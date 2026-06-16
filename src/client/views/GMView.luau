local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local TweenService = game:GetService("TweenService")

local PANEL_WIDTH = 500
local PANEL_HEIGHT = 420

local GMView = {}
GMView.__index = GMView

function GMView.new(screenGui: Instance)
	local self = setmetatable({}, GMView)

	local overlay = Instance.new("Frame")
	overlay.Name = "GMOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.6
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 30
	overlay.Visible = false
	overlay.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "GMPanel"
	panel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	panel.Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -PANEL_HEIGHT / 2)
	panel.BackgroundColor3 = Color3.new(0.08, 0.08, 0.16)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.ZIndex = 35
	panel.Parent = overlay

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.new(0.6, 0.3, 0.3)
	panelStroke.Thickness = 1.5
	panelStroke.Transparency = 0.3
	panelStroke.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -38, 0, 8)
	closeBtn.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
	closeBtn.BackgroundTransparency = 0.3
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "X"
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 40
	closeBtn.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 200, 0, 24)
	title.Position = UDim2.new(0, 16, 0, 10)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 0.5, 0.5)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "GM Panel"
	title.ZIndex = 40
	title.Parent = panel

	local userIdLabel = Instance.new("TextLabel")
	userIdLabel.Name = "UserIdLabel"
	userIdLabel.Size = UDim2.new(0, 80, 0, 18)
	userIdLabel.Position = UDim2.new(0, 16, 0, 50)
	userIdLabel.BackgroundTransparency = 1
	userIdLabel.TextColor3 = Color3.new(0.8, 0.8, 0.9)
	userIdLabel.TextSize = 14
	userIdLabel.Font = Enum.Font.Gotham
	userIdLabel.TextXAlignment = Enum.TextXAlignment.Left
	userIdLabel.Text = "User ID:"
	userIdLabel.Parent = panel

	local userIdInput = Instance.new("TextBox")
	userIdInput.Name = "UserIdInput"
	userIdInput.Size = UDim2.new(0, 150, 0, 22)
	userIdInput.Position = UDim2.new(0, 100, 0, 48)
	userIdInput.BackgroundColor3 = Color3.new(0.12, 0.12, 0.2)
	userIdInput.TextColor3 = Color3.new(1, 1, 1)
	userIdInput.TextSize = 14
	userIdInput.Font = Enum.Font.Gotham
	userIdInput.PlaceholderText = "Enter UserId..."
	userIdInput.Text = ""
	userIdInput.BorderSizePixel = 0
	userIdInput.ZIndex = 36
	userIdInput.Parent = panel

	local viewBtn = Instance.new("TextButton")
	viewBtn.Name = "ViewBtn"
	viewBtn.Size = UDim2.new(0, 80, 0, 28)
	viewBtn.Position = UDim2.new(0, 260, 0, 46)
	viewBtn.BackgroundColor3 = Color3.new(0.15, 0.35, 0.15)
	viewBtn.BackgroundTransparency = 0.2
	viewBtn.TextColor3 = Color3.new(1, 1, 1)
	viewBtn.TextSize = 14
	viewBtn.Font = Enum.Font.GothamBold
	viewBtn.Text = "View"
	viewBtn.BorderSizePixel = 0
	viewBtn.ZIndex = 36
	viewBtn.Parent = panel

	local viewCorner = Instance.new("UICorner")
	viewCorner.CornerRadius = UDim.new(0, 6)
	viewCorner.Parent = viewBtn

	local outputLabel = Instance.new("TextLabel")
	outputLabel.Name = "Output"
	outputLabel.Size = UDim2.new(1, -32, 0, 160)
	outputLabel.Position = UDim2.new(0, 16, 0, 84)
	outputLabel.BackgroundColor3 = Color3.new(0.06, 0.06, 0.12)
	outputLabel.BackgroundTransparency = 0.2
	outputLabel.TextColor3 = Color3.new(0.8, 0.9, 0.8)
	outputLabel.TextSize = 11
	outputLabel.Font = Enum.Font.Code
	outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	outputLabel.TextYAlignment = Enum.TextYAlignment.Top
	outputLabel.TextWrapped = true
	outputLabel.Text = ""
	outputLabel.BorderSizePixel = 0
	outputLabel.ZIndex = 36
	outputLabel.Parent = panel

	local outputCorner = Instance.new("UICorner")
	outputCorner.CornerRadius = UDim.new(0, 6)
	outputCorner.Parent = outputLabel

	local jsonInput = Instance.new("TextBox")
	jsonInput.Name = "JsonInput"
	jsonInput.Size = UDim2.new(1, -32, 0, 80)
	jsonInput.Position = UDim2.new(0, 16, 0, 256)
	jsonInput.BackgroundColor3 = Color3.new(0.95, 0.95, 0.95)
	jsonInput.TextColor3 = Color3.new(0.1, 0.1, 0.1)
	jsonInput.TextSize = 13
	jsonInput.Font = Enum.Font.Code
	jsonInput.PlaceholderText = [[{"Coins": 9999, "Level": 5}]]
	jsonInput.Text = ""
	jsonInput.TextXAlignment = Enum.TextXAlignment.Left
	jsonInput.TextYAlignment = Enum.TextYAlignment.Top
	jsonInput.ClearTextOnFocus = false
	jsonInput.MultiLine = true
	jsonInput.BorderSizePixel = 0
	jsonInput.ZIndex = 36
	jsonInput.Parent = panel

	local jsonCorner = Instance.new("UICorner")
	jsonCorner.CornerRadius = UDim.new(0, 6)
	jsonCorner.Parent = jsonInput

	local applyBtn = Instance.new("TextButton")
	applyBtn.Name = "ApplyBtn"
	applyBtn.Size = UDim2.new(0, 80, 0, 28)
	applyBtn.Position = UDim2.new(1, -96, 0, 344)
	applyBtn.BackgroundColor3 = Color3.new(0.5, 0.2, 0.1)
	applyBtn.BackgroundTransparency = 0.2
	applyBtn.TextColor3 = Color3.new(1, 1, 1)
	applyBtn.TextSize = 14
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.Text = "Apply"
	applyBtn.BorderSizePixel = 0
	applyBtn.ZIndex = 36
	applyBtn.Parent = panel

	local applyCorner = Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 6)
	applyCorner.Parent = applyBtn

	local statusBar = Instance.new("TextLabel")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(0, 300, 0, 18)
	statusBar.Position = UDim2.new(0, 16, 0, 384)
	statusBar.BackgroundTransparency = 1
	statusBar.TextColor3 = Color3.new(0.8, 0.8, 1)
	statusBar.TextSize = 12
	statusBar.Font = Enum.Font.Gotham
	statusBar.TextXAlignment = Enum.TextXAlignment.Left
	statusBar.Text = ""
	statusBar.ZIndex = 40
	statusBar.Parent = panel

	self._overlay = overlay
	self._panel = panel
	self._userIdInput = userIdInput
	self._output = outputLabel
	self._jsonInput = jsonInput
	self._status = statusBar
	self._closeBtn = closeBtn

	closeBtn.MouseButton1Click:Connect(function() self:Close() end)
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then self:Close() end
	end)

	viewBtn.MouseButton1Click:Connect(function()
		local uidStr = self._userIdInput.Text
		local uid = tonumber(uidStr)
		if not uid then
			local player = game:GetService("Players").LocalPlayer
			uid = player.UserId
			self._userIdInput.Text = tostring(uid)
		end
		self._status.Text = "Loading..."
		local adminSvc = Knit.GetService("AdminService")
		local data, raw = adminSvc:GetPlayerData(uid)
		if data then
			print("=== GM: " .. data.Name .. " (" .. tostring(data.UserId) .. ") ===")
			print("  Coins: " .. tostring(data.Coins))
			print("  Level: Lv." .. tostring(data.Level.level) .. " x" .. tostring(data.Level.multiplier))
			if raw then
				print("  --- Raw Data ---")
				for k, v in pairs(raw) do
					if typeof(v) == "table" then
						print("  " .. k .. ": " .. game:GetService("HttpService"):JSONEncode(v))
					else
						print("  " .. k .. ": " .. tostring(v))
					end
				end
			end
			self._status.Text = "Printed to console"
			task.delay(3, function() self._status.Text = "" end)
		else
			self._status.Text = "Player not found or access denied"
			task.delay(3, function() self._status.Text = "" end)
		end
	end)

	applyBtn.MouseButton1Click:Connect(function()
		local uidStr = self._userIdInput.Text
		local uid = tonumber(uidStr)
		if not uid then
			local player = game:GetService("Players").LocalPlayer
			uid = player.UserId
			self._userIdInput.Text = tostring(uid)
		end
		local jsonText = self._jsonInput.Text
		if jsonText == "" then
			self._status.Text = "Enter JSON key-value pairs"
			task.delay(3, function() self._status.Text = "" end)
			return
		end
		local ok, decoded = pcall(function()
			return game:GetService("HttpService"):JSONDecode(jsonText)
		end)
		if not ok or type(decoded) ~= "table" then
			self._status.Text = "Invalid JSON"
			task.delay(3, function() self._status.Text = "" end)
			return
		end
		local adminSvc = Knit.GetService("AdminService")
		local success = adminSvc:SetPlayerData(uid, decoded)
		if success then
			self._status.Text = "Applied successfully!"
			task.delay(3, function() self._status.Text = "" end)
		else
			self._status.Text = "Apply failed"
			task.delay(3, function() self._status.Text = "" end)
		end
	end)

	return self
end

function GMView:Open()
	self._overlay.Visible = true
	self._status.Text = ""
	self._output.Text = ""
end

function GMView:Close()
	self._overlay.Visible = false
end

return GMView
