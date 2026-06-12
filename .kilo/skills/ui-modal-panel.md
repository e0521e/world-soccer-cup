# 技能名称: ui_modal_panel

**描述**: 创建可切换的居中 Modal 覆盖面板（Shop / DailyReward / QBank 等），包含 Header、Tab 系统、内容区和底部提示。

## 架构模式

```txt
ScreenGui (单例, ResetOnSpawn=false)
├── ToggleButton (TextButton)       -- HUD 右侧按钮 → 调用 Toggle()
└── Panel (Frame, Visible=false)    -- 居中 Modal
    ├── UICorner (10px)
    ├── UIStroke (1.5px)
    ├── Header (TextLabel, 24px 金色)
    ├── TabRow (Frame)               -- 可选：分类标签
    │   └── TabButtons[] (TextButton)
    ├── ContentArea (...)             -- 面板主要内容
    └── Hint (TextLabel, "Press [X] to toggle")
```

## 标准 Controller 结构

```lua
-- 在 KnitStart 中:
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
self:_CreateUI(playerGui)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then  -- 快捷键
        self:Toggle()
    end
end)

-- 核心方法:
Toggle = function(self)
    if self._isOpen then self:Close() else self:Open() end
end
Open = function(self)
    if self._isOpen then return end
    self:_Refresh()                       -- 打开前刷新数据
    self._panel.Visible = true
    self._isOpen = true
end
Close = function(self)
    self._panel.Visible = false
    self._isOpen = false
end
```

## 代码模板

### 1. Modal 面板（居中）

```lua
self._panel = Instance.new("Frame")
self._panel.Name = "XxxPanel"
self._panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)  -- 500x420(Shop), 500x250(Daily), 520x460(QBank)
self._panel.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
self._panel.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
self._panel.BackgroundTransparency = 0.08
self._panel.BorderSizePixel = 0
self._panel.Visible = false
self._panel.Parent = self._screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = self._panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(50, 50, 50)
panelStroke.Thickness = 1.5
panelStroke.Parent = self._panel

-- Header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 44)
header.Position = UDim2.new(0, 0, 0, 6)
header.BackgroundTransparency = 1
header.Text = "📝  Panel Title"
header.TextColor3 = Color3.fromRGB(255, 215, 80)  -- 金色
header.TextSize = 24
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Center
header.Parent = self._panel

-- 底部提示
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0, 18)
hint.Position = UDim2.new(0, 0, 1, -20)
hint.BackgroundTransparency = 1
hint.Text = "Press [X] to toggle"
hint.TextColor3 = Color3.fromRGB(100, 100, 100)
hint.TextSize = 11
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.Parent = self._panel
```

### 2. Tab 系统

```lua
self._tabProducts = self:_CreateTabButton(X, Y, W, "Products", "products")
self._tabPasses = self:_CreateTabButton(X + W + GAP, Y, W, "Game Passes", "passes")

function self:_CreateTabButton(x, y, w, text, tabName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, 30)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(140, 140, 140)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = self._panel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(tabName)
    end)
    return btn
end

-- Tab 激活样式切换
function self:_UpdateTabStyles()
    self._tabProducts.BackgroundColor3 = if self._currentTab == "products"
        then Color3.fromRGB(40, 35, 20)       -- 激活: 金色底
        else Color3.fromRGB(25, 25, 25)       -- 未激活: 灰色底
    self._tabProducts.TextColor3 = if self._currentTab == "products"
        then Color3.fromRGB(255, 215, 80)     -- 激活: 金色字
        else Color3.fromRGB(140, 140, 140)    -- 未激活: 灰色字
end
```

### 3. 动态 Tab 行（QBank 风格：根据数据生成）

```lua
function self:_BuildCategoryTabs()
    -- 清除旧 tab
    for _, tab in ipairs(self._categoryTabs) do
        tab:Destroy()
    end
    self._categoryTabs = {}

    local tabW = 100
    local tabGap = 6
    local tabRowWidth = self._tabRow.AbsoluteSize.X
    local totalW = #self._categories * tabW + (#self._categories - 1) * tabGap
    local startX = (tabRowWidth - totalW) / 2

    for ci, cat in ipairs(self._categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, tabW, 0, 30)
        btn.Position = UDim2.new(0, math.max(0, startX + (ci-1)*(tabW+tabGap)), 0, 0)
        btn.BackgroundColor3 = if ci == self._currentCategory
            then Color3.fromRGB(25, 40, 50)      -- 激活色
            else Color3.fromRGB(25, 25, 25)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = `{cat.Icon} {cat.Name}`
        btn.TextColor3 = if ci == self._currentCategory
            then Color3.fromRGB(100, 200, 255)
            else Color3.fromRGB(140, 140, 140)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.Parent = self._tabRow

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            self:SwitchCategory(ci)
        end)
        self._categoryTabs[ci] = btn
    end
end
```

### 4. 选项按钮网格（QBank 风格：2x2）

```lua
local optionLabels = { "A", "B", "C", "D" }
for i = 1, 4 do
    local row = math.floor((i - 1) / 2)
    local col = (i - 1) % 2
    local bw, bh = 236, 68
    local gapX, gapY = 12, 10
    local x, y = col * (bw + gapX), row * (bh + gapY)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, bw, 0, bh)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = self._optionsBg

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local letter = Instance.new("TextLabel")
    letter.Size = UDim2.new(0, 28, 1, 0)
    letter.Position = UDim2.new(0, 6, 0, 0)
    letter.BackgroundTransparency = 1
    letter.Text = optionLabels[i]
    letter.TextColor3 = Color3.fromRGB(100, 200, 255)
    letter.TextSize = 14
    letter.Font = Enum.Font.GothamBold
    letter.TextXAlignment = Enum.TextXAlignment.Center
    letter.Parent = btn

    local optionText = Instance.new("TextLabel")
    optionText.Size = UDim2.new(1, -42, 1, -12)
    optionText.Position = UDim2.new(0, 38, 0, 6)
    optionText.BackgroundTransparency = 1
    optionText.Text = ""
    optionText.TextColor3 = Color3.fromRGB(180, 180, 180)
    optionText.TextSize = 14
    optionText.Font = Enum.Font.Gotham
    optionText.TextWrapped = true
    optionText.TextXAlignment = Enum.TextXAlignment.Left
    optionText.Parent = btn

    btn.MouseButton1Click:Connect(function()
        self:_SubmitAnswer(i)
    end)

    self._optionButtons[i] = {
        Button = btn,
        Letter = letter,
        OptionText = optionText,
    }
end
```

## 现有面板尺寸对照

| 面板 | 尺寸 (WxH) | 快捷键 | HUD 按钮 Y 位置 | Toggle 方法 |
| ---- | --------- | ------ | --------------- | ----------- |
| Shop | 500 x 420 | N | 204 | `Toggle()` |
| DailyReward | 500 x 250 | B | 160 | `Toggle()` |
| QBank | 520 x 460 | Q | 248 | `Toggle()` |

## 数据刷新模式

```lua
function self:_Refresh()
    -- 1. 通过 Knit Service 获取最新数据
    local service = Knit.GetService("XxxService")
    local data = service:GetData()

    -- 2. 更新 Tab 激活状态
    self:_UpdateTabStyles()

    -- 3. 重建列表内容
    self:_RebuildItems()
end
```
