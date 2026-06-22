local Players = game:GetService("Players")
local player = Players.LocalPlayer

local carryLevel = player:WaitForChild("CarryLevel")
local playerGui = player:WaitForChild("PlayerGui")

local function updateCarryStorageUI()
	-- 既存のUIがあれば削除
	local existingGui = playerGui:FindFirstChild("CarryStorageGui")
	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CarryStorageGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 40 * carryLevel.Value) -- レベルに応じた高さ調整
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -10) -- 画面下部中央に配置
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	-- 各キャリースロットの作成
	for i = 1, carryLevel.Value do
		local slotFrame = Instance.new("Frame")
		slotFrame.Size = UDim2.new(1, 0, 0, 40)
		slotFrame.BackgroundTransparency = 1
		slotFrame.LayoutOrder = i
		slotFrame.Parent = frame

		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, 0, 0, 40)
		slotLabel.Text = "Slot " .. i .. ": Empty"
		slotLabel.TextColor3 = Color3.new(1,1,1)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Parent = slotFrame
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
