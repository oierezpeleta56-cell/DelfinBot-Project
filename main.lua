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

local player = Players.LocalPlayer
if not IDs_Autorizadas[player.UserId] then return end

-- ==========================================
-- CONFIG Y VARIABLES GLOBALES
-- ==========================================
local TARGET_NAME = "brainrots"

local Config = {
    AutoPlaySpeed   = 30,
    HelicopterSpeed = 720,
    SpeedMultiplier = 1.5, -- moderado para evitar rubberband
    AutoBatRange    = 15,
    FlySpeed        = 40,
}

_G.AutoPlay       = _G.AutoPlay       or false
_G.AutoBat        = _G.AutoBat        or false
_G.HelicopterSpin = _G.HelicopterSpin or false
_G.FlyMode        = _G.FlyMode        or false
_G.InfiniteJump   = _G.InfiniteJump   or false
_G.CFrameBooster  = _G.CFrameBooster  or false
_G.ESPVisuals     = _G.ESPVisuals     or false

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

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 1.5

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -60, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "DelfinBot Panel"
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Frame que contiene los botones (para min/max)
local ButtonsFrame = Instance.new("Frame", MainFrame)
ButtonsFrame.Size = UDim2.new(1, 0, 1, -55)
ButtonsFrame.Position = UDim2.new(0, 0, 0, 50)
ButtonsFrame.BackgroundTransparency = 1

-- Botón de minimizar
local MinBtn = Instance.new("TextButton", MainFrame)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -40, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
local MinCorner = Instance.new("UICorner", MinBtn)
MinCorner.CornerRadius = UDim.new(1, 0)

local expandedSize  = UDim2.new(0, 350, 0, 450)
local collapsedSize = UDim2.new(0, 350, 0, 60)
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ButtonsFrame.Visible = not minimized
    TweenService:Create(
        MainFrame,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = minimized and collapsedSize or expandedSize }
    ):Play()
end)

-- UI Draggable (MainFrame completo)
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
    Title.InputBegan:Connect(onInputBegan)
    UIS.InputChanged:Connect(onInputChanged)
end

-- ==========================================
-- POP-UP DE CONFIGURACIÓN DEL "+"
-- ==========================================
local ConfigFrame

local function crearConfigPopup(nombre, campos)
    if not ConfigFrame then
        ConfigFrame = Instance.new("Frame")
        ConfigFrame.Size = UDim2.new(0, 260, 0, 230)
        ConfigFrame.Position = UDim2.new(0.5, -130, 0.5, -115)
        ConfigFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        ConfigFrame.BorderSizePixel = 0
        ConfigFrame.Visible = false
        ConfigFrame.Parent = ScreenGui

        local corner = Instance.new("UICorner", ConfigFrame)
        corner.CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke", ConfigFrame)
        stroke.Color = Color3.fromRGB(0, 200, 255)
        stroke.Thickness = 1.5

        local header = Instance.new("TextLabel", ConfigFrame)
        header.Name = "Header"
        header.Size = UDim2.new(1, -40, 0, 30)
        header.Position = UDim2.new(0, 10, 0, 5)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 18
        header.TextColor3 = Color3.fromRGB(0, 255, 255)
        header.TextXAlignment = Enum.TextXAlignment.Left

        local closeBtn = Instance.new("TextButton", ConfigFrame)
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -35, 0, 5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.Text = "X"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 16
        local closeCorner = Instance.new("UICorner", closeBtn)
        closeCorner.CornerRadius = UDim.new(1, 0)

        closeBtn.MouseButton1Click:Connect(function()
            ConfigFrame.Visible = false
        end)

        local camposContainer = Instance.new("Frame", ConfigFrame)
        camposContainer.Name = "Campos"
        camposContainer.Size = UDim2.new(1, -20, 1, -50)
        camposContainer.Position = UDim2.new(0, 10, 0, 45)
        camposContainer.BackgroundTransparency = 1

        local uiList = Instance.new("UIListLayout", camposContainer)
        uiList.Padding = UDim.new(0, 8)
        uiList.FillDirection = Enum.FillDirection.Vertical
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
    end

    ConfigFrame.Header.Text = "Config: " .. nombre

    for _, child in ipairs(ConfigFrame.Campos:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, info in ipairs(campos or {}) do
        local row = Instance.new("Frame", ConfigFrame.Campos)
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", row)
        label.Size = UDim2.new(0.55, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = info.label

        local input = Instance.new("TextBox", row)
        input.Size = UDim2.new(0.4, 0, 1, 0)
        input.Position = UDim2.new(0.6, 0, 0, 0)
        input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        input.TextColor3 = Color3.new(1, 1, 1)
        input.Font = Enum.Font.Gotham
        input.TextSize = 14
        input.ClearTextOnFocus = false
        input.Text = tostring(Config[info.key] or "")

        local inputCorner = Instance.new("UICorner", input)
        inputCorner.CornerRadius = UDim.new(0, 6)

        input.FocusLost:Connect(function()
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

    -- Por nombre del modelo
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if nameLower:find(playerNameLower) or nameLower:find(userIdStr) then
                local part = getBasePartFromModel(obj)
                if part then return part end
            end
        end
    end

    -- Por Owner / OwnerID
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
-- AUTOPLAY BRAINROTS (BUCLE SEGURO)
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

                local speed = Config.AutoPlaySpeed or 30

                -- Ir al brainrots
                local brainPos = brain.Position + Vector3.new(0, 3, 0)
                local d1 = (brainPos - hrp.Position).Magnitude
                local t1 = math.clamp(d1 / speed, 0.1, 10)
                local tween1 = TweenService:Create(
                    hrp,
                    TweenInfo.new(t1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                    { CFrame = CFrame.new(brainPos) }
                )
                tween1:Play()
                tween1.Completed:Wait()
                if not _G.AutoPlay then return end

                -- Volver a la base
                local basePos = basePart.Position + Vector3.new(0, 3, 0)
                local d2 = (basePos - hrp.Position).Magnitude
                local t2 = math.clamp(d2 / speed, 0.1, 10)
                local tween2 = TweenService:Create(
                    hrp,
                    TweenInfo.new(t2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                    { CFrame = CFrame.new(basePos) }
                )
                tween2:Play()
                tween2.Completed:Wait()
            end)
            if not ok then
                warn("Error en Autoplay:", err)
                task.wait(1)
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
                    hrp.CFrame = CFrame.new(thrp.Position + thrp.CFrame.LookVector * -2)
                    bat:Activate()
                end
            end)
            if not ok then
                warn("Error en AutoBat:", err)
            end
            task.wait(0.1) -- no saturar servidor
        end
        autoBatRunning = false
    end)
end

-- ==========================================
-- HELICOPTER SPIN
-- ==========================================
local heliRunning = false
local function startHeliLoop()
    if heliRunning then return end
    heliRunning = true

    task.spawn(function()
        while _G.HelicopterSpin do
            local dt = RunService.Heartbeat:Wait()
            local ok, err = pcall(function()
                local _, hrp = getCharacterAndHRP()
                local speedRad = math.rad(Config.HelicopterSpeed or 720)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, speedRad * dt, 0)
            end)
            if not ok then
                warn("Error Helicopter:", err)
            end
        end
        heliRunning = false
    end)
end

-- ==========================================
-- FLY MODE (VELOCIDAD SUAVIZADA, MENOS RUBBERBAND)
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

                local currentVel = hrp.AssemblyLinearVelocity
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    local speed = Config.FlySpeed or 40
                    local targetVel = moveDir * speed
                    -- suavizado para no dar picos de velocidad
                    local newVel = currentVel:Lerp(targetVel, 0.4)
                    hrp.AssemblyLinearVelocity = Vector3.new(newVel.X, newVel.Y, newVel.Z)
                else
                    -- si no se pulsa nada, suavemente reducimos
                    local newVel = currentVel:Lerp(Vector3.new(0, 0, 0), 0.2)
                    hrp.AssemblyLinearVelocity = Vector3.new(newVel.X, newVel.Y, newVel.Z)
                end
            end)
            if not ok then
                warn("Error Fly:", err)
            end
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
-- CFRAME BOOSTER (ANTI-RUBBERBAND)
-- ==========================================
local boostRunning = false
local function startBoostLoop()
    if boostRunning then return end
    boostRunning = true

    task.spawn(function()
        while _G.CFrameBooster do
            local dt = RunService.Heartbeat:Wait()
            local ok, err = pcall(function()
                local _, hrp, humanoid = getCharacterAndHRP()
                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    local mult = Config.SpeedMultiplier or 1.5
                    mult = math.clamp(mult, 1, 2) -- clamp para evitar flags
                    local vel = hrp.AssemblyLinearVelocity
                    local horiz = Vector3.new(vel.X, 0, vel.Z)
                    local boosted = horiz * mult
                    -- mezclamos, no teletransportamos
                    local final = horiz:Lerp(boosted, 0.3)
                    hrp.AssemblyLinearVelocity = Vector3.new(final.X, vel.Y, final.Z)
                end
            end)
            if not ok then
                warn("Error Booster:", err)
            end
        end
        boostRunning = false
    end)
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
    text.Color = Color3.fromRGB(0, 255, 255)
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
            and UDim2.new(0.5, -175, 1.1, 0)
            or  UDim2.new(0.5, -175, 0.5, -225)

        TweenService:Create(
            MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = targetPos }
        ):Play()
    end
end)

-- ==========================================
-- CLEAN UNLOAD
-- ==========================================
local function CleanUnload()
    _G.AutoPlay       = false
    _G.AutoBat        = false
    _G.HelicopterSpin = false
    _G.FlyMode        = false
    _G.InfiniteJump   = false
    _G.CFrameBooster  = false
    _G.ESPVisuals     = false

    updateInfiniteJump()
    clearESP()

    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if uiToggleConn then uiToggleConn:Disconnect() uiToggleConn = nil end

    if ScreenGui then ScreenGui:Destroy() end
end

-- ==========================================
-- CREACIÓN DE BOTONES (TOGGLES REALES)
-- ==========================================
local function crearToggle(nombre, posicionY, toggleKey, loopStarter, camposConfig)
    local Btn = Instance.new("TextButton", ButtonsFrame)
    Btn.Text = nombre
    Btn.Size = UDim2.new(0.7, 0, 0, 40)
    Btn.Position = UDim2.new(0.05, 0, 0, posicionY)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14

    local btnCorner = Instance.new("UICorner", Btn)
    btnCorner.CornerRadius = UDim.new(0, 8)

    local function actualizarColor()
        if _G[toggleKey] then
            Btn.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            Btn.TextColor3 = Color3.new(0,0,0)
        else
            Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Btn.TextColor3 = Color3.new(1,1,1)
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
        end
    end)

    local PlusBtn = Instance.new("TextButton", ButtonsFrame)
    PlusBtn.Text = "+"
    PlusBtn.Size = UDim2.new(0, 40, 0, 40)
    PlusBtn.Position = UDim2.new(0.8, 0, 0, posicionY)
    PlusBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    PlusBtn.TextColor3 = Color3.new(0,0,0)
    PlusBtn.Font = Enum.Font.GothamBold
    PlusBtn.TextSize = 20

    local plusCorner = Instance.new("UICorner", PlusBtn)
    plusCorner.CornerRadius = UDim.new(1, 0)

    PlusBtn.MouseButton1Click:Connect(function()
        crearConfigPopup(nombre, camposConfig)
    end)
end

local function crearBotonAccion(nombre, posicionY, callback)
    local Btn = Instance.new("TextButton", ButtonsFrame)
    Btn.Text = nombre
    Btn.Size = UDim2.new(0.9, 0, 0, 40)
    Btn.Position = UDim2.new(0.05, 0, 0, posicionY)
    Btn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14

    local btnCorner = Instance.new("UICorner", Btn)
    btnCorner.CornerRadius = UDim.new(0, 8)

    Btn.MouseButton1Click:Connect(callback)
end

-- ==========================================
-- BOTONES PRINCIPALES
-- ==========================================
local yStart = 10
local step  = 45

crearToggle(
    "Autoplay brainrots",
    yStart + step * 0,
    "AutoPlay",
    startAutoPlayLoop,
    {
        { label = "Velocidad (stud/s)", key = "AutoPlaySpeed" },
    }
)

crearToggle(
    "Auto Bat (Kill Aura)",
    yStart + step * 1,
    "AutoBat",
    startAutoBatLoop,
    {
        { label = "Rango Auto Bat", key = "AutoBatRange" },
    }
)

crearToggle(
    "Helicopter Spin",
    yStart + step * 2,
    "HelicopterSpin",
    startHeliLoop,
    {
        { label = "Grados por segundo", key = "HelicopterSpeed" },
    }
)

crearToggle(
    "Fly Mode",
    yStart + step * 3,
    "FlyMode",
    startFlyLoop,
    {
        { label = "Velocidad Fly", key = "FlySpeed" },
    }
)

crearToggle(
    "Infinite Jump",
    yStart + step * 4,
    "InfiniteJump",
    nil,
    nil
)

crearToggle(
    "CFrame Booster",
    yStart + step * 5,
    "CFrameBooster",
    startBoostLoop,
    {
        { label = "Multiplicador vel.", key = "SpeedMultiplier" },
    }
)

crearToggle(
    "ESP Visuals",
    yStart + step * 6,
    "ESPVisuals",
    nil,
    nil
)

crearBotonAccion(
    "Unload (Limpiar todo)",
    yStart + step * 7,
    CleanUnload
)
