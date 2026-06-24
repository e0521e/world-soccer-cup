local TweenService = game:GetService("TweenService")

local DEFAULT_DURATION = 2
local ANIM_IN = 0.3
local ANIM_OUT = 0.4

local ToastView = {}
ToastView.__index = ToastView

function ToastView.new(screenGui: Instance)
	local self = setmetatable({}, ToastView)

	self._container = Instance.new("Frame")
	self._container.Name = "ToastContainer"
	self._container.Size = UDim2.new(0.2, 0, 0, 0)
	self._container.Position = UDim2.new(0.5, 0, 0.38, 0)
	self._container.AnchorPoint = Vector2.new(0.5, 0.5)
	self._container.BackgroundTransparency = 1
	self._container.Parent = screenGui

	self._queue = {}
	self._isDisplaying = false

	return self
end

function ToastView:Show(options)
	local opts = {
		emoji = options.emoji or "",
		title = options.title or "",
		body = options.body or "",
		duration = options.duration or DEFAULT_DURATION,
	}
	table.insert(self._queue, opts)
	self:_ProcessQueue()
end

function ToastView:_ProcessQueue()
	if self._isDisplaying or #self._queue == 0 then return end
	self._isDisplaying = true
	local opts = table.remove(self._queue, 1)
	self:_Display(opts)
end

function ToastView:_BuildContent(bg, opts)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = bg

	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 4)
	list.Parent = bg

	if opts.emoji and opts.emoji ~= "" then
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
		row.LayoutOrder = 1
		row.Parent = bg

		local emoji = Instance.new("TextLabel")
		emoji.Size = UDim2.new(0, 28, 1, 0)
		emoji.BackgroundTransparency = 1
		emoji.Text = opts.emoji
		emoji.TextScaled = true
		emoji.Font = Enum.Font.GothamBold
		emoji.TextXAlignment = Enum.TextXAlignment.Left
		emoji.LayoutOrder = 1
		emoji.Parent = row

		if opts.title and opts.title ~= "" then
			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Size = UDim2.new(1, -36, 1, 0)
			title.BackgroundTransparency = 1
			title.TextColor3 = Color3.new(1, 1, 1)
			title.TextStrokeTransparency = 0.15
			title.TextStrokeColor3 = Color3.new(0, 0, 0)
			title.TextScaled = true
			title.Font = Enum.Font.GothamBold
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Text = opts.title
			title.LayoutOrder = 2
			title.Parent = row
		end
	end

	if opts.body and opts.body ~= "" then
		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.Size = UDim2.new(1, -28, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.BackgroundTransparency = 1
		body.TextColor3 = Color3.new(0.9, 0.9, 1)
		body.TextStrokeTransparency = 0.25
		body.TextStrokeColor3 = Color3.new(0, 0, 0)
		body.TextSize = 16
		body.Font = Enum.Font.Gotham
		body.RichText = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.Text = opts.body
		body.LayoutOrder = 2
		body.Parent = bg
	end
end

function ToastView:_Display(opts)
	local duration = opts.duration or DEFAULT_DURATION

	local borderGlow = Instance.new("Frame")
	borderGlow.Name = "ToastGlow"
	borderGlow.Size = UDim2.new(0.94, 0, 0, 0)
	borderGlow.AutomaticSize = Enum.AutomaticSize.Y
	borderGlow.BackgroundColor3 = Color3.new(0.4, 0.6, 1)
	borderGlow.BackgroundTransparency = 1
	borderGlow.BorderSizePixel = 0
	borderGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	borderGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	borderGlow.ZIndex = 49
	borderGlow.Parent = self._container

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 10)
	glowCorner.Parent = borderGlow

	local bg = Instance.new("Frame")
	bg.Name = "Toast"
	bg.Size = UDim2.new(0.9, 0, 0, 0)
	bg.AutomaticSize = Enum.AutomaticSize.Y
	bg.BackgroundColor3 = Color3.new(0.05, 0.05, 0.12)
	bg.BackgroundTransparency = 0.15
	bg.BorderSizePixel = 0
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.ZIndex = 50
	bg.Parent = self._container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 10)
	bgCorner.Parent = bg

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.new(0.4, 0.6, 1)
	bgStroke.Thickness = 1
	bgStroke.Transparency = 0.6
	bgStroke.Parent = bg

	self:_BuildContent(bg, opts)

	local targetHeight = bg.AbsoluteSize.Y
	if targetHeight < 1 then
		task.wait()
		targetHeight = bg.AbsoluteSize.Y
		if targetHeight < 1 then targetHeight = 60 end
	end

	local bgTarget = UDim2.new(0.9, 0, 0, targetHeight)
	local glowTarget = UDim2.new(0.94, 0, 0, targetHeight + 6)

	local inTweenBg = TweenService:Create(bg, TweenInfo.new(ANIM_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = bgTarget,
	})
	local inTweenGlow = TweenService:Create(borderGlow, TweenInfo.new(ANIM_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = glowTarget,
		BackgroundTransparency = 0.6,
	})
	inTweenBg:Play()
	inTweenGlow:Play()

	task.delay(duration, function()
		local outTweenBg = TweenService:Create(bg, TweenInfo.new(ANIM_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		local outTweenGlow = TweenService:Create(borderGlow, TweenInfo.new(ANIM_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		outTweenBg:Play()
		outTweenGlow:Play()
		outTweenBg.Completed:Connect(function()
			bg:Destroy()
			borderGlow:Destroy()
			self._isDisplaying = false
			self:_ProcessQueue()
		end)
	end)
end

return ToastView
