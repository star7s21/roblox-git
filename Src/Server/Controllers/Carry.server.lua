local MAX_CARRY_LEVEL = 5
local carryLevelIncrease = 1
local carryDebounce = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- CarryRemoteが存在しない場合は作成
local carryRemote = ReplicatedStorage:FindFirstChild("CarryRemote")
if not carryRemote then
	carryRemote = Instance.new("RemoteEvent")
	carryRemote.Name = "CarryRemote"
	carryRemote.Parent = ReplicatedStorage
end

-- CarryStorageのルートフォルダ設定
local carryStorageRoot = ServerStorage:FindFirstChild("CarryStorage")
if not carryStorageRoot then
	carryStorageRoot = Instance.new("Folder")
	carryStorageRoot.Name = "CarryStorage"
	carryStorageRoot.Parent = ServerStorage
end

local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

-- 宝箱アイテムをプレイヤーに持たせる処理
local function equipTreasure(player, typeName, level, displayName)
	local character = player.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- 既存の手持ち宝箱をクリーンアップ
	local existing = character:FindFirstChild("CarriedTreasure")
	if existing then existing:Destroy() end

	-- プレイヤーの状態を表すValueオブジェクトを作成・更新
	local tag = player:FindFirstChild("HasTreasure")
	if not tag then
		tag = Instance.new("BoolValue")
		tag.Name = "HasTreasure"
		tag.Parent = player
	end

	local levelObj = player:FindFirstChild("TreasureLevel")
	if not levelObj then
		levelObj = Instance.new("IntValue")
		levelObj.Name = "TreasureLevel"
		levelObj.Parent = player
	end
	levelObj.Value = level

	local typeObj = player:FindFirstChild("TreasureType")
	if not typeObj then
		typeObj = Instance.new("StringValue")
		typeObj.Name = "TreasureType"
		typeObj.Parent = player
	end
	typeObj.Value = typeName

	local displayObj = player:FindFirstChild("TreasureDisplayName")
	if not displayObj then
		displayObj = Instance.new("StringValue")
		displayObj.Name = "TreasureDisplayName"
		displayObj.Parent = player
	end
	displayObj.Value = displayName

	-- 宝箱モデルの複製とキャラクターへの接続
	local template = treasureFolder:FindFirstChild(typeName)
	if template then
		local clone = template:Clone()
		clone.Name = "CarriedTreasure"
		clone.Parent = character

		for _, p in ipairs(clone:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = false
				p.CanCollide = false
				p.Massless = true
			end
		end

		if not clone.PrimaryPart then
			clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
		end

		if clone.PrimaryPart then
			clone:PivotTo(head.CFrame * CFrame.new(0, 2, 2))

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = clone.PrimaryPart
			weld.Part1 = head
			weld.Parent = clone.PrimaryPart
		end
	end
end

-- プレイヤーの手持ち宝箱状態をクリアする処理
local function clearCarriedTreasure(player)
	local character = player.Character
	if character then
		local carried = character:FindFirstChild("CarriedTreasure")
		if carried then carried:Destroy() end
	end

	local tag = player:FindFirstChild("HasTreasure")
	if tag then tag:Destroy() end

	local typeObj = player:FindFirstChild("TreasureType")
	if typeObj then typeObj:Destroy() end

	local levelObj = player:FindFirstChild("TreasureLevel")
	if levelObj then levelObj:Destroy() end

	local displayObj = player:FindFirstChild("TreasureDisplayName")
	if displayObj then displayObj:Destroy() end
end

-- プレイヤーのCarryLevelに応じたUI更新処理
local function updateClientCarryUI(player)
	local carryLevelObj = player:FindFirstChild("CarryLevel")
	local carryLevel = carryLevelObj and carryLevelObj.Value or 1
	-- スロット数はレベルに応じて決定。レベル1は0スロット、レベル2は1スロット...レベル5は4スロット。
	-- MAX_CARRY_LEVELは5なので、最大スロット数はMAX_CARRY_LEVEL - 1 = 4 となる。
	local slotCount = math.max(0, carryLevel - 1)

	local slotContents = {}
	local carryStorage = player:FindFirstChild("CarryStorage")
	for i = 1, slotCount do
		local item = carryStorage and carryStorage:FindFirstChild("Slot" .. i)
		if item then
			slotContents[i] = item:GetAttribute("OriginalName") or item.Name
		else
			slotContents[i] = "Empty"
		end
	end

	-- クライアントにUI更新を通知し、現在のスロットコンテンツを渡す
	carryRemote:FireClient(player, "UpdateUI", slotContents)
end

-- プレイヤーのCarryLevelとスロットを初期化
local function initializePlayerCarry(player)
	-- CarryStorageフォルダを作成
	local carryStorage = player:FindFirstChild("CarryStorage")
	if not carryStorage then
		carryStorage = Instance.new("Folder")
		carryStorage.Name = "CarryStorage"
		carryStorage.Parent = player
	end
end

-- CarryUpgrade Pad の処理
local function setupCarryUpgradePad()
	local carryUpgradePad = workspace:FindFirstChild("CarryUpgrade")
	if not carryUpgradePad then
		carryUpgradePad = Instance.new("Part")
		carryUpgradePad.Name = "CarryUpgrade"
		carryUpgradePad.Size = Vector3.new(5, 0.5, 5)
		carryUpgradePad.Position = Vector3.new(10, 0.25, 10) -- 仮の初期位置
		carryUpgradePad.Anchored = true
		carryUpgradePad.BrickColor = BrickColor.new("Bright blue")
		carryUpgradePad.Material = Enum.Material.Neon
		carryUpgradePad.Parent = workspace
	end

	local carryPrompt = carryUpgradePad:FindFirstChildOfClass("ProximityPrompt")
	if not carryPrompt then
		carryPrompt = Instance.new("ProximityPrompt")
		carryPrompt.Parent = carryUpgradePad
	end
	carryPrompt.ActionText = "Upgrade Carry"
	carryPrompt.KeyboardKeyCode = Enum.KeyCode.E
	carryPrompt.HoldDuration = 0

	carryPrompt.Triggered:Connect(function(player)
		if carryDebounce[player] then return end

		local carryLevelObj = player:FindFirstChild("CarryLevel")
		local currentCarryLevel = carryLevelObj and carryLevelObj.Value or 1

		if currentCarryLevel >= MAX_CARRY_LEVEL then
			carryPrompt.ActionText = "❌ Max Level"
			task.delay(1.5, function()
				carryPrompt.ActionText = "Upgrade Carry"
			end)
			return
		end

		carryDebounce[player] = true
		carryPrompt.ActionText = "⏳ Wait..."

		-- CarryLevelを増加させる
		if carryLevelObj then
			carryLevelObj.Value = currentCarryLevel + carryLevelIncrease
		end

		task.delay(0.2, function()
			carryDebounce[player] = nil
			carryPrompt.ActionText = "Upgrade Carry"
		end)
	end)
end

-- プレイヤーが参加したときの処理
Players.PlayerAdded:Connect(function(player)
	initializePlayerCarry(player)
	
	local carryLevelObj = player:WaitForChild("CarryLevel", 5)
	if carryLevelObj then
		carryLevelObj.Changed:Connect(function()
			updateClientCarryUI(player)
		end)
	end

	-- データのロード完了を待ってからUIをトリガー
	task.spawn(function()
		if not player:GetAttribute("DataLoaded") then
			player:GetAttributeChangedSignal("DataLoaded"):Wait()
		end
		updateClientCarryUI(player)
	end)

	setupCarryUpgradePad() -- CarryUpgradePad をセットアップ

	-- CharacterAddedイベントでUI更新などをトリガー
	player.CharacterAdded:Connect(function(character)
		updateClientCarryUI(player) -- UI更新をトリガー
	end)
end)

-- 既存プレイヤーの初期化
for _, player in ipairs(Players:GetPlayers()) do
	initializePlayerCarry(player)
	local carryLevelObj = player:FindFirstChild("CarryLevel")
	if carryLevelObj then
		carryLevelObj.Changed:Connect(function()
			updateClientCarryUI(player)
		end)
	end
	
	task.spawn(function()
		if not player:GetAttribute("DataLoaded") then
			player:GetAttributeChangedSignal("DataLoaded"):Wait()
		end
		updateClientCarryUI(player)
	end)

	setupCarryUpgradePad()
end

-- スロットタップ時の格納・回収イベントハンドリング
carryRemote.OnServerEvent:Connect(function(player, slotIndex)
	if slotIndex == "RequestUIUpdate" then
		updateClientCarryUI(player)
		return
	end

	local character = player.Character
	if not character then return end

	local carryStorage = player:FindFirstChild("CarryStorage")
	if not carryStorage then
		warn("CarryStorage not found for player:", player.Name)
		return
	end

	local carryLevelObj = player:FindFirstChild("CarryLevel")
	local carryLevel = carryLevelObj and carryLevelObj.Value or 1
	local maxCarrySlots = math.max(0, carryLevel - 1)
	
	-- slotIndex が有効な範囲内かチェック
	if slotIndex == nil or slotIndex < 1 or slotIndex > maxCarrySlots then
		warn("Invalid slotIndex received:", slotIndex)
		return
	end

	local carried = character:FindFirstChild("CarriedTreasure")
	local toolInSlot = carryStorage:FindFirstChild("Slot"..slotIndex)

	if carried then
		-- 格納処理 (Treasureをもっているときは格納)
		local typeObj = player:FindFirstChild("TreasureType")
		local levelObj = player:FindFirstChild("TreasureLevel")
		local displayObj = player:FindFirstChild("TreasureDisplayName")

		if typeObj and levelObj then
			local typeName = typeObj.Value
			local level = levelObj.Value
			local displayName = displayObj and displayObj.Value or typeName

			if toolInSlot then
				-- スロットがすでに埋まっている場合はスワップ（入れ替え）
				local oldType = toolInSlot:GetAttribute("Type") or toolInSlot.Name
				local oldLevel = toolInSlot:GetAttribute("Level") or 1
				local oldDisplayName = toolInSlot:GetAttribute("OriginalName") or oldType

				-- スロットの情報を新しい宝箱に上書き
				toolInSlot:SetAttribute("Type", typeName)
				toolInSlot:SetAttribute("Level", level)
				toolInSlot:SetAttribute("OriginalName", displayName)

				-- スロットに入っていた古い宝箱をプレイヤーに持たせる
				equipTreasure(player, oldType, oldLevel, oldDisplayName)
			else
				-- スロットが空の場合は新規格納
				local slotFolder = Instance.new("Folder")
				slotFolder.Name = "Slot"..slotIndex
				slotFolder:SetAttribute("Type", typeName)
				slotFolder:SetAttribute("Level", level)
				slotFolder:SetAttribute("OriginalName", displayName)
				slotFolder.Parent = carryStorage

				-- プレイヤーの手持ち状態を消去
				clearCarriedTreasure(player)
			end
			updateClientCarryUI(player)
		end
	else
		-- 回収処理 (Slotに格納されていてTreasureを持っていない場合は回収)
		if toolInSlot then
			local oldType = toolInSlot:GetAttribute("Type") or toolInSlot.Name
			local oldLevel = toolInSlot:GetAttribute("Level") or 1
			local oldDisplayName = toolInSlot:GetAttribute("OriginalName") or oldType

			-- スロットから削除
			toolInSlot:Destroy()

			-- アイテムを装備
			equipTreasure(player, oldType, oldLevel, oldDisplayName)
			updateClientCarryUI(player)
		end
	end
end)

-- =========================
-- クリーンアップ
-- =========================
Players.PlayerRemoving:Connect(function(player)
	carryDebounce[player] = nil
	-- CarryStorageフォルダはPlayer.Parentなので、Playerが削除されるときに自動的に削除される
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local carryRemote = ReplicatedStorage:WaitForChild("CarryRemote")
-- 他の必要なサービスやモジュールをここでロード
-- local MarketplaceManager = require(game.ServerStorage.Services.MarketplaceManager) -- 例
-- local BaseUpgradeService = require(game.ServerStorage.Services.BaseUpgradeService) -- 例
local TreasureConfig = require(game.ServerStorage.Services.TreasureConfig) -- 例: 宝物の設定から情報を取得するために使用
local MarketplaceConfig = require(game.ServerStorage.Services.MarketplaceConfig) -- 例: コスト計算などに使用

local carryData = {} -- 各プレイヤーのキャリー関連データを格納するテーブル
local carryUpgradeCostTable = {} -- CarryUpgradeのコストテーブル（例）

-- CarryUpgradeの初期レベルとコストを設定する関数
local function getCarryUpgradeInitialData(player)
	-- ここでCarryUpgradeの初期レベルとコストを設定します。
	-- 例：初期レベルは0、コストは100
	return {
		Level = 0,
		Cost = 100
	}
end

-- CarryUpgradeの次のレベルのコストを計算する関数
local function calculateNextCarryUpgradeCost(currentLevel)
	-- ここでCarryUpgradeの次のレベルのコストを計算します。
	-- 例：レベルが上がるごとにコストが2倍になる
	return 100 * (2 ^ (currentLevel + 1))
end

-- CarryUpgradeの最大レベルを定義
local MAX_CARRY_UPGRADE_LEVEL = 10 -- 例：最大レベルを10とする

-- プレイヤーのCarryUpgradeレベルを取得する関数
local function getCarryUpgradeLevel(player)
	return carryData[player] and carryData[player].UpgradeLevel or 0
end

-- プレイヤーのCarryUpgradeコストを取得する関数
local function getCarryUpgradeCost(player)
	local currentLevel = getCarryUpgradeLevel(player)
	if currentLevel >= MAX_CARRY_UPGRADE_LEVEL then
		return 0 -- 最大レベルの場合はコスト0
	end
	return carryData[player] and carryData[player].UpgradeCost or calculateNextCarryUpgradeCost(0)
end

-- CarryUpgradeレベルを更新する関数
local function setCarryUpgradeLevel(player, level)
	if not carryData[player] then
		carryData[player] = {}
	end
	carryData[player].UpgradeLevel = level
	carryData[player].UpgradeCost = calculateNextCarryUpgradeCost(level)
end

-- プレイヤーのキャリーインベントリ（スロット）を管理する関数
-- 初期化時やUI表示のために使用
local function getPlayerCarrySlots(player)
	-- ここでは、プレイヤーのキャリーインベントリのデータを返します。
	-- 例：空のスロットを返す
	local level = getCarryUpgradeLevel(player)
	local numberOfSlots = 2 + level -- 例：レベルごとにスロットが1つ増える
	local slots = {}
	for i = 1, numberOfSlots do
		slots[i] = "Empty" -- 初期値はEmpty
	end
	-- 実際には、ここでプレイヤーが保持している宝物をスロットに割り当てる必要があります。
	-- 例：slots[1] = "CommonTreasure"
	return slots
end

-- CarryUpgradeをアップグレードする処理
local function upgradeCarry(player)
	local currentLevel = getCarryUpgradeLevel(player)
	local currentCost = getCarryUpgradeCost(player)

	if currentLevel >= MAX_CARRY_UPGRADE_LEVEL then
		carryRemote:FireClient(player, "NotifyUpgradeFail", { Message = "Max level reached." })
		return false -- 最大レベル
	end

	-- プレイヤーの通貨（例：Coins）を取得して、コストと比較
	-- ここでは例として、プレイヤーが十分な通貨を持っていると仮定します。
	-- 実際には、プレイヤーの通貨を管理するシステムと連携する必要があります。
	local playerCurrency = 1000 -- 例：プレイヤーの所持金

	if playerCurrency < currentCost then
		carryRemote:FireClient(player, "NotifyUpgradeFail", { Message = "Not enough currency." })
		return false -- コスト不足
	end

	-- 通貨を消費する処理 (例)
	-- playerCurrency = playerCurrency - currentCost
	-- UpdatePlayerCurrency(player, playerCurrency) -- 通貨更新関数を呼び出す

	-- CarryUpgradeレベルを上げる
	setCarryUpgradeLevel(player, currentLevel + 1)

	-- UIを更新するためにクライアントに通知
	local slots = getPlayerCarrySlots(player)
	carryRemote:FireClient(player, "UpdateUI", {
		Slots = slots,
		CarryUpgradeLevel = getCarryUpgradeLevel(player),
		CarryUpgradeCost = getCarryUpgradeCost(player)
	})

	carryRemote:FireClient(player, "NotifyUpgradeSuccess") -- アップグレード成功通知
	return true
end

-- StoreOrRetrieve アクションの処理
local function handleStoreOrRetrieve(player, slotIndex)
	local slots = getPlayerCarrySlots(player)
	local currentItem = slots[slotIndex]

	if currentItem == "Empty" then
		-- 空のスロットに何かを格納する処理
		-- 例：プレイヤーが現在持っている宝物を指定されたスロットに格納する
		-- ここでは、単純にスロットにアイテムを割り当てる例を示します。
		-- 実際には、プレイヤーのインベントリからアイテムを取得する処理が必要です。
		local playerHoldingTreasure = "ExampleTreasure" -- 例：プレイヤーが現在持っている宝物
		if playerHoldingTreasure then
			slots[slotIndex] = playerHoldingTreasure
			-- プレイヤーのインベントリからアイテムを削除する処理
			-- ClearPlayerHoldingTreasure(player) -- 例
			print(player.Name .. " stored " .. playerHoldingTreasure .. " in slot " .. slotIndex)
		end
	else
		-- スロットからアイテムを取り出す処理
		-- 例：スロットのアイテムをプレイヤーが持てるようにする
		-- ここでは、単純にスロットを空にする例を示します。
		local itemToRetrieve = slots[slotIndex]
		slots[slotIndex] = "Empty"
		-- プレイヤーがアイテムを持てるようにする処理
		-- GivePlayerTreasure(player, itemToRetrieve) -- 例
		print(player.Name .. " retrieved " .. itemToRetrieve .. " from slot " .. slotIndex)
	end

	-- UIを更新するためにクライアントに通知
	carryRemote:FireClient(player, "UpdateUI", {
		Slots = slots,
		CarryUpgradeLevel = getCarryUpgradeLevel(player),
		CarryUpgradeCost = getCarryUpgradeCost(player)
	})
end


-- プレイヤーのCarryUpgradeレベルとスロットを初期化
local function initializePlayerCarryData(player)
	if not carryData[player] then
		carryData[player] = {}
	end
	-- 初期レベルとコストを設定
	local initialData = getCarryUpgradeInitialData(player)
	carryData[player].UpgradeLevel = initialData.Level
	carryData[player].UpgradeCost = initialData.Cost
end

-- プレイヤーがゲームに参加したときの処理
Players.PlayerAdded:Connect(function(player)
	initializePlayerCarryData(player)

	-- プレイヤーがロードされたときに、初期UIデータを送信
	player.CharacterAdded:Connect(function(character)
		-- キャラクターがロードされたら、CarryUpgradeのUIを更新
		local slots = getPlayerCarrySlots(player)
		carryRemote:FireClient(player, "UpdateUI", {
			Slots = slots,
			CarryUpgradeLevel = getCarryUpgradeLevel(player),
			CarryUpgradeCost = getCarryUpgradeCost(player)
		})
	end)
end)

-- プレイヤーがゲームから退出したときの処理
Players.PlayerRemoving:Connect(function(player)
	carryData[player] = nil -- プレイヤーデータを削除
end)

-- クライアントからのリモートイベントを処理
carryRemote.OnServerEvent:Connect(function(player, action, ...)
	if action == "RequestUIUpdate" then
		-- UI更新リクエストがあった場合、現在のCarryUpgradeレベルとコスト、スロット情報を送信
		local slots = getPlayerCarrySlots(player)
		carryRemote:FireClient(player, "UpdateUI", {
			Slots = slots,
			CarryUpgradeLevel = getCarryUpgradeLevel(player),
			CarryUpgradeCost = getCarryUpgradeCost(player)
		})
	elseif action == "UpgradeCarry" then
		-- CarryUpgradeのアップグレードリクエスト
		upgradeCarry(player)
	elseif action == "StoreOrRetrieve" then
		-- StoreOrRetrieve アクションの処理
		local slotIndex = ...
		handleStoreOrRetrieve(player, slotIndex)
	end
end)

-- CarryUpgrade Pad のセットアップ (例としてworkspaceに配置)
-- この部分は、ゲームのセットアップ時に一度だけ実行されるように、
-- Main.server.luaや別の初期化スクリプトから呼び出すのが適切かもしれません。
local function setupCarryUpgradePad()
	local carryUpgradePad = workspace:FindFirstChild("CarryUpgrade")
	if not carryUpgradePad then
		carryUpgradePad = Instance.new("Part")
		carryUpgradePad.Name = "CarryUpgrade"
		carryUpgradePad.Size = Vector3.new(5, 0.5, 5)
		carryUpgradePad.Position = Vector3.new(10, 0.25, 10) -- 仮の初期位置
		carryUpgradePad.Anchored = true
		carryUpgradePad.BrickColor = BrickColor.new("Bright blue")
		carryUpgradePad.Material = Enum.Material.Neon
		carryUpgradePad.Parent = workspace
	end

	local carryPrompt = carryUpgradePad:FindFirstChildOfClass("ProximityPrompt")
	if not carryPrompt then
		carryPrompt = Instance.new("ProximityPrompt")
		carryPrompt.Parent = carryUpgradePad
	end
	carryPrompt.ActionText = "Upgrade Carry"
	carryPrompt.KeyboardKeyCode = Enum.KeyCode.E
	carryPrompt.HoldDuration = 0

	carryPrompt.Triggered:Connect(function(player)
		local currentLevel = getCarryUpgradeLevel(player)
		local currentCost = getCarryUpgradeCost(player)

		if currentLevel >= MAX_CARRY_UPGRADE_LEVEL then
			carryPrompt.ActionText = "❌ Max Level"
			task.delay(1.5, function()
				carryPrompt.ActionText = "Upgrade Carry"
			end)
			return
		end

		-- クライアントにアップグレードを試みるよう指示
		carryRemote:FireServer("UpgradeCarry")
	end)
end

-- ゲーム起動時にCarryUpgradePadをセットアップ
-- 実際には、ゲームのメインサーバーコントローラーなど、
-- 適切な場所からこの関数を呼び出す必要があります。
-- task.spawn(setupCarryUpgradePad)
