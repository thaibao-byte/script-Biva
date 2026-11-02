-- ==============================================================================
-- BIVA STORM | ULTRA INSTINCT v6.0 — PRINCIPAL CORE LOADER & COMMAND STUDIO
-- Architecture: Zero-Lag Pure Luau • Event-Driven UI • Debounced Disk I/O
-- Design System: Obsidian & Platinum-Cyan Studio (Zero Per-Frame Gradient Loops)
-- Pricing Tiers: Free (20h) | 8K (1D) | 40K (7D) | 130K (30D) | 200K (365D) | 250K (Lifetime)
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
-- 1. HẰNG SỐ KẾT NỐI & BẢNG MÀU STUDIO v6.0
-- ==============================================================================
local API_BASE = "https://biva-hub.onrender.com"
local WEB_SHOP_URL = API_BASE .. "/index.html"
local LOADER_RAW_URL = "https://raw.githubusercontent.com/thaibao-byte/script-Biva/main/biva_storm.lua"
local SAVE_FILE_NAME = "BivaStorm_UltraInstinct_Config_v60.json"
local VAULT_FILE_NAME = "BivaStorm_UltraInstinct_Vault_v60.json"

local DEFAULT_PRICING_FOOTNOTE = "Chính sách: Miễn Phí = Vượt Link (20h) • 8.000đ = 1 Ngày • 40.000đ = 1 Tuần • 130.000đ = 1 Tháng • 200.000đ = 1 Năm VIP • 250.000đ = Vĩnh Viễn. Quét VietQR kích hoạt tự động 3 giây, khóa bảo vệ HWID, hỗ trợ tự đổi thiết bị và bù giờ 100% khi bảo trì."

local THEMES = {
	UltraInstinct = {
		Name = "Obsidian",
		BgMain = Color3.fromRGB(7, 9, 15),
		BgCard = Color3.fromRGB(12, 16, 24),
		BgElevated = Color3.fromRGB(18, 24, 36),
		BgInput = Color3.fromRGB(9, 12, 19),
		Border = Color3.fromRGB(30, 41, 59),
		Accent = Color3.fromRGB(56, 189, 248),
		Primary = Color3.fromRGB(14, 165, 233),
		Platinum = Color3.fromRGB(241, 245, 249),
		TextMain = Color3.fromRGB(248, 250, 252),
		TextSub = Color3.fromRGB(148, 163, 184),
		TextMuted = Color3.fromRGB(100, 116, 139),
		Ok = Color3.fromRGB(16, 185, 129),
		Warn = Color3.fromRGB(245, 158, 11),
		Err = Color3.fromRGB(244, 63, 94)
	},
	Platinum = {
		Name = "Platinum",
		BgMain = Color3.fromRGB(9, 11, 17),
		BgCard = Color3.fromRGB(15, 19, 28),
		BgElevated = Color3.fromRGB(22, 28, 40),
		BgInput = Color3.fromRGB(11, 14, 22),
		Border = Color3.fromRGB(42, 54, 74),
		Accent = Color3.fromRGB(226, 232, 240),
		Primary = Color3.fromRGB(56, 189, 248),
		Platinum = Color3.fromRGB(255, 255, 255),
		TextMain = Color3.fromRGB(248, 250, 252),
		TextSub = Color3.fromRGB(165, 180, 200),
		TextMuted = Color3.fromRGB(110, 125, 148),
		Ok = Color3.fromRGB(16, 185, 129),
		Warn = Color3.fromRGB(245, 158, 11),
		Err = Color3.fromRGB(244, 63, 94)
	},
	Emerald = {
		Name = "Emerald",
		BgMain = Color3.fromRGB(6, 12, 11),
		BgCard = Color3.fromRGB(10, 20, 18),
		BgElevated = Color3.fromRGB(16, 30, 27),
		BgInput = Color3.fromRGB(8, 15, 14),
		Border = Color3.fromRGB(26, 52, 45),
		Accent = Color3.fromRGB(52, 211, 153),
		Primary = Color3.fromRGB(16, 185, 129),
		Platinum = Color3.fromRGB(236, 253, 245),
		TextMain = Color3.fromRGB(240, 253, 244),
		TextSub = Color3.fromRGB(153, 204, 184),
		TextMuted = Color3.fromRGB(98, 145, 128),
		Ok = Color3.fromRGB(16, 185, 129),
		Warn = Color3.fromRGB(245, 158, 11),
		Err = Color3.fromRGB(244, 63, 94)
	},
	Cobalt = {
		Name = "Cobalt",
		BgMain = Color3.fromRGB(7, 10, 19),
		BgCard = Color3.fromRGB(12, 17, 32),
		BgElevated = Color3.fromRGB(18, 26, 46),
		BgInput = Color3.fromRGB(9, 13, 25),
		Border = Color3.fromRGB(32, 46, 78),
		Accent = Color3.fromRGB(96, 165, 250),
		Primary = Color3.fromRGB(37, 99, 235),
		Platinum = Color3.fromRGB(239, 246, 255),
		TextMain = Color3.fromRGB(248, 250, 252),
		TextSub = Color3.fromRGB(148, 163, 184),
		TextMuted = Color3.fromRGB(100, 116, 139),
		Ok = Color3.fromRGB(16, 185, 129),
		Warn = Color3.fromRGB(245, 158, 11),
		Err = Color3.fromRGB(244, 63, 94)
	}
}

local THEME = THEMES.UltraInstinct
local ThemeBindings = {}
local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_THEME = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ==============================================================================
-- 2. TIỆN ÍCH CHUẨN HÓA HWID / KEY & LƯU TRỮ DEBOUNCED (0 STUTTER)
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
		return "Roblox Client"
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
		ultra_instinct = true,
		theme_id = "UltraInstinct",
		pending_order_id = "",
		pending_package = ""
	}
	pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" then
			local targetFile = nil
			local candidates = {
				SAVE_FILE_NAME,
				"BivaStorm_UltraInstinct_Config_v50.json",
				"BivaStorm_ApexOmega_Config_v40.json",
				"BivaStorm_ApexOmega_Config_v35.json"
			}
			for _, cand in ipairs(candidates) do
				if isfile(cand) then
					targetFile = cand
					break
				end
			end
			if targetFile then
				local decoded = HttpService:JSONDecode(readfile(targetFile))
				if type(decoded) == "table" then
					for k, v in pairs(decoded) do
						cfg[k] = v
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
		if g and type(g.BIVA_ULTRA_INSTINCT) == "boolean" then
			cfg.ultra_instinct = g.BIVA_ULTRA_INSTINCT
		end
	end)
	if THEMES[cfg.theme_id] then
		THEME = THEMES[cfg.theme_id]
	else
		cfg.theme_id = "UltraInstinct"
		THEME = THEMES.UltraInstinct
	end
	return cfg
end

local saveConfigSeq = 0
local function flushConfigNow(cfg)
	pcall(function()
		if type(writefile) == "function" and type(cfg) == "table" then
			writefile(SAVE_FILE_NAME, HttpService:JSONEncode(cfg))
		end
	end)
end

local function saveConfig(cfg, immediate)
	saveConfigSeq = saveConfigSeq + 1
	if immediate then
		flushConfigNow(cfg)
		return
	end
	local mySeq = saveConfigSeq
	task.delay(0.35, function()
		if mySeq == saveConfigSeq then
			flushConfigNow(cfg)
		end
	end)
end

local function loadVault()
	local list = {}
	pcall(function()
		if type(isfile) == "function" and type(readfile) == "function" then
			local vf = nil
			for _, cand in ipairs({ VAULT_FILE_NAME, "BivaStorm_UltraInstinct_Vault_v50.json", "BivaStorm_ApexOmega_Vault_v40.json" }) do
				if isfile(cand) then
					vf = cand
					break
				end
			end
			if vf then
				local dec = HttpService:JSONDecode(readfile(vf))
				if type(dec) == "table" then list = dec end
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
-- 3. LÕI HTTP AN TOÀN & SMART COLD-START RETRY
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
			Accept = "application/json, text/plain, */*",
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
	if method == "GET" then
		local okGet, bodyGet = pcall(function()
			return game:HttpGet(url)
		end)
		if okGet and type(bodyGet) == "string" then
			return true, 200, bodyGet
		end
	end
	return false, 0, ""
end

local function apiCall(path, method, bodyTable, isPlainText)
	local sep = string.find(path, "?", 1, true) and "&" or "?"
	for attempt = 1, 2 do
		local fullUrl = API_BASE .. path .. sep .. "_t=" .. tostring(math.floor(os.clock() * 1000)) .. tostring(attempt)
		local t0 = os.clock()
		local ok, status, raw = rawHttp(fullUrl, method, bodyTable)
		local ping = math.max(4, math.floor((os.clock() - t0) * 1000))
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
		if attempt == 1 and (status == 0 or status == 502 or status == 503 or status == 504) then
			task.wait(1.1)
		else
			return nil, status or 0, ping
		end
	end
	return nil, 0, 999
end

-- ==============================================================================
-- 4. TRẠNG THÁI HỆ THỐNG & ÂM THANH TỐI GIẢN
-- ==============================================================================
local State = {
	config = loadConfig(),
	sync_rev = 1,
	ping = 0,
	admin_notice = "BIVA STORM v6.0 [ULTRA INSTINCT] — Phản Xạ 0ms • Duyệt VietQR Tự Động 3 Giây.",
	pricing_footnote = DEFAULT_PRICING_FOOTNOTE,
	maintenance = false,
	voucher_code = "",
	voucher_discount = 0,
	voucher_bonus_hours = 0,
	flash_sale = { active = false, discount_percent = 0, title = "", remaining_text = "" },
	package_prices = {
		["1 Ngày"] = 8000,
		["1 Tuần"] = 40000,
		["1 Tháng"] = 130000,
		["1 Năm VIP"] = 200000,
		["Vĩnh Viễn"] = 250000
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
	optimizing_fps = false,
	watching_order = false,
	minimized = false
}

local function playUiSound(isSuccess)
	if not State.config.sound_fx then return end
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = isSuccess and "rbxassetid://6895079853" or "rbxassetid://6895079775"
		snd.Volume = isSuccess and 0.35 or 0.2
		snd.Parent = SoundService
		snd:Play()
		task.delay(1.1, function()
			if snd and snd.Parent then snd:Destroy() end
		end)
	end)
end

-- ==============================================================================
-- 5. KHỞI TẠO GIAO DIỆN STUDIO v6.0 (ZERO-LEAK LIFECYCLE, 0 IDLE GPU LOAD)
-- ==============================================================================
local sharedEnv = (type(getgenv) == "function" and getgenv()) or _G
if type(sharedEnv) == "table" and type(sharedEnv.BIVA_LOADER_CLEANUP) == "function" then
	pcall(sharedEnv.BIVA_LOADER_CLEANUP)
end

local LoaderAlive = true
local LoaderConns = {}
local function trackLoaderConn(conn)
	if conn then table.insert(LoaderConns, conn) end
	return conn
end

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

local function cleanupLoader()
	if not LoaderAlive then return end
	LoaderAlive = false
	flushConfigNow(State.config)
	for i = #LoaderConns, 1, -1 do
		pcall(function() LoaderConns[i]:Disconnect() end)
		LoaderConns[i] = nil
	end
	table.clear(ThemeBindings)
	if ScreenGui and ScreenGui.Parent then
		pcall(function() ScreenGui:Destroy() end)
	end
end

if type(sharedEnv) == "table" then
	sharedEnv.BIVA_LOADER_CLEANUP = cleanupLoader
end

local function pruneThemeBindings()
	local writeIdx = 1
	for readIdx = 1, #ThemeBindings do
		local b = ThemeBindings[readIdx]
		if b and b.inst and b.inst.Parent then
			ThemeBindings[writeIdx] = b
			writeIdx = writeIdx + 1
		end
	end
	for i = writeIdx, #ThemeBindings do
		ThemeBindings[i] = nil
	end
end

local function BindTheme(inst, prop, key)
	table.insert(ThemeBindings, { inst = inst, prop = prop, key = key })
	pcall(function() inst[prop] = THEME[key] end)
end

local ActiveTabId = "auth"
local TabButtons = {}
local TabIndicators = {}
local TabPages = {}
local PillRefreshers = {}

local function SetTheme(themeId)
	local nextTheme = THEMES[themeId]
	if not nextTheme then return end
	THEME = nextTheme
	State.config.theme_id = themeId
	saveConfig(State.config)
	pruneThemeBindings()
	for _, b in ipairs(ThemeBindings) do
		if b.inst and b.inst.Parent and THEME[b.key] then
			pcall(function()
				TweenService:Create(b.inst, TWEEN_THEME, { [b.prop] = THEME[b.key] }):Play()
			end)
		end
	end
	for id, btn in pairs(TabButtons) do
		local isAct = (id == ActiveTabId)
		btn.BackgroundColor3 = isAct and THEME.BgElevated or THEME.BgCard
		btn.TextColor3 = isAct and THEME.TextMain or THEME.TextSub
		if TabIndicators[id] then
			TabIndicators[id].BackgroundColor3 = THEME.Accent
		end
	end
	for _, refreshFn in ipairs(PillRefreshers) do
		pcall(refreshFn, true)
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
	return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function Stroke(parent, themeKey, thick, trans)
	local s = New("UIStroke", {
		Color = THEME[themeKey or "Border"] or Color3.fromRGB(30, 41, 59),
		Thickness = thick or 1,
		Transparency = trans or 0.15,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent
	})
	if themeKey then BindTheme(s, "Color", themeKey) end
	return s
end

local function MakeDraggable(handle, target)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	trackLoaderConn(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end))
	trackLoaderConn(handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	trackLoaderConn(UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and target and target.Parent then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
end

-- TOAST THÔNG BÁO CHUẨN STUDIO
local ToastHolder = New("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0, 380, 0, 96),
	ZIndex = 120,
	Parent = ScreenGui
})
New("UIListLayout", {
	Padding = UDim.new(0, 6),
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
		Color = isErr and THEME.Err or THEME.Border,
		Thickness = 1,
		Transparency = 0.1,
		Parent = item
	})
	local bar = New("Frame", {
		BackgroundColor3 = isErr and THEME.Err or THEME.Accent,
		Position = UDim2.new(0, 8, 0.5, -7),
		Size = UDim2.new(0, 3, 0, 14),
		BorderSizePixel = 0,
		ZIndex = 122,
		Parent = item
	})
	Corner(bar, 2)
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(1, -26, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = tostring(msg),
		TextColor3 = THEME.TextMain,
		TextSize = 11.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 122,
		Parent = item
	})
	task.delay(2.6, function()
		if item and item.Parent then item:Destroy() end
	end)
end

-- NÚT THU NHỎ NỔI (STATIC PRECISION GRADIENT — 0 IDLE CPU)
local FloatingOrb = New("TextButton", {
	BackgroundColor3 = THEME.BgCard,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.new(0, 176, 0, 34),
	Font = Enum.Font.GothamBold,
	Text = "BIVA v6.0 • STUDIO",
	TextColor3 = THEME.Platinum,
	TextSize = 11,
	Visible = false,
	AutoButtonColor = false,
	ZIndex = 95,
	Parent = ScreenGui
})
Corner(FloatingOrb, 17)
local OrbStroke = New("UIStroke", {
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 1.2,
	Transparency = 0.25,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Parent = FloatingOrb
})
New("UIGradient", {
	Rotation = 35,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(241, 245, 249)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(56, 189, 248)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 41, 59))
	}),
	Parent = OrbStroke
})
BindTheme(FloatingOrb, "BackgroundColor3", "BgCard")
BindTheme(FloatingOrb, "TextColor3", "Platinum")
MakeDraggable(FloatingOrb, FloatingOrb)

-- CỬA SỔ CHÍNH (600 x 400) + TỰ CO GIÃN ĐA MÀN HÌNH
local MainWindow = New("Frame", {
	BackgroundColor3 = THEME.BgMain,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 600, 0, 400),
	ClipsDescendants = true,
	Parent = ScreenGui
})
Corner(MainWindow, 12)
local MainStroke = New("UIStroke", {
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 1.2,
	Transparency = 0.35,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Parent = MainWindow
})
New("UIGradient", {
	Rotation = 35,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(226, 232, 240)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(56, 189, 248)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 41, 59))
	}),
	Parent = MainStroke
})
BindTheme(MainWindow, "BackgroundColor3", "BgMain")

local WindowScale = New("UIScale", { Scale = 1, Parent = MainWindow })

local function updateResponsiveScale()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local scaleX = (vp.X - 24) / 600
	local scaleY = (vp.Y - 24) / 400
	local s = math.min(1, scaleX, scaleY)
	WindowScale.Scale = math.clamp(s, 0.62, 1)
end
updateResponsiveScale()
if workspace.CurrentCamera then
	trackLoaderConn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
end

-- HEADER TRÊN CÙNG
local Header = New("Frame", {
	BackgroundColor3 = THEME.BgCard,
	Size = UDim2.new(1, 0, 0, 44),
	BorderSizePixel = 0,
	Parent = MainWindow
})
Corner(Header, 12)
BindTheme(Header, "BackgroundColor3", "BgCard")
MakeDraggable(Header, MainWindow)

local HeaderDivider = New("Frame", {
	BackgroundColor3 = THEME.Border,
	Position = UDim2.new(0, 0, 1, -1),
	Size = UDim2.new(1, 0, 0, 1),
	BorderSizePixel = 0,
	Parent = Header
})
BindTheme(HeaderDivider, "BackgroundColor3", "Border")

local LogoBadge = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(0, 12, 0.5, -13),
	Size = UDim2.new(0, 26, 0, 26),
	Parent = Header
})
Corner(LogoBadge, 7)
Stroke(LogoBadge, "Accent", 1, 0.35)
BindTheme(LogoBadge, "BackgroundColor3", "BgElevated")

local LogoMono = New("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.GothamBlack,
	Text = "BS",
	TextColor3 = THEME.Accent,
	TextSize = 11,
	Parent = LogoBadge
})
BindTheme(LogoMono, "TextColor3", "Accent")

local TitleLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 46, 0, 6),
	Size = UDim2.new(0, 350, 0, 16),
	Font = Enum.Font.GothamBold,
	Text = "BIVA STORM v6.0 — ULTRA INSTINCT",
	TextColor3 = THEME.TextMain,
	TextSize = 12.5,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = Header
})
BindTheme(TitleLbl, "TextColor3", "TextMain")

local LiveStatusDot = New("Frame", {
	BackgroundColor3 = THEME.Ok,
	Position = UDim2.new(0, 46, 0, 27),
	Size = UDim2.new(0, 6, 0, 6),
	BorderSizePixel = 0,
	Parent = Header
})
Corner(LiveStatusDot, 3)

local SubHeaderLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 57, 0, 22),
	Size = UDim2.new(0, 350, 0, 15),
	Font = Enum.Font.Code,
	Text = EXECUTOR_NAME .. " • Ping: --ms",
	TextColor3 = THEME.TextSub,
	TextSize = 10.5,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = Header
})
BindTheme(SubHeaderLbl, "TextColor3", "TextSub")

local SyncTopBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(1, -138, 0.5, -13),
	Size = UDim2.new(0, 64, 0, 26),
	Font = Enum.Font.GothamBold,
	Text = "Đồng Bộ",
	TextColor3 = THEME.Accent,
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = Header
})
Corner(SyncTopBtn, 6)
Stroke(SyncTopBtn, "Border", 1, 0.2)
BindTheme(SyncTopBtn, "BackgroundColor3", "BgElevated")
BindTheme(SyncTopBtn, "TextColor3", "Accent")

local MinBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(1, -68, 0.5, -13),
	Size = UDim2.new(0, 26, 0, 26),
	Font = Enum.Font.GothamBold,
	Text = "—",
	TextColor3 = THEME.TextSub,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = Header
})
Corner(MinBtn, 6)
Stroke(MinBtn, "Border", 1, 0.2)
BindTheme(MinBtn, "BackgroundColor3", "BgElevated")
BindTheme(MinBtn, "TextColor3", "TextSub")

local CloseBtn = New("TextButton", {
	BackgroundColor3 = Color3.fromRGB(45, 14, 22),
	Position = UDim2.new(1, -36, 0.5, -13),
	Size = UDim2.new(0, 26, 0, 26),
	Font = Enum.Font.GothamBold,
	Text = "✕",
	TextColor3 = THEME.Err,
	TextSize = 11,
	AutoButtonColor = false,
	Parent = Header
})
Corner(CloseBtn, 6)

-- SIDEBAR ĐIỀU HƯỚNG 5 TAB BÊN TRÁI
local Sidebar = New("Frame", {
	BackgroundColor3 = THEME.BgCard,
	Position = UDim2.new(0, 8, 0, 52),
	Size = UDim2.new(0, 146, 1, -60),
	Parent = MainWindow
})
Corner(Sidebar, 10)
Stroke(Sidebar, "Border", 1, 0.15)
BindTheme(Sidebar, "BackgroundColor3", "BgCard")

local NavList = New("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 6, 0, 6),
	Size = UDim2.new(1, -12, 1, -80),
	Parent = Sidebar
})
New("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = NavList
})

-- Hộp Mã Máy (HWID) cố định ở góc trái dưới
local HwidBox = New("Frame", {
	BackgroundColor3 = THEME.BgInput,
	Position = UDim2.new(0, 6, 1, -68),
	Size = UDim2.new(1, -12, 0, 62),
	Parent = Sidebar
})
Corner(HwidBox, 8)
Stroke(HwidBox, "Border", 1, 0.2)
BindTheme(HwidBox, "BackgroundColor3", "BgInput")

local HwidTitleLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 8, 0, 4),
	Size = UDim2.new(1, -16, 0, 12),
	Font = Enum.Font.GothamBold,
	Text = "MÃ THIẾT BỊ (HWID)",
	TextColor3 = THEME.TextMuted,
	TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = HwidBox
})
BindTheme(HwidTitleLbl, "TextColor3", "TextMuted")

local HwidTextLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 8, 0, 17),
	Size = UDim2.new(1, -16, 0, 14),
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
	Text = "Sao Chép HWID",
	TextColor3 = THEME.TextMain,
	TextSize = 10,
	AutoButtonColor = false,
	Parent = HwidBox
})
Corner(CopyHwidBtn, 5)
BindTheme(CopyHwidBtn, "BackgroundColor3", "BgElevated")
BindTheme(CopyHwidBtn, "TextColor3", "TextMain")

CopyHwidBtn.MouseButton1Click:Connect(function()
	if copyClipboard(DEVICE_HWID) then
		showToast("Đã sao chép HWID: " .. DEVICE_HWID, false)
	else
		showToast("HWID: " .. DEVICE_HWID, false)
	end
end)

-- VÙNG NỘI DUNG BÊN PHẢI
local ContentArea = New("Frame", {
	BackgroundColor3 = THEME.BgCard,
	Position = UDim2.new(0, 160, 0, 52),
	Size = UDim2.new(1, -168, 1, -60),
	ClipsDescendants = true,
	Parent = MainWindow
})
Corner(ContentArea, 10)
Stroke(ContentArea, "Border", 1, 0.15)
BindTheme(ContentArea, "BackgroundColor3", "BgCard")

local function switchTab(tabId)
	ActiveTabId = tabId
	playUiSound(false)
	for id, page in pairs(TabPages) do
		page.Visible = (id == tabId)
	end
	for id, btn in pairs(TabButtons) do
		local isAct = (id == tabId)
		TweenService:Create(btn, TWEEN_FAST, {
			BackgroundColor3 = isAct and THEME.BgElevated or THEME.BgCard,
			TextColor3 = isAct and THEME.TextMain or THEME.TextSub
		}):Play()
		local ind = TabIndicators[id]
		if ind then
			TweenService:Create(ind, TWEEN_FAST, {
				BackgroundTransparency = isAct and 0 or 1,
				Size = isAct and UDim2.new(0, 3, 0, 16) or UDim2.new(0, 3, 0, 6)
			}):Play()
		end
	end
end

local function createTab(tabId, title, order)
	local btn = New("TextButton", {
		BackgroundColor3 = THEME.BgCard,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 32),
		Font = Enum.Font.GothamBold,
		Text = "   " .. title,
		TextColor3 = THEME.TextSub,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		Parent = NavList
	})
	Corner(btn, 7)

	local ind = New("Frame", {
		BackgroundColor3 = THEME.Accent,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 6),
		BorderSizePixel = 0,
		Parent = btn
	})
	Corner(ind, 2)
	BindTheme(ind, "BackgroundColor3", "Accent")

	local page = New("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 1, -20),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Visible = false,
		Parent = ContentArea
	})
	BindTheme(page, "ScrollBarImageColor3", "Accent")
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page
	})

	btn.MouseButton1Click:Connect(function() switchTab(tabId) end)
	TabButtons[tabId] = btn
	TabIndicators[tabId] = ind
	TabPages[tabId] = page
	return page
end

createTab("auth", "Kích Hoạt Key", 1)
createTab("shop", "Bảng Giá Key", 2)
createTab("vault", "Kho Key & Thiết Bị", 3)
createTab("support", "Đơn & Hỗ Trợ", 4)
createTab("utils", "Tiện Ích & Giao Diện", 5)

-- ==============================================================================
-- 6. TAB 1: KÍCH HOẠT KEY, ĐỒNG BỘ HWID & ĐỔI GIFTCODE
-- ==============================================================================
local NoticeBanner = New("Frame", {
	BackgroundColor3 = THEME.BgInput,
	Size = UDim2.new(1, 0, 0, 28),
	Parent = TabPages.auth
})
Corner(NoticeBanner, 7)
Stroke(NoticeBanner, "Border", 1, 0.25)
BindTheme(NoticeBanner, "BackgroundColor3", "BgInput")

local NoticeDot = New("Frame", {
	BackgroundColor3 = THEME.Accent,
	Position = UDim2.new(0, 10, 0.5, -3),
	Size = UDim2.new(0, 6, 0, 6),
	BorderSizePixel = 0,
	Parent = NoticeBanner
})
Corner(NoticeDot, 3)
BindTheme(NoticeDot, "BackgroundColor3", "Accent")

local NoticeLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 22, 0, 0),
	Size = UDim2.new(1, -30, 1, 0),
	Font = Enum.Font.GothamMedium,
	Text = State.admin_notice,
	TextColor3 = THEME.TextSub,
	TextSize = 10.5,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = NoticeBanner
})
BindTheme(NoticeLbl, "TextColor3", "TextSub")

local KeyCard = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 66),
	Parent = TabPages.auth
})
Corner(KeyCard, 8)
Stroke(KeyCard, "Border", 1, 0.2)
BindTheme(KeyCard, "BackgroundColor3", "BgElevated")

local KeyCardLabel = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 6),
	Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.GothamBold,
	Text = "MÃ KEY BẢN QUYỀN (RB-XXXX-XXXX / FREE-XXXX)",
	TextColor3 = THEME.TextMuted,
	TextSize = 9.5,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = KeyCard
})
BindTheme(KeyCardLabel, "TextColor3", "TextMuted")

local KeyInput = New("TextBox", {
	BackgroundColor3 = THEME.BgInput,
	Position = UDim2.new(0, 10, 0, 24),
	Size = UDim2.new(1, -172, 0, 32),
	Font = Enum.Font.Code,
	PlaceholderText = "Nhập hoặc dán mã Key bản quyền...",
	PlaceholderColor3 = THEME.TextMuted,
	Text = State.config.hide_key and maskKey(State.config.saved_key) or (State.config.saved_key or ""),
	TextColor3 = THEME.Accent,
	TextSize = 12,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = KeyCard
})
Corner(KeyInput, 6)
Stroke(KeyInput, "Border", 1, 0.25)
New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = KeyInput })
BindTheme(KeyInput, "BackgroundColor3", "BgInput")
BindTheme(KeyInput, "TextColor3", "Accent")

local HideKeyBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgCard,
	Position = UDim2.new(1, -156, 0, 24),
	Size = UDim2.new(0, 44, 0, 32),
	Font = Enum.Font.GothamBold,
	Text = State.config.hide_key and "Hiện" or "Ẩn",
	TextColor3 = THEME.TextSub,
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = KeyCard
})
Corner(HideKeyBtn, 6)
Stroke(HideKeyBtn, "Border", 1, 0.25)
BindTheme(HideKeyBtn, "BackgroundColor3", "BgCard")
BindTheme(HideKeyBtn, "TextColor3", "TextSub")

local PasteKeyBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgCard,
	Position = UDim2.new(1, -106, 0, 24),
	Size = UDim2.new(0, 58, 0, 32),
	Font = Enum.Font.GothamBold,
	Text = "Dán Key",
	TextColor3 = THEME.Accent,
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = KeyCard
})
Corner(PasteKeyBtn, 6)
Stroke(PasteKeyBtn, "Border", 1, 0.25)
BindTheme(PasteKeyBtn, "BackgroundColor3", "BgCard")
BindTheme(PasteKeyBtn, "TextColor3", "Accent")

local ClearKeyBtn = New("TextButton", {
	BackgroundColor3 = Color3.fromRGB(45, 14, 22),
	Position = UDim2.new(1, -42, 0, 24),
	Size = UDim2.new(0, 32, 0, 32),
	Font = Enum.Font.GothamBold,
	Text = "Xoá",
	TextColor3 = THEME.Err,
	TextSize = 10,
	AutoButtonColor = false,
	Parent = KeyCard
})
Corner(ClearKeyBtn, 6)

HideKeyBtn.MouseButton1Click:Connect(function()
	State.config.hide_key = not State.config.hide_key
	saveConfig(State.config)
	KeyInput.Text = State.config.hide_key and maskKey(State.config.saved_key) or (State.config.saved_key or "")
	HideKeyBtn.Text = State.config.hide_key and "Hiện" or "Ẩn"
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
		showToast("Nhấn giữ vào ô nhập để dán Key từ bộ nhớ tạm.", false)
	end
end)

ClearKeyBtn.MouseButton1Click:Connect(function()
	State.config.saved_key = ""
	saveConfig(State.config)
	KeyInput.Text = ""
	showToast("Đã làm trống ô nhập Key.", false)
end)

local AuthBtnRow = New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 36),
	Parent = TabPages.auth
})

local ActivateBtn = New("TextButton", {
	BackgroundColor3 = THEME.Primary,
	Size = UDim2.new(0.54, -4, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "KÍCH HOẠT & MỞ STUDIO",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11.5,
	AutoButtonColor = false,
	Parent = AuthBtnRow
})
Corner(ActivateBtn, 8)
BindTheme(ActivateBtn, "BackgroundColor3", "Primary")

local AutoFetchBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(0.54, 4, 0, 0),
	Size = UDim2.new(0.46, -4, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "Nhận Diện Theo HWID",
	TextColor3 = THEME.Accent,
	TextSize = 11,
	AutoButtonColor = false,
	Parent = AuthBtnRow
})
Corner(AutoFetchBtn, 8)
Stroke(AutoFetchBtn, "Accent", 1, 0.55)
BindTheme(AutoFetchBtn, "BackgroundColor3", "BgElevated")
BindTheme(AutoFetchBtn, "TextColor3", "Accent")

local GiftRow = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 36),
	Parent = TabPages.auth
})
Corner(GiftRow, 8)
Stroke(GiftRow, "Border", 1, 0.2)
BindTheme(GiftRow, "BackgroundColor3", "BgElevated")

local GiftInput = New("TextBox", {
	BackgroundColor3 = THEME.BgInput,
	Position = UDim2.new(0, 6, 0, 4),
	Size = UDim2.new(1, -122, 0, 28),
	Font = Enum.Font.Code,
	PlaceholderText = "Nhập mã Giftcode sự kiện...",
	PlaceholderColor3 = THEME.TextMuted,
	Text = "",
	TextColor3 = THEME.TextMain,
	TextSize = 11,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = GiftRow
})
Corner(GiftInput, 6)
New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = GiftInput })
BindTheme(GiftInput, "BackgroundColor3", "BgInput")
BindTheme(GiftInput, "TextColor3", "TextMain")

local RedeemGiftBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgCard,
	Position = UDim2.new(1, -110, 0, 4),
	Size = UDim2.new(0, 104, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Đổi Giftcode",
	TextColor3 = THEME.Platinum,
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = GiftRow
})
Corner(RedeemGiftBtn, 6)
Stroke(RedeemGiftBtn, "Accent", 1, 0.5)
BindTheme(RedeemGiftBtn, "BackgroundColor3", "BgCard")
BindTheme(RedeemGiftBtn, "TextColor3", "Platinum")

local StatusCard = New("Frame", {
	BackgroundColor3 = THEME.BgInput,
	Size = UDim2.new(1, 0, 0, 66),
	Parent = TabPages.auth
})
Corner(StatusCard, 8)
Stroke(StatusCard, "Border", 1, 0.15)
BindTheme(StatusCard, "BackgroundColor3", "BgInput")

local StatusTitleLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 7),
	Size = UDim2.new(1, -20, 0, 16),
	Font = Enum.Font.GothamBold,
	Text = "Đang đồng bộ trạng thái từ máy chủ...",
	TextColor3 = THEME.TextSub,
	TextSize = 11,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = StatusCard
})

local StatusDetailLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 26),
	Size = UDim2.new(1, -20, 0, 34),
	Font = Enum.Font.Code,
	Text = "Gói: Chưa kích hoạt • Hạn: --\nHWID: " .. DEVICE_HWID,
	TextColor3 = THEME.TextMuted,
	TextSize = 10,
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
		"Gói: %s • Thời hạn: %s\nThiết bị: %s (%d/%d máy)",
		tostring(m.package or "VIP"),
		tostring(rem or "--"),
		tostring(m.bound_hwid or DEVICE_HWID),
		tonumber(m.device_count or 0),
		tonumber(m.max_devices or 1)
	)
	if State.minimized and m.valid then
		FloatingOrb.Text = "BIVA • " .. tostring(rem or "VIP")
	else
		FloatingOrb.Text = "BIVA v6.0 • STUDIO"
	end
end
-- ==============================================================================
-- 7. TAB 2: BẢNG GIÁ 6 GÓI CHỦ LỰC + MÃ GIẢM GIÁ + VIETQR TỰ ĐỘNG
-- ==============================================================================
local FlashSaleBar = New("Frame", {
	BackgroundColor3 = Color3.fromRGB(38, 22, 10),
	Size = UDim2.new(1, 0, 0, 26),
	Visible = false,
	Parent = TabPages.shop
})
Corner(FlashSaleBar, 7)
New("UIStroke", { Color = Color3.fromRGB(245, 158, 11), Thickness = 1, Transparency = 0.25, Parent = FlashSaleBar })

local FlashSaleLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 0),
	Size = UDim2.new(1, -20, 1, 0),
	Font = Enum.Font.GothamBold,
	Text = "FLASH SALE ĐANG DIỄN RA",
	TextColor3 = Color3.fromRGB(251, 191, 36),
	TextSize = 10.5,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = FlashSaleBar
})

local VoucherBar = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 32),
	Parent = TabPages.shop
})
Corner(VoucherBar, 7)
Stroke(VoucherBar, "Border", 1, 0.2)
BindTheme(VoucherBar, "BackgroundColor3", "BgElevated")

local VoucherBoxInput = New("TextBox", {
	BackgroundColor3 = THEME.BgInput,
	Position = UDim2.new(0, 5, 0, 4),
	Size = UDim2.new(1, -116, 0, 24),
	Font = Enum.Font.Code,
	PlaceholderText = "Mã giảm giá (VD: BIVA20)...",
	PlaceholderColor3 = THEME.TextMuted,
	Text = "",
	TextColor3 = THEME.Accent,
	TextSize = 10.5,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = VoucherBar
})
Corner(VoucherBoxInput, 5)
New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = VoucherBoxInput })
BindTheme(VoucherBoxInput, "BackgroundColor3", "BgInput")
BindTheme(VoucherBoxInput, "TextColor3", "Accent")

local ApplyVoucherBtn = New("TextButton", {
	BackgroundColor3 = THEME.Primary,
	Position = UDim2.new(1, -106, 0, 4),
	Size = UDim2.new(0, 101, 0, 24),
	Font = Enum.Font.GothamBold,
	Text = "Áp Dụng Mã",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = VoucherBar
})
Corner(ApplyVoucherBtn, 5)
BindTheme(ApplyVoucherBtn, "BackgroundColor3", "Primary")

local PlansGrid = New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 214),
	Parent = TabPages.shop
})
New("UIGridLayout", {
	CellPadding = UDim2.new(0, 8, 0, 8),
	CellSize = UDim2.new(0.5, -4, 0, 66),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = PlansGrid
})

local CorePlans = {
	{ pkg = "Free", title = "Dùng Thử • 20 Giờ", price = "Miễn Phí = Vượt Link", base = 0, sub = "Vượt link rút gọn • Khóa 1 HWID", isFree = true },
	{ pkg = "1 Ngày", title = "Gói 1 Ngày • 24 Giờ", price = "8.000đ = 1 Ngày", base = 8000, sub = "VietQR duyệt 3 giây • Vào thẳng", isFree = false },
	{ pkg = "1 Tuần", title = "Gói 1 Tuần • 7 Ngày", price = "40.000đ = 1 Tuần", base = 40000, sub = "Tiết kiệm 16.000đ • Tự đổi máy", isFree = false },
	{ pkg = "1 Tháng", title = "Gói 1 Tháng • 30 Ngày", price = "130.000đ = 1 Tháng", base = 130000, sub = "Tiết kiệm 110.000đ • Ưu tiên VIP", isFree = false },
	{ pkg = "1 Năm VIP", title = "Gói 1 Năm VIP • 365 Ngày", price = "200.000đ = 1 Năm VIP", base = 200000, sub = "Tối ưu dài hạn • Đồng bộ Cloud", isFree = false },
	{ pkg = "Vĩnh Viễn", title = "Vĩnh Viễn • Ultra Instinct", price = "250.000đ = Vĩnh Viễn", base = 250000, sub = "Trọn đời • Toàn bộ đặc quyền", isFree = false }
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

ApplyVoucherBtn.MouseButton1Click:Connect(function()
	local vCode = cleanKey(VoucherBoxInput.Text)
	if #vCode < 2 then
		State.voucher_code = ""
		State.voucher_discount = 0
		refreshPlanPrices()
		showToast("Vui lòng nhập mã giảm giá hợp lệ.", true)
		return
	end
	ApplyVoucherBtn.Text = "Đang kiểm..."
	task.spawn(function()
		local res = apiCall("/api/check_voucher?code=" .. urlEncode(vCode) .. "&package=" .. urlEncode("1 Ngày"), "GET")
		ApplyVoucherBtn.Text = "Áp Dụng Mã"
		if res and res.success then
			State.voucher_code = tostring(res.code or vCode)
			State.voucher_discount = tonumber(res.discount_percent) or 0
			State.voucher_bonus_hours = tonumber(res.bonus_hours) or 0
			refreshPlanPrices()
			showToast(tostring(res.message or ("Đã áp dụng giảm " .. State.voucher_discount .. "%.")), false)
		else
			State.voucher_code = ""
			State.voucher_discount = 0
			refreshPlanPrices()
			showToast((res and res.message) or "Mã giảm giá không hợp lệ.", true)
		end
	end)
end)

local FootnoteBox = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 44),
	Parent = TabPages.shop
})
Corner(FootnoteBox, 8)
Stroke(FootnoteBox, "Border", 1, 0.2)
BindTheme(FootnoteBox, "BackgroundColor3", "BgElevated")

local FootnoteLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 3),
	Size = UDim2.new(1, -20, 1, -6),
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
	Size = UDim2.new(1, 0, 0, 66),
	Parent = TabPages.shop
})
Corner(ShopOrderBox, 8)
Stroke(ShopOrderBox, "Border", 1, 0.2)
BindTheme(ShopOrderBox, "BackgroundColor3", "BgInput")

local ShopOrderTitle = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 5),
	Size = UDim2.new(1, -20, 0, 15),
	Font = Enum.Font.GothamBold,
	Text = "Chọn gói phía trên để nhận link vượt hoặc khởi tạo mã VietQR",
	TextColor3 = THEME.Accent,
	TextSize = 10.5,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = ShopOrderBox
})
BindTheme(ShopOrderTitle, "TextColor3", "Accent")

local ShopOrderSub = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 21),
	Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.GothamMedium,
	Text = "Sau khi chuyển khoản trên trình duyệt, Studio tự động nhận Key trong 3 giây.",
	TextColor3 = THEME.TextSub,
	TextSize = 9.5,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = ShopOrderBox
})
BindTheme(ShopOrderSub, "TextColor3", "TextSub")

local CheckPaidBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(0, 10, 0, 38),
	Size = UDim2.new(0.49, -12, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "Kiểm Tra Thanh Toán",
	TextColor3 = THEME.Accent,
	TextSize = 10,
	AutoButtonColor = false,
	Parent = ShopOrderBox
})
Corner(CheckPaidBtn, 5)
Stroke(CheckPaidBtn, "Border", 1, 0.25)
BindTheme(CheckPaidBtn, "BackgroundColor3", "BgElevated")
BindTheme(CheckPaidBtn, "TextColor3", "Accent")

local CopyShopLinkBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(0.51, 2, 0, 38),
	Size = UDim2.new(0.49, -12, 0, 22),
	Font = Enum.Font.GothamBold,
	Text = "Sao Chép Link Web Shop",
	TextColor3 = THEME.TextMain,
	TextSize = 10,
	AutoButtonColor = false,
	Parent = ShopOrderBox
})
Corner(CopyShopLinkBtn, 5)
Stroke(CopyShopLinkBtn, "Border", 1, 0.25)
BindTheme(CopyShopLinkBtn, "BackgroundColor3", "BgElevated")
BindTheme(CopyShopLinkBtn, "TextColor3", "TextMain")

CopyShopLinkBtn.MouseButton1Click:Connect(function()
	local link = WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID)
	if State.voucher_code ~= "" then
		link = link .. "&voucher=" .. urlEncode(State.voucher_code)
	end
	copyClipboard(link)
	showToast("Đã sao chép link Web Shop kèm HWID.", false)
end)

-- ==============================================================================
-- 8. TAB 3: KHO KEY, GÁN HWID & ĐỔI THIẾT BỊ (RESET HWID)
-- ==============================================================================
local BindFreeRow = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 36),
	Parent = TabPages.vault
})
Corner(BindFreeRow, 8)
Stroke(BindFreeRow, "Border", 1, 0.2)
BindTheme(BindFreeRow, "BackgroundColor3", "BgElevated")

local BindFreeInput = New("TextBox", {
	BackgroundColor3 = THEME.BgInput,
	Position = UDim2.new(0, 6, 0, 4),
	Size = UDim2.new(1, -130, 0, 28),
	Font = Enum.Font.Code,
	PlaceholderText = "Nhập Key chưa gắn hoặc Key Clan...",
	PlaceholderColor3 = THEME.TextMuted,
	Text = "",
	TextColor3 = THEME.TextMain,
	TextSize = 11,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = BindFreeRow
})
Corner(BindFreeInput, 6)
New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = BindFreeInput })
BindTheme(BindFreeInput, "BackgroundColor3", "BgInput")
BindTheme(BindFreeInput, "TextColor3", "TextMain")

local BindFreeBtn = New("TextButton", {
	BackgroundColor3 = THEME.Primary,
	Position = UDim2.new(1, -118, 0, 4),
	Size = UDim2.new(0, 112, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Gán Thiết Bị Này",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = BindFreeRow
})
Corner(BindFreeBtn, 6)
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
	BackgroundColor3 = Color3.fromRGB(4, 7, 13),
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
	Size = UDim2.new(0, 324, 0, 148),
	ZIndex = 81,
	Parent = ResetModal
})
Corner(ResetCard, 10)
Stroke(ResetCard, "Accent", 1, 0.35)
BindTheme(ResetCard, "BackgroundColor3", "BgCard")

local ResetTitleLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 12),
	Size = UDim2.new(1, -28, 0, 18),
	Font = Enum.Font.GothamBold,
	Text = "Xác Nhận Gỡ Khóa Thiết Bị (Reset HWID)",
	TextColor3 = THEME.TextMain,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 82,
	Parent = ResetCard
})
BindTheme(ResetTitleLbl, "TextColor3", "TextMain")

local ResetDescLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 0, 34),
	Size = UDim2.new(1, -28, 0, 58),
	Font = Enum.Font.GothamMedium,
	Text = "Gỡ khóa thiết bị hiện tại cho mã Key này?",
	TextColor3 = THEME.TextSub,
	TextSize = 10.5,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 82,
	Parent = ResetCard
})
BindTheme(ResetDescLbl, "TextColor3", "TextSub")

local ResetCancelBtn = New("TextButton", {
	BackgroundColor3 = THEME.BgElevated,
	Position = UDim2.new(0, 14, 1, -40),
	Size = UDim2.new(0.46, 0, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Huỷ Bỏ",
	TextColor3 = THEME.TextSub,
	TextSize = 11,
	AutoButtonColor = false,
	ZIndex = 82,
	Parent = ResetCard
})
Corner(ResetCancelBtn, 6)
BindTheme(ResetCancelBtn, "BackgroundColor3", "BgElevated")
BindTheme(ResetCancelBtn, "TextColor3", "TextSub")

local ResetConfirmBtn = New("TextButton", {
	BackgroundColor3 = THEME.Primary,
	Position = UDim2.new(0.54, -14, 1, -40),
	Size = UDim2.new(0.46, 0, 0, 28),
	Font = Enum.Font.GothamBold,
	Text = "Xác Nhận Gỡ",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
	AutoButtonColor = false,
	ZIndex = 82,
	Parent = ResetCard
})
Corner(ResetConfirmBtn, 6)
BindTheme(ResetConfirmBtn, "BackgroundColor3", "Primary")

local targetResetKey = ""
ResetCancelBtn.MouseButton1Click:Connect(function()
	ResetModal.Visible = false
end)

-- ==============================================================================
-- 9. TAB 4: LỊCH SỬ ĐƠN HÀNG & GỬI YÊU CẦU HỖ TRỢ ADMIN
-- ==============================================================================
local TicketCard = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 68),
	Parent = TabPages.support
})
Corner(TicketCard, 8)
Stroke(TicketCard, "Border", 1, 0.2)
BindTheme(TicketCard, "BackgroundColor3", "BgElevated")

local TicketHeaderLbl = New("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 10, 0, 5),
	Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.GothamBold,
	Text = "GỬI YÊU CẦU HỖ TRỢ / MỞ KHÓA THIẾT BỊ TỚI ADMIN",
	TextColor3 = THEME.TextMuted,
	TextSize = 9.5,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TicketCard
})
BindTheme(TicketHeaderLbl, "TextColor3", "TextMuted")

local TicketInput = New("TextBox", {
	BackgroundColor3 = THEME.BgInput,
	Position = UDim2.new(0, 8, 0, 23),
	Size = UDim2.new(1, -120, 0, 36),
	Font = Enum.Font.GothamMedium,
	PlaceholderText = "Nhập nội dung cần hỗ trợ (VD: Nhờ Admin Reset HWID)...",
	PlaceholderColor3 = THEME.TextMuted,
	Text = "",
	TextColor3 = THEME.TextMain,
	TextSize = 10.5,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TicketCard
})
Corner(TicketInput, 6)
New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = TicketInput })
BindTheme(TicketInput, "BackgroundColor3", "BgInput")
BindTheme(TicketInput, "TextColor3", "TextMain")

local SendTicketBtn = New("TextButton", {
	BackgroundColor3 = THEME.Primary,
	Position = UDim2.new(1, -106, 0, 23),
	Size = UDim2.new(0, 98, 0, 36),
	Font = Enum.Font.GothamBold,
	Text = "Gửi Yêu Cầu",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 10.5,
	AutoButtonColor = false,
	Parent = TicketCard
})
Corner(SendTicketBtn, 6)
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
-- 10. TAB 5: TIỆN ÍCH HỆ THỐNG, CHỦ ĐỀ STUDIO & PILL SWITCHES MƯỢT
-- ==============================================================================
local ThemeBar = New("Frame", {
	BackgroundColor3 = THEME.BgElevated,
	Size = UDim2.new(1, 0, 0, 44),
	Parent = TabPages.utils
})
Corner(ThemeBar, 8)
Stroke(ThemeBar, "Border", 1, 0.2)
BindTheme(ThemeBar, "BackgroundColor3", "BgElevated")

local ThemeGrid = New("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 8, 0, 7),
	Size = UDim2.new(1, -16, 0, 30),
	Parent = ThemeBar
})
New("UIGridLayout", {
	CellPadding = UDim2.new(0, 6, 0, 6),
	CellSize = UDim2.new(0.25, -5, 0, 30),
	Parent = ThemeGrid
})

for _, tKey in ipairs({ "UltraInstinct", "Platinum", "Emerald", "Cobalt" }) do
	local tMeta = THEMES[tKey]
	local tb = New("TextButton", {
		BackgroundColor3 = tMeta.BgCard,
		Font = Enum.Font.GothamBold,
		Text = tMeta.Name,
		TextColor3 = tMeta.Accent,
		TextSize = 10.5,
		AutoButtonColor = false,
		Parent = ThemeGrid
	})
	Corner(tb, 6)
	New("UIStroke", { Color = tMeta.Border, Thickness = 1, Transparency = 0.1, Parent = tb })
	local swatch = New("Frame", {
		BackgroundColor3 = tMeta.Accent,
		Position = UDim2.new(0, 7, 0.5, -3),
		Size = UDim2.new(0, 6, 0, 6),
		BorderSizePixel = 0,
		Parent = tb
	})
	Corner(swatch, 3)
	tb.MouseButton1Click:Connect(function()
		SetTheme(tKey)
		showToast("Đã chuyển giao diện: " .. tMeta.Name, false)
	end)
end

local ToggleGrid = New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 88),
	Parent = TabPages.utils
})
New("UIGridLayout", {
	CellPadding = UDim2.new(0, 8, 0, 8),
	CellSize = UDim2.new(0.5, -4, 0, 40),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = ToggleGrid
})

local function addStudioSwitch(label, cfgKey, defaultTrue, onToggle)
	local row = New("TextButton", {
		BackgroundColor3 = THEME.BgElevated,
		Text = "",
		AutoButtonColor = false,
		Parent = ToggleGrid
	})
	Corner(row, 8)
	Stroke(row, "Border", 1, 0.2)
	BindTheme(row, "BackgroundColor3", "BgElevated")

	local title = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = label,
		TextColor3 = THEME.TextMain,
		TextSize = 10.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row
	})
	BindTheme(title, "TextColor3", "TextMain")

	local function getVal()
		if defaultTrue then
			return State.config[cfgKey] ~= false
		end
		return State.config[cfgKey] == true
	end

	local track = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 18),
		BackgroundColor3 = getVal() and THEME.Primary or THEME.BgInput,
		BorderSizePixel = 0,
		Parent = row
	})
	Corner(track, 9)
	Stroke(track, "Border", 1, 0.35)

	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = getVal() and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = Color3.fromRGB(248, 250, 252),
		BorderSizePixel = 0,
		Parent = track
	})
	Corner(knob, 7)

	local function syncVisual(instant)
		local active = getVal()
		local targetBg = active and THEME.Primary or THEME.BgInput
		local targetPos = active and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		if instant then
			track.BackgroundColor3 = targetBg
			knob.Position = targetPos
		else
			TweenService:Create(track, TWEEN_FAST, { BackgroundColor3 = targetBg }):Play()
			TweenService:Create(knob, TWEEN_FAST, { Position = targetPos }):Play()
		end
	end
	table.insert(PillRefreshers, syncVisual)

	row.MouseButton1Click:Connect(function()
		local nextState = not getVal()
		State.config[cfgKey] = nextState
		saveConfig(State.config)
		syncVisual(false)
		if onToggle then onToggle(nextState) end
	end)
end

addStudioSwitch("Bản Năng Vô Cực", "ultra_instinct", true, function(st)
	pcall(function()
		local g = (type(getgenv) == "function") and getgenv() or _G
		if type(g) == "table" then g.BIVA_ULTRA_INSTINCT = st end
	end)
	showToast("Bản Năng Vô Cực: " .. (st and "Đã bật" or "Tạm tắt"), false)
end)

addStudioSwitch("Tự Động Đăng Nhập", "auto_login", true, function(st)
	showToast("Tự động đăng nhập: " .. (st and "Đã bật" or "Tạm tắt"), false)
end)

addStudioSwitch("Chống Treo (Anti-AFK)", "anti_afk", true, function(st)
	showToast("Chống treo Anti-AFK: " .. (st and "Đã bật" or "Tạm tắt"), false)
end)

addStudioSwitch("Âm Thanh Tương Tác", "sound_fx", true, function(st)
	showToast("Âm thanh giao diện: " .. (st and "Đã bật" or "Tạm tắt"), false)
end)

local ActionUtilsGrid = New("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 128),
	Parent = TabPages.utils
})
New("UIGridLayout", {
	CellPadding = UDim2.new(0, 8, 0, 8),
	CellSize = UDim2.new(0.5, -4, 0, 36),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = ActionUtilsGrid
})

local function addActionUtilBtn(label, fn)
	local b = New("TextButton", {
		BackgroundColor3 = THEME.BgElevated,
		Font = Enum.Font.GothamBold,
		Text = label,
		TextColor3 = THEME.TextMain,
		TextSize = 10.5,
		AutoButtonColor = false,
		Parent = ActionUtilsGrid
	})
	Corner(b, 8)
	Stroke(b, "Border", 1, 0.2)
	BindTheme(b, "BackgroundColor3", "BgElevated")
	BindTheme(b, "TextColor3", "TextMain")
	b.MouseButton1Click:Connect(function() fn(b) end)
end

addActionUtilBtn("Tối Ưu FPS (Không Khựng)", function(btn)
	if State.optimizing_fps then return end
	State.optimizing_fps = true
	btn.Text = "Đang tối ưu FPS..."
	task.spawn(function()
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
		end)
		local okList, descendants = pcall(function() return workspace:GetDescendants() end)
		if okList and type(descendants) == "table" then
			local myChar = LocalPlayer.Character
			for i, v in ipairs(descendants) do
				if not LoaderAlive then break end
				if v and v.Parent and not (myChar and v:IsDescendantOf(myChar)) then
					if v:IsA("BasePart") then
						pcall(function()
							v.Material = Enum.Material.SmoothPlastic
							v.Reflectance = 0
							v.CastShadow = false
						end)
					elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
						pcall(function() v.Enabled = false end)
					end
				end
				if i % 350 == 0 then
					task.wait()
				end
			end
		end
		State.optimizing_fps = false
		if btn and btn.Parent then
			btn.Text = "Tối Ưu FPS (Không Khựng)"
		end
		showToast("Đã hoàn tất tối ưu FPS mượt mà.", false)
	end)
end)

addActionUtilBtn("Kết Nối Lại Server (Rejoin)", function()
	showToast("Đang kết nối lại máy chủ hiện tại...", false)
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

addActionUtilBtn("Đổi Server Ít Người (Hop)", function()
	showToast("Đang dò tìm máy chủ ít người...", false)
	task.spawn(function()
		local ok, _, raw = rawHttp("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100", "GET")
		if ok and raw ~= "" then
			local decOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
			if decOk and type(data) == "table" and type(data.data) == "table" then
				for _, srv in ipairs(data.data) do
					if type(srv) == "table" and srv.id ~= game.JobId and (tonumber(srv.playing) or 0) < (tonumber(srv.maxPlayers) or 1) then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
						return
					end
				end
			end
		end
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
end)

addActionUtilBtn("Sao Chép Loader Kèm Key", function()
	local k = cleanKey(State.config.saved_key)
	if k == "" then
		showToast("Chưa có mã Key nào được lưu.", true)
		return
	end
	local s = string.format('getgenv().BIVA_AUTO_KEY = "%s"; loadstring(game:HttpGet("%s"))()', k, LOADER_RAW_URL)
	copyClipboard(s)
	showToast("Đã sao chép Script kèm sẵn mã Key.", false)
end)

addActionUtilBtn("Sao Chép PlaceId & JobId", function()
	local info = string.format("PlaceId: %s | JobId: %s", tostring(game.PlaceId), tostring(game.JobId))
	copyClipboard(info)
	showToast("Đã sao chép PlaceId & JobId.", false)
end)

-- ==============================================================================
-- 11. ĐỒNG BỘ DỮ LIỆU OMNI-SYNC, NẠP SCRIPT & XỬ LÝ SỰ KIỆN
-- ==============================================================================
local renderVaultUI
local renderSupportUI
local verifyAndRunScript

local function sendTelemetry(keyCode)
	task.spawn(function()
		apiCall("/api/telemetry", "POST", {
			key = keyCode or State.config.saved_key or "",
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
	pruneThemeBindings()

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
				time_left = "Nhấn Nạp để kiểm tra",
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
		Stroke(empty, "Border", 1, 0.25)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -20, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = "Chưa có mã Key nào gắn với HWID [" .. DEVICE_HWID .. "]. Chuyển sang tab Bảng Giá Key để khởi tạo.",
			TextColor3 = THEME.TextSub,
			TextSize = 10.5,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
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
			Size = UDim2.new(1, 0, 0, 50),
			Parent = VaultList
		})
		Corner(row, 8)
		Stroke(row, "Border", 1, 0.25)
		BindTheme(row, "BackgroundColor3", "BgInput")

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 5),
			Size = UDim2.new(0.55, 0, 0, 18),
			Font = Enum.Font.Code,
			Text = code,
			TextColor3 = THEME.Accent,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row
		})

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 24),
			Size = UDim2.new(0.55, 0, 0, 20),
			Font = Enum.Font.GothamMedium,
			Text = string.format("Gói: %s • %s (%d/%d máy)", pkg, left, devCnt, maxDev),
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
			Text = "Nạp",
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
			Text = "Copy",
			TextColor3 = THEME.TextMain,
			TextSize = 10,
			AutoButtonColor = false,
			Parent = row
		})
		Corner(cpBtn, 6)

		local rstBtn = New("TextButton", {
			BackgroundColor3 = Color3.fromRGB(48, 32, 12),
			Position = UDim2.new(1, -62, 0.5, -13),
			Size = UDim2.new(0, 54, 0, 26),
			Font = Enum.Font.GothamBold,
			Text = "Đổi Máy",
			TextColor3 = THEME.Warn,
			TextSize = 10,
			AutoButtonColor = false,
			Parent = row
		})
		Corner(rstBtn, 6)

		useBtn.MouseButton1Click:Connect(function()
			State.config.saved_key = code
			saveConfig(State.config, true)
			KeyInput.Text = State.config.hide_key and maskKey(code) or code
			switchTab("auth")
			verifyAndRunScript(code)
		end)

		cpBtn.MouseButton1Click:Connect(function()
			copyClipboard(code)
			showToast("Đã sao chép Key: " .. code, false)
		end)

		rstBtn.MouseButton1Click:Connect(function()
			targetResetKey = code
			ResetDescLbl.Text = "Gỡ khóa thiết bị hiện tại cho Key [" .. code .. "] để chuyển sang máy mới?"
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
		Stroke(empty, "Border", 1, 0.25)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -20, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = "Chưa có lịch sử đơn hàng hoặc yêu cầu hỗ trợ trên thiết bị này.",
			TextColor3 = THEME.TextSub,
			TextSize = 10.5,
			TextXAlignment = Enum.TextXAlignment.Left,
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
		Stroke(row, "Border", 1, 0.25)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 5),
			Size = UDim2.new(1, -20, 0, 16),
			Font = Enum.Font.GothamBold,
			Text = string.format("[%s] %s", tostring(t.ticket_id or "TICKET"), isDone and "Đã phản hồi" or "Đang chờ xử lý"),
			TextColor3 = isDone and THEME.Ok or THEME.Warn,
			TextSize = 10.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row
		})
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 23),
			Size = UDim2.new(1, -20, 0, 18),
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
		Stroke(row, "Border", 1, 0.25)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 5),
			Size = UDim2.new(0.7, 0, 0, 16),
			Font = Enum.Font.GothamBold,
			Text = string.format("Đơn #%s • %s (%s)", oid, pkg, formatVND(o.price or 0)),
			TextColor3 = THEME.TextMain,
			TextSize = 10.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row
		})
		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 23),
			Size = UDim2.new(0.7, 0, 0, 16),
			Font = Enum.Font.Code,
			Text = isPaid and ("Key: " .. (issued ~= "" and issued or "Đã cấp")) or "Đang chờ thanh toán",
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
			LiveStatusDot.BackgroundColor3 = THEME.Warn
			SubHeaderLbl.Text = "Máy chủ đang khởi động... vui lòng chờ vài giây"
			if showToastMsg then showToast("Máy chủ đang thức dậy, vui lòng thử lại sau vài giây.", true) end
			return
		end

		State.sync_rev = tonumber(data.sync_revision) or State.sync_rev
		State.ping = ping
		LiveStatusDot.BackgroundColor3 = THEME.Ok
		SubHeaderLbl.Text = string.format("%s • REV #%d • %dms", EXECUTOR_NAME, State.sync_rev, ping)

		if data.admin_notice and tostring(data.admin_notice) ~= "" then
			State.admin_notice = tostring(data.admin_notice)
			NoticeLbl.Text = State.admin_notice
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
					"%s • Còn %s",
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
				setStatus("Đã nhận diện Key [" .. code .. "] (" .. State.key_meta.package .. ")", THEME.Accent)
				if showToastMsg then showToast("Đã đồng bộ Key: " .. code, false) end
				if autoRunIfValid and State.config.auto_login and not data.maintenance then
					verifyAndRunScript(code)
				end
				return
			end
		end

		if showToastMsg then
			showToast("Chưa tìm thấy Key còn hạn gắn với HWID này.", true)
		end
		setStatus("Nhập Key bản quyền hoặc chọn gói ở tab Bảng Giá Key để kích hoạt.", THEME.TextSub)
	end)
end

verifyAndRunScript = function(rawKey)
	if State.busy then return end
	local k = cleanKey(rawKey)
	if k == "" or string.find(tostring(rawKey or ""), "•", 1, true) then
		k = cleanKey(State.config.saved_key)
	end
	if #k < 4 then
		setStatus("Vui lòng nhập mã Key hợp lệ trước khi kích hoạt.", THEME.Err)
		showToast("Vui lòng nhập mã Key hợp lệ.", true)
		return
	end

	State.busy = true
	ActivateBtn.Text = "Đang xác thực..."
	setStatus("Đang kiểm tra Key [" .. k .. "] trên máy chủ...", THEME.Warn)

	task.spawn(function()
		local vPath = string.format("/api/verify_key?key=%s&hwid=%s&auto_bind=true", urlEncode(k), urlEncode(DEVICE_HWID))
		local vData = apiCall(vPath, "GET")
		if not vData then
			State.busy = false
			ActivateBtn.Text = "KÍCH HOẠT & MỞ STUDIO"
			setStatus("Không thể kết nối máy chủ, vui lòng thử lại.", THEME.Err)
			showToast("Lỗi kết nối máy chủ.", true)
			return
		end

		if not vData.valid then
			State.busy = false
			ActivateBtn.Text = "KÍCH HOẠT & MỞ STUDIO"
			local msg = tostring(vData.detail or vData.message or "Mã Key không hợp lệ hoặc đã hết hạn.")
			setStatus(msg, THEME.Err)
			showToast(msg, true)
			if vData.hwid_match == false then switchTab("vault") end
			return
		end

		local confirmed = cleanKey(vData.key_code or k)
		State.config.saved_key = confirmed
		saveConfig(State.config, true)
		saveKeyToVault(confirmed, vData.package or "VIP")
		KeyInput.Text = State.config.hide_key and maskKey(confirmed) or confirmed

		pcall(function()
			local g = (type(getgenv) == "function") and getgenv() or _G
			if type(g) == "table" then
				if vData.session_sig then
					g.BIVA_SESSION_SIG = tostring(vData.session_sig)
				end
				g.BIVA_ULTRA_INSTINCT = (State.config.ultra_instinct ~= false)
				g.BIVA_KEY = confirmed
				g.BIVA_HWID = DEVICE_HWID
			end
		end)

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
		sendTelemetry(confirmed)

		local gameId = State.config.selected_game or "steal_egg"
		ActivateBtn.Text = "Đang nạp Studio..."
		local sPath = string.format("/api/get_script?key=%s&hwid=%s&game_id=%s", urlEncode(confirmed), urlEncode(DEVICE_HWID), urlEncode(gameId))
		local luaCode = apiCall(sPath, "GET", nil, true)
		State.busy = false
		ActivateBtn.Text = "KÍCH HOẠT & MỞ STUDIO"

		if type(luaCode) == "string" and #luaCode > 20 then
			local fn, err = loadstring(luaCode)
			if type(fn) == "function" then
				setStatus("Đã kích hoạt BIVA STORM v6.0 thành công.", THEME.Ok)
				showToast("Đã mở BIVA STORM v6.0 [ULTRA INSTINCT].", false)
				task.spawn(function() pcall(fn) end)
				task.delay(0.55, function()
					if MainWindow and MainWindow.Parent then
						MainWindow.Visible = false
						FloatingOrb.Visible = true
						State.minimized = true
						refreshStatusCard()
					end
				end)
			else
				setStatus("Lỗi biên dịch Script: " .. tostring(err), THEME.Err)
			end
		else
			setStatus("Không tải được dữ liệu Script từ máy chủ.", THEME.Err)
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
			if not LoaderAlive then break end
			local oid = State.config.pending_order_id
			if not oid or oid == "" then break end
			local res = apiCall("/api/check_order?order_id=" .. urlEncode(oid), "GET")
			if res and res.status == "paid" and res.key then
				local newK = cleanKey(res.key)
				State.config.pending_order_id = ""
				State.config.saved_key = newK
				saveConfig(State.config, true)
				saveKeyToVault(newK, pkgName)
				KeyInput.Text = State.config.hide_key and maskKey(newK) or newK
				ShopOrderTitle.Text = "Đơn #" .. oid .. " đã thanh toán — Key: " .. newK
				showToast("Đã nhận Key tự động: " .. newK, false)
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
	Corner(card, 8)
	Stroke(card, p.isFree and "Border" or "Accent", 1, p.isFree and 0.2 or 0.55)
	BindTheme(card, "BackgroundColor3", "BgElevated")

	local cardTitle = New("TextLabel", {
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
	BindTheme(cardTitle, "TextColor3", "TextMain")

	local pLbl = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 18),
		Size = UDim2.new(1, -16, 0, 16),
		Font = Enum.Font.Code,
		Text = p.price,
		TextColor3 = THEME.Accent,
		TextSize = 11.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card
	})
	BindTheme(pLbl, "TextColor3", "Accent")
	table.insert(PlanPriceLabels, { lbl = pLbl, base = p.base, pkg = p.pkg })

	local cardSub = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 35),
		Size = UDim2.new(0.62, 0, 0, 14),
		Font = Enum.Font.GothamMedium,
		Text = p.sub,
		TextColor3 = THEME.TextSub,
		TextSize = 9,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card
	})
	BindTheme(cardSub, "TextColor3", "TextSub")

	local actionBtn = New("TextButton", {
		BackgroundColor3 = p.isFree and THEME.BgInput or THEME.Primary,
		Position = UDim2.new(1, -84, 1, -24),
		Size = UDim2.new(0, 76, 0, 19),
		Font = Enum.Font.GothamBold,
		Text = p.isFree and "Vượt Link" or "Mua Ngay",
		TextColor3 = p.isFree and THEME.Accent or Color3.fromRGB(255, 255, 255),
		TextSize = 10,
		AutoButtonColor = false,
		Parent = card
	})
	Corner(actionBtn, 5)
	if p.isFree then
		Stroke(actionBtn, "Accent", 1, 0.55)
		BindTheme(actionBtn, "BackgroundColor3", "BgInput")
		BindTheme(actionBtn, "TextColor3", "Accent")
	else
		BindTheme(actionBtn, "BackgroundColor3", "Primary")
	end

	actionBtn.MouseButton1Click:Connect(function()
		if p.isFree then
			ShopOrderTitle.Text = "Đang khởi tạo link vượt nhận Key Miễn Phí (20 Giờ)..."
			task.spawn(function()
				local res = apiCall("/api/get_free_link?hwid=" .. urlEncode(DEVICE_HWID) .. "&game=rb", "POST", {
					hwid = DEVICE_HWID,
					game = "rb"
				})
				if res and res.success and res.link then
					copyClipboard(res.link)
					ShopOrderTitle.Text = "Đã sao chép link vượt Key Miễn Phí (20 Giờ) vào bộ nhớ tạm."
					ShopOrderSub.Text = "Dán link vừa sao chép ra trình duyệt (Chrome/Safari) để nhận Key."
					showToast("Đã sao chép link nhận Key Miễn Phí.", false)
				elseif res and res.existing_key then
					local ex = cleanKey(res.existing_key)
					State.config.saved_key = ex
					saveConfig(State.config, true)
					KeyInput.Text = State.config.hide_key and maskKey(ex) or ex
					showToast("Thiết bị đang có Key Miễn Phí còn hạn: " .. ex, false)
					switchTab("auth")
				else
					showToast((res and res.message) or "Không thể tạo link vượt lúc này.", true)
				end
			end)
		else
			ShopOrderTitle.Text = "Đang khởi tạo mã VietQR cho gói [" .. p.pkg .. "]..."
			task.spawn(function()
				local vParam = (State.voucher_code ~= "") and ("&voucher=" .. urlEncode(State.voucher_code)) or ""
				local path = string.format("/api/create_order?game=rb&package=%s&hwid=%s%s", urlEncode(p.pkg), urlEncode(DEVICE_HWID), vParam)
				local res = apiCall(path, "POST", {
					game = "rb",
					package = p.pkg,
					hwid = DEVICE_HWID,
					voucher = State.voucher_code
				})
				if res and res.success and res.order_id then
					local payLink = (res.checkout_url and res.checkout_url ~= "") and res.checkout_url or (WEB_SHOP_URL .. "?hwid=" .. urlEncode(DEVICE_HWID))
					copyClipboard(payLink)
					ShopOrderTitle.Text = "Đơn #" .. tostring(res.order_id) .. " (" .. formatVND(res.price or p.base) .. ") — Đã sao chép link QR"
					ShopOrderSub.Text = "Dán link ra trình duyệt để quét VietQR. Studio tự động kích hoạt sau 3 giây."
					showToast("Đã sao chép link thanh toán đơn #" .. tostring(res.order_id), false)
					watchInGameOrder(res.order_id, p.pkg)
				else
					showToast((res and (res.detail or res.message)) or "Lỗi tạo đơn hàng.", true)
				end
			end)
		end
	end)
end

-- Sự kiện điều khiển chính
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
		showToast("Vui lòng nhập mã Giftcode sự kiện.", true)
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
			saveConfig(State.config, true)
			KeyInput.Text = State.config.hide_key and maskKey(k) or k
			saveKeyToVault(k, res.package or "Giftcode")
			showToast("Đổi Giftcode thành công — Key: " .. k, false)
			runOmniSync(false, true)
		else
			showToast((res and (res.message or res.detail)) or "Mã Giftcode không hợp lệ.", true)
		end
	end)
end)

BindFreeBtn.MouseButton1Click:Connect(function()
	local k = cleanKey(BindFreeInput.Text)
	if #k < 4 then
		showToast("Vui lòng nhập mã Key cần gắn.", true)
		return
	end
	task.spawn(function()
		local res = apiCall("/api/verify_key?key=" .. urlEncode(k) .. "&hwid=" .. urlEncode(DEVICE_HWID) .. "&auto_bind=true", "GET")
		if res and res.valid then
			local ck = cleanKey(res.key_code or k)
			BindFreeInput.Text = ""
			State.config.saved_key = ck
			saveConfig(State.config, true)
			KeyInput.Text = State.config.hide_key and maskKey(ck) or ck
			saveKeyToVault(ck, res.package or "VIP")
			showToast("Đã gắn thiết bị vào Key " .. ck, false)
			runOmniSync(false, false)
		else
			showToast((res and (res.detail or res.message)) or "Không thể gắn mã Key này.", true)
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
			showToast(tostring(res.message or "Đã gỡ khóa thiết bị thành công."), false)
			runOmniSync(false, false)
		else
			showToast((res and (res.message or res.detail)) or "Chưa thể gỡ khóa thiết bị lúc này.", true)
		end
	end)
end)

SendTicketBtn.MouseButton1Click:Connect(function()
	local msg = tostring(TicketInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if #msg < 4 then
		showToast("Vui lòng nhập nội dung cần hỗ trợ.", true)
		return
	end
	SendTicketBtn.Text = "Đang gửi..."
	task.spawn(function()
		local res = apiCall("/api/support_ticket", "POST", {
			hwid = DEVICE_HWID,
			key = State.config.saved_key or "",
			topic = "Hỗ trợ In-Game / Mở khóa HWID",
			message = msg
		})
		SendTicketBtn.Text = "Gửi Yêu Cầu"
		if res and res.success then
			TicketInput.Text = ""
			showToast("Đã gửi yêu cầu hỗ trợ tới Admin.", false)
			runOmniSync(false, false)
		else
			showToast((res and (res.message or res.detail)) or "Không thể gửi yêu cầu lúc này.", true)
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
			saveConfig(State.config, true)
			KeyInput.Text = State.config.hide_key and maskKey(k) or k
			showToast("Đơn đã thanh toán — Key: " .. k, false)
			switchTab("auth")
			verifyAndRunScript(k)
		else
			showToast("Đơn hàng vẫn đang chờ xác nhận chuyển khoản.", false)
		end
	end)
end)

-- Thu nhỏ / Đóng / Phím tắt RightShift
local function toggleMin()
	State.minimized = not State.minimized
	MainWindow.Visible = not State.minimized
	FloatingOrb.Visible = State.minimized
	refreshStatusCard()
end

MinBtn.MouseButton1Click:Connect(toggleMin)
FloatingOrb.MouseButton1Click:Connect(toggleMin)
CloseBtn.MouseButton1Click:Connect(function() cleanupLoader() end)

trackLoaderConn(UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.RightShift and LoaderAlive then
		toggleMin()
	end
end))

trackLoaderConn(LocalPlayer.Idled:Connect(function()
	if LoaderAlive and State.config.anti_afk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

-- Bộ đếm thời gian 1s nhẹ (chỉ cập nhật khi cửa sổ hiển thị hoặc đang thu nhỏ có Key) & Telemetry 60s
task.spawn(function()
	local tickCounter = 0
	while LoaderAlive and ScreenGui and ScreenGui.Parent do
		task.wait(1)
		tickCounter = tickCounter + 1
		if State.key_meta.valid and State.key_meta.expire_ts > 0 then
			refreshStatusCard()
		end
		if tickCounter >= 60 then
			tickCounter = 0
			sendTelemetry(State.key_meta.key_code)
		end
	end
end)

switchTab("auth")
if State.config.pending_order_id and State.config.pending_order_id ~= "" then
	watchInGameOrder(State.config.pending_order_id, State.config.pending_package or "VIP")
end
runOmniSync(false, true)
