local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PANEL_WIDTH = 520
local PANEL_HEIGHT = 460

local ShopView = {}
ShopView.__index = ShopView

function ShopView.new(screenGui: Instance)
	local self = setmetatable({}, ShopView)

	self._activeTab = "Products"
	self._currentItems = {}
	self._currentItemType = "Product"

	local overlay = Instance.new("Frame")
	overlay.Name = "ShopOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.6
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 20
	overlay.Visible = false
	overlay.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	panel.Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -PANEL_HEIGHT / 2)
	panel.BackgroundColor3 = Color3.new(0.06, 0.06, 0.14)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.ZIndex = 25
	panel.Parent = overlay

	local panelGradient = Instance.new("UIGradient")
	panelGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.1, 0.1, 0.2)),
		ColorSequenceKeypoint.new(1, Color3.new(0.04, 0.04, 0.1)),
	})
	panelGradient.Rotation = 90
	panelGradient.Parent = panel

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.new(0.35, 0.35, 0.65)
	panelStroke.Thickness = 1
	panelStroke.Transparency = 0.4
	panelStroke.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -38, 0, 8)
	closeBtn.BackgroundColor3 = Color3.new(0.3, 0.1, 0.1)
	closeBtn.BackgroundTransparency = 0.4
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "X"
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 30
	closeBtn.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	local title = Instance.new("TextLabel")
	title.Name = "ShopTitle"
	title.Size = UDim2.new(0, 200, 0, 32)
	title.Position = UDim2.new(0, 16, 0, 8)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "🏪 Shop"
	title.ZIndex = 30
	title.Parent = panel

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0, 150, 0, 22)
	coinsLabel.Position = UDim2.new(0, 16, 0, 44)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.TextColor3 = Color3.new(1, 0.9, 0.1)
	coinsLabel.TextStrokeTransparency = 0.1
	coinsLabel.TextStrokeColor3 = Color3.new(0.5, 0.3, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.Text = "💵 0"
	coinsLabel.ZIndex = 30
	coinsLabel.Parent = panel
	self._coinsLabel = coinsLabel

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -32, 0, 36)
	tabBar.Position = UDim2.new(0, 16, 0, 72)
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	tabBar.ZIndex = 25
	tabBar.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabBar

	local function makeTab(name: string, text: string, layoutOrder: number)
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Tab"
		btn.Size = UDim2.new(0, 140, 0, 36)
		btn.LayoutOrder = layoutOrder
		btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
		btn.BackgroundTransparency = 0.3
		btn.TextColor3 = Color3.new(0.7, 0.7, 0.8)
		btn.TextSize = 16
		btn.Font = Enum.Font.GothamBold
		btn.Text = text
		btn.TextWrapped = false
		btn.BorderSizePixel = 0
		btn.ZIndex = 26
		btn.Parent = tabBar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		return btn
	end

	local prodTab = makeTab("Products", "📦 Products", 1)
	local passTab = makeTab("GamePasses", "⭐ Game Passes", 2)
	self._prodTab = prodTab
	self._passTab = passTab

	local itemContainer = Instance.new("ScrollingFrame")
	itemContainer.Name = "ItemContainer"
	itemContainer.Size = UDim2.new(1, -32, 1, -162)
	itemContainer.Position = UDim2.new(0, 16, 0, 114)
	itemContainer.BackgroundTransparency = 1
	itemContainer.BorderSizePixel = 0
	itemContainer.ScrollBarThickness = 4
	itemContainer.ScrollBarImageColor3 = Color3.new(0.3, 0.3, 0.5)
	itemContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemContainer.ZIndex = 25
	itemContainer.Parent = panel

	local itemList = Instance.new("UIListLayout")
	itemList.SortOrder = Enum.SortOrder.LayoutOrder
	itemList.Padding = UDim.new(0, 8)
	itemList.Parent = itemContainer

	local statusBar = Instance.new("TextLabel")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, -32, 0, 24)
	statusBar.Position = UDim2.new(0, 16, 1, -36)
	statusBar.BackgroundTransparency = 1
	statusBar.TextColor3 = Color3.new(0.8, 0.8, 1)
	statusBar.TextStrokeTransparency = 0.3
	statusBar.TextScaled = true
	statusBar.Font = Enum.Font.Gotham
	statusBar.TextXAlignment = Enum.TextXAlignment.Center
	statusBar.Text = ""
	statusBar.ZIndex = 30
	statusBar.Parent = panel
	self._statusBar = statusBar

	self._overlay = overlay
	self._panel = panel
	self._itemContainer = itemContainer
	self._itemList = itemList
	self._closeBtn = closeBtn

	prodTab.MouseButton1Click:Connect(function()
		self:SwitchTab("Products")
	end)
	passTab.MouseButton1Click:Connect(function()
		self:SwitchTab("GamePasses")
	end)
	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:Close()
		end
	end)

	self._shopService = nil
	self._signalsConnected = false

	return self
end

function ShopView:Open()
	self._overlay.Visible = true
	self._panel.Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -PANEL_HEIGHT / 2 - 20)
	self._panel.BackgroundTransparency = 0.05

	local slideIn = TweenService:Create(self._panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -PANEL_HEIGHT / 2),
	})
	slideIn:Play()

	if not self._signalsConnected then
		self:_ConnectShopSignals()
	end

	self:UpdateCoinsDisplay()
	self:SwitchTab(self._activeTab)
	self._statusBar.Text = ""
end

function ShopView:_ConnectShopSignals()
	if self._signalsConnected then return end
	local svc = Knit.GetService("ShopService")
	if not svc then
		task.delay(0.5, function()
			self:_ConnectShopSignals()
		end)
		return
	end
	self._shopService = svc
	svc.OnPurchaseComplete:Connect(function(player, itemType, itemId, info)
		if player ~= Players.LocalPlayer then return end
			self._statusBar.Text = "✅ " .. (info.name or "") .. " purchased!"
		self:UpdateCoinsDisplay()
		task.delay(3, function()
			self._statusBar.Text = ""
		end)
	end)
	svc.OnPurchaseFailed:Connect(function(player, itemType, itemId, reason)
		if player ~= Players.LocalPlayer then return end
		self._statusBar.Text = "❌ " .. (reason or "Purchase failed")
		task.delay(3, function()
			self._statusBar.Text = ""
		end)
	end)
	self._signalsConnected = true
	if self._overlay.Visible then
		self:_BuildItemList()
	end
end

function ShopView:Close()
	self._overlay.Visible = false
end

function ShopView:UpdateCoinsDisplay()
	local rewardService = Knit.GetService("RewardService")
	local coins = rewardService:GetCoins()
	self._coinsLabel.Text = "💵 " .. tostring(math.floor(coins))
end

function ShopView:SwitchTab(tab: string)
	self._activeTab = tab

	self._prodTab.BackgroundColor3 = if tab == "Products" then Color3.new(0.25, 0.25, 0.4) else Color3.new(0.15, 0.15, 0.25)
	self._prodTab.BackgroundTransparency = if tab == "Products" then 0.1 else 0.3
	self._prodTab.TextColor3 = if tab == "Products" then Color3.new(1, 1, 1) else Color3.new(0.7, 0.7, 0.8)

	self._passTab.BackgroundColor3 = if tab == "GamePasses" then Color3.new(0.25, 0.25, 0.4) else Color3.new(0.15, 0.15, 0.25)
	self._passTab.BackgroundTransparency = if tab == "GamePasses" then 0.1 else 0.3
	self._passTab.TextColor3 = if tab == "GamePasses" then Color3.new(1, 1, 1) else Color3.new(0.7, 0.7, 0.8)

	self:_BuildItemList()
end

function ShopView:_BuildItemList()
	for _, child in ipairs(self._itemContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local shopService = self._shopService
	if not shopService then
		self:_ConnectShopSignals()
		shopService = self._shopService
	end
	if not shopService then
		self._statusBar.Text = "❌ Shop unavailable"
		self._itemContainer.CanvasSize = UDim2.new(0, 0, 0, self._itemList.AbsoluteContentSize.Y + 8)
		return
	end

	if self._activeTab == "Products" then
		local products = shopService:GetProducts()
		self._currentItems = products
		self._currentItemType = "Product"
		for _, item in ipairs(products) do
			self:_CreateItemCard(item, "Product")
		end
	else
		local gamePasses = shopService:GetGamePasses()
		local owned = shopService:GetOwnedGamePasses()
		local ownedSet = {}
		for _, id in ipairs(owned) do
			ownedSet[tostring(id)] = true
		end
		self._currentItems = gamePasses
		self._currentItemType = "GamePass"
		for _, item in ipairs(gamePasses) do
			local isOwned = ownedSet[tostring(item.GamePassId)] == true
			self:_CreateItemCard(item, "GamePass", isOwned)
		end
	end

	self._itemContainer.CanvasSize = UDim2.new(0, 0, 0, self._itemList.AbsoluteContentSize.Y + 8)
end

function ShopView:_CreateItemCard(item: any, itemType: string, isOwned: boolean?)
	local card = Instance.new("Frame")
	card.Name = item.Name .. "Card"
	card.Size = UDim2.new(1, 0, 0, 72)
	card.BackgroundColor3 = Color3.new(0.08, 0.08, 0.16)
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.ZIndex = 26
	card.Parent = self._itemContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.new(0.3, 0.3, 0.5)
	cardStroke.Thickness = 1
	cardStroke.Transparency = 0.6
	cardStroke.Parent = card

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 44, 0, 44)
	icon.Position = UDim2.new(0, 12, 0, 14)
	icon.BackgroundColor3 = Color3.new(0.12, 0.12, 0.22)
	icon.BackgroundTransparency = 0.3
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Text = item.Icon or "📦"
	icon.ZIndex = 27
	icon.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = icon

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0, PANEL_WIDTH - 260, 0, 22)
	nameLabel.Position = UDim2.new(0, 66, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = item.Name
	nameLabel.ZIndex = 27
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0, PANEL_WIDTH - 260, 0, 18)
	descLabel.Position = UDim2.new(0, 66, 0, 36)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = Color3.new(0.7, 0.7, 0.85)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Text = item.Description
	descLabel.ZIndex = 27
	descLabel.Parent = card

	if isOwned then
		local ownedLabel = Instance.new("TextLabel")
		ownedLabel.Name = "OwnedLabel"
		ownedLabel.Size = UDim2.new(0, 70, 0, 28)
		ownedLabel.Position = UDim2.new(1, -80, 0, 22)
		ownedLabel.BackgroundColor3 = Color3.new(0.1, 0.3, 0.1)
		ownedLabel.BackgroundTransparency = 0.3
		ownedLabel.TextColor3 = Color3.new(0.3, 1, 0.3)
		ownedLabel.TextScaled = true
		ownedLabel.Font = Enum.Font.GothamBold
		ownedLabel.Text = "Owned"
		ownedLabel.BorderSizePixel = 0
		ownedLabel.ZIndex = 27
		ownedLabel.Parent = card

		local ownedCorner = Instance.new("UICorner")
		ownedCorner.CornerRadius = UDim.new(0, 6)
		ownedCorner.Parent = ownedLabel
		return
	end

	if itemType == "Product" then
		local robuxIcon = utf8.char(0xE002)
		self:_CreateBuyButton(card, item, itemType, item.PriceRobux, robuxIcon)
	elseif itemType == "GamePass" then
		local priceCoins = item.PriceCoins or 0
		local priceRobux = item.PriceRobux or 0

		if priceCoins > 0 then
			self:_CreateBuyButton(card, item, itemType, priceCoins, "💵")
		elseif priceRobux > 0 then
			self:_CreateBuyButton(card, item, itemType, priceRobux, utf8.char(0xE002))
		end
	end
end

function ShopView:_CreateBuyButton(card: Frame, item: any, itemType: string, price: number, currencyIcon: string)
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceTag"
	priceLabel.Size = UDim2.new(0, 70, 0, 22)
	priceLabel.Position = UDim2.new(1, -156, 0, 25)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = if currencyIcon == "💵" then Color3.new(1, 0.9, 0.1) else Color3.new(0.6, 0.8, 1)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Text = currencyIcon .. " " .. tostring(price)
	priceLabel.ZIndex = 27
	priceLabel.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.Size = UDim2.new(0, 70, 0, 28)
	buyBtn.Position = UDim2.new(1, -82, 0, 22)
	buyBtn.BackgroundColor3 = if currencyIcon == "💵" then Color3.new(0.8, 0.6, 0.05) else Color3.new(0.1, 0.35, 0.6)
	buyBtn.BackgroundTransparency = 0.15
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.TextScaled = true
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = "Buy"
	buyBtn.BorderSizePixel = 0
	buyBtn.ZIndex = 27
	buyBtn.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyBtn

	buyBtn.MouseButton1Click:Connect(function()
		if itemType == "Product" then
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, item.ProductId)
		elseif itemType == "GamePass" then
			local shopService = self._shopService
			if not shopService then
				self:_ConnectShopSignals()
				shopService = self._shopService
			end
			if not shopService then
				self._statusBar.Text = "❌ Shop unavailable"
				task.delay(3, function() self._statusBar.Text = "" end)
				return
			end
			if currencyIcon == "💵" then
				local success, err = shopService:PurchaseWithCoins(item.GamePassId)
				if success then
					self._statusBar.Text = "✅ " .. item.Name .. " purchased!"
					self:UpdateCoinsDisplay()
					self:SwitchTab(self._activeTab)
				else
					self._statusBar.Text = "❌ " .. (err or "Purchase failed")
				end
				task.delay(3, function()
					self._statusBar.Text = ""
				end)
			else
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, item.GamePassId)
			end
		end
	end)
end

function ShopView:SetCloseCallback(cb: (() -> ())?)
	self._closeCb = cb
end

return ShopView
