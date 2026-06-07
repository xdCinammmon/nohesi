local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local function updateAllLights()
	-- Debugging the ClockTime and the boolean state
	local isNight = (Lighting.ClockTime >= 17 or Lighting.ClockTime < 7)

	print("--- Light Sync Debug ---")
	print("Current ClockTime: " .. tostring(Lighting.ClockTime))
	print("Is it Night? " .. tostring(isNight))

	local taggedLights = CollectionService:GetTagged("TrafficLamp")
	print("Found " .. #taggedLights .. " lights to update.")

	for _, lightBlock in pairs(taggedLights) do
		local surfaceLight = lightBlock:FindFirstChildWhichIsA("SurfaceLight", true)

		if surfaceLight then
			surfaceLight.Enabled = isNight
		end

		lightBlock.Material = isNight and Enum.Material.Neon or Enum.Material.SmoothPlastic
		lightBlock.Color = isNight and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(226, 155, 64)
	end
end

-- Listen for time changes
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateAllLights)

-- Run once on startup
updateAllLights()