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
    [2] = { Common = 65, Rare = 22, Epic = 11,  Legendary = 2   },
    [3] = { Common = 50, Rare = 30, Epic = 16,  Legendary = 4   },
    [4] = { Common = 35, Rare = 35, Epic = 22,  Legendary = 8   },
    [5] = { Common = 20, Rare = 35, Epic = 30,  Legendary = 15  },
    [6] = { Common = 10, Rare = 30, Epic = 40,  Legendary = 20  },
    [7] = { Common = 5,  Rare = 25, Epic = 50,  Legendary = 20  },
}

-- エリアのレベルに応じた、モデルのレベル(Lv)の出現帯と確率（重み）
local LEVEL_RANGES = {
    [1] = {
        { min = 1,  max = 15, weight = 90 },
        { min = 16, max = 25, weight = 10 },
    },
    [2] = {
        { min = 10, max = 25, weight = 70 },
        { min = 26, max = 35, weight = 30 },
    },
    [3] = {
        { min = 20, max = 35, weight = 70 },
        { min = 36, max = 45, weight = 30 },
    },
    [4] = {
        { min = 30, max = 45, weight = 60 },
        { min = 46, max = 55, weight = 40 },
    },
    [5] = {
        { min = 40, max = 55, weight = 60 },
        { min = 56, max = 65, weight = 40 },
    },
    [6] = {
        { min = 50, max = 65, weight = 50 },
        { min = 66, max = 75, weight = 50 },
    },
    [7] = {
        { min = 60, max = 75, weight = 20 },
        { min = 76, max = 100, weight = 80 },
    },
}

-- エリアごとのスポーン・リスポーン詳細設定
local SPAWN_SETTINGS = {
	-- [エリアレベル] = { targetCount = 最大維持数, minRespawnTime = 最短リスポーン秒, maxRespawnTime = 最長リスポーン秒 }
	[1] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
	[2] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
	[3] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
	[4] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
	[5] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
	[6] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
	[7] = { targetCount = 10, minRespawnTime = 30, maxRespawnTime = 60 },
}

-- ==========================================================
-- ロジック
-- ==========================================================

-- エリア内のランダムな位置を取得
local function getRandomPositionInArea(level)
	local area = workspace:WaitForChild("Level" .. level)
	local size = area.Size
	local pos = area.Position

	local x = pos.X + math.random(-size.X / 2, size.X / 2)
	local z = pos.Z + math.random(-size.Z / 2, size.Z/ 2)
	local y = pos.Y + size.Y / 2 + 3

	return Vector3.new(x, y, z)
end

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

	-- レベル設定
	local modelLevel = getRandomModelLevel(level)
	treasure:SetAttribute("Level", modelLevel)

	-- 取得時に一定時間後リスポーン
	treasure.Destroying:Connect(function()
		-- プレイヤーが取得した場合のみリスポーン
		if not treasure:GetAttribute("Collected") then
			return
		end

		local settings = SPAWN_SETTINGS[level] or {
			minRespawnTime = 30,
			maxRespawnTime = 60,
		}

		local respawnDelay = math.random(
			settings.minRespawnTime,
			settings.maxRespawnTime
		)

		task.delay(respawnDelay, function()
			local newPosition = getRandomPositionInArea(level)
			spawnTreasure(newPosition, level)
		end)
	end)

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

-- 初期スポーン
for level = 1, 7 do
	local settings = SPAWN_SETTINGS[level] or { targetCount = 10 }
	for i = 1, settings.targetCount do
		local pos = getRandomPositionInArea(level)
		spawnTreasure(pos, level)
	end
end
