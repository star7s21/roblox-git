local configModule = require(game:GetService("ServerScriptService").Server.Services.TreasureConfig)
local config = configModule and configModule.Types

local TreasureModule = require(game:GetService("ServerScriptService").Server.Services.Treasure)
local treasureFolder = game.ReplicatedStorage:WaitForChild("Treasures")

-- ランダム
local function getRandomTreasure(level)
	level = tonumber(level) or 1
	local weighted = {}

	if not config then return nil end

	for _, t in ipairs(config) do
		local weight = t.chance or 0

		if t.name == "Rare" then
			weight = weight + (level * 5)
		elseif t.name == "Epic" then
			weight = weight + (level * 3)
		elseif t.name == "Legendary" then
			weight = weight + (level * 2)
		end

		table.insert(weighted, {data = t, weight = weight})
	end

	local total = 0
	for _, w in ipairs(weighted) do
		total = total + (w.weight or 0)
	end

	if total <= 0 then return config[1] end

	local rand = math.random() * total
	local sum = 0

	for _, w in ipairs(weighted) do
		sum = sum + (w.weight or 0)
		if rand <= sum then
			return w.data
		end
	end

	return config[1]
end

-- スポーン
local function spawnTreasure(position, level)
	local t = getRandomTreasure(level)
	if not t then return end

	local template = treasureFolder:FindFirstChild(t.model)
	local treasure = template:Clone()
	treasure:SetAttribute("Model", t.model)
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
			part.Color = t.color
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
		text.Text = t.name
		text.TextColor3 = t.color
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
		local y = pos.Y + size.Y/2 + 14

		spawnTreasure(Vector3.new(x, y, z), level)
	end
end
