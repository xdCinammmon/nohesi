local TrafficConfig = {}

-- 🛣️ 4-LANE HIGHWAY INDEX MAP (Updated Orientation)
-- Lane 1: Fast Lane         (Far Left   -> 29)
-- Lane 2: Middle Lane Left  (Mid-Left   -> 8)
-- Lane 3: Middle Lane Right (Mid-Right  -> -8)
-- Lane 4: Slow Lane         (Far Right  -> -29)

TrafficConfig.VehiclePool = {
	{
		ClassName = "SemiTruck",
		Weight = 10, 
		StoragePath = "BBTruck",
		LaneWeights = {
			[1] = 0,   -- Absolutely banned from the fast lane (Far Left)
			[2] = 5,   -- Rarely goes into the left-middle lane
			[3] = 25,  -- Sometimes wanders into the right-middle lane
			[4] = 70   -- Mostly in the slow lane (Far Right)
		}
	},
	{
		ClassName = "Sedan",
		Weight = 30, 
		StoragePath = "BSedan",
		LaneWeights = {
			[1] = 20,
			[2] = 30, -- Evenly prefers both middle lanes smoothly
			[3] = 30, 
			[4] = 20
		}
	},
	{
		ClassName = "Wagon",
		Weight = 12,  
		StoragePath = "GWagon",
		LaneWeights = {
			[1] = 10,  
			[2] = 35,  
			[3] = 35,
			[4] = 20    
		}
	},
	{
		ClassName = "Taxi",
		Weight = 12,  
		StoragePath = "Taxi",
		LaneWeights = {
			[1] = 25,  
			[2] = 25,  
			[3] = 25,
			[4] = 25    
		}
	},
	{
		ClassName = "Hatchback",
		Weight = 12,  
		StoragePath = "RHatchback",
		LaneWeights = {
			[1] = 25,  
			[2] = 25,  
			[3] = 25,
			[4] = 25    
		}
	},
	{
		ClassName = "Pickup",
		Weight = 12,  
		StoragePath = "BPickup",
		LaneWeights = {
			[1] = 0,  
			[2] = 33,  
			[3] = 34,
			[4] = 33    
		}
	},
	{
		ClassName = "Police",
		Weight = 12,  
		StoragePath = "Police",
		LaneWeights = {
			[1] = 0,  
			[2] = 50,  
			[3] = 50,
			[4] = 0    
		}
	}
}

-- 📐 PHYSICAL HIGHWAY LAYOUT CONFIGURATION
-- Re-mapped precisely so index tracking matches your physical workspace layout
TrafficConfig.LaneXPositions = {
	[1] = 29,  -- Far Left (Fast Lane)
	[2] = 8,   -- Middle Lane Left
	[3] = -8,  -- Middle Lane Right
	[4] = -29  -- Far Right (Slow Lane)
}

return TrafficConfig