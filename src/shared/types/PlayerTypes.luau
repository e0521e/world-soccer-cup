--!strict

export type PlayerData = {
    Coins: number,
    Level: number,
    NPCTiers: { [string]: number },
    UnlockedNPCs: { string },
}

export type NPCSlotInfo = {
    slotId: number,
    npcId: string,
    quality: number,
    qualityMultiplier: number,
    timerRemaining: number,
}

return {}
