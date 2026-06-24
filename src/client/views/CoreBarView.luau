local Constants = require(game:GetService("ReplicatedStorage").Shared.constants.Constants)
local NPCData = require(game:GetService("ReplicatedStorage").Shared.configs.NPCData)

local TOTAL_DOTS = Constants.ACTIVE_NPC_COUNT
local UNLOCK_SLOTS = TOTAL_DOTS
local NPC_UNLOCK_INTERVAL = math.floor(Constants.ONLINE_TOTAL_MINUTES * 60 / UNLOCK_SLOTS)
local TOTAL_DURATION = Constants.ONLINE_TOTAL_MINUTES * 60

local CoreBarView = {}
CoreBarView.__index = CoreBarView

function CoreBarView.new(screenGui: Instance)
	local self = setmetatable({}, CoreBarView)
	self._dots = {}
	self._waitingMode = false

	local bar = screenGui:FindFirstChild("CoreBar")
	if not bar then return self end

	self._bar = bar
	self._timeLabel = bar:FindFirstChild("TimerLabel")
	if not self._timeLabel then
		self._timeLabel = bar:WaitForChild("TimerLabel", 3)
	end

	local trackBg = bar:FindFirstChild("TrackBg")
	self._trackFill = trackBg and trackBg:FindFirstChild("TrackFill")

	for i = 1, TOTAL_DOTS do
		local dotFrame = bar:FindFirstChild("Dot_" .. tostring(i))
		if dotFrame then
			local vpf = dotFrame:FindFirstChild("VPF")
			self._dots[i] = {
				dot = dotFrame,
				stroke = dotFrame:FindFirstChild("Stroke"),
				vpf = vpf,
				worldModel = vpf and vpf:FindFirstChild("NPCHead"),
				name = dotFrame:FindFirstChild("Name"),
				vpfOverlay = vpf and vpf:FindFirstChild("Overlay"),
			}
		end
	end

	return self
end

function CoreBarView:LoadNPCHead(index: number)
	local entry = self._dots[index]
	if not entry then return end
	if not entry.worldModel then return end
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
		local cam = entry.vpf.CurrentCamera or entry.vpf:FindFirstChild("HeadCam")
		if not cam then
			cam = Instance.new("Camera")
			cam.Name = "HeadCam"
			cam.Parent = entry.vpf
			entry.vpf.CurrentCamera = cam
		end
		cam.FieldOfView = Constants.HEAD_CAM_FOV
		cam.CFrame = CFrame.new(cameraPos.Position, headPos)
	end
end

function CoreBarView:SetWaitingMode(neededTrophies: number, nextBatchOffset: number)
	self._waitingMode = true
	if not self._timeLabel then return end
	local label = "Need to win " .. tostring(neededTrophies) .. " World Cup"
	if neededTrophies > 1 then label = label .. "s" end
	self._timeLabel.Text = label
	self._timeLabel.TextSize = 14
	self._timeLabel.TextXAlignment = Enum.TextXAlignment.Center

	if self._trackFill then
		self._trackFill.Size = UDim2.new(1, 0, 1, 0)
	end

	for i = 1, TOTAL_DOTS do
		local entry = self._dots[i]
		if not entry then continue end
		if entry.vpfOverlay then entry.vpfOverlay.BackgroundTransparency = 1 end
		entry.dot.BackgroundColor3 = Color3.new(0.2, 0.2, 0.35)
		entry.dot.BackgroundTransparency = 0.1
		if entry.stroke then
			entry.stroke.Color = Color3.new(1, 0.85, 0.1)
			entry.stroke.Transparency = 0
			entry.stroke.Thickness = 2
		end
		if entry.vpf then
			entry.vpf.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
			entry.vpf.BackgroundTransparency = 0.1
		end
		if entry.name then
			entry.name.TextTransparency = 0
			entry.name.TextColor3 = Color3.new(1, 1, 1)
		end
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
	if not self._timeLabel then return end
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	self._timeLabel.Text = string.format("%02d:%02d", minutes, seconds)

	local filledDots = math.min(math.floor(totalSeconds / NPC_UNLOCK_INTERVAL), TOTAL_DOTS)

	local fillRatio = math.min(totalSeconds / TOTAL_DURATION, 1)
	if self._trackFill then
		self._trackFill.Size = UDim2.new(fillRatio, 0, 1, 0)
	end

	for i = 1, TOTAL_DOTS do
		local entry = self._dots[i]
		if not entry then continue end
		local isFilled = i <= filledDots
		local isActive = i == filledDots + 1 and filledDots < TOTAL_DOTS

		if isFilled then
			if entry.vpfOverlay then entry.vpfOverlay.BackgroundTransparency = 1 end
			entry.dot.BackgroundColor3 = Color3.new(0.2, 0.2, 0.35)
			entry.dot.BackgroundTransparency = 0.1
			if entry.stroke then
				entry.stroke.Color = Color3.new(1, 0.85, 0.1)
				entry.stroke.Transparency = 0
				entry.stroke.Thickness = 2
			end
			if entry.vpf then
				entry.vpf.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
				entry.vpf.BackgroundTransparency = 0.1
			end
			if entry.name then
				entry.name.TextTransparency = 0
				entry.name.TextColor3 = Color3.new(1, 1, 1)
			end
		elseif isActive then
			if entry.vpfOverlay then entry.vpfOverlay.BackgroundTransparency = 0.4 end
			entry.dot.BackgroundColor3 = Color3.new(0.18, 0.18, 0.28)
			entry.dot.BackgroundTransparency = 0.2
			if entry.stroke then
				entry.stroke.Color = Color3.new(0.6, 0.6, 0.8)
				entry.stroke.Transparency = 0.2
				entry.stroke.Thickness = 2
			end
			if entry.vpf then
				entry.vpf.BackgroundColor3 = Color3.new(0.08, 0.08, 0.13)
				entry.vpf.BackgroundTransparency = 0.15
			end
			if entry.name then
				entry.name.TextTransparency = 0.3
				entry.name.TextColor3 = Color3.new(0.8, 0.8, 1)
			end
		else
			if entry.vpfOverlay then entry.vpfOverlay.BackgroundTransparency = 0.55 end
			entry.dot.BackgroundColor3 = Color3.new(0.15, 0.15, 0.22)
			entry.dot.BackgroundTransparency = 0.5
			if entry.stroke then
				entry.stroke.Color = Color3.new(0.35, 0.35, 0.45)
				entry.stroke.Transparency = 0.5
				entry.stroke.Thickness = 1.5
			end
			if entry.vpf then
				entry.vpf.BackgroundColor3 = Color3.new(0.08, 0.08, 0.12)
				entry.vpf.BackgroundTransparency = 0.3
			end
			if entry.name then
				entry.name.TextTransparency = 0.6
				entry.name.TextColor3 = Color3.new(0.5, 0.5, 0.6)
			end
		end
	end
end

return CoreBarView
