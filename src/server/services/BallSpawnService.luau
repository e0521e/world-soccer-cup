--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BallSpawnService = Knit.CreateService({
    Name = "BallSpawnService",

    Client = {
        OnBallSpawned = Knit.CreateSignal(),
        OnBallLanded = Knit.CreateSignal(),
        OnPlayerKick = Knit.CreateSignal(),
        OnBallFlying = Knit.CreateSignal(),
        OnPlayerGoal = Knit.CreateSignal(),
    },

    _activeBalls = {},
    _spawnTimer = nil,

    SpawnBall = function(self, field)
        local ballFolder = ServerStorage:FindFirstChild("Ball")
        if not ballFolder then return end

        local ballTemplates = ballFolder:GetChildren()
        if #ballTemplates == 0 then return end

        local template = ballTemplates[math.random(#ballTemplates)]
        if not template:IsA("Model") then return end

        local ball = template:Clone()
        ball.Name = "FieldBall_" .. tostring(tick())

        local mainPart = ball:FindFirstChild("Main")
        if not mainPart then
            ball:Destroy()
            return
        end

        ball.PrimaryPart = mainPart
        mainPart.Anchored = true
        mainPart.CanCollide = false

        ball.Parent = workspace

        local dropPos = Vector3.new(
            (math.random() - 0.5) * 40,
            Constants.BALL_SPAWN_DROP_HEIGHT,
            (math.random() - 0.5) * 40
        )

        local areaBall = field:FindFirstChild("AreaBall")
        if areaBall and areaBall:IsA("BasePart") then
            local cp = areaBall.Position
            local cs = areaBall.Size
            dropPos = Vector3.new(
                cp.X + (math.random() - 0.5) * cs.X,
                Constants.BALL_SPAWN_DROP_HEIGHT,
                cp.Z + (math.random() - 0.5) * cs.Z
            )
        end

        ball:PivotTo(CFrame.new(dropPos))

        local highlight = ball:FindFirstChildWhichIsA("Highlight")
        if highlight then
            highlight.Enabled = true
        end

        self._activeBalls[ball] = {
            model = ball,
            mainPart = mainPart,
            inUse = false,
            spawnTime = tick(),
            dropPos = dropPos,
        }
        self.Client.OnBallSpawned:FireAll(dropPos, mainPart.Size)

		local soundEvent = ReplicatedStorage:FindFirstChild("SoundEvent")
		if soundEvent then
			soundEvent:FireAllClients("Sprint")
		end

        task.spawn(function()
            self:_WaitForLand(ball, mainPart)
        end)
    end,

    _WaitForLand = function(self, ball, mainPart)
        local ballData = self._activeBalls[ball]
        if not ballData then return end

        local startPos = ball:GetPivot()
        local targetPos = Vector3.new(mainPart.Position.X, Constants.BALL_LAND_Y, mainPart.Position.Z)
        local dropDuration = 1.5
        local startTime = tick()

        while true do
            local elapsed = tick() - startTime
            local t = math.min(elapsed / dropDuration, 1)
            local eased = t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
            local currentY = startPos.Y + (targetPos.Y - startPos.Y) * eased
            local currentPos = Vector3.new(mainPart.Position.X, currentY, mainPart.Position.Z)
            ball:PivotTo(CFrame.new(currentPos) * startPos.Rotation)

            if t >= 1 then
                ball:PivotTo(CFrame.new(targetPos) * startPos.Rotation)
                break
            end

            if not self._activeBalls[ball] or ballData.inUse then return end
            task.wait()
        end

        if not self._activeBalls[ball] or ballData.inUse then return end

        ballData.landPos = targetPos

        self.Client.OnBallLanded:FireAll(mainPart.Position, ball.Name)

        task.spawn(function()
            local Players = game:GetService("Players")
            while not ballData.inUse and self._activeBalls[ball] do
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - mainPart.Position).Magnitude
                            if dist < Constants.AUTO_KICK_DISTANCE then
                                ballData.inUse = true
                                self:_PlayerKickBall(player, ball, ballData)
                                return
                            end
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
    end,

    _PlayerKickBall = function(self, player, ball, ballData)
        local character = player.Character
        if not character then return end

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            humanoid:MoveTo(rootPart.Position)
            humanoid.AutoRotate = false
        end

        self.Client.OnPlayerKick:Fire(player, ball.Name)

        local anim = Instance.new("Animation")
        anim.AnimationId = Constants.NPC_KICK_ANIM_ID
        local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
        if not animator.Parent then animator.Parent = humanoid end
        local track = animator:LoadAnimation(anim)
        if track then
            track.Looped = false
            track:Play()
        end

        task.wait(Constants.KICK_ANIM_TO_FLIGHT_DELAY)
        if rootPart then
            humanoid.AutoRotate = true
        end
        self:_FlyBallToGoal(player, ball, ballData)
    end,

    _FlyBallToGoal = function(self, player, ball, ballData)
		local fieldMgr = Knit.GetService("FieldManagerService")
		local field = fieldMgr:GetField(player)
        if not field then return end
        local goal = field:FindFirstChild("_door")
        if not goal then return end
        local goalChk = goal:FindFirstChild("goal_chk")
        if not goalChk then return end

        local gPos = goalChk.Position
        local gSize = goalChk.Size
        local toGoal = Vector3.new(gPos.X, 0, gPos.Z).Unit
        local offsetDist = 2 + math.random() * 8
        local targetPos = Vector3.new(
            gPos.X + toGoal.X * offsetDist,
            Constants.BALL_LAND_Y + 0.1,
            gPos.Z + toGoal.Z * offsetDist
        )
        local mainPart = ballData.mainPart
        local startPos = mainPart.Position
        local arcHeight = math.random(Constants.BALL_ARC_MIN, Constants.BALL_ARC_MAX)
        local flightDuration = Constants.BALL_FLIGHT_DURATION

        self.Client.OnBallFlying:Fire(player, ball.Name, startPos, targetPos)

		local soundEvent = ReplicatedStorage:FindFirstChild("SoundEvent")
		if soundEvent then
			soundEvent:FireClient(player, "shoot")
		end

        local shootSound = mainPart:FindFirstChild("Shoot")
        if shootSound then
            shootSound:Play()
        end

        local trail = mainPart:FindFirstChildWhichIsA("Trail")
        if trail then
            trail.Enabled = true
        end

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
                self:_DetectGoal(player, ball, ballData, mainPart, goalChk)
            end
        end)
    end,

    _DetectGoal = function(self, player, ball, ballData, mainPart, goalChk)
        local dist = (mainPart.Position - goalChk.Position).Magnitude
        if dist < 40 then
            self.Client.OnPlayerGoal:Fire(player, dist)

			local coinEvent = ReplicatedStorage:FindFirstChild("CoinEffectEvent")
			if coinEvent then
				coinEvent:FireClient(player, mainPart.Position)
			end

			local soundEvent = ReplicatedStorage:FindFirstChild("SoundEvent")
			if soundEvent then
				soundEvent:FireClient(player, "coins")
			end

            local rewardService = Knit.GetService("RewardService")
            local npcId = "player"
            rewardService:AwardGoal(player, npcId)
        end

        task.delay(2, function()
            if ball and ball.Parent then
                ball:Destroy()
            end
            self._activeBalls[ball] = nil
        end)
    end,

    GetActiveBallPositions = function(self)
        local positions = {}
        for _, data in pairs(self._activeBalls) do
            if not data.inUse and data.landPos then
                table.insert(positions, {
                    position = data.landPos,
                    model = data.model,
                })
            end
        end
        return positions
    end,

    ClaimBall = function(self, ballModel)
        local data = self._activeBalls[ballModel]
        if data and not data.inUse then
            data.inUse = true
            return data
        end
        return nil
    end,

    RemoveBall = function(self, ballModel)
        self._activeBalls[ballModel] = nil
    end,

    KnitInit = function(self)
        print("BallSpawnService initialized")
    end,

    KnitStart = function(self)
        local fieldMgr = Knit.GetService("FieldManagerService")
        task.spawn(function()
            while true do
                task.wait(Constants.BALL_SPAWN_INTERVAL)
                local players = game:GetService("Players"):GetPlayers()
                local activeFieldCount = 0
                for _, player in ipairs(players) do
                    if fieldMgr:GetField(player) then
                        activeFieldCount += 1
                    end
                end
                local maxBalls = Constants.MAX_BALLS_ON_FIELD * math.max(activeFieldCount, 1)

                local totalBalls = 0
                for _ in pairs(self._activeBalls) do
                    totalBalls += 1
                end
                if totalBalls >= maxBalls then continue end

                for _, player in ipairs(players) do
                    local field = fieldMgr:GetField(player)
                    if field then
                        self:SpawnBall(field)
                    end
                end
            end
        end)
        print("BallSpawnService started")
    end,
})

return BallSpawnService
