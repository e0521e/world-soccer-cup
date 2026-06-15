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
