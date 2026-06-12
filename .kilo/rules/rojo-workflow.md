# Rojo 开发工作流规范

## 项目配置文件

- `default.project.json`：开发环境配置（rojo serve 使用）
- `deploy.project.json`：生产环境配置（rojo build 使用）

## 同步规则

- 编辑 src/ 下的任何文件，都要提醒用户运行 `rojo serve` 保持同步
- 修改 default.project.json 后，必须重启 rojo serve
- 遇到 Packages/ 缺失错误 → 运行 `wally install`

## 文件映射（必记）

| 文件路径                      | Roblox 目标                          |
| ------------------------      | ------------------------------------ |
| src/Shared/**/*.luau          | ReplicatedStorage 对应路径           |
| src/Server/**/*.server.luau   |  ServerScriptService 对应路径        |
| src/Client/**/*.client.luau   | StarterPlayerScripts 对应路径        |

## 禁止操作

- 不要在 ReplicatedStorage 中放入服务器专用代码（安全风险）
- 不要混用 .lua 和 .luau 扩展名
- 不要提交 Packages/ 到 Git

> 规则来源：Rojo 官方最佳实践[citation:4] [citation:9]
