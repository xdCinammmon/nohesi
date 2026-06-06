local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera


-- 🎥 TUNED OFFSETS
local CAMERA_OFFSET_FORWARD = Vector3.new(0, 7.5, 24)
local LOOK_AT_OFFSET_FORWARD = Vector3.new(0, 0, -45)

-- 🔄 REAR VIEW OFFSETS (Flipped geometry when holding Space)
local CAMERA_OFFSET_REAR = Vector3.new(0, 7.5, -24)  -- Pushed in front of the car facing back
local LOOK_AT_OFFSET_REAR = Vector3.new(0, 0, 45)     -- Looking backward down the road

local BASE_FOV = 75
local MAX_SPEED_FOV = 100
local FOV_SNAP_SPEED = 18

-- 🛠️ VIBRATION PARAMETERS
local BASE_SPEED = 120
local SHAKE_INTENSITY_SCALER = 0.005 

-- 🔑 REAR-VIEW STATE TRACKER
local isLookingBack = false

-- Listen for the spacebar press/release events
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.Space then
		isLookingBack = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		isLookingBack = false
	end
end)

local function updateCamera(deltaTime)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local currentSpeed = character:GetAttribute("CurrentSpeed") or 90

	-- 1. FOV DYNAMICS
	local speedPercent = math.clamp((currentSpeed - BASE_SPEED) / 150, 0, 1)
	local targetFOV = BASE_FOV + (speedPercent * (MAX_SPEED_FOV - BASE_FOV))
	camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * (FOV_SNAP_SPEED * deltaTime)

	-- 3. STRICT SHAKE FLOOR
	local shakeX = 0
	local shakeY = 0

	if currentSpeed > 120.5 then
		local intensity = (currentSpeed - BASE_SPEED) * SHAKE_INTENSITY_SCALER
		shakeX = (math.random() - 0.5) * intensity * math.sin(os.clock() * 50)
		shakeY = (math.random() - 0.5) * intensity * math.cos(os.clock() * 50)
	end

	-- 4. DYNAMIC DIRECTION SYSTEM
	local activeCamOffset = CAMERA_OFFSET_FORWARD
	local activeLookOffset = LOOK_AT_OFFSET_FORWARD

	if isLookingBack then
		activeCamOffset = CAMERA_OFFSET_REAR
		activeLookOffset = LOOK_AT_OFFSET_REAR
	end

	-- 5. CAMERA ASSEMBLY
	-- Object-space translation transforms vector offsets relative to where the car is rotated
	local cameraPosition = rootPart.CFrame:PointToWorldSpace(activeCamOffset)
	local targetLookAt = rootPart.CFrame:PointToWorldSpace(activeLookOffset)

	local baseCFrame = CFrame.new(cameraPosition, targetLookAt)
	camera.CFrame = baseCFrame * CFrame.new(shakeX, shakeY, 0)
end

RunService.PreRender:Connect(updateCamera)