local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- 📁 AUTOMATED HIERARCHY INITIALIZATION
local generatedContent = Workspace:FindFirstChild("GeneratedContent")
if not generatedContent then
	generatedContent = Instance.new("Folder")
	generatedContent.Name = "GeneratedContent"
	generatedContent.Parent = Workspace
end

local chunksFolder = generatedContent:FindFirstChild("Chunks")
if not chunksFolder then
	chunksFolder = Instance.new("Folder")
	chunksFolder.Name = "Chunks"
	chunksFolder.Parent = generatedContent
end

local trafficFolder = generatedContent:FindFirstChild("Traffic")
if not trafficFolder then
	trafficFolder = Instance.new("Folder")
	trafficFolder.Name = "Traffic"
	trafficFolder.Parent = generatedContent
end

-- 📁 MODULAR STORAGE REFERENCES
local chunkTemplate = ReplicatedStorage:WaitForChild("HighwayChunk")
local TrafficModels = ReplicatedStorage:WaitForChild("TrafficModels")
local TrafficConfig = require(ReplicatedStorage:WaitForChild("TrafficConfig"))

local CHUNK_LENGTH = 200 
local activeChunks = {}
local activeTraffic = {} 
local lastSpawnTime = 0 

-- 🛣️ MASTER HIGHWAY LAYOUT CONFIG
-- [1] Fast Passing Lane, [2] Mid-Fast, [3] Mid-Slow, [4] Slow Truck Lane
local LANES = {-29, -8, 8, 29} 
local DENSITY_PER_PLAYER = 18   
local SPAWN_RADIUS = 700       
local MIN_SPAWN_DIST_AHEAD = 250
local MAX_SPAWN_DIST_AHEAD = 950
local MIN_GAP_BETWEEN_CARS = 40
local TRAFFIC_SPAWN_Y = 5.2
local SPAWN_COOLDOWN = 0.2

local LANE_CHANGE_SPEED = 2.5 

-- 🎚️ VARIANCE CONFIGURATION
local MAX_LANE_DRIFT = 3 -- Max studs a car can wander left or right from lane center

local LANE_SPEEDS = {
	[-29] = 140, -- Lane 1: Far Left (Fast)
	[-8]  = 110, -- Lane 2: Mid-Left
	[8]   = 90,  -- Lane 3: Mid-Right
	[29]  = 70   -- Lane 4: Far Right (Slow Truck Lane)
}

-- 🎲 WEIGHTED SELECTION ENGINE FUNCTIONS
local function getRandomVehicleProfile()
	local totalWeight = 0
	for _, profile in ipairs(TrafficConfig.VehiclePool) do
		totalWeight = totalWeight + profile.Weight
	end

	local rolledValue = math.random(1, totalWeight)
	local currentCounter = 0

	for _, profile in ipairs(TrafficConfig.VehiclePool) do
		currentCounter = currentCounter + profile.Weight
		if rolledValue <= currentCounter then
			return profile
		end
	end
	return TrafficConfig.VehiclePool[1]
end

local function calculateTargetLaneIndex(profile)
	local laneWeights = profile.LaneWeights
	local totalLaneWeight = 0
	for _, weight in pairs(laneWeights) do
		totalLaneWeight = totalLaneWeight + weight
	end

	local rolledValue = math.random(1, totalLaneWeight)
	local currentCounter = 0

	for laneIndex, weight in pairs(laneWeights) do
		currentCounter = currentCounter + weight
		if rolledValue <= currentCounter then
			return laneIndex
		end
	end
	return #LANES -- Fallback to slow lane
end

-- 🛠️ MODULAR VEHICLE CONSTRUCTOR
local function createTrafficCar(spawnX, spawnZ, templateModel, className)
	local trafficClone = templateModel:Clone()
	trafficClone.Name = "TrafficCar"

	-- Dynamic speed profiling based on physical location assignment
	local constantLaneSpeed = 90
	local closestDist = math.huge
	for laneX, speed in pairs(LANE_SPEEDS) do
		local dist = math.abs(spawnX - laneX)
		if dist < closestDist then
			closestDist = dist
			constantLaneSpeed = speed
		end
	end

	-- Initialize required attributes for replication and driving loops
	trafficClone:SetAttribute("Speed", constantLaneSpeed)
	trafficClone:SetAttribute("MaxSpeed", constantLaneSpeed)
	trafficClone:SetAttribute("VehicleClass", className)
	trafficClone:SetAttribute("SignalState", "Off")
	trafficClone:SetAttribute("IsBraking", false)

	trafficClone:PivotTo(CFrame.new(spawnX, TRAFFIC_SPAWN_Y, spawnZ))
	trafficClone.Parent = trafficFolder -- 🔄 ROUTED TO TRAFFIC FOLDER
	table.insert(activeTraffic, trafficClone)
end

local function spawnChunk(zOffset)
	local newChunk = chunkTemplate:Clone()
	local roadBed = newChunk:FindFirstChild("RoadBed")
	if roadBed then
		local currentPivot = newChunk:GetPivot()
		local offsetFromRoadToPivot = roadBed.CFrame:Inverse() * currentPivot
		newChunk:PivotTo(CFrame.new(0, 0, zOffset) * offsetFromRoadToPivot)
	else
		newChunk:PivotTo(CFrame.new(0, 0, zOffset))
	end
	newChunk.Parent = chunksFolder -- 🔄 ROUTED TO CHUNKS FOLDER
	table.insert(activeChunks, newChunk)
end

-- 📡 NETWORK LISTENERS
-- ============================================================================
-- UPGRADED ROUTINE: game.ServerScriptService.WorldGenerator
-- LOCATION: Network Listeners Section (Lines 103+)
-- ============================================================================
-- 📡 NETWORK LISTENERS
local ToggleLightsEvent = ReplicatedStorage:FindFirstChild("ToggleLights") or Instance.new("RemoteEvent", ReplicatedStorage)
ToggleLightsEvent.Name = "ToggleLights"

ToggleLightsEvent.OnServerEvent:Connect(function(player, attributeName, value)
	if player.Character then 
		player.Character:SetAttribute(attributeName, value) 

		-- 🟢 NEW: Server-Side Velocity Counter-Measure
		-- If a player pauses, instantly drop their calculated network speed index
		if attributeName == "IsPaused" and value == true then
			player.Character:SetAttribute("CurrentSpeed", 0)
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
			end
		end
	end
end)

-- 🏁 SERVER HEARTBEAT LOOP
RunService.Heartbeat:Connect(function(deltaTime)
	local allPlayers = Players:GetPlayers()
	if #allPlayers == 0 then return end

	-- 1. ZONE STREAMING MECHANICS
	local chunksRequired = {}
	for _, player in ipairs(allPlayers) do
		local char = player.Character
		if not char then continue end

		-- 🛡️ SAFEGUARD ADDITION: If they are browsing your shop tabs, pass over them!
		if char:GetAttribute("InMenu") == true then continue end

		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local pZ = player.Character.HumanoidRootPart.Position.Z
			local currentGridZ = math.floor(pZ / CHUNK_LENGTH) * CHUNK_LENGTH
			for i = -2, 4 do 
				chunksRequired[currentGridZ - (i * CHUNK_LENGTH)] = true 
			end
		end
	end

	-- Cleanup unused chunks & orphaned traffic
	for i = #activeChunks, 1, -1 do
		local chunk = activeChunks[i]
		local chunkZ = chunk:GetPivot().Position.Z
		local isNeeded = false
		for zCoord, _ in pairs(chunksRequired) do
			if math.abs(chunkZ - zCoord) < 5 then isNeeded = true; break end
		end
		if not isNeeded then
			table.remove(activeChunks, i):Destroy()
			for j = #activeTraffic, 1, -1 do
				local tCar = activeTraffic[j]
				if tCar and tCar.Parent and math.abs(tCar:GetPivot().Position.Z - chunkZ) < (CHUNK_LENGTH / 2) then
					tCar:Destroy()
					table.remove(activeTraffic, j)
				end
			end
		end
	end

	-- Spawn missing chunks
	for zCoord, _ in pairs(chunksRequired) do
		local exists = false
		for _, chunk in ipairs(activeChunks) do
			if math.abs(chunk:GetPivot().Position.Z - zCoord) < 5 then exists = true; break end
		end
		if not exists then spawnChunk(zCoord) end
	end

	-- 2. LOCALIZED MULTI-VARIANT TRAFFIC GENERATION
	for _, player in ipairs(allPlayers) do
		local char = player.Character
		if not char then continue end

		-- 🛡️ ADD THIS CRITICAL SAFEGUARD LINE HERE:
		if char:GetAttribute("InMenu") == true then continue end -- Completely halts traffic loops for menu browsers

		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then continue end

		local playerX = rootPart.Position.X
		local playerZ = rootPart.Position.Z

		-- High Beam Evade Trigger
		if char:GetAttribute("HighBeamsOn") then
			local closestCarAhead = nil
			local closestDistance = 200 

			for _, tCar in ipairs(activeTraffic) do
				if tCar and tCar.Parent and not tCar:GetAttribute("TargetLaneX") and not tCar:GetAttribute("IsPanicking") then
					local carPivot = tCar:GetPivot()
					local laneMatch = math.abs(carPivot.Position.X - playerX) < 6 
					local isAhead = carPivot.Position.Z < playerZ 

					if laneMatch and isAhead then
						local distance = math.abs(carPivot.Position.Z - playerZ)
						if distance < closestDistance then
							closestDistance = distance
							closestCarAhead = tCar
						end
					end
				end
			end

			if closestCarAhead then
				closestCarAhead:SetAttribute("IsPanicking", true)
				task.spawn(function()
					if not closestCarAhead or not closestCarAhead.Parent then return end

					local currentLaneX = closestCarAhead:GetPivot().Position.X
					local currentLaneIndex = 1
					local trackingDist = math.huge
					for i, laneX in ipairs(LANES) do
						local dist = math.abs(currentLaneX - laneX)
						if dist < trackingDist then
							trackingDist = dist
							currentLaneIndex = i
						end
					end

					local chosenTargetX = nil
					if currentLaneIndex == 1 then
						chosenTargetX = LANES[2]
						closestCarAhead:SetAttribute("SignalState", "Right")
					elseif currentLaneIndex == #LANES then
						chosenTargetX = LANES[#LANES - 1]
						closestCarAhead:SetAttribute("SignalState", "Left")
					else
						chosenTargetX = LANES[currentLaneIndex + 1]
						closestCarAhead:SetAttribute("SignalState", "Right")
					end

					task.wait(0.6)

					if closestCarAhead and closestCarAhead.Parent then
						local targetLaneIsClear = true
						local myZ = closestCarAhead:GetPivot().Position.Z

						for _, otherCar in ipairs(activeTraffic) do
							if otherCar ~= closestCarAhead and otherCar.Parent then
								local otherPivot = otherCar:GetPivot()
								local isInTargetLane = math.abs(otherPivot.Position.X - chosenTargetX) < 4 or otherCar:GetAttribute("TargetLaneX") == chosenTargetX

								if isInTargetLane and math.abs(otherPivot.Position.Z - myZ) < 45 then
									targetLaneIsClear = false
									break
								end
							end
						end

						if targetLaneIsClear then
							closestCarAhead:SetAttribute("TargetLaneX", chosenTargetX)
							local targetSpeedProfile = LANE_SPEEDS[chosenTargetX] or 90
							closestCarAhead:SetAttribute("Speed", targetSpeedProfile)
							closestCarAhead:SetAttribute("MaxSpeed", targetSpeedProfile)
						else
							closestCarAhead:SetAttribute("SignalState", "Off")
						end
					end

					task.wait(1.5)
					if closestCarAhead and closestCarAhead.Parent then
						closestCarAhead:SetAttribute("IsPanicking", false)
					end
				end)
			end
		end

		-- Bubble Density Counter
		local localTrafficCount = 0
		for _, tCar in ipairs(activeTraffic) do
			if tCar and tCar.Parent then
				local dist = (tCar:GetPivot().Position - rootPart.Position).Magnitude
				if dist < SPAWN_RADIUS then localTrafficCount = localTrafficCount + 1 end
			end
		end

		-- Weighted Multi-Variant Spawning Gate
		if localTrafficCount < DENSITY_PER_PLAYER and (os.clock() - lastSpawnTime >= SPAWN_COOLDOWN) then
			local targetSpawnZ = playerZ - math.random(MIN_SPAWN_DIST_AHEAD, MAX_SPAWN_DIST_AHEAD)

			local targetProfile = getRandomVehicleProfile()
			local masterTemplate = TrafficModels:FindFirstChild(targetProfile.StoragePath)

			if masterTemplate then
				local assignedLaneIndex = calculateTargetLaneIndex(targetProfile)
				local baseLaneX = LANES[assignedLaneIndex]

				local driftRange = math.floor(MAX_LANE_DRIFT * 10)
				local laneVariance = math.random(-driftRange, driftRange) / 10 

				local targetSpawnX = baseLaneX + laneVariance

				-- Clearance check radar
				local isClear = true
				for _, c in ipairs(activeTraffic) do
					if c and c.Parent then
						local cPivot = c:GetPivot()
						local lateralDist = math.abs(cPivot.Position.X - targetSpawnX)
						local longitudinalDist = math.abs(cPivot.Position.Z - targetSpawnZ)

						if lateralDist < 9.0 and longitudinalDist < MIN_GAP_BETWEEN_CARS then
							isClear = false
							break
						end
					end
				end

				if isClear then
					createTrafficCar(targetSpawnX, targetSpawnZ, masterTemplate, targetProfile.ClassName)
					lastSpawnTime = os.clock()
				end
			end
		end
	end

	-- 3. TRAFFIC MOVEMENT ENGINE & SMOOTH TRANSITIONS
	for i = #activeTraffic, 1, -1 do
		local tCar = activeTraffic[i]
		if tCar and tCar.Parent then
			local speed = tCar:GetAttribute("Speed") or 90
			local currentPivot = tCar:GetPivot()
			local nextCFrame = currentPivot * CFrame.new(0, 0, -speed * deltaTime)
			local targetX = currentPivot.Position.X

			local targetLaneAttr = tCar:GetAttribute("TargetLaneX")
			if targetLaneAttr then
				local currentX = currentPivot.Position.X
				targetX = currentX + (targetLaneAttr - currentX) * (LANE_CHANGE_SPEED * deltaTime)

				if math.abs(targetX - targetLaneAttr) < 0.1 then
					targetX = targetLaneAttr
					tCar:SetAttribute("TargetLaneX", nil)
					tCar:SetAttribute("SignalState", "Off") 
				end
			end

			tCar:PivotTo(CFrame.new(Vector3.new(targetX, TRAFFIC_SPAWN_Y, nextCFrame.Position.Z)) * currentPivot.Rotation)
		else
			table.remove(activeTraffic, i)
		end
	end
end)