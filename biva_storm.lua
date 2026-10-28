-- ==============================================================================
-- BIVA STORM | V27.0 HYPERION SUPREME OMNI-SYNC LOADER & COMMAND CENTER
-- Kiến trúc Đồng Bộ Toàn Diện 100% Với Server V27.0:
--   [+] Tab 1: Kích Hoạt Bản Quyền, Chọn Game Động (/api/games) & Đếm Ngược Real-time
--   [+] Tab 2: Cửa Hàng PayOS In-Game + Áp Mã Giảm Giá (/api/check_voucher) & Tự Duyệt 3s
--   [+] Tab 3: Kho Key Đa Thiết Bị (Server + Local Vault), Gán HWID & Đổi Máy (Reset HWID)
--   [+] Tab 4: Lịch Sử Đơn Hàng & Cấp Phép Trực Tuyến (/api/omni_sync)
--   [+] Tab 5: Tiện Ích VIP (FPS Boost, Anti-AFK, Server Hop, FullBright) & 5 Chủ Đề Giao Diện
--   [+] Tab 6: Nhật Ký Đồng Bộ Thời Gian Thực (Live Sync Console) & Chẩn Đoán Kết Nối
-- ==============================================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ==============================================================================
-- 1. CẤU HÌNH HỆ THỐNG, ENDPOINT & DANH MỤC GAME MẶC ĐỊNH V27.0
-- ==============================================================================
local API_ENDPOINTS = {
"https://biva-hub.onrender.com"
}
local activeEndpointIndex = 1
local WEB_SHOP_URL = "https://biva-hub.onrender.com/index.html"
local SAVE_FILE_NAME = "BivaStorm_V27_Hyperion_Config.json"
local VAULT_FILE_NAME = "BivaStorm_V27_KeyVault.json"
local VERSION_TAG = "V27.0 HYPERION"

local DEFAULT_GAME_CATALOG = {
{
id = "steal_egg",
code = "rb",
name = "⚡ Steal Egg / Biva Main Hub",
version = "27.0",
status = "online",
features = { "Auto Steal Egg", "ESP Players/Items", "Instant Teleport", "Anti-AFK" }
},
{
id = "blox_fruits",
code = "rb",
name = "🏴‍☠️ Blox Fruits Hyperion",
version = "27.0",
status = "online",
features = { "Auto Farm Level", "Auto Sea Event", "Fruit Sniper", "Raid Carry" }
},
{
id = "fisch",
code = "rb",
name = "🐟 Fisch Auto Reel Supreme",
version = "27.0",
status = "online",
features = { "Instant Shake/Reel", "Auto Sell Inventory", "Rare Fish Radar", "Zone TP" }
},
{
id = "dead_rails",
code = "rb",
name = "🚂 Dead Rails Outlaw Hub",
version = "27.0",
status = "online",
features = { "Auto Collect Bonds", "Silent Aimbot", "Train Fuel Guard", "Loot ESP" }
},
{
id = "arise_crossover",
code = "rb",
name = "⚔️ Arise Crossover Shadow",
version = "27.0",
status = "online",
features = { "Auto Dungeon Clear", "Auto Arise Boss", "Shadow Macro", "Kill Aura" }
},
{
id = "blue_lock",
code = "rb",
name = "⚽ Blue Lock Rivals Striker",
version = "27.0",
status = "online",
features = { "Auto Goal Curve", "Infinite Stamina", "Ball Magnet", "Hitbox Expander" }
}
}

local PACKAGE_CATALOG = {
{ name = "Free 20h",   title = "🎁 Dùng Thử 20 Giờ",     price = 0,      sub = "Vượt Link LootLabs • 20 Giờ",     isFree = true },
{ name = "1 Ngày",     title = "⚡ Gói 1 Ngày (24h)",    price = 15000,  sub = "15.000đ • Tự động 3 giây",         isFree = false },
{ name = "1 Tuần",     title = "🔥 Gói 1 Tuần (7 Ngày)", price = 55000,  sub = "55.000đ • Tiết kiệm 50.000đ",      isFree = false, isHot = true },
{ name = "1 Tháng",    title = "💎 Gói VIP 1 Tháng",     price = 135000, sub = "135.000đ • Tự Đổi Máy 12h/lần",    isFree = false, isVip = true },
{ name = "1 Năm VIP",  title = "👑 Gói 1 Năm Supreme",   price = 200000, sub = "200.000đ • 365 Ngày Ưu Tiên",      isFree = false, isVip = true },
{ name = "Vĩnh Viễn",  title = "♾️ Gói Vĩnh Viễn",       price = 250000, sub = "250.000đ • Trọn Đời Không Hết Hạn", isFree = false, isVip = true }
}

-- ==============================================================================
-- 2. HÀM CHUẨN HÓA HWID & KEY (KHỚP TUYỆT ĐỐI VỚI SERVER.PY V27.0)
-- ==============================================================================
local function sanitizeHwid(raw)
if not raw then return "" end
local s = tostring(raw):gsub("%s+", "")
s = s:gsub("^[hH][wW][iI][dD][:=%-]*", "")
s = s:gsub("^[dD][eE][vV][iI][cC][eE][:=%-]", "")
s = s:gsub("^[mM][aA][mM][aA][yY][:=%-]", "")
s = s:gsub("[^%w%-_]", ""):upper()
return s:sub(1, 64)
end

local function sanitizeKey(raw)
if not raw then return "" end
local s = tostring(raw):gsub("%s+", "")
s = s:gsub("^[kK][eE][yY][:=%-]*", "")
s = s:gsub("^[mM][aA][kK][eE][yY][:=%-]*", "")
s = s:gsub("^[lL][iI][cC][eE][nN][sS][eE][:=%-]*", "")
s = s:gsub("[^%w%-_]", ""):upper()
return s:sub(1, 64)
end

local function urlEncode(str)
if not str then return "" end
str = tostring(str):gsub("\n", "\r\n")
str = str:gsub("([^%w %-%_%.%~])", function(c)
return string.format("%%%02X", string.byte(c))
end)
return str:gsub(" ", "+")
end

local function formatVnd(amount)
local num = tonumber(amount) or 0
if num <= 0 then return "Miễn Phí" end
local formatted = tostring(math.floor(num))
while true do
local k
formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
if k == 0 then break end
end
return formatted .. "đ"
end

local function formatRemainingSeconds(remSec)
local rem = math.floor(tonumber(remSec) or 0)
if rem <= 0 then return "Đã hết hạn" end
if rem > 3000 * 86400 then return "Vĩnh Viễn" end
local days = math.floor(rem / 86400)
local hours = math.floor((rem % 86400) / 3600)
local mins = math.floor((rem % 3600) / 60)
local secs = rem % 60
if days > 0 then
return string.format("%d ngày %d giờ %d phút", days, hours, mins)
elseif hours > 0 then
return string.format("%d giờ %d phút %02ds", hours, mins, secs)
elseif mins > 0 then
return string.format("%d phút %02d giây", mins, secs)
end
return string.format("%d giây", math.max(1, secs))
end

local function getExecutorName()
local ok, name = pcall(function()
if identifyexecutor then
return identifyexecutor()
elseif getexecutorname then
return getexecutorname()
end
return "Roblox Executor"
end)
if ok and name and tostring(name) ~= "" then
return tostring(name)
end
return "Standard Executor"
end

local function getDeviceHwid()
local rawHwid = ""
local ok, res = pcall(function()
if gethwid then
return gethwid()
elseif get_hwid then
return get_hwid()
elseif getclientid then
return getclientid()
else
return RbxAnalyticsService:GetClientId()
end
end)
if ok and res and tostring(res) ~= "" then
rawHwid = tostring(res)
else
rawHwid = "RBX-" .. tostring(LocalPlayer.UserId)
end
return sanitizeHwid(rawHwid)
end

local DEVICE_HWID = getDeviceHwid()
local EXECUTOR_NAME = getExecutorName()

-- ==============================================================================
-- 3. TRẠNG THÁI ỨNG DỤNG, LƯU TRỮ CỤC BỘ & KHO KEY (LOCAL VAULT)
-- ==============================================================================
local AppState = {
key = "",
game_id = "steal_egg",
auto_login = true,
anti_afk = true,
fps_boost = false,
full_bright = false,
mask_key = false,
theme_name = "Cyber Cyan",
voucher_code = "",
voucher_discount_pct = 0,
voucher_bonus_hours = 0,
active_order_id = nil,
active_order_pkg = nil,
active_order_price = 0,
active_order_expire_clock = 0,
last_pay_url = "",
sync_revision = 1,
last_ping_ms = 0,
is_busy = false,
is_blacklisted = false,
maintenance = false,
admin_notice = "⚡ Hệ thống BIVA STORM V27.0 HYPERION SUPREME đồng bộ tức thì 0ms!",
current_key_meta = {
valid = false,
package = "Chưa kích hoạt",
tier_label = "GUEST",
bound_hwid = "Chưa khóa máy",
expire_ts = 0,
expire_str = "N/A",
time_left = "Chưa có",
executions = 0,
note = "",
can_self_reset = false,
reset_cooldown_left = "Sẵn sàng"
},
server_keys = {},
server_orders = {},
games_catalog = DEFAULT_GAME_CATALOG,
local_vault = {},
sync_logs = {}
}

local UIRefs = {}

local function appendSyncLog(tag, message, level)
local timestamp = os.date("%H:%M:%S")
local prefix = "⚡"
if level == "error" then prefix = "❌"
elseif level == "warn" then prefix = "⚠️"
elseif level == "ok" then prefix = "✅" end

local entry = string.format("[%s] %s [%s] %s", timestamp, prefix, tostring(tag), tostring(message))
table.insert(AppState.sync_logs, 1, entry)
if #AppState.sync_logs > 60 then
    table.remove(AppState.sync_logs)
end
if UIRefs.LogConsoleText then
    UIRefs.LogConsoleText.Text = table.concat(AppState.sync_logs, "\n")
end


end

local function safeSetClipboard(text)
if not text or tostring(text) == "" then return false end
local ok = pcall(function()
if setclipboard then
setclipboard(tostring(text))
elseif toclipboard then
toclipboard(tostring(text))
elseif Clipboard and Clipboard.set then
Clipboard.set(tostring(text))
else
error("Clipboard API unavailable")
end
end)
return ok
end

local function saveKeyToLocalVault(keyCode, pkgName, expireStr)
local cleanK = sanitizeKey(keyCode)
if #cleanK < 4 then return end
local updated = {}
table.insert(updated, {
key = cleanK,
package = tostring(pkgName or "VIP"),
expire_str = tostring(expireStr or "Còn hạn"),
saved_at = os.date("%H:%M %d/%m")
})
for _, item in ipairs(AppState.local_vault) do
if type(item) == "table" and sanitizeKey(item.key) ~= cleanK and #updated < 12 then
table.insert(updated, item)
end
end
AppState.local_vault = updated
pcall(function()
if writefile then
writefile(VAULT_FILE_NAME, HttpService:JSONEncode(AppState.local_vault))
end
end)
end

local function loadLocalConfig()
pcall(function()
if isfile and readfile and isfile(SAVE_FILE_NAME) then
local raw = readfile(SAVE_FILE_NAME)
local decoded = HttpService:JSONDecode(raw)
if type(decoded) == "table" then
if decoded.key then AppState.key = sanitizeKey(decoded.key) end
if decoded.game_id then AppState.game_id = tostring(decoded.game_id) end
if decoded.auto_login ~= nil then AppState.auto_login = (decoded.auto_login == true) end
if decoded.anti_afk ~= nil then AppState.anti_afk = (decoded.anti_afk == true) end
if decoded.theme_name then AppState.theme_name = tostring(decoded.theme_name) end
end
end
end)
pcall(function()
if isfile and readfile and isfile(VAULT_FILE_NAME) then
local rawV = readfile(VAULT_FILE_NAME)
local decodedV = HttpService:JSONDecode(rawV)
if type(decodedV) == "table" then
AppState.local_vault = decodedV
end
end
end)
local envOk, envKey = pcall(function()
local env = (getgenv and getgenv()) or _G
return env and env.BIVA_AUTO_KEY
end)
if envOk and type(envKey) == "string" and #sanitizeKey(envKey) >= 4 then
AppState.key = sanitizeKey(envKey)
saveKeyToLocalVault(AppState.key, "Auto-Script", "Tự động")
end
end

local function saveLocalConfig()
pcall(function()
if writefile then
local payload = HttpService:JSONEncode({
key = sanitizeKey(AppState.key),
hwid = DEVICE_HWID,
game_id = AppState.game_id,
auto_login = AppState.auto_login,
anti_afk = AppState.anti_afk,
theme_name = AppState.theme_name,
updated_at = os.time()
})
writefile(SAVE_FILE_NAME, payload)
end
end)
end

-- ==============================================================================
-- 4. LÕI HTTP CLIENT ĐA EXECUTOR V27.0 (CHỐNG CACHE & ĐO PING THỜI GIAN THỰC)
-- ==============================================================================
local function rawHttpRequest(url, method, bodyTable)
method = method or "GET"
local reqFunc = (syn and syn.request)
or (http and http.request)
or http_request
or (fluxus and fluxus.request)
or request

if reqFunc then
    local headers = {
        ["Accept"] = "application/json, text/plain, */*",
        ["Cache-Control"] = "no-cache, no-store, max-age=0",
        ["Pragma"] = "no-cache"
    }
    local bodyStr = nil
    if bodyTable then
        headers["Content-Type"] = "application/json"
        bodyStr = HttpService:JSONEncode(bodyTable)
    end
    local ok, response = pcall(function()
        return reqFunc({
            Url = url,
            Method = method,
            Headers = headers,
            Body = bodyStr
        })
    end)
    if ok and response and response.Body then
        return true, tonumber(response.StatusCode) or 200, tostring(response.Body)
    end
end

if method == "GET" then
    local okGet, resGet = pcall(function()
        return game:HttpGet(url)
    end)
    if okGet and resGet then
        return true, 200, tostring(resGet)
    end
end
return false, 0, ""


end

local function apiRequest(path, method, bodyTable, retries)
retries = retries or 2
local sep = path:find("?", 1, true) and "&" or "?"
local cacheBuster = sep .. "_t=" .. tostring(math.floor(os.clock() * 1000)) .. tostring(math.random(100, 999))

for attempt = 1, retries do
    for i = 1, #API_ENDPOINTS do
        local idx = ((activeEndpointIndex + i - 2) % #API_ENDPOINTS) + 1
        local fullUrl = API_ENDPOINTS[idx] .. path .. cacheBuster
        local t0 = os.clock()
        local ok, status, rawBody = rawHttpRequest(fullUrl, method, bodyTable)
        local elapsedMs = math.max(6, math.floor((os.clock() - t0) * 1000))
        if ok and status > 0 and status < 500 and rawBody ~= "" then
            activeEndpointIndex = idx
            AppState.last_ping_ms = elapsedMs
            local jsonOk, parsed = pcall(function()
                return HttpService:JSONDecode(rawBody)
            end)
            return true, status, (jsonOk and parsed or nil), rawBody
        end
    end
    if attempt < retries then
        task.wait(0.45)
    end
end
return false, 0, nil, ""


end

-- ==============================================================================
-- 5. HỆ THỐNG CHỦ ĐỀ GIAO DIỆN (5 CYBER THEMES) & KHỞI TẠO SCREEN GUI
-- ==============================================================================
local THEME_PRESETS = {
["Cyber Cyan"] = {
Accent = Color3.fromRGB(0, 229, 255),
Primary = Color3.fromRGB(37, 99, 235),
Secondary = Color3.fromRGB(79, 70, 229),
Border = Color3.fromRGB(30, 64, 175)
},
["Hyperion Purple"] = {
Accent = Color3.fromRGB(192, 132, 252),
Primary = Color3.fromRGB(126, 34, 206),
Secondary = Color3.fromRGB(79, 70, 229),
Border = Color3.fromRGB(107, 33, 168)
},
["Emerald Matrix"] = {
Accent = Color3.fromRGB(52, 211, 153),
Primary = Color3.fromRGB(5, 150, 105),
Secondary = Color3.fromRGB(16, 185, 129),
Border = Color3.fromRGB(6, 95, 70)
},
["Crimson Apex"] = {
Accent = Color3.fromRGB(251, 113, 133),
Primary = Color3.fromRGB(225, 29, 72),
Secondary = Color3.fromRGB(159, 18, 57),
Border = Color3.fromRGB(136, 19, 55)
},
["Gold Sovereign"] = {
Accent = Color3.fromRGB(251, 191, 36),
Primary = Color3.fromRGB(217, 119, 6),
Secondary = Color3.fromRGB(180, 83, 9),
Border = Color3.fromRGB(146, 64, 14)
}
}

local THEME = {
BgBase       = Color3.fromRGB(6, 10, 22),
BgSurface    = Color3.fromRGB(11, 18, 36),
BgElevated   = Color3.fromRGB(17, 29, 56),
BgInput      = Color3.fromRGB(4, 8, 18),
AccentCyan   = Color3.fromRGB(0, 229, 255),
AccentBlue   = Color3.fromRGB(37, 99, 235),
AccentIndigo = Color3.fromRGB(79, 70, 229),
TextMain     = Color3.fromRGB(248, 250, 252),
TextSub      = Color3.fromRGB(148, 163, 184),
TextDim      = Color3.fromRGB(100, 116, 139),
StatusOk     = Color3.fromRGB(56, 189, 248),
StatusWarn   = Color3.fromRGB(245, 158, 11),
StatusErr    = Color3.fromRGB(244, 63, 94),
BorderSubtle = Color3.fromRGB(30, 58, 138)
}

local ThemeAccentObjects = {}
local ThemePrimaryObjects = {}
local ThemeStrokeObjects = {}

local function applyThemePreset(presetName)
local p = THEME_PRESETS[presetName] or THEME_PRESETS["Cyber Cyan"]
AppState.theme_name = presetName
THEME.AccentCyan = p.Accent
THEME.AccentBlue = p.Primary
THEME.AccentIndigo = p.Secondary
THEME.BorderSubtle = p.Border

for _, obj in ipairs(ThemeAccentObjects) do
    if obj and obj.Parent then
        pcall(function() obj.TextColor3 = THEME.AccentCyan end)
    end
end
for _, obj in ipairs(ThemePrimaryObjects) do
    if obj and obj.Parent then
        pcall(function() obj.BackgroundColor3 = THEME.AccentBlue end)
    end
end
for _, st in ipairs(ThemeStrokeObjects) do
    if st and st.Parent then
        pcall(function() st.Color = THEME.AccentCyan end)
    end
end
saveLocalConfig()


end

local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
for _, oldName in ipairs({ "BivaStormV26Loader", "BivaStormV26Supreme", "BivaStormV27Hyperion" }) do
local old = guiParent:FindFirstChild(oldName)
if old then old:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BivaStormV27Hyperion"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

-- ==============================================================================
-- 6. TOAST NOTIFICATION & INTERACTIVE CONFIRMATION MODAL
-- ==============================================================================
local ToastHolder = Instance.new("Frame")
ToastHolder.Name = "ToastHolder"
ToastHolder.Size = UDim2.new(0, 320, 1, -30)
ToastHolder.Position = UDim2.new(1, -334, 0, 15)
ToastHolder.BackgroundTransparency = 1
ToastHolder.ZIndex = 50
ToastHolder.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ToastLayout.Padding = UDim.new(0, 8)
ToastLayout.Parent = ToastHolder

local function showToast(msg, statusType)
local borderColor = THEME.AccentCyan
local icon = "⚡"
if statusType == "error" then
borderColor = THEME.StatusErr
icon = "❌"
elseif statusType == "warn" then
borderColor = THEME.StatusWarn
icon = "⚠️"
elseif statusType == "success" then
borderColor = THEME.AccentCyan
icon = "✅"
end

local card = Instance.new("Frame")
card.Size = UDim2.new(1, 0, 0, 46)
card.BackgroundColor3 = THEME.BgSurface
card.BackgroundTransparency = 0.06
card.BorderSizePixel = 0
card.ZIndex = 51
card.Parent = ToastHolder

Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", card)
st.Color = borderColor
st.Thickness = 1.5

local lbl = Instance.new("TextLabel", card)
lbl.Size = UDim2.new(1, -20, 1, -8)
lbl.Position = UDim2.new(0, 10, 0, 4)
lbl.BackgroundTransparency = 1
lbl.Font = Enum.Font.GothamBold
lbl.Text = icon .. " " .. tostring(msg)
lbl.TextColor3 = THEME.TextMain
lbl.TextSize = 11.5
lbl.TextWrapped = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.ZIndex = 52

card.Position = UDim2.new(1, 40, 0, 0)
TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Position = UDim2.new(0, 0, 0, 0)
}):Play()

task.delay(3.4, function()
    if card and card.Parent then
        local tw = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        tw:Play()
        task.wait(0.22)
        if card and card.Parent then card:Destroy() end
    end
end)


end

-- NÚT NỔI THU NHỎ (FLOATING PILL)
local FloatingPill = Instance.new("TextButton")
FloatingPill.Name = "FloatingPill"
FloatingPill.Size = UDim2.new(0, 152, 0, 38)
FloatingPill.Position = UDim2.new(0, 18, 0.5, -19)
FloatingPill.BackgroundColor3 = THEME.BgSurface
FloatingPill.Font = Enum.Font.GothamBold
FloatingPill.Text = "⚡ BIVA V27.0"
FloatingPill.TextColor3 = THEME.AccentCyan
FloatingPill.TextSize = 12
FloatingPill.Visible = false
FloatingPill.Active = true
FloatingPill.Draggable = true
FloatingPill.ZIndex = 40
FloatingPill.Parent = ScreenGui
Instance.new("UICorner", FloatingPill).CornerRadius = UDim.new(0, 19)
local pillStroke = Instance.new("UIStroke", FloatingPill)
pillStroke.Color = THEME.AccentCyan
pillStroke.Thickness = 1.6
table.insert(ThemeAccentObjects, FloatingPill)
table.insert(ThemeStrokeObjects, pillStroke)

-- ==============================================================================
-- 7. KHUNG CHÍNH (MAIN COMMAND CENTER WINDOW - 650x440)
-- ==============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 650, 0, 440)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -220)
MainFrame.BackgroundColor3 = THEME.BgBase
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = THEME.AccentCyan
MainStroke.Thickness = 1.6
MainStroke.Transparency = 0.2
table.insert(ThemeStrokeObjects, MainStroke)

-- MODAL XÁC NHẬN TRONG GAME (CHỐNG BẤM NHẦM KHI RESET HWID / XOÁ VAULT)
local ModalOverlay = Instance.new("Frame", MainFrame)
ModalOverlay.Name = "ModalOverlay"
ModalOverlay.Size = UDim2.new(1, 0, 1, 0)
ModalOverlay.BackgroundColor3 = Color3.fromRGB(2, 6, 16)
ModalOverlay.BackgroundTransparency = 0.25
ModalOverlay.Visible = false
ModalOverlay.ZIndex = 30
Instance.new("UICorner", ModalOverlay).CornerRadius = UDim.new(0, 16)

local ModalBox = Instance.new("Frame", ModalOverlay)
ModalBox.Size = UDim2.new(0, 360, 0, 175)
ModalBox.Position = UDim2.new(0.5, -180, 0.5, -88)
ModalBox.BackgroundColor3 = THEME.BgSurface
ModalBox.BorderSizePixel = 0
ModalBox.ZIndex = 31
Instance.new("UICorner", ModalBox).CornerRadius = UDim.new(0, 14)
local modalStroke = Instance.new("UIStroke", ModalBox)
modalStroke.Color = THEME.AccentCyan
modalStroke.Thickness = 1.5
table.insert(ThemeStrokeObjects, modalStroke)

local ModalTitle = Instance.new("TextLabel", ModalBox)
ModalTitle.Size = UDim2.new(1, -24, 0, 26)
ModalTitle.Position = UDim2.new(0, 12, 0, 12)
ModalTitle.BackgroundTransparency = 1
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.Text = "🔓 Xác Nhận Thao Tác"
ModalTitle.TextColor3 = THEME.AccentCyan
ModalTitle.TextSize = 14
ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
ModalTitle.ZIndex = 32
table.insert(ThemeAccentObjects, ModalTitle)

local ModalBody = Instance.new("TextLabel", ModalBox)
ModalBody.Size = UDim2.new(1, -24, 0, 72)
ModalBody.Position = UDim2.new(0, 12, 0, 42)
ModalBody.BackgroundTransparency = 1
ModalBody.Font = Enum.Font.GothamMedium
ModalBody.Text = ""
ModalBody.TextColor3 = THEME.TextMain
ModalBody.TextSize = 12
ModalBody.TextWrapped = true
ModalBody.TextXAlignment = Enum.TextXAlignment.Left
ModalBody.ZIndex = 32

local ModalCancelBtn = Instance.new("TextButton", ModalBox)
ModalCancelBtn.Size = UDim2.new(0.45, 0, 0, 36)
ModalCancelBtn.Position = UDim2.new(0.04, 0, 1, -48)
ModalCancelBtn.BackgroundColor3 = THEME.BgElevated
ModalCancelBtn.Font = Enum.Font.GothamBold
ModalCancelBtn.Text = "Huỷ Bỏ"
ModalCancelBtn.TextColor3 = THEME.TextSub
ModalCancelBtn.TextSize = 12
ModalCancelBtn.ZIndex = 32
Instance.new("UICorner", ModalCancelBtn).CornerRadius = UDim.new(0, 8)

local ModalConfirmBtn = Instance.new("TextButton", ModalBox)
ModalConfirmBtn.Size = UDim2.new(0.45, 0, 0, 36)
ModalConfirmBtn.Position = UDim2.new(0.51, 0, 1, -48)
ModalConfirmBtn.BackgroundColor3 = THEME.AccentBlue
ModalConfirmBtn.Font = Enum.Font.GothamBold
ModalConfirmBtn.Text = "✓ Xác Nhận"
ModalConfirmBtn.TextColor3 = THEME.TextMain
ModalConfirmBtn.TextSize = 12
ModalConfirmBtn.ZIndex = 32
Instance.new("UICorner", ModalConfirmBtn).CornerRadius = UDim.new(0, 8)
table.insert(ThemePrimaryObjects, ModalConfirmBtn)

local pendingModalCallback = nil
ModalCancelBtn.MouseButton1Click:Connect(function()
ModalOverlay.Visible = false
pendingModalCallback = nil
end)
ModalConfirmBtn.MouseButton1Click:Connect(function()
ModalOverlay.Visible = false
if pendingModalCallback then
local cb = pendingModalCallback
pendingModalCallback = nil
cb()
end
end)

local function openConfirmModal(titleText, bodyText, onConfirm)
ModalTitle.Text = tostring(titleText or "Xác Nhận")
ModalBody.Text = tostring(bodyText or "")
pendingModalCallback = onConfirm
ModalOverlay.Visible = true
end

-- HEADER BAR
local HeaderBar = Instance.new("Frame", MainFrame)
HeaderBar.Size = UDim2.new(1, 0, 0, 52)
HeaderBar.BackgroundColor3 = THEME.BgSurface
HeaderBar.BorderSizePixel = 0
Instance.new("UICorner", HeaderBar).CornerRadius = UDim.new(0, 16)

local BrandTitle = Instance.new("TextLabel", HeaderBar)
BrandTitle.Size = UDim2.new(0, 330, 0, 22)
BrandTitle.Position = UDim2.new(0, 16, 0, 7)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Font = Enum.Font.GothamBold
BrandTitle.Text = "⚡ BIVA STORM | " .. VERSION_TAG .. " SUPREME"
BrandTitle.TextColor3 = THEME.AccentCyan
BrandTitle.TextSize = 15
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, BrandTitle)

local BrandSub = Instance.new("TextLabel", HeaderBar)
BrandSub.Size = UDim2.new(0, 390, 0, 16)
BrandSub.Position = UDim2.new(0, 16, 0, 29)
BrandSub.BackgroundTransparency = 1
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.Text = "🟢 Omni-Sync 0ms • HWID: " .. DEVICE_HWID:sub(1, 18) .. " • " .. EXECUTOR_NAME
BrandSub.TextColor3 = THEME.TextSub
BrandSub.TextSize = 11
BrandSub.TextXAlignment = Enum.TextXAlignment.Left

local PingBadge = Instance.new("TextButton", HeaderBar)
PingBadge.Size = UDim2.new(0, 108, 0, 28)
PingBadge.Position = UDim2.new(1, -196, 0, 12)
PingBadge.BackgroundColor3 = THEME.BgInput
PingBadge.Font = Enum.Font.Code
PingBadge.Text = "⚡ --ms | R#1"
PingBadge.TextColor3 = THEME.AccentCyan
PingBadge.TextSize = 11
Instance.new("UICorner", PingBadge).CornerRadius = UDim.new(0, 8)
local pingStroke = Instance.new("UIStroke", PingBadge)
pingStroke.Color = THEME.BorderSubtle
pingStroke.Thickness = 1
table.insert(ThemeAccentObjects, PingBadge)

local MinBtn = Instance.new("TextButton", HeaderBar)
MinBtn.Size = UDim2.new(0, 32, 0, 28)
MinBtn.Position = UDim2.new(1, -80, 0, 12)
MinBtn.BackgroundColor3 = THEME.BgElevated
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = THEME.TextMain
MinBtn.TextSize = 13
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

local CloseBtn = Instance.new("TextButton", HeaderBar)
CloseBtn.Size = UDim2.new(0, 32, 0, 28)
CloseBtn.Position = UDim2.new(1, -42, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(65, 16, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = THEME.StatusErr
CloseBtn.TextSize = 13
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

MinBtn.MouseButton1Click:Connect(function()
MainFrame.Visible = false
FloatingPill.Visible = true
showToast("Đã thu nhỏ Menu! Bấm nút '⚡ BIVA V27.0' hoặc RightShift để mở lại.", "info")
end)

FloatingPill.MouseButton1Click:Connect(function()
FloatingPill.Visible = false
MainFrame.Visible = true
end)

UserInputService.InputBegan:Connect(function(input, gp)
if not gp and input.KeyCode == Enum.KeyCode.RightShift then
local nextState = not MainFrame.Visible
MainFrame.Visible = nextState
FloatingPill.Visible = not nextState
end
end)

CloseBtn.MouseButton1Click:Connect(function()
ScreenGui:Destroy()
end)

-- BANNER THÔNG BÁO TRỰC TIẾP TỪ ADMIN (LIVE BROADCAST BAR)
local BroadcastBar = Instance.new("Frame", MainFrame)
BroadcastBar.Size = UDim2.new(1, -24, 0, 26)
BroadcastBar.Position = UDim2.new(0, 12, 0, 58)
BroadcastBar.BackgroundColor3 = THEME.BgInput
BroadcastBar.BorderSizePixel = 0
Instance.new("UICorner", BroadcastBar).CornerRadius = UDim.new(0, 7)
local bcStroke = Instance.new("UIStroke", BroadcastBar)
bcStroke.Color = THEME.BorderSubtle
bcStroke.Transparency = 0.4

local BroadcastLabel = Instance.new("TextLabel", BroadcastBar)
BroadcastLabel.Size = UDim2.new(1, -16, 1, 0)
BroadcastLabel.Position = UDim2.new(0, 8, 0, 0)
BroadcastLabel.BackgroundTransparency = 1
BroadcastLabel.Font = Enum.Font.GothamMedium
BroadcastLabel.Text = "📡 Đang đồng bộ thông báo thời gian thực từ Server V27.0 HYPERION..."
BroadcastLabel.TextColor3 = THEME.StatusOk
BroadcastLabel.TextSize = 11
BroadcastLabel.TextTruncate = Enum.TextTruncate.AtEnd
BroadcastLabel.TextXAlignment = Enum.TextXAlignment.Left

-- SIDEBAR ĐIỀU HƯỚNG 6 TAB CHUYÊN SÂU
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 154, 1, -102)
Sidebar.Position = UDim2.new(0, 12, 0, 90)
Sidebar.BackgroundColor3 = THEME.BgSurface
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)
local sideStroke = Instance.new("UIStroke", Sidebar)
sideStroke.Color = THEME.BorderSubtle
sideStroke.Transparency = 0.4

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 5)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 8)
SidePad.PaddingLeft = UDim.new(0, 6)
SidePad.PaddingRight = UDim.new(0, 6)

-- KHUNG NỘI DUNG TAB (CONTENT CONTAINER)
local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -184, 1, -102)
ContentArea.Position = UDim2.new(0, 172, 0, 90)
ContentArea.BackgroundColor3 = THEME.BgSurface
ContentArea.BorderSizePixel = 0
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0, 12)
local contentStroke = Instance.new("UIStroke", ContentArea)
contentStroke.Color = THEME.BorderSubtle
contentStroke.Transparency = 0.4

local Tabs = {}
local TabButtons = {}

local function switchTab(tabId)
for id, page in pairs(Tabs) do
page.Visible = (id == tabId)
end
for id, btn in pairs(TabButtons) do
local isAct = (id == tabId)
TweenService:Create(btn, TweenInfo.new(0.18), {
BackgroundColor3 = isAct and THEME.BgElevated or THEME.BgInput,
TextColor3 = isAct and THEME.AccentCyan or THEME.TextSub
}):Play()
local st = btn:FindFirstChildOfClass("UIStroke")
if st then
st.Color = isAct and THEME.AccentCyan or THEME.BorderSubtle
st.Transparency = isAct and 0.12 or 0.65
end
end
end

local function createTabPage(tabId, tabTitle, orderIdx)
local btn = Instance.new("TextButton", Sidebar)
btn.LayoutOrder = orderIdx
btn.Size = UDim2.new(1, 0, 0, 36)
btn.BackgroundColor3 = THEME.BgInput
btn.Font = Enum.Font.GothamBold
btn.Text = tabTitle
btn.TextColor3 = THEME.TextSub
btn.TextSize = 11.5
btn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
local pad = Instance.new("UIPadding", btn)
pad.PaddingLeft = UDim.new(0, 10)
local st = Instance.new("UIStroke", btn)
st.Color = THEME.BorderSubtle
st.Transparency = 0.65

local page = Instance.new("ScrollingFrame", ContentArea)
page.Name = "Tab_" .. tabId
page.Size = UDim2.new(1, -16, 1, -16)
page.Position = UDim2.new(0, 8, 0, 8)
page.BackgroundTransparency = 1
page.BorderSizePixel = 0
page.ScrollBarThickness = 3
page.ScrollBarImageColor3 = THEME.AccentCyan
page.CanvasSize = UDim2.new(0, 0, 0, 0)
page.AutomaticCanvasSize = Enum.AutomaticSize.Y
page.Visible = false

btn.MouseButton1Click:Connect(function()
    switchTab(tabId)
end)

Tabs[tabId] = page
TabButtons[tabId] = btn
return page


end

-- Khởi tạo 6 Tab Chuyên Sâu V27.0
local PageActivate = createTabPage("activate", "🔑 Kích Hoạt & Game", 1)
local PageShop     = createTabPage("shop",     "🛒 Mua Key / Voucher", 2)
local PageVault    = createTabPage("vault",    "🛡️ Kho Key & Đổi Máy", 3)
local PageOrders   = createTabPage("orders",   "🧾 Lịch Sử Đơn Hàng", 4)
local PageUtils    = createTabPage("utils",    "⚙️ Tiện Ích & Theme", 5)
local PageConsole  = createTabPage("console",  "📡 Nhật Ký Đồng Bộ", 6)

-- Nút Copy HWID nhanh ở đáy Sidebar
local QuickHwidSideBtn = Instance.new("TextButton", Sidebar)
QuickHwidSideBtn.LayoutOrder = 99
QuickHwidSideBtn.Size = UDim2.new(1, 0, 0, 34)
QuickHwidSideBtn.BackgroundColor3 = Color3.fromRGB(12, 34, 62)
QuickHwidSideBtn.Font = Enum.Font.GothamBold
QuickHwidSideBtn.Text = "📋 Copy Mã HWID"
QuickHwidSideBtn.TextColor3 = THEME.AccentCyan
QuickHwidSideBtn.TextSize = 11.5
Instance.new("UICorner", QuickHwidSideBtn).CornerRadius = UDim.new(0, 8)
local qhStroke = Instance.new("UIStroke", QuickHwidSideBtn)
qhStroke.Color = THEME.AccentCyan
qhStroke.Transparency = 0.4
table.insert(ThemeAccentObjects, QuickHwidSideBtn)
table.insert(ThemeStrokeObjects, qhStroke)

local function makeCyberBtn(parent, text, pos, size, bg, fg, isPrimary)
local b = Instance.new("TextButton", parent)
b.Position = pos
b.Size = size
b.BackgroundColor3 = bg or THEME.AccentBlue
b.Font = Enum.Font.GothamBold
b.Text = text
b.TextColor3 = fg or THEME.TextMain
b.TextSize = 11.5
b.AutoButtonColor = true
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
local st = Instance.new("UIStroke", b)
st.Color = THEME.AccentCyan
st.Transparency = 0.55
if isPrimary then
table.insert(ThemePrimaryObjects, b)
end
return b
end

-- ==============================================================================
-- 8. TAB 1: KÍCH HOẠT BẢN QUYỀN & CHỌN MODULE GAME (PageActivate)
-- ==============================================================================
local Sec1Title = Instance.new("TextLabel", PageActivate)
Sec1Title.Size = UDim2.new(1, -4, 0, 18)
Sec1Title.Position = UDim2.new(0, 2, 0, 0)
Sec1Title.BackgroundTransparency = 1
Sec1Title.Font = Enum.Font.GothamBold
Sec1Title.Text = "🎮 1. CHỌN MODULE GAME ROBLOX (ĐỒNG BỘ TỪ SERVER):"
Sec1Title.TextColor3 = THEME.AccentCyan
Sec1Title.TextSize = 11.5
Sec1Title.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, Sec1Title)

local GameGrid = Instance.new("Frame", PageActivate)
GameGrid.Size = UDim2.new(1, -4, 0, 84)
GameGrid.Position = UDim2.new(0, 2, 0, 20)
GameGrid.BackgroundTransparency = 1

local GameGridLayout = Instance.new("UIGridLayout", GameGrid)
GameGridLayout.CellSize = UDim2.new(0.32, 0, 0, 38)
GameGridLayout.CellPadding = UDim2.new(0.018, 0, 0, 6)

local GameFeatureBanner = Instance.new("TextLabel", PageActivate)
GameFeatureBanner.Size = UDim2.new(1, -4, 0, 18)
GameFeatureBanner.Position = UDim2.new(0, 2, 0, 106)
GameFeatureBanner.BackgroundTransparency = 1
GameFeatureBanner.Font = Enum.Font.Code
GameFeatureBanner.Text = "✨ Tính năng nổi bật: Auto Steal Egg • ESP Players/Items • Instant Teleport • Anti-AFK"
GameFeatureBanner.TextColor3 = THEME.TextSub
GameFeatureBanner.TextSize = 10.5
GameFeatureBanner.TextTruncate = Enum.TextTruncate.AtEnd
GameFeatureBanner.TextXAlignment = Enum.TextXAlignment.Left

local GameButtons = {}

local function renderGameCatalogButtons()
for _, child in ipairs(GameGrid:GetChildren()) do
if child:IsA("TextButton") then child:Destroy() end
end
GameButtons = {}

for _, gInfo in ipairs(AppState.games_catalog) do
    local gBtn = Instance.new("TextButton", GameGrid)
    local isSel = (gInfo.id == AppState.game_id)
    gBtn.BackgroundColor3 = isSel and THEME.BgElevated or THEME.BgInput
    gBtn.Font = Enum.Font.GothamBold
    gBtn.Text = tostring(gInfo.name or gInfo.id)
    gBtn.TextColor3 = isSel and THEME.AccentCyan or THEME.TextSub
    gBtn.TextSize = 10.5
    gBtn.TextTruncate = Enum.TextTruncate.AtEnd
    Instance.new("UICorner", gBtn).CornerRadius = UDim.new(0, 7)
    local st = Instance.new("UIStroke", gBtn)
    st.Color = isSel and THEME.AccentCyan or THEME.BorderSubtle
    st.Transparency = isSel and 0.15 or 0.65

    if isSel and type(gInfo.features) == "table" then
        GameFeatureBanner.Text = "✨ Tính năng [" .. tostring(gInfo.name) .. "]: " .. table.concat(gInfo.features, " • ")
    end

    gBtn.MouseButton1Click:Connect(function()
        AppState.game_id = gInfo.id
        saveLocalConfig()
        renderGameCatalogButtons()
        showToast("Đã chọn module: " .. tostring(gInfo.name), "info")
    end)
    GameButtons[gInfo.id] = gBtn
end


end

local Sec2Title = Instance.new("TextLabel", PageActivate)
Sec2Title.Size = UDim2.new(1, -4, 0, 18)
Sec2Title.Position = UDim2.new(0, 2, 0, 128)
Sec2Title.BackgroundTransparency = 1
Sec2Title.Font = Enum.Font.GothamBold
Sec2Title.Text = "🔑 2. MÃ KEY BẢN QUYỀN (TỰ ĐỘNG KHÓA & NHẬN DIỆN HWID):"
Sec2Title.TextColor3 = THEME.AccentCyan
Sec2Title.TextSize = 11.5
Sec2Title.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, Sec2Title)

local KeyInput = Instance.new("TextBox", PageActivate)
KeyInput.Size = UDim2.new(1, -138, 0, 34)
KeyInput.Position = UDim2.new(0, 2, 0, 148)
KeyInput.BackgroundColor3 = THEME.BgInput
KeyInput.Font = Enum.Font.Code
KeyInput.PlaceholderText = "Nhập/Dán Mã Key (RB-XXXX-XXXX) hoặc bấm Tự Lấy Key..."
KeyInput.PlaceholderColor3 = THEME.TextDim
KeyInput.Text = ""
KeyInput.TextColor3 = THEME.TextMain
KeyInput.TextSize = 12.5
KeyInput.ClearTextOnFocus = false
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 8)
local kStroke = Instance.new("UIStroke", KeyInput)
kStroke.Color = THEME.AccentCyan
kStroke.Transparency = 0.4
table.insert(ThemeStrokeObjects, kStroke)

local MaskKeyBtn  = makeCyberBtn(PageActivate, "👁️", UDim2.new(1, -130, 0, 148), UDim2.new(0, 36, 0, 34), THEME.BgElevated, THEME.TextMain)
local CopyKeyBtn  = makeCyberBtn(PageActivate, "📋", UDim2.new(1, -90, 0, 148),  UDim2.new(0, 36, 0, 34), THEME.BgElevated, THEME.AccentCyan)
local ClearKeyBtn = makeCyberBtn(PageActivate, "🗑️", UDim2.new(1, -50, 0, 148),  UDim2.new(0, 46, 0, 34), THEME.BgElevated, THEME.StatusErr)

local isUpdatingKeyBox = false
local function syncKeyBoxDisplay()
isUpdatingKeyBox = true
if AppState.mask_key and #AppState.key > 4 then
KeyInput.Text = AppState.key:sub(1, 3) .. "-****-" .. AppState.key:sub(-3)
else
KeyInput.Text = AppState.key
end
isUpdatingKeyBox = false
end

KeyInput.Focused:Connect(function()
if AppState.mask_key then
isUpdatingKeyBox = true
KeyInput.Text = AppState.key
isUpdatingKeyBox = false
end
end)

KeyInput.FocusLost:Connect(function()
local cleaned = sanitizeKey(KeyInput.Text)
if not cleaned:find("%*") then
AppState.key = cleaned
saveLocalConfig()
end
syncKeyBoxDisplay()
end)

KeyInput:GetPropertyChangedSignal("Text"):Connect(function()
if isUpdatingKeyBox then return end
if not KeyInput.Text:find("%*") then
local cleaned = sanitizeKey(KeyInput.Text)
if KeyInput.Text ~= cleaned then
isUpdatingKeyBox = true
KeyInput.Text = cleaned
isUpdatingKeyBox = false
end
AppState.key = cleaned
end
end)

MaskKeyBtn.MouseButton1Click:Connect(function()
AppState.mask_key = not AppState.mask_key
MaskKeyBtn.Text = AppState.mask_key and "🙈" or "👁️"
syncKeyBoxDisplay()
end)

CopyKeyBtn.MouseButton1Click:Connect(function()
if #AppState.key < 4 then
showToast("Chưa có Mã Key để copy!", "warn")
return
end
if safeSetClipboard(AppState.key) then
showToast("Đã copy Key: " .. AppState.key, "success")
end
end)

ClearKeyBtn.MouseButton1Click:Connect(function()
AppState.key = ""
syncKeyBoxDisplay()
saveLocalConfig()
showToast("Đã xoá ô nhập Key!", "info")
end)

local ActivateBtn  = makeCyberBtn(PageActivate, "⚡ KÍCH HOẠT & MỞ MENU VIP", UDim2.new(0, 2, 0, 188), UDim2.new(0.52, -4, 0, 36), THEME.AccentBlue, THEME.TextMain, true)
local AutoFetchBtn = makeCyberBtn(PageActivate, "🔍 Tự Lấy Key Theo HWID",    UDim2.new(0.52, 4, 0, 188), UDim2.new(0.48, -6, 0, 36), Color3.fromRGB(14, 116, 144), THEME.TextMain)

-- THẺ CHI TIẾT BẢN QUYỀN & ĐẾM NGƯỢC THỜI GIAN THỰC (LICENSE INSPECTOR CARD)
local LicenseCard = Instance.new("Frame", PageActivate)
LicenseCard.Size = UDim2.new(1, -4, 0, 96)
LicenseCard.Position = UDim2.new(0, 2, 0, 230)
LicenseCard.BackgroundColor3 = THEME.BgInput
LicenseCard.BorderSizePixel = 0
Instance.new("UICorner", LicenseCard).CornerRadius = UDim.new(0, 10)
local lcStroke = Instance.new("UIStroke", LicenseCard)
lcStroke.Color = THEME.BorderSubtle

local LicenseHeaderLbl = Instance.new("TextLabel", LicenseCard)
LicenseHeaderLbl.Size = UDim2.new(1, -16, 0, 20)
LicenseHeaderLbl.Position = UDim2.new(0, 8, 0, 5)
LicenseHeaderLbl.BackgroundTransparency = 1
LicenseHeaderLbl.Font = Enum.Font.GothamBold
LicenseHeaderLbl.Text = "🛡️ TRẠNG THÁI BẢN QUYỀN TRỰC TIẾP: CHƯA KÍCH HOẠT"
LicenseHeaderLbl.TextColor3 = THEME.AccentCyan
LicenseHeaderLbl.TextSize = 11.5
LicenseHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, LicenseHeaderLbl)

local LicenseDetailLbl = Instance.new("TextLabel", LicenseCard)
LicenseDetailLbl.Size = UDim2.new(1, -16, 0, 42)
LicenseDetailLbl.Position = UDim2.new(0, 8, 0, 25)
LicenseDetailLbl.BackgroundTransparency = 1
LicenseDetailLbl.Font = Enum.Font.Code
LicenseDetailLbl.Text = "📦 Gói: Chưa có | ⏳ Hạn: Chưa xác thực\n💻 Thiết bị khóa: " .. DEVICE_HWID .. " | 🚀 Lượt chạy: 0"
LicenseDetailLbl.TextColor3 = THEME.TextSub
LicenseDetailLbl.TextSize = 11
LicenseDetailLbl.TextWrapped = true
LicenseDetailLbl.TextXAlignment = Enum.TextXAlignment.Left

local OpenShopBtn   = makeCyberBtn(LicenseCard, "🌐 Copy Link Web Shop",   UDim2.new(0, 8, 1, -26), UDim2.new(0.48, -8, 0, 22), THEME.BgElevated, THEME.AccentCyan)
local QuickResetBtn = makeCyberBtn(LicenseCard, "🔓 Đổi Máy (Reset HWID)", UDim2.new(0.52, 0, 1, -26), UDim2.new(0.48, -8, 0, 22), THEME.BgElevated, THEME.StatusWarn)

local function setStatus(text, col)
LicenseHeaderLbl.Text = tostring(text)
LicenseHeaderLbl.TextColor3 = col or THEME.AccentCyan
end

local function refreshLicenseInspectorUI()
local meta = AppState.current_key_meta
local remText = meta.time_left
if meta.expire_ts and meta.expire_ts > os.time() then
remText = formatRemainingSeconds(meta.expire_ts - os.time())
end
local notePart = (meta.note and meta.note ~= "") and (" • 📝 " .. meta.note) or ""
LicenseDetailLbl.Text = string.format(
"📦 Gói: %s (%s) | ⏳ Còn: %s\n💻 Khóa HWID: %s | 🚀 Lượt chạy: %d%s",
tostring(meta.package or "VIP"),
tostring(meta.tier_label or "V27.0"),
tostring(remText or "N/A"),
tostring(meta.bound_hwid or "Tự Do"),
tonumber(meta.executions or 0),
notePart
)
end

-- ==============================================================================
-- 9. TAB 2: CỬA HÀNG PAYOS TỰ ĐỘNG + VOUCHER GIẢM GIÁ (PageShop)
-- ==============================================================================
local VoucherBar = Instance.new("Frame", PageShop)
VoucherBar.Size = UDim2.new(1, -4, 0, 38)
VoucherBar.Position = UDim2.new(0, 2, 0, 0)
VoucherBar.BackgroundColor3 = THEME.BgInput
VoucherBar.BorderSizePixel = 0
Instance.new("UICorner", VoucherBar).CornerRadius = UDim.new(0, 9)
Instance.new("UIStroke", VoucherBar).Color = THEME.BorderSubtle

local VoucherInput = Instance.new("TextBox", VoucherBar)
VoucherInput.Size = UDim2.new(0.62, -12, 0, 28)
VoucherInput.Position = UDim2.new(0, 6, 0, 5)
VoucherInput.BackgroundColor3 = THEME.BgSurface
VoucherInput.Font = Enum.Font.Code
VoucherInput.PlaceholderText = "🏷️ Nhập Mã Giảm Giá / Voucher (Nếu có)..."
VoucherInput.PlaceholderColor3 = THEME.TextDim
VoucherInput.Text = ""
VoucherInput.TextColor3 = THEME.AccentCyan
VoucherInput.TextSize = 11.5
VoucherInput.ClearTextOnFocus = false
Instance.new("UICorner", VoucherInput).CornerRadius = UDim.new(0, 6)

local ApplyVoucherBtn = makeCyberBtn(VoucherBar, "🏷️ Áp Mã Giảm Giá", UDim2.new(0.62, 0, 0, 5), UDim2.new(0.38, -6, 0, 28), THEME.AccentBlue, THEME.TextMain, true)

local ShopPkgGrid = Instance.new("Frame", PageShop)
ShopPkgGrid.Size = UDim2.new(1, -4, 0, 146)
ShopPkgGrid.Position = UDim2.new(0, 2, 0, 44)
ShopPkgGrid.BackgroundTransparency = 1

local ShopPkgLayout = Instance.new("UIGridLayout", ShopPkgGrid)
ShopPkgLayout.CellSize = UDim2.new(0.32, 0, 0, 68)
ShopPkgLayout.CellPadding = UDim2.new(0.018, 0, 0, 8)

local OrderStatusCard = Instance.new("Frame", PageShop)
OrderStatusCard.Size = UDim2.new(1, -4, 0, 130)
OrderStatusCard.Position = UDim2.new(0, 2, 0, 196)
OrderStatusCard.BackgroundColor3 = THEME.BgInput
OrderStatusCard.BorderSizePixel = 0
Instance.new("UICorner", OrderStatusCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", OrderStatusCard).Color = THEME.BorderSubtle

local OrderStatusTitle = Instance.new("TextLabel", OrderStatusCard)
OrderStatusTitle.Size = UDim2.new(1, -16, 0, 20)
OrderStatusTitle.Position = UDim2.new(0, 8, 0, 5)
OrderStatusTitle.BackgroundTransparency = 1
OrderStatusTitle.Font = Enum.Font.GothamBold
OrderStatusTitle.Text = "🧾 TRẠNG THÁI ĐƠN HÀNG PAYOS TỰ ĐỘNG (3 GIÂY):"
OrderStatusTitle.TextColor3 = THEME.AccentCyan
OrderStatusTitle.TextSize = 11.5
OrderStatusTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, OrderStatusTitle)

local OrderStatusDetail = Instance.new("TextLabel", OrderStatusCard)
OrderStatusDetail.Size = UDim2.new(1, -16, 0, 58)
OrderStatusDetail.Position = UDim2.new(0, 8, 0, 26)
OrderStatusDetail.BackgroundTransparency = 1
OrderStatusDetail.Font = Enum.Font.GothamMedium
OrderStatusDetail.Text = "Chưa có đơn hàng đang chờ. Chọn 1 gói ở trên để tạo mã QR tự động gắn sẵn HWID [" .. DEVICE_HWID .. "]!"
OrderStatusDetail.TextColor3 = THEME.TextSub
OrderStatusDetail.TextSize = 11
OrderStatusDetail.TextWrapped = true
OrderStatusDetail.TextXAlignment = Enum.TextXAlignment.Left

local CheckOrderNowBtn = makeCyberBtn(OrderStatusCard, "🔄 Kiểm Tra Đã Chuyển Khoản", UDim2.new(0, 8, 1, -38), UDim2.new(0.54, -10, 0, 30), THEME.AccentBlue, THEME.TextMain, true)
local CopyPayLinkBtn   = makeCyberBtn(OrderStatusCard, "📋 Copy Link QR / Checkout", UDim2.new(0.54, 4, 1, -38), UDim2.new(0.46, -12, 0, 30), THEME.BgElevated, THEME.AccentCyan)

-- ==============================================================================
-- 10. TAB 3: KHO KEY ĐA THIẾT BỊ & GÁN / ĐỔI MÁY HWID (PageVault)
-- ==============================================================================
local BindBar = Instance.new("Frame", PageVault)
BindBar.Size = UDim2.new(1, -4, 0, 40)
BindBar.Position = UDim2.new(0, 2, 0, 0)
BindBar.BackgroundColor3 = THEME.BgInput
BindBar.BorderSizePixel = 0
Instance.new("UICorner", BindBar).CornerRadius = UDim.new(0, 9)
Instance.new("UIStroke", BindBar).Color = THEME.BorderSubtle

local BindKeyInput = Instance.new("TextBox", BindBar)
BindKeyInput.Size = UDim2.new(0.60, -10, 0, 28)
BindKeyInput.Position = UDim2.new(0, 6, 0, 6)
BindKeyInput.BackgroundColor3 = THEME.BgSurface
BindKeyInput.Font = Enum.Font.Code
BindKeyInput.PlaceholderText = "🔗 Nhập Key Tự Do để gán cứng vào HWID máy này..."
BindKeyInput.PlaceholderColor3 = THEME.TextDim
BindKeyInput.Text = ""
BindKeyInput.TextColor3 = THEME.TextMain
BindKeyInput.TextSize = 11.5
BindKeyInput.ClearTextOnFocus = false
Instance.new("UICorner", BindKeyInput).CornerRadius = UDim.new(0, 6)

local BindNowBtn = makeCyberBtn(BindBar, "🔗 Gán HWID Máy Này", UDim2.new(0.60, 2, 0, 6), UDim2.new(0.40, -8, 0, 28), THEME.AccentBlue, THEME.TextMain, true)

local VaultHeaderBar = Instance.new("Frame", PageVault)
VaultHeaderBar.Size = UDim2.new(1, -4, 0, 28)
VaultHeaderBar.Position = UDim2.new(0, 2, 0, 46)
VaultHeaderBar.BackgroundTransparency = 1

local VaultHeaderTitle = Instance.new("TextLabel", VaultHeaderBar)
VaultHeaderTitle.Size = UDim2.new(0.65, 0, 1, 0)
VaultHeaderTitle.BackgroundTransparency = 1
VaultHeaderTitle.Font = Enum.Font.GothamBold
VaultHeaderTitle.Text = "🔑 DANH SÁCH KEY CỦA MÁY NÀY (SERVER + LOCAL VAULT):"
VaultHeaderTitle.TextColor3 = THEME.AccentCyan
VaultHeaderTitle.TextSize = 11.5
VaultHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, VaultHeaderTitle)

local RefreshVaultBtn = makeCyberBtn(VaultHeaderBar, "🔄 Đồng Bộ Ngay", UDim2.new(0.66, 0, 0, 0), UDim2.new(0.34, 0, 0, 26), THEME.BgElevated, THEME.AccentCyan)

local VaultCardsContainer = Instance.new("Frame", PageVault)
VaultCardsContainer.Size = UDim2.new(1, -4, 0, 240)
VaultCardsContainer.Position = UDim2.new(0, 2, 0, 78)
VaultCardsContainer.BackgroundTransparency = 1
VaultCardsContainer.AutomaticSize = Enum.AutomaticSize.Y

local VaultListLayout = Instance.new("UIListLayout", VaultCardsContainer)
VaultListLayout.Padding = UDim.new(0, 6)
VaultListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ==============================================================================
-- 11. TAB 4: LỊCH SỬ ĐƠN HÀNG & CẤP PHÉP (PageOrders)
-- ==============================================================================
local OrdersTopBar = Instance.new("Frame", PageOrders)
OrdersTopBar.Size = UDim2.new(1, -4, 0, 30)
OrdersTopBar.Position = UDim2.new(0, 2, 0, 0)
OrdersTopBar.BackgroundTransparency = 1

local OrdersTopTitle = Instance.new("TextLabel", OrdersTopBar)
OrdersTopTitle.Size = UDim2.new(0.68, 0, 1, 0)
OrdersTopTitle.BackgroundTransparency = 1
OrdersTopTitle.Font = Enum.Font.GothamBold
OrdersTopTitle.Text = "🧾 LỊCH SỬ GIAO DỊCH PAYOS & ADMIN CẤP PHÉP:"
OrdersTopTitle.TextColor3 = THEME.AccentCyan
OrdersTopTitle.TextSize = 11.5
OrdersTopTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, OrdersTopTitle)

local RefreshOrdersBtn = makeCyberBtn(OrdersTopBar, "🔄 Làm Mới Lịch Sử", UDim2.new(0.68, 0, 0, 2), UDim2.new(0.32, 0, 0, 26), THEME.BgElevated, THEME.AccentCyan)

local OrdersListContainer = Instance.new("Frame", PageOrders)
OrdersListContainer.Size = UDim2.new(1, -4, 0, 280)
OrdersListContainer.Position = UDim2.new(0, 2, 0, 36)
OrdersListContainer.BackgroundTransparency = 1
OrdersListContainer.AutomaticSize = Enum.AutomaticSize.Y

local OrdersListLayout = Instance.new("UIListLayout", OrdersListContainer)
OrdersListLayout.Padding = UDim.new(0, 6)
OrdersListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ==============================================================================
-- 12. TAB 5: TIỆN ÍCH VIP & ĐỔI CHỦ ĐỀ GIAO DIỆN (PageUtils)
-- ==============================================================================
local UtilSecTitle = Instance.new("TextLabel", PageUtils)
UtilSecTitle.Size = UDim2.new(1, -4, 0, 20)
UtilSecTitle.Position = UDim2.new(0, 2, 0, 0)
UtilSecTitle.BackgroundTransparency = 1
UtilSecTitle.Font = Enum.Font.GothamBold
UtilSecTitle.Text = "⚙️ TIỆN ÍCH HỆ THỐNG ROBLOX & CẤU HÌNH TỰ ĐỘNG:"
UtilSecTitle.TextColor3 = THEME.AccentCyan
UtilSecTitle.TextSize = 11.5
UtilSecTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, UtilSecTitle)

local ToggleAutoLoginBtn = makeCyberBtn(PageUtils, "⚡ Tự Động Kích Hoạt Khi Có Key: BẬT", UDim2.new(0, 2, 0, 24), UDim2.new(0.49, -2, 0, 34), THEME.BgElevated, THEME.AccentCyan)
local ToggleAntiAfkBtn   = makeCyberBtn(PageUtils, "🛡️ Chống Văng Khi Treo Máy (Anti-AFK): BẬT", UDim2.new(0.51, 2, 0, 24), UDim2.new(0.49, -4, 0, 34), THEME.BgElevated, THEME.AccentCyan)
local BoostFpsBtn        = makeCyberBtn(PageUtils, "🚀 Tối Ưu Đồ Họa Giảm Lag (FPS Boost)", UDim2.new(0, 2, 0, 64), UDim2.new(0.49, -2, 0, 34), THEME.BgElevated, THEME.TextMain)
local FullBrightBtn      = makeCyberBtn(PageUtils, "☀️ Làm Sáng Bản Đồ (FullBright): TẮT", UDim2.new(0.51, 2, 0, 64), UDim2.new(0.49, -4, 0, 34), THEME.BgElevated, THEME.TextMain)
local RejoinServerBtn    = makeCyberBtn(PageUtils, "🔄 Vào Lại Server Hiện Tại (Rejoin)", UDim2.new(0, 2, 0, 104), UDim2.new(0.49, -2, 0, 34), THEME.BgElevated, THEME.TextMain)
local ServerHopBtn       = makeCyberBtn(PageUtils, "🌐 Đổi Sang Server Khác (Server Hop)", UDim2.new(0.51, 2, 0, 104), UDim2.new(0.49, -4, 0, 34), THEME.BgElevated, THEME.TextMain)
local CopyAutoScriptBtn  = makeCyberBtn(PageUtils, "📋 Copy Script Kèm Sẵn Key Hiện Tại", UDim2.new(0, 2, 0, 144), UDim2.new(0.49, -2, 0, 34), THEME.BgElevated, THEME.AccentCyan)
local WipeCacheBtn       = makeCyberBtn(PageUtils, "🧹 Xoá File Lưu Cấu Hình & Kho Key", UDim2.new(0.51, 2, 0, 144), UDim2.new(0.49, -4, 0, 34), THEME.BgElevated, THEME.StatusErr)

local ThemeSecTitle = Instance.new("TextLabel", PageUtils)
ThemeSecTitle.Size = UDim2.new(1, -4, 0, 20)
ThemeSecTitle.Position = UDim2.new(0, 2, 0, 188)
ThemeSecTitle.BackgroundTransparency = 1
ThemeSecTitle.Font = Enum.Font.GothamBold
ThemeSecTitle.Text = "🎨 CHỌN CHỦ ĐỀ GIAO DIỆN (5 CYBER THEMES):"
ThemeSecTitle.TextColor3 = THEME.AccentCyan
ThemeSecTitle.TextSize = 11.5
ThemeSecTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, ThemeSecTitle)

local ThemeGrid = Instance.new("Frame", PageUtils)
ThemeGrid.Size = UDim2.new(1, -4, 0, 72)
ThemeGrid.Position = UDim2.new(0, 2, 0, 212)
ThemeGrid.BackgroundTransparency = 1

local ThemeGridLayout = Instance.new("UIGridLayout", ThemeGrid)
ThemeGridLayout.CellSize = UDim2.new(0.32, 0, 0, 32)
ThemeGridLayout.CellPadding = UDim2.new(0.018, 0, 0, 6)

for themeName, preset in pairs(THEME_PRESETS) do
local tBtn = Instance.new("TextButton", ThemeGrid)
tBtn.BackgroundColor3 = THEME.BgInput
tBtn.Font = Enum.Font.GothamBold
tBtn.Text = "🎨 " .. themeName
tBtn.TextColor3 = preset.Accent
tBtn.TextSize = 11
Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 7)
local st = Instance.new("UIStroke", tBtn)
st.Color = preset.Accent
st.Transparency = 0.4
tBtn.MouseButton1Click:Connect(function()
applyThemePreset(themeName)
showToast("Đã chuyển sang giao diện: " .. themeName, "success")
end)
end

-- ==============================================================================
-- 13. TAB 6: NHẬT KÝ ĐỒNG BỘ & CHẨN ĐOÁN KẾT NỐI (PageConsole)
-- ==============================================================================
local ConsoleHeader = Instance.new("Frame", PageConsole)
ConsoleHeader.Size = UDim2.new(1, -4, 0, 30)
ConsoleHeader.Position = UDim2.new(0, 2, 0, 0)
ConsoleHeader.BackgroundTransparency = 1

local ConsoleTitle = Instance.new("TextLabel", ConsoleHeader)
ConsoleTitle.Size = UDim2.new(0.52, 0, 1, 0)
ConsoleTitle.BackgroundTransparency = 1
ConsoleTitle.Font = Enum.Font.GothamBold
ConsoleTitle.Text = "📡 NHẬT KÝ ĐỒNG BỘ OMNI-SYNC (LIVE LOGS):"
ConsoleTitle.TextColor3 = THEME.AccentCyan
ConsoleTitle.TextSize = 11.5
ConsoleTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(ThemeAccentObjects, ConsoleTitle)

local RunDiagBtn  = makeCyberBtn(ConsoleHeader, "🧪 Chẩn Đoán Server", UDim2.new(0.53, 0, 0, 2), UDim2.new(0.27, -4, 0, 26), THEME.AccentBlue, THEME.TextMain, true)
local CopyLogsBtn = makeCyberBtn(ConsoleHeader, "📋 Copy Log",         UDim2.new(0.80, 2, 0, 2), UDim2.new(0.20, -2, 0, 26), THEME.BgElevated, THEME.AccentCyan)

local LogConsoleBox = Instance.new("Frame", PageConsole)
LogConsoleBox.Size = UDim2.new(1, -4, 0, 275)
LogConsoleBox.Position = UDim2.new(0, 2, 0, 36)
LogConsoleBox.BackgroundColor3 = THEME.BgInput
LogConsoleBox.BorderSizePixel = 0
Instance.new("UICorner", LogConsoleBox).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", LogConsoleBox).Color = THEME.BorderSubtle

local LogConsoleText = Instance.new("TextLabel", LogConsoleBox)
LogConsoleText.Size = UDim2.new(1, -16, 1, -14)
LogConsoleText.Position = UDim2.new(0, 8, 0, 7)
LogConsoleText.BackgroundTransparency = 1
LogConsoleText.Font = Enum.Font.Code
LogConsoleText.Text = "[Khởi tạo] Hệ thống BIVA STORM V27.0 HYPERION sẵn sàng..."
LogConsoleText.TextColor3 = THEME.TextSub
LogConsoleText.TextSize = 10.5
LogConsoleText.TextWrapped = true
LogConsoleText.TextXAlignment = Enum.TextXAlignment.Left
LogConsoleText.TextYAlignment = Enum.TextYAlignment.Top
UIRefs.LogConsoleText = LogConsoleText

-- ==============================================================================
-- 14. LOGIC RENDER KHO KEY (TAB 3), ĐƠN HÀNG (TAB 4) & CỬA HÀNG (TAB 2)
-- ==============================================================================
local verifyAndLoadScript
local requestSelfResetHwid
local syncOmniState

local function renderVaultKeysUI()
for _, child in ipairs(VaultCardsContainer:GetChildren()) do
if child:IsA("Frame") then child:Destroy() end
end

local combined = {}
local seenKeys = {}

for _, kItem in ipairs(AppState.server_keys) do
    local code = sanitizeKey(kItem.key or kItem.key_code)
    if code ~= "" and not seenKeys[code] then
        seenKeys[code] = true
        table.insert(combined, {
            key = code,
            package = tostring(kItem.package or "VIP"),
            time_left = tostring(kItem.time_left or "Còn hạn"),
            expire_str = tostring(kItem.expire_str or ""),
            hwid = tostring(kItem.hwid or "Chưa khóa máy"),
            is_bound = (kItem.is_bound == true),
            is_expired = (kItem.is_expired == true),
            is_banned = (kItem.is_banned == true),
            can_self_reset = (kItem.can_self_reset == true),
            reset_cooldown_left = tostring(kItem.reset_cooldown_left or "Sẵn sàng"),
            source = "SERVER"
        })
    end
end

for _, vItem in ipairs(AppState.local_vault) do
    local code = sanitizeKey(vItem.key)
    if code ~= "" and not seenKeys[code] then
        seenKeys[code] = true
        table.insert(combined, {
            key = code,
            package = tostring(vItem.package or "Local Vault"),
            time_left = "Đã lưu trên máy",
            expire_str = tostring(vItem.expire_str or ""),
            hwid = DEVICE_HWID,
            is_bound = true,
            is_expired = false,
            is_banned = false,
            can_self_reset = true,
            reset_cooldown_left = "Sẵn sàng",
            source = "LOCAL"
        })
    end
end

if #combined == 0 then
    local emptyCard = Instance.new("Frame", VaultCardsContainer)
    emptyCard.Size = UDim2.new(1, 0, 0, 56)
    emptyCard.BackgroundColor3 = THEME.BgInput
    Instance.new("UICorner", emptyCard).CornerRadius = UDim.new(0, 9)
    local lbl = Instance.new("TextLabel", emptyCard)
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = "🔑 Chưa tìm thấy Key nào gắn với HWID [" .. DEVICE_HWID .. "].\nHãy qua Tab 2 để mua tự động hoặc dán Key Tự Do vào ô bên trên để gán máy!"
    lbl.TextColor3 = THEME.TextSub
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return
end

for idx, item in ipairs(combined) do
    local card = Instance.new("Frame", VaultCardsContainer)
    card.LayoutOrder = idx
    card.Size = UDim2.new(1, 0, 0, 62)
    card.BackgroundColor3 = THEME.BgInput
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
    local st = Instance.new("UIStroke", card)
    st.Color = item.is_banned and THEME.StatusErr or (item.is_expired and THEME.StatusWarn or THEME.BorderSubtle)

    local codeLbl = Instance.new("TextLabel", card)
    codeLbl.Size = UDim2.new(0.58, -10, 0, 22)
    codeLbl.Position = UDim2.new(0, 8, 0, 5)
    codeLbl.BackgroundTransparency = 1
    codeLbl.Font = Enum.Font.Code
    codeLbl.Text = string.format("🔑 %s [%s]", item.key, item.package)
    codeLbl.TextColor3 = THEME.AccentCyan
    codeLbl.TextSize = 12
    codeLbl.TextXAlignment = Enum.TextXAlignment.Left

    local statusStr = item.is_banned and "🚫 ĐANG KHÓA" or (item.is_expired and "⏰ ĐÃ HẾT HẠN" or ("✅ " .. item.time_left))
    local metaLbl = Instance.new("TextLabel", card)
    metaLbl.Size = UDim2.new(0.58, -10, 0, 30)
    metaLbl.Position = UDim2.new(0, 8, 0, 26)
    metaLbl.BackgroundTransparency = 1
    metaLbl.Font = Enum.Font.GothamMedium
    metaLbl.Text = string.format("%s • Nguồn: %s\nHWID: %s", statusStr, item.source, item.hwid)
    metaLbl.TextColor3 = THEME.TextSub
    metaLbl.TextSize = 10.5
    metaLbl.TextWrapped = true
    metaLbl.TextXAlignment = Enum.TextXAlignment.Left

    local useBtn = makeCyberBtn(card, "⚡ Dùng Key", UDim2.new(0.59, 0, 0, 14), UDim2.new(0.20, -4, 0, 34), THEME.AccentBlue, THEME.TextMain, true)
    useBtn.MouseButton1Click:Connect(function()
        AppState.key = item.key
        syncKeyBoxDisplay()
        saveLocalConfig()
        switchTab("activate")
        verifyAndLoadScript()
    end)

    local rstBtn = makeCyberBtn(card, "🔓 Đổi Máy", UDim2.new(0.80, 0, 0, 14), UDim2.new(0.20, -6, 0, 34), THEME.BgElevated, THEME.StatusWarn)
    rstBtn.MouseButton1Click:Connect(function()
        requestSelfResetHwid(item.key)
    end)
end


end

local function renderOrdersHistoryUI()
for _, child in ipairs(OrdersListContainer:GetChildren()) do
if child:IsA("Frame") then child:Destroy() end
end

if #AppState.server_orders == 0 then
    local emptyCard = Instance.new("Frame", OrdersListContainer)
    emptyCard.Size = UDim2.new(1, 0, 0, 52)
    emptyCard.BackgroundColor3 = THEME.BgInput
    Instance.new("UICorner", emptyCard).CornerRadius = UDim.new(0, 9)
    local lbl = Instance.new("TextLabel", emptyCard)
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = "🧾 Chưa có lịch sử đơn hàng nào cho thiết bị [" .. DEVICE_HWID .. "]."
    lbl.TextColor3 = THEME.TextSub
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return
end

for idx, ord in ipairs(AppState.server_orders) do
    local card = Instance.new("Frame", OrdersListContainer)
    card.LayoutOrder = idx
    card.Size = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3 = THEME.BgInput
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
    local isPaid = (tostring(ord.status):lower() == "paid")
    local st = Instance.new("UIStroke", card)
    st.Color = isPaid and THEME.BorderSubtle or THEME.StatusWarn

    local issuedKey = sanitizeKey(ord.key or ord.key_code or "")
    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size = UDim2.new(0.66, -10, 0, 20)
    titleLbl.Position = UDim2.new(0, 8, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.Code
    titleLbl.Text = string.format(
        "🧾 %s • %s (%s)",
        tostring(ord.order_id or "ORDER"),
        tostring(ord.package or "VIP"),
        formatVnd(ord.price or 0)
    )
    titleLbl.TextColor3 = isPaid and THEME.AccentCyan or THEME.StatusWarn
    titleLbl.TextSize = 11.5
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local subLbl = Instance.new("TextLabel", card)
    subLbl.Size = UDim2.new(0.66, -10, 0, 24)
    subLbl.Position = UDim2.new(0, 8, 0, 26)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.Text = string.format(
        "Trạng thái: %s • Key: %s • %s",
        isPaid and "✅ ĐÃ KÍCH HOẠT" or "⏳ CHỜ THANH TOÁN",
        (issuedKey ~= "" and issuedKey or "Chưa cấp"),
        tostring(ord.time_str or "")
    )
    subLbl.TextColor3 = THEME.TextSub
    subLbl.TextSize = 10.5
    subLbl.TextXAlignment = Enum.TextXAlignment.Left

    if isPaid and issuedKey ~= "" then
        local actBtn = makeCyberBtn(card, "⚡ Nạp Key", UDim2.new(0.68, 0, 0, 12), UDim2.new(0.32, -8, 0, 32), THEME.AccentBlue, THEME.TextMain, true)
        actBtn.MouseButton1Click:Connect(function()
            AppState.key = issuedKey
            syncKeyBoxDisplay()
            saveLocalConfig()
            switchTab("activate")
            verifyAndLoadScript()
        end)
    else
        local chkBtn = makeCyberBtn(card, "🔄 Kiểm Tra TT", UDim2.new(0.68, 0, 0, 12), UDim2.new(0.32, -8, 0, 32), THEME.BgElevated, THEME.StatusWarn)
        chkBtn.MouseButton1Click:Connect(function()
            AppState.active_order_id = tostring(ord.order_id)
            AppState.active_order_pkg = tostring(ord.package or "VIP")
            switchTab("shop")
            CheckOrderNowBtn.Text = "⏳ Đang kiểm tra..."
            task.spawn(function()
                local ok, _, d = apiRequest("/api/check_order?order_id=" .. urlEncode(AppState.active_order_id), "GET")
                CheckOrderNowBtn.Text = "🔄 Kiểm Tra Đã Chuyển Khoản"
                if ok and type(d) == "table" and d.status == "paid" and d.key then
                    local k = sanitizeKey(d.key)
                    AppState.key = k
                    syncKeyBoxDisplay()
                    saveKeyToLocalVault(k, AppState.active_order_pkg, "Mới mua")
                    saveLocalConfig()
                    showToast("🎉 Đơn " .. AppState.active_order_id .. " đã thanh toán! Key: " .. k, "success")
                    switchTab("activate")
                    verifyAndLoadScript()
                else
                    showToast("Đơn " .. tostring(ord.order_id) .. " vẫn đang chờ chuyển khoản!", "warn")
                end
            end)
        end)
    end
end


end

-- ==============================================================================
-- 15. LOGIC ĐỒNG BỘ OMNI-SYNC 0MS, VOUCHER, PAYOS & TELEMETRY V27.0
-- ==============================================================================
local function updateHeaderTelemetryUI()
PingBadge.Text = string.format("⚡ %dms | R#%d", AppState.last_ping_ms, AppState.sync_revision)
BrandSub.Text = string.format("🟢 Omni-Sync 0ms • HWID: %s • %s", DEVICE_HWID:sub(1, 18), EXECUTOR_NAME)
end

local function reportLoaderTelemetry(confirmedKey)
task.spawn(function()
apiRequest("/api/telemetry", "POST", {
key = sanitizeKey(confirmedKey),
hwid = DEVICE_HWID,
game_id = AppState.game_id,
executor = EXECUTOR_NAME,
place_id = tonumber(game.PlaceId) or 0,
job_id = tostring(game.JobId or "")
}, 1)
end)
end

syncOmniState = function(forceFresh, autoActivateIfFound)
task.spawn(function()
local freshFlag = forceFresh and "1" or "0"
local path = string.format(
"/api/omni_sync?hwid=%s&key=%s&order_id=%s&fresh=%s",
urlEncode(DEVICE_HWID),
urlEncode(AppState.key),
urlEncode(AppState.active_order_id or ""),
freshFlag
)
local ok, _, data = apiRequest(path, "GET")
if not ok or type(data) ~= "table" then
appendSyncLog("OMNI_SYNC", "Máy chủ đang thức dậy sau nghỉ ngơi, thử lại sau 2s", "warn")
setStatus("⚠️ Máy chủ đang thức dậy, vui lòng thử lại sau 2 giây!", THEME.StatusWarn)
return
end

    if data.sync_revision then
        AppState.sync_revision = tonumber(data.sync_revision) or AppState.sync_revision
    end
    AppState.is_blacklisted = (data.is_blacklisted == true)
    AppState.maintenance = (data.maintenance == true)
    updateHeaderTelemetryUI()

    if AppState.is_blacklisted then
        BroadcastLabel.Text = "🚫 Thiết bị (HWID) này đang nằm trong danh sách hạn chế của Admin!"
        BroadcastLabel.TextColor3 = THEME.StatusErr
        appendSyncLog("SECURITY", "HWID nằm trong danh sách hạn chế!", "error")
    elseif AppState.maintenance then
        BroadcastLabel.Text = "🛠️ BẢO TRÌ: " .. tostring(data.admin_notice or "Hệ thống đang bảo trì nâng cấp")
        BroadcastLabel.TextColor3 = THEME.StatusWarn
    elseif data.admin_notice then
        AppState.admin_notice = tostring(data.admin_notice)
        BroadcastLabel.Text = "📢 " .. AppState.admin_notice
        BroadcastLabel.TextColor3 = THEME.StatusOk
    end

    if type(data.games) == "table" and #data.games > 0 then
        AppState.games_catalog = data.games
        renderGameCatalogButtons()
    end

    AppState.server_keys = type(data.keys) == "table" and data.keys or {}
    AppState.server_orders = type(data.orders) == "table" and data.orders or {}

    for _, kEntry in ipairs(AppState.server_keys) do
        if not kEntry.is_expired and not kEntry.is_banned then
            saveKeyToLocalVault(kEntry.key or kEntry.key_code, kEntry.package, kEntry.expire_str)
        end
    end

    renderVaultKeysUI()
    renderOrdersHistoryUI()

    if type(data.best_key) == "table" and data.best_key.key then
        local bk = data.best_key
        local bestCode = sanitizeKey(bk.key or bk.key_code)
        if bestCode ~= "" then
            AppState.key = bestCode
            syncKeyBoxDisplay()
            saveLocalConfig()

            AppState.current_key_meta = {
                valid = true,
                package = tostring(bk.package or "VIP"),
                tier_label = tostring(bk.tier_label or "V27.0 VIP"),
                bound_hwid = tostring(bk.bound_hwid or bk.hwid or DEVICE_HWID),
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
            appendSyncLog("OMNI_SYNC", string.format("Khớp Key [%s] (%s) • Rev #%d", bestCode, AppState.current_key_meta.package, AppState.sync_revision), "ok")

            if autoActivateIfFound then
                task.wait(0.15)
                verifyAndLoadScript()
            end
            return
        end
    end

    appendSyncLog("OMNI_SYNC", string.format("Đồng bộ hoàn tất (Keys: %d, Orders: %d, Rev #%d)", #AppState.server_keys, #AppState.server_orders, AppState.sync_revision), "info")
    if forceFresh then
        showToast("Đã đồng bộ dữ liệu mới nhất từ Server V27.0!", "info")
    end
end)


end

verifyAndLoadScript = function()
if AppState.is_busy then return end
local keyClean = sanitizeKey(AppState.key)
if #keyClean < 4 then
setStatus("⚠️ Vui lòng nhập Mã Key hoặc bấm '🔍 Tự Lấy Key Theo HWID'!", THEME.StatusErr)
showToast("Bạn chưa nhập Mã Key!", "warn")
return
end

AppState.is_busy = true
setStatus("⏳ Đang xác thực & đồng bộ HWID cho Key [" .. keyClean .. "]...", THEME.StatusOk)
appendSyncLog("VERIFY", "Đang xác thực Key [" .. keyClean .. "] với HWID [" .. DEVICE_HWID .. "]...", "info")

task.spawn(function()
    local verifyPath = string.format(
        "/api/verify_key?key=%s&hwid=%s&auto_bind=true",
        urlEncode(keyClean),
        urlEncode(DEVICE_HWID)
    )
    local ok, _, verifyData = apiRequest(verifyPath, "GET")
    updateHeaderTelemetryUI()

    if not ok or type(verifyData) ~= "table" then
        AppState.is_busy = false
        setStatus("❌ Máy chủ đang khởi động lại, vui lòng bấm KÍCH HOẠT lại sau 2 giây!", THEME.StatusErr)
        appendSyncLog("VERIFY", "Lỗi kết nối máy chủ khi xác thực Key", "error")
        showToast("Lỗi kết nối máy chủ, hãy thử lại!", "error")
        return
    end

    if not verifyData.valid then
        AppState.is_busy = false
        local errMsg = tostring(verifyData.detail or verifyData.message or "Key không hợp lệ hoặc đã khóa cho máy khác!")
        setStatus("❌ " .. errMsg, THEME.StatusErr)
        appendSyncLog("VERIFY", errMsg, "error")
        showToast(errMsg, "error")
        return
    end

    local confirmedKey = sanitizeKey(verifyData.key_code or verifyData.key or keyClean)
    AppState.key = confirmedKey
    syncKeyBoxDisplay()
    saveKeyToLocalVault(confirmedKey, verifyData.package, verifyData.expire_str)
    saveLocalConfig()

    AppState.current_key_meta = {
        valid = true,
        package = tostring(verifyData.package or "VIP"),
        tier_label = tostring(verifyData.tier_label or "V27.0 VIP"),
        bound_hwid = tostring(verifyData.bound_hwid or DEVICE_HWID),
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

    setStatus(
        string.format("✅ Hợp lệ (%s • Còn: %s)! Đang nạp Script...", AppState.current_key_meta.package, AppState.current_key_meta.time_left),
        THEME.AccentCyan
    )
    appendSyncLog("VERIFY", "Xác thực thành công Key [" .. confirmedKey .. "], đang tải module [" .. AppState.game_id .. "]", "ok")
    showToast("Xác thực thành công! Đang mở Menu Game...", "success")

    local scriptPath = string.format(
        "/api/get_script?key=%s&hwid=%s&game_id=%s",
        urlEncode(confirmedKey),
        urlEncode(DEVICE_HWID),
        urlEncode(AppState.game_id)
    )
    local sOk, _, _, rawLua = apiRequest(scriptPath, "GET")
    AppState.is_busy = false

    if sOk and type(rawLua) == "string" and #rawLua > 10 then
        local fn, compileErr = loadstring(rawLua)
        if fn then
            appendSyncLog("LOADER", "Nạp thành công module [" .. AppState.game_id .. "]!", "ok")
            MainFrame.Visible = false
            FloatingPill.Visible = true
            task.spawn(fn)
        else
            setStatus("❌ Lỗi biên dịch Script: " .. tostring(compileErr), THEME.StatusErr)
            appendSyncLog("LOADER", "Lỗi biên dịch Lua: " .. tostring(compileErr), "error")
        end
    else
        setStatus("❌ Không thể tải Script từ máy chủ, vui lòng thử lại!", THEME.StatusErr)
        appendSyncLog("LOADER", "Không thể tải nội dung Script từ /api/get_script", "error")
    end
end)


end

requestSelfResetHwid = function(targetKey)
local keyClean = sanitizeKey(targetKey or AppState.key)
if #keyClean < 4 then
showToast("Hãy nhập hoặc chọn Mã Key cần gỡ khóa thiết bị!", "warn")
return
end
openConfirmModal(
"🔓 Đổi Thiết Bị (Reset HWID)",
"Bạn có chắc chắn muốn gỡ khóa thiết bị hiện tại cho Key [" .. keyClean .. "] để đăng nhập trên máy mới không?",
function()
if AppState.is_busy then return end
AppState.is_busy = true
setStatus("⏳ Đang gỡ khóa thiết bị (Reset HWID) cho Key [" .. keyClean .. "]...", THEME.StatusWarn)
task.spawn(function()
local ok, _, data = apiRequest("/api/reset_hwid_by_key?key=" .. urlEncode(keyClean), "GET")
AppState.is_busy = false
updateHeaderTelemetryUI()
if ok and type(data) == "table" then
if data.success then
local msg = tostring(data.message or "Đã gỡ khóa HWID thành công!")
setStatus("🔓 " .. msg, THEME.AccentCyan)
appendSyncLog("RESET_HWID", msg, "ok")
showToast("Đã gỡ khóa thiết bị thành công!", "success")
syncOmniState(true, false)
else
local err = tostring(data.message or data.detail or "Không thể Reset HWID lúc này!")
setStatus("⚠️ " .. err, THEME.StatusErr)
appendSyncLog("RESET_HWID", err, "warn")
showToast(err, "warn")
end
else
setStatus("❌ Lỗi kết nối máy chủ khi gỡ khóa HWID!", THEME.StatusErr)
end
end)
end
)
end

-- Hàm tạo đơn PayOS hoặc lấy link Free 20h ngay trong Tab 2
local function createInGameOrder(pkgInfo)
if AppState.is_busy then return end
if pkgInfo.isFree then
AppState.is_busy = true
OrderStatusDetail.Text = "⏳ Đang khởi tạo Link Vượt Key Free 20 Giờ cho HWID [" .. DEVICE_HWID .. "]..."
OrderStatusDetail.TextColor3 = THEME.StatusOk
task.spawn(function()
local ok, _, data = apiRequest("/api/get_free_link", "POST", { hwid = DEVICE_HWID, game = "rb" })
AppState.is_busy = false
if ok and type(data) == "table" then
if data.existing_key then
local k = sanitizeKey(data.existing_key)
AppState.key = k
syncKeyBoxDisplay()
saveKeyToLocalVault(k, "Free 20h", "Còn hạn")
saveLocalConfig()
OrderStatusDetail.Text = "✅ Máy bạn đang có sẵn Key Free còn hạn: " .. k
showToast("Đã tự động lấy lại Key Free: " .. k, "success")
switchTab("activate")
elseif data.success and data.link then
AppState.last_pay_url = tostring(data.link)
safeSetClipboard(AppState.last_pay_url)
OrderStatusDetail.Text = "🎁 Đã copy Link Vượt Key Free 20h vào bộ nhớ tạm!\nHãy dán ra trình duyệt để vượt link, sau đó quay lại bấm '🔍 Tự Lấy Key Theo HWID'."
OrderStatusDetail.TextColor3 = THEME.AccentCyan
showToast("Đã copy Link Vượt Key Free 20h!", "success")
else
OrderStatusDetail.Text = "⚠️ " .. tostring(data.message or "Không thể tạo link vượt lúc này!")
OrderStatusDetail.TextColor3 = THEME.StatusWarn
showToast(tostring(data.message or "Lỗi tạo link Free"), "warn")
end
end
end)
return
end

AppState.is_busy = true
local vCode = sanitizeKey(VoucherInput.Text)
OrderStatusDetail.Text = string.format(
    "⏳ Đang khởi tạo đơn PayOS [%s] cho HWID [%s]%s...",
    pkgInfo.name,
    DEVICE_HWID,
    (vCode ~= "" and (" kèm Voucher " .. vCode) or "")
)
OrderStatusDetail.TextColor3 = THEME.StatusOk

task.spawn(function()
    local path = string.format(
        "/api/create_order?game=rb&package=%s&hwid=%s&voucher=%s",
        urlEncode(pkgInfo.name),
        urlEncode(DEVICE_HWID),
        urlEncode(vCode)
    )
    local ok, _, data = apiRequest(path, "POST", {
        game = "rb",
        package = pkgInfo.name,
        hwid = DEVICE_HWID,
        price = pkgInfo.price,
        voucher = vCode
    })
    AppState.is_busy = false

    if ok and type(data) == "table" and data.success and data.order_id then
        AppState.active_order_id = tostring(data.order_id)
        AppState.active_order_pkg = pkgInfo.name
        AppState.active_order_price = tonumber(data.price) or pkgInfo.price
        AppState.active_order_expire_clock = os.clock() + 300
        AppState.last_pay_url = (data.checkout_url and data.checkout_url ~= "") and tostring(data.checkout_url) or tostring(data.qr_url or WEB_SHOP_URL)
        safeSetClipboard(AppState.last_pay_url)

        local bonusNote = (tonumber(data.bonus_hours) or 0) > 0 and string.format(" (+Tặng %dh)", tonumber(data.bonus_hours)) or ""
        OrderStatusDetail.Text = string.format(
            "✅ Mã đơn: %s | Gói: %s%s | Số tiền: %s\n📋 Đã tự động Copy Link QR vào bộ nhớ tạm! Hãy dán ra trình duyệt để quét QR (Tự động nhận Key sau 3 giây).",
            AppState.active_order_id,
            pkgInfo.name,
            bonusNote,
            formatVnd(AppState.active_order_price)
        )
        OrderStatusDetail.TextColor3 = THEME.AccentCyan
        appendSyncLog("ORDER", "Đã tạo đơn " .. AppState.active_order_id .. " (" .. formatVnd(AppState.active_order_price) .. ")", "ok")
        showToast("Đã tạo đơn " .. AppState.active_order_id .. " & Copy link QR!", "success")
        syncOmniState(true, false)
    else
        local err = (type(data) == "table" and (data.detail or data.message)) or "Không thể tạo mã QR lúc này!"
        OrderStatusDetail.Text = "❌ " .. tostring(err) .. "\nBạn cũng có thể bấm '🌐 Copy Link Web Shop' ở Tab 1 để mua trên trình duyệt."
        OrderStatusDetail.TextColor3 = THEME.StatusErr
        appendSyncLog("ORDER", tostring(err), "error")
        showToast(tostring(err), "error")
    end
end)


end

local function renderShopPackagesUI()
for _, child in ipairs(ShopPkgGrid:GetChildren()) do
if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
end

for _, pkg in ipairs(PACKAGE_CATALOG) do
    local finalPrice = pkg.price
    if not pkg.isFree and AppState.voucher_discount_pct > 0 then
        finalPrice = math.max(2000, math.floor(pkg.price * (100 - AppState.voucher_discount_pct) / 100))
    end

    local cardBtn = Instance.new("TextButton", ShopPkgGrid)
    cardBtn.BackgroundColor3 = pkg.isHot and THEME.BgElevated or THEME.BgInput
    cardBtn.AutoButtonColor = true
    cardBtn.Text = ""
    Instance.new("UICorner", cardBtn).CornerRadius = UDim.new(0, 9)
    local st = Instance.new("UIStroke", cardBtn)
    st.Color = pkg.isHot and THEME.AccentCyan or (pkg.isVip and THEME.AccentIndigo or THEME.BorderSubtle)
    st.Thickness = pkg.isHot and 1.5 or 1

    local tLbl = Instance.new("TextLabel", cardBtn)
    tLbl.Size = UDim2.new(1, -12, 0, 20)
    tLbl.Position = UDim2.new(0, 6, 0, 4)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = pkg.title
    tLbl.TextColor3 = pkg.isHot and THEME.AccentCyan or THEME.TextMain
    tLbl.TextSize = 11
    tLbl.TextTruncate = Enum.TextTruncate.AtEnd
    tLbl.TextXAlignment = Enum.TextXAlignment.Left

    local pLbl = Instance.new("TextLabel", cardBtn)
    pLbl.Size = UDim2.new(1, -12, 0, 20)
    pLbl.Position = UDim2.new(0, 6, 0, 24)
    pLbl.BackgroundTransparency = 1
    pLbl.Font = Enum.Font.Code
    pLbl.Text = pkg.isFree and "MIỄN PHÍ (20H)" or formatVnd(finalPrice)
    pLbl.TextColor3 = THEME.AccentCyan
    pLbl.TextSize = 13
    pLbl.TextXAlignment = Enum.TextXAlignment.Left

    local sLbl = Instance.new("TextLabel", cardBtn)
    sLbl.Size = UDim2.new(1, -12, 0, 16)
    sLbl.Position = UDim2.new(0, 6, 0, 46)
    sLbl.BackgroundTransparency = 1
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.Text = pkg.sub
    sLbl.TextColor3 = THEME.TextSub
    sLbl.TextSize = 9.5
    sLbl.TextTruncate = Enum.TextTruncate.AtEnd
    sLbl.TextXAlignment = Enum.TextXAlignment.Left

    cardBtn.MouseButton1Click:Connect(function()
        createInGameOrder(pkg)
    end)
end


end

ApplyVoucherBtn.MouseButton1Click:Connect(function()
local code = sanitizeKey(VoucherInput.Text)
if #code < 2 then
AppState.voucher_code = ""
AppState.voucher_discount_pct = 0
AppState.voucher_bonus_hours = 0
renderShopPackagesUI()
showToast("Đã xoá mã giảm giá!", "info")
return
end
ApplyVoucherBtn.Text = "⏳ Đang kiểm tra..."
task.spawn(function()
local ok, _, data = apiRequest("/api/check_voucher?code=" .. urlEncode(code) .. "&package=" .. urlEncode("1 Tuần"), "GET")
ApplyVoucherBtn.Text = "🏷️ Áp Mã Giảm Giá"
if ok and type(data) == "table" and data.success then
AppState.voucher_code = code
AppState.voucher_discount_pct = tonumber(data.discount_percent) or 0
AppState.voucher_bonus_hours = tonumber(data.bonus_hours) or 0
renderShopPackagesUI()
OrderStatusDetail.Text = "🎉 " .. tostring(data.message or ("Đã áp dụng mã " .. code))
OrderStatusDetail.TextColor3 = THEME.AccentCyan
appendSyncLog("VOUCHER", tostring(data.message), "ok")
showToast(tostring(data.message), "success")
else
AppState.voucher_discount_pct = 0
AppState.voucher_bonus_hours = 0
renderShopPackagesUI()
local msg = (type(data) == "table" and data.message) or "Mã giảm giá không tồn tại hoặc đã hết lượt!"
showToast(tostring(msg), "warn")
end
end)
end)

local function checkActiveInGameOrder(manualClick)
if not AppState.active_order_id then
if manualClick then
showToast("Chưa có đơn hàng nào đang chờ! Hãy chọn 1 gói ở trên.", "warn")
end
return
end
task.spawn(function()
local ok, _, data = apiRequest("/api/check_order?order_id=" .. urlEncode(AppState.active_order_id), "GET")
if ok and type(data) == "table" and data.status == "paid" and data.key then
local newKey = sanitizeKey(data.key)
local paidOid = AppState.active_order_id
AppState.active_order_id = nil
AppState.key = newKey
syncKeyBoxDisplay()
saveKeyToLocalVault(newKey, AppState.active_order_pkg or "VIP", "Mới thanh toán")
saveLocalConfig()
OrderStatusDetail.Text = "🎉 THANH TOÁN THÀNH CÔNG ĐƠN " .. tostring(paidOid) .. "! Đã nhận Key: " .. newKey .. " và tự động kích hoạt!"
OrderStatusDetail.TextColor3 = THEME.AccentCyan
appendSyncLog("ORDER_PAID", "Đơn " .. tostring(paidOid) .. " hoàn tất -> Key: " .. newKey, "ok")
showToast("Thanh toán thành công! Key: " .. newKey, "success")
switchTab("activate")
verifyAndLoadScript()
elseif manualClick then
showToast("Đơn " .. tostring(AppState.active_order_id) .. " vẫn đang chờ chuyển khoản!", "info")
end
end)
end

-- ==============================================================================
-- 16. KẾT NỐI SỰ KIỆN NÚT BẤM TRÊN TOÀN BỘ 6 TAB
-- ==============================================================================
ActivateBtn.MouseButton1Click:Connect(verifyAndLoadScript)

AutoFetchBtn.MouseButton1Click:Connect(function()
setStatus("⏳ Đang đồng bộ Key gắn với HWID [" .. DEVICE_HWID .. "]...", THEME.StatusOk)
syncOmniState(true, false)
end)

PingBadge.MouseButton1Click:Connect(function()
syncOmniState(true, false)
end)

QuickHwidSideBtn.MouseButton1Click:Connect(function()
if safeSetClipboard(DEVICE_HWID) then
showToast("Đã copy HWID: " .. DEVICE_HWID, "success")
setStatus("📋 Đã copy Mã Máy (HWID): " .. DEVICE_HWID, THEME.AccentCyan)
else
showToast("HWID của bạn: " .. DEVICE_HWID, "info")
end
end)

OpenShopBtn.MouseButton1Click:Connect(function()
local url = WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID)
if safeSetClipboard(url) then
showToast("Đã copy Link Web Shop kèm sẵn HWID!", "success")
setStatus("🌐 Đã copy Link: " .. url, THEME.AccentCyan)
end
end)

QuickResetBtn.MouseButton1Click:Connect(function()
requestSelfResetHwid(AppState.key)
end)

CheckOrderNowBtn.MouseButton1Click:Connect(function()
checkActiveInGameOrder(true)
end)

CopyPayLinkBtn.MouseButton1Click:Connect(function()
local target = (AppState.last_pay_url ~= "") and AppState.last_pay_url or (WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID))
if safeSetClipboard(target) then
showToast("Đã copy Link thanh toán vào bộ nhớ tạm!", "success")
end
end)

BindNowBtn.MouseButton1Click:Connect(function()
local kToBind = sanitizeKey(BindKeyInput.Text)
if #kToBind < 4 then
showToast("Vui lòng nhập Mã Key Tự Do cần gán vào máy này!", "warn")
return
end
BindNowBtn.Text = "⏳ Đang gán..."
task.spawn(function()
local ok, _, data = apiRequest(
string.format("/api/verify_key?key=%s&hwid=%s&auto_bind=true", urlEncode(kToBind), urlEncode(DEVICE_HWID)),
"GET"
)
BindNowBtn.Text = "🔗 Gán HWID Máy Này"
if ok and type(data) == "table" and data.valid then
local rk = sanitizeKey(data.key_code or data.key or kToBind)
BindKeyInput.Text = ""
AppState.key = rk
syncKeyBoxDisplay()
saveKeyToLocalVault(rk, data.package, data.expire_str)
saveLocalConfig()
showToast("Đã gán cứng HWID máy này vào Key " .. rk .. "!", "success")
syncOmniState(true, false)
else
local err = (type(data) == "table" and (data.detail or data.message)) or "Không thể gán HWID cho Key này!"
showToast(tostring(err), "error")
end
end)
end)

RefreshVaultBtn.MouseButton1Click:Connect(function()
syncOmniState(true, false)
end)

RefreshOrdersBtn.MouseButton1Click:Connect(function()
syncOmniState(true, false)
end)

-- Tab 5: Tiện ích VIP
ToggleAutoLoginBtn.MouseButton1Click:Connect(function()
AppState.auto_login = not AppState.auto_login
ToggleAutoLoginBtn.Text = "⚡ Tự Động Kích Hoạt Khi Có Key: " .. (AppState.auto_login and "BẬT" or "TẮT")
ToggleAutoLoginBtn.TextColor3 = AppState.auto_login and THEME.AccentCyan or THEME.TextSub
saveLocalConfig()
end)

ToggleAntiAfkBtn.MouseButton1Click:Connect(function()
AppState.anti_afk = not AppState.anti_afk
ToggleAntiAfkBtn.Text = "🛡️ Chống Văng Khi Treo Máy (Anti-AFK): " .. (AppState.anti_afk and "BẬT" or "TẮT")
ToggleAntiAfkBtn.TextColor3 = AppState.anti_afk and THEME.AccentCyan or THEME.TextSub
saveLocalConfig()
showToast(AppState.anti_afk and "Đã bật Anti-AFK!" or "Đã tắt Anti-AFK!", "info")
end)

BoostFpsBtn.MouseButton1Click:Connect(function()
pcall(function()
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(Workspace:GetDescendants()) do
if v:IsA("BasePart") then
v.Material = Enum.Material.SmoothPlastic
v.Reflectance = 0
elseif v:IsA("Decal") or v:IsA("Texture") then
v.Transparency = 1
elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
v.Enabled = false
end
end
end)
appendSyncLog("UTILS", "Đã kích hoạt chế độ FPS Boost tối ưu đồ họa", "ok")
showToast("🚀 Đã tối ưu đồ họa & tăng FPS thành công!", "success")
end)

FullBrightBtn.MouseButton1Click:Connect(function()
AppState.full_bright = not AppState.full_bright
FullBrightBtn.Text = "☀️ Làm Sáng Bản Đồ (FullBright): " .. (AppState.full_bright and "BẬT" or "TẮT")
FullBrightBtn.TextColor3 = AppState.full_bright and THEME.AccentCyan or THEME.TextMain
pcall(function()
if AppState.full_bright then
Lighting.Brightness = 2.5
Lighting.ClockTime = 14
Lighting.FogEnd = 100000
Lighting.GlobalShadows = false
Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
else
Lighting.Brightness = 1
Lighting.GlobalShadows = true
end
end)
end)

RejoinServerBtn.MouseButton1Click:Connect(function()
showToast("Đang kết nối lại vào Server hiện tại...", "info")
TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

ServerHopBtn.MouseButton1Click:Connect(function()
showToast("Đang tìm Server mới ít người...", "info")
task.spawn(function()
local ok, _, raw = rawHttpRequest(
string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId),
"GET"
)
if ok and raw then
local pOk, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
if pOk and type(parsed) == "table" and type(parsed.data) == "table" then
for _, srv in ipairs(parsed.data) do
if type(srv) == "table" and srv.id ~= game.JobId and tonumber(srv.playing or 0) < tonumber(srv.maxPlayers or 0) then
TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
return
end
end
end
end
TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
end)

CopyAutoScriptBtn.MouseButton1Click:Connect(function()
local k = sanitizeKey(AppState.key)
if #k < 4 then
showToast("Bạn chưa có Mã Key để tạo Auto-Script!", "warn")
return
end
local autoCode = string.format(
'getgenv().BIVA_AUTO_KEY = "%s"; loadstring(game:HttpGet("%s/biva_storm.lua"))()',
k,
API_ENDPOINTS[activeEndpointIndex]
)
if safeSetClipboard(autoCode) then
showToast("⚡ Đã copy Auto-Script kèm sẵn Key " .. k .. "!", "success")
end
end)

WipeCacheBtn.MouseButton1Click:Connect(function()
openConfirmModal(
"🧹 Xoá Dữ Liệu Lưu Cục Bộ",
"Bạn có chắc chắn muốn xoá file lưu cấu hình và danh sách Key lưu trên máy này không? (Key trên Server vẫn an toàn 100%)",
function()
pcall(function()
if delfile and isfile then
if isfile(SAVE_FILE_NAME) then delfile(SAVE_FILE_NAME) end
if isfile(VAULT_FILE_NAME) then delfile(VAULT_FILE_NAME) end
end
end)
AppState.key = ""
AppState.local_vault = {}
syncKeyBoxDisplay()
renderVaultKeysUI()
showToast("Đã xoá sạch bộ nhớ đệm cục bộ!", "info")
end
)
end)

-- Tab 6: Console & Diagnostics
RunDiagBtn.MouseButton1Click:Connect(function()
RunDiagBtn.Text = "⏳ Đang kiểm tra..."
task.spawn(function()
appendSyncLog("DIAG", "Bắt đầu kiểm tra kết nối tới " .. API_ENDPOINTS[activeEndpointIndex] .. "/api/health...", "info")
local ok, status, data = apiRequest("/api/health", "GET")
RunDiagBtn.Text = "🧪 Chẩn Đoán Server"
if ok and type(data) == "table" and data.status == "ok" then
local msg = string.format(
"Server OK! Ver: %s | Ping: %dms | Rev: #%s | Indexed Keys: %s | PayOS: %s",
tostring(data.version or "27.0"),
AppState.last_ping_ms,
tostring(data.sync_revision or 1),
tostring(data.indexed_keys or 0),
tostring(data.payos_mode or "auto")
)
appendSyncLog("DIAG_OK", msg, "ok")
showToast("Kết nối Server hoàn hảo (" .. tostring(AppState.last_ping_ms) .. "ms)!", "success")
else
appendSyncLog("DIAG_ERR", "HTTP Status: " .. tostring(status) .. " - Máy chủ có thể đang Cold-Start", "error")
showToast("Máy chủ đang phản hồi chậm, hãy thử lại sau 2 giây!", "warn")
end
end)
end)

CopyLogsBtn.MouseButton1Click:Connect(function()
if safeSetClipboard(table.concat(AppState.sync_logs, "\n")) then
showToast("Đã copy toàn bộ Nhật Ký Đồng Bộ!", "success")
end
end)

LocalPlayer.Idled:Connect(function()
if AppState.anti_afk then
pcall(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
end)

-- ==============================================================================
-- 17. KHỞI CHẠY HỆ THỐNG & VÒNG LẶP ĐỒNG BỘ THỜI GIAN THỰC V27.0
-- ==============================================================================
loadLocalConfig()
applyThemePreset(AppState.theme_name)
renderGameCatalogButtons()
renderShopPackagesUI()
renderVaultKeysUI()
renderOrdersHistoryUI()
syncKeyBoxDisplay()
switchTab("activate")

ToggleAutoLoginBtn.Text = "⚡ Tự Động Kích Hoạt Khi Có Key: " .. (AppState.auto_login and "BẬT" or "TẮT")
ToggleAutoLoginBtn.TextColor3 = AppState.auto_login and THEME.AccentCyan or THEME.TextSub
ToggleAntiAfkBtn.Text = "🛡️ Chống Văng Khi Treo Máy (Anti-AFK): " .. (AppState.anti_afk and "BẬT" or "TẮT")
ToggleAntiAfkBtn.TextColor3 = AppState.anti_afk and THEME.AccentCyan or THEME.TextSub

appendSyncLog("BOOT", "Khởi chạy BIVA STORM " .. VERSION_TAG .. " • HWID: " .. DEVICE_HWID, "ok")

task.spawn(function()
showToast("BIVA STORM " .. VERSION_TAG .. " đã sẵn sàng!", "info")
if AppState.key ~= "" and AppState.auto_login then
syncOmniState(false, false)
verifyAndLoadScript()
else
syncOmniState(true, AppState.auto_login)
end
end)

-- Vòng lặp cập nhật đồng hồ đếm ngược Key mỗi 1 giây & tự động đồng bộ đơn QR / Revision
task.spawn(function()
local secCounter = 0
while ScreenGui and ScreenGui.Parent do
task.wait(1)
secCounter = secCounter + 1

    if AppState.current_key_meta.expire_ts and AppState.current_key_meta.expire_ts > 0 then
        refreshLicenseInspectorUI()
    end

    if AppState.active_order_id and (secCounter % 3 == 0) then
        checkActiveInGameOrder(false)
    elseif secCounter % 15 == 0 then
        syncOmniState(false, false)
    end
end


end)
