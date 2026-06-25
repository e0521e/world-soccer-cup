--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Workspace = game:GetService("Workspace")

local CameraController = Knit.CreateController({
    Name = "CameraController",

    _camera = nil,

    KnitStart = function(self)
        self._camera = Workspace.CurrentCamera
    end,

    KnitInit = function(self)
        print("CameraController initialized")
    end,
})

return CameraController
