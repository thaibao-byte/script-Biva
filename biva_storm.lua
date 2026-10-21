-- =========================================================
-- ⚡ BIVA STORM | CYBER LOADER UI V3 (ELECTRIC BLUE EDITION)
-- =========================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- Hàm mã hóa URL an toàn
local function url_encode(str)
if type(str) ~= "string" then return "" end
return (str:gsub("([^%w ])", function(c)
return string.format("%%%02X", string.byte(c))
end):gsub(" ", "%%20"))
end
-- Quản lý lưu trữ HWID & Key tự động
local HWID_FILE = "Biva_HWID.txt"
local KEY_FILE = "Biva_SavedKey.txt"
local hwid = tostring(player.UserId)
pcall(function()
if isfile and readfile and writefile then
if isfile(HWID_FILE) and readfile(HWID_FILE) ~= "" then
hwid = readfile(HWID_FILE)
else
writefile(HWID_FILE, hwid)
end
end
end)
local function loadSavedKey()
local saved = ""
pcall(function()
if isfile and readfile and isfile(KEY_FILE) then
saved = readfile(KEY_FILE)
end
end)
return saved or ""
end
local function saveKeyToFile(k)
pcall(function()
if writefile and k and k ~= "" then
writefile(KEY_FILE, k)
end
end)
end
-- Xoá UI cũ nếu đang tồn tại
if playerGui:FindFirstChild("BivaLoaderUI") then
playerGui.BivaLoaderUI:Destroy()
end
-- BẢNG MÀU CYBER ELECTRIC BLUE (Không dùng xanh lá)
local Theme = {
Main = Color3.fromRGB(7, 11, 20),
MainBottom = Color3.fromRGB(15, 23, 42),
Surface = Color3.fromRGB(16, 25, 46),
SurfaceHover = Color3.fromRGB(24, 38, 68),
Input = Color3.fromRGB(10, 16, 30),
Accent = Color3.fromRGB(56, 189, 248),      -- Electric Sky Blue
AccentBright = Color3.fromRGB(0, 210, 255), -- Neon Cyan Blue
AccentDeep = Color3.fromRGB(37, 99, 235),   -- Royal Blue
Purple = Color3.fromRGB(99, 102, 241),      -- Cyber Indigo
Text = Color3.fromRGB(248, 250, 252),
TextDim = Color3.fromRGB(148, 163, 184),
Danger = Color3.fromRGB(255, 51, 102),
Warning = Color3.fromRGB(251, 191, 36),
Stroke = Color3.fromRGB(30, 58, 95)
}
local sg = Instance.new("ScreenGui")
sg.Name = "BivaLoaderUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui
-- HÀM KÉO THẢ ĐỘC LẬP CHO TỪNG KHUNG (Mượt trên cả Mobile & PC)
local function MakeDraggable(frame, dragArea)
local dragging = false
local dragInput, dragStart, startPos
dragArea.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = frame.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
dragging = false
end
end)
end
end)
dragArea.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)
UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
frame.Position = UDim2.new(
startPos.X.Scale,
startPos.X.Offset + delta.X,
startPos.Y.Scale,
startPos.Y.Offset + delta.Y
)
end
end)
end
-- NÚT THU GỌN NỔI (FLOATING TOGGLE BUTTON "B")
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 46, 0, 46)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -23)
FloatBtn.BackgroundColor3 = Theme.Main
FloatBtn.Text = "B"
FloatBtn.TextColor3 = Theme.Accent
FloatBtn.Font = Enum.Font.FredokaOne
FloatBtn.TextSize = 24
FloatBtn.Visible = false
FloatBtn.Parent = sg
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatBtn)
FloatStroke.Color = Theme.Accent
FloatStroke.Thickness = 2
MakeDraggable(FloatBtn, FloatBtn)
-- KHUNG CHÍNH
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 380, 0, 470)
Main.Position = UDim2.new(0.5, -190, 0.5, -235)
Main.BackgroundColor3 = Theme.Main
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = sg
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.35
local MainGradient = Instance.new("UIGradient", Main)
MainGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Theme.Main),
ColorSequenceKeypoint.new(1, Theme.MainBottom)
})
MainGradient.Rotation = 45
-- HEADER (THANH TIÊU ĐỀ)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundTransparency = 1
Header.Parent = Main
MakeDraggable(Main, Header)
local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 40, 0, 40)
Logo.Position = UDim2.new(0, 18, 0.5, -20)
Logo.BackgroundColor3 = Theme.Surface
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 10)
local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Color = Theme.Accent
LogoStroke.Thickness = 1.5
local LogoGradient = Instance.new("UIGradient", Logo)
LogoGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Theme.AccentDeep),
ColorSequenceKeypoint.new(1, Theme.Main)
})
LogoGradient.Rotation = 135
local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "⚡"
LogoText.TextColor3 = Theme.Accent
LogoText.Font = Enum.Font.FredokaOne
LogoText.TextSize = 20
LogoText.Parent = Logo
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -145, 0, 24)
Title.Position = UDim2.new(0, 68, 0, 12)
Title.BackgroundTransparency = 1
Title.Text = "BIVA STORM"
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header
local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -145, 0, 16)
Subtitle.Position = UDim2.new(0, 68, 0, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "● Cyber Multi-Game Hub V3"
Subtitle.TextColor3 = Theme.Accent
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header
-- Nút Thu Gọn (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -82, 0.5, -15)
MinBtn.BackgroundColor3 = Theme.Surface
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.Accent
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)
local MinStroke = Instance.new("UIStroke", MinBtn)
MinStroke.Color = Theme.Stroke
MinStroke.Thickness = 1
MinBtn.MouseButton1Click:Connect(function()
Main.Visible = false
FloatBtn.Visible = true
end)
FloatBtn.MouseButton1Click:Connect(function()
FloatBtn.Visible = false
Main.Visible = true
end)
-- Nút Đóng (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -15)
CloseBtn.BackgroundColor3 = Theme.Surface
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.Color = Theme.Stroke
CloseStroke.Thickness = 1
CloseBtn.MouseButton1Click:Connect(function()
TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
Size = UDim2.new(0, 380, 0, 0)
}):Play()
task.wait(0.25)
sg:Destroy()
end)
-- ĐƯỜNG KẺ NGANG PHÁT SÁNG
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -36, 0, 1)
Divider.Position = UDim2.new(0, 18, 0, 64)
Divider.BackgroundColor3 = Theme.Stroke
Divider.BorderSizePixel = 0
Divider.Parent = Main
-- CONTAINER CHỨA CÁC TRANG
local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1, -36, 1, -80)
Pages.Position = UDim2.new(0, 18, 0, 74)
Pages.BackgroundTransparency = 1
Pages.ClipsDescendants = true
Pages.Parent = Main
-- ==========================================
-- TRANG 1: CHỌN GAME
-- ==========================================
local Page1 = Instance.new("Frame")
Page1.Size = UDim2.new(1, 0, 1, 0)
Page1.BackgroundTransparency = 1
Page1.Parent = Pages
local SearchBox = Instance.new("Frame")
SearchBox.Size = UDim2.new(1, 0, 0, 42)
SearchBox.BackgroundColor3 = Theme.Input
SearchBox.Parent = Page1
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 10)
local SearchStroke = Instance.new("UIStroke", SearchBox)
SearchStroke.Color = Theme.Stroke
SearchStroke.Thickness = 1.2
local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 38, 1, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = 15
SearchIcon.Parent = SearchBox
local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -44, 1, 0)
SearchInput.Position = UDim2.new(0, 38, 0, 0)
SearchInput.BackgroundTransparency = 1
SearchInput.PlaceholderText = "Tìm kiếm tựa game (Steal, Blox...)..."
SearchInput.PlaceholderColor3 = Theme.TextDim
SearchInput.TextColor3 = Theme.Text
SearchInput.Font = Enum.Font.GothamMedium
SearchInput.TextSize = 13
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.Text = ""
SearchInput.Parent = SearchBox
SearchInput.Focused:Connect(function()
TweenService:Create(SearchStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
end)
SearchInput.FocusLost:Connect(function()
TweenService:Create(SearchStroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
end)
local SectionLbl = Instance.new("TextLabel")
SectionLbl.Size = UDim2.new(1, 0, 0, 20)
SectionLbl.Position = UDim2.new(0, 2, 0, 48)
SectionLbl.BackgroundTransparency = 1
SectionLbl.Text = "DANH SÁCH GAME HỖ TRỢ"
SectionLbl.TextColor3 = Theme.TextDim
SectionLbl.Font = Enum.Font.GothamBold
SectionLbl.TextSize = 10
SectionLbl.TextXAlignment = Enum.TextXAlignment.Left
SectionLbl.Parent = Page1
local GameScroll = Instance.new("ScrollingFrame")
GameScroll.Size = UDim2.new(1, 0, 1, -72)
GameScroll.Position = UDim2.new(0, 0, 0, 72)
GameScroll.BackgroundTransparency = 1
GameScroll.ScrollBarThickness = 3
GameScroll.ScrollBarImageColor3 = Theme.Accent
GameScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
GameScroll.Parent = Page1
local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Padding = UDim.new(0, 8)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Parent = GameScroll
-- ==========================================
-- TRANG 2: NHẬP KEY & KÍCH HOẠT
-- ==========================================
local Page2 = Instance.new("Frame")
Page2.Size = UDim2.new(1, 0, 1, 0)
Page2.Position = UDim2.new(1, 20, 0, 0)
Page2.BackgroundTransparency = 1
Page2.Parent = Pages
local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(0, 88, 0, 32)
BackBtn.BackgroundColor3 = Theme.Surface
BackBtn.Text = "← Quay lại"
BackBtn.TextColor3 = Theme.Accent
BackBtn.Font = Enum.Font.GothamBold
BackBtn.TextSize = 12
BackBtn.Parent = Page2
Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 8)
local BackStroke = Instance.new("UIStroke", BackBtn)
BackStroke.Color = Theme.Stroke
BackStroke.Thickness = 1
local GameTitle = Instance.new("TextLabel")
GameTitle.Size = UDim2.new(1, -98, 0, 32)
GameTitle.Position = UDim2.new(0, 98, 0, 0)
GameTitle.BackgroundTransparency = 1
GameTitle.Text = "Tên Game"
GameTitle.TextColor3 = Theme.Text
GameTitle.Font = Enum.Font.GothamBold
GameTitle.TextSize = 15
GameTitle.TextXAlignment = Enum.TextXAlignment.Left
GameTitle.TextTruncate = Enum.TextTruncate.AtEnd
GameTitle.Parent = Page2
-- Hộp hiển thị HWID
local HwidTitle = Instance.new("TextLabel")
HwidTitle.Size = UDim2.new(1, 0, 0, 18)
HwidTitle.Position = UDim2.new(0, 2, 0, 42)
HwidTitle.BackgroundTransparency = 1
HwidTitle.Text = "MÃ MÁY CỦA BẠN (HWID)"
HwidTitle.TextColor3 = Theme.TextDim
HwidTitle.Font = Enum.Font.GothamBold
HwidTitle.TextSize = 10
HwidTitle.TextXAlignment = Enum.TextXAlignment.Left
HwidTitle.Parent = Page2
local HwidBox = Instance.new("Frame")
HwidBox.Size = UDim2.new(1, 0, 0, 44)
HwidBox.Position = UDim2.new(0, 0, 0, 62)
HwidBox.BackgroundColor3 = Theme.Input
HwidBox.Parent = Page2
Instance.new("UICorner", HwidBox).CornerRadius = UDim.new(0, 10)
local HwidStroke = Instance.new("UIStroke", HwidBox)
HwidStroke.Color = Theme.Stroke
HwidStroke.Thickness = 1.2
local HwidLabel = Instance.new("TextBox")
HwidLabel.Size = UDim2.new(1, -95, 1, 0)
HwidLabel.Position = UDim2.new(0, 12, 0, 0)
HwidLabel.BackgroundTransparency = 1
HwidLabel.Text = hwid
HwidLabel.TextEditable = false
HwidLabel.ClearTextOnFocus = false
HwidLabel.TextColor3 = Theme.Accent
HwidLabel.Font = Enum.Font.GothamBold
HwidLabel.TextSize = 13
HwidLabel.TextXAlignment = Enum.TextXAlignment.Left
HwidLabel.Parent = HwidBox
local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 74, 0, 30)
CopyBtn.Position = UDim2.new(1, -81, 0.5, -15)
CopyBtn.BackgroundColor3 = Theme.Surface
CopyBtn.Text = "📋 Copy"
CopyBtn.TextColor3 = Theme.Text
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 12
CopyBtn.Parent = HwidBox
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 7)
local CopyStroke = Instance.new("UIStroke", CopyBtn)
CopyStroke.Color = Theme.Accent
CopyStroke.Thickness = 1
-- Hộp nhập Key bản quyền
local KeyHeaderRow = Instance.new("Frame")
KeyHeaderRow.Size = UDim2.new(1, 0, 0, 18)
KeyHeaderRow.Position = UDim2.new(0, 2, 0, 118)
KeyHeaderRow.BackgroundTransparency = 1
KeyHeaderRow.Parent = Page2
local KeyHeaderLbl = Instance.new("TextLabel")
KeyHeaderLbl.Size = UDim2.new(0.6, 0, 1, 0)
KeyHeaderLbl.BackgroundTransparency = 1
KeyHeaderLbl.Text = "MÃ KEY BẢN QUYỀN"
KeyHeaderLbl.TextColor3 = Theme.TextDim
KeyHeaderLbl.Font = Enum.Font.GothamBold
KeyHeaderLbl.TextSize = 10
KeyHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
KeyHeaderLbl.Parent = KeyHeaderRow
local ClearKeyBtn = Instance.new("TextButton")
ClearKeyBtn.Size = UDim2.new(0, 60, 1, 0)
ClearKeyBtn.Position = UDim2.new(1, -62, 0, 0)
ClearKeyBtn.BackgroundTransparency = 1
ClearKeyBtn.Text = "✖ Xoá ô"
ClearKeyBtn.TextColor3 = Theme.TextDim
ClearKeyBtn.Font = Enum.Font.GothamBold
ClearKeyBtn.TextSize = 10
ClearKeyBtn.TextXAlignment = Enum.TextXAlignment.Right
ClearKeyBtn.Parent = KeyHeaderRow
local KeyBox = Instance.new("Frame")
KeyBox.Size = UDim2.new(1, 0, 0, 46)
KeyBox.Position = UDim2.new(0, 0, 0, 138)
KeyBox.BackgroundColor3 = Theme.Input
KeyBox.Parent = Page2
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 10)
local KeyStroke = Instance.new("UIStroke", KeyBox)
KeyStroke.Color = Theme.Stroke
KeyStroke.Thickness = 1.2
local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -24, 1, 0)
KeyInput.Position = UDim2.new(0, 12, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.PlaceholderText = "Nhập hoặc dán Key vào đây..."
KeyInput.PlaceholderColor3 = Theme.TextDim
KeyInput.TextColor3 = Theme.Accent
KeyInput.Font = Enum.Font.GothamBold
KeyInput.TextSize = 14
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false
KeyInput.Text = loadSavedKey()
KeyInput.Parent = KeyBox
KeyInput.Focused:Connect(function()
TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
end)
KeyInput.FocusLost:Connect(function()
TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
end)
ClearKeyBtn.MouseButton1Click:Connect(function()
KeyInput.Text = ""
end)
-- Nút Kích Hoạt Script (Electric Blue Gradient)
local ActivateBtn = Instance.new("TextButton")
ActivateBtn.Size = UDim2.new(1, 0, 0, 50)
ActivateBtn.Position = UDim2.new(0, 0, 0, 198)
ActivateBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT"
ActivateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActivateBtn.Font = Enum.Font.GothamBold
ActivateBtn.TextSize = 15
ActivateBtn.Parent = Page2
Instance.new("UICorner", ActivateBtn).CornerRadius = UDim.new(0, 10)
local ActGradient = Instance.new("UIGradient", ActivateBtn)
ActGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Theme.AccentBright),
ColorSequenceKeypoint.new(0.5, Theme.AccentDeep),
ColorSequenceKeypoint.new(1, Theme.Purple)
})
ActGradient.Rotation = 0
local ActStroke = Instance.new("UIStroke", ActivateBtn)
ActStroke.Color = Theme.Accent
ActStroke.Thickness = 1.2
-- Nút Copy Link Web Mua Key
local WebLinkBtn = Instance.new("TextButton")
WebLinkBtn.Size = UDim2.new(1, 0, 0, 36)
WebLinkBtn.Position = UDim2.new(0, 0, 0, 258)
WebLinkBtn.BackgroundColor3 = Theme.Surface
WebLinkBtn.Text = "🌐 Copy Link Web Mua Key Tự Động 24/7"
WebLinkBtn.TextColor3 = Theme.Accent
WebLinkBtn.Font = Enum.Font.GothamBold
WebLinkBtn.TextSize = 12
WebLinkBtn.Parent = Page2
Instance.new("UICorner", WebLinkBtn).CornerRadius = UDim.new(0, 8)
local WebStroke = Instance.new("UIStroke", WebLinkBtn)
WebStroke.Color = Theme.Stroke
WebStroke.Thickness = 1
-- Hộp Trạng Thái Kết Nối
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 48)
Status.Position = UDim2.new(0, 0, 0, 304)
Status.BackgroundTransparency = 1
Status.Text = "💡 Mẹo: Key sau khi kích hoạt sẽ được tự động lưu cho lần sau."
Status.TextColor3 = Theme.TextDim
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 12
Status.TextWrapped = true
Status.Parent = Page2
-- ==========================================
-- LOGIC XỬ LÝ DANH SÁCH GAME & TƯƠNG TÁC
-- ==========================================
local games = {
{name = "Steal an Egg", id = "steal_egg", desc = "Auto Steal, ESP Eggs, Teleport All"},
{name = "Blox Fruits", id = "blox_fruits", desc = "Auto Farm, Raid, Sea Events VIP"},
}
local gameBtns = {}
local selectedGameId = ""
for _, g in ipairs(games) do
local Card = Instance.new("TextButton")
Card.Size = UDim2.new(1, 0, 0, 58)
Card.BackgroundColor3 = Theme.Surface
Card.Text = ""
Card.AutoButtonColor = false
Card.Parent = GameScroll
Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)
local Strk = Instance.new("UIStroke", Card)
Strk.Color = Theme.Stroke
Strk.Thickness = 1.2
local IconBox = Instance.new("Frame")
IconBox.Size = UDim2.new(0, 38, 0, 38)
IconBox.Position = UDim2.new(0, 10, 0.5, -19)
IconBox.BackgroundColor3 = Theme.Input
IconBox.Parent = Card
Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0, 8)
local IconLbl = Instance.new("TextLabel")
IconLbl.Size = UDim2.new(1, 0, 1, 0)
IconLbl.BackgroundTransparency = 1
IconLbl.Text = "⚡"
IconLbl.TextColor3 = Theme.Accent
IconLbl.Font = Enum.Font.GothamBold
IconLbl.TextSize = 18
IconLbl.Parent = IconBox
local NameLbl = Instance.new("TextLabel")
NameLbl.Size = UDim2.new(1, -95, 0, 20)
NameLbl.Position = UDim2.new(0, 58, 0, 10)
NameLbl.BackgroundTransparency = 1
NameLbl.Text = g.name
NameLbl.TextColor3 = Theme.Text
NameLbl.Font = Enum.Font.GothamBold
NameLbl.TextSize = 14
NameLbl.TextXAlignment = Enum.TextXAlignment.Left
NameLbl.Parent = Card
local DescLbl = Instance.new("TextLabel")
DescLbl.Size = UDim2.new(1, -95, 0, 16)
DescLbl.Position = UDim2.new(0, 58, 0, 30)
DescLbl.BackgroundTransparency = 1
DescLbl.Text = g.desc or "Bản quyền Biva Storm"
DescLbl.TextColor3 = Theme.TextDim
DescLbl.Font = Enum.Font.Gotham
DescLbl.TextSize = 11
DescLbl.TextXAlignment = Enum.TextXAlignment.Left
DescLbl.Parent = Card
local ArrowLbl = Instance.new("TextLabel")
ArrowLbl.Size = UDim2.new(0, 30, 1, 0)
ArrowLbl.Position = UDim2.new(1, -34, 0, 0)
ArrowLbl.BackgroundTransparency = 1
ArrowLbl.Text = "→"
ArrowLbl.TextColor3 = Theme.Accent
ArrowLbl.Font = Enum.Font.GothamBold
ArrowLbl.TextSize = 16
ArrowLbl.Parent = Card
Card.MouseEnter:Connect(function()
TweenService:Create(Card, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SurfaceHover}):Play()
TweenService:Create(Strk, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
end)
Card.MouseLeave:Connect(function()
TweenService:Create(Card, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Surface}):Play()
TweenService:Create(Strk, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
end)
table.insert(gameBtns, {btn = Card, name = string.lower(g.name)})
Card.MouseButton1Click:Connect(function()
selectedGameId = g.id
GameTitle.Text = "⚡ " .. g.name
Status.TextColor3 = Theme.TextDim
Status.Text = "💡 Mẹo: Key sau khi kích hoạt sẽ được tự động lưu cho lần sau."
TweenService:Create(Page1, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
Position = UDim2.new(-1, -20, 0, 0)
}):Play()
TweenService:Create(Page2, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
Position = UDim2.new(0, 0, 0, 0)
}):Play()
end)
end
ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
GameScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 10)
end)
GameScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 10)
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
local txt = string.lower(SearchInput.Text)
for _, item in ipairs(gameBtns) do
item.btn.Visible = (string.find(item.name, txt, 1, true) ~= nil)
end
end)
BackBtn.MouseButton1Click:Connect(function()
TweenService:Create(Page1, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
Position = UDim2.new(0, 0, 0, 0)
}):Play()
TweenService:Create(Page2, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
Position = UDim2.new(1, 20, 0, 0)
}):Play()
end)
-- Copy HWID
local copyCooldown = false
CopyBtn.MouseButton1Click:Connect(function()
if copyCooldown then return end
copyCooldown = true
if setclipboard then
setclipboard(hwid)
CopyBtn.Text = "✅ Đã Copy"
TweenService:Create(CopyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.AccentDeep}):Play()
task.delay(1.5, function()
if CopyBtn and CopyBtn.Parent then
CopyBtn.Text = "📋 Copy"
TweenService:Create(CopyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Surface}):Play()
end
copyCooldown = false
end)
else
Status.TextColor3 = Theme.Warning
Status.Text = "⚠️ Executor không hỗ trợ tự copy, hãy bấm vào ô HWID để copy."
copyCooldown = false
end
end)
-- Copy Link Web Cửa Hàng
WebLinkBtn.MouseButton1Click:Connect(function()
if setclipboard then
setclipboard("https://bivastorm-web.onrender.com")
WebLinkBtn.Text = "✅ Đã Copy Link Web Cửa Hàng!"
task.delay(2, function()
if WebLinkBtn and WebLinkBtn.Parent then
WebLinkBtn.Text = "🌐 Copy Link Web Mua Key Tự Động 24/7"
end
end)
else
Status.TextColor3 = Theme.Accent
Status.Text = "🌐 Web mua Key: https://bivastorm-web.onrender.com"
end
end)
-- Logic Kích Hoạt Script
local isConnecting = false
ActivateBtn.MouseButton1Click:Connect(function()
if isConnecting then return end
local cleanKey = string.gsub(KeyInput.Text, "%s+", "")
if cleanKey == "" then
Status.TextColor3 = Theme.Danger
Status.Text = "⚠️ Vui lòng nhập Key bản quyền trước khi kích hoạt!"
return
end
isConnecting = true
local elapsed = 0
ActivateBtn.Text = "⏳ ĐANG KẾT NỐI SERVER..."
-- Bộ đếm giây trực quan nếu Render đang ngủ đông
task.spawn(function()
while isConnecting and ActivateBtn and ActivateBtn.Parent do
Status.TextColor3 = Theme.Accent
Status.Text = string.format("⚡ Đang xác thực bản quyền với Server (%ds)...", elapsed)
task.wait(1)
elapsed = elapsed + 1
end
end)
task.spawn(function()
local url = "https://biva-hub.onrender.com/api/get_script?key="
.. url_encode(cleanKey)
.. "&hwid=" .. url_encode(hwid)
.. "&game_id=" .. url_encode(selectedGameId)
local success, code = pcall(function()
return game:HttpGet(url)
end)
isConnecting = false
if success and code and code ~= "" then
if string.find(code, "Kick") then
loadstring(code)()
ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT"
else
local func, err = loadstring(code)
if func then
-- Lưu lại Key hợp lệ cho lần chơi tiếp theo
saveKeyToFile(cleanKey)
Status.TextColor3 = Theme.Accent
Status.Text = "✅ Kích hoạt thành công! Đang mở Menu..."
TweenService:Create(Main, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
Size = UDim2.new(0, 380, 0, 0)
}):Play()
task.wait(0.28)
sg:Destroy()
func()
else
ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT"
Status.TextColor3 = Theme.Danger
Status.Text = "❌ Lỗi thực thi Script: " .. tostring(err)
end
end
else
ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT"
Status.TextColor3 = Theme.Danger
Status.Text = "❌ Lỗi kết nối Server! Hãy bấm Kích Hoạt lại sau 5 giây."
end
end)
end)
