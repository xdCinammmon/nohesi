local lighting = game:GetService("Lighting")
local surfaceLight = script.Parent
local lightBlock = script.Parent.Parent

local function updateLighting()
	-- 🌙 Logic fix: Night is NOT (Between 6 AM and 6 PM)
	-- So, if time is > 18 OR < 6, it is officially night time.
	if lighting.ClockTime >= 17 or lighting.ClockTime < 7 then
		surfaceLight.Enabled = true
		lightBlock.Material = Enum.Material.Neon
		lightBlock.Color = Color3.fromRGB(255, 255, 0) -- Use FromRGB for standard 0-255 colors
	else
		surfaceLight.Enabled = false
		lightBlock.Material = Enum.Material.SmoothPlastic -- Fixed: Material property, not Color
		lightBlock.Color = Color3.fromRGB(226, 155, 64)
	end
end

-- Run it once immediately so it works when the game starts
updateLighting()

-- ⏱️ Listen for time changes so the lights turn on automatically as it gets dark
lighting:GetPropertyChangedSignal("ClockTime"):Connect(updateLighting)