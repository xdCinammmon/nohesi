-- ServerScriptService.ObjectPooler
local ObjectPooler = {}
local ServerStorage = game:GetService("ServerStorage")

local pool = {} -- Stores tables of inactive objects
local POOL_SIZE = 20 -- Pre-allocate this many per model

function ObjectPooler:Initialize(modelTemplate)
	local modelName = modelTemplate.Name
	if not pool[modelName] then pool[modelName] = {} end

	for _ = 1, POOL_SIZE do
		local clone = modelTemplate:Clone()
		clone.Parent = ServerStorage -- Keep hidden
		table.insert(pool[modelName], clone)
	end
end

function ObjectPooler:Get(modelName)
	if not pool[modelName] or #pool[modelName] == 0 then
		warn("Pool empty for: " .. modelName .. ". Expanding pool...")
		-- Emergency expansion
		return game.ReplicatedStorage.TrafficModels:FindFirstChild(modelName):Clone()
	end

	local obj = table.remove(pool[modelName])
	return obj
end

function ObjectPooler:Return(obj)
	-- Reset state before returning
	obj.Parent = ServerStorage
	-- Reset physics
	if obj:IsA("Model") then
		for _, child in pairs(obj:GetDescendants()) do
			if child:IsA("BasePart") then
				child.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				child.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
		end
	end

	table.insert(pool[obj.Name], obj)
end

return ObjectPooler