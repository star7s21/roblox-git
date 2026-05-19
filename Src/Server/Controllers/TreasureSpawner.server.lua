local configModule = require(game:GetService("ServerScriptService").Server.Services.TreasureConfig)
local config = configModule and configModule.Rarities

local TreasureModule = require(game:GetService("ServerScriptService").Server.Services.Treasure)
local treasureFolder = game.ReplicatedStorage:WaitForChild("Treasures")

-- ランダム
local function getRandomTreasure(level)
	level = tonumber(level) or 1
	local weighted = {}

	if not config then return nil end

	for _, rarity in ipairs(config) do
		local weight = rarity.chance or 0

		if rarity.name == "Rare" then
			weight = weight + (level * 5)
		elseif rarity.name == "Epic" then
			weight = weight + (level * 3)
		elseif rarity.name == "Legendary" then
			weight = weight + (level * 2)
		end

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
	treasure:SetAttribute("Level", level)

	-- 名前表示
	if treasure.PrimaryPart then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 60, 0, 20)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = treasure.PrimaryPart

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = item.name
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
