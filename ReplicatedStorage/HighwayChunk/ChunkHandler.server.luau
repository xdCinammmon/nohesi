local chunk = script.Parent -- This is the HighwayChunk Model container

-- 1. Locate the actual asphalt part inside the model safely
local roadBed = chunk:FindFirstChild("RoadBed")

if roadBed and roadBed:IsA("BasePart") then
	-- Apply physical rules directly to the asphalt surface part
	roadBed.Anchored = true
	roadBed.CanCollide = true
	roadBed.CastShadow = false -- Keeps that clean, unshaded flat look
	roadBed.Size = Vector3.new(80, 1, 200) 
else
	warn("WorldGenerator Warning: 'RoadBed' part missing inside HighwayChunk model!")
end

-- 2. Clean up scenery assets and track memory leaks when the chunk drops off screen
chunk.Destroying:Connect(function()
	-- Because we are tracking the whole Model container, destroying the chunk
	-- automatically completely wipes out all light poles, signs, and the RoadBed together.
	local currentPivot = chunk:GetPivot()
	print("Cleared old road segment and scenery at Z-axis: " .. tostring(math.round(currentPivot.Z)))
end)