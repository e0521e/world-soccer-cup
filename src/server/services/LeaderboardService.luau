local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LEADERBOARD_SIZE = 100
local ORDERED_DS_NAME = "TrophiesRanking"
local PLAYER_NAMES_KEY = "PlayerDisplayNames"

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
	_nameDs = nil,
	_cachedTop = {},
	_cacheTime = 0,
	_broadcastCooldown = 0,
	_broadcastThread = nil,

	UpdateRanking = function(self, player)
		local pds = Knit.GetService("PlayerDataService")
		local trophies = pds:GetTrophies(player)
		print("[Leaderboard] UpdateRanking", player.Name, "trophies", trophies)
		if not self._orderedDs then
			warn("[Leaderboard] OrderedDataStore nil, cannot save")
			return
		end
		local ok, err = pcall(function()
			self._orderedDs:SetAsync(tostring(player.UserId), trophies)
		end)
		if ok then
			self._cacheTime = 0
			print("[Leaderboard] SetAsync OK for", player.Name, trophies)
		else
			warn("[Leaderboard] SetAsync failed:", err)
			return
		end

		local now = tick()
		if now - self._broadcastCooldown >= 2 then
			self._broadcastCooldown = now
			self.Client.OnLeaderboardUpdated:Fire(player)
		elseif not self._broadcastThread then
			self._broadcastThread = task.delay(2 - (now - self._broadcastCooldown), function()
				self._broadcastThread = nil
				self._broadcastCooldown = tick()
				self.Client.OnLeaderboardUpdated:Fire()
			end)
		end
	end,

	GetTopPlayers = function(self, requestingPlayer, count)
		count = math.clamp(count or 10, 1, LEADERBOARD_SIZE)
		local now = tick()
		if now - self._cacheTime < Constants.LEADERBOARD_CACHE_SECONDS and #self._cachedTop > 0 then
			return self._cachedTop
		end

		if not self._orderedDs then
			warn("[Leaderboard] GetTopPlayers: OrderedDataStore nil")
			return {}
		end

		local ok, pages = pcall(function()
			return self._orderedDs:GetSortedAsync(false, count)
		end)
		if not ok then
			warn("[Leaderboard] GetSortedAsync failed:", pages)
			return {}
		end
		if not pages then
			warn("[Leaderboard] GetSortedAsync returned nil pages")
			return {}
		end

		local data = pages:GetCurrentPage()
		print("[Leaderboard] GetCurrentPage entries:", #data)

		local nameMap = {}
		if self._nameDs then
			local ok2, names = pcall(function()
				return self._nameDs:GetAsync(PLAYER_NAMES_KEY)
			end)
			if ok2 and names then
				nameMap = names
			end
		end

		local entries = {}
		for _, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local playerObj = userId and Players:GetPlayerByUserId(userId)
			local name = playerObj and playerObj.DisplayName or nameMap[tostring(userId)] or "Offline"
			table.insert(entries, {
				userId = userId,
				name = name,
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

		local ok2, nds = pcall(function()
			return DataStoreService:GetDataStore("PlayerNames")
		end)
		self._nameDs = ok2 and nds or nil

		if self._orderedDs then
			print("[Leaderboard] OrderedDataStore ready")
		else
			warn("[Leaderboard] OrderedDataStore unavailable")
		end
		print("[Leaderboard] initialized")
	end,

	KnitStart = function(self)
		Players.PlayerAdded:Connect(function(player)
			task.wait(3)
			local pds = Knit.GetService("PlayerDataService")
			local trophies = pds:GetTrophies(player)
			print("[Leaderboard] PlayerAdded", player.Name, "trophies", trophies)
			self:UpdateRanking(player)
			if self._nameDs then
				pcall(function()
					self._nameDs:UpdateAsync(PLAYER_NAMES_KEY, function(old)
						old = old or {}
						old[tostring(player.UserId)] = player.DisplayName
						return old
					end)
				end)
			end
		end)

		Players.PlayerRemoving:Connect(function(player)
			local pds = Knit.GetService("PlayerDataService")
			local trophies = pds:GetTrophies(player)
			if trophies > 0 then
				self:UpdateRanking(player)
			end
			if self._nameDs then
				pcall(function()
					self._nameDs:UpdateAsync(PLAYER_NAMES_KEY, function(old)
						old = old or {}
						old[tostring(player.UserId)] = player.DisplayName
						return old
					end)
				end)
			end
		end)

		print("[Leaderboard] started")
	end,
})

return LeaderboardService
