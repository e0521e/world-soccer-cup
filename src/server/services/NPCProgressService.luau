--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)

local NPCProgressService = Knit.CreateService({
	Name = "NPCProgressService",

	Client = {
		GetElapsedTime = function(self, player)
			return self.Server:GetElapsedTime(player)
		end,
		GetQueueSize = function(self, player)
			return self.Server:GetQueueSize(player)
		end,
		OnTimeTick = Knit.CreateSignal(),
		OnMinuteReached = Knit.CreateSignal(),
		OnTeamComplete = Knit.CreateSignal(),
	},

	_playerData = {},

	GetElapsedTime = function(self, player)
		local pd = self._playerData[player]
		return pd and pd.totalSeconds or 0
	end,

	GetQueueSize = function(self, player)
		local pd = self._playerData[player]
		return pd and #pd.queue or 0
	end,

	DequeueNextNPC = function(self, player)
		local pd = self._playerData[player]
		if not pd or #pd.queue == 0 then return nil end
		return table.remove(pd.queue, 1)
	end,

	_InitPlayer = function(self, player)
		local pd = {
			totalSeconds = 0,
			minuteCount = 0,
			queue = {},
			teamComplete = false,
		}
		self._playerData[player] = pd

		for i = 1, Constants.FIELD_NPC_SLOTS do
			if i <= #NPCData.NPCList then
				table.insert(pd.queue, NPCData.NPCList[i].id)
			end
		end

		task.spawn(function()
			while pd.minuteCount < Constants.ONLINE_TOTAL_MINUTES do
				task.wait(1)
				pd.totalSeconds = pd.totalSeconds + 1

				local newMin = math.floor(pd.totalSeconds / 60)
				if newMin > pd.minuteCount then
					for i = pd.minuteCount + 1, newMin do
						local npcIdx = i + Constants.FIELD_NPC_SLOTS
						if npcIdx <= #NPCData.NPCList then
							table.insert(pd.queue, NPCData.NPCList[npcIdx].id)
							self.Client.OnMinuteReached:Fire(player, i, NPCData.NPCList[npcIdx].displayName)
						end
					end
					pd.minuteCount = newMin
				end

				if pd.minuteCount >= Constants.ONLINE_TOTAL_MINUTES and not pd.teamComplete then
					pd.teamComplete = true
					self.Client.OnTeamComplete:Fire(player)
				end
			end
		end)
	end,

	KnitInit = function(self)
		print("NPCProgressService initialized")
	end,

	KnitStart = function(self)
		game:GetService("Players").PlayerAdded:Connect(function(player)
			self:_InitPlayer(player)
		end)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			self:_InitPlayer(player)
		end
		print("NPCProgressService started")
	end,
})

return NPCProgressService
