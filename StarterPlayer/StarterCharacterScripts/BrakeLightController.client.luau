local character = script.Parent

print("Searching for brake lights on vehicle chassis...")

-- Using a recursive WaitForChild loop to guarantee the parts have fully streamed in
local leftLight = character:WaitForChild("LeftBrakeLight", 10)
local rightLight = character:WaitForChild("RightBrakeLight", 10)

-- Deep scan fallback if they are nested inside a sub-folder or sub-model of the car
if not leftLight or not rightLight then
	for _, part in ipairs(character:GetDescendants()) do
		if part.Name == "LeftBrakeLight" then
			leftLight = part
		elseif part.Name == "RightBrakeLight" then
			rightLight = part
		end
	end
end

-- Final validation safety check
if not leftLight or not rightLight then
	warn("❌ Brake light parts could not be found within 10 seconds! Check your model hierarchy naming.")
	return
else
	print("✅ Brake lights successfully linked to controller framework.")
end

-- 🎨 LIGHT APPEARANCE CONFIG
local OFF_COLOR = Color3.fromRGB(120, 0, 0)       
local ON_COLOR = Color3.fromRGB(255, 30, 30)       

local OFF_MATERIAL = Enum.Material.SmoothPlastic
local ON_MATERIAL = Enum.Material.Neon

local function updateBrakeLights()
	local isBraking = character:GetAttribute("IsBraking")

	if isBraking then
		leftLight.Color = ON_COLOR
		leftLight.Material = ON_MATERIAL
		rightLight.Color = ON_COLOR
		rightLight.Material = ON_MATERIAL
	else
		leftLight.Color = OFF_COLOR
		leftLight.Material = OFF_MATERIAL
		rightLight.Color = OFF_COLOR
		rightLight.Material = OFF_MATERIAL
	end
end

-- Connect the listener matrix
character:GetAttributeChangedSignal("IsBraking"):Connect(updateBrakeLights)

-- Run an initial pass to match the current spawn state
updateBrakeLights()