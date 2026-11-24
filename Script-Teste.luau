--[[
  Fontes (não inventado):
  - Quest: Banana v301 / v311 / v313 + ramo "if not Quest then _tp(PosQ) wait 2 se <=10 StartQuest"
  - Abandon: só se quest ATIVA e título não bate (Banana)
  - Movimento longo: PartTele Relz (Banana Part limita 200 studs e reseta)
  - Ataque: AttackNoCoolDown Banana
]]

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.5)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local LP = Players.LocalPlayer
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

_G.Seriality      = false
_G.AutoFarmLevel  = false
_G.BringMob       = true
_G.SelectWeapon   = "Melee"
_G.FarmDistance   = 25
_G.PlayerTweenSpeed = 300
_G.StopTween      = false

local Mon, LevelQuest, NameQuest, NameMon, CFrameQuest, CFrameMon
local PosMon = CFrame.new()
local Pos = CFrame.new(0, 25, 0)
local isTeleporting = false
local Sec = 0.15

-- FarmDistance (Relz)
task.spawn(function()
    while task.wait() do
        Pos = CFrame.new(0, _G.FarmDistance or 25, 0)
    end
end)

-- BodyClip + noclip no farm (Relz)
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.AutoFarmLevel and HumanoidRootPart then
                if not HumanoidRootPart:FindFirstChild("BodyClip") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "BodyClip"
                    bv.MaxForce = Vector3.new(100000, 100000, 100000)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.Parent = HumanoidRootPart
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

-- ====================== TweenPlayer (Relz PartTele) ======================
local function TweenPlayer(dest)
    if not Char or not Humanoid or Humanoid.Health <= 0 or not HumanoidRootPart or not dest then return end
    local Distance = (dest.Position - HumanoidRootPart.Position).Magnitude
    if Distance < 3 then
        HumanoidRootPart.CFrame = dest
        return
    end

    local PartTele = Char:FindFirstChild("PartTele")
    if not PartTele then
        PartTele = Instance.new("Part")
        PartTele.Size = Vector3.new(10, 1, 10)
        PartTele.Name = "PartTele"
        PartTele.Anchored = true
        PartTele.Transparency = 1
        PartTele.CanCollide = false
        PartTele.CFrame = HumanoidRootPart.CFrame
        PartTele.Parent = Char
        PartTele:GetPropertyChangedSignal("CFrame"):Connect(function()
            if not isTeleporting then return end
            task.wait()
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                Char.HumanoidRootPart.CFrame = PartTele.CFrame
                Char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end

    isTeleporting = true
    local tw = TweenService:Create(
        PartTele,
        TweenInfo.new(Distance / (_G.PlayerTweenSpeed or 300), Enum.EasingStyle.Linear),
        { CFrame = dest }
    )
    tw:Play()
    tw.Completed:Wait()
    isTeleporting = false
    if HumanoidRootPart then
        HumanoidRootPart.CFrame = dest
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end
end

local function StopTween()
    _G.StopTween = true
    isTeleporting = false
    if Char and Char:FindFirstChild("PartTele") then
        Char.PartTele:Destroy()
    end
    if HumanoidRootPart and HumanoidRootPart:FindFirstChild("BodyClip") then
        HumanoidRootPart.BodyClip:Destroy()
    end
    _G.StopTween = false
end

-- ====================== QUEST HELPERS (Banana v301 / v305 / v311 / v313) ======================
local function HasQuestVisible()
    local tracked = LP.PlayerGui:FindFirstChild("TrackedQuestFrame")
    if tracked then
        local frame = tracked:FindFirstChild("Frame")
        if frame and tracked.Enabled and frame.Visible then
            return true
        end
    end
    local main = LP.PlayerGui:FindFirstChild("Main")
    local q = main and main:FindFirstChild("Quest")
    return q and q.Visible == true
end

local function GetQuestTitle()
    local tracked = LP.PlayerGui:FindFirstChild("TrackedQuestFrame")
    if tracked then
        local frame = tracked:FindFirstChild("Frame")
        if frame and frame.Visible then
            local header = frame:FindFirstChild("header")
            local label = header and header:FindFirstChild("textLabel")
            if label and label:IsA("TextLabel") and label.Text ~= "" then
                return tostring(label.Text)
            end
        end
    end
    local ok, text = pcall(function()
        return LP.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
    end)
    if ok and text then return tostring(text) end
    return ""
end

-- v311: tem quest E título contém NameMon
local function HasCorrectQuest(nameMon)
    if not nameMon or not HasQuestVisible() then return false end
    local title = GetQuestTitle()
    if title == "" then return false end
    return string.find(string.lower(title), string.lower(nameMon), 1, true) ~= nil
end

-- v313: StartQuest + espera até 3s o título bater
local function StartQuestWait(qname, qdata, nameMon)
    if HasCorrectQuest(nameMon) then return true end
    local ok = pcall(function()
        Remotes.CommF_:InvokeServer("StartQuest", qname, qdata)
    end)
    if not ok then return false end
    local deadline = os.clock() + 3
    repeat
        if HasCorrectQuest(nameMon) then return true end
        task.wait(0.25)
    until os.clock() >= deadline
    return HasCorrectQuest(nameMon)
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
        if hum and hrp and hum.Health > 0 and (hrp.Position - pivot).Magnitude <= 350 then
            hrp.CFrame = CFrame.new(pivot)
            hrp.CanCollide = false
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            pcall(function()
                if sethiddenproperty then sethiddenproperty(LP, "SimulationRadius", math.huge) end
            end)
        end
    end
end

-- ====================== ATTACK (Banana) ======================
local function IsAlive(e)
    local h = e and e:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

function AttackNoCoolDown()
    if not Char or not Char:FindFirstChildOfClass("Tool") then return end
    local targets, mainTarget = {}, nil
    local pos = Char:GetPivot().Position
    for _, enemy in ipairs(Enemies:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp and IsAlive(enemy) and not enemy:GetAttribute("IsBoat") and (hrp.Position - pos).Magnitude <= 60 then
            local limbs = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
            local part = enemy:FindFirstChild(limbs[math.random(#limbs)]) or enemy.PrimaryPart or hrp
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

pcall(function() require(ReplicatedStorage.Util.CameraShaker):Stop() end)

-- ====================== CHECKQUEST (dados Relz/Banana) ======================
local function CheckQuest()
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
        else
            Mon, LevelQuest, NameQuest, NameMon = "Snow Bandit", 1, "SnowQuest", "Snow Bandit"
            CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796)
            CFrameMon   = CFrame.new(1354.347900390625, 87.27277374267578, -1393.946533203125)
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

-- ====================== AttackTarget (Relz shape, TweenPlayer Relz) ======================
local function AttackTarget(v, bring, stateFn)
    repeat
        task.wait()
        if stateFn and not stateFn() then return end
        if not v or not v.Parent or not IsAlive(v) or not v:FindFirstChild("HumanoidRootPart") then return end
        EquipWeapon(_G.SelectWeapon)
        TweenPlayer(v.HumanoidRootPart.CFrame * Pos)
        if bring then
            PosMon = v.HumanoidRootPart.CFrame
            BringEnemy()
        end
    until not v or not v.Parent or not IsAlive(v) or _G.StopTween or (stateFn and not stateFn())
end

-- ====================== FARM LOOP (Banana order) ======================
task.spawn(function()
    while task.wait(Sec) do
        if not _G.AutoFarmLevel then continue end
        pcall(function()
            if not HumanoidRootPart then return end
            CheckQuest()

            -- Banana: se quest VISÍVEL mas título errado → abandon
            if HasQuestVisible() and not HasCorrectQuest(NameMon) then
                Remotes.CommF_:InvokeServer("AbandonQuest")
                task.wait(0.2)
                return
            end

            -- Banana: se NÃO tem quest correta → vai no NPC, espera, StartQuest
            if not HasCorrectQuest(NameMon) then
                if CFrameQuest then
                    TweenPlayer(CFrameQuest)
                    task.wait(2)
                    if (HumanoidRootPart.Position - CFrameQuest.Position).Magnitude <= 10 then
                        StartQuestWait(NameQuest, LevelQuest, NameMon)
                    end
                else
                    StartQuestWait(NameQuest, LevelQuest, NameMon)
                end
                return
            end

            -- tem quest certa → farm (Relz/Banana)
            local target = nil
            for _, v in pairs(Enemies:GetChildren()) do
                if v.Name == Mon and IsAlive(v) and v:FindFirstChild("HumanoidRootPart") then
                    target = v
                    break
                end
            end

            if target then
                AttackTarget(target, true, function() return _G.AutoFarmLevel end)
            else
                -- Banana fallback: ReplicatedStorage
                local found = false
                for _, v in pairs(ReplicatedStorage:GetChildren()) do
                    if string.find(v.Name, Mon) and v:FindFirstChild("HumanoidRootPart") and IsAlive(v) then
                        TweenPlayer(v.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                        found = true
                        break
                    end
                end
                if not found then
                    local origin = workspace:FindFirstChild("_WorldOrigin")
                    local spawns = origin and origin:FindFirstChild("EnemySpawns")
                    if spawns then
                        for _, s in pairs(spawns:GetChildren()) do
                            if string.find(s.Name, Mon) then
                                TweenPlayer(s.CFrame * CFrame.new(0, 20, 0))
                                found = true
                                break
                            end
                        end
                    end
                end
                if not found and CFrameMon then
                    TweenPlayer(CFrameMon)
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
        if v then _G.Seriality = true else StopTween() end
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
        EquipWeapon(v)
    end
})

print("[Auto Farm] Banana quest flow + Relz PartTele")
