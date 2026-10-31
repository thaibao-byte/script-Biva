-- ==============================================================================
-- BIVA STORM V50 SOVEREIGN | APEX OMEGA CORE LOADER & IN-GAME COMMAND CENTER
-- Kiến trúc sư trưởng: Lead Full-Stack & Luau Systems Architect (100% Pure Luau)
-- * Tự động co giãn tỷ lệ (Auto UIScale) chuẩn mọi màn hình Điện thoại & PC
-- * Chọn Tựa Game trực tiếp (Steal An Egg V50, Blox Fruits, Fisch, Dead Rails)
-- * Bảng Giá Chuẩn: Miễn Phí = Vượt Link (20h) | 8.000đ = 1 Ngày | 40.000đ = 1 Tuần | 130.000đ = 1 Tháng
-- * Đồng bộ trực tiếp với Server V50 Sovereign, tự truyền biến sang Script Game
-- ==============================================================================
-- ... existing code ...
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
-- ==============================================================================
-- 1. CẤU HÌNH KẾT NỐI & HẰNG SỐ HỆ THỐNG V50 SOVEREIGN
-- ==============================================================================
local API_BASE = "https://biva-hub.onrender.com"
local WEB_SHOP_URL = API_BASE .. "/index.html"
local LOADER_RAW_URL = "https://raw.githubusercontent.com/thaibao-byte/script-Biva/main/biva_storm.lua"
local SAVE_FILE_NAME = "BivaStorm_ApexOmega_Config_v50.json"
local VAULT_FILE_NAME = "BivaStorm_ApexOmega_Vault_v50.json"
local DEFAULT_PRICING_FOOTNOTE = "💡 Chú thích: Miễn Phí = Vượt Link (20h) • 8.000đ = 1 Ngày • 40.000đ = 1 Tuần • 130.000đ = 1 Tháng. Mọi gói trả phí đều kích hoạt tự động sau 3 giây quét QR, tự khóa bảo vệ theo Mã Máy (HWID), hỗ trợ tự đổi máy miễn phí và cam kết bù giờ 100% nếu bảo trì."
local GAME_MODES = {
{ id = "steal_egg", name = "🥚 Steal An Egg V50" },
{ id = "blox_fruits", name = "🏴‍☠️ Blox Fruits Sovereign" },
{ id = "fisch", name = "🐟 Fisch Assistant" },
{ id = "dead_rails", name = "🚂 Dead Rails HUD" }
}
local THEMES = {
-- ... existing code ...
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
for _, fName in ipairs({ SAVE_FILE_NAME, "BivaStorm_ApexOmega_Config_v45.json", "BivaStorm_ApexOmega_Config_v40.json", "BivaStorm_ApexOmega_Config_v35.json" }) do
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
-- ... existing code ...
local function loadVault()
local list = {}
pcall(function()
if type(isfile) == "function" and type(readfile) == "function" then
for _, vFile in ipairs({ VAULT_FILE_NAME, "BivaStorm_ApexOmega_Vault_v45.json", "BivaStorm_ApexOmega_Vault_v40.json", "BivaStorm_ApexOmega_Vault_v35.json" }) do
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
-- ... existing code ...
-- ==============================================================================
-- 4. TRẠNG THÁI ỨNG DỤNG & ÂM THANH TƯƠNG TÁC
-- ==============================================================================
local State = {
config = loadConfig(),
sync_rev = 1,
ping = 0,
admin_notice = "Hệ thống BIVA STORM V50 SOVEREIGN cấp Key tự động 3 giây hoạt động ổn định 100%",
pricing_footnote = DEFAULT_PRICING_FOOTNOTE,
maintenance = false,
-- ... existing code ...
-- NÚT THU NHỎ NỔI (FLOATING PILL)
local FloatingOrb = New("TextButton", {
BackgroundColor3 = THEME.BgCard,
AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.new(0, 14, 0.5, 0),
Size = UDim2.new(0, 168, 0, 36),
Font = Enum.Font.GothamBold,
Text = "⚡ BIVA V50",
TextColor3 = THEME.Accent,
TextSize = 11.5,
Visible = false,
AutoButtonColor = false,
ZIndex = 95,
Parent = ScreenGui
})
Corner(FloatingOrb, 18)
-- ... existing code ...
local TitleLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 44, 0, 5),
Size = UDim2.new(0, 320, 0, 16),
Font = Enum.Font.GothamBlack,
Text = "BIVA STORM V50 — SOVEREIGN LOADER",
TextColor3 = THEME.TextMain,
TextSize = 13,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = Header
})
BindTheme(TitleLbl, "TextColor3", "TextMain")
-- ... existing code ...
local GameModeBtn = New("TextButton", {
BackgroundColor3 = THEME.BgInput,
Position = UDim2.new(0, 125, 0, 4),
Size = UDim2.new(1, -133, 0, 24),
Font = Enum.Font.GothamBold,
Text = "🥚 Steal An Egg V50 (Bấm để đổi Game)",
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
GameModeBtn.Text = "🥚 Steal An Egg V50 (Bấm để đổi)"
end
refreshGameModeLabel()
-- ... existing code ...
local StatusTitleLbl = New("TextLabel", {
BackgroundTransparency = 1,
Position = UDim2.new(0, 10, 0, 5),
Size = UDim2.new(1, -20, 0, 16),
Font = Enum.Font.GothamBold,
Text = "💡 Trạng thái: Đang đồng bộ dữ liệu từ Server V50...",
TextColor3 = THEME.TextSub,
TextSize = 11,
TextTruncate = Enum.TextTruncate.AtEnd,
TextXAlignment = Enum.TextXAlignment.Left,
Parent = StatusCard
})
-- ... existing code ...
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
FloatingOrb.Text = "⚡ BIVA V50"
end
end
-- ... existing code ...
State.busy = true
ActivateBtn.Text = "⏳ Đang xác thực Key..."
setStatus("⏳ Đang kiểm tra Key [" .. k .. "] trên Server V50...", THEME.Warn)
task.spawn(function()
-- ... existing code ...
if type(luaCode) == "string" and #luaCode > 20 then
local fn, err = loadstring(luaCode)
if type(fn) == "function" then
setStatus("✅ Đã kích hoạt Script V50 Sovereign thành công!", THEME.Ok)
showToast("🎉 Đã mở khóa BIVA STORM V50 thành công!", false)
task.spawn(function() pcall(fn) end)
task.delay(0.7, function()
-- ... existing code ...
