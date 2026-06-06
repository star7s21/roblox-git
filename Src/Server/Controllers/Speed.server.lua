local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceManager = require(ServerScriptService.Server.Services.MarketplaceManager)
local pad = workspace:WaitForChild("SpeedUpgrade")

local baseCost = 50
local speedIncrease = 4
local debounce = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleRemote = ReplicatedStorage:FindFirstChild("ToggleSpeedLimit")
if not toggleRemote then
	toggleRemote = Instance.new("RemoteEvent")
	toggleRemote.Name = "ToggleSpeedLimit"
	toggleRemote.Parent = ReplicatedStorage
end

local speedLimitActive = {}

local function applySpeedValue(player, char)
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local isLimited = speedLimitActive[player.UserId] or false
	if isLimited then
		humanoid.WalkSpeed = 16 -- 初期値
	else
		local leaderstats = player:FindFirstChild("leaderstats")
		local speedAttr = leaderstats and leaderstats:FindFirstChild("Speed")
		humanoid.WalkSpeed = speedAttr and speedAttr.Value or 16
	end
end

toggleRemote.OnServerEvent:Connect(function(player, isLimited)
	speedLimitActive[player.UserId] = isLimited
	applySpeedValue(player, player.Character)
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5) -- キャラクター初期化を少し待つ
		applySpeedValue(player, char)
	end)
end)

-- 既存のスピード値変化イベントの監視
local function watchSpeedValue(player)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local speed = leaderstats:WaitForChild("Speed", 10)
		if speed then
			speed.Changed:Connect(function()
				applySpeedValue(player, player.Character)
			end)
		end
	end
end

game.Players.PlayerAdded:Connect(watchSpeedValue)
for _, player in ipairs(game.Players:GetPlayers()) do
	task.spawn(watchSpeedValue, player)
	if player.Character then
		task.spawn(applySpeedValue, player, player.Character)
	end
end

-- 課金スピードアップの処理登録
MarketplaceManager.RegisterUpgrade("Speed", function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local speed = leaderstats:FindFirstChild("Speed")
	local costValue = player:FindFirstChild("UpgradeCost")

	if speed then
		speed.Value = speed.Value + speedIncrease
	end

	if costValue then
		costValue.Value = math.floor(costValue.Value * 1.5)
	end

	applySpeedValue(player, player.Character)
end)

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
		MarketplaceManager.PromptPurchase(player, "Speed")
		task.delay(1.5, function()
			prompt.ActionText = "Upgrade Speed"
		end)
		return
	end

	debounce[player] = true
	prompt.ActionText = "⏳ Wait..."

	coins.Value = coins.Value - currentCost
	speed.Value = speed.Value + speedIncrease

	-- コスト更新
	local costValue = player:FindFirstChild("UpgradeCost")
	if costValue then
		costValue.Value = math.floor(currentCost * 1.5)
	end

	applySpeedValue(player, player.Character)

	task.delay(0.2, function()
		debounce[player] = nil
		prompt.ActionText = "Upgrade Speed"
	end)
end)

-- =========================
-- クリーンアップ
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	debounce[player] = nil
	speedLimitActive[player.UserId] = nil
end)
