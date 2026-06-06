local ProgressionConfig = {}

-- 🗺️ MULTI-COUNTRY ARCADE CAMPAIGN ARCHITECTURE
ProgressionConfig.Campaign = {
	[1] = {
		CountryName = "Saudi Arabia",
		EnvironmentTheme = "DesertHighway", -- Used by WorldGenerator to swap foliage/skyboxes
		Stages = {
			[1] = {
				ObjectiveType = "Distance",
				GoalValue = 2500, -- Studs to travel
				TimeLimit = 60, -- Seconds
				CoinReward = 150,
				ScoreReward = 1000,
				Description = "Sprint down the coastal highway before sunset."
			},
			[2] = {
				ObjectiveType = "NearMisses",
				GoalValue = 5,
				TimeLimit = 45,
				CoinReward = 300,
				ScoreReward = 2000,
				Description = "Weave through midday traffic tightly."
			}
		}
	},
	[2] = {
		CountryName = "Japan",
		EnvironmentTheme = "TokyoExpressway",
		Stages = {
			[1] = {
				ObjectiveType = "SpeedMaintenance",
				GoalValue = 180, -- Must stay above 180 MPH/KMH for X seconds
				DurationRequired = 10,
				TimeLimit = 90,
				CoinReward = 600,
				ScoreReward = 5000,
				Description = "Keep your foot down through the neon tunnels."
			}
		}
	}
}

-- 📈 PLAYER EXPERIENCE LEVEL MATRIX
-- Calculates how much total career score is required to level up
function ProgressionConfig.GetRequiredScoreForLevel(currentLevel)
	if currentLevel <= 1 then return 5000 end
	return math.floor(5000 * math.pow(currentLevel, 1.5)) -- Exponential scaling curve
end

return ProgressionConfig