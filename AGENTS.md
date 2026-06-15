# Roblox 项目 AI 协作规范

## 项目信息

- 项目名称：[自由踢球]
- 使用工具：Rojo + Wally + Luau
- 同步方式：`rojo serve` + Studio 插件

## 代码组织

- src/Shared/ → ReplicatedStorage（客户端+服务器共享）
- src/Server/ → ServerScriptService（仅服务器）
- src/Client/ → StarterPlayerScripts（仅客户端）

## 命名规范

- 脚本文件：*.server.luau（服务器）、*.client.luau（客户端）、*.luau（ModuleScript）
- 文件夹：PascalCase（如 PlayerData）

## UI 显示规范

- 所有 UI 展示文本统一使用英文（包括 Title、Button、Label、Toast、StatusBar 等）
- 游戏内货币符号：Coins 使用 `🪙`，Robux 使用 `utf8.char(0xE002)`
- 避免使用中文 UI 文本，错误消息、提示、按钮文字、状态栏等均用英文

## AI 工作原则

1. 在任何文件修改前，先说明意图
2. 涉及架构决策时，引用 game-design.md 和 architecture.md
3. 不确定的地方主动询问，不要猜测
4. 涉及 Rojo 同步问题时，参考 .kilo/skills/rojo-pro.md

## 禁止事项

- 不要修改 Packages/ 目录（由 wally install 生成）
- 不要在 Server 代码中放客户端逻辑（安全风险）
- 禁止使用 `Model:SetPrimaryPartCFrame()`，必须使用 `Model:PivotTo()` 替代

## Markdown 格式约定

- 表格分隔符行必须使用空格对齐风格：`| --- | ----- | ------ |`
- 所有 Markdown 表格的每列内容前后都应有空格（与分隔符风格一致）

## 文档体系

- `docs/game-design.md` — 游戏设计文档（玩法、机制、数值）
- `docs/architecture.md` — 技术架构文档（Knit 服务/控制器设计）
- `docs/api-reference.md` — API 参考文档（模块接口定义）
- `docs/changelog.md` — 变更日志

## 当前项目状态

### 已完成（Studio 实例）

- 半足球场布局（Workspace.Field_1）含禁区线、中圈、球门
- 24 位球星 NPC（R15 骨骼，放置在场上各处）
- 45 个足球模型（ServerStorage.Ball）含 ProximityPrompt、Highlights、Trail、音效
- 44 个球门模型（ServerStorage.Goal）含 goal_chk 进球检测器
- Knit 框架基础入口（init.server.luau + init.client.luau）

### 待开发（src/ 代码）

- services/ 目录为空 — 需要新建 BallService、GoalService、RewardService、PlayerService
- controllers/ 目录为空 — 需要新建 UIController、InputController、CameraController
- shared/types/ 为空 — 需要定义 BallTypes、GoalTypes、PlayerTypes
- shared/constants/ 为空 — 需要定义事件名、常量
- shared/configs/ 为空 — 需要数据配置
- DataStore 尚未接入 — 需要金币持久化逻辑

## 工作流说明

因项目采用 Studio + Rojo 混合模式：

- Studio 中已存在的实例（球场、模型、NPC）**不应在 src/ 中重复创建**
- src/ 只编写 ServerScriptService / StarterPlayerScripts 下的逻辑脚本
- 修改 default.project.json 后必须重启 `rojo serve`
- Studio 中手动创建的 UI 界面通过 MCP 工具调用，Knit Controller 负责事件绑定
