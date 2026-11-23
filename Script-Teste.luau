repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
repeat task.wait() until LP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
local PGui = LP:WaitForChild("PlayerGui")
local SafeParent = (gethui and gethui()) or CoreGui

-- ════════════════════════════════════════
--  CARREGAMENTO DA UI (GG-UI)
-- ════════════════════════════════════════
local UI_URL = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
local GGUI_LIB = loadstring(game:HttpGet(UI_URL))()

if not GGUI_LIB or type(GGUI_LIB.MakeWindow) ~= "function" then
    warn("[BF Script] Falha ao carregar GGUI.")
    return
end

local CurrentSea = 1
if game.PlaceId == 4442272183 then CurrentSea = 2
elseif game.PlaceId == 7449423635 then CurrentSea = 3 end

local Win = GGUI_LIB:MakeWindow({
    Title = "Auto Farm (Hits Contando)",
    SubTitle = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or 1),
    ScriptFolder = "AutoFarmHits"
})

-- ════════════════════════════════════════
--  REMOTES E ESTADO
-- ════════════════════════════════════════
local R = {}
pcall(function()
    local rf = ReplicatedStorage:FindFirstChild("Remotes")
    if rf then R.CommF_ = rf:FindFirstChild("CommF_") end
end)

-- CombatFramework (usado para o ataque natural)
local CombatFW
pcall(function()
    local cf = LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("CombatFramework")
    if cf then CombatFW = require(cf) end
end)

local ST = {
    Ativo = false,
    Arma = "Melee",
    BringMob = true,
    Distancia = 15,
    VelocidadeVoo = 260,
    AutoBuso = true,
    DelayAtaque = 0.35, -- Delay entre ataques (mais alto = mais estável)
}

-- ════════════════════════════════════════
--  TABELA DE QUESTS COMPLETA
-- ════════════════════════════════════════
local Quests = {
    {Min=1, Max=9, Quest="BanditQuest1", Nome="Bandit", Lvl=1, NPC=CFrame.new(1060.9,16.4,1547.7), MobCF=CFrame.new(1038.5,41.2,1576.5)},
    {Min=10, Max=14, Quest="JungleQuest", Nome="Monkey", Lvl=1, NPC=CFrame.new(-1601.6,36.8,153.3), MobCF=CFrame.new(-1448.1,50.8,63.6)},
    {Min=15, Max=29, Quest="JungleQuest", Nome="Gorilla", Lvl=2, NPC=CFrame.new(-1601.6,36.8,153.3), MobCF=CFrame.new(-1142.6,40.4,515.3)},
    {Min=30, Max=39, Quest="BuggyQuest1", Nome="Pirate", Lvl=1, NPC=CFrame.new(-1140.1,4.7,3827.4), MobCF=CFrame.new(-1201.0,40.6,3857.5)},
    {Min=40, Max=59, Quest="BuggyQuest1", Nome="Brute", Lvl=2, NPC=CFrame.new(-1140.1,4.7,3827.4), MobCF=CFrame.new(-1387.5,24.5,4100.9)},
    {Min=60, Max=74, Quest="DesertQuest", Nome="Desert Bandit", Lvl=1, NPC=CFrame.new(896.5,6.4,4390.1), MobCF=CFrame.new(984.9,16.1,4417.9)},
    {Min=75, Max=89, Quest="DesertQuest", Nome="Desert Officer", Lvl=2, NPC=CFrame.new(896.5,6.4,4390.1), MobCF=CFrame.new(1547.1,14.4,4381.8)},
    {Min=90, Max=99, Quest="SnowQuest", Nome="Snow Bandit", Lvl=1, NPC=CFrame.new(1386.8,87.2,1298.3), MobCF=CFrame.new(1356.3,105.7,1328.2)},
    {Min=100, Max=119, Quest="SnowQuest", Nome="Snowman", Lvl=2, NPC=CFrame.new(1386.8,87.2,1298.3), MobCF=CFrame.new(1218.7,138.0,1488.0)},
    {Min=120, Max=149, Quest="MarineQuest2", Nome="Chief Petty Officer", Lvl=1, NPC=CFrame.new(-5035.4,28.6,4324.1), MobCF=CFrame.new(-4931.1,65.7,4121.8)},
    {Min=150, Max=174, Quest="SkyQuest", Nome="Sky Bandit", Lvl=1, NPC=CFrame.new(-4842.1,717.6,2623.0), MobCF=CFrame.new(-4955.6,365.4,2908.1)},
    {Min=175, Max=189, Quest="SkyQuest", Nome="Dark Master", Lvl=2, NPC=CFrame.new(-4842.1,717.6,2623.0), MobCF=CFrame.new(-5148.1,439.0,2332.9)},
    {Min=190, Max=209, Quest="PrisonerQuest", Nome="Prisoner", Lvl=1, NPC=CFrame.new(5310.6,0.3,474.9), MobCF=CFrame.new(4937.3,0.3,649.5)},
    {Min=210, Max=249, Quest="PrisonerQuest", Nome="Dangerous Prisoner", Lvl=2, NPC=CFrame.new(5310.6,0.3,474.9), MobCF=CFrame.new(5099.6,0.3,1055.7)},
    {Min=250, Max=274, Quest="ColosseumQuest", Nome="Toga Warrior", Lvl=1, NPC=CFrame.new(-1577.7,7.4,2984.4), MobCF=CFrame.new(-1872.5,49.0,2913.8)},
    {Min=275, Max=299, Quest="ColosseumQuest", Nome="Gladiator", Lvl=2, NPC=CFrame.new(-1577.7,7.4,2984.4), MobCF=CFrame.new(-1521.3,81.2,3066.3)},
    {Min=300, Max=324, Quest="MagmaQuest", Nome="Military Soldier", Lvl=1, NPC=CFrame.new(-5316.1,12.2,8517.0), MobCF=CFrame.new(-5369.0,61.2,8556.4)},
    {Min=325, Max=374, Quest="MagmaQuest", Nome="Military Spy", Lvl=2, NPC=CFrame.new(-5316.1,12.2,8517.0), MobCF=CFrame.new(-5787.0,75.8,8651.6)},
    {Min=375, Max=399, Quest="FishmanQuest", Nome="Fishman Warrior", Lvl=1, NPC=CFrame.new(61122.6,18.4,1569.3), MobCF=CFrame.new(60844.1,98.4,1298.3), Entrance=Vector3.new(61163.8,11.6,1819.7)},
    {Min=400, Max=449, Quest="FishmanQuest", Nome="Fishman Commando", Lvl=2, NPC=CFrame.new(61122.6,18.4,1569.3), MobCF=CFrame.new(61738.3,64.2,1433.8), Entrance=Vector3.new(61163.8,11.6,1819.7)},
    {Min=450, Max=474, Quest="SkyExp1Quest", Nome="God's Guard", Lvl=1, NPC=CFrame.new(-4721.8,845.3,1953.8), MobCF=CFrame.new(-4628.0,866.9,1931.2), Entrance=Vector3.new(-4607.8,872.5,-1667.5)},
    {Min=475, Max=524, Quest="SkyExp1Quest", Nome="Shanda", Lvl=2, NPC=CFrame.new(-4721.8,845.3,1953.8), MobCF=CFrame.new(-7680,5560,-500), Entrance=Vector3.new(-4607.8,872.5,-1667.5)},
    {Min=525, Max=624, Quest="SkyExp2Quest", Nome="Royal Squad", Lvl=1, NPC=CFrame.new(-7906,5634,-1411), MobCF=CFrame.new(-7600,5600,-1450)},
    {Min=625, Max=649, Quest="FountainQuest", Nome="Galley Pirate", Lvl=1, NPC=CFrame.new(5259,37,4050), MobCF=CFrame.new(5590,45,3990)},
    {Min=650, Max=699, Quest="FountainQuest", Nome="Galley Captain", Lvl=2, NPC=CFrame.new(5259,37,4050), MobCF=CFrame.new(5650,45,4950)},
    {Min=700, Max=724, Quest="Area1Quest", Nome="Raider", Lvl=1, NPC=CFrame.new(-429,72,1836), MobCF=CFrame.new(-730,40,2380)},
    {Min=725, Max=774, Quest="Area1Quest", Nome="Mercenary", Lvl=2, NPC=CFrame.new(-429,72,1836), MobCF=CFrame.new(-960,75,1750)},
    {Min=775, Max=799, Quest="Area2Quest", Nome="Swan Pirate", Lvl=1, NPC=CFrame.new(638,72,918), MobCF=CFrame.new(900,120,1200)},
    {Min=800, Max=874, Quest="Area2Quest", Nome="Factory Staff", Lvl=2, NPC=CFrame.new(638,72,918), MobCF=CFrame.new(295,73,-55)},
    {Min=875, Max=899, Quest="MarineQuest3", Nome="Marine Lieutenant", Lvl=1, NPC=CFrame.new(-2440,72,-3217), MobCF=CFrame.new(-2700,75,-3000)},
    {Min=900, Max=949, Quest="MarineQuest3", Nome="Marine Captain", Lvl=2, NPC=CFrame.new(-2440,72,-3217), MobCF=CFrame.new(-1900,75,-3300)},
    {Min=950, Max=999, Quest="ZombieQuest", Nome="Zombie", Lvl=1, NPC=CFrame.new(-5497,48,-795), MobCF=CFrame.new(-5650,120,-750)},
    {Min=1000, Max=1099, Quest="SnowMountainQuest", Nome="Snow Trooper", Lvl=1, NPC=CFrame.new(609,401,-5372), MobCF=CFrame.new(480,420,-5600)},
    {Min=1100, Max=1249, Quest="ShipQuest1", Nome="Ship Deckhand", Lvl=1, NPC=CFrame.new(1008,125,32911), MobCF=CFrame.new(1180,140,32990)},
    {Min=1250, Max=1499, Quest="FrostQuest", Nome="Sea Soldier", Lvl=1, NPC=CFrame.new(-3054,237,-10145), MobCF=CFrame.new(-3300,240,-10400)},
    {Min=1500, Max=1574, Quest="PiratePortQuest", Nome="Pirate Millionaire", Lvl=1, NPC=CFrame.new(-289,44,5580), MobCF=CFrame.new(-200,45,5900)},
    {Min=1575, Max=1699, Quest="PiratePortQuest", Nome="Pistol Billionaire", Lvl=2, NPC=CFrame.new(-289,44,5580), MobCF=CFrame.new(-400,75,5950)},
    {Min=1700, Max=1824, Quest="AmazonQuest", Nome="Female Islander", Lvl=1, NPC=CFrame.new(5832,51,-1100), MobCF=CFrame.new(5400,80,-1000)},
    {Min=1825, Max=1974, Quest="MarineTreeIsland", Nome="Marine Commodore", Lvl=1, NPC=CFrame.new(2180,28,-6740), MobCF=CFrame.new(2450,75,-6700)},
    {Min=1975, Max=2074, Quest="HauntedQuest1", Nome="Reborn Skeleton", Lvl=1, NPC=CFrame.new(-9515,142,5536), MobCF=CFrame.new(-8750,140,5900)},
    {Min=2075, Max=2199, Quest="HauntedQuest2", Nome="Living Zombie", Lvl=1, NPC=CFrame.new(-9515,142,5536), MobCF=CFrame.new(-10150,140,5950)},
    {Min=2200, Max=2299, Quest="CandyQuest1", Nome="Candy Rebel", Lvl=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1000,20,-14200)},
    {Min=2300, Max=2449, Quest="CandyQuest2", Nome="Sweet Thief", Lvl=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1200,20,-14700)},
    {Min=2450, Max=2599, Quest="TikiQuest1", Nome="Isle Outlaw", Lvl=1, NPC=CFrame.new(-16547,55,-172), MobCF=CFrame.new(-16800,30,-150)},
    {Min=2600, Max=2840, Quest="DragonDojoQuest", Nome="Dojo Fighter", Lvl=1, NPC=CFrame.new(-16547,55,-172), MobCF=CFrame.new(-16300,60,-350)},
}

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════
local function GetHRP() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function GetHum() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end
local function GetLevel() return LP.Data and LP.Data.Level.Value or 1 end
local function GetQuest()
    local lv = GetLevel()
    for _, q in ipairs(Quests) do if lv >= q.Min and lv <= q.Max then return q end end
    return Quests[#Quests]
end

local function SetFlyAnchor(enabled)
    local hrp = GetHRP()
    if not hrp then return end
    local bv = hrp:FindFirstChild("FarmFlyAnchor")
    if enabled then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "FarmFlyAnchor"
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

local curTween
local function Teleportar(targetCF)
    local hrp = GetHRP()
    if not hrp then return end
    if curTween then pcall(function() curTween:Cancel() end) curTween = nil end
    
    local dist = (hrp.Position - targetCF.Position).Magnitude
    if dist <= 15 then hrp.CFrame = targetCF return end
    
    if dist > 200 then
        hrp.CFrame = targetCF
        return
    end
    
    local ti = TweenInfo.new(dist / ST.VelocidadeVoo, Enum.EasingStyle.Linear)
    curTween = TweenService:Create(hrp, ti, {CFrame = targetCF})
    curTween:Play()
end

local function PararTeleporte()
    if curTween then pcall(function() curTween:Cancel() end) curTween = nil end
end

local function EquiparArma()
    local char = LP.Character
    local hum = GetHum()
    if not char or not hum then return end
    if char:FindFirstChildOfClass("Tool") then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == ST.Arma then
            hum:EquipTool(t)
            return
        end
    end
end

-- ════════════════════════════════════════
--  SISTEMA DE ATAQUE SIMPLES (HITS CONTANDO)
-- ════════════════════════════════════════
local ultimoAtaque = 0

local function Atacar()
    -- Controla o tempo entre ataques
    if tick() - ultimoAtaque < ST.DelayAtaque then
        return
    end
    ultimoAtaque = tick()
    
    local char = LP.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    -- 1. Ativa a ferramenta (isso é o que o jogo conta como hit)
    pcall(function()
        tool:Activate()
    end)
    
    -- 2. Tenta usar o CombatFramework se disponível (registra o hit naturalmente)
    pcall(function()
        if CombatFW and CombatFW.activeController then
            local ac = CombatFW.activeController
            -- Não altera hitbox nem timeToNextAttack, apenas deixa o jogo processar
            ac:attack()
        end
    end)
end

-- ════════════════════════════════════════
--  PROCURAR MOB
-- ════════════════════════════════════════
local function ProcurarMob(nome)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(mob.Name, nome) then
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hrp then
                return mob
            end
        end
    end
    return nil
end

local function PuxarMobs(nome, cfCentro)
    if not ST.BringMob then return end
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end
    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(mob.Name, nome) then
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            local mhum = mob:FindFirstChildOfClass("Humanoid")
            if mhrp and mhum and mhum.Health > 0 then
                mhrp.CFrame = cfCentro
                mhrp.Size = Vector3.new(15, 15, 15) -- Hitbox moderado
                mhum.WalkSpeed = 0
            end
        end
    end
end

-- ════════════════════════════════════════
--  UI
-- ════════════════════════════════════════
local Aba = Win:MakeTab({Title = "Auto Farm"})
Aba:AddIcon({Name = "swords"})

Aba:AddToggle({Name = "Ativar Auto Farm", Default = false, Callback = function(v)
    ST.Ativo = v
    if not v then PararTeleporte(); SetFlyAnchor(false) end
end})
Aba:AddDropdown({Name = "Arma", Options = {"Melee", "Sword", "Blox Fruit", "Gun"}, Callback = function(v) ST.Arma = v end})
Aba:AddToggle({Name = "Puxar Mobs", Default = true, Callback = function(v) ST.BringMob = v end})
Aba:AddSlider({Name = "Distância do Mob", Min = 10, Max = 30, Default = 15, Increment = 1, Callback = function(v) ST.Distancia = v end})
Aba:AddSlider({Name = "Delay entre Ataques", Min = 0.1, Max = 1.0, Default = 0.35, Increment = 0.05, Callback = function(v) ST.DelayAtaque = v end})
Aba:AddSlider({Name = "Velocidade Voo", Min = 100, Max = 400, Default = 260, Increment = 10, Callback = function(v) ST.VelocidadeVoo = v end})

-- ════════════════════════════════════════
--  LOOP PRINCIPAL
-- ════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.05)
        if ST.Ativo then
            pcall(function()
                local hrp = GetHRP()
                local hum = GetHum()
                if not hrp or not hum or hum.Health <= 0 then
                    PararTeleporte()
                    SetFlyAnchor(false)
                    return
                end
                
                local q = GetQuest()
                if not q then return end
                
                -- 1. Tenta encontrar o mob
                local mob = ProcurarMob(q.Nome)
                
                if mob then
                    -- TEM MOB: Vai para cima e ataca
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if mhrp then
                        local posAlvo = CFrame.new(mhrp.Position + Vector3.new(0, ST.Distancia, 0))
                        local dist = (hrp.Position - mhrp.Position).Magnitude
                        
                        if dist > 25 then
                            SetFlyAnchor(false)
                            Teleportar(posAlvo)
                        else
                            PararTeleporte()
                            SetFlyAnchor(true)
                            hrp.CFrame = posAlvo
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            
                            PuxarMobs(q.Nome, mhrp.CFrame)
                            EquiparArma()
                            Atacar()
                        end
                    end
                else
                    -- SEM MOB: Vai para a área de spawn ou NPC
                    SetFlyAnchor(false)
                    
                    local distNPC = (hrp.Position - q.NPC.Position).Magnitude
                    if distNPC < 30 then
                        if R.CommF_ then
                            R.CommF_:InvokeServer("StartQuest", q.Quest, q.Lvl)
                            task.wait(0.5)
                        end
                    else
                        Teleportar(q.MobCF)
                    end
                end
            end)
        end
    end
end)

print("Auto Farm (Hits Contando) carregado!")
