-- SAITAMA SERIOUS SIDEHOPS (SECRET GUI - ON/OFF BUTTONS)
-- No accidental activation → 100% safe in front of friends
-- Place in StarterPlayer → StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- SETTINGS (Saitama Anime Look)
local FWD_SPEED = 50
local SIDE_AMP = 7
local SIDE_FREQ = 250
local AFTERIMAGE_INTERVAL = 0.006
local AFTERIMAGE_LIFETIME = 1.5
local AFTERIMAGE_START_TRANS = 0.2

local BASEPLATE_MIN = -250
local BASEPLATE_MAX = 250

local SAITAMA_COLORS = {Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,0), Color3.fromRGB(255,240,150)}

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local active = false
local conn = nil
local trail, att0, att1 = nil, nil, nil
local lastImg = 0

local fx = Instance.new("Folder", workspace)
fx.Name = "SecretSaitamaFX"

-- === SECRET GUI (Only YOU see it) ===
local gui = Instance.new("ScreenGui")
gui.Name = "SaitamaSecretGUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 120)
frame.Position = UDim2.new(0.5, -150, 0, 20)  -- Top center
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 255, 0)
frame.Visible = true  -- Start visible
frame.Active = true  -- Make it interactable
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "SAITAMA MODE"
title.TextColor3 = Color3.fromRGB(255, 255, 0)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local onBtn = Instance.new("TextButton")
onBtn.Size = UDim2.new(0.45, 0, 0, 50)
onBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
onBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
onBtn.Text = "ON"
onBtn.TextColor3 = Color3.new(1,1,1)
onBtn.TextScaled = true
onBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", onBtn).CornerRadius = UDim.new(0, 12)
onBtn.Parent = frame

local offBtn = Instance.new("TextButton")
offBtn.Size = onBtn.Size
offBtn.Position = UDim2.new(0.5, 0, 0.4, 0)
offBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
offBtn.Text = "OFF"
offBtn.TextColor3 = Color3.new(1,1,1)
offBtn.TextScaled = true
offBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", offBtn).CornerRadius = UDim.new(0, 12)
offBtn.Parent = frame

-- Make GUI draggable
local dragging = false
local dragInput, mousePos, framePos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        frame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Toggle GUI visibility with INSERT key only
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        frame.Visible = not frame.Visible
    end
end)

-- Movement & Effects
local function getDir()
    local m = Humanoid.MoveDirection
    if m.Magnitude == 0 then
        local l = Camera.CFrame.LookVector
        m = Vector3.new(l.X, 0, l.Z).Unit
    end
    return m.Unit
end

local function createAfterimage()
    local model = Instance.new("Model")
    for _, p in pairs(Character:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "HumanoidRootPart" then
            local c = p:Clone()
            c.Anchored = true
            c.CanCollide = false
            c.Material = Enum.Material.Neon
            c.Color = SAITAMA_COLORS[math.random(1,#SAITAMA_COLORS)]
            c.Transparency = AFTERIMAGE_START_TRANS
            c.CFrame = p.CFrame
            c.Parent = model
        end
    end
    model.Parent = fx
    for _, p in pairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            TweenService:Create(p, TweenInfo.new(AFTERIMAGE_LIFETIME*0.8), {Transparency = 1}):Play()
        end
    end
    Debris:AddItem(model, AFTERIMAGE_LIFETIME)
end

local function startSidehops()
    if active then return end
    active = true
    Humanoid.PlatformStand = true

    trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,0))
    trail.Transparency = NumberSequence.new(0.05, 1)
    trail.Lifetime = 0.15
    trail.WidthScale = NumberSequence.new(15, 0)
    att0 = Instance.new("Attachment", Root); att0.Position = Vector3.new(0,-4,0)
    att1 = Instance.new("Attachment", Root); att1.Position = Vector3.new(0,4,0)
    trail.Attachment0 = att0; trail.Attachment1 = att1; trail.Parent = Root

    conn = RunService.Heartbeat:Connect(function(dt)
        if not active then return end
        local fwd = getDir()
        local right = Root.CFrame.RightVector.Unit
        local sideVel = SIDE_AMP * 2 * math.pi * SIDE_FREQ * math.cos(tick() * 2 * math.pi * SIDE_FREQ)
        local delta = fwd * FWD_SPEED * dt + right * sideVel * dt
        local newPos = Root.Position + delta

        newPos = Vector3.new(
            math.clamp(newPos.X, BASEPLATE_MIN, BASEPLATE_MAX),
            Root.Position.Y,
            math.clamp(newPos.Z, BASEPLATE_MIN, BASEPLATE_MAX)
        )

        Root.CFrame = CFrame.lookAt(newPos, newPos + fwd)

        if tick() - lastImg >= AFTERIMAGE_INTERVAL then
            createAfterimage()
            lastImg = tick()
        end
    end)
end

local function stopSidehops()
    if not active then return end
    active = false
    if conn then conn:Disconnect(); conn = nil end
    if trail then trail:Destroy(); trail = nil end
    if att0 then att0:Destroy(); att0 = nil end
    if att1 then att1:Destroy(); att1 = nil end
    Humanoid.PlatformStand = false
end

onBtn.Activated:Connect(startSidehops)
offBtn.Activated:Connect(stopSidehops)

-- Respawn
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid")
    Root = c:WaitForChild("HumanoidRootPart")
    stopSidehops()
end)

print("SAITAMA SECRET MODE LOADED")
print("Press INSERT to toggle GUI visibility")
print("Drag the GUI to move it around")
print("Now you can flex ONLY when you want")
