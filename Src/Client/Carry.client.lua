local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local carryLevel = player:WaitForChild("CarryLevel")
local playerGui = player:WaitForChild("PlayerGui")
local carrySlots = player:WaitForChild("CarrySlots")
local carryRemote = ReplicatedStorage:WaitForChild("CarryRemote")

local function updateCarryStorageUI()
	-- 既存のUIがあれば削除
	local existingGui = playerGui:FindFirstChild("CarryStorageGui")
	if existingGui then
		existingGui:Destroy()
	end

	-- レベル1の時は表示しない
	if carryLevel.Value <= 1 then
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CarryStorageGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	-- 横並びにするため、幅をレベルに合わせてスケール
	frame.Size = UDim2.new(0, 65 * carryLevel.Value, 0, 50)
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
	for i = 1, carryLevel.Value do
		local slotBtn = Instance.new("TextButton")
		slotBtn.Size = UDim2.new(0, 60, 0, 40)
		slotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		slotBtn.BorderSizePixel = 1
		slotBtn.LayoutOrder = i
		slotBtn.TextSize = 10
		slotBtn.TextWrapped = true
		slotBtn.TextColor3 = Color3.new(1, 1, 1)
		slotBtn.Parent = frame

		-- スロット状態の監視と表示更新
		local slotVal = carrySlots:WaitForChild("Slot" .. i)
		local function updateSlotText()
			if slotVal.Value then
				slotBtn.Text = "Slot " .. i .. "\n" .. slotVal.Value.Name
				slotBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60) -- 格納中は色を変更
			else
				slotBtn.Text = "Slot " .. i .. "\nEmpty"
				slotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			end
		end

		slotVal.Changed:Connect(updateSlotText)
		updateSlotText()

		-- タップ時の格納・回収リクエスト
		slotBtn.MouseButton1Click:Connect(function()
			carryRemote:FireServer(i)
		end)
	end
end

-- 値の変更時にUIを更新
carryLevel:GetPropertyChangedSignal("Value"):Connect(function()
	updateCarryStorageUI()
end)

-- 初期化およびキャラクターロード時のUI更新
updateCarryStorageUI()

player.CharacterAdded:Connect(function(character)
	updateCarryStorageUI()
end)
