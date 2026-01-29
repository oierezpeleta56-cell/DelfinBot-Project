-- ==========================================
-- DELFINBOT V3.5 - VERSIÓN LIMPIA
-- ==========================================

local IDs_Autorizadas = {
    [9383569669] = true, -- Tu ID autorizada
}

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not IDs_Autorizadas[player.UserId] then return end

-- ==========================================
-- CONFIGURACIÓN
-- ==========================================
local Config = {
    InfiniteHitRange = 15,
    AutoGrabRange = 20,
    DashDistance = 15,
}

_G.InfiniteHit = _G.InfiniteHit or false
_G.AutoGrab = _G.AutoGrab or false

-- Variables de control
local infiniteHitRunning = false
local autoGrabRunning = false
local dashDebounce = false

-- ==========================================
-- FUNCIÓN: OBTENER PERSONAJE
-- ==========================================
local function getCharacter()
    return player.Character
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- INFINITE HIT (KILL AURA)
-- ==========================================
local function getEquippedTool()
    local char = getCharacter()
    if not char then return nil end
    
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end
    return nil
end

local function startInfiniteHit()
    if infiniteHitRunning then return end
    infiniteHitRunning = true

    task.spawn(function()
        while _G.InfiniteHit do
            local success, err = pcall(function()
                local hrp = getHRP()
                local tool = getEquippedTool()
                
                if not hrp or not tool then 
                    task.wait(0.1)
                    return 
                end

                -- Buscar jugador más cercano
                local nearestPlayer = nil
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
                                    nearestPlayer = otherChar
                                end
                            end
                        end
                    end
                end

                -- Activar tool si hay alguien cerca
                if nearestPlayer then
                    tool:Activate()
                end
            end)
            
            if not success then
                warn("Error en Infinite Hit:", err)
            end
            
            task.wait(0.1)
        end
        infiniteHitRunning = false
    end)
end

-- ==========================================
-- AUTO GRAB (PROXIMITY PROMPTS)
-- ==========================================
local function startAutoGrab()
    if autoGrabRunning then return end
    autoGrabRunning = true

    task.spawn(function()
        while _G.AutoGrab do
            local success, err = pcall(function()
                local hrp = getHRP()
                if not hrp then 
                    task.wait(0.1)
                    return 
                end

                -- Buscar ProximityPrompts cercanos
                for _, descendant in ipairs(workspace:GetDescendants()) do
                    if descendant:IsA("ProximityPrompt") then
                        local promptParent = descendant.Parent
                        if promptParent and promptParent:IsA("BasePart") then
                            local distance = (promptParent.Position - hrp.Position).Magnitude
                            
                            if distance <= Config.AutoGrabRange then
                                fireproximityprompt(descendant)
                            end
                        end
                    end
                end
            end)
            
            if not success then
                warn("Error en Auto Grab:", err)
            end
            
            task.wait(0.2) -- Verificar cada 0.2 segundos
        end
        autoGrabRunning = false
    end)
end

-- ==========================================
-- DASH FORWARD
-- ==========================================
local function dashForward()
    if dashDebounce then return end
    dashDebounce = true

    local success, err = pcall(function()
        local char = getCharacter()
        local hrp = getHRP()
        
        if not char or not hrp then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        -- Obtener dirección de la cámara
        local camera = workspace.CurrentCamera
        if not camera then return end

        local lookVector = camera.CFrame.LookVector
        local targetPosition = hrp.Position + (lookVector * Config.DashDistance)

        -- Crear impulso usando BodyVelocity temporal
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = lookVector * 100
        bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
        bodyVelocity.Parent = hrp

        -- Eliminar después de 0.15 segundos
        task.delay(0.15, function()
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
    end)

    if not success then
        warn("Error en Dash Forward:", err)
    end

    -- Cooldown de 0.5 segundos
    task.delay(0.5, function()
        dashDebounce = false
    end)
end

-- Activar Dash con la tecla Q
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        dashForward()
    end
end)

-- ==========================================
-- RECONEXIÓN AL RESPAWN
-- ==========================================
player.CharacterAdded:Connect(function(newCharacter)
    -- Reiniciar estados si las funciones están activas
    if _G.InfiniteHit then
        infiniteHitRunning = false
        task.wait(0.5)
        startInfiniteHit()
    end
    
    if _G.AutoGrab then
        autoGrabRunning = false
        task.wait(0.5)
        startAutoGrab()
    end
end)

-- ==========================================
-- INTERFAZ GRÁFICA (GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotV3_5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local playerGui = player:WaitForChild("PlayerGui")
ScreenGui.Parent = playerGui

-- Frame Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "DelfinBot v3.5"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 18
Title.ZIndex = 3
Title.Parent = MainFrame

-- Container de botones
local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Name = "ButtonsContainer"
ButtonsContainer.Size = UDim2.new(1, -20, 1, -60)
ButtonsContainer.Position = UDim2.new(0, 10, 0, 50)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.ZIndex = 2
ButtonsContainer.Parent = MainFrame

-- ==========================================
-- FUNCIÓN: CREAR TOGGLE
-- ==========================================
local function createToggle(name, yPosition, toggleKey, startFunction)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name .. "Toggle"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 45)
    ToggleFrame.Position = UDim2.new(0, 0, 0, yPosition)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.ZIndex = 3
    ToggleFrame.Parent = ButtonsContainer

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleFrame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Gotham
    Label.Text = name
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.ZIndex = 4
    Label.Parent = ToggleFrame

    -- Botón circular de toggle
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 35, 0, 35)
    ToggleButton.Position = UDim2.new(1, -40, 0.5, -17.5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    ToggleButton.Text = "+"
    ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 20
    ToggleButton.ZIndex = 5
    ToggleButton.Parent = ToggleFrame

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(1, 0)
    ButtonCorner.Parent = ToggleButton

    -- Actualizar estado visual
    local function updateVisual()
        if _G[toggleKey] then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            ToggleButton.Text = "X"
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            ToggleButton.Text = "+"
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
createToggle("Infinite Hit", 0, "InfiniteHit", startInfiniteHit)
createToggle("Auto Grab", 55, "AutoGrab", startAutoGrab)

-- ==========================================
-- BOTÓN DASH FORWARD
-- ==========================================
local DashButton = Instance.new("TextButton")
DashButton.Name = "DashButton"
DashButton.Size = UDim2.new(1, 0, 0, 45)
DashButton.Position = UDim2.new(0, 0, 0, 110)
DashButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
DashButton.Text = "Dash Forward (Q)"
DashButton.TextColor3 = Color3.fromRGB(0, 0, 0)
DashButton.Font = Enum.Font.GothamBold
DashButton.TextSize = 14
DashButton.ZIndex = 4
DashButton.Parent = ButtonsContainer

local DashCorner = Instance.new("UICorner")
DashCorner.CornerRadius = UDim.new(0, 8)
DashCorner.Parent = DashButton

DashButton.MouseButton1Click:Connect(function()
    dashForward()
end)

-- ==========================================
-- BOTÓN UNLOAD
-- ==========================================
local UnloadButton = Instance.new("TextButton")
UnloadButton.Name = "UnloadButton"
UnloadButton.Size = UDim2.new(1, 0, 0, 35)
UnloadButton.Position = UDim2.new(0, 0, 0, 165)
UnloadButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
UnloadButton.Text = "Unload"
UnloadButton.TextColor3 = Color3.new(1, 1, 1)
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.TextSize = 14
UnloadButton.ZIndex = 4
UnloadButton.Parent = ButtonsContainer

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 8)
UnloadCorner.Parent = UnloadButton

UnloadButton.MouseButton1Click:Connect(function()
    -- Detener todas las funciones
    _G.InfiniteHit = false
    _G.AutoGrab = false
    
    -- Destruir GUI
    ScreenGui:Destroy()
    
    print("DelfinBot v3.5 desactivado correctamente.")
end)

-- ==========================================
-- HACER GUI DRAGGABLE
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

print("DelfinBot v3.5 cargado correctamente!")
