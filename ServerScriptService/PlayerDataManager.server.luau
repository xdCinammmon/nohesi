local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 📡 Modular Framework Links
local VehicleCatalog = require(ReplicatedStorage:WaitForChild("VehicleCatalog"))

-- 💾 Master Cloud Storage Bucket
local PlayerDataStore = DataStoreService:GetDataStore("DrivingGame_SaveSystem_v2")

-- ⚙️ FACTORY BASELINE PROFILE SCHEMA
local DEFAULT_DATA = {
	Cash = 5000,
	CareerScore = 0,
	Level = 1,
	CurrentCountry = 1,
	CurrentStage = 1,
	EquippedCar = "BSedan",
	UnlockedCars = {"BSedan"}
}

-- 📈 EXPERIENCE SCALING FORMULA
-- Calculates career experience point thresholds exponentially
local function getXPRequirement(currentLevel)
	return currentLevel * 7500
end

-- 🛠️ HELPER: Pack player session variables back into a save schema array
local function compilePlayerData(player)
	local ownedCarsFolder = player:FindFirstChild("OwnedCars")
	local unlockedList = {}

	if ownedCarsFolder then
		for _, child in ipairs(ownedCarsFolder:GetChildren()) do
			if child:IsA("StringValue") then
				table.insert(unlockedList, child.Value)
			end
		end
	end

	return {
		Cash = player:GetAttribute("Cash") or DEFAULT_DATA.Cash,
		CareerScore = player:GetAttribute("CareerScore") or DEFAULT_DATA.CareerScore,
		Level = player:GetAttribute("Level") or DEFAULT_DATA.Level,
		CurrentCountry = player:GetAttribute("CurrentCountry") or DEFAULT_DATA.CurrentCountry,
		CurrentStage = player:GetAttribute("CurrentStage") or DEFAULT_DATA.CurrentStage,
		EquippedCar = player:GetAttribute("EquippedCar") or DEFAULT_DATA.EquippedCar,
		UnlockedCars = unlockedList
	}
end

-- 📥 LOAD SEAMLESS DATA PIPELINES
local function onPlayerAdded(player)
	local playerKey = "Player_" .. player.UserId

	local ownedCarsFolder = Instance.new("Folder")
	ownedCarsFolder.Name = "OwnedCars"
	ownedCarsFolder.Parent = player

	local success, savedData = pcall(function()
		return PlayerDataStore:GetAsync(playerKey)
	end)

	if not success or not savedData then
		savedData = DEFAULT_DATA
		if not success then
			warn("Cloud database timeout for user " .. player.Name .. ". Applying local fail-safe cache profiles.")
		end
	end

	-- 🟢 INITIALIZE NETWORK ATTRIBUTE CORES
	player:SetAttribute("Cash", savedData.Cash or DEFAULT_DATA.Cash)
	player:SetAttribute("CareerScore", savedData.CareerScore or DEFAULT_DATA.CareerScore)
	player:SetAttribute("Level", savedData.Level or DEFAULT_DATA.Level)
	player:SetAttribute("CurrentCountry", savedData.CurrentCountry or DEFAULT_DATA.CurrentCountry)
	player:SetAttribute("CurrentStage", savedData.CurrentStage or DEFAULT_DATA.CurrentStage)
	player:SetAttribute("EquippedCar", savedData.EquippedCar or DEFAULT_DATA.EquippedCar)

	-- Populate local inventory catalog frame folders
	local unlockedTable = savedData.UnlockedCars or DEFAULT_DATA.UnlockedCars
	for _, carId in ipairs(unlockedTable) do
		if not ownedCarsFolder:FindFirstChild(carId) then
			local stringValue = Instance.new("StringValue")
			stringValue.Name = carId
			stringValue.Value = carId
			stringValue.Parent = ownedCarsFolder
		end
	end

	-- 📊 AUTO EXPERIENCE ATTRIBUTE WATCHER
	player:GetAttributeChangedSignal("CareerScore"):Connect(function()
		local scoreValue = player:GetAttribute("CareerScore") or 0
		local currentLevel = player:GetAttribute("Level") or 1

		while scoreValue >= getXPRequirement(currentLevel) do
			currentLevel = currentLevel + 1
			player:SetAttribute("Level", currentLevel)
			print("🎉 LEVEL UP! " .. player.Name .. " reached Level " .. tostring(currentLevel))
		end
	end)

	print("Successfully mounted progression game profile for user: " .. player.Name)
end

local function onPlayerRemoving(player)
	local playerKey = "Player_" .. player.UserId
	local dataPayload = compilePlayerData(player)

	local success, err = pcall(function()
		PlayerDataStore:SetAsync(playerKey, dataPayload)
	end)

	if not success then
		warn("CRITICAL: Cloud save failed for user " .. player.Name .. ". Error: " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)

-- ============================================================================
-- 📡 EXPLOIT-SAFE MULTIPLAYER GARAGE BRIDGE NETWORK RECEIVER
-- ============================================================================
local GarageRemote = ReplicatedStorage:FindFirstChild("GarageRemote") or Instance.new("RemoteFunction", ReplicatedStorage)
GarageRemote.Name = "GarageRemote"

GarageRemote.OnServerInvoke = function(player, actionType, requestedCarId)
	if not VehicleCatalog.DoesCarExist(requestedCarId) then return false, "Invalid Car Identification Key" end

	local ownedCarsFolder = player:WaitForChild("OwnedCars")
	local playerCash = player:GetAttribute("Cash") or 0
	local carData = VehicleCatalog.GetCarData(requestedCarId)

	if actionType == "Equip" then
		if ownedCarsFolder:FindFirstChild(requestedCarId) then
			player:SetAttribute("EquippedCar", requestedCarId)
			return true, "Successfully equipped " .. carData.DisplayName
		else
			return false, "You do not own this vehicle!"
		end

	elseif actionType == "Buy" then
		if ownedCarsFolder:FindFirstChild(requestedCarId) then
			return false, "You already own this vehicle!"
		end

		if playerCash >= carData.Price then
			player:SetAttribute("Cash", playerCash - carData.Price)

			local stringValue = Instance.new("StringValue")
			stringValue.Name = requestedCarId
			stringValue.Value = requestedCarId
			stringValue.Parent = ownedCarsFolder

			player:SetAttribute("EquippedCar", requestedCarId)
			return true, "Successfully purchased " .. carData.DisplayName .. "!"
		else
			return false, "Insufficient funds!"
		end
	end
	return false, "Unknown instruction network packet."
end

-- ============================================================================
-- 📥 ✨ NEW: RUN RESOLUTION NETWORK INTERFACE ENGINE
-- ============================================================================
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ProcessRunResolution = Instance.new("RemoteFunction")
ProcessRunResolution.Name = "ProcessRunResolution"
ProcessRunResolution.Parent = NetworkEvents

-- ============================================================================
-- REPLACEMENT ROUTINE: game.ServerScriptService.PlayerDataManager (Lines 133+)
-- ============================================================================
ProcessRunResolution.OnServerInvoke = function(player, runMode, finalScore, constraintsMet)
	local character = player.Character
	if not character then return false, "No tracking character active" end

	local cashEarned = 0
	local msg = ""

	if runMode == "Endless" then
		cashEarned = math.floor(finalScore / 100)

		local currentCash = player:GetAttribute("Cash") or 0
		local currentCareerScore = player:GetAttribute("CareerScore") or 0

		player:SetAttribute("Cash", currentCash + cashEarned)
		player:SetAttribute("CareerScore", currentCareerScore + finalScore)

		msg = "Endless Run Finalized!\n+" .. tostring(cashEarned) .. " Cash added to profile bank."
		return true, msg

	elseif runMode == "Career" then
		local currentCountry = player:GetAttribute("CurrentCountry") or 1
		local currentStage = player:GetAttribute("CurrentStage") or 1

		local countryConfig = ProgressionConfig.Campaign[currentCountry]
		if not countryConfig then return false, "Invalid campaign tracking boundary sector lookup" end

		local stageConfig = countryConfig.Stages[currentStage]
		if not stageConfig then return false, "Target stage objective specifications do not exist" end

		if constraintsMet then
			-- Award configuration defined variables cleanly instead of constant dummy values
			local coinPayout = stageConfig.CoinReward or 500
			local scorePayout = stageConfig.ScoreReward or 2000

			local currentCash = player:GetAttribute("Cash") or 0
			local currentCareerScore = player:GetAttribute("CareerScore") or 0

			player:SetAttribute("Cash", currentCash + coinPayout)
			player:SetAttribute("CareerScore", currentCareerScore + scorePayout)

			-- Advance index progression map
			if currentStage < #countryConfig.Stages then
				player:SetAttribute("CurrentStage", currentStage + 1)
				msg = string.format("Stage Passed!\n+%d Cash / +%d Score. Next stage unlocked.", coinPayout, scorePayout)
			else
				-- Wrap around maps or scale to next country context array blocks cleanly
				if ProgressionConfig.Campaign[currentCountry + 1] then
					player:SetAttribute("CurrentCountry", currentCountry + 1)
					player:SetAttribute("CurrentStage", 1)
					msg = string.format("Country Completed! Welcome to %s.\n+%d Completion Payout Awarded.", ProgressionConfig.Campaign[currentCountry + 1].CountryName, coinPayout)
				else
					player:SetAttribute("CurrentStage", currentStage + 1) -- Keep incrementing index metrics out
					msg = "🎉 MASTER CAMPAIGN COMPLETION! You've conquered every highway sector globally!"
				end
			end
			return true, msg
		else
			msg = "Stage Failed! Required milestones were not reached inside limits."
			return false, msg
		end
	end

	return false, "Invalid payload context frame type identifiers."
end