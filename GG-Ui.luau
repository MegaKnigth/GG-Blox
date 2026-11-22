

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local GGUI = { Windows = {}, Paints = {}, Version = "3.0.0" }
local Window, Tab, Comp, Minimizer = {}, {}, {}, {}
Window.__index = Window
Tab.__index = Tab
Comp.__index = Comp
Minimizer.__index = Minimizer

-- ===== CONFIGURAÇÕES =====
local REPO = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/main/assets/"
local TOPBAR_H = 28
local DEFAULT_W, DEFAULT_H = 620, 420

local LIMITS = {
	W = { 430, 1000 },
	H = { 200, 500 },
	TabsW = { 135, 210 },
	Scale = { 0.6, 1.6 },
}

local TIME = {
	Hover = 0.2, Fast = 0.15, Normal = 0.25, Tab = 0.45, Drop = 0.2,
	Slider = 0.3, Minimize = 0.25, NotifyIn = 0.35, NotifyOut = 0.8, Dialog = 0.3,
}

local ICONS = {
	Close = "rbxassetid://10747384394",
	Minimize = "rbxassetid://10734896206",
	Open = "rbxassetid://10709791523",
}

local DEFAULT_BACKGROUNDS = {
	{ nome = "Aventura", arquivo = "aventura.jpg" },
	{ nome = "Batman", arquivo = "batman.jpg" },
	{ nome = "Branco", arquivo = "branco.jpg" },
	{ nome = "Hollow Knight", arquivo = "hollowknight.jpg" },
	{ nome = "Jujutsu", arquivo = "jujutsu.jpg" },
	{ nome = "Mangá", arquivo = "manga.jpg" },
	{ nome = "Miku", arquivo = "miku.jpg" },
	{ nome = "Miku Code", arquivo = "mikucode.jpg" },
	{ nome = "Re:Zero", arquivo = "rezero.jpg" },
	{ nome = "Rosa", arquivo = "rosa.jpg" },
	{ nome = "Tóquio", arquivo = "toquio.jpg" },
}

-- As 12 cores de tema, camada e texto
local PALETTE = {
	{ name = "Rosa Suave", color = Color3.fromRGB(255,150,190) },
	{ name = "Azul Suave", color = Color3.fromRGB(120,180,255) },
	{ name = "Vermelho Carmesim", color = Color3.fromRGB(190,20,50) },
	{ name = "Roxo", color = Color3.fromRGB(150,90,230) },
	{ name = "Verde Menta", color = Color3.fromRGB(110,220,170) },
	{ name = "Amarelo Suave", color = Color3.fromRGB(255,225,130) },
	{ name = "Laranja", color = Color3.fromRGB(255,140,70) },
	{ name = "Ciano", color = Color3.fromRGB(80,220,235) },
	{ name = "Branco", color = Color3.fromRGB(255,255,255) },
	{ name = "Cinza", color = Color3.fromRGB(140,140,150) },
	{ name = "Preto", color = Color3.fromRGB(0,0,0) },
	{ name = "Dourado", color = Color3.fromRGB(212,175,55) },
}

-- Tema padrão "Darker", igual ao da Gold
local DARKER = {
	Background = Color3.fromRGB(25,25,25),
	Element = Color3.fromRGB(36,36,38),
	ElementHold = Color3.fromRGB(44,44,48),
	Stroke = Color3.fromRGB(55,55,58),
	Primary = Color3.fromRGB(88,101,242),
	Dropdown = Color3.fromRGB(30,30,30),
}

GGUI.State = {
	Base = "Darker",
	Tone = 20,
	TextName = "Branco",
	TomName = "Preto",
	Opacity = 5,
	Background = "Miku",
	TabsW = 160,
	W = DEFAULT_W,
	H = DEFAULT_H,
	UiScale = 80,
}

-- ===== CORES E TEMA =====
local function findColor(name)
	for _, p in ipairs(PALETTE) do
		if p.name == name then
			return p.color
		end
	end
	return nil
end

local function buildTheme(s)
	local t = {}
	local base = nil
	if s.Base ~= "Darker" then
		base = findColor(s.Base)
	end
	if base then
		local k = math.clamp((s.Tone or 20) / 100, 0, 1)
		local amt = 0.85 - 0.5 * k
		local bg = base:Lerp(Color3.new(0, 0, 0), amt)
		t.Background = bg
		t.Element = bg:Lerp(base, 0.15)
		t.ElementHold = bg:Lerp(base, 0.28)
		t.Stroke = bg:Lerp(base, 0.35)
		t.Dropdown = bg:Lerp(base, 0.1)
		t.Primary = base:Lerp(Color3.new(1, 1, 1), 0.15 + 0.25 * k)
	else
		for k2, v in pairs(DARKER) do
			t[k2] = v
		end
	end
	t.Error = Color3.fromRGB(255, 102, 102)
	local tc = findColor(s.TextName) or Color3.new(1, 1, 1)
	t.Text = tc
	t.Icons = tc
	t.TextDark = tc:Lerp(t.Background, 0.25)
	t.TextDarker = tc:Lerp(t.Background, 0.4)
	return t
end

GGUI.Theme = buildTheme(GGUI.State)

local function T(role)
	return GGUI.Theme[role] or GGUI.Theme.Text
end

-- ===== UTILIDADES =====
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(o, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o)
end

local function tween(o, props, dur, style, dir)
	local tw = TweenService:Create(
		o,
		TweenInfo.new(dur or TIME.Normal, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

-- Dispara callbacks sem travar a interface
local function fire(cb, ...)
	if type(cb) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(cb, table.unpack(args, 1, args.n))
		if not ok then
			warn("[GGUI] erro em callback: " .. tostring(err))
		end
	end)
end

-- Registra uma propriedade para trocar de cor quando o tema mudar
local function reg(obj, prop, role)
	obj[prop] = T(role)
	table.insert(GGUI.Paints, { obj = obj, prop = prop, role = role })
	return obj
end

-- Registra uma função que reaplica cores quando o tema mudar
local function regFn(fn)
	table.insert(GGUI.Paints, { fn = fn })
	pcall(fn)
end

local function label(parent, props, role)
	local p = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
	}
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	local l = new("TextLabel", p, parent)
	reg(l, "TextColor3", role or "Text")
	return l
end

local function hoverable(hit, frame)
	hit.MouseEnter:Connect(function()
		tween(frame, { BackgroundColor3 = T("ElementHold") }, TIME.Hover)
	end)
	hit.MouseLeave:Connect(function()
		tween(frame, { BackgroundColor3 = T("Element") }, TIME.Hover)
	end)
end

-- Arrasto suave da janela (com Lerp, como a Gold)
local function draggable(handle, target, win)
	local dragging, startMouse, startGoal, goal = false, nil, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startMouse = i.Position
			startGoal = target.Position
			goal = target.Position
		end
	end)
	table.insert(win.Connections, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			goal = UDim2.new(startGoal.X.Scale, startGoal.X.Offset + d.X, startGoal.Y.Scale, startGoal.Y.Offset + d.Y)
		end
	end))
	table.insert(win.Connections, UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				win:_save()
			end
			dragging = false
		end
	end))
	table.insert(win.Connections, RunService.RenderStepped:Connect(function()
		if goal and target.Parent then
			target.Position = target.Position:Lerp(goal, 0.6)
		end
	end))
end

-- Alça de arrasto genérica (redimensionar e largura das abas)
local function dragHandle(handle, win, onStart, onDelta, onEnd)
	local dragging, startMouse = false, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startMouse = i.Position
			if onStart then
				onStart()
			end
		end
	end)
	table.insert(win.Connections, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			onDelta(i.Position - startMouse)
		end
	end))
	table.insert(win.Connections, UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if dragging and onEnd then
				onEnd()
			end
			dragging = false
		end
	end))
end

local function rowTitles(f, name, desc, rightPad)
	local pad = rightPad or 70
	local t = label(f, {
		Position = desc and UDim2.fromOffset(10, 7) or UDim2.fromOffset(10, 0),
		Size = desc and UDim2.new(1, -pad, 0, 18) or UDim2.new(1, -pad, 1, 0),
		Text = tostring(name),
	}, "Text")
	local d = nil
	if desc then
		d = label(f, {
			Position = UDim2.fromOffset(10, 26),
			Size = UDim2.new(1, -pad, 0, 16),
			Text = tostring(desc),
			TextSize = 11,
		}, "TextDark")
	end
	return t, d
end

local function readJson(path)
	if not path or not (isfile and readfile) then
		return nil
	end
	local ok, exists = pcall(isfile, path)
	if not (ok and exists) then
		return nil
	end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if ok2 and type(data) == "table" then
		return data
	end
	return nil
end

-- ===== COMPONENTES (base comum) =====
local function newComp(tab, frame, t, d)
	return setmetatable({
		Frame = frame,
		Tab = tab,
		Window = tab.Window,
		_title = t,
		_desc = d,
		_cbs = {},
	}, Comp)
end

function Comp:SetTitle(v)
	if self._title then
		self._title.Text = tostring(v)
	end
end

function Comp:SetDescription(v)
	if self._desc then
		self._desc.Text = tostring(v)
	end
end
Comp.SetDesc = Comp.SetDescription
Comp.SetContent = Comp.SetDescription

function Comp:SetVisible(v)
	self.Frame.Visible = v and true or false
end

function Comp:Destroy()
	self.Frame:Destroy()
end

function Comp:AddCallback(fn)
	if type(fn) == "function" then
		table.insert(self._cbs, fn)
	end
end
Comp.NewCallback = Comp.AddCallback

function Comp:_emit(...)
	for _, f in ipairs(self._cbs) do
		fire(f, ...)
	end
end

-- ===== TEMA: API PÚBLICA =====
local function lastWin()
	return GGUI.Windows[#GGUI.Windows]
end

function GGUI:IsValidTheme(name)
	return name == "Darker" or findColor(name) ~= nil
end

function GGUI:GetThemes()
	local out = { "Darker" }
	for _, p in ipairs(PALETTE) do
		table.insert(out, p.name)
	end
	return out
end

function GGUI:GetTheme(name)
	return buildTheme({ Base = name, Tone = GGUI.State.Tone, TextName = GGUI.State.TextName })
end

function GGUI:GetCurrentTheme()
	return GGUI.State.Base
end

function GGUI:_refreshTheme()
	GGUI.Theme = buildTheme(GGUI.State)
	for i = #GGUI.Paints, 1, -1 do
		local p = GGUI.Paints[i]
		if p.fn then
			local ok = pcall(p.fn)
			if not ok then
				table.remove(GGUI.Paints, i)
			end
		elseif p.obj and p.obj.Parent ~= nil then
			p.obj[p.prop] = T(p.role)
		else
			table.remove(GGUI.Paints, i)
		end
	end
end

function GGUI:_applyAll()
	GGUI:_refreshTheme()
	for _, w in ipairs(GGUI.Windows) do
		w:_applyTom()
	end
end

function GGUI:SetTheme(name)
	if not GGUI:IsValidTheme(name) then
		return false
	end
	GGUI.State.Base = name
	GGUI:_applyAll()
	local w = lastWin()
	if w then
		w:_save()
	end
	return true
end

function GGUI:SetUIScale(v)
	local w = lastWin()
	if w then
		w.Scale.Scale = math.clamp(tonumber(v) or 1, LIMITS.Scale[1], LIMITS.Scale[2])
	end
end

function GGUI:GetMaxScale()
	return LIMITS.Scale[2]
end

function GGUI:GetMinScale()
	return LIMITS.Scale[1]
end

function GGUI:GetIconByName(name)
	return ICONS[name]
end

function GGUI:Notify(cfg)
	local w = lastWin()
	if w then
		return w:Notify(cfg)
	end
end
GGUI.MakeNotify = GGUI.Notify

function GGUI:NewNotifyGroup(cfg)
	local w = lastWin()
	if w then
		return w:NewNotifyGroup(cfg)
	end
end

function GGUI:Destroy()
	for _, w in ipairs(GGUI.Windows) do
		w:Destroy()
	end
	GGUI.Windows = {}
end

-- ===== CARREGAMENTO DAS CONFIGURAÇÕES =====
function GGUI:_loadSettings(win)
	local folder = win.ScriptFolder
	local lib = readJson(folder and (folder .. "/LibrarySettings.json"))
	local s = GGUI.State
	if lib then
		if type(lib.Base) == "string" and GGUI:IsValidTheme(lib.Base) then s.Base = lib.Base end
		if type(lib.Tone) == "number" then s.Tone = math.clamp(lib.Tone, 0, 100) end
		if type(lib.TextName) == "string" and findColor(lib.TextName) then s.TextName = lib.TextName end
		if type(lib.TomName) == "string" and findColor(lib.TomName) then s.TomName = lib.TomName end
		if type(lib.Opacity) == "number" then s.Opacity = math.clamp(lib.Opacity, 0, 100) end
		if type(lib.Background) == "string" then s.Background = lib.Background end
		if type(lib.TabsW) == "number" then s.TabsW = math.clamp(lib.TabsW, LIMITS.TabsW[1], LIMITS.TabsW[2]) end
		if type(lib.W) == "number" then s.W = math.clamp(lib.W, LIMITS.W[1], LIMITS.W[2]) end
		if type(lib.H) == "number" then s.H = math.clamp(lib.H, LIMITS.H[1], LIMITS.H[2]) end
		if type(lib.UiScale) == "number" then s.UiScale = math.clamp(lib.UiScale, 50, 120) end
	end
	local flags = readJson(folder and (folder .. "/ScriptFlags.json"))
	if flags then
		win.Flags = flags
	end
end

-- ===== TABS (estado visual) =====
local function paintTab(win, tab, instant)
	local on = (win.Selected == tab)
	local bgc = on and T("ElementHold") or T("Element")
	local tr = on and 0.1 or 0.4
	local isz = on and UDim2.fromOffset(4, 13) or UDim2.fromOffset(4, 4)
	local itr = on and 0 or 1
	if instant then
		tab.Button.BackgroundColor3 = bgc
		tab.Button.BackgroundTransparency = tr
		tab.Indicator.Size = isz
		tab.Indicator.BackgroundTransparency = itr
	else
		tween(tab.Button, { BackgroundColor3 = bgc, BackgroundTransparency = tr }, TIME.Tab)
		tween(tab.Indicator, { Size = isz, BackgroundTransparency = itr }, TIME.Tab)
	end
end

-- ===== LIBRARY: MakeWindow =====
function GGUI:MakeWindow(cfg)
	cfg = cfg or {}
	local win = setmetatable({}, Window)
	win.Title = tostring(cfg.Title or cfg.Name or cfg[1] or "GG")
	win.SubTitle = tostring(cfg.SubTitle or cfg[2] or "")
	win.ScriptFolder = cfg.ScriptFolder or cfg.SaveFolder or cfg[3]
	win.Repo = cfg.Repo or REPO
	win.Backgrounds = cfg.Backgrounds or DEFAULT_BACKGROUNDS
	win.Flags = {}
	win.TabList = {}
	win.Connections = {}
	win.Minimized = false
	win.Shrunk = false
	win.SquareAlways = false
	win.Keybind = nil

	GGUI:_loadSettings(win)
	GGUI:_refreshTheme()

	local parent = (gethui and gethui()) or CoreGui
	local old = parent:FindFirstChild("GGUI")
	if old then
		old:Destroy()
	end
	win.Screen = new("ScreenGui", {
		Name = "GGUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
	}, parent)

	local s = GGUI.State
	local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)

	-- janela principal
	win.Main = new("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(s.W, s.H),
		Position = UDim2.fromOffset((vp.X - s.W) / 2, (vp.Y - s.H) / 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.03,
		Active = true,
		ClipsDescendants = true,
	}, win.Screen)
	corner(win.Main, 8)
	win.Scale = new("UIScale", { Scale = GGUI.State.UiScale / 100 }, win.Main)
	win.Gradient = new("UIGradient", { Rotation = 90 }, win.Main)
	local gradient = win.Gradient
	regFn(function()
		local bg = T("Background")
		gradient.Color = ColorSequence.new(bg:Lerp(T("Primary"), 0.04), bg)
	end)

	-- fundo atrás de tudo e camada colorida
	win.BgImage = new("ImageLabel", {
		Name = "Fundo",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		Visible = false,
	}, win.Main)
	corner(win.BgImage, 8)
	win.Tom = new("Frame", {
		Name = "Tom",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.95,
		ZIndex = 0,
	}, win.BgImage)
	corner(win.Tom, 8)

	-- barra superior
	win.TopBar = new("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		Active = true,
	}, win.Main)
	win.TitleLabel = label(win.TopBar, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = win.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, "Text")
	win.SubLabel = label(win.TopBar, {
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.3, 0, 1, 0),
		Text = win.SubTitle,
		TextSize = 10,
	}, "TextDark")
	if cfg.Link then
		local tsv = game:GetService("TextService"):GetTextSize(
			win.Title, 15, Enum.Font.GothamBold, Vector2.new(1000, 36))
		local lk = reg(new("TextButton", {
			Position = UDim2.fromOffset(12 + tsv.X + 8, 7),
			Size = UDim2.fromOffset(64, 22),
			AutoButtonColor = false,
			Text = cfg.LinkLabel or "Discord",
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
		}, win.TopBar), "BackgroundColor3", "Primary")
		reg(lk, "TextColor3", "Text")
		corner(lk, 5)
		lk.Activated:Connect(function()
			if setclipboard then
				setclipboard(cfg.Link)
			end
			win:Notify({ Title = "Link copiado", Content = cfg.Link, Duration = 3 })
		end)
		end
	local closeBtn = new("ImageButton", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICONS.Close,
		AutoButtonColor = false,
	}, win.TopBar)
	reg(closeBtn, "ImageColor3", "Icons")
	local minBtn = new("ImageButton", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -36, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICONS.Minimize,
		AutoButtonColor = false,
	}, win.TopBar)
	reg(minBtn, "ImageColor3", "Icons")
	minBtn.Activated:Connect(function()
		win:Minimize()
	end)
	closeBtn.Activated:Connect(function()
		win:Destroy()
	end)
	draggable(win.TopBar, win.Main, win)

	-- abas, conteúdo, divisor e alça de redimensionar
	win.Sidebar = new("ScrollingFrame", {
		Name = "Abas",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, win.Main)
	new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, win.Sidebar)
	win.Content = new("Frame", {
		Name = "Conteudo",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, win.Main)
	win.Divider = new("Frame", {
		Name = "DivisorAbas",
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, win.Main)
	win.Grip = new("Frame", {
		Name = "Redimensionar",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, win.Main)
	local gripDot = new("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.new(1, -4, 1, -4),
		AnchorPoint = Vector2.new(1, 1),
		BorderSizePixel = 0,
	}, win.Grip)
	reg(gripDot, "BackgroundColor3", "TextDark")
	corner(gripDot, 3)
	win:_layout()

	local tabStart = nil
	dragHandle(win.Divider, win, function()
		tabStart = GGUI.State.TabsW
	end, function(d)
		GGUI.State.TabsW = math.clamp(tabStart + d.X, LIMITS.TabsW[1], LIMITS.TabsW[2])
		win:_layout()
	end, function()
		win:_save()
	end)

	local startW, startH, startScale = GGUI.State.W, GGUI.State.H, 1
	dragHandle(win.Grip, win, function()
		startW, startH = GGUI.State.W, GGUI.State.H
		startScale = win.Scale.Scale
	end, function(d)
		GGUI.State.W = math.clamp(startW + d.X / startScale, LIMITS.W[1], LIMITS.W[2])
		GGUI.State.H = math.clamp(startH + d.Y / startScale, LIMITS.H[1], LIMITS.H[2])
		if not win.Shrunk then
			win.Main.Size = UDim2.fromOffset(GGUI.State.W, GGUI.State.H)
		end
	end, function()
		win:_save()
	end)

	-- quadrado minimizado (padrão; CreateMobileMinimizer reconfigura este mesmo)
	win.Square = reg(new("ImageButton", {
		Name = "Minimizado",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.fromScale(0.15, 0.3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
		ZIndex = 30,
	}, win.Screen), "BackgroundColor3", "Element")
	corner(win.Square, 8)
	win.Square.Activated:Connect(function()
		win:Minimize()
	end)
	draggable(win.Square, win.Square, win)

	-- atalho de teclado (definido por NewMinimizer)
	table.insert(win.Connections, UIS.InputBegan:Connect(function(input, gp)
		if not gp and win.Keybind and input.KeyCode == win.Keybind then
			win:Minimize()
		end
	end))

	table.insert(GGUI.Windows, win)
	win:_setupPersonalizar()
	return win
end

-- ===== WINDOW: LAYOUT E JANELA =====
function Window:_layout()
	local tw = GGUI.State.TabsW
	self.Sidebar.Position = UDim2.fromOffset(8, TOPBAR_H + 8)
	self.Sidebar.Size = UDim2.new(0, tw - 16, 1, -(TOPBAR_H + 16))
	self.Content.Position = UDim2.fromOffset(tw + 4, TOPBAR_H + 8)
	self.Content.Size = UDim2.new(1, -(tw + 12), 1, -(TOPBAR_H + 16))
	self.Divider.Position = UDim2.fromOffset(tw - 2, TOPBAR_H + 8)
	self.Divider.Size = UDim2.new(0, 4, 1, -(TOPBAR_H + 16))
	self.Grip.Position = UDim2.new(1, -2, 1, -2)
end

function Window:_syncSquare()
	if self.Square then
		self.Square.Visible = (self.Minimized or self.SquareAlways) and true or false
	end
end

-- Esconde a janela e mostra o quadrado (também usado pelo atalho)
function Window:Minimize()
	self.Minimized = not self.Minimized
	self.Main.Visible = not self.Minimized
	self.Shrunk = false
	self.Main.Size = UDim2.fromOffset(GGUI.State.W, GGUI.State.H)
	self:_syncSquare()
end

-- Versão da Gold: encolhe a janela até a barra superior
function Window:MinimizeButton()
	if self.Shrunk then
		self.Shrunk = false
		tween(self.Main, { Size = UDim2.fromOffset(GGUI.State.W, GGUI.State.H) }, TIME.Minimize)
	else
		self.Shrunk = true
		tween(self.Main, { Size = UDim2.fromOffset(GGUI.State.W, TOPBAR_H) }, TIME.Minimize)
	end
end

function Window:GetElements()
	return {
		MainFrame = self.Main,
		ScreenGui = self.Screen,
		TopBar = self.TopBar,
		Sidebar = self.Sidebar,
		Content = self.Content,
		Square = self.Square,
	}
end

function Window:GetTitle()
	return self.Title
end

function Window:SetTitle(t)
	self.Title = tostring(t)
	self.TitleLabel.Text = self.Title
end

function Window:GetSubTitle()
	return self.SubTitle
end

function Window:SetSubTitle(t)
	self.SubTitle = tostring(t)
	self.SubLabel.Text = self.SubTitle
end

function Window:StartWindow()
	return self
end

function Window:SetUIScale(v)
	self.Scale.Scale = math.clamp(tonumber(v) or 1, LIMITS.Scale[1], LIMITS.Scale[2])
end

function Window:Destroy()
	for _, c in ipairs(self.Connections) do
		c:Disconnect()
	end
	self.Connections = {}
	if self.Screen then
		self.Screen:Destroy()
	end
	self.Screen = nil
	for i, w in ipairs(GGUI.Windows) do
		if w == self then
			table.remove(GGUI.Windows, i)
			break
		end
	end
end

-- ===== MINIMIZADOR =====
function Window:NewMinimizer(cfg)
	local key = cfg
	if type(cfg) == "table" then
		key = cfg.KeyCode or cfg[1]
	end
	self.Keybind = key
	return setmetatable({ Window = self }, Minimizer)
end

function Minimizer:SetKeyCode(k)
	self.Window.Keybind = k
end
Minimizer.SetKey = Minimizer.SetKeyCode

function Minimizer:CreateMobileMinimizer(props)
	props = props or {}
	local win = self.Window
	local sq = win.Square
	local cr = props.Corner
	local rad = (type(cr) == "number" and cr) or (typeof(cr) == "UDim" and cr.Offset) or 8

	for k, v in pairs(props) do
		if k ~= "Corner" and k ~= "Stroke" and k ~= "Always" then
			pcall(function()
				sq[k] = v
			end)
		end
	end

	local c = sq:FindFirstChildOfClass("UICorner")
	if c then
		c.CornerRadius = UDim.new(0, rad)
	else
		corner(sq, rad)
	end

	if props.Stroke then
		local st = sq:FindFirstChildOfClass("UIStroke") or new("UIStroke", {}, sq)
		st.Color = props.Stroke.Color or T("Stroke")
		st.Thickness = props.Stroke.Thickness or 1
	end

	win.SquareAlways = props.Always == true
	win:_syncSquare()
	return sq
end

-- ===== FLAGS E ARQUIVOS =====
function Window:SetFlag(name, value)
	self.Flags[name] = value
	self:_save()
end

function Window:GetFlag(name)
	return self.Flags[name]
end

function Window:DeleteFlags()
	self.Flags = {}
	local p = self:_path("ScriptFlags.json")
	if p and delfile and isfile and isfile(p) then
		pcall(delfile, p)
	end
end

function Window:_path(file)
	if not self.ScriptFolder then
		return nil
	end
	return self.ScriptFolder .. "/" .. file
end

function Window:ReadFile(file)
	local p = self:_path(file) or file
	if isfile and readfile and isfile(p) then
		return readfile(p)
	end
	return nil
end

function Window:WriteFile(file, content)
	if not writefile then
		return false
	end
	if self.ScriptFolder and makefolder and isfolder and not isfolder(self.ScriptFolder) then
		pcall(makefolder, self.ScriptFolder)
	end
	local p = self:_path(file) or file
	return (pcall(writefile, p, content))
end

-- Salva com atraso de 0.5 s para agrupar alterações (igual à Gold)
function Window:_save()
	if self._queued then
		return
	end
	self._queued = true
	task.delay(0.5, function()
		self._queued = false
		self:_writeSettings()
	end)
end

function Window:_writeSettings()
	if not self.ScriptFolder then
		return
	end
	local s = GGUI.State
	local lib = {
		Base = s.Base,
		Tone = s.Tone,
		TextName = s.TextName,
		TomName = s.TomName,
		Opacity = s.Opacity,
		Background = s.Background,
		TabsW = s.TabsW,
		W = s.W,
		H = s.H,
		UiScale = s.UiScale,
	}
	pcall(function()
		self:WriteFile("LibrarySettings.json", HttpService:JSONEncode(lib))
	end)
	pcall(function()
		self:WriteFile("ScriptFlags.json", HttpService:JSONEncode(self.Flags))
	end)
end

-- ===== NOTIFICAÇÕES =====
function Window:SetNotifyDefaultIcon(icon)
	self.NotifyIcon = icon
end
Window.SetDefaultNotifyIcon = Window.SetNotifyDefaultIcon

function Window:Notify(cfg)
	cfg = cfg or {}
	local title = cfg.Title or cfg.Name or cfg[1] or "Aviso"
	local content = cfg.Content or cfg.Text or cfg[2] or ""
	local icon = cfg.Icon or cfg.Image or cfg[3] or self.NotifyIcon
	local dur = tonumber(cfg.Duration or cfg.Countdown or cfg.Time or cfg[4]) or 5

	if not self.NotifyHolder then
		self.NotifyHolder = new("Frame", {
			Name = "Notificacoes",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -12),
			Size = UDim2.fromOffset(280, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 20,
		}, self.Screen)
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		}, self.NotifyHolder)
	end

	self._notifyN = (self._notifyN or 0) + 1
	local wrap = new("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = self._notifyN,
	}, self.NotifyHolder)

	local card = reg(new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromScale(1.2, 0),
		BackgroundTransparency = 0.05,
	}, wrap), "BackgroundColor3", "Background")
	corner(card, 8)

	local textX = 12
	if icon then
		new("ImageLabel", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
			Image = tostring(icon),
		}, card)
		textX = 42
	end

	label(card, {
		Position = UDim2.fromOffset(textX, 8),
		Size = UDim2.new(1, -textX - 12, 0, 18),
		Text = tostring(title),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, "Text")
	label(card, {
		Position = UDim2.fromOffset(textX, 27),
		Size = UDim2.new(1, -textX - 12, 0, 28),
		Text = tostring(content),
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.None,
	}, "TextDark")

	-- barra de contagem regressiva
	local cd = reg(new("Frame", {
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		BorderSizePixel = 0,
	}, card), "BackgroundColor3", "Primary")
	corner(cd, 2)

	-- clique para fechar
	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, card)

	tween(card, { Position = UDim2.fromScale(0, 0) }, TIME.NotifyIn)
	tween(cd, { Size = UDim2.new(0, 0, 0, 3) }, dur, Enum.EasingStyle.Linear)

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		local tw = tween(card, { Position = UDim2.fromScale(1.2, 0) }, TIME.NotifyOut)
		tw.Completed:Connect(function()
			wrap:Destroy()
		end)
	end
	hit.Activated:Connect(close)
	task.delay(dur, close)
	return { Close = close }
end

function Window:NewNotifyGroup(cfg)
	cfg = cfg or {}
	local defaults = {
		Title = cfg.Title or cfg.Name or cfg[1],
		Content = cfg.Content or cfg[2],
		Icon = cfg.Icon or cfg[3],
		Duration = cfg.Duration or cfg[4],
	}
	local win = self
	local group = {}
	function group:Notify(c2)
		c2 = c2 or {}
		return win:Notify({
			Title = c2.Title or c2.Name or c2[1] or defaults.Title,
			Content = c2.Content or c2.Text or c2[2] or defaults.Content,
			Icon = c2.Icon or c2[3] or defaults.Icon,
			Duration = c2.Duration or c2[4] or defaults.Duration,
		})
	end
	return group
end
Window.NewNotificationGroup = Window.NewNotifyGroup

-- ===== DIALOG =====
function Window:Dialog(cfg)
	cfg = cfg or {}
	if self.DialogOverlay then
		self.DialogOverlay:Destroy()
	end

	local overlay = new("TextButton", {
		Name = "Dialog",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Active = true,
	}, self.Main)
	tween(overlay, { BackgroundTransparency = 0.45 }, TIME.Dialog)
	self.DialogOverlay = overlay

	local box = reg(new("Frame", {
		Size = UDim2.new(0.8, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 51,
	}, overlay), "BackgroundColor3", "Background")
	corner(box, 8)
	local sc = new("UIScale", { Scale = 1.2 }, box)
	tween(sc, { Scale = 1 }, TIME.Dialog)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, box)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, box)

	local function close()
		if self.DialogOverlay == overlay then
			self.DialogOverlay = nil
		end
		overlay:Destroy()
	end

	label(box, {
		Size = UDim2.new(1, 0, 0, 20),
		Text = tostring(cfg.Title or cfg.Name or "Aviso"),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		ZIndex = 52,
		LayoutOrder = 1,
	}, "Text")
	label(box, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(cfg.Content or cfg.Description or ""),
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 52,
		LayoutOrder = 2,
	}, "TextDark")

	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		ZIndex = 52,
		LayoutOrder = 3,
	}, box)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)

	for i, opt in ipairs(cfg.Options or {}) do
		local ocb = opt.Callback or opt[2]
		local b = reg(new("TextButton", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = tostring(opt.Title or opt.Name or opt[1] or "OK"),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			AutoButtonColor = false,
			ZIndex = 52,
			LayoutOrder = i,
		}, row), "BackgroundColor3", "Primary")
		reg(b, "TextColor3", "Text")
		corner(b, 6)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}, b)
		b.Activated:Connect(function()
			close()
			fire(ocb)
		end)
	end
end

-- ===== ABAS =====
function Window:GetTabByTitle(name)
	for _, t in ipairs(self.TabList) do
		if t.Name == name then
			return t
		end
	end
	return nil
end
Window.GetTabByName = Window.GetTabByTitle

function Window:SelectTab(tab, instant)
	if type(tab) == "number" then
		tab = self.TabList[tab]
	elseif type(tab) == "string" then
		tab = self:GetTabByTitle(tab)
	end
	if not tab then
		return
	end
	for _, t in ipairs(self.TabList) do
		t.Page.Visible = (t == tab)
	end
	self.Selected = tab
	for _, t in ipairs(self.TabList) do
		paintTab(self, t, instant)
	end
end

-- isLast = true para a aba Personalizar, que fica sempre por último
function Window:_newTab(name, isLast)
	local tab = setmetatable({ Window = self, Name = name, Order = 0, IsLast = isLast }, Tab)

	local btn = new("Frame", {
		Name = "Aba_" .. tostring(name),
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = isLast and 100000 or (#self.TabList + 1),
	}, self.Sidebar)
	corner(btn, 6)

	local ind = new("Frame", {
		Name = "Indicador",
		Size = UDim2.fromOffset(4, 4),
		Position = UDim2.new(0, 4, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}, btn)
	reg(ind, "BackgroundColor3", "Primary")
	corner(ind, 2)

	label(btn, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -22, 1, 0),
		Text = tostring(name),
		TextSize = 13,
	}, "Text")

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, btn)

	local page = new("ScrollingFrame", {
		Name = "Pagina_" .. tostring(name),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, self.Content)
	reg(page, "ScrollBarImageColor3", "Primary")
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 6),
	}, page)

	tab.Button = btn
	tab.Indicator = ind
	tab.Page = page
	table.insert(self.TabList, tab)

	regFn(function()
		paintTab(self, tab, true)
	end)

	hit.Activated:Connect(function()
		self:SelectTab(tab)
	end)
	hit.MouseEnter:Connect(function()
		if self.Selected ~= tab then
			tween(btn, { BackgroundColor3 = T("ElementHold") }, TIME.Hover)
		end
	end)
	hit.MouseLeave:Connect(function()
		if self.Selected ~= tab then
			tween(btn, { BackgroundColor3 = T("Element") }, TIME.Hover)
		end
	end)

	if not isLast and not self.Selected then
		self:SelectTab(tab, true)
	end
	return tab
end

function Window:MakeTab(cfg)
	if type(cfg) ~= "table" then
		cfg = { cfg }
	end
	local name = cfg.Title or cfg.Name or cfg[1] or "Tab"
	return self:_newTab(tostring(name), false)
end

-- ===== FUNDO E CAMADA =====
function Window:ApplyBackground(name)
	if name == "Nenhum" then
		self.BgImage.Visible = false
		self.Main.BackgroundTransparency = 0.03
		self.Square.Image = ""
		return true
	end
	local info = nil
	for _, b in ipairs(self.Backgrounds) do
		if b.nome == name then
			info = b
			break
		end
	end
	if not info then
		return false
	end
	local ok, asset = pcall(function()
		if not isfile(info.arquivo) then
			writefile(info.arquivo, game:HttpGet(self.Repo .. info.arquivo))
		end
		return getcustomasset(info.arquivo)
	end)
	if not ok then
		warn("[GGUI] fundo '" .. tostring(name) .. "' falhou: " .. tostring(asset))
		return false
	end
	self.BgImage.Image = asset
	self.BgImage.Visible = true
	self.Main.BackgroundTransparency = 1
	self.Square.Image = asset
	return true
end

function Window:SetTomOpacity(v)
	v = math.clamp(tonumber(v) or 5, 0, 100)
	GGUI.State.Opacity = v
	self.Tom.BackgroundTransparency = 1 - v / 100
end

function Window:_applyTom()
	self.Tom.BackgroundColor3 = findColor(GGUI.State.TomName) or Color3.new(0, 0, 0)
	self:SetTomOpacity(GGUI.State.Opacity)
end

-- ===== ABA PERSONALIZAR (sempre a última) =====
function Window:_setupPersonalizar()
	local tab = self:_newTab("Personalizar", true)
	self.PersTab = tab
	local s = GGUI.State
	local win = self

	local names = {}
	for _, b in ipairs(self.Backgrounds) do
		table.insert(names, b.nome)
	end
	table.insert(names, "Nenhum")
	if not table.find(names, s.Background) then
		s.Background = names[1]
	end

	tab:AddSection("Janela")
	tab:AddSlider({
		Name = "Tamanho da janela (%)",
		Min = 50,
		Max = 120,
		Increment = 5,
		Default = s.UiScale,
		Callback = function(v)
			s.UiScale = v
			win.Scale.Scale = v / 100
			win:_save()
		end,
	})

	tab:AddSection("Fundo")
	tab:AddDropdown({
		Name = "Escolher fundo",
		Options = names,
		Default = s.Background,
		Flag = "Fundo/Selecionado",
		Callback = function(v)
			s.Background = v
			win:ApplyBackground(v)
			win:_save()
		end,
	})

	tab:AddSection("Camada sobre o fundo")
	tab:_palette("Cor da camada", s.TomName, function(n)
		s.TomName = n
		win:_applyTom()
		win:_save()
	end)
	tab:AddSlider({
		Name = "Opacidade da camada",
		Min = 0,
		Max = 100,
		Increment = 1,
		Default = s.Opacity,
		Callback = function(v)
			win:SetTomOpacity(v)
			win:_save()
		end,
	})

	tab:AddSection("Tema")
	tab:_palette("Cor do tema", s.Base, function(n)
		s.Base = n
		GGUI:_applyAll()
		win:_save()
	end)
	tab:AddSlider({
		Name = "Tom do tema",
		Min = 0,
		Max = 100,
		Increment = 1,
		Default = s.Tone,
		Callback = function(v)
			s.Tone = v
			GGUI:_applyAll()
			win:_save()
		end,
	})

	tab:AddSection("Texto")
	tab:_palette("Cor do texto", s.TextName, function(n)
		s.TextName = n
		GGUI:_applyAll()
		win:_save()
	end)

	tab:AddSection("Restaurar")
	tab:AddButton({
		Name = "Restaurar padrão",
		Callback = function()
			s.Base = "Darker"
			s.Tone = 20
			s.TextName = "Branco"
			s.TomName = "Preto"
			s.Opacity = 5
			GGUI:_applyAll()
			win:SetTomOpacity(5)
			win:_save()
		end,
	})

	self:_applyTom()
end

-- ===== TAB: COMPONENTES =====
function Tab:Select()
	self.Window:SelectTab(self)
end

function Tab:Unselect()
	-- a aba selecionada muda ao escolher outra aba
end

function Tab:_row(h)
	self.Order = self.Order + 1
	local f = reg(new("Frame", {
		Size = UDim2.new(1, 0, 0, h or 42),
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	f.BackgroundTransparency = 0.25
	corner(f, 6)
	return f
end

function Tab:AddSection(cfg)
	local text = cfg
	if type(cfg) == "table" then
		text = cfg[1] or cfg.Name or cfg.Title or ""
	end
	self.Order = self.Order + 1
	local l = label(self.Page, {
		Size = UDim2.new(1, 0, 0, 24),
		Text = tostring(text or ""),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		LayoutOrder = self.Order,
	}, "Text")
	return newComp(self, l, l, nil)
end

function Tab:AddIcon(cfg)
	if type(cfg) ~= "table" then
		cfg = { cfg }
	end
	local name = cfg.Name or cfg[1] or "home"
	local size = cfg.Size or 22
	local f = self:_row(38)
	local img = GGUI:IconImage(f, name, size)
	if img then
		img.Position = UDim2.fromOffset(12, (38 - size) / 2)
	end
	label(f, {
		Position = UDim2.fromOffset(12 + size + 10, 0),
		Size = UDim2.new(1, -(12 + size + 20), 1, 0),
		Text = tostring(name),
	}, "Text")
	return newComp(self, f, nil, nil)
end

function Tab:AddParagraph(title, desc)
	if type(title) == "table" then
		desc = title[2] or title.Desc or title.Description
		title = title[1] or title.Name or title.Title
	end
	self.Order = self.Order + 1
	local f = reg(new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	f.BackgroundTransparency = 0.25
	corner(f, 6)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, f)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, f)
	local t = label(f, {
		Size = UDim2.new(1, 0, 0, 18),
		Text = tostring(title or ""),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
	}, "Text")
	local d = label(f, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(desc or ""),
		TextSize = 12,
		TextWrapped = true,
		RichText = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.None,
	}, "TextDark")
	return newComp(self, f, t, d)
end

function Tab:AddLabel(cfg)
	if type(cfg) ~= "table" then
		cfg = { cfg }
	end
	local text = cfg.Text or cfg[2] or cfg[1] or ""
	local f = self:_row(32)
	local l = label(f, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = tostring(text),
		TextSize = 12,
		TextWrapped = true,
	}, "TextDark")
	return newComp(self, f, l, nil)
end

function Tab:AddToggle(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Toggle"
	local default = cfg.Default
	if default == nil then
		default = cfg[2]
	end
	local cb = cfg.Callback or cfg[3]
	local flag = cfg.Flag or cfg[4]
	local desc = cfg.Description or cfg.Desc
	local win = self.Window

	local value = (default == true)
	if flag and win.Flags[flag] ~= nil then
		-- toggles são guardados como 0 (ligado) e 1 (desligado), igual à Gold
		local fv = win.Flags[flag]
		value = (fv == 0) or (fv == true)
	end

	local f = self:_row(desc and 49 or 42)
	local t, d = rowTitles(f, name, desc, 70)

	local sw = new("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BorderSizePixel = 0,
	}, f)
	corner(sw, 10)
	local knob = reg(new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		BorderSizePixel = 0,
	}, sw), "BackgroundColor3", "TextDark")
	corner(knob, 7)

	local obj = newComp(self, f, t, d)
	obj._cbs = cb and { cb } or {}

	local function paintSw(anim)
		local kp = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local sc = value and T("Primary") or T("Stroke")
		if anim then
			tween(knob, { Position = kp }, TIME.Fast)
			tween(sw, { BackgroundColor3 = sc }, TIME.Fast)
		else
			knob.Position = kp
			sw.BackgroundColor3 = sc
		end
	end
	regFn(function()
		paintSw(false)
	end)

	local function set(v, emit, anim)
		value = v and true or false
		paintSw(anim)
		if flag then
			win.Flags[flag] = value and 0 or 1
			if emit then
				win:_save()
			end
		end
		if emit then
			obj:_emit(value)
		end
	end

	if flag then
		win.Flags[flag] = value and 0 or 1
	end

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, f)
	hoverable(hit, f)
	hit.Activated:Connect(function()
		set(not value, true, true)
	end)

	function obj:Set(v)
		set(v, true, true)
	end
	function obj:Get()
		return value
	end

	-- Gold chama o callback na criação com o valor inicial
	if cb then
		fire(cb, value)
	end
	return obj
end

function Tab:AddButton(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Botao"
	local cb = cfg.Callback or cfg[2]
	local cooldown = tonumber(cfg.Cooldown or cfg.Debounce) or 0
	local f = self:_row(38)
	local b = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = tostring(name),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
	}, f)
	reg(b, "TextColor3", "Text")
	hoverable(b, f)

	local obj = newComp(self, f, nil, nil)
	obj._cbs = cb and { cb } or {}
	obj._title = nil
	function obj:SetTitle(v)
		b.Text = tostring(v)
	end
	local last = 0
	b.Activated:Connect(function()
		local now = os.clock()
		if now - last < cooldown then
			return
		end
		last = now
		obj:_emit()
	end)
	return obj
end

function Tab:AddTextBox(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Input"
	local default = cfg.Default
	if default == nil then
		default = cfg[2] or ""
	end
	local cb = cfg.Callback or cfg[3]
	local flag = cfg.Flag or cfg[4]
	local placeholder = cfg.Placeholder or cfg.PlaceholderText or "..."
	local clear = (cfg.ClearOnFocus or cfg.ClearTextOnFocus) == true
	local win = self.Window

	local value = tostring(default)
	if flag and type(win.Flags[flag]) == "string" then
		value = win.Flags[flag]
	end

	local f = self:_row(42)
	local t = rowTitles(f, name, nil, 170)
	local box = reg(new("TextBox", {
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.new(0, 150, 0, 26),
		Text = value,
		PlaceholderText = tostring(placeholder),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		ClearTextOnFocus = clear,
	}, f), "BackgroundColor3", "Stroke")
	reg(box, "TextColor3", "Text")
	corner(box, 4)

	local obj = newComp(self, f, t, nil)
	obj._cbs = cb and { cb } or {}
	if flag then
		win.Flags[flag] = value
	end

	box.FocusLost:Connect(function()
		value = box.Text
		if flag then
			win.Flags[flag] = value
			win:_save()
		end
		obj:_emit(value)
	end)

	function obj:Set(v)
		box.Text = tostring(v)
		value = box.Text
		if flag then
			win.Flags[flag] = value
			win:_save()
		end
	end
	function obj:Get()
		return box.Text
	end
	return obj
end

function Tab:AddSlider(cfg)
	cfg = cfg or {}
	-- posições: 1 nome, 2 min, 3 max, 4 incremento, 5 padrão, 6 callback, 7 flag
	local name = cfg.Name or cfg.Title or cfg[1] or "Slider"
	local min = tonumber(cfg.Min or cfg[2]) or 0
	local max = tonumber(cfg.Max or cfg[3]) or 100
	local inc = tonumber(cfg.Increment or cfg.Inc or cfg[4]) or 1
	local default = cfg.Default
	if default == nil then
		default = cfg[5]
	end
	local cb = cfg.Callback or cfg[6]
	local flag = cfg.Flag or cfg[7]
	local win = self.Window
	if inc <= 0 then
		inc = 1
	end

	local value = tonumber(default) or min
	if flag and type(win.Flags[flag]) == "number" then
		value = win.Flags[flag]
	end

	local f = self:_row(51)
	local t = label(f, {
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -100, 0, 18),
		Text = tostring(name),
	}, "Text")
	local vl = label(f, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(80, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
	}, "TextDark")
	local vs = new("UIScale", {}, vl)

	local bar = reg(new("Frame", {
		Position = UDim2.new(0, 10, 1, -16),
		Size = UDim2.new(1, -20, 0, 6),
		BorderSizePixel = 0,
	}, f), "BackgroundColor3", "Stroke")
	corner(bar, 3)
	local fill = reg(new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
	}, bar), "BackgroundColor3", "Primary")
	corner(fill, 3)
	local hit = new("TextButton", {
		Position = UDim2.new(0, 0, 1, -24),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, f)

	local obj = newComp(self, f, t, nil)
	obj._cbs = cb and { cb } or {}

	-- efeito da Gold no número ao mudar
	local function bump()
		vs.Scale = 0.3
		tween(vs, { Scale = 1.2 }, 0.1)
		task.delay(0.1, function()
			if vs.Parent then
				tween(vs, { Scale = 1 }, 0.2)
			end
		end)
		vl.Rotation = math.random(-75, 75) / 10
		tween(vl, { Rotation = 0 }, 0.15)
	end

	local function set(v, emit, anim)
		v = math.clamp(min + math.floor((v - min) / inc + 0.5) * inc, min, max)
		local changed = (v ~= value)
		value = v
		local ratio = (max - min) > 0 and (v - min) / (max - min) or 0
		if anim then
			tween(fill, { Size = UDim2.fromScale(ratio, 1) }, TIME.Slider)
		else
			fill.Size = UDim2.fromScale(ratio, 1)
		end
		vl.Text = tostring(math.floor(v * 1000 + 0.5) / 1000)
		if anim and changed then
			bump()
		end
		if flag then
			win.Flags[flag] = v
			if emit then
				win:_save()
			end
		end
		if emit and changed then
			obj:_emit(v)
		end
	end
	set(value, false, false)

	local dragging = false
	local function fromX(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		set(min + rel * (max - min), true, true)
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(i.Position.X)
		end
	end)
	table.insert(win.Connections, UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			fromX(i.Position.X)
		end
	end))
	table.insert(win.Connections, UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	function obj:Set(v)
		set(v, true, true)
	end
	function obj:Get()
		return value
	end

	if cb then
		fire(cb, value)
	end
	return obj
end

function Tab:AddDropdown(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Dropdown"
	local options = cfg.Options or cfg[2] or {}
	local default = cfg.Default
	if default == nil then
		default = cfg[3]
	end
	local cb = cfg.Callback or cfg[4]
	local flag = cfg.Flag or cfg[5]
	local multi = (cfg.MultiSelect == true) or (cfg.Multi == true)
	local win = self.Window

	self.Order = self.Order + 1
	local box = reg(new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Dropdown")
	box.BackgroundTransparency = 0.25
	corner(box, 6)

	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, box)
	local t = label(head, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = tostring(name),
	}, "Text")
	local val = label(head, {
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, -34, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
		Text = "...",
	}, "TextDark")
	local arrow = reg(new("ImageLabel", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICONS.Open,
	}, head), "ImageColor3", "Icons")

	local buttons, order, selected = {}, {}, {}
	local open = false
	local dd = setmetatable({ Frame = box, Tab = self, Window = win, _title = t, _cbs = cb and { cb } or {} }, Comp)
	dd.Options = {}
	dd.Value = nil
	dd._enabled = true

	-- lista flutuante no ScreenGui, por cima da janela
	local body = reg(new("ScrollingFrame", {
		Name = "Lista",
		Size = UDim2.fromOffset(200, 120),
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 60,
	}, win.Screen), "BackgroundColor3", "Dropdown")
	body.BackgroundTransparency = 0.05
	corner(body, 6)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, body)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, body)
	local bscale = new("UIScale", { Scale = win.Scale.Scale }, body)

	local search = reg(new("TextBox", {
		Size = UDim2.new(1, 0, 0, 26),
		Text = "",
		PlaceholderText = "Pesquisar...",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		ClearTextOnFocus = false,
		LayoutOrder = 0,
		ZIndex = 61,
	}, body), "BackgroundColor3", "Stroke")
	reg(search, "TextColor3", "Text")
	corner(search, 4)

	local function current()
		if multi then
			local map = {}
			for _, o in ipairs(order) do
				map[o] = selected[o] and true or false
			end
			return map
		end
		return dd.Value
	end

	local function refresh()
		if multi then
			local names = {}
			for _, o in ipairs(order) do
				if selected[o] then
					table.insert(names, o)
				end
			end
			val.Text = (#names > 0) and table.concat(names, ", ") or "..."
		else
			val.Text = dd.Value and tostring(dd.Value) or "..."
		end
		for _, o in ipairs(order) do
			local b = buttons[o]
			if b then
				b.BackgroundColor3 = selected[o] and T("Primary") or T("Stroke")
			end
		end
	end
	regFn(refresh)

	local function commit(emit)
		refresh()
		if flag then
			win.Flags[flag] = current()
			if emit then
				win:_save()
			end
		end
		if emit then
			dd:_emit(current())
		end
	end

	local function place()
		local sc = win.Scale.Scale
		bscale.Scale = sc
		local h = math.min(#order * 33 + 40, 230)
		body.Position = UDim2.fromOffset(head.AbsolutePosition.X, head.AbsolutePosition.Y + head.AbsoluteSize.Y + 4)
		body.Size = UDim2.fromOffset(head.AbsoluteSize.X / sc, h / sc)
	end

	local function setOpen(v)
		open = v and true or false
		if open then
			place()
		end
		body.Visible = open
		tween(arrow, { Rotation = open and 180 or 0 }, TIME.Drop)
	end

	-- fecha ao clicar fora da lista e do campo
	table.insert(win.Connections, UIS.InputBegan:Connect(function(i)
		if not open then
			return
		end
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local p = i.Position
		local function inside(g)
			local a, s = g.AbsolutePosition, g.AbsoluteSize
			return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y
		end
		if not inside(body) and not inside(head) then
			setOpen(false)
		end
	end))

	local function addOne(opt)
		opt = tostring(opt)
		if buttons[opt] then
			return
		end
		local b = reg(new("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			AutoButtonColor = false,
			Text = opt,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			LayoutOrder = #order + 1,
			ZIndex = 61,
		}, body), "BackgroundColor3", "Stroke")
		reg(b, "TextColor3", "Text")
		corner(b, 4)
		buttons[opt] = b
		table.insert(order, opt)
		b.Activated:Connect(function()
			if not dd._enabled then
				return
			end
			if multi then
				selected[opt] = (not selected[opt]) or nil
			else
				dd.Value = opt
				selected = { [opt] = true }
				setOpen(false)
			end
			commit(true)
		end)
	end

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local q = search.Text:lower()
		for _, o in ipairs(order) do
			local b = buttons[o]
			if b then
				b.Visible = (q == "") or (o:lower():find(q, 1, true) ~= nil)
			end
		end
	end)

	head.Activated:Connect(function()
		if not dd._enabled then
			return
		end
		setOpen(not open)
	end)

	function dd:Add(...)
		for _, o in ipairs({ ... }) do
			if type(o) == "table" then
				for _, x in ipairs(o) do
					addOne(x)
				end
			else
				addOne(o)
			end
		end
		self.Options = order
	end

	function dd:Remove(...)
		for _, o in ipairs({ ... }) do
			o = tostring(o)
			local b = buttons[o]
			if b then
				b:Destroy()
				buttons[o] = nil
				selected[o] = nil
				for i, v in ipairs(order) do
					if v == o then
						table.remove(order, i)
						break
					end
				end
				if dd.Value == o then
					dd.Value = nil
				end
			end
		end
		self.Options = order
		commit(false)
	end

	function dd:Clear()
		for _, b in pairs(buttons) do
			b:Destroy()
		end
		buttons, order, selected = {}, {}, {}
		self.Options = order
		self.Value = nil
		commit(false)
	end

	function dd:NewOptions(...)
		self:Clear()
		self:Add(...)
		commit(false)
	end
	dd.Set = dd.NewOptions

	function dd:GetOptionsCount()
		return #order
	end

	function dd:Select(opt, emit)
		opt = tostring(opt)
		if not buttons[opt] then
			return false
		end
		if multi then
			selected[opt] = true
		else
			dd.Value = opt
			selected = { [opt] = true }
		end
		commit(emit and true or false)
		return true
	end

	function dd:Get()
		return current()
	end

	function dd:SetEnabled(v)
		self._enabled = v and true or false
		local tr = self._enabled and 0 or 0.5
		t.TextTransparency = tr
		val.TextTransparency = tr
		arrow.ImageTransparency = tr
	end

	dd:Add(options)

	-- restaura valor salvo ou padrão
	local initial = flag and win.Flags[flag]
	if initial == nil then
		initial = default
	end
	if multi then
		selected = {}
		if type(initial) == "table" then
			for k, v in pairs(initial) do
				if type(k) == "number" then
					if buttons[tostring(v)] then
						selected[tostring(v)] = true
					end
				elseif v == true and buttons[tostring(k)] then
					selected[tostring(k)] = true
				end
			end
		end
	else
		if type(initial) == "table" then
			initial = initial[1]
		end
		if initial ~= nil and buttons[tostring(initial)] then
			dd.Value = tostring(initial)
			selected = { [dd.Value] = true }
		end
	end
	commit(false)

	if cb then
		task.defer(function()
			dd:_emit(current())
		end)
	end
	return dd
end

function Tab:AddKeybind(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Tecla"
	local default = cfg.Default or cfg[2]
	local cb = cfg.Callback or cfg[3]
	local flag = cfg.Flag or cfg[4]
	local win = self.Window

	local key = default
	if flag and type(win.Flags[flag]) == "string" then
		if win.Flags[flag] == "" then
			key = nil
		else
			local ok, kc = pcall(function()
				return Enum.KeyCode[win.Flags[flag]]
			end)
			if ok and kc then
				key = kc
			end
		end
	end

	local f = self:_row(44)
	local t = rowTitles(f, name, nil, 140)
	local btn = reg(new("TextButton", {
		Size = UDim2.fromOffset(120, 26),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		Text = "",
	}, f), "BackgroundColor3", "Stroke")
	reg(btn, "TextColor3", "Text")
	corner(btn, 4)

	local obj = newComp(self, f, t, nil)
	obj._cbs = cb and { cb } or {}
	local listening = false

	local function show()
		if listening then
			btn.Text = "..."
		else
			btn.Text = key and key.Name or "Nenhuma"
		end
	end

	local function setKey(k, save)
		key = k
		listening = false
		show()
		if flag then
			win.Flags[flag] = k and k.Name or ""
			if save then
				win:_save()
			end
		end
	end

	btn.Activated:Connect(function()
		listening = true
		show()
	end)

	table.insert(win.Connections, UIS.InputBegan:Connect(function(input, gp)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					setKey(nil, true)
				else
					setKey(input.KeyCode, true)
				end
			end
			return
		end
		if not gp and key and input.KeyCode == key then
			obj:_emit(key)
		end
	end))

	function obj:Set(k)
		setKey(k, true)
	end
	function obj:Get()
		return key
	end
	show()
	return obj
end

function Tab:AddDiscordInvite(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Comunidade"
	local desc = cfg.Description or cfg.Desc or cfg[2] or ""
	local logo = cfg.Logo or cfg.Icon or cfg.Image or ""
	local invite = cfg.Invite or cfg.Link or ""

	local extra = {}
	if cfg.MembersOnline or cfg.Online then
		table.insert(extra, "Online: " .. tostring(cfg.MembersOnline or cfg.Online))
	end
	if cfg.Members or cfg.TotalMembers then
		table.insert(extra, "Membros: " .. tostring(cfg.Members or cfg.TotalMembers))
	end
	if #extra > 0 then
		desc = desc .. "\n" .. table.concat(extra, " · ")
	end

	local f = self:_row(104)
	local img = new("ImageLabel", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(72, 72),
		BackgroundTransparency = 1,
		Image = tostring(logo),
		ScaleType = Enum.ScaleType.Fit,
	}, f)
	corner(img, 36)

	local t = label(f, {
		Position = UDim2.fromOffset(92, 10),
		Size = UDim2.new(1, -100, 0, 18),
		Text = tostring(name),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, "Text")
	local d = label(f, {
		Position = UDim2.fromOffset(92, 30),
		Size = UDim2.new(1, -100, 0, 40),
		Text = tostring(desc),
		TextSize = 11,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.None,
	}, "TextDark")

	local btn = reg(new("TextButton", {
		Position = UDim2.new(1, -10, 1, -10),
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.fromOffset(124, 24),
		AutoButtonColor = false,
		Text = "Copiar convite",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
	}, f), "BackgroundColor3", "Primary")
	reg(btn, "TextColor3", "Text")
	corner(btn, 4)
	btn.Activated:Connect(function()
		if setclipboard and invite ~= "" then
			setclipboard(invite)
			btn.Text = "Copiado!"
			task.delay(1.5, function()
				if btn.Parent then
					btn.Text = "Copiar convite"
				end
			end)
		end
	end)
	return newComp(self, f, t, d)
end

-- Grade de 12 cores (usada em Personalizar)
function Tab:_palette(title, current, onPick)
	self.Order = self.Order + 1
	local box = reg(new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	box.BackgroundTransparency = 0.25
	corner(box, 6)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
	}, box)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, box)

	local head = label(box, {
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		LayoutOrder = 1,
	}, "Text")

	local grid = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, box)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(56, 26),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	local sel = current
	local swatches = {}

	local function refresh()
		head.Text = title .. ": " .. tostring(sel)
		for n, sw in pairs(swatches) do
			sw.Enabled = (n == sel)
		end
	end

	for i, item in ipairs(PALETTE) do
		local c = item.color
		local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
		local b = new("TextButton", {
			BackgroundColor3 = c,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
		}, grid)
		corner(b, 6)
		local st = new("UIStroke", {
			Color = (lum > 0.6) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1),
			Thickness = 2,
			Enabled = false,
		}, b)
		swatches[item.name] = st
		b.Activated:Connect(function()
			sel = item.name
			refresh()
			if onPick then
				onPick(item.name)
			end
		end)
	end

	refresh()
	return box
end

-- Ícones Lucide (monocromáticos) extraídos de lucide-roblox 0.1.3 / Lucide 0.363.0 (MIT, Latte Softworks)
-- Formato: nome = {id da spritesheet, {largura, altura}, {offsetX, offsetY}} tamanho 256px
local LUCIDE_ICONS = {
	["a-arrow-down"] = {16898612629, {256, 256}, {0, 0}},
	["a-arrow-up"] = {16898612629, {256, 256}, {257, 0}},
	["a-large-small"] = {16898612629, {256, 256}, {0, 257}},
	accessibility = {16898612629, {256, 256}, {514, 0}},
	["activity-square"] = {16898612629, {256, 256}, {257, 257}},
	["air-vent"] = {16898612629, {256, 256}, {514, 257}},
	airplay = {16898612629, {256, 256}, {257, 514}},
	["alarm-check"] = {16898612629, {256, 256}, {514, 514}},
	["alarm-clock"] = {16898612819, {256, 256}, {257, 257}},
	["alarm-clock-check"] = {16898612819, {256, 256}, {0, 0}},
	["alarm-clock-minus"] = {16898612819, {256, 256}, {257, 0}},
	["alarm-clock-off"] = {16898612819, {256, 256}, {0, 257}},
	["alarm-minus"] = {16898612819, {256, 256}, {0, 514}},
	["alarm-plus"] = {16898612819, {256, 256}, {514, 257}},
	album = {16898612819, {256, 256}, {514, 514}},
	["alert-circle"] = {16898613044, {256, 256}, {0, 0}},
	["alert-octagon"] = {16898613044, {256, 256}, {257, 0}},
	["align-center"] = {16898613044, {256, 256}, {0, 514}},
	["align-center-horizontal"] = {16898613044, {256, 256}, {514, 0}},
	["align-center-vertical"] = {16898613044, {256, 256}, {257, 257}},
	["align-end-horizontal"] = {16898613044, {256, 256}, {514, 257}},
	["align-end-vertical"] = {16898613044, {256, 256}, {257, 514}},
	["align-horizontal-justify-center"] = {16898613353, {256, 256}, {0, 257}},
	["align-horizontal-justify-end"] = {16898613353, {256, 256}, {514, 0}},
	["align-justify"] = {16898613353, {256, 256}, {257, 514}},
	["align-right"] = {16898613509, {256, 256}, {0, 0}},
	["align-vertical-distribute-end"] = {16898613509, {256, 256}, {257, 257}},
	["align-vertical-justify-end"] = {16898613509, {256, 256}, {257, 514}},
	["align-vertical-justify-start"] = {16898613509, {256, 256}, {514, 514}},
	["align-vertical-space-around"] = {16898613613, {256, 256}, {0, 0}},
	ampersands = {16898613613, {256, 256}, {257, 257}},
	anchor = {16898613613, {256, 256}, {0, 514}},
	angry = {16898613613, {256, 256}, {514, 257}},
	annoyed = {16898613613, {256, 256}, {257, 514}},
	anvil = {16898613699, {256, 256}, {0, 0}},
	["app-window"] = {16898613699, {256, 256}, {514, 0}},
	["app-window-mac"] = {16898613699, {256, 256}, {0, 257}},
	apple = {16898613699, {256, 256}, {257, 257}},
	archive = {16898613699, {256, 256}, {257, 514}},
	["archive-restore"] = {16898613699, {256, 256}, {0, 514}},
	["archive-x"] = {16898613699, {256, 256}, {514, 257}},
	["area-chart"] = {16898613699, {256, 256}, {514, 514}},
	armchair = {16898613777, {256, 256}, {0, 0}},
	["arrow-big-down"] = {16898613777, {256, 256}, {0, 257}},
	["arrow-big-down-dash"] = {16898613777, {256, 256}, {257, 0}},
	["arrow-big-left"] = {16898613777, {256, 256}, {257, 257}},
	["arrow-big-right"] = {16898613777, {256, 256}, {514, 257}},
	["arrow-big-up"] = {16898613777, {256, 256}, {514, 514}},
	["arrow-big-up-dash"] = {16898613777, {256, 256}, {257, 514}},
	["arrow-down-0-1"] = {16898613869, {256, 256}, {0, 0}},
	["arrow-down-1-0"] = {16898613869, {256, 256}, {257, 0}},
	["arrow-down-a-z"] = {16898613869, {256, 256}, {0, 257}},
	["arrow-down-from-line"] = {16898613869, {256, 256}, {257, 257}},
	["arrow-down-left"] = {16898613869, {256, 256}, {257, 514}},
	["arrow-down-left-from-circle"] = {16898613869, {256, 256}, {0, 514}},
	["arrow-down-narrow-wide"] = {16898613869, {256, 256}, {514, 514}},
	["arrow-down-right"] = {16898614020, {256, 256}, {0, 257}},
	["arrow-down-right-from-circle"] = {16898614020, {256, 256}, {0, 0}},
	["arrow-down-right-square"] = {16898614020, {256, 256}, {257, 0}},
	["arrow-down-square"] = {16898614020, {256, 256}, {514, 0}},
	["arrow-down-wide-narrow"] = {16898614020, {256, 256}, {257, 514}},
	["arrow-down-z-a"] = {16898614020, {256, 256}, {514, 514}},
	["arrow-left-circle"] = {16898614166, {256, 256}, {257, 0}},
	["arrow-left-from-line"] = {16898614166, {256, 256}, {0, 257}},
	["arrow-left-right"] = {16898614166, {256, 256}, {514, 0}},
	["arrow-left-square"] = {16898614166, {256, 256}, {257, 257}},
	["arrow-left-to-line"] = {16898614166, {256, 256}, {0, 514}},
	["arrow-right-from-line"] = {16898614166, {256, 256}, {514, 514}},
	["arrow-right-left"] = {16898614275, {256, 256}, {0, 0}},
	["arrow-right-square"] = {16898614275, {256, 256}, {257, 0}},
	["arrow-up-0-1"] = {16898614275, {256, 256}, {257, 257}},
	["arrow-up-1-0"] = {16898614275, {256, 256}, {0, 514}},
	["arrow-up-a-z"] = {16898614275, {256, 256}, {514, 257}},
	["arrow-up-circle"] = {16898614275, {256, 256}, {257, 514}},
	["arrow-up-down"] = {16898614275, {256, 256}, {514, 514}},
	["arrow-up-from-dot"] = {16898614410, {256, 256}, {0, 0}},
	["arrow-up-from-line"] = {16898614410, {256, 256}, {257, 0}},
	["arrow-up-left"] = {16898614410, {256, 256}, {257, 257}},
	["arrow-up-left-square"] = {16898614410, {256, 256}, {514, 0}},
	["arrow-up-narrow-wide"] = {16898614410, {256, 256}, {0, 514}},
	["arrow-up-right"] = {16898614410, {256, 256}, {514, 514}},
	["arrow-up-right-from-circle"] = {16898614410, {256, 256}, {514, 257}},
	["arrow-up-right-square"] = {16898614410, {256, 256}, {257, 514}},
	["arrow-up-to-line"] = {16898614574, {256, 256}, {257, 0}},
	["arrow-up-z-a"] = {16898614574, {256, 256}, {514, 0}},
	asterisk = {16898614574, {256, 256}, {514, 257}},
	["at-sign"] = {16898614574, {256, 256}, {257, 514}},
	atom = {16898614574, {256, 256}, {514, 514}},
	["audio-lines"] = {16898614755, {256, 256}, {0, 0}},
	["audio-waveform"] = {16898614755, {256, 256}, {257, 0}},
	axe = {16898614755, {256, 256}, {514, 0}},
	["axis-3d"] = {16898614755, {256, 256}, {257, 257}},
	baby = {16898614755, {256, 256}, {0, 514}},
	backpack = {16898614755, {256, 256}, {514, 257}},
	["badge-check"] = {16898614945, {256, 256}, {0, 0}},
	["badge-dollar-sign"] = {16898614945, {256, 256}, {257, 0}},
	["badge-euro"] = {16898614945, {256, 256}, {0, 257}},
	["badge-japanese-yen"] = {16898614945, {256, 256}, {514, 257}},
	["badge-minus"] = {16898614945, {256, 256}, {257, 514}},
	["badge-swiss-franc"] = {16898615022, {256, 256}, {514, 0}},
	["badge-x"] = {16898615022, {256, 256}, {257, 257}},
	["baggage-claim"] = {16898615022, {256, 256}, {514, 257}},
	ban = {16898615022, {256, 256}, {257, 514}},
	banana = {16898615022, {256, 256}, {514, 514}},
	["bar-chart"] = {16898615143, {256, 256}, {257, 514}},
	["bar-chart-2"] = {16898615143, {256, 256}, {257, 0}},
	["bar-chart-3"] = {16898615143, {256, 256}, {0, 257}},
	["bar-chart-big"] = {16898615143, {256, 256}, {257, 257}},
	["bar-chart-horizontal-big"] = {16898615143, {256, 256}, {0, 514}},
	baseline = {16898615240, {256, 256}, {0, 0}},
	bath = {16898615240, {256, 256}, {257, 0}},
	battery = {16898615240, {256, 256}, {257, 514}},
	["battery-charging"] = {16898615240, {256, 256}, {0, 257}},
	["battery-full"] = {16898615240, {256, 256}, {514, 0}},
	["battery-warning"] = {16898615240, {256, 256}, {514, 257}},
	beaker = {16898615240, {256, 256}, {514, 514}},
	bean = {16898615374, {256, 256}, {257, 0}},
	["bean-off"] = {16898615374, {256, 256}, {0, 0}},
	beef = {16898615374, {256, 256}, {0, 514}},
	beer = {16898615374, {256, 256}, {257, 514}},
	["beer-off"] = {16898615374, {256, 256}, {514, 257}},
	bell = {16898615428, {256, 256}, {0, 514}},
	["bell-dot"] = {16898615374, {256, 256}, {514, 514}},
	["bell-electric"] = {16898615428, {256, 256}, {0, 0}},
	["bell-minus"] = {16898615428, {256, 256}, {257, 0}},
	["bell-off"] = {16898615428, {256, 256}, {0, 257}},
	["bell-plus"] = {16898615428, {256, 256}, {514, 0}},
	["bell-ring"] = {16898615428, {256, 256}, {257, 257}},
	["between-horizontal-start"] = {16898615428, {256, 256}, {257, 514}},
	["between-vertical-end"] = {16898615428, {256, 256}, {514, 514}},
	bike = {16898615570, {256, 256}, {257, 0}},
	binary = {16898615570, {256, 256}, {0, 257}},
	bird = {16898615570, {256, 256}, {257, 257}},
	bitcoin = {16898615570, {256, 256}, {0, 514}},
	blend = {16898615570, {256, 256}, {514, 257}},
	blocks = {16898615570, {256, 256}, {514, 514}},
	bluetooth = {16898615799, {256, 256}, {514, 0}},
	["bluetooth-off"] = {16898615799, {256, 256}, {257, 0}},
	bolt = {16898615799, {256, 256}, {0, 514}},
	bomb = {16898615799, {256, 256}, {514, 257}},
	bone = {16898615799, {256, 256}, {257, 514}},
	book = {16898616524, {256, 256}, {257, 257}},
	["book-a"] = {16898615799, {256, 256}, {514, 514}},
	["book-check"] = {16898616080, {256, 256}, {257, 0}},
	["book-headphones"] = {16898616080, {256, 256}, {0, 514}},
	["book-key"] = {16898616080, {256, 256}, {514, 514}},
	["book-lock"] = {16898616322, {256, 256}, {0, 0}},
	["book-minus"] = {16898616322, {256, 256}, {0, 257}},
	["book-open-text"] = {16898616322, {256, 256}, {257, 257}},
	["book-plus"] = {16898616322, {256, 256}, {514, 257}},
	["book-text"] = {16898616322, {256, 256}, {257, 514}},
	["book-type"] = {16898616322, {256, 256}, {514, 514}},
	["book-up-2"] = {16898616524, {256, 256}, {0, 0}},
	["book-x"] = {16898616524, {256, 256}, {514, 0}},
	bookmark = {16898616650, {256, 256}, {0, 0}},
	["bookmark-check"] = {16898616524, {256, 256}, {0, 514}},
	["bookmark-minus"] = {16898616524, {256, 256}, {514, 257}},
	["bookmark-plus"] = {16898616524, {256, 256}, {257, 514}},
	["boom-box"] = {16898616650, {256, 256}, {257, 0}},
	box = {16898616650, {256, 256}, {0, 514}},
	boxes = {16898616650, {256, 256}, {514, 257}},
	braces = {16898616650, {256, 256}, {257, 514}},
	brain = {16898616757, {256, 256}, {0, 257}},
	["brick-wall"] = {16898616757, {256, 256}, {514, 0}},
	briefcase = {16898616757, {256, 256}, {514, 257}},
	["briefcase-medical"] = {16898616757, {256, 256}, {0, 514}},
	["bring-to-front"] = {16898616757, {256, 256}, {257, 514}},
	brush = {16898616757, {256, 256}, {514, 514}},
	["bug-off"] = {16898616879, {256, 256}, {0, 0}},
	["bug-play"] = {16898616879, {256, 256}, {257, 0}},
	["bus-front"] = {16898616879, {256, 256}, {0, 514}},
	cable = {16898616879, {256, 256}, {514, 514}},
	cake = {16898616953, {256, 256}, {257, 0}},
	calculator = {16898616953, {256, 256}, {0, 257}},
	calendar = {16898617146, {256, 256}, {0, 0}},
	["calendar-check"] = {16898616953, {256, 256}, {257, 257}},
	["calendar-fold"] = {16898616953, {256, 256}, {257, 514}},
	["calendar-heart"] = {16898616953, {256, 256}, {514, 514}},
	["calendar-minus"] = {16898617053, {256, 256}, {257, 0}},
	["calendar-minus-2"] = {16898617053, {256, 256}, {0, 0}},
	["calendar-off"] = {16898617053, {256, 256}, {0, 257}},
	["calendar-plus"] = {16898617053, {256, 256}, {257, 257}},
	["calendar-plus-2"] = {16898617053, {256, 256}, {514, 0}},
	["calendar-search"] = {16898617053, {256, 256}, {514, 257}},
	["calendar-x-2"] = {16898617053, {256, 256}, {257, 514}},
	camera = {16898617146, {256, 256}, {0, 257}},
	candy = {16898617146, {256, 256}, {514, 257}},
	["candy-cane"] = {16898617146, {256, 256}, {257, 257}},
	["candy-off"] = {16898617146, {256, 256}, {0, 514}},
	cannabis = {16898617146, {256, 256}, {257, 514}},
	captions = {16898617249, {256, 256}, {0, 0}},
	["captions-off"] = {16898617146, {256, 256}, {514, 514}},
	car = {16898617249, {256, 256}, {514, 0}},
	["car-front"] = {16898617249, {256, 256}, {257, 0}},
	["car-taxi-front"] = {16898617249, {256, 256}, {0, 257}},
	caravan = {16898617249, {256, 256}, {257, 257}},
	carrot = {16898617249, {256, 256}, {0, 514}},
	["case-lower"] = {16898617249, {256, 256}, {514, 257}},
	["case-sensitive"] = {16898617249, {256, 256}, {257, 514}},
	["case-upper"] = {16898617249, {256, 256}, {514, 514}},
	["cassette-tape"] = {16898617325, {256, 256}, {0, 0}},
	castle = {16898617325, {256, 256}, {0, 257}},
	cat = {16898617325, {256, 256}, {514, 0}},
	cctv = {16898617325, {256, 256}, {257, 257}},
	check = {16898617411, {256, 256}, {257, 0}},
	["check-check"] = {16898617325, {256, 256}, {0, 514}},
	["check-circle"] = {16898617325, {256, 256}, {257, 514}},
	["check-circle-2"] = {16898617325, {256, 256}, {514, 257}},
	["check-square-2"] = {16898617325, {256, 256}, {514, 514}},
	["chef-hat"] = {16898617411, {256, 256}, {0, 257}},
	["chevron-down"] = {16898617411, {256, 256}, {514, 257}},
	["chevron-down-circle"] = {16898617411, {256, 256}, {257, 257}},
	["chevron-down-square"] = {16898617411, {256, 256}, {0, 514}},
	["chevron-first"] = {16898617411, {256, 256}, {257, 514}},
	["chevron-last"] = {16898617411, {256, 256}, {514, 514}},
	["chevron-left-circle"] = {16898617509, {256, 256}, {0, 0}},
	["chevron-right-square"] = {16898617509, {256, 256}, {257, 257}},
	["chevron-up"] = {16898617509, {256, 256}, {514, 514}},
	["chevron-up-circle"] = {16898617509, {256, 256}, {514, 257}},
	["chevrons-down-up"] = {16898617626, {256, 256}, {0, 0}},
	["chevrons-left"] = {16898617626, {256, 256}, {514, 0}},
	["chevrons-left-right"] = {16898617626, {256, 256}, {0, 257}},
	["chevrons-right-left"] = {16898617626, {256, 256}, {257, 257}},
	["chevrons-up"] = {16898617626, {256, 256}, {257, 514}},
	["chevrons-up-down"] = {16898617626, {256, 256}, {514, 257}},
	chrome = {16898617626, {256, 256}, {514, 514}},
	church = {16898617705, {256, 256}, {0, 0}},
	cigarette = {16898617705, {256, 256}, {0, 257}},
	circle = {16898618049, {256, 256}, {257, 514}},
	["circle-arrow-down"] = {16898617705, {256, 256}, {257, 257}},
	["circle-arrow-out-down-left"] = {16898617705, {256, 256}, {514, 257}},
	["circle-arrow-out-up-right"] = {16898617803, {256, 256}, {0, 0}},
	["circle-arrow-right"] = {16898617803, {256, 256}, {257, 0}},
	["circle-arrow-up"] = {16898617803, {256, 256}, {0, 257}},
	["circle-check"] = {16898617803, {256, 256}, {257, 257}},
	["circle-check-big"] = {16898617803, {256, 256}, {514, 0}},
	["circle-chevron-left"] = {16898617803, {256, 256}, {514, 257}},
	["circle-chevron-up"] = {16898617803, {256, 256}, {514, 514}},
	["circle-dollar-sign"] = {16898617884, {256, 256}, {0, 257}},
	["circle-ellipsis"] = {16898617884, {256, 256}, {0, 514}},
	["circle-equal"] = {16898617884, {256, 256}, {514, 257}},
	["circle-gauge"] = {16898617884, {256, 256}, {514, 514}},
	["circle-off"] = {16898617944, {256, 256}, {0, 257}},
	["circle-parking"] = {16898617944, {256, 256}, {257, 257}},
	["circle-pause"] = {16898617944, {256, 256}, {0, 514}},
	["circle-percent"] = {16898617944, {256, 256}, {514, 257}},
	["circle-play"] = {16898617944, {256, 256}, {257, 514}},
	["circle-power"] = {16898618049, {256, 256}, {0, 0}},
	["circle-slash"] = {16898618049, {256, 256}, {0, 257}},
	["circle-slash-2"] = {16898618049, {256, 256}, {257, 0}},
	["circle-stop"] = {16898618049, {256, 256}, {514, 0}},
	["circle-user"] = {16898618049, {256, 256}, {0, 514}},
	["circle-user-round"] = {16898618049, {256, 256}, {257, 257}},
	["circle-x"] = {16898618049, {256, 256}, {514, 257}},
	["circuit-board"] = {16898618049, {256, 256}, {514, 514}},
	citrus = {16898618228, {256, 256}, {0, 0}},
	clipboard = {16898618392, {256, 256}, {0, 514}},
	["clipboard-list"] = {16898618228, {256, 256}, {0, 514}},
	["clipboard-minus"] = {16898618228, {256, 256}, {514, 257}},
	["clipboard-pen"] = {16898618392, {256, 256}, {0, 0}},
	["clipboard-type"] = {16898618392, {256, 256}, {514, 0}},
	["clipboard-x"] = {16898618392, {256, 256}, {257, 257}},
	clock = {16898618763, {256, 256}, {0, 0}},
	["clock-10"] = {16898618392, {256, 256}, {257, 514}},
	["clock-2"] = {16898618583, {256, 256}, {257, 0}},
	["clock-3"] = {16898618583, {256, 256}, {0, 257}},
	["clock-4"] = {16898618583, {256, 256}, {514, 0}},
	["clock-7"] = {16898618583, {256, 256}, {514, 257}},
	["clock-8"] = {16898618583, {256, 256}, {257, 514}},
	["clock-9"] = {16898618583, {256, 256}, {514, 514}},
	cloud = {16898618899, {256, 256}, {257, 514}},
	["cloud-download"] = {16898618763, {256, 256}, {0, 257}},
	["cloud-drizzle"] = {16898618763, {256, 256}, {514, 0}},
	["cloud-fog"] = {16898618763, {256, 256}, {257, 257}},
	["cloud-hail"] = {16898618763, {256, 256}, {0, 514}},
	["cloud-lightning"] = {16898618763, {256, 256}, {514, 257}},
	["cloud-off"] = {16898618899, {256, 256}, {0, 0}},
	["cloud-rain"] = {16898618899, {256, 256}, {0, 257}},
	["cloud-rain-wind"] = {16898618899, {256, 256}, {257, 0}},
	["cloud-snow"] = {16898618899, {256, 256}, {514, 0}},
	["cloud-sun"] = {16898618899, {256, 256}, {0, 514}},
	["cloud-sun-rain"] = {16898618899, {256, 256}, {257, 257}},
	["cloud-upload"] = {16898618899, {256, 256}, {514, 257}},
	clover = {16898619015, {256, 256}, {0, 0}},
	["code-2"] = {16898619015, {256, 256}, {0, 257}},
	codepen = {16898619015, {256, 256}, {0, 514}},
	codesandbox = {16898619015, {256, 256}, {514, 257}},
	coffee = {16898619015, {256, 256}, {257, 514}},
	coins = {16898619182, {256, 256}, {0, 0}},
	["columns-2"] = {16898619182, {256, 256}, {257, 0}},
	["columns-4"] = {16898619182, {256, 256}, {514, 0}},
	combine = {16898619182, {256, 256}, {0, 514}},
	compass = {16898619182, {256, 256}, {257, 514}},
	component = {16898619182, {256, 256}, {514, 514}},
	computer = {16898619347, {256, 256}, {0, 0}},
	cone = {16898619347, {256, 256}, {0, 257}},
	construction = {16898619347, {256, 256}, {514, 0}},
	contact = {16898619347, {256, 256}, {514, 257}},
	["contact-round"] = {16898619347, {256, 256}, {0, 514}},
	contrast = {16898619347, {256, 256}, {514, 514}},
	copy = {16898619423, {256, 256}, {257, 514}},
	["copy-check"] = {16898619423, {256, 256}, {0, 257}},
	["copy-plus"] = {16898619423, {256, 256}, {257, 257}},
	["copy-slash"] = {16898619423, {256, 256}, {0, 514}},
	["copy-x"] = {16898619423, {256, 256}, {514, 257}},
	copyright = {16898668288, {256, 256}, {0, 0}},
	["corner-down-left"] = {16898668288, {256, 256}, {257, 0}},
	["corner-down-right"] = {16898668288, {256, 256}, {0, 257}},
	["corner-right-down"] = {16898668288, {256, 256}, {0, 514}},
	["corner-right-up"] = {16898668288, {256, 256}, {514, 257}},
	["corner-up-left"] = {16898668288, {256, 256}, {257, 514}},
	["corner-up-right"] = {16898668288, {256, 256}, {514, 514}},
	cpu = {16898668482, {256, 256}, {0, 0}},
	["creative-commons"] = {16898668482, {256, 256}, {257, 0}},
	croissant = {16898668482, {256, 256}, {514, 0}},
	cross = {16898668482, {256, 256}, {0, 514}},
	["cup-soda"] = {16898668755, {256, 256}, {0, 0}},
	currency = {16898668755, {256, 256}, {257, 0}},
	database = {16898668755, {256, 256}, {0, 514}},
	["database-zap"] = {16898668755, {256, 256}, {257, 257}},
	delete = {16898668755, {256, 256}, {514, 257}},
	dessert = {16898668755, {256, 256}, {257, 514}},
	diamond = {16898669042, {256, 256}, {257, 0}},
	["dice-2"] = {16898669042, {256, 256}, {514, 0}},
	["dice-3"] = {16898669042, {256, 256}, {257, 257}},
	["dice-4"] = {16898669042, {256, 256}, {0, 514}},
	["dice-5"] = {16898669042, {256, 256}, {514, 257}},
	dices = {16898669042, {256, 256}, {514, 514}},
	disc = {16898669271, {256, 256}, {257, 257}},
	["disc-2"] = {16898669271, {256, 256}, {257, 0}},
	["disc-album"] = {16898669271, {256, 256}, {514, 0}},
	divide = {16898669271, {256, 256}, {257, 514}},
	["divide-circle"] = {16898669271, {256, 256}, {0, 514}},
	["divide-square"] = {16898669271, {256, 256}, {514, 257}},
	["dna-off"] = {16898669271, {256, 256}, {514, 514}},
	dock = {16898669433, {256, 256}, {257, 0}},
	dog = {16898669433, {256, 256}, {0, 257}},
	["dollar-sign"] = {16898669433, {256, 256}, {514, 0}},
	donut = {16898669433, {256, 256}, {257, 257}},
	["door-closed"] = {16898669433, {256, 256}, {0, 514}},
	["door-open"] = {16898669433, {256, 256}, {514, 257}},
	dot = {16898669433, {256, 256}, {257, 514}},
	download = {16898669562, {256, 256}, {0, 0}},
	["download-cloud"] = {16898669433, {256, 256}, {514, 514}},
	["drafting-compass"] = {16898669562, {256, 256}, {257, 0}},
	drama = {16898669562, {256, 256}, {0, 257}},
	dribbble = {16898669562, {256, 256}, {514, 0}},
	drill = {16898669562, {256, 256}, {257, 257}},
	drum = {16898669562, {256, 256}, {257, 514}},
	drumstick = {16898669562, {256, 256}, {514, 514}},
	dumbbell = {16898669689, {256, 256}, {0, 0}},
	ear = {16898669689, {256, 256}, {0, 257}},
	["ear-off"] = {16898669689, {256, 256}, {257, 0}},
	["earth-lock"] = {16898669689, {256, 256}, {514, 0}},
	egg = {16898669689, {256, 256}, {514, 514}},
	["egg-fried"] = {16898669689, {256, 256}, {514, 257}},
	["egg-off"] = {16898669689, {256, 256}, {257, 514}},
	eraser = {16898669772, {256, 256}, {257, 257}},
	euro = {16898669772, {256, 256}, {0, 514}},
	expand = {16898669772, {256, 256}, {514, 257}},
	eye = {16898669897, {256, 256}, {0, 0}},
	["eye-off"] = {16898669772, {256, 256}, {514, 514}},
	["fast-forward"] = {16898669897, {256, 256}, {257, 257}},
	feather = {16898669897, {256, 256}, {0, 514}},
	fence = {16898669897, {256, 256}, {514, 257}},
	["ferris-wheel"] = {16898669897, {256, 256}, {257, 514}},
	file = {16898670620, {256, 256}, {0, 514}},
	["file-archive"] = {16898669984, {256, 256}, {0, 0}},
	["file-audio"] = {16898669984, {256, 256}, {0, 257}},
	["file-badge-2"] = {16898669984, {256, 256}, {257, 257}},
	["file-check-2"] = {16898670072, {256, 256}, {0, 0}},
	["file-clock"] = {16898670072, {256, 256}, {0, 257}},
	["file-code"] = {16898670072, {256, 256}, {257, 257}},
	["file-cog"] = {16898670072, {256, 256}, {0, 514}},
	["file-digit"] = {16898670072, {256, 256}, {257, 514}},
	["file-down"] = {16898670072, {256, 256}, {514, 514}},
	["file-edit"] = {16898670171, {256, 256}, {0, 0}},
	["file-heart"] = {16898670171, {256, 256}, {257, 0}},
	["file-json"] = {16898670171, {256, 256}, {0, 514}},
	["file-key"] = {16898670171, {256, 256}, {257, 514}},
	["file-line-chart"] = {16898670171, {256, 256}, {514, 514}},
	["file-lock"] = {16898670241, {256, 256}, {257, 0}},
	["file-lock-2"] = {16898670241, {256, 256}, {0, 0}},
	["file-minus"] = {16898670241, {256, 256}, {514, 0}},
	["file-music"] = {16898670241, {256, 256}, {257, 257}},
	["file-pen"] = {16898670241, {256, 256}, {257, 514}},
	["file-pen-line"] = {16898670241, {256, 256}, {514, 257}},
	["file-plus"] = {16898670367, {256, 256}, {257, 0}},
	["file-plus-2"] = {16898670367, {256, 256}, {0, 0}},
	["file-search"] = {16898670367, {256, 256}, {0, 514}},
	["file-search-2"] = {16898670367, {256, 256}, {257, 257}},
	["file-signature"] = {16898670367, {256, 256}, {514, 257}},
	["file-sliders"] = {16898670367, {256, 256}, {257, 514}},
	["file-spreadsheet"] = {16898670367, {256, 256}, {514, 514}},
	["file-stack"] = {16898670469, {256, 256}, {0, 0}},
	["file-symlink"] = {16898670469, {256, 256}, {257, 0}},
	["file-terminal"] = {16898670469, {256, 256}, {0, 257}},
	["file-text"] = {16898670469, {256, 256}, {514, 0}},
	["file-type"] = {16898670469, {256, 256}, {0, 514}},
	["file-type-2"] = {16898670469, {256, 256}, {257, 257}},
	["file-up"] = {16898670469, {256, 256}, {514, 257}},
	["file-video-2"] = {16898670469, {256, 256}, {257, 514}},
	["file-volume-2"] = {16898670620, {256, 256}, {0, 0}},
	["file-warning"] = {16898670620, {256, 256}, {0, 257}},
	["file-x"] = {16898670620, {256, 256}, {257, 257}},
	files = {16898670620, {256, 256}, {514, 257}},
	film = {16898670620, {256, 256}, {257, 514}},
	filter = {16898670775, {256, 256}, {0, 0}},
	["fish-symbol"] = {16898670775, {256, 256}, {257, 257}},
	["flag-triangle-left"] = {16898670775, {256, 256}, {257, 514}},
	["flag-triangle-right"] = {16898670775, {256, 256}, {514, 514}},
	flashlight = {16898670919, {256, 256}, {257, 257}},
	["flashlight-off"] = {16898670919, {256, 256}, {514, 0}},
	flower = {16898671019, {256, 256}, {257, 257}},
	["flower-2"] = {16898671019, {256, 256}, {514, 0}},
	focus = {16898671019, {256, 256}, {0, 514}},
	["fold-horizontal"] = {16898671019, {256, 256}, {514, 257}},
	["folder-archive"] = {16898671019, {256, 256}, {514, 514}},
	["folder-check"] = {16898671139, {256, 256}, {0, 0}},
	["folder-cog"] = {16898671139, {256, 256}, {514, 0}},
	["folder-dot"] = {16898671139, {256, 256}, {257, 257}},
	["folder-down"] = {16898671139, {256, 256}, {0, 514}},
	["folder-edit"] = {16898671139, {256, 256}, {514, 257}},
	["folder-git"] = {16898671139, {256, 256}, {514, 514}},
	["folder-git-2"] = {16898671139, {256, 256}, {257, 514}},
	["folder-heart"] = {16898671263, {256, 256}, {0, 0}},
	["folder-input"] = {16898671263, {256, 256}, {257, 0}},
	["folder-kanban"] = {16898671263, {256, 256}, {0, 257}},
	["folder-key"] = {16898671263, {256, 256}, {514, 0}},
	["folder-lock"] = {16898671263, {256, 256}, {257, 257}},
	["folder-open"] = {16898671263, {256, 256}, {257, 514}},
	["folder-plus"] = {16898671463, {256, 256}, {257, 0}},
	["folder-search"] = {16898671463, {256, 256}, {257, 257}},
	["folder-search-2"] = {16898671463, {256, 256}, {514, 0}},
	["folder-symlink"] = {16898671463, {256, 256}, {0, 514}},
	["folder-sync"] = {16898671463, {256, 256}, {514, 257}},
	["folder-tree"] = {16898671463, {256, 256}, {257, 514}},
	["folder-x"] = {16898671684, {256, 256}, {0, 0}},
	folders = {16898671684, {256, 256}, {0, 257}},
	footprints = {16898671684, {256, 256}, {514, 0}},
	forklift = {16898671684, {256, 256}, {257, 257}},
	["form-input"] = {16898671684, {256, 256}, {0, 514}},
	forward = {16898671684, {256, 256}, {514, 257}},
	frame = {16898671684, {256, 256}, {257, 514}},
	fullscreen = {16898672004, {256, 256}, {0, 257}},
	["function-square"] = {16898672004, {256, 256}, {514, 0}},
	["gallery-horizontal"] = {16898672004, {256, 256}, {0, 514}},
	["gallery-horizontal-end"] = {16898672004, {256, 256}, {257, 257}},
	["gallery-thumbnails"] = {16898672004, {256, 256}, {514, 257}},
	["gamepad-2"] = {16898672166, {256, 256}, {0, 0}},
	["gantt-chart"] = {16898672166, {256, 256}, {514, 0}},
	gauge = {16898672166, {256, 256}, {0, 514}},
	["gauge-circle"] = {16898672166, {256, 256}, {257, 257}},
	gem = {16898672166, {256, 256}, {257, 514}},
	ghost = {16898672166, {256, 256}, {514, 514}},
	gift = {16898672316, {256, 256}, {0, 0}},
	["git-branch"] = {16898672316, {256, 256}, {0, 257}},
	["git-commit-horizontal"] = {16898672316, {256, 256}, {514, 0}},
	["git-graph"] = {16898672316, {256, 256}, {514, 514}},
	["git-merge"] = {16898672450, {256, 256}, {0, 0}},
	["git-pull-request-create-arrow"] = {16898672450, {256, 256}, {514, 0}},
	["git-pull-request-draft"] = {16898672450, {256, 256}, {0, 514}},
	github = {16898672450, {256, 256}, {257, 514}},
	["glass-water"] = {16898672599, {256, 256}, {0, 0}},
	glasses = {16898672599, {256, 256}, {257, 0}},
	globe = {16898672599, {256, 256}, {257, 257}},
	goal = {16898672599, {256, 256}, {0, 514}},
	["graduation-cap"] = {16898672599, {256, 256}, {257, 514}},
	["grid-2x2"] = {16898672700, {256, 256}, {0, 0}},
	grip = {16898672700, {256, 256}, {257, 257}},
	["grip-vertical"] = {16898672700, {256, 256}, {514, 0}},
	guitar = {16898672700, {256, 256}, {514, 257}},
	ham = {16898672700, {256, 256}, {257, 514}},
	hammer = {16898672700, {256, 256}, {514, 514}},
	hand = {16898672829, {256, 256}, {0, 514}},
	["hand-coins"] = {16898672829, {256, 256}, {0, 0}},
	["hand-heart"] = {16898672829, {256, 256}, {257, 0}},
	["hand-metal"] = {16898672829, {256, 256}, {514, 0}},
	["hard-drive-upload"] = {16898672829, {256, 256}, {514, 514}},
	hash = {16898672954, {256, 256}, {0, 257}},
	haze = {16898672954, {256, 256}, {514, 0}},
	heading = {16898673115, {256, 256}, {0, 257}},
	["heading-1"] = {16898672954, {256, 256}, {0, 514}},
	["heading-2"] = {16898672954, {256, 256}, {514, 257}},
	["heading-3"] = {16898672954, {256, 256}, {257, 514}},
	["heading-4"] = {16898672954, {256, 256}, {514, 514}},
	["heading-6"] = {16898673115, {256, 256}, {257, 0}},
	headphones = {16898673115, {256, 256}, {514, 0}},
	headset = {16898673115, {256, 256}, {257, 257}},
	heart = {16898673271, {256, 256}, {0, 0}},
	["heart-crack"] = {16898673115, {256, 256}, {0, 514}},
	["helping-hand"] = {16898673271, {256, 256}, {514, 0}},
	hexagon = {16898673271, {256, 256}, {257, 257}},
	highlighter = {16898673271, {256, 256}, {0, 514}},
	history = {16898673271, {256, 256}, {514, 257}},
	home = {16898673271, {256, 256}, {257, 514}},
	hop = {16898673358, {256, 256}, {0, 0}},
	hospital = {16898673358, {256, 256}, {257, 0}},
	hotel = {16898673358, {256, 256}, {0, 257}},
	["ice-cream"] = {16898673358, {256, 256}, {257, 514}},
	["ice-cream-bowl"] = {16898673358, {256, 256}, {0, 514}},
	["ice-cream-cone"] = {16898673358, {256, 256}, {514, 257}},
	image = {16898673447, {256, 256}, {257, 257}},
	["image-down"] = {16898673358, {256, 256}, {514, 514}},
	["image-plus"] = {16898673447, {256, 256}, {0, 257}},
	images = {16898673447, {256, 256}, {0, 514}},
	import = {16898673447, {256, 256}, {514, 257}},
	inbox = {16898673447, {256, 256}, {257, 514}},
	indent = {16898673523, {256, 256}, {257, 0}},
	["indent-increase"] = {16898673523, {256, 256}, {0, 0}},
	["indian-rupee"] = {16898673523, {256, 256}, {0, 257}},
	["kanban-square"] = {16898673616, {256, 256}, {257, 257}},
	["kanban-square-dashed"] = {16898673616, {256, 256}, {514, 0}},
	key = {16898673616, {256, 256}, {514, 514}},
	["key-square"] = {16898673616, {256, 256}, {257, 514}},
	keyboard = {16898673794, {256, 256}, {257, 0}},
	["keyboard-music"] = {16898673794, {256, 256}, {0, 0}},
	lamp = {16898673794, {256, 256}, {257, 514}},
	["lamp-desk"] = {16898673794, {256, 256}, {514, 0}},
	["lamp-wall-down"] = {16898673794, {256, 256}, {0, 514}},
	["lamp-wall-up"] = {16898673794, {256, 256}, {514, 257}},
	["land-plot"] = {16898673794, {256, 256}, {514, 514}},
	landmark = {16898673999, {256, 256}, {0, 0}},
	languages = {16898673999, {256, 256}, {257, 0}},
	laptop = {16898673999, {256, 256}, {257, 257}},
	["laptop-2"] = {16898673999, {256, 256}, {0, 257}},
	lasso = {16898673999, {256, 256}, {514, 257}},
	["layers-3"] = {16898674182, {256, 256}, {0, 0}},
	layout = {16898674182, {256, 256}, {514, 514}},
	["layout-dashboard"] = {16898674182, {256, 256}, {0, 257}},
	["layout-list"] = {16898674182, {256, 256}, {257, 257}},
	["layout-panel-left"] = {16898674182, {256, 256}, {0, 514}},
	["layout-template"] = {16898674182, {256, 256}, {257, 514}},
	leaf = {16898674337, {256, 256}, {0, 0}},
	["leafy-green"] = {16898674337, {256, 256}, {257, 0}},
	library = {16898674337, {256, 256}, {257, 257}},
	["life-buoy"] = {16898674337, {256, 256}, {0, 514}},
	ligature = {16898674337, {256, 256}, {514, 257}},
	lightbulb = {16898674337, {256, 256}, {514, 514}},
	["line-chart"] = {16898674482, {256, 256}, {0, 0}},
	["link-2-off"] = {16898674482, {256, 256}, {257, 0}},
	linkedin = {16898674482, {256, 256}, {257, 257}},
	list = {16898674684, {256, 256}, {257, 0}},
	["list-checks"] = {16898674482, {256, 256}, {0, 514}},
	["list-collapse"] = {16898674482, {256, 256}, {514, 257}},
	["list-end"] = {16898674482, {256, 256}, {257, 514}},
	["list-minus"] = {16898674572, {256, 256}, {0, 0}},
	["list-music"] = {16898674572, {256, 256}, {257, 0}},
	["list-plus"] = {16898674572, {256, 256}, {514, 0}},
	["list-start"] = {16898674572, {256, 256}, {0, 514}},
	["list-todo"] = {16898674572, {256, 256}, {514, 257}},
	["list-tree"] = {16898674572, {256, 256}, {257, 514}},
	["list-video"] = {16898674572, {256, 256}, {514, 514}},
	["list-x"] = {16898674684, {256, 256}, {0, 0}},
	loader = {16898674684, {256, 256}, {257, 257}},
	["locate-off"] = {16898674684, {256, 256}, {514, 257}},
	lock = {16898674825, {256, 256}, {0, 257}},
	["lock-keyhole"] = {16898674825, {256, 256}, {0, 0}},
	["lock-keyhole-open"] = {16898674684, {256, 256}, {514, 514}},
	["lock-open"] = {16898674825, {256, 256}, {257, 0}},
	["log-in"] = {16898674825, {256, 256}, {514, 0}},
	["log-out"] = {16898674825, {256, 256}, {257, 257}},
	lollipop = {16898674825, {256, 256}, {0, 514}},
	magnet = {16898674825, {256, 256}, {514, 514}},
	["mail-check"] = {16898675156, {256, 256}, {0, 0}},
	["mail-minus"] = {16898675156, {256, 256}, {257, 0}},
	["mail-plus"] = {16898675156, {256, 256}, {514, 0}},
	["mail-question"] = {16898675156, {256, 256}, {257, 257}},
	mailbox = {16898675359, {256, 256}, {0, 0}},
	mails = {16898675359, {256, 256}, {257, 0}},
	["map-pin-off"] = {16898675359, {256, 256}, {0, 257}},
	martini = {16898675359, {256, 256}, {514, 257}},
	maximize = {16898675359, {256, 256}, {514, 514}},
	megaphone = {16898675673, {256, 256}, {0, 257}},
	["megaphone-off"] = {16898675673, {256, 256}, {257, 0}},
	["memory-stick"] = {16898675673, {256, 256}, {257, 257}},
	menu = {16898675673, {256, 256}, {514, 257}},
	["menu-square"] = {16898675673, {256, 256}, {0, 514}},
	merge = {16898675673, {256, 256}, {257, 514}},
	["message-circle"] = {16898675863, {256, 256}, {0, 0}},
	["message-circle-code"] = {16898675673, {256, 256}, {514, 514}},
	["message-circle-heart"] = {16898675752, {256, 256}, {257, 0}},
	["message-circle-more"] = {16898675752, {256, 256}, {0, 257}},
	["message-circle-plus"] = {16898675752, {256, 256}, {257, 257}},
	["message-circle-question"] = {16898675752, {256, 256}, {0, 514}},
	["message-circle-warning"] = {16898675752, {256, 256}, {257, 514}},
	["message-circle-x"] = {16898675752, {256, 256}, {514, 514}},
	["message-square-code"] = {16898675863, {256, 256}, {257, 0}},
	["message-square-dashed"] = {16898675863, {256, 256}, {0, 257}},
	["message-square-diff"] = {16898675863, {256, 256}, {514, 0}},
	["message-square-more"] = {16898675863, {256, 256}, {514, 257}},
	["message-square-quote"] = {16898728402, {256, 256}, {0, 0}},
	["message-square-share"] = {16898728402, {256, 256}, {0, 257}},
	["message-square-text"] = {16898728402, {256, 256}, {514, 0}},
	mic = {16898728659, {256, 256}, {0, 257}},
	["mic-2"] = {16898728402, {256, 256}, {514, 514}},
	["mic-off"] = {16898728659, {256, 256}, {0, 0}},
	["mic-vocal"] = {16898728659, {256, 256}, {257, 0}},
	microwave = {16898728659, {256, 256}, {257, 257}},
	["milk-off"] = {16898728659, {256, 256}, {514, 257}},
	minimize = {16898728878, {256, 256}, {0, 0}},
	["minimize-2"] = {16898728659, {256, 256}, {514, 514}},
	minus = {16898728878, {256, 256}, {514, 0}},
	["minus-square"] = {16898728878, {256, 256}, {0, 257}},
	monitor = {16898729141, {256, 256}, {514, 257}},
	["monitor-pause"] = {16898728878, {256, 256}, {514, 514}},
	["monitor-play"] = {16898729141, {256, 256}, {0, 0}},
	["monitor-up"] = {16898729141, {256, 256}, {257, 257}},
	moon = {16898729141, {256, 256}, {514, 514}},
	["more-vertical"] = {16898729337, {256, 256}, {257, 0}},
	mountain = {16898729337, {256, 256}, {514, 0}},
	["mountain-snow"] = {16898729337, {256, 256}, {0, 257}},
	mouse = {16898729572, {256, 256}, {0, 0}},
	["mouse-pointer"] = {16898729337, {256, 256}, {514, 514}},
	["mouse-pointer-2"] = {16898729337, {256, 256}, {257, 257}},
	["mouse-pointer-click"] = {16898729337, {256, 256}, {0, 514}},
	["mouse-pointer-square"] = {16898729337, {256, 256}, {257, 514}},
	move = {16898729752, {256, 256}, {0, 514}},
	["move-diagonal"] = {16898729572, {256, 256}, {514, 0}},
	["move-down"] = {16898729572, {256, 256}, {514, 257}},
	["move-down-left"] = {16898729572, {256, 256}, {257, 257}},
	["move-down-right"] = {16898729572, {256, 256}, {0, 514}},
	["move-horizontal"] = {16898729572, {256, 256}, {257, 514}},
	["move-right"] = {16898729752, {256, 256}, {0, 0}},
	music = {16898730065, {256, 256}, {0, 0}},
	navigation = {16898730065, {256, 256}, {257, 257}},
	["navigation-off"] = {16898730065, {256, 256}, {514, 0}},
	network = {16898730065, {256, 256}, {0, 514}},
	newspaper = {16898730065, {256, 256}, {514, 257}},
	notebook = {16898730298, {256, 256}, {0, 257}},
	["notebook-pen"] = {16898730065, {256, 256}, {514, 514}},
	["notebook-text"] = {16898730298, {256, 256}, {257, 0}},
	["octagon-alert"] = {16898730298, {256, 256}, {257, 514}},
	["octagon-pause"] = {16898730298, {256, 256}, {514, 514}},
	option = {16898730417, {256, 256}, {0, 257}},
	orbit = {16898730417, {256, 256}, {514, 0}},
	outdent = {16898730417, {256, 256}, {257, 257}},
	["package-minus"] = {16898730417, {256, 256}, {257, 514}},
	["package-plus"] = {16898730641, {256, 256}, {0, 0}},
	["package-search"] = {16898730641, {256, 256}, {257, 0}},
	["package-x"] = {16898730641, {256, 256}, {0, 257}},
	["paint-bucket"] = {16898730641, {256, 256}, {257, 257}},
	["paint-roller"] = {16898730641, {256, 256}, {0, 514}},
	paintbrush = {16898730641, {256, 256}, {257, 514}},
	["paintbrush-2"] = {16898730641, {256, 256}, {514, 257}},
	palette = {16898730641, {256, 256}, {514, 514}},
	palmtree = {16898730821, {256, 256}, {0, 0}},
	["panel-bottom"] = {16898730821, {256, 256}, {0, 514}},
	["panel-left"] = {16898731024, {256, 256}, {257, 0}},
	["panel-left-inactive"] = {16898730821, {256, 256}, {514, 514}},
	["panel-right-open"] = {16898731024, {256, 256}, {0, 514}},
	["panel-top-close"] = {16898731024, {256, 256}, {257, 514}},
	["panel-top-inactive"] = {16898731166, {256, 256}, {0, 0}},
	["panels-top-left"] = {16898731166, {256, 256}, {0, 514}},
	paperclip = {16898731166, {256, 256}, {514, 257}},
	parentheses = {16898731166, {256, 256}, {257, 514}},
	["parking-circle"] = {16898731301, {256, 256}, {0, 0}},
	["parking-square-off"] = {16898731301, {256, 256}, {0, 257}},
	["party-popper"] = {16898731301, {256, 256}, {257, 257}},
	pause = {16898731301, {256, 256}, {257, 514}},
	["pause-octagon"] = {16898731301, {256, 256}, {514, 257}},
	["paw-print"] = {16898731301, {256, 256}, {514, 514}},
	["pc-case"] = {16898731419, {256, 256}, {0, 0}},
	pen = {16898731419, {256, 256}, {257, 257}},
	["pen-line"] = {16898731419, {256, 256}, {257, 0}},
	["pen-square"] = {16898731419, {256, 256}, {0, 257}},
	["pen-tool"] = {16898731419, {256, 256}, {514, 0}},
	pencil = {16898731419, {256, 256}, {257, 514}},
	["pencil-ruler"] = {16898731419, {256, 256}, {514, 257}},
	pentagon = {16898731419, {256, 256}, {514, 514}},
	percent = {16898731539, {256, 256}, {514, 0}},
	["percent-diamond"] = {16898731539, {256, 256}, {257, 0}},
	phone = {16898731683, {256, 256}, {0, 257}},
	["phone-forwarded"] = {16898731539, {256, 256}, {514, 257}},
	["phone-off"] = {16898731683, {256, 256}, {0, 0}},
	["phone-outgoing"] = {16898731683, {256, 256}, {257, 0}},
	["pi-square"] = {16898731683, {256, 256}, {514, 0}},
	pickaxe = {16898731683, {256, 256}, {514, 257}},
	["picture-in-picture"] = {16898731683, {256, 256}, {514, 514}},
	["picture-in-picture-2"] = {16898731683, {256, 256}, {257, 514}},
	["pie-chart"] = {16898731819, {256, 256}, {0, 0}},
	pilcrow = {16898731819, {256, 256}, {514, 0}},
	pin = {16898731819, {256, 256}, {514, 257}},
	["pin-off"] = {16898731819, {256, 256}, {0, 514}},
	pipette = {16898731819, {256, 256}, {257, 514}},
	pizza = {16898731819, {256, 256}, {514, 514}},
	plane = {16898731919, {256, 256}, {0, 257}},
	["plane-landing"] = {16898731919, {256, 256}, {0, 0}},
	["plane-takeoff"] = {16898731919, {256, 256}, {257, 0}},
	play = {16898731919, {256, 256}, {0, 514}},
	["play-circle"] = {16898731919, {256, 256}, {514, 0}},
	["play-square"] = {16898731919, {256, 256}, {257, 257}},
	plug = {16898732061, {256, 256}, {0, 0}},
	["plug-2"] = {16898731919, {256, 256}, {514, 257}},
	pocket = {16898732061, {256, 256}, {0, 514}},
	["pocket-knife"] = {16898732061, {256, 256}, {257, 257}},
	pointer = {16898732061, {256, 256}, {514, 514}},
	["pointer-off"] = {16898732061, {256, 256}, {257, 514}},
	popcorn = {16898732262, {256, 256}, {0, 0}},
	popsicle = {16898732262, {256, 256}, {257, 0}},
	power = {16898732262, {256, 256}, {514, 257}},
	["power-square"] = {16898732262, {256, 256}, {0, 514}},
	presentation = {16898732262, {256, 256}, {257, 514}},
	projector = {16898732504, {256, 256}, {0, 0}},
	pyramid = {16898732504, {256, 256}, {514, 0}},
	quote = {16898732504, {256, 256}, {0, 514}},
	rabbit = {16898732504, {256, 256}, {514, 257}},
	radar = {16898732504, {256, 256}, {257, 514}},
	radiation = {16898732504, {256, 256}, {514, 514}},
	radical = {16898732665, {256, 256}, {0, 0}},
	radio = {16898732665, {256, 256}, {514, 0}},
	["radio-receiver"] = {16898732665, {256, 256}, {257, 0}},
	["radio-tower"] = {16898732665, {256, 256}, {0, 257}},
	radius = {16898732665, {256, 256}, {257, 257}},
	["rail-symbol"] = {16898732665, {256, 256}, {0, 514}},
	rat = {16898732665, {256, 256}, {257, 514}},
	ratio = {16898732665, {256, 256}, {514, 514}},
	receipt = {16898732855, {256, 256}, {514, 514}},
	["receipt-cent"] = {16898732855, {256, 256}, {0, 0}},
	["receipt-euro"] = {16898732855, {256, 256}, {257, 0}},
	["receipt-indian-rupee"] = {16898732855, {256, 256}, {0, 257}},
	["receipt-pound-sterling"] = {16898732855, {256, 256}, {257, 257}},
	["receipt-swiss-franc"] = {16898732855, {256, 256}, {514, 257}},
	["rectangle-ellipsis"] = {16898733036, {256, 256}, {0, 0}},
	["rectangle-vertical"] = {16898733036, {256, 256}, {0, 257}},
	recycle = {16898733036, {256, 256}, {514, 0}},
	["redo-2"] = {16898733036, {256, 256}, {257, 257}},
	["redo-dot"] = {16898733036, {256, 256}, {0, 514}},
	["refresh-cw"] = {16898733146, {256, 256}, {257, 0}},
	["refresh-cw-off"] = {16898733146, {256, 256}, {0, 0}},
	refrigerator = {16898733146, {256, 256}, {0, 257}},
	regex = {16898733146, {256, 256}, {514, 0}},
	["remove-formatting"] = {16898733146, {256, 256}, {257, 257}},
	["repeat"] = {16898733146, {256, 256}, {257, 514}},
	["repeat-2"] = {16898733146, {256, 256}, {514, 257}},
	["replace-all"] = {16898733146, {256, 256}, {514, 514}},
	["reply-all"] = {16898733317, {256, 256}, {257, 0}},
	rewind = {16898733317, {256, 256}, {514, 0}},
	ribbon = {16898733317, {256, 256}, {257, 257}},
	rocket = {16898733317, {256, 256}, {0, 514}},
	["rotate-3d"] = {16898733317, {256, 256}, {514, 514}},
	["rotate-ccw"] = {16898733415, {256, 256}, {257, 0}},
	["rotate-cw"] = {16898733415, {256, 256}, {514, 0}},
	route = {16898733415, {256, 256}, {0, 514}},
	["route-off"] = {16898733415, {256, 256}, {257, 257}},
	router = {16898733415, {256, 256}, {514, 257}},
	rows = {16898733534, {256, 256}, {257, 0}},
	["rows-2"] = {16898733415, {256, 256}, {257, 514}},
	["rows-4"] = {16898733534, {256, 256}, {0, 0}},
	salad = {16898733534, {256, 256}, {514, 257}},
	sandwich = {16898733534, {256, 256}, {257, 514}},
	save = {16898733674, {256, 256}, {0, 257}},
	["save-all"] = {16898733674, {256, 256}, {257, 0}},
	scale = {16898733674, {256, 256}, {257, 257}},
	scaling = {16898733674, {256, 256}, {0, 514}},
	scan = {16898733817, {256, 256}, {514, 0}},
	["scan-barcode"] = {16898733674, {256, 256}, {514, 257}},
	["scan-search"] = {16898733817, {256, 256}, {257, 0}},
	["scatter-chart"] = {16898733817, {256, 256}, {257, 257}},
	school = {16898733817, {256, 256}, {514, 257}},
	scissors = {16898734065, {256, 256}, {257, 0}},
	["scissors-line-dashed"] = {16898733817, {256, 256}, {257, 514}},
	["scissors-square"] = {16898734065, {256, 256}, {0, 0}},
	search = {16898734242, {256, 256}, {257, 0}},
	["search-check"] = {16898734065, {256, 256}, {514, 257}},
	["search-slash"] = {16898734065, {256, 256}, {514, 514}},
	send = {16898734242, {256, 256}, {257, 257}},
	["send-horizontal"] = {16898734242, {256, 256}, {0, 257}},
	["separator-horizontal"] = {16898734242, {256, 256}, {0, 514}},
	["separator-vertical"] = {16898734242, {256, 256}, {514, 257}},
	server = {16898734421, {256, 256}, {257, 0}},
	["server-cog"] = {16898734242, {256, 256}, {257, 514}},
	["server-off"] = {16898734421, {256, 256}, {0, 0}},
	settings = {16898734421, {256, 256}, {514, 0}},
	["share-2"] = {16898734421, {256, 256}, {0, 514}},
	sheet = {16898734421, {256, 256}, {257, 514}},
	["shield-alert"] = {16898734564, {256, 256}, {0, 0}},
	["shield-ban"] = {16898734564, {256, 256}, {257, 0}},
	["shield-half"] = {16898734564, {256, 256}, {257, 257}},
	["shield-minus"] = {16898734564, {256, 256}, {0, 514}},
	["shield-plus"] = {16898734564, {256, 256}, {257, 514}},
	["shield-x"] = {16898734664, {256, 256}, {0, 0}},
	ship = {16898734664, {256, 256}, {514, 0}},
	["ship-wheel"] = {16898734664, {256, 256}, {0, 257}},
	shirt = {16898734664, {256, 256}, {257, 257}},
	["shopping-bag"] = {16898734664, {256, 256}, {0, 514}},
	shovel = {16898734664, {256, 256}, {514, 514}},
	["shower-head"] = {16898734792, {256, 256}, {0, 0}},
	shrink = {16898734792, {256, 256}, {257, 0}},
	shrub = {16898734792, {256, 256}, {0, 257}},
	shuffle = {16898734792, {256, 256}, {514, 0}},
	sigma = {16898734792, {256, 256}, {0, 514}},
	signal = {16898734905, {256, 256}, {257, 0}},
	["signal-medium"] = {16898734792, {256, 256}, {514, 514}},
	["signal-zero"] = {16898734905, {256, 256}, {0, 0}},
	signpost = {16898734905, {256, 256}, {514, 0}},
	["signpost-big"] = {16898734905, {256, 256}, {0, 257}},
	siren = {16898734905, {256, 256}, {257, 257}},
	["skip-back"] = {16898734905, {256, 256}, {0, 514}},
	["skip-forward"] = {16898734905, {256, 256}, {514, 257}},
	skull = {16898734905, {256, 256}, {257, 514}},
	slash = {16898735040, {256, 256}, {0, 0}},
	slice = {16898735040, {256, 256}, {257, 0}},
	sliders = {16898735040, {256, 256}, {257, 257}},
	["sliders-horizontal"] = {16898735040, {256, 256}, {0, 257}},
	["sliders-vertical"] = {16898735040, {256, 256}, {514, 0}},
	["smartphone-charging"] = {16898735040, {256, 256}, {0, 514}},
	["smartphone-nfc"] = {16898735040, {256, 256}, {514, 257}},
	smile = {16898735175, {256, 256}, {0, 0}},
	snail = {16898735175, {256, 256}, {257, 0}},
	soup = {16898735175, {256, 256}, {257, 257}},
	spade = {16898735175, {256, 256}, {514, 257}},
	sparkles = {16898735175, {256, 256}, {514, 514}},
	speaker = {16898735455, {256, 256}, {0, 0}},
	speech = {16898735455, {256, 256}, {257, 0}},
	["spell-check-2"] = {16898735455, {256, 256}, {0, 257}},
	spline = {16898735455, {256, 256}, {257, 257}},
	split = {16898735455, {256, 256}, {257, 514}},
	["split-square-vertical"] = {16898735455, {256, 256}, {514, 257}},
	square = {16898736597, {256, 256}, {257, 257}},
	["square-arrow-down"] = {16898735593, {256, 256}, {257, 257}},
	["square-arrow-down-right"] = {16898735593, {256, 256}, {514, 0}},
	["square-arrow-out-up-right"] = {16898735664, {256, 256}, {0, 0}},
	["square-arrow-right"] = {16898735664, {256, 256}, {257, 0}},
	["square-arrow-up-left"] = {16898735664, {256, 256}, {0, 257}},
	["square-asterisk"] = {16898735664, {256, 256}, {0, 514}},
	["square-check"] = {16898735664, {256, 256}, {514, 514}},
	["square-check-big"] = {16898735664, {256, 256}, {257, 514}},
	["square-chevron-down"] = {16898735845, {256, 256}, {0, 0}},
	["square-chevron-up"] = {16898735845, {256, 256}, {514, 0}},
	["square-code"] = {16898735845, {256, 256}, {257, 257}},
	["square-dashed-bottom"] = {16898735845, {256, 256}, {514, 257}},
	["square-dashed-mouse-pointer"] = {16898735845, {256, 256}, {514, 514}},
	["square-divide"] = {16898736072, {256, 256}, {0, 0}},
	["square-dot"] = {16898736072, {256, 256}, {257, 0}},
	["square-function"] = {16898736072, {256, 256}, {514, 0}},
	["square-gantt-chart"] = {16898736072, {256, 256}, {257, 257}},
	["square-kanban"] = {16898736072, {256, 256}, {0, 514}},
	["square-m"] = {16898736072, {256, 256}, {257, 514}},
	["square-menu"] = {16898736072, {256, 256}, {514, 514}},
	["square-minus"] = {16898736237, {256, 256}, {0, 0}},
	["square-parking-off"] = {16898736237, {256, 256}, {0, 257}},
	["square-percent"] = {16898736237, {256, 256}, {0, 514}},
	["square-play"] = {16898736237, {256, 256}, {514, 514}},
	["square-power"] = {16898736398, {256, 256}, {257, 0}},
	["square-scissors"] = {16898736398, {256, 256}, {514, 0}},
	["square-sigma"] = {16898736398, {256, 256}, {257, 257}},
	["square-slash"] = {16898736398, {256, 256}, {0, 514}},
	["square-x"] = {16898736597, {256, 256}, {514, 0}},
	squircle = {16898736597, {256, 256}, {0, 514}},
	stamp = {16898736597, {256, 256}, {257, 514}},
	star = {16898736776, {256, 256}, {257, 0}},
	["star-off"] = {16898736776, {256, 256}, {0, 0}},
	["step-back"] = {16898736776, {256, 256}, {0, 257}},
	["step-forward"] = {16898736776, {256, 256}, {514, 0}},
	stethoscope = {16898736776, {256, 256}, {257, 257}},
	sticker = {16898736776, {256, 256}, {0, 514}},
	["stop-circle"] = {16898736776, {256, 256}, {257, 514}},
	["stretch-horizontal"] = {16898736967, {256, 256}, {0, 0}},
	["stretch-vertical"] = {16898736967, {256, 256}, {257, 0}},
	strikethrough = {16898736967, {256, 256}, {0, 257}},
	subscript = {16898736967, {256, 256}, {514, 0}},
	subtitles = {16898736967, {256, 256}, {257, 257}},
	sun = {16898787671, {256, 256}, {0, 0}},
	["sun-dim"] = {16898736967, {256, 256}, {0, 514}},
	["sun-medium"] = {16898736967, {256, 256}, {514, 257}},
	sunrise = {16898787671, {256, 256}, {257, 0}},
	superscript = {16898787671, {256, 256}, {514, 0}},
	["swiss-franc"] = {16898787671, {256, 256}, {0, 514}},
	["switch-camera"] = {16898787671, {256, 256}, {514, 257}},
	swords = {16898787671, {256, 256}, {514, 514}},
	table = {16898787819, {256, 256}, {257, 514}},
	["table-2"] = {16898787819, {256, 256}, {257, 0}},
	["table-cells-split"] = {16898787819, {256, 256}, {514, 0}},
	["table-properties"] = {16898787819, {256, 256}, {0, 514}},
	["table-rows-split"] = {16898787819, {256, 256}, {514, 257}},
	tablet = {16898788033, {256, 256}, {0, 0}},
	tablets = {16898788033, {256, 256}, {257, 0}},
	tags = {16898788033, {256, 256}, {514, 0}},
	["tally-1"] = {16898788033, {256, 256}, {257, 257}},
	["tally-2"] = {16898788033, {256, 256}, {0, 514}},
	["tally-3"] = {16898788033, {256, 256}, {514, 257}},
	["tally-4"] = {16898788033, {256, 256}, {257, 514}},
	["tally-5"] = {16898788033, {256, 256}, {514, 514}},
	target = {16898788248, {256, 256}, {257, 0}},
	tent = {16898788248, {256, 256}, {257, 257}},
	["terminal-square"] = {16898788248, {256, 256}, {0, 514}},
	["text-cursor-input"] = {16898788479, {256, 256}, {0, 257}},
	["text-quote"] = {16898788479, {256, 256}, {257, 257}},
	theater = {16898788479, {256, 256}, {514, 514}},
	thermometer = {16898788660, {256, 256}, {0, 257}},
	["thumbs-down"] = {16898788660, {256, 256}, {514, 0}},
	ticket = {16898788789, {256, 256}, {0, 257}},
	["ticket-minus"] = {16898788660, {256, 256}, {514, 257}},
	["ticket-slash"] = {16898788789, {256, 256}, {0, 0}},
	["timer-off"] = {16898788789, {256, 256}, {514, 0}},
	["timer-reset"] = {16898788789, {256, 256}, {257, 257}},
	["toggle-right"] = {16898788789, {256, 256}, {257, 514}},
	touchpad = {16898788908, {256, 256}, {0, 257}},
	["touchpad-off"] = {16898788908, {256, 256}, {257, 0}},
	tractor = {16898788908, {256, 256}, {0, 514}},
	["train-front"] = {16898788908, {256, 256}, {514, 514}},
	["train-front-tunnel"] = {16898788908, {256, 256}, {257, 514}},
	["train-track"] = {16898789012, {256, 256}, {0, 0}},
	["tram-front"] = {16898789012, {256, 256}, {257, 0}},
	trash = {16898789012, {256, 256}, {514, 0}},
	["trash-2"] = {16898789012, {256, 256}, {0, 257}},
	["tree-deciduous"] = {16898789012, {256, 256}, {257, 257}},
	["tree-palm"] = {16898789012, {256, 256}, {0, 514}},
	["tree-pine"] = {16898789012, {256, 256}, {514, 257}},
	trees = {16898789012, {256, 256}, {257, 514}},
	trello = {16898789012, {256, 256}, {514, 514}},
	["trending-up"] = {16898789153, {256, 256}, {257, 0}},
	["triangle-alert"] = {16898789153, {256, 256}, {0, 257}},
	["triangle-right"] = {16898789153, {256, 256}, {514, 0}},
	truck = {16898789153, {256, 256}, {514, 257}},
	turtle = {16898789153, {256, 256}, {257, 514}},
	tv = {16898789303, {256, 256}, {0, 0}},
	["tv-2"] = {16898789153, {256, 256}, {514, 514}},
	twitch = {16898789303, {256, 256}, {257, 0}},
	type = {16898789303, {256, 256}, {514, 0}},
	umbrella = {16898789303, {256, 256}, {0, 514}},
	["umbrella-off"] = {16898789303, {256, 256}, {257, 257}},
	underline = {16898789303, {256, 256}, {514, 257}},
	["undo-2"] = {16898789303, {256, 256}, {257, 514}},
	["unfold-vertical"] = {16898789451, {256, 256}, {0, 257}},
	university = {16898789451, {256, 256}, {257, 257}},
	unlink = {16898789451, {256, 256}, {514, 257}},
	["unlink-2"] = {16898789451, {256, 256}, {0, 514}},
	unplug = {16898789644, {256, 256}, {0, 0}},
	usb = {16898789644, {256, 256}, {514, 0}},
	user = {16898790259, {256, 256}, {0, 0}},
	["user-2"] = {16898789644, {256, 256}, {257, 257}},
	["user-check"] = {16898789644, {256, 256}, {514, 257}},
	["user-check-2"] = {16898789644, {256, 256}, {0, 514}},
	["user-circle"] = {16898789644, {256, 256}, {514, 514}},
	["user-cog-2"] = {16898789825, {256, 256}, {0, 0}},
	["user-minus-2"] = {16898789825, {256, 256}, {0, 257}},
	["user-plus"] = {16898789825, {256, 256}, {0, 514}},
	["user-round-check"] = {16898789825, {256, 256}, {514, 257}},
	["user-round-minus"] = {16898789825, {256, 256}, {514, 514}},
	["user-round-plus"] = {16898790047, {256, 256}, {0, 0}},
	["user-round-x"] = {16898790047, {256, 256}, {0, 257}},
	["user-square"] = {16898790047, {256, 256}, {514, 257}},
	["user-x"] = {16898790047, {256, 256}, {514, 514}},
	users = {16898790259, {256, 256}, {514, 0}},
	["users-round"] = {16898790259, {256, 256}, {0, 257}},
	utensils = {16898790259, {256, 256}, {0, 514}},
	["utensils-crossed"] = {16898790259, {256, 256}, {257, 257}},
	["utility-pole"] = {16898790259, {256, 256}, {514, 257}},
	variable = {16898790259, {256, 256}, {257, 514}},
	vault = {16898790259, {256, 256}, {514, 514}},
	["venetian-mask"] = {16898790439, {256, 256}, {257, 0}},
	["video-off"] = {16898790439, {256, 256}, {257, 257}},
	videotape = {16898790439, {256, 256}, {514, 257}},
	view = {16898790439, {256, 256}, {257, 514}},
	volume = {16898790615, {256, 256}, {514, 0}},
	vote = {16898790615, {256, 256}, {257, 257}},
	wallet = {16898790615, {256, 256}, {514, 514}},
	["wallet-2"] = {16898790615, {256, 256}, {0, 514}},
	["wallet-cards"] = {16898790615, {256, 256}, {514, 257}},
	["wallet-minimal"] = {16898790615, {256, 256}, {257, 514}},
	wand = {16898790791, {256, 256}, {514, 0}},
	warehouse = {16898790791, {256, 256}, {257, 257}},
	waves = {16898790791, {256, 256}, {257, 514}},
	webhook = {16898790996, {256, 256}, {0, 257}},
	weight = {16898790996, {256, 256}, {514, 0}},
	wheat = {16898790996, {256, 256}, {0, 514}},
	["wheat-off"] = {16898790996, {256, 256}, {257, 257}},
	wifi = {16898790996, {256, 256}, {514, 514}},
	wine = {16898791187, {256, 256}, {0, 257}},
	workflow = {16898791187, {256, 256}, {514, 0}},
	worm = {16898791187, {256, 256}, {257, 257}},
	x = {16898791349, {256, 256}, {257, 0}},
	["x-octagon"] = {16898791187, {256, 256}, {514, 514}},
	["x-square"] = {16898791349, {256, 256}, {0, 0}},
	youtube = {16898791349, {256, 256}, {0, 257}},
	["zoom-in"] = {16898791349, {256, 256}, {0, 514}},
}


-- ===== ÍCONES LUCIDE: funções =====
function GGUI:GetIcon(name)
	local key = tostring(name):lower():gsub("[%s_]", "-")
	local e = LUCIDE_ICONS[key]
	if not e then
		return nil
	end
	return {
		Image = "rbxassetid://" .. e[1],
		ImageRectSize = Vector2.new(e[2][1], e[2][2]),
		ImageRectOffset = Vector2.new(e[3][1], e[3][2]),
	}
end

function GGUI:GetIconByName(name)
	return GGUI:GetIcon(name)
end

function GGUI:IconImage(parent, name, size)
	local ic = GGUI:GetIcon(name)
	if not ic then
		warn("[GGUI] ícone não encontrado: " .. tostring(name))
		return nil
	end
	return new("ImageLabel", {
		Size = UDim2.fromOffset(size or 16, size or 16),
		BackgroundTransparency = 1,
		Image = ic.Image,
		ImageRectSize = ic.ImageRectSize,
		ImageRectOffset = ic.ImageRectOffset,
		ImageColor3 = T("Icons"),
		ScaleType = Enum.ScaleType.Fit,
	}, parent)
end

return GGUI
