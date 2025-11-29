-- DashScript for Roblox with instantaneous left-right dash and afterimages (no delay)
-- Character faces the initial facing direction when dash starts
-- Dash speed is instant, creating afterimage effect
-- Character stays locked at initial position horizontally
-- Mobile GUI with ON and OFF buttons

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local dashDistance = 5 -- small offset for dash left/right
local dashing = false
local dashLeft = true

local initialPosition
local facingDirection

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

local function createAfterimage()
    local clone = character:Clone()
    clone.Name = "Afterimage"
    -- Remove scripts and unnecessary parts to optimize performance
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.Transparency = 0.5
            descendant.Material = Enum.Material.Neon
            descendant.CastShadow = false
        elseif descendant:IsA("Decal") then
            descendant.Transparency = 0.5
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            descendant.Enabled = false
        end
    end
    clone.Parent = workspace

    -- Fade out and remove after 0.3 seconds
    local fadeTime = 0.3
    local fadeSteps = 10
    local waitTime = fadeTime / fadeSteps

    spawn(function()
        for i = 1, fadeSteps do
            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = part.Transparency + (0.5 / fadeSteps)
                elseif part:IsA("Decal") then
                    part.Transparency = part.Transparency + (0.5 / fadeSteps)
                end
            end
            wait(waitTime)
        end
        clone:Destroy()
    end)
end

local function dashCycle()
    while dashing do
        if not humanoidRootPart or not humanoidRootPart.Parent then break end

        createAfterimage()

        local dashOffset = dashLeft and Vector3.new(-dashDistance, 0, 0) or Vector3.new(dashDistance, 0, 0)
        local targetPos = initialPosition + dashOffset

        humanoidRootPart.CFrame = CFrame.new(targetPos, targetPos + facingDirection)
        humanoidRootPart.CFrame = CFrame.new(initialPosition, initialPosition + facingDirection)

        dashLeft = not dashLeft

        RunService.Heartbeat:Wait() -- Yield to next frame, no delay
    end
end

local dashCoroutine

local function startDashing()
    if dashing then return end
    dashing = true
    initialPosition = humanoidRootPart.Position
    facingDirection = humanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
    dashCoroutine = coroutine.create(dashCycle)
    coroutine.resume(dashCoroutine)
end

local function stopDashing()
    dashing = false
    if dashCoroutine and coroutine.status(dashCoroutine) ~= "dead" then
        coroutine.resume(dashCoroutine)
    end
    humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.lookAt(Vector3.new(), Vector3.new(0, 0, 1))
end

onButton.MouseButton1Click:Connect(startDashing)
offButton.MouseButton1Click:Connect(stopDashing)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    initialPosition = humanoidRootPart.Position
    stopDashing()
end)
