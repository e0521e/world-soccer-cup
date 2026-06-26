--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)
local ServerStorage = game:GetService("ServerStorage")

local MAX_ACTIVE_NPCS = Constants.MAX_ACTIVE_NPCS

local NPCTimerService = Knit.CreateService({
	Name = "NPCTimerService",

	Client = {
		GetSlotPosition = function(self, player, slotId)
			return self.Server:GetSlotPosition(player, slotId)
		end,

		OnNPCActivated = Knit.CreateSignal(),
		OnTimerUpdated = Knit.CreateSignal(),
		OnTimerExpired = Knit.CreateSignal(),
	},

	_slotPositions = {},   -- [playerName] = { Vector3, Vector3, Vector3 }
	_slotNPCs = {},         -- [playerName][slotIdx] = { model, planEntry, npcId }
	_plan = {},              -- [playerName] = { {npcData, slotIdx, countdownEnd, index}, ... }
	_cycleStartTime = {},    -- [playerName] = tick()
	_nextPlanIdx = {},       -- [playerName] = 4 (next plan entry to spawn after first 3)
	_activeNPCs = {},        -- [playerName] = { entry, ... }
	_unlockedInCycle = {},
	_currentOffset = {},

	-- ===== Slot Position Methods =====

	GetSlotPosition = function(self, player, slotId)
		local positions = self._slotPositions[player.Name]
		if not positions then return nil end
		return positions[slotId]
	end,

	_readAndSaveSlots = function(self, player)
		local fieldMgr = Knit.GetService("FieldManagerService")
		local field = fieldMgr:GetField(player)
		local positions = {}
		if field then
			local playerFolder = field:FindFirstChild("Player")
			if playerFolder then
				for _, child in ipairs(playerFolder:GetChildren()) do
					if child:IsA("BasePart") or child:IsA("Model") then
						local pos = if child:IsA("Model") then child:GetPivot().Position else child.Position
						table.insert(positions, pos)
					end
				end
			end
		end
		while #positions < 3 do
			table.insert(positions, Vector3.new(40, 2.5, (#positions - 1) * 20 - 20))
		end
		self._slotPositions[player.Name] = positions
		return positions
	end,

	-- ===== Cycle Init =====

	InitCycle = function(self, player, offset)
		local name = player.Name
		self._currentOffset[name] = offset or 1
		self._unlockedInCycle[name] = 0
		self._cycleStartTime[name] = tick()
		self._nextPlanIdx[name] = 4

		-- clean up any leftover slot NPCs
		self:_cleanAllSlots(player)

		-- read slot positions
		if not self._slotPositions[name] then
			self:_readAndSaveSlots(player)
		end

		-- pre-compute plan, skipping NPCs already on field or unlocked
		local pds = Knit.GetService("PlayerDataService")
		local activeNPCs = pds:GetActiveNPCS(player)
		local unlockedNPCs = pds:GetUnlockedNPCs(player)
		local plan = {}
		local searched = 0
		local planIdx = 0
		local npcIdx = offset
		while planIdx < Constants.ACTIVE_NPC_COUNT and npcIdx <= #NPCData.NPCList do
			local npcData = NPCData.NPCList[npcIdx]
			if npcData then
				local skip = false
				for _, id in ipairs(activeNPCs) do
					if id == npcData.id then skip = true; break end
				end
				if not skip then
					for _, id in ipairs(unlockedNPCs) do
						if id == npcData.id then skip = true; break end
					end
				end
				if not skip then
					planIdx += 1
					local slotIdx = ((planIdx - 1) % 3) + 1
					table.insert(plan, {
						npcData = npcData,
						slotIdx = slotIdx,
						countdown = planIdx * Constants.NPC_UNLOCK_COUNTDOWN,
						index = planIdx,
					})
				end
			end
			npcIdx += 1
			searched += 1
			if searched > 200 then break end
		end
		self._plan[name] = plan
		self._slotNPCs[name] = {}

		-- spawn first 3 immediately
		for i = 1, math.min(3, #plan) do
			local entry = plan[i]
			self:_spawnSlotNPC(player, entry)
		end
	end,

	-- ===== Slot NPC Management =====

	_spawnSlotNPC = function(self, player, planEntry)
		local name = player.Name
		local npcData = planEntry.npcData
		local slotIdx = planEntry.slotIdx
		local pos = self._slotPositions[name][slotIdx]

		-- find model in ServerStorage
		local npcFolder = ServerStorage:FindFirstChild("Player")
		if not npcFolder then return end

		local template
		for _, child in ipairs(npcFolder:GetDescendants()) do
			if child:IsA("Model") and child.Name == npcData.displayName then
				template = child
				break
			end
		end
		if not template then return end

		local model = template:Clone()
		model.Parent = workspace:FindFirstChild("FieldNPCs") or workspace

		-- template parts may carry Anchored; unanchor all so PivotTo moves the whole rig
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end

		model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0))
		local humanoid = model:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
		end

		-- tag the NPC model so client can find it
		model:SetAttribute("SlotId", slotIdx)
		model:SetAttribute("OwnerPlayer", player.Name)

		self._slotNPCs[name][slotIdx] = {
			model = model,
			planEntry = planEntry,
			npcId = npcData.id,
		}

		self.Client.OnNPCActivated:Fire(player, slotIdx, npcData.id, planEntry.countdown)
	end,

	_removeSlotNPC = function(self, player, slotIdx)
		local name = player.Name
		local slotData = self._slotNPCs[name] and self._slotNPCs[name][slotIdx]
		if not slotData then return end

		local humanoid = slotData.model:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Constants.NPC_WALK_SPEED
			humanoid.AutoRotate = true
		end

		local ballSpawn = Knit.GetService("BallSpawnService")
		local balls = ballSpawn:GetActiveBallPositions()
		local rootPart = slotData.model:FindFirstChild("HumanoidRootPart")
		local targetPos

		if #balls > 0 and rootPart then
			local nearest = balls[1]
			local nearestDist = (rootPart.Position - balls[1].position).Magnitude
			for _, b in ipairs(balls) do
				local d = (rootPart.Position - b.position).Magnitude
				if d < nearestDist then
					nearestDist = d
					nearest = b
				end
			end
			targetPos = nearest.position
		elseif rootPart then
			local pos = self._slotPositions[name][slotIdx] or rootPart.Position
			targetPos = pos + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
		end

		if humanoid and targetPos then
			humanoid:MoveTo(targetPos)
		end

		local entry = {
			player = player,
			npcId = slotData.npcId,
			npcModel = slotData.model,
			slotIdx = slotIdx,
			isActive = true,
			kickCD = 3,
		}
		self:_startKickLoop(player, entry)
		self:_addToActive(player, entry)

		local pds = Knit.GetService("PlayerDataService")
		pds:AddUnlockedNPC(player, slotData.npcId)

		slotData.model:SetAttribute("SlotId", nil)
		slotData.model:SetAttribute("OwnerPlayer", nil)

		self._slotNPCs[name][slotIdx] = nil
		self.Client.OnTimerExpired:Fire(player, slotIdx, slotData.npcId)
	end,

	-- ===== Tick (called every second from NPCProgressService) =====

	Tick = function(self, player)
		local name = player.Name
		local startTime = self._cycleStartTime[name]
		if not startTime then return end

		local elapsed = math.floor(tick() - startTime)
		local plan = self._plan[name] or {}
		local slotNPCs = self._slotNPCs[name]

		-- update countdown displays for slot NPCs
		for slotIdx = 1, 3 do
			local sd = slotNPCs and slotNPCs[slotIdx]
			if sd then
				local remaining = math.max(0, sd.planEntry.countdown - elapsed)
				self.Client.OnTimerUpdated:Fire(player, slotIdx, remaining)

				-- countdown expired
				if remaining <= 0 then
					self:_removeSlotNPC(player, slotIdx)
				end
			end
		end

		-- spawn next NPC in freed slot
		local nextIdx = self._nextPlanIdx[name] or 4
		if nextIdx <= #plan then
			for slotIdx = 1, 3 do
				if not (slotNPCs and slotNPCs[slotIdx]) then
					-- find the next plan entry for this slot
					for pi = nextIdx, #plan do
						if plan[pi].slotIdx == slotIdx then
							local entry = plan[pi]
							self:_spawnSlotNPC(player, entry)
							-- advance nextIdx past this and any skipped entries
							self._nextPlanIdx[name] = pi + 1
							self._unlockedInCycle[name] = (self._unlockedInCycle[name] or 0) + 1
							break
						end
					end
				end
			end
		end
	end,

	GetUnlockedInCycle = function(self, player)
		return self._unlockedInCycle[player.Name] or 0
	end,

	SetCurrentOffset = function(self, player, offset)
		self._currentOffset[player.Name] = offset
		self._unlockedInCycle[player.Name] = 0
	end,

	-- ===== Active NPC Management =====

	_addToActive = function(self, player, entry)
		local name = player.Name
		local active = self._activeNPCs[name]
		if not active then
			active = {}
			self._activeNPCs[name] = active
		end

		if #active >= MAX_ACTIVE_NPCS then
			entry.isActive = false
			if entry.npcModel then
				entry.npcModel:Destroy()
			end
			return
		end

		table.insert(active, entry)

		self:_saveActiveNPCS(player)
	end,

	_saveActiveNPCS = function(self, player)
		local active = self._activeNPCs[player.Name] or {}
		local ids = {}
		for _, e in ipairs(active) do
			table.insert(ids, e.npcId)
		end
		local pds = Knit.GetService("PlayerDataService")
		pds:SetActiveNPCS(player, ids)
		pds:SavePlayerData(player)
	end,

	-- ===== Kick Loop (after slot countdown expires) =====

	_startKickLoop = function(self, player, entry)
		task.spawn(function()
			while entry.isActive and entry.npcModel and entry.npcModel.Parent do
				if entry.kickCD > 0 then
					task.wait(entry.kickCD)
					entry.kickCD = 0
				end
				if not entry.isActive then break end

				local ballSpawn = Knit.GetService("BallSpawnService")
				local balls = ballSpawn:GetActiveBallPositions()

				local primary = entry.npcModel:FindFirstChild("HumanoidRootPart")
				if not primary then break end

				local nearest
				local nearestDist = math.huge
				for _, info in ipairs(balls) do
					local dist = (primary.Position - info.position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = info
					end
				end

				if nearest then
					local autoKick = Knit.GetService("AutoKickService")
					pcall(function()
						autoKick:ExecuteKick(player, entry.npcModel, {
							npcId = entry.npcId,
							slotId = entry.slotIdx,
							npcModel = entry.npcModel,
							quality = 1,
							qualityMultiplier = 1.0,
							claimed = false,
							firstClaimDone = false,
						})
					end)
				end

				local playerService = Knit.GetService("PlayerService")
				local quality = playerService:GetNPCQuality(player, entry.npcId)
				local qualityData = NPCData.QualityTiers[quality] or NPCData.QualityTiers[1]
				entry.kickCD = qualityData.cooldown
			end
		end)
	end,

	-- ===== Rejoin Restore =====

	RestoreFromActiveNPCS = function(self, player)
		if self._restored and self._restored[player.Name] then return end
		if not self._restored then self._restored = {} end
		self._restored[player.Name] = true

		local pds = Knit.GetService("PlayerDataService")
		local savedIds = pds:GetActiveNPCS(player)
		if #savedIds == 0 then return end

		if not self._slotPositions[player.Name] then
			self:_readAndSaveSlots(player)
		end

		for _, npcId in ipairs(savedIds) do
			local npcData
			for _, npc in ipairs(NPCData.NPCList) do
				if npc.id == npcId then
					npcData = npc
					break
				end
			end
			if npcData then
				self:spawnAtRandom(player, npcData)
				task.wait(0.3)
			end
		end
	end,

	spawnAtRandom = function(self, player, npcData)
		local fieldMgr = Knit.GetService("FieldManagerService")
		local field = fieldMgr:GetField(player)
		local ground = field and field:FindFirstChild("Ground")
		local randomPos
		if ground and ground:IsA("BasePart") then
			local cf = ground.CFrame
			local sz = ground.Size
			randomPos = Vector3.new(
				cf.X + (math.random() - 0.5) * sz.X * 0.8,
				cf.Y + 3,
				cf.Z + (math.random() - 0.5) * sz.Z * 0.8
			)
		else
			randomPos = Vector3.new(30 + math.random() * 20, 3, -30 + math.random() * 60)
		end

		local npcFolder = ServerStorage:FindFirstChild("Player")
		if not npcFolder then return end
		local template
		for _, child in ipairs(npcFolder:GetDescendants()) do
			if child:IsA("Model") and child.Name == npcData.displayName then
				template = child
				break
			end
		end
		if not template then return end

		local model = template:Clone()
		model.Parent = workspace:FindFirstChild("FieldNPCs") or workspace

		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end

		model:PivotTo(CFrame.new(randomPos))

		local entry = {
			player = player,
			npcId = npcData.id,
			npcModel = model,
			slotIdx = 0,
			isActive = true,
			kickCD = 1,
		}
		self:_startKickLoop(player, entry)
		self:_addToActive(player, entry)
	end,

	_cleanAllSlots = function(self, player)
		local name = player.Name
		for slotIdx = 1, 3 do
			local sd = self._slotNPCs[name] and self._slotNPCs[name][slotIdx]
			if sd then
				if sd.model then sd.model:Destroy() end
			end
		end
		self._slotNPCs[name] = {}
	end,

	CleanupPlayer = function(self, player)
		local name = player.Name
		self:_cleanAllSlots(player)
		local active = self._activeNPCs[name]
		if active then
			for _, entry in ipairs(active) do
				entry.isActive = false
				if entry.npcModel then entry.npcModel:Destroy() end
			end
			self._activeNPCs[name] = nil
		end
		self._slotPositions[name] = nil
		self._plan[name] = nil
		self._cycleStartTime[name] = nil
		self._nextPlanIdx[name] = nil
		self._unlockedInCycle[name] = nil
		self._currentOffset[name] = nil
		self._activeNPCs[name] = nil
	end,

	KnitInit = function(self)
		print("NPCTimerService initialized")
	end,

	KnitStart = function(self)
		local npcFolder = ServerStorage:FindFirstChild("Player")
		if npcFolder then
			local displayFolder = Instance.new("Folder")
			displayFolder.Name = "NPCHeads"
			displayFolder.Parent = game:GetService("ReplicatedStorage")
			for _, child in ipairs(npcFolder:GetDescendants()) do
				if child:IsA("Model") and child:FindFirstChild("Head") then
					local clone = child:Clone()
					clone.Parent = displayFolder
				end
			end
			print("NPCTimerService: cloned NPC models to ReplicatedStorage.NPCHeads")
		end

		game:GetService("Players").PlayerRemoving:Connect(function(player)
			self:CleanupPlayer(player)
		end)

		print("NPCTimerService started")
	end,
})

return NPCTimerService
