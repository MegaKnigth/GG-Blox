-- ══════════════════════════════════════════════════════════════
--  BLOX FRUITS PROFESSIONAL SCRIPT
--  UI: GG-Ui (MegaKnigth) — loadstring via HttpGet
--  Arquitetura: inspirada em QuocKhanh Hub v3.5 (lógica real)
--  Suporte: Sea 1 / 2 / 3 | Level 1-2840 | PC + Mobile
-- ══════════════════════════════════════════════════════════════

repeat task.wait() until game:IsLoaded()

-- ════════════════════════════════════════
--  SERVIÇOS
-- ════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local VirtualInputMgr  = game:GetService("VirtualInputManager")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")

local LP    = Players.LocalPlayer
repeat task.wait() until LP and LP:FindFirstChild("PlayerGui")
local PGui  = LP:WaitForChild("PlayerGui")

-- Parent seguro (bypass CoreGui detection)
local SafeParent = (gethui and gethui())
    or (syn and syn.protect_gui and (function()
           local f = Instance.new("Folder")
           syn.protect_gui(f); f.Parent = CoreGui; return f
       end)())
    or PGui

-- Limpar instância anterior
for _, n in ipairs({"BFScript_ScreenGui"}) do
    for _, p in ipairs({SafeParent, PGui, CoreGui}) do
        local ex = p:FindFirstChild(n)
        if ex then ex:Destroy() end
    end
end

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Detectar Sea
local CurrentSea = 1
if game.PlaceId == 4442272183 then CurrentSea = 2
elseif game.PlaceId == 7449423635 then CurrentSea = 3 end

-- ════════════════════════════════════════
--  REMOTES (live dump BF Update 20+)
-- ════════════════════════════════════════
local R = {}
pcall(function()
    local rf = ReplicatedStorage:WaitForChild("Remotes", 5)
    if rf then
        R.CommF_   = rf:FindFirstChild("CommF_")
        R.CommE    = rf:FindFirstChild("CommE")
        R.Stats    = rf:FindFirstChild("Stats")
        R.Redeem   = rf:FindFirstChild("Redeem")
        R.Leviathan= rf:FindFirstChild("Leviathan")
        R.Temple   = rf:FindFirstChild("Temple")
        R.Chest    = rf:FindFirstChild("Chest")
    end
    local ev = ReplicatedStorage:FindFirstChild("Events")
    if ev then
        R.ActivateRaceV4 = ev:FindFirstChild("ActivateRaceV4")
        R.UsedRaceSkill  = ev:FindFirstChild("UsedRaceSkill")
    end
end)
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Modules")
    if mod then
        local net = mod:FindFirstChild("Net")
        if net then
            R.RegisterAttack   = net:FindFirstChild("RE/RegisterAttack")
            R.RegisterHit      = net:FindFirstChild("RE/RegisterHit")
            R.CollectBlueEmber = net:FindFirstChild("RE/CollectBlueEmber")
            R.KitsuneStatuePray= net:FindFirstChild("RF/KitsuneStatuePray")
            R.TouchKitsune     = net:FindFirstChild("RE/TouchKitsuneStatue")
        end
    end
end)

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
    -- Farm Mob/Boss
    SelectedMob       = "",
    AutoFarmMob       = false,
    SelectedBoss      = "The Gorilla King",
    AutoFarmBoss      = false,
    -- Chests
    AutoChest         = false,
    ChestCount        = 0,
    TweenSpeed        = 260,
    -- Stats
    AutoStats         = false,
    StatChunk         = 3,
    StatsMap          = {Melee=true, Defense=true, Sword=false, Gun=false, ["Demon Fruit"]=false},
    -- ESP
    ESP_Players       = false,
    ESP_Chests        = false,
    ESP_Fruits        = false,
    ESP_Mobs          = false,
    -- Movement
    WalkSpeed         = 16,
    JumpPower         = 50,
    Noclip            = false,
    InfiniteJump      = false,
    AntiAFK           = true,
    FPSBoost          = false,
    -- Skills
    AutoSkillZ        = false,
    AutoSkillX        = false,
    AutoSkillC        = false,
    AutoSkillV        = false,
    -- Fruit
    AutoSnipeFruit    = false,
    AutoStoreFruit    = false,
    -- Events
    AutoCollectEmbers = false,
    AutoPrayStatue    = false,
    AutoAwakenV4      = false,
    AutoUseRaceSkill  = false,
    AutoMirageGear    = false,
    -- Sea
    AutoLeviathan     = false,
    AutoSeaBeast      = false,
    AutoShipRaid      = false,
    -- Webhook
    EnableWebhook     = false,
    WebhookURL        = "",
    WebhookFile       = "BFScript_Webhook.txt",
}

if isfile and isfile(ST.WebhookFile) then
    pcall(function()
        local u = readfile(ST.WebhookFile)
        if u and #u > 15 then ST.WebhookURL = u:gsub("%s+",""); ST.EnableWebhook = true end
    end)
end

-- ════════════════════════════════════════
--  DADOS DE QUESTS (Level 1-2840, Sea 1-3)
-- ════════════════════════════════════════
local QuestsData = {
    -- SEA 1
    {Min=1,   Max=9,   Quest="BanditQuest1",    Name="Bandit",             Level=1, NPC=CFrame.new(1059,15,1550),   MobCF=CFrame.new(1145,17,1634)},
    {Min=10,  Max=14,  Quest="JungleQuest",      Name="Monkey",             Level=1, NPC=CFrame.new(-1598,35,153),   MobCF=CFrame.new(-1610,22,142)},
    {Min=15,  Max=29,  Quest="JungleQuest",      Name="Gorilla",            Level=2, NPC=CFrame.new(-1598,35,153),   MobCF=CFrame.new(-1240,6,-490)},
    {Min=30,  Max=39,  Quest="BuggyQuest",       Name="Pirate",             Level=1, NPC=CFrame.new(-1141,4,3831),   MobCF=CFrame.new(-1215,4,3880)},
    {Min=40,  Max=59,  Quest="BuggyQuest",       Name="Brute",              Level=2, NPC=CFrame.new(-1141,4,3831),   MobCF=CFrame.new(-1370,15,4135)},
    {Min=60,  Max=74,  Quest="DesertQuest",      Name="Desert Bandit",      Level=1, NPC=CFrame.new(894,5,4392),     MobCF=CFrame.new(995,6,4450)},
    {Min=75,  Max=89,  Quest="DesertQuest",      Name="Desert Officer",     Level=2, NPC=CFrame.new(894,5,4392),     MobCF=CFrame.new(1570,10,4370)},
    {Min=90,  Max=99,  Quest="SnowQuest",        Name="Snow Bandit",        Level=1, NPC=CFrame.new(1389,85,-1298),  MobCF=CFrame.new(1288,106,-1450)},
    {Min=100, Max=119, Quest="SnowQuest",        Name="Snowman",            Level=2, NPC=CFrame.new(1389,85,-1298),  MobCF=CFrame.new(1285,150,-1500)},
    {Min=120, Max=149, Quest="MarineQuest2",     Name="Chief Petty Officer",Level=1, NPC=CFrame.new(-5039,27,4324),  MobCF=CFrame.new(-4880,21,4260)},
    {Min=150, Max=174, Quest="SkyQuest",         Name="Sky Bandit",         Level=1, NPC=CFrame.new(-4839,716,-2619),MobCF=CFrame.new(-4980,278,-2830)},
    {Min=175, Max=189, Quest="SkyQuest",         Name="Dark Master",        Level=2, NPC=CFrame.new(-4839,716,-2619),MobCF=CFrame.new(-5250,388,-2270)},
    {Min=190, Max=209, Quest="PrisonerQuest",    Name="Prisoner",           Level=1, NPC=CFrame.new(5308,0,474),     MobCF=CFrame.new(5410,95,690)},
    {Min=210, Max=224, Quest="PrisonerQuest",    Name="Dangerous Prisoner", Level=2, NPC=CFrame.new(5308,0,474),     MobCF=CFrame.new(5540,95,710)},
    {Min=225, Max=274, Quest="ColosseumQuest",   Name="Toga Warrior",       Level=1, NPC=CFrame.new(-1580,6,-2986),  MobCF=CFrame.new(-1820,50,-2740)},
    {Min=275, Max=299, Quest="ColosseumQuest",   Name="Gladiator",          Level=2, NPC=CFrame.new(-1580,6,-2986),  MobCF=CFrame.new(-1330,50,-3280)},
    {Min=300, Max=324, Quest="MagmaQuest",       Name="Military Soldier",   Level=1, NPC=CFrame.new(-5313,7,8515),   MobCF=CFrame.new(-5410,48,8540)},
    {Min=325, Max=374, Quest="MagmaQuest",       Name="Military Spy",       Level=2, NPC=CFrame.new(-5313,7,8515),   MobCF=CFrame.new(-5820,77,8820)},
    {Min=375, Max=399, Quest="FishmanQuest",     Name="Fishman Warrior",    Level=1, NPC=CFrame.new(61122,17,1569),  MobCF=CFrame.new(60900,90,1500)},
    {Min=400, Max=449, Quest="FishmanQuest",     Name="Fishman Commando",   Level=2, NPC=CFrame.new(61122,17,1569),  MobCF=CFrame.new(61800,90,1450)},
    {Min=450, Max=474, Quest="SkyExp1Quest",     Name="God's Guard",        Level=1, NPC=CFrame.new(-4721,843,-1949),MobCF=CFrame.new(-4620,850,-1900)},
    {Min=475, Max=524, Quest="SkyExp1Quest",     Name="Shanda",             Level=2, NPC=CFrame.new(-4721,843,-1949),MobCF=CFrame.new(-7680,5560,-500)},
    {Min=525, Max=624, Quest="SkyExp2Quest",     Name="Royal Squad",        Level=1, NPC=CFrame.new(-7906,5634,-1411),MobCF=CFrame.new(-7600,5600,-1450)},
    {Min=625, Max=649, Quest="FountainQuest",    Name="Galley Pirate",      Level=1, NPC=CFrame.new(5259,37,4050),   MobCF=CFrame.new(5590,45,3990)},
    {Min=650, Max=699, Quest="FountainQuest",    Name="Galley Captain",     Level=2, NPC=CFrame.new(5259,37,4050),   MobCF=CFrame.new(5650,45,4950)},
    -- SEA 2
    {Min=700, Max=724,  Quest="Area1Quest",      Name="Raider",             Level=1, NPC=CFrame.new(-429,72,1836),   MobCF=CFrame.new(-730,40,2380)},
    {Min=725, Max=774,  Quest="Area1Quest",      Name="Mercenary",          Level=2, NPC=CFrame.new(-429,72,1836),   MobCF=CFrame.new(-960,75,1750)},
    {Min=775, Max=799,  Quest="Area2Quest",      Name="Swan Pirate",        Level=1, NPC=CFrame.new(638,72,918),     MobCF=CFrame.new(900,120,1200)},
    {Min=800, Max=874,  Quest="Area2Quest",      Name="Factory Staff",      Level=2, NPC=CFrame.new(638,72,918),     MobCF=CFrame.new(295,73,-55)},
    {Min=875, Max=899,  Quest="MarineQuest3",    Name="Marine Lieutenant",  Level=1, NPC=CFrame.new(-2440,72,-3217), MobCF=CFrame.new(-2700,75,-3000)},
    {Min=900, Max=949,  Quest="MarineQuest3",    Name="Marine Captain",     Level=2, NPC=CFrame.new(-2440,72,-3217), MobCF=CFrame.new(-1900,75,-3300)},
    {Min=950, Max=999,  Quest="ZombieQuest",     Name="Zombie",             Level=1, NPC=CFrame.new(-5497,48,-795),  MobCF=CFrame.new(-5650,120,-750)},
    {Min=1000,Max=1099, Quest="SnowMountainQuest",Name="Snow Trooper",      Level=1, NPC=CFrame.new(609,401,-5372),  MobCF=CFrame.new(480,420,-5600)},
    {Min=1100,Max=1249, Quest="ShipQuest1",      Name="Ship Deckhand",      Level=1, NPC=CFrame.new(1008,125,32911), MobCF=CFrame.new(1180,140,32990)},
    {Min=1250,Max=1499, Quest="FrostQuest",      Name="Sea Soldier",        Level=1, NPC=CFrame.new(-3054,237,-10145),MobCF=CFrame.new(-3300,240,-10400)},
    -- SEA 3
    {Min=1500,Max=1574, Quest="PiratePortQuest", Name="Pirate Millionaire", Level=1, NPC=CFrame.new(-289,44,5580),   MobCF=CFrame.new(-200,45,5900)},
    {Min=1575,Max=1699, Quest="PiratePortQuest", Name="Pistol Billionaire", Level=2, NPC=CFrame.new(-289,44,5580),   MobCF=CFrame.new(-400,75,5950)},
    {Min=1700,Max=1824, Quest="AmazonQuest",     Name="Female Islander",    Level=1, NPC=CFrame.new(5832,51,-1100),   MobCF=CFrame.new(5400,80,-1000)},
    {Min=1825,Max=1974, Quest="MarineTreeIsland",Name="Marine Commodore",   Level=1, NPC=CFrame.new(2180,28,-6740),   MobCF=CFrame.new(2450,75,-6700)},
    {Min=1975,Max=2074, Quest="HauntedQuest1",   Name="Reborn Skeleton",    Level=1, NPC=CFrame.new(-9515,142,5536),  MobCF=CFrame.new(-8750,140,5900)},
    {Min=2075,Max=2199, Quest="HauntedQuest2",   Name="Living Zombie",      Level=1, NPC=CFrame.new(-9515,142,5536),  MobCF=CFrame.new(-10150,140,5950)},
    {Min=2200,Max=2299, Quest="CandyQuest1",     Name="Candy Rebel",        Level=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1000,20,-14200)},
    {Min=2300,Max=2449, Quest="CandyQuest2",     Name="Sweet Thief",        Level=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1200,20,-14700)},
    {Min=2450,Max=2599, Quest="TikiQuest1",      Name="Isle Outlaw",        Level=1, NPC=CFrame.new(-16547,55,-172),  MobCF=CFrame.new(-16800,30,-150)},
    {Min=2600,Max=2840, Quest="DragonDojoQuest", Name="Dojo Fighter",       Level=1, NPC=CFrame.new(-16547,55,-172),  MobCF=CFrame.new(-16300,60,-350)},
}

local Waypoints = {
    ["Windmill (Sea 1 Start)"]       = CFrame.new(1059,15,1550),
    ["Marine Starter"]               = CFrame.new(-2855,7,5354),
    ["Jungle"]                       = CFrame.new(-1598,35,153),
    ["Pirate Village"]               = CFrame.new(-1141,4,3831),
    ["Desert"]                       = CFrame.new(894,5,4392),
    ["Frozen Village"]               = CFrame.new(1389,85,-1298),
    ["MarineFord"]                   = CFrame.new(-5039,27,4324),
    ["Sky Island"]                   = CFrame.new(-4839,716,-2619),
    ["Prison"]                       = CFrame.new(5308,0,474),
    ["Colosseum"]                    = CFrame.new(-1580,6,-2986),
    ["Magma Island"]                 = CFrame.new(-5313,7,8515),
    ["Underwater City"]              = CFrame.new(61122,17,1569),
    ["Fountain City"]                = CFrame.new(5259,37,4050),
    ["Temple of Time"]               = CFrame.new(28282,14896,102),
    ["Kitsune Island"]               = CFrame.new(-22123,22,-12345),
}

-- ════════════════════════════════════════
--  HELPERS DE PERSONAGEM
-- ════════════════════════════════════════
local function GetChar()   return LP.Character end
local function GetHRP()    local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()    local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function GetLevel()
    local d = LP:FindFirstChild("Data")
    return d and d:FindFirstChild("Level") and d.Level.Value or 1
end

local function GetQuestData()
    local lv = GetLevel()
    for _, q in ipairs(QuestsData) do
        if lv >= q.Min and lv <= q.Max then return q end
    end
    return QuestsData[#QuestsData]
end

-- ════════════════════════════════════════
--  SAFETWEEN
-- ════════════════════════════════════════
local curTween, tweenDest
local function SafeTween(targetCF, spd)
    local hrp = GetHRP()
    if not hrp then return end
    local speed = spd or ST.TweenSpeed
    local dist = (hrp.Position - targetCF.Position).Magnitude
    if dist <= 15 then hrp.CFrame = targetCF; return end
    if tweenDest and (tweenDest.Position - targetCF.Position).Magnitude < 8 and curTween then return end
    if curTween then curTween:Cancel() end
    tweenDest = targetCF
    local ti = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    curTween = TweenService:Create(hrp, ti, {CFrame = targetCF})
    curTween:Play()
    curTween.Completed:Connect(function() curTween = nil; tweenDest = nil end)
end

local function StopTween()
    if curTween then curTween:Cancel(); curTween = nil; tweenDest = nil end
end

-- ════════════════════════════════════════
--  FLY ANCHOR (anti-gravidade)
-- ════════════════════════════════════════
local function SetFlyAnchor(en)
    local hrp = GetHRP()
    if not hrp then return end
    local bv = hrp:FindFirstChild("BF_FlyVelocity")
    if en then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "BF_FlyVelocity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity  = Vector3.zero
            bv.Parent = hrp
        else
            bv.Velocity = Vector3.zero
        end
    else
        if bv then bv:Destroy() end
    end
end

-- ════════════════════════════════════════
--  EQUIPAR ARMA
-- ════════════════════════════════════════
local function EquipWeapon()
    local c = GetChar()
    if not c then return end
    local hum = GetHum()
    if not hum then return end
    -- Já tem uma tool?
    if c:FindFirstChildOfClass("Tool") then return end
    local bp = LP.Backpack
    -- Preferência: ToolTip ou atributo
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and (t.ToolTip == ST.WeaponType or t:GetAttribute("WeaponType") == ST.WeaponType) then
            hum:EquipTool(t); return
        end
    end
    -- Fallback: qualquer tool
    local any = bp:FindFirstChildOfClass("Tool")
    if any then hum:EquipTool(any) end
end

-- ════════════════════════════════════════
--  FAST ATTACK v4
-- ════════════════════════════════════════
local CombatFW
pcall(function()
    if LP.PlayerScripts:FindFirstChild("CombatFramework") then
        CombatFW = require(LP.PlayerScripts.CombatFramework)
    end
end)

local function FastAttack(mob)
    pcall(function()
        local c = GetChar()
        if not c then return end
        local tool = c:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        if CombatFW and CombatFW.activeController then
            local ac = CombatFW.activeController
            ac.hitboxMagnitude = 60
            ac.timeToNextAttack = 0
            ac.attacking = false
            pcall(function() ac:attack() end)
        end
        if R.RegisterAttack then R.RegisterAttack:FireServer(0) end
        if mob and R.RegisterHit then
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if mhrp then
                R.RegisterHit:FireServer(mhrp, {{mhrp, mhrp.Position}})
            end
        end
    end)
end

-- ════════════════════════════════════════
--  BRING MOBS AOE
-- ════════════════════════════════════════
local function BringMobs(mobName, centerCF)
    if not ST.BringMob then return end
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return end
        for _, mob in ipairs(enemies:GetChildren()) do
            if string.find(mob.Name, mobName) then
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                local mhum = mob:FindFirstChildOfClass("Humanoid")
                if mhrp and mhum and mhum.Health > 0 then
                    if (mhrp.Position - centerCF.Position).Magnitude <= ST.BringMobDist then
                        mhrp.Size        = Vector3.new(60, 60, 60)
                        mhrp.Transparency = 0.85
                        mhrp.CanCollide  = false
                        mhrp.CFrame      = centerCF
                        mhrp.Velocity    = Vector3.zero
                        mhum.WalkSpeed   = 0
                        mhum.JumpPower   = 0
                    end
                end
            end
        end
    end)
end

-- ════════════════════════════════════════
--  AUTO SKILLS (Z X C V)
-- ════════════════════════════════════════
local function TriggerSkills()
    local function tap(key)
        VirtualInputMgr:SendKeyEvent(true,  key, false, game)
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

-- ════════════════════════════════════════
--  BUSO HAKI AUTO
-- ════════════════════════════════════════
local lastBuso = 0
local function EnsureBuso()
    if not ST.AutoBuso then return end
    if tick() - lastBuso < 5 then return end
    lastBuso = tick()
    pcall(function()
        local c = GetChar()
        if c and R.CommF_ and not (c:GetAttribute("HasBuso") == true) then
            R.CommF_:InvokeServer("Buso")
        end
    end)
end

-- ════════════════════════════════════════
--  DISCORD WEBHOOK
-- ════════════════════════════════════════
local function Webhook(title, desc, color, fields)
    if not ST.EnableWebhook or #ST.WebhookURL < 15 then return end
    task.spawn(function()
        pcall(function()
            local req = (syn and syn.request) or (http and http.request)
                or http_request or request or (fluxus and fluxus.request)
            if not req then return end
            req({
                Url    = ST.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body   = HttpService:JSONEncode({
                    username = "BF Script Pro",
                    embeds   = {{
                        title       = "🔥 " .. title,
                        description = desc,
                        color       = color or 65535,
                        fields      = fields or {},
                        footer      = {text = "BF Script • " .. os.date("%d/%m/%Y %H:%M:%S")}
                    }}
                })
            })
        end)
    end)
end

-- ════════════════════════════════════════
--  ESP HIGHLIGHT
-- ════════════════════════════════════════
local espCache = {}

local function CreateESP(obj, label, color)
    if espCache[obj] then return end
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.FillColor          = color
        hl.OutlineColor       = Color3.new(1,1,1)
        hl.FillTransparency   = 0.5
        hl.OutlineTransparency= 0.2
        hl.Adornee            = obj
        hl.Parent             = SafeParent

        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0, 160, 0, 30)
        bb.Adornee     = obj:IsA("Model")
            and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart)
            or obj
        bb.Parent = SafeParent

        local lbl = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text               = label
        lbl.TextColor3         = color
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextSize           = 11
        lbl.TextStrokeTransparency = 0.3
        lbl.Parent = bb

        espCache[obj] = {hl, bb, lbl}

        -- auto-limpa ao sair do workspace
        obj.AncestryChanged:Connect(function()
            if not obj:IsDescendantOf(workspace) then
                for _, v in pairs(espCache[obj] or {}) do pcall(function() v:Destroy() end) end
                espCache[obj] = nil
            end
        end)
    end)
end

local function ClearAllESP()
    for obj, parts in pairs(espCache) do
        for _, v in pairs(parts) do pcall(function() v:Destroy() end) end
        espCache[obj] = nil
    end
end

-- ════════════════════════════════════════
--  LOAD GG-UI
-- ════════════════════════════════════════
loadstring(game:HttpGet("https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"))()
task.wait(1.5) -- aguarda globals

-- Detecta o global que a GG-Ui expõe
local UI = GGUI or GGLib or _G.GGUI or _G.GGLib

if not UI then
    -- Fallback: notifica no output e cria UI mínima para não quebrar
    warn("[BF Script] GG-Ui global não detectado. Cheque o nome exposto pela lib.")
    warn("[BF Script] Tentados: GGUI, GGLib, _G.GGUI, _G.GGLib")
else
    -- ══════════════════════════════════════
    --  CONSTRUÇÃO DOS TABS VIA GG-UI
    -- ══════════════════════════════════════

    -- ── TAB: AUTO FARM LEVEL ──────────────
    local farmTab = UI:AddTab("⚔ Farm Level")

    farmTab:AddToggle("Auto Farm Level", false, function(v)
        ST.AutoFarmLevel = v
        if not v then StopTween(); SetFlyAnchor(false) end
    end)

    farmTab:AddDropdown("Arma", {"Melee","Sword","Blox Fruit","Gun"}, function(v)
        ST.WeaponType = v
    end)

    farmTab:AddToggle("Fast Attack v4", true, function(v)
        ST.FastAttack = v
    end)

    farmTab:AddToggle("Bring Mob AOE", true, function(v)
        ST.BringMob = v
    end)

    farmTab:AddToggle("Auto Buso Haki", true, function(v)
        ST.AutoBuso = v
    end)

    farmTab:AddSlider("Farm Distance", 10, 40, 20, function(v)
        ST.FarmDist = v
    end)

    farmTab:AddSlider("Tween Speed", 100, 400, 260, function(v)
        ST.TweenSpeed = v
    end)

    -- ── TAB: QUÁI & BOSS ─────────────────
    local mobTab = UI:AddTab("👹 Quái & Boss")

    local mobList = {
        "Bandit","Monkey","Gorilla","Pirate","Brute","Desert Bandit","Desert Officer",
        "Snow Bandit","Snowman","Chief Petty Officer","Sky Bandit","Dark Master",
        "Prisoner","Dangerous Prisoner","Toga Warrior","Gladiator",
        "Military Soldier","Military Spy","Fishman Warrior","Fishman Commando",
        "God's Guard","Shanda","Royal Squad","Galley Pirate","Galley Captain",
        "Raider","Mercenary","Swan Pirate","Factory Staff","Marine Lieutenant",
        "Marine Captain","Zombie","Snow Trooper","Ship Deckhand","Sea Soldier",
        "Pirate Millionaire","Pistol Billionaire","Female Islander","Marine Commodore",
        "Reborn Skeleton","Living Zombie","Candy Rebel","Sweet Thief","Isle Outlaw","Dojo Fighter"
    }

    if mobTab.AddDropdown then
        mobTab:AddDropdown("Mob Alvo", mobList, function(v) ST.SelectedMob = v end)
    else
        mobTab:AddTextBox("Nome do Mob", function(v) ST.SelectedMob = v end)
    end

    mobTab:AddToggle("Auto Farm Mob Escolhido", false, function(v)
        ST.AutoFarmMob = v
        if not v then StopTween(); SetFlyAnchor(false) end
    end)

    local bossList = {
        "The Gorilla King","Bobby","Yeti","Vice Admiral","Warden","Chief Warden",
        "Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God","Cyborg",
        "EVO Guard","Darkbeard","Rip_Indra","Dragon","Cake Queen","Soul Reaper"
    }

    if mobTab.AddDropdown then
        mobTab:AddDropdown("Boss Alvo", bossList, function(v) ST.SelectedBoss = v end)
    else
        mobTab:AddTextBox("Nome do Boss", function(v) ST.SelectedBoss = v end)
    end

    mobTab:AddToggle("Auto Farm Boss", false, function(v)
        ST.AutoFarmBoss = v
        if not v then StopTween(); SetFlyAnchor(false) end
    end)

    -- ── TAB: RƯƠNG & STATS ───────────────
    local chestTab = UI:AddTab("💎 Rương & Stats")

    chestTab:AddToggle("Auto Nhặt Rương", false, function(v)
        ST.AutoChest = v
        if not v then StopTween() end
    end)

    chestTab:AddSlider("Velocidade Rương", 150, 400, 260, function(v)
        ST.TweenSpeed = v
    end)

    chestTab:AddToggle("Auto Stats", false, function(v)
        ST.AutoStats = v
    end)

    chestTab:AddSlider("Pontos por Rodada", 1, 10, 3, function(v)
        ST.StatChunk = v
    end)

    for _, stat in ipairs({"Melee","Defense","Sword","Gun","Demon Fruit"}) do
        chestTab:AddToggle("Nâng " .. stat, ST.StatsMap[stat] or false, function(v)
            ST.StatsMap[stat] = v
        end)
    end

    -- ── TAB: ESP ─────────────────────────
    local espTab = UI:AddTab("👁 ESP")

    espTab:AddToggle("ESP Players", false, function(v)
        ST.ESP_Players = v
        if not v then ClearAllESP() end
    end)

    espTab:AddToggle("ESP Rương", false, function(v)
        ST.ESP_Chests = v
        if not v then ClearAllESP() end
    end)

    espTab:AddToggle("ESP Frutas", false, function(v)
        ST.ESP_Fruits = v
        if not v then ClearAllESP() end
    end)

    espTab:AddToggle("ESP Quái/Boss", false, function(v)
        ST.ESP_Mobs = v
        if not v then ClearAllESP() end
    end)

    espTab:AddButton("Limpar ESP", function()
        ClearAllESP()
    end)

    -- ── TAB: PLAYER ──────────────────────
    local playerTab = UI:AddTab("👤 Player")

    playerTab:AddSlider("WalkSpeed", 16, 300, 16, function(v)
        ST.WalkSpeed = v
        local hum = GetHum()
        if hum then hum.WalkSpeed = v end
    end)

    playerTab:AddSlider("JumpPower", 50, 350, 50, function(v)
        ST.JumpPower = v
        local hum = GetHum()
        if hum then hum.JumpPower = v end
    end)

    playerTab:AddToggle("Noclip / Xuyên Tường", false, function(v)
        ST.Noclip = v
    end)

    playerTab:AddToggle("Infinite Jump", false, function(v)
        ST.InfiniteJump = v
    end)

    playerTab:AddToggle("Anti-AFK", true, function(v)
        ST.AntiAFK = v
    end)

    playerTab:AddToggle("FPS Boost", false, function(v)
        ST.FPSBoost = v
        if v then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and not p.Parent:FindFirstChild("Humanoid") then
                    pcall(function() p.Material = Enum.Material.SmoothPlastic end)
                end
            end
        end
    end)

    -- ── TAB: SKILLS ──────────────────────
    local skillTab = UI:AddTab("⚡ Skills")

    for _, k in ipairs({"Z","X","C","V"}) do
        skillTab:AddToggle("Auto Skill " .. k, false, function(v)
            ST["AutoSkill"..k] = v
        end)
    end

    skillTab:AddToggle("Auto Fruit Sniper", false, function(v)
        ST.AutoSnipeFruit = v
    end)

    skillTab:AddToggle("Auto Guardar Fruta", false, function(v)
        ST.AutoStoreFruit = v
    end)

    -- ── TAB: EVENTOS ─────────────────────
    local eventTab = UI:AddTab("🦊 Eventos")

    eventTab:AddToggle("Auto Coletar Blue Ember", false, function(v)
        ST.AutoCollectEmbers = v
    end)

    eventTab:AddToggle("Auto Rezar Kitsune", false, function(v)
        ST.AutoPrayStatue = v
    end)

    eventTab:AddButton("Tocar Estátua Kitsune", function()
        pcall(function()
            if R.TouchKitsune then R.TouchKitsune:FireServer() end
        end)
    end)

    eventTab:AddToggle("Auto Awakening V4", false, function(v)
        ST.AutoAwakenV4 = v
    end)

    eventTab:AddToggle("Auto Race Skill V4", false, function(v)
        ST.AutoUseRaceSkill = v
    end)

    eventTab:AddToggle("Auto Mirage Gear", false, function(v)
        ST.AutoMirageGear = v
    end)

    eventTab:AddToggle("Auto Leviathan", false, function(v)
        ST.AutoLeviathan = v
    end)

    eventTab:AddToggle("Auto Sea Beast", false, function(v)
        ST.AutoSeaBeast = v
    end)

    eventTab:AddToggle("Auto Ship Raid", false, function(v)
        ST.AutoShipRaid = v
    end)

    -- ── TAB: TELEPORT ────────────────────
    local tpTab = UI:AddTab("🌌 Teleport")

    local wpNames = {}
    for k in pairs(Waypoints) do table.insert(wpNames, k) end
    table.sort(wpNames)

    local chosenWP = wpNames[1]

    if tpTab.AddDropdown then
        tpTab:AddDropdown("Ilha", wpNames, function(v)
            chosenWP = v
        end)
    end

    tpTab:AddButton("Ir para Ilha", function()
        local cf = Waypoints[chosenWP]
        if cf then SafeTween(cf) end
    end)

    tpTab:AddButton("Parar Voo", function()
        StopTween(); SetFlyAnchor(false)
    end)

    tpTab:AddButton("Server Hop", function()
        pcall(function()
            local data = HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
            )
            for _, s in ipairs(data.data or {}) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    break
                end
            end
        end)
    end)

    tpTab:AddButton("Rejoin", function()
        TeleportService:Teleport(game.PlaceId, LP)
    end)

    -- ── TAB: MISC ────────────────────────
    local miscTab = UI:AddTab("⚙ Misc")

    miscTab:AddTextBox("Webhook URL", function(v)
        local url = v:gsub("%s+","")
        ST.WebhookURL = url
        if writefile then writefile(ST.WebhookFile, url) end
        ST.EnableWebhook = #url > 15
    end)

    miscTab:AddToggle("Enviar Webhook", false, function(v)
        ST.EnableWebhook = v
    end)

    miscTab:AddButton("Testar Webhook", function()
        Webhook("Teste de Conexão", "BF Script conectado com sucesso!", 65535, {
            {name="Player", value=LP.Name.." (Lv."..GetLevel()..")", inline=true},
            {name="Sea", value="Sea "..CurrentSea, inline=true},
        })
    end)

    miscTab:AddButton("Resgatar Codes", function()
        local codes = {
            "SUB2GAMERROBOT_EXP1","KITT_RESET","Sub2Fer999","StrawHatMaine",
            "Sub2OfficialNoobie","THEGREATACE","AXIORE","TantaiGaming",
            "BLUXXY","fudd10","BIGNEWS","CHANDLER","FUDD10_V2"
        }
        for _, c in ipairs(codes) do
            pcall(function()
                if R.Redeem then R.Redeem:InvokeServer(c) end
            end)
            task.wait(0.3)
        end
    end)
end

-- ════════════════════════════════════════
--  BACKGROUND TASKS
-- ════════════════════════════════════════

-- ── 1. AUTO FARM LEVEL
task.spawn(function()
    while true do
        task.wait(0.03)
        if ST.AutoFarmLevel then
            pcall(function()
                local hrp = GetHRP(); local hum = GetHum()
                if not hrp or not hum or hum.Health <= 0 then
                    SetFlyAnchor(false); return
                end
                local q = GetQuestData()
                EnsureBuso()

                -- Checar se tem quest ativa
                local questGui = PGui:FindFirstChild("Main")
                    and PGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible

                if not hasQuest then
                    -- Sem quest: ir ao NPC
                    SetFlyAnchor(false)
                    if (hrp.Position - q.NPC.Position).Magnitude > 20 then
                        SafeTween(q.NPC)
                    else
                        StopTween()
                        hrp.CFrame = q.NPC
                        if R.CommF_ then
                            R.CommF_:InvokeServer("StartQuest", q.Quest, q.Level)
                        end
                        task.wait(0.4)
                    end
                else
                    -- Com quest: procurar mob
                    local enemies = workspace:FindFirstChild("Enemies")
                    local target
                    if enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            if string.find(mob.Name, q.Name) then
                                local mhum = mob:FindFirstChildOfClass("Humanoid")
                                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                                if mhum and mhum.Health > 0 and mhrp then
                                    target = mob; break
                                end
                            end
                        end
                    end

                    if target and target:FindFirstChild("HumanoidRootPart") then
                        local mhrp = target.HumanoidRootPart
                        local dist = (hrp.Position - mhrp.Position).Magnitude
                        local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)

                        if dist > 40 then
                            SetFlyAnchor(false)
                            SafeTween(flyPos)
                        else
                            StopTween(); SetFlyAnchor(true)
                            hrp.CFrame = flyPos
                            hrp.Velocity = Vector3.zero
                            BringMobs(q.Name, mhrp.CFrame)
                            EquipWeapon()
                            if ST.FastAttack then FastAttack(target) end
                            TriggerSkills()
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

-- ── 2. AUTO FARM MOB ESCOLHIDO
task.spawn(function()
    while true do
        task.wait(0.05)
        if ST.AutoFarmMob and not ST.AutoFarmLevel then
            pcall(function()
                local hrp = GetHRP(); local hum = GetHum()
                if not hrp or not hum or hum.Health <= 0 then SetFlyAnchor(false); return end
                EnsureBuso()
                local enemies = workspace:FindFirstChild("Enemies")
                local target
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        if string.find(mob.Name, ST.SelectedMob) then
                            local mh = mob:FindFirstChildOfClass("Humanoid")
                            local mr = mob:FindFirstChild("HumanoidRootPart")
                            if mh and mh.Health > 0 and mr then target = mob; break end
                        end
                    end
                end
                if target then
                    local mhrp = target.HumanoidRootPart
                    local dist  = (hrp.Position - mhrp.Position).Magnitude
                    local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)
                    if dist > 40 then
                        SetFlyAnchor(false); SafeTween(flyPos)
                    else
                        StopTween(); SetFlyAnchor(true)
                        hrp.CFrame = flyPos; hrp.Velocity = Vector3.zero
                        BringMobs(ST.SelectedMob, mhrp.CFrame)
                        EquipWeapon()
                        if ST.FastAttack then FastAttack(target) end
                        TriggerSkills()
                    end
                else
                    SetFlyAnchor(false)
                end
            end)
        end
    end
end)

-- ── 3. AUTO FARM BOSS
task.spawn(function()
    while true do
        task.wait(0.1)
        if ST.AutoFarmBoss and not ST.AutoFarmLevel then
            pcall(function()
                local hrp = GetHRP(); local hum = GetHum()
                if not hrp or not hum or hum.Health <= 0 then SetFlyAnchor(false); return end
                EnsureBuso()
                local enemies = workspace:FindFirstChild("Enemies")
                local target
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        if string.find(mob.Name, ST.SelectedBoss) then
                            local mh = mob:FindFirstChildOfClass("Humanoid")
                            local mr = mob:FindFirstChild("HumanoidRootPart")
                            if mh and mh.Health > 0 and mr then target = mob; break end
                        end
                    end
                end
                if target then
                    local mhrp = target.HumanoidRootPart
                    local dist  = (hrp.Position - mhrp.Position).Magnitude
                    local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist + 5, 0), mhrp.Position)
                    if dist > 40 then
                        SetFlyAnchor(false); SafeTween(flyPos)
                    else
                        StopTween(); SetFlyAnchor(true)
                        hrp.CFrame = flyPos; hrp.Velocity = Vector3.zero
                        EquipWeapon()
                        if ST.FastAttack then FastAttack(target) end
                        TriggerSkills()
                    end
                else
                    SetFlyAnchor(false)
                end
            end)
        end
    end
end)

-- ── 4. AUTO CHEST
task.spawn(function()
    while true do
        task.wait(0.4)
        if ST.AutoChest and not ST.AutoFarmLevel and not ST.AutoFarmBoss then
            pcall(function()
                local hrp = GetHRP()
                if not hrp then return end
                local nearest, nearDist = nil, math.huge
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
                        local d = (hrp.Position - obj.Position).Magnitude
                        if d < nearDist then nearest = obj; nearDist = d end
                    end
                end
                if nearest then
                    SafeTween(nearest.CFrame * CFrame.new(0,2,0), ST.TweenSpeed)
                    if nearDist <= 12 then
                        pcall(function()
                            firetouchinterest(hrp, nearest, 0)
                            firetouchinterest(hrp, nearest, 1)
                        end)
                        ST.ChestCount = ST.ChestCount + 1
                        task.wait(0.2)
                    end
                end
            end)
        end
    end
end)

-- ── 5. AUTO STATS
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
                        R.CommF_:InvokeServer("AddPoint", stat, chunk)
                        task.wait(0.08)
                    end
                end
            end)
        end
    end
end)

-- ── 6. ESP
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local myHRP = GetHRP()
            local function dist(p)
                return myHRP and (myHRP.Position - p).Magnitude or 0
            end

            if ST.ESP_Players then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hr = p.Character:FindFirstChild("HumanoidRootPart")
                        local hm = p.Character:FindFirstChildOfClass("Humanoid")
                        if hr and hm and hm.Health > 0 then
                            local d = math.floor(dist(hr.Position))
                            CreateESP(p.Character, p.Name.." ["..d.."m]", Color3.fromRGB(0,230,255))
                        end
                    end
                end
            end

            if ST.ESP_Chests then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name,"Chest") and obj:FindFirstChild("TouchInterest") then
                        local d = math.floor(dist(obj.Position))
                        CreateESP(obj, "💎 Chest ["..d.."m]", Color3.fromRGB(255,215,0))
                    end
                end
            end

            if ST.ESP_Fruits then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if string.find(obj.Name,"Fruit") then
                        CreateESP(obj, "🍎 "..obj.Name, Color3.fromRGB(220,80,255))
                    end
                end
            end

            if ST.ESP_Mobs then
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mh = mob:FindFirstChildOfClass("Humanoid")
                        if mh and mh.Health > 0 then
                            local hp = math.floor(mh.Health)
                            CreateESP(mob, mob.Name.." [HP:"..hp.."]", Color3.fromRGB(255,120,50))
                        end
                    end
                end
            end

            -- Limpa se todos desligados
            if not ST.ESP_Players and not ST.ESP_Chests
            and not ST.ESP_Fruits and not ST.ESP_Mobs then
                ClearAllESP()
            end
        end)
    end
end)

-- ── 7. FRUIT SNIPER & STORE
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local hrp = GetHRP()
            if not hrp then return end

            if ST.AutoSnipeFruit then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if string.find(obj.Name,"Fruit") then
                        local handle = obj:FindFirstChild("Handle") or (obj:IsA("BasePart") and obj)
                        if handle then
                            SafeTween(handle.CFrame, 350)
                            if (hrp.Position - handle.Position).Magnitude <= 10 then
                                pcall(function()
                                    firetouchinterest(hrp, handle, 0)
                                    firetouchinterest(hrp, handle, 1)
                                end)
                                Webhook("Fruta Coletada!", obj.Name.." foi apanhada automaticamente.", 16753920)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end

            if ST.AutoStoreFruit and R.CommF_ then
                for _, t in ipairs(LP.Backpack:GetChildren()) do
                    if t:IsA("Tool") and string.find(t.Name,"Fruit") then
                        R.CommF_:InvokeServer("StoreFruit", t.Name, t)
                        task.wait(0.4)
                    end
                end
            end
        end)
    end
end)

-- ── 8. EVENTOS KITSUNE & V4 & SEA
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local hrp = GetHRP()

            -- Kitsune Blue Ember
            if ST.AutoCollectEmbers and hrp and R.CollectBlueEmber then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if string.find(obj.Name,"Ember") or string.find(obj.Name,"BlueEmber") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                        if part then
                            R.CollectBlueEmber:FireServer(part)
                            SafeTween(part.CFrame, 350)
                            task.wait(0.2)
                        end
                    end
                end
            end

            -- Kitsune Pray
            if ST.AutoPrayStatue and R.KitsuneStatuePray then
                pcall(function() R.KitsuneStatuePray:InvokeServer() end)
            end

            -- V4
            if ST.AutoAwakenV4 and R.ActivateRaceV4 then
                pcall(function() R.ActivateRaceV4:FireServer() end)
            end
            if ST.AutoUseRaceSkill and R.UsedRaceSkill then
                pcall(function() R.UsedRaceSkill:FireServer() end)
            end

            -- Mirage Gear
            if ST.AutoMirageGear and hrp then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "Gear" or string.find(obj.Name,"MirageGear") then
                        SafeTween(obj.CFrame, 350); break
                    end
                end
            end

            -- Leviathan
            if ST.AutoLeviathan and hrp and R.Leviathan then
                local sb = workspace:FindFirstChild("SeaBeasts")
                if sb then
                    for _, beast in ipairs(sb:GetChildren()) do
                        if string.find(beast.Name,"Leviathan") then
                            local bhrp = beast:FindFirstChild("HumanoidRootPart")
                            if bhrp then
                                SafeTween(bhrp.CFrame * CFrame.new(0,30,0))
                                EquipWeapon(); FastAttack(beast)
                                R.Leviathan:FireServer("Hit", bhrp)
                            end
                        end
                    end
                end
            end

            -- Sea Beast
            if ST.AutoSeaBeast and hrp then
                local sb = workspace:FindFirstChild("SeaBeasts") or workspace:FindFirstChild("Enemies")
                if sb then
                    for _, beast in ipairs(sb:GetChildren()) do
                        if string.find(beast.Name,"SeaBeast") then
                            local bhrp = beast:FindFirstChild("HumanoidRootPart")
                            if bhrp then
                                SafeTween(bhrp.CFrame * CFrame.new(0,35,0))
                                EquipWeapon(); FastAttack(beast)
                            end
                        end
                    end
                end
            end

            -- Ship Raid
            if ST.AutoShipRaid and hrp then
                local boats = workspace:FindFirstChild("Boats") or workspace:FindFirstChild("Enemies")
                if boats then
                    for _, boat in ipairs(boats:GetChildren()) do
                        if string.find(boat.Name,"Brigade") or string.find(boat.Name,"Ship") then
                            local bhrp = boat:FindFirstChild("HumanoidRootPart") or boat:FindFirstChildOfClass("BasePart")
                            if bhrp then
                                SafeTween(bhrp.CFrame * CFrame.new(0,25,0))
                                EquipWeapon(); FastAttack(boat)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ── 9. NOCLIP + WALKSPEED PERSISTENTE
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
            if hum.JumpPower  ~= ST.JumpPower  then hum.JumpPower  = ST.JumpPower  end
        end
    end)
end)

-- ── 10. INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if ST.InfiniteJump then
        local hum = GetHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── 11. ANTI-AFK
LP.Idled:Connect(function()
    if ST.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ── 12. CHARACTER RESPAWN — reconecta tudo
LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = ST.WalkSpeed
    hum.JumpPower = ST.JumpPower
    if ST.AutoFarmLevel then SetFlyAnchor(false) end
end)

print("══════════════════════════════════════")
print("✅ BF Script Pro carregado com sucesso")
print("🌊 Sea " .. CurrentSea .. " | Level " .. GetLevel())
print("══════════════════════════════════════")end
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
	Title = "GG Blox v2.9",
	Content = "Carregado · Sea " .. SEA .. " · Motor de ataque Hardcore ativado",
	Duration = 6,
})