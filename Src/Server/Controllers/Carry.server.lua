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

-- プレイヤーのCarryLevelに応じたUI更新処理
local function updateClientCarryUI(player)
	local carryLevelObj = player:FindFirstChild("CarryLevel")
	local carryLevel = carryLevelObj and carryLevelObj.Value or 1
	-- スロット数はレベルに応じて決定。レベル1は0スロット、レベル2は1スロット...レベル5は4スロット。
	-- MAX_CARRY_LEVELは5なので、最大スロット数はMAX_CARRY_LEVEL - 1 = 4 となる。
	local slotCount = math.max(0, carryLevel - 1)
	-- クライアントにUI更新を通知し、現在のスロット数を渡す
	carryRemote:FireClient(player, "UpdateUI", slotCount)
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

	updateClientCarryUI(player) -- UI更新をトリガー
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
	updateClientCarryUI(player) -- UI更新をトリガー
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
		return {success = false, message = "Internal error."}
	end

	local maxCarrySlots = MAX_CARRY_LEVEL
	
	-- slotIndex が有効な範囲内かチェック
	if slotIndex == nil or slotIndex < 1 or slotIndex > maxCarrySlots then
		warn("Invalid slotIndex received:", slotIndex)
		return {success = false, message = "Invalid slot index."}
	end

	local currentSlotsCount = #carryStorage:GetChildren()
	local toolInSlot = carryStorage:FindFirstChild("Slot"..slotIndex) -- slotIndex に対応するアイテムを探す

	if toolInSlot then
		-- 回収処理
		-- ツールをキャラクターにアタッチ（またはワールドに配置）
		local itemToRetrieve = toolInSlot
		itemToRetrieve.Parent = character -- キャラクターの子として配置

		-- 必要に応じて、アイテムの位置を調整
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			-- キャラクターの前面に配置
			itemToRetrieve:SetPrimaryPartCFrame(humanoidRootPart.CFrame * CFrame.new(0, 0, -3))
		end
		
		updateClientCarryUI(player) -- UI更新を通知
		return {success = true, message = "Item retrieved."}
	else
		-- 格納処理
		local equippedTool = character:FindFirstChildOfClass("Tool")
		if equippedTool and currentSlotsCount < maxCarrySlots then
			-- ツールをCarryStorageに移動
			local toolToStore = equippedTool:Clone()
			toolToStore.Parent = carryStorage
			toolToStore.Name = "Slot"..slotIndex -- slotIndex を名前に使用

			equippedTool:Destroy() -- 元のツールを削除

			updateClientCarryUI(player) -- UI更新を通知
			return {success = true, message = "Item stored."}
		else
			return {success = false, message = "Cannot store item. Storage full or no item equipped."}
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
