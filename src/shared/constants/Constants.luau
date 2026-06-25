--!strict

local Constants = {
    BASE_COINS = 20,                -- 每次进球的基础金币（计算前）
    ACTIVE_NPC_COUNT = 10,          -- 队伍总 NPC 数量（逐步解锁）
    FIELD_NPC_SLOTS = 3,            -- 场上同时可见的等待插槽数
    COUNTDOWN_MIN = 15,             -- (已废弃，改用品质 cd)
    COUNTDOWN_MAX = 30,             -- (已废弃，改用品质 cd)
    BALL_FLIGHT_DURATION = 1.5,     -- 球飞行弧线时长（秒）
    BALL_ARC_MIN = 3,               -- 球飞行弧线最小高度（studs）
    BALL_ARC_MAX = 10,              -- 球飞行弧线最大高度（studs）
    MAX_NPC_QUALITY = 5,            -- NPC 品质上限（1-5 级）
    DATASTORE_KEY = "PlayerData_",  -- DataStore 存储键前缀
    BALL_SPAWN_INTERVAL = 6,        -- 掉球间隔（秒）
    BALL_SPAWN_DROP_HEIGHT = 50,    -- 球掉落起始高度（studs）
    BALL_LAND_Y = 1.0,              -- 球落地目标 Y 坐标
    AUTO_KICK_DISTANCE = 6,         -- 自动踢球触发距离（studs）
    NPC_WALK_SPEED = 16,            -- NPC 走向球时的移动速度（studs/s）
    MAX_BALLS_ON_FIELD = 3,         -- 场上同时存在的球数量上限
    MAX_BALLS_PER_PLAYER = 11,      -- 每个玩家同时拥有的球数量上限（一队最多11人）
    NPC_RUN_ANIM_ID = "rbxassetid://913376220",    -- NPC 奔跑动画 ID
    ONLINE_TOTAL_MINUTES = 5,       -- 在线进度总时长（分钟）- 测试阶段减半
    NPC_UNLOCK_COUNTDOWN = 30,      -- NPC 槽位初始倒计时（秒）
    MAX_ACTIVE_NPCS = 10,           -- 场上同时踢球 NPC 上限
    WORLD_CUP_REQUIRED_NPCS = 10,   -- 参加世界杯所需最少 NPC 数量
    HEAD_CAM_FOV = 50,              -- NPC 头像相机视野角度（度）
    USER_ICON_TEMPLATE = "rbxthumb://type=AvatarHeadShot&id=%s&w=60&h=60",  -- 玩家头像 URL 模板
    LEADERBOARD_CACHE_SECONDS = 60, -- 排行榜缓存时间（秒）

    -- 金币格式化：最多 4 位有效数字，超千加 K/M/B
    FormatCoins = function(amount: number): string
        if amount >= 1000000000 then
            return string.format("%.2fB", amount / 1000000000)
        elseif amount >= 1000000 then
            return string.format("%.2fM", amount / 1000000)
        elseif amount >= 1000 then
            return string.format("%.2fK", amount / 1000)
        else
            return tostring(math.floor(amount))
        end
    end,
}

return Constants
