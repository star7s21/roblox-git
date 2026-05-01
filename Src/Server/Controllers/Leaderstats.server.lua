local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataStore = DataStoreService:GetDataStore("PlayerData")

-- Base待機
local function waitForBase(player)
	while true do
		local base = workspace:FindFirstChild(player.Name .. "_Base")
		if base and base:FindFirstChild("Base") then
			return base
		end
		task.wait(0.2)
	end
end

-- スナップショット
local function collectBaseData(base)
	local result = {}

	for _, slot in ipairs(base.Base:GetChildren()) do
		local placePart = slot:FindFirstChild("ItemArea")
		local stored = placePart and placePart:FindFirstChild("StoredItem")

		if stored and stored.Value and stored.Value.Parent then
			table.insert(result, {
				slot = slot.Name,
				type = stored.Value.Name,
				value = stored.Value:GetAttribute("Value") or 0
			})
		end
	end

	return result
end

-- 復元
local function spawnItem(base, data)
	local folder = ReplicatedStorage:WaitForChild("Treasures")

	local slot = base.Base:FindFirstChild(data.slot)
	if not slot then return end

	local placePart = slot:FindFirstChild("ItemArea")
	if not placePart then return end

	local template = folder:FindFirstChild(data.type)
	if not template then return end

	local item = template:Clone()
	item.Parent = base
	item:SetAttribute("Value", data.value)

	if item.PrimaryPart then
		item:PivotTo(placePart.CFrame)
	else
		item:MoveTo(placePart.Position)
	end

	local stored = Instance.new("ObjectValue")
	stored.Name = "StoredItem"
	stored.Value = item
	stored.Parent = placePart
end

-- Player
Players.PlayerAdded:Connect(function(player)

	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue", leaderstats)
	coins.Name = "Coins"

	local speed = Instance.new("IntValue", leaderstats)
	speed.Name = "Speed"

	local upgradeCost = Instance.new("IntValue", player)
	upgradeCost.Name = "UpgradeCost"

	local data
	pcall(function()
		data = dataStore:GetAsync(player.UserId)
	end)

	if data then
		coins.Value = data.Coins or 0
		speed.Value = data.Speed or 16
		upgradeCost.Value = data.UpgradeCost or 50
	end

	-- 復元（1回のみ）
	task.spawn(function()

		local base = waitForBase(player)

		-- クリア
		for _, slot in ipairs(base.Base:GetChildren()) do
			local p = slot:FindFirstChild("ItemArea")
			local s = p and p:FindFirstChild("StoredItem")
			if s then
				if s.Value then s.Value:Destroy() end
				s:Destroy()
			end
		end

		-- 復元
		if data and data.BaseItems then
			for _, item in ipairs(data.BaseItems) do
				spawnItem(base, item)
			end
		end
	end)
end)

-- SAVE
local function save(player)

	local base = workspace:FindFirstChild(player.Name .. "_Base")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not base or not leaderstats then return end

	local data = {
		Coins = leaderstats.Coins.Value,
		Speed = leaderstats.Speed.Value,
		UpgradeCost = player:FindFirstChild("UpgradeCost") and player.UpgradeCost.Value or 50,
		BaseItems = collectBaseData(base)
	}

	pcall(function()
		dataStore:SetAsync(player.UserId, data)
	end)
end

Players.PlayerRemoving:Connect(save)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		save(p)
	end
	task.wait(2)
end)