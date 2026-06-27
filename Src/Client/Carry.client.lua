local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local carryRemote = ReplicatedStorage:WaitForChild("CarryRemote")
local playerGui = player:WaitForChild("PlayerGui")

local currentSlotCount = 0 -- 現在表示されているスロット数
local currentCarryUpgradeLevel = 0 -- 現在のCarryUpgradeレベル
local currentCarryUpgradeCost = 0 -- 現在のCarryUpgradeコスト

local function updateCarryStorageUI(slotContents, carryUpgradeLevel, carryUpgradeCost)
	-- 既存のUIがあれば削除
	local existingGui = playerGui:FindFirstChild("CarryStorageGui")
	if existingGui then
		existingGui:Destroy()
	end
	
	-- slotContentsがnilでないことを確認してから長さを取得
	local slotCount = slotContents and #slotContents or 0
	-- slotCountが0以下の場合はUIを表示しない
	if slotCount <= 0 and carryUpgradeLevel == 0 then
		return
	end

	currentSlotCount = slotCount -- 現在のスロット数を更新
	currentCarryUpgradeLevel = carryUpgradeLevel or 0
	currentCarryUpgradeCost = carryUpgradeCost or 0

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CarryStorageGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	-- 横並びにするため、幅をスロット数に合わせてスケール
	-- CarryUpgradeUIのためのスペースも考慮
	frame.Size = UDim2.new(0, (65 * slotCount) + 100, 0, 50) -- スロット+アップグレードUIの幅
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -10) -- 画面下部中央に配置
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.FillDirection = Enum.FillDirection.Horizontal -- 横に並べる
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	-- 各キャリースロットの作成
	for i = 1, slotCount do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Size = UDim2.new(0, 60, 0, 40)
		slotBtn.BorderSizePixel = 1
		slotBtn.LayoutOrder = i
		slotBtn.TextSize = 10
		slotBtn.TextWrapped = true
		slotBtn.TextColor3 = Color3.new(1, 1, 1)
		slotBtn.Parent = frame

		-- slotBtnのテキストと背景色を設定
		local contentName = slotContents[i] or "Empty"
		slotBtn.Text = "Slot " .. i .. "\n" .. contentName

		if contentName == "Empty" then
			slotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		else
			slotBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
		end

		-- タップ時の格納・回収リクエスト
		slotBtn.MouseButton1Click:Connect(function()
			carryRemote:FireServer("StoreOrRetrieve", i) -- slotIndex をサーバーに送信
		end)
	end

	-- CarryUpgrade UIの作成
	local upgradeBtn = Instance.new("TextButton")
	upgradeBtn.Size = UDim2.new(0, 100, 0, 40)
	upgradeBtn.BorderSizePixel = 1
	upgradeBtn.LayoutOrder = slotCount + 1 -- スロットの次に追加
	upgradeBtn.TextSize = 10
	upgradeBtn.TextWrapped = true
	upgradeBtn.TextColor3 = Color3.new(1, 1, 1)
	upgradeBtn.Parent = frame

	local upgradeText = string.format("Carry Upgrade\nLevel: %d\nCost: %d", currentCarryUpgradeLevel, currentCarryUpgradeCost)
	upgradeBtn.Text = upgradeText
	
	-- コストが0より大きい場合（アップグレード可能）、または最大レベルでない場合は緑色に、それ以外は灰色にする
	-- (CarryUpgradeCostが0の場合は、最大レベル到達などの理由でアップグレード不可とみなす)
	if currentCarryUpgradeCost > 0 then
		upgradeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0) -- アップグレード可能
	else
		upgradeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- アップグレード不可（最大レベルなど）
	end

	-- タップ時のアップグレードリクエスト
	upgradeBtn.MouseButton1Click:Connect(function()
		if currentCarryUpgradeCost > 0 then
			carryRemote:FireServer("UpgradeCarry") -- アップグレードをリクエスト
		end
	end)
end

-- サーバーからのUI更新通知を受け取る
carryRemote.OnClientEvent:Connect(function(action, data)
	if action == "UpdateUI" then
		local slotContents = data.Slots
		local carryUpgradeLevel = data.CarryUpgradeLevel
		local carryUpgradeCost = data.CarryUpgradeCost
		updateCarryStorageUI(slotContents, carryUpgradeLevel, carryUpgradeCost)
	elseif action == "NotifyUpgradeSuccess" then
		-- アップグレード成功時のフィードバック（必要であれば追加）
		print("Carry Upgrade successful!")
	elseif action == "NotifyUpgradeFail" then
		-- アップグレード失敗時のフィードバック（必要であれば追加）
		print("Carry Upgrade failed!")
	end
end)

-- ゲーム開始時にサーバーにUI更新を要求
carryRemote:FireServer("RequestUIUpdate")
