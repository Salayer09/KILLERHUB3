-- ============================================================================
-- 👻 KILLER HUB | MURDER SUITE V6.5 (KINETIC CALIBRATOR - FIXED BALISTICS)
-- ============================================================================
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub2/refs/heads/main/Sheriff.lua"))()

-- 1. CREACIÓN DE LA PESTAÑA MURDER
MurderTab = KillerHub:CreateTab("Murder", "rbxassetid://10747372517")

-- 2. CONFIGURACIÓN SÓLIDA DEL MOTOR MURDER
local MurderConfig = {
    SilentAim = false,
    HorizontalPred = 0.145,
    VerticalPred = 0.040,
    WallCheck = false,
    
    -- Ajustes del FOV y Visualizadores
    ShowFOV = false,
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(0, 255, 185),
    
    ShowPredCircle = false,
    SmartVisibility = false
}

-- Servicios Esenciales de Roblox
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera

-- Tablas de memoria global para suavizado físico
local playerFysics = {}
local lastVisualPosition = Vector3.new(0, 0, 0)
local lastActualPosition = Vector3.new(0, 0, 0)

-- Configuración para el Raycast del Wall Check
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- ============================================================================
-- ⭕ VISUALIZADORES PREMIUM REDISEÑADOS (DRAWING API)
-- ============================================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Visible = false 

-- Círculo Exterior Hueco Compacto Elegante (Radio 6.0)
local PredRingOuter = Drawing.new("Circle")
PredRingOuter.Radius = 6.0
PredRingOuter.Thickness = 1.2
PredRingOuter.Filled = false
PredRingOuter.Color = Color3.fromRGB(255, 35, 35)
PredRingOuter.Visible = false

-- Centro de Enfoque Blanco Ampliado
local PredDotCenter = Drawing.new("Circle")
PredDotCenter.Radius = 2.5
PredDotCenter.Thickness = 1
PredDotCenter.Filled = true
PredDotCenter.Color = Color3.fromRGB(255, 255, 255)
PredDotCenter.Visible = false

-- El Hilo Morado de Inercia Elástica
local PredLine = Drawing.new("Line")
PredLine.Thickness = 1.0
PredLine.Color = Color3.fromRGB(185, 0, 255)
PredLine.Transparency = 0.65
PredLine.Visible = false

-- ============================================================================
-- 🧠 MOTOR BALÍSTICO RE-CALIBRADO (LINEAL Y EXACTO)
-- ============================================================================

local function hasKnifeInInventory()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    return (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife"))
end

local function isVisibleThroughWalls(targetChar)
    if not targetChar then return false end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp or not LocalPlayer.Character then return false end
    
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar, Camera}
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, hrp.Position - Camera.CFrame.Position, raycastParams)
    
    if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
        return false 
    end
    return true
end

local function getClosestTargetToFOV()
    local closestPlayer = nil
    local shortestDistance = MurderConfig.FOVRadius 
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                if MurderConfig.WallCheck and not isVisibleThroughWalls(player.Character) then
                    continue
                end

                local hrp = player.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distToCenter < shortestDistance then
                        shortestDistance = distToCenter
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Algoritmo Balístico v6.5 (Ecuación Lineal Corregida)
local function getAdvancedKnifePrediction(targetChar)
    if not targetChar then return nil, nil end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not humanoid or not localHrp then return nil, nil end

    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    local targetPosition = hrp.Position
    local distance = (targetPosition - localHrp.Position).Magnitude
    
    -- Compensación de avatares pequeños (Filtro Enano)
    local extentsY = targetChar:GetExtentsSize().Y
    local scaleFactor = 1.0
    if humanoid:FindFirstChild("BodyHeightScale") then
        scaleFactor = humanoid.BodyHeightScale.Value
    end

    if extentsY < 4.8 or scaleFactor < 0.85 then
        local heightDeficit = math.clamp((5.1 - extentsY) * 0.52, 0.4, 2.3)
        targetPosition = targetPosition - Vector3.new(0, heightDeficit, 0)
    end

    -- Extraer el vector de velocidad suavizado
    local smoothVelocity = Vector3.new(0, 0, 0)
    if targetPlayer and playerFysics[targetPlayer] then
        smoothVelocity = playerFysics[targetPlayer].SmoothedVelocity
    end

    if smoothVelocity.Magnitude < 0.15 then return targetPosition, targetPosition end

    -- Cálculo de latencia y tiempo de viaje (Cuchillo MM2 ~85 studs/s)
    local rawPing = 0.06
    if Stats and Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerToClientPing") then
        rawPing = Stats.Network.ServerToClientPing:GetValue() / 1000
    end
    local ping = math.clamp(rawPing, 0.01, 0.25)
    local travelTime = (distance / 85) + ping

    -- ========================================================================
    -- 📊 CORRECCIÓN MATEMÁTICA: PREDICCIÓN LINEAL EQUILIBRADA
    -- ========================================================================
    local horizontalVelocity = Vector3.new(smoothVelocity.X, 0, smoothVelocity.Z)
    local exactSpeed = horizontalVelocity.Magnitude

    -- Escudo Anti-Exploits (Speedhack/Fly) capado firmemente
    if exactSpeed > 42 then
        horizontalVelocity = horizontalVelocity.Unit * 42
    elseif exactSpeed < 4 then
        horizontalVelocity = horizontalVelocity * (exactSpeed / 4)
    end

    -- Boost moderado de corta distancia (Para evitar que te esquiven girando cerca)
    local shortRangeBoost = 1.0
    if distance < 20 then
        shortRangeBoost = 1.15
    end

    -- NUEVA ESCALA ADAPTATIVA SUAVE (Eliminado el multiplicador cuadrático de velocidad)
    local dynamicScale = (1.0 + (distance * 0.008)) * shortRangeBoost

    -- Tope elástico máximo blindado (Evita por completo que exagere a larga distancia)
    local maxElasticCap = math.clamp(distance * 0.38, 3.5, 13.5)

    -- Aplicación del desplazamiento horizontal (Ajustado el multiplicador base a un valor óptimo)
    local horizontalOffset = horizontalVelocity * (MurderConfig.HorizontalPred * 6.8) * travelTime * dynamicScale

    if horizontalOffset.Magnitude > maxElasticCap then
        horizontalOffset = horizontalOffset.Unit * maxElasticCap
    end

    -- Control balístico vertical (Saltos y caídas normales)
    local verticalOffset = Vector3.new(0, 0, 0)
    if humanoid.FloorMaterial == Enum.Material.Air or math.abs(smoothVelocity.Y) > 0.4 then
        local verticalVelocity = math.clamp(smoothVelocity.Y, -16, 16)
        if verticalVelocity > 22 then verticalVelocity = 22 end
        
        local verticalDistanceScale = 1 / (1 + (distance * 0.020)) 
        
        if verticalVelocity < -1 then
            verticalVelocity = verticalVelocity * 0.40
        else
            verticalVelocity = verticalVelocity * 0.70
        end
        
        verticalOffset = Vector3.new(0, verticalVelocity * (MurderConfig.VerticalPred * 5.5) * travelTime * verticalDistanceScale, 0)
    end

    return targetPosition, (targetPosition + horizontalOffset + verticalOffset)
end

-- ============================================================================
-- 📡 MONITOR DE FILTRADO SÍNCRONO (INERTIAL BUFFER)
-- ============================================================================
RunService.Heartbeat:Connect(function()
    local currentTime = os.clock()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local currentPos = hrp.Position
            local physicsVelocity = hrp.AssemblyLinearVelocity
            
            if not playerFysics[player] then
                playerFysics[player] = {
                    LastPos = currentPos,
                    LastTime = currentTime,
                    SmoothedVelocity = physicsVelocity
                }
            else
                local data = playerFysics[player]
                local deltaTime = currentTime - data.LastTime
                
                local actualSpeed = 0
                if deltaTime > 0 then
                    actualSpeed = (currentPos - data.LastPos).Magnitude / deltaTime
                end
                
                local finalVelocity = physicsVelocity
                if physicsVelocity.Magnitude > 4.5 and actualSpeed < 1.8 then
                    finalVelocity = Vector3.new(0, 0, 0)
                end
                
                data.SmoothedVelocity = data.SmoothedVelocity:Lerp(finalVelocity, 0.18)
                
                data.LastPos = currentPos
                data.LastTime = currentTime
            end
        end
    end
end)

-- ============================================================================
-- 🔄 BUCLE RENDERSTEPPED: EFECTO HILO ELÁSTICO PREMIUM PERFECCIONADO
-- ============================================================================
RunService.RenderStepped:Connect(function()
    local hasKnife = hasKnifeInInventory()
    
    local allowRender = false
    if MurderConfig.SmartVisibility then
        allowRender = hasKnife
    else
        allowRender = true
    end

    -- 1. Renderizado del Círculo del FOV
    if MurderConfig.ShowFOV and allowRender then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = MurderConfig.FOVRadius
        FOVCircle.Color = MurderConfig.FOVColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- 2. Renderizado de la Mira Calibrada y el Hilo de Arrastre
    local activeTarget = getClosestTargetToFOV()
    if MurderConfig.ShowPredCircle and allowRender and activeTarget and activeTarget.Character then
        local basePos, rawPredictedPos = getAdvancedKnifePrediction(activeTarget.Character)
        
        if basePos and rawPredictedPos then
            -- Interpolación suave
            lastActualPosition = lastActualPosition:Lerp(basePos, 0.28)
            lastVisualPosition = lastVisualPosition:Lerp(rawPredictedPos, 0.28)
            
            local screenPosBase, onScreenBase = Camera:WorldToViewportPoint(lastActualPosition)
            local screenPosPred, onScreenPred = Camera:WorldToViewportPoint(lastVisualPosition)
            
            if onScreenBase and onScreenPred then
                local drawBase = Vector2.new(screenPosBase.X, screenPosBase.Y)
                local drawPred = Vector2.new(screenPosPred.X, screenPosPred.Y)
                
                PredDotCenter.Position = drawBase
                PredRingOuter.Position = drawPred
                
                PredLine.From = drawBase
                PredLine.To = drawPred
                
                -- Ocultar el hilo elástico si el rival se detiene por completo
                if (drawBase - drawPred).Magnitude < 1.5 then
                    PredLine.Visible = false
                else
                    PredLine.Visible = true
                end
                
                PredDotCenter.Visible = true
                PredRingOuter.Visible = true
            else
                PredDotCenter.Visible = false PredRingOuter.Visible = false PredLine.Visible = false
            end
        else
            PredDotCenter.Visible = false PredRingOuter.Visible = false PredLine.Visible = false
        end
    else
        PredDotCenter.Visible = false PredRingOuter.Visible = false PredLine.Visible = false
        if activeTarget and activeTarget.Character and activeTarget.Character:FindFirstChild("HumanoidRootPart") then
            local currentHrpPos = activeTarget.Character.HumanoidRootPart.Position
            lastActualPosition = currentHrpPos
            lastVisualPosition = currentHrpPos
        end
    end
end)

-- ============================================================================
-- ⚙️ INTERFAZ GRÁFICA INYECTADA EN LA PESTAÑA
-- ============================================================================
MurderTab:CreateSection("Ajustes de Cuchillo Lanzado")

MurderTab:CreateToggle("KnifeSilentActive", "Activar Thrown Silent Aim", function(estado)
    MurderConfig.SilentAim = estado
end)

MurderTab:CreateToggle("KnifeWallCheckActive", "Activar Wall Check Optimizado", function(estado)
    MurderConfig.WallCheck = estado
end)

MurderTab:CreateSlider("KnifeHorizSlider", "Predicción Horizontal (Cuchillo)", 0, 300, function(valor)
    MurderConfig.HorizontalPred = valor / 1000
end)

MurderTab:CreateSlider("KnifeVertSlider", "Predicción Vertical (Saltos/Caída)", 0, 120, function(valor)
    MurderConfig.VerticalPred = valor / 1000
end)

MurderTab:CreateSection("Visualizadores e Interfaz Inteligente")

MurderTab:CreateToggle("ShowKnifePredictionVisual", "Mostrar Predicción Premium (Círculo Hueco)", function(estado)
    MurderConfig.ShowPredCircle = estado
end)

MurderTab:CreateToggle("SmartHandVisibility", "Visibilidad Inteligente (Solo Asesino)", function(estado)
    MurderConfig.SmartVisibility = estado
end)

MurderTab:CreateSection("Personalización del Campo de Visión (FOV)")

MurderTab:CreateToggleColorPicker(
    "FovVisibleMurder", 
    "FovColorMurder", 
    "Mostrar Círculo de FOV", 
    MurderConfig.FOVColor, 
    function(estadoToggle)
        MurderConfig.ShowFOV = estadoToggle
    end,
    function(colorSeleccionado)
        MurderConfig.FOVColor = colorSeleccionado
    end
)

MurderTab:CreateSlider("FovRadiusMurder", "Tamaño del FOV", 30, 600, function(valor)
    MurderConfig.FOVRadius = valor
end)

-- ============================================================================
-- 📡 ENCADENAMIENTO DE HOOKS (SÍNCRONO CON WEAPONSERVICE)
-- ============================================================================
local ClientServices = ReplicatedStorage:WaitForChild("ClientServices", 5)
if ClientServices then
    local WeaponService = require(ClientServices:WaitForChild("WeaponService"))
    local oldGetTargetPosition = WeaponService.GetTargetPosition
    local oldGetMouseTargetCFrame = WeaponService.GetMouseTargetCFrame

    WeaponService.GetTargetPosition = function(self, ...)
        if MurderConfig.SilentAim and hasKnifeInInventory() then
            local targetPlayer = getClosestTargetToFOV()
            if targetPlayer and targetPlayer.Character then
                local _, predictedPos = getAdvancedKnifePrediction(targetPlayer.Character)
                if predictedPos then 
                    return CFrame.new(predictedPos) 
                end
            end
        end
        return oldGetTargetPosition(self, ...)
    end

    WeaponService.GetMouseTargetCFrame = function(self, ...)
        if MurderConfig.SilentAim and hasKnifeInInventory() then
            local targetPlayer = getClosestTargetToFOV()
            if targetPlayer and targetPlayer.Character then
                local _, predictedPos = getAdvancedKnifePrediction(targetPlayer.Character)
                if predictedPos then 
                    return CFrame.new(predictedPos) 
                end
            end
        end
        return oldGetMouseTargetCFrame(self, ...)
    end
end

return KillerHub
