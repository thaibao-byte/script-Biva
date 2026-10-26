-- File: biva_storm.lua
-- =========================================================
-- ⚡ BIVA STORM | CYBER LOADER UI V25 OMNI
-- Đồng bộ Server V25 • Tự Nhận BIVA_AUTO_KEY • Đổi Máy (Reset HWID) Trực Tiếp Trong Game
-- =========================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Hệ thống Dual-Endpoint tự động chuyển đổi nếu 1 trong 2 link đang ngủ đông
local API_LIST = {
    "https://biva-hub.onrender.com",
    "https://bivastorm-web.onrender.com"
}
local API_BASE = API_LIST[1]
local WEB_STORE = "https://bivastorm-web.onrender.com"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if _G.BivaLoaderCleanup then
    pcall(_G.BivaLoaderCleanup)
end
if _G.BivaLoaderV25Cleanup then
    pcall(_G.BivaLoaderV25Cleanup)
end

local Connections = {}
local isLoaderAlive = true

local function trackConn(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

local function cleanupAllConnections()
    isLoaderAlive = false
    for _, conn in ipairs(Connections) do
        pcall(function()
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end)
    end
    table.clear(Connections)
end

local function getGuiParent()
    local ok, hui = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if ok and hui then return hui end
    return playerGui
end

-- Hàm kiểm tra chuỗi hợp lệ (Tuyệt đối không dùng dấu ngã để chống lỗi trình soạn thảo xóa ký tự)
local function isNonEmptyStr(s)
    return type(s) == "string" and not (s == "")
end

-- Chuẩn hóa HWID & Key đồng bộ tuyệt đối với server.py V25
local function normalizeHwidStr(s)
    if not (type(s) == "string") then return "" end
    local clean = s:gsub("%s+", ""):gsub("[^%w%-]", ""):upper()
    return clean:sub(1, 64)
end

local function normalizeKeyStr(s)
    if not (type(s) == "string") then return "" end
    local clean = s:gsub("%s+", ""):gsub("[^%w%-_]", ""):upper()
    return clean:sub(1, 64)
end

-- Mã hóa URL chuẩn RFC 3986
local function url_encode(str)
    if not (type(str) == "string") then
        return ""
    end
    local clean = str:gsub("\r\n", "\n")
    local encoded = clean:gsub("([^%w%-%.%_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return encoded
end

-- Gọi HTTP thông minh: Hỗ trợ mọi Executor + trả về cả phản hồi lỗi JSON nếu có
local function safeHttpRequest(url)
    local reqFunc = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)

    if reqFunc then
        local okReq, resp = pcall(function()
            return reqFunc({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json, text/plain, */*",
                    ["Cache-Control"] = "no-cache"
                }
            })
        end)
        if okReq and type(resp) == "table" then
            local code = tonumber(resp.StatusCode) or 200
            if isNonEmptyStr(resp.Body) then
                if code >= 200 and code < 300 then
                    return true, tostring(resp.Body)
                elseif tostring(resp.Body):sub(1, 1) == "{" then
                    return true, tostring(resp.Body)
                end
            end
        end
    end

    local okGet, resGet = pcall(function()
        return game:HttpGet(url)
    end)
    if okGet and isNonEmptyStr(resGet) then
        return true, resGet
    end
    return false, nil
end

local function apiGet(pathAndQuery, retries)
    local maxAttempts = retries or 2
    for attempt = 1, maxAttempts do
        local ok, body = safeHttpRequest(API_BASE .. pathAndQuery)
        if ok and isNonEmptyStr(body) then
            return true, body
        end
        for _, base in ipairs(API_LIST) do
            if not (base == API_BASE) then
                local okBackup, bodyBackup = safeHttpRequest(base .. pathAndQuery)
                if okBackup and isNonEmptyStr(bodyBackup) then
                    API_BASE = base
                    return true, bodyBackup
                end
            end
        end
        if attempt < maxAttempts then
            task.wait(1.0)
        end
    end
    return false, nil
end

-- Quản lý lưu trữ HWID, Key & Game gần nhất tự động
local HWID_FILE = "Biva_HWID.txt"
local KEY_FILE = "Biva_SavedKey.txt"
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
    if not isNonEmptyStr(id) then
        id = "BIVA" .. tostring(player.UserId)
    end
    return normalizeHwidStr(id)
end

local hwid = detectHWID()
pcall(function()
    if isfile and readfile and writefile then
        if isfile(HWID_FILE) then
            local savedHwid = normalizeHwidStr(readfile(HWID_FILE))
            if isNonEmptyStr(savedHwid) then
                hwid = savedHwid
            else
                writefile(HWID_FILE, hwid)
            end
        else
            writefile(HWID_FILE, hwid)
        end
    end
end)

local function loadSavedFile(fileName)
    local saved = ""
    pcall(function()
        if isfile and readfile and isfile(fileName) then
            saved = readfile(fileName):gsub("%s+", "")
        end
    end)
    return saved or ""
end

local function saveToFile(fileName, content)
    pcall(function()
        if writefile and content then
            writefile(fileName, tostring(content))
        end
    end)
end

-- Tự động nhận BIVA_AUTO_KEY nếu người chơi copy lệnh kèm sẵn Key từ Web V25
local envAutoKey = ""
pcall(function()
    local genv = (getgenv and getgenv()) or _G
    if type(genv) == "table" and isNonEmptyStr(genv.BIVA_AUTO_KEY) then
        envAutoKey = normalizeKeyStr(tostring(genv.BIVA_AUTO_KEY))
    elseif isNonEmptyStr(_G.BIVA_AUTO_KEY) then
        envAutoKey = normalizeKeyStr(tostring(_G.BIVA_AUTO_KEY))
    end
end)
if isNonEmptyStr(envAutoKey) then
    saveToFile(KEY_FILE, envAutoKey)
end

-- Xóa UI & Blur cũ nếu đang tồn tại
local guiParent = getGuiParent()
for _, container in ipairs({guiParent, playerGui}) do
    pcall(function()
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ScreenGui") and string.find(child.Name, "^BivaLoaderUI") then
                child:Destroy()
            end
        end
    end)
end
if Lighting:FindFirstChild("BivaCyberBlur") then
    pcall(function() Lighting.BivaCyberBlur:Destroy() end)
end

-- Bảng màu Cyber Blue V25 Supreme (Sắc độ Xanh Dương - Neon Cyan - Royal Indigo)
local Theme = {
    BgDark = Color3.fromRGB(4, 8, 18),
    BgBottom = Color3.fromRGB(9, 16, 34),
    Card = Color3.fromRGB(13, 22, 42),
    CardHover = Color3.fromRGB(20, 34, 64),
    Input = Color3.fromRGB(6, 11, 24),
    Accent = Color3.fromRGB(59, 130, 246),
    AccentNeon = Color3.fromRGB(0, 229, 255),
    AccentRoyal = Color3.fromRGB(37, 99, 235),
    Indigo = Color3.fromRGB(99, 102, 241),
    Success = Color3.fromRGB(56, 189, 248),
    Danger = Color3.fromRGB(244, 63, 94),
    Warning = Color3.fromRGB(245, 158, 11),
    Text = Color3.fromRGB(248, 250, 252),
    TextDim = Color3.fromRGB(148, 163, 184),
    Stroke = Color3.fromRGB(30, 58, 138)
}

local Blur = Instance.new("BlurEffect")
Blur.Name = "BivaCyberBlur"
Blur.Size = 0
Blur.Parent = Lighting
TweenService:Create(Blur, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = 15}):Play()

local sg = Instance.new("ScreenGui")
sg.Name = "BivaLoaderUI_V25"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = guiParent

local function fullCleanup()
    cleanupAllConnections()
    if Blur and Blur.Parent then Blur:Destroy() end
    if sg and sg.Parent then sg:Destroy() end
end
_G.BivaLoaderCleanup = fullCleanup
_G.BivaLoaderV25Cleanup = fullCleanup

local function AddButtonRipple(btn)
    btn.ClipsDescendants = true
    trackConn(btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local relX = input.Position.X - absPos.X
            local relY = input.Position.Y - absPos.Y
            local maxRadius = math.max(absSize.X, absSize.Y) * 2.2
            local ripple = Instance.new("Frame")
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.Position = UDim2.new(0, relX, 0, relY)
            ripple.AnchorPoint = Vector2.new(0.5, 0.5)
            ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ripple.BackgroundTransparency = 0.78
            ripple.BorderSizePixel = 0
            ripple.ZIndex = btn.ZIndex + 2
            ripple.Parent = btn
            Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
            local tw = TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, maxRadius, 0, maxRadius),
                BackgroundTransparency = 1
            })
            tw:Play()
            task.delay(0.42, function()
                if ripple and ripple.Parent then
                    ripple:Destroy()
                end
            end)
        end
    end))
end

local function MakeDraggable(frame, dragArea)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    local lastDragEndTime = 0

    trackConn(dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end))

    trackConn(dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    trackConn(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then
                lastDragEndTime = os.clock()
            end
            local cam = Workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
            local absX = vp.X * startPos.X.Scale + startPos.X.Offset + delta.X
            local absY = vp.Y * startPos.Y.Scale + startPos.Y.Offset + delta.Y
            local clampedX = math.clamp(absX, 24, math.max(24, vp.X - 24))
            local clampedY = math.clamp(absY, 24, math.max(24, vp.Y - 24))
            TweenService:Create(frame, TweenInfo.new(0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, clampedX, 0, clampedY)
            }):Play()
        end
    end))

    return function()
        return (os.clock() - lastDragEndTime) < 0.25
    end
end

-- NÚT THU GỌN NỔI (FLOATING ORB V25)
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 54, 0, 54)
FloatBtn.Position = UDim2.new(0, 26, 0.5, 0)
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
FloatStroke.Thickness = 2.2
local wasFloatDragged = MakeDraggable(FloatBtn, FloatBtn)

-- KHUNG CHÍNH (MAIN CONTAINER)
local MAIN_W, MAIN_H = 436, 540
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
local camConn = nil

local function updateResponsiveScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local scaleH = (vp.Y - 24) / MAIN_H
    local scaleW = (vp.X - 20) / MAIN_W
    MainScale.Scale = math.clamp(math.min(scaleH, scaleW, 1), 0.55, 1)
end

local function bindCameraViewport()
    if camConn and camConn.Connected then
        camConn:Disconnect()
    end
    local cam = Workspace.CurrentCamera
    if cam then
        updateResponsiveScale()
        camConn = trackConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
    end
end
bindCameraViewport()
trackConn(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCameraViewport))

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 2
MainStroke.Color = Color3.new(1, 1, 1)

local BorderGrad = Instance.new("UIGradient", MainStroke)
BorderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentNeon),
    ColorSequenceKeypoint.new(0.5, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.Indigo)
})

local MainGradient = Instance.new("UIGradient", Main)
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.BgDark),
    ColorSequenceKeypoint.new(1, Theme.BgBottom)
})
MainGradient.Rotation = 45

TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, MAIN_W, 0, MAIN_H)
}):Play()

-- TOAST NOTIFICATION TRONG MENU
local ToastFrame = Instance.new("Frame")
ToastFrame.Size = UDim2.new(1, -36, 0, 36)
ToastFrame.Position = UDim2.new(0, 18, 0, -48)
ToastFrame.BackgroundColor3 = Theme.Card
ToastFrame.ZIndex = 40
ToastFrame.Parent = Main
Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 10)
local ToastStroke = Instance.new("UIStroke", ToastFrame)
ToastStroke.Color = Theme.AccentNeon
ToastStroke.Thickness = 1.4

local ToastLabel = Instance.new("TextLabel")
ToastLabel.Size = UDim2.new(1, -20, 1, 0)
ToastLabel.Position = UDim2.new(0, 10, 0, 0)
ToastLabel.BackgroundTransparency = 1
ToastLabel.Text = "⚡ Thông báo"
ToastLabel.TextColor3 = Theme.Text
ToastLabel.Font = Enum.Font.GothamBold
ToastLabel.TextSize = 12
ToastLabel.TextTruncate = Enum.TextTruncate.AtEnd
ToastLabel.ZIndex = 41
ToastLabel.Parent = ToastFrame

local toastId = 0
local function showToast(msg, color)
    toastId = toastId + 1
    local currentId = toastId
    ToastLabel.Text = tostring(msg)
    ToastStroke.Color = color or Theme.AccentNeon
    TweenService:Create(ToastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 18, 0, 14)
    }):Play()
    task.delay(2.5, function()
        if toastId == currentId and ToastFrame and ToastFrame.Parent then
            TweenService:Create(ToastFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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
            task.wait(0.03)
        end
        if guiObj and guiObj.Parent then
            guiObj.Position = origPos
        end
    end)
end

-- ==========================================
-- HEADER V25 OMNI
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
VersionBadge.Size = UDim2.new(0, 86, 0, 17)
VersionBadge.Position = UDim2.new(0, 186, 0, 14)
VersionBadge.BackgroundColor3 = Color3.new(1, 1, 1)
VersionBadge.Text = "V25 OMNI"
VersionBadge.TextColor3 = Color3.new(1, 1, 1)
VersionBadge.Font = Enum.Font.GothamBold
VersionBadge.TextSize = 9
VersionBadge.Parent = Header
Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(0, 6)
local BadgeGrad = Instance.new("UIGradient", VersionBadge)
BadgeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentNeon),
    ColorSequenceKeypoint.new(1, Theme.AccentRoyal)
})

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -165, 0, 16)
Subtitle.Position = UDim2.new(0, 68, 0, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "● Hệ thống tự động 24/7 • PayOS V25 Auto"
Subtitle.TextColor3 = Theme.Accent
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.TextTruncate = Enum.TextTruncate.AtEnd
Subtitle.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -86, 0.5, -16)
MinBtn.BackgroundColor3 = Theme.Card
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.AccentNeon
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 9)
local MinStroke = Instance.new("UIStroke", MinBtn)
MinStroke.Color = Theme.Stroke
MinStroke.Thickness = 1

local isMinimized = false
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
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
FloatBtn.MouseButton1Click:Connect(function()
    if wasFloatDragged and wasFloatDragged() then
        return
    end
    toggleMinimize()
end)

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
    cleanupAllConnections()
    TweenService:Create(Blur, TweenInfo.new(0.22), {Size = 0}):Play()
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, MAIN_W, 0, 0)
    }):Play()
    task.wait(0.23)
    if Blur and Blur.Parent then Blur:Destroy() end
    if sg and sg.Parent then sg:Destroy() end
end
CloseBtn.MouseButton1Click:Connect(closeLoader)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -36, 0, 1)
Divider.Position = UDim2.new(0, 18, 0, 64)
Divider.BackgroundColor3 = Theme.Stroke
Divider.BorderSizePixel = 0
Divider.Parent = Main

-- THẺ HỒ SƠ NGƯỜI CHƠI + FPS & PING REALTIME
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, -36, 0, 52)
ProfileCard.Position = UDim2.new(0, 18, 0, 73)
ProfileCard.BackgroundColor3 = Theme.Card
ProfileCard.Parent = Main
Instance.new("UICorner", ProfileCard).CornerRadius = UDim.new(0, 12)
local ProfStroke = Instance.new("UIStroke", ProfileCard)
ProfStroke.Color = Theme.Stroke
ProfStroke.Thickness = 1

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 36, 0, 36)
AvatarImg.Position = UDim2.new(0, 9, 0.5, -18)
AvatarImg.BackgroundColor3 = Theme.Input
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
AvatarImg.Parent = ProfileCard
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
local AvStroke = Instance.new("UIStroke", AvatarImg)
AvStroke.Color = Theme.AccentNeon
AvStroke.Thickness = 1.2

local UserTitle = Instance.new("TextLabel")
UserTitle.Size = UDim2.new(1, -170, 0, 18)
UserTitle.Position = UDim2.new(0, 54, 0, 8)
UserTitle.BackgroundTransparency = 1
UserTitle.Text = player.DisplayName .. " (@" .. player.Name .. ")"
UserTitle.TextColor3 = Theme.Text
UserTitle.Font = Enum.Font.GothamBold
UserTitle.TextSize = 12
UserTitle.TextXAlignment = Enum.TextXAlignment.Left
UserTitle.TextTruncate = Enum.TextTruncate.AtEnd
UserTitle.Parent = ProfileCard

local UserSub = Instance.new("TextLabel")
UserSub.Size = UDim2.new(1, -170, 0, 15)
UserSub.Position = UDim2.new(0, 54, 0, 27)
UserSub.BackgroundTransparency = 1
UserSub.Text = "🛡️ HWID: " .. hwid:sub(1, 12) .. (string.len(hwid) > 12 and "..." or "")
UserSub.TextColor3 = Theme.TextDim
UserSub.Font = Enum.Font.GothamMedium
UserSub.TextSize = 11
UserSub.TextXAlignment = Enum.TextXAlignment.Left
UserSub.Parent = ProfileCard

local OnlinePill = Instance.new("TextLabel")
OnlinePill.Size = UDim2.new(0, 104, 0, 26)
OnlinePill.Position = UDim2.new(1, -112, 0.5, -13)
OnlinePill.BackgroundColor3 = Color3.fromRGB(14, 30, 64)
OnlinePill.Text = "⚡ 60 FPS • --ms"
OnlinePill.TextColor3 = Theme.AccentNeon
OnlinePill.Font = Enum.Font.GothamBold
OnlinePill.TextSize = 10
OnlinePill.Parent = ProfileCard
Instance.new("UICorner", OnlinePill).CornerRadius = UDim.new(0, 8)
local PillStroke = Instance.new("UIStroke", OnlinePill)
PillStroke.Color = Theme.AccentRoyal
PillStroke.Thickness = 1

local currentPingStr = "--ms"
local fpsCount = 0
local lastFpsTime = os.clock()
local currentFps = 60
local borderAngle = 0

trackConn(RunService.RenderStepped:Connect(function(dt)
    fpsCount = fpsCount + 1
    local now = os.clock()
    if now - lastFpsTime >= 0.5 then
        currentFps = math.clamp(math.floor(fpsCount / (now - lastFpsTime) + 0.5), 1, 240)
        fpsCount = 0
        lastFpsTime = now
        if Main.Visible and OnlinePill and OnlinePill.Parent then
            OnlinePill.Text = string.format("⚡ %d FPS • %s", currentFps, currentPingStr)
        end
    end
    if Main.Visible then
        borderAngle = (borderAngle + dt * 65) % 360
        BorderGrad.Rotation = borderAngle
    end
end))

task.spawn(function()
    while isLoaderAlive and sg and sg.Parent do
        if Main.Visible then
            local t0 = os.clock()
            local ok, resp = apiGet("/api/public_stats", 1)
            local ms = math.max(11, math.floor((os.clock() - t0) * 1000))
            if ok and OnlinePill and OnlinePill.Parent then
                currentPingStr = tostring(ms) .. "ms"
                OnlinePill.TextColor3 = Theme.AccentNeon
                if isNonEmptyStr(resp) and Subtitle and Subtitle.Parent then
                    local decOk, data = pcall(function() return HttpService:JSONDecode(resp) end)
                    if decOk and type(data) == "table" and isNonEmptyStr(data.admin_notice) then
                        Subtitle.Text = "● " .. tostring(data.admin_notice)
                        Subtitle.TextColor3 = data.maintenance and Theme.Warning or Theme.Accent
                    end
                end
            elseif OnlinePill and OnlinePill.Parent then
                currentPingStr = "Wake"
                OnlinePill.TextColor3 = Theme.Warning
            end
        end
        task.wait(15)
    end
end)

-- CONTAINER CHỨA CÁC TRANG
local Pages = Instance.new("Frame")
Pages.Size = UDim2.new(1, -36, 1, -145)
Pages.Position = UDim2.new(0, 18, 0, 134)
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
SectionLbl.TextColor3 = Theme.AccentNeon
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
GameScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
GameScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
GameScroll.Parent = Page1

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Padding = UDim.new(0, 10)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Parent = GameScroll

-- ==========================================
-- TRANG 2: NHẬP KEY & KÍCH HOẠT V25 OMNI
-- ==========================================
local Page2 = Instance.new("Frame")
Page2.Size = UDim2.new(1, 0, 1, 0)
Page2.Position = UDim2.new(1, 20, 0, 0)
Page2.BackgroundTransparency = 1
Page2.Parent = Pages

local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(0, 94, 0, 30)
BackBtn.BackgroundColor3 = Theme.Card
BackBtn.Text = "← Chọn Game"
BackBtn.TextColor3 = Theme.AccentNeon
BackBtn.Font = Enum.Font.GothamBold
BackBtn.TextSize = 11
BackBtn.Parent = Page2
Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 8)
local BackStroke = Instance.new("UIStroke", BackBtn)
BackStroke.Color = Theme.Stroke
BackStroke.Thickness = 1
AddButtonRipple(BackBtn)

local GameTitle = Instance.new("TextLabel")
GameTitle.Size = UDim2.new(1, -102, 0, 30)
GameTitle.Position = UDim2.new(0, 102, 0, 0)
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
HwidLabel.Size = UDim2.new(1, -104, 1, 0)
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
CopyBtn.Size = UDim2.new(0, 88, 0, 28)
CopyBtn.Position = UDim2.new(1, -95, 0.5, -14)
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
AddButtonRipple(CopyBtn)

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
KeyReadyPill.Size = UDim2.new(0, 136, 0, 16)
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
KeyInput.Text = isNonEmptyStr(envAutoKey) and envAutoKey or normalizeKeyStr(loadSavedFile(KEY_FILE))
KeyInput.Parent = KeyBox

local PasteKeyBtn = Instance.new("TextButton")
PasteKeyBtn.Size = UDim2.new(0, 68, 0, 28)
PasteKeyBtn.Position = UDim2.new(1, -75, 0.5, -14)
PasteKeyBtn.BackgroundColor3 = Theme.Card
PasteKeyBtn.Text = "📋 Dán"
PasteKeyBtn.TextColor3 = Theme.AccentNeon
PasteKeyBtn.Font = Enum.Font.GothamBold
PasteKeyBtn.TextSize = 11
PasteKeyBtn.Parent = KeyBox
Instance.new("UICorner", PasteKeyBtn).CornerRadius = UDim.new(0, 7)
local PasteStroke = Instance.new("UIStroke", PasteKeyBtn)
PasteStroke.Color = Theme.Stroke
PasteStroke.Thickness = 1
AddButtonRipple(PasteKeyBtn)

local function updateKeyStatusPill()
    local clean = normalizeKeyStr(KeyInput.Text)
    if #clean >= 4 then
        KeyReadyPill.Text = "✓ Sẵn sàng"
        KeyReadyPill.TextColor3 = Theme.AccentNeon
        KeyReadyPill.BackgroundColor3 = Color3.fromRGB(14, 32, 68)
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
    local cleaned = normalizeKeyStr(clip)
    if ok and isNonEmptyStr(cleaned) then
        KeyInput.Text = cleaned
        showToast("📋 Đã dán mã Key từ bộ nhớ tạm!", Theme.AccentNeon)
    else
        KeyInput:CaptureFocus()
        showToast("💡 Hãy nhấn giữ vào ô để dán mã Key!", Theme.AccentNeon)
    end
end)

KeyInput.Focused:Connect(function()
    TweenService:Create(KeyStroke, TweenInfo.new(0.2), {Color = Theme.AccentNeon}):Play()
end)
KeyInput.FocusLost:Connect(function()
    KeyInput.Text = normalizeKeyStr(KeyInput.Text)
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
ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT V25 NGAY"
ActivateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ActivateBtn.Font = Enum.Font.GothamBlack
ActivateBtn.TextSize = 14
ActivateBtn.Parent = Page2
Instance.new("UICorner", ActivateBtn).CornerRadius = UDim.new(0, 11)
local ActGradient = Instance.new("UIGradient", ActivateBtn)
ActGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentNeon),
    ColorSequenceKeypoint.new(0.5, Theme.AccentRoyal),
    ColorSequenceKeypoint.new(1, Theme.Indigo)
})
local ActStroke = Instance.new("UIStroke", ActivateBtn)
ActStroke.Color = Theme.AccentNeon
ActStroke.Thickness = 1.4
AddButtonRipple(ActivateBtn)

local SubBtnRow = Instance.new("Frame")
SubBtnRow.Size = UDim2.new(1, 0, 0, 36)
SubBtnRow.Position = UDim2.new(0, 0, 0, 234)
SubBtnRow.BackgroundTransparency = 1
SubBtnRow.Parent = Page2

local CheckHwidKeyBtn = Instance.new("TextButton")
CheckHwidKeyBtn.Size = UDim2.new(0.35, -4, 1, 0)
CheckHwidKeyBtn.Position = UDim2.new(0, 0, 0, 0)
CheckHwidKeyBtn.BackgroundColor3 = Theme.Card
CheckHwidKeyBtn.Text = "🔍 Tự Lấy Key"
CheckHwidKeyBtn.TextColor3 = Theme.AccentNeon
CheckHwidKeyBtn.Font = Enum.Font.GothamBold
CheckHwidKeyBtn.TextSize = 11
CheckHwidKeyBtn.Parent = SubBtnRow
Instance.new("UICorner", CheckHwidKeyBtn).CornerRadius = UDim.new(0, 9)
local CheckHwidStroke = Instance.new("UIStroke", CheckHwidKeyBtn)
CheckHwidStroke.Color = Theme.Stroke
CheckHwidStroke.Thickness = 1
AddButtonRipple(CheckHwidKeyBtn)

local ResetHwidBtn = Instance.new("TextButton")
ResetHwidBtn.Size = UDim2.new(0.31, -4, 1, 0)
ResetHwidBtn.Position = UDim2.new(0.35, 2, 0, 0)
ResetHwidBtn.BackgroundColor3 = Theme.Card
ResetHwidBtn.Text = "🔓 Đổi Máy"
ResetHwidBtn.TextColor3 = Theme.Warning
ResetHwidBtn.Font = Enum.Font.GothamBold
ResetHwidBtn.TextSize = 11
ResetHwidBtn.Parent = SubBtnRow
Instance.new("UICorner", ResetHwidBtn).CornerRadius = UDim.new(0, 9)
local ResetHwidStroke = Instance.new("UIStroke", ResetHwidBtn)
ResetHwidStroke.Color = Theme.Stroke
ResetHwidStroke.Thickness = 1
AddButtonRipple(ResetHwidBtn)

local WebLinkBtn = Instance.new("TextButton")
WebLinkBtn.Size = UDim2.new(0.34, -2, 1, 0)
WebLinkBtn.Position = UDim2.new(0.66, 2, 0, 0)
WebLinkBtn.BackgroundColor3 = Theme.Card
WebLinkBtn.Text = "🌐 Copy Web"
WebLinkBtn.TextColor3 = Theme.Accent
WebLinkBtn.Font = Enum.Font.GothamBold
WebLinkBtn.TextSize = 11
WebLinkBtn.Parent = SubBtnRow
Instance.new("UICorner", WebLinkBtn).CornerRadius = UDim.new(0, 9)
local WebStroke = Instance.new("UIStroke", WebLinkBtn)
WebStroke.Color = Theme.Stroke
WebStroke.Thickness = 1
AddButtonRipple(WebLinkBtn)

local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, 0, 0, 58)
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
Status.Text = "💡 Mẹo V25: Bấm [🔍 Tự Lấy Key] để tự điền Key theo HWID hoặc [🔓 Đổi Máy] nếu bạn chuyển thiết bị mới!"
Status.TextColor3 = Theme.TextDim
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 11
Status.TextWrapped = true
Status.Parent = StatusBox

local FooterHint = Instance.new("TextLabel")
FooterHint.Size = UDim2.new(1, 0, 0, 18)
FooterHint.Position = UDim2.new(0, 0, 1, -20)
FooterHint.BackgroundTransparency = 1
FooterHint.Text = "⌨️ Phím tắt PC: [RightControl] Ẩn/Hiện • [Enter] Kích hoạt ngay"
FooterHint.TextColor3 = Theme.TextDim
FooterHint.Font = Enum.Font.GothamMedium
FooterHint.TextSize = 10
FooterHint.Parent = Page2

local lastVerifiedTimeLeft = ""
local lastVerifiedTier = ""
local lastVerifiedNotice = ""
local lastVerifiedExpire = ""

-- Tự động kiểm tra ngầm thời hạn của Key đã lưu khi mở Trang 2
local function checkSavedKeyValiditySilent()
    local savedK = normalizeKeyStr(KeyInput.Text)
    if #savedK < 4 then return end
    task.spawn(function()
        local ok, resp = apiGet("/api/verify_key?key=" .. url_encode(savedK) .. "&hwid=" .. url_encode(hwid), 1)
        if ok and isNonEmptyStr(resp) and KeyReadyPill and KeyReadyPill.Parent then
            local decOk, data = pcall(function() return HttpService:JSONDecode(resp) end)
            if decOk and type(data) == "table" and data.success then
                if isNonEmptyStr(data.time_left) then
                    lastVerifiedTimeLeft = tostring(data.time_left)
                end
                if isNonEmptyStr(data.tier_label) then
                    lastVerifiedTier = tostring(data.tier_label)
                end
                if isNonEmptyStr(data.admin_notice) then
                    lastVerifiedNotice = tostring(data.admin_notice)
                end
                if isNonEmptyStr(data.expire_str or data.expire_date) then
                    lastVerifiedExpire = tostring(data.expire_str or data.expire_date)
                end
                if data.is_banned then
                    KeyReadyPill.Text = "🚫 Bị khóa"
                    KeyReadyPill.TextColor3 = Theme.Danger
                elseif data.is_expired then
                    KeyReadyPill.Text = "⏰ Đã hết hạn"
                    KeyReadyPill.TextColor3 = Theme.Warning
                elseif not data.hwid_match then
                    KeyReadyPill.Text = "🔒 Khác HWID"
                    KeyReadyPill.TextColor3 = Theme.Danger
                else
                    KeyReadyPill.Text = "✓ " .. tostring(data.time_left or data.remaining_text or "Còn hạn")
                    KeyReadyPill.TextColor3 = Theme.AccentNeon
                end
            end
        end
    end)
end

-- ==========================================
-- DANH SÁCH GAME & CHUYỂN TRANG MƯỢT
-- ==========================================
local lastPlayedGameId = loadSavedFile(GAME_FILE)
local games = {
    {name = "Steal an Egg", id = "steal_egg", badge = "V25 OMNI", desc = "Auto Steal V25, Player Avoid, Rare Alert, ESP Radar"},
    {name = "Blox Fruits", id = "blox_fruits", badge = "VIP HUB", desc = "Auto Farm Level, Raid, Sea Events, Auto Mastery"},
}

local gameBtns = {}
local selectedGameId = ""
local onPage2 = false

local function openGamePage(g)
    selectedGameId = g.id
    onPage2 = true
    saveToFile(GAME_FILE, g.id)
    GameTitle.Text = "⚡ " .. g.name
    Status.TextColor3 = Theme.TextDim
    if isNonEmptyStr(envAutoKey) then
        Status.TextColor3 = Theme.AccentNeon
        Status.Text = "⚡ Đã tự động nạp mã Key [" .. envAutoKey .. "] từ lệnh Auto-Key! Bấm Kích Hoạt ngay."
    else
        Status.Text = "💡 Đã chọn " .. g.name .. ". Nhập Key hoặc bấm [🔍 Tự Lấy Key] để kích hoạt."
    end
    TweenService:Create(Page1, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(-1, -20, 0, 0)
    }):Play()
    TweenService:Create(Page2, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    checkSavedKeyValiditySilent()
end

for idx, g in ipairs(games) do
    local isRecent = (lastPlayedGameId == g.id)
    local Card = Instance.new("TextButton")
    Card.Size = UDim2.new(1, 0, 0, 68)
    Card.LayoutOrder = isRecent and 0 or idx
    Card.BackgroundColor3 = Theme.Card
    Card.Text = ""
    Card.AutoButtonColor = false
    Card.Parent = GameScroll
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)
    local Strk = Instance.new("UIStroke", Card)
    Strk.Color = isRecent and Theme.AccentNeon or Theme.Stroke
    Strk.Thickness = isRecent and 1.5 or 1.2
    AddButtonRipple(Card)

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
    NameLbl.Size = UDim2.new(1, -180, 0, 20)
    NameLbl.Position = UDim2.new(0, 66, 0, 12)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Text = g.name
    NameLbl.TextColor3 = Theme.Text
    NameLbl.Font = Enum.Font.GothamBold
    NameLbl.TextSize = 14
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left
    NameLbl.Parent = Card

    local BadgePill = Instance.new("TextLabel")
    BadgePill.Size = UDim2.new(0, 96, 0, 18)
    BadgePill.Position = UDim2.new(1, -128, 0, 13)
    BadgePill.BackgroundColor3 = Color3.fromRGB(14, 36, 72)
    BadgePill.Text = isRecent and "★ VỪA CHƠI" or g.badge
    BadgePill.TextColor3 = Theme.AccentNeon
    BadgePill.Font = Enum.Font.GothamBold
    BadgePill.TextSize = 9
    BadgePill.Parent = Card
    Instance.new("UICorner", BadgePill).CornerRadius = UDim.new(1, 0)

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -105, 0, 16)
    DescLbl.Position = UDim2.new(0, 66, 0, 36)
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
        TweenService:Create(Strk, TweenInfo.new(0.2), {Color = isRecent and Theme.AccentNeon or Theme.Stroke}):Play()
    end)

    table.insert(gameBtns, {btn = Card, name = string.lower(g.name)})
    Card.MouseButton1Click:Connect(function()
        openGamePage(g)
    end)
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = string.lower(SearchInput.Text)
    for _, item in ipairs(gameBtns) do
        local found = string.find(item.name, txt, 1, true)
        item.btn.Visible = not (found == nil)
    end
end)

BackBtn.MouseButton1Click:Connect(function()
    onPage2 = false
    TweenService:Create(Page1, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    TweenService:Create(Page2, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
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
        showToast("📋 Đã copy Mã Máy (HWID) vào bộ nhớ tạm!", Theme.AccentNeon)
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
    CheckHwidKeyBtn.Text = "⏳ Đang tìm..."
    Status.TextColor3 = Theme.AccentNeon
    Status.Text = "🔎 Đang kiểm tra Key bản quyền của HWID [" .. hwid .. "] trên Server V25..."

    task.spawn(function()
        local ok, resp = apiGet("/api/search_hwid?hwid=" .. url_encode(hwid), 2)
        isFetchingHwidKey = false
        if CheckHwidKeyBtn and CheckHwidKeyBtn.Parent then
            CheckHwidKeyBtn.Text = "🔍 Tự Lấy Key"
        end
        if ok and isNonEmptyStr(resp) then
            local decodeOk, data = pcall(function()
                return HttpService:JSONDecode(resp)
            end)
            if decodeOk and type(data) == "table" and data.success and type(data.keys) == "table" and #data.keys > 0 then
                local validKey = nil
                for _, k in ipairs(data.keys) do
                    local kStr = normalizeKeyStr(k.key or k.key_code)
                    if not k.is_expired and not k.is_banned and isNonEmptyStr(kStr) then
                        validKey = k
                        validKey.final_key = kStr
                        break
                    end
                end
                if not validKey then
                    local first = data.keys[1]
                    if first and isNonEmptyStr(first.key or first.key_code) then
                        validKey = first
                        validKey.final_key = normalizeKeyStr(first.key or first.key_code)
                    end
                end
                if validKey and isNonEmptyStr(validKey.final_key) then
                    local foundCode = tostring(validKey.final_key)
                    KeyInput.Text = foundCode
                    saveToFile(KEY_FILE, foundCode)
                    if isNonEmptyStr(validKey.time_left) then
                        lastVerifiedTimeLeft = tostring(validKey.time_left)
                    end
                    if isNonEmptyStr(validKey.tier_label) then
                        lastVerifiedTier = tostring(validKey.tier_label)
                    end
                    if isNonEmptyStr(validKey.expire_str) then
                        lastVerifiedExpire = tostring(validKey.expire_str)
                    end
                    if validKey.is_banned then
                        KeyReadyPill.Text = "🚫 Bị khóa"
                        KeyReadyPill.TextColor3 = Theme.Danger
                        Status.TextColor3 = Theme.Danger
                        Status.Text = "🚫 Key [" .. foundCode .. "] hiện đang bị Admin tạm khóa!"
                        showToast("🚫 Key này đang bị tạm khóa!", Theme.Danger)
                    elseif validKey.is_expired then
                        KeyReadyPill.Text = "⏰ Đã hết hạn"
                        KeyReadyPill.TextColor3 = Theme.Warning
                        Status.TextColor3 = Theme.Warning
                        Status.Text = "⚠️ Tìm thấy Key [" .. foundCode .. "] nhưng đã hết hạn. Vui lòng gia hạn trên Web!"
                        showToast("⚠️ Key gần nhất của bạn đã hết hạn!", Theme.Warning)
                    else
                        KeyReadyPill.Text = "✓ " .. tostring(validKey.time_left or "Còn hạn")
                        KeyReadyPill.TextColor3 = Theme.AccentNeon
                        Status.TextColor3 = Theme.AccentNeon
                        Status.Text = "✅ Đã tự động điền Key [" .. foundCode .. "] (" .. tostring(validKey.time_left or "Còn hạn") .. ")!"
                        showToast("🎉 Đã tìm thấy & tự điền Key bản quyền!", Theme.AccentNeon)
                    end
                    return
                end
            end
            Status.TextColor3 = Theme.Warning
            Status.Text = "⚠️ Chưa tìm thấy Key nào cho HWID [" .. hwid .. "]. Hãy Copy HWID và lên Web mua!"
            showToast("⚠️ Không tìm thấy Key cho HWID này!", Theme.Warning)
        else
            Status.TextColor3 = Theme.Danger
            Status.Text = "❌ Máy chủ đang thức dậy, hãy bấm [🔍 Tự Lấy Key] lại ngay!"
            showToast("❌ Lỗi kết nối máy chủ! Bấm thử lại.", Theme.Danger)
        end
    end)
end)

-- Tính năng V25: Tự mở khóa thiết bị (Reset HWID) ngay trong Loader
local isResettingHwid = false
ResetHwidBtn.MouseButton1Click:Connect(function()
    if isResettingHwid then return end
    local cleanKey = normalizeKeyStr(KeyInput.Text)
    if cleanKey == "" then
        Status.TextColor3 = Theme.Warning
        Status.Text = "⚠️ Hãy dán mã Key cần đổi máy vào ô Mã Key trước khi bấm [🔓 Đổi Máy]!"
        showToast("⚠️ Nhập mã Key cần đổi máy trước!", Theme.Warning)
        shakeElement(KeyBox, KeyStroke)
        return
    end
    isResettingHwid = true
    ResetHwidBtn.Text = "⏳ Đang gỡ..."
    Status.TextColor3 = Theme.AccentNeon
    Status.Text = "🔓 Đang gửi yêu cầu gỡ khóa thiết bị cũ cho Key [" .. cleanKey .. "]..."

    task.spawn(function()
        local ok, resp = apiGet("/api/reset_hwid_by_key?key=" .. url_encode(cleanKey), 2)
        isResettingHwid = false
        if ResetHwidBtn and ResetHwidBtn.Parent then
            ResetHwidBtn.Text = "🔓 Đổi Máy"
        end
        if ok and isNonEmptyStr(resp) then
            local decOk, data = pcall(function() return HttpService:JSONDecode(resp) end)
            if decOk and type(data) == "table" then
                if data.success then
                    KeyReadyPill.Text = "✓ Đã mở khóa"
                    KeyReadyPill.TextColor3 = Theme.AccentNeon
                    Status.TextColor3 = Theme.AccentNeon
                    Status.Text = "✅ " .. tostring(data.message or "Đã gỡ khóa máy cũ! Bấm Kích Hoạt để khóa vào máy này.")
                    showToast("🔓 Đã gỡ khóa thiết bị cũ thành công!", Theme.AccentNeon)
                    return
                else
                    local errMsg = tostring(data.detail or data.message or "Không thể gỡ khóa thiết bị lúc này!")
                    Status.TextColor3 = Theme.Warning
                    Status.Text = "⚠️ " .. errMsg
                    showToast("⚠️ " .. errMsg, Theme.Warning)
                    return
                end
            end
        end
        Status.TextColor3 = Theme.Danger
        Status.Text = "❌ Không thể kết nối máy chủ để gỡ khóa thiết bị, vui lòng thử lại!"
        showToast("❌ Lỗi kết nối máy chủ!", Theme.Danger)
    end)
end)

WebLinkBtn.MouseButton1Click:Connect(function()
    local smartUrl = WEB_STORE .. "/?hwid=" .. url_encode(hwid)
    if setclipboard then
        setclipboard(smartUrl)
        WebLinkBtn.Text = "✅ Đã Copy!"
        Status.TextColor3 = Theme.AccentNeon
        Status.Text = "🌐 Đã copy link kèm sẵn HWID: " .. smartUrl .. " — Dán lên trình duyệt để mua Key ngay!"
        showToast("🌐 Đã copy link Web (tự điền sẵn HWID)!", Theme.AccentNeon)
        task.delay(2.2, function()
            if WebLinkBtn and WebLinkBtn.Parent then
                WebLinkBtn.Text = "🌐 Copy Web"
            end
        end)
    else
        Status.TextColor3 = Theme.AccentNeon
        Status.Text = "🌐 Web mua Key: " .. smartUrl
    end
end)

-- ==========================================
-- LOGIC KÍCH HOẠT SCRIPT V25 OMNI
-- ==========================================
local isConnecting = false
local function triggerActivate()
    if isConnecting or not onPage2 then return end
    local cleanKey = normalizeKeyStr(KeyInput.Text)
    if cleanKey == "" then
        Status.TextColor3 = Theme.Danger
        Status.Text = "⚠️ Vui lòng nhập mã Key hoặc bấm [🔍 Tự Lấy Key] trước khi Kích Hoạt!"
        showToast("⚠️ Bạn chưa nhập mã Key bản quyền!", Theme.Danger)
        shakeElement(KeyBox, KeyStroke)
        return
    end
    KeyInput.Text = cleanKey
    isConnecting = true
    local elapsed = 0
    ActivateBtn.Text = "⏳ ĐANG XÁC THỰC BẢN QUYỀN V25..."

    task.spawn(function()
        while isConnecting and ActivateBtn and ActivateBtn.Parent do
            Status.TextColor3 = Theme.AccentNeon
            Status.Text = string.format("⚡ Đang kết nối máy chủ BIVA STORM V25 (%ds)...", elapsed)
            task.wait(1)
            elapsed = elapsed + 1
        end
    end)

    task.spawn(function()
        local queryPath = "/api/get_script?key="
            .. url_encode(cleanKey)
            .. "&hwid=" .. url_encode(hwid)
            .. "&game_id=" .. url_encode(selectedGameId)

        local success, code = apiGet(queryPath, 2)
        isConnecting = false

        if success and isNonEmptyStr(code) then
            -- Bắt lỗi nếu Server trả về JSON báo lỗi (Rate limit 429 hoặc lỗi hệ thống)
            if code:sub(1, 1) == "{" then
                local decOk, errObj = pcall(function() return HttpService:JSONDecode(code) end)
                local msg = (decOk and type(errObj) == "table" and (errObj.detail or errObj.message)) or "❌ Thao tác quá nhanh, vui lòng thử lại sau vài giây!"
                ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT V25 NGAY"
                Status.TextColor3 = Theme.Danger
                Status.Text = tostring(msg)
                showToast(tostring(msg), Theme.Danger)
                return
            end

            if string.find(code, ":Kick%(") or string.find(code, "Kick%(") then
                local kickMsg = code:match('Kick%("([^"]+)"%)') or "❌ Key không hợp lệ hoặc đã hết hạn!"
                ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT V25 NGAY"
                Status.TextColor3 = Theme.Danger
                Status.Text = kickMsg
                showToast(kickMsg, Theme.Danger)
                shakeElement(KeyBox, KeyStroke)
            else
                local func, err = loadstring(code)
                if func then
                    saveToFile(KEY_FILE, cleanKey)
                    _G.BIVA_KEY = cleanKey
                    _G.SEM_KEY = cleanKey
                    _G.BIVA_HWID = hwid
                    _G.BIVA_API_BASE = API_BASE
                    if isNonEmptyStr(lastVerifiedTimeLeft) then
                        _G.SEM_TIME = lastVerifiedTimeLeft
                    end
                    if isNonEmptyStr(lastVerifiedTier) then
                        _G.BIVA_TIER = lastVerifiedTier
                    end
                    if isNonEmptyStr(lastVerifiedNotice) then
                        _G.BIVA_ADMIN_MSG = lastVerifiedNotice
                    end
                    if isNonEmptyStr(lastVerifiedExpire) then
                        _G.BIVA_EXPIRE = lastVerifiedExpire
                    end
                    Status.TextColor3 = Theme.AccentNeon
                    Status.Text = "✅ Bản quyền V25 hợp lệ! Đang khởi chạy Script..."
                    showToast("🎉 Kích hoạt thành công! Đang mở Menu V25...", Theme.AccentNeon)
                    task.wait(0.3)
                    closeLoader()
                    task.spawn(func)
                else
                    ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT V25 NGAY"
                    Status.TextColor3 = Theme.Danger
                    Status.Text = "❌ Lỗi thực thi Script: " .. tostring(err)
                    showToast("❌ Lỗi cú pháp Script trả về!", Theme.Danger)
                end
            end
        else
            ActivateBtn.Text = "⚡ KÍCH HOẠT SCRIPT V25 NGAY"
            Status.TextColor3 = Theme.Danger
            Status.Text = "❌ Máy chủ đang thức dậy sau nghỉ ngơi, hãy bấm Kích Hoạt lại ngay!"
            showToast("❌ Lỗi kết nối Server! Hãy bấm lại.", Theme.Danger)
        end
    end)
end

ActivateBtn.MouseButton1Click:Connect(triggerActivate)
KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed and onPage2 then
        triggerActivate()
    end
end)

trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        toggleMinimize()
    elseif input.KeyCode == Enum.KeyCode.Return and onPage2 and Main.Visible then
        triggerActivate()
    end
end))
