repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.5)

-- ════════════════════════════════════════
--  SERVIÇOS
-- ════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")

local LP  = Players.LocalPlayer
local Char, Humanoid, HRP

local function RefreshChar(c)
    Char     = c
    Humanoid = c:WaitForChild("Humanoid")
    HRP      = c:WaitForChild("HumanoidRootPart")
end
if LP.Character then RefreshChar(LP.Character) end
LP.CharacterAdded:Connect(RefreshChar)

local Remotes       = ReplicatedStorage.Remotes
local Enemies       = workspace:WaitForChild("Enemies")
local NetFolder     = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RERegAtk      = NetFolder:WaitForChild("RE/RegisterAttack")
local RERegHit      = NetFolder:WaitForChild("RE/RegisterHit")
local NetSeed       = NetFolder:FindFirstChild("seed")

-- XOR anti-detecção (Banana t55)
local xorRemote, xorAttr
local function FindXorRemote()
    for _, fname in ipairs({"Util","Common","Remotes","Assets","FX"}) do
        local f = ReplicatedStorage:FindFirstChild(fname)
        if not f then continue end
        for _, c in ipairs(f:GetChildren()) do
            if c:IsA("RemoteEvent") and c:GetAttribute("Id") then
                xorRemote=c; xorAttr=c:GetAttribute("Id")
            end
        end
        f.ChildAdded:Connect(function(c)
            if c:IsA("RemoteEvent") and c:GetAttribute("Id") then
                xorRemote=c; xorAttr=c:GetAttribute("Id")
            end
        end)
    end
end
task.spawn(FindXorRemote)

-- COMBAT_REMOTE_THREAD + SendHitsToServer
local combatFlag = false
local SendHitsToServer = nil
pcall(function()
    combatFlag = require(ReplicatedStorage.Modules.Flags).COMBAT_REMOTE_THREAD or false
end)
if getsenv then
    task.spawn(function()
        local ps = LP:WaitForChild("PlayerScripts", 10)
        local ls = ps and ps:FindFirstChildOfClass("LocalScript")
        if ls then
            local ok, env = pcall(getsenv, ls)
            if ok and env and env._G then SendHitsToServer = env._G.SendHitsToServer end
        end
    end)
end

local World1 = game.PlaceId==2753915549 or game.PlaceId==85211729168715
local World2 = game.PlaceId==4442272183 or game.PlaceId==79091703265657
local World3 = game.PlaceId==7449423635 or game.PlaceId==100117331123089
local CurrentSea = World1 and 1 or World2 and 2 or World3 and 3 or 1

pcall(function() Remotes.CommF_:InvokeServer("SetTeam","Pirates") end)
pcall(function() require(ReplicatedStorage.Util.CameraShaker):Stop() end)

-- ════════════════════════════════════════
--  GLOBALS
-- ════════════════════════════════════════
_G.Seriality    = false
_G.Level        = false
_G.AutoFarmNear = false
_G.FarmBoss     = false
_G.BringMob     = true
_G.SelectWeapon = "Melee"
_G.FarmDistance = 25
_G.AutoFarmChest= false
_G.AutoStats    = false
_G.AutoSnipeFruit=false
_G.ESP_Players  = false
_G.ESP_Mobs     = false
_G.ESP_Chests   = false
_G.ESP_Fruits   = false
_G.AntiAFK      = true
_G.InfiniteJump = false
_G.FPSBoost     = false
_G.StatsMap     = {Melee=true,Defense=true,Sword=false,Gun=false,["Demon Fruit"]=false}
_G.StatChunk    = 3
_G.FindBoss     = "The Gorilla King"
_G.AutoBuso     = true
_G.KillAuraPlayers = false
getgenv().TweenSpeedNear = 180
getgenv().TweenSpeedFar  = 150   -- mesmo default do Banana
getgenv().OnFarm = false
getgenv()._G_WasOnFarm = false

-- quest vars
local Mon, LevelQuest, NameQuest, NameMon
local CFrameQuest, CFrameMon
local PosMon = nil
local _B = true

-- ════════════════════════════════════════
--  SHOULDTWEEN / BODYCLIP
--  Exatamente como o Banana:
--  shouldTween atualizado num loop separado
--  BodyClip = BodyVelocity no HRP do PLAYER
-- ════════════════════════════════════════
local shouldTween = false

local function AnyFarmActive()
    return _G.Level or _G.AutoFarmNear or _G.FarmBoss
        or _G.AutoFarmChest or _G.AutoSnipeFruit
end

task.spawn(function()
    while task.wait() do
        pcall(function()
            if AnyFarmActive() then
                shouldTween = true
                if HRP then
                    if not HRP:FindFirstChild("BodyClip") then
                        local bv       = Instance.new("BodyVelocity")
                        bv.Name        = "BodyClip"
                        bv.MaxForce    = Vector3.new(100000,100000,100000)
                        bv.Velocity    = Vector3.zero
                        bv.Parent      = HRP
                    end
                end
            else
                shouldTween = false
                if HRP then
                    local bc = HRP:FindFirstChild("BodyClip")
                    if bc then bc:Destroy() end
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  TWEEN PLAYER — FIEL AO BANANA
--
--  Part fica no WORKSPACE (não no Char).
--  Loop cola HRP na Part com tolerância 200 studs
--  (se HRP sair >200 da Part, reseta Part pro HRP).
--  OnFarm = true DEPOIS que tween completa (task.spawn).
--  shouldTween=false cancela o tween no meio.
--  notween = snap direto no HRP.
-- ════════════════════════════════════════
local Part = Instance.new("Part", workspace)
Part.Size         = Vector3.new(1,1,1)
Part.Name         = "BF_TweenAnchor"
Part.Anchored     = true
Part.CanCollide   = false
Part.CanTouch     = false
Part.Transparency = 1

-- limpa duplicata
do
    local existing = workspace:FindFirstChild(Part.Name)
    if existing and existing ~= Part then existing:Destroy() end
end

-- loop que sincroniza HRP com Part (igual Banana)
task.spawn(function()
    while true do
        task.wait()
        pcall(function()
            if getgenv().OnFarm then
                if not getgenv()._G_WasOnFarm then
                    getgenv()._G_WasOnFarm = true
                end
                if Part and Part.Parent == workspace then
                    local pp = LP.Character and LP.Character.PrimaryPart
                    if pp then
                        if (pp.Position - Part.Position).Magnitude <= 200 then
                            -- HRP cola na Part
                            pp.CFrame = CFrame.new(Part.Position)
                        else
                            -- muito longe: reseta Part pro HRP (lagback recovery)
                            Part.CFrame = pp.CFrame
                        end
                    end
                end
                -- noclip enquanto OnFarm
                local c = LP.Character
                if c then
                    for _, child in pairs(c:GetChildren()) do
                        if child:IsA("BasePart") then
                            child.CanCollide = false
                        end
                    end
                end
            elseif getgenv()._G_WasOnFarm then
                getgenv()._G_WasOnFarm = false
                local c = LP.Character
                if c then
                    for _, child in pairs(c:GetChildren()) do
                        if child:IsA("BasePart") then
                            child.CanCollide = true
                        end
                    end
                end
            end
        end)
    end
end)

-- OnFarm updater (igual Banana)
task.spawn(function()
    while task.wait() do
        if Part and Part.Parent == workspace then
            if shouldTween then
                getgenv().OnFarm = true
            else
                getgenv().OnFarm = false
            end
        else
            getgenv().OnFarm = false
        end
    end
end)

local function _tp(p53)
    local cFrame3
    if typeof(p53) == "Vector3" then
        cFrame3 = CFrame.new(p53)
    elseif typeof(p53) == "CFrame" then
        cFrame3 = p53
    elseif p53 and p53.CFrame then
        cFrame3 = p53.CFrame
    end
    if not cFrame3 then return end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end

    local HumanoidRootPart = LP.Character.HumanoidRootPart

    -- desliga OnFarm durante o tween (igual Banana)
    getgenv().OnFarm = false

    local Magnitude = (cFrame3.Position - HumanoidRootPart.Position).Magnitude
    local spd = Magnitude <= 15
        and (getgenv().TweenSpeedNear or 180)
        or  (getgenv().TweenSpeedFar  or 150)
    local tweenInfo = TweenInfo.new(Magnitude / spd, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Part, tweenInfo, {
        CFrame = CFrame.new(cFrame3.Position)
    })

    -- se sentado: ajusta Y da Part antes de twenar (igual Banana)
    if LP.Character.Humanoid.Sit then
        Part.CFrame = CFrame.new(Part.Position.X, cFrame3.Y, Part.Position.Z)
    end

    tween:Play()

    -- task.spawn monitora: cancela se shouldTween=false,
    -- liga OnFarm=true quando completa (igual Banana)
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

local function notween(cf)
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame = cf
    end
end

local function StopTween()
    getgenv().OnFarm = false
    shouldTween = false
end

-- ════════════════════════════════════════
--  EQUIP WEAPON
-- ════════════════════════════════════════
local function EquipWeapon(tip)
    tip = tip or _G.SelectWeapon
    if not Char or not Humanoid then return end
    local cur = Char:FindFirstChildOfClass("Tool")
    if cur and cur.ToolTip == tip then return end
    local bp = LP.Backpack
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.ToolTip == tip then
                Humanoid:EquipTool(t); return
            end
        end
    end
end

-- ════════════════════════════════════════
--  BRING ENEMY — Banana fiel
--  BodyVelocity nos mobs, sethiddenproperty,
--  isnetworkowner, traz todos do mesmo nome
-- ════════════════════════════════════════
local function isNetOwner(part)
    if isnetworkowner then return isnetworkowner(part) end
    return part.ReceiveAge == 0 and not part.Anchored and part.Velocity.Magnitude > 0
end

BringEnemy = function(mainMob)
    if not _B or not PosMon then return end
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(LP, "SimulationRadius", math.huge)
        end

        local pivot    = PosMon
        local mainName = mainMob and mainMob.Name or nil
        local allClose = false

        for _, child in ipairs(Enemies:GetChildren()) do
            if mainName and child.Name ~= mainName then continue end
            local hum = child:FindFirstChildOfClass("Humanoid")
            local hrp = child:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then continue end

            local dist = (hrp.Position - pivot).Magnitude
            if dist > 3000 then continue end

            -- BodyVelocity no mob (igual Banana)
            if not hrp:FindFirstChild("BodyVelocity") then
                local bv       = Instance.new("BodyVelocity")
                bv.Name        = "BodyVelocity"
                bv.MaxForce    = Vector3.new(1e9,1e9,1e9)
                bv.Velocity    = Vector3.zero
                bv.Parent      = hrp
            end

            if dist <= 10 then allClose = true end

            -- move só se não estiver já agrupado E for network owner
            if not allClose and isNetOwner(hrp) then
                hrp.CFrame = CFrame.new(pivot)
            end

            hrp.CanCollide = false
            hum.WalkSpeed  = 0
            hum.JumpPower  = 0
        end

        -- mob principal também
        if mainMob and mainMob:FindFirstChild("HumanoidRootPart") then
            mainMob.HumanoidRootPart.CanCollide = false
            if mainMob:FindFirstChild("Humanoid") then
                mainMob.Humanoid.WalkSpeed = 0
                mainMob.Humanoid.JumpPower = 0
            end
        end
    end)
end

-- ════════════════════════════════════════
--  T9.KILL — SetAttribute Locked, ponto fixo
-- ════════════════════════════════════════
local function Kill(mob, flag)
    if not mob or not flag then return end
    if not mob:GetAttribute("Locked") then
        mob:SetAttribute("Locked", mob.HumanoidRootPart.CFrame)
    end
    PosMon = mob:GetAttribute("Locked").Position
    BringEnemy(mob)
    EquipWeapon(_G.SelectWeapon)

    local tool    = Char and Char:FindFirstChildOfClass("Tool")
    local toolTip = tool and tool.ToolTip or ""

    if toolTip == "Blox Fruit" then
        _tp(mob.HumanoidRootPart.CFrame * CFrame.new(0,30,0) * CFrame.Angles(0,math.rad(90),0))
    else
        _tp(mob.HumanoidRootPart.CFrame * CFrame.new(0,_G.FarmDistance,0) * CFrame.Angles(0,math.rad(180),0))
    end
end

-- ════════════════════════════════════════
--  ATAQUE — do teu script (teu AttackNoCoolDown)
--  com multi-mob: pega TODOS em raio 60
--  + t55 XOR+seed no Heartbeat
-- ════════════════════════════════════════
local function GetNearbyTargets(radius)
    if not Char then return {} end
    local pos     = Char:GetPivot().Position
    local targets = {}
    for _, child in ipairs(Enemies:GetChildren()) do
        local hum = child:FindFirstChild("Humanoid")
        local hrp = child:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0
           and not child:GetAttribute("IsBoat")
           and (hrp.Position - pos).Magnitude <= (radius or 60) then
            table.insert(targets, child)
        end
    end
    if _G.KillAuraPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    if (hrp.Position - Char:GetPivot().Position).Magnitude <= (radius or 60) then
                        table.insert(targets, p.Character)
                    end
                end
            end
        end
    end
    return targets
end

local function GetTargetParts(targets)
    local parts  = {}
    local mainPt = nil
    local limbs  = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
    for _, mob in ipairs(targets) do
        local part = mob:FindFirstChild(limbs[math.random(#limbs)])
                  or mob:FindFirstChild("Head")
                  or mob.PrimaryPart
        if part then
            table.insert(parts, {mob, part})
            if not mainPt then mainPt = part end
        end
    end
    return parts, mainPt
end

-- t54: fast attack multi-mob
local function ExecuteFastAttack()
    if not Char or not Char:FindFirstChildOfClass("Tool") then return end
    local targets = GetNearbyTargets(60)
    if #targets == 0 then return end
    local parts, mainPt = GetTargetParts(targets)
    if not mainPt then return end

    RERegAtk:FireServer(2e-9)

    if combatFlag and SendHitsToServer then
        SendHitsToServer(mainPt, parts)
    else
        RERegHit:FireServer(mainPt, parts)
    end
end

-- t55: Heartbeat XOR+seed
local function ExecuteXorAttack()
    if not Char or not Char:FindFirstChildOfClass("Tool") then return end
    local tool  = Char:FindFirstChildOfClass("Tool")
    local wType = tool and tool:GetAttribute("WeaponType")
    if wType ~= "Melee" and wType ~= "Sword" then return end

    local targets = GetNearbyTargets(60)
    if #targets == 0 then return end
    local parts, mainPt = GetTargetParts(targets)
    if not mainPt then return end

    local seedVal = 0
    if NetSeed then pcall(function() seedVal = NetSeed:InvokeServer() or 0 end) end

    RERegAtk:FireServer()
    local head = targets[1]:FindFirstChild("Head")
    if head then RERegHit:FireServer(head, parts, {}) end

    if xorRemote and xorAttr and cloneref then
        pcall(function()
            local v = math.floor(workspace:GetServerTimeNow()/10%10)+1
            local rh = string.gsub("RE/RegisterHit",".",function(c)
                return string.char(bit32.bxor(string.byte(c),v))
            end)
            local xv = bit32.bxor(xorAttr+909090, seedVal*2)
            cloneref(xorRemote):FireServer(rh, xv, head, parts)
        end)
    end
end

-- Blox Fruit M1 (do teu script, igual Banana)
local function Actived()
    pcall(function()
        local tool = Char and Char:FindFirstChildOfClass("Tool")
        if not tool then return end
        for _, conn in next, getconnections(tool.Activated) do
            if typeof(conn.Function) == "function" then
                getupvalues(conn.Function)
            end
        end
    end)
end

local function get_Monster()
    if not Char or not HRP then return false end
    for _, child in ipairs(Enemies:GetChildren()) do
        local head = child:FindFirstChild("Head") or child:FindFirstChild("UpperTorso")
        if child:FindFirstChild("HumanoidRootPart") and head
           and (head.Position - HRP.Position).Magnitude <= 50 then
            return true
        end
    end
    return false
end

-- t54 loop (praticamente instantâneo, igual Banana Rate=2e-9)
task.spawn(function()
    while task.wait(2e-9) do
        pcall(function()
            if not _G.Seriality then return end
            ExecuteFastAttack()
        end)
    end
end)

-- t55 Heartbeat
RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.Seriality then return end
        ExecuteXorAttack()
        local tool = Char and Char:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == "Blox Fruit" and get_Monster() then
            local lcr = tool:FindFirstChild("LeftClickRemote")
            if lcr then
                Actived()
                lcr:FireServer(Vector3.new(0.01,-500,0.01),1,true)
                lcr:FireServer(false)
            end
        end
    end)
end)

-- ════════════════════════════════════════
--  QUEST HELPERS
-- ════════════════════════════════════════
local function HasQuestVisible()
    local tracked = LP.PlayerGui:FindFirstChild("TrackedQuestFrame")
    if tracked and tracked.Enabled then
        local f = tracked:FindFirstChild("Frame")
        if f and f.Visible then return true end
    end
    local main = LP.PlayerGui:FindFirstChild("Main")
    local q    = main and main:FindFirstChild("Quest")
    return q and q.Visible == true
end

local function GetQuestTitle()
    local tracked = LP.PlayerGui:FindFirstChild("TrackedQuestFrame")
    if tracked and tracked.Enabled then
        local f = tracked:FindFirstChild("Frame")
        if f and f.Visible then
            local h = f:FindFirstChild("header")
            local l = h and h:FindFirstChild("textLabel")
            if l and l.Text ~= "" then return tostring(l.Text) end
        end
    end
    local ok, t = pcall(function()
        return LP.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
    end)
    return ok and tostring(t) or ""
end

local function HasCorrectQuest(name)
    if not name or not HasQuestVisible() then return false end
    local t = GetQuestTitle()
    return t ~= "" and t:lower():find(name:lower(), 1, true) ~= nil
end

local function StartQuestWait(qname, qdata, mobName)
    if HasCorrectQuest(mobName) then return true end
    pcall(function() Remotes.CommF_:InvokeServer("StartQuest", qname, qdata) end)
    local t0 = os.clock()
    repeat task.wait(0.2) until HasCorrectQuest(mobName) or os.clock()-t0>3
    return HasCorrectQuest(mobName)
end

-- ════════════════════════════════════════
--  CHECK QUEST — Sea 1 / 2 / 3 completo
-- ════════════════════════════════════════
local function CheckQuest()
    local lv = LP.Data.Level.Value
    if World1 then
        if     lv<=9   then Mon,LevelQuest,NameQuest,NameMon="Bandit",1,"BanditQuest1","Bandit"; CFrameQuest=CFrame.new(1059.37,15.45,1550.42); CFrameMon=CFrame.new(1045.96,27,1560.82)
        elseif lv<=14  then Mon,LevelQuest,NameQuest,NameMon="Monkey",1,"JungleQuest","Monkey"; CFrameQuest=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1448.52,67.85,11.47)
        elseif lv<=29  then Mon,LevelQuest,NameQuest,NameMon="Gorilla",2,"JungleQuest","Gorilla"; CFrameQuest=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1129.88,40.46,-525.42)
        elseif lv<=39  then Mon,LevelQuest,NameQuest,NameMon="Pirate",1,"BuggyQuest1","Pirate"; CFrameQuest=CFrame.new(-1141.07,4.1,3831.55); CFrameMon=CFrame.new(-1103.51,13.75,3896.09)
        elseif lv<=59  then Mon,LevelQuest,NameQuest,NameMon="Brute",2,"BuggyQuest1","Brute"; CFrameQuest=CFrame.new(-1141.07,4.1,3831.55); CFrameMon=CFrame.new(-1140.08,14.81,4322.92)
        elseif lv<=74  then Mon,LevelQuest,NameQuest,NameMon="Desert Bandit",1,"DesertQuest","Desert Bandit"; CFrameQuest=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(924.8,6.45,4481.59)
        elseif lv<=89  then Mon,LevelQuest,NameQuest,NameMon="Desert Officer",2,"DesertQuest","Desert Officer"; CFrameQuest=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(1608.28,8.61,4371.01)
        elseif lv<=99  then Mon,LevelQuest,NameQuest,NameMon="Snow Bandit",1,"SnowQuest","Snow Bandit"; CFrameQuest=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1354.35,87.27,-1393.95)
        elseif lv<=119 then Mon,LevelQuest,NameQuest,NameMon="Snowman",2,"SnowQuest","Snowman"; CFrameQuest=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1201.64,144.58,-1550.07)
        elseif lv<=149 then Mon,LevelQuest,NameQuest,NameMon="Chief Petty Officer",1,"MarineQuest2","Chief Petty Officer"; CFrameQuest=CFrame.new(-5039.59,27.35,4324.68); CFrameMon=CFrame.new(-4881.23,22.65,4273.75)
        elseif lv<=174 then Mon,LevelQuest,NameQuest,NameMon="Sky Bandit",1,"SkyQuest","Sky Bandit"; CFrameQuest=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-4953.21,295.74,-2899.23)
        elseif lv<=189 then Mon,LevelQuest,NameQuest,NameMon="Dark Master",2,"SkyQuest","Dark Master"; CFrameQuest=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-5259.84,391.4,-2229.04)
        elseif lv<=209 then Mon,LevelQuest,NameQuest,NameMon="Prisoner",1,"PrisonerQuest","Prisoner"; CFrameQuest=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5098.97,-0.32,474.24)
        elseif lv<=249 then Mon,LevelQuest,NameQuest,NameMon="Dangerous Prisoner",2,"PrisonerQuest","Dangerous Prisoner"; CFrameQuest=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5654.56,15.63,866.3)
        elseif lv<=274 then Mon,LevelQuest,NameQuest,NameMon="Toga Warrior",1,"ColosseumQuest","Toga Warrior"; CFrameQuest=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1820.21,51.68,-2740.67)
        elseif lv<=299 then Mon,LevelQuest,NameQuest,NameMon="Gladiator",2,"ColosseumQuest","Gladiator"; CFrameQuest=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1292.84,56.38,-3339.03)
        elseif lv<=324 then Mon,LevelQuest,NameQuest,NameMon="Military Soldier",1,"MagmaQuest","Military Soldier"; CFrameQuest=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5411.16,11.08,8454.29)
        elseif lv<=374 then Mon,LevelQuest,NameQuest,NameMon="Military Spy",2,"MagmaQuest","Military Spy"; CFrameQuest=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5802.87,86.26,8828.86)
        elseif lv<=399 then Mon,LevelQuest,NameQuest,NameMon="Fishman Warrior",1,"FishmanQuest","Fishman Warrior"; CFrameQuest=CFrame.new(61122.65,18.5,1569.4); CFrameMon=CFrame.new(60878.3,18.48,1543.76)
        elseif lv<=449 then Mon,LevelQuest,NameQuest,NameMon="Fishman Commando",2,"FishmanQuest","Fishman Commando"; CFrameQuest=CFrame.new(61122.65,18.5,1569.4); CFrameMon=CFrame.new(61922.63,18.48,1493.93)
        elseif lv<=474 then Mon,LevelQuest,NameQuest,NameMon="God's Guard",1,"SkyExp1Quest","God's Guard"; CFrameQuest=CFrame.new(-4721.89,843.87,-1949.97); CFrameMon=CFrame.new(-4710.04,845.28,-1927.31)
        elseif lv<=524 then Mon,LevelQuest,NameQuest,NameMon="Shanda",2,"SkyExp1Quest","Shanda"; CFrameQuest=CFrame.new(-7859.1,5544.19,-381.48); CFrameMon=CFrame.new(-7678.49,5566.4,-497.22)
        elseif lv<=549 then Mon,LevelQuest,NameQuest,NameMon="Royal Squad",1,"SkyExp2Quest","Royal Squad"; CFrameQuest=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7624.25,5658.13,-1467.35)
        elseif lv<=624 then Mon,LevelQuest,NameQuest,NameMon="Royal Soldier",2,"SkyExp2Quest","Royal Soldier"; CFrameQuest=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7836.75,5645.66,-1790.62)
        elseif lv<=649 then Mon,LevelQuest,NameQuest,NameMon="Galley Pirate",1,"FountainQuest","Galley Pirate"; CFrameQuest=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5551.02,78.9,3930.41)
        else                Mon,LevelQuest,NameQuest,NameMon="Galley Captain",2,"FountainQuest","Galley Captain"; CFrameQuest=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5441.95,42.5,4950.09)
        end
    elseif World2 then
        if     lv<=724  then Mon,LevelQuest,NameQuest,NameMon="Raider",1,"Area1Quest","Raider"; CFrameQuest=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-728.33,52.78,2345.77)
        elseif lv<=774  then Mon,LevelQuest,NameQuest,NameMon="Mercenary",2,"Area1Quest","Mercenary"; CFrameQuest=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-1004.32,80.16,1424.62)
        elseif lv<=799  then Mon,LevelQuest,NameQuest,NameMon="Swan Pirate",1,"Area2Quest","Swan Pirate"; CFrameQuest=CFrame.new(638.44,71.77,918.28); CFrameMon=CFrame.new(1068.66,137.61,1322.11)
        elseif lv<=874  then Mon,LevelQuest,NameQuest,NameMon="Factory Staff",2,"Area2Quest","Factory Staff"; CFrameQuest=CFrame.new(632.7,73.11,918.67); CFrameMon=CFrame.new(73.08,81.86,-27.47)
        elseif lv<=899  then Mon,LevelQuest,NameQuest,NameMon="Marine Lieutenant",1,"MarineQuest3","Marine Lieutenant"; CFrameQuest=CFrame.new(-2440.8,71.71,-3216.07); CFrameMon=CFrame.new(-2821.37,75.9,-3070.09)
        elseif lv<=949  then Mon,LevelQuest,NameQuest,NameMon="Marine Captain",2,"MarineQuest3","Marine Captain"; CFrameQuest=CFrame.new(-2440.8,71.71,-3216.07); CFrameMon=CFrame.new(-1861.23,80.18,-3254.7)
        elseif lv<=974  then Mon,LevelQuest,NameQuest,NameMon="Zombie",1,"ZombieQuest","Zombie"; CFrameQuest=CFrame.new(-5497.06,47.59,-795.24); CFrameMon=CFrame.new(-5657.78,78.97,-928.69)
        elseif lv<=999  then Mon,LevelQuest,NameQuest,NameMon="Vampire",2,"ZombieQuest","Vampire"; CFrameQuest=CFrame.new(-5497.06,47.59,-795.24); CFrameMon=CFrame.new(-6037.67,32.18,-1340.66)
        elseif lv<=1049 then Mon,LevelQuest,NameQuest,NameMon="Snow Trooper",1,"SnowMountainQuest","Snow Trooper"; CFrameQuest=CFrame.new(609.86,400.12,-5372.26); CFrameMon=CFrame.new(549.15,427.39,-5563.7)
        elseif lv<=1099 then Mon,LevelQuest,NameQuest,NameMon="Winter Warrior",2,"SnowMountainQuest","Winter Warrior"; CFrameQuest=CFrame.new(609.86,400.12,-5372.26); CFrameMon=CFrame.new(1142.75,475.64,-5199.42)
        elseif lv<=1174 then Mon,LevelQuest,NameQuest,NameMon="Horned Warrior",2,"IceSideQuest","Horned Warrior"; CFrameQuest=CFrame.new(-6064.07,15.24,-4902.98); CFrameMon=CFrame.new(-6341.37,15.95,-5723.16)
        elseif lv<=1249 then Mon,LevelQuest,NameQuest,NameMon="Ship Deckhand",1,"ShipQuest1","Ship Deckhand"; CFrameQuest=CFrame.new(1008,125,32911); CFrameMon=CFrame.new(1180,140,32990)
        elseif lv<=1499 then Mon,LevelQuest,NameQuest,NameMon="Sea Soldier",1,"FrostQuest","Sea Soldier"; CFrameQuest=CFrame.new(-3054,237,-10145); CFrameMon=CFrame.new(-3300,240,-10400)
        end
    elseif World3 then
        if     lv<=1574 then Mon,LevelQuest,NameQuest,NameMon="Pirate Millionaire",1,"PiratePortQuest","Pirate Millionaire"; CFrameQuest=CFrame.new(-450,84,5660); CFrameMon=CFrame.new(-712.83,98.58,5711.95)
        elseif lv<=1699 then Mon,LevelQuest,NameQuest,NameMon="Pistol Billionaire",2,"PiratePortQuest","Pistol Billionaire"; CFrameQuest=CFrame.new(-450,84,5660); CFrameMon=CFrame.new(-723.43,147.43,5931.99)
        elseif lv<=1824 then Mon,LevelQuest,NameQuest,NameMon="Female Islander",1,"AmazonQuest","Female Islander"; CFrameQuest=CFrame.new(5832,51,-1100); CFrameMon=CFrame.new(4692.79,797.98,858.85)
        elseif lv<=1974 then Mon,LevelQuest,NameQuest,NameMon="Marine Commodore",1,"MarineTreeIsland","Marine Commodore"; CFrameQuest=CFrame.new(2180,28,-6740); CFrameMon=CFrame.new(2401,123,-7589)
        elseif lv<=2074 then Mon,LevelQuest,NameQuest,NameMon="Reborn Skeleton",1,"HauntedQuest1","Reborn Skeleton"; CFrameQuest=CFrame.new(-9515,142,5536); CFrameMon=CFrame.new(-8750,140,5900)
        elseif lv<=2199 then Mon,LevelQuest,NameQuest,NameMon="Living Zombie",1,"HauntedQuest2","Living Zombie"; CFrameQuest=CFrame.new(-9515,142,5536); CFrameMon=CFrame.new(-10150,140,5950)
        elseif lv<=2299 then Mon,LevelQuest,NameQuest,NameMon="Candy Rebel",1,"CandyQuest1","Candy Rebel"; CFrameQuest=CFrame.new(-1149,13,-14445); CFrameMon=CFrame.new(-1000,20,-14200)
        elseif lv<=2449 then Mon,LevelQuest,NameQuest,NameMon="Sweet Thief",1,"CandyQuest2","Sweet Thief"; CFrameQuest=CFrame.new(-1149,13,-14445); CFrameMon=CFrame.new(-1200,20,-14700)
        elseif lv<=2599 then Mon,LevelQuest,NameQuest,NameMon="Isle Outlaw",1,"TikiQuest1","Isle Outlaw"; CFrameQuest=CFrame.new(-16547,55,-172); CFrameMon=CFrame.new(-16800,30,-150)
        else                 Mon,LevelQuest,NameQuest,NameMon="Dojo Fighter",1,"DragonDojoQuest","Dojo Fighter"; CFrameQuest=CFrame.new(-16547,55,-172); CFrameMon=CFrame.new(-16300,60,-350)
        end
    end
end

-- ════════════════════════════════════════
--  FARM LOOP PRINCIPAL
-- ════════════════════════════════════════
local Sec = 0.1
task.spawn(function()
    while task.wait(Sec) do
        if not _G.Level then _G.Seriality=false; continue end
        pcall(function()
            if not HRP then return end
            CheckQuest()
            if HasQuestVisible() and not HasCorrectQuest(NameMon) then
                _G.Seriality=false
                Remotes.CommF_:InvokeServer("AbandonQuest")
                task.wait(0.2); return
            end
            if not HasCorrectQuest(NameMon) then
                _G.Seriality=false
                local distNPC = CFrameQuest and (HRP.Position-CFrameQuest.Position).Magnitude or 999
                if distNPC > 15 then _tp(CFrameQuest)
                else StartQuestWait(NameQuest,LevelQuest,NameMon) end
                return
            end
            local target, bestD = nil, math.huge
            for _, v in ipairs(Enemies:GetChildren()) do
                if v.Name==Mon then
                    local hum=v:FindFirstChild("Humanoid")
                    local hrp=v:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health>0 and hrp then
                        local d=(hrp.Position-HRP.Position).Magnitude
                        if d<bestD then bestD=d; target=v end
                    end
                end
            end
            if target then
                Kill(target, true)
                local mhrp=target:FindFirstChild("HumanoidRootPart")
                _G.Seriality = mhrp and (HRP.Position-mhrp.Position).Magnitude<=70 or false
            else
                _G.Seriality=false
                if CFrameMon then _tp(CFrameMon) end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  AUTO FARM NEAREST
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait() do
        if not _G.AutoFarmNear then _G.Seriality=false; continue end
        pcall(function()
            for _, child in ipairs(Enemies:GetChildren()) do
                local hum=child:FindFirstChild("Humanoid")
                local hrp=child:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health>0 and hrp then
                    while hum.Health>0 and _G.AutoFarmNear do
                        task.wait()
                        Kill(child, true)
                        _G.Seriality = (HRP.Position-hrp.Position).Magnitude<=70
                    end
                    child:SetAttribute("Locked",nil)
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  BOSS FARM — separado por sea
-- ════════════════════════════════════════
local BossData = {
    [1] = {
        {Name="The Gorilla King", CF=CFrame.new(-1088.76,8.13,-488.56)},
        {Name="Bobby",            CF=CFrame.new(-1087.38,46.95,4040.15)},
        {Name="The Saw",          CF=CFrame.new(5325.1,7.04,719.57)},
        {Name="Yeti",             CF=CFrame.new(1218.8,138,-1488.03)},
        {Name="Vice Admiral",     CF=CFrame.new(-5006.55,88,4353.16)},
        {Name="Warden",           CF=CFrame.new(5278.05,2.15,944.1)},
        {Name="Chief Warden",     CF=CFrame.new(5206.93,1,814.98)},
        {Name="Swan",             CF=CFrame.new(638,72,918)},
        {Name="Magma Admiral",    CF=CFrame.new(-5765.9,82.92,8718.3)},
        {Name="Fishman Lord",     CF=CFrame.new(61260.15,30.95,1193.43)},
        {Name="Wysper",           CF=CFrame.new(-7866.13,5576.43,-546.75)},
        {Name="Thunder God",      CF=CFrame.new(-7994.98,5761.03,-2088.65)},
        {Name="Cyborg",           CF=CFrame.new(6094.02,73.77,3825.73)},
        {Name="Saber Expert",     CF=CFrame.new(-4867,390,-1942)},
        {Name="Mob Leader",       CF=CFrame.new(1059,15,1550)},
    },
    [2] = {
        {Name="Darkbeard",        CF=CFrame.new(-5081.35,85.22,4257.36)},
        {Name="Don Swan",         CF=CFrame.new(638,72,918)},
        {Name="Smoke Admiral",    CF=CFrame.new(-429,71,1836)},
        {Name="Cursed Captain",   CF=CFrame.new(-3054,237,-10145)},
        {Name="Ice Admiral",      CF=CFrame.new(609,401,-5372)},
        {Name="Diamond",          CF=CFrame.new(-429,71,1836)},
        {Name="Jeremy",           CF=CFrame.new(-429,71,1836)},
        {Name="Fajita",           CF=CFrame.new(638,72,918)},
        {Name="Order",            CF=CFrame.new(-3054,237,-10145)},
        {Name="Greybeard",        CF=CFrame.new(-429,71,1836)},
    },
    [3] = {
        {Name="Cake Queen",       CF=CFrame.new(-11000,850,490)},
        {Name="Soul Reaper",      CF=CFrame.new(-9800,142,5700)},
        {Name="rip_indra",        CF=CFrame.new(-28220,350,-2000)},
        {Name="Dragon",           CF=CFrame.new(-28000,20,11000)},
        {Name="Stone",            CF=CFrame.new(-16547,55,-172)},
        {Name="Kilo Admiral",     CF=CFrame.new(-289,44,5580)},
        {Name="Longma",           CF=CFrame.new(-16300,60,-350)},
        {Name="Beautiful Pirate", CF=CFrame.new(5832,51,-1100)},
        {Name="Captain Elephant", CF=CFrame.new(-9515,142,5536)},
        {Name="Leviathan",        CF=CFrame.new(-22000,20,-10000)},
        {Name="Hydra Leader",     CF=CFrame.new(5657,1013,-335)},
    },
}

local seaBosses = BossData[CurrentSea] or {}
local seaBossNames = {}
local seaBossCFMap  = {}
for _, b in ipairs(seaBosses) do
    table.insert(seaBossNames, b.Name)
    seaBossCFMap[b.Name] = b.CF
end

task.spawn(function()
    while task.wait(Sec) do
        if not _G.FarmBoss then _G.Seriality=false; continue end
        pcall(function()
            if not HRP then return end
            for _, child in ipairs(Enemies:GetChildren()) do
                if child.Name==_G.FindBoss then
                    local hum=child:FindFirstChild("Humanoid")
                    if hum and hum.Health>0 then
                        Kill(child, true)
                        local hrp=child:FindFirstChild("HumanoidRootPart")
                        _G.Seriality = hrp and (HRP.Position-hrp.Position).Magnitude<=70 or false
                        return
                    end
                end
            end
            _G.Seriality=false
            local pos=seaBossCFMap[_G.FindBoss]
            if pos then _tp(pos) end
        end)
    end
end)

-- ════════════════════════════════════════
--  AUTO BUSO HAKI
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(5) do
        if _G.AutoBuso and AnyFarmActive() then
            pcall(function() Remotes.CommF_:InvokeServer("Buso") end)
        end
    end
end)

-- ════════════════════════════════════════
--  AUTO STATS
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(1.5) do
        if not _G.AutoStats then continue end
        pcall(function()
            local d=LP:FindFirstChild("Data"); if not d then return end
            local pts=d:FindFirstChild("Points") and d.Points.Value or 0
            if pts<=0 then return end
            local chunk=math.min(pts,_G.StatChunk or 3)
            for stat,en in pairs(_G.StatsMap) do
                if en then Remotes.CommF_:InvokeServer("AddPoint",stat,chunk); task.wait(0.08) end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  AUTO CHEST
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(0.4) do
        if not _G.AutoFarmChest then continue end
        pcall(function()
            if not HRP then return end
            local nearest,nearD=nil,math.huge
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and string.find(obj.Name,"Chest")
                   and obj:FindFirstChild("TouchInterest") then
                    local d=(HRP.Position-obj.Position).Magnitude
                    if d<nearD then nearest=obj; nearD=d end
                end
            end
            if nearest then
                _tp(nearest.CFrame*CFrame.new(0,2,0))
                if nearD<=12 then
                    pcall(function() firetouchinterest(HRP,nearest,0) end)
                    pcall(function() firetouchinterest(HRP,nearest,1) end)
                    task.wait(0.2)
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  AUTO SNIPE FRUTA
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(1) do
        if not _G.AutoSnipeFruit then continue end
        pcall(function()
            if not HRP then return end
            for _,obj in ipairs(workspace:GetChildren()) do
                if string.find(obj.Name,"Fruit") then
                    local handle=obj:FindFirstChild("Handle") or (obj:IsA("BasePart") and obj)
                    if handle then
                        _tp(handle.CFrame)
                        if (HRP.Position-handle.Position).Magnitude<=10 then
                            pcall(function() firetouchinterest(HRP,handle,0) end)
                            pcall(function() firetouchinterest(HRP,handle,1) end)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════
local espCache={}
local function CreateESP(obj,label,color)
    if espCache[obj] then return end
    pcall(function()
        local hl=Instance.new("Highlight")
        hl.FillColor=color; hl.OutlineColor=Color3.new(1,1,1)
        hl.FillTransparency=0.5; hl.OutlineTransparency=0.3
        hl.Adornee=obj; hl.Parent=LP.PlayerGui
        local bb=Instance.new("BillboardGui")
        bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,160,0,28)
        bb.Adornee=obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart) or obj
        bb.Parent=LP.PlayerGui
        local lbl=Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text=label; lbl.TextColor3=color
        lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
        lbl.TextStrokeTransparency=0.4; lbl.Parent=bb
        espCache[obj]={hl,bb}
        obj.AncestryChanged:Connect(function()
            if not obj:IsDescendantOf(workspace) then
                for _,v in pairs(espCache[obj] or {}) do pcall(function() v:Destroy() end) end
                espCache[obj]=nil
            end
        end)
    end)
end
local function ClearESP()
    for obj,parts in pairs(espCache) do
        for _,v in pairs(parts) do pcall(function() v:Destroy() end) end
        espCache[obj]=nil
    end
end
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not HRP then return end
            if _G.ESP_Players then
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=LP and p.Character then
                        local hr=p.Character:FindFirstChild("HumanoidRootPart")
                        local hm=p.Character:FindFirstChildOfClass("Humanoid")
                        if hr and hm and hm.Health>0 then
                            CreateESP(p.Character,p.Name.." ["..math.floor((HRP.Position-hr.Position).Magnitude).."m]",Color3.fromRGB(0,230,255))
                        end
                    end
                end
            end
            if _G.ESP_Mobs then
                for _,mob in ipairs(Enemies:GetChildren()) do
                    local mh=mob:FindFirstChildOfClass("Humanoid")
                    if mh and mh.Health>0 then
                        CreateESP(mob,mob.Name.." [HP:"..math.floor(mh.Health).."]",Color3.fromRGB(255,120,50))
                    end
                end
            end
            if _G.ESP_Chests then
                for _,obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(obj.Name,"Chest") and obj:FindFirstChild("TouchInterest") then
                        CreateESP(obj,"Chest ["..math.floor((HRP.Position-obj.Position).Magnitude).."m]",Color3.fromRGB(255,215,0))
                    end
                end
            end
            if _G.ESP_Fruits then
                for _,obj in ipairs(workspace:GetChildren()) do
                    if string.find(obj.Name,"Fruit") then
                        CreateESP(obj,obj.Name,Color3.fromRGB(220,80,255))
                    end
                end
            end
            if not _G.ESP_Players and not _G.ESP_Mobs and not _G.ESP_Chests and not _G.ESP_Fruits then
                ClearESP()
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  INFINITE JUMP + ANTI-AFK
-- ════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
LP.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ════════════════════════════════════════
--  GG-UI
-- ════════════════════════════════════════
local GGUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
))()
if not GGUI or type(GGUI.MakeWindow) ~= "function" then
    warn("[BF] GG-UI falhou"); return
end

local Win = GGUI:MakeWindow({
    Title        = "BF Script",
    SubTitle     = "Sea "..CurrentSea.." | Lv."..(LP.Data and LP.Data.Level.Value or "?"),
    ScriptFolder = "BFScript"
})

-- ── FARM ───────────────────────────────
local tFarm = Win:MakeTab({Title="Farm"})
tFarm:AddSection("Auto Farm Level")
tFarm:AddToggle({Title="Auto Farm Level", Default=false, Callback=function(v)
    _G.Level=v; if not v then _G.Seriality=false end
end})
tFarm:AddToggle({Title="Seriality (Ataque)", Default=false, Callback=function(v) _G.Seriality=v end})
tFarm:AddToggle({Title="Bring Mobs", Default=true, Callback=function(v) _G.BringMob=v; _B=v end})
tFarm:AddToggle({Title="Auto Buso Haki", Default=true, Callback=function(v) _G.AutoBuso=v end})

tFarm:AddSection("Farm Nearest (sem quest)")
tFarm:AddToggle({Title="Auto Farm Nearest", Default=false, Callback=function(v)
    _G.AutoFarmNear=v; if not v then _G.Seriality=false end
end})

tFarm:AddSection("Boss — Sea "..CurrentSea)
tFarm:AddDropdown({
    Title="Boss", Options=seaBossNames,
    Default=seaBossNames[1] or "The Gorilla King",
    Callback=function(v) _G.FindBoss=v end
})
tFarm:AddToggle({Title="Auto Farm Boss", Default=false, Callback=function(v)
    _G.FarmBoss=v; if not v then _G.Seriality=false end
end})

tFarm:AddSection("Itens")
tFarm:AddToggle({Title="Auto Pegar Baús", Default=false, Callback=function(v) _G.AutoFarmChest=v end})
tFarm:AddToggle({Title="Auto Snipe Fruta", Default=false, Callback=function(v) _G.AutoSnipeFruit=v end})

-- ── STATS ──────────────────────────────
local tStats = Win:MakeTab({Title="Stats"})
tStats:AddSection("Auto Stats")
tStats:AddToggle({Title="Auto Stats", Default=false, Callback=function(v) _G.AutoStats=v end})
tStats:AddSlider({Title="Pontos por Rodada", Min=1, Max=10, Default=3, Increment=1,
    Callback=function(v) _G.StatChunk=v end})
for _, stat in ipairs({"Melee","Defense","Sword","Gun","Demon Fruit"}) do
    tStats:AddToggle({Title=stat, Default=_G.StatsMap[stat] or false,
        Callback=function(v) _G.StatsMap[stat]=v end})
end

-- ── ESP ────────────────────────────────
local tESP = Win:MakeTab({Title="ESP"})
tESP:AddSection("Visibilidade")
tESP:AddToggle({Title="ESP Players", Default=false, Callback=function(v) _G.ESP_Players=v; if not v then ClearESP() end end})
tESP:AddToggle({Title="ESP Mobs",    Default=false, Callback=function(v) _G.ESP_Mobs=v;    if not v then ClearESP() end end})
tESP:AddToggle({Title="ESP Baús",    Default=false, Callback=function(v) _G.ESP_Chests=v;  if not v then ClearESP() end end})
tESP:AddToggle({Title="ESP Frutas",  Default=false, Callback=function(v) _G.ESP_Fruits=v;  if not v then ClearESP() end end})
tESP:AddButton({Title="Limpar ESP",  Callback=ClearESP})

-- ── SHOP ───────────────────────────────
local tShop = Win:MakeTab({Title="Shop"})
tShop:AddSection("Espadas")
tShop:AddDropdown({Title="Espada",
    Options={"Cutlass","Triple Katana","Bisento","Saber","Dark Blade","Yama","Pole (1st Form)",
             "Pole (2nd Form)","Saddi","Wando","Hariharakesh","Canvander","Gravity Blade",
             "Cursed Dual Katana","Tushita","Enma","True Triple Katana","Soul Cane","Shark Saw","Dragon Trident"},
    Callback=function(v) _G.ShopSword=v end})
tShop:AddButton({Title="Comprar Espada", Callback=function()
    pcall(function() Remotes.CommF_:InvokeServer("BuySword",_G.ShopSword or "Cutlass") end)
end})
tShop:AddSection("Acessórios")
tShop:AddDropdown({Title="Acessório",
    Options={"Lei","Tomoe Ring","Swan Glasses","Musketeer Hat","Valkyrie Helmet","Ghoul Mask",
             "Dragon Scales","Angel Wings","Shark Tooth Necklace","Golden Crown","Trench Coat",
             "Cyborg Glasses","Marine Coat","Swan Coat"},
    Callback=function(v) _G.ShopAcc=v end})
tShop:AddButton({Title="Comprar Acessório", Callback=function()
    pcall(function() Remotes.CommF_:InvokeServer("BuyAccessory",_G.ShopAcc or "Lei") end)
end})
tShop:AddSection("Codes")
tShop:AddButton({Title="Resgatar Codes", Callback=function()
    task.spawn(function()
        for _,c in ipairs({"SUB2GAMERROBOT_EXP1","KITT_RESET","Sub2Fer999","StrawHatMaine",
            "Sub2OfficialNoobie","THEGREATACE","AXIORE","TantaiGaming","BLUXXY","fudd10",
            "BIGNEWS","CHANDLER","FUDD10_V2","3BVISITS"}) do
            pcall(function() Remotes.CommF_:InvokeServer("Redeem",c) end); task.wait(0.3)
        end
        Win:Notify({Title="Codes",Content="Resgatados!",Duration=3})
    end)
end})

-- ── TELEPORT ───────────────────────────
-- Teleport usa notween (snap direto) para evitar o bug
-- do _tp ser cancelado pelo shouldTween=false fora do farm
local teleMap = {
    [1]={
        ["Starter Island"]=CFrame.new(1059,15,1550),
        ["Jungle"]=CFrame.new(-1448,68,11),
        ["Pirate Village"]=CFrame.new(-1141,4,3831),
        ["Desert"]=CFrame.new(924,6,4481),
        ["Snow Mountain"]=CFrame.new(1354,87,-1393),
        ["Marine Fortress"]=CFrame.new(-5035,28,4324),
        ["Sky Island"]=CFrame.new(-4842,717,2623),
        ["Prison"]=CFrame.new(5310,0,474),
        ["Colosseum"]=CFrame.new(-1577,7,2984),
        ["Magma Village"]=CFrame.new(-5316,12,8517),
        ["Underwater City"]=CFrame.new(61122,18,1569),
        ["Upper Skylands"]=CFrame.new(-4721,845,1953),
    },
    [2]={
        ["Kingdom of Rose"]=CFrame.new(-429,71,1836),
        ["Green Zone"]=CFrame.new(638,72,918),
        ["Graveyard"]=CFrame.new(-5497,48,-795),
        ["Snow Mountain S2"]=CFrame.new(609,401,-5372),
        ["Hot & Cold"]=CFrame.new(1008,125,32911),
        ["Cursed Ship"]=CFrame.new(-3054,237,-10145),
        ["Marine HQ"]=CFrame.new(-2440,72,-3217),
    },
    [3]={
        ["Pirate Port"]=CFrame.new(-289,44,5580),
        ["Amazon Lily"]=CFrame.new(5832,51,-1100),
        ["Great Tree"]=CFrame.new(2180,28,-6740),
        ["Haunted Castle"]=CFrame.new(-9515,142,5536),
        ["Candy Island"]=CFrame.new(-1149,13,-14445),
        ["Tiki Outpost"]=CFrame.new(-16547,55,-172),
        ["Dragon Dojo"]=CFrame.new(-16300,60,-350),
    },
}
local seaMap   = teleMap[CurrentSea] or teleMap[1]
local destKeys = {}; for k in pairs(seaMap) do table.insert(destKeys,k) end; table.sort(destKeys)
local selDest  = destKeys[1]

local tTP = Win:MakeTab({Title="Teleport"})
tTP:AddSection("Ilhas — Sea "..CurrentSea)
tTP:AddDropdown({Title="Destino", Options=destKeys, Default=destKeys[1],
    Callback=function(v) selDest=v end})
tTP:AddButton({Title="Teleportar", Callback=function()
    -- usa notween pra TP manual (não depende de shouldTween/farm ativo)
    local cf=seaMap[selDest]
    if cf and HRP then notween(cf) end
end})
tTP:AddButton({Title="Parar Movimento", Callback=function()
    StopTween()
    if HRP then HRP.AssemblyLinearVelocity=Vector3.zero end
end})
tTP:AddSection("Servidor")
tTP:AddButton({Title="Server Hop", Callback=function()
    pcall(function()
        local d=game:GetService("HttpService"):JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
        )
        for _,s in ipairs(d.data or {}) do
            if s.playing<s.maxPlayers and s.id~=game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,s.id,LP); break
            end
        end
    end)
end})
tTP:AddButton({Title="Rejoin", Callback=function()
    game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
end})

-- ── CONFIG ─────────────────────────────
local tCfg = Win:MakeTab({Title="Config"})
tCfg:AddSection("Farm")
tCfg:AddDropdown({Title="Arma", Options={"Melee","Sword","Blox Fruit","Gun"}, Default="Melee",
    Callback=function(v) _G.SelectWeapon=v; EquipWeapon(v) end})
tCfg:AddSlider({Title="Altura sobre mob", Min=5, Max=60, Default=25, Increment=1,
    Callback=function(v) _G.FarmDistance=v end})
tCfg:AddSlider({Title="Tween Speed (curta ≤15)", Min=50, Max=400, Default=180, Increment=10,
    Callback=function(v) getgenv().TweenSpeedNear=v end})
tCfg:AddSlider({Title="Tween Speed (longa)", Min=50, Max=600, Default=150, Increment=10,
    Callback=function(v) getgenv().TweenSpeedFar=v end})
tCfg:AddSection("Misc")
tCfg:AddToggle({Title="Infinite Jump", Default=false, Callback=function(v) _G.InfiniteJump=v end})
tCfg:AddToggle({Title="Anti-AFK", Default=true, Callback=function(v) _G.AntiAFK=v end})
tCfg:AddToggle({Title="Kill Aura Players", Default=false, Callback=function(v) _G.KillAuraPlayers=v end})
tCfg:AddToggle({Title="FPS Boost", Default=false, Callback=function(v)
    if v then
        game:GetService("Lighting").GlobalShadows=false
        game:GetService("Lighting").FogEnd=9e9
        for _,p in ipairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") and not p.Parent:FindFirstChild("Humanoid") then
                pcall(function() p.Material=Enum.Material.SmoothPlastic end)
            end
        end
    end
end})
tCfg:AddButton({Title="Desligar Tudo", Callback=function()
    _G.Level=false; _G.AutoFarmNear=false; _G.FarmBoss=false
    _G.AutoFarmChest=false; _G.AutoSnipeFruit=false; _G.AutoStats=false
    _G.Seriality=false; StopTween(); ClearESP()
    Win:Notify({Title="Script",Content="Tudo desligado.",Duration=3})
end})

Win:Notify({Title="BF Script",Content="Sea "..CurrentSea.." | OK",Duration=4})
print("[BF Script] Sea "..CurrentSea.." | Lv."..(LP.Data and LP.Data.Level.Value or "?"))
