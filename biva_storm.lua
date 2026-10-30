-- ==============================================================================
-- BIVA STORM | SOVEREIGN MASTERPIECE LOADER & IN-GAME COMMAND CENTER
-- Kiến trúc Đồng Bộ Toàn Diện 100% Với BIVA STORM SOVEREIGN CORE:
--   [+] Tab 1: Kích Hoạt Bản Quyền, Đổi Giftcode Sự Kiện (/api/redeem_giftcode) & Đếm Ngược Real-time
--   [+] Tab 2: Cửa Hàng PayOS Chuẩn Giá (Miễn Phí = Vượt Link | 8K = 1 Ngày | 40K = 1 Tuần | 130K = 1 Tháng)
--             + Khung Chú Thích Cam Kết Bảo Hành Tự Động + Flash Sale & Mã Giảm Giá Voucher
--   [+] Tab 3: Kho Key Đa Thiết Bị (Multi-Device Slot 📱 X/Y máy), Gán HWID & Đổi Máy (Reset HWID)
--   [+] Tab 4: Lịch Sử Đơn Hàng & Trung Tâm Gửi Phiếu Hỗ Trợ / Xin Mở Khóa Đổi Máy (/api/support_ticket)
--   [+] Tab 5: Tiện Ích VIP (FPS Boost, Anti-AFK, Server Hop, FullBright) & 5 Chủ Đề Giao Diện
--   [+] Tab 6: Nhật Ký Đồng Bộ Thời Gian Thực (Live Sync Console) & Nhịp Tim Radar Online (/api/heartbeat)
-- ==============================================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local AnalyticsService = nil
pcall(function()
AnalyticsService = game:GetService("RbxAnalyticsService")
end)

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ==============================================================================
-- 1. CẤU HÌNH ENDPOINT, LƯU TRỮ CỤC BỘ & BẢNG MÀU CHỦ ĐỀ (5 THEMES)
-- ==============================================================================
local API_ENDPOINTS = {
"https://biva-hub.onrender.com"
}
local activeEndpointIndex = 1
local WEB_SHOP_URL = "https://biva-hub.onrender.com/index.html"
local SAVE_FILE_NAME = "BivaStorm_Sovereign_Config.json"
local VAULT_FILE_NAME = "BivaStorm_Sovereign_KeyVault.json"
local VERSION_TAG = "SOVEREIGN MASTERPIECE"

local DEFAULT_PRICING_FOOTNOTE = "💡 Chú thích: Miễn Phí = Vượt Link (20h) | 8.000đ = 1 Ngày | 40.000đ = 1 Tuần | 130.000đ = 1 Tháng. Mọi gói đều kích hoạt tự động sau 3 giây quét QR, tự khóa bảo vệ theo Mã Máy (HWID), hỗ trợ tự đổi máy miễn phí và cam kết bù giờ 100% khi bảo trì!"

local DEFAULT_GAME_CATALOG = {
{
id = "steal_egg",
code = "rb",
name = "⚡ Steal Egg / Biva Main Hub",
version = "SOVEREIGN",
status = "online",
features = { "Auto Task Assistant", "Smart Radar Overlay", "Quick Waypoint", "Anti-AFK Guard" }
},
{
id = "blox_fruits",
code = "rb",
name = "🏴‍☠️ Blox Fruits Sovereign",
version = "SOVEREIGN",
status = "online",
features = { "Quest Tracker", "Sea Event Timer", "Inventory Manager", "FPS Optimizer" }
},
{
id = "fisch",
code = "rb",
name = "🐟 Fisch Reel Assistant",
version = "SOVEREIGN",
status = "online",
features = { "Reel Timing HUD", "Weather & Biome Alert", "Fish Index Tracker", "Quick Sell UI" }
},
{
id = "dead_rails",
code = "rb",
name = "🚂 Dead Rails Tactical HUD",
version = "SOVEREIGN",
status = "online",
features = { "Fuel & Distance Meter", "Resource Locator", "Night Vision Filter", "Ping Stabilizer" }
},
{
id = "arise_crossover",
code = "rb",
name = "⚔️ Arise Crossover Companion",
version = "SOVEREIGN",
status = "online",
features = { "Dungeon Cooldown Timer", "Shadow Team Preset", "Performance Boost", "Auto Reconnect" }
},
{
id = "blue_lock",
code = "rb",
name = "⚽ Blue Lock Rivals Pro HUD",
version = "SOVEREIGN",
status = "online",
features = { "Stamina Bar HUD", "Trajectory Guide", "Camera FOV Tuner", "Ultra Low Latency" }
}
}

local THEMES = {
CyberBlue = {
Name = "Cyber Blue",
BgBase = Color3.fromRGB(5, 9, 20),
BgSurface = Color3.fromRGB(10, 17, 34),
BgElevated = Color3.fromRGB(15, 25, 50),
BgInput = Color3.fromRGB(6, 11, 24),
AccentCyan = Color3.fromRGB(0, 229, 255),
AccentBlue = Color3.fromRGB(37, 99, 235),
AccentPurple = Color3.fromRGB(168, 85, 247),
TextMain = Color3.fromRGB(248, 250, 252),
TextSub = Color3.fromRGB(148, 163, 184),
TextDim = Color3.fromRGB(100, 116, 139),
StatusOk = Color3.fromRGB(56, 189, 248),
StatusWarn = Color3.fromRGB(245, 158, 11),
StatusErr = Color3.fromRGB(244, 63, 94),
BorderSubtle = Color3.fromRGB(37, 99, 235)
},
CrimsonNeon = {
Name = "Crimson Neon",
BgBase = Color3.fromRGB(16, 6, 12),
BgSurface = Color3.fromRGB(28, 10, 20),
BgElevated = Color3.fromRGB(42, 14, 30),
BgInput = Color3.fromRGB(18, 6, 14),
AccentCyan = Color3.fromRGB(255, 46, 99),
AccentBlue = Color3.fromRGB(225, 29, 72),
AccentPurple = Color3.fromRGB(244, 114, 182),
TextMain = Color3.fromRGB(255, 241, 242),
TextSub = Color3.fromRGB(253, 164, 175),
TextDim = Color3.fromRGB(159, 18, 57),
StatusOk = Color3.fromRGB(52, 211, 153),
StatusWarn = Color3.fromRGB(251, 191, 36),
StatusErr = Color3.fromRGB(244, 63, 94),
BorderSubtle = Color3.fromRGB(225, 29, 72)
},
EmeraldMatrix = {
Name = "Emerald Matrix",
BgBase = Color3.fromRGB(4, 15, 12),
BgSurface = Color3.fromRGB(8, 26, 20),
BgElevated = Color3.fromRGB(13, 38, 30),
BgInput = Color3.fromRGB(5, 18, 14),
AccentCyan = Color3.fromRGB(16, 185, 129),
AccentBlue = Color3.fromRGB(5, 150, 105),
AccentPurple = Color3.fromRGB(52, 211, 153),
TextMain = Color3.fromRGB(236, 253, 245),
TextSub = Color3.fromRGB(167, 243, 208),
TextDim = Color3.fromRGB(110, 231, 183),
StatusOk = Color3.fromRGB(16, 185, 129),
StatusWarn = Color3.fromRGB(245, 158, 11),
StatusErr = Color3.fromRGB(244, 63, 94),
BorderSubtle = Color3.fromRGB(16, 185, 129)
},
RoyalAmethyst = {
Name = "Royal Amethyst",
BgBase = Color3.fromRGB(11, 6, 22),
BgSurface = Color3.fromRGB(19, 11, 38),
BgElevated = Color3.fromRGB(29, 17, 56),
BgInput = Color3.fromRGB(13, 7, 26),
AccentCyan = Color3.fromRGB(192, 132, 252),
AccentBlue = Color3.fromRGB(147, 51, 234),
AccentPurple = Color3.fromRGB(232, 121, 249),
TextMain = Color3.fromRGB(250, 245, 255),
TextSub = Color3.fromRGB(216, 180, 254),
TextDim = Color3.fromRGB(147, 51, 234),
StatusOk = Color3.fromRGB(56, 189, 248),
StatusWarn = Color3.fromRGB(245, 158, 11),
StatusErr = Color3.fromRGB(244, 63, 94),
BorderSubtle = Color3.fromRGB(168, 85, 247)
},
SolarGold = {
Name = "Solar Gold",
BgBase = Color3.fromRGB(16, 12, 5),
BgSurface = Color3.fromRGB(28, 21, 9),
BgElevated = Color3.fromRGB(42, 31, 14),
BgInput = Color3.fromRGB(18, 14, 6),
AccentCyan = Color3.fromRGB(251, 191, 36),
AccentBlue = Color3.fromRGB(217, 119, 6),
AccentPurple = Color3.fromRGB(245, 158, 11),
TextMain = Color3.fromRGB(254, 252, 232),
TextSub = Color3.fromRGB(253, 230, 138),
TextDim = Color3.fromRGB(180, 83, 9),
StatusOk = Color3.fromRGB(52, 211, 153),
StatusWarn = Color3.fromRGB(251, 191, 36),
StatusErr = Color3.fromRGB(244, 63, 94),
BorderSubtle = Color3.fromRGB(245, 158, 11)
}
}

local THEME = THEMES.CyberBlue
local ThemeBindings = {}

-- ==============================================================================
-- 2. HÀM TIỆN ÍCH CHUẨN HÓA HWID / KEY & TƯƠNG THÍCH MỌI EXECUTOR
-- ==============================================================================
local function sanitizeHwid(raw)
if not raw then return "" end
local s = tostring(raw):gsub("%s+", "")
s = s:gsub("^[hH][wW][iI][dD][:=-]*", "")
s = s:gsub("^[dD][eE][vV][iI][cC][eE][:=-]*", "")
s = s:gsub("[^%w%-_]", ""):upper()
return s:sub(1, 64)
end

local function sanitizeKey(raw)
if not raw then return "" end
local s = tostring(raw):gsub("%s+", "")
s = s:gsub("^[kK][eE][yY][:=-]*", "")
s = s:gsub("[^%w%-]", ""):upper()
return s:sub(1, 64)
end

local function maskKeyString(k)
local clean = sanitizeKey(k)
if #clean <= 6 then return clean end
return clean:sub(1, 5) .. "••••" .. clean:sub(#clean - 2, #clean)
end

local function formatCurrencyVND(amount)
local n = math.max(0, math.floor(tonumber(amount) or 0))
if n == 0 then return "Miễn Phí" end
local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
return formatted .. "đ"
end

local function getExecutorName()
local ok, name = pcall(function()
if type(identifyexecutor) == "function" then
local n, v = identifyexecutor()
return tostring(n or "Executor") .. (v and (" " .. tostring(v)) or "")
elseif type(getexecutorname) == "function" then
return tostring(getexecutorname())
end
return "Roblox Executor"
end)
return (ok and name and name ~= "") and name or "Roblox Client"
end

local function resolveDeviceHwid()
local rawHwid = ""
pcall(function()
if type(gethwid) == "function" then
rawHwid = gethwid()
elseif AnalyticsService and type(AnalyticsService.GetClientId) == "function" then
rawHwid = AnalyticsService:GetClientId()
end
end)
local cleaned = sanitizeHwid(rawHwid)
if #cleaned < 4 then
cleaned = "RBXDEVICE-" .. tostring(LocalPlayer.UserId or 100001)
end
return cleaned
end

local DEVICE_HWID = resolveDeviceHwid()
local EXECUTOR_TITLE = getExecutorName()

local function safeCopyClipboard(text)
if not text or text == "" then return false end
local ok = pcall(function()
if type(setclipboard) == "function" then
setclipboard(tostring(text))
elseif type(toclipboard) == "function" then
toclipboard(tostring(text))
elseif Clipboard and type(Clipboard.set) == "function" then
Clipboard.set(tostring(text))
else
error("No clipboard API")
end
end)
return ok
end

local function safeGetClipboard()
local ok, res = pcall(function()
if type(getclipboard) == "function" then
return getclipboard()
end
return ""
end)
if ok and type(res) == "string" then
return res
end
return ""
end

local function loadConfig()
local defaultCfg = {
saved_key = "",
selected_game = "steal_egg",
auto_login = true,
anti_afk = true,
hide_key = false,
theme_id = "CyberBlue",
pending_order_id = "",
pending_package = ""
}
pcall(function()
if type(isfile) == "function" and type(readfile) == "function" and isfile(SAVE_FILE_NAME) then
local raw = readfile(SAVE_FILE_NAME)
local decoded = HttpService:JSONDecode(raw)
if type(decoded) == "table" then
for k, v in pairs(decoded) do
defaultCfg[k] = v
end
end
end
end)
local envKey = ""
pcall(function()
local g = (type(getgenv) == "function") and getgenv() or _G
if g and type(g.BIVA_AUTO_KEY) == "string" and #g.BIVA_AUTO_KEY >= 4 then
envKey = sanitizeKey(g.BIVA_AUTO_KEY)
end
end)
if envKey ~= "" then
defaultCfg.saved_key = envKey
else
defaultCfg.saved_key = sanitizeKey(defaultCfg.saved_key)
end
if THEMES[defaultCfg.theme_id] then
THEME = THEMES[defaultCfg.theme_id]
end
return defaultCfg
end

local function saveConfig(cfg)
pcall(function()
if type(writefile) == "function" then
writefile(SAVE_FILE_NAME, HttpService:JSONEncode(cfg))
end
end)
end

local function loadLocalVault()
local vault = {}
pcall(function()
if type(isfile) == "function" and type(readfile) == "function" and isfile(VAULT_FILE_NAME) then
local decoded = HttpService:JSONDecode(readfile(VAULT_FILE_NAME))
if type(decoded) == "table" then
vault = decoded
end
end
end)
return vault
end

local function addToLocalVault(keyCode, pkgName)
local clean = sanitizeKey(keyCode)
if clean == "" then return end
local vault = loadLocalVault()
local updated = {
{
key = clean,
package = tostring(pkgName or "VIP"),
saved_at = os.date("%H:%M %d/%m")
}
}
for _, item in ipairs(vault) do
if type(item) == "table" and sanitizeKey(item.key) ~= clean and #updated < 15 then
table.insert(updated, item)
end
end
pcall(function()
if type(writefile) == "function" then
writefile(VAULT_FILE_NAME, HttpService:JSONEncode(updated))
end
end)
end

local function urlEncode(str)
if not str then return "" end
str = tostring(str)
str = string.gsub(str, "\n", "\r\n")
str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
return string.format("%%%02X", string.byte(c))
end)
return string.gsub(str, " ", "+")
end

local function formatRemainingSeconds(rem)
rem = math.max(0, math.floor(tonumber(rem) or 0))
if rem <= 0 then return "Đã hết hạn" end
if rem > 3000 * 86400 then return "Vĩnh Viễn" end
local d = math.floor(rem / 86400)
local h = math.floor((rem % 86400) / 3600)
local m = math.floor((rem % 3600) / 60)
local s = rem % 60
if d > 0 then
return string.format("%d ngày %02dh %02dp", d, h, m)
elseif h > 0 then
return string.format("%02dh %02dp %02ds", h, m, s)
end
return string.format("%02dp %02ds", m, s)
end

-- ==============================================================================
-- 3. TRẠNG THÁI ỨNG DỤNG & NHẬT KÝ ĐỒNG BỘ (SYNC CONSOLE LOG)
-- ==============================================================================
local AppState = {
config = loadConfig(),
sync_revision = 0,
last_latency_ms = 0,
admin_notice = "Hệ thống BIVA STORM SOVEREIGN CORE hoạt động ổn định 100%!",
pricing_footnote = DEFAULT_PRICING_FOOTNOTE,
maintenance = false,
is_blacklisted = false,
blacklist_reason = "",
active_voucher = "",
voucher_discount = 0,
voucher_bonus_hours = 0,
flash_sale = {
active = false,
discount_percent = 0,
bonus_hours = 0,
remaining_text = "",
title = ""
},
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
-- Bảng giá chuẩn Masterpiece: Miễn Phí = Vượt Link | 8K = 1 Ngày | 40K = 1 Tuần | 130K = 1 Tháng
package_prices = {
["1 Ngày"] = 8000,
["1 Tuần"] = 40000,
["1 Tháng"] = 130000,
["1 Năm VIP"] = 200000,
["Vĩnh Viễn"] = 250000
},
server_keys = {},
server_orders = {},
server_tickets = {},
games = DEFAULT_GAME_CATALOG,
sync_logs = {},
is_busy = false,
watching_order = false,
minimized = false
}

local LEGACY_PRICE_MIGRATION = {
["1 Ngày"] = { 15000, 8000 },
["1 Tuần"] = { 55000, 40000 },
["1 Tháng"] = { 135000, 130000 }
}

local renderSyncLogsUI = function() end

local function pushSyncLog(tag, message, isErr)
local entry = {
time = os.date("%H:%M:%S"),
tag = tostring(tag or "SYNC"),
msg = tostring(message or ""),
err = isErr and true or false
}
table.insert(AppState.sync_logs, 1, entry)
if #AppState.sync_logs > 40 then
table.remove(AppState.sync_logs)
end
pcall(renderSyncLogsUI)
end

-- ==============================================================================
-- 4. LÕI HTTP MULTI-ENDPOINT FAILOVER (HỖ TRỢ REQUEST + HTTPGET FALLBACK)
-- ==============================================================================
local httpRequestFunc = nil
pcall(function()
httpRequestFunc = (syn and syn.request)
or (http and http.request)
or http_request
or (fluxus and fluxus.request)
or request
end)

local function rawHttpCall(url, method, bodyTable)
method = method or "GET"
if httpRequestFunc then
local headers = {
["Accept"] = "application/json, text/plain, /",
["Cache-Control"] = "no-cache"
}
local bodyStr = nil
if bodyTable then
headers["Content-Type"] = "application/json"
bodyStr = HttpService:JSONEncode(bodyTable)
end
local ok, res = pcall(function()
return httpRequestFunc({
Url = url,
Method = method,
Headers = headers,
Body = bodyStr
})
end)
if ok and type(res) == "table" and res.Body then
return true, tonumber(res.StatusCode) or 200, tostring(res.Body)
end
end

local okGet, bodyGet = pcall(function()
    return game:HttpGet(url)
end)
if okGet and type(bodyGet) == "string" then
    return true, 200, bodyGet
end
return false, 0, ""


end

local function apiRequest(pathWithQuery, method, bodyTable, expectPlainText)
local sep = string.find(pathWithQuery, "?", 1, true) and "&" or "?"
local stampedPath = pathWithQuery .. sep .. "_t=" .. tostring(math.floor(os.clock() * 1000))

for i = 0, #API_ENDPOINTS - 1 do
    local idx = ((activeEndpointIndex - 1 + i) % #API_ENDPOINTS) + 1
    local baseUrl = API_ENDPOINTS[idx]
    local fullUrl = baseUrl .. stampedPath
    local t0 = os.clock()
    local ok, status, rawBody = rawHttpCall(fullUrl, method, bodyTable)
    local latency = math.max(5, math.floor((os.clock() - t0) * 1000))

    if ok and status > 0 and status < 500 and rawBody ~= "" then
        activeEndpointIndex = idx
        AppState.last_latency_ms = latency
        if expectPlainText then
            return rawBody, status, latency
        end
        local decOk, decoded = pcall(function()
            return HttpService:JSONDecode(rawBody)
        end)
        if decOk and type(decoded) == "table" then
            return decoded, status, latency
        end
    end
end
return nil, 0, 0


end

-- ==============================================================================
-- 5. KHỞI TẠO GIAO DIỆN CYBER COMMAND CENTER (6 TAB CHUYÊN SÂU)
-- ==============================================================================
local GuiParent = nil
pcall(function()
if type(gethui) == "function" then
GuiParent = gethui()
end
end)
if not GuiParent then
local okCore = pcall(function()
return CoreGui.Name
end)
GuiParent = okCore and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end

for _, oldName in ipairs({ "BivaStormV26OmniLoader", "BivaStormV27HyperionLoader", "BivaStormSovereignLoader" }) do
local oldGui = GuiParent:FindFirstChild(oldName)
if oldGui then
pcall(function() oldGui:Destroy() end)
end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BivaStormSovereignLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local function RegisterTheme(inst, prop, themeKey)
table.insert(ThemeBindings, { inst = inst, prop = prop, key = themeKey })
pcall(function()
inst[prop] = THEME[themeKey]
end)
end

local function ApplyThemePalette(themeId)
local nextPalette = THEMES[themeId]
if not nextPalette then return end
THEME = nextPalette
AppState.config.theme_id = themeId
saveConfig(AppState.config)
for _, b in ipairs(ThemeBindings) do
if b.inst and b.inst.Parent and THEME[b.key] then
pcall(function()
TweenService:Create(b.inst, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
[b.prop] = THEME[b.key]
}):Play()
end)
end
end
end

local function Create(className, props)
local inst = Instance.new(className)
for k, v in pairs(props or {}) do
if k ~= "Parent" then
inst[k] = v
end
end
if props and props.Parent then
inst.Parent = props.Parent
end
return inst
end

local function AddCorner(parent, radius)
return Create("UICorner", {
CornerRadius = UDim.new(0, radius or 10),
Parent = parent
})
end

local function AddStroke(parent, themeKey, thickness, transparency)
local st = Create("UIStroke", {
Color = THEME[themeKey or "BorderSubtle"] or Color3.fromRGB(37, 99, 235),
Thickness = thickness or 1,
Transparency = transparency or 0.35,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
Parent = parent
})
if themeKey then
RegisterTheme(st, "Color", themeKey)
end
return st
end

local function MakeDraggable(dragHandle, targetFrame)
local dragging = false
local dragInput, dragStart, startPos

dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = targetFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragHandle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        targetFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)


end

-- HỆ THỐNG TOAST NOTIFICATION
local ToastContainer = Create("Frame", {
Name = "ToastContainer",
BackgroundTransparency = 1,
AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.new(0.5, 0, 0, 16),
Size = UDim2.new(0, 400, 0, 130),
ZIndex = 120,
Parent = ScreenGui
})

Create("UIListLayout", {
Padding = UDim.new(0, 6),
HorizontalAlignment = Enum.HorizontalAlignment.Center,
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = ToastContainer
})

local function showToast(msg, isError)
local card = Create("Frame", {
BackgroundColor3 = THEME.BgSurface,
Size = UDim2.new(1, 0, 0, 36),
BackgroundTransparency = 0.06,
ZIndex = 121,
Parent = ToastContainer
})
AddCorner(card, 10)
Create("UIStroke", {
Color = isError and THEME.StatusErr or THEME.AccentCyan,
Thickness = 1.4,
Transparency = 0.15,
Parent = card
})

Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -24, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = (isError and "❌ " or "⚡ ") .. tostring(msg),
    TextColor3 = THEME.TextMain,
    TextSize = 12,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 122,
    Parent = card
})

task.delay(2.8, function()
    if card and card.Parent then
        local tw = TweenService:Create(card, TweenInfo.new(0.22), { BackgroundTransparency = 1 })
        tw:Play()
        tw.Completed:Wait()
        if card and card.Parent then
            card:Destroy()
        end
    end
end)


end

-- NÚT NỔI THU NHỎ KÈM ĐỒNG HỒ ĐẾM NGƯỢC LIVE (FLOATING PILL WIDGET)
local FloatingOrb = Create("TextButton", {
Name = "FloatingOrb",
BackgroundColor3 = THEME.BgSurface,
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 16, 0.5, 0),
Size = UDim2.new(0, 178, 0, 40),
Font = Enum.Font.GothamBold,
Text = "⚡ BIVA SOVEREIGN",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
Visible = false,
AutoButtonColor = false,
ZIndex = 95,
Parent = ScreenGui
})
AddCorner(FloatingOrb, 20)
AddStroke(FloatingOrb, "AccentCyan", 1.5, 0.15)
RegisterTheme(FloatingOrb, "BackgroundColor3", "BgSurface")
RegisterTheme(FloatingOrb, "TextColor3", "AccentCyan")
MakeDraggable(FloatingOrb, FloatingOrb)

-- KHUNG CHÍNH (660 x 450)
local MainWindow = Create("Frame", {
Name = "MainWindow",
BackgroundColor3 = THEME.BgBase,
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 0),
Size = UDim2.new(0, 660, 0, 450),
ClipsDescendants = true,
Parent = ScreenGui
})
AddCorner(MainWindow, 16)
AddStroke(MainWindow, "AccentCyan", 1.5, 0.25)
RegisterTheme(MainWindow, "BackgroundColor3", "BgBase")

-- THANH TIÊU ĐỀ TRÊN CÙNG (HEADER BAR)
local TopHeader = Create("Frame", {
Name = "TopHeader",
BackgroundColor3 = THEME.BgSurface,
Size = UDim2.new(1, 0, 0, 50),
Parent = MainWindow
})
AddCorner(TopHeader, 16)
RegisterTheme(TopHeader, "BackgroundColor3", "BgSurface")
MakeDraggable(TopHeader, MainWindow)

local BrandBadge = Create("Frame", {
BackgroundColor3 = THEME.AccentBlue,
Position = UDim2.new(0, 12, 0.5, -15),
Size = UDim2.new(0, 30, 0, 30),
Parent = TopHeader
})
AddCorner(BrandBadge, 9)
RegisterTheme(BrandBadge, "BackgroundColor3", "AccentBlue")

Create("TextLabel", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 1, 0),
Font = Enum.Font.GothamBlack,
Text = "⚡",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 15,
Parent = BrandBadge
})

local HeaderTitle = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 50, 0, 7),
Size = UDim2.new(0, 330, 0, 18),
Font = Enum.Font.GothamBlack,
Text = "BIVA STORM | " .. VERSION_TAG,
TextColor3 = THEME.TextMain,
TextSize = 14,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = TopHeader
})
RegisterTheme(HeaderTitle, "TextColor3", "TextMain")

local HeaderSub = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 50, 0, 26),
Size = UDim2.new(0, 360, 0, 16),
Font = Enum.Font.GothamMedium,
Text = "🟢 " .. EXECUTOR_TITLE .. " • REV #0 • Ping: --ms",
TextColor3 = THEME.AccentCyan,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = TopHeader
})
RegisterTheme(HeaderSub, "TextColor3", "AccentCyan")

local QuickSyncBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(1, -152, 0.5, -14),
Size = UDim2.new(0, 74, 0, 28),
Font = Enum.Font.GothamBold,
Text = "🔄 Sync",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
AutoButtonColor = false,
Parent = TopHeader
})
AddCorner(QuickSyncBtn, 8)
AddStroke(QuickSyncBtn, "AccentCyan", 1, 0.5)
RegisterTheme(QuickSyncBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(QuickSyncBtn, "TextColor3", "AccentCyan")

local MinimizeBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(1, -72, 0.5, -14),
Size = UDim2.new(0, 28, 0, 28),
Font = Enum.Font.GothamBold,
Text = "—",
TextColor3 = THEME.TextMain,
TextSize = 13,
AutoButtonColor = false,
Parent = TopHeader
})
AddCorner(MinimizeBtn, 8)
RegisterTheme(MinimizeBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(MinimizeBtn, "TextColor3", "TextMain")

local CloseBtn = Create("TextButton", {
BackgroundColor3 = Color3.fromRGB(65, 16, 30),
Position = UDim2.new(1, -38, 0.5, -14),
Size = UDim2.new(0, 28, 0, 28),
Font = Enum.Font.GothamBold,
Text = "✕",
TextColor3 = THEME.StatusErr,
TextSize = 13,
AutoButtonColor = false,
Parent = TopHeader
})
AddCorner(CloseBtn, 8)

-- THANH THÔNG BÁO TRỰC TIẾP TỪ ADMIN (LIVE BROADCAST BAR)
local BroadcastBar = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 10, 0, 56),
Size = UDim2.new(1, -20, 0, 26),
Parent = MainWindow
})
AddCorner(BroadcastBar, 7)
AddStroke(BroadcastBar, "BorderSubtle", 1, 0.45)
RegisterTheme(BroadcastBar, "BackgroundColor3", "BgElevated")

local BroadcastText = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamBold,
Text = "📢 Thông báo Server: " .. AppState.admin_notice,
TextColor3 = THEME.TextSub,
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = BroadcastBar
})
RegisterTheme(BroadcastText, "TextColor3", "TextSub")

-- CỘT ĐIỀU HƯỚNG 6 TAB BÊN TRÁI (SIDEBAR NAVIGATION)
local Sidebar = Create("Frame", {
BackgroundColor3 = THEME.BgSurface,
Position = UDim2.new(0, 10, 0, 88),
Size = UDim2.new(0, 158, 1, -98),
Parent = MainWindow
})
AddCorner(Sidebar, 12)
AddStroke(Sidebar, "BorderSubtle", 1, 0.4)
RegisterTheme(Sidebar, "BackgroundColor3", "BgSurface")

local SidebarList = Create("Frame", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 6, 0, 6),
Size = UDim2.new(1, -12, 1, -86),
Parent = Sidebar
})

Create("UIListLayout", {
Padding = UDim.new(0, 5),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = SidebarList
})

-- Hộp hiển thị HWID ở đáy Sidebar
local HwidBoxFrame = Create("Frame", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 1, -74),
Size = UDim2.new(1, -12, 0, 68),
Parent = Sidebar
})
AddCorner(HwidBoxFrame, 9)
AddStroke(HwidBoxFrame, "BorderSubtle", 1, 0.4)
RegisterTheme(HwidBoxFrame, "BackgroundColor3", "BgInput")

Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 5),
Size = UDim2.new(1, -16, 0, 13),
Font = Enum.Font.GothamBold,
Text = "MÃ MÁY (HWID):",
TextColor3 = THEME.TextDim,
TextSize = 9.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = HwidBoxFrame
})

local HwidValueLbl = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 19),
Size = UDim2.new(1, -16, 0, 16),
Font = Enum.Font.Code,
Text = DEVICE_HWID,
TextColor3 = THEME.AccentCyan,
TextSize = 10.5,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = HwidBoxFrame
})
RegisterTheme(HwidValueLbl, "TextColor3", "AccentCyan")

local CopyHwidBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 6, 0, 39),
Size = UDim2.new(1, -12, 0, 23),
Font = Enum.Font.GothamBold,
Text = "📋 Copy Mã HWID",
TextColor3 = THEME.TextMain,
TextSize = 10.5,
AutoButtonColor = false,
Parent = HwidBoxFrame
})
AddCorner(CopyHwidBtn, 6)
RegisterTheme(CopyHwidBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(CopyHwidBtn, "TextColor3", "TextMain")

CopyHwidBtn.MouseButton1Click:Connect(function()
if safeCopyClipboard(DEVICE_HWID) then
showToast("Đã copy Mã Máy (HWID): " .. DEVICE_HWID, false)
else
showToast("HWID: " .. DEVICE_HWID, false)
end
end)

-- VÙNG NỘI DUNG CHÍNH BÊN PHẢI (CONTENT CONTAINER)
local ContentArea = Create("Frame", {
BackgroundColor3 = THEME.BgSurface,
Position = UDim2.new(0, 176, 0, 88),
Size = UDim2.new(1, -186, 1, -98),
ClipsDescendants = true,
Parent = MainWindow
})
AddCorner(ContentArea, 12)
AddStroke(ContentArea, "BorderSubtle", 1, 0.4)
RegisterTheme(ContentArea, "BackgroundColor3", "BgSurface")

local TabButtons = {}
local TabPages = {}

local function switchTab(tabId)
for id, page in pairs(TabPages) do
page.Visible = (id == tabId)
end
for id, btn in pairs(TabButtons) do
local isAct = (id == tabId)
TweenService:Create(btn, TweenInfo.new(0.18), {
BackgroundColor3 = isAct and THEME.BgInput or THEME.BgElevated,
TextColor3 = isAct and THEME.AccentCyan or THEME.TextSub
}):Play()
end
end

local function createNavTab(tabId, labelText, order)
local btn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
LayoutOrder = order,
Size = UDim2.new(1, 0, 0, 34),
Font = Enum.Font.GothamBold,
Text = "  " .. labelText,
TextColor3 = THEME.TextSub,
TextSize = 11.5,
TextXAlignment = Enum.TextXAlignment.Left,
AutoButtonColor = false,
Parent = SidebarList
})
AddCorner(btn, 8)

local page = Create("ScrollingFrame", {
    Name = "Page_" .. tabId,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(1, -20, 1, -20),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.AccentCyan,
    Visible = false,
    Parent = ContentArea
})
Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = page
})

btn.MouseButton1Click:Connect(function()
    switchTab(tabId)
end)

TabButtons[tabId] = btn
TabPages[tabId] = page
return page


end

createNavTab("auth", "🔑 Kích Hoạt & Game", 1)
createNavTab("shop", "🛒 Bảng Giá 8K/40K/130K", 2)
createNavTab("vault", "🛡️ Kho Key & Đổi Máy", 3)
createNavTab("orders", "🧾 Đơn & Hỗ Trợ", 4)
createNavTab("utils", "⚙️ Tiện Ích & Theme", 5)
createNavTab("console", "📡 Nhật Ký Đồng Bộ", 6)

-- ==============================================================================
-- 6. XÂY DỰNG TAB 1: KÍCH HOẠT BẢN QUYỀN, ĐỔI GIFTCODE & DANH SÁCH GAME
-- ==============================================================================
local GameSelectHeader = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 20),
Parent = TabPages.auth
})

Create("TextLabel", {
BackgroundTransparency = 1,
Size = UDim2.new(0.55, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🎮 CHỌN TỰA GAME HỖ TRỢ:",
TextColor3 = THEME.TextSub,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = GameSelectHeader
})

local SelectedFeatureTag = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0.38, 0, 0, 0),
Size = UDim2.new(0.62, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "✨ Full Tính Năng Sovereign",
TextColor3 = THEME.AccentCyan,
TextSize = 10.5,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Right,
Parent = GameSelectHeader
})
RegisterTheme(SelectedFeatureTag, "TextColor3", "AccentCyan")

local GameGridFrame = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 74),
Parent = TabPages.auth
})

Create("UIGridLayout", {
CellPadding = UDim2.new(0, 6, 0, 6),
CellSize = UDim2.new(0.32, 0, 0, 34),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = GameGridFrame
})

local GameOptionButtons = {}

local function updateSelectedGameDisplay(gameId)
AppState.config.selected_game = gameId
saveConfig(AppState.config)
for id, btn in pairs(GameOptionButtons) do
local isSel = (id == gameId)
btn.BackgroundColor3 = isSel and THEME.BgInput or THEME.BgElevated
btn.TextColor3 = isSel and THEME.AccentCyan or THEME.TextSub
end
for _, g in ipairs(AppState.games) do
if g.id == gameId and type(g.features) == "table" then
SelectedFeatureTag.Text = "✨ " .. table.concat(g.features, " • ")
break
end
end
end

local function renderGameCatalogCards()
for _, child in ipairs(GameGridFrame:GetChildren()) do
if child:IsA("TextButton") then
child:Destroy()
end
end
GameOptionButtons = {}
for idx, g in ipairs(AppState.games) do
local isSel = (AppState.config.selected_game == g.id)
local gBtn = Create("TextButton", {
BackgroundColor3 = isSel and THEME.BgInput or THEME.BgElevated,
LayoutOrder = idx,
Font = Enum.Font.GothamBold,
Text = tostring(g.name or g.id),
TextColor3 = isSel and THEME.AccentCyan or THEME.TextSub,
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
AutoButtonColor = false,
Parent = GameGridFrame
})
AddCorner(gBtn, 8)
AddStroke(gBtn, "BorderSubtle", 1, 0.35)
GameOptionButtons[g.id] = gBtn

    gBtn.MouseButton1Click:Connect(function()
        updateSelectedGameDisplay(g.id)
        showToast("Đã chọn: " .. tostring(g.name), false)
    end)
end
local rows = math.ceil(#AppState.games / 3)
GameGridFrame.Size = UDim2.new(1, 0, 0, math.max(36, rows * 40 - 6))
updateSelectedGameDisplay(AppState.config.selected_game)


end

renderGameCatalogCards()

-- Khung nhập Mã Key & Nút Ẩn/Hiện/Dán
local KeyInputCard = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 68),
Parent = TabPages.auth
})
AddCorner(KeyInputCard, 10)
AddStroke(KeyInputCard, "BorderSubtle", 1, 0.3)
RegisterTheme(KeyInputCard, "BackgroundColor3", "BgElevated")

Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 6),
Size = UDim2.new(1, -20, 0, 14),
Font = Enum.Font.GothamBold,
Text = "NHẬP MÃ KEY BẢN QUYỀN (RB-XXXX-XXXX / FREE-XXXX / GIFT-XXXX):",
TextColor3 = THEME.TextSub,
TextSize = 10.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = KeyInputCard
})

local KeyBox = Create("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 10, 0, 24),
Size = UDim2.new(1, -172, 0, 34),
Font = Enum.Font.Code,
PlaceholderText = "Dán Mã Key hoặc bấm 'Tự Lấy Key Theo HWID'...",
PlaceholderColor3 = THEME.TextDim,
Text = AppState.config.saved_key or "",
TextColor3 = THEME.AccentCyan,
TextSize = 13,
ClearTextOnFocus = false,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = KeyInputCard
})
AddCorner(KeyBox, 8)
AddStroke(KeyBox, "BorderSubtle", 1, 0.35)
RegisterTheme(KeyBox, "BackgroundColor3", "BgInput")
RegisterTheme(KeyBox, "TextColor3", "AccentCyan")

local MaskToggleBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgSurface,
Position = UDim2.new(1, -156, 0, 24),
Size = UDim2.new(0, 36, 0, 34),
Font = Enum.Font.GothamBold,
Text = "👁️",
TextColor3 = THEME.TextMain,
TextSize = 13,
AutoButtonColor = false,
Parent = KeyInputCard
})
AddCorner(MaskToggleBtn, 8)
RegisterTheme(MaskToggleBtn, "BackgroundColor3", "BgSurface")

local PasteKeyBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgSurface,
Position = UDim2.new(1, -114, 0, 24),
Size = UDim2.new(0, 64, 0, 34),
Font = Enum.Font.GothamBold,
Text = "📋 Dán",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
AutoButtonColor = false,
Parent = KeyInputCard
})
AddCorner(PasteKeyBtn, 8)
RegisterTheme(PasteKeyBtn, "BackgroundColor3", "BgSurface")
RegisterTheme(PasteKeyBtn, "TextColor3", "AccentCyan")

local ClearKeyBtn = Create("TextButton", {
BackgroundColor3 = Color3.fromRGB(58, 16, 28),
Position = UDim2.new(1, -44, 0, 24),
Size = UDim2.new(0, 34, 0, 34),
Font = Enum.Font.GothamBold,
Text = "✖",
TextColor3 = THEME.StatusErr,
TextSize = 12,
AutoButtonColor = false,
Parent = KeyInputCard
})
AddCorner(ClearKeyBtn, 8)

MaskToggleBtn.MouseButton1Click:Connect(function()
AppState.config.hide_key = not AppState.config.hide_key
saveConfig(AppState.config)
if AppState.config.hide_key then
KeyBox.Text = maskKeyString(AppState.config.saved_key)
MaskToggleBtn.Text = "🙈"
else
KeyBox.Text = AppState.config.saved_key or ""
MaskToggleBtn.Text = "👁️"
end
end)

KeyBox.Focused:Connect(function()
if AppState.config.hide_key then
KeyBox.Text = AppState.config.saved_key or ""
end
end)

KeyBox.FocusLost:Connect(function()
local cleaned = sanitizeKey(KeyBox.Text)
if not string.find(KeyBox.Text, "•", 1, true) then
AppState.config.saved_key = cleaned
saveConfig(AppState.config)
end
if AppState.config.hide_key then
KeyBox.Text = maskKeyString(AppState.config.saved_key)
else
KeyBox.Text = AppState.config.saved_key
end
end)

PasteKeyBtn.MouseButton1Click:Connect(function()
local clip = sanitizeKey(safeGetClipboard())
if #clip >= 4 then
AppState.config.saved_key = clip
saveConfig(AppState.config)
KeyBox.Text = AppState.config.hide_key and maskKeyString(clip) or clip
showToast("Đã dán Key: " .. clip, false)
else
KeyBox:CaptureFocus()
showToast("Hãy nhấn giữ vào ô Key để dán!", false)
end
end)

ClearKeyBtn.MouseButton1Click:Connect(function()
AppState.config.saved_key = ""
saveConfig(AppState.config)
KeyBox.Text = ""
showToast("Đã xóa ô nhập Key!", false)
end)

-- Hàng nút Kích Hoạt & Tự Lấy Key Theo HWID
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

-- Khung đổi Giftcode Sự Kiện trực tiếp ngay trong Tab 1
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

-- Thẻ Thông Tin Bản Quyền Chi Tiết (License Inspector Card)
local LicenseInspectorCard = Create("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 68),
Parent = TabPages.auth
})
AddCorner(LicenseInspectorCard, 10)
AddStroke(LicenseInspectorCard, "BorderSubtle", 1, 0.35)
RegisterTheme(LicenseInspectorCard, "BackgroundColor3", "BgInput")

local StatusBoxLbl = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 18),
Font = Enum.Font.GothamBold,
Text = "💡 Trạng thái: Đang đồng bộ dữ liệu từ Server Sovereign Core...",
TextColor3 = THEME.TextSub,
TextSize = 11.5,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = LicenseInspectorCard
})

local LicenseDetailLbl = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 25),
Size = UDim2.new(1, -20, 0, 36),
Font = Enum.Font.GothamMedium,
Text = "📦 Gói: Chưa kích hoạt | ⏳ Hạn: -- | 💻 Thiết bị: " .. DEVICE_HWID,
TextColor3 = THEME.TextDim,
TextSize = 11,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = LicenseInspectorCard
})
RegisterTheme(LicenseDetailLbl, "TextColor3", "TextDim")

local function setStatus(text, color)
StatusBoxLbl.Text = tostring(text)
StatusBoxLbl.TextColor3 = color or THEME.TextSub
end

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
tostring(meta.tier_label or "SOVEREIGN"),
tostring(remText or "N/A"),
tostring(meta.bound_hwid or "Tự Do"),
slotPart,
tonumber(meta.executions or 0),
sigPart,
notePart
)
if AppState.minimized and meta.valid then
FloatingOrb.Text = "⚡ BIVA • " .. tostring(remText or "VIP")
else
FloatingOrb.Text = "⚡ BIVA SOVEREIGN"
end
end

-- ==============================================================================
-- 7. XÂY DỰNG TAB 2: CỬA HÀNG PAYOS (MIỄN PHÍ / 8K / 40K / 130K) + CHÚ THÍCH BẢO HÀNH
-- ==============================================================================
local FlashSaleInGameCard = Create("Frame", {
BackgroundColor3 = Color3.fromRGB(48, 22, 16),
Size = UDim2.new(1, 0, 0, 30),
Visible = false,
Parent = TabPages.shop
})
AddCorner(FlashSaleInGameCard, 9)
Create("UIStroke", {
Color = Color3.fromRGB(245, 158, 11),
Thickness = 1.2,
Parent = FlashSaleInGameCard
})

local FlashSaleInGameLbl = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🔥 FLASH SALE TOÀN SERVER ĐANG DIỄN RA!",
TextColor3 = Color3.fromRGB(251, 191, 36),
TextSize = 11.5,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = FlashSaleInGameCard
})

local VoucherBar = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 38),
Parent = TabPages.shop
})
AddCorner(VoucherBar, 10)
AddStroke(VoucherBar, "BorderSubtle", 1, 0.35)
RegisterTheme(VoucherBar, "BackgroundColor3", "BgElevated")

local VoucherInput = Create("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 0, 5),
Size = UDim2.new(1, -134, 0, 28),
Font = Enum.Font.Code,
PlaceholderText = "🏷️ Nhập Mã Giảm Giá (Voucher) nếu có...",
PlaceholderColor3 = THEME.TextDim,
Text = "",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
ClearTextOnFocus = false,
Parent = VoucherBar
})
AddCorner(VoucherInput, 7)
RegisterTheme(VoucherInput, "BackgroundColor3", "BgInput")
RegisterTheme(VoucherInput, "TextColor3", "AccentCyan")

local ApplyVoucherBtn = Create("TextButton", {
BackgroundColor3 = THEME.AccentBlue,
Position = UDim2.new(1, -122, 0, 5),
Size = UDim2.new(0, 116, 0, 28),
Font = Enum.Font.GothamBold,
Text = "🏷️ Áp Mã",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11.5,
AutoButtonColor = false,
Parent = VoucherBar
})
AddCorner(ApplyVoucherBtn, 7)
RegisterTheme(ApplyVoucherBtn, "BackgroundColor3", "AccentBlue")

local ShopGrid = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 162),
Parent = TabPages.shop
})

Create("UIGridLayout", {
CellPadding = UDim2.new(0, 8, 0, 8),
CellSize = UDim2.new(0.32, -2, 0, 77),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = ShopGrid
})

-- KHUNG CHÚ THÍCH NHỎ CAM KẾT BẢO HÀNH & TỰ ĐỘNG DƯỚI BẢNG GIÁ TRONG GAME
local PricingFootnoteCard = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 48),
Parent = TabPages.shop
})
AddCorner(PricingFootnoteCard, 9)
AddStroke(PricingFootnoteCard, "BorderSubtle", 1, 0.45)
RegisterTheme(PricingFootnoteCard, "BackgroundColor3", "BgElevated")

local PricingFootnoteLbl = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 4),
Size = UDim2.new(1, -20, 1, -8),
Font = Enum.Font.GothamMedium,
Text = AppState.pricing_footnote,
TextColor3 = THEME.TextSub,
TextSize = 10,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
TextYAlignment = Enum.TextYAlignment.Center,
Parent = PricingFootnoteCard
})
RegisterTheme(PricingFootnoteLbl, "TextColor3", "TextSub")

local OrderStatusCard = Create("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 80),
Parent = TabPages.shop
})
AddCorner(OrderStatusCard, 10)
AddStroke(OrderStatusCard, "AccentCyan", 1, 0.35)
RegisterTheme(OrderStatusCard, "BackgroundColor3", "BgInput")

local OrderStatusTitle = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 18),
Font = Enum.Font.GothamBold,
Text = "🧾 Trạng thái đơn: Chưa có đơn chờ thanh toán",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = OrderStatusCard
})
RegisterTheme(OrderStatusTitle, "TextColor3", "AccentCyan")

local OrderStatusSub = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 23),
Size = UDim2.new(1, -20, 0, 20),
Font = Enum.Font.GothamMedium,
Text = "Chọn gói (Free Vượt Link / 8K / 40K / 130K) bên trên để nhận hoặc tạo đơn QR gắn sẵn HWID.",
TextColor3 = THEME.TextSub,
TextSize = 10.5,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = OrderStatusCard
})
RegisterTheme(OrderStatusSub, "TextColor3", "TextSub")

local CheckOrderNowBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 10, 0, 47),
Size = UDim2.new(0.48, -12, 0, 26),
Font = Enum.Font.GothamBold,
Text = "🔄 Kiểm Tra Đã Chuyển Khoản",
TextColor3 = THEME.AccentCyan,
TextSize = 11,
AutoButtonColor = false,
Parent = OrderStatusCard
})
AddCorner(CheckOrderNowBtn, 7)
RegisterTheme(CheckOrderNowBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(CheckOrderNowBtn, "TextColor3", "AccentCyan")

local CopyWebShopBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.52, 2, 0, 47),
Size = UDim2.new(0.48, -12, 0, 26),
Font = Enum.Font.GothamBold,
Text = "🌐 Copy Link Web Shop Kèm HWID",
TextColor3 = THEME.TextMain,
TextSize = 11,
AutoButtonColor = false,
Parent = OrderStatusCard
})
AddCorner(CopyWebShopBtn, 7)
RegisterTheme(CopyWebShopBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(CopyWebShopBtn, "TextColor3", "TextMain")

CopyWebShopBtn.MouseButton1Click:Connect(function()
local link = WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID)
safeCopyClipboard(link)
showToast("Đã copy Link Web Shop kèm HWID!", false)
end)

-- BẢNG GIÁ CHUẨN MASTERPIECE: MIỄN PHÍ = VƯỢT LINK | 8K = 1 NGÀY | 40K = 1 TUẦN | 130K = 1 THÁNG
local PackagesMeta = {
{ pkg = "Free", title = "🎁 Miễn Phí (20h)", price = "Vượt Link", basePrice = 0, sub = "Vượt Link • 20 Giờ", isFree = true },
{ pkg = "1 Ngày", title = "⚡ Gói 1 Ngày", price = "8.000đ", basePrice = 8000, sub = "24 Giờ • Duyệt QR 3s", isFree = false },
{ pkg = "1 Tuần", title = "🔥 Gói 1 Tuần", price = "40.000đ", basePrice = 40000, sub = "7 Ngày • Tiết kiệm 29%", isFree = false },
{ pkg = "1 Tháng", title = "💎 Gói 1 Tháng", price = "130.000đ", basePrice = 130000, sub = "30 Ngày • Tiết kiệm 46%", isFree = false },
{ pkg = "1 Năm VIP", title = "👑 Gói 1 Năm VIP", price = "200.000đ", basePrice = 200000, sub = "365 Ngày • Siêu Rẻ", isFree = false },
{ pkg = "Vĩnh Viễn", title = "♾️ Gói Vĩnh Viễn", price = "250.000đ", basePrice = 250000, sub = "Trọn Đời • Lifetime", isFree = false }
}

local PackagePriceLabels = {}

local function updateShopPricesUI()
local fsPct = (AppState.flash_sale and AppState.flash_sale.active) and (tonumber(AppState.flash_sale.discount_percent) or 0) or 0
local effDiscount = math.max(tonumber(AppState.voucher_discount) or 0, fsPct)
for _, item in ipairs(PackagePriceLabels) do
if item.basePrice > 0 then
local dynamicBase = tonumber(AppState.package_prices[item.pkg]) or item.basePrice
local finalP = dynamicBase
if effDiscount > 0 then
finalP = math.max(2000, math.floor(dynamicBase * (100 - effDiscount) / 100))
end
item.label.Text = formatCurrencyVND(finalP)
end
end
end

-- ==============================================================================
-- 8. XÂY DỰNG TAB 3: KHO KEY, GÁN HWID & ĐỔI THIẾT BỊ (RESET HWID)
-- ==============================================================================
local VaultHeaderRow = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 28),
Parent = TabPages.vault
})

Create("TextLabel", {
BackgroundTransparency = 1,
Size = UDim2.new(0.65, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🛡️ KHO KEY ĐỒNG BỘ TRÊN MÁY CỦA BẠN:",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = VaultHeaderRow
})

local RefreshVaultBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.68, 0, 0, 0),
Size = UDim2.new(0.32, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🔄 Làm Mới Kho Key",
TextColor3 = THEME.AccentCyan,
TextSize = 11,
AutoButtonColor = false,
Parent = VaultHeaderRow
})
AddCorner(RefreshVaultBtn, 7)
AddStroke(RefreshVaultBtn, "AccentCyan", 1, 0.4)
RegisterTheme(RefreshVaultBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(RefreshVaultBtn, "TextColor3", "AccentCyan")

local QuickBindRow = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 38),
Parent = TabPages.vault
})
AddCorner(QuickBindRow, 9)
AddStroke(QuickBindRow, "BorderSubtle", 1, 0.35)
RegisterTheme(QuickBindRow, "BackgroundColor3", "BgElevated")

local QuickBindInput = Create("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 0, 5),
Size = UDim2.new(1, -142, 0, 28),
Font = Enum.Font.Code,
PlaceholderText = "Nhập Key Tự Do / Clan để gán vào HWID máy này...",
PlaceholderColor3 = THEME.TextDim,
Text = "",
TextColor3 = THEME.TextMain,
TextSize = 11.5,
ClearTextOnFocus = false,
Parent = QuickBindRow
})
AddCorner(QuickBindInput, 7)
RegisterTheme(QuickBindInput, "BackgroundColor3", "BgInput")
RegisterTheme(QuickBindInput, "TextColor3", "TextMain")

local QuickBindBtn = Create("TextButton", {
BackgroundColor3 = THEME.AccentBlue,
Position = UDim2.new(1, -130, 0, 5),
Size = UDim2.new(0, 124, 0, 28),
Font = Enum.Font.GothamBold,
Text = "🔗 Gán HWID Này",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11,
AutoButtonColor = false,
Parent = QuickBindRow
})
AddCorner(QuickBindBtn, 7)
RegisterTheme(QuickBindBtn, "BackgroundColor3", "AccentBlue")

local VaultListContainer = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 200),
AutomaticSize = Enum.AutomaticSize.Y,
Parent = TabPages.vault
})

Create("UIListLayout", {
Padding = UDim.new(0, 6),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = VaultListContainer
})

-- HỘP THOẠI XÁC NHẬN ĐỔI MÁY (RESET HWID MODAL TRONG GAME)
local ConfirmResetModal = Create("Frame", {
BackgroundColor3 = Color3.fromRGB(4, 8, 18),
BackgroundTransparency = 0.2,
Size = UDim2.new(1, 0, 1, 0),
Visible = false,
ZIndex = 80,
Parent = MainWindow
})

local ConfirmDialog = Create("Frame", {
BackgroundColor3 = THEME.BgSurface,
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 0),
Size = UDim2.new(0, 350, 0, 165),
ZIndex = 81,
Parent = ConfirmResetModal
})
AddCorner(ConfirmDialog, 14)
AddStroke(ConfirmDialog, "AccentCyan", 1.5, 0.15)
RegisterTheme(ConfirmDialog, "BackgroundColor3", "BgSurface")

local ConfirmTitle = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 14, 0, 12),
Size = UDim2.new(1, -28, 0, 22),
Font = Enum.Font.GothamBold,
Text = "🔓 Xác Nhận Đổi Máy (Reset HWID)",
TextColor3 = THEME.AccentCyan,
TextSize = 13.5,
ZIndex = 82,
Parent = ConfirmDialog
})
RegisterTheme(ConfirmTitle, "TextColor3", "AccentCyan")

local ConfirmDesc = Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 14, 0, 38),
Size = UDim2.new(1, -28, 0, 66),
Font = Enum.Font.GothamMedium,
Text = "Bạn muốn gỡ khóa HWID cho Key này?",
TextColor3 = THEME.TextSub,
TextSize = 11.5,
TextWrapped = true,
ZIndex = 82,
Parent = ConfirmDialog
})
RegisterTheme(ConfirmDesc, "TextColor3", "TextSub")

local ConfirmNoBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 14, 1, -44),
Size = UDim2.new(0.46, 0, 0, 32),
Font = Enum.Font.GothamBold,
Text = "Huỷ",
TextColor3 = THEME.TextSub,
TextSize = 12,
AutoButtonColor = false,
ZIndex = 82,
Parent = ConfirmDialog
})
AddCorner(ConfirmNoBtn, 8)
RegisterTheme(ConfirmNoBtn, "BackgroundColor3", "BgElevated")

local ConfirmYesBtn = Create("TextButton", {
BackgroundColor3 = THEME.AccentBlue,
Position = UDim2.new(0.54, -14, 1, -44),
Size = UDim2.new(0.46, 0, 0, 32),
Font = Enum.Font.GothamBold,
Text = "✓ Gỡ Khóa Ngay",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 12,
AutoButtonColor = false,
ZIndex = 82,
Parent = ConfirmDialog
})
AddCorner(ConfirmYesBtn, 8)
RegisterTheme(ConfirmYesBtn, "BackgroundColor3", "AccentBlue")

local pendingResetKeyCode = ""
ConfirmNoBtn.MouseButton1Click:Connect(function()
ConfirmResetModal.Visible = false
end)

-- ==============================================================================
-- 9. XÂY DỰNG TAB 4: LỊCH SỬ ĐƠN HÀNG & GỬI PHIẾU HỖ TRỢ TỚI ADMIN
-- ==============================================================================
local SupportTicketCard = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 74),
Parent = TabPages.orders
})
AddCorner(SupportTicketCard, 10)
AddStroke(SupportTicketCard, "BorderSubtle", 1, 0.35)
RegisterTheme(SupportTicketCard, "BackgroundColor3", "BgElevated")

Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 15),
Font = Enum.Font.GothamBold,
Text = "🎫 GỬI PHIẾU HỖ TRỢ / XIN MỞ KHÓA ĐỔI MÁY TỚI ADMIN:",
TextColor3 = THEME.AccentCyan,
TextSize = 10.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = SupportTicketCard
})

local TicketMsgBox = Create("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 8, 0, 24),
Size = UDim2.new(1, -138, 0, 40),
Font = Enum.Font.GothamMedium,
PlaceholderText = "Nhập nội dung cần Admin hỗ trợ (VD: Nhờ Admin Reset HWID giúp mình)...",
PlaceholderColor3 = THEME.TextDim,
Text = "",
TextColor3 = THEME.TextMain,
TextSize = 11.5,
ClearTextOnFocus = false,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = SupportTicketCard
})
AddCorner(TicketMsgBox, 8)
RegisterTheme(TicketMsgBox, "BackgroundColor3", "BgInput")
RegisterTheme(TicketMsgBox, "TextColor3", "TextMain")

local SendTicketBtn = Create("TextButton", {
BackgroundColor3 = THEME.AccentBlue,
Position = UDim2.new(1, -124, 0, 24),
Size = UDim2.new(0, 116, 0, 40),
Font = Enum.Font.GothamBold,
Text = "📨 Gửi Admin",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11.5,
AutoButtonColor = false,
Parent = SupportTicketCard
})
AddCorner(SendTicketBtn, 8)
RegisterTheme(SendTicketBtn, "BackgroundColor3", "AccentBlue")

local OrdersHeaderRow = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 24),
Parent = TabPages.orders
})

Create("TextLabel", {
BackgroundTransparency = 1,
Size = UDim2.new(0.65, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🧾 LỊCH SỬ ĐƠN HÀNG & PHIẾU HỖ TRỢ:",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = OrdersHeaderRow
})

local RefreshOrdersBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.68, 0, 0, 0),
Size = UDim2.new(0.32, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🔄 Đồng Bộ Lịch Sử",
TextColor3 = THEME.AccentCyan,
TextSize = 11,
AutoButtonColor = false,
Parent = OrdersHeaderRow
})
AddCorner(RefreshOrdersBtn, 7)
AddStroke(RefreshOrdersBtn, "AccentCyan", 1, 0.4)
RegisterTheme(RefreshOrdersBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(RefreshOrdersBtn, "TextColor3", "AccentCyan")

local OrdersListContainer = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 200),
AutomaticSize = Enum.AutomaticSize.Y,
Parent = TabPages.orders
})

Create("UIListLayout", {
Padding = UDim.new(0, 6),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = OrdersListContainer
})

-- ==============================================================================
-- 10. XÂY DỰNG TAB 5: TIỆN ÍCH VIP & BỘ CHỌN 5 CHỦ ĐỀ GIAO DIỆN
-- ==============================================================================
local ThemeSelectorCard = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 64),
Parent = TabPages.utils
})
AddCorner(ThemeSelectorCard, 10)
AddStroke(ThemeSelectorCard, "BorderSubtle", 1, 0.35)
RegisterTheme(ThemeSelectorCard, "BackgroundColor3", "BgElevated")

Create("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 14),
Font = Enum.Font.GothamBold,
Text = "🎨 CHỦ ĐỀ GIAO DIỆN (CYBER THEME ENGINE):",
TextColor3 = THEME.TextSub,
TextSize = 10.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = ThemeSelectorCard
})

local ThemeRow = Create("Frame", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 24),
Size = UDim2.new(1, -16, 0, 32),
Parent = ThemeSelectorCard
})

Create("UIGridLayout", {
CellPadding = UDim2.new(0, 6, 0, 6),
CellSize = UDim2.new(0.19, 0, 0, 30),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = ThemeRow
})

local ThemeOrder = { "CyberBlue", "CrimsonNeon", "EmeraldMatrix", "RoyalAmethyst", "SolarGold" }
for idx, tId in ipairs(ThemeOrder) do
local tMeta = THEMES[tId]
local tBtn = Create("TextButton", {
BackgroundColor3 = tMeta.BgSurface,
LayoutOrder = idx,
Font = Enum.Font.GothamBold,
Text = tMeta.Name,
TextColor3 = tMeta.AccentCyan,
TextSize = 10,
AutoButtonColor = false,
Parent = ThemeRow
})
AddCorner(tBtn, 7)
Create("UIStroke", {
Color = tMeta.AccentCyan,
Thickness = 1,
Transparency = 0.3,
Parent = tBtn
})
tBtn.MouseButton1Click:Connect(function()
ApplyThemePalette(tId)
showToast("🎨 Đã chuyển sang chủ đề: " .. tMeta.Name, false)
end)
end

local UtilsGrid = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 185),
Parent = TabPages.utils
})

Create("UIGridLayout", {
CellPadding = UDim2.new(0, 8, 0, 8),
CellSize = UDim2.new(0.49, -2, 0, 44),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = UtilsGrid
})

local function addUtilityButton(title, callback)
local b = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Font = Enum.Font.GothamBold,
Text = title,
TextColor3 = THEME.TextMain,
TextSize = 11.5,
AutoButtonColor = false,
Parent = UtilsGrid
})
AddCorner(b, 9)
AddStroke(b, "BorderSubtle", 1, 0.35)
RegisterTheme(b, "BackgroundColor3", "BgElevated")
RegisterTheme(b, "TextColor3", "TextMain")
b.MouseButton1Click:Connect(function()
callback(b)
end)
return b
end

addUtilityButton("⚡ Tự Đăng Nhập: " .. (AppState.config.auto_login and "BẬT" or "TẮT"), function(btn)
AppState.config.auto_login = not AppState.config.auto_login
saveConfig(AppState.config)
btn.Text = "⚡ Tự Đăng Nhập: " .. (AppState.config.auto_login and "BẬT" or "TẮT")
showToast("Đã " .. (AppState.config.auto_login and "BẬT" or "TẮT") .. " tự động nạp Script!", false)
end)

addUtilityButton("🛡️ Chống Treo (Anti-AFK): " .. (AppState.config.anti_afk and "BẬT" or "TẮT"), function(btn)
AppState.config.anti_afk = not AppState.config.anti_afk
saveConfig(AppState.config)
btn.Text = "🛡️ Chống Treo (Anti-AFK): " .. (AppState.config.anti_afk and "BẬT" or "TẮT")
showToast("Đã " .. (AppState.config.anti_afk and "BẬT" or "TẮT") .. " Anti-AFK!", false)
end)

addUtilityButton("🚀 Tối Ưu FPS Giảm Lag", function()
pcall(function()
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(workspace:GetDescendants()) do
if v:IsA("BasePart") then
v.Material = Enum.Material.SmoothPlastic
v.Reflectance = 0
elseif v:IsA("Decal") or v:IsA("Texture") then
v.Transparency = 0.85
end
end
end)
showToast("🚀 Đã tối ưu hóa FPS siêu mượt!", false)
end)

addUtilityButton("💡 Bật Sáng Bản Đồ (FullBright)", function()
pcall(function()
Lighting.Brightness = 2.5
Lighting.ClockTime = 14
Lighting.FogEnd = 100000
Lighting.GlobalShadows = false
Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
end)
showToast("💡 Đã kích hoạt FullBright!", false)
end)

addUtilityButton("🔄 Vào Lại Server (Rejoin)", function()
showToast("Đang kết nối lại Server hiện tại...", false)
TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

addUtilityButton("🌐 Đổi Server Ít Người (Server Hop)", function()
showToast("Đang tìm Server mới ít người...", false)
task.spawn(function()
local ok, _, body = rawHttpCall(
"https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100",
"GET"
)
if ok then
local decOk, data = pcall(function() return HttpService:JSONDecode(body) end)
if decOk and data and type(data.data) == "table" then
for _, srv in ipairs(data.data) do
if type(srv) == "table" and srv.id ~= game.JobId and tonumber(srv.playing) < tonumber(srv.maxPlayers) then
TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
return
end
end
end
end
TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
end)

addUtilityButton("📋 Copy Script Kèm Sẵn Key", function()
local k = sanitizeKey(AppState.config.saved_key)
if k == "" then
showToast("⚠️ Bạn chưa có Mã Key nào được lưu!", true)
return
end
local autoCode = string.format(
'getgenv().BIVA_AUTO_KEY = "%s"; loadstring(game:HttpGet("https://raw.githubusercontent.com/thaibao-byte/script-Biva/main/biva_storm.lua"))()',
k
)
safeCopyClipboard(autoCode)
showToast("⚡ Đã copy Script kèm sẵn Key " .. k .. "!", false)
end)

addUtilityButton("🌐 Mở Link Web Shop Chính Thức", function()
local link = WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID)
safeCopyClipboard(link)
showToast("Đã copy Link Web Shop: " .. link, false)
end)

-- ==============================================================================
-- 11. XÂY DỰNG TAB 6: NHẬT KÝ ĐỒNG BỘ THỜI GIAN THỰC (LIVE SYNC CONSOLE)
-- ==============================================================================
local ConsoleHeader = Create("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 28),
Parent = TabPages.console
})

Create("TextLabel", {
BackgroundTransparency = 1,
Size = UDim2.new(0.62, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "📡 NHẬT KÝ ĐỒNG BỘ OMNI-SYNC (REAL-TIME):",
TextColor3 = THEME.AccentCyan,
TextSize = 11.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = ConsoleHeader
})

local PingDiagBtn = Create("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.65, 0, 0, 0),
Size = UDim2.new(0.35, 0, 1, 0),
Font = Enum.Font.GothamBold,
Text = "⚡ Chẩn Đoán Kết Nối",
TextColor3 = THEME.AccentCyan,
TextSize = 11,
AutoButtonColor = false,
Parent = ConsoleHeader
})
AddCorner(PingDiagBtn, 7)
AddStroke(PingDiagBtn, "AccentCyan", 1, 0.4)
RegisterTheme(PingDiagBtn, "BackgroundColor3", "BgElevated")
RegisterTheme(PingDiagBtn, "TextColor3", "AccentCyan")

local ConsoleLogsFrame = Create("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 260),
AutomaticSize = Enum.AutomaticSize.Y,
Parent = TabPages.console
})
AddCorner(ConsoleLogsFrame, 10)
AddStroke(ConsoleLogsFrame, "BorderSubtle", 1, 0.35)
RegisterTheme(ConsoleLogsFrame, "BackgroundColor3", "BgInput")

Create("UIListLayout", {
Padding = UDim.new(0, 4),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = ConsoleLogsFrame
})

renderSyncLogsUI = function()
for _, ch in ipairs(ConsoleLogsFrame:GetChildren()) do
if ch:IsA("TextLabel") then
ch:Destroy()
end
end
for idx, item in ipairs(AppState.sync_logs) do
Create("TextLabel", {
BackgroundTransparency = 1,
LayoutOrder = idx,
Size = UDim2.new(1, -16, 0, 20),
Font = Enum.Font.Code,
Text = string.format(" [%s] [%s] %s", item.time, item.tag, item.msg),
TextColor3 = item.err and THEME.StatusErr or THEME.TextSub,
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = ConsoleLogsFrame
})
end
end

PingDiagBtn.MouseButton1Click:Connect(function()
task.spawn(function()
local data, _, lat = apiRequest("/api/health", "GET")
if data and data.success then
local msg = string.format(
"Server OK • Ver %s • Rev #%s • Keys: %s • Online: %s • Ping: %dms",
tostring(data.version or "SOVEREIGN"),
tostring(data.sync_revision or 1),
tostring(data.indexed_keys or 0),
tostring(data.online_players or 0),
lat
)
pushSyncLog("HEALTH", msg, false)
showToast(msg, false)
else
pushSyncLog("HEALTH", "Không thể kết nối tới Server!", true)
showToast("❌ Lỗi kết nối khi kiểm tra Server!", true)
end
end)
end)

-- ==============================================================================
-- 12. LOGIC ĐỒNG BỘ OMNI-SYNC, RADAR HEARTBEAT, KÍCH HOẠT SCRIPT & HỖ TRỢ
-- ==============================================================================
local renderVaultCards
local renderOrdersCards
local verifyAndExecuteScript

local function reportLoaderTelemetry(confirmedKey)
task.spawn(function()
apiRequest("/api/telemetry", "POST", {
key = confirmedKey,
hwid = DEVICE_HWID,
game_id = AppState.config.selected_game or "steal_egg",
executor = EXECUTOR_TITLE,
player_name = tostring(LocalPlayer.Name or "RobloxPlayer"),
place_id = tonumber(game.PlaceId) or 0,
job_id = tostring(game.JobId or "")
})
end)
end

local function executeSelfResetHwid(targetKey)
local cleanK = sanitizeKey(targetKey)
if cleanK == "" then return end
setStatus("⏳ Đang gỡ khóa thiết bị (Reset HWID) cho Key " .. cleanK .. "...", THEME.StatusWarn)
pushSyncLog("RESET_HWID", "Yêu cầu gỡ HWID cho Key " .. cleanK, false)
task.spawn(function()
local data = apiRequest(
"/api/reset_hwid_by_key?key=" .. urlEncode(cleanK),
"POST",
{ key = cleanK }
)
if data and data.success then
local msg = tostring(data.message or "Đã gỡ khóa thiết bị thành công!")
setStatus("🔓 " .. msg, THEME.AccentCyan)
pushSyncLog("RESET_OK", msg, false)
showToast("🔓 " .. msg, false)
task.wait(0.25)
local syncData = apiRequest("/api/omni_sync?hwid=" .. urlEncode(DEVICE_HWID) .. "&key=" .. urlEncode(cleanK) .. "&fresh=1", "GET")
if syncData and syncData.success then
AppState.server_keys = syncData.keys or {}
AppState.server_orders = syncData.orders or {}
AppState.server_tickets = syncData.support_tickets or {}
renderVaultCards()
renderOrdersCards()
end
else
local errMsg = (data and (data.message or data.detail)) or "Không thể gỡ khóa HWID lúc này!"
setStatus("⚠️ " .. tostring(errMsg), THEME.StatusErr)
pushSyncLog("RESET_ERR", tostring(errMsg), true)
showToast("⚠️ " .. tostring(errMsg), true)
end
end)
end

ConfirmYesBtn.MouseButton1Click:Connect(function()
ConfirmResetModal.Visible = false
if pendingResetKeyCode ~= "" then
executeSelfResetHwid(pendingResetKeyCode)
end
end)

renderVaultCards = function()
for _, child in ipairs(VaultListContainer:GetChildren()) do
if child:IsA("Frame") then
child:Destroy()
end
end

local combined = {}
local seen = {}

for _, kItem in ipairs(AppState.server_keys or {}) do
    local code = sanitizeKey(kItem.key or kItem.key_code)
    if code ~= "" and not seen[code] then
        seen[code] = true
        table.insert(combined, kItem)
    end
end

for _, localItem in ipairs(loadLocalVault()) do
    local code = sanitizeKey(localItem.key)
    if code ~= "" and not seen[code] then
        seen[code] = true
        table.insert(combined, {
            key = code,
            package = localItem.package or "Đã lưu trên máy",
            time_left = "Bấm Nạp để kiểm tra",
            hwid = DEVICE_HWID,
            is_expired = false,
            is_banned = false,
            can_self_reset = true
        })
    end
end

if #combined == 0 then
    local emptyBox = Create("Frame", {
        BackgroundColor3 = THEME.BgInput,
        Size = UDim2.new(1, 0, 0, 54),
        Parent = VaultListContainer
    })
    AddCorner(emptyBox, 9)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Chưa tìm thấy Key nào gắn với HWID [" .. DEVICE_HWID .. "]. Hãy tạo/mua Key (8K/40K/130K) hoặc nhập Key Tự Do ở trên!",
        TextColor3 = THEME.TextSub,
        TextSize = 11.5,
        TextWrapped = true,
        Parent = emptyBox
    })
    return
end

for idx, item in ipairs(combined) do
    local kCode = sanitizeKey(item.key or item.key_code)
    local pkg = tostring(item.package or "VIP")
    local tLeft = tostring(item.time_left or "Còn hạn")
    local bound = tostring(item.bound_hwid or item.hwid or "Tự Do")
    local devCnt = tonumber(item.device_count) or (bound ~= "Chưa khóa máy" and bound ~= "Tự Do" and 1 or 0)
    local maxDev = math.max(1, tonumber(item.max_devices) or 1)
    local isBanned = item.is_banned == true
    local isExp = item.is_expired == true

    local row = Create("Frame", {
        BackgroundColor3 = THEME.BgInput,
        LayoutOrder = idx,
        Size = UDim2.new(1, 0, 0, 62),
        Parent = VaultListContainer
    })
    AddCorner(row, 9)
    AddStroke(row, isBanned and "StatusErr" or "BorderSubtle", 1, 0.35)
    RegisterTheme(row, "BackgroundColor3", "BgInput")

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(0.58, 0, 0, 18),
        Font = Enum.Font.Code,
        Text = kCode,
        TextColor3 = THEME.AccentCyan,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 24),
        Size = UDim2.new(0.58, 0, 0, 32),
        Font = Enum.Font.GothamMedium,
        Text = string.format(
            "Gói: %s • %s\nThiết bị: %s (📱 %d/%d máy)",
            pkg,
            isBanned and "🚫 ĐANG KHÓA" or (isExp and "⏰ Hết hạn" or ("⏳ " .. tLeft)),
            bound,
            devCnt,
            maxDev
        ),
        TextColor3 = (isBanned or isExp) and THEME.StatusErr or THEME.TextSub,
        TextSize = 10.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

    local useBtn = Create("TextButton", {
        BackgroundColor3 = THEME.AccentBlue,
        Position = UDim2.new(1, -184, 0.5, -14),
        Size = UDim2.new(0, 56, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = "⚡ Nạp",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        AutoButtonColor = false,
        Parent = row
    })
    AddCorner(useBtn, 7)

    local copyBtn = Create("TextButton", {
        BackgroundColor3 = THEME.BgElevated,
        Position = UDim2.new(1, -122, 0.5, -14),
        Size = UDim2.new(0, 50, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = "📋",
        TextColor3 = THEME.TextMain,
        TextSize = 11.5,
        AutoButtonColor = false,
        Parent = row
    })
    AddCorner(copyBtn, 7)

    local resetBtn = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(58, 38, 12),
        Position = UDim2.new(1, -66, 0.5, -14),
        Size = UDim2.new(0, 58, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = "🔓 Đổi",
        TextColor3 = THEME.StatusWarn,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = row
    })
    AddCorner(resetBtn, 7)

    useBtn.MouseButton1Click:Connect(function()
        AppState.config.saved_key = kCode
        saveConfig(AppState.config)
        KeyBox.Text = AppState.config.hide_key and maskKeyString(kCode) or kCode
        switchTab("auth")
        verifyAndExecuteScript(kCode)
    end)

    copyBtn.MouseButton1Click:Connect(function()
        safeCopyClipboard(kCode)
        showToast("Đã copy Key: " .. kCode, false)
    end)

    resetBtn.MouseButton1Click:Connect(function()
        pendingResetKeyCode = kCode
        ConfirmDesc.Text = "Bạn muốn gỡ khóa thiết bị hiện tại cho Key [" .. kCode .. "] để đăng nhập trên máy mới?"
        ConfirmResetModal.Visible = true
    end)
end


end

renderOrdersCards = function()
for _, child in ipairs(OrdersListContainer:GetChildren()) do
if child:IsA("Frame") then
child:Destroy()
end
end

local orders = AppState.server_orders or {}
local tickets = AppState.server_tickets or {}

if #orders == 0 and #tickets == 0 then
    local emptyBox = Create("Frame", {
        BackgroundColor3 = THEME.BgInput,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = OrdersListContainer
    })
    AddCorner(emptyBox, 9)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Chưa có lịch sử giao dịch hoặc phiếu hỗ trợ nào cho thiết bị này.",
        TextColor3 = THEME.TextSub,
        TextSize = 11.5,
        Parent = emptyBox
    })
    return
end

local layoutIdx = 0

for _, tk in ipairs(tickets) do
    layoutIdx = layoutIdx + 1
    local tid = tostring(tk.ticket_id or "TK")
    local topic = tostring(tk.topic or "Hỗ trợ")
    local msgTxt = tostring(tk.message or "")
    local replyTxt = tostring(tk.admin_reply or "")
    local isResolved = (tostring(tk.status) == "resolved")

    local tkRow = Create("Frame", {
        BackgroundColor3 = THEME.BgInput,
        LayoutOrder = layoutIdx,
        Size = UDim2.new(1, 0, 0, replyTxt ~= "" and 62 or 48),
        Parent = OrdersListContainer
    })
    AddCorner(tkRow, 9)
    AddStroke(tkRow, isResolved and "AccentCyan" or "StatusWarn", 1, 0.35)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = string.format("🎫 Phiếu [%s] • %s (%s)", tid, topic, isResolved and "✓ ĐÃ XỬ LÝ" or "⏳ CHỜ ADMIN"),
        TextColor3 = isResolved and THEME.AccentCyan or THEME.StatusWarn,
        TextSize = 11.5,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tkRow
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 22),
        Size = UDim2.new(1, -20, 0, 34),
        Font = Enum.Font.GothamMedium,
        Text = msgTxt .. (replyTxt ~= "" and ("\n↪ Admin: " .. replyTxt) or ""),
        TextColor3 = THEME.TextSub,
        TextSize = 10.5,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tkRow
    })
end

for _, ord in ipairs(orders) do
    layoutIdx = layoutIdx + 1
    local oid = tostring(ord.order_id or "ORDER")
    local pkg = tostring(ord.package or "VIP")
    local priceNum = tonumber(ord.price) or 0
    local isPaid = tostring(ord.status) == "paid"
    local issuedKey = sanitizeKey(ord.key or ord.key_code)
    local timeStr = tostring(ord.time_str or "")

    local row = Create("Frame", {
        BackgroundColor3 = THEME.BgInput,
        LayoutOrder = layoutIdx,
        Size = UDim2.new(1, 0, 0, 54),
        Parent = OrdersListContainer
    })
    AddCorner(row, 9)
    AddStroke(row, "BorderSubtle", 1, 0.35)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(0.62, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = string.format("🧾 %s • %s (%s)", oid, pkg, formatCurrencyVND(priceNum)),
        TextColor3 = THEME.TextMain,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 26),
        Size = UDim2.new(0.62, 0, 0, 20),
        Font = Enum.Font.Code,
        Text = (issuedKey ~= "" and ("Key: " .. issuedKey) or "Chưa cấp Key") .. " • " .. timeStr,
        TextColor3 = isPaid and THEME.AccentCyan or THEME.StatusWarn,
        TextSize = 10.5,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

    local actBtn = Create("TextButton", {
        BackgroundColor3 = isPaid and THEME.AccentBlue or Color3.fromRGB(58, 38, 12),
        Position = UDim2.new(1, -110, 0.5, -14),
        Size = UDim2.new(0, 100, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = isPaid and "⚡ Nạp Key" or "🔄 Kiểm Tra",
        TextColor3 = isPaid and Color3.fromRGB(255, 255, 255) or THEME.StatusWarn,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = row
    })
    AddCorner(actBtn, 7)

    actBtn.MouseButton1Click:Connect(function()
        if isPaid and issuedKey ~= "" then
            AppState.config.saved_key = issuedKey
            saveConfig(AppState.config)
            KeyBox.Text = AppState.config.hide_key and maskKeyString(issuedKey) or issuedKey
            switchTab("auth")
            verifyAndExecuteScript(issuedKey)
        else
            task.spawn(function()
                local checkRes = apiRequest("/api/check_order?order_id=" .. urlEncode(oid), "GET")
                if checkRes and checkRes.status == "paid" and checkRes.key then
                    local newK = sanitizeKey(checkRes.key)
                    addToLocalVault(newK, pkg)
                    AppState.config.saved_key = newK
                    saveConfig(AppState.config)
                    KeyBox.Text = AppState.config.hide_key and maskKeyString(newK) or newK
                    showToast("🎉 Đơn " .. oid .. " đã thanh toán! Key: " .. newK, false)
                    switchTab("auth")
                    verifyAndExecuteScript(newK)
                else
                    showToast("⏳ Đơn " .. oid .. " vẫn đang chờ chuyển khoản!", false)
                end
            end)
        end
    end)
end


end

-- Hàm Đồng Bộ Tổng Hợp 1-Request (/api/omni_sync)
local function runOmniSync(notifyToast, autoExecuteIfValid)
task.spawn(function()
local savedKey = sanitizeKey(AppState.config.saved_key)
local path = string.format(
"/api/omni_sync?hwid=%s&key=%s&fresh=1",
urlEncode(DEVICE_HWID),
urlEncode(savedKey)
)
local data, _, lat = apiRequest(path, "GET")
if not data or not data.success then
HeaderSub.Text = "🟡 Server đang thức dậy... Hãy thử lại sau vài giây"
pushSyncLog("WARN", "Không thể kết nối /api/omni_sync", true)
if notifyToast then
showToast("⚠️ Máy chủ đang thức dậy, vui lòng thử lại!", true)
end
return
end

    AppState.sync_revision = tonumber(data.sync_revision) or AppState.sync_revision
    AppState.admin_notice = tostring(data.admin_notice or AppState.admin_notice)
    if data.pricing_footnote and tostring(data.pricing_footnote) ~= "" then
        AppState.pricing_footnote = tostring(data.pricing_footnote)
        PricingFootnoteLbl.Text = AppState.pricing_footnote
    end
    AppState.maintenance = data.maintenance == true
    AppState.is_blacklisted = data.is_blacklisted == true
    AppState.blacklist_reason = tostring(data.blacklist_reason or "")
    AppState.server_keys = data.keys or {}
    AppState.server_orders = data.orders or {}
    AppState.server_tickets = data.support_tickets or {}

    if data.flash_sale and type(data.flash_sale) == "table" then
        AppState.flash_sale = data.flash_sale
        if AppState.flash_sale.active then
            FlashSaleInGameCard.Visible = true
            local bonusPart = (tonumber(AppState.flash_sale.bonus_hours) or 0) > 0
                and (" + TẶNG " .. tostring(AppState.flash_sale.bonus_hours) .. "H")
                or ""
            FlashSaleInGameLbl.Text = string.format(
                "🔥 %s%s (Còn %s)",
                tostring(AppState.flash_sale.title or ("FLASH SALE -" .. tostring(AppState.flash_sale.discount_percent) .. "%")),
                bonusPart,
                tostring(AppState.flash_sale.remaining_text or "Đang diễn ra")
            )
        else
            FlashSaleInGameCard.Visible = false
        end
    end

    if data.package_prices and type(data.package_prices) == "table" then
        for k, v in pairs(data.package_prices) do
            local numVal = tonumber(v) or AppState.package_prices[k]
            if LEGACY_PRICE_MIGRATION[k] and numVal == LEGACY_PRICE_MIGRATION[k][1] then
                numVal = LEGACY_PRICE_MIGRATION[k][2]
            end
            AppState.package_prices[k] = numVal
        end
        updateShopPricesUI()
    end

    if data.games and type(data.games) == "table" and #data.games > 0 then
        AppState.games = data.games
        renderGameCatalogCards()
    end

    HeaderSub.Text = string.format(
        "%s %s • REV #%d • Ping: %dms",
        AppState.maintenance and "🟠 BẢO TRÌ" or "🟢 ONLINE",
        EXECUTOR_TITLE,
        AppState.sync_revision,
        lat
    )
    BroadcastText.Text = "📢 Thông báo Server: " .. AppState.admin_notice

    if AppState.is_blacklisted then
        setStatus("🚫 Thiết bị HWID đã bị khóa vĩnh viễn: " .. AppState.blacklist_reason, THEME.StatusErr)
        pushSyncLog("BLACKLIST", "Thiết bị bị từ chối: " .. AppState.blacklist_reason, true)
        return
    end

    renderVaultCards()
    renderOrdersCards()
    pushSyncLog("OMNI_SYNC", string.format("Rev #%d • Keys: %d • Orders: %d (%dms)", AppState.sync_revision, #AppState.server_keys, #AppState.server_orders, lat), false)

    if data.best_key and type(data.best_key) == "table" then
        local bk = data.best_key
        local bestCode = sanitizeKey(bk.key or bk.key_code)
        if bestCode ~= "" then
            addToLocalVault(bestCode, bk.package)
            AppState.config.saved_key = bestCode
            saveConfig(AppState.config)
            KeyBox.Text = AppState.config.hide_key and maskKeyString(bestCode) or bestCode
            AppState.current_key_meta = {
                valid = true,
                package = tostring(bk.package or "VIP"),
                tier_label = tostring(bk.tier_label or "SOVEREIGN VIP"),
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
            if notifyToast then
                showToast("🔑 Đã tìm thấy Key: " .. bestCode, false)
            end
            if autoExecuteIfValid and AppState.config.auto_login and not AppState.maintenance then
                verifyAndExecuteScript(bestCode)
            end
            return
        end
    end

    if notifyToast then
        showToast("⚠️ Chưa tìm thấy Key còn hạn nào gắn với HWID này!", true)
    end
    setStatus("💡 Nhập Mã Key, đổi Giftcode hoặc qua tab Bảng Giá (Free / 8K / 40K / 130K) để kích hoạt!", THEME.TextSub)
end)


end

-- Hàm Xác Thực Key (Auto-Bind HWID) & Nạp Script Game
verifyAndExecuteScript = function(rawKeyInput)
if AppState.is_busy then return end
local cleanKey = sanitizeKey(rawKeyInput)
if cleanKey == "" or string.find(rawKeyInput or "", "•", 1, true) then
cleanKey = sanitizeKey(AppState.config.saved_key)
end
if #cleanKey < 4 then
setStatus("⚠️ Vui lòng nhập Mã Key hợp lệ trước khi bấm Kích Hoạt!", THEME.StatusErr)
showToast("⚠️ Vui lòng nhập Mã Key hợp lệ!", true)
return
end

AppState.is_busy = true
ActivateBtn.Text = "⏳ Đang xác thực & khóa HWID..."
setStatus("⏳ Đang xác thực Key [" .. cleanKey .. "] trên Server Sovereign Core...", THEME.StatusWarn)
pushSyncLog("VERIFY", "Đang kiểm tra Key " .. cleanKey, false)

task.spawn(function()
    local verifyPath = string.format(
        "/api/verify_key?key=%s&hwid=%s&auto_bind=true",
        urlEncode(cleanKey),
        urlEncode(DEVICE_HWID)
    )
    local verifyData = apiRequest(verifyPath, "GET")

    if not verifyData then
        AppState.is_busy = false
        ActivateBtn.Text = "⚡ KÍCH HOẠT & MỞ MENU VIP"
        setStatus("❌ Không thể kết nối Server! Hãy bấm Kích Hoạt lại.", THEME.StatusErr)
        pushSyncLog("VERIFY_ERR", "Mất kết nối tới /api/verify_key", true)
        showToast("❌ Lỗi kết nối Server!", true)
        return
    end

    if not verifyData.valid then
        AppState.is_busy = false
        ActivateBtn.Text = "⚡ KÍCH HOẠT & MỞ MENU VIP"
        local reason = tostring(verifyData.detail or verifyData.message or "Key không hợp lệ hoặc đã hết hạn!")
        setStatus("❌ " .. reason, THEME.StatusErr)
        pushSyncLog("REJECT", reason, true)
        showToast("❌ " .. reason, true)
        if verifyData.hwid_match == false then
            switchTab("vault")
        end
        return
    end

    local confirmedKey = sanitizeKey(verifyData.key_code or cleanKey)
    AppState.config.saved_key = confirmedKey
    saveConfig(AppState.config)
    addToLocalVault(confirmedKey, verifyData.package or "VIP")
    KeyBox.Text = AppState.config.hide_key and maskKeyString(confirmedKey) or confirmedKey

    AppState.current_key_meta = {
        valid = true,
        package = tostring(verifyData.package or "VIP"),
        tier_label = tostring(verifyData.tier_label or "SOVEREIGN VIP"),
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

    local gameId = AppState.config.selected_game or "steal_egg"
    setStatus("🚀 Xác thực thành công! Đang tải Script [" .. gameId .. "]...", THEME.AccentCyan)
    ActivateBtn.Text = "🚀 Đang nạp Script..."

    local scriptPath = string.format(
        "/api/get_script?key=%s&hwid=%s&game_id=%s",
        urlEncode(confirmedKey),
        urlEncode(DEVICE_HWID),
        urlEncode(gameId)
    )
    local luaSource = apiRequest(scriptPath, "GET", nil, true)
    AppState.is_busy = false
    ActivateBtn.Text = "⚡ KÍCH HOẠT & MỞ MENU VIP"

    if type(luaSource) == "string" and #luaSource > 20 then
        local fn, compileErr = loadstring(luaSource)
        if type(fn) == "function" then
            pushSyncLog("EXEC_OK", "Đã nạp Script " .. gameId .. " cho Key " .. confirmedKey, false)
            showToast("🎉 Kích hoạt BIVA STORM SOVEREIGN thành công!", false)
            setStatus("✅ Đã khởi chạy Script [" .. gameId .. "] thành công!", THEME.AccentCyan)
            task.spawn(function()
                local okRun, runErr = pcall(fn)
                if not okRun then
                    warn("[BIVA STORM Runtime Error]:", runErr)
                end
            end)
            task.delay(0.8, function()
                if MainWindow and MainWindow.Parent then
                    MainWindow.Visible = false
                    FloatingOrb.Visible = true
                    AppState.minimized = true
                    refreshLicenseInspectorUI()
                end
            end)
        else
            setStatus("⚠️ Lỗi biên dịch Script: " .. tostring(compileErr), THEME.StatusErr)
            pushSyncLog("COMPILE_ERR", tostring(compileErr), true)
            showToast("⚠️ Lỗi biên dịch Script!", true)
        end
    else
        setStatus("❌ Không tải được mã nguồn Script từ Server!", THEME.StatusErr)
        pushSyncLog("SCRIPT_ERR", "Phản hồi rỗng từ /api/get_script", true)
        showToast("❌ Lỗi tải Script từ Server!", true)
    end
end)


end

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
setStatus("⏳ Đang đổi Mã Giftcode [" .. gCode .. "] trên Server...", THEME.StatusWarn)
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

SendTicketBtn.MouseButton1Click:Connect(function()
if AppState.is_busy then return end
local msgTxt = tostring(TicketMsgBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
if #msgTxt < 4 then
showToast("⚠️ Vui lòng nhập nội dung cần hỗ trợ (tối thiểu 4 ký tự)!", true)
return
end
AppState.is_busy = true
SendTicketBtn.Text = "⏳ Đang gửi..."
task.spawn(function()
local data = apiRequest(
"/api/support_ticket?hwid=" .. urlEncode(DEVICE_HWID) .. "&key=" .. urlEncode(AppState.config.saved_key or "") .. "&message=" .. urlEncode(msgTxt),
"POST",
{
hwid = DEVICE_HWID,
key = AppState.config.saved_key or "",
topic = "Hỗ trợ In-Game / Mở khóa đổi máy",
message = msgTxt
}
)
AppState.is_busy = false
SendTicketBtn.Text = "📨 Gửi Admin"
if data and data.success then
TicketMsgBox.Text = ""
pushSyncLog("TICKET", "Đã gửi phiếu hỗ trợ [" .. tostring(data.ticket_id or "") .. "]", false)
showToast("🎫 " .. tostring(data.message or "Đã gửi phiếu hỗ trợ tới Admin!"), false)
runOmniSync(false, false)
else
local err = (data and (data.message or data.detail)) or "Không thể gửi phiếu hỗ trợ lúc này!"
showToast("⚠️ " .. tostring(err), true)
end
end)
end)

ApplyVoucherBtn.MouseButton1Click:Connect(function()
local vCode = sanitizeKey(VoucherInput.Text)
if vCode == "" then
AppState.active_voucher = ""
AppState.voucher_discount = 0
AppState.voucher_bonus_hours = 0
updateShopPricesUI()
showToast("Đã gỡ mã giảm giá!", false)
return
end
VoucherInput.Text = vCode
task.spawn(function()
local data = apiRequest("/api/check_voucher?code=" .. urlEncode(vCode) .. "&package=" .. urlEncode("1 Tuần"), "GET")
if data and data.success then
AppState.active_voucher = vCode
AppState.voucher_discount = tonumber(data.discount_percent) or 0
AppState.voucher_bonus_hours = tonumber(data.bonus_hours) or 0
updateShopPricesUI()
pushSyncLog("VOUCHER", tostring(data.message), false)
showToast("🏷️ " .. tostring(data.message), false)
else
AppState.active_voucher = ""
AppState.voucher_discount = 0
AppState.voucher_bonus_hours = 0
updateShopPricesUI()
showToast("⚠️ " .. tostring((data and data.message) or "Mã giảm giá không hợp lệ!"), true)
end
end)
end)

QuickBindBtn.MouseButton1Click:Connect(function()
local targetK = sanitizeKey(QuickBindInput.Text)
if #targetK < 4 then
showToast("⚠️ Vui lòng nhập Mã Key cần gán!", true)
return
end
task.spawn(function()
local data = apiRequest(
"/api/verify_key?key=" .. urlEncode(targetK) .. "&hwid=" .. urlEncode(DEVICE_HWID) .. "&auto_bind=true",
"GET"
)
if data and data.success and data.valid then
local resolved = sanitizeKey(data.key_code or targetK)
addToLocalVault(resolved, data.package or "VIP")
AppState.config.saved_key = resolved
saveConfig(AppState.config)
KeyBox.Text = AppState.config.hide_key and maskKeyString(resolved) or resolved
QuickBindInput.Text = ""
showToast("✅ Đã liên kết HWID vào Key " .. resolved .. "!", false)
runOmniSync(false, false)
else
showToast("❌ " .. tostring((data and (data.detail or data.message)) or "Không thể gán Key này!"), true)
end
end)
end)

-- Vòng lặp theo dõi đơn hàng QR PayOS ngay trong Game
local function startInGameOrderWatcher(orderId, pkgName)
AppState.config.pending_order_id = orderId
AppState.config.pending_package = pkgName
saveConfig(AppState.config)

if AppState.watching_order then return end
AppState.watching_order = true

task.spawn(function()
    local attempts = 0
    while AppState.config.pending_order_id ~= "" and attempts < 100 do
        attempts = attempts + 1
        task.wait(3)
        local currOid = AppState.config.pending_order_id
        if currOid == "" then break end
        local checkData = apiRequest("/api/check_order?order_id=" .. urlEncode(currOid), "GET")
        if checkData and checkData.status == "paid" and checkData.key then
            local newKey = sanitizeKey(checkData.key)
            AppState.config.pending_order_id = ""
            AppState.config.saved_key = newKey
            saveConfig(AppState.config)
            addToLocalVault(newKey, pkgName)
            KeyBox.Text = AppState.config.hide_key and maskKeyString(newKey) or newKey
            OrderStatusTitle.Text = "🎉 ĐƠN " .. currOid .. " ĐÃ THANH TOÁN THÀNH CÔNG!"
            OrderStatusSub.Text = "Đã nhận Key: " .. newKey .. " — Đang tự động kích hoạt..."
            pushSyncLog("PAID_AUTO", "Đơn " .. currOid .. " xuất Key: " .. newKey, false)
            showToast("🎉 Thanh toán thành công! Key: " .. newKey, false)
            switchTab("auth")
            verifyAndExecuteScript(newKey)
            break
        end
    end
    AppState.watching_order = false
end)


end

-- Khởi tạo các thẻ gói mua trong Tab 2 (Miễn Phí = Vượt Link | 8K = 1 Ngày | 40K = 1 Tuần | 130K = 1 Tháng)
for idx, pMeta in ipairs(PackagesMeta) do
local card = Create("Frame", {
BackgroundColor3 = THEME.BgElevated,
LayoutOrder = idx,
Parent = ShopGrid
})
AddCorner(card, 10)
AddStroke(card, pMeta.isFree and "AccentCyan" or "BorderSubtle", 1, 0.35)
RegisterTheme(card, "BackgroundColor3", "BgElevated")

Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 4),
    Size = UDim2.new(1, -16, 0, 14),
    Font = Enum.Font.GothamBold,
    Text = pMeta.title,
    TextColor3 = THEME.TextMain,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = card
})

local priceLbl = Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 18),
    Size = UDim2.new(1, -16, 0, 18),
    Font = Enum.Font.GothamBlack,
    Text = pMeta.price,
    TextColor3 = THEME.AccentCyan,
    TextSize = 13.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = card
})
RegisterTheme(priceLbl, "TextColor3", "AccentCyan")
table.insert(PackagePriceLabels, { label = priceLbl, basePrice = pMeta.basePrice, pkg = pMeta.pkg })

Create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 35),
    Size = UDim2.new(1, -16, 0, 13),
    Font = Enum.Font.GothamMedium,
    Text = pMeta.sub,
    TextColor3 = THEME.TextSub,
    TextSize = 9.5,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = card
})

local buyBtn = Create("TextButton", {
    BackgroundColor3 = pMeta.isFree and THEME.BgInput or THEME.AccentBlue,
    Position = UDim2.new(0, 8, 1, -24),
    Size = UDim2.new(1, -16, 0, 20),
    Font = Enum.Font.GothamBold,
    Text = pMeta.isFree and "Vượt Link ➔" or "Mua Ngay ➔",
    TextColor3 = pMeta.isFree and THEME.AccentCyan or Color3.fromRGB(255, 255, 255),
    TextSize = 10.5,
    AutoButtonColor = false,
    Parent = card
})
AddCorner(buyBtn, 6)

buyBtn.MouseButton1Click:Connect(function()
    if pMeta.isFree then
        OrderStatusTitle.Text = "⏳ Đang khởi tạo Link Vượt 20 Giờ cho HWID..."
        task.spawn(function()
            local res = apiRequest(
                "/api/get_free_link?hwid=" .. urlEncode(DEVICE_HWID) .. "&game=rb",
                "POST",
                { hwid = DEVICE_HWID, game = "rb" }
            )
            if res and res.success and res.link then
                safeCopyClipboard(res.link)
                OrderStatusTitle.Text = "✅ Đã Copy Link Vượt Key Free 20 Giờ!"
                OrderStatusSub.Text = "Hãy dán link vừa copy vào trình duyệt (Safari/Chrome) để nhận Key!"
                showToast("📋 Đã copy Link Vượt Key Free vào bộ nhớ tạm!", false)
            else
                if res and res.existing_key then
                    local exK = sanitizeKey(res.existing_key)
                    AppState.config.saved_key = exK
                    saveConfig(AppState.config)
                    KeyBox.Text = AppState.config.hide_key and maskKeyString(exK) or exK
                    showToast("🔑 Đã lấy lại Key Free còn hạn: " .. exK, false)
                    switchTab("auth")
                else
                    local msg = (res and (res.message or res.detail)) or "Hãy mở Web Shop để nhận Key Free hoặc mua gói 1 Ngày (8.000đ)!"
                    OrderStatusTitle.Text = "⚠️ " .. tostring(msg)
                    showToast("⚠️ " .. tostring(msg), true)
                end
            end
        end)
    else
        OrderStatusTitle.Text = "⏳ Đang tạo đơn PayOS gói [" .. pMeta.pkg .. "]..."
        task.spawn(function()
            local path = string.format(
                "/api/create_order?game=rb&package=%s&hwid=%s&voucher=%s",
                urlEncode(pMeta.pkg),
                urlEncode(DEVICE_HWID),
                urlEncode(AppState.active_voucher or "")
            )
            local res = apiRequest(path, "POST", {
                game = "rb",
                package = pMeta.pkg,
                hwid = DEVICE_HWID,
                voucher = AppState.active_voucher or ""
            })
            if res and res.success and res.order_id then
                local payUrl = (res.checkout_url and res.checkout_url ~= "") and res.checkout_url or (WEB_SHOP_URL .. "?order=" .. urlEncode(res.order_id))
                safeCopyClipboard(payUrl)
                OrderStatusTitle.Text = "✅ Mã đơn: " .. tostring(res.order_id) .. " (" .. formatCurrencyVND(res.price or pMeta.basePrice) .. ") — Đã Copy Link!"
                OrderStatusSub.Text = "Dán link vừa copy ra trình duyệt để quét QR. Game sẽ tự kích hoạt sau 3 giây khi chuyển khoản xong!"
                pushSyncLog("ORDER_NEW", "Tạo đơn " .. tostring(res.order_id) .. " (" .. pMeta.pkg .. ")", false)
                showToast("📋 Đã copy cổng thanh toán đơn " .. tostring(res.order_id) .. "!", false)
                startInGameOrderWatcher(res.order_id, pMeta.pkg)
            else
                local err = (res and (res.detail or res.message)) or "Không thể tạo đơn lúc này!"
                OrderStatusTitle.Text = "❌ " .. tostring(err)
                showToast("❌ " .. tostring(err), true)
            end
        end)
    end
end)


end

CheckOrderNowBtn.MouseButton1Click:Connect(function()
local oid = AppState.config.pending_order_id
if not oid or oid == "" then
runOmniSync(true, false)
return
end
task.spawn(function()
local checkData = apiRequest("/api/check_order?order_id=" .. urlEncode(oid), "GET")
if checkData and checkData.status == "paid" and checkData.key then
local newK = sanitizeKey(checkData.key)
AppState.config.pending_order_id = ""
AppState.config.saved_key = newK
saveConfig(AppState.config)
addToLocalVault(newK, AppState.config.pending_package or "VIP")
KeyBox.Text = AppState.config.hide_key and maskKeyString(newK) or newK
showToast("🎉 Đơn " .. oid .. " đã thanh toán! Key: " .. newK, false)
switchTab("auth")
verifyAndExecuteScript(newK)
else
showToast("⏳ Đơn " .. oid .. " vẫn đang chờ chuyển khoản!", false)
end
end)
end)

RefreshVaultBtn.MouseButton1Click:Connect(function()
runOmniSync(true, false)
end)

RefreshOrdersBtn.MouseButton1Click:Connect(function()
runOmniSync(true, false)
end)

QuickSyncBtn.MouseButton1Click:Connect(function()
runOmniSync(true, false)
end)

-- ==============================================================================
-- 13. THU NHỎ / MỞ RỘNG CỬA SỔ, PHÍM TẮT RIGHTSHIFT & BỘ ĐẾM THỜI GIAN THỰC
-- ==============================================================================
local function toggleWindowMinimize()
AppState.minimized = not AppState.minimized
MainWindow.Visible = not AppState.minimized
FloatingOrb.Visible = AppState.minimized
refreshLicenseInspectorUI()
end

MinimizeBtn.MouseButton1Click:Connect(toggleWindowMinimize)
FloatingOrb.MouseButton1Click:Connect(toggleWindowMinimize)

CloseBtn.MouseButton1Click:Connect(function()
ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
toggleWindowMinimize()
end
end)

-- Chống văng game khi treo máy 20 phút (Anti-AFK Guard)
LocalPlayer.Idled:Connect(function()
if AppState.config.anti_afk then
pcall(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
end)

-- Bộ đếm ngược thời gian thực mỗi 1 giây trên License Inspector & Floating Orb
task.spawn(function()
while ScreenGui and ScreenGui.Parent do
task.wait(1)
if AppState.current_key_meta.valid and AppState.current_key_meta.expire_ts > 0 then
refreshLicenseInspectorUI()
end
end
end)

-- Vòng lặp đồng bộ nền tự động nhận lệnh từ Admin & gửi nhịp tim Radar Online mỗi 20 giây
task.spawn(function()
while ScreenGui and ScreenGui.Parent do
task.wait(20)
if not AppState.is_busy then
local path = string.format(
"/api/omni_sync?hwid=%s&key=%s&fresh=0",
urlEncode(DEVICE_HWID),
urlEncode(AppState.config.saved_key or "")
)
local data, _, lat = apiRequest(path, "GET")
if data and data.success then
local newRev = tonumber(data.sync_revision) or 0
HeaderSub.Text = string.format(
"%s %s • REV #%d • Ping: %dms",
data.maintenance and "🟠 BẢO TRÌ" or "🟢 ONLINE",
EXECUTOR_TITLE,
newRev,
lat
)
if data.admin_notice and data.admin_notice ~= AppState.admin_notice then
AppState.admin_notice = tostring(data.admin_notice)
BroadcastText.Text = "📢 Thông báo Server: " .. AppState.admin_notice
showToast("📢 " .. AppState.admin_notice, false)
end
if newRev ~= AppState.sync_revision then
AppState.sync_revision = newRev
AppState.server_keys = data.keys or {}
AppState.server_orders = data.orders or {}
AppState.server_tickets = data.support_tickets or {}
if data.package_prices and type(data.package_prices) == "table" then
for k, v in pairs(data.package_prices) do
local numVal = tonumber(v) or AppState.package_prices[k]
if LEGACY_PRICE_MIGRATION[k] and numVal == LEGACY_PRICE_MIGRATION[k][1] then
numVal = LEGACY_PRICE_MIGRATION[k][2]
end
AppState.package_prices[k] = numVal
end
updateShopPricesUI()
end
renderVaultCards()
renderOrdersCards()
pushSyncLog("AUTO_SYNC", "Phát hiện cập nhật mới từ Server (Rev #" .. tostring(newRev) .. ")", false)
end
end
end
end
end)

-- Khởi động mặc định ở Tab 1 và chạy Omni-Sync ngay lập tức
switchTab("auth")
if AppState.config.pending_order_id and AppState.config.pending_order_id ~= "" then
startInGameOrderWatcher(AppState.config.pending_order_id, AppState.config.pending_package or "VIP")
end
runOmniSync(false, true)
