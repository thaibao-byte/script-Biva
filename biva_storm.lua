# File: server.py
# ==============================================================================
# BIVA STORM | V27.0 HYPERION SUPREME OMNI-SYNC SERVER
# Kiến trúc Đồng Bộ 4 Tầng:
#   [Tầng 1] O(1) In-Memory Hash Index (Tra cứu HWID / Key / Order 0ms)
#   [Tầng 2] Real-Time SSE Event Bus (Đẩy biến động trực tiếp sang Web & Admin)
#   [Tầng 3] Atomic Write-Ahead Local Disk Backup (biva_db_local.json)
#   [Tầng 4] CRDT Conflict-Free GitHub Cloud Storage (Chống Stale CDN 100%)
# ==============================================================================

import asyncio
import base64
from contextlib import asynccontextmanager
import copy
from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import json
import logging
import os
from pathlib import Path
import random
import re
import secrets
import string
import time
from typing import Any, AsyncGenerator, Dict, List, Optional, Set, Tuple
from urllib.parse import quote

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import (
    FileResponse,
    HTMLResponse,
    JSONResponse,
    PlainTextResponse,
    StreamingResponse,
)
from pydantic import BaseModel, Field

# ==============================================================================
# 1. CẤU HÌNH LOGGING, MÚI GIỜ VIỆT NAM (GMT+7) & HẰNG SỐ HỆ THỐNG
# ==============================================================================
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("BIVA_V27_HYPERION")

VN_TZ = timezone(timedelta(hours=7))
APP_VERSION = "27.0.0"
DEFAULT_ADMIN_NOTICE = (
    "⚡ Hệ thống BIVA STORM V27.0 HYPERION SUPREME đồng bộ tức thì 0ms hoạt động ổn định 100%!"
)

BASE_STATIC_DIR = Path(".").resolve()
LOCAL_DB_BACKUP_PATH = (BASE_STATIC_DIR / "biva_db_local.json").resolve()
LOCAL_WAL_PATH = (BASE_STATIC_DIR / "biva_wal.log").resolve()


def now_ts() -> float:
    """Trả về Unix timestamp chuẩn xác."""
    return time.time()


def format_vn_time(ts: float, fmt: str = "%Y-%m-%d %H:%M") -> str:
    """Định dạng thời gian chuẩn múi giờ Việt Nam (GMT+7) bất kể múi giờ máy chủ."""
    try:
        val = float(ts or 0)
        if val <= 0:
            return "N/A"
        if val > 3000 * 86400 + time.time():
            return "Vĩnh Viễn"
        return datetime.fromtimestamp(val, tz=VN_TZ).strftime(fmt)
    except Exception:
        return "Vĩnh Viễn"


def format_remaining_time(expire_ts: float, now: Optional[float] = None) -> str:
    """Tính thời gian còn lại chính xác và dễ đọc bằng tiếng Việt."""
    if now is None:
        now = time.time()
    try:
        rem = int(float(expire_ts) - now)
    except Exception:
        return "Đã hết hạn"
    if rem <= 0:
        return "Đã hết hạn"
    if rem > 3000 * 86400:
        return "Vĩnh Viễn"
    days = rem // 86400
    hours = (rem % 86400) // 3600
    mins = (rem % 3600) // 60
    secs = rem % 60
    if days > 0:
        return f"{days} ngày {hours} giờ"
    if hours > 0:
        return f"{hours} giờ {mins} phút"
    if mins > 0:
        return f"{mins} phút {secs} giây"
    return f"{max(1, secs)} giây"


def lua_escape(val: Any) -> str:
    """Làm sạch chuỗi trước khi nhúng vào hằng chuỗi Lua để chống lỗi cú pháp & Lua Injection."""
    s = str(val if val is not None else "")
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("'", "\\'")
    s = s.replace("\r", " ").replace("\n", " ")
    return s


# ==============================================================================
# 2. TÍCH HỢP CỔNG THANH TOÁN TỰ ĐỘNG PAYOS V27.0 (MODULE + REST API V2 DỰ PHÒNG)
# ==============================================================================
try:
    import payos  # type: ignore
except ImportError:
    payos = None
    logger.warning(
        "Không tìm thấy module 'payos'. Sử dụng PayOS REST API v2 gốc nếu có cấu hình ENV."
    )

PAYOS_CLIENT_ID = os.getenv("PAYOS_CLIENT_ID", "").strip()
PAYOS_API_KEY = os.getenv("PAYOS_API_KEY", "").strip()
PAYOS_CHECKSUM_KEY = os.getenv("PAYOS_CHECKSUM_KEY", "").strip()
PAYOS_API_BASE = os.getenv("PAYOS_API_BASE", "https://api-merchant.payos.vn").rstrip("/")


def _payos_module_has(func_name: str) -> bool:
    return payos is not None and callable(getattr(payos, func_name, None))


def _payos_native_ready() -> bool:
    return bool(PAYOS_CLIENT_ID and PAYOS_API_KEY and PAYOS_CHECKSUM_KEY)


def payment_gateway_mode() -> str:
    if _payos_module_has("create_payment_link"):
        return "module"
    if _payos_native_ready():
        return "native"
    return "disabled"


async def _call_payos_func(func_name: str, *args: Any, **kwargs: Any) -> Any:
    if not _payos_module_has(func_name):
        return None
    fn = getattr(payos, func_name)
    try:
        if asyncio.iscoroutinefunction(fn):
            return await fn(*args, **kwargs)
        return await asyncio.to_thread(fn, *args, **kwargs)
    except Exception as e:
        logger.error(f"PayOS '{func_name}' error: {e}")
        return None


def _payos_native_headers() -> Dict[str, str]:
    return {
        "x-client-id": PAYOS_CLIENT_ID,
        "x-api-key": PAYOS_API_KEY,
        "Content-Type": "application/json",
    }


async def _native_create_payment_link(
    order_code: int, amount: int, description: str
) -> Optional[Dict[str, Any]]:
    """Khởi tạo đơn thanh toán VietQR qua PayOS REST API v2 (POST /v2/payment-requests)."""
    return_url = f"{WEB_DOMAIN}/index.html?order={quote(description)}"
    cancel_url = f"{WEB_DOMAIN}/index.html?cancel={quote(description)}"
    desc = str(description)[:25]
    raw = (
        f"amount={amount}&cancelUrl={cancel_url}&description={desc}"
        f"&orderCode={order_code}&returnUrl={return_url}"
    )
    signature = hmac.new(
        PAYOS_CHECKSUM_KEY.encode("utf-8"),
        raw.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    payload = {
        "orderCode": int(order_code),
        "amount": int(amount),
        "description": desc,
        "cancelUrl": cancel_url,
        "returnUrl": return_url,
        "signature": signature,
    }
    try:
        client = await _get_http_client()
        res = await client.post(
            f"{PAYOS_API_BASE}/v2/payment-requests",
            json=payload,
            headers=_payos_native_headers(),
        )
        body = res.json() if res.content else {}
        data = body.get("data") if isinstance(body, dict) else None
        if (
            res.status_code == 200
            and str(body.get("code")) == "00"
            and isinstance(data, dict)
        ):
            qr_text = str(data.get("qrCode") or "")
            bin_code = str(data.get("bin") or "")
            acc_no = str(data.get("accountNumber") or "")
            acc_name = str(data.get("accountName") or "")
            if bin_code and acc_no:
                qr_url = (
                    f"https://img.vietqr.io/image/{quote(bin_code)}-{quote(acc_no)}-compact2.png"
                    f"?amount={int(amount)}&addInfo={quote(desc)}&accountName={quote(acc_name)}"
                )
            elif qr_text:
                qr_url = (
                    f"https://api.qrserver.com/v1/create-qr-code/"
                    f"?size=360x360&margin=12&data={quote(qr_text)}"
                )
            else:
                return None
            return {
                "success": True,
                "qr_url": qr_url,
                "qr_raw": qr_text,
                "account_no": acc_no,
                "account_name": acc_name,
                "bin": bin_code,
                "checkout_url": str(data.get("checkoutUrl") or ""),
            }
        logger.error(f"PayOS native create HTTP {res.status_code}: {str(body)[:200]}")
    except Exception as e:
        logger.error(f"PayOS native create error: {e}")
    return None


async def _native_check_payment_paid(order_code: int) -> bool:
    """Kiểm tra trạng thái thanh toán trực tiếp từ PayOS REST API v2."""
    try:
        client = await _get_http_client()
        res = await client.get(
            f"{PAYOS_API_BASE}/v2/payment-requests/{int(order_code)}",
            headers=_payos_native_headers(),
        )
        body = res.json() if res.content else {}
        data = body.get("data") if isinstance(body, dict) else None
        return (
            res.status_code == 200
            and isinstance(data, dict)
            and str(data.get("status") or "").upper() == "PAID"
        )
    except Exception as e:
        logger.error(f"PayOS native status error: {e}")
        return False


async def gateway_create_payment(
    order_code: int, amount: int, description: str
) -> Optional[Dict[str, Any]]:
    mode = payment_gateway_mode()
    if mode == "module":
        res = await _call_payos_func("create_payment_link", order_code, amount, description)
        if isinstance(res, dict) and res.get("success") and res.get("qr_url"):
            return res
        if _payos_native_ready():
            return await _native_create_payment_link(order_code, amount, description)
        return None
    if mode == "native":
        return await _native_create_payment_link(order_code, amount, description)
    return None


async def gateway_payment_confirmed(order_code: int) -> Optional[bool]:
    if _payos_module_has("check_payment_status"):
        return bool(await _call_payos_func("check_payment_status", order_code))
    if _payos_native_ready():
        return await _native_check_payment_paid(order_code)
    return None


def verify_payos_webhook_signature(body: Dict[str, Any], checksum_key: str) -> bool:
    """Xác thực chữ ký HMAC-SHA256 của PayOS Webhook chống giả mạo giao dịch."""
    if not checksum_key:
        return True
    data = body.get("data")
    signature = str(body.get("signature") or "").strip()
    if not isinstance(data, dict) or not signature:
        return False
    try:
        sorted_keys = sorted(data.keys())
        parts = []
        for k in sorted_keys:
            v = data[k]
            if v is None or v == "null" or v == "undefined":
                v_str = ""
            elif isinstance(v, (dict, list)):
                v_str = json.dumps(v, separators=(",", ":"), ensure_ascii=False)
            else:
                v_str = str(v)
            parts.append(f"{k}={v_str}")
        sign_data = "&".join(parts)
        computed = hmac.new(
            checksum_key.encode("utf-8"),
            sign_data.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(computed.lower(), signature.lower())
    except Exception as e:
        logger.error(f"PayOS signature check error: {e}")
        return False


# ==============================================================================
# 3. CẤU HÌNH BẢO MẬT, GITHUB STORAGE & GÓI BẢN QUYỀN V27.0
# ==============================================================================
ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", os.getenv("ADMIN_PASSWORD", "biva_secret_2026")).strip()
TOKEN_SECRET = (
    os.getenv("BIVA_TOKEN_SECRET", "").strip()
    or hashlib.sha256(f"biva-v27-hyperion:{ADMIN_TOKEN}".encode("utf-8")).hexdigest()
)

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "").strip()
GITHUB_REPO = os.getenv("GITHUB_REPO", "thaibao28082008/Biva_Storm").strip()
GITHUB_PATH = os.getenv("GITHUB_PATH", "biva_db.json").strip()

GITHUB_SCRIPT_URL = os.getenv(
    "GITHUB_SCRIPT_URL",
    f"https://raw.githubusercontent.com/{GITHUB_REPO or 'thaibao28082008/Biva_Storm'}/main/steal_egg.lua",
).strip()

WEB_DOMAIN = os.getenv("WEB_DOMAIN", "https://biva-hub.onrender.com").rstrip("/")
LOOTLABS_API_KEY = os.getenv("LOOTLABS_API_KEY", "").strip()

EXPIRED_KEY_RETENTION_SECONDS = 7 * 86400
PENDING_ORDER_TTL_SECONDS = 86400
TOMBSTONE_TTL_SECONDS = 14400
FREE_TOKEN_TTL_SECONDS = 900
SELF_RESET_COOLDOWN_PAID = 12 * 3600
SELF_RESET_COOLDOWN_FREE = 24 * 3600
MAX_AUDIT_LOGS = 250

# Khoảng thời gian bảo vệ Read-Your-Own-Writes (RYOW):
# Trong 30s kể từ lần Ghi gần nhất, RAM của Server là nguồn chân lý tuyệt đối (Authoritative),
# không cho phép GitHub CDN lag ghi đè dữ liệu cũ.
WRITE_FENCE_SECONDS = 30.0
CACHE_TTL_SECONDS = 4.0

PACKAGE_CONFIG: Dict[str, Dict[str, int]] = {
    "Dùng Thử 20h": {"price": 0, "days": 1, "duration": 20 * 3600},
    "Free 20h": {"price": 0, "days": 1, "duration": 20 * 3600},
    "20 Giờ": {"price": 0, "days": 1, "duration": 20 * 3600},
    "1 Ngày": {"price": 15000, "days": 1, "duration": 86400},
    "24 Giờ": {"price": 15000, "days": 1, "duration": 86400},
    "1 Tuần": {"price": 55000, "days": 7, "duration": 7 * 86400},
    "7 Ngày": {"price": 55000, "days": 7, "duration": 7 * 86400},
    "168 Giờ": {"price": 55000, "days": 7, "duration": 7 * 86400},
    "1 Tháng": {"price": 135000, "days": 30, "duration": 30 * 86400},
    "30 Ngày": {"price": 135000, "days": 30, "duration": 30 * 86400},
    "720 Giờ": {"price": 135000, "days": 30, "duration": 30 * 86400},
    "1 Năm VIP": {"price": 200000, "days": 365, "duration": 365 * 86400},
    "8760 Giờ": {"price": 200000, "days": 365, "duration": 365 * 86400},
    "Vĩnh Viễn": {"price": 250000, "days": 365000, "duration": 365000 * 86400},
}

SUPPORTED_GAMES_CATALOG: List[Dict[str, Any]] = [
    {
        "id": "steal_egg",
        "code": "rb",
        "name": "⚡ Steal Egg / Biva Main Hub",
        "status": "online",
        "version": "27.0",
        "features": ["Auto Steal Egg", "ESP Players/Items", "Instant Teleport", "Anti-AFK"],
    },
    {
        "id": "blox_fruits",
        "code": "rb",
        "name": "🏴‍☠️ Blox Fruits Hyperion",
        "status": "online",
        "version": "27.0",
        "features": ["Auto Farm Level", "Auto Sea Event", "Fruit Sniper", "Raid Carry"],
    },
    {
        "id": "fisch",
        "code": "rb",
        "name": "🐟 Fisch Auto Reel Supreme",
        "status": "online",
        "version": "27.0",
        "features": ["Instant Shake/Reel", "Auto Sell Inventory", "Rare Fish Radar", "Zone TP"],
    },
    {
        "id": "dead_rails",
        "code": "rb",
        "name": "🚂 Dead Rails Outlaw Hub",
        "status": "online",
        "version": "27.0",
        "features": ["Auto Collect Bonds", "Silent Aimbot", "Train Fuel Guard", "Loot ESP"],
    },
    {
        "id": "arise_crossover",
        "code": "rb",
        "name": "⚔️ Arise Crossover Shadow",
        "status": "online",
        "version": "27.0",
        "features": ["Auto Dungeon Clear", "Auto Arise Boss", "Shadow Macro", "Kill Aura"],
    },
    {
        "id": "blue_lock",
        "code": "rb",
        "name": "⚽ Blue Lock Rivals Striker",
        "status": "online",
        "version": "27.0",
        "features": ["Auto Goal Curve", "Infinite Stamina", "Ball Magnet", "Hitbox Expander"],
    },
]


def resolve_package_label(hours_val: float, custom_pkg: Optional[str] = None) -> str:
    if custom_pkg and custom_pkg.strip() in PACKAGE_CONFIG:
        p = custom_pkg.strip()
        if p == "24 Giờ":
            return "1 Ngày"
        if p in ("7 Ngày", "168 Giờ"):
            return "1 Tuần"
        if p in ("30 Ngày", "720 Giờ"):
            return "1 Tháng"
        if p == "8760 Giờ":
            return "1 Năm VIP"
        return p
    if hours_val >= 72000:
        return "Vĩnh Viễn"
    if abs(hours_val - 20) < 0.1:
        return "Free 20h"
    if abs(hours_val - 24) < 0.1:
        return "1 Ngày"
    if abs(hours_val - 168) < 0.1:
        return "1 Tuần"
    if abs(hours_val - 720) < 0.1:
        return "1 Tháng"
    if abs(hours_val - 8760) < 0.1:
        return "1 Năm VIP"
    if custom_pkg and custom_pkg.strip():
        return custom_pkg.strip()
    return f"{int(hours_val)} Giờ"


# ==============================================================================
# 4. BỘ NHỚ ĐỆM ĐỒNG BỘ 4 TẦNG, CHỈ MỤC RAM O(1) & REAL-TIME SSE EVENT BUS
# ==============================================================================
FREE_TOKENS: Dict[str, Dict[str, Any]] = {}
DB_ASYNC_LOCK = asyncio.Lock()
GITHUB_PUSH_LOCK = asyncio.Lock()
SERVER_START_TIME = time.time()

DB_CACHE: Dict[str, Any] = {
    "data": {"keys": {}, "orders": {}, "meta": {}},
    "sha": None,
    "last_fetch": 0.0,
    "last_mutation_ts": 0.0,
    "last_push_ts": 0.0,
    "last_pushed_sha": None,
    "dirty": False,
    "revision": 1,
}

# Bộ chỉ mục O(1) trong RAM giúp tìm kiếm Key / HWID / Order tức thì 0ms
MEMORY_INDEX: Dict[str, Any] = {
    "by_hwid": {},          # hwid_clean -> Set[key_code]
    "by_compact_hwid": {},  # compact_alnum(hwid) -> Set[key_code]
    "by_compact_key": {},   # compact_alnum(key) -> key_code
    "orders_by_hwid": {},   # hwid_clean -> Set[order_id]
    "orders_by_key": {},    # key_code -> order_id
}

# Hàng đợi Pub/Sub cho các kết nối Server-Sent Events (SSE) thời gian thực
SSE_SUBSCRIBERS: Set[asyncio.Queue] = set()

SCRIPT_CACHE: Dict[str, Dict[str, Any]] = {}
HTTP_CLIENT: Optional[httpx.AsyncClient] = None
SYNC_TASK: Optional[asyncio.Task] = None


def broadcast_sse_event(event_type: str, payload: Dict[str, Any]) -> None:
    """Đẩy sự kiện đồng bộ thời gian thực tới mọi trình duyệt đang mở Web Shop hoặc Admin."""
    if not SSE_SUBSCRIBERS:
        return
    message = {
        "event": event_type,
        "ts": int(time.time() * 1000),
        "revision": int(DB_CACHE.get("revision") or 1),
        **payload,
    }
    stale_queues: List[asyncio.Queue] = []
    for q in list(SSE_SUBSCRIBERS):
        try:
            if q.full():
                try:
                    q.get_nowait()
                except Exception:
                    pass
            q.put_nowait(message)
        except Exception:
            stale_queues.append(q)
    for q in stale_queues:
        SSE_SUBSCRIBERS.discard(q)


def normalize_hwid(raw_hwid: Optional[str]) -> str:
    """
    Chuẩn hóa HWID đồng nhất tuyệt đối giữa Server, Admin, Web Shop và Lua Loader:
    - Loại bỏ tiền tố thừa ('HWID:', 'KEY:', 'ID=') nếu người dùng copy cả nhãn.
    - Xóa mọi khoảng trắng, ký tự điều khiển và ép kiểu chữ in hoa.
    """
    if not raw_hwid:
        return ""
    cleaned = re.sub(r"\s+", "", str(raw_hwid))
    cleaned = re.sub(r"^(HWID|DEVICE|MA_MAY)[:=\-_]*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"[^\w\-]", "", cleaned).upper()
    return cleaned[:64]


def normalize_key(raw_key: Optional[str]) -> str:
    """Chuẩn hóa Mã Key đồng nhất tuyệt đối."""
    if not raw_key:
        return ""
    cleaned = re.sub(r"\s+", "", str(raw_key))
    cleaned = re.sub(r"^(KEY|MA_KEY|LICENSE)[:=\-_]*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"[^a-zA-Z0-9\-_]", "", cleaned).upper()
    return cleaned[:64]


def compact_alnum(val: Optional[str]) -> str:
    """Chỉ giữ lại chữ cái và chữ số in hoa để đối sánh mờ (bất chấp dấu gạch ngang)."""
    if not val:
        return ""
    return re.sub(r"[^A-Z0-9]", "", str(val).upper())


def append_audit_log(
    db_data: Dict[str, Any],
    action: str,
    actor: str,
    target: str,
    detail: str = "",
) -> None:
    """Ghi nhật ký kiểm toán (Audit Log) cho mọi biến động quan trọng trên hệ thống."""
    meta = _ensure_meta_structure(db_data.get("meta"))
    logs: List[Dict[str, Any]] = meta.get("audit_logs", [])
    now = time.time()
    logs.insert(
        0,
        {
            "id": secrets.token_hex(4).upper(),
            "time": now,
            "time_str": format_vn_time(now, "%H:%M:%S %d/%m/%Y"),
            "action": action,
            "actor": actor,
            "target": target,
            "detail": detail,
        },
    )
    meta["audit_logs"] = logs[:MAX_AUDIT_LOGS]
    db_data["meta"] = meta


def rebuild_memory_indexes(db_data: Dict[str, Any]) -> Dict[str, int]:
    """
    Xây dựng lại bảng chỉ mục RAM O(1) và tự động hàn gắn (Self-Heal) liên kết HWID giữa Order và Key.
    Trả về thống kê số lượng liên kết đã tự động phục hồi.
    """
    by_hwid: Dict[str, Set[str]] = {}
    by_compact_hwid: Dict[str, Set[str]] = {}
    by_compact_key: Dict[str, str] = {}
    orders_by_hwid: Dict[str, Set[str]] = {}
    orders_by_key: Dict[str, str] = {}

    keys_dict = db_data.get("keys", {})
    orders_dict = db_data.get("orders", {})
    healed_links = 0

    # Bước 1: Đồng bộ chéo HWID 2 chiều giữa Đơn hàng đã Paid và Key được cấp
    for oid, o in orders_dict.items():
        if not isinstance(o, dict):
            continue
        o_hwid = normalize_hwid(o.get("hwid"))
        issued_k = normalize_key(o.get("key") or o.get("key_code"))
        if o_hwid:
            orders_by_hwid.setdefault(o_hwid, set()).add(oid)
        if issued_k:
            orders_by_key[issued_k] = oid
            if issued_k in keys_dict:
                k_obj = keys_dict[issued_k]
                k_hwid = normalize_hwid(k_obj.get("hwid"))
                if o_hwid and not k_hwid and not k_obj.get("last_hwid_reset"):
                    k_obj["hwid"] = o_hwid
                    healed_links += 1
                elif k_hwid and not o_hwid:
                    o["hwid"] = k_hwid
                    orders_by_hwid.setdefault(k_hwid, set()).add(oid)
                    healed_links += 1
                if not k_obj.get("order_id"):
                    k_obj["order_id"] = oid

    # Bước 2: Đánh chỉ mục O(1) cho toàn bộ Key
    for k, v in keys_dict.items():
        if not isinstance(v, dict):
            continue
        ck = compact_alnum(k)
        if ck:
            by_compact_key[ck] = k
        bound = normalize_hwid(v.get("hwid"))
        if bound:
            by_hwid.setdefault(bound, set()).add(k)
            cb = compact_alnum(bound)
            if cb:
                by_compact_hwid.setdefault(cb, set()).add(k)

    MEMORY_INDEX["by_hwid"] = by_hwid
    MEMORY_INDEX["by_compact_hwid"] = by_compact_hwid
    MEMORY_INDEX["by_compact_key"] = by_compact_key
    MEMORY_INDEX["orders_by_hwid"] = orders_by_hwid
    MEMORY_INDEX["orders_by_key"] = orders_by_key

    return {
        "indexed_keys": len(keys_dict),
        "indexed_hwids": len(by_hwid),
        "indexed_orders": len(orders_dict),
        "healed_links": healed_links,
    }


async def _get_http_client() -> httpx.AsyncClient:
    global HTTP_CLIENT
    if HTTP_CLIENT is None or HTTP_CLIENT.is_closed:
        HTTP_CLIENT = httpx.AsyncClient(
            timeout=httpx.Timeout(12.0, connect=5.0),
            limits=httpx.Limits(max_keepalive_connections=60, max_connections=120),
        )
    return HTTP_CLIENT


def _save_local_disk_backup(db_data: Dict[str, Any]) -> None:
    """Ghi nguyên tử (Atomic Write-Ahead) xuống ổ cứng cục bộ."""
    try:
        tmp_path = LOCAL_DB_BACKUP_PATH.with_suffix(".tmp")
        tmp_path.write_text(
            json.dumps(db_data, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        tmp_path.replace(LOCAL_DB_BACKUP_PATH)
    except Exception as e:
        logger.debug(f"Local disk backup skip: {e}")


def _load_local_disk_backup() -> Optional[Dict[str, Any]]:
    try:
        if LOCAL_DB_BACKUP_PATH.is_file():
            raw = LOCAL_DB_BACKUP_PATH.read_text(encoding="utf-8")
            parsed = json.loads(raw)
            if isinstance(parsed, dict):
                return parsed
    except Exception as e:
        logger.warning(f"Local disk backup load error: {e}")
    return None


async def _background_dirty_sync_loop() -> None:
    """Vòng lặp đồng bộ nền tự động đẩy dữ liệu chờ (dirty) lên GitHub mỗi 6 giây."""
    while True:
        try:
            await asyncio.sleep(6)
            if DB_CACHE.get("dirty") and GITHUB_TOKEN and GITHUB_REPO:
                async with GITHUB_PUSH_LOCK:
                    if DB_CACHE.get("dirty"):
                        snapshot_to_push = copy.deepcopy(DB_CACHE["data"])
                        await push_github_db(
                            snapshot_to_push,
                            DB_CACHE.get("sha"),
                            from_background=True,
                        )
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Background sync error: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    global HTTP_CLIENT, SYNC_TASK
    HTTP_CLIENT = httpx.AsyncClient(
        timeout=httpx.Timeout(12.0, connect=5.0),
        limits=httpx.Limits(max_keepalive_connections=60, max_connections=120),
    )
    local_backup = _load_local_disk_backup()
    if local_backup:
        clean_local, _ = normalize_and_clean_db(local_backup)
        DB_CACHE["data"] = clean_local
        rebuild_memory_indexes(clean_local)
    async with DB_ASYNC_LOCK:
        await fetch_github_db(force_refresh=True)
    SYNC_TASK = asyncio.create_task(_background_dirty_sync_loop())
    yield
    if SYNC_TASK and not SYNC_TASK.done():
        SYNC_TASK.cancel()
    if HTTP_CLIENT and not HTTP_CLIENT.is_closed:
        await HTTP_CLIENT.aclose()


app = FastAPI(
    title="BIVA STORM API V27.0 HYPERION SUPREME",
    version=APP_VERSION,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    if request.url.path.startswith("/api/"):
        response.headers["Cache-Control"] = (
            "no-store, no-cache, must-revalidate, max-age=0"
        )
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "detail": exc.detail, "message": exc.detail},
        )
    logger.error(f"Unhandled error at {request.url.path}: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "detail": "Hệ thống đang xử lý lưu lượng cao, vui lòng thử lại sau giây lát!",
            "message": "Hệ thống đang xử lý lưu lượng cao, vui lòng thử lại sau giây lát!",
        },
    )


# ==============================================================================
# 5. CHỐNG SPAM / DDOS / BRUTE-FORCE & XÁC THỰC ADMIN V27.0
# ==============================================================================
RATE_LIMIT_CACHE: Dict[str, List[float]] = {}
AUTH_FAIL_CACHE: Dict[str, List[float]] = {}
LAST_RATE_CLEANUP: float = 0.0


def get_client_ip(request: Optional[Request]) -> str:
    if request is None:
        return "unknown"
    for h_name in ("cf-connecting-ip", "true-client-ip", "x-real-ip"):
        val = request.headers.get(h_name)
        if val and val.strip():
            return val.strip()[:64]
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()[:64]
    return (
        request.client.host[:64]
        if (request.client and request.client.host)
        else "unknown"
    )


def check_rate_limit(
    request: Optional[Request],
    limit: int = 90,
    window: int = 60,
    scope: str = "",
) -> None:
    global LAST_RATE_CLEANUP
    if request is None:
        return
    ip = get_client_ip(request)
    path = scope or request.url.path
    now = time.time()

    if now - LAST_RATE_CLEANUP > 120 or len(RATE_LIMIT_CACHE) > 10000:
        LAST_RATE_CLEANUP = now
        stale = [
            k
            for k, hits in list(RATE_LIMIT_CACHE.items())
            if not hits or (now - hits[-1] > 180)
        ]
        for k in stale:
            RATE_LIMIT_CACHE.pop(k, None)

    key = f"{ip}:{path}"
    bucket = [t for t in RATE_LIMIT_CACHE.get(key, []) if now - t < window]
    if len(bucket) >= limit:
        raise HTTPException(
            status_code=429,
            detail="Thao tác quá nhanh, vui lòng đợi vài giây!",
        )
    bucket.append(now)
    RATE_LIMIT_CACHE[key] = bucket


async def verify_admin(
    request: Request,
    authorization: Optional[str] = Header(None),
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
    x_admin_password: Optional[str] = Header(None, alias="X-Admin-Password"),
    token: Optional[str] = Query(None, include_in_schema=False),
):
    ip = get_client_ip(request)
    now = time.time()
    fail_bucket = [t for t in AUTH_FAIL_CACHE.get(ip, []) if now - t < 300]
    if len(fail_bucket) >= 8:
        raise HTTPException(
            status_code=429,
            detail="Tạm khóa xác thực Admin 5 phút do nhập sai quá nhiều lần!",
        )

    provided: Optional[str] = None
    if authorization and authorization.lower().startswith("bearer "):
        provided = authorization[7:].strip()
    elif x_admin_token:
        provided = x_admin_token.strip()
    elif x_admin_password:
        provided = x_admin_password.strip()
    elif token:
        provided = token.strip()

    if not provided:
        try:
            body = await request.json()
            if isinstance(body, dict) and body.get("token"):
                provided = str(body.get("token")).strip()
        except Exception:
            pass

    if not provided or not secrets.compare_digest(provided, ADMIN_TOKEN):
        fail_bucket.append(now)
        AUTH_FAIL_CACHE[ip] = fail_bucket
        raise HTTPException(status_code=403, detail="Sai mật khẩu Admin!")

    AUTH_FAIL_CACHE.pop(ip, None)
    return True


def generate_key(prefix: str = "RB", length: int = 6) -> str:
    clean_prefix = re.sub(r"[^A-Z0-9]", "", str(prefix or "RB").upper()) or "RB"
    alphabet = string.ascii_uppercase + string.digits
    p1 = "".join(secrets.choice(alphabet) for _ in range(4))
    p2 = "".join(secrets.choice(alphabet) for _ in range(4))
    return f"{clean_prefix}-{p1}-{p2}"


def create_signed_free_token(hwid: str, game: str) -> Tuple[str, str]:
    nonce = secrets.token_hex(8)
    ts = int(time.time())
    payload_obj = {"h": hwid, "g": game, "t": ts, "n": nonce}
    raw_bytes = json.dumps(payload_obj, separators=(",", ":")).encode("utf-8")
    b64_payload = base64.urlsafe_b64encode(raw_bytes).decode("utf-8").rstrip("=")
    sig = hmac.new(
        TOKEN_SECRET.encode("utf-8"),
        b64_payload.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()[:24]
    return f"{b64_payload}.{sig}", nonce


def verify_signed_free_token(token: str) -> Optional[Dict[str, Any]]:
    if "." not in token:
        return None
    try:
        b64_payload, sig = token.split(".", 1)
        expected_sig = hmac.new(
            TOKEN_SECRET.encode("utf-8"),
            b64_payload.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()[:24]
        if not hmac.compare_digest(sig.lower(), expected_sig.lower()):
            return None
        padding = "=" * ((4 - len(b64_payload) % 4) % 4)
        decoded = base64.urlsafe_b64decode(
            (b64_payload + padding).encode("utf-8")
        ).decode("utf-8")
        obj = json.loads(decoded)
        if not isinstance(obj, dict):
            return None
        return {
            "hwid": normalize_hwid(obj.get("h")),
            "game": str(obj.get("g") or "rb").strip().lower(),
            "time": float(obj.get("t") or 0),
            "nonce": str(obj.get("n") or ""),
        }
    except Exception:
        return None


def get_key_tier_label(key_data: Dict[str, Any]) -> str:
    k_type = str(key_data.get("type") or "paid").lower()
    pkg = str(key_data.get("package") or "").strip()
    exp = float(key_data.get("expire") or 0)
    if exp - time.time() > 3000 * 86400 or "vĩnh viễn" in pkg.lower():
        return "V27.0 HYPERION LIFETIME"
    if k_type == "free":
        return "V27.0 FREE EDITION"
    if pkg:
        return f"V27.0 VIP ({pkg})"
    return "V27.0 VIP EDITION"


# ==============================================================================
# 6. LÕI ĐỒNG BỘ DATABASE V27.0 (CRDT TIMESTAMP MERGE + WRITE-FENCE RYOW)
# ==============================================================================
def _ensure_meta_structure(meta: Any) -> Dict[str, Any]:
    if not isinstance(meta, dict):
        meta = {}
    if not isinstance(meta.get("deleted_keys"), dict):
        meta["deleted_keys"] = {}
    if not isinstance(meta.get("deleted_orders"), dict):
        meta["deleted_orders"] = {}
    if not isinstance(meta.get("used_free_tokens"), dict):
        meta["used_free_tokens"] = {}
    if not isinstance(meta.get("vouchers"), dict):
        meta["vouchers"] = {}
    if not isinstance(meta.get("hwid_blacklist"), dict):
        meta["hwid_blacklist"] = {}
    if not isinstance(meta.get("audit_logs"), list):
        meta["audit_logs"] = []
    if not isinstance(meta.get("admin_notice"), str) or not meta.get("admin_notice"):
        meta["admin_notice"] = DEFAULT_ADMIN_NOTICE
    if not isinstance(meta.get("maintenance"), bool):
        meta["maintenance"] = False
    try:
        meta["sync_revision"] = max(1, int(meta.get("sync_revision") or 1))
    except Exception:
        meta["sync_revision"] = 1
    return meta


def normalize_and_clean_db(db_data: Any) -> Tuple[Dict[str, Any], bool]:
    is_modified = False
    if not isinstance(db_data, dict):
        db_data = {"keys": {}, "orders": {}, "meta": {}}
        is_modified = True

    if "keys" not in db_data or not isinstance(db_data["keys"], dict):
        db_data["keys"] = {}
        is_modified = True

    if "orders" not in db_data or not isinstance(db_data["orders"], dict):
        db_data["orders"] = {}
        is_modified = True

    db_data["meta"] = _ensure_meta_structure(db_data.get("meta"))

    now = time.time()
    deleted_keys: Dict[str, float] = db_data["meta"]["deleted_keys"]
    deleted_orders: Dict[str, float] = db_data["meta"]["deleted_orders"]
    used_free_tokens: Dict[str, float] = db_data["meta"]["used_free_tokens"]

    for tk in [
        k
        for k, ts in list(deleted_keys.items())
        if now - float(ts or 0) > TOMBSTONE_TTL_SECONDS
    ]:
        deleted_keys.pop(tk, None)
        is_modified = True
    for to in [
        k
        for k, ts in list(deleted_orders.items())
        if now - float(ts or 0) > TOMBSTONE_TTL_SECONDS
    ]:
        deleted_orders.pop(to, None)
        is_modified = True
    for fn in [
        k
        for k, ts in list(used_free_tokens.items())
        if now - float(ts or 0) > (FREE_TOKEN_TTL_SECONDS + 900)
    ]:
        used_free_tokens.pop(fn, None)
        is_modified = True

    normalized_keys: Dict[str, Dict[str, Any]] = {}
    for raw_k, v in list(db_data["keys"].items()):
        if not isinstance(v, dict):
            is_modified = True
            continue
        k = normalize_key(raw_k)
        if not k:
            is_modified = True
            continue

        created_ts = float(v.get("created_at") or now)
        updated_ts = float(v.get("updated_at") or created_ts)
        del_ts = float(deleted_keys.get(k) or 0)
        if del_ts > 0 and del_ts >= updated_ts:
            is_modified = True
            continue
        elif del_ts > 0 and updated_ts > del_ts:
            deleted_keys.pop(k, None)
            is_modified = True

        try:
            expire_ts = float(v.get("expire") or 0)
        except (ValueError, TypeError):
            expire_ts = 0.0

        if expire_ts <= 0 or (now - expire_ts) > EXPIRED_KEY_RETENTION_SECONDS:
            is_modified = True
            continue

        norm_hwid = normalize_hwid(v.get("hwid"))
        if v.get("key_code") != k or v.get("hwid") != norm_hwid:
            is_modified = True
        v["key_code"] = k
        v["hwid"] = norm_hwid
        v["expire"] = expire_ts
        v["is_banned"] = bool(v.get("is_banned", False))
        v["note"] = str(v.get("note") or "")
        v["game"] = str(v.get("game") or "rb").strip().lower()
        if "type" not in v:
            v["type"] = "free" if k.startswith("FREE-") else "paid"
            is_modified = True
        v["created_at"] = created_ts
        v["updated_at"] = updated_ts
        v["executions"] = int(v.get("executions") or 0)

        normalized_keys[k] = v

    if len(normalized_keys) != len(db_data["keys"]):
        is_modified = True
    db_data["keys"] = normalized_keys

    normalized_orders: Dict[str, Dict[str, Any]] = {}
    for raw_oid, o in list(db_data["orders"].items()):
        if not isinstance(o, dict):
            is_modified = True
            continue
        oid = str(raw_oid).strip().upper()
        if not oid:
            is_modified = True
            continue

        try:
            order_time = float(o.get("time") or 0)
        except (ValueError, TypeError):
            order_time = 0.0

        order_updated = float(o.get("updated_at") or order_time or now)
        del_o_ts = float(deleted_orders.get(oid) or 0)
        if del_o_ts > 0 and del_o_ts >= order_updated:
            is_modified = True
            continue
        elif del_o_ts > 0 and order_updated > del_o_ts:
            deleted_orders.pop(oid, None)
            is_modified = True

        status = str(o.get("status") or "pending").lower()
        if status == "pending" and (now - order_time > PENDING_ORDER_TTL_SECONDS):
            is_modified = True
            continue

        issued_key = normalize_key(o.get("key") or o.get("key_code")) or None
        norm_hwid = normalize_hwid(o.get("hwid"))
        if (
            o.get("order_id") != oid
            or o.get("hwid") != norm_hwid
            or o.get("key") != issued_key
            or o.get("key_code") != issued_key
        ):
            is_modified = True

        o["order_id"] = oid
        o["status"] = status
        o["key"] = issued_key
        o["key_code"] = issued_key
        o["hwid"] = norm_hwid
        o["time"] = order_time
        o["updated_at"] = order_updated

        normalized_orders[oid] = o

    if len(normalized_orders) != len(db_data["orders"]):
        is_modified = True
    db_data["orders"] = normalized_orders

    rebuild_memory_indexes(db_data)
    return db_data, is_modified


def _merge_db_states(remote_db: Dict[str, Any], local_db: Dict[str, Any]) -> Dict[str, Any]:
    """
    Thuật toán hợp nhất CRDT (Conflict-Free Replicated Data Type) cấp bản ghi:
    - So sánh `updated_at` trên từng Key và từng Order.
    - Bảo toàn tuyệt đối Key mới tạo hoặc HWID mới gán trên RAM trước dữ liệu trễ của GitHub CDN.
    """
    r_meta = _ensure_meta_structure(remote_db.get("meta"))
    l_meta = _ensure_meta_structure(local_db.get("meta"))

    deleted_keys: Dict[str, float] = {}
    for k in set(r_meta["deleted_keys"].keys()) | set(l_meta["deleted_keys"].keys()):
        deleted_keys[k] = max(
            float(r_meta["deleted_keys"].get(k) or 0),
            float(l_meta["deleted_keys"].get(k) or 0),
        )

    deleted_orders: Dict[str, float] = {}
    for oid in set(r_meta["deleted_orders"].keys()) | set(l_meta["deleted_orders"].keys()):
        deleted_orders[oid] = max(
            float(r_meta["deleted_orders"].get(oid) or 0),
            float(l_meta["deleted_orders"].get(oid) or 0),
        )

    used_free_tokens: Dict[str, float] = {
        **r_meta["used_free_tokens"],
        **l_meta["used_free_tokens"],
    }
    merged_vouchers: Dict[str, Any] = {
        **r_meta.get("vouchers", {}),
        **l_meta.get("vouchers", {}),
    }
    merged_blacklist: Dict[str, Any] = {
        **r_meta.get("hwid_blacklist", {}),
        **l_meta.get("hwid_blacklist", {}),
    }

    # Hợp nhất Audit Logs theo ID không trùng lặp
    seen_log_ids: Set[str] = set()
    merged_logs: List[Dict[str, Any]] = []
    for item in list(l_meta.get("audit_logs", [])) + list(r_meta.get("audit_logs", [])):
        if isinstance(item, dict):
            lid = str(item.get("id") or "")
            if lid and lid not in seen_log_ids:
                seen_log_ids.add(lid)
                merged_logs.append(item)
    merged_logs.sort(key=lambda x: float(x.get("time") or 0), reverse=True)

    r_notice_ts = float(r_meta.get("notice_updated_at") or 0)
    l_notice_ts = float(l_meta.get("notice_updated_at") or 0)
    use_local_meta = l_notice_ts >= r_notice_ts

    merged_keys: Dict[str, Dict[str, Any]] = {}
    all_key_ids = set(remote_db.get("keys", {}).keys()) | set(local_db.get("keys", {}).keys())
    for k in all_key_ids:
        rk = remote_db.get("keys", {}).get(k)
        lk = local_db.get("keys", {}).get(k)
        r_ts = float((rk or {}).get("updated_at") or (rk or {}).get("created_at") or 0)
        l_ts = float((lk or {}).get("updated_at") or (lk or {}).get("created_at") or 0)
        best_ts = max(r_ts, l_ts)
        del_ts = float(deleted_keys.get(k) or 0)
        if del_ts > 0 and del_ts >= best_ts:
            continue
        if del_ts > 0 and best_ts > del_ts:
            deleted_keys.pop(k, None)

        if rk and lk:
            winner = copy.deepcopy(lk if l_ts >= r_ts else rk)
            if not normalize_hwid(winner.get("hwid")):
                other = rk if l_ts >= r_ts else lk
                other_hwid = normalize_hwid(other.get("hwid"))
                if other_hwid and float(winner.get("last_hwid_reset") or 0) <= float(
                    other.get("updated_at") or 0
                ):
                    winner["hwid"] = other_hwid
            winner["executions"] = max(
                int(rk.get("executions") or 0), int(lk.get("executions") or 0)
            )
            merged_keys[k] = winner
        elif lk:
            merged_keys[k] = copy.deepcopy(lk)
        elif rk:
            merged_keys[k] = copy.deepcopy(rk)

    merged_orders: Dict[str, Dict[str, Any]] = {}
    all_order_ids = set(remote_db.get("orders", {}).keys()) | set(
        local_db.get("orders", {}).keys()
    )
    for oid in all_order_ids:
        ro = remote_db.get("orders", {}).get(oid)
        lo = local_db.get("orders", {}).get(oid)
        r_ts = float((ro or {}).get("updated_at") or (ro or {}).get("time") or 0)
        l_ts = float((lo or {}).get("updated_at") or (lo or {}).get("time") or 0)
        best_ts = max(r_ts, l_ts)
        del_o_ts = float(deleted_orders.get(oid) or 0)
        if del_o_ts > 0 and del_o_ts >= best_ts:
            continue
        if del_o_ts > 0 and best_ts > del_o_ts:
            deleted_orders.pop(oid, None)

        if ro and lo:
            if lo.get("status") == "paid" and ro.get("status") != "paid":
                merged_orders[oid] = copy.deepcopy(lo)
            elif ro.get("status") == "paid" and lo.get("status") != "paid":
                merged_orders[oid] = copy.deepcopy(ro)
            else:
                merged_orders[oid] = copy.deepcopy(lo if l_ts >= r_ts else ro)
        elif lo:
            merged_orders[oid] = copy.deepcopy(lo)
        elif ro:
            merged_orders[oid] = copy.deepcopy(ro)

    merged_rev = max(
        int(r_meta.get("sync_revision") or 1), int(l_meta.get("sync_revision") or 1)
    )
    merged = {
        "keys": merged_keys,
        "orders": merged_orders,
        "meta": {
            "deleted_keys": deleted_keys,
            "deleted_orders": deleted_orders,
            "used_free_tokens": used_free_tokens,
            "vouchers": merged_vouchers,
            "hwid_blacklist": merged_blacklist,
            "audit_logs": merged_logs[:MAX_AUDIT_LOGS],
            "admin_notice": (
                l_meta["admin_notice"] if use_local_meta else r_meta["admin_notice"]
            ),
            "maintenance": (
                l_meta["maintenance"] if use_local_meta else r_meta["maintenance"]
            ),
            "notice_updated_at": max(r_notice_ts, l_notice_ts),
            "sync_revision": merged_rev,
        },
    }
    cleaned, _ = normalize_and_clean_db(merged)
    return cleaned


def _github_headers() -> Dict[str, str]:
    return {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
    }


async def fetch_github_db(
    force_refresh: bool = False, bypass_write_fence: bool = False
) -> Tuple[Dict[str, Any], Optional[str]]:
    """
    Đọc Database với bảo vệ Write-Fence RYOW:
    - Nếu Server vừa thực hiện lệnh Ghi trong vòng `WRITE_FENCE_SECONDS` (30 giây) hoặc đang `dirty`,
      RAM hiện tại chính là bản mới nhất (Authoritative State) -> Trả ngay lập tức trong 0ms!
    """
    now = time.time()
    recent_mutation = (
        now - float(DB_CACHE.get("last_mutation_ts") or 0)
    ) < WRITE_FENCE_SECONDS

    if not bypass_write_fence and DB_CACHE["data"].get("keys") is not None:
        if (
            recent_mutation
            or DB_CACHE.get("dirty")
            or (not force_refresh and (now - DB_CACHE["last_fetch"] < CACHE_TTL_SECONDS))
        ):
            db_data, _ = normalize_and_clean_db(DB_CACHE["data"])
            return db_data, DB_CACHE.get("last_pushed_sha") or DB_CACHE.get("sha")

    if not GITHUB_TOKEN or not GITHUB_REPO:
        db_data, _ = normalize_and_clean_db(DB_CACHE["data"])
        DB_CACHE["data"] = db_data
        DB_CACHE["last_fetch"] = now
        _save_local_disk_backup(db_data)
        return db_data, DB_CACHE["sha"]

    url = (
        f"https://api.github.com/repos/{GITHUB_REPO}/contents/{GITHUB_PATH}"
        f"?_t={int(now * 1000)}"
    )
    try:
        client = await _get_http_client()
        res = await client.get(url, headers=_github_headers())
        if res.status_code == 200:
            content = res.json()
            remote_sha = content.get("sha")
            raw_json = base64.b64decode(content["content"]).decode("utf-8")
            remote_data = json.loads(raw_json)
            remote_clean, _ = normalize_and_clean_db(remote_data)

            merged_data = _merge_db_states(remote_clean, DB_CACHE["data"])
            DB_CACHE["data"] = merged_data

            last_pushed_sha = DB_CACHE.get("last_pushed_sha")
            last_push_ts = float(DB_CACHE.get("last_push_ts") or 0)
            if (
                last_pushed_sha
                and remote_sha != last_pushed_sha
                and (now - last_push_ts < 60)
            ):
                effective_sha = last_pushed_sha
            else:
                effective_sha = remote_sha

            DB_CACHE["sha"] = effective_sha
            DB_CACHE["last_fetch"] = now
            _save_local_disk_backup(merged_data)
            return merged_data, effective_sha
        elif res.status_code == 404:
            db_data, _ = normalize_and_clean_db(DB_CACHE["data"])
            DB_CACHE["data"] = db_data
            DB_CACHE["last_fetch"] = now
            _save_local_disk_backup(db_data)
            return db_data, None
        else:
            logger.warning(
                f"GitHub Fetch HTTP {res.status_code}: Sử dụng RAM Authoritative Cache."
            )
    except Exception as e:
        logger.error(f"GitHub Fetch Error: {e}")

    db_data, _ = normalize_and_clean_db(DB_CACHE["data"])
    return db_data, DB_CACHE.get("last_pushed_sha") or DB_CACHE.get("sha")


async def commit_db_mutation(
    data: Dict[str, Any],
    sha: Optional[str],
    sync_immediately: bool = True,
    event_name: str = "db_updated",
    event_info: Optional[Dict[str, Any]] = None,
) -> bool:
    """
    Cam kết thay đổi dữ liệu (Mutation Commit V27.0):
    1. Tăng `sync_revision` và cập nhật `last_mutation_ts` ngay lập tức.
    2. Chuẩn hóa & đánh lại chỉ mục RAM O(1) (`rebuild_memory_indexes`).
    3. Ghi xuống đĩa cục bộ (`biva_db_local.json`).
    4. Phát sóng sự kiện Real-time SSE (`broadcast_sse_event`) tới Web Shop & Admin.
    5. Đẩy lên GitHub Cloud.
    """
    now = time.time()
    meta = _ensure_meta_structure(data.get("meta"))
    meta["sync_revision"] = (
        max(int(DB_CACHE.get("revision") or 1), int(meta.get("sync_revision") or 1)) + 1
    )
    data["meta"] = meta

    clean_data, _ = normalize_and_clean_db(data)
    DB_CACHE["data"] = clean_data
    DB_CACHE["last_fetch"] = now
    DB_CACHE["last_mutation_ts"] = now
    DB_CACHE["revision"] = meta["sync_revision"]
    DB_CACHE["dirty"] = True
    _save_local_disk_backup(clean_data)

    broadcast_sse_event(event_name, event_info or {})

    if not GITHUB_TOKEN or not GITHUB_REPO:
        DB_CACHE["dirty"] = False
        return True

    if sync_immediately:
        return await push_github_db(clean_data, sha)
    return True


async def push_github_db(
    data: Dict[str, Any],
    sha: Optional[str],
    retries: int = 4,
    from_background: bool = False,
) -> bool:
    if not from_background:
        now = time.time()
        meta = _ensure_meta_structure(data.get("meta"))
        meta["sync_revision"] = (
            max(int(DB_CACHE.get("revision") or 1), int(meta.get("sync_revision") or 1))
            + 1
        )
        data["meta"] = meta
        clean_data, _ = normalize_and_clean_db(data)
        DB_CACHE["data"] = clean_data
        DB_CACHE["last_fetch"] = now
        DB_CACHE["last_mutation_ts"] = now
        DB_CACHE["revision"] = meta["sync_revision"]
        _save_local_disk_backup(clean_data)
    else:
        clean_data, _ = normalize_and_clean_db(data)

    if not GITHUB_TOKEN or not GITHUB_REPO:
        DB_CACHE["dirty"] = False
        return True

    base_url = f"https://api.github.com/repos/{GITHUB_REPO}/contents/{GITHUB_PATH}"
    current_sha = sha or DB_CACHE.get("last_pushed_sha") or DB_CACHE.get("sha")
    current_data = clean_data

    for attempt in range(retries):
        try:
            json_str = json.dumps(current_data, indent=2, ensure_ascii=False)
            b64_content = base64.b64encode(json_str.encode("utf-8")).decode("utf-8")
            rev_num = current_data.get("meta", {}).get("sync_revision", 1)
            payload: Dict[str, Any] = {
                "message": (
                    f"BIVA STORM V27.0 Sync r{rev_num} "
                    f"({format_vn_time(time.time(), '%H:%M:%S %d/%m')})"
                ),
                "content": b64_content,
            }
            if current_sha:
                payload["sha"] = current_sha

            client = await _get_http_client()
            res = await client.put(base_url, headers=_github_headers(), json=payload)

            if res.status_code in (200, 201):
                new_sha = res.json().get("content", {}).get("sha")
                now_curr = time.time()
                if new_sha:
                    DB_CACHE["sha"] = new_sha
                    DB_CACHE["last_pushed_sha"] = new_sha
                    DB_CACHE["last_push_ts"] = now_curr
                merged_latest = _merge_db_states(current_data, DB_CACHE["data"])
                DB_CACHE["data"] = merged_latest
                DB_CACHE["last_fetch"] = now_curr
                DB_CACHE["dirty"] = False
                _save_local_disk_backup(merged_latest)
                return True

            if res.status_code in (409, 422):
                logger.warning(
                    f"GitHub SHA conflict (attempt {attempt + 1}), đang tự động hợp nhất CRDT..."
                )
                get_res = await client.get(
                    f"{base_url}?_t={int(time.time() * 1000)}",
                    headers=_github_headers(),
                )
                if get_res.status_code == 200:
                    remote_json = get_res.json()
                    current_sha = remote_json.get("sha")
                    remote_raw = base64.b64decode(remote_json["content"]).decode("utf-8")
                    remote_db, _ = normalize_and_clean_db(json.loads(remote_raw))
                    current_data = _merge_db_states(remote_db, DB_CACHE["data"])
                    DB_CACHE["data"] = current_data
                    DB_CACHE["sha"] = current_sha
                    _save_local_disk_backup(current_data)
                await asyncio.sleep(0.3 * (attempt + 1))
                continue

            logger.error(f"GitHub Push Error ({res.status_code}): {res.text[:200]}")
        except Exception as e:
            logger.error(f"GitHub Push Exception (attempt {attempt + 1}): {e}")
        await asyncio.sleep(0.3 * (attempt + 1))

    DB_CACHE["dirty"] = True
    return False


# ==============================================================================
# 7. PYDANTIC MODELS DỮ LIỆU ĐẦU VÀO
# ==============================================================================
class FreeKeyRequest(BaseModel):
    hwid: str
    game: str = "rb"


class OrderRequest(BaseModel):
    game: str = "rb"
    package: str
    hwid: str
    price: Optional[int] = None
    voucher: Optional[str] = ""


class SelfResetHwidRequest(BaseModel):
    key: str = Field(..., min_length=1, max_length=64)


class VerifyKeyPostRequest(BaseModel):
    key: str = Field(default="", max_length=64)
    hwid: str = Field(default="", max_length=64)
    auto_bind: bool = True


class TelemetryReportRequest(BaseModel):
    key: str = Field(default="", max_length=64)
    hwid: str = Field(default="", max_length=64)
    game_id: str = Field(default="steal_egg", max_length=64)
    executor: str = Field(default="Unknown", max_length=64)
    place_id: int = 0
    job_id: str = Field(default="", max_length=64)


class AdminCreateKeyRequest(BaseModel):
    token: Optional[str] = None
    game: str = "rb"
    hwid: Optional[str] = ""
    hours: float = Field(default=24, gt=0, le=876000)
    prefix: Optional[str] = None
    package: Optional[str] = None
    note: Optional[str] = Field(default="", max_length=120)
    amount: int = Field(default=1, ge=1, le=50)


class AdminExtendKeyRequest(BaseModel):
    token: Optional[str] = None
    key: Optional[str] = None
    hours: float = Field(default=24, gt=0, le=876000)
    all_active: bool = False


class AdminBindHwidRequest(BaseModel):
    token: Optional[str] = None
    key: str
    hwid: str = Field(default="", max_length=96)


class AdminUpdateNoteRequest(BaseModel):
    token: Optional[str] = None
    key: str
    note: str = Field(default="", max_length=120)


class AdminToggleBanRequest(BaseModel):
    token: Optional[str] = None
    key: str
    is_banned: Optional[bool] = None


class AdminDeleteRequest(BaseModel):
    token: Optional[str] = None
    key: Optional[str] = None
    order_id: Optional[str] = None


class AdminBroadcastRequest(BaseModel):
    notice: str = Field(..., min_length=1, max_length=280)
    maintenance: bool = Field(default=False)


class AdminVoucherRequest(BaseModel):
    code: str = Field(..., min_length=2, max_length=32)
    discount_percent: int = Field(default=10, ge=1, le=90)
    bonus_hours: float = Field(default=0, ge=0, le=8760)
    max_uses: int = Field(default=100, ge=1, le=10000)


class AdminBlacklistHwidRequest(BaseModel):
    hwid: str = Field(..., min_length=2, max_length=64)
    reason: str = Field(default="Vi phạm điều khoản sử dụng", max_length=120)
    ban: bool = True


# ==============================================================================
# 8. HÀM DỰNG SNAPSHOT & TÌM KIẾM ĐA CHIỀU O(1)
# ==============================================================================
def build_admin_snapshot(db: Dict[str, Any]) -> Dict[str, Any]:
    now = time.time()
    today_str = format_vn_time(now, "%Y-%m-%d")
    meta = _ensure_meta_structure(db.get("meta"))

    active_keys = 0
    expired_keys = 0
    free_keys = 0
    paid_keys = 0
    banned_keys = 0
    total_executions = 0

    keys_snapshot = copy.deepcopy(db.get("keys", {}))
    orders_snapshot = copy.deepcopy(db.get("orders", {}))

    for k, v in keys_snapshot.items():
        exp = float(v.get("expire") or 0)
        is_banned = bool(v.get("is_banned", False))
        bound = normalize_hwid(v.get("hwid"))
        v["key_code"] = k
        v["hwid"] = bound
        v["is_bound"] = bool(bound)
        v["note"] = str(v.get("note") or "")
        v["is_banned"] = is_banned
        v["tier_label"] = get_key_tier_label(v)
        v["expire_str"] = format_vn_time(exp)
        v["time_left"] = format_remaining_time(exp, now)
        v["is_expired"] = now > exp
        total_executions += int(v.get("executions") or 0)
        if is_banned:
            banned_keys += 1
        if not v["is_expired"] and not is_banned:
            active_keys += 1
            if v.get("type") == "free":
                free_keys += 1
            else:
                paid_keys += 1
        elif v["is_expired"]:
            expired_keys += 1

    total_revenue = 0
    today_revenue = 0
    paid_orders = 0
    pending_orders = 0

    for oid, o in orders_snapshot.items():
        issued = o.get("key") or o.get("key_code")
        order_ts = float(o.get("time") or 0)
        o["order_id"] = oid
        o["key"] = issued
        o["key_code"] = issued
        o["hwid"] = normalize_hwid(o.get("hwid"))
        o["time_str"] = format_vn_time(order_ts)
        if o.get("status") == "paid":
            paid_orders += 1
            price_val = int(o.get("price") or 0)
            total_revenue += price_val
            paid_ts = float(o.get("paid_at") or order_ts)
            if format_vn_time(paid_ts, "%Y-%m-%d") == today_str:
                today_revenue += price_val
        else:
            pending_orders += 1

    return {
        "stats": {
            "total_revenue": total_revenue,
            "today_revenue": today_revenue,
            "total_keys": len(keys_snapshot),
            "active_keys": active_keys,
            "expired_keys": expired_keys,
            "banned_keys": banned_keys,
            "free_keys": free_keys,
            "paid_keys": paid_keys,
            "paid_orders": paid_orders,
            "pending_orders": pending_orders,
            "total_executions": total_executions,
            "blacklisted_hwids": len(meta.get("hwid_blacklist", {})),
            "active_vouchers": len(meta.get("vouchers", {})),
            "dirty_sync": bool(DB_CACHE.get("dirty")),
            "sync_revision": int(meta.get("sync_revision") or 1),
            "server_time": format_vn_time(now, "%H:%M:%S %d/%m/%Y"),
            "version": APP_VERSION,
            "admin_notice": meta.get("admin_notice") or DEFAULT_ADMIN_NOTICE,
            "maintenance": bool(meta.get("maintenance")),
            "payos_mode": payment_gateway_mode(),
        },
        "orders": orders_snapshot,
        "keys": keys_snapshot,
        "vouchers": meta.get("vouchers", {}),
        "hwid_blacklist": meta.get("hwid_blacklist", {}),
        "audit_logs": meta.get("audit_logs", [])[:50],
    }


def _find_key_in_db(
    db: Dict[str, Any], raw_key: str
) -> Tuple[str, Optional[Dict[str, Any]]]:
    k_clean = normalize_key(raw_key)
    if not k_clean:
        return "", None
    keys_map = db.get("keys", {})
    if k_clean in keys_map:
        return k_clean, keys_map[k_clean]

    compact_q = compact_alnum(k_clean)
    if len(compact_q) >= 6:
        indexed_k = MEMORY_INDEX.get("by_compact_key", {}).get(compact_q)
        if indexed_k and indexed_k in keys_map:
            return indexed_k, keys_map[indexed_k]
        for k, v in keys_map.items():
            if compact_alnum(k) == compact_q:
                return k, v
    return k_clean, None


def _format_key_entry_for_client(
    k: str, v: Dict[str, Any], now: float
) -> Dict[str, Any]:
    bound = normalize_hwid(v.get("hwid"))
    exp = float(v.get("expire") or 0)
    is_exp = now > exp
    is_banned = bool(v.get("is_banned", False))
    cooldown = (
        SELF_RESET_COOLDOWN_FREE
        if v.get("type") == "free"
        else SELF_RESET_COOLDOWN_PAID
    )
    last_reset = float(v.get("last_hwid_reset") or 0)
    reset_wait = max(0, int((last_reset + cooldown) - now))
    can_reset = bool(bound) and (reset_wait == 0) and (not is_exp) and (not is_banned)
    return {
        "key": k,
        "key_code": k,
        "game": v.get("game", "rb"),
        "package": v.get("package", "VIP"),
        "type": v.get("type", "paid"),
        "note": str(v.get("note") or ""),
        "tier_label": get_key_tier_label(v),
        "hwid": bound or "Chưa khóa máy",
        "bound_hwid": bound or "Chưa khóa máy",
        "is_bound": bool(bound),
        "expire": exp,
        "expire_str": format_vn_time(exp),
        "time_left": format_remaining_time(exp, now),
        "is_expired": is_exp,
        "is_banned": is_banned,
        "executions": int(v.get("executions") or 0),
        "can_self_reset": can_reset,
        "reset_cooldown_seconds": reset_wait,
        "reset_cooldown_left": (
            format_remaining_time(now + reset_wait, now)
            if reset_wait > 0
            else "Sẵn sàng"
        ),
    }


def _collect_matching_keys(
    db: Dict[str, Any], raw_query: str, now: float
) -> List[Dict[str, Any]]:
    hwid_clean = normalize_hwid(raw_query)
    key_query = normalize_key(raw_query)
    compact_q = compact_alnum(raw_query)
    keys_map = db.get("keys", {})
    orders_map = db.get("orders", {})

    matched_key_codes: Set[str] = set()

    # 1. Khớp trực tiếp theo Key hoặc Compact Key từ Index O(1)
    if key_query in keys_map:
        matched_key_codes.add(key_query)
    if len(compact_q) >= 6:
        ck_hit = MEMORY_INDEX.get("by_compact_key", {}).get(compact_q)
        if ck_hit and ck_hit in keys_map:
            matched_key_codes.add(ck_hit)

    # 2. Khớp theo HWID chuẩn hóa & Compact HWID từ Index O(1)
    if hwid_clean:
        for k_hit in MEMORY_INDEX.get("by_hwid", {}).get(hwid_clean, set()):
            if k_hit in keys_map:
                matched_key_codes.add(k_hit)
    if len(compact_q) >= 4:
        for k_hit in MEMORY_INDEX.get("by_compact_hwid", {}).get(compact_q, set()):
            if k_hit in keys_map:
                matched_key_codes.add(k_hit)

    # 3. Khớp bắc cầu qua Mã Đơn Hàng (BIVAxxxxxx)
    if key_query in orders_map:
        ord_obj = orders_map[key_query]
        ord_k = normalize_key(ord_obj.get("key") or ord_obj.get("key_code"))
        ord_hwid = normalize_hwid(ord_obj.get("hwid"))
        if ord_k and ord_k in keys_map:
            matched_key_codes.add(ord_k)
        if ord_hwid:
            for k_hit in MEMORY_INDEX.get("by_hwid", {}).get(ord_hwid, set()):
                if k_hit in keys_map:
                    matched_key_codes.add(k_hit)

    # 4. Quét vét cạn dự phòng (Fallback Scan) để đảm bảo không sót bất kỳ trường hợp nào
    for k, v in keys_map.items():
        if k in matched_key_codes:
            continue
        bound = normalize_hwid(v.get("hwid"))
        order_id_val = str(v.get("order_id") or "").upper()
        if (
            (bound and bound == hwid_clean)
            or (k == key_query)
            or (
                len(compact_q) >= 6
                and (
                    compact_alnum(k) == compact_q
                    or (bound and compact_alnum(bound) == compact_q)
                )
            )
            or (order_id_val and order_id_val == key_query)
        ):
            matched_key_codes.add(k)

    found = [
        _format_key_entry_for_client(k, keys_map[k], now)
        for k in matched_key_codes
        if k in keys_map
    ]
    found.sort(
        key=lambda x: (not x["is_expired"], not x["is_banned"], x["expire"]),
        reverse=True,
    )
    return found


def _collect_matching_orders(
    db: Dict[str, Any], raw_query: str
) -> List[Dict[str, Any]]:
    hwid_clean = normalize_hwid(raw_query)
    upper_query = normalize_key(raw_query)
    compact_q = compact_alnum(raw_query)
    user_orders: List[Dict[str, Any]] = []
    seen_keys: Set[str] = set()

    for oid, o in db.get("orders", {}).items():
        issued = normalize_key(o.get("key") or o.get("key_code")) or None
        order_hwid = normalize_hwid(o.get("hwid"))
        if (
            (order_hwid and order_hwid == hwid_clean)
            or (
                len(compact_q) >= 4
                and order_hwid
                and compact_alnum(order_hwid) == compact_q
            )
            or oid == upper_query
            or (issued and issued == upper_query)
            or (len(compact_q) >= 6 and issued and compact_alnum(issued) == compact_q)
        ):
            order_ts = float(o.get("time") or 0)
            if issued:
                seen_keys.add(issued)
            user_orders.append(
                {
                    "order_id": oid,
                    "game": o.get("game", "rb"),
                    "package": o.get("package", "VIP"),
                    "price": o.get("price", 0),
                    "status": o.get("status", "pending"),
                    "key": issued,
                    "key_code": issued,
                    "hwid": order_hwid,
                    "time": order_ts,
                    "time_str": format_vn_time(order_ts),
                }
            )

    # Hiển thị đồng bộ cả các Key tạo từ Admin hoặc Key Free vào lịch sử giao dịch
    for k, v in db.get("keys", {}).items():
        if k in seen_keys:
            continue
        bound = normalize_hwid(v.get("hwid"))
        if (
            (bound and bound == hwid_clean)
            or (len(compact_q) >= 4 and bound and compact_alnum(bound) == compact_q)
            or k == upper_query
            or (len(compact_q) >= 6 and compact_alnum(k) == compact_q)
        ):
            c_ts = float(v.get("created_at") or v.get("updated_at") or time.time())
            k_type = str(v.get("type") or "admin").lower()
            synthetic_oid = str(
                v.get("order_id")
                or ("FREE-LINK" if k_type == "free" else "ADMIN-GRANT")
            )
            pkg_name = str(v.get("package") or "VIP")
            pkg_price = (
                PACKAGE_CONFIG.get(pkg_name, {}).get("price", 0)
                if k_type == "paid"
                else 0
            )
            user_orders.append(
                {
                    "order_id": synthetic_oid,
                    "game": v.get("game", "rb"),
                    "package": pkg_name,
                    "price": pkg_price,
                    "status": "paid",
                    "key": k,
                    "key_code": k,
                    "hwid": bound,
                    "time": c_ts,
                    "time_str": format_vn_time(c_ts),
                }
            )

    user_orders.sort(key=lambda x: x["time"], reverse=True)
    return user_orders


# ==============================================================================
# 9. CẤP KEY NGUYÊN TỬ CHO ĐƠN HÀNG PAYOS (ATOMIC ORDER FULFILLMENT)
# ==============================================================================
async def fulfill_order_atomic(order_id: str, actor: str = "PayOS") -> str:
    oid_clean = str(order_id).strip().upper()
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        if oid_clean not in db["orders"]:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng!")

        order = db["orders"][oid_clean]
        existing_key = normalize_key(order.get("key") or order.get("key_code"))
        if (
            order.get("status") == "paid"
            and existing_key
            and existing_key in db["keys"]
        ):
            return existing_key

        pkg_name = str(order.get("package") or "1 Ngày")
        pkg_info = PACKAGE_CONFIG.get(pkg_name, {"days": 1, "duration": 86400})
        dur = pkg_info.get("duration") or (pkg_info.get("days", 1) * 86400)
        bonus_sec = float(order.get("bonus_hours") or 0) * 3600

        game_code = str(order.get("game") or "RB").strip()
        new_key = existing_key or generate_key(game_code.upper())
        while new_key in db["keys"] and not existing_key:
            new_key = generate_key(game_code.upper())

        now = time.time()
        hwid_upper = normalize_hwid(order.get("hwid"))
        tombstones = db.setdefault("meta", {}).setdefault("deleted_keys", {})
        tombstones.pop(new_key, None)

        db["keys"][new_key] = {
            "key_code": new_key,
            "game": game_code.lower(),
            "hwid": hwid_upper,
            "expire": now + dur + bonus_sec,
            "created_at": now,
            "updated_at": now,
            "type": "paid",
            "package": pkg_name,
            "order_id": oid_clean,
            "note": f"Đơn {oid_clean}",
            "is_banned": False,
            "executions": 0,
        }

        db["orders"][oid_clean]["status"] = "paid"
        db["orders"][oid_clean]["key"] = new_key
        db["orders"][oid_clean]["key_code"] = new_key
        db["orders"][oid_clean]["paid_at"] = now
        db["orders"][oid_clean]["updated_at"] = now

        append_audit_log(
            db,
            action="FULFILL_ORDER",
            actor=actor,
            target=new_key,
            detail=f"Đơn {oid_clean} ({pkg_name}) -> HWID: {hwid_upper or 'Tự Do'}",
        )

        await commit_db_mutation(
            db,
            sha,
            sync_immediately=True,
            event_name="order_paid",
            event_info={"order_id": oid_clean, "key": new_key, "hwid": hwid_upper},
        )
        return new_key


@app.post("/api/payos_webhook")
async def payos_webhook(request: Request):
    check_rate_limit(request, limit=120, window=60, scope="payos_webhook")
    try:
        body = await request.json()
        if not isinstance(body, dict):
            return {"success": True}

        data = body.get("data") if isinstance(body.get("data"), dict) else body
        raw_order_code = data.get("orderCode") or body.get("orderCode")

        if raw_order_code in (None, 123, "123"):
            return {"success": True}

        if PAYOS_CHECKSUM_KEY and not verify_payos_webhook_signature(
            body, PAYOS_CHECKSUM_KEY
        ):
            logger.warning("PayOS Webhook bị từ chối do chữ ký HMAC không khớp!")
            return JSONResponse(
                {"success": False, "message": "Invalid signature"}, status_code=403
            )

        try:
            order_code_int = int(raw_order_code)
        except (ValueError, TypeError):
            return {"success": True}

        status = str(data.get("status") or body.get("status") or "").upper()
        code = str(body.get("code") or data.get("code") or "").strip()
        desc = str(body.get("desc") or data.get("desc") or "").lower()
        is_success = (
            body.get("success") is True
            or status == "PAID"
            or code == "00"
            or desc in ("success", "thanh cong", "thành công")
        )

        if is_success:
            db, _ = await fetch_github_db(force_refresh=True)
            target_oid: Optional[str] = None

            candidate_oid = f"BIVA{order_code_int}"
            if candidate_oid in db["orders"]:
                target_oid = candidate_oid
            else:
                for oid, order in db["orders"].items():
                    try:
                        if int(order.get("payos_code") or 0) == order_code_int:
                            target_oid = oid
                            break
                    except (ValueError, TypeError):
                        continue

            if not target_oid:
                return {"success": True}

            target_order = db["orders"][target_oid]
            expected_price = int(target_order.get("price") or 0)
            webhook_amount = data.get("amount")
            if webhook_amount is not None:
                try:
                    if int(webhook_amount) < expected_price:
                        logger.warning(
                            f"PayOS Webhook số tiền không đủ cho đơn {target_oid}"
                        )
                        return {"success": False, "message": "Insufficient amount"}
                except (ValueError, TypeError):
                    pass

            confirmed = await gateway_payment_confirmed(order_code_int)
            verified = True if confirmed is None else bool(confirmed)

            if verified:
                await fulfill_order_atomic(target_oid, actor="PayOS_Webhook")

        return {"success": True}
    except Exception as e:
        logger.error(f"PayOS webhook error: {e}")
        return {"success": False}


# ==============================================================================
# 10. PUBLIC APIS V27.0 HYPERION (WEB SHOP, SSE STREAM & ROBLOX LOADER OMNI SYNC)
# ==============================================================================
@app.get("/api/health")
async def health_check():
    meta = _ensure_meta_structure(DB_CACHE["data"].get("meta"))
    return {
        "success": True,
        "status": "ok",
        "version": APP_VERSION,
        "uptime_seconds": int(time.time() - SERVER_START_TIME),
        "dirty_sync": bool(DB_CACHE.get("dirty")),
        "sync_revision": int(meta.get("sync_revision") or 1),
        "indexed_keys": len(MEMORY_INDEX.get("by_compact_key", {})),
        "indexed_hwids": len(MEMORY_INDEX.get("by_hwid", {})),
        "payos_mode": payment_gateway_mode(),
    }


@app.get("/api/events")
async def sse_events_stream(request: Request):
    """
    Kênh Server-Sent Events (SSE) thời gian thực:
    Đẩy thông báo biến động `sync_revision` tức thì tới trình duyệt mà không cần chờ polling.
    """
    q: asyncio.Queue = asyncio.Queue(maxsize=25)
    SSE_SUBSCRIBERS.add(q)

    async def event_generator() -> AsyncGenerator[str, None]:
        try:
            init_payload = {
                "event": "connected",
                "revision": int(DB_CACHE.get("revision") or 1),
                "ts": int(time.time() * 1000),
            }
            yield f"data: {json.dumps(init_payload)}\n\n"
            while True:
                if await request.is_disconnected():
                    break
                try:
                    msg = await asyncio.wait_for(q.get(), timeout=15.0)
                    yield f"data: {json.dumps(msg, ensure_ascii=False)}\n\n"
                except asyncio.TimeoutError:
                    ping_msg = {
                        "event": "heartbeat",
                        "revision": int(DB_CACHE.get("revision") or 1),
                        "ts": int(time.time() * 1000),
                    }
                    yield f"data: {json.dumps(ping_msg)}\n\n"
        finally:
            SSE_SUBSCRIBERS.discard(q)

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@app.get("/api/games")
async def get_supported_games():
    return {
        "success": True,
        "version": APP_VERSION,
        "games": SUPPORTED_GAMES_CATALOG,
    }


@app.get("/api/public_stats")
@app.get("/api/status")
async def public_stats(request: Request):
    check_rate_limit(request, limit=120, window=60)
    db, _ = await fetch_github_db(force_refresh=False)
    now = time.time()
    active_keys = sum(
        1
        for v in db["keys"].values()
        if float(v.get("expire") or 0) > now and not bool(v.get("is_banned", False))
    )
    meta = _ensure_meta_structure(db.get("meta"))
    return {
        "success": True,
        "active_keys": active_keys,
        "version": APP_VERSION,
        "server_time": format_vn_time(now, "%H:%M:%S %d/%m/%Y"),
        "admin_notice": meta.get("admin_notice") or DEFAULT_ADMIN_NOTICE,
        "maintenance": bool(meta.get("maintenance")),
        "sync_revision": int(meta.get("sync_revision") or 1),
        "payos_mode": payment_gateway_mode(),
    }


@app.get("/api/omni_sync")
async def omni_sync_endpoint(
    request: Request,
    hwid: str = "",
    key: str = "",
    order_id: str = "",
    fresh: int = 0,
):
    """
    API Hợp Nhất V27.0 HYPERION:
    Chỉ với 1 request duy nhất, trả về toàn bộ trạng thái đồng bộ của thiết bị (HWID / Key / Đơn hàng / Broadcast).
    Hỗ trợ trực tiếp cho cả Web Shop và Roblox Loader.
    """
    check_rate_limit(request, limit=100, window=60)
    db, _ = await fetch_github_db(force_refresh=bool(fresh))
    now = time.time()
    meta = _ensure_meta_structure(db.get("meta"))

    hwid_clean = normalize_hwid(hwid)
    key_clean = normalize_key(key)
    order_clean = str(order_id or "").strip().upper()

    # Hợp nhất kết quả từ cả HWID, Key và Order ID nếu client gửi đồng thời
    seen_k: Set[str] = set()
    keys_found: List[Dict[str, Any]] = []
    for q_target in (hwid_clean, key_clean, order_clean):
        if q_target:
            for item in _collect_matching_keys(db, q_target, now):
                if item["key"] not in seen_k:
                    seen_k.add(item["key"])
                    keys_found.append(item)

    keys_found.sort(
        key=lambda x: (not x["is_expired"], not x["is_banned"], x["expire"]),
        reverse=True,
    )

    seen_o: Set[str] = set()
    orders_found: List[Dict[str, Any]] = []
    for q_target in (hwid_clean, key_clean, order_clean):
        if q_target:
            for o_item in _collect_matching_orders(db, q_target):
                uid = f"{o_item['order_id']}:{o_item.get('key_code') or ''}"
                if uid not in seen_o:
                    seen_o.add(uid)
                    orders_found.append(o_item)

    best_active_key: Optional[Dict[str, Any]] = None
    for k_item in keys_found:
        if not k_item["is_expired"] and not k_item["is_banned"]:
            best_active_key = k_item
            break

    is_blacklisted = bool(
        hwid_clean and hwid_clean in meta.get("hwid_blacklist", {})
    )

    return {
        "success": True,
        "version": APP_VERSION,
        "sync_revision": int(meta.get("sync_revision") or 1),
        "server_time": format_vn_time(now, "%H:%M:%S %d/%m/%Y"),
        "admin_notice": meta.get("admin_notice") or DEFAULT_ADMIN_NOTICE,
        "maintenance": bool(meta.get("maintenance")),
        "is_blacklisted": is_blacklisted,
        "best_key": best_active_key,
        "keys": keys_found,
        "orders": orders_found,
        "games": SUPPORTED_GAMES_CATALOG,
    }


@app.get("/api/check_voucher")
async def check_voucher_endpoint(code: str = "", package: str = "1 Ngày"):
    clean_code = normalize_key(code)
    if not clean_code:
        return {"success": False, "message": "Vui lòng nhập mã giảm giá!"}
    db, _ = await fetch_github_db(force_refresh=False)
    meta = _ensure_meta_structure(db.get("meta"))
    vouchers = meta.get("vouchers", {})
    v_obj = vouchers.get(clean_code)
    if not isinstance(v_obj, dict):
        return {"success": False, "message": "Mã giảm giá không tồn tại hoặc đã hết lượt!"}
    used = int(v_obj.get("used") or 0)
    max_uses = int(v_obj.get("max_uses") or 100)
    if used >= max_uses:
        return {"success": False, "message": "Mã giảm giá này đã hết lượt sử dụng!"}
    discount_pct = max(0, min(90, int(v_obj.get("discount_percent") or 0)))
    bonus_hours = float(v_obj.get("bonus_hours") or 0)
    base_price = PACKAGE_CONFIG.get(package, {"price": 15000})["price"]
    final_price = max(2000, int(base_price * (100 - discount_pct) / 100))
    return {
        "success": True,
        "code": clean_code,
        "discount_percent": discount_pct,
        "bonus_hours": bonus_hours,
        "base_price": base_price,
        "final_price": final_price,
        "message": f"Áp dụng mã {clean_code}: Giảm {discount_pct}% + Tặng thêm {int(bonus_hours)}h!",
    }


@app.post("/api/create_order")
@app.get("/api/create_order")
async def create_order(
    request: Request,
    req: Optional[OrderRequest] = None,
    game: str = "rb",
    package: str = "1 Ngày",
    hwid: str = "",
    voucher: str = "",
    price: Optional[int] = None,
):
    """Hỗ trợ tạo đơn QR từ cả Web Shop (POST JSON) và trực tiếp từ Menu Roblox Loader (GET/POST)."""
    check_rate_limit(request, limit=25, window=60)
    raw_hwid = req.hwid if req else hwid
    raw_pkg = req.package if req else package
    raw_game = req.game if req else game
    raw_voucher = (req.voucher if req else voucher) or ""

    hwid_clean = normalize_hwid(raw_hwid)
    if not hwid_clean:
        raise HTTPException(
            status_code=400, detail="Vui lòng nhập Mã Máy (HWID) hợp lệ!"
        )
    if raw_pkg not in PACKAGE_CONFIG or PACKAGE_CONFIG[raw_pkg]["price"] <= 0:
        raise HTTPException(status_code=400, detail="Gói bản quyền không hợp lệ!")

    official_price = PACKAGE_CONFIG[raw_pkg]["price"]
    bonus_hours = 0.0
    applied_voucher = ""

    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        meta = _ensure_meta_structure(db.get("meta"))

        if hwid_clean in meta.get("hwid_blacklist", {}):
            raise HTTPException(
                status_code=403,
                detail="Thiết bị (HWID) này đang nằm trong danh sách hạn chế!",
            )

        clean_v_code = normalize_key(raw_voucher)
        if clean_v_code and clean_v_code in meta.get("vouchers", {}):
            v_obj = meta["vouchers"][clean_v_code]
            if int(v_obj.get("used") or 0) < int(v_obj.get("max_uses") or 100):
                pct = max(0, min(90, int(v_obj.get("discount_percent") or 0)))
                official_price = max(2000, int(official_price * (100 - pct) / 100))
                bonus_hours = float(v_obj.get("bonus_hours") or 0)
                v_obj["used"] = int(v_obj.get("used") or 0) + 1
                applied_voucher = clean_v_code

        order_id_int = random.randint(100000, 999999)
        order_id_str = f"BIVA{order_id_int}"
        while order_id_str in db["orders"]:
            order_id_int = random.randint(100000, 999999)
            order_id_str = f"BIVA{order_id_int}"

        payos_res = await gateway_create_payment(
            order_id_int, official_price, order_id_str
        )
        if not isinstance(payos_res, dict) or not payos_res.get("success"):
            raise HTTPException(
                status_code=400,
                detail="Không thể tạo mã QR thanh toán PayOS lúc này!",
            )

        now = time.time()
        db["orders"][order_id_str] = {
            "order_id": order_id_str,
            "game": (raw_game or "rb").strip().lower(),
            "package": raw_pkg,
            "hwid": hwid_clean,
            "price": official_price,
            "bonus_hours": bonus_hours,
            "voucher": applied_voucher,
            "status": "pending",
            "key": None,
            "key_code": None,
            "time": now,
            "updated_at": now,
            "payos_code": order_id_int,
        }
        await commit_db_mutation(
            db,
            sha,
            sync_immediately=True,
            event_name="order_created",
            event_info={"order_id": order_id_str, "hwid": hwid_clean},
        )
        return {
            "success": True,
            "order_id": order_id_str,
            "qr_url": payos_res["qr_url"],
            "qr_raw": payos_res.get("qr_raw", ""),
            "price": official_price,
            "bonus_hours": bonus_hours,
            "voucher": applied_voucher,
            "package": raw_pkg,
            "hwid": hwid_clean,
            "checkout_url": payos_res.get("checkout_url", ""),
        }


@app.get("/api/check_order")
async def check_order(order_id: str, request: Request):
    check_rate_limit(request, limit=75, window=60)
    oid_clean = str(order_id).strip().upper()
    if not oid_clean:
        raise HTTPException(status_code=400, detail="Mã đơn hàng không hợp lệ!")

    db, _ = await fetch_github_db(force_refresh=False)
    if oid_clean not in db["orders"]:
        db, _ = await fetch_github_db(force_refresh=True)
        if oid_clean not in db["orders"]:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng!")

    order = db["orders"][oid_clean]
    existing_key = order.get("key") or order.get("key_code")
    if order.get("status") == "paid" and existing_key:
        return {
            "success": True,
            "status": "paid",
            "key": existing_key,
            "package": order.get("package", "VIP"),
            "hwid": order.get("hwid", ""),
        }

    payos_code = order.get("payos_code")
    if payos_code and await gateway_payment_confirmed(payos_code):
        issued_key = await fulfill_order_atomic(oid_clean, actor="PayOS_Poll")
        return {
            "success": True,
            "status": "paid",
            "key": issued_key,
            "package": order.get("package", "VIP"),
            "hwid": order.get("hwid", ""),
        }

    return {"success": True, "status": "pending"}


@app.get("/api/verify_key")
@app.post("/api/verify_key")
async def verify_key_endpoint(
    request: Request,
    key: str = "",
    hwid: str = "",
    auto_bind: bool = True,
    post_req: Optional[VerifyKeyPostRequest] = None,
):
    check_rate_limit(request, limit=90, window=60)
    raw_k = key or (post_req.key if post_req else "")
    raw_h = hwid or (post_req.hwid if post_req else "")
    do_bind = auto_bind if post_req is None else bool(post_req.auto_bind)

    k_clean = normalize_key(raw_k)
    hwid_clean = normalize_hwid(raw_h)
    if not k_clean:
        return {
            "success": False,
            "valid": False,
            "detail": "Vui lòng nhập Mã Key!",
            "message": "Vui lòng nhập Mã Key!",
        }

    db, _ = await fetch_github_db(force_refresh=False)
    meta = _ensure_meta_structure(db.get("meta"))
    if hwid_clean and hwid_clean in meta.get("hwid_blacklist", {}):
        reason = meta["hwid_blacklist"][hwid_clean].get("reason", "Vi phạm điều khoản")
        return {
            "success": False,
            "valid": False,
            "detail": f"Thiết bị (HWID) đã bị khóa: {reason}",
            "message": f"Thiết bị (HWID) đã bị khóa: {reason}",
        }

    resolved_k, v = _find_key_in_db(db, k_clean)
    if not v:
        db, _ = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, k_clean)
        if not v:
            return {
                "success": False,
                "valid": False,
                "detail": "Key không tồn tại hoặc đã bị xóa!",
                "message": "Key không tồn tại hoặc đã bị xóa!",
            }

    now = time.time()
    exp = float(v.get("expire") or 0)
    is_expired = now >= exp
    is_banned = bool(v.get("is_banned", False))
    bound_hwid = normalize_hwid(v.get("hwid"))

    # Tự động khóa HWID (Auto-Bind) ngay khi thiết bị xác thực Key Tự Do
    if do_bind and hwid_clean and not bound_hwid and not is_expired and not is_banned:
        async with DB_ASYNC_LOCK:
            fresh_db, fresh_sha = await fetch_github_db(force_refresh=True)
            rk, fv = _find_key_in_db(fresh_db, resolved_k)
            if fv:
                curr_bound = normalize_hwid(fv.get("hwid"))
                if not curr_bound:
                    fv["hwid"] = hwid_clean
                    fv["last_used"] = now
                    fv["updated_at"] = now
                    bound_hwid = hwid_clean
                    resolved_k = rk
                    v = fv
                    db = fresh_db
                    append_audit_log(
                        fresh_db,
                        action="AUTO_BIND_HWID",
                        actor="Client_Verify",
                        target=rk,
                        detail=f"Auto-Bind vào HWID {hwid_clean}",
                    )
                    await commit_db_mutation(
                        fresh_db,
                        fresh_sha,
                        sync_immediately=True,
                        event_name="key_bound",
                        event_info={"key": rk, "hwid": hwid_clean},
                    )
                else:
                    bound_hwid = curr_bound
                    v = fv
                    db = fresh_db

    hwid_match = (
        (not bound_hwid)
        or (not hwid_clean)
        or (bound_hwid == hwid_clean)
        or (compact_alnum(bound_hwid) == compact_alnum(hwid_clean))
    )

    cooldown = (
        SELF_RESET_COOLDOWN_FREE
        if v.get("type") == "free"
        else SELF_RESET_COOLDOWN_PAID
    )
    last_reset = float(v.get("last_hwid_reset") or 0)
    reset_wait = max(0, int((last_reset + cooldown) - now))
    meta = _ensure_meta_structure(db.get("meta"))
    time_left_str = format_remaining_time(exp, now)
    tier_str = get_key_tier_label(v)
    expire_str_val = format_vn_time(exp)

    if is_banned:
        status_msg = "Key này đang bị tạm khóa bởi Admin!"
    elif is_expired:
        status_msg = "Key này đã hết hạn sử dụng!"
    elif not hwid_match:
        status_msg = f"Key đã khóa cho thiết bị khác ({bound_hwid})! Hãy bấm Đổi Máy (Reset HWID)."
    else:
        status_msg = "Xác thực Key bản quyền thành công!"

    return {
        "success": True,
        "valid": (not is_expired) and (not is_banned) and hwid_match,
        "detail": status_msg,
        "message": status_msg,
        "is_expired": is_expired,
        "is_banned": is_banned,
        "hwid_match": hwid_match,
        "key": resolved_k,
        "key_code": resolved_k,
        "bound_hwid": bound_hwid or "Chưa khóa máy",
        "hwid": bound_hwid or "",
        "is_bound": bool(bound_hwid),
        "package": v.get("package", "VIP"),
        "type": v.get("type", "paid"),
        "note": str(v.get("note") or ""),
        "tier_label": tier_str,
        "user_tier": tier_str,
        "expire": exp,
        "expire_str": expire_str_val,
        "expire_date": expire_str_val,
        "time_left": time_left_str,
        "remaining_text": time_left_str,
        "executions": int(v.get("executions") or 0),
        "can_self_reset": bool(bound_hwid)
        and (reset_wait == 0)
        and (not is_expired)
        and (not is_banned),
        "reset_cooldown_seconds": reset_wait,
        "reset_cooldown_left": (
            format_remaining_time(now + reset_wait, now)
            if reset_wait > 0
            else "Sẵn sàng"
        ),
        "admin_notice": meta.get("admin_notice") or DEFAULT_ADMIN_NOTICE,
        "maintenance": bool(meta.get("maintenance")),
        "sync_revision": int(meta.get("sync_revision") or 1),
    }


@app.post("/api/telemetry")
async def report_telemetry(req: TelemetryReportRequest, request: Request):
    """Ghi nhận thông tin thực thi từ Loader Roblox (Executor, PlaceId, số lần chạy)."""
    check_rate_limit(request, limit=30, window=60)
    k_clean = normalize_key(req.key)
    hwid_clean = normalize_hwid(req.hwid)
    if not k_clean:
        return {"success": True}
    db = DB_CACHE["data"]
    _, v = _find_key_in_db(db, k_clean)
    if v:
        v["executions"] = int(v.get("executions") or 0) + 1
        v["last_executor"] = str(req.executor or "Unknown")[:48]
        v["last_game_id"] = str(req.game_id or "steal_egg")[:48]
        v["last_used"] = time.time()
        if hwid_clean and not normalize_hwid(v.get("hwid")):
            v["hwid"] = hwid_clean
            rebuild_memory_indexes(db)
        _save_local_disk_backup(db)
    return {"success": True}


@app.get("/api/reset_hwid_by_key")
@app.post("/api/reset_hwid_by_key")
async def self_reset_hwid_by_key(
    request: Request,
    key: Optional[str] = None,
    req: Optional[SelfResetHwidRequest] = None,
):
    check_rate_limit(request, limit=20, window=60)
    raw_key = key or (req.key if req else "")
    k_clean = normalize_key(raw_key)
    if not k_clean:
        msg = "Vui lòng nhập Mã Key hợp lệ!"
        return {"success": False, "detail": msg, "message": msg}

    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, k_clean)
        if not v:
            msg = "Mã Key không tồn tại trên hệ thống!"
            return {"success": False, "detail": msg, "message": msg}

        if bool(v.get("is_banned", False)):
            msg = "Key này đang bị tạm khóa bởi Admin, không thể đổi máy!"
            return {"success": False, "detail": msg, "message": msg}

        now = time.time()
        exp = float(v.get("expire") or 0)
        if now >= exp:
            msg = "Key này đã hết hạn, không thể đổi thiết bị!"
            return {"success": False, "detail": msg, "message": msg}

        bound_hwid = normalize_hwid(v.get("hwid"))
        if not bound_hwid:
            msg = "Key này hiện đã ở trạng thái Tự Do (chưa khóa máy), bạn có thể đăng nhập ngay!"
            return {"success": True, "detail": msg, "message": msg, "key": resolved_k}

        cooldown = (
            SELF_RESET_COOLDOWN_FREE
            if v.get("type") == "free"
            else SELF_RESET_COOLDOWN_PAID
        )
        last_reset = float(v.get("last_hwid_reset") or 0)
        if now - last_reset < cooldown:
            wait_str = format_remaining_time(last_reset + cooldown, now)
            msg = f"Bạn vừa đổi máy gần đây! Vui lòng đợi {wait_str} nữa hoặc liên hệ Admin hỗ trợ."
            return {"success": False, "detail": msg, "message": msg}

        old_hwid = bound_hwid
        v["hwid"] = ""
        v["last_hwid_reset"] = now
        v["updated_at"] = now
        append_audit_log(
            db,
            action="SELF_RESET_HWID",
            actor="User",
            target=resolved_k,
            detail=f"Gỡ khóa HWID cũ: {old_hwid}",
        )
        await commit_db_mutation(
            db,
            sha,
            sync_immediately=True,
            event_name="hwid_reset",
            event_info={"key": resolved_k, "old_hwid": old_hwid},
        )
        msg = f"Đã gỡ khóa thiết bị cho Key {resolved_k} thành công! Hãy bấm KÍCH HOẠT trên máy mới."
        return {"success": True, "detail": msg, "message": msg, "key": resolved_k}


@app.get("/api/search_hwid")
async def search_hwid(hwid: str = "", fresh: int = 0, request: Request = None):
    check_rate_limit(request, limit=75, window=60)
    raw_query = str(hwid or "").strip()
    if not normalize_hwid(raw_query) and not normalize_key(raw_query):
        return {"success": True, "keys": []}

    db, _ = await fetch_github_db(force_refresh=bool(fresh))
    now = time.time()
    found = _collect_matching_keys(db, raw_query, now)

    if not found:
        db, _ = await fetch_github_db(force_refresh=True, bypass_write_fence=False)
        found = _collect_matching_keys(db, raw_query, time.time())

    meta = _ensure_meta_structure(db.get("meta"))
    return {
        "success": True,
        "sync_revision": int(meta.get("sync_revision") or 1),
        "keys": found,
    }


@app.get("/api/history_hwid")
async def history_hwid(hwid: str = "", fresh: int = 0, request: Request = None):
    check_rate_limit(request, limit=75, window=60)
    raw_query = str(hwid or "").strip()
    if not normalize_hwid(raw_query) and not normalize_key(raw_query):
        return {"success": True, "orders": []}

    db, _ = await fetch_github_db(force_refresh=bool(fresh))
    user_orders = _collect_matching_orders(db, raw_query)
    if not user_orders:
        db, _ = await fetch_github_db(force_refresh=True, bypass_write_fence=False)
        user_orders = _collect_matching_orders(db, raw_query)

    meta = _ensure_meta_structure(db.get("meta"))
    return {
        "success": True,
        "sync_revision": int(meta.get("sync_revision") or 1),
        "orders": user_orders,
    }


# ==============================================================================
# 11. TRÌNH PHỤC VỤ SCRIPT GAME ROBLOX & EMBEDDED VIP IN-GAME HUB V27.0
# ==============================================================================
EMBEDDED_FALLBACK_VIP_HUB_LUA = """
-- =========================================================================
-- BIVA STORM V27.0 HYPERION - EMBEDDED UNIVERSAL IN-GAME VIP HUB
-- Tự động kích hoạt khi game_id chưa có file riêng trên máy chủ
-- =========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("BivaStormVIPHubV27") then
    guiParent.BivaStormVIPHubV27:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BivaStormVIPHubV27"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local HubFrame = Instance.new("Frame")
HubFrame.Size = UDim2.new(0, 420, 0, 310)
HubFrame.Position = UDim2.new(0.5, -210, 0.5, -155)
HubFrame.BackgroundColor3 = Color3.fromRGB(7, 13, 28)
HubFrame.BorderSizePixel = 0
HubFrame.Active = true
HubFrame.Draggable = true
HubFrame.Parent = ScreenGui

Instance.new("UICorner", HubFrame).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", HubFrame)
stroke.Color = Color3.fromRGB(0, 229, 255)
stroke.Thickness = 1.6

local Title = Instance.new("TextLabel", HubFrame)
Title.Size = UDim2.new(1, -24, 0, 34)
Title.Position = UDim2.new(0, 12, 0, 6)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ BIVA STORM VIP HUB | {USER_TIER}"
Title.TextColor3 = Color3.fromRGB(0, 229, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local Info = Instance.new("TextLabel", HubFrame)
Info.Size = UDim2.new(1, -24, 0, 40)
Info.Position = UDim2.new(0, 12, 0, 38)
Info.BackgroundTransparency = 1
Info.Font = Enum.Font.GothamMedium
Info.Text = "🔑 Key: {KEY} • ⏳ Hạn: {TIME_LEFT}\\n📢 {ADMIN_MSG}"
Info.TextColor3 = Color3.fromRGB(203, 213, 225)
Info.TextSize = 11.5
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left

local espEnabled = false
local noclipEnabled = false
local infJumpEnabled = false

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local function makeBtn(txt, pos, cb)
    local b = Instance.new("TextButton", HubFrame)
    b.Size = UDim2.new(0.46, 0, 0, 36)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(16, 28, 56)
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(248, 250, 252)
    b.TextSize = 11.5
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

makeBtn("🚀 Tốc Chạy (WalkSpeed 42)", UDim2.new(0.03, 0, 0, 88), function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 42
    end
end)

makeBtn("🦘 Nhảy Vô Hạn (InfJump): TẮT", UDim2.new(0.51, 0, 0, 88), function(btn)
    infJumpEnabled = not infJumpEnabled
    btn.Text = "🦘 Nhảy Vô Hạn (InfJump): " .. (infJumpEnabled and "BẬT" or "TẮT")
end)

makeBtn("👻 Đi Xuyên Tường (Noclip): TẮT", UDim2.new(0.03, 0, 0, 132), function(btn)
    noclipEnabled = not noclipEnabled
    btn.Text = "👻 Đi Xuyên Tường (Noclip): " .. (noclipEnabled and "BẬT" or "TẮT")
end)

makeBtn("👁️ Định Vị Player (ESP): TẮT", UDim2.new(0.51, 0, 0, 132), function(btn)
    espEnabled = not espEnabled
    btn.Text = "👁️ Định Vị Player (ESP): " .. (espEnabled and "BẬT" or "TẮT")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hl = plr.Character:FindFirstChild("BivaESP")
            if espEnabled and not hl then
                hl = Instance.new("Highlight", plr.Character)
                hl.Name = "BivaESP"
                hl.FillColor = Color3.fromRGB(0, 229, 255)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            elseif not espEnabled and hl then
                hl:Destroy()
            end
        end
    end
end)

makeBtn("☀️ Sáng Bản Đồ (FullBright)", UDim2.new(0.03, 0, 0, 176), function()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
end)

makeBtn("🔄 Vào Lại Server (Rejoin)", UDim2.new(0.51, 0, 0, 176), function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

makeBtn("❌ Đóng Menu VIP", UDim2.new(0.27, 0, 0, 232), function()
    ScreenGui:Destroy()
end)
"""


async def _load_game_script(safe_game_id: str) -> str:
    file_path = (BASE_STATIC_DIR / f"{safe_game_id}.lua").resolve()
    if file_path.parent == BASE_STATIC_DIR and file_path.is_file():
        return file_path.read_text(encoding="utf-8")

    default_path = (BASE_STATIC_DIR / "steal_egg.lua").resolve()
    if default_path.parent == BASE_STATIC_DIR and default_path.is_file():
        return default_path.read_text(encoding="utf-8")

    now = time.time()
    cached = SCRIPT_CACHE.get(safe_game_id)
    if cached and (now - float(cached.get("ts") or 0) < 60):
        return str(cached.get("code") or "")

    if GITHUB_SCRIPT_URL:
        try:
            client = await _get_http_client()
            res = await client.get(GITHUB_SCRIPT_URL)
            if res.status_code == 200 and len(res.text) > 80:
                SCRIPT_CACHE[safe_game_id] = {"code": res.text, "ts": now}
                return res.text
        except Exception as e:
            logger.error(f"Fallback script fetch error: {e}")

    return EMBEDDED_FALLBACK_VIP_HUB_LUA


@app.get("/api/get_script", response_class=PlainTextResponse)
async def get_script(
    request: Request,
    key: str = "",
    hwid: str = "",
    game_id: str = "steal_egg",
):
    check_rate_limit(request, limit=50, window=60)
    key_clean = normalize_key(key)
    hwid_clean = normalize_hwid(hwid)
    safe_game_id = re.sub(r"[^a-zA-Z0-9_]", "", game_id or "steal_egg") or "steal_egg"

    if not key_clean:
        return 'game.Players.LocalPlayer:Kick("⚠️ [BIVA STORM V27.0]: Bạn chưa nhập mã Key!")'
    if not hwid_clean:
        return 'game.Players.LocalPlayer:Kick("⚠️ [BIVA STORM V27.0]: Không nhận diện được thiết bị (HWID)!")'

    db, _ = await fetch_github_db(force_refresh=False)
    meta = _ensure_meta_structure(db.get("meta"))
    if meta.get("maintenance"):
        msg = lua_escape(
            meta.get("admin_notice") or "Hệ thống đang bảo trì nâng cấp vài phút!"
        )
        return f'game.Players.LocalPlayer:Kick("🛠️ [BIVA STORM V27.0 BẢO TRÌ]: {msg}")'

    if hwid_clean in meta.get("hwid_blacklist", {}):
        reason = lua_escape(
            meta["hwid_blacklist"][hwid_clean].get("reason", "Vi phạm điều khoản")
        )
        return f'game.Players.LocalPlayer:Kick("🚫 [BIVA STORM V27.0]: Thiết bị đã bị khóa ({reason})!")'

    resolved_key, key_data = _find_key_in_db(db, key_clean)
    if not key_data:
        db, _ = await fetch_github_db(force_refresh=True)
        resolved_key, key_data = _find_key_in_db(db, key_clean)
        if not key_data:
            return 'game.Players.LocalPlayer:Kick("❌ [BIVA STORM V27.0]: Key không tồn tại hoặc đã hết hạn!")'

    if bool(key_data.get("is_banned", False)):
        return 'game.Players.LocalPlayer:Kick("🚫 [BIVA STORM V27.0]: Key này đang bị tạm khóa bởi Admin!")'

    now = time.time()
    expire_ts = float(key_data.get("expire") or 0)
    if now > expire_ts:
        return 'game.Players.LocalPlayer:Kick("⏰ [BIVA STORM V27.0]: Key đã hết hạn! Vui lòng gia hạn trên Web.")'

    bound_hwid = normalize_hwid(key_data.get("hwid"))

    if not bound_hwid:
        async with DB_ASYNC_LOCK:
            fresh_db, fresh_sha = await fetch_github_db(force_refresh=True)
            rk, fresh_key_data = _find_key_in_db(fresh_db, resolved_key)
            if not fresh_key_data:
                return 'game.Players.LocalPlayer:Kick("❌ [BIVA STORM V27.0]: Key không tồn tại hoặc đã hết hạn!")'

            current_bound = normalize_hwid(fresh_key_data.get("hwid"))
            if (
                current_bound
                and current_bound != hwid_clean
                and compact_alnum(current_bound) != compact_alnum(hwid_clean)
            ):
                return 'game.Players.LocalPlayer:Kick("🔒 [BIVA STORM V27.0]: Key đã khóa cho thiết bị (HWID) khác!")'

            if not current_bound:
                fresh_key_data["hwid"] = hwid_clean
                fresh_key_data["last_used"] = now
                fresh_key_data["updated_at"] = now
                fresh_key_data["executions"] = int(fresh_key_data.get("executions") or 0) + 1
                key_data = fresh_key_data
                await commit_db_mutation(
                    fresh_db,
                    fresh_sha,
                    sync_immediately=True,
                    event_name="key_bound",
                    event_info={"key": rk, "hwid": hwid_clean},
                )
    elif bound_hwid != hwid_clean and compact_alnum(bound_hwid) != compact_alnum(
        hwid_clean
    ):
        return 'game.Players.LocalPlayer:Kick("🔒 [BIVA STORM V27.0]: Key đã khóa cho thiết bị (HWID) khác! Hãy bấm Đổi Máy trên Web/Loader.")'
    else:
        key_data["executions"] = int(key_data.get("executions") or 0) + 1
        key_data["last_used"] = now

    time_str = lua_escape(format_remaining_time(expire_ts, now))
    expire_str = lua_escape(format_vn_time(expire_ts))
    user_tier = lua_escape(get_key_tier_label(key_data))
    admin_msg = lua_escape(meta.get("admin_notice") or DEFAULT_ADMIN_NOTICE)

    menu_code = await _load_game_script(safe_game_id)
    return (
        menu_code.replace("{TIME_LEFT}", time_str)
        .replace("{USER_TIER}", user_tier)
        .replace("{ADMIN_MSG}", admin_msg)
        .replace("{KEY}", lua_escape(resolved_key))
        .replace("{HWID}", lua_escape(hwid_clean))
        .replace("{EXPIRE_STR}", expire_str)
        .replace("{VERSION}", APP_VERSION)
        .replace("{API_BASE}", lua_escape(WEB_DOMAIN))
    )


# ==============================================================================
# 12. VƯỢT LINK NHẬN KEY FREE 20H (STATELESS HMAC + ANTI-REPLAY)
# ==============================================================================
@app.post("/api/get_free_link")
@app.get("/api/get_free_link")
async def get_free_link(
    request: Request,
    req: Optional[FreeKeyRequest] = None,
    hwid: str = "",
    game: str = "rb",
):
    check_rate_limit(request, limit=12, window=60)
    raw_hwid = req.hwid if req else hwid
    raw_game = req.game if req else game
    hwid_clean = normalize_hwid(raw_hwid)
    if not hwid_clean:
        return {"success": False, "message": "Vui lòng nhập HWID hợp lệ!"}

    now = time.time()
    expired_tokens = [
        k
        for k, v in list(FREE_TOKENS.items())
        if now - v["time"] > FREE_TOKEN_TTL_SECONDS
    ]
    for k in expired_tokens:
        FREE_TOKENS.pop(k, None)

    db, _ = await fetch_github_db(force_refresh=False)
    for existing in db["keys"].values():
        if (
            normalize_hwid(existing.get("hwid")) == hwid_clean
            and existing.get("type") == "free"
            and float(existing.get("expire") or 0) > now
        ):
            return {
                "success": False,
                "message": "Thiết bị này đang có Key Free còn hạn! Đã tự động lấy lại Key cho bạn.",
                "existing_key": existing.get("key_code"),
            }

    if not LOOTLABS_API_KEY:
        return {
            "success": False,
            "message": "Hệ thống Key Free đang bảo trì, vui lòng mua gói 15.000đ tự động!",
        }

    game_clean = (raw_game or "rb").strip().lower()
    token, _ = create_signed_free_token(hwid_clean, game_clean)
    FREE_TOKENS[token] = {"hwid": hwid_clean, "game": game_clean, "time": now}

    target_url = f"{WEB_DOMAIN}/index.html?token={token}"
    headers = {
        "Authorization": f"Bearer {LOOTLABS_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "title": "BIVA STORM V27.0 | Free Key 20h",
        "url": target_url,
        "description": "Vượt link nhận Key 20 Giờ!",
    }

    try:
        client = await _get_http_client()
        res = await client.post(
            "https://api.lootlabs.gg/api/public/v1/links/create",
            json=payload,
            headers=headers,
        )
        if res.status_code in (200, 201):
            data = res.json()
            shortened_url = data.get("data", {}).get("url")
            if shortened_url:
                return {"success": True, "link": shortened_url}
    except Exception as e:
        logger.error(f"LootLabs API error: {e}")

    FREE_TOKENS.pop(token, None)
    return {"success": False, "message": "Lỗi tạo link vượt! Vui lòng thử lại sau."}


@app.get("/api/claim_free_key")
async def claim_free_key(token: str, request: Request):
    check_rate_limit(request, limit=15, window=60)
    clean_token = str(token).strip()
    if not clean_token:
        return {"success": False, "message": "Token nhận Key không hợp lệ!"}

    now = time.time()
    token_info = verify_signed_free_token(clean_token)
    if not token_info:
        legacy = FREE_TOKENS.pop(clean_token, None)
        if not legacy:
            return {
                "success": False,
                "message": "Token nhận Key không hợp lệ hoặc đã sử dụng!",
            }
        token_info = {
            "hwid": normalize_hwid(legacy.get("hwid")),
            "game": str(legacy.get("game") or "rb").lower(),
            "time": float(legacy.get("time") or 0),
            "nonce": clean_token[:16],
        }
    else:
        FREE_TOKENS.pop(clean_token, None)

    if now - float(token_info["time"]) > FREE_TOKEN_TTL_SECONDS:
        return {"success": False, "message": "Token đã hết hạn! Vui lòng vượt link lại."}

    hwid_clean = normalize_hwid(token_info.get("hwid"))
    nonce = str(token_info.get("nonce") or clean_token[:16])
    if not hwid_clean:
        return {"success": False, "message": "Token thiếu thông tin thiết bị (HWID)!"}

    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        meta = _ensure_meta_structure(db.get("meta"))
        if nonce in meta["used_free_tokens"]:
            return {"success": False, "message": "Token nhận Key này đã được sử dụng!"}

        for k, existing in db["keys"].items():
            if (
                normalize_hwid(existing.get("hwid")) == hwid_clean
                and existing.get("type") == "free"
                and float(existing.get("expire") or 0) > now
            ):
                meta["used_free_tokens"][nonce] = now
                await commit_db_mutation(db, sha, sync_immediately=True)
                return {"success": True, "key": k, "hwid": hwid_clean}

        new_key = generate_key("FREE")
        while new_key in db["keys"]:
            new_key = generate_key("FREE")

        tombstones = meta.setdefault("deleted_keys", {})
        tombstones.pop(new_key, None)
        meta["used_free_tokens"][nonce] = now
        db["keys"][new_key] = {
            "key_code": new_key,
            "game": token_info["game"],
            "hwid": hwid_clean,
            "expire": now + 72000,
            "created_at": now,
            "updated_at": now,
            "type": "free",
            "package": "Free 20h",
            "note": "",
            "is_banned": False,
            "executions": 0,
        }
        append_audit_log(
            db,
            action="CLAIM_FREE_KEY",
            actor="LootLabs",
            target=new_key,
            detail=f"HWID: {hwid_clean}",
        )
        await commit_db_mutation(
            db,
            sha,
            sync_immediately=True,
            event_name="free_key_claimed",
            event_info={"key": new_key, "hwid": hwid_clean},
        )
        return {"success": True, "key": new_key, "hwid": hwid_clean}


# ==============================================================================
# 13. ADMIN APIS V27.0 HYPERION (SNAPSHOT 0MS + AUDIT LOG + VOUCHER + DIAGNOSTICS)
# ==============================================================================
@app.get("/api/admin/data", dependencies=[Depends(verify_admin)])
async def admin_data():
    db, _ = await fetch_github_db(force_refresh=True)
    return build_admin_snapshot(db)


@app.get("/api/admin/diagnostics", dependencies=[Depends(verify_admin)])
async def admin_diagnostics():
    """Kiểm tra chuyên sâu & tự động sửa chữa liên kết chỉ mục RAM O(1)."""
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        index_report = rebuild_memory_indexes(db)
        if index_report.get("healed_links", 0) > 0:
            await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "version": APP_VERSION,
            "uptime_seconds": int(time.time() - SERVER_START_TIME),
            "index_report": index_report,
            "dirty_sync": bool(DB_CACHE.get("dirty")),
            "last_pushed_sha": DB_CACHE.get("last_pushed_sha"),
            "snapshot": build_admin_snapshot(db),
        }


@app.get("/api/admin/audit_logs", dependencies=[Depends(verify_admin)])
async def admin_get_audit_logs():
    db, _ = await fetch_github_db(force_refresh=False)
    meta = _ensure_meta_structure(db.get("meta"))
    return {
        "success": True,
        "audit_logs": meta.get("audit_logs", []),
    }


@app.post("/api/admin/vouchers", dependencies=[Depends(verify_admin)])
async def admin_create_voucher(req: AdminVoucherRequest):
    clean_code = normalize_key(req.code)
    if not clean_code:
        raise HTTPException(status_code=400, detail="Mã giảm giá không hợp lệ!")
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        meta = _ensure_meta_structure(db.get("meta"))
        meta["vouchers"][clean_code] = {
            "code": clean_code,
            "discount_percent": req.discount_percent,
            "bonus_hours": req.bonus_hours,
            "max_uses": req.max_uses,
            "used": 0,
            "created_at": time.time(),
        }
        append_audit_log(
            db,
            action="CREATE_VOUCHER",
            actor="Admin",
            target=clean_code,
            detail=f"Giảm {req.discount_percent}% + Tặng {req.bonus_hours}h (Tối đa {req.max_uses} lượt)",
        )
        await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "vouchers": meta["vouchers"],
            "snapshot": build_admin_snapshot(db),
        }


@app.post("/api/admin/blacklist_hwid", dependencies=[Depends(verify_admin)])
async def admin_blacklist_hwid(req: AdminBlacklistHwidRequest):
    hwid_clean = normalize_hwid(req.hwid)
    if not hwid_clean:
        raise HTTPException(status_code=400, detail="Mã Máy (HWID) không hợp lệ!")
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        meta = _ensure_meta_structure(db.get("meta"))
        if req.ban:
            meta["hwid_blacklist"][hwid_clean] = {
                "hwid": hwid_clean,
                "reason": req.reason.strip(),
                "time": time.time(),
                "time_str": format_vn_time(time.time()),
            }
            append_audit_log(
                db,
                action="BLACKLIST_HWID",
                actor="Admin",
                target=hwid_clean,
                detail=req.reason.strip(),
            )
        else:
            meta["hwid_blacklist"].pop(hwid_clean, None)
            append_audit_log(
                db,
                action="UNBAN_HWID",
                actor="Admin",
                target=hwid_clean,
                detail="Gỡ khỏi danh sách đen",
            )
        await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "hwid_blacklist": meta["hwid_blacklist"],
            "snapshot": build_admin_snapshot(db),
        }


@app.get("/api/admin/export_db", dependencies=[Depends(verify_admin)])
async def admin_export_db():
    db, _ = await fetch_github_db(force_refresh=True)
    return {
        "success": True,
        "exported_at": format_vn_time(time.time(), "%Y-%m-%d %H:%M:%S"),
        "version": APP_VERSION,
        "database": copy.deepcopy(db),
    }


@app.post("/api/admin/import_db", dependencies=[Depends(verify_admin)])
async def admin_import_db(request: Request):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Dữ liệu JSON tải lên không hợp lệ!")
    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="Cấu trúc file sao lưu không hợp lệ!")
    incoming_db = (
        payload.get("database")
        if isinstance(payload.get("database"), dict)
        else payload
    )
    if not isinstance(incoming_db.get("keys"), dict) and not isinstance(
        incoming_db.get("orders"), dict
    ):
        raise HTTPException(
            status_code=400, detail="File JSON không chứa dữ liệu keys hoặc orders!"
        )
    mode = str(payload.get("mode") or "merge").lower()

    async with DB_ASYNC_LOCK:
        current_db, sha = await fetch_github_db(force_refresh=True)
        clean_incoming, _ = normalize_and_clean_db(incoming_db)
        if mode == "replace":
            final_db = clean_incoming
        else:
            final_db = _merge_db_states(current_db, clean_incoming)
        append_audit_log(
            final_db,
            action="IMPORT_DB",
            actor="Admin",
            target=mode.upper(),
            detail=f"Keys: {len(final_db.get('keys', {}))}, Orders: {len(final_db.get('orders', {}))}",
        )
        await commit_db_mutation(final_db, sha, sync_immediately=True)
        return {
            "success": True,
            "total_keys": len(final_db.get("keys", {})),
            "total_orders": len(final_db.get("orders", {})),
            "snapshot": build_admin_snapshot(final_db),
        }


@app.post("/api/admin/reset_all_hwid", dependencies=[Depends(verify_admin)])
async def admin_reset_all_hwid():
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        now = time.time()
        reset_count = 0
        for v in db["keys"].values():
            if float(v.get("expire") or 0) > now and not bool(v.get("is_banned", False)):
                if normalize_hwid(v.get("hwid")):
                    reset_count += 1
                v["hwid"] = ""
                v["last_hwid_reset"] = 0
                v["updated_at"] = now
        if reset_count > 0:
            append_audit_log(
                db,
                action="RESET_ALL_HWID",
                actor="Admin",
                target="ALL_ACTIVE_KEYS",
                detail=f"Đã mở khóa {reset_count} Key",
            )
            await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "reset_count": reset_count,
            "snapshot": build_admin_snapshot(db),
        }


@app.post("/api/admin/broadcast", dependencies=[Depends(verify_admin)])
async def admin_update_broadcast(req: AdminBroadcastRequest):
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        meta = _ensure_meta_structure(db.get("meta"))
        meta["admin_notice"] = req.notice.strip()
        meta["maintenance"] = bool(req.maintenance)
        meta["notice_updated_at"] = time.time()
        db["meta"] = meta
        append_audit_log(
            db,
            action="BROADCAST",
            actor="Admin",
            target="MAINT_ON" if req.maintenance else "MAINT_OFF",
            detail=req.notice.strip()[:80],
        )
        await commit_db_mutation(
            db,
            sha,
            sync_immediately=True,
            event_name="broadcast_updated",
            event_info={
                "admin_notice": meta["admin_notice"],
                "maintenance": meta["maintenance"],
            },
        )
        return {
            "success": True,
            "admin_notice": meta["admin_notice"],
            "maintenance": meta["maintenance"],
            "snapshot": build_admin_snapshot(db),
        }


@app.get("/api/admin/approve_order", dependencies=[Depends(verify_admin)])
@app.post("/api/admin/approve_order", dependencies=[Depends(verify_admin)])
async def approve_order(
    order_id: Optional[str] = None, req: Optional[AdminDeleteRequest] = None
):
    target_oid = order_id or (req.order_id if req else "")
    if not target_oid:
        raise HTTPException(status_code=400, detail="Thiếu mã đơn hàng!")
    key_code = await fulfill_order_atomic(target_oid, actor="Admin")
    return {
        "success": True,
        "key": key_code,
        "snapshot": build_admin_snapshot(DB_CACHE["data"]),
    }


@app.get("/api/admin/delete_order", dependencies=[Depends(verify_admin)])
@app.post("/api/admin/delete_order", dependencies=[Depends(verify_admin)])
async def delete_order(
    order_id: Optional[str] = None, req: Optional[AdminDeleteRequest] = None
):
    raw_oid = order_id or (req.order_id if req else "")
    oid = str(raw_oid or "").strip().upper()
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        if oid in db["orders"]:
            db.setdefault("meta", {}).setdefault("deleted_orders", {})[oid] = time.time()
            del db["orders"][oid]
            append_audit_log(
                db, action="DELETE_ORDER", actor="Admin", target=oid, detail="Xóa đơn"
            )
            await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "snapshot": build_admin_snapshot(db),
        }


@app.get("/api/admin/reset_hwid", dependencies=[Depends(verify_admin)])
@app.post("/api/admin/reset_hwid", dependencies=[Depends(verify_admin)])
async def reset_hwid(
    key: Optional[str] = None, req: Optional[AdminDeleteRequest] = None
):
    raw_k = key or (req.key if req else "")
    k = normalize_key(raw_k)
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, k)
        if v:
            old_h = v.get("hwid") or ""
            v["hwid"] = ""
            v["last_hwid_reset"] = 0
            v["updated_at"] = time.time()
            append_audit_log(
                db,
                action="ADMIN_RESET_HWID",
                actor="Admin",
                target=resolved_k,
                detail=f"HWID cũ: {old_h}",
            )
            await commit_db_mutation(
                db,
                sha,
                sync_immediately=True,
                event_name="hwid_reset",
                event_info={"key": resolved_k},
            )
            return {
                "success": True,
                "key": resolved_k,
                "snapshot": build_admin_snapshot(db),
            }
    raise HTTPException(status_code=404, detail="Không tìm thấy mã Key này!")


@app.post("/api/admin/bind_hwid", dependencies=[Depends(verify_admin)])
async def admin_bind_hwid(req: AdminBindHwidRequest):
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, req.key)
        if v:
            hwid_clean = normalize_hwid(req.hwid)
            now = time.time()
            v["hwid"] = hwid_clean
            v["updated_at"] = now
            linked_oid = str(v.get("order_id") or "").upper()
            if linked_oid and linked_oid in db["orders"]:
                db["orders"][linked_oid]["hwid"] = hwid_clean
                db["orders"][linked_oid]["updated_at"] = now
            append_audit_log(
                db,
                action="ADMIN_BIND_HWID",
                actor="Admin",
                target=resolved_k,
                detail=f"Gán HWID: {hwid_clean or 'Tự Do'}",
            )
            await commit_db_mutation(
                db,
                sha,
                sync_immediately=True,
                event_name="key_bound",
                event_info={"key": resolved_k, "hwid": hwid_clean},
            )
            return {
                "success": True,
                "key": resolved_k,
                "hwid": hwid_clean,
                "snapshot": build_admin_snapshot(db),
            }
    raise HTTPException(status_code=404, detail="Không tìm thấy mã Key này!")


@app.post("/api/admin/update_note", dependencies=[Depends(verify_admin)])
async def admin_update_note(req: AdminUpdateNoteRequest):
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, req.key)
        if v:
            note_clean = str(req.note or "").strip()[:120]
            v["note"] = note_clean
            v["updated_at"] = time.time()
            await commit_db_mutation(db, sha, sync_immediately=True)
            return {
                "success": True,
                "key": resolved_k,
                "note": note_clean,
                "snapshot": build_admin_snapshot(db),
            }
    raise HTTPException(status_code=404, detail="Không tìm thấy mã Key này!")


@app.post("/api/admin/toggle_ban", dependencies=[Depends(verify_admin)])
async def admin_toggle_ban(req: AdminToggleBanRequest):
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, req.key)
        if v:
            current_state = bool(v.get("is_banned", False))
            next_state = (
                (not current_state) if req.is_banned is None else bool(req.is_banned)
            )
            v["is_banned"] = next_state
            v["updated_at"] = time.time()
            append_audit_log(
                db,
                action="BAN_KEY" if next_state else "UNBAN_KEY",
                actor="Admin",
                target=resolved_k,
                detail="Khóa Key" if next_state else "Mở khóa Key",
            )
            await commit_db_mutation(db, sha, sync_immediately=True)
            return {
                "success": True,
                "key": resolved_k,
                "is_banned": next_state,
                "snapshot": build_admin_snapshot(db),
            }
    raise HTTPException(status_code=404, detail="Không tìm thấy mã Key này!")


@app.get("/api/admin/delete_key", dependencies=[Depends(verify_admin)])
@app.post("/api/admin/delete_key", dependencies=[Depends(verify_admin)])
async def delete_key(
    key: Optional[str] = None, req: Optional[AdminDeleteRequest] = None
):
    raw_k = key or (req.key if req else "")
    k = normalize_key(raw_k)
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        resolved_k, v = _find_key_in_db(db, k)
        if v:
            db.setdefault("meta", {}).setdefault("deleted_keys", {})[
                resolved_k
            ] = time.time()
            del db["keys"][resolved_k]
            append_audit_log(
                db,
                action="DELETE_KEY",
                actor="Admin",
                target=resolved_k,
                detail="Xóa Key vĩnh viễn",
            )
            await commit_db_mutation(db, sha, sync_immediately=True)
            return {
                "success": True,
                "snapshot": build_admin_snapshot(db),
            }
    raise HTTPException(status_code=404, detail="Không tìm thấy mã Key này!")


@app.get("/api/admin/purge_expired", dependencies=[Depends(verify_admin)])
@app.post("/api/admin/purge_expired", dependencies=[Depends(verify_admin)])
async def admin_purge_expired():
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        now = time.time()
        removed_keys = 0
        removed_orders = 0
        k_tombstones = db.setdefault("meta", {}).setdefault("deleted_keys", {})
        o_tombstones = db.setdefault("meta", {}).setdefault("deleted_orders", {})

        for k, v in list(db["keys"].items()):
            if float(v.get("expire") or 0) <= now:
                del db["keys"][k]
                k_tombstones[k] = now
                removed_keys += 1

        for oid, o in list(db["orders"].items()):
            if o.get("status") == "pending" and (now - float(o.get("time") or 0) > 3600):
                del db["orders"][oid]
                o_tombstones[oid] = now
                removed_orders += 1

        if removed_keys > 0 or removed_orders > 0:
            append_audit_log(
                db,
                action="PURGE_EXPIRED",
                actor="Admin",
                target="CLEANUP",
                detail=f"Xóa {removed_keys} Key hết hạn & {removed_orders} đơn treo",
            )
            await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "removed_keys": removed_keys,
            "removed_orders": removed_orders,
            "deleted_count": removed_keys,
            "snapshot": build_admin_snapshot(db),
        }


@app.post("/api/admin/create_key", dependencies=[Depends(verify_admin)])
async def admin_create_key(req: AdminCreateKeyRequest):
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        created: List[str] = []
        prefix = (req.prefix or req.game or "RB").strip().upper()
        amount = max(1, min(req.amount, 50))
        now = time.time()
        hours_val = max(1.0, float(req.hours))
        expire_ts = now + (hours_val * 3600)
        hwid_clean = normalize_hwid(req.hwid)
        note_clean = str(req.note or "").strip()[:120]
        pkg_label = resolve_package_label(hours_val, req.package)
        tombstones = db.setdefault("meta", {}).setdefault("deleted_keys", {})

        for _ in range(amount):
            new_key = generate_key(prefix)
            while new_key in db["keys"]:
                new_key = generate_key(prefix)
            tombstones.pop(new_key, None)
            db["keys"][new_key] = {
                "key_code": new_key,
                "game": (req.game or "rb").strip().lower(),
                "hwid": hwid_clean,
                "expire": expire_ts,
                "created_at": now,
                "updated_at": now,
                "type": "admin",
                "package": pkg_label,
                "note": note_clean,
                "is_banned": False,
                "executions": 0,
            }
            created.append(new_key)

        append_audit_log(
            db,
            action="CREATE_KEY",
            actor="Admin",
            target=created[0] if len(created) == 1 else f"{len(created)}_KEYS",
            detail=f"Gói: {pkg_label} | HWID: {hwid_clean or 'Tự Do'} | Note: {note_clean}",
        )
        await commit_db_mutation(
            db,
            sha,
            sync_immediately=True,
            event_name="keys_created",
            event_info={"keys": created, "hwid": hwid_clean, "package": pkg_label},
        )
        return {
            "success": True,
            "keys": created,
            "hwid": hwid_clean,
            "package": pkg_label,
            "expire_str": format_vn_time(expire_ts),
            "snapshot": build_admin_snapshot(db),
        }


@app.post("/api/admin/extend_key", dependencies=[Depends(verify_admin)])
async def admin_extend_key(req: AdminExtendKeyRequest):
    async with DB_ASYNC_LOCK:
        db, sha = await fetch_github_db(force_refresh=True)
        now = time.time()
        added_seconds = max(1.0, float(req.hours)) * 3600

        if req.all_active:
            count = 0
            for v in db["keys"].values():
                if float(v.get("expire") or 0) > now and not bool(
                    v.get("is_banned", False)
                ):
                    v["expire"] = float(v["expire"]) + added_seconds
                    v["updated_at"] = now
                    count += 1
            if count > 0:
                append_audit_log(
                    db,
                    action="EXTEND_ALL_KEYS",
                    actor="Admin",
                    target="ALL_ACTIVE",
                    detail=f"Bù +{req.hours}h cho {count} Key",
                )
                await commit_db_mutation(db, sha, sync_immediately=True)
            return {
                "success": True,
                "updated_count": count,
                "snapshot": build_admin_snapshot(db),
            }

        resolved_k, target_obj = _find_key_in_db(db, req.key or "")
        if not target_obj:
            raise HTTPException(status_code=404, detail="Không tìm thấy Key!")

        base_time = max(now, float(target_obj.get("expire") or now))
        new_exp = base_time + added_seconds
        target_obj["expire"] = new_exp
        target_obj["updated_at"] = now
        append_audit_log(
            db,
            action="EXTEND_KEY",
            actor="Admin",
            target=resolved_k,
            detail=f"Cộng thêm +{req.hours}h",
        )
        await commit_db_mutation(db, sha, sync_immediately=True)
        return {
            "success": True,
            "updated_count": 1,
            "key": resolved_k,
            "new_expire": new_exp,
            "expire_str": format_vn_time(new_exp),
            "time_left": format_remaining_time(new_exp, now),
            "snapshot": build_admin_snapshot(db),
        }


# ==============================================================================
# 14. STRICT WHITELIST STATIC ROUTER (BẢO VỆ MÃ NGUỒN SERVER)
# ==============================================================================
@app.get("/", response_class=HTMLResponse)
@app.get("/index.html", response_class=HTMLResponse)
async def serve_index():
    p = (BASE_STATIC_DIR / "index.html").resolve()
    if p.is_file():
        return FileResponse(p, media_type="text/html; charset=utf-8")
    raise HTTPException(status_code=404, detail="Không tìm thấy trang chủ!")


@app.get("/admin", response_class=HTMLResponse)
@app.get("/admin.html", response_class=HTMLResponse)
async def serve_admin():
    p = (BASE_STATIC_DIR / "admin.html").resolve()
    if p.is_file():
        return FileResponse(p, media_type="text/html; charset=utf-8")
    raise HTTPException(status_code=404, detail="Không tìm thấy trang Quản trị!")


@app.get("/biva_storm.lua", response_class=PlainTextResponse)
@app.get("/loader.lua", response_class=PlainTextResponse)
async def serve_public_loader():
    p = (BASE_STATIC_DIR / "biva_storm.lua").resolve()
    if p.is_file():
        return PlainTextResponse(
            p.read_text(encoding="utf-8"), media_type="text/plain; charset=utf-8"
        )
    raise HTTPException(status_code=404, detail="Không tìm thấy Loader!")


@app.get("/IMG_1277.jpeg")
async def serve_logo():
    p = (BASE_STATIC_DIR / "IMG_1277.jpeg").resolve()
    if p.is_file():
        return FileResponse(p, media_type="image/jpeg")
    raise HTTPException(status_code=404, detail="Logo not found")


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 10000))
    uvicorn.run(app, host="0.0.0.0", port=port)
