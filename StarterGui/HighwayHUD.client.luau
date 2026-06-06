local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

-- 🗺️ DEFAULT POSITION LAYOUT ANCHOR
local BASE_HUD_POSITION = UDim2.new(0.5, 0, 0.05, 0)

-- 🎛️ STACK NOTIFICATION CONFIGURATION VARIABLES
local COMBO_LIFETIME = 1.5   
local MAX_STACK_SIZE = 2     
local FLASH_THRESHOLD = 1.0  

-- [[ UI COMPONENT INITIALIZATION ]]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HighwayHUD_v2"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Strict depth stacking layout rules
screenGui.Enabled = false 
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- 💠 MAIN TOP POSITIONING CONTAINER
local hudContainer = Instance.new("Frame")
hudContainer.Name = "HUDContainer"
hudContainer.Size = UDim2.new(0, 580, 0, 100) 
hudContainer.Position = BASE_HUD_POSITION
hudContainer.AnchorPoint = Vector2.new(0.5, 0)
hudContainer.BackgroundTransparency = 1
hudContainer.Parent = screenGui

-- ============================================================================
-- ⏸️ PAUSE BUTTON & OVERLAY WINDOW ARCHITECTURE
-- ============================================================================
local pauseBtn = Instance.new("TextButton")
pauseBtn.Name = "PauseButton"
pauseBtn.Size = UDim2.new(0, 50, 0, 50)
pauseBtn.Position = UDim2.new(1, -70, 0, 30)
pauseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
pauseBtn.BackgroundTransparency = 0.3
pauseBtn.Font = Enum.Font.GothamBold
pauseBtn.Text = "II"
pauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pauseBtn.TextSize = 20
pauseBtn.ZIndex = 50
pauseBtn.Parent = screenGui

local pauseCorner = Instance.new("UICorner")
pauseCorner.CornerRadius = UDim.new(0, 12)
pauseCorner.Parent = pauseBtn

local pauseStroke = Instance.new("UIStroke")
pauseStroke.Color = Color3.fromRGB(255, 255, 255)
pauseStroke.Thickness = 1.5
pauseStroke.Transparency = 0.6
pauseStroke.Parent = pauseBtn

-- Master Fullscreen Background Darkener Overlay Frame
local pauseMenuOverlay = Instance.new("Frame")
pauseMenuOverlay.Name = "PauseMenuOverlay"
pauseMenuOverlay.Size = UDim2.new(1, 0, 1, 0)
pauseMenuOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
pauseMenuOverlay.BackgroundTransparency = 1 
pauseMenuOverlay.Visible = false
pauseMenuOverlay.ZIndex = 100 -- Tint wrapper base layer level
pauseMenuOverlay.Parent = screenGui

local pauseCenterBox = Instance.new("Frame")
pauseCenterBox.Name = "CenterBox"
pauseCenterBox.Size = UDim2.new(0, 320, 0, 220)
pauseCenterBox.Position = UDim2.new(0.5, 0, 0.5, 0)
pauseCenterBox.AnchorPoint = Vector2.new(0.5, 0.5)
pauseCenterBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
pauseCenterBox.ZIndex = 110 -- ✨ FIX: Pushes container frame layout in front of background overlay
pauseCenterBox.Parent = pauseMenuOverlay

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 16)
boxCorner.Parent = pauseCenterBox

-- 🖌️ NOTE: Green UIStroke border configuration code block removed entirely!

local pauseTitle = Instance.new("TextLabel")
pauseTitle.Size = UDim2.new(1, 0, 0, 60)
pauseTitle.BackgroundTransparency = 1
pauseTitle.Font = Enum.Font.GothamBold
pauseTitle.Text = "GAME PAUSED"
pauseTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pauseTitle.TextSize = 26
pauseTitle.ZIndex = 120 -- Layer text elements clear of base frames
pauseTitle.Parent = pauseCenterBox

local continueRunBtn = Instance.new("TextButton")
continueRunBtn.Size = UDim2.new(0, 240, 0, 45)
continueRunBtn.Position = UDim2.new(0.5, -120, 0, 80)
continueRunBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
continueRunBtn.Font = Enum.Font.GothamBold
continueRunBtn.Text = "CONTINUE"
continueRunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
continueRunBtn.TextSize = 16
continueRunBtn.ZIndex = 120 
continueRunBtn.Parent = pauseCenterBox
Instance.new("UICorner", continueRunBtn).CornerRadius = UDim.new(0, 8)

local endRunBtn = Instance.new("TextButton")
endRunBtn.Size = UDim2.new(0, 240, 0, 45)
endRunBtn.Position = UDim2.new(0.5, -120, 0, 145)
endRunBtn.BackgroundColor3 = Color3.fromRGB(200, 35, 55)
endRunBtn.Font = Enum.Font.GothamBold
endRunBtn.Text = "END RUN"
endRunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
endRunBtn.TextSize = 16
endRunBtn.ZIndex = 120 
endRunBtn.Parent = pauseCenterBox
Instance.new("UICorner", endRunBtn).CornerRadius = UDim.new(0, 8)

-- ============================================================================
-- ⚡ THREAD THE NEEDLE GOLD SHOCKWAVE LAYER
-- ============================================================================
local needleShockwave = Instance.new("Frame")
needleShockwave.Name = "NeedleShockwave"
needleShockwave.Size = UDim2.new(1, 40, 1, 20)
needleShockwave.Position = UDim2.new(0.5, 0, 0.5, 0)
needleShockwave.AnchorPoint = Vector2.new(0.5, 0.5)
needleShockwave.BackgroundColor3 = Color3.fromRGB(255, 145, 0) 
needleShockwave.BackgroundTransparency = 1
needleShockwave.ZIndex = 0
needleShockwave.Parent = hudContainer

local uiCornerShock = Instance.new("UICorner")
uiCornerShock.CornerRadius = UDim.new(0, 45)
uiCornerShock.Parent = needleShockwave

-- 🫀 HEARTBEAT PILL GLOW BACKGROUND
local heartGlow = Instance.new("Frame")
heartGlow.Name = "HeartGlow"
heartGlow.Size = UDim2.new(1, 30, 1, 20)
heartGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
heartGlow.AnchorPoint = Vector2.new(0.5, 0.5)
heartGlow.BackgroundColor3 = Color3.fromRGB(0, 120, 255) 
heartGlow.BackgroundTransparency = 1
heartGlow.ZIndex = 1
heartGlow.Parent = hudContainer

local uiCornerGlow = Instance.new("UICorner")
uiCornerGlow.CornerRadius = UDim.new(0, 45) 
uiCornerGlow.Parent = heartGlow

local pillGradient = Instance.new("UIGradient")
pillGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),      
	NumberSequenceKeypoint.new(0.25, 0.4),  
	NumberSequenceKeypoint.new(0.5, 0),    
	NumberSequenceKeypoint.new(0.75, 0.4),  
	NumberSequenceKeypoint.new(1, 1)       
})
pillGradient.Parent = heartGlow

local shockGradient = pillGradient:Clone()
shockGradient.Parent = needleShockwave

-- 📊 INSIDE DISPLAY PANEL
local displayLayout = Instance.new("Frame")
displayLayout.Name = "DisplayLayout"
displayLayout.Size = UDim2.new(1, 0, 1, 0)
displayLayout.BackgroundTransparency = 1
displayLayout.ZIndex = 2
displayLayout.Parent = hudContainer

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 15)
uiListLayout.Parent = displayLayout

-- ❤️ PROGRAMMATIC ARCADE LIVES SYSTEM
local livesContainer = Instance.new("Frame")
livesContainer.Name = "LivesContainer"
livesContainer.Size = UDim2.new(0, 130, 0, 40)
livesContainer.BackgroundTransparency = 1
livesContainer.LayoutOrder = 0 
livesContainer.ZIndex = 3
livesContainer.Parent = displayLayout

local livesLayout = Instance.new("UIListLayout")
livesLayout.FillDirection = Enum.FillDirection.Horizontal
livesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
livesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
livesLayout.Padding = UDim.new(0, 6)
livesLayout.Parent = livesContainer

local heartInstances = {}
for i = 1, 3 do
	local heart = Instance.new("ImageLabel")
	heart.Name = "Heart_" .. i
	heart.LayoutOrder = i 
	heart.Size = UDim2.new(0, 32, 0, 32) 
	heart.BackgroundTransparency = 1
	heart.Image = "http://www.roblox.com/asset/?id=249529864" 
	heart.ImageColor3 = Color3.fromRGB(255, 35, 70) 
	heart.ZIndex = 4 
	heart.Parent = livesContainer
	table.insert(heartInstances, heart)
end

-- [[ GEOMETRIC SCORE AREA CONTAINER ]]
local scoreAreaContainer = Instance.new("Frame")
scoreAreaContainer.Name = "ScoreArea"
scoreAreaContainer.Size = UDim2.new(0, 260, 1, -10) 
scoreAreaContainer.BackgroundTransparency = 1
scoreAreaContainer.LayoutOrder = 1
scoreAreaContainer.ClipsDescendants = true 
scoreAreaContainer.Parent = displayLayout

-- 🔷 GEOMETRIC GRID INTERFACE
local geometricGrid = Instance.new("Frame")
geometricGrid.Name = "GeometricGrid"
geometricGrid.Size = UDim2.new(1.5, 0, 1.5, 0) 
geometricGrid.Position = UDim2.new(0.5, 0, 0.5, 0)
geometricGrid.AnchorPoint = Vector2.new(0.5, 0.5)
geometricGrid.BackgroundTransparency = 1
geometricGrid.Parent = scoreAreaContainer

local gridLines = {}
local lineCount = 10
for i = 1, lineCount do
	local line = Instance.new("Frame")
	line.Name = "GridLine_" .. i
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.Position = UDim2.new((i / lineCount) * 1.5 - 0.25, 0, 0, 0) 
	line.Size = UDim2.new(0, 1, 1, 0) 
	line.Rotation = 35 
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BackgroundTransparency = 0.9 
	line.BorderSizePixel = 0
	line.ZIndex = 1
	line.Parent = geometricGrid
	table.insert(gridLines, line)
end

local gridFade = Instance.new("UIGradient")
gridFade.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.1, 0),
	NumberSequenceKeypoint.new(0.9, 0),
	NumberSequenceKeypoint.new(1, 1)
})
gridFade.Parent = geometricGrid

-- 🔢 DIGITAL SCORE METERS
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(1, -20, 1, 0) 
scoreLabel.Position = UDim2.new(1, 0, 0.5, 0)
scoreLabel.AnchorPoint = Vector2.new(1, 0.5)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 48 
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
scoreLabel.Text = "000,000"
scoreLabel.ZIndex = 2 
scoreLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
scoreLabel.TextStrokeTransparency = 0
scoreLabel.Parent = scoreAreaContainer

-- 🗂 MULTIPLIER ISOLATION CONTAINER
local multiplierContainer = Instance.new("Frame")
multiplierContainer.Name = "MultiplierContainer"
multiplierContainer.Size = UDim2.new(0, 120, 1, 0)
multiplierContainer.BackgroundTransparency = 1
multiplierContainer.LayoutOrder = 2
multiplierContainer.Parent = displayLayout

-- ✖ SPEED MULTIPLIER METERS
local multiplierLabel = Instance.new("TextLabel")
multiplierLabel.Name = "MultiplierLabel"
multiplierLabel.Size = UDim2.new(1, 0, 1, 0)
multiplierLabel.Position = UDim2.new(0, 0, 0, 0)
multiplierLabel.BackgroundTransparency = 1
multiplierLabel.Font = Enum.Font.GothamBold
multiplierLabel.TextSize = 24
multiplierLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
multiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
multiplierLabel.Text = ""
multiplierLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
multiplierLabel.TextStrokeTransparency = 0
multiplierLabel.Parent = multiplierContainer

-- 🗂 FEED CONTAINER
local comboStackContainer = Instance.new("Frame")
comboStackContainer.Name = "ComboStackContainer"
comboStackContainer.Size = UDim2.new(0, 600, 0, 250)
comboStackContainer.Position = UDim2.new(0.5, 0, 1.15, 0) 
comboStackContainer.AnchorPoint = Vector2.new(0.5, 0)
comboStackContainer.BackgroundTransparency = 1
comboStackContainer.Parent = hudContainer

local stackListLayout = Instance.new("UIListLayout")
stackListLayout.FillDirection = Enum.FillDirection.Vertical
stackListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
stackListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
stackListLayout.SortOrder = Enum.SortOrder.LayoutOrder
stackListLayout.Padding = UDim.new(0, 4) 
stackListLayout.Parent = comboStackContainer

-- 📡 BACKEND SERVER DEPLOYMENT HOOKS
local RequestVehicleSpawn = ReplicatedStorage:WaitForChild("NetworkEvents"):WaitForChild("RequestVehicleSpawn")

-- 🗺️ EXACT MATCH: physical studio layout frame hooks
local studioGameplayHUD = localPlayer:WaitForChild("PlayerGui"):WaitForChild("GameplayHUD")
local resultScreen = studioGameplayHUD:WaitForChild("ResultScreen")
local overlayBox = resultScreen:WaitForChild("ResultScreenOverlay")
local restartBtn = resultScreen:WaitForChild("RestartButton")
local backToGarageBtn = resultScreen:WaitForChild("TextButton")

local scoreValueLabel = overlayBox:WaitForChild("ScoreValue")
local nearMissValueLabel = overlayBox:WaitForChild("NearMissValue")
local ttnValueLabel = overlayBox:WaitForChild("TTNValue")
local earningsValueLabel = overlayBox:WaitForChild("EarningsValue")

resultScreen.Visible = false

-- [[ DATA REPLICATION LISTENERS ]]
local targetScore = 0
local currentMultiplier = 1.0
local lastActiveMultiplier = 1.0 
local multiplierExpiration = 0
local lastProcessedComboTime = 0
local isCrashingUI = false       
local lastKnownLives = 3 

local totalNearMisses = 0
local totalThreadTheNeedles = 0
local runningScore = 0

local function formatToMultiplierScale(value)
	local floorValue = math.floor(value)
	if floorValue >= 1000000 then
		return string.format("%.2fM", value / 1000000)
	elseif floorValue >= 1000 then
		return string.format("%.1fK", value / 1000)
	else
		return string.format("%06d", floorValue) 
	end
end

local function formatNumberWithCommas(value)
	local formatted = tostring(math.floor(value))
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')  
		if k == 0 then break end  
	end  
	return formatted
end

-- 🔢 SEQUENTIAL REVENUE TICKER MECHANICAL SYSTEM
local function tickValueUpInSequence(labelElement, finalTargetValue, duration, isCashValue)
	local startTime = os.clock()
	while os.clock() - startTime < duration do
		local elapsed = os.clock() - startTime
		local ratio = math.clamp(elapsed / duration, 0, 1)
		local easedRatio = 1 - (1 - ratio) * (1 - ratio)
		local currentCount = math.floor(finalTargetValue * easedRatio)

		if isCashValue then
			labelElement.Text = "$" .. formatNumberWithCommas(currentCount)
		else
			labelElement.Text = formatNumberWithCommas(currentCount)
		end
		RunService.Heartbeat:Wait()
	end

	if isCashValue then
		labelElement.Text = "$" .. formatNumberWithCommas(finalTargetValue)
	else
		labelElement.Text = formatNumberWithCommas(finalTargetValue)
	end
end

local function bindCharacterAttributes(character)
	if not character then return end

	totalNearMisses = 0
	totalThreadTheNeedles = 0
	hudContainer.Visible = true 
	pauseBtn.Visible = true

	local function handleHUDLayoutMasking(character)
		local currentMode = character:GetAttribute("GameMode") or "Solo"

		if currentMode == "Multiplayer" then
			livesContainer.Visible = false       
			hudContainer.Visible = true          
			comboStackContainer.Visible = true   
		else
			livesContainer.Visible = true        
			hudContainer.Visible = true
			comboStackContainer.Visible = true
		end
	end

	local function updateHeartVisuals()
		local totalLivesLeft = character:GetAttribute("Lives") or 3

		if totalLivesLeft < lastKnownLives and totalLivesLeft >= 0 then
			local brokenHeartIndex = totalLivesLeft + 1
			local originalHeart = heartInstances[brokenHeartIndex]

			if originalHeart then
				heartGlow.BackgroundColor3 = Color3.fromRGB(255, 0, 50)
				heartGlow.Size = UDim2.new(1, 95, 0, 24)
				heartGlow.BackgroundTransparency = 0.1

				for _, line in ipairs(gridLines) do
					line.Size = UDim2.new(0, 8, 1, 0)
					line.BackgroundColor3 = Color3.fromRGB(255, 30, 60)
					line.BackgroundTransparency = 0.3
				end

				originalHeart.ImageColor3 = Color3.fromRGB(45, 45, 48)
				originalHeart.ImageTransparency = 0.6

				task.spawn(function()
					local kineticClone = originalHeart:Clone()
					kineticClone.Name = "KineticHeartParticle"
					kineticClone.ImageColor3 = Color3.fromRGB(255, 255, 255)
					kineticClone.ImageTransparency = 0

					kineticClone.Position = UDim2.new(0, originalHeart.AbsolutePosition.X, 0, originalHeart.AbsolutePosition.Y)
					kineticClone.Parent = screenGui

					TweenService:Create(kineticClone, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 68, 0, 68),
						Rotation = math.random(-35, 35)
					}):Play()

					task.wait(0.08)

					kineticClone.ImageColor3 = Color3.fromRGB(255, 30, 60)
					local dropTween = TweenService:Create(kineticClone, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Position = UDim2.new(0, kineticClone.AbsolutePosition.X + math.random(-40, 40), 0, kineticClone.AbsolutePosition.Y + 220),
						Size = UDim2.new(0, 12, 0, 12),
						ImageTransparency = 1,
						Rotation = math.random(-120, 120)
					})

					dropTween.Completed:Connect(function() kineticClone:Destroy() end)
					dropTween:Play()
				end)
			end
		end

		lastKnownLives = totalLivesLeft

		for index, heartObj in ipairs(heartInstances) do
			if index <= totalLivesLeft then
				heartObj.ImageColor3 = Color3.fromRGB(255, 35, 70)
				heartObj.ImageTransparency = 0
			else
				heartObj.ImageColor3 = Color3.fromRGB(45, 45, 48)
				heartObj.ImageTransparency = 0.6
			end
		end
	end

	character:GetAttributeChangedSignal("GameMode"):Connect(function() handleHUDLayoutMasking(character) end)
	handleHUDLayoutMasking(character)

	character:GetAttributeChangedSignal("Lives"):Connect(updateHeartVisuals)
	lastKnownLives = character:GetAttribute("Lives") or 3
	updateHeartVisuals()

	character:GetAttributeChangedSignal("Score"):Connect(function()
		if character:GetAttribute("InMenu") == true then return end
		targetScore = character:GetAttribute("Score") or 0
	end)

	character:GetAttributeChangedSignal("CurrentMultiplier"):Connect(function()
		if character:GetAttribute("InMenu") == true then return end
		local val = character:GetAttribute("CurrentMultiplier") or 1.0
		currentMultiplier = val
		if val > 1.01 then lastActiveMultiplier = val end
	end)

	character:GetAttributeChangedSignal("MultiplierExpiration"):Connect(function()
		if character:GetAttribute("InMenu") == true then return end
		multiplierExpiration = character:GetAttribute("MultiplierExpiration") or 0
	end)

	-- 🏁 CRITICAL DRIVER INTERCEPT SYSTEM: GAME OVER SECTOR INITIALIZATION
	character:GetAttributeChangedSignal("GameOver"):Connect(function()
		if character:GetAttribute("GameOver") == true then
			local currentMode = character:GetAttribute("GameMode") or "Solo"

			task.wait(0.2) 

			-- Hide active top score and pause button layout clean templates
			hudContainer.Visible = false
			pauseBtn.Visible = false

			scoreValueLabel.Text = "0"
			nearMissValueLabel.Text = "0"
			ttnValueLabel.Text = "0"
			earningsValueLabel.Text = "$0"

			resultScreen.Visible = true
			resultScreen.BackgroundTransparency = 1
			studioGameplayHUD.Enabled = true

			TweenService:Create(resultScreen, TweenInfo.new(0.35), {BackgroundTransparency = 0.2}):Play()
			task.wait(0.4)

			tickValueUpInSequence(scoreValueLabel, targetScore, 0.75, false)
			task.wait(0.15)

			tickValueUpInSequence(nearMissValueLabel, totalNearMisses, 0.45, false)
			task.wait(0.15)

			tickValueUpInSequence(ttnValueLabel, totalThreadTheNeedles, 0.45, false)
			task.wait(0.2)

			-- If Freeplay, cash stays at $0, otherwise calculate Solo Endless earnings
			local finalCashCalculated = (currentMode == "Multiplayer") and 0 or math.floor(targetScore / 100)
			tickValueUpInSequence(earningsValueLabel, finalCashCalculated, 0.6, true)
		end
	end)

	-- FORZA STYLE VISUAL CRASH DISASTER SEQUENCER
	character:GetAttributeChangedSignal("StreakBroken"):Connect(function()
		if character:GetAttribute("InMenu") == true or isCrashingUI then return end
		isCrashingUI = true

		multiplierLabel.Text = string.format("x%.1f", lastActiveMultiplier)
		multiplierLabel.TextColor3 = Color3.fromRGB(255, 30, 30) 

		TweenService:Create(heartGlow, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			Size = UDim2.new(1, 80, 0, 12),
			BackgroundTransparency = 0.2
		}):Play()

		TweenService:Create(geometricGrid, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			Rotation = math.random(-20, 20),
			Position = UDim2.new(0.5, math.random(-10, 10), 0.7, 5)
		}):Play()

		TweenService:Create(scoreLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextColor3 = Color3.fromRGB(255, 40, 50)
		}):Play()

		for _, alert in ipairs(comboStackContainer:GetChildren()) do
			if alert:IsA("TextLabel") then
				alert.TextColor3 = Color3.fromRGB(255, 30, 30)
				TweenService:Create(alert, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Rotation = math.random(-15, 15),
					TextTransparency = 1,
				}):Play()
				task.delay(0.15, function() alert:Destroy() end)
			end
		end

		local randomTiltAngle = math.random(-25, -12)
		if math.random() > 0.5 then randomTiltAngle = math.random(12, 25) end

		local crashTiltTween = TweenService:Create(multiplierLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = randomTiltAngle,
			TextTransparency = 1,
			TextSize = multiplierLabel.TextSize * 1.15 
		})

		crashTiltTween.Completed:Connect(function()
			multiplierLabel.Text = ""
			multiplierLabel.Rotation = 0 
			multiplierLabel.Position = UDim2.new(0, 0, 0, 0)

			TweenService:Create(scoreLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()

			geometricGrid.Position = UDim2.new(0.5, 0, 0.5, 0)
			geometricGrid.Rotation = 0

			lastActiveMultiplier = 1.0
			isCrashingUI = false
		end)

		crashTiltTween:Play()
	end)

	-- ⚡ NEAR MISS AND THREAD THE NEEDLE COMBO FEED TRANSLATOR
	character:GetAttributeChangedSignal("ComboTime"):Connect(function()
		if character:GetAttribute("InMenu") == true or isCrashingUI then return end 
		local comboTime = character:GetAttribute("ComboTime") or 0
		if comboTime == lastProcessedComboTime then return end
		lastProcessedComboTime = comboTime

		local comboText = character:GetAttribute("ComboText") or ""
		if comboText == "" then return end

		local activeAlerts = {}
		for _, child in ipairs(comboStackContainer:GetChildren()) do
			if child.Name == "StackAlert" then table.insert(activeAlerts, child) end
		end
		table.sort(activeAlerts, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

		if #activeAlerts >= MAX_STACK_SIZE then
			local oldestAlert = activeAlerts[1]
			if oldestAlert then oldestAlert:Destroy() end
		end

		local displayText = comboText
		local isNeedleEvent = string.find(comboText, "THREAD") or string.find(comboText, "NEEDLE")

		if isNeedleEvent then
			totalThreadTheNeedles = totalThreadTheNeedles + 1 
			displayText = "+500 " .. comboText
		else
			totalNearMisses = totalNearMisses + 1             
			displayText = "+150 " .. comboText
		end

		local newFeedItem = Instance.new("TextLabel")
		newFeedItem.Name = "StackAlert"
		newFeedItem.Size = UDim2.new(1, 0, 0, 32)
		newFeedItem.BackgroundTransparency = 1
		newFeedItem.Font = Enum.Font.GothamBold
		newFeedItem.TextTransparency = 1
		newFeedItem.Text = displayText 
		newFeedItem.LayoutOrder = math.floor(os.clock() * 1000)
		newFeedItem.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		newFeedItem.TextStrokeTransparency = 0

		local baseSize = 22
		local sizeBonus = math.min((currentMultiplier - 1.0) * 8, 20) 
		local finalTextSize = baseSize + sizeBonus

		if isNeedleEvent then
			newFeedItem.TextColor3 = Color3.fromRGB(255, 145, 0) 
			newFeedItem.TextSize = finalTextSize * 1.65

			needleShockwave.Size = UDim2.new(1, 30, 1, 20)
			needleShockwave.BackgroundTransparency = 0.15

			TweenService:Create(needleShockwave, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 240, 1, 105), 
				BackgroundTransparency = 1
			}):Play()
		else
			newFeedItem.TextColor3 = Color3.fromRGB(0, 255, 150) 
			newFeedItem.TextSize = 0
		end

		newFeedItem.Parent = comboStackContainer

		TweenService:Create(newFeedItem, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = finalTextSize,
			TextTransparency = 0
		}):Play()

		task.delay(COMBO_LIFETIME, function()
			if newFeedItem and newFeedItem.Parent then
				local fadeTween = TweenService:Create(newFeedItem, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					TextSize = finalTextSize - 8,
					TextTransparency = 1
				})
				fadeTween.Completed:Connect(function() newFeedItem:Destroy() end)
				fadeTween:Play()
			end
		end)
	end)
end

-- ============================================================================
-- ⏸️ PAUSE MODAL SELECTION LOGIC BINDINGS
-- ============================================================================
-- ============================================================================
-- MODIFIED ROUTINE: game.StarterGui.HighwayHUD
-- LOCATION: Pause/Unpause Button Connections
-- ============================================================================
pauseBtn.MouseButton1Click:Connect(function()
	local character = localPlayer.Character
	if not character or character:GetAttribute("InMenu") == true or character:GetAttribute("GameOver") == true then return end

	character:SetAttribute("IsPaused", true)
	-- 🟢 NEW: Tell the server we paused so other players see us disappear
	if ReplicatedStorage:FindFirstChild("ToggleLights") then
		ReplicatedStorage.ToggleLights:FireServer("IsPaused", true)
	end

	pauseMenuOverlay.Visible = true
	TweenService:Create(pauseMenuOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
end)

continueRunBtn.MouseButton1Click:Connect(function()
	local character = localPlayer.Character
	if character then 
		character:SetAttribute("IsPaused", false) 
		-- 🟢 NEW: Tell the server we unpaused so we materialize back in the race
		if ReplicatedStorage:FindFirstChild("ToggleLights") then
			ReplicatedStorage.ToggleLights:FireServer("IsPaused", false)
		end
	end

	TweenService:Create(pauseMenuOverlay, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()

	task.delay(0.15, function() 
		pauseMenuOverlay.Visible = false 
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end)
end)

endRunBtn.MouseButton1Click:Connect(function()
	local character = localPlayer.Character
	pauseMenuOverlay.Visible = false
	pauseMenuOverlay.BackgroundTransparency = 1

	if character then
		character:SetAttribute("IsPaused", false)
		-- ✨ FIX: Reroutes both modes into the active Result Screen card sequence loops
		character:SetAttribute("GameOver", true)
	end
end)

-- 🔄 RESTORE BUTTON ACTIONS
restartBtn.MouseButton1Click:Connect(function()
	local equippedCarId = localPlayer:GetAttribute("EquippedCar") or "BSedan"

	resultScreen.Visible = false
	hudContainer.Visible = true
	pauseBtn.Visible = true

	runningScore = 0
	targetScore = 0
	totalNearMisses = 0
	totalThreadTheNeedles = 0
	scoreLabel.Text = "000,000"

	local character = localPlayer.Character
	if character then
		character:SetAttribute("GameOver", false)
		character:SetAttribute("InMenu", false)
		character:SetAttribute("Lives", 3)
		character:SetAttribute("Score", 0)
		character:SetAttribute("IsPaused", false)
	end

	RequestVehicleSpawn:FireServer(equippedCarId)
end)

-- ============================================================================
-- CORRECTED ROUTINE: game.StarterGui.HighwayHUD
-- LOCATION: backToGarageBtn.MouseButton1Click
-- ============================================================================
backToGarageBtn.MouseButton1Click:Connect(function()
	-- 1. Reset all state flags cleanly
	local character = localPlayer.Character
	if character then
		character:SetAttribute("GameOver", false) 
		character:SetAttribute("InMenu", true) -- Return to menu logic
		character:SetAttribute("IsPaused", false)

		-- Clear physics lock if it was stuck
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then root.Anchored = false end
	end

	-- 2. Hide result screens
	resultScreen.Visible = false
	studioGameplayHUD.Enabled = false
	screenGui.Enabled = false

	-- 3. Transition Camera & UI
	local mainMenuGui = localPlayer.PlayerGui:FindFirstChild("MainMenuGUI")
	if mainMenuGui then
		mainMenuGui.Enabled = true
	end

	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	-- 4. Final Cleanup: Destroy physics assembly to prevent ghost-collisions
	if character then
		local equippedVehicle = character:FindFirstChild("EquippedVehicleBody")
		if equippedVehicle then equippedVehicle:Destroy() end
	end
end)

localPlayer.CharacterAdded:Connect(bindCharacterAttributes)
if localPlayer.Character then bindCharacterAttributes(localPlayer.Character) end

-- [[ ANIMATION & HEARTBEAT ENGINE ]]
-- ============================================================================
-- CORRECTED ROUTINE: game.StarterGui.HighwayHUD
-- LOCATION: RunService.RenderStepped HUD Guard Matrix (Lines 372+)
-- ============================================================================
RunService.RenderStepped:Connect(function(deltaTime)
	local character = localPlayer.Character
	if not character then
		screenGui.Enabled = false
		return
	end

	local inMenu = character:GetAttribute("InMenu") or false
	local isGameOver = character:GetAttribute("GameOver") or false
	local isPaused = character:GetAttribute("IsPaused") or false

	-- 🟢 FIX: Allow the HUD to stay completely visible if the game is over!
	if inMenu and not isGameOver then
		if screenGui.Enabled then screenGui.Enabled = false end
		studioGameplayHUD.Enabled = false
		return
	else
		-- Keep screens active during game over sequences to view final scores
		if not screenGui.Enabled then screenGui.Enabled = true end
	end

	if isGameOver and not isPaused then
		-- Keep rendering interpolation tickers down into your result display screen fields
		if runningScore ~= targetScore then
			local interpolationSpeed = 15 
			runningScore = runningScore + (targetScore - runningScore) * math.clamp(deltaTime * interpolationSpeed, 0, 1)
			scoreValueLabel.Text = formatNumberWithCommas(runningScore)
		end
		return 
	end

	if isPaused then 
		return 
	end

	if runningScore ~= targetScore then
		local interpolationSpeed = 15 
		runningScore = runningScore + (targetScore - runningScore) * math.clamp(deltaTime * interpolationSpeed, 0, 1)
		scoreLabel.Text = formatToMultiplierScale(runningScore)
	end

	if isCrashingUI then
		local extremeRumble = (math.random() - 0.5) * 28
		hudContainer.Position = UDim2.new(
			BASE_HUD_POSITION.X.Scale,
			BASE_HUD_POSITION.X.Offset + extremeRumble,
			BASE_HUD_POSITION.Y.Scale,
			BASE_HUD_POSITION.Y.Offset + math.abs(extremeRumble) * 0.5
		)
		return 
	end

	local currentTime = os.clock()
	local timeRemaining = multiplierExpiration - currentTime

	if currentMultiplier <= 1.01 or timeRemaining <= 0 then
		multiplierLabel.Text = ""
		multiplierLabel.TextTransparency = 0
		multiplierLabel.Position = UDim2.new(0, 0, 0, 0)

		heartGlow.BackgroundColor3 = heartGlow.BackgroundColor3:Lerp(Color3.fromRGB(0, 120, 255), deltaTime * 5)
		heartGlow.Size = heartGlow.Size:Lerp(UDim2.new(1, 0, 1, 0), deltaTime * 10)
		heartGlow.BackgroundTransparency = math.min(heartGlow.BackgroundTransparency + (deltaTime * 6), 1)
		hudContainer.Position = hudContainer.Position:Lerp(BASE_HUD_POSITION, deltaTime * 8)

		scoreLabel.TextColor3 = scoreLabel.TextColor3:Lerp(Color3.fromRGB(255, 255, 255), deltaTime * 5)

		for _, line in ipairs(gridLines) do
			line.Size = line.Size:Lerp(UDim2.new(0, 1, 1, 0), deltaTime * 8)
			line.BackgroundTransparency = math.min(line.BackgroundTransparency + deltaTime * 3, 0.95)
			line.BackgroundColor3 = line.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), deltaTime * 5)
		end
	else
		multiplierLabel.Text = string.format("x%.1f", currentMultiplier)

		local baseMultSize = 24
		local multSizeBonus = math.min((currentMultiplier - 1.0) * 12, 22) 
		multiplierLabel.TextSize = baseMultSize + multSizeBonus

		local colorProgress = math.clamp((currentMultiplier - 1.0) / 2.0, 0, 1)
		local currentThemeColor = Color3.fromRGB(0, 120, 255):Lerp(Color3.fromRGB(255, 30, 60), colorProgress)

		multiplierLabel.TextColor3 = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(255, 30, 60), colorProgress)

		local textShakeIntensity = math.min((currentMultiplier - 1.0) * 6, 16)
		local labelRandomX = (math.random() - 0.5) * textShakeIntensity
		local labelRandomY = (math.random() - 0.5) * textShakeIntensity
		multiplierLabel.Position = UDim2.new(0, labelRandomX, 0, labelRandomY)

		heartGlow.BackgroundColor3 = currentThemeColor

		if timeRemaining <= FLASH_THRESHOLD then
			multiplierLabel.TextTransparency = math.abs(math.sin(currentTime * 22)) * 0.8
		else
			multiplierLabel.TextTransparency = 0
		end

		local pulseSpeedMultiplier = 6.5 + ((currentMultiplier - 1.0) * 2.5)
		local clockTime = currentTime * pulseSpeedMultiplier

		local pulse1 = math.pow(math.sin(clockTime), 12) * 0.28
		local pulse2 = math.pow(math.sin(clockTime - 0.45), 24) * 0.14
		local finalPulseScale = pulse1 + pulse2

		heartGlow.Size = UDim2.new(1, 30 + (finalPulseScale * 120), 1, 20 + (finalPulseScale * 35))
		heartGlow.BackgroundTransparency = math.clamp(0.40 - (finalPulseScale * 1.5), 0.05, 1)

		for i, line in ipairs(gridLines) do
			local targetWidth = 1 + (finalPulseScale * 6)
			line.Size = UDim2.new(0, targetWidth, 1, 0)
			line.BackgroundColor3 = Color3.fromRGB(255, 255, 255):Lerp(currentThemeColor, finalPulseScale)
			line.BackgroundTransparency = math.clamp(0.9 - (finalPulseScale * 2), 0.4, 0.95)

			local baseShift = (currentTime * 0.1) % 1
			local pulseDistortion = finalPulseScale * 0.05
			line.Position = UDim2.new((i / lineCount) * 1.5 - 0.25 + baseShift - pulseDistortion, 0, 0, 0)
		end

		local randomShakeX = (math.random() - 0.5) * 14 * finalPulseScale
		local verticalBounceY = finalPulseScale * 10

		hudContainer.Position = UDim2.new(
			BASE_HUD_POSITION.X.Scale,
			BASE_HUD_POSITION.X.Offset + randomShakeX,
			BASE_HUD_POSITION.Y.Scale,
			BASE_HUD_POSITION.Y.Offset + verticalBounceY
		)
	end
end)