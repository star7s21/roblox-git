local pad = workspace:WaitForChild("SpeedUpgrade")

local baseCost = 50
local speedIncrease = 4
local debounce = {}

-- =========================
-- ProximityPrompt
-- =========================
local prompt = pad:FindFirstChild("ProximityPrompt")

if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.Parent = pad
end

prompt.ActionText = "Upgrade Speed"
prompt.ObjectText = ""
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0

-- =========================
-- コスト取得
-- =========================
local function getCost(player)
	local costValue = player:WaitForChild("UpgradeCost", 10)
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
	local speed = leaderstats:FindFirstChild("Speed")

	if not coins or not speed then return end

	if coins.Value < currentCost then
		prompt.ActionText = "❌ Not Enough Coins"
		task.delay(1, function()
			prompt.ActionText = "Upgrade Speed"
		end)
		return
	end

	debounce[player] = true
	prompt.ActionText = "⏳ Wait..."

	coins.Value -= currentCost
	speed.Value += speedIncrease

	-- コスト更新
	local costValue = player:FindFirstChild("UpgradeCost")
	if costValue then
		costValue.Value = math.floor(currentCost * 1.5)
	end

	task.delay(1, function()
		debounce[player] = nil
		prompt.ActionText = "Upgrade Speed"
	end)
end)

-- =========================
-- クリーンアップ
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	debounce[player] = nil
end)
