# UI 现状文档（重构前记录）

> 生成时间：2026-06-13
> 用途：为 UI 重构提供完整的现状梳理

---

## 一、UI 概览

当前项目中的 UI 分为三类来源：

| 来源 | 位置 | 创建方式 | 说明 |
| --- | --- | --- | --- |
| UIController (Knit Controller) | `StarterPlayerScripts.Client.controllers.UIController` | 代码动态创建 | HUD 主界面、进球特效、解锁反馈、浮动文字 |
| NPCTimerService (Knit Service) | `ServerScriptService.Server.services.NPCTimerService` | 代码动态创建 | NPC 头顶倒计时 BillboardGui、认领 Prompt/Highlight |
| Studio 预制实例 | `Workspace.Field_1.FieldOwnerGui` + 其他 Field | Studio 手动放置 | 球场归属者信息（头像 + 名字） |

---

## 二、UIController — 主 HUD (`src/client/controllers/UIController.luau`)

### 2.1 UI 层级结构

```
PlayerGui (Players.LocalPlayer)
 └─ FreeKickHUD (ScreenGui, ResetOnSpawn=false)
     ├─ HUD (Frame, 顶部黑条, BG透明度0.5)
     │   ├─ LevelLabel (TextLabel)        : "Lv.1 (x1.0)"
     │   ├─ CoinsLabel (TextLabel)        : "Coins: 0"
     │   ├─ TimeDotContainer (Frame)      : 时间+进度容器
     │   │   ├─ TimerLabel (TextLabel)    : "00:00" (MM:SS)
     │   │   ├─ ProgressBar (Frame)       : 黄色圆角进度条
     │   │   │   └─ UICorner
     │   │   ├─ Dot_1~Dot_5 (Frame×5)    : 每分钟节点圆点
     │   │   │   └─ UICorner
     │   └─ UpgradeButton (TextButton)    : "UPGRADE"
     ├─ GoalLabel (TextLabel, 初始隐藏)    : "GOAL!" (ZIndex=10)
     ├─ UnlockLabel (TextLabel, 初始隐藏)  : "XXX 解锁!" (ZIndex=10)
     └─ [运行时创建的浮动文字] (TextLabel, ZIndex=20, 自动销毁)
```

### 2.2 数据更新机制

| 数据 | 更新方式 | 更新频率 |
| --- | --- | --- |
| 时间 (MM:SS) | 轮询 `NPCProgressService:GetElapsedTime()` | 1 秒 |
| 金币 | 轮询 `RewardService:GetCoins()` | 1 秒 |
| 等级 | 轮询 `RewardService:GetLevel()` | 1 秒（仅在变化时更新） |
| 进度点 | 基于分钟数填充 Dot (共 5 分钟, `ONLINE_TOTAL_MINUTES`) | 1 秒 |
| 进度条 | 基于分钟数百分比 | 1 秒 |

### 2.3 数据更新方式

当前 HUD 采用 **轮询方式** 获取数据（见 2.2 节），因为 Knit 信号可能在服务器端触发而客户端未收到。

所有之前在 2.3 节列出的 18 个空信号连接已在 2026-06-13 UI 重构第 2 步中全部清除。

### 2.4 实际使用的连接

| 事件 | 回调 | 效果 |
| --- | --- | --- |
| `AutoKickService.OnGoalScored` | `_ShowGoalEffect()` | 显示 "GOAL!" 文字动画 |
| `UpgradeButton.MouseButton1Click` | lambda | 调用 `RewardService:UpgradeLevel()` |

### 2.5 UI 功能列表

| 功能 | 方法 | 触发时机 |
| --- | --- | --- |
| 时间显示更新 | `_UpdateTimeDisplay(totalSeconds)` | 每 1 秒 |
| 金币更新 | `_UpdateCoins(balance, delta)` | 每 1 秒 + delta>0 时浮动 "+N Coins" |
| 等级更新 | `_UpdateLevel(level, multiplier)` | 等级变化时 |
| 进球特效 | `_ShowGoalEffect()` | `OnGoalScored` 事件 |
| ~~解锁 NPC 提示~~ | ~~`_AnimateDot(npcIdx, displayName)`~~ | ~~从未被调用，已在第 2 步清理~~ |
| 球队完成 | `_ShowTeamComplete()` | 300 秒（5 分钟）到达 |
| 升级按钮 | UpgradeButton click | 玩家手动点击 |
| 浮动文字 | `_ShowFloatingText(text, color)` | 被上述多个方法调用 |

---

## 三、NPCTimerService — NPC 头顶 UI (`ServerScriptService.Server.services.NPCTimerService`)

### 3.1 UI 层级结构

```
NPC Model (workspace 内)
 └─ HumanoidRootPart (BasePart)
     ├─ TimerGui (BillboardGui, AlwaysOnTop=true, StudsOffset=(0,8,0))
     │   ├─ TimerLabel (TextLabel)     : 倒计时数字 / "PRESS E"
     │   └─ QualityLabel (TextLabel)   : "Common x1.0" / "Rare x1.5" ...
     ├─ ClaimPrompt (ProximityPrompt, 认领后销毁)
     │   ├─ Key: E, HoldDuration=0, Distance=6
     │   └─ Triggered → playerService:TakeoverNPC()
     └─ ClaimHighlight (Highlight, 认领后销毁)
         ├─ FillColor: (0,1,0), FillTransparency=0.6
```

### 3.2 计时流程

1. `ActivateNPCs()` → 为每个 slot 放置 NPC → 创建 TimerGui
2. `_BeginTimer()` → 每秒递减 `timerRemaining` → 更新 `TimerLabel.Text`
   - 倒计时 ≤5 秒时文字变红
3. 倒计时到 0 → `TimerGui:Destroy()` → 显示 ClaimPrompt + ClaimHighlight
   - TimerLabel.Text → "PRESS E" (绿色)
4. 玩家按下 E → `TakeoverNPC()` → 销毁 Prompt/Highlight → `_RefillSlot()`

### 3.3 Quality 视觉表现

| Quality | VisualEffect | 外观变化 |
| --- | --- | --- |
| Common (Lv.1) | none | 无变化 |
| Rare (Lv.2) | jersey | Shirt 变金色 |
| Epic (Lv.3) | gold | Shirt 变金色 |
| Legendary (Lv.4) | glow | Shirt 金色 + Highlight 金色 |
| Mythic (Lv.5) | dynamic | Shirt 红色 + Highlight 红色+黄色描边 |

---

## 四、FieldManagerService — 球场归属 UI (`ServerScriptService.Server.services.FieldManagerService`)

### 4.1 UI 层级结构（Studio 预制）

```
Field_N (Model, workspace)
 └─ FieldOwnerGui (BillboardGui, 初始 Enabled=false)
     ├─ Avatar (ImageLabel)         : 玩家头像 (48×48 headshot)
     ├─ AvatarBorder (Frame)
     │   └─ UICorner
     └─ PlayerName (TextLabel)      : 玩家 DisplayName
```

### 4.2 赋值/释放逻辑

- **PlayerAdded** → `_AssignField(player)` → `_UpdatePlayerGuis(field, player)`
  - 获取 player.UserId 的头像 URL → 设置 Avatar.Image
  - 设置 PlayerName.Text = player.DisplayName
  - 设置 Enabled = true
- **PlayerRemoving** → `_ReleaseField(player)` → `_ClearPlayerGuis(field)`
  - Enabled = false
  - Avatar.Image = 占位图
  - PlayerName.Text = ""

---

## 五、CameraController — 视角控制 (`src/client/controllers/CameraController.luau`)

非 UI 但影响视觉体验，一并记录：

| 事件 | 镜头行为 |
| --- | --- |
| `OnKickAnimation` | 切换到 `CameraType.Scriptable` → zoom to 玩家角色 (0.3s) |
| `OnBallFlying` | 跟随球飞行弧线 (1.2s)，镜头在球和中点之间 |
| `OnGoalScored` | 切换到进球检测器位置 (1s)，然后延迟 1s → 恢复 `CameraType.Custom` |

---

## 六、Package 级 UI 依赖

| Package | 用途 |
| --- | --- |
| `topbarplus` (1foreverhd) | 在 StarterPlayerScripts 中通过 Knit 加载，未直接使用其 API |
| `satchel` (ryanlua) | 背包 GUI 框架，未直接使用 |

---

## 七、已清理项（2026-06-13 第 2 步）

| 清理项 | 类型 | 操作 |
| --- | --- | --- |
| 18 个空信号连接 | 代码 | 删除（所有`Connect(function() end)`） |
| 3 个仅用于空连接的 Service 变量 | 代码 | 删除 npcTimer / ballSpawn / playerSvc |
| `_AnimateDot` 方法 | 代码 | 删除（从未被调用） |
| `_unlockLabel` 实例 + 字段 | 代码 + Roblox 实例 | 删除（仅被 `_AnimateDot` 使用） |
| `DOT_VIBRATE_SCALE` 常量 | 代码 | 删除（仅被 `_AnimateDot` 使用） |

### 保留观察项

| 项目 | 说明 |
| --- | --- |
| StarterGui | Roblox 核心服务，无法删除，保持为空 |
| topbarplus / satchel | Package 已安装但未直接使用，留待重构时决定去留 |

---

## 八、新 UI 设计方案（已实现，2026-06-13）

### 8.1 布局分区

```
┌──────────────────────────────────────────────────┐
│                    TOP BAR                        │
│  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  标题/标识    │  │  Coins: XXX   Lv.X(xY.Z) │  │
│  └──────────────┘  └──────────────────────────┘  │
│                                                    │
│          ┌──────────────────────────┐              │
│          │  在线时长进度条          │              │
│          │  ●──●──●──●──●           │              │
│          │  MM:SS                   │              │
│          └──────────────────────────┘              │
│                                                    │
│                                                    │
│                          ┌──────────────────┐      │
│                          │   商店 (Shop)     │      │
│                          ├──────────────────┤      │
│                          │   重生 (Rebirth)  │      │
│                          ├──────────────────┤      │
│                          │   [后续功能...]   │      │
│                          └──────────────────┘      │
│                                                    │
│               [GOAL! 等浮动效果]                     │
│                                                    │
└──────────────────────────────────────────────────┘
```

### 8.2 分区详情

| 区域 | 位置 | 内容 | 说明 |
| --- | --- | --- | --- |
| **CoreBar** | 正上居中 | 在线时长进度条 + 计时器 + 5 分钟节点圆点 | 核心玩法进度，替代当前顶部黑条 |
| **InfoBar** | 右上角 | Coins 数量 + 等级 Lv.X (xY.Z) | 精简显示，不包含进度 |
| **ActionPanel** | 右侧垂直居中 | 商店按钮（弹出覆盖层）、重生按钮（保留按钮形式） | 功能入口，后续重生改为与场景内 NPC 交互 |
| **Overlay** | 屏幕居中 | GOAL! 进球特效、解锁通知、浮动文字 | 与现有逻辑一致 |

### 8.3 UI 组件拆分

| 组件 | 文件路径 | 职责 | 类型 |
| --- | --- | --- | --- |
| `CoreBar` View | `src/client/views/CoreBarView.luau` | 进度条 + 计时器 + 圆点 | 常驻 |
| `InfoBar` View | `src/client/views/InfoBarView.luau` | Coins + 等级显示 | 常驻 |
| `ActionPanel` View | `src/client/views/ActionPanelView.luau` | 商店/重生按钮 | 常驻 |
| `Overlay` View | `src/client/views/OverlayView.luau` | GOAL! 大标题特效 | 临时 |
| `Toast` View | `src/client/views/ToastView.luau` | 通用提示通知（emoji+标题+富文本正文） | 临时 |

### 8.4 Toast — 通用提示通知组件（新增）

**用途：** 替代当前分散的 `_ShowFloatingText`、`_ShowGoalEffect`、`_ShowTeamComplete`，提供统一的提示通知入口。

#### API 设计

```luau
Toast:Show(options: ToastOptions)

type ToastOptions = {
    emoji: string?,          -- Emoji 前缀（如 "⚽", "🏆", "🎉"）
    title: string,           -- 标题文本（纯文本）
    body: string?,           -- 正文（支持 RichText）
    duration: number?,       -- 显示时长（秒，默认 2）
    position: Vector2?,      -- 屏幕位置比例（默认 0.5, 0.4）
    onComplete: (() -> ())?, -- 动画结束回调
}
```

#### UI 结构

```
ScreenGui
 └─ ToastContainer (Frame, 居中, 自动大小)
     ├─ EmojiLabel (TextLabel)    : emoji 字符, fontSize 40+
     ├─ TitleLabel (TextLabel)    : 标题, 纯文本, fontSize 24, 粗体
     └─ BodyLabel (TextLabel, 可省略) : 正文, RichText 启用, fontSize 18
```

- 进入动画：Scale + Fade (0.3s)
- 离开动画：Fade out + Move up (0.5s)，或根据 duration 自动消失
- 支持队列：连续调用时依次显示，不重叠

#### 使用场景

| 场景 | Emoji | 标题 | 正文 |
| --- | --- | --- | --- |
| 进球 | ⚽ | GOAL! | — |
| 球队完成 | 🏆 | 踢球队完成! | — |
| 升级 | ⬆ | LEVEL UP! | Lv.2 (x1.5) |
| 金币获得 | 💵 | +50 Coins | — |
| NPC 解锁 | 🎉 | Lionel Messi 已解锁! | 品质: <font color="gold">Rare</font> |
| 提示信息 | ℹ | — | 按 <b>E</b> 与 NPC 交互 |

### 8.5 已决策事项

| # | 问题 | 决策 | 日期 |
| --- | --- | --- | --- |
| 1 | 商店点击行为 | 弹出 UI 覆盖层（Overlay Panel） | 2026-06-13 |
| 2 | 重生按钮形式 | 当前保留按钮形式，后续改为场景 NPC 交互 | 2026-06-13 |
| 3 | InfoBar 内容 | 仅显示 Coins + 等级，不加头像/昵称 | 2026-06-13 |
| 4 | CoreBar 左区块 | 留空，最小化 UI，最大化游戏空间 | 2026-06-13 |

---

## 九、实现记录（2026-06-13 第 3-4 步）

### 新增文件

```
src/client/views/
 ├── ToastView.luau        # 通用提示通知组件
 ├── CoreBarView.luau      # 正上居中进度条
 ├── InfoBarView.luau      # 右上角 Coins + 等级
 ├── ActionPanelView.luau  # 右侧居中商店/重生按钮
 └── OverlayView.luau      # GOAL! 进球特效
```

### 修改文件

```
src/client/controllers/UIController.luau  # 重写，组合所有 View
```

### 移除内容

| 内容 | 替代 |
| --- | --- |
| 旧 HUD Frame（顶部黑条含所有子元素） | CoreBarView + InfoBarView |
| UPGRADE 按钮 | ActionPanelView（商店 + 重生） |
| `_UpdateTimeDisplay` / `_FormatTime` | `CoreBarView:UpdateTime()` |
| `_UpdateCoins` / `_UpdateLevel` | `InfoBarView:UpdateCoins/UpdateLevel()` |
| `_ShowFloatingText` / `_ShowTeamComplete` | `ToastView:Show()` |
| `_ShowGoalEffect` | `OverlayView:ShowGoal()` + `ToastView:Show()` |

### 修复

- 恢复 NPCTimerService 的 `OnTimerUpdated`/`OnNPCActivated`/`OnTimerExpired` 信号连接（防止 RemoteEvent 队列溢出）
- `OnNPCActivated` → Toast: "⏳ NPC将在X秒后准备就绪"
- `OnTimerExpired` → Toast: "✅ NPC 已就绪! 按 E 认领"

### 待办

- 商店覆盖层 UI（`SetShopCallback` 已就位，当前弹出 Toast 占位）
- 重生场景内 NPC 交互
