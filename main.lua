-- ==========================================
-- ROBLOX LUAU SCRIPT FOR GAME CHEATS - DELFINBOT V2.0
-- Features: Base ESP, Auto-Grab, Infinite Kill Aura, Base Opener, Fly, Dash
-- With Modern GUI (Mobile & PC Friendly)
-- ==========================================

-- Bootloader: Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character, humanoidRootPart, humanoid

-- ==========================================
-- CONFIGURATIONS
-- ==========================================
local Config = {
    AutoGrabRange = 18,
    KillAuraRange = 12,
    DashDistance = 12,
    FlySpeed = 50,
}

-- Toggles
local _G = _G or {}
_G.BaseESP = _G.BaseESP or false
_G.AutoGrab = _G.AutoGrab or false
_G.InfiniteKillAura = _G.InfiniteKillAura or false
_G.FlyMode = _G.FlyMode or false

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local function getCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    return character, humanoidRootPart, humanoid
end

getCharacter()  -- Initial call

-- ==========================================
-- BASE ESP: Find and modify Walls, Gates, Fences
-- ==========================================
local espParts = {}

local function updateBaseESP()
    if _G.BaseESP then
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name == "Wall" or part.Name == "Gate" or part.Name == "Fence") then
                if not espParts[part] then
                    espParts[part] = true
                    part.Transparency = 0.5
                    part.CanCollide = true
                end
            end
        end
    else
        for part in pairs(espParts) do
            if part and part.Parent then
                part.Transparency = 0
                part.CanCollide = true
            end
        end
        espParts = {}
    end
end

-- ==========================================
-- AUTO-GRAB: Detect and trigger ProximityPrompt or TouchTransmitter within range
-- ==========================================
local autoGrabRunning = false

local function startAutoGrabLoop()
    if autoGrabRunning then return end
    autoGrabRunning = true

    task.spawn(function()
        while _G.AutoGrab do
            local ok, err = pcall(function()
                local _, hrp = getCharacter()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if (obj:IsA("ProximityPrompt") or obj:IsA("TouchTransmitter")) and obj.Parent:IsA("BasePart") then
                        local dist = (obj.Parent.Position - hrp.Position).Magnitude
                        if dist <= Config.AutoGrabRange then
                            if obj:IsA("ProximityPrompt") then
                                obj:InputHoldBegin()
                                task.wait(0.1)
                                obj:InputHoldEnd()
                            elseif obj:IsA("TouchTransmitter") then
                                local originalPos = hrp.Position
                                hrp.CFrame = CFrame.new(obj.Parent.Position)
                                task.wait(0.05)
                                hrp.CFrame = CFrame.new(originalPos)
                            end
                        end
                    end
                end
            end)
            if not ok then warn("AutoGrab Error:", err) end
            task.wait(0.5)
        end
        autoGrabRunning = false
    end)
end

-- ==========================================
-- INFINITE KILL AURA: Damage players within range
-- ==========================================
local killAuraRunning = false
local damageRemote = ReplicatedStorage:FindFirstChild("DamageRemote") or Workspace:FindFirstChild("DamageRemote", true)

local function startKillAuraLoop()
    if killAuraRunning then return end
    killAuraRunning = true

    task.spawn(function()
        while _G.InfiniteKillAura do
            local ok, err = pcall(function()
                local _, hrp = getCharacter()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player and plr.Character then
                        local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP then
                            local dist = (targetHRP.Position - hrp.Position).Magnitude
                            if dist <= Config.KillAuraRange then
                                if damageRemote and damageRemote:IsA("RemoteEvent") then
                                    damageRemote:FireServer(plr.Character)
                                else
                                    local tool = character:FindFirstChildOfClass("Tool")
                                    if tool and tool.Name:lower():find("bat") then
                                        tool:Activate()
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not ok then warn("KillAura Error:", err) end
            task.wait(0.1)
        end
        killAuraRunning = false
    end)
end

-- ==========================================
-- BASE OPENER: Find Buttons, Levers, Keypads and trigger
-- ==========================================
local function triggerBaseOpener()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Button" or obj.Name == "Lever" or obj.Name == "Keypad") then
            local remote = obj:FindFirstChildOfClass("RemoteEvent")
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
            if remote then
                remote:FireServer()
            elseif prompt then
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end
        end
    end
end

-- ==========================================
-- FLY MODE: Using LinearVelocity
-- ==========================================
local flyAttachment, flyLinearVelocity

local function startFly()
    if not flyAttachment then
        flyAttachment = Instance.new("Attachment", humanoidRootPart)
        flyLinearVelocity = Instance.new("LinearVelocity", humanoidRootPart)
        flyLinearVelocity.Attachment0 = flyAttachment
        flyLinearVelocity.MaxForce = math.huge
        flyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end

    humanoid.PlatformStand = true

    RunService.Heartbeat:Connect(function()
        if not _G.FlyMode then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end

        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            flyLinearVelocity.VectorVelocity = moveDir.Unit * Config.FlySpeed
        else
            flyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function stopFly()
    if flyLinearVelocity then flyLinearVelocity:Destroy() flyLinearVelocity = nil end
    if flyAttachment then flyAttachment:Destroy() flyAttachment = nil end
    humanoid.PlatformStand = false
end

-- ==========================================
-- DASH: 12-stud forward push using LinearVelocity
-- ==========================================
local dashAttachment, dashLinearVelocity

local function dashForward()
    if not dashAttachment then
        dashAttachment = Instance.new("Attachment", humanoidRootPart)
        dashLinearVelocity = Instance.new("LinearVelocity", humanoidRootPart)
        dashLinearVelocity.Attachment0 = dashAttachment
        dashLinearVelocity.MaxForce = math.huge
    end

    local cam = Workspace.CurrentCamera
    if cam then
        local direction = cam.CFrame.LookVector
        dashLinearVelocity.VectorVelocity = direction * (Config.DashDistance * 10)
        task.wait(0.2)
        dashLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end
end

-- ==========================================
-- AUTO-REFRESH: Restart features on respawn
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")

    -- Restart Fly if enabled
    if _G.FlyMode then
        stopFly()
        startFly()
    end

    -- Restart Kill Aura if enabled
    if _G.InfiniteKillAura then
        killAuraRunning = false
        startKillAuraLoop()
    end

    -- Dash attachment recreation if needed
    if dashAttachment then dashAttachment:Destroy() dashAttachment = nil end
    if dashLinearVelocity then dashLinearVelocity:Destroy() dashLinearVelocity = nil end
end)

-- ==========================================
-- MODERN GUI: Draggable, Compact, Blue/Cyan Theme
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 350)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "🐬 DelfinBot v2.0"
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Center

-- Draggable functionality
local dragging = false
local dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Button container
local ButtonFrame = Instance.new("Frame", MainFrame)
ButtonFrame.Size = UDim2.new(1, -20, 1, -50)
ButtonFrame.Position = UDim2.new(0, 10, 0, 45)
ButtonFrame.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout", ButtonFrame)
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.HorizontalAlignment = Enum.FillDirection.HorizontalAlignment.Center

-- Function to create toggle buttons
local function createToggleButton(text, toggleKey, callback)
    local Button = Instance.new("TextButton", ButtonFrame)
    Button.Size = UDim2.new(0, 200, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.Text = text
    Button.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", Button)
    btnCorner.CornerRadius = UDim.new(0, 8)

    local function updateColor()
        if _G[toggleKey] then
            Button.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            Button.TextColor3 = Color3.new(0, 0, 0)
        else
            Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Button.TextColor3 = Color3.new(1, 1, 1)
        end
    end
    updateColor()

    Button.MouseButton1Click:Connect(function()
        _G[toggleKey] = not _G[toggleKey]
        updateColor()
        if callback then callback() end
    end)

    return Button
end

-- Function to create action buttons
local function createActionButton(text, callback)
    local Button = Instance.new("TextButton", ButtonFrame)
    Button.Size = UDim2.new(0, 200, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 14
    Button.Text = text
    Button.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", Button)
    btnCorner.CornerRadius = UDim.new(0, 8)

    Button.MouseButton1Click:Connect(callback)

    return Button
end

-- Create buttons
createToggleButton("Toggle Fly", "FlyMode", function()
    if _G.FlyMode then startFly() else stopFly() end
end)

createToggleButton("Toggle Auto-Grab", "AutoGrab", function()
    if _G.AutoGrab then startAutoGrabLoop() end
end)

createToggleButton("Toggle Kill Aura", "InfiniteKillAura", function()
    if _G.InfiniteKillAura then startKillAuraLoop() end
end)

createToggleButton("Toggle Base ESP", "BaseESP", updateBaseESP)

createActionButton("Open Bases", triggerBaseOpener)

createActionButton("Dash Forward", dashForward)

-- ==========================================
-- INITIAL EXECUTIONS
-- ==========================================
updateBaseESP()
if _G.AutoGrab then startAutoGrabLoop() end
if _G.InfiniteKillAura then startKillAuraLoop() end
if _G.FlyMode then startFly() end

-- Anti-AFK
player.Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)
