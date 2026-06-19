local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceManager = require(ServerScriptService.Server.Services.MarketplaceManager)
local pad = workspace:WaitForChild("JumpUpgrade")

local baseCost = 500
local jumpIncrease = 10
local debounce = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleRemote = ReplicatedStorage:FindFirstChild("ToggleJumpLimit")
if not toggleRemote then
	toggleRemote = Instance.new("RemoteEvent")
	toggleRemote.Name = "ToggleJumpLimit"
	toggleRemote.Parent = ReplicatedStorage
end

local jumpLimitActive = {}

local function applyJumpValue(player, char)
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.UseJumpPower = true -- JumpPowerを確実に適用

	local isLimited = jumpLimitActive[player.UserId] or false
	if isLimited then
		humanoid.JumpPower = 50 -- 初期値
	else
		local leaderstats = player:FindFirstChild("leaderstats")
		local jumpAttr = leaderstats and leaderstats:FindFirstChild("Jump")
		humanoid.JumpPower = jumpAttr and jumpAttr.Value or 50
	end
end

toggleRemote.OnServerEvent:Connect(function(player, isLimited)
	jumpLimitActive[player.UserId] = isLimited
	applyJumpValue(player, player.Character)
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5) -- キャラクター初期化を少し待つ
		applyJumpValue(player, char)
	end)
end)

-- 既存のジャンプ値変化イベントの監視
local function watchJumpValue(player)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local jump = leaderstats:WaitForChild("Jump", 10)
		if jump then
			jump.Changed:Connect(function()
				applyJumpValue(player, player.Character)
			end)
		end
	end
end

game.Players.PlayerAdded:Connect(watchJumpValue)
for _, player in ipairs(game.Players:GetPlayers()) do
	task.spawn(watchJumpValue, player)
	if player.Character then
		task.spawn(applyJumpValue, player, player.Character)
	end
end

-- 課金ジャンプアップの処理登録
MarketplaceManager.RegisterUpgrade("Jump", function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local jump = leaderstats:FindFirstChild("Jump")
	local costValue = player:FindFirstChild("JumpUpgradeCost")

	if jump then
		jump.Value = jump.Value + jumpIncrease
	end

	if costValue then
		costValue.Value = math.floor(costValue.Value * 5.0)
	end

	applyJumpValue(player, player.Character)
end)

-- =========================
-- ProximityPrompt
-- =========================
local prompt = pad:FindFirstChild("ProximityPrompt")

if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.Parent = pad
end

prompt.ActionText = "Upgrade Jump"
prompt.ObjectText = ""
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0

-- =========================
-- コスト取得
-- =========================
local function getCost(player)
	local costValue = player:WaitForChild("JumpUpgradeCost", 10)
	return costValue and costValue.Value or baseCost
end

-- =========================
-- 購入処理
-- =========================
prompt.Triggered:Connect(function(player)

	local currentCost = getCost(player)

	if debounce[player] then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	local jump = leaderstats:FindFirstChild("Jump")

	if not coins or not jump then return end

	if coins.Value < currentCost then
		prompt.ActionText = "❌ Not Enough Coins"
		MarketplaceManager.PromptPurchase(player, "Jump")
		task.delay(1.5, function()
			prompt.ActionText = "Upgrade Jump"
		end)
		return
	end

	debounce[player] = true
	prompt.ActionText = "⏳ Wait..."

	coins.Value = coins.Value - currentCost
	jump.Value = jump.Value + jumpIncrease

	-- コスト更新
	local costValue = player:FindFirstChild("JumpUpgradeCost")
	if costValue then
		costValue.Value = math.floor(currentCost * 5.0)
	end

	applyJumpValue(player, player.Character)

	task.delay(0.2, function()
		debounce[player] = nil
		prompt.ActionText = "Upgrade Jump"
	end)
end)

-- =========================
-- Carry機能の追加
-- =========================
local MAX_CARRY_LEVEL = 5
local CARRY_COST_MULTIPLIER = 5.0
local CARRY_SLOT_HEIGHT = 40 -- UIの各スロットの高さ

local carryCostBase = 500
local carryLevelIncrease = 1
local carryDebounce = {}

local function applyCarryLevel(player, char)
	if not char then return end
	local carryLevel = player:FindFirstChild("CarryLevel")
	local carryCost = player:FindFirstChild("CarryCost")

	if not carryLevel or not carryCost then return end

	local currentCarryLevel = carryLevel.Value
	local currentCarryCost = carryCost.Value

	-- UIの更新（CarryStorageContainer内のScreenGuiを更新）
	local carryStorageContainer = char:FindFirstChild("CarryStorageContainer")
	if carryStorageContainer then
		local screenGui = carryStorageContainer:FindFirstChild("CarryStorageGui")
		if screenGui then
			local frame = screenGui:FindFirstChildOfClass("Frame")
			if frame then
				frame.Size = UDim2.new(0, 200, 0, CARRY_SLOT_HEIGHT * currentCarryLevel) -- UIの高さをレベルに合わせて更新

				-- slotsの更新
				local slots = {}
				for _, child in ipairs(frame:GetChildren()) do
					if child:IsA("Frame") and child:FindFirstChild("TextLabel") then
						table.insert(slots, child)
					end
				end

				-- 新しいレベルのUIを追加
				for i = #slots + 1, currentCarryLevel do
					local slotFrame = Instance.new("Frame")
					slotFrame.Size = UDim2.new(1, 0, 0, CARRY_SLOT_HEIGHT)
					slotFrame.BackgroundTransparency = 1
					slotFrame.LayoutOrder = i
					slotFrame.Parent = frame

					local slotLabel = Instance.new("TextLabel")
					slotLabel.Size = UDim2.new(1, 0, 0, CARRY_SLOT_HEIGHT)
					slotLabel.Text = "Slot " .. i .. ": Empty"
					slotLabel.TextColor3 = Color3.new(1,1,1)
					slotLabel.BackgroundTransparency = 1
					slotLabel.Parent = slotFrame
				end
			end
		end
	end
end

local function updateCarryCost(player)
	local carryCost = player:FindFirstChild("CarryCost")
	if carryCost then
		carryCost.Value = math.floor(carryCost.Value * CARRY_COST_MULTIPLIER)
	end
end

local function addCarrySlot(player, char)
	if not char then return end
	local carryLevel = player:FindFirstChild("CarryLevel")
	if not carryLevel then return end

	local newLevel = carryLevel.Value + carryLevelIncrease
	if newLevel <= MAX_CARRY_LEVEL then
		carryLevel.Value = newLevel
		applyCarryLevel(player, char)
		updateCarryCost(player) -- コストも更新
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

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	local carryCost = player:FindFirstChild("CarryCost")

	if not coins or not carryCost then return end

	local currentCost = carryCost.Value

	if coins.Value < currentCost then
		carryPrompt.ActionText = "❌ Not Enough Coins"
		-- MarketplaceManager.PromptPurchase(player, "Carry") -- 将来的にCarryの購入機能を追加する場合
		task.delay(1.5, function()
			carryPrompt.ActionText = "Upgrade Carry"
		end)
		return
	end

	carryDebounce[player] = true
	carryPrompt.ActionText = "⏳ Wait..."

	coins.Value = coins.Value - currentCost
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
	-- jumpLimitActive[player.UserId] = nil -- Jump機能のクリーンアップはそのまま
end)
