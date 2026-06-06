local RunService = game:GetService("RunService")
local carModel = script.Parent

-- 🗂️ BULLETPROOF CACHE: Scans once at setup; completely immune to nested folders
local lightParts = {
	LeftBrakeLight = {},
	RightBrakeLight = {},
	BrakeLights = {},
	MainLights = {},
	LeftSignal = {},
	RightSignal = {}
}

for _, desc in ipairs(carModel:GetDescendants()) do
	if desc:IsA("BasePart") and lightParts[desc.Name] then
		table.insert(lightParts[desc.Name], desc)
	end
end

-- 🎨 REFINED COLOR PROFILES
local BRAKE_OFF_COLOR = Color3.fromRGB(30, 0, 0)       -- Completely off (dull dark plastic)
local RUNNING_LIGHT_COLOR = Color3.fromRGB(130, 15, 15)  -- ✨ FIXED: Distinct dimmer red for casual night cruising
local BRAKE_ON_COLOR = Color3.fromRGB(255, 20, 20)     -- Vibrant high-intensity neon red
local SIGNAL_ON_COLOR = Color3.fromRGB(255, 160, 0)    -- Bright amber neon
local SIGNAL_OFF_COLOR = Color3.fromRGB(45, 30, 0)     -- Dull amber housing

-- ⏱️ LOCAL INDICATOR FLASHER SYSTEM
local blinkOn = false
local BLINK_SPEED = 0.25
local lastBlinkToggle = 0

-- 🔄 UNIFIED LIGHT REFRESH MATRIX
local function updateVehicleVisuals()
	local isBraking = carModel:GetAttribute("BrakeLights") or carModel:GetAttribute("IsBraking") or false
	local headlightsOn = carModel:GetAttribute("HeadlightsOn") or false
	local highBeamsOn = carModel:GetAttribute("HighBeamsOn") or false
	local signalState = carModel:GetAttribute("SignalState") or "Off"

	-- 1. Render Brake Components (With fixed high-contrast night visibility)
	local function refreshBrakePart(part)
		local sLight = part:FindFirstChildOfClass("SurfaceLight")
		if isBraking then
			part.Color = BRAKE_ON_COLOR
			part.Material = Enum.Material.Neon
			if sLight then
				sLight.Enabled = true
				sLight.Brightness = headlightsOn and 16.0 or 8.0 
			end
		elseif headlightsOn then
			part.Color = RUNNING_LIGHT_COLOR -- ✨ Swapped to running tone for distinct brake pop
			part.Material = Enum.Material.Neon
			if sLight then
				sLight.Enabled = true
				sLight.Brightness = 1.5 
			end
		else
			part.Color = BRAKE_OFF_COLOR
			part.Material = Enum.Material.SmoothPlastic
			if sLight then sLight.Enabled = false end
		end
	end

	for _, p in ipairs(lightParts.LeftBrakeLight) do refreshBrakePart(p) end
	for _, p in ipairs(lightParts.RightBrakeLight) do refreshBrakePart(p) end
	for _, p in ipairs(lightParts.BrakeLights) do refreshBrakePart(p) end

	-- 2. Render Main Headlights & High Beams
	for _, part in ipairs(lightParts.MainLights) do
		local sLight = part:FindFirstChildOfClass("SurfaceLight")
		if highBeamsOn then
			part.Material = Enum.Material.Neon
			if sLight then sLight.Enabled = true; sLight.Brightness = 12.0 end
		elseif headlightsOn then
			part.Material = Enum.Material.Neon
			if sLight then sLight.Enabled = true; sLight.Brightness = 2.5 end
		else
			part.Material = Enum.Material.SmoothPlastic
			if sLight then sLight.Enabled = false end
		end
	end

	-- 3. Render Turn Signals
	for _, part in ipairs(lightParts.LeftSignal) do
		if (signalState == "Hazards" or signalState == "Left") and blinkOn then
			part.Color = SIGNAL_ON_COLOR
			part.Material = Enum.Material.Neon
		else
			part.Color = SIGNAL_OFF_COLOR
			part.Material = Enum.Material.SmoothPlastic
		end
	end

	for _, part in ipairs(lightParts.RightSignal) do
		if (signalState == "Hazards" or signalState == "Right") and blinkOn then
			part.Color = SIGNAL_ON_COLOR
			part.Material = Enum.Material.Neon
		else
			part.Color = SIGNAL_OFF_COLOR
			part.Material = Enum.Material.SmoothPlastic
		end
	end
end

-- 📡 LIFECYCLE LISTENERS
carModel:GetAttributeChangedSignal("BrakeLights"):Connect(updateVehicleVisuals)
carModel:GetAttributeChangedSignal("IsBraking"):Connect(updateVehicleVisuals)
carModel:GetAttributeChangedSignal("HeadlightsOn"):Connect(updateVehicleVisuals)
carModel:GetAttributeChangedSignal("HighBeamsOn"):Connect(updateVehicleVisuals)

carModel:GetAttributeChangedSignal("SignalState"):Connect(function()
	local signalState = carModel:GetAttribute("SignalState") or "Off"
	if signalState == "Off" then
		blinkOn = false -- ✨ RESET STATE: Guarantees blinkers start clean on selection
	end
	updateVehicleVisuals()
end)

-- ⏱️ RUNTIME BLINK TICKER HEARTBEAT
RunService.Heartbeat:Connect(function()
	local signalState = carModel:GetAttribute("SignalState") or "Off"
	if signalState ~= "Off" then
		local currentTime = os.clock()
		if currentTime - lastBlinkToggle >= BLINK_SPEED then
			lastBlinkToggle = currentTime
			blinkOn = not blinkOn
			updateVehicleVisuals() 
		end
	end
end)

-- Run initial paint cycle on setup loading
updateVehicleVisuals()