-- BIVA STORM | MULTI-GAME HUB (Mobile Optimized - No AutoFill)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hàm mã hóa URL an toàn
local function url_encode(str)
    if type(str) ~= "string" then return "" end
    return (str:gsub("([^%w ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "%%20"))
end

-- LẤY HWID AN TOÀN CHO CẢ IOS VÀ ANDROID
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

-- TẠO UI
local sg = Instance.new("ScreenGui")
sg.Name = "BivaLoaderUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui

local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0, 320, 0, 400)
f.Position = UDim2.new(0.5, -160, 0.5, -200)
f.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
f.BorderSizePixel = 0
f.Active = true
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", f)
mainStroke.Color = Color3.fromRGB(0, 255, 204)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.25

-- HỖ TRỢ KÉO THẢ
local dragging, dragInput, dragStart, startPos
f.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = f.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
f.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local titleBar = Instance.new("Frame", f)
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -45, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 204)
title.Text = "⚡ BIVA STORM HUB"
title.Font = Enum.Font.FredokaOne
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local selectedGameId = ""
local selectedGameName = ""

local gameSelectFrame = Instance.new("Frame", f)
gameSelectFrame.Size = UDim2.new(1, -24, 1, -60)
gameSelectFrame.Position = UDim2.new(0, 12, 0, 52)
gameSelectFrame.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", gameSelectFrame)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 204)
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local keyInputFrame = Instance.new("Frame", f)
keyInputFrame.Size = UDim2.new(1, -24, 1, -60)
keyInputFrame.Position = UDim2.new(0, 12, 0, 52)
keyInputFrame.BackgroundTransparency = 1
keyInputFrame.Visible = false

local keyTitle = Instance.new("TextLabel", keyInputFrame)
keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.BackgroundTransparency = 1
keyTitle.TextColor3 = Color3.fromRGB(0, 255, 204)
keyTitle.Text = "Kích hoạt: ..."
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 15

local backBtn = Instance.new("TextButton", keyInputFrame)
backBtn.Size = UDim2.new(0, 75, 0, 26)
backBtn.Position = UDim2.new(0, 0, 0, 36)
backBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 85)
backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
backBtn.Text = "<- Quay lại"
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 12
Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 6)
backBtn.MouseButton1Click:Connect(function()
    keyInputFrame.Visible = false
    gameSelectFrame.Visible = true
end)

local hwidLbl = Instance.new("TextBox", keyInputFrame)
hwidLbl.Size = UDim2.new(1, 0, 0, 30)
hwidLbl.Position = UDim2.new(0, 0, 0, 74)
hwidLbl.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
hwidLbl.TextColor3 = Color3.fromRGB(220, 230, 242)
hwidLbl.Text = "Mã Máy: " .. hwid
hwidLbl.TextEditable = false
hwidLbl.ClearTextOnFocus = false
hwidLbl.Font = Enum.Font.GothamMedium
hwidLbl.TextSize = 11
Instance.new("UICorner", hwidLbl).CornerRadius = UDim.new(0, 6)

local copyBtn = Instance.new("TextButton", keyInputFrame)
copyBtn.Size = UDim2.new(1, 0, 0, 24)
copyBtn.Position = UDim2.new(0, 0, 0, 108)
copyBtn.BackgroundTransparency = 1
copyBtn.TextColor3 = Color3.fromRGB(0, 255, 204)
copyBtn.Text = "📋 Bấm để copy Mã Máy (HWID)"
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 11
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(hwid)
        copyBtn.Text = "✅ ĐÃ COPY MÃ MÁY!"
        task.wait(2)
        copyBtn.Text = "📋 Bấm để copy Mã Máy (HWID)"
    else
        copyBtn.Text = "⚠️ Hãy bôi đen ô trên để copy!"
    end
end)

local tb = Instance.new("TextBox", keyInputFrame)
tb.Size = UDim2.new(1, 0, 0, 38)
tb.Position = UDim2.new(0, 0, 0, 140)
tb.PlaceholderText = "Nhập Key bản quyền vào đây..."
tb.PlaceholderColor3 = Color3.fromRGB(130, 140, 160)
tb.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
tb.TextColor3 = Color3.fromRGB(0, 255, 204)
tb.Font = Enum.Font.GothamBold
tb.TextSize = 13
tb.Text = ""
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)

-- (ĐÃ XÓA ĐOẠN TỰ ĐỘNG ĐIỀN KEY Ở ĐÂY)

local btn = Instance.new("TextButton", keyInputFrame)
btn.Size = UDim2.new(1, 0, 0, 42)
btn.Position = UDim2.new(0, 0, 0, 190)
btn.Text = "⚡ KÍCH HOẠT SCRIPT"
btn.BackgroundColor3 = Color3.fromRGB(0, 255, 204)
btn.TextColor3 = Color3.fromRGB(10, 15, 20)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel", keyInputFrame)
status.Size = UDim2.new(1, 0, 0, 45)
status.Position = UDim2.new(0, 0, 0, 240)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255, 65, 110)
status.Font = Enum.Font.GothamMedium
status.Text = ""
status.TextSize = 12
status.TextWrapped = true

local games = {
    {name = "Steal an Egg", id = "steal_egg"},
    {name = "Blox Fruits", id = "blox_fruits"},
}
for i, g in ipairs(games) do
    local gBtn = Instance.new("TextButton", scroll)
    gBtn.Size = UDim2.new(1, 0, 0, 42)
    gBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 44)
    gBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    gBtn.Text = "🎮  " .. g.name
    gBtn.Font = Enum.Font.GothamBold
    gBtn.TextSize = 14
    Instance.new("UICorner", gBtn).CornerRadius = UDim.new(0, 8)
    gBtn.MouseButton1Click:Connect(function()
        gameSelectFrame.Visible = false
        keyInputFrame.Visible = true
        selectedGameId = g.id
        selectedGameName = g.name
        keyTitle.Text = "Kích hoạt: " .. g.name
        status.Text = ""
    end)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

btn.MouseButton1Click:Connect(function()
    local cleanKey = string.gsub(tb.Text, "%s+", "")
    if cleanKey == "" then
        status.TextColor3 = Color3.fromRGB(255, 65, 110)
        status.Text = "⚠️ Vui lòng nhập Key trước khi kích hoạt!"
        return
    end
    btn.Text = "⏳ ĐANG TẢI..."
    btn.BackgroundColor3 = Color3.fromRGB(100, 110, 125)
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.Text = "Đang kết nối máy chủ (Có thể mất 50s nếu Server ngủ đông)..."
    
    task.spawn(function()
        local url = "https://biva-hub.onrender.com/api/get_script?key="
            .. url_encode(cleanKey)
            .. "&hwid=" .. url_encode(hwid)
            .. "&game_id=" .. url_encode(selectedGameId)
            
        local success, code = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success and code and code ~= "" then
            if string.find(code, "Kick") then
                loadstring(code)()
                btn.Text = "⚡ KÍCH HOẠT SCRIPT"
                btn.BackgroundColor3 = Color3.fromRGB(0, 255, 204)
            else
                local func, err = loadstring(code)
                if func then
                    -- (ĐÃ XÓA ĐOẠN TỰ ĐỘNG LƯU KEY Ở ĐÂY)
                    sg:Destroy()
                    func()
                else
                    btn.Text = "⚡ KÍCH HOẠT SCRIPT"
                    btn.BackgroundColor3 = Color3.fromRGB(0, 255, 204)
                    status.TextColor3 = Color3.fromRGB(255, 65, 110)
                    status.Text = "Lỗi Code: " .. tostring(err)
                end
            end
        else
            btn.Text = "⚡ KÍCH HOẠT SCRIPT"
            btn.BackgroundColor3 = Color3.fromRGB(0, 255, 204)
            status.TextColor3 = Color3.fromRGB(255, 65, 110)
            status.Text = "❌ Lỗi kết nối Server!"
        end
    end)
end)
