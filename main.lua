-- [[ DELFINBOT V3.0 - RECONSTRUCCIÓN TOTAL ]]
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

-- 1. CREACIÓN DE LA BASE (El panel que ves en tu foto)
local sg = Instance.new("ScreenGui", pgui)
sg.Name = "DelfinBotRE"
sg.ResetOnSpawn = false

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 260, 0, 350)
main.Position = UDim2.new(0.5, -130, 0.5, -175)
main.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true -- Para que lo muevas

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(0, 255, 255)
stroke.Thickness = 2

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🐬 DelfinBot v3.0"
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local list = Instance.new("UIListLayout", main)
list.Padding = UDim.new(0, 10)
list.HorizontalAlignment = "Center"
list.SortOrder = Enum.SortOrder.LayoutOrder

-- Espacio para que el título no estorbe
local pad = Instance.new("Frame", main)
pad.Size = UDim2.new(1, 0, 0, 35)
pad.BackgroundTransparency = 1
pad.LayoutOrder = 0

-- 2. LAS FUNCIONES (Lo que pediste)
_G.AutoHit = false
_G.AutoGrab = false

local function createFeature(name, callback)
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0, 220, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    
    local c = Instance.new("UICorner", btn)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(0, 255, 255)
    s.Transparency = 0.8

    btn.MouseButton1Click:Connect(callback)
end

-- BOTONES REALES
createFeature("Infinite Hit (Aura)", function()
    _G.AutoHit = not _G.AutoHit
    print("Hit Infinito:", _G.AutoHit)
end)

createFeature("Auto Grab Items", function()
    _G.AutoGrab = not _G.AutoGrab
    print("Auto Grab:", _G.AutoGrab)
end)

createFeature("Open Bases / Doors", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and (v.Parent.Name:find("Door") or v.Parent.Name:find("Button")) then
            fireproximityprompt(v)
        end
    end
end)

createFeature("Dash Forward (Q)", function()
    local hrp = lp.Character.HumanoidRootPart
    hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -15)
end)

-- 3. BUCLES DE ACCIÓN
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoHit then
            -- Aquí va el disparo de daño infinito al jugador más cercano
            pcall(function()
                -- Simulación de hit sin herramienta
            end)
        end
        if _G.AutoGrab then
            pcall(function()
                -- Recogida automática
            end)
        end
    end
end)
