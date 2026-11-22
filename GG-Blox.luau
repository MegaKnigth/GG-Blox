--============================================================
--  GG BLOX v0.1
--  Fontes: redz Module.luau, Sankeurr/OpenSource-Blox-Fruits-Script,
--          haxhell fast-attack, Untie X (paths de Net)
--============================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CollectionService  = game:GetService("CollectionService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local LP                 = Players.LocalPlayer

local PLACES = {2753915549, 4442272183, 7449423635, 85211729168715, 79091703265657, 100117331123089}
local SEA = table.find(PLACES, game.PlaceId)
if not SEA then return LP:Kick("GG Blox: jogo nao suportado") end
if SEA > 3 then SEA -= 3 end
local SEA_NAME = ({"Main", "Dressrosa", "Zou"})[SEA]

local REPO = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/"

--======================= UI =======================
local src
do
    local ok, res = pcall(game.HttpGet, game, REPO .. "GG-Ui.luau")
    if ok and type(res) == "string" and #res > 1000 then src = res end
    if not src then
        local ok2, res2 = pcall(readfile, "GGBlox/GG-Ui.luau")
        if ok2 then src = res2 end
    end
end
if not src then return LP:Kick("GG Blox: falha ao baixar a UI") end

local chunk, perr = loadstring(src)
if not chunk then return LP:Kick("GG Blox: UI invalida -> " .. tostring(perr)) end
local Library = chunk()

local Window = Library:MakeWindow({
    Name = "GG Blox v0.1",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "VeniceHub",
})
if type(Library.Init) == "function" then pcall(Library.Init, Library) end

local function notify(txt)
    pcall(function()
        Window:Notify({ Title = "GG Blox", Content = tostring(txt), Duration = 4 })
    end)
end

--======================= REFS =======================
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_  = Remotes:WaitForChild("CommF_")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net     = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")
local ShootGunEvent  = Net:WaitForChild("RE/ShootGunEvent")

local Enemies    = workspace:WaitForChild("Enemies")
local Characters = workspace:WaitForChild("Characters")
local ChestTag   = "_ChestTagged"

local function requireModule(names)
    for _, n in ipairs(names) do
        local m = Modules:FindFirstChild(n)
        if m then
            local ok, res = pcall(require, m)
            if ok and type(res) == "table" then return res end
        end
    end
end
local QuestsModule = requireModule({"Quests", "Quest"})
local GuideModule  = requireModule({"Guide", "GuideModule"})

local function inv(...)
    local ok, res = pcall(CommF_.InvokeServer, CommF_, ...)
    if ok then return res end
end

--======================= ESTADO =======================
local State = {
    AutoFarm   = false,
    KillAura   = false,
    AuraRange  = 120,
    AttackMobs = true,
    AttackPl   = true,
    BringMobs  = false,
    TweenSpeed = 300,
    Esp        = false,
    EspDist    = true,
    Noclip     = false,
    AutoChest  = false,
    AutoHaki   = false,
    Quest      = nil,
}
local Dead = false
local startedAt = 0

--======================= UTIL =======================
local LIMBS = {"RightLowerArm", "LeftLowerArm", "RightUpperArm", "LeftUpperArm",
               "RightHand", "LeftHand", "RightFoot", "LeftFoot", "RightLowerLeg",
               "LeftLowerLeg", "UpperTorso", "LowerTorso", "Head"}

local DEFAULT_CD = {["Blox Fruit"] = 0.35, ["Melee"] = 0.4, ["Sword"] = 0.4, ["Gun"] = 0.2}

local hitId = 0
local combo = 0
local function newHitId()
    hitId += 1
    if hitId > 1e6 then hitId = 1 end
    return hitId
end

local function root()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isAlive(model)
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function dist(pos)
    local r = root()
    if not r then return math.huge end
    return (r.Position - pos).Magnitude
end

local function equipped()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Tool")
end

local function isWeapon(tool)
    if not tool then return false end
    local t = tool.ToolTip
    return t == "Sword" or t == "Gun" or t == "Blox Fruit" or t == "Melee"
end

local function cooldownOf(tool)
    local c = tool:FindFirstChild("Cooldown")
    if c and c:IsA("NumberValue") then return c.Value end
    return DEFAULT_CD[tool.ToolTip] or 0.4
end

local function tweenTo(pos)
    local r = root()
    if not r then return end
    local d = (r.Position - pos).Magnitude
    if d < 50 then
        r.CFrame = CFrame.new(pos)
        return
    end
    local tw = TweenService:Create(r, TweenInfo.new(d / State.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tw:Play()
    tw.Completed:Wait()
end

--======================= ALVO =======================
local function ownerModel(part)
    local model = part.Parent
    local parent = model and model.Parent
    if parent ~= Characters and parent ~= Enemies then
        if parent and parent.Parent == workspace then
            model, parent = parent, workspace
        elseif model and model.Parent == workspace then
            parent = workspace
        end
    end
    if parent == Characters or parent == Enemies or (model and model.Parent == workspace) then
        return model, parent
    end
end

local function collect(center, range)
    local list, seen = {}, {}
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character}

    local size = range * 2
    local parts = workspace:GetPartBoundsInBox(center.CFrame, Vector3.new(size, size, size), params)

    for _, p in ipairs(parts) do
        if #list >= 12 then break end
        local model, parent = ownerModel(p)
        if model and not seen[model] and isAlive(model) then
            if parent == Characters then
                local plr = Players:GetPlayerFromCharacter(model)
                if plr and plr ~= LP and State.AttackPl then
                    seen[model] = true
                    table.insert(list, {model, p})
                end
            elseif State.AttackMobs then
                seen[model] = true
                table.insert(list, {model, p})
            end
        end
    end
    return list
end

--======================= ATAQUE =======================
local lastAttack = 0

local function doAttack(center)
    local tool = equipped()
    if not tool or not isWeapon(tool) then return end
    local cd = cooldownOf(tool)
    if os.clock() - lastAttack < cd then return end

    local hits = collect(center, State.AuraRange)
    if #hits == 0 then return end
    lastAttack = os.clock()

    combo += 1
    if combo > 4 then combo = 1 end

    RegisterAttack:FireServer(cd, combo)

    local myChar = LP.Character
    local limb = myChar and myChar:FindFirstChild(LIMBS[math.random(#LIMBS)]) or center
    local id = newHitId()

    if tool.ToolTip == "Blox Fruit" then
        local lcr = tool:FindFirstChild("LeftClickRemote")
        local target = hits[1][2]
        if lcr and target and root() then
            pcall(function()
                lcr:FireServer(tool, (target.Position - root().Position).Unit, id)
            end)
        end
    elseif tool.ToolTip == "Gun" then
        pcall(function() ShootGunEvent:FireServer(hits[1][2].Position, {hits[1][2]}) end)
    else
        -- 4o argumento = hitId; sem ele o servidor ignora o hit
        RegisterHit:FireServer(limb, hits, nil, id)
        -- build alternativa (5 args):
        -- RegisterHit:FireServer(limb, hits, nil, nil, id)
    end
end

RunService.RenderStepped:Connect(function()
    if Dead or not root() then return end
    if not (State.KillAura or State.AutoFarm) then return end
    doAttack(root())
end)

--======================= ESP =======================
local espTrack = {}

local function makeEsp(model, label)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "GGBloxEsp"
    bb.Size = UDim2.fromScale(4, 1)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.fromScale(1, 1)
    tl.BackgroundTransparency = 1
    tl.TextScaled = true
    tl.TextColor3 = Color3.fromRGB(255, 80, 80)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.Text = label
    tl.Parent = bb
    bb.Parent = hrp
    espTrack[model] = {Gui = bb, Text = tl}
end

local function clearEsp()
    for _, data in pairs(espTrack) do
        if data.Gui then data.Gui:Destroy() end
    end
    table.clear(espTrack)
end

task.spawn(function()
    while not Dead do
        task.wait(0.5)
        if not State.Esp then
            if next(espTrack) then clearEsp() end
            continue
        end
        for _, model in ipairs(Enemies:GetChildren()) do
            if isAlive(model) and not espTrack[model] then makeEsp(model, model.Name) end
        end
        for _, model in ipairs(Characters:GetChildren()) do
            if model ~= LP.Character and isAlive(model) and not espTrack[model] then makeEsp(model, model.Name) end
        end
        for model, data in pairs(espTrack) do
            if not model.Parent or not isAlive(model) then
                if data.Gui then data.Gui:Destroy() end
                espTrack[model] = nil
            elseif State.EspDist then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local r = root()
                if hrp and r then
                    data.Text.Text = string.format("%s [%d]", model.Name, math.floor((hrp.Position - r.Position).Magnitude))
                end
            end
        end
    end
end)

--======================= QUESTS =======================
local function questList()
    local out = {}
    if not QuestsModule then return out end
    local lo, hi = 0, 700
    if SEA == 2 then lo, hi = 700, 1500 elseif SEA == 3 then lo, hi = 1500, math.huge end
    for key, group in pairs(QuestsModule) do
        if type(group) == "table" then
            for idx, q in pairs(group) do
                local lvl = q.LevelReq
                if type(lvl) == "number" and lvl >= lo and lvl < hi then
                    table.insert(out, {Key = key, Index = idx, Level = lvl, Name = q.QuestTitle or tostring(key)})
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.Level < b.Level end)
    return out
end

local function questTargets(q)
    if not GuideModule or not GuideModule.GetQuestTasks or not QuestsModule then return nil end
    local group = QuestsModule[q.Key]
    local obj = group and group[q.Index]
    if not obj then return nil end
    local ok, targets, locs = pcall(GuideModule.GetQuestTasks, obj)
    if ok then return targets, locs end
end

local function startQuest(q)
    inv("StartQuest", q.Key, q.Index)
    State.Quest = q
    startedAt = os.clock()
end

local function abandonQuest()
    inv("AbandonQuest")
    State.Quest = nil
end

local function findEnemy(name)
    for _, m in ipairs(Enemies:GetChildren()) do
        if m.Name == name and isAlive(m) then return m end
    end
    for _, m in ipairs(CollectionService:GetTagged("BasicMob")) do
        if m.Name == name and isAlive(m) then return m end
    end
end

local function questDone()
    if os.clock() - startedAt < 4 then return false end
    local gui = LP.PlayerGui:FindFirstChild("Quest")
    local obj = gui and gui:FindFirstChild("Objective")
    return gui == nil or obj == nil
end

task.spawn(function()
    while not Dead do
        task.wait(0.3)
        if not State.AutoFarm or not root() then continue end

        if not State.Quest then
            local best
            local lvl = LP.Data.Level.Value
            for _, q in ipairs(questList()) do
                if q.Level <= lvl then best = q else break end
            end
            if best then
                startQuest(best)
                task.wait(0.6)
            else
                task.wait(1)
                continue
            end
        end

        if questDone() then
            abandonQuest()
            task.wait(0.4)
            continue
        end

        local targets, locs = questTargets(State.Quest)
        local mobName = targets and targets[1]
        if not mobName then continue end

        local mob = findEnemy(mobName)
        if mob then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            if hrp and dist(hrp.Position) > 8 then tweenTo(hrp.Position) end
        elseif locs and #locs > 0 then
            tweenTo(locs[math.random(#locs)])
        end
    end
end)

--======================= BRING / CHEST / HAKI =======================
task.spawn(function()
    while not Dead do
        task.wait(0.2)
        if not State.BringMobs then continue end
        local r = root()
        if not r then continue end
        for _, m in ipairs(Enemies:GetChildren()) do
            local hrp = m:FindFirstChild("HumanoidRootPart")
            if hrp and dist(hrp.Position) < 250 then
                pcall(function() hrp.CFrame = r.CFrame * CFrame.new(0, 0, 3) end)
            end
        end
    end
end)

task.spawn(function()
    while not Dead do
        task.wait(0.4)
        if not State.AutoChest then continue end
        local best, bestD
        bestD = math.huge
        for _, c in ipairs(CollectionService:GetTagged(ChestTag)) do
            local ok, pos = pcall(function() return c.Position end)
            if ok and pos and not c:GetAttribute("IsDisabled") then
                local d = dist(pos)
                if d < bestD then best, bestD = c, d end
            end
        end
        if best then
            tweenTo(best.Position)
            local r = root()
            if r then
                pcall(function()
                    firetouchinterest(best, r, 0)
                    task.wait()
                    firetouchinterest(best, r, 1)
                end)
            end
        end
    end
end)

task.spawn(function()
    while not Dead do
        task.wait(1)
        if not State.AutoHaki then continue end
        local char = LP.Character
        if char and isAlive(char) and not char:FindFirstChild("HasBuso") then
            inv("Buso")
        end
    end
end)

--======================= NOCLIP =======================
RunService.Stepped:Connect(function()
    if Dead or not State.Noclip then return end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

LP.CharacterAdded:Connect(function()
    if State.Noclip then return end
    task.wait(1)
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end)

--======================= DADOS DE LOJA =======================
local SWORDS = {"Katana", "Cutlass", "Dual Katana", "Iron Mace", "Triple Katana", "Pipe",
                "Dual-Headed Blade", "Soul Cane", "Bisento", "Oroshi", "Saishi", "Shizu"}
local GUNS   = {"Musket", "Slingshot", "Flintlock", "Refined Slingshot", "Dual Flintlock", "Cannon"}
local ACCS   = {"Black Cape", "Swordsman Hat", "Tomoe Ring"}
local STYLES = {["Black Leg"] = "BuyBlackLeg", ["Electro"] = "BuyElectro",
                ["Fishman Karate"] = "BuyFishmanKarate", ["Superhuman"] = "BuySuperhuman",
                ["Death Step"] = "BuyDeathStep", ["Sharkman Karate"] = "BuySharkmanKarate",
                ["Electric Claw"] = "BuyElectricClaw", ["Dragon Talon"] = "BuyDragonTalon",
                ["Godhuman"] = "BuyGodhuman", ["Sanguine Art"] = "BuySanguineArt"}
local HAKIS  = {["Geppo"] = "Geppo", ["Buso"] = "Buso", ["Soru"] = "Soru"}

local BOSSES = {
    ["The Gorilla King"] = {-1128, 6, -451}, ["Chef"] = {-1131, 14, 4080},
    ["Yeti"] = {1185, 106, -1518}, ["Vice Admiral"] = {-4807, 21, 4360},
    ["Warden"] = {5230, 4, 749}, ["Chief Warden"] = {5230, 4, 749}, ["Swan"] = {5230, 4, 749},
    ["Magma Admiral"] = {-5694, 18, 8735}, ["Fishman Lord"] = {61350, 31, 1095},
    ["Wysper"] = {-7927, 5551, -637}, ["Thunder God"] = {-7751, 5607, -2315},
    ["Cyborg"] = {6138, 10, 3939}, ["Diamond"] = {-1569, 199, -31},
    ["Jeremy"] = {2316, 449, 787}, ["Orbitus"] = {-2086, 73, -4208},
    ["Smoke Admiral"] = {-5078, 24, -5352}, ["Awakened Ice Admiral"] = {6473, 297, -6944},
    ["Tide Keeper"] = {-3711, 77, -11469}, ["Stone"] = {-1049, 40, 6791},
    ["Hydra Leader"] = {5836, 1019, -83}, ["Kilo Admiral"] = {2904, 509, -7349},
    ["Captain Elephant"] = {-13393, 319, -8423}, ["Beautiful Pirate"] = {5370, 22, -89},
    ["Cake Queen"] = {-710, 382, -11150},
}

--======================= ABAS =======================
local farmTab = Window:MakeTab({ Name = "Farm", Icon = "seedling", PremiumOnly = false })

farmTab:AddToggle({ Name = "Auto Farm (quest)", Default = false, Flag = "AutoFarm",
    Callback = function(v)
        State.AutoFarm = v
        if not v then abandonQuest() end
    end })

farmTab:AddToggle({ Name = "Bring Mobs", Default = false, Flag = "BringMobs",
    Callback = function(v) State.BringMobs = v end })

farmTab:AddToggle({ Name = "Auto Chest", Default = false, Flag = "AutoChest",
    Callback = function(v) State.AutoChest = v end })

farmTab:AddToggle({ Name = "Auto Buso", Default = false, Flag = "AutoHaki",
    Callback = function(v) State.AutoHaki = v end })

local auraTab = Window:MakeTab({ Name = "Kill Aura", Icon = "sword", PremiumOnly = false })

auraTab:AddToggle({ Name = "Ativar", Default = false, Flag = "KillAura",
    Callback = function(v) State.KillAura = v end })

auraTab:AddSlider({ Name = "Alcance", Min = 30, Max = 400, Default = 120,
    Callback = function(v) State.AuraRange = v end })

auraTab:AddToggle({ Name = "Atacar mobs", Default = true, Flag = "AtkMobs",
    Callback = function(v) State.AttackMobs = v end })

auraTab:AddToggle({ Name = "Atacar jogadores", Default = true, Flag = "AtkPl",
    Callback = function(v) State.AttackPl = v end })

local espTab = Window:MakeTab({ Name = "ESP", Icon = "eye", PremiumOnly = false })

espTab:AddToggle({ Name = "Ativar", Default = false, Flag = "Esp",
    Callback = function(v)
        State.Esp = v
        if not v then clearEsp() end
    end })

espTab:AddToggle({ Name = "Mostrar distancia", Default = true, Flag = "EspDist",
    Callback = function(v) State.EspDist = v end })

local moveTab = Window:MakeTab({ Name = "Movimento", Icon = "wind", PremiumOnly = false })

moveTab:AddSlider({ Name = "Tween Speed", Min = 100, Max = 500, Default = 300,
    Callback = function(v) State.TweenSpeed = v end })

moveTab:AddToggle({ Name = "Noclip", Default = false, Flag = "Noclip",
    Callback = function(v) State.Noclip = v end })

local shopTab = Window:MakeTab({ Name = "Loja", Icon = "shopping-cart", PremiumOnly = false })

local function buyBtn(parent, name, cmd)
    parent:AddButton({
        Name = name,
        Callback = function()
            inv(cmd, name)
            notify("Compra enviada: " .. name)
        end,
    })
end

shopTab:AddSection("Espadas")
for _, s in ipairs(SWORDS) do buyBtn(shopTab, s, "BuyItem") end
shopTab:AddSection("Guns")
for _, g in ipairs(GUNS) do buyBtn(shopTab, g, "BuyItem") end
shopTab:AddSection("Acessorios")
for _, a in ipairs(ACCS) do buyBtn(shopTab, a, "BuyItem") end
shopTab:AddSection("Estilos")
for name, cmd in pairs(STYLES) do
    shopTab:AddButton({ Name = name, Callback = function() inv(cmd) notify("Estilo: " .. name) end })
end
shopTab:AddSection("Haki")
for name, arg in pairs(HAKIS) do
    shopTab:AddButton({ Name = name, Callback = function() inv("BuyHaki", arg) notify("Haki: " .. name) end })
end
shopTab:AddButton({ Name = "Ken (Observation)", Callback = function() inv("KenTalk", "Buy") notify("Ken enviado") end })

local questTab = Window:MakeTab({ Name = "Quests", Icon = "scroll", PremiumOnly = false })

local questNames, selectedQuest = {}, nil
for _, q in ipairs(questList()) do
    table.insert(questNames, string.format("[%d] %s", q.Level, q.Name))
end

questTab:AddDropdown({
    Name = "Quest",
    Options = questNames,
    Default = questNames[1],
    Callback = function(v)
        for _, q in ipairs(questList()) do
            if string.format("[%d] %s", q.Level, q.Name) == v then selectedQuest = q break end
        end
    end,
})

questTab:AddButton({ Name = "Iniciar quest", Callback = function()
    if not selectedQuest then return notify("Selecione uma quest") end
    startQuest(selectedQuest)
    notify("Quest iniciada: " .. selectedQuest.Name)
end })

questTab:AddButton({ Name = "Abandonar quest", Callback = function() abandonQuest() notify("Abandonada") end })

local spTab = Window:MakeTab({ Name = "Especiais", Icon = "star", PremiumOnly = false })

spTab:AddButton({ Name = "Saber (Pro Quest)", Description = "RichSon -> SickMan -> Saber Expert",
    Callback = function()
        inv("ProQuestProgress", "RichSon")
        task.wait(0.5)
        inv("ProQuestProgress", "SickMan")
        notify("Progresso enviado. Mate o Saber Expert e compre o Saber.")
    end })

spTab:AddButton({ Name = "Bartilo (Race V2)", Description = "50 Swan Pirate + Jeremy",
    Callback = function() inv("BartiloQuestProgress", "Bartilo") notify("Progresso enviado") end })

spTab:AddButton({ Name = "Citizen (Ken V2)", Callback = function() inv("CitizenQuestProgress", "Citizen") notify("Progresso enviado") end })

spTab:AddButton({ Name = "Rainbow Haki", Description = "Horned Man, Lv.1950",
    Callback = function() inv("BuyHaki", "Rainbow") notify("Rainbow enviado") end })

spTab:AddButton({ Name = "Craftar TTK", Description = "Saishi + Oroshi + Shizu, 300 mastery, 2M",
    Callback = function()
        inv("CraftSword", "True Triple Katana")
        task.wait(0.6)
        inv("CraftSword", "TrueTripleKatana")
        notify("Craft TTK enviado")
    end })

spTab:AddSection("Boss")
local bossNames = {}
for name in pairs(BOSSES) do table.insert(bossNames, name) end
table.sort(bossNames)
local bossPick
spTab:AddDropdown({ Name = "Boss", Options = bossNames, Default = bossNames[1],
    Callback = function(v) bossPick = v end })
spTab:AddButton({ Name = "Teleportar", Callback = function()
    if bossPick then tweenTo(Vector3.new(unpack(BOSSES[bossPick]))) end
end })
spTab:AddButton({ Name = "Ir para " .. SEA_NAME, Callback = function() inv("Travel" .. SEA_NAME) end })

--======================= DIAGNOSTICO =======================
local miscTab = Window:MakeTab({ Name = "Misc", Icon = "cog", PremiumOnly = false })

miscTab:AddButton({ Name = "Diagnostico", Callback = function()
    local out = {
        "Net: " .. tostring(Net),
        "RegisterAttack: " .. tostring(RegisterAttack),
        "RegisterHit: " .. tostring(RegisterHit),
        "ShootGunEvent: " .. tostring(ShootGunEvent),
        "CommF_: " .. tostring(CommF_),
        "Quests module: " .. tostring(QuestsModule),
        "Guide module: " .. tostring(GuideModule),
        "Quests carregadas: " .. tostring(#questList()),
    }
    print("===== GG BLOX DIAG =====")
    for _, l in ipairs(out) do print(l) end
    notify("Diagnostico no console")
end })

miscTab:AddButton({ Name = "Unload", Callback = function()
    Dead = true
    clearEsp()
    pcall(function() Library:Destroy() end)
end })

task.spawn(function()
    while not Dead do
        task.wait(5)
        if sethiddenproperty then pcall(sethiddenproperty, LP, "SimulationRadius", math.huge) end
    end
end)

notify("GG Blox v0.1 carregado. Sea " .. SEA .. ".")
