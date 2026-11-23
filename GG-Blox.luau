repeat task.wait() until game:IsLoaded()

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")
local CoreGui           = game:GetService("CoreGui")

local LP = Players.LocalPlayer
repeat task.wait() until LP and LP:FindFirstChild("PlayerGui")
local PGui = LP:WaitForChild("PlayerGui")

local SafeParent = (gethui and gethui())
	or (syn and syn.protect_gui and (function()
		local f = Instance.new("Folder")
		syn.protect_gui(f)
		f.Parent = CoreGui
		return f
	end)())
	or PGui

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local CurrentSea = 1
if game.PlaceId == 4442272183 then
	CurrentSea = 2
elseif game.PlaceId == 7449423635 then
	CurrentSea = 3
end

-- ════════════════════════════════════════
--  REMOTES
-- ════════════════════════════════════════
local R = {}
pcall(function()
	local rf = ReplicatedStorage:WaitForChild("Remotes", 5)
	if not rf then return end
	for _, name in ipairs({
		"CommF_", "CommE", "Stats", "Redeem", "Leviathan",
		"Temple", "Chest", "CollectBlueEmber"
	}) do
		R[name] = rf:FindFirstChild(name)
	end

	local mod = ReplicatedStorage:FindFirstChild("Modules")
	if mod then
		local net = mod:FindFirstChild("Net")
		if net then
			for _, name in ipairs({
				"RE/RegisterAttack", "RE/RegisterHit",
				"RF/KitsuneStatuePray", "RE/TouchKitsuneStatue"
			}) do
				R[name] = net:FindFirstChild(name)
			end
		end
	end

	local ev = ReplicatedStorage:FindFirstChild("Events")
	if ev then
		R.ActivateRaceV4 = ev:FindFirstChild("ActivateRaceV4")
		R.UsedRaceSkill  = ev:FindFirstChild("UsedRaceSkill")
	end
end)

local function CF_(method, ...)
	if R.CommF_ then
		return R.CommF_:InvokeServer(method, ...)
	end
end

-- ════════════════════════════════════════
--  ESTADO GLOBAL
-- ════════════════════════════════════════
local ST = {
	-- Farm Level
	AutoFarmLevel     = false,
	WeaponType        = "Melee",
	FastAttack        = true,
	BringMob          = true,
	BringMobDist      = 350,
	FarmDist          = 20,
	AutoBuso          = true,
	-- Mob/Boss livre
	SelectedMob       = "",
	AutoFarmMob       = false,
	SelectedBoss      = "The Gorilla King",
	AutoFarmBoss      = false,
	-- Rương
	AutoChest         = false,
	ChestCount        = 0,
	-- Stats
	AutoStats         = false,
	StatChunk         = 3,
	StatsMap          = { Melee = true, Defense = true, Sword = false, Gun = false, ["Demon Fruit"] = false },
	-- ESP
	ESP_Players       = false,
	ESP_Chests        = false,
	ESP_Fruits        = false,
	ESP_Mobs          = false,
	-- Movimento
	WalkSpeed         = 16,
	JumpPower         = 50,
	Noclip            = false,
	InfiniteJump      = false,
	AntiAFK           = true,
	FPSBoost          = false,
	TweenSpeed        = 260,
	-- Skills
	AutoSkillZ        = false,
	AutoSkillX        = false,
	AutoSkillC        = false,
	AutoSkillV        = false,
	-- Fruit
	AutoSnipeFruit    = false,
	AutoStoreFruit    = false,
	-- Bartilo Quest
	AutoBartilo       = false,
	-- Rainbow Haki
	AutoRainbowHaki   = false,
	-- Race Quests
	AutoRaceQuest     = false,
	RaceType          = "Human",
	-- Berry
	AutoCollectBerry  = false,
	-- Haki recipientes
	AutoHakiContainer = false,
	-- Missão Colosseum
	AutoColosseum     = false,
	-- Eventos
	AutoCollectEmbers = false,
	AutoPrayStatue    = false,
	AutoAwakenV4      = false,
	AutoUseRaceSkill  = false,
	AutoMirageGear    = false,
	-- Sea
	AutoLeviathan     = false,
	AutoSeaBeast      = false,
	AutoShipRaid      = false,
	-- Shop — compras
	ShopBuySword      = false,
	ShopSwordName     = "Cutlass",
	ShopBuyAccessory  = false,
	ShopAccessoryName = "Warrior Helmet",
	ShopBuyFruitSlot  = false,
	-- Webhook
	EnableWebhook     = false,
	WebhookURL        = "",
	WebhookFile       = "BFScript_Webhook.txt",
}

if isfile and readfile then
	pcall(function()
		if isfile(ST.WebhookFile) then
			local u = readfile(ST.WebhookFile)
			if type(u) == "string" and #u:gsub("%s+", "") > 15 then
				ST.WebhookURL = u:gsub("%s+", "")
				ST.EnableWebhook = true
			end
		end
	end)
end

-- Controle anti-duplicação de loops assíncronos
local LoopTokens = {}
local function NextToken(key)
	local n = (LoopTokens[key] or 0) + 1
	LoopTokens[key] = n
	return n
end
local function IsTokenValid(key, token)
	return LoopTokens[key] == token
end

-- ════════════════════════════════════════
--  DADOS DE QUESTS (1-2840)
-- ════════════════════════════════════════
local QuestsData = {
	{ Min = 1,    Max = 9,    Quest = "BanditQuest1",      Name = "Bandit",              Level = 1, NPC = CFrame.new(1060.9, 16.4, 1547.7),    MobCF = CFrame.new(1038.5, 41.2, 1576.5) },
	{ Min = 10,   Max = 14,   Quest = "JungleQuest",        Name = "Monkey",              Level = 1, NPC = CFrame.new(-1601.6, 36.8, 153.3),    MobCF = CFrame.new(-1448.1, 50.8, 63.6) },
	{ Min = 15,   Max = 29,   Quest = "JungleQuest",        Name = "Gorilla",             Level = 2, NPC = CFrame.new(-1601.6, 36.8, 153.3),    MobCF = CFrame.new(-1142.6, 40.4, 515.3) },
	{ Min = 30,   Max = 39,   Quest = "BuggyQuest1",        Name = "Pirate",              Level = 1, NPC = CFrame.new(-1140.1, 4.7, 3827.4),    MobCF = CFrame.new(-1201.0, 40.6, 3857.5) },
	{ Min = 40,   Max = 59,   Quest = "BuggyQuest1",        Name = "Brute",               Level = 2, NPC = CFrame.new(-1140.1, 4.7, 3827.4),    MobCF = CFrame.new(-1387.5, 24.5, 4100.9) },
	{ Min = 60,   Max = 74,   Quest = "DesertQuest",        Name = "Desert Bandit",       Level = 1, NPC = CFrame.new(896.5, 6.4, 4390.1),     MobCF = CFrame.new(984.9, 16.1, 4417.9) },
	{ Min = 75,   Max = 89,   Quest = "DesertQuest",        Name = "Desert Officer",      Level = 2, NPC = CFrame.new(896.5, 6.4, 4390.1),     MobCF = CFrame.new(1547.1, 14.4, 4381.8) },
	{ Min = 90,   Max = 99,   Quest = "SnowQuest",          Name = "Snow Bandit",         Level = 1, NPC = CFrame.new(1386.8, 87.2, 1298.3),   MobCF = CFrame.new(1356.3, 105.7, 1328.2) },
	{ Min = 100,  Max = 119,  Quest = "SnowQuest",          Name = "Snowman",             Level = 2, NPC = CFrame.new(1386.8, 87.2, 1298.3),   MobCF = CFrame.new(1218.7, 138.0, 1488.0) },
	{ Min = 120,  Max = 149,  Quest = "MarineQuest2",       Name = "Chief Petty Officer", Level = 1, NPC = CFrame.new(-5035.4, 28.6, 4324.1),  MobCF = CFrame.new(-4931.1, 65.7, 4121.8) },
	{ Min = 150,  Max = 174,  Quest = "SkyQuest",           Name = "Sky Bandit",          Level = 1, NPC = CFrame.new(-4842.1, 717.6, 2623.0),  MobCF = CFrame.new(-4955.6, 365.4, 2908.1) },
	{ Min = 175,  Max = 189,  Quest = "SkyQuest",           Name = "Dark Master",         Level = 2, NPC = CFrame.new(-4842.1, 717.6, 2623.0),  MobCF = CFrame.new(-5148.1, 439.0, 2332.9) },
	{ Min = 190,  Max = 209,  Quest = "PrisonerQuest",      Name = "Prisoner",            Level = 1, NPC = CFrame.new(5310.6, 0.3, 474.9),     MobCF = CFrame.new(4937.3, 0.3, 649.5) },
	{ Min = 210,  Max = 249,  Quest = "PrisonerQuest",      Name = "Dangerous Prisoner",  Level = 2, NPC = CFrame.new(5310.6, 0.3, 474.9),     MobCF = CFrame.new(5099.6, 0.3, 1055.7) },
	{ Min = 250,  Max = 274,  Quest = "ColosseumQuest",     Name = "Toga Warrior",        Level = 1, NPC = CFrame.new(-1577.7, 7.4, 2984.4),   MobCF = CFrame.new(-1872.5, 49.0, 2913.8) },
	{ Min = 275,  Max = 299,  Quest = "ColosseumQuest",     Name = "Gladiator",           Level = 2, NPC = CFrame.new(-1577.7, 7.4, 2984.4),   MobCF = CFrame.new(-1521.3, 81.2, 3066.3) },
	{ Min = 300,  Max = 324,  Quest = "MagmaQuest",         Name = "Military Soldier",    Level = 1, NPC = CFrame.new(-5316.1, 12.2, 8517.0),  MobCF = CFrame.new(-5369.0, 61.2, 8556.4) },
	{ Min = 325,  Max = 374,  Quest = "MagmaQuest",         Name = "Military Spy",        Level = 2, NPC = CFrame.new(-5316.1, 12.2, 8517.0),  MobCF = CFrame.new(-5787.0, 75.8, 8651.6) },
	{ Min = 375,  Max = 399,  Quest = "FishmanQuest",       Name = "Fishman Warrior",     Level = 1, NPC = CFrame.new(61122.6, 18.4, 1569.3),  MobCF = CFrame.new(60844.1, 98.4, 1298.3), Entrance = Vector3.new(61163.8, 11.6, 1819.7) },
	{ Min = 400,  Max = 449,  Quest = "FishmanQuest",       Name = "Fishman Commando",    Level = 2, NPC = CFrame.new(61122.6, 18.4, 1569.3),  MobCF = CFrame.new(61738.3, 64.2, 1433.8), Entrance = Vector3.new(61163.8, 11.6, 1819.7) },
	{ Min = 450,  Max = 474,  Quest = "SkyExp1Quest",       Name = "God's Guard",         Level = 1, NPC = CFrame.new(-4721.8, 845.3, 1953.8),  MobCF = CFrame.new(-4628.0, 866.9, 1931.2), Entrance = Vector3.new(-4607.8, 872.5, -1667.5) },
	{ Min = 475,  Max = 524,  Quest = "SkyExp1Quest",       Name = "Shanda",              Level = 2, NPC = CFrame.new(-4721.8, 845.3, 1953.8),  MobCF = CFrame.new(-7680, 5560, -500),     Entrance = Vector3.new(-4607.8, 872.5, -1667.5) },
	{ Min = 525,  Max = 624,  Quest = "SkyExp2Quest",       Name = "Royal Squad",         Level = 1, NPC = CFrame.new(-7906, 5634, -1411),     MobCF = CFrame.new(-7600, 5600, -1450) },
	{ Min = 625,  Max = 649,  Quest = "FountainQuest",      Name = "Galley Pirate",       Level = 1, NPC = CFrame.new(5259, 37, 4050),         MobCF = CFrame.new(5590, 45, 3990) },
	{ Min = 650,  Max = 699,  Quest = "FountainQuest",      Name = "Galley Captain",      Level = 2, NPC = CFrame.new(5259, 37, 4050),         MobCF = CFrame.new(5650, 45, 4950) },
	-- Sea 2
	{ Min = 700,  Max = 724,  Quest = "Area1Quest",         Name = "Raider",              Level = 1, NPC = CFrame.new(-429, 72, 1836),          MobCF = CFrame.new(-730, 40, 2380) },
	{ Min = 725,  Max = 774,  Quest = "Area1Quest",         Name = "Mercenary",           Level = 2, NPC = CFrame.new(-429, 72, 1836),          MobCF = CFrame.new(-960, 75, 1750) },
	{ Min = 775,  Max = 799,  Quest = "Area2Quest",         Name = "Swan Pirate",         Level = 1, NPC = CFrame.new(638, 72, 918),            MobCF = CFrame.new(900, 120, 1200) },
	{ Min = 800,  Max = 874,  Quest = "Area2Quest",         Name = "Factory Staff",       Level = 2, NPC = CFrame.new(638, 72, 918),            MobCF = CFrame.new(295, 73, -55) },
	{ Min = 875,  Max = 899,  Quest = "MarineQuest3",       Name = "Marine Lieutenant",   Level = 1, NPC = CFrame.new(-2440, 72, -3217),      MobCF = CFrame.new(-2700, 75, -3000) },
	{ Min = 900,  Max = 949,  Quest = "MarineQuest3",       Name = "Marine Captain",      Level = 2, NPC = CFrame.new(-2440, 72, -3217),      MobCF = CFrame.new(-1900, 75, -3300) },
	{ Min = 950,  Max = 999,  Quest = "ZombieQuest",        Name = "Zombie",              Level = 1, NPC = CFrame.new(-5497, 48, -795),       MobCF = CFrame.new(-5650, 120, -750) },
	{ Min = 1000, Max = 1099, Quest = "SnowMountainQuest",  Name = "Snow Trooper",        Level = 1, NPC = CFrame.new(609, 401, -5372),       MobCF = CFrame.new(480, 420, -5600) },
	{ Min = 1100, Max = 1249, Quest = "ShipQuest1",         Name = "Ship Deckhand",       Level = 1, NPC = CFrame.new(1008, 125, 32911),      MobCF = CFrame.new(1180, 140, 32990) },
	{ Min = 1250, Max = 1499, Quest = "FrostQuest",         Name = "Sea Soldier",         Level = 1, NPC = CFrame.new(-3054, 237, -10145),    MobCF = CFrame.new(-3300, 240, -10400) },
	-- Sea 3
	{ Min = 1500, Max = 1574, Quest = "PiratePortQuest",    Name = "Pirate Millionaire",  Level = 1, NPC = CFrame.new(-289, 44, 5580),          MobCF = CFrame.new(-200, 45, 5900) },
	{ Min = 1575, Max = 1699, Quest = "PiratePortQuest",    Name = "Pistol Billionaire",  Level = 2, NPC = CFrame.new(-289, 44, 5580),          MobCF = CFrame.new(-400, 75, 5950) },
	{ Min = 1700, Max = 1824, Quest = "AmazonQuest",        Name = "Female Islander",     Level = 1, NPC = CFrame.new(5832, 51, -1100),       MobCF = CFrame.new(5400, 80, -1000) },
	{ Min = 1825, Max = 1974, Quest = "MarineTreeIsland",   Name = "Marine Commodore",    Level = 1, NPC = CFrame.new(2180, 28, -6740),       MobCF = CFrame.new(2450, 75, -6700) },
	{ Min = 1975, Max = 2074, Quest = "HauntedQuest1",      Name = "Reborn Skeleton",     Level = 1, NPC = CFrame.new(-9515, 142, 5536),      MobCF = CFrame.new(-8750, 140, 5900) },
	{ Min = 2075, Max = 2199, Quest = "HauntedQuest2",      Name = "Living Zombie",       Level = 1, NPC = CFrame.new(-9515, 142, 5536),      MobCF = CFrame.new(-10150, 140, 5950) },
	{ Min = 2200, Max = 2299, Quest = "CandyQuest1",        Name = "Candy Rebel",         Level = 1, NPC = CFrame.new(-1149, 13, -14445),     MobCF = CFrame.new(-1000, 20, -14200) },
	{ Min = 2300, Max = 2449, Quest = "CandyQuest2",        Name = "Sweet Thief",         Level = 1, NPC = CFrame.new(-1149, 13, -14445),     MobCF = CFrame.new(-1200, 20, -14700) },
	{ Min = 2450, Max = 2599, Quest = "TikiQuest1",         Name = "Isle Outlaw",         Level = 1, NPC = CFrame.new(-16547, 55, -172),      MobCF = CFrame.new(-16800, 30, -150) },
	{ Min = 2600, Max = 2840, Quest = "DragonDojoQuest",    Name = "Dojo Fighter",        Level = 1, NPC = CFrame.new(-16547, 55, -172),      MobCF = CFrame.new(-16300, 60, -350) },
}

-- ════════════════════════════════════════
--  DADOS DE MISSÕES ESPECIAIS
-- ════════════════════════════════════════
local BartiloData = {
	NPC_CF    = CFrame.new(315.9, 73.2, -1795.8),
	MobName   = "Galley Captain",
	MobCF     = CFrame.new(5650, 45, 4950),
	QuestKey  = "BartiloQuest",
	QuestLv   = 1,
	KillCount = 30,
}

local RainbowHakiData = {
	NPC_CF    = CFrame.new(-3268, 53, 2740),
	QuestKey  = "RainbowHakiQuest",
	MobName   = "Dojo Fighter",
	MobCF     = CFrame.new(-16300, 60, -350),
	KillCount = 20,
}

local ColosseumData = {
	NPC_CF   = CFrame.new(-1577.7, 7.4, 2984.4),
	MobNames = { "Toga Warrior", "Gladiator" },
	QuestKey = "ColosseumQuest",
}

local RaceQuestData = {
	Human = {
		Steps = {
			{ NPC = CFrame.new(1059, 15, 1550),    Task = "StartHumanStep1", MobName = "Gorilla",               MobCF = CFrame.new(-1142, 40, 515),    Kill = 10 },
			{ NPC = CFrame.new(-5035, 28, 4324),   Task = "StartHumanStep2", MobName = "Chief Petty Officer", MobCF = CFrame.new(-4931, 65, 4121),  Kill = 10 },
			{ NPC = CFrame.new(5259, 37, 4050),    Task = "StartHumanStep3", MobName = "Galley Captain",      MobCF = CFrame.new(5650, 45, 4950),   Kill = 10 },
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "FinishHumanRace", MobName = nil },
		}
	},
	Mink = {
		Steps = {
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "StartMinkStep1",  MobName = "Dojo Fighter",        MobCF = CFrame.new(-16300, 60, -350), Kill = 15 },
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "StartMinkStep2",  MobName = "Isle Outlaw",         MobCF = CFrame.new(-16800, 30, -150), Kill = 15 },
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "FinishMinkRace",  MobName = nil },
		}
	},
	Shark = {
		Steps = {
			{ NPC = CFrame.new(61122, 18, 1569),   Task = "StartSharkStep1", MobName = "Fishman Warrior",     MobCF = CFrame.new(60844, 98, 1298),  Kill = 10, Entrance = Vector3.new(61163, 11, 1819) },
			{ NPC = CFrame.new(61122, 18, 1569),   Task = "StartSharkStep2", MobName = "Fishman Commando",    MobCF = CFrame.new(61738, 64, 1433),  Kill = 10, Entrance = Vector3.new(61163, 11, 1819) },
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "FinishSharkRace", MobName = nil },
		}
	},
	Sky = {
		Steps = {
			{ NPC = CFrame.new(-4721, 845, 1953),  Task = "StartSkyStep1",   MobName = "God's Guard",         MobCF = CFrame.new(-4628, 866, 1931),  Kill = 10, Entrance = Vector3.new(-4607, 872, -1667) },
			{ NPC = CFrame.new(-7906, 5634, -1411),Task = "StartSkyStep2",   MobName = "Royal Squad",         MobCF = CFrame.new(-7600, 5600, -1450), Kill = 10 },
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "FinishSkyRace",   MobName = nil },
		}
	},
	Cyborg = {
		Steps = {
			{ NPC = CFrame.new(295, 73, -55),      Task = "StartCyborgStep1",MobName = "Factory Staff",       MobCF = CFrame.new(295, 73, -55),      Kill = 20 },
			{ NPC = CFrame.new(295, 73, -55),      Task = "StartCyborgStep2",MobName = "Swan Pirate",         MobCF = CFrame.new(900, 120, 1200),    Kill = 20 },
			{ NPC = CFrame.new(-3268, 53, 2740),   Task = "FinishCyborgRace",MobName = nil },
		}
	},
}

local ShopData = {
	Swords = {
		"Cutlass", "Dual Cutlass", "Iron Mace", "Triple Katana",
		"Bisento", "Pole (1st Form)", "Saber", "Dark Blade", "Yama",
		"Pole (2nd Form)", "Saddi", "Wando", "Hariharakesh",
		"Canvander", "Gravity Blade", "Cursed Dual Katana",
		"Tushita", "True Triple Katana", "Enma", "Dark Dagger",
		"Soul Cane", "Hallow Scythe", "Buddy Sword", "Shark Saw"
	},
	Accessories = {
		"Warrior Helmet", "Tomoe Ring", "Swan Glasses",
		"Lei", "Swordsman Hat", "Ghoul Mask",
		"Horned Helmet", "Christmas Hat", "Pilot Helmet",
		"Dark Coat", "Angel Wings", "Dragon Scales",
		"Trench Coat", "Norp Hat", "Cyborg Glasses",
		"Shark Tooth Necklace", "Spiked Mohawk", "Golden Crown"
	},
	FruitSlot = "FruitStorage",
}

local Waypoints = {
	["Windmill (Sea 1)"]      = CFrame.new(1059, 15, 1550),
	["Jungle"]                = CFrame.new(-1598, 35, 153),
	["Pirate Village"]        = CFrame.new(-1141, 4, 3831),
	["Desert"]                = CFrame.new(894, 5, 4392),
	["Frozen Village"]        = CFrame.new(1389, 85, -1298),
	["Marine Ford"]           = CFrame.new(-5039, 27, 4324),
	["Sky Island"]            = CFrame.new(-4839, 716, -2619),
	["Prison"]                = CFrame.new(5308, 0, 474),
	["Colosseum"]             = CFrame.new(-1580, 6, -2986),
	["Magma Island"]          = CFrame.new(-5313, 7, 8515),
	["Underwater City"]       = CFrame.new(61122, 17, 1569),
	["Fountain City"]         = CFrame.new(5259, 37, 4050),
	["Upper Sky (Sky Exp 1)"] = CFrame.new(-4721, 845, 1953),
	["Floating Turtle (S2)"]  = CFrame.new(-429, 72, 1836),
	["Hot & Cold (S2)"]       = CFrame.new(609, 401, -5372),
	["Mansion (S2)"]          = CFrame.new(-5497, 48, -795),
	["Mirage Island (S2)"]    = CFrame.new(1008, 125, 32911),
	["Pirate Port (S3)"]      = CFrame.new(-289, 44, 5580),
	["Amazon (S3)"]           = CFrame.new(5832, 51, -1100),
	["Haunted Castle (S3)"]   = CFrame.new(-9515, 142, 5536),
	["Candy Island (S3)"]     = CFrame.new(-1149, 13, -14445),
	["Tiki Outpost (S3)"]     = CFrame.new(-16547, 55, -172),
	["Dragon Dojo (S3)"]      = CFrame.new(-16300, 60, -350),
	["Rainbow Haki NPC"]      = CFrame.new(-3268, 53, 2740),
	["Temple of Time"]        = CFrame.new(28282, 14896, 102),
	["Kitsune Island"]        = CFrame.new(-22123, 22, -12345),
}

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function GetChar() return LP.Character end
local function GetHRP()
	local c = GetChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
	local c = GetChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetLevel()
	local d = LP:FindFirstChild("Data")
	return d and d:FindFirstChild("Level") and d.Level.Value or 1
end
local function GetBerry()
	local d = LP:FindFirstChild("Data")
	return d and d:FindFirstChild("Beli") and d.Beli.Value or 0
end
local function GetQuestData()
	local lv = GetLevel()
	for _, q in ipairs(QuestsData) do
		if lv >= q.Min and lv <= q.Max then
			return q
		end
	end
	return QuestsData[#QuestsData]
end
local function HasActiveQuest()
	local gui = PGui:FindFirstChild("Main")
	if not gui then return false end
	local qf = gui:FindFirstChild("Quest")
	return qf and qf.Visible or false
end

local function SafeTouch(hrp, part)
	if not hrp or not part or not part:IsA("BasePart") then return end
	if type(firetouchinterest) == "function" then
		pcall(function()
			firetouchinterest(hrp, part, 0)
			firetouchinterest(hrp, part, 1)
		end)
	end
end

-- ════════════════════════════════════════
--  SAFETWEEN & FLY ANCHOR
-- ════════════════════════════════════════
local curTween, tweenDest
local function SafeTween(targetCF, spd)
	local hrp = GetHRP()
	if not hrp or typeof(targetCF) ~= "CFrame" then return end
	local speed = math.max(tonumber(spd) or ST.TweenSpeed or 260, 50)
	local dist = (hrp.Position - targetCF.Position).Magnitude
	if dist <= 10 then
		hrp.CFrame = targetCF
		return
	end
	if tweenDest and (tweenDest.Position - targetCF.Position).Magnitude < 8 and curTween then
		return
	end
	if curTween then
		pcall(function() curTween:Cancel() end)
		curTween = nil
	end
	tweenDest = targetCF
	local ti = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
	curTween = TweenService:Create(hrp, ti, { CFrame = targetCF })
	curTween:Play()
	curTween.Completed:Connect(function()
		curTween = nil
		tweenDest = nil
	end)
end

local function StopTween()
	if curTween then
		pcall(function() curTween:Cancel() end)
		curTween = nil
	end
	tweenDest = nil
end

local function SetFlyAnchor(en)
	local hrp = GetHRP()
	if not hrp then return end
	local bv = hrp:FindFirstChild("BF_FlyVelocity")
	if en then
		if not bv then
			bv = Instance.new("BodyVelocity")
			bv.Name = "BF_FlyVelocity"
			bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp
		else
			bv.Velocity = Vector3.zero
		end
	elseif bv then
		bv:Destroy()
	end
end

-- ════════════════════════════════════════
--  EQUIPAR ARMA, FAST ATTACK & BRING MOBS
-- ════════════════════════════════════════
local function EquipWeapon()
	local c = GetChar()
	local hum = GetHum()
	if not c or not hum then return end
	if c:FindFirstChildOfClass("Tool") then return end
	local bp = LP:FindFirstChild("Backpack")
	if not bp then return end
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") and (t.ToolTip == ST.WeaponType or t:GetAttribute("WeaponType") == ST.WeaponType) then
			hum:EquipTool(t)
			return
		end
	end
	local any = bp:FindFirstChildOfClass("Tool")
	if any then
		hum:EquipTool(any)
	end
end

local CombatFW
pcall(function()
	if LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("CombatFramework") then
		CombatFW = require(LP.PlayerScripts.CombatFramework)
	end
end)

local function FastAttack(mob)
	pcall(function()
		local c = GetChar()
		if not c then return end
		local tool = c:FindFirstChildOfClass("Tool")
		if tool then
			tool:Activate()
		end
		if CombatFW and CombatFW.activeController then
			local ac = CombatFW.activeController
			ac.hitboxMagnitude = 60
			ac.timeToNextAttack = 0
			ac.attacking = false
			pcall(function() ac:attack() end)
		end
		if R["RE/RegisterAttack"] then
			R["RE/RegisterAttack"]:FireServer(0)
		end
		if mob and R["RE/RegisterHit"] then
			local mhrp = mob:FindFirstChild("HumanoidRootPart")
			if mhrp then
				R["RE/RegisterHit"]:FireServer(mhrp, { { mhrp, mhrp.Position } })
			end
		end
	end)
end

local function BringMobs(mobName, centerCF)
	if not ST.BringMob or not mobName or mobName == "" then return end
	pcall(function()
		local enemies = workspace:FindFirstChild("Enemies")
		if not enemies then return end
		for _, mob in ipairs(enemies:GetChildren()) do
			if string.find(mob.Name, mobName) then
				local mhrp = mob:FindFirstChild("HumanoidRootPart")
				local mhum = mob:FindFirstChildOfClass("Humanoid")
				if mhrp and mhum and mhum.Health > 0 then
					if (mhrp.Position - centerCF.Position).Magnitude <= ST.BringMobDist then
						mhrp.Size = Vector3.new(60, 60, 60)
						mhrp.Transparency = 0.85
						mhrp.CanCollide = false
						mhrp.CFrame = centerCF
						mhrp.AssemblyLinearVelocity = Vector3.zero
						mhum.WalkSpeed = 0
						mhum.JumpPower = 0
					end
				end
			end
		end
	end)
end

local function TriggerSkills()
	if type(VirtualInputMgr) ~= "userdata" and type(VirtualInputMgr) ~= "table" then return end
	local function tap(key)
		if not VirtualInputMgr.SendKeyEvent then return end
		VirtualInputMgr:SendKeyEvent(true, key, false, game)
		task.wait(0.01)
		VirtualInputMgr:SendKeyEvent(false, key, false, game)
	end
	pcall(function()
		if ST.AutoSkillZ then tap(Enum.KeyCode.Z) end
		if ST.AutoSkillX then tap(Enum.KeyCode.X) end
		if ST.AutoSkillC then tap(Enum.KeyCode.C) end
		if ST.AutoSkillV then tap(Enum.KeyCode.V) end
	end)
end

local lastBuso = 0
local function EnsureBuso()
	if not ST.AutoBuso then return end
	if tick() - lastBuso < 5 then return end
	lastBuso = tick()
	pcall(function()
		local c = GetChar()
		if c and not c:GetAttribute("HasBuso") then
			CF_("Buso")
		end
	end)
end

local function FindMob(nameFilter)
	if not nameFilter or nameFilter == "" then return nil end
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then return nil end
	for _, mob in ipairs(enemies:GetChildren()) do
		if string.find(mob.Name, nameFilter) then
			local mh = mob:FindFirstChildOfClass("Humanoid")
			local mr = mob:FindFirstChild("HumanoidRootPart")
			if mh and mh.Health > 0 and mr then
				return mob
			end
		end
	end
	return nil
end

local function FarmUntilDead(mob, stopCheck)
	if not mob then return end
	local mhrp = mob:FindFirstChild("HumanoidRootPart")
	local mhum = mob:FindFirstChildOfClass("Humanoid")
	if not mhrp or not mhum then return end
	while mhum.Health > 0 and mhum.Parent and mhrp.Parent do
		if stopCheck and not stopCheck() then break end
		task.wait(0.05)
		local hrp = GetHRP()
		local hum = GetHum()
		if not hrp or not hum or hum.Health <= 0 then break end
		local dist = (hrp.Position - mhrp.Position).Magnitude
		local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)
		if dist > 40 then
			SetFlyAnchor(false)
			SafeTween(flyPos)
		else
			StopTween()
			SetFlyAnchor(true)
			hrp.CFrame = flyPos
			hrp.AssemblyLinearVelocity = Vector3.zero
			BringMobs(mob.Name, mhrp.CFrame)
			EquipWeapon()
			if ST.FastAttack then
				FastAttack(mob)
			end
			TriggerSkills()
		end
	end
	SetFlyAnchor(false)
end

-- ════════════════════════════════════════
--  LOOPS DE MISSÕES ESPECIAIS
-- ════════════════════════════════════════
local function AutoBartiloLoop(token)
	while ST.AutoBartilo and IsTokenValid("Bartilo", token) do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			if (hrp.Position - BartiloData.NPC_CF.Position).Magnitude > 20 then
				SetFlyAnchor(false)
				SafeTween(BartiloData.NPC_CF)
				return
			end
			StopTween()
			CF_("StartQuest", BartiloData.QuestKey, BartiloData.QuestLv)
			task.wait(0.4)
			if not HasActiveQuest() then return end
			local mob = FindMob(BartiloData.MobName)
			if mob then
				FarmUntilDead(mob, function() return ST.AutoBartilo and IsTokenValid("Bartilo", token) end)
			else
				SafeTween(BartiloData.MobCF)
			end
		end)
	end
	SetFlyAnchor(false)
end

local function AutoRainbowHakiLoop(token)
	while ST.AutoRainbowHaki and IsTokenValid("RainbowHaki", token) do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			if (hrp.Position - RainbowHakiData.NPC_CF.Position).Magnitude > 20 then
				SetFlyAnchor(false)
				SafeTween(RainbowHakiData.NPC_CF)
				return
			end
			StopTween()
			CF_("StartQuest", RainbowHakiData.QuestKey, 1)
			task.wait(0.4)
			if not HasActiveQuest() then return end
			local mob = FindMob(RainbowHakiData.MobName)
			if mob then
				FarmUntilDead(mob, function() return ST.AutoRainbowHaki and IsTokenValid("RainbowHaki", token) end)
			else
				SafeTween(RainbowHakiData.MobCF)
			end
		end)
	end
	SetFlyAnchor(false)
end

local raceStepIndex = 1
local function AutoRaceQuestLoop(token)
	raceStepIndex = 1
	while ST.AutoRaceQuest and IsTokenValid("RaceQuest", token) do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			local raceInfo = RaceQuestData[ST.RaceType]
			if not raceInfo then return end
			local step = raceInfo.Steps[raceStepIndex]
			if not step then
				ST.AutoRaceQuest = false
				return
			end
			if (hrp.Position - step.NPC.Position).Magnitude > 20 then
				SetFlyAnchor(false)
				SafeTween(step.NPC)
				return
			end
			StopTween()
			if step.Entrance then
				CF_("requestEntrance", step.Entrance)
				task.wait(0.5)
			end
			CF_(step.Task)
			task.wait(0.4)
			if step.MobName then
				local mob = FindMob(step.MobName)
				if mob then
					FarmUntilDead(mob, function() return ST.AutoRaceQuest and IsTokenValid("RaceQuest", token) end)
				elseif step.MobCF then
					SafeTween(step.MobCF)
				end
			else
				raceStepIndex = raceStepIndex + 1
			end
		end)
	end
	SetFlyAnchor(false)
end

local function AutoCollectBerryLoop(token)
	while ST.AutoCollectBerry and IsTokenValid("Berry", token) do
		task.wait(1)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			for _, obj in ipairs(workspace:GetDescendants()) do
				if not ST.AutoCollectBerry or not IsTokenValid("Berry", token) then break end
				local isBerry = obj.Name == "Money" or obj.Name == "Beli"
					or obj.Name == "GoldBag" or string.find(obj.Name or "", "Berry")
				if isBerry and obj:IsA("BasePart") then
					local d = (hrp.Position - obj.Position).Magnitude
					if d > 5 then
						SafeTween(obj.CFrame, 400)
					else
						SafeTouch(hrp, obj)
						task.wait(0.1)
					end
				end
			end
		end)
	end
end

local HakiContainerCFs = {
	CFrame.new(-4721, 845, 1953),
	CFrame.new(-7906, 5634, -1411),
	CFrame.new(28282, 14896, 102),
}

local function AutoHakiContainerLoop(token)
	local idx = 1
	while ST.AutoHakiContainer and IsTokenValid("HakiContainer", token) do
		task.wait(0.8)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			local cf = HakiContainerCFs[idx]
			if not cf then idx = 1; return end
			if (hrp.Position - cf.Position).Magnitude > 25 then
				SafeTween(cf)
				return
			end
			for _, obj in ipairs(workspace:GetDescendants()) do
				if string.find(obj.Name or "", "HakiContainer")
					or string.find(obj.Name or "", "KiContainer")
					or string.find(obj.Name or "", "HakiJar") then
					if obj:IsA("BasePart") then
						SafeTouch(hrp, obj)
					end
				end
			end
			idx = (idx % #HakiContainerCFs) + 1
		end)
	end
end

-- ════════════════════════════════════════
--  SHOP & WEBHOOK
-- ════════════════════════════════════════
local function BuySword(name)
	pcall(function()
		CF_("BuySword", name)
		task.wait(0.2)
		CF_("BuyItem", "Sword", name)
	end)
end

local function BuyAccessory(name)
	pcall(function()
		CF_("BuyAccessory", name)
		task.wait(0.2)
		CF_("BuyItem", "Accessory", name)
	end)
end

local function BuyFruitSlot()
	pcall(function()
		CF_("BuyFruitStorage")
		task.wait(0.2)
		CF_("BuyItem", "FruitStorage", 1)
	end)
end

local function Webhook(title, desc, color, fields)
	if not ST.EnableWebhook or #ST.WebhookURL < 15 then return end
	task.spawn(function()
		pcall(function()
			local req = (syn and syn.request) or http_request or request or (fluxus and fluxus.request)
			if type(req) ~= "function" then return end
			req({
				Url = ST.WebhookURL,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({
					username = "BF Script Pro",
					embeds = { {
						title = "[BF] " .. tostring(title),
						description = tostring(desc),
						color = color or 65535,
						fields = fields or {},
						footer = { text = "BFScript v2 • " .. os.date("%d/%m/%Y %H:%M") }
					} }
				})
			})
		end)
	end)
end

-- ════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════
local espCache = {}
local function CreateESP(obj, labelText, color)
	if espCache[obj] then
		local existing = espCache[obj][3]
		if existing and existing.Parent then
			existing.Text = labelText
		end
		return
	end
	pcall(function()
		local hl = Instance.new("Highlight")
		hl.FillColor = color
		hl.OutlineColor = Color3.new(1, 1, 1)
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0.2
		hl.Adornee = obj
		hl.Parent = SafeParent

		local bb = Instance.new("BillboardGui")
		bb.AlwaysOnTop = true
		bb.Size = UDim2.new(0, 160, 0, 30)
		bb.Adornee = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart) or obj
		bb.Parent = SafeParent

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText
		lbl.TextColor3 = color
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextStrokeTransparency = 0.3
		lbl.Parent = bb

		espCache[obj] = { hl, bb, lbl }
		obj.AncestryChanged:Connect(function()
			if not obj:IsDescendantOf(workspace) then
				for _, v in pairs(espCache[obj] or {}) do
					pcall(function() v:Destroy() end)
				end
				espCache[obj] = nil
			end
		end)
	end)
end

local function ClearAllESP()
	for obj, parts in pairs(espCache) do
		for _, v in pairs(parts) do
			pcall(function() v:Destroy() end)
		end
		espCache[obj] = nil
	end
end

-- ════════════════════════════════════════
--  CARREGAMENTO SEGURO DA UI (GG-Ui.luau)
-- ════════════════════════════════════════
local UI_URL = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"

local function SafeHttpGet(url)
	local src = nil
	local ok = pcall(function()
		src = game:HttpGet(url, true)
	end)

	if not ok or not src or src == "" then
		local httpFn = (syn and syn.request) or request or http_request
		if type(httpFn) == "function" then
			local finished = false
			task.spawn(function()
				local reqOk, res = pcall(httpFn, { Url = url, Method = "GET" })
				if reqOk and type(res) == "table" and type(res.Body) == "string" then
					src = res.Body
				end
				finished = true
			end)
			local t0 = tick()
			while not finished and (tick() - t0) < 5 do
				task.wait(0.1)
			end
		end
	end
	return src
end

local GGUI_LIB = nil
local uiSource = SafeHttpGet(UI_URL)

if uiSource and uiSource ~= "" then
	local fn, syntaxErr = loadstring(uiSource)
	if not fn then
		warn("[BF Script] Erro de sintaxe no GG-Ui: " .. tostring(syntaxErr))
	else
		local runOk, ret = pcall(fn)
		if not runOk then
			warn("[BF Script] Falha ao executar GG-Ui: " .. tostring(ret))
		else
			GGUI_LIB = ret or (getgenv and getgenv().GGUI) or _G.GGUI
		end
	end
else
	warn("[BF Script] Falha ao baixar GG-Ui! Verifique sua conexão ou o link.")
end

if not GGUI_LIB or type(GGUI_LIB.MakeWindow) ~= "function" then
	warn("[BF Script] GGUI ou MakeWindow não encontrado. Interrompendo execução.")
	return
end

local Win = GGUI_LIB:MakeWindow({
	Title = "BF Script Pro v2",
	SubTitle = "Sea " .. tostring(CurrentSea) .. " | Lv." .. tostring(GetLevel()),
	ScriptFolder = "BFScriptProV2",
})

if Win and Win.NewMinimizer then
	local mm = Win:NewMinimizer({ KeyCode = Enum.KeyCode.RightControl })
	if mm.CreateMobileMinimizer then
		mm:CreateMobileMinimizer({
			Size = UDim2.fromOffset(44, 44),
			Position = UDim2.fromScale(0.12, 0.25),
			Corner = 10,
		})
	end
end

-- ══════════════════════════════════════
--  TABS PRINCIPAIS
-- ══════════════════════════════════════
local tFarm = Win:MakeTab({ Title = "Farm Level" })
tFarm:AddIcon({ Name = "swords" })

tFarm:AddToggle({
	Name = "Auto Farm Level",
	Default = false,
	Callback = function(v)
		ST.AutoFarmLevel = v
		if not v then
			StopTween()
			SetFlyAnchor(false)
		end
	end
})

tFarm:AddDropdown({
	Name = "Arma",
	Options = { "Melee", "Sword", "Blox Fruit", "Gun" },
	Callback = function(v)
		ST.WeaponType = v
	end
})

tFarm:AddToggle({ Name = "Fast Attack v4", Default = true, Callback = function(v) ST.FastAttack = v end })
tFarm:AddToggle({ Name = "Bring Mob AOE",  Default = true, Callback = function(v) ST.BringMob = v end })
tFarm:AddToggle({ Name = "Auto Buso Haki", Default = true, Callback = function(v) ST.AutoBuso = v end })
tFarm:AddSlider({ Name = "Farm Distance", Min = 10, Max = 50, Default = 20, Increment = 1, Callback = function(v) ST.FarmDist = v end })
tFarm:AddSlider({ Name = "Tween Speed", Min = 100, Max = 400, Default = 260, Increment = 10, Callback = function(v) ST.TweenSpeed = v end })

local tMob = Win:MakeTab({ Title = "Quái & Boss" })
tMob:AddIcon({ Name = "skull" })

tMob:AddTextBox({ Name = "Nome do Mob", Default = "", Callback = function(v) ST.SelectedMob = v end })
tMob:AddToggle({
	Name = "Auto Farm Mob Livre",
	Default = false,
	Callback = function(v)
		ST.AutoFarmMob = v
		if not v then
			StopTween()
			SetFlyAnchor(false)
		end
	end
})

tMob:AddSection("Boss")
local bossList = {
	"The Gorilla King", "Bobby", "Yeti", "Vice Admiral", "Warden", "Chief Warden",
	"Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
	"EVO Guard", "Darkbeard", "Rip_Indra", "Dragon", "Cake Queen", "Soul Reaper", "Leviathan"
}
tMob:AddDropdown({ Name = "Boss Alvo", Options = bossList, Callback = function(v) ST.SelectedBoss = v end })
tMob:AddToggle({
	Name = "Auto Farm Boss",
	Default = false,
	Callback = function(v)
		ST.AutoFarmBoss = v
		if not v then
			StopTween()
			SetFlyAnchor(false)
		end
	end
})

local tQuest = Win:MakeTab({ Title = "Missões" })
tQuest:AddIcon({ Name = "target" })

tQuest:AddSection("Bartilo (Saber Expert)")
tQuest:AddToggle({
	Name = "Auto Bartilo Quest",
	Default = false,
	Callback = function(v)
		ST.AutoBartilo = v
		local tok = NextToken("Bartilo")
		if v then task.spawn(AutoBartiloLoop, tok) end
	end
})

tQuest:AddSection("Rainbow Haki")
tQuest:AddToggle({
	Name = "Auto Rainbow Haki",
	Default = false,
	Callback = function(v)
		ST.AutoRainbowHaki = v
		local tok = NextToken("RainbowHaki")
		if v then task.spawn(AutoRainbowHakiLoop, tok) end
	end
})

tQuest:AddSection("Missão de Raça")
tQuest:AddDropdown({
	Name = "Raça",
	Options = { "Human", "Mink", "Shark", "Sky", "Cyborg" },
	Callback = function(v)
		ST.RaceType = v
		raceStepIndex = 1
	end
})
tQuest:AddToggle({
	Name = "Auto Race Quest",
	Default = false,
	Callback = function(v)
		ST.AutoRaceQuest = v
		raceStepIndex = 1
		local tok = NextToken("RaceQuest")
		if v then task.spawn(AutoRaceQuestLoop, tok) end
	end
})

tQuest:AddSection("Colosseum")
tQuest:AddToggle({
	Name = "Auto Colosseum Farm",
	Default = false,
	Callback = function(v)
		ST.AutoColosseum = v
		if not v then
			StopTween()
			SetFlyAnchor(false)
		end
	end
})

local tChest = Win:MakeTab({ Title = "Rương & Stats" })
tChest:AddIcon({ Name = "gem" })

tChest:AddSection("Rương")
tChest:AddToggle({
	Name = "Auto Nhặt Rương",
	Default = false,
	Callback = function(v)
		ST.AutoChest = v
		if not v then StopTween() end
	end
})
tChest:AddSlider({ Name = "Velocidade Rương", Min = 150, Max = 450, Default = 260, Increment = 10, Callback = function(v) ST.TweenSpeed = v end })

tChest:AddSection("Status Points")
tChest:AddToggle({ Name = "Auto Stats", Default = false, Callback = function(v) ST.AutoStats = v end })
tChest:AddSlider({ Name = "Pontos por Rodada", Min = 1, Max = 10, Default = 3, Increment = 1, Callback = function(v) ST.StatChunk = v end })
for _, stat in ipairs({ "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }) do
	tChest:AddToggle({
		Name = "Nâng " .. stat,
		Default = ST.StatsMap[stat] or false,
		Callback = function(v)
			ST.StatsMap[stat] = v
		end
	})
end

local tBerry = Win:MakeTab({ Title = "Berry & Haki" })
tBerry:AddIcon({ Name = "coins" })

tBerry:AddSection("Berry (Beli)")
tBerry:AddToggle({
	Name = "Auto Coletar Berry",
	Default = false,
	Callback = function(v)
		ST.AutoCollectBerry = v
		local tok = NextToken("Berry")
		if v then task.spawn(AutoCollectBerryLoop, tok) end
	end
})
tBerry:AddLabel({ Text = "Berry atual: " .. tostring(GetBerry()) })

tBerry:AddSection("Recipientes de Haki")
tBerry:AddToggle({
	Name = "Auto Pegar Recipientes Haki",
	Default = false,
	Callback = function(v)
		ST.AutoHakiContainer = v
		local tok = NextToken("HakiContainer")
		if v then task.spawn(AutoHakiContainerLoop, tok) end
	end
})

local tShop = Win:MakeTab({ Title = "Shop" })
tShop:AddIcon({ Name = "shopping-bag" })

tShop:AddSection("Espadas")
tShop:AddDropdown({ Name = "Espada", Options = ShopData.Swords, Callback = function(v) ST.ShopSwordName = v end })
tShop:AddButton({
	Name = "Comprar Espada",
	Callback = function()
		BuySword(ST.ShopSwordName)
		Win:Notify({ Title = "Shop", Content = "Comprando: " .. ST.ShopSwordName, Duration = 3 })
	end
})

tShop:AddSection("Acessórios")
tShop:AddDropdown({ Name = "Acessório", Options = ShopData.Accessories, Callback = function(v) ST.ShopAccessoryName = v end })
tShop:AddButton({
	Name = "Comprar Acessório",
	Callback = function()
		BuyAccessory(ST.ShopAccessoryName)
		Win:Notify({ Title = "Shop", Content = "Comprando: " .. ST.ShopAccessoryName, Duration = 3 })
	end
})

tShop:AddSection("Fruit Storage")
tShop:AddButton({
	Name = "Comprar Slot de Fruta",
	Callback = function()
		BuyFruitSlot()
		Win:Notify({ Title = "Shop", Content = "Comprando slot de fruta...", Duration = 3 })
	end
})

tShop:AddSection("Resgatar Codes")
tShop:AddButton({
	Name = "Auto Resgatar Codes",
	Callback = function()
		local codes = {
			"SUB2GAMERROBOT_EXP1", "KITT_RESET", "Sub2Fer999", "StrawHatMaine",
			"Sub2OfficialNoobie", "THEGREATACE", "AXIORE", "TantaiGaming",
			"BLUXXY", "fudd10", "BIGNEWS", "CHANDLER", "FUDD10_V2", "3BVISITS"
		}
		task.spawn(function()
			for _, c in ipairs(codes) do
				pcall(function() CF_("Redeem", c) end)
				task.wait(0.3)
			end
			Win:Notify({ Title = "Codes", Content = "Todos os codes resgatados!", Duration = 4 })
		end)
	end
})

local tESP = Win:MakeTab({ Title = "ESP" })
tESP:AddIcon({ Name = "eye" })

tESP:AddToggle({ Name = "ESP Players", Default = false, Callback = function(v) ST.ESP_Players = v; if not v then ClearAllESP() end end })
tESP:AddToggle({ Name = "ESP Rương", Default = false, Callback = function(v) ST.ESP_Chests = v; if not v then ClearAllESP() end end })
tESP:AddToggle({ Name = "ESP Frutas", Default = false, Callback = function(v) ST.ESP_Fruits = v; if not v then ClearAllESP() end end })
tESP:AddToggle({ Name = "ESP Quái/Boss", Default = false, Callback = function(v) ST.ESP_Mobs = v; if not v then ClearAllESP() end end })
tESP:AddButton({ Name = "Limpar ESP", Callback = ClearAllESP })

local tSkill = Win:MakeTab({ Title = "Skills & Frutas" })
tSkill:AddIcon({ Name = "sparkles" })

tSkill:AddSection("Skills")
for _, k in ipairs({ "Z", "X", "C", "V" }) do
	tSkill:AddToggle({
		Name = "Auto Skill " .. k,
		Default = false,
		Callback = function(v)
			ST["AutoSkill" .. k] = v
		end
	})
end

tSkill:AddSection("Frutas")
tSkill:AddToggle({ Name = "Auto Sniper de Fruta", Default = false, Callback = function(v) ST.AutoSnipeFruit = v end })
tSkill:AddToggle({ Name = "Auto Guardar Fruta", Default = false, Callback = function(v) ST.AutoStoreFruit = v end })

local tPlayer = Win:MakeTab({ Title = "Player" })
tPlayer:AddIcon({ Name = "user" })

tPlayer:AddSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 500,
	Default = 16,
	Increment = 1,
	Callback = function(v)
		ST.WalkSpeed = v
		local h = GetHum()
		if h then h.WalkSpeed = v end
	end
})
tPlayer:AddSlider({
	Name = "JumpPower",
	Min = 50,
	Max = 500,
	Default = 50,
	Increment = 1,
	Callback = function(v)
		ST.JumpPower = v
		local h = GetHum()
		if h then h.JumpPower = v end
	end
})
tPlayer:AddToggle({ Name = "Noclip", Default = false, Callback = function(v) ST.Noclip = v end })
tPlayer:AddToggle({ Name = "Infinite Jump", Default = false, Callback = function(v) ST.InfiniteJump = v end })
tPlayer:AddToggle({ Name = "Anti-AFK", Default = true, Callback = function(v) ST.AntiAFK = v end })
tPlayer:AddToggle({
	Name = "FPS Boost",
	Default = false,
	Callback = function(v)
		ST.FPSBoost = v
		if v then
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			for _, p in ipairs(workspace:GetDescendants()) do
				if p:IsA("BasePart") and p.Parent and not p.Parent:FindFirstChild("Humanoid") then
					pcall(function() p.Material = Enum.Material.SmoothPlastic end)
				end
			end
		end
	end
})

local tEvent = Win:MakeTab({ Title = "Eventos" })
tEvent:AddIcon({ Name = "star" })

tEvent:AddSection("Kitsune Island")
tEvent:AddToggle({ Name = "Auto Coletar Blue Ember", Default = false, Callback = function(v) ST.AutoCollectEmbers = v end })
tEvent:AddToggle({ Name = "Auto Rezar Kitsune", Default = false, Callback = function(v) ST.AutoPrayStatue = v end })
tEvent:AddButton({
	Name = "Tocar Estátua",
	Callback = function()
		pcall(function()
			if R["RE/TouchKitsuneStatue"] then
				R["RE/TouchKitsuneStatue"]:FireServer()
			end
		end)
	end
})

tEvent:AddSection("V4 / Raça")
tEvent:AddToggle({ Name = "Auto Awakening V4", Default = false, Callback = function(v) ST.AutoAwakenV4 = v end })
tEvent:AddToggle({ Name = "Auto Race Skill V4", Default = false, Callback = function(v) ST.AutoUseRaceSkill = v end })
tEvent:AddToggle({ Name = "Auto Mirage Gear", Default = false, Callback = function(v) ST.AutoMirageGear = v end })

tEvent:AddSection("Mar")
tEvent:AddToggle({ Name = "Auto Leviathan", Default = false, Callback = function(v) ST.AutoLeviathan = v end })
tEvent:AddToggle({ Name = "Auto Sea Beast", Default = false, Callback = function(v) ST.AutoSeaBeast = v end })
tEvent:AddToggle({ Name = "Auto Ship Raid", Default = false, Callback = function(v) ST.AutoShipRaid = v end })

local tTP = Win:MakeTab({ Title = "Teleport" })
tTP:AddIcon({ Name = "navigation" })

local wpNames = {}
for k in pairs(Waypoints) do table.insert(wpNames, k) end
table.sort(wpNames)
local chosenWP = wpNames[1]

tTP:AddDropdown({ Name = "Ilha", Options = wpNames, Callback = function(v) chosenWP = v end })
tTP:AddButton({
	Name = "Ir para Ilha",
	Callback = function()
		local cf = Waypoints[chosenWP]
		if cf then SafeTween(cf) end
	end
})
tTP:AddButton({
	Name = "Parar Voo",
	Callback = function()
		StopTween()
		SetFlyAnchor(false)
	end
})
tTP:AddButton({
	Name = "Server Hop",
	Callback = function()
		pcall(function()
			local data = HttpService:JSONDecode(
				game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
			)
			for _, s in ipairs(data.data or {}) do
				if s.playing < s.maxPlayers and s.id ~= game.JobId then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
					break
				end
			end
		end)
	end
})
tTP:AddButton({
	Name = "Rejoin",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, LP)
	end
})

local tMisc = Win:MakeTab({ Title = "Misc" })
tMisc:AddIcon({ Name = "settings" })

tMisc:AddSection("Webhook")
tMisc:AddTextBox({
	Name = "URL do Webhook",
	Default = ST.WebhookURL,
	Callback = function(v)
		local url = tostring(v or ""):gsub("%s+", "")
		ST.WebhookURL = url
		if writefile then
			pcall(writefile, ST.WebhookFile, url)
		end
		ST.EnableWebhook = #url > 15
	end
})
tMisc:AddToggle({ Name = "Enviar Webhook", Default = false, Callback = function(v) ST.EnableWebhook = v end })
tMisc:AddButton({
	Name = "Testar Webhook",
	Callback = function()
		Webhook("Teste", "Conexão OK — BF Script v2 ativo!", 65535, {
			{ name = "Player", value = LP.Name .. " (Lv." .. GetLevel() .. ")", inline = true },
			{ name = "Sea", value = "Sea " .. CurrentSea, inline = true },
		})
	end
})
tMisc:AddButton({
	Name = "Desligar Tudo",
	Callback = function()
		for k in pairs(ST) do
			if type(ST[k]) == "boolean" then
				ST[k] = false
			end
		end
		StopTween()
		SetFlyAnchor(false)
		ClearAllESP()
		Win:Notify({ Title = "Script", Content = "Tudo desligado.", Duration = 3 })
	end
})

-- ════════════════════════════════════════
--  BACKGROUND TASKS PRINCIPAIS
-- ════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(0.03)
		if ST.AutoFarmLevel then
			pcall(function()
				local hrp = GetHRP()
				local hum = GetHum()
				if not hrp or not hum or hum.Health <= 0 then
					SetFlyAnchor(false)
					return
				end
				local q = GetQuestData()
				EnsureBuso()
				if not HasActiveQuest() then
					SetFlyAnchor(false)
					if (hrp.Position - q.NPC.Position).Magnitude > 20 then
						SafeTween(q.NPC)
					else
						StopTween()
						hrp.CFrame = q.NPC
						if q.Entrance then
							CF_("requestEntrance", q.Entrance)
							task.wait(0.3)
						end
						CF_("StartQuest", q.Quest, q.Level)
						task.wait(0.4)
					end
				else
					local mob = FindMob(q.Name)
					if mob then
						local mhrp = mob:FindFirstChild("HumanoidRootPart")
						if mhrp then
							local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)
							if (hrp.Position - mhrp.Position).Magnitude > 40 then
								SetFlyAnchor(false)
								SafeTween(flyPos)
							else
								StopTween()
								SetFlyAnchor(true)
								hrp.CFrame = flyPos
								hrp.AssemblyLinearVelocity = Vector3.zero
								BringMobs(q.Name, mhrp.CFrame)
								EquipWeapon()
								if ST.FastAttack then
									FastAttack(mob)
								end
								TriggerSkills()
							end
						end
					else
						SetFlyAnchor(false)
						SafeTween(q.MobCF)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.05)
		if ST.AutoFarmMob and not ST.AutoFarmLevel then
			pcall(function()
				local hum = GetHum()
				if not hum or hum.Health <= 0 then
					SetFlyAnchor(false)
					return
				end
				EnsureBuso()
				local mob = FindMob(ST.SelectedMob)
				if mob then
					FarmUntilDead(mob, function() return ST.AutoFarmMob and not ST.AutoFarmLevel end)
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if ST.AutoFarmBoss and not ST.AutoFarmLevel then
			pcall(function()
				local hrp = GetHRP()
				local hum = GetHum()
				if not hrp or not hum or hum.Health <= 0 then
					SetFlyAnchor(false)
					return
				end
				EnsureBuso()
				local mob = FindMob(ST.SelectedBoss)
				if mob then
					local mhrp = mob:FindFirstChild("HumanoidRootPart")
					if mhrp then
						local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist + 5, 0), mhrp.Position)
						if (hrp.Position - mhrp.Position).Magnitude > 40 then
							SetFlyAnchor(false)
							SafeTween(flyPos)
						else
							StopTween()
							SetFlyAnchor(true)
							hrp.CFrame = flyPos
							hrp.AssemblyLinearVelocity = Vector3.zero
							EquipWeapon()
							if ST.FastAttack then
								FastAttack(mob)
							end
							TriggerSkills()
						end
					end
				else
					SetFlyAnchor(false)
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if ST.AutoColosseum then
			pcall(function()
				local hrp = GetHRP()
				if not hrp then return end
				EnsureBuso()
				if not HasActiveQuest() then
					if (hrp.Position - ColosseumData.NPC_CF.Position).Magnitude > 20 then
						SafeTween(ColosseumData.NPC_CF)
						return
					end
					StopTween()
					CF_("StartQuest", ColosseumData.QuestKey, 1)
					task.wait(0.4)
				else
					local mob = FindMob(ColosseumData.MobNames[1]) or FindMob(ColosseumData.MobNames[2])
					if mob then
						FarmUntilDead(mob, function() return ST.AutoColosseum end)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.4)
		if ST.AutoChest and not ST.AutoFarmLevel then
			pcall(function()
				local hrp = GetHRP()
				if not hrp then return end
				local nearest, nearDist = nil, math.huge
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
						local d = (hrp.Position - obj.Position).Magnitude
						if d < nearDist then
							nearest = obj
							nearDist = d
						end
					end
				end
				if nearest then
					SafeTween(nearest.CFrame * CFrame.new(0, 2, 0), ST.TweenSpeed)
					if nearDist <= 12 then
						SafeTouch(hrp, nearest)
						ST.ChestCount = ST.ChestCount + 1
						task.wait(0.2)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		if ST.AutoStats and R.CommF_ then
			pcall(function()
				local d = LP:FindFirstChild("Data")
				if not d then return end
				local pts = d:FindFirstChild("Points") and d.Points.Value or 0
				if pts <= 0 then return end
				local chunk = math.min(pts, ST.StatChunk)
				for stat, en in pairs(ST.StatsMap) do
					if en then
						CF_("AddPoint", stat, chunk)
						task.wait(0.08)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			local myHRP = GetHRP()
			local function dist(p) return myHRP and (myHRP.Position - p).Magnitude or 0 end
			if ST.ESP_Players then
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LP and p.Character then
						local hr = p.Character:FindFirstChild("HumanoidRootPart")
						local hm = p.Character:FindFirstChildOfClass("Humanoid")
						if hr and hm and hm.Health > 0 then
							CreateESP(p.Character, p.Name .. " [" .. math.floor(dist(hr.Position)) .. "m]", Color3.fromRGB(0, 230, 255))
						end
					end
				end
			end
			if ST.ESP_Chests then
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
						CreateESP(obj, "Chest [" .. math.floor(dist(obj.Position)) .. "m]", Color3.fromRGB(255, 215, 0))
					end
				end
			end
			if ST.ESP_Fruits then
				for _, obj in ipairs(workspace:GetChildren()) do
					if string.find(obj.Name, "Fruit") then
						CreateESP(obj, obj.Name, Color3.fromRGB(220, 80, 255))
					end
				end
			end
			if ST.ESP_Mobs then
				local enemies = workspace:FindFirstChild("Enemies")
				if enemies then
					for _, mob in ipairs(enemies:GetChildren()) do
						local mh = mob:FindFirstChildOfClass("Humanoid")
						if mh and mh.Health > 0 then
							CreateESP(mob, mob.Name .. " [HP:" .. math.floor(mh.Health) .. "]", Color3.fromRGB(255, 120, 50))
						end
					end
				end
			end
			if not ST.ESP_Players and not ST.ESP_Chests and not ST.ESP_Fruits and not ST.ESP_Mobs then
				ClearAllESP()
			end
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			if ST.AutoSnipeFruit then
				for _, obj in ipairs(workspace:GetChildren()) do
					if string.find(obj.Name, "Fruit") then
						local handle = obj:FindFirstChild("Handle") or (obj:IsA("BasePart") and obj)
						if handle and handle:IsA("BasePart") then
							SafeTween(handle.CFrame, 350)
							if (hrp.Position - handle.Position).Magnitude <= 10 then
								SafeTouch(hrp, handle)
								Webhook("Fruta", obj.Name .. " coletada automaticamente", 16753920)
								task.wait(0.3)
							end
						end
					end
				end
			end
			if ST.AutoStoreFruit and R.CommF_ then
				local bp = LP:FindFirstChild("Backpack")
				if bp then
					for _, t in ipairs(bp:GetChildren()) do
						if t:IsA("Tool") and string.find(t.Name, "Fruit") then
							CF_("StoreFruit", t.Name, t)
							task.wait(0.4)
						end
					end
				end
			end
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if ST.AutoCollectEmbers and hrp and R["RE/CollectBlueEmber"] then
				for _, obj in ipairs(workspace:GetDescendants()) do
					if string.find(obj.Name or "", "Ember") then
						local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
						if part then
							R["RE/CollectBlueEmber"]:FireServer(part)
							SafeTween(part.CFrame, 350)
						end
					end
				end
			end
			if ST.AutoPrayStatue and R["RF/KitsuneStatuePray"] then
				pcall(function() R["RF/KitsuneStatuePray"]:InvokeServer() end)
			end
			if ST.AutoAwakenV4 and R.ActivateRaceV4 then
				pcall(function() R.ActivateRaceV4:FireServer() end)
			end
			if ST.AutoUseRaceSkill and R.UsedRaceSkill then
				pcall(function() R.UsedRaceSkill:FireServer() end)
			end
			if ST.AutoMirageGear and hrp then
				for _, obj in ipairs(workspace:GetDescendants()) do
					if string.find(obj.Name or "", "MirageGear") and obj:IsA("BasePart") then
						SafeTween(obj.CFrame, 350)
						break
					end
				end
			end
			if ST.AutoLeviathan and hrp then
				local sb = workspace:FindFirstChild("SeaBeasts") or workspace:FindFirstChild("Enemies")
				if sb then
					for _, beast in ipairs(sb:GetChildren()) do
						if string.find(beast.Name, "Leviathan") then
							local bhrp = beast:FindFirstChild("HumanoidRootPart")
							if bhrp then
								SafeTween(bhrp.CFrame * CFrame.new(0, 30, 0))
								EquipWeapon()
								FastAttack(beast)
							end
						end
					end
				end
			end
			if ST.AutoSeaBeast and hrp then
				local sb = workspace:FindFirstChild("SeaBeasts") or workspace:FindFirstChild("Enemies")
				if sb then
					for _, beast in ipairs(sb:GetChildren()) do
						if string.find(beast.Name, "SeaBeast") then
							local bhrp = beast:FindFirstChild("HumanoidRootPart")
							if bhrp then
								SafeTween(bhrp.CFrame * CFrame.new(0, 35, 0))
								EquipWeapon()
								FastAttack(beast)
							end
						end
					end
				end
			end
			if ST.AutoShipRaid and hrp then
				local boats = workspace:FindFirstChild("Boats") or workspace:FindFirstChild("Enemies")
				if boats then
					for _, boat in ipairs(boats:GetChildren()) do
						if string.find(boat.Name, "Brigade") or string.find(boat.Name, "Ship") then
							local bhrp = boat:FindFirstChild("HumanoidRootPart") or boat:FindFirstChildOfClass("BasePart")
							if bhrp then
								SafeTween(bhrp.CFrame * CFrame.new(0, 25, 0))
								EquipWeapon()
								FastAttack(boat)
							end
						end
					end
				end
			end
		end)
	end
end)

RunService.Stepped:Connect(function()
	pcall(function()
		local c = GetChar()
		if not c then return end
		if ST.Noclip or ST.AutoFarmLevel or ST.AutoFarmBoss or ST.AutoFarmMob or ST.AutoChest then
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
		local hum = GetHum()
		if hum then
			if hum.WalkSpeed ~= ST.WalkSpeed then hum.WalkSpeed = ST.WalkSpeed end
			if hum.JumpPower ~= ST.JumpPower then hum.JumpPower = ST.JumpPower end
		end
	end)
end)

UserInputService.JumpRequest:Connect(function()
	if ST.InfiniteJump then
		local hum = GetHum()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

LP.Idled:Connect(function()
	if ST.AntiAFK then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

LP.CharacterAdded:Connect(function(char)
	task.wait(1)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.WalkSpeed = ST.WalkSpeed
		hum.JumpPower = ST.JumpPower
	end
end)

-- ══════════════════════════════════════════════════════════════
--  BLOCO 2: FIGHTING STYLES + ESPADAS ESPECIAIS + ACESSÓRIOS
-- ══════════════════════════════════════════════════════════════
local FightingStyleData = {
	Superhuman = {
		NPC = CFrame.new(1346, 128, 2098),
		Cost = 3000000,
		Req = { { Stat = "Melee", Value = 300 } },
		Invoke = { "GetFightingStyle", "Superhuman" },
		Note = "Precisa Melee 300+ e 3M beli",
	},
	["Death Step"] = {
		NPC = CFrame.new(921, 124, 43476),
		Cost = 2500000,
		Req = {
			{ Stat = "Melee", Value = 400 },
			{ Material = "Leather", Count = 20 },
			{ Material = "Scrap Metal", Count = 10 },
		},
		Invoke = { "GetFightingStyle", "DeathStep" },
		Note = "20 Leather + 10 Scrap Metal + Melee 400",
	},
	["Sharkman Karate"] = {
		NPC = CFrame.new(61350, 15, 1900),
		Cost = 2500000,
		Req = {
			{ Stat = "Melee", Value = 400 },
			{ Material = "Fish Tail", Count = 20 },
			{ Material = "Shark Tooth Necklace", Count = 5 },
		},
		Invoke = { "GetFightingStyle", "SharkmanKarate" },
		Note = "Melee 400 + 20 Fish Tail + 5 Shark Tooth",
	},
	["Electric Claw"] = {
		NPC = CFrame.new(-3272, 48, 3310),
		Cost = 5000000,
		Req = {
			{ Stat = "Melee", Value = 400 },
			{ Material = "Cyborg Parts", Count = 10 },
			{ Material = "Scrap Metal", Count = 10 },
			{ Material = "Leather", Count = 10 },
		},
		Invoke = { "GetFightingStyle", "ElectricClaw" },
		Note = "5M beli + Melee 400 + 10 Cyborg Parts + 10 Scrap Metal + 10 Leather",
	},
	["Dragon Talon"] = {
		NPC = CFrame.new(-16547, 55, -172),
		Cost = 3000000,
		Req = {
			{ Stat = "Melee", Value = 400 },
			{ Material = "Fish Tail", Count = 10 },
			{ Material = "Magma Ore", Count = 10 },
			{ Material = "Dragon Scale", Count = 10 },
			{ Material = "Blaze Ember", Count = 10 },
		},
		Invoke = { "GetFightingStyle", "DragonTalon" },
		Note = "Melee 400 + materiais Dragon + Blaze Ember",
	},
	Godhuman = {
		NPC = CFrame.new(-3272, 48, 3310),
		Cost = 5000000,
		Req = {
			{ Stat = "Melee", Value = 400 },
			{ Material = "Fish Tail", Count = 10 },
			{ Material = "Magma Ore", Count = 10 },
			{ Material = "Mystic Droplet", Count = 10 },
			{ Material = "Dragon Scale", Count = 10 },
		},
		Invoke = { "GetFightingStyle", "Godhuman" },
		Note = "5M beli + Melee 400 + 4 materiais",
	},
	["Sanguine Art"] = {
		NPC = CFrame.new(-28220, 350, -2000),
		Cost = 5000000,
		Req = {
			{ Stat = "Melee", Value = 400 },
			{ Material = "Ectoplasm", Count = 20 },
			{ Material = "Vampire Fang", Count = 10 },
		},
		Invoke = { "GetFightingStyle", "SanguineArt" },
		Note = "5M beli + 20 Ectoplasm + 10 Vampire Fang",
	},
	["Superhuman V2"] = {
		NPC = CFrame.new(1346, 128, 2098),
		Cost = 7500000,
		Req = { { Stat = "Melee", Value = 400 } },
		Invoke = { "GetFightingStyle", "SuperhumanV2" },
		Note = "Requer Superhuman desbloqueado",
	},
}

local SpecialSwordData = {
	Saber = {
		NPC = CFrame.new(-4867, 390, -1942),
		Invoke = { "UnlockSword", "Saber" },
		Req = { { Quest = "BartiloKills", Count = 30 } },
		Note = "Completar Bartilo Quest 30 kills primeiro",
	},
	Rengoku = {
		NPC = CFrame.new(-11200, 850, 490),
		Invoke = { "UnlockSword", "Rengoku" },
		Req = {
			{ Material = "Magma Ore", Count = 10 },
			{ Material = "Scrap Metal", Count = 10 },
			{ Material = "Leather", Count = 10 },
			{ Stat = "Sword", Value = 300 },
		},
		Note = "Sword 300 + materiais",
	},
	["Dragon Trident"] = {
		NPC = CFrame.new(61350, 60, 3000),
		Invoke = { "UnlockSword", "DragonTrident" },
		Req = { { Material = "Fish Tail", Count = 20 }, { Stat = "Sword", Value = 200 } },
		Note = "20 Fish Tail + Sword 200",
	},
	["Pole V1"] = {
		NPC = CFrame.new(-4842, 717, 2623),
		Invoke = { "UnlockSword", "PoleV1" },
		Req = { { Stat = "Sword", Value = 200 } },
		Note = "Sword 200",
	},
	["Pole V2"] = {
		NPC = CFrame.new(28282, 14896, 102),
		Invoke = { "UnlockSword", "PoleV2" },
		Req = {
			{ Material = "Dragon Scale", Count = 10 },
			{ Material = "Mystic Droplet", Count = 5 },
			{ Stat = "Sword", Value = 400 },
		},
		Note = "Temple of Time + Dragon Scale + Mystic Droplet",
	},
	Canvander = {
		NPC = CFrame.new(-11200, 350, -150),
		Invoke = { "UnlockSword", "Canvander" },
		Req = { { Material = "Mystic Droplet", Count = 10 }, { Stat = "Sword", Value = 350 } },
		Note = "10 Mystic Droplet + Sword 350",
	},
	["Gravity Blade"] = {
		NPC = CFrame.new(-11200, 350, -180),
		Invoke = { "UnlockSword", "GravityBlade" },
		Req = {
			{ Material = "Dragon Scale", Count = 10 },
			{ Material = "Magma Ore", Count = 10 },
			{ Stat = "Sword", Value = 350 },
		},
		Note = "Dragon Scale + Magma Ore + Sword 350",
	},
	Tushita = {
		NPC = CFrame.new(2310, 72, -3250),
		Invoke = { "UnlockSword", "Tushita" },
		Req = { { Boss = "Cursed Captain", Count = 1 }, { Stat = "Sword", Value = 300 } },
		Note = "Matar Cursed Captain + Puzzle no Colosseum",
		Steps = {
			CFrame.new(2310, 72, -3250),
			CFrame.new(2290, 72, -3270),
			CFrame.new(2330, 72, -3280),
		},
		StepDelay = 1.5,
	},
	Yama = {
		NPC = CFrame.new(-9515, 142, 5536),
		Invoke = { "UnlockSword", "Yama" },
		Req = { { Boss = "Soul Reaper", Count = 1 }, { Stat = "Sword", Value = 350 } },
		Note = "Matar Soul Reaper + Puzzle no Haunted Castle",
		Steps = {
			CFrame.new(-9515, 142, 5536),
			CFrame.new(-9490, 142, 5560),
			CFrame.new(-9540, 142, 5520),
		},
		StepDelay = 1.5,
	},
	["True Triple Katana"] = {
		NPC = CFrame.new(5259, 37, 4050),
		Invoke = { "UnlockSword", "TrueTripleKatana" },
		Req = { { Sword = "Triple Katana" }, { Beli = 200000 } },
		Note = "Triple Katana no inventário + 200k beli",
	},
	["Dark Blade V3"] = {
		NPC = CFrame.new(-28000, 20, 11000),
		Invoke = { "UnlockSword", "DarkBladeV3" },
		Req = { { Sword = "Dark Blade" }, { Boss = "rip_indra", Count = 1 } },
		Note = "Dark Blade + matar Rip_Indra",
	},
	["Cursed Dual Katana"] = {
		NPC = CFrame.new(-16300, 60, -350),
		Invoke = { "UnlockSword", "CDK" },
		Req = {
			{ Sword = "Cursed Dual Katana pieces" },
			{ Stat = "Sword", Value = 400 },
			{ Material = "Ectoplasm", Count = 20 },
		},
		Note = "Puzzle CDK Sea 3 + 20 Ectoplasm",
		Steps = {
			CFrame.new(-16300, 60, -350),
			CFrame.new(-16350, 60, -300),
			CFrame.new(-16250, 65, -320),
			CFrame.new(-16300, 70, -380),
		},
		StepDelay = 2,
	},
	Enma = {
		NPC = CFrame.new(2180, 28, -6740),
		Invoke = { "UnlockSword", "Enma" },
		Req = { { Boss = "Marine Commodore", Count = 20 }, { Stat = "Sword", Value = 400 } },
		Note = "20 Marine Commodore kills + Sword 400",
	},
}

local AccessoryData = {
	["Marine Coat"] = { NPC = CFrame.new(-2855, 7, 5354), Invoke = { "BuyAccessory", "MarineCoat" }, Beli = 350000, Note = "Marine Starter" },
	["Swan Coat"] = { NPC = CFrame.new(638, 72, 918), Invoke = { "BuyAccessory", "SwanCoat" }, Beli = 1500000, Note = "Swan HQ Sea 2" },
	["Swan Glasses"] = { NPC = CFrame.new(638, 72, 918), Invoke = { "BuyAccessory", "SwanGlasses" }, Beli = 500000, Note = "Swan HQ Sea 2" },
	["Musketeer Hat"] = { NPC = CFrame.new(-429, 72, 1836), Invoke = { "BuyAccessory", "MusketeerHat" }, Beli = 500000, Note = "Floating Turtle Sea 2" },
	["Valkyrie Helmet"] = { NPC = CFrame.new(-7906, 5634, -1411), Invoke = { "BuyAccessory", "ValkyrieHelmet" }, Beli = 1500000, Note = "Upper Skypiea" },
	["Usoap Hat"] = { NPC = CFrame.new(5259, 37, 4050), Invoke = { "BuyAccessory", "UsoappHat" }, Beli = 1000000, Note = "Fountain City Sea 1" },
	Lei = { NPC = CFrame.new(-4842, 717, 2623), Invoke = { "BuyAccessory", "Lei" }, Beli = 220000, Note = "Sky Island" },
	["Tomoe Ring"] = { NPC = CFrame.new(-4842, 717, 2623), Invoke = { "BuyAccessory", "TomoeRing" }, Beli = 500000, Note = "Sky Island" },
	["Ghoul Mask"] = { NPC = CFrame.new(-9515, 142, 5536), Invoke = { "BuyAccessory", "GhoulMask" }, Beli = 1000000, Note = "Haunted Castle Sea 3" },
	["Dragon Scales"] = { NPC = CFrame.new(-16300, 60, -350), Invoke = { "BuyAccessory", "DragonScales" }, Beli = 1500000, Note = "Dragon Dojo Sea 3" },
	["Angel Wings"] = { NPC = CFrame.new(-7906, 5634, -1411), Invoke = { "BuyAccessory", "AngelWings" }, Beli = 1000000, Note = "Upper Skypiea" },
	["Shark Tooth Necklace"] = { NPC = CFrame.new(61122, 17, 1569), Invoke = { "BuyAccessory", "SharkTooth" }, Beli = 750000, Note = "Underwater City" },
	["Golden Crown"] = { NPC = CFrame.new(-3268, 53, 2740), Invoke = { "BuyAccessory", "GoldenCrown" }, Beli = 2000000, Note = "Mansion Sea 3" },
	["Trench Coat"] = { NPC = CFrame.new(-429, 72, 1836), Invoke = { "BuyAccessory", "TrenchCoat" }, Beli = 1200000, Note = "Floating Turtle Sea 2" },
	["Cyborg Glasses"] = { NPC = CFrame.new(295, 73, -55), Invoke = { "BuyAccessory", "CyborgGlasses" }, Beli = 500000, Note = "Factory Sea 2" },
}

local ST2 = {
	AutoFightingStyle    = false,
	SelectedStyle        = "Godhuman",
	AutoSpecialSword     = false,
	SelectedSword        = "Tushita",
	AutoAccessory        = false,
	SelectedAccessory    = "Valkyrie Helmet",
	AutoMastery          = false,
	MasteryWeapon        = "Sword",
	MasteryHPStop        = 10,
	MasteryMob           = "Dojo Fighter",
	MasteryMobCF         = CFrame.new(-16300, 60, -350),
	KillAura             = false,
	KillAuraRadius       = 60,
	KillAuraTargetPlayer = false,
	AimbotEnabled        = false,
	AimbotLockCamera     = false,
	AimbotTarget         = nil,
}

local function HasMaterial(name, count)
	local d = LP:FindFirstChild("Data")
	if not d then return false end
	local inv = d:FindFirstChild("Inventory") or d:FindFirstChild("Materials")
	if inv then
		local slot = inv:FindFirstChild(name)
		if slot and slot.Value >= count then
			return true
		end
	end
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t.Name == name then
				return true
			end
		end
	end
	return false
end

local function HasStat(statName, value)
	local d = LP:FindFirstChild("Data")
	if not d then return false end
	local stats = d:FindFirstChild("Stats")
	if stats then
		local s = stats:FindFirstChild(statName)
		return s and s.Value >= value
	end
	return false
end

local function HasSword(name)
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t.Name == name and t:IsA("Tool") then
				return true
			end
		end
	end
	local c = GetChar()
	if c and c:FindFirstChild(name) then
		return true
	end
	return false
end

local function CheckReqs(reqList)
	if not reqList then return true end
	for _, r in ipairs(reqList) do
		if r.Stat and not HasStat(r.Stat, r.Value) then
			return false, "Precisa " .. r.Stat .. " " .. r.Value
		end
		if r.Material and not HasMaterial(r.Material, r.Count) then
			return false, "Falta " .. r.Count .. "x " .. r.Material
		end
		if r.Sword and not HasSword(r.Sword) then
			return false, "Falta espada: " .. r.Sword
		end
		if r.Beli and GetBerry() < r.Beli then
			return false, "Falta beli: " .. r.Beli
		end
	end
	return true
end

local function AutoFightingStyleLoop(token)
	while ST2.AutoFightingStyle and IsTokenValid("FightStyle", token) do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			local data = FightingStyleData[ST2.SelectedStyle]
			if not data then
				ST2.AutoFightingStyle = false
				return
			end
			local ok, reason = CheckReqs(data.Req)
			if not ok then
				Win:Notify({ Title = "Fighting Style", Content = "Req faltando: " .. (reason or "?"), Duration = 5 })
				task.wait(3)
				return
			end
			if (hrp.Position - data.NPC.Position).Magnitude > 20 then
				SetFlyAnchor(false)
				SafeTween(data.NPC)
				return
			end
			StopTween()
			CF_(data.Invoke[1], data.Invoke[2])
			task.wait(1)
			local c = GetChar()
			if c and c:FindFirstChild("FightingStyle") and string.find(tostring(c.FightingStyle.Value), data.Invoke[2]) then
				Win:Notify({ Title = "Fighting Style", Content = ST2.SelectedStyle .. " desbloqueado!", Duration = 5 })
				ST2.AutoFightingStyle = false
			end
		end)
	end
	SetFlyAnchor(false)
end

local function RunSwordPuzzle(steps, delay)
	local hrp = GetHRP()
	if not hrp then return end
	for _, cf in ipairs(steps) do
		SafeTween(cf, 400)
		local t0 = tick()
		while (hrp.Position - cf.Position).Magnitude > 8 and tick() - t0 < 10 do
			task.wait(0.1)
		end
		task.wait(delay or 1.5)
	end
end

local function AutoSpecialSwordLoop(token)
	while ST2.AutoSpecialSword and IsTokenValid("SpecialSword", token) do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			local data = SpecialSwordData[ST2.SelectedSword]
			if not data then
				ST2.AutoSpecialSword = false
				return
			end
			if HasSword(ST2.SelectedSword) then
				Win:Notify({ Title = "Sword", Content = ST2.SelectedSword .. " já no inventário!", Duration = 4 })
				ST2.AutoSpecialSword = false
				return
			end
			local ok, reason = CheckReqs(data.Req)
			if not ok then
				Win:Notify({ Title = "Sword", Content = "Req: " .. (reason or "?"), Duration = 5 })
				task.wait(3)
				return
			end
			if (hrp.Position - data.NPC.Position).Magnitude > 25 then
				SetFlyAnchor(false)
				SafeTween(data.NPC)
				return
			end
			StopTween()
			if data.Steps then
				RunSwordPuzzle(data.Steps, data.StepDelay)
			end
			CF_(data.Invoke[1], data.Invoke[2])
			task.wait(1)
			if HasSword(ST2.SelectedSword) then
				Win:Notify({ Title = "Sword", Content = ST2.SelectedSword .. " obtida!", Duration = 5 })
				ST2.AutoSpecialSword = false
			end
		end)
	end
	SetFlyAnchor(false)
end

local function AutoAccessoryLoop(token)
	while ST2.AutoAccessory and IsTokenValid("Accessory", token) do
		task.wait(0.5)
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			local data = AccessoryData[ST2.SelectedAccessory]
			if not data then
				ST2.AutoAccessory = false
				return
			end
			if (hrp.Position - data.NPC.Position).Magnitude > 20 then
				SetFlyAnchor(false)
				SafeTween(data.NPC)
				return
			end
			StopTween()
			if GetBerry() < (data.Beli or 0) then
				Win:Notify({ Title = "Acessório", Content = "Beli insuficiente: " .. tostring(data.Beli), Duration = 4 })
				task.wait(3)
				return
			end
			CF_(data.Invoke[1], data.Invoke[2])
			task.wait(1)
			Win:Notify({ Title = "Acessório", Content = ST2.SelectedAccessory .. " comprado!", Duration = 4 })
			ST2.AutoAccessory = false
		end)
	end
	SetFlyAnchor(false)
end

local MasterySkillKeys = {
	Sword = Enum.KeyCode.Z,
	Melee = Enum.KeyCode.Z,
	Gun   = Enum.KeyCode.Z,
	Fruit = Enum.KeyCode.Z,
}

local function GetMasteryPct(mob)
	local hum = mob:FindFirstChildOfClass("Humanoid")
	if not hum or hum.MaxHealth <= 0 then return 100 end
	return (hum.Health / hum.MaxHealth) * 100
end

local function AutoMasteryLoop(token)
	while ST2.AutoMastery and IsTokenValid("Mastery", token) do
		task.wait(0.05)
		pcall(function()
			local hrp = GetHRP()
			local hum = GetHum()
			if not hrp or not hum or hum.Health <= 0 then
				SetFlyAnchor(false)
				return
			end
			EnsureBuso()
			local mob = FindMob(ST2.MasteryMob)
			if not mob then
				SetFlyAnchor(false)
				SafeTween(ST2.MasteryMobCF)
				return
			end
			local mhrp = mob:FindFirstChild("HumanoidRootPart")
			local mhum = mob:FindFirstChildOfClass("Humanoid")
			if not mhrp or not mhum then return end

			local dist = (hrp.Position - mhrp.Position).Magnitude
			local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)
			if dist > 40 then
				SetFlyAnchor(false)
				SafeTween(flyPos)
				return
			end
			StopTween()
			SetFlyAnchor(true)
			hrp.CFrame = flyPos
			hrp.AssemblyLinearVelocity = Vector3.zero
			BringMobs(ST2.MasteryMob, mhrp.CFrame)
			EquipWeapon()

			if GetMasteryPct(mob) > ST2.MasteryHPStop then
				FastAttack(mob)
			else
				local key = MasterySkillKeys[ST2.MasteryWeapon] or Enum.KeyCode.Z
				pcall(function()
					if VirtualInputMgr.SendKeyEvent then
						VirtualInputMgr:SendKeyEvent(true, key, false, game)
						task.wait(0.05)
						VirtualInputMgr:SendKeyEvent(false, key, false, game)
					end
				end)
				task.wait(0.3)
			end
		end)
	end
	SetFlyAnchor(false)
end

task.spawn(function()
	while true do
		task.wait(0.05)
		if ST2.KillAura then
			pcall(function()
				local hrp = GetHRP()
				if not hrp then return end
				EquipWeapon()
				local enemies = workspace:FindFirstChild("Enemies")
				if enemies then
					for _, mob in ipairs(enemies:GetChildren()) do
						local mhum = mob:FindFirstChildOfClass("Humanoid")
						local mhrp = mob:FindFirstChild("HumanoidRootPart")
						if mhum and mhum.Health > 0 and mhrp and (hrp.Position - mhrp.Position).Magnitude <= ST2.KillAuraRadius then
							FastAttack(mob)
						end
					end
				end
				if ST2.KillAuraTargetPlayer then
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LP and p.Character then
							local phrp = p.Character:FindFirstChild("HumanoidRootPart")
							local phum = p.Character:FindFirstChildOfClass("Humanoid")
							if phrp and phum and phum.Health > 0 and (hrp.Position - phrp.Position).Magnitude <= ST2.KillAuraRadius then
								FastAttack(p.Character)
							end
						end
					end
				end
			end)
		end
	end
end)

local function FindNearestTarget(includePlayer)
	local hrp = GetHRP()
	if not hrp then return nil end
	local nearest, nearDist = nil, math.huge

	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, mob in ipairs(enemies:GetChildren()) do
			local mhum = mob:FindFirstChildOfClass("Humanoid")
			local mhrp = mob:FindFirstChild("HumanoidRootPart")
			if mhum and mhum.Health > 0 and mhrp then
				local d = (hrp.Position - mhrp.Position).Magnitude
				if d < nearDist then
					nearest = mhrp
					nearDist = d
				end
			end
		end
	end

	if includePlayer then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then
				local phrp = p.Character:FindFirstChild("HumanoidRootPart")
				local phum = p.Character:FindFirstChildOfClass("Humanoid")
				if phrp and phum and phum.Health > 0 then
					local d = (hrp.Position - phrp.Position).Magnitude
					if d < nearDist then
						nearest = phrp
						nearDist = d
					end
				end
			end
		end
	end

	return nearest
end

RunService.RenderStepped:Connect(function()
	if not ST2.AimbotEnabled then return end
	pcall(function()
		local target = FindNearestTarget(ST2.KillAuraTargetPlayer)
		ST2.AimbotTarget = target
		if not target then return end

		if ST2.AimbotLockCamera and workspace.CurrentCamera then
			local cam = workspace.CurrentCamera
			cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
		end

		local hrp = GetHRP()
		if hrp then
			hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))
		end
	end)
end)

local MaterialMobMap = {
	["Scrap Metal"]        = { Mob = "Cyborg",             CF = CFrame.new(295, 73, -55) },
	["Leather"]            = { Mob = "Gorilla",            CF = CFrame.new(-1142, 40, 515) },
	["Magma Ore"]          = { Mob = "Military Spy",       CF = CFrame.new(-5787, 75, 8651) },
	["Angel Wings"]        = { Mob = "God's Guard",        CF = CFrame.new(-4628, 866, 1931) },
	["Fish Tail"]          = { Mob = "Fishman Warrior",    CF = CFrame.new(60844, 98, 1298), Entrance = Vector3.new(61163, 11, 1819) },
	["Radioactive Material"] = { Mob = "Zombie",            CF = CFrame.new(-5650, 120, -750) },
	["Vampire Fang"]       = { Mob = "Living Zombie",      CF = CFrame.new(-10150, 140, 5950) },
	["Mystic Droplet"]     = { Mob = "Royal Squad",        CF = CFrame.new(-7600, 5600, -1450) },
	["Mini Tusk"]          = { Mob = "Dojo Fighter",       CF = CFrame.new(-16300, 60, -350) },
	["Gunpowder"]          = { Mob = "Pirate Millionaire", CF = CFrame.new(-200, 45, 5900) },
	["Conjured Cocoa"]     = { Mob = "Sweet Thief",        CF = CFrame.new(-1200, 20, -14700) },
	["Dragon Scale"]       = { Mob = "Dragon",             CF = CFrame.new(-28000, 20, 11000) },
	["Ectoplasm"]          = { Mob = "Reborn Skeleton",    CF = CFrame.new(-8750, 140, 5900) },
	["Demonic Wisp"]       = { Mob = "Living Zombie",      CF = CFrame.new(-10150, 140, 5950) },
	["Bones"]              = { Mob = "Reborn Skeleton",    CF = CFrame.new(-8750, 140, 5900) },
	["Yeti Fur"]           = { Mob = "Yeti",               CF = CFrame.new(609, 401, -5372) },
	["Blaze Ember"]        = { Mob = "Dojo Fighter",       CF = CFrame.new(-16300, 60, -350) },
	["Cyborg Parts"]       = { Mob = "Cyborg",             CF = CFrame.new(295, 73, -55) },
}

local ST2Materials = {
	AutoMaterialFarm = false,
	TargetMaterial   = "Dragon Scale",
	MaterialCount    = 10,
}

local function AutoMaterialFarmLoop(token)
	while ST2Materials.AutoMaterialFarm and IsTokenValid("MaterialFarm", token) do
		task.wait(0.1)
		pcall(function()
			local hrp = GetHRP()
			local hum = GetHum()
			if not hrp or not hum or hum.Health <= 0 then
				SetFlyAnchor(false)
				return
			end
			local name = ST2Materials.TargetMaterial
			local info = MaterialMobMap[name]
			if not info then
				ST2Materials.AutoMaterialFarm = false
				return
			end
			if HasMaterial(name, ST2Materials.MaterialCount) then
				Win:Notify({ Title = "Material", Content = name .. " coletado!", Duration = 4 })
				ST2Materials.AutoMaterialFarm = false
				return
			end
			EnsureBuso()
			if info.Entrance and (hrp.Position - info.CF.Position).Magnitude > 3000 then
				CF_("requestEntrance", info.Entrance)
				task.wait(0.5)
			end
			local mob = FindMob(info.Mob)
			if mob then
				FarmUntilDead(mob, function() return ST2Materials.AutoMaterialFarm and IsTokenValid("MaterialFarm", token) end)
			else
				SetFlyAnchor(false)
				SafeTween(info.CF)
			end
		end)
	end
	SetFlyAnchor(false)
end

-- ════════════════════════════════════════
--  TABS DO BLOCO 2
-- ════════════════════════════════════════
local tFS = Win:MakeTab({ Title = "Fight Styles" })
tFS:AddIcon({ Name = "dumbbell" })

local styleNames = {}
for k in pairs(FightingStyleData) do table.insert(styleNames, k) end
table.sort(styleNames)

tFS:AddDropdown({
	Name = "Estilo",
	Options = styleNames,
	Callback = function(v)
		ST2.SelectedStyle = v
		local d = FightingStyleData[v]
		if d then Win:Notify({ Title = v, Content = d.Note, Duration = 5 }) end
	end
})
tFS:AddToggle({
	Name = "Auto Get Fighting Style",
	Default = false,
	Callback = function(v)
		ST2.AutoFightingStyle = v
		local tok = NextToken("FightStyle")
		if v then task.spawn(AutoFightingStyleLoop, tok) end
	end
})
tFS:AddSection("Info")
tFS:AddLabel({ Text = "Selecione o estilo e ative. Script vai ao NPC, verifica requisitos e compra." })

local tSW = Win:MakeTab({ Title = "Espadas" })
tSW:AddIcon({ Name = "swords" })

local swordNames = {}
for k in pairs(SpecialSwordData) do table.insert(swordNames, k) end
table.sort(swordNames)

tSW:AddDropdown({
	Name = "Espada",
	Options = swordNames,
	Callback = function(v)
		ST2.SelectedSword = v
		local d = SpecialSwordData[v]
		if d then Win:Notify({ Title = v, Content = d.Note, Duration = 6 }) end
	end
})
tSW:AddToggle({
	Name = "Auto Get Espada",
	Default = false,
	Callback = function(v)
		ST2.AutoSpecialSword = v
		local tok = NextToken("SpecialSword")
		if v then task.spawn(AutoSpecialSwordLoop, tok) end
	end
})
tSW:AddSection("Puzzle Swords")
tSW:AddLabel({ Text = "Tushita, Yama e CDK têm puzzle de posição automático." })

local tACC = Win:MakeTab({ Title = "Acessórios" })
tACC:AddIcon({ Name = "backpack" })

local accNames = {}
for k in pairs(AccessoryData) do table.insert(accNames, k) end
table.sort(accNames)

tACC:AddDropdown({
	Name = "Acessório",
	Options = accNames,
	Callback = function(v)
		ST2.SelectedAccessory = v
		local d = AccessoryData[v]
		if d then Win:Notify({ Title = v, Content = d.Note .. " | " .. d.Beli .. " beli", Duration = 5 }) end
	end
})
tACC:AddToggle({
	Name = "Auto Comprar Acessório",
	Default = false,
	Callback = function(v)
		ST2.AutoAccessory = v
		local tok = NextToken("Accessory")
		if v then task.spawn(AutoAccessoryLoop, tok) end
	end
})

local tMST = Win:MakeTab({ Title = "Mastery" })
tMST:AddIcon({ Name = "target" })

tMST:AddDropdown({
	Name = "Arma para Mastery",
	Options = { "Melee", "Sword", "Gun", "Fruit" },
	Callback = function(v) ST2.MasteryWeapon = v end
})
tMST:AddTextBox({
	Name = "Mob para Mastery",
	Default = ST2.MasteryMob,
	Callback = function(v)
		ST2.MasteryMob = v
		local info = MaterialMobMap[v]
		if info then ST2.MasteryMobCF = info.CF end
	end
})
tMST:AddSlider({
	Name = "Parar Ataque em HP%",
	Min = 5,
	Max = 50,
	Default = 10,
	Increment = 1,
	Callback = function(v) ST2.MasteryHPStop = v end
})
tMST:AddToggle({
	Name = "Auto Mastery",
	Default = false,
	Callback = function(v)
		ST2.AutoMastery = v
		local tok = NextToken("Mastery")
		if v then task.spawn(AutoMasteryLoop, tok) end
	end
})

local tCMB = Win:MakeTab({ Title = "Combate" })
tCMB:AddIcon({ Name = "skull" })

tCMB:AddSection("Kill Aura")
tCMB:AddToggle({ Name = "Kill Aura", Default = false, Callback = function(v) ST2.KillAura = v end })
tCMB:AddSlider({ Name = "Raio Kill Aura", Min = 10, Max = 200, Default = 60, Increment = 5, Callback = function(v) ST2.KillAuraRadius = v end })
tCMB:AddToggle({ Name = "Incluir Players", Default = false, Callback = function(v) ST2.KillAuraTargetPlayer = v end })

tCMB:AddSection("Aimbot")
tCMB:AddToggle({ Name = "Aimbot", Default = false, Callback = function(v) ST2.AimbotEnabled = v end })
tCMB:AddToggle({ Name = "Lock Camera no Alvo", Default = false, Callback = function(v) ST2.AimbotLockCamera = v end })

local tMAT = Win:MakeTab({ Title = "Materiais" })
tMAT:AddIcon({ Name = "beaker" })

local matNames = {}
for k in pairs(MaterialMobMap) do table.insert(matNames, k) end
table.sort(matNames)

tMAT:AddDropdown({
	Name = "Material Alvo",
	Options = matNames,
	Callback = function(v)
		ST2Materials.TargetMaterial = v
		local info = MaterialMobMap[v]
		if info then Win:Notify({ Title = "Material", Content = "Mob: " .. info.Mob, Duration = 3 }) end
	end
})
tMAT:AddSlider({
	Name = "Quantidade Alvo",
	Min = 1,
	Max = 100,
	Default = 10,
	Increment = 1,
	Callback = function(v) ST2Materials.MaterialCount = v end
})
tMAT:AddToggle({
	Name = "Auto Material Farm",
	Default = false,
	Callback = function(v)
		ST2Materials.AutoMaterialFarm = v
		local tok = NextToken("MaterialFarm")
		if v then task.spawn(AutoMaterialFarmLoop, tok) end
	end
})

print("══════════════════════════════════════")
print("BF Script Pro v2 | Sea " .. CurrentSea .. " | Lv." .. GetLevel())
print("UI Carregada com sucesso!")
print("══════════════════════════════════════")
data.StepDelay)
            end

            -- Invoke
            local method = data.Invoke[1]
            local arg    = data.Invoke[2]
            CF_(method, arg)
            task.wait(1)

            if HasSword(ST2.SelectedSword) then
                if Win then Win:Notify({Title="Sword", Content=ST2.SelectedSword.." obtida!", Duration=5}) end
                ST2.AutoSpecialSword=false
            end
        end)
    end
end

-- ════════════════════════════════════════
--  ACESSÓRIOS — COMPRA DIRETA
-- ════════════════════════════════════════
local function AutoAccessoryLoop()
    while ST2.AutoAccessory do
        task.wait(0.5)
        pcall(function()
            local hrp = GetHRP(); if not hrp then return end
            local data = AccessoryData[ST2.SelectedAccessory]
            if not data then ST2.AutoAccessory=false; return end

            -- Ir ao NPC
            if (hrp.Position - data.NPC.Position).Magnitude > 20 then
                SetFlyAnchor(false); SafeTween(data.NPC); return
            end
            StopTween()

            -- Verificar beli
            local d=LP:FindFirstChild("Data")
            local beli=d and d.Beli and d.Beli.Value or 0
            if beli < (data.Beli or 0) then
                if Win then Win:Notify({Title="Acessório", Content="Beli insuficiente: "..data.Beli, Duration=4}) end
                task.wait(3); return
            end

            CF_(data.Invoke[1], data.Invoke[2])
            task.wait(1)

            if Win then Win:Notify({Title="Acessório", Content=ST2.SelectedAccessory.." comprado!", Duration=4}) end
            ST2.AutoAccessory = false
        end)
    end
end

-- ════════════════════════════════════════
--  AUTO MASTERY
-- ════════════════════════════════════════
local MasterySkillKeys = {
    Sword  = Enum.KeyCode.Z,
    Melee  = Enum.KeyCode.Z,
    Gun    = Enum.KeyCode.Z,
    Fruit  = Enum.KeyCode.Z,
}

local function GetMasteryPct(mob)
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum then return 100 end
    return (hum.Health / hum.MaxHealth) * 100
end

local function AutoMasteryLoop()
    while ST2.AutoMastery do
        task.wait(0.05)
        pcall(function()
            local hrp = GetHRP(); local hum = GetHum()
            if not hrp or not hum or hum.Health <= 0 then SetFlyAnchor(false); return end

            EnsureBuso()

            local mob = FindMob(ST2.MasteryMob)
            if not mob then
                SetFlyAnchor(false)
                SafeTween(ST2.MasteryMobCF)
                return
            end

            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            local mhum = mob:FindFirstChildOfClass("Humanoid")
            if not mhrp or not mhum then return end

            local dist = (hrp.Position - mhrp.Position).Magnitude
            local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)

            if dist > 40 then
                SetFlyAnchor(false); SafeTween(flyPos); return
            end

            StopTween(); SetFlyAnchor(true)
            hrp.CFrame = flyPos; hrp.Velocity = Vector3.zero
            BringMobs(ST2.MasteryMob, mhrp.CFrame)
            EquipWeapon()

            local hpPct = GetMasteryPct(mob)

            if hpPct > ST2.MasteryHPStop then
                -- Ataque normal até chegar no HP alvo
                FastAttack(mob)
            else
                -- HP baixo: usar habilidade da arma/fruta alvo (Z por padrão)
                local key = MasterySkillKeys[ST2.MasteryWeapon] or Enum.KeyCode.Z
                pcall(function()
                    VirtualInputMgr:SendKeyEvent(true,  key, false, game)
                    task.wait(0.05)
                    VirtualInputMgr:SendKeyEvent(false, key, false, game)
                end)
                task.wait(0.3)
            end
        end)
    end
end

-- ════════════════════════════════════════
--  KILL AURA
-- ════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.05)
        if ST2.KillAura then
            pcall(function()
                local hrp = GetHRP(); if not hrp then return end
                EquipWeapon()
                -- NPCs/Mobs
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mhum = mob:FindFirstChildOfClass("Humanoid")
                        local mhrp = mob:FindFirstChild("HumanoidRootPart")
                        if mhum and mhum.Health > 0 and mhrp then
                            if (hrp.Position - mhrp.Position).Magnitude <= ST2.KillAuraRadius then
                                FastAttack(mob)
                            end
                        end
                    end
                end
                -- Players (se ativado)
                if ST2.KillAuraTargetPlayer then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                            local phum = p.Character:FindFirstChildOfClass("Humanoid")
                            if phrp and phum and phum.Health > 0 then
                                if (hrp.Position - phrp.Position).Magnitude <= ST2.KillAuraRadius then
                                    FastAttack(p.Character)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ════════════════════════════════════════
--  AIMBOT
-- ════════════════════════════════════════
local function FindNearestTarget(includePlayer)
    local hrp = GetHRP(); if not hrp then return nil end
    local nearest, nearDist = nil, math.huge

    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, mob in ipairs(enemies:GetChildren()) do
            local mhum = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if mhum and mhum.Health > 0 and mhrp then
                local d = (hrp.Position - mhrp.Position).Magnitude
                if d < nearDist then nearest = mhrp; nearDist = d end
            end
        end
    end

    if includePlayer then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                local phum = p.Character:FindFirstChildOfClass("Humanoid")
                if phrp and phum and phum.Health > 0 then
                    local d = (GetHRP().Position - phrp.Position).Magnitude
                    if d < nearDist then nearest = phrp; nearDist = d end
                end
            end
        end
    end

    return nearest
end

RunService.RenderStepped:Connect(function()
    if not ST2.AimbotEnabled then return end
    pcall(function()
        local target = FindNearestTarget(ST2.KillAuraTargetPlayer)
        ST2.AimbotTarget = target
        if not target then return end

        -- Lock câmera no alvo
        if ST2.AimbotLockCamera then
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
        end

        -- Rotacionar HRP para o alvo (para skills)
        local hrp = GetHRP()
        if hrp then
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(
                target.Position.X,
                hrp.Position.Y,
                target.Position.Z
            ))
        end
    end)
end)

-- ════════════════════════════════════════
--  AUTO MATERIAL FARM (16 materiais)
-- ════════════════════════════════════════
local MaterialMobMap = {
    ["Scrap Metal"]       = {Mob="Cyborg",          CF=CFrame.new(295,73,-55)},
    ["Leather"]           = {Mob="Gorilla",          CF=CFrame.new(-1142,40,515)},
    ["Magma Ore"]         = {Mob="Military Spy",     CF=CFrame.new(-5787,75,8651)},
    ["Angel Wings"]       = {Mob="God's Guard",      CF=CFrame.new(-4628,866,1931)},
    ["Fish Tail"]         = {Mob="Fishman Warrior",  CF=CFrame.new(60844,98,1298), Entrance=Vector3.new(61163,11,1819)},
    ["Radioactive Material"]={Mob="Zombie",          CF=CFrame.new(-5650,120,-750)},
    ["Vampire Fang"]      = {Mob="Living Zombie",    CF=CFrame.new(-10150,140,5950)},
    ["Mystic Droplet"]    = {Mob="Royal Squad",      CF=CFrame.new(-7600,5600,-1450)},
    ["Mini Tusk"]         = {Mob="Dojo Fighter",     CF=CFrame.new(-16300,60,-350)},
    ["Gunpowder"]         = {Mob="Pirate Millionaire",CF=CFrame.new(-200,45,5900)},
    ["Conjured Cocoa"]    = {Mob="Sweet Thief",      CF=CFrame.new(-1200,20,-14700)},
    ["Dragon Scale"]      = {Mob="Dragon",           CF=CFrame.new(-28000,20,11000)},
    ["Ectoplasm"]         = {Mob="Reborn Skeleton",  CF=CFrame.new(-8750,140,5900)},
    ["Demonic Wisp"]      = {Mob="Living Zombie",    CF=CFrame.new(-10150,140,5950)},
    ["Bones"]             = {Mob="Reborn Skeleton",  CF=CFrame.new(-8750,140,5900)},
    ["Yeti Fur"]          = {Mob="Yeti",             CF=CFrame.new(609,401,-5372)},
    ["Blaze Ember"]       = {Mob="Dojo Fighter",     CF=CFrame.new(-16300,60,-350)},
    ["Cyborg Parts"]      = {Mob="Cyborg",           CF=CFrame.new(295,73,-55)},
}

local ST2Materials = {
    AutoMaterialFarm = false,
    TargetMaterial   = "Dragon Scale",
    MaterialCount    = 10,
}

local function AutoMaterialFarmLoop()
    while ST2Materials.AutoMaterialFarm do
        task.wait(0.1)
        pcall(function()
            local hrp = GetHRP(); local hum = GetHum()
            if not hrp or not hum or hum.Health <= 0 then SetFlyAnchor(false); return end

            local name = ST2Materials.TargetMaterial
            local info = MaterialMobMap[name]
            if not info then ST2Materials.AutoMaterialFarm=false; return end

            -- Checar se já tem o suficiente
            if HasMaterial(name, ST2Materials.MaterialCount) then
                if Win then Win:Notify({Title="Material", Content=name.." coletado!", Duration=4}) end
                ST2Materials.AutoMaterialFarm=false; return
            end

            EnsureBuso()

            -- Entrance especial se necessário
            if info.Entrance then
                local entrDist = (hrp.Position - info.CF.Position).Magnitude
                if entrDist > 3000 then
                    CF_("requestEntrance", info.Entrance)
                    task.wait(0.5)
                end
            end

            local mob = FindMob(info.Mob)
            if mob then
                FarmUntilDead(mob)
            else
                SetFlyAnchor(false); SafeTween(info.CF)
            end
        end)
    end
end

-- ════════════════════════════════════════
--  BIND UI — adiciona tabs ao Win existente
-- ════════════════════════════════════════
if Win then

    -- ── TAB: FIGHTING STYLES ─────────────
    local tFS = Win:MakeTab({Title="Fight Styles"})
    tFS:AddIcon({Name="dumbbell"})

    local styleNames = {}
    for k in pairs(FightingStyleData) do table.insert(styleNames,k) end
    table.sort(styleNames)

    tFS:AddDropdown({Name="Estilo", Options=styleNames, Callback=function(v)
        ST2.SelectedStyle=v
        local d=FightingStyleData[v]
        if d and Win then Win:Notify({Title=v,Content=d.Note,Duration=5}) end
    end})

    tFS:AddToggle({Name="Auto Get Fighting Style", Default=false, Callback=function(v)
        ST2.AutoFightingStyle=v
        if v then task.spawn(AutoFightingStyleLoop) end
    end})

    tFS:AddSection("Info")
    tFS:AddLabel({Text="Selecione o estilo e ative. Script vai ao NPC, verifica requisitos e compra."})

    -- ── TAB: ESPADAS ESPECIAIS ────────────
    local tSW = Win:MakeTab({Title="Espadas"})
    tSW:AddIcon({Name="swords"})

    local swordNames = {}
    for k in pairs(SpecialSwordData) do table.insert(swordNames,k) end
    table.sort(swordNames)

    tSW:AddDropdown({Name="Espada", Options=swordNames, Callback=function(v)
        ST2.SelectedSword=v
        local d=SpecialSwordData[v]
        if d and Win then Win:Notify({Title=v,Content=d.Note,Duration=6}) end
    end})

    tSW:AddToggle({Name="Auto Get Espada", Default=false, Callback=function(v)
        ST2.AutoSpecialSword=v
        if v then task.spawn(AutoSpecialSwordLoop) end
    end})

    tSW:AddSection("Puzzle Swords")
    tSW:AddLabel({Text="Tushita, Yama e CDK têm puzzle de posição automático."})

    -- ── TAB: ACESSÓRIOS ───────────────────
    local tACC = Win:MakeTab({Title="Acessórios"})
    tACC:AddIcon({Name="backpack"})

    local accNames = {}
    for k in pairs(AccessoryData) do table.insert(accNames,k) end
    table.sort(accNames)

    tACC:AddDropdown({Name="Acessório", Options=accNames, Callback=function(v)
        ST2.SelectedAccessory=v
        local d=AccessoryData[v]
        if d and Win then Win:Notify({Title=v,Content=d.Note.." | "..d.Beli.." beli",Duration=5}) end
    end})

    tACC:AddToggle({Name="Auto Comprar Acessório", Default=false, Callback=function(v)
        ST2.AutoAccessory=v
        if v then task.spawn(AutoAccessoryLoop) end
    end})

    -- ── TAB: MASTERY ──────────────────────
    local tMST = Win:MakeTab({Title="Mastery"})
    tMST:AddIcon({Name="target"})

    tMST:AddDropdown({
        Name="Arma para Mastery",
        Options={"Melee","Sword","Gun","Fruit"},
        Callback=function(v) ST2.MasteryWeapon=v end
    })

    tMST:AddTextBox({Name="Mob para Mastery", Default=ST2.MasteryMob, Callback=function(v)
        ST2.MasteryMob=v
        local info=MaterialMobMap[v] -- reutiliza se tiver
        if info then ST2.MasteryMobCF=info.CF end
    end})

    tMST:AddSlider({
        Name="Parar Ataque em HP%",
        Min=5, Max=50, Default=10, Increment=1,
        Callback=function(v) ST2.MasteryHPStop=v end
    })

    tMST:AddToggle({Name="Auto Mastery", Default=false, Callback=function(v)
        ST2.AutoMastery=v
        if v then task.spawn(AutoMasteryLoop) end
    end})

    -- ── TAB: COMBATE ──────────────────────
    local tCMB = Win:MakeTab({Title="Combate"})
    tCMB:AddIcon({Name="crosshair"})  -- usa skull que já confirmamos; crosshair é lucide

    tCMB:AddSection("Kill Aura")
    tCMB:AddToggle({Name="Kill Aura", Default=false, Callback=function(v)
        ST2.KillAura=v
    end})
    tCMB:AddSlider({
        Name="Raio Kill Aura",
        Min=10, Max=200, Default=60, Increment=5,
        Callback=function(v) ST2.KillAuraRadius=v end
    })
    tCMB:AddToggle({Name="Incluir Players", Default=false, Callback=function(v)
        ST2.KillAuraTargetPlayer=v
    end})

    tCMB:AddSection("Aimbot")
    tCMB:AddToggle({Name="Aimbot", Default=false, Callback=function(v)
        ST2.AimbotEnabled=v
    end})
    tCMB:AddToggle({Name="Lock Camera no Alvo", Default=false, Callback=function(v)
        ST2.AimbotLockCamera=v
    end})

    -- ── TAB: MATERIAIS ────────────────────
    local tMAT = Win:MakeTab({Title="Materiais"})
    tMAT:AddIcon({Name="beaker"})

    local matNames = {}
    for k in pairs(MaterialMobMap) do table.insert(matNames,k) end
    table.sort(matNames)

    tMAT:AddDropdown({Name="Material Alvo", Options=matNames, Callback=function(v)
        ST2Materials.TargetMaterial=v
        local info=MaterialMobMap[v]
        if info and Win then
            Win:Notify({Title="Material",Content="Mob: "..info.Mob,Duration=3})
        end
    end})

    tMAT:AddSlider({
        Name="Quantidade Alvo",
        Min=1, Max=100, Default=10, Increment=1,
        Callback=function(v) ST2Materials.MaterialCount=v end
    })

    tMAT:AddToggle({Name="Auto Material Farm", Default=false, Callback=function(v)
        ST2Materials.AutoMaterialFarm=v
        if v then task.spawn(AutoMaterialFarmLoop) end
    end})

end -- if Win

print("══════════════════════════════════════")
print("BF Script Pro v2 | Sea "..CurrentSea.." | Lv."..GetLevel())
print("Tabs: Farm | Missões | Bartilo | Rainbow Haki | Race Quest | Shop")
print("══════════════════════════════════════")