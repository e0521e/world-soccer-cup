local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

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
            self:_SetupLevelUpZone(field, player)
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

    _SetupLevelUpZone = function(self, field, player)
        local zone = field:FindFirstChild("Zone_LevelUp")
        if not zone then print("Zone_LevelUp not found in", field.Name); return end

        print("Zone_LevelUp found in", field.Name, "for", player.Name)

        local pds = Knit.GetService("PlayerDataService")

        task.spawn(function()
            local levelInfo
            for _ = 1, 20 do
                levelInfo = pds:GetLevel(player)
                if levelInfo.loaded then break end
                task.wait(0.5)
            end
            print("Level info for", player.Name, ":", levelInfo.level, levelInfo.nextCost)
            local info = zone:FindFirstChild("info")
            if info then
                local gui = info:FindFirstChild("Gui")
                if gui then
                    local tPrice = gui:FindFirstChild("t_price")
                    if tPrice and tPrice:IsA("TextLabel") then
                        tPrice.Text = "💵" .. tostring(levelInfo.nextCost)
                        print("t_price set to", tPrice.Text)
                    else
                        print("t_price not found")
                    end
                else
                    print("Gui not found in info")
                end
            else
                print("info not found in Zone_LevelUp")
            end
        end)

        local mainPart = zone:FindFirstChild("touch")
        if not mainPart or not mainPart:IsA("BasePart") then print("No touch part in Zone_LevelUp"); return end

        print("Touch connected on", mainPart.Name)

        local cd = false
        mainPart.Touched:Connect(function(hit)
            if cd then return end
            if hit.Name ~= "HumanoidRootPart" then return end
            local char = hit.Parent
            local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
            if not humanoid then return end
            local touchingPlayer = Players:GetPlayerFromCharacter(char)
            if not touchingPlayer or touchingPlayer ~= player then return end

            cd = true
            task.delay(3, function() cd = false end)

            local levelInfo = pds:GetLevel(player)
            local nextConfig = require(game:GetService("ReplicatedStorage").Shared.configs.PlayerLevels)[levelInfo.level + 1]
            if not nextConfig then
                self:_NotifyPlayer(player, "Max Level")
                return
            end

            local coins = pds:GetCoins(player)
            if coins < nextConfig.cost then
                self:_NotifyPlayer(player, "NotEnough")
                return
            end

            local success = pds:UpgradeLevel(player)
            if success then
                self:_NotifyPlayer(player, "Success")
                self:_PlayUpgradeEffect(mainPart)
                local newLevelInfo = pds:GetLevel(player)
                local info = zone:FindFirstChild("info")
                if info then
                    local gui = info:FindFirstChild("Gui")
                    if gui then
                        local tPrice = gui:FindFirstChild("t_price")
                        if tPrice and tPrice:IsA("TextLabel") then
                            tPrice.Text = "💵" .. tostring(newLevelInfo.nextCost)
                        end
                    end
                end
            end
        end)
    end,

    _NotifyPlayer = function(self, player, messageType)
        local event = game:GetService("ReplicatedStorage"):FindFirstChild("UpgradeNoticeEvent")
        if event then
            event:FireClient(player, messageType)
        end
    end,

    _PlayUpgradeEffect = function(self, part)
        local attachment = Instance.new("Attachment")
        attachment.Parent = part

        local emitter = Instance.new("ParticleEmitter")
        emitter.Parent = attachment
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0.5)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.8, 0)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 0.4, 0)),
        })
        emitter.Lifetime = NumberRange.new(1.5, 3)
        emitter.Rate = 60
        emitter.SpreadAngle = Vector2.new(0, 360)
        emitter.Speed = NumberRange.new(5, 12)
        emitter.Acceleration = Vector3.new(0, -3, 0)
        emitter.Enabled = true

        local beamAttach = Instance.new("Attachment")
        beamAttach.Name = "BeamAttach"
        beamAttach.Position = Vector3.new(0, 3, 0)
        beamAttach.Parent = part

        local beam = Instance.new("Beam")
        beam.Parent = part
        beam.Attachment0 = attachment
        beam.Attachment1 = beamAttach
        beam.Color = ColorSequence.new(Color3.new(1, 0.9, 0.1))
        beam.LightEmission = 1
        beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        beam.TextureLength = 2
        beam.TextureSpeed = 1
        beam.Transparency = NumberSequence.new(0.3)
        beam.Width0 = 2
        beam.Width1 = 0.5

        task.delay(3, function()
            emitter.Enabled = false
            task.delay(2, function()
                emitter:Destroy()
                attachment:Destroy()
                beam:Destroy()
                beamAttach:Destroy()
            end)
        end)
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
        local upgradeEvent = Instance.new("RemoteEvent")
        upgradeEvent.Name = "UpgradeNoticeEvent"
        upgradeEvent.Parent = game:GetService("ReplicatedStorage")

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
