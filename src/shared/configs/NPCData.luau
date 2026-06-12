--!strict

local NPCList = {
    { id = "messi", displayName = "Lionel Messi", defaultQuality = 1 },
    { id = "ronaldo", displayName = "Cristiano Ronaldo", defaultQuality = 1 },
    { id = "neymar", displayName = "Neymar Jr", defaultQuality = 1 },
    { id = "kane", displayName = "Harry Kane", defaultQuality = 1 },
    { id = "salah", displayName = "Mohamed Salah", defaultQuality = 1 },
    { id = "lewandowski", displayName = "Robert Lewandowski", defaultQuality = 1 },
    { id = "modric", displayName = "Luka Modric", defaultQuality = 1 },
    { id = "benzema", displayName = "Karim Benzema", defaultQuality = 1 },
    { id = "mbappe", displayName = "Kylian Mbappé", defaultQuality = 1 },
    { id = "haaland", displayName = "Erling Haaland", defaultQuality = 1 },
    { id = "debruyne", displayName = "Kevin De Bruyne", defaultQuality = 1 },
    { id = "vandijk", displayName = "Virgil van Dijk", defaultQuality = 1 },
    { id = "mane", displayName = "Sadio Mané", defaultQuality = 1 },
    { id = "ramos", displayName = "Sergio Ramos", defaultQuality = 1 },
    { id = "kroos", displayName = "Toni Kroos", defaultQuality = 1 },
    { id = "marcelo", displayName = "Marcelo", defaultQuality = 1 },
    { id = "iniesta", displayName = "Andrés Iniesta", defaultQuality = 1 },
    { id = "ibrahimovic", displayName = "Zlatan Ibrahimović", defaultQuality = 1 },
    { id = "bale", displayName = "Gareth Bale", defaultQuality = 1 },
    { id = "hazard", displayName = "Eden Hazard", defaultQuality = 1 },
    { id = "griezmann", displayName = "Antoine Griezmann", defaultQuality = 1 },
    { id = "courtois", displayName = "Thibaut Courtois", defaultQuality = 1 },
    { id = "neuer", displayName = "Manuel Neuer", defaultQuality = 1 },
    { id = "beckham", displayName = "David Beckham", defaultQuality = 1 },
}

local QualityTiers = {
    { level = 1, name = "Common", multiplier = 1.0, visualEffect = "none", cooldown = 10 },
    { level = 2, name = "Rare", multiplier = 1.5, visualEffect = "jersey", cooldown = 8 },
    { level = 3, name = "Epic", multiplier = 2.0, visualEffect = "gold", cooldown = 6 },
    { level = 4, name = "Legendary", multiplier = 3.0, visualEffect = "glow", cooldown = 4 },
    { level = 5, name = "Mythic", multiplier = 5.0, visualEffect = "dynamic", cooldown = 2 },
}

return { NPCList = NPCList, QualityTiers = QualityTiers }
