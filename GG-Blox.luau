--=====================================================================
--  GG BLOX v2.8 — BLOX FRUITS
--  UI: Gold UI (redz v5) · baixada do repositorio, local como fallback
--  RightShift minimiza. Teste em servidor privado primeiro.
--=====================================================================

local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local Lighting = cloneref(game:GetService("Lighting"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 15)
local CommE = Remotes and Remotes:FindFirstChild("CommE")

local SEA = ({ [2753915549] = 1, [4442272183] = 2, [7449423635] = 3 })[game.PlaceId] or 1

--=====================================================================
--  CARREGAR A UI  (repo primeiro, local como fallback)
--=====================================================================
local UI_URLS = {
	"https://cdn.jsdelivr.net/gh/MegaKnigth/GG-Blox@main/Gold-Ui.luau",
	"https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/Gold-Ui.luau",
}
local UI_LOCAL = { "GoldUI.luau", "Gold-Ui.luau", "GoldUI.lua", "Gold ui.luau", "Gold ui.luau.txt" }

local function validSource(src)
	return type(src) == "string" and #src > 2000 and string.find(src, "MakeWindow", 1, true) ~= nil
end

local function trySource(src, tag)
	if not validSource(src) then
		return nil
	end
	local fn = loadstring(src, tag)
	if not fn then
		return nil
	end
	local ok, lib = pcall(fn)
	if ok and type(lib) == "table" and lib.MakeWindow then
		return lib
	end
	return nil
end

local function tryDownload()
	for _, url in ipairs(UI_URLS) do
		local ok, src = pcall(function()
			return game:HttpGet(url)
		end)
		if ok then
			local lib = trySource(src, "GoldUI")
			if lib then
				return lib
			end
		end
	end
	return nil
end

local function tryLocal()
	for _, name in ipairs(UI_LOCAL) do
		local ok, src = pcall(readfile, name)
		if ok then
			local lib = trySource(src, name)
			if lib then
				return lib
			end
		end
	end
	return nil
end

local function loadUILibrary()
	assert(loadstring, "Executor sem loadstring.")
	local lib = tryDownload()
	if lib then
		return lib
	end
	lib = tryLocal()
	if lib then
		return lib
	end
	error("GoldUI indisponivel: download do GitHub falhou e nenhum arquivo local valido. Confira UI_URLS.")
end

local Library = loadUILibrary()

--=====================================================================
--  UTILITARIOS
--=====================================================================
local function new(class, props, children)
	local obj = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = obj
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function comma(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function normalize(name)
	name = string.gsub(name, "%s*%[Lv%.%s*%d+%]", "")
	return (string.gsub(name, "[%[%]]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function getChar()
	local char = LocalPlayer.Character
	if not char then
		return nil, nil
	end
	return char, char:FindFirstChild("HumanoidRootPart")
end

local function getLevel()
	local data = LocalPlayer:FindFirstChild("Data")
	local lvl = data and data:FindFirstChild("Level")
	return lvl and lvl.Value or 1
end

local function getBeli()
	local data = LocalPlayer:FindFirstChild("Data")
	local beli = data and data:FindFirstChild("Beli")
	return beli and beli.Value or 0
end

local Window
local Dead = false

local function notify(title, content)
	if Window and not Dead then
		pcall(function()
			Window:Notify({ Title = title, Content = content, Duration = 4 })
		end)
	end
end

local function fireTouch(target)
	local _, hrp = getChar()
	if not hrp or not target then
		return
	end
	local part = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
	if not part then
		return
	end
	pcall(function()
		firetouchinterest(hrp, part, 0)
		task.wait(0.05)
		firetouchinterest(hrp, part, 1)
	end)
end

--=====================================================================
--  ESTADO
--=====================================================================
local MAX_TARGETS = 12

local State = {
	Tween = nil,
	FarmPos = nil,
	FarmMob = nil,
	QuestGrace = 0,
	SeenChest = {},
	SeenFruit = {},
}

local WarnTimes = {}
local function warnOnce(key, title, content, cooldown)
	cooldown = cooldown or 20
	if os.clock() - (WarnTimes[key] or 0) < cooldown then
		return
	end
	WarnTimes[key] = os.clock()
	warn("[GG] " .. content)
	notify(title, content)
end

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
--  MOVIMENTACAO
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

--=====================================================================
--  COMBATE
--=====================================================================
local Net
local warnedNet = false
local warnedWeapon = false

task.spawn(function()
	for _ = 1, 30 do
		local modules = ReplicatedStorage:FindFirstChild("Modules")
		local netModule = modules and modules:FindFirstChild("Net")
		if netModule and netModule:IsA("ModuleScript") then
			local ok, res = pcall(require, netModule)
			if ok and type(res) == "table" and res["RE/RegisterAttack"] then
				Net = res
				return
			end
		end
		task.wait(1)
	end
	warnOnce("net", "Erro", "Modulo Net nao carregou. Ataque/Farm sem dano.", 60)
end)

local function equipType(kind)
	local char = getChar()
	if not char then
		return nil
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
	return nil
end

local function collectTargets(range)
	local _, hrp = getChar()
	if not hrp then
		return nil, nil
	end
	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then
		return nil, nil
	end
	local targets, head = {}, nil
	for _, mob in ipairs(enemies:GetChildren()) do
		local mhrp = mob:FindFirstChild("HumanoidRootPart")
		local hum = mob:FindFirstChildOfClass("Humanoid")
		if mhrp and hum and hum.Health > 0 and (mhrp.Position - hrp.Position).Magnitude <= range then
			local h = mob:FindFirstChild("Head") or mhrp
			table.insert(targets, { mob, h })
			if not head then
				head = h
			end
			if #targets >= MAX_TARGETS then
				break
			end
		end
	end
	return targets, head
end

local function attack(range)
	local char, hrp = getChar()
	if not char or not hrp then
		return
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then
		if not warnedWeapon then
			warnedWeapon = true
			warnOnce("weapon", "Combate", "Nenhuma arma equipada. Auto Farm e Kill Aura nao atacam.", 45)
		end
		return
	end

	local targets, head = collectTargets(range or 62)
	if not head then
		return
	end

	if Net and Net["RE/RegisterAttack"] and Net["RE/RegisterHit"] then
		pcall(function()
			Net["RE/RegisterAttack"]:FireServer(0)
			Net["RE/RegisterHit"]:FireServer(head, targets)
		end)
		return
	end

	local rig = ReplicatedStorage:FindFirstChild("RigControllerEvent")
	local val = Remotes and Remotes:FindFirstChild("Validator")
	if rig and val then
		pcall(function()
			rig:FireServer("weaponChange", tool.Name)
			val:FireServer(math.random(1, 16777215), math.random(1, 99))
			rig:FireServer("hit", targets, 2, "")
		end)
		return
	end

	if not warnedNet then
		warnedNet = true
		warn("[GG] Net nil e sem fallback no attack(). Dano nao vai aplicar.")
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
		if mhrp and hum and hum.Health > 0 and (not State.FarmMob or normalize(mob.Name) == State.FarmMob) then
			if (mhrp.Position - State.FarmPos.Position).Magnitude <= (range or 400) then
				mhrp.CFrame = State.FarmPos
				mhrp.Size = Vector3.new(60, 60, 60)
				mhrp.Transparency = 0.9
				mhrp.CanCollide = false
				hum.WalkSpeed = 0
				hum.UseJumpPower = true
				hum.JumpPower = 0
				local animator = hum:FindFirstChildOfClass("Animator")
				if animator then
					animator:Destroy()
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
	State.FarmMob = normalize(mob.Name)
	teleport(mhrp.CFrame * (offset or CFrame.new(0, 30, 8)))
	attack()
end

--=====================================================================
--  QUEST DINAMICA
--=====================================================================
local GuideCache, QuestCache
local SpawnCache = {}

local function findModule(names)
	local parents = { ReplicatedStorage }
	local modules = ReplicatedStorage:FindFirstChild("Modules")
	if modules then
		table.insert(parents, modules)
	end
	for _, parent in ipairs(parents) do
		for _, name in ipairs(names) do
			local m = parent:FindFirstChild(name)
			if m and m:IsA("ModuleScript") then
				return m
			end
		end
	end
	return nil
end

local function getModules()
	if GuideCache and QuestCache then
		return GuideCache, QuestCache
	end
	local guide = findModule({ "GuideModule" })
	local quests = findModule({ "Quests", "QuestModule" })
	if guide then
		local ok, res = pcall(require, guide)
		if ok and type(res) == "table" then
			GuideCache = res
		end
	end
	if quests then
		local ok, res = pcall(require, quests)
		if ok and type(res) == "table" then
			QuestCache = res
		end
	end
	return GuideCache, QuestCache
end

local function spawnPoints(mob)
	local cached = SpawnCache[mob]
	if cached and os.clock() - cached.t < 30 then
		return cached.pts
	end
	local out = {}
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local spawns = origin and origin:FindFirstChild("EnemySpawns")
	if spawns then
		for _, part in ipairs(spawns:GetChildren()) do
			if part:IsA("BasePart") and normalize(part.Name) == mob then
				table.insert(out, part.CFrame)
			end
		end
	end
	SpawnCache[mob] = { pts = out, t = os.clock() }
	return out
end

local STARTER = {
	Marines = { level = 1, npc = CFrame.new(-2709.67944, 24.5206585, 2104.24585), mob = "Trainee", quest = "MarineQuest", display = "Trainee [Lv. 5]" },
	Pirates = { level = 1, npc = CFrame.new(1059.99731, 16.9222069, 1549.28162), mob = "Bandit", quest = "BanditQuest1", display = "Bandit [Lv. 5]" },
}

local function resolveQuest()
	local lvl = getLevel()

	if lvl <= 9 then
		local s = STARTER[tostring(LocalPlayer.Team)] or STARTER.Pirates
		return { level = s.level, npc = s.npc, mob = s.mob, quest = s.quest, display = s.display, spawns = spawnPoints(s.mob) }
	end

	local guide, quests = getModules()
	local npcList = guide and guide.Data and guide.Data.NPCList
	if not npcList or not quests then
		warnOnce("modules", "Farm", "Modulos de quest nao carregaram (LV " .. lvl .. ").", 30)
		return nil
	end

	local bestNpc, bestReq = nil, -1
	for _, entry in pairs(npcList) do
		for _, req in ipairs(entry.Levels or {}) do
			if lvl >= req and req > bestReq then
				bestNpc, bestReq = entry, req
			end
		end
	end
	if not bestNpc or bestReq < 0 then
		warnOnce("npc", "Farm", "Nenhum NPC de quest para LV " .. lvl .. ".", 30)
		return nil
	end

	for questName, tiers in pairs(quests) do
		if questName ~= "CitizenQuest" and type(tiers) == "table" then
			for tierKey, tier in pairs(tiers) do
				if type(tier) == "table" and tier.LevelReq == bestReq and tier.Task then
					for mobDisplay in pairs(tier.Task) do
						local mob = normalize(mobDisplay)
						return {
							level = tierKey,
							npc = bestNpc.CFrame,
							mob = mob,
							quest = questName,
							display = mobDisplay,
							spawns = spawnPoints(mob),
						}
					end
				end
			end
		end
	end
	warnOnce("quest", "Farm", "Nenhuma quest encontrada para LV " .. lvl .. ".", 30)
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

local function findMob(display, mob)
	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then
		return nil
	end
	local direct = enemies:FindFirstChild(display) or enemies:FindFirstChild(mob)
	if direct then
		return direct
	end
	for _, child in ipairs(enemies:GetChildren()) do
		if normalize(child.Name) == mob then
			return child
		end
	end
	return nil
end

--=====================================================================
--  RAID
--=====================================================================
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
		notify("Chip", "Voce ja tem um chip no inventario.")
		return true
	end
	if getBeli() < 100000 then
		notify("Chip", "Beli insuficiente (minimo 100.000).")
		return false
	end

	local variants = {
		function() CommF:InvokeServer("RaidsInfo", "Buy", chip) end,
		function() CommF:InvokeServer("RaidsInfo", "BuyChip", chip) end,
		function() CommF:InvokeServer("RaidsInfo", "Buy") end,
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
	notify("Chip", "Falha ao comprar. Va ate o Mysterious Scientist.")
	return false
end

local function startRaid(chip, island)
	if raidActive() then
		return true
	end
	if not chipInBackpack() then
		notify("Raid", "Sem chip no inventario.")
		return false
	end

	local variants = {
		function() CommF:InvokeServer("RaidsInfo", "Start", chip, island) end,
		function() CommF:InvokeServer("RaidsInfo", "Start", chip) end,
		function() CommF:InvokeServer("RaidsInfo", "Start") end,
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
	notify("Raid", "Nao foi possivel iniciar.")
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
				score = score + 1000
			end
			if hrp then
				score = score + (2000 - math.min((mhrp.Position - hrp.Position).Magnitude, 2000))
			end
			if not bestScore or score > bestScore then
				best, bestScore = mob, score
			end
		end
	end
	return best
end

--=====================================================================
--  QUESTS ESPECIAIS
--=====================================================================
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
	local hum = mob and mob:FindFirstChildOfClass("Humanoid")
	if mob and mob:FindFirstChild("HumanoidRootPart") and hum and hum.Health > 0 then
		killMob(mob, CFrame.new(0, 28, 8))
		return true
	end
	return false
end

--=====================================================================
--  JANELA
--=====================================================================
Window = Library:MakeWindow({
	Title = "GG Blox",
	SubTitle = "blox fruits · v2.8",
	ScriptFolder = "VeniceHub",
})

local hasGetFlag = pcall(function()
	return Window:GetFlag("__probe")
end)

local function flag(name)
	if not hasGetFlag then
		return nil
	end
	local ok, v = pcall(Window.GetFlag, Window, name)
	return ok and v or nil
end

local function setFlag(name, value)
	if not Window.SetFlag then
		return
	end
	pcall(Window.SetFlag, Window, name, value)
end

local function on(name)
	if Dead then
		return false
	end
	return flag(name) == 0
end

local function num(name, default)
	local v = flag(name)
	return type(v) == "number" and v or default
end

local function str(name, default)
	local v = flag(name)
	return (type(v) == "string" and v ~= "") and v or default
end

if Window.NewMinimizer then
	pcall(function()
		Window:NewMinimizer(Enum.KeyCode.RightShift)
	end)
end

if not hasGetFlag then
	task.delay(1, function()
		warnOnce("flags", "Erro", "GetFlag indisponivel na UI. Toggles nao vao alimentar os loops.", 60)
	end)
end

local Farm = Window:MakeTab({ Title = "Farm" })
local Combat = Window:MakeTab({ Title = "Combate" })
local Raid = Window:MakeTab({ Title = "Raid" })
local Quests = Window:MakeTab({ Title = "Quests" })
local Stats = Window:MakeTab({ Title = "Progressao" })
local Travel = Window:MakeTab({ Title = "Viagem" })
local Visual = Window:MakeTab({ Title = "Visual" })
local Misc = Window:MakeTab({ Title = "Diversos" })
local Config = Window:MakeTab({ Title = "Config" })

--=====================================================================
--  ABA FARM
--=====================================================================
Farm:AddSection("Nivel")
Farm:AddToggle({ Name = "Auto Farm Nivel", Description = "Quest automatica por faixa de level", Flag = "AutoFarm", Default = false })
Farm:AddSlider({ Name = "Distancia", Min = 10, Max = 60, Increment = 1, Default = 25, Flag = "FarmDistance" })
Farm:AddToggle({ Name = "Puxar mobs", Flag = "BringMob", Default = true })

Farm:AddSection("Boss")
Farm:AddDropdown({
	Name = "Boss",
	Options = ({
		[1] = { "The Gorilla King", "Bobby", "The Saw", "Chef", "Yeti", "Mob Leader", "Vice Admiral", "Saber Expert", "Warden", "Chief Warden", "Magma General", "Fishman Lord", "Sky Warlord", "Lightning God", "Cyborg" },
		[2] = { "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Awakened Ice Admiral", "Tide Keeper", "Order", "Cursed Captain", "Greybeard" },
		[3] = { "Stone", "Hydra Leader", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Cake Queen", "Longma", "Soul Reaper", "rip_indra", "Dough King" },
	})[SEA],
	Default = "Stone",
	Flag = "BossSelect",
})
Farm:AddToggle({ Name = "Auto Boss", Flag = "AutoBoss", Default = false })

Farm:AddSection("Coleta")
Farm:AddToggle({ Name = "Auto Baus", Description = "Coleta baus no mapa", Flag = "AutoChest", Default = false })
Farm:AddToggle({ Name = "Auto Fruta", Description = "Pega frutas caidas", Flag = "AutoFruit", Default = false })
Farm:AddToggle({ Name = "Bone Farm", Description = "Castelo Assombrado (Sea 3)", Flag = "AutoBone", Default = false })
Farm:AddToggle({ Name = "Auto Elite", Description = "Elites do Sea 3", Flag = "AutoElite", Default = false })

Farm:AddSection("Material")
Farm:AddDropdown({
	Name = "Material",
	Options = ({
		[1] = { "Brute", "Snow Bandit", "Fishman Warrior", "God's Guard" },
		[2] = { "Zombie", "Snow Trooper", "Magma Ninja", "Ship Deckhand", "Arctic Warrior" },
		[3] = { "Dragon Crew Warrior", "Marine Commando", "Fishman Raider", "Reborn Skeleton", "Peanut Scout" },
	})[SEA],
	Default = "",
	Flag = "MaterialMob",
})
Farm:AddToggle({ Name = "Auto Material", Flag = "AutoMaterial", Default = false })

--=====================================================================
--  ABA COMBATE
--=====================================================================
Combat:AddSection("Ataque")
Combat:AddToggle({ Name = "Ataque rapido", Description = "Intervalo minimo entre hits", Flag = "FastAttack", Default = true })
Combat:AddSlider({ Name = "Delay (ms)", Min = 0, Max = 500, Increment = 10, Default = 0, Flag = "AttackDelay" })
Combat:AddDropdown({ Name = "Arma automatica", Options = { "Melee", "Sword", "Fruit", "Gun" }, Default = "Melee", Flag = "WeaponType" })

Combat:AddSection("Kill Aura")
Combat:AddToggle({ Name = "Kill Aura", Description = "Ataca todos os mobs no raio, independente do farm", Flag = "KillAura", Default = false })
Combat:AddSlider({ Name = "Raio da Aura", Min = 20, Max = 400, Increment = 10, Default = 120, Flag = "AuraRange" })
Combat:AddToggle({ Name = "Multi-hit", Description = "Repete o hit no mesmo alvo", Flag = "MultiHit", Default = false })

Combat:AddSection("Haki e skills")
Combat:AddToggle({ Name = "Auto Buso", Flag = "AutoBuso", Default = true })
Combat:AddToggle({ Name = "Auto Ken", Flag = "AutoKen", Default = false })
Combat:AddToggle({ Name = "Auto Skills (Z X C V)", Flag = "AutoSkills", Default = false })
Combat:AddSlider({ Name = "Intervalo das skills", Min = 0.2, Max = 5, Increment = 0.1, Default = 1, Flag = "SkillDelay" })

--=====================================================================
--  ABA RAID
--=====================================================================
Raid:AddSection("Chip")
Raid:AddDropdown({ Name = "Chip selecionado", Options = CHIPS, Default = "Basic Raid Microchip", Flag = "RaidChip" })
Raid:AddSlider({ Name = "Ilha", Min = 1, Max = 5, Increment = 1, Default = 1, Flag = "RaidIsland" })
Raid:AddButton({ Name = "Comprar chip", Callback = function()
	buyChip(str("RaidChip", "Basic Raid Microchip"))
end })
Raid:AddButton({ Name = "Iniciar raid", Callback = function()
	startRaid(str("RaidChip", "Basic Raid Microchip"), num("RaidIsland", 1))
end })

Raid:AddSection("Automacao")
Raid:AddToggle({ Name = "Auto Comprar Chip", Flag = "AutoBuyChip", Default = false })
Raid:AddToggle({ Name = "Auto Start Raid", Flag = "AutoStartRaid", Default = false })
Raid:AddToggle({ Name = "Auto Limpar Raid", Description = "Mata mobs e boss da raid", Flag = "AutoClearRaid", Default = false })
Raid:AddToggle({ Name = "Auto Sair da Raid", Description = "Sai quando termina", Flag = "AutoLeaveRaid", Default = false })
Raid:AddButton({ Name = "Sair da raid agora", Callback = function()
	pcall(function()
		CommF:InvokeServer("RaidsInfo", "Leave")
	end)
end })

--=====================================================================
--  ABA QUESTS
--=====================================================================
Quests:AddSection("Race")
for _, entry in ipairs(QD.Race) do
	Quests:AddButton({ Name = "TP · " .. entry.name, Callback = function()
		if SEA < entry.sea then
			notify("Quest", "Precisa do Sea " .. entry.sea .. ".")
			return
		end
		teleport(entry.npc, num("TweenSpeed", 360))
	end })
end

Quests:AddSection("Espadas")
Quests:AddDropdown({
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
	Default = "",
	Flag = "SwordTarget",
})
Quests:AddToggle({ Name = "Auto Farm da espada", Description = "Mata o boss e pega o drop", Flag = "AutoSword", Default = false })

Quests:AddSection("Estilos de luta")
Quests:AddDropdown({
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
	Default = "",
	Flag = "StyleTarget",
})
Quests:AddButton({ Name = "Comprar estilo", Callback = function()
	local entry
	for _, e in ipairs(QD.Style) do
		if e.name == str("StyleTarget", "") then
			entry = e
			break
		end
	end
	if not entry then
		notify("Estilo", "Selecione um estilo.")
		return
	end
	teleport(entry.npc, num("TweenSpeed", 360))
	task.wait(1.2)
	pcall(function()
		CommF:InvokeServer("BuyFightingStyle", entry.id)
	end)
	notify("Estilo", "Tentativa de compra: " .. entry.name)
end })

Quests:AddSection("Coleta de item")
Quests:AddToggle({ Name = "Auto Coletar Item", Description = "Pega espadas/ferramentas no chao", Flag = "AutoItem", Default = false })
Quests:AddToggle({ Name = "ESP Item", Flag = "EspItem", Default = false })

--=====================================================================
--  ABA PROGRESSAO
--=====================================================================
Stats:AddSection("Distribuicao de pontos")
for _, statName in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
	Stats:AddToggle({
		Name = "Auto " .. statName,
		Flag = "Stat_" .. statName,
		Default = (statName == "Melee" or statName == "Defense"),
	})
end
Stats:AddToggle({ Name = "Auto Stats", Description = "Gasta pontos nos ativos", Flag = "AutoStats", Default = false })
Stats:AddButton({ Name = "Gastar todos os pontos agora", Callback = function()
	local data = LocalPlayer:FindFirstChild("Data")
	local points = data and data:FindFirstChild("Points")
	if not points then
		return
	end
	local guard = 0
	while points.Value > 0 and guard < 500 do
		guard = guard + 1
		local done = false
		for _, statName in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
			if on("Stat_" .. statName) and points.Value > 0 then
				CommF:InvokeServer("AddPoint", statName, 1)
				done = true
				task.wait(0.1)
			end
		end
		if not done then
			break
		end
	end
	notify("Stats", "Pontos distribuidos.")
end })

Stats:AddSection("Haki")
Stats:AddButton({ Name = "Comprar Buso Haki", Callback = function()
	pcall(function()
		CommF:InvokeServer("BuyHaki", "Buso")
	end)
end })
Stats:AddButton({ Name = "Comprar Ken Haki", Callback = function()
	pcall(function()
		CommF:InvokeServer("BuyHaki", "Geppo")
		CommF:InvokeServer("BuyHaki", "Soru")
	end)
end })

--=====================================================================
--  ABA VIAGEM
--=====================================================================
Travel:AddSection("Ilhas")

local function islandList()
	local out = {}
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	if not locations then
		return out
	end
	for _, loc in ipairs(locations:GetChildren()) do
		if loc:IsA("BasePart") and loc.Name ~= "Sea" then
			table.insert(out, loc.Name)
		end
	end
	table.sort(out)
	return out
end

local islandDrop = Travel:AddDropdown({
	Name = "Ilha",
	Options = {},
	Default = "",
	Flag = "IslandTarget",
})

local function refreshIslands()
	local names = islandList()
	local keep = str("IslandTarget", "")
	pcall(function()
		islandDrop:Clear()
	end)
	if #names > 0 then
		pcall(function()
			islandDrop:Add(table.unpack(names))
		end)
	end
	if keep ~= "" and islandDrop.Select then
		pcall(function()
			islandDrop:Select(keep)
		end)
	end
end
refreshIslands()
task.delay(5, refreshIslands)

Travel:AddButton({ Name = "Teleportar para ilha", Callback = function()
	local name = str("IslandTarget", "")
	if name == "" then
		notify("Viagem", "Selecione uma ilha.")
		refreshIslands()
		return
	end
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	local loc = locations and locations:FindFirstChild(name)
	if loc and loc:IsA("BasePart") then
		teleport(loc.CFrame * CFrame.new(0, 20, 0), 520)
	else
		notify("Viagem", "Ilha nao encontrada. Atualize a lista.")
		refreshIslands()
	end
end })
Travel:AddButton({ Name = "Atualizar lista", Callback = refreshIslands })

Travel:AddSection("Quest")
Travel:AddButton({ Name = "Ir ao NPC da quest", Callback = function()
	local q = resolveQuest()
	if q then
		teleport(q.npc, num("TweenSpeed", 360))
	end
end })
Travel:AddButton({ Name = "Ir ao mob da quest", Callback = function()
	local q = resolveQuest()
	if q and q.spawns[1] then
		teleport(q.spawns[1] + Vector3.new(0, 25, 0), num("TweenSpeed", 360))
	end
end })

Travel:AddSection("Sea")
Travel:AddButton({ Name = "Ir para Sea 2 (via portal)", Callback = function()
	pcall(function()
		CommF:InvokeServer("TravelDressrosa")
	end)
end })
Travel:AddButton({ Name = "Ir para Sea 3 (via portal)", Callback = function()
	pcall(function()
		CommF:InvokeServer("TravelZou")
	end)
end })

--=====================================================================
--  ABA VISUAL
--=====================================================================
Visual:AddSection("ESP")
Visual:AddToggle({ Name = "ESP Fruta", Flag = "EspFruit", Default = false })
Visual:AddToggle({ Name = "ESP Bau", Flag = "EspChest", Default = false })
Visual:AddToggle({ Name = "ESP Boss", Flag = "EspBoss", Default = false })
Visual:AddToggle({ Name = "ESP Jogador", Flag = "EspPlayer", Default = false })
Visual:AddSlider({ Name = "Distancia maxima do ESP", Min = 50, Max = 1500, Increment = 50, Default = 300, Flag = "EspDistance" })
Visual:AddToggle({ Name = "Notificador de Fruta", Description = "Avisa fruta no servidor", Flag = "FruitNotify", Default = false })

Visual:AddSection("Cena")
Visual:AddToggle({ Name = "Fullbright", Flag = "Fullbright", Default = false })
Visual:AddToggle({ Name = "Sem neblina", Flag = "NoFog", Default = false })
Visual:AddToggle({ Name = "FPS Boost", Description = "Remove sombras globais", Flag = "FpsBoost", Default = false })

--=====================================================================
--  ABA DIVERSOS
--=====================================================================
Misc:AddSection("Jogador")
Misc:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 400, Increment = 1, Default = 16, Flag = "WalkSpeed" })
Misc:AddSlider({ Name = "JumpPower", Min = 50, Max = 400, Increment = 1, Default = 50, Flag = "JumpPower" })
Misc:AddSlider({ Name = "Tween Speed", Min = 100, Max = 900, Increment = 10, Default = 360, Flag = "TweenSpeed" })
Misc:AddToggle({ Name = "Fly", Flag = "Fly", Default = false })
Misc:AddToggle({ Name = "NoClip", Flag = "Noclip", Default = false })
Misc:AddToggle({ Name = "Pulo infinito", Flag = "InfJump", Default = false })
Misc:AddToggle({ Name = "Anti-AFK", Flag = "AntiAfk", Default = true })

Misc:AddSection("Servidor")
Misc:AddToggle({ Name = "Auto Rejoin", Flag = "AutoRejoin", Default = false })
Misc:AddButton({ Name = "Rejoin", Callback = function()
	pcall(function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
end })
Misc:AddButton({ Name = "Servidor novo", Callback = function()
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

local statusOpt = Misc:AddParagraph("Status", "carregando...")

--=====================================================================
--  ABA CONFIG
--=====================================================================
Config:AddSection("Interface")

local themes = { "Darker" }
pcall(function()
	local list = Library:GetThemes()
	if type(list) == "table" and #list > 0 then
		themes = list
	end
end)

Config:AddDropdown({
	Name = "Tema",
	Options = themes,
	Default = themes[1] or "Darker",
	Flag = "UiTheme",
	Callback = function(v)
		pcall(function()
			Library:SetTheme(v)
		end)
	end,
})
Config:AddSlider({
	Name = "Escala",
	Min = 0.6,
	Max = 1.6,
	Increment = 0.05,
	Default = 1,
	Flag = "UiScale",
	Callback = function(v)
		pcall(function()
			Library:SetUIScale(v)
		end)
	end,
})
Config:AddParagraph("Esconder UI", "RightShift, ou o botao de minimizar")

Config:AddSection("Flags")
Config:AddButton({ Name = "Salvar agora", Callback = function()
	setFlag("_save", os.time())
	notify("Config", "Flags salvas em VeniceHub.")
end })
Config:AddButton({ Name = "Limpar flags", Callback = function()
	pcall(function()
		Window:DeleteFlags()
	end)
	notify("Config", "Flags apagadas. Reexecute para aplicar.")
end })
Config:AddButton({ Name = "Limpar cache da UI", Callback = function()
	if delfile then
		pcall(delfile, "GoldUI.luau")
		notify("Config", "Cache removido. Reexecute para baixar a versao do repo.")
	else
		notify("Config", "Executor sem delfile.")
	end
end })

Config:AddSection("Sessao")
Config:AddButton({ Name = "Descarregar hub", Callback = function()
	Dead = true
	pcall(function()
		Library:Destroy()
	end)
end })

--=====================================================================
--  LOOPS
--=====================================================================
-- ataque / kill aura
task.spawn(function()
	while task.wait(0.1) do
		local aura = on("KillAura")
		if aura or on("FastAttack") then
			pcall(function()
				if on("FastAttack") then
					equipType(str("WeaponType", "Melee"))
				end
				if aura then
					attack(num("AuraRange", 120))
					if on("MultiHit") then
						attack(num("AuraRange", 120))
					end
				end
			end)
			if on("FastAttack") then
				task.wait(num("AttackDelay", 0) / 1000)
			end
		end
	end
end)

-- skills
task.spawn(function()
	local last = 0
	while task.wait(0.2) do
		if on("AutoSkills") and os.clock() - last >= num("SkillDelay", 1) then
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

-- bring mobs
task.spawn(function()
	while task.wait(0.35) do
		if on("BringMob") and (on("AutoFarm") or on("AutoBoss") or on("AutoBone") or on("AutoMaterial") or on("AutoElite")) then
			pcall(bringMobs)
		end
	end
end)

-- haki
task.spawn(function()
	while task.wait(0.4) do
		pcall(function()
			if on("AutoBuso") then
				local char = getChar()
				if char and not char:FindFirstChild("HasBuso") then
					CommF:InvokeServer("Buso")
				end
			end
			if on("AutoKen") and CommE then
				CommE:FireServer("Ken", true)
			end
		end)
	end
end)

-- velocidade
task.spawn(function()
	while task.wait(0.8) do
		pcall(function()
			local char = getChar()
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = num("WalkSpeed", 16)
				hum.UseJumpPower = true
				hum.JumpPower = num("JumpPower", 50)
			end
		end)
	end
end)

-- AUTO FARM
task.spawn(function()
	while task.wait(0.45) do
		if not on("AutoFarm") then
			State.FarmMob = nil
			continue
		end
		pcall(function()
			local _, hrp = getChar()
			if not hrp then
				return
			end
			local q = resolveQuest()
			if not q then
				return
			end

			local expected = normalize(q.mob)
			if State.FarmMob and State.FarmMob ~= expected then
				State.FarmMob = nil
			end

			local visible, text = questText()
			if visible then
				local matches = q.mob ~= "" and string.find(text, q.mob, 1, true) ~= nil
				if not matches and q.display ~= "" and string.find(text, q.display, 1, true) then
					matches = true
				end
				if not matches and os.clock() - State.QuestGrace > 4 then
					CommF:InvokeServer("AbandonQuest")
					return
				end
				if matches then
					local target = findMob(q.display, q.mob)
					if target then
						killMob(target)
					elseif q.spawns[1] then
						teleport(q.spawns[1] + Vector3.new(0, 25, 0), num("TweenSpeed", 360))
					end
				end
			else
				if (q.npc.Position - hrp.Position).Magnitude > num("FarmDistance", 25) then
					teleport(q.npc, num("TweenSpeed", 360))
				else
					State.QuestGrace = os.clock()
					CommF:InvokeServer("StartQuest", q.quest, q.level)
					task.wait(0.6)
				end
			end
		end)
	end
end)

-- auto boss
task.spawn(function()
	while task.wait(0.4) do
		if not on("AutoBoss") then
			continue
		end
		pcall(function()
			local boss = str("BossSelect", "")
			if boss == "" then
				return
			end
			local enemies = Workspace:FindFirstChild("Enemies")
			local target = enemies and enemies:FindFirstChild(boss)
			local hum = target and target:FindFirstChildOfClass("Humanoid")
			if target and target:FindFirstChild("HumanoidRootPart") and hum and hum.Health > 0 then
				killMob(target, CFrame.new(0, 30, 10))
			else
				local tpl = ReplicatedStorage:FindFirstChild(boss)
				if tpl and tpl:FindFirstChild("HumanoidRootPart") then
					teleport(tpl.HumanoidRootPart.CFrame * CFrame.new(5, 15, 5), num("TweenSpeed", 360))
				end
			end
		end)
	end
end)

-- auto material
task.spawn(function()
	while task.wait(0.4) do
		if not on("AutoMaterial") then
			continue
		end
		pcall(function()
			local mobName = str("MaterialMob", "")
			if mobName == "" then
				return
			end
			local target = findMob(mobName, mobName)
			if target then
				killMob(target)
			else
				local pts = spawnPoints(mobName)
				if pts[1] then
					teleport(pts[1] + Vector3.new(0, 25, 0), num("TweenSpeed", 360))
				end
			end
		end)
	end
end)

-- auto bau
task.spawn(function()
	while task.wait(0.35) do
		if not on("AutoChest") then
			continue
		end
		pcall(function()
			local _, hrp = getChar()
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
			if bestDist > 12 then
				teleport(CFrame.new(best:GetPivot().Position + Vector3.new(0, 3, 0)), 620)
			else
				fireTouch(best)
				State.SeenChest[best] = true
			end
		end)
	end
end)

-- auto fruta
task.spawn(function()
	while task.wait(0.4) do
		if not on("AutoFruit") then
			continue
		end
		pcall(function()
			local _, hrp = getChar()
			if not hrp then
				return
			end
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
					local pos = obj.Handle.Position
					if (pos - hrp.Position).Magnitude > 12 then
						teleport(CFrame.new(pos + Vector3.new(0, 4, 0)), 700)
					else
						fireTouch(obj.Handle)
					end
					break
				end
			end
		end)
	end
end)

-- bone farm
task.spawn(function()
	while task.wait(0.45) do
		if not on("AutoBone") then
			continue
		end
		pcall(function()
			local enemies = Workspace:FindFirstChild("Enemies")
			if enemies then
				for _, n in ipairs({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }) do
					local m = enemies:FindFirstChild(n)
					local hum = m and m:FindFirstChildOfClass("Humanoid")
					if m and m:FindFirstChild("HumanoidRootPart") and hum and hum.Health > 0 then
						killMob(m)
						return
					end
				end
			end
			teleport(CFrame.new(-9516.99, 172.01, 6078.46), num("TweenSpeed", 360))
		end)
	end
end)

-- elite
task.spawn(function()
	while task.wait(0.5) do
		if not on("AutoElite") then
			continue
		end
		pcall(function()
			local enemies = Workspace:FindFirstChild("Enemies")
			if not enemies then
				return
			end
			for _, mob in ipairs(enemies:GetChildren()) do
				local hum = mob:FindFirstChildOfClass("Humanoid")
				if string.find(mob.Name, "Elite") and mob:FindFirstChild("HumanoidRootPart") and hum and hum.Health > 0 then
					killMob(mob)
					return
				end
			end
		end)
	end
end)

-- auto espada
task.spawn(function()
	while task.wait(0.4) do
		if not on("AutoSword") then
			continue
		end
		pcall(function()
			local entry
			for _, e in ipairs(QD.Sword) do
				if e.name == str("SwordTarget", "") then
					entry = e
					break
				end
			end
			if not entry then
				return
			end
			if not killBossLoop(entry.boss) then
				teleport(entry.npc, num("TweenSpeed", 360))
			end
			local _, hrp = getChar()
			if hrp then
				for _, obj in ipairs(Workspace:GetChildren()) do
					if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
						if (obj.Handle.Position - hrp.Position).Magnitude < 20 then
							fireTouch(obj.Handle)
						end
					end
				end
			end
		end)
	end
end)

-- auto item
task.spawn(function()
	while task.wait(0.4) do
		if not on("AutoItem") then
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
			else
				fireTouch(best.Handle)
			end
		end)
	end
end)

-- raid start
task.spawn(function()
	while task.wait(1) do
		if not on("AutoStartRaid") then
			continue
		end
		pcall(function()
			if raidActive() then
				return
			end
			local chip = chipInBackpack()
			if not chip then
				if on("AutoBuyChip") then
					buyChip(str("RaidChip", "Basic Raid Microchip"))
				end
				return
			end
			startRaid(chip.Name, num("RaidIsland", 1))
		end)
	end
end)

-- raid clear
task.spawn(function()
	while task.wait(0.35) do
		if not on("AutoClearRaid") then
			continue
		end
		pcall(function()
			if not raidActive() then
				if on("AutoLeaveRaid") and not chipInBackpack() then
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
					teleport(island.CFrame + Vector3.new(0, 30, 0), num("TweenSpeed", 360))
				end
			end
		end)
	end
end)

-- auto stats
task.spawn(function()
	while task.wait(1) do
		if not on("AutoStats") then
			continue
		end
		pcall(function()
			local data = LocalPlayer:FindFirstChild("Data")
			local points = data and data:FindFirstChild("Points")
			if points and points.Value > 0 then
				for _, statName in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
					if on("Stat_" .. statName) and points.Value > 0 then
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
	while task.wait(0.2) do
		local char, hrp = getChar()
		if on("Fly") and hrp then
			if not bv then
				bv = new("BodyVelocity", { MaxForce = Vector3.new(1, 1, 1) * 1e5, Parent = hrp })
				bg = new("BodyGyro", { MaxTorque = Vector3.new(1, 1, 1) * 1e5, P = 1200, D = 60, Parent = hrp })
			end
			local cam = Workspace.CurrentCamera
			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then
				dir = dir + cam.CFrame.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.S) then
				dir = dir - cam.CFrame.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.A) then
				dir = dir - cam.CFrame.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) then
				dir = dir + cam.CFrame.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then
				dir = dir + Vector3.yAxis
			end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
				dir = dir - Vector3.yAxis
			end
			bv.Velocity = dir.Magnitude > 0 and dir.Unit * num("WalkSpeed", 16) * 3 or Vector3.zero
			bg.CFrame = cam.CFrame
		elseif bv then
			stopFly()
		end
	end
end)

-- utilidades
UIS.JumpRequest:Connect(function()
	if on("InfJump") then
		local char = getChar()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- noclip (com restauracao)
local noclipWas = false
local noclipFrame = 0
RunService.Stepped:Connect(function()
	local active = on("Noclip")
	local char = getChar()
	if not active then
		if noclipWas and char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
		noclipWas = false
		return
	end
	noclipFrame = noclipFrame + 1
	if noclipFrame % 3 ~= 0 then
		return
	end
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
		noclipWas = true
	end
end)

LocalPlayer.Idled:Connect(function()
	if not on("AntiAfk") then
		return
	end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- cena
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			Lighting.FogEnd = on("NoFog") and 1e6 or 100000
			Lighting.Brightness = on("Fullbright") and 3 or 2
			Lighting.Ambient = on("Fullbright") and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(70, 70, 70)
			if on("Fullbright") then
				Lighting.ClockTime = 12
			end
			Lighting.GlobalShadows = not on("FpsBoost")
		end)
	end
end)

-- status
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			local data = LocalPlayer:FindFirstChild("Data")
			local beli = data and data:FindFirstChild("Beli")
			statusOpt:SetDescription(string.format("Sea %d · LV %d · $%s", SEA, getLevel(), comma(beli and beli.Value or 0)))
		end)
	end
end)

-- poda de tabelas
task.spawn(function()
	while task.wait(20) do
		for chest in pairs(State.SeenChest) do
			if not chest.Parent then
				State.SeenChest[chest] = nil
			end
		end
		for fruit in pairs(State.SeenFruit) do
			if not fruit.Parent then
				State.SeenFruit[fruit] = nil
			end
		end
	end
end)

--=====================================================================
--  ESP (com distancia)
--=====================================================================
local EspPool = {}

local function espRemove(part)
	local entry = EspPool[part]
	if entry then
		if entry.bb then
			entry.bb:Destroy()
		end
		EspPool[part] = nil
	end
end

local function espClear()
	for part in pairs(EspPool) do
		espRemove(part)
	end
end

local function espMark(part, label, color, dist, live)
	if not part or not part.Parent then
		return
	end
	local entry = EspPool[part]
	if not entry then
		local bb = new("BillboardGui", {
			Name = "GGBloxEsp",
			Size = UDim2.fromOffset(180, 26),
			StudsOffset = Vector3.new(0, 3, 0),
			AlwaysOnTop = true,
			Parent = part,
		})
		local text = new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSansBold,
			TextSize = 11,
			TextStrokeTransparency = 0.3,
			TextColor3 = color,
			Parent = bb,
		})
		entry = { bb = bb, label = text }
		EspPool[part] = entry
	end
	entry.label.Text = string.format("%s [%dm]", label, math.floor(dist / 3 + 0.5))
	entry.label.TextColor3 = color
	live[part] = true
end

task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			local any = on("EspFruit") or on("EspItem") or on("EspChest") or on("EspBoss") or on("EspPlayer")
			if not any then
				if next(EspPool) then
					espClear()
				end
				return
			end

			local _, hrp = getChar()
			if not hrp then
				espClear()
				return
			end

			local maxDist = num("EspDistance", 300)
			local live = {}
			local origin = hrp.Position

			local function consider(part, label, color)
				if not part or not part.Parent then
					return
				end
				local d = (part.Position - origin).Magnitude
				if d <= maxDist then
					espMark(part, label, color, d, live)
				end
			end

			if on("EspFruit") or on("EspItem") then
				for _, obj in ipairs(Workspace:GetChildren()) do
					if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
						consider(obj.Handle, obj.Name, Color3.fromRGB(255, 200, 90))
					end
				end
			end

			if on("EspChest") then
				for _, chest in ipairs(CollectionService:GetTagged("_ChestTagged")) do
					local ok, pos = pcall(function()
						return chest:GetPivot().Position
					end)
					if ok and (pos - origin).Magnitude <= maxDist then
						local part = chest:IsA("BasePart") and chest or chest:FindFirstChildWhichIsA("BasePart")
						if part then
							espMark(part, "BAU", Color3.fromRGB(120, 255, 200), (pos - origin).Magnitude, live)
						end
					end
				end
			end

			if on("EspBoss") then
				local enemies = Workspace:FindFirstChild("Enemies")
				for _, mob in ipairs(enemies and enemies:GetChildren() or {}) do
					local hum = mob:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 and not string.find(mob.Name, "[Lv", 1, true) then
						consider(mob:FindFirstChild("HumanoidRootPart"), mob.Name, Color3.fromRGB(255, 90, 90))
					end
				end
			end

			if on("EspPlayer") then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= LocalPlayer and plr.Character then
						consider(plr.Character:FindFirstChild("HumanoidRootPart"), plr.Name, Color3.fromRGB(150, 200, 255))
					end
				end
			end

			for part in pairs(EspPool) do
				if not live[part] or not part.Parent then
					espRemove(part)
				end
			end
		end)
	end
end)

-- notificador de fruta
task.spawn(function()
	while task.wait(2) do
		if not on("FruitNotify") then
			continue
		end
		pcall(function()
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj:IsA("Tool") and obj:FindFirstChild("Handle") and not State.SeenFruit[obj] then
					State.SeenFruit[obj] = true
					local pos = obj.Handle.Position
					notify("Fruta encontrada", string.format("%s em (%.0f, %.0f, %.0f)", obj.Name, pos.X, pos.Y, pos.Z))
				end
			end
		end)
	end
end)

-- auto rejoin
task.spawn(function()
	while task.wait(2) do
		if on("AutoRejoin") and not LocalPlayer.Parent then
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end
	end
end)

Window:Notify({
	Title = "GG Blox v2.8",
	Content = "Carregado · Sea " .. SEA .. " · RightShift minimiza",
	Duration = 6,
})
