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
    warn("[Aviso] Falha ao carregar a GG-UI.")
    return
end

local SafeParent = (gethui and gethui()) or (syn and syn.protect_gui and (function()
    local f = Instance.new("Folder")
    syn.protect_gui(f)
    f.Parent = CoreGui
    return f
end)()) or PGui

local CurrentSea = 1
if game.PlaceId == 4442272183 then CurrentSea = 2
elseif game.PlaceId == 7449423635 then CurrentSea = 3 end

-- ════════════════════════════════════════
--  VARIÁVEIS GLOBAIS (TRADUZIDAS)
-- ════════════════════════════════════════
local Root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local CommF_ = Remotes and Remotes:FindFirstChild("CommF_")
local Enemies = workspace:FindFirstChild("Enemies")

local Config = {
    FarmNivel = false,
    FarmMaterial = false,
    MaterialSelecionado = "Leather",
    FarmInimigoProximo = false,
    MatarBoss = false,
    Noclip = false,
    VelocidadeVoo = 260,
    ArmaSelecionada = "Melee",
    
    -- Webhook
    AtivarWebhook = false,
    URLWebhook = ""
}

-- Listas de Boss e Materiais por Sea
local ListaBoss = {}
local ListaMateriais = {}

if game.PlaceId == 2753915549 or game.PlaceId == 85211729168715 then
    CurrentSea = 1
    ListaBoss = {"The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader", "Vice Admiral", "Saber Expert", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Ice Admiral", "Greybeard"}
    ListaMateriais = {"Leather + Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail"}
elseif game.PlaceId == 4442272183 then
    CurrentSea = 2
    ListaBoss = {"Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Awakened Ice Admiral", "Tide Keeper", "Darkbeard", "Cursed Captain", "Order"}
    ListaMateriais = {"Leather + Scrap Metal", "Radioactive Material", "Ectoplasm", "Mystic Droplet", "Magma Ore", "Vampire Fang"}
elseif game.PlaceId == 7449423635 then
    CurrentSea = 3
    ListaBoss = {"Stone", "Hydra Leader", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "Cake Queen", "Longma", "Soul Reaper"}
    ListaMateriais = {"Scrap Metal", "Demonic Wisp", "Conjured Cocoa", "Dragon Scale", "Gunpowder", "Fish Tail", "Mini Tusk"}
end

-- ════════════════════════════════════════
--  SISTEMA DE TELEPORTE (BLOCK INVISÍVEL)
-- ════════════════════════════════════════
local Block = Instance.new("Part", workspace)
Block.Size = Vector3.new(1, 1, 1)
Block.Name = "SkyNet_Block"
Block.Anchored = true
Block.CanCollide = false
Block.CanTouch = false
Block.Transparency = 1

task.spawn(function()
    while task.wait() do
        if Config.FarmNivel or Config.FarmMaterial or Config.FarmInimigoProximo or Config.MatarBoss then
            pcall(function()
                if Root then Block.CFrame = Root.CFrame end
            end)
        end
    end
end)

local function Teleporte(target)
    if not Root then return end
    Block.CFrame = Root.CFrame
    local dist = (target.Position - Root.Position).Magnitude
    local tweenInfo = TweenInfo.new(dist / 150, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Block, tweenInfo, {CFrame = target})
    tween:Play()
    
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not (Config.FarmNivel or Config.FarmMaterial or Config.FarmInimigoProximo or Config.MatarBoss) then
                tween:Cancel()
                break
            end
            if Root and (Root.Position - Block.Position).Magnitude < 10 then
                break
            end
            task.wait(0.1)
        end
    end)
end

local function TeleporteRapido(targetCFrame)
    if Root then
        Root.CFrame = targetCFrame
    end
end

-- ════════════════════════════════════════
--  FUNÇÕES UTILITÁRIAS DE COMBATE
-- ════════════════════════════════════════
local function EquiparArma(tipo)
    local backpack = LP:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == tipo then
            LP.Character.Humanoid:EquipTool(tool)
            return
        end
    end
end

local function PuxarInimigos(PosMon)
    if not Enemies then return end
    for _, v in pairs(Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v.PrimaryPart then
            if (v.PrimaryPart.Position - PosMon).Magnitude <= 300 then
                v.PrimaryPart.CFrame = CFrame.new(PosMon)
                v.PrimaryPart.CanCollide = true
                v.Humanoid.WalkSpeed = 0
                v.Humanoid.JumpPower = 0
            end
        end
    end
end

local function AtacarInimigo(mob)
    if not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then return end
    
    -- Trava a posição original do mob
    if not mob:GetAttribute("Travado") then
        mob:SetAttribute("Travado", mob.HumanoidRootPart.CFrame)
    end
    local PosMon = mob:GetAttribute("Travado").Position
    
    PuxarInimigos(PosMon)
    EquiparArma(Config.ArmaSelecionada)
    
    -- Teleporta para perto do mob
    TeleporteRapido(mob.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
    
    -- Simula o ataque (ativa a ferramenta)
    local tool = LP.Character:FindFirstChildOfClass("Tool")
    if tool then tool:Activate() end
end

-- ════════════════════════════════════════
--  DADOS DE QUESTS (SIMPLIFICADO)
-- ════════════════════════════════════════
local DadosQuest = {
    -- Sea 1
    {Min=1, Max=9, Nome="Bandit", Quest="BanditQuest1", Level=1, NPC=CFrame.new(1059,15,1550)},
    {Min=10, Max=14, Nome="Monkey", Quest="JungleQuest", Level=1, NPC=CFrame.new(-1598,35,153)},
    {Min=15, Max=29, Nome="Gorilla", Quest="JungleQuest", Level=2, NPC=CFrame.new(-1598,35,153)},
    {Min=30, Max=39, Nome="Pirate", Quest="BuggyQuest1", Level=1, NPC=CFrame.new(-1141,4,3831)},
    {Min=40, Max=59, Nome="Brute", Quest="BuggyQuest1", Level=2, NPC=CFrame.new(-1141,4,3831)},
    {Min=60, Max=74, Nome="Desert Bandit", Quest="DesertQuest", Level=1, NPC=CFrame.new(894,5,4392)},
    {Min=75, Max=89, Nome="Desert Officer", Quest="DesertQuest", Level=2, NPC=CFrame.new(894,5,4392)},
    {Min=90, Max=99, Nome="Snow Bandit", Quest="SnowQuest", Level=1, NPC=CFrame.new(1389,85,-1298)},
    {Min=100, Max=119, Nome="Snowman", Quest="SnowQuest", Level=2, NPC=CFrame.new(1389,85,-1298)},
    -- Sea 2
    {Min=700, Max=724, Nome="Raider", Quest="Area1Quest", Level=1, NPC=CFrame.new(-429,72,1836)},
    {Min=725, Max=774, Nome="Mercenary", Quest="Area1Quest", Level=2, NPC=CFrame.new(-429,72,1836)},
    -- Sea 3 (Adicione mais conforme necessário)
    {Min=1500, Max=1574, Nome="Pirate Millionaire", Quest="PiratePortQuest", Level=1, NPC=CFrame.new(-289,44,5580)},
}

local function ObterNivel()
    local data = LP:FindFirstChild("Data")
    return data and data:FindFirstChild("Level") and data.Level.Value or 1
end

local function ObterQuestAtual()
    local level = ObterNivel()
    for _, q in ipairs(DadosQuest) do
        if level >= q.Min and level <= q.Max then return q end
    end
    return DadosQuest[#DadosQuest]
end

-- ════════════════════════════════════════
--  CRIAÇÃO DA INTERFACE (GG-UI)
-- ════════════════════════════════════════
local Janela = GGUI_LIB:MakeWindow({
    Title = "SkyNet Adaptado",
    SubTitle = "Sea " .. CurrentSea .. " | Lv." .. ObterNivel(),
    ScriptFolder = "SkyNet_GG"
})

-- Aba Principal (Home)
local AbaHome = Janela:MakeTab({Title = "Home"})
AbaHome:AddIcon({Name = "home"})
AbaHome:AddLabel({Text = "Bem-vindo ao SkyNet Adaptado!"})
AbaHome:AddLabel({Text = "Sea: " .. CurrentSea .. " | Level: " .. ObterNivel()})

-- Aba Farm Level
local AbaFarm = Janela:MakeTab({Title = "Farm Level"})
AbaFarm:AddIcon({Name = "swords"})
AbaFarm:AddToggle({Name = "Auto Farm Nível", Default = false, Callback = function(v)
    Config.FarmNivel = v
end})
AbaFarm:AddDropdown({Name = "Arma", Options = {"Melee", "Sword", "Blox Fruit", "Gun"}, Callback = function(v)
    Config.ArmaSelecionada = v
end})

-- Aba Materiais
local AbaMat = Janela:MakeTab({Title = "Materiais"})
AbaMat:AddIcon({Name = "box"})
AbaMat:AddDropdown({Name = "Material Alvo", Options = ListaMateriais, Callback = function(v)
    Config.MaterialSelecionado = v
end})
AbaMat:AddToggle({Name = "Auto Farm Material", Default = false, Callback = function(v)
    Config.FarmMaterial = v
end})

-- Aba Combate
local AbaCombate = Janela:MakeTab({Title = "Combate"})
AbaCombate:AddIcon({Name = "skull"})
AbaCombate:AddToggle({Name = "Auto Farm Inimigo Próximo", Default = false, Callback = function(v)
    Config.FarmInimigoProximo = v
end})
AbaCombate:AddSection("Boss")
AbaCombate:AddDropdown({Name = "Boss Alvo", Options = ListaBoss, Callback = function(v)
    Config.BossSelecionado = v
end})
AbaCombate:AddToggle({Name = "Auto Matar Boss", Default = false, Callback = function(v)
    Config.MatarBoss = v
end})

-- Aba Teleporte
local AbaTP = Janela:MakeTab({Title = "Teleporte"})
AbaTP:AddIcon({Name = "navigation"})
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
}
local wpNomes = {}
for k in pairs(Waypoints) do table.insert(wpNomes, k) end
table.sort(wpNomes)
local wpEscolhido = wpNomes[1]
AbaTP:AddDropdown({Name = "Ilha", Options = wpNomes, Callback = function(v) wpEscolhido = v end})
AbaTP:AddButton({Name = "Ir para Ilha", Callback = function()
    if Waypoints[wpEscolhido] then Teleporte(Waypoints[wpEscolhido]) end
end})
AbaTP:AddButton({Name = "Parar Voo", Callback = function()
    Config.FarmNivel = false
    Config.FarmMaterial = false
    Config.FarmInimigoProximo = false
    Config.MatarBoss = false
end})

-- Aba Misc
local AbaMisc = Janela:MakeTab({Title = "Misc"})
AbaMisc:AddIcon({Name = "settings"})
AbaMisc:AddToggle({Name = "Noclip", Default = false, Callback = function(v) Config.Noclip = v end})
AbaMisc:AddTextBox({Name = "URL Webhook", Default = Config.URLWebhook, Callback = function(v)
    Config.URLWebhook = v
    Config.AtivarWebhook = #v > 15
end})
AbaMisc:AddButton({Name = "Desligar Tudo", Callback = function()
    for k in pairs(Config) do if type(Config[k]) == "boolean" then Config[k] = false end end
    Janela:Notify({Title = "Script", Content = "Tudo desligado.", Duration = 3})
end})

-- ════════════════════════════════════════
--  LOOPS DE FUNDO
-- ════════════════════════════════════════

-- Loop Farm Nível
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.FarmNivel then
            pcall(function()
                local quest = ObterQuestAtual()
                if not quest then return end
                
                local questGui = PGui:FindFirstChild("Main") and PGui.Main:FindFirstChild("Quest")
                local hasQuest = questGui and questGui.Visible
                
                if not hasQuest then
                    Teleporte(quest.NPC)
                    if Root and (Root.Position - quest.NPC.Position).Magnitude <= 10 then
                        CommF_:InvokeServer("StartQuest", quest.Quest, quest.Level)
                        task.wait(0.5)
                    end
                else
                    local targetMob = nil
                    if Enemies then
                        for _, mob in ipairs(Enemies:GetChildren()) do
                            if string.find(mob.Name, quest.Nome) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                                targetMob = mob
                                break
                            end
                        end
                    end
                    
                    if targetMob then
                        repeat
                            AtacarInimigo(targetMob)
                            task.wait(0.05)
                        until not Config.FarmNivel or not targetMob.Parent or targetMob.Humanoid.Health <= 0
                    end
                end
            end)
        end
    end
end)

-- Loop Farm Material (Simplificado)
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.FarmMaterial then
            pcall(function()
                -- Lógica genérica: procura mobs e ataca
                if Enemies then
                    for _, mob in ipairs(Enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            AtacarInimigo(mob)
                            break
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop Farm Inimigo Próximo
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.FarmInimigoProximo then
            pcall(function()
                if Enemies then
                    for _, mob in ipairs(Enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            repeat
                                AtacarInimigo(mob)
                                task.wait(0.05)
                            until not Config.FarmInimigoProximo or not mob.Parent or mob.Humanoid.Health <= 0
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop Matar Boss
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.MatarBoss then
            pcall(function()
                if Enemies then
                    for _, mob in ipairs(Enemies:GetChildren()) do
                        if mob.Name == Config.BossSelecionado and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            repeat
                                AtacarInimigo(mob)
                                task.wait(0.05)
                            until not Config.MatarBoss or not mob.Parent or mob.Humanoid.Health <= 0
                        end
                    end
                end
            end)
        end
    end
end)

-- Loop Noclip
RunService.Stepped:Connect(function()
    if Config.Noclip then
        pcall(function()
            if LP.Character then
                for _, part in ipairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
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
print("SkyNet Adaptado | Sea " .. CurrentSea .. " | Lv." .. ObterNivel())
print("UI GG-UI carregada com sucesso!")
print("══════════════════════════════════════")
