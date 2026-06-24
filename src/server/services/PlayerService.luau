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

        GetUnlockedNPCs = function(self, player)
            return self.Server:GetUnlockedNPCs(player)
        end,

        GetNPCQuality = function(self, player, npcId)
            return self.Server:GetNPCQuality(player, npcId)
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
        local active = timerService._activeNPCs[player.Name]
        if not active or #active == 0 then return end

        local lowestEntry = nil
        local lowestQuality = Constants.MAX_NPC_QUALITY + 1
        local rewardService = Knit.GetService("RewardService")
        for _, entry in ipairs(active) do
            local quality = rewardService:GetNPCQuality(player, entry.npcId)
            if quality < lowestQuality then
                lowestQuality = quality
                lowestEntry = entry
            end
        end

        if lowestEntry and lowestQuality < Constants.MAX_NPC_QUALITY then
            rewardService:UpgradeNPCQuality(player, lowestEntry.npcId)
        end
    end,

    InitializePlayer = function(self, player)
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
                    local pds = Knit.GetService("PlayerDataService")
                    local unlocked = pds:GetUnlockedNPCs(player)
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

                    local trophyMain = trophyPart
                    local origCF = trophyMain and trophyMain:IsA("BasePart") and trophyMain.CFrame

                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if origCF and root then
                        local riseCF = CFrame.new(root.Position.X, root.Position.Y + 15, root.Position.Z)
                        local tweenService = game:GetService("TweenService")
                        local riseTween = tweenService:Create(trophyMain, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = riseCF })
                        riseTween:Play()
                        riseTween.Completed:Wait()
                    end

                    local delay = math.random(11, 20)
                    task.wait(delay)

                    if origCF then
                        local tweenService = game:GetService("TweenService")
                        local returnTween = tweenService:Create(trophyMain, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = origCF })
                        returnTween:Play()
                        returnTween.Completed:Wait()
                    end

					pds:AddTrophies(player, 1)
					pds:SavePlayerData(player)
					local leaderboard = Knit.GetService("LeaderboardService")
					leaderboard:UpdateRanking(player)

                    local npcProg = Knit.GetService("NPCProgressService")
                    local newOffset = #pds:GetUnlockedNPCs(player) + 1
                    npcProg:ResetProgress(player, newOffset)

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
