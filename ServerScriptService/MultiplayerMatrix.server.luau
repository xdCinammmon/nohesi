-- Server Script inside ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- 📡 NETWORK EVENT INITIALIZATION
local NetworkEventsFolder = ReplicatedStorage:FindFirstChild("NetworkEvents") or Instance.new("Folder", ReplicatedStorage)
NetworkEventsFolder.Name = "NetworkEvents"

local UpdateInputEvent = NetworkEventsFolder:FindFirstChild("UpdateInput") or Instance.new("RemoteEvent", NetworkEventsFolder)
UpdateInputEvent.Name = "UpdateInput"

-- Global remote for light states replication
local CarLightEvent = ReplicatedStorage:FindFirstChild("CarLightEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
CarLightEvent.Name = "CarLightEvent"

local playerData = {}
local MIN_SPEED = 60

-- Track when a player joins
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local rootPart = character:WaitForChild("HumanoidRootPart")
		local valuesFolder = character:WaitForChild("Values")

		playerData[player.UserId] = {
			rootPart = rootPart,
			values = valuesFolder,
			moveDirection = 0,
			throttleDirection = 0,
			currentSpeed = 90, -- Matches BASE_FORWARD_SPEED on the client side
		}
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

-- 📥 Listen for individual input updates from clients
UpdateInputEvent.OnServerEvent:Connect(function(player, moveDirection, throttleDirection)
	local data = playerData[player.UserId]
	if data then
		data.moveDirection = moveDirection
		data.throttleDirection = throttleDirection
	end
end)

-- 📥 ✨ NEW: Listen for light event changes and stamp attributes onto characters
CarLightEvent.OnServerEvent:Connect(function(player, characterContainer, attributeName, value)
	-- Security Verification Check: Ensure players only alter their own vehicle assets
	if player.Character and player.Character == characterContainer then
		player.Character:SetAttribute(attributeName, value)
	end
end)

-- 🏎️ CENTRAL MULTIPLAYER HEARTBEAT SYNC LOOP
RunService.Heartbeat:Connect(function(deltaTime)
	for userId, data in pairs(playerData) do
		local rootPart = data.rootPart
		local values = data.values

		if rootPart and rootPart.Parent and values then
			-- 🔄 DYNAMIC PROFILE FETCHING: Pulls custom catalog limits from the car's folder
			local maxSpeedObj = values:FindFirstChild("MAX_SPEED")
			local accObj = values:FindFirstChild("ACCELERATION_INDEX")
			local decObj = values:FindFirstChild("DECELERATION_INDEX")

			local maxSpeed = maxSpeedObj and maxSpeedObj.Value or 220
			local accIndex = accObj and accObj.Value or 120
			local decIndex = decObj and decObj.Value or 180
			local baseForwardSpeed = 90

			-- 🔄 SYNCED DYNAMIC TORQUE SIMULATION ENGINE
			if data.throttleDirection == 1 then
				-- Matches client non-linear curve calculations perfectly
				local speedDeficitRatio = (maxSpeed - data.currentSpeed) / (maxSpeed - MIN_SPEED)
				local dynamicEnginePush = math.max(speedDeficitRatio, 0.08)

				data.currentSpeed = math.min(data.currentSpeed + (accIndex * dynamicEnginePush * deltaTime), maxSpeed)
			elseif data.throttleDirection == -1 then
				data.currentSpeed = math.max(data.currentSpeed - (decIndex * deltaTime), MIN_SPEED)
			else
				-- Captures your custom momentum decay sliders per car
				local decayRate = values:FindFirstChild("MOMENTUM_DECAY") and values.MOMENTUM_DECAY.Value or 60
				if data.currentSpeed > baseForwardSpeed then
					data.currentSpeed = math.max(data.currentSpeed - (decayRate * deltaTime), baseForwardSpeed)
				elseif data.currentSpeed < baseForwardSpeed then
					data.currentSpeed = math.min(data.currentSpeed + (decayRate * deltaTime), baseForwardSpeed)
				end
			end

			-- Replicate calculated real-time tracking speed onto the character container
			rootPart.Parent:SetAttribute("CurrentSpeed", data.currentSpeed)
		end
	end
end)