-- ==========================================
-- DELFINBOT V3.5 - PROFESSIONAL EDITION
-- Strict Whitelist System
-- ==========================================

-- ==========================================
-- WHITELIST SYSTEM
-- ==========================================
local IDS_AUTORIZADAS = {
    [9383569669] = true,  -- Cliente principal
    -- Añade más IDs aquí: [ID] = true,
}

-- Verificación de autorización
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not IDS_AUTORIZADAS[LocalPlayer.UserId] then
    print('ID no autorizada')
    return
end

-- Notificación de acceso autorizado
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🐬 DelfinBot v3.5",
    Text = "Acceso Autorizado",
    Duration = 3
})

-- ==========================================
-- SERVICIOS Y VARIABLES
-- ==========================================
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

-- Configuración
local Config = {
    BatRange = 15,
    SwingSpeed = 0.4,
    HeliSpeed = 600,
    FlySpeed = 35,
    SpeedMult = 1.3,
}

-- Estado de funciones
local FuncionesActivas = {
    DoubleJump = false,
    AntiRagdoll = false,
    TornadoSpin = false,
    FlyMode = false,
    SpeedBoost = false,
}

-- Variables de control
local Connections = {}
local FlyVelocity, FlyAttachment
local BoostVelocity, BoostAttachment
local HeliVelocity, HeliAttachment
local CanDoubleJump = false
local HasDoubleJumped = false
local JumpCount = 0
local LastJumpReset = tick()

-- ==========================================
-- FUNCIONES AUXILIARES
-- ==========================================
local function getCharacter()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    return character, humanoidRootPart, humanoid
end

local function getBat()
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
    duration = duration or 3
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🐬 DelfinBot v3.5",
        Text = message,
        Duration = duration
    })
end

-- ==========================================
-- DOUBLE JUMP
-- ==========================================
local function setupDoubleJump()
    if Connections.DoubleJump then Connections.DoubleJump:Disconnect() end
    if Connections.Landed then Connections.Landed:Disconnect() end
    
    if not FuncionesActivas.DoubleJump then return end
    
    local character, _, humanoid = getCharacter()
    
    -- Reset jump count every 3 seconds
    task.spawn(function()
        while FuncionesActivas.DoubleJump do
            task.wait(3)
            if tick() - LastJumpReset > 3 then
                JumpCount = 0
                LastJumpReset = tick()
            end
        end
    end)
    
    Connections.Landed = humanoid.StateChanged:Connect(function(oldState, newState)
        if not FuncionesActivas.DoubleJump then return end
        if newState == Enum.HumanoidStateType.Landed then
            CanDoubleJump = true
            HasDoubleJumped = false
        elseif newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
            CanDoubleJump = true
        end
    end)
    
    Connections.DoubleJump = UserInputService.JumpRequest:Connect(function()
        if not FuncionesActivas.DoubleJump then return end
        
        local now = tick()
        if JumpCount >= 2 and now - LastJumpReset < 3 then
            return
        end
        
        pcall(function()
            local char, hrp, hum = getCharacter()
            if not char or not hrp or not hum then return end
            
            local state = hum:GetState()
            if (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping) and 
               CanDoubleJump and not HasDoubleJumped then
                
                JumpCount = JumpCount + 1
                
                -- Variable jump power for more natural movement
                local variation = math.random(55, 65) / 100
                local jumpPower = (hum.JumpPower or 50) * variation
                
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    jumpPower,
                    hrp.AssemblyLinearVelocity.Z
                )
                
                HasDoubleJumped = true
                CanDoubleJump = false
            end
        end)
    end)
end

-- ==========================================
-- ANTI-RAGDOLL
-- ==========================================
local function setupAntiRagdoll()
    if Connections.AntiRagdoll then Connections.AntiRagdoll:Disconnect() end
    if not FuncionesActivas.AntiRagdoll then return end
    
    local character, _, humanoid = getCharacter()
    if not character or not humanoid then return end
    
    Connections.AntiRagdoll = humanoid.StateChanged:Connect(function(oldState, newState)
        if not FuncionesActivas.AntiRagdoll then return end
        if newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.FallingDown then
            task.defer(function()
                task.wait(math.random(50, 150) / 1000)
                if humanoid and humanoid.Parent then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end)
    
    -- Keep joints active
    task.spawn(function()
        while FuncionesActivas.AntiRagdoll do
            pcall(function()
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("Motor6D") and not v.Enabled then
                        task.defer(function()
                            v.Enabled = true
                        end)
                    end
                end
            end)
            task.wait(math.random(200, 400) / 1000)
        end
    end)
end

-- ==========================================
-- TORNADO SPIN (HELICOPTER)
-- ==========================================
local function setupTornadoSpin()
    if not FuncionesActivas.TornadoSpin then
        if HeliVelocity then HeliVelocity:Destroy() end
        if HeliAttachment then HeliAttachment:Destroy() end
        HeliVelocity = nil
        HeliAttachment = nil
        return
    end
    
    task.spawn(function()
        while FuncionesActivas.TornadoSpin do
            pcall(function()
                local _, humanoidRootPart = getCharacter()
                if not HeliVelocity then
                    HeliAttachment = Instance.new("Attachment", humanoidRootPart)
                    HeliVelocity = Instance.new("AngularVelocity", humanoidRootPart)
                    HeliVelocity.Attachment0 = HeliAttachment
                    HeliVelocity.MaxTorque = math.huge
                end
                
                local speedVariation = Config.HeliSpeed + math.random(-50, 50)
                HeliVelocity.AngularVelocity = Vector3.new(0, math.rad(speedVariation), 0)
            end)
            task.wait()
        end
        
        if HeliVelocity then HeliVelocity:Destroy() end
        if HeliAttachment then HeliAttachment:Destroy() end
        HeliVelocity = nil
        HeliAttachment = nil
    end)
end

-- ==========================================
-- FLY MODE
-- ==========================================
local function setupFlyMode()
    if not FuncionesActivas.FlyMode then
        if FlyVelocity then FlyVelocity:Destroy() end
        if FlyAttachment then FlyAttachment:Destroy() end
        FlyVelocity = nil
        FlyAttachment = nil
        
        local _, _, humanoid = getCharacter()
        if humanoid then
            task.defer(function()
                task.wait(0.1)
                if humanoid.Parent then humanoid.PlatformStand = false end
            end)
        end
        return
    end
    
    task.spawn(function()
        local _, humanoidRootPart, humanoid = getCharacter()
        
        task.defer(function()
            task.wait(0.1)
            if humanoid then humanoid.PlatformStand = true end
        end)
        
        if not FlyVelocity then
            FlyAttachment = Instance.new("Attachment", humanoidRootPart)
            FlyVelocity = Instance.new("LinearVelocity", humanoidRootPart)
            FlyVelocity.Attachment0 = FlyAttachment
            FlyVelocity.MaxForce = math.huge
        end
        
        while FuncionesActivas.FlyMode do
            pcall(function()
                local camera = workspace.CurrentCamera
                if not camera then return end
                
                local moveVector = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveVector = moveVector + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveVector = moveVector - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveVector = moveVector - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveVector = moveVector + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveVector = moveVector + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveVector = moveVector - Vector3.new(0, 1, 0)
                end
                
                local speed = Config.FlySpeed + math.random(-2, 2)
                FlyVelocity.VectorVelocity = moveVector.Magnitude > 0 and moveVector.Unit * speed or Vector3.zero
            end)
            RunService.Heartbeat:Wait()
        end
        
        if FlyVelocity then FlyVelocity:Destroy() end
        if FlyAttachment then FlyAttachment:Destroy() end
        FlyVelocity = nil
        FlyAttachment = nil
        
        if humanoid then
            task.defer(function()
                task.wait(0.1)
                if humanoid.Parent then humanoid.PlatformStand = false end
            end)
        end
    end)
end

-- ==========================================
-- SPEED BOOST
-- ==========================================
local function setupSpeedBoost()
    if not FuncionesActivas.SpeedBoost then
        if BoostVelocity then BoostVelocity:Destroy() end
        if BoostAttachment then BoostAttachment:Destroy() end
        BoostVelocity = nil
        BoostAttachment = nil
        return
    end
    
    task.spawn(function()
        if not BoostVelocity then
            BoostAttachment = Instance.new("Attachment")
            BoostVelocity = Instance.new("LinearVelocity")
            BoostVelocity.MaxForce = math.huge
        end
        
        while FuncionesActivas.SpeedBoost do
            pcall(function()
                local _, humanoidRootPart, humanoid = getCharacter()
                if BoostAttachment.Parent ~= humanoidRootPart then
                    BoostAttachment.Parent = humanoidRootPart
                    BoostVelocity.Parent = humanoidRootPart
                    BoostVelocity.Attachment0 = BoostAttachment
                end
                
                local moveDirection = humanoid.MoveDirection
                local multiplier = Config.SpeedMult + (math.random(-10, 10) / 100)
                BoostVelocity.VectorVelocity = moveDirection.Magnitude > 0 and moveDirection.Unit * humanoid.WalkSpeed * multiplier or Vector3.zero
            end)
            RunService.Heartbeat:Wait()
        end
        
        if BoostVelocity then BoostVelocity:Destroy() end
        if BoostAttachment then BoostAttachment:Destroy() end
        BoostVelocity = nil
        BoostAttachment = nil
    end)
end

-- ==========================================
-- AUTO BAT
-- ==========================================
local function setupAutoBat()
    -- Esta función puede ser implementada si se necesita
    -- Por ahora, mantenemos el sistema simple
end

-- ==========================================
-- CHARACTER ADDED HANDLER
-- ==========================================
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    CanDoubleJump = false
    HasDoubleJumped = false
    JumpCount = 0
    LastJumpReset = tick()
    
    if FuncionesActivas.DoubleJump then setupDoubleJump() end
    if FuncionesActivas.AntiRagdoll then setupAntiRagdoll() end
end)

-- ==========================================
-- ANTI-AFK
-- ==========================================
LocalPlayer.Idled:Connect(function()
    task.defer(function()
        task.wait(math.random(500, 1500) / 1000)
        VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
    end)
end)

-- ==========================================
-- UI SYSTEM
-- ==========================================
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DelfinBotUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 350, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
    
    local UIStroke = Instance.new("UIStroke", MainFrame)
    UIStroke.Color = Color3.fromRGB(0, 191, 255)
    UIStroke.Thickness = 2
    UIStroke.Transparency = 0.3
    
    -- Header
    local Header = Instance.new("Frame", MainFrame)
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Header.BorderSizePixel = 0
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)
    
    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Text = "🐬 DelfinBot v3.5"
    Title.TextSize = 18
    Title.TextColor3 = Color3.fromRGB(240, 240, 245)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Minimize button
    local MinimizeButton = Instance.new("TextButton", Header)
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Position = UDim2.new(1, -35, 0, 10)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    MinimizeButton.Text = "━"
    MinimizeButton.TextColor3 = Color3.fromRGB(240, 240, 245)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 14
    Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)
    
    local isMinimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        MinimizeButton.Text = isMinimized and "+" or "━"
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            Size = isMinimized and UDim2.new(0, 350, 0, 50) or UDim2.new(0, 350, 0, 400)
        }):Play()
    end)
    
    -- Buttons container
    local ButtonContainer = Instance.new("ScrollingFrame", MainFrame)
    ButtonContainer.Name = "ButtonContainer"
    ButtonContainer.Size = UDim2.new(1, -20, 1, -60)
    ButtonContainer.Position = UDim2.new(0, 10, 0, 55)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.BorderSizePixel = 0
    ButtonContainer.ScrollBarThickness = 4
    ButtonContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 191, 255)
    ButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 350)
    
    -- Toggle button function
    local function createToggleButton(name, position, key, emoji)
        local Button = Instance.new("TextButton", ButtonContainer)
        Button.Name = name .. "Button"
        Button.Size = UDim2.new(0.9, 0, 0, 40)
        Button.Position = UDim2.new(0.05, 0, 0, position)
        Button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        Button.Text = (emoji or "●") .. "  " .. name
        Button.TextColor3 = Color3.fromRGB(240, 240, 245)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
        
        local ButtonStroke = Instance.new("UIStroke", Button)
        ButtonStroke.Color = Color3.fromRGB(0, 191, 255)
        ButtonStroke.Thickness = 1
        ButtonStroke.Transparency = 0.7
        
        local function updateButton()
            local isActive = FuncionesActivas[key]
            TweenService:Create(Button, TweenInfo.new(0.3), {
                BackgroundColor3 = isActive and Color3.fromRGB(0, 191, 255) or Color3.fromRGB(50, 50, 60)
            }):Play()
            TweenService:Create(ButtonStroke, TweenInfo.new(0.3), {
                Transparency = isActive and 0.2 or 0.7
            }):Play()
        end
        
        Button.MouseButton1Click:Connect(function()
            FuncionesActivas[key] = not FuncionesActivas[key]
            updateButton()
            
            -- Setup corresponding function
            if key == "DoubleJump" then
                setupDoubleJump()
            elseif key == "AntiRagdoll" then
                setupAntiRagdoll()
            elseif key == "TornadoSpin" then
                setupTornadoSpin()
            elseif key == "FlyMode" then
                setupFlyMode()
            elseif key == "SpeedBoost" then
                setupSpeedBoost()
            end
            
            notify(name .. (FuncionesActivas[key] and " Activado" or " Desactivado"), 2)
        end)
        
        updateButton()
    end
    
    -- Create toggle buttons
    local buttonSpacing = 50
    createToggleButton("Double Jump", 0, "DoubleJump", "🦘")
    createToggleButton("Anti-Ragdoll", buttonSpacing * 1, "AntiRagdoll", "🛡")
    createToggleButton("Tornado Spin", buttonSpacing * 2, "TornadoSpin", "🌪")
    createToggleButton("Fly Mode", buttonSpacing * 3, "FlyMode", "✈")
    createToggleButton("Speed Boost", buttonSpacing * 4, "SpeedBoost", "🏃")
    
    -- Unload button
    local UnloadButton = Instance.new("TextButton", ButtonContainer)
    UnloadButton.Name = "UnloadButton"
    UnloadButton.Size = UDim2.new(0.9, 0, 0, 40)
    UnloadButton.Position = UDim2.new(0.05, 0, 0, buttonSpacing * 5)
    UnloadButton.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    UnloadButton.Text = "🗑  Unload Script"
    UnloadButton.TextColor3 = Color3.fromRGB(240, 240, 245)
    UnloadButton.Font = Enum.Font.GothamBold
    UnloadButton.TextSize = 14
    Instance.new("UICorner", UnloadButton).CornerRadius = UDim.new(0, 8)
    
    UnloadButton.MouseButton1Click:Connect(function()
        -- Disable all functions
        for key in pairs(FuncionesActivas) do
            FuncionesActivas[key] = false
        end
        
        -- Disconnect all connections
        for _, connection in pairs(Connections) do
            if connection then connection:Disconnect() end
        end
        
        -- Clean up physics objects
        if FlyVelocity then FlyVelocity:Destroy() end
        if FlyAttachment then FlyAttachment:Destroy() end
        if BoostVelocity then BoostVelocity:Destroy() end
        if BoostAttachment then BoostAttachment:Destroy() end
        if HeliVelocity then HeliVelocity:Destroy() end
        if HeliAttachment then HeliAttachment:Destroy() end
        
        -- Destroy UI
        ScreenGui:Destroy()
        
        notify("Script Descargado", 3)
    end)
    
    -- Make UI draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Toggle UI with RightControl
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= Enum.KeyCode.RightControl then return end
        local isHidden = MainFrame.Position.Y.Scale > 0.9
        TweenService:Create(MainFrame, TweenInfo.new(0.4), {
            Position = isHidden and UDim2.new(0.5, -175, 0.5, -200) or UDim2.new(0.5, -175, 1.2, 0)
        }):Play()
    end)
end

-- ==========================================
-- INITIALIZATION
-- ==========================================
createUI()
notify("Sistema Cargado Exitosamente", 3)

print("DelfinBot v3.5 - Professional Edition")
print("Usuario autorizado: " .. LocalPlayer.Name)
print("ID: " .. LocalPlayer.UserId)
