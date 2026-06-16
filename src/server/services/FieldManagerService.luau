--!strict

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")

local MAX_FIELDS = 6

local FieldManagerService = Knit.CreateService({
    Name = "FieldManagerService",

    Client = {
        GetFieldName = function(self, player)
            return self.Server:GetFieldName(player)
        end,

        GetGroundPosition = function(self, player)
            return self.Server:GetGroundPosition(player)
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

    GetGroundPosition = function(self, player)
        local field = self._playerFields[player]
        if field then
            local ground = field:FindFirstChild("Ground")
            if ground then
                return ground.Position
            end
        end
        return nil
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


    KnitInit = function(self)
        print("FieldManagerService initialized")
    end,

    KnitStart = function(self)
        local template = workspace:FindFirstChild("Field_1")
        if template then
            local existing = ServerStorage:FindFirstChild("FieldTemplate")
            if existing then existing:Destroy() end
            template.Name = "FieldTemplate"
            template.Parent = ServerStorage
            print("FieldManagerService: moved Field_1 to ServerStorage as FieldTemplate")
        else
            template = ServerStorage:FindFirstChild("FieldTemplate")
        end
        if not template then
            warn("FieldManagerService: no FieldTemplate found")
            return
        end

        local fieldIdx = 0
        for i = 0, 5 do
            fieldIdx += 1
            local rad = math.rad(i * 60)

            local field = template:Clone()
            field.Name = "Field_" .. tostring(fieldIdx)
            field.Parent = workspace

            local primary = field.PrimaryPart
            if primary then
                field:PivotTo(
                    primary.CFrame * CFrame.Angles(0, rad, 0)
                )
            end

            field:SetAttribute("Angle", i * 60)
            table.insert(self._freeFields, field)
            print("FieldManagerService: created " .. field.Name .. " rotated " .. tostring(i * 60) .. " deg")
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
