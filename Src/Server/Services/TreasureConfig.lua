local TreasureConfig = {}

TreasureConfig.Rarities = {
	{ 
		name = "Common", 
		chance = 60, 
		baseCoinsPerSecond = 2, 
		baseCapacityTime = 120, 
		rarityMultiplier = 1, 
		capacityMultiplier = 1, 
		levelMultiplier = 1.2, 
		color = Color3.fromRGB(150,150,150),
		items = {
			{ name = "Common Treasure", model = "CommonTreasure" }
		}
	},
	{ 
		name = "Rare", 
		chance = 25, 
		baseCoinsPerSecond = 2, 
		baseCapacityTime = 120, 
		rarityMultiplier = 3, 
		capacityMultiplier = 1, 
		levelMultiplier = 1.2, 
		color = Color3.fromRGB(0,170,255),
		items = {
			{ name = "Rare Treasure", model = "RareTreasure" }
		}
	},
	{ 
		name = "Epic", 
		chance = 10, 
		baseCoinsPerSecond = 2, 
		baseCapacityTime = 120, 
		rarityMultiplier = 8, 
		capacityMultiplier = 1, 
		levelMultiplier = 1.2, 
		color = Color3.fromRGB(170,0,255),
		items = {
			{ name = "Epic Treasure", model = "EpicTreasure" }
		}
	},
	{ 
		name = "Legendary", 
		chance = 5, 
		baseCoinsPerSecond = 2, 
		baseCapacityTime = 120, 
		rarityMultiplier = 20, 
		capacityMultiplier = 1, 
		levelMultiplier = 1.2, 
		color = Color3.fromRGB(255,170,0),
		items = {
			{ name = "Legendary Treasure", model = "LegendaryTreasure" }
		}
	},
}

function TreasureConfig.GetRarity(nameOrModel)
	for _, rarity in ipairs(TreasureConfig.Rarities) do
		if rarity.name == nameOrModel then return rarity end
		if rarity.items then
			for _, item in ipairs(rarity.items) do
				if item.model == nameOrModel or item.name == nameOrModel then
					return rarity
				end
			end
		end
	end
	return nil
end

function TreasureConfig.GetDisplayName(nameOrModel)
	for _, rarity in ipairs(TreasureConfig.Rarities) do
		if rarity.items then
			for _, item in ipairs(rarity.items) do
				if item.model == nameOrModel or item.name == nameOrModel then
					return item.name
				end
			end
		end
	end
	return nameOrModel
end

return TreasureConfig
