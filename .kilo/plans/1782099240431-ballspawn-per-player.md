# BallSpawnService 改为玩家独立掉球循环

## 目标

- 每个玩家拥有独立的掉球循环，每周期按**动态间隔**等待
- 每个玩家的球数上限 = `max(3, #UnlockedNPCs)`（取代全局固定的 `MAX_BALLS_ON_FIELD`）
- 球关联到所属玩家，便于统计和清理
- 动态间隔：缺口越大等待越短，接近上限时用满 6s

## 涉及文件

| 文件 | 改动 |
|------|------|
| `src/server/services/BallSpawnService.luau` | 重构核心逻辑 |

## 详细改动

### 1. 数据结构变更

`_activeBalls` 保持 flat `{ [ballModel] = data }`，但 data 增加 `player` 字段：

```lua
_activeBalls = {},
_playerLoops = {},
```

**SpawnBall 中保存 player**：

```lua
self._activeBalls[ball] = {
    player = player,
    model = ball,
    mainPart = mainPart,
    inUse = false,
    spawnTime = tick(),
    dropPos = dropPos,
}
```

### 2. 新增辅助方法

```lua
_GetPlayerBallCount = function(self, player)
    local count = 0
    for _, data in pairs(self._activeBalls) do
        if data.player == player then count += 1 end
    end
    return count
end,

_GetPlayerBallCap = function(self, player)
    local pds = Knit.GetService("PlayerDataService")
    local unlocked = pds:GetUnlockedNPCs(player)
    return math.max(3, #unlocked)
end,
```

### 3. 移除全局循环，改为玩家独立循环 + 动态间隔

**KnitStart 移除**：旧的 `while true do task.wait(BALL_SPAWN_INTERVAL) ... end`

**改为**：

```lua
_StartPlayerLoop = function(self, player)
    self._playerLoops[player] = true
    task.spawn(function()
        while self._playerLoops[player] and game:GetService("Players"):FindFirstChild(player.Name) do
            local field = Knit.GetService("FieldManagerService"):GetField(player)
            if field then
                local cap = self:_GetPlayerBallCap(player)
                local current = self:_GetPlayerBallCount(player)
                if current < cap then
                    self:SpawnBall(field, player)
                    current += 1
                end
                local gap = cap - current
                local interval = math.max(1, Constants.BALL_SPAWN_INTERVAL - math.floor(gap / 2))
                task.wait(interval)
            else
                task.wait(Constants.BALL_SPAWN_INTERVAL)
            end
        end
    end)
end,

_StopPlayerLoop = function(self, player)
    self._playerLoops[player] = false
end,
```

**动态间隔验证**（BALL_SPAWN_INTERVAL=6）：

| cap | current | gap | interval |
|-----|---------|-----|----------|
| 10  | 3       | 7   | 6-3=3s   |
| 10  | 6       | 4   | 6-2=4s   |
| 10  | 8       | 2   | 6-1=5s   |
| 10  | 9       | 1   | 6-0=6s   |
| 3   | 0       | 3   | 6-1=5s   |

### 4. KnitStart

```lua
KnitStart = function(self)
    local Players = game:GetService("Players")

    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            repeat task.wait(0.5) until player.Character
            self:_StartPlayerLoop(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:_StopPlayerLoop(player)
        for ball, data in pairs(self._activeBalls) do
            if data.player == player then
                if ball.Parent then ball:Destroy() end
                self._activeBalls[ball] = nil
            end
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            repeat task.wait(0.5) until player.Character
            self:_StartPlayerLoop(player)
        end)
    end

    print("BallSpawnService started")
end,
```

## 边界条件

| 场景 | 行为 |
|------|------|
| 玩家加入时 | 启动独立循环，动态间隔掉球至 cap |
| 玩家离开时 | 停止循环，销毁该玩家所有球 |
| 解锁新 NPC 后 | 下次循环 `_GetPlayerBallCap` 自动升高，继续掉球 |
| 世界杯胜利后 | `#UnlockedNPCs` 不变（持久化），cap 不变，循环继续 |
| 球数超过 cap | 不主动回收，已有球被踢后自然销毁 |
| 场上无 field | 回退到固定 6s 轮询等待 field 分配 |

## 风险

- `_GetPlayerBallCap` 每次循环调 `GetUnlockedNPCs`（RemoteFunction），每 ~3-6s 一次，可接受
- `PlayerRemoving` 需确保可靠触发，否则 `_playerLoops` 会残留
