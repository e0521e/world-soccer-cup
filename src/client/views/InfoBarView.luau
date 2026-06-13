local InfoBarView = {}
InfoBarView.__index = InfoBarView

function InfoBarView.new(screenGui: Instance)
	local self = setmetatable({}, InfoBarView)

	local bar = Instance.new("Frame")
	bar.Name = "InfoBar"
	bar.Size = UDim2.new(0, 150, 0, 52)
	bar.Position = UDim2.new(1, -162, 0, 10)
	bar.BackgroundColor3 = Color3.new(0.04, 0.04, 0.1)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = screenGui

	local barGradient = Instance.new("UIGradient")
	barGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.08, 0.08, 0.18)),
		ColorSequenceKeypoint.new(1, Color3.new(0.03, 0.03, 0.08)),
	})
	barGradient.Rotation = 90
	barGradient.Parent = bar

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = bar

	local barStroke = Instance.new("UIStroke")
	barStroke.Color = Color3.new(0.3, 0.3, 0.6)
	barStroke.Thickness = 1
	barStroke.Transparency = 0.5
	barStroke.Parent = bar

	local coins = Instance.new("TextLabel")
	coins.Name = "CoinsLabel"
	coins.Size = UDim2.new(1, -12, 0, 22)
	coins.Position = UDim2.new(0, 6, 0, 5)
	coins.BackgroundTransparency = 1
	coins.TextColor3 = Color3.new(1, 0.9, 0.1)
	coins.TextStrokeTransparency = 0.1
	coins.TextStrokeColor3 = Color3.new(0.5, 0.3, 0)
	coins.TextScaled = true
	coins.Font = Enum.Font.GothamBold
	coins.TextXAlignment = Enum.TextXAlignment.Right
	coins.Text = "💰0"
	coins.Parent = bar
	self._coinLabel = coins

	local level = Instance.new("TextLabel")
	level.Name = "LevelLabel"
	level.Size = UDim2.new(1, -12, 0, 20)
	level.Position = UDim2.new(0, 6, 0, 28)
	level.BackgroundTransparency = 1
	level.TextColor3 = Color3.new(0.7, 0.85, 1)
	level.TextStrokeTransparency = 0.15
	level.TextStrokeColor3 = Color3.new(0, 0, 0.2)
	level.TextScaled = true
	level.Font = Enum.Font.GothamBold
	level.TextXAlignment = Enum.TextXAlignment.Right
	level.Text = "Lv.1 (x1.0)"
	level.Parent = bar
	self._levelLabel = level

	return self
end

function InfoBarView:UpdateCoins(balance: number)
	if self._coinLabel then
		self._coinLabel.Text = "💰" .. tostring(math.floor(balance))
	end
end

function InfoBarView:UpdateLevel(levelNum: number, multiplier: number)
	if self._levelLabel then
		self._levelLabel.Text = "Lv." .. tostring(levelNum) .. " (x" .. tostring(multiplier) .. ")"
	end
end

return InfoBarView
