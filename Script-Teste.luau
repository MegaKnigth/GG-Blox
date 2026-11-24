--[[
  Auto Farm Estável — GG-UI
  Quest/Farm: lógica do gghub (original)
  Ataque: AttackNoCoolDown intacto
  Movimento: estável (CFrame longo / tween curto)
]]

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.8)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")

local LP   = Players.LocalPlayer
local Char = LP.Character or LP.CharacterAdded:Wait()
local Root = Char:WaitForChild("HumanoidRootPart")
local Hum  = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c
    Root = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
end)

pcall(function()
    ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
end)

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
local Sec       = 0.12

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

-- movimento estável: longo = CFrame, curto = tween
local function TP(cf)
    local hrp = GetHRP()
    if not hrp or not cf then return end
    local dist = (hrp.Position - cf.Position).Magnitude

    -- noclip leve
    for _, p in ipairs(LP.Character:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end

    if dist > 180 then
        -- long range / ilha: CFrame direto + zera velocity
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.05)
    elseif dist > 4 then
        local speed = 300
        local tw = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = cf})
        tw:Play()
        tw.Completed:Wait()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    else
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
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

-- ====================== BRING (original) ======================
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

-- ====================== ATTACK NO COOLDOWN (intacto) ======================
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

    local equippedWeapon = character:FindFirstChildOfClass("Tool")
    if not equippedWeapon then return end

    local enemiesInRange = GetEnemiesInRange(character, 60)
    if #enemiesInRange == 0 then return end

    local storage = game:GetService("ReplicatedStorage")
    local modules = storage:FindFirstChild("Modules")
    if not modules then return end

    local attackEvent = RegisterAttack
    local hitEvent    = RegisterHit
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
    if playerScripts then
        local localScript = playerScripts:FindFirstChildOfClass("LocalScript")
        if localScript and getsenv then
            local ok, env = pcall(getsenv, localScript)
            if ok and env and env._G and env._G.SendHitsToServer then
                env._G.SendHitsToServer(mainTarget, targets)
                return
            end
        end
    end

    local okFlags, combatRemoteThread = pcall(function()
        return require(modules.Flags).COMBAT_REMOTE_THREAD or false
    end)
    hitEvent:FireServer(mainTarget, targets)
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.Seriality then return end
        AttackNoCoolDown()
        local tool = LP.Character and rec.LP.Character:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == "Blox Fruit" then
            local left = tool:FindFirstChild("LeftClickRemote")
            if left then
                left:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                left:FireServer(false)
            end
        end
    end)
end)

pcall(function()
    require(game.ReplicatedStorage.Util.CameraShaker):Stop()
end)

-- ====================== QUEST DATA (padrão original) ======================
local function QuestNeta()
    local a = LP.Data.Level.Value
    local Mon, Qdata, Qname, NameMon, PosM, PosQ

    if Sea1 then
        if a <= 9 then
            Mon, Qdata, Qname, NameMon = "Bandit", 1, "BanditQuest1", "Bandit"
            PosQ = CFrame.new(1059.37, 15.45, 1550.42)
            PosM = CFrame.new(1045.96, 27.00, 1560.82)
        elseif a <= 14 then
            Mon, Qdata, Qname, NameMon = "Monkey", 1, "JungleQuest", "Monkey"
            PosQ = CFrame.new(-1598.09, 35.55, 153.38)
            PosM = CFrame.new(-1448.52, 67.85, 11.47)
        elseif a <= 29 then
            Mon, Qdata, Qname, NameMon = "Gorilla", 2, "JungleQuest", "Gorilla"
            PosQ = CFrame.new(-1598.09, 35.55, 153.38)
            PosM = CFrame.new(-1129.88, 40.46, -525.42)
        elseif a <= 39 then
            Mon, Qdata, Qname, NameMon = "Pirate", 1, "BuggyQuest1", "Pirate"
            PosQ = CFrame.new(-1141.07, 4.10, 3831.55)
            PosM = CFrame.new(-1103.51, 13.75, 3896.09)
        elseif a <= 59 then
            Mon, Qdata, Qname, NameMon = "Brute", 2, "BuggyQuest1", "Brute"
            PosQ = CFrame.new(-1141.07, 4.10, 3831.55)
            PosM = CFrame.new(-1140.08, 14.81, 4322.92)
        elseif a <= 74 then
            Mon, Qdata, Qname, NameMon = "Desert Bandit", 1, "DesertQuest", "Desert Bandit"
            PosQ = CFrame.new(894.49, 5.14, 4392.43)
            PosM = CFrame.new(924.80, 6.45, 4481.59)
        elseif a <= 89 then
            Mon, Qdata, Qname, NameMon = "Desert Officer", 2, "DesertQuest", "Desert Officer"
            PosQ = CFrame.new(894.49, 5.14, 4392.43)
            PosM = CFrame.new(1608.28, 8.61, 4371.01)
        elseif a <= 99 then
            Mon, Qdata, Qname, NameMon = "Snow Bandit", 1, "SnowQuest", "Snow Bandit"
            PosQ = CFrame.new(1389.74, 88.15, -1298.91)
            PosM = CFrame.new(1356.30, 105.77, -1328.24)
        elseif a <= 119 then
            Mon, Qdata, Qname, NameMon = "Snowman", 2, "SnowQuest", "Snowman"
            PosQ = CFrame.new(1389.74, 88.15, -1298.91)
            PosM = CFrame.new(1218.80, 138.01, -1488.03)
        elseif a <= 149 then
            Mon, Qdata, Qname, NameMon = "Chief Petty Officer", 1, "MarineQuest2", "Chief Petty Officer"
            PosQ = CFrame.new(-5035.50, 28.68, 4324.18)
            PosM = CFrame.new(-4931.16, 65.79, 4121.84)
        elseif a <= 174 then
            Mon, Qdata, Qname, NameMon = "Sky Bandit", 1, "SkyQuest", "Sky Bandit"
            PosQ = CFrame.new(-4842.14, 717.70, -2623.05)
            PosM = CFrame.new(-4955.64, 365.46, -2908.19)
        elseif a <= 189 then
            Mon, Qdata, Qname, NameMon = "Dark Master", 2, "SkyQuest", "Dark Master"
            PosQ = CFrame.new(-4842.14, 717.70, -2623.05)
            PosM = CFrame.new(-5148.17, 439.05, -2332.96)
        elseif a <= 209 then
            Mon, Qdata, Qname, NameMon = "Prisoner", 1, "PrisonerQuest", "Prisoner"
            PosQ = CFrame.new(5310.61, 0.35, 474.95)
            PosM = CFrame.new(4937.32, 0.33, 649.57)
        elseif a <= 249 then
            Mon, Qdata, Qname, NameMon = "Dangerous Prisoner", 2, "PrisonerQuest", "Dangerous Prisoner"
            PosQ = CFrame.new(5310.61, 0.35, 474.95)
            PosM = CFrame.new(5099.66, 0.35, 1055.76)
        elseif a <= 274 then
            Mon, Qdata, Qname, NameMon = "Toga Warrior", 1, "ColosseumQuest", "Toga Warrior"
            PosQ = CFrame.new(-1577.79, 7.42, -2984.48)
            PosM = CFrame.new(-1872.52, 49.08, -2913.81)
        elseif a <= 299 then
            Mon, Qdata, Qname, NameMon = "Gladiator", 2, "ColosseumQuest", "Gladiator"
            PosQ = CFrame.new(-1577.79, 7.42, -2984.48)
            PosM = CFrame.new(-1521.37, 81.20, -3066.31)
        elseif a <= 324 then
            Mon, Qdata, Qname, NameMon = "Military Soldier", 1, "MagmaQuest", "Military Soldier"
            PosQ = CFrame.new(-5316.12, 12.26, 8517.00)
            PosM = CFrame.new(-5369.00, 61.24, 8556.49)
        elseif a <= 374 then
            Mon, Qdata, Qname, NameMon = "Military Spy", 2, "MagmaQuest", "Military Spy"
            PosQ = CFrame.new(-5316.12, 12.26, 8517.00)
            PosM = CFrame.new(-5787.00, 75.83, 8651.70)
        elseif a <= 399 then
            Mon, Qdata, Qname, NameMon = "Fishman Warrior", 1, "FishmanQuest", "Fishman Warrior"
            PosQ = CFrame.new(61122.65, 18.50, 1569.40)
            PosM = CFrame.new(60844.11, 98.46, 1298.40)
        elseif a <= 449 then
            Mon, Qdata, Qname, NameMon = "Fishman Commando", 2, "FishmanQuest", "Fishman Commando"
            PosQ = CFrame.new(61122.65, 18.50, 1569.40)
            PosM = CFrame.new(61738.40, 64.21, 1433.84)
        elseif a <= 474 then
            Mon, Qdata, Qname, NameMon = "God's Guard", 1, "SkyExp1Quest", "God's Guard"
            PosQ = CFrame.new(-4721.86, 845.30, -1953.85)
            PosM = CFrame.new(-4628.05, 866.93, -1931.24)
        elseif a <= 524 then
            Mon, Qdata, Qname, NameMon = "Shanda", 2, "SkyExp1Quest", "Shanda"
            PosQ = CFrame.new(-7863.16, 5545.52, -378.42)
            PosM = CFrame.new(-7685.15, 5601.08, -441.39)
        elseif a <= 549 then
            Mon, Qdata, Qname, NameMon = "Royal Squad", 1, "SkyExp2Quest", "Royal Squad"
            PosQ = CFrame.new(-7903.38, 5635.99, -1410.92)
            PosM = CFrame.new(-7654.25, 5637.11, -1407.76)
        elseif a <= 624 then
            Mon, Qdata, Qname, NameMon = "Royal Soldier", 2, "SkyExp2Quest", "Royal Soldier"
            PosQ = CFrame.new(-7903.38, 5635.99, -1410.92)
            PosM = CFrame.new(-7760.41, 5679.91, -1884.81)
        elseif a <= 649 then
            Mon, Qdata, Qname, NameMon = "Galley Pirate", 1, "FountainQuest", "Galley Pirate"
            PosQ = CFrame.new(5258.28, 38.53, 4050.04)
            PosM = CFrame.new(5557.17, 152.33, 3998.78)
        else
            Mon, Qdata, Qname, NameMon = "Galley Captain", 2, "FountainQuest", "Galley Captain"
            PosQ = CFrame.new(5258.28, 38.53, 4050.04)
            PosM = CFrame.new(5677.68, 92.79, 4966.63)
        end
    elseif Sea2 then
        if a <= 724 then
            Mon, Qdata, Qname, NameMon = "Raider", 1, "Area1Quest", "Raider"
            PosQ = CFrame.new(-427.73, 73, 1835.94)
            PosM = CFrame.new(68.87, 93.64, 2429.68)
        elseif a <= 774 then
            Mon, Qdata, Qname, NameMon = "Mercenary", 2, "Area1Quest", "Mercenary"
            PosQ = CFrame.new(-427.73, 73, 1835.94)
            PosM = CFrame.new(-864.85, 122.47, 1453.15)
        else
            Mon, Qdata, Qname, NameMon = "Swan Pirate", 1, "Area2Quest", "Swan Pirate"
            PosQ = CFrame.new(635.61, 73.10, 917.81)
            PosM = CFrame.new(1065.37, 137.64, 1324.38)
        end
    else
        Mon, Qdata, Qname, NameMon = "Pirate Millionaire", 1, "PiratePortQuest", "Pirate Millionaire"
        PosQ = CFrame.new(-450, 84, 5660)
        PosM = CFrame.new(-450, 84, 5660)
    end

    -- [1]Mon [2]Qdata [3]Qname [4]PosM [5]NameMon [6]PosQ
    return { Mon, Qdata, Qname, PosM, NameMon, PosQ }
end

-- ====================== FARM LEVEL (lógica original) ======================
task.spawn(function()
    while task.wait(Sec) do
        if not _G.AutoLevel then
            NoClip(false)
            continue
        end

        pcall(function()
            NoClip(true)
            EquipWeapon(_G.SelectWeapon)

            local q = QuestNeta()
            local Mon, Qdata, Qname, PosM, NameMon, PosQ = q[1], q[2], q[3], q[4], q[5], q[6]

            local questGui = LP.PlayerGui.Main.Quest
            local questTitle = ""
            pcall(function()
                questTitle = questGui.Container.QuestTitle.Title.Text
            end)

            -- se tem quest mas não é a do mob atual → abandona (igual original)
            if questGui.Visible and not string.find(questTitle, NameMon) then
                ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
                task.wait(0.3)
            end

            if not questGui.Visible then
                -- sem quest → vai no NPC e pega
                TP(PosQ)
                local hrp = GetHRP()
                if hrp and (hrp.Position - PosQ.Position).Magnitude <= 8 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", Qname, Qdata)
                    task.wait(0.4)
                end
            else
                -- tem quest certa → farm
                local enemies = workspace:FindFirstChild("Enemies")
                local target = nil
                if enemies then
                    for _, v in ipairs(enemies:GetChildren()) do
                        if v.Name == Mon and IsEntityAlive(v) and v:FindFirstChild("HumanoidRootPart") then
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
                        if (hrp.Position - above.Position).Magnitude > 10 then
                            TP(above)
                        else
                            hrp.CFrame = above
                            hrp.AssemblyLinearVelocity = Vector3.zero
                        end
                    end
                else
                    -- sem mob → vai pro spawn da área
                    TP(PosM * CFrame.new(0, 10, 0))
                end
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
    Description = "Farm level (lógica original gghub)",
    Default = false,
    Callback = function(v)
        _G.AutoLevel = v
        if v then _G.Seriality = true end
    end
})

TabFarm:AddToggle({
    Title = "Seriality (Ataque)",
    Description = "AttackNoCoolDown",
    Default = false,
    Callback = function(v)
        _G.Seriality = v
    end
})

TabFarm:AddToggle({
    Title = "Bring Mobs",
    Description = "Puxa mobs",
    Default = true,
    Callback = function(v)
        _G.BringMobs = v
    end
})

TabCfg:AddDropdown({
    Title = "Arma",
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

print("[Auto Farm Estável] original quest logic + stable TP")
