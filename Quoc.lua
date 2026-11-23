

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
repeat task.wait() until LP and LP:FindFirstChild("PlayerGui")
local PGui = LP:WaitForChild("PlayerGui")

-- ════════════════════════════════════════
--  CARREGAMENTO DA UI (GG-UI)
-- ════════════════════════════════════════
local UI_URL = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
local uiSource = game:HttpGet(UI_URL)
local GGUI_LIB = loadstring(uiSource)()

if not GGUI_LIB or type(GGUI_LIB.MakeWindow) ~= "function" then
    warn("[Aviso] Falha ao carregar a GG-UI. Verifique sua conexão.")
    return
end

local SafeParent = (gethui and gethui()) or (syn and syn.protect_gui and (function()
    local f = Instance.new("Folder")
    syn.protect_gui(f)
    f.Parent = CoreGui
    return f
end)()) or PGui

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
local Remotes = {}
pcall(function()
    local rf = ReplicatedStorage:WaitForChild("Remotes", 5)
    if rf then
        Remotes.CommF_ = rf:FindFirstChild("CommF_")
        Remotes.CommE = rf:FindFirstChild("CommE")
        Remotes.Chest = rf:FindFirstChild("Chest")
        Remotes.Redeem = rf:FindFirstChild("Redeem")
        Remotes.Leviathan = rf:FindFirstChild("Leviathan")
        Remotes.Temple = rf:FindFirstChild("Temple")
        Remotes.TempleObby = rf:FindFirstChild("TempleObby")
    end
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        Remotes.ActivateRaceV4 = events:FindFirstChild("ActivateRaceV4")
        Remotes.UsedRaceSkill = events:FindFirstChild("UsedRaceSkill")
    end
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if modules then
        local net = modules:FindFirstChild("Net")
        if net then
            Remotes.RegisterAttack = net:FindFirstChild("RE/RegisterAttack")
            Remotes.RegisterHit = net:FindFirstChild("RE/RegisterHit")
            Remotes.CollectBlueEmber = net:FindFirstChild("RE/CollectBlueEmber")
            Remotes.KitsuneStatuePray = net:FindFirstChild("RF/KitsuneStatuePray")
            Remotes.TouchKitsuneStatue = net:FindFirstChild("RE/TouchKitsuneStatue")
        end
    end
end)

local function ExecutarComando(method, ...)
    if Remotes.CommF_ then
        return Remotes.CommF_:InvokeServer(method, ...)
    end
end

-- ════════════════════════════════════════
--  ESTADO GLOBAL (TRADUZIDO)
-- ════════════════════════════════════════
local Config = {
    -- Farm Nível
    FarmNivel = false,
    TipoArma = "Melee",
    AtaqueRapido = true,
    PuxarMobs = true,
    DistanciaFarm = 20,
    AutoBuso = true,
    AutoKen = false,
    
    -- Mob & Boss
    MobSelecionado = "Bandit",
    FarmMob = false,
    BossSelecionado = "The Gorilla King",
    FarmBoss = false,
    
    -- Rápidos
    AutoRapido = false,
    AutoBau = false,
    ContadorBaus = 0,
    AutoStatus = false,
    ChunkStatus = 3,
    StatusParaUpar = {
        ["Melee"] = true,
        ["Defense"] = true,
        ["Sword"] = false,
        ["Gun"] = false,
        ["Demon Fruit"] = false
    },
    
    -- ESP
    ESP_Jogadores = false,
    ESP_Baus = false,
    ESP_Frutas = false,
    ESP_Mobs = false,
    
    -- Movimento
    VelocidadeVoo = 260,
    Noclip = false,
    PuloInfinito = false,
    VelocidadeCaminhada = 16,
    ForcaPulo = 50,
    AntiAFK = true,
    FPSBoost = false,
    
    -- Frutas & Skills
    AutoSniperFruta = false,
    AutoGuardarFruta = false,
    AutoSkillZ = false,
    AutoSkillX = false,
    AutoSkillC = false,
    AutoSkillV = false,
    
    -- Kitsune
    AutoColetarEmbers = false,
    AutoRezarEstatua = false,
    
    -- Raça V4
    AutoDespertarV4 = false,
    AutoUsarSkillRaca = false,
    AutoEngrenagemMirage = false,
    
    -- Eventos Mar
    AutoLeviathan = false,
    AutoSeaBeast = false,
    AutoShipRaid = false,
    
    -- Webhook
    AtivarWebhook = false,
    URLWebhook = "",
    ArquivoWebhook = "Webhook_BF.txt"
}

-- Carrega Webhook salvo
if isfile and readfile then
    pcall(function()
        if isfile(Config.ArquivoWebhook) then
            local url = readfile(Config.ArquivoWebhook)
            if url and #url > 15 then
                Config.URLWebhook = url:gsub("%s+", "")
                Config.AtivarWebhook = true
            end
        end
    end)
end

-- ════════════════════════════════════════
--  DADOS DE QUESTS (TRADUZIDO)
-- ════════════════════════════════════════
local DadosQuests = {
    -- Sea 1
    {Min=1, Max=9, Quest="BanditQuest1", Nome="Bandit", Level=1, NPC=CFrame.new(1059,15,1550), MobCF=CFrame.new(1145,17,1634)},
    {Min=10, Max=14, Quest="JungleQuest", Nome="Monkey", Level=1, NPC=CFrame.new(-1598,35,153), MobCF=CFrame.new(-1610,22,142)},
    {Min=15, Max=29, Quest="JungleQuest", Nome="Gorilla", Level=2, NPC=CFrame.new(-1598,35,153), MobCF=CFrame.new(-1240,6,-490)},
    {Min=30, Max=39, Quest="BuggyQuest", Nome="Pirate", Level=1, NPC=CFrame.new(-1141,4,3831), MobCF=CFrame.new(-1215,4,3880)},
    {Min=40, Max=59, Quest="BuggyQuest", Nome="Brute", Level=2, NPC=CFrame.new(-1141,4,3831), MobCF=CFrame.new(-1370,15,4135)},
    {Min=60, Max=74, Quest="DesertQuest", Nome="Desert Bandit", Level=1, NPC=CFrame.new(894,5,4392), MobCF=CFrame.new(995,6,4450)},
    {Min=75, Max=89, Quest="DesertQuest", Nome="Desert Officer", Level=2, NPC=CFrame.new(894,5,4392), MobCF=CFrame.new(1570,10,4370)},
    {Min=90, Max=99, Quest="SnowQuest", Nome="Snow Bandit", Level=1, NPC=CFrame.new(1389,85,-1298), MobCF=CFrame.new(1288,106,-1450)},
    {Min=100, Max=119, Quest="SnowQuest", Nome="Snowman", Level=2, NPC=CFrame.new(1389,85,-1298), MobCF=CFrame.new(1285,150,-1500)},
    {Min=120, Max=149, Quest="MarineQuest2", Nome="Chief Petty Officer", Level=1, NPC=CFrame.new(-5039,27,4324), MobCF=CFrame.new(-4880,21,4260)},
    {Min=150, Max=174, Quest="SkyQuest", Nome="Sky Bandit", Level=1, NPC=CFrame.new(-4839,716,-2619), MobCF=CFrame.new(-4980,278,-2830)},
    {Min=175, Max=189, Quest="SkyQuest", Nome="Dark Master", Level=2, NPC=CFrame.new(-4839,716,-2619), MobCF=CFrame.new(-5250,388,-2270)},
    {Min=190, Max=209, Quest="PrisonerQuest", Nome="Prisoner", Level=1, NPC=CFrame.new(5308,0,474), MobCF=CFrame.new(5410,95,690)},
    {Min=210, Max=224, Quest="PrisonerQuest", Nome="Dangerous Prisoner", Level=2, NPC=CFrame.new(5308,0,474), MobCF=CFrame.new(5540,95,710)},
    {Min=225, Max=274, Quest="ColosseumQuest", Nome="Toga Warrior", Level=1, NPC=CFrame.new(-1580,6,-2986), MobCF=CFrame.new(-1820,50,-2740)},
    {Min=275, Max=299, Quest="ColosseumQuest", Nome="Gladiator", Level=2, NPC=CFrame.new(-1580,6,-2986), MobCF=CFrame.new(-1330,50,-3280)},
    {Min=300, Max=324, Quest="MagmaQuest", Nome="Military Soldier", Level=1, NPC=CFrame.new(-5313,7,8515), MobCF=CFrame.new(-5410,48,8540)},
    {Min=325, Max=374, Quest="MagmaQuest", Nome="Military Spy", Level=2, NPC=CFrame.new(-5313,7,8515), MobCF=CFrame.new(-5820,77,8820)},
    {Min=375, Max=399, Quest="FishmanQuest", Nome="Fishman Warrior", Level=1, NPC=CFrame.new(61122,17,1569), MobCF=CFrame.new(60900,90,1500)},
    {Min=400, Max=449, Quest="FishmanQuest", Nome="Fishman Commando", Level=2, NPC=CFrame.new(61122,17,1569), MobCF=CFrame.new(61800,90,1450)},
    {Min=450, Max=474, Quest="SkyExp1Quest", Nome="God's Guard", Level=1, NPC=CFrame.new(-4721,843,-1949), MobCF=CFrame.new(-4620,850,-1900)},
    {Min=475, Max=524, Quest="SkyExp1Quest", Nome="Shanda", Level=2, NPC=CFrame.new(-4721,843,-1949), MobCF=CFrame.new(-7680,5560,-500)},
    {Min=525, Max=624, Quest="SkyExp2Quest", Nome="Royal Squad", Level=1, NPC=CFrame.new(-7906,5634,-1411), MobCF=CFrame.new(-7600,5600,-1450)},
    {Min=625, Max=649, Quest="FountainQuest", Nome="Galley Pirate", Level=1, NPC=CFrame.new(5259,37,4050), MobCF=CFrame.new(5590,45,3990)},
    {Min=650, Max=699, Quest="FountainQuest", Nome="Galley Captain", Level=2, NPC=CFrame.new(5259,37,4050), MobCF=CFrame.new(5650,45,4950)},
    -- Sea 2
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
    -- Sea 3
    {Min=1500, Max=1574, Quest="PiratePortQuest", Nome="Pirate Millionaire", Level=1, NPC=CFrame.new(-289,44,5580), MobCF=CFrame.new(-200,45,5900)},
    {Min=1575, Max=1699, Quest="PiratePortQuest", Nome="Pistol Billionaire", Level=2, NPC=CFrame.new(-289,44,5580), MobCF=CFrame.new(-400,75,5950)},
    {Min=1700, Max=1824, Quest="AmazonQuest", Nome="Female Islander", Level=1, NPC=CFrame.new(5832,51,-1100), MobCF=CFrame.new(5400,80,-1000)},
    {Min=1825, Max=1974, Quest="MarineTreeIsland", Nome="Marine Commodore", Level=1, NPC=CFrame.new(2180,28,-6740), MobCF=CFrame.new(2450,75,-6700)},
    {Min=1975, Max=2074, Quest="HauntedQuest1", Nome="Reborn Skeleton", Level=1, NPC=CFrame.new(-9515,142,5536), MobCF=CFrame.new(-8750,140,5900)},
    {Min=2075, Max=2199, Quest="HauntedQuest2", Nome="Living Zombie", Level=1, NPC=CFrame.new(-9515,142,5536), MobCF=CFrame.new(-10150,140,5950)},
    {Min=2200, Max=2299, Quest="CandyQuest1", Nome="Candy Rebel", Level=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1000,20,-14200)},
    {Min=2300, Max=2449, Quest="CandyQuest2", Nome="Sweet Thief", Level=1, NPC=CFrame.new(-1149,13,-14445), MobCF=CFrame.new(-1200,20,-14700)},
    {Min=2450, Max=2599, Quest="TikiQuest1", Nome="Isle Outlaw", Level=1, NPC=CFrame.new(-16547,55,-172), MobCF=CFrame.new(-16800,30,-150)},
    {Min=2600, Max=2840, Quest="DragonDojoQuest", Nome="Dojo Fighter", Level=1, NPC=CFrame.new(-16547,55,-172), MobCF=CFrame.new(-16300,60,-350)}
}

local Waypoints = {
    ["Ilha Windmill"] = CFrame.new(1059,15,1550),
    ["Ilha Jungle"] = CFrame.new(-1598,35,153),
    ["Ilha Pirata"] = CFrame.new(-1141,4,3831),
    ["Ilha Deserto"] = CFrame.new(894,5,4392),
    ["Vila Gelada"] = CFrame.new(1389,85,-1298),
    ["Marine Ford"] = CFrame.new(-5039,27,4324),
    ["Ilha do Céu"] = CFrame.new(-4839,716,-2619),
    ["Prisão"] = CFrame.new(5308,0,474),
    ["Coliseu"] = CFrame.new(-1580,6,-2986),
    ["Ilha Magma"] = CFrame.new(-5313,7,8515),
    ["Cidade Submarina"] = CFrame.new(61122,17,1569),
    ["Cidade Fountain"] = CFrame.new(5259,37,4050),
    ["Templo do Tempo"] = CFrame.new(28282,14896,102),
    ["Ilha Kitsune"] = CFrame.new(-22123,22,-12345)
}

-- ════════════════════════════════════════
--  FUNÇÕES UTILITÁRIAS
-- ════════════════════════════════════════
local function ObterNivel()
    local data = LP:FindFirstChild("Data")
    return data and data:FindFirstChild("Level") and data.Level.Value or 1
end

local function ObterDadosQuest()
    local level = ObterNivel()
    for _, q in ipairs(DadosQuests) do
        if level >= q.Min and level <= q.Max then return q end
    end
    return DadosQuests[#DadosQuests]
end

local function ObterHRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function ObterHum()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function TemQuestAtiva()
    local gui = PGui:FindFirstChild("Main")
    if not gui then return false end
    local qf = gui:FindFirstChild("Quest")
    return qf and qf.Visible or false
end

local function TocarObjeto(hrp, objeto)
    if not hrp or not objeto or not objeto:IsA("BasePart") then return end
    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, objeto, 0)
            firetouchinterest(hrp, objeto, 1)
        end)
    end
end

-- SafeTween e FlyAnchor
local tweenAtual, destinoTween
local function SafeTween(targetCF, speed)
    local hrp = ObterHRP()
    if not hrp or typeof(targetCF) ~= "CFrame" then return end
    local vel = math.max(tonumber(speed) or Config.VelocidadeVoo or 260, 50)
    local dist = (hrp.Position - targetCF.Position).Magnitude
    if dist <= 10 then
        hrp.CFrame = targetCF
        return
    end
    if destinoTween and (destinoTween.Position - targetCF.Position).Magnitude < 8 and tweenAtual then return end
    if tweenAtual then pcall(function() tweenAtual:Cancel() end) end
    destinoTween = targetCF
    local ti = TweenInfo.new(dist / vel, Enum.EasingStyle.Linear)
    tweenAtual = TweenService:Create(hrp, ti, {CFrame = targetCF})
    tweenAtual:Play()
    tweenAtual.Completed:Connect(function()
        tweenAtual = nil
        destinoTween = nil
    end)
end

local function PararTween()
    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end
    destinoTween = nil
end

local function AncorarVoo(ativar)
    local hrp = ObterHRP()
    if not hrp then return end
    local bv = hrp:FindFirstChild("Voo_BF")
    if ativar then
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "Voo_BF"
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

-- Equipar Arma e Ataque
local function EquiparArma()
    local char = LP.Character
    local hum = ObterHum()
    if not char or not hum then return end
    if char:FindFirstChildOfClass("Tool") then return end
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == Config.TipoArma or tool:GetAttribute("WeaponType") == Config.TipoArma) then
            hum:EquipTool(tool)
            return
        end
    end
    local anyTool = backpack:FindFirstChildOfClass("Tool")
    if anyTool then hum:EquipTool(anyTool) end
end

local CombatFW
pcall(function()
    if LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("CombatFramework") then
        CombatFW = require(LP.PlayerScripts.CombatFramework)
    end
end)

local function AtaqueRapido(mob)
    pcall(function()
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        if CombatFW and CombatFW.activeController then
            local ac = CombatFW.activeController
            ac.hitboxMagnitude = 60
            ac.timeToNextAttack = 0
            ac.attacking = false
            pcall(function() ac:attack() end)
        end
        if Remotes.RegisterAttack then Remotes.RegisterAttack:FireServer(0) end
        if mob and Remotes.RegisterHit then
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if mhrp then
                Remotes.RegisterHit:FireServer(mhrp, {{mhrp, mhrp.Position}})
            end
        end
    end)
end

local function PuxarMobs(nomeMob, cfCentro)
    if not Config.PuxarMobs or not nomeMob or nomeMob == "" then return end
    pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return end
        for _, mob in ipairs(enemies:GetChildren()) do
            if string.find(mob.Name, nomeMob) then
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                local mhum = mob:FindFirstChildOfClass("Humanoid")
                if mhrp and mhum and mhum.Health > 0 then
                    if (mhrp.Position - cfCentro.Position).Magnitude <= 350 then
                        mhrp.Size = Vector3.new(60, 60, 60)
                        mhrp.Transparency = 0.85
                        mhrp.CanCollide = false
                        mhrp.CFrame = cfCentro
                        mhrp.AssemblyLinearVelocity = Vector3.zero
                        mhum.WalkSpeed = 0
                        mhum.JumpPower = 0
                    end
                end
            end
        end
    end)
end

local function UsarSkills()
    if type(VirtualInputManager) ~= "userdata" and type(VirtualInputManager) ~= "table" then return end
    local function tecla(key)
        if not VirtualInputManager.SendKeyEvent then return end
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
    pcall(function()
        if Config.AutoSkillZ then tecla(Enum.KeyCode.Z) end
        if Config.AutoSkillX then tecla(Enum.KeyCode.X) end
        if Config.AutoSkillC then tecla(Enum.KeyCode.C) end
        if Config.AutoSkillV then tecla(Enum.KeyCode.V) end
    end)
end

local lastBuso = 0
local function GarantirBuso()
    if not Config.AutoBuso then return end
    if tick() - lastBuso < 5 then return end
    lastBuso = tick()
    pcall(function()
        local char = LP.Character
        if char and not char:GetAttribute("HasBuso") then
            ExecutarComando("Buso")
        end
    end)
end

local function EncontrarMob(nomeFiltro)
    if not nomeFiltro or nomeFiltro == "" then return nil end
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, mob in ipairs(enemies:GetChildren()) do
        if string.find(mob.Name, nomeFiltro) then
            local mh = mob:FindFirstChildOfClass("Humanoid")
            local mr = mob:FindFirstChild("HumanoidRootPart")
            if mh and mh.Health > 0 and mr then return mob end
        end
    end
    return nil
end

local function FarmAteMorrer(mob, pararCheck)
    if not mob then return end
    local mhrp = mob:FindFirstChild("HumanoidRootPart")
    local mhum = mob:FindFirstChildOfClass("Humanoid")
    if not mhrp or not mhum then return end
    while mhum.Health > 0 and mhum.Parent and mhrp.Parent do
        if pararCheck and not pararCheck() then break end
        task.wait(0.05)
        local hrp = ObterHRP()
        local hum = ObterHum()
        if not hrp or not hum or hum.Health <= 0 then break end
        local dist = (hrp.Position - mhrp.Position).Magnitude
        local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, Config.DistanciaFarm, 0), mhrp.Position)
        if dist > 40 then
            AncorarVoo(false)
            SafeTween(flyPos)
        else
            PararTween()
            AncorarVoo(true)
            hrp.CFrame = flyPos
            hrp.AssemblyLinearVelocity = Vector3.zero
            PuxarMobs(mob.Name, mhrp.CFrame)
            EquiparArma()
            if Config.AtaqueRapido then AtaqueRapido(mob) end
            UsarSkills()
        end
    end
    AncorarVoo(false)
end

-- ════════════════════════════════════════
--  WEBHOOK
-- ════════════════════════════════════════
local function EnviarWebhook(titulo, desc, cor, campos)
    if not Config.AtivarWebhook or #Config.URLWebhook < 15 then return end
    task.spawn(function()
        pcall(function()
            local req = (syn and syn.request) or http_request or request or (fluxus and fluxus.request)
            if type(req) ~= "function" then return end
            req({
                Url = Config.URLWebhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    username = "Script BF",
                    embeds = {{
                        title = "[BF] " .. tostring(titulo),
                        description = tostring(desc),
                        color = cor or 65535,
                        fields = campos or {},
                        footer = {text = "Script BF • " .. os.date("%d/%m/%Y %H:%M")}
                    }}
                })
            })
        end)
    end)
end

-- ════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════
local espCache = {}
local function CriarESP(obj, texto, cor)
    if espCache[obj] then return end
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.FillColor = cor
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0.2
        hl.Adornee = obj
        hl.Parent = SafeParent
        
        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 140, 0, 30)
        bb.Adornee = obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart) or obj
        bb.Parent = SafeParent
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = texto
        lbl.TextColor3 = cor
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextStrokeTransparency = 0.3
        lbl.Parent = bb
        
        espCache[obj] = {hl, bb, lbl}
        obj.AncestryChanged:Connect(function()
            if not obj:IsDescendantOf(workspace) then
                for _, v in pairs(espCache[obj] or {}) do pcall(function() v:Destroy() end) end
                espCache[obj] = nil
            end
        end)
    end)
end

local function LimparESP()
    for obj, parts in pairs(espCache) do
        for _, v in pairs(parts) do pcall(function() v:Destroy() end) end
        espCache[obj] = nil
    end
end

-- ════════════════════════════════════════
--  CRIAÇÃO DA INTERFACE (GG-UI)
-- ════════════════════════════════════════
local Janela = GGUI_LIB:MakeWindow({
    Title = "Script BF Adaptado",
    SubTitle = "Sea " .. CurrentSea .. " | Lv." .. ObterNivel(),
    ScriptFolder = "BF_Adaptado"
})

-- Aba: Farm Nível
local AbaFarm = Janela:MakeTab({Title = "Farm Nível"})
AbaFarm:AddIcon({Name = "swords"})
AbaFarm:AddToggle({Name = "Auto Farm Nível", Default = false, Callback = function(v)
    Config.FarmNivel = v
    if not v then PararTween(); AncorarVoo(false) end
end})
AbaFarm:AddDropdown({Name = "Arma", Options = {"Melee", "Sword", "Blox Fruit", "Gun"}, Callback = function(v) Config.TipoArma = v end})
AbaFarm:AddToggle({Name = "Ataque Rápido v4", Default = true, Callback = function(v) Config.AtaqueRapido = v end})
AbaFarm:AddToggle({Name = "Puxar Mobs AOE", Default = true, Callback = function(v) Config.PuxarMobs = v end})
AbaFarm:AddToggle({Name = "Auto Buso Haki", Default = true, Callback = function(v) Config.AutoBuso = v end})
AbaFarm:AddSlider({Name = "Distância Farm", Min = 10, Max = 50, Default = 20, Increment = 1, Callback = function(v) Config.DistanciaFarm = v end})

-- Aba: Mob & Boss
local AbaMob = Janela:MakeTab({Title = "Mobs & Boss"})
AbaMob:AddIcon({Name = "skull"})
AbaMob:AddTextBox({Name = "Nome do Mob", Default = "Bandit", Callback = function(v) Config.MobSelecionado = v end})
AbaMob:AddToggle({Name = "Auto Farm Mob", Default = false, Callback = function(v)
    Config.FarmMob = v
    if not v then PararTween(); AncorarVoo(false) end
end})
AbaMob:AddSection("Boss")
local bossList = {"The Gorilla King", "Bobby", "Yeti", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg"}
AbaMob:AddDropdown({Name = "Boss Alvo", Options = bossList, Callback = function(v) Config.BossSelecionado = v end})
AbaMob:AddToggle({Name = "Auto Farm Boss", Default = false, Callback = function(v)
    Config.FarmBoss = v
    if not v then PararTween(); AncorarVoo(false) end
end})

-- Aba: Rápidos
local AbaRapido = Janela:MakeTab({Title = "Rápidos"})
AbaRapido:AddIcon({Name = "zap"})
AbaRapido:AddToggle({Name = "Auto Bau", Default = false, Callback = function(v) Config.AutoBau = v; if not v then PararTween() end end})
AbaRapido:AddToggle({Name = "Auto Status", Default = false, Callback = function(v) Config.AutoStatus = v end})
AbaRapido:AddSlider({Name = "Pontos por Rodada", Min = 1, Max = 10, Default = 3, Increment = 1, Callback = function(v) Config.ChunkStatus = v end})
for _, stat in ipairs({"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}) do
    AbaRapido:AddToggle({Name = "Upar " .. stat, Default = Config.StatusParaUpar[stat] or false, Callback = function(v) Config.StatusParaUpar[stat] = v end})
end

-- Aba: ESP
local AbaESP = Janela:MakeTab({Title = "ESP"})
AbaESP:AddIcon({Name = "eye"})
AbaESP:AddToggle({Name = "ESP Jogadores", Default = false, Callback = function(v) Config.ESP_Jogadores = v; if not v then LimparESP() end end})
AbaESP:AddToggle({Name = "ESP Baús", Default = false, Callback = function(v) Config.ESP_Baus = v; if not v then LimparESP() end end})
AbaESP:AddToggle({Name = "ESP Frutas", Default = false, Callback = function(v) Config.ESP_Frutas = v; if not v then LimparESP() end end})
AbaESP:AddToggle({Name = "ESP Mobs", Default = false, Callback = function(v) Config.ESP_Mobs = v; if not v then LimparESP() end end})

-- Aba: Skills & Frutas
local AbaSkill = Janela:MakeTab({Title = "Skills & Frutas"})
AbaSkill:AddIcon({Name = "sparkles"})
for _, k in ipairs({"Z", "X", "C", "V"}) do
    AbaSkill:AddToggle({Name = "Auto Skill " .. k, Default = false, Callback = function(v) Config["AutoSkill" .. k] = v end})
end
AbaSkill:AddToggle({Name = "Auto Sniper Fruta", Default = false, Callback = function(v) Config.AutoSniperFruta = v end})
AbaSkill:AddToggle({Name = "Auto Guardar Fruta", Default = false, Callback = function(v) Config.AutoGuardarFruta = v end})

-- Aba: Player
local AbaPlayer = Janela:MakeTab({Title = "Player"})
AbaPlayer:AddIcon({Name = "user"})
AbaPlayer:AddSlider({Name = "WalkSpeed", Min = 16, Max = 500, Default = 16, Increment = 1, Callback = function(v) Config.VelocidadeCaminhada = v; local h = ObterHum(); if h then h.WalkSpeed = v end end})
AbaPlayer:AddSlider({Name = "JumpPower", Min = 50, Max = 500, Default = 50, Increment = 1, Callback = function(v) Config.ForcaPulo = v; local h = ObterHum(); if h then h.JumpPower = v end end})
AbaPlayer:AddToggle({Name = "Noclip", Default = false, Callback = function(v) Config.Noclip = v end})
AbaPlayer:AddToggle({Name = "Pulo Infinito", Default = false, Callback = function(v) Config.PuloInfinito = v end})
AbaPlayer:AddToggle({Name = "Anti-AFK", Default = true, Callback = function(v) Config.AntiAFK = v end})

-- Aba: Eventos
local AbaEvento = Janela:MakeTab({Title = "Eventos"})
AbaEvento:AddIcon({Name = "star"})
AbaEvento:AddSection("Kitsune")
AbaEvento:AddToggle({Name = "Auto Coletar Embers", Default = false, Callback = function(v) Config.AutoColetarEmbers = v end})
AbaEvento:AddToggle({Name = "Auto Rezar Estátua", Default = false, Callback = function(v) Config.AutoRezarEstatua = v end})
AbaEvento:AddSection("Raça V4")
AbaEvento:AddToggle({Name = "Auto Despertar V4", Default = false, Callback = function(v) Config.AutoDespertarV4 = v end})
AbaEvento:AddToggle({Name = "Auto Skill Raça", Default = false, Callback = function(v) Config.AutoUsarSkillRaca = v end})
AbaEvento:AddSection("Mar")
AbaEvento:AddToggle({Name = "Auto Leviathan", Default = false, Callback = function(v) Config.AutoLeviathan = v end})
AbaEvento:AddToggle({Name = "Auto Sea Beast", Default = false, Callback = function(v) Config.AutoSeaBeast = v end})
AbaEvento:AddToggle({Name = "Auto Ship Raid", Default = false, Callback = function(v) Config.AutoShipRaid = v end})

-- Aba: Teleporte
local AbaTP = Janela:MakeTab({Title = "Teleporte"})
AbaTP:AddIcon({Name = "navigation"})
local wpNomes = {}
for k in pairs(Waypoints) do table.insert(wpNomes, k) end
table.sort(wpNomes)
local wpEscolhido = wpNomes[1]
AbaTP:AddDropdown({Name = "Ilha", Options = wpNomes, Callback = function(v) wpEscolhido = v end})
AbaTP:AddButton({Name = "Ir para Ilha", Callback = function()
    if Waypoints[wpEscolhido] then SafeTween(Waypoints[wpEscolhido]) end
end})
AbaTP:AddButton({Name = "Parar Voo", Callback = function() PararTween(); AncorarVoo(false) end})

-- Aba: Misc
local AbaMisc = Janela:MakeTab({Title = "Misc"})
AbaMisc:AddIcon({Name = "settings"})
AbaMisc:AddTextBox({Name = "URL Webhook", Default = Config.URLWebhook, Callback = function(v)
    local url = v:gsub("%s+", "")
    Config.URLWebhook = url
    if writefile then writefile(Config.ArquivoWebhook, url) end
    Config.AtivarWebhook = #url > 15
end})
AbaMisc:AddButton({Name = "Testar Webhook", Callback = function()
    EnviarWebhook("Teste", "Conexão OK!", 65535, {{name = "Player", value = LP.Name, inline = true}})
end})
AbaMisc:AddButton({Name = "Desligar Tudo", Callback = function()
    for k in pairs(Config) do if type(Config[k]) == "boolean" then Config[k] = false end end
    PararTween()
    AncorarVoo(false)
    LimparESP()
    Janela:Notify({Title = "Script", Content = "Tudo desligado.", Duration = 3})
end})

-- ════════════════════════════════════════
--  LOOPS DE FUNDO
-- ════════════════════════════════════════

-- Loop Farm Nível
task.spawn(function()
    while true do
        task.wait(0.03)
        if Config.FarmNivel then
            pcall(function()
                local hrp = ObterHRP()
                local hum = ObterHum()
                if not hrp or not hum or hum.Health <= 0 then AncorarVoo(false); return end
                local q = ObterDadosQuest()
                GarantirBuso()
                if not TemQuestAtiva() then
                    AncorarVoo(false)
                    if (hrp.Position - q.NPC.Position).Magnitude > 25 then
                        SafeTween(q.NPC)
                    else
                        PararTween()
                        hrp.CFrame = q.NPC
                        ExecutarComando("StartQuest", q.Quest, q.Level)
                        task.wait(0.4)
                    end
                else
                    local mob = EncontrarMob(q.Nome)
                    if mob then
                        local mhrp = mob:FindFirstChild("HumanoidRootPart")
                        if mhrp then
                            local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, Config.DistanciaFarm, 0), mhrp.Position)
                            if (hrp.Position - mhrp.Position).Magnitude > 40 then
                                AncorarVoo(false)
                                SafeTween(flyPos)
                            else
                                PararTween()
                                AncorarVoo(true)
                                hrp.CFrame = flyPos
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                PuxarMobs(q.Nome, mhrp.CFrame)
                                EquiparArma()
                                if Config.AtaqueRapido then AtaqueRapido(mob) end
                                UsarSkills()
                            end
                        end
                    else
                        AncorarVoo(false)
                        SafeTween(q.MobCF)
                    end
                end
            end)
        end
    end
end)

-- Loop Farm Mob
task.spawn(function()
    while true do
        task.wait(0.05)
        if Config.FarmMob and not Config.FarmNivel then
            pcall(function()
                local hum = ObterHum()
                if not hum or hum.Health <= 0 then AncorarVoo(false); return end
                GarantirBuso()
                local mob = EncontrarMob(Config.MobSelecionado)
                if mob then FarmAteMorrer(mob, function() return Config.FarmMob and not Config.FarmNivel end) end
            end)
        end
    end
end)

-- Loop Farm Boss
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.FarmBoss and not Config.FarmNivel then
            pcall(function()
                local hrp = ObterHRP()
                local hum = ObterHum()
                if not hrp or not hum or hum.Health <= 0 then AncorarVoo(false); return end
                GarantirBuso()
                local mob = EncontrarMob(Config.BossSelecionado)
                if mob then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if mhrp then
                        local flyPos = CFrame.new(mhrp.Position + Vector3.new(0, Config.DistanciaFarm + 4, 0), mhrp.Position)
                        if (hrp.Position - mhrp.Position).Magnitude > 40 then
                            AncorarVoo(false); SafeTween(flyPos)
                        else
                            PararTween(); AncorarVoo(true)
                            hrp.CFrame = flyPos
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            EquiparArma()
                            if Config.AtaqueRapido then AtaqueRapido(mob) end
                            UsarSkills()
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop Auto Bau
task.spawn(function()
    while true do
        task.wait(0.4)
        if Config.AutoBau and not Config.FarmNivel then
            pcall(function()
                local hrp = ObterHRP()
                if not hrp then return end
                local nearest, nearDist = nil, math.huge
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
                        local d = (hrp.Position - obj.Position).Magnitude
                        if d < nearDist then nearest = obj; nearDist = d end
                    end
                end
                if nearest then
                    SafeTween(nearest.CFrame * CFrame.new(0, 2, 0), Config.VelocidadeVoo)
                    if nearDist <= 12 then
                        TocarObjeto(hrp, nearest)
                        Config.ContadorBaus = Config.ContadorBaus + 1
                        task.wait(0.2)
                    end
                end
            end)
        end
    end
end)

-- Loop Auto Status
task.spawn(function()
    while true do
        task.wait(1.5)
        if Config.AutoStatus and Remotes.CommF_ then
            pcall(function()
                local data = LP:FindFirstChild("Data")
                if not data then return end
                local pts = data:FindFirstChild("Points") and data.Points.Value or 0
                if pts <= 0 then return end
                local chunk = math.min(pts, Config.ChunkStatus)
                for stat, en in pairs(Config.StatusParaUpar) do
                    if en then ExecutarComando("AddPoint", stat, chunk); task.wait(0.08) end
                end
            end)
        end
    end
end)

-- Loop ESP
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local myHRP = ObterHRP()
            local function dist(p) return myHRP and (myHRP.Position - p).Magnitude or 0 end
            if Config.ESP_Jogadores then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hr = p.Character:FindFirstChild("HumanoidRootPart")
                        local hm = p.Character:FindFirstChildOfClass("Humanoid")
                        if hr and hm and hm.Health > 0 then
                            CriarESP(p.Character, p.Name .. " [" .. math.floor(dist(hr.Position)) .. "m]", Color3.fromRGB(0, 230, 255))
                        end
                    end
                end
            end
            if Config.ESP_Baus then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name, "Chest") and obj:FindFirstChild("TouchInterest") then
                        CriarESP(obj, "Bau [" .. math.floor(dist(obj.Position)) .. "m]", Color3.fromRGB(255, 215, 0))
                    end
                end
            end
            if Config.ESP_Frutas then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if string.find(obj.Name, "Fruit") then
                        CriarESP(obj, obj.Name, Color3.fromRGB(220, 80, 255))
                    end
                end
            end
            if Config.ESP_Mobs then
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mh = mob:FindFirstChildOfClass("Humanoid")
                        if mh and mh.Health > 0 then
                            CriarESP(mob, mob.Name .. " [HP:" .. math.floor(mh.Health) .. "]", Color3.fromRGB(255, 120, 50))
                        end
                    end
                end
            end
            if not Config.ESP_Jogadores and not Config.ESP_Baus and not Config.ESP_Frutas and not Config.ESP_Mobs then
                LimparESP()
            end
        end)
    end
end)

-- Loop Frutas
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local hrp = ObterHRP()
            if not hrp then return end
            if Config.AutoSniperFruta then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if string.find(obj.Name, "Fruit") then
                        local handle = obj:FindFirstChild("Handle") or (obj:IsA("BasePart") and obj)
                        if handle then
                            SafeTween(handle.CFrame, 350)
                            if (hrp.Position - handle.Position).Magnitude <= 10 then
                                TocarObjeto(hrp, handle)
                                EnviarWebhook("Fruta", obj.Name .. " coletada!", 16753920)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
            if Config.AutoGuardarFruta and Remotes.CommF_ then
                local bp = LP:FindFirstChild("Backpack")
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA("Tool") and string.find(t.Name, "Fruit") then
                            ExecutarComando("StoreFruit", t.Name, t)
                            task.wait(0.4)
                        end
                    end
                end
            end
        end)
    end
end)

-- Loop Eventos (Kitsune, V4, Mar)
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local hrp = ObterHRP()
            if Config.AutoColetarEmbers and hrp and Remotes.CollectBlueEmber then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if string.find(obj.Name or "", "Ember") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                        if part then Remotes.CollectBlueEmber:FireServer(part); SafeTween(part.CFrame, 350) end
                    end
                end
            end
            if Config.AutoRezarEstatua and Remotes.KitsuneStatuePray then pcall(function() Remotes.KitsuneStatuePray:InvokeServer() end) end
            if Config.AutoDespertarV4 and Remotes.ActivateRaceV4 then pcall(function() Remotes.ActivateRaceV4:FireServer() end) end
            if Config.AutoUsarSkillRaca and Remotes.UsedRaceSkill then pcall(function() Remotes.UsedRaceSkill:FireServer() end) end
            if Config.AutoEngrenagemMirage and hrp then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "Gear" or string.find(obj.Name, "MirageGear") then SafeTween(obj.CFrame, 350); break end
                end
            end
            if Config.AutoLeviathan and hrp then
                local sb = workspace:FindFirstChild("SeaBeasts") or workspace:FindFirstChild("Enemies")
                if sb then
                    for _, beast in ipairs(sb:GetChildren()) do
                        if string.find(beast.Name, "Leviathan") then
                            local bhrp = beast:FindFirstChild("HumanoidRootPart")
                            if bhrp then SafeTween(bhrp.CFrame * CFrame.new(0, 30, 0)); EquiparArma(); AtaqueRapido(beast) end
                        end
                    end
                end
            end
            if Config.AutoSeaBeast and hrp then
                local sb = workspace:FindFirstChild("SeaBeasts") or workspace:FindFirstChild("Enemies")
                if sb then
                    for _, beast in ipairs(sb:GetChildren()) do
                        if string.find(beast.Name, "SeaBeast") then
                            local bhrp = beast:FindFirstChild("HumanoidRootPart")
                            if bhrp then SafeTween(bhrp.CFrame * CFrame.new(0, 35, 0)); EquiparArma(); AtaqueRapido(beast) end
                        end
                    end
                end
            end
            if Config.AutoShipRaid and hrp then
                local boats = workspace:FindFirstChild("Boats") or workspace:FindFirstChild("Enemies")
                if boats then
                    for _, boat in ipairs(boats:GetChildren()) do
                        if string.find(boat.Name, "Brigade") or string.find(boat.Name, "Ship") then
                            local bhrp = boat:FindFirstChild("HumanoidRootPart") or boat:FindFirstChildOfClass("BasePart")
                            if bhrp then SafeTween(bhrp.CFrame * CFrame.new(0, 25, 0)); EquiparArma(); AtaqueRapido(boat) end
                        end
                    end
                end
            end
        end)
    end
end)

-- Noclip e Movimento
RunService.Stepped:Connect(function()
    pcall(function()
        local char = LP.Character
        if not char then return end
        if Config.Noclip or Config.FarmNivel or Config.FarmMob or Config.FarmBoss or Config.AutoBau then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
        local hum = ObterHum()
        if hum then
            if hum.WalkSpeed ~= Config.VelocidadeCaminhada then hum.WalkSpeed = Config.VelocidadeCaminhada end
            if hum.JumpPower ~= Config.ForcaPulo then hum.JumpPower = Config.ForcaPulo end
        end
    end)
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
    if Config.PuloInfinito then
        local hum = ObterHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Atualiza Level no SubTitle
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            if Janela.SetSubTitle then
                Janela:SetSubTitle("Sea " .. CurrentSea .. " | Lv." .. ObterNivel())
            end
        end)
    end
end)

print("══════════════════════════════════════")
print("Script BF Adaptado | Sea " .. CurrentSea .. " | Lv." .. ObterNivel())
print("UI GG-UI carregada com sucesso!")
print("══════════════════════════════════════")