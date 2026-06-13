# 自由踢球 — 游戏设计文档

## 1. 游戏概述

### 1.1 基本信息

| 项目 | 内容 |
| --- | --- |
| 游戏名称 | 自由踢球 |
| 游戏类型 | 半挂机自由踢自动进球（Semi-idle Free Kick Auto-scoring） |
| 目标平台 | Roblox（PC / 移动端 / 主机） |
| 目标玩家 | 单人 |
| 美术风格 | Low-poly 卡通风格 |

### 1.2 核心体验

玩家分配到专属半球场（从 6 个克隆场中），场上按槽位（3 个）轮转出现 10 位球星 NPC，每位头顶倒计时。倒计时归零后 NPC 自动走向最近足球、播放踢球动画、球弧线射入球门。每次进球获得 Coins。整个过程半挂机——玩家无需手动操作射门，可以自由走动，靠近球时自动触发踢球。

### 1.3 核心循环

```
10 NPC 预分配 → 3 槽位错开倒计时(60s/120s/180s) → 到期 NPC 自动走向球 → 踢球 → 进球 → 品质 CD 自动再循环 → 槽位补位 (90s CD)
10 分钟后 10 NPC + 玩家组成踢球队 → 完成大任务
```

---

## 2. 场地布局

### 2.1 多场布局

服务器启动时从 `Workspace.Field_1` 模板克隆 **6 个球场**，分两列（Row A X=-10 正常、Row B X=10 绕 Y 旋转 180°），Z 轴排开（-112/0/112）。
球门相对、行走区居中，玩家被分配一个专属场。

### 2.2 单场尺寸

| 参数 | 值 |
| --- | --- |
| 场地中心 | (0, 0, 0) 相对模板 |
| X 轴跨度 | ~116 studs |
| Z 轴跨度 | ~140 studs |
| 球门位置 | X≈116, Z≈0（正常朝向） |
| 禁区 | X≈70-105 |
| 格位 | 3 个占位块（Part），策划可拖拽调整位置 |

### 2.3 场主标牌

每个球场中心上方 30 studs 有一个 `FieldOwnerGui` BillboardGui（头像+名字），默认隐藏，分配玩家后显示。

---

## 3. 核心机制

### 3.1 游戏状态机

```
Idle
  │
  ▼
3 NPC 倒计时运行（头顶 BillboardGui 显示剩余秒数）
  │
  ▼（任一 NPC 倒计时 = 0）
Player 自动移至目标 NPC 位置（"吃球员" / Take Over）
  │
  ▼
NPC 自动寻路至禁区内最近的一颗球
  │
  ▼
NPC 播放踢球动画（Humanoid 动画）
  │
  ▼
球沿弧线/抛物线飞入球门（Tween / Lerp）
  │
  ▼
goal_chk.Touched 检测 → 判定进球
  │
  ▼
Coins 增加 → 下一 NPC 倒计时开始
```

### 3.2 NPC 倒计时系统

| 参数 | 值 |
| --- | --- |
| 同时活跃 NPC 数 | 3 |
| 倒计时范围 | 可配置（例：15~30 秒随机） |
| 显示方式 | 头顶 BillboardGui |
| 倒计时归零触发 | 玩家自动移至该 NPC |

### 3.3 自动吃球员（Auto Take-over）

当 NPC 倒计时归零时：

| 步骤 | 描述 |
| --- | --- |
| 1 | 服务器将玩家角色移至 NPC 所在位置 |
| 2 | NPC 设为活跃状态 |
| 3 | NPC 开始自动寻路到禁区内最近的球 |

### 3.4 自动寻球

NPC 激活后：

| 步骤 | 描述 |
| --- | --- |
| 1 | 扫描 `ServerStorage.Ball` 中所有球，或在禁区内查找已放置的球 |
| 2 | 计算距离最近的球（使用 `(pos - ballPos).Magnitude`） |
| 3 | NPC 通过 PathfindingService 或简单步行移动到球所在位置 |
| 4 | 到达球附近后触发踢球动画 |

### 3.5 自动踢球

NPC 到达球位置后：

| 参数 | 值 |
| --- | --- |
| 触发方式 | 自动（无需玩家按键） |
| 动画 | NPC Humanoid 播放预设踢球动画 |
| 球飞行 | 从当前位置沿弧线飞入球门（~1~2 秒） |
| 运动类型 | 弧线/抛物线（TweenService 或自定义 Lerp） |

### 3.6 进球检测

唯一球门 `Workspace.Field_1._door` 内含 `goal_chk` 部件：

| 属性 | 值 |
| --- | --- |
| ClassName | Part |
| 大小 | 2 × 9 × 24 studs |
| Anchored | true |
| CanTouch | true |
| Transparent | true（不可见检测器） |

当球的 `Main` MeshPart 与 `goal_chk` 发生 Touch 事件时，判定为进球。

### 3.7 奖励发放

| 结果 | 操作 |
| --- | --- |
| 进球 | +Coins、播放进球特效、更新 UI |
| 未进球 | 球飞出边界后消失，等待下一轮 NPC 循环 |
| 结算 | Coins 累加到玩家数据并写入 DataStore |

---

## 4. 球系统

### 4.1 球模型结构

每个球模型（`ServerStorage.Ball.ballN`）包含：

| 部件 | 类型 | 说明 |
| --- | --- | --- |
| E_Ball | Part + ProximityPrompt | 触发器部件（保留但非核心交互入口） |
| Highlight | Highlight | 球体高亮 |
| Main | MeshPart | 球体主体，size 2×2×2 |
| Main.Shoot | Sound | 射门音效（×2 个） |
| Main.Trail | Trail | 飞行轨迹尾迹 |
| Main.Attachment1 | Attachment | Trail 起点 |
| Main.Attachment2 | Attachment | Trail 终点 |
| Main.Center | Attachment | 球体中心参考点 |
| Main.gui_bomb | BillboardGui | 球上的炸弹图标 GUI |

### 4.2 Main 部件属性

| 属性 | 值 |
| --- | --- |
| Size | 2, 2, 2 |
| MeshId | rbxassetid://433989406 |
| TextureId | rbxassetid://433989409 |
| Material | Glass |
| Massless | true |
| CollisionGroup | "Ball" |
| CanCollide | false（飞行中） |

### 4.3 球清单

`ServerStorage.Ball` 下有 45 个球模型：

| 球编号 | 数量 | 说明 |
| --- | --- | --- |
| ball1 ~ ball44 | 44 | 44 种球 |
| ball422 | 1 | 额外球 |

### 4.4 碰撞组

球使用独立碰撞组 `"Ball"`，避免与角色或其他物理对象发生碰撞，仅用于 Touch 检测进球。

---

## 5. 球门系统

### 5.1 唯一球门

| 属性 | 值 |
| --- | --- |
| 实例路径 | `Workspace.Field_1._door` |
| 位置 | X ≈ 116, Z ≈ 0 |
| 数量 | 1 个（场上仅此一个球门） |

`ServerStorage.Goal` 下的 44 个 door 模型（door1 ~ door44）**不在游戏玩法中使用**，作为预留资产。

### 5.2 球门结构

| 部件 | 类型 | 说明 |
| --- | --- | --- |
| goal_chk | Part | 透明检测器，2×9×24，Anchored, CanTouch=true |
| goal | MeshPart / UnionOperation | 球门框主体 |
| side | Part | 球门侧柱 |
| beam | UnionOperation / Part | 球门横梁 |

### 5.3 进球检测流程

```
球 Main MeshPart 飞行
      │
      ▼
goal_chk.Touched 触发
      │
      ▼
服务器验证球是否处于飞行状态（排除走动碰触）
      │
      ▼
判定进球 → 发放金币 → 播放特效
```

---

## 6. NPC 系统

### 6.1 预分配轮转

10 个 NPC 从 `NPCData.luau` 预读（ID 与 `ServerStorage.Player` 子文件夹内模型名精确匹配），按槽位轮转分配：
- 槽 1：NPC 1、4、7、10
- 槽 2：NPC 2、5、8
- 槽 3：NPC 3、6、9

### 6.2 倒计时

| 阶段 | 时长 | 说明 |
| --- | --- | --- |
| 初始启动 | 30s / 60s / 90s（测试） | 错开启动 |
| 补位 CD | 90s（3×NPC_UNLOCK_COUNTDOWN） | 到期后自动补下一个 |
| 品质休息 CD | 2~10s（依赖品质） | 踢球后休息 |

### 6.3 上场

NPC 从 `ServerStorage.Player` 的 4 个子文件夹（Retro/Trending/Popular/Icons）按 `GetDescendants()` 遍历查找，精确匹配 `displayName` 后取模型并移至 `workspace`。
站位在占位点基础上 ±3 studs 随机散开，避免叠模。

### 6.4 NPC 品质系统

每个 NPC 拥有**品质等级**，影响进球金币加成和外观。

**品质级别**：

| 级别 | 名称 | 金币倍率 | 外观变化 |
| --- | --- | -------- | -------- |
| 1 | 普通 (Common) | 1.0x | 基础外观 |
| 2 | 稀有 (Rare) | 1.5x | 球衣颜色变化 |
| 3 | 史诗 (Epic) | 2.0x | 金色特效 + 专属球衣 |
| 4 | 传奇 (Legendary) | 3.0x | 全身发光粒子 + 专属配件 |
| 5 | 神话 (Mythic) | 5.0x | 动态特效 + 特殊入场动画 |

**品质提升方式**：

| 条件 | 效果 |
| ---- | ---- |
| 玩家重生 | 当前活跃 NPC 的品质 +1（上限 5） |
| 金币购买（可选） | 消耗 Coins 直接提升指定 NPC 品质 |

**品质与解锁的关系**：

- 解锁一个新的 NPC 后，该 NPC **会出现在球场上**（加入活跃池）
- 默认解锁的 NPC 初始品质为 1（普通）
- 已解锁但尚未进入 3 人活跃池的 NPC，会替换掉场上品质最低的 NPC
- 品质达到 5 的 NPC 不再被替换出活跃池

---

## 7. 进度与 UI

### 7.1 在线进度条

HUD 顶部展示 `FreeKickHUD.HUD.TimeDotContainer`：
- 5 个圆点串联金条，每 60s（测试 30s）点亮一个
- 时间标签 `MM:SS` 格式，每秒轮询 `NPCProgressService:GetElapsedTime()`

### 7.2 Coins 展示

`CoinsLabel` 每秒轮询 `RewardService:GetCoins()` 刷新。
`LevelLabel` 显示 `Lv.X(xY.Y)`，轮询 `RewardService:GetLevel()` 后更新。

---

## 8. 玩家等级与成长系统

### 8.1 等级系统

玩家拥有**等级**，通过消耗 Coins 升级。等级影响进球获得的金币数量。

| 等级 | 升级所需 Coins | 进球金币倍率 |
| --- | ------------- | ----------- |
| 1 | 0（初始） | 1.0x |
| 2 | 200 | 1.2x |
| 3 | 500 | 1.4x |
| 4 | 1000 | 1.6x |
| 5 | 2000 | 1.8x |
| 6 | 3500 | 2.0x |
| 7 | 5500 | 2.2x |
| 8 | 8000 | 2.5x |
| 9 | 11000 | 2.8x |
| 10 | 15000 | 3.0x |

> 注：以上数值为初始配置，后续可在 `src/shared/configs/PlayerLevels.luau` 中调整。

### 8.2 金币计算公式

```
单次进球获得 Coins = BASE_COINS × 等级倍率 × NPC 品质倍率
```

| 参数 | 默认值 | 说明 |
| ---- | ------ | ---- |
| BASE_COINS | 20 | 基础进球金币 |
| 等级倍率 | 参见 8.1 节 | 由玩家等级决定 |
| NPC 品质倍率 | 参见 6.4 节 | 由执行射门的 NPC 品质决定 |

**示例**：

| 玩家等级 | NPC 品质 | 单次进球 Coins |
| -------- | -------- | ------------- |
| 1 (1.0x) | 普通 (1.0x) | 20 × 1.0 × 1.0 = 20 |
| 5 (1.8x) | 史诗 (2.0x) | 20 × 1.8 × 2.0 = 72 |
| 10 (3.0x) | 神话 (5.0x) | 20 × 3.0 × 5.0 = 300 |

### 8.3 重生与成长循环

玩家重生（Respawn）触发成长：

```
玩家死亡/重生
    │
    ▼
检查场上 3 个活跃 NPC
    │
    ▼
选择品质最低的 NPC → 品质 +1
    │
    ▼
更新 NPC 外观（换球衣/加特效）
    │
    ▼
继续游戏循环（更高品质 = 更多 Coins）
```

---

## 9. 奖励系统

### 9.1 金币系统

| 参数 | 值 |
| --- | --- |
| 货币名称 | Coins（金币） |
| 存储方式 | DataStoreService（持久化） |

### 9.2 DataStore 键

| 数据类型 | 存储键 | 说明 |
| --- | --- | --- |
| Coins | PlayerCoins | 玩家金币余额 |
| PlayerLevel | PlayerLevel | 当前等级 |
| NPCQuality | NPCQuality_<npcId> | 各 NPC 的品质等级 |
| UnlockedCharacters | UnlockedChars | 已解锁球星 ID 列表 |

---

## 10. 角色系统

### 10.1 玩家角色

玩家使用标准 R15 角色，由 StarterPlayer 中定义。玩家角色在"吃球员"阶段自动移至目标 NPC 位置。

### 10.2 球星解锁

| 状态 | 操作 |
| --- | --- |
| 默认可用 | 1~3 位基础球星（如 Messi, Ronaldo, Neymar） |
| 金币解锁 | 消耗 Coins 解锁其他球星 |
| 选择方式 | 通过 UI 角色选择界面 |

### 10.3 解锁费用

| 球星范围 | 解锁费用 |
| --- | --- |
| 基础（默认） | 0 |
| 明星（4~12） | 各 500 Coins |
| 传奇（13~24） | 各 1000 Coins |

---

## 11. UI 流程

### 11.1 游戏中 HUD

```text
┌──────────────────────────────────────┐
│  Lv: X    金币: XXXX                 │
│                                       │
│             半场 / 足球场景             │
│         ○ NPC1 ♢Rare (倒计时: 12s)   │
│         ○ NPC2 ♢Common (倒计时: 5s)  │
│         ○ NPC3 ♢Epic (倒计时: 20s)   │
│                                       │
│   [升级]  [选择球星]  [排行榜]       │
└──────────────────────────────────────┘
```

### 11.2 进球反馈

| 元素 | 说明 |
| --- | --- |
| 屏幕特效 | 进球闪光 + "Goal!" 文字 + Coins 数额 |
| 音效 | 进球欢呼声（品质越高音效越丰富） |
| 金币弹出 | +XX Coins 浮字动画（含倍率提示） |
| 计分更新 | HUD 金币数和经验值实时增加 |

### 11.3 角色选择界面

| 元素 | 说明 |
| --- | --- |
| 球星网格 | 显示所有 24 位球星头像/名称/品质星级 |
| 锁定状态 | 已解锁 vs 未解锁（显示价格） |
| 选中高亮 | 当前使用的球星有边框标识 |
| 购买按钮 | 消耗金币解锁新球星 |
| 品质显示 | 每位球星显示当前品质等级及金币加成倍率 |

### 11.4 升级界面

| 元素 | 说明 |
| --- | --- |
| 当前等级 | 显示玩家等级及下一级所需 Coins |
| 升级按钮 | 消耗 Coins 升级，显示升级后收益 |
| 倍率预览 | 显示升级后各 NPC 进球金币变化 |

---

## 12. 技术架构

### 12.1 Knit 框架

| 层级 | 技术 | 路径 |
| --- | --- | --- |
| 框架 | Knit v1.7.0 | ReplicatedStorage.Packages.Knit |
| Component | Component v2.4.8 | ReplicatedStorage.Packages.Component |
| 服务端 | ServerScriptService.Server | `Knit.AddServicesDeep(script.services)` → `Knit.Start()` |
| 客户端 | StarterPlayerScripts.Client | `Knit.AddControllersDeep(script.controllers)` → `Knit.Start():await()` |

### 12.2 服务层设计

| 服务 | 职责 |
| --- | --- |
| BallService | 球管理、球飞行 tween、球回收 |
| GoalService | 进球检测（goal_chk.Touched）、进球判定 |
| NPCSchedulerService | NPC 选取、倒计时管理、激活/切换逻辑 |
| NPCActionService | NPC 自动寻路到球、播放踢球动画 |
| RewardService | 金币结算、等级管理、NPC 品质管理、DataStore 读写、角色解锁 |
| PlayerService | 玩家加入/离开、角色迁移（吃球员） |

### 12.3 控制器层设计

| 控制器 | 职责 |
| --- | --- |
| UIController | HUD 显示（等级、金币、倒计时）、升级界面、进球反馈、角色选择界面 |
| CameraController | 吃球员及射球时镜头切换/跟随 |
| NPCTimerController | 头顶倒计时 BillboardGui 更新 |

### 12.4 工具依赖

| 包 | 用途 |
| --- | --- |
| Knit | 服务/控制器框架 |
| Component | 面向对象组件系统 |
| Loader | 模块加载管理 |
| TableUtil | 表格操作工具 |
| Timer | 计时器/倒计时 |
| Input | 输入管理 |
| Trove | 连接/资源清理 |
| Promise | 异步操作 |
| Shake | 镜头震动 |
| Signal | 自定义事件 |
| WaitFor | 等待实例出现 |
| Topbarplus | 顶部栏 UI |
| Janitor | 资源自动清理 |
| Satchel | 数据存储 |
| Tree | 树形结构工具 |
| Sift | 表格深度操作 |

### 12.5 数据存储

| 数据类型 | 存储键 | 说明 |
| --- | --- | --- |
| Coins | PlayerCoins | 玩家金币余额 |
| PlayerLevel | PlayerLevel | 当前等级 |
| NPCQuality | NPCQuality_<npcId> | 各 NPC 的品质等级（1~5） |
| UnlockedCharacters | UnlockedChars | 已解锁球星 ID 列表 |

---

## 13. 开发路线图

### 13.1 第一阶段 — 核心循环

- [ ] 实现 NPCSchedulerService：从 24 NPC 中选 3 个激活，管理倒计时
- [ ] 实现 NPCActionService：NPC 自动寻路到最近球 + 播放踢球动画
- [ ] 实现 BallService：球管理、飞行 tween
- [ ] 实现 GoalService：goal_chk Touch 检测进球
- [ ] 实现 RewardService + DataStore 金币/等级/品质持久化
- [ ] 实现 PlayerService：玩家自动移至目标 NPC（吃球员）、重生品质提升

### 13.2 第二阶段 — 角色与 UI

- [ ] 角色选择界面与 NPC 解锁系统（含品质星级显示）
- [ ] 玩家等级系统（消耗 Coins 升级，倍率提升）
- [ ] NPC 品质系统（重生提升、外观变化）
- [ ] 倒计时 HUD（NPC 头顶 + 屏幕 UI）
- [ ] 金币与等级显示、进球反馈（特效、音效、浮字）
- [ ] 镜头控制（射球时跟随球）

### 13.3 第三阶段 — 打磨

- [ ] 多语言支持（中文/英文）
- [ ] 性能优化与防作弊
- [ ] 更多 NPC 品质外观与动画
- [ ] 每日奖励系统
- [ ] 球/球门外观商店
- [ ] 数值平衡调整

---

文档版本: v1.0
最后更新: 2026-06-12
维护者: (待填写)
