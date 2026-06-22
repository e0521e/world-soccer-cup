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
	_playerLoops = {},

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

	ResetProgress = function(self, player, startIndex)
		if self._playerLoops[player] then
			self._playerLoops[player] = false
		end
		self._playerData[player] = nil
		self:_InitPlayer(player, startIndex or 1)
	end,

	_InitPlayer = function(self, player, startIndex)
		if self._playerLoops[player] then
			self._playerLoops[player] = false
			task.wait()
		end
		startIndex = startIndex or 1
		local pd = {
			totalSeconds = 0,
			minuteCount = 0,
			queue = {},
			teamComplete = false,
			startIndex = startIndex,
		}
		self._playerData[player] = pd
		self._playerLoops[player] = true
		local active = true

		local totalSecondsLimit = Constants.ONLINE_TOTAL_MINUTES * 60
		local unlockSlots = Constants.ACTIVE_NPC_COUNT
		local npcInterval = math.floor(totalSecondsLimit / unlockSlots)

		task.spawn(function()
			while active and self._playerLoops[player] do
				task.wait(1)
				pd.totalSeconds = pd.totalSeconds + 1

				local newMin = math.floor(pd.totalSeconds / npcInterval)
				if newMin > pd.minuteCount then
					for i = pd.minuteCount + 1, newMin do
						if i <= Constants.ACTIVE_NPC_COUNT then
							local npcIdx = pd.startIndex + i - 1
							local npcData = NPCData.NPCList[npcIdx]
							if npcData then
								table.insert(pd.queue, npcData.id)
								local pds = Knit.GetService("PlayerDataService")
								pds:AddUnlockedNPC(player, npcData.id)
								self.Client.OnMinuteReached:Fire(player, i, npcData.id, npcData.displayName)
							end
						end
					end
					pd.minuteCount = newMin
				end

				if pd.minuteCount >= Constants.ACTIVE_NPC_COUNT and not pd.teamComplete then
					pd.teamComplete = true
					self.Client.OnTeamComplete:Fire(player)
					break
				end
			end
		end)
	end,

	KnitInit = function(self)
		print("NPCProgressService initialized")
	end,

	KnitStart = function(self)
		game:GetService("Players").PlayerAdded:Connect(function(player)
			task.spawn(function()
				repeat task.wait(0.5) until player.Character
				task.wait(0.5)
				self:_InitPlayer(player)
			end)
		end)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			task.spawn(function()
				repeat task.wait(0.5) until player.Character
				task.wait(0.5)
				self:_InitPlayer(player)
			end)
		end
		print("NPCProgressService started")
	end,
})

return NPCProgressService
