local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataStore = DataStoreService:GetDataStore("PlayerData")

-- =========================
-- Base待機
-- =========================
local function waitForBase(player)
	while true do
		local base = workspace:FindFirstChild(player.Name .. "_Base")
		if base and base:FindFirstChild("Base") then
			return base
		end
		task.wait(0.2)
	end
end

-- =========================
-- 保存用データ取得
-- =========================
local function collectBaseData(base)

	local result = {}

	for _, slot in ipairs(base.Base:GetChildren()) do
		local stored = slot:FindFirstChild("StoredItem")

		if stored and stored.Value then
			local item = stored.Value

			table.insert(result, {
				slot = slot.Name,
				type = item.Name,
				value = item:GetAttribute("Value") or 0
			})
		end
	end

	return result
end

-- =========================
-- アイテム復元
-- =========================
local function spawnItem(player, base, data)

	local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

	local slot = base.Base:FindFirstChild(data.slot)
	if not slot then return end

	local template = treasureFolder:FindFirstChild(data.type)
	if not template then return end

	local item = template:Clone()
	item.Parent = base
	item:SetAttribute("Value", data.value or 0)

	if item.PrimaryPart then
		item:PivotTo(slot.CFrame)
	else
		item:MoveTo(slot.Position)
	end

	local stored = Instance.new("ObjectValue")
	stored.Name = "StoredItem"
	stored.Value = item
	stored.Parent = slot
end

-- =========================
-- Player
-- =========================
Players.PlayerAdded:Connect(function(player)

	-- leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local speed = Instance.new("IntValue")
	speed.Name = "Speed"
	speed.Parent = leaderstats

	local upgradeCost = Instance.new("IntValue")
	upgradeCost.Name = "UpgradeCost"
	upgradeCost.Parent = player

	-- =========================
	-- LOAD
	-- =========================
	local data
	local success = pcall(function()
		data = dataStore:GetAsync(tostring(player.UserId))
	end)

	-- 必要な時にリセット！→true
	local DEV_RESET = false
	if DEV_RESET then
		print("DEV RESET:", player.Name)
		pcall(function()
			dataStore:RemoveAsync(tostring(player.UserId))
		end)
		data = nil
	end

	if success and data then
		coins.Value = data.Coins or 0
		speed.Value = data.Speed or 16
		upgradeCost.Value = data.UpgradeCost or 50
	else
		coins.Value = 0
		speed.Value = 16
		upgradeCost.Value = 50
	end

	-- =========================
	-- CHARACTER
	-- =========================
	player.CharacterAdded:Connect(function(char)

		local humanoid = char:WaitForChild("Humanoid")
		local base = waitForBase(player)

		-- スピード同期
		humanoid.WalkSpeed = speed.Value

		speed:GetPropertyChangedSignal("Value"):Connect(function()
			humanoid.WalkSpeed = speed.Value
		end)

		-- =========================
		-- 復元
		-- =========================
		if data and data.BaseItems then
			for _, item in ipairs(data.BaseItems) do
				spawnItem(player, base, item)
			end
		end
	end)
end)

-- =========================
-- SAVE
-- =========================
local function savePlayer(player)

	local base = workspace:FindFirstChild(player.Name .. "_Base")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not base or not leaderstats then return end

	local dataToSave = {
		Coins = leaderstats.Coins.Value,
		Speed = leaderstats.Speed.Value,
		UpgradeCost = player:FindFirstChild("UpgradeCost") and player.UpgradeCost.Value or 50,
		BaseItems = collectBaseData(base)
	}

	local success, err = pcall(function()
		dataStore:SetAsync(tostring(player.UserId), dataToSave)
	end)

	if success then
		print("SAVE OK:", player.Name)
	else
		warn("SAVE FAILED:", err)
	end
end

Players.PlayerRemoving:Connect(savePlayer)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		savePlayer(p)
	end
	task.wait(2)
end)