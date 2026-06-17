# UI 设计文档

> 本文档记录所有 UI 组件的设计规范、实现细节和交互流程。
> 维护者：开发团队
> 最后更新：2026-06-15

---

## 1. 总览

### 1.1 UI 组件目录

| 组件 | 文件 | 类型 | 职责 |
| --- | --- | --- | --- |
| UIController | `src/client/controllers/UIController.luau` | Knit Controller | 主 HUD 管理器，组合所有 View |
| CoreBarView | `src/client/views/CoreBarView.luau` | View | 正上居中：在线时长进度条 + 计时器 + 圆点 |
| InfoBarView | `src/client/views/InfoBarView.luau` | View | 右上角：Coins + 等级 Lv.X (xY.Z) |
| ActionPanelView | `src/client/views/ActionPanelView.luau` | View | 右侧居中：商店/重生功能按钮 |
| OverlayView | `src/client/views/OverlayView.luau` | View | 屏幕居中：GOAL! 进球特效 |
| ToastView | `src/client/views/ToastView.luau` | View | 通用提示通知（带队列） |
| ShopView | `src/client/views/ShopView.luau` | View | 商店覆盖层面板（商品 + 特权） |

### 1.2 UI 层级结构

```
PlayerGui (Players.LocalPlayer)
 └─ FreeKickHUD (ScreenGui, ResetOnSpawn=false)
     ├─ CoreBar (Frame, 正上居中)
     ├─ InfoBar (Frame, 右上角)
     ├─ ActionPanel (Frame, 右侧居中)
     │   ├─ ShopButton "🏪 Shop"
     │   ├─ PitchButton "🏟️ Pitch"
     │   └─ RebirthButton "🔄 Rebirth"
     ├─ GoalOverlay (Frame, 居中, ZIndex=10, 初始隐藏)
     ├─ ToastContainer (Frame, ZIndex=49, 弹出通知)
     └─ ShopOverlay (Frame, 全屏, ZIndex=20, 初始隐藏)
         └─ ShopPanel (Frame, 居中)
             ├─ CloseBtn (TextButton)
             ├─ Title "🏪 商店"
             ├─ CoinsLabel "💵 XXXX"
             ├─ TabBar
             │   ├─ ProductsTab "📦 商品"
             │   └─ GamePassesTab "⭐ 特权"
             ├─ ItemContainer (ScrollingFrame)
             │   └─ ItemCard × N
             └─ StatusBar (TextLabel)
```

---

## 2. UIController (`src/client/controllers/UIController.luau`)

### 2.1 职责

- 创建 ScreenGui 并挂载所有 View
- 轮询服务器数据（每 1 秒）：Coins、Level、在线时间
- 监听 Knit Service 信号：进球、NPC 计时器、商店购买
- 协调 View 之间的通信（如购买后刷新金币显示）

### 2.2 数据流

```
服务端 ──Knit──→ 客户端
  RewardService.GetCoins()     → UIController 轮询 → InfoBarView:UpdateCoins()
  RewardService.GetLevel()     → UIController 轮询 → InfoBarView:UpdateLevel()
  NPCProgressService.GetElapsedTime() → UIController 轮询 → CoreBarView:UpdateTime()
  AutoKickService.OnGoalScored → UIController 信号 → OverlayView:ShowGoal() + ToastView:Show()
  NPCTimerService.OnNPCActivated  → ToastView:Show()
  NPCTimerService.OnTimerExpired  → ToastView:Show()
  ShopService.OnPurchaseComplete   → ShopView 信号 → ShopView 刷新
  ShopService.OnPurchaseFailed     → ShopView 信号 → ShopView 显示错误
```

### 2.3 轮询机制

| 数据 | 频率 | 方法 |
| --- | --- | --- |
| Coins | 1 秒 | `GetCoins()` |
| Level | 1 秒 | `GetLevel()`（仅在变化时更新） |
| 在线时间 | 1 秒 | `GetElapsedTime()` |

---

## 3. ShopView（商店 UI）

### 3.1 设计概览

商店以**全屏覆盖层面板**形式呈现，点击右侧 ActionPanel 的「商店」按钮打开。

**布局：**

```
┌──────────────────────────────────────────────────┐
│  ╱╱ 半透明黑色遮罩 (BackgroundTransparency=0.6)  ╱╱│
│                                                    │
│          ┌──────────────────────────────┐          │
│          │      🏪 商店             ✕   │          │
│          │  💵 1500                     │          │
│          │  ┌──────┐ ┌──────┐          │          │
│          │  │📦商品│ │⭐特权│          │          │
│          │  └──────┘ └──────┘          │          │
│          │                              │          │
│          │  ┌────────────────────────┐  │          │
│          │  │ 🔷  │ Double Coins     │  │          │
│          │  │      │ 2x 进球金币   💵2000 [购买]│  │
│          │  ├────────────────────────┤  │          │
│          │  │ ❤️‍🔥│ Extra Stamina    │  │          │
│          │  │      │ 200 最大体力 💵1500 [购买]│  │
│          │  └────────────────────────┘  │          │
│          │                              │          │
│          │       [状态提示文字]         │          │
│          └──────────────────────────────┘          │
└──────────────────────────────────────────────────┘
```

### 3.2 面板规格

| 属性 | 值 |
| --- | --- |
| 面板尺寸 | 520 × 460 |
| 面板圆角 | 12 px |
| 背景色 | `Color3(0.06, 0.06, 0.14)` 透明度 0.05 |
| 遮罩背景 | `Color3(0, 0, 0)` 透明度 0.6 |
| ZIndex | 面板 25，遮罩 20，按钮 30 |
| 打开动画 | Slide-in (0.25s, Quad Out) |

### 3.3 Tab 页

| Tab | 按钮文本 | 数据源 | 购买货币 |
| --- | --- | --- | --- |
| Products | "📦 商品" | `Products.luau` | 💎 Robux |
| GamePasses | "⭐ 特权" | `GamePasses.luau` | 💵 Coins / 💎 Robux |

### 3.4 ItemCard 设计

每个商品卡片：

```
┌─────────────────────────────────────────────────┐
│ ┌────┐  Double Coins                    💵 2000 │
│ │ 🔷 │  Earn 2x coins from goals      [购买]   │
│ └────┘                                           │
└─────────────────────────────────────────────────┘
```

| 元素 | 规格 |
| --- | --- |
| 卡片尺寸 | 全宽 × 72 px |
| 卡片圆角 | 8 px |
| 图标区域 | 44 × 44 px，圆角 8 px |
| 名称 | 左侧，粗体，白色 |
| 描述 | 名称下方，灰色 `(0.7, 0.7, 0.85)` |
| 价格 | 右上，金色（💵）或蓝色（💎） |
| 购买按钮 | 右下，70 × 28 px，圆角 6 px |

### 3.5 购买流程

```
用户点击 [购买]
    │
    ├── Product 类型 ──→ MarketplaceService:PromptProductPurchase()
    │                       │
    │                       ▼
    │                  Roblox 购买弹窗
    │                       │
    │                       ▼
    │                  Server.ProcessReceipt 回调
    │                       │
    │                       ▼
    │                  ShopService:_GrantProduct()
    │                       │
    │                       ▼
    │                  OnPurchaseComplete Signal
    │                       │
    │                       ▼
    │                  ShopView 刷新 UI
    │
    └── GamePass 类型
            │
            ├── Coins 支付 ──→ ShopService:PurchaseWithCoins()
            │                     │
            │                     ▼
            │                验证余额 → 扣减 Coins
            │                     │
            │                     ▼
            │                授予 GamePass 所有权
            │                     │
            │                     ▼
            │                OnPurchaseComplete Signal
            │                     │
            │                     ▼
            │                ShopView 刷新 UI
            │
            └── Robux 支付 ──→ MarketplaceService:PromptGamePassPurchase()
                                  │
                                  ▼
                            同 Product 流程
```

### 3.6 状态与错误处理

| 状态 | 显示 |
| --- | --- |
| 购买成功 | 绿色状态栏 "✅ XXX 购买成功!"，3 秒后消失 |
| 余额不足 | 红色状态栏 "❌ Insufficient coins" |
| 已拥有 | 卡片显示绿色「已拥有」标签，隐藏购买按钮 |
| Robux 购买进行中 | Roblox 原生弹窗 |
| 服务端错误 | 红色状态栏 "❌ 错误信息" |

---

## 4. CoreBarView（在线进度条）

### 4.1 UI 结构

```
CoreBar (Frame, 860×170, 正上居中 y=6)
 ├─ TimerLabel (TextLabel, "00:00", TextSize=16, 居中顶部)
 ├─ Dot_1 ~ Dot_10 (Frame, 50×50 圆角)
 │   ├─ UICorner (Radius=10)
 │   ├─ UIStroke (边框，解锁时变金色)
 │   ├─ ViewportFrame (44×44, RoundCorner)
 │   │   ├─ WorldModel (NPCHead)
 │   │   │   └─ Placeholder (Sphere, 1×1×1, 彩色)
 │   │   ├─ HeadCam (Camera, FOV=30, 对准头部)
 │   │   └─ VPFLighting
 │   └─ Name (TextLabel, NPC 名称)
 ├─ TrackBg (Frame, 760×5, 底部)
 │   └─ TrackFill (Frame, 绿→金→橙渐变)
```

### 4.2 Dot 状态

| 状态 | 圆点底色 | 边框 | VPF 内球颜色 | 名称 |
| --- | --- | --- | --- | --- |
| 已解锁 | 深蓝 | 金色 2px | 每个 NPC 独有色 | 白色不透明 |
| 解锁中 | 暗蓝 | 半透 2px | 灰 | 半透明 |
| 未解锁 | 深灰 | 高透 1.5px | 深灰 | 高透 |

### 4.3 解锁计时

- 全部 10 个 NPC 从 0 开始解锁
- 每 `300/10 = 30s` 解锁一个
- 前 3 个 NPC CD 同样计入（不预点亮）
- 第 10 个 NPC 在 t=300s 与进度条同时满

---

## 5. InfoBarView（信息栏）

### 5.1 UI 结构

```
InfoBar (Frame, 150×52, 右上 y=10, x=-162)
 ├─ CoinsLabel "💵 0"
 └─ LevelLabel "Lv.1 (x1.0)"
```

### 5.2 数据更新

| 标签 | 内容格式 | 更新触发 |
| --- | --- | --- |
| CoinsLabel | `💵 {coins}` | 每秒轮询 |
| LevelLabel | `Lv.{level} (x{multiplier})` | 仅等级变化时 |

---

## 6. ActionPanelView（操作面板）

### 6.1 UI 结构

```
ActionPanel (Frame, 110×160, 右侧居中 y=-80)
 ├─ ShopButton "🏪 Shop" (绿渐变)
 ├─ PitchButton "🏟️ Pitch" (蓝渐变)
 └─ RebirthButton "🔄 Rebirth" (红渐变)
```

### 6.2 交互

| 操作 | 效果 |
| --- | --- |
| 鼠标悬停 | 透明度降低，尺寸微增 (0.2s tween) |
| 点击 Shop | 打开 ShopView 覆盖层 |
| 点击 Pitch | 本地玩家传送到自己场地 `Field_X.Ground` 位置 |
| 点击 Rebirth | Toast 提示"Coming soon..."（TODO） |

---

## 7. OverlayView（进球特效）

### 7.1 UI 结构

```
GoalOverlay (Frame, 全屏, ZIndex=10, 初始隐藏)
 ├─ GoalLabel "GOAL!" (TextLabel, 500×120, 居中)
 └─ GoalShadow "GOAL!" (TextLabel, 阴影层)
```

### 7.2 动画序列

| 阶段 | 时长 | 效果 |
| --- | --- | --- |
| 缩放入场 | 0.35s | Back Out 缓动，从 500×120 到 620×150 |
| 停留 | 0.8s | 保持 |
| 淡出上移 | 1s | 透明度 → 1，位置上移至 25% |

---

## 8. ToastView（通知队列）

### 8.1 API

```luau
type ToastOptions = {
    emoji: string?,          -- Emoji 前缀
    title: string,           -- 标题
    body: string?,           -- 正文 (RichText 支持)
    duration: number?,       -- 显示时长（默认 2 秒）
    position: Vector2?,      -- 屏幕位置比例（默认 0.5, 0.38）
    onComplete: (() -> ())?, -- 动画结束回调
}
```

### 8.2 场景列表

| 场景 | Emoji | 标题 | 正文 |
| --- | --- | --- | --- |
| 进球 | ⚽ | GOAL! | — |
| 球队完成 | 🏆 | 踢球队完成! | — |
| 升级 | ⬆ | LEVEL UP! | Lv.2 (x1.5) |
| 金币获得 | 💵 | +50 Coins | — |
| NPC 解锁 | 🎉 | Lionel Messi 已解锁! | 品质: Rare |
| NPC 就绪 | ⏳ | {name} | 将在 X 秒后准备就绪 |
| NPC 可认领 | ✅ | {name} | 已就绪! 按 E 认领 |
| 提示信息 | ℹ | — | 按 E 与 NPC 交互 |
| 商店通知 | 🏪 | 商店 | 使用 ShopView 覆盖层替代 |

---

## 9. 设计原则

1. **一致性**：所有面板使用相同的圆角(8-12px)、字体(Gotham)、颜色体系
2. **性能**：避免频繁的 Instance 创建/销毁（ShopView 在打开/关闭时复用）
3. **可访问性**：所有按钮有足够的点击区域 (44px+)
4. **反馈**：每个用户操作都有视觉反馈（悬停、点击、状态提示）
5. **不侵入**：UI 不遮挡核心游戏区域（仅边缘和覆盖层）

### 9.1 字体与特殊字符

- 按钮/标签文本优先使用 **ASCII 安全字符**（A-Z, 0-9, 标点）
- 非 ASCII 特殊字符（如 Unicode 符号 `✕` `↩` `✔`）在 Roblox 不同字体下 **渲染不稳定**，禁止使用
- 关闭按钮统一用大写 `X` 代替 `✕`，方向/确认等用文本替代特殊符号
- Emoji 字符（💵💵⭐📦🏪🔄）在 Roblox 下渲染可靠，可继续使用

## 10. 颜色体系

| 用途 | Color3 | 说明 |
| --- | --- | --- |
| 面板背景深色 | (0.06, 0.06, 0.14) | 主面板底色 |
| 面板背景亮色 | (0.1, 0.1, 0.2) | 渐变上部 |
| 面板背景暗色 | (0.04, 0.04, 0.1) | 渐变下部 |
| 卡片底色 | (0.08, 0.08, 0.16) | 商品卡片 |
| Tab 非活跃 | (0.15, 0.15, 0.25) | 未选中 Tab |
| Tab 活跃 | (0.25, 0.25, 0.4) | 选中 Tab |
| 描线 | (0.35, 0.35, 0.65) | 面板边框 |
| 描线(卡片) | (0.3, 0.3, 0.5) | 卡片边框 |
| 金色 | (1, 0.9, 0.1) | Coins 显示 |
| 蓝色 | (0.6, 0.8, 1) | Robux 价格 |
| 绿色按钮 | (0.1, 0.35, 0.6) | 购买/商店 |
| 红色按钮 | (0.55, 0.15, 0.15) | 重生 |
| 已拥有 | (0.3, 1, 0.3) | 已解锁标签 |

---

## 11. 版本历史

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-06-15 | v1.0 | 初版：完整 UI 体系文档，含 ShopView 设计 |

---
