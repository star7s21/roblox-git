local MAX_CARRY_LEVEL = 5
local CARRY_SLOT_HEIGHT = 40 -- UIの各スロットの高さ
local carryLevelIncrease = 1
local carryDebounce = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 通信用RemoteEventの設定
local carryRemote = ReplicatedStorage:FindFirstChild("CarryRemote")
if not carryRemote then
	carryRemote = Instance.new("RemoteEvent")
	carryRemote.Name = "CarryRemote"
	carryRemote.Parent = ReplicatedStorage
end

local function applyCarryLevel(player, char)
	-- UIの表示・更新処理はクライアント側（Carry.client.lua）で行われるため、サーバー側でのUI操作は行いません。
end

local function addCarrySlot(player, char)
	if not char then return end
	local carryLevel = player:FindFirstChild("CarryLevel")
	if not carryLevel then return end

	local newLevel = carryLevel.Value + carryLevelIncrease
	if newLevel <= MAX_CARRY_LEVEL then
		carryLevel.Value = newLevel
	end
end

-- プレイヤーごとの格納用フォルダとスロットデータの初期化
local function initializePlayerSlots(player)
	local carryStorage = player:FindFirstChild("CarryStorage")
	if not carryStorage then
		carryStorage = Instance.new("Folder")
		carryStorage.Name = "CarryStorage"
		carryStorage.Parent = player
	end

	local carrySlots = player:FindFirstChild("CarrySlots")
	if not carrySlots then
		carrySlots = Instance.new("Folder")
		carrySlots.Name = "CarrySlots"
		carrySlots.Parent = player
	end

	for i = 1, MAX_CARRY_LEVEL do
		local slotName = "Slot" .. i
		if not carrySlots:FindFirstChild(slotName) then
			local slotVal = Instance.new("ObjectValue")
			slotVal.Name = slotName
			slotVal.Parent = carrySlots
		end
	end
end

Players.PlayerAdded:Connect(initializePlayerSlots)
for _, player in ipairs(Players:GetPlayers()) do
	initializePlayerSlots(player)
end

-- スロットタップ時の格納・回収イベントハンドリング
carryRemote.OnServerEvent:Connect(function(player, slotIndex)
	local carryLevel = player:FindFirstChild("CarryLevel")
	if not carryLevel or slotIndex > carryLevel.Value or slotIndex < 1 then return end

	local carrySlots = player:FindFirstChild("CarrySlots")
	local carryStorage = player:FindFirstChild("CarryStorage")
	if not carrySlots or not carryStorage then return end

	local slotVal = carrySlots:FindFirstChild("Slot" .. slotIndex)
	if not slotVal then return end

	local char = player.Character
	if not char then return end

	local currentTool = char:FindFirstChildOfClass("Tool")

	if currentTool then
		-- 手にToolを持っている場合：スロットが空なら格納する
		if slotVal.Value == nil then
			slotVal.Value = currentTool
			currentTool.Parent = carryStorage
		end
	else
		-- 手にToolを持っていない場合：スロットに格納されているものがあれば手元に戻す
		local storedTool = slotVal.Value
		if storedTool and storedTool:IsDescendantOf(carryStorage) then
			storedTool.Parent = char
			slotVal.Value = nil
		end
	end
end)

-- CarryUpgrade PadのProximityPrompt設定
local carryUpgradePad = workspace:WaitForChild("CarryUpgrade")
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

	local carryLevel = player:FindFirstChild("CarryLevel")
	if not carryLevel then return end

	if carryLevel.Value >= MAX_CARRY_LEVEL then
		carryPrompt.ActionText = "❌ Max Level"
		task.delay(1.5, function()
			carryPrompt.ActionText = "Upgrade Carry"
		end)
		return
	end

	carryDebounce[player] = true
	carryPrompt.ActionText = "⏳ Wait..."

	addCarrySlot(player, player.Character) -- CarryレベルとUIを更新

	task.delay(0.2, function()
		carryDebounce[player] = nil
		carryPrompt.ActionText = "Upgrade Carry"
	end)
end)

-- PlayerAdded & CharacterAdded で Carry UI を初期化
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5) -- Character初期化を待つ
		applyCarryLevel(player, char)
	end)
end)

-- 既存プレイヤーの初期化
for _, player in ipairs(game.Players:GetPlayers()) do
	if player.Character then
		task.spawn(applyCarryLevel, player, player.Character)
	end
end

-- CarryLevel変更時のUI更新
local function watchCarryLevel(player)
	local carryLevel = player:WaitForChild("CarryLevel", 10)
	if carryLevel then
		carryLevel.Changed:Connect(function()
			applyCarryLevel(player, player.Character)
		end)
	end
end
game.Players.PlayerAdded:Connect(watchCarryLevel)
for _, player in ipairs(game.Players:GetPlayers()) do
	task.spawn(watchCarryLevel, player)
end

-- =========================
-- クリーンアップ
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	carryDebounce[player] = nil
end)
