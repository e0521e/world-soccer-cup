--!strict

export type ProductItem = {
    ProductId: number,
    Name: string,
    Description: string,
    PriceRobux: number,
    PriceCoins: number,
    Rewards: { Coins: number }?,
    Icon: string,
}

export type GamePassItem = {
    GamePassId: number,
    Name: string,
    Description: string,
    PriceRobux: number,
    PriceCoins: number,
    Icon: string,
}

export type ShopTab = "Products" | "GamePasses"

return {}
