local TreasureConfig = {}

TreasureConfig.Types = {
	{ name = "Common", chance = 60, baseCoinsPerSecond = 2, baseCapacityTime = 120, rarityMultiplier = 1, capacityMultiplier = 1, levelMultiplier = 1.2, model = "CommonTreasure", color = Color3.fromRGB(150,150,150) },
	{ name = "Rare", chance = 25, baseCoinsPerSecond = 2, baseCapacityTime = 120, rarityMultiplier = 3, capacityMultiplier = 1, levelMultiplier = 1.2, model = "RareTreasure", color = Color3.fromRGB(0,170,255) },
	{ name = "Epic", chance = 10, baseCoinsPerSecond = 2, baseCapacityTime = 120, rarityMultiplier = 8, capacityMultiplier = 1, levelMultiplier = 1.2, model = "EpicTreasure", color = Color3.fromRGB(170,0,255) },
	{ name = "Legendary", chance = 5, baseCoinsPerSecond = 2, baseCapacityTime = 120, rarityMultiplier = 20, capacityMultiplier = 1, levelMultiplier = 1.2, model = "LegendaryTreasure", color = Color3.fromRGB(255,170,0) },
}

return TreasureConfig
