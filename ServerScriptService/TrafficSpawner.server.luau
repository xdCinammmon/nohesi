local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrafficConfig = require(ReplicatedStorage:WaitForChild("TrafficConfig"))
local TrafficModels = ReplicatedStorage:WaitForChild("TrafficModels")

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
	return 1
end

local function spawnTrafficCar(targetZCoord)
	local targetProfile = getRandomVehicleProfile()
	local masterTemplate = TrafficModels:FindFirstChild(targetProfile.StoragePath)
	if not masterTemplate then return nil end

	local assignedLaneIndex = calculateTargetLaneIndex(targetProfile)
	local targetXPosition = TrafficConfig.LaneXPositions[assignedLaneIndex]

	local newCar = masterTemplate:Clone()
	newCar.Name = "TrafficCar"

	newCar:SetAttribute("VehicleClass", targetProfile.ClassName)
	newCar:SetAttribute("AssignedLane", assignedLaneIndex)

	-- Ensure the model has a primary part anchored to drive physics properties
	local root = newCar.PrimaryPart or newCar:FindFirstChildByClass("BasePart")
	if not root then
		warn("Traffic model missing base parts to drive physics paths!")
		newCar:Destroy()
		return nil
	end
	newCar.PrimaryPart = root

	-- Calculate orientation position matrix
	local spawnCFrame = CFrame.new(targetXPosition, 5.5, targetZCoord)
	newCar:PivotTo(spawnCFrame)

	-- 🏎️ FIXED: APPLY CONSTANT MOVEMENT FORCE TO GROUPED MODEL
	local attachment = Instance.new("Attachment")
	attachment.Name = "DriveAttachment"
	attachment.Parent = root

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DriveVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge -- Prevents heavy trucks from slowing down
	-- Force the car to drive forward down the negative Z axis
	linearVelocity.VectorVelocity = Vector3.new(0, 0, -65) 
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = root

	newCar.Parent = workspace
	return newCar
end

task.spawn(function()
	while true do
		task.wait(math.random(3, 6))
		spawnTrafficCar(-400) -- Spawn deep down the road track
	end
end)