

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
	{ nome = "Black", arquivo = "black.jpg" },
	{ nome = "Miku Code", arquivo = "mikucode.jpg" },
	{ nome = "Branco", arquivo = "branco.jpg" },
	{ nome = "Hollow", arquivo = "hollow.jpg" },
	{ nome = "Miku Mine", arquivo = "mikumine.jpg" },
	{ nome = "Re:Zero", arquivo = "rezero.jpg" },
	{ nome = "Dragon Ball", arquivo = "dragonball.jpg" },
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
	Background = "Black",
	TabsW = 160,
	W = DEFAULT_W,
	H = DEFAULT_H,
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
			target.Position = target.Position:Lerp(goal, 0.5)
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
	win.Scale = new("UIScale", {}, win.Main)
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
		Size = UDim2.new(1, 0, 0, h or 44),
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
	local f = self:_row(34)
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

	local f = self:_row(desc and 52 or 44)
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
	local f = self:_row(40)
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

	local f = self:_row(44)
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

	local f = self:_row(54)
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
	-- posições: 1 nome, 2 opções, 3 padrão, 4 callback, 5 flag
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
		Size = UDim2.new(1, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Dropdown")
	box.BackgroundTransparency = 0.25
	corner(box, 6)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, box)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, box)

	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 1,
	}, box)
	local t = label(head, {
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = tostring(name),
	}, "Text")
	local val = label(head, {
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.5, -30, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
		Text = "...",
	}, "TextDark")
	local arrow = reg(new("ImageLabel", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICONS.Open,
	}, head), "ImageColor3", "Icons")

	local body = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
	}, box)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, body)

	-- pesquisa dentro do dropdown
	local search = reg(new("TextBox", {
		Size = UDim2.new(1, 0, 0, 26),
		Text = "",
		PlaceholderText = "Pesquisar...",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		ClearTextOnFocus = false,
		LayoutOrder = 0,
	}, body), "BackgroundColor3", "Stroke")
	reg(search, "TextColor3", "Text")
	corner(search, 4)

	local dd = setmetatable({ Frame = box, Tab = self, Window = win, _title = t, _cbs = cb and { cb } or {} }, Comp)
	dd.Options = {}
	dd.Value = nil
	dd._enabled = true

	local buttons, order, selected = {}, {}, {}

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
				body.Visible = false
				tween(arrow, { Rotation = 0 }, TIME.Drop)
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
		body.Visible = not body.Visible
		tween(arrow, { Rotation = body.Visible and 180 or 0 }, TIME.Drop)
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

	-- callback na criação (como a Gold)
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

return GGUIText = "",
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

return GGUIwns[1] then
		teleport(q.spawns[1] + Vector3.new(0, 25, 0))
	end
end })

Library:Section(Travel, "Sea")
Library:Button(Travel, { Name = "Ir para Sea 2 (via portal)", Callback = function()
	pcall(function()
		CommF:InvokeServer("TravelDressrosa")
	end)
end })
Library:Button(Travel, { Name = "Ir para Sea 3 (via portal)", Callback = function()
	pcall(function()
		CommF:InvokeServer("TravelZou")
	end)
end })

-- VISUAL
Library:Section(Visual, "ESP")
Library:Toggle(Visual, { Name = "ESP Fruta", Flag = "EspFruit", Default = Library:Flag("EspFruit", false) })
Library:Toggle(Visual, { Name = "ESP Baú", Flag = "EspChest", Default = Library:Flag("EspChest", false) })
Library:Toggle(Visual, { Name = "ESP Boss", Flag = "EspBoss", Default = Library:Flag("EspBoss", false) })
Library:Toggle(Visual, { Name = "ESP Jogador", Flag = "EspPlayer", Default = Library:Flag("EspPlayer", false) })
Library:Toggle(Visual, { Name = "Notificador de Fruta", Description = "Avisa fruta no servidor", Flag = "FruitNotify", Default = Library:Flag("FruitNotify", false) })

Library:Section(Visual, "Cena")
Library:Toggle(Visual, { Name = "Fullbright", Flag = "Fullbright", Default = Library:Flag("Fullbright", false) })
Library:Toggle(Visual, { Name = "Sem neblina", Flag = "NoFog", Default = Library:Flag("NoFog", false) })
Library:Toggle(Visual, { Name = "FPS Boost", Description = "Remove sombras globais", Flag = "FpsBoost", Default = Library:Flag("FpsBoost", false) })

-- DIVERSOS
Library:Section(Misc, "Jogador")
Library:Slider(Misc, { Name = "WalkSpeed", Min = 16, Max = 400, Default = Library:Flag("WalkSpeed", 16), Increment = 1, Flag = "WalkSpeed" })
Library:Slider(Misc, { Name = "JumpPower", Min = 50, Max = 400, Default = Library:Flag("JumpPower", 50), Increment = 1, Flag = "JumpPower" })
Library:Slider(Misc, { Name = "Tween Speed", Min = 100, Max = 900, Default = Library:Flag("TweenSpeed", 360), Increment = 10, Flag = "TweenSpeed" })
Library:Toggle(Misc, { Name = "Fly", Flag = "Fly", Default = Library:Flag("Fly", false) })
Library:Toggle(Misc, { Name = "NoClip", Flag = "Noclip", Default = Library:Flag("Noclip", false) })
Library:Toggle(Misc, { Name = "Pulo infinito", Flag = "InfJump", Default = Library:Flag("InfJump", false) })
Library:Toggle(Misc, { Name = "Anti-AFK", Flag = "AntiAfk", Default = Library:Flag("AntiAfk", true) })

Library:Section(Misc, "Servidor")
Library:Toggle(Misc, { Name = "Auto Rejoin", Flag = "AutoRejoin", Default = Library:Flag("AutoRejoin", false) })
Library:Button(Misc, { Name = "Rejoin", Callback = function()
	pcall(function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
end })
Library:Button(Misc, { Name = "Servidor novo", Callback = function()
	pcall(function()
		local ok, res = pcall(function()
			return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		end)
		if ok then
			for _, srv in ipairs(res.data or {}) do
				if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
					return
				end
			end
		end
		notify("Servidor", "Nenhum servidor livre.")
	end)
end })

-- CONFIG
Library:Section(Config, "Interface")
Library:Dropdown(Config, { Name = "Tema", Options = { "Noir", "Abyss", "Bloom", "Jade" }, Default = Library.ThemeName, Callback = function(v)
	Library:SetTheme(v)
end })
Library:Slider(Config, { Name = "Escala", Min = 0.7, Max = 1.3, Default = 1, Increment = 0.05, Callback = function(v)
	Library:SetScale(v)
end })
Library:Paragraph(Config, "Esconder UI", "RightShift")

Library:Section(Config, "Configurações salvas")
local currentSlot = "principal"
Library:TextBox(Config, { Name = "Slot", Placeholder = "nome", Default = "principal", Callback = function(v)
	if v and v ~= "" then
		currentSlot = v
	end
end })
Library:Button(Config, { Name = "Salvar config", Callback = function()
	Library:Save(currentSlot)
	notify("Config", "Salvo em '" .. currentSlot .. "'.")
end })
Library:Button(Config, { Name = "Carregar config", Callback = function()
	if Library:Load(currentSlot) then
		notify("Config", "Carregado. Reabra o hub.")
	else
		notify("Config", "Slot vazio.")
	end
end })

Library:Section(Config, "Sessão")
Library:Button(Config, { Name = "Descarregar hub", Callback = function()
	Library:Destroy()
end })

--=====================================================================
--  LOOPS
--=====================================================================
task.spawn(function()
	while task.wait(0.1) and not Library.Destroyed do
		if Library.Flags.FastAttack then
			pcall(function()
				equipType(Library.Flags.WeaponType)
				if Library.Flags.MobAura then
					attack(Library.Flags.AuraRange)
					if Library.Flags.MultiHit then
						attack(Library.Flags.AuraRange)
					end
				end
			end)
			task.wait((Library.Flags.AttackDelay or 0) / 1000)
		end
	end
end)

task.spawn(function()
	local last = 0
	while task.wait(0.2) and not Library.Destroyed do
		if Library.Flags.AutoSkills and os.clock() - last >= (Library.Flags.SkillDelay or 1) then
			last = os.clock()
			pcall(function()
				for _, key in ipairs({ "Z", "X", "C", "V" }) do
					VirtualInputManager:SendKeyEvent(true, key, false, game)
					VirtualInputManager:SendKeyEvent(false, key, false, game)
					task.wait(0.08)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.35) and not Library.Destroyed do
		if Library.Flags.BringMob and (Library.Flags.AutoFarm or Library.Flags.AutoBoss or Library.Flags.AutoBone or Library.Flags.AutoMaterial or Library.Flags.AutoElite) then
			pcall(bringMobs)
		end
	end
end)

task.spawn(function()
	while task.wait(0.4) and not Library.Destroyed do
		pcall(function()
			if Library.Flags.AutoBuso then
				local char = getChar()
				if char and not char:FindFirstChild("HasBuso") then
					CommF:InvokeServer("Buso")
				end
			end
			if Library.Flags.AutoKen then
				CommE:FireServer("Ken", true)
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.8) and not Library.Destroyed do
		pcall(function()
			local char = getChar()
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = Library.Flags.WalkSpeed or 16
				hum.UseJumpPower = true
				hum.JumpPower = Library.Flags.JumpPower or 50
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.45) and not Library.Destroyed do
		if not Library.Flags.AutoFarm then
			continue
		end
		pcall(function()
			local char, hrp = getChar()
			if not hrp then
				return
			end
			local q = resolveQuest()
			if not q then
				return
			end
			local visible, text = questText()
			if visible then
				if q.mob ~= "" and not string.find(text, q.mob) then
					CommF:InvokeServer("AbandonQuest")
					return
				end
				local enemies = Workspace:FindFirstChild("Enemies")
				local target = enemies and (enemies:FindFirstChild(q.display) or enemies:FindFirstChild(q.mob))
				if target then
					killMob(target)
				elseif q.spawns[1] then
					teleport(q.spawns[1] + Vector3.new(0, 25, 0))
				end
			else
				if (q.npc.Position - hrp.Position).Magnitude > (Library.Flags.FarmDistance or 25) then
					teleport(q.npc, Library.Flags.TweenSpeed)
				else
					CommF:InvokeServer("StartQuest", q.quest, q.level)
					task.wait(0.6)
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.4) and not Library.Destroyed do
		if not Library.Flags.AutoBoss then
			continue
		end
		pcall(function()
			local boss = Library.Flags.BossSelect
			if not boss or boss == "" then
				return
			end
			local enemies = Workspace:FindFirstChild("Enemies")
			local target = enemies and enemies:FindFirstChild(boss)
			if target and target:FindFirstChild("HumanoidRootPart") and target.Humanoid.Health > 0 then
				killMob(target, CFrame.new(0, 30, 10))
			else
				local tpl = ReplicatedStorage:FindFirstChild(boss)
				if tpl and tpl:FindFirstChild("HumanoidRootPart") then
					teleport(tpl.HumanoidRootPart.CFrame * CFrame.new(5, 15, 5), Library.Flags.TweenSpeed)
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.4) and not Library.Destroyed do
		if not Library.Flags.AutoMaterial then
			continue
		end
		pcall(function()
			local mobName = Library.Flags.MaterialMob
			if not mobName or mobName == "" then
				return
			end
			local enemies = Workspace:FindFirstChild("Enemies")
			local target = enemies and enemies:FindFirstChild(mobName)
			if target and target:FindFirstChild("HumanoidRootPart") then
				killMob(target)
			else
				local pts = spawnPoints(mobName)
				if pts[1] then
					teleport(pts[1] + Vector3.new(0, 25, 0), Library.Flags.TweenSpeed)
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.35) and not Library.Destroyed do
		if not Library.Flags.AutoChest then
			continue
		end
		pcall(function()
			local char, hrp = getChar()
			if not hrp then
				return
			end
			local best, bestDist
			for _, chest in ipairs(CollectionService:GetTagged("_ChestTagged")) do
				if chest.Parent and not State.SeenChest[chest] and not chest:GetAttribute("IsDisabled") then
					local ok, pos = pcall(function()
						return chest:GetPivot().Position
					end)
					if ok then
						local d = (pos - hrp.Position).Magnitude
						if not bestDist or d < bestDist then
							best, bestDist = chest, d
						end
					end
				end
			end
			if not best then
				return
			end
			local pos = best:GetPivot().Position
			if bestDist > 12 then
				teleport(CFrame.new(pos + Vector3.new(0, 3, 0)), 620)
			else
				if firetouchinterest then
					firetouchinterest(hrp, best, 0)
					task.wait(0.05)
					firetouchinterest(hrp, best, 1)
				end
				State.SeenChest[best] = true
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.4) and not Library.Destroyed do
		if not Library.Flags.AutoFruit then
			continue
		end
		pcall(function()
			local char, hrp = getChar()
			if not hrp then
				return
			end
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
					local pos = obj.Handle.Position
					if (pos - hrp.Position).Magnitude > 12 then
						teleport(CFrame.new(pos + Vector3.new(0, 4, 0)), 700)
					elseif firetouchinterest then
						firetouchinterest(hrp, obj.Handle, 0)
						task.wait(0.05)
						firetouchinterest(hrp, obj.Handle, 1)
					end
					break
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.45) and not Library.Destroyed do
		if not Library.Flags.AutoBone then
			continue
		end
		pcall(function()
			local char, hrp = getChar()
			if not hrp then
				return
			end
			local enemies = Workspace:FindFirstChild("Enemies")
			if enemies then
				for _, n in ipairs({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }) do
					local m = enemies:FindFirstChild(n)
					if m and m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 then
						killMob(m)
						return
					end
				end
			end
			teleport(CFrame.new(-9516.99, 172.01, 6078.46), Library.Flags.TweenSpeed)
		end)
	end
end)

task.spawn(function()
	while task.wait(0.5) and not Library.Destroyed do
		if not Library.Flags.AutoElite then
			continue
		end
		pcall(function()
			local enemies = Workspace:FindFirstChild("Enemies")
			if not enemies then
				return
			end
			for _, mob in ipairs(enemies:GetChildren()) do
				if string.find(mob.Name, "Elite") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
					killMob(mob)
					return
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.4) and not Library.Destroyed do
		if not Library.Flags.AutoSword then
			continue
		end
		pcall(function()
			local entry
			for _, e in ipairs(QD.Sword) do
				if e.name == Library.Flags.SwordTarget then
					entry = e
					break
				end
			end
			if not entry then
				return
			end
			if not killBossLoop(entry.boss) then
				teleport(entry.npc, Library.Flags.TweenSpeed)
			end
			local _, hrp = getChar()
			if hrp then
				for _, obj in ipairs(Workspace:GetChildren()) do
					if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
						if (obj.Handle.Position - hrp.Position).Magnitude < 20 and firetouchinterest then
							firetouchinterest(hrp, obj.Handle, 0)
							task.wait(0.05)
							firetouchinterest(hrp, obj.Handle, 1)
						end
					end
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.4) and not Library.Destroyed do
		if not Library.Flags.AutoItem then
			continue
		end
		pcall(function()
			local _, hrp = getChar()
			if not hrp then
				return
			end
			local best, bestDist
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
					local d = (obj.Handle.Position - hrp.Position).Magnitude
					if not bestDist or d < bestDist then
						best, bestDist = obj, d
					end
				end
			end
			if not best then
				return
			end
			if bestDist > 10 then
				teleport(CFrame.new(best.Handle.Position + Vector3.new(0, 4, 0)), 700)
			elseif firetouchinterest then
				firetouchinterest(hrp, best.Handle, 0)
				task.wait(0.05)
				firetouchinterest(hrp, best.Handle, 1)
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(1) and not Library.Destroyed do
		if not Library.Flags.AutoStartRaid then
			continue
		end
		pcall(function()
			if raidActive() then
				return
			end
			if not chipInBackpack() then
				if Library.Flags.AutoBuyChip then
					buyChip(Library.Flags.RaidChip)
				end
				return
			end
			local chip = chipInBackpack()
			startRaid(chip and chip.Name or Library.Flags.RaidChip, Library.Flags.RaidIsland)
		end)
	end
end)

task.spawn(function()
	while task.wait(0.35) and not Library.Destroyed do
		if not Library.Flags.AutoClearRaid then
			continue
		end
		pcall(function()
			if not raidActive() then
				if Library.Flags.AutoLeaveRaid and not chipInBackpack() then
					pcall(function()
						CommF:InvokeServer("RaidsInfo", "Leave")
					end)
				end
				return
			end
			local target = raidTarget()
			if target then
				killMob(target, CFrame.new(0, 28, 8))
			else
				local origin = Workspace:FindFirstChild("_WorldOrigin")
				local island = origin and origin:FindFirstChild("RaidIsland")
				if island and island:IsA("BasePart") then
					teleport(island.CFrame + Vector3.new(0, 30, 0), Library.Flags.TweenSpeed)
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(1) and not Library.Destroyed do
		if not Library.Flags.AutoStats then
			continue
		end
		pcall(function()
			local data = LocalPlayer:FindFirstChild("Data")
			local points = data and data:FindFirstChild("Points")
			if points and points.Value > 0 then
				for _, statName in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
					if Library.Flags["Stat_" .. statName] and points.Value > 0 then
						CommF:InvokeServer("AddPoint", statName, 1)
						break
					end
				end
			end
		end)
	end
end)

-- fly
task.spawn(function()
	local bv, bg
	local function stopFly()
		if bv then
			bv:Destroy()
			bv = nil
		end
		if bg then
			bg:Destroy()
			bg = nil
		end
	end
	while task.wait(0.2) and not Library.Destroyed do
		local char, hrp = getChar()
		if Library.Flags.Fly and hrp then
			if not bv then
				bv = new("BodyVelocity", { MaxForce = Vector3.new(1, 1, 1) * 1e5, Parent = hrp })
				bg = new("BodyGyro", { MaxTorque = Vector3.new(1, 1, 1) * 1e5, P = 1200, D = 60, Parent = hrp })
			end
			local cam = Workspace.CurrentCamera
			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then
				dir += cam.CFrame.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.S) then
				dir -= cam.CFrame.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.A) then
				dir -= cam.CFrame.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) then
				dir += cam.CFrame.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then
				dir += Vector3.yAxis
			end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
				dir -= Vector3.yAxis
			end
			bv.Velocity = dir.Magnitude > 0 and dir.Unit * (Library.Flags.WalkSpeed or 16) * 3 or Vector3.zero
			bg.CFrame = cam.CFrame
		elseif bv then
			stopFly()
		end
	end
end)

-- utilidades
connect(UIS.JumpRequest, function()
	if Library.Flags.InfJump then
		local char = getChar()
		if char and char:FindFirstChildOfClass("Humanoid") then
			char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

connect(RunService.Stepped, function()
	if not Library.Flags.Noclip then
		return
	end
	local char = getChar()
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

connect(LocalPlayer.Idled, function()
	if not Library.Flags.AntiAfk then
		return
	end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
	while task.wait(1) and not Library.Destroyed do
		pcall(function()
			Lighting.FogEnd = Library.Flags.NoFog and 1e6 or 100000
			Lighting.Brightness = Library.Flags.Fullbright and 3 or 2
			Lighting.Ambient = Library.Flags.Fullbright and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(70, 70, 70)
			if Library.Flags.Fullbright then
				Lighting.ClockTime = 12
			end
			if Library.Flags.FpsBoost then
				Lighting.GlobalShadows = false
			end
		end)
	end
end)

-- ESP
local function addEsp(obj, text, color)
	if obj:FindFirstChild("VeniceEsp") then
		return
	end
	local bb = new("BillboardGui", {
		Name = "VeniceEsp",
		Size = UDim2.fromOffset(150, 24),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		Parent = obj,
	})
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextStrokeTransparency = 0.3,
		TextColor3 = color or Color3.fromRGB(120, 255, 200),
		Text = text,
		Parent = bb,
	})
end

task.spawn(function()
	while task.wait(1) and not Library.Destroyed do
		pcall(function()
			local _, hrp = getChar()
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj.Name == "VeniceEsp" then
					obj:Destroy()
				end
			end
			if not hrp then
				return
			end
			if Library.Flags.EspFruit or Library.Flags.EspItem then
				for _, obj in ipairs(Workspace:GetChildren()) do
					if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
						addEsp(obj.Handle, obj.Name .. " [" .. math.floor((obj.Handle.Position - hrp.Position).Magnitude / 3) .. "m]", Color3.fromRGB(255, 200, 90))
					end
				end
			end
			if Library.Flags.EspChest then
				for _, chest in ipairs(CollectionService:GetTagged("_ChestTagged")) do
					if chest.Parent then
						addEsp(chest, "BAU", Color3.fromRGB(120, 255, 200))
					end
				end
			end
			if Library.Flags.EspBoss then
				local enemies = Workspace:FindFirstChild("Enemies")
				for _, mob in ipairs(enemies and enemies:GetChildren() or {}) do
					if mob:FindFirstChild("HumanoidRootPart") and not string.find(mob.Name, "%[Lv") then
						addEsp(mob.HumanoidRootPart, mob.Name, Color3.fromRGB(255, 90, 90))
					end
				end
			end
			if Library.Flags.EspPlayer then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						addEsp(plr.Character.HumanoidRootPart, plr.Name, Color3.fromRGB(150, 200, 255))
					end
				end
			end
		end)
	end
end)

-- notificador de fruta
task.spawn(function()
	while task.wait(2) and not Library.Destroyed do
		if not Library.Flags.FruitNotify then
			continue
		end
		pcall(function()
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj:IsA("Tool") and obj:FindFirstChild("Handle") and not State.Bought[obj] then
					State.Bought[obj] = true
					local pos = obj.Handle.Position
					notify("Fruta encontrada", string.format("%s em (%.0f, %.0f, %.0f)", obj.Name, pos.X, pos.Y, pos.Z))
				end
			end
		end)
	end
end)

-- auto rejoin
task.spawn(function()
	while task.wait(2) and not Library.Destroyed do
		if Library.Flags.AutoRejoin and not LocalPlayer.Parent then
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end
	end
end)

Library:Notify({ Title = "Venice Hub v2.1", Content = "Carregado · Sea " .. SEA .. " · RightShift esconde a UI", Duration = 6 })