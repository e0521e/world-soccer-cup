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
		OnTimeTick = Knit.CreateSignal(),
		OnTeamComplete = Knit.CreateSignal(),
	},

	_playerData = {},
	_playerLoops = {},

	GetElapsedTime = function(self, player)
		local pd = self._playerData[player]
		return pd and pd.totalSeconds or 0
	end,

	ResetProgress = function(self, player, offset)
		local timer = Knit.GetService("NPCTimerService")
		timer:SetCurrentOffset(player, offset)
		self:_InitPlayer(player, offset, true)
	end,

	_InitPlayer = function(self, player, offset, noRestore)
		offset = offset or 1

		if self._playerLoops[player] then
			self._playerLoops[player] = false
			task.wait()
		end

		local timer = Knit.GetService("NPCTimerService")
		if not noRestore then
			timer:RestoreFromActiveNPCS(player)
		end
		timer:InitCycle(player, offset)

		local pd = {
			totalSeconds = 0,
			lastTick = 0,
			lastUnlockCount = 0,
		}
		self._playerData[player] = pd
		self._playerLoops[player] = true

		task.spawn(function()
			while self._playerLoops[player] do
				task.wait(1)
				pd.totalSeconds += 1

				-- tick NPCTimerService to update countdowns + slot cycling
				timer:Tick(player)
				self.Client.OnTimeTick:Fire(player, pd.totalSeconds)

				local unlocked = timer:GetUnlockedInCycle(player)
				if unlocked > pd.lastUnlockCount then
					pd.lastUnlockCount = unlocked

					-- check team complete
					if unlocked >= Constants.ACTIVE_NPC_COUNT then
						self.Client.OnTeamComplete:Fire(player)
					end
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
