local MAX_CARRY_LEVEL = 5
local carryLevelIncrease = 1
local carryDebounce = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- CarryConfig をロード
local CarryConfig = require(script.Parent.Services.CarryConfig) -- パスは環境に合わせて調整してください

-- CarryStorageのルートフォルダ設定
local carryStorageRoot = ServerStorage:FindFirstChild("CarryStorage")
if not carryStorageRoot then
	carryStorageRoot = Instance.new("Folder")
	carryStorageRoot.Name = "CarryStorage"
	carryStorageRoot.Parent = ServerStorage
end

-- 通信用RemoteEventの設定
local carryRemote = ReplicatedStorage:WaitForChild("CarryRemote")

-- プレイヤーのCarryLevelに応じたUI更新処理
local function updateClientCarryUI(player)
	carryRemote:FireClient(player, "UpdateUI")
end

-- プレイヤーのCarryLevelとスロットを初期化
local function initializePlayerCarry(player)
	-- CarryLevel属性が存在しない場合は作成
	if not player:GetAttribute("CarryLevel") then
		player:SetAttribute("CarryLevel", 1)
	end

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

		local currentCarryLevel = player:GetAttribute("CarryLevel") or 1

		if currentCarryLevel >= CarryConfig.MaxCarryLevel then
			carryPrompt.ActionText = "❌ Max Level"
			task.delay(1.5, function()
				carryPrompt.ActionText = "Upgrade Carry"
			end)
			return
		end

		carryDebounce[player] = true
		carryPrompt.ActionText = "⏳ Wait..."

		-- CarryLevelを増加させる
		player:SetAttribute("CarryLevel", currentCarryLevel + CarryConfig.CarryLevelIncrease)
		updateClientCarryUI(player) -- クライアントにUI更新を通知

		task.delay(0.2, function()
			carryDebounce[player] = nil
			carryPrompt.ActionText = "Upgrade Carry"
		end)
	end)
end

-- プレイヤーが参加したときの処理
Players.PlayerAdded:Connect(function(player)
	initializePlayerCarry(player)
	setupCarryUpgradePad() -- CarryUpgradePad をセットアップ

	-- CharacterAddedイベントでUI更新などをトリガー
	player.CharacterAdded:Connect(function(character)
		-- 必要に応じて、キャラクター固有の初期化処理
		updateClientCarryUI(player) -- UI更新をトリガー
	end)

	-- CarryLevelの変更を監視
	player:GetAttributeChangedSignal("CarryLevel"):Connect(function()
		updateClientCarryUI(player)
	end)
end)

-- 既存プレイヤーの初期化
for _, player in ipairs(Players:GetPlayers()) do
	initializePlayerCarry(player)
	setupCarryUpgradePad()
	updateClientCarryUI(player)
end

-- スロットタップ時の格納・回収イベントハンドリング
carryRemote.OnServerEvent:Connect(function(player, action, targetInstance)
	local character = player.Character
	if not character then return end

	local currentCarryLevel = player:GetAttribute("CarryLevel") or 1
	local maxCarrySlots = CarryConfig.MaxCarrySlots -- CarryConfigから最大スロット数を取得

	local carryStorage = player:FindFirstChild("CarryStorage")
	if not carryStorage then return end

	if action == "Store" then
		-- 格納処理
		local equippedTool = character:FindFirstChildOfClass("Tool")
		if equippedTool and #carryStorage:GetChildren() < maxCarrySlots then
			-- ツールをCarryStorageに移動
			local toolToStore = equippedTool:Clone()
			toolToStore.Parent = carryStorage
			toolToStore.Name = equippedTool.Name .. "_" .. tick() -- 重複を避けるための命名

			equippedTool:Destroy() -- 元のツールを削除

			carryRemote:FireClient(player, "UpdateUI") -- UI更新を通知
			return {success = true, message = "Item stored."}
		else
			return {success = false, message = "Cannot store item. Storage full or no item equipped."}
		end

	elseif action == "Retrieve" then
		-- 回収処理
		if targetInstance and targetInstance.Parent == carryStorage then
			-- targetInstance をワールドに配置
			local itemToRetrieve = targetInstance
			itemToRetrieve.Parent = character -- キャラクターの子として配置（またはワークスペースなど）
			
			-- 必要に応じて、アイテムの位置を調整
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				itemToRetrieve:SetPrimaryPartCFrame(humanoidRootPart.CFrame * CFrame.new(0, 0, -5))
			end
			
			carryRemote:FireClient(player, "UpdateUI") -- UI更新を通知
			return {success = true, message = "Item retrieved."}
		else
			return {success = false, message = "Invalid item to retrieve or not in storage."}
		end
	end
	return {success = false, message = "Unknown action."}
end)

-- =========================
-- クリーンアップ
-- =========================
Players.PlayerRemoving:Connect(function(player)
	carryDebounce[player] = nil
	-- CarryStorageフォルダはPlayer.Parentなので、Playerが削除されるときに自動的に削除される
end)
