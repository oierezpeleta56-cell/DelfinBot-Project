-- [[ DELFINBOT V3.1 - REPARACIÓN DE FUNCIONES ]]
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

-- Limpieza de versiones fallidas
if pgui:FindFirstChild("DelfinBotPanel") then pgui.DelfinBotPanel:Destroy() end

local sg = Instance.new("ScreenGui", pgui)
sg.Name = "DelfinBotPanel"
sg.ResetOnSpawn = false

-- MARCO PRINCIPAL
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 280, 0, 380)
main.Position = UDim2.new(0.5, -140, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
main.Active = true
main.Draggable = true

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(0, 255, 255)
stroke.Thickness = 2

-- TÍTULO
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🐬 DelfinBot v3.1 (FIXED)"
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16

-- VARIABLES DE ESTADO GLOBALES (Para que no fallen)
_G.DelfinHit = false
_G.DelfinGrab = false

-- FUNCIÓN DE BOTÓN QUE SÍ RESPONDE
local function createToggle(name, yPos, globalVar)
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(1, -20, 0, 45)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = name .. " [OFF]"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        _G[globalVar] = not _G[globalVar]
        btn.Text = name .. (_G[globalVar] and " [ON]" or " [OFF]")
        btn.BackgroundColor3 = _G[globalVar] and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(40, 40, 45)
        print("🐬 Botón pulsado: " .. name .. " ahora está " .. tostring(_G[globalVar]))
    end)
end

-- CREACIÓN MANUAL (Sin contenedores que puedan fallar)
createToggle("Infinite Hit", 60, "DelfinHit")
createToggle("Auto Grab", 115, "DelfinGrab")

-- BOTÓN DASH INSTANTÁNEO
local dash = Instance.new("TextButton", main)
dash.Size = UDim2.new(1, -20, 0, 45)
dash.Position = UDim2.new(0, 10, 0, 170)
dash.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
dash.Text = "Dash Forward (Q)"
dash.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", dash)

local function executeDash()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -15)
    end
end

dash.MouseButton1Click:Connect(executeDash)
game:GetService("UserInputService").InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.Q then executeDash() end
end)

-- BUCLE DE EJECUCIÓN (El motor del script)
task.spawn(function()
    while task.wait(0.1) do
        if _G.DelfinGrab then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local char = lp.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        if (v.Parent.Position - char.HumanoidRootPart.Position).Magnitude < 20 then
                            fireproximityprompt(v)
                        end
                    end
                end
            end
        end
        
        if _G.DelfinHit then
            -- Intenta activar la herramienta que tengas en la mano
            local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
    end
end)
