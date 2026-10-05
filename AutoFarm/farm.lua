local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local commF = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local workspace = game:GetService("Workspace")

_G.PureAutoFarm = true
_G.WeaponType = "Melee"

getgenv().Sea1 = game.PlaceId == 2753915549
getgenv().Sea2 = game.PlaceId == 4442274612
getgenv().Sea3 = game.PlaceId == 7449423635
getgenv().SelectMonster = getgenv().SelectMonster or ""

-- Load external quest data
task.spawn(function()
    local s, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/wh1tehourse/vtrunc/main/data.lua"))()
    end)
    if not s then warn("[FARM] Failed to load data.lua: ", err) end
end)

----------------------------------------------------------------
--  MINI NOTIFIER  (draggable status bar)
----------------------------------------------------------------
local notifier = {}
do
    local oldGui = player.PlayerGui:FindFirstChild("FarmNotifier")
    if oldGui then oldGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FarmNotifier"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = player.PlayerGui

    -- Main bar
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0, 280, 0, 34)
    bar.Position = UDim2.new(0.5, -140, 0, 10)
    bar.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    bar.BackgroundTransparency = 0.12
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = gui

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 8)
    barCorner.Parent = bar

    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(60, 60, 90)
    barStroke.Thickness = 1
    barStroke.Transparency = 0.4
    barStroke.Parent = bar

    -- Accent line (top edge glow)
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(1, -16, 0, 2)
    accent.Position = UDim2.new(0, 8, 0, 0)
    accent.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    accent.BorderSizePixel = 0
    accent.Parent = bar

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 1)
    accentCorner.Parent = accent

    -- Status dot
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 10, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    dot.BorderSizePixel = 0
    dot.Parent = bar

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    -- Mob name label (left side)
    local mobLabel = Instance.new("TextLabel")
    mobLabel.Name = "MobLabel"
    mobLabel.Size = UDim2.new(0, 130, 1, 0)
    mobLabel.Position = UDim2.new(0, 24, 0, 0)
    mobLabel.BackgroundTransparency = 1
    mobLabel.Text = "—"
    mobLabel.TextColor3 = Color3.fromRGB(225, 225, 245)
    mobLabel.TextSize = 11
    mobLabel.Font = Enum.Font.GothamBold
    mobLabel.TextXAlignment = Enum.TextXAlignment.Left
    mobLabel.TextTruncate = Enum.TextTruncate.AtEnd
    mobLabel.Parent = bar

    -- Status text (right side)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 110, 1, 0)
    statusLabel.Position = UDim2.new(1, -118, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Starting..."
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = bar

    -- Dragging logic (works on all executors)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bar.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    bar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            bar.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Color map
    local STATUS_COLORS = {
        farming  = Color3.fromRGB(80, 200, 120),   -- hijau
        travel   = Color3.fromRGB(90, 155, 255),    -- biru
        quest    = Color3.fromRGB(255, 195, 55),     -- kuning
        waiting  = Color3.fromRGB(160, 160, 175),    -- abu
        error    = Color3.fromRGB(255, 75, 75),      -- merah
    }

    function notifier.update(mob, status, sType)
        if mob then mobLabel.Text = mob end
        if status then statusLabel.Text = status end
        local col = STATUS_COLORS[sType] or STATUS_COLORS.waiting
        dot.BackgroundColor3 = col
        accent.BackgroundColor3 = col
        -- Pulse dot on error
        if sType == "error" then
            pcall(function()
                local pulse = TS:Create(dot, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
                    {BackgroundTransparency = 0.7})
                pulse:Play()
            end)
        else
            dot.BackgroundTransparency = 0
        end
    end

    function notifier.destroy()
        pcall(function() gui:Destroy() end)
    end
end

----------------------------------------------------------------
--  QUEST DATA  (unchanged)
----------------------------------------------------------------
local function GetQuestData(level)
    if CheckLevel then
        local s, err = pcall(CheckLevel)
        if s and getgenv().Ms and getgenv().NameQuest and getgenv().QuestLv and getgenv().CFrameQ and getgenv().CFrameMon then
            return getgenv().Ms, getgenv().NameQuest, getgenv().QuestLv, getgenv().CFrameQ, getgenv().CFrameMon
        elseif s and Ms and NameQuest and QuestLv and CFrameQ and CFrameMon then
            return Ms, NameQuest, QuestLv, CFrameQ, CFrameMon
        end
    end
    if level >= 2575 then
        return "Skull Slayer", "TikiQuest3", 2,
            CFrame.new(-16665.19, 104.60, 1579.69),
            CFrame.new(-16811.57, 84.63, 1542.24)
    elseif level >= 2550 then
        return "Serpent Hunter", "TikiQuest3", 1,
            CFrame.new(-16665.19, 104.60, 1579.69),
            CFrame.new(-16621.41, 121.41, 1290.69)
    elseif level >= 2525 then
        return "Isle Champion", "TikiQuest2", 2,
            CFrame.new(-16541.02, 54.77, 1051.46),
            CFrame.new(-16848.94, 21.69, 1041.45)
    elseif level >= 2500 then
        return "Sun-kissed Warrior", "TikiQuest2", 1,
            CFrame.new(-16541.02, 54.77, 1051.46),
            CFrame.new(-16357.31, 20.63, 1005.65)
    elseif level >= 2475 then
        return "Island Boy", "TikiQuest1", 2,
            CFrame.new(-16549.89, 55.69, -179.91),
            CFrame.new(-16357.31, 20.63, 1005.65)
    elseif level >= 2450 then
        return "Isle Outlaw", "TikiQuest1", 1,
            CFrame.new(-16549.89, 55.69, -179.91),
            CFrame.new(-16162.82, 11.69, -96.45)
    else
        return "Bandit", "BanditQuest1", 1,
            CFrame.new(1060.94, 16.46, 1547.78),
            CFrame.new(1038.55, 41.30, 1576.51)
    end
end

----------------------------------------------------------------
--  SAFER UTILITY FUNCTIONS
----------------------------------------------------------------

-- AntiJitter: BodyPosition (finite force) + HRP-only collision off
local function AntiJitter()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.CanCollide = false

    local bp = hrp:FindFirstChild("FarmBP")
    if not bp then
        bp = Instance.new("BodyPosition")
        bp.Name = "FarmBP"
        bp.MaxForce = Vector3.new(50000, 50000, 50000)
        bp.D = 1250
        bp.P = 12500
        bp.Position = hrp.Position
        bp.Parent = hrp
    end
    bp.Position = hrp.Position
end

local function CleanupAntiJitter()
    pcall(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bp = hrp:FindFirstChild("FarmBP")
            if bp then bp:Destroy() end
        end
    end)
end

-- EquipWeapon (safe — returns success bool)
local function EquipWeapon()
    local char = player.Character
    if not char then return false end
    -- Already equipped?
    local held = char:FindFirstChildOfClass("Tool")
    if held and held.ToolTip:find(_G.WeaponType) then return true end
    -- Try equip from backpack
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip:find(_G.WeaponType) then
            char.Humanoid:EquipTool(v)
            return true
        end
    end
    return false
end

-- AutoHaki (safe)
local function AutoHaki()
    if player.Character and not player.Character:FindFirstChild("HasBuso") then
        pcall(function() commF:InvokeServer("Buso") end)
    end
end

-- Attack: SAFE — natural timing, no CombatFramework hack
local VIM = game:GetService("VirtualInputManager")
local lastAttackTick = 0
local ATTACK_COOLDOWN = 0.35  -- realistic sword swing speed

local function Attack()
    local now = tick()
    if now - lastAttackTick < ATTACK_COOLDOWN then return true end -- still in cooldown, not an error

    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return false end

    -- Primary: tool:Activate (safest, game's own API)
    pcall(function() tool:Activate() end)

    -- Backup: virtual mouse click (simulates real player input)
    pcall(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.015)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)

    lastAttackTick = now
    return true
end

-- Tween: capped at 120 stud/s (much more realistic than 300)
local currentTween = nil
local function Tween(targetCFrame)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 9999 end

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist < 5 then
        if currentTween then currentTween:Cancel() end
        return dist
    end

    local speed = 120
    if dist < 60 then speed = 80 end

    if currentTween then currentTween:Cancel() end
    local ti = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    currentTween = TS:Create(hrp, ti, {CFrame = targetCFrame})
    currentTween:Play()
    return dist
end

-- SmoothTP: fast tween instead of raw CFrame set (looks more legit)
local function SmoothTP(targetCFrame)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist < 2 then
        hrp.CFrame = targetCFrame
        return
    end
    if currentTween then currentTween:Cancel() end
    local t = math.clamp(dist / 220, 0.04, 0.35)
    currentTween = TS:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    currentTween:Play()
end

-- FindNearestMob: pick closest valid mob (player goes TO mob, not mob to player)
local function FindNearestMob(NameMon, CFrameMon)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge

    -- Pass 1: mobs near their spawn point
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local mHrp = mob:FindFirstChild("HumanoidRootPart")
            if mHrp then
                local spawnDist = (mHrp.Position - CFrameMon.Position).Magnitude
                if spawnDist < 200 then
                    local d = (hrp.Position - mHrp.Position).Magnitude
                    if d < bestDist then
                        best = mob
                        bestDist = d
                    end
                end
            end
        end
    end

    -- Pass 2 fallback: any living mob with that name
    if not best then
        for _, mob in pairs(workspace.Enemies:GetChildren()) do
            if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                local mHrp = mob:FindFirstChild("HumanoidRootPart")
                if mHrp then
                    local d = (hrp.Position - mHrp.Position).Magnitude
                    if d < bestDist then
                        best = mob
                        bestDist = d
                    end
                end
            end
        end
    end

    return best
end

----------------------------------------------------------------
--  ERROR TRACKING
----------------------------------------------------------------
local errorLog = {}
local function LogError(category, message)
    local entry = "[" .. category .. "] " .. message
    table.insert(errorLog, {time = tick(), msg = entry})
    if #errorLog > 15 then table.remove(errorLog, 1) end
    warn("[FARM ERR] " .. entry)
end

----------------------------------------------------------------
--  MAIN FARM LOOP
----------------------------------------------------------------
local questFailedCount = 0
local bypassQuest = false
local questCooldown = 0
local noMobTimer = 0
local noDmgCounter = 0
local lastTrackedMob = nil
local lastTrackedHP = 0

task.spawn(function()
    notifier.update("—", "Initializing...", "waiting")
    warn("[SAFE FARM] Script dimulai — Safety mode aktif.")

    while _G.PureAutoFarm and task.wait(0.15) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hrp or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            notifier.update("—", "Respawning...", "waiting")
            CleanupAntiJitter()
            continue
        end

        AntiJitter()

        -- Read level safely
        local level = nil
        local ls, le = pcall(function() level = player.Data.Level.Value end)
        if not ls or not level then
            LogError("DATA", "Gagal baca Level")
            notifier.update("—", "⚠ Level error", "error")
            continue
        end

        -- Quest data
        local NameMon, NameQuest, QuestLv, CFrameQ, CFrameMon = GetQuestData(level)
        if not NameMon then
            LogError("QUEST", "GetQuestData nil (Lv " .. tostring(level) .. ")")
            notifier.update("Lv " .. level, "⚠ No quest data", "error")
            continue
        end

        -- Quest visibility
        local questActive = false
        pcall(function() questActive = player.PlayerGui.Main.Quest.Visible end)

        ----------------------------------------------------
        --  PHASE: TAKE QUEST
        ----------------------------------------------------
        if not questActive and not bypassQuest then
            notifier.update(NameMon, "Taking quest...", "quest")

            if tick() - questCooldown < 3.5 then
                continue   -- cooldown between requests (anti-spam)
            end

            local targetPos = CFrameQ * CFrame.new(0, 5, 0)
            local dist = (hrp.Position - targetPos.Position).Magnitude

            if dist > 15 then
                Tween(targetPos)
                notifier.update(NameMon, "→ Quest NPC", "travel")
            else
                if currentTween then currentTween:Cancel() currentTween = nil end
                SmoothTP(targetPos)
                task.wait(0.7)

                questCooldown = tick()
                local res = nil
                local qs, qe = pcall(function()
                    res = commF:InvokeServer("StartQuest", NameQuest, QuestLv)
                end)

                if not qs then
                    LogError("QUEST", "InvokeServer crash: " .. tostring(qe))
                    notifier.update(NameMon, "⚠ Quest error", "error")
                else
                    -- Re-check visibility after invoke
                    local nowVis = false
                    pcall(function() nowVis = player.PlayerGui.Main.Quest.Visible end)

                    if res == "Quest Already Active" or nowVis then
                        questFailedCount = 0
                        notifier.update(NameMon, "Quest active ✓", "farming")
                    else
                        questFailedCount = questFailedCount + 1
                        LogError("QUEST", "Rejected #" .. questFailedCount .. " (resp: " .. tostring(res) .. ")")
                        notifier.update(NameMon, "⚠ Rejected #" .. questFailedCount, "error")
                        if questFailedCount > 3 then
                            warn("[SAFE FARM] Quest fail 3x → bypass ON")
                            bypassQuest = true
                        end
                    end
                end
            end

        ----------------------------------------------------
        --  PHASE: FARM MOB
        ----------------------------------------------------
        else
            local mob = FindNearestMob(NameMon, CFrameMon)

            if mob then
                noMobTimer = 0
                local mobHrp = mob:FindFirstChild("HumanoidRootPart")
                if not mobHrp then continue end

                local mobPos = mobHrp.Position
                local farmPos = CFrame.new(mobPos + Vector3.new(0, 12, 0), mobPos)
                local dist = (hrp.Position - farmPos.Position).Magnitude

                if dist > 30 then
                    Tween(farmPos)
                    notifier.update(NameMon, "Approaching...", "travel")
                else
                    -- Close enough — engage
                    if currentTween then currentTween:Cancel() currentTween = nil end
                    SmoothTP(farmPos)

                    AutoHaki()

                    local equipped = EquipWeapon()
                    if not equipped then
                        LogError("WEAPON", "'" .. _G.WeaponType .. "' not found")
                        notifier.update(NameMon, "⚠ No weapon!", "error")
                    else
                        -- Damage tracking (per-mob)
                        if mob ~= lastTrackedMob then
                            lastTrackedMob = mob
                            lastTrackedHP = mob.Humanoid.Health
                            noDmgCounter = 0
                        else
                            local hp = mob.Humanoid.Health
                            if hp >= lastTrackedHP then
                                noDmgCounter = noDmgCounter + 1
                            else
                                noDmgCounter = 0
                            end
                            lastTrackedHP = hp
                        end

                        local atkOk = Attack()
                        if not atkOk then
                            LogError("ATTACK", "Tool inactive / attack failed")
                            notifier.update(NameMon, "⚠ Atk fail", "error")
                        else
                            local hpPct = math.floor((mob.Humanoid.Health / mob.Humanoid.MaxHealth) * 100)
                            notifier.update(NameMon, "⚔ " .. hpPct .. "% HP", "farming")
                        end

                        if noDmgCounter > 45 then
                            LogError("DAMAGE", "0 dmg on " .. NameMon .. " (45+ cycles)")
                            notifier.update(NameMon, "⚠ No damage!", "error")
                            noDmgCounter = 0
                        end
                    end
                end

            -- No mob found — wait at spawn
            else
                noMobTimer = noMobTimer + 1
                local waitPos = CFrameMon * CFrame.new(0, 15, 0)
                local dist = (hrp.Position - waitPos.Position).Magnitude

                if dist > 15 then
                    Tween(waitPos)
                else
                    if currentTween then currentTween:Cancel() currentTween = nil end
                    SmoothTP(waitPos)
                end

                notifier.update(NameMon, "Waiting spawn...", "waiting")

                if noMobTimer > 80 then  -- ~12 detik tanpa mob
                    LogError("MOB", NameMon .. " not spawning (timeout)")
                    notifier.update(NameMon, "⚠ No spawn", "error")
                    noMobTimer = 0
                end

                -- Reset bypass kalau quest complete
                if not questActive and bypassQuest then
                    bypassQuest = false
                    questFailedCount = 0
                end
            end
        end
    end

    -- Cleanup saat script stop
    CleanupAntiJitter()
    notifier.update("—", "Stopped", "waiting")
    warn("[SAFE FARM] Script dihentikan.")
end)