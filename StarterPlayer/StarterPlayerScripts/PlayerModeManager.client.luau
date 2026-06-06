local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local TAG_Y_OFFSET = 4.5         

local function createTagTemplate()
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ModeTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 250

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TagLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 18
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.Parent = billboard

	return billboard
end

local billboardTemplate = createTagTemplate()

local function updatePlayerTags(otherPlayer)
	if otherPlayer == localPlayer then return end

	local function processCharacter(otherChar)
		local otherRoot = otherChar:WaitForChild("HumanoidRootPart", 5)
		if not otherRoot then return end

		local existingTag = otherRoot:FindFirstChild("ModeTag")
		local currentTag = existingTag or billboardTemplate:Clone()
		currentTag.ExtentsOffset = Vector3.new(0, TAG_Y_OFFSET, 0)
		currentTag.Parent = otherRoot

		local label = currentTag:WaitForChild("TagLabel")

		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not localPlayer.Character or not otherChar.Parent or not otherRoot.Parent then
				connection:Disconnect()
				currentTag:Destroy()
				return
			end

			local theirMode = otherChar:GetAttribute("GameMode") or "Solo"
			local displayModeName = (theirMode == "Solo") and "ENDLESS" or "FREEPLAY"

			label.Text = string.format("%s | %s", otherPlayer.Name, displayModeName)

			-- 🎨 Color assignments match active team states cleanly
			if theirMode == "Multiplayer" then
				label.TextColor3 = Color3.fromRGB(0, 255, 145) -- Freeplay green
			else
				label.TextColor3 = Color3.fromRGB(255, 200, 0)  -- Endless gold
			end

			-- Ensure all players remain solid and visible on the road together!
			for _, part in ipairs(otherChar:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 0
				end
			end
		end)
	end

	otherPlayer.CharacterAdded:Connect(processCharacter)
	if otherPlayer.Character then processCharacter(otherPlayer.Character) end
end

Players.PlayerAdded:Connect(updatePlayerTags)
for _, player in ipairs(Players:GetPlayers()) do
	updatePlayerTags(player)
end