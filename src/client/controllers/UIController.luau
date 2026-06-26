local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)
local AdminData = require(game:GetService("ReplicatedStorage").Shared.configs.AdminData)
local PlayerLevels = require(game:GetService("ReplicatedStorage").Shared.configs.PlayerLevels)
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToastView = require(script.Parent.Parent.views.ToastView)
local CoreBarView = require(script.Parent.Parent.views.CoreBarView)
local InfoBarView = require(script.Parent.Parent.views.InfoBarView)
local ActionPanelView = require(script.Parent.Parent.views.ActionPanelView)
local OverlayView = require(script.Parent.Parent.views.OverlayView)
local ShopView = require(script.Parent.Parent.views.ShopView)
local GMView = require(script.Parent.Parent.views.GMView)

local function getNPCName(npcId: string): string
	for _, npc in ipairs(NPCData.NPCList) do
		if npc.id == npcId then
			return npc.displayName
		end
	end
	return npcId
end

local UIController = Knit.CreateController({
	Name = "UIController",

	_screenGui = nil,
	_teamDone = false,
	_toastDelay = 0,
	_nameTag = nil,
	_nameTagConn = nil,
	_tacticalBoardCards = {},
	_tacticalBoardFilled = false,
	_slotCountdowns = {},

	_UpdateNameTag = function(self)
		if self._nameTagConn then
			self._nameTagConn:Disconnect()
			self._nameTagConn = nil
		end

		local char = Players.LocalPlayer.Character
		if not char then
			self._nameTagConn = Players.LocalPlayer.CharacterAdded:Connect(function()
				self:_UpdateNameTag()
			end)
			return
		end

		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then
			self._nameTagConn = char.ChildAdded:Connect(function()
				self:_UpdateNameTag()
			end)
			return
		end

		local levelInfo = self._pds:GetLevel()

		if self._nameTag and self._nameTag.Parent then
			local nameLabel = self._nameTag:FindFirstChild("NameLabel")
			if nameLabel then
				nameLabel.Text = Players.LocalPlayer.DisplayName
			end
			local levelLabel = self._nameTag:FindFirstChild("LevelLabel")
			if levelLabel then
				levelLabel.Text = "Lv." .. tostring(levelInfo.level)
			end
			self._nameTag.Adornee = root
			self._nameTag.Parent = root

			self._nameTagConn = Players.LocalPlayer.CharacterAdded:Connect(function()
				self:_UpdateNameTag()
			end)
			return
		end

		if self._nameTag then
			self._nameTag:Destroy()
			self._nameTag = nil
		end

		local gui = Instance.new("BillboardGui")
		gui.Name = "PlayerNameTag"
		gui.Size = UDim2.new(0, 160, 0, 44)
		gui.StudsOffset = Vector3.new(0, 3.5, 0)
		gui.AlwaysOnTop = true
		gui.Adornee = root
		gui.Parent = root

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0, 22)
		nameLabel.Position = UDim2.new(0, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = Players.LocalPlayer.DisplayName
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextStrokeTransparency = 0.3
		nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Parent = gui

		local levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.Size = UDim2.new(1, 0, 0, 20)
		levelLabel.Position = UDim2.new(0, 0, 0, 22)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "Lv." .. tostring(levelInfo.level)
		levelLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
		levelLabel.TextStrokeTransparency = 0.4
		levelLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		levelLabel.TextScaled = true
		levelLabel.Font = Enum.Font.GothamBold
		levelLabel.TextXAlignment = Enum.TextXAlignment.Center
		levelLabel.Parent = gui

		self._nameTag = gui

		self._nameTagConn = Players.LocalPlayer.CharacterAdded:Connect(function()
			self:_UpdateNameTag()
		end)
	end,

	_FindSlotModel = function(self, slotId)
		local playerName = Players.LocalPlayer.Name
		local function search(container)
			for _, obj in ipairs(container:GetChildren()) do
				if obj:IsA("Model") then
					local sid = obj:GetAttribute("SlotId")
					local owner = obj:GetAttribute("OwnerPlayer")
					if sid ~= nil and owner == playerName and sid == slotId then
						return obj
					end
				end
				local found = search(obj)
				if found then return found end
			end
			return nil
		end
		local container = Workspace:FindFirstChild("FieldNPCs")
		if container then
			local found = search(container)
			if found then return found end
		end
		return search(Workspace)
	end,

	KnitStart = function(self)
		self._pds = Knit.GetService("PlayerDataService")
		self._autoKick = Knit.GetService("AutoKickService")
		self._npcProgress = Knit.GetService("NPCProgressService")

		self._pds.OnLevelUp:Connect(function(level, multiplier)
			print("[OnLevelUp] level", level, "multiplier", multiplier)
			self._toast:Show({
				emoji = "⬆",
				title = "LEVEL UP!",
				body = "Lv." .. tostring(level) .. " (x" .. tostring(multiplier) .. ")",
				duration = 3,
			})
			self._infoBar:UpdateCoins(self._pds:GetCoins())
			self._infoBar:UpdatePower(self._pds:GetPower())
			self._infoBar:UpdateTrophies(self._pds:GetTrophies())
			self:_UpdateNameTag()
		end)

		local npcTimer = Knit.GetService("NPCTimerService")
		local ballSpawn = Knit.GetService("BallSpawnService")
		local npcProg = Knit.GetService("NPCProgressService")

		npcProg.OnTimeTick:Connect(function() end)
		self._pds.OnCoinsChanged:Connect(function() end)
		ballSpawn.OnBallSpawned:Connect(function() end)
		ballSpawn.OnBallLanded:Connect(function() end)

		self._lastKickPos = Vector3.new()

		self._autoKick.OnBallFlying:Connect(function(slotId, startPos, targetPos)
			self._lastKickPos = startPos
		end)

		ballSpawn.OnBallFlying:Connect(function(ballName, startPos, targetPos)
			self._lastKickPos = startPos
		end)

		local coinEvent = ReplicatedStorage:FindFirstChild("CoinEffectEvent")
		if coinEvent then
			coinEvent.OnClientEvent:Connect(function(startPos)
				self:_SpawnCoinEffect(startPos)
			end)
		else
			warn("CoinEffectEvent not found")
		end

		task.spawn(function()
			local upgradeEvent = ReplicatedStorage:WaitForChild("UpgradeNoticeEvent", 10)
			if upgradeEvent then
				upgradeEvent.OnClientEvent:Connect(function(messageType)
					if messageType == "Success" then
						self._toast:Show({
							emoji = "⬆",
							title = "LEVEL UP!",
							duration = 3,
						})
						self._infoBar:UpdateCoins(self._pds:GetCoins())
						self._infoBar:UpdatePower(self._pds:GetPower())
						self._infoBar:UpdateTrophies(self._pds:GetTrophies())
						self:_UpdateNameTag()
					elseif messageType == "NotEnough" then
						self._toast:Show({
							emoji = "❌",
							title = "Not Enough Coins",
							duration = 2,
						})
					elseif messageType == "Max Level" then
						self._toast:Show({
							emoji = "⭐",
							title = "Max Level",
							duration = 2,
						})
					elseif messageType == "WorldCupNeedTeam" then
						self._toast:Show({
							emoji = "🏆",
							title = "World Cup",
							body = "Your team needs 10 players to enter.",
							duration = 3,
						})
					elseif messageType == "WorldCupStart" then
						self._toast:Show({
							emoji = "🏆",
							title = "World Cup!",
							body = "Match started...",
							duration = 3,
						})
					elseif messageType == "WorldCupDone" then
						self._toast:Show({
							emoji = "🏆",
							title = "World Cup Champion!",
							body = "Trophy +1",
							duration = 4,
						})
						self._infoBar:UpdateTrophies(self._pds:GetTrophies())
						self._teamDone = false
						self._coreBar:SetNormalMode()
						self:_SetupTacticalBoard()
						local unlocked = self._pds:GetUnlockedNPCs()
						local offset = #unlocked + 1
						self._coreBar:SetOffset(offset)
						self._coreBar:UpdateTime(0)
						local lbCtrl = Knit.GetController("LeaderboardController")
						if lbCtrl then lbCtrl:Refresh() end
					end
				end)
			end
		end)

		self:_CreateHUD()

		task.spawn(function()
			local boardRefreshInterval = 0
			while true do
				task.wait(1)
				self._toastDelay = self._toastDelay + 1
				local totalSeconds = self._npcProgress:GetElapsedTime()
				self._coreBar:UpdateTime(totalSeconds)
				local coins = self._pds:GetCoins()
				self._infoBar:UpdateCoins(coins)
				local power = self._pds:GetPower()
				self._infoBar:UpdatePower(power)
				local trophies = self._pds:GetTrophies()
				self._infoBar:UpdateTrophies(trophies)
				local teamCompleteSec = Constants.ONLINE_TOTAL_MINUTES * 60
				if totalSeconds >= teamCompleteSec and not self._teamDone then
					self._teamDone = true
					local trophies = self._pds:GetTrophies()
					local needed = trophies + 1
					local unlocked = self._pds:GetUnlockedNPCs()
					local nextOffset = #unlocked + 1
					self._coreBar:SetWaitingMode(needed, nextOffset)
					self._toast:Show({
						emoji = "🏆",
						title = "Team Complete!",
						duration = 3,
					})
				end
				boardRefreshInterval += 1
				if boardRefreshInterval >= 5 then
					boardRefreshInterval = 0
					self:_SetupTacticalBoard()
				end
			end
		end)

		self._autoKick.OnGoalScored:Connect(function()
		end)

		ballSpawn.OnPlayerGoal:Connect(function()
			self._overlay:ShowGoal()
			--self._toast:Show({
			--	emoji = "⚽",
			--	title = "GOAL!",
			--	duration = 2,
			--})
		end)

		npcTimer.OnNPCActivated:Connect(function(slotId, npcId, duration)
			local name = getNPCName(npcId)
			self._toast:Show({
				emoji = "⏳",
				title = name,
				body = "Ready in <b>" .. tostring(duration) .. "</b>s",
				duration = 2,
				side = "left",
			})
		end)
		npcTimer.OnTimerUpdated:Connect(function(slotId, remaining)
			local sd = self._slotCountdowns[slotId]
			if sd then
				if not sd.gui or not sd.gui.Parent then
					self._slotCountdowns[slotId] = nil
					sd = nil
				else
					sd.label.Text = tostring(remaining)
					sd.label.TextColor3 = if remaining <= 5 then Color3.new(1, 0.2, 0.2) else Color3.new(1, 1, 1)
				end
			end
			if not sd then
				local model = self:_FindSlotModel(slotId)
				if model then
					local primary = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
					if primary then
						local gui = Instance.new("BillboardGui")
						gui.Name = "SlotCountdownGui"
						gui.Size = UDim2.new(0, 60, 0, 30)
						gui.StudsOffset = Vector3.new(0, 5, 0)
						gui.MaxDistance = 80
						gui.Parent = primary

						local label = Instance.new("TextLabel")
						label.Size = UDim2.new(1, 0, 1, 0)
						label.BackgroundTransparency = 1
						label.Text = tostring(remaining)
						label.TextColor3 = Color3.new(1, 1, 1)
						label.TextStrokeColor3 = Color3.new(0, 0, 0)
						label.TextStrokeTransparency = 0.3
						label.TextScaled = true
						label.Font = Enum.Font.GothamBold
						label.Parent = gui

						self._slotCountdowns[slotId] = { gui = gui, label = label }
					end
				end
			end
		end)
		npcTimer.OnTimerExpired:Connect(function(slotId, npcId)
			local sd = self._slotCountdowns[slotId]
			if sd then
				sd.gui:Destroy()
				self._slotCountdowns[slotId] = nil
			end

		end)

		self._infoBar:UpdateCoins(self._pds:GetCoins())
		self._infoBar:UpdatePower(self._pds:GetPower())
		self._infoBar:UpdateTrophies(self._pds:GetTrophies())

		task.spawn(function()
			self:_SetupTacticalBoard()
		end)

		task.defer(function()
			self:_UpdateNameTag()
		end)
	end,

	KnitInit = function(self)
		print("UIController initialized")
	end,

	_FindTacticalBoard = function(self)
		local fieldName = Knit.GetService("FieldManagerService"):GetFieldName()
		local field = workspace:FindFirstChild(fieldName)
		if not field then return nil end
		local info = field:FindFirstChild("Info")
		if not info then return nil end
		local main = info:FindFirstChild("Main")
		if not main then return nil end
		local gui = main:FindFirstChild("Gui")
		if not gui then return nil end
		return gui:FindFirstChild("u_card")
	end,

	_SetupTacticalBoard = function(self)
		local cardContainer = self:_FindTacticalBoard()
		if not cardContainer then
			task.delay(1, function() self:_SetupTacticalBoard() end)
			return
		end

		local pds = self._pds
		local localPlayer = Players.LocalPlayer
		local userId = localPlayer.UserId

		local card1 = cardContainer:FindFirstChild("card_1")
		if card1 and card1:IsA("ImageButton") and card1.Image == "" then
			local bg = card1:FindFirstChild("bg")
			if bg then bg.Visible = false end
			local tname = card1:FindFirstChild("t_name")
			if tname and tname:IsA("TextLabel") then
				tname.Text = localPlayer.DisplayName
			end
			local success, url = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			end)
			if success and url ~= "" then
				card1.Image = url
			end
		end

		local unlocked = pds:GetUnlockedNPCs()
		for i, npcId in ipairs(unlocked) do
			local cardIdx = i + 1
			if cardIdx > 11 then break end
			local card = cardContainer:FindFirstChild("card_" .. tostring(cardIdx))
			if card and card:IsA("ImageButton") and card.Image == "" then
				for _, npc in ipairs(NPCData.NPCList) do
					if npc.id == npcId then
						local bg = card:FindFirstChild("bg")
						if bg then bg.Visible = false end
						local tname = card:FindFirstChild("t_name")
						if tname and tname:IsA("TextLabel") then
							tname.Text = npc.displayName
						end
						card.Image = npc.icon
						break
					end
				end
			end
		end

		-- update level info panel
		local infoPanel = cardContainer.Parent:FindFirstChild("u_info")
		if infoPanel then
			local levelInfo = pds:GetLevel()
			local config = PlayerLevels[levelInfo.level] or PlayerLevels[1]
			local tLv = infoPanel:FindFirstChild("t_lv")
			if tLv and tLv:IsA("TextLabel") then
				tLv.Text = "Level : " .. tostring(levelInfo.level)
			end
			local tMoney = infoPanel:FindFirstChild("t_money")
			if tMoney and tMoney:IsA("TextLabel") then
				tMoney.Text = "💵 " .. tostring(levelInfo.multiplier) .. "x"
			end
			local tPower = infoPanel:FindFirstChild("t_power")
			if tPower and tPower:IsA("TextLabel") then
				tPower.Text = tostring(config.power)
			end
		end
	end,

	_SpawnCoinEffect = function(self, startWorldPos)
		if not startWorldPos then return end

		local camera = Workspace.CurrentCamera
		if not camera then return end

		local viewport = camera.ViewportSize
		local screenPos = camera:WorldToViewportPoint(startWorldPos)
		local originX = if screenPos.Z > 0 then screenPos.X else viewport.X / 2
		local originY = if screenPos.Z > 0 then screenPos.Y else viewport.Y * 0.7

		local coinIcon = self._screenGui and self._screenGui:FindFirstChild("InfoBar"):FindFirstChild("CoinSegment"):FindFirstChild("Icon")
		if not coinIcon then return end

		local absPos = coinIcon.AbsolutePosition
		local absSize = coinIcon.AbsoluteSize
		if absSize.X == 0 or absSize.Y == 0 then return end

		local targetX = absPos.X + absSize.X / 2
		local targetY = absPos.Y + absSize.Y

		task.spawn(function()
			for i = 1, 8 do
				local coin = Instance.new("TextLabel")
				coin.Name = "CoinFX"
				coin.Text = "💵"
				coin.Font = Enum.Font.GothamBold
				coin.TextScaled = true
				coin.BackgroundTransparency = 1
				coin.Size = UDim2.new(0, 52, 0, 52)
				coin.ZIndex = 200
				coin.Parent = self._screenGui

				local spreadX = (math.random() - 0.5) * 60
				local spreadY = (math.random() - 0.5) * 40 - 20
				coin.Position = UDim2.new(0, originX + spreadX - 26, 0, originY + spreadY - 26)

				task.delay((i - 1) * 0.04, function()
					local tween = TweenService:Create(coin, TweenInfo.new(1.0 + math.random() * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Position = UDim2.new(0, targetX - 26, 0, targetY - 26),
						Size = UDim2.new(0, 14, 0, 14),
						TextTransparency = 1,
					})
					tween:Play()
					tween.Completed:Connect(function()
						coin:Destroy()
					end)
				end)
			end
		end)
	end,

	_CreateHUD = function(self)
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		for _ = 1, 30 do
			self._screenGui = playerGui:WaitForChild("FreeKickHUD", 1)
			if self._screenGui and self._screenGui:FindFirstChild("CoreBar") then break end
			task.wait(0.5)
		end

		self._toast = ToastView.new(self._screenGui)
		self._coreBar = CoreBarView.new(self._screenGui)
		self._infoBar = InfoBarView.new(self._screenGui)
		self._actionPanel = ActionPanelView.new(self._screenGui)
		self._overlay = OverlayView.new(self._screenGui)

		self._shopView = ShopView.new(self._screenGui)

		self._gmView = GMView.new(self._screenGui)
		if AdminData.IsAdmin(Players.LocalPlayer.UserId) then
			self._actionPanel:ShowGM(true)
		end

		self._actionPanel:SetShopCallback(function()
			self._shopView._activeTab = "Products"
			self._shopView:Open()
		end)

		self._actionPanel:SetLeaderboardCallback(function()
			local leaderboardModel = workspace:FindFirstChild("Leaderboard")
			if leaderboardModel then
				local cf = leaderboardModel:GetPrimaryPartCFrame()
				if cf then
					local char = Players.LocalPlayer.Character
					if char then
						local root = char:FindFirstChild("HumanoidRootPart")
						if root then
							local look = cf.LookVector
							root.CFrame = CFrame.lookAt(
								cf.Position + look * 8,
								cf.Position
							)
						end
					end
				end
			end
		end)

		self._actionPanel:SetRebirthCallback(function()
			self._toast:Show({
				emoji = "🔄",
				title = "Rebirth",
				body = "Coming soon...",
				duration = 2,
			})
		end)

		self._actionPanel:SetPitchCallback(function()
			local fieldMgr = Knit.GetService("FieldManagerService")
			local pos = fieldMgr:GetGroundPosition()
			if pos then
				local char = Players.LocalPlayer.Character
				if char then
					local root = char:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = CFrame.new(pos.X, pos.Y + 5, pos.Z)
					end
				end
			end
		end)

		self._actionPanel:SetGMCallback(function()
			self._gmView:Open()
		end)

		for i = 1, Constants.ACTIVE_NPC_COUNT do
			self._coreBar:LoadNPCHead(i)
		end

		local unlocked = self._pds:GetUnlockedNPCs()
		self._coreBar:SetOffset(#unlocked + 1)

	end,
})

return UIController
