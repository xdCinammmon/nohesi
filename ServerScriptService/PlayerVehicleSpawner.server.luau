local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🎛️ CONFIGURATION SPAWN ANCHOR COORDINATES
-- Adjust these values to match the exact starting line vectors of your highway tracks!
local SOLO_START_CFRAME = CFrame.new(0, 5.5, 0)
local MULTIPLAYER_START_CFRAME = CFrame.new(0, 5.5, 0) -- Can change Z to a shared lobby node point if needed

-- 📁 MODULAR STORAGE REFERENCES
local PlayerModels = ReplicatedStorage:WaitForChild("PlayerModels")
local VehicleCatalog = require(ReplicatedStorage:WaitForChild("VehicleCatalog"))

-- 📡 REMOTE GATE INITIALIZATION
local networkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents") or Instance.new("Folder", ReplicatedStorage)
networkEvents.Name = "NetworkEvents"

local RequestVehicleSpawn = networkEvents:FindFirstChild("RequestVehicleSpawn") or Instance.new("RemoteEvent", networkEvents)
RequestVehicleSpawn.Name = "RequestVehicleSpawn"

-- 🛠️ CLEANED UP CONSTRUCTOR FUNCTION
local function attachVehicleBody(player, character)
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- 1. 🧹 CLEANUP OLD VEHICLE ASSETS (For mid-game garage swaps / restarts)
	local existingVehicle = character:FindFirstChild("EquippedVehicleBody")
	if existingVehicle then
		existingVehicle:Destroy()
	end

	-- Wipe out any old broken weld instances attached to the physics root
	for _, child in ipairs(rootPart:GetChildren()) do
		if child:IsA("WeldConstraint") and child.Name == "VehicleAnchorWeld" then
			child:Destroy()
		end
	end

	-- 2. 🗃️ FETCH CAR MODEL TEMPLATE
	local equippedCarId = player:GetAttribute("EquippedCar") or "BSedan"
	local masterTemplate = PlayerModels:FindFirstChild(equippedCarId)

	if not masterTemplate then
		warn("Vehicle Spawner could not locate storage asset matching ID: " .. tostring(equippedCarId))
		return
	end

	-- 3. 🛠️ CLONE AND SNAP VEHICLE PANEL ASSEMBLY
	local carClone = masterTemplate:Clone()
	carClone.Name = "EquippedVehicleBody"

	local carRoot = carClone.PrimaryPart or carClone:FindFirstChildByClass("BasePart")
	if not carRoot then
		warn("Vehicle template " .. equippedCarId .. " is missing an anchored PrimaryPart design!")
		carClone:Destroy()
		return
	end
	carClone.PrimaryPart = carRoot

	-- Teleport complete grouped assembly onto character skeleton tracking coordinate frame
	carClone:PivotTo(rootPart.CFrame)
	carClone.Parent = character

	-- 🔗 Create single master weld connecting the car model to the physics root block
	local anchorWeld = Instance.new("WeldConstraint")
	anchorWeld.Name = "VehicleAnchorWeld"
	anchorWeld.Part0 = rootPart
	anchorWeld.Part1 = carRoot
	anchorWeld.Parent = rootPart

	-- 4. ⚙️ INJECT LIVE PERFORMANCE VALUE CONFIGURATIONS
	local carData = VehicleCatalog.Cars and VehicleCatalog.Cars[equippedCarId] or (VehicleCatalog.GetCarData and VehicleCatalog.GetCarData(equippedCarId))

	if carData and carData.EngineValues then
		local valuesFolder = character:WaitForChild("Values")
		local maxSpeedObj = valuesFolder:FindFirstChild("MAX_SPEED")
		local accObj = valuesFolder:FindFirstChild("ACCELERATION_INDEX")
		local decObj = valuesFolder:FindFirstChild("DECELERATION_INDEX")
		local handlingObj = valuesFolder:FindFirstChild("HANDLING_INDEX")
		local rideHeightObj = valuesFolder:FindFirstChild("RIDE_HEIGHT")

		if maxSpeedObj then maxSpeedObj.Value = carData.EngineValues.TopSpeed end
		if accObj then accObj.Value = carData.EngineValues.AccelerationIndex end
		if decObj then decObj.Value = carData.EngineValues.DecelerationIndex end
		if handlingObj then handlingObj.Value = carData.EngineValues.HandlingIndex end
		if rideHeightObj then rideHeightObj.Value = carData.EngineValues.RideHeight or 5.5 end

		print("Performance configuration profiling successful for player: " .. player.Name .. " [" .. equippedCarId .. "]")
	end
end

-- 🏁 LIFECYCLE ROUTING CONNECTORS
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- 🟢 INITIALIZE MENUSTATE FLAGS
		character:SetAttribute("InMenu", true)
		character:SetAttribute("GameMode", "Solo") -- ✨ NEW: Safe fallback baseline starting profile

		if not player:GetAttribute("EquippedCar") then
			player:SetAttribute("EquippedCar", "BSedan")
		end
	end)

	-- 🔄 REAL-TIME MID-MENU PROFILE PREVIEW REFRESHER
	player:GetAttributeChangedSignal("EquippedCar"):Connect(function()
		local currentCharacter = player.Character
		if currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart") then
			if currentCharacter:GetAttribute("InMenu") == false then
				attachVehicleBody(player, currentCharacter)
			end
		end
	end)
end)

-- 📥 INBOUND NETWORK GATES: FIRE UPON MAIN MENU SPAWN OR RESTART BUTTON CLICKS
-- ============================================================================
-- CORRECTED ROUTINE: game.ServerScriptService.PlayerVehicleSpawner
-- LOCATION: RequestVehicleSpawn.OnServerEvent block
-- ============================================================================
RequestVehicleSpawn.OnServerEvent:Connect(function(player, selectedCarId)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		-- 🟢 FIX: THE "HARD-RESET"
		-- 1. Un-anchor and reset physics state before doing ANYTHING else
		rootPart.Anchored = false
		if humanoid then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

		-- 2. Set the position to the start frame BEFORE spawning the car
		local currentMode = character:GetAttribute("GameMode") or "Solo"
		local spawnCFrame = (currentMode == "Multiplayer") and MULTIPLAYER_START_CFRAME or SOLO_START_CFRAME

		rootPart.CFrame = spawnCFrame
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		-- 3. Transition UI State
		character:SetAttribute("InMenu", false)

		-- 4. Build the vehicle
		attachVehicleBody(player, character)

		print("🚀 Vehicle spawn successfully forced into physical world for: " .. player.Name)
	end
end)