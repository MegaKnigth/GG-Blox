--[[
  Abas: Info | Farm | Farm Settings | Stats | ESP | Teleport | Shop | Misc
  Farm core = gghub | extras = Banana | Redeem = Remotes.Redeem
]]

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.5)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local StatsService      = game:GetService("Stats")

local plr = Players.LocalPlayer
local Root, Character, Humanoid

local function RefreshChar(c)
    Character = c
    Humanoid  = c:WaitForChild("Humanoid")
    Root      = c:WaitForChild("HumanoidRootPart")
end
if plr.Character then RefreshChar(plr.Character) end
plr.CharacterAdded:Connect(RefreshChar)

local replicated = ReplicatedStorage
local Enemies    = workspace:WaitForChild("Enemies")
local Net        = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

World1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
World2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
World3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089
local CurrentSea = World1 and 1 or World2 and 2 or World3 and 3 or 1

pcall(function() replicated.Remotes.CommF_:InvokeServer("SetTeam", "Pirates") end)
pcall(function() require(replicated.Util.CameraShaker):Stop() end)

Sec = 0.1
shouldTween = false
_G.Level = false
_G.Seriality = false
_G.SelectWeapon = "Melee"
_G.AutoFarmNear = false
_G.AutoFarmChest = false
_G.AutoCollectFruit = false
_G.AutoStoreFruit = false
_G.AutoStats = false
_G.FarmBoss = false
_G.FindBoss = "The Gorilla King"
_G.AutoBuso = true
_G.AntiAFK = true
_G.InfiniteJump = false
_G.FPSBoost = false
_G.FarmDistance = 30
_B = true
PosMon = Vector3.zero
_G.StatsMap = {Melee=true, Defense=true, Sword=false, Gun=false, ["Demon Fruit"]=false}
_G.StatChunk = 3

PlayerEsp, IslandESP, DevilFruitESP, ChestESP = false, false, false, false
local EspNumber = math.random(1, 1000000)

-- ====================== TWEEN ======================
local block = Instance.new("Part")
block.Size = Vector3.new(1,1,1)
block.Name = "Rip_Indra"
block.Anchored = true
block.CanCollide = false
block.CanTouch = false
block.Transparency = 1
block.Parent = workspace
do
    local old = workspace:FindFirstChild(block.Name)
    if old and old \~= block then old:Destroy() end
end

task.spawn(function()
    while task.wait() do
        getgenv().OnFarm = (block and block.Parent == workspace and shouldTween) and true or false
    end
end)

task.spawn(function()
    repeat task.wait() until plr.Character and plr.Character.PrimaryPart
    block.CFrame = plr.Character.PrimaryPart.CFrame
    while task.wait() do
        pcall(function()
            if getgenv().OnFarm and block and block.Parent == workspace then
                local pp = plr.Character and plr.Character.PrimaryPart
                if pp then
                    if (pp.Position - block.Position).Magnitude <= 200 then
                        pp.CFrame = block.CFrame
                    else
                        block.CFrame = pp.CFrame
                    end
                end
                if plr.Character then
                    for _, e in pairs(plr.Character:GetChildren()) do
                        if e:IsA("BasePart") then e.CanCollide = false end
                    end
                end
            end
        end)
    end
end)

local function AnyFarm()
    return _G.Level or _G.AutoFarmNear or _G.AutoFarmChest or _G.AutoCollectFruit or _G.FarmBoss
end

task.spawn(function()
    while task.wait() do
        pcall(function()
            if AnyFarm() then
                shouldTween = true
                if Root and not Root:FindFirstChild("BodyClip") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "BodyClip"
                    bv.MaxForce = Vector3.new(100000,100000,100000)
                    bv.Velocity = Vector3.zero
                    bv.Parent = Root
                end
                if Character then
                    for _, n in pairs(Character:GetDescendants()) do
                        if n:IsA("BasePart") then n.CanCollide = false end
                    end
                end
            else
                shouldTween = false
                if Root and Root:FindFirstChild("BodyClip") then Root.BodyClip:Destroy() end
            end
        end)
    end
end)

_tp = function(target)
    local character = plr.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart
    local distance = (target.Position - rootPart.Position).Magnitude
    local tween = TweenService:Create(block, TweenInfo.new(distance / 300, Enum.EasingStyle.Linear), {CFrame = target})
    if character.Humanoid.Sit then
        block.CFrame = CFrame.new(block.Position.X, target.Y, block.Position.Z)
    end
    tween:Play()
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not shouldTween then tween:Cancel(); break end
            task.wait(0.1)
        end
    end)
end

notween = function(p)
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        plr.Character.HumanoidRootPart.CFrame = p
    end
end

-- ====================== COMBAT ======================
EquipWeapon = function(text)
    if not text then return end
    if plr.Backpack:FindFirstChild(text) then
        plr.Character.Humanoid:EquipTool(plr.Backpack:FindFirstChild(text))
    end
end

weaponSc = function(weapon)
    for _, v in pairs(plr.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == weapon then EquipWeapon(v.Name) end
    end
end

BringEnemy = function()
    if not _B then return end
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v.PrimaryPart then
            if (v.PrimaryPart.Position - PosMon).Magnitude <= 300 then
                v.PrimaryPart.CFrame = CFrame.new(PosMon)
                v.PrimaryPart.CanCollide = true
                v.Humanoid.WalkSpeed = 0
                v.Humanoid.JumpPower = 0
                if v.Humanoid:FindFirstChild("Animator") then v.Humanoid.Animator:Destroy() end
                plr.SimulationRadius = math.huge
            end
        end
    end
end

Attack = {}
Attack.Alive = function(m)
    local h = m and m:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

Attack.Kill = function(model, Succes)
    if model and Succes and model:FindFirstChild("HumanoidRootPart") then
        if not model:GetAttribute("Locked") then
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame)
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        weaponSc(_G.SelectWeapon)
        local eq = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
        local tip = eq and eq.ToolTip
        local y = _G.FarmDistance or 30
        if tip == "Blox Fruit" then
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0) * CFrame.Angles(0, math.rad(90), 0))
        else
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, y, 0) * CFrame.Angles(0, math.rad(180), 0))
        end
    end
end

local function GetEnemiesInRange(character, range)
    local targets, pos = {}, character:GetPivot().Position
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 and (hrp.Position - pos).Magnitude <= range then
            table.insert(targets, enemy)
        end
    end
    return targets
end

function AttackNoCoolDown()
    local character = plr.Character
    if not character or not character:FindFirstChildOfClass("Tool") then return end
    local list = GetEnemiesInRange(character, 60)
    if #list == 0 then return end
    local targets, mainTarget = {}, nil
    local limbs = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
    for _, enemy in ipairs(list) do
        if not enemy:GetAttribute("IsBoat") then
            local part = enemy:FindFirstChild(limbs[math.random(#limbs)]) or enemy.PrimaryPart
            if part then
                table.insert(targets, {enemy, part})
                mainTarget = part
            end
        end
    end
    if not mainTarget then return end
    RegisterAttack:FireServer(0)
    local hitFn
    if getsenv then
        local ls = plr:FindFirstChild("PlayerScripts") and plr.PlayerScripts:FindFirstChildOfClass("LocalScript")
        if ls then
            local ok, env = pcall(getsenv, ls)
            if ok and env and env._G then hitFn = env._G.SendHitsToServer end
        end
    end
    local okF, thread = pcall(function() return require(replicated.Modules.Flags).COMBAT_REMOTE_THREAD end)
    if okF and thread and hitFn then hitFn(mainTarget, targets)
    else RegisterHit:FireServer(mainTarget, targets) end
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.Seriality then return end
        AttackNoCoolDown()
        local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == "Blox Fruit" then
            local lcr = tool:FindFirstChild("LeftClickRemote")
            if lcr then
                lcr:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                lcr:FireServer(false)
            end
        end
    end)
end)

-- ====================== QUEST LEVEL ======================
local Mon, Qdata, Qname, NameMon, PosM, PosQ

local function QuestCheck()
    local a = plr.Data.Level.Value
    if World1 then
        if a <= 9 then Mon,Qdata,Qname,NameMon="Bandit",1,"BanditQuest1","Bandit"; PosQ=CFrame.new(1059.37,15.45,1550.42); PosM=CFrame.new(1045.96,27,1560.82)
        elseif a <= 14 then Mon,Qdata,Qname,NameMon="Monkey",1,"JungleQuest","Monkey"; PosQ=CFrame.new(-1598.09,35.55,153.38); PosM=CFrame.new(-1448.52,67.85,11.47)
        elseif a <= 29 then Mon,Qdata,Qname,NameMon="Gorilla",2,"JungleQuest","Gorilla"; PosQ=CFrame.new(-1598.09,35.55,153.38); PosM=CFrame.new(-1129.88,40.46,-525.42)
        elseif a <= 39 then Mon,Qdata,Qname,NameMon="Pirate",1,"BuggyQuest1","Pirate"; PosQ=CFrame.new(-1141.07,4.1,3831.55); PosM=CFrame.new(-1103.51,13.75,3896.09)
        elseif a <= 59 then Mon,Qdata,Qname,NameMon="Brute",2,"BuggyQuest1","Brute"; PosQ=CFrame.new(-1141.07,4.1,3831.55); PosM=CFrame.new(-1140.08,14.81,4322.92)
        elseif a <= 74 then Mon,Qdata,Qname,NameMon="Desert Bandit",1,"DesertQuest","Desert Bandit"; PosQ=CFrame.new(894.49,5.14,4392.43); PosM=CFrame.new(924.8,6.45,4481.59)
        elseif a <= 89 then Mon,Qdata,Qname,NameMon="Desert Officer",2,"DesertQuest","Desert Officer"; PosQ=CFrame.new(894.49,5.14,4392.43); PosM=CFrame.new(1608.28,8.61,4371.01)
        elseif a <= 99 then Mon,Qdata,Qname,NameMon="Snow Bandit",1,"SnowQuest","Snow Bandit"; PosQ=CFrame.new(1389.74,88.15,-1298.91); PosM=CFrame.new(1354.35,87.27,-1393.95)
        elseif a <= 119 then Mon,Qdata,Qname,NameMon="Snowman",2,"SnowQuest","Snowman"; PosQ=CFrame.new(1389.74,88.15,-1298.91); PosM=CFrame.new(1201.64,144.58,-1550.07)
        elseif a <= 149 then Mon,Qdata,Qname,NameMon="Chief Petty Officer",1,"MarineQuest2","Chief Petty Officer"; PosQ=CFrame.new(-5039.59,27.35,4324.68); PosM=CFrame.new(-4881.23,22.65,4273.75)
        else Mon,Qdata,Qname,NameMon="Sky Bandit",1,"SkyQuest","Sky Bandit"; PosQ=CFrame.new(-4839.53,716.37,-2619.44); PosM=CFrame.new(-4953.21,295.74,-2899.23)
        end
    elseif World2 then
        if a <= 724 then Mon,Qdata,Qname,NameMon="Raider",1,"Area1Quest","Raider"; PosQ=CFrame.new(-429.54,71.77,1836.18); PosM=CFrame.new(-728.33,52.78,2345.77)
        elseif a <= 774 then Mon,Qdata,Qname,NameMon="Mercenary",2,"Area1Quest","Mercenary"; PosQ=CFrame.new(-429.54,71.77,1836.18); PosM=CFrame.new(-1004.32,80.16,1424.62)
        else Mon,Qdata,Qname,NameMon="Swan Pirate",1,"Area2Quest","Swan Pirate"; PosQ=CFrame.new(638.44,71.77,918.28); PosM=CFrame.new(1068.66,137.61,1322)
        end
    else
        Mon,Qdata,Qname,NameMon="Pirate Millionaire",1,"PiratePortQuest","Pirate Millionaire"; PosQ=CFrame.new(-450,84,5660); PosM=CFrame.new(-712.83,98.58,5711.95)
    end
end

QuestNeta = function()
    QuestCheck()
    return {[1]=Mon,[2]=Qdata,[3]=Qname,[4]=PosM,[5]=NameMon,[6]=PosQ}
end

spawn(function()
    while wait(Sec) do
        if _G.Level then
            pcall(function()
                local QuestTitle = plr.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
                if not string.find(QuestTitle, QuestNeta()[5]) then
                    replicated.Remotes.CommF_:InvokeServer("AbandonQuest")
                end
                if plr.PlayerGui.Main.Quest.Visible == false then
                    _tp(QuestNeta()[6])
                    if (Root.Position - QuestNeta()[6].Position).Magnitude <= 5 then
                        replicated.Remotes.CommF_:InvokeServer("StartQuest", QuestNeta()[3], QuestNeta()[2])
                    end
                elseif plr.PlayerGui.Main.Quest.Visible == true then
                    if workspace.Enemies:FindFirstChild(QuestNeta()[1]) then
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if Attack.Alive(v) and v.Name == QuestNeta()[1] then
                                if string.find(QuestTitle, QuestNeta()[5]) then
                                    repeat wait()
                                        Attack.Kill(v, _G.Level)
                                        _G.Seriality = true
                                    until not _G.Level or v.Humanoid.Health <= 0 or not v.Parent or plr.PlayerGui.Main.Quest.Visible == false
                                    _G.Seriality = false
                                else
                                    replicated.Remotes.CommF_:InvokeServer("AbandonQuest")
                                end
                            end
                        end
                    else
                        _tp(QuestNeta()[4])
                        if replicated:FindFirstChild(QuestNeta()[1]) then
                            _tp(replicated:FindFirstChild(QuestNeta()[1]).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
                        end
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while wait(Sec) do
        if not _G.AutoFarmNear then continue end
        pcall(function()
            for _, v in pairs(workspace.Enemies:GetChildren()) do
                if Attack.Alive(v) and v:FindFirstChild("HumanoidRootPart") then
                    repeat wait()
                        Attack.Kill(v, _G.AutoFarmNear)
                        _G.Seriality = true
                    until not _G.AutoFarmNear or not v.Parent or v.Humanoid.Health <= 0
                    _G.Seriality = false
                end
            end
        end)
    end
end)

-- ====================== BOSS FARM ======================
local BossData = {
    [1] = {
        {Name="The Gorilla King", CF=CFrame.new(-1088.76,8.13,-488.56)},
        {Name="Bobby", CF=CFrame.new(-1087.38,46.95,4040.15)},
        {Name="The Saw", CF=CFrame.new(-784.9,72.43,1603.58)},
        {Name="Yeti", CF=CFrame.new(1218.8,138,-1488.03)},
        {Name="Mob Leader", CF=CFrame.new(-2844.73,7.42,5356.67)},
        {Name="Vice Admiral", CF=CFrame.new(-5006.55,88,4353.16)},
        {Name="Warden", CF=CFrame.new(5278.05,2.15,944.1)},
        {Name="Chief Warden", CF=CFrame.new(5206.93,1,814.98)},
        {Name="Swan", CF=CFrame.new(5325.1,7.04,719.57)},
        {Name="Magma Admiral", CF=CFrame.new(-5765.9,82.92,8718.3)},
        {Name="Fishman Lord", CF=CFrame.new(61350.15,31,1150)},
        {Name="Wysper", CF=CFrame.new(-7866.13,5576.43,-546.75)},
        {Name="Thunder God", CF=CFrame.new(-7994.98,5761.03,-2088.65)},
        {Name="Cyborg", CF=CFrame.new(6041.02,52.92,850.73)},
        {Name="Saber Expert", CF=CFrame.new(-1458.9,29.89,-50.63)},
    },
    [2] = {
        {Name="Diamond", CF=CFrame.new(-1576,198,-266)},
        {Name="Jeremy", CF=CFrame.new(2292,448,715)},
        {Name="Fajita", CF=CFrame.new(-2153,92,-6765)},
        {Name="Don Swan", CF=CFrame.new(2285,15,905)},
        {Name="Smoke Admiral", CF=CFrame.new(-5076,23,-8420)},
        {Name="Awakened Ice Admiral", CF=CFrame.new(6407,204,-7050)},
        {Name="Tide Keeper", CF=CFrame.new(-3713,50,-11469)},
        {Name="Darkbeard", CF=CFrame.new(3677,63,-3145)},
        {Name="Cursed Captain", CF=CFrame.new(917,181,33422)},
        {Name="Order", CF=CFrame.new(-6217,28,-5053)},
    },
    [3] = {
        {Name="Stone", CF=CFrame.new(-1028,92,6579)},
        {Name="Hydra Leader", CF=CFrame.new(5822,1019,-74)},
        {Name="Kilo Admiral", CF=CFrame.new(2764,432,-7144)},
        {Name="Captain Elephant", CF=CFrame.new(-13377,433,-8071)},
        {Name="Beautiful Pirate", CF=CFrame.new(5310,23,-110)},
        {Name="Cake Queen", CF=CFrame.new(-679,381,-11114)},
        {Name="Longma", CF=CFrame.new(-10239,390,-9550)},
        {Name="Soul Reaper", CF=CFrame.new(-9525,316,6656)},
        {Name="rip_indra True Form", CF=CFrame.new(-5345,424,-2720)},
        {Name="Dough King", CF=CFrame.new(-2151,149,-15200)},
    },
}
local seaBosses = BossData[CurrentSea] or BossData[1]
local seaBossNames, seaBossCF = {}, {}
for _, b in ipairs(seaBosses) do
    table.insert(seaBossNames, b.Name)
    seaBossCF[b.Name] = b.CF
end
_G.FindBoss = seaBossNames[1] or "The Gorilla King"

spawn(function()
    while wait(Sec) do
        if not _G.FarmBoss then continue end
        pcall(function()
            local name = _G.FindBoss
            local target = workspace.Enemies:FindFirstChild(name) or replicated:FindFirstChild(name)
            if target and Attack.Alive(target) and target:FindFirstChild("HumanoidRootPart") then
                repeat wait()
                    Attack.Kill(target, _G.FarmBoss)
                    _G.Seriality = true
                until not _G.FarmBoss or not target.Parent or target.Humanoid.Health <= 0
                _G.Seriality = false
            else
                local cf = seaBossCF[name]
                if cf then _tp(cf) end
            end
        end)
    end
end)

-- ====================== FRUIT / CHEST / STATS ======================
UpdStFruit = function()
    for _, v1 in pairs(plr.Backpack:GetChildren()) do
        local sf = v1:FindFirstChild("EatRemote", true)
        if sf then
            pcall(function()
                replicated.Remotes.CommF_:InvokeServer("StoreFruit", sf.Parent:GetAttribute("OriginalName"), plr.Backpack:FindFirstChild(v1.Name))
            end)
        end
    end
end

collectFruits = function(on)
    if not on or not Root then return end
    for _, child in pairs(workspace:GetChildren()) do
        if string.find(child.Name, "Fruit") and child:FindFirstChild("Handle") then
            child.Handle.CFrame = Root.CFrame
        end
    end
end

spawn(function()
    while wait(0.4) do
        if _G.AutoCollectFruit then collectFruits(true) end
        if _G.AutoStoreFruit then UpdStFruit() end
    end
end)

spawn(function()
    while wait(0.35) do
        if not _G.AutoFarmChest or not Root then continue end
        pcall(function()
            local nearest, dist = nil, math.huge
            local chests = {}
            pcall(function() chests = CollectionService:GetTagged("_ChestTagged") end)
            if #chests == 0 then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name, "Chest") then table.insert(chests, obj) end
                end
            end
            for _, chest in ipairs(chests) do
                local pos = chest:IsA("Model") and chest:GetPivot().Position or chest.Position
                local d = (pos - Root.Position).Magnitude
                if d < dist and not chest:GetAttribute("IsDisabled") then nearest, dist = chest, d end
            end
            if nearest then
                local cf = nearest:IsA("Model") and nearest:GetPivot() or nearest.CFrame
                _tp(cf * CFrame.new(0, 2, 0))
                if dist <= 12 then
                    local part = nearest:IsA("Model") and (nearest.PrimaryPart or nearest:FindFirstChildWhichIsA("BasePart")) or nearest
                    if part then
                        pcall(function() firetouchinterest(Root, part, 0) end)
                        pcall(function() firetouchinterest(Root, part, 1) end)
                    end
                end
            end
        end)
    end
end)

spawn(function()
    while wait(1.5) do
        if not _G.AutoStats then continue end
        pcall(function()
            local pts = plr.Data.Points.Value
            if pts <= 0 then return end
            local chunk = math.min(pts, _G.StatChunk or 3)
            for stat, en in pairs(_G.StatsMap) do
                if en then
                    replicated.Remotes.CommF_:InvokeServer("AddPoint", stat, chunk)
                    task.wait(0.08)
                end
            end
        end)
    end
end)

spawn(function()
    while wait(5) do
        if _G.AutoBuso and AnyFarm() then
            pcall(function() replicated.Remotes.CommF_:InvokeServer("Buso") end)
        end
    end
end)

-- ====================== ESP ======================
local function DistM(a, b) return math.floor(((a - b).Magnitude / 3) + 0.5) end

EspPly = function()
    for _, v1 in pairs(Players:GetPlayers()) do
        pcall(function()
            if not v1.Character or not v1.Character:FindFirstChild("Head") or not plr.Character or not plr.Character:FindFirstChild("Head") then return end
            local head = v1.Character.Head
            local tag = head:FindFirstChild("NameEsp" .. EspNumber)
            if PlayerEsp and v1 \~= plr then
                local txt = v1.Name .. " | " .. DistM(plr.Character.Head.Position, head.Position) .. " M\nHP " .. math.floor(v1.Character.Humanoid.Health * 100 / v1.Character.Humanoid.MaxHealth) .. "%"
                if tag then tag.TextLabel.Text = txt
                else
                    local bb = Instance.new("BillboardGui", head)
                    bb.Name = "NameEsp" .. EspNumber
                    bb.Size = UDim2.new(1, 200, 1, 30)
                    bb.Adornee = head
                    bb.AlwaysOnTop = true
                    local tl = Instance.new("TextLabel", bb)
                    tl.Font = Enum.Font.Code; tl.TextSize = 14; tl.TextWrapped = true
                    tl.Text = txt; tl.Size = UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency = 1; tl.TextStrokeTransparency = 0.5
                    tl.TextColor3 = (v1.Team == plr.Team) and Color3.fromRGB(0,120,255) or Color3.fromRGB(255,60,60)
                end
            elseif tag then tag:Destroy() end
        end)
    end
end

LocationEsp = function()
    local locs = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if not locs or not Root then return end
    for _, v1 in pairs(locs:GetChildren()) do
        pcall(function()
            if v1.Name == "Sea" then return end
            local tag = v1:FindFirstChild("NameEsp")
            if IslandESP then
                local pos = v1:IsA("BasePart") and v1.Position or v1:GetPivot().Position
                local txt = v1.Name .. "\n" .. DistM(Root.Position, pos) .. " M"
                if tag then tag.TextLabel.Text = txt
                else
                    local bb = Instance.new("BillboardGui", v1)
                    bb.Name = "NameEsp"; bb.Size = UDim2.new(1,200,1,30); bb.Adornee = v1; bb.AlwaysOnTop = true
                    local tl = Instance.new("TextLabel", bb)
                    tl.Font = Enum.Font.Code; tl.TextSize = 14; tl.Text = txt; tl.Size = UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency = 1; tl.TextStrokeTransparency = 0.5
                    tl.TextColor3 = Color3.fromRGB(80,255,120)
                end
            elseif tag then tag:Destroy() end
        end)
    end
end

FruitEsp = function()
    if not Root then return end
    for _, v1 in pairs(workspace:GetChildren()) do
        pcall(function()
            if not string.find(v1.Name, "Fruit") or not v1:FindFirstChild("Handle") then return end
            local handle = v1.Handle
            local tag = handle:FindFirstChild("NameEsp" .. EspNumber)
            if DevilFruitESP then
                local txt = v1.Name .. "\n" .. DistM(Root.Position, handle.Position) .. " M"
                if tag then tag.TextLabel.Text = txt
                else
                    local bb = Instance.new("BillboardGui", handle)
                    bb.Name = "NameEsp" .. EspNumber; bb.Size = UDim2.new(1,200,1,30); bb.Adornee = handle; bb.AlwaysOnTop = true
                    local tl = Instance.new("TextLabel", bb)
                    tl.Font = Enum.Font.Code; tl.TextSize = 14; tl.Text = txt; tl.Size = UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency = 1; tl.TextStrokeTransparency = 0.5
                    tl.TextColor3 = Color3.fromRGB(220,80,255)
                end
            elseif tag then tag:Destroy() end
        end)
    end
end

ChestEspFn = function()
    if not Root then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        pcall(function()
            if not (obj:IsA("BasePart") and string.find(obj.Name, "Chest")) then return end
            local tag = obj:FindFirstChild("NameEsp" .. EspNumber)
            if ChestESP then
                local txt = obj.Name .. "\n" .. DistM(Root.Position, obj.Position) .. " M"
                if tag then tag.TextLabel.Text = txt
                else
                    local bb = Instance.new("BillboardGui", obj)
                    bb.Name = "NameEsp" .. EspNumber; bb.Size = UDim2.new(1,200,1,30); bb.Adornee = obj; bb.AlwaysOnTop = true
                    local tl = Instance.new("TextLabel", bb)
                    tl.Font = Enum.Font.Code; tl.TextSize = 14; tl.Text = txt; tl.Size = UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency = 1; tl.TextStrokeTransparency = 0.5
                    tl.TextColor3 = Color3.fromRGB(255,215,0)
                end
            elseif tag then tag:Destroy() end
        end)
    end
end

spawn(function()
    while wait(1) do
        if PlayerEsp then EspPly() end
        if IslandESP then LocationEsp() end
        if DevilFruitESP then FruitEsp() end
        if ChestESP then ChestEspFn() end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump and Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
plr.Idled:Connect(function()
    if _G.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

-- ====================== ISLANDS / CODES ======================
local IslandMap = {
    [1] = {
        ["Starter Island"]=CFrame.new(1059,15,1550), ["Jungle"]=CFrame.new(-1448,68,11),
        ["Pirate Village"]=CFrame.new(-1141,4,3831), ["Desert"]=CFrame.new(924,6,4481),
        ["Snow Mountain"]=CFrame.new(1354,87,-1393), ["Marine Fortress"]=CFrame.new(-5035,28,4324),
        ["Sky Island"]=CFrame.new(-4842,717,-2623), ["Prison"]=CFrame.new(5310,0,474),
        ["Colosseum"]=CFrame.new(-1577,7,-2984), ["Magma Village"]=CFrame.new(-5316,12,8517),
        ["Underwater City"]=CFrame.new(61122,18,1569), ["Fountain City"]=CFrame.new(5259,37,4050),
    },
    [2] = {
        ["Kingdom of Rose"]=CFrame.new(-429,71,1836), ["Green Zone"]=CFrame.new(638,72,918),
        ["Graveyard"]=CFrame.new(-5497,48,-795), ["Snow Mountain S2"]=CFrame.new(609,401,-5372),
        ["Hot and Cold"]=CFrame.new(1008,125,32911), ["Cursed Ship"]=CFrame.new(923,126,32852),
        ["Forgotten Island"]=CFrame.new(-3054,237,-10145),
    },
    [3] = {
        ["Pirate Port"]=CFrame.new(-289,44,5580), ["Amazon Lily"]=CFrame.new(5832,51,-1100),
        ["Great Tree"]=CFrame.new(2180,28,-6740), ["Haunted Castle"]=CFrame.new(-9515,142,5536),
        ["Candy Island"]=CFrame.new(-1149,13,-14445), ["Tiki Outpost"]=CFrame.new(-16547,55,-172),
        ["Hydra Island"]=CFrame.new(5657,1013,-335), ["Castle on the Sea"]=CFrame.new(-5036,315,-3179),
    },
}
local seaIslands = IslandMap[CurrentSea] or IslandMap[1]
local islandKeys = {}; for k in pairs(seaIslands) do table.insert(islandKeys, k) end; table.sort(islandKeys)
local selIsland = islandKeys[1]

-- Banana codes + Redeem remote correto
local Codes = {
    "LIGHTNINGABUSE","1LOSTADMIN","ADMINFIGHT","GIFTING_HOURS","NOMOREHACK","BANEXPLOIT",
    "WildDares","BossBuild","GetPranked","EARN_FRUITS","SUB2GAMERROBOT_RESET1","KITT_RESET",
    "Bignews","CHANDLER","Fudd10","fudd10_v2","Sub2UncleKizaru","FIGHT4FRUIT","kittgaming",
    "TRIPLEABUSE","Sub2CaptainMaui","Sub2Fer999","Enyu_is_Pro","Magicbus","JCWK","Starcodeheo",
    "Bluxxy","SUB2GAMERROBOT_EXP1","Sub2NoobMaster123","Sub2Daigrock","Axiore","TantaiGaming",
    "StrawHatMaine","Sub2OfficialNoobie","TheGreatAce","JULYUPDATE_RESET","ADMINHACKED",
    "SEATROLLING","24NOADMIN","ADMIN_TROLL","NEWTROLL","SECRET_ADMIN","staffbattle","NOEXPLOIT",
    "NOOB2ADMIN","CODESLIDE","fruitconcepts","krazydares",
}

local function RedeemAllCodes()
    local Redeem = replicated.Remotes:FindFirstChild("Redeem")
    if not Redeem then return false, "Remotes.Redeem não encontrado" end
    local n = 0
    for _, code in ipairs(Codes) do
        pcall(function()
            if Redeem.InvokeServer then Redeem:InvokeServer(code)
            else Redeem:FireServer(code) end
            n += 1
        end)
        task.wait(0.05)
    end
    return true, n
end

-- ====================== INFO HELPERS (Banana) ======================
local function GetMoonText()
    local id = ""
    pcall(function()
        if Lighting:FindFirstChild("Sky") then id = Lighting.Sky.MoonTextureId end
        if World1 or World2 then
            if Lighting:FindFirstChild("FantasySky") then id = Lighting.FantasySky.MoonTextureId end
        end
    end)
    if id == "http://www.roblox.com/asset/?id=9709149431" then return "Moon 5/5 Full ✅"
    elseif id == "http://www.roblox.com/asset/?id=9709149052" then return "Moon 4/5"
    elseif id == "http://www.roblox.com/asset/?id=9709143733" then return "Moon 3/5"
    elseif id == "http://www.roblox.com/asset/?id=9709150401" then return "Moon 2/5"
    elseif id == "http://www.roblox.com/asset/?id=9709149680" then return "Moon 1/5"
    end
    return "Moon 0/5"
end

local function LocHas(name)
    local locs = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if locs and locs:FindFirstChild(name) then return "✅" end
    if workspace.Map and workspace.Map:FindFirstChild(name:gsub(" ", "")) then return "✅" end
    if name == "Kitsune Island" and workspace.Map and workspace.Map:FindFirstChild("KitsuneIsland") then return "✅" end
    return "❌"
end

local function EnemyOrRep(name)
    if workspace.Enemies:FindFirstChild(name) or replicated:FindFirstChild(name) then return "✅" end
    return "❌"
end

local function GetPing()
    local ok, s = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    return ok and s or "?"
end

local function BuildInfoText()
    local lv = plr.Data and plr.Data.Level.Value or "?"
    local beli = plr.Data and plr.Data.Beli and plr.Data.Beli.Value or "?"
    local frag = plr.Data and plr.Data.Fragments and plr.Data.Fragments.Value or "?"
    local race = plr.Data and plr.Data.Race and (plr.Data.Race.C and plr.Data.Race.C.Value or plr.Data.Race.Value) or "?"
    local df = plr.Data and plr.Data.DevilFruit and plr.Data.DevilFruit.Value or "None"
    local gt = math.floor(workspace.DistributedGameTime + 0.5)
    local gh = math.floor(gt/3600)%24
    local gm = math.floor(gt/60)%60
    local gs = gt%60
    return table.concat({
        "Player: "..plr.Name,
        "Level: "..tostring(lv).." | Sea: "..CurrentSea,
        "Beli: "..tostring(beli).." | Fragments: "..tostring(frag),
        "Race: "..tostring(race).." | Fruit: "..tostring(df),
        "Team: "..tostring(plr.Team and plr.Team.Name or "?"),
        "Ping: "..GetPing(),
        "JobId: "..tostring(game.JobId),
        "Players: "..#Players:GetPlayers().."/"..(Players.MaxPlayers or "?"),
        "Server time: "..gh.."h "..gm.."m "..gs.."s",
        GetMoonText(),
        "Mirage: "..LocHas("Mirage Island"),
        "Kitsune: "..LocHas("Kitsune Island"),
        "Prehistoric: "..LocHas("Prehistoric Island"),
        "Cake Prince: "..EnemyOrRep("Cake Prince"),
        "Dough King: "..EnemyOrRep("Dough King"),
        "rip_indra: "..EnemyOrRep("rip_indra True Form"),
    }, "\n")
end

-- ====================== UI ======================
local GGUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"))()
if not GGUI or type(GGUI.MakeWindow) \~= "function" then
    warn("[BF] GG-UI fail"); return
end

local Win = GGUI:MakeWindow({
    Title = "BF Hub",
    SubTitle = "Sea "..CurrentSea.." | Lv."..(plr.Data and plr.Data.Level.Value or "?"),
    ScriptFolder = "BFHubFull"
})

-- 1) INFO
local tInfo = Win:MakeTab({ Title = "Info" })
tInfo:AddSection("Status")
tInfo:AddButton({ Title = "Atualizar Info", Callback = function()
    Win:Notify({ Title = "Info", Content = BuildInfoText(), Duration = 8 })
end })
tInfo:AddButton({ Title = "Copy JobId", Callback = function()
    if setclipboard then setclipboard(tostring(game.JobId)) end
    Win:Notify({ Title = "JobId", Content = tostring(game.JobId), Duration = 3 })
end })
tInfo:AddSection("Eventos")
tInfo:AddButton({ Title = "Checar Mirage / Kitsune / Moon", Callback = function()
    Win:Notify({
        Title = "Eventos",
        Content = GetMoonText().."\nMirage "..LocHas("Mirage Island").."\nKitsune "..LocHas("Kitsune Island").."\nPrehistoric "..LocHas("Prehistoric Island"),
        Duration = 5
    })
end })
tInfo:AddButton({ Title = "Checar Bosses (Cake / Dough / Indra)", Callback = function()
    Win:Notify({
        Title = "Bosses",
        Content = "Cake Prince "..EnemyOrRep("Cake Prince").."\nDough King "..EnemyOrRep("Dough King").."\nrip_indra "..EnemyOrRep("rip_indra True Form"),
        Duration = 5
    })
end })

-- 2) FARM
local tFarm = Win:MakeTab({ Title = "Farm" })
tFarm:AddSection("Level")
tFarm:AddToggle({ Title = "Auto Farm Level", Default = false, Callback = function(v)
    _G.Level = v; if not v then _G.Seriality = false end
end })
tFarm:AddToggle({ Title = "Auto Farm Nearest", Default = false, Callback = function(v)
    _G.AutoFarmNear = v; if not v then _G.Seriality = false end
end })
tFarm:AddSection("Boss")
tFarm:AddDropdown({
    Title = "Select Boss",
    Options = seaBossNames,
    Default = seaBossNames[1],
    Callback = function(v) _G.FindBoss = v end
})
tFarm:AddToggle({ Title = "Auto Farm Boss", Default = false, Callback = function(v)
    _G.FarmBoss = v; if not v then _G.Seriality = false end
end })
tFarm:AddSection("Collect")
tFarm:AddToggle({ Title = "Auto Collect Chest", Default = false, Callback = function(v) _G.AutoFarmChest = v end })
tFarm:AddToggle({ Title = "Auto Collect Fruit", Default = false, Callback = function(v) _G.AutoCollectFruit = v end })
tFarm:AddToggle({ Title = "Auto Store Fruit", Default = false, Callback = function(v) _G.AutoStoreFruit = v end })
tFarm:AddButton({ Title = "Collect Fruits Agora", Callback = function() collectFruits(true) end })
tFarm:AddButton({ Title = "Store Fruits Agora", Callback = function() UpdStFruit() end })

-- 3) FARM SETTINGS
local tFarmSet = Win:MakeTab({ Title = "Farm Settings" })
tFarmSet:AddSection("Combat")
tFarmSet:AddToggle({ Title = "Seriality (Ataque)", Default = true, Callback = function(v) _G.Seriality = v end })
tFarmSet:AddToggle({ Title = "Bring Mobs", Default = true, Callback = function(v) _B = v end })
tFarmSet:AddToggle({ Title = "Auto Buso", Default = true, Callback = function(v) _G.AutoBuso = v end })
tFarmSet:AddDropdown({
    Title = "Arma",
    Options = {"Melee","Sword","Blox Fruit","Gun"},
    Default = "Melee",
    Callback = function(v) _G.SelectWeapon = v; weaponSc(v) end
})
tFarmSet:AddSlider({
    Title = "Altura no mob",
    Min = 5, Max = 60, Default = 30, Increment = 1,
    Callback = function(v) _G.FarmDistance = v end
})
tFarmSet:AddButton({ Title = "Parar todo farm", Callback = function()
    _G.Level=false; _G.AutoFarmNear=false; _G.FarmBoss=false
    _G.AutoFarmChest=false; _G.AutoCollectFruit=false; _G.Seriality=false
    shouldTween=false
end })

-- 4) STATS
local tStats = Win:MakeTab({ Title = "Stats" })
tStats:AddSection("Auto Stats")
tStats:AddToggle({ Title = "Auto Stats", Default = false, Callback = function(v) _G.AutoStats = v end })
tStats:AddSlider({ Title = "Pontos / rodada", Min = 1, Max = 10, Default = 3, Increment = 1,
    Callback = function(v) _G.StatChunk = v end })
for _, s in ipairs({"Melee","Defense","Sword","Gun","Demon Fruit"}) do
    tStats:AddToggle({ Title = s, Default = _G.StatsMap[s] or false,
        Callback = function(v) _G.StatsMap[s] = v end })
end
tStats:AddSection("Manual")
tStats:AddButton({ Title = "+Melee x3", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("AddPoint","Melee",3) end)
end })
tStats:AddButton({ Title = "+Defense x3", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("AddPoint","Defense",3) end)
end })
tStats:AddButton({ Title = "Refund Stats", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("BlackbeardReward","Refund","2") end)
end })

-- 5) ESP
local tESP = Win:MakeTab({ Title = "ESP" })
tESP:AddSection("ESP")
tESP:AddToggle({ Title = "Player ESP", Default = false, Callback = function(v) PlayerEsp = v end })
tESP:AddToggle({ Title = "Island ESP", Default = false, Callback = function(v) IslandESP = v end })
tESP:AddToggle({ Title = "Devil Fruit ESP", Default = false, Callback = function(v) DevilFruitESP = v end })
tESP:AddToggle({ Title = "Chest ESP", Default = false, Callback = function(v) ChestESP = v end })

-- 6) TELEPORT
local tTP = Win:MakeTab({ Title = "Teleport" })
tTP:AddSection("Ilhas — Sea "..CurrentSea)
tTP:AddDropdown({ Title = "Ilha", Options = islandKeys, Default = islandKeys[1],
    Callback = function(v) selIsland = v end })
tTP:AddButton({ Title = "Teleport snap", Callback = function()
    local cf = seaIslands[selIsland]; if cf then notween(cf) end
end })
tTP:AddButton({ Title = "Tween até ilha", Callback = function()
    local cf = seaIslands[selIsland]
    if cf then shouldTween = true; _tp(cf) end
end })
tTP:AddSection("Mares")
tTP:AddButton({ Title = "Sea 1", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("TravelMain") end)
end })
tTP:AddButton({ Title = "Sea 2", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("TravelDressrosa") end)
end })
tTP:AddButton({ Title = "Sea 3", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("TravelZou") end)
end })
tTP:AddSection("Servidor")
tTP:AddButton({ Title = "Server Hop", Callback = function()
    pcall(function()
        local data = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in ipairs(data.data or {}) do
            if s.playing < s.maxPlayers and s.id \~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, plr); break
            end
        end
    end)
end })
tTP:AddButton({ Title = "Rejoin", Callback = function()
    TeleportService:Teleport(game.PlaceId, plr)
end })

-- 7) SHOP (sem codes)
local tShop = Win:MakeTab({ Title = "Shop" })
tShop:AddSection("Haki")
tShop:AddButton({ Title = "Buy Buso", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("BuyHaki","Buso") end)
end })
tShop:AddButton({ Title = "Buy Geppo", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("BuyHaki","Geppo") end)
end })
tShop:AddButton({ Title = "Buy Soru", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("BuyHaki","Soru") end)
end })
tShop:AddButton({ Title = "Buy Ken", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("KenTalk","Buy") end)
end })
tShop:AddSection("Fighting Style")
for _, s in ipairs({
    {"Black Leg","BuyBlackLeg"},{"Electro","BuyElectro"},{"Fishman Karate","BuyFishmanKarate"},
    {"Superhuman","BuySuperhuman"},{"Death Step","BuyDeathStep"},{"Sharkman Karate","BuySharkmanKarate"},
    {"Electric Claw","BuyElectricClaw"},{"Dragon Talon","BuyDragonTalon"},{"Godhuman","BuyGodhuman"},
}) do
    tShop:AddButton({ Title = "Buy "..s[1], Callback = function()
        pcall(function() replicated.Remotes.CommF_:InvokeServer(s[2]) end)
    end })
end
tShop:AddButton({ Title = "Buy Dragon Claw", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("BlackbeardReward","DragonClaw","2") end)
end })
tShop:AddSection("Armas")
for _, w in ipairs({
    "Cutlass","Katana","Iron Mace","Duel Katana","Triple Katana","Pipe",
    "Dual-Headed Blade","Bisento","Soul Cane","Slingshot","Musket",
    "Dual Flintlock","Flintlock","Refined Flintlock","Cannon",
}) do
    tShop:AddButton({ Title = "Buy "..w, Callback = function()
        pcall(function() replicated.Remotes.CommF_:InvokeServer("BuyItem", w) end)
    end })
end
tShop:AddSection("Acessórios / Race")
for _, a in ipairs({"Tomoe Ring","Black Cape","Swordsman Hat"}) do
    tShop:AddButton({ Title = "Buy "..a, Callback = function()
        pcall(function() replicated.Remotes.CommF_:InvokeServer("BuyItem", a) end)
    end })
end
tShop:AddButton({ Title = "Reroll Race", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("BlackbeardReward","Reroll","2") end)
end })
tShop:AddButton({ Title = "Buy Ghoul Race", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("Ectoplasm","Change",4) end)
end })
tShop:AddButton({ Title = "Buy Cyborg Race", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("CyborgTrainer","Buy") end)
end })

-- 8) MISC (codes aqui — remote Redeem correto)
local tMisc = Win:MakeTab({ Title = "Misc" })
tMisc:AddSection("Codes")
tMisc:AddButton({ Title = "Redeem All Codes", Callback = function()
    task.spawn(function()
        local ok, res = RedeemAllCodes()
        if ok then
            Win:Notify({ Title = "Codes", Content = "Enviados: "..tostring(res).." codes (Remotes.Redeem)", Duration = 4 })
        else
            Win:Notify({ Title = "Codes", Content = tostring(res), Duration = 4 })
        end
    end)
end })
tMisc:AddSection("Player")
tMisc:AddToggle({ Title = "Anti-AFK", Default = true, Callback = function(v) _G.AntiAFK = v end })
tMisc:AddToggle({ Title = "Infinite Jump", Default = false, Callback = function(v) _G.InfiniteJump = v end })
tMisc:AddToggle({ Title = "FPS Boost", Default = false, Callback = function(v)
    if v then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, p in ipairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") and not (p.Parent and p.Parent:FindFirstChild("Humanoid")) then
                pcall(function() p.Material = Enum.Material.SmoothPlastic; p.Reflectance = 0 end)
            elseif p:IsA("Decal") or p:IsA("Texture") then
                pcall(function() p.Transparency = 1 end)
            end
        end
    end
end })
tMisc:AddSection("Team")
tMisc:AddButton({ Title = "Set Pirates", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("SetTeam","Pirates") end)
end })
tMisc:AddButton({ Title = "Set Marines", Callback = function()
    pcall(function() replicated.Remotes.CommF_:InvokeServer("SetTeam","Marines") end)
end })
tMisc:AddSection("Util")
tMisc:AddButton({ Title = "Remove Fog", Callback = function()
    pcall(function()
        if Lighting:FindFirstChild("LightingLayers") then Lighting.LightingLayers:Destroy() end
        Lighting.FogEnd = 9e9
    end)
end })

Win:Notify({ Title = "BF Hub", Content = "Info → Farm → Settings → ... | Redeem = Remotes.Redeem", Duration = 4 })
print("[BF Hub] tabs ok | Sea "..CurrentSea)
