local TweenService = game:GetService("TweenService")

local ActionPanelView = {}
ActionPanelView.__index = ActionPanelView

function ActionPanelView.new(screenGui: Instance)
	local self = setmetatable({}, ActionPanelView)

	local panel = screenGui:FindFirstChild("ActionPanel")
	if not panel then return self end

	self._shopButton = panel:FindFirstChild("ShopButton")
	self._pitchButton = panel:FindFirstChild("PitchButton")
	self._leaderboardButton = panel:FindFirstChild("LeaderboardButton")
	self._rebirthButton = panel:FindFirstChild("RebirthButton")
	self._gmButton = panel:FindFirstChild("GMButton")

	local function applyHover(btn)
		if not btn then return end
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.1,
				Size = UDim2.new(1, 0, 0.34, 0),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.3,
				Size = UDim2.new(1, 0, 0.3, 0),
			}):Play()
		end)
	end

	applyHover(self._shopButton)
	applyHover(self._pitchButton)
	applyHover(self._leaderboardButton)
	applyHover(self._rebirthButton)
	applyHover(self._gmButton)

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

function ActionPanelView:SetLeaderboardCallback(cb: (() -> ())?)
	if self._leaderboardButton then
		self._leaderboardButton.MouseButton1Click:Connect(cb)
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
