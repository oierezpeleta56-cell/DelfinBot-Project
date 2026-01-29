-- ==========================================
-- DELFINBOT V3.5 - STEALTH EDITION
-- Anti-Detection + Optimized
-- ==========================================

-- Sistema de clave
_G.Key = _G.Key or ""
local VALID_KEY = "exploiter"

if _G.Key ~= VALID_KEY then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🚫 Acceso Denegado",
        Text = "Clave incorrecta. Usa: _G.Key = 'exploiter'",
        Duration = 5
    })
    return
end

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

local plr = P.LocalPlayer
local IDs = {[9383569669] = true}
if not IDs[plr.UserId] then return end

local TARGET = "brainrots"
local CFG = {
    BatRange = 15,
    SwingSpeed = 0.4, -- Más lento para parecer humano
    HeliSpeed = 600, -- Menos agresivo
    FlySpeed = 35, -- Más lento para evitar detección
    SpeedMult = 1.3, -- Menos obvio
}

local TGL = {
    Bat = false,
    Jump = false,
    Ragdoll = false,
    Heli = false,
    Fly = false,
    Boost = false,
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

local fly, flyA, boost, boostA, heli, heliA
local conns = {}
local canDoubleJump = false
local hasDoubleJumped = false

-- Variables para comportamiento humano
local lastActionTime = {}
local humanDelays = {
    bat = 0,
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

local function getBat()
    local c = plr.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("bat") then return t end
        end
    end
    local b = plr:FindFirstChildOfClass("Backpack")
    if b then
        for _, t in ipairs(b:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("bat") then return t end
        end
    end
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
-- AUTO BAT (STEALTH + COMPORTAMIENTO HUMANO)
-- ==========================================
local batRun = false
local consecutiveSwings = 0

local function startBat()
    if batRun then return end
    batRun = true
    
    task.spawn(function()
        while TGL.Bat do
            pcall(function()
                local c, h = getCHH()
                local bat = getBat()
                
                if bat then
                    -- Equipar con retraso humano
                    if bat.Parent ~= c then
                        humanDelay(0.1, 0.3)
                        bat.Parent = c
                    end
                    
                    -- Limitar swings consecutivos (comportamiento humano)
                    if consecutiveSwings > 5 then
                        humanDelay(1, 2) -- Pausa después de muchos swings
                        consecutiveSwings = 0
                    end
                    
                    bat:Activate()
                    consecutiveSwings = consecutiveSwings + 1
                end
            end)
            
            -- Tiempo variable entre swings (más humano)
            humanDelay(CFG.SwingSpeed * 0.8, CFG.SwingSpeed * 1.2)
        end
        batRun = false
        consecutiveSwings = 0
    end)
end

-- ==========================================
-- HELICOPTER (STEALTH)
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
-- FLY (STEALTH)
-- ==========================================
local flyRun = false
local function startFly()
    if flyRun then return end
    flyRun = true
    
    task.spawn(function()
        local _, h, hum = getCHH()
        task.defer(function()
            humanDelay(0.1, 0.2)
            if hum then hum.PlatformStand = true end
        end)
        
        if not fly then
            flyA = Instance.new("Attachment", h)
            flyA.Name = randomString(10)
            protect(flyA)
            fly = Instance.new("LinearVelocity", h)
            fly.Name = randomString(10)
            protect(fly)
            fly.Attachment0 = flyA
            fly.MaxForce = math.huge
        end
        
        while TGL.Fly do
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                
                local m = Vector3.new()
                if U:IsKeyDown(Enum.KeyCode.W) then m = m + cam.CFrame.LookVector end
                if U:IsKeyDown(Enum.KeyCode.S) then m = m - cam.CFrame.LookVector end
                if U:IsKeyDown(Enum.KeyCode.A) then m = m - cam.CFrame.RightVector end
                if U:IsKeyDown(Enum.KeyCode.D) then m = m + cam.CFrame.RightVector end
                if U:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0, 1, 0) end
                if U:IsKeyDown(Enum.KeyCode.LeftControl) then m = m - Vector3.new(0, 1, 0) end
                
                -- Velocidad con ligera variación
                local speed = CFG.FlySpeed + math.random(-2, 2)
                fly.VectorVelocity = m.Magnitude > 0 and m.Unit * speed or Vector3.zero
            end)
            R.Heartbeat:Wait()
        end
        
        if fly then fly:Destroy() fly = nil end
        if flyA then flyA:Destroy() flyA = nil end
        if hum then 
            task.defer(function()
                humanDelay(0.1, 0.2)
                if hum.Parent then hum.PlatformStand = false end
            end)
        end
        flyRun = false
    end)
end

-- ==========================================
-- BOOSTER (STEALTH)
-- ==========================================
local boostRun = false
local function startBoost()
    if boostRun then return end
    boostRun = true
    
    task.spawn(function()
        if not boost then
            boostA = Instance.new("Attachment")
            boostA.Name = randomString(10)
            protect(boostA)
            boost = Instance.new("LinearVelocity")
            boost.Name = randomString(10)
            protect(boost)
            boost.MaxForce = math.huge
        end
        
        while TGL.Boost do
            pcall(function()
                local _, h, hum = getCHH()
                if boostA.Parent ~= h then
                    boostA.Parent = h
                    boost.Parent = h
                    boost.Attachment0 = boostA
                end
                
                local m = hum.MoveDirection
                -- Multiplicador con variación para parecer natural
                local mult = CFG.SpeedMult + (math.random(-10, 10) / 100)
                boost.VectorVelocity = m.Magnitude > 0 and m.Unit * hum.WalkSpeed * mult or Vector3.zero
            end)
            R.Heartbeat:Wait()
        end
        
        if boost then boost:Destroy() boost = nil end
        if boostA then boostA:Destroy() boostA = nil end
        boostRun = false
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
M.Size = UDim2.new(0, 380, 0, 420)
M.Position = UDim2.new(0.5, -190, 0.5, -210)
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
    T:Create(M, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = mini and UDim2.new(0, 380, 0, 65) or UDim2.new(0, 380, 0, 420)}):Play()
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
SF.CanvasSize = UDim2.new(0, 0, 0, 420)
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
    
    for _, btn in ipairs(SF:GetChildren()) do
        if btn:IsA("TextButton") and btn.Name:find("TGL") then
            local k = btn:GetAttribute("K")
            btn.BackgroundColor3 = TGL[k] and C.ON or C.OFF
            btn.TextColor3 = C.TXT
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then s.Color = C.BRD end
        end
    end
    notify("🎨 Tema: " .. t, 2)
end

-- ==========================================
-- BUTTONS
-- ==========================================
local function createTgl(name, y, key, func, emoji)
    local b = Instance.new("TextButton", SF)
    b.Name = "TGL_" .. randomString(5)
    b.Text = (emoji or "●") .. "  " .. name
    b.Size = UDim2.new(0.96, 0, 0, 45)
    b.Position = UDim2.new(0.02, 0, 0, y)
    b.BackgroundColor3 = C.OFF
    b.TextColor3 = C.TXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b:SetAttribute("K", key)
    protect(b)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", b)
    s.Color = C.BRD
    s.Thickness = 1.5
    s.Transparency = 0.7
    
    local function upd()
        T:Create(b, TweenInfo.new(0.3), {BackgroundColor3 = TGL[key] and C.ON or C.OFF}):Play()
        T:Create(s, TweenInfo.new(0.3), {Transparency = TGL[key] and 0.2 or 0.7}):Play()
    end
    
    b.MouseButton1Click:Connect(function()
        TGL[key] = not TGL[key]
        upd()
        if TGL[key] and func then func() end
        if key == "Jump" then setupDoubleJump() end
        if key == "Ragdoll" then setupAntiRagdoll() end
        notify(name .. (TGL[key] and " ✓" or " ✗"), 2)
    end)
    upd()
end

local y, s = 5, 55
createTgl("Auto Bat (Kill Aura)", y + s * 0, "Bat", startBat, "⚔")
createTgl("Double Jump", y + s * 1, "Jump", nil, "🦘")
createTgl("Anti-Ragdoll", y + s * 2, "Ragdoll", nil, "🛡")
createTgl("Helicopter Spin", y + s * 3, "Heli", startHeli, "🚁")
createTgl("Fly Mode", y + s * 4, "Fly", startFly, "✈")
createTgl("Speed Booster", y + s * 5, "Boost", startBoost, "🏃")

-- Theme Button
local TB = Instance.new("TextButton", SF)
TB.Name = randomString(8)
TB.Text = "🎨  Cambiar Tema"
TB.Size = UDim2.new(0.96, 0, 0, 45)
TB.Position = UDim2.new(0.02, 0, 0, y + s * 6)
TB.BackgroundColor3 = C.AC
TB.TextColor3 = C.TXT
TB.Font = Enum.Font.GothamBold
TB.TextSize = 13
protect(TB)
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)
TB.MouseButton1Click:Connect(function() applyTheme(THEME == "Cyan" and "Red" or "Cyan") end)

-- Unload Button
local UB = Instance.new("TextButton", SF)
UB.Name = randomString(8)
UB.Text = "🗑  Unload"
UB.Size = UDim2.new(0.96, 0, 0, 45)
UB.Position = UDim2.new(0.02, 0, 0, y + s * 7)
UB.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
UB.TextColor3 = C.TXT
UB.Font = Enum.Font.GothamBold
UB.TextSize = 14
protect(UB)
Instance.new("UICorner", UB).CornerRadius = UDim.new(0, 10)
UB.MouseButton1Click:Connect(function()
    for k in pairs(TGL) do TGL[k] = false end
    for _, v in pairs(conns) do if v then v:Disconnect() end end
    if fly then fly:Destroy() end
    if flyA then flyA:Destroy() end
    if boost then boost:Destroy() end
    if boostA then boostA:Destroy() end
    if heli then heli:Destroy() end
    if heliA then heliA:Destroy() end
    G:Destroy()
    notify("👋 Descargado", 3)
end)

-- ==========================================
-- INIT
-- ==========================================
notify("✓ Cargado (Stealth Mode)", 2)

U.InputBegan:Connect(function(i, g)
    if g or i.KeyCode ~= Enum.KeyCode.RightControl then return end
    local h = M.Position.Y.Scale > 0.9
    T:Create(M, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = h and UDim2.new(0.5, -190, 0.5, -210) or UDim2.new(0.5, -190, 1.2, 0)}):Play()
end)
