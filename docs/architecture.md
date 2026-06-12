# 自由踢球 — 技术架构文档

## 1. 技术栈

| 层级 | 技术 | 版本 | 用途 |
| --- | --- | --- | --- |
| 语言 | Luau (strict mode) | 0.6+ | 脚本语言 |
| 框架 | Knit | 1.7.0 | 服务端/客户端通信框架 |
| 组件系统 | Component | 2.4.8 | 面向对象实体组件 |
| 事件信号 | Signal | 2.0.3 | 自定义事件总线 |
| 包管理 | Wally + Aftman | latest | 依赖管理 |
| 同步工具 | Rojo | 7.6.1 | 文件系统 ↔ Roblox Studio 同步 |
| 资源管理 | Loader | 2.0.0 | 模块加载与资源预载 |
| 表格工具 | TableUtil | 1.2.1 | 表格操作工具集 |
| 计时器 | Timer | 1.1.2 | 倒计时/周期计时器 |
| 输入管理 | Input | 2.3.0 | 玩家输入处理 |
| 资源清理 | Trove | 1.5.1 | 事件连接与实例清理 |
| 异步编程 | Promise | 4.0.0 | 异步操作编排 |
| 相机震动 | Shake | 1.1.0 | 进球时镜头震动 |
| 条件等待 | WaitFor | 1.0.0 | 等待实例或条件满足 |
| 顶部图标栏 | TopbarPlus | 3.4.0 | 屏幕顶部 UI 图标栏 |
| 连接清理 | Janitor | 1.18.3 | 自动断开事件连接 |
| 背包存储 | Satchel | 1.4.0 | 数据存储与背包管理 |
| 树结构 | Tree | 1.1.0 | 树形数据管理 |
| 深度操作 | Sift | 0.0.11 | 表格深度合并/过滤/映射 |
| 数据持久化 | DataStoreService | Roblox 内置 | 玩家金币与解锁数据存储 |

---

## 2. 项目结构

### 2.1 文件树

```text
world-soccer-cup/
├── default.project.json            # Rojo 开发环境映射
├── deploy.project.json             # Rojo 生产环境映射 (待创建)
├── wally.toml                      # Wally 依赖声明
├── aftman.toml                     # 工具版本管理
├── AGENTS.md                       # AI 协作规范
├── GameConfig.xlsx                 # 游戏配置表格
├── docs/                           # 项目文档
│   ├── game-design.md              # 游戏设计文档
│   ├── architecture.md             # 本文件
│   ├── api-reference.md            # API 参考
│   └── changelog.md                # 变更日志
├── .kilo/                          # Kilo Code 配置
│   ├── agent/                      # Agent 定义
│   ├── commands/                   # 命令定义
│   ├── rules/                      # 规则定义
│   ├── skills/                     # 技能定义
│   └── plans/                      # 计划存档
├── Packages/                       # Wally 安装依赖 (gitignored)
│   ├── Knit/
│   ├── Component/
│   ├── Signal/
│   ├── Loader/
│   ├── TableUtil/
│   ├── Timer/
│   ├── Input/
│   ├── Trove/
│   ├── Promise/
│   ├── Shake/
│   ├── WaitFor/
│   ├── Topbarplus/
│   ├── Janitor/
│   ├── Satchel/
│   ├── Tree/
│   └── Sift/
├── src/
│   ├── shared/                     → ReplicatedStorage.Shared
│   │   ├── configs/                # 数据驱动配置 (空)
│   │   ├── constants/              # 常量和事件名 (空)
│   │   ├── datas/                  # 数据结构模板 (空)
│   │   └── types/                  # Luau 类型定义 (空)
│   ├── server/                     → ServerScriptService.Server
│   │   ├── init.server.luau        # 服务端 Knit 入口
│   │   ├── services/               # Knit Services (空)
│   │   └── components/             # Component 定义 (空)
│   └── client/                     → StarterPlayer.StarterPlayerScripts.Client
│       ├── init.client.luau        # 客户端 Knit 入口
│       └── controllers/            # Knit Controllers (空)
└── scripts/                        # 辅助脚本
```

### 2.2 Rojo 映射关系

| 文件系统路径 | Roblox DataModel 路径 |
| --- | --- |
| `Packages/` | `ReplicatedStorage.Packages` |
| `src/shared/` | `ReplicatedStorage.Shared` |
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |

> **注意**：Studio 中 `Workspace.Field_1`（球场、NPC、球门等）是由 Studio 手动创建的实例，**不应在 src/ 中重复创建**。Rojo 仅管理 ServerScriptService.Server、StarterPlayer.StarterPlayerScripts.Client 和 ReplicatedStorage.Shared 下的脚本逻辑。首次同步前建议手动删除 Studio 中目标目录下的旧子对象，避免 Rojo 合并冲突。

---

## 3. Knit 框架

### 3.1 架构概览

Knit 是本项目的通信骨架。本项目使用以下模式：

- **Service**（服务端）：运行在 `ServerScriptService.Server.services/`，处理所有游戏逻辑（NPC 计时、自动踢球、金币奖励、玩家管理）。客户端通过 `Knit.GetService("XxxService")` 调用公开方法。
- **Controller**（客户端）：运行在 `StarterPlayer.StarterPlayerScripts.Client.controllers/`，处理 UI 更新、镜头控制。
- **Signal**：Service 定义的 `Client.SignalName` 自动成为 RemoteEvent，客户端可监听。
- **Property**：Service 定义的 `Client.PropertyName` 自动成为 RemoteProperty，客户端可读取。

### 3.2 通信模型

```text
┌─────────────────────────────────────────────────────┐
│                      客户端                          │
│  ┌──────────────┐  ┌───────────────┐                 │
│  │ UIController  │  │CameraController│               │
│  └──────┬───────┘  └───────┬───────┘                 │
│         │                  │                         │
│         └──────┬───────────┘                         │
│                │  Knit.GetService():Method()          │
│                │  Service.Signal:Connect()            │
└────────────────┼─────────────────────────────────────┘
                 │ RemoteEvent / RemoteFunction
┌────────────────┼─────────────────────────────────────┐
│                      服务端                          │
│  ┌──────────────┐  ┌────────────┐  ┌───────────────┐│
│  │NPCTimerService│  │AutoKick   │  │RewardService   ││
│  │              │  │Service     │  │PlayerService   ││
│  └──────┬───────┘  └─────┬──────┘  └───────┬───────┘│
│         │                │                  │         │
│         └──────┬─────────┴──────────────────┘         │
│                │                                      │
│         ┌──────┴──────┐                               │
│         │  DataStore  │                               │
│         └─────────────┘                               │
└──────────────────────────────────────────────────────┘
```

### 3.3 服务端入口

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddServicesDeep(script.services)

Knit.Start():catch(warn)
```

### 3.4 客户端入口

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllersDeep(script.controllers)

Knit.Start({ServicePromises = false}):catch(warn):await()
```

### 3.5 Service 模板

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MyService = Knit.CreateService({
    Name = "MyService",

    Client = {
        SomeMethod = function(self, player: Player, arg: any)
            return self.Server:SomeMethod(player, arg)
        end,

        OnEvent = Knit.CreateSignal(),

        SomeProperty = Knit.CreateProperty("default"),
    },

    SomeMethod = function(self, player: Player, arg: any)
        -- 服务端实现
    end,

    KnitInit = function(self)
    end,

    KnitStart = function(self)
    end,
})

return MyService
```

### 3.6 Controller 模板

```lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SomeService = Knit.GetService("SomeService")

local MyController = Knit.CreateController({
    Name = "MyController",

    KnitStart = function(self)
        SomeService.Client.OnEvent:Connect(function(...)
            self:_HandleEvent(...)
        end)
    end,

    _HandleEvent = function(self, ...)
        -- UI 更新或镜头控制
    end,
})

return MyController
```

---

## 4. Service 设计

四种 Service 全部待实现（`src/server/services/` 当前为空）。

### 4.1 NPCTimerService

管理 24 个 NPC 中 3 个活跃 NPC 的轮换计时。每个活跃 NPC 头顶显示倒计时，归零后触发自动接管。

| 方法 | 可见性 | 说明 |
| --- | --- | --- |
| `StartGame()` | 内部 | 在 KnitStart 中调用，初始化 3 个活跃 NPC 槽位并启动第一个计时器 |
| `SelectActiveNPCs()` | 内部 | 从 24 个 NPC 中随机/顺序选取 3 个作为当前活跃 |
| `GetNextNPC()` | 内部 | 当前活跃 NPC 计时结束后，从剩余 21 个中选下一个 |
| `StartTimerForNPC(npcIndex)` | 内部 | 为指定 NPC 启动倒计时（5~10 秒），头顶显示 BillboardGui |
| `OnTimerExpired(npcIndex)` | 内部 | 倒计时归零回调 — 触发自动接管流程 |
| `GetActiveNPCs()` | Client | 返回当前 3 个活跃 NPC 的索引列表 |
| `GetRemainingTime(npcIndex)` | Client | 查询指定 NPC 的剩余倒计时 |

| Client 暴露 | 类型 | 说明 |
| --- | --- | --- |
| `OnTimerUpdated` | Signal | 任意 NPC 计时变化时通知客户端（npcIndex, remainingTime） |
| `OnTimerExpired` | Signal | 某 NPC 计时归零时通知客户端（npcIndex） |
| `OnActiveNPCsChanged` | Signal | 活跃 NPC 列表变化时通知客户端 |

**NPC 槽位数据**：

```lua
type NPCSlot = {
    npcIndex: number,         -- 1~24, 对应 Workspace.Field_1.Player 下的 NPC
    npcInstance: Model,       -- Workspace 中的 NPC 模型引用
    timer: number,            -- 当前倒计时秒数
    state: "waiting" | "active" | "expired",
    billboard: BillboardGui?, -- 头顶倒计时 UI
}
```

**计时器实现**：使用 Knit Timer 库（`Timer` 包）或 `task.delay` 实现倒计时。每 0.1 秒广播剩余时间。

### 4.2 AutoKickService

处理 NPC 到球的自动寻路、踢球动画触发、球飞行和进球检测。这是核心 gameplay 的执行者。

| 方法 | 可见性 | 说明 |
| --- | --- | --- |
| `StartKickSequence(npcIndex)` | 内部 | 接管后启动完整踢球序列 |
| `MovePlayerToNPC(player, npcIndex)` | 内部 | 将玩家角色 tween 移动到 NPC 位置并触发"接管"伪装动画 |
| `FindNearestBall(npcPosition)` | 内部 | 扫描 `ServerStorage.Ball` 中未被使用的球，找最近的 |
| `SpawnBall(ballModel)` | 内部 | 从 ServerStorage.Ball 克隆球到 NPC 脚下 |
| `WalkToBall(npc, ball)` | 内部 | NPC Humanoid 自动行走至球位置（使用 MoveTo + PathfindingService） |
| `PlayKickAnimation(npc)` | 内部 | NPC 上播放踢球动画（AnimationTrack） |
| `KickBall(ball, goalDoor)` | 内部 | TweenService 驱动球沿弧线飞向 `_door` 的 goal_chk |
| `OnGoalDetected(ball, goalChk)` | 内部 | Touch 事件回调 — 判定进球 |
| `CleanupBall(ball)` | 内部 | 进球或出界后回收球（移除实例） |

| Client 暴露 | 类型 | 说明 |
| --- | --- | --- |
| `OnTakeoverNPC` | Signal | 通知客户端当前接管了哪个 NPC（npcIndex） |
| `OnKickStarted` | Signal | 通知客户端踢球动画开始 (npcIndex, ballPosition, targetGoal) |
| `OnBallFlying` | Signal | 球飞行中每帧广播位置（用于镜头跟随） |
| `OnGoalScored` | Signal | 进球通知（coins awarded, npcIndex） |
| `OnKickMissed` | Signal | 未进球通知 |

**单球门**：全场只有 1 个球门 `Workspace.Field_1._door`，球门内有一个 `goal_chk` Part（透明检测器，Size 2×9×24, Anchored, CanTouch=true）。所有球飞行目标均为这个 goal_chk。

**Pathfinding 方案**：使用 `PathfindingService:CreatePath()` + `Humanoid:MoveTo()` 让 NPC 自动走向球。路径规划跨越半场距离（X: NPC 位置 → 球位置）。

**球飞行 Tween**：

```lua
local tween = TweenService:Create(ball.Main, TweenInfo.new(
    1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out
), {CFrame = goalChk.CFrame})
tween:Play()
```

飞行期间激活 Trail 和 Shoot 音效。

**进球检测**：

```lua
ball.Main.Touched:Connect(function(hit)
    if hit.Name == "goal_chk" and hit.Parent.Name == "_door" then
        self:OnGoalDetected(ball, hit)
    end
end)
```

通过 `isFlying` 标志区分飞行中和意外接触。

### 4.3 RewardService

金币结算、等级管理、NPC 品质管理、DataStore 读写、NPC 解锁

| 方法 | 可见性 | 说明 |
| --- | --- | --- |
| `GetPlayerData(player)` | 内部 | 从 DataStore 读取或创建默认 PlayerData |
| `SavePlayerData(player)` | 内部 | 将 PlayerData 写回 DataStore |
| `AwardCoins(player, amount)` | 内部 | 原子增加金币（UpdateAsync） |
| `UnlockNPC(player, npcIndex)` | 内部 | 消耗金币解锁 NPC |
| `SelectActiveNPCs(player, indices)` | 内部 | 保存玩家选择的 3 个活跃 NPC |
| `GetCoins(player)` | Client | 查询金币余额 |
| `IsNPCUnlocked(player, npcIndex)` | Client | 查询 NPC 解锁状态 |

| Client 暴露 | 类型 | 说明 |
| --- | --- | --- |
| `OnCoinsChanged` | Signal | 金币变化时通知客户端（newAmount, delta） |
| `OnNPCUnlocked` | Signal | NPC 解锁时通知（npcIndex, npcName） |

**DataStore 键**：

| DataStore 名称 | 键格式 | 存储内容 |
| --- | --- | --- |
| `PlayerData` | `pdata_{userId}` | 完整 PlayerData JSON 字符串 |

**DataStore 策略**：
- 使用 `DataStoreService:GetDataStore("PlayerData")`
- 玩家加入时 `GetAsync`，离开时 `SetAsync`
- 写入失败重试 3 次（指数退避）
- 金币增减使用 `UpdateAsync` 实现原子操作
- 每 60 秒自动保存缓存数据

### 4.4 PlayerService

玩家会话管理。

| 方法 | 可见性 | 说明 |
| --- | --- | --- |
| `OnPlayerJoin(player)` | 内部 | 连接 `Players.PlayerAdded`，初始化角色，加载数据 |
| `OnPlayerLeave(player)` | 内部 | 连接 `Players.PlayerRemoving`，保存数据 |
| `SetupCharacter(player)` | 内部 | 配置玩家角色（位置到中场、碰撞组等） |
| `RespawnPlayer(player)` | 内部 | 玩家重生处理 |

| Client 暴露 | 类型 | 说明 |
| --- | --- | --- |
| `OnPlayerReady` | Signal | 玩家初始化完成时通知客户端 |

**玩家出生位置**：中场附近 `(0, 5, 0)`，位于球场中圈区域。

---

## 5. Controller 设计

两种 Controller 全部待实现（`src/client/controllers/` 当前为空）。

### 5.1 UIController

管理 HUD 元素：倒计时显示、金币显示、进球特效、接管提示。

| 方法 | 可见性 | 说明 |
| --- | --- | --- |
| `SetupHUD()` | 内部 | 创建 ScreenGui（金币文本、3 个 NPC 计时器、操作提示） |
| `UpdateCoinDisplay(coins)` | 内部 | 更新金币 UI 文本 |
| `UpdateNPCTimers(npcIndex, remainingTime)` | 内部 | 更新指定 NPC 的倒计时显示 |
| `ShowTakeoverEffect(npcIndex)` | 内部 | NPC 接管动画：镜头拉近、文字提示"接管 XX！" |
| `ShowGoalEffect(coins)` | 内部 | 进球特效：屏幕闪光 + "Goal!" + 金币弹出动画 |
| `ShowKickMissed()` | 内部 | 未进球提示 |
| `ShowNPCActiveIndicators(activeIndices)` | 内部 | 标记当前 3 个活跃 NPC |

| 监听的服务 | Signal/Property |
| --- | --- |
| NPCTimerService | `OnTimerUpdated` — 更新倒计时 |
| NPCTimerService | `OnTimerExpired` — 触发接管过渡 |
| AutoKickService | `OnGoalScored` — 进球特效 |
| AutoKickService | `OnKickMissed` — 未进球提示 |
| RewardService | `OnCoinsChanged` — 更新金币显示 |

### 5.2 CameraController

镜头控制：自由视角 → NPC 接管特写 → 跟随球飞行 → 进球回放。

| 方法 | 可见性 | 说明 |
| --- | --- | --- |
| `SetupDefaultCamera()` | 内部 | 设置默认自由相机（第三人称俯视半场视角） |
| `FocusOnNPC(npcPosition)` | 内部 | NPC 接管时将镜头推近到 NPC 附近 |
| `FollowBall(ballPosition)` | 内部 | 球飞行时镜头跟随球 |
| `GoalReplay()` | 内部 | 进球后慢动作镜头回放（3 秒） |
| `ReturnToDefault()` | 内部 | 回放结束后恢复默认视角 |

| 监听 | 说明 |
| --- | --- |
| AutoKickService `OnTakeoverNPC` | 镜头聚焦到 NPC |
| AutoKickService `OnKickStarted` | 镜头切换到踢球视角 |
| AutoKickService `OnBallFlying` | 镜头跟随球飞行 |
| AutoKickService `OnGoalScored` | 触发进球回放 |

---

## 6. 游戏状态机

```text
                        ┌──────────────────┐
                        │      Idle        │ ← 玩家出生，初始状态
                        └────────┬─────────┘
                                 │ NPCTimerService 启动 3 个计时器
                                 ▼
                        ┌──────────────────┐
                 ┌──────│   TimerRunning   │ ← 3 个 NPC 头顶显示倒计时
                 │      └────────┬─────────┘
                 │               │ 某 NPC 计时归零
                 │               ▼
                 │      ┌──────────────────┐
                 │      │   TimerExpired   │ ← 确定要接管的 NPC
                 │      └────────┬─────────┘
                 │               │ AutoKickService.MovePlayerToNPC()
                 │               ▼
                 │      ┌──────────────────┐
                 │      │   MoveToNPC      │ ← 玩家角色自动移动到 NPC 位置
                 │      └────────┬─────────┘
                 │               │ NPC 位置到达
                 │               ▼
                 │      ┌──────────────────┐
                 │      │ FindNearestBall  │ ← NPC 扫描附近最近的球
                 │      └────────┬─────────┘
                 │               │ 找到球，从 ServerStorage 克隆到场内
                 │               ▼
                 │      ┌──────────────────┐
                 │      │   WalkToBall     │ ← NPC 自动行走至球位置
                 │      └────────┬─────────┘
                 │               │ 到达球位置
                 │               ▼
                 │      ┌──────────────────┐
                 │      │  KickAnimation   │ ← NPC 播放踢球动画
                 │      └────────┬─────────┘
                 │               │ 动画触发 Tween
                 │               ▼
                 │      ┌──────────────────┐
                 │      │   BallFlying     │ ← 球沿弧线飞向球门 goal_chk
                 │      └────────┬─────────┘
                 │               │ 到达 goal_chk / Touch 事件
                 │               ▼
                 │      ┌──────────────────┐
                 │      │  GoalDetected    │ ← 检测是否碰到 goal_chk
                 │      └────────┬─────────┘
                 │          ┌────┴────┐
                 │          ▼         ▼
                 │  ┌────────────┐ ┌──────────┐
                 │  │ AwardCoins │ │  Miss    │ ← 未进球
                 │  │ +Coins UI  │ │ 清理球   │
                 │  └─────┬──────┘ └────┬─────┘
│        │             │
│        ▼             ▼
│  ┌────────────────────────────────────┐
│  │         CheckLevelUp              │ ← 检查是否可升级, 显示升级选项
│  └─────────────┬──────────────────────┘
│                │
│                ▼
│  ┌────────────────────────────────────┐
│  │         NextTimer                  │ ← 返回 TimerRunning，
│  │  从剩余 NPC 中选下一个激活          │    进入下一轮
└──│  新 NPC 头顶开始倒计时              │
                    └────────────────────────────────────┘
```

### 状态说明

| 状态 | 持续时间 | 说明 |
| --- | --- | --- |
| Idle | 玩家刚出生 | 初始化游戏，准备第一轮 NPC |
| TimerRunning | 5~10 秒 | 3 个 NPC 同时倒计时，玩家可以自由移动 |
| TimerExpired | 瞬发 | 第一个归零的 NPC 触发接管 |
| MoveToNPC | ~1 秒 | 玩家角色 tween 移动到 NPC 位置 |
| FindNearestBall | ~0.3 秒 | 扫描 45 个球模型，找最近的克隆 |
| WalkToBall | 1~3 秒 | NPC 寻路走到球位置 |
| KickAnimation | ~1 秒 | 播放踢球动画 |
| BallFlying | 1~2 秒 | Tween 飞行到 goal_chk |
| GoalDetected | 瞬发 | Touch 事件判定 |
| AwardCoins | ~2 秒 | 金币增加 + UI 特效 |
| NextTimer | ~1 秒 | 选下一个 NPC，开始新倒计时 |

---

## 7. 数据架构

### 7.1 玩家数据结构

```lua
type PlayerData = {
    Coins: number,
    Level: number,
    NPCTiers: { [string]: number },  -- npcId → quality level (1~5)
    UnlockedNPCs: { string },
    ActiveSlots: { string },  -- 3 NPC IDs currently active on field
}
```

### 7.2 NPC 配置格式

```lua
type NPCConfig = {
    index: number,           -- 1~24
    name: string,            -- "Lionel Messi"
    instancePath: string,    -- "Workspace.Field_1.Player.Messi"
    displayName: string,     -- "梅西" (中文显示名)
    unlockCost: number,      -- 解锁所需金币 (0 = 默认解锁)
    kickAnimationId: string, -- 踢球动画 AnimationId
    timerDuration: number,   -- 倒计时秒数 (默认 8)
}
```

### 7.3 游戏状态枚举

```lua
type GameState = "Idle"
    | "TimerRunning"
    | "TimerExpired"
    | "MoveToNPC"
    | "FindNearestBall"
    | "WalkToBall"
    | "KickAnimation"
    | "BallFlying"
    | "GoalDetected"
    | "AwardCoins"
    | "NextTimer"
```

### 7.4 事件名常量

```lua
-- NPCTimerService events (shared/constants/)
local NPC_TIMER_EVENTS = {
    TIMER_UPDATED = "NPCTimer_TimerUpdated",
    TIMER_EXPIRED = "NPCTimer_TimerExpired",
    ACTIVE_NPCS_CHANGED = "NPCTimer_ActiveNPCsChanged",
}

-- AutoKickService events
local AUTO_KICK_EVENTS = {
    TAKEOVER_NPC = "AutoKick_TakeoverNPC",
    KICK_STARTED = "AutoKick_KickStarted",
    BALL_FLYING = "AutoKick_BallFlying",
    GOAL_SCORED = "AutoKick_GoalScored",
    KICK_MISSED = "AutoKick_KickMissed",
}

-- RewardService events
local REWARD_EVENTS = {
    COINS_CHANGED = "Reward_CoinsChanged",
    NPC_UNLOCKED = "Reward_NPCUnlocked",
}

-- PlayerService events
local PLAYER_EVENTS = {
    PLAYER_READY = "Player_Ready",
}
```

### 7.5 DataStore 键

| DataStore 名称 | 键格式 | 存储内容 |
| --- | --- | --- |
| PlayerData | PlayerData_<userId> | JSON 对象含 Coins / Level / NPCTiers / UnlockedNPCs |

### 7.6 数据流

```text
玩家进入     → PlayerService          → DataStore:GetAsync → 缓存到内存
NPC 进球     → AutoKickService        → 通知 RewardService
             → RewardService          → UpdateAsync 原子增加 Coins
             → RewardService          → Signal OnCoinsChanged → UIController 更新显示
玩家离开     → PlayerService          → DataStore:SetAsync 写入
周期存档     → RewardService          → 每 60 秒自动保存
```

---

## 8. 现场实例说明（Studio 中已存在，src/ 不重复创建）

| 路径 | 内容 | 说明 |
| --- | --- | --- |
| `Workspace.Field_1` | 半足球场 | 包含场地、边线、禁区、中圈等部件 |
| `Workspace.Field_1._door` | 球门 | 单个球门，内含 `goal_chk` Part（2×9×24, Anchored, CanTouch=true, Transparent） |
| `Workspace.Field_1.Player` | 24 个 NPC | 著名球星 R15 模型（Messi, Ronaldo 等），Anchored |
| `ServerStorage.Ball` | 45 个球模型 | 每个含 E_Ball(ProximityPrompt)、Main(MeshPart)、Trail、Shoot 音效 |
| `ServerStorage.Goal` | 44 个球门模型 | 门模板，存储在 ServerStorage 中（当前未使用——仅用 _door） |
| `ReplicatedStorage.Packages` | Wally 包 | Knit, Component, Timer 等依赖包 |

> **关键**：Studio 中只有 1 个球门 `_door` 在球门线上使用。`ServerStorage.Goal` 中的 44 个球门模型作为模板保留，当前未在运行中使用。

---

## 9. 安全设计

| 措施 | 说明 |
| --- | --- |
| 服务端权威计时 | NPC 计时器完全在服务端运行，客户端仅接收广播 |
| 服务端权威踢球 | 踢球序列（寻路 → 动画 → Tween）全在服务端执行 |
| 服务端权威金币 | 金币变更仅通过 `DataStore:UpdateAsync()` 在服务端原子执行 |
| 飞行路径服务端计算 | Tween 在服务端执行，客户端仅接收位置广播用于镜头跟随 |
| 碰撞检测服务端执行 | Touch 事件在球的服务端脚本中处理 |
| DataStore 原子操作 | 使用 `UpdateAsync` 替代 `GetAsync` + `SetAsync` 组合 |
| 写入失败重试 | 指数退避重试机制（3 次），避免 DataStore 限流 |
| 玩家离开即时保存 | `Players.PlayerRemoving` 事件中确保数据落盘 |

---

## 10. 开发路线图

### 10.1 第一阶段 — 核心循环

| 任务 | 说明 |
| --- | --- |
| shared/types/ | 定义 PlayerTypes、NPCTypes、GameTypes |
| shared/constants/ | 定义事件名常量 |
| NPCTimerService | 3 个 NPC 槽位、倒计时管理、自动接管 |
| AutoKickService | NPC 寻路到球 + Tween 飞行 + goal_chk 进球检测 |
| RewardService | Coins 管理 + DataStore 读写 |
| PlayerService | 玩家加入/离开 + 角色初始化 |
| 完整循环 | Idle → TimerRunning → MoveToNPC → WalkToBall → Kick → BallFlying → Goal → Coins |

### 10.2 第二阶段 — UI 与反馈

| 任务 | 说明 |
| --- | --- |
| UIController | HUD（金币、3 个倒计时、接管提示） |
| CameraController | 自由镜头 → NPC 聚焦 → 跟随球 → 进球回放 |
| 进球特效 | 屏幕闪光 + "Goal!" 文字 + 金币弹出动画 |
| NPC BillboardGui | 头顶倒计时显示 |
| 等级系统 UI | 升级面板、经验条显示、等级提升特效 |
| NPC 品质系统 | NPC 品质等级提升界面、品质升级消耗 UI |

### 10.3 第三阶段 — 角色与商店

| 任务 | 说明 |
| --- | --- |
| NPC 解锁系统 | 消耗 Coins 解锁新 NPC |
| NPC 选择 UI | 选择 3 个活跃 NPC |
| 接管动画 | 玩家角色"变为"NPC 的视觉过渡 |
| 球皮肤系统 | 可购买不同外观的球（从 ServerStorage.Ball 选） |

### 10.4 第四阶段 — 打磨

| 任务 | 说明 |
| --- | --- |
| 排行榜 | DataStore 存储总进球数 |
| 每日奖励 | 登录奖励、每日挑战 |
| 设置界面 | 音量、画质 |
| 性能优化 | 碰撞组、对象池、NPC 动画缓存 |
| 多语言 | 中文 + 英文 |

---

## 11. 命名规范

| 类型 | 命名格式 | 示例 |
| --- | --- | --- |
| Knit Service | `XxxService` | `NPCTimerService`, `AutoKickService` |
| Knit Controller | `XxxController` | `UIController`, `CameraController` |
| Component | `Xxx` (语义名) | `NPCSlot`, `KickSequence` |
| 服务端脚本 | `*.server.luau` | `init.server.luau` |
| 客户端脚本 | `*.client.luau` | `init.client.luau` |
| 模块脚本 | `init.luau` | 文件夹内的入口 |
| 事件名 | `PascalCase` | `OnGoalScored`, `OnCoinsChanged` |
| 常量 | `UPPER_SNAKE_CASE` | `NPC_COUNT`, `TIMER_DURATION` |
| 类型定义 | `XxxTypes` | `PlayerDataTypes` |
| 文件夹 | `PascalCase` | `services/`, `controllers/` |

---

## 12. 依赖清单

| 包名 | 版本 | 用途 |
| --- | --- | --- |
| Knit | 1.7.0 | 服务端/客户端通信框架 |
| Component | 2.4.8 | 实体组件系统 |
| Signal | 2.0.3 | 事件信号 |
| Loader | 2.0.0 | 模块加载管理 |
| Trove | 1.5.1 | 资源清理 |
| Promise | 4.0.0 | 异步 Promise |
| Input | 2.3.0 | 输入管理 |
| Timer | 1.1.2 | 计时器/倒计时 |
| TableUtil | 1.2.1 | 表格工具 |
| Shake | 1.1.0 | 相机震动 |
| TopbarPlus | 3.4.0 | 顶部图标栏 |
| Janitor | 1.18.3 | 事件连接清理 |
| Satchel | 1.4.0 | 背包管理 |
| Tree | 1.1.0 | 树形数据结构 |
| Sift | 0.0.11 | 表过滤/映射/深度合并 |
| WaitFor | 1.0.0 | 条件等待 |

---

文档版本: v2.0
最后更新: 2026-06-12
