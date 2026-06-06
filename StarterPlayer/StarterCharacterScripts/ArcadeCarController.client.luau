local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- 🛡️ ANTI-DUPLICATE SAFEGUARD
for _, oldScript in ipairs(script.Parent:GetChildren()) do
	if oldScript:IsA("LocalScript") and oldScript.Name == script.Name and oldScript ~= script then
		oldScript:Destroy()
	end
end

local character = script.Parent
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local values = character:WaitForChild("Values")

-- 📡 MULTIPLAYER & BANKING BRIDGE CONNECTIONS
local carLightEvent = ReplicatedStorage:WaitForChild("CarLightEvent")
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ProcessRunResolution = NetworkEvents:WaitForChild("ProcessRunResolution")

-- 🎛️ DYNAMIC PERFORMANCE PARAMETERS FROM CHAR SKELETON
local MIN_SPEED = 60              
local BASE_FORWARD_SPEED = 90      
local MAX_SPEED = values:WaitForChild("MAX_SPEED").Value      
local ACCELERATION_INDEX = values:WaitForChild("ACCELERATION_INDEX").Value     
local DECELERATION_INDEX = values:WaitForChild("DECELERATION_INDEX").Value    
local HORIZONTAL_SPEED = values:WaitForChild("HANDLING_INDEX").Value
local RIDE_HEIGHT = values:WaitForChild("RIDE_HEIGHT").Value

local CURRENT_FORWARD_SPEED = BASE_FORWARD_SPEED
local MAX_LANE_OFFSET = 60 

-- 🔄 RUNTIME DYNAMIC STAT RE-MAPPING LISTENERS
values:WaitForChild("MAX_SPEED").Changed:Connect(function(newVal) MAX_SPEED = newVal end)
values:WaitForChild("ACCELERATION_INDEX").Changed:Connect(function(newVal) ACCELERATION_INDEX = newVal end)
values:WaitForChild("DECELERATION_INDEX").Changed:Connect(function(newVal) DECELERATION_INDEX = newVal end)
values:WaitForChild("HANDLING_INDEX").Changed:Connect(function(newVal) HORIZONTAL_SPEED = newVal end)
values:WaitForChild("RIDE_HEIGHT").Changed:Connect(function(newVal) RIDE_HEIGHT = newVal end)

-- 🎚️ SUSPENSION LEAN, PITCH, STEERING & CAMERA SLIDERS
local MAX_LEAN_ANGLE = 5          
local MAX_PITCH_ANGLE = 3          
local MAX_TURN_ANGLE = 3.5        
local SUSPENSION_SPEED = 8        

-- 🎥 CAMERA CONFIGURATION SLIDERS
local CAM_HEIGHT = 7.0            
local CAM_DISTANCE = 16.5         
local BASELINE_ROAD_Y = 5.5       

-- 🏎️ MOMENTUM DECAY SLIDER
local MOMENTUM_DECAY = 60         

-- 📉 HIGH-SPEED CONTROL DAMPENING SLIDER
local HIGH_SPEED_DAMPENING = 0.45  

local currentLean = 0              
local currentPitch = 0            
local currentYaw = 0              

-- 🩸 GAMEPLAY STATE
local lives = 3
local isInvincible = false

-- 📈 STREAK MULTIPLIER CORE VARIABLES
local currentMultiplier = 1.0
local multiplierExpiration = 0
local STREAK_DURATION = 3.0
local MULTIPLIER_INCREMENT = 0.2

-- ⏱️ rolling temporal window combo variables
local recentNearMisses = {}     
local NEEDLE_WINDOW = 0.35      

-- 🏆 SCORE ENGINE VARIABLES
local score = 0
local scoreTimer = 0
local passedCars = {} 

-- ⏱️ AUTOMATIC SIGNAL DEBOUNCE TIMERS
local turnDuration = 0
local lastDirection = 0
local AUTO_SIGNAL_THRESHOLD = 0.2 

-- 🟢 INITIALIZE ATTRIBUTES
character:SetAttribute("Lives", lives)
character:SetAttribute("IsBraking", false)
character:SetAttribute("CurrentSpeed", CURRENT_FORWARD_SPEED)
character:SetAttribute("SignalState", "Off")
character:SetAttribute("Score", score)
character:SetAttribute("HeadlightsOn", false)
character:SetAttribute("HighBeamsOn", false)
character:SetAttribute("GameOver", false)
character:SetAttribute("ComboText", "")
character:SetAttribute("ComboTime", 0)
character:SetAttribute("CurrentMultiplier", currentMultiplier)
character:SetAttribute("MultiplierExpiration", multiplierExpiration)

-- 💡 LIGHT VALUE CONFIGURATION SLIDERS
local LOW_BEAM_BRIGHTNESS = 2.5
local HIGH_BEAM_BRIGHTNESS = 12.0

-- ⏱️ CLIENT BLINK TIMER FOR TRAFFIC CARS
local blinkOn = false
local lastBlinkToggle = 0
local BLINK_SPEED = 0.25 

-- 🛠️ STATE CHANGED TRACKERS
local lastBrakeState = false
local lastSignalState = "Off"
local lastHeadlightState = false
local lastHighBeamState = false

-- ============================================================================
-- 🔄 MASTER RESTART RESET AGENT
-- ============================================================================
character:GetAttributeChangedSignal("GameOver"):Connect(function()
	if character:GetAttribute("GameOver") == false and character:GetAttribute("InMenu") == false then
		lives = 3
		CURRENT_FORWARD_SPEED = BASE_FORWARD_SPEED
		score = 0
		scoreTimer = 0
		currentMultiplier = 1.0
		multiplierExpiration = 0
		isInvincible = false
		passedCars = {}
		table.clear(recentNearMisses)

		print("🔄 ArcadeCarController: Engine reinitialized for a live restart!")
	end
end)

-- ============================================================================
-- 💔 LOSS CONDITION DEDUCTION PIPELINES
-- ============================================================================
-- ============================================================================
-- CORRECTED ROUTINE: game.StarterPlayer.StarterCharacterScripts.ArcadeCarController
-- LOCATION: State Deductions Matrix inside triggerHit()
-- ============================================================================
local function triggerHit()
	-- 🟢 FIX 1: IMMEDIATE GATEKEEPER FENCE
	-- Stops any multi-frame or rapid-succession hits from executing during the active flashing window
	if isInvincible or lives <= 0 then return end
	isInvincible = true -- Instantly close the gate before any processing logic yields execution threads

	local currentMode = character:GetAttribute("GameMode") or "Solo"

	-- 🌐 MULTIPLAYER FREEPLAY RULES (With combo clean alerts added)
	if currentMode == "Multiplayer" then
		CURRENT_FORWARD_SPEED = MIN_SPEED 

		-- Wipes current score multiplier and alerts HUD framework to clear combo popups
		if currentMultiplier > 1.0 then
			currentMultiplier = 1.0
			character:SetAttribute("CurrentMultiplier", currentMultiplier)
			character:SetAttribute("MultiplierExpiration", 0)
			character:SetAttribute("StreakBroken", os.clock()) 
		end

		task.spawn(function()
			for i = 1, 4 do
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.LocalTransparencyModifier = 0.5 end
				end
				task.wait(0.15)
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
				end
				task.wait(0.15)
			end
			isInvincible = false
		end)
		return 
	end

	-- 🕹️ SOLO ENDLESS MODE RULES
	-- 🟢 FIX 2: STRICT SEPARATION OF STATE DEDUCTION
	lives = lives - 1
	character:SetAttribute("Lives", lives)
	CURRENT_FORWARD_SPEED = MIN_SPEED

	if currentMultiplier > 1.0 then
		currentMultiplier = 1.0
		character:SetAttribute("CurrentMultiplier", currentMultiplier)
		character:SetAttribute("MultiplierExpiration", 0)
		character:SetAttribute("StreakBroken", os.clock()) 
	end

	if lives <= 0 then
		CURRENT_FORWARD_SPEED = 0
		character:SetAttribute("CurrentSpeed", 0)
		character:SetAttribute("GameOver", true)
		character:SetAttribute("InMenu", true)

		print("🛑 RUN OUT OF LIVES: Transmitting scores to account servers...")

		task.spawn(function()
			local success, resultMessage = ProcessRunResolution:InvokeServer("Endless", math.floor(score), false)
			print(resultMessage)
		end)
		return
	end

	-- 🟢 FIX 3: BULLETPROOF RECOVERY PROFILE
	-- Extends the invincibility window and forces transparency modifier updates safely
	task.spawn(function()
		-- 1.5 seconds of absolute collision immunity to allow the chassis to pass entirely through the obstacle
		local duration = 1.5
		local flashFrequency = 0.1
		local elapsed = 0
		
		while elapsed < duration do
			if lives <= 0 or character:GetAttribute("GameOver") == true then break end
			
			-- Toggle transparency fields to create visual blinking indicator feedback
			local currentModifierValue = (math.floor(elapsed / flashFrequency) % 2 == 0) and 0.6 or 0
			
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then 
					part.LocalTransparencyModifier = currentModifierValue 
					part.CanCollide = false -- Explicitly strip collisions every frame during recovery
				end
			end
			
			elapsed = elapsed + task.wait()
		end
		
		-- Clean recovery wrap up state
		if lives > 0 and character:GetAttribute("GameOver") ~= true then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then 
					part.LocalTransparencyModifier = 0 
				end
			end
			isInvincible = false -- Open the hit validation gate again safely
			print("🛡️ Invincibility window expired cleanly. Core hit tracking active.")
		end
	end)
end

-- 🛠️ PRE-FLIGHT COLLISION CLEANER
for _, part in ipairs(character:GetDescendants()) do
	if part:IsA("BasePart") and part ~= rootPart then
		part.CanCollide = false
	end
end

-- ============================================================================
-- 🔁 CORE HEARTBEAT RENDERING CONTROL RUNNERS
-- ============================================================================
-- ============================================================================
-- MODIFIED ROUTINE: game.StarterPlayer.StarterCharacterScripts.ArcadeCarController
-- LOCATION: RunService.RenderStepped Physics Guard Matrix
-- ============================================================================
RunService.RenderStepped:Connect(function(deltaTime)
	if character:GetAttribute("InMenu") == true or lives <= 0 then
		return
	end

	-- 🟢 NEW: PAUSE PHANTOM MODE INTERCEPTOR
	local isPaused = character:GetAttribute("IsPaused") or false

	-- Manage local parts visibility and collision layers dynamically based on state
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if isPaused then
				part.LocalTransparencyModifier = 1 -- Make completely invisible locally
				part.CanCollide = false            -- Strip physics contact points
			else
				-- Restore visibility if not in an active post-crash invincibility flash window
				if not isInvincible then
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end

	if isPaused then
		-- Zero out structural forces completely so the physics root freezes solid in time
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		return -- Freeze frame execution loop immediately
	end

	if os.clock() - lastBlinkToggle >= BLINK_SPEED then
		blinkOn = not blinkOn
		lastBlinkToggle = os.clock()
	end

	local moveDirection = 0
	local throttleDirection = 0
	-- ============================================================================
	-- [[ REMAINING ARCADE CAR CONTROLLER LOGIC CONTINUES UNCHANGED FROM HERE ]]
	-- ============================================================================

	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		moveDirection = -1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		moveDirection = 1
	end

	if moveDirection ~= 0 then
		if moveDirection == lastDirection then
			turnDuration = turnDuration + deltaTime
		else
			turnDuration = 0
		end
		lastDirection = moveDirection
	else
		turnDuration = 0
		lastDirection = 0
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		throttleDirection = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		throttleDirection = -1
		character:SetAttribute("IsBraking", true)
	else
		character:SetAttribute("IsBraking", false)
	end

	local currentSignal = "Off"
	if UserInputService:IsKeyDown(Enum.KeyCode.X) then
		currentSignal = "Hazards"
	elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
		currentSignal = "Left"    
	elseif UserInputService:IsKeyDown(Enum.KeyCode.E) then
		currentSignal = "Right"   
	elseif moveDirection == -1 and turnDuration >= AUTO_SIGNAL_THRESHOLD then
		currentSignal = "Left"    
	elseif moveDirection == 1 and turnDuration >= AUTO_SIGNAL_THRESHOLD then
		currentSignal = "Right"   
	end
	character:SetAttribute("SignalState", currentSignal)

	local currentBrakeState = character:GetAttribute("IsBraking") or false
	if currentBrakeState ~= lastBrakeState then
		lastBrakeState = currentBrakeState
		carLightEvent:FireServer(character, "BrakeLights", currentBrakeState)
	end

	if currentSignal ~= lastSignalState then
		lastSignalState = currentSignal
		carLightEvent:FireServer(character, "SignalState", currentSignal)
	end

	if throttleDirection == 1 then
		local speedDeficitRatio = (MAX_SPEED - CURRENT_FORWARD_SPEED) / (MAX_SPEED - MIN_SPEED)
		local dynamicEnginePush = math.max(speedDeficitRatio, 0.08)
		CURRENT_FORWARD_SPEED = math.min(CURRENT_FORWARD_SPEED + (ACCELERATION_INDEX * dynamicEnginePush * deltaTime), MAX_SPEED)
	elseif throttleDirection == -1 then
		CURRENT_FORWARD_SPEED = math.max(CURRENT_FORWARD_SPEED - (DECELERATION_INDEX * deltaTime), MIN_SPEED)
	else
		if CURRENT_FORWARD_SPEED > BASE_FORWARD_SPEED then
			CURRENT_FORWARD_SPEED = math.max(CURRENT_FORWARD_SPEED - (MOMENTUM_DECAY * deltaTime), BASE_FORWARD_SPEED)
		elseif CURRENT_FORWARD_SPEED < BASE_FORWARD_SPEED then
			CURRENT_FORWARD_SPEED = math.min(CURRENT_FORWARD_SPEED + (MOMENTUM_DECAY * deltaTime), BASE_FORWARD_SPEED)
		end
	end
	character:SetAttribute("CurrentSpeed", CURRENT_FORWARD_SPEED)

	local currentTime = os.clock()
	if currentTime >= multiplierExpiration and currentMultiplier > 1.0 then
		currentMultiplier = 1.0
		character:SetAttribute("CurrentMultiplier", currentMultiplier)
	end

	scoreTimer = scoreTimer + deltaTime
	if scoreTimer >= 0.1 then
		scoreTimer = 0
		local speedBonusMultiplier = CURRENT_FORWARD_SPEED / BASE_FORWARD_SPEED
		score = score + (10 * speedBonusMultiplier * currentMultiplier)
		character:SetAttribute("Score", math.floor(score))
	end

	local speedFactor = math.clamp((CURRENT_FORWARD_SPEED - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 1)
	local handlingDampening = 1 - (speedFactor * HIGH_SPEED_DAMPENING)

	local currentPos = rootPart.Position
	local newZ = currentPos.Z - (CURRENT_FORWARD_SPEED * deltaTime) 
	local newX = currentPos.X + (moveDirection * (HORIZONTAL_SPEED * handlingDampening) * deltaTime) 

	newX = math.clamp(newX, -MAX_LANE_OFFSET, MAX_LANE_OFFSET)

	local targetLean = -moveDirection * math.rad(MAX_LEAN_ANGLE)
	currentLean = currentLean + (targetLean - currentLean) * (SUSPENSION_SPEED * deltaTime)

	local targetPitch = throttleDirection * math.rad(MAX_PITCH_ANGLE)
	if throttleDirection == 1 then
		local speedFactorFactor = (CURRENT_FORWARD_SPEED - BASE_FORWARD_SPEED) / (MAX_SPEED - BASE_FORWARD_SPEED)
		speedFactorFactor = math.clamp(speedFactorFactor, 0, 1)
		local topSpeedDampening = 1 - (speedFactorFactor * 0.6)
		targetPitch = targetPitch * topSpeedDampening
	elseif throttleDirection == -1 then
		local brakeFactor = (CURRENT_FORWARD_SPEED - MIN_SPEED) / (BASE_FORWARD_SPEED - MIN_SPEED)
		brakeFactor = math.clamp(brakeFactor, 0, 1)
		targetPitch = targetPitch * brakeFactor
	end
	currentPitch = currentPitch + (targetPitch - currentPitch) * (SUSPENSION_SPEED * deltaTime)

	local targetYaw = -moveDirection * math.rad(MAX_TURN_ANGLE * handlingDampening)
	currentYaw = currentYaw + (targetYaw - currentYaw) * (SUSPENSION_SPEED * deltaTime)

	rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	rootPart.CFrame = CFrame.new(Vector3.new(newX, RIDE_HEIGHT, newZ)) * CFrame.Angles(currentPitch, currentYaw, currentLean) 

	camera.CameraType = Enum.CameraType.Scriptable
	local stableCamPosition = Vector3.new(rootPart.Position.X, rootPart.Position.Y + CAM_HEIGHT, rootPart.Position.Z + CAM_DISTANCE)
	local stableLookTarget = Vector3.new(rootPart.Position.X, rootPart.Position.Y + 2.0, rootPart.Position.Z - 100)
	camera.CFrame = CFrame.lookAt(stableCamPosition, stableLookTarget)

	local trafficCarsToScan = {}
	local generatedContent = workspace:FindFirstChild("GeneratedContent")
	local trafficFolder = generatedContent and generatedContent:FindFirstChild("Traffic")

	if trafficFolder and #trafficFolder:GetChildren() > 0 then
		trafficCarsToScan = trafficFolder:GetChildren()
	else
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj.Name == "TrafficCar" then table.insert(trafficCarsToScan, obj) end
		end
	end

	for _, child in ipairs(trafficCarsToScan) do
		if child:IsA("Model") then
			local primaryPart = child.PrimaryPart
			if not primaryPart then continue end

			local childX = primaryPart.Position.X
			local childZ = primaryPart.Position.Z

			local xDist = math.abs(rootPart.Position.X - childX)
			local zDist = math.abs(rootPart.Position.Z - childZ)

			if xDist < 8.55 and zDist < 14.5 then
				print("💥 CRASH REGISTERED | Hit: " .. child.Name)
				triggerHit()
				break
			end

			if zDist < 12.0 and xDist >= 8.55 and xDist < 12.5 then
				if not passedCars[child] then
					passedCars[child] = true
					recentNearMisses[child] = currentTime 

					local activeChainCount = 0
					for _, passTime in pairs(recentNearMisses) do
						if currentTime - passTime <= NEEDLE_WINDOW then
							activeChainCount = activeChainCount + 1
						end
					end

					if activeChainCount >= 2 then
						currentMultiplier = currentMultiplier + (MULTIPLIER_INCREMENT * 2)
						multiplierExpiration = currentTime + STREAK_DURATION
						score = score + (500 * currentMultiplier)
						character:SetAttribute("ComboText", "THREAD THE NEEDLE!")
					else
						currentMultiplier = currentMultiplier + MULTIPLIER_INCREMENT
						multiplierExpiration = currentTime + STREAK_DURATION
						score = score + (150 * currentMultiplier)
						character:SetAttribute("ComboText", "NEAR MISS")
					end

					character:SetAttribute("ComboTime", currentTime)
					character:SetAttribute("CurrentMultiplier", currentMultiplier)
					character:SetAttribute("MultiplierExpiration", multiplierExpiration)
					character:SetAttribute("Score", math.floor(score))
				end
			end

			if childZ > rootPart.Position.Z + 50 and passedCars[child] then
				passedCars[child] = nil
			end

			local signalState = child:GetAttribute("SignalState") or "Off"
			local isCarBraking = child:GetAttribute("BrakeLights") or child:GetAttribute("IsBraking") or false
			local trafficHeadlightsOn = child:GetAttribute("HeadlightsOn") or false
			local trafficHighBeamsOn = child:GetAttribute("HighBeamsOn") or false

			for _, desc in ipairs(child:GetDescendants()) do
				if desc:IsA("BasePart") then
					if desc.Name == "LeftSignal" then
						desc.Material = (signalState == "Hazards" or signalState == "Left") and blinkOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
					elseif desc.Name == "RightSignal" then
						desc.Material = (signalState == "Hazards" or signalState == "Right") and blinkOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
					elseif desc.Name == "LeftBrakeLight" or desc.Name == "RightBrakeLight" or desc.Name == "BrakeLights" then
						local sLight = desc:FindFirstChildOfClass("SurfaceLight")
						if isCarBraking then
							desc.Material = Enum.Material.Neon
							if sLight then sLight.Enabled = true; sLight.Brightness = trafficHeadlightsOn and 15.0 or 8.0 end
						elseif trafficHeadlightsOn then
							desc.Material = Enum.Material.Neon
							if sLight then sLight.Enabled = true; sLight.Brightness = 1.25 end
						else
							desc.Material = Enum.Material.SmoothPlastic
							if sLight then sLight.Enabled = false end
						end
					elseif desc.Name == "MainLights" then
						local sLight = desc:FindFirstChildOfClass("SurfaceLight")
						if sLight then
							if trafficHighBeamsOn then
								sLight.Enabled = true; sLight.Brightness = HIGH_BEAM_BRIGHTNESS; desc.Material = Enum.Material.Neon
							elseif trafficHeadlightsOn then
								sLight.Enabled = true; sLight.Brightness = LOW_BEAM_BRIGHTNESS; desc.Material = Enum.Material.Neon
							else
								sLight.Enabled = false; desc.Material = Enum.Material.SmoothPlastic
							end
						end
					end
				end
			end
		end
	end

	local currentHeadlights = character:GetAttribute("HeadlightsOn") or false
	if UserInputService:IsKeyDown(Enum.KeyCode.L) then
		if not character:GetAttribute("L_Pressed") then
			character:SetAttribute("L_Pressed", true)
			currentHeadlights = not currentHeadlights
			character:SetAttribute("HeadlightsOn", currentHeadlights)
			if ReplicatedStorage:FindFirstChild("ToggleLights") then
				ReplicatedStorage.ToggleLights:FireServer("HeadlightsOn", currentHeadlights)
			end
		end
	else
		character:SetAttribute("L_Pressed", false)
	end

	local isHoldingEnter = UserInputService:IsKeyDown(Enum.KeyCode.Return)
	character:SetAttribute("HighBeamsOn", isHoldingEnter)

	if currentHeadlights ~= lastHeadlightState then
		lastHeadlightState = currentHeadlights
		carLightEvent:FireServer(character, "HeadlightsOn", currentHeadlights)
	end

	if isHoldingEnter ~= lastHighBeamState then
		lastHighBeamState = isHoldingEnter
		carLightEvent:FireServer(character, "HighBeamsOn", isHoldingEnter)
		if ReplicatedStorage:FindFirstChild("ToggleLights") then
			ReplicatedStorage.ToggleLights:FireServer("HighBeamsOn", isHoldingEnter)
		end
	end

	local speedValueObj = values:FindFirstChild("Speed")
	if speedValueObj then speedValueObj.Value = CURRENT_FORWARD_SPEED end

	local playerHeadlights = character:GetAttribute("HeadlightsOn") or false
	local playerHighBeams = character:GetAttribute("HighBeamsOn") or false
	local playerIsBraking = character:GetAttribute("IsBraking") or false
	local playerSignalState = character:GetAttribute("SignalState") or "Off"

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name == "MainLights" then
				local sLight = descendant:FindFirstChildOfClass("SurfaceLight")
				if sLight then
					if playerHighBeams then
						sLight.Enabled = true; sLight.Brightness = HIGH_BEAM_BRIGHTNESS; descendant.Material = Enum.Material.Neon
					elseif playerHeadlights then
						sLight.Enabled = true; sLight.Brightness = LOW_BEAM_BRIGHTNESS; descendant.Material = Enum.Material.Neon
					else
						sLight.Enabled = false; descendant.Material = Enum.Material.SmoothPlastic
					end
				end
			elseif descendant.Name == "LeftBrakeLight" or descendant.Name == "RightBrakeLight" or descendant.Name == "BrakeLights" then
				local sLight = descendant:FindFirstChildOfClass("SurfaceLight")
				if sLight then
					if playerIsBraking then
						sLight.Enabled = true; sLight.Brightness = playerHeadlights and 15.0 or 8.0; descendant.Material = Enum.Material.Neon
					elseif playerHeadlights then
						sLight.Enabled = true; sLight.Brightness = 1.25; descendant.Material = Enum.Material.Neon
					else
						sLight.Enabled = false; descendant.Material = Enum.Material.SmoothPlastic
					end
				end
			elseif descendant.Name == "LeftSignal" then
				descendant.Material = (playerSignalState == "Hazards" or playerSignalState == "Left") and blinkOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
			elseif descendant.Name == "RightSignal" then
				descendant.Material = (playerSignalState == "Hazards" or playerSignalState == "Right") and blinkOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
			end
		end
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer and otherPlayer.Character then
			local otherChar = otherPlayer.Character
			local vehicleBody = otherChar:FindFirstChild("EquippedVehicleBody")
			if vehicleBody then
				local pHeadlights = otherChar:GetAttribute("HeadlightsOn") or false
				local pHighBeams = otherChar:GetAttribute("HighBeamsOn") or false
				local pIsBraking = otherChar:GetAttribute("BrakeLights") or false
				local pSignalState = otherChar:GetAttribute("SignalState") or "Off"

				for _, desc in ipairs(vehicleBody:GetDescendants()) do
					if desc:IsA("BasePart") then
						if desc.Name == "MainLights" then
							local sLight = desc:FindFirstChildOfClass("SurfaceLight")
							if sLight then
								if pHighBeams then
									sLight.Enabled = true; sLight.Brightness = HIGH_BEAM_BRIGHTNESS; desc.Material = Enum.Material.Neon
								elseif pHeadlights then
									sLight.Enabled = true; sLight.Brightness = LOW_BEAM_BRIGHTNESS; desc.Material = Enum.Material.Neon
								else
									sLight.Enabled = false; desc.Material = Enum.Material.SmoothPlastic
								end
							end
						elseif desc.Name == "LeftBrakeLight" or desc.Name == "RightBrakeLight" or desc.Name == "BrakeLights" then
							local sLight = desc:FindFirstChildOfClass("SurfaceLight")
							if sLight then
								if pIsBraking then
									sLight.Enabled = true; sLight.Brightness = pHeadlights and 15.0 or 8.0; desc.Material = Enum.Material.Neon
								elseif pHeadlights then
									sLight.Enabled = true; sLight.Brightness = 1.25; desc.Material = Enum.Material.Neon
								else
									sLight.Enabled = false; desc.Material = Enum.Material.SmoothPlastic
								end
							end
						elseif desc.Name == "LeftSignal" then
							desc.Material = (pSignalState == "Hazards" or pSignalState == "Left") and blinkOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
						elseif desc.Name == "RightSignal" then
							desc.Material = (pSignalState == "Hazards" or pSignalState == "Right") and blinkOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
						end
					end
				end
			end
		end
	end
end)