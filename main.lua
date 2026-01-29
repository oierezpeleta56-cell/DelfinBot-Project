-- ==========================================
-- SISTEMA DE ACCESO (WHITELIST)
-- ==========================================
local IDs_Autorizadas = {
    [9383569669] = true, -- Reemplaza con tu ID
}

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VirtualUser  = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not IDs_Autorizadas[player.UserId] then return end

-- ==========================================
-- CONFIG Y VARIABLES GLOBALES
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
    TPForwardDist   = 12, -- máximo 10-15 studs por vez
}

_G.AutoPlay       = _G.AutoPlay       or false
_G.AutoBat        = _G.AutoBat        or false
_G.HelicopterSpin = _G.HelicopterSpin or false
_G.FlyMode        = _G.FlyMode        or false
_G.InfiniteJump   = _G.InfiniteJump   or false
_G.CFrameBooster  = _G.CFrameBooster  or false
_G.ESPVisuals     = _G.ESPVisuals     or false
_G.Noclip         = _G.Noclip         or false
_G.AutoGrabBrainrots = _G.AutoGrabBrainrots or false
_G.AutoGrabBrainrots = _G.AutoGrabBrainrots or false

-- Objetos de física que se crean/destruyen
local flyLinearVelocity
local flyAttachment
local boostLinearVelocity
local boostAttachment
local heliAngularVelocity
local heliAttachment

local function getCharacterAndHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    return character, hrp, humanoid
end

-- ==========================================
-- UI PRINCIPAL (DRAGGABLE, MIN/MAX)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DelfinBotUI"
ScreenGui.ResetOnSpawn = false
local parentGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
ScreenGui.Parent = parentGui

-- COLORES MEJORADOS - Tema Oscuro Moderno con Acentos Cyan/Purple
local COLORS = {
    Background = Color3.fromRGB(18, 18, 24),        -- Fondo principal oscuro
    BackgroundSecondary = Color3.fromRGB(25, 25, 35), -- Fondo secundario
    Accent = Color3.fromRGB(138, 43, 226),          -- Púrpura brillante
    AccentSecondary = Color3.fromRGB(0, 191, 255),  -- Cyan brillante
    Text = Color3.fromRGB(240, 240, 245),           -- Texto blanco suave
    TextDim = Color3.fromRGB(160, 160, 170),        -- Texto atenuado
    ButtonOff = Color3.fromRGB(35, 35, 45),         -- Botón apagado
    ButtonOn = Color3.fromRGB(138, 43, 226),        -- Botón encendido (púrpura)
    ButtonHover = Color3.fromRGB(45, 45, 55),       -- Hover estado
    Border = Color3.fromRGB(138, 43, 226),          -- Borde púrpura
    BorderGlow = Color3.fromRGB(0, 191, 255),       -- Borde glow cyan
    Success = Color3.fromRGB(46, 213, 115),         -- Verde éxito
    Warning = Color3.fromRGB(255, 159, 67),         -- Naranja advertencia
    Danger = Color3.fromRGB(255, 71, 87),           -- Rojo peligro
}

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 480)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -240)
MainFrame.BackgroundColor3 = COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

-- Borde con gradiente visual
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = COLORS.Border
UIStroke.Thickness = 2
UIStroke.Transparency = 0.3

-- Sombra suave
local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.ZIndex = 0
Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.7

-- Header con gradiente
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
Title.Text = "🐬 DELFIN HUB"
Title.TextSize = 22
Title.TextColor3 = COLORS.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextStrokeTransparency = 0.8
Title.TextStrokeColor3 = COLORS.Accent

-- Subtítulo
local Subtitle = Instance.new("TextLabel", HeaderFrame)
Subtitle.Size = UDim2.new(1, -70, 0, 20)
Subtitle.Position = UDim2.new(0, 20, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "Advanced Control Panel"
Subtitle.TextSize = 11
Subtitle.TextColor3 = COLORS.TextDim
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

local ButtonsFrame = Instance.new("Frame", MainFrame)
ButtonsFrame.Size = UDim2.new(1, -20, 1, -70)
ButtonsFrame.Position = UDim2.new(0, 10, 0, 60)
ButtonsFrame.BackgroundTransparency = 1

-- ScrollingFrame para más espacio
local ScrollFrame = Instance.new("ScrollingFrame", ButtonsFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = COLORS.Accent
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 420)

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

local MinStroke = Instance.new("UIStroke", MinBtn)
MinStroke.Color = COLORS.Border
MinStroke.Thickness = 1.5
MinStroke.Transparency = 0.5

local expandedSize  = UDim2.new(0, 380, 0, 480)
local collapsedSize = UDim2.new(0, 380, 0, 65)
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ButtonsFrame.Visible = not minimized
    MinBtn.Text = minimized and "+" or "━"
    TweenService:Create(
        MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = minimized and collapsedSize or expandedSize }
    ):Play()
end)

-- Efecto hover en minimizar
MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = COLORS.ButtonHover,
        TextColor3 = COLORS.AccentSecondary
    }):Play()
end)

MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = COLORS.ButtonOff,
        TextColor3 = COLORS.Text
    }):Play()
end)

-- UI Draggable
do
    local dragging = false
    local dragStart, startPos

    local function onInputBegan(input)
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
    end

    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end

    MainFrame.InputBegan:Connect(onInputBegan)
    HeaderFrame.InputBegan:Connect(onInputBegan)
    UIS.InputChanged:Connect(onInputChanged)
end

-- ==========================================
-- POP-UP DE CONFIGURACIÓN DEL "+"
-- ==========================================
local ConfigFrame

local function crearConfigPopup(nombre, campos)
    if not ConfigFrame then
        ConfigFrame = Instance.new("Frame")
        ConfigFrame.Size = UDim2.new(0, 300, 0, 250)
        ConfigFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
        ConfigFrame.BackgroundColor3 = COLORS.Background
        ConfigFrame.BorderSizePixel = 0
        ConfigFrame.Visible = false
        ConfigFrame.ZIndex = 100
        ConfigFrame.Parent = ScreenGui

        local corner = Instance.new("UICorner", ConfigFrame)
        corner.CornerRadius = UDim.new(0, 12)

        local stroke = Instance.new("UIStroke", ConfigFrame)
        stroke.Color = COLORS.Accent
        stroke.Thickness = 2
        stroke.Transparency = 0.3

        -- Header del popup
        local popupHeader = Instance.new("Frame", ConfigFrame)
        popupHeader.Size = UDim2.new(1, 0, 0, 45)
        popupHeader.BackgroundColor3 = COLORS.BackgroundSecondary
        popupHeader.BorderSizePixel = 0

        local popupHeaderCorner = Instance.new("UICorner", popupHeader)
        popupHeaderCorner.CornerRadius = UDim.new(0, 12)

        local popupGradient = Instance.new("UIGradient", popupHeader)
        popupGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS.AccentSecondary),
            ColorSequenceKeypoint.new(1, COLORS.Accent)
        }
        popupGradient.Rotation = -45
        popupGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(1, 0.95)
        }

        local header = Instance.new("TextLabel", popupHeader)
        header.Name = "Header"
        header.Size = UDim2.new(1, -50, 0, 45)
        header.Position = UDim2.new(0, 15, 0, 0)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 16
        header.TextColor3 = COLORS.Text
        header.TextXAlignment = Enum.TextXAlignment.Left

        local closeBtn = Instance.new("TextButton", popupHeader)
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -40, 0, 7.5)
        closeBtn.BackgroundColor3 = COLORS.Danger
        closeBtn.TextColor3 = COLORS.Text
        closeBtn.Text = "✕"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 16
        local closeCorner = Instance.new("UICorner", closeBtn)
        closeCorner.CornerRadius = UDim.new(0, 8)

        local closeStroke = Instance.new("UIStroke", closeBtn)
        closeStroke.Color = COLORS.Danger
        closeStroke.Thickness = 1.5
        closeStroke.Transparency = 0.5

        closeBtn.MouseButton1Click:Connect(function()
            TweenService:Create(ConfigFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            task.wait(0.2)
            ConfigFrame.Visible = false
            ConfigFrame.Size = UDim2.new(0, 300, 0, 250)
            ConfigFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
        end)

        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(255, 100, 110)
            }):Play()
        end)

        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.Danger
            }):Play()
        end)

        local camposContainer = Instance.new("Frame", ConfigFrame)
        camposContainer.Name = "Campos"
        camposContainer.Size = UDim2.new(1, -30, 1, -60)
        camposContainer.Position = UDim2.new(0, 15, 0, 50)
        camposContainer.BackgroundTransparency = 1

        local uiList = Instance.new("UIListLayout", camposContainer)
        uiList.Padding = UDim.new(0, 10)
        uiList.FillDirection = Enum.FillDirection.Vertical
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
    end

    ConfigFrame.Campos.Parent.Header.Text = "⚙️ " .. nombre

    for _, child in ipairs(ConfigFrame.Campos:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, info in ipairs(campos or {}) do
        local row = Instance.new("Frame", ConfigFrame.Campos)
        row.Size = UDim2.new(1, 0, 0, 45)
        row.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", row)
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextColor3 = COLORS.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = info.label

        local input = Instance.new("TextBox", row)
        input.Size = UDim2.new(0.35, 0, 0.7, 0)
        input.Position = UDim2.new(0.65, 0, 0.15, 0)
        input.BackgroundColor3 = COLORS.ButtonOff
        input.TextColor3 = COLORS.Text
        input.Font = Enum.Font.GothamBold
        input.TextSize = 14
        input.ClearTextOnFocus = false
        input.Text = tostring(Config[info.key] or "")
        input.PlaceholderText = "..."
        input.PlaceholderColor3 = COLORS.TextDim

        local inputCorner = Instance.new("UICorner", input)
        inputCorner.CornerRadius = UDim.new(0, 8)

        local inputStroke = Instance.new("UIStroke", input)
        inputStroke.Color = COLORS.Border
        inputStroke.Thickness = 1.5
        inputStroke.Transparency = 0.7

        input.Focused:Connect(function()
            TweenService:Create(inputStroke, TweenInfo.new(0.2), {
                Transparency = 0.2,
                Color = COLORS.AccentSecondary
            }):Play()
        end)

        input.FocusLost:Connect(function()
            TweenService:Create(inputStroke, TweenInfo.new(0.2), {
                Transparency = 0.7,
                Color = COLORS.Border
            }):Play()
            
            local num = tonumber(input.Text)
            if num then
                Config[info.key] = num
                input.Text = tostring(num)
            else
                input.Text = tostring(Config[info.key] or "")
            end
        end)
    end

    ConfigFrame.Visible = true
    ConfigFrame.Size = UDim2.new(0, 0, 0, 0)
    ConfigFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(ConfigFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 300, 0, 250),
        Position = UDim2.new(0.5, -150, 0.5, -125)
    }):Play()
end

-- ==========================================
-- HELPERS: BRAINROTS Y BASE
-- ==========================================
local function findNearestBrainrots()
    local _, hrp = getCharacterAndHRP()
    local nearest, bestDist = nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == TARGET_NAME then
            local d = (obj.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                nearest = obj
            end
        end
    end
    return nearest
end

local function findPlayerBase()
    local userIdStr = tostring(player.UserId)
    local playerNameLower = string.lower(player.Name)

    local function getBasePartFromModel(m)
        if m.PrimaryPart then return m.PrimaryPart end
        return m:FindFirstChildWhichIsA("BasePart", true)
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if nameLower:find(playerNameLower) or nameLower:find(userIdStr) then
                local part = getBasePartFromModel(obj)
                if part then return part end
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("OwnerID")
            if ownerVal then
                local mine = false
                if ownerVal:IsA("IntValue") then
                    mine = (ownerVal.Value == player.UserId)
                elseif ownerVal:IsA("StringValue") then
                    local valLower = string.lower(ownerVal.Value)
                    if valLower == playerNameLower or ownerVal.Value == userIdStr then
                        mine = true
                    end
                end
                if mine then
                    local part = getBasePartFromModel(obj)
                    if part then return part end
                end
            end
        end
    end

    return nil
end

-- ==========================================
-- INSTANT STEAL (BUSCAR REMOTEEVENTS)
-- ==========================================
local function findStealRemote()
    local possibleNames = {
        "CollectItem", "PickupItem", "GrabItem", "TakeItem",
        "CollectBrainrots", "PickupBrainrots", "StealItem",
        "RemoteEvent", "Collect", "Pickup"
    }

    for _, name in ipairs(possibleNames) do
        local remote = ReplicatedStorage:FindFirstChild(name)
        if remote and remote:IsA("RemoteEvent") then
            return remote
        end
    end

    for _, name in ipairs(possibleNames) do
        local remote = workspace:FindFirstChild(name, true)
        if remote and remote:IsA("RemoteEvent") then
            return remote
        end
    end

    return nil
end

local function instantSteal(part)
    if not part then return end
    local remote = findStealRemote()
    if remote then
        pcall(function()
            remote:FireServer(part)
        end)
    end
end

-- ==========================================
-- TP FORWARD SEGURO (LINEARVELOCITY)
-- ==========================================
local function tpForwardSafe(distance)
    distance = math.clamp(distance, 0, Config.TPForwardDist)
    local _, hrp = getCharacterAndHRP()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local direction = cam.CFrame.LookVector
    local targetPos = hrp.Position + direction * distance

    if not flyLinearVelocity then
        flyAttachment = Instance.new("Attachment", hrp)
        flyLinearVelocity = Instance.new("LinearVelocity", hrp)
        flyLinearVelocity.Attachment0 = flyAttachment
        flyLinearVelocity.MaxForce = math.huge
        flyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end

    local vel = (targetPos - hrp.Position).Unit * (distance * 10)
    flyLinearVelocity.VectorVelocity = vel

    task.wait(0.1)
    if flyLinearVelocity then
        flyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    end
end

-- ==========================================
-- AUTOPLAY BRAINROTS (CON INSTANT STEAL Y TP SEGURO)
-- ==========================================
local autoPlayRunning = false
local function startAutoPlayLoop()
    if autoPlayRunning then return end
    autoPlayRunning = true

    task.spawn(function()
        while _G.AutoPlay do
            local ok, err = pcall(function()
                local _, hrp = getCharacterAndHRP()
                local brain = findNearestBrainrots()
                local basePart = findPlayerBase()

                if not brain then
                    warn("No se encontró '" .. TARGET_NAME .. "'.")
                    task.wait(1)
                    return
                end
                if not basePart then
                    warn("No se encontró base del jugador.")
                    task.wait(1)
                    return
                end

                local brainPos = brain.Position + Vector3.new(0, 3, 0)
                local distToBrain = (brainPos - hrp.Position).Magnitude

                while distToBrain > Config.TPForwardDist and _G.AutoPlay do
                    tpForwardSafe(Config.TPForwardDist)
                    distToBrain = (brainPos - hrp.Position).Magnitude
                    task.wait(0.05)
                end

                if distToBrain <= 5 then
                    instantSteal(brain)
                end

                if not _G.AutoPlay then return end

                local basePos = basePart.Position + Vector3.new(0, 3, 0)
                local distToBase = (basePos - hrp.Position).Magnitude

                while distToBase > Config.TPForwardDist and _G.AutoPlay do
                    tpForwardSafe(Config.TPForwardDist)
                    distToBase = (basePos - hrp.Position).Magnitude
                    task.wait(0.05)
                end
            end)
            if not ok then
                warn("Error en Autoplay:", err)
            end
            task.wait(0.1)
        end
        autoPlayRunning = false
    end)
end

-- ==========================================
-- AUTO BAT (KILL AURA INTELIGENTE)
-- ==========================================
local autoBatRunning = false

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

local function startAutoBatLoop()
    if autoBatRunning then return end
    autoBatRunning = true

    task.spawn(function()
        while _G.AutoBat do
            local ok, err = pcall(function()
                local character, hrp, humanoid = getCharacterAndHRP()
                local bat = getBatTool()
                if not bat then return end

                if bat.Parent ~= character then
                    bat.Parent = character
                end

                local nearestEnemy
                local bestDist = math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player then
                        local ch = plr.Character
                        if ch and ch:FindFirstChild("HumanoidRootPart") then
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                local thrp = ch.HumanoidRootPart
                                local dist = (thrp.Position - hrp.Position).Magnitude
                                if dist < (Config.AutoBatRange or 15) and dist < bestDist then
                                    bestDist = dist
                                    nearestEnemy = ch
                                end
                            end
                        end
                    end
                end

                if nearestEnemy then
                    local thrp = nearestEnemy.HumanoidRootPart
                    local direction = (thrp.Position - hrp.Position).Unit
                    local safeDist = math.min((thrp.Position - hrp.Position).Magnitude, Config.TPForwardDist)
                    tpForwardSafe(safeDist)
                end
                
                -- Auto swing: siempre activar el bat independientemente de si hay enemigos
                bat:Activate()
            end)
            if not ok then
                warn("Error en AutoBat:", err)
            end
            task.wait(Config.AutoSwingSpeed or 0.3)
        end
        autoBatRunning = false
    end)
end

-- ==========================================
-- AUTO-GRAB BRAINROTS (PROXIMITY PROMPT)
-- ==========================================
local autoGrabRunning = false

local function startAutoGrabLoop()
    if autoGrabRunning then return end
    autoGrabRunning = true

    task.spawn(function()
        while _G.AutoGrabBrainrots do
            local ok, err = pcall(function()
                local _, hrp = getCharacterAndHRP()
                local grabRange = Config.AutoGrabRange or 20

                -- Buscar todos los ProximityPrompts en workspace
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        -- Verificar si el ProximityPrompt está en un objeto brainrots o cerca de uno
                        local parent = obj.Parent
                        if parent and parent:IsA("BasePart") then
                            local distance = (parent.Position - hrp.Position).Magnitude
                            
                            -- Si está dentro del rango, activar el prompt automáticamente
                            if distance <= grabRange then
                                -- Verificar si es un brainrots (opcional, puedes quitar esta línea si quieres agarrar todo)
                                if parent.Name == TARGET_NAME or obj.ObjectText:lower():find("brain") or obj.ActionText:lower():find("collect") or obj.ActionText:lower():find("grab") or obj.ActionText:lower():find("pick") then
                                    fireproximityprompt(obj)
                                end
                            end
                        elseif parent and parent:IsA("Model") then
                            -- Si el ProximityPrompt está en un Model, buscar su parte principal
                            local mainPart = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
                            if mainPart then
                                local distance = (mainPart.Position - hrp.Position).Magnitude
                                
                                if distance <= grabRange then
                                    -- Verificar si es relevante
                                    if parent.Name == TARGET_NAME or obj.ObjectText:lower():find("brain") or obj.ActionText:lower():find("collect") or obj.ActionText:lower():find("grab") or obj.ActionText:lower():find("pick") then
                                        fireproximityprompt(obj)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not ok then
                warn("Error en AutoGrab:", err)
            end
            task.wait(0.2) -- Chequear cada 0.2 segundos
        end
        autoGrabRunning = false
    end)
end

-- ==========================================
-- HELICOPTER SPIN (ANGULARVELOCITY)
-- ==========================================
local heliRunning = false
local function startHeliLoop()
    if heliRunning then return end
    heliRunning = true

    task.spawn(function()
        while _G.HelicopterSpin do
            local ok, err = pcall(function()
                local _, hrp = getCharacterAndHRP()

                if not heliAngularVelocity then
                    heliAttachment = Instance.new("Attachment", hrp)
                    heliAngularVelocity = Instance.new("AngularVelocity", hrp)
                    heliAngularVelocity.Attachment0 = heliAttachment
                    heliAngularVelocity.MaxTorque = math.huge
                    heliAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
                end

                local speedRad = math.rad(Config.HelicopterSpeed or 720)
                heliAngularVelocity.AngularVelocity = Vector3.new(0, speedRad, 0)
            end)
            if not ok then
                warn("Error Helicopter:", err)
            end
            task.wait()
        end

        if heliAngularVelocity then
            heliAngularVelocity:Destroy()
            heliAngularVelocity = nil
        end
        if heliAttachment then
            heliAttachment:Destroy()
            heliAttachment = nil
        end
        heliRunning = false
    end)
end

-- ==========================================
-- FLY MODE (LINEARVELOCITY)
-- ==========================================
local flyRunning = false
local lastFlyHumanoid

local function startFlyLoop()
    if flyRunning then return end
    flyRunning = true

    task.spawn(function()
        local _, hrp, humanoid = getCharacterAndHRP()
        lastFlyHumanoid = humanoid
        humanoid.PlatformStand = true

        if not flyLinearVelocity then
            flyAttachment = Instance.new("Attachment", hrp)
            flyLinearVelocity = Instance.new("LinearVelocity", hrp)
            flyLinearVelocity.Attachment0 = flyAttachment
            flyLinearVelocity.MaxForce = math.huge
            flyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
        end

        while _G.FlyMode do
            local dt = RunService.Heartbeat:Wait()
            local ok, err = pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end

                local moveDir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    local speed = Config.FlySpeed or 40
                    flyLinearVelocity.VectorVelocity = moveDir * speed
                else
                    flyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
                end
            end)
            if not ok then
                warn("Error Fly:", err)
            end
        end

        if flyLinearVelocity then
            flyLinearVelocity:Destroy()
            flyLinearVelocity = nil
        end
        if flyAttachment then
            flyAttachment:Destroy()
            flyAttachment = nil
        end
        if lastFlyHumanoid and lastFlyHumanoid.Parent then
            lastFlyHumanoid.PlatformStand = false
        end
        flyRunning = false
    end)
end

-- ==========================================
-- INFINITE JUMP
-- ==========================================
local infiniteJumpConn

local function updateInfiniteJump()
    if _G.InfiniteJump then
        if not infiniteJumpConn then
            infiniteJumpConn = UIS.JumpRequest:Connect(function()
                if _G.InfiniteJump then
                    local _, _, humanoid = getCharacterAndHRP()
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    else
        if infiniteJumpConn then
            infiniteJumpConn:Disconnect()
            infiniteJumpConn = nil
        end
    end
end

-- ==========================================
-- CFRAME BOOSTER (LINEARVELOCITY)
-- ==========================================
local boostRunning = false
local function startBoostLoop()
    if boostRunning then return end
    boostRunning = true

    task.spawn(function()
        if not boostLinearVelocity then
            boostAttachment = Instance.new("Attachment")
            boostLinearVelocity = Instance.new("LinearVelocity")
            boostLinearVelocity.MaxForce = math.huge
            boostLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
        end

        while _G.CFrameBooster do
            local dt = RunService.Heartbeat:Wait()
            local ok, err = pcall(function()
                local _, hrp, humanoid = getCharacterAndHRP()

                if boostAttachment.Parent ~= hrp then
                    boostAttachment.Parent = hrp
                    boostLinearVelocity.Parent = hrp
                    boostLinearVelocity.Attachment0 = boostAttachment
                end

                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    local mult = Config.SpeedMultiplier or 1.5
                    mult = math.clamp(mult, 1, 2)
                    local baseSpeed = humanoid.WalkSpeed
                    local boostVel = moveDir.Unit * baseSpeed * mult
                    boostLinearVelocity.VectorVelocity = boostVel
                else
                    boostLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
                end
            end)
            if not ok then
                warn("Error Booster:", err)
            end
        end

        if boostLinearVelocity then
            boostLinearVelocity:Destroy()
            boostLinearVelocity = nil
        end
        if boostAttachment then
            boostAttachment:Destroy()
            boostAttachment = nil
        end
        boostRunning = false
    end)
end

-- ==========================================
-- NOCLIP ULTRA AGRESIVO (ANTI-RUBBERBAND RADICAL)
-- ==========================================
local noclipRunning = false
local noclipSteppedConn
local noclipHeartbeatConn
local noclipRenderConn
local noclipLastPosition = nil
local noclipCollisionGroup = "NoclipGroup"
local noclipOriginalGroups = {}

local function setupCollisionGroups()
    local physicsService = game:GetService("PhysicsService")
    
    local success, err = pcall(function()
        physicsService:RegisterCollisionGroup(noclipCollisionGroup)
    end)
    
    for _, groupName in ipairs(physicsService:GetRegisteredCollisionGroups()) do
        if groupName.Name ~= noclipCollisionGroup then
            pcall(function()
                physicsService:SetPartCollisionGroup(workspace, groupName.Name, noclipCollisionGroup, false)
            end)
        end
    end
end

setupCollisionGroups()

local function startNoclip()
    if noclipRunning then return end
    noclipRunning = true

    local ok, err = pcall(function()
        local character = player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    noclipOriginalGroups[part] = part.CollisionGroupId
                end
            end
        end
    end)

    noclipSteppedConn = RunService.Stepped:Connect(function()
        if not _G.Noclip then return end

        local ok, err = pcall(function()
            local character = player.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local cam = workspace.CurrentCamera

            if not hrp or not humanoid then return end

            local physicsService = game:GetService("PhysicsService")
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        physicsService:SetPartCollisionGroup(part, noclipCollisionGroup)
                    end)
                end
            end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    if part:IsA("BasePart") then
                        part.Velocity = Vector3.new(0, 0, 0)
                        part.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end

            humanoid:ChangeState(Enum.HumanoidStateType.PhysicsDisabled)

            if noclipLastPosition then
                local currentPos = hrp.Position
                local distance = (currentPos - noclipLastPosition).Magnitude
                
                if distance > 1.5 then
                    local direction = (currentPos - noclipLastPosition)
                    if cam then
                        local forwardDir = cam.CFrame.LookVector
                        local dot = direction.Unit:Dot(forwardDir)
                        if dot < -0.3 then
                            hrp.CFrame = hrp.CFrame * CFrame.new(forwardDir * 0.15)
                        end
                    end
                end
            end
            noclipLastPosition = hrp.Position
        end)
        if not ok then
            warn("Error Noclip Stepped:", err)
        end
    end)

    noclipHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not _G.Noclip then return end

        local ok, err = pcall(function()
            local character = player.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if not hrp or not humanoid then return end

            local physicsService = game:GetService("PhysicsService")
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        physicsService:SetPartCollisionGroup(part, noclipCollisionGroup)
                    end)
                end
            end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    if part:IsA("BasePart") then
                        part.Velocity = Vector3.new(0, 0, 0)
                        part.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end

            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
        if not ok then
            warn("Error Noclip Heartbeat:", err)
        end
    end)

    noclipRenderConn = RunService.RenderStepped:Connect(function()
        if not _G.Noclip then return end

        local ok, err = pcall(function()
            local character = player.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
        if not ok then
            warn("Error Noclip RenderStepped:", err)
        end
    end)
end

local function stopNoclip()
    if noclipSteppedConn then
        noclipSteppedConn:Disconnect()
        noclipSteppedConn = nil
    end
    if noclipHeartbeatConn then
        noclipHeartbeatConn:Disconnect()
        noclipHeartbeatConn = nil
    end
    if noclipRenderConn then
        noclipRenderConn:Disconnect()
        noclipRenderConn = nil
    end

    local ok, err = pcall(function()
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local physicsService = game:GetService("PhysicsService")

            for part, originalGroupId in pairs(noclipOriginalGroups) do
                if part and part.Parent then
                    pcall(function()
                        physicsService:SetPartCollisionGroup(part, "Default")
                    end)
                end
            end
            noclipOriginalGroups = {}

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end

            if hrp then
                hrp.Anchored = false
            end
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end
        end
    end)

    noclipRunning = false
    noclipLastPosition = nil
end

-- ==========================================
-- ESP VISUALS (DRAWING)
-- ==========================================
local espObjects = {}
local espRenderConn
local espDescendantConn

local function clearESP()
    for part, draw in pairs(espObjects) do
        if draw then pcall(function() draw:Remove() end) end
        espObjects[part] = nil
    end
    if espRenderConn then espRenderConn:Disconnect() espRenderConn = nil end
    if espDescendantConn then espDescendantConn:Disconnect() espDescendantConn = nil end
end

local function addESPForPart(part)
    if espObjects[part] then return end
    local text = Drawing.new("Text")
    text.Center = true
    text.Outline = true
    text.Size = 14
    text.Color = Color3.fromRGB(138, 43, 226)
    text.Text = TARGET_NAME
    text.Visible = false
    espObjects[part] = text
end

local function updateESPState()
    if not _G.ESPVisuals then
        clearESP()
        return
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == TARGET_NAME then
            addESPForPart(obj)
        end
    end

    if not espRenderConn then
        espRenderConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            for part, draw in pairs(espObjects) do
                if part and part.Parent and draw then
                    local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        draw.Visible = true
                        draw.Position = Vector2.new(pos.X, pos.Y)
                    else
                        draw.Visible = false
                    end
                else
                    if draw then draw.Visible = false end
                end
            end
        end)
    end

    if not espDescendantConn then
        espDescendantConn = workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") and obj.Name == TARGET_NAME then
                addESPForPart(obj)
            end
        end)
    end
end

-- ==========================================
-- ANTI-AFK
-- ==========================================
local antiAfkConn = player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
end)

-- ==========================================
-- TOGGLE UI (RightControl)
-- ==========================================
local uiHidden = false
local uiToggleConn

uiToggleConn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiHidden = not uiHidden
        local targetPos = uiHidden
            and UDim2.new(0.5, -190, 1.2, 0)
            or  UDim2.new(0.5, -190, 0.5, -240)

        TweenService:Create(
            MainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Position = targetPos }
        ):Play()
    end
end)

-- ==========================================
-- CLEAN UNLOAD (DESTRUIR TODOS LOS OBJETOS)
-- ==========================================
local function CleanUnload()
    _G.AutoPlay       = false
    _G.AutoBat        = false
    _G.HelicopterSpin = false
    _G.FlyMode        = false
    _G.InfiniteJump   = false
    _G.CFrameBooster  = false
    _G.ESPVisuals     = false
    _G.Noclip         = false
    _G.AutoGrabBrainrots = false

    if flyLinearVelocity then flyLinearVelocity:Destroy() flyLinearVelocity = nil end
    if flyAttachment then flyAttachment:Destroy() flyAttachment = nil end
    if boostLinearVelocity then boostLinearVelocity:Destroy() boostLinearVelocity = nil end
    if boostAttachment then boostAttachment:Destroy() boostAttachment = nil end
    if heliAngularVelocity then heliAngularVelocity:Destroy() heliAngularVelocity = nil end
    if heliAttachment then heliAttachment:Destroy() heliAttachment = nil end

    updateInfiniteJump()
    clearESP()
    stopNoclip()

    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if uiToggleConn then uiToggleConn:Disconnect() uiToggleConn = nil end

    if ScreenGui then ScreenGui:Destroy() end
end

-- ==========================================
-- CREACIÓN DE BOTONES (TOGGLES REALES)
-- ==========================================
local function crearToggle(nombre, posicionY, toggleKey, loopStarter, camposConfig, emoji)
    local Btn = Instance.new("TextButton", ScrollFrame)
    Btn.Text = (emoji or "●") .. "  " .. nombre
    Btn.Size = UDim2.new(0.68, 0, 0, 45)
    Btn.Position = UDim2.new(0.02, 0, 0, posicionY)
    Btn.BackgroundColor3 = COLORS.ButtonOff
    Btn.TextColor3 = COLORS.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.TextTruncate = Enum.TextTruncate.AtEnd

    local btnCorner = Instance.new("UICorner", Btn)
    btnCorner.CornerRadius = UDim.new(0, 10)

    local btnStroke = Instance.new("UIStroke", Btn)
    btnStroke.Color = COLORS.Border
    btnStroke.Thickness = 1.5
    btnStroke.Transparency = 0.7

    local btnGradient = Instance.new("UIGradient", Btn)
    btnGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
    }
    btnGradient.Rotation = 90

    local function actualizarColor()
        if _G[toggleKey] then
            TweenService:Create(Btn, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.ButtonOn
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {
                Transparency = 0.2,
                Color = COLORS.AccentSecondary
            }):Play()
            Btn.TextColor3 = COLORS.Text
            btnGradient.Enabled = false
        else
            TweenService:Create(Btn, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.ButtonOff
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.3), {
                Transparency = 0.7,
                Color = COLORS.Border
            }):Play()
            Btn.TextColor3 = COLORS.Text
            btnGradient.Enabled = true
        end
    end
    actualizarColor()

    Btn.MouseButton1Click:Connect(function()
        _G[toggleKey] = not _G[toggleKey]
        actualizarColor()
        if _G[toggleKey] and loopStarter then
            loopStarter()
        end
        if toggleKey == "InfiniteJump" then
            updateInfiniteJump()
        elseif toggleKey == "ESPVisuals" then
            updateESPState()
        elseif toggleKey == "Noclip" then
            if _G.Noclip then
                startNoclip()
            else
                stopNoclip()
            end
        end
    end)

    Btn.MouseEnter:Connect(function()
        if not _G[toggleKey] then
            TweenService:Create(Btn, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.ButtonHover
            }):Play()
        end
    end)

    Btn.MouseLeave:Connect(function()
        if not _G[toggleKey] then
            TweenService:Create(Btn, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.ButtonOff
            }):Play()
        end
    end)

    local PlusBtn = Instance.new("TextButton", ScrollFrame)
    PlusBtn.Text = "⚙"
    PlusBtn.Size = UDim2.new(0, 45, 0, 45)
    PlusBtn.Position = UDim2.new(0.72, 0, 0, posicionY)
    PlusBtn.BackgroundColor3 = COLORS.Accent
    PlusBtn.TextColor3 = COLORS.Text
    PlusBtn.Font = Enum.Font.GothamBold
    PlusBtn.TextSize = 18

    local plusCorner = Instance.new("UICorner", PlusBtn)
    plusCorner.CornerRadius = UDim.new(0, 10)

    local plusStroke = Instance.new("UIStroke", PlusBtn)
    plusStroke.Color = COLORS.AccentSecondary
    plusStroke.Thickness = 1.5
    plusStroke.Transparency = 0.5

    PlusBtn.MouseEnter:Connect(function()
        TweenService:Create(PlusBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(160, 60, 255),
            Rotation = 90
        }):Play()
    end)

    PlusBtn.MouseLeave:Connect(function()
        TweenService:Create(PlusBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.Accent,
            Rotation = 0
        }):Play()
    end)

    PlusBtn.MouseButton1Click:Connect(function()
        crearConfigPopup(nombre, camposConfig)
    end)
end

local function crearBotonAccion(nombre, posicionY, callback, emoji)
    local Btn = Instance.new("TextButton", ScrollFrame)
    Btn.Text = (emoji or "⚠") .. "  " .. nombre
    Btn.Size = UDim2.new(0.96, 0, 0, 45)
    Btn.Position = UDim2.new(0.02, 0, 0, posicionY)
    Btn.BackgroundColor3 = COLORS.Danger
    Btn.TextColor3 = COLORS.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14

    local btnCorner = Instance.new("UICorner", Btn)
    btnCorner.CornerRadius = UDim.new(0, 10)

    local btnStroke = Instance.new("UIStroke", Btn)
    btnStroke.Color = Color3.fromRGB(255, 100, 110)
    btnStroke.Thickness = 2
    btnStroke.Transparency = 0.5

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(255, 100, 110)
        }):Play()
    end)

    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.Danger
        }):Play()
    end)

    Btn.MouseButton1Click:Connect(callback)
end

-- ==========================================
-- BOTONES PRINCIPALES
-- ==========================================
local yStart = 5
local step  = 52

crearToggle(
    "Auto Bat (Kill Aura)",
    yStart + step * 0,
    "AutoBat",
    startAutoBatLoop,
    {
        { label = "Rango Auto Bat", key = "AutoBatRange" },
        { label = "Velocidad Swing (s)", key = "AutoSwingSpeed" },
    },
    "⚔"
)

crearToggle(
    "Auto-Grab Brainrots",
    yStart + step * 1,
    "AutoGrabBrainrots",
    startAutoGrabLoop,
    {
        { label = "Rango Auto-Grab", key = "AutoGrabRange" },
    },
    "🧲"
)

crearToggle(
    "Helicopter Spin",
    yStart + step * 2,
    "HelicopterSpin",
    startHeliLoop,
    {
        { label = "Grados por segundo", key = "HelicopterSpeed" },
    },
    "🚁"
)

crearToggle(
    "Fly Mode",
    yStart + step * 3,
    "FlyMode",
    startFlyLoop,
    {
        { label = "Velocidad Fly", key = "FlySpeed" },
    },
    "✈"
)

crearToggle(
    "Infinite Jump",
    yStart + step * 4,
    "InfiniteJump",
    nil,
    nil,
    "🦘"
)

crearToggle(
    "CFrame Booster",
    yStart + step * 5,
    "CFrameBooster",
    startBoostLoop,
    {
        { label = "Multiplicador vel.", key = "SpeedMultiplier" },
    },
    "⚡"
)

crearBotonAccion(
    "Unload (Limpiar todo)",
    yStart + step * 6,
    CleanUnload,
    "🗑"
)
