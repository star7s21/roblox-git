local MAX_CARRY_LEVEL = 5
local CARRY_SLOT_HEIGHT = 40 -- UIの各スロットの高さ
local carryLevelIncrease = 1
local carryDebounce = {}

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
