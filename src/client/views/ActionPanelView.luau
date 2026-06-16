local TweenService = game:GetService("TweenService")

local ActionPanelView = {}
ActionPanelView.__index = ActionPanelView

local function makeButton(name: string, text: string, color: Color3, gradient: {ColorSequenceKeypoint})
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Button"
	btn.Size = UDim2.new(0, 130, 0, 50)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.3
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 18
	btn.Font = Enum.Font.GothamBold
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.new(0, 0, 0)
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.ZIndex = 5

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	return btn
end

function ActionPanelView.new(screenGui: Instance)
	local self = setmetatable({}, ActionPanelView)

	local panel = Instance.new("Frame")
	panel.Name = "ActionPanel"
	panel.Size = UDim2.new(0, 130, 0, 240)
	panel.Position = UDim2.new(1, -150, 0.5, -120)
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

	local pitch = makeButton("Pitch", "🏟️ Pitch", Color3.new(0.15, 0.25, 0.5), {
		ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.35, 0.65)),
		ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.2, 0.4)),
	})
	pitch.LayoutOrder = 2
	pitch.Parent = panel

	local rebirth = makeButton("Rebirth", "🔄 Rebirth", Color3.new(0.4, 0.1, 0.1), {
		ColorSequenceKeypoint.new(0, Color3.new(0.55, 0.15, 0.15)),
		ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.08, 0.08)),
	})
	rebirth.LayoutOrder = 3
	rebirth.Parent = panel

	local gm = makeButton("GM", "⚙️ GM", Color3.new(0.5, 0.15, 0.05), {
		ColorSequenceKeypoint.new(0, Color3.new(0.65, 0.2, 0.08)),
		ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.1, 0.03)),
	})
	gm.LayoutOrder = 4
	gm.Parent = panel
	gm.Visible = false

	local function applyHover(btn)
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.1,
				Size = UDim2.new(0, 136, 0, 54),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.3,
				Size = UDim2.new(0, 130, 0, 50),
			}):Play()
		end)
	end

	applyHover(shop)
	applyHover(pitch)
	applyHover(rebirth)
	applyHover(gm)

	self._shopButton = shop
	self._pitchButton = pitch
	self._rebirthButton = rebirth
	self._gmButton = gm

	return self
end

function ActionPanelView:SetShopCallback(cb: (() -> ())?)
	if self._shopButton then
		self._shopButton.MouseButton1Click:Connect(cb)
	end
end

function ActionPanelView:SetPitchCallback(cb: (() -> ())?)
	if self._pitchButton then
		self._pitchButton.MouseButton1Click:Connect(cb)
	end
end

function ActionPanelView:SetRebirthCallback(cb: (() -> ())?)
	if self._rebirthButton then
		self._rebirthButton.MouseButton1Click:Connect(cb)
	end
end

function ActionPanelView:SetGMCallback(cb: (() -> ())?)
	if self._gmButton then
		self._gmButton.MouseButton1Click:Connect(cb)
	end
end

function ActionPanelView:ShowGM(show: boolean)
	if self._gmButton then
		self._gmButton.Visible = show
	end
end

return ActionPanelView
