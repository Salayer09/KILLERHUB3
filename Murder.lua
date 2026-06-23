-- ============================================================================
-- 👻 KILLER HUB | SHERIFF V6.6.3 [🔥 THE REPAIR UPDATE - BUG FIXED]
-- ============================================================================
if _G.KillerHubLines then
    for _, line in pairs(_G.KillerHubLines) do
        pcall(function() line:Remove() end)
    end
end
_G.KillerHubLines = {}

local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub/refs/heads/main/Slayer.lua"))()

-- 1. PESTAÑA SHERIFF
local SheriffTab = KillerHub:CreateTab("Sheriff", "rbxassetid://10747373142")

-- 2. CONFIGURACIÓN GLOBAL AUTOMÁTICA
local SheriffConfig = {
    SilentAim = false,
    PredictionMode = "Híbrido Absoluto (Omni)", 
    HorizontalPred = 0.145, 
    VerticalPred = 0.035,   
    WallCheck = true,    
    
    -- Tracers Sincronizados
    PredictTracer = true,      
    ShowPingTracer = false,    
    ShowLagTracer = false,     
    ShowLeadTracer = true,     
    
    TracerSmoothness = 0.60, 
    UseWeaponDetector = false, 
    AutoUnequip = false,        
    ShowShootButton = false,
    ButtonSize = 95,
    ButtonOpacity = 0.95, 
    ButtonLocked = false,
    ButtonX = 0.7, 
    ButtonY = 0.6,
    LeadTimePred = 0.05 
}

local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "KillerHub_SheriffSuite.txt"

local function saveConfig()
    if writefile then
        local data = {
            ButtonX = SheriffConfig.ButtonX,
            ButtonY = SheriffConfig.ButtonY,
            PredictionMode = SheriffConfig.PredictionMode,
            HorizontalPred = SheriffConfig.HorizontalPred, 
            VerticalPred = SheriffConfig.VerticalPred,     
            LeadTimePred = SheriffConfig.LeadTimePred,
            TracerSmoothness = SheriffConfig.TracerSmoothness,
            UseWeaponDetector = SheriffConfig.UseWeaponDetector,
            AutoUnequip = SheriffConfig.AutoUnequip,
            PredictTracer = SheriffConfig.PredictTracer,
            ShowLeadTracer = SheriffConfig.ShowLeadTracer,
            ShowPingTracer = SheriffConfig.ShowPingTracer,
            ShowLagTracer = SheriffConfig.ShowLagTracer
        }
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end
end

local function loadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(data) == "table" then
            SheriffConfig.ButtonX = data.ButtonX or SheriffConfig.ButtonX
            SheriffConfig.ButtonY = data.ButtonY or SheriffConfig.ButtonY
            SheriffConfig.PredictionMode = data.PredictionMode or SheriffConfig.PredictionMode
            SheriffConfig.HorizontalPred = data.HorizontalPred or SheriffConfig.HorizontalPred 
            SheriffConfig.VerticalPred = data.VerticalPred or SheriffConfig.VerticalPred     
            SheriffConfig.LeadTimePred = data.LeadTimePred or SheriffConfig.LeadTimePred
            SheriffConfig.TracerSmoothness = data.TracerSmoothness or SheriffConfig.TracerSmoothness
            if data.UseWeaponDetector ~= nil then SheriffConfig.UseWeaponDetector = data.UseWeaponDetector end
            if data.AutoUnequip ~= nil then SheriffConfig.AutoUnequip = data.AutoUnequip end
            if data.PredictTracer ~= nil then SheriffConfig.PredictTracer = data.PredictTracer end
            if data.ShowLeadTracer ~= nil then SheriffConfig.ShowLeadTracer = data.ShowLeadTracer end
            if data.ShowPingTracer ~= nil then SheriffConfig.ShowPingTracer = data.ShowPingTracer end
            if data.ShowLagTracer ~= nil then SheriffConfig.ShowLagTracer = data.ShowLagTracer end
        end
    end
end
loadConfig()

-- ============================================================================
-- ⚙️ INTERFAZ GRÁFICA CONTROLADA
-- ============================================================================
SheriffTab:CreateSection("Ajustes del Silent Aim")

SheriffTab:CreateToggle("SheriffSilent", "Activar Silent Aim Pasivo", function(estado)
    SheriffConfig.SilentAim = estado
end)

SheriffTab:CreateToggle("SheriffWallCheckToggle", "Verificar Paredes (Wall Check)", function(estado)
    SheriffConfig.WallCheck = estado
end)

SheriffTab:CreateDropdown("PredMode", "Modo de Predicción:", {"Híbrido Absoluto (Omni)", "Predictiva 2.0 (Aceleración)", "Predictivo Adaptativo"}, function(seleccionado)
    SheriffConfig.PredictionMode = seleccionado
    saveConfig()
end)

SheriffTab:CreateSlider("HorizontalPredSlider", "Predicción Horizontal", 0, 300, function(valor)
    SheriffConfig.HorizontalPred = valor / 1000 
    saveConfig() 
end)

SheriffTab:CreateSlider("VerticalPredSlider", "Predicción Vertical (Suave)", 0, 120, function(valor)
    SheriffConfig.VerticalPred = valor / 1000
    saveConfig() 
end)

SheriffTab:CreateSection("Líneas de Trayectoria")

SheriffTab:CreateMultiDropdown("ActiveTracers", "Seleccionar Tracers Activos:", {
    "Impacto Final (Rojo)", 
    "Ping (Azul)", 
    "Lag (Violeta)", 
    "Lead (Verde)"
}, function(tablaFlags)
    SheriffConfig.PredictTracer = tablaFlags["Impacto Final (Rojo)"]
    SheriffConfig.ShowPingTracer = tablaFlags["Ping (Azul)"]
    SheriffConfig.ShowLagTracer = tablaFlags["Lag (Violeta)"]
    SheriffConfig.ShowLeadTracer = tablaFlags["Lead (Verde)"]
    saveConfig()
end)

SheriffTab:CreateSlider("TracerSmoothSlider", "Estabilizador Anti-Temblor (1 = Instantáneo)", 1, 100, function(valor)
    if valor == 1 then
        SheriffConfig.TracerSmoothness = 1 
    else
        SheriffConfig.TracerSmoothness = 0.95 - ((valor - 2) / 98) * 0.80
    end
    saveConfig()
end)

SheriffTab:CreateSlider("LeadTimeSlider", "Anticipación de la Mano (Lead Time)", 0, 100, function(valor)
    SheriffConfig.LeadTimePred = valor / 100
    saveConfig()
end)

SheriffTab:CreateSection("Condiciones de Interfaz / Tácticas")
SheriffTab:CreateToggle("WeaponDetectToggle", "Ocultar Botón si no tengo Arma en Inventario", function(estado)
    SheriffConfig.UseWeaponDetector = estado
    saveConfig()
end)

SheriffTab:CreateToggle("AutoUnequipToggle", "Auto-Desequipar Arma (Fast Unequip)", function(estado)
    SheriffConfig.AutoUnequip = estado
    saveConfig()
end)

SheriffTab:CreateToggle("ShowVoidButton", "Mostrar Botón en Pantalla", function(estado)
    SheriffConfig.ShowShootButton = estado
end)

SheriffTab:CreateSlider("VoidBtnSize", "Tamaño del Botón Void", 50, 200, function(valor)
    SheriffConfig.ButtonSize = valor
    local btn = game:GetService("CoreGui"):FindFirstChild("KillerHub_VoidGui") and game:GetService("CoreGui").KillerHub_VoidGui:FindFirstChild("ShootButton")
    if btn then 
        btn.Size = UDim2.new(0, valor, 0, valor) 
        if btn:FindFirstChild("UICorner") then btn.UICorner.CornerRadius = UDim.new(0, math.floor(valor * 0.24)) end
    end
end)

SheriffTab:CreateSlider("VoidBtnOpacity", "Opacidad del Botón", 10, 100, function(valor)
    SheriffConfig.ButtonOpacity = valor / 100
    local btn = game:GetService("CoreGui"):FindFirstChild("KillerHub_VoidGui") and game:GetService("CoreGui").KillerHub_VoidGui:FindFirstChild("ShootButton")
    if btn then
        btn.BackgroundTransparency = 1 - SheriffConfig.ButtonOpacity
        if btn:FindFirstChild("DecalTexture") then btn.DecalTexture.ImageTransparency = 1 - SheriffConfig.ButtonOpacity end
        if btn:FindFirstChild("Label") then btn.Label.TextTransparency = 1 - SheriffConfig.ButtonOpacity end
    end
end)

SheriffTab:CreateToggle("LockVoidBtn", "Bloquear Posición del Botón", function(estado)
    SheriffConfig.ButtonLocked = estado
end)

-- ============================================================================
-- 🧠 MOTOR CINEMÁTICO INTEGRADO Y DESGLOSADO DE TRACERS
-- ============================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") 
local Stats = game:GetService("Stats") 
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local lastVelocity = Vector3.new(0,0,0)
local previousTargetVelocity = Vector3.new(0,0,0) 
local smoothedVelocity = Vector3.new(0,0,0)
local lastRawVelocity = Vector3.new(0,0,0) 
local lastTargetChar = nil
local lastDeltaTime = 0.016

local pingHistory = {}
local maxPingHistorySize = 12
local cachedPingValue = 0.06

local function getSmoothedPing(rawPing)
    table.insert(pingHistory, rawPing)
    if #pingHistory > maxPingHistorySize then table.remove(pingHistory, 1) end
    
    local sum = 0
    local maxRecentPing = 0
    for _, p in ipairs(pingHistory) do
        sum = sum + p
        if p > maxRecentPing then maxRecentPing = p end
    end
    local averagePing = sum / #pingHistory
    return (averagePing * 0.65) + (maxRecentPing * 0.35)
end

task.spawn(function()
    while task.wait(0.3) do
        if Stats and Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerToClientPing") then
            local currentRaw = Stats.Network.ServerToClientPing:GetValue() / 1000
            cachedPingValue = getSmoothedPing(currentRaw)
        end
    end
end)

local wallcastParams = RaycastParams.new()
wallcastParams.FilterType = Enum.RaycastFilterType.Exclude

local floorCastParams = RaycastParams.new()
floorCastParams.FilterType = Enum.RaycastFilterType.Exclude

local function getGunLocation()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Gun") then
        return char:FindFirstChild("Gun"), char
    elseif LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Gun") then
        return LocalPlayer.Backpack.Gun, LocalPlayer.Backpack
    end
    return nil, nil
end

local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Parent ~= nil then
            local char = player.Character
            if (char and char:FindFirstChild("Knife")) or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife")) then
                return player
            end
        end
    end
    return nil
end

local function isTargetVisible(targetPart, murdererChar)
    if not SheriffConfig.WallCheck then return true end
    if not targetPart or not murdererChar or not LocalPlayer.Character then return false end
    
    local char = LocalPlayer.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local gun = char:FindFirstChild("Gun")
    local originPos = (gun and gun:FindFirstChild("Handle")) and gun.Handle.Position or hrp.Position
    local targetPos = targetPart.Position
    
    local ignoreList = {char, murdererChar, Camera}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p ~= murdererChar then table.insert(ignoreList, p.Character) end
    end
    wallcastParams.FilterDescendantsInstances = ignoreList
    
    local clipCheck = workspace:Raycast(hrp.Position, originPos - hrp.Position, wallcastParams)
    if clipCheck then return false end
    
    local pathCheck = workspace:Raycast(originPos, targetPos - originPos, wallcastParams)
    if not pathCheck then return true end 
    
    local instance = pathCheck.Instance
    if instance.CanCollide == true then return false end
    if instance.Transparency < 0.75 then return false end
    
    local mat = instance.Material
    if mat == Enum.Material.Glass or mat == Enum.Material.SmoothPlastic or mat == Enum.Material.Brick or mat == Enum.Material.Wood or mat == Enum.Material.Concrete or mat == Enum.Material.Metal then
        return false
    end
    
    return false
end

local function getBestTargetPart(murdererChar)
    if not murdererChar then return nil end
    local hrp = murdererChar:FindFirstChild("HumanoidRootPart")
    local head = murdererChar:FindFirstChild("Head")
    
    if hrp and isTargetVisible(hrp, murdererChar) then
        return hrp
    elseif head and isTargetVisible(head, murdererChar) then
        return head
    end
    return nil 
end

local function getFloorHeight(targetHrp, targetChar)
    floorCastParams.FilterDescendantsInstances = {targetChar, LocalPlayer.Character, Camera}
    local ray = workspace:Raycast(targetHrp.Position, Vector3.new(0, -25, 0), floorCastParams)
    return ray and ray.Position.Y or nil
end

local function getPredictedPosition(targetChar, targetPart)
    if not targetChar or not targetPart then return nil, nil, nil end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not humanoid or humanoid.Health <= 0 or not localHrp then return nil, nil, nil end

    if lastTargetChar ~= targetChar then
        smoothedVelocity = hrp.AssemblyLinearVelocity
        previousTargetVelocity = smoothedVelocity
        lastRawVelocity = hrp.AssemblyLinearVelocity
        lastTargetChar = targetChar
    end

    local targetPosition = targetPart.Position
    local distance = (targetPosition - localHrp.Position).Magnitude

    local proximityFactor = 1
    if distance < 14 then
        proximityFactor = math.clamp((distance - 2) / 12, 0.35, 1)
    end

    local rawVelocity = hrp.AssemblyLinearVelocity
    if rawVelocity.Magnitude > 16.705 then 
        rawVelocity = rawVelocity.Unit * 16.705 
    end

    local dotProduct = 1
    if lastRawVelocity.Magnitude > 0.5 and rawVelocity.Magnitude > 0.5 then
        dotProduct = rawVelocity.Unit:Dot(lastRawVelocity.Unit)
    end
    lastRawVelocity = rawVelocity 

    local clampedDT = math.min(lastDeltaTime, 0.05) 
    local isLowFPS = lastDeltaTime > 0.033

    local responseSpeed = isLowFPS and 11.0 or 15.5
    local adaptiveWeight = math.clamp(1 - math.exp(-responseSpeed * clampedDT), 0.08, 0.88)
    smoothedVelocity = smoothedVelocity:Lerp(rawVelocity, adaptiveWeight)
    
    if smoothedVelocity.Magnitude < 0.05 then 
        previousTargetVelocity = smoothedVelocity
        return targetPosition, targetPosition, targetPosition 
    end

    local currentSpeed = smoothedVelocity.Magnitude
    local speedFactor = math.clamp(currentSpeed / 16.705, 0, 1.2)

    local fpsBuffer = isLowFPS and 0.040 or 0.030
    local ping = math.clamp(cachedPingValue, 0.01, 0.5) + fpsBuffer 
    
    local distanceFactor = math.clamp(distance / 22, 0.05, 1.15) * proximityFactor
    local hFactor = (SheriffConfig.HorizontalPred * 1.12) * speedFactor

    local timeFrameTotal = (hFactor + ping) * distanceFactor
    local timeFramePingOnly = ping * distanceFactor
    local timeFrameLagOnly = hFactor * distanceFactor

    local rawAcceleration = (smoothedVelocity - previousTargetVelocity) / math.max(clampedDT, 0.001)
    if dotProduct < 0.5 then rawAcceleration = rawAcceleration * 0.05 end
    if rawAcceleration.Magnitude > 60 then rawAcceleration = rawAcceleration.Unit * 60 end
    local accAmortiguacion = isLowFPS and 0.02 or 0.06
    local stableAcceleration = Vector3.new(rawAcceleration.X, rawAcceleration.Y * accAmortiguacion, rawAcceleration.Z)

    local finalHorizontal = Vector3.new(0,0,0)
    local pingHorizontal = Vector3.new(0,0,0)
    local lagHorizontal = Vector3.new(0,0,0)

    if SheriffConfig.PredictionMode == "Híbrido Absoluto (Omni)" then
        local linealPred = (smoothedVelocity * timeFrameTotal)
        local adaptativoPred = (smoothedVelocity * (timeFrameTotal * math.clamp(dotProduct, 0.4, 1.0)))
        local aceleracionPred = (smoothedVelocity * timeFrameTotal) + (0.5 * stableAcceleration * (timeFrameTotal ^ 2))
        
        if distance < 13 then finalHorizontal = linealPred:Lerp(adaptativoPred, 0.5)
        else finalHorizontal = linealPred:Lerp(adaptativoPred, 0.3):Lerp(aceleracionPred, math.clamp((distance - 13) / 32, 0, 0.75)) end
        if dotProduct < 0.88 then finalHorizontal = finalHorizontal * math.clamp((dotProduct + 1.12) / 2.0, 0.35, 0.90) end
        if ping > 0.22 then finalHorizontal = finalHorizontal * 0.85 end

        local linealPing = (smoothedVelocity * timeFramePingOnly)
        local adaptativoPing = (smoothedVelocity * (timeFramePingOnly * math.clamp(dotProduct, 0.4, 1.0)))
        local aceleracionPing = (smoothedVelocity * timeFramePingOnly)
        if distance < 13 then pingHorizontal = linealPing:Lerp(adaptativoPing, 0.5)
        else pingHorizontal = linealPing:Lerp(adaptativoPing, 0.3):Lerp(aceleracionPing, math.clamp((distance - 13) / 32, 0, 0.75)) end
        if dotProduct < 0.88 then pingHorizontal = pingHorizontal * math.clamp((dotProduct + 1.12) / 2.0, 0.35, 0.90) end
        if ping > 0.22 then pingHorizontal = pingHorizontal * 0.85 end

        local linealLag = (smoothedVelocity * timeFrameLagOnly)
        local adaptativoLag = (smoothedVelocity * (timeFrameLagOnly * math.clamp(dotProduct, 0.4, 1.0)))
        local aceleracionLag = (smoothedVelocity * timeFrameLagOnly) + (0.5 * stableAcceleration * (timeFrameLagOnly ^ 2))
        if distance < 13 then lagHorizontal = linealLag:Lerp(adaptativoLag, 0.5)
        else lagHorizontal = linealLag:Lerp(adaptativoLag, 0.3):Lerp(aceleracionLag, math.clamp((distance - 13) / 32, 0, 0.75)) end
        if dotProduct < 0.88 then lagHorizontal = lagHorizontal * math.clamp((dotProduct + 1.12) / 2.0, 0.35, 0.90) end

    elseif SheriffConfig.PredictionMode == "Predictiva 2.0 (Aceleración)" then
        finalHorizontal = (smoothedVelocity * timeFrameTotal) + (0.5 * stableAcceleration * (timeFrameTotal ^ 2))
        if ping > 0.22 then finalHorizontal = finalHorizontal * 0.80 end

        pingHorizontal = (smoothedVelocity * timeFramePingOnly)
        if ping > 0.22 then pingHorizontal = pingHorizontal * 0.80 end

        lagHorizontal = (smoothedVelocity * timeFrameLagOnly) + (0.5 * stableAcceleration * (timeFrameLagOnly ^ 2))

    elseif SheriffConfig.PredictionMode == "Predictivo Adaptativo" then
        local function getAdaptOffset(t)
            local dH = t
            if dotProduct < 0.85 then dH = dH * math.clamp(dotProduct, 0.2, 1.0) end
            return Vector3.new(smoothedVelocity.X, 0, smoothedVelocity.Z) * dH
        end
        finalHorizontal = getAdaptOffset(timeFrameTotal)
        pingHorizontal = getAdaptOffset(timeFramePingOnly)
        lagHorizontal = getAdaptOffset(timeFrameLagOnly)
    end

    local verticalOffset = Vector3.new(0, 0, 0)
    if humanoid.FloorMaterial == Enum.Material.Air or math.abs(smoothedVelocity.Y) > 0.1 then
        local gravity = 196.2 
        local verticalTime = ping * SheriffConfig.VerticalPred * proximityFactor
        local pY = (smoothedVelocity.Y * verticalTime) - (0.5 * gravity * (verticalTime ^ 2))
        if distance < 10 then pY = pY * 0.2 end
        verticalOffset = Vector3.new(0, pY, 0)
    end

    local finalPrediction = targetPosition + Vector3.new(finalHorizontal.X, 0, finalHorizontal.Z) + verticalOffset
    local pingPrediction = targetPosition + Vector3.new(pingHorizontal.X, 0, pingHorizontal.Z) + verticalOffset
    local lagPrediction = targetPosition + Vector3.new(lagHorizontal.X, 0, lagHorizontal.Z)

    if smoothedVelocity.Y < -0.1 then
        local floorY = getFloorHeight(hrp, targetChar)
        if floorY then
            local heightScale = humanoid:FindFirstChild("BodyHeightScale") and math.clamp(humanoid.BodyHeightScale.Value, 0.2, 1.5) or 1
            local minAllowedY = floorY + ((hrp.Size.Y / 2) * heightScale) + 0.2
            if finalPrediction.Y < minAllowedY then finalPrediction = Vector3.new(finalPrediction.X, minAllowedY, finalPrediction.Z) end
            if pingPrediction.Y < minAllowedY then pingPrediction = Vector3.new(pingPrediction.X, minAllowedY, pingPrediction.Z) end
            if lagPrediction.Y < minAllowedY then lagPrediction = Vector3.new(lagPrediction.X, minAllowedY, lagPrediction.Z) end
        end
    end

    previousTargetVelocity = smoothedVelocity
    lastVelocity = smoothedVelocity

    return finalPrediction, pingPrediction, lagPrediction
end

-- ============================================================================
-- 🟩 RENDERIZADOR COMPLETO DE CAPAS
-- ============================================================================
local PingLine = Drawing.new("Line")
PingLine.Color = Color3.fromRGB(0, 100, 255) 
PingLine.Thickness = 1.2
PingLine.Visible = false
table.insert(_G.KillerHubLines, PingLine)

local LagLine = Drawing.new("Line")
LagLine.Color = Color3.fromRGB(150, 50, 255) 
LagLine.Thickness = 1.2
LagLine.Visible = false
table.insert(_G.KillerHubLines, LagLine)

local LeadLine = Drawing.new("Line")
LeadLine.Color = Color3.fromRGB(0, 255, 100) 
LeadLine.Thickness = 1.5
LeadLine.Visible = false
table.insert(_G.KillerHubLines, LeadLine)

local PredictionLine = Drawing.new("Line")
PredictionLine.Color = Color3.fromRGB(255, 35, 35) 
PredictionLine.Thickness = 1.8 
PredictionLine.Visible = false
table.insert(_G.KillerHubLines, PredictionLine)

local currentScreenPred = Vector2.new(0,0)
local currentScreenPing = Vector2.new(0,0)
local currentScreenLag = Vector2.new(0,0)
local currentScreenLead = Vector2.new(0,0)
local firstFrame = true

local vec2New, vec3New = Vector2.new, Vector3.new
local worldToViewport = Camera.WorldToViewportPoint

RunService.RenderStepped:Connect(function(dt)
    lastDeltaTime = dt 
    local gun, _ = getGunLocation()
    local hasGun = not SheriffConfig.UseWeaponDetector or (gun ~= nil)
    local murderer = getMurderer()
    local screenGui = game:GetService("CoreGui"):FindFirstChild("KillerHub_VoidGui")
    if screenGui then screenGui.Enabled = SheriffConfig.ShowShootButton and hasGun end

    if not hasGun or not murderer or not murderer.Character then
        PredictionLine.Visible = false; PingLine.Visible = false; LagLine.Visible = false; LeadLine.Visible = false;
        firstFrame = true
        return
    end

    local targetChar = murderer.Character
    local bestPart = getBestTargetPart(targetChar) or targetChar:FindFirstChild("HumanoidRootPart") 
    local localChar = LocalPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

    if bestPart and localHrp then
        local distance = (bestPart.Position - localHrp.Position).Magnitude
        local distFactor = math.clamp((distance - 4) / 16, 0, 1)
        local tSmooth = SheriffConfig.TracerSmoothness
        
        local predictedPos, pingPos, lagPos = getPredictedPosition(targetChar, bestPart)
        local screenOrigin = vec2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        if predictedPos and SheriffConfig.PredictTracer then
            local screenPos, onScreen = worldToViewport(Camera, predictedPos)
            if onScreen then
                local target2D = vec2New(screenPos.X, screenPos.Y)
                currentScreenPred = (firstFrame or tSmooth == 1) and target2D or currentScreenPred:Lerp(target2D, tSmooth)
                PredictionLine.From = screenOrigin
                PredictionLine.To = currentScreenPred
                PredictionLine.Visible = true
            else PredictionLine.Visible = false end
        else PredictionLine.Visible = false end

        if pingPos and SheriffConfig.ShowPingTracer then
            local screenPos, onScreen = worldToViewport(Camera, pingPos)
            if onScreen then
                local target2D = vec2New(screenPos.X, screenPos.Y)
                currentScreenPing = (firstFrame or tSmooth == 1) and target2D or currentScreenPing:Lerp(target2D, tSmooth)
                PingLine.From = screenOrigin
                PingLine.To = currentScreenPing
                PingLine.Visible = true
            else PingLine.Visible = false end
        else PingLine.Visible = false end

        if lagPos and SheriffConfig.ShowLagTracer then
            local screenPos, onScreen = worldToViewport(Camera, lagPos)
            if onScreen then
                local target2D = vec2New(screenPos.X, screenPos.Y)
                currentScreenLag = (firstFrame or tSmooth == 1) and target2D or currentScreenLag:Lerp(target2D, tSmooth)
                LagLine.From = screenOrigin
                LagLine.To = currentScreenLag
                LagLine.Visible = true
            else LagLine.Visible = false end
        else LagLine.Visible = false end

        local hand = localChar and (localChar:FindFirstChild("RightHand") or localChar:FindFirstChild("Right Arm"))
        if SheriffConfig.ShowLeadTracer and hand then
            local balancedVelocity = vec3New(smoothedVelocity.X, smoothedVelocity.Y * 0.5, smoothedVelocity.Z)
            local leadPredictedPos = bestPart.Position + (balancedVelocity * SheriffConfig.LeadTimePred * distFactor)
            
            if smoothedVelocity.Y < -0.5 then
                local floorY = getFloorHeight(bestPart, targetChar)
                if floorY and leadPredictedPos.Y < (floorY + 1) then
                    leadPredictedPos = vec3New(leadPredictedPos.X, floorY + 1, leadPredictedPos.Z)
                end
            end

            local handScreenPos, handOnScreen = worldToViewport(Camera, hand.Position)
            local targetScreenPos, targetOnScreen = worldToViewport(Camera, leadPredictedPos)

            if handOnScreen and targetOnScreen then
                local target2D = vec2New(targetScreenPos.X, targetScreenPos.Y)
                currentScreenLead = (firstFrame or tSmooth == 1) and target2D or currentScreenLead:Lerp(target2D, tSmooth)
                LeadLine.From = vec2New(handScreenPos.X, handScreenPos.Y)
                LeadLine.To = currentScreenLead
                LeadLine.Visible = true
            else LeadLine.Visible = false end
        else LeadLine.Visible = false end
        
        firstFrame = false
    else
        PredictionLine.Visible = false; PingLine.Visible = false; LagLine.Visible = false; LeadLine.Visible = false;
        firstFrame = true
    end 
end)

local function fireAtMurdererDirectly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local gun, parent = getGunLocation()
    local murderer = getMurderer()

    if gun and murderer and murderer.Character then
        local targetChar = murderer.Character
        local bestPart = getBestTargetPart(targetChar) 
        
        if bestPart then 
            local predictedPos = getPredictedPosition(targetChar, bestPart)
            if predictedPos then
                local startedInBackpack = (parent == LocalPlayer.Backpack)
                if startedInBackpack then 
                    humanoid:EquipTool(gun) 
                    RunService.Heartbeat:Wait() 
                end 
                if gun:FindFirstChild("Shoot") then
                    local originCFrame = char.HumanoidRootPart.CFrame
                    if char.HumanoidRootPart:FindFirstChild("GunRaycastAttachment") then
                        originCFrame = char.HumanoidRootPart.GunRaycastAttachment.WorldCFrame
                    end
                    gun.Shoot:FireServer(originCFrame, CFrame.new(predictedPos))
                end 
                if SheriffConfig.AutoUnequip then 
                    task.wait(0.02) 
                    humanoid:UnequipTools() 
                end 
            end
        end
    end
end

-- ============================================================================
-- 🌌 INTERFAZ V3.4 (BOTÓN SHOOT INTERACTIVO - ARREGLADO)
-- ============================================================================
local VoidGui = Instance.new("ScreenGui")
VoidGui.Name = "KillerHub_VoidGui"
VoidGui.ResetOnSpawn = false
VoidGui.Parent = game:GetService("CoreGui")

local ShootButton = Instance.new("ImageButton")
ShootButton.Name = "ShootButton"
ShootButton.Size = UDim2.new(0, SheriffConfig.ButtonSize, 0, SheriffConfig.ButtonSize)
ShootButton.Position = UDim2.new(SheriffConfig.ButtonX, 0, SheriffConfig.ButtonY, 0)
ShootButton.BackgroundColor3 = Color3.fromRGB(15, 6, 26)
ShootButton.BackgroundTransparency = 1 - SheriffConfig.ButtonOpacity
ShootButton.BorderSizePixel = 0  
ShootButton.AutoButtonColor = false 
ShootButton.ClipsDescendants = true 
ShootButton.Parent = VoidGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, math.floor(SheriffConfig.ButtonSize * 0.24))
Corner.Parent = ShootButton

local GlowOverlay = Instance.new("Frame")
GlowOverlay.Name = "GlowOverlay"
GlowOverlay.Size = UDim2.new(1, 0, 1, 0)
GlowOverlay.Position = UDim2.new(0, 0, 0, 0)
GlowOverlay.BackgroundTransparency = 1
GlowOverlay.ZIndex = ShootButton.ZIndex + 1
GlowOverlay.Parent = ShootButton

local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = Corner.CornerRadius
GlowCorner.Parent = GlowOverlay

local UiGradient = Instance.new("UIGradient")
UiGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 8, 43)),    
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(131, 46, 222)),  
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 8, 43))
})
UiGradient.Rotation = 45 
UiGradient.Parent = GlowOverlay

local DecalTexture = Instance.new("ImageLabel")
DecalTexture.Name = "DecalTexture"
DecalTexture.Size = UDim2.new(0.38, 0, 0.38, 0)
DecalTexture.AnchorPoint = Vector2.new(0.5, 0.5)
DecalTexture.Position = UDim2.new(0.5, 0, 0.43, 0)
DecalTexture.BackgroundTransparency = 1
DecalTexture.Image = "rbxassetid://125754446555599"
DecalTexture.ImageTransparency = 1 - SheriffConfig.ButtonOpacity
DecalTexture.ZIndex = ShootButton.ZIndex + 2
DecalTexture.Parent = ShootButton

TweenService:Create(DecalTexture, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 360}):Play()

local Label = Instance.new("TextLabel")
Label.Name = "Label"
Label.Size = UDim2.new(1, 0, 0.2, 0)
Label.Position = UDim2.new(0, 0, 0.75, 0)
Label.BackgroundTransparency = 1
Label.Text = "SHOOT"
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextSize = 15
Label.Font = Enum.Font.GothamBold
Label.TextTransparency = 1 - SheriffConfig.ButtonOpacity
Label.ZIndex = ShootButton.ZIndex + 2
Label.Parent = ShootButton

local function processGlowAtCoordinates(inputPosition)
    local buttonAbsolutePos = ShootButton.AbsolutePosition
    local buttonSize = ShootButton.AbsoluteSize
    local localX = inputPosition.X - buttonAbsolutePos.X
    local relX = (localX / buttonSize.X) - 0.5
    UiGradient.Offset = Vector2.new(relX * 1.5, 0)
    TweenService:Create(GlowOverlay, TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.25}):Play()
end

local function fadeGlowReflection()
    TweenService:Create(GlowOverlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
end

-- 🛸 SISTEMA DE ARRASTRE (REESCRITO DESDE CERO - ANTIBUGS)
local dragging, dragInput, dragStart, startPos
ShootButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        processGlowAtCoordinates(input.Position)
        
        -- ✨ LLAMADA CORREGIDA: `fireAtMurdererDirectly` (Ya no crashea)
        task.spawn(fireAtMurdererDirectly)
        
        if not SheriffConfig.ButtonLocked then
            dragging = true
            dragStart = input.Position
            startPos = ShootButton.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    SheriffConfig.ButtonX = ShootButton.Position.X.Scale
                    SheriffConfig.ButtonY = ShootButton.Position.Y.Scale
                    saveConfig()
                end
            end)
        end
    end
end)

ShootButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fadeGlowReflection()
    end
end)

ShootButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        ShootButton.Position = UDim2.new(
            startPos.X.Scale + (delta.X / Camera.ViewportSize.X), 0, 
            startPos.Y.Scale + (delta.Y / Camera.ViewportSize.Y), 0
        )
    end
end)

-- ============================================================================
-- ⚡ REMOTOS MODIFICADOS
-- ============================================================================
local ClientServices = ReplicatedStorage:WaitForChild("ClientServices", 5)
if ClientServices then
    local WeaponService = require(ClientServices:WaitForChild("WeaponService"))
    local oldGetTargetPosition = WeaponService.GetTargetPosition
    local oldGetMouseTargetCFrame = WeaponService.GetMouseTargetCFrame

    local function checkAndPredict()
        local gun, _ = getGunLocation()
        if SheriffConfig.SilentAim and (not SheriffConfig.UseWeaponDetector or (gun ~= nil)) then
            local murderer = getMurderer()
            if murderer and murderer.Character then
                local targetChar = murderer.Character
                local bestPart = getBestTargetPart(targetChar)
                if bestPart then
                    local predictedPos = getPredictedPosition(targetChar, bestPart)
                    if predictedPos then return CFrame.new(predictedPos) end
                end
            end
        end
        return nil
    end

    WeaponService.GetTargetPosition = function(self, ...)
        local prediction = checkAndPredict()
        return prediction or oldGetTargetPosition(self, ...)
    end

    WeaponService.GetMouseTargetCFrame = function(self, ...)
        local prediction = checkAndPredict()
        return prediction or oldGetMouseTargetCFrame(self, ...)
    end
end

return KillerHub
