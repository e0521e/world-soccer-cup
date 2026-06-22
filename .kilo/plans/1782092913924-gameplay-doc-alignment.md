# 核心玩法文档对齐

## 对齐后的理解

### 玩家数据

- `UnlockedNPCs` — 已解锁球星 ID 列表，默认 `{}`
- `Trophies` — 世界杯奖杯数，默认 `0`

### 游戏循环

```txt
阶段 1：解锁阶段
  → 在线进度条累积（ONLINE_TOTAL_MINUTES）
  → 每到一个节点（总时间/10），解锁 1 个球星
  → 从 NPCList 按顺序取（id=1→10）
  → 对应 NPC 头像 icon 填充到战术板 card_2~card_11
  → card_1 始终为本地玩家头像
  → 场上 3 个站位槽显示当前已解锁的 NPC，带倒计时

阶段 2：满员等待
  → 10 人解锁完毕 → 进度条停
  → 3 个站位槽切换为 NPC 11/12/13
  → 不再显示倒计时，NPC 头顶提示 "赢得世界杯后，我会加入你"
  → c 场上仍然正常掉球/踢球（NPC 11/12/13 参与自动踢球）
  → 玩家可走向场地中央的世界杯奖杯（Workspace.trophy 的 ProximityPrompt）

阶段 3：世界杯比赛
  → 按 E 触发 WorldCupPrompt
  → 检查 #UnlockedNPCs >= 10（10 人 + 玩家 = 11 人队伍）
  → 不足则提示 "Need 11 players"
  → 模拟等待（11-20s 随机）
  → 总是赢 → Trophies+1
  → 奖杯目标升起玩家当前位置，持续数秒

阶段 4：下一轮
  → 进度条重置，继续解锁下一批 10 个球星（id=11→20, 21→30, ...）
  → 后续每轮解锁的 NPC 也填充到战术板（card 不替换，已有的一直显示）
  → 当 #UnlockedNPCs >= 10，再次可触发世界杯
  → 循环至全部 84 人解锁
```

### 详细机制

#### 战术板（Tactical Board）

- 位置：`Workspace.Field_X.Info.Main.Gui.u_card`
- 结构：`card_1`~`card_11`（ImageButton）+ `u_bench`（Frame）
- `card_1` — 本地玩家头像（Image 设为玩家头像）
- `card_2`~`card_11` — 对应 10 个已解锁 NPC 的 icon（NPCList[i].icon）
- 纯客户端 UI：监听 `NPCProgressService.OnMinuteReached` 填充

#### 满员后站位 NPC

- 服务端 `NPCTimerService` 检测 `#UnlockedNPCs >= 10`
- 3 个活跃槽位替换为 NPC 11, 12, 13 的模型
- 不启动倒计时
- NPC 头顶 BillboardGui 显示 "赢得世界杯后，我会加入你"
- NPC 仍在场上参与自动踢球逻辑（AutoKickService）

#### 世界杯奖杯

- 模型 `Workspace.trophy.Main`，带有 `WorldCupPrompt`（ProximityPrompt）
- 服务端 `PlayerService` 中已实现提示绑定
- 当前逻辑直接加奖杯（固定赢）

### 现有代码覆盖情况

| 功能 | 状态 | 说明 |
| ------ | ------ | ------ |
| UnlockedNPCs 默认 `{}` | ✅ 已实现 | PlayerDataService 创建默认值 |
| Trophies 默认 0 | ✅ 已实现 | PlayerDataService 创建默认值 |
| 在线进度条解锁 10 人 | ✅ 已实现 | NPCProgressService |
| 战术板 card 填充 | ❌ 未实现 | 需纯客户端实现 |
| card_1 玩家头像 | ❌ 未实现 | 需纯客户端实现 |
| 满员后 NPC 11/12/13 替换 | ❌ 未实现 | NPCTimerService 新增逻辑 |
| 满员后 NPC 提示文字 | ❌ 未实现 | BillboardGui 新增 |
| 满员后关倒计时 | ❌ 未实现 | NPCTimerService |
| 世界杯 E 互动 | ✅ 已实现 | PlayerService 已有 |
| 世界杯检查 10 NPC | ⚠️ 常量对齐 | WORLDCUP_REQUIRED_NPCS=11 需改为 10 |
| 世界杯固定赢 | ✅ 已实现 | 当前直接 +Trophies |
| 新一轮解锁 | ❌ 未实现 | 世界杯胜利后重置进度 |

### 文档更新清单

所有修改仅限于 `docs/game-design.md`：

1. **1.2 核心体验** — 重写为按用户描述
2. **1.3 核心循环** — 替换为 4 阶段循环文本图
3. **3.1 游戏状态机** — 更新流程，增加满员等待和世界杯阶段
4. **3.2 NPC 倒计时系统** — 增加满员后行为说明
5. **6.4 进度与解锁（新增）** — 战术板 + 满员NPC + 世界杯的完整描述
6. **7.3 战术板（新增）** — card 布局、填充逻辑
7. **10.2 球星解锁** — 改为两阶段解锁（进度条解锁10人→世界杯解锁下一轮）

### 常量对齐

- `WORLD_CUP_REQUIRED_NPCS = 10`（当前 = 11，需改为 10）

### 实施注意事项

- 纯客户端战术板填充不应迟于下一轮任务周期
- NPCTimerService 满员检测在 `OnTeamComplete` 信号触发时执行
- 世界杯胜利后进度重置前需清除 NPCProgressService._playerData
