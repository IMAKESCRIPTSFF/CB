
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hatchRemote = remotes:WaitForChild("HatchEggs")
local ticketsRemote = remotes:WaitForChild("ClaimTickets")

local hatchEnabled = false
local ticketsEnabled = false
local tapEnabled = false
local minimized = false

local HATCH_INTERVAL = 0.1
local TICKET_INTERVAL = 60
local TAP_INTERVAL = 0.05
local TAP_HOLD = 0.02
local TAP_X, TAP_Y = 765, 915

-- Theme
local BG = Color3.fromRGB(22, 24, 33)
local PANEL = Color3.fromRGB(32, 35, 47)
local PURPLE = Color3.fromRGB(139, 92, 246)
local GREEN = Color3.fromRGB(46, 170, 115)
local RED = Color3.fromRGB(180, 65, 75)
local WHITE = Color3.fromRGB(245, 245, 255)
local MUTED = Color3.fromRGB(165, 170, 190)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(270, 220)
frame.Position = UDim2.new(0.5, -135, 0.5, -110)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 68, 88)
stroke.Thickness = 1
stroke.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = PANEL
header.BorderSizePixel = 0
header.Parent = frame

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 3)
accent.BackgroundColor3 = PURPLE
accent.BorderSizePixel = 0
accent.Parent = header

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(13, 3)
title.Size = UDim2.new(1, -95, 1, -5)
title.BackgroundTransparency = 1
title.Text = "AUTO FARM"
title.TextColor3 = WHITE
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local function headerButton(text, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(27, 27)
    b.Position = UDim2.new(1, x, 0, 8)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = 17
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Parent = header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local minimizeButton = headerButton("-", -61, Color3.fromRGB(65, 68, 88))
local closeButton = headerButton("X", -31, RED)

-- Existing feature buttons
local function createToggle(label, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -24, 0, 43)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = RED
    button.Text = label .. ": OFF"
    button.TextColor3 = WHITE
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = frame

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(65, 68, 88)
    border.Thickness = 1
    border.Parent = button

    return button
end

local hatchButton = createToggle("Auto Hatch", 55)
local ticketsButton = createToggle("Auto Claim Tickets", 105)
local tapButton = createToggle("Auto Tap", 155)

local function updateButton(button, label, enabled)
    button.Text = label .. (enabled and ": ON" or ": OFF")
    button.BackgroundColor3 = enabled and GREEN or RED
end

hatchButton.Activated:Connect(function()
    hatchEnabled = not hatchEnabled
    updateButton(hatchButton, "Auto Hatch", hatchEnabled)
end)

ticketsButton.Activated:Connect(function()
    ticketsEnabled = not ticketsEnabled
    updateButton(ticketsButton, "Auto Claim Tickets", ticketsEnabled)
end)

tapButton.Activated:Connect(function()
    tapEnabled = not tapEnabled
    updateButton(tapButton, "Auto Tap", tapEnabled)
end)

-- Minimize / restore
minimizeButton.Activated:Connect(function()
    minimized = not minimized

    hatchButton.Visible = not minimized
    ticketsButton.Visible = not minimized
    tapButton.Visible = not minimized

    frame.Size = minimized
        and UDim2.fromOffset(270, 42)
        or UDim2.fromOffset(270, 220)

    minimizeButton.Text = minimized and "+" or "-"
end)

-- Close
closeButton.Activated:Connect(function()
    hatchEnabled = false
    ticketsEnabled = false
    tapEnabled = false
    gui:Destroy()
end)

-- Auto Hatch: same arguments and interval
task.spawn(function()
    while gui.Parent do
        if hatchEnabled then
            local ok, err = pcall(function()
                hatchRemote:InvokeServer("Cloud Egg", 10)
            end)

            if not ok then
                warn("Auto Hatch error:", err)
                hatchEnabled = false
                updateButton(hatchButton, "Auto Hatch", false)
            end
        end

        task.wait(HATCH_INTERVAL)
    end
end)

-- Auto Claim Tickets: once every 60 seconds
task.spawn(function()
    while gui.Parent do
        if ticketsEnabled then
            local ok, err = pcall(function()
                ticketsRemote:FireServer()
            end)

            if not ok then
                warn("Ticket claim error:", err)
            end

            for i = 1, 600 do
                if not gui.Parent or not ticketsEnabled then
                    break
                end
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end)

-- Auto Tap: same coordinates and input method
task.spawn(function()
    while gui.Parent do
        if tapEnabled then
            local ok, err = pcall(function()
                VIM:SendMouseButtonEvent(
                    TAP_X, TAP_Y, 0, true, game, 0
                )

                task.wait(TAP_HOLD)

                VIM:SendMouseButtonEvent(
                    TAP_X, TAP_Y, 0, false, game, 0
                )
            end)

            if not ok then
                warn("Auto Tap error:", err)
                tapEnabled = false
                updateButton(tapButton, "Auto Tap", false)
            end

            task.wait(TAP_INTERVAL)
        else
            task.wait(0.05)
        end
    end
end)
