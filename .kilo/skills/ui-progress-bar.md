# 技能名称: ui_progress_bar

**描述**: 创建进度条、里程碑标记和圆形冷却覆盖层。适用于 OnlineReward 进度条、SkillX 冷却环等场景。

## 1. 基础进度条（OnlineReward 风格）

### 结构

```txt
BarTrack (Frame, 圆角)
├── UICorner (5px)
├── ProgressFill (Frame, 动态宽度, 金色)
│   └── UICorner (5px)
└── MilestoneDots[] (Frame, 圆形, 沿进度条定位)
    ├── UICorner (7px)
    └── UIStroke (1px)
```

### 代码模板

```lua
-- 轨道背景
local barTrack = Instance.new("Frame")
barTrack.Size = UDim2.new(0, barWidth, 0, barHeight)     -- e.g. 0,208, 0,10
barTrack.Position = UDim2.new(0, barX, 0, barY)
barTrack.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barTrack.BorderSizePixel = 0
barTrack.Parent = panel

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 5)
trackCorner.Parent = barTrack

-- 进度填充
self._progressFill = Instance.new("Frame")
self._progressFill.Size = UDim2.new(0, 0, 1, 0)         -- 初始 0%
self._progressFill.BackgroundColor3 = Color3.fromRGB(255, 215, 80)  -- 金色
self._progressFill.BorderSizePixel = 0
self._progressFill.Parent = barTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = self._progressFill
```

### 更新进度（带动画）

```lua
-- 平滑动画
self._progressFill:TweenSize(
    UDim2.new(pct, 0, 1, 0),
    Enum.EasingDirection.Out,
    Enum.EasingStyle.Quad,
    0.3,
    true
)

-- 或直接设置
self._progressFill.Size = UDim2.new(pct, 0, 1, 0)
```

## 2. 里程碑标记

### 创建沿进度条排列的里程碑圆点

```lua
local milestones = GameSettings.ONLINE_REWARD_MILESTONES  -- { 60, 180, 300 }
local maxTime = milestones[#milestones]

for i, t in ipairs(milestones) do
    local pos = t / maxTime
    local dotCenterX = barX + pos * barWidth

    -- 圆点
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(pos, -7, 0.5, -7)  -- 沿进度条分布
    dot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    dot.BorderSizePixel = 0
    dot.Parent = barTrack

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 7)
    dotCorner.Parent = dot

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(100, 100, 120)
    dotStroke.Thickness = 1
    dotStroke.Parent = dot

    self._milestoneDots[t] = dot

    -- 底部时间标签
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 60, 0, 14)
    label.Position = UDim2.new(0, dotCenterX - 30, 0, barY + barHeight + 4)
    label.BackgroundTransparency = 1
    label.Text = `{t / 60}min`
    label.TextColor3 = Color3.fromRGB(120, 120, 130)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = panel

    self._milestoneLabels[t] = label
end
```

### 里程碑状态更新

```lua
-- 三种状态:
-- claimed (已完成): 金色圆点 + 绿色卡片 + ✅
-- available (可领取): 金色圆点 + 暗金卡片 + ⏳
-- locked (未解锁): 灰色圆点 + 深色卡片 + 🔒

if claimed then
    dot.BackgroundColor3 = Color3.fromRGB(255, 215, 80)  -- 金色
    label.TextColor3 = Color3.fromRGB(255, 215, 80)
    card.BackgroundColor3 = Color3.fromRGB(25, 40, 20)   -- 绿色
    icon.Text = "✅"
elseif elapsed >= milestoneTime then
    dot.BackgroundColor3 = Color3.fromRGB(255, 215, 80)
    card.BackgroundColor3 = Color3.fromRGB(30, 28, 20)    -- 暗金色
    icon.Text = "⏳"
    icon.TextColor3 = Color3.fromRGB(255, 215, 80)
else
    dot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)     -- 灰色
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    icon.Text = "🔒"
end
```

## 3. 圆形冷却覆盖层（SkillX 风格）

### 结构2

```txt
Container (Frame, 圆角 50%=圆形)
├── OuterRing (Frame, UIStroke 2px 金色)
│   ├── UICorner (圆形)
│   └── UIStroke
├── CooldownOverlay (Frame)
│   ├── LeftMask (Frame, ClipsDescendants, 左半圆)
│   │   └── LeftFill (Frame, 旋转角度控制)
│   │       └── UICorner (圆形)
│   └── RightMask (Frame, ClipsDescendants, 右半圆)
│       └── RightFill (Frame, 旋转角度控制)
│           └── UICorner (圆形)
├── CenterLabel (TextLabel, "X" 图标)
└── CooldownText (TextLabel, 冷却秒数)
```

### 代码模板2

```lua
-- 圆形容器
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 77, 0, 77)
container.Position = UDim2.new(1, -160, 1, -170)
container.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
container.BackgroundTransparency = 0.2
container.BorderSizePixel = 0
container.Parent = self._screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 38)  -- 77/2 ≈ 38, 圆形
containerCorner.Parent = container

-- 外环描边
self._outerRing = Instance.new("Frame")
self._outerRing.Size = UDim2.new(1, 4, 1, 4)
self._outerRing.Position = UDim2.new(0, -2, 0, -2)
self._outerRing.BackgroundTransparency = 1
self._outerRing.BorderSizePixel = 0
self._outerRing.Parent = container

local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Color3.fromRGB(255, 215, 80)
ringStroke.Thickness = 2
ringStroke.Transparency = 0.3
ringStroke.Parent = self._outerRing

local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(0, 40)
ringCorner.Parent = self._outerRing

-- 冷却遮罩层
self._cooldownOverlay = Instance.new("Frame")
self._cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
self._cooldownOverlay.BackgroundTransparency = 1
self._cooldownOverlay.BorderSizePixel = 0
self._cooldownOverlay.Parent = container

-- 左半圆遮罩
local leftMask = Instance.new("Frame")
leftMask.Size = UDim2.new(0.5, 0, 1, 0)
leftMask.BackgroundTransparency = 1
leftMask.ClipsDescendants = true
leftMask.BorderSizePixel = 0
leftMask.Parent = self._cooldownOverlay

self._leftFill = Instance.new("Frame")
self._leftFill.Size = UDim2.new(2, 0, 1, 0)
self._leftFill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
self._leftFill.BackgroundTransparency = 0.4
self._leftFill.BorderSizePixel = 0
self._leftFill.Parent = leftMask

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 38)
leftCorner.Parent = self._leftFill

-- 右半圆遮罩
local rightMask = Instance.new("Frame")
rightMask.Size = UDim2.new(0.5, 0, 1, 0)
rightMask.Position = UDim2.new(0.5, 0, 0, 0)
rightMask.BackgroundTransparency = 1
rightMask.ClipsDescendants = true
rightMask.BorderSizePixel = 0
rightMask.Parent = self._cooldownOverlay

self._rightFill = Instance.new("Frame")
self._rightFill.Size = UDim2.new(2, 0, 1, 0)
self._rightFill.Position = UDim2.new(-1, 0, 0, 0)
self._rightFill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
self._rightFill.BackgroundTransparency = 0.4
self._rightFill.BorderSizePixel = 0
self._rightFill.Parent = rightMask

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 38)
rightCorner.Parent = self._rightFill

-- 中心文字
self._centerLabel = Instance.new("TextLabel")
self._centerLabel.Size = UDim2.new(1, 0, 1, 0)
self._centerLabel.BackgroundTransparency = 1
self._centerLabel.Text = "X"
self._centerLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
self._centerLabel.TextSize = 32
self._centerLabel.Font = Enum.Font.GothamBold
self._centerLabel.TextXAlignment = Enum.TextXAlignment.Center
self._centerLabel.Parent = container
```

### 冷却进度控制

```lua
-- progress: 0~1, 0=可用, 1=满冷却
function self:_SetCooldownProgress(progress: number)
    local p = math.clamp(progress, 0, 1)
    if p > 0.5 then
        -- 超过 50%，右半圆旋转
        local t = (p - 0.5) * 2
        self._rightFill.Rotation = -180 * t
        self._leftFill.Rotation = 180
    else
        -- 小于 50%，左半圆旋转
        self._rightFill.Rotation = 0
        self._leftFill.Rotation = 360 * p
    end
end
```

### Heartbeat 冷却循环

```lua
self._remaining = GameSettings.SKILL_X_COOLDOWN
self._cooldownActive = true
self._centerLabel.Visible = false
self._cooldownText.Visible = true

local conn
conn = RunService.Heartbeat:Connect(function(dt)
    if not self._cooldownActive then
        conn:Disconnect()
        return
    end
    self._remaining = math.max(0, self._remaining - dt)
    local progress = self._remaining / GameSettings.SKILL_X_COOLDOWN
    self:_SetCooldownProgress(progress)
    if self._remaining > 0 then
        self._cooldownText.Text = tostring(math.ceil(self._remaining))
    end
    if self._remaining <= 0 then
        self._cooldownActive = false
        self._cooldownText.Visible = false
        self._centerLabel.Visible = true
        self:_SetCooldownProgress(0)
        conn:Disconnect()
    end
end)
```

## 4. 弹出奖励动画

```lua
-- 当里程碑达成时，在卡片上方弹出 "+1000 $"
local animLabel = Instance.new("TextLabel")
animLabel.Size = UDim2.new(0, 80, 0, 24)
animLabel.Position = UDim2.new(0.5, -40, 0, -10)
animLabel.BackgroundTransparency = 1
animLabel.Text = "+1,000 $"
animLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
animLabel.TextSize = 16
animLabel.Font = Enum.Font.GothamBold
animLabel.TextXAlignment = Enum.TextXAlignment.Center
animLabel.Parent = card

local startTime = os.clock()
local conn
conn = RunService.Heartbeat:Connect(function()
    local dt = os.clock() - startTime
    if dt > 1.5 then
        conn:Disconnect()
        animLabel:Destroy()
        return
    end
    local alpha = dt / 1.5
    animLabel.Position = UDim2.new(0.5, -40, 0, -10 - alpha * 20)
    animLabel.TextTransparency = alpha
end)
```

## 5. 时间格式工具

```lua
local minutes = math.floor(elapsed / 60)
local seconds = math.floor(elapsed % 60)
local text = `⏱ {string.format("%02i:%02i", minutes, seconds)}`
```
