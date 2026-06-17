--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)

local PlayerService = Knit.CreateService({
    Name = "PlayerService",

    Client = {
        GetActiveSlot = function(self, player)
            return self.Server:GetActiveSlot(player)
        end,

        SelectNPC = function(self, player, npcId)
            return self.Server:SelectNPC(player, npcId)
        end,

        OnCharacterChanged = Knit.CreateSignal(),
        OnTakeover = Knit.CreateSignal(),
        OnRespawnQualityUp = Knit.CreateSignal(),
    },

    _playerSlots = {},
    _playerRespawnConnections = {},

    GetActiveSlot = function(self, player)
        local data = self._playerSlots[player]
        return data and data.slotId or nil
    end,

    SelectNPC = function(self, player, npcId)
        local rewardService = Knit.GetService("RewardService")
        local unlocked = rewardService:GetUnlockedNPCs(player)
        for _, id in ipairs(unlocked) do
            if id == npcId then
                self.Client.OnCharacterChanged:Fire(player, npcId)
                return true
            end
        end
        return false
    end,

    GetUnlockedNPCs = function(self, player)
        local rewardService = Knit.GetService("RewardService")
        return rewardService:GetUnlockedNPCs(player)
    end,

    GetNPCQuality = function(self, player, npcId)
        local rewardService = Knit.GetService("RewardService")
        return rewardService:GetNPCQuality(player, npcId)
    end,

    TakeoverNPC = function(self, player, slotData)
        local npcModel = slotData.npcModel
        if not npcModel then return end

        self._playerSlots[player] = slotData

        local autoKickService = Knit.GetService("AutoKickService")
        autoKickService:ExecuteKick(player, npcModel, slotData)
    end,

    OnPlayerRespawn = function(self, player)
        self.Client.OnRespawnQualityUp:Fire(player)

        local timerService = Knit.GetService("NPCTimerService")
        local slots = timerService._playerSlots[player]
        if not slots then return end

        local lowestSlot = nil
        local lowestQuality = Constants.MAX_NPC_QUALITY + 1
        for _, slotData in pairs(slots) do
            if slotData.quality < lowestQuality then
                lowestQuality = slotData.quality
                lowestSlot = slotData
            end
        end

        if lowestSlot and lowestQuality < Constants.MAX_NPC_QUALITY then
            local rewardService = Knit.GetService("RewardService")
            rewardService:UpgradeNPCQuality(player, lowestSlot.npcId)
            lowestSlot.quality = lowestQuality + 1

            local qualityData = NPCData.QualityTiers[lowestSlot.quality]
            lowestSlot.qualityMultiplier = qualityData.multiplier

            timerService:_ApplyQualityVisual(lowestSlot.npcModel, lowestSlot.quality)

            local npcModel = lowestSlot.npcModel
            if npcModel then
                local primary = npcModel:FindFirstChild("HumanoidRootPart") or npcModel
                local existing = primary:FindFirstChild("TimerGui")
                if not existing then
                    timerService:_PlaceNPCOnField(player, lowestSlot)
                end
            end
        end
    end,

    InitializePlayer = function(self, player)
        local timerService = Knit.GetService("NPCTimerService")
        timerService:ActivateNPCs(player)
    end,

    _setupRespawn = function(self, player)
        local conn
        conn = player.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            self:OnPlayerRespawn(player)
        end)
        self._playerRespawnConnections[player] = conn
    end,

    KnitInit = function(self)
        print("PlayerService initialized")
    end,

    KnitStart = function(self)
        task.spawn(function()
            local trophyModel = workspace:FindFirstChild("trophy")
            local trophyPart = trophyModel and trophyModel:FindFirstChild("Main")
            local prompt = trophyPart and trophyPart:FindFirstChild("WorldCupPrompt")
            if prompt and prompt:IsA("ProximityPrompt") then
                prompt.Triggered:Connect(function(player)
                    local rewardService = Knit.GetService("RewardService")
                    local unlocked = rewardService:GetUnlockedNPCs(player)
                    if #unlocked < Constants.WORLD_CUP_REQUIRED_NPCS then
                        local noticeEvent = game:GetService("ReplicatedStorage"):FindFirstChild("UpgradeNoticeEvent")
                        if noticeEvent then
                            noticeEvent:FireClient(player, "WorldCupNeedTeam")
                        end
                        return
                    end

                    local noticeEvent = game:GetService("ReplicatedStorage"):FindFirstChild("UpgradeNoticeEvent")
                    if noticeEvent then
                        noticeEvent:FireClient(player, "WorldCupStart")
                    end

                    local delay = math.random(11, 20)
                    task.wait(delay)

                    rewardService._playerData[player].Trophies += 1
                    rewardService:_SaveData(player, true)

                    if noticeEvent then
                        noticeEvent:FireClient(player, "WorldCupDone")
                    end
                end)
            end
        end)

        game:GetService("Players").PlayerAdded:Connect(function(player)
            self._playerSlots[player] = nil
            self:_setupRespawn(player)
            player.CharacterAdded:Connect(function()
                task.wait(1)
                self:InitializePlayer(player)
            end)
            if player.Character then
                task.wait(1)
                self:InitializePlayer(player)
            end
        end)

        game:GetService("Players").PlayerRemoving:Connect(function(player)
            if self._playerRespawnConnections[player] then
                self._playerRespawnConnections[player]:Disconnect()
                self._playerRespawnConnections[player] = nil
            end
            self._playerSlots[player] = nil
        end)

        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            self._playerSlots[player] = nil
            self:_setupRespawn(player)
            if player.Character then
                task.wait(1)
                self:InitializePlayer(player)
            end
        end

        print("PlayerService started")
    end,
})

return PlayerService
