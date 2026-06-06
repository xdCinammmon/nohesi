local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ObjectPooler = require(ServerScriptService.ObjectPooler)
local TrafficConfig = require(ReplicatedStorage.TrafficConfig)
local TrafficModels = ReplicatedStorage:WaitForChild("TrafficModels")

local TrafficContainer = Workspace:FindFirstChild("Traffic") or Instance.new("Folder", Workspace)
TrafficContainer.Name = "Traffic"

-- 1. Initialize Pool with all defined vehicle types
for _, profile in ipairs(TrafficConfig.VehiclePool) do
	local template = TrafficModels:FindFirstChild(profile.StoragePath)
	if template then
		ObjectPooler:Initialize(template)
	end
end

-- Function to setup physics on a retrieved car
local function configurePhysics(model)
	local root = model.PrimaryPart
	local attachment = root:FindFirstChild("DriveAttachment") or Instance.new("Attachment")
	attachment.Name = "DriveAttachment"
	attachment.Parent = root

	local linearVelocity = root:FindFirstChild("DriveVelocity") or Instance.new("LinearVelocity")
	linearVelocity.Name = "DriveVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge 
	linearVelocity.VectorVelocity = Vector3.new(0, 0, -65) -- Constant movement
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Enabled = true -- Ensure it's active
	linearVelocity.Parent = root
end

local function spawnTrafficCar(targetZCoord)
	local profile = TrafficConfig.GetRandomVehicleProfile() -- Assume this returns a table
	local car = ObjectPooler:Get(profile.StoragePath)

	if not car then return end

	-- Apply setup
	car:SetAttribute("VehicleClass", profile.ClassName)
	configurePhysics(car)

	-- Position
	local assignedLaneIndex = TrafficConfig.CalculateTargetLaneIndex(profile)
	local targetXPosition = TrafficConfig.LaneXPositions[assignedLaneIndex]
	car:PivotTo(CFrame.new(targetXPosition, 5.5, targetZCoord))

	car.Parent = TrafficContainer

	-- 🔄 Lifecycle: Return to pool after passing the player
	task.spawn(function()
		-- Wait until car is far behind the player (e.g., Z > 200)
		-- Adjust the threshold based on your road length
		while car:GetPivot().Position.Z < 200 do
			task.wait(1)
		end

		car.Parent = ServerStorage -- Back to the pool
		ObjectPooler:Return(car)
	end)
end

-- Main Spawning Loop
task.spawn(function()
	while true do
		task.wait(math.random(TrafficConfig.MinSpawnDelay, TrafficConfig.MaxSpawnDelay))
		spawnTrafficCar(-400) 
	end
end)