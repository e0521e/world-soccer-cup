# 技能名称: mcp_create_ui

**描述**: 通过 MCP 在 Roblox Studio 中创建 UI 界面

## 触发条件

用户说以下任意说法时自动触发：

- "创建UI {界面名}"
- "新建界面 {界面名}"  
- "在 Studio 创建 {界面名}"
- "MCP 创建 {界面名}"

## 输入参数

- `ui_name`: 界面名称 (如 UI_L1, ShopUI)
- `parent`: 父级路径 (默认 "StarterGui")
- `ui_type`: 界面类型 (默认 "ScreenGui")

## 执行步骤

1. 调用 MCP 工具 `create_instance`
2. 参数:

   ```json
   {
     "className": "ScreenGui",
     "name": "{ui_name}",
     "parent": "game:GetService('StarterGui')"
   }
   ```
