<think>
Primero, el usuario quiere que elimine cualquier sistema de keys o contraseñas. En el script original, hay un sistema de clave con _G.Key = "exploiter". Necesito quitar eso.


## Removing Key System  
- The user requests removing any key or password systems from the original script.  
- Found a key system with _G.Key = "exploiter" that needs to be eliminated.
</think>```lua
-- ==========================================
-- DELFINBOT V3.5 - STEALTH EDITION (MODIFICADO)
-- Anti-Detection + Optimized
-- ==========================================

-- Tabla de IDs autorizadas (fácil de editar: añade más IDs aquí)
local IDs_Autorizadas = {
    [9383569669] = true,
    -- Ejemplo: añade más así: [123456789] = true,
}

-- Verificación de ID
local plr = game:GetService("Players").LocalPlayer
if not IDs_Autorizadas[plr.UserId] then
    print('ID no autorizada')
    return
end

-- Notificación de acceso autorizado
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "✅ Acceso Autorizado",
    Text = "DelfinBot v3.5: Cargando funciones...",
    Duration = 3
})

-- ==========================================
-- ANTI-DETECTION SETUP
-- ==========================================
-- Ocultar del script scanner de Roblox
local function protect(instance)
    if gethiddenproperty then
        pcall(function()
            gethiddenproperty(instance, "Name")
        end)
    end
    if sethiddenproperty then
        pcall(function()
            sethiddenproperty(instance, "Name", tostring(math.random(100000, 999999)))
        end)
    end
end

-- Randomizar nombres para evitar detección de patrones
local function randomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. chars:sub(rand, rand)
    end
    return result
end

-- ==========================================
-- SERVICIOS Y VARIABLES (OFUSCADOS)
-- ==========================================
local P = game:GetService("Players")
local T = game:GetService("TweenService")
local R = game:GetService("RunService")
local U = game:GetService("UserInputService")
local V = game:GetService("VirtualUser")

local CFG = {
    HeliSpeed = 600, -- Menos agresivo
}

local TGL = {
    Jump = false,
    Ragdoll = false,
    Heli = false,
}

local THEME = "Cyan"
local THEMES = {
    Cyan = {
        BG = Color3.fromRGB(18, 18, 24),
        BG2 = Color3.fromRGB(25, 25, 35),
        AC = Color3.fromRGB(138, 43, 226),
        AC2 = Color3.fromRGB(0, 191, 255),
        TXT = Color3.fromRGB(240, 240, 245),
        DIM = Color3.fromRGB(160, 160, 170),
        OFF = Color3.fromRGB(35, 35, 45),
        ON = Color3.fromRGB(138, 43, 226),
        BRD = Color3.fromRGB(138, 43, 226),
    },
    Red = {
        BG = Color3.fromRGB(18, 18, 24),
        BG2 = Color3.fromRGB(35, 25, 25),
        AC = Color3.fromRGB(220, 38, 38),
        AC2 = Color3.fromRGB(255, 82, 82),
        TXT = Color3.fromRGB(240, 240, 245),
        DIM = Color3.fromRGB(160, 160, 170),
        OFF = Color3.fromRGB(35, 35, 45),
        ON = Color3.fromRGB(220, 38, 38),
        BRD = Color3.fromRGB(220, 38, 38),
    }
}
local C = THEMES[THEME]

local heli, heliA
local conns = {}
local canDoubleJump = false
local hasDoubleJumped = false

-- Variables para comportamiento humano
local humanDelays = {
    jump = 0,
}

-- ==========================================
-- NOTIFICACIONES (STEALTH)
-- ==========================================
local NotifFrame
local function notify(msg, dur)
    if not NotifFrame then
        NotifFrame = Instance.new("Frame")
        NotifFrame.Name = randomString(10) -- Nombre random
        NotifFrame.Size = UDim2.new(0, 300, 0, 0)
        NotifFrame.Position = UDim2.new(1, -320, 0, 20)
        NotifFrame.BackgroundTransparency = 1
        NotifFrame.Parent = plr:WaitForChild("PlayerGui"):WaitForChild(randomString(8))
        protect(NotifFrame)
        local l = Instance.new("UIListLayout", NotifFrame)
        l.Padding = UDim.new(0, 10)
    end
    
    local n = Instance.new("Frame", NotifFrame)
    n.Name = randomString(8)
    n.Size = UDim2.new(1, 0, 0, 0)
    n.BackgroundColor3 = C.BG2
    n.BorderSizePixel = 0
    protect(n)
    Instance.new("UICorner", n).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", n)
    s.Color = C.AC2
    s.Thickness = 2
    s.Transparency = 0.3
    
    local t = Instance.new("TextLabel", n)
    t.Size = UDim2.new(1, -20, 1, 0)
    t.Position = UDim2.new(0, 10, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.Gotham
    t.TextSize = 13
    t.TextColor3 = C.TXT
    t.Text = msg
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextWrapped = true
    
    T:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 0, 50)}):Play()
    task.delay(dur or 3, function()
        T:Create(n, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        task.wait(0.3)
        n:Destroy()
    end)
end

-- ==========================================
-- HELPERS (CON RETRASOS HUMANOS)
-- ==========================================
local function getCHH()
    local c = plr.Character or plr.CharacterAdded:Wait()
    local h = c:WaitForChild("HumanoidRootPart", 5)
    local hum = c:WaitForChild("Humanoid", 5)
    return c, h, hum
end

-- Retraso humano random
local function humanDelay(min, max)
    task.wait(math.random(min * 100, max * 100) / 100)
end

-- ==========================================
-- DOUBLE JUMP (STEALTH + LIMITADO)
-- ==========================================
local jumpCount = 0
local lastJumpReset = tick()

local function setupDoubleJump()
    if conns.jump then conns.jump:Disconnect() end
    if conns.landed then conns.landed:Disconnect() end
    
    if not TGL.Jump then return end
    
    local c, h, hum = getCHH()
    
    -- Reset cada 3 segundos (comportamiento más humano)
    task.spawn(function()
        while TGL.Jump do
            task.wait(3)
            if tick() - lastJumpReset > 3 then
                jumpCount = 0
                lastJumpReset = tick()
            end
        end
    end)
    
    conns.landed = hum.StateChanged:Connect(function(old, new)
        if not TGL.Jump then return end
        if new == Enum.HumanoidStateType.Landed then
            canDoubleJump = true
            hasDoubleJumped = false
        elseif new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
            canDoubleJump = true
        end
    end)
    
    conns.jump = U.JumpRequest:Connect(function()
        if not TGL.Jump then return end
        
        -- Limitar a 2 saltos por cada 3 segundos (anti-spam detection)
        local now = tick()
        if now - humanDelays.jump < 0.2 then return end
        humanDelays.jump = now
        
        if jumpCount >= 2 and now - lastJumpReset < 3 then
            return -- No permitir más de 2 saltos en 3 segundos
        end
        
        pcall(function()
            local char, hrp, humanoid = getCHH()
            if not char or not hrp or not humanoid then return end
            
            local state = humanoid:GetState()
            if (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping) and 
               canDoubleJump and not hasDoubleJumped then
                
                jumpCount = jumpCount + 1
                
                -- Fuerza variable para parecer más humano (55-65%)
                local variation = math.random(55, 65) / 100
                local jumpPower = (humanoid.JumpPower or 50) * variation
                
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
-- ANTI-RAGDOLL (STEALTH)
-- ==========================================
local function setupAntiRagdoll()
    if conns.ragdoll then conns.ragdoll:Disconnect() end
    if not TGL.Ragdoll then return end
    
    local c, h, hum = getCHH()
    if not c or not hum then return end
    
    -- Usar task.defer para evitar detección de bucles sospechosos
    conns.ragdoll = hum.StateChanged:Connect(function(old, new)
        if not TGL.Ragdoll then return end
        if new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.FallingDown then
            task.defer(function()
                humanDelay(0.05, 0.15) -- Retraso humano
                if hum and hum.Parent then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end)
    
    -- Mantener joints activos de forma menos agresiva
    task.spawn(function()
        while TGL.Ragdoll do
            pcall(function()
                for _, v in pairs(c:GetDescendants()) do
                    if v:IsA("Motor6D") and not v.Enabled then
                        task.defer(function()
                            v.Enabled = true
                        end)
                    end
                end
            end)
            humanDelay(0.2, 0.4) -- Más lento para evitar detección
        end
    end)
end

-- ==========================================
-- TORNADO SPIN (RENOMBRADO DE HELICOPTER)
-- ==========================================
local heliRun = false
local function startHeli()
    if heliRun then return end
    heliRun = true
    
    task.spawn(function()
        while TGL.Heli do
            pcall(function()
                local _, h = getCHH()
                if not heli then
                    heliA = Instance.new("Attachment", h)
                    heliA.Name = randomString(10)
                    protect(heliA)
                    heli = Instance.new("AngularVelocity", h)
                    heli.Name = randomString(10)
                    protect(heli)
                    heli.Attachment0 = heliA
                    heli.MaxTorque = math.huge
                end
                -- Velocidad ligeramente variable
                local speedVar = CFG.HeliSpeed + math.random(-50, 50)
                heli.AngularVelocity = Vector3.new(0, math.rad(speedVar), 0)
            end)
            task.wait()
        end
        if heli then heli:Destroy() heli = nil end
        if heliA then heliA:Destroy() heliA = nil end
        heliRun = false
    end)
end

-- ==========================================
-- CHARACTER ADDED
-- ==========================================
conns.char = plr.CharacterAdded:Connect(function(c)
    task.wait(1)
    canDoubleJump = false
    hasDoubleJumped = false
    jumpCount = 0
    lastJumpReset = tick()
    
    if TGL.Jump then setupDoubleJump() end
    if TGL.Ragdoll then setupAntiRagdoll() end
end)

-- ==========================================
-- ANTI-AFK (STEALTH)
-- ==========================================
plr.Idled:Connect(function()
    task.defer(function()
        humanDelay(0.5, 1.5)
        V:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        V:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
    end)
end)

-- ==========================================
-- UI (CON NOMBRES RANDOM)
-- ==========================================
local G = Instance.new("ScreenGui")
G.Name = randomString(12)
G.ResetOnSpawn = false
G.Parent = plr:WaitForChild("PlayerGui")
protect(G)

local M = Instance.new("Frame", G)
M.Name = randomString(8)
M.Size = UDim2.new(0, 380, 0, 300) -- Ajustado para menos funciones
M.Position = UDim2.new(0.5, -190, 0.5, -150)
M.BackgroundColor3 = C.BG
M.BorderSizePixel = 0
protect(M)
Instance.new("UICorner", M).CornerRadius = UDim.new(0, 12)
local MS = Instance.new("UIStroke", M)
MS.Color = C.BRD
MS.Thickness = 2
MS.Transparency = 0.3

local H = Instance.new("Frame", M)
H.Name = randomString(8)
H.Size = UDim2.new(1, 0, 0, 55)
H.BackgroundColor3 = C.BG2
H.BorderSizePixel = 0
protect(H)
Instance.new("UICorner", H).CornerRadius = UDim.new(0, 12)
local HG = Instance.new("UIGradient", H)
HG.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.AC), ColorSequenceKeypoint.new(1, C.AC2)}
HG.Rotation = 45
HG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(1, 0.95)}

local TIT = Instance.new("TextLabel", H)
TIT.Size = UDim2.new(1, -70, 0, 55)
TIT.Position = UDim2.new(0, 20, 0, 0)
TIT.BackgroundTransparency = 1
TIT.Font = Enum.Font.GothamBold
TIT.Text = "🐬 DELFIN BOT V3.5"
TIT.TextSize = 22
TIT.TextColor3 = C.TXT
TIT.TextXAlignment = Enum.TextXAlignment.Left

local SUB = Instance.new("TextLabel", H)
SUB.Size = UDim2.new(1, -70, 0, 20)
SUB.Position = UDim2.new(0, 20, 0, 32)
SUB.BackgroundTransparency = 1
SUB.Font = Enum.Font.Gotham
SUB.Text = "Stealth Edition"
SUB.TextSize = 11
SUB.TextColor3 = C.DIM
SUB.TextXAlignment = Enum.TextXAlignment.Left

local MIN = Instance.new("TextButton", H)
MIN.Name = randomString(8)
MIN.Size = UDim2.new(0, 35, 0, 35)
MIN.Position = UDim2.new(1, -45, 0, 10)
MIN.BackgroundColor3 = C.OFF
MIN.TextColor3 = C.TXT
MIN.Text = "━"
MIN.Font = Enum.Font.GothamBold
MIN.TextSize = 16
protect(MIN)
Instance.new("UICorner", MIN).CornerRadius = UDim.new(0, 8)

local mini = false
MIN.MouseButton1Click:Connect(function()
    mini = not mini
    MIN.Text = mini and "+" or "━"
    T:Create(M, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = mini and UDim2.new(0, 380, 0, 65) or UDim2.new(0, 380, 0, 300)}):Play()
end)

local BF = Instance.new("Frame", M)
BF.Name = randomString(8)
BF.Size = UDim2.new(1, -20, 1, -70)
BF.Position = UDim2.new(0, 10, 0, 60)
BF.BackgroundTransparency = 1
protect(BF)

local SF = Instance.new("ScrollingFrame", BF)
SF.Name = randomString(8)
SF.Size = UDim2.new(1, 0, 1, 0)
SF.BackgroundTransparency = 1
SF.BorderSizePixel = 0
SF.ScrollBarThickness = 4
SF.ScrollBarImageColor3 = C.AC
SF.CanvasSize = UDim2.new(0, 0, 0, 200) -- Ajustado
protect(SF)

-- Draggable
local drag, dStart, sPos
M.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true
        dStart = i.Position
        sPos = M.Position
    end
end)
U.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dStart
        M.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
    end
end)
U.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)

-- ==========================================
-- THEME CHANGER
-- ==========================================
local function applyTheme(t)
    THEME = t
    C = THEMES[t]
    M.BackgroundColor3 = C.BG
    MS.Color = C.BRD
    H.BackgroundColor3 = C.BG2
    HG.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.AC), ColorSequenceKeypoint.new(1, C.AC2)}
    TIT.TextColor3 = C.TXT
    SUB.TextColor3 = C.DIM
    MIN.BackgroundColor3 = C.OFF
    MIN.TextColor3 = C.TXT
    SF.ScrollBarImageColor3 = C.AC
