
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local GGUI = {}
GGUI.Windows = {}
GGUI.Paints = {}
GGUI.CurrentTheme = "Darker"
GGUI.ThemeOrder = { "Darker", "Rosa Suave", "Azul Suave", "Vermelho Carmesim" }

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

-- ===== CONFIGURAÇÕES =====
local REPO = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/main/assets/"

local DEFAULT_BACKGROUNDS = {
	{ nome = "Black", arquivo = "black.jpg", tom = Color3.new(0,0,0) },
	{ nome = "Miku Code", arquivo = "mikucode.jpg", tom = Color3.fromRGB(20,10,40) },
	{ nome = "Branco", arquivo = "branco.jpg", tom = Color3.fromRGB(10,30,70) },
	{ nome = "Hollow", arquivo = "hollow.jpg", tom = Color3.fromRGB(10,30,70) },
	{ nome = "Miku Mine", arquivo = "mikumine.jpg", tom = Color3.fromRGB(40,20,60) },
	{ nome = "Re:Zero", arquivo = "rezero.jpg", tom = Color3.new(1,1,1) },
	{ nome = "Dragon Ball", arquivo = "dragonball.jpg", tom = Color3.new(0,0,0) },
}

GGUI.Themes = {
	["Darker"] = {
		Background = Color3.fromRGB(25,25,25),
		Element = Color3.fromRGB(36,36,38),
		Stroke = Color3.fromRGB(55,55,58),
		Primary = Color3.fromRGB(88,101,242),
		Text = Color3.fromRGB(255,255,255),
		TextDark = Color3.fromRGB(200,200,200),
	},
	["Rosa Suave"] = {
		Background = Color3.fromRGB(40,28,36),
		Element = Color3.fromRGB(56,39,50),
		Stroke = Color3.fromRGB(96,66,84),
		Primary = Color3.fromRGB(255,150,190),
		Text = Color3.fromRGB(255,246,250),
		TextDark = Color3.fromRGB(230,200,216),
	},
	["Azul Suave"] = {
		Background = Color3.fromRGB(24,31,44),
		Element = Color3.fromRGB(35,44,62),
		Stroke = Color3.fromRGB(66,84,112),
		Primary = Color3.fromRGB(120,180,255),
		Text = Color3.fromRGB(240,248,255),
		TextDark = Color3.fromRGB(190,210,235),
	},
	["Vermelho Carmesim"] = {
		Background = Color3.fromRGB(30,18,20),
		Element = Color3.fromRGB(46,26,30),
		Stroke = Color3.fromRGB(96,30,42),
		Primary = Color3.fromRGB(190,20,50),
		Text = Color3.fromRGB(255,240,242),
		TextDark = Color3.fromRGB(222,190,196),
	},
}

local ICON_CLOSE = "rbxassetid://10747384394"
local ICON_MIN = "rbxassetid://10734896206"
local ICON_OPEN = "rbxassetid://10709791523"
local ICON_CLOSED = "rbxassetid://10709790948"

-- ===== TEMA =====
local function T(role)
	local t = GGUI.Themes[GGUI.CurrentTheme] or GGUI.Themes.Darker
	return t[role] or t.Text
end

-- ===== HELPERS =====
local function create(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

-- Registra a propriedade para trocar de cor quando o tema mudar
local function paint(obj, prop, role)
	obj[prop] = T(role)
	table.insert(GGUI.Paints, { obj = obj, prop = prop, role = role })
	return obj
end

local function round(obj, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, obj)
end

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quint), props):Play()
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
	local l = create("TextLabel", p, parent)
	paint(l, "TextColor3", role or "Text")
	return l
end

local function draggable(handle, target)
	local dragging, startInput, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local function titles(f, name, desc, pad)
	pad = pad or 70
	label(f, {
		Position = desc and UDim2.fromOffset(10, 7) or UDim2.fromOffset(10, 0),
		Size = desc and UDim2.new(1, -pad, 0, 18) or UDim2.new(1, -pad, 1, 0),
		Text = tostring(name),
	}, "Text")
	if desc then
		label(f, {
			Position = UDim2.fromOffset(10, 26),
			Size = UDim2.new(1, -pad, 0, 16),
			Text = tostring(desc),
			TextSize = 11,
		}, "TextDark")
	end
end

-- ===== LIBRARY =====
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
	win.Refreshers = {}
	win.Minimized = false
	win.TomOpacity = 5

	-- carrega flags salvas
	if win.ScriptFolder and isfile and readfile then
		local path = win.ScriptFolder .. "/Flags.json"
		if isfile(path) then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(readfile(path))
			end)
			if ok and type(data) == "table" then
				win.Flags = data
			end
		end
	end

	-- tema salvo na aba Config (flag "UiTheme")
	if type(win.Flags["UiTheme"]) == "string" and GGUI.Themes[win.Flags["UiTheme"]] then
		GGUI.CurrentTheme = win.Flags["UiTheme"]
	end

	local parent = (gethui and gethui()) or CoreGui
	local old = parent:FindFirstChild("GGUI")
	if old then
		old:Destroy()
	end
	win.Screen = create("ScreenGui", {
		Name = "GGUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, parent)

	local size = cfg.Size or UDim2.fromOffset(620, 420)
	win.Main = paint(create("Frame", {
		Name = "Main",
		Size = size,
		Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
		BackgroundTransparency = 0.03,
		Active = true,
		ClipsDescendants = true,
	}, win.Screen), "BackgroundColor3", "Background")
	round(win.Main, 8)
	win.Scale = create("UIScale", {}, win.Main)

	-- fundo (atrás de tudo) + camada escura
	win.BgImage = create("ImageLabel", {
		Name = "Fundo",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		Visible = false,
	}, win.Main)
	round(win.BgImage, 8)
	win.Tom = create("Frame", {
		Name = "Tom",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.95,
		ZIndex = 0,
	}, win.BgImage)
	round(win.Tom, 8)

	-- barra superior
	win.TopBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Active = true,
	}, win.Main)
	label(win.TopBar, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Text = win.Title,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
	}, "Text")
	label(win.TopBar, {
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0.3, 0, 1, 0),
		Text = win.SubTitle,
		TextSize = 10,
	}, "TextDark")

	local closeBtn = create("ImageButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICON_CLOSE,
		AutoButtonColor = false,
	}, win.TopBar)
	paint(closeBtn, "ImageColor3", "Text")
	local minBtn = create("ImageButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -38, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICON_MIN,
		AutoButtonColor = false,
	}, win.TopBar)
	paint(minBtn, "ImageColor3", "Text")
	minBtn.Activated:Connect(function()
		win:Minimize()
	end)
	closeBtn.Activated:Connect(function()
		win:Destroy()
	end)
	draggable(win.TopBar, win.Main)

	-- sidebar e conteúdo
	win.Sidebar = create("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(8, 42),
		Size = UDim2.new(0, 170, 1, -50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, win.Main)
	create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, win.Sidebar)

	win.Content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(186, 42),
		Size = UDim2.new(1, -194, 1, -50),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, win.Main)

	-- quadrado minimizado
	win.Square = paint(create("ImageButton", {
		Name = "Minimizado",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.fromScale(0.17, 0.28),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
	}, win.Screen), "BackgroundColor3", "Element")
	round(win.Square, 8)
	win.Square.Activated:Connect(function()
		win:Minimize()
	end)
	draggable(win.Square, win.Square)

	-- atalho de teclado
	table.insert(win.Connections, UIS.InputBegan:Connect(function(input, gp)
		if not gp and win.KeyBind and input.KeyCode == win.KeyBind then
			win:Minimize()
		end
	end))

	table.insert(GGUI.Windows, win)
	table.insert(win.Refreshers, function()
		win:_paintTabs(false)
	end)
	win:_setupBackgroundTab()
	return win
end

function GGUI:GetThemes()
	local out = {}
	for _, n in ipairs(GGUI.ThemeOrder) do
		table.insert(out, n)
	end
	return out
end

function GGUI:SetTheme(name)
	if not GGUI.Themes[name] then
		return false
	end
	GGUI.CurrentTheme = name
	for i = #GGUI.Paints, 1, -1 do
		local p = GGUI.Paints[i]
		if p.obj and p.obj.Parent ~= nil then
			p.obj[p.prop] = T(p.role)
		else
			table.remove(GGUI.Paints, i)
		end
	end
	for _, w in ipairs(GGUI.Windows) do
		w:_refresh()
	end
	return true
end

function GGUI:SetUIScale(v)
	local w = GGUI.Windows[#GGUI.Windows]
	if w then
		w:SetUIScale(v)
	end
end

function GGUI:MakeNotify(cfg)
	local w = GGUI.Windows[#GGUI.Windows]
	if w then
		w:Notify(cfg)
	end
end

function GGUI:Destroy()
	for _, w in ipairs(GGUI.Windows) do
		w:Destroy()
	end
	GGUI.Windows = {}
end

-- ===== WINDOW =====
function Window:_refresh()
	for _, fn in ipairs(self.Refreshers) do
		pcall(fn)
	end
end

function Window:SetUIScale(v)
	self.Scale.Scale = math.clamp(v, 0.6, 1.6)
end

function Window:Minimize()
	self.Minimized = not self.Minimized
	self.Main.Visible = not self.Minimized
	self.Square.Visible = self.Minimized
end

function Window:Destroy()
	for _, c in ipairs(self.Connections) do
		c:Disconnect()
	end
	if self.Screen then
		self.Screen:Destroy()
	end
	self.Screen = nil
end

function Window:NewMinimizer(keycode)
	self.KeyBind = keycode
	local win = self
	local m = {}
	function m:CreateMobileMinimizer(props)
		for k, v in pairs(props or {}) do
			pcall(function()
				win.Square[k] = v
			end)
		end
		return win.Square
	end
	function m:SetKeyCode(k)
		win.KeyBind = k
	end
	return m
end

function Window:_save()
	if self._saving then
		return
	end
	self._saving = true
	task.delay(0.5, function()
		self._saving = false
		if self.ScriptFolder and writefile then
			pcall(function()
				if makefolder and isfolder and not isfolder(self.ScriptFolder) then
					makefolder(self.ScriptFolder)
				end
				writefile(self.ScriptFolder .. "/Flags.json", HttpService:JSONEncode(self.Flags))
			end)
		end
	end)
end

function Window:SetFlag(name, value)
	self.Flags[name] = value
	self:_save()
end

function Window:GetFlag(name)
	return self.Flags[name]
end

function Window:DeleteFlags()
	self.Flags = {}
	if self.ScriptFolder and delfile and isfile and isfile(self.ScriptFolder .. "/Flags.json") then
		pcall(delfile, self.ScriptFolder .. "/Flags.json")
	end
end

function Window:Notify(cfg)
	cfg = cfg or {}
	local title = cfg.Title or cfg.Name or cfg[1] or "Aviso"
	local content = cfg.Content or cfg.Text or cfg[2] or ""
	local duration = cfg.Duration or cfg.Time or cfg[4] or 5

	if not self.NotifyHolder then
		self.NotifyHolder = create("Frame", {
			Name = "Notify",
			Size = UDim2.new(0, 280, 1, -20),
			Position = UDim2.new(1, -290, 0, 10),
			BackgroundTransparency = 1,
		}, self.Screen)
		create("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, self.NotifyHolder)
	end

	local n = paint(create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 0.05,
		LayoutOrder = #self.NotifyHolder:GetChildren() + 1,
	}, self.NotifyHolder), "BackgroundColor3", "Background")
	round(n, 8)
	label(n, {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 18),
		Text = tostring(title),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, "Text")
	label(n, {
		Position = UDim2.fromOffset(12, 28),
		Size = UDim2.new(1, -24, 0, 26),
		Text = tostring(content),
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.None,
	}, "TextDark")
	task.delay(tonumber(duration) or 5, function()
		if n.Parent then
			n:Destroy()
		end
	end)
end

-- Caixa de confirmação: cfg.Title, cfg.Content, cfg.Options = { {Title, Callback}, ... }
function Window:Dialog(cfg)
	cfg = cfg or {}
	if self.DialogOverlay then
		self.DialogOverlay:Destroy()
	end

	local overlay = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Active = true,
	}, self.Main)
	round(overlay, 8)
	self.DialogOverlay = overlay

	local box = paint(create("Frame", {
		Size = UDim2.new(0.8, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 51,
	}, overlay), "BackgroundColor3", "Background")
	round(box, 8)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, box)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, box)

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

	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		ZIndex = 52,
		LayoutOrder = 3,
	}, box)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)

	for i, opt in ipairs(cfg.Options or {}) do
		local otitle = opt.Title or opt.Name or opt[1] or "OK"
		local ocb = opt.Callback or opt[2]
		local b = create("TextButton", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = tostring(otitle),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			AutoButtonColor = false,
			ZIndex = 52,
			LayoutOrder = i,
		}, row)
		paint(b, "BackgroundColor3", "Primary")
		paint(b, "TextColor3", "Text")
		round(b, 6)
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}, b)
		b.Activated:Connect(function()
			close()
			if ocb then
				task.spawn(ocb)
			end
		end)
	end
end

function Window:_paintTabs(animate)
	for _, t in ipairs(self.TabList) do
		local on = (t == self.Selected)
		local bg = on and T("Primary") or T("Element")
		local tr = on and 0.1 or 0.4
		if animate then
			tween(t.Button, { BackgroundColor3 = bg, BackgroundTransparency = tr }, 0.2)
		else
			t.Button.BackgroundColor3 = bg
			t.Button.BackgroundTransparency = tr
		end
	end
end

function Window:SelectTab(tab)
	if type(tab) == "number" then
		tab = self.TabList[tab]
	end
	if not tab then
		return
	end
	for _, t in ipairs(self.TabList) do
		t.Page.Visible = (t == tab)
	end
	self.Selected = tab
	self:_paintTabs(true)
end

function Window:_newTab(name, isBg)
	local order = isBg and 100000 or (#self.TabList + 1)
	local btn = paint(create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
	}, self.Sidebar), "BackgroundColor3", "Element")
	btn.BackgroundTransparency = 0.4
	round(btn, 6)
	label(btn, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = tostring(name),
		TextSize = 13,
	}, "Text")

	local page = paint(create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, self.Content), "ScrollBarImageColor3", "Primary")
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 6),
	}, page)

	local tab = setmetatable({ Window = self, Page = page, Button = btn, Order = 0, IsBg = isBg }, Tab)
	btn.Activated:Connect(function()
		self:SelectTab(tab)
	end)
	table.insert(self.TabList, tab)
	if not isBg and not self.Selected then
		self:SelectTab(tab)
	end
	return tab
end

function Window:MakeTab(cfg)
	if type(cfg) ~= "table" then
		cfg = { cfg }
	end
	local name = cfg.Title or cfg.Name or cfg[1] or "Tab"
	return self:_newTab(name, false)
end

-- ===== FUNDOS =====
function Window:ApplyBackground(name)
	local info
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
	self.Tom.BackgroundColor3 = info.tom or Color3.new(0, 0, 0)
	self.Main.BackgroundTransparency = 1
	self.Square.Image = asset
	return true
end

function Window:SetTomOpacity(pct)
	pct = math.clamp(tonumber(pct) or 5, 0, 100)
	self.TomOpacity = pct
	self.Tom.BackgroundTransparency = 1 - pct / 100
end

function Window:_setupBackgroundTab()
	if #self.Backgrounds == 0 then
		return
	end
	local tab = self:_newTab("Fundos", true)
	self.BgTab = tab
	local names = {}
	for _, b in ipairs(self.Backgrounds) do
		table.insert(names, b.nome)
	end

	tab:AddDropdown({
		Name = "Escolher fundo",
		Options = names,
		Default = names[1],
		Flag = "Fundo/Selecionado",
		Callback = function(v)
			self:ApplyBackground(v)
		end,
	})

	local slider = tab:AddSlider({
		Name = "Opacidade da camada escura",
		Min = 0,
		Max = 100,
		Increment = 1,
		Default = 5,
		Flag = "Fundo/Opacidade",
		Callback = function(v)
			self:SetTomOpacity(v)
		end,
	})
	self:SetTomOpacity(slider:Get())

	local saved = self.Flags["Fundo/Selecionado"]
	if not (type(saved) == "string" and self:ApplyBackground(saved)) then
		self:ApplyBackground(names[1])
	end
end

-- ===== TAB =====
function Tab:_row(h)
	self.Order = self.Order + 1
	local f = paint(create("Frame", {
		Size = UDim2.new(1, 0, 0, h or 44),
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	f.BackgroundTransparency = 0.25
	round(f, 6)
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
	return { SetTitle = function(_, t) l.Text = tostring(t) end }
end

function Tab:AddParagraph(title, desc)
	if type(title) == "table" then
		desc = title[2] or title.Desc or title.Description
		title = title[1] or title.Name or title.Title
	end
	self.Order = self.Order + 1
	local f = paint(create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	f.BackgroundTransparency = 0.25
	round(f, 6)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, f)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, f)
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
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTruncate = Enum.TextTruncate.None,
	}, "TextDark")
	return {
		SetTitle = function(_, v) t.Text = tostring(v) end,
		SetDescription = function(_, v) d.Text = tostring(v) end,
	}
end

function Tab:AddToggle(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Toggle"
	local desc = cfg.Description or cfg.Desc
	local flag = cfg.Flag
	local cb = cfg.Callback
	local win = self.Window

	local value = cfg.Default
	if value == nil then
		value = cfg[2] or false
	end
	-- toggles são guardados como 0 (ligado) e 1 (desligado), igual à Gold
	if flag and win.Flags[flag] ~= nil then
		value = (win.Flags[flag] == 0)
	end

	local f = self:_row(desc and 52 or 44)
	titles(f, name, desc, 70)

	local sw = create("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = T("Stroke"),
	}, f)
	round(sw, 10)
	local knob = paint(create("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
	}, sw), "BackgroundColor3", "TextDark")
	round(knob, 7)

	local function paintSw(animate)
		local knobPos = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local swColor = value and T("Primary") or T("Stroke")
		if animate then
			tween(knob, { Position = knobPos }, 0.15)
			tween(sw, { BackgroundColor3 = swColor }, 0.15)
		else
			knob.Position = knobPos
			sw.BackgroundColor3 = swColor
		end
	end
	table.insert(win.Refreshers, function()
		paintSw(false)
	end)

	local function set(v, fire)
		value = v and true or false
		paintSw(true)
		if flag then
			win.Flags[flag] = value and 0 or 1
			if fire then
				win:_save()
			end
		end
		if fire and cb then
			task.spawn(cb, value)
		end
	end

	if flag then
		win.Flags[flag] = value and 0 or 1
	end
	paintSw(false)

	local hit = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, f)
	hit.Activated:Connect(function()
		set(not value, true)
	end)

	local obj = {}
	function obj:Set(v)
		set(v, true)
	end
	function obj:Get()
		return value
	end
	return obj
end

function Tab:AddButton(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Botao"
	local cb = cfg.Callback or cfg[2]
	self.Order = self.Order + 1
	local b = paint(create("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		AutoButtonColor = false,
		Text = tostring(name),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	b.BackgroundTransparency = 0.25
	paint(b, "TextColor3", "Text")
	round(b, 6)
	b.Activated:Connect(function()
		if cb then
			task.spawn(cb)
		end
	end)
	return {
		SetTitle = function(_, t) b.Text = tostring(t) end,
		Callback = function(_, fn) cb = fn end,
	}
end

function Tab:AddSlider(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Slider"
	local min = cfg.Min or 0
	local max = cfg.Max or 100
	local inc = cfg.Increment or cfg.Inc or 1
	local flag = cfg.Flag
	local cb = cfg.Callback
	local win = self.Window

	local value = cfg.Default or min
	if flag and type(win.Flags[flag]) == "number" then
		value = win.Flags[flag]
	end

	local f = self:_row(54)
	label(f, {
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -90, 0, 18),
		Text = tostring(name),
	}, "Text")
	local vl = label(f, {
		Position = UDim2.new(1, -80, 0, 6),
		Size = UDim2.fromOffset(70, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
	}, "TextDark")
	local bar = paint(create("Frame", {
		Position = UDim2.new(0, 10, 1, -16),
		Size = UDim2.new(1, -20, 0, 6),
		BorderSizePixel = 0,
	}, f), "BackgroundColor3", "Stroke")
	round(bar, 3)
	local fill = paint(create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
	}, bar), "BackgroundColor3", "Primary")
	round(fill, 3)
	local hit = create("TextButton", {
		Position = UDim2.new(0, 0, 1, -24),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, f)

	local function set(v, fire)
		v = math.clamp(math.round(v / inc) * inc, min, max)
		value = v
		fill.Size = UDim2.fromScale((v - min) / math.max(max - min, 1e-9), 1)
		vl.Text = tostring(math.floor(v * 1000) / 1000)
		if flag then
			win.Flags[flag] = v
			if fire then
				win:_save()
			end
		end
		if fire and cb then
			task.spawn(cb, v)
		end
	end
	set(value, false)

	local dragging = false
	local function fromInput(input)
		local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		set(min + rel * (max - min), true)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromInput(input)
		end
	end)
	table.insert(win.Connections, UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromInput(input)
		end
	end))
	table.insert(win.Connections, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local obj = {}
	function obj:Set(v)
		set(v, true)
	end
	function obj:Get()
		return value
	end
	return obj
end

function Tab:AddDropdown(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Dropdown"
	local options = cfg.Options or cfg[2] or {}
	local default = cfg.Default
	local flag = cfg.Flag
	local cb = cfg.Callback
	local multi = cfg.MultiSelect == true or cfg.Multi == true
	local win = self.Window

	self.Order = self.Order + 1
	local box = paint(create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.Order,
	}, self.Page), "BackgroundColor3", "Element")
	box.BackgroundTransparency = 0.25
	round(box, 6)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, box)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
	}, box)

	local head = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 1,
	}, box)
	label(head, {
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
	local arrow = create("ImageLabel", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = ICON_OPEN,
	}, head)
	paint(arrow, "ImageColor3", "Text")

	local list = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
	}, box)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, list)

	local dd = { Options = {}, Value = nil }
	local buttons = {}
	local selected = {}
	local count = 0

	local function currentValue()
		if multi then
			local out = {}
			for _, o in ipairs(dd.Options) do
				if selected[o] then
					table.insert(out, o)
				end
			end
			return out
		end
		return dd.Value
	end

	local function paintOpt(opt)
		local b = buttons[opt]
		if not b then
			return
		end
		local on = selected[opt] and true or false
		b.BackgroundColor3 = on and T("Primary") or T("Stroke")
	end

	local function refreshLabel()
		if multi then
			local names = {}
			for _, o in ipairs(dd.Options) do
				if selected[o] then
					table.insert(names, o)
				end
			end
			val.Text = #names > 0 and table.concat(names, ", ") or "..."
		else
			val.Text = dd.Value and tostring(dd.Value) or "..."
		end
		for _, o in ipairs(dd.Options) do
			paintOpt(o)
		end
	end

	local function commit(fire)
		refreshLabel()
		if flag then
			win.Flags[flag] = currentValue()
			if fire then
				win:_save()
			end
		end
		if fire and cb then
			task.spawn(cb, currentValue())
		end
	end

	table.insert(win.Refreshers, function()
		refreshLabel()
	end)

	local function addOne(opt)
		opt = tostring(opt)
		if buttons[opt] then
			return
		end
		count = count + 1
		local b = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			AutoButtonColor = false,
			Text = opt,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			LayoutOrder = count,
		}, list)
		paint(b, "TextColor3", "Text")
		round(b, 4)
		buttons[opt] = b
		table.insert(dd.Options, opt)
		b.Activated:Connect(function()
			if multi then
				selected[opt] = (not selected[opt]) or nil
			else
				dd.Value = opt
				for k in pairs(selected) do
					selected[k] = nil
				end
				selected[opt] = true
				list.Visible = false
				arrow.Image = ICON_OPEN
			end
			commit(true)
		end)
	end

	function dd:Select(opt, fire)
		opt = tostring(opt)
		if not buttons[opt] then
			return false
		end
		if multi then
			selected[opt] = true
		else
			self.Value = opt
			for k in pairs(selected) do
				selected[k] = nil
			end
			selected[opt] = true
		end
		commit(fire and true or false)
		return true
	end

	function dd:Get()
		return currentValue()
	end

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
	end

	function dd:Clear()
		for _, b in pairs(buttons) do
			b:Destroy()
		end
		buttons = {}
		self.Options = {}
		self.Value = nil
		selected = {}
		count = 0
		commit(false)
	end

	function dd:Set(opts)
		self:Clear()
		self:Add(opts)
	end

	head.Activated:Connect(function()
		list.Visible = not list.Visible
		arrow.Image = list.Visible and ICON_CLOSED or ICON_OPEN
	end)

	dd:Add(options)

	-- restaura valor salvo ou o padrão
	local initial = flag and win.Flags[flag]
	if initial == nil then
		initial = default
	end
	if multi then
		if type(initial) == "table" then
			for _, v in ipairs(initial) do
				if buttons[tostring(v)] then
					selected[tostring(v)] = true
				end
			end
		end
	else
		if type(initial) == "table" then
			initial = initial[1]
		end
		if initial ~= nil and buttons[tostring(initial)] then
			dd.Value = tostring(initial)
			selected[dd.Value] = true
		end
	end
	commit(false)

	-- chama o callback logo ao criar, igual à Gold
	if cb then
		task.defer(function()
			local cv = currentValue()
			if cv ~= nil then
				cb(cv)
			end
		end)
	end
	return dd
end

function Tab:AddTextBox(cfg)
	cfg = cfg or {}
	local name = cfg.Name or cfg.Title or cfg[1] or "Input"
	local default = cfg.Default or ""
	local placeholder = cfg.Placeholder or cfg.PlaceholderText or "..."
	local cb = cfg.Callback

	local f = self:_row(44)
	titles(f, name, nil, 170)
	local box = paint(create("TextBox", {
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.new(0, 150, 0, 26),
		Text = tostring(default),
		PlaceholderText = tostring(placeholder),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		ClearTextOnFocus = false,
	}, f), "BackgroundColor3", "Stroke")
	paint(box, "TextColor3", "Text")
	round(box, 4)
	box.FocusLost:Connect(function()
		if cb then
			task.spawn(cb, box.Text)
		end
	end)
	return {
		Set = function(_, v) box.Text = tostring(v) end,
		Get = function() return box.Text end,
	}
end

return GGUIapi = {}
	function api:Set(v)
		selected = {}
		if type(v) == "table" then
			for _, item in ipairs(v) do
				selected[item] = true
			end
		elseif v then
			selected[v] = true
		end
		refresh()
	end

	if cfg.Default then
		api:Set(cfg.Default)
	else
		refresh()
	end
	return api
end

function Library:TextBox(tab, cfg)
	local row = makeRow(tab, 32, cfg.Name, cfg.Description)
	local box = new("TextBox", {
		Size = UDim2.new(0, 110, 0, 20),
		Position = UDim2.new(1, -110, 0.5, -10),
		BackgroundColor3 = Library.Theme.Stroke,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 9,
		Text = cfg.Default or "",
		PlaceholderText = cfg.Placeholder or "",
		TextColor3 = Library.Theme.Text,
		PlaceholderColor3 = Library.Theme.Dim,
		ClearTextOnFocus = false,
		Parent = row,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = box })
	connect(box.FocusLost, function()
		if cfg.Callback then
			task.spawn(cfg.Callback, box.Text)
		end
	end)
	return box
end

function Library:Keybind(tab, cfg)
	local row = makeRow(tab, 32, cfg.Name, cfg.Description)
	local btn = new("TextButton", {
		Size = UDim2.new(0, 80, 0, 20),
		Position = UDim2.new(1, -80, 0.5, -10),
		BackgroundColor3 = Library.Theme.Stroke,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		Text = cfg.Default and cfg.Default.Name or "—",
		Parent = row,
	})
	style(btn, "BackgroundColor3", "Stroke")
	style(btn, "TextColor3", "Text")
	new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = btn })

	local listening, current = false, cfg.Default
	connect(btn.MouseButton1Click, function()
		listening = true
		btn.Text = "..."
	end)
	connect(UIS.InputBegan, function(input)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			current = input.KeyCode
			btn.Text = input.KeyCode.Name
			listening = false
			if cfg.Callback then
				task.spawn(cfg.Callback, input.KeyCode)
			end
		end
	end)
	return {
		Get = function()
			return current
		end,
	}
end

--=====================================================================
--  ESTADO
--=====================================================================
local State = {
	Tween = nil,
	FarmPos = nil,
	FarmMob = nil,
	SeenChest = {},
	Bought = {},
}

pcall(function()
	local effect = ReplicatedStorage:FindFirstChild("Effect")
	local container = effect and effect:FindFirstChild("Container")
	if container then
		if container:FindFirstChild("Death") then
			container.Death:Destroy()
		end
		if container:FindFirstChild("Respawn") then
			container.Respawn:Destroy()
		end
	end
end)

pcall(function()
	local util = ReplicatedStorage:FindFirstChild("Util")
	local shaker = util and util:FindFirstChild("CameraShaker")
	if shaker then
		require(shaker):Stop()
	end
end)

--=====================================================================
--  MOVIMENTAÇÃO
--=====================================================================
local function stopTween()
	if State.Tween then
		pcall(function()
			State.Tween:Cancel()
		end)
		State.Tween = nil
	end
end

local function teleport(cf, speed)
	local _, hrp = getChar()
	if not hrp or not cf then
		return
	end
	stopTween()
	local dist = (cf.Position - hrp.Position).Magnitude
	if dist < 8 then
		hrp.CFrame = cf
		return
	end
	State.Tween = TweenService:Create(hrp, TweenInfo.new(dist / (speed or 360), Enum.EasingStyle.Linear), { CFrame = cf })
	State.Tween:Play()
end

local function snap(cf)
	local _, hrp = getChar()
	if hrp and cf then
		stopTween()
		hrp.CFrame = cf
	end
end

--=====================================================================
--  COMBATE
--=====================================================================
local function equipType(kind)
	local char = getChar()
	if not char then
		return
	end
	local tip = (kind == "Fruit") and "Blox Fruit" or kind
	for _, t in ipairs(char:GetChildren()) do
		if t:IsA("Tool") and t.ToolTip == tip then
			return t
		end
	end
	for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
		if t:IsA("Tool") and t.ToolTip == tip then
			pcall(function()
				char.Humanoid:EquipTool(t)
			end)
			return t
		end
	end
end

local function attack(range)
	local char, hrp = getChar()
	if not char or not hrp then
		return
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then
		return
	end

	local targets, mainTarget = {}, nil
	for _, mob in ipairs(enemies:GetChildren()) do
		local mhrp = mob:FindFirstChild("HumanoidRootPart")
		local hum = mob:FindFirstChildOfClass("Humanoid")
		if mhrp and hum and hum.Health > 0 and (mhrp.Position - hrp.Position).Magnitude <= (range or 62) then
			local head = mob:FindFirstChild("Head") or mhrp
			table.insert(targets, { mob, head })
			mainTarget = head
		end
	end
	if not mainTarget then
		return
	end

	local net = ReplicatedStorage:FindFirstChild("Modules")
	net = net and net:FindFirstChild("Net")
	local regAtk = net and net:FindFirstChild("RE/RegisterAttack")
	local regHit = net and net:FindFirstChild("RE/RegisterHit")

	if regAtk and regHit then
		pcall(function()
			regAtk:FireServer(0)
			regHit:FireServer(mainTarget, targets)
		end)
		return
	end

	local rig = ReplicatedStorage:FindFirstChild("RigControllerEvent")
	local val = Remotes:FindFirstChild("Validator")
	if rig and val then
		pcall(function()
			rig:FireServer("weaponChange", tool.Name)
			val:FireServer(math.random(1, 16777215), math.random(1, 99))
			rig:FireServer("hit", targets, 2, "")
		end)
	end
end

local function bringMobs(range)
	local _, hrp = getChar()
	if not hrp or not State.FarmPos then
		return
	end
	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then
		return
	end
	for _, mob in ipairs(enemies:GetChildren()) do
		local mhrp = mob:FindFirstChild("HumanoidRootPart")
		local hum = mob:FindFirstChildOfClass("Humanoid")
		if mhrp and hum and hum.Health > 0 and (not State.FarmMob or mob.Name == State.FarmMob) then
			if (mhrp.Position - State.FarmPos.Position).Magnitude <= (range or 400) then
				mhrp.CFrame = State.FarmPos
				mhrp.Size = Vector3.new(60, 60, 60)
				mhrp.Transparency = 0.9
				mhrp.CanCollide = false
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				if hum:FindFirstChild("Animator") then
					hum.Animator:Destroy()
				end
			end
		end
	end
end

local function killMob(mob, offset)
	local mhrp = mob:FindFirstChild("HumanoidRootPart")
	if not mhrp then
		return
	end
	State.FarmPos = mhrp.CFrame
	State.FarmMob = mob.Name
	teleport(mhrp.CFrame * (offset or CFrame.new(0, 30, 8)))
	attack()
end

--=====================================================================
--  QUEST DINÂMICA
--=====================================================================
local GuideCache, QuestCache

local function getModules()
	if GuideCache and QuestCache then
		return GuideCache, QuestCache
	end
	pcall(function()
		GuideCache = require(ReplicatedStorage:WaitForChild("GuideModule"))
		QuestCache = require(ReplicatedStorage:WaitForChild("Quests"))
	end)
	return GuideCache, QuestCache
end

local function spawnPoints(mob)
	local out = {}
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local spawns = origin and origin:FindFirstChild("EnemySpawns")
	if not spawns then
		return out
	end
	for _, part in ipairs(spawns:GetChildren()) do
		if part:IsA("BasePart") and normalize(part.Name) == mob then
			table.insert(out, part.CFrame)
		end
	end
	return out
end

local STARTER = {
	Marines = { level = 1, npc = CFrame.new(-2709.67944, 24.5206585, 2104.24585), mob = "Trainee", quest = "MarineQuest", display = "Trainee [Lv. 5]" },
	Pirates = { level = 1, npc = CFrame.new(1059.99731, 16.9222069, 1549.28162), mob = "Bandit", quest = "BanditQuest1", display = "Bandit [Lv. 5]" },
}

local function resolveQuest()
	local data = LocalPlayer:FindFirstChild("Data")
	local lvlVal = data and data:FindFirstChild("Level")
	local lvl = lvlVal and lvlVal.Value or 1

	if lvl <= 9 then
		local s = STARTER[tostring(LocalPlayer.Team)] or STARTER.Pirates
		return { level = s.level, npc = s.npc, mob = s.mob, quest = s.quest, display = s.display, spawns = spawnPoints(s.mob) }
	end

	local guide, quests = getModules()
	local npcList = guide and guide.Data and guide.Data.NPCList
	if not npcList then
		return nil
	end

	local bestNpc, bestReq = nil, 0
	for _, entry in pairs(npcList) do
		for _, req in ipairs(entry.Levels or {}) do
			if lvl >= req and req > bestReq then
				bestNpc, bestReq = entry, req
			end
		end
	end
	if not bestNpc then
		return nil
	end

	for questName, tiers in pairs(quests) do
		if questName ~= "CitizenQuest" then
			for _, tier in pairs(tiers) do
				if tier.LevelReq == bestReq and tier.Task then
					for mobDisplay in pairs(tier.Task) do
						local mob = normalize(mobDisplay)
						return { level = bestReq, npc = bestNpc.CFrame, mob = mob, quest = questName, display = mobDisplay, spawns = spawnPoints(mob) }
					end
				end
			end
		end
	end
	return nil
end

local function questText()
	local main = LocalPlayer.PlayerGui:FindFirstChild("Main")
	local quest = main and main:FindFirstChild("Quest")
	local container = quest and quest:FindFirstChild("Container")
	local title = container and container:FindFirstChild("QuestTitle")
	title = title and title:FindFirstChild("Title")
	return (quest and quest.Visible), (title and title.Text or "")
end

--=====================================================================
--  CONSTRUÇÃO DA UI
--=====================================================================
Library:Load()

local Window = Library:CreateWindow({ Title = "Venice Hub", SubTitle = "blox fruits · v2.1" })
Window.SearchTab = Library:CreateTab(Window, "Busca", "⌕")

local Farm = Library:CreateTab(Window, "Farm", "⚔")
local Combat = Library:CreateTab(Window, "Combate", "✧")
local Raid = Library:CreateTab(Window, "Raid", "☄")
local Quests = Library:CreateTab(Window, "Quests", "✧")
local Stats = Library:CreateTab(Window, "Progressão", "▲")
local Travel = Library:CreateTab(Window, "Viagem", "✈")
local Visual = Library:CreateTab(Window, "Visual", "◈")
local Misc = Library:CreateTab(Window, "Diversos", "⚙")
local Config = Library:CreateTab(Window, "Config", "≡")

-- FARM
Library:Section(Farm, "Nível")
Library:Toggle(Farm, { Name = "Auto Farm Nível", Description = "Quest automática por faixa de level", Flag = "AutoFarm", Default = Library:Flag("AutoFarm", false) })
Library:Slider(Farm, { Name = "Distância", Min = 10, Max = 60, Default = Library:Flag("FarmDistance", 25), Increment = 1, Flag = "FarmDistance" })
Library:Toggle(Farm, { Name = "Puxar mobs", Flag = "BringMob", Default = Library:Flag("BringMob", true) })

Library:Section(Farm, "Boss")
Library:Dropdown(Farm, {
	Name = "Boss",
	Options = ({
		[1] = { "The Gorilla King", "Bobby", "The Saw", "Chef", "Yeti", "Mob Leader", "Vice Admiral", "Saber Expert", "Warden", "Chief Warden", "Magma General", "Fishman Lord", "Sky Warlord", "Lightning God", "Cyborg" },
		[2] = { "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Awakened Ice Admiral", "Tide Keeper", "Order", "Cursed Captain", "Greybeard" },
		[3] = { "Stone", "Hydra Leader", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Cake Queen", "Longma", "Soul Reaper", "rip_indra", "Dough King" },
	})[SEA],
	Default = Library:Flag("BossSelect", "Stone"),
	Flag = "BossSelect",
})
Library:Toggle(Farm, { Name = "Auto Boss", Flag = "AutoBoss", Default = Library:Flag("AutoBoss", false) })

Library:Section(Farm, "Coleta")
Library:Toggle(Farm, { Name = "Auto Baús", Description = "Coleta baús no mapa", Flag = "AutoChest", Default = Library:Flag("AutoChest", false) })
Library:Toggle(Farm, { Name = "Auto Fruta", Description = "Pega frutas caídas", Flag = "AutoFruit", Default = Library:Flag("AutoFruit", false) })
Library:Toggle(Farm, { Name = "Bone Farm", Description = "Castelo Assombrado (Sea 3)", Flag = "AutoBone", Default = Library:Flag("AutoBone", false) })
Library:Toggle(Farm, { Name = "Auto Elite", Description = "Elites do Sea 3", Flag = "AutoElite", Default = Library:Flag("AutoElite", false) })

Library:Section(Farm, "Material")
Library:Dropdown(Farm, {
	Name = "Material",
	Options = ({
		[1] = { "Brute", "Snow Bandit", "Fishman Warrior", "God's Guard" },
		[2] = { "Zombie", "Snow Trooper", "Magma Ninja", "Ship Deckhand", "Arctic Warrior" },
		[3] = { "Dragon Crew Warrior", "Marine Commando", "Fishman Raider", "Reborn Skeleton", "Peanut Scout" },
	})[SEA],
	Default = Library:Flag("MaterialMob", ""),
	Flag = "MaterialMob",
})
Library:Toggle(Farm, { Name = "Auto Material", Flag = "AutoMaterial", Default = Library:Flag("AutoMaterial", false) })

-- COMBATE
Library:Section(Combat, "Ataque")
Library:Toggle(Combat, { Name = "Ataque rápido", Description = "Hits direto no remote", Flag = "FastAttack", Default = Library:Flag("FastAttack", true) })
Library:Slider(Combat, { Name = "Delay (ms)", Min = 0, Max = 500, Default = Library:Flag("AttackDelay", 0), Increment = 10, Flag = "AttackDelay" })
Library:Toggle(Combat, { Name = "Mob Aura", Flag = "MobAura", Default = Library:Flag("MobAura", false) })
Library:Slider(Combat, { Name = "Raio da Aura", Min = 20, Max = 400, Default = Library:Flag("AuraRange", 120), Increment = 10, Flag = "AuraRange" })
Library:Toggle(Combat, { Name = "Multi-hit", Description = "Repete o hit no mesmo alvo", Flag = "MultiHit", Default = Library:Flag("MultiHit", false) })
Library:Dropdown(Combat, { Name = "Arma automática", Options = { "Melee", "Sword", "Fruit", "Gun" }, Default = Library:Flag("WeaponType", "Melee"), Flag = "WeaponType" })

Library:Section(Combat, "Haki e skills")
Library:Toggle(Combat, { Name = "Auto Buso", Flag = "AutoBuso", Default = Library:Flag("AutoBuso", true) })
Library:Toggle(Combat, { Name = "Auto Ken", Flag = "AutoKen", Default = Library:Flag("AutoKen", false) })
Library:Toggle(Combat, { Name = "Auto Skills (Z X C V)", Flag = "AutoSkills", Default = Library:Flag("AutoSkills", false) })
Library:Slider(Combat, { Name = "Intervalo das skills", Min = 0.2, Max = 5, Default = Library:Flag("SkillDelay", 1), Increment = 0.1, Flag = "SkillDelay", Suffix = "s" })

-- RAID
local function raidGui()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	local main = pg and pg:FindFirstChild("Main")
	return main and main:FindFirstChild("Raid")
end

local function raidActive()
	local raid = raidGui()
	return raid and raid.Visible or false
end

local function chipInBackpack()
	local char = getChar()
	local lists = { LocalPlayer.Backpack }
	if char then
		table.insert(lists, char)
	end
	for _, list in ipairs(lists) do
		for _, t in ipairs(list:GetChildren()) do
			if t:IsA("Tool") and string.find(string.lower(t.Name), "chip") then
				return t
			end
		end
	end
	return nil
end

local CHIPS = {
	"Basic Raid Microchip",
	"Advanced Raid Microchip",
	"Flame Chip", "Ice Chip", "Sand Chip", "Dark Chip", "Lightning Chip",
	"Ghost Chip", "Magma Chip", "Quake Chip", "Bomb Chip", "Spike Chip",
	"Spring Chip", "Chop Chip", "Smoke Chip", "Blade Chip", "Barrier Chip",
	"Rubber Chip", "Revive Chip", "Diamond Chip", "Rumble Chip", "Paw Chip",
	"Gravity Chip", "Phoenix Chip", "Dough Chip",
}

local function buyChip(chip)
	if chipInBackpack() then
		notify("Chip", "Você já tem um chip no inventário.")
		return true
	end
	local data = LocalPlayer:FindFirstChild("Data")
	local beli = data and data:FindFirstChild("Beli")
	if beli and beli.Value < 100000 then
		notify("Chip", "Beli insuficiente (mínimo 100.000).")
		return false
	end

	local variants = {
		function()
			CommF:InvokeServer("RaidsInfo", "Buy", chip)
		end,
		function()
			CommF:InvokeServer("RaidsInfo", "BuyChip", chip)
		end,
		function()
			CommF:InvokeServer("RaidsInfo", "Buy")
		end,
	}

	for _, fn in ipairs(variants) do
		pcall(fn)
		for _ = 1, 6 do
			task.wait(0.25)
			if chipInBackpack() then
				notify("Chip", "Comprado: " .. chip)
				return true
			end
		end
	end
	notify("Chip", "Falha ao comprar. Vá até o Mysterious Scientist.")
	return false
end

local function startRaid(chip, island)
	if raidActive() then
		return true
	end
	if not chipInBackpack() then
		notify("Raid", "Sem chip no inventário.")
		return false
	end

	local variants = {
		function()
			CommF:InvokeServer("RaidsInfo", "Start", chip, island)
		end,
		function()
			CommF:InvokeServer("RaidsInfo", "Start", chip)
		end,
		function()
			CommF:InvokeServer("RaidsInfo", "Start")
		end,
	}

	for _, fn in ipairs(variants) do
		pcall(fn)
		for _ = 1, 8 do
			task.wait(0.3)
			if raidActive() then
				notify("Raid", "Raid iniciada na ilha " .. tostring(island))
				return true
			end
		end
	end
	notify("Raid", "Não foi possível iniciar.")
	return false
end

local function raidTarget()
	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then
		return nil
	end
	local _, hrp = getChar()
	local best, bestScore
	for _, mob in ipairs(enemies:GetChildren()) do
		local mhrp = mob:FindFirstChild("HumanoidRootPart")
		local hum = mob:FindFirstChildOfClass("Humanoid")
		if mhrp and hum and hum.Health > 0 then
			local score = 0
			if string.find(mob.Name, "Boss") or string.find(mob.Name, "Awakened") then
				score += 1000
			end
			if hrp then
				score += 2000 - math.min((mhrp.Position - hrp.Position).Magnitude, 2000)
			end
			if not bestScore or score > bestScore then
				best, bestScore = mob, score
			end
		end
	end
	return best
end

Library:Section(Raid, "Chip")
Library:Dropdown(Raid, {
	Name = "Chip selecionado",
	Options = CHIPS,
	Default = Library:Flag("RaidChip", "Basic Raid Microchip"),
	Flag = "RaidChip",
})
Library:Slider(Raid, { Name = "Ilha", Min = 1, Max = 5, Default = Library:Flag("RaidIsland", 1), Increment = 1, Flag = "RaidIsland" })
Library:Button(Raid, { Name = "Comprar chip", Callback = function()
	buyChip(Library.Flags.RaidChip)
end })
Library:Button(Raid, { Name = "Iniciar raid", Callback = function()
	startRaid(Library.Flags.RaidChip, Library.Flags.RaidIsland)
end })

Library:Section(Raid, "Automação")
Library:Toggle(Raid, { Name = "Auto Comprar Chip", Flag = "AutoBuyChip", Default = Library:Flag("AutoBuyChip", false) })
Library:Toggle(Raid, { Name = "Auto Start Raid", Flag = "AutoStartRaid", Default = Library:Flag("AutoStartRaid", false) })
Library:Toggle(Raid, { Name = "Auto Limpar Raid", Description = "Mata mobs e boss da raid", Flag = "AutoClearRaid", Default = Library:Flag("AutoClearRaid", false) })
Library:Toggle(Raid, { Name = "Auto Sair da Raid", Description = "Sai quando termina", Flag = "AutoLeaveRaid", Default = Library:Flag("AutoLeaveRaid", false) })
Library:Button(Raid, { Name = "Sair da raid agora", Callback = function()
	pcall(function()
		CommF:InvokeServer("RaidsInfo", "Leave")
	end)
end })

-- QUESTS ESPECIAIS
local QD = {}

QD.Race = {
	{ name = "Race V2 (Arowe)", npc = CFrame.new(-2955.9, 27.6, -2520.2), sea = 3 },
	{ name = "Race V3 (Tort)", npc = CFrame.new(-7332.3, 30.6, 5983.1), sea = 3 },
	{ name = "Race V4 (Templo)", npc = CFrame.new(-16808.5, 210.5, 573.3), sea = 3 },
}

QD.Sword = {
	{ name = "Saber (Saber Expert)", npc = CFrame.new(-1405.0, 29.4, 4.4), boss = "Saber Expert", sea = 1 },
	{ name = "Dark Blade (Mihawk)", npc = CFrame.new(-1352.9, 46.4, -1420.9), boss = "Mihawk", sea = 1 },
	{ name = "Canvander (Beautiful Pirate)", npc = CFrame.new(5289.0, 22.7, 590.7), boss = "Beautiful Pirate", sea = 3 },
	{ name = "Yama (Cursed Skeleton)", npc = CFrame.new(-14215.0, 314.0, 6210.0), boss = "Cursed Skeleton", sea = 3 },
	{ name = "Tushita (Longma)", npc = CFrame.new(-15008.0, 250.0, 5600.0), boss = "Longma", sea = 3 },
}

QD.Style = {
	{ id = "Superhuman", name = "Superhuman", npc = CFrame.new(-2877.0, 23.0, -2850.0), price = 3000000, sea = 2 },
	{ id = "SharkmanKarate", name = "Sharkman Karate", npc = CFrame.new(-2820.0, 20.0, -6800.0), price = 750000, sea = 3 },
	{ id = "DeathStep", name = "Death Step", npc = CFrame.new(-2431.0, 21.0, -3470.0), price = 500000, sea = 2 },
}

local function killBossLoop(boss)
	local enemies = Workspace:FindFirstChild("Enemies")
	local mob = enemies and enemies:FindFirstChild(boss)
	if mob and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
		killMob(mob, CFrame.new(0, 28, 8))
		return true
	end
	return false
end

Library:Section(Quests, "Race")
for _, entry in ipairs(QD.Race) do
	Library:Button(Quests, { Name = "TP · " .. entry.name, Callback = function()
		if SEA < entry.sea then
			notify("Quest", "Precisa do Sea " .. entry.sea .. ".")
			return
		end
		teleport(entry.npc, Library.Flags.TweenSpeed)
	end })
end

Library:Section(Quests, "Espadas")
Library:Dropdown(Quests, {
	Name = "Espada alvo",
	Options = (function()
		local out = {}
		for _, e in ipairs(QD.Sword) do
			if SEA >= e.sea then
				table.insert(out, e.name)
			end
		end
		return out
	end)(),
	Default = Library:Flag("SwordTarget", ""),
	Flag = "SwordTarget",
})
Library:Toggle(Quests, { Name = "Auto Farm da espada", Description = "Mata o boss e pega o drop", Flag = "AutoSword", Default = Library:Flag("AutoSword", false) })

Library:Section(Quests, "Estilos de luta")
Library:Dropdown(Quests, {
	Name = "Estilo alvo",
	Options = (function()
		local out = {}
		for _, e in ipairs(QD.Style) do
			if SEA >= e.sea then
				table.insert(out, e.name)
			end
		end
		return out
	end)(),
	Default = Library:Flag("StyleTarget", ""),
	Flag = "StyleTarget",
})
Library:Button(Quests, { Name = "Comprar estilo", Callback = function()
	local entry
	for _, e in ipairs(QD.Style) do
		if e.name == Library.Flags.StyleTarget then
			entry = e
			break
		end
	end
	if not entry then
		notify("Estilo", "Selecione um estilo.")
		return
	end
	teleport(entry.npc, Library.Flags.TweenSpeed)
	task.wait(1.2)
	pcall(function()
		CommF:InvokeServer("BuyFightingStyle", entry.id)
	end)
	notify("Estilo", "Tentativa de compra: " .. entry.name)
end })

Library:Section(Quests, "Coleta de item")
Library:Toggle(Quests, { Name = "Auto Coletar Item", Description = "Pega espadas/ferramentas no chão", Flag = "AutoItem", Default = Library:Flag("AutoItem", false) })
Library:Toggle(Quests, { Name = "ESP Item", Flag = "EspItem", Default = Library:Flag("EspItem", false) })

-- PROGRESSÃO
Library:Section(Stats, "Distribuição de pontos")
for _, statName in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
	Library:Toggle(Stats, { Name = "Auto " .. statName, Flag = "Stat_" .. statName, Default = Library:Flag("Stat_" .. statName, statName == "Melee" or statName == "Defense") })
end
Library:Toggle(Stats, { Name = "Auto Stats", Description = "Gasta pontos nos ativos", Flag = "AutoStats", Default = Library:Flag("AutoStats", false) })
Library:Button(Stats, { Name = "Gastar todos os pontos agora", Callback = function()
	local data = LocalPlayer:FindFirstChild("Data")
	local points = data and data:FindFirstChild("Points")
	if not points then
		return
	end
	while points.Value > 0 do
		local done = false
		for _, statName in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
			if Library.Flags["Stat_" .. statName] and points.Value > 0 then
				CommF:InvokeServer("AddPoint", statName, 1)
				done = true
				task.wait(0.05)
			end
		end
		if not done then
			break
		end
	end
	notify("Stats", "Pontos distribuídos.")
end })

Library:Section(Stats, "Haki")
Library:Button(Stats, { Name = "Comprar Buso Haki", Callback = function()
	pcall(function()
		CommF:InvokeServer("BuyHaki", "Buso")
	end)
end })
Library:Button(Stats, { Name = "Comprar Ken Haki", Callback = function()
	pcall(function()
		CommF:InvokeServer("BuyHaki", "Geppo")
		CommF:InvokeServer("BuyHaki", "Soru")
	end)
end })

-- VIAGEM
Library:Section(Travel, "Ilhas")
local islandHolder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Travel.Container })
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = islandHolder })

local function buildIslands()
	for _, c in ipairs(islandHolder:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	if not locations then
		return
	end
	for _, loc in ipairs(locations:GetChildren()) do
		if loc:IsA("BasePart") and loc.Name ~= "Sea" then
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = Library.Theme.Row,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Font = Enum.Font.GothamMedium,
				TextSize = 10,
				Text = "  " .. loc.Name,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = islandHolder,
			})
			style(b, "BackgroundColor3", "Row")
			style(b, "TextColor3", "Text")
			new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = b })
			connect(b.MouseButton1Click, function()
				teleport(loc.CFrame * CFrame.new(0, 20, 0), 520)
			end)
			connect(b.MouseEnter, function()
				tween(b, 0.12, { BackgroundColor3 = Library.Theme.Hover })
			end)
			connect(b.MouseLeave, function()
				tween(b, 0.12, { BackgroundColor3 = Library.Theme.Row })
			end)
		end
	end
end
buildIslands()
task.delay(5, buildIslands)

Library:Section(Travel, "Quest")
Library:Button(Travel, { Name = "Ir ao NPC da quest", Callback = function()
	local q = resolveQuest()
	if q then
		teleport(q.npc)
	end
end })
Library:Button(Travel, { Name = "Ir ao mob da quest", Callback = function()
	local q = resolveQuest()
	if q and q.spawns[1] then
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