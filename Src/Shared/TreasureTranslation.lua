local TreasureTranslation = {}

TreasureTranslation.Translations = {
	["ja-jp"] = {
		-- Rarities
		["Common"] = "コモン",
		["Rare"] = "レア",
		["Epic"] = "エピック",
		["Legendary"] = "レジェンダリー",
		-- Items
		["Bear"] = "クマ",
		["Chair"] = "椅子",
		["67"] = "67",
		["Monster"] = "モンスター",
		["Dog"] = "イヌ",
		["Cat"] = "ネコ",
		["Puppy"] = "子イヌ",
		["Shark"] = "サメ",
		["Cow"] = "牛",
		["Bunny"] = "うさぎ",
		["Frog"] = "カエル",
		["Deamon"] = "デーモン",
		["Dragon"] = "ドラゴン",
		["Phoenix"] = "フェニックス",
		["Axolotl"] = "ウーパールーパー",
		["BlueAxolotl"] = "青ウーパールーパー",
		["Devil"] = "悪魔",
	},
	["en-us"] = {
		-- Rarities
		["Common"] = "Common",
		["Rare"] = "Rare",
		["Epic"] = "Epic",
		["Legendary"] = "Legendary",
		-- Items
		["Bear"] = "Bear",
		["Chair"] = "Chair",
		["67"] = "67",
		["Monster"] = "Monster",
		["Dog"] = "Dog",
		["Cat"] = "Cat",
		["Puppy"] = "Puppy",
		["Shark"] = "Shark",
		["Cow"] = "Cow",
		["Bunny"] = "Bunny",
		["Frog"] = "Frog",
		["Deamon"] = "Deamon",
		["Dragon"] = "Dragon",
		["Phoenix"] = "Phoenix",
		["Axolotl"] = "Axolotl",
		["BlueAxolotl"] = "BlueAxolotl",
		["Devil"] = "Devil",
	}
}

TreasureTranslation.Translations["ja"] = TreasureTranslation.Translations["ja-jp"]
TreasureTranslation.Translations["en"] = TreasureTranslation.Translations["en-us"]

function TreasureTranslation.Translate(text, localeId)
	if not localeId then
		return text
	end
	
	local cleanLocale = string.lower(string.gsub(localeId, "_", "-"))
	local langTable = TreasureTranslation.Translations[cleanLocale]
	
	if not langTable then
		local baseLang = string.split(cleanLocale, "-")[1]
		langTable = TreasureTranslation.Translations[baseLang]
	end
	
	if langTable and langTable[text] then
		return langTable[text]
	end
	
	return text
end

return TreasureTranslation
