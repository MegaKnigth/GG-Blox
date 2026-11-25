repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
task.wait(0.5)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Char, Humanoid, HumanoidRootPart

local function SetupCharacter(c)
    Char             = c
    Humanoid         = c:WaitForChild("Humanoid")
    HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end
if LP.Character then SetupCharacter(LP.Character) end
LP.CharacterAdded:Connect(function(c)
    SetupCharacter(c)
    -- limpa BodyVelocity antiga ao respawnar
    task.wait(0.5)
    local bv = HumanoidRootPart and HumanoidRootPart:FindFirstChild("BF_Lock")
    if bv then bv:Destroy() end
end)

local Remotes        = ReplicatedStorage.Remotes
local Enemies        = workspace:WaitForChild("Enemies")
local Net            = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

pcall(function() Remotes.CommF_:InvokeServer("SetTeam","Pirates") end)

local PlaceId = game.PlaceId
local World1  = (PlaceId == 2753915549 or PlaceId == 85211729168715)
local World2  = (PlaceId == 4442272183 or PlaceId == 79091703265657)
local World3  = (PlaceId == 7449423635 or PlaceId == 100117331123089)
local CurrentSea = World1 and 1 or World2 and 2 or World3 and 3 or 1

_G.Seriality        = false
_G.AutoFarmLevel    = false
_G.BringMob         = true
_G.SelectWeapon     = "Melee"
_G.FarmDistance     = 25
_G.PlayerTweenSpeed = 300

local Mon, LevelQuest, NameQuest, NameMon
local CFrameQuest, CFrameMon

-- ════════════════════════════════════════
--  PONTO FIXO DE FARM
--  FIX #2: salvo UMA VEZ por mob, não rastreado em
--  tempo real. Isso elimina o player seguindo o mob.
-- ════════════════════════════════════════
local fixedFarmCF  = nil   -- CFrame fixo onde o player fica (acima do mob)
local fixedMobRef  = nil   -- referência ao mob atual
local ARRIVE_DIST  = 6     -- studs: considera "chegou ao ponto de farm"

-- ════════════════════════════════════════
--  BODY VELOCITY — anti-deslize
--  FIX #3: BodyVelocity persistente no HRP do player
--  enquanto AutoFarmLevel=true e está no ponto de farm.
--  Zera velocidade real, não só AssemblyLinearVelocity.
-- ════════════════════════════════════════
local function GetOrCreateBV()
    if not HumanoidRootPart then return nil end
    local bv = HumanoidRootPart:FindFirstChild("BF_Lock")
    if not bv then
        bv          = Instance.new("BodyVelocity")
        bv.Name     = "BF_Lock"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero
        bv.Parent   = HumanoidRootPart
    end
    return bv
end

local function RemoveBV()
    local bv = HumanoidRootPart and HumanoidRootPart:FindFirstChild("BF_Lock")
    if bv then bv:Destroy() end
end

-- ════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if _G.AutoFarmLevel and Char then
                for _, v in ipairs(Char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  TWEEN PLAYER
--  FIX #1: tween não é recriado a cada iteração do farm.
--  Recria SOMENTE quando:
--    a) mob trocou (fixedMobRef mudou)
--    b) destino mudou mais que DEST_THRESHOLD
--    c) tween completou naturalmente
--
--  Durante o tween: steppedConn cola HRP na part.
--  Depois que completa: BV segura o player no ponto fixo.
--  Sem conflito — Stepped e Heartbeat nunca disputam juntos.
-- ════════════════════════════════════════
local DEST_THRESHOLD = 12   -- studs: só recriar se destino mudou mais que isso

local tweenRunning = false
local tweenObj     = nil
local steppedConn  = nil
local tweenDest    = nil
local tweenPart    = nil

local function StopTween(keepBV)
    tweenRunning = false
    tweenDest    = nil
    if tweenObj then
        pcall(function() tweenObj:Cancel() end)
        tweenObj = nil
    end
    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
    if tweenPart and tweenPart.Parent then
        tweenPart:Destroy()
    end
    tweenPart = nil
    if not keepBV then RemoveBV() end
end

local function TweenPlayer(dest)
    if not Char or not Humanoid or Humanoid.Health <= 0
       or not HumanoidRootPart or not dest then return end

    local dist = (dest.Position - HumanoidRootPart.Position).Magnitude

    -- muito perto: snap direto, sem tween
    if dist < 5 then
        StopTween(true)
        HumanoidRootPart.CFrame = dest
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        GetOrCreateBV().Velocity = Vector3.zero
        return
    end

    -- tween já rodando pro mesmo destino: NÃO recria
    if tweenRunning and tweenDest then
        local delta = (tweenDest.Position - dest.Position).Magnitude
        if delta < DEST_THRESHOLD then return end   -- destino não mudou o suficiente
    end

    -- destino mudou de verdade ou não tinha tween: recria
    StopTween(false)

    local part        = Instance.new("Part")
    part.Name         = "BF_TweenPart"
    part.Size         = Vector3.new(1,1,1)
    part.Anchored     = true
    part.Transparency = 1
    part.CanCollide   = false
    part.CFrame       = HumanoidRootPart.CFrame
    part.Parent       = Char
    tweenPart = part

    tweenRunning = true
    tweenDest    = dest

    -- Stepped: cola HRP na part enquanto tween roda
    -- Separado do Heartbeat (ataque) → sem conflito
    steppedConn = RunService.Stepped:Connect(function()
        if not tweenRunning or not part.Parent then
            if steppedConn then steppedConn:Disconnect(); steppedConn = nil end
            return
        end
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = part.CFrame
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    local duration = dist / math.max(_G.PlayerTweenSpeed or 300, 50)
    tweenObj = TweenService:Create(part,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = dest })

    tweenObj:Play()
    tweenObj.Completed:Connect(function(state)
        tweenRunning = false
        tweenDest    = nil
        if steppedConn then steppedConn:Disconnect(); steppedConn = nil end
        if HumanoidRootPart and state == Enum.PlaybackState.Completed then
            HumanoidRootPart.CFrame = dest
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            -- BV segura o player no ponto de chegada
            local bv = GetOrCreateBV()
            if bv then bv.Velocity = Vector3.zero end
        end
        if part and part.Parent then part:Destroy() end
        tweenObj  = nil
        tweenPart = nil
    end)
end

-- ════════════════════════════════════════
--  QUEST HELPERS
-- ════════════════════════════════════════
local function HasQuestVisible()
    local tracked = LP.PlayerGui:FindFirstChild("TrackedQuestFrame")
    if tracked then
        local frame = tracked:FindFirstChild("Frame")
        if frame and tracked.Enabled and frame.Visible then return true end
    end
    local main = LP.PlayerGui:FindFirstChild("Main")
    local q    = main and main:FindFirstChild("Quest")
    return q and q.Visible == true
end

local function GetQuestTitle()
    local tracked = LP.PlayerGui:FindFirstChild("TrackedQuestFrame")
    if tracked then
        local frame = tracked:FindFirstChild("Frame")
        if frame and frame.Visible then
            local header = frame:FindFirstChild("header")
            local lbl    = header and header:FindFirstChild("textLabel")
            if lbl and lbl:IsA("TextLabel") and lbl.Text ~= "" then
                return tostring(lbl.Text)
            end
        end
    end
    local ok, text = pcall(function()
        return LP.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
    end)
    return ok and text and tostring(text) or ""
end

local function HasCorrectQuest(nameMon)
    if not nameMon or not HasQuestVisible() then return false end
    local title = GetQuestTitle()
    return title ~= "" and string.find(string.lower(title), string.lower(nameMon), 1, true) ~= nil
end

local function StartQuestWait(qname, qdata, nameMon)
    if HasCorrectQuest(nameMon) then return true end
    pcall(function() Remotes.CommF_:InvokeServer("StartQuest", qname, qdata) end)
    local deadline = os.clock() + 3
    repeat
        if HasCorrectQuest(nameMon) then return true end
        task.wait(0.25)
    until os.clock() >= deadline
    return HasCorrectQuest(nameMon)
end

-- ════════════════════════════════════════
--  EQUIP
-- ════════════════════════════════════════
local function EquipWeapon(tip)
    tip = tip or _G.SelectWeapon
    if not Char or not Humanoid then return end
    local cur = Char:FindFirstChildOfClass("Tool")
    if cur and cur.ToolTip == tip then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == tip then
            Humanoid:EquipTool(t); return
        end
    end
end

-- ════════════════════════════════════════
--  BRING ENEMY
--  Traz todos os mobs do mesmo tipo pro
--  ponto fixo — não usa o mob alvo como pivot
--  (evita feedback loop)
-- ════════════════════════════════════════
local function BringEnemy()
    if not _G.BringMob or not fixedFarmCF or not Mon then return end
    local pivot = fixedFarmCF.Position
    for _, child in ipairs(Enemies:GetChildren()) do
        if child.Name ~= Mon then continue end
        local hum = child:FindFirstChildOfClass("Humanoid")
        local hrp = child:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0
           and (hrp.Position - pivot).Magnitude <= 350 then
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(LP, "SimulationRadius", math.huge)
                end
                hrp.CFrame     = CFrame.new(pivot)
                hrp.CanCollide = false
                hum.WalkSpeed  = 0
                hum.JumpPower  = 0
            end)
        end
    end
end

-- ════════════════════════════════════════
--  ATAQUE
-- ════════════════════════════════════════
local _SendHitsToServer = nil
local _usesNewCombat    = false

pcall(function()
    _usesNewCombat = require(ReplicatedStorage.Modules.Flags).COMBAT_REMOTE_THREAD or false
end)

-- tenta pegar SendHitsToServer do getsenv (sistema novo BF)
if getsenv then
    task.spawn(function()
        local ps = LP:WaitForChild("PlayerScripts", 10)
        if not ps then return end
        local ls = ps:FindFirstChildOfClass("LocalScript")
        if not ls then
            local conn
            conn = ps.ChildAdded:Connect(function(c)
                if c:IsA("LocalScript") then ls = c; conn:Disconnect() end
            end)
            task.wait(5)
        end
        if ls then
            local ok, env = pcall(getsenv, ls)
            if ok and env and env._G then
                _SendHitsToServer = env._G.SendHitsToServer
            end
        end
    end)
end

local function IsAlive(e)
    local h = e and e:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

local function AttackNoCoolDown()
    if not Char then return end
    local pos     = Char:GetPivot().Position
    local targets = {}
    local mainT   = nil

    for _, enemy in ipairs(Enemies:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp and IsAlive(enemy) and not enemy:GetAttribute("IsBoat")
           and (hrp.Position - pos).Magnitude <= 60 then
            local limbs = {"RightLowerArm","RightUpperArm","LeftLowerArm",
                           "LeftUpperArm","RightHand","LeftHand"}
            local part  = enemy:FindFirstChild(limbs[math.random(#limbs)])
                       or enemy.PrimaryPart or hrp
            if part then
                table.insert(targets, {enemy, part})
                if not mainT then mainT = part end
            end
        end
    end

    if not mainT then return end
    RegisterAttack:FireServer(0)

    if _usesNewCombat and _SendHitsToServer then
        _SendHitsToServer(mainT, targets)
    else
        RegisterHit:FireServer(mainT, targets)
    end
end

-- Blox Fruit M1
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

-- Heartbeat de ataque — SEPARADO do Stepped do tween
-- os dois nunca escrevem CFrame ao mesmo tempo
RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.Seriality then return end
        AttackNoCoolDown()
        local tool = Char and Char:FindFirstChildOfClass("Tool")
        if tool and tool.ToolTip == "Blox Fruit" then
            local lcr = tool:FindFirstChild("LeftClickRemote")
            if lcr then
                Actived()
                lcr:FireServer(Vector3.new(0.01,-500,0.01),1,true)
                lcr:FireServer(false)
            end
        end
    end)
end)

pcall(function() require(ReplicatedStorage.Util.CameraShaker):Stop() end)

-- ════════════════════════════════════════
--  CHECK QUEST — completo Sea 1/2/3
-- ════════════════════════════════════════
local function CheckQuest()
    local lv = LP.Data.Level.Value
    if World1 then
        if     lv <= 9   then Mon,LevelQuest,NameQuest,NameMon="Bandit",1,"BanditQuest1","Bandit"; CFrameQuest=CFrame.new(1059.37,15.45,1550.42); CFrameMon=CFrame.new(1045.96,27,1560.82)
        elseif lv <= 14  then Mon,LevelQuest,NameQuest,NameMon="Monkey",1,"JungleQuest","Monkey"; CFrameQuest=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1448.52,67.85,11.47)
        elseif lv <= 29  then Mon,LevelQuest,NameQuest,NameMon="Gorilla",2,"JungleQuest","Gorilla"; CFrameQuest=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1129.88,40.46,-525.42)
        elseif lv <= 39  then Mon,LevelQuest,NameQuest,NameMon="Pirate",1,"BuggyQuest1","Pirate"; CFrameQuest=CFrame.new(-1141.07,4.1,3831.55); CFrameMon=CFrame.new(-1103.51,13.75,3896.09)
        elseif lv <= 59  then Mon,LevelQuest,NameQuest,NameMon="Brute",2,"BuggyQuest1","Brute"; CFrameQuest=CFrame.new(-1141.07,4.1,3831.55); CFrameMon=CFrame.new(-1140.08,14.81,4322.92)
        elseif lv <= 74  then Mon,LevelQuest,NameQuest,NameMon="Desert Bandit",1,"DesertQuest","Desert Bandit"; CFrameQuest=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(924.8,6.45,4481.59)
        elseif lv <= 89  then Mon,LevelQuest,NameQuest,NameMon="Desert Officer",2,"DesertQuest","Desert Officer"; CFrameQuest=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(1608.28,8.61,4371.01)
        elseif lv <= 99  then Mon,LevelQuest,NameQuest,NameMon="Snow Bandit",1,"SnowQuest","Snow Bandit"; CFrameQuest=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1354.35,87.27,-1393.95)
        elseif lv <= 119 then Mon,LevelQuest,NameQuest,NameMon="Snowman",2,"SnowQuest","Snowman"; CFrameQuest=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1201.64,144.58,-1550.07)
        elseif lv <= 149 then Mon,LevelQuest,NameQuest,NameMon="Chief Petty Officer",1,"MarineQuest2","Chief Petty Officer"; CFrameQuest=CFrame.new(-5039.59,27.35,4324.68); CFrameMon=CFrame.new(-4881.23,22.65,4273.75)
        elseif lv <= 174 then Mon,LevelQuest,NameQuest,NameMon="Sky Bandit",1,"SkyQuest","Sky Bandit"; CFrameQuest=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-4953.21,295.74,-2899.23)
        elseif lv <= 189 then Mon,LevelQuest,NameQuest,NameMon="Dark Master",2,"SkyQuest","Dark Master"; CFrameQuest=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-5259.84,391.4,-2229.04)
        elseif lv <= 209 then Mon,LevelQuest,NameQuest,NameMon="Prisoner",1,"PrisonerQuest","Prisoner"; CFrameQuest=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5098.97,-0.32,474.24)
        elseif lv <= 249 then Mon,LevelQuest,NameQuest,NameMon="Dangerous Prisoner",2,"PrisonerQuest","Dangerous Prisoner"; CFrameQuest=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5654.56,15.63,866.3)
        elseif lv <= 274 then Mon,LevelQuest,NameQuest,NameMon="Toga Warrior",1,"ColosseumQuest","Toga Warrior"; CFrameQuest=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1820.21,51.68,-2740.67)
        elseif lv <= 299 then Mon,LevelQuest,NameQuest,NameMon="Gladiator",2,"ColosseumQuest","Gladiator"; CFrameQuest=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1292.84,56.38,-3339.03)
        elseif lv <= 324 then Mon,LevelQuest,NameQuest,NameMon="Military Soldier",1,"MagmaQuest","Military Soldier"; CFrameQuest=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5411.16,11.08,8454.29)
        elseif lv <= 374 then Mon,LevelQuest,NameQuest,NameMon="Military Spy",2,"MagmaQuest","Military Spy"; CFrameQuest=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5802.87,86.26,8828.86)
        elseif lv <= 399 then Mon,LevelQuest,NameQuest,NameMon="Fishman Warrior",1,"FishmanQuest","Fishman Warrior"; CFrameQuest=CFrame.new(61122.65,18.5,1569.4); CFrameMon=CFrame.new(60878.3,18.48,1543.76); if _G.AutoFarmLevel and (CFrameQuest.Position-HumanoidRootPart.Position).Magnitude>10000 then pcall(function() Remotes.CommF_:InvokeServer("requestEntrance",Vector3.new(61163.85,11.68,1819.78)) end) end
        elseif lv <= 449 then Mon,LevelQuest,NameQuest,NameMon="Fishman Commando",2,"FishmanQuest","Fishman Commando"; CFrameQuest=CFrame.new(61122.65,18.5,1569.4); CFrameMon=CFrame.new(61922.63,18.48,1493.93); if _G.AutoFarmLevel and (CFrameQuest.Position-HumanoidRootPart.Position).Magnitude>10000 then pcall(function() Remotes.CommF_:InvokeServer("requestEntrance",Vector3.new(61163.85,11.68,1819.78)) end) end
        elseif lv <= 474 then Mon,LevelQuest,NameQuest,NameMon="God's Guard",1,"SkyExp1Quest","God's Guard"; CFrameQuest=CFrame.new(-4721.89,843.87,-1949.97); CFrameMon=CFrame.new(-4710.04,845.28,-1927.31); if _G.AutoFarmLevel then pcall(function() Remotes.CommF_:InvokeServer("requestEntrance",Vector3.new(-4607.82,872.54,-1667.56)) end) end
        elseif lv <= 524 then Mon,LevelQuest,NameQuest,NameMon="Shanda",2,"SkyExp1Quest","Shanda"; CFrameQuest=CFrame.new(-7859.1,5544.19,-381.48); CFrameMon=CFrame.new(-7678.49,5566.4,-497.22); if _G.AutoFarmLevel then pcall(function() Remotes.CommF_:InvokeServer("requestEntrance",Vector3.new(-7894.62,5547.14,-380.29)) end) end
        elseif lv <= 549 then Mon,LevelQuest,NameQuest,NameMon="Royal Squad",1,"SkyExp2Quest","Royal Squad"; CFrameQuest=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7624.25,5658.13,-1467.35)
        elseif lv <= 624 then Mon,LevelQuest,NameQuest,NameMon="Royal Soldier",2,"SkyExp2Quest","Royal Soldier"; CFrameQuest=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7836.75,5645.66,-1790.62)
        elseif lv <= 649 then Mon,LevelQuest,NameQuest,NameMon="Galley Pirate",1,"FountainQuest","Galley Pirate"; CFrameQuest=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5551.02,78.9,3930.41)
        else                   Mon,LevelQuest,NameQuest,NameMon="Galley Captain",2,"FountainQuest","Galley Captain"; CFrameQuest=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5441.95,42.5,4950.09)
        end
    elseif World2 then
        if     lv <= 724  then Mon,LevelQuest,NameQuest,NameMon="Raider",1,"Area1Quest","Raider"; CFrameQuest=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-728.33,52.78,2345.77)
        elseif lv <= 774  then Mon,LevelQuest,NameQuest,NameMon="Mercenary",2,"Area1Quest","Mercenary"; CFrameQuest=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-1004.32,80.16,1424.62)
        elseif lv <= 799  then Mon,LevelQuest,NameQuest,NameMon="Swan Pirate",1,"Area2Quest","Swan Pirate"; CFrameQuest=CFrame.new(638.44,71.77,918.28); CFrameMon=CFrame.new(1068.66,137.61,1322.11)
        elseif lv <= 874  then Mon,LevelQuest,NameQuest,NameMon="Factory Staff",2,"Area2Quest","Factory Staff"; CFrameQuest=CFrame.new(632.7,73.11,918.67); CFrameMon=CFrame.new(73.08,81.86,-27.47)
        elseif lv <= 899  then Mon,LevelQuest,NameQuest,NameMon="Marine Lieutenant",1,"MarineQuest3","Marine Lieutenant"; CFrameQuest=CFrame.new(-2440.8,71.71,-3216.07); CFrameMon=CFrame.new(-2821.37,75.9,-3070.09)
        elseif lv <= 949  then Mon,LevelQuest,NameQuest,NameMon="Marine Captain",2,"MarineQuest3","Marine Captain"; CFrameQuest=CFrame.new(-2440.8,71.71,-3216.07); CFrameMon=CFrame.new(-1861.23,80.18,-3254.7)
        elseif lv <= 974  then Mon,LevelQuest,NameQuest,NameMon="Zombie",1,"ZombieQuest","Zombie"; CFrameQuest=CFrame.new(-5497.06,47.59,-795.24); CFrameMon=CFrame.new(-5657.78,78.97,-928.69)
        elseif lv <= 999  then Mon,LevelQuest,NameQuest,NameMon="Vampire",2,"ZombieQuest","Vampire"; CFrameQuest=CFrame.new(-5497.06,47.59,-795.24); CFrameMon=CFrame.new(-6037.67,32.18,-1340.66)
        elseif lv <= 1049 then Mon,LevelQuest,NameQuest,NameMon="Snow Trooper",1,"SnowMountainQuest","Snow Trooper"; CFrameQuest=CFrame.new(609.86,400.12,-5372.26); CFrameMon=CFrame.new(549.15,427.39,-5563.7)
        elseif lv <= 1099 then Mon,LevelQuest,NameQuest,NameMon="Winter Warrior",2,"SnowMountainQuest","Winter Warrior"; CFrameQuest=CFrame.new(609.86,400.12,-5372.26); CFrameMon=CFrame.new(1142.75,475.64,-5199.42)
        elseif lv <= 1124 then Mon,LevelQuest,NameQuest,NameMon="Lab Subordinate",1,"IceSideQuest","Lab Subordinate"; CFrameQuest=CFrame.new(-6064.07,15.24,-4902.98); CFrameMon=CFrame.new(-5707.47,15.95,-4513.39)
        elseif lv <= 1174 then Mon,LevelQuest,NameQuest,NameMon="Horned Warrior",2,"IceSideQuest","Horned Warrior"; CFrameQuest=CFrame.new(-6064.07,15.24,-4902.98); CFrameMon=CFrame.new(-6341.37,15.95,-5723.16)
        elseif lv <= 1199 then Mon,LevelQuest,NameQuest,NameMon="Magma Ninja",1,"MagmaNinjaQuest","Magma Ninja"; CFrameQuest=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5411.16,11.08,8454.29)
        elseif lv <= 1249 then Mon,LevelQuest,NameQuest,NameMon="Ship Deckhand",1,"ShipQuest1","Ship Deckhand"; CFrameQuest=CFrame.new(1008,125,32911); CFrameMon=CFrame.new(1180,140,32990); if _G.AutoFarmLevel then pcall(function() Remotes.CommF_:InvokeServer("requestEntrance",Vector3.new(923.21,126.98,32852.83)) end) end
        elseif lv <= 1299 then Mon,LevelQuest,NameQuest,NameMon="Ship Engineer",2,"ShipQuest1","Ship Engineer"; CFrameQuest=CFrame.new(1008,125,32911); CFrameMon=CFrame.new(1050,130,32850); if _G.AutoFarmLevel then pcall(function() Remotes.CommF_:InvokeServer("requestEntrance",Vector3.new(923.21,126.98,32852.83)) end) end
        elseif lv <= 1499 then Mon,LevelQuest,NameQuest,NameMon="Sea Soldier",1,"FrostQuest","Sea Soldier"; CFrameQuest=CFrame.new(-3054,237,-10145); CFrameMon=CFrame.new(-3300,240,-10400)
        end
    elseif World3 then
        if     lv <= 1574 then Mon,LevelQuest,NameQuest,NameMon="Pirate Millionaire",1,"PiratePortQuest","Pirate Millionaire"; CFrameQuest=CFrame.new(-450,84,5660); CFrameMon=CFrame.new(-712.83,98.58,5711.95)
        elseif lv <= 1699 then Mon,LevelQuest,NameQuest,NameMon="Pistol Billionaire",2,"PiratePortQuest","Pistol Billionaire"; CFrameQuest=CFrame.new(-450,84,5660); CFrameMon=CFrame.new(-723.43,147.43,5931.99)
        elseif lv <= 1824 then Mon,LevelQuest,NameQuest,NameMon="Female Islander",1,"AmazonQuest","Female Islander"; CFrameQuest=CFrame.new(5832,51,-1100); CFrameMon=CFrame.new(4692.79,797.98,858.85)
        elseif lv <= 1974 then Mon,LevelQuest,NameQuest,NameMon="Marine Commodore",1,"MarineTreeIsland","Marine Commodore"; CFrameQuest=CFrame.new(2180,28,-6740); CFrameMon=CFrame.new(2401,123,-7589)
        elseif lv <= 2074 then Mon,LevelQuest,NameQuest,NameMon="Reborn Skeleton",1,"HauntedQuest1","Reborn Skeleton"; CFrameQuest=CFrame.new(-9515,142,5536); CFrameMon=CFrame.new(-8750,140,5900)
        elseif lv <= 2199 then Mon,LevelQuest,NameQuest,NameMon="Living Zombie",1,"HauntedQuest2","Living Zombie"; CFrameQuest=CFrame.new(-9515,142,5536); CFrameMon=CFrame.new(-10150,140,5950)
        elseif lv <= 2299 then Mon,LevelQuest,NameQuest,NameMon="Candy Rebel",1,"CandyQuest1","Candy Rebel"; CFrameQuest=CFrame.new(-1149,13,-14445); CFrameMon=CFrame.new(-1000,20,-14200)
        elseif lv <= 2449 then Mon,LevelQuest,NameQuest,NameMon="Sweet Thief",1,"CandyQuest2","Sweet Thief"; CFrameQuest=CFrame.new(-1149,13,-14445); CFrameMon=CFrame.new(-1200,20,-14700)
        elseif lv <= 2599 then Mon,LevelQuest,NameQuest,NameMon="Isle Outlaw",1,"TikiQuest1","Isle Outlaw"; CFrameQuest=CFrame.new(-16547,55,-172); CFrameMon=CFrame.new(-16800,30,-150)
        else                   Mon,LevelQuest,NameQuest,NameMon="Dojo Fighter",1,"DragonDojoQuest","Dojo Fighter"; CFrameQuest=CFrame.new(-16547,55,-172); CFrameMon=CFrame.new(-16300,60,-350)
        end
    end
end

-- ════════════════════════════════════════
--  ATTACK TARGET
--  FIX #2 completo: salva ponto fixo UMA VEZ
--  por mob. Não rastreia posição em tempo real.
--  Quando o mob morre e um novo é escolhido,
--  salva o ponto do novo mob. Sem âncora flutuante.
--
--  FIX deslize: BV (BodyVelocity) segura o player
--  no ponto fixo enquanto ataca. LERP eliminado —
--  não havia motivo para ele existir.
-- ════════════════════════════════════════
local function AttackTarget(mob)
    if not mob or not mob.Parent or not IsAlive(mob) then
        fixedFarmCF = nil
        fixedMobRef = nil
        _G.Seriality = false
        return
    end
    local mhrp = mob:FindFirstChild("HumanoidRootPart")
    if not mhrp then return end

    -- mob novo: salva ponto fixo UMA ÚNICA VEZ
    -- e reinicia o tween pro novo ponto
    if mob ~= fixedMobRef then
        fixedMobRef = mob
        -- ponto fixo = posição ATUAL do mob + altura
        -- não será atualizado enquanto esse mob estiver vivo
        fixedFarmCF = CFrame.new(
            mhrp.Position + Vector3.new(0, _G.FarmDistance or 25, 0)
        ) * CFrame.Angles(0, math.pi, 0)   -- virado pro mob
        StopTween(false)
        _G.Seriality = false
    end

    if not fixedFarmCF or not HumanoidRootPart then return end

    local dist = (HumanoidRootPart.Position - fixedFarmCF.Position).Magnitude

    if dist > ARRIVE_DIST then
        -- ainda longe: tween leva até o ponto fixo
        -- (não recria se já está indo pra lá — threshold cuida)
        _G.Seriality = false
        TweenPlayer(fixedFarmCF)
    else
        -- chegou: para o tween, BV segura, ataca
        StopTween(true)   -- keepBV=true: não remove a BV
        local bv = GetOrCreateBV()
        if bv then bv.Velocity = Vector3.zero end
        HumanoidRootPart.CFrame = fixedFarmCF
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        _G.Seriality = true
        EquipWeapon(_G.SelectWeapon)
        BringEnemy()
    end
end

-- ════════════════════════════════════════
--  FARM LOOP
-- ════════════════════════════════════════
local Sec = 0.15

task.spawn(function()
    while task.wait(Sec) do
        if not _G.AutoFarmLevel then
            _G.Seriality = false
            fixedFarmCF  = nil
            fixedMobRef  = nil
            StopTween()
            RemoveBV()
            continue
        end
        pcall(function()
            if not HumanoidRootPart then return end
            CheckQuest()

            -- quest errada: abandona
            if HasQuestVisible() and not HasCorrectQuest(NameMon) then
                fixedFarmCF  = nil
                fixedMobRef  = nil
                _G.Seriality = false
                Remotes.CommF_:InvokeServer("AbandonQuest")
                task.wait(0.2)
                return
            end

            -- sem quest: vai ao NPC pegar
            if not HasCorrectQuest(NameMon) then
                fixedFarmCF  = nil
                fixedMobRef  = nil
                _G.Seriality = false
                StopTween()
                RemoveBV()
                if CFrameQuest then
                    local distNPC = (HumanoidRootPart.Position - CFrameQuest.Position).Magnitude
                    if distNPC > 15 then
                        TweenPlayer(CFrameQuest)
                    else
                        StartQuestWait(NameQuest, LevelQuest, NameMon)
                    end
                else
                    StartQuestWait(NameQuest, LevelQuest, NameMon)
                end
                return
            end

            -- procura mob mais próximo
            local target, bestDist = nil, math.huge
            for _, v in ipairs(Enemies:GetChildren()) do
                if v.Name == Mon and IsAlive(v) then
                    local mh = v:FindFirstChild("HumanoidRootPart")
                    if mh then
                        local d = (mh.Position - HumanoidRootPart.Position).Magnitude
                        if d < bestDist then bestDist = d; target = v end
                    end
                end
            end

            if target then
                AttackTarget(target)
            else
                -- sem mob vivo: vai pra posição conhecida
                fixedFarmCF  = nil
                fixedMobRef  = nil
                _G.Seriality = false
                StopTween()
                RemoveBV()
                if CFrameMon then TweenPlayer(CFrameMon) end
            end
        end)
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
    Title        = "Auto Farm",
    SubTitle     = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or "?"),
    ScriptFolder = "AutoFarmEstavel"
})

local TabFarm = Win:MakeTab({ Title = "Farm" })
local TabTele = Win:MakeTab({ Title = "Teleport" })
local TabCfg  = Win:MakeTab({ Title = "Config" })

TabFarm:AddSection("Auto Farm")
TabFarm:AddToggle({
    Title = "Auto Farm Level", Default = false,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if not v then
            _G.Seriality = false
            fixedFarmCF  = nil
            fixedMobRef  = nil
            StopTween(); RemoveBV()
        end
    end
})
TabFarm:AddToggle({
    Title = "Bring Mobs", Default = true,
    Callback = function(v) _G.BringMob = v end
})
TabFarm:AddToggle({
    Title = "Seriality (forçar ataque)", Default = false,
    Callback = function(v) _G.Seriality = v end
})

local teleDestinos = {
    [1]={ ["Starter Island"]=CFrame.new(1059,15,1550), ["Jungle"]=CFrame.new(-1448,68,11), ["Pirate Village"]=CFrame.new(-1141,4,3831), ["Desert"]=CFrame.new(924,6,4481), ["Snow Mountain"]=CFrame.new(1354,87,-1393), ["Marine Fortress"]=CFrame.new(-5035,28,4324), ["Sky Island"]=CFrame.new(-4842,717,2623), ["Prison"]=CFrame.new(5310,0,474), ["Colosseum"]=CFrame.new(-1577,7,2984), ["Magma Village"]=CFrame.new(-5316,12,8517), ["Underwater City"]=CFrame.new(61122,18,1569), ["Upper Skylands"]=CFrame.new(-4721,845,1953) },
    [2]={ ["Kingdom of Rose"]=CFrame.new(-429,71,1836), ["Green Zone"]=CFrame.new(638,72,918), ["Graveyard"]=CFrame.new(-5497,48,-795), ["Snow Mountain S2"]=CFrame.new(609,401,-5372), ["Hot & Cold"]=CFrame.new(1008,125,32911), ["Cursed Ship"]=CFrame.new(-3054,237,-10145), ["Marine HQ"]=CFrame.new(-2440,72,-3217) },
    [3]={ ["Pirate Port"]=CFrame.new(-289,44,5580), ["Amazon Lily"]=CFrame.new(5832,51,-1100), ["Great Tree"]=CFrame.new(2180,28,-6740), ["Haunted Castle"]=CFrame.new(-9515,142,5536), ["Candy Island"]=CFrame.new(-1149,13,-14445), ["Tiki Outpost"]=CFrame.new(-16547,55,-172), ["Dragon Dojo"]=CFrame.new(-16300,60,-350) },
}

local seaMap   = teleDestinos[CurrentSea] or teleDestinos[1]
local destKeys = {}
for k in pairs(seaMap) do table.insert(destKeys, k) end
table.sort(destKeys)
local selectedDest = destKeys[1]

TabTele:AddSection("Ilhas — Sea "..CurrentSea)
TabTele:AddDropdown({ Title="Destino", Options=destKeys, Default=destKeys[1], Callback=function(v) selectedDest=v end })
TabTele:AddButton({ Title="Teleportar", Callback=function()
    if HumanoidRootPart then TweenPlayer(seaMap[selectedDest]) end
end })
TabTele:AddButton({ Title="Parar Movimento", Callback=function()
    StopTween()
    if HumanoidRootPart then HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero end
    RemoveBV()
end })

TabCfg:AddSection("Configuração")
TabCfg:AddDropdown({ Title="Arma", Options={"Melee","Sword","Blox Fruit"}, Default="Melee", Callback=function(v) _G.SelectWeapon=v; EquipWeapon(v) end })
TabCfg:AddSlider({ Title="Altura sobre o mob", Min=5, Max=60, Default=25, Increment=1, Callback=function(v) _G.FarmDistance=v; fixedFarmCF=nil; fixedMobRef=nil end })
TabCfg:AddSlider({ Title="Velocidade tween",   Min=100, Max=800, Default=300, Increment=10, Callback=function(v) _G.PlayerTweenSpeed=v end })

print("[Auto Farm Estável] Sea "..CurrentSea.." | Lv."..(LP.Data and LP.Data.Level.Value or "?"))
