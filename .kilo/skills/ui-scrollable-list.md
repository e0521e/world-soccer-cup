# 技能名称: ui_scrollable_list

**描述**: 在 Knit Controller 中创建可滚动物品列表，包含卡片式 Item 条目、动态 CanvasSize、购买按钮和数量显示。

## 架构模式

```txt
ScrollingFrame
├── ScrollBarThickness: 6
├── ScrollBarImageColor3: Color3.fromRGB(60, 60, 60)
├── CanvasSize: 动态计算 (根据子项总高度)
└── ItemCards[]
    └── ItemCard (Frame, 60px 高, 暗色底)
        ├── UICorner (6px)
        ├── UIStroke (1px, 45,45,55)
        ├── Icon (TextLabel, 40px 宽)
        ├── Name (TextLabel, 16px, 粗体)
        ├── Desc (TextLabel, 11px, 灰色)
        ├── BuyBtn (TextButton, 金色背景)
        │   ├── UICorner (5px)
        │   └── Text: 价格 / "Owned"
        └── QtyLabel (TextLabel, 可选: 显示数量)
```

## 代码模板

### 1. ScrollingFrame 创建

```lua
self._scrollingFrame = Instance.new("ScrollingFrame")
self._scrollingFrame.Name = "ItemList"
self._scrollingFrame.Size = UDim2.new(1, -16, 1, -110)  -- 留出 Header+Tab+Hint 空间
self._scrollingFrame.Position = UDim2.new(0, 8, 0, 92)
self._scrollingFrame.BackgroundTransparency = 1
self._scrollingFrame.BorderSizePixel = 0
self._scrollingFrame.ScrollBarThickness = 6
self._scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
self._scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
self._scrollingFrame.Parent = self._panel
```

### 2. Item 卡片模板

```lua
function self:_CreateItemCard(item, y)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.Position = UDim2.new(0, 0, 0, y)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.Parent = self._scrollingFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(45, 45, 55)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    -- 图标 (40px 宽)
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = item.Icon or "❓"
    icon.TextSize = 24
    icon.Font = Enum.Font.GothamBold
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = card

    -- 名称
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 200, 0, 22)
    nameLabel.Position = UDim2.new(0, 44, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.Name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    -- 描述
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0, 200, 0, 16)
    descLabel.Position = UDim2.new(0, 44, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = item.Description or ""
    descLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    descLabel.TextSize = 11
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = card

    -- 购买按钮
    local buyBtn = Instance.new("TextButton")
    buyBtn.BorderSizePixel = 0
    buyBtn.TextSize = 13
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.AutoButtonColor = false

    if item.Owned then
        buyBtn.Size = UDim2.new(0, 90, 0, 28)
        buyBtn.Position = UDim2.new(1, -98, 0.5, -14)
        buyBtn.BackgroundColor3 = Color3.fromRGB(30, 45, 30)
        buyBtn.BackgroundTransparency = 0.2
        buyBtn.Text = "Owned"
        buyBtn.TextColor3 = Color3.fromRGB(100, 160, 100)
        buyBtn.Active = false
    else
        buyBtn.Size = UDim2.new(0, 100, 0, 28)
        buyBtn.Position = UDim2.new(1, -108, 0.5, -14)
        buyBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 80)  -- 金色
        buyBtn.BackgroundTransparency = 0.1
        buyBtn.Text = `{item.Price}$`
        buyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)

        buyBtn.MouseButton1Click:Connect(function()
            self:_BuyItem(item.Index)
        end)
    end

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = buyBtn
    buyBtn.Parent = card

    return card
end
```

### 3. 重建列表逻辑

```lua
function self:_RebuildItems()
    -- 1. 清除旧卡片
    for _, btn in ipairs(self._itemButtons) do
        btn:Destroy()
    end
    self._itemButtons = {}

    -- 2. 根据当前 Tab 获取数据
    local items = if self._currentTab == "products" then self._products
        elseif self._currentTab == "passes" then self._passes
        else self._items

    -- 3. 逐项创建卡片
    local y = 0
    local cardH = 60
    local gap = 6
    for _, item in ipairs(items) do
        local card = self:_CreateItemCard(item, y)
        table.insert(self._itemButtons, card)
        y = y + cardH + gap
    end

    -- 4. 更新 CanvasSize (保证内容可滚动)
    self._scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(y, self._scrollingFrame.AbsoluteSize.Y))
end
```

### 4. 物品数量显示

```lua
-- 当为消耗品且数量>0时，在卡片右下角显示 "xN"
if (item.Quantity or 0) > 0 then
    local qtyLabel = Instance.new("TextLabel")
    qtyLabel.Size = UDim2.new(0, 40, 0, 16)
    qtyLabel.Position = UDim2.new(1, -48, 0.5, 12)
    qtyLabel.BackgroundTransparency = 1
    qtyLabel.Text = "x" .. tostring(item.Quantity)
    qtyLabel.TextColor3 = Color3.fromRGB(140, 200, 140)
    qtyLabel.TextSize = 12
    qtyLabel.Font = Enum.Font.GothamBold
    qtyLabel.TextXAlignment = Enum.TextXAlignment.Right
    qtyLabel.Parent = card
end
```

## 通用列表常量

| 属性 | 值 |
| ---- | --- |
| 卡片高度 | 60px |
| 卡片间距 | 6px |
| 卡片背景 | `Color3.fromRGB(20, 20, 28)`, transparency 0.3 |
| 卡片圆角 | 6px |
| 卡片描边 | Color3.fromRGB(45, 45, 55), 1px |
| 按钮金色 | `Color3.fromRGB(255, 215, 80)`, transparency 0.1 |
| 按钮绿色(Owned) | `Color3.fromRGB(30, 45, 30)`, transparency 0.2 |
| 滚动条 | 6px 宽, Color3.fromRGB(60, 60, 60) |
