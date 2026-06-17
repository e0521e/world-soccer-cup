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

        DeductCoins = function(self, player, amount)
            return self.Server:DeductCoins(player, amount)
        end,

        GetPower = function(self, player)
            return self.Server:GetPower(player)
        end,

        GetTrophies = function(self, player)
            return self.Server:GetTrophies(player)
        end,

        CompleteTutorial = function(self, player)
            return self.Server:CompleteTutorial(player)
        end,

        IsNewPlayer = function(self, player)
            return self.Server:IsNewPlayer(player)
        end,

        ResolveMatch = function(self, player, targetUserId)
            return self.Server:ResolveMatch(player, targetUserId)
        end,

        OnCoinsChanged = Knit.CreateSignal(),
        OnLevelUp = Knit.CreateSignal(),
        OnNPCQualityUp = Knit.CreateSignal(),
        OnNPCUnlocked = Knit.CreateSignal(),
    },

    _playerData = {},
    _dataStore = nil,
    _lastSave = {},

    GetCoins = function(self, player)
        local data = self._playerData[player]
        return data and data.Coins or 0
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

    DeductCoins = function(self, player, amount)
        local data = self._playerData[player]
        if not data or data.Coins < amount then return false end
        data.Coins -= amount
        self.Client.OnCoinsChanged:Fire(player, data.Coins, -amount)
        self:_SaveData(player)
        return true
    end,

    AwardCoinsDirect = function(self, player, amount)
        local data = self._playerData[player]
        if not data then return end
        data.Coins += amount
        self.Client.OnCoinsChanged:Fire(player, data.Coins, amount)
    end,

    AwardGoal = function(self, player, npcId)
        local data = self._playerData[player]
        if not data then return end

        local levelConfig = PlayerLevels[data.Level] or PlayerLevels[1]
        local quality = data.NPCTiers[npcId] or 1
        local qualityConfig = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]

        local coins = Constants.BASE_COINS * levelConfig.multiplier * qualityConfig.multiplier

        local ok, shopService = pcall(Knit.GetService, Knit, "ShopService")
        if ok and shopService and shopService:HasGamePass(player, 1696596147) then
            coins *= 2
        end

        coins = math.floor(coins)

        data.Coins += coins
        self.Client.OnCoinsChanged:Fire(player, data.Coins, coins)
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

    GetTrophies = function(self, player)
        local data = self._playerData[player]
        return data and data.Trophies or 0
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

    IsNewPlayer = function(self, player)
        local data = self._playerData[player]
        local result = data and data.New == true or false
        print("[IsNewPlayer]", player.Name, "data exists:", data ~= nil, "New value:", data and data.New, "result:", result)
        return result
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
            data.Coins += coins
            self.Client.OnCoinsChanged:Fire(player, data.Coins, coins)
        end

        return {
            win = win,
            myPower = myPower,
            targetPower = targetPower,
        }
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
                if data.Trophies == nil then data.Trophies = 0 end
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
                Trophies = 0,
                New = true,
            }
            print("[LoadPlayerData] new player", player.Name, "New set to true")
        else
            print("[LoadPlayerData] loaded from DataStore for", player.Name, "New:", self._playerData[player].New)
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
            warn("Failed to save data for", player.Name, err)
        end
    end,

    OnPlayerRemoving = function(self, player)
        self:_SaveData(player, true)
        self._playerData[player] = nil
        self._lastSave[player] = nil
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
