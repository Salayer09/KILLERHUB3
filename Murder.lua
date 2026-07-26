-- ============================================================================
-- 👻 KILLER HUB | MURDER SUITE V8.6 (TARGET CACHE OPTIMIZED & CFRAME FIX)
-- ============================================================================
local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub2/main/Sheriff.lua"))()
local Utils = KillerHub.Utils

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
    SmartVisibility = false,

    -- Hitbox Settings
    HitboxActive = false, 
    HitboxSize = 2,
    SeeHitbox = false,
    HitboxMaterial = "Plastic",
    HitboxOpacity = 0 
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
            HitboxActive = MurderConfig.HitboxActive,
            HitboxSize = MurderConfig.HitboxSize,
            SeeHitbox = MurderConfig.SeeHitbox,
            HitboxMaterial = MurderConfig.HitboxMaterial,
            HitboxOpacity = MurderConfig.HitboxOpacity,
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
            if decoded.HitboxActive ~= nil then MurderConfig.HitboxActive = decoded.HitboxActive end
            if decoded.HitboxSize ~= nil then MurderConfig.HitboxSize = decoded.HitboxSize end
            if decoded.SeeHitbox ~= nil then MurderConfig.SeeHitbox = decoded.SeeHitbox end
            if decoded.HitboxMaterial ~= nil then MurderConfig.HitboxMaterial = decoded.HitboxMaterial end
            if decoded.HitboxOpacity ~= nil then MurderConfig.HitboxOpacity = decoded.HitboxOpacity end
            if decoded.FOVColor ~= nil then
                MurderConfig.FOVColor = Color3.new(decoded.FOVColor[1], decoded.FOVColor[2], decoded.FOVColor[3])
            end
        end
    end
end

loadConfig()

local MurderTab = KillerHub:CreateTab("Murder", "rbxassetid://14939026710")

-- Variables de estado globales optimizadas
local globalClosestTarget = nil
local playerFysics = {}
local lastVisualPosition = Vector3.new(0, 0, 0)
local lastActualPosition = Vector3.new(0, 0, 0)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- Visual Drawing API
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 48; FOVCircle.Filled = false; FOVCircle.Visible = false 
local PredRingOuter = Drawing.new("Circle")
PredRingOuter.Radius = 6.0; PredRingOuter.Thickness = 1.2; PredRingOuter.Filled = false; PredRingOuter.Color = Color3.fromRGB(255, 35, 35); PredRingOuter.Visible = false
local PredDotCenter = Drawing.new("Circle")
PredDotCenter.Radius = 2.5; PredDotCenter.Thickness = 1; PredDotCenter.Filled = true; PredDotCenter.Color = Color3.fromRGB(255, 255, 255); PredDotCenter.Visible = false
local PredLine = Drawing.new("Line")
PredLine.Thickness = 1.0; PredLine.Color = Color3.fromRGB(185, 0, 255); PredLine.Transparency = 0.65; PredLine.Visible = false

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
-- 🎯 SHERIFF DETECTION SYSTEM
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
-- 🧠 TARGET SELECTION
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
-- 🧠 KNIFE BALLISTIC PREDICTION MOTOR
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
    if smoothVelocity.Magnitude < 0.15 then return targetPosition, targetPosition end

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

    local velocityScale = math.clamp(exactSpeed / MAX_WALKSPEED, 0, 1)
    if exactSpeed < 12 then
        velocityScale = math.pow(velocityScale, 1.4)
    end

    local shortRangeBoost = distance < 20 and 1.15 or 1.0
    local dynamicScale = (1.0 + (distance * 0.004)) * shortRangeBoost
    local maxElasticCap = math.clamp(distance * 0.38, 3.5, 13.5)
    
    local horizontalOffset = horizontalVelocity * (MurderConfig.HorizontalPred * 6.8) * travelTime * dynamicScale * jukeFactor * velocityScale

    if horizontalOffset.Magnitude > maxElasticCap then horizontalOffset = horizontalOffset.Unit * maxElasticCap end

    local verticalOffset = Vector3.new(0, 0, 0)
    local isAir = (humanoid.FloorMaterial == Enum.Material.Air)
    local absYVelocity = math.abs(smoothVelocity.Y)

    if isAir then
        local verticalVelocity = math.clamp(smoothVelocity.Y, -18, 25)
        local verticalDistanceScale = 1 / (1 + (distance * 0.005))
        verticalVelocity = verticalVelocity * (verticalVelocity < -1 and 0.40 or 0.70)
        verticalOffset = Vector3.new(0, verticalVelocity * (MurderConfig.VerticalPred * 6.0) * travelTime * verticalDistanceScale, 0)
    elseif absYVelocity > 0.02 then
        local verticalVelocity = smoothVelocity.Y
        local rampCompensationFactor = 1.35
        local sliderScale = (MurderConfig.VerticalPred / 0.040)
        verticalOffset = Vector3.new(0, verticalVelocity * travelTime * sliderScale * rampCompensationFactor, 0)
    end

    local finalPredictedPos = targetPosition + horizontalOffset + verticalOffset
    
    local wallClampParams = RaycastParams.new()
    wallClampParams.FilterType = Enum.RaycastFilterType.Exclude
    wallClampParams.FilterDescendantsInstances = {targetChar, LocalPlayer.Character, Camera}
    
    local wallRay = workspace:Raycast(targetPosition, finalPredictedPos - targetPosition, wallClampParams)
    if wallRay and wallRay.Instance and wallRay.Instance.CanCollide then
        local hitDistance = (wallRay.Position - targetPosition).Magnitude
        if hitDistance > 0.5 then
            finalPredictedPos = targetPosition + (finalPredictedPos - targetPosition).Unit * (hitDistance - 0.4)
        else
            finalPredictedPos = targetPosition
        end
    end

    return targetPosition, finalPredictedPos
end

-- ============================================================================
-- 📡 HITBOX ENGINE & OPTIMIZED PHYSICS LOOP (ANTI-LAG ON DEATH)
-- ============================================================================
RunService.Heartbeat:Connect(function()
    local currentTime = os.clock()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and hum and hum.Health > 0 then
                if MurderConfig.HitboxActive and MurderConfig.SeeHitbox then
                    hrp.Size = Vector3.new(MurderConfig.HitboxSize, MurderConfig.HitboxSize, MurderConfig.HitboxSize)
                    
                    local calculatedTransparency = MurderConfig.HitboxOpacity / 100
                    hrp.Transparency = math.clamp(calculatedTransparency, 0, 1)
                    
                    local successMat, parsedMaterial = pcall(function()
                        return Enum.Material[MurderConfig.HitboxMaterial]
                    end)
                    hrp.Material = successMat and parsedMaterial or Enum.Material.Plastic
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.Material = Enum.Material.Plastic
                end

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
            else
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.Material = Enum.Material.Plastic
                end
                playerFysics[player] = nil
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    playerFysics[player] = nil
end)

-- Bucle de Renderizado optimizado con Caché único por Frame
RunService.RenderStepped:Connect(function()
    local hasKnife = hasKnifeInInventory()
    local allowRender = not MurderConfig.SmartVisibility or hasKnife

    -- ACTUALIZACIÓN DE CACHÉ GLOBAL: Evita que los hooks repitan el cálculo pesado
    globalClosestTarget = getClosestTargetToFOV()

    if MurderConfig.ShowFOV and allowRender then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = MurderConfig.FOVRadius
        FOVCircle.Color = MurderConfig.FOVColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if MurderConfig.ShowPredCircle and allowRender and globalClosestTarget and globalClosestTarget.Character then
        local basePos, rawPredictedPos = getAdvancedKnifePrediction(globalClosestTarget.Character)
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
        if globalClosestTarget and globalClosestTarget.Character then
            local hrp = globalClosestTarget.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                lastActualPosition = hrp.Position
                lastVisualPosition = hrp.Position
            end
        end
    end
end)

-- ============================================================================
-- 📊 Clean User Interface
-- ============================================================================
MurderTab:CreateSection("Knife Combats")
MurderTab:CreateToggle("KnifeAimActive", "Knife Thrown aim", function(state) MurderConfig.SilentAim = state; saveConfig() end)
MurderTab:CreateToggle("PrioritizeSheriffActive", "Prioritize Sheriff", function(state) MurderConfig.PrioritizeSheriff = state; saveConfig() end)
MurderTab:CreateToggle("KnifeWallCheckActive", "Wall Check", function(state) MurderConfig.WallCheck = state; saveConfig() end)
MurderTab:CreateSlider("KnifeHorizSlider", "Horizontal prediction", 0, 300, function(value) MurderConfig.HorizontalPred = value / 1000; saveConfig() end)
MurderTab:CreateSlider("KnifeVertSlider", "Vertical prediction", 0, 120, function(value) MurderConfig.VerticalPred = value / 1000; saveConfig() end)

MurderTab:CreateSection("Stab Hitbox Modifier")
MurderTab:CreateToggle("StabHitboxMaster", "Stab Hitbox Status", function(state) MurderConfig.HitboxActive = state; saveConfig() end)
MurderTab:CreateToggle("SeeHitboxActive", "See hitbox", function(state) MurderConfig.SeeHitbox = state; saveConfig() end)

local debouncedSize = Utils.Debounce(function(value)
    MurderConfig.HitboxSize = value
    saveConfig()
end, 0.05)
MurderTab:CreateSlider("HitboxSizeSlider", "Stab Hitbox Size", 2, 30, function(value) debouncedSize(value) end)

local debouncedOpacity = Utils.Debounce(function(value)
    MurderConfig.HitboxOpacity = value
    saveConfig()
end, 0.05)
MurderTab:CreateSlider("HitboxOpacitySlider", "Hitbox opacity", 0, 100, function(value) debouncedOpacity(value) end)

MurderTab:CreateDropdown("HitboxMaterialDropdown", "Hitbox Material", {"Plastic", "SmoothPlastic", "Metal", "DiamondPlate", "Glass", "Neon", "ForceField", "Wood"}, function(selected) MurderConfig.HitboxMaterial = selected; saveConfig() end)

MurderTab:CreateSection("Visuals & Environment")
MurderTab:CreateToggle("ShowKnifePredictionVisual", "See prediction", function(state) MurderConfig.ShowPredCircle = state; saveConfig() end)
MurderTab:CreateToggle("SmartHandVisibility", "Smart Visibility", function(state) MurderConfig.SmartVisibility = state; saveConfig() end)

MurderTab:CreateSection("Field Of View (FOV)")
MurderTab:CreateToggleColorPicker("FovVisibleMurder", "FovColorMurder", "Show FOV Circle", MurderConfig.FOVColor, function(stateToggle) MurderConfig.ShowFOV = stateToggle; saveConfig() end, function(selectedColor) MurderConfig.FOVColor = selectedColor; saveConfig() end)
MurderTab:CreateSlider("FovRadiusMurder", "FOV Radius", 30, 600, function(value) MurderConfig.FOVRadius = value; saveConfig() end)

-- Hooks corregidos (Uso de Caché Global y corrección del tipo Vector3/CFrame)
local ClientServices = ReplicatedStorage:WaitForChild("ClientServices", 5)
if ClientServices then
    local WeaponService = require(ClientServices:WaitForChild("WeaponService"))
    local oldGetTargetPosition = WeaponService.GetTargetPosition
    local oldGetMouseTargetCFrame = WeaponService.GetMouseTargetCFrame

    WeaponService.GetTargetPosition = function(self, ...)
        if MurderConfig.SilentAim and hasKnifeInInventory() and globalClosestTarget and globalClosestTarget.Character then
            local _, predictedPos = getAdvancedKnifePrediction(globalClosestTarget.Character)
            if predictedPos then 
                return predictedPos -- SOLUCIÓN: Retorna un Vector3 puro para evitar que el cuchillo se desvíe.
            end
        end
        return oldGetTargetPosition(self, ...)
    end

    WeaponService.GetMouseTargetCFrame = function(self, ...)
        if MurderConfig.SilentAim and hasKnifeInInventory() and globalClosestTarget and globalClosestTarget.Character then
            local _, predictedPos = getAdvancedKnifePrediction(globalClosestTarget.Character)
            if predictedPos then 
                return CFrame.new(predictedPos) -- SOLUCIÓN: Retorna un CFrame nativo completo.
            end
        end
        return oldGetMouseTargetCFrame(self, ...)
    end
end

return KillerHub
