local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- 📡 SYSTEM INFRASTRUCTURE REMOTE CONNECTIONS
local GarageRemote = ReplicatedStorage:WaitForChild("GarageRemote")
local VehicleCatalog = require(ReplicatedStorage:WaitForChild("VehicleCatalog"))
local PlayerModels = ReplicatedStorage:WaitForChild("PlayerModels")
local RequestVehicleSpawn = ReplicatedStorage:WaitForChild("NetworkEvents"):WaitForChild("RequestVehicleSpawn")

-- UI INTERFACE OBJECT HOOKS
local screenGui = script.Parent
local sidebar = screenGui:WaitForChild("Sidebar")
local tabNavigation = sidebar:WaitForChild("TabNavigation")
local displayPanels = screenGui:WaitForChild("DisplayPanels")

local panels = {
	Play = displayPanels:WaitForChild("PlayPanel"),
	Shop = displayPanels:WaitForChild("ShopPanel"),
	Help = displayPanels:WaitForChild("HelpPanel")
}

local buttons = {
	Play = tabNavigation:WaitForChild("PlayTabBtn"),
	Shop = tabNavigation:WaitForChild("ShopTabBtn"),
	Help = tabNavigation:WaitForChild("HelpTabBtn")
}

local playPanel = panels.Play
local carListFrame = playPanel:WaitForChild("CarList")
local carTemplate = playPanel:WaitForChild("CarTemplate")
local garageDashboardFrame = playPanel:WaitForChild("Frame")

-- 🗺️ EXACT MATCH: GAMEMODE SELECTION CONTAINER HOOKS
local modeSelectFrame = playPanel:WaitForChild("ModeSelectFrame")
local endlessCard = modeSelectFrame:WaitForChild("EndlessCard")
local multiplayerCard = modeSelectFrame:WaitForChild("MultiplayerCard") 
local careerCard = modeSelectFrame:WaitForChild("CareerCard")
local gamemodeBackButton = modeSelectFrame:WaitForChild("BackButton") 
local continueButton = modeSelectFrame:WaitForChild("ContinueButton") 

-- 🛡️ SAFE STROKE ACQUISITION: Prevents infinite yields if strokes are missing in studio
local endlessStroke = endlessCard:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", endlessCard)
local multiplayerStroke = multiplayerCard:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", multiplayerCard)
local careerStroke = careerCard:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", careerCard)

-- Force interaction active parameters
endlessCard.Active = true
multiplayerCard.Active = true
careerCard.Active = true

-- RIGHT SIDE PANEL CONTAINERS
local carViewport = garageDashboardFrame:WaitForChild("CarViewport")
local detailTitle = garageDashboardFrame:WaitForChild("DetailTitle")
local mainActionButton = garageDashboardFrame:WaitForChild("MainActionButton")

-- Individual numeric performance text indicators
local speedValue = garageDashboardFrame:WaitForChild("SpeedValue")
local brakingValue = garageDashboardFrame:WaitForChild("BrakingValue")
local handlingValue = garageDashboardFrame:WaitForChild("HandlingValue")

local inMenu = true
local camZPosition = 0 
local CINEMATIC_SPEED = 45

-- RUNTIME PROFILE STORAGE TRACKERS
local selectedCarId = "BSedan"
local selectedGameMode = nil 
local viewportRotationAngle = 0
local viewportCarClone = nil
local viewportCamera = Instance.new("Camera")
viewportCamera.FieldOfView = 35
carViewport.CurrentCamera = viewportCamera
viewportCamera.Parent = carViewport

-- ============================================================================
-- 🎨 WHITE TEXT STROKE & BORDER UPDATE PIPELINE
-- ============================================================================
local function applySelectionHighlight(targetCard, modeName)
	selectedGameMode = modeName

	local allCards = {
		Solo = {card = endlessCard, stroke = endlessStroke},
		Multiplayer = {card = multiplayerCard, stroke = multiplayerStroke},
		Career = {card = careerCard, stroke = careerStroke}
	}

	for mode, config in pairs(allCards) do
		if mode == modeName then
			config.stroke.Color = Color3.fromRGB(0, 255, 140)
			config.stroke.Thickness = 3

			for _, desc in ipairs(config.card:GetDescendants()) do
				if desc:IsA("TextLabel") then
					local textStroke = desc:FindFirstChildOfClass("UIStroke")
					if textStroke then
						textStroke.Color = Color3.fromRGB(255, 255, 255)
						textStroke.Thickness = 2
					end
				end
			end
		else
			config.stroke.Color = Color3.fromRGB(0, 0, 0)
			config.stroke.Thickness = 1

			for _, desc in ipairs(config.card:GetDescendants()) do
				if desc:IsA("TextLabel") then
					local textStroke = desc:FindFirstChildOfClass("UIStroke")
					if textStroke then
						textStroke.Color = Color3.fromRGB(50, 50, 50)
						textStroke.Thickness = 1
					end
				end
			end
		end
	end
end

-- ============================================================================
-- 🗂️ TAB NAVIGATION SWITCH MATRIX
-- ============================================================================
local function showPanel(targetName)
	modeSelectFrame.Visible = false
	carListFrame.Visible = (targetName == "Play")
	garageDashboardFrame.Visible = (targetName == "Play")

	for name, panelFrame in pairs(panels) do
		if name == targetName then
			panelFrame.Visible = true
			if panelFrame:IsA("CanvasGroup") then
				panelFrame.GroupTransparency = 1
				TweenService:Create(panelFrame, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
			end
		else
			panelFrame.Visible = false
		end
	end

	for name, btn in pairs(buttons) do
		if name == targetName then
			btn.TextColor3 = Color3.fromRGB(255, 215, 0)
		else
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

for name, btn in pairs(buttons) do
	btn.MouseButton1Click:Connect(function()
		showPanel(name)
	end)
end

-- ============================================================================
-- 📊 DYNAMIC RIGHT SIDE DASHBOARD POPULATION LAYER
-- ============================================================================
local function updateFocusedCarView(carId)
	selectedCarId = carId
	local carListSource = VehicleCatalog.Cars or VehicleCatalog
	local carData = carListSource[carId]
	if type(carData) ~= "table" then return end

	local ownedCarsFolder = localPlayer:WaitForChild("OwnedCars")
	local equippedCarId = localPlayer:GetAttribute("EquippedCar") or "BSedan"

	local isOwned = ownedCarsFolder:FindFirstChild(carId) ~= nil
	local isEquipped = (carId == equippedCarId)

	detailTitle.Text = carData.DisplayName or carId
	if carData.Rarity and carData.Rarity.Color then
		detailTitle.TextColor3 = carData.Rarity.Color
	else
		detailTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	speedValue.Text = (carData.EngineValues.TopSpeed or 0) .. " km/h"
	brakingValue.Text = (carData.DisplayStats.Acceleration or 0) .. "/5"
	handlingValue.Text = (carData.DisplayStats.Handling or 0) .. "/5"

	if viewportCarClone then viewportCarClone:Destroy() end

	local sourceModelTemplate = PlayerModels:FindFirstChild(carId)
	if sourceModelTemplate then
		viewportCarClone = sourceModelTemplate:Clone()

		for _, part in ipairs(viewportCarClone:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end

		viewportCarClone:PivotTo(CFrame.new(Vector3.new(0, 0, 0)))
		viewportCarClone.Parent = carViewport
	end

	mainActionButton = garageDashboardFrame.MainActionButton
	local oldBtnClone = mainActionButton:Clone()
	oldBtnClone.Parent = garageDashboardFrame
	mainActionButton:Destroy()
	mainActionButton = oldBtnClone

	if isEquipped then
		mainActionButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100) 
		mainActionButton.Text = "Spawn"

		mainActionButton.MouseButton1Click:Connect(function()
			carListFrame.Visible = false
			garageDashboardFrame.Visible = false

			selectedGameMode = nil
			endlessStroke.Color = Color3.fromRGB(0, 0, 0)
			multiplayerStroke.Color = Color3.fromRGB(0, 0, 0)
			careerStroke.Color = Color3.fromRGB(0, 0, 0)

			modeSelectFrame.Visible = true
		end)
	elseif isOwned then
		mainActionButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255) 
		mainActionButton.Text = "Equip"

		mainActionButton.MouseButton1Click:Connect(function()
			local success = GarageRemote:InvokeServer("Equip", carId)
			if success then
				localPlayer:SetAttribute("EquippedCar", carId)
				updateFocusedCarView(carId)
			end
		end)
	else
		mainActionButton.BackgroundColor3 = Color3.fromRGB(180, 35, 55) 
		mainActionButton.Text = "Buy - $" .. tostring(carData.Price or "0")

		mainActionButton.MouseButton1Click:Connect(function()
			local success, response = GarageRemote:InvokeServer("Buy", carId)
			if success then
				localPlayer:SetAttribute("EquippedCar", carId)
				updateFocusedCarView(carId)
			end
		end)
	end
end

-- ============================================================================
-- 🏎️ LEFT SIDE GALLERY SELECTION GENERATOR ENGINE
-- ============================================================================
local function rebuildLeftSelectionGallery()
	for _, child in ipairs(carListFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "VehicleCard" then child:Destroy() end
	end

	local ownedCarsFolder = localPlayer:WaitForChild("OwnedCars")
	local equippedCarId = localPlayer:GetAttribute("EquippedCar") or "BSedan"
	local carListSource = VehicleCatalog.Cars or VehicleCatalog

	local oldList = carListFrame:FindFirstChildOfClass("UIListLayout")
	if oldList then oldList:Destroy() end

	local gridLayout = carListFrame:FindFirstChildOfClass("UIGridLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Parent = carListFrame
	end

	local uiPadding = carListFrame:FindFirstChildOfClass("UIPadding")
	if not uiPadding then
		uiPadding = Instance.new("UIPadding")
		uiPadding.Parent = carListFrame
	end
	local LEFT_TOP_PADDING = 16
	uiPadding.PaddingLeft = UDim.new(0, LEFT_TOP_PADDING)
	uiPadding.PaddingTop = UDim.new(0, LEFT_TOP_PADDING)

	local interCellPadding = 14
	local frameWidth = carListFrame.AbsoluteSize.X
	if frameWidth == 420 or frameWidth == 0 then frameWidth = carListFrame.Parent.AbsoluteSize.X * 0.65 end

	local computedCellWidth = (frameWidth - LEFT_TOP_PADDING - interCellPadding - 25) / 2
	local designHeight = carTemplate.AbsoluteSize.Y
	if designHeight == 0 then designHeight = 135 end

	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder 
	gridLayout.StartCorner = Enum.StartCorner.TopLeft
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.CellSize = UDim2.new(0, computedCellWidth, 0, designHeight)
	gridLayout.CellPadding = UDim2.new(0, interCellPadding, 0, 14)

	for carId, carData in pairs(carListSource) do
		if type(carData) ~= "table" or not carData.EngineValues then continue end

		local isOwned = ownedCarsFolder:FindFirstChild(carId) ~= nil
		local isEquipped = (carId == equippedCarId)

		local card = carTemplate:Clone()
		card.Name = "VehicleCard"
		card.Position = UDim2.new(0, 0, 0, 0) 
		card.Visible = true

		if isEquipped then
			card.LayoutOrder = 1 
		elseif isOwned then
			card.LayoutOrder = 2 
		else
			card.LayoutOrder = 3 + (carData.Price or 0) 
		end

		card.Parent = carListFrame

		local cardViewport = card:FindFirstChild("CarImage") 
		local titleLabel = card:FindFirstChild("Title")
		local statusLabel = card:FindFirstChild("StatusLabel")

		local selectionOverlayButton = Instance.new("TextButton", card)
		selectionOverlayButton.Name = "SelectionButton"
		selectionOverlayButton.Size = UDim2.new(1, 0, 1, 0)
		selectionOverlayButton.BackgroundTransparency = 1
		selectionOverlayButton.Text = ""
		selectionOverlayButton.ZIndex = 10

		if titleLabel then 
			titleLabel.Text = carData.DisplayName or carId 
			if carData.Rarity and carData.Rarity.Color then
				titleLabel.TextColor3 = carData.Rarity.Color 
			end
		end

		local strokeInstance = card:FindFirstChildOfClass("UIStroke")
		if strokeInstance and carData.Rarity and carData.Rarity.Color then
			strokeInstance.Color = carData.Rarity.Color
		end

		if statusLabel then
			if isEquipped then
				statusLabel.Text = "ACTIVE"
				statusLabel.TextColor3 = Color3.fromRGB(0, 140, 255)
			elseif isOwned then
				statusLabel.Text = "OWNED"
				statusLabel.TextColor3 = Color3.fromRGB(0, 200, 120)
			else
				statusLabel.Text = carData.Price and ("$" .. tostring(carData.Price)) or "FREE"
				statusLabel.TextColor3 = Color3.fromRGB(245, 180, 0)
			end
		end

		if cardViewport and cardViewport:IsA("ViewportFrame") then
			local cardCamera = Instance.new("Camera")
			cardCamera.FieldOfView = 28 
			cardViewport.CurrentCamera = cardCamera
			cardCamera.Parent = cardViewport

			local sourceModelTemplate = PlayerModels:FindFirstChild(carId)
			if sourceModelTemplate then
				local miniCarClone = sourceModelTemplate:Clone()

				for _, part in ipairs(miniCarClone:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end

				miniCarClone:PivotTo(CFrame.new(Vector3.new(0, 0, 0)))
				miniCarClone.Parent = cardViewport

				local cameraOffset = Vector3.new(-22, 3.5, -33) 
				local focusPoint = Vector3.new(0, 0.3, 0)

				cardCamera.CFrame = CFrame.lookAt(cameraOffset, focusPoint)
			end
		end

		selectionOverlayButton.MouseButton1Click:Connect(function()
			updateFocusedCarView(carId)
		end)
	end
end

-- ============================================================================
-- 🕹️ GAMEMODE SELECTION ACTION INTERFACES
-- ============================================================================

gamemodeBackButton.MouseButton1Click:Connect(function()
	modeSelectFrame.Visible = false
	carListFrame.Visible = true
	garageDashboardFrame.Visible = true
end)

local function connectCardClick(cardObject, actionCallback)
	cardObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			actionCallback()
		end
	end)
end

-- Endless/Solo Selection Highlight
connectCardClick(endlessCard, function()
	applySelectionHighlight(endlessCard, "Solo")
end)

-- Multiplayer Selection Highlight 
connectCardClick(multiplayerCard, function()
	applySelectionHighlight(multiplayerCard, "Multiplayer")
end)

-- Career Selection Highlight
connectCardClick(careerCard, function()
	applySelectionHighlight(careerCard, "Career")
end)

-- ============================================================================
-- MODIFICATION REPLACEMENT: game.StarterGui.MainMenuGUI.MenuController (Lines 319+)
-- ============================================================================
-- confirmation validator gate
continueButton.MouseButton1Click:Connect(function()
	if not selectedGameMode then return end 

	if selectedGameMode == "Solo" or selectedGameMode == "Multiplayer" or selectedGameMode == "Career" then
		inMenu = false
		screenGui.Enabled = false 

		local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
		character:SetAttribute("GameMode", selectedGameMode) 
		character:SetAttribute("InMenu", false)

		-- Update world generator tags matching specific environment profiles if career mode selected
		if selectedGameMode == "Career" then
			local targetCountryIdx = localPlayer:GetAttribute("CurrentCountry") or 1
			local campaignDef = VehicleCatalog.Campaign or ProgressionConfig.Campaign
			local activeZoneData = campaignDef[targetCountryIdx]

			if activeZoneData and activeZoneData.EnvironmentTheme then
				-- Notify environment streaming folders if landscape alterations are deployed
				workspace:SetAttribute("ActiveTheme", activeZoneData.EnvironmentTheme)
			end
		end

		RequestVehicleSpawn:FireServer(selectedCarId)
	end
end)

-- ============================================================================
-- 🔁 ANIMATION RUNTIME TICK HEARTBEAT
-- ============================================================================
RunService.RenderStepped:Connect(function(deltaTime)
	if not inMenu then return end

	camZPosition = camZPosition - (CINEMATIC_SPEED * deltaTime)
	camera.CFrame = CFrame.lookAt(Vector3.new(-15, 18.5, camZPosition), Vector3.new(0, 4.0, camZPosition - 120))

	if viewportCarClone and viewportCarClone.PrimaryPart then
		viewportRotationAngle = viewportRotationAngle + math.rad(30 * deltaTime)

		local targetDistance = 44.0
		local cameraHeightOffset = 6.8
		local camX = math.sin(viewportRotationAngle) * targetDistance
		local camZ = math.cos(viewportRotationAngle) * targetDistance

		viewportCamera.CFrame = CFrame.lookAt(
			Vector3.new(camX, cameraHeightOffset, camZ), 
			viewportCarClone.PrimaryPart.Position + Vector3.new(0, 0.4, 0)
		)
	end
end)

carListFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(rebuildLeftSelectionGallery)
localPlayer:GetAttributeChangedSignal("EquippedCar"):Connect(rebuildLeftSelectionGallery)
localPlayer:WaitForChild("OwnedCars").ChildAdded:Connect(rebuildLeftSelectionGallery)

rebuildLeftSelectionGallery()
updateFocusedCarView(localPlayer:GetAttribute("EquippedCar") or "BSedan")