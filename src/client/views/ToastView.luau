local TweenService = game:GetService("TweenService")

local DEFAULT_DURATION = 2
local ANIM_IN = 0.3
local ANIM_OUT = 0.4
local TOAST_WIDTH = 340

local ToastView = {}
ToastView.__index = ToastView

function ToastView.new(screenGui: Instance)
	local self = setmetatable({}, ToastView)

	self._container = Instance.new("Frame")
	self._container.Name = "ToastContainer"
	self._container.Size = UDim2.new(0, 0, 0, 0)
	self._container.Position = UDim2.new(0.5, 0, 0.38, 0)
	self._container.AnchorPoint = Vector2.new(0.5, 0.5)
	self._container.BackgroundTransparency = 1
	self._container.Parent = screenGui

	self._queue = {}
	self._active = false

	return self
end

function ToastView:Show(options)
	table.insert(self._queue, options)
	if not self._active then
		self:_ProcessQueue()
	end
end

function ToastView:_ProcessQueue()
	if #self._queue == 0 then
		self._active = false
		return
	end
	self._active = true
	local opts = table.remove(self._queue, 1)
	self:_Display(opts)
end

function ToastView:_BuildContent(bg, opts)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = bg

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.Parent = bg

	if opts.emoji or opts.title then
		local row = Instance.new("Frame")
		row.Name = "HeaderRow"
		row.Size = UDim2.new(1, 0, 0, 0)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.LayoutOrder = 1
		row.Parent = bg

		local rowList = Instance.new("UIListLayout")
		rowList.FillDirection = Enum.FillDirection.Horizontal
		rowList.VerticalAlignment = Enum.VerticalAlignment.Center
		rowList.Padding = UDim.new(0, 10)
		rowList.SortOrder = Enum.SortOrder.LayoutOrder
		rowList.Parent = row

		if opts.emoji and opts.emoji ~= "" then
			local emoji = Instance.new("TextLabel")
			emoji.Name = "Emoji"
			emoji.Size = UDim2.new(0, 32, 0, 32)
			emoji.BackgroundTransparency = 1
			emoji.TextColor3 = Color3.new(1, 1, 1)
			emoji.TextScaled = true
			emoji.Font = Enum.Font.GothamBold
			emoji.Text = opts.emoji
			emoji.LayoutOrder = 1
			emoji.Parent = row
		end

		if opts.title and opts.title ~= "" then
			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Size = UDim2.new(0, TOAST_WIDTH - 100, 0, 32)
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
		body.Size = UDim2.new(0, TOAST_WIDTH - 36, 0, 0)
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
	borderGlow.Size = UDim2.new(0, TOAST_WIDTH + 4, 0, 0)
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
	bg.Size = UDim2.new(0, TOAST_WIDTH, 0, 0)
	bg.AutomaticSize = Enum.AutomaticSize.Y
	bg.BackgroundColor3 = Color3.new(0.05, 0.05, 0.12)
	bg.BackgroundTransparency = 0.1
	bg.BorderSizePixel = 0
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.ZIndex = 50
	bg.Parent = self._container

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.08, 0.08, 0.18)),
		ColorSequenceKeypoint.new(1, Color3.new(0.04, 0.04, 0.1)),
	})
	bgGradient.Rotation = 90
	bgGradient.Parent = bg

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 10)
	bgCorner.Parent = bg

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.new(0.4, 0.5, 0.8)
	bgStroke.Thickness = 1
	bgStroke.Transparency = 0.45
	bgStroke.Parent = bg

	self:_BuildContent(bg, opts)

	bg.Size = UDim2.new(0, TOAST_WIDTH, 0, 0)
	borderGlow.Size = UDim2.new(0, TOAST_WIDTH + 4, 0, 0)

	task.wait()

	local targetHeight = bg.AbsoluteSize.Y
	if targetHeight < 1 then targetHeight = 60 end

	local scaleIn = TweenService:Create(bg, TweenInfo.new(ANIM_IN, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, TOAST_WIDTH, 0, targetHeight),
	})
	local glowIn = TweenService:Create(borderGlow, TweenInfo.new(ANIM_IN, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.6,
		Size = UDim2.new(0, TOAST_WIDTH + 4, 0, targetHeight + 4),
	})
	scaleIn:Play()
	glowIn:Play()
	scaleIn.Completed:Wait()

	task.wait(duration)

	local fadeOut = TweenService:Create(bg, TweenInfo.new(ANIM_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	local glowOut = TweenService:Create(borderGlow, TweenInfo.new(ANIM_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	fadeOut:Play()
	glowOut:Play()
	fadeOut.Completed:Wait()

	bg:Destroy()
	borderGlow:Destroy()

	if opts.onComplete then
		task.spawn(opts.onComplete)
	end

	self:_ProcessQueue()
end

return ToastView
