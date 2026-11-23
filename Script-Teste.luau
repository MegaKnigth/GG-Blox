-- ════════════════════════════════════════
--  AUTO FARM ESTÁVEL v4 — COMPLETO
--  Luau | LocalScript | Blox Fruits (Sea 1-3)
--  Combat engine: venice-test v4 (provado)
-- ════════════════════════════════════════

repeat task.wait() until game:IsLoaded()

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local UIS               = game:GetService("UserInputService")

local LP = Players.LocalPlayer
repeat task.wait() until LP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
local SafeParent = (gethui and gethui()) or CoreGui

-- ════════════════════════════════════════
--  UI LIB
-- ════════════════════════════════════════
local UI_URL   = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
local GGUI_LIB = loadstring(game:HttpGet(UI_URL))()
if not GGUI_LIB or type(GGUI_LIB.MakeWindow) ~= "function" then
    warn("[BF Script] Falha ao carregar GGUI.")
    return
end

local CurrentSea = 1
if game.PlaceId == 4442272183 then CurrentSea = 2
elseif game.PlaceId == 7449423635 then CurrentSea = 3 end

local Win = GGUI_LIB:MakeWindow({
    Title        = "Auto Farm Estável v4",
    SubTitle     = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or 1),
    ScriptFolder = "AutoFarmEstavelV4"
})

-- ════════════════════════════════════════
--  ESTADO
-- ════════════════════════════════════════
local ST = {
    Ativo         = false,
    Arma          = "Melee",
    FastAttack    = true,
    BringMob      = true,
    Distancia     = 25,
    VelocidadeVoo = 300,
}

-- constantes
local HIT_RANGE   = 60
local MOB_RANGE   = 300   -- raio do bring
local ATTACK_CD   = 0.05

local LIMBS = {
    "RightLowerArm","RightUpperArm","LeftLowerArm",
    "LeftUpperArm","RightHand","LeftHand"
}
local VALID_TOOLS = { Melee = true, Sword = true, ["Blox Fruit"] = true, Gun = true }

-- ════════════════════════════════════════
--  QUESTS
-- ════════════════════════════════════════
local Quests = {
    {Min=1,    Max=9,    Quest="BanditQuest1",     Nome="Bandit",              Lvl=1, NPC=CFrame.new(1060.9,16.4,1547.7),   MobCF=CFrame.new(1038.5,41.2,1576.5)},
    {Min=10,   Max=14,   Quest="JungleQuest",       Nome="Monkey",              Lvl=1, NPC=CFrame.new(-1601.6,36.8,153.3),   MobCF=CFrame.new(-1448.1,50.8,63.6)},
    {Min=15,   Max=29,   Quest="JungleQuest",       Nome="Gorilla",             Lvl=2, NPC=CFrame.new(-1601.6,36.8,153.3),   MobCF=CFrame.new(-1142.6,40.4,515.3)},
    {Min=30,   Max=39,   Quest="BuggyQuest1",       Nome="Pirate",              Lvl=1, NPC=CFrame.new(-1140.1,4.7,3827.4),   MobCF=CFrame.new(-1201.0,40.6,3857.5)},
    {Min=40,   Max=59,   Quest="BuggyQuest1",       Nome="Brute",               Lvl=2, NPC=CFrame.new(-1140.1,4.7,3827.4),   MobCF=CFrame.new(-1387.5,24.5,4100.9)},
    {Min=60,   Max=74,   Quest="DesertQuest",       Nome="Desert Bandit",       Lvl=1, NPC=CFrame.new(896.5,6.4,4390.1),    MobCF=CFrame.new(984.9,16.1,4417.9)},
    {Min=75,   Max=89,   Quest="DesertQuest",       Nome="Desert Officer",      Lvl=2, NPC=CFrame.new(896.5,6.4,4390.1),    MobCF=CFrame.new(1547.1,14.4,4381.8)},
    {Min=90,   Max=99,   Quest="SnowQuest",         Nome="Snow Bandit",         Lvl=1, NPC=CFrame.new(1386.8,87.2,1298.3),  MobCF=CFrame.new(1356.3,105.7,1328.2)},
    {Min=100,  Max=119,  Quest="SnowQuest",         Nome="Snowman",             Lvl=2, NPC=CFrame.new(1386.8,87.2,1298.3),  MobCF=CFrame.new(1218.7,138.0,1488.0)},
    {Min=120,  Max=149,  Quest="MarineQuest2",      Nome="Chief Petty Officer", Lvl=1, NPC=CFrame.new(-5035.4,28.6,4324.1), MobCF=CFrame.new(-4931.1,65.7,4121.8)},
    {Min=150,  Max=174,  Quest="SkyQuest",          Nome="Sky Bandit",          Lvl=1, NPC=CFrame.new(-4842.1,717.6,2623.0),MobCF=CFrame.new(-4955.6,365.4,2908.1)},
    {Min=175,  Max=189,  Quest="SkyQuest",          Nome="Dark Master",         Lvl=2, NPC=CFrame.new(-4842.1,717.6,2623.0),MobCF=CFrame.new(-5148.1,439.0,2332.9)},
    {Min=190,  Max=209,  Quest="PrisonerQuest",     Nome="Prisoner",            Lvl=1, NPC=CFrame.new(5310.6,0.3,474.9),   MobCF=CFrame.new(4937.3,0.3,649.5)},
    {Min=210,  Max=249,  Quest="PrisonerQuest",     Nome="Dangerous Prisoner",  Lvl=2, NPC=CFrame.new(5310.6,0.3,474.9),   MobCF=CFrame.new(5099.6,0.3,1055.7)},
    {Min=250,  Max=274,  Quest="ColosseumQuest",    Nome="Toga Warrior",        Lvl=1, NPC=CFrame.new(-1577.7,7.4,2984.4), MobCF=CFrame.new(-1872.5,49.0,2913.8)},
    {Min=275,  Max=299,  Quest="ColosseumQuest",    Nome="Gladiator",           Lvl=2, NPC=CFrame.new(-1577.7,7.4,2984.4), MobCF=CFrame.new(-1521.3,81.2,3066.3)},
    {Min=300,  Max=324,  Quest="MagmaQuest",        Nome="Military Soldier",    Lvl=1, NPC=CFrame.new(-5316.1,12.2,8517.0),MobCF=CFrame.new(-5369.0,61.2,8556.4)},
    {Min=325,  Max=374,  Quest="MagmaQuest",        Nome="Military Spy",        Lvl=2, NPC=CFrame.new(-5316.1,12.2,8517.0),MobCF=CFrame.new(-5787.0,75.8,8651.6)},
    {Min=375,  Max=399,  Quest="FishmanQuest",      Nome="Fishman Warrior",     Lvl=1, NPC=CFrame.new(61122.6,18.4,1569.3),MobCF=CFrame.new(60844.1,98.4,1298.3)},
    {Min=400,  Max=449,  Quest="FishmanQuest",      Nome="Fishman Commando",    Lvl=2, NPC=CFrame.new(61122.6,18.4,1569.3),MobCF=CFrame.new(61738.3,64.2,1433.8)},
    {Min=450,  Max=474,  Quest="SkyExp1Quest",      Nome="God's Guard",         Lvl=1, NPC=CFrame.new(-4721.8,845.3,1953.8),MobCF=CFrame.new(-4628.0,866.9,1931.2)},
    {Min=475,  Max=524,  Quest="SkyExp1Quest",      Nome="Shanda",              Lvl=2, NPC=CFrame.new(-4721.8,845.3,1953.8),MobCF=CFrame.new(-7680,5560,-500)},
    {Min=525,  Max=624,  Quest="SkyExp2Quest",      Nome="Royal Squad",         Lvl=1, NPC=CFrame.new(-7906,5634,-1411),  MobCF=CFrame.new(-7600,5600,-1450)},
    {Min=625,  Max=649,  Quest="FountainQuest",     Nome="Galley Pirate",       Lvl=1, NPC=CFrame.new(5259,37,4050),      MobCF=CFrame.new(5590,45,3990)},
    {Min=650,  Max=699,  Quest="FountainQuest",     Nome="Galley Captain",      Lvl=2, NPC=CFrame.new(5259,37,4050),      MobCF=CFrame.new(5650,45,4950)},
    {Min=700,  Max=724,  Quest="Area1Quest",        Nome="Raider",              Lvl=1, NPC=CFrame.new(-429,72,1836),      MobCF=CFrame.new(-730,40,2380)},
    {Min=725,  Max=774,  Quest="Area1Quest",        Nome="Mercenary",           Lvl=2, NPC=CFrame.new(-429,72,1836),      MobCF=CFrame.new(-960,75,1750)},
    {Min=775,  Max=799,  Quest="Area2Quest",        Nome="Swan Pirate",         Lvl=1, NPC=CFrame.new(638,72,918),        MobCF=CFrame.new(900,120,1200)},
    {Min=800,  Max=874,  Quest="Area2Quest",        Nome="Factory Staff",       Lvl=2, NPC=CFrame.new(638,72,918),        MobCF=CFrame.new(295,73,-55)},
    {Min=875,  Max=899,  Quest="MarineQuest3",      Nome="Marine Lieutenant",   Lvl=1, NPC=CFrame.new(-2440,72,-3217),    MobCF=CFrame.new(-2700,75,-3000)},
    {Min=900,  Max=949,  Quest="MarineQuest3",      Nome="Marine Captain",      Lvl=2, NPC=CFrame.new(-2440,72,-3217),    MobCF=CFrame.new(-1900,75,-3300)},
    {Min=950,  Max=999,  Quest="ZombieQuest",       Nome="Zombie",              Lvl=1, NPC=CFrame.new(-5497,48,-795),     MobCF=CFrame.new(-5650,120,-750)},
    {Min=1000, Max=1099, Quest="SnowMountainQuest", Nome="Snow Trooper",        Lvl=1, NPC=CFrame.new(609,401,-5372),     MobCF=CFrame.new(480,420,-5600)},
    {Min=1100, Max=1249, Quest="ShipQuest1",        Nome="Ship Deckhand",       Lvl=1, NPC=CFrame.new(1008,125,32911),    MobCF=CFrame.new(1180,140,32990)},
    {Min=1250, Max=1499, Quest="FrostQuest",        Nome="Sea Soldier",         Lvl=1, NPC=CFrame.new(-3054,237,-10145),  MobCF=CFrame.new(-3300,240,-10400)},
    {Min=1500, Max=1574, Quest="PiratePortQuest",   Nome="Pirate Millionaire",  Lvl=1, NPC=CFrame.new(-289,44,5580),      MobCF=CFrame.new(-200,45,5900)},
    {Min=1575, Max=1699, Quest="PiratePortQuest",   Nome="Pistol Billionaire",  Lvl=2, NPC=CFrame.new(-289,44,5580),      MobCF=CFrame.new(-400,75,5950)},
    {Min=1700, Max=1824, Quest="AmazonQuest",       Nome="Female Islander",     Lvl=1, NPC=CFrame.new(5832,51,-1100),     MobCF=CFrame.new(5400,80,-1000)},
    {Min=1825, Max=1974, Quest="MarineTreeIsland",  Nome="Marine Commodore",    Lvl=1, NPC=CFrame.new(2180,28,-6740),     MobCF=CFrame.new(2450,75,-6700)},
    {Min=1975, Max=2074, Quest="HauntedQuest1",     Nome="Reborn Skeleton",     Lvl=1, NPC=CFrame.new(-9515,142,5536),    MobCF=CFrame.new(-8750,140,5900)},
    {Min=2075, Max=2199, Quest="HauntedQuest2",     Nome="Living Zombie",       Lvl=1, NPC=CFrame.new(-9515,142,5536),    MobCF=CFrame.new(-10150,140,5950)},
    {Min=2200, Max=2299, Quest="CandyQuest1",       Nome="Candy Rebel",         Lvl=1, NPC=CFrame.new(-1149,13,-14445),   MobCF=CFrame.new(-1000,20,-14200)},
    {Min=2300, Max=2449, Quest="CandyQuest2",       Nome="Sweet Thief",         Lvl=1, NPC=CFrame.new(-1149,13,-14445),   MobCF=CFrame.new(-1200,20,-14700)},
    {Min=2450, Max=2599, Quest="TikiQuest1",        Nome="Isle Outlaw",         Lvl=1, NPC=CFrame.new(-16547,55,-172),    MobCF=CFrame.new(-16800,30,-150)},
    {Min=2600, Max=2840, Quest="DragonDojoQuest",   Nome="Dojo Fighter",        Lvl=1, NPC=CFrame.new(-16547,55,-172),    MobCF=CFrame.new(-16300,60,-350)},
}

-- ════════════════════════════════════════
--  CHAR BIND
-- ════════════════════════════════════════
local char, hrp, hum

local function bind(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart", 15)
    hum  = c:WaitForChild("Humanoid", 15)
end
if LP.Character then pcall(bind, LP.Character) end
LP.CharacterAdded:Connect(function(c) pcall(bind, c) end)

-- ════════════════════════════════════════
--  REMOTES + COMBAT SETUP
-- ════════════════════════════════════════
local RegisterAttack, RegisterHit, CommF_, ac, HitFunction

task.spawn(function()
    local Modules = RS:FindFirstChild("Modules") or RS:WaitForChild("Modules", 15)
    local net     = Modules and (Modules:FindFirstChild("Net") or Modules:WaitForChild("Net", 10))
    if net then
        RegisterAttack = net:FindFirstChild("RE/RegisterAttack") or net:WaitForChild("RE/RegisterAttack", 10)
        RegisterHit    = net:FindFirstChild("RE/RegisterHit")    or net:WaitForChild("RE/RegisterHit", 10)
    end
    local rf = RS:FindFirstChild("Remotes")
    if rf then CommF_ = rf:FindFirstChild("CommF_") end

    pcall(function()
        local CF = require(LP.PlayerScripts:WaitForChild("CombatFramework", 10))
        ac = CF and CF.activeController
    end)
    pcall(function()
        local ls = LP.PlayerScripts:FindFirstChildOfClass("LocalScript")
        if ls and getsenv then HitFunction = getsenv(ls)._G.SendHitsToServer end
    end)
end)

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function GetHRP()   return hrp end
local function GetHum()   return hum end
local function GetLevel() return LP.Data and LP.Data.Level.Value or 1 end

local function GetQuest()
    local lv = GetLevel()
    for _, q in ipairs(Quests) do
        if lv >= q.Min and lv <= q.Max then return q end
    end
    return Quests[#Quests]
end

local function hitId()
    return tostring(LP.UserId):sub(2,4) .. tostring(coroutine.running()):sub(11,15)
end

local function stunned()
    if not char then return false end
    local s = char:FindFirstChild("Stun")
    local b = char:FindFirstChild("Busy")
    return (s and s.Value > 0) or (b and b.Value) or false
end

local function folders()
    local t = {}
    local e = workspace:FindFirstChild("Enemies")
    local c = workspace:FindFirstChild("Characters")
    if e then t[#t+1] = e end
    if c then t[#t+1] = c end
    return t
end

local function equipWeapon()
    if not char then return nil end
    local eq = char:FindFirstChildOfClass("Tool")
    if eq and VALID_TOOLS[eq.ToolTip] then return eq end
    local bp = LP:FindFirstChild("Backpack")
    if not bp or not hum then return nil end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and VALID_TOOLS[t.ToolTip] then
            pcall(function() hum:EquipTool(t) end)
            return t
        end
    end
end

-- ════════════════════════════════════════
--  FLY ANCHOR
-- ════════════════════════════════════════
local function SetFlyAnchor(enabled)
    if not hrp then return end
    local bv = hrp:FindFirstChild("FarmFlyAnchor")
    if enabled then
        if not bv then
            bv          = Instance.new("BodyVelocity")
            bv.Name     = "FarmFlyAnchor"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent   = hrp
        else
            bv.Velocity = Vector3.zero
        end
    elseif bv then
        bv:Destroy()
    end
end

-- ════════════════════════════════════════
--  TELEPORTE
-- ════════════════════════════════════════
local tweenObj

local function PararTeleporte()
    if tweenObj then
        pcall(function() tweenObj:Cancel() end)
        tweenObj = nil
    end
end

local function Teleportar(targetCF)
    if not hrp then return end
    PararTeleporte()
    local d = (hrp.Position - targetCF.Position).Magnitude
    if d < 50  then hrp.CFrame = targetCF return end
    if d > 500 then hrp.CFrame = targetCF return end
    tweenObj = TweenService:Create(hrp,
        TweenInfo.new(d / ST.VelocidadeVoo, Enum.EasingStyle.Linear),
        { CFrame = targetCF })
    tweenObj:Play()
end

-- ════════════════════════════════════════
--  BRING — venice v4, corrigido
--  Trava o mob no ponto fixo, sem alterar Size
-- ════════════════════════════════════════
local PosMon    = nil   -- posição travada do alvo principal
local lastTarget = nil

local function bring(questNome)
    if not ST.BringMob or not PosMon then return end
    for _, folder in ipairs(folders()) do
        for _, mob in ipairs(folder:GetChildren()) do
            if not string.find(mob.Name, questNome) then continue end
            local mh  = mob:FindFirstChild("HumanoidRootPart")
            local mhu = mob:FindFirstChildOfClass("Humanoid")
            if mh and mhu and mhu.Health > 0 and mob ~= char then
                if (mh.Position - PosMon).Magnitude <= MOB_RANGE then
                    pcall(function()
                        mh.CFrame     = CFrame.new(PosMon)
                        mh.CanCollide = true
                        mhu.WalkSpeed = 0
                        mhu.JumpPower = 0
                        local an = mhu:FindFirstChild("Animator")
                        if an then an:Destroy() end
                        LP.SimulationRadius = math.huge
                    end)
                end
            end
        end
    end
end

-- ════════════════════════════════════════
--  STRIKE — venice v4 (provado, não mexido)
-- ════════════════════════════════════════
local function strike()
    if not hrp or not hum or hum.Health <= 0 or stunned() then return end
    local tool = equipWeapon()
    if not tool then return end

    local targets = {}
    local pos = hrp.Position
    for _, folder in ipairs(folders()) do
        for _, m in ipairs(folder:GetChildren()) do
            local h = m:FindFirstChild("HumanoidRootPart")
            local u = m:FindFirstChildOfClass("Humanoid")
            if h and u and u.Health > 0 and m ~= char
               and (h.Position - pos).Magnitude <= HIT_RANGE then
                targets[#targets+1] = {
                    m,
                    m:FindFirstChild(LIMBS[math.random(#LIMBS)]) or h,
                    h
                }
            end
        end
    end
    if #targets == 0 then return end

    -- Blox Fruit M1
    if tool.ToolTip == "Blox Fruit" and tool:FindFirstChild("LeftClickRemote") then
        local dir = (targets[1][3].Position - hrp.Position).Unit
        pcall(function() tool.LeftClickRemote:FireServer(dir, math.random(1, 3)) end)
        return
    end

    local cd = tool:FindFirstChild("Cooldown") and tool.Cooldown.Value or 0

    -- RegisterAttack + RegisterHit (caminho principal)
    if RegisterAttack and RegisterHit then
        pcall(function() RegisterAttack:FireServer(cd) end)
        local head = targets[1][1]:FindFirstChild("Head") or targets[1][3]
        local list = {}
        for i, t in ipairs(targets) do list[i] = { t[1], t[2] } end
        if HitFunction then
            pcall(HitFunction, head, list)
        else
            pcall(function() RegisterHit:FireServer(head, list, nil, nil, hitId()) end)
        end
        return
    end

    -- CombatFramework fallback
    if ac then
        pcall(function()
            ac.timeToNextAttack = 0
            ac.hitboxMagnitude  = 150
            ac.increment        = 4
            ac.blocking         = false
            if type(ac.attack) == "function" then ac:attack() else ac:Attack() end
        end)
        return
    end

    -- último recurso
    pcall(function() tool:Activate() end)
end

-- ════════════════════════════════════════
--  LOOP — posição travada + bring
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(0.1) do
        if not (ST.Ativo and hrp) then continue end

        local q = GetQuest()
        if not q then continue end

        -- localiza alvo
        local targetMob = nil
        local bestDist  = math.huge
        for _, folder in ipairs(folders()) do
            for _, mob in ipairs(folder:GetChildren()) do
                if string.find(mob.Name, q.Nome) then
                    local mh  = mob:FindFirstChild("HumanoidRootPart")
                    local mhu = mob:FindFirstChildOfClass("Humanoid")
                    if mh and mhu and mhu.Health > 0 then
                        local d = (mh.Position - hrp.Position).Magnitude
                        if d < bestDist then
                            bestDist  = d
                            targetMob = mob
                        end
                    end
                end
            end
        end

        if not targetMob then
            lastTarget, PosMon = nil, nil
            -- sem mob: vai pro NPC ou área de spawn
            SetFlyAnchor(false)
            if CommF_ then
                local distNPC = (hrp.Position - q.NPC.Position).Magnitude
                if distNPC < 30 then
                    pcall(function() CommF_:InvokeServer("StartQuest", q.Quest, q.Lvl) end)
                    task.wait(0.5)
                else
                    Teleportar(q.MobCF)
                end
            else
                Teleportar(q.MobCF)
            end
            continue
        end

        -- trava posição uma vez por alvo
        if targetMob ~= lastTarget then
            lastTarget = targetMob
            local mh = targetMob:FindFirstChild("HumanoidRootPart")
            if mh then
                -- usa atributo pra manter o ponto mesmo se o mob se mover
                if not targetMob:GetAttribute("PosTravada") then
                    pcall(function()
                        targetMob:SetAttribute("PosTravada", mh.CFrame)
                    end)
                end
                local locked = targetMob:GetAttribute("PosTravada")
                PosMon = (locked and locked.Position) or mh.Position
            end
        end

        bring(q.Nome)

        -- move o player para cima do ponto travado
        if PosMon then
            local want = CFrame.new(PosMon + Vector3.new(0, ST.Distancia, 0))
                * CFrame.Angles(0, math.rad(180), 0)
            local dist = (hrp.Position - want.Position).Magnitude
            if dist > 3 then
                SetFlyAnchor(false)
                Teleportar(want)
            else
                PararTeleporte()
                SetFlyAnchor(true)
                hrp.CFrame = want
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end)

-- ════════════════════════════════════════
--  LOOP DE ATAQUE — separado, 0.05s
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(ATTACK_CD) do
        if ST.Ativo and ST.FastAttack then
            pcall(strike)
        end
    end
end)

-- ════════════════════════════════════════
--  UI
-- ════════════════════════════════════════
local Aba = Win:MakeTab({Title = "Auto Farm"})
Aba:AddIcon({Name = "swords"})

Aba:AddToggle({Name = "Ativar Auto Farm", Default = false, Callback = function(v)
    ST.Ativo = v
    if not v then
        PararTeleporte()
        SetFlyAnchor(false)
        PosMon, lastTarget = nil, nil
    end
end})

Aba:AddDropdown({
    Name = "Arma",
    Options = {"Melee","Sword","Blox Fruit","Gun"},
    Callback = function(v) ST.Arma = v end
})

Aba:AddToggle({Name = "Fast Attack", Default = true, Callback = function(v)
    ST.FastAttack = v
end})

Aba:AddToggle({Name = "Puxar Mobs", Default = true, Callback = function(v)
    ST.BringMob = v
end})

Aba:AddSlider({
    Name = "Distância do Mob", Min = 5, Max = 60, Default = 25, Increment = 1,
    Callback = function(v) ST.Distancia = v end
})

Aba:AddSlider({
    Name = "Velocidade Voo", Min = 100, Max = 600, Default = 300, Increment = 10,
    Callback = function(v) ST.VelocidadeVoo = v end
})

print("Auto Farm Estável v4 carregado!")
