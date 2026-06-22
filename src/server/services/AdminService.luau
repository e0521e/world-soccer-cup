local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local AdminData = require(game:GetService("ReplicatedStorage").Shared.configs.AdminData)
local Players = game:GetService("Players")

local AdminService = Knit.CreateService({
	Name = "AdminService",

	Client = {
		GetPlayerData = function(self, player, targetUserId)
			return self.Server:GetPlayerData(player, targetUserId)
		end,

		SetPlayerData = function(self, player, targetUserId, keyValues)
			return self.Server:SetPlayerData(player, targetUserId, keyValues)
		end,
	},

	_VerifyAdmin = function(self, player)
		if not player then return false end
		return AdminData.IsAdmin(player.UserId)
	end,

	GetPlayerData = function(self, player, targetUserId)
		if not self:_VerifyAdmin(player) then return nil end

		local pds = Knit.GetService("PlayerDataService")
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target then return nil end

		local data = {
			UserId = targetUserId,
			Name = target.Name,
			Coins = pds:GetCoins(target),
			Level = pds:GetLevel(target),
		}

		local raw = pds:GetData(target)

		return data, raw
	end,

	SetPlayerData = function(self, player, targetUserId, keyValues)
		if not self:_VerifyAdmin(player) then return false end

		local pds = Knit.GetService("PlayerDataService")
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target then return false end

		local data = pds:GetData(target)
		if not data then return false end

		local ok, err = pcall(function()
			for key, value in pairs(keyValues) do
				data[key] = value
			end
		end)
		if not ok then
			warn("AdminService: SetPlayerData failed:", err)
			return false
		end

		pds:SavePlayerData(target)
		return true
	end,

	KnitInit = function(self)
		print("AdminService initialized")
	end,

	KnitStart = function(self)
		print("AdminService started")
	end,
})

return AdminService
