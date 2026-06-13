--!strict

local NPCList = {
    { id = "messi", displayName = "Lionel Messi", defaultQuality = 1 },
    { id = "ronaldo", displayName = "Cristiano Ronaldo", defaultQuality = 1 },
    { id = "neymar", displayName = "Neymar Jr", defaultQuality = 1 },
    { id = "kane", displayName = "Harry Kane", defaultQuality = 1 },
    { id = "lewandowski", displayName = "Lewandowski", defaultQuality = 1 },
    { id = "modric", displayName = "Modric", defaultQuality = 1 },
    { id = "benzema", displayName = "Benzema", defaultQuality = 1 },
    { id = "mbappe", displayName = "Mbappe", defaultQuality = 1 },
    { id = "haaland", displayName = "Haaland", defaultQuality = 1 },
    { id = "salah", displayName = "Salah", defaultQuality = 1 },
}

local QualityTiers = {
    { level = 1, name = "Common", multiplier = 1.0, visualEffect = "none", cooldown = 10 },
    { level = 2, name = "Rare", multiplier = 1.5, visualEffect = "jersey", cooldown = 8 },
    { level = 3, name = "Epic", multiplier = 2.0, visualEffect = "gold", cooldown = 6 },
    { level = 4, name = "Legendary", multiplier = 3.0, visualEffect = "glow", cooldown = 4 },
    { level = 5, name = "Mythic", multiplier = 5.0, visualEffect = "dynamic", cooldown = 2 },
}

return { NPCList = NPCList, QualityTiers = QualityTiers }
