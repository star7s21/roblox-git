local MAX_CARRY_LEVEL = 5
local CARRY_SLOT_HEIGHT = 40 -- UIの各スロットの高さ
local carryLevelIncrease = 1
local carryDebounce = {}

local function applyCarryLevel(player, char)
	if not char then return end
	local carryLevel = player:FindFirstChild("CarryLevel")

	if not carryLevel then return end

	local currentCarryLevel = carryLevel.Value

	-- UIの更新（CarryStorageContainer内のScreenGuiを更新）
	local carryStorageContainer = char:FindFirstChild("CarryStorageContainer")
	if carryStorageContainer then
		local screenGui = carryStorageContainer:FindFirstChild("CarryStorageGui")
		if screenGui then
			local frame = screenGui:FindFirstChildOfClass("Frame")
			if frame then
				frame.Size = UDim2.new(0, 200, 0, CARRY_SLOT_HEIGHT * currentCarryLevel) -- UIの高さをレベルに合わせて更新

				-- slotsの更新
				local slots = {}
				for _, child in ipairs(frame:GetChildren()) do
					if child:IsA("Frame") and child:FindFirstChild("TextLabel") then
						table.insert(slots, child)
					end
				end

				-- 新しいレベルのUIを追加
				for i = #slots + 1, currentCarryLevel do
					local slotFrame = Instance.new("Frame")
					slotFrame.Size = UDim2.new(1, 0, 0, CARRY_SLOT_HEIGHT)
					slotFrame.BackgroundTransparency = 1
					slotFrame.LayoutOrder = i
					slotFrame.Parent = frame

					local slotLabel = Instance.new("TextLabel")
					slotLabel.Size = UDim2.new(1, 0, 0, CARRY_SLOT_HEIGHT)
					slotLabel.Text = "Slot " .. i .. ": Empty"
					slotLabel.TextColor3 = Color3.new(1,1,1)
					slotLabel.BackgroundTransparency = 1
					slotLabel.Parent = slotFrame
				end
			end
		end
	end
end

local function addCarrySlot(player, char)
	if not char then return end
	local carryLevel = player:FindFirstChild("CarryLevel")
	if not carryLevel then return end

	local newLevel = carryLevel.Value + carryLevelIncrease
	if newLevel <= MAX_CARRY_LEVEL then
		carryLevel.Value = newLevel
		applyCarryLevel(player, char)
	end
end

-- CarryUpgrade PadのProximityPrompt設定
local carryUpgradePad = workspace:WaitForChild("CarryUpgrade")
local carryPrompt = carryUpgradePad:FindFirstChildOfClass("ProximityPrompt")

if not carryPrompt then
	carryPrompt = Instance.new("ProximityPrompt")
	carryPrompt.Parent = carryUpgradePad
end
carryPrompt.ActionText = "Upgrade Carry"
carryPrompt.KeyboardKeyCode = Enum.KeyCode.E
carryPrompt.HoldDuration = 0

carryPrompt.Triggered:Connect(function(player)
	if carryDebounce[player] then return end

	local carryLevel = player:FindFirstChild("CarryLevel")
	if not carryLevel then return end

	if carryLevel.Value >= MAX_CARRY_LEVEL then
		carryPrompt.ActionText = "❌ Max Level"
		task.delay(1.5, function()
			carryPrompt.ActionText = "Upgrade Carry"
		end)
		return
	end

	carryDebounce[player] = true
	carryPrompt.ActionText = "⏳ Wait..."

	addCarrySlot(player, player.Character) -- CarryレベルとUIを更新

	task.delay(0.2, function()
		carryDebounce[player] = nil
		carryPrompt.ActionText = "Upgrade Carry"
	end)
end)

-- PlayerAdded & CharacterAdded で Carry UI を初期化
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5) -- Character初期化を待つ
		applyCarryLevel(player, char)
	end)
end)

-- 既存プレイヤーの初期化
for _, player in ipairs(game.Players:GetPlayers()) do
	if player.Character then
		task.spawn(applyCarryLevel, player, player.Character)
	end
end

-- CarryLevel変更時のUI更新
local function watchCarryLevel(player)
	local carryLevel = player:WaitForChild("CarryLevel", 10)
	if carryLevel then
		carryLevel.Changed:Connect(function()
			applyCarryLevel(player, player.Character)
		end)
	end
end
game.Players.PlayerAdded:Connect(watchCarryLevel)
for _, player in ipairs(game.Players:GetPlayers()) do
	task.spawn(watchCarryLevel, player)
end

-- =========================
-- クリーンアップ
-- =========================
game.Players.PlayerRemoving:Connect(function(player)
	carryDebounce[player] = nil
end)
