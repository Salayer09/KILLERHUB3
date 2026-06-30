-- ============================================================================
-- 👻 KILLER HUB | MURDER SUITE V7.0 (ANTI-LAG & ADVANCED JUKE DEFIER)
-- ============================================================================
-- Adaptado a la API V2.6.2 con Persistencia Nativa y Flags Optimizadas.

-- 1. CARGA DEL CORE ORIGINAL
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub2/refs/heads/main/Sheriff.lua"))()

-- 2. ACTIVACIÓN DEL SISTEMA DE AUTOGUARDADO PERSISTENTE (Reemplaza txt manuales)
KillerHub:EnableAutosave("KillerHub_MurderSuite.json")

-- 3. PARAMETRIZACIÓN DEL TEMA VISUAL
KillerHub:SetTheme("Blood")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera

-- Enlace dinámico con el diccionario interno de banderas de la librería
local MurderConfig = {
    SilentAim = false,
    HorizontalPred = 0.145,
    VerticalPred = 0.040,
    WallCheck = false,
    PrioritizeSheriff = false,
    ShowFOV = false,
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(0, 255, 185),
    ShowPredCircle = false,
    SmartVisibility = false
}

local MurderTab = KillerHub:CreateTab("Murder", "rbxassetid://10747372517")

local playerFysics = {}
local lastVisualPosition = Vector3.new(0, 0, 0)
local lastActualPosition = Vector3.new(0, 0, 0)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- Visualizadores Drawing API (48 lados optimizado)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 48; FOVCircle.Filled = false; FOVCircle.Visible = false 
local PredRingOuter = Drawing.new("Circle")
PredRingOuter.Radius = 6.0; PredRingOuter.Thickness = 1.2; PredRingOuter.Filled = false; PredRingOuter.Color = Color3.fromRGB(255, 35, 35); PredRingOuter.Visible = false
local PredDotCenter = Drawing.new("Circle")
PredDotCenter.Radius = 2.5; PredDotCenter.Thickness = 1; PredDotCenter.Filled = true; PredDotCenter.Color = Color3.fromRGB(255, 255, 255); PredDotCenter.Visible = false
local PredLine = Drawing.new("Line")
PredLine.Thickness = 1.0; PredLine.Color = Color3.fromRGB(185, 0, 255); PredLine.Transparency = 0.65; PredLine.Visible = false

-- Cache del cuchillo propio
local cachedHasKnife = false
local lastKnifeCheck = 0

local function hasKnifeInInventory()
    local now = os.clock()
    if now - lastKnifeCheck > 0.2 then
        lastKnifeCheck = now
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        cachedHasKnife = (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife"))
    end
    return cachedHasKnife
end

-- Función interna de escaneo rápido de arma
local function checkPlayerHasGun(player)
    local char = player.Character
    if char and char:FindFirstChild("Gun") then return true end
    local backpack = player:FindFirstChild("Backpack")
    return backpack and backpack:FindFirstChild("Gun") ~= nil
end

local function isVisibleThroughWalls(targetChar)
    if not targetChar then return false end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp or not LocalPlayer.Character then return false end
    
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar, Camera}
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, hrp.Position - Camera.CFrame.Position, raycastParams)
    
    return not (raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide)
end

-- ============================================================================
-- 🎯 SISTEMA DE MEMORIA Y FIJACIÓN DEL SHERIFF / HÉROE
-- ============================================================================
local CurrentSheriff = nil
local lastSheriffScan = 0

local function updateSheriffTarget()
    if CurrentSheriff and CurrentSheriff.Parent == Players then
        local char = CurrentSheriff.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and checkPlayerHasGun(CurrentSheriff) then
            return 
        end
    end

    local now = os.clock()
    if now - lastSheriffScan > 0.5 then
        lastSheriffScan = now
        CurrentSheriff = nil
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and checkPlayerHasGun(player) then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    CurrentSheriff = player
                    break
                end
            end
        end
    end
end

-- ============================================================================
-- 🧠 MOTOR DE SELECCIÓN INTELIGENTE CON OBJETIVO ASIGNADO
-- ============================================================================
local function getClosestTargetToFOV()
    if MurderConfig.SmartVisibility and not hasKnifeInInventory() then 
        return nil 
    end

    if MurderConfig.PrioritizeSheriff then
        updateSheriffTarget()
    else
        CurrentSheriff = nil
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if CurrentSheriff and CurrentSheriff.Character then
        local hrp = CurrentSheriff.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if distToCenter < MurderConfig.FOVRadius then
                    if not MurderConfig.WallCheck or isVisibleThroughWalls(CurrentSheriff.Character) then
                        return CurrentSheriff
                    end
                end
            end
        end
    end

    local closestInnocent = nil
    local shortestDistance = MurderConfig.FOVRadius 

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player ~= CurrentSheriff and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    
                    if distToCenter < shortestDistance then
                        if MurderConfig.WallCheck and not isVisibleThroughWalls(player.Character) then
                            continue
                        end
                        shortestDistance = distToCenter
                        closestInnocent = player
                    end
                end
            end
        end
    end

    return closestInnocent
end

-- ============================================================================
-- 🧠 MOTOR BALÍSTICO AVANZADO CALIBRADO (ANTI-FINTAS Y DETECTOR DE GHOSTING)
-- ============================================================================
local function getAdvancedKnifePrediction(targetChar)
    if not targetChar then return nil, nil end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not humanoid or not localHrp then return nil, nil end

    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    local targetPosition = hrp.Position
    local distance = (targetPosition - localHrp.Position).Magnitude
    
    local physicsData = playerFysics[targetPlayer]
    
    if physicsData and physicsData.IsLaggingOut then
        return targetPosition, targetPosition
    end

    local extentsY = targetChar:GetExtentsSize().Y
    local scaleFactor = 1.0
    if humanoid:FindFirstChild("BodyHeightScale") then scaleFactor = humanoid.BodyHeightScale.Value end

    if extentsY < 4.8 or scaleFactor < 0.85 then
        local heightDeficit = math.clamp((5.1 - extentsY) * 0.52, 0.4, 2.3)
        targetPosition = targetPosition - Vector3.new(0, heightDeficit, 0)
    end

    local smoothVelocity = Vector3.new(0, 0, 0)
    if physicsData then smoothVelocity = physicsData.SmoothedVelocity end
    if smoothVelocity.Magnitude < 0.10 then return targetPosition, targetPosition end

    local rawPing = 0.06
    if Stats and Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerToClientPing") then
        rawPing = Stats.Network.ServerToClientPing:GetValue() / 1000
    end
    local ping = math.clamp(rawPing, 0.01, 0.25)
    local travelTime = (distance / 85) + ping

    local horizontalVelocity = Vector3.new(smoothVelocity.X, 0, smoothVelocity.Z)
    local exactSpeed = horizontalVelocity.Magnitude

    local MAX_WALKSPEED = 16.715
    if exactSpeed > MAX_WALKSPEED then 
        horizontalVelocity = horizontalVelocity.Unit * MAX_WALKSPEED
        exactSpeed = MAX_WALKSPEED
    elseif exactSpeed < 2 then 
        horizontalVelocity = horizontalVelocity * (exactSpeed / 2) 
        exactSpeed = horizontalVelocity.Magnitude
    end

    local jukeFactor = 1.0
    if physicsData and physicsData.LastVelocity then
        local lastHorizVel = Vector3.new(physicsData.LastVelocity.X, 0, physicsData.LastVelocity.Z)
        local lastSpeed = lastHorizVel.Magnitude
        
        if exactSpeed > 1 and lastSpeed > 1 then
            local currentDir = horizontalVelocity.Unit
            local lastDir = lastHorizVel.Unit
            local dotProduct = currentDir:Dot(lastDir)
            
            if dotProduct < 0.94 then
                jukeFactor = math.clamp(dotProduct, 0.10, 1.0)
            end
            
            if exactSpeed < lastSpeed * 0.85 then
                local decelerationRatio = exactSpeed / lastSpeed
                jukeFactor = jukeFactor * math.clamp(decelerationRatio, 0.05, 1.0)
            end
        end
    end

    local shortRangeBoost = distance < 20 and 1.15 or 1.0
    local dynamicScale = (1.0 + (distance * 0.008)) * shortRangeBoost
    local maxElasticCap = math.clamp(distance * 0.38, 3.5, 13.5)
    
    local horizontalOffset = horizontalVelocity * (MurderConfig.HorizontalPred * 6.8) * travelTime * dynamicScale * jukeFactor

    if horizontalOffset.Magnitude > maxElasticCap then horizontalOffset = horizontalOffset.Unit * maxElasticCap end

    local verticalOffset = Vector3.new(0, 0, 0)
    local isAir = (humanoid.FloorMaterial == Enum.Material.Air)
    local absYVelocity = math.abs(smoothVelocity.Y)

    if isAir or absYVelocity > 0.05 then
        local verticalVelocity = math.clamp(smoothVelocity.Y, -18, 25)
        local verticalDistanceScale = 1 / (1 + (distance * 0.016))
        
        if isAir then
            verticalVelocity = verticalVelocity * (verticalVelocity < -1 and 0.40 or 0.70)
        else
            if verticalVelocity > 0.05 then 
                verticalVelocity = verticalVelocity * 1.65 
            end
        end
        verticalOffset = Vector3.new(0, verticalVelocity * (MurderConfig.VerticalPred * 6.0) * travelTime * verticalDistanceScale, 0)
    end

    return targetPosition, (targetPosition + horizontalOffset + verticalOffset)
end

-- ============================================================================
-- 📡 FILTRADO FÍSICO AVANZADO (RESOLUCIÓN DE GHOSTING / CONEXIÓN)
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if MurderConfig.SmartVisibility and not hasKnifeInInventory() then return end

    local currentTime = os.clock()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                local physicsVelocity = hrp.AssemblyLinearVelocity
                
                if not playerFysics[player] then
                    playerFysics[player] = { 
                        LastPos = currentPos, 
                        LastTime = currentTime, 
                        SmoothedVelocity = physicsVelocity, 
                        LastVelocity = physicsVelocity,
                        LastRawVelocity = physicsVelocity,
                        ConsecutiveSameVelocity = 0,
                        IsLaggingOut = false
                    }
                else
                    local data = playerFysics[player]
                    local deltaTime = currentTime - data.LastTime
                    
                    if deltaTime > 0 then
                        local positionalVelocity = (currentPos - data.LastPos) / deltaTime
                        local realVelocity = Vector3.new(physicsVelocity.X, positionalVelocity.Y, physicsVelocity.Z)
                        
                        if data.LastRawVelocity and (realVelocity - data.LastRawVelocity).Magnitude < 0.0001 then
                            data.ConsecutiveSameVelocity = data.ConsecutiveSameVelocity + 1
                        else
                            data.ConsecutiveSameVelocity = 0
                        end
                        
                        data.LastRawVelocity = realVelocity
                        
                        if data.ConsecutiveSameVelocity > 20 and realVelocity.Magnitude > 1 then
                            data.IsLaggingOut = true
                            realVelocity = Vector3.new(0, 0, 0)
                        else
                            data.IsLaggingOut = false
                        end
                        
                        if positionalVelocity.Magnitude > 55 then 
                            realVelocity = Vector3.new(0, 0, 0) 
                        end
                        
                        data.LastVelocity = data.SmoothedVelocity
                        data.SmoothedVelocity = data.SmoothedVelocity:Lerp(realVelocity, 0.20)
                    end
                    
                    data.LastPos = currentPos
                    data.LastTime = currentTime
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local hasKnife = hasKnifeInInventory()
    local allowRender = not MurderConfig.SmartVisibility or hasKnife

    if MurderConfig.ShowFOV and allowRender then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = MurderConfig.FOVRadius
        FOVCircle.Color = MurderConfig.FOVColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    local activeTarget = getClosestTargetToFOV()
    if MurderConfig.ShowPredCircle and allowRender and activeTarget and activeTarget.Character then
        local basePos, rawPredictedPos = getAdvancedKnifePrediction(activeTarget.Character)
        if basePos and rawPredictedPos then
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
                
                PredLine.Visible = (drawBase - drawPred).Magnitude >= 1.5
                PredDotCenter.Visible = true
                PredRingOuter.Visible = true
            else
                PredDotCenter.Visible = false; PredRingOuter.Visible = false; PredLine.Visible = false
            end
        else
            PredDotCenter.Visible = false; PredRingOuter.Visible = false; PredLine.Visible = false
        end
    else
        PredDotCenter.Visible = false; PredRingOuter.Visible = false; PredLine.Visible = false
        if activeTarget and activeTarget.Character then
            local hrp = activeTarget.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                lastActualPosition = hrp.Position
                lastVisualPosition = hrp.Position
            end
        end
    end
end)

-- ============================================================================
-- 🖥️ ESTRUCTURACIÓN DE COMPONENTES INTERFAZ GRÁFICA (V2.6.2 NATIVA)
-- ============================================================================
MurderTab:CreateSection("Ajustes de Cuchillo Lanzado")

MurderTab:CreateToggle("KnifeSilentActive", "Activar Thrown Silent Aim", false, function(estado) 
    MurderConfig.SilentAim = estado 
end)

MurderTab:CreateToggle("PrioritizeSheriffActive", "Priorizar Sheriff / Héroe", false, function(estado) 
    MurderConfig.PrioritizeSheriff = estado 
end)

MurderTab:CreateToggle("KnifeWallCheckActive", "Activar Wall Check Optimizado", false, function(estado) 
    MurderConfig.WallCheck = estado 
end)

-- Los Sliders se adaptaron a los límites lógicos requeridos por tu motor balístico
MurderTab:CreateSlider("KnifeHorizSlider", "Predicción Horizontal (Cuchillo)", 0, 300, 145, function(valor) 
    MurderConfig.HorizontalPred = valor / 1000 
end)

MurderTab:CreateSlider("KnifeVertSlider", "Predicción Vertical (Saltos/Caída)", 0, 120, 40, function(valor) 
    MurderConfig.VerticalPred = valor / 1000 
end)

MurderTab:CreateSection("Visualizadores e Interfaz Inteligente")

MurderTab:CreateToggle("ShowKnifePredictionVisual", "Mostrar Predicción Premium (Círculo Hueco)", false, function(estado) 
    MurderConfig.ShowPredCircle = estado 
end)

MurderTab:CreateToggle("SmartHandVisibility", "Visibilidad Inteligente (Solo Asesino)", false, function(estado) 
    MurderConfig.SmartVisibility = estado 
end)

MurderTab:CreateSection("Personalización del Campo de Visión (FOV)")

-- Uso de la firma exacta de CreateToggleColorPicker (Círculo RGB y Toggle acoplado)
MurderTab:CreateToggleColorPicker(
    "FovVisibleMurder", 
    "FovColorMurder", 
    "Mostrar Círculo de FOV", 
    false, 
    Color3.fromRGB(0, 255, 185), 
    function(estadoToggle) 
        MurderConfig.ShowFOV = estadoToggle 
    end, 
    function(colorSeleccionado) 
        MurderConfig.FOVColor = colorSeleccionado 
    end
)

MurderTab:CreateSlider("FovRadiusMurder", "Tamaño del FOV", 30, 600, 150, function(valor) 
    MurderConfig.FOVRadius = valor 
end)

-- ============================================================================
-- 🔗 GANCHOS SÍNCRONOS DE MEMORIA (HOOKS WEAPON SERVICE)
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
                if predictedPos then return CFrame.new(predictedPos) end
            end
        end
        return oldGetTargetPosition(self, ...)
    end

    WeaponService.GetMouseTargetCFrame = function(self, ...)
        if MurderConfig.SilentAim and hasKnifeInInventory() then
            local targetPlayer = getClosestTargetToFOV()
            if targetPlayer and targetPlayer.Character then
                local _, predictedPos = getAdvancedKnifePrediction(targetPlayer.Character)
                if predictedPos then return CFrame.new(predictedPos) end
            end
        end
        return oldGetMouseTargetCFrame(self, ...)
    end
end

-- ============================================================================
-- 🚪 RETORNO GLOBAL OBLIGATORIO PARA LA CADENA DE COMPILACIÓN
-- ============================================================================
return KillerHub
