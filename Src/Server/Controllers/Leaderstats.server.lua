local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataStore = DataStoreService:GetDataStore("PlayerData")

-- =========================
-- 設定
-- =========================
local DEV_RESET = false -- ← trueで全リセット
local DATA_VERSION = 1  -- ← 変更で強制リセット

-- =========================
-- Base待機（安全版）
-- =========================
local function waitForBase(player)
	for i = 1,50 do
		local base = workspace:FindFirstChild(player.Name .. "_Base")
		if base and base:FindFirstChild("Base") then
			return base
		end
		task.wait(0.2)
	end
	warn("Base not found:", player.Name)
	return nil
end

-- =========================
-- スナップショット
-- =========================
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

-- =========================
-- 復元
-- =========================
local function spawnItem(base, data)
	if not base then return end -- baseがnilの場合の早期リターン

	local folder = ReplicatedStorage:WaitForChild("Treasures")

	local slot = base.Base:FindFirstChild(data.slot)
	if not slot then return end

	local placePart = slot:FindFirstChild("ItemArea")
	if not placePart then return end

	local template = folder:FindFirstChild(data.type)
	if not template then return end

	local item = template:Clone()
	item.Parent = base
	item:SetAttribute("Value", data.value or 0)

	item.PrimaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")

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

-- =========================
-- Player
-- =========================
Players.PlayerAdded:Connect(function(player)

	-- =========================
	-- leaderstats初期化
	-- =========================
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue", leaderstats)
	coins.Name = "Coins"
	coins.Value = 0

	local speed = Instance.new("IntValue", leaderstats)
	speed.Name = "Speed"
	speed.Value = 16

	local upgradeCost = Instance.new("IntValue", player)
	upgradeCost.Name = "UpgradeCost"
	upgradeCost.Value = 50

	-- =========================
	-- LOAD
	-- =========================
	local data

	if DEV_RESET then
		print("DEV RESET:", player.Name)
		pcall(function()
			dataStore:RemoveAsync(player.UserId)
		end)
	else
		pcall(function()
			data = dataStore:GetAsync(player.UserId)
		end)
	end

	-- バージョンチェック
	if data and data.Version ~= DATA_VERSION then
		print("VERSION RESET:", player.Name)
		data = nil
	end

	-- 適用（安全版）
	if data then
		coins.Value = data.Coins or 0

		-- 🔥 Speedバグ防止
		if data.Speed and data.Speed > 0 then
			speed.Value = data.Speed
		end

		upgradeCost.Value = data.UpgradeCost or 50
	end

	-- =========================
	-- Base復元
	-- =========================
	task.spawn(function()

		local base = waitForBase(player)
		if not base then return end

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

-- =========================
-- SAVE（安全版）
-- =========================
local function save(player)

	local base = workspace:FindFirstChild(player.Name .. "_Base")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not base or not leaderstats then return end

	local data = {
		Version = DATA_VERSION,

		Coins = leaderstats:FindFirstChild("Coins") and leaderstats.Coins.Value or 0,

		-- 🔥 Speed安全保存
		Speed = math.max(
			leaderstats:FindFirstChild("Speed") and leaderstats.Speed.Value or 16,
			16
		),

		UpgradeCost = player:FindFirstChild("UpgradeCost") and player.UpgradeCost.Value or 50,

		BaseItems = collectBaseData(base)
	}

	for i = 1,3 do
		local success = pcall(function()
			dataStore:UpdateAsync(player.UserId, function(currentData)
				-- currentData を使用して必要に応じて更新ロジックを適用
				-- ここでは単純に新しいデータ構造を返す
				return data
			end)
		end)

		if success then
			print("SAVE OK:", player.Name)
			return
		end

		task.wait(1)
	end

	warn("SAVE FAILED:", player.Name)
end

Players.PlayerRemoving:Connect(save)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		save(p)
	end
	task.wait(5)
end)
