local ReplicatedStorage = game:GetService("ReplicatedStorage")
local carLightEvent = ReplicatedStorage:WaitForChild("CarLightEvent")

-- Listen for any player sending light state updates
carLightEvent.OnServerEvent:Connect(function(player, carModel, lightType, isSwitchedOn)
	-- Verify the car actually exists and belongs to the player area safely
	if carModel and carModel:IsA("Model") then
		-- Set an attribute directly on the car model. 
		-- Attributes automatically replicate from Server to ALL clients instantly.
		carModel:SetAttribute(lightType, isSwitchedOn)
	end
end)