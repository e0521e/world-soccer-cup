--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoKickService = Knit.CreateService({
    Name = "AutoKickService",

    Client = {
        OnKickAnimation = Knit.CreateSignal(),
        OnBallFlying = Knit.CreateSignal(),
        OnGoalScored = Knit.CreateSignal(),
    },

    _soundEvent = nil,

    ExecuteKick = function(self, player, npcModel, slotData)
        self:_WalkToNearestBall(player, npcModel, slotData)
    end,

    _WalkToNearestBall = function(self, player, npcModel, slotData)
        local humanoid = npcModel:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end

        local ballSpawn = Knit.GetService("BallSpawnService")
        local activeBalls = ballSpawn:GetActiveBallPositions()

        local primary = npcModel:FindFirstChild("HumanoidRootPart")
        if not primary then return end

        local nearest = nil
        if #activeBalls > 0 then
            local npcPos = primary.Position
            local nearestDist = math.huge
            for _, info in ipairs(activeBalls) do
                local dist = (npcPos - info.position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = info
                end
            end
        end

        if not nearest then
            local ballFolder = game:GetService("ServerStorage"):FindFirstChild("Ball")
            if ballFolder then
                local template = ballFolder:FindFirstChild("ball1")
                if template and template:IsA("Model") then
                    local ball = template:Clone()
                    ball.Name = "FieldBall_" .. tostring(tick())
                    local mainPart = ball:FindFirstChild("Main")
                    if mainPart then
                        local spawnPos = Vector3.new(primary.Position.X + 8, 0.5, primary.Position.Z)
                        mainPart.Position = spawnPos
                        mainPart.Anchored = true
                        mainPart.CanCollide = false
                        ball.Parent = workspace
                        nearest = { model = ball, position = spawnPos }
                    end
                end
            end
        end

        if not nearest then return end

        ballSpawn:ClaimBall(nearest.model)
        slotData.claimedBall = nearest.model

        humanoid.WalkSpeed = Constants.NPC_WALK_SPEED

        local runAnim = Instance.new("Animation")
        runAnim.AnimationId = Constants.NPC_RUN_ANIM_ID
        local runTrack = humanoid:LoadAnimation(runAnim)
        if runTrack then
            runTrack.Looped = true
            runTrack:Play()
        end

        humanoid:MoveTo(nearest.position)

        task.spawn(function()
            while true do
                task.wait(0.3)
                if not npcModel or not npcModel.Parent then return end
                if not primary then return end
                local distXZ = math.sqrt(
                    (primary.Position.X - nearest.position.X)^2 +
                    (primary.Position.Z - nearest.position.Z)^2
                )
                if distXZ <= Constants.AUTO_KICK_DISTANCE then
                    humanoid:MoveTo(primary.Position)
                    if runTrack then
                        runTrack:Stop()
                    end
                    self:_PlayKick(player, npcModel, nearest.model, slotData)
                    return
                end
            end
        end)
    end,

    _PlayKick = function(self, player, npcModel, ball, slotData)
        local humanoid = npcModel:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end

        humanoid.AutoRotate = false
        self.Client.OnKickAnimation:Fire(player, slotData.slotId)

        local anim = Instance.new("Animation")
        anim.AnimationId = Constants.NPC_KICK_ANIM_ID
        local animTrack = humanoid:LoadAnimation(anim)
        if animTrack then
            animTrack.Looped = false
            animTrack:Play()
        end

        task.wait(Constants.KICK_ANIM_TO_FLIGHT_DELAY)
        if ball then
            self:_FlyBallToGoal(player, ball, slotData)
        end
    end,

    _FlyBallToGoal = function(self, player, ball, slotData)
		local fieldMgr = Knit.GetService("FieldManagerService")
		local field = fieldMgr:GetField(player)
		local goal = field and field:FindFirstChild("_door")
		if not goal then return end
		local goalChk = goal:FindFirstChild("goal_chk")
		if not goalChk then return end

        local gPos = goalChk.Position
		local gSize = goalChk.Size
		local toGoal = Vector3.new(gPos.X, 0, gPos.Z).Unit
		local offsetDist = gSize.Z / 2 + 1 + math.random() * (gSize.Z - 2)
		local targetPos = Vector3.new(
			gPos.X + toGoal.X * offsetDist,
			Constants.BALL_LAND_Y + 0.1,
			gPos.Z + toGoal.Z * offsetDist
		)
		local mainPart = ball:FindFirstChild("Main")
		if not mainPart then return end

		self.Client.OnBallFlying:Fire(player, slotData.slotId, mainPart.Position, targetPos)

		if self._soundEvent then
			self._soundEvent:FireClient(player, "shoot")
		end

        local shootSound = mainPart:FindFirstChild("Shoot")
        if shootSound then
            shootSound:Play()
        end

        local trail = mainPart:FindFirstChildWhichIsA("Trail")
        if trail then
            trail.Enabled = true
        end

        local flightDuration = Constants.BALL_FLIGHT_DURATION
        local arcHeight = 15

        local startPos = mainPart.Position
        local midPos = (startPos + targetPos) / 2 + Vector3.new(0, arcHeight, 0)

        local flightInfo = TweenInfo.new(
            flightDuration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )

        local startTime = tick()
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local t = math.min(elapsed / flightDuration, 1)

            local pos = startPos:Lerp(targetPos, t)
            pos = pos + Vector3.new(0, math.sin(t * math.pi) * arcHeight, 0)

            mainPart.CFrame = CFrame.new(pos) * CFrame.Angles(t * 10, t * 5, 0)

            if t >= 1 then
                connection:Disconnect()
                self:_DetectGoal(player, ball, mainPart, targetPos, slotData)
            end
        end)
    end,

    _DetectGoal = function(self, player, ball, mainPart, goalPos, slotData)
		local fieldMgr = Knit.GetService("FieldManagerService")
		local field = fieldMgr:GetField(player)
		local goal = field and field:FindFirstChild("_door")
		if not goal then return end
		local goalChk = goal:FindFirstChild("goal_chk")
		if not goalChk then return end

		local dist = (mainPart.Position - goalChk.Position).Magnitude
        local scored = dist < 40

        if scored then
            self.Client.OnGoalScored:Fire(player, slotData.slotId, slotData.npcId)

			if self._soundEvent then
				self._soundEvent:FireClient(player, "coins")
			end

            local rewardService = Knit.GetService("RewardService")
            rewardService:AwardGoal(player, slotData.npcId)

            local timerService = Knit.GetService("NPCTimerService")
            timerService:ResetSlot(player, slotData)
        end

        task.delay(2, function()
            if ball and ball.Parent then
                ball:Destroy()
            end
            local ballSpawn = Knit.GetService("BallSpawnService")
            ballSpawn:RemoveBall(ball)
        end)
    end,

    KnitInit = function(self)
        print("AutoKickService initialized")
    end,

    KnitStart = function(self)
		self._soundEvent = Instance.new("RemoteEvent")
		self._soundEvent.Name = "SoundEvent"
		self._soundEvent.Parent = ReplicatedStorage
        print("AutoKickService started")
    end,
})

return AutoKickService
