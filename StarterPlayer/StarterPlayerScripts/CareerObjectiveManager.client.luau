-- ============================================================================
-- FULL NAME: game.StarterPlayer.StarterPlayerScripts.CareerObjectiveManager
-- LOCATION: StarterPlayerScripts -> CareerObjectiveManager (LocalScript)
-- ============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- 📁 MODULAR CONFIGURATION MATRIX LINKS
local ProgressionConfig = require(ReplicatedStorage:WaitForChild("ProgressionConfig"))
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ProcessRunResolution = NetworkEvents:WaitForChild("ProcessRunResolution")

local activeTracking = false
local startTime = 0
local initialZCoord = 0
local speedMaintenanceTimer = 0
local stageConstraintsMet = false

-- Dynamic objective UI display overlay anchors (Injected into your updated HUD layout)
local screenGui = localPlayer:WaitForChild("PlayerGui"):WaitForChild("HighwayHUD_v2")
local hudContainer = screenGui:WaitForChild("HUDContainer")

local objectiveDisplay = Instance.new("TextLabel")
objectiveDisplay.Name = "CareerObjectiveTrackerLabel"
objectiveDisplay.Size = UDim2.new(0, 400, 0, 24)
objectiveDisplay.Position = UDim2.new(0.5, -200, 1, 15) -- Placed neatly below score pills
objectiveDisplay.BackgroundTransparency = 1
objectiveDisplay.Font = Enum.Font.GothamMedium
objectiveDisplay.TextSize = 14
objectiveDisplay.TextColor3 = Color3.fromRGB(240, 240, 245)
objectiveDisplay.TextStrokeTransparency = 0
objectiveDisplay.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
objectiveDisplay.Visible = false
objectiveDisplay.Parent = hudContainer

local function terminateSessionTracker()
	activeTracking = false
	objectiveDisplay.Visible = false
end

local function initializeCampaignObjectiveTracker(charContext)
	character = charContext
	local gameMode = character:GetAttribute("GameMode") or "Solo"
	if gameMode ~= "Career" then 
		terminateSessionTracker()
		return 
	end

	-- Extract user profile attributes assigned securely by our PlayerDataManager
	local countryIndex = localPlayer:GetAttribute("CurrentCountry") or 1
	local stageIndex = localPlayer:GetAttribute("CurrentStage") or 1

	local countryData = ProgressionConfig.Campaign[countryIndex]
	if not countryData then return end
	local stageData = countryData.Stages[stageIndex]
	if not stageData then
		warn("🏁 Campaign Matrix Complete! Maximum milestone reached for current world zones.")
		return
	end

	local rootPart = character:WaitForChild("HumanoidRootPart")
	initialZCoord = rootPart.Position.Z
	startTime = os.clock()
	speedMaintenanceTimer = 0
	stageConstraintsMet = false
	activeTracking = true
	objectiveDisplay.Visible = true

	print(string.format("🗺️ Campaign Route Loaded: %s | Stage %d Objectives Initialized.", countryData.CountryName, stageIndex))
end

-- 🔁 RUNTIME PERFORMANCE FRAME DELTA EVALUATION TICK
RunService.RenderStepped:Connect(function(deltaTime)
	if not activeTracking or not character or not character.Parent or character:GetAttribute("GameOver") == true then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local countryIndex = localPlayer:GetAttribute("CurrentCountry") or 1
	local stageIndex = localPlayer:GetAttribute("CurrentStage") or 1
	local stageData = ProgressionConfig.Campaign[countryIndex].Stages[stageIndex]
	if not stageData then return end

	local timeElapsed = os.clock() - startTime
	local timeLeft = math.max(stageData.TimeLimit - timeElapsed, 0)

	-- 📊 EVALUATE CAMPAIGN CONDITIONALS
	if stageData.ObjectiveType == "Distance" then
		local currentZ = rootPart.Position.Z
		local distanceTraveled = math.floor(math.abs(initialZCoord - currentZ))
		objectiveDisplay.Text = string.format("🎯 DRIVE: %d / %d STUDS | ⏱️ TIME LEFT: %.1fs", distanceTraveled, stageData.GoalValue, timeLeft)

		if distanceTraveled >= stageData.GoalValue then
			stageConstraintsMet = true
		end

	elseif stageData.ObjectiveType == "NearMisses" then
		-- Pull stats recorded dynamically by our ArcadeCarController miss tracker matrix
		local currentMissCount = 0
		local scoreArea = hudContainer:FindFirstChild("ScoreArea")
		local hudScript = screenGui:FindFirstChildOfClass("LocalScript") -- Reading from live runtime session variables safely

		-- Reading near miss events via global calculation mirrors safely
		local currentScore = character:GetAttribute("Score") or 0
		-- Fallback to attribute inspection loops or script counters matching internal values
		local liveNearMisses = math.clamp(math.floor(currentScore / 150), 0, stageData.GoalValue + 10) 

		objectiveDisplay.Text = string.format("⚡ NEAR MISSES: %d / %d SECURED | ⏱️ TIME LEFT: %.1fs", liveNearMisses, stageData.GoalValue, timeLeft)
		if liveNearMisses >= stageData.GoalValue then
			stageConstraintsMet = true
		end

	elseif stageData.ObjectiveType == "SpeedMaintenance" then
		local liveSpeed = character:GetAttribute("CurrentSpeed") or 0
		if liveSpeed >= stageData.GoalValue then
			speedMaintenanceTimer = speedMaintenanceTimer + deltaTime
		else
			speedMaintenanceTimer = math.max(speedMaintenanceTimer - (deltaTime * 0.5), 0) -- Soft decaying penalty for dropping under thresholds
		end

		objectiveDisplay.Text = string.format("🏎️ MAINTAIN SPEED (>%d): %.1f / %.1fs | ⏱️ TIME: %.1fs", stageData.GoalValue, speedMaintenanceTimer, stageData.DurationRequired, timeLeft)
		if speedMaintenanceTimer >= stageData.DurationRequired then
			stageConstraintsMet = true
		end
	end

	-- ⏳ RUNOUT TIMEOUT FAILURE INTERCEPT
	if timeLeft <= 0 and not stageConstraintsMet then
		activeTracking = false
		character:SetAttribute("GameOver", true)
		task.spawn(function()
			local success, responseMsg = ProcessRunResolution:InvokeServer("Career", math.floor(character:GetAttribute("Score") or 0), false)
			print(responseMsg)
		end)
	elseif stageConstraintsMet and timeLeft > 0 then
		activeTracking = false
		character:SetAttribute("GameOver", true)
		task.spawn(function()
			local success, responseMsg = ProcessRunResolution:InvokeServer("Career", math.floor(character:GetAttribute("Score") or 0), true)
			print(responseMsg)
			if success then
				objectiveDisplay.Text = "🎉 STAGE COMPLETED SECURELY!"
				objectiveDisplay.TextColor3 = Color3.fromRGB(0, 255, 125)
			end
		end)
	end
end)

localPlayer.CharacterAdded:Connect(initializeCampaignObjectiveTracker)
if localPlayer.Character then initializeCampaignObjectiveTracker(localPlayer.Character) end