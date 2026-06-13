--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)
local ServerStorage = game:GetService("ServerStorage")

local NPCTimerService = Knit.CreateService({
    Name = "NPCTimerService",

    Client = {
        GetActiveNPCs = function(self, player)
            return self.Server:GetActiveNPCs(player)
        end,

        GetTimerRemaining = function(self, player, slotId)
            return self.Server:GetTimerRemaining(player, slotId)
        end,

        OnTimerUpdated = Knit.CreateSignal(),
        OnNPCActivated = Knit.CreateSignal(),
        OnTimerExpired = Knit.CreateSignal(),
    },

    _playerSlots = {},
    _slotPositions = {},

    GetActiveNPCs = function(self, player)
        local slots = self._playerSlots[player]
        if not slots then return {} end
        local result = {}
        for _, data in pairs(slots) do
            table.insert(result, {
                slotId = data.slotId,
                npcId = data.npcId,
                quality = data.quality,
                qualityMultiplier = data.qualityMultiplier,
                timerRemaining = data.timerRemaining,
            })
        end
        return result
    end,

    GetTimerRemaining = function(self, player, slotId)
        local slots = self._playerSlots[player]
        if not slots or not slots[slotId] then return 0 end
        return slots[slotId].timerRemaining
    end,

    _getNPCNameById = function(self, npcId)
        for _, npc in ipairs(NPCData.NPCList) do
            if npc.id == npcId then
                return npc.displayName
            end
        end
        return nil
    end,

    ActivateNPCs = function(self, player)
        local positions = {}
        local fieldMgr = Knit.GetService("FieldManagerService")
        local field = fieldMgr:GetField(player)
        if field then
            local placeholderFolder = field:FindFirstChild("Player")
            if placeholderFolder then
                local children = placeholderFolder:GetChildren()
                for _, child in ipairs(children) do
                    if child:IsA("BasePart") or child:IsA("Model") then
                        local pos = if child:IsA("Model") then child:GetPivot().Position else child.Position
                        table.insert(positions, pos)
                    end
                end
                for _, child in ipairs(children) do
                    if child:IsA("BasePart") or child:IsA("Model") then
                        child:Destroy()
                    end
                end
            end
        end
        if #positions == 0 then
            positions = {
                Vector3.new(40, 2.5, -20),
                Vector3.new(40, 2.5, 0),
                Vector3.new(40, 2.5, 20),
            }
        end
        self._slotPositions[player] = positions

        local slots = {}
        self._playerSlots[player] = slots
        local playerService = Knit.GetService("PlayerService")

        -- Pre-assign 10 NPCs to 3 slots, round-robin
        local slotQueues = { {}, {}, {} }
        for i = 1, Constants.ACTIVE_NPC_COUNT do
            local slotIdx = ((i - 1) % 3) + 1
            table.insert(slotQueues[slotIdx], NPCData.NPCList[i].id)
        end

        for i = 1, 3 do
            local npcId = slotQueues[i][1]
            local quality = playerService:GetNPCQuality(player, npcId)
            local qualityData = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]

            local slotData = {
                slotId = i,
                npcId = npcId,
                npcQueue = slotQueues[i],
                npcIndex = 1,
                quality = quality,
                qualityMultiplier = qualityData.multiplier,
                timerRemaining = 0,
                isActive = false,
                npcModel = nil,
                claimPrompt = nil,
                claimed = false,
                firstClaimDone = false,
            }
            slots[i] = slotData
            self:_PlaceNPCOnField(player, slotData)
        end

        if slots[1] then
            self:_BeginTimer(player, slots[1], Constants.NPC_UNLOCK_COUNTDOWN)
        end
        if slots[2] then
            self:_BeginTimer(player, slots[2], Constants.NPC_UNLOCK_COUNTDOWN * 2)
        end
        if slots[3] then
            self:_BeginTimer(player, slots[3], Constants.NPC_UNLOCK_COUNTDOWN * 3)
        end
    end,

    _PlaceNPCOnField = function(self, player, slotData)
        local displayName = self:_getNPCNameById(slotData.npcId)
        if not displayName then return end

        local npcFolder = game:GetService("ServerStorage"):FindFirstChild("Player")
        local npcModel = nil
        if npcFolder then
            for _, child in ipairs(npcFolder:GetDescendants()) do
                if child:IsA("Model") and child.Name == displayName then
                    npcModel = child
                    break
                end
            end
        end
        if not npcModel then return end

        npcModel.Parent = workspace
        slotData.npcModel = npcModel
        local humanoid = npcModel:FindFirstChildWhichIsA("Humanoid")

        local positions = self._slotPositions[player] or {}
        local pos = positions[slotData.slotId]
        if not pos then return end
        local ox = (math.random() - 0.5) * 6
        local oz = (math.random() - 0.5) * 6
        local targetPos = Vector3.new(pos.X + ox, pos.Y + 2.5, pos.Z + oz)
        local dropHeight = 50
        local dropDuration = 1.5
        local targetRot = CFrame.Angles(0, math.rad(90), 0)
        local dropStart = targetPos + Vector3.new(0, dropHeight, 0)

        npcModel:PivotTo(CFrame.new(dropStart) * targetRot)

        task.spawn(function()
            local startTime = tick()
            while true do
                local elapsed = tick() - startTime
                local t = math.min(elapsed / dropDuration, 1)
                local eased = t * t
                local currentY = dropStart.Y + (targetPos.Y - dropStart.Y) * eased
                npcModel:PivotTo(CFrame.new(Vector3.new(targetPos.X, currentY, targetPos.Z)) * targetRot)
                if t >= 1 then
                    npcModel:PivotTo(CFrame.new(targetPos) * targetRot)
                    break
                end
                task.wait()
            end
            for _, part in ipairs(npcModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                end
            end
        end)
        if humanoid then
            humanoid.WalkSpeed = 0
        end
        
        local gui = Instance.new("BillboardGui")
        gui.Name = "TimerGui"
        gui.Size = UDim2.new(0, 100, 0, 40)
        gui.StudsOffset = Vector3.new(0, 8, 0)
        gui.AlwaysOnTop = true
		gui.Parent = npcModel:FindFirstChild("HumanoidRootPart") or npcModel

        local label = Instance.new("TextLabel")
        label.Name = "TimerLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0.5
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Text = "0"
        label.Parent = gui

        local qualityLabel = Instance.new("TextLabel")
        qualityLabel.Name = "QualityLabel"
        qualityLabel.Size = UDim2.new(1, 0, 0, 20)
        qualityLabel.Position = UDim2.new(0, 0, 1, 0)
        qualityLabel.BackgroundTransparency = 1
        qualityLabel.TextColor3 = Color3.new(1, 0.84, 0)
        qualityLabel.TextScaled = true
        qualityLabel.Font = Enum.Font.GothamBold
        local qData = NPCData.QualityTiers[slotData.quality] or NPCData.QualityTiers[1]
        qualityLabel.Text = qData.name .. " x" .. tostring(qData.multiplier)
        qualityLabel.Parent = gui

        self:_ApplyQualityVisual(npcModel, slotData.quality)
    end,

    _ApplyQualityVisual = function(self, npcModel, quality)
        local qualityData = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]
        if qualityData.visualEffect == "none" then
            return
        elseif qualityData.visualEffect == "jersey" then
            local shirt = npcModel:FindFirstChildOfClass("Shirt")
            if shirt then
                shirt.Color = Color3.new(1, 0.84, 0)
            end
        elseif qualityData.visualEffect == "gold" then
            local shirt = npcModel:FindFirstChildOfClass("Shirt")
            if shirt then
                shirt.Color = Color3.new(1, 0.84, 0)
            end
        elseif qualityData.visualEffect == "glow" then
            local shirt = npcModel:FindFirstChildOfClass("Shirt")
            if shirt then
                shirt.Color = Color3.new(1, 0.84, 0)
            end
            local primary = npcModel:FindFirstChild("HumanoidRootPart")
            if primary then
                local hl = Instance.new("Highlight")
                hl.Name = "QualityHighlight"
                hl.FillColor = Color3.new(1, 0.84, 0)
                hl.FillTransparency = 0.5
                hl.Parent = npcModel
            end
        elseif qualityData.visualEffect == "dynamic" then
            local shirt = npcModel:FindFirstChildOfClass("Shirt")
            if shirt then
                shirt.Color = Color3.new(1, 0, 0)
            end
            local primary = npcModel:FindFirstChild("HumanoidRootPart")
            if primary then
                local hl = Instance.new("Highlight")
                hl.Name = "QualityHighlight"
                hl.FillColor = Color3.new(1, 0, 0)
                hl.FillTransparency = 0.3
                hl.OutlineColor = Color3.new(1, 1, 0)
                hl.Parent = npcModel
            end
        end
    end,

    _StartNextTimer = function(self, player)
        local slots = self._playerSlots[player]
        if not slots then return end
        for _, slotData in pairs(slots) do
            if not slotData.isActive then
                self:_BeginTimer(player, slotData)
                break
            end
        end
    end,

    _BeginTimer = function(self, player, slotData, duration)
        duration = duration or math.random(Constants.COUNTDOWN_MIN, Constants.COUNTDOWN_MAX)
        slotData.timerRemaining = duration
        slotData.isActive = true

        self.Client.OnNPCActivated:Fire(player, slotData.slotId, slotData.npcId, duration)

        task.spawn(function()
            while slotData.timerRemaining > 0 and slotData.isActive do
                task.wait(1)
                if not slotData.isActive then break end
                slotData.timerRemaining -= 1
                self.Client.OnTimerUpdated:Fire(player, slotData.slotId, slotData.timerRemaining)

                local npcModel = slotData.npcModel
                if npcModel then
                    local primary = npcModel:FindFirstChild("HumanoidRootPart") or npcModel
                    local gui = primary:FindFirstChild("TimerGui")
                    if gui then
                        local label = gui:FindFirstChild("TimerLabel")
                        if label then
                            if slotData.timerRemaining <= 5 then
                                label.TextColor3 = Color3.new(1, 0, 0)
                            end
                            label.Text = tostring(slotData.timerRemaining)
                        end
                    end
                end
            end

            if slotData.isActive then
                slotData.isActive = false
                self.Client.OnTimerExpired:Fire(player, slotData.slotId, slotData.npcId)
                local playerService = Knit.GetService("PlayerService")
                if slotData.npcModel then
                    local primary = slotData.npcModel:FindFirstChild("HumanoidRootPart")
                    if primary then
                        local gui = primary:FindFirstChild("TimerGui")
                        if gui then gui:Destroy() end
                    end
                end
                playerService:TakeoverNPC(player, slotData)
                if not slotData.firstClaimDone then
                    slotData.firstClaimDone = true
                    self:_AdvanceSlotNPC(player, slotData)
                end
            end
        end)
    end,

    StopTimer = function(self, player, slotId)
        local slots = self._playerSlots[player]
        if slots and slots[slotId] then
            slots[slotId].isActive = false
        end
    end,

    ResetSlot = function(self, player, sd)
        sd.isActive = false
        self:_CleanupClaimPrompt(sd)
        sd.firstClaimDone = true
        local qData = NPCData.QualityTiers[sd.quality] or NPCData.QualityTiers[1]
        local cooldown = qData.cooldown or 10
        self:_BeginTimer(player, sd, cooldown)
    end,

    _MakeClaimable = function(self, player, slotData)
        local npcModel = slotData.npcModel
        if not npcModel then return end

        local primary = npcModel:FindFirstChild("HumanoidRootPart") or npcModel

        local gui = primary:FindFirstChild("TimerGui")
        if gui then
            local label = gui:FindFirstChild("TimerLabel")
            if label then
                label.Text = "PRESS E"
                label.TextColor3 = Color3.new(0, 1, 0)
            end
        end

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "ClaimPrompt"
        prompt.Parent = primary
        prompt.ActionText = "Claim " .. (slotData.npcId or "Player")
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 6
        prompt.RequiresLineOfSight = false
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
        prompt.Enabled = true
        slotData.claimPrompt = prompt

        local highlight = Instance.new("Highlight")
        highlight.Name = "ClaimHighlight"
        highlight.FillColor = Color3.new(0, 1, 0)
        highlight.FillTransparency = 0.6
        highlight.Parent = npcModel

        prompt.Triggered:Connect(function(claimingPlayer)
            if slotData.claimed then return end
            slotData.claimed = true
            prompt.Enabled = false
            if highlight then
                highlight:Destroy()
            end
            local playerService = Knit.GetService("PlayerService")
            playerService:TakeoverNPC(claimingPlayer, slotData)
            self:_RefillSlot(player, slotData)
        end)
    end,

    _CleanupClaimPrompt = function(self, slotData)
        if slotData.claimPrompt then
            slotData.claimPrompt:Destroy()
            slotData.claimPrompt = nil
        end
        slotData.claimed = false
        if slotData.npcModel then
            local hl = slotData.npcModel:FindFirstChild("ClaimHighlight")
            if hl then hl:Destroy() end
        end
    end,

    _RefillSlot = function(self, player, slotData)
        local progressService = Knit.GetService("NPCProgressService")
        local nextNpcId = progressService:DequeueNextNPC(player)
        if not nextNpcId then return end

        local playerService = Knit.GetService("PlayerService")
        local quality = playerService:GetNPCQuality(player, nextNpcId)
        local qualityData = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]

        local newSlot = {
            slotId = slotData.slotId,
            npcId = nextNpcId,
            quality = quality,
            qualityMultiplier = qualityData.multiplier,
            timerRemaining = 0,
            isActive = false,
            npcModel = nil,
            claimPrompt = nil,
            claimed = false,
            firstClaimDone = false,
        }
        local slots = self._playerSlots[player]
        slots[newSlot.slotId] = newSlot
        self:_PlaceNPCOnField(player, newSlot)
        self:_BeginTimer(player, newSlot, Constants.NPC_UNLOCK_COUNTDOWN)
    end,

    _StartNextNPC = function(self, player, fromSlotId)
        local slots = self._playerSlots[player]
        if not slots then return end
        local positions = self._slotPositions[player] or {}

        for i = 1, #positions do
            local slotData = slots[i]
            if not slotData or not slotData.isActive then
                self:_FillSlot(player, i)
                return
            end
        end
    end,

    _AdvanceSlotNPC = function(self, player, slotData)
        slotData.npcIndex += 1
        local queue = slotData.npcQueue
        if not queue or slotData.npcIndex > #queue then return end

        local npcId = queue[slotData.npcIndex]
        local playerService = Knit.GetService("PlayerService")
        local quality = playerService:GetNPCQuality(player, npcId)
        local qualityData = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]

        local newSlot = {
            slotId = slotData.slotId,
            npcId = npcId,
            npcQueue = slotData.npcQueue,
            npcIndex = slotData.npcIndex,
            quality = quality,
            qualityMultiplier = qualityData.multiplier,
            timerRemaining = 0,
            isActive = false,
            npcModel = nil,
            claimPrompt = nil,
            claimed = false,
            firstClaimDone = false,
        }
        local slots = self._playerSlots[player]
        slots[slotData.slotId] = newSlot
        self:_PlaceNPCOnField(player, newSlot)
        self:_BeginTimer(player, newSlot, Constants.NPC_UNLOCK_COUNTDOWN * 3)
    end,

    KnitInit = function(self)
        print("NPCTimerService initialized")
    end,

    KnitStart = function(self)
        print("NPCTimerService started")
    end,
})

return NPCTimerService
