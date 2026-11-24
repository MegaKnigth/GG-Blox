--[[
  Auto Farm Estável v4
  Movimento: PartTele (Relz)
  Quest: padrão Relz/Banana
  Ataque: AttackNoCoolDown (Banana/gghub)
  UI: GG-UI
]]

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.6)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")

local LP   = Players.LocalPlayer
local Char, Root, Hum

local function SetupChar(c)
    Char = c
    Root = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
end
if LP.Character then SetupChar(LP.Character) end
LP.CharacterAdded:Connect(SetupChar)

pcall(function()
    ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
end)

local PlaceId = game.PlaceId
local World1 = (PlaceId == 2753915549 or PlaceId == 85211729168715)
local World2 = (PlaceId == 4442272183 or PlaceId == 79091703265657)
local World3 = (PlaceId == 7449423635 or PlaceId == 100117331123089)
local CurrentSea = World1 and 1 or World2 and 2 or World3 and 3 or 1

-- ====================== STATE ======================
_G.Seriality     = false
_G.AutoFarmLevel = false
_G.BringMob      = true
_G.SelectWeapon  = "Melee"
_G.PlayerTweenSpeed = 300
local PosMon = Vector3.zero
local isTeleporting = false

-- ====================== REMOTES ======================
local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")
local Remotes = ReplicatedStorage.Remotes

-- ====================== EQUIP ======================
local function EquipWeapon(tip)
    tip = tip or _G.SelectWeapon
    if not Char or not Hum then return end
    local cur = Char:FindFirstChildOfClass("Tool")
    if cur and cur.ToolTip == tip then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == tip then
            Hum:EquipTool(t)
            return
        end
    end
end

-- ====================== MOVIMENTO (PartTele — Relz) ======================
local function StopTween()
    isTeleporting = false
    if Char and Char:FindFirstChild("PartTele") then
        Char.PartTele:Destroy()
    end
end

local function TweenPlayer(Pos)
    if not Char or not Hum or Hum.Health <= 0 or not Root or not Pos then return end

    local Distance = (Pos.Position - Root.Position).Magnitude
    if Distance < 3 then
        Root.CFrame = Pos
        Root.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- PartTele proxy
    local PartTele = Char:FindFirstChild("PartTele")
    if not PartTele then
        PartTele = Instance.new("Part")
        PartTele.Size = Vector3.new(8, 1, 8)
        PartTele.Name = "PartTele"
        PartTele.Anchored = true
        PartTele.Transparency = 1
        PartTele.CanCollide = false
        PartTele.CFrame = Root.CFrame
        PartTele.Parent = Char

        PartTele:GetPropertyChangedSignal("CFrame"):Connect(function()
            if not isTeleporting then return end
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                Char.HumanoidRootPart.CFrame = PartTele.CFrame
                Char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                Char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end

    -- noclip enquanto move
    for _, p in ipairs(Char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end

    isTeleporting = true
    local speed = _G.PlayerTweenSpeed or 300
    local tw = TweenService:Create(PartTele, TweenInfo.new(Distance / speed, Enum.EasingStyle.Linear), {CFrame = Pos})
    tw:Play()
    tw.Completed:Wait()
    isTeleporting = false

    if Root then
        Root.CFrame = Pos
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ====================== BRING ======================
local function BringEnemy(main)
    if not _G.BringMob then return end
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end
    local pivot = PosMon
    if main and main:FindFirstChild("HumanoidRootPart") then
        pivot = main.HumanoidRootPart.Position
        PosMon = pivot
    end
    for _, v in ipairs(enemies:GetChildren()) do
        local hum = v:FindFirstChildOfClass("Humanoid")
        local hrp = v:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and (not main or v.Name == main.Name) then
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

-- ====================== ATTACK NO COOLDOWN (Banana) ======================
local function IsAlive(e)
    local h = e and e:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

function AttackNoCoolDown()
    if not Char then return end
    local tool = Char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end

    local targets, mainTarget = {}, nil
    local pos = Char:GetPivot().Position
    for _, enemy in ipairs(enemies:GetChildren()) do
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

-- ====================== CHECK QUEST (Relz/Banana data) ======================
local Mon, LevelQuest, NameQuest, NameMon, CFrameQuest, CFrameMon

local function CheckQuest()
    local MyLevel = LP.Data.Level.Value
    if World1 then
        if MyLevel <= 9 then
            Mon, LevelQuest, NameQuest, NameMon = "Bandit", 1, "BanditQuest1", "Bandit"
            CFrameQuest = CFrame.new(1059.37, 15.45, 1550.42)
            CFrameMon   = CFrame.new(1045.96, 27.00, 1560.82)
        elseif MyLevel <= 14 then
            Mon, LevelQuest, NameQuest, NameMon = "Monkey", 1, "JungleQuest", "Monkey"
            CFrameQuest = CFrame.new(-1598.09, 35.55, 153.38)
            CFrameMon   = CFrame.new(-1448.52, 67.85, 11.47)
        elseif MyLevel <= 29 then
            Mon, LevelQuest, NameQuest, NameMon = "Gorilla", 2, "JungleQuest", "Gorilla"
            CFrameQuest = CFrame.new(-1598.09, 35.55, 153.38)
            CFrameMon   = CFrame.new(-1129.88, 40.46, -525.42)
        elseif MyLevel <= 39 then
            Mon, LevelQuest, NameQuest, NameMon = "Pirate", 1, "BuggyQuest1", "Pirate"
            CFrameQuest = CFrame.new(-1141.07, 4.10, 3831.55)
            CFrameMon   = CFrame.new(-1103.51, 13.75, 3896.09)
        elseif MyLevel <= 59 then
            Mon, LevelQuest, NameQuest, NameMon = "Brute", 2, "BuggyQuest1", "Brute"
            CFrameQuest = CFrame.new(-1141.07, 4.10, 3831.55)
            CFrameMon   = CFrame.new(-1140.08, 14.81, 4322.92)
        elseif MyLevel <= 74 then
            Mon, LevelQuest, NameQuest, NameMon = "Desert Bandit", 1, "DesertQuest", "Desert Bandit"
            CFrameQuest = CFrame.new(894.49, 5.14, 4392.43)
            CFrameMon   = CFrame.new(924.80, 6.45, 4481.59)
        elseif MyLevel <= 89 then
            Mon, LevelQuest, NameQuest, NameMon = "Desert Officer", 2, "DesertQuest", "Desert Officer"
            CFrameQuest = CFrame.new(894.49, 5.14, 4392.43)
            CFrameMon   = CFrame.new(1608.28, 8.61, 4371.01)
        elseif MyLevel <= 99 then
            Mon, LevelQuest, NameQuest, NameMon = "Snow Bandit", 1, "SnowQuest", "Snow Bandit"
            CFrameQuest = CFrame.new(1389.74, 88.15, -1298.91)
            CFrameMon   = CFrame.new(1354.35, 87.27, -1393.95)
        elseif MyLevel <= 119 then
            Mon, LevelQuest, NameQuest, NameMon = "Snowman", 2, "SnowQuest", "Snowman"
            CFrameQuest = CFrame.new(1389.74, 88.15, -1298.91)
            CFrameMon   = CFrame.new(1201.64, 144.58, -1550.07)
        elseif MyLevel <= 149 then
            Mon, LevelQuest, NameQuest, NameMon = "Chief Petty Officer", 1, "MarineQuest2", "Chief Petty Officer"
            CFrameQuest = CFrame.new(-5039.59, 27.35, 4324.68)
            CFrameMon   = CFrame.new(-4881.23, 22.65, 4273.75)
        elseif MyLevel <= 174 then
            Mon, LevelQuest, NameQuest, NameMon = "Sky Bandit", 1, "SkyQuest", "Sky Bandit"
            CFrameQuest = CFrame.new(-4839.53, 716.37, -2619.44)
            CFrameMon   = CFrame.new(-4953.21, 295.74, -2899.23)
        elseif MyLevel <= 189 then
            Mon, LevelQuest, NameQuest, NameMon = "Dark Master", 2, "SkyQuest", "Dark Master"
            CFrameQuest = CFrame.new(-4839.53, 716.37, -2619.44)
            CFrameMon   = CFrame.new(-5259.84, 391.40, -2229.04)
        elseif MyLevel <= 209 then
            Mon, LevelQuest, NameQuest, NameMon = "Prisoner", 1, "PrisonerQuest", "Prisoner"
            CFrameQuest = CFrame.new(5308.93, 1.66, 475.12)
            CFrameMon   = CFrame.new(5098.97, -0.32, 474.24)
        elseif MyLevel <= 249 then
            Mon, LevelQuest, NameQuest, NameMon = "Dangerous Prisoner", 2, "PrisonerQuest", "Dangerous Prisoner"
            CFrameQuest = CFrame.new(5308.93, 1.66, 475.12)
            CFrameMon   = CFrame.new(5654.56, 15.63, 866.30)
        elseif MyLevel <= 274 then
            Mon, LevelQuest, NameQuest, NameMon = "Toga Warrior", 1, "ColosseumQuest", "Toga Warrior"
            CFrameQuest = CFrame.new(-1580.05, 6.35, -2986.48)
            CFrameMon   = CFrame.new(-1820.21, 51.68, -2740.67)
        elseif MyLevel <= 299 then
            Mon, LevelQuest, NameQuest, NameMon = "Gladiator", 2, "ColosseumQuest", "Gladiator"
            CFrameQuest = CFrame.new(-1580.05, 6.35, -2986.48)
            CFrameMon   = CFrame.new(-1292.84, 56.38, -3339.03)
        elseif MyLevel <= 324 then
            Mon, LevelQuest, NameQuest, NameMon = "Military Soldier", 1, "MagmaQuest", "Military Soldier"
            CFrameQuest = CFrame.new(-5313.37, 10.95, 8515.29)
            CFrameMon   = CFrame.new(-5411.16, 11.08, 8454.29)
        elseif MyLevel <= 374 then
            Mon, LevelQuest, NameQuest, NameMon = "Military Spy", 2, "MagmaQuest", "Military Spy"
            CFrameQuest = CFrame.new(-5313.37, 10.95, 8515.29)
            CFrameMon   = CFrame.new(-5802.87, 86.26, 8828.86)
        elseif MyLevel <= 399 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Warrior", 1, "FishmanQuest", "Fishman Warrior"
            CFrameQuest = CFrame.new(61122.65, 18.50, 1569.40)
            CFrameMon   = CFrame.new(60878.30, 18.48, 1543.76)
        elseif MyLevel <= 449 then
            Mon, LevelQuest, NameQuest, NameMon = "Fishman Commando", 2, "FishmanQuest", "Fishman Commando"
            CFrameQuest = CFrame.new(61122.65, 18.50, 1569.40)
            CFrameMon   = CFrame.new(61922.63, 18.48, 1493.93)
        elseif MyLevel <= 474 then
            Mon, LevelQuest, NameQuest, NameMon = "God's Guard", 1, "SkyExp1Quest", "God's Guard"
            CFrameQuest = CFrame.new(-4721.89, 843.87, -1949.97)
            CFrameMon   = CFrame.new(-4710.04, 845.28, -1927.31)
        elseif MyLevel <= 524 then
            Mon, LevelQuest, NameQuest, NameMon = "Shanda", 2, "SkyExp1Quest", "Shanda"
            CFrameQuest = CFrame.new(-7859.10, 5544.19, -381.48)
            CFrameMon   = CFrame.new(-7678.49, 5566.40, -497.22)
        elseif MyLevel <= 549 then
            Mon, LevelQuest, NameQuest, NameMon = "Royal Squad", 1, "SkyExp2Quest", "Royal Squad"
            CFrameQuest = CFrame.new(-7906.82, 5634.66, -1411.99)
            CFrameMon   = CFrame.new(-7624.25, 5658.13, -1467.35)
        elseif MyLevel <= 624 then
            Mon, LevelQuest, NameQuest, NameMon = "Royal Soldier", 2, "SkyExp2Quest", "Royal Soldier"
            CFrameQuest = CFrame.new(-7906.82, 5634.66, -1411.99)
            CFrameMon   = CFrame.new(-7836.75, 5645.66, -1790.62)
        elseif MyLevel <= 649 then
            Mon, LevelQuest, NameQuest, NameMon = "Galley Pirate", 1, "FountainQuest", "Galley Pirate"
            CFrameQuest = CFrame.new(5259.82, 37.35, 4050.03)
            CFrameMon   = CFrame.new(5551.02, 78.90, 3930.41)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Galley Captain", 2, "FountainQuest", "Galley Captain"
            CFrameQuest = CFrame.new(5259.82, 37.35, 4050.03)
            CFrameMon   = CFrame.new(5441.95, 42.50, 4950.09)
        end
    elseif World2 then
        if MyLevel <= 724 then
            Mon, LevelQuest, NameQuest, NameMon = "Raider", 1, "Area1Quest", "Raider"
            CFrameQuest = CFrame.new(-429.54, 71.77, 1836.18)
            CFrameMon   = CFrame.new(-728.33, 52.78, 2345.77)
        elseif MyLevel <= 774 then
            Mon, LevelQuest, NameQuest, NameMon = "Mercenary", 2, "Area1Quest", "Mercenary"
            CFrameQuest = CFrame.new(-429.54, 71.77, 1836.18)
            CFrameMon   = CFrame.new(-1004.32, 80.16, 1424.62)
        else
            Mon, LevelQuest, NameQuest, NameMon = "Swan Pirate", 1, "Area2Quest", "Swan Pirate"
            CFrameQuest = CFrame.new(638.44, 71.77, 918.28)
            CFrameMon   = CFrame.new(1068.66, 137.61, 1322.00)
        end
    else
        Mon, LevelQuest, NameQuest, NameMon = "Pirate Millionaire", 1, "PiratePortQuest", "Pirate Millionaire"
        CFrameQuest = CFrame.new(-450, 84, 5660)
        CFrameMon   = CFrame.new(-712.83, 98.58, 5711.95)
    end
end

-- ====================== ATTACK TARGET (fica em cima, não cai) ======================
local function AttackTarget(v)
    if not v or not IsAlive(v) then return end
    local mhrp = v:FindFirstChild("HumanoidRootPart")
    if not mhrp then return end

    if not v:GetAttribute("Locked") then
        v:SetAttribute("Locked", mhrp.CFrame)
    end
    PosMon = (v:GetAttribute("Locked") or mhrp.CFrame).Position
    BringEnemy(v)
    EquipWeapon(_G.SelectWeapon)

    local above
    local tool = Char and Char:FindFirstChildOfClass("Tool")
    if tool and tool.ToolTip == "Blox Fruit" then
        above = mhrp.CFrame * CFrame.new(0, 30, 0) * CFrame.Angles(0, math.rad(90), 0)
    else
        above = mhrp.CFrame * CFrame.new(0, 18, 0) * CFrame.Angles(0, math.rad(180), 0)
    end

    -- se já está perto, só cola o CFrame (sem tween) pra não oscilar
    if Root and (Root.Position - above.Position).Magnitude > 12 then
        TweenPlayer(above)
    elseif Root then
        Root.CFrame = above
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ====================== AUTO FARM LEVEL (Relz) ======================
task.spawn(function()
    while task.wait(0.15) do
        if not _G.AutoFarmLevel then
            StopTween()
            continue
        end

        pcall(function()
            if not Root or not Char then return end
            CheckQuest()

            local questGui = LP.PlayerGui.Main.Quest
            local questTitle = ""
            pcall(function()
                questTitle = questGui.Container.QuestTitle.Title.Text
            end)

            -- quest errada → abandona
            if questGui.Visible and NameMon and not string.find(questTitle, NameMon) then
                Remotes.CommF_:InvokeServer("AbandonQuest")
                task.wait(0.25)
            end

            if not questGui.Visible then
                -- pega quest (Relz chama remoto; se longe, anda até o NPC)
                if Root and CFrameQuest and (Root.Position - CFrameQuest.Position).Magnitude > 20 then
                    TweenPlayer(CFrameQuest)
                end
                Remotes.CommF_:InvokeServer("StartQuest", NameQuest, LevelQuest)
                task.wait(0.35)
            else
                -- farm
                local enemies = workspace:FindFirstChild("Enemies")
                local found = false
                if enemies and Mon then
                    for _, v in ipairs(enemies:GetChildren()) do
                        if v.Name == Mon and IsAlive(v) and v:FindFirstChild("HumanoidRootPart") then
                            found = true
                            AttackTarget(v)
                            break
                        end
                    end
                end
                if not found and CFrameMon then
                    TweenPlayer(CFrameMon * CFrame.new(0, 8, 0))
                end
            end
        end)
    end
end)

-- ====================== GG-UI ======================
local UI_URL = "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
local GGUI = loadstring(game:HttpGet(UI_URL))()
if not GGUI or type(GGUI.MakeWindow) ~= "function" then
    warn("[BF] Falha GG-UI")
    return
end

local Win = GGUI:MakeWindow({
    Title = "Auto Farm Estável v4",
    SubTitle = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or 1),
    ScriptFolder = "AutoFarmEstavel"
})

local TabFarm = Win:MakeTab({ Title = "Farm" })
local TabCfg  = Win:MakeTab({ Title = "Config" })

TabFarm:AddToggle({
    Title = "Auto Farm Level",
    Description = "Quest + farm (Relz logic)",
    Default = false,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if v then _G.Seriality = true else StopTween() end
    end
})

TabFarm:AddToggle({
    Title = "Seriality (Ataque)",
    Description = "AttackNoCoolDown",
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

TabCfg:AddButton({
    Title = "Equipar Arma",
    Callback = function() EquipWeapon(_G.SelectWeapon) end
})

print("[Auto Farm Estável v4] PartTele + Relz quest + Banana attack")
