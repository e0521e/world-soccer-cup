--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local PlayerLevels = require(game:GetService("ReplicatedStorage").Shared.configs.PlayerLevels)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)
local DataStoreService = game:GetService("DataStoreService")

local RewardService = Knit.CreateService({
    Name = "RewardService",

    Client = {
        GetCoins = function(self, player)
            return self.Server:GetCoins(player)
        end,

        GetLevel = function(self, player)
            return self.Server:GetLevel(player)
        end,

        UpgradeLevel = function(self, player)
            return self.Server:UpgradeLevel(player)
        end,

        GetNPCQuality = function(self, player, npcId)
            return self.Server:GetNPCQuality(player, npcId)
        end,

        GetUnlockedNPCs = function(self, player)
            return self.Server:GetUnlockedNPCs(player)
        end,

        UnlockNPC = function(self, player, npcId)
            return self.Server:UnlockNPC(player, npcId)
        end,

        OnCoinsChanged = Knit.CreateSignal(),
        OnLevelUp = Knit.CreateSignal(),
        OnNPCQualityUp = Knit.CreateSignal(),
        OnNPCUnlocked = Knit.CreateSignal(),
    },

    _playerData = {},
    _dataStore = nil,

    GetCoins = function(self, player)
        local data = self._playerData[player]
        return data and data.Coins or 0
    end,

    GetLevel = function(self, player)
        local data = self._playerData[player]
        if not data then return { level = 1, multiplier = 1.0, nextCost = 0 } end

        local level = data.Level
        local levelConfig = PlayerLevels[level] or PlayerLevels[#PlayerLevels]
        local nextConfig = PlayerLevels[level + 1]

        return {
            level = level,
            multiplier = levelConfig.multiplier,
            nextCost = nextConfig and nextConfig.cost or 0,
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

    GetUnlockedNPCs = function(self, player)
        local data = self._playerData[player]
        return data and data.UnlockedNPCs or {}
    end,

    UnlockNPC = function(self, player, npcId)
        local data = self._playerData[player]
        if not data then return false end

        for _, id in ipairs(data.UnlockedNPCs) do
            if id == npcId then return false end
        end

        local cost = 500
        for i, npc in ipairs(NPCData.NPCList) do
            if npc.id == npcId then
                if i <= 12 then
                    cost = 500
                else
                    cost = 1000
                end
                break
            end
        end

        if data.Coins < cost then return false end

        data.Coins -= cost
        table.insert(data.UnlockedNPCs, npcId)
        data.NPCTiers[npcId] = 1

        self.Client.OnCoinsChanged:Fire(player, data.Coins, -cost)
        self.Client.OnNPCUnlocked:Fire(player, npcId, cost)
        self:_SaveData(player)

        return true
    end,

    AwardGoal = function(self, player, npcId)
        local data = self._playerData[player]
        if not data then return end

        local levelConfig = PlayerLevels[data.Level] or PlayerLevels[1]
        local quality = data.NPCTiers[npcId] or 1
        local qualityConfig = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]

        local coins = Constants.BASE_COINS * levelConfig.multiplier * qualityConfig.multiplier
        coins = math.floor(coins)

        data.Coins += coins
        self.Client.OnCoinsChanged:Fire(player, data.Coins, coins)
        self:_SaveData(player)
    end,

    UpgradeNPCQuality = function(self, player, npcId)
        local data = self._playerData[player]
        if not data then return end

        local currentQuality = data.NPCTiers[npcId] or 1
        if currentQuality >= Constants.MAX_NPC_QUALITY then return end

        local newQuality = currentQuality + 1
        data.NPCTiers[npcId] = newQuality

        local qualityConfig = NPCData.QualityTiers[newQuality]
        self.Client.OnNPCQualityUp:Fire(player, npcId, newQuality, qualityConfig.multiplier)
        self:_SaveData(player)
    end,

    LoadPlayerData = function(self, player)
        local loaded = false
        if self._dataStore then
            local userId = player.UserId
            local key = Constants.DATASTORE_KEY .. tostring(userId)
            local success, data = pcall(function()
                return self._dataStore:GetAsync(key)
            end)
            if success and data then
                self._playerData[player] = data
                loaded = true
            end
        end

        if not loaded then
            local defaultNPCs = {}
            for i = 1, math.min(3, #NPCData.NPCList) do
                table.insert(defaultNPCs, NPCData.NPCList[i].id)
            end
            local tiers = {}
            for _, id in ipairs(defaultNPCs) do
                tiers[id] = 1
            end

            self._playerData[player] = {
                Coins = 0,
                Level = 1,
                NPCTiers = tiers,
                UnlockedNPCs = defaultNPCs,
            }
        end
    end,

    _SaveData = function(self, player)
        if not self._dataStore then return end
        local data = self._playerData[player]
        if not data then return end

        local userId = player.UserId
        local key = Constants.DATASTORE_KEY .. tostring(userId)

        local success, err = pcall(function()
            self._dataStore:SetAsync(key, data)
        end)
        if not success then
            warn("Failed to save data for", player.Name, err)
        end
    end,

    OnPlayerRemoving = function(self, player)
        self:_SaveData(player)
        self._playerData[player] = nil
    end,

    KnitInit = function(self)
        local ok, ds = pcall(function()
            return DataStoreService:GetDataStore("FreeKickData")
        end)
        self._dataStore = ok and ds or nil
        if not self._dataStore then
            warn("RewardService: DataStore unavailable, using in-memory storage")
        end
        print("RewardService initialized")
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

        print("RewardService started")
    end,
})

return RewardService
