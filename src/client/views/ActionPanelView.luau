local TweenService = game:GetService("TweenService")

local ActionPanelView = {}
ActionPanelView.__index = ActionPanelView

local function makeButton(name: string, text: string, color: Color3, gradient: {ColorSequenceKeypoint})
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Button"
	btn.Size = UDim2.new(0, 110, 0, 44)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.2
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.ZIndex = 5

	local btnGradient = Instance.new("UIGradient")
	btnGradient.Color = ColorSequence.new(gradient)
	btnGradient.Rotation = 90
	btnGradient.Parent = btn

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.new(1, 1, 1)
	btnStroke.Thickness = 1
	btnStroke.Transparency = 0.8
	btnStroke.Parent = btn

	return btn
end

function ActionPanelView.new(screenGui: Instance)
	local self = setmetatable({}, ActionPanelView)

	local panel = Instance.new("Frame")
	panel.Name = "ActionPanel"
	panel.Size = UDim2.new(0, 110, 0, 104)
	panel.Position = UDim2.new(1, -130, 0.5, -52)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.ZIndex = 5
	panel.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = panel

	local shop = makeButton("Shop", "🏪 Shop", Color3.new(0.1, 0.4, 0.25), {
		ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.55, 0.3)),
		ColorSequenceKeypoint.new(1, Color3.new(0.08, 0.3, 0.18)),
	})
	shop.LayoutOrder = 1
	shop.Parent = panel

	local rebirth = makeButton("Rebirth", "🔄 Rebirth", Color3.new(0.4, 0.1, 0.1), {
		ColorSequenceKeypoint.new(0, Color3.new(0.55, 0.15, 0.15)),
		ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.08, 0.08)),
	})
	rebirth.LayoutOrder = 2
	rebirth.Parent = panel

	local function applyHover(btn: TextButton, baseColor: Color3, highlightColor: Color3)
		btn.MouseEnter:Connect(function()
			local hoverTween = TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
				Size = UDim2.new(0, 116, 0, 48),
			})
			hoverTween:Play()
		end)
		btn.MouseLeave:Connect(function()
			local leaveTween = TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.2,
				Size = UDim2.new(0, 110, 0, 44),
			})
			leaveTween:Play()
		end)
	end

	applyHover(shop, Color3.new(0.1, 0.4, 0.25), Color3.new(0.15, 0.55, 0.3))
	applyHover(rebirth, Color3.new(0.4, 0.1, 0.1), Color3.new(0.55, 0.15, 0.15))

	self._shopButton = shop
	self._rebirthButton = rebirth

	return self
end

function ActionPanelView:SetShopCallback(cb: (() -> ())?)
	if self._shopButton then
		self._shopButton.MouseButton1Click:Connect(cb)
	end
end

function ActionPanelView:SetRebirthCallback(cb: (() -> ())?)
	if self._rebirthButton then
		self._rebirthButton.MouseButton1Click:Connect(cb)
	end
end

return ActionPanelView
