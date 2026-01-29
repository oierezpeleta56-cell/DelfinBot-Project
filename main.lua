-- [[ DELFINBOT V3.0 - FIX TOTAL ]]
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

-- Asegurarnos de borrar versiones viejas para que no se amontonen
if pgui:FindFirstChild("DelfinBotPanel") then pgui.DelfinBotPanel:Destroy() end

local sg = Instance.new("ScreenGui", pgui)
sg.Name = "DelfinBotPanel"
sg.ResetOnSpawn = false

-- Marco Principal (Estilo tu foto 2)
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 280, 0, 380)
main.Position = UDim2.new(0.5, -140, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(0, 255, 255)
stroke.Thickness = 2

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "DelfinBot Panel"
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

-- Contenedor de Botones
local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, -20, 1, -100)
container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1

local list = Instance.new("UIListLayout", container)
list.Padding = UDim.new(0, 8)
list.HorizontalAlignment = "Center"

-- Variables de Estado
local Toggles = {
    Hit = false,
    Grab = false,
    Bases = false
}

-- FUNCIÓN PARA CREAR BOTONES (CON EL "+" CIAN DE TU FOTO)
local function createButton(name, key)
    local btnFrame = Instance.new("Frame", container)
    btnFrame.Size = UDim2.new(1, 0, 0, 40)
    btnFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    
    local corner = Instance.new("UICorner", btnFrame)
    
    local txt = Instance.new("TextLabel", btnFrame)
    txt.Size = UDim2.new(1, -50, 1, 0)
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.Text = name
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 14
    txt.TextXAlignment = Enum.TextXAlignment.Center

    local circle = Instance.new("TextButton", btnFrame)
    circle.Size = UDim2.new(0, 30, 0, 30)
    circle.Position = UDim2.new(1, -35, 0.5, -15)
    circle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    circle.Text = "+"
    circle.Font = Enum.Font.GothamBold
    circle.TextSize = 18
    circle.TextColor3 = Color3.new(0,0,0)
    
    local cCorner = Instance.new("UICorner", circle)
    cCorner.CornerRadius = UDim.new(1, 0)

    circle.MouseButton1Click:Connect(function()
        Toggles[key] = not Toggles[key]
        circle.BackgroundColor3 = Toggles[key] and Color3.new(1,1,1) or Color3.fromRGB(0, 255, 255)
        circle.Text = Toggles[key] and "X" or "+"
    end)
end

-- Crear los botones que pediste
createButton("Infinite Hit (No Bat)", "Hit")
createButton("Auto Grab Items", "Grab")
createButton("Open Bases / Doors", "Bases")

-- Botón de Dash (Acción Instantánea)
local dashBtn = Instance.new("TextButton", container)
dashBtn.Size = UDim2.new(1, 0, 0, 40)
dashBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dashBtn.Text = "Dash Forward (Q)"
dashBtn.TextColor3 = Color3.new(1, 1, 1)
dashBtn.Font = Enum.Font.Gotham
Instance.new("UICorner", dashBtn)

dashBtn.MouseButton1Click:Connect(function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -15)
    end
end)

-- Botón UNLOAD (Rojo, como en tu foto)
local unload = Instance.new("TextButton", main)
unload.Size = UDim2.new(1, -20, 0, 40)
unload.Position = UDim2.new(0, 10, 1, -50)
unload.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
unload.Text = "Unload (Limpiar todo)"
unload.TextColor3 = Color3.new(1, 1, 1)
unload.Font = Enum.Font.GothamBold
Instance.new("UICorner", unload)

unload.MouseButton1Click:Connect(function() sg:Destroy() end)

-- LÓGICA DE FUNCIONAMIENTO (Lo que hace que los botones SIRVAN)
task.spawn(function()
    while task.wait(0.1) do
        -- Lógica de Hit Infinito
        if Toggles.Hit then
            pcall(function()
                -- Aquí el script busca al jugador más cercano y envía el daño
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") then
                        local dist = (v.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 15 then
                            -- Simula el golpe
                            game:GetService("ReplicatedStorage").Events.Hit:FireServer(v.Character.Humanoid) 
                        end
                    end
                end
            end)
        end
        
        -- Lógica de Auto Grab
        if Toggles.Grab then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") and (lp.Character.HumanoidRootPart.Position - v.Parent.Position).Magnitude < 15 then
                    fireproximityprompt(v)
                end
            end
        end
    end
end)
