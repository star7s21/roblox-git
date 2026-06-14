local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataStore = DataStoreService:GetDataStore("PlayerData")
local coinRankingStore = DataStoreService:GetOrderedDataStore("CoinRankingStore_v1")

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

	local function scan(container, floorNum)
		local baseFolder = container:FindFirstChild("Base")
		if not baseFolder then return end

		for _, slot in ipairs(baseFolder:GetChildren()) do
			local placePart = slot:FindFirstChild("ItemArea")
			local stored = placePart and placePart:FindFirstChild("StoredItem")

			if stored and stored.Value and stored.Value.Parent then
				table.insert(result, {
					floor = floorNum,
					slot = slot.Name,
					type = stored.Value.Name,
					level = placePart:GetAttribute("Level") or 1
				})
			end
		end
	end

	scan(base, 1)
	for i = 2, 10 do
		local floor = base:FindFirstChild("Floor" .. i)
		if floor then
			scan(floor, i)
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

	local floorModel = base
	if data.floor and data.floor > 1 then
		floorModel = base:FindFirstChild("Floor" .. data.floor)
	end
	if not floorModel or not floorModel:FindFirstChild("Base") then return end

	local slot = floorModel.Base:FindFirstChild(data.slot)
	if not slot then return end

	local placePart = slot:FindFirstChild("ItemArea")
	if not placePart then return end

	local template = folder:FindFirstChild(data.type)
	if not template then return end

	local item = template:Clone()
	item.Parent = base
	placePart:SetAttribute("Level", data.level or 1)

	item.PrimaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")

	local yOffset = (placePart.Size.Y / 2) + (item:GetExtentsSize().Y / 2)
	if item.PrimaryPart then
		item:PivotTo(placePart.CFrame * CFrame.new(0, yOffset, 0))
	else
		item:MoveTo((placePart.CFrame * CFrame.new(0, yOffset, 0)).Position)
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
	speed.Value = 24

	local jump = Instance.new("IntValue", leaderstats)
	jump.Name = "Jump"
	jump.Value = 50

	local rebirths = Instance.new("IntValue", leaderstats)
	rebirths.Name = "Rebirths"
	rebirths.Value = 0

	local baseLevel = Instance.new("IntValue", leaderstats)
	baseLevel.Name = "BaseLevel"
	baseLevel.Value = 1

	local upgradeCost = Instance.new("IntValue", player)
	upgradeCost.Name = "UpgradeCost"
	upgradeCost.Value = 50

	local jumpUpgradeCost = Instance.new("IntValue", player)
	jumpUpgradeCost.Name = "JumpUpgradeCost"
	jumpUpgradeCost.Value = 500

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
		rebirths.Value = data.Rebirths or 0
		baseLevel.Value = data.BaseLevel or 1

		-- 🔥 Speedバグ防止
		if data.Speed and data.Speed > 0 then
			speed.Value = data.Speed
		end

		-- 🔥 Jumpバグ防止
		if data.Jump and data.Jump > 0 then
			jump.Value = data.Jump
		end

		upgradeCost.Value = data.UpgradeCost or 50
		jumpUpgradeCost.Value = data.JumpUpgradeCost or 500
	end

	player:SetAttribute("DataLoaded", true)

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
			-- 階層の復元を少し待つ (Base.server.luaの処理)
			task.wait(1.5)
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

	if not leaderstats then return end

	local data = {
		Version = DATA_VERSION,

		Coins = leaderstats:FindFirstChild("Coins") and leaderstats.Coins.Value or 0,
		Rebirths = leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0,
		BaseLevel = leaderstats:FindFirstChild("BaseLevel") and leaderstats.BaseLevel.Value or 1,

		-- 🔥 Speed安全保存
		Speed = math.max(
			leaderstats:FindFirstChild("Speed") and leaderstats.Speed.Value or 24,
			24
		),

		-- 🔥 Jump安全保存
		Jump = math.max(
			leaderstats:FindFirstChild("Jump") and leaderstats.Jump.Value or 50,
			50
		),

		UpgradeCost = player:FindFirstChild("UpgradeCost") and player.UpgradeCost.Value or 50,
		JumpUpgradeCost = player:FindFirstChild("JumpUpgradeCost") and player.JumpUpgradeCost.Value or 500,

		BaseItems = base and collectBaseData(base) or {}
	}

	-- コインランキング用 OrderedDataStore に保存
	local coinsValue = data.Coins
	if coinsValue and coinsValue >= 0 then
		pcall(function()
			coinRankingStore:SetAsync(tostring(player.UserId), coinsValue)
		end)
	end

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

Players.PlayerRemoving:Connect(function(player)
	save(player)

	-- 保存完了後に基地を削除（データ消失を防止）
	local base = workspace:FindFirstChild(player.Name .. "_Base")
	if base then
		base:Destroy()
	end
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		save(p)
	end
	task.wait(5)
end)

-- =========================
-- ランキング表示処理（RankingCoin）
-- =========================
task.spawn(function()
	local rankingCoin = workspace:WaitForChild("RankingCoin", 10)
	if not rankingCoin then
		warn("RankingCoin not found in Workspace")
		return
	end

	-- SurfaceGui のセットアップ
	local surfaceGui = rankingCoin:FindFirstChild("RankingGui")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "RankingGui"
		surfaceGui.Face = Enum.NormalId.Front -- 側面（パーツの前面/側面に表示）
		surfaceGui.CanvasSize = Vector2.new(800, 600)
		surfaceGui.Parent = rankingCoin
	end

	local textLabel = surfaceGui:FindFirstChild("RankingText")
	if not textLabel then
		textLabel = Instance.new("TextLabel")
		textLabel.Name = "RankingText"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 24
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
		textLabel.TextYAlignment = Enum.TextYAlignment.Center
		textLabel.RichText = true
		textLabel.Parent = surfaceGui
	end

	while true do
		local success, pages = pcall(function()
			return coinRankingStore:GetSortedAsync(false, 10)
		end)

		if success and pages then
			local chunk = pages:GetCurrentPage()
			local displayText = "<font color='#FFD700' size='36'><b>★ COIN RANKING ★</b></font>\n\n"

			for rank, data in ipairs(chunk) do
				local userId = tonumber(data.key)
				local score = data.value
				local name = "Unknown"

				if userId then
					local nameSuccess, result = pcall(function()
						return Players:GetNameFromUserIdAsync(userId)
					end)
					if nameSuccess then
						name = result
					else
						name = "ID: " .. tostring(userId)
					end
				end

				displayText = displayText .. string.format("%d. %s - %s Coins\n", rank, name, tostring(score))
			end

			if #chunk == 0 then
				displayText = displayText .. "No ranking data yet."
			end

			textLabel.Text = displayText
		else
			warn("Failed to load ranking data from OrderedDataStore")
		end

		task.wait(60) -- 60秒毎にランキングを更新
	end
end)
