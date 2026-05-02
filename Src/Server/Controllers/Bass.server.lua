local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local goal = workspace:WaitForChild("StartArea")
local baseTemplate = ServerStorage:WaitForChild("BaseModel")
local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

-- =========================
-- スロット管理
-- =========================
local SPACING = 100
local MAX_SLOTS = 10

local used = {}
local generators = {}

local function assignSlot(player)
	for i = 1, MAX_SLOTS do
		if not used[i] then
			used[i] = player.UserId

			local offsetIndex = i - 1
			local direction = (offsetIndex % 2 == 0) and 1 or -1
			local step = math.ceil(offsetIndex / 2)

			local x = step * SPACING * direction
			return Vector3.new(x, 10, 0), i
		end
	end

	warn("Server full!")
	return nil, nil
end

local function releaseSlot(player)
	for i, id in pairs(used) do
		if id == player.UserId then
			used[i] = nil
		end
	end
end

-- =========================
-- 状態リセット
-- =========================
local function clearTreasure(player, character)
	for _, name in ipairs({"HasTreasure","TreasureValue","TreasureType"}) do
		local v = player:FindFirstChild(name)
		if v then v:Destroy() end
	end

	if character then
		local carried = character:FindFirstChild("CarriedTreasure")
		if carried then carried:Destroy() end
	end
end

-- =========================
-- スピード適用
-- =========================
local function applySpeed(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local speed = player:WaitForChild("leaderstats"):WaitForChild("Speed")

	humanoid.WalkSpeed = speed.Value

	speed:GetPropertyChangedSignal("Value"):Connect(function()
		if humanoid.Parent then
			humanoid.WalkSpeed = speed.Value
		end
	end)
end

-- =========================
-- コイン生成（安全版）
-- =========================
local function startGenerating(player, item)
	local alive = true

	task.spawn(function()
		while alive and item and item.Parent do
			task.wait(5)

			local coins = player:FindFirstChild("leaderstats")
				and player.leaderstats:FindFirstChild("Coins")

			if coins then
				local value = item:GetAttribute("Value") or 0
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

	-- UI更新
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

	-- 処理
	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player or debounce then return end
		debounce = true

		local character = player.Character
		if not character then debounce = false return end

		local stored = placePart:FindFirstChild("StoredItem")
		local hasTreasure = player:FindFirstChild("HasTreasure")

		-- 回収
		if stored and stored.Value and not hasTreasure then

			local item = stored.Value
			clearTreasure(player, character)

			Instance.new("BoolValue", player).Name = "HasTreasure"

			local value = Instance.new("IntValue", player)
			value.Name = "TreasureValue"
			value.Value = item:GetAttribute("Value") or 0

			local typeValue = Instance.new("StringValue", player)
			typeValue.Name = "TreasureType"
			typeValue.Value = item.Name

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

					clone.PrimaryPart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")

					if clone.PrimaryPart then
						clone:PivotTo(hrp.CFrame * CFrame.new(0,2,-2))

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = clone.PrimaryPart
						weld.Part1 = hrp
						weld.Parent = clone.PrimaryPart
					end
				end
			end

			item:Destroy()
			stored:Destroy()

		-- 設置
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

			local storedItem = Instance.new("ObjectValue", placePart)
			storedItem.Name = "StoredItem"
			storedItem.Value = item

			-- コイン生成管理
			if generators[player] then
				generators[player]()
			end
			generators[player] = startGenerating(player, item)

			clearTreasure(player, character)
		end

		debounce = false
	end)
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

	base.PrimaryPart = base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")

	local pos, slotIndex = assignSlot(player)
	if not pos then
		player:Kick("Server is full")
		return nil
	end

	if base.PrimaryPart then
		base:PivotTo(goal.CFrame + pos)
	else
		base:MoveTo((goal.CFrame + pos).Position)
	end

	return base
end

-- =========================
-- Player
-- =========================
Players.PlayerAdded:Connect(function(player)

	local base = createBase(player)
	if not base then return end

	for _, slot in ipairs(base.Base:GetChildren()) do
		if slot:IsA("Model") then
			setupSlot(player, base, slot)
		end
	end

	player.CharacterAdded:Connect(function(character)
		clearTreasure(player, character)
		applySpeed(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)

	releaseSlot(player)

	if generators[player] then
		generators[player]()
		generators[player] = nil
	end

	local base = workspace:FindFirstChild(player.Name .. "_Base")
	if base then
		base:Destroy()
	end
end)