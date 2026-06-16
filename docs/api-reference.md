# API 参考文档

> 本文档记录项目所有 Knit Service 和 Controller 的公开 API。
> 游戏为**半放置自由踢球自动射门**：3 名 NPC 轮流上场，倒计时结束后玩家自动接管，NPC 自动寻路踢球射门，进球获得金币。
>
> UI 设计细节请参阅 `docs/ui-design.md`。

---

## 模板说明

每个 API 模块使用以下模板记录：

```markdown
### Service/Controller: [名称]

**文件路径**: `src/[端]/[目录]/[文件名].luau`

**简述**: 一句话描述模块职责。

#### 公开方法

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |

#### 信号/事件

| 信号 | 参数 | 触发时机 | 说明 |
| ---- | ---- | -------- | ---- |

#### 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
```

---

## 一、服务端 Services

### 1.1 NPCTimerService

**文件路径**: `src/server/services/NPCTimerService.luau`

**简述**: 管理 3 个 NPC 活动槽位的倒计时生命周期。每个 NPC 头顶显示倒计时，归零后自动触发接管流程。

#### 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| GetActiveNPCs | `()` | `{NPCSlotInfo}` | Client | 获取当前 3 个活跃 NPC 的 slotId、npcId、剩余时间 |
| GetTimerRemaining | `(slotId: number)` | `number` | Client | 获取指定槽位倒计时剩余秒数 |

#### 信号

| 信号 | 参数 | 触发时机 | 说明 |
| ---- | ---- | -------- | ---- |
| OnNPCActivated | `(slotId: number, npcId: string, duration: number)` | NPC 进入活跃槽位 | NPC 被激活并开始倒计时 |
| OnTimerUpdated | `(slotId: number, remaining: number)` | 每秒更新 | 倒计时值变化 |
| OnTimerExpired | `(slotId: number, npcId: string)` | 倒计时归零 | 触发自动接管 |

#### 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| _ActivateNPC | `(slotId: number)` | `()` | 从备选池选取 NPC 填入空槽，启动计时器 |
| _StartTimer | `(slotId: number, duration: number)` | `()` | 创建 3-2-1 倒计时 Tween，每秒触发 OnTimerUpdated |
| _OnTimerExpired | `(slotId: number)` | `()` | 广播 OnTimerExpired 并通知 PlayerService 接管该 NPC |

#### NPC轮转（新设计）

10 个 NPC 预分配到 3 个槽位轮转队列。到期自动补位。

##### 内部方法（新增）

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| ActivateNPCs | `(player)` | `()` | 初始占位 3 个 NPC，错开定时 |
| _AdvanceSlotNPC | `(player, slotData)` | `()` | 槽位轮转到下一个 NPC |
| ResetSlot | `(player, sd)` | `()` | 品质 CD 定时重启 |

---

### 1.2 AutoKickService

**文件路径**: `src/server/services/AutoKickService.luau`

**简述**: 接管 NPC 后自动执行完整踢球流程：寻路到最近球、播放踢球动画、球飞行至球门、检测进球。

#### 1.2.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| （无公开方法） | | | | 全部由服务器自动驱动 |

#### 1.2.2 信号

| 信号 | 参数 | 触发时机 | 说明 |
| ---- | ---- | -------- | ---- |
| OnNPCWalking | `(npcId: string, targetPos: Vector3)` | NPC 开始寻路 | NPC 走向最近的球 |
| OnKickAnimation | `(npcId: string, ballPos: Vector3)` | 踢球瞬间 | NPC 播放踢球动画，球开始飞行 |
| OnBallFlying | `(ballPos: Vector3, startPos: Vector3, targetPos: Vector3)` | 球离脚 | 球沿弧线飞向球门 |
| OnGoalScored | `(npcId: string, reward: number)` | 球进门 | 进球确认，通知 RewardService |

#### 1.2.3 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| _FindNearestBall | `(npcPosition: Vector3)` | `BasePart?` | 在 Workspace 中搜索距离 NPC 最近的 Ball 实例 |
| _NavigateToBall | `(character: Model, ballPos: Vector3)` | `()` | 使用 Humanoid:MoveTo 寻路到球位置，到位后停止 |
| _PlayKickAnimation | `(humanoid: Humanoid)` | `()` | 加载并播放踢球动画轨道 |
| _FlyBallToGoal | `(ball: BasePart, goalPos: Vector3)` | `()` | Tween 球沿抛物线飞向球门，附带 Trail 和音效 |
| _DetectGoal | `(ball: BasePart)` | `boolean` | 检测 ball 与 Workspace.Field_1.Goal.goal_chk 的 Touch 事件 |

---

### 1.3 RewardService

**文件路径**: `src/server/services/RewardService.luau`

**简述**: 管理玩家金币结算、等级系统、NPC 品质管理、DataStore 持久化以及 NPC 解锁。

#### 1.3.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| GetCoins | `()` | `number` | Client | 获取当前玩家金币余额 |
| GetLevel | `()` | `{level: number, multiplier: number, nextCost: number}` | Client | 获取当前等级信息 |
| UpgradeLevel | `()` | `boolean` | Client | 消耗 Coins 升级（自动扣除） |
| GetNPCQuality | `(npcId: string)` | `{quality: number, multiplier: number}` | Client | 获取指定 NPC 品质 |
| GetUnlockedNPCs | `()` | `{string}` | Client | 获取已解锁的 NPC ID 列表 |
| DeductCoins | `(amount: number)` | `boolean` | Client | 扣减金币（ShopService 调用，外部慎用） |

#### 1.3.2 信号

| 信号 | 参数 | 触发时机 | 说明 |
| ---- | ---- | -------- | ---- |
| OnCoinsChanged | `(newBalance: number, delta: number)` | 金币增减 | 每次金币变化后广播 |
| OnLevelUp | `(newLevel: number, multiplier: number)` | 等级提升 | 玩家升级成功 |
| OnNPCQualityUp | `(npcId: string, newQuality: number, multiplier: number)` | NPC 品质提升 | NPC 品质变化（重生或购买） |
| OnNPCUnlocked | `(npcId: string, cost: number)` | NPC 解锁成功 | 玩家消耗金币解锁新 NPC |

#### 1.3.3 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| DeductCoins | `(player: Player, amount: number)` | `boolean` | 扣减金币，触发 OnCoinsChanged |
| AwardCoinsDirect | `(player: Player, amount: number)` | `()` | 直接增加金币（用于开发者产品购买奖励） |
| _AwardCoins | `(player: Player, amount: number)` | `()` | 增加金币，触发 OnCoinsChanged |
| _CalculateReward | `(player: Player, npcId: string)` | `number` | 按公式计算实际金币：BASE × 等级倍率 × NPC 品质倍率 |
| _UpgradeNPCQuality | `(player: Player, npcId: string)` | `()` | 重生后提升 NPC 品质 +1（上限 5） |
| _SaveData | `(player: Player)` | `()` | 将 Coins / Level / NPCTiers / UnlockedNPCs 写入 DataStore |
| _LoadData | `(player: Player)` | `()` | 从 DataStore 读取玩家存档初始化内存 |
| UnlockNPC | `(player: Player, npcId: string, cost: number)` | `boolean` | 扣除金币解锁 NPC，触发 OnNPCUnlocked |

**奖励规则**:

| 参数 | 默认值 | 说明 |
| ---- | ------ | ---- |
| BASE_COINS | 20 | 基础进球金币 |
| 等级倍率 | 参见等级配置 | 由玩家等级决定（Lv1=1.0x, Lv10=3.0x） |
| NPC 品质倍率 | 参见品质配置 | 由 NPC 品质决定（Common=1.0x, Mythic=5.0x） |

**公式**: `单次进球 Coins = BASE_COINS × 等级倍率 × NPC 品质倍率`

---

### 1.4 PlayerService

**文件路径**: `src/server/services/PlayerService.luau`

**简述**: 管理玩家会话生命周期：加入/离开、当前接管槽位、NPC 选择。

#### 1.4.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| GetActiveSlot | `()` | `number?` | Client | 获取当前接管中的 NPC 槽位编号 |
| SelectNPC | `(npcId: string)` | `boolean` | Client | 从已解锁 NPC 中选择一位设为默认 |

#### 1.4.2 信号

| 信号 | 参数 | 触发时机 | 说明 |
| ---- | ---- | -------- | ---- |
| OnCharacterChanged | `(npcId: string)` | 切换默认 NPC | 玩家选中的默认 NPC 变更 |
| OnTakeover | `(slotId: number, npcId: string)` | 接管 NPC 时 | 玩家被自动移至 NPC 位置开始控制 |

#### 1.4.3 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| OnPlayerAdded | `(player: Player)` | `()` | 玩家加入时加载数据、创建角色 |
| OnPlayerRemoving | `(player: Player)` | `()` | 玩家离开时保存数据、清理角色 |
| _TeleportToNPC | `(player: Player, npcId: string)` | `()` | 将玩家角色移至 NPC 所在位置 |

---

### 1.5 FieldManagerService

**文件路径**: `src/server/services/FieldManagerService.luau`

**简述**: 管理球场克隆、玩家分配、场主标牌。

#### 1.5.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| GetFieldName | `()` | `string` | Client | 获取分配的场名 |
| GetGroundPosition | `()` | `Vector3?` | Client | 获取当前场地 Ground 部件坐标（Pitch 按钮传送） |

#### 1.5.2 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| GetField | `(player)` | `Model?` | 获取玩家分配的场 Model |
| _AssignField | `(player)` | `Model?` | 分配空闲场 |
| _ReleaseField | `(player)` | `()` | 释放场 |
| _MirrorField | `(fieldModel, xOffset, zOffset)` | `()` | 绕 Y 旋转 180° + 平移 |
| _UpdatePlayerGuis | `(field, player)` | `()` | 更新场主标牌（头像+名字） |
| _ClearPlayerGuis | `(field)` | `()` | 清除场主标牌 |

---

### 1.6 NPCProgressService

**文件路径**: `src/server/services/NPCProgressService.luau`

**简述**: 在线时间进度、NPC 解锁队列。

#### 1.6.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| GetElapsedTime | `()` | `number` | Client | 获取已在线秒数 |
| GetQueueSize | `()` | `number` | Client | 获取队列待领取数量 |

#### 1.6.2 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| DequeueNextNPC | `(player)` | `string?` | 从队列出队一个 NPC ID |
| _InitPlayer | `(player)` | `()` | 初始化进度跟踪循环 |

---

### 1.7 ShopService

**文件路径**: `src/server/services/ShopService.luau`

**简述**: 管理商店购买逻辑：Robux 开发者产品/GamePass 购买处理、金币购买 GamePass、已购所有权查询。

#### 1.7.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| PurchaseWithCoins | `(gamePassId: number)` | `boolean, string?` | Client | 金币购买 GamePass，成功返回 true |
| GetOwnedGamePasses | `()` | `{number}` | Client | 获取已拥有的 GamePass ID 列表 |
| GetProducts | `()` | `{ProductItem}` | Client | 获取完整开发者产品清单（Products.luau） |
| GetGamePasses | `()` | `{GamePassItem}` | Client | 获取完整 GamePass 清单（GamePasses.luau） |
| HasGamePass | `(gamePassId: number)` | `boolean` | Client | 检查是否已拥有某 GamePass |

#### 1.7.2 信号

| 信号 | 参数 | 触发时机 | 说明 |
| ---- | ---- | -------- | ---- |
| OnPurchaseComplete | `(itemType: string, itemId: number, info: {name: string, icon: string})` | 购买成功 | Robux/Coins 购买均触发 |
| OnPurchaseFailed | `(itemType: string, itemId: number, reason: string)` | 购买失败 | 余额不足/已拥有/服务端错误 |

#### 1.7.3 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| _GrantProduct | `(player: Player, productId: number)` | `boolean` | ProcessReceipt 回调：发放产品奖励（金币） |
| _GrantGamePass | `(player: Player, gamePassId: number)` | `boolean` | ProcessReceipt 回调：授予 GamePass 所有权 |
| _CheckExistingGamePasses | `(player: Player)` | `()` | 玩家加入时检查 Roblox 已有 GamePass 所有权 |
| PurchaseWithCoins | `(player: Player, gamePassId: number)` | `boolean, string?` | 服务器端金币购买逻辑（验证→扣款→授权→信号） |

#### 1.7.4 数据清单

| 数据文件 | 路径 | 内容 |
| -------- | ---- | ---- |
| Products.luau | `src/shared/datas/Products.luau` | 3 个 Robux 金币包（500/1500/5000 Coins） |
| GamePasses.luau | `src/shared/datas/GamePasses.luau` | 2 个 GamePass（Double Coins / Extra Stamina） |

#### 1.7.5 购买流程

```
Client (ShopView)                    Server (ShopService)
       │                                     │
       ├── Robux 商品 ──────────────────→ MarketplaceService
       │    PromptProductPurchase()          ProcessReceipt()
       │    ─────────────────────────────    → _GrantProduct()
       │    ← OnPurchaseComplete ─────────     → AwardCoinsDirect()
       │
       ├── Robux GamePass ──────────────→ MarketplaceService
       │    PromptGamePassPurchase()          ProcessReceipt()
       │    ─────────────────────────────    → _GrantGamePass()
       │    ← OnPurchaseComplete ─────────
       │
       └── Coins GamePass ──────────────→ PurchaseWithCoins()
            ShopService:PurchaseWithCoins()  → 验证余额
            ─────────────────────────────    → DeductCoins()
            ← OnPurchaseComplete ─────────    → 记录所有权
                                               → Fire Signal
```

---

### 1.8 MusicService

**文件路径**: `src/server/services/MusicService.luau`

**简述**: 管理游戏音频播放：背景音乐（MusicGroup）和音效（SoundGroup），支持按名称播放、指定父级位置发声。

#### 音频资源位置

| 容器 | 路径 | 内容 |
| ---- | ---- | ---- |
| 背景音乐 | `SoundService.MusicGroup` | `BGM_lobby` |
| 游戏音效 | `SoundService.SoundGroup` | `Picked`, `goal_b`, `cd`, `kickOff`, `gameEnd_b`, `gameEnd_a`, `HitFrame`, `Sprint`, `shoot2`, `Rush`, `goal_c` 等 |

#### 1.8.1 公开方法（Client 表）

| 方法 | 参数 | 返回值 | 权限 | 说明 |
| ---- | ---- | ------ | ---- | ---- |
| PlayMusic | `(name: string)` | `boolean` | Client | 播放指定背景音乐，自动停止前一首 |
| StopMusic | `()` | `()` | Client | 停止当前背景音乐并清理实例 |
| PlaySound | `(name: string, parent: Instance?)` | `boolean` | Client | 播放指定音效，可选指定父级位置 |
| StopAllSounds | `()` | `()` | Client | 停止所有活跃音效 |
| SetVolume | `(volume: number)` | `()` | Client | 设置音量（0~1） |

#### 1.8.2 内部方法

| 方法 | 参数 | 返回值 | 说明 |
| ---- | ---- | ------ | ---- |
| _FindSoundInGroup | `(groupName: string, soundName: string)` | `Sound?` | 在指定 SoundGroup 中按名称查找 Sound 模板 |
| PlayMusic | `(name: string)` | `boolean` | 服务端实现：克隆模板 → 停止旧 BGM → 播放 → 记录引用 |
| StopMusic | `()` | `()` | 服务端实现：停止并销毁当前 BGM 实例 |
| PlaySound | `(name: string, parent: Instance?)` | `boolean` | 服务端实现：克隆模板 → 设置父级 → 播放 → 自动清理 |
| StopAllSounds | `()` | `()` | 停止并销毁所有活跃音效实例 |
| SetVolume | `(volume: number)` | `()` | 更新音量并同步到当前 BGM |

#### 1.8.3 播放行为

| 场景 | 行为 |
| ---- | ---- |
| BGM 播放 | 克隆 `MusicGroup` 下的模板 Sound → 设为 Looped=true → 持续播放 → 调用 `StopMusic`/新 `PlayMusic` 时停止 |
| 音效播放 | 克隆 `SoundGroup` 下的模板 Sound → 播放一次 → `Sound.Ended` 事件触发时自动 `Destroy()` 清理 |
| 指定父级 | 将克隆的 Sound 实例 `.Parent = parent`，音效在父级位置发声（适用于在角色/球门等位置播放） |
| 未指定父级 | 默认挂在 `SoundService` 下（全局发声，所有玩家可闻） |

### 2.1 UIController

**文件路径**: `src/client/controllers/UIController.luau`

**简述**: 主 HUD 控制器——创建 ScreenGui 并组合所有 View，管理数据轮询与事件分发。

#### 监听的服务

| 服务 | 说明 |
| ---- | ---- |
| AutoKickService | 进球信号 → Overlay + Toast |
| NPCTimerService | NPC 激活/倒计时到期 → Toast |
| RewardService | 金币/等级轮询 |

#### 2.1.1 内部方法

| 方法 | 参数 | 说明 |
| ---- | ---- | ---- |
| _CreateHUD | `()` | 创建 ScreenGui 并挂载所有 View（CoreBar/InfoBar/ActionPanel/Overlay/Toast/Shop） |

### 2.3 SoundController

**文件路径**: `src/client/controllers/SoundController.luau`

**简述**: 客户端踢球音效播放——监听 `ReplicatedStorage.SoundEvent` RemoteEvent，收到 `"shoot"` 时在客户端播放。

#### 公开方法

| 方法 | 参数 | 说明 |
| ---- | ---- | ---- |
| PlayShoot | `(parent: Instance?)` | 播放踢球音效，默认挂载玩家角色 HumanoidRootPart |

#### 触发链路

```
Server AutoKickService._FlyBallToGoal
  → SoundEvent:FireAllClients("shoot")
  → Client SoundEvent.OnClientEvent
  → SoundController:PlayShoot()
```

#### 2.1.2 View 组合

| View | 实例变量 | 初始化 |
| ---- | -------- | ------ |
| CoreBarView | `_coreBar` | `_CreateHUD` |
| InfoBarView | `_infoBar` | `_CreateHUD` |
| ActionPanelView | `_actionPanel` | `_CreateHUD` |
| OverlayView | `_overlay` | `_CreateHUD` |
| ToastView | `_toast` | `_CreateHUD` |
| ShopView | `_shopView` | `_CreateHUD`（点击商店按钮打开覆盖层） |

---

### 2.2 CameraController

**文件路径**: `src/client/controllers/CameraController.luau`

**简述**: 管理游戏视角：NPC 随行视角、踢球时镜头跟进、进球回放后复位。

#### 2.1.2 内部方法

| 方法 | 参数 | 说明 |
| ---- | ---- | ---- |
| _FollowNPC | `(npcPosition: Vector3)` | 第三人称跟随 NPC，保持合适距离和角度 |
| _KickCamera | `(ballPos: Vector3, goalPos: Vector3)` | 踢球瞬间镜头切换到球后方，跟随飞行轨迹 |
| _GoalReplayCamera | `(goalPos: Vector3)` | 进球后慢动作回放：从球门方向看球飞入 |
| _ResetCamera | `()` | 回放结束恢复默认第三人称跟随 |

---

## 三、共享类型定义

### 3.1 PlayerTypes

**文件路径**: `src/shared/types/PlayerTypes.luau`

```lua
export type PlayerData = {
    Coins: number,
    Level: number,
    NPCTiers: { [string]: number },  -- npcId → quality level 1~5
    UnlockedNPCs: { string },
}

export type NPCSlotInfo = {
    slotId: number,
    npcId: string,
    quality: number,
    qualityMultiplier: number,
    timerRemaining: number,
}

export type PlayerSession = {
    player: Player,
    activeSlotId: number?,
    data: PlayerData,
}
```

### 3.2 NPCTypes

**文件路径**: `src/shared/types/NPCTypes.luau`

```lua
export type NPCInfo = {
    npcId: string,
    displayName: string,
    model: Model,
    position: Vector3,
    isUnlocked: boolean,
    unlockCost: number?,         -- nil if base/default NPC
}

export type NPCSlotInfo = {
    slotId: number,
    npcId: string,
    totalDuration: number,       -- total countdown seconds
    remaining: number,           -- current remaining seconds
    isActive: boolean,
}

export type TimerState = {
    slotId: number,
    npcId: string,
    startTime: number,           -- os.time
    duration: number,
    remaining: number,
    connection: RBXScriptConnection?,
}
```

### 3.3 GameTypes

**文件路径**: `src/shared/types/GameTypes.luau`

```lua
export type GameState = "Idle" | "TakingOver" | "Walking" | "Kicking" | "GoalReplay"

export type KickResult = {
    npcId: string,
    startPos: Vector3,
    ballPos: Vector3,
    goalPos: Vector3,
    reward: number,
    duration: number,            -- ball flight time
}
```

---

### 3.4 ShopTypes

**文件路径**: `src/shared/types/ShopTypes.luau`

```lua
export type ProductItem = {
    ProductId: number,
    Name: string,
    Description: string,
    PriceRobux: number,
    PriceCoins: number,
    Rewards: { Coins: number }?,
    Icon: string,
}

export type GamePassItem = {
    GamePassId: number,
    Name: string,
    Description: string,
    PriceRobux: number,
    PriceCoins: number,
    Icon: string,
}

export type ShopTab = "Products" | "GamePasses"
```

---

## 四、事件清单

| 事件名 | 触发端 | 参数 | 说明 |
| ------ | ------ | ---- | ---- |
| NPCTimerStarted | 服务端 | `(npcId: string, duration: number)` | NPC 激活倒计时开始 |
| NPCTimerExpired | 服务端 | `(npcId: string)` | NPC 计时归零触发接管 |
| NPCTakeover | 服务端 | `(npcId: string, npcPosition: Vector3)` | 玩家自动传送至 NPC 位置 |
| BallKicked | 服务端 | `(ballPos: Vector3, startPos: Vector3, targetPos: Vector3)` | 球被踢出飞向球门 |
| GoalScored | 服务端 | `(playerId: number, npcId: string, reward: number)` | 球进球门，金币结算 |
| CoinsUpdated | 服务端 | `(newBalance: number, delta: number)` | 玩家金币余额变化 |
| NPCUnlocked | 服务端 | `(npcId: string, cost: number)` | 玩家解锁新 NPC |
| ShopPurchaseComplete | 服务端 | `(itemType: string, itemId: number, info: table)` | 商店购买成功（含 Robux 和 Coins） |
| ShopPurchaseFailed | 服务端 | `(itemType: string, itemId: number, reason: string)` | 商店购买失败 |

---

文档版本: v1.0
最后更新: 2026-06-12
维护者: (待填写)
