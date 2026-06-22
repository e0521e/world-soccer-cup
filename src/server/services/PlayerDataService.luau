local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local PlayerLevels = require(game:GetService("ReplicatedStorage").Shared.configs.PlayerLevels)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataService = Knit.CreateService({
	Name = "PlayerDataService",

	Client = {
		GetCoins = function(self, player)
			return self.Server:GetCoins(player)
		end,

		GetLevel = function(self, player)
			return self.Server:GetLevel(player)
		end,

		GetPower = function(self, player)
			return self.Server:GetPower(player)
		end,

		GetTrophies = function(self, player)
			return self.Server:GetTrophies(player)
		end,

		GetUnlockedNPCs = function(self, player)
			return self.Server:GetUnlockedNPCs(player)
		end,

		GetBallIds = function(self, player)
			return self.Server:GetBallIds(player)
		end,

		IsNewPlayer = function(self, player)
			return self.Server:IsNewPlayer(player)
		end,

		CompleteTutorial = function(self, player)
			return self.Server:CompleteTutorial(player)
		end,

		UpgradeLevel = function(self, player)
			return self.Server:UpgradeLevel(player)
		end,

		OnCoinsChanged = Knit.CreateSignal(),
		OnLevelUp = Knit.CreateSignal(),
	},

	_playerData = {},
	_dataStore = nil,
	_lastSave = {},

	LoadPlayerData = function(self, player)
		local loaded = false
		if self._dataStore then
			local userId = player.UserId
			local key = Constants.DATASTORE_KEY .. tostring(userId)
			local success, data = pcall(function()
				return self._dataStore:GetAsync(key)
			end)
			if success and data then
				if data.Trophies == nil then data.Trophies = 0 end
				if data.BallIds == nil then data.BallIds = { "1" } end
				self._playerData[player] = data
				loaded = true
			end
		end

		if not loaded then
			self._playerData[player] = {
				Coins = 0,
				Level = 1,
				NPCTiers = {},
				UnlockedNPCs = {},
				BallIds = { "1" },
				Trophies = 0,
				New = true,
			}
			print("[PlayerDataService] new player", player.Name)
		else
			print("[PlayerDataService] loaded for", player.Name)
		end
	end,

	_SaveData = function(self, player, force)
		if not self._dataStore then return end
		local data = self._playerData[player]
		if not data then return end

		local now = tick()
		local last = self._lastSave[player] or 0
		if not force and (now - last) < 60 then return end
		self._lastSave[player] = now

		local userId = player.UserId
		local key = Constants.DATASTORE_KEY .. tostring(userId)

		local success, err = pcall(function()
			self._dataStore:SetAsync(key, data)
		end)
		if not success then
			warn("PlayerDataService: failed to save for", player.Name, err)
		end
	end,

	SavePlayerData = function(self, player)
		self:_SaveData(player, true)
	end,

	OnPlayerRemoving = function(self, player)
		self:_SaveData(player, true)
		self._playerData[player] = nil
		self._lastSave[player] = nil
	end,

	GetCoins = function(self, player)
		local data = self._playerData[player]
		return data and data.Coins or 0
	end,

	SetCoins = function(self, player, amount)
		local data = self._playerData[player]
		if not data then return end
		data.Coins = amount
	end,

	AddCoins = function(self, player, delta)
		local data = self._playerData[player]
		if not data then return end
		data.Coins += delta
		self.Client.OnCoinsChanged:Fire(player, data.Coins, delta)
	end,

	DeductCoins = function(self, player, amount)
		local data = self._playerData[player]
		if not data or data.Coins < amount then return false end
		data.Coins -= amount
		self.Client.OnCoinsChanged:Fire(player, data.Coins, -amount)
		return true
	end,

	GetLevel = function(self, player)
		local data = self._playerData[player]
		if not data then
			local defaultNext = PlayerLevels[2]
			return { level = 1, multiplier = 1.0, nextCost = defaultNext and defaultNext.cost or 0, loaded = false }
		end

		local level = data.Level
		local config = PlayerLevels[level] or PlayerLevels[1]
		local nextConfig = PlayerLevels[level + 1]
		return {
			level = level,
			multiplier = config.multiplier,
			nextCost = nextConfig and nextConfig.cost or 0,
			loaded = true,
		}
	end,

	UpgradeLevel = function(self, player)
		local data = self._playerData[player]
		if not data then return false end

		local currentLevel = data.Level
		local nextConfig = PlayerLevels[currentLevel + 1]
		if not nextConfig then return false end

		if data.Coins < nextConfig.cost then return false end

		data.Coins -= nextConfig.cost
		data.Level = currentLevel + 1

		local levelConfig = PlayerLevels[data.Level]
		self.Client.OnCoinsChanged:Fire(player, data.Coins, -nextConfig.cost)
		self.Client.OnLevelUp:Fire(player, data.Level, levelConfig.multiplier)
		self:_SaveData(player)

		return true
	end,

	GetNPCQuality = function(self, player, npcId)
		local data = self._playerData[player]
		if not data then return 1 end
		return data.NPCTiers[npcId] or 1
	end,

	SetNPCQuality = function(self, player, npcId, quality)
		local data = self._playerData[player]
		if not data then return end
		data.NPCTiers[npcId] = quality
	end,

	GetUnlockedNPCs = function(self, player)
		local data = self._playerData[player]
		return data and data.UnlockedNPCs or {}
	end,

	AddUnlockedNPC = function(self, player, npcId)
		local data = self._playerData[player]
		if not data then return end
		for _, id in ipairs(data.UnlockedNPCs) do
			if id == npcId then return end
		end
		table.insert(data.UnlockedNPCs, npcId)
	end,

	GetBallIds = function(self, player)
		local data = self._playerData[player]
		return data and data.BallIds or { "1" }
	end,

	AddBallId = function(self, player, ballId)
		local data = self._playerData[player]
		if not data then return end
		table.insert(data.BallIds, ballId)
		self:_SaveData(player)
	end,

	GetTrophies = function(self, player)
		local data = self._playerData[player]
		return data and data.Trophies or 0
	end,

	AddTrophies = function(self, player, delta)
		local data = self._playerData[player]
		if not data then return end
		data.Trophies += delta
	end,

	IsNewPlayer = function(self, player)
		local data = self._playerData[player]
		local result = data and data.New == true or false
		return result
	end,

	SetNewPlayer = function(self, player, newValue)
		local data = self._playerData[player]
		if data then
			data.New = newValue
		end
	end,

	CompleteTutorial = function(self, player)
		local data = self._playerData[player]
		if data then
			data.New = false
			self:_SaveData(player, true)
			return true
		end
		return false
	end,

	GetPower = function(self, player)
		local data = self._playerData[player]
		if not data then return 0 end

		local config = PlayerLevels[data.Level] or PlayerLevels[1]
		local power = config.power

		local totalQualityMultiplier = 0
		for _, quality in pairs(data.NPCTiers) do
			local qConfig = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]
			totalQualityMultiplier += qConfig.multiplier
		end
		power += math.floor(totalQualityMultiplier * 10)

		return power
	end,

	GetData = function(self, player)
		return self._playerData[player]
	end,

	ResolveMatch = function(self, player, targetUserId)
		local data = self._playerData[player]
		if not data then return { win = false, reason = "No data" } end

		local targetPlayer = nil
		for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
			if p.UserId == targetUserId then
				targetPlayer = p
				break
			end
		end
		if not targetPlayer then return { win = false, reason = "Target offline" } end

		local targetData = self._playerData[targetPlayer]
		if not targetData then return { win = false, reason = "Target no data" } end

		local myPower = self:GetPower(player)
		local targetPower = self:GetPower(targetPlayer)

		local total = myPower + targetPower
		local roll = math.random(1, total)
		local win = roll <= myPower

		if win then
			local coins = math.max(10, math.floor(targetPower * 0.1))
			self:AddCoins(player, coins)
		end

		return {
			win = win,
			myPower = myPower,
			targetPower = targetPower,
		}
	end,

	KnitInit = function(self)
		local ok, ds = pcall(function()
			return DataStoreService:GetDataStore("FreeKickData")
		end)
		self._dataStore = ok and ds or nil
		if not self._dataStore then
			warn("PlayerDataService: DataStore unavailable, using in-memory storage")
		end
		print("PlayerDataService initialized")
	end,

	KnitStart = function(self)
		game:GetService("Players").PlayerAdded:Connect(function(player)
			self:LoadPlayerData(player)
		end)
		game:GetService("Players").PlayerRemoving:Connect(function(player)
			self:OnPlayerRemoving(player)
		end)

		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			self:LoadPlayerData(player)
		end

		print("PlayerDataService started")
	end,
})

return PlayerDataService
