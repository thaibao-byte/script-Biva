-- =========================================================
-- ⚡ BIVA STORM | CYBER LOADER UI V8 APEX (SYNCED EDITION)
-- =========================================================
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local API_BASE  = "https://biva-hub.onrender.com"
local WEB_STORE = "https://bivastorm-web.onrender.com"
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bảo vệ UI trên các Executor hỗ trợ gethui / CoreGui
local function getGuiParent()
    local ok, hui = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if ok and hui then return hui end
    return playerGui
end

-- Hàm mã hóa URL an toàn (ĐÃ FIX LỖI DẤU ==)
local function url_encode(str)
    if type(str) ~= "string" then return "" end 
    str = str:gsub("\r\n", "\n")
    return (str:gsub("([^%w%-%.%_% ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
end

-- Quản lý lưu trữ HWID, Key & Game gần nhất tự động
local HWID_FILE = "Biva_HWID.txt"
local KEY_FILE  = "Biva_SavedKey.txt"
local GAME_FILE = "Biva_LastGame.txt"

local function detectHWID()
    local id = nil
    pcall(function()
        if gethwid then
            id = tostring(gethwid())
        elseif game:GetService("RbxAnalyticsService") then
            id = tostring(game:GetService("RbxAnalyticsService"):GetClientId()):gsub("-", ""):sub(1, 16)
        end
    end)
    if not id or id == "" then
        id = "BIVA" .. tostring(player.UserId)
    end
    return id:gsub("[^%w%-]", ""):upper()
end

local hwid = detectHWID()
pcall(function()
    if isfile and readfile and writefile then
        if isfile(HWID_FILE) then
            local savedHwid = readfile(HWID_FILE):gsub("%s+", "")
            if savedHwid ~= "" then
                hwid = savedHwid
            else
                writefile(HWID_FILE, hwid)
            end
        else
            writefile(HWID_FILE, hwid)
        end
    end
end)

local function loadSavedKey()
    local saved = ""
    pcall(function()
        if isfile and readfile and isfile(KEY_FILE) then
            saved = readfile(KEY_FILE):gsub("%s+", "")
        end
    end)
    return saved or ""
end

local function saveKeyToFile(k)
    pcall(function()
        if writefile and k then
            writefile(KEY_FILE, k)
        end
    end)
end

-- Xoá UI & Blur cũ nếu đang tồn tại
local guiParent = getGuiParent()
if guiParent:FindFirstChild("BivaLoaderUI") then
    guiParent.BivaLoaderUI:Destroy()
end
if playerGui:FindFirstChild("BivaLoaderUI") then
    playerGui.BivaLoaderUI:Destroy()
end
if Lighting:FindFirstChild("BivaCyberBlur") then
    Lighting.BivaCyberBlur:Destroy()
end

-- BẢNG MÀU CYBERPUNK V8 APEX (ĐỒNG BỘ WEB STORE)
local Theme = {
    BgDark       = Color3.fromRGB(3, 6, 15),
    BgBottom     = Color3.fromRGB(11, 20, 38),
    Card         = Color3.fromRGB(12, 21, 40),
    CardHover    = Color3.fromRGB(19, 34, 62),
    Input        = Color3.fromRGB(6, 11, 22),
    Accent       = Color3.fromRGB(56, 189, 248),  
    AccentNeon   = Color3.fromRGB(0, 198, 255),   
    AccentRoyal  = Color3.fromRGB(37, 99, 235),   
    Purple       = Color3.fromRGB(129, 140, 248), 
    Success      = Color3.fromRGB(52, 211, 153),  
    Danger       = Color3.fromRGB(255, 51, 102),  
    Warning      = Color3.fromRGB(251, 191, 36),  
    Text         = Color3.fromRGB(248, 250, 252),
    TextDim      = Color3.fromRGB(148, 163, 184),
    Stroke       = Color3.fromRGB(30, 54, 92)
}

-- HIỆU ỨNG KÍNH MỜ HẬU CẢNH (BLUR)
local Blur = Instance.new("BlurEffect")
Blur.Name = "BivaCyberBlur"
Blur.Size = 0
Blur.Parent = Lighting
TweenService:Create(Blur, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = 14}):Play()

local sg = Instance.new("ScreenGui")
sg.Name = "BivaLoaderUI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = guiParent

-- HÀM KÉO THẢ MƯỢT MÀ (HỖ TRỢ CẢ PC & MOBILE + UISCALE)
local function MakeDraggable(frame, dragArea)
    local dragging, dragInput, dragStart, startPos
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
            TweenService:Create(frame, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

-- NÚT THU GỌN NỔI (FLOATING ORB)
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 52, 0, 52)
FloatBtn.Position = UDim2.new(0, 28, 0.5, 0)
FloatBtn.AnchorPoint = Vector2.new(0, 0.5)
FloatBtn.BackgroundColor3 = Theme.BgDark
FloatBtn.Text = "⚡"
FloatBtn.TextColor3 = Theme.AccentNeon
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 24
FloatBtn.Visible = false
FloatBtn.Parent = sg
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatBtn)
FloatStroke.Color = Theme.AccentNeon
FloatStroke.Thickness = 2
MakeDraggable(FloatBtn, FloatBtn)

-- KHUNG CHÍNH (MAIN CONTAINER)
local MAIN_W, MAIN_H = 420, 515
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, MAIN_W, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Theme.BgDark
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = sg
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)

local MainScale = Instance.new("UIScale", Main)
local function updateResponsiveScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local scaleH = (vp.Y - 28) / MAIN_H
    local scaleW = (vp.X - 24) / MAIN_W
    local targetScale = math.clamp(math.min(scaleH, scaleW, 1), 0.58, 1)
    MainScale.Scale = targetScale
end
updateResponsiveScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
end

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 1.8
MainStroke.Color = Color3.new(1, 1, 1)
local BorderGrad = Instance.new("UIGradient", MainStroke)
BorderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentNeon),
    ColorSequenceKeypoint.new(0.5, Theme.Purple),
    ColorSequenceKeypoint.new(1, Theme.AccentRoyal)
})

local MainGradient = Instance.new("UIGradient", Main)
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.BgDark),
    ColorSequenceKeypoint.new(1, Theme.BgBottom)
})
MainGradient.Rotation = 45

TweenService:Create(Main, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, MAIN_W, 0, MAIN_H)
}):Play()

-- TOAST NOTIFICATION TRONG MENU
local ToastFrame = Instance.new("Frame")
ToastFrame.Size = UDim2.new(1, -36, 0, 36)
ToastFrame.Position = UDim2.new(0, 18, 0, -48)
ToastFrame.BackgroundColor3 = Theme.Card
ToastFrame.ZIndex = 30
ToastFrame.Parent = Main
Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 10)
local ToastStroke = Instance.new("UIStroke", ToastFrame)
ToastStroke.Color = Theme.AccentNeon
ToastStroke.Thickness = 1.3
local ToastLabel = Instance.new("TextLabel")
ToastLabel.Size = UDim2.new(1, -20, 1, 0)
ToastLabel.Position = UDim2.new(0, 10, 0, 0)
ToastLabel.BackgroundTransparency = 1
ToastLabel.Text = "⚡ Thông báo"
ToastLabel.TextColor3 = Theme.Text
ToastLabel.Font = Enum.Font.GothamBold
ToastLabel.TextSize = 12
ToastLabel.TextTruncate = Enum.TextTruncate.AtEnd
ToastLabel.ZIndex = 31
ToastLabel.Parent = ToastFrame

local toastId = 0
local function showToast(msg, color)
    toastId = toastId + 1
    local currentId = toastId
    ToastLabel.Text = msg
    ToastStroke.Color = color or Theme.AccentNeon
    TweenService:Create(ToastFrame, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 18, 0, 14)
    }):Play()
    task.delay(2.4, function()
        if toastId == currentId and ToastFrame and ToastFrame.Parent then
            TweenService:Create(ToastFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, 18, 0, -48)
            }):Play()
        end
    end)
end

local function shakeElement(guiObj, strokeObj)
    if strokeObj then
        strokeObj.Color = Theme.Danger
        task.delay(0.65, function()
            if strokeObj and strokeObj.Parent then
                strokeObj.Color = Theme.Stroke
            end
        end)
    end
    local origPos = guiObj.Position
    task.spawn(function()
        local offsets = {-6, 6, -5, 5, -3, 3, 0}
        for _, dx in ipairs(offsets) do
            if not guiObj or not guiObj.Parent then break end
            guiObj.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + dx, origPos.Y.Scale, origPos.Y.Offset)
            task.wait(0.035)
        end
        if guiObj and guiObj.Parent then
            guiObj.Position = origPos
        end
    end)
end

-- ==========================================
-- HEADER
-- ==========================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundTransparency = 1
Header.Parent = Main
MakeDraggable(Main, Header)

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 42, 0, 42)
Logo.Position = UDim2.new(0, 18, 0.5, -21)
Logo.BackgroundColor3 = Theme.Card
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 12)
local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Color = Theme.AccentNeon
LogoStroke.Thickness = 1.5
local LogoGradient = Instance.new("UIGradient", Logo)
LogoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentRoyal),
    ColorSequenceKeypoint.new(1, Theme.BgDark)
})
LogoGradient.Rotation = 135
local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "⚡"
LogoText.TextColor3 = Theme.AccentNeon
LogoText.Font = Enum.Font.FredokaOne
LogoText.TextSize = 22
LogoText.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 118, 0, 22)
Title.Position = UDim2.new(0, 68, 0, 12)
Title.BackgroundTransparency = 1
Title.Text = "BIVA STORM"
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local VersionBadge = Instance.new("TextLabel")
VersionBadge.Size = UDim2.new(0, 54, 0, 17)
VersionBadge.Position = UDim2.new(0, 186, 0, 14)
VersionBadge.BackgroundColor3 = Color3.new(1, 1, 1)
VersionBadge.Text = "V8 APEX"
VersionBadge.TextColor3 = Color3.new(1, 1, 1)
VersionBadge.Font = Enum.Font.GothamBold
VersionBadge.TextSize = 9
VersionBadge.Parent = Header
Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(0, 6)
local BadgeGrad = Instance.new("UIGradient", VersionBadge)
BadgeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentNeon),
    ColorSequenceKeypoint.new(1, Theme.Purple)
})

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -165, 0, 16)
Subtitle.Position = UDim2.new(0, 68, 0, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "● Hệ thống tự động 24/7 • PayOS Auto"
Subtitle.TextColor3 = Theme.Accent
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Nút Thu Gọn
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -86, 0.5, -16)
MinBtn.BackgroundColor3 = Theme.Card
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.Accent
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 9)
local MinStroke = Instance.new("UIStroke", MinBtn)
MinStroke.Color = Theme.Stroke
MinStroke.Thickness = 1

local function toggleMinimize()
    if Main.Visible then
        Main.Visible = false
        Blur.Enabled = false
        FloatBtn.Visible = true
    else
        FloatBtn.Visible = false
        Blur.Enabled = true
        Main.Visible = true
    end
end
MinBtn.MouseButton1Click:Connect(toggleMinimize)
FloatBtn.MouseButton1Click:Connect(toggleMinimize)

-- Nút Đóng
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -46, 0.5, -16)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 9)
local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.Color = Theme.Stroke
CloseStroke.Thickness = 1

local function closeLoader()
    TweenService:Create(Blur, TweenInfo.new(0.24), {Size = 0}):Play()
    TweenService:Create(Main, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, MAIN_W, 0, 0)
    }):Play()
    task.wait(0.24)
    if Blur then Blur:Destroy() end
    if sg then sg:Destroy() end
end
CloseBtn.MouseButton1Click:Connect(closeLoader)

-- ĐƯỜNG KẺ NGANG
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -36, 0, 1)
Divider.Position = UDim2.new(0, 18, 0, 64)
Divider.BackgroundColor3 = Theme.Stroke
Divider.BorderSizePixel = 0
Divider.Parent = Main

-- THẺ HỒ SƠ NGƯỜI CHƠI & PING REALTIME
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, -36, 0, 50)
ProfileCard.Position = UDim2.new(0, 18, 0, 73)
ProfileCard.BackgroundColor3 = Theme.Card
ProfileCard.Parent = Main
Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 11)
local ProfStroke = Instance.new("UIStroke", ProfileCard)
ProfStroke.Color = Theme.Stroke
ProfStroke.Thickness = 1

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 36, 0, 36)
AvatarImg.Position = UDim2.new(0, 8, 0.5, -18)
AvatarImg.BackgroundColor3 = Theme.Input
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
AvatarImg.Parent = ProfileCard
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
local AvStroke = Instance.new("UIStroke", AvatarImg)
AvStroke.Color = Theme.AccentNeon
AvStroke.Thickness = 1.2

local UserTitle = Instance.new("TextLabel")
UserTitle.Size = UDim2.new(1, -155, 0, 18)
UserTitle.Position = UDim2.new(0, 52, 0, 7)
UserTitle.BackgroundTransparency = 1
UserTitle.Text = player.DisplayName .. " (@" .. player.Name .. ")"
UserTitle.TextColor3 = Theme.Text
UserTitle.Font = Enum.Font.GothamBold
UserTitle.TextSize = 12
UserTitle.TextXAlignment = Enum.TextXAlignment.Left
UserTitle.TextTruncate = Enum.TextTruncate.AtEnd
UserTitle.Parent = ProfileCard

local UserSub = Instance.new("TextLabel")
UserSub.Size = UDim2.new(1, -155, 0, 15)
UserSub.Position = UDim2.new(0, 52, 0, 26)
UserSub.BackgroundTransparency = 1
UserSub.Text = "🛡️ HWID: " .. hwid:sub(1, 12) .. (string.len(hwid) > 12 and "..." or "")
UserSub.TextColor3 = Theme.TextDim
UserSub.Font = Enum.Font.GothamMedium
UserSub.TextSize = 11
UserSub.TextXAlignment = Enum.TextXAlignment.Left
UserSub.Parent = ProfileCard

local OnlinePill = Instance.new("TextLabel")
OnlinePill.Size = UDim2.new(0, 84, 0, 24)
OnlinePill.Position = UDim2.new(1, -92, 0.5, -12)
OnlinePill.BackgroundColor3 = Color3.fromRGB(12, 38, 36)
OnlinePill.Text = "⚡ ONLINE"
OnlinePill.TextColor3 = Theme.Success
OnlinePill.Font = Enum.Font.GothamBold
OnlinePill.TextSize = 10
OnlinePill.Parent = ProfileCard
Instance.new("UICorner", OnlinePill).CornerRadius = UDim.new(0, 8)
local PillStroke = Instance.new("UIStroke", OnlinePill)
PillStroke.Color = Color3.fromRGB(28, 92, 76)
PillStroke.Thickness = 1

task.spawn(function()
    while sg and sg.Parent do
        if Main.Visible then
            local t0 = os.clock()
            local ok = pcall(function()
                return game:HttpGet(API_BASE .. "/api/public_stats")
            end)
            local ms = math.max(12, math.floor((os.clock() - t0) * 1000))
            if ok and OnlinePill and OnlinePill.Parent then
                OnlinePill.Text = "⚡ " .. tostring(ms) .. "ms"
                OnlinePill.TextColor3 = Theme.Success
            elseif OnlinePill and OnlinePill.Parent then
                OnlinePill.Text = "● STANDBY"
                OnlinePill.TextColor3 = Theme.Warning
            end
        end
        task.wait(15)
    end
end)

-- CONTAINER CHỨA CÁC TRANG
local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1, -36, 1, -142)
Pages.Position = UDim2.new(0, 18, 0, 132)
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
SearchBox.Size = UDim2.new(1, 0, 0, 40)
SearchBox.BackgroundColor3 = Theme.Input
SearchBox.Parent = Page1
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 10)
local SearchStroke = Instance.new("UIStroke", SearchBox)
SearchStroke.Color = Theme.Stroke
SearchStroke.Thickness = 1.2

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 36, 1, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = 14
SearchIcon.Parent = SearchBox

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -42, 1, 0)
SearchInput.Position = UDim2.new(0, 36, 0, 0)
SearchInput.BackgroundTransparency = 1
SearchInput.PlaceholderText = "Tìm nhanh tựa game (Steal an Egg, Blox Fruits...)..."
SearchInput.PlaceholderColor3 = Theme.TextDim
SearchInput.TextColor3 = Theme.Text
SearchInput.Font = Enum.Font.GothamMedium
SearchInput.TextSize = 12
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.Text = ""
SearchInput.Parent = SearchBox

SearchInput.Focused:Connect(function()
    TweenService:Create(SearchStroke, TweenInfo.new(0.2), {Color = Theme.AccentNeon}):Play()
end)
SearchInput.FocusLost:Connect(function()
    TweenService:Create(SearchStroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
end)

local SectionLbl = Instance.new("TextLabel")
SectionLbl.Size = UDim2.new(1, 0, 0, 18)
SectionLbl.Position = UDim2.new(0, 2, 0, 46)
SectionLbl.BackgroundTransparency = 1
SectionLbl.Text = "⚡ CHỌN TỰA GAME ĐỂ TIẾP TỤC"
SectionLbl.TextColor3 = Theme.Accent
SectionLbl.Font = Enum.Font.GothamBold
SectionLbl.TextSize = 10
SectionLbl.TextXAlignment = Enum.TextXAlignment.Left
SectionLbl.Parent = Page1

local GameScroll = Instance.new("ScrollingFrame")
GameScroll.Size = UDim2.new(1, 0, 1, -68)
GameScroll.Position = UDim2.new(0, 0, 0, 68)
GameScroll.BackgroundTransparency = 1
GameScroll.ScrollBarThickness = 3
GameScroll.ScrollBarImageColor3 = Theme.AccentNeon
GameScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
GameScroll.Parent = Page1

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Padding = UDim.new(0, 10)
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
BackBtn.Size = UDim2.new(0, 92, 0, 30)
BackBtn.BackgroundColor3 = Theme.Card
BackBtn.Text = "← Chọn Game"
BackBtn.TextColor3 = Theme.Accent
BackBtn.Font = Enum.Font.GothamBold
BackBtn.TextSize = 11
BackBtn.Parent = Page2
Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 8)
local BackStroke = Instance.new("UIStroke", BackBtn)
BackStroke.Color = Theme.Stroke
BackStroke.Thickness = 1

local GameTitle = Instance.new("TextLabel")
GameTitle.Size = UDim2.new(1, -100, 0, 30)
GameTitle.Position = UDim2.new(0, 100, 0, 0)
GameTitle.BackgroundTransparency = 1
GameTitle.Text = "Tên Game"
GameTitle.TextColor3 = Theme.Text
GameTitle.Font = Enum.Font.GothamBold
GameTitle.TextSize = 14
GameTitle.TextXAlignment = Enum.TextXAlignment.Left
GameTitle.TextTruncate = Enum.TextTruncate.AtEnd
GameTitle.Parent = Page2

local HwidTitle = Instance.new("TextLabel")
HwidTitle.Size = UDim2.new(1, 0, 0, 16)
HwidTitle.Position = UDim2.new(0, 2, 0, 36)
HwidTitle.BackgroundTransparency = 1
HwidTitle.Text = "MÃ MÁY CỦA BẠN (HWID - DÙNG ĐỂ MUA KEY TRÊN WEB)"
HwidTitle.TextColor3 = Theme.TextDim
HwidTitle.Font = Enum.Font.GothamBold
HwidTitle.TextSize = 10
HwidTitle.TextXAlignment = Enum.TextXAlignment.Left
HwidTitle.Parent = Page2

local HwidBox = Instance.new("Frame")
HwidBox.Size = UDim2.new(1, 0, 0, 42)
HwidBox.Position = UDim2.new(0, 0, 0, 54)
HwidBox.BackgroundColor3 = Theme.Input
HwidBox.Parent = Page2
Instance.new("UICorner", HwidBox).CornerRadius = UDim.new(0, 10)
local HwidStroke = Instance.new("UIStroke", HwidBox)
HwidStroke.Color = Theme.Stroke
HwidStroke.Thickness = 1.2

local HwidLabel = Instance.new("TextBox")
HwidLabel.Size = UDim2.new(1, -102, 1, 0)
HwidLabel.Position = UDim2.new(0, 12, 0, 0)
HwidLabel.BackgroundTransparency = 1
HwidLabel.Text = hwid
HwidLabel.TextEditable = false
HwidLabel.ClearTextOnFocus = false
HwidLabel.TextColor3 = Theme.AccentNeon
HwidLabel.Font = Enum.Font.GothamBold
HwidLabel.TextSize = 13
HwidLabel.TextXAlignment = Enum.TextXAlignment.Left
HwidLabel.Parent = HwidBox

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 86, 0, 28)
CopyBtn.Position = UDim2.new(1, -93, 0.5, -14)
CopyBtn.BackgroundColor3 = Theme.Card
CopyBtn.Text = "📋 Copy HWID"
CopyBtn.TextColor3 = Theme.Text
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 11
CopyBtn.Parent = HwidBox
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 7)
local CopyStroke = Instance.new("UIStroke", CopyBtn)
CopyStroke.Color = Theme.Accent
CopyStroke.Thickness = 1

local KeyHeaderRow = Instance.new("Frame")
KeyHeaderRow.Size = UDim2.new(1, 0, 0, 18)
KeyHeaderRow.Position = UDim2.new(0, 2, 0, 104)
KeyHeaderRow.BackgroundTransparency = 1
KeyHeaderRow.Parent = Page2

local KeyHeaderLbl = Instance.new("TextLabel")
KeyHeaderLbl.Size = UDim2.new(0, 115, 1, 0)
KeyHeaderLbl.BackgroundTransparency = 1
KeyHeaderLbl.Text = "MÃ KEY BẢN QUYỀN"
KeyHeaderLbl.TextColor3 = Theme.TextDim
KeyHeaderLbl.Font = Enum.Font.GothamBold
KeyHeaderLbl.TextSize = 10
KeyHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
KeyHeaderLbl.Parent = KeyHeaderRow

local KeyReadyPill = Instance.new("TextLabel")
KeyReadyPill.Size = UDim2.new(0, 74, 0, 16)
KeyReadyPill.Position = UDim2.new(0, 118, 0, 1)
KeyReadyPill.BackgroundColor3 = Theme.Card
KeyReadyPill.Text = "Chưa nhập"
KeyReadyPill.TextColor3 = Theme.TextDim
KeyReadyPill.Font = Enum.Font.GothamBold
KeyReadyPill.TextSize = 9
KeyReadyPill.Parent = KeyHeaderRow
Instance.new("UICorner", KeyReadyPill).CornerRadius = UDim.new(1, 0)

local ClearKeyBtn = Instance.new("TextButton")
ClearKeyBtn.Size = UDim2.new(0, 55, 1, 0)
ClearKeyBtn.Position = UDim2.new(1, -58, 0, 0)
ClearKeyBtn.BackgroundTransparency = 1
ClearKeyBtn.Text = "✖ Xoá ô"
ClearKeyBtn.TextColor3 = Theme.TextDim
ClearKeyBtn.Font = Enum.Font.GothamBold
ClearKeyBtn.TextSize = 10
ClearKeyBtn.TextXAlignment = Enum.TextXAlignment.Right
ClearKeyBtn.Parent = KeyHeaderRow

local KeyBox = Instance.new("Frame")
KeyBox.Size = UDim2.new(1, 0, 0, 44)
KeyBox.Position = UDim2.new(0, 0, 0, 124)
KeyBox.BackgroundColor3 = Theme.Input
KeyBox.Parent = Page2
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 10)
local KeyStroke = Instance.new("UIStroke", KeyBox)
KeyStroke.Color = Theme.Stroke
KeyStroke.Thickness = 1.2

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -88, 1, 0)
KeyInput.Position = UDim2.new(0, 12, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.PlaceholderText = "Dán mã Key (VD: RB-XXXX...) vào đây..."
KeyInput.PlaceholderColor3 = Theme.TextDim
KeyInput.TextColor3 = Theme.AccentNeon
KeyInput.Font = Enum.Font.GothamBold
KeyInput.TextSize = 13
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false
KeyInput.Text = loadSavedKey()
KeyInput.Parent = KeyBox

local PasteKeyBtn = Instance.new("TextButton")
PasteKeyBtn.Size = UDim2.new(0, 68, 0, 28)
PasteKeyBtn.Position = UDim2.new(1, -75, 0.5, -14)
PasteKeyBtn.BackgroundColor3 = Theme.Card
PasteKeyBtn.Text = "📋 Dán"
PasteKeyBtn.TextColor3 = Theme.Accent
PasteKeyBtn.Font = Enum.Font.GothamBold
PasteKeyBtn.TextSize = 11
PasteKeyBtn.Parent = KeyBox
Instance.new("UICorner", PasteKeyBtn).CornerRadius = UDim.new(0, 7)
local PasteStroke = Instance.new("UIStroke", PasteKeyBtn)
PasteStroke.Color = Theme.Stroke
PasteStroke.Thickness = 1

local function updateKeyStatusPill()
    local clean = KeyInput.Text:gsub("%s+", "")
    if #clean >= 4 then
        KeyReadyPill.Text = "✓ Sẵn sàng"
        KeyReadyPill.TextColor3 = Theme.Success
        KeyReadyPill.BackgroundColor3 = Color3.fromRGB(12, 38, 36)
    else
        KeyReadyPill.Text = "Chưa nhập"
        KeyReadyPill.TextColor3 = Theme.TextDim
        KeyReadyPill.BackgroundColor3 = Theme.Card
    end
end
updateKeyStatusPill()
KeyInput:GetPropertyChangedSignal("Text"):Connect(updateKeyStatusPill)

PasteKeyBtn.MouseButton1Click:Connect(function()
    local ok, clip = pcall(function()
        return getclipboard and getclipboard()
    end)
    if ok and type(clip) == "string" and clip:gsub("%s+", "") ~= "" then
        KeyInput.Text = clip:gsub("%s+", "")
        showToast("📋 Đã dán mã Key từ bộ nhớ tạm!", Theme.Success)
    else
        KeyInput:CaptureFocus()
        showToast("💡 Hãy nhấn giữ vào ô để dán mã Key!", Theme.AccentNeon)
    end
end)

KeyInput.Focused:Connect(function()
    TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.AccentNeon}):Play()
end)
KeyInput.FocusLost:Connect(function()
    TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
end)

ClearKeyBtn.MouseButton1Click:Connect(function()
    KeyInput.Text = ""
    showToast("🗑️ Đã xoá ô nhập Key!", Theme.Warning)
end)

local ActivateBtn = Instance.new("TextButton")
ActivateBtn.Size = UDim2.new(1, 0, 0, 48)
ActivateBtn.Position = UDim2.new(0, 0, 0, 178)
ActivateBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT NGAY"
ActivateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActivateBtn.Font = Enum.Font.GothamBlack
ActivateBtn.TextSize = 14
ActivateBtn.Parent = Page2
Instance.new("UICorner", ActivateBtn).CornerRadius = UDim.new(0, 11)
local ActGradient = Instance.new("UIGradient", ActivateBtn)
ActGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentNeon),
    ColorSequenceKeypoint.new(0.5, Theme.AccentRoyal),
    ColorSequenceKeypoint.new(1, Theme.Purple)
})
local ActStroke = Instance.new("UIStroke", ActivateBtn)
ActStroke.Color = Theme.AccentNeon
ActStroke.Thickness = 1.4

local SubBtnRow = Instance.new("Frame")
SubBtnRow.Size = UDim2.new(1, 0, 0, 36)
SubBtnRow.Position = UDim2.new(0, 0, 0, 234)
SubBtnRow.BackgroundTransparency = 1
SubBtnRow.Parent = Page2

local CheckHwidKeyBtn = Instance.new("TextButton")
CheckHwidKeyBtn.Size = UDim2.new(0.48, -4, 1, 0)
CheckHwidKeyBtn.Position = UDim2.new(0, 0, 0, 0)
CheckHwidKeyBtn.BackgroundColor3 = Theme.Card
CheckHwidKeyBtn.Text = "🔍 Tự Lấy Key Đã Mua"
CheckHwidKeyBtn.TextColor3 = Theme.AccentNeon
CheckHwidKeyBtn.Font = Enum.Font.GothamBold
CheckHwidKeyBtn.TextSize = 11
CheckHwidKeyBtn.Parent = SubBtnRow
Instance.new("UICorner", CheckHwidKeyBtn).CornerRadius = UDim.new(0, 9)
local CheckHwidStroke = Instance.new("UIStroke", CheckHwidKeyBtn)
CheckHwidStroke.Color = Theme.Stroke
CheckHwidStroke.Thickness = 1

local WebLinkBtn = Instance.new("TextButton")
WebLinkBtn.Size = UDim2.new(0.52, -4, 1, 0)
WebLinkBtn.Position = UDim2.new(0.48, 4, 0, 0)
WebLinkBtn.BackgroundColor3 = Theme.Card
WebLinkBtn.Text = "🌐 Copy Web Mua Key"
WebLinkBtn.TextColor3 = Theme.Accent
WebLinkBtn.Font = Enum.Font.GothamBold
WebLinkBtn.TextSize = 11
WebLinkBtn.Parent = SubBtnRow
Instance.new("UICorner", WebLinkBtn).CornerRadius = UDim.new(0, 9)
local WebStroke = Instance.new("UIStroke", WebLinkBtn)
WebStroke.Color = Theme.Stroke
WebStroke.Thickness = 1

local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, 0, 0, 56)
StatusBox.Position = UDim2.new(0, 0, 0, 278)
StatusBox.BackgroundColor3 = Theme.Input
StatusBox.Parent = Page2
Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 10)
local StatusStroke = Instance.new("UIStroke", StatusBox)
StatusStroke.Color = Theme.Stroke
StatusStroke.Thickness = 1

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 1, -8)
Status.Position = UDim2.new(0, 10, 0, 4)
Status.BackgroundTransparency = 1
Status.Text = "💡 Mẹo: Đã mua Key trên Web? Bấm [🔍 Tự Lấy Key Đã Mua] để tự động điền Key theo HWID của bạn!"
Status.TextColor3 = Theme.TextDim
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 11
Status.TextWrapped = true
Status.Parent = StatusBox

local FooterHint = Instance.new("TextLabel")
FooterHint.Size = UDim2.new(1, 0, 0, 18)
FooterHint.Position = UDim2.new(0, 0, 1, -20)
FooterHint.BackgroundTransparency = 1
FooterHint.Text = "⌨️ Phím tắt PC: [RightControl] Ẩn/Hiện • [Enter] Kích hoạt"
FooterHint.TextColor3 = Theme.TextDim
FooterHint.Font = Enum.Font.GothamMedium
FooterHint.TextSize = 10
FooterHint.Parent = Page2

task.spawn(function()
    local rot = 0
    while sg and sg.Parent do
        if Main.Visible then
            rot = (rot + 2) % 360
            BorderGrad.Rotation = rot
        end
        task.wait(0.03)
    end
end)

-- ==========================================
-- DANH SÁCH GAME & CHUYỂN TRANG
-- ==========================================
local games = {
    {name = "Steal an Egg", id = "steal_egg", badge = "HOT • WORKING", desc = "Auto Steal, ESP Trứng Hiếm, Auto TP, Fly VIP"},
    {name = "Blox Fruits", id = "blox_fruits", badge = "VIP HUB", desc = "Auto Farm Level, Raid, Sea Events, Auto Mastery"},
}
local gameBtns = {}
local selectedGameId = ""

local function openGamePage(g)
    selectedGameId = g.id
    pcall(function()
        if writefile then writefile(GAME_FILE, g.id) end
    end)
    GameTitle.Text = "⚡ " .. g.name
    Status.TextColor3 = Theme.TextDim
    Status.Text = "💡 Đã chọn " .. g.name .. ". Nhập Key hoặc bấm [🔍 Tự Lấy Key Đã Mua] để kích hoạt."
    TweenService:Create(Page1, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(-1, -20, 0, 0)
    }):Play()
    TweenService:Create(Page2, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
end

for _, g in ipairs(games) do
    local Card = Instance.new("TextButton")
    Card.Size = UDim2.new(1, 0, 0, 66)
    Card.BackgroundColor3 = Theme.Card
    Card.Text = ""
    Card.AutoButtonColor = false
    Card.Parent = GameScroll
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)
    local Strk = Instance.new("UIStroke", Card)
    Strk.Color = Theme.Stroke
    Strk.Thickness = 1.2

    local IconBox = Instance.new("Frame")
    IconBox.Size = UDim2.new(0, 44, 0, 44)
    IconBox.Position = UDim2.new(0, 11, 0.5, -22)
    IconBox.BackgroundColor3 = Theme.Input
    IconBox.Parent = Card
    Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0, 10)
    local IconStroke = Instance.new("UIStroke", IconBox)
    IconStroke.Color = Theme.AccentRoyal
    IconStroke.Thickness = 1

    local IconLbl = Instance.new("TextLabel")
    IconLbl.Size = UDim2.new(1, 0, 1, 0)
    IconLbl.BackgroundTransparency = 1
    IconLbl.Text = "⚡"
    IconLbl.TextColor3 = Theme.AccentNeon
    IconLbl.Font = Enum.Font.GothamBold
    IconLbl.TextSize = 20
    IconLbl.Parent = IconBox

    local NameLbl = Instance.new("TextLabel")
    NameLbl.Size = UDim2.new(1, -170, 0, 20)
    NameLbl.Position = UDim2.new(0, 66, 0, 12)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Text = g.name
    NameLbl.TextColor3 = Theme.Text
    NameLbl.Font = Enum.Font.GothamBold
    NameLbl.TextSize = 14
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left
    NameLbl.Parent = Card

    local BadgePill = Instance.new("TextLabel")
    BadgePill.Size = UDim2.new(0, 86, 0, 18)
    BadgePill.Position = UDim2.new(1, -120, 0, 13)
    BadgePill.BackgroundColor3 = Color3.fromRGB(14, 38, 68)
    BadgePill.Text = g.badge
    BadgePill.TextColor3 = Theme.AccentNeon
    BadgePill.Font = Enum.Font.GothamBold
    BadgePill.TextSize = 9
    BadgePill.Parent = Card
    Instance.new("UICorner", BadgePill).CornerRadius = UDim.new(1, 0)

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -105, 0, 16)
    DescLbl.Position = UDim2.new(0, 66, 0, 35)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Text = g.desc
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.Font = Enum.Font.GothamMedium
    DescLbl.TextSize = 11
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.TextTruncate = Enum.TextTruncate.AtEnd
    DescLbl.Parent = Card

    local ArrowLbl = Instance.new("TextLabel")
    ArrowLbl.Size = UDim2.new(0, 28, 1, 0)
    ArrowLbl.Position = UDim2.new(1, -30, 0, 0)
    ArrowLbl.BackgroundTransparency = 1
    ArrowLbl.Text = "›"
    ArrowLbl.TextColor3 = Theme.AccentNeon
    ArrowLbl.Font = Enum.Font.GothamBold
    ArrowLbl.TextSize = 22
    ArrowLbl.Parent = Card

    Card.MouseEnter:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.2), {BackgroundColor3 = Theme.CardHover}):Play()
        TweenService:Create(Strk, TweenInfo.new(0.2), {Color = Theme.AccentNeon}):Play()
    end)
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Card}):Play()
        TweenService:Create(Strk, TweenInfo.new(0.2), {Color = Theme.Stroke}):Play()
    end)

    table.insert(gameBtns, {btn = Card, name = string.lower(g.name)})
    Card.MouseButton1Click:Connect(function()
        openGamePage(g)
    end)
end

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    GameScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 12)
end)
GameScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 12)

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = string.lower(SearchInput.Text)
    for _, item in ipairs(gameBtns) do
        item.btn.Visible = (string.find(item.name, txt, 1, true) ~= nil)
    end
end)

BackBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Page1, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    TweenService:Create(Page2, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 20, 0, 0)
    }):Play()
end)

local copyCooldown = false
CopyBtn.MouseButton1Click:Connect(function()
    if copyCooldown then return end
    copyCooldown = true
    if setclipboard then
        setclipboard(hwid)
        CopyBtn.Text = "✅ Đã Copy"
        showToast("📋 Đã copy Mã Máy (HWID) vào bộ nhớ tạm!", Theme.Success)
        TweenService:Create(CopyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.AccentRoyal}):Play()
        task.delay(1.5, function()
            if CopyBtn and CopyBtn.Parent then
                CopyBtn.Text = "📋 Copy HWID"
                TweenService:Create(CopyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Card}):Play()
            end
            copyCooldown = false
        end)
    else
        showToast("⚠️ Hãy bấm giữ vào ô HWID để copy thủ công!", Theme.Warning)
        copyCooldown = false
    end
end)

local isFetchingHwidKey = false
CheckHwidKeyBtn.MouseButton1Click:Connect(function()
    if isFetchingHwidKey then return end
    isFetchingHwidKey = true
    CheckHwidKeyBtn.Text = "⏳ Đang tìm Key..."
    Status.TextColor3 = Theme.AccentNeon
    Status.Text = "🔎 Đang kiểm tra Key bản quyền của HWID này trên Server..."
    task.spawn(function()
        local ok, resp = pcall(function()
            return game:HttpGet(API_BASE .. "/api/search_hwid?hwid=" .. url_encode(hwid))
        end)
        isFetchingHwidKey = false
        if CheckHwidKeyBtn and CheckHwidKeyBtn.Parent then
            CheckHwidKeyBtn.Text = "🔍 Tự Lấy Key Đã Mua"
        end
        if ok and resp and resp ~= "" then
            local decodeOk, data = pcall(function()
                return HttpService:JSONDecode(resp)
            end)
            if decodeOk and data and data.success and type(data.keys) == "table" and #data.keys > 0 then
                local validKey = nil
                for _, k in ipairs(data.keys) do
                    if not k.is_expired and k.key then
                        validKey = k
                        break
                    end
                end
                validKey = validKey or data.keys[1]
                if validKey and validKey.key then
                    KeyInput.Text = tostring(validKey.key)
                    saveKeyToFile(tostring(validKey.key))
                    if validKey.is_expired then
                        Status.TextColor3 = Theme.Warning
                        Status.Text = "⚠️ Tìm thấy Key [" .. tostring(validKey.key) .. "] nhưng đã hết hạn. Vui lòng gia hạn trên Web!"
                        showToast("⚠️ Key gần nhất của bạn đã hết hạn!", Theme.Warning)
                    else
                        Status.TextColor3 = Theme.Success
                        Status.Text = "✅ Đã tự động điền Key [" .. tostring(validKey.key) .. "] (" .. tostring(validKey.time_left or "Còn hạn") .. ")!"
                        showToast("🎉 Đã tìm thấy & tự điền Key bản quyền!", Theme.Success)
                    end
                    return
                end
            end
            Status.TextColor3 = Theme.Warning
            Status.Text = "⚠️ Chưa tìm thấy Key nào cho HWID này. Hãy Copy HWID và lên Web mua hoặc nhận Key Free!"
            showToast("⚠️ Không tìm thấy Key cho HWID này!", Theme.Warning)
        else
            Status.TextColor3 = Theme.Danger
            Status.Text = "❌ Không thể kết nối máy chủ tra cứu. Vui lòng thử lại sau vài giây!"
            showToast("❌ Lỗi kết nối máy chủ!", Theme.Danger)
        end
    end)
end)

WebLinkBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(WEB_STORE)
        WebLinkBtn.Text = "✅ Đã Copy Link Web!"
        Status.TextColor3 = Theme.AccentNeon
        Status.Text = "🌐 Đã copy link: " .. WEB_STORE .. " — Hãy mở trình duyệt và dán để mua Key!"
        showToast("🌐 Đã copy link Web Store vào bộ nhớ tạm!", Theme.AccentNeon)
        task.delay(2.2, function()
            if WebLinkBtn and WebLinkBtn.Parent then
                WebLinkBtn.Text = "🌐 Copy Web Mua Key"
            end
        end)
    else
        Status.TextColor3 = Theme.AccentNeon
        Status.Text = "🌐 Web mua Key: " .. WEB_STORE
    end
end)

-- ==========================================
-- LOGIC KÍCH HOẠT SCRIPT (ĐÃ FIX PATTERN KICK)
-- ==========================================
local isConnecting = false
local function triggerActivate()
    if isConnecting then return end
    local cleanKey = string.gsub(KeyInput.Text, "%s+", "")
    if cleanKey == "" then
        Status.TextColor3 = Theme.Danger
        Status.Text = "⚠️ Vui lòng nhập mã Key hoặc bấm [🔍 Tự Lấy Key Đã Mua] trước khi Kích Hoạt!"
        showToast("⚠️ Bạn chưa nhập mã Key bản quyền!", Theme.Danger)
        shakeElement(KeyBox, KeyStroke)
        return
    end
    isConnecting = true
    local elapsed = 0
    ActivateBtn.Text = "⏳ ĐANG XÁC THỰC BẢN QUYỀN..."
    
    task.spawn(function()
        while isConnecting and ActivateBtn and ActivateBtn.Parent do
            Status.TextColor3 = Theme.AccentNeon
            Status.Text = string.format("⚡ Đang kết nối máy chủ Biva Storm (%ds)...", elapsed)
            task.wait(1)
            elapsed = elapsed + 1
        end
    end)
    
    task.spawn(function()
        local url = API_BASE .. "/api/get_script?key="
            .. url_encode(cleanKey)
            .. "&hwid=" .. url_encode(hwid)
            .. "&game_id=" .. url_encode(selectedGameId)
        
        local success, code = pcall(function()
            return game:HttpGet(url)
        end)
        
        isConnecting = false
        
        if success and code and code ~= "" then
            -- NẾU SERVER TRẢ VỀ LỆNH KICK, TRÍCH XUẤT THÔNG BÁO
            if string.find(code, ":Kick%(") or string.find(code, "Kick%(") then
                local kickMsg = code:match('Kick%("([^"]+)"%)') or "❌ Key không hợp lệ hoặc đã hết hạn!"
                ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT NGAY"
                Status.TextColor3 = Theme.Danger
                Status.Text = kickMsg
                showToast(kickMsg, Theme.Danger)
                shakeElement(KeyBox, KeyStroke)
            else
                local func, err = loadstring(code)
                if func then
                    saveKeyToFile(cleanKey)
                    Status.TextColor3 = Theme.Success
                    Status.Text = "✅ Bản quyền hợp lệ! Đang khởi chạy Script..."
                    showToast("🎉 Kích hoạt thành công! Đang mở Menu...", Theme.Success)
                    task.wait(0.35)
                    closeLoader()
                    func()
                else
                    ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT NGAY"
                    Status.TextColor3 = Theme.Danger
                    Status.Text = "❌ Lỗi thực thi Script: " .. tostring(err)
                    showToast("❌ Lỗi cú pháp Script trả về!", Theme.Danger)
                end
            end
        else
            ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT NGAY"
            Status.TextColor3 = Theme.Danger
            Status.Text = "❌ Máy chủ đang khởi động lại, hãy bấm Kích Hoạt lại sau 5 giây!"
            showToast("❌ Lỗi kết nối Server! Thử lại sau 5s.", Theme.Danger)
        end
    end)
end

ActivateBtn.MouseButton1Click:Connect(triggerActivate)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        toggleMinimize()
    end
end)
