local TweenService = game:GetService("TweenService")

local OverlayView = {}
OverlayView.__index = OverlayView

function OverlayView.new(screenGui: Instance)
	local self = setmetatable({}, OverlayView)

	local container = Instance.new("Frame")
	container.Name = "GoalOverlay"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Position = UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = 10
	container.Visible = false
	container.Parent = screenGui

	local goal = Instance.new("TextLabel")
	goal.Name = "GoalLabel"
	goal.Size = UDim2.new(0, 500, 0, 120)
	goal.Position = UDim2.new(0.5, -250, 0.5, -60)
	goal.BackgroundTransparency = 1
	goal.TextColor3 = Color3.new(1, 1, 0.3)
	goal.TextStrokeTransparency = 0
	goal.TextStrokeColor3 = Color3.new(0.8, 0.3, 0)
	goal.TextScaled = true
	goal.Font = Enum.Font.GothamBlack
	goal.Text = "GOAL!"
	goal.ZIndex = 12
	goal.Parent = container

	local shadow = Instance.new("TextLabel")
	shadow.Name = "GoalShadow"
	shadow.Size = UDim2.new(0, 500, 0, 120)
	shadow.Position = UDim2.new(0.5, -248, 0.5, -58)
	shadow.BackgroundTransparency = 1
	shadow.TextColor3 = Color3.new(1, 0.4, 0)
	shadow.TextStrokeTransparency = 1
	shadow.TextScaled = true
	shadow.Font = Enum.Font.GothamBlack
	shadow.Text = "GOAL!"
	shadow.ZIndex = 11
	shadow.Parent = container

	self._container = container
	self._goalLabel = goal
	self._shadow = shadow

	return self
end

function OverlayView:ShowGoal()
	if not self._goalLabel then return end

	local c = self._container
	local g = self._goalLabel
	local s = self._shadow

	c.Visible = true
	g.TextTransparency = 0
	g.TextColor3 = Color3.new(1, 1, 0.3)
	g.Size = UDim2.new(0, 500, 0, 120)
	g.Position = UDim2.new(0.5, -250, 0.5, -60)
	s.TextTransparency = 0.5
	s.Size = UDim2.new(0, 500, 0, 120)
	s.Position = UDim2.new(0.5, -248, 0.5, -58)

	local scaleUp = TweenService:Create(g, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 620, 0, 150),
	})
	local shadowScale = TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 620, 0, 150),
	})
	scaleUp:Play()
	shadowScale:Play()
	scaleUp.Completed:Wait()

	task.wait(0.8)

	local fadeOut = TweenService:Create(g, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		Position = UDim2.new(0.5, -250, 0.25, -60),
	})
	local shadowFade = TweenService:Create(s, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		Position = UDim2.new(0.5, -248, 0.25, -58),
	})
	fadeOut:Play()
	shadowFade:Play()
	fadeOut.Completed:Connect(function()
		c.Visible = false
	end)
end

return OverlayView
