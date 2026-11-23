repeat task.wait() until game:IsLoaded()

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local CurrentSea = 1
if game.PlaceId == 4442272183 then CurrentSea = 2
elseif game.PlaceId == 7449423635 then CurrentSea = 3 end

-- ════════════════════════════════════════
--  CARREGAMENTO DA UI (MÉTODO DIRETO)
-- ════════════════════════════════════════
local UI_URL = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
local uiSource = game:HttpGet(UI_URL)
local GGUI_LIB = loadstring(uiSource)()

if not GGUI_LIB or type(GGUI_LIB.MakeWindow) ~= "function" then
    warn("[BF Script] Falha ao carregar GGUI.")
    return
end

local Win = GGUI_LIB:MakeWindow({
    Title = "BF Script Básico",
    SubTitle = "Sea " .. tostring(CurrentSea) .. " | Lv." .. tostring(1),
    ScriptFolder = "BFScriptBasico",
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

-- ════════════════════════════════════════
--  REMOTES E VARIÁVEIS BÁSICAS
-- ════════════════════════════════════════
local R = {}
pcall(function()
    local rf = ReplicatedStorage:WaitForChild("Remotes", 5)
    if not rf then return end
    for _, name in ipairs({"CommF_", "CommE", "Stats", "Redeem"}) do
        R[name] = rf:FindFirstChild(name)
    end
    local mod = ReplicatedStorage:FindFirstChild("Modules")
    if mod and mod:FindFirstChild("Net") then
        R["RE/RegisterAttack"] = mod.Net:FindFirstChild("RE/RegisterAttack")
        R["RE/RegisterHit"] = mod.Net:FindFirstChild("RE/RegisterHit")
    end
end)

local function CF_(method, ...)
    if R.CommF_ then return R.CommF_:InvokeServer(method, ...) end
end

local ST = {
    FarmLevel = false,
    FarmMob = false,
    MobNome = "",
    FarmBoss = false,
    BossNome = "The Gorilla King",
    RoubarBau = false,
    AutoStats = false,
    StatChunk = 3,
    StatsMap = {Melee=true, Defense=true, Sword=false, Gun=false, ["Demon Fruit"]=false},
    ESP_Jogadores = false,
    ESP_Baus = false,
    ESP_Mobs = false,
    Velocidade = 16,
    PuloForca = 50,
    Noclip = false,
    PuloInfinito = false,
    AntiAFK = true,
    AutoSkillZ = false, AutoSkillX = false, AutoSkillC = false, AutoSkillV = false,
    WeaponType = "Melee",
    FastAttack = true,
    BringMob = true,
    FarmDist = 20,
    AutoBuso = true,
    TweenSpeed = 260,
    VelocidadeVoo = 260,
    BringMobDist = 350,
}

-- ════════════════════════════════════════
--  TABELA DE QUESTS COMPLETA (Até Lv 2840)
-- ════════════════════════════════════════
local QuestsData = {
    -- ══════════ SEA 1 ══════════
    {Min=1, Max=9, Quest="BanditQuest1", Nome="Bandit", Level=1, NPC=CFrame.new(1060.9,16.4,1547.7), MobCF=CFrame.new(1038.5,41.2,1576.5)},
    {Min=10, Max=14, Quest="JungleQuest", Nome="Monkey", Level=1, NPC=CFrame.new(-1601.6,36.8,153.3), MobCF=CFrame.new(-1448.1,50.8,63.6)},
    {Min=15, Max=29, Quest="JungleQuest", Nome="Gorilla", Level=2, NPC=CFrame.new(-1601.6,36.8,153.3), MobCF=CFrame.new(-1142.6,40.4,515.3)},
    {Min=30, Max=39, Quest="BuggyQuest1", Nome="Pirate", Level=1, NPC=CFrame.new(-1140.1,4.7,3827.4), MobCF=CFrame.new(-1201.0,40.6,3857.5)},
    {Min=40, Max=59, Quest="BuggyQuest1", Nome="Brute", Level=2, NPC=CFrame.new(-1140.1,4.7,3827.4), MobCF=CFrame.new(-1387.5,24.5,4100.9)},
    {Min=60, Max=74, Quest="DesertQuest", Nome="Desert Bandit", Level=1, NPC=CFrame.new(896.5,6.4,4390.1), MobCF=CFrame.new(984.9,16.1,4417.9)},
    {Min=75, Max=89, Quest="DesertQuest", Nome="Desert Officer", Level=2, NPC=CFrame.new(896.5,6.4,4390.1), MobCF=CFrame.new(1547.1,14.4,4381.8)},
    {Min=90, Max=99, Quest="SnowQuest", Nome="Snow Bandit", Level=1, NPC=CFrame.new(1386.8,87.2,1298.3), MobCF=CFrame.new(1356.3,105.7,1328.2)},
    {Min=100, Max=119, Quest="SnowQuest", Nome="Snowman", Level=2, NPC=CFrame.new(1386.8,87.2,1298.3), MobCF=CFrame.new(1218.7,138.0,1488.0)},
    {Min=120, Max=149, Quest="MarineQuest2", Nome="Chief Petty Officer", Level=1, NPC=CFrame.new(-5035.4,28.6,4324.1), MobCF=CFrame.new(-4931.1,65.7,4121.8)},
    {Min=150, Max=174, Quest="SkyQuest", Nome="Sky Bandit", Level=1, NPC=CFrame.new(-4842.1,717.6,2623.0), MobCF=CFrame.new(-4955.6,365.4,2908.1)},
    {Min=175, Max=189, Quest="SkyQuest", Nome="Dark Master", Level=2, NPC=CFrame.new(-4842.1,717.6,2623.0), MobCF=CFrame.new(-5148.1,439.0,2332.9)},
    {Min=190, Max=209, Quest="PrisonerQuest", Nome="Prisoner", Level=1, NPC=CFrame.new(5310.6,0.3,474.9), MobCF=CFrame.new(4937.3,0.3,649.5)},
    {Min=210, Max=249, Quest="PrisonerQuest", Nome="Dangerous Prisoner", Level=2, NPC=CFrame.new(5310.6,0.3,474.9), MobCF=CFrame.new(5099.6,0.3,1055.7)},
    {Min=250, Max=274, Quest="ColosseumQuest", Nome="Toga Warrior", Level=1, NPC=CFrame.new(-1577.7,7.4,2984.4), MobCF=CFrame.new(-1872.5,49.0,2913.8)},
    {Min=275, Max=299, Quest="ColosseumQuest", Nome="Gladiator", Level=2, NPC=CFrame.new(-1577.7,7.4,2984.4), MobCF=CFrame.new(-1521.3,81.2,3066.3)},
    {Min=300, Max=324, Quest="MagmaQuest", Nome="Military Soldier", Level=1, NPC=CFrame.new(-5316.1,12.2,8517.0), MobCF=CFrame.new(-5369.0,61.2,8556.4)},
    {Min=325, Max=374, Quest="MagmaQuest", Nome="Military Spy", Level=2, NPC=CFrame.new(-5316.1,12.2,8517.0), MobCF=CFrame.new(-5787.0,75.8,8651.6)},
    {Min=375, Max=399, Quest="FishmanQuest", Nome="Fishman Warrior", Level=1, NPC=CFrame.new(61122.6,18.4,1569.3), MobCF=CFrame.new(60844.1,98.4,1298.3), Entrance=Vector3.new(61163.8,11.6,1819.7)},
    {Min=400, Max=449, Quest="FishmanQuest", Nome="Fishman Commando", Level=2, NPC=CFrame.new(61122.6,18.4,1569.3), MobCF=CFrame.new(61738.3,64.2,1433.8), Entrance=Vector3.new(61163.8,11.6,1819.7)},
    {Min=450, Max=474, Quest="SkyExp1Quest", Nome="God's Guard", Level=1, NPC=CFrame.new(-4721.8,845.3,1953.8), MobCF=CFrame.new(-4628.0,866.9,1931.2), Entrance=Vector3.new(-4607.8,872.5,-1667.5)},
    {Min=475, Max=524, Quest="SkyExp1Quest", Nome="Shanda", Level=2, NPC=CFrame.new(-4721.8,845.3,1953.8), MobCF=CFrame.new(-7680,5560,-500), Entrance=Vector3.new(-4607.8,872.5,-1667.5)},
    {Min=525, Max=624, Quest="SkyExp2Quest", Nome="Royal Squad", Level=1, NPC=CFrame.new(-7906,5634,-1411), MobCF=CFrame.new(-7600,5600,-1450)},
    {Min=625, Max=649, Quest="FountainQuest", Nome="Galley Pirate", Level=1, NPC=CFrame.new(5259,37,4050), MobCF=CFrame.new(5590,45,3990)},
    {Min=650, Max=699, Quest="FountainQuest", Nome="Galley Captain", Level=2, NPC=CFrame.new(5259,37,4050), MobCF=CFrame.new(5650,45,4950)},
    -- ══════════ SEA 2 ══════════
    {Min=700, Max=724, Quest="Area1Quest", Nome="Raider", Level=1, NPC=CFrame.new(-429,72,1836), MobCF=CFrame.new(-730,40,2380)},
    {Min=725, Max=774, Quest="Area1Quest", Nome="Mercenary", Level=2, NPC=CFrame.new(-429,72,1836), MobCF=CFrame.new(-960,75,1750)},
    {Min=775, Max=799, Quest="Area2Quest", Nome="Swan Pirate", Level=1, NPC=CFrame.new(638,72,918), MobCF=CFrame.new(900,120,1200)},
    {Min=800, Max=874, Quest="Area2Quest", Nome="Factory Staff", Level=2, NPC=CFrame.new(638,72,918), MobCF=CFrame.new(295,73,-55)},
    {Min=875, Max=899, Quest="MarineQuest3", Nome="Marine Lieutenant", Level=1, NPC=CFrame.new(-2440,72,-3217), MobCF=CFrame.new(-2700,75,-3000)},
    {Min=900, Max=949, Quest="MarineQuest3", Nome="Marine Captain", Level=2, NPC=CFrame.new(-2440,72,-3217), MobCF=CFrame.new(-1900,75,-3300)},
    {Min=950, Max=999, Quest="ZombieQuest", Nome="Zombie", Level=1, NPC=CFrame.new(-5497,48,-795), MobCF=CFrame.new(-5650,120,-750)},
    {Min=1000, Max=1099, Quest="SnowMountainQuest", Nome="Snow Trooper", Level=1, NPC=CFrame.new(609,401,-5372), MobCF=CFrame.new(480,420,-5600)},
    {Min=1100, Max=1249, Quest="ShipQuest1", Nome="Ship Deckhand", Level=1, NPC=CFrame.new(1008,125,32911), MobCF=CFrame.new(1180,140,32990)},
    {Min=1250, Max=1499, Quest="FrostQuest", Nome="Sea Soldier", Level=1, NPC=CFrame.new(-3054,237,-10145), MobCF=CFrame.new(-3300,240,-10400)},
    -- ══════════ SEA 3 ══════════
    {Min=1500, Max=1574, Quest="PiratePortQuest", Nome="Pirate Millionaire", Level=1, NPC=CFrame.new(-289,44,5580), MobCF=CFrame.new(-200,45,5900)},
    {Min=1575, Max=1699, Quest="PiratePortQuest", Nome="Pistol Billionaire", Level=2, NPC=CFrame.new(-289,44,5580), MobCF=CFrame.new(-400,75,5950)},
    {Min=1700, Max=1824, Quest="AmazonQuest", Nome="Female Islander", Level=1, NPC=CFrame.new(5832,51,-1100), MobCF=CFrame.new(5400,80,-1000)},
    {Min=1825, Max=1974, Quest="MarineTreeIsland", Nome="Marine Commodore", Level=1, NPC=CFrame.new(2180,28,-6740), MobCF=CFrame.new(2450,75,-6700)},
    {Min=1975, Max=2074, Quest="HauntedQuest1", Nome="Reborn Skeleton", Level=1, NPC=CFrame.new(-9515,142,5536), MobCF=CFrame.new(-8750,140,5900)},
    {Min=2075, Max=2199, Quest="HauntedQuest2", Nome="Living Zombie", Level=1, NPC=CFrame.new(-9515,142,5536), MobCF=CFrame.new(-10150,140,5950)},
    {Min=2200, Max=2299, Quest="CandyQuest1", Nome="Candy Rebel", Level=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1000,20,-14200)},
    {Min=2300, Max=2449, Quest="CandyQuest2", Nome="Sweet Thief", Level=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1200,20,-14700)},
    {Min=2450, Max=2599, Quest="TikiQuest1", Nome="Isle Outlaw", Level=1, NPC=CFrame.new(-16547,55,-172), MobCF=CFrame.new(-16800,30,-150)},
    {Min=2600, Max=2840, Quest="DragonDojoQuest", Nome="Dojo Fighter", Level=1, NPC=CFrame.new(-16547,55,-172), MobCF=CFrame.new(-16300,60,-350)},
}

local function GetChar() return LP.Character end
local function GetHRP() local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function GetLevel() local d = LP:FindFirstChild("Data"); return d and d:FindFirstChild("Level") and d.Level.Value or 1 end
local function GetQuestData() local lv = GetLevel(); for _, q in ipairs(QuestsData) do if lv >= q.Min and lv <= q.Max then return q end end return QuestsData[#QuestsData] end
local function HasActiveQuest() local gui = PGui:FindFirstChild("Main"); if not gui then return false end; local qf = gui:FindFirstChild("Quest"); return qf and qf.Visible or false end

local curTween, tweenDest
local function SafeTween(targetCF, spd)
    local hrp = GetHRP()
    if not hrp or typeof(targetCF) ~= "CFrame" then return end
    local speed = math.max(tonumber(spd) or ST.TweenSpeed or 260, 50)
    local dist = (hrp.Position - targetCF.Position).Magnitude
    if dist <= 10 then hrp.CFrame = targetCF return end
    if tweenDest and (tweenDest.Position - targetCF.Position).Magnitude < 8 and curTween then return end
    if curTween then pcall(function() curTween:Cancel() end) curTween = nil end
    tweenDest = targetCF
    local ti = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    curTween = TweenService:Create(hrp, ti, {CFrame = targetCF})
    curTween:Play()
    curTween.Completed:Connect(function() curTween = nil; tweenDest = nil end)
end

local function StopTween() if curTween then pcall(function() curTween:Cancel() end) curTween = nil end; tweenDest = nil end

local function SetFlyAnchor(en)
    local hrp = GetHRP(); if not hrp then return end
    local bv = hrp:FindFirstChild("BF_FlyVelocity")
    if en then
        if not bv then bv = Instance.new("BodyVelocity"); bv.Name = "BF_FlyVelocity"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.zero; bv.Parent = hrp
        else bv.Velocity = Vector3.zero end
    else if bv then bv:Destroy() end end
end

local function EquipWeapon()
    local c = GetChar(); local hum = GetHum()
    if not c or not hum then return end
    if c:FindFirstChildOfClass("Tool") then return end
    local bp = LP:FindFirstChild("Backpack"); if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and (t.ToolTip == ST.WeaponType or t:GetAttribute("WeaponType") == ST.WeaponType) then hum:EquipTool(t) return end
    end
    local any = bp:FindFirstChildOfClass("Tool")
    if any then hum:EquipTool(any) end
end

local CombatFW
pcall(function()
    if LP.PlayerScripts:FindFirstChild("CombatFramework") then CombatFW = require(LP.PlayerScripts.CombatFramework) end
end)

local function FastAttack(mob)
    pcall(function()
        local c = GetChar(); if not c then return end
        local tool = c:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
        if CombatFW and CombatFW.activeController then
            local ac = CombatFW.activeController
            ac.hitboxMagnitude = 60; ac.timeToNextAttack = 0; ac.attacking = false
            pcall(function() ac:attack() end)
        end
        if R["RE/RegisterAttack"] then R["RE/RegisterAttack"]:FireServer(0) end
        if mob and R["RE/RegisterHit"] then
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if mhrp then R["RE/RegisterHit"]:FireServer(mhrp, {{mhrp, mhrp.Position}}) end
        end
    end)
end

local function BringMobs(mobName, centerCF)
    if not ST.BringMob or not mobName or mobName == "" then return end
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies"); if not enemies then return end
        for _, mob in ipairs(enemies:GetChildren()) do
            if string.find(mob.Name, mobName) then
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                local mhum = mob:FindFirstChildOfClass("Humanoid")
                if mhrp and mhum and mhum.Health > 0 then
                    if (mhrp.Position - centerCF.Position).Magnitude <= ST.BringMobDist then
                        mhrp.Size = Vector3.new(60, 60, 60); mhrp.Transparency = 0.85; mhrp.CanCollide = false
                        mhrp.CFrame = centerCF; mhrp.AssemblyLinearVelocity = Vector3.zero
                        mhum.WalkSpeed = 0; mhum.JumpPower = 0
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
        VirtualInputMgr:SendKeyEvent(true, key, false, game); task.wait(0.01); VirtualInputMgr:SendKeyEvent(false, key, false, game)
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
        if c and not c:GetAttribute("HasBuso") then CF_("Buso") end
    end)
end

local function FindMob(nameFilter)
    if not nameFilter or nameFilter == "" then return nil end
    local enemies = workspace:FindFirstChild("Enemies"); if not enemies then return nil end
    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(mob.Name, nameFilter) then
            local mh = mob:FindFirstChildOfClass("Humanoid"); local mr = mob:FindFirstChild("HumanoidRootPart")
            if mh and mh.Health > 0 and mr then return mob end
        end
    end
    return nil
end

-- ESP BÁSICO
local espCache = {}
local function CreateESP(obj, label, color)
    if espCache[obj] then return end
    pcall(function()
        local hl = Instance.new("Highlight"); hl.FillColor = color; hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.5; hl.OutlineTransparency = 0.2; hl.Adornee = obj; hl.Parent = SafeParent
        local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true; bb.Size = UDim2.new(0,160,0,30)
        bb.Adornee = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart) or obj; bb.Parent = SafeParent
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.Text = label; lbl.TextColor3 = color; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextStrokeTransparency = 0.3; lbl.Parent = bb
        espCache[obj] = {hl, bb, lbl}
        obj.AncestryChanged:Connect(function()
            if not obj:IsDescendantOf(workspace) then
                for _, v in pairs(espCache[obj] or {}) do pcall(function() v:Destroy() end) end
                espCache[obj] = nil
            end
        end)
    end)
end
local function ClearESP()
    for obj, parts in pairs(espCache) do for _, v in pairs(parts) do pcall(function() v:Destroy() end) end espCache[obj] = nil end
end

-- ════════════════════════════════════════
--  INTERFACE
-- ════════════════════════════════════════
local AbaFarm = Win:MakeTab({Title="Farm Level"})
AbaFarm:AddIcon({Name="swords"})
AbaFarm:AddToggle({Name="Auto Farm Level", Default=false, Callback=function(v) ST.FarmLevel = v; if not v then StopTween(); SetFlyAnchor(false) end end})
AbaFarm:AddDropdown({Name="Arma", Options={"Melee","Sword","Blox Fruit","Gun"}, Callback=function(v) ST.WeaponType = v end})
AbaFarm:AddToggle({Name="Fast Attack", Default=true, Callback=function(v) ST.FastAttack = v end})
AbaFarm:AddToggle({Name="Bring Mob", Default=true, Callback=function(v) ST.BringMob = v end})
AbaFarm:AddToggle({Name="Auto Buso", Default=true, Callback=function(v) ST.AutoBuso = v end})
AbaFarm:AddSlider({Name="Farm Dist", Min=10, Max=50, Default=20, Increment=1, Callback=function(v) ST.FarmDist = v end})
AbaFarm:AddSlider({Name="Tween Speed", Min=100, Max=400, Default=260, Increment=10, Callback=function(v) ST.TweenSpeed = v end})

local AbaMob = Win:MakeTab({Title="Mobs & Boss"})
AbaMob:AddIcon({Name="skull"})
AbaMob:AddTextBox({Name="Mob Nome", Default="", Callback=function(v) ST.MobNome = v end})
AbaMob:AddToggle({Name="Auto Farm Mob", Default=false, Callback=function(v) ST.FarmMob = v; if not v then StopTween(); SetFlyAnchor(false) end end})
AbaMob:AddDropdown({Name="Boss", Options={"The Gorilla King","Bobby","Yeti","Vice Admiral","Warden","Chief Warden","Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God","Cyborg"}, Callback=function(v) ST.BossNome = v end})
AbaMob:AddToggle({Name="Auto Farm Boss", Default=false, Callback=function(v) ST.FarmBoss = v; if not v then StopTween(); SetFlyAnchor(false) end end})

local AbaRapido = Win:MakeTab({Title="Auto Rápido"})
AbaRapido:AddIcon({Name="zap"})
AbaRapido:AddToggle({Name="Auto Roubar Baú", Default=false, Callback=function(v) ST.RoubarBau = v; if not v then StopTween() end end})
AbaRapido:AddToggle({Name="Auto Stats", Default=false, Callback=function(v) ST.AutoStats = v end})
AbaRapido:AddSlider({Name="Stats Chunk", Min=1, Max=10, Default=3, Increment=1, Callback=function(v) ST.StatChunk = v end})
for _, stat in ipairs({"Melee","Defense","Sword","Gun","Demon Fruit"}) do
    AbaRapido:AddToggle({Name="Upar "..stat, Default=ST.StatsMap[stat] or false, Callback=function(v) ST.StatsMap[stat] = v end})
end

local AbaESP = Win:MakeTab({Title="ESP"})
AbaESP:AddIcon({Name="eye"})
AbaESP:AddToggle({Name="ESP Jogadores", Default=false, Callback=function(v) ST.ESP_Jogadores = v; if not v then ClearESP() end end})
AbaESP:AddToggle({Name="ESP Baús", Default=false, Callback=function(v) ST.ESP_Baus = v; if not v then ClearESP() end end})
AbaESP:AddToggle({Name="ESP Mobs", Default=false, Callback=function(v) ST.ESP_Mobs = v; if not v then ClearESP() end end})

local AbaSkill = Win:MakeTab({Title="Skills"})
AbaSkill:AddIcon({Name="sparkles"})
for _, k in ipairs({"Z","X","C","V"}) do
    AbaSkill:AddToggle({Name="Auto Skill "..k, Default=false, Callback=function(v) ST["AutoSkill"..k] = v end})
end

local AbaPlayer = Win:MakeTab({Title="Player"})
AbaPlayer:AddIcon({Name="user"})
AbaPlayer:AddSlider({Name="WalkSpeed", Min=16, Max=500, Default=16, Increment=1, Callback=function(v) ST.Velocidade = v; local h = GetHum(); if h then h.WalkSpeed = v end end})
AbaPlayer:AddSlider({Name="JumpPower", Min=50, Max=500, Default=50, Increment=1, Callback=function(v) ST.PuloForca = v; local h = GetHum(); if h then h.JumpPower = v end end})
AbaPlayer:AddToggle({Name="Noclip", Default=false, Callback=function(v) ST.Noclip = v end})
AbaPlayer:AddToggle({Name="Infinite Jump", Default=false, Callback=function(v) ST.PuloInfinito = v end})
AbaPlayer:AddToggle({Name="Anti-AFK", Default=true, Callback=function(v) ST.AntiAFK = v end})

-- ════════════════════════════════════════
--  LOOPS DE FUNDO
-- ════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.05)
        if ST.FarmLevel then
            pcall(function()
                local hrp = GetHRP(); local hum = GetHum()
                if not hrp or not hum or hum.Health <= 0 then SetFlyAnchor(false) return end
                local q = GetQuestData()
                EnsureBuso()
                if not HasActiveQuest() then
                    SetFlyAnchor(false)
                    if (hrp.Position - q.NPC.Position).Magnitude > 20 then SafeTween(q.NPC)
                    else
                        StopTween(); hrp.CFrame = q.NPC
                        if q.Entrance then CF_("requestEntrance", q.Entrance) task.wait(0.3) end
                        CF_("StartQuest", q.Quest, q.Level); task.wait(0.4)
                    end
                else
                    local mob = FindMob(q.Nome)
                    if mob then
                        local mhrp = mob.HumanoidRootPart
                        local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)
                        if (hrp.Position - mhrp.Position).Magnitude > 40 then SetFlyAnchor(false); SafeTween(flyPos)
                        else
                            StopTween(); SetFlyAnchor(true)
                            hrp.CFrame = flyPos; hrp.Velocity = Vector3.zero
                            BringMobs(q.Nome, mhrp.CFrame)
                            EquipWeapon()
                            if ST.FastAttack then FastAttack(mob) end
                            TriggerSkills()
                        end
                    else SetFlyAnchor(false); SafeTween(q.MobCF) end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if ST.FarmMob and not ST.FarmLevel then
            pcall(function()
                local hum = GetHum(); if not hum or hum.Health <= 0 then SetFlyAnchor(false) return end
                EnsureBuso()
                local mob = FindMob(ST.MobNome)
                if mob then
                    local mhrp = mob.HumanoidRootPart
                    local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist, 0), mhrp.Position)
                    if (GetHRP().Position - mhrp.Position).Magnitude > 40 then SetFlyAnchor(false); SafeTween(flyPos)
                    else
                        StopTween(); SetFlyAnchor(true)
                        GetHRP().CFrame = flyPos; GetHRP().Velocity = Vector3.zero
                        EquipWeapon()
                        if ST.FastAttack then FastAttack(mob) end
                        TriggerSkills()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if ST.FarmBoss and not ST.FarmLevel then
            pcall(function()
                local hrp = GetHRP(); local hum = GetHum()
                if not hrp or not hum or hum.Health <= 0 then SetFlyAnchor(false) return end
                EnsureBuso()
                local mob = FindMob(ST.BossNome)
                if mob then
                    local mhrp = mob.HumanoidRootPart
                    local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, ST.FarmDist + 5, 0), mhrp.Position)
                    if (hrp.Position - mhrp.Position).Magnitude > 40 then SetFlyAnchor(false); SafeTween(flyPos)
                    else
                        StopTween(); SetFlyAnchor(true)
                        hrp.CFrame = flyPos; hrp.Velocity = Vector3.zero
                        EquipWeapon(); FastAttack(mob); TriggerSkills()
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.4)
        if ST.RoubarBau and not ST.FarmLevel then
            pcall(function()
                local hrp = GetHRP(); if not hrp then return end
                local nearest, nearDist = nil, math.huge
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
                        local d = (hrp.Position - obj.Position).Magnitude
                        if d < nearDist then nearest = obj; nearDist = d end
                    end
                end
                if nearest then
                    SafeTween(nearest.CFrame * CFrame.new(0, 2, 0), ST.TweenSpeed)
                    if nearDist <= 12 then
                        pcall(function() firetouchinterest(hrp, nearest, 0); firetouchinterest(hrp, nearest, 1) end)
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
                local d = LP:FindFirstChild("Data"); if not d then return end
                local pts = d:FindFirstChild("Points") and d.Points.Value or 0
                if pts <= 0 then return end
                local chunk = math.min(pts, ST.StatChunk)
                for stat, en in pairs(ST.StatsMap) do
                    if en then CF_("AddPoint", stat, chunk); task.wait(0.08) end
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
            if ST.ESP_Jogadores then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hr = p.Character:FindFirstChild("HumanoidRootPart")
                        local hm = p.Character:FindFirstChildOfClass("Humanoid")
                        if hr and hm and hm.Health > 0 then CreateESP(p.Character, p.Name.." ["..math.floor(dist(hr.Position)).."m]", Color3.fromRGB(0,230,255)) end
                    end
                end
            end
            if ST.ESP_Baus then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
                        CreateESP(obj, "Bau ["..math.floor(dist(obj.Position)).."m]", Color3.fromRGB(255,215,0))
                    end
                end
            end
            if ST.ESP_Mobs then
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mh = mob:FindFirstChildOfClass("Humanoid")
                        if mh and mh.Health > 0 then CreateESP(mob, mob.Name.." [HP:"..math.floor(mh.Health).."]", Color3.fromRGB(255,120,50)) end
                    end
                end
            end
            if not ST.ESP_Jogadores and not ST.ESP_Baus and not ST.ESP_Mobs then ClearESP() end
        end)
    end
end)

RunService.Stepped:Connect(function()
    pcall(function()
        local c = GetChar(); if not c then return end
        if ST.Noclip or ST.FarmLevel or ST.FarmMob or ST.FarmBoss or ST.RoubarBau then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
        local hum = GetHum()
        if hum then
            if hum.WalkSpeed ~= ST.Velocidade then hum.WalkSpeed = ST.Velocidade end
            if hum.JumpPower ~= ST.PuloForca then hum.JumpPower = ST.PuloForca end
        end
    end)
end)

UserInputService.JumpRequest:Connect(function()
    if ST.PuloInfinito then
        local hum = GetHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LP.Idled:Connect(function()
    if ST.AntiAFK then
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            if Win and Win.SetSubTitle then Win:SetSubTitle("Sea " .. CurrentSea .. " | Lv." .. GetLevel()) end
        end)
    end
end)

print("══════════════════════════════════════")
print("BF Script Básico | Sea " .. CurrentSea .. " | Lv." .. GetLevel())
print("Tabela de quests completa (1-2840) carregada!")
print("══════════════════════════════════════")
