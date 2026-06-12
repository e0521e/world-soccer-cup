--!strict

local Events = {
    NPCTimerStarted = "NPCTimerStarted",
    NPCTimerUpdated = "NPCTimerUpdated",
    NPCTimerExpired = "NPCTimerExpired",
    NPCActivated = "NPCActivated",

    NPCWalking = "NPCWalking",
    KickAnimation = "KickAnimation",
    BallFlying = "BallFlying",
    GoalScored = "GoalScored",

    CoinsChanged = "CoinsChanged",
    LevelUp = "LevelUp",
    NPCQualityUp = "NPCQualityUp",
    NPCUnlocked = "NPCUnlocked",

    Takeover = "Takeover",
    CharacterChanged = "CharacterChanged",
    PlayerRespawned = "PlayerRespawned",
}

return Events
