local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)

local TOTAL_NPCS = Constants.ACTIVE_NPC_COUNT
local TOTAL_DOTS = TOTAL_NPCS + 1
local NPC_UNLOCK_INTERVAL = Constants.NPC_UNLOCK_COUNTDOWN
local TOTAL_DURATION = Constants.ONLINE_TOTAL_MINUTES * 60

local DOT_SIZE = 10
local BAR_WIDTH = 320
local BAR_HEIGHT = 56
local TRACK_LEFT = 14
local TRACK_RIGHT = 14
local TRACK_WIDTH = BAR_WIDTH - TRACK_LEFT - TRACK_RIGHT

local CoreBarView = {}
CoreBarView.__index = CoreBarView

function CoreBarView.new(screenGui: Instance)
	local self = setmetatable({}, CoreBarView)

	local bar = Instance.new("Frame")
	bar.Name = "CoreBar"
	bar.Size = UDim2.new(0, BAR_WIDTH, 0, BAR_HEIGHT)
	bar.Position = UDim2.new(0.5, -BAR_WIDTH / 2, 0, 10)
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

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimerLabel"
	timeLabel.Size = UDim2.new(0, 70, 0, 18)
	timeLabel.Position = UDim2.new(0.5, -35, 0, 5)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.new(1, 1, 1)
	timeLabel.TextStrokeTransparency = 0.15
	timeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextXAlignment = Enum.TextXAlignment.Center
	timeLabel.Text = "00:00"
	timeLabel.Parent = bar

	local trackBg = Instance.new("Frame")
	trackBg.Name = "TrackBg"
	trackBg.Size = UDim2.new(0, TRACK_WIDTH, 0, 3)
	trackBg.Position = UDim2.new(0, TRACK_LEFT, 0, BAR_HEIGHT - 16)
	trackBg.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
	trackBg.BackgroundTransparency = 0.3
	trackBg.BorderSizePixel = 0
	trackBg.ZIndex = 5
	trackBg.Parent = bar

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = trackBg

	local trackFill = Instance.new("Frame")
	trackFill.Name = "TrackFill"
	trackFill.Size = UDim2.new(0, 0, 0, 3)
	trackFill.Position = UDim2.new(0, 0, 0, 0)
	trackFill.BackgroundColor3 = Color3.new(1, 0.85, 0.1)
	trackFill.BorderSizePixel = 0
	trackFill.ZIndex = 6
	trackFill.Parent = trackBg

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.9, 0.3)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.85, 0.1)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 0.5, 0.05)),
	})
	fillGradient.Rotation = 0
	fillGradient.Parent = trackFill

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = trackFill

	self._bar = bar
	self._timeLabel = timeLabel
	self._trackFill = trackFill
	self._trackBg = trackBg
	self._dots = {}

	for i = 1, TOTAL_DOTS do
		local dotX = TRACK_WIDTH * (i - 1) / TOTAL_NPCS

		local dot = Instance.new("Frame")
		dot.Name = "Dot_" .. tostring(i)
		dot.Size = UDim2.new(0, DOT_SIZE, 0, DOT_SIZE)
		dot.Position = UDim2.new(0, dotX - DOT_SIZE / 2, 0.5, -DOT_SIZE / 2)
		dot.BackgroundColor3 = Color3.new(0.25, 0.25, 0.35)
		dot.BorderSizePixel = 0
		dot.ZIndex = 7
		dot.Parent = trackBg

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0.5, 0)
		dotCorner.Parent = dot

		local dotStroke = Instance.new("UIStroke")
		dotStroke.Color = Color3.new(0.4, 0.4, 0.5)
		dotStroke.Thickness = 1
		dotStroke.Transparency = 0.4
		dotStroke.Parent = dot

		local dotGlow = Instance.new("Frame")
		dotGlow.Name = "Glow"
		dotGlow.Size = UDim2.new(0, 15, 0, 15)
		dotGlow.Position = UDim2.new(0.5, -4, 0.5, -4)
		dotGlow.BackgroundColor3 = Color3.new(1, 0.85, 0.1)
		dotGlow.BackgroundTransparency = 1
		dotGlow.BorderSizePixel = 0
		dotGlow.ZIndex = 6
		dotGlow.Parent = dot

		local glowCorner = Instance.new("UICorner")
		glowCorner.CornerRadius = UDim.new(0.5, 0)
		glowCorner.Parent = dotGlow

		self._dots[i] = {
			dot = dot,
			glow = dotGlow,
			stroke = dotStroke,
		}
	end

	return self
end

function CoreBarView:UpdateTime(totalSeconds: number)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	self._timeLabel.Text = string.format("%02d:%02d", minutes, seconds)

	local filledDots = math.min(math.floor(totalSeconds / NPC_UNLOCK_INTERVAL) + 1, TOTAL_DOTS)

	local fillRatio = math.min(totalSeconds / TOTAL_DURATION, 1)
	self._trackFill.Size = UDim2.new(0, TRACK_WIDTH * fillRatio, 0, 3)

	for i = 1, TOTAL_DOTS do
		local entry = self._dots[i]
		if not entry then continue end
		local isFilled = i <= filledDots
		local isActive = i == filledDots and filledDots < TOTAL_DOTS and i > 1

		if i == 1 then
			entry.dot.BackgroundColor3 = Color3.new(0.3, 0.5, 0.8)
			entry.stroke.Transparency = 0.3
			entry.stroke.Color = Color3.new(0.4, 0.6, 0.9)
			entry.glow.BackgroundTransparency = 1
		elseif isFilled then
			local baseColor = if isActive then Color3.new(1, 1, 0.4) else Color3.new(1, 0.85, 0.1)
			entry.dot.BackgroundColor3 = baseColor
			entry.stroke.Transparency = 0
			entry.stroke.Color = Color3.new(1, 0.9, 0.2)
			entry.glow.BackgroundTransparency = if isActive then 0.5 else 1
		else
			entry.dot.BackgroundColor3 = Color3.new(0.25, 0.25, 0.35)
			entry.stroke.Transparency = 0.4
			entry.stroke.Color = Color3.new(0.4, 0.4, 0.5)
			entry.glow.BackgroundTransparency = 1
		end
	end
end

return CoreBarView
