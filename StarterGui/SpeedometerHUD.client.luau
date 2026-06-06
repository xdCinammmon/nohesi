local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

-- 🎛️ SPEED CONFIGURATION
local BASE_SPEED = 90
local MIN_SPEED = 60
local MAX_SPEED = 300 

-- [[ SPEEDOMETER UI GENERATOR ]]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DigitalSpeedometerHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false -- 🔒 START DISABLED: Keeps HUD hidden while on menu tabs
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- 💠 MAIN HUD HUB 
local dashContainer = Instance.new("Frame")
dashContainer.Name = "DashContainer"
dashContainer.Size = UDim2.new(0, 500, 0, 200)
dashContainer.Position = UDim2.new(0.92, 0, 0.90, 0)
dashContainer.AnchorPoint = Vector2.new(1, 1)
dashContainer.BackgroundTransparency = 1
dashContainer.Parent = screenGui

-- 🔢 LARGE DIGITAL SPEED TEXT
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(0, 200, 0, 75)
speedLabel.Position = UDim2.new(0, 260, 0, 130)
speedLabel.AnchorPoint = Vector2.new(1, 0.5)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 76
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Right
speedLabel.Text = "0"
speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
speedLabel.TextStrokeTransparency = 0
speedLabel.Parent = dashContainer

-- 🏁 KM/H INDICATOR LABEL
local kmhLabel = Instance.new("TextLabel")
kmhLabel.Name = "KMHLabel"
kmhLabel.Size = UDim2.new(0, 60, 0, 20)
kmhLabel.Position = UDim2.new(0, 272, 0, 140)
kmhLabel.AnchorPoint = Vector2.new(0, 0.5)
kmhLabel.BackgroundTransparency = 1
kmhLabel.Font = Enum.Font.GothamBold
kmhLabel.TextSize = 16
kmhLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
kmhLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
kmhLabel.TextStrokeTransparency = 0
kmhLabel.Parent = dashContainer

-- ⚙️ DIGITAL GEAR READOUT PANEL
local gearLabel = Instance.new("TextLabel")
gearLabel.Name = "GearLabel"
gearLabel.Size = UDim2.new(0, 56, 0, 56)
gearLabel.Position = UDim2.new(0, 365, 0, 130)
gearLabel.AnchorPoint = Vector2.new(0.5, 0.5)
gearLabel.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
gearLabel.BackgroundTransparency = 0.15
gearLabel.Font = Enum.Font.GothamBold
gearLabel.TextSize = 38
gearLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gearLabel.Text = "N"
gearLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
gearLabel.TextStrokeTransparency = 0
gearLabel.Parent = dashContainer

local gearCorner = Instance.new("UICorner")
gearCorner.CornerRadius = UDim.new(0, 10)
gearCorner.Parent = gearLabel

-- [[ SOLID FLAT PROGRESS TACHOMETER TRACK ]]
local trackWidth = 320
local trackHeight = 14
local trackStartX = 45
local trackStartY = 65

local gaugeBackground = Instance.new("Frame")
gaugeBackground.Name = "GaugeBackground"
gaugeBackground.Size = UDim2.new(0, trackWidth, 0, trackHeight)
gaugeBackground.Position = UDim2.new(0, trackStartX, 0, trackStartY)
gaugeBackground.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
gaugeBackground.BackgroundTransparency = 0.35
gaugeBackground.Parent = dashContainer

local trackStroke = Instance.new("UIStroke")
trackStroke.Thickness = 2
trackStroke.Color = Color3.fromRGB(0, 0, 0)
trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
trackStroke.Parent = gaugeBackground

local gaugeFill = Instance.new("Frame")
gaugeFill.Name = "GaugeFill"
gaugeFill.Size = UDim2.new(0, 0, 1, 0) 
gaugeFill.BackgroundColor3 = Color3.fromRGB(245, 248, 255) 
gaugeFill.BorderSizePixel = 0
gaugeFill.Parent = gaugeBackground

-- [[ SIMULATOR ENGINE TRANSMISSION PARAMETERS ]]
local gearRanges = {
	{min = 0,   max = 75},   
	{min = 75,  max = 120},  
	{min = 120, max = 175},  
	{min = 175, max = 235},  
	{min = 235, max = 400}   
}

local currentRPM = 1000
local currentGear = 1

-- [[ CORE DATA RENDERING LOOP ]]
RunService.RenderStepped:Connect(function(deltaTime)
	local character = localPlayer.Character
	if not character then 
		screenGui.Enabled = false
		return 
	end

	-- 🛡️ MAIN MENU GATING MATRIX
	local inMenu = character:GetAttribute("InMenu")
	if inMenu == nil or inMenu == true then
		if screenGui.Enabled then screenGui.Enabled = false end
		return
	else
		if not screenGui.Enabled then screenGui.Enabled = true end
	end

	local values = character:FindFirstChild("Values")
	if values and values:FindFirstChild("MAX_SPEED") then
		MAX_SPEED = values.MAX_SPEED.Value
	end

	local speed = character:GetAttribute("CurrentSpeed") or BASE_FORWARD_SPEED
	speedLabel.Text = string.format("%d", math.floor(speed))

	-- 🏎️ SPEED-HEAT COLOR ENGINE
	local speedHeat = math.clamp(speed / MAX_SPEED, 0, 1)
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(255, 80, 50), speedHeat)

	local isAccelerating = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)
	local isBraking = UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)

	for i, range in ipairs(gearRanges) do
		if speed >= range.min then currentGear = i end
	end

	local activeRange = gearRanges[currentGear]
	local speedFactor = (speed - activeRange.min) / (activeRange.max - activeRange.min)
	speedFactor = math.clamp(speedFactor, 0, 1)

	local minPowerBandRPM = 4500
	local maxPowerBandRPM = 13000
	local baseTargetRPM = minPowerBandRPM + (speedFactor * (maxPowerBandRPM - minPowerBandRPM))

	if isAccelerating then
		baseTargetRPM = baseTargetRPM + 1500 
	elseif isBraking then
		baseTargetRPM = baseTargetRPM - 2000 
	else
		baseTargetRPM = baseTargetRPM - 800  
	end

	local targetRPM = math.clamp(baseTargetRPM, 1000, 14000)
	currentRPM = currentRPM + (targetRPM - currentRPM) * math.clamp(deltaTime * 16, 0, 1)
	gearLabel.Text = tostring(currentGear)

	-- Redline warning
	if currentRPM >= 11000 then
		gearLabel.TextColor3 = Color3.fromRGB(255, 35, 65) 
		local flashPulse = math.abs(math.sin(os.clock() * 26))
		gearLabel.BackgroundTransparency = 0.1 + (flashPulse * 0.4)
	else
		gearLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		gearLabel.BackgroundTransparency = 0.2
	end

	local fillProgress = math.clamp((currentRPM - 1000) / 13000, 0, 1)
	gaugeFill.Size = UDim2.new(fillProgress, 0, 1, 0)

	if currentRPM >= 10000 then
		gaugeFill.BackgroundColor3 = Color3.fromRGB(255, 35, 55) 
	else
		gaugeFill.BackgroundColor3 = Color3.fromRGB(245, 248, 255)
	end
end)