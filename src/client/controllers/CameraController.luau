--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local CameraController = Knit.CreateController({
    Name = "CameraController",

    _camera = nil,

    KnitStart = function(self)
        self._camera = Workspace.CurrentCamera
        local AutoKickService = Knit.GetService("AutoKickService")

        if AutoKickService then
            AutoKickService.OnKickAnimation:Connect(function(player, slotId)
                if player ~= Players.LocalPlayer then return end
                self:_ZoomToKick()
            end)

            AutoKickService.OnBallFlying:Connect(function(player, slotId, startPos, targetPos)
                if player ~= Players.LocalPlayer then return end
                self:_FollowBall(startPos, targetPos)
            end)

            AutoKickService.OnGoalScored:Connect(function(player, slotId, npcId)
                if player ~= Players.LocalPlayer then return end
                self:_GoalReplay()
            end)
        end
    end,

    _FocusOnAction = function(self, targetPos)
        if not self._camera then return end
        self._camera.CameraType = Enum.CameraType.Scriptable

        local npcPos = targetPos - Vector3.new(0, 0, 10)
        local focus = CFrame.lookAt(npcPos, targetPos)
        local tween = TweenService:Create(self._camera, TweenInfo.new(0.5), {
            CFrame = focus,
        })
        tween:Play()
    end,

    _ZoomToKick = function(self)
        if not self._camera then return end
        local character = Players.LocalPlayer.Character
        if not character then return end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local camPos = root.Position + Vector3.new(5, 3, -5)
        local focus = CFrame.lookAt(camPos, root.Position)
        local tween = TweenService:Create(self._camera, TweenInfo.new(0.3), {
            CFrame = focus,
        })
        tween:Play()
    end,

    _FollowBall = function(self, startPos, targetPos)
        if not self._camera then return end

        local midPoint = (startPos + targetPos) / 2
        local camPos = midPoint + Vector3.new(-10, 15, 0)
        local focus = CFrame.lookAt(camPos, midPoint)
        local tween = TweenService:Create(self._camera, TweenInfo.new(1.2), {
            CFrame = focus,
        })
        tween:Play()
    end,

    _GoalReplay = function(self)
        if not self._camera then return end

		local fieldMgr = Knit.GetService("FieldManagerService")
		local goal = fieldMgr:GetField(Players.LocalPlayer)
        if goal then
            goal = goal:FindFirstChild("_door")
        end
        if not goal then return end

        local goalChk = goal:FindFirstChild("goal_chk")
        if not goalChk then return end

        local camPos = goalChk.Position + Vector3.new(-15, 10, 0)
        local focus = CFrame.lookAt(camPos, goalChk.Position)
        local tween = TweenService:Create(self._camera, TweenInfo.new(1), {
            CFrame = focus,
        })
        tween:Play()

        -- Reset camera after replay
        tween.Completed:Connect(function()
            task.wait(1)
            self:_ResetCamera()
        end)
    end,

    _ResetCamera = function(self)
        if not self._camera then return end
        self._camera.CameraType = Enum.CameraType.Custom
    end,

    KnitInit = function(self)
        print("CameraController initialized")
    end,
})

return CameraController
