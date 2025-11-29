-- DashScript for Roblox
-- Dashes character left and right repeatedly with facing direction
-- Dash speed is 10000
-- Character stays in place, only facing direction changes
-- GUI with ON and OFF buttons for mobile control

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local dashSpeed = 10000
local dashDistance = 5 -- small offset for dash effect, actual movement is locked
local dashDuration = 0.05 -- short dash duration
local dashing = false

-- Variables to control dash direction
local dashLeft = true

-- Lock character position to initial position to prevent forward/backward movement
local initialPosition = humanoidRootPart.Position

-- Create ScreenGui for mobile buttons
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DashGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 60)
frame.Position = UDim2.new(0.5, -75, 0.9, 0)
frame.BackgroundTransparency = 0.3
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.Parent = screenGui

local onButton = Instance.new("TextButton")
onButton.Size = UDim2.new(0, 70, 0, 50)
onButton.Position = UDim2.new(0, 5, 0, 5)
onButton.Text = "ON"
onButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
onButton.TextColor3 = Color3.new(1, 1, 1)
onButton.Parent = frame

local offButton = Instance.new("TextButton")
offButton.Size = UDim2.new(0, 70, 0, 50)
offButton.Position = UDim2.new(0, 75, 0, 5)
offButton.Text = "OFF"
offButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
offButton.TextColor3 = Color3.new(1, 1, 1)
offButton.Parent = frame

local dashConnection

local function dashCycle()
    -- Alternates dash direction left/right repeatedly
    while dashing do
        if not humanoidRootPart or not humanoidRootPart.Parent then break end

        -- Face direction: left or right on X axis
        local lookVector
        if dashLeft then
            lookVector = Vector3.new(-1, 0, 0)
        else
            lookVector = Vector3.new(1, 0, 0)
        end

        -- Set facing direction
        humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.lookAt(Vector3.new(), lookVector)

        -- Calculate dash target position (small offset left or right)
        local dashOffset = dashLeft and Vector3.new(-dashDistance, 0, 0) or Vector3.new(dashDistance, 0, 0)
        local targetPos = initialPosition + dashOffset

        -- Move instantly to target position with dash speed effect simulated by tweening
        local startPos = humanoidRootPart.Position
        local elapsed = 0
        local dt

        while elapsed < dashDuration and dashing do
            dt = RunService.Heartbeat:Wait()
            elapsed = elapsed + dt
            local alpha = math.clamp(elapsed / dashDuration, 0, 1)
            local newPos = startPos:Lerp(targetPos, alpha)
            humanoidRootPart.CFrame = CFrame.new(newPos) * CFrame.lookAt(Vector3.new(), lookVector)
        end

        -- Snap to target position to avoid small gaps
        humanoidRootPart.CFrame = CFrame.new(targetPos) * CFrame.lookAt(Vector3.new(), lookVector)

        -- Return to initial position instantly to prevent drifting
        humanoidRootPart.CFrame = CFrame.new(initialPosition) * CFrame.lookAt(Vector3.new(), lookVector)

        -- Swap dash direction
        dashLeft = not dashLeft

        -- Small wait before next dash cycle
        wait(0.1)
    end
end

local function startDashing()
    if dashing then return end
    dashing = true
    initialPosition = humanoidRootPart.Position
    dashConnection = coroutine.wrap(dashCycle)
    dashConnection()
end

local function stopDashing()
    dashing = false
    if dashConnection then
        dashConnection = nil
    end
    -- Reset facing direction forward (positive Z)
    humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.lookAt(Vector3.new(), Vector3.new(0, 0, 1))
end

onButton.MouseButton1Click:Connect(function()
    startDashing()
end)

offButton.MouseButton1Click:Connect(function()
    stopDashing()
end)

-- Also reset on character respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    initialPosition = humanoidRootPart.Position
    stopDashing()
end)
