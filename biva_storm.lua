-- ==============================================================================
-- BIVA STORM | V29.0 SINGULARITY SOVEREIGN OMNI-SYNC LOADER & COMMAND CENTER
-- Kiến trúc Đồng Bộ Toàn Diện 100% Với Server V29.0:
--   [+] Tab 1: Kích Hoạt Bản Quyền, Đổi Giftcode Sự Kiện (/api/redeem_giftcode) & Đếm Ngược Real-time
--   [+] Tab 2: Cửa Hàng PayOS In-Game (Đồng Bộ Giá Động Từ Server) + Áp Mã Giảm Giá (/api/check_voucher)
--   [+] Tab 3: Kho Key Đa Thiết Bị (Multi-Device Slot 📱 X/Y máy), Gán HWID & Đổi Máy (Reset HWID)
--   [+] Tab 4: Lịch Sử Đơn Hàng & Cấp Phép Trực Tuyến (/api/omni_sync)
--   [+] Tab 5: Tiện Ích VIP (FPS Boost, Anti-AFK, Server Hop, FullBright) & 5 Chủ Đề Giao Diện
--   [+] Tab 6: Nhật Ký Đồng Bộ Thời Gian Thực (Live Sync Console) & Chẩn Đoán Kết Nối
-- ==============================================================================

-- ... existing code ...
local API_ENDPOINTS = {
"https://biva-hub.onrender.com"
}
local activeEndpointIndex = 1
local WEB_SHOP_URL = "https://biva-hub.onrender.com/index.html"
local SAVE_FILE_NAME = "BivaStorm_V29_Singularity_Config.json"
local VAULT_FILE_NAME = "BivaStorm_V29_KeyVault.json"
local VERSION_TAG = "V29.0 SINGULARITY"

local DEFAULT_GAME_CATALOG = {
{
id = "steal_egg",
code = "rb",
name = "⚡ Steal Egg / Biva Main Hub",
version = "29.0",
status = "online",
features = { "Auto Task Assistant", "Smart Radar Overlay", "Quick Waypoint", "Anti-AFK Guard" }
},
{
id = "blox_fruits",
code = "rb",
name = "🏴‍☠️ Blox Fruits Singularity",
version = "29.0",
status = "online",
features = { "Quest Tracker", "Sea Event Timer", "Inventory Manager", "FPS Optimizer" }
},
{
id = "fisch",
code = "rb",
name = "🐟 Fisch Reel Assistant",
version = "29.0",
status = "online",
features = { "Reel Timing HUD", "Weather & Biome Alert", "Fish Index Tracker", "Quick Sell UI" }
},
{
id = "dead_rails",
code = "rb",
name = "🚂 Dead Rails Tactical HUD",
version = "29.0",
status = "online",
features = { "Fuel & Distance Meter", "Resource Locator", "Night Vision Filter", "Ping Stabilizer" }
},
{
id = "arise_crossover",
code = "rb",
name = "⚔️ Arise Crossover Companion",
version = "29.0",
status = "online",
features = { "Dungeon Cooldown Timer", "Shadow Team Preset", "Performance Boost", "Auto Reconnect" }
},
{
id = "blue_lock",
code = "rb",
name = "⚽ Blue Lock Rivals Pro HUD",
version = "29.0",
status = "online",
features = { "Stamina Bar HUD", "Trajectory Guide", "Camera FOV Tuner", "Ultra Low Latency" }
}
}
-- ... existing code ...
current_key_meta = {
valid = false,
package = "Chưa kích hoạt",
tier_label = "GUEST",
bound_hwid = "Chưa khóa máy",
device_count = 0,
max_devices = 1,
is_paused = false,
session_sig = "",
expire_ts = 0,
expire_str = "N/A",
time_left = "Chưa có",
executions = 0,
note = "",
can_self_reset = false,
reset_cooldown_left = "Sẵn sàng"
},
package_prices = {
["1 Ngày"] = 15000,
["1 Tuần"] = 55000,
["1 Tháng"] = 135000,
["1 Năm VIP"] = 200000,
["Vĩnh Viễn"] = 250000
},
server_keys = {},
-- ... existing code ...
local function refreshLicenseInspectorUI()
local meta = AppState.current_key_meta
local remText = meta.time_left
if meta.is_paused then
remText = "⏸️ Đang Bảo Lưu Giờ"
elseif meta.expire_ts and meta.expire_ts > os.time() then
remText = formatRemainingSeconds(meta.expire_ts - os.time())
end
local slotPart = string.format("📱 %d/%d máy", tonumber(meta.device_count or 0), tonumber(meta.max_devices or 1))
local sigPart = (meta.session_sig and meta.session_sig ~= "") and (" • 🔐 " .. tostring(meta.session_sig):sub(1, 8)) or ""
local notePart = (meta.note and meta.note ~= "") and (" • 📝 " .. meta.note) or ""
LicenseDetailLbl.Text = string.format(
"📦 Gói: %s (%s) | ⏳ Còn: %s\n💻 HWID: %s (%s) | 🚀 Chạy: %d%s%s",
tostring(meta.package or "VIP"),
tostring(meta.tier_label or "V29.0"),
tostring(remText or "N/A"),
tostring(meta.bound_hwid or "Tự Do"),
slotPart,
tonumber(meta.executions or 0),
sigPart,
notePart
)
end
-- ... existing code ...
local ActionRow1 = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 38),
Parent = TabPages.auth
})

local ActivateBtn = Create("TextButton", {
BackgroundColor3 = THEME.AccentBlue,
Size = UDim2.new(0.52, -4, 1, 0),
Font = Enum.Font.GothamBold,
Text = "⚡ KÍCH HOẠT & MỞ MENU VIP",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 12.5,
AutoButtonColor = false,
Parent = ActionRow1
})
AddCorner(ActivateBtn, 10)
RegisterTheme(ActivateBtn, "BackgroundColor3", "AccentBlue")

local AutoFetchBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.52, 4, 0, 0),
Size = UDim2.new(0.48, -4, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🔍 Tự Lấy Key Theo HWID",
TextColor3 = THEME.AccentCyan,
TextSize = 12,
AutoButtonColor = false,
Parent = ActionRow1
})
AddCorner(AutoFetchBtn, 10)
AddStroke(AutoFetchBtn, "AccentCyan", 1, 0.35)
RegisterTheme(AutoFetchBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(AutoFetchBtn, "TextColor3", "AccentCyan")

-- Khung đổi Giftcode Sự Kiện trực tiếp ngay trong Tab 1 (V29.0 SINGULARITY)
local GiftRow = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 38),
Parent = TabPages.auth
})
AddCorner(GiftRow, 10)
AddStroke(GiftRow, "BorderSubtle", 1, 0.25)
RegisterTheme(GiftRow, "BackgroundColor3", "BgElevated")

local GiftBox = Create("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 0, 5),
Size = UDim2.new(1, -142, 0, 28),
Font = Enum.Font.Code,
PlaceholderText = "🎁 Nhập Mã Giftcode Sự Kiện nhận Key miễn phí...",
PlaceholderColor3 = THEME.TextDim,
Text = "",
TextColor3 = THEME.TextMain,
TextSize = 11.5,
ClearTextOnFocus = false,
Parent = GiftRow
})
AddCorner(GiftBox, 7)
RegisterTheme(GiftBox, "BackgroundColor3", "BgInput")
RegisterTheme(GiftBox, "TextColor3", "TextMain")

local RedeemGiftBtn = Create("TextButton", {
BackgroundColor3 = THEME.AccentPurple,
Position = UDim2.new(1, -130, 0, 5),
Size = UDim2.new(0, 124, 0, 28),
Font = Enum.Font.GothamBold,
Text = "🎁 Đổi Giftcode",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11.5,
AutoButtonColor = false,
Parent = GiftRow
})
AddCorner(RedeemGiftBtn, 7)
RegisterTheme(RedeemGiftBtn, "BackgroundColor3", "AccentPurple")
-- ... existing code ...
local PackagesMeta = {
{ pkg = "Free", title = "🎁 Dùng Thử Free", price = "0đ • 20 Giờ", basePrice = 0, sub = "Vượt Link Web", isFree = true },
{ pkg = "1 Ngày", title = "⚡ Gói 1 Ngày", price = "15.000đ", basePrice = 15000, sub = "24 Giờ • Duyệt 3s", isFree = false },
{ pkg = "1 Tuần", title = "🔥 Gói 1 Tuần", price = "55.000đ", basePrice = 55000, sub = "7 Ngày • Tiết kiệm", isFree = false },
{ pkg = "1 Tháng", title = "💎 Gói 1 Tháng", price = "135.000đ", basePrice = 135000, sub = "30 Ngày • VIP", isFree = false },
{ pkg = "1 Năm VIP", title = "👑 Gói 1 Năm VIP", price = "200.000đ", basePrice = 200000, sub = "365 Ngày • Siêu rẻ", isFree = false },
{ pkg = "Vĩnh Viễn", title = "♾️ Gói Vĩnh Viễn", price = "250.000đ", basePrice = 250000, sub = "Trọn Đời • Không Hết Hạn", isFree = false }
}

local PackagePriceLabels = {}

local function updateShopPricesUI()
for _, item in ipairs(PackagePriceLabels) do
if item.basePrice > 0 then
local dynamicBase = tonumber(AppState.package_prices[item.pkg]) or item.basePrice
local finalP = dynamicBase
if AppState.voucher_discount > 0 then
finalP = math.max(2000, math.floor(dynamicBase * (100 - AppState.voucher_discount) / 100))
end
item.label.Text = tostring(finalP):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "") .. "đ"
end
end
end
-- ... existing code ...
if data.package_prices and type(data.package_prices) == "table" then
for k, v in pairs(data.package_prices) do
AppState.package_prices[k] = tonumber(v) or AppState.package_prices[k]
end
updateShopPricesUI()
end

    if data.games and type(data.games) == "table" and #data.games > 0 then
        AppState.games = data.games
        renderGameCatalogCards()
    end


-- ... existing code ...
AppState.current_key_meta = {
valid = true,
package = tostring(bk.package or "VIP"),
tier_label = tostring(bk.tier_label or "V29.0 VIP"),
bound_hwid = tostring(bk.bound_hwid or bk.hwid or DEVICE_HWID),
device_count = tonumber(bk.device_count) or 1,
max_devices = tonumber(bk.max_devices) or 1,
is_paused = (bk.is_paused == true),
session_sig = tostring(data.session_sig or ""),
expire_ts = tonumber(bk.expire) or 0,
expire_str = tostring(bk.expire_str or ""),
time_left = tostring(bk.time_left or ""),
executions = tonumber(bk.executions) or 0,
note = tostring(bk.note or ""),
can_self_reset = (bk.can_self_reset == true),
reset_cooldown_left = tostring(bk.reset_cooldown_left or "Sẵn sàng")
}
refreshLicenseInspectorUI()
setStatus(
string.format("✅ Đã đồng bộ Key [%s] (%s • Còn %s)", bestCode, AppState.current_key_meta.package, AppState.current_key_meta.time_left),
THEME.AccentCyan
)
-- ... existing code ...
AppState.current_key_meta = {
valid = true,
package = tostring(verifyData.package or "VIP"),
tier_label = tostring(verifyData.tier_label or "V29.0 VIP"),
bound_hwid = tostring(verifyData.bound_hwid or DEVICE_HWID),
device_count = tonumber(verifyData.device_count) or 1,
max_devices = tonumber(verifyData.max_devices) or 1,
is_paused = (verifyData.is_paused == true),
session_sig = tostring(verifyData.session_sig or ""),
expire_ts = tonumber(verifyData.expire) or 0,
expire_str = tostring(verifyData.expire_str or ""),
time_left = tostring(verifyData.time_left or ""),
executions = (tonumber(verifyData.executions) or 0) + 1,
note = tostring(verifyData.note or ""),
can_self_reset = (verifyData.can_self_reset == true),
reset_cooldown_left = tostring(verifyData.reset_cooldown_left or "Sẵn sàng")
}
refreshLicenseInspectorUI()
reportLoaderTelemetry(confirmedKey)
-- ... existing code ...
ActivateBtn.MouseButton1Click:Connect(function()
verifyAndExecuteScript(KeyBox.Text)
end)

AutoFetchBtn.MouseButton1Click:Connect(function()
runOmniSync(true, false)
end)

RedeemGiftBtn.MouseButton1Click:Connect(function()
if AppState.is_busy then return end
local gCode = sanitizeKey(GiftBox.Text)
if gCode == "" or #gCode < 2 then
showToast("⚠️ Vui lòng nhập Mã Giftcode Sự Kiện!", true)
return
end
GiftBox.Text = gCode
AppState.is_busy = true
setStatus("⏳ Đang đổi Mã Giftcode [" .. gCode .. "] trên Server V29.0...", THEME.StatusWarn)
task.spawn(function()
local data = apiRequest(
"/api/redeem_giftcode?code=" .. urlEncode(gCode) .. "&hwid=" .. urlEncode(DEVICE_HWID) .. "&game=rb",
"POST",
{ code = gCode, hwid = DEVICE_HWID, game = "rb" }
)
AppState.is_busy = false
if data and data.success and data.key then
local issuedKey = sanitizeKey(data.key)
GiftBox.Text = ""
KeyBox.Text = issuedKey
AppState.config.saved_key = issuedKey
saveConfig(AppState.config)
addToLocalVault(issuedKey, data.package or "Giftcode")
showToast("🎉 " .. tostring(data.message or ("Nhận Key " .. issuedKey .. " thành công!")), false)
runOmniSync(true, true)
else
local errMsg = (data and (data.message or data.detail)) or "Mã Giftcode không hợp lệ hoặc đã hết lượt!"
setStatus("⚠️ " .. tostring(errMsg), THEME.StatusErr)
showToast("⚠️ " .. tostring(errMsg), true)
end
end)
end)

ApplyVoucherBtn.MouseButton1Click:Connect(function()
-- ... existing code ...
