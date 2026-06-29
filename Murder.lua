-- ============================================================================
-- 👻 KILLER HUB | MURDER SUITE V6.8 (EVENT-DRIVEN SHERIFF TRACKER)
-- ============================================================================
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub2/main/Sheriff.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

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

local CONFIG_FILE = "KillerHub_MurderSuite.txt"

local function saveConfig()
    if writefile then
        local data = {
            SilentAim = MurderConfig.SilentAim,
            HorizontalPred = MurderConfig.HorizontalPred,
            VerticalPred = MurderConfig.VerticalPred,
            WallCheck = MurderConfig.WallCheck,
            PrioritizeSheriff = MurderConfig.PrioritizeSheriff,
            ShowFOV = MurderConfig.ShowFOV,
            FOVRadius = MurderConfig.FOVRadius,
            ShowPredCircle = MurderConfig.ShowPredCircle,
            SmartVisibility = MurderConfig.SmartVisibility,
            FOVColor = {MurderConfig.FOVColor.R, MurderConfig.FOVColor.G, MurderConfig.FOVColor.B}
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end
end

local function loadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and decoded then
            if decoded.SilentAim ~= nil then MurderConfig.SilentAim = decoded.SilentAim end
            if decoded.HorizontalPred ~= nil then MurderConfig.HorizontalPred = decoded.HorizontalPred end
            if decoded.VerticalPred ~= nil then MurderConfig.VerticalPred = decoded.VerticalPred end
            if decoded.WallCheck ~= nil then MurderConfig.WallCheck = decoded.WallCheck end
            if decoded.PrioritizeSheriff ~= nil then MurderConfig.PrioritizeSheriff = decoded.PrioritizeSheriff end
            if decoded.ShowFOV ~= nil then MurderConfig.ShowFOV = decoded.ShowFOV end
            if decoded.FOVRadius ~= nil then MurderConfig.FOVRadius = decoded.FOVRadius end
            if decoded.ShowPredCircle ~= nil then MurderConfig.ShowPredCircle = decoded.ShowPredCircle end
            if decoded.SmartVisibility ~= nil then MurderConfig.SmartVisibility = decoded.SmartVisibility end
            if decoded.FOVColor ~= nil then
                MurderConfig.FOVColor = Color3.new(decoded.FOVColor[1], decoded.FOVColor[2], decoded.FOVColor[3])
            end
        end
    end
end

loadConfig()

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
    -- Si ya hay un Sheriff fijado, verificamos de forma ultra rápida si sigue vivo y con el arma
    if CurrentSheriff and CurrentSheriff.Parent == Players then
        local char = CurrentSheriff.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and checkPlayerHasGun(CurrentSheriff) then
            return -- El Sheriff actual sigue siendo válido, no busques más.
        end
    end

    -- Si no hay Sheriff o el que estaba murió/tiró el arma, hacemos un escaneo pasivo controlado (cada 0.5 seg)
    local now = os.clock()
    if now - lastSheriffScan > 0.5 then
        lastSheriffScan = now
        CurrentSheriff = nil -- Limpiar datos anteriores
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and checkPlayerHasGun(player) then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    CurrentSheriff = player -- ✨ Nuevo Sheriff memorizado
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

    -- Actualizar el estado del Sheriff en memoria
    if MurderConfig.PrioritizeSheriff then
        updateSheriffTarget()
    else
        CurrentSheriff = nil
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- 🥇 PASO 1: Si hay un Sheriff válido en memoria, intentamos apuntarle directamente
    if CurrentSheriff and CurrentSheriff.Character then
        local hrp = CurrentSheriff.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if distToCenter < MurderConfig.FOVRadius then
                    -- Si pasa el Wall Check (o está desactivado), es el objetivo absoluto
                    if not MurderConfig.WallCheck or isVisibleThroughWalls(CurrentSheriff.Character) then
                        return CurrentSheriff
                    end
                    -- Si NO pasa el Wall Check por estar escondido, el código continúa hacia los inocentes...
                end
            end
        end
    end

    -- 🥈 PASO 2: Si no hay Sheriff, si está muerto, o si se escondió detrás de una pared, buscamos al Inocente más cercano
    local closestInnocent = nil
    local shortestDistance = MurderConfig.FOVRadius 

    for _, player in ipairs(Players:GetPlayers()) do
        -- Ignorar al jugador local y al Sheriff actual (si ya fue procesado arriba)
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

-- (El motor predictivo balístico se mantiene idéntico...)
local function getAdvancedKnifePrediction(targetChar)
    if not targetChar then return nil, nil end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not humanoid or not localHrp then return nil, nil end

    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    local targetPosition = hrp.Position
    local distance = (targetPosition - localHrp.Position).Magnitude
    
    local extentsY = targetChar:GetExtentsSize().Y
    local scaleFactor = 1.0
    if humanoid:FindFirstChild("BodyHeightScale") then scaleFactor = humanoid.BodyHeightScale.Value end

    if extentsY < 4.8 or scaleFactor < 0.85 then
        local heightDeficit = math.clamp((5.1 - extentsY) * 0.52, 0.4, 2.3)
        targetPosition = targetPosition - Vector3.new(0, heightDeficit, 0)
    end

    local smoothVelocity = Vector3.new(0, 0, 0)
    if targetPlayer and playerFysics[targetPlayer] then smoothVelocity = playerFysics[targetPlayer].SmoothedVelocity end
    if smoothVelocity.Magnitude < 0.15 then return targetPosition, targetPosition end

    local rawPing = 0.06
    if Stats and Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerToClientPing") then
        rawPing = Stats.Network.ServerToClientPing:GetValue() / 1000
    end
    local ping = math.clamp(rawPing, 0.01, 0.25)
    local travelTime = (distance / 85) + ping

    local horizontalVelocity = Vector3.new(smoothVelocity.X, 0, smoothVelocity.Z)
    local exactSpeed = horizontalVelocity.Magnitude

    if exactSpeed > 42 then horizontalVelocity = horizontalVelocity.Unit * 42
    elseif exactSpeed < 4 then horizontalVelocity = horizontalVelocity * (exactSpeed / 4) end

    local shortRangeBoost = distance < 20 and 1.15 or 1.0
    local dynamicScale = (1.0 + (distance * 0.008)) * shortRangeBoost
    local maxElasticCap = math.clamp(distance * 0.38, 3.5, 13.5)
    local horizontalOffset = horizontalVelocity * (MurderConfig.HorizontalPred * 6.8) * travelTime * dynamicScale

    if horizontalOffset.Magnitude > maxElasticCap then horizontalOffset = horizontalOffset.Unit * maxElasticCap end

    local verticalOffset = Vector3.new(0, 0, 0)
    local isAir = (humanoid.FloorMaterial == Enum.Material.Air)
    local absYVelocity = math.abs(smoothVelocity.Y)

    if isAir or absYVelocity > 0.15 then
        local verticalVelocity = math.clamp(smoothVelocity.Y, -16, 22)
        local verticalDistanceScale = 1 / (1 + (distance * 0.018))
        if isAir then
            verticalVelocity = verticalVelocity * (verticalVelocity < -1 and 0.40 or 0.70)
        else
            if verticalVelocity > 0.15 then verticalVelocity = verticalVelocity * 1.45 end
        end
        verticalOffset = Vector3.new(0, verticalVelocity * (MurderConfig.VerticalPred * 5.5) * travelTime * verticalDistanceScale, 0)
    end

    return targetPosition, (targetPosition + horizontalOffset + verticalOffset)
end

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
                    playerFysics[player] = { LastPos = currentPos, LastTime = currentTime, SmoothedVelocity = physicsVelocity }
                else
                    local data = playerFysics[player]
                    local deltaTime = currentTime - data.LastTime
                    local actualSpeed = deltaTime > 0 and (currentPos - data.LastPos).Magnitude / deltaTime or 0
                    local finalVelocity = physicsVelocity
                    if physicsVelocity.Magnitude > 4.5 and actualSpeed < 1.8 then finalVelocity = Vector3.new(0, 0, 0) end
                    data.SmoothedVelocity = data.SmoothedVelocity:Lerp(finalVelocity, 0.18)
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

-- Interfaz Gráfica (Se mantiene igual)
MurderTab:CreateSection("Ajustes de Cuchillo Lanzado")
MurderTab:CreateToggle("KnifeSilentActive", "Activar Thrown Silent Aim", function(estado) MurderConfig.SilentAim = estado; saveConfig() end)
MurderTab:CreateToggle("PrioritizeSheriffActive", "Priorizar Sheriff / Héroe", function(estado) MurderConfig.PrioritizeSheriff = estado; saveConfig() end)
MurderTab:CreateToggle("KnifeWallCheckActive", "Activar Wall Check Optimizado", function(estado) MurderConfig.WallCheck = estado; saveConfig() end)
MurderTab:CreateSlider("KnifeHorizSlider", "Predicción Horizontal (Cuchillo)", 0, 300, function(valor) MurderConfig.HorizontalPred = valor / 1000; saveConfig() end)
MurderTab:CreateSlider("KnifeVertSlider", "Predicción Vertical (Saltos/Caída)", 0, 120, function(valor) MurderConfig.VerticalPred = valor / 1000; saveConfig() end)

MurderTab:CreateSection("Visualizadores e Interfaz Inteligente")
MurderTab:CreateToggle("ShowKnifePredictionVisual", "Mostrar Predicción Premium (Círculo Hueco)", function(estado) MurderConfig.ShowPredCircle = estado; saveConfig() end)
MurderTab:CreateToggle("SmartHandVisibility", "Visibilidad Inteligente (Solo Asesino)", function(estado) MurderConfig.SmartVisibility = estado; saveConfig() end)

MurderTab:CreateSection("Personalización del Campo de Visión (FOV)")
MurderTab:CreateToggleColorPicker("FovVisibleMurder", "FovColorMurder", "Mostrar Círculo de FOV", MurderConfig.FOVColor, function(estadoToggle) MurderConfig.ShowFOV = estadoToggle; saveConfig() end, function(colorSeleccionado) MurderConfig.FOVColor = colorSeleccionado; saveConfig() end)
MurderTab:CreateSlider("FovRadiusMurder", "Tamaño del FOV", 30, 600, function(valor) MurderConfig.FOVRadius = valor; saveConfig() end)

-- Métodos de Hooking síncronos
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

-- Retorno para el link de GitHub[span_0](start_span)[span_0](end_span)
return KillerHub
