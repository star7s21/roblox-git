local pad = workspace:WaitForChild("SpeedUpgrade")

-- 初期設定
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
prompt.ObjectText = "Cost: Loading..."
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0

-- =========================
-- コスト取得
-- =========================
local function getCost(player)
	local costValue = player:FindFirstChild("UpgradeCost")
	return costValue and costValue.Value or baseCost
end

-- =========================
-- 定期更新
-- =========================
task.spawn(function()
	while true do
		task.wait(2)

		local players = game.Players:GetPlayers()
		if #players > 0 then
			local player = players[1] -- とりあえず誰か1人
			local cost = getCost(player)
			prompt.ObjectText = "Cost: " .. cost
		end
	end
end)

-- =========================
-- 押されたとき
-- =========================
prompt.Triggered:Connect(function(player)

	local currentCost = getCost(player)

	-- 押した瞬間に確実に更新
	prompt.ObjectText = "Cost: " .. currentCost

	-- 連打防止
	if debounce[player] then
		prompt.ActionText = "⏳ Wait..."
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	local speed = leaderstats:FindFirstChild("Speed")

	if not coins or not speed then return end

	-- コイン不足
	if coins.Value < currentCost then
		prompt.ActionText = "❌ Not Enough Coins"

		task.delay(1, function()
			prompt.ActionText = "Upgrade Speed"
			prompt.ObjectText = "Cost: " .. currentCost
		end)

		return
	end

	-- ロック
	debounce[player] = true

	prompt.ActionText = "⏳ Wait..."

	-- 購入
	coins.Value -= currentCost
	speed.Value += speedIncrease

	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed.Value
	end

	-- 価格更新
	local costValue = player:FindFirstChild("UpgradeCost")
	if costValue then
		currentCost = math.floor(currentCost * 1.5)
		costValue.Value = currentCost
	end

	-- クールダウン解除
	task.delay(1, function()
		debounce[player] = nil
		prompt.ActionText = "Upgrade Speed"
		prompt.ObjectText = "Cost: " .. currentCost
	end)
end)

-- =========================
-- プレイヤー退出
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	debounce[player] = nil
end)