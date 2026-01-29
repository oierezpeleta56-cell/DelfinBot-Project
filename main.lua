-- ==========================================
-- SISTEMA DE ACCESO (WHITELIST)
-- ==========================================
local IDs_Autorizadas = {
    [9383569669] = true,
}

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VirtualUser  = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService  = game:GetService("HttpService")

local player = Players.LocalPlayer
if not IDs_Autorizadas[player.UserId] then return end

-- ==========================================
-- CONFIG Y VARIABLES GLOBALES (OPTIMIZADAS)
-- ==========================================
local TARGET_NAME = "brainrots"

local Config = {
    AutoPlaySpeed   = 30,
    HelicopterSpeed = 720,
    SpeedMultiplier = 1.5,
    AutoBatRange    = 15,
    AutoSwingSpeed  = 0.3,
    AutoGrabRange   = 20,
    FlySpeed        = 40,
    TPForwardDist   = 12,
    DashForce       = 100,      -- Nueva: Fuerza del dash
    DashDuration    = 0.15,     -- Nueva: Duración del dash
}

-- Cache de objetos para optimización
local ObjectCache = {
    Character = nil,
    HRP = nil,
    Humanoid = nil,
    Camera = workspace.CurrentCamera
}

-- Actualización del cache
local function updateCache()
    if player.Character then
        ObjectCache.Character = player.Character
        ObjectCache.HRP = player.Character:FindFirstChild("HumanoidRootPart")
        ObjectCache.Humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    end
    ObjectCache.Camera = workspace.CurrentCamera
end

-- Función optimizada para obtener character
local function getCharacterAndHRP()
    if not ObjectCache.Character or not ObjectCache.Character.Parent then
        updateCache()
    end
    return ObjectCache.Character, ObjectCache.HRP, ObjectCache.Humanoid
end

-- ==========================================
-- UI PRINCIPAL (OPTIMIZADA PARA LATENCIA)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotUI_" .. HttpService:GenerateGUID(false):sub(1, 8)
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- COLORES OPTIMIZADOS - Tema Oscuro Cian Neón
local COLORS = {
    Background = Color3.fromRGB(10, 10, 15),
    BackgroundSecondary = Color3.fromRGB(20, 20, 30),
    Accent = Color3.fromRGB(0, 255, 255),       -- Cyan neón
    AccentSecondary = Color3.fromRGB(138, 43, 226),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    ButtonOff = Color3.fromRGB(30, 30, 40),
    ButtonOn = Color3.fromRGB(0, 200, 200),     -- Cyan para activado
    ButtonHover = Color3.fromRGB(40, 40, 50),
    Border = Color3.fromRGB(0, 255, 255),       -- Borde cian neón
    BorderGlow = Color3.fromRGB(100, 255, 255),
    Success = Color3.fromRGB(0, 255, 127),
    Warning = Color3.fromRGB(255, 215, 0),
    Danger = Color3.fromRGB(255, 50, 50),
}

-- Frame principal con efectos neón
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Borde con efecto glow
local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.Border),
    ColorSequenceKeypoint.new(0.5, COLORS.BorderGlow),
    ColorSequenceKeypoint.new(1, COLORS.Border)
})
UIGradient.Rotation = 45

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = COLORS.Border
UIStroke.Thickness = 2
UIStroke.Transparency = 0.3
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Efecto de brillo interno
local InnerGlow = Instance.new("Frame", MainFrame)
InnerGlow.Size = UDim2.new(1, -4, 1, -4)
InnerGlow.Position = UDim2.new(0, 2, 0, 2)
InnerGlow.BackgroundTransparency = 1
InnerGlow.BorderSizePixel = 0

local GlowStroke = Instance.new("UIStroke", InnerGlow)
GlowStroke.Color = COLORS.BorderGlow
GlowStroke.Thickness = 1
GlowStroke.Transparency = 0.7

-- Header con gradiente cian
local HeaderFrame = Instance.new("Frame", MainFrame)
HeaderFrame.Size = UDim2.new(1, 0, 0, 60)
HeaderFrame.BackgroundColor3 = COLORS.BackgroundSecondary
HeaderFrame.BorderSizePixel = 0

local HeaderGradient = Instance.new("UIGradient", HeaderFrame)
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 100))
})

-- Título con efecto neón
local Title = Instance.new("TextLabel", HeaderFrame)
Title.Size = UDim2.new(1, -100, 0, 60)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.Text = "🐬 DELFIN HUB PRO"
Title.TextSize = 24
Title.TextColor3 = COLORS.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextStrokeTransparency = 0.5
Title.TextStrokeColor3 = COLORS.Accent

-- Subtítulo optimizado
local Subtitle = Instance.new("TextLabel", HeaderFrame)
Subtitle.Size = UDim2.new(1, -100, 0, 20)
Subtitle.Position = UDim2.new(0, 20, 0, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.Text = "Transatlantis Optimized • v2.0"
Subtitle.TextSize = 12
Subtitle.TextColor3 = COLORS.TextDim
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Botón minimizar con círculo
local MinBtn = Instance.new("TextButton", HeaderFrame)
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -50, 0, 10)
MinBtn.BackgroundColor3 = COLORS.ButtonOff
MinBtn.TextColor3 = COLORS.Text
MinBtn.Text = "━"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.ZIndex = 5

local MinCorner = Instance.new("UICorner", MinBtn)
MinCorner.CornerRadius = UDim.new(1, 0) -- Círculo perfecto

local MinStroke = Instance.new("UIStroke", MinBtn)
MinStroke.Color = COLORS.Border
MinStroke.Thickness = 2
MinStroke.Transparency = 0.3

-- Contenedor principal
local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -80)
ScrollFrame.Position = UDim2.new(0, 10, 0, 70)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = COLORS.Accent
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 450)

-- Variables para UI
local expandedSize = UDim2.new(0, 400, 0, 500)
local collapsedSize = UDim2.new(0, 400, 0, 65)
local minimized = false

-- Minimizar con animación suave
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ScrollFrame.Visible = not minimized
    MinBtn.Text = minimized and "+" or "━"
    
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(MainFrame, tweenInfo, {
        Size = minimized and collapsedSize or expandedSize
    }):Play()
end)

-- Efectos hover
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = COLORS.Accent,
        Size = UDim2.new(0, 42, 0, 42)
    }):Play()
end)

MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = COLORS.ButtonOff,
        Size = UDim2.new(0, 40, 0, 40)
    }):Play()
end)

-- ==========================================
-- INFINITE JUMP PRO (OPTIMIZADO)
-- ==========================================
local InfiniteJumpEnabled = false
local JumpRequestConnection

local function setupInfiniteJump()
    if InfiniteJumpEnabled and not JumpRequestConnection then
        -- Usar JumpRequest para evitar detección
        JumpRequestConnection = UIS.JumpRequest:Connect(function()
            local _, _, humanoid = getCharacterAndHRP()
            if humanoid and humanoid.Parent then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    elseif not InfiniteJumpEnabled and JumpRequestConnection then
        JumpRequestConnection:Disconnect()
        JumpRequestConnection = nil
    end
end

-- ==========================================
-- DASH ANTI-RUBBERBAND (LINEAR VELOCITY)
-- ==========================================
local DashEnabled = false
local DashConnection
local DashLinearVelocity
local DashAttachment

local function performDash()
    local character, hrp = getCharacterAndHRP()
    local camera = ObjectCache.Camera
    
    if not hrp or not camera then return end
    
    -- Crear objetos de física si no existen
    if not DashAttachment then
        DashAttachment = Instance.new("Attachment", hrp)
        DashLinearVelocity = Instance.new("LinearVelocity", hrp)
        DashLinearVelocity.Attachment0 = DashAttachment
        DashLinearVelocity.MaxForce = math.huge
        DashLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end
    
    -- Calcular dirección de la cámara
    local direction = camera.CFrame.LookVector
    local dashForce = Config.DashForce or 100
    
    -- Aplicar fuerza
    DashLinearVelocity.VectorVelocity = direction * dashForce
    
    -- Esperar duración configurada
    task.wait(Config.DashDuration or 0.15)
    
    -- Detener dash
    if DashLinearVelocity then
        DashLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end
end

local function setupDash()
    if DashEnabled and not DashConnection then
        DashConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.Q then
                performDash()
            end
        end)
    elseif not DashEnabled and DashConnection then
        DashConnection:Disconnect()
        DashConnection = nil
        
        -- Limpiar objetos de física
        if DashLinearVelocity then
            DashLinearVelocity:Destroy()
            DashLinearVelocity = nil
        end
        if DashAttachment then
            DashAttachment:Destroy()
            DashAttachment = nil
        end
    end
end

-- ==========================================
-- AUTO-GRAB DE PROXIMIDAD (EFICIENTE)
-- ==========================================
local AutoGrabEnabled = false
local AutoGrabConnection
local ProximityPromptCache = {}

local function updateProximityPromptCache()
    table.clear(ProximityPromptCache)
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                table.insert(ProximityPromptCache, obj)
            end
        end
    end
end

local function performAutoGrab()
    local character, hrp = getCharacterAndHRP()
    if not hrp then return end
    
    local grabRange = Config.AutoGrabRange or 20
    local rangeSquared = grabRange * grabRange
    
    -- Verificar prompts en cache
    for _, prompt in ipairs(ProximityPromptCache) do
        local parent = prompt.Parent
        if parent then
            local position
            if parent:IsA("BasePart") then
                position = parent.Position
            elseif parent:IsA("Model") then
                local primary = parent.PrimaryPart
                if primary then
                    position = primary.Position
                end
            end
            
            if position then
                local distanceSquared = (position - hrp.Position).Magnitude
                if distanceSquared <= rangeSquared then
                    -- Auto-activar prompt
                    fireproximityprompt(prompt)
                end
            end
        end
    end
end

local function setupAutoGrab()
    if AutoGrabEnabled and not AutoGrabConnection then
        -- Actualizar cache inicial
        updateProximityPromptCache()
        
        -- Monitorear cambios
        workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("ProximityPrompt") then
                table.insert(ProximityPromptCache, obj)
            end
        end)
        
        workspace.DescendantRemoving:Connect(function(obj)
            if obj:IsA("ProximityPrompt") then
                for i, prompt in ipairs(ProximityPromptCache) do
                    if prompt == obj then
                        table.remove(ProximityPromptCache, i)
                        break
                    end
                end
            end
        end)
        
        -- Loop optimizado
        AutoGrabConnection = RunService.Heartbeat:Connect(function()
            if AutoGrabEnabled then
                performAutoGrab()
            end
        end)
        
    elseif not AutoGrabEnabled and AutoGrabConnection then
        AutoGrabConnection:Disconnect()
        AutoGrabConnection = nil
        table.clear(ProximityPromptCache)
    end
end

-- ==========================================
-- SISTEMA DE TOGGLES (OPTIMIZADO)
-- ==========================================
local Toggles = {
    InfiniteJump = {enabled = false, setup = setupInfiniteJump, emoji = "🦘"},
    Dash = {enabled = false, setup = setupDash, emoji = "💨"},
    AutoGrab = {enabled = false, setup = setupAutoGrab, emoji = "🧲"},
    AutoBat = {enabled = false, emoji = "⚔"},
    FlyMode = {enabled = false, emoji = "✈"},
    Helicopter = {enabled = false, emoji = "🚁"},
    CFrameBooster = {enabled = false, emoji = "⚡"},
    ESP = {enabled = false, emoji = "👁"},
    NoClip = {enabled = false, emoji = "👻"},
}

-- ==========================================
-- CREACIÓN DE BOTONES CON CÍRCULOS
-- ==========================================
local function createToggleButton(name, toggleKey, positionY, configFields)
    local container = Instance.new("Frame", ScrollFrame)
    container.Size = UDim2.new(1, 0, 0, 50)
    container.Position = UDim2.new(0, 0, 0, positionY)
    container.BackgroundTransparency = 1
    
    -- Botón principal
    local toggleBtn = Instance.new("TextButton", container)
    toggleBtn.Size = UDim2.new(0.8, 0, 1, 0)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.BackgroundColor3 = COLORS.ButtonOff
    toggleBtn.TextColor3 = COLORS.Text
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    toggleBtn.Text = Toggles[toggleKey].emoji .. "  " .. name
    
    local btnCorner = Instance.new("UICorner", toggleBtn)
    btnCorner.CornerRadius = UDim.new(0, 10)
    
    local btnStroke = Instance.new("UIStroke", toggleBtn)
    btnStroke.Color = COLORS.Border
    btnStroke.Thickness = 1.5
    btnStroke.Transparency = 0.7
    
    -- Indicador de estado (círculo)
    local statusCircle = Instance.new("Frame", toggleBtn)
    statusCircle.Size = UDim2.new(0, 12, 0, 12)
    statusCircle.Position = UDim2.new(1, -30, 0.5, -6)
    statusCircle.BackgroundColor3 = COLORS.Danger
    statusCircle.BorderSizePixel = 0
    
    local circleCorner = Instance.new("UICorner", statusCircle)
    circleCorner.CornerRadius = UDim.new(1, 0)
    
    local circleStroke = Instance.new("UIStroke", statusCircle)
    circleStroke.Color = COLORS.Text
    circleStroke.Thickness = 1
    
    -- Botón de configuración (círculo +)
    local configBtn = Instance.new("TextButton", container)
    configBtn.Size = UDim2.new(0, 40, 0, 40)
    configBtn.Position = UDim2.new(0.82, 0, 0.1, 0)
    configBtn.BackgroundColor3 = COLORS.Accent
    configBtn.TextColor3 = COLORS.Text
    configBtn.Text = "⚙"
    configBtn.Font = Enum.Font.GothamBold
    configBtn.TextSize = 18
    configBtn.Visible = configFields and #configFields > 0
    
    local configCorner = Instance.new("UICorner", configBtn)
    configCorner.CornerRadius = UDim.new(1, 0)
    
    local configStroke = Instance.new("UIStroke", configBtn)
    configStroke.Color = COLORS.BorderGlow
    configStroke.Thickness = 2
    
    -- Función para actualizar estado
    local function updateState()
        if Toggles[toggleKey].enabled then
            toggleBtn.BackgroundColor3 = COLORS.ButtonOn
            statusCircle.BackgroundColor3 = COLORS.Success
            if Toggles[toggleKey].setup then
                Toggles[toggleKey].setup()
            end
        else
            toggleBtn.BackgroundColor3 = COLORS.ButtonOff
            statusCircle.BackgroundColor3 = COLORS.Danger
        end
    end
    
    -- Eventos del botón
    toggleBtn.MouseButton1Click:Connect(function()
        Toggles[toggleKey].enabled = not Toggles[toggleKey].enabled
        updateState()
    end)
    
    toggleBtn.MouseEnter:Connect(function()
        if not Toggles[toggleKey].enabled then
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.ButtonHover
            }):Play()
        end
    end)
    
    toggleBtn.MouseLeave:Connect(function()
        if not Toggles[toggleKey].enabled then
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.ButtonOff
            }):Play()
        end
    end)
    
    -- Efectos del botón de configuración
    configBtn.MouseEnter:Connect(function()
        TweenService:Create(configBtn, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 42, 0, 42),
            Rotation = 90
        }):Play()
    end)
    
    configBtn.MouseLeave:Connect(function()
        TweenService:Create(configBtn, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 40, 0, 40),
            Rotation = 0
        }):Play()
    end)
    
    updateState()
    
    return container
end

-- ==========================================
-- CREACIÓN DE INTERFAZ
-- ==========================================
local yPosition = 10
local yStep = 55

-- Crear todos los toggles
createToggleButton("Infinite Jump Pro", "InfiniteJump", yPosition + yStep * 0)
createToggleButton("Anti-Rubberband Dash (Q)", "Dash", yPosition + yStep * 1, {
    {label = "Fuerza", key = "DashForce"},
    {label = "Duración", key = "DashDuration"}
})
createToggleButton("Auto-Grab Proximity", "AutoGrab", yPosition + yStep * 2, {
    {label = "Rango", key = "AutoGrabRange"}
})
createToggleButton("Auto Bat", "AutoBat", yPosition + yStep * 3, {
    {label = "Rango", key = "AutoBatRange"},
    {label = "Velocidad", key = "AutoSwingSpeed"}
})
createToggleButton("Fly Mode", "FlyMode", yPosition + yStep * 4, {
    {label = "Velocidad", key = "FlySpeed"}
})
createToggleButton("Helicopter Spin", "Helicopter", yPosition + yStep * 5, {
    {label = "Velocidad", key = "HelicopterSpeed"}
})
createToggleButton("CFrame Booster", "CFrameBooster", yPosition + yStep * 6, {
    {label = "Multiplicador", key = "SpeedMultiplier"}
})
createToggleButton("ESP Visuals", "ESP", yPosition + yStep * 7)
createToggleButton("No-Clip", "NoClip", yPosition + yStep * 8)

-- Botón de unload (círculo X)
local unloadContainer = Instance.new("Frame", ScrollFrame)
unloadContainer.Size = UDim2.new(1, 0, 0, 50)
unloadContainer.Position = UDim2.new(0, 0, 0, yPosition + yStep * 9)
unloadContainer.BackgroundTransparency = 1

local unloadBtn = Instance.new("TextButton", unloadContainer)
unloadBtn.Size = UDim2.new(1, 0, 1, 0)
unloadBtn.BackgroundColor3 = COLORS.Danger
unloadBtn.TextColor3 = COLORS.Text
unloadBtn.Text = "✕  UNLOAD SCRIPT"
unloadBtn.Font = Enum.Font.GothamBlack
unloadBtn.TextSize = 16

local unloadCorner = Instance.new("UICorner", unloadBtn)
unloadCorner.CornerRadius = UDim.new(0, 10)

local unloadStroke = Instance.new("UIStroke", unloadBtn)
unloadStroke.Color = Color3.fromRGB(255, 100, 100)
unloadStroke.Thickness = 2

unloadBtn.MouseButton1Click:Connect(function()
    -- Limpieza completa
    for toggleName, toggleData in pairs(Toggles) do
        toggleData.enabled = false
        if toggleData.setup then
            toggleData.setup()
        end
    end
    
    if ScreenGui then
        ScreenGui:Destroy()
    end
end)

unloadBtn.MouseEnter:Connect(function()
    TweenService:Create(unloadBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        Size = UDim2.new(1.02, 0, 1.05, 0)
    }):Play()
end)

unloadBtn.MouseLeave:Connect(function()
    TweenService:Create(unloadBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = COLORS.Danger,
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()
end)

-- ==========================================
-- TOGGLE UI CON TECLA
-- ==========================================
local uiHidden = false
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiHidden = not uiHidden
        local targetPos = uiHidden and 
            UDim2.new(0.5, -200, 1.2, 0) or 
            UDim2.new(0.5, -200, 0.5, -250)
        
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            Position = targetPos
        }):Play()
    end
end)

-- ==========================================
-- ANTI-AFK OPTIMIZADO
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ==========================================
-- ACTUALIZACIÓN DE CACHE PERIÓDICA
-- ==========================================
RunService.Heartbeat:Connect(function()
    updateCache()
end)

-- Notificación de carga
warn("🐬 DelfinBot Pro v2.0 cargado")
warn("Optimizado para Transatlantis")
warn("Presiona RightControl para mostrar/ocultar")
