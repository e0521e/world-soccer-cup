local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)

local ToastView = require(script.Parent.Parent.views.ToastView)
local CoreBarView = require(script.Parent.Parent.views.CoreBarView)
local InfoBarView = require(script.Parent.Parent.views.InfoBarView)
local ActionPanelView = require(script.Parent.Parent.views.ActionPanelView)
local OverlayView = require(script.Parent.Parent.views.OverlayView)
local ShopView = require(script.Parent.Parent.views.ShopView)

local function getNPCName(npcId: string): string
	for _, npc in ipairs(NPCData.NPCList) do
		if npc.id == npcId then
			return npc.displayName
		end
	end
	return npcId
end

local UIController = Knit.CreateController({
	Name = "UIController",

	_screenGui = nil,
	_teamDone = false,
	_lastLevel = nil,

	KnitStart = function(self)
		self._reward = Knit.GetService("RewardService")
		self._autoKick = Knit.GetService("AutoKickService")
		self._npcProgress = Knit.GetService("NPCProgressService")

		self:_CreateHUD()

		task.spawn(function()
			while true do
				task.wait(1)
				local totalSeconds = self._npcProgress:GetElapsedTime()
				self._coreBar:UpdateTime(totalSeconds)
				local coins = self._reward:GetCoins()
				self._infoBar:UpdateCoins(coins)
				local levelInfo = self._reward:GetLevel()
				if levelInfo and self._lastLevel ~= levelInfo.level then
					local prevLevel = self._lastLevel
					self._lastLevel = levelInfo.level
					self._infoBar:UpdateLevel(levelInfo.level, levelInfo.multiplier)
					if prevLevel ~= nil then
						self._toast:Show({
							emoji = "⬆",
							title = "LEVEL UP!",
							body = "Lv." .. tostring(levelInfo.level) .. " (x" .. tostring(levelInfo.multiplier) .. ")",
							duration = 2,
						})
					end
				end
				local teamCompleteSec = Constants.ONLINE_TOTAL_MINUTES * 60
				if totalSeconds >= teamCompleteSec and not self._teamDone then
					self._teamDone = true
					self._toast:Show({
						emoji = "🏆",
						title = "Team Complete!",
						duration = 3,
					})
				end
			end
		end)

		self._autoKick.OnGoalScored:Connect(function(player, slotId, npcId)
			if player ~= Players.LocalPlayer then return end
			self._overlay:ShowGoal()
			self._toast:Show({
				emoji = "⚽",
				title = "GOAL!",
				duration = 2,
			})
		end)

		local npcTimer = Knit.GetService("NPCTimerService")
		npcTimer.OnNPCActivated:Connect(function(player, slotId, npcId, duration)
			if player ~= Players.LocalPlayer then return end
			local name = getNPCName(npcId)
			self._toast:Show({
				emoji = "⏳",
				title = name,
				body = "Ready in <b>" .. tostring(duration) .. "</b>s",
				duration = 2,
			})
		end)
		npcTimer.OnTimerExpired:Connect(function(player, slotId, npcId)
			if player ~= Players.LocalPlayer then return end
			local name = getNPCName(npcId)
			self._toast:Show({
				emoji = "✅",
				title = name,
				body = "Ready! Press <b>E</b>",
				duration = 3,
			})
		end)

		self._infoBar:UpdateCoins(self._reward:GetCoins())
	end,

	KnitInit = function(self)
		print("UIController initialized")
	end,

	_CreateHUD = function(self)
		self._screenGui = Instance.new("ScreenGui")
		self._screenGui.Name = "FreeKickHUD"
		self._screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		self._screenGui.ResetOnSpawn = false
		self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		self._toast = ToastView.new(self._screenGui)
		self._coreBar = CoreBarView.new(self._screenGui)
		self._infoBar = InfoBarView.new(self._screenGui)
		self._actionPanel = ActionPanelView.new(self._screenGui)
		self._overlay = OverlayView.new(self._screenGui)

		self._shopView = ShopView.new(self._screenGui)

		self._actionPanel:SetShopCallback(function()
			self._shopView._activeTab = "Products"
			self._shopView:Open()
		end)

		self._actionPanel:SetRebirthCallback(function()
			self._toast:Show({
				emoji = "🔄",
				title = "Rebirth",
				body = "Coming soon...",
				duration = 2,
			})
		end)
	end,
})

return UIController
