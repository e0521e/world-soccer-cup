# 变更日志

本文件记录项目的所有重要变更。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## 模板说明

每个版本记录使用以下格式：

```markdown
## [版本号] - YYYY-MM-DD

### 新增 (Added)
- 新增的功能

### 变更 (Changed)
- 现有功能的变更

### 废弃 (Deprecated)
- 即将移除的功能

### 移除 (Removed)
- 已移除的功能

### 修复 (Fixed)
- Bug 修复

### 安全 (Security)
- 安全相关修复
```

---

## [Unreleased]

### 新增

- 玩家数据新增 `BallIds` 字段，默认 `["1"]`
- `RewardService.GetBallIds(player)` — 获取玩家已拥有的球模型 ID 列表
- `KickAnimList.luau` — 踢球动画配置表（`src/shared/configs/KickAnimList.luau`）
- `PlayerDataService` — 新建服务，作为所有持久化玩家数据（Coins / Level / NPCTiers / UnlockedNPCs / BallIds / Trophies）的单一数据源，接管 DataStore 生命周期和数据变更信号

### 变更

- `BallSpawnService.SpawnBall` 改为根据玩家 `BallIds` 列表随机选球，替代旧的全量随机
- 踢球动画 ID 和延迟改为从 `KickAnimList` 配置表随机选取，替代旧的两个硬编码常量
- `Constants.luau` 移除 `NPC_KICK_ANIM_ID` 和 `KICK_ANIM_TO_FLIGHT_DELAY`
- **玩家数据架构重构**：`RewardService` 瘦身为纯奖励逻辑，数据 CRUD/DataStore 迁移至 `PlayerDataService`
  - `RewardService` 移除：`_playerData`、DataStore 代码、GetCoins/GetLevel/UpgradeLevel/DeductCoins/GetPower/GetTrophies/IsNewPlayer/CompleteTutorial/GetBallIds/ResolveMatch
  - `RewardService` 保留：`AwardGoal`、`UpgradeNPCQuality`、`UnlockNPC` 及 `OnNPCQualityUp`/`OnNPCUnlocked` 信号
  - `PlayerDataService` 新增：`OnCoinsChanged`/`OnLevelUp` 信号及所有数据操作方法
  - `UIController` 和 `ShopView` 改为监听/调用 `PlayerDataService`
  - `PlayerService` 移除 `rewardService._playerData` 直接访问，改用 `PlayerDataService` 方法
  - `FieldManagerService` 移除 `rewardService._playerData` 直接访问，改用 `PlayerDataService` 方法
  - `AdminService` 移除 `rewardService._playerData` 直接访问，改用 `PlayerDataService:GetData()`

---

## [Unreleased]

### 新增

- `NPCProgressService.ResetProgress(player, startIndex)` — 重置进度循环并偏移起始索引，支持多轮解锁
- `NPCTimerService.EnterPostFullUnlockMode(player)` — 满员后模式：3槽替换为offset NPC，无倒计时，提示文字，可重复认领
- `NPCTimerService.LeavePostFullUnlockMode(player)` — 离开满员模式
- `NPCTimerService._CleanupSlotNPCs(player)` — 清空玩家所有槽位的NPC模型
- `CoreBarView:SetOffset(offset)` — 更新进度条圆点名称以匹配当前解锁批次
- 战术板（Tactical Board）填充 — `UIController._SetupTacticalBoard` 填充 `card_1`~`card_11` 的 Image
- 世界杯奖杯升起效果 — 触发时 tween 升至玩家头顶 15 studs，结束后归位

### 变更

- `WORLD_CUP_REQUIRED_NPCS` 从 11 改为 10（10 NPC + 玩家 = 11 人队伍）
- `NPCProgressService._InitPlayer` 新增 `startIndex` 参数，从 `NPCData.NPCList[startIndex]` 开始取 NPC
- `NPCProgressService.OnMinuteReached` 信号增加 `npcId` 参数
- `NPCTimerService._PlaceNPCOnField` 支持 `isPostUnlock` 标志：无倒计时，显示"Win World Cup to join me!" 提示
- `NPCTimerService._MakeClaimable` 支持 `isPostUnlock` 参数：认领后不补位，8秒冷却后重新可认领
- `PlayerService` 世界杯处理：奖杯升起 → 等待11-20s → 奖杯归位 → `ResetProgress(player, #UnlockedNPCs+1)`
- `NPCTimerService.KnitStart` 添加 `NPCProgressService.OnTeamComplete` 监听，触发后检查 `#UnlockedNPCs >= 10` 并进入满员模式
- 客户端 `_teamDone` 标志在 `WorldCupDone` 时重置
- Toast 文本 "Your team needs 11 players to enter." → "Your team needs 10 players to enter."
- `docs/game-design.md` 更新：1.2 核心体验、1.3 核心循环（4阶段）、3.1 游戏状态机、3.2 NPC倒计时系统、7.1 在线进度条、7.2 Coins展示、7.3 战术板、10.2 球星解锁
- `docs/architecture.md` 更新：NPCTimerService (PostFullUnlockMode)、NPCProgressService (多轮解锁/ResetProgress)、PlayerService (世界杯处理)、游戏状态机 (TeamComplete+WorldCup)

- `ShopService` — 商店购买服务（`src/server/services/ShopService.luau`）
  - `PurchaseWithCoins(player, gamePassId)` — 金币购买 GamePass
  - `GetOwnedGamePasses(player)` — 查询已拥有 GamePass
  - `HasGamePass(player, gamePassId)` — 检查特定 GamePass 所有权
  - `GetProducts()/GetGamePasses()` — 返回完整商品清单
  - `ProcessReceipt` — MarketplaceService Robux 购买回调处理
  - `OnPurchaseComplete / OnPurchaseFailed` — 购买结果信号
  - 玩家加入时自动检查已有 GamePass 所有权
- `ShopView` — 商店覆盖层 UI（`src/client/views/ShopView.luau`）
  - 全屏半透明面板 + 居中商店面板 (520×460)
  - 双 Tab：「📦 商品」和「⭐ 特权」
  - 商品列表：图标 + 名称 + 描述 + 价格 + 购买按钮
  - Coin 购买 GamePass：调起 ShopService 金币扣减流程
  - Robux 购买：调起 MarketplaceService 原生购买弹窗
  - 购买成功/失败状态提示
  - 已拥有状态显示
- `ShopTypes.luau` — 商店类型定义（`src/shared/types/ShopTypes.luau`）
  - `ProductItem` 和 `GamePassItem` 类型
- `RewardService.DeductCoins(player, amount)` — 通用金币扣减方法
- `RewardService.AwardCoinsDirect(player, amount)` — 直接发放金币方法
- Double Coins GamePass 集成：拥有者进球金币 ×2
- `docs/ui-design.md` — 完整的 UI 设计规范文档

### 变更

- UIController 接入 ShopView，商店按钮不再弹出 Toast 占位而是打开完整覆盖层
- Products.luau 数据清单确认（3 个 Robux 金币包）
- GamePasses.luau 数据清单确认（2 个 GamePass）
- default.project.json 通过 `$path` 自动映射新文件，无需手动添加

---

文档版本: v0.1
最后更新: 2026-06-12
维护者: (待填写)
