# 技能名称: ui_hud_panel

**描述**: 在 Knit Controller 中创建 HUD 面板（右侧按钮列、状态面板、血条、通知系统）。适用于本项目的暗色主题 Knit 架构。

## 常见 HUD 元素布局

```txt
ScreenGui (ResetOnSpawn=false, IgnoreGuiInset=true)
├── StatPanel (Frame)              -- 右上: Score / Kills / Coins 信息面板
│   ├── UICorner
│   ├── UIStroke
│   ├── Icon (TextLabel)           -- ★ / ☠ / $ 图标
│   └── Label (TextLabel)          -- SCORE / KILLS / COINS + 数值
├── HealthPanel (Frame)            -- 左下: 血条面板
│   ├── UICorner
│   ├── UIStroke
│   ├── HeartIcon (TextLabel)      -- ❤
│   ├── BarBg (Frame)              -- 血条背景
│   │   ├── UICorner
│   │   └── HealthFill (Frame)     -- 动态宽度 fill
│   └── HealthText (TextLabel)     -- "100 / 100"
├── ToggleButton[N] (TextButton)   -- 右侧任务栏按钮（Daily / Shop / QBank）
│   ├── UICorner
│   ├── UIStroke
│   ├── Icon (TextLabel)
│   └── Label (TextLabel)
├── Notification (TextLabel)       -- 居中通知（Heartbeat fade-out）
└── GameOver (Frame)               -- 全屏遮罩
```

## 代码模板

### 1. 右侧 Toggle 按钮（用于打开 Shop / DailyReward / QBank 等面板）

```lua
local btn = Instance.new("TextButton")
btn.Name = "XxxToggle"
btn.Size = UDim2.new(0, 160, 0, 40)
btn.Position = UDim2.new(1, -176, 0, Y_POSITION)  -- Y: 160(Daily), 204(Shop), 248(QBank)
btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
btn.BackgroundTransparency = 0.25
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Parent = self._screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = btn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(60, 60, 60)
btnStroke.Thickness = 1
btnStroke.Parent = btn

local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 30, 1, 0)
icon.BackgroundTransparency = 1
icon.Text = "ICON_EMOJI"
icon.TextColor3 = Color3.fromRGB(255, 215, 80)  -- 金色主题色
icon.TextSize = 18
icon.Font = Enum.Font.GothamBold
icon.TextXAlignment = Enum.TextXAlignment.Center
icon.Parent = btn

local label = Instance.new("TextLabel")
label.Name = "Label"
label.Size = UDim2.new(0, 124, 1, 0)
label.Position = UDim2.new(0, 32, 0, 0)
label.BackgroundTransparency = 1
label.Text = "ButtonName"
label.TextColor3 = Color3.fromRGB(255, 215, 80)
label.TextSize = 16
label.Font = Enum.Font.GothamBold
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = btn

btn.MouseButton1Click:Connect(function()
    self:Toggle()
end)
```

### 2. Stat 信息面板（Score / Kills / Coins）

```lua
local panel = Instance.new("Frame")
panel.Name = "XxxPanel"
panel.Size = UDim2.new(0, 160, 0, 40)
panel.Position = UDim2.new(1, -176, 0, Y_OFFSET)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel = 0
panel.Parent = self._screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1
stroke.Parent = panel

-- 图标 (24x24, 左上角偏移 8,8)
local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 24, 0, 24)
icon.Position = UDim2.new(0, 8, 0, 8)
icon.BackgroundTransparency = 1
icon.Text = "★"  -- 或 ☠ / $
icon.TextColor3 = Color3.fromRGB(255, 200, 50)
icon.TextSize = 18
icon.Font = Enum.Font.GothamBold
icon.TextXAlignment = Enum.TextXAlignment.Center
icon.Parent = panel

-- 数值 (24px 字体)
self._valueText = Instance.new("TextLabel")
self._valueText.Size = UDim2.new(0, 120, 0, 24)
self._valueText.Position = UDim2.new(0, 36, 0, 8)
self._valueText.BackgroundTransparency = 1
self._valueText.Text = "0"
self._valueText.TextColor3 = Color3.fromRGB(255, 200, 50)
self._valueText.TextSize = 20
self._valueText.Font = Enum.Font.GothamBold
self._valueText.TextXAlignment = Enum.TextXAlignment.Left
self._valueText.Parent = panel

-- 标签 (10px 灰色小字)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 120, 0, 14)
label.Position = UDim2.new(0, 36, 0, 26)
label.BackgroundTransparency = 1
label.Text = "SCORE"
label.TextColor3 = Color3.fromRGB(140, 140, 140)
label.TextSize = 10
label.Font = Enum.Font.GothamBold
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = panel
```

### 3. 血条 (Health Bar)

```lua
local barBg = Instance.new("Frame")
barBg.Name = "BarBg"
barBg.Size = UDim2.new(0, 160, 0, 10)
barBg.Position = UDim2.new(0, 36, 0, 8)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBg.BackgroundTransparency = 0.5
barBg.BorderSizePixel = 0
barBg.Parent = healthPanel

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 5)
barCorner.Parent = barBg

self._healthFill = Instance.new("Frame")
self._healthFill.Name = "HealthFill"
self._healthFill.Size = UDim2.new(1, 0, 1, 0)
self._healthFill.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
self._healthFill.BorderSizePixel = 0
self._healthFill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = self._healthFill

-- 更新血条逻辑
local pct = math.clamp(currentHealth / maxHealth, 0, 1)
self._healthFill.Size = UDim2.new(pct, 0, 1, 0)

-- 颜色阈值
local color
if pct > 0.5 then
    color = Color3.fromRGB(80, 255, 80)     -- 绿色
elseif pct > 0.25 then
    color = Color3.fromRGB(255, 200, 50)    -- 黄色
else
    color = Color3.fromRGB(255, 50, 50)     -- 红色
end
self._healthFill.BackgroundColor3 = color
```

### 4. 通知系统（居中淡出）

```lua
self._notificationLabel = Instance.new("TextLabel")
self._notificationLabel.Name = "Notification"
self._notificationLabel.Size = UDim2.new(0, 400, 0, 50)
self._notificationLabel.Position = UDim2.new(0.5, -200, 0.4, -25)
self._notificationLabel.BackgroundTransparency = 1
self._notificationLabel.Text = ""
self._notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
self._notificationLabel.TextSize = 28
self._notificationLabel.Font = Enum.Font.GothamBold
self._notificationLabel.TextXAlignment = Enum.TextXAlignment.Center
self._notificationLabel.TextStrokeTransparency = 0.3
self._notificationLabel.Parent = self._screenGui

function self:_ShowNotification(text: string)
    self._notificationLabel.Text = text
    self._notificationLabel.TextTransparency = 0
    if self._notificationConn then self._notificationConn:Disconnect() end
    task.delay(3, function()
        local start = os.clock()
        self._notificationConn = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = os.clock() - start
            local alpha = math.min(1, elapsed / 1.5)
            self._notificationLabel.TextTransparency = alpha
            if alpha >= 1 and self._notificationConn then
                self._notificationConn:Disconnect()
                self._notificationConn = nil
            end
        end)
    end)
end
```

### 5. 金币浮动动画

```lua
function self:_PlayCoinAnimation(amount: number)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 160, 0, 28)
    label.Position = UDim2.new(1, -176, 0, 112)  -- 从 CoinsPanel 位置开始
    label.BackgroundTransparency = 1
    label.Text = `+{amount} $`
    label.TextColor3 = Color3.fromRGB(255, 215, 80)
    label.TextSize = 18
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.TextStrokeTransparency = 0.3
    label.Parent = self._coinsAnimRoot  -- Folder in ScreenGui

    local startTime = os.clock()
    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = os.clock() - startTime
        if elapsed > 1.5 then
            conn:Disconnect()
            label:Destroy()
            return
        end
        local alpha = elapsed / 1.5
        label.Position = UDim2.new(1, -176, 0, 112 - alpha * 40)
        label.TextTransparency = alpha
    end)
end
```

## ScreenGui 标准设置

```lua
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
self._screenGui = Instance.new("ScreenGui")
self._screenGui.Name = "XxxUI"
self._screenGui.ResetOnSpawn = false
self._screenGui.IgnoreGuiInset = true
self._screenGui.Parent = playerGui
```

## 设计常量

| 元素 | 背景色 | 透明度 | 圆角 | 描边 |
| ---- | ------ | ------ | ---- | ---- |
| 面板 | `Color3.fromRGB(15, 15, 15)` | 0.25 | 6 | 60,60,60, 1px |
| Modal 大面板 | `Color3.fromRGB(12, 12, 12)` | 0.08 | 10 | 50,50,50, 1.5px |
| 金币/金色 | `ffd750`(RGB:255,215,80) | - | - | - |
| 按钮 inactive | `Color3.fromRGB(25, 25, 25)` | 0.3 | 6 | - |
| 列表卡片 | `Color3.fromRGB(20, 20, 28)` | 0.3 | 6 | 45,45,55, 1px |
