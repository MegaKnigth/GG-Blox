--[[
  Auto Farm Estável — GG-UI + AttackNoCoolDown (gghub)
  UI: https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau
  Ataque: RegisterAttack + RegisterHit + flags (não mexido)
]]

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
_G.Seriality   = false   -- liga o AttackNoCoolDown
_G.AutoLevel   = false
_G.BringMobs   = true
_G.SelectWeapon = "Melee" -- Melee | Sword | Blox Fruit
local PosMon   = Vector3.zero

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

-- ====================== BRING (do gghub, intacto) ======================
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

-- ====================== ATTACK NO COOLDOWN (gghub — não mexido) ======================
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

-- Heartbeat do ataque (igual gghub)
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
        else
            Ms, NameQuest, QuestLv = "Desert Officer", "DesertQuest", 2
            CFrameQ = CFrame.new(896.52, 6.44, 4390.15)
            CFrameMon = CFrame.new(1547.15, 14.45, 4381.80)
        end
    elseif Sea2 then
        if lv <= 724 then
            Ms, NameQuest, QuestLv = "Raider", "Area1Quest", 1
            CFrameQ = CFrame.new(-427.73, 73, 1835.94)
            CFrameMon = CFrame.new(68.87, 93.64, 2429.68)
        else
            Ms, NameQuest, QuestLv = "Mercenary", "Area1Quest", 2
            CFrameQ = CFrame.new(-427.73, 73, 1835.94)
            CFrameMon = CFrame.new(-864.85, 122.47, 1453.15)
        end
    else -- Sea3 fallback
        Ms, NameQuest, QuestLv = "Pirate Millionaire", "PiratePortQuest", 1
        CFrameQ = CFrame.new(-450, 84, 5660)
        CFrameMon = CFrame.new(-450, 84, 5660)
    end

    return Ms, NameQuest, QuestLv, CFrameQ, CFrameMon
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

            -- Quest
            local hasQuest = LP.PlayerGui.Main.Quest.Visible
            if not hasQuest then
                TweenTo(CFrameQ * CFrame.new(0, 3, 0))
                task.wait(0.35)
                ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, QuestLv)
                task.wait(0.4)
            end

            -- Mob
            local target
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, v in ipairs(enemies:GetChildren()) do
                    if v.Name == Ms and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0
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
                TweenTo(above)
                Root.CFrame = above
                Root.AssemblyLinearVelocity = Vector3.zero
            else
                -- vai pro spawn da área
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

-- Farm tab
TabFarm:AddToggle({
    Title = "Auto Level",
    Description = "Farm automático de level + quest",
    Default = false,
    Callback = function(v)
        _G.AutoLevel = v
        if v then
            _G.Seriality = true -- liga o ataque junto
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

-- Config tab
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

print("[Auto Farm Estável] carregado — GG-UI + AttackNoCoolDown")
