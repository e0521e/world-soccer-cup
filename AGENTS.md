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

- 脚本文件：*.server.luau（服务器）、*.client.luau（客户端）、init.luau（ModuleScript）
- 文件夹：PascalCase（如 PlayerData）

## AI 工作原则

1. 在任何文件修改前，先说明意图
2. 涉及架构决策时，引用 game-design.md 和 architecture.md
3. 不确定的地方主动询问，不要猜测
4. 涉及 Rojo 同步问题时，参考 .kilo/skills/rojo-pro.md

## 禁止事项

- 不要修改 Packages/ 目录（由 wally install 生成）
- 不要在 Server 代码中放客户端逻辑（安全风险）

## Markdown 格式约定

- 表格分隔符行必须使用空格对齐风格：`| --- | ----- | ------ |`
- 所有 Markdown 表格的每列内容前后都应有空格（与分隔符风格一致）
