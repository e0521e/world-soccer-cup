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
- docs/ 目录及文档体系搭建
  - `docs/game-design.md` — 游戏设计文档（半场自由踢射门挑战）
  - `docs/architecture.md` — 技术架构文档（Knit + 服务/控制器）
  - `docs/api-reference.md` — API 参考文档（模块接口定义）
  - `docs/changelog.md` — 变更日志
- AGENTS.md 新增文档体系、项目状态和工作流说明
- AGENTS.md 新增 Studio + Rojo 混合工作流指导

### 变更
- game-design.md 从 11v11 多人足球改为单人半场自由踢射门挑战
- architecture.md 从多人比赛架构改为单机射门挑战架构
- api-reference.md 从多人比赛 API 改为射门挑战 API

---

文档版本: v0.1
最后更新: 2026-06-12
维护者: (待填写)
