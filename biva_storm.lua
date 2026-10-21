-- BIVA STORM | PREMIUM LOADER UI
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hàm mã hóa URL
local function url_encode(str)
    if type(str) ~= "string" then return "" end
    return (str:gsub("([^%w ])", function(c) return string.format("%%%02X", string.byte(c)) end):gsub(" ", "%%20"))
end

-- HWID (Tự động lưu trữ)
local hwid = tostring(player.UserId)
pcall(function()
    if isfile and readfile and writefile then
        if isfile("Biva_HWID.txt") and readfile("Biva_HWID.txt") ~= "" then
            hwid = readfile("Biva_HWID.txt")
        else
            writefile("Biva_HWID.txt", hwid)
        end
    end
end)

if playerGui:FindFirstChild("BivaLoaderUI") then
    playerGui.BivaLoaderUI:Destroy()
end

-- BẢNG MÀU CHỦ ĐẠO
local Theme = {
    Main = Color3.fromRGB(12, 14, 19),
    Surface = Color3.fromRGB(22, 25, 35),
    Input = Color3.fromRGB(30, 34, 46),
    Accent = Color3.fromRGB(0, 255, 204),
    AccentHover = Color3.fromRGB(0, 255, 230),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(140, 150, 170),
    Danger = Color3.fromRGB(255, 60, 80),
    Stroke = Color3.fromRGB(45, 50, 65)
}

local sg = Instance.new("ScreenGui")
sg.Name = "BivaLoaderUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

-- KHUNG CHÍNH
local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 360, 0, 460)
Main.Position = UDim2.new(0.5, -180, 0.5, -230)
Main.BackgroundColor3 = Theme.Main
Main.BorderSizePixel = 0
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Stroke
MainStroke.Thickness = 1.5

local MainGradient = Instance.new("UIGradient", Main)
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Main),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 24, 35))
})
MainGradient.Rotation = 45

-- HÀM KÉO THẢ MƯỢT
local dragging, dragInput, dragStart, startPos
local function MakeDraggable(frame, dragArea)
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- HEADER (THANH TIÊU ĐỀ)
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundTransparency = 1
Header.Parent = Main
MakeDraggable(Main, Header)

local Logo = Instance.new("Frame", Header)
Logo.Size = UDim2.new(0, 36, 0, 36)
Logo.Position = UDim2.new(0, 20, 0.5, -18)
Logo.BackgroundColor3 = Theme.Surface
Logo.Parent = Header
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 8)
local LogoStroke = Instance.new("UIStroke", Logo)
LogoStroke.Color = Theme.Accent
LogoStroke.Thickness = 1.5

local LogoText = Instance.new("TextLabel", Logo)
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "B"
LogoText.TextColor3 = Theme.Accent
LogoText.Font = Enum.Font.FredokaOne
LogoText.TextSize = 22
LogoText.Parent = Logo

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -80, 0, 25)
Title.Position = UDim2.new(0, 65, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "BIVA STORM"
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel", Header)
Subtitle.Size = UDim2.new(1, -80, 0, 15)
Subtitle.Position = UDim2.new(0, 65, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Premium Multi-Game Hub"
Subtitle.TextColor3 = Theme.TextDim
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 12
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -45, 0.5, -15)
CloseBtn.BackgroundColor3 = Theme.Surface
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function() 
    TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 360, 0, 0)}):Play()
    task.wait(0.3)
    sg:Destroy() 
end)

-- ĐƯỜNG KẺ NGANG
local Divider = Instance.new("Frame", Main)
Divider.Size = UDim2.new(1, -40, 0, 1)
Divider.Position = UDim2.new(0, 20, 0, 60)
Divider.BackgroundColor3 = Theme.Stroke
Divider.BorderSizePixel = 0
Divider.Parent = Main

-- CONTAINER CHỨA CÁC TRANG
local Pages = Instance.new("Frame", Main)
Pages.Size = UDim2.new(1, -40, 1, -80)
Pages.Position = UDim2.new(0, 20, 0, 70)
Pages.BackgroundTransparency = 1
Pages.ClipsDescendants = true
Pages.Parent = Main

-- ==========================================
-- TRANG 1: CHỌN GAME
-- ==========================================
local Page1 = Instance.new("Frame", Pages)
Page1.Size = UDim2.new(1, 0, 1, 0)
Page1.BackgroundTransparency = 1
Page1.Parent = Pages

local SearchBox = Instance.new("Frame", Page1)
SearchBox.Size = UDim2.new(1, 0, 0, 42)
SearchBox.BackgroundColor3 = Theme.Input
SearchBox.Parent = Page1
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)
local SearchStroke = Instance.new("UIStroke", SearchBox)
SearchStroke.Color = Theme.Stroke
SearchStroke.Thickness = 1

local SearchIcon = Instance.new("TextLabel", SearchBox)
SearchIcon.Size = UDim2.new(0, 40, 1, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = 16
SearchIcon.Parent = SearchBox

local SearchInput = Instance.new("TextBox", SearchBox)
SearchInput.Size = UDim2.new(1, -45, 1, 0)
SearchInput.Position = UDim2.new(0, 40, 0, 0)
SearchInput.BackgroundTransparency = 1
SearchInput.PlaceholderText = "Tìm kiếm game..."
SearchInput.PlaceholderColor3 = Theme.TextDim
SearchInput.TextColor3 = Theme.Text
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextSize = 14
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.Text = ""
SearchInput.Parent = SearchBox

local GameScroll = Instance.new("ScrollingFrame", Page1)
GameScroll.Size = UDim2.new(1, 0, 1, -52)
GameScroll.Position = UDim2.new(0, 0, 0, 52)
GameScroll.BackgroundTransparency = 1
GameScroll.ScrollBarThickness = 3
GameScroll.ScrollBarImageColor3 = Theme.Accent
GameScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
GameScroll.Parent = Page1

local ScrollLayout = Instance.new("UIListLayout", GameScroll)
ScrollLayout.Padding = UDim.new(0, 8)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ==========================================
-- TRANG 2: NHẬP KEY
-- ==========================================
local Page2 = Instance.new("Frame", Pages)
Page2.Size = UDim2.new(1, 0, 1, 0)
Page2.Position = UDim2.new(1, 20, 0, 0) -- Ẩn bên phải
Page2.BackgroundTransparency = 1
Page2.Parent = Pages

local BackBtn = Instance.new("TextButton", Page2)
BackBtn.Size = UDim2.new(0, 80, 0, 30)
BackBtn.BackgroundColor3 = Theme.Surface
BackBtn.Text = "< Quay lại"
BackBtn.TextColor3 = Theme.TextDim
BackBtn.Font = Enum.Font.GothamBold
BackBtn.TextSize = 12
BackBtn.Parent = Page2
Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 6)

local GameTitle = Instance.new("TextLabel", Page2)
GameTitle.Size = UDim2.new(1, -90, 0, 30)
GameTitle.Position = UDim2.new(0, 90, 0, 0)
GameTitle.BackgroundTransparency = 1
GameTitle.Text = "Tên Game"
GameTitle.TextColor3 = Theme.Accent
GameTitle.Font = Enum.Font.GothamBold
GameTitle.TextSize = 16
GameTitle.TextXAlignment = Enum.TextXAlignment.Left
GameTitle.Parent = Page2

local HwidBox = Instance.new("Frame", Page2)
HwidBox.Size = UDim2.new(1, 0, 0, 45)
HwidBox.Position = UDim2.new(0, 0, 0, 45)
HwidBox.BackgroundColor3 = Theme.Input
HwidBox.Parent = Page2
Instance.new("UICorner", HwidBox).CornerRadius = UDim.new(0, 8)

local HwidLabel = Instance.new("TextLabel", HwidBox)
HwidLabel.Size = UDim2.new(1, -50, 1, 0)
HwidLabel.Position = UDim2.new(0, 10, 0, 0)
HwidLabel.BackgroundTransparency = 1
HwidLabel.Text = "HWID: " .. hwid
HwidLabel.TextColor3 = Theme.TextDim
HwidLabel.Font = Enum.Font.GothamBold
HwidLabel.TextSize = 12
HwidLabel.TextXAlignment = Enum.TextXAlignment.Left
HwidLabel.TextTruncate = Enum.TextTruncate.AtEnd
HwidLabel.Parent = HwidBox

local CopyBtn = Instance.new("TextButton", HwidBox)
CopyBtn.Size = UDim2.new(0, 40, 0, 30)
CopyBtn.Position = UDim2.new(1, -45, 0.5, -15)
CopyBtn.BackgroundColor3 = Theme.Surface
CopyBtn.Text = "📋"
CopyBtn.TextSize = 14
CopyBtn.Parent = HwidBox
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

local KeyBox = Instance.new("Frame", Page2)
KeyBox.Size = UDim2.new(1, 0, 0, 45)
KeyBox.Position = UDim2.new(0, 0, 0, 100)
KeyBox.BackgroundColor3 = Theme.Input
KeyBox.Parent = Page2
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

local KeyInput = Instance.new("TextBox", KeyBox)
KeyInput.Size = UDim2.new(1, -20, 1, 0)
KeyInput.Position = UDim2.new(0, 10, 0, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.PlaceholderText = "Dán Key bản quyền vào đây..."
KeyInput.PlaceholderColor3 = Theme.TextDim
KeyInput.TextColor3 = Theme.Accent
KeyInput.Font = Enum.Font.GothamBold
KeyInput.TextSize = 14
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.Text = ""
KeyInput.Parent = KeyBox

local ActivateBtn = Instance.new("TextButton", Page2)
ActivateBtn.Size = UDim2.new(1, 0, 0, 50)
ActivateBtn.Position = UDim2.new(0, 0, 0, 165)
ActivateBtn.BackgroundColor3 = Theme.Accent
ActivateBtn.Text = "KÍCH HOẠT SCRIPT"
ActivateBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ActivateBtn.Font = Enum.Font.GothamBold
ActivateBtn.TextSize = 15
ActivateBtn.Parent = Page2
Instance.new("UICorner", ActivateBtn).CornerRadius = UDim.new(0, 8)

local ActGradient = Instance.new("UIGradient", ActivateBtn)
ActGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 150))
})
ActGradient.Rotation = 90

local Status = Instance.new("TextLabel", Page2)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0, 225)
Status.BackgroundTransparency = 1
Status.Text = ""
Status.TextColor3 = Theme.TextDim
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 12
Status.TextWrapped = true
Status.Parent = Page2

-- ==========================================
-- LOGIC XỬ LÝ
-- ==========================================
local games = {
    {name = "Steal an Egg", id = "steal_egg"},
    {name = "Blox Fruits", id = "blox_fruits"},
}
local gameBtns = {}
local selectedGameId = ""

for _, g in ipairs(games) do
    local Btn = Instance.new("TextButton", GameScroll)
    Btn.Size = UDim2.new(1, 0, 0, 50)
    Btn.BackgroundColor3 = Theme.Surface
    Btn.Text = "  " .. g.name
    Btn.TextColor3 = Theme.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = GameScroll
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    local Strk = Instance.new("UIStroke", Btn)
    Strk.Color = Theme.Stroke
    Strk.Thickness = 1
    
    Btn.MouseEnter:Connect(function() 
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Input}):Play()
        Strk.Color = Theme.Accent
    end)
    Btn.MouseLeave:Connect(function() 
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Surface}):Play()
        Strk.Color = Theme.Stroke
    end)
    
    table.insert(gameBtns, {btn = Btn, name = string.lower(g.name)})
    
    Btn.MouseButton1Click:Connect(function()
        selectedGameId = g.id
        GameTitle.Text = g.name
        Status.Text = ""
        
        -- Hiệu ứng trượt sang trang nhập Key
        TweenService:Create(Page1, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(-1, -20, 0, 0)}):Play()
        TweenService:Create(Page2, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    end)
end

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    GameScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 10)
end)

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = string.lower(SearchInput.Text)
    for _, item in ipairs(gameBtns) do
        if string.find(item.name, txt, 1, true) then
            item.btn.Visible = true
        else
            item.btn.Visible = false
        end
    end
end)

BackBtn.MouseButton1Click:Connect(function()
    -- Hiệu ứng trượt về trang chọn Game
    TweenService:Create(Page1, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(Page2, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, 20, 0, 0)}):Play()
end)

local copyCooldown = false
CopyBtn.MouseButton1Click:Connect(function()
    if copyCooldown then return end
    copyCooldown = true
    
    if setclipboard then
        setclipboard(hwid)
        CopyBtn.Text = "✅"
        TweenService:Create(CopyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        
        task.delay(1.5, function()
            CopyBtn.Text = "📋"
            TweenService:Create(CopyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Surface}):Play()
            copyCooldown = false
        end)
    else
        Status.TextColor3 = Theme.Danger
        Status.Text = "⚠️ Executor không hỗ trợ copy, hãy tự bôi đen."
        copyCooldown = false
    end
end)

ActivateBtn.MouseEnter:Connect(function()
    TweenService:Create(ActivateBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.AccentHover}):Play()
end)
ActivateBtn.MouseLeave:Connect(function()
    TweenService:Create(ActivateBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
end)

ActivateBtn.MouseButton1Click:Connect(function()
    local cleanKey = string.gsub(KeyInput.Text, "%s+", "")
    if cleanKey == "" then
        Status.TextColor3 = Theme.Danger
        Status.Text = "⚠️ Vui lòng nhập Key trước!"
        return
    end
    
    ActivateBtn.Text = "ĐANG KẾT NỐI..."
    ActivateBtn.BackgroundColor3 = Theme.Surface
    ActivateBtn.TextColor3 = Theme.TextDim
    Status.TextColor3 = Theme.Text
    Status.Text = "Đang xác thực (có thể mất 50s nếu Server ngủ đông)..."
    
    task.spawn(function()
        local url = "https://biva-hub.onrender.com/api/get_script?key="
            .. url_encode(cleanKey)
            .. "&hwid=" .. url_encode(hwid)
            .. "&game_id=" .. url_encode(selectedGameId)
            
        local success, code = pcall(function() return game:HttpGet(url) end)
        
        if success and code and code ~= "" then
            if string.find(code, "Kick") then
                loadstring(code)()
                ActivateBtn.Text = "KÍCH HOẠT SCRIPT"
                ActivateBtn.BackgroundColor3 = Theme.Accent
                ActivateBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            else
                local func, err = loadstring(code)
                if func then
                    TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 360, 0, 0)}):Play()
                    task.wait(0.3)
                    sg:Destroy()
                    func()
                else
                    ActivateBtn.Text = "KÍCH HOẠT SCRIPT"
                    ActivateBtn.BackgroundColor3 = Theme.Accent
                    ActivateBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    Status.TextColor3 = Theme.Danger
                    Status.Text = "Lỗi Code: " .. tostring(err)
                end
            end
        else
            ActivateBtn.Text = "KÍCH HOẠT SCRIPT"
            ActivateBtn.BackgroundColor3 = Theme.Accent
            ActivateBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            Status.TextColor3 = Theme.Danger
            Status.Text = "❌ Lỗi kết nối Server!"
        end
    end)
end)
