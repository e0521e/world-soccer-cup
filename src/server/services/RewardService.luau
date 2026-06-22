local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local PlayerLevels = require(game:GetService("ReplicatedStorage").Shared.configs.PlayerLevels)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)

local RewardService = Knit.CreateService({
	Name = "RewardService",

	Client = {
		GetNPCQuality = function(self, player, npcId)
			return self.Server:GetNPCQuality(player, npcId)
		end,

		GetUnlockedNPCs = function(self, player)
			return self.Server:GetUnlockedNPCs(player)
		end,

		UnlockNPC = function(self, player, npcId)
			return self.Server:UnlockNPC(player, npcId)
		end,

		OnNPCQualityUp = Knit.CreateSignal(),
		OnNPCUnlocked = Knit.CreateSignal(),
	},

	GetNPCQuality = function(self, player, npcId)
		local pds = Knit.GetService("PlayerDataService")
		return pds:GetNPCQuality(player, npcId)
	end,

	GetUnlockedNPCs = function(self, player)
		local pds = Knit.GetService("PlayerDataService")
		return pds:GetUnlockedNPCs(player)
	end,

	AwardGoal = function(self, player, npcId)
		local pds = Knit.GetService("PlayerDataService")
		local levelInfo = pds:GetLevel(player)
		local quality = pds:GetNPCQuality(player, npcId)
		local qualityConfig = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]

		local coins = Constants.BASE_COINS * levelInfo.multiplier * qualityConfig.multiplier

		local ok, shopService = pcall(Knit.GetService, Knit, "ShopService")
		if ok and shopService and shopService:HasGamePass(player, 1696596147) then
			coins *= 2
		end

		coins = math.floor(coins)
		pds:AddCoins(player, coins)
	end,

	UnlockNPC = function(self, player, npcId)
		local pds = Knit.GetService("PlayerDataService")
		local unlocked = pds:GetUnlockedNPCs(player)

		for _, id in ipairs(unlocked) do
			if id == npcId then return false end
		end

		local cost = 500
		for i, npc in ipairs(NPCData.NPCList) do
			if npc.id == npcId then
				cost = if i <= 12 then 500 else 1000
				break
			end
		end

		if not pds:DeductCoins(player, cost) then return false end

		pds:AddUnlockedNPC(player, npcId)
		pds:SetNPCQuality(player, npcId, 1)

		self.Client.OnNPCUnlocked:Fire(player, npcId, cost)
		return true
	end,

	UpgradeNPCQuality = function(self, player, npcId)
		local pds = Knit.GetService("PlayerDataService")
		local currentQuality = pds:GetNPCQuality(player, npcId)
		if currentQuality >= Constants.MAX_NPC_QUALITY then return end

		local newQuality = currentQuality + 1
		pds:SetNPCQuality(player, npcId, newQuality)

		local qualityConfig = NPCData.QualityTiers[newQuality]
		self.Client.OnNPCQualityUp:Fire(player, npcId, newQuality, qualityConfig.multiplier)
	end,

	KnitInit = function(self)
		print("RewardService initialized")
	end,

	KnitStart = function(self)
		print("RewardService started")
	end,
})

return RewardService
