local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local goal = workspace:WaitForChild("StartArea")
local baseTemplate = ServerStorage:WaitForChild("BaseModel")
local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

-- =========================
-- 状態リセット
-- =========================
local function clearTreasure(player, character)
	for _, name in ipairs({"HasTreasure", "TreasureValue", "TreasureType"}) do
		local v = player:FindFirstChild(name)
		if v then v:Destroy() end
	end

	if character then
		local carried = character:FindFirstChild("CarriedTreasure")
		if carried then carried:Destroy() end
	end
end

-- =========================
-- ベースクリア
-- =========================
local function clearBase(base)
	for _, slot in ipairs(base.Base:GetChildren()) do
		local placePart = slot:FindFirstChild("ItemArea")
		if placePart then
			local stored = placePart:FindFirstChild("StoredItem")
			if stored then
				if stored.Value then
					stored.Value:Destroy()
				end
				stored:Destroy()
			end
		end
	end
end

-- =========================
-- Base生成
-- =========================
local function createBase(player)
	local old = workspace:FindFirstChild(player.Name .. "_Base")
	if old then old:Destroy() end

	local base = baseTemplate:Clone()
	base.Name = player.Name .. "_Base"
	base.Parent = workspace
	base:PivotTo(goal.CFrame * CFrame.new(0, 10, 0))

	return base
end

-- =========================
-- スピード適用（重要）
-- =========================
local function applySpeed(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local speed = player:WaitForChild("leaderstats"):WaitForChild("Speed")

	humanoid.WalkSpeed = speed.Value

	speed:GetPropertyChangedSignal("Value"):Connect(function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = speed.Value
		end
	end)
end

-- =========================
-- コイン生成
-- =========================
local function startGenerating(player, item)
	local alive = true

	task.spawn(function()
		while alive and item and item.Parent do
			task.wait(5)

			local value = item:GetAttribute("Value")
			local coins = player:FindFirstChild("leaderstats")
				and player.leaderstats:FindFirstChild("Coins")

			if value and coins then
				coins.Value += value
			end
		end
	end)

	return function()
		alive = false
	end
end

-- =========================
-- SLOT
-- =========================
local function setupSlot(player, base, slot)

	local touchPart = slot:FindFirstChild("TouchArea")
	local placePart = slot:FindFirstChild("ItemArea")
	if not touchPart or not placePart then return end

	local prompt = touchPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = touchPart
	end

	prompt.HoldDuration = 0

	local debounce = false
	local stopCoinGen = nil

	-- UI
	task.spawn(function()
		while base.Parent do
			task.wait(0.2)

			local stored = placePart:FindFirstChild("StoredItem")
			local hasTreasure = player:FindFirstChild("HasTreasure")

			local item = stored and stored.Value

			local canPickup = item and not hasTreasure
			local canPlace = hasTreasure and not item

			prompt.Enabled = canPickup or canPlace

			if canPickup then
				prompt.ActionText = "Pick Up"
				prompt.ObjectText = item.Name
			elseif canPlace then
				prompt.ActionText = "Place"
				prompt.ObjectText = "Empty Slot"
			end
		end
	end)

	-- 触発
	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player then return end
		if debounce then return end
		debounce = true

		local character = player.Character
		if not character then debounce = false return end

		local stored = placePart:FindFirstChild("StoredItem")
		local hasTreasure = player:FindFirstChild("HasTreasure")

		-- =========================
		-- 回収
		-- =========================
		if stored and stored.Value and not hasTreasure then

			local item = stored.Value
			clearTreasure(player, character)

			Instance.new("BoolValue", player).Name = "HasTreasure"

			local value = Instance.new("IntValue")
			value.Name = "TreasureValue"
			value.Value = item:GetAttribute("Value") or 0
			value.Parent = player

			local typeValue = Instance.new("StringValue")
			typeValue.Name = "TreasureType"
			typeValue.Value = item.Name
			typeValue.Parent = player

			local hrp = character:FindFirstChild("HumanoidRootPart")

			if hrp then
				local template = treasureFolder:FindFirstChild(item.Name)
				if template then
					local clone = template:Clone()
					clone.Name = "CarriedTreasure"
					clone.Parent = character

					for _, p in ipairs(clone:GetDescendants()) do
						if p:IsA("BasePart") then
							p.Anchored = false
							p.CanCollide = false
							p.Massless = true
						end
					end

					if not clone.PrimaryPart then
						clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart")
					end

					if clone.PrimaryPart then
						clone:PivotTo(hrp.CFrame * CFrame.new(0, 2, -2))

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = clone.PrimaryPart
						weld.Part1 = hrp
						weld.Parent = clone.PrimaryPart
					end
				end
			end

			item:Destroy()
			stored:Destroy()

		-- =========================
		-- 設置
		-- =========================
		elseif hasTreasure and (not stored or not stored.Value) then

			local value = player:FindFirstChild("TreasureValue")
			local typeValue = player:FindFirstChild("TreasureType")
			if not value or not typeValue then debounce = false return end

			local template = treasureFolder:FindFirstChild(typeValue.Value)
			if not template then debounce = false return end

			local item = template:Clone()
			item.Parent = base
			item:SetAttribute("Value", value.Value)

			if item.PrimaryPart then
				item:PivotTo(placePart.CFrame)
			else
				item:MoveTo(placePart.Position)
			end

			local storedItem = Instance.new("ObjectValue")
			storedItem.Name = "StoredItem"
			storedItem.Value = item
			storedItem.Parent = placePart

			if stopCoinGen then stopCoinGen() end
			stopCoinGen = startGenerating(player, item)

			clearTreasure(player, character)
		end

		task.delay(0.2, function()
			debounce = false
		end)
	end)
end

-- =========================
-- Player
-- =========================
Players.PlayerAdded:Connect(function(player)

	-- Base作成
	local base = createBase(player)

	-- slotsセット
	for _, slot in ipairs(base.Base:GetChildren()) do
		if slot:IsA("Model") then
			setupSlot(player, base, slot)
		end
	end

	-- Character
	player.CharacterAdded:Connect(function(character)
		clearTreasure(player, character)
		applySpeed(player, character)
	end)
end)