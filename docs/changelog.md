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

- `FieldManagerService` — 6 场克隆、2 列镜像排布、玩家分配/释放、场主标牌 `FieldOwnerGui`（头像+名字，分配亮/离开灭）
- `NPCProgressService` — 在线时间进度、NPC 解锁队列、供 UI 轮询的 `GetElapsedTime` RemoteFunction
- `BallSpawnService` — 按场禁区掉球（CenterX/CenterZ 属性）、3 球上限、自动踢检测
- 10 NPC 预分配轮转（`_AdvanceSlotNPC`）：槽 1/2/3 错开倒计时，到期自动补位
- Player 子文件夹下 4 个子文件夹（Retro/Trending/Popular/Icons）80+ 球星模型
- HUD 进度条（5 圆点+金条+MM:SS 时间标签）+ Coins 轮询显示
- 玩家靠近球场中心自动踢球（AUTO_KICK_DISTANCE=6）
- NPC 跑动动画（rbxassetid://913376220）和踢球动画（rbxassetid://129320048058024）

### 变更

- `Field_1` Folder 转换为 Model（含 PrimaryPart），存于 `ServerStorage.FieldTemplate`
- NPC 查找路径固定为 `ServerStorage.Player` 子目录（`GetDescendants` 遍历）
- NPCTimerService 从随机选 NPC 改为预分配轮转
- UIController：Coins/Level 改用 `GetCoins()/GetLevel()` 轮询代替不可达的 Knit 信号
- Knit 信号断层：全部未消费信号接入空操作处理器防队列积压
- 球场布局：Row A X=-10 正常 + Row B X=10 绕 Y 旋转 180°
- 模板中的 BillBoardGui 默认隐藏（Enabled=false），分配后显示
- DataStore 写入节流：每 15 秒最多存一次

### 新增613

- docs/ 目录及文档体系搭建
  - `docs/game-design.md` — 游戏设计文档（半场自由踢射门挑战）
  - `docs/architecture.md` — 技术架构文档（Knit + 服务/控制器）
  - `docs/api-reference.md` — API 参考文档（模块接口定义）
  - `docs/changelog.md` — 变更日志
- AGENTS.md 新增文档体系、项目状态和工作流说明
- AGENTS.md 新增 Studio + Rojo 混合工作流指导

### 变更613

- game-design.md 从 11v11 多人足球改为单人半场自由踢射门挑战
- architecture.md 从多人比赛架构改为单机射门挑战架构
- api-reference.md 从多人比赛 API 改为射门挑战 API

---

文档版本: v0.1
最后更新: 2026-06-12
维护者: (待填写)
