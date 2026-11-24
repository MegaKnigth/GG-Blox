--[[
  Auto Farm — só lógica dos opensource
  Movimento: Part (Banana) + BodyClip (Relz)
  Farm: loop Relz + fallback EnemySpawns/ReplicatedStorage (Banana)
  Ataque: AttackNoCoolDown (Banana)
  UI: GG-UI
]]

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.5)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")

local LP  = Players.LocalPlayer
local Char, Humanoid, HumanoidRootPart

local function SetupCharacter(c)
    Char = c
    Humanoid = c:WaitForChild("Humanoid")
    HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end
if LP.Character then SetupCharacter(LP.Character) end
LP.CharacterAdded:Connect(SetupCharacter)

local Remotes = ReplicatedStorage.Remotes
local Enemies = workspace:WaitForChild("Enemies")
local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

pcall(function()
    Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
end)

local PlaceId = game.PlaceId
local World1 = (PlaceId == 2753915549 or PlaceId == 85211729168715)
local World2 = (PlaceId == 4442272183 or PlaceId == 79091703265657)
local World3 = (PlaceId == 7449423635 or PlaceId == 100117331123089)
local CurrentSea = World1 and 1 or World2 and 2 or World3 and 3 or 1

-- state (nomes dos hubs)
_G.Seriality      = false
_G.AutoFarmLevel  = false
_G.BringMob       = true
_G.SelectWeapon   = "Melee"
_G.SelectedWeapon = "Melee"
_G.FarmDistance   = 25
_G.PlayerTweenSpeed = 300
_G.StopTween      = false

local PosMon = CFrame.new()
local Mon, LevelQuest, NameQuest, NameMon, CFrameQuest, CFrameMon
local Pos = CFrame.new(0, 25, 0)
local shouldTween = false
getgenv().OnFarm = false

-- ====================== PART (Banana) ======================
local Part = Instance.new("Part")
Part.Size = Vector3.new(1, 1, 1)
Part.Name = "Rip_Indra"
Part.Anchored = true
Part.CanCollide = false
Part.CanTouch = false
Part.Transparency = 1
Part.Parent = workspace

do
    local old = workspace:FindFirstChild(Part.Name)
    if old and old ~= Part then old:Destroy() end
end

task.spawn(function()
    while task.wait() do
        if Part and Part.Parent == workspace then
            getgenv().OnFarm = shouldTween and true or false
        else
            getgenv().OnFarm = false
        end
    end
end)

task.spawn(function()
    while not (LP.Character and LP.Character.PrimaryPart) do task.wait() end
    Part.CFrame = LP.Character.PrimaryPart.CFrame
    while task.wait() do
        pcall(function()
            if getgenv().OnFarm then
                local PrimaryPart = LP.Character and LP.Character.PrimaryPart
                if Part and Part.Parent == workspace and PrimaryPart then
                    if (PrimaryPart.Position - Part.Position).Magnitude <= 200 then
                        PrimaryPart.CFrame = CFrame.new(Part.Position)
                    else
                        Part.CFrame = PrimaryPart.CFrame
                    end
                end
                if LP.Character then
                    for _, child in pairs(LP.Character:GetChildren()) do
                        if child:IsA("BasePart") then child.CanCollide = false end
                    end
                end
            end
        end)
    end
end)

-- FarmDistance offset (Relz)
task.spawn(function()
    while task.wait() do
        Pos = CFrame.new(0, _G.FarmDistance or 25, 0)
    end
end)

-- BodyClip + noclip enquanto AutoFarmLevel (Relz)
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.AutoFarmLevel then
                if HumanoidRootPart and not HumanoidRootPart:FindFirstChild("BodyClip") then
                    local Noclip = Instance.new("BodyVelocity")
                    Noclip.Name = "BodyClip"
                    Noclip.Parent = HumanoidRootPart
                    Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
                    Noclip.Velocity = Vector3.new(0, 0, 0)
                end
                if Char then
                    for _, v in pairs(Char:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                end
            else
                if HumanoidRootPart and HumanoidRootPart:FindFirstChild("BodyClip") then
                    HumanoidRootPart.BodyClip:Destroy()
                end
            end
        end)
    end
end)

-- ====================== _tp (Banana, Part) ======================
local function _tp(target)
    local cFrame3
    if typeof(target) == "Vector3" then
        cFrame3 = CFrame.new(target)
    elseif typeof(target) == "CFrame" then
        cFrame3 = target
    else
        cFrame3 = target and target.CFrame
    end
    if not cFrame3 then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = LP.Character.HumanoidRootPart
    local Magnitude = (cFrame3.Position - hrp.Position).Magnitude
    local speed = (Magnitude <= 15 and 180 or (_G.PlayerTweenSpeed or 300))
    local tweenInfo = TweenInfo.new(Magnitude / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Part, tweenInfo, { CFrame = CFrame.new(cFrame3.Position) })

    if LP.Character.Humanoid.Sit then
        Part.CFrame = CFrame.new(Part.Position.X, cFrame3.Y, Part.Position.Z)
    end

    shouldTween = true
    tween:Play()
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if shouldTween then
                task.wait(0.1)
            else
                tween:Cancel()
                break
            end
        end
        getgenv().OnFarm = true
    end)
    return tween
end

local function StopTween(state)
    if not state then
        _G.StopTween = true
        shouldTween = false
        if HumanoidRootPart and HumanoidRootPart:FindFirstChild("BodyClip") then
            HumanoidRootPart.BodyClip:Destroy()
        end
        _G.StopTween = false
    end
end

-- ====================== EQUIP / BRING ======================
local function EquipWeapon(tip)
    tip = tip or _G.SelectWeapon
    if not Char or not Humanoid then return end
    local cur = Char:FindFirstChildOfClass("Tool")
    if cur and cur.ToolTip == tip then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == tip then
            Humanoid:EquipTool(t)
            return
        end
    end
end

local function BringEnemy()
    if not _G.BringMob then return end
    local pivot = PosMon.Position
    for _, child in ipairs(Enemies:GetChildren()) do
        local hum = child:FindFirstChildOfClass("Humanoid")
        local hrp = child:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            if (hrp.Position - pivot).Magnitude <= 350 then
                hrp.CFrame = CFrame.new(pivot)
                hrp.CanCollide = false
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                pcall(function()
                    if sethiddenproperty then
                        sethiddenproperty(LP, "SimulationRadius", math.huge)
                    end
                end)
            end
        end
    end
end

-- ====================== ATTACK (Banana AttackNoCoolDown) ======================
local function IsAlive(e)
    local h = e and e:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

function AttackNoCoolDown()
    if not Char then return end
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local targets, mainTarget = {}, nil
    local pos = Char:GetPivot().Position
    for _, enemy in ipairs(Enemies:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp and IsAlive(enemy) and not enemy:GetAttribute("IsBoat") then
            if (hrp.Position - pos).Magnitude <= 60 then
                local limbs = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
                local part = enemy:FindFirstChild(limbs[math.random(#limbs)]) or enemy.PrimaryPart or hrp
                if part then
                    table.insert(targets, {enemy, part})
                    mainTarget = part
                end
            end
        end
    end
    if not mainTarget then return end

    RegisterAttack:FireServer(0)

    local hitFn
    if getsenv then
        local ps = LP:FindFirstChild("PlayerScripts")
        local ls = ps and ps:FindFirstChildOfClass("LocalScript")
        if ls then
            local ok, env = pcall(getsenv, ls)
            if ok and env and env._G then hitFn = env._G.SendHitsToServer end
        end
    end
    local okF, combatThread = pcall(function()
        return require(ReplicatedStorage.Modules.Flags).COMBAT_REMOTE_THREAD or false
    end)
    if okF and combatThread and hitFn then
        hitFn(mainTarget, targets)
    else
        RegisterHit:FireServer(mainTarget, targets)
    end
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.Seriality then return end
        AttackNoCoolDown()
        local tool = Char and Char:FindFirstChildOfClass("Tool")
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
    require(ReplicatedStorage.Util.CameraShaker):Stop()
end)

-- ====================== CHECKQUEST (Relz — dados iguais) ======================
function CheckQuest()
    local MyLevel = LP.Data.Level.Value
    if World1 then
        if MyLevel <= 9 then
            Mon, LevelQuest, NameQuest, NameMon = "Bandit", 1, "BanditQuest1", "Bandit"
            CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231)
            CFrameMon   = CFrame.new(1045.962646484375, 27.00250816345215, 1560.8203125)
        elseif MyLevel <= 14 then
            Mon, LevelQuest, NameQuest, NameMon = "Monkey", 1, "JungleQuest", "Monkey"
            CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838)
            CFrameMon   = CFrame.new(-1448.51806640625, 67.85301208496094, 11.46579647064209)
        elseif MyLevel <= 29 then
            Mon, LevelQuest, NameQuest, NameMon = "Gorilla", 2, "JungleQuest", "Gorilla"
            CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838)
            CFrameMon   = CFrame.new(-1129.8836669921875, 40.46354675292969, -525.4237060546875)
        elseif MyLevel <= 39 then
            Mon, LevelQuest, NameQuest, NameMon = "Pirate", 1, "BuggyQuest1", "Pirate"
            CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498)
            CFrameMon   = CFrame.new(-1103.513427734375, 13.752052307128906, 3896.091064453125)
        elseif MyLevel <= 59 then
            Mon, LevelQuest, NameQuest, NameMon = "Brute", 2, "BuggyQuest1", "Brute"
            CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498)
            CFrameMon   = CFrame.new(-1140.083740234375, 14.809885025024414, 4322.92138671875)
        elseif MyLevel <= 74 then
            Mon, LevelQuest, NameQuest, NameMon = "Desert Bandit", 1, "DesertQuest", "Desert Bandit"
            CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359)
            CFrameMon   = CFrame.new(924.7998046875, 6.44867467880249, 4481.5859375)
        elseif MyLevel <= 89 then
            Mon, LevelQuest, NameQuest, NameMon = "Desert Officer", 2, "DesertQuest", "Desert Officer"
            CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359)
            CFrameMon   = CFrame.new(1608.2822265625, 8.614224433898926, 4371.00732421875)
        elseif MyLevel <= 99 then
            Mon, LevelQuest, NameQuest, NameMon = "Snow Bandit", 1, "SnowQuest", "Snow Bandit"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796)
            CFrameMon   = CFrame.new(1354.347900390625, 87.27277374267578, -1393.946533203125)
        elseif MyLevel <= 119 then
            Mon, LevelQuest, NameQuest, NameMon = "Snowman", 2, "SnowQuest", "Snowman"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796)
            CFrameMon   = CFrame.new(1201.6412353515625, 144.57958984375, -1550.0670166015625)
        elseif MyLevel <= 149 then
            Mon, LevelQuest, NameQuest, NameMon = "Chief Petty Officer", 1, "MarineQuest2", "Chief Petty Officer"
            CFrameQuest = CFrame.new(-5039.58643, 27.3500385, 4324.68018)
            CFrameMon   = CFrame.new(-4881.23095703125, 22.65204429626465, 4273.75244140625)
        elseif MyLevel <= 174 then
            Mon, LevelQuest, NameQuest, NameMon = "Sky Bandit", 1, "SkyQuest", "Sky Bandit"
            CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165)
            CFrameMon   = CFrame.new(-4953.20703125, 295.74420166015625, -2899.22900390625)
        elseif MyLevel <= 189 then
            Mon, LevelQuest, NameQuest, NameMon = "Dark Master", 2, "SkyQuest", "Dark Master"
            CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165)
            CFrameMon   = CFrame.new(-5259.8447265625, 391.3976745605469, -2229.035400390625)
        elseif MyLevel <= 209 then
            Mon, LevelQuest, NameQuest, NameMon = "Prisoner", 1, "PrisonerQuest", "Prisoner"
            CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514)
            CFrameMon   = CFrame.new(5098.9736328125, -0.3204058110713959, 474.2373352050781)
        elseif MyLevel <= 249 then
            Mon, LevelQuest, NameQuest, NameMon = "Dangerous Prisoner", 2, "PrisonerQuest", "Dangerous Prisoner"
            CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514)
            CFrameMon   = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375)
        elseif MyLevel <= 274 then
            Mon, LevelQuest, NameQuest, NameMon = "Toga Warrior", 1, "ColosseumQuest", "Toga Warrior"
            CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534)
            CFrameMon   = CFrame.new(-1820.21484375, 51.68385696411133, -2740.6650390625)
        elseif MyLevel <= 299 then
            Mon, LevelQuest, NameQuest, NameMon = "Gladiator", 2, "ColosseumQuest", "Gladiator"
            CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534)
            CFrameMon   = CFrame.new(-1292.838134765625, 56.380882263183594, -3339.031494140625)
        elseif MyLevel <= 324 then
            Mon, LevelQuest, NameQuest, NameMon = "Military Soldier", 1, "MagmaQuest", "Military Soldier"
            CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395)
            CFrameMon   = CFrame.new(-5411.16455078125, 11.081554412841797, 8454.29296875)
        elseif MyLevel <= 374 then
            Mon, LevelQuest, NameQuest, NameMon = "Military Spy", 2, "MagmaQuest", "Military Spy"
            CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395)
            CFrameMon   = CFrame.new(-5802.8681640625, 86.26241302490234, 8828.859375)
        elseif MyLevel <= 399 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Warrior", 1, "FishmanQuest", "Fishman Warrior"
            CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
            CFrameMon   = CFrame.new(60878.30078125, 18.482830047607422, 1543.7574462890625)
        elseif MyLevel <= 449 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Commando", 2, "FishmanQuest", "Fishman Commando"
            CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
            CFrameMon   = CFrame.new(61922.6328125, 18.482830047607422, 1493.934326171875)
        elseif MyLevel <= 474 then
            Mon, LevelQuest, NameQuest, NameMon = "God's Guard", 1, "SkyExp1Quest", "God's Guard"
            CFrameQuest = CFrame.new(-4721.88867, 843.874695, -1949.96643)
            CFrameMon   = CFrame.new(-4710.04296875, 845.2769775390625, -1927.3079833984375)
        elseif MyLevel <= 524 then
            Mon, LevelQuest, NameQuest, NameMon = "Shanda", 2, "SkyExp1Quest", "Shanda"
            CFrameQuest = CFrame.new(-7859.09814, 5544.19043, -381.476196)
            CFrameMon   = CFrame.new(-7678.48974609375, 5566.40380859375, -497.2156066894531)
        elseif MyLevel <= 549 then
            Mon, LevelQuest, NameQuest, NameMon = "Royal Squad", 1, "SkyExp2Quest", "Royal Squad"
            CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194)
            CFrameMon   = CFrame.new(-7624.25244140625, 5658.13330078125, -1467.354248046875)
        elseif MyLevel <= 624 then
            Mon, LevelQuest, NameQuest, NameMon = "Royal Soldier", 2, "SkyExp2Quest", "Royal Soldier"
            CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194)
            CFrameMon   = CFrame.new(-7836.75341796875, 5645.6640625, -1790.6236572265625)
        elseif MyLevel <= 649 then
            Mon, LevelQuest, NameQuest, NameMon = "Galley Pirate", 1, "FountainQuest", "Galley Pirate"
            CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293)
            CFrameMon   = CFrame.new(5551.02197265625, 78.90135192871094, 3930.412841796875)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Galley Captain", 2, "FountainQuest", "Galley Captain"
            CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293)
            CFrameMon   = CFrame.new(5441.95166015625, 42.50205993652344, 4950.09375)
        end
    elseif World2 then
        if MyLevel <= 724 then
            Mon, LevelQuest, NameQuest, NameMon = "Raider", 1, "Area1Quest", "Raider"
            CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188)
            CFrameMon   = CFrame.new(-728.3267211914062, 52.779319763183594, 2345.7705078125)
        elseif MyLevel <= 774 then
            Mon, LevelQuest, NameQuest, NameMon = "Mercenary", 2, "Area1Quest", "Mercenary"
            CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188)
            CFrameMon   = CFrame.new(-1004.3244018554688, 80.15886688232422, 1424.619384765625)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Swan Pirate", 1, "Area2Quest", "Swan Pirate"
            CFrameQuest = CFrame.new(638.43811, 71.769989, 918.282898)
            CFrameMon   = CFrame.new(1068.664306640625, 137.61428833007812, 1322)
        end
    else
        Mon, LevelQuest, NameQuest, NameMon = "Pirate Millionaire", 1, "PiratePortQuest", "Pirate Millionaire"
        CFrameQuest = CFrame.new(-450, 84, 5660)
        CFrameMon   = CFrame.new(-712.8272705078125, 98.5770492553711, 5711.9541015625)
    end
end

-- ====================== AttackTarget (Relz) ======================
local function AttackTarget(v, bring, stateFn)
    repeat
        task.wait()
        if stateFn and not stateFn() then return end
        if not v or not v.Parent or not IsAlive(v) or not v:FindFirstChild("HumanoidRootPart") then return end
        EquipWeapon(_G.SelectWeapon)
        _tp(v.HumanoidRootPart.CFrame * Pos)
        if bring then
            PosMon = v.HumanoidRootPart.CFrame
            BringEnemy()
        end
    until not v or not v.Parent or not IsAlive(v) or _G.StopTween == true or (stateFn and not stateFn())
end

-- ====================== AUTO FARM LEVEL (Relz loop + Banana fallback) ======================
task.spawn(function()
    while task.wait(0.2) do
        if not _G.AutoFarmLevel then
            shouldTween = false
            continue
        end
        pcall(function()
            CheckQuest()
            local QuestTitle = ""
            pcall(function()
                QuestTitle = LP.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
            end)

            if not string.find(QuestTitle, NameMon) then
                Remotes.CommF_:InvokeServer("AbandonQuest")
            end

            if LP.PlayerGui.Main.Quest.Visible == false then
                Remotes.CommF_:InvokeServer("StartQuest", NameQuest, LevelQuest)
            elseif LP.PlayerGui.Main.Quest.Visible == true then
                if Enemies:FindFirstChild(Mon) then
                    for _, v in pairs(Enemies:GetChildren()) do
                        if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            if v.Name == Mon then
                                AttackTarget(v, true, function()
                                    return _G.AutoFarmLevel
                                end)
                            end
                        end
                    end
                else
                    -- Banana: ReplicatedStorage
                    local found = false
                    for _, v in pairs(ReplicatedStorage:GetChildren()) do
                        if string.find(v.Name, Mon) and v:FindFirstChild("HumanoidRootPart") and IsAlive(v) then
                            _tp(v.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                            found = true
                            break
                        end
                    end
                    -- Banana: EnemySpawns
                    if not found then
                        local spawns = workspace:FindFirstChild("_WorldOrigin")
                        spawns = spawns and spawns:FindFirstChild("EnemySpawns")
                        if spawns then
                            for _, v1 in pairs(spawns:GetChildren()) do
                                if string.find(v1.Name, Mon) then
                                    _tp(v1.CFrame * CFrame.new(0, 20, 0))
                                    found = true
                                    break
                                end
                            end
                        end
                    end
                    if not found and CFrameMon then
                        _tp(CFrameMon)
                    end
                end
            end
        end)
    end
end)

-- ====================== GG-UI ======================
local GGUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"))()
if not GGUI or type(GGUI.MakeWindow) ~= "function" then
    warn("[BF] GG-UI fail")
    return
end

local Win = GGUI:MakeWindow({
    Title = "Auto Farm",
    SubTitle = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or 1),
    ScriptFolder = "AutoFarmEstavel"
})

local TabFarm = Win:MakeTab({ Title = "Farm" })
local TabCfg  = Win:MakeTab({ Title = "Config" })

TabFarm:AddToggle({
    Title = "Auto Farm Level",
    Default = false,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if v then
            _G.Seriality = true
        else
            StopTween(false)
            shouldTween = false
        end
    end
})

TabFarm:AddToggle({
    Title = "Seriality (Ataque)",
    Default = false,
    Callback = function(v) _G.Seriality = v end
})

TabFarm:AddToggle({
    Title = "Bring Mobs",
    Default = true,
    Callback = function(v) _G.BringMob = v end
})

TabCfg:AddDropdown({
    Title = "Arma",
    Options = {"Melee", "Sword", "Blox Fruit"},
    Default = "Melee",
    Callback = function(v)
        _G.SelectWeapon = v
        _G.SelectedWeapon = v
        EquipWeapon(v)
    end
})

print("[Auto Farm] Banana Part + Relz farm loop + Banana attack")
