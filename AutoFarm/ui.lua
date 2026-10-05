local player = game:GetService("Players").LocalPlayer
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local notifier = {}

local oldGui = player.PlayerGui:FindFirstChild("FarmNotifier")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FarmNotifier"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = player.PlayerGui

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

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.Size = UDim2.new(1, -16, 0, 2)
accent.Position = UDim2.new(0, 8, 0, 0)
accent.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
accent.BorderSizePixel = 0
accent.Parent = bar

Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 1)

local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 10, 0.5, -4)
dot.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
dot.BorderSizePixel = 0
dot.Parent = bar

Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

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

local statsBar = Instance.new("Frame")
statsBar.Name = "StatsBar"
statsBar.Size = UDim2.new(0, 220, 0, 18)
statsBar.Position = UDim2.new(0.5, -110, 0, 46)
statsBar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
statsBar.BackgroundTransparency = 0.2
statsBar.BorderSizePixel = 0
statsBar.Active = true
statsBar.Parent = gui

Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 6)

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = Color3.fromRGB(45, 45, 70)
statsStroke.Thickness = 1
statsStroke.Transparency = 0.5
statsStroke.Parent = statsBar

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsText"
statsLabel.Size = UDim2.new(1, -12, 1, 0)
statsLabel.Position = UDim2.new(0, 6, 0, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Kills: 0 | Elapsed: 0m"
statsLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
statsLabel.TextSize = 9
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextXAlignment = Enum.TextXAlignment.Center
statsLabel.Parent = statsBar

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosBar = nil
local startPosStats = nil

bar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosBar = bar.Position
        startPosStats = statsBar.Position
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
            startPosBar.X.Scale, startPosBar.X.Offset + delta.X,
            startPosBar.Y.Scale, startPosBar.Y.Offset + delta.Y
        )
        statsBar.Position = UDim2.new(
            startPosStats.X.Scale, startPosStats.X.Offset + delta.X,
            startPosStats.Y.Scale, startPosStats.Y.Offset + delta.Y
        )
    end
end)

local STATUS_COLORS = {
    farming  = Color3.fromRGB(80, 200, 120),
    travel   = Color3.fromRGB(90, 155, 255),
    quest    = Color3.fromRGB(255, 195, 55),
    waiting  = Color3.fromRGB(160, 160, 175),
    error    = Color3.fromRGB(255, 75, 75),
}

function notifier.update(mob, status, sType)
    if mob then mobLabel.Text = mob end
    if status then statusLabel.Text = status end
    local col = STATUS_COLORS[sType] or STATUS_COLORS.waiting
    dot.BackgroundColor3 = col
    accent.BackgroundColor3 = col
    if sType == "error" then
        pcall(function()
            TS:Create(dot, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
                {BackgroundTransparency = 0.7}):Play()
        end)
    else
        dot.BackgroundTransparency = 0
    end
end

function notifier.stat(text)
    if text then statsLabel.Text = text end
end

function notifier.destroy()
    pcall(function() gui:Destroy() end)
end

getgenv().FarmNotifier = notifier
return notifier
