local MAX_CARRY_LEVEL = 5
local baseCost = 50000
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


-- =========================
-- コスト取得
-- =========================
local function getCost(player)
	local costValue = player:WaitForChild("CarryUpgradeCost", 10)
	return costValue and costValue.Value or baseCost
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
		
		-- コスト更新
		local currentCost = getCost(player)
		local costValue = player:FindFirstChild("CarryUpgradeCost")
		if costValue then
			costValue.Value = math.floor(currentCost * 100.0)
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
end

setupCarryUpgradePad() -- グローバルで1回だけセットアップ

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
