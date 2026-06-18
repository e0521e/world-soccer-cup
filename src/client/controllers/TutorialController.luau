local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function findField()
	local player = Players.LocalPlayer
	print("[Tutorial] findField for", player.DisplayName)
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name:find("Field_") then
			local ownerGui = child:FindFirstChild("FieldOwnerGui", true)
			if ownerGui and ownerGui:IsA("BillboardGui") then
				local nameLabel = ownerGui:FindFirstChild("PlayerName")
				if nameLabel and nameLabel:IsA("TextLabel") then
					print("[Tutorial] found field", child.Name, "owner:", nameLabel.Text)
					if nameLabel.Text == player.DisplayName then
						return child
					end
				end
			end
		end
	end
	print("[Tutorial] no field found for", player.DisplayName)
	return nil
end

local function findFirstNPC(field)
	local player = Players.LocalPlayer
	local char = player.Character
	local npcTimer = Knit.GetService("NPCTimerService")
	local slotPos = npcTimer:GetSlotPosition(1)
	if not slotPos then
		print("[Tutorial] no Slot1 position available")
		return nil
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child ~= char then
			local root = child:FindFirstChild("HumanoidRootPart")
			if root and child:FindFirstChildWhichIsA("Humanoid") then
				if (root.Position - slotPos).Magnitude < 3 then
					print("[Tutorial] found NPC at Slot1:", child.Name)
					return root
				end
			end
		end
	end
	print("[Tutorial] no NPC found at Slot1 position")
	return nil
end

local function findNearestBall()
	local nearest, nearestDist = nil, math.huge
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name:find("FieldBall") then
			local main = child:FindFirstChild("Main")
			if main then
				return main
			end
		end
	end
	print("[Tutorial] no ball found")
	return nil
end

local function createBeamArrow(targetPos, text)
	print("[Tutorial] createBeamArrow at", targetPos, "text:", text)

	local player = Players.LocalPlayer
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	local targetPart = Instance.new("Part")
	targetPart.Name = "TutorialBeamTarget"
	targetPart.Size = Vector3.new(0.5, 0.5, 0.5)
	targetPart.Position = targetPos + Vector3.new(0, 2, 0)
	targetPart.Anchored = true
	targetPart.CanCollide = false
	targetPart.Transparency = 1
	targetPart.Parent = Workspace

	local targetAttach = Instance.new("Attachment")
	targetAttach.Name = "BeamTarget"
	targetAttach.Parent = targetPart

	local playerAttach
	if root then
		playerAttach = Instance.new("Attachment")
		playerAttach.Name = "BeamPlayer"
		playerAttach.Position = Vector3.new(0, 3, 0)
		playerAttach.Parent = root
	end

	local beam = game:GetService("StarterGui"):FindFirstChild("BeamGuide")
	if beam and playerAttach then
		beam = beam:Clone()
		beam.Attachment0 = targetAttach
		beam.Attachment1 = playerAttach
		beam.Parent = targetPart
	else
		warn("[Tutorial] BeamGuide or player character not found")
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 300, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = targetPart
	billboard.Parent = targetPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = billboard

	return { target = targetPart, playerAttach = playerAttach, beam = beam }
end

local function destroyArrow(arrow)
	if arrow then
		if arrow.beam then arrow.beam:Destroy() end
		if arrow.target then arrow.target:Destroy() end
		if arrow.playerAttach then arrow.playerAttach:Destroy() end
	end
end

local TutorialController = Knit.CreateController({
	Name = "TutorialController",

	_running = false,

	KnitStart = function(self)
		local reward = Knit.GetService("RewardService")
		local isNew = false
		for i = 1, 20 do
			isNew = reward:IsNewPlayer()
			if isNew then break end
			task.wait(0.5)
		end
		print("[Tutorial] IsNewPlayer result:", isNew)
		if not isNew then
			print("[Tutorial] player is not new, skipping")
			return end

		self._running = true
		task.spawn(function()
			self:_RunTutorial()
		end)
	end,

	_RunTutorial = function(self)
		print("[Tutorial] _RunTutorial started")
		local player = Players.LocalPlayer
		local reward = Knit.GetService("RewardService")
		local upgradeEvent = ReplicatedStorage:FindFirstChild("UpgradeNoticeEvent")
		local coinEvent = ReplicatedStorage:FindFirstChild("CoinEffectEvent")
		print("[Tutorial] upgradeEvent:", upgradeEvent, "coinEvent:", coinEvent)

		-- Wait for character
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart", 10)
		print("[Tutorial] character ready")

		-- Wait for field assignment
		local field
		for _ = 1, 30 do
			field = findField()
			if field then break end
			task.wait(0.5)
		end
		print("[Tutorial] field:", field)

		---- Step 1: Kick a ball ----
		print("[Tutorial] Step 1: waiting for ball")
		local ball = findNearestBall()
		for _ = 1, 30 do
			ball = findNearestBall()
			if ball then break end
			task.wait(1)
		end
		print("[Tutorial] nearest ball:", ball)
		if ball then
			local arrow = createBeamArrow(ball.Position, "⚽ 踢球射门开始游戏")
			local kicked = false
			local conn
			if coinEvent then
				conn = coinEvent.OnClientEvent:Connect(function()
					kicked = true
				end)
			end
			local timeout = 30
			while timeout > 0 and not kicked do
				task.wait(1)
				timeout -= 1
				if not ball or not ball.Parent then
					ball = findNearestBall()
					if ball then
						destroyArrow(arrow)
						arrow = createBeamArrow(ball.Position, "⚽ 踢球射门开始游戏")
					end
				end
			end
			if conn then conn:Disconnect() end
			destroyArrow(arrow)
			task.wait(1)
		end

		print("[Tutorial] Step 1 done, moving to Step 2")

		---- Step 2: Walk to NPC ----
		print("[Tutorial] Step 2: finding NPC on field")
		field = findField()
		local npcRoot = findFirstNPC(field)
		for _ = 1, 20 do
			npcRoot = findFirstNPC(field)
			if npcRoot then break end
			task.wait(1)
		end
		print("[Tutorial] npcRoot:", npcRoot)
		if npcRoot then
			local arrow = createBeamArrow(npcRoot.Position + Vector3.new(0, 2, 0), "👤 靠近球员，他将加入你的队伍")
			local near = false
			local timeout = 30
			while timeout > 0 and not near do
				task.wait(0.5)
				timeout -= 0.5
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and npcRoot and npcRoot.Parent then
					local dist = (root.Position - npcRoot.Position).Magnitude
					if dist < 12 then
						near = true
					end
				end
			end
			destroyArrow(arrow)
			task.wait(1)
		end
		print("[Tutorial] Step 2 done")

		---- Step 3: Upgrade zone ----
		print("[Tutorial] Step 3: finding upgrade zone")
		local zone = field and field:FindFirstChild("Zone_LevelUp")
		local zonePart = zone and (zone:IsA("BasePart") and zone or zone:FindFirstChildWhichIsA("BasePart"))
		if zonePart then
			local arrow = createBeamArrow(zonePart.Position, "⬆ 触碰升级区域提升等级")
			local upgraded = false
			local conn
			if upgradeEvent then
				conn = upgradeEvent.OnClientEvent:Connect(function(msg)
					if msg == "Success" then upgraded = true end
				end)
			end
			local timeout = 15
			while timeout > 0 and not upgraded do
				task.wait(1)
				timeout -= 1
			end
			if conn then conn:Disconnect() end
			destroyArrow(arrow)
			task.wait(1)
		end
		print("[Tutorial] Step 3 done")

		---- Step 4: World Cup trophy ----
		local trophyModel = Workspace:FindFirstChild("trophy")
		local trophyPart = trophyModel and trophyModel:FindFirstChild("Main")
		if trophyPart then
			local arrow = createBeamArrow(trophyPart.Position, "🏆 触摸世界杯奖杯参赛")
			local triggered = false
			local conn
			if upgradeEvent then
				conn = upgradeEvent.OnClientEvent:Connect(function(msg)
					if msg == "WorldCupStart" or msg == "WorldCupDone" then
						triggered = true
					end
				end)
			end
			local timeout = 15
			while timeout > 0 and not triggered do
				task.wait(1)
				timeout -= 1
			end
			if conn then conn:Disconnect() end
			destroyArrow(arrow)
			task.wait(1)
		end
		print("[Tutorial] Step 4 done")

		---- Step 5: Kick again ----
		local ball = findNearestBall()
		if ball then
			local arrow = createBeamArrow(ball.Position, "⚽ 再踢一球完成引导")
			local kicked = false
			local conn
			if coinEvent then
				conn = coinEvent.OnClientEvent:Connect(function()
					kicked = true
				end)
			end
			local timeout = 30
			while timeout > 0 and not kicked do
				task.wait(1)
				timeout -= 1
				if not ball or not ball.Parent then
					ball = findNearestBall()
					if ball then
						destroyArrow(arrow)
						arrow = createBeamArrow(ball.Position, "⚽ 再踢一球完成引导")
					end
				end
			end
			if conn then conn:Disconnect() end
			destroyArrow(arrow)
		end

		reward:CompleteTutorial()
		self._running = false
	end,

	KnitInit = function(self)
		print("TutorialController initialized")
	end,
})

return TutorialController