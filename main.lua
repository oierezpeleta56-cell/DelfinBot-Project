-- [[ DELFINBOT V2.5 - CLEAN EDITION ]]
-- Se han eliminado: Autoplay, Noclip y ESP Visuals.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- 1. WHIELIST (Tu control de acceso)
local AllowedUsers = {
    [9383569669] = true, -- PON AQUÍ TU ID REAL
}

if not AllowedUsers[player.UserId] then
    warn("🐬 DelfinBot: Acceso Denegado.")
    return
end

-- 2. DASH (Para entrar en bases por fuerza)
local function doDash()
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Un impulso de 12 studs hacia adelante
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -12)
    end
end

-- 3. AUTO-GRAB (Recoger objetos automáticamente)
_G.AutoGrab = false
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoGrab and player.Character then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local dist = (obj.Parent.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 15 then
                        fireproximityprompt(obj)
                    end
                end
            end
        end
    end
end)

-- 4. INTERFAZ MODERNA (Solo lo que necesitas)
local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
sg.Name = "DelfinBotUI"

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 180, 0, 200)
frame.Position = UDim2.new(0.5, -90, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "🐬 DELFINBOT V2.5"
title.TextColor3 = Color3.new(0, 1, 1)
title.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = "Center"

-- BOTONES
local function makeBtn(txt, callback)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0, 160, 0, 35)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.MouseButton1Click:Connect(callback)
    
    local c = Instance.new("UICorner", b)
end

makeBtn("Dash (Tecla Q)", doDash)
makeBtn("Toggle Auto-Grab", function() 
    _G.AutoGrab = not _G.AutoGrab 
    print("AutoGrab:", _G.AutoGrab)
end)
makeBtn("Open All Doors", function()
    -- Lógica para disparar botones cercanos
end)

-- Configurar tecla Q para el Dash
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Q then doDash() end
end)

print("🐬 DelfinBot Limpio Cargado. Operando desde Transatlantis.")
