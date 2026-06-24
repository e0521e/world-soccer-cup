local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)

local DISPLAY_COUNT = 100
local REFRESH_INTERVAL = 15

local function avatarUrl(userId: string): string
	return Constants.USER_ICON_TEMPLATE:format(tostring(userId))
end

local LeaderboardController = Knit.CreateController({
	Name = "LeaderboardController",

	_gui = nil,
	_paused = false,

	_FindGui = function(self)
		local boardModel = Workspace:FindFirstChild("Leaderboard")
		if not boardModel then return nil end
		local display = boardModel:FindFirstChild("DisplayBoard")
		if not display then return nil end
		return display:FindFirstChild("LeaderboardGui")
	end,

	_UpdateDisplay = function(self)
		if self._paused then return end
		local gui = self._gui
		if not gui then
			gui = self:_FindGui()
			if not gui then return end
			self._gui = gui
		end

		local svc = Knit.GetService("LeaderboardService")
		local ok, entries = pcall(function()
			return svc:GetTopPlayers(DISPLAY_COUNT)
		end)
		if not ok or not entries then return end

		local rowList = gui:FindFirstChild("RowList")
		if not rowList then return end

		local localUserId = Players.LocalPlayer.UserId
		for i = 1, DISPLAY_COUNT do
			local entry = entries[i]
			local rankLabel = rowList:FindFirstChild("Rank_" .. tostring(i))
			local avatarLabel = rowList:FindFirstChild("Avatar_" .. tostring(i))
			local nameLabel = rowList:FindFirstChild("Name_" .. tostring(i))
			local trophyLabel = rowList:FindFirstChild("Trophies_" .. tostring(i))

			if entry then
				if rankLabel then
					rankLabel.Text = "#" .. tostring(entry.rank)
					rankLabel.TextColor3 = if entry.userId == localUserId then Color3.new(0.3, 1, 0.3) elseif entry.rank == 1 then Color3.new(1, 0.85, 0.1) elseif entry.rank <= 3 then Color3.new(0.8, 0.8, 0.8) else Color3.new(0.5, 0.5, 0.6)
				end
				if nameLabel then
					nameLabel.Text = entry.name
					nameLabel.TextColor3 = if entry.userId == localUserId then Color3.new(0.3, 1, 0.3) else Color3.new(0.85, 0.85, 1)
				end
				if avatarLabel then avatarLabel.Image = avatarUrl(entry.userId) end
				if trophyLabel then trophyLabel.Text = "🏆 " .. tostring(entry.trophies) end
			else
				if rankLabel then rankLabel.Text = "-" end
				if nameLabel then nameLabel.Text = "" end
				if avatarLabel then avatarLabel.Image = "" end
				if trophyLabel then trophyLabel.Text = "" end
			end
		end
	end,

	Refresh = function(self)
		self:_UpdateDisplay()
	end,

	KnitStart = function(self)
		self._gui = self:_FindGui()

		local svc = Knit.GetService("LeaderboardService")
		svc.OnLeaderboardUpdated:Connect(function()
			self:_UpdateDisplay()
		end)

		task.spawn(function()
			while true do
				task.wait(REFRESH_INTERVAL)
				self:_UpdateDisplay()
			end
		end)

		task.defer(function()
			self:_UpdateDisplay()
		end)

		print("LeaderboardController started")
	end,

	KnitInit = function(self)
		print("LeaderboardController initialized")
	end,
})

return LeaderboardController
