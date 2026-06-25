--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local KickAnimList = require(game:GetService("ReplicatedStorage").Shared.configs.KickAnimList)
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

        if not nearest then return end

        ballSpawn:ClaimBall(nearest.model)

        humanoid.WalkSpeed = Constants.NPC_WALK_SPEED

        local runAnim = Instance.new("Animation")
        runAnim.AnimationId = Constants.NPC_RUN_ANIM_ID
        local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
        if not animator.Parent then animator.Parent = humanoid end
        local runTrack = animator:LoadAnimation(runAnim)
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
                    -- check ball still available (player may have kicked it already)
                    if ballSpawn:IsBallTaken(nearest.model) then
                        return
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

        local kickConfig = KickAnimList[math.random(#KickAnimList)]

        local anim = Instance.new("Animation")
        anim.AnimationId = kickConfig.animId
        local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
        if not animator.Parent then animator.Parent = humanoid end
        local animTrack = animator:LoadAnimation(anim)
        if animTrack then
            animTrack.Looped = false
            animTrack:Play()
        end

        task.wait(kickConfig.delay)
        if ball then
            self:_FlyBallToGoal(player, ball, slotData)
        end

        local primary = npcModel:FindFirstChild("HumanoidRootPart")
        if primary then
            local field = Knit.GetService("FieldManagerService"):GetField(player)
            local goal = field and field:FindFirstChild("_door")
            if goal then
                local goalPos = goal:GetPivot().Position
                local npcPos = primary.Position
                local lookDir = (Vector3.new(goalPos.X, 0, goalPos.Z) - Vector3.new(npcPos.X, 0, npcPos.Z)).Unit
                if lookDir.Magnitude > 0 then
                    primary.CFrame = CFrame.lookAt(primary.Position, primary.Position + lookDir)
                end
            end
        end
        humanoid.AutoRotate = true
    end,

    _FlyBallToGoal = function(self, player, ball, slotData)
		local fieldMgr = Knit.GetService("FieldManagerService")
		local field = fieldMgr:GetField(player)
		local goal = field and field:FindFirstChild("_door")
		if not goal then return end
		local goalChk = goal:FindFirstChild("goal_chk")
		if not goalChk then return end
		local goalChk2 = goalChk:FindFirstChild("goal_chk2")

		local gSize = goalChk2 and goalChk2.Size or goalChk.Size
		local gCf = (goalChk2 or goalChk).CFrame
		local rx = (math.random() - 0.5) * gSize.X
		local rz = (math.random() - 0.5) * gSize.Z
		local localOffset = Vector3.new(rx, 0, rz)
		local targetPos = gCf:PointToWorldSpace(localOffset)
		targetPos = Vector3.new(targetPos.X, Constants.BALL_LAND_Y + 0.1, targetPos.Z)
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
        local startPos = mainPart.Position
        local arcHeight = math.random(Constants.BALL_ARC_MIN, Constants.BALL_ARC_MAX)

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

			local coinEvent = ReplicatedStorage:FindFirstChild("CoinEffectEvent")
			if coinEvent then
				coinEvent:FireClient(player, mainPart.Position)
			end

			if self._soundEvent then
				self._soundEvent:FireClient(player, "coins")
			end

            local rewardService = Knit.GetService("RewardService")
            rewardService:AwardGoal(player, slotData.npcId)
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

		local coinEvent = Instance.new("RemoteEvent")
		coinEvent.Name = "CoinEffectEvent"
		coinEvent.Parent = ReplicatedStorage

        print("AutoKickService started")
    end,
})

return AutoKickService
