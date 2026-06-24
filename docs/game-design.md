# 自由踢球 — 游戏设计文档

## 1. 游戏概述

### 1.1 基本信息

| 项目 | 内容 |
| ------ | ------------------ |
| 游戏名称 | 自由踢球 |
| 游戏类型 | 半挂机自由踢自动进球（Semi-idle Free Kick Auto-scoring） |
| 目标平台 | Roblox（PC / 移动端 / 主机） |
| 目标玩家 | 单人 |
| 美术风格 | Low-poly 卡通风格 |

### 1.2 核心体验

玩家分配到专属半球场。场上设有 **3 个固定站位**（Slot1-3），新解锁的 NPC 依次从这 3 个站位出场。解锁后的 NPC 自动寻球、踢球、进球，加入场上活跃池（`ActiveNPCS`，上限 10 个）。超过 10 个时采用 FIFO 替换（最早进入的 NPC 离场）。

每 30 秒解锁 1 个 NPC，一轮 10 个（5 分钟总和）。10 人解锁完成后触发「满员等待」阶段——玩家必须走向世界杯奖杯触发比赛。**世界杯总是获胜** → 奖杯 +1 → 进入下一轮解锁。循环至全部 84 位球星解锁。

老玩家重连时，`ActiveNPCS` 中记录的上次在场 NPC 会被随机放置在球场活动区（AreaBall），恢复踢球循环。

### 1.3 核心循环

```txt
阶段 1：解锁阶段
  → 在线进度条累积
  → 每 NPC_UNLOCK_COUNTDOWN（30s）解锁 1 个球星
  → 从 NPCList 按 order 顺序，取未解锁的前 10 个
  → NPC 从 3 个站位依次上场 → 自动寻球踢球 → 加入 ActiveNPCS
  → ActiveNPCS 超 10 个时 FIFO 移除最早 NPC

阶段 2：满员等待
  → 10 人解锁完毕 → 进度条停
  → 场上 NPC 继续自动踢球
  → 等待玩家走向世界杯奖杯

阶段 3：世界杯比赛
  → 玩家走向场地中央奖杯（ProximityPrompt，按 E 触发）
  → 检查 #UnlockedNPCs >= 10
  → 不足则提示 "Need 10 players"
  → 奖杯升起（1.5s tween）→ 等待 11~20s → 奖杯归位（1.5s）
  → 总是赢 → Trophies+1

阶段 4：下一轮
  → 进度条重置，继续解锁下一批 10 个
  → 循环至全部 84 人解锁
```

---

## 2. 场地布局

### 2.1 多场布局

服务器启动时从 `Workspace.Field_1` 模板克隆 **6 个球场**，六边形排布（半径 ~110 studs，每 60° 一个场）。球门朝外、球员中场站位，每个玩家分配一个专属场。

### 2.2 单场结构

| 参数 | 说明 |
| --- | --- |
| 球门 | 1 个（`_door`），内含 goal_chk 检测器 |
| 站位点 | `Player/Slot1`、`Slot2`、`Slot3` 三个 Marker Part |
| 活动区 | `AreaBall` BasePart，球掉落范围 |
| 升级区 | `Zone_LevelUp` + touch 检测 |
| 战术板 | `Info/Main/Gui` — SurfaceGui 显示已解锁 NPC icon |

### 2.3 场主标牌

每个球场中心上方 30 studs 有一个 `FieldOwnerGui` BillboardGui（头像 + 名字），分配玩家后显示。

---

## 3. 核心机制

### 3.1 游戏状态机

```txt
Idle → 解锁阶段
  │
  ▼
在线计时累积，每 30s 解锁 1 个 NPC
  │
  ▼
NPC 从 SlotX 站位从天而降 → 加入场上活跃池
  │
  ▼
NPC 自动寻球 → 走向球 → 踢球动画 → 球弧线飞向球门
  │
  ▼
goal_chk 距离检测 → 判定进球 → Coins 增加
  │
  ▼
NPC CD（品质 cool down）后继续寻球踢球（独立循环）
  │
  ▼ (10 NPC 全部解锁)
满员等待阶段
  │
  ▼ (按 E 触发 ProximityPrompt)
世界杯比赛阶段：奖杯升起 → 等待 11~20s → 奖杯归位 → Trophies+1
  │
  ▼
下一轮：进度重置 → 返回解锁阶段（下一批 10 个 NPC）
```

### 3.2 NPC 解锁系统

| 参数 | 值 |
| --- | --- |
| 站位数量 | 3（Slot1-3，Marker Part，**不删除**） |
| 每轮解锁数 | 10（`ACTIVE_NPC_COUNT`） |
| 解锁间隔 | 30s（`NPC_UNLOCK_COUNTDOWN`） |
| 总轮时间 | 300s（`ONLINE_TOTAL_MINUTES` × 60） |
| 出场方式 | 从站位依次上场，从天而降（drop 动画 1.5s） |
| FIFO 上限 | 10（`MAX_ACTIVE_NPCS`），超限时移除最早 |

### 3.3 NPC 自动踢球

NPC 上场后进入独立踢球循环：

| 步骤 | 描述 |
| --- | --- |
| 1 | 扫描场上已落地的球 |
| 2 | 计算距离最近的球 |
| 3 | NPC Humanoid 自动行走至球位置（MoveTo） |
| 4 | 播放踢球动画 |
| 5 | 球沿弧线飞向球门 goal_chk |
| 6 | 距离检测 `< 40` → 判进球 → 发放 Coins |
| 7 | 进入品质 CD（2~10s），然后回到步骤 1 |

### 3.4 自动踢球参数

| 参数 | 值 |
| --- | --- |
| NPC 行走速度 | `NPC_WALK_SPEED`（20） |
| 球飞行时间 | `BALL_FLIGHT_DURATION`（1.5s） |
| 弧线高度 | `BALL_ARC_MIN`~`BALL_ARC_MAX`（3~10） |
| 进球判定距离 | `< 40 studs` |
| 冷却 CD | 品质 cooldown（Common=10, Rare=8, Epic=6, Legendary=4, Mythic=2） |

### 3.5 进球检测

球飞行终点 → 计算 Main 位置与 goal_chk.Position 距离 → `< 40` 即判进球：

```txt
球飞行结束 (elapsed >= 1.5s)
  → 计算 Main.Position 与 goal_chk.Position 距离
  → dist < 40 → 进球 → 发放金币 → 播放音效 "coins" → 2s 后销毁球
```

### 3.6 进球奖励

| 参数 | 值 |
| --- | --- |
| 基础金币 | `BASE_COINS`（20） |
| 等级倍率 | 见 8.1 玩家等级表 |
| NPC 品质倍率 | 见 6.4 品质表 |
| 公式 | `单次进球 = BASE_COINS × 等级倍率 × NPC 品质倍率` |

---

## 4. 球系统

### 4.1 球模型结构

每个球模型（`ServerStorage.Ball.ballN`）包含：

| 部件 | 类型 | 说明 |
| --- | --- | --- |
| E_Ball | Part + ProximityPrompt | 触发器部件 |
| Highlight | Highlight | 球体高亮 |
| Main | MeshPart | 球体主体，size 2×2×2 |
| Main.Shoot | Sound | 射门音效 |
| Main.Trail | Trail | 飞行轨迹尾迹 |

### 4.2 球生成逻辑

| 参数 | 值 |
| --- | --- |
| 生成间隔 | `BALL_SPAWN_INTERVAL`（6s） |
| 每玩家球上限 | `MAX_BALLS_PER_PLAYER`（11） |
| 模板来源 | `ServerStorage.Ball`，从玩家 `BallIds` 随机选 |
| 下落起点 | Y = 50（`BALL_SPAWN_DROP_HEIGHT`） |
| 落地目标 | Y = 1.0（`BALL_LAND_Y`） |
| 下落动画 | 1.5s 缓动 |
| 落点范围 | AreaBall 内随机 |

---

## 5. 球门系统

### 5.1 唯一球门

每个球场有 1 个球门（`Field_X._door`），球门框内含 `goal_chk` Part（Size 2×9×24，Anchored，CanTouch=true，Transparent）作为进球检测器。

---

## 6. NPC 系统

### 6.1 站位与出场

3 个固定站位（`Player/Slot1-3` Marker Parts，**游戏过程中不删除**），NPC 按轮转顺序从这 3 个站位依次上场。

### 6.2 解锁顺序

84 位球星按 `order` 字段（综合影响力评分）排序：前 10 位为顶级巨星（Messi、Ronaldo、Neymar 等），每组 10 个中前 5 位具有吸引力，保证早期体验最佳。

### 6.3 NPC 品质系统

| 级别 | 名称 | 金币倍率 | 冷却 CD | 外观变化 |
| --- | --- | --- | --- | --- |
| 1 | Common | 1.0x | 10s | 基础外观 |
| 2 | Rare | 1.5x | 8s | 球衣颜色变化 |
| 3 | Epic | 2.0x | 6s | 金色特效 + 专属球衣 |
| 4 | Legendary | 3.0x | 4s | 全身发光粒子 |
| 5 | Mythic | 5.0x | 2s | 动态特效 + 特殊入场动画 |

**品质提升**：玩家重生时，场上活跃 NPC 中品质最低的 +1（上限 5）。

### 6.4 ActiveNPCS 管理

| 参数 | 说明 |
| --- | --- |
| 含义 | 场上正在踢球的 NPC ID 列表 |
| 上限 | `MAX_ACTIVE_NPCS`（10） |
| 新增时机 | 每个 NPC 解锁并上场时 |
| 移除时机 | 超过 10 个时，FIFO 移除最早进入的 NPC |
| 持久化 | 每次变更立即保存到 DataStore |
| 重连恢复 | 老玩家重连时，按 `ActiveNPCS` 将 NPC 随机放置在 AreaBall |

---

## 7. 进度与 UI

### 7.1 在线进度条

HUD 底部展示进度条（CoreBarView）：10 个圆点串联金条，每 `NPC_UNLOCK_COUNTDOWN`（30s）点亮一个。总时长 5 分钟。10 人解锁后暂停，世界杯胜利后重置。

### 7.2 Coins 与等级

`InfoBarView` 每秒轮询刷新金币数、等级和战力。新玩家默认赠送 200 Coins。

### 7.3 战术板

场上 Info 板投影（SurfaceGui）：`card_1` 显示本地玩家头像，`card_2~11` 显示已解锁 NPC 的 icon。世界杯胜利后重新读取解锁列表更新。

### 7.4 排行榜

Workspace 中放置了金色外框排行榜模型（SurfaceGui），按奖杯数量排名，支持 100 名滚动展示，每行含玩家头像、名称和奖杯数。

---

## 8. 玩家等级与成长系统

### 8.1 等级系统

| 等级 | 升级所需 Coins | 进球金币倍率 |
| --- | --- | --- |
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

### 8.2 金币计算公式

```
单次进球获得 Coins = BASE_COINS × 等级倍率 × NPC 品质倍率
```

### 8.3 重生成长

玩家重生 → 场上活跃 NPC 中品质最低的 +1 → 继续游戏循环。

---

## 9. 奖励系统

### 9.1 DataStore 键

| 数据类型 | DataStore 名称 | 键格式 |
| --- | --- | --- |
| 完整玩家数据 | `FreeKickData` | `PlayerData_{userId}` |

**PlayerData 结构**：
- `Coins`：金币余额
- `Level`：玩家等级
- `NPCTiers`：各 NPC 品质等级（npcId → quality）
- `UnlockedNPCs`：已解锁 NPC ID 列表
- `BallIds`：已拥有球模型 ID 列表
- `Trophies`：奖杯数
- `FirstJoinTime`：首次加入时间戳
- `ActiveNPCS`：场上踢球 NPC ID 列表（max 10）
- `New`：是否新玩家

---

## 10. 新手引导

新玩家进入后等待第一个球落地 → 箭头引导依次指向：
1. 踢一个球得分
2. 走到 NPC 处领取
3. 走到升级区升级
4. 走向奖杯触发世界杯
5. 再踢一个球

---

## 11. 音频系统

| 时机 | 音效 | SoundId |
| --- | --- | --- |
| 球下落 | Sprint | `rbxassetid://12221842` |
| 踢球 | shoot | `rbxassetid://8595974357` |
| 进球 | coins | `rbxassetid://662290183` |

---

文档版本: v2.0
最后更新: 2026-06-24
