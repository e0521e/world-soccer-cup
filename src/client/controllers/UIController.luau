--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MAX_MINUTES = 10
local DOT_SIZE = 12
local DOT_VIBRATE_SCALE = 1.3

local UIController = Knit.CreateController({
	Name = "UIController",

	_screenGui = nil,
	_hudFrame = nil,
	_coinLabel = nil,
	_levelLabel = nil,
	_goalLabel = nil,
	_upgradeButton = nil,
	_timeLabel = nil,
	_dots = nil,
	_unlockLabel = nil,
	_teamDone = false,

	KnitStart = function(self)
		self._reward = Knit.GetService("RewardService")
		self._autoKick = Knit.GetService("AutoKickService")
		self._npcProgress = Knit.GetService("NPCProgressService")
		local npcTimer = Knit.GetService("NPCTimerService")
		local ballSpawn = Knit.GetService("BallSpawnService")
		local playerSvc = Knit.GetService("PlayerService")

		self:_CreateHUD()

	npcTimer.OnTimerUpdated:Connect(function() end)
	npcTimer.OnNPCActivated:Connect(function() end)
	npcTimer.OnTimerExpired:Connect(function() end)
	ballSpawn.OnBallSpawned:Connect(function() end)
	ballSpawn.OnBallLanded:Connect(function() end)
	ballSpawn.OnPlayerKick:Connect(function() end)
	ballSpawn.OnBallFlying:Connect(function() end)
	ballSpawn.OnPlayerGoal:Connect(function() end)
	playerSvc.OnTakeover:Connect(function() end)
	playerSvc.OnCharacterChanged:Connect(function() end)
	playerSvc.OnRespawnQualityUp:Connect(function() end)
	self._reward.OnNPCQualityUp:Connect(function() end)
	self._reward.OnNPCUnlocked:Connect(function() end)

	-- Poll elapsed time every 1s instead of signal (signals not reaching client)
		task.spawn(function()
			while true do
				task.wait(1)
				local totalSeconds = self._npcProgress:GetElapsedTime()
				self:_UpdateTimeDisplay(totalSeconds)
				if totalSeconds >= 600 and not self._teamDone then
					self._teamDone = true
					self:_ShowTeamComplete()
				end
			end
		end)

		self._reward.OnCoinsChanged:Connect(function(player, newBalance, delta)
			if player ~= Players.LocalPlayer then return end
			self:_UpdateCoins(newBalance, delta)
		end)

		self._reward.OnLevelUp:Connect(function(player, newLevel, multiplier)
			if player ~= Players.LocalPlayer then return end
			self:_UpdateLevel(newLevel, multiplier)
		end)

		if self._autoKick then
			self._autoKick.OnGoalScored:Connect(function(player, slotId, npcId)
				if player ~= Players.LocalPlayer then return end
				self:_ShowGoalEffect()
			end)
		end

		self:_UpdateCoins(self._reward:GetCoins(), 0)
	end,

	KnitInit = function(self)
		print("UIController initialized")
	end,

	_CreateHUD = function(self)
		self._screenGui = Instance.new("ScreenGui")
		self._screenGui.Name = "FreeKickHUD"
		self._screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		self._screenGui.ResetOnSpawn = false

		local hud = Instance.new("Frame")
		hud.Name = "HUD"
		hud.Size = UDim2.new(1, 0, 0, 70)
		hud.BackgroundTransparency = 0.5
		hud.BackgroundColor3 = Color3.new(0, 0, 0)
		hud.Parent = self._screenGui
		self._hudFrame = hud

		local level = Instance.new("TextLabel")
		level.Name = "LevelLabel"
		level.Size = UDim2.new(0, 150, 0, 25)
		level.Position = UDim2.new(0, 10, 0, 5)
		level.BackgroundTransparency = 1
		level.TextColor3 = Color3.new(1, 1, 0)
		level.TextStrokeTransparency = 0.3
		level.TextScaled = true
		level.Font = Enum.Font.GothamBold
		level.TextXAlignment = Enum.TextXAlignment.Left
		level.Text = "Lv.1 (x1.0)"
		level.Parent = hud
		self._levelLabel = level

		local coins = Instance.new("TextLabel")
		coins.Name = "CoinsLabel"
		coins.Size = UDim2.new(0, 200, 0, 25)
		coins.Position = UDim2.new(1, -210, 0, 5)
		coins.BackgroundTransparency = 1
		coins.TextColor3 = Color3.new(1, 0.84, 0)
		coins.TextStrokeTransparency = 0.3
		coins.TextScaled = true
		coins.Font = Enum.Font.GothamBold
		coins.TextXAlignment = Enum.TextXAlignment.Right
		coins.Text = "Coins: 0"
		coins.Parent = hud
		self._coinLabel = coins

		local center = Instance.new("Frame")
		center.Name = "TimeDotContainer"
		center.Size = UDim2.new(0, 220, 0, 30)
		center.Position = UDim2.new(0.5, -140, 0, 5)
		center.BackgroundTransparency = 1
		center.Parent = hud

		local timeLabel = Instance.new("TextLabel")
		timeLabel.Name = "TimerLabel"
		timeLabel.Size = UDim2.new(0, 50, 0, 16)
		timeLabel.Position = UDim2.new(0.5, -25, 0, -18)
		timeLabel.BackgroundTransparency = 1
		timeLabel.TextColor3 = Color3.new(1, 1, 1)
		timeLabel.TextStrokeTransparency = 0.3
		timeLabel.TextScaled = true
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.Text = "00:00"
		timeLabel.Parent = center
		self._timeLabel = timeLabel

		local bar = Instance.new("Frame")
		bar.Name = "ProgressBar"
		bar.Size = UDim2.new(1, -20, 0, 4)
		bar.Position = UDim2.new(0, 10, 0.5, -2)
bar.BackgroundColor3 = Color3.new(1, 0.88, 0.1)
bar.BorderSizePixel = 0
bar.ZIndex = 0
bar.Parent = center

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = bar

self._progressBar = bar

		self._dots = {}
		local dotSpacing = 100 / (MAX_MINUTES - 1)
		for i = 1, MAX_MINUTES do
			local dot = Instance.new("Frame")
			dot.Name = "Dot_" .. tostring(i)
			dot.Size = UDim2.new(0, 12, 0, 12)
			dot.Position = UDim2.new(dotSpacing * (i - 1) / 100, -6, 0.5, -6)
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
			dot.ZIndex = 2
			dot.Parent = center

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = dot

			self._dots[i] = dot
		end

		local upgrade = Instance.new("TextButton")
		upgrade.Name = "UpgradeButton"
		upgrade.Size = UDim2.new(0, 100, 0, 25)
		upgrade.Position = UDim2.new(1, -110, 0, 38)
		upgrade.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
		upgrade.TextColor3 = Color3.new(1, 1, 1)
		upgrade.TextScaled = true
		upgrade.Font = Enum.Font.GothamBold
		upgrade.Text = "UPGRADE"
		upgrade.Parent = hud

		upgrade.MouseButton1Click:Connect(function()
			local result = self._reward:UpgradeLevel()
			if not result then
				upgrade.Text = "NOT ENOUGH"
				task.delay(1, function()
					upgrade.Text = "UPGRADE"
				end)
			end
		end)
		self._upgradeButton = upgrade

		local goal = Instance.new("TextLabel")
		goal.Name = "GoalLabel"
		goal.Size = UDim2.new(0, 400, 0, 100)
		goal.Position = UDim2.new(0.5, -200, 0.5, -50)
		goal.BackgroundTransparency = 1
		goal.TextColor3 = Color3.new(1, 1, 0)
		goal.TextStrokeTransparency = 0
		goal.TextScaled = true
		goal.Font = Enum.Font.GothamBlack
		goal.Text = "GOAL!"
		goal.Visible = false
		goal.ZIndex = 10
		goal.Parent = self._screenGui
		self._goalLabel = goal

		local unlock = Instance.new("TextLabel")
		unlock.Name = "UnlockLabel"
		unlock.Size = UDim2.new(0, 250, 0, 30)
		unlock.Position = UDim2.new(0.5, -125, 0.4, 0)
		unlock.BackgroundTransparency = 0.3
		unlock.BackgroundColor3 = Color3.new(0, 0, 0)
		unlock.TextColor3 = Color3.new(0, 1, 0.2)
		unlock.TextStrokeTransparency = 0.3
		unlock.TextScaled = true
		unlock.Font = Enum.Font.GothamBold
		unlock.Text = ""
		unlock.Visible = false
		unlock.ZIndex = 10
		unlock.Parent = self._screenGui
		self._unlockLabel = unlock
	end,

	_FormatTime = function(self, totalSeconds)
		local minutes = math.floor(totalSeconds / 60)
		local seconds = totalSeconds % 60
		return string.format("%02d:%02d", minutes, seconds)
	end,

	_UpdateTimeDisplay = function(self, totalSeconds)
		if self._timeLabel then
			self._timeLabel.Text = self:_FormatTime(totalSeconds)
		end
		local filledCount = math.min(math.floor(totalSeconds / 60), MAX_MINUTES)
		for i = 1, MAX_MINUTES do
			local dot = self._dots[i]
			if dot then
				if i <= filledCount then
					dot.BackgroundColor3 = Color3.new(0.2, 0.85, 0.15)
				else
					dot.BackgroundColor3 = Color3.new(0.4, 0.4, 0.4)
				end
			end
		end
		if self._progressBar then
			self._progressBar.Size = UDim2.new(filledCount / MAX_MINUTES, -20, 0, 4)
		end
	end,

	_AnimateDot = function(self, npcIdx, displayName)
		local dot = self._dots[npcIdx]
		if not dot then return end

		dot.BackgroundColor3 = Color3.new(1, 0.84, 0)

		local normalSize = UDim2.new(0, DOT_SIZE, 0, DOT_SIZE)
		local bigSize = UDim2.new(0, math.floor(DOT_SIZE * DOT_VIBRATE_SCALE), 0, DOT_SIZE)

		local growTween = TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = bigSize,
		})
		growTween:Play()
		growTween.Completed:Connect(function()
			local shrinkTween = TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = normalSize,
			})
			shrinkTween:Play()
		end)

		if self._unlockLabel then
			self._unlockLabel.Text = displayName .. " 解锁!"
			self._unlockLabel.Visible = true
			self._unlockLabel.TextTransparency = 0

			local fadeTween = TweenService:Create(self._unlockLabel, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
			})
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				self._unlockLabel.Visible = false
			end)
		end
	end,

	_ShowTeamComplete = function(self)
		self:_ShowFloatingText("踢球队完成!", Color3.new(0, 1, 0))
	end,

	_UpdateCoins = function(self, newBalance, delta)
		if self._coinLabel then
			self._coinLabel.Text = "Coins: " .. tostring(math.floor(newBalance))
		end
		if delta > 0 then
			self:_ShowFloatingText("+" .. tostring(math.floor(delta)) .. " Coins", Color3.new(1, 0.84, 0))
		end
	end,

	_UpdateLevel = function(self, newLevel, multiplier)
		if self._levelLabel then
			self._levelLabel.Text = "Lv." .. tostring(newLevel) .. " (x" .. tostring(multiplier) .. ")"
		end
		self:_ShowFloatingText("LEVEL UP! Lv." .. tostring(newLevel), Color3.new(1, 1, 0))
	end,

	_ShowGoalEffect = function(self)
		if not self._goalLabel then return end
		self._goalLabel.Visible = true
		self._goalLabel.TextTransparency = 0
		self._goalLabel.Text = "GOAL!"
		self._goalLabel.Position = UDim2.new(0.5, -200, 0.5, -50)

		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(self._goalLabel, tweenInfo, {
			TextTransparency = 1,
			Position = UDim2.new(0.5, -200, 0.3, -50),
		})
		tween:Play()
		tween.Completed:Connect(function()
			self._goalLabel.Visible = false
		end)
	end,

	_ShowFloatingText = function(self, text, color)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 200, 0, 30)
		label.Position = UDim2.new(0.5, -100, 0.5, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.3
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.ZIndex = 20
		label.Parent = self._screenGui

		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(label, tweenInfo, {
			TextTransparency = 1,
			Position = UDim2.new(0.5, -100, 0.3, 0),
		})
		tween:Play()
		tween.Completed:Connect(function()
			label:Destroy()
		end)
	end,
})

return UIController
