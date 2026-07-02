local configModule = require(game:GetService("ServerScriptService").Server.Services.TreasureConfig)
local config = configModule and configModule.Rarities

local TreasureModule = require(game:GetService("ServerScriptService").Server.Services.Treasure)
local treasureFolder = game.ReplicatedStorage:WaitForChild("Treasures")

-- ==========================================================
-- バランス調整用設定テーブル
-- ==========================================================

-- エリアのレベルに応じた各レアリティの出現比率（重み）
local RARITY_WEIGHTS = {
	[1] = { Common = 80, Rare = 15, Epic = 4.5, Legendary = 0.5 },
	[2] = { Common = 60, Rare = 25, Epic = 13,   Legendary = 2   },
	[3] = { Common = 40, Rare = 35, Epic = 20,   Legendary = 5   },
	[4] = { Common = 25, Rare = 40, Epic = 25,   Legendary = 10  },
	[5] = { Common = 15, Rare = 35, Epic = 35,   Legendary = 15  },
	[6] = { Common = 5,  Rare = 25, Epic = 45,   Legendary = 25  },
	[7] = { Common = 1,  Rare = 14, Epic = 50,   Legendary = 35  },
}

-- エリアのレベルに応じた、モデルのレベル(Lv)の出現帯と確率（重み）
local LEVEL_RANGES = {
	[1] = {
		{ min = 1,  max = 10, weight = 90 },
		{ min = 11, max = 20, weight = 10 },
	},
	[2] = {
		{ min = 10, max = 20, weight = 70 },
		{ min = 21, max = 30, weight = 30 },
	},
	[3] = {
		{ min = 20, max = 30, weight = 70 },
		{ min = 31, max = 40, weight = 30 },
	},
	[4] = {
		{ min = 30, max = 40, weight = 60 },
		{ min = 41, max = 50, weight = 40 },
	},
	[5] = {
		{ min = 40, max = 50, weight = 60 },
		{ min = 51, max = 60, weight = 40 },
	},
	[6] = {
		{ min = 50, max = 60, weight = 50 },
		{ min = 61, max = 70, weight = 50 },
	},
	[7] = {
		{ min = 50, max = 60, weight = 15 },
		{ min = 61, max = 70, weight = 85 },
	}
}

-- ==========================================================
-- ロジック
-- ==========================================================

-- エリアレベルからモデルレベルを決定
local function getRandomModelLevel(areaLevel)
	areaLevel = tonumber(areaLevel) or 1
	local ranges = LEVEL_RANGES[areaLevel] or LEVEL_RANGES[1]

	local total = 0
	for _, range in ipairs(ranges) do
		total = total + range.weight
	end

	local rand = math.random() * total
	local sum = 0
	local selectedRange = ranges[1]
	for _, range in ipairs(ranges) do
		sum = sum + range.weight
		if rand <= sum then
			selectedRange = range
			break
		end
	end

	return math.random(selectedRange.min, selectedRange.max)
end

-- ランダム
local function getRandomTreasure(areaLevel)
	areaLevel = tonumber(areaLevel) or 1
	local weighted = {}

	if not config then return nil end

	local weightTable = RARITY_WEIGHTS[areaLevel] or RARITY_WEIGHTS[1]

	for _, rarity in ipairs(config) do
		local weight = weightTable[rarity.name] or 0
		table.insert(weighted, {data = rarity, weight = weight})
	end

	local total = 0
	for _, w in ipairs(weighted) do
		total = total + (w.weight or 0)
	end

	local selectedRarity = config[1]
	if total > 0 then
		local rand = math.random() * total
		local sum = 0

		for _, w in ipairs(weighted) do
			sum = sum + (w.weight or 0)
			if rand <= sum then
				selectedRarity = w.data
				break
			end
		end
	end

	-- レア度からランダムにアイテムを選択
	local items = selectedRarity.items
	if not items or #items == 0 then return nil end

	local selectedItem = items[math.random(1, #items)]

	return { rarity = selectedRarity, item = selectedItem }
end

-- スポーン
local function spawnTreasure(position, level)
	local data = getRandomTreasure(level)
	if not data or not data.rarity or not data.item then return end

	local rarity = data.rarity
	local item = data.item

	local template = treasureFolder:FindFirstChild(item.model)
	if not template then return end

	local treasure = template:Clone()
	treasure:SetAttribute("Model", item.model)
	treasure:SetAttribute("DisplayName", item.name)
	treasure.Parent = workspace

	-- PrimaryPart保険
	if not treasure.PrimaryPart then
		local root = treasure:FindFirstChild("HumanoidRootPart") 
			or treasure:FindFirstChildWhichIsA("BasePart")
		if root then
			treasure.PrimaryPart = root
		end
	end

	if treasure.PrimaryPart then
		treasure:PivotTo(CFrame.new(position))
	end

	-- 色
	for _, part in ipairs(treasure:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = rarity.color
		end
	end

	-- レベル設定
	local modelLevel = getRandomModelLevel(level)
	treasure:SetAttribute("Level", modelLevel)

	-- 名前表示
	if treasure.PrimaryPart then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 60, 0, 20)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = treasure.PrimaryPart

		local locRarityName = configModule.GetLocalizedRarityName(rarity.name)
		local locDisplayName = configModule.GetLocalizedDisplayName(item.model)

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = locRarityName .. "\n" .. locDisplayName
		text.TextColor3 = rarity.color
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.new(0,0,0)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextWrapped = false
		text.Parent = billboard
	end

	TreasureModule.setupTreasure(treasure)
end

-- スポーン
for level = 1, 7 do
	local area = workspace:WaitForChild("Level"..level)

	local size = area.Size
	local pos = area.Position

	for i = 1, 10 do
		local x = pos.X + math.random(-size.X/2, size.X/2)
		local z = pos.Z + math.random(-size.Z/2, size.Z/2)
		local y = pos.Y + size.Y/2 + 3

		spawnTreasure(Vector3.new(x, y, z), level)
	end
end
