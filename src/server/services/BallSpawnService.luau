--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local KickAnimList = require(game:GetService("ReplicatedStorage").Shared.configs.KickAnimList)
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
    _playerLoops = {},

    _GetPlayerBallCount = function(self, player)
        local count = 0
        for _, data in pairs(self._activeBalls) do
            if data.player == player then count += 1 end
        end
        return count
    end,

    _GetPlayerBallCap = function(self, player)
        local pds = Knit.GetService("PlayerDataService")
        local unlocked = pds:GetUnlockedNPCs(player)
        return math.max(3, math.min(#unlocked, Constants.MAX_BALLS_PER_PLAYER))
    end,

    _StartPlayerLoop = function(self, player)
        self._playerLoops[player] = true
        task.spawn(function()
            local Players = game:GetService("Players")
            while self._playerLoops[player] and Players:FindFirstChild(player.Name) do
                local field = Knit.GetService("FieldManagerService"):GetField(player)
                if field then
                    local cap = self:_GetPlayerBallCap(player)
                    local current = self:_GetPlayerBallCount(player)
                    if current < cap then
                        self:SpawnBall(field, player)
                        current += 1
                    end
                    local gap = cap - current
                    local interval = math.max(1, Constants.BALL_SPAWN_INTERVAL - math.floor(gap / 2))
                    task.wait(interval)
                else
                    task.wait(Constants.BALL_SPAWN_INTERVAL)
                end
            end
        end)
    end,

    _StopPlayerLoop = function(self, player)
        self._playerLoops[player] = false
    end,

    SpawnBall = function(self, field, player)
        local ballFolder = ServerStorage:FindFirstChild("Ball")
        if not ballFolder then return end

        local pds = Knit.GetService("PlayerDataService")
        local ballIds = pds:GetBallIds(player)
        local ballId = ballIds[math.random(#ballIds)]

        local template = ballFolder:FindFirstChild("ball" .. ballId)
        if not template or not template:IsA("Model") then return end

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

        ball.Parent = workspace:FindFirstChild("FieldBalls") or workspace

        local dropPos = Vector3.new(
            (math.random() - 0.5) * 40,
            Constants.BALL_SPAWN_DROP_HEIGHT,
            (math.random() - 0.5) * 40
        )

        local areaBall = field:FindFirstChild("AreaBall")
        if areaBall and areaBall:IsA("BasePart") then
            local cf = areaBall.CFrame
            local sz = areaBall.Size
            local localPos = Vector3.new(
                (math.random() - 0.5) * sz.X,
                (math.random() - 0.5) * sz.Y,
                (math.random() - 0.5) * sz.Z
            )
            local worldPos = cf:PointToWorldSpace(localPos)
            dropPos = Vector3.new(
                worldPos.X,
                Constants.BALL_SPAWN_DROP_HEIGHT,
                worldPos.Z
            )
        end

        ball:PivotTo(CFrame.new(dropPos))

        local highlight = ball:FindFirstChildWhichIsA("Highlight")
        if highlight then
            highlight.Enabled = true
        end

        self._activeBalls[ball] = {
            player = player,
            model = ball,
            mainPart = mainPart,
            inUse = false,
            claimedByNPC = false,
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

            if not self._activeBalls[ball] then return end
            task.wait()
        end

        if not self._activeBalls[ball] then return end

        ballData.landPos = targetPos

        self.Client.OnBallLanded:FireAll(mainPart.Position, ball.Name)

        task.spawn(function()
            local Players = game:GetService("Players")
            while self._activeBalls[ball] do
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - mainPart.Position).Magnitude
                            if dist < Constants.AUTO_KICK_DISTANCE then
                                -- skip if player already kicked this ball
                                if ballData.inUse and not ballData.claimedByNPC then break end
                                ballData.inUse = true
                                ballData.inUseTime = tick()
                                ballData.claimedByNPC = false
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

        local kickConfig = KickAnimList[math.random(#KickAnimList)]

        local anim = Instance.new("Animation")
        anim.AnimationId = kickConfig.animId
        local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
        if not animator.Parent then animator.Parent = humanoid end
        local track = animator:LoadAnimation(anim)
        if track then
            track.Looped = false
            track:Play()
        end

        task.wait(kickConfig.delay)
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
        local goalChk2 = goalChk:FindFirstChild("goal_chk2")

        local gSize = goalChk2 and goalChk2.Size or goalChk.Size
        local gCf = (goalChk2 or goalChk).CFrame
        local rx = (math.random() - 0.5) * gSize.X
        local rz = (math.random() - 0.5) * gSize.Z
        local localOffset = Vector3.new(rx, 0, rz)
        local targetPos = gCf:PointToWorldSpace(localOffset)
        targetPos = Vector3.new(targetPos.X, Constants.BALL_LAND_Y + 0.1, targetPos.Z)
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
        local now = tick()
        for ball, data in pairs(self._activeBalls) do
            if data.inUse then
                if data.inUseTime and now - data.inUseTime > 15 then
                    data.inUse = false
                    data.inUseTime = nil
                end
            end
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
            data.inUseTime = tick()
            data.claimedByNPC = true
            return data
        end
        return nil
    end,

    IsBallTaken = function(self, ballModel)
        local data = self._activeBalls[ballModel]
        return data ~= nil and data.inUse and not data.claimedByNPC
    end,

    RemoveBall = function(self, ballModel)
        self._activeBalls[ballModel] = nil
    end,

    KnitInit = function(self)
        print("BallSpawnService initialized")
    end,

    KnitStart = function(self)
        local Players = game:GetService("Players")

        Players.PlayerAdded:Connect(function(player)
            task.spawn(function()
                repeat task.wait(0.5) until player.Character
                self:_StartPlayerLoop(player)
            end)
        end)

        Players.PlayerRemoving:Connect(function(player)
            self:_StopPlayerLoop(player)
            for ball, data in pairs(self._activeBalls) do
                if data.player == player then
                    if ball.Parent then ball:Destroy() end
                    self._activeBalls[ball] = nil
                end
            end
        end)

        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                repeat task.wait(0.5) until player.Character
                self:_StartPlayerLoop(player)
            end)
        end

        print("BallSpawnService started")
    end,
})

return BallSpawnService
