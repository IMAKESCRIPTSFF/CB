local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hatchRemote = remotes:WaitForChild("HatchEggs")
local ticketsRemote = remotes:WaitForChild("ClaimTickets")
local playtimeRemote = remotes:WaitForChild("ClaimPlaytime")

local eggAmount = 10
local hatchEnabled = false
local ticketsEnabled = false
local playtimeEnabled = false
local tapEnabled = false
local minimized = false
local unloaded = false

local TICKET_INTERVAL = 60
local PLAYTIME_INTERVAL = 10
local HATCH_INTERVAL = 0.1
local TAP_INTERVAL = 0.05

local TAP_X = 765
local TAP_Y = 915
local TAP_HOLD = 0.02

-- Remove an older copy of the GUI
local oldGui = playerGui:FindFirstChild("AutoFarmGUI")
if oldGui then
    oldGui:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(270, 300)
main.Position = UDim2.new(0.5, -135, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(25, 24, 35)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(125, 85, 210)
stroke.Thickness = 1.5
stroke.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(38, 34, 55)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -85, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "Auto Farm"
title.TextColor3 = Color3.fromRGB(235, 225, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.fromOffset(30, 28)
minimizeButton.Position = UDim2.new(1, -68, 0, 7)
minimizeButton.BackgroundColor3 = Color3.fromRGB(90, 70, 130)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 20
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = header

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 6)
miniCorner.Parent = minimizeButton

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(30, 28)
closeButton.Position = UDim2.new(1, -34, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(160, 55, 75)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Egg amount input
local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.fromOffset(125, 28)
amountLabel.Position = UDim2.fromOffset(10, 48)
amountLabel.BackgroundTransparency = 1
amountLabel.Text = "Eggs per hatch:"
amountLabel.TextColor3 = Color3.fromRGB(220, 215, 235)
amountLabel.TextSize = 12
amountLabel.Font = Enum.Font.Gotham
amountLabel.TextXAlignment = Enum.TextXAlignment.Left
amountLabel.Parent = main

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.fromOffset(95, 28)
amountBox.Position = UDim2.fromOffset(160, 48)
amountBox.BackgroundColor3 = Color3.fromRGB(43, 40, 58)
amountBox.TextColor3 = Color3.new(1, 1, 1)
amountBox.PlaceholderText = "Amount"
amountBox.Text = tostring(eggAmount)
amountBox.ClearTextOnFocus = false
amountBox.TextSize = 13
amountBox.Font = Enum.Font.Gotham
amountBox.Parent = main

local amountCorner = Instance.new("UICorner")
amountCorner.CornerRadius = UDim.new(0, 6)
amountCorner.Parent = amountBox

amountBox.FocusLost:Connect(function()
    local value = tonumber(amountBox.Text)

    if value and value >= 1 then
        eggAmount = math.floor(value)
        amountBox.Text = tostring(eggAmount)
    else
        amountBox.Text = tostring(eggAmount)
    end
end)

-- Toggle button creator
local function createToggle(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(65, 50, 90)
    button.Text = text .. ": OFF"
    button.TextColor3 = Color3.fromRGB(245, 240, 255)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    return button
end

local hatchButton = createToggle("Auto Hatch", 83)
local ticketsButton = createToggle("Auto Claim Tickets", 125)
local playtimeButton = createToggle("Auto Claim Playtime", 167)
local tapButton = createToggle("Auto Tap", 209)

local function updateButton(button, name, enabled)
    button.Text = name .. (enabled and ": ON" or ": OFF")
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(90, 125, 75)
        or Color3.fromRGB(65, 50, 90)
end

-- Auto Hatch
hatchButton.MouseButton1Click:Connect(function()
    hatchEnabled = not hatchEnabled
    updateButton(hatchButton, "Auto Hatch", hatchEnabled)
end)

task.spawn(function()
    while not unloaded do
        if hatchEnabled then
            local amount = eggAmount

            pcall(function()
                hatchRemote:InvokeServer("Cloud Egg", amount)
            end)

            task.wait(HATCH_INTERVAL)
        else
            task.wait(0.1)
        end
    end
end)

-- Auto Claim Tickets
ticketsButton.MouseButton1Click:Connect(function()
    ticketsEnabled = not ticketsEnabled
    updateButton(ticketsButton, "Auto Claim Tickets", ticketsEnabled)
end)

task.spawn(function()
    while not unloaded do
        if ticketsEnabled then
            pcall(function()
                ticketsRemote:FireServer()
            end)

            for _ = 1, TICKET_INTERVAL * 10 do
                if unloaded or not ticketsEnabled then
                    break
                end
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

-- Auto Claim Playtime: claim IDs 1 through 9 every 10 seconds
playtimeButton.MouseButton1Click:Connect(function()
    playtimeEnabled = not playtimeEnabled
    updateButton(playtimeButton, "Auto Claim Playtime", playtimeEnabled)
end)

task.spawn(function()
    while not unloaded do
        if playtimeEnabled then
            for rewardId = 1, 9 do
                if unloaded or not playtimeEnabled then
                    break
                end

                pcall(function()
                    playtimeRemote:FireServer(rewardId)
                end)
            end

            for _ = 1, PLAYTIME_INTERVAL * 10 do
                if unloaded or not playtimeEnabled then
                    break
                end
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

-- Auto Tap
tapButton.MouseButton1Click:Connect(function()
    tapEnabled = not tapEnabled
    updateButton(tapButton, "Auto Tap", tapEnabled)
end)

task.spawn(function()
    while not unloaded do
        if tapEnabled then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(
                    TAP_X, TAP_Y, 0, true, game, 0
                )
                task.wait(TAP_HOLD)
                VirtualInputManager:SendMouseButtonEvent(
                    TAP_X, TAP_Y, 0, false, game, 0
                )
            end)

            task.wait(TAP_INTERVAL)
        else
            task.wait(0.1)
        end
    end
end)

-- Minimize / restore
local function setMinimized(state)
    minimized = state

    amountLabel.Visible = not state
    amountBox.Visible = not state
    hatchButton.Visible = not state
    ticketsButton.Visible = not state
    playtimeButton.Visible = not state
    tapButton.Visible = not state

    main.Size = state
        and UDim2.fromOffset(270, 42)
        or UDim2.fromOffset(270, 255)

    minimizeButton.Text = state and "+" or "-"
end

minimizeButton.MouseButton1Click:Connect(function()
    setMinimized(not minimized)
end)

-- Drag GUI using the header
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Close and stop all loops
closeButton.MouseButton1Click:Connect(function()
    unloaded = true
    hatchEnabled = false
    ticketsEnabled = false
    playtimeEnabled = false
    tapEnabled = false
    gui:Destroy()
end)
