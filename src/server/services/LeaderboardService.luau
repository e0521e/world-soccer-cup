local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LEADERBOARD_SIZE = 100
local ORDERED_DS_NAME = "TrophiesRanking"

local LeaderboardService = Knit.CreateService({
	Name = "LeaderboardService",

	Client = {
		GetTopPlayers = function(self, player, count)
			return self.Server:GetTopPlayers(player, count)
		end,

		GetPlayerRank = function(self, player)
			return self.Server:GetPlayerRank(player)
		end,

		OnLeaderboardUpdated = Knit.CreateSignal(),
	},

	_orderedDs = nil,
	_cachedTop = {},
	_cacheTime = 0,

	UpdateRanking = function(self, player)
		if not self._orderedDs then return end
		local pds = Knit.GetService("PlayerDataService")
		local trophies = pds:GetTrophies(player)
		local ok = pcall(function()
			self._orderedDs:SetAsync(tostring(player.UserId), trophies)
		end)
		if ok then
			self._cacheTime = 0
			self.Client.OnLeaderboardUpdated:Fire(player)
		end
	end,

	GetTopPlayers = function(self, requestingPlayer, count)
		count = math.clamp(count or 10, 1, LEADERBOARD_SIZE)
		local now = tick()
		if now - self._cacheTime < 10 and #self._cachedTop > 0 then
			return self._cachedTop
		end

		if not self._orderedDs then return {} end
		local entries = {}
		local ok, pages = pcall(function()
			return self._orderedDs:GetSortedAsync(false, count)
		end)
		if not ok or not pages then return {} end

		local data = pages:GetCurrentPage()
		for _, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local playerObj = userId and Players:GetPlayerByUserId(userId)
			table.insert(entries, {
				userId = userId,
				name = playerObj and playerObj.DisplayName or "Offline",
				trophies = entry.value,
				rank = #entries + 1,
			})
		end

		self._cachedTop = entries
		self._cacheTime = now
		return entries
	end,

	GetPlayerRank = function(self, player)
		if not self._orderedDs then return nil end
		local ok, score = pcall(function()
			return self._orderedDs:GetAsync(tostring(player.UserId))
		end)
		if not ok then return nil end
		return {
			userId = player.UserId,
			name = player.DisplayName,
			trophies = score or 0,
		}
	end,

	RemovePlayer = function(self, player)
		if not self._orderedDs then return end
		pcall(function()
			self._orderedDs:RemoveAsync(tostring(player.UserId))
		end)
	end,

	KnitInit = function(self)
		local ok, ds = pcall(function()
			return DataStoreService:GetOrderedDataStore(ORDERED_DS_NAME)
		end)
		self._orderedDs = ok and ds or nil
		if not self._orderedDs then
			warn("LeaderboardService: OrderedDataStore unavailable")
		end
		print("LeaderboardService initialized")
	end,

	KnitStart = function(self)
		Players.PlayerAdded:Connect(function(player)
			task.wait(3)
			local pds = Knit.GetService("PlayerDataService")
			local trophies = pds:GetTrophies(player)
			if self._orderedDs then
				pcall(function()
					self._orderedDs:SetAsync(tostring(player.UserId), trophies)
				end)
			end
		end)

		Players.PlayerRemoving:Connect(function(player)
			self:UpdateRanking(player)
		end)

		print("LeaderboardService started")
	end,
})

return LeaderboardService
