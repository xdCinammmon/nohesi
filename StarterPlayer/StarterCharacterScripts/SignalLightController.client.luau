local character = script.Parent
local leftSignal = character:WaitForChild("LeftSignal", 10)
local rightSignal = character:WaitForChild("RightSignal", 10)

if not leftSignal or not rightSignal then
	warn("⚠️ Indicator signal parts not found! Ensure naming matches 'LeftSignal' and 'RightSignal' exactly.")
	return
end

-- 🎨 SIGNAL COLOR MATRIX
local OFF_COLOR = Color3.fromRGB(130, 75, 0)      -- Dim Amber
local ON_COLOR = Color3.fromRGB(255, 165, 0)      -- Bright Neon Orange

local OFF_MATERIAL = Enum.Material.SmoothPlastic
local ON_MATERIAL = Enum.Material.Neon

local blinkLoopActive = false

local function setLightState(part, turnOn)
	if turnOn then
		part.Color = ON_COLOR
		part.Material = ON_MATERIAL
	else
		part.Color = OFF_COLOR
		part.Material = OFF_MATERIAL
	end
end

-- Async Coroutine to run blinking animations seamlessly alongside physics
local function runBlinkerEngine()
	if blinkLoopActive then return end
	blinkLoopActive = true

	while blinkLoopActive do
		local currentState = character:GetAttribute("SignalState") or "Off"

		if currentState == "Off" then
			blinkLoopActive = false
			setLightState(leftSignal, false)
			setLightState(rightSignal, false)
			break
		end

		-- 💡 BLINK ON STAGE
		if currentState == "Left" then
			setLightState(leftSignal, true)
		elseif currentState == "Right" then
			setLightState(rightSignal, true)
		elseif currentState == "Hazards" then
			setLightState(leftSignal, true)
			setLightState(rightSignal, true)
		end

		task.wait(0.3) -- Blink timing window

		-- 💡 BLINK OFF STAGE
		setLightState(leftSignal, false)
		setLightState(rightSignal, false)

		task.wait(0.3)
	end
end

character:GetAttributeChangedSignal("SignalState"):Connect(function()
	local state = character:GetAttribute("SignalState")
	if state ~= "Off" then
		task.spawn(runBlinkerEngine)
	else
		blinkLoopActive = false
		setLightState(leftSignal, false)
		setLightState(rightSignal, false)
	end
end)