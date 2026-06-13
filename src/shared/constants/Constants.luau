--!strict

local Constants = {
    BASE_COINS = 20,                -- 每次进球的基础金币（计算前）
    ACTIVE_NPC_COUNT = 10,          -- 队伍总 NPC 数量（10 分钟逐步解锁）
    FIELD_NPC_SLOTS = 3,            -- 场上同时可见的等待插槽数
    COUNTDOWN_MIN = 15,             -- (已废弃，改用品质 cd)
    COUNTDOWN_MAX = 30,             -- (已废弃，改用品质 cd)
    BALL_FLIGHT_DURATION = 1.5,     -- 球飞行弧线时长（秒）
    MAX_NPC_QUALITY = 5,            -- NPC 品质上限（1-5 级）
    DATASTORE_KEY = "PlayerData_",  -- DataStore 存储键前缀
    BALL_SPAWN_INTERVAL = 6,        -- 掉球间隔（秒）
    BALL_SPAWN_DROP_HEIGHT = 50,    -- 球掉落起始高度（studs）
    BALL_LAND_Y = 1.0,              -- 球落地目标 Y 坐标
    AUTO_KICK_DISTANCE = 6,         -- 自动踢球触发距离（studs）
    NPC_WALK_SPEED = 16,            -- NPC 走向球时的移动速度（studs/s）
    MAX_BALLS_ON_FIELD = 3,         -- 场上同时存在的球数量上限
    NPC_RUN_ANIM_ID = "rbxassetid://913376220",    -- NPC 奔跑动画 ID
    NPC_KICK_ANIM_ID = "rbxassetid://129320048058024", -- NPC 踢球动画 ID
    ONLINE_TOTAL_MINUTES = 5,       -- 在线进度总时长（分钟）- 测试阶段减半
    NPC_UNLOCK_COUNTDOWN = 30,      -- 新 NPC 出现在场上的倒计时（秒）- 测试阶段减半
}

return Constants
