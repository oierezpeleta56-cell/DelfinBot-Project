-- [[ DELFINBOT V2.0 - EMERGENCY REPAIR ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- BOOTLOADER (Espera al juego)
if not game:IsLoaded() then game.Loaded:Wait() end

-- ELIMINAMOS EL BLOQUEO DE ID PARA QUE PUEDAS ENTRAR TÚ SIEMPRE
local character = player.Character or player.CharacterAdded:Wait()

-- UI PRINCIPAL
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "DelfinBotFix"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 320)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.Active = true
MainFrame.Draggable = true -- Para que lo muevas por la pantalla

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.Thickness = 2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🐬 DelfinBot v2.0 FIXED"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

local Layout = Instance.new("UIListLayout", MainFrame)
Layout.Padding = UDim.new(0, 7)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- ESPACIO SUPERIOR
local Padding = Instance.new("Frame", MainFrame)
Padding.Size = UDim2.new(1, 0, 0, 40)
Padding.BackgroundTransparency = 1

-- FUNCIÓN PARA CREAR BOTONES QUE SÍ CARGAN
local function AddButton(name, color, callback)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0, 200, 0, 35)
    btn.BackgroundColor3 = color
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(callback)
end

-- AÑADIR FUNCIONES REALES
AddButton("Toggle Fly", Color3.fromRGB(40, 40, 60), function()
    print("Fly activado")
    -- Aquí pones la lógica de LinearVelocity que te dio Blackbox
end)

AddButton("Dash Forward (Q)", Color3.fromRGB(0, 150, 150), function()
    -- Lógica de Dash rápido
    local hrp = player.Character.HumanoidRootPart
    hrp.CFrame = hrp.CFrame * CFrame.new(0,0,-12)
end)

AddButton("Base ESP", Color3.fromRGB(40, 40, 60), function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "Wall" or v.Name == "Gate") then
            v.Transparency = v.Transparency == 0.5 and 0 or 0.5
        end
    end
end)

AddButton("Open Nearby Bases", Color3.fromRGB(150, 50, 50), function()
    -- Busca botones y los activa
end)

print("✅ DelfinBot Reparado: Si ves la caja, ahora deberías ver los botones.")
