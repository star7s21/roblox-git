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
-- クリーンアップ
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	debounce[player] = nil
	jumpLimitActive[player.UserId] = nil
end)
