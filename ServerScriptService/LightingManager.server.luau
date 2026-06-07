local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local function updateAllLights()
	-- Determine if it's night
	local isNight = (Lighting.ClockTime >= 17 or Lighting.ClockTime < 7)

	-- Get all tagged objects
	for _, lightBlock in pairs(CollectionService:GetTagged("TrafficLight")) do
		-- Handle logic
		local surfaceLight = lightBlock:FindFirstChildWhichIsA("SurfaceLight")

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