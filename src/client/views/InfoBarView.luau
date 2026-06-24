local function createSegment(parent: Instance, xScale: number, icon: string, color: Color3, strokeColor: Color3)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.32, 0, 1, 0)
	frame.Position = UDim2.new(xScale, 0, 0, 0)
	frame.BackgroundColor3 = Color3.new(0.04, 0.04, 0.1)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.ZIndex = 5
	frame.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.08, 0.08, 0.18)),
		ColorSequenceKeypoint.new(1, Color3.new(0.03, 0.03, 0.08)),
	})
	gradient.Rotation = 90
	gradient.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0.25, 0, 1, 0)
	iconLabel.Position = UDim2.new(0, 0, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.ZIndex = 6
	iconLabel.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.72, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.25, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = color
	valueLabel.TextStrokeTransparency = 0.1
	valueLabel.TextStrokeColor3 = strokeColor
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Text = "0"
	valueLabel.ZIndex = 6
	valueLabel.Parent = frame

	return valueLabel
end

local InfoBarView = {}
InfoBarView.__index = InfoBarView

function InfoBarView.new(screenGui: Instance)
	local self = setmetatable({}, InfoBarView)

	local bar = Instance.new("Frame")
	bar.Name = "InfoBar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Size = UDim2.new(0.18, 0, 0.032, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 0.015)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.Parent = screenGui

	self._coinLabel = createSegment(bar, 0, "💵", Color3.new(1, 0.9, 0.1), Color3.new(0.5, 0.3, 0))
	self._powerLabel = createSegment(bar, 0.34, "⚔", Color3.new(1, 0.5, 0.1), Color3.new(0.3, 0.1, 0))
	self._trophyLabel = createSegment(bar, 0.68, "🏆", Color3.new(0.7, 0.85, 1), Color3.new(0, 0, 0.2))

	return self
end

function InfoBarView:UpdateCoins(balance: number)
	if self._coinLabel then
		self._coinLabel.Text = tostring(math.floor(balance))
	end
end

function InfoBarView:UpdatePower(power: number)
	if self._powerLabel then
		self._powerLabel.Text = tostring(power)
	end
end

function InfoBarView:UpdateTrophies(trophies: number)
	if self._trophyLabel then
		self._trophyLabel.Text = tostring(trophies)
	end
end

return InfoBarView
