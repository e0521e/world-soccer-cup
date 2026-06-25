local InfoBarView = {}
InfoBarView.__index = InfoBarView
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)

function InfoBarView.new(screenGui: Instance)
	local self = setmetatable({}, InfoBarView)

	local bar = screenGui:FindFirstChild("InfoBar")
	if not bar then return self end

	local coinSeg = bar:FindFirstChild("CoinSegment")
	if coinSeg then
		self._coinLabel = coinSeg:FindFirstChild("Value")
		self._coinIcon = coinSeg:FindFirstChild("Icon")
	end

	local powerSeg = bar:FindFirstChild("PowerSegment")
	if powerSeg then
		self._powerLabel = powerSeg:FindFirstChild("Value")
	end

	local trophySeg = bar:FindFirstChild("TrophySegment")
	if trophySeg then
		self._trophyLabel = trophySeg:FindFirstChild("Value")
	end

	return self
end

function InfoBarView:UpdateCoins(balance: number)
	if self._coinLabel then
		self._coinLabel.Text = Constants.FormatCoins(balance)
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
