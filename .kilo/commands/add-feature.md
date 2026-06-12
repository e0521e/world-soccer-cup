---
name: add-feature
description: 在 Rojo 项目中添加新游戏功能
---

# 添加新功能到 Roblox 项目

## 步骤

1. **理解需求**
   - 询问功能的具体行为（玩家交互、触发条件、预期结果）
   - 判断是否需要新数据模型（如 Leaderstats、DataStore）

2. **设计文件结构**
   - 确定代码位置：
     - 纯逻辑 → src/Shared/
     - 服务器权威操作 → src/Server/
     - 客户端 UI/输入 → src/Client/
   - 给出文件路径建议（遵循 Rojo 命名规范）

3. **等待确认**
   - 呈现设计方案
   - 获得用户批准后才开始写代码

4. **实现代码**
   - 生成 .luau 文件（使用正确的 .server/.client 后缀）
   - 包含必要的类型注释（Type Checking）

5. **更新同步**
   - 提醒用户运行 `rojo serve`
   - 提醒用户在 Studio 中测试
