

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.8)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")

local LP   = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local Root = Char:WaitForChild("HumanoidRootPart")
local Hum  = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c
    Root = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
end)

-- Team
pcall(function()
    ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
end)

-- Sea
local PlaceId = game.PlaceId
local Sea1 = (PlaceId == 2753915549 or PlaceId == 85211729168715)
local Sea2 = (PlaceId == 4442272183 or PlaceId == 79091703265657)
local Sea3 = (PlaceId == 7449423635 or PlaceId == 100117331123089)
local CurrentSea = Sea1 and 1 or Sea2 and 2 or Sea3 and 3 or 1

-- ====================== STATE ======================
_G.Seriality    = false
_G.AutoLevel    = false
_G.BringMobs    = true
_G.SelectWeapon = "Melee"
local PosMon    = Vector3.zero

-- ====================== REMOTES ======================
local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

-- ====================== UTILS ======================
local function GetHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function EquipWeapon(tip)
    tip = tip or _G.SelectWeapon
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local cur = char:FindFirstChildOfClass("Tool")
    if cur and cur.ToolTip == tip then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == tip then
            hum:EquipTool(t)
            return
        end
    end
end

local function TweenTo(cf)
    local hrp = GetHRP()
    if not hrp then return end
    local dist = (hrp.Position - cf.Position).Magnitude
    if dist < 3 then return end
    local speed = 320
    local tw = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = cf})
    tw:Play()
    tw.Completed:Wait()
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local function NoClip(on)
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = not on
        end
    end
end

-- ====================== BRING ======================
local function BringEnemy()
    if not _G.BringMobs then return end
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end
    for _, v in ipairs(enemies:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        local hrp = v:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            if (hrp.Position - PosMon).Magnitude <= 300 then
                hrp.CFrame = CFrame.new(PosMon)
                hrp.CanCollide = false
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                if hum:FindFirstChild("Animator") then
                    hum.Animator:Destroy()
                end
                pcall(function() LP.SimulationRadius = math.huge end)
            end
        end
    end
end

-- ====================== ATTACK NO COOLDOWN (gghub — intacto) ======================
local function IsEntityAlive(entity)
    if not entity then return false end
    local humanoid = entity:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetEnemiesInRange(character, range)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return {} end
    local targets = {}
    local playerPos = character:GetPivot().Position
    for _, enemy in ipairs(enemies:GetChildren()) do
        local rootPart = enemy:FindFirstChild("HumanoidRootPart")
        if rootPart and IsEntityAlive(enemy) then
            if (rootPart.Position - playerPos).Magnitude <= range then
                table.insert(targets, enemy)
            end
        end
    end
    return targets
end

function AttackNoCoolDown()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character then return end

    local equippedWeapon = nil
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            equippedWeapon = item
            break
        end
    end
    if not equippedWeapon then return end

    local enemiesInRange = GetEnemiesInRange(character, 60)
    if #enemiesInRange == 0 then return end

    local storage = game:GetService("ReplicatedStorage")
    local modules = storage:FindFirstChild("Modules")
    if not modules then return end

    local attackEvent = storage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterAttack")
    local hitEvent    = storage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterHit")
    if not attackEvent or not hitEvent then return end

    local targets, mainTarget = {}, nil
    for _, enemy in ipairs(enemiesInRange) do
        if not enemy:GetAttribute("IsBoat") then
            local HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"}
            local head = enemy:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)]) or enemy.PrimaryPart
            if head then
                table.insert(targets, { enemy, head })
                mainTarget = head
            end
        end
    end
    if not mainTarget then return end

    attackEvent:FireServer(0)

    local playerScripts = player:FindFirstChild("PlayerScripts")
    if not playerScripts then return end
    local localScript = playerScripts:FindFirstChildOfClass("LocalScript")
    while not localScript do
        playerScripts.ChildAdded:Wait()
        localScript = playerScripts:FindFirstChildOfClass("LocalScript")
    end

    local hitFunction
    if getsenv then
        local success, scriptEnv = pcall(getsenv, localScript)
        if success and scriptEnv then
            hitFunction = scriptEnv._G.SendHitsToServer
        end
    end

    local successFlags, combatRemoteThread = pcall(function()
        return require(modules.Flags).COMBAT_REMOTE_THREAD or false
    end)

    if successFlags and combatRemoteThread and hitFunction then
        hitFunction(mainTarget, targets)
    elseif successFlags and not combatRemoteThread then
        hitEvent:FireServer(mainTarget, targets)
    else
        hitEvent:FireServer(mainTarget, targets)
    end
end

-- Heartbeat do ataque
RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.Seriality then return end
        AttackNoCoolDown()

        local Pretool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if Pretool and Pretool.ToolTip == "Blox Fruit" then
            local LeftClickRemote = Pretool:FindFirstChild("LeftClickRemote")
            if LeftClickRemote then
                LeftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                LeftClickRemote:FireServer(false)
            end
        end
    end)
end)

-- Camera shake off
pcall(function()
    local CameraShakerR = require(game.ReplicatedStorage.Util.CameraShaker)
    CameraShakerR:Stop()
end)

-- ====================== CHECK LEVEL ======================
local function CheckLevel()
    local lv = LP.Data.Level.Value
    local Ms, NameQuest, QuestLv, CFrameQ, CFrameMon

    if Sea1 then
        if lv <= 9 then
            Ms, NameQuest, QuestLv = "Bandit", "BanditQuest1", 1
            CFrameQ = CFrame.new(1060.9, 16.45, 1547.78)
            CFrameMon = CFrame.new(1038.55, 41.3, 1576.51)
        elseif lv <= 14 then
            Ms, NameQuest, QuestLv = "Monkey", "JungleQuest", 1
            CFrameQ = CFrame.new(-1601.65, 36.85, 153.39)
            CFrameMon = CFrame.new(-1448.14, 50.85, 63.61)
        elseif lv <= 29 then
            Ms, NameQuest, QuestLv = "Gorilla", "JungleQuest", 2
            CFrameQ = CFrame.new(-1601.65, 36.85, 153.39)
            CFrameMon = CFrame.new(-1142.65, 40.46, -515.39)
        elseif lv <= 39 then
            Ms, NameQuest, QuestLv = "Pirate", "BuggyQuest1", 1
            CFrameQ = CFrame.new(-1140.18, 4.75, 3827.41)
            CFrameMon = CFrame.new(-1201.09, 40.63, 3857.60)
        elseif lv <= 59 then
            Ms, NameQuest, QuestLv = "Brute", "BuggyQuest1", 2
            CFrameQ = CFrame.new(-1140.18, 4.75, 3827.41)
            CFrameMon = CFrame.new(-1387.53, 24.59, 4100.96)
        elseif lv <= 74 then
            Ms, NameQuest, QuestLv = "Desert Bandit", "DesertQuest", 1
            CFrameQ = CFrame.new(896.52, 6.44, 4390.15)
            CFrameMon = CFrame.new(984.99, 16.11, 4417.91)
        elseif lv <= 89 then
            Ms, NameQuest, QuestLv = "Desert Officer", "DesertQuest", 2
            CFrameQ = CFrame.new(896.52, 6.44, 4390.15)
            CFrameMon = CFrame.new(1547.15, 14.45, 4381.80)
        elseif lv <= 99 then
            Ms, NameQuest, QuestLv = "Snow Bandit", "SnowQuest", 1
            CFrameQ = CFrame.new(1386.81, 87.27, -1298.36)
            CFrameMon = CFrame.new(1356.30, 105.77, -1328.24)
        elseif lv <= 119 then
            Ms, NameQuest, QuestLv = "Snowman", "SnowQuest", 2
            CFrameQ = CFrame.new(1386.81, 87.27, -1298.36)
            CFrameMon = CFrame.new(1218.80, 138.01, -1488.03)
        elseif lv <= 149 then
            Ms, NameQuest, QuestLv = "Chief Petty Officer", "MarineQuest2", 1
            CFrameQ = CFrame.new(-5035.50, 28.68, 4324.18)
            CFrameMon = CFrame.new(-4931.16, 65.79, 4121.84)
        elseif lv <= 174 then
            Ms, NameQuest, QuestLv = "Sky Bandit", "SkyQuest", 1
            CFrameQ = CFrame.new(-4842.14, 717.70, -2623.05)
            CFrameMon = CFrame.new(-4955.64, 365.46, -2908.19)
        elseif lv <= 189 then
            Ms, NameQuest, QuestLv = "Dark Master", "SkyQuest", 2
            CFrameQ = CFrame.new(-4842.14, 717.70, -2623.05)
            CFrameMon = CFrame.new(-5148.17, 439.05, -2332.96)
        elseif lv <= 209 then
            Ms, NameQuest, QuestLv = "Prisoner", "PrisonerQuest", 1
            CFrameQ = CFrame.new(5310.61, 0.35, 474.95)
            CFrameMon = CFrame.new(4937.32, 0.33, 649.57)
        elseif lv <= 249 then
            Ms, NameQuest, QuestLv = "Dangerous Prisoner", "PrisonerQuest", 2
            CFrameQ = CFrame.new(5310.61, 0.35, 474.95)
            CFrameMon = CFrame.new(5099.66, 0.35, 1055.76)
        elseif lv <= 274 then
            Ms, NameQuest, QuestLv = "Toga Warrior", "ColosseumQuest", 1
            CFrameQ = CFrame.new(-1577.79, 7.42, -2984.48)
            CFrameMon = CFrame.new(-1872.52, 49.08, -2913.81)
        elseif lv <= 299 then
            Ms, NameQuest, QuestLv = "Gladiator", "ColosseumQuest", 2
            CFrameQ = CFrame.new(-1577.79, 7.42, -2984.48)
            CFrameMon = CFrame.new(-1521.37, 81.20, -3066.31)
        elseif lv <= 324 then
            Ms, NameQuest, QuestLv = "Military Soldier", "MagmaQuest", 1
            CFrameQ = CFrame.new(-5316.12, 12.26, 8517.00)
            CFrameMon = CFrame.new(-5369.00, 61.24, 8556.49)
        elseif lv <= 374 then
            Ms, NameQuest, QuestLv = "Military Spy", "MagmaQuest", 2
            CFrameQ = CFrame.new(-5316.12, 12.26, 8517.00)
            CFrameMon = CFrame.new(-5787.00, 75.83, 8651.70)
        elseif lv <= 399 then
            Ms, NameQuest, QuestLv = "Fishman Warrior", "FishmanQuest", 1
            CFrameQ = CFrame.new(61122.65, 18.50, 1569.40)
            CFrameMon = CFrame.new(60844.11, 98.46, 1298.40)
        elseif lv <= 449 then
            Ms, NameQuest, QuestLv = "Fishman Commando", "FishmanQuest", 2
            CFrameQ = CFrame.new(61122.65, 18.50, 1569.40)
            CFrameMon = CFrame.new(61738.40, 64.21, 1433.84)
        elseif lv <= 474 then
            Ms, NameQuest, QuestLv = "God's Guard", "SkyExp1Quest", 1
            CFrameQ = CFrame.new(-4721.86, 845.30, -1953.85)
            CFrameMon = CFrame.new(-4628.05, 866.93, -1931.24)
        elseif lv <= 524 then
            Ms, NameQuest, QuestLv = "Shanda", "SkyExp1Quest", 2
            CFrameQ = CFrame.new(-7863.16, 5545.52, -378.42)
            CFrameMon = CFrame.new(-7685.15, 5601.08, -441.39)
        elseif lv <= 549 then
            Ms, NameQuest, QuestLv = "Royal Squad", "SkyExp2Quest", 1
            CFrameQ = CFrame.new(-7903.38, 5635.99, -1410.92)
            CFrameMon = CFrame.new(-7654.25, 5637.11, -1407.76)
        elseif lv <= 624 then
            Ms, NameQuest, QuestLv = "Royal Soldier", "SkyExp2Quest", 2
            CFrameQ = CFrame.new(-7903.38, 5635.99, -1410.92)
            CFrameMon = CFrame.new(-7760.41, 5679.91, -1884.81)
        elseif lv <= 649 then
            Ms, NameQuest, QuestLv = "Galley Pirate", "FountainQuest", 1
            CFrameQ = CFrame.new(5258.28, 38.53, 4050.04)
            CFrameMon = CFrame.new(5557.17, 152.33, 3998.78)
        else
            Ms, NameQuest, QuestLv = "Galley Captain", "FountainQuest", 2
            CFrameQ = CFrame.new(5258.28, 38.53, 4050.04)
            CFrameMon = CFrame.new(5677.68, 92.79, 4966.63)
        end
    elseif Sea2 then
        if lv <= 724 then
            Ms, NameQuest, QuestLv = "Raider", "Area1Quest", 1
            CFrameQ = CFrame.new(-427.73, 73, 1835.94)
            CFrameMon = CFrame.new(68.87, 93.64, 2429.68)
        elseif lv <= 774 then
            Ms, NameQuest, QuestLv = "Mercenary", "Area1Quest", 2
            CFrameQ = CFrame.new(-427.73, 73, 1835.94)
            CFrameMon = CFrame.new(-864.85, 122.47, 1453.15)
        elseif lv <= 799 then
            Ms, NameQuest, QuestLv = "Swan Pirate", "Area2Quest", 1
            CFrameQ = CFrame.new(635.61, 73.10, 917.81)
            CFrameMon = CFrame.new(1065.37, 137.64, 1324.38)
        elseif lv <= 874 then
            Ms, NameQuest, QuestLv = "Factory Staff", "Area2Quest", 2
            CFrameQ = CFrame.new(635.61, 73.10, 917.81)
            CFrameMon = CFrame.new(533.22, 128.47, 355.63)
        else
            Ms, NameQuest, QuestLv = "Marine Lieutenant", "MarineQuest3", 1
            CFrameQ = CFrame.new(-2440.99, 73.04, -3217.71)
            CFrameMon = CFrame.new(-2489.26, 84.61, -3151.88)
        end
    else -- Sea3
        Ms, NameQuest, QuestLv = "Pirate Millionaire", "PiratePortQuest", 1
        CFrameQ = CFrame.new(-450, 84, 5660)
        CFrameMon = CFrame.new(-450, 84, 5660)
    end

    return Ms, NameQuest, QuestLv, CFrameQ, CFrameMon
end

-- ====================== QUEST CHECK ======================
local function TemQuestCorreta(NameQuest)
    local ok, result = pcall(function()
        local main = LP.PlayerGui:FindFirstChild("Main")
        if not main then return false end
        local q = main:FindFirstChild("Quest")
        if not q or not q.Visible then return false end

        local title = q:FindFirstChild("Title") or q:FindFirstChild("QuestTitle")
        if title and title:IsA("TextLabel") then
            local t = string.lower(title.Text or "")
            local key = string.lower((NameQuest or ""):gsub("Quest", ""))
            if key ~= "" and string.find(t, key) then
                return true
            end
            -- qualquer quest ativa = não pega outra
            return true
        end
        return q.Visible
    end)
    return ok and result
end

-- ====================== AUTO LEVEL LOOP ======================
task.spawn(function()
    while task.wait(0.12) do
        if not _G.AutoLevel then
            NoClip(false)
            continue
        end

        pcall(function()
            NoClip(true)
            EquipWeapon(_G.SelectWeapon)

            local Ms, NameQuest, QuestLv, CFrameQ, CFrameMon = CheckLevel()
            if not Ms then return end

            local temQuest = TemQuestCorreta(NameQuest)

            -- só vai no NPC se NÃO tiver quest
            if not temQuest then
                local hrp = GetHRP()
                if hrp and (hrp.Position - CFrameQ.Position).Magnitude > 12 then
                    TweenTo(CFrameQ * CFrame.new(0, 3, 0))
                end
                task.wait(0.25)
                ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, QuestLv)
                task.wait(0.45)
                return
            end

            -- tem quest → fica no mob
            local target = nil
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, v in ipairs(enemies:GetChildren()) do
                    if v.Name == Ms
                        and v:FindFirstChild("Humanoid")
                        and v.Humanoid.Health > 0
                        and v:FindFirstChild("HumanoidRootPart") then
                        target = v
                        break
                    end
                end
            end

            if target then
                local mhrp = target.HumanoidRootPart
                PosMon = mhrp.Position
                BringEnemy()

                local above = mhrp.CFrame * CFrame.new(0, 25, 0)
                local hrp = GetHRP()
                if hrp then
                    if (hrp.Position - above.Position).Magnitude > 8 then
                        TweenTo(above)
                    else
                        hrp.CFrame = above
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end
                end
            else
                TweenTo(CFrameMon * CFrame.new(0, 10, 0))
            end
        end)
    end
end)

-- ====================== GG-UI ======================
local UI_URL = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
local GGUI = loadstring(game:HttpGet(UI_URL))()

if not GGUI or type(GGUI.MakeWindow) ~= "function" then
    warn("[BF] Falha ao carregar GG-UI")
    return
end

local Win = GGUI:MakeWindow({
    Title = "Auto Farm Estável",
    SubTitle = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or 1),
    ScriptFolder = "AutoFarmEstavel"
})

local TabFarm = Win:MakeTab({ Title = "Farm" })
local TabCfg  = Win:MakeTab({ Title = "Config" })

TabFarm:AddToggle({
    Title = "Auto Level",
    Description = "Farm automático de level + quest",
    Default = false,
    Callback = function(v)
        _G.AutoLevel = v
        if v then
            _G.Seriality = true
        end
    end
})

TabFarm:AddToggle({
    Title = "Seriality (Ataque)",
    Description = "AttackNoCoolDown — RegisterAttack + RegisterHit",
    Default = false,
    Callback = function(v)
        _G.Seriality = v
    end
})

TabFarm:AddToggle({
    Title = "Bring Mobs",
    Description = "Puxa mobs pro mesmo ponto",
    Default = true,
    Callback = function(v)
        _G.BringMobs = v
    end
})

TabCfg:AddDropdown({
    Title = "Arma",
    Description = "Tipo de tool",
    Options = {"Melee", "Sword", "Blox Fruit"},
    Default = "Melee",
    Callback = function(v)
        _G.SelectWeapon = v
        EquipWeapon(v)
    end
})

TabCfg:AddButton({
    Title = "Equipar Arma Agora",
    Callback = function()
        EquipWeapon(_G.SelectWeapon)
    end
})

print("[Auto Farm Estável] carregado — GG-UI + AttackNoCoolDown + quest fix")
