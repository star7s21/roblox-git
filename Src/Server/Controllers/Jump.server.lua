local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceManager = require(ServerScriptService.Server.Services.MarketplaceManager)
local pad = workspace:WaitForChild("JumpUpgrade")

local baseCost = 50
local jumpIncrease = 10
local debounce = {}

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
		costValue.Value = math.floor(costValue.Value * 1.5)
	end
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
		costValue.Value = math.floor(currentCost * 1.5)
	end

	task.delay(0.2, function()
		debounce[player] = nil
		prompt.ActionText = "Upgrade Jump"
	end)
end)

-- =========================
-- クリーンアップ
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	debounce[player] = nil
end)
