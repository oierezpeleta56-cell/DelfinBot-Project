-- ==========================================
-- DELFINBOT V3.5 - ADVANCED EDITION
-- ==========================================
local IDs_Autorizadas = {
    [9383569669] = true, -- Reemplaza con tu ID
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
if not IDs_Autorizadas[player.UserId] then return end

-- ==========================================
-- CONFIGURACIÓN Y VARIABLES GLOBALES
-- ==========================================
local TARGET_NAME = "brainrots"

local Config = {
    AutoBatRange = 15,
    AutoSwingSpeed = 0.3,
    AutoGrabRange = 20,
    HelicopterSpeed = 720,
    FlySpeed = 40,
    SpeedMultiplier = 1.5,
    DashDistance = 25,
}

local Toggles = {
    AutoBat = false,
    AutoGrab = false,
    InfiniteJump = false,
    AntiRagdoll = false,
    HelicopterSpin = false,
    FlyMode = false,
    CFrameBooster = false,
    Dash = false,
}

-- Tema de colores (Cyan por defecto)
local CurrentTheme = "Cyan"
local Themes = {
    Cyan = {
        Background = Color3.fromRGB(18, 18, 24),
        BackgroundSecondary = Color3.fromRGB(25, 25, 35),
        Accent = Color3.fromRGB(138, 43, 226),
        AccentSecondary = Color3.fromRGB(0, 191, 255),
        Text = Color3.fromRGB(240, 240, 245),
        TextDim = Color3.fromRGB(160, 160, 170),
        ButtonOff = Color3.fromRGB(35, 35, 45),
        ButtonOn = Color3.fromRGB(138, 43, 226),
        Border = Color3.fromRGB(138, 43, 226),
        BorderGlow = Color3.fromRGB(0, 191, 255),
    },
    Red = {
        Background = Color3.fromRGB(18, 18, 24),
        BackgroundSecondary = Color3.fromRGB(35, 25, 25),
        Accent = Color3.fromRGB(220, 38, 38),
        AccentSecondary = Color3.fromRGB(255, 82, 82),
        Text = Color3.fromRGB(240, 240, 245),
        TextDim = Color3.fromRGB(160, 160, 170),
        ButtonOff = Color3.fromRGB(35, 35, 45),
        ButtonOn = Color3.fromRGB(220, 38, 38),
        Border = Color3.fromRGB(220, 38, 38),
        BorderGlow = Color3.fromRGB(255, 82, 82),
    }
}

local COLORS = Themes[CurrentTheme]

-- Objetos de física
local flyLinearVelocity, flyAttachment
local boostLinearVelocity, boostAttachment
local heliAngularVelocity, heliAttachment

-- Conexiones
local infiniteJumpConn
local antiRagdollConn
local dashConn
local characterAddedConn

-- ==========================================
-- SISTEMA DE NOTIFICACIONES
-- ==========================================
local NotificationFrame

local function createNotificationUI()
    if NotificationFrame then return end
    
    NotificationFrame = Instance.new("Frame")
    NotificationFrame.Name = "NotificationContainer"
    NotificationFrame.Size = UDim2.new(0, 300, 0, 0)
    NotificationFrame.Position = UDim2.new(1, -320, 0, 20)
    NotificationFrame.BackgroundTransparency = 1
    NotificationFrame.Parent = player:WaitForChild("PlayerGui"):WaitForChild("DelfinBotUI")
    
    local UIListLayout = Instance.new("UIListLayout", NotificationFrame)
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
end

local function showNotification(message, duration)
    createNotificationUI()
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.BackgroundColor3 = COLORS.BackgroundSecondary
    notif.BorderSizePixel = 0
    notif.Parent = NotificationFrame
    
    local corner = Instance.new("UICorner", notif)
    corner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", notif)
    stroke.Color = COLORS.AccentSecondary
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    
    local text = Instance.new("TextLabel", notif)
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 10, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.TextColor3 = COLORS.Text
    text.Text = message
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    
    -- Animar entrada
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(1, 0, 0, 50)
    }):Play()
    
    -- Auto destruir
    task.delay(duration or 3, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- ==========================================
-- HELPERS
-- ==========================================
local function getCharacterAndHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    return character, hrp, humanoid
end

local function getBatTool()
    local character = player.Character
    if character then
        for _, t in ipairs(character:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "bat") then
                return t
            end
        end
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "bat") then
                return t
            end
        end
    end
    return nil
end

-- ==========================================
-- INFINITE JUMP (RECONSTRUIDO - SIN RUBBERBANDING)
-- ==========================================
local function setupInfiniteJump()
    if infiniteJumpConn then
        infiniteJumpConn:Disconnect()
        infiniteJumpConn = nil
    end
    
    if not Toggles.InfiniteJump then return end
    
    -- Usar el evento JumpRequest del servidor (método orgánico)
    infiniteJumpConn = UIS.JumpRequest:Connect(function()
        if not Toggles.InfiniteJump then return end
        
        local ok = pcall(function()
            local character, hrp, humanoid = getCharacterAndHRP()
            if not character or not hrp or not humanoid then return end
            
            -- Usar ChangeState para que el servidor reconozca el salto como legal
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)
end

-- ==========================================
-- ANTI-RAGDOLL SYSTEM
-- ==========================================
local function setupAntiRagdoll()
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
    
    if not Toggles.AntiRagdoll then return end
    
    local character, hrp, humanoid = getCharacterAndHRP()
    if not character or not humanoid then return end
    
    -- Conexión para prevenir estados de ragdoll
    antiRagdollConn = humanoid.StateChanged:Connect(function(oldState, newState)
        if not Toggles.AntiRagdoll then return end
        
        -- Si intenta entrar en ragdoll o caída, forzar a estado normal
        if newState == Enum.HumanoidStateType.Ragdoll or 
           newState == Enum.HumanoidStateType.FallingDown then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    
    -- Prevenir que se desactiven los joints
    task.spawn(function()
        while Toggles.AntiRagdoll do
            pcall(function()
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("Motor6D") then
                        v.Enabled = true
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

-- ==========================================
-- AUTO BAT (KILL AURA CON AUTO-SWING)
-- ==========================================
local autoBatRunning = false
local function startAutoBat()
    if autoBatRunning then return end
    autoBatRunning = true
    
    task.spawn(function()
        while Toggles.AutoBat do
            pcall(function()
                local character, hrp, humanoid = getCharacterAndHRP()
                local bat = getBatTool()
                if not bat then return end
                
                if bat.Parent ~= character then
                    bat.Parent = character
                end
                
                -- Buscar enemigo más cercano
                local nearestEnemy, bestDist = nil, math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player then
                        local ch = plr.Character
                        if ch and ch:FindFirstChild("HumanoidRootPart") then
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                local thrp = ch.HumanoidRootPart
                                local dist = (thrp.Position - hrp.Position).Magnitude
                                if dist < Config.AutoBatRange and dist < bestDist then
                                    bestDist = dist
                                    nearestEnemy = thrp
                                end
                            end
                        end
                    end
                end
                
                -- Siempre swing el bat
                bat:Activate()
            end)
            task.wait(Config.AutoSwingSpeed)
        end
        autoBatRunning = false
    end)
end

-- ==========================================
-- AUTO-GRAB BRAINROTS (CON NOTIFICACIONES)
-- ==========================================
local autoGrabRunning = false
local lastGrabbedTime = 0

local function startAutoGrab()
    if autoGrabRunning then return end
    autoGrabRunning = true
    
    task.spawn(function()
        while Toggles.AutoGrab do
            pcall(function()
                local _, hrp = getCharacterAndHRP()
                local grabRange = Config.AutoGrabRange
                
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local parent = obj.Parent
                        local promptPart = nil
                        
                        if parent and parent:IsA("BasePart") then
                            promptPart = parent
                        elseif parent and parent:IsA("Model") then
                            promptPart = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
                        end
                        
                        if promptPart then
                            local distance = (promptPart.Position - hrp.Position).Magnitude
                            
                            if distance <= grabRange then
                                -- Verificar si es un brainrot
                                local isBrainrot = parent.Name == TARGET_NAME or 
                                                   (obj.ObjectText and obj.ObjectText:lower():find("brain")) or
                                                   (obj.ActionText and (obj.ActionText:lower():find("collect") or 
                                                                        obj.ActionText:lower():find("grab") or
                                                                        obj.ActionText:lower():find("pick")))
                                
                                if isBrainrot then
                                    fireproximityprompt(obj)
                                    
                                    -- Notificación (throttled para evitar spam)
                                    local currentTime = tick()
                                    if currentTime - lastGrabbedTime > 1 then
                                        showNotification("🧲 Brainrot recogido!", 2)
                                        lastGrabbedTime = currentTime
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.2)
        end
        autoGrabRunning = false
    end)
end

-- ==========================================
-- DASH SYSTEM (TECLA Q)
-- ==========================================
local lastDashTime = 0
local dashCooldown = 0.5

local function setupDash()
    if dashConn then
        dashConn:Disconnect()
        dashConn = nil
    end
    
    if not Toggles.Dash then return end
    
    dashConn = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Q then
            local currentTime = tick()
            if currentTime - lastDashTime < dashCooldown then return end
            lastDashTime = currentTime
            
            pcall(function()
                local character, hrp = getCharacterAndHRP()
                local cam = workspace.CurrentCamera
                if not cam then return end
                
                local direction = cam.CFrame.LookVector
                local dashVelocity = Instance.new("BodyVelocity", hrp)
                dashVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
                dashVelocity.Velocity = direction * Config.DashDistance * 10
                
                game:GetService("Debris"):AddItem(dashVelocity, 0.1)
                
                showNotification("⚡ Dash!", 1)
            end)
        end
    end)
end

-- ==========================================
-- HELICOPTER SPIN
-- ==========================================
local heliRunning = false
local function startHelicopter()
    if heliRunning then return end
    heliRunning = true
    
    task.spawn(function()
        while Toggles.HelicopterSpin do
            pcall(function()
                local _, hrp = getCharacterAndHRP()
                
                if not heliAngularVelocity then
                    heliAttachment = Instance.new("Attachment", hrp)
                    heliAngularVelocity = Instance.new("AngularVelocity", hrp)
                    heliAngularVelocity.Attachment0 = heliAttachment
                    heliAngularVelocity.MaxTorque = math.huge
                end
                
                heliAngularVelocity.AngularVelocity = Vector3.new(0, math.rad(Config.HelicopterSpeed), 0)
            end)
            task.wait()
        end
        
        if heliAngularVelocity then heliAngularVelocity:Destroy() heliAngularVelocity = nil end
        if heliAttachment then heliAttachment:Destroy() heliAttachment = nil end
        heliRunning = false
    end)
end

-- ==========================================
-- FLY MODE
-- ==========================================
local flyRunning = false
local function startFly()
    if flyRunning then return end
    flyRunning = true
    
    task.spawn(function()
        local _, hrp, humanoid = getCharacterAndHRP()
        humanoid.PlatformStand = true
        
        if not flyLinearVelocity then
            flyAttachment = Instance.new("Attachment", hrp)
            flyLinearVelocity = Instance.new("LinearVelocity", hrp)
            flyLinearVelocity.Attachment0 = flyAttachment
            flyLinearVelocity.MaxForce = math.huge
        end
        
        while Toggles.FlyMode do
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                
                local moveDir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                flyLinearVelocity.VectorVelocity = moveDir.Magnitude > 0 and moveDir.Unit * Config.FlySpeed or Vector3.zero
            end)
            RunService.Heartbeat:Wait()
        end
        
        if flyLinearVelocity then flyLinearVelocity:Destroy() flyLinearVelocity = nil end
        if flyAttachment then flyAttachment:Destroy() flyAttachment = nil end
        if humanoid then humanoid.PlatformStand = false end
        flyRunning = false
    end)
end

-- ==========================================
-- CFRAME BOOSTER
-- ==========================================
local boostRunning = false
local function startBooster()
    if boostRunning then return end
    boostRunning = true
    
    task.spawn(function()
        if not boostLinearVelocity then
            boostAttachment = Instance.new("Attachment")
            boostLinearVelocity = Instance.new("LinearVelocity")
            boostLinearVelocity.MaxForce = math.huge
        end
        
        while Toggles.CFrameBooster do
            pcall(function()
                local _, hrp, humanoid = getCharacterAndHRP()
                
                if boostAttachment.Parent ~= hrp then
                    boostAttachment.Parent = hrp
                    boostLinearVelocity.Parent = hrp
                    boostLinearVelocity.Attachment0 = boostAttachment
                end
                
                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    local mult = math.clamp(Config.SpeedMultiplier, 1, 2)
                    boostLinearVelocity.VectorVelocity = moveDir.Unit * humanoid.WalkSpeed * mult
                else
                    boostLinearVelocity.VectorVelocity = Vector3.zero
                end
            end)
            RunService.Heartbeat:Wait()
        end
        
        if boostLinearVelocity then boostLinearVelocity:Destroy() boostLinearVelocity = nil end
        if boostAttachment then boostAttachment:Destroy() boostAttachment = nil end
        boostRunning = false
    end)
end

-- ==========================================
-- CHARACTER ADDED (REACTIVAR FUNCIONES)
-- ==========================================
local function onCharacterAdded(character)
    task.wait(1)
    
    if Toggles.InfiniteJump then
        setupInfiniteJump()
    end
    
    if Toggles.AntiRagdoll then
        setupAntiRagdoll()
    end
    
    if Toggles.Dash then
        setupDash()
    end
end

characterAddedConn = player.CharacterAdded:Connect(onCharacterAdded)

-- ==========================================
-- ANTI-AFK
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
end)

-- ==========================================
-- UI CREATION
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 520)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = COLORS.Border
UIStroke.Thickness = 2
UIStroke.Transparency = 0.3

-- Header
local HeaderFrame = Instance.new("Frame", MainFrame)
HeaderFrame.Size = UDim2.new(1, 0, 0, 55)
HeaderFrame.BackgroundColor3 = COLORS.BackgroundSecondary
HeaderFrame.BorderSizePixel = 0

local HeaderCorner = Instance.new("UICorner", HeaderFrame)
HeaderCorner.CornerRadius = UDim.new(0, 12)

local HeaderGradient = Instance.new("UIGradient", HeaderFrame)
HeaderGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.Accent),
    ColorSequenceKeypoint.new(1, COLORS.AccentSecondary)
}
HeaderGradient.Rotation = 45
HeaderGradient.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 0.95)
}

local Title = Instance.new("TextLabel", HeaderFrame)
Title.Size = UDim2.new(1, -70, 0, 55)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "🐬 DELFIN BOT V3.5"
Title.TextSize = 22
Title.TextColor3 = COLORS.Text
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel", HeaderFrame)
Subtitle.Size = UDim2.new(1, -70, 0, 20)
Subtitle.Position = UDim2.new(0, 20, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "Advanced Control Panel"
Subtitle.TextSize = 11
Subtitle.TextColor3 = COLORS.TextDim
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinBtn = Instance.new("TextButton", HeaderFrame)
MinBtn.Size = UDim2.new(0, 35, 0, 35)
MinBtn.Position = UDim2.new(1, -45, 0, 10)
MinBtn.BackgroundColor3 = COLORS.ButtonOff
MinBtn.TextColor3 = COLORS.Text
MinBtn.Text = "━"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16

local MinCorner = Instance.new("UICorner", MinBtn)
MinCorner.CornerRadius = UDim.new(0, 8)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinBtn.Text = minimized and "+" or "━"
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Size = minimized and UDim2.new(0, 380, 0, 65) or UDim2.new(0, 380, 0, 520)
    }):Play()
end)

-- Buttons Container
local ButtonsFrame = Instance.new("Frame", MainFrame)
ButtonsFrame.Size = UDim2.new(1, -20, 1, -70)
ButtonsFrame.Position = UDim2.new(0, 10, 0, 60)
ButtonsFrame.BackgroundTransparency = 1

local ScrollFrame = Instance.new("ScrollingFrame", ButtonsFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = COLORS.Accent
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 520)

-- Draggable
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ==========================================
-- THEME CHANGER
-- ==========================================
local function applyTheme(themeName)
    CurrentTheme = themeName
    COLORS = Themes[themeName]
    
    -- Update UI colors
    MainFrame.BackgroundColor3 = COLORS.Background
    UIStroke.Color = COLORS.Border
    HeaderFrame.BackgroundColor3 = COLORS.BackgroundSecondary
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, COLORS.Accent),
        ColorSequenceKeypoint.new(1, COLORS.AccentSecondary)
    }
    Title.TextColor3 = COLORS.Text
    Subtitle.TextColor3 = COLORS.TextDim
    MinBtn.BackgroundColor3 = COLORS.ButtonOff
    MinBtn.TextColor3 = COLORS.Text
    ScrollFrame.ScrollBarImageColor3 = COLORS.Accent
    
    -- Update all buttons
    for _, btn in ipairs(ScrollFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            if btn.Name:find("Toggle") then
                local toggleKey = btn:GetAttribute("ToggleKey")
                if Toggles[toggleKey] then
                    btn.BackgroundColor3 = COLORS.ButtonOn
                else
                    btn.BackgroundColor3 = COLORS.ButtonOff
                end
                btn.TextColor3 = COLORS.Text
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = COLORS.Border end
            end
        end
    end
    
    showNotification("🎨 Tema cambiado a: " .. themeName, 2)
end

-- ==========================================
-- BUTTON CREATION FUNCTIONS
-- ==========================================
local function createToggle(name, yPos, toggleKey, startFunc, emoji)
    local btn = Instance.new("TextButton", ScrollFrame)
    btn.Name = "Toggle_" .. toggleKey
    btn.Text = (emoji or "●") .. "  " .. name
    btn.Size = UDim2.new(0.96, 0, 0, 45)
    btn.Position = UDim2.new(0.02, 0, 0, yPos)
    btn.BackgroundColor3 = COLORS.ButtonOff
    btn.TextColor3 = COLORS.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn:SetAttribute("ToggleKey", toggleKey)
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = COLORS.Border
    stroke.Thickness = 1.5
    stroke.Transparency = 0.7
    
    local function updateColor()
        TweenService:Create(btn, TweenInfo.new(0.3), {
            BackgroundColor3 = Toggles[toggleKey] and COLORS.ButtonOn or COLORS.ButtonOff
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Transparency = Toggles[toggleKey] and 0.2 or 0.7
        }):Play()
    end
    
    btn.MouseButton1Click:Connect(function()
        Toggles[toggleKey] = not Toggles[toggleKey]
        updateColor()
        
        if Toggles[toggleKey] and startFunc then
            startFunc()
        end
        
        -- Funciones especiales
        if toggleKey == "InfiniteJump" then
            setupInfiniteJump()
        elseif toggleKey == "AntiRagdoll" then
            setupAntiRagdoll()
        elseif toggleKey == "Dash" then
            setupDash()
        end
        
        showNotification(name .. (Toggles[toggleKey] and " activado ✓" or " desactivado ✗"), 2)
    end)
    
    updateColor()
end

-- ==========================================
-- CREATE BUTTONS
-- ==========================================
local yStart = 5
local step = 55

createToggle("Auto Bat (Kill Aura)", yStart + step * 0, "AutoBat", startAutoBat, "⚔")
createToggle("Auto-Grab Brainrots", yStart + step * 1, "AutoGrab", startAutoGrab, "🧲")
createToggle("Infinite Jump (Sin Rubberband)", yStart + step * 2, "InfiniteJump", nil, "🦘")
createToggle("Anti-Ragdoll Protection", yStart + step * 3, "AntiRagdoll", nil, "🛡")
createToggle("Dash (Tecla Q)", yStart + step * 4, "Dash", nil, "⚡")
createToggle("Helicopter Spin", yStart + step * 5, "HelicopterSpin", startHelicopter, "🚁")
createToggle("Fly Mode (WASD)", yStart + step * 6, "FlyMode", startFly, "✈")
createToggle("Speed Booster", yStart + step * 7, "CFrameBooster", startBooster, "🏃")

-- Theme Buttons
local ThemeBtn = Instance.new("TextButton", ScrollFrame)
ThemeBtn.Text = "🎨  Cambiar Tema (Cyan/Red)"
ThemeBtn.Size = UDim2.new(0.96, 0, 0, 45)
ThemeBtn.Position = UDim2.new(0.02, 0, 0, yStart + step * 8)
ThemeBtn.BackgroundColor3 = COLORS.Accent
ThemeBtn.TextColor3 = COLORS.Text
ThemeBtn.Font = Enum.Font.GothamBold
ThemeBtn.TextSize = 13

local themeCorner = Instance.new("UICorner", ThemeBtn)
themeCorner.CornerRadius = UDim.new(0, 10)

ThemeBtn.MouseButton1Click:Connect(function()
    applyTheme(CurrentTheme == "Cyan" and "Red" or "Cyan")
end)

-- Unload Button
local UnloadBtn = Instance.new("TextButton", ScrollFrame)
UnloadBtn.Text = "🗑  Unload Script"
UnloadBtn.Size = UDim2.new(0.96, 0, 0, 45)
UnloadBtn.Position = UDim2.new(0.02, 0, 0, yStart + step * 9)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
UnloadBtn.TextColor3 = COLORS.Text
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 14

local unloadCorner = Instance.new("UICorner", UnloadBtn)
unloadCorner.CornerRadius = UDim.new(0, 10)

UnloadBtn.MouseButton1Click:Connect(function()
    for k in pairs(Toggles) do Toggles[k] = false end
    
    if infiniteJumpConn then infiniteJumpConn:Disconnect() end
    if antiRagdollConn then antiRagdollConn:Disconnect() end
    if dashConn then dashConn:Disconnect() end
    if characterAddedConn then characterAddedConn:Disconnect() end
    
    if flyLinearVelocity then flyLinearVelocity:Destroy() end
    if flyAttachment then flyAttachment:Destroy() end
    if boostLinearVelocity then boostLinearVelocity:Destroy() end
    if boostAttachment then boostAttachment:Destroy() end
    if heliAngularVelocity then heliAngularVelocity:Destroy() end
    if heliAttachment then heliAttachment:Destroy() end
    
    ScreenGui:Destroy()
    showNotification("👋 DelfinBot v3.5 descargado", 3)
end)

-- ==========================================
-- INICIALIZACIÓN
-- ==========================================
showNotification("✓ DelfinBot v3.5 cargado exitosamente", 3)
task.wait(0.5)
showNotification("💡 Presiona RightControl para ocultar/mostrar UI", 3)

-- Toggle UI con RightControl
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        local hidden = MainFrame.Position.Y.Scale > 0.9
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
            Position = hidden and UDim2.new(0.5, -190, 0.5, -260) or UDim2.new(0.5, -190, 1.2, 0)
        }):Play()
    end
end)
