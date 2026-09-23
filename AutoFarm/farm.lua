local player = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local commF = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local workspace = game:GetService("Workspace")
_G.PureAutoFarm = true
_G.WeaponType = "Melee" 
getgenv().Sea1 = game.PlaceId == 2753915549
getgenv().Sea2 = game.PlaceId == 4442274612
getgenv().Sea3 = game.PlaceId == 7449423635
getgenv().SelectMonster = getgenv().SelectMonster or ""
task.spawn(function()
    local s, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/wh1tehourse/vtrunc/main/data.lua"))()
    end)
    if not s then warn("Failed to load data.lua: ", err) end
end)
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
local function AntiJitter()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bv = hrp:FindFirstChild("FarmBV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "FarmBV"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp
    end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end
local function EquipWeapon()
    local char = player.Character
    if not char then return end
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip:find(_G.WeaponType) then
            char.Humanoid:EquipTool(v)
            break
        end
    end
end
local function AutoHaki()
    if player.Character and not player.Character:FindFirstChild("HasBuso") then
        pcall(function() commF:InvokeServer("Buso") end)
    end
end
local hitCounters = {}
local lastHealths = {}
local function DiagnosticDamage(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return end
    local mobName = mob.Name
    local health = mob.Humanoid.Health
    if not hitCounters[mobName] then
        hitCounters[mobName] = 0
        lastHealths[mobName] = health
    end
    if health < lastHealths[mobName] then
        hitCounters[mobName] = 0
        lastHealths[mobName] = health
        return
    end
    hitCounters[mobName] = hitCounters[mobName] + 1
    if hitCounters[mobName] > 30 then
        local diag = "[DIAGNOSIS DETEKTIF: NO DAMAGE]\nTarget: " .. mobName .. "\n"
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then
            diag = diag .. "❌ SENJATA: ERROR! Karakter ga megang senjata.\n"
        else
            diag = diag .. "✅ SENJATA: OK (" .. tool.Name .. ")\n"
        end
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local mobHrp = mob:FindFirstChild("HumanoidRootPart")
        if hrp and mobHrp then
            local dist = (hrp.Position - mobHrp.Position).Magnitude
            if dist > 35 then
                diag = diag .. "❌ JARAK FISIK: Kejauhan (" .. math.floor(dist) .. " stud).\n"
            else
                diag = diag .. "✅ JARAK FISIK: Dekat (" .. math.floor(dist) .. " stud).\n"
            end
        end
        local env = getgenv and getgenv() or _G
        local cfHooked = false
        if env.CombatFramework and env.CombatFramework.activeController then
            diag = diag .. "✅ COMBAT_FRAMEWORK: Hook Berhasil Terbaca!\n"
            cfHooked = true
        else
            diag = diag .. "❌ COMBAT_FRAMEWORK: Gagal di-hook! Executor memblokir require.\n"
        end
        diag = diag .. "=> KESIMPULAN: "
        if not cfHooked then
            diag = diag .. "Metode utama gagal karena CombatFramework diblokir oleh executor Arceus X. Kita butuh ganti ke metode NetworkOwnership (Spam klik biasa tapi jarak mob 0)."
        else
            diag = diag .. "CombatFramework sukses, senjata OK. Tapi damage ga masuk karena mob ngalamin DESYNC (di layar lu keseret ke bawah, tapi di server mob-nya ketinggalan di atas/belakang)."
        end
        warn(diag)
        if setclipboard then setclipboard(diag) end
        hitCounters[mobName] = 0
    end
end
local VIM = game:GetService("VirtualInputManager")
local function Attack(enemiesTable)
    if #enemiesTable == 0 then return end
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    pcall(function()
        tool:Activate()
    end)
    pcall(function()
        local env = getgenv and getgenv() or _G
        if not env.CombatFramework then
            env.CombatFramework = require(player.PlayerScripts.CombatFramework)
        end
        local activeController = env.CombatFramework.activeController
        if activeController then
            activeController.timeToNextAttack = 0
            activeController.hitboxMagnitude = 60
            activeController:attack()
        end
    end)
    pcall(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
    DiagnosticDamage(enemiesTable[1][1])
end
local currentTween = nil
local function Tween(targetCFrame)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 9999 end
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist < 5 then 
        if currentTween then currentTween:Cancel() end
        return dist 
    end
    local speed = 300
    if dist < 100 then speed = 150 end
    if currentTween then currentTween:Cancel() end
    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    currentTween = TS:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()
    return dist
end
local function MagnetMobs(NameMon, anchorCFrame, primaryMob)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local enemiesToHit = {}
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local mobHrp = mob:FindFirstChild("HumanoidRootPart")
            if mobHrp and (hrp.Position - mobHrp.Position).Magnitude < 300 then
                for _, part in pairs(mob:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                        part.Velocity = Vector3.zero
                    end
                end
                if mob ~= primaryMob then
                    mobHrp.CFrame = anchorCFrame
                end
                mobHrp.Size = Vector3.new(10, 10, 10)
                mob.Humanoid.WalkSpeed = 0
                mob.Humanoid.JumpPower = 0
                mob.Humanoid:ChangeState(11) 
                table.insert(enemiesToHit, {mob, mobHrp})
            end
        end
    end
    return enemiesToHit
end
local questFailedCount = 0
local bypassQuest = false
task.spawn(function()
    warn("[PURE FARM] Script Dimulai. Anti-Fling & Ground-Anchor Aktif.")
    while _G.PureAutoFarm and task.wait(0.1) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or char.Humanoid.Health <= 0 then continue end
        AntiJitter()
        local level = player.Data.Level.Value
        local NameMon, NameQuest, QuestLv, CFrameQ, CFrameMon = GetQuestData(level)
        local questActive = player.PlayerGui.Main.Quest.Visible
        if not questActive and not bypassQuest then
            local targetPos = CFrameQ * CFrame.new(0, 5, 0)
            local dist = (hrp.Position - targetPos.Position).Magnitude
            if dist > 20 then
                Tween(targetPos)
            else
                if currentTween then currentTween:Cancel() currentTween = nil end
                hrp.CFrame = targetPos 
                task.wait(0.5)
                local res = commF:InvokeServer("StartQuest", NameQuest, QuestLv)
                if res == "Quest Already Active" or player.PlayerGui.Main.Quest.Visible then
                    questFailedCount = 0
                    warn("[PURE FARM] Quest Berhasil Aktif!")
                else
                    questFailedCount = questFailedCount + 1
                    warn("[PURE FARM] Server Menolak Quest. Percobaan ke-" .. tostring(questFailedCount))
                    if questFailedCount > 3 then
                        warn("[PURE FARM] Quest gagal 3x. BYPASS DIAKTIFKAN. Langsung eksekusi Mob!")
                        bypassQuest = true
                    end
                end
            end
        else
            local primaryMob = nil
            for _, mob in pairs(workspace.Enemies:GetChildren()) do
                if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    local mHrp = mob:FindFirstChild("HumanoidRootPart")
                    if mHrp and math.abs(mHrp.Position.Y - CFrameMon.Position.Y) < 120 then
                        primaryMob = mob
                        break
                    end
                end
            end
            if not primaryMob then
                for _, mob in pairs(workspace.Enemies:GetChildren()) do
                    if mob.Name == NameMon and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        if mob:FindFirstChild("HumanoidRootPart") then
                            primaryMob = mob
                            break
                        end
                    end
                end
            end
            if primaryMob then
                local mobHrp = primaryMob:FindFirstChild("HumanoidRootPart")
                if mobHrp then
                    local groundCFrame = mobHrp.CFrame
                    local groundPos = mobHrp.Position
                    local farmPos = CFrame.new(groundPos + Vector3.new(0, 18, 0), groundPos)
                    local dist = (hrp.Position - farmPos.Position).Magnitude
                    if dist > 40 then
                        Tween(farmPos)
                    else
                        if currentTween then currentTween:Cancel() currentTween = nil end
                        hrp.CFrame = farmPos 
                    end
                    AutoHaki()
                    EquipWeapon()
                    local enemies = MagnetMobs(NameMon, groundCFrame, primaryMob)
                    Attack(enemies)
                end
            else
                local waitPos = CFrameMon * CFrame.new(0, 20, 0)
                local dist = (hrp.Position - waitPos.Position).Magnitude
                if dist > 15 then
                    Tween(waitPos)
                else
                    if currentTween then currentTween:Cancel() currentTween = nil end
                    hrp.CFrame = waitPos
                end
            end
        end
    end
end)