local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreasureTranslation = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreasureTranslation"))

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
			{ name = "Bear", model = "Bear" },
			{ name = "Chair", model = "Chair" },
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
			{ name = "67", model = "67" }
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
			{ name = "Monster", model = "Monster" }
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
			{ name = "Dog", model = "Dog" }
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

local function getLocaleId(playerOrLocale)
	if type(playerOrLocale) == "string" and playerOrLocale ~= "" then
		return playerOrLocale
	elseif typeof(playerOrLocale) == "Instance" and playerOrLocale:IsA("Player") then
		local success, localeId = pcall(function()
			return playerOrLocale.LocaleId
		end)
		if success and localeId and localeId ~= "" then
			return localeId
		end
	end
	
	local LocalizationService = game:GetService("LocalizationService")
	local success, localeId = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	if success and localeId and localeId ~= "" then
		return localeId
	end
	
	return "en-us"
end

function TreasureConfig.GetLocalizedRarityName(rarityName, playerOrLocale)
	local localeId = getLocaleId(playerOrLocale)
	return TreasureTranslation.Translate(rarityName, localeId)
end

function TreasureConfig.GetLocalizedDisplayName(nameOrModel, playerOrLocale)
	local localeId = getLocaleId(playerOrLocale)
	local displayName = TreasureConfig.GetDisplayName(nameOrModel)
	return TreasureTranslation.Translate(displayName, localeId)
end

return TreasureConfig
