local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceManager = require(ServerScriptService.Server.Services.MarketplaceManager)

local BASE_REBIRTH_COST = 1000
local COST_MULTIPLIER = 2

-- 課金リバースの処理登録
MarketplaceManager.RegisterUpgrade("Rebirth", function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local speed = leaderstats:FindFirstChild("Speed")
	local jump = leaderstats:FindFirstChild("Jump")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	local upgradeCost = player:FindFirstChild("UpgradeCost")
	local jumpUpgradeCost = player:FindFirstChild("JumpUpgradeCost")

	if not speed or not jump or not rebirths or not upgradeCost or not jumpUpgradeCost then return end

	-- コインを消費せずに他のステータスをリセットしてリバース
	speed.Value = 16
	jump.Value = 50
	rebirths.Value = rebirths.Value + 1
	upgradeCost.Value = 50
	jumpUpgradeCost.Value = 50

	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.WalkSpeed = speed.Value
		humanoid.JumpPower = jump.Value
	end

	print(player.Name .. " has Rebirth via Robux! Total: " .. rebirths.Value)
end)

-- RemoteEventの作成/取得
local remote = ReplicatedStorage:FindFirstChild("RebirthEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "RebirthEvent"
	remote.Parent = ReplicatedStorage
end

local function doRebirth(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	local speed = leaderstats:FindFirstChild("Speed")
	local jump = leaderstats:FindFirstChild("Jump")
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	local upgradeCost = player:FindFirstChild("UpgradeCost")
	local jumpUpgradeCost = player:FindFirstChild("JumpUpgradeCost")

	if not coins or not speed or not jump or not rebirths or not upgradeCost or not jumpUpgradeCost then return end

	local currentCost = BASE_REBIRTH_COST * (COST_MULTIPLIER ^ rebirths.Value)

	if coins.Value >= currentCost then
		-- ステータスリセット
		coins.Value = 0
		speed.Value = 16
		jump.Value = 50
		rebirths.Value = rebirths.Value + 1
		upgradeCost.Value = 50
		jumpUpgradeCost.Value = 50

		-- キャラクターに速度適用
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.WalkSpeed = speed.Value
			humanoid.JumpPower = jump.Value
		end

		print(player.Name .. " has Rebirth! Total: " .. rebirths.Value)
	else
		MarketplaceManager.PromptPurchase(player, "Rebirth")
		print(player.Name .. " needs " .. currentCost .. " coins for Rebirth.")
	end
end

remote.OnServerEvent:Connect(function(player)
	doRebirth(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if message:lower() == "/rebirth" then
			doRebirth(player)
		end
	end)
end)
