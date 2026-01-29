--[[
    🐬 DelfinBot V1.5 - Transatlantis Edition
    Optimizado para evitar Rubberband y Resets
]]

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Configuración Global
_G.FlyEnabled = false
_G.SpinEnabled = false
_G.SpeedBoost = false
_G.FlySpeed = 50

-- UI BÁSICA (Asegúrate de que tus botones llamen a estas funciones)
local function notify(title, text)
    game.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
end

-- 1. TP FORWARD (El sustituto del Noclip para saltar paredes)
local function tpForward()
    local forwardDist = 12 -- Distancia segura para el servidor
    Root.CFrame = Root.CFrame * CFrame.new(0, 0, -forwardDist)
    notify("DelfinBot", "Dash ejecutado")
end

-- 2. FLY SEGURO (Usa Velocity para evitar el Reset)
local bv
task.spawn(function()
    while true do
        task.wait()
        if _G.FlyEnabled then
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Parent = Root
            end
            bv.Velocity = workspace.CurrentCamera.CFrame.LookVector * _G.FlySpeed
        else
            if bv then bv:Destroy() bv = nil end
        end
    end
end)

-- 3. SPIN (Helicoptero suave para evitar detección)
local av
task.spawn(function()
    while true do
        task.wait()
        if _G.SpinEnabled then
            if not av then
                av = Instance.new("BodyAngularVelocity")
                av.MaxTorque = Vector3.new(0, 1e6, 0)
                av.AngularVelocity = Vector3.new(0, 50, 0)
                av.Parent = Root
            end
        else
            if av then av:Destroy() av = nil end
        end
    end
end)

-- 4. INSTANT STEAL (Ajusta el nombre del RemoteEvent según tu juego)
local function instantSteal()
    -- Intentamos disparar los eventos de recolección comunes
    local remotes = game:GetDescendants()
    for _, r in pairs(remotes) do
        if r:IsA("RemoteEvent") and (r.Name:find("Steal") or r.Name:find("Collect") or r.Name:find("Grab")) then
            r:FireServer()
        end
    end
end

-- Ejemplo de Keybinds para pruebas rápidas
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.T then -- Pulsa T para saltar paredes
        tpForward()
    end
    if input.KeyCode == Enum.KeyCode.F then -- Pulsa F para volar
        _G.FlyEnabled = not _G.FlyEnabled
        notify("Fly", _G.FlyEnabled and "ON" or "OFF")
    end
end)

print("🐬 DelfinBot cargado desde Transatlantis")
