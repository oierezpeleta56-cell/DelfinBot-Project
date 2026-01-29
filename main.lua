-- ==========================================
-- DELFINBOT V3.5 - STEALTH & WHITELIST EDITION
-- Anti-Detection + Optimized
-- ==========================================

local P = game:GetService("Players")
local plr = P.LocalPlayer

-- ==========================================
-- SISTEMA DE WHITELIST DIRECTA (ELIMINADA KEY)
-- ==========================================
local IDs_Autorizadas = {
    [9383569669] = true, -- Tu ID
    -- [OTRO_ID] = true, (Añade aquí a tus clientes de Discord)
}

if not IDs_Autorizadas[plr.UserId] then 
    warn("DelfinBot: Acceso denegado para ID " .. plr.UserId)
    return 
end

-- ==========================================
-- ANTI-DETECTION SETUP
-- ==========================================
local function protect(instance)
    if gethiddenproperty then
        pcall(function() gethiddenproperty(instance, "Name") end)
    end
    if sethiddenproperty then
        pcall(function() sethiddenproperty(instance, "Name", tostring(math.random(100000, 999999))) end)
    end
end

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
local T = game:GetService("TweenService")
local R = game:GetService("RunService")
local U = game:GetService("UserInputService")
local V = game:GetService("VirtualUser")

local CFG = {
    BatRange = 15,
    SwingSpeed = 0.4,
    HeliSpeed = 600,
    FlySpeed = 35,
    SpeedMult = 1.3,
}

local TGL = {
    Bat = false,
    Jump = false,
    Ragdoll = false,
    Heli = false,
    Fly = false,
    Boost = false,
}

local C = {
    BG = Color3.fromRGB(18, 18, 24),
    BG2 = Color3.fromRGB(25, 25, 35),
    AC = Color3.fromRGB(138, 43, 226),
    AC2 = Color3.fromRGB(0, 191, 255),
    TXT = Color3.fromRGB(240, 240, 245),
    DIM = Color3.fromRGB(160, 160, 170),
    OFF = Color3.fromRGB(35, 35, 45),
    ON = Color3.fromRGB(138, 43, 226),
    BRD = Color3.fromRGB(138, 43, 226),
}

local fly, flyA, boost, boostA, heli, heliA
local conns = {}
local canDoubleJump = false
local hasDoubleJumped = false
local humanDelays = {bat = 0, jump = 0}

-- ==========================================
-- NOTIFICACIONES (STEALTH)
-- ==========================================
local NotifFrame
local function notify(msg, dur)
    if not NotifFrame then
        NotifFrame = Instance.new("Frame")
        NotifFrame.Name = randomString(10)
        NotifFrame.Size = UDim2.new(0, 300, 0, 0)
        NotifFrame.Position = UDim2.new(1, -320, 0, 20)
        NotifFrame.BackgroundTransparency = 1
        NotifFrame.Parent = plr:WaitForChild("PlayerGui")
        protect(NotifFrame)
        local l = Instance.new("UIListLayout", NotifFrame)
        l.Padding = UDim.new(0, 10)
    end
    
    local n = Instance.new("Frame", NotifFrame)
    n.Size = UDim2.new(1, 0, 0, 50)
    n.BackgroundColor3 = C.BG2
    Instance.new("UICorner", n).CornerRadius = UDim.new(0, 8)
    
    local t = Instance.new("TextLabel", n)
    t.Size = UDim2.new(1, -20, 1, 0)
    t.Position = UDim2.new(0, 10, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.Gotham
    t.TextColor3 = C.TXT
    t.Text = msg
    
    T:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 0, 50)}):Play()
    task.delay(dur or 3, function()
        n:Destroy()
    end)
end

-- ==========================================
-- HELPERS Y FUNCIONES DE MOVIMIENTO
-- ==========================================
local function getCHH()
    local c = plr.Character or plr.CharacterAdded:Wait()
    local h = c:WaitForChild("HumanoidRootPart", 5)
    local hum = c:WaitForChild("Humanoid", 5)
    return c, h, hum
end

-- Double Jump
local function setupDoubleJump()
    if conns.jump then conns.jump:Disconnect() end
    conns.jump = U.JumpRequest:Connect(function()
        if not TGL.Jump then return end
        local char, hrp, hum = getCHH()
        if hrp and hum and (hum:GetState() == Enum.HumanoidStateType.Freefall) and canDoubleJump and not hasDoubleJumped then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 55, hrp.AssemblyLinearVelocity.Z)
            hasDoubleJumped = true
            canDoubleJump = false
        end
    end)
end

-- Anti-Ragdoll
local function setupAntiRagdoll()
    if conns.ragdoll then conns.ragdoll:Disconnect() end
    local _, _, hum = getCHH()
    conns.ragdoll = hum.StateChanged:Connect(function(_, new)
        if TGL.Ragdoll and (new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.FallingDown) then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- Helicopter Spin
local function startHeli()
    task.spawn(function()
        while TGL.Heli do
            local _, h = getCHH()
            if h then
                h.CFrame = h.CFrame * CFrame.Angles(0, math.rad(CFG.HeliSpeed/10), 0)
            end
            task.wait(0.01)
        end
    end)
end

-- ==========================================
-- UI PRINCIPAL
-- ==========================================
local G = Instance.new("ScreenGui", plr:WaitForChild("PlayerGui"))
G.Name = randomString(12)
protect(G)

local M = Instance.new("Frame", G)
M.Size = UDim2.new(0, 380, 0, 420)
M.Position = UDim2.new(0.5, -190, 0.5, -210)
M.BackgroundColor3 = C.BG
Instance.new("UICorner", M)

local TIT = Instance.new("TextLabel", M)
TIT.Size = UDim2.new(1, 0, 0, 55)
TIT.BackgroundTransparency = 1
TIT.Text = "🐬 DELFIN BOT V3.5"
TIT.Font = Enum.Font.GothamBold
TIT.TextColor3 = C.TXT
TIT.TextSize = 22

local SF = Instance.new("ScrollingFrame", M)
SF.Size = UDim2.new(1, -20, 1, -70)
SF.Position = UDim2.new(0, 10, 0, 60)
SF.BackgroundTransparency = 1
SF.ScrollBarThickness = 2

local function createTgl(name, y, key, func, emoji)
    local b = Instance.new("TextButton", SF)
    b.Text = (emoji or "●") .. "  " .. name
    b.Size = UDim2.new(0.96, 0, 0, 45)
    b.Position = UDim2.new(0.02, 0, 0, y)
    b.BackgroundColor3 = C.OFF
    b.TextColor3 = C.TXT
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        TGL[key] = not TGL[key]
        b.BackgroundColor3 = TGL[key] and C.ON or C.OFF
        if TGL[key] and func then func() end
        if key == "Jump" then setupDoubleJump() end
        if key == "Ragdoll" then setupAntiRagdoll() end
        notify(name .. (TGL[key] and " ON" or " OFF"))
    end)
end

createTgl("Auto Bat (Kill Aura)", 0, "Bat", nil, "⚔")
createTgl("Double Jump", 55, "Jump", nil, "🦘")
createTgl("Anti-Ragdoll", 110, "Ragdoll", nil, "🛡")
createTgl("Helicopter Spin", 165, "Heli", startHeli, "🚁")
createTgl("Fly Mode", 220, "Fly", nil, "✈")
createTgl("Speed Booster", 275, "Boost", nil, "🏃")

notify("✓ DelfinBot Autorizado", 3)
