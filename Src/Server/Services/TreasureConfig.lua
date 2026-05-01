local TreasureConfig = {}

TreasureConfig.Types = {
	{ name = "Common", chance = 60, coins = 10, model = "CommonTreasure", color = Color3.fromRGB(150,150,150) },
	{ name = "Rare", chance = 25, coins = 30, model = "RareTreasure", color = Color3.fromRGB(0,170,255) },
	{ name = "Epic", chance = 10, coins = 80, model = "EpicTreasure", color = Color3.fromRGB(170,0,255) },
	{ name = "Legendary", chance = 5, coins = 200, model = "LegendaryTreasure", color = Color3.fromRGB(255,170,0) },
}

return TreasureConfig