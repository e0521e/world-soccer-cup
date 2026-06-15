--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Products = require(game:GetService("ReplicatedStorage").Shared.datas.Products)
local GamePasses = require(game:GetService("ReplicatedStorage").Shared.datas.GamePasses)

local ShopService = Knit.CreateService({
	Name = "ShopService",

	Client = {
		PurchaseWithCoins = function(self, player, gamePassId)
			return self.Server:PurchaseWithCoins(player, gamePassId)
		end,

		GetOwnedGamePasses = function(self, player)
			return self.Server:GetOwnedGamePasses(player)
		end,

		GetProducts = function(self, _player)
			return Products
		end,

		GetGamePasses = function(self, _player)
			return GamePasses
		end,

		HasGamePass = function(self, player, gamePassId)
			return self.Server:HasGamePass(player, gamePassId)
		end,

		OnPurchaseComplete = Knit.CreateSignal(),
		OnPurchaseFailed = Knit.CreateSignal(),
	},

	_ownedGamePasses = {},
	_processedReceipts = {},

	GetOwnedGamePasses = function(self, player)
		return self._ownedGamePasses[player] or {}
	end,

	HasGamePass = function(self, player, gamePassId)
		local passes = self._ownedGamePasses[player]
		if not passes then return false end
		for _, id in ipairs(passes) do
			if id == gamePassId then return true end
		end
		return false
	end,

	PurchaseWithCoins = function(self, player, gamePassId)
		local gamePass = nil
		for _, gp in ipairs(GamePasses) do
			if gp.GamePassId == gamePassId then
				gamePass = gp
				break
			end
		end
		if not gamePass then
			self.Client.OnPurchaseFailed:Fire(player, "GamePass", gamePassId, "Item not found")
			return false
		end

		if self:HasGamePass(player, gamePassId) then
			self.Client.OnPurchaseFailed:Fire(player, "GamePass", gamePassId, "Already owned")
			return false
		end

		local cost = gamePass.PriceCoins
		if cost <= 0 then
			self.Client.OnPurchaseFailed:Fire(player, "GamePass", gamePassId, "Robux only item")
			return false
		end

		local rewardService = Knit.GetService("RewardService")
		local coins = rewardService:GetCoins(player)
		if coins < cost then
			self.Client.OnPurchaseFailed:Fire(player, "GamePass", gamePassId, "Insufficient coins")
			return false
		end

		local ok = rewardService:DeductCoins(player, cost)
		if not ok then
			self.Client.OnPurchaseFailed:Fire(player, "GamePass", gamePassId, "Transaction failed")
			return false
		end

		local passes = self._ownedGamePasses[player]
		if not passes then
			passes = {}
			self._ownedGamePasses[player] = passes
		end
		table.insert(passes, gamePassId)

		self.Client.OnPurchaseComplete:Fire(player, "GamePass", gamePassId, {
			name = gamePass.Name,
			icon = gamePass.Icon,
		})

		return true
	end,

	_GrantProduct = function(self, player, productId)
		for _, product in ipairs(Products) do
			if product.ProductId == productId then
				if product.Rewards and product.Rewards.Coins then
					local rewardService = Knit.GetService("RewardService")
					rewardService:AwardCoinsDirect(player, product.Rewards.Coins)
				end
				self.Client.OnPurchaseComplete:Fire(player, "Product", productId, {
					name = product.Name,
					icon = product.Icon,
				})
				return true
			end
		end
		return false
	end,

	_GrantGamePass = function(self, player, gamePassId)
		local passes = self._ownedGamePasses[player]
		if not passes then
			passes = {}
			self._ownedGamePasses[player] = passes
		end
		table.insert(passes, gamePassId)

		for _, gp in ipairs(GamePasses) do
			if gp.GamePassId == gamePassId then
				self.Client.OnPurchaseComplete:Fire(player, "GamePass", gamePassId, {
					name = gp.Name,
					icon = gp.Icon,
				})
				return true
			end
		end
		return false
	end,

	_CheckExistingGamePasses = function(self, player)
		local passes = {}
		for _, gp in ipairs(GamePasses) do
			local owned = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.GamePassId)
			end)
			if owned then
				table.insert(passes, gp.GamePassId)
			end
		end
		if #passes > 0 then
			self._ownedGamePasses[player] = passes
		end
	end,

	KnitInit = function(self)
		print("ShopService initialized")
	end,

	KnitStart = function(self)
		MarketplaceService.ProcessReceipt = function(receiptInfo)
			if self._processedReceipts[receiptInfo.PurchaseId] then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			if receiptInfo.PurchaseType == Enum.PurchaseType.Product then
				local ok = self:_GrantProduct(player, receiptInfo.ProductId)
				if not ok then
					return Enum.ProductPurchaseDecision.NotProcessedYet
				end
			elseif receiptInfo.PurchaseType == Enum.PurchaseType.GamePass then
				self:_GrantGamePass(player, receiptInfo.ProductId)
			end

			self._processedReceipts[receiptInfo.PurchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		Players.PlayerAdded:Connect(function(player)
			self:_CheckExistingGamePasses(player)
		end)

		Players.PlayerRemoving:Connect(function(player)
			self._ownedGamePasses[player] = nil
		end)

		for _, player in ipairs(Players:GetPlayers()) do
			self:_CheckExistingGamePasses(player)
		end

		print("ShopService started")
	end,
})

return ShopService
