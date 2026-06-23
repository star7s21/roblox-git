local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local carryRemote = ReplicatedStorage:WaitForChild("CarryRemote")
local playerGui = player:WaitForChild("PlayerGui")

local CarryConfig = require(ReplicatedStorage.Shared.CarryConfig) -- CarryConfigをReplicatedStorageからロード

local currentSlotCount = 0 -- 現在表示されているスロット数

local function updateCarryStorageUI(slotCount)
	-- 既存のUIがあれば削除
	local existingGui = playerGui:FindFirstChild("CarryStorageGui")
	if existingGui then
		existingGui:Destroy()
	end
	
	-- slotCountが0以下の場合はUIを表示しない
	if slotCount <= 0 then
		return
	end

	currentSlotCount = slotCount -- 現在のスロット数を更新

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CarryStorageGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	-- 横並びにするため、幅をスロット数に合わせてスケール
	frame.Size = UDim2.new(0, 65 * slotCount, 0, 50)
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
		slotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		slotBtn.BorderSizePixel = 1
		slotBtn.LayoutOrder = i
		slotBtn.TextSize = 10
		slotBtn.TextWrapped = true
		slotBtn.TextColor3 = Color3.new(1, 1, 1)
		slotBtn.Parent = frame

		-- slotBtnのテキストと背景色を設定
		slotBtn.Text = "Slot " .. i .. "\nEmpty"
		slotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

		-- タップ時の格納・回収リクエスト
		slotBtn.MouseButton1Click:Connect(function()
			carryRemote:FireServer(i) -- slotIndex をサーバーに送信
		end)
	end
end

-- サーバーからのUI更新通知を受け取る
carryRemote.OnClientEvent:Connect(function(action, slotCount)
	if action == "UpdateUI" then
		updateCarryStorageUI(slotCount)
	end
end)

-- 初期化およびキャラクターロード時のUI更新
-- プレイヤー参加時にサーバーから初期スロット数が通知されるのを待つ
-- player.CharacterAdded:Connect(function(character)
-- 	-- キャラクターロード時にサーバーからUI更新情報が送られてくるはずなので、ここでは特別な処理は不要
-- end)

-- ゲーム開始時（またはクライアントロード時）にサーバーにUI更新を要求
-- carryRemote:FireServer("RequestUIUpdate") -- これはサーバー側でHandleされる必要あり
