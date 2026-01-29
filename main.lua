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
-- CONFIGURACIÓN GENERAL
-- ==========================================
local TARGET_NAME = "brainrots" -- nombre exacto del objetivo

local Config = {
    AutoPlaySpeed   = 30,   -- velocidad hacia brainrots/base (stud/s)
    HelicopterSpeed = 720,  -- grados/s en Helicopter Spin
    SpeedMultiplier = 3,    -- multiplicador de movimiento (CFrame Booster)
    AutoBatRange    = 15,   -- rango de Auto Bat (Kill Aura)
    FlySpeed        = 50,   -- velocidad del Fly Mode (stud/s)
}

local function getCharacterAndHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    return character, hrp, humanoid
end

-- ==========================================
-- UI PRINCIPAL (DARK NEON)
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

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "DelfinBot Panel"
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

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

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = ConfigFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 200, 255)
        stroke.Thickness = 1.5
        stroke.Parent = ConfigFrame

        local header = Instance.new("TextLabel")
        header.Name = "Header"
        header.Size = UDim2.new(1, -40, 0, 30)
        header.Position = UDim2.new(0, 10, 0, 5)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 18
        header.TextColor3 = Color3.fromRGB(0, 255, 255)
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = ConfigFrame

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -35, 0, 5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.Text = "X"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 16
        closeBtn.Parent = ConfigFrame

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(1, 0)
        closeCorner.Parent = closeBtn

        closeBtn.MouseButton1Click:Connect(function()
            ConfigFrame.Visible = false
        end)

        local camposContainer = Instance.new("Frame")
        camposContainer.Name = "Campos"
        camposContainer.Size = UDim2.new(1, -20, 1, -50)
        camposContainer.Position = UDim2.new(0, 10, 0, 45)
        camposContainer.BackgroundTransparency = 1
        camposContainer.Parent = ConfigFrame

        local uiList = Instance.new("UIListLayout")
        uiList.Padding = UDim.new(0, 8)
        uiList.FillDirection = Enum.FillDirection.Vertical
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
        uiList.Parent = camposContainer
    end

    ConfigFrame.Header.Text = "Config: " .. nombre

    for _, child in ipairs(ConfigFrame.Campos:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for _, info in ipairs(campos or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.Parent = ConfigFrame.Campos

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.55, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = info.label
        label.Parent = row

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.4, 0, 1, 0)
        input.Position = UDim2.new(0.6, 0, 0, 0)
        input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        input.TextColor3 = Color3.new(1, 1, 1)
        input.Font = Enum.Font.Gotham
        input.TextSize = 14
        input.ClearTextOnFocus = false
        input.Text = tostring(Config[info.key] or "")
        input.Parent = row

        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, 6)
        inputCorner.Parent = input

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
-- HELPERS: BRAINROTS Y BASE DEL JUGADOR
-- ==========================================
local function findNearestBrainrots()
    local _, hrp = getCharacterAndHRP()
    local nearest
    local bestDist = math.huge

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
        if m.PrimaryPart then
            return m.PrimaryPart
        end
        local part = m:FindFirstChildWhichIsA("BasePart", true)
        return part
    end

    -- 1) nombre del modelo contiene player.Name o UserId
    local candidatoPorNombre
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if nameLower:find(playerNameLower) or nameLower:find(userIdStr) then
                local basePart = getBasePartFromModel(obj)
                if basePart then
                    candidatoPorNombre = basePart
                    break
                end
            end
        end
    end
    if candidatoPorNombre then
        return candidatoPorNombre
    end

    -- 2) buscar propiedad Owner / OwnerID
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("OwnerID")
            if ownerVal then
                local esMia = false

                if ownerVal:IsA("IntValue") then
                    esMia = (ownerVal.Value == player.UserId)
                elseif ownerVal:IsA("StringValue") then
                    local valLower = string.lower(ownerVal.Value)
                    if valLower == playerNameLower or ownerVal.Value == userIdStr then
                        esMia = true
                    end
                end

                if esMia then
                    local basePart = getBasePartFromModel(obj)
                    if basePart then
                        return basePart
                    end
                end
            end
        end
    end

    return nil
end

-- ==========================================
-- AUTOPLAY BRAINROTS (BUCLE)
-- ==========================================
local autoPlayOn = false
local autoPlayThread

local function AutoPlayToggle()
    autoPlayOn = not autoPlayOn

    if autoPlayOn and not autoPlayThread then
        autoPlayThread = task.spawn(function()
            while autoPlayOn and task.wait() do
                local ok, err = pcall(function()
                    local _, hrp = getCharacterAndHRP()
                    local brain = findNearestBrainrots()
                    local basePart = findPlayerBase()

                    if not brain then
                        warn("No se encontró ningún '" .. TARGET_NAME .. "'.")
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

                    if not autoPlayOn then return end

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
                    warn("Error en Autoplay: ", err)
                    task.wait(1)
                end
            end
            autoPlayThread = nil
        end)
    end
end

-- ==========================================
-- AUTO BAT (KILL AURA)
-- ==========================================
local autoBatOn = false
local autoBatThread

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

local function AutoBatToggle()
    autoBatOn = not autoBatOn

    if autoBatOn and not autoBatThread then
        autoBatThread = task.spawn(function()
            while autoBatOn and task.wait(0.1) do
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
                            if ch and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChildOfClass("Humanoid") then
                                local thrp = ch.HumanoidRootPart
                                local dist = (thrp.Position - hrp.Position).Magnitude
                                if dist < (Config.AutoBatRange or 15) and dist < bestDist and ch.Humanoid.Health > 0 then
                                    bestDist = dist
                                    nearestEnemy = ch
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
                    warn("Error en AutoBat: ", err)
                    task.wait(0.5)
                end
            end
            autoBatThread = nil
        end)
    end
end

-- ==========================================
-- HELICOPTER SPIN
-- ==========================================
local helicopterConnection
local helicopterOn = false

local function StartHelicopterSpin()
    if helicopterConnection then return end
    local _, hrp = getCharacterAndHRP()

    helicopterConnection = RunService.Heartbeat:Connect(function(dt)
        local speedRad = math.rad(Config.HelicopterSpeed or 720)
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, speedRad * dt, 0)
    end)
end

local function StopHelicopterSpin()
    if helicopterConnection then
        helicopterConnection:Disconnect()
        helicopterConnection = nil
    end
end

local function ToggleHelicopterSpin()
    helicopterOn = not helicopterOn
    if helicopterOn then
        StartHelicopterSpin()
    else
        StopHelicopterSpin()
    end
end

-- ==========================================
-- FLY MODE (CFRAME + WASD)
-- ==========================================
local flyOn = false
local flyConnection
local lastFlyHumanoid

local function StartFly()
    if flyConnection then return end
    local _, hrp, humanoid = getCharacterAndHRP()
    lastFlyHumanoid = humanoid
    humanoid.PlatformStand = true

    flyConnection = RunService.Heartbeat:Connect(function(dt)
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
            local speed = Config.FlySpeed or 50
            hrp.CFrame = hrp.CFrame + moveDir * speed * dt
        end

        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
end

local function StopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if lastFlyHumanoid and lastFlyHumanoid.Parent then
        lastFlyHumanoid.PlatformStand = false
    end
end

local function ToggleFly()
    flyOn = not flyOn
    if flyOn then
        StartFly()
    else
        StopFly()
    end
end

-- ==========================================
-- INFINITE JUMP
-- ==========================================
local infiniteJumpOn = false
local infiniteJumpConn

local function ToggleInfiniteJump()
    infiniteJumpOn = not infiniteJumpOn

    if infiniteJumpOn and not infiniteJumpConn then
        infiniteJumpConn = UIS.JumpRequest:Connect(function()
            if infiniteJumpOn then
                local _, _, humanoid = getCharacterAndHRP()
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    elseif not infiniteJumpOn and infiniteJumpConn then
        infiniteJumpConn:Disconnect()
        infiniteJumpConn = nil
    end
end

-- ==========================================
-- CFRAME BOOSTER (VELOCIDAD SIN CAMBIAR WALKSPEED)
-- ==========================================
local speedConnection
local speedOn = false

local function StartSpeedBoost()
    if speedConnection then return end
    local _, hrp, humanoid = getCharacterAndHRP()

    speedConnection = RunService.Heartbeat:Connect(function()
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local mult = Config.SpeedMultiplier or 3
            local baseSpeed = humanoid.WalkSpeed
            local desired = moveDir.Unit * baseSpeed * mult

            local currentVel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(desired.X, currentVel.Y, desired.Z)
        end
    end)
end

local function StopSpeedBoost()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
end

local function ToggleSpeedBoost()
    speedOn = not speedOn
    if speedOn then
        StartSpeedBoost()
    else
        StopSpeedBoost()
    end
end

-- ==========================================
-- VISUALS: ESP PARA "brainrots" (DRAWING)
-- ==========================================
local espEnabled = false
local espObjects = {}       -- [BasePart] = DrawingObject
local espRenderConn
local espDescendantConn

local function clearESP()
    for part, draw in pairs(espObjects) do
        if draw then
            pcall(function() draw:Remove() end)
        end
        espObjects[part] = nil
    end
    if espRenderConn then
        espRenderConn:Disconnect()
        espRenderConn = nil
    end
    if espDescendantConn then
        espDescendantConn:Disconnect()
        espDescendantConn = nil
    end
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

local function ESP_Toggle()
    espEnabled = not espEnabled

    if not espEnabled then
        clearESP()
        return
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == TARGET_NAME then
            addESPForPart(obj)
        end
    end

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
                if draw then
                    draw.Visible = false
                end
            end
        end
    end)

    espDescendantConn = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name == TARGET_NAME then
            addESPForPart(obj)
        end
    end)
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
    autoPlayOn      = false
    autoBatOn       = false
    helicopterOn    = false
    flyOn           = false
    infiniteJumpOn  = false
    speedOn         = false
    espEnabled      = false

    StopHelicopterSpin()
    StopSpeedBoost()
    StopFly()
    clearESP()

    if infiniteJumpConn then
        infiniteJumpConn:Disconnect()
        infiniteJumpConn = nil
    end
    if antiAfkConn then
        antiAfkConn:Disconnect()
        antiAfkConn = nil
    end
    if uiToggleConn then
        uiToggleConn:Disconnect()
        uiToggleConn = nil
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end
end

-- ==========================================
-- CREACIÓN DE BOTONES
-- ==========================================
local function crearBotonFuncional(nombre, posicionY, funcionPrincipal, camposConfig)
    local Btn = Instance.new("TextButton")
    Btn.Text = nombre
    Btn.Size = UDim2.new(0.7, 0, 0, 40)
    Btn.Position = UDim2.new(0.05, 0, 0, posicionY)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14
    Btn.Parent = MainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = Btn

    if funcionPrincipal then
        Btn.MouseButton1Click:Connect(funcionPrincipal)
    end

    local PlusBtn = Instance.new("TextButton")
    PlusBtn.Text = "+"
    PlusBtn.Size = UDim2.new(0, 40, 0, 40)
    PlusBtn.Position = UDim2.new(0.8, 0, 0, posicionY)
    PlusBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    PlusBtn.TextColor3 = Color3.new(0,0,0)
    PlusBtn.Font = Enum.Font.GothamBold
    PlusBtn.TextSize = 20
    PlusBtn.Parent = MainFrame

    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(1, 0)
    plusCorner.Parent = PlusBtn

    PlusBtn.MouseButton1Click:Connect(function()
        crearConfigPopup(nombre, camposConfig)
    end)
end

-- ==========================================
-- BOTONES DEL PANEL PRINCIPAL
-- ==========================================
local yStart = 60
local step  = 45

crearBotonFuncional(
    "Autoplay brainrots",
    yStart + step * 0,
    AutoPlayToggle,
    {
        { label = "Velocidad (stud/s)", key = "AutoPlaySpeed" },
    }
)

crearBotonFuncional(
    "Auto Bat (Kill Aura)",
    yStart + step * 1,
    AutoBatToggle,
    {
        { label = "Rango Auto Bat", key = "AutoBatRange" },
    }
)

crearBotonFuncional(
    "Helicopter Spin",
    yStart + step * 2,
    ToggleHelicopterSpin,
    {
        { label = "Grados por segundo", key = "HelicopterSpeed" },
    }
)

crearBotonFuncional(
    "Fly Mode",
    yStart + step * 3,
    ToggleFly,
    {
        { label = "Velocidad Fly", key = "FlySpeed" },
    }
)

crearBotonFuncional(
    "Infinite Jump",
    yStart + step * 4,
    ToggleInfiniteJump,
    nil
)

crearBotonFuncional(
    "CFrame Booster",
    yStart + step * 5,
    ToggleSpeedBoost,
    {
        { label = "Multiplicador vel.", key = "SpeedMultiplier" },
    }
)

crearBotonFuncional(
    "ESP Visuals",
    yStart + step * 6,
    ESP_Toggle,
    nil
)

crearBotonFuncional(
    "Unload",
    yStart + step * 7,
    CleanUnload,
    nil
)
