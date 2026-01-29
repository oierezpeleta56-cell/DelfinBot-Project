-- ==========================================
-- ROBLOX LUAU SCRIPT FOR GAME CHEATS
-- Features: Base ESP, Auto-Grab, Infinite Kill Aura, Base Opener, Anti-Reset Movement
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ==========================================
-- CONFIGURATIONS
-- ==========================================
local Config = {
    AutoGrabRange = 15,
    KillAuraRange = 12,
    DashDistance = 12,
    FlySpeed = 50,  -- Speed for fly mode
}

-- Toggles
local _G = _G or {}
_G.BaseESP = _G.BaseESP or false
_G.AutoGrab = _G.AutoGrab or false
_G.InfiniteKillAura = _G.InfiniteKillAura or false
_G.BaseOpener = _G.BaseOpener or false
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
                    part.CanCollide = true  -- As per request, keeping CanCollide true
                end
            end
        end
    else
        for part in pairs(espParts) do
            if part and part.Parent then
                part.Transparency = 0  -- Reset to original (assuming 0 is default)
                part.CanCollide = true  -- Reset CanCollide
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
                                -- Simulate touch by moving to the part briefly
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
-- INFINITE KILL AURA: Damage players within range without tool
-- ==========================================
local killAuraRunning = false

-- Assuming the game has a damage remote; adjust "DamageRemote" to the actual name if known
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
                                -- Fire damage remote if available
                                if damageRemote and damageRemote:IsA("RemoteEvent") then
                                    damageRemote:FireServer(plr.Character)
                                else
                                    -- Fallback: If no remote, try to use a bat tool if equipped
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
-- ANTI-RESET MOVEMENT: Fly and Dash using LinearVelocity
-- ==========================================
local flyAttachment, flyLinearVelocity
local dashAttachment, dashLinearVelocity

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
        dashLinearVelocity.VectorVelocity = direction * (Config.DashDistance * 10)  -- Quick dash
        task.wait(0.2)
        dashLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end
end

-- Keybind for Dash (e.g., Q key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        dashForward()
    end
end)

-- ==========================================
-- TOGGLE HANDLERS
-- ==========================================
local function updateToggles()
    updateBaseESP()
    if _G.AutoGrab then startAutoGrabLoop() end
    if _G.InfiniteKillAura then startKillAuraLoop() end
    if _G.BaseOpener then triggerBaseOpener() end
    if _G.FlyMode then startFly() else stopFly() end
end

-- Initial setup
updateToggles()

-- Example: Toggle with a key (e.g., for testing, bind to keys)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F1 then _G.BaseESP = not _G.BaseESP; updateBaseESP() end
    if input.KeyCode == Enum.KeyCode.F2 then _G.AutoGrab = not _G.AutoGrab; if _G.AutoGrab then startAutoGrabLoop() end end
    if input.KeyCode == Enum.KeyCode.F3 then _G.InfiniteKillAura = not _G.InfiniteKillAura; if _G.InfiniteKillAura then startKillAuraLoop() end end
    if input.KeyCode == Enum.KeyCode.F4 then _G.BaseOpener = not _G.BaseOpener; if _G.BaseOpener then triggerBaseOpener() end end
    if input.KeyCode == Enum.KeyCode.F5 then _G.FlyMode = not _G.FlyMode; if _G.FlyMode then startFly() else stopFly() end end
end)

-- Anti-AFK
player.Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)
