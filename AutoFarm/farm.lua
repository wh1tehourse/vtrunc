----------------------------------------------------------------
--  SAFE FARM v3 — Optimized & Modular
--  Changes from v2:
--    • UI moved to notifier.lua (loaded separately)
--    • Anti-AFK built-in
--    • Kill priority: lowest HP mob first → faster quest completion
--    • Auto server-hop on prolonged idle (optional)
--    • Stats tracking: kills, elapsed time, kills/min
--    • Smarter quest cycle: instant re-take on completion
--    • Adaptive attack speed based on weapon tooltip
----------------------------------------------------------------
local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local commF = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local workspace = game:GetService("Workspace")

-- ══════════════ CONFIG ══════════════
_G.PureAutoFarm = true
_G.WeaponType = "Melee"
_G.AutoServerHop = false       -- set true to hop if stuck >60s
_G.ServerHopTimeout = 60       -- seconds before hop

getgenv().Sea1 = game.PlaceId == 2753915549
getgenv().Sea2 = game.PlaceId == 4442274612
getgenv().Sea3 = game.PlaceId == 7449423635
getgenv().SelectMonster = getgenv().SelectMonster or ""

-- ══════════════ LOAD DEPENDENCIES ══════════════
-- Load quest data
task.spawn(function()
    local s, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/wh1tehourse/vtrunc/main/data.lua"))()
    end)
    if not s then warn("[FARM] Failed to load data.lua: ", err) end
end)

-- Load notifier UI (separate module)
local notifier = nil
task.spawn(function()
    local s, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/wh1tehourse/vtrunc/main/AutoFarm/notifier.lua"
        ))()
    end)
    if s and result then
        notifier = result
    elseif getgenv().FarmNotifier then
        notifier = getgenv().FarmNotifier
    else
        warn("[FARM] Notifier failed to load, using fallback")
        -- Fallback: silent notifier (no UI, just warn)
        notifier = {
            update = function(_, mob, status, sType)
                if sType == "error" then warn("[FARM] " .. tostring(mob) .. " | " .. tostring(status)) end
            end,
            stat = function() end,
            destroy = function() end,
        }
    end
end)

-- Wait for notifier to be ready (max 5s)
local waitStart = tick()
while not notifier and tick() - waitStart < 5 do task.wait(0.1) end
if not notifier then
    notifier = {
        update = function(_, m, s) warn("[FARM FALLBACK] " .. tostring(m) .. " " .. tostring(s)) end,
        stat = function() end,
        destroy = function() end,
    }
end

-- ══════════════ ANTI-AFK ══════════════
local antiAfkConn = nil
antiAfkConn = player.Idled:Connect(function()
    pcall(function() VirtualUser:CaptureController() end)
    pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
end)

-- ══════════════ STATS TRACKER ══════════════
local stats = {
    kills = 0,
    startTime = tick(),
    lastQuestComplete = 0,
}

local function UpdateStats()
    local elapsed = tick() - stats.startTime
    local mins = math.floor(elapsed / 60)
    local kpm = mins > 0 and string.format("%.1f", stats.kills / mins) or "—"
    notifier.stat("⚔ " .. stats.kills .. " kills | " .. kpm .. "/min | " .. mins .. "m")
end

-- ══════════════ QUEST DATA ══════════════
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

-- ══════════════ UTILITY FUNCTIONS (SAFE) ══════════════

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

-- EquipWeapon (returns success bool)
local function EquipWeapon()
    local char = player.Character
    if not char then return false end
    local held = char:FindFirstChildOfClass("Tool")
    if held and held.ToolTip:find(_G.WeaponType) then return true end
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip:find(_G.WeaponType) then
            char.Humanoid:EquipTool(v)
            return true
        end
    end
    return false
end

-- AutoHaki
local lastHakiTick = 0
local function AutoHaki()
    if tick() - lastHakiTick < 2 then return end  -- don't spam haki
    if player.Character and not player.Character:FindFirstChild("HasBuso") then
        pcall(function() commF:InvokeServer("Buso") end)
        lastHakiTick = tick()
    end
end

-- Attack: natural timing, adaptive cooldown by weapon type
local VIM = game:GetService("VirtualInputManager")
local lastAttackTick = 0

local function GetAttackCooldown()
    -- Sword = faster, Blox Fruit = slower
    if _G.WeaponType == "Melee" then return 0.32 end
    if _G.WeaponType == "Sword" then return 0.35 end
    return 0.4 -- Blox Fruit / other
end

local function Attack()
    local now = tick()
    local cd = GetAttackCooldown()
    if now - lastAttackTick < cd then return true end

    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return false end

    pcall(function() tool:Activate() end)
    pcall(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.015)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)

    lastAttackTick = now
    return true
end

-- Tween: capped 120 stud/s
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
    currentTween = TS:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    currentTween:Play()
    return dist
end

-- SmoothTP: fast but not instant
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

-- FindBestMob: prioritize LOWEST HP mob for faster kills
local function FindBestMob(NameMon, CFrameMon)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local candidates = {}

    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local mHrp = mob:FindFirstChild("HumanoidRootPart")
            if mHrp then
                local spawnDist = (mHrp.Position - CFrameMon.Position).Magnitude
                local playerDist = (hrp.Position - mHrp.Position).Magnitude
                if spawnDist < 250 then
                    table.insert(candidates, {
                        mob = mob,
                        hrp = mHrp,
                        dist = playerDist,
                        hpPct = mob.Humanoid.Health / mob.Humanoid.MaxHealth,
                    })
                end
            end
        end
    end

    if #candidates == 0 then
        -- Fallback: any mob regardless of spawn distance
        for _, mob in pairs(workspace.Enemies:GetChildren()) do
            if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                local mHrp = mob:FindFirstChild("HumanoidRootPart")
                if mHrp then
                    table.insert(candidates, {
                        mob = mob,
                        hrp = mHrp,
                        dist = (hrp.Position - mHrp.Position).Magnitude,
                        hpPct = mob.Humanoid.Health / mob.Humanoid.MaxHealth,
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    -- Sort: prioritize mobs already damaged (low HP%), then closest
    table.sort(candidates, function(a, b)
        -- If one is significantly damaged and the other isn't, prefer damaged
        if a.hpPct < 0.6 and b.hpPct >= 0.6 then return true end
        if b.hpPct < 0.6 and a.hpPct >= 0.6 then return false end
        -- Among similar HP, pick closest
        return a.dist < b.dist
    end)

    return candidates[1].mob
end

-- Server Hop (optional)
local function TryServerHop()
    if not _G.AutoServerHop then return end
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local url = "https://games.roblox.com/v1/games/" .. game.GameId .. "/servers/Public?sortOrder=Asc&limit=25"
        local data = HttpService:JSONDecode(game:HttpGet(url))
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TPS:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
        end
    end)
end

-- ══════════════ ERROR TRACKING ══════════════
local errorLog = {}
local function LogError(category, message)
    local entry = "[" .. category .. "] " .. message
    table.insert(errorLog, {time = tick(), msg = entry})
    if #errorLog > 15 then table.remove(errorLog, 1) end
    warn("[FARM ERR] " .. entry)
end

-- ══════════════ MAIN FARM LOOP ══════════════
local questFailedCount = 0
local bypassQuest = false
local questCooldown = 0
local noMobTimer = 0
local noDmgCounter = 0
local lastTrackedMob = nil
local lastTrackedHP = 0
local totalIdleTime = 0
local wasQuestActive = false  -- for instant re-take detection

task.spawn(function()
    notifier.update("—", "Initializing...", "waiting")
    warn("[SAFE FARM v3] Script dimulai.")

    while _G.PureAutoFarm and task.wait(0.15) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if not hrp or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            notifier.update("—", "Respawning...", "waiting")
            CleanupAntiJitter()
            continue
        end

        AntiJitter()
        UpdateStats()

        -- Read level
        local level = nil
        local ls = pcall(function() level = player.Data.Level.Value end)
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

        -- Detect quest just completed → instant re-take
        local questJustCompleted = wasQuestActive and not questActive
        wasQuestActive = questActive

        --------------------------------------------------------
        --  PHASE: TAKE QUEST
        --------------------------------------------------------
        if (not questActive and not bypassQuest) or questJustCompleted then
            notifier.update(NameMon, "Taking quest...", "quest")
            totalIdleTime = 0

            -- Cooldown (skip if quest just completed → instant re-take)
            if not questJustCompleted and tick() - questCooldown < 3.5 then
                continue
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
                    local nowVis = false
                    pcall(function() nowVis = player.PlayerGui.Main.Quest.Visible end)

                    if res == "Quest Already Active" or nowVis then
                        questFailedCount = 0
                        notifier.update(NameMon, "Quest active ✓", "farming")
                    else
                        questFailedCount = questFailedCount + 1
                        LogError("QUEST", "Rejected #" .. questFailedCount .. " (" .. tostring(res) .. ")")
                        notifier.update(NameMon, "⚠ Rejected #" .. questFailedCount, "error")
                        if questFailedCount > 3 then
                            warn("[FARM] Quest fail 3x → bypass ON")
                            bypassQuest = true
                        end
                    end
                end
            end

        --------------------------------------------------------
        --  PHASE: FARM MOB
        --------------------------------------------------------
        else
            local mob = FindBestMob(NameMon, CFrameMon)

            if mob then
                noMobTimer = 0
                totalIdleTime = 0
                local mobHrp = mob:FindFirstChild("HumanoidRootPart")
                if not mobHrp then continue end

                local mobPos = mobHrp.Position
                local farmPos = CFrame.new(mobPos + Vector3.new(0, 12, 0), mobPos)
                local dist = (hrp.Position - farmPos.Position).Magnitude

                if dist > 30 then
                    Tween(farmPos)
                    notifier.update(NameMon, "Approaching...", "travel")
                else
                    if currentTween then currentTween:Cancel() currentTween = nil end
                    SmoothTP(farmPos)
                    AutoHaki()

                    local equipped = EquipWeapon()
                    if not equipped then
                        LogError("WEAPON", "'" .. _G.WeaponType .. "' not found")
                        notifier.update(NameMon, "⚠ No weapon!", "error")
                    else
                        -- Damage tracking
                        if mob ~= lastTrackedMob then
                            -- Track kill from previous mob
                            if lastTrackedMob and lastTrackedMob:FindFirstChild("Humanoid")
                            and lastTrackedMob.Humanoid.Health <= 0 then
                                stats.kills = stats.kills + 1
                            end
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
                totalIdleTime = totalIdleTime + 0.15

                local waitPos = CFrameMon * CFrame.new(0, 15, 0)
                local dist = (hrp.Position - waitPos.Position).Magnitude

                if dist > 15 then
                    Tween(waitPos)
                else
                    if currentTween then currentTween:Cancel() currentTween = nil end
                    SmoothTP(waitPos)
                end

                notifier.update(NameMon, "Waiting spawn...", "waiting")

                if noMobTimer > 80 then
                    LogError("MOB", NameMon .. " not spawning (timeout)")
                    notifier.update(NameMon, "⚠ No spawn", "error")
                    noMobTimer = 0
                end

                -- Server hop if idle too long
                if totalIdleTime > _G.ServerHopTimeout and _G.AutoServerHop then
                    warn("[FARM] Idle > " .. _G.ServerHopTimeout .. "s → hopping server")
                    notifier.update(NameMon, "⚠ Server hop...", "error")
                    task.wait(1)
                    TryServerHop()
                end

                -- Reset bypass when quest complete
                if not questActive and bypassQuest then
                    bypassQuest = false
                    questFailedCount = 0
                end
            end
        end
    end

    -- Cleanup
    CleanupAntiJitter()
    if antiAfkConn then antiAfkConn:Disconnect() end
    notifier.update("—", "Stopped", "waiting")
    warn("[SAFE FARM v3] Script dihentikan.")
end)