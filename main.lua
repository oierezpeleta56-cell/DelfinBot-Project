-- ==========================================
-- DELFINBOT V3.5 PREMIUM EDITION
-- Sistema de Combat & Utility Optimizado
-- ==========================================

-- ==========================================
-- SISTEMA DE ACCESO (WHITELIST)
-- ==========================================
local IDs_Autorizadas = {
    [9383569669] = true, -- ID Autorizada
}

-- Servicios principales
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
if not IDs_Autorizadas[player.UserId] then 
    warn("⛔ Acceso denegado. ID no autorizada.")
    return 
end

-- ==========================================
-- CONFIGURACIÓN GLOBAL
-- ==========================================
local Config = {
    InfiniteHitRange = 15,      -- Rango de detección para Kill Aura
    AutoGrabRange = 20,         -- Rango de recogida automática
    DashDistance = 15,          -- Distancia del impulso
    DashCooldown = 0.5,         -- Tiempo entre dashes
    UpdateRate = 0.1,           -- Velocidad de actualización (optimizado para latencia)
}

-- Estados globales
_G.InfiniteHit = _G.InfiniteHit or false
_G.AutoGrab = _G.AutoGrab or false

-- Variables de control
local infiniteHitRunning = false
local autoGrabRunning = false
local dashDebounce = false
local characterLoadedOnce = false

-- ==========================================
-- UTILIDADES: OBTENER PERSONAJE Y HRP
-- ==========================================
local function getCharacterAndHRP()
    local character = player.Character
    if not character then return nil, nil end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    return character, hrp, humanoid
end

-- ==========================================
-- INFINITE HIT (KILL AURA PREMIUM)
-- ==========================================
local function getEquippedTool()
    local character, _, _ = getCharacterAndHRP()
    if not character then return nil end
    
    -- Buscar tool equipada en el personaje
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end
    
    return nil
end

local function findNearestEnemy()
    local _, hrp, _ = getCharacterAndHRP()
    if not hrp then return nil end
    
    local nearestEnemy = nil
    local shortestDistance = Config.InfiniteHitRange
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar then
                local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
                local otherHumanoid = otherChar:FindFirstChildOfClass("Humanoid")
                
                if otherHRP and otherHumanoid and otherHumanoid.Health > 0 then
                    local distance = (otherHRP.Position - hrp.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestEnemy = otherChar
                    end
                end
            end
        end
    end
    
    return nearestEnemy, shortestDistance
end

local function startInfiniteHit()
    if infiniteHitRunning then return end
    infiniteHitRunning = true
    
    task.spawn(function()
        while _G.InfiniteHit do
            local success, err = pcall(function()
                local tool = getEquippedTool()
                if not tool then 
                    task.wait(Config.UpdateRate)
                    return 
                end
                
                local nearestEnemy, distance = findNearestEnemy()
                
                if nearestEnemy and distance then
                    -- Activar herramienta
                    tool:Activate()
                end
            end)
            
            if not success then
                warn("⚠️ Error en Infinite Hit:", err)
            end
            
            task.wait(Config.UpdateRate)
        end
        
        infiniteHitRunning = false
    end)
end

-- ==========================================
-- AUTO GRAB (SISTEMA INTELIGENTE)
-- ==========================================
local processedPrompts = {}

local function startAutoGrab()
    if autoGrabRunning then return end
    autoGrabRunning = true
    
    task.spawn(function()
        while _G.AutoGrab do
            local success, err = pcall(function()
                local _, hrp, _ = getCharacterAndHRP()
                if not hrp then 
                    task.wait(Config.UpdateRate * 2)
                    return 
                end
                
                -- Limpiar caché de prompts procesados cada 30 segundos
                if tick() % 30 < 1 then
                    processedPrompts = {}
                end
                
                -- Buscar ProximityPrompts en el workspace
                for _, descendant in ipairs(workspace:GetDescendants()) do
                    if descendant:IsA("ProximityPrompt") and descendant.Enabled then
                        local promptParent = descendant.Parent
                        
                        if promptParent and promptParent:IsA("BasePart") then
                            local distance = (promptParent.Position - hrp.Position).Magnitude
                            
                            -- Si está en rango y no se ha procesado recientemente
                            if distance <= Config.AutoGrabRange then
                                local promptId = tostring(descendant:GetFullName())
                                
                                if not processedPrompts[promptId] or (tick() - processedPrompts[promptId]) > 2 then
                                    fireproximityprompt(descendant)
                                    processedPrompts[promptId] = tick()
                                end
                            end
                        end
                    end
                end
            end)
            
            if not success then
                warn("⚠️ Error en Auto Grab:", err)
            end
            
            task.wait(Config.UpdateRate * 2)
        end
        
        autoGrabRunning = false
    end)
end

-- ==========================================
-- DASH FORWARD (IMPULSO FLUIDO)
-- ==========================================
local function dashForward()
    if dashDebounce then return end
    dashDebounce = true
    
    local success, err = pcall(function()
        local character, hrp, humanoid = getCharacterAndHRP()
        if not character or not hrp or not humanoid then return end
        
        -- Obtener dirección de la cámara
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        local lookVector = camera.CFrame.LookVector
        
        -- Crear impulso usando BodyVelocity
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = lookVector * 100
        bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
        bodyVelocity.Parent = hrp
        
        -- Eliminar después de tiempo calculado
        local dashTime = Config.DashDistance / 100
        task.delay(dashTime, function()
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
    end)
    
    if not success then
        warn("⚠️ Error en Dash Forward:", err)
    end
    
    -- Cooldown
    task.delay(Config.DashCooldown, function()
        dashDebounce = false
    end)
end

-- Activar Dash con tecla Q
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        dashForward()
    end
end)

-- ==========================================
-- SISTEMA DE AUTO-RELOAD AL RESPAWN
-- ==========================================
local function onCharacterAdded(newCharacter)
    -- Esperar a que el personaje cargue completamente
    newCharacter:WaitForChild("HumanoidRootPart")
    newCharacter:WaitForChild("Humanoid")
    
    task.wait(0.5) -- Delay para estabilidad
    
    -- Reiniciar funciones activas
    if _G.InfiniteHit then
        infiniteHitRunning = false
        startInfiniteHit()
    end
    
    if _G.AutoGrab then
        autoGrabRunning = false
        startAutoGrab()
    end
    
    if characterLoadedOnce then
        print("🔄 DelfinBot reconectado al personaje")
    end
    
    characterLoadedOnce = true
end

-- Conectar al respawn
player.CharacterAdded:Connect(onCharacterAdded)

-- Si el personaje ya existe, conectar inmediatamente
if player.Character then
    onCharacterAdded(player.Character)
end

-- ==========================================
-- INTERFAZ GRÁFICA PREMIUM
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotPremium"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local playerGui = player:WaitForChild("PlayerGui")
ScreenGui.Parent = playerGui

-- Frame Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0, 340, 0, 280)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

-- Esquinas redondeadas
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Borde neón cian
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 2.5
UIStroke.Parent = MainFrame

-- Sombra suave
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.Position = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.7
Shadow.ZIndex = 1
Shadow.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -60, 0, 50)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "DelfinBot v3.5"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = MainFrame

-- Subtítulo
local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, -60, 0, 20)
Subtitle.Position = UDim2.new(0, 15, 0, 28)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "Premium Edition"
Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
Subtitle.TextSize = 12
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 3
Subtitle.Parent = MainFrame

-- Botón minimizar
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -45, 0, 10)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.ZIndex = 4
MinimizeBtn.Parent = MainFrame

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinimizeBtn

-- Container de botones
local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Name = "ButtonsContainer"
ButtonsContainer.Size = UDim2.new(1, -30, 1, -70)
ButtonsContainer.Position = UDim2.new(0, 15, 0, 60)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.ZIndex = 2
ButtonsContainer.Parent = MainFrame

-- UIListLayout para alineación perfecta
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ButtonsContainer

-- ==========================================
-- FUNCIÓN: CREAR TOGGLE PREMIUM
-- ==========================================
local function createPremiumToggle(name, layoutOrder, toggleKey, startFunction, configFields)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name .. "Toggle"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 50)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.LayoutOrder = layoutOrder
    ToggleFrame.ZIndex = 3
    ToggleFrame.Parent = ButtonsContainer
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Color3.fromRGB(40, 40, 50)
    ToggleStroke.Thickness = 1
    ToggleStroke.Parent = ToggleFrame
    
    -- Label
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = name
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 4
    Label.Parent = ToggleFrame
    
    -- Botón circular
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 38, 0, 38)
    ToggleButton.Position = UDim2.new(1, -44, 0.5, -19)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    ToggleButton.Text = "+"
    ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 22
    ToggleButton.ZIndex = 5
    ToggleButton.Parent = ToggleFrame
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(1, 0)
    ButtonCorner.Parent = ToggleButton
    
    -- Efecto hover
    ToggleButton.MouseEnter:Connect(function()
        TweenService:Create(
            ToggleButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            { Size = UDim2.new(0, 42, 0, 42) }
        ):Play()
    end)
    
    ToggleButton.MouseLeave:Connect(function()
        TweenService:Create(
            ToggleButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            { Size = UDim2.new(0, 38, 0, 38) }
        ):Play()
    end)
    
    -- Actualizar estado visual
    local function updateVisual()
        if _G[toggleKey] then
            TweenService:Create(
                ToggleButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                { 
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    TextColor3 = Color3.fromRGB(0, 0, 0)
                }
            ):Play()
            ToggleButton.Text = "✕"
            ToggleStroke.Color = Color3.fromRGB(0, 255, 255)
        else
            TweenService:Create(
                ToggleButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad),
                { 
                    BackgroundColor3 = Color3.fromRGB(0, 255, 255),
                    TextColor3 = Color3.fromRGB(0, 0, 0)
                }
            ):Play()
            ToggleButton.Text = "+"
            ToggleStroke.Color = Color3.fromRGB(40, 40, 50)
        end
    end
    
    updateVisual()
    
    ToggleButton.MouseButton1Click:Connect(function()
        _G[toggleKey] = not _G[toggleKey]
        updateVisual()
        
        if _G[toggleKey] and startFunction then
            startFunction()
        end
    end)
end

-- ==========================================
-- CREAR TOGGLES
-- ==========================================
createPremiumToggle("Infinite Hit", 1, "InfiniteHit", startInfiniteHit)
createPremiumToggle("Auto Grab", 2, "AutoGrab", startAutoGrab)

-- ==========================================
-- BOTÓN DASH FORWARD
-- ==========================================
local DashButton = Instance.new("TextButton")
DashButton.Name = "DashButton"
DashButton.Size = UDim2.new(1, 0, 0, 50)
DashButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
DashButton.Text = "⚡ Dash Forward (Q)"
DashButton.TextColor3 = Color3.fromRGB(0, 0, 0)
DashButton.Font = Enum.Font.GothamBold
DashButton.TextSize = 15
DashButton.LayoutOrder = 3
DashButton.ZIndex = 4
DashButton.Parent = ButtonsContainer

local DashCorner = Instance.new("UICorner")
DashCorner.CornerRadius = UDim.new(0, 10)
DashCorner.Parent = DashButton

local DashStroke = Instance.new("UIStroke")
DashStroke.Color = Color3.fromRGB(0, 150, 200)
DashStroke.Thickness = 1.5
DashStroke.Parent = DashButton

DashButton.MouseEnter:Connect(function()
    TweenService:Create(
        DashButton,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { BackgroundColor3 = Color3.fromRGB(0, 230, 255) }
    ):Play()
end)

DashButton.MouseLeave:Connect(function()
    TweenService:Create(
        DashButton,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { BackgroundColor3 = Color3.fromRGB(0, 200, 255) }
    ):Play()
end)

DashButton.MouseButton1Click:Connect(function()
    dashForward()
end)

-- ==========================================
-- BOTÓN UNLOAD
-- ==========================================
local UnloadButton = Instance.new("TextButton")
UnloadButton.Name = "UnloadButton"
UnloadButton.Size = UDim2.new(1, 0, 0, 40)
UnloadButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
UnloadButton.Text = "🗑️ Unload Script"
UnloadButton.TextColor3 = Color3.new(1, 1, 1)
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.TextSize = 14
UnloadButton.LayoutOrder = 4
UnloadButton.ZIndex = 4
UnloadButton.Parent = ButtonsContainer

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 10)
UnloadCorner.Parent = UnloadButton

local UnloadStroke = Instance.new("UIStroke")
UnloadStroke.Color = Color3.fromRGB(150, 20, 20)
UnloadStroke.Thickness = 1.5
UnloadStroke.Parent = UnloadButton

UnloadButton.MouseEnter:Connect(function()
    TweenService:Create(
        UnloadButton,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { BackgroundColor3 = Color3.fromRGB(220, 40, 40) }
    ):Play()
end)

UnloadButton.MouseLeave:Connect(function()
    TweenService:Create(
        UnloadButton,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { BackgroundColor3 = Color3.fromRGB(180, 30, 30) }
    ):Play()
end)

UnloadButton.MouseButton1Click:Connect(function()
    -- Detener funciones
    _G.InfiniteHit = false
    _G.AutoGrab = false
    
    -- Animación de salida
    TweenService:Create(
        MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 0, 0, 0) }
    ):Play()
    
    task.wait(0.3)
    ScreenGui:Destroy()
    
    print("✅ DelfinBot v3.5 desactivado correctamente.")
end)

-- ==========================================
-- MINIMIZAR/MAXIMIZAR
-- ==========================================
local minimized = false
local expandedSize = UDim2.new(0, 340, 0, 280)
local collapsedSize = UDim2.new(0, 340, 0, 60)

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ButtonsContainer.Visible = not minimized
    Subtitle.Visible = not minimized
    
    TweenService:Create(
        MainFrame,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = minimized and collapsedSize or expandedSize }
    ):Play()
    
    MinimizeBtn.Text = minimized and "+" or "−"
end)

-- ==========================================
-- SISTEMA DRAGGABLE (ARRASTRABLE)
-- ==========================================
local dragging = false
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
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

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

-- ==========================================
-- ANTI-AFK SYSTEM
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ==========================================
-- NOTIFICACIÓN DE CARGA
-- ==========================================
print("✅ DelfinBot v3.5 Premium Edition cargado correctamente!")
print("🎯 Funciones activas: Infinite Hit, Auto Grab, Dash Forward")
print("⌨️ Presiona Q para Dash Forward")
print("🔧 Optimizado para baja latencia")
