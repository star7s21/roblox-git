local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local carryRemote = ReplicatedStorage:WaitForChild("CarryRemote")
local playerGui = player:WaitForChild("PlayerGui")

local currentSlotCount = 0 -- 現在表示されているスロット数

local function updateCarryStorageUI(slotContents)
	-- 既存のUIがあれば削除
	local existingGui = playerGui:FindFirstChild("CarryStorageGui")
	if existingGui then
		existingGui:Destroy()
	end
	
	local slotCount = #slotContents
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
			carryRemote:FireServer(i) -- slotIndex をサーバーに送信
		end)
	end
end

-- サーバーからのUI更新通知を受け取る
carryRemote.OnClientEvent:Connect(function(action, slotContents)
	if action == "UpdateUI" then
		updateCarryStorageUI(slotContents)
	end
end)

-- ゲーム開始時にサーバーにUI更新を要求
carryRemote:FireServer("RequestUIUpdate")

local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local formatNumber = Utils.formatNumber

local function updatePrompt(prompt)
	local costValue = player:FindFirstChild("CarryUpgradeCost")
	local cost = costValue and costValue.Value or 500
	prompt.ObjectText = "Coins: " .. formatNumber(cost)
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Parent and prompt.Parent.Name == "CarryUpgrade" then
		updatePrompt(prompt)
	end
end)

-- コスト変更時は「表示中のpromptだけ更新」
local costValue = player:WaitForChild("CarryUpgradeCost")

costValue:GetPropertyChangedSignal("Value"):Connect(function()
	local prompt = workspace.CarryUpgrade:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		updatePrompt(prompt)
	end
end)
