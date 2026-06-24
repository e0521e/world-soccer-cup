local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)

local TOTAL_DOTS = Constants.ACTIVE_NPC_COUNT
local UNLOCK_SLOTS = TOTAL_DOTS
local NPC_UNLOCK_INTERVAL = math.floor(Constants.ONLINE_TOTAL_MINUTES * 60 / UNLOCK_SLOTS)
local TOTAL_DURATION = Constants.ONLINE_TOTAL_MINUTES * 60

local BAR_HEIGHT_SCALE = 0.1
local TRACK_WIDTH_SCALE = 0.82
local DOT_SIZE_SCALE = 0.055
local DOT_Y_SCALE = 0.5
local TRACK_Y_SCALE = 0.88
local TRACK_HEIGHT_SCALE = 0.12
local DOT_GAP_SCALE = TRACK_WIDTH_SCALE / (TOTAL_DOTS - 1)
local TRACK_LEFT_SCALE = (1 - TRACK_WIDTH_SCALE) / 2

local CoreBarView = {}
CoreBarView.__index = CoreBarView

function CoreBarView.new(screenGui: Instance)
	local self = setmetatable({}, CoreBarView)

	local bar = Instance.new("Frame")
	bar.Name = "CoreBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Size = UDim2.new(0.8, 0, BAR_HEIGHT_SCALE, 0)
	bar.Position = UDim2.new(0.5, 0, 1, 0)
	bar.BackgroundColor3 = Color3.new(0.04, 0.04, 0.1)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = screenGui

	local barGradient = Instance.new("UIGradient")
	barGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.08, 0.08, 0.18)),
		ColorSequenceKeypoint.new(1, Color3.new(0.03, 0.03, 0.08)),
	})
	barGradient.Rotation = 90
	barGradient.Parent = bar

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 12)
	barCorner.Parent = bar

	local barStroke = Instance.new("UIStroke")
	barStroke.Color = Color3.new(0.3, 0.3, 0.6)
	barStroke.Thickness = 1
	barStroke.Transparency = 0.5
	barStroke.Parent = bar

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimerLabel"
	timeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	timeLabel.Size = UDim2.new(0.22, 0, 0.15, 0)
	timeLabel.Position = UDim2.new(0.5, 0, 0.56, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.new(1, 1, 1)
	timeLabel.TextStrokeTransparency = 0.15
	timeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.ZIndex = 10
	timeLabel.TextXAlignment = Enum.TextXAlignment.Center
	timeLabel.Text = "00:00"
	timeLabel.Parent = bar

	local trackBg = Instance.new("Frame")
	trackBg.Name = "TrackBg"
	trackBg.AnchorPoint = Vector2.new(0.5, 0.5)
	trackBg.Size = UDim2.new(TRACK_WIDTH_SCALE, 0, TRACK_HEIGHT_SCALE, 0)
	trackBg.Position = UDim2.new(0.5, 0, TRACK_Y_SCALE, 0)
	trackBg.BackgroundColor3 = Color3.new(0.12, 0.12, 0.2)
	trackBg.BackgroundTransparency = 0.15
	trackBg.BorderSizePixel = 0
	trackBg.ZIndex = 5
	trackBg.Parent = bar

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = trackBg

	local trackFill = Instance.new("Frame")
	trackFill.Name = "TrackFill"
	trackFill.Size = UDim2.new(0, 0, 1, 0)
	trackFill.AnchorPoint = Vector2.new(0, 0)
	trackFill.Position = UDim2.new(0, 0, 0, 0)
	trackFill.BackgroundColor3 = Color3.new(1, 0.85, 0.1)
	trackFill.BorderSizePixel = 0
	trackFill.ZIndex = 6
	trackFill.Parent = trackBg

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.15, 0.9, 0.3)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.85, 0.1)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 0.5, 0.05)),
	})
	fillGradient.Rotation = 0
	fillGradient.Parent = trackFill

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = trackFill

	self._bar = bar
	self._timeLabel = timeLabel
	self._trackFill = trackFill
	self._dots = {}
	self._waitingMode = false

	for i = 1, TOTAL_DOTS do
		local centerX = TRACK_LEFT_SCALE + DOT_GAP_SCALE * (i - 1)

		local dotFrame = Instance.new("Frame")
		dotFrame.Name = "Dot_" .. tostring(i)
		dotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		dotFrame.Size = UDim2.new(DOT_SIZE_SCALE, 0, 0.42, 0)
		dotFrame.Position = UDim2.new(centerX, 0, DOT_Y_SCALE, 0)
		dotFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.22)
		dotFrame.BackgroundTransparency = 0.5
		dotFrame.BorderSizePixel = 0
		dotFrame.ZIndex = 7
		dotFrame.Parent = bar

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0, 10)
		dotCorner.Parent = dotFrame

		local dotStroke = Instance.new("UIStroke")
		dotStroke.Color = Color3.new(0.4, 0.4, 0.5)
		dotStroke.Thickness = 1.5
		dotStroke.Transparency = 0.5
		dotStroke.Parent = dotFrame

		local vpf = Instance.new("ViewportFrame")
		vpf.Name = "VPF"
		vpf.Size = UDim2.new(1, -6, 1, -6)
		vpf.Position = UDim2.new(0, 3, 0, 3)
		vpf.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
		vpf.BackgroundTransparency = 0.2
		vpf.BorderSizePixel = 0
		vpf.ZIndex = 8
		vpf.Parent = dotFrame

		local vpfCorner = Instance.new("UICorner")
		vpfCorner.CornerRadius = UDim.new(0, 8)
		vpfCorner.Parent = vpf

		local worldModel = Instance.new("WorldModel")
		worldModel.Name = "NPCHead"
		worldModel.Parent = vpf

		local cam = Instance.new("Camera")
		cam.Name = "HeadCam"
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.5, -3.5), Vector3.new(0, 1.5, 0))
		cam.FieldOfView = 30
		cam.Parent = vpf
		vpf.CurrentCamera = cam

		local vpfOverlay = Instance.new("Frame")
		vpfOverlay.Name = "Overlay"
		vpfOverlay.Size = UDim2.new(1, 0, 1, 0)
		vpfOverlay.Position = UDim2.new(0, 0, 0, 0)
		vpfOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		vpfOverlay.BackgroundTransparency = 0.55
		vpfOverlay.BorderSizePixel = 0
		vpfOverlay.ZIndex = 9
		vpfOverlay.Parent = vpf

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.AnchorPoint = Vector2.new(0.5, 1)
		nameLabel.Size = UDim2.new(0.075, 0, 0.11, 0)
		nameLabel.Position = UDim2.new(centerX, 0, 0.05, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.new(0.5, 0.5, 0.6)
		nameLabel.TextSize = 10
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Text = if i <= #NPCData.NPCList then NPCData.NPCList[i].displayName else "NPC " .. i
		nameLabel.TextTransparency = 0.6
		nameLabel.Parent = dotFrame

		self._dots[i] = {
			dot = dotFrame,
			stroke = dotStroke,
			vpf = vpf,
			worldModel = worldModel,
			name = nameLabel,
			vpfOverlay = vpfOverlay,
		}
	end

	return self
end

function CoreBarView:LoadNPCHead(index: number)
	local entry = self._dots[index]
	if not entry then return end
	if #entry.worldModel:GetChildren() > 0 then return end

	local npcName = NPCData.NPCList[index].displayName
	local npcHeads = game:GetService("ReplicatedStorage"):FindFirstChild("NPCHeads")
	if not npcHeads then return end
	local model = npcHeads:FindFirstChild(npcName)
	if not model then return end

	local clone = model:Clone()
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	clone:PivotTo(CFrame.new(0, 0, 0))
	clone.Parent = entry.worldModel

	local head = clone:FindFirstChild("Head")
	if head then
		local headPos = head.Position
		local distance = 3.5
		local cameraPos = head.CFrame * CFrame.new(0, 0, -distance)
		entry.vpf.CurrentCamera.CFrame = CFrame.new(cameraPos.Position, headPos)
	end
end

function CoreBarView:SetWaitingMode(neededTrophies: number, nextBatchOffset: number)
	self._waitingMode = true
	local label = "Need to win " .. tostring(neededTrophies) .. " World Cup"
	if neededTrophies > 1 then label = label .. "s" end
	self._timeLabel.Text = label
	self._timeLabel.TextSize = 14
	self._timeLabel.TextXAlignment = Enum.TextXAlignment.Center

	self._trackFill.Size = UDim2.new(1, 0, 1, 0)

	for i = 1, TOTAL_DOTS do
		local entry = self._dots[i]
		if not entry then continue end
		entry.vpfOverlay.BackgroundTransparency = 1
		entry.dot.BackgroundColor3 = Color3.new(0.2, 0.2, 0.35)
		entry.dot.BackgroundTransparency = 0.1
		entry.stroke.Color = Color3.new(1, 0.85, 0.1)
		entry.stroke.Transparency = 0
		entry.stroke.Thickness = 2
		entry.vpf.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
		entry.vpf.BackgroundTransparency = 0.1
		entry.name.TextTransparency = 0
		entry.name.TextColor3 = Color3.new(1, 1, 1)
	end

	if nextBatchOffset then
		self:SetOffset(nextBatchOffset)
	end
end

function CoreBarView:SetNormalMode()
	self._waitingMode = false
	self._timeLabel.TextSize = 18
end

function CoreBarView:SetOffset(offset: number)
	local effectiveOffset = math.max(1, offset)
	for i = 1, TOTAL_DOTS do
		local entry = self._dots[i]
		if not entry then continue end
		local npcIdx = effectiveOffset + i - 1
		local npcData = NPCData.NPCList[npcIdx]
		if npcData then
			entry.name.Text = npcData.displayName
		end
	end
end

function CoreBarView:UpdateTime(totalSeconds: number)
	if self._waitingMode then return end
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	self._timeLabel.Text = string.format("%02d:%02d", minutes, seconds)

	local filledDots = math.min(math.floor(totalSeconds / NPC_UNLOCK_INTERVAL), TOTAL_DOTS)

	local fillRatio = math.min(totalSeconds / TOTAL_DURATION, 1)
	self._trackFill.Size = UDim2.new(fillRatio, 0, 1, 0)

	for i = 1, TOTAL_DOTS do
		local entry = self._dots[i]
		if not entry then continue end
		local isFilled = i <= filledDots
		local isActive = i == filledDots + 1 and filledDots < TOTAL_DOTS

		if isFilled then
			entry.vpfOverlay.BackgroundTransparency = 1
			entry.dot.BackgroundColor3 = Color3.new(0.2, 0.2, 0.35)
			entry.dot.BackgroundTransparency = 0.1
			entry.stroke.Color = Color3.new(1, 0.85, 0.1)
			entry.stroke.Transparency = 0
			entry.stroke.Thickness = 2
			entry.vpf.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
			entry.vpf.BackgroundTransparency = 0.1
			entry.name.TextTransparency = 0
			entry.name.TextColor3 = Color3.new(1, 1, 1)
		elseif isActive then
			entry.vpfOverlay.BackgroundTransparency = 0.4
			entry.dot.BackgroundColor3 = Color3.new(0.18, 0.18, 0.28)
			entry.dot.BackgroundTransparency = 0.2
			entry.stroke.Color = Color3.new(0.6, 0.6, 0.8)
			entry.stroke.Transparency = 0.2
			entry.stroke.Thickness = 2
			entry.vpf.BackgroundColor3 = Color3.new(0.08, 0.08, 0.13)
			entry.vpf.BackgroundTransparency = 0.15
			entry.name.TextTransparency = 0.3
			entry.name.TextColor3 = Color3.new(0.8, 0.8, 1)
		else
			entry.vpfOverlay.BackgroundTransparency = 0.55
			entry.dot.BackgroundColor3 = Color3.new(0.15, 0.15, 0.22)
			entry.dot.BackgroundTransparency = 0.5
			entry.stroke.Color = Color3.new(0.35, 0.35, 0.45)
			entry.stroke.Transparency = 0.5
			entry.stroke.Thickness = 1.5
			entry.vpf.BackgroundColor3 = Color3.new(0.08, 0.08, 0.12)
			entry.vpf.BackgroundTransparency = 0.3
			entry.name.TextTransparency = 0.6
			entry.name.TextColor3 = Color3.new(0.5, 0.5, 0.6)
		end
	end
end

return CoreBarView
