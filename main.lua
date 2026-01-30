-- ==========================================
-- DELFINBOT V3.5 - PROFESSIONAL WHITELIST EDITION
-- Desarrollador: [Tu Nombre]
-- Versión: 3.5 Final
-- ==========================================

--[[
    WHITELIST SYSTEM
    Para añadir más clientes, simplemente agrega sus IDs a la tabla:
    [ID_DEL_USUARIO] = true,
    
    Ejemplo:
    [123456789] = true,
    [987654321] = true,
]]

local IDs_Autorizadas = {
    [9383569669] = true,  -- Cliente principal
    -- Añade más IDs aquí:
    -- [ID_USUARIO] = true,
}

-- ==========================================
-- VERIFICACIÓN DE ACCESO
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Verificar si el usuario está autorizado
if not IDs_Autorizadas[LocalPlayer.UserId] then
    print("ID no autorizada")
    return
end

-- Si llegamos aquí, el usuario está autorizado
print("✓ DelfinBot v3.5: Usuario autorizado (ID: " .. LocalPlayer.UserId .. ")")

-- ==========================================
-- SERVICIOS Y CONFIGURACIÓN
-- ==========================================
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

-- Notificación de acceso
StarterGui:SetCore("SendNotification", {
    Title = "🐬 DelfinBot v3.5",
    Text = "Acceso Autorizado ✓",
    Duration = 5
})

-- ==========================================
-- CONFIGURACIÓN GLOBAL
-- ==========================================
local Config = {
    -- Auto Bat
    BatRange = 15,
    SwingSpeed = 0.4,
    
    -- Tornado Spin
    TornadoSpeed = 600,
    
    -- Fly Mode
    FlySpeed = 35,
    
    -- Speed Booster
    SpeedMultiplier = 1.3,
}

local Toggles = {
    AutoBat = false,
    DoubleJump = false,
    AntiRagdoll = false,
    TornadoSpin = false,
    FlyMode = false,
    SpeedBoost = false,
}

-- Tema de colores
local Theme = "Cyan"
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
    }
}
local Colors = Themes[Theme]

-- Variables de física
local flyVelocity, flyAttachment
local boostVelocity, boostAttachment
local tornadoVelocity, tornadoAttachment

-- Conexiones
local connections = {}

-- Variables de control para Double Jump
local canDoubleJump = false
local hasDoubleJumped = false
local jumpCount = 0
local lastJumpReset = tick()

-- ==========================================
-- FUNCIONES AUXILIARES
-- ==========================================
local function getCharacterComponents()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    return character, rootPart, humanoid
end

local function getBatTool()
    local character = LocalPlayer.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("bat") then
                return tool
            end
        end
    end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("bat") then
                return tool
            end
        end
    end
    return nil
end

local function notify(message, duration)
    StarterGui:SetCore("SendNotification", {
        Title = "🐬 DelfinBot v3.5",
        Text = message,
        Duration = duration or 3
    })
end

local function humanDelay(min, max)
    task.wait(math.random(min * 100, max * 100) / 100)
end

-- ==========================================
-- DOUBLE JUMP SYSTEM
-- ==========================================
local function setupDoubleJump()
    if connections.doubleJump then
        connections.doubleJump:Disconnect()
    end
    if connections.landed then
        connections.landed:Disconnect()
    end
    
    if not Toggles.DoubleJump then return end
    
    local character, rootPart, humanoid = getCharacterComponents()
    
    -- Reset del double jump al tocar el suelo
    connections.landed = humanoid.StateChanged:Connect(function(oldState, newState)
        if not Toggles.DoubleJump then return end
        
        if newState == Enum.HumanoidStateType.Landed then
            canDoubleJump = true
            hasDoubleJumped = false
        elseif newState == Enum.HumanoidStateType.Freefall or 
               newState == Enum.HumanoidStateType.Jumping then
            canDoubleJump = true
        end
    end)
    
    -- Detección del segundo salto
    connections.doubleJump = UserInputService.JumpRequest:Connect(function()
        if not Toggles.DoubleJump then return end
        
        -- Límite de spam: máximo 2 saltos cada 3 segundos
        local now = tick()
        if jumpCount >= 2 and now - lastJumpReset < 3 then
            return
        end
        
        if now - lastJumpReset >= 3 then
            jumpCount = 0
            lastJumpReset = now
        end
        
        pcall(function()
            local char, hrp, hum = getCharacterComponents()
            if not char or not hrp or not hum then return end
            
            local state = hum:GetState()
            if (state == Enum.HumanoidStateType.Freefall or 
                state == Enum.HumanoidStateType.Jumping) and 
               canDoubleJump and not hasDoubleJumped then
                
                jumpCount = jumpCount + 1
                
                -- Fuerza variable (55-65% del salto normal)
                local variation = math.random(55, 65) / 100
                local jumpPower = (hum.JumpPower or 50) * variation
                
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    jumpPower,
                    hrp.AssemblyLinearVelocity.Z
                )
                
                hasDoubleJumped = true
                canDoubleJump = false
            end
        end)
    end)
end

-- ==========================================
-- ANTI-RAGDOLL SYSTEM
-- ==========================================
local function setupAntiRagdoll()
    if connections.antiRagdoll then
        connections.antiRagdoll:Disconnect()
    end
    
    if not Toggles.AntiRagdoll then return end
    
    local character, rootPart, humanoid = getCharacterComponents()
    if not character or not humanoid then return end
    
    connections.antiRagdoll = humanoid.StateChanged:Connect(function(oldState, newState)
        if not Toggles.AntiRagdoll then return end
        
        if newState == Enum.HumanoidStateType.Ragdoll or 
           newState == Enum.HumanoidStateType.FallingDown then
            task.defer(function()
                humanDelay(0.05, 0.15)
                if humanoid and humanoid.Parent then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end)
    
    -- Mantener joints activos
    task.spawn(function()
        while Toggles.AntiRagdoll do
            pcall(function()
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("Motor6D") and not part.Enabled then
                        part.Enabled = true
                    end
                end
            end)
            humanDelay(0.2, 0.4)
        end
    end)
end

-- ==========================================
-- AUTO BAT (KILL AURA)
-- ==========================================
local autoBatRunning = false
local consecutiveSwings = 0

local function startAutoBat()
    if autoBatRunning then return end
    autoBatRunning = true
    
    task.spawn(function()
        while Toggles.AutoBat do
            pcall(function()
                local character, rootPart = getCharacterComponents()
                local bat = getBatTool()
                
                if bat then
                    if bat.Parent ~= character then
                        humanDelay(0.1, 0.3)
                        bat.Parent = character
                    end
                    
                    -- Pausa después de muchos swings
                    if consecutiveSwings > 5 then
                        humanDelay(1, 2)
                        consecutiveSwings = 0
                    end
                    
                    bat:Activate()
                    consecutiveSwings = consecutiveSwings + 1
                end
            end)
            
            humanDelay(Config.SwingSpeed * 0.8, Config.SwingSpeed * 1.2)
        end
        
        autoBatRunning = false
        consecutiveSwings = 0
    end)
end

-- ==========================================
-- TORNADO SPIN (HELICOPTER)
-- ==========================================
local tornadoRunning = false

local function startTornadoSpin()
    if tornadoRunning then return end
    tornadoRunning = true
    
    task.spawn(function()
        while Toggles.TornadoSpin do
            pcall(function()
                local character, rootPart = getCharacterComponents()
                
                if not tornadoVelocity then
                    tornadoAttachment = Instance.new("Attachment", rootPart)
                    tornadoVelocity = Instance.new("AngularVelocity", rootPart)
                    tornadoVelocity.Attachment0 = tornadoAttachment
                    tornadoVelocity.MaxTorque = math.huge
                end
                
                local speedVariation = Config.TornadoSpeed + math.random(-50, 50)
                tornadoVelocity.AngularVelocity = Vector3.new(0, math.rad(speedVariation), 0)
            end)
            task.wait()
        end
        
        if tornadoVelocity then tornadoVelocity:Destroy() tornadoVelocity = nil end
        if tornadoAttachment then tornadoAttachment:Destroy() tornadoAttachment = nil end
        tornadoRunning = false
    end)
end

-- ==========================================
-- FLY MODE
-- ==========================================
local flyRunning = false

local function startFlyMode()
    if flyRunning then return end
    flyRunning = true
    
    task.spawn(function()
        local character, rootPart, humanoid = getCharacterComponents()
        
        task.defer(function()
            humanDelay(0.1, 0.2)
            if humanoid then humanoid.PlatformStand = true end
        end)
        
        if not flyVelocity then
            flyAttachment = Instance.new("Attachment", rootPart)
            flyVelocity = Instance.new("LinearVelocity", rootPart)
            flyVelocity.Attachment0 = flyAttachment
            flyVelocity.MaxForce = math.huge
        end
        
        while Toggles.FlyMode do
            pcall(function()
                local camera = workspace.CurrentCamera
                if not camera then return end
                
                local moveDirection = Vector3.new()
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                
                local speed = Config.FlySpeed + math.random(-2, 2)
                flyVelocity.VectorVelocity = moveDirection.Magnitude > 0 and 
                                             moveDirection.Unit * speed or 
                                             Vector3.zero
            end)
            RunService.Heartbeat:Wait()
        end
        
        if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
        if flyAttachment then flyAttachment:Destroy() flyAttachment = nil end
        if humanoid then
            task.defer(function()
                humanDelay(0.1, 0.2)
                if humanoid.Parent then humanoid.PlatformStand = false end
            end)
        end
        flyRunning = false
    end)
end

-- ==========================================
-- SPEED BOOSTER
-- ==========================================
local boostRunning = false

local function startSpeedBoost()
    if boostRunning then return end
    boostRunning = true
    
    task.spawn(function()
        if not boostVelocity then
            boostAttachment = Instance.new("Attachment")
            boostVelocity = Instance.new("LinearVelocity")
            boostVelocity.MaxForce = math.huge
        end
        
        while Toggles.SpeedBoost do
            pcall(function()
                local character, rootPart, humanoid = getCharacterComponents()
                
                if boostAttachment.Parent ~= rootPart then
                    boostAttachment.Parent = rootPart
                    boostVelocity.Parent = rootPart
                    boostVelocity.Attachment0 = boostAttachment
                end
                
                local moveDirection = humanoid.MoveDirection
                if moveDirection.Magnitude > 0 then
                    local multiplier = Config.SpeedMultiplier + (math.random(-10, 10) / 100)
                    boostVelocity.VectorVelocity = moveDirection.Unit * 
                                                   humanoid.WalkSpeed * 
                                                   multiplier
                else
                    boostVelocity.VectorVelocity = Vector3.zero
                end
            end)
            RunService.Heartbeat:Wait()
        end
        
        if boostVelocity then boostVelocity:Destroy() boostVelocity = nil end
        if boostAttachment then boostAttachment:Destroy() boostAttachment = nil end
        boostRunning = false
    end)
end

-- ==========================================
-- CHARACTER RESPAWN HANDLER
-- ==========================================
connections.characterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    
    -- Reset variables de control
    canDoubleJump = false
    hasDoubleJumped = false
    jumpCount = 0
    lastJumpReset = tick()
    
    -- Reactivar funciones
    if Toggles.DoubleJump then setupDoubleJump() end
    if Toggles.AntiRagdoll then setupAntiRagdoll() end
end)

-- ==========================================
-- ANTI-AFK
-- ==========================================
LocalPlayer.Idled:Connect(function()
    task.defer(function()
        humanDelay(0.5, 1.5)
        VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
    end)
end)

-- ==========================================
-- INTERFAZ GRÁFICA (GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 380, 0, 420)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -210)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Colors.Border
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3

-- ==========================================
-- SISTEMA DE GOTAS DE AGUA (PARTÍCULAS) 💧
-- ==========================================
local WaterDropsContainer = Instance.new("Frame", MainFrame)
WaterDropsContainer.Name = "WaterDrops"
WaterDropsContainer.Size = UDim2.new(1, 0, 1, 0)
WaterDropsContainer.BackgroundTransparency = 1
WaterDropsContainer.ZIndex = 10
WaterDropsContainer.ClipsDescendants = true

local function createWaterDrop()
    local drop = Instance.new("Frame", WaterDropsContainer)
    drop.Size = UDim2.new(0, math.random(3, 8), 0, math.random(8, 16))
    drop.Position = UDim2.new(math.random(0, 100) / 100, 0, 0, -20)
    drop.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    drop.BackgroundTransparency = math.random(30, 60) / 100
    drop.BorderSizePixel = 0
    drop.ZIndex = 11
    
    local corner = Instance.new("UICorner", drop)
    corner.CornerRadius = UDim.new(1, 0)
    
    local gradient = Instance.new("UIGradient", drop)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 220, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 240))
    }
    gradient.Rotation = 90
    
    -- Animación de caída
    local fallDuration = math.random(15, 30) / 10
    local endY = 1.2
    
    local tween = TweenService:Create(drop, TweenInfo.new(
        fallDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.In
    ), {
        Position = UDim2.new(drop.Position.X.Scale, 0, endY, 0),
        BackgroundTransparency = 1
    })
    
    tween:Play()
    
    tween.Completed:Connect(function()
        drop:Destroy()
    end)
end

-- Generar gotas continuamente
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        createWaterDrop()
        task.wait(math.random(1, 4) / 10) -- Cada 0.1 a 0.4 segundos
    end
end)

-- Función para crear burbujas que suben 🫧
local function createBubble()
    local bubble = Instance.new("Frame", WaterDropsContainer)
    bubble.Size = UDim2.new(0, math.random(4, 10), 0, math.random(4, 10))
    bubble.Position = UDim2.new(math.random(10, 90) / 100, 0, 1.05, 0)
    bubble.BackgroundColor3 = Color3.fromRGB(180, 230, 255)
    bubble.BackgroundTransparency = 0.5
    bubble.BorderSizePixel = 0
    bubble.ZIndex = 11
    
    local corner = Instance.new("UICorner", bubble)
    corner.CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke", bubble)
    stroke.Color = Color3.fromRGB(200, 240, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    
    -- Animación de subida con movimiento ondulante
    local riseDuration = math.random(25, 40) / 10
    
    local tween = TweenService:Create(bubble, TweenInfo.new(
        riseDuration,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.Out
    ), {
        Position = UDim2.new(bubble.Position.X.Scale, 0, -0.1, 0),
        Size = UDim2.new(0, bubble.Size.X.Offset * 0.4, 0, bubble.Size.Y.Offset * 0.4),
        BackgroundTransparency = 1
    })
    
    tween:Play()
    
    -- Movimiento ondulante horizontal
    task.spawn(function()
        local elapsed = 0
        local startX = bubble.Position.X.Scale
        while bubble and bubble.Parent and elapsed < riseDuration do
            local offset = math.sin(elapsed * 4) * 0.03
            bubble.Position = UDim2.new(startX + offset, 0, bubble.Position.Y.Scale, 0)
            task.wait(0.03)
            elapsed = elapsed + 0.03
        end
    end)
    
    tween.Completed:Connect(function()
        bubble:Destroy()
    end)
end

-- Generar burbujas ocasionalmente
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        if math.random(1, 100) <= 30 then -- 30% de probabilidad
            createBubble()
        end
        task.wait(math.random(5, 12) / 10)
    end
end)

-- Función para crear destellos de agua ✨
local function createSparkle()
    local sparkle = Instance.new("Frame", WaterDropsContainer)
    sparkle.Size = UDim2.new(0, 3, 0, 3)
    sparkle.Position = UDim2.new(
        math.random(10, 90) / 100,
        0,
        math.random(10, 90) / 100,
        0
    )
    sparkle.BackgroundColor3 = Color3.fromRGB(220, 245, 255)
    sparkle.BackgroundTransparency = 0
    sparkle.BorderSizePixel = 0
    sparkle.ZIndex = 12
    sparkle.Rotation = math.random(0, 360)
    
    local corner = Instance.new("UICorner", sparkle)
    corner.CornerRadius = UDim.new(1, 0)
    
    -- Animación de brillo
    local sparkTween = TweenService:Create(sparkle, TweenInfo.new(
        0.8,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ), {
        Size = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Rotation = sparkle.Rotation + 180
    })
    
    sparkTween:Play()
    sparkTween.Completed:Connect(function()
        sparkle:Destroy()
    end)
end

-- Generar destellos ocasionalmente
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        if math.random(1, 100) <= 20 then -- 20% de probabilidad
            createSparkle()
        end
        task.wait(math.random(8, 15) / 10)
    end
end)

-- ==========================================
-- EFECTO DE OLAS EN EL HEADER 🌊
-- ==========================================
local HeaderFrame = Instance.new("Frame", MainFrame)
HeaderFrame.Size = UDim2.new(1, 0, 0, 55)
HeaderFrame.BackgroundColor3 = Colors.BackgroundSecondary
HeaderFrame.BorderSizePixel = 0

local HeaderCorner = Instance.new("UICorner", HeaderFrame)
HeaderCorner.CornerRadius = UDim.new(0, 12)

local HeaderGradient = Instance.new("UIGradient", HeaderFrame)
HeaderGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Colors.Accent),
    ColorSequenceKeypoint.new(1, Colors.AccentSecondary)
}
HeaderGradient.Rotation = 45
HeaderGradient.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 0.95)
}

-- Animación de olas en el gradiente del header 🌊
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        TweenService:Create(HeaderGradient, TweenInfo.new(
            4,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        ), {
            Rotation = 65,
            Offset = Vector2.new(0.1, 0)
        }):Play()
        task.wait(4)
        
        TweenService:Create(HeaderGradient, TweenInfo.new(
            4,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        ), {
            Rotation = 25,
            Offset = Vector2.new(-0.1, 0)
        }):Play()
        task.wait(4)
    end
end)

local TitleLabel = Instance.new("TextLabel", HeaderFrame)
TitleLabel.Size = UDim2.new(1, -70, 0, 55)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🐬 DELFIN BOT V3.5"
TitleLabel.TextSize = 22
TitleLabel.TextColor3 = Colors.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local SubtitleLabel = Instance.new("TextLabel", HeaderFrame)
SubtitleLabel.Size = UDim2.new(1, -70, 0, 20)
SubtitleLabel.Position = UDim2.new(0, 20, 0, 32)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.Text = "Professional Edition"
SubtitleLabel.TextSize = 11
SubtitleLabel.TextColor3 = Colors.TextDim
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinimizeButton = Instance.new("TextButton", HeaderFrame)
MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
MinimizeButton.Position = UDim2.new(1, -45, 0, 10)
MinimizeButton.BackgroundColor3 = Colors.ButtonOff
MinimizeButton.TextColor3 = Colors.Text
MinimizeButton.Text = "━"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16

local MinCorner = Instance.new("UICorner", MinimizeButton)
MinCorner.CornerRadius = UDim.new(0, 8)

local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MinimizeButton.Text = isMinimized and "+" or "━"
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Size = isMinimized and UDim2.new(0, 380, 0, 65) or UDim2.new(0, 380, 0, 420)
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
ScrollFrame.ScrollBarImageColor3 = Colors.Accent
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 420)

-- Draggable functionality
local dragging = false
local dragStart, startPosition

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPosition.X.Scale, 
            startPosition.X.Offset + delta.X, 
            startPosition.Y.Scale, 
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ==========================================
-- THEME CHANGER
-- ==========================================
local function applyTheme(themeName)
    Theme = themeName
    Colors = Themes[themeName]
    
    MainFrame.BackgroundColor3 = Colors.Background
    MainStroke.Color = Colors.Border
    HeaderFrame.BackgroundColor3 = Colors.BackgroundSecondary
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Colors.Accent),
        ColorSequenceKeypoint.new(1, Colors.AccentSecondary)
    }
    TitleLabel.TextColor3 = Colors.Text
    SubtitleLabel.TextColor3 = Colors.TextDim
    MinimizeButton.BackgroundColor3 = Colors.ButtonOff
    MinimizeButton.TextColor3 = Colors.Text
    ScrollFrame.ScrollBarImageColor3 = Colors.Accent
    
    for _, button in ipairs(ScrollFrame:GetChildren()) do
        if button:IsA("TextButton") and button:GetAttribute("ToggleKey") then
            local toggleKey = button:GetAttribute("ToggleKey")
            button.BackgroundColor3 = Toggles[toggleKey] and Colors.ButtonOn or Colors.ButtonOff
            button.TextColor3 = Colors.Text
            local stroke = button:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Colors.Border end
        end
    end
    
    notify("🎨 Tema cambiado a: " .. themeName, 2)
end

-- ==========================================
-- CREATE TOGGLE BUTTONS
-- ==========================================
local function createToggleButton(name, yPosition, toggleKey, startFunction, emoji)
    local button = Instance.new("TextButton", ScrollFrame)
    button.Name = "Toggle_" .. toggleKey
    button.Text = (emoji or "●") .. "  " .. name
    button.Size = UDim2.new(0.96, 0, 0, 45)
    button.Position = UDim2.new(0.02, 0, 0, yPosition)
    button.BackgroundColor3 = Colors.ButtonOff
    button.TextColor3 = Colors.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.TextXAlignment = Enum.TextXAlignment.Left
    button:SetAttribute("ToggleKey", toggleKey)
    
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", button)
    stroke.Color = Colors.Border
    stroke.Thickness = 1.5
    stroke.Transparency = 0.7
    
    local function updateColor()
        TweenService:Create(button, TweenInfo.new(0.3), {
            BackgroundColor3 = Toggles[toggleKey] and Colors.ButtonOn or Colors.ButtonOff
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Transparency = Toggles[toggleKey] and 0.2 or 0.7
        }):Play()
    end
    
    button.MouseButton1Click:Connect(function()
        Toggles[toggleKey] = not Toggles[toggleKey]
        updateColor()
        
        if Toggles[toggleKey] and startFunction then
            startFunction()
        end
        
        -- Funciones especiales que necesitan setup
        if toggleKey == "DoubleJump" then setupDoubleJump() end
        if toggleKey == "AntiRagdoll" then setupAntiRagdoll() end
        
        notify(name .. (Toggles[toggleKey] and " ✓" or " ✗"), 2)
    end)
    
    updateColor()
end

-- ==========================================
-- CREATE ALL BUTTONS
-- ==========================================
local yStart = 5
local yStep = 55

createToggleButton("Auto Bat (Kill Aura)", yStart + yStep * 0, "AutoBat", startAutoBat, "⚔")
createToggleButton("Double Jump", yStart + yStep * 1, "DoubleJump", nil, "🦘")
createToggleButton("Anti-Ragdoll", yStart + yStep * 2, "AntiRagdoll", nil, "🛡")
createToggleButton("Tornado Spin", yStart + yStep * 3, "TornadoSpin", startTornadoSpin, "🌪")
createToggleButton("Fly Mode", yStart + yStep * 4, "FlyMode", startFlyMode, "✈")
createToggleButton("Speed Booster", yStart + yStep * 5, "SpeedBoost", startSpeedBoost, "🏃")

-- Theme Button
local ThemeButton = Instance.new("TextButton", ScrollFrame)
ThemeButton.Text = "🎨  Cambiar Tema (Cyan/Red)"
ThemeButton.Size = UDim2.new(0.96, 0, 0, 45)
ThemeButton.Position = UDim2.new(0.02, 0, 0, yStart + yStep * 6)
ThemeButton.BackgroundColor3 = Colors.Accent
ThemeButton.TextColor3 = Colors.Text
ThemeButton.Font = Enum.Font.GothamBold
ThemeButton.TextSize = 13

local ThemeCorner = Instance.new("UICorner", ThemeButton)
ThemeCorner.CornerRadius = UDim.new(0, 10)

ThemeButton.MouseButton1Click:Connect(function()
    applyTheme(Theme == "Cyan" and "Red" or "Cyan")
end)

-- Unload Button
local UnloadButton = Instance.new("TextButton", ScrollFrame)
UnloadButton.Text = "🗑  Unload Script"
UnloadButton.Size = UDim2.new(0.96, 0, 0, 45)
UnloadButton.Position = UDim2.new(0.02, 0, 0, yStart + yStep * 7)
UnloadButton.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
UnloadButton.TextColor3 = Colors.Text
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.TextSize = 14

local UnloadCorner = Instance.new("UICorner", UnloadButton)
UnloadCorner.CornerRadius = UDim.new(0, 10)

UnloadButton.MouseButton1Click:Connect(function()
    -- Desactivar todos los toggles
    for key in pairs(Toggles) do
        Toggles[key] = false
    end
    
    -- Desconectar todas las conexiones
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Destruir objetos de física
    if flyVelocity then flyVelocity:Destroy() end
    if flyAttachment then flyAttachment:Destroy() end
    if boostVelocity then boostVelocity:Destroy() end
    if boostAttachment then boostAttachment:Destroy() end
    if tornadoVelocity then tornadoVelocity:Destroy() end
    if tornadoAttachment then tornadoAttachment:Destroy() end
    
    -- Destruir GUI
    ScreenGui:Destroy()
    
    notify("👋 DelfinBot descargado correctamente", 3)
end)

-- ==========================================
-- TOGGLE UI CON RIGHTCONTROL
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightControl then
        local isHidden = MainFrame.Position.Y.Scale > 0.9
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
            Position = isHidden and 
                      UDim2.new(0.5, -190, 0.5, -210) or 
                      UDim2.new(0.5, -190, 1.2, 0)
        }):Play()
    end
end)

-- ==========================================
-- EFECTO DE GOTAS DE AGUA (DELFIN THEME)
-- ==========================================
local WaterDropsContainer = Instance.new("Frame", MainFrame)
WaterDropsContainer.Name = "WaterDrops"
WaterDropsContainer.Size = UDim2.new(1, 0, 1, 0)
WaterDropsContainer.BackgroundTransparency = 1
WaterDropsContainer.ZIndex = 10
WaterDropsContainer.ClipsDescendants = true

local function createWaterDrop()
    local drop = Instance.new("Frame", WaterDropsContainer)
    drop.Size = UDim2.new(0, math.random(3, 8), 0, math.random(8, 15))
    drop.Position = UDim2.new(math.random(0, 100) / 100, 0, 0, -20)
    drop.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    drop.BackgroundTransparency = 0.3
    drop.BorderSizePixel = 0
    drop.ZIndex = 10
    
    local corner = Instance.new("UICorner", drop)
    corner.CornerRadius = UDim.new(1, 0)
    
    local gradient = Instance.new("UIGradient", drop)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 220, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 235))
    }
    gradient.Rotation = 90
    
    -- Animación de caída
    local fallDuration = math.random(15, 25) / 10
    local targetY = 1.2
    
    TweenService:Create(drop, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(drop.Position.X.Scale, 0, targetY, 0)
    }):Play()
    
    -- Pequeño movimiento horizontal (como si el viento las moviera)
    local sway = math.random(-20, 20)
    task.delay(0.1, function()
        TweenService:Create(drop, TweenInfo.new(fallDuration * 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.new(drop.Position.X.Scale, sway, drop.Position.Y.Scale, 0)
        }):Play()
    end)
    
    -- Efecto de brillo aleatorio
    task.spawn(function()
        while drop and drop.Parent do
            local randomTransparency = math.random(20, 40) / 100
            TweenService:Create(drop, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
                BackgroundTransparency = randomTransparency
            }):Play()
            task.wait(math.random(5, 15) / 10)
        end
    end)
    
    -- Destruir cuando salga de la pantalla
    task.delay(fallDuration + 0.5, function()
        if drop and drop.Parent then
            drop:Destroy()
        end
    end)
end

-- Crear gotas de agua constantemente
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        -- Crear entre 1 y 3 gotas
        local dropCount = math.random(1, 3)
        for i = 1, dropCount do
            createWaterDrop()
            task.wait(math.random(1, 3) / 10)
        end
        
        -- Esperar antes de crear más gotas
        task.wait(math.random(3, 8) / 10)
    end
end)

-- Efecto de burbujas ocasionales
local function createBubble()
    local bubble = Instance.new("Frame", WaterDropsContainer)
    bubble.Size = UDim2.new(0, math.random(5, 12), 0, math.random(5, 12))
    bubble.Position = UDim2.new(math.random(0, 100) / 100, 0, 1, 20)
    bubble.BackgroundColor3 = Color3.fromRGB(180, 230, 255)
    bubble.BackgroundTransparency = 0.6
    bubble.BorderSizePixel = 0
    bubble.ZIndex = 10
    
    local corner = Instance.new("UICorner", bubble)
    corner.CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke", bubble)
    stroke.Color = Color3.fromRGB(200, 240, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    
    -- Animación de subida (burbujas suben)
    local riseDuration = math.random(20, 35) / 10
    
    TweenService:Create(bubble, TweenInfo.new(riseDuration, Enum.EasingStyle.Sine), {
        Position = UDim2.new(bubble.Position.X.Scale, 0, -0.2, 0),
        Size = UDim2.new(0, bubble.Size.X.Offset * 0.5, 0, bubble.Size.Y.Offset * 0.5)
    }):Play()
    
    -- Movimiento ondulante
    task.spawn(function()
        local elapsed = 0
        while bubble and bubble.Parent and elapsed < riseDuration do
            local offset = math.sin(elapsed * 3) * 15
            bubble.Position = UDim2.new(bubble.Position.X.Scale, offset, bubble.Position.Y.Scale, 0)
            task.wait(0.05)
            elapsed = elapsed + 0.05
        end
    end)
    
    -- Pulso de transparencia
    task.spawn(function()
        while bubble and bubble.Parent do
            TweenService:Create(bubble, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                BackgroundTransparency = math.random(40, 80) / 100
            }):Play()
            task.wait(0.8)
        end
    end)
    
    task.delay(riseDuration + 0.5, function()
        if bubble and bubble.Parent then
            bubble:Destroy()
        end
    end)
end

-- Crear burbujas ocasionalmente
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(math.random(20, 40) / 10)
        if math.random(1, 3) == 1 then -- 33% de probabilidad
            createBubble()
        end
    end
end)

-- ==========================================
-- INICIALIZACIÓN COMPLETA
-- ==========================================
notify("✓ Cargado correctamente", 3)
task.wait(0.5)
notify("💡 RightControl = Ocultar/Mostrar UI", 3)

print("✓ DelfinBot v3.5: Inicializado correctamente")
print("Usuario: " .. LocalPlayer.Name .. " (ID: " .. LocalPlayer.UserId .. ")")
