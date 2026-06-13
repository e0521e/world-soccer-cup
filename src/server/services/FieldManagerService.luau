--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")

local MAX_FIELDS = 6
local ROW_Z = { -112, 0, 112 }
local ROW_A_X = -10
local ROW_B_X = 10

local FieldManagerService = Knit.CreateService({
    Name = "FieldManagerService",

    Client = {
        GetFieldName = function(self, player)
            return self.Server:GetFieldName(player)
        end,
    },

    _playerFields = {},
    _freeFields = {},

    GetField = function(self, player)
        return self._playerFields[player]
    end,

    GetFieldName = function(self, player)
        local field = self._playerFields[player]
        return field and field.Name or "none"
    end,

    _AssignField = function(self, player)
        if #self._freeFields > 0 then
            local field = table.remove(self._freeFields)
            self._playerFields[player] = field
            self:_UpdatePlayerGuis(field, player)
            print("FieldManagerService: assigned " .. field.Name .. " to " .. player.Name)
            return field
        end
        return nil
    end,

    _ReleaseField = function(self, player)
        local field = self._playerFields[player]
        if field then
            self:_ClearPlayerGuis(field)
            table.insert(self._freeFields, field)
            self._playerFields[player] = nil
            for _, ball in ipairs(field:GetChildren()) do
                if ball.Name:find("FieldBall") then ball:Destroy() end
            end
            print("FieldManagerService: released " .. field.Name .. " from " .. player.Name)
        end
    end,

    _UpdatePlayerGuis = function(self, field, player)
        local guis = {}
        for _, child in ipairs(field:GetDescendants()) do
            if child:IsA("BillboardGui") and child.Name == "FieldOwnerGui" then
                table.insert(guis, child)
            end
        end
        if #guis == 0 then return end

        local userId = player.UserId
        local success, content = pcall(function()
            return game:GetService("Players"):GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        local avatarUrl = success and content or ""

        for _, gui in ipairs(guis) do
            local avatar = gui:FindFirstChild("Avatar")
            if avatar and avatar:IsA("ImageLabel") then
                if avatarUrl ~= "" then
                    avatar.Image = avatarUrl
                end
            end
            local nameLabel = gui:FindFirstChild("PlayerName")
            if nameLabel and nameLabel:IsA("TextLabel") then
                nameLabel.Text = player.DisplayName
            end
            gui.Enabled = true
        end
    end,

    _ClearPlayerGuis = function(self, field)
        for _, child in ipairs(field:GetDescendants()) do
            if child:IsA("BillboardGui") and child.Name == "FieldOwnerGui" then
                child.Enabled = false
                local avatar = child:FindFirstChild("Avatar")
                if avatar and avatar:IsA("ImageLabel") then
                    avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                end
                local nameLabel = child:FindFirstChild("PlayerName")
                if nameLabel and nameLabel:IsA("TextLabel") then
                    nameLabel.Text = ""
                end
            end
        end
    end,

    _MirrorField = function(self, fieldModel, xOffset, zOffset)
        local firstPart = nil
        for _, part in ipairs(fieldModel:GetDescendants()) do
            if part:IsA("BasePart") then firstPart = part break end
        end
        if not firstPart then return end

        fieldModel.PrimaryPart = firstPart
        local cf = firstPart.CFrame
        local targetPos = Vector3.new(-cf.Position.X + xOffset, cf.Position.Y, -cf.Position.Z + zOffset)
        fieldModel:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, math.pi, 0))
        fieldModel.PrimaryPart = nil
    end,

    KnitInit = function(self)
        print("FieldManagerService initialized")
    end,

    KnitStart = function(self)
        local fieldFolder = workspace:FindFirstChild("Field_1")
        if fieldFolder then
            local existing = ServerStorage:FindFirstChild("FieldTemplate")
            if existing then existing:Destroy() end

            local model = Instance.new("Model")
            model.Name = "FieldTemplate"
            for _, child in ipairs(fieldFolder:GetChildren()) do
                child.Parent = model
            end
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    model.PrimaryPart = part
                    break
                end
            end
            model.Parent = ServerStorage
            fieldFolder:Destroy()
            print("FieldManagerService: converted Field_1 to Model FieldTemplate")
        end

        template = ServerStorage:FindFirstChild("FieldTemplate")
        if template and template:IsA("Folder") then
            local model = Instance.new("Model")
            model.Name = "FieldTemplate"
            for _, child in ipairs(template:GetChildren()) do
                child.Parent = model
            end
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    model.PrimaryPart = part
                    break
                end
            end
            model.Parent = ServerStorage
            template:Destroy()
            template = model
            print("FieldManagerService: converted ServerStorage.FieldTemplate to Model")
        end
        if not template then
            warn("FieldManagerService: no FieldTemplate found")
            return
        end

        local fieldIdx = 0
        for _, zOffset in ipairs(ROW_Z) do
            fieldIdx += 1
            local field = Instance.new("Model")
            field.Name = "Field_" .. tostring(fieldIdx)
            for _, child in ipairs(template:GetChildren()) do
                local c = child:Clone()
                c.Parent = field
            end
            field.Parent = workspace
            for _, part in ipairs(field:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Position = part.Position + Vector3.new(ROW_A_X, 0, zOffset)
                end
            end
            field:SetAttribute("CenterX", ROW_A_X)
            field:SetAttribute("CenterZ", zOffset)
            field:SetAttribute("Mirrored", false)
            table.insert(self._freeFields, field)
            print("FieldManagerService: created " .. field.Name .. " at X=" .. tostring(ROW_A_X) .. " Z=" .. tostring(zOffset))
        end

        for _, zOffset in ipairs(ROW_Z) do
            fieldIdx += 1
            local field = Instance.new("Model")
            field.Name = "Field_" .. tostring(fieldIdx)
            for _, child in ipairs(template:GetChildren()) do
                local c = child:Clone()
                c.Parent = field
            end
            self:_MirrorField(field, ROW_B_X, zOffset)
            field.Parent = workspace
            field:SetAttribute("CenterX", ROW_B_X)
            field:SetAttribute("CenterZ", zOffset)
            field:SetAttribute("Mirrored", true)
            table.insert(self._freeFields, field)
            print("FieldManagerService: created " .. field.Name .. " at X=" .. tostring(ROW_B_X) .. " Z=" .. tostring(zOffset) .. " (mirrored)")
        end

        game:GetService("Players").PlayerAdded:Connect(function(player)
            local field = self:_AssignField(player)
            if not field then player:Kick("No fields available") end
        end)

        game:GetService("Players").PlayerRemoving:Connect(function(player)
            self:_ReleaseField(player)
        end)

        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            local field = self:_AssignField(player)
            if not field then player:Kick("No fields available") end
        end

        print("FieldManagerService started")
    end,
})

return FieldManagerService
