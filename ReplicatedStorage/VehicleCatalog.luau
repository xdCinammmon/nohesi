local VehicleCatalog = {}

-- 🏷️ VEHICLE RARITY TYPEDEFS (Used for UI text styling & card backgrounds)
VehicleCatalog.Rarities = {
	Common = { Name = "Common", Color = Color3.fromRGB(150, 150, 150) },
	Uncommon = { Name = "Uncommon", Color = Color3.fromRGB(85, 255, 127) },
	Rare = { Name = "Rare", Color = Color3.fromRGB(85, 170, 255) },
	Exotic = { Name = "Exotic", Color = Color3.fromRGB(255, 85, 255) }
}

-- 🚘 THE VEHICLE DATA MATRIX
VehicleCatalog.Cars = {
	["Cybertruck"] = {
		DisplayName = "Cybertruck",
		Description = "Heavy, durable, and commands respect on the asphalt.",
		Price = 1,
		Rarity = VehicleCatalog.Rarities.Exotic,
		ThumbnailId = 0, -- 🔗 Replace with your uploaded Roblox asset ID!

		DisplayStats = { Acceleration = 3, Handling = 3 },
		EngineValues = { TopSpeed = 209, AccelerationIndex = 55, DecelerationIndex = 160, HandlingIndex = 48, RideHeight = 5.5 }
	},

	["Rimac"] = {
		DisplayName = "Rimac",
		Description = "vroom",
		Price = 1,
		Rarity = VehicleCatalog.Rarities.Exotic,
		ThumbnailId = 0, -- 🔗 Replace with your uploaded Roblox asset ID!

		DisplayStats = { Acceleration = 5, Handling = 5 },
		EngineValues = { TopSpeed = 412, AccelerationIndex = 100, DecelerationIndex = 250, HandlingIndex = 80, RideHeight = 4.5 }
	},
}

-- 🛠️ HELPER FUNCTIONS (Makes searching data clean and easy)
function VehicleCatalog.GetCarData(carId)
	return VehicleCatalog.Cars[carId]
end

function VehicleCatalog.DoesCarExist(carId)
	return VehicleCatalog.Cars[carId] ~= nil
end

return VehicleCatalog