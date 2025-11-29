local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local INITIAL_DASH_POWER = 125
local DASH_DURATION = 0.5
local DASH_COOLDOWN = 0
local MIN_VELOCITY = 5
local TURN_SPEED = 0.75
local DECELERATION = 1
local START_DELAY = 0
local STOP_POINT = 0.5
local SLOWDOWN_START = 0.6
local STOP_DURATION = 0.05

-- Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local canDash = true
local isDashing = false
local dashVelocity = Vector3.new(0, 0, 0)
local initialDashDir = Vector3.new(0, 0, 0)

local dashLeft = true -- toggle for dash direction
local dashingEnabled = false -- toggle for dash on/off via GUI

-- Function to get dash direction (left/right dash only, no forward/backward)
local function getDashDirection()
    local rightVec = Camera.CFrame.RightVector
    rightVec = Vector3.new(rightVec.X, 0, rightVec.Z).Unit
    return rightVec
end

local function getDashDirectionToggle()
    local rightVec = getDashDirection()
    if dashLeft then
        return -rightVec
    else
        return rightVec
    end
end

local function dash()
    if not canDash or isDashing then return end

    canDash = false
    isDashing = true
    dashVelocity = Vector3.new(0, 0, 0)

    initialDashDir = getDashDirectionToggle()
    dashLeft = not dashLeft

    local dashStart = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function(delta)
        if not isDashing then
            connection:Disconnect()
            return
        end

        local elapsed = tick() - dashStart
        local progress = elapsed / DASH_DURATION

        if progress < START_DELAY / DASH_DURATION then
            dashVelocity = Vector3.new(0,0,0)
        elseif progress < STOP_POINT then
            local accelerationProgress = (progress - START_DELAY / DASH_DURATION) / (STOP_POINT - START_DELAY / DASH_DURATION)
            local speedFactor = accelerationProgress * (2 - accelerationProgress)
            local targetVelocity = initialDashDir * (INITIAL_DASH_POWER * speedFactor)
            dashVelocity = dashVelocity:Lerp(targetVelocity, TURN_SPEED * delta * 60)
        elseif progress < SLOWDOWN_START then
            local targetVelocity = initialDashDir * INITIAL_DASH_POWER
            dashVelocity = dashVelocity:Lerp(targetVelocity, TURN_SPEED * delta * 60)
        else
            local slowdownProgress = (progress - SLOWDOWN_START) / (1 - SLOWDOWN_START)
            local slowdownFactor = (1 - slowdownProgress) ^ 2
            local targetVelocity = initialDashDir * (INITIAL_DASH_POWER * slowdownFactor)
            dashVelocity = dashVelocity:Lerp(targetVelocity, TURN_SPEED * delta * 60)
        end

        if Root then
            Root.CFrame = Root.CFrame + dashVelocity * delta

            if dashVelocity.Magnitude > MIN_VELOCITY then
                local lookAt = Root.Position + dashVelocity.Unit
                Root.CFrame = CFrame.lookAt(Root.Position, Vector3.new(lookAt.X, Root.Position.Y, lookAt.Z))
            end
        end

        if elapsed >= DASH_DURATION then
            isDashing = false
            connection:Disconnect()
            if Humanoid then
                Humanoid.WalkSpeed = 0
                task.delay(STOP_DURATION, function()
                    if Humanoid then
                        Humanoid.WalkSpeed = 16
                        task.delay(DASH_COOLDOWN, function()
                            canDash = true
                        end)
                    end
                end)
            end
        end
    end)
end

-- Loop that triggers dash repeatedly when enabled
spawn(function()
    while true do
        if dashingEnabled then
            dash()
            -- Wait dash duration plus a small gap before next dash
            task.wait(DASH_DURATION + 0.1)
        else
            task.wait(0.1)
        end
    end
end)

-- GUI creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DashToggleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

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

onButton.MouseButton1Click:Connect(function()
    dashingEnabled = true
end)

offButton.MouseButton1Click:Connect(function()
    dashingEnabled = false
end)

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")
    canDash = true
    isDashing = false
    dashingEnabled = false
end)

print("Dash Script Loaded! Use ON/OFF buttons to toggle dash.")
