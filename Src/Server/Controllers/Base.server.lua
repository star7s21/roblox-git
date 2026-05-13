local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TreasureConfig = require(game:GetService("ServerScriptService").Server.Services.TreasureConfig)

local goal = workspace:WaitForChild("StartArea")
local baseTemplate = ServerStorage:WaitForChild("BaseModel")
local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

-- =========================
-- スロット管理
-- =========================
local SPACING = 150
local MAX_SLOTS = 7

local used = {}
local speedConnections = {}

local function assignSlot(player)
	for i = 1, MAX_SLOTS do
		if not used[i] then
			used[i] = player.UserId

			local offsetIndex = i - 1
			local direction = (offsetIndex % 2 == 0) and 1 or -1
			local step = math.ceil(offsetIndex / 2)

			local x = step * SPACING * direction
			return Vector3.new(x, 7.5, 0), i
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
	for _, name in ipairs({"HasTreasure","TreasureValue","TreasureType","TreasureLevel"}) do
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
-- ステータス計算
local function getStats(player, typeName, level)
	local config = nil
	for _, t in ipairs(TreasureConfig.Types) do
		if t.name == typeName or t.model == typeName then
			config = t
			break
		end
	end
	if not config then return 0, 0 end

	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
	local rebirthMultiplier = 1 + (rebirths and rebirths.Value or 0)

	local coinsPerSecond = config.baseCoinsPerSecond
		* config.rarityMultiplier
		* (config.levelMultiplier ^ (level - 1))
		* rebirthMultiplier

	local maxCapacity = coinsPerSecond
		* config.baseCapacityTime
		* config.capacityMultiplier

	return coinsPerSecond, maxCapacity
end

local function getUpgradeCost(level)
	return math.floor(100 * (1.8 ^ (level - 1)))
end

local function applySpeed(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local speed = player:WaitForChild("leaderstats"):WaitForChild("Speed")

	humanoid.WalkSpeed = speed.Value

	-- 古い接続があれば解除
	if speedConnections[player] then
		speedConnections[player]:Disconnect()
	end

	-- 新しいキャラクターのHumanoidに対して接続
	speedConnections[player] = speed.Changed:Connect(function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = speed.Value
		end
	end)
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

	local clickDetector = placePart:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.Parent = placePart
	end

	local collectDebounce = false
	local promptDebounce = false

	-- 初期属性
	if not placePart:GetAttribute("Level") then placePart:SetAttribute("Level", 1) end
	if not placePart:GetAttribute("CurrentCoins") then placePart:SetAttribute("CurrentCoins", 0) end
	if not placePart:GetAttribute("LastUpdateTime") then placePart:SetAttribute("LastUpdateTime", os.clock()) end

	local function updateSlot()
		local stored = placePart:FindFirstChild("StoredItem")
		local item = stored and stored.Value
		if not item or not item.Parent then
			placePart:SetAttribute("CurrentCoins", 0)
			placePart:SetAttribute("LastUpdateTime", os.clock())
			return 0, 0
		end

		local level = placePart:GetAttribute("Level") or 1
		local currentCoins = placePart:GetAttribute("CurrentCoins") or 0
		local lastUpdateTime = placePart:GetAttribute("LastUpdateTime") or os.clock()

		local now = os.clock()
		local delta = now - lastUpdateTime

		local cps, maxCap = getStats(player, item.Name, level)

		currentCoins = math.min(maxCap, currentCoins + cps * delta)

		placePart:SetAttribute("CurrentCoins", currentCoins)
		placePart:SetAttribute("LastUpdateTime", now)

		return currentCoins, maxCap
	end

	-- Touched (コイン回収)
	touchPart.Touched:Connect(function(hit)
		local char = hit.Parent
		local p = Players:GetPlayerFromCharacter(char)
		if p ~= player or collectDebounce then return end

		local stored = placePart:FindFirstChild("StoredItem")
		if not stored or not stored.Value then return end

		collectDebounce = true
		local current, _ = updateSlot()
		if current and current > 0 then
			local leaderstats = player:FindFirstChild("leaderstats")
			local coins = leaderstats and leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + math.floor(current)
				placePart:SetAttribute("CurrentCoins", 0)
			end
		end
		task.wait(0.5)
		collectDebounce = false
	end)

	-- UI (BillboardGui) 作成
	local billboard = touchPart:FindFirstChild("StatusUI")
	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "StatusUI"
		billboard.Size = UDim2.new(0, 100, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 6, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = touchPart
		billboard.MaxDistance = 50

		local text = Instance.new("TextLabel")
		text.Name = "Label"
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.new(0, 0, 0)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextWrapped = true
		text.Parent = billboard
	end

	-- SurfaceGui (上面表示用) 作成
	local surfaceGui = touchPart:FindFirstChild("SurfaceStatusUI")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "SurfaceStatusUI"
		surfaceGui.Face = Enum.NormalId.Top
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surfaceGui.PixelsPerStud = 50
		surfaceGui.Parent = touchPart

		local text = Instance.new("TextLabel")
		text.Name = "Label"
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.new(1, 1, 1)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = surfaceGui
	end

	-- ItemArea UI (側面レベル表示)
	local itemSurfaceGui = placePart:FindFirstChild("LevelUI")
	if not itemSurfaceGui then
		itemSurfaceGui = Instance.new("SurfaceGui")
		itemSurfaceGui.Name = "LevelUI"
		itemSurfaceGui.Face = Enum.NormalId.Front
		itemSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		itemSurfaceGui.PixelsPerStud = 50
		itemSurfaceGui.Parent = placePart

		local text = Instance.new("TextLabel")
		text.Name = "Label"
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.new(1, 1, 0)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = itemSurfaceGui
	end

	-- UI更新
	task.spawn(function()
		while base.Parent do
			task.wait(1)

			local stored = placePart:FindFirstChild("StoredItem")
			local hasTreasure = player:FindFirstChild("HasTreasure")
			local item = stored and stored.Value
			local level = placePart:GetAttribute("Level") or 1

			local current, maxCap = updateSlot()

			local canPickup = item and not hasTreasure
			local canPlace = hasTreasure and not item

			prompt.Enabled = canPickup or canPlace

			if item then
				prompt.ObjectText = item.Name
				prompt.ActionText = "Pick Up"
				
				local cps, _ = getStats(player, item.Name, level)
				local statusText = "Lv." .. level .. "\n"
				local coinText = tostring(math.floor(current))
				if current >= maxCap then
					statusText = statusText .. "FULL!"
					billboard.Label.TextColor3 = Color3.fromRGB(255, 255, 0)
					surfaceGui.Label.TextColor3 = Color3.fromRGB(255, 255, 0)
					touchPart.Color = Color3.fromRGB(255, 255, 0)
				else
					statusText = statusText .. "+" .. math.floor(cps) .. "/s"
					billboard.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
					surfaceGui.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
					touchPart.Color = Color3.fromRGB(163, 162, 165)
				end
				billboard.Label.Text = statusText
				billboard.Enabled = true
				surfaceGui.Label.Text = coinText
				surfaceGui.Enabled = true

				local upCost = getUpgradeCost(level)
				itemSurfaceGui.Label.Text = "Lv." .. level .. " -> " .. (level + 1) .. "\n(" .. upCost .. ")"
				itemSurfaceGui.Enabled = true

				clickDetector.MaxActivationDistance = 32
			elseif canPlace then
				prompt.ActionText = "Place"
				prompt.ObjectText = "Empty Slot"
				touchPart.Color = Color3.fromRGB(163, 162, 165)
				billboard.Enabled = false
				surfaceGui.Enabled = false
				itemSurfaceGui.Enabled = false
				clickDetector.MaxActivationDistance = 0
			else
				prompt.Enabled = false
				touchPart.Color = Color3.fromRGB(163, 162, 165)
				billboard.Enabled = false
				surfaceGui.Enabled = false
				itemSurfaceGui.Enabled = false
				clickDetector.MaxActivationDistance = 0
			end
		end
	end)

	-- 処理 (レベルアップ)
	clickDetector.MouseClick:Connect(function(triggerPlayer)
		if triggerPlayer ~= player or promptDebounce then return end
		promptDebounce = true

		local stored = placePart:FindFirstChild("StoredItem")
		local item = stored and stored.Value
		if not item then promptDebounce = false return end

		local level = placePart:GetAttribute("Level") or 1
		local cost = getUpgradeCost(level)

		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")

		if coins and coins.Value >= cost then
			coins.Value = coins.Value - cost
			placePart:SetAttribute("Level", level + 1)
		end

		promptDebounce = false
	end)

	-- 処理 (配置/回収)
	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player or promptDebounce then return end
		promptDebounce = true

		local character = player.Character
		if not character then promptDebounce = false return end

		local stored = placePart:FindFirstChild("StoredItem")
		local hasTreasure = player:FindFirstChild("HasTreasure")

		-- 回収
		if stored and stored.Value and not hasTreasure then

			local item = stored.Value
			local level = placePart:GetAttribute("Level") or 1
			clearTreasure(player, character)

			Instance.new("BoolValue", player).Name = "HasTreasure"

			local levelValue = Instance.new("IntValue", player)
			levelValue.Name = "TreasureLevel"
			levelValue.Value = level

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

			local levelValue = player:FindFirstChild("TreasureLevel")
			local typeValue = player:FindFirstChild("TreasureType")
			if not levelValue or not typeValue then promptDebounce = false return end

			local template = treasureFolder:FindFirstChild(typeValue.Value)
			if not template then promptDebounce = false return end

			local item = template:Clone()
			item.Parent = base
			placePart:SetAttribute("Level", levelValue.Value)
			placePart:SetAttribute("CurrentCoins", 0)
			placePart:SetAttribute("LastUpdateTime", os.clock())

			local yOffset = (placePart.Size.Y / 2) + (item:GetExtentsSize().Y / 2)
			if item.PrimaryPart then
				item:PivotTo(placePart.CFrame * CFrame.new(0, yOffset, 0))
			else
				item:MoveTo((placePart.CFrame * CFrame.new(0, yOffset, 0)).Position)
			end

			local storedItem = Instance.new("ObjectValue", placePart)
			storedItem.Name = "StoredItem"
			storedItem.Value = item

			clearTreasure(player, character)
		end

		promptDebounce = false
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

	if speedConnections[player] then
		speedConnections[player]:Disconnect()
		speedConnections[player] = nil
	end
end)
