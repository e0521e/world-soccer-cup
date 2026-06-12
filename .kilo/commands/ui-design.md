---
name: ui-design
description: 在 Roblox Studio 中创建 UI 的标准化流程
---

# UI 设计工作流

## 阶段 1：需求收集

- 询问 UI 的功能目标
- 确定用户交互流程
- 收集视觉风格参考

## 阶段 2：设计文档

- 在 `docs/ui/[feature]/design.md` 中撰写设计说明
- 包括组件清单、布局草图、交互说明

## 阶段 3：Studio 实现

- 使用 `create_ui_tree` 创建 UI 骨架
- 使用 `set_properties` 调整视觉属性
- 使用 `get_ui_tree` 验证结构

## 阶段 4：标识绑定

- 为功能性组件添加 Tag
- 为需要唯一引用的组件设置 Attribute ID
- 在 `docs/ui/[feature]/mapping.md` 中记录映射

## 阶段 5：设计审查

- 总结完成的工作
- 等待用户确认视觉效果
- 准备好映射表供代码阶段使用
