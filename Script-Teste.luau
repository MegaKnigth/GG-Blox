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
LP.CharacterAdded:Connect(SetupCharacter)

local Remotes        = ReplicatedStorage.Remotes
local Enemies        = workspace:WaitForChild("Enemies")
local Net            = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

pcall(function() Remotes.CommF_:InvokeServer("SetTeam","Pirates") end)

local PlaceId    = game.PlaceId
local World1     = (PlaceId == 2753915549 or PlaceId == 85211729168715)
local World2     = (PlaceId == 4442272183 or PlaceId == 79091703265657)
local World3     = (PlaceId == 7449423635 or PlaceId == 100117331123089)
local CurrentSea = World1 and 1 or World2 and 2 or World3 and 3 or 1

_G.Seriality        = false
_G.AutoFarmLevel    = false
_G.BringMob         = true
_G.SelectWeapon     = "Melee"
_G.FarmDistance     = 25
_G.PlayerTweenSpeed = 300

local Mon, LevelQuest, NameQuest, NameMon, CFrameQuest, CFrameMon
local PosMon        = CFrame.new()
local Pos           = CFrame.new(0, 25, 0)
local Sec           = 0.15

-- atualiza Pos quando FarmDistance muda
task.spawn(function()
    while task.wait() do
        Pos = CFrame.new(0, _G.FarmDistance or 25, 0)
    end
end)

-- BodyClip / noclip
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.AutoFarmLevel and HumanoidRootPart then
                if not HumanoidRootPart:FindFirstChild("BodyClip") then
                    local bv          = Instance.new("BodyVelocity")
                    bv.Name           = "BodyClip"
                    bv.MaxForce       = Vector3.new(1e5,1e5,1e5)
                    bv.Velocity       = Vector3.zero
                    bv.Parent         = HumanoidRootPart
                end
                if Char then
                    for _, v in ipairs(Char:GetDescendants()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                end
            else
                local bc = HumanoidRootPart and HumanoidRootPart:FindFirstChild("BodyClip")
                if bc then bc:Destroy() end
            end
        end)
    end
end)

-- ════════════════════════════════════════
--  TWEEN PLAYER — reescrito
--  Problema original: o CFrame changed do PartTele continuava
--  disparando depois do tween terminar, puxando o HRP de volta
--  para posições antigas.
--  Fix: flag `moving` controla o stepped; conexão desfeita no fim.
-- ════════════════════════════════════════
local tweenActive   = false
local tweenObj      = nil
local steppedConn   = nil

local function StopTween()
    tweenActive = false
    if tweenObj then
        pcall(function() tweenObj:Cancel() end)
        tweenObj = nil
    end
    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
    -- limpa PartTele sem mexer no HRP
    if Char then
        local pt = Char:FindFirstChild("PartTele")
        if pt then pt:Destroy() end
    end
end

local function TweenPlayer(dest)
    if not Char or not Humanoid or Humanoid.Health <= 0
       or not HumanoidRootPart or not dest then return end

    -- destino próximo: snap direto, sem tween
    local dist = (dest.Position - HumanoidRootPart.Position).Magnitude
    if dist < 5 then
        HumanoidRootPart.CFrame = dest
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        return
    end

    -- cancela qualquer tween anterior
    StopTween()

    -- cria ou reusa PartTele
    local part = Instance.new("Part")
    part.Name         = "PartTele"
    part.Size         = Vector3.new(1,1,1)
    part.Anchored     = true
    part.Transparency = 1
    part.CanCollide   = false
    part.CFrame       = HumanoidRootPart.CFrame
    part.Parent       = Char

    tweenActive = true

    -- Stepped cola o HRP na part enquanto move
    -- Desconecta sozinho assim que tweenActive = false
    steppedConn = RunService.Stepped:Connect(function()
        if not tweenActive then
            steppedConn:Disconnect()
            steppedConn = nil
            return
        end
        if HumanoidRootPart and part and part.Parent then
            HumanoidRootPart.CFrame = part.CFrame
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    local duration = dist / (_G.PlayerTweenSpeed or 300)
    tweenObj = TweenService:Create(part,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = dest })

    tweenObj:Play()

    -- espera o tween acabar
    tweenObj.Completed:Connect(function(state)
        tweenActive = false
        if steppedConn then
            steppedConn:Disconnect()
            steppedConn = nil
        end
        -- snap final
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = dest
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
        if part and part.Parent then part:Destroy() end
        tweenObj = nil
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
            local label  = header and header:FindFirstChild("textLabel")
            if label and label:IsA("TextLabel") and label.Text ~= "" then
                return tostring(label.Text)
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
    if title == "" then return false end
    return string.find(string.lower(title), string.lower(nameMon), 1, true) ~= nil
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
--  EQUIP / BRING
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
        if hum and hrp and hum.Health > 0
           and (hrp.Position - pivot).Magnitude <= 350 then
            pcall(function()
                hrp.CFrame     = CFrame.new(pivot)
                hrp.CanCollide = false
                hum.WalkSpeed  = 0
                hum.JumpPower  = 0
                if sethiddenproperty then
                    sethiddenproperty(LP, "SimulationRadius", math.huge)
                end
            end)
        end
    end
end

-- ════════════════════════════════════════
--  ATTACK
-- ════════════════════════════════════════
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
        if hrp and IsAlive(enemy) and not enemy:GetAttribute("IsBoat")
           and (hrp.Position - pos).Magnitude <= 60 then
            local limbs = {"RightLowerArm","RightUpperArm","LeftLowerArm",
                           "LeftUpperArm","RightHand","LeftHand"}
            local part  = enemy:FindFirstChild(limbs[math.random(#limbs)])
                       or enemy.PrimaryPart or hrp
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
                left:FireServer(Vector3.new(0.01,-500,0.01),1,true)
                left:FireServer(false)
            end
        end
    end)
end)

pcall(function() require(ReplicatedStorage.Util.CameraShaker):Stop() end)

-- ════════════════════════════════════════
--  CHECK QUEST
-- ════════════════════════════════════════
local function CheckQuest()
    local lv = LP.Data.Level.Value
    if World1 then
        if lv <= 9 then
            Mon,LevelQuest,NameQuest,NameMon = "Bandit",1,"BanditQuest1","Bandit"
            CFrameQuest = CFrame.new(1059.37195,15.4495068,1550.4231)
            CFrameMon   = CFrame.new(1045.962646,27.002508,1560.820312)
        elseif lv <= 14 then
            Mon,LevelQuest,NameQuest,NameMon = "Monkey",1,"JungleQuest","Monkey"
            CFrameQuest = CFrame.new(-1598.08911,35.5501175,153.377838)
            CFrameMon   = CFrame.new(-1448.51806,67.853012,11.465796)
        elseif lv <= 29 then
            Mon,LevelQuest,NameQuest,NameMon = "Gorilla",2,"JungleQuest","Gorilla"
            CFrameQuest = CFrame.new(-1598.08911,35.5501175,153.377838)
            CFrameMon   = CFrame.new(-1129.883666,40.463546,-525.423706)
        elseif lv <= 39 then
            Mon,LevelQuest,NameQuest,NameMon = "Pirate",1,"BuggyQuest1","Pirate"
            CFrameQuest = CFrame.new(-1141.07483,4.10001802,3831.5498)
            CFrameMon   = CFrame.new(-1103.513427,13.752052,3896.091064)
        elseif lv <= 59 then
            Mon,LevelQuest,NameQuest,NameMon = "Brute",2,"BuggyQuest1","Brute"
            CFrameQuest = CFrame.new(-1141.07483,4.10001802,3831.5498)
            CFrameMon   = CFrame.new(-1140.083740,14.809885,4322.921386)
        elseif lv <= 74 then
            Mon,LevelQuest,NameQuest,NameMon = "Desert Bandit",1,"DesertQuest","Desert Bandit"
            CFrameQuest = CFrame.new(894.488647,5.14000702,4392.43359)
            CFrameMon   = CFrame.new(924.799804,6.448674,4481.585937)
        elseif lv <= 89 then
            Mon,LevelQuest,NameQuest,NameMon = "Desert Officer",2,"DesertQuest","Desert Officer"
            CFrameQuest = CFrame.new(894.488647,5.14000702,4392.43359)
            CFrameMon   = CFrame.new(1608.282226,8.614224,4371.007324)
        else
            Mon,LevelQuest,NameQuest,NameMon = "Snow Bandit",1,"SnowQuest","Snow Bandit"
            CFrameQuest = CFrame.new(1389.74451,88.1519318,-1298.90796)
            CFrameMon   = CFrame.new(1354.347900,87.272773,-1393.946533)
        end
    elseif World2 then
        if lv <= 724 then
            Mon,LevelQuest,NameQuest,NameMon = "Raider",1,"Area1Quest","Raider"
            CFrameQuest = CFrame.new(-429.543518,71.7699966,1836.18188)
            CFrameMon   = CFrame.new(-728.326721,52.779319,2345.770507)
        elseif lv <= 774 then
            Mon,LevelQuest,NameQuest,NameMon = "Mercenary",2,"Area1Quest","Mercenary"
            CFrameQuest = CFrame.new(-429.543518,71.7699966,1836.18188)
            CFrameMon   = CFrame.new(-1004.324401,80.158866,1424.619384)
        else
            Mon,LevelQuest,NameQuest,NameMon = "Swan Pirate",1,"Area2Quest","Swan Pirate"
            CFrameQuest = CFrame.new(638.43811,71.769989,918.282898)
            CFrameMon   = CFrame.new(1068.664306,137.614288,1322)
        end
    else
        Mon,LevelQuest,NameQuest,NameMon = "Pirate Millionaire",1,"PiratePortQuest","Pirate Millionaire"
        CFrameQuest = CFrame.new(-450,84,5660)
        CFrameMon   = CFrame.new(-712.827270,98.577049,5711.954101)
    end
end

-- ════════════════════════════════════════
--  ATTACK TARGET
--  Problema original: o repeat/task.wait() bloqueava o loop
--  principal enquanto tentava matar um mob, fazendo o script
--  ignorar quest e bring durante a perseguição.
--  Fix: sem repeat interno — cada iteração do loop principal
--  decide o que fazer, AttackTarget apenas posiciona e ataca
--  uma vez por chamada.
-- ════════════════════════════════════════
local function AttackTarget(v)
    if not v or not v.Parent or not IsAlive(v) then return end
    local mhrp = v:FindFirstChild("HumanoidRootPart")
    if not mhrp then return end

    -- trava posição do mob
    if not v:GetAttribute("Locked") then
        pcall(function() v:SetAttribute("Locked", mhrp.CFrame) end)
    end
    local locked = v:GetAttribute("Locked")
    PosMon = locked or mhrp.CFrame

    -- posiciona acima do ponto travado
    local destino = PosMon * Pos
    local dist    = (HumanoidRootPart.Position - destino.Position).Magnitude

    if dist > 5 then
        TweenPlayer(destino)
    else
        -- já está no ponto: para o tween, ancora, ataca
        StopTween()
        HumanoidRootPart.CFrame = destino
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        _G.Seriality = true
        EquipWeapon(_G.SelectWeapon)
    end

    BringEnemy()
end

-- ════════════════════════════════════════
--  FARM LOOP
-- ════════════════════════════════════════
task.spawn(function()
    while task.wait(Sec) do
        if not _G.AutoFarmLevel then
            _G.Seriality = false
            continue
        end
        pcall(function()
            if not HumanoidRootPart then return end
            CheckQuest()

            -- quest errada → abandon
            if HasQuestVisible() and not HasCorrectQuest(NameMon) then
                _G.Seriality = false
                Remotes.CommF_:InvokeServer("AbandonQuest")
                task.wait(0.2)
                return
            end

            -- sem quest → vai no NPC
            if not HasCorrectQuest(NameMon) then
                _G.Seriality = false
                StopTween()
                if CFrameQuest then
                    TweenPlayer(CFrameQuest)
                    task.wait(2)
                    local distNPC = (HumanoidRootPart.Position - CFrameQuest.Position).Magnitude
                    if distNPC <= 10 then
                        StartQuestWait(NameQuest, LevelQuest, NameMon)
                    end
                else
                    StartQuestWait(NameQuest, LevelQuest, NameMon)
                end
                return
            end

            -- localiza mob
            local target = nil
            for _, v in ipairs(Enemies:GetChildren()) do
                if v.Name == Mon and IsAlive(v) and v:FindFirstChild("HumanoidRootPart") then
                    target = v
                    break
                end
            end

            if target then
                AttackTarget(target)
            else
                -- fallback: área de spawn
                _G.Seriality = false
                local found = false
                for _, v in ipairs(ReplicatedStorage:GetChildren()) do
                    if string.find(v.Name, Mon) and v:FindFirstChild("HumanoidRootPart") and IsAlive(v) then
                        TweenPlayer(v.HumanoidRootPart.CFrame * CFrame.new(0,20,0))
                        found = true
                        break
                    end
                end
                if not found then
                    local origin = workspace:FindFirstChild("_WorldOrigin")
                    local spawns = origin and origin:FindFirstChild("EnemySpawns")
                    if spawns then
                        for _, s in ipairs(spawns:GetChildren()) do
                            if string.find(s.Name, Mon) then
                                TweenPlayer(s.CFrame * CFrame.new(0,20,0))
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

-- ════════════════════════════════════════
--  GG-UI
-- ════════════════════════════════════════
local GGUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MegaKnigth/GG-Blox/refs/heads/main/GG-Ui.luau"
))()
if not GGUI or type(GGUI.MakeWindow) ~= "function" then
    warn("[BF] GG-UI fail")
    return
end

local Win = GGUI:MakeWindow({
    Title        = "Auto Farm",
    SubTitle     = "Sea " .. CurrentSea .. " | Lv." .. (LP.Data and LP.Data.Level.Value or 1),
    ScriptFolder = "AutoFarmEstavel"
})

local TabFarm = Win:MakeTab({ Title = "Farm" })
local TabCfg  = Win:MakeTab({ Title = "Config" })

TabFarm:AddToggle({
    Title    = "Auto Farm Level",
    Default  = false,
    Callback = function(v)
        _G.AutoFarmLevel = v
        if not v then
            _G.Seriality = false
            StopTween()
        end
    end
})

TabFarm:AddToggle({
    Title    = "Seriality (Ataque)",
    Default  = false,
    Callback = function(v) _G.Seriality = v end
})

TabFarm:AddToggle({
    Title    = "Bring Mobs",
    Default  = true,
    Callback = function(v) _G.BringMob = v end
})

TabCfg:AddDropdown({
    Title    = "Arma",
    Options  = {"Melee","Sword","Blox Fruit"},
    Default  = "Melee",
    Callback = function(v)
        _G.SelectWeapon = v
        EquipWeapon(v)
    end
})

TabCfg:AddSlider({
    Title    = "Altura sobre o mob",
    Min      = 5,
    Max      = 60,
    Default  = 25,
    Increment = 1,
    Callback = function(v) _G.FarmDistance = v end
})

TabCfg:AddSlider({
    Title    = "Velocidade tween",
    Min      = 100,
    Max      = 800,
    Default  = 300,
    Increment = 10,
    Callback = function(v) _G.PlayerTweenSpeed = v end
})

print("[Auto Farm] carregado — PartTele corrigido")
