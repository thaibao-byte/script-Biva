-- ==============================================================================
-- BIVA STORM V45 SUPREME | APEX OMEGA CORE LOADER & IN-GAME COMMAND CENTER
-- Phiên bản Chủ Dự Án (100% Pure Luau, Zero-Bug):
-- * Tự động co giãn tỷ lệ (Auto UIScale) chuẩn mọi màn hình Điện thoại & PC
-- * Chọn Tựa Game trực tiếp (Steal An Egg, Blox Fruits, Fisch, Dead Rails)
-- * Bảng Giá Chuẩn: Miễn Phí = Vượt Link (20h) | 8.000đ = 1 Ngày | 40.000đ = 1 Tuần | 130.000đ = 1 Tháng
-- * Đồng bộ trực tiếp với Server V45, tự truyền biến sang steal_egg.lua
-- ==============================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local AnalyticsService = nil
pcall(function()
AnalyticsService = game:GetService("RbxAnalyticsService")
end)
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
-- ==============================================================================
-- 1. CẤU HÌNH KẾT NỐI & HẰNG SỐ HỆ THỐNG V45
-- ==============================================================================
local API_BASE = "https://biva-hub.onrender.com"
local WEB_SHOP_URL = API_BASE .. "/index.html"
local LOADER_RAW_URL = "https://raw.githubusercontent.com/thaibao-byte/script-Biva/main/biva_storm.lua"
local SAVE_FILE_NAME = "BivaStorm_ApexOmega_Config_v45.json"
local VAULT_FILE_NAME = "BivaStorm_ApexOmega_Vault_v45.json"
local DEFAULT_PRICING_FOOTNOTE = "💡 Chú thích: Miễn Phí = Vượt Link (20h) • 8.000đ = 1 Ngày • 40.000đ = 1 Tuần • 130.000đ = 1 Tháng. Mọi gói trả phí đều kích hoạt tự động sau 3 giây quét QR, tự khóa bảo vệ theo Mã Máy (HWID), hỗ trợ tự đổi máy miễn phí và cam kết bù giờ 100% nếu bảo trì."
local GAME_MODES = {
{ id = "steal_egg", name = "🥚 Steal An Egg V45" },
{ id = "blox_fruits", name = "🏴‍☠️ Blox Fruits VIP" },
{ id = "fisch", name = "🐟 Fisch Assistant" },
{ id = "dead_rails", name = "🚂 Dead Rails HUD" }
}
local THEMES = {
CyberBlue = {
Name = "Cyber Blue",
BgMain = Color3.fromRGB(5, 8, 18),
BgCard = Color3.fromRGB(11, 18, 34),
BgElevated = Color3.fromRGB(18, 29, 52),
BgInput = Color3.fromRGB(7, 12, 24),
Accent = Color3.fromRGB(0, 229, 255),
Primary = Color3.fromRGB(37, 99, 235),
Purple = Color3.fromRGB(147, 51, 234),
TextMain = Color3.fromRGB(248, 250, 252),
TextSub = Color3.fromRGB(148, 163, 184),
TextMuted = Color3.fromRGB(100, 116, 139),
Ok = Color3.fromRGB(16, 185, 129),
Warn = Color3.fromRGB(245, 158, 11),
Err = Color3.fromRGB(244, 63, 94)
},
Emerald = {
Name = "Emerald",
BgMain = Color3.fromRGB(4, 13, 11),
BgCard = Color3.fromRGB(9, 24, 20),
BgElevated = Color3.fromRGB(15, 37, 31),
BgInput = Color3.fromRGB(6, 17, 14),
Accent = Color3.fromRGB(16, 185, 129),
Primary = Color3.fromRGB(5, 150, 105),
Purple = Color3.fromRGB(52, 211, 153),
TextMain = Color3.fromRGB(240, 253, 244),
TextSub = Color3.fromRGB(167, 243, 208),
TextMuted = Color3.fromRGB(110, 231, 183),
Ok = Color3.fromRGB(16, 185, 129),
Warn = Color3.fromRGB(245, 158, 11),
Err = Color3.fromRGB(244, 63, 94)
},
Amethyst = {
Name = "Amethyst",
BgMain = Color3.fromRGB(10, 6, 20),
BgCard = Color3.fromRGB(18, 11, 36),
BgElevated = Color3.fromRGB(28, 18, 54),
BgInput = Color3.fromRGB(12, 7, 26),
Accent = Color3.fromRGB(192, 132, 252),
Primary = Color3.fromRGB(147, 51, 234),
Purple = Color3.fromRGB(216, 180, 254),
TextMain = Color3.fromRGB(250, 245, 255),
TextSub = Color3.fromRGB(216, 180, 254),
TextMuted = Color3.fromRGB(147, 51, 234),
Ok = Color3.fromRGB(56, 189, 248),
Warn = Color3.fromRGB(245, 158, 11),
Err = Color3.fromRGB(244, 63, 94)
}
}
local THEME = THEMES.CyberBlue
local ThemeBindings = {}
-- ==============================================================================
-- 2. HÀM TIỆN ÍCH CHUẨN HÓA HWID / KEY & TƯƠNG THÍCH EXECUTOR
-- ==============================================================================
local function cleanHwid(raw)
if not raw then return "" end
local s = tostring(raw):gsub("%s+", "")
s = s:gsub("^[hH][wW][iI][dD][:=-]*", "")
s = s:gsub("^[dD][eE][vV][iI][cC][eE][:=-]*", "")
s = s:gsub("[^%w%-_]", ""):upper()
return s:sub(1, 64)
end
local function cleanKey(raw)
if not raw then return "" end
local s = tostring(raw):gsub("%s+", "")
s = s:gsub("^[kK][eE][yY][:=-]*", "")
s = s:gsub("[^%w%-]", ""):upper()
return s:sub(1, 64)
end
local function maskKey(k)
local c = cleanKey(k)
if #c <= 6 then return c end
return c:sub(1, 5) .. "••••" .. c:sub(#c - 2, #c)
end
local function formatVND(amount)
local n = math.max(0, math.floor(tonumber(amount) or 0))
if n == 0 then return "Miễn Phí" end
local s = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
return s .. "đ"
end
local function formatRemain(sec)
sec = math.max(0, math.floor(tonumber(sec) or 0))
if sec <= 0 then return "Đã hết hạn" end
if sec > 3000 * 86400 then return "Vĩnh Viễn" end
local d = math.floor(sec / 86400)
local h = math.floor((sec % 86400) / 3600)
local m = math.floor((sec % 3600) / 60)
local s = sec % 60
if d > 0 then
return string.format("%dn %02dh %02dp", d, h, m)
elseif h > 0 then
return string.format("%02dh %02dp %02ds", h, m, s)
end
return string.format("%02dp %02ds", m, s)
end
local function urlEncode(str)
if not str then return "" end
str = tostring(str):gsub("\n", "\r\n")
str = str:gsub("([^%w %-%_%.%~])", function(c)
return string.format("%%%02X", string.byte(c))
end)
return str:gsub(" ", "+")
end
local function getExecutorName()
local ok, res = pcall(function()
if type(identifyexecutor) == "function" then
local n, v = identifyexecutor()
return tostring(n or "Executor") .. (v and (" " .. tostring(v)) or "")
elseif type(getexecutorname) == "function" then
return tostring(getexecutorname())
end
return "Roblox Executor"
end)
return (ok and res and res ~= "") and res or "Roblox Client"
end
local function getDeviceHwid()
local raw = ""
pcall(function()
if type(gethwid) == "function" then
raw = gethwid()
elseif AnalyticsService and type(AnalyticsService.GetClientId) == "function" then
raw = AnalyticsService:GetClientId()
end
end)
local cleaned = cleanHwid(raw)
if #cleaned < 4 then
cleaned = "RBX-" .. tostring(LocalPlayer.UserId or 100001)
end
return cleaned
end
local DEVICE_HWID = getDeviceHwid()
local EXECUTOR_NAME = getExecutorName()
local function copyClipboard(text)
if not text or text == "" then return false end
return pcall(function()
if type(setclipboard) == "function" then
setclipboard(tostring(text))
elseif type(toclipboard) == "function" then
toclipboard(tostring(text))
elseif Clipboard and type(Clipboard.set) == "function" then
Clipboard.set(tostring(text))
else
error("No clipboard")
end
end)
end
local function readClipboard()
local ok, res = pcall(function()
if type(getclipboard) == "function" then
return getclipboard()
end
return ""
end)
return (ok and type(res) == "string") and res or ""
end
local function loadConfig()
local cfg = {
saved_key = "",
selected_game = "steal_egg",
auto_login = true,
anti_afk = true,
sound_fx = true,
hide_key = false,
theme_id = "CyberBlue",
pending_order_id = "",
pending_package = ""
}
pcall(function()
if type(isfile) == "function" and type(readfile) == "function" then
for _, fName in ipairs({ SAVE_FILE_NAME, "BivaStorm_ApexOmega_Config_v40.json", "BivaStorm_ApexOmega_Config_v35.json" }) do
if isfile(fName) then
local decoded = HttpService:JSONDecode(readfile(fName))
if type(decoded) == "table" then
for k, v in pairs(decoded) do
cfg[k] = v
end
break
end
end
end
end
end)
pcall(function()
local g = (type(getgenv) == "function") and getgenv() or _G
if g and type(g.BIVA_AUTO_KEY) == "string" and #g.BIVA_AUTO_KEY >= 4 then
cfg.saved_key = cleanKey(g.BIVA_AUTO_KEY)
else
cfg.saved_key = cleanKey(cfg.saved_key)
end
if g and type(g.BIVA_GAME) == "string" and #g.BIVA_GAME >= 2 then
cfg.selected_game = tostring(g.BIVA_GAME)
end
end)
local chosenTheme = THEMES[cfg.theme_id]
if chosenTheme then
THEME = chosenTheme
end
return cfg
end
local function saveConfig(cfg)
pcall(function()
if type(writefile) == "function" then
writefile(SAVE_FILE_NAME, HttpService:JSONEncode(cfg))
if cfg.saved_key and #cfg.saved_key >= 4 then
writefile("Biva_SavedKey.txt", cfg.saved_key)
end
writefile("Biva_HWID.txt", DEVICE_HWID)
end
end)
end
local function loadVault()
local list = {}
pcall(function()
if type(isfile) == "function" and type(readfile) == "function" then
for _, vFile in ipairs({ VAULT_FILE_NAME, "BivaStorm_ApexOmega_Vault_v40.json", "BivaStorm_ApexOmega_Vault_v35.json" }) do
if isfile(vFile) then
local dec = HttpService:JSONDecode(readfile(vFile))
if type(dec) == "table" then
list = dec
break
end
end
end
end
end)
return list
end
local function saveKeyToVault(keyCode, pkgName)
local c = cleanKey(keyCode)
if c == "" then return end
local old = loadVault()
local out = { { key = c, package = tostring(pkgName or "VIP") } }
for _, item in ipairs(old) do
if type(item) == "table" and cleanKey(item.key) ~= c and #out < 10 then
table.insert(out, item)
end
end
pcall(function()
if type(writefile) == "function" then
writefile(VAULT_FILE_NAME, HttpService:JSONEncode(out))
end
end)
end
-- ==============================================================================
-- 3. LÕI KẾT NỐI HTTP AN TOÀN
-- ==============================================================================
local httpReq = nil
pcall(function()
httpReq = (syn and syn.request)
or (http and http.request)
or http_request
or (fluxus and fluxus.request)
or request
end)
local function rawHttp(url, method, bodyTable)
method = method or "GET"
if httpReq then
local headers = {
Accept = "application/json, text/plain, /",
["Cache-Control"] = "no-cache"
}
local bodyStr = nil
if bodyTable then
headers["Content-Type"] = "application/json"
bodyStr = HttpService:JSONEncode(bodyTable)
end
local ok, res = pcall(function()
return httpReq({
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
local function apiCall(path, method, bodyTable, isPlainText)
local sep = string.find(path, "?", 1, true) and "&" or "?"
local fullUrl = API_BASE .. path .. sep .. "_t=" .. tostring(math.floor(os.clock() * 1000))
local t0 = os.clock()
local ok, status, raw = rawHttp(fullUrl, method, bodyTable)
local ping = math.max(5, math.floor((os.clock() - t0) * 1000))
if ok and status > 0 and status < 500 and raw ~= "" then
if isPlainText then
return raw, status, ping
end
local decOk, data = pcall(function()
return HttpService:JSONDecode(raw)
end)
if decOk and type(data) == "table" then
return data, status, ping
end
end
return nil, 0, ping
end
-- ==============================================================================
-- 4. TRẠNG THÁI ỨNG DỤNG & ÂM THANH TƯƠNG TÁC
-- ==============================================================================
local State = {
config = loadConfig(),
sync_rev = 1,
ping = 0,
admin_notice = "Hệ thống BIVA STORM V45 SUPREME cấp Key tự động 3 giây hoạt động ổn định 100%",
pricing_footnote = DEFAULT_PRICING_FOOTNOTE,
maintenance = false,
voucher_code = "",
voucher_discount = 0,
flash_sale = { active = false, discount_percent = 0, title = "", remaining_text = "" },
package_prices = {
["1 Ngày"] = 8000,
["1 Tuần"] = 40000,
["1 Tháng"] = 130000
},
key_meta = {
valid = false,
key_code = "",
package = "Chưa kích hoạt",
bound_hwid = "Chưa khóa máy",
device_count = 0,
max_devices = 1,
expire_ts = 0,
time_left = "--"
},
keys = {},
orders = {},
tickets = {},
busy = false,
watching_order = false,
minimized = false
}
local function playUiSound(isSuccess)
if not State.config.sound_fx then return end
pcall(function()
local snd = Instance.new("Sound")
snd.SoundId = isSuccess and "rbxassetid://6895079853" or "rbxassetid://6895079775"
snd.Volume = isSuccess and 0.45 or 0.25
snd.Parent = SoundService
snd:Play()
task.delay(1.2, function()
if snd and snd.Parent then snd:Destroy() end
end)
end)
end
-- ==============================================================================
-- 5. KHỞI TẠO GIAO DIỆN APEX OMEGA V45 (TỰ CO GIÃN ĐA MÀN HÌNH + SPRING TWEEN)
-- ==============================================================================
local GuiParent = nil
pcall(function()
if type(gethui) == "function" then GuiParent = gethui() end
end)
if not GuiParent then
local okC = pcall(function() return CoreGui.Name end)
GuiParent = okC and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end
for _, oldName in ipairs({ "BivaStormV26OmniLoader", "BivaStormV27HyperionLoader", "BivaStormSovereignLoader" }) do
local old = GuiParent:FindFirstChild(oldName)
if old then pcall(function() old:Destroy() end) end
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BivaStormSovereignLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent
local function BindTheme(inst, prop, key)
table.insert(ThemeBindings, { inst = inst, prop = prop, key = key })
pcall(function() inst[prop] = THEME[key] end)
end
local function SetTheme(themeId)
local nextTheme = THEMES[themeId]
if not nextTheme then return end
THEME = nextTheme
State.config.theme_id = themeId
saveConfig(State.config)
for _, b in ipairs(ThemeBindings) do
if b.inst and b.inst.Parent and THEME[b.key] then
pcall(function()
TweenService:Create(b.inst, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { [b.prop] = THEME[b.key] }):Play()
end)
end
end
end
local function New(className, props)
local inst = Instance.new(className)
for k, v in pairs(props or {}) do
if k ~= "Parent" then inst[k] = v end
end
if props and props.Parent then inst.Parent = props.Parent end
return inst
end
local function Corner(parent, r)
return New("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = parent })
end
local function Stroke(parent, themeKey, thick, trans)
local s = New("UIStroke", {
Color = THEME[themeKey or "Accent"] or Color3.fromRGB(0, 229, 255),
Thickness = thick or 1,
Transparency = trans or 0.65,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
Parent = parent
})
if themeKey then BindTheme(s, "Color", themeKey) end
return s
end
local function MakeDraggable(handle, target)
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
handle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = target.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then dragging = false end
end)
end
end)
handle.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)
UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)
end
-- TOAST THÔNG BÁO MƯỢT MÀ
local ToastHolder = New("Frame", {
BackgroundTransparency = 1,
AnchorPoint = Vector2.new(0.5, 0),
Position = UDim2.new(0.5, 0, 0, 14),
Size = UDim2.new(0, 360, 0, 90),
ZIndex = 120,
Parent = ScreenGui
})
New("UIListLayout", {
Padding = UDim.new(0, 5),
HorizontalAlignment = Enum.HorizontalAlignment.Center,
Parent = ToastHolder
})
local function showToast(msg, isErr)
playUiSound(not isErr)
local item = New("Frame", {
BackgroundColor3 = THEME.BgCard,
Size = UDim2.new(1, 0, 0, 32),
ZIndex = 121,
Parent = ToastHolder
})
Corner(item, 8)
New("UIStroke", {
Color = isErr and THEME.Err or THEME.Accent,
Thickness = 1.2,
Transparency = 0.2,
Parent = item
})
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamBold,
Text = (isErr and "⚠️ " or "⚡ ") .. tostring(msg),
TextColor3 = THEME.TextMain,
TextSize = 11.5,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
ZIndex = 122,
Parent = item
})
task.delay(2.5, function()
if item and item.Parent then item:Destroy() end
end)
end
-- NÚT THU NHỎ NỔI (FLOATING PILL)
local FloatingOrb = New("TextButton", {
BackgroundColor3 = THEME.BgCard,
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 14, 0.5, 0),
Size = UDim2.new(0, 168, 0, 36),
Font = Enum.Font.GothamBold,
Text = "⚡ BIVA V45",
TextColor3 = THEME.Accent,
TextSize = 11.5,
Visible = false,
AutoButtonColor = false,
ZIndex = 95,
Parent = ScreenGui
})
Corner(FloatingOrb, 18)
Stroke(FloatingOrb, "Accent", 1.4, 0.2)
BindTheme(FloatingOrb, "BackgroundColor3", "BgCard")
BindTheme(FloatingOrb, "TextColor3", "Accent")
MakeDraggable(FloatingOrb, FloatingOrb)
-- CỬA SỔ CHÍNH (580 x 390) + TỰ CO GIÃN THEO MÀN HÌNH ĐIỆN THOẠI & PC
local MainWindow = New("Frame", {
BackgroundColor3 = THEME.BgMain,
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 0),
Size = UDim2.new(0, 580, 0, 390),
ClipsDescendants = true,
Parent = ScreenGui
})
Corner(MainWindow, 14)
Stroke(MainWindow, "Accent", 1.4, 0.35)
BindTheme(MainWindow, "BackgroundColor3", "BgMain")
local WindowScale = New("UIScale", { Scale = 1, Parent = MainWindow })
local function updateResponsiveScale()
local cam = workspace.CurrentCamera
if not cam then return end
local vp = cam.ViewportSize
local scaleX = (vp.X - 24) / 580
local scaleY = (vp.Y - 24) / 390
local s = math.min(1, scaleX, scaleY)
WindowScale.Scale = math.clamp(s, 0.62, 1)
end
updateResponsiveScale()
if workspace.CurrentCamera then
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
end
-- THANH TIÊU ĐỀ TRÊN CÙNG (HEADER)
local Header = New("Frame", {
BackgroundColor3 = THEME.BgCard,
Size = UDim2.new(1, 0, 0, 44),
Parent = MainWindow
})
Corner(Header, 14)
BindTheme(Header, "BackgroundColor3", "BgCard")
MakeDraggable(Header, MainWindow)
local LogoBadge = New("Frame", {
BackgroundColor3 = THEME.Primary,
Position = UDim2.new(0, 10, 0.5, -13),
Size = UDim2.new(0, 26, 0, 26),
Parent = Header
})
Corner(LogoBadge, 8)
BindTheme(LogoBadge, "BackgroundColor3", "Primary")
New("TextLabel", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 1, 0),
Font = Enum.Font.GothamBlack,
Text = "⚡",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 14,
Parent = LogoBadge
})
local TitleLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 44, 0, 5),
Size = UDim2.new(0, 320, 0, 16),
Font = Enum.Font.GothamBlack,
Text = "BIVA STORM V45 — APEX OMEGA LOADER",
TextColor3 = THEME.TextMain,
TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = Header
})
BindTheme(TitleLbl, "TextColor3", "TextMain")
local SubHeaderLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 44, 0, 22),
Size = UDim2.new(0, 340, 0, 15),
Font = Enum.Font.GothamMedium,
Text = "🟢 " .. EXECUTOR_NAME .. " • Ping: --ms",
TextColor3 = THEME.Accent,
TextSize = 10.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = Header
})
BindTheme(SubHeaderLbl, "TextColor3", "Accent")
local SyncTopBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(1, -132, 0.5, -13),
Size = UDim2.new(0, 60, 0, 26),
Font = Enum.Font.GothamBold,
Text = "🔄 Sync",
TextColor3 = THEME.Accent,
TextSize = 11,
AutoButtonColor = false,
Parent = Header
})
Corner(SyncTopBtn, 7)
BindTheme(SyncTopBtn, "BackgroundColor3", "BgElevated")
BindTheme(SyncTopBtn, "TextColor3", "Accent")
local MinBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(1, -66, 0.5, -13),
Size = UDim2.new(0, 26, 0, 26),
Font = Enum.Font.GothamBold,
Text = "—",
TextColor3 = THEME.TextMain,
TextSize = 12,
AutoButtonColor = false,
Parent = Header
})
Corner(MinBtn, 7)
BindTheme(MinBtn, "BackgroundColor3", "BgElevated")
BindTheme(MinBtn, "TextColor3", "TextMain")
local CloseBtn = New("TextButton", {
BackgroundColor3 = Color3.fromRGB(64, 16, 28),
Position = UDim2.new(1, -34, 0.5, -13),
Size = UDim2.new(0, 26, 0, 26),
Font = Enum.Font.GothamBold,
Text = "✕",
TextColor3 = THEME.Err,
TextSize = 12,
AutoButtonColor = false,
Parent = Header
})
Corner(CloseBtn, 7)
-- CỘT ĐIỀU HƯỚNG 5 TAB BÊN TRÁI (SIDEBAR)
local Sidebar = New("Frame", {
BackgroundColor3 = THEME.BgCard,
Position = UDim2.new(0, 8, 0, 50),
Size = UDim2.new(0, 142, 1, -58),
Parent = MainWindow
})
Corner(Sidebar, 11)
Stroke(Sidebar, "Accent", 1, 0.8)
BindTheme(Sidebar, "BackgroundColor3", "BgCard")
local NavList = New("Frame", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 6, 0, 6),
Size = UDim2.new(1, -12, 1, -78),
Parent = Sidebar
})
New("UIListLayout", {
Padding = UDim.new(0, 5),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = NavList
})
local HwidBox = New("Frame", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 1, -68),
Size = UDim2.new(1, -12, 0, 62),
Parent = Sidebar
})
Corner(HwidBox, 8)
Stroke(HwidBox, "Accent", 1, 0.78)
BindTheme(HwidBox, "BackgroundColor3", "BgInput")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 7, 0, 4),
Size = UDim2.new(1, -14, 0, 12),
Font = Enum.Font.GothamBold,
Text = "MÃ MÁY (HWID):",
TextColor3 = THEME.TextMuted,
TextSize = 9,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = HwidBox
})
local HwidTextLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 7, 0, 16),
Size = UDim2.new(1, -14, 0, 15),
Font = Enum.Font.Code,
Text = DEVICE_HWID,
TextColor3 = THEME.Accent,
TextSize = 10,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = HwidBox
})
BindTheme(HwidTextLbl, "TextColor3", "Accent")
local CopyHwidBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 6, 0, 34),
Size = UDim2.new(1, -12, 0, 22),
Font = Enum.Font.GothamBold,
Text = "📋 Copy Mã HWID",
TextColor3 = THEME.TextMain,
TextSize = 10,
AutoButtonColor = false,
Parent = HwidBox
})
Corner(CopyHwidBtn, 6)
BindTheme(CopyHwidBtn, "BackgroundColor3", "BgElevated")
BindTheme(CopyHwidBtn, "TextColor3", "TextMain")
CopyHwidBtn.MouseButton1Click:Connect(function()
if copyClipboard(DEVICE_HWID) then
showToast("Đã copy Mã Máy (HWID): " .. DEVICE_HWID, false)
else
showToast("HWID: " .. DEVICE_HWID, false)
end
end)
-- VÙNG NỘI DUNG BÊN PHẢI
local ContentArea = New("Frame", {
BackgroundColor3 = THEME.BgCard,
Position = UDim2.new(0, 156, 0, 50),
Size = UDim2.new(1, -164, 1, -58),
ClipsDescendants = true,
Parent = MainWindow
})
Corner(ContentArea, 11)
Stroke(ContentArea, "Accent", 1, 0.8)
BindTheme(ContentArea, "BackgroundColor3", "BgCard")
local TabButtons = {}
local TabPages = {}
local function switchTab(tabId)
playUiSound(false)
for id, page in pairs(TabPages) do
page.Visible = (id == tabId)
end
for id, btn in pairs(TabButtons) do
local isAct = (id == tabId)
TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
BackgroundColor3 = isAct and THEME.BgInput or THEME.BgElevated,
TextColor3 = isAct and THEME.Accent or THEME.TextSub
}):Play()
end
end
local function createTab(tabId, title, order)
local btn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
LayoutOrder = order,
Size = UDim2.new(1, 0, 0, 34),
Font = Enum.Font.GothamBold,
Text = "  " .. title,
TextColor3 = THEME.TextSub,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
AutoButtonColor = false,
Parent = NavList
})
Corner(btn, 8)
local page = New("ScrollingFrame", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 10),
Size = UDim2.new(1, -20, 1, -20),
CanvasSize = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize = Enum.AutomaticSize.Y,
ScrollBarThickness = 3,
ScrollBarImageColor3 = THEME.Accent,
Visible = false,
Parent = ContentArea
})
New("UIListLayout", {
Padding = UDim.new(0, 7),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = page
})
btn.MouseButton1Click:Connect(function() switchTab(tabId) end)
TabButtons[tabId] = btn
TabPages[tabId] = page
return page
end
createTab("auth", "🔑 Kích Hoạt Key", 1)
createTab("shop", "🛒 Bảng Giá Key", 2)
createTab("vault", "🛡️ Kho Key & Đổi Máy", 3)
createTab("support", "🎫 Đơn & Hỗ Trợ", 4)
createTab("utils", "⚙️ Tiện Ích & Theme", 5)
-- ==============================================================================
-- 6. TAB 1: KÍCH HOẠT KEY, CHỌN GAME, TỰ LẤY KEY THEO HWID & ĐỔI GIFTCODE
-- ==============================================================================
local NoticeBanner = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 26),
Parent = TabPages.auth
})
Corner(NoticeBanner, 8)
BindTheme(NoticeBanner, "BackgroundColor3", "BgElevated")
local NoticeLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamBold,
Text = "📢 " .. State.admin_notice,
TextColor3 = THEME.TextSub,
TextSize = 10.5,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = NoticeBanner
})
BindTheme(NoticeLbl, "TextColor3", "TextSub")
local GameSelectorRow = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 32),
Parent = TabPages.auth
})
Corner(GameSelectorRow, 8)
BindTheme(GameSelectorRow, "BackgroundColor3", "BgElevated")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(0, 120, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🎮 CHẾ ĐỘ GAME:",
TextColor3 = THEME.TextSub,
TextSize = 10,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = GameSelectorRow
})
local GameModeBtn = New("TextButton", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 125, 0, 4),
Size = UDim2.new(1, -133, 0, 24),
Font = Enum.Font.GothamBold,
Text = "🥚 Steal An Egg V45 (Bấm để đổi Game)",
TextColor3 = THEME.Accent,
TextSize = 10.5,
AutoButtonColor = false,
Parent = GameSelectorRow
})
Corner(GameModeBtn, 6)
BindTheme(GameModeBtn, "BackgroundColor3", "BgInput")
BindTheme(GameModeBtn, "TextColor3", "Accent")
local function refreshGameModeLabel()
for _, gm in ipairs(GAME_MODES) do
if gm.id == State.config.selected_game then
GameModeBtn.Text = gm.name .. " (Bấm để đổi)"
return
end
end
GameModeBtn.Text = "🥚 Steal An Egg V45 (Bấm để đổi)"
end
refreshGameModeLabel()
GameModeBtn.MouseButton1Click:Connect(function()
local currIdx = 1
for idx, gm in ipairs(GAME_MODES) do
if gm.id == State.config.selected_game then
currIdx = idx
break
end
end
local nextIdx = (currIdx % #GAME_MODES) + 1
State.config.selected_game = GAME_MODES[nextIdx].id
saveConfig(State.config)
refreshGameModeLabel()
showToast("Đã chọn chế độ: " .. GAME_MODES[nextIdx].name, false)
end)
local KeyCard = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 62),
Parent = TabPages.auth
})
Corner(KeyCard, 10)
BindTheme(KeyCard, "BackgroundColor3", "BgElevated")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 14),
Font = Enum.Font.GothamBold,
Text = "NHẬP MÃ KEY BẢN QUYỀN (RB-XXXX-XXXX / FREE-XXXX):",
TextColor3 = THEME.TextSub,
TextSize = 10,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = KeyCard
})
local KeyInput = New("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 10, 0, 22),
Size = UDim2.new(1, -158, 0, 32),
Font = Enum.Font.Code,
PlaceholderText = "Dán Mã Key hoặc bấm 'Tự Lấy Key Theo HWID'...",
PlaceholderColor3 = THEME.TextMuted,
Text = State.config.saved_key or "",
TextColor3 = THEME.Accent,
TextSize = 12.5,
ClearTextOnFocus = false,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = KeyCard
})
Corner(KeyInput, 7)
BindTheme(KeyInput, "BackgroundColor3", "BgInput")
BindTheme(KeyInput, "TextColor3", "Accent")
local HideKeyBtn = New("TextButton", {
BackgroundColor3 = THEME.BgCard,
Position = UDim2.new(1, -142, 0, 22),
Size = UDim2.new(0, 32, 0, 32),
Font = Enum.Font.GothamBold,
Text = "👁️",
TextColor3 = THEME.TextMain,
TextSize = 12,
AutoButtonColor = false,
Parent = KeyCard
})
Corner(HideKeyBtn, 7)
BindTheme(HideKeyBtn, "BackgroundColor3", "BgCard")
local PasteKeyBtn = New("TextButton", {
BackgroundColor3 = THEME.BgCard,
Position = UDim2.new(1, -104, 0, 22),
Size = UDim2.new(0, 58, 0, 32),
Font = Enum.Font.GothamBold,
Text = "📋 Dán",
TextColor3 = THEME.Accent,
TextSize = 11,
AutoButtonColor = false,
Parent = KeyCard
})
Corner(PasteKeyBtn, 7)
BindTheme(PasteKeyBtn, "BackgroundColor3", "BgCard")
BindTheme(PasteKeyBtn, "TextColor3", "Accent")
local ClearKeyBtn = New("TextButton", {
BackgroundColor3 = Color3.fromRGB(58, 16, 28),
Position = UDim2.new(1, -40, 0, 22),
Size = UDim2.new(0, 30, 0, 32),
Font = Enum.Font.GothamBold,
Text = "✕",
TextColor3 = THEME.Err,
TextSize = 11,
AutoButtonColor = false,
Parent = KeyCard
})
Corner(ClearKeyBtn, 7)
HideKeyBtn.MouseButton1Click:Connect(function()
State.config.hide_key = not State.config.hide_key
saveConfig(State.config)
KeyInput.Text = State.config.hide_key and maskKey(State.config.saved_key) or (State.config.saved_key or "")
HideKeyBtn.Text = State.config.hide_key and "🙈" or "👁️"
end)
KeyInput.Focused:Connect(function()
if State.config.hide_key then KeyInput.Text = State.config.saved_key or "" end
end)
KeyInput.FocusLost:Connect(function()
if not string.find(KeyInput.Text, "•", 1, true) then
State.config.saved_key = cleanKey(KeyInput.Text)
saveConfig(State.config)
end
KeyInput.Text = State.config.hide_key and maskKey(State.config.saved_key) or (State.config.saved_key or "")
end)
PasteKeyBtn.MouseButton1Click:Connect(function()
local clip = cleanKey(readClipboard())
if #clip >= 4 then
State.config.saved_key = clip
saveConfig(State.config)
KeyInput.Text = State.config.hide_key and maskKey(clip) or clip
showToast("Đã dán Key: " .. clip, false)
else
KeyInput:CaptureFocus()
showToast("Nhấn giữ vào ô Key để dán!", false)
end
end)
ClearKeyBtn.MouseButton1Click:Connect(function()
State.config.saved_key = ""
saveConfig(State.config)
KeyInput.Text = ""
showToast("Đã xoá ô nhập Key!", false)
end)
local AuthBtnRow = New("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 36),
Parent = TabPages.auth
})
local ActivateBtn = New("TextButton", {
BackgroundColor3 = THEME.Primary,
Size = UDim2.new(0.53, -4, 1, 0),
Font = Enum.Font.GothamBold,
Text = "⚡ KÍCH HOẠT & MỞ MENU VIP",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 12,
AutoButtonColor = false,
Parent = AuthBtnRow
})
Corner(ActivateBtn, 9)
BindTheme(ActivateBtn, "BackgroundColor3", "Primary")
local AutoFetchBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.53, 4, 0, 0),
Size = UDim2.new(0.47, -4, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🔍 Tự Lấy Key Theo HWID",
TextColor3 = THEME.Accent,
TextSize = 11.5,
AutoButtonColor = false,
Parent = AuthBtnRow
})
Corner(AutoFetchBtn, 9)
Stroke(AutoFetchBtn, "Accent", 1, 0.5)
BindTheme(AutoFetchBtn, "BackgroundColor3", "BgElevated")
BindTheme(AutoFetchBtn, "TextColor3", "Accent")
local GiftRow = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 34),
Parent = TabPages.auth
})
Corner(GiftRow, 9)
BindTheme(GiftRow, "BackgroundColor3", "BgElevated")
local GiftInput = New("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 0, 3),
Size = UDim2.new(1, -124, 0, 28),
Font = Enum.Font.Code,
PlaceholderText = "🎁 Nhập Mã Giftcode sự kiện nhận Key...",
PlaceholderColor3 = THEME.TextMuted,
Text = "",
TextColor3 = THEME.TextMain,
TextSize = 11.5,
ClearTextOnFocus = false,
Parent = GiftRow
})
Corner(GiftInput, 7)
BindTheme(GiftInput, "BackgroundColor3", "BgInput")
BindTheme(GiftInput, "TextColor3", "TextMain")
local RedeemGiftBtn = New("TextButton", {
BackgroundColor3 = THEME.Purple,
Position = UDim2.new(1, -112, 0, 3),
Size = UDim2.new(0, 106, 0, 28),
Font = Enum.Font.GothamBold,
Text = "🎁 Đổi Key",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11,
AutoButtonColor = false,
Parent = GiftRow
})
Corner(RedeemGiftBtn, 7)
BindTheme(RedeemGiftBtn, "BackgroundColor3", "Purple")
local StatusCard = New("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 58),
Parent = TabPages.auth
})
Corner(StatusCard, 10)
Stroke(StatusCard, "Accent", 1, 0.72)
BindTheme(StatusCard, "BackgroundColor3", "BgInput")
local StatusTitleLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 16),
Font = Enum.Font.GothamBold,
Text = "💡 Trạng thái: Đang đồng bộ dữ liệu từ Server V45...",
TextColor3 = THEME.TextSub,
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = StatusCard
})
local StatusDetailLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 23),
Size = UDim2.new(1, -20, 0, 30),
Font = Enum.Font.GothamMedium,
Text = "📦 Gói: Chưa kích hoạt | ⏳ Hạn: -- | 💻 HWID: " .. DEVICE_HWID,
TextColor3 = THEME.TextMuted,
TextSize = 10.5,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = StatusCard
})
BindTheme(StatusDetailLbl, "TextColor3", "TextMuted")
local function setStatus(msg, col)
StatusTitleLbl.Text = tostring(msg)
StatusTitleLbl.TextColor3 = col or THEME.TextSub
end
local function refreshStatusCard()
local m = State.key_meta
local rem = m.time_left
if m.expire_ts and m.expire_ts > os.time() then
rem = formatRemain(m.expire_ts - os.time())
end
StatusDetailLbl.Text = string.format(
"📦 Gói: %s | ⏳ Còn: %s\n💻 Thiết bị: %s (%d/%d máy)",
tostring(m.package or "VIP"),
tostring(rem or "--"),
tostring(m.bound_hwid or DEVICE_HWID),
tonumber(m.device_count or 0),
tonumber(m.max_devices or 1)
)
if State.minimized and m.valid then
FloatingOrb.Text = "⚡ BIVA • " .. tostring(rem or "VIP")
else
FloatingOrb.Text = "⚡ BIVA V45"
end
end
-- ==============================================================================
-- 7. TAB 2: BẢNG GIÁ 4 GÓI CHỦ LỰC + CHÚ THÍCH BẢO HÀNH
-- ==============================================================================
local FlashSaleBar = New("Frame", {
BackgroundColor3 = Color3.fromRGB(48, 22, 16),
Size = UDim2.new(1, 0, 0, 28),
Visible = false,
Parent = TabPages.shop
})
Corner(FlashSaleBar, 8)
New("UIStroke", { Color = Color3.fromRGB(245, 158, 11), Thickness = 1, Parent = FlashSaleBar })
local FlashSaleLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamBold,
Text = "🔥 FLASH SALE TOÀN SERVER!",
TextColor3 = Color3.fromRGB(251, 191, 36),
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = FlashSaleBar
})
local PlansGrid = New("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 148),
Parent = TabPages.shop
})
New("UIGridLayout", {
CellPadding = UDim2.new(0, 8, 0, 8),
CellSize = UDim2.new(0.5, -4, 0, 70),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = PlansGrid
})
local CorePlans = {
{ pkg = "Free", title = "🎁 Dùng Thử (20 Giờ)", price = "Miễn Phí = Vượt Link", base = 0, sub = "Vượt link rút gọn • Khóa 1 HWID", isFree = true },
{ pkg = "1 Ngày", title = "⚡ Gói 1 Ngày (24 Giờ)", price = "8.000đ = 1 Ngày", base = 8000, sub = "Quét QR duyệt 3s • Vào thẳng", isFree = false },
{ pkg = "1 Tuần", title = "🔥 Gói 1 Tuần (7 Ngày)", price = "40.000đ = 1 Tuần", base = 40000, sub = "Tiết kiệm 16.000đ • Tự đổi máy", isFree = false },
{ pkg = "1 Tháng", title = "💎 Gói 1 Tháng (30 Ngày)", price = "130.000đ = 1 Tháng", base = 130000, sub = "Tiết kiệm 110.000đ • VIP Tối Thượng", isFree = false }
}
local PlanPriceLabels = {}
local function refreshPlanPrices()
local fsDisc = State.flash_sale.active and (tonumber(State.flash_sale.discount_percent) or 0) or 0
local disc = math.max(fsDisc, tonumber(State.voucher_discount) or 0)
for _, item in ipairs(PlanPriceLabels) do
if item.base > 0 then
local baseVal = tonumber(State.package_prices[item.pkg]) or item.base
local finalP = disc > 0 and math.max(2000, math.floor(baseVal * (100 - disc) / 100)) or baseVal
item.lbl.Text = formatVND(finalP) .. " = " .. item.pkg
end
end
end
local FootnoteBox = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 48),
Parent = TabPages.shop
})
Corner(FootnoteBox, 9)
Stroke(FootnoteBox, "Accent", 1, 0.78)
BindTheme(FootnoteBox, "BackgroundColor3", "BgElevated")
local FootnoteLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 4),
Size = UDim2.new(1, -20, 1, -8),
Font = Enum.Font.GothamMedium,
Text = State.pricing_footnote,
TextColor3 = THEME.TextSub,
TextSize = 9.5,
TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = FootnoteBox
})
BindTheme(FootnoteLbl, "TextColor3", "TextSub")
local ShopOrderBox = New("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 68),
Parent = TabPages.shop
})
Corner(ShopOrderBox, 9)
Stroke(ShopOrderBox, "Accent", 1, 0.7)
BindTheme(ShopOrderBox, "BackgroundColor3", "BgInput")
local ShopOrderTitle = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 16),
Font = Enum.Font.GothamBold,
Text = "🧾 Chọn gói bên trên để nhận link vượt hoặc tạo mã QR tự động",
TextColor3 = THEME.Accent,
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = ShopOrderBox
})
BindTheme(ShopOrderTitle, "TextColor3", "Accent")
local ShopOrderSub = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 21),
Size = UDim2.new(1, -20, 0, 15),
Font = Enum.Font.GothamMedium,
Text = "Sau khi quét QR trên trình duyệt, Game sẽ tự động nhận Key sau 3 giây!",
TextColor3 = THEME.TextSub,
TextSize = 10,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = ShopOrderBox
})
BindTheme(ShopOrderSub, "TextColor3", "TextSub")
local CheckPaidBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 10, 0, 39),
Size = UDim2.new(0.48, -12, 0, 24),
Font = Enum.Font.GothamBold,
Text = "🔄 Kiểm Tra Đã Chuyển Khoản",
TextColor3 = THEME.Accent,
TextSize = 10.5,
AutoButtonColor = false,
Parent = ShopOrderBox
})
Corner(CheckPaidBtn, 6)
BindTheme(CheckPaidBtn, "BackgroundColor3", "BgElevated")
BindTheme(CheckPaidBtn, "TextColor3", "Accent")
local CopyShopLinkBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0.52, 2, 0, 39),
Size = UDim2.new(0.48, -12, 0, 24),
Font = Enum.Font.GothamBold,
Text = "🌐 Copy Link Web Shop Kèm HWID",
TextColor3 = THEME.TextMain,
TextSize = 10.5,
AutoButtonColor = false,
Parent = ShopOrderBox
})
Corner(CopyShopLinkBtn, 6)
BindTheme(CopyShopLinkBtn, "BackgroundColor3", "BgElevated")
BindTheme(CopyShopLinkBtn, "TextColor3", "TextMain")
CopyShopLinkBtn.MouseButton1Click:Connect(function()
local link = WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID)
copyClipboard(link)
showToast("Đã copy Link Web Shop kèm sẵn HWID!", false)
end)
-- ==============================================================================
-- 8. TAB 3: KHO KEY, GÁN HWID & ĐỔI MÁY (RESET HWID)
-- ==============================================================================
local BindFreeRow = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 36),
Parent = TabPages.vault
})
Corner(BindFreeRow, 9)
BindTheme(BindFreeRow, "BackgroundColor3", "BgElevated")
local BindFreeInput = New("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 6, 0, 4),
Size = UDim2.new(1, -130, 0, 28),
Font = Enum.Font.Code,
PlaceholderText = "Nhập Key Tự Do / Key Clan để gắn vào máy này...",
PlaceholderColor3 = THEME.TextMuted,
Text = "",
TextColor3 = THEME.TextMain,
TextSize = 11.5,
ClearTextOnFocus = false,
Parent = BindFreeRow
})
Corner(BindFreeInput, 7)
BindTheme(BindFreeInput, "BackgroundColor3", "BgInput")
BindTheme(BindFreeInput, "TextColor3", "TextMain")
local BindFreeBtn = New("TextButton", {
BackgroundColor3 = THEME.Primary,
Position = UDim2.new(1, -118, 0, 4),
Size = UDim2.new(0, 112, 0, 28),
Font = Enum.Font.GothamBold,
Text = "🔗 Gán HWID Này",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11,
AutoButtonColor = false,
Parent = BindFreeRow
})
Corner(BindFreeBtn, 7)
BindTheme(BindFreeBtn, "BackgroundColor3", "Primary")
local VaultList = New("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 180),
AutomaticSize = Enum.AutomaticSize.Y,
Parent = TabPages.vault
})
New("UIListLayout", {
Padding = UDim.new(0, 6),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = VaultList
})
local ResetModal = New("Frame", {
BackgroundColor3 = Color3.fromRGB(4, 8, 18),
BackgroundTransparency = 0.25,
Size = UDim2.new(1, 0, 1, 0),
Visible = false,
ZIndex = 80,
Parent = MainWindow
})
local ResetCard = New("Frame", {
BackgroundColor3 = THEME.BgCard,
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 0),
Size = UDim2.new(0, 320, 0, 150),
ZIndex = 81,
Parent = ResetModal
})
Corner(ResetCard, 12)
Stroke(ResetCard, "Accent", 1.4, 0.2)
BindTheme(ResetCard, "BackgroundColor3", "BgCard")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 12, 0, 10),
Size = UDim2.new(1, -24, 0, 20),
Font = Enum.Font.GothamBold,
Text = "🔓 Xác Nhận Đổi Thiết Bị (Reset HWID)",
TextColor3 = THEME.Accent,
TextSize = 13,
ZIndex = 82,
Parent = ResetCard
})
local ResetDescLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 12, 0, 34),
Size = UDim2.new(1, -24, 0, 60),
Font = Enum.Font.GothamMedium,
Text = "Gỡ khóa thiết bị hiện tại cho Key này?",
TextColor3 = THEME.TextSub,
TextSize = 11,
TextWrapped = true,
ZIndex = 82,
Parent = ResetCard
})
local ResetCancelBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(0, 12, 1, -40),
Size = UDim2.new(0.46, 0, 0, 30),
Font = Enum.Font.GothamBold,
Text = "Huỷ",
TextColor3 = THEME.TextSub,
TextSize = 11.5,
AutoButtonColor = false,
ZIndex = 82,
Parent = ResetCard
})
Corner(ResetCancelBtn, 7)
local ResetConfirmBtn = New("TextButton", {
BackgroundColor3 = THEME.Primary,
Position = UDim2.new(0.54, -12, 1, -40),
Size = UDim2.new(0.46, 0, 0, 30),
Font = Enum.Font.GothamBold,
Text = "✓ Gỡ Khóa Ngay",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11.5,
AutoButtonColor = false,
ZIndex = 82,
Parent = ResetCard
})
Corner(ResetConfirmBtn, 7)
local targetResetKey = ""
ResetCancelBtn.MouseButton1Click:Connect(function()
ResetModal.Visible = false
end)
-- ==============================================================================
-- 9. TAB 4: ĐƠN HÀNG & GỬI PHIẾU HỖ TRỢ TỚI ADMIN
-- ==============================================================================
local TicketCard = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 68),
Parent = TabPages.support
})
Corner(TicketCard, 9)
BindTheme(TicketCard, "BackgroundColor3", "BgElevated")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 14),
Font = Enum.Font.GothamBold,
Text = "🎫 GỬI YÊU CẦU HỖ TRỢ / XIN MỞ KHÓA ĐỔI MÁY TỚI ADMIN:",
TextColor3 = THEME.Accent,
TextSize = 10,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = TicketCard
})
local TicketInput = New("TextBox", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 8, 0, 23),
Size = UDim2.new(1, -124, 0, 36),
Font = Enum.Font.GothamMedium,
PlaceholderText = "Nhập nội dung cần Admin hỗ trợ (VD: Nhờ Admin Reset HWID giúp mình)...",
PlaceholderColor3 = THEME.TextMuted,
Text = "",
TextColor3 = THEME.TextMain,
TextSize = 11,
ClearTextOnFocus = false,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = TicketCard
})
Corner(TicketInput, 7)
BindTheme(TicketInput, "BackgroundColor3", "BgInput")
BindTheme(TicketInput, "TextColor3", "TextMain")
local SendTicketBtn = New("TextButton", {
BackgroundColor3 = THEME.Primary,
Position = UDim2.new(1, -110, 0, 23),
Size = UDim2.new(0, 102, 0, 36),
Font = Enum.Font.GothamBold,
Text = "📨 Gửi Admin",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11,
AutoButtonColor = false,
Parent = TicketCard
})
Corner(SendTicketBtn, 7)
BindTheme(SendTicketBtn, "BackgroundColor3", "Primary")
local SupportList = New("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 160),
AutomaticSize = Enum.AutomaticSize.Y,
Parent = TabPages.support
})
New("UIListLayout", {
Padding = UDim.new(0, 6),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = SupportList
})
-- ==============================================================================
-- 10. TAB 5: TIỆN ÍCH VIP & ĐỔI CHỦ ĐỀ GIAO DIỆN
-- ==============================================================================
local ThemeBar = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
Size = UDim2.new(1, 0, 0, 44),
Parent = TabPages.utils
})
Corner(ThemeBar, 9)
BindTheme(ThemeBar, "BackgroundColor3", "BgElevated")
local ThemeGrid = New("Frame", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 7),
Size = UDim2.new(1, -16, 0, 30),
Parent = ThemeBar
})
New("UIGridLayout", {
CellPadding = UDim2.new(0, 6, 0, 6),
CellSize = UDim2.new(0.32, 0, 0, 30),
Parent = ThemeGrid
})
for _, tKey in ipairs({ "CyberBlue", "Emerald", "Amethyst" }) do
local tMeta = THEMES[tKey]
local tb = New("TextButton", {
BackgroundColor3 = tMeta.BgCard,
Font = Enum.Font.GothamBold,
Text = "🎨 " .. tMeta.Name,
TextColor3 = tMeta.Accent,
TextSize = 11,
AutoButtonColor = false,
Parent = ThemeGrid
})
Corner(tb, 7)
New("UIStroke", { Color = tMeta.Accent, Thickness = 1, Transparency = 0.4, Parent = tb })
tb.MouseButton1Click:Connect(function()
SetTheme(tKey)
showToast("Đã đổi chủ đề: " .. tMeta.Name, false)
end)
end
local UtilsGrid = New("Frame", {
BackgroundTransparency = 1,
Size = UDim2.new(1, 0, 0, 190),
Parent = TabPages.utils
})
New("UIGridLayout", {
CellPadding = UDim2.new(0, 8, 0, 8),
CellSize = UDim2.new(0.5, -4, 0, 38),
SortOrder = Enum.SortOrder.LayoutOrder,
Parent = UtilsGrid
})
local function addUtilBtn(label, fn)
local b = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Font = Enum.Font.GothamBold,
Text = label,
TextColor3 = THEME.TextMain,
TextSize = 11,
AutoButtonColor = false,
Parent = UtilsGrid
})
Corner(b, 8)
BindTheme(b, "BackgroundColor3", "BgElevated")
BindTheme(b, "TextColor3", "TextMain")
b.MouseButton1Click:Connect(function() fn(b) end)
end
addUtilBtn("⚡ Tự Đăng Nhập: " .. (State.config.auto_login and "BẬT" or "TẮT"), function(b)
State.config.auto_login = not State.config.auto_login
saveConfig(State.config)
b.Text = "⚡ Tự Đăng Nhập: " .. (State.config.auto_login and "BẬT" or "TẮT")
showToast("Đã cập nhật Tự Đăng Nhập!", false)
end)
addUtilBtn("🛡️ Chống Treo (Anti-AFK): " .. (State.config.anti_afk and "BẬT" or "TẮT"), function(b)
State.config.anti_afk = not State.config.anti_afk
saveConfig(State.config)
b.Text = "🛡️ Chống Treo (Anti-AFK): " .. (State.config.anti_afk and "BẬT" or "TẮT")
showToast("Đã cập nhật Anti-AFK!", false)
end)
addUtilBtn("🔊 Âm Thanh Menu: " .. (State.config.sound_fx and "BẬT" or "TẮT"), function(b)
State.config.sound_fx = not State.config.sound_fx
saveConfig(State.config)
b.Text = "🔊 Âm Thanh Menu: " .. (State.config.sound_fx and "BẬT" or "TẮT")
showToast("Đã cập nhật âm thanh Menu!", false)
end)
addUtilBtn("🚀 Tối Ưu FPS Giảm Lag", function()
pcall(function()
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in ipairs(workspace:GetDescendants()) do
if v:IsA("BasePart") then
v.Material = Enum.Material.SmoothPlastic
v.Reflectance = 0
end
end
end)
showToast("🚀 Đã tối ưu FPS mượt mà!", false)
end)
addUtilBtn("🌐 Đổi Server Vắng (Hop)", function()
showToast("🌐 Đang tìm Server vắng người & Ping thấp...", false)
task.spawn(function()
local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
local ok, _, body = rawHttp(url, "GET")
if ok and body then
local decOk, data = pcall(function() return HttpService:JSONDecode(body) end)
if decOk and data and type(data.data) == "table" then
for _, srv in ipairs(data.data) do
if type(srv) == "table" and tonumber(srv.playing) and tonumber(srv.maxPlayers) then
if srv.playing >= 1 and srv.playing < (srv.maxPlayers - 2) and srv.id ~= game.JobId then
TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
return
end
end
end
end
end
TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
end)
addUtilBtn("🔄 Vào Lại Server (Rejoin)", function()
showToast("Đang kết nối lại Server...", false)
TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
addUtilBtn("📋 Copy Script Kèm Sẵn Key", function()
local k = cleanKey(State.config.saved_key)
if k == "" then
showToast("Chưa có Mã Key nào được lưu!", true)
return
end
local s = string.format('getgenv().BIVA_AUTO_KEY = "%s"; loadstring(game:HttpGet("%s"))()', k, LOADER_RAW_URL)
copyClipboard(s)
showToast("⚡ Đã copy Script kèm sẵn Key!", false)
end)
addUtilBtn("🌐 Copy Link Web Shop", function()
local link = WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID)
copyClipboard(link)
showToast("🌐 Đã copy Link Web Shop kèm sẵn HWID!", false)
end)
-- ==============================================================================
-- 11. HÀM ĐỒNG BỘ DỮ LIỆU, NẠP SCRIPT & XỬ LÝ SỰ KIỆN
-- ==============================================================================
local renderVaultUI
local renderSupportUI
local verifyAndRunScript
local function sendTelemetry(keyCode)
task.spawn(function()
apiCall("/api/telemetry", "POST", {
key = keyCode,
hwid = DEVICE_HWID,
game_id = State.config.selected_game or "steal_egg",
executor = EXECUTOR_NAME,
player_name = tostring(LocalPlayer.Name or "Player"),
place_id = tonumber(game.PlaceId) or 0,
job_id = tostring(game.JobId or "")
})
end)
end
renderVaultUI = function()
for _, ch in ipairs(VaultList:GetChildren()) do
if ch:IsA("Frame") then ch:Destroy() end
end
local items = {}
local seen = {}
for _, k in ipairs(State.keys or {}) do
local c = cleanKey(k.key_code or k.key)
if c ~= "" and not seen[c] then
seen[c] = true
table.insert(items, k)
end
end
for _, loc in ipairs(loadVault()) do
local c = cleanKey(loc.key)
if c ~= "" and not seen[c] then
seen[c] = true
table.insert(items, {
key_code = c,
package = loc.package or "Đã lưu",
time_left = "Bấm Nạp để kiểm tra",
bound_hwid = DEVICE_HWID,
device_count = 1,
max_devices = 1
})
end
end
if #items == 0 then
local empty = New("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 48),
Parent = VaultList
})
Corner(empty, 8)
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamMedium,
Text = "Chưa có Key nào gắn với HWID [" .. DEVICE_HWID .. "]. Hãy chọn gói ở Tab Bảng Giá!",
TextColor3 = THEME.TextSub,
TextSize = 11,
TextWrapped = true,
Parent = empty
})
return
end
for idx, item in ipairs(items) do
local code = cleanKey(item.key_code or item.key)
local pkg = tostring(item.package or "VIP")
local left = tostring(item.time_left or "Còn hạn")
local devCnt = tonumber(item.device_count) or 1
local maxDev = math.max(1, tonumber(item.max_devices) or 1)
local row = New("Frame", {
BackgroundColor3 = THEME.BgInput,
LayoutOrder = idx,
Size = UDim2.new(1, 0, 0, 52),
Parent = VaultList
})
Corner(row, 8)
BindTheme(row, "BackgroundColor3", "BgInput")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(0.55, 0, 0, 18),
Font = Enum.Font.Code,
Text = code,
TextColor3 = THEME.Accent,
TextSize = 12.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = row
})
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 24),
Size = UDim2.new(0.55, 0, 0, 22),
Font = Enum.Font.GothamMedium,
Text = string.format("Gói: %s • ⏳ %s (%d/%d máy)", pkg, left, devCnt, maxDev),
TextColor3 = THEME.TextSub,
TextSize = 10,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = row
})
local useBtn = New("TextButton", {
BackgroundColor3 = THEME.Primary,
Position = UDim2.new(1, -172, 0.5, -13),
Size = UDim2.new(0, 54, 0, 26),
Font = Enum.Font.GothamBold,
Text = "⚡ Nạp",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 10.5,
AutoButtonColor = false,
Parent = row
})
Corner(useBtn, 6)
local cpBtn = New("TextButton", {
BackgroundColor3 = THEME.BgElevated,
Position = UDim2.new(1, -112, 0.5, -13),
Size = UDim2.new(0, 44, 0, 26),
Font = Enum.Font.GothamBold,
Text = "📋",
TextColor3 = THEME.TextMain,
TextSize = 11,
AutoButtonColor = false,
Parent = row
})
Corner(cpBtn, 6)
local rstBtn = New("TextButton", {
BackgroundColor3 = Color3.fromRGB(58, 38, 12),
Position = UDim2.new(1, -62, 0.5, -13),
Size = UDim2.new(0, 54, 0, 26),
Font = Enum.Font.GothamBold,
Text = "🔓 Đổi",
TextColor3 = THEME.Warn,
TextSize = 10.5,
AutoButtonColor = false,
Parent = row
})
Corner(rstBtn, 6)
useBtn.MouseButton1Click:Connect(function()
State.config.saved_key = code
saveConfig(State.config)
KeyInput.Text = State.config.hide_key and maskKey(code) or code
switchTab("auth")
verifyAndRunScript(code)
end)
cpBtn.MouseButton1Click:Connect(function()
copyClipboard(code)
showToast("Đã copy Key: " .. code, false)
end)
rstBtn.MouseButton1Click:Connect(function()
targetResetKey = code
ResetDescLbl.Text = "Bạn muốn gỡ khóa thiết bị hiện tại cho Key [" .. code .. "] để chuyển sang máy mới?"
ResetModal.Visible = true
end)
end
end
renderSupportUI = function()
for _, ch in ipairs(SupportList:GetChildren()) do
if ch:IsA("Frame") then ch:Destroy() end
end
local orders = State.orders or {}
local tickets = State.tickets or {}
if #orders == 0 and #tickets == 0 then
local empty = New("Frame", {
BackgroundColor3 = THEME.BgInput,
Size = UDim2.new(1, 0, 0, 44),
Parent = SupportList
})
Corner(empty, 8)
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 0),
Size = UDim2.new(1, -20, 1, 0),
Font = Enum.Font.GothamMedium,
Text = "Chưa có đơn hàng hoặc phiếu hỗ trợ nào trên thiết bị này.",
TextColor3 = THEME.TextSub,
TextSize = 11,
Parent = empty
})
return
end
local orderIdx = 0
for _, t in ipairs(tickets) do
orderIdx = orderIdx + 1
local isDone = (tostring(t.status) == "resolved")
local row = New("Frame", {
BackgroundColor3 = THEME.BgInput,
LayoutOrder = orderIdx,
Size = UDim2.new(1, 0, 0, 48),
Parent = SupportList
})
Corner(row, 8)
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 4),
Size = UDim2.new(1, -20, 0, 16),
Font = Enum.Font.GothamBold,
Text = string.format("🎫 [%s] %s", tostring(t.ticket_id or "TK"), isDone and "✓ Đã xử lý" or "⏳ Đang chờ Admin"),
TextColor3 = isDone and THEME.Ok or THEME.Warn,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = row
})
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 22),
Size = UDim2.new(1, -20, 0, 20),
Font = Enum.Font.GothamMedium,
Text = tostring(t.admin_reply and t.admin_reply ~= "" and ("Admin: " .. t.admin_reply) or t.message or ""),
TextColor3 = THEME.TextSub,
TextSize = 10,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = row
})
end
for _, o in ipairs(orders) do
orderIdx = orderIdx + 1
local oid = tostring(o.order_id or "BIVA")
local pkg = tostring(o.package or "VIP")
local issued = cleanKey(o.key_code or o.key)
local isPaid = (tostring(o.status) == "paid")
local row = New("Frame", {
BackgroundColor3 = THEME.BgInput,
LayoutOrder = orderIdx,
Size = UDim2.new(1, 0, 0, 46),
Parent = SupportList
})
Corner(row, 8)
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(0.65, 0, 0, 16),
Font = Enum.Font.GothamBold,
Text = string.format("🧾 %s • %s (%s)", oid, pkg, formatVND(o.price or 0)),
TextColor3 = THEME.TextMain,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = row
})
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 23),
Size = UDim2.new(0.65, 0, 0, 16),
Font = Enum.Font.Code,
Text = isPaid and ("Key: " .. (issued ~= "" and issued or "Đã cấp")) or "⏳ Chờ thanh toán",
TextColor3 = isPaid and THEME.Accent or THEME.Warn,
TextSize = 10,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = row
})
end
end
local function runOmniSync(showToastMsg, autoRunIfValid)
task.spawn(function()
local saved = cleanKey(State.config.saved_key)
local path = string.format("/api/omni_sync?hwid=%s&key=%s&fresh=1", urlEncode(DEVICE_HWID), urlEncode(saved))
local data, _, ping = apiCall(path, "GET")
if not data or not data.success then
SubHeaderLbl.Text = "🟡 Server đang thức dậy... Vui lòng đợi vài giây"
if showToastMsg then showToast("Máy chủ đang khởi động, thử lại sau vài giây!", true) end
return
end
State.sync_rev = tonumber(data.sync_revision) or State.sync_rev
State.ping = ping
SubHeaderLbl.Text = string.format("🟢 %s • REV #%d • Ping: %dms", EXECUTOR_NAME, State.sync_rev, ping)
if data.admin_notice and tostring(data.admin_notice) ~= "" then
State.admin_notice = tostring(data.admin_notice)
NoticeLbl.Text = "📢 " .. State.admin_notice
end
if data.pricing_footnote and tostring(data.pricing_footnote) ~= "" then
State.pricing_footnote = tostring(data.pricing_footnote)
FootnoteLbl.Text = State.pricing_footnote
end
if data.package_prices and type(data.package_prices) == "table" then
for k, v in pairs(data.package_prices) do
State.package_prices[k] = tonumber(v) or State.package_prices[k]
end
refreshPlanPrices()
end
if data.flash_sale and type(data.flash_sale) == "table" then
State.flash_sale = data.flash_sale
FlashSaleBar.Visible = (State.flash_sale.active == true)
if State.flash_sale.active then
FlashSaleLbl.Text = string.format(
"🔥 %s (Còn %s)",
tostring(State.flash_sale.title or "FLASH SALE"),
tostring(State.flash_sale.remaining_text or "Đang diễn ra")
)
end
refreshPlanPrices()
end
State.keys = data.keys or {}
State.orders = data.orders or {}
State.tickets = data.support_tickets or {}
renderVaultUI()
renderSupportUI()
if data.best_key and type(data.best_key) == "table" then
local bk = data.best_key
local code = cleanKey(bk.key_code or bk.key)
if code ~= "" then
saveKeyToVault(code, bk.package)
State.config.saved_key = code
saveConfig(State.config)
KeyInput.Text = State.config.hide_key and maskKey(code) or code
State.key_meta = {
valid = true,
key_code = code,
package = tostring(bk.package or "VIP"),
bound_hwid = tostring(bk.bound_hwid or bk.hwid or DEVICE_HWID),
device_count = tonumber(bk.device_count) or 1,
max_devices = tonumber(bk.max_devices) or 1,
expire_ts = tonumber(bk.expire) or 0,
time_left = tostring(bk.time_left or "Còn hạn")
}
refreshStatusCard()
setStatus("✅ Đã nhận diện Key [" .. code .. "] (" .. State.key_meta.package .. ")", THEME.Accent)
if showToastMsg then showToast("🔑 Đã tìm thấy Key: " .. code, false) end
if autoRunIfValid and State.config.auto_login and not data.maintenance then
verifyAndRunScript(code)
end
return
end
end
if showToastMsg then
showToast("Chưa tìm thấy Key còn hạn cho HWID này!", true)
end
setStatus("💡 Nhập Key hoặc qua Tab Bảng Giá (Miễn Phí / 8K / 40K / 130K) để kích hoạt!", THEME.TextSub)
end)
end
verifyAndRunScript = function(rawKey)
if State.busy then return end
local k = cleanKey(rawKey)
if k == "" or string.find(tostring(rawKey or ""), "•", 1, true) then
k = cleanKey(State.config.saved_key)
end
if #k < 4 then
setStatus("⚠️ Vui lòng nhập Mã Key hợp lệ trước khi kích hoạt!", THEME.Err)
showToast("Vui lòng nhập Mã Key hợp lệ!", true)
return
end
State.busy = true
ActivateBtn.Text = "⏳ Đang xác thực Key..."
setStatus("⏳ Đang kiểm tra Key [" .. k .. "] trên Server V45...", THEME.Warn)
task.spawn(function()
local vPath = string.format("/api/verify_key?key=%s&hwid=%s&auto_bind=true", urlEncode(k), urlEncode(DEVICE_HWID))
local vData = apiCall(vPath, "GET")
if not vData then
State.busy = false
ActivateBtn.Text = "⚡ KÍCH HOẠT & MỞ MENU VIP"
setStatus("❌ Không thể kết nối Server, vui lòng thử lại!", THEME.Err)
showToast("Lỗi kết nối Server!", true)
return
end
if not vData.valid then
State.busy = false
ActivateBtn.Text = "⚡ KÍCH HOẠT & MỞ MENU VIP"
local msg = tostring(vData.detail or vData.message or "Key không hợp lệ hoặc đã hết hạn!")
setStatus("❌ " .. msg, THEME.Err)
showToast(msg, true)
if vData.hwid_match == false then switchTab("vault") end
return
end
local confirmed = cleanKey(vData.key_code or k)
State.config.saved_key = confirmed
saveConfig(State.config)
saveKeyToVault(confirmed, vData.package or "VIP")
KeyInput.Text = State.config.hide_key and maskKey(confirmed) or confirmed
State.key_meta = {
valid = true,
key_code = confirmed,
package = tostring(vData.package or "VIP"),
bound_hwid = tostring(vData.bound_hwid or DEVICE_HWID),
device_count = tonumber(vData.device_count) or 1,
max_devices = tonumber(vData.max_devices) or 1,
expire_ts = tonumber(vData.expire) or 0,
time_left = tostring(vData.time_left or "Còn hạn")
}
refreshStatusCard()
_G.BIVA_KEY = confirmed
_G.SEM_KEY = confirmed
_G.BIVA_HWID = DEVICE_HWID
_G.SEM_TIME = State.key_meta.time_left
_G.BIVA_TIER = tostring(vData.tier_label or State.key_meta.package)
_G.BIVA_ADMIN_MSG = State.admin_notice
_G.BIVA_EXPIRE = tostring(vData.expire_str or "Đang đồng bộ")
_G.BIVA_API_BASE = API_BASE
sendTelemetry(confirmed)
local gameId = State.config.selected_game or "steal_egg"
ActivateBtn.Text = "🚀 Đang nạp Script..."
local sPath = string.format("/api/get_script?key=%s&hwid=%s&game_id=%s", urlEncode(confirmed), urlEncode(DEVICE_HWID), urlEncode(gameId))
local luaCode = apiCall(sPath, "GET", nil, true)
State.busy = false
ActivateBtn.Text = "⚡ KÍCH HOẠT & MỞ MENU VIP"
if type(luaCode) == "string" and #luaCode > 20 then
local fn, err = loadstring(luaCode)
if type(fn) == "function" then
setStatus("✅ Đã kích hoạt Script V45 thành công!", THEME.Ok)
showToast("🎉 Đã mở khóa BIVA STORM V45 thành công!", false)
task.spawn(function() pcall(fn) end)
task.delay(0.7, function()
if MainWindow and MainWindow.Parent then
MainWindow.Visible = false
FloatingOrb.Visible = true
State.minimized = true
refreshStatusCard()
end
end)
else
setStatus("⚠️ Lỗi biên dịch Script: " .. tostring(err), THEME.Err)
end
else
setStatus("❌ Không tải được Script từ Server!", THEME.Err)
end
end)
end
local function watchInGameOrder(orderId, pkgName)
State.config.pending_order_id = orderId
State.config.pending_package = pkgName
saveConfig(State.config)
if State.watching_order then return end
State.watching_order = true
task.spawn(function()
for _ = 1, 100 do
task.wait(3)
local oid = State.config.pending_order_id
if not oid or oid == "" then break end
local res = apiCall("/api/check_order?order_id=" .. urlEncode(oid), "GET")
if res and res.status == "paid" and res.key then
local newK = cleanKey(res.key)
State.config.pending_order_id = ""
State.config.saved_key = newK
saveConfig(State.config)
saveKeyToVault(newK, pkgName)
KeyInput.Text = State.config.hide_key and maskKey(newK) or newK
ShopOrderTitle.Text = "🎉 ĐƠN " .. oid .. " ĐÃ THANH TOÁN! KEY: " .. newK
showToast("🎉 Đã nhận Key tự động: " .. newK, false)
switchTab("auth")
verifyAndRunScript(newK)
break
end
end
State.watching_order = false
end)
end
for idx, p in ipairs(CorePlans) do
local card = New("Frame", {
BackgroundColor3 = THEME.BgElevated,
LayoutOrder = idx,
Parent = PlansGrid
})
Corner(card, 9)
Stroke(card, p.isFree and "Accent" or "Primary", 1, 0.55)
BindTheme(card, "BackgroundColor3", "BgElevated")
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 4),
Size = UDim2.new(1, -16, 0, 14),
Font = Enum.Font.GothamBold,
Text = p.title,
TextColor3 = THEME.TextMain,
TextSize = 10.5,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = card
})
local pLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 18),
Size = UDim2.new(1, -16, 0, 17),
Font = Enum.Font.GothamBlack,
Text = p.price,
TextColor3 = THEME.Accent,
TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = card
})
BindTheme(pLbl, "TextColor3", "Accent")
table.insert(PlanPriceLabels, { lbl = pLbl, base = p.base, pkg = p.pkg })
New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 8, 0, 34),
Size = UDim2.new(0.62, 0, 0, 14),
Font = Enum.Font.GothamMedium,
Text = p.sub,
TextColor3 = THEME.TextSub,
TextSize = 9,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = card
})
local actionBtn = New("TextButton", {
BackgroundColor3 = p.isFree and THEME.BgInput or THEME.Primary,
Position = UDim2.new(1, -86, 1, -26),
Size = UDim2.new(0, 78, 0, 20),
Font = Enum.Font.GothamBold,
Text = p.isFree and "Vượt Link ➔" or "Mua Ngay ➔",
TextColor3 = p.isFree and THEME.Accent or Color3.fromRGB(255, 255, 255),
TextSize = 10,
AutoButtonColor = false,
Parent = card
})
Corner(actionBtn, 6)
actionBtn.MouseButton1Click:Connect(function()
if p.isFree then
ShopOrderTitle.Text = "⏳ Đang tạo link vượt nhận Key Miễn Phí (20 Giờ)..."
task.spawn(function()
local res = apiCall("/api/get_free_link?hwid=" .. urlEncode(DEVICE_HWID) .. "&game=rb", "POST", {
hwid = DEVICE_HWID,
game = "rb"
})
if res and res.success and res.link then
copyClipboard(res.link)
ShopOrderTitle.Text = "✅ Đã Copy Link Vượt Key Free 20 Giờ vào bộ nhớ tạm!"
ShopOrderSub.Text = "Hãy dán link vừa copy ra trình duyệt (Safari/Chrome) để nhận Key!"
showToast("📋 Đã copy Link Vượt Key Free!", false)
elseif res and res.existing_key then
local ex = cleanKey(res.existing_key)
State.config.saved_key = ex
saveConfig(State.config)
KeyInput.Text = ex
showToast("🔑 Máy đang có Key Free còn hạn: " .. ex, false)
switchTab("auth")
else
showToast((res and res.message) or "Không thể tạo link lúc này!", true)
end
end)
else
ShopOrderTitle.Text = "⏳ Đang khởi tạo mã QR cho gói [" .. p.pkg .. "]..."
task.spawn(function()
local path = string.format("/api/create_order?game=rb&package=%s&hwid=%s", urlEncode(p.pkg), urlEncode(DEVICE_HWID))
local res = apiCall(path, "POST", {
game = "rb",
package = p.pkg,
hwid = DEVICE_HWID
})
if res and res.success and res.order_id then
local payLink = (res.checkout_url and res.checkout_url ~= "") and res.checkout_url or (WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID))
copyClipboard(payLink)
ShopOrderTitle.Text = "✅ Đơn " .. tostring(res.order_id) .. " (" .. formatVND(res.price or p.base) .. ") — Đã Copy Link!"
ShopOrderSub.Text = "Dán link vừa copy ra trình duyệt để quét QR. Game sẽ tự kích hoạt sau 3 giây chuyển khoản!"
showToast("📋 Đã copy link thanh toán đơn " .. tostring(res.order_id) .. "!", false)
watchInGameOrder(res.order_id, p.pkg)
else
showToast((res and (res.detail or res.message)) or "Lỗi tạo đơn hàng!", true)
end
end)
end
end)
end
ActivateBtn.MouseButton1Click:Connect(function()
verifyAndRunScript(KeyInput.Text)
end)
AutoFetchBtn.MouseButton1Click:Connect(function()
runOmniSync(true, false)
end)
SyncTopBtn.MouseButton1Click:Connect(function()
runOmniSync(true, false)
end)
RedeemGiftBtn.MouseButton1Click:Connect(function()
local gCode = cleanKey(GiftInput.Text)
if #gCode < 2 then
showToast("Vui lòng nhập Mã Giftcode sự kiện!", true)
return
end
task.spawn(function()
local res = apiCall("/api/redeem_giftcode?code=" .. urlEncode(gCode) .. "&hwid=" .. urlEncode(DEVICE_HWID) .. "&game=rb", "POST", {
code = gCode,
hwid = DEVICE_HWID,
game = "rb"
})
if res and res.success and res.key then
local k = cleanKey(res.key)
GiftInput.Text = ""
State.config.saved_key = k
saveConfig(State.config)
KeyInput.Text = k
saveKeyToVault(k, res.package or "Giftcode")
showToast("🎉 Đổi Giftcode thành công! Key: " .. k, false)
runOmniSync(false, true)
else
showToast((res and (res.message or res.detail)) or "Mã Giftcode không hợp lệ!", true)
end
end)
end)
BindFreeBtn.MouseButton1Click:Connect(function()
local k = cleanKey(BindFreeInput.Text)
if #k < 4 then
showToast("Vui lòng nhập Mã Key cần gắn!", true)
return
end
task.spawn(function()
local res = apiCall("/api/verify_key?key=" .. urlEncode(k) .. "&hwid=" .. urlEncode(DEVICE_HWID) .. "&auto_bind=true", "GET")
if res and res.valid then
local ck = cleanKey(res.key_code or k)
BindFreeInput.Text = ""
State.config.saved_key = ck
saveConfig(State.config)
KeyInput.Text = ck
saveKeyToVault(ck, res.package or "VIP")
showToast("✅ Đã gắn HWID vào Key " .. ck .. "!", false)
runOmniSync(false, false)
else
showToast((res and (res.detail or res.message)) or "Không thể gắn Key này!", true)
end
end)
end)
ResetConfirmBtn.MouseButton1Click:Connect(function()
ResetModal.Visible = false
if targetResetKey == "" then return end
local k = targetResetKey
task.spawn(function()
local res = apiCall("/api/reset_hwid_by_key?key=" .. urlEncode(k), "POST", { key = k })
if res and res.success then
showToast("🔓 " .. tostring(res.message or "Đã gỡ khóa thiết bị thành công!"), false)
runOmniSync(false, false)
else
showToast((res and (res.message or res.detail)) or "Không thể đổi máy lúc này!", true)
end
end)
end)
SendTicketBtn.MouseButton1Click:Connect(function()
local msg = tostring(TicketInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
if #msg < 4 then
showToast("Vui lòng nhập nội dung cần hỗ trợ!", true)
return
end
SendTicketBtn.Text = "⏳..."
task.spawn(function()
local res = apiCall("/api/support_ticket", "POST", {
hwid = DEVICE_HWID,
key = State.config.saved_key or "",
topic = "Hỗ trợ In-Game / Mở khóa HWID",
message = msg
})
SendTicketBtn.Text = "📨 Gửi Admin"
if res and res.success then
TicketInput.Text = ""
showToast("🎫 Đã gửi phiếu hỗ trợ tới Admin!", false)
runOmniSync(false, false)
else
showToast((res and (res.message or res.detail)) or "Không thể gửi lúc này!", true)
end
end)
end)
CheckPaidBtn.MouseButton1Click:Connect(function()
local oid = State.config.pending_order_id
if not oid or oid == "" then
runOmniSync(true, false)
return
end
task.spawn(function()
local res = apiCall("/api/check_order?order_id=" .. urlEncode(oid), "GET")
if res and res.status == "paid" and res.key then
local k = cleanKey(res.key)
State.config.pending_order_id = ""
State.config.saved_key = k
saveConfig(State.config)
KeyInput.Text = k
showToast("🎉 Đơn đã thanh toán! Key: " .. k, false)
switchTab("auth")
verifyAndRunScript(k)
else
showToast("⏳ Đơn hàng vẫn đang chờ chuyển khoản!", false)
end
end)
end)
local function toggleMin()
State.minimized = not State.minimized
MainWindow.Visible = not State.minimized
FloatingOrb.Visible = State.minimized
refreshStatusCard()
end
MinBtn.MouseButton1Click:Connect(toggleMin)
FloatingOrb.MouseButton1Click:Connect(toggleMin)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
UserInputService.InputBegan:Connect(function(input, gp)
if not gp and input.KeyCode == Enum.KeyCode.RightShift then
toggleMin()
end
end)
LocalPlayer.Idled:Connect(function()
if State.config.anti_afk then
pcall(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
end)
-- Bộ đếm ngược thời gian thực mỗi giây & gửi Heartbeat định kỳ lên Radar Admin
task.spawn(function()
local hbCounter = 0
while ScreenGui and ScreenGui.Parent do
task.wait(1)
hbCounter = hbCounter + 1
if State.key_meta.valid and State.key_meta.expire_ts > 0 then
refreshStatusCard()
end
if hbCounter >= 45 and State.key_meta.valid and State.key_meta.key_code ~= "" then
hbCounter = 0
sendTelemetry(State.key_meta.key_code)
end
end
end)
switchTab("auth")
if State.config.pending_order_id and State.config.pending_order_id ~= "" then
watchInGameOrder(State.config.pending_order_id, State.config.pending_package or "VIP")
end
runOmniSync(false, true)
