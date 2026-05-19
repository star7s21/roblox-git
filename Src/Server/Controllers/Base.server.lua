local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local TreasureConfig = require(game:GetService("ServerScriptService").Server.Services.TreasureConfig)

local function formatNumber(n)
	local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi"}
	local i = 1
	local val = n
	while val >= 1000 and i < #suffixes do
		val = val / 1000
		i = i + 1
	end
	return i == 1 and tostring(math.floor(val)) or string.format("%.1f%s", val, suffixes[i])
end

local goal = workspace:WaitForChild("StartArea", 10) or { CFrame = CFrame.new(0, 7.5, 0) }
local baseTemplate = ServerStorage:WaitForChild("BaseModel")
local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

-- =========================
-- スロット管理
-- =========================
local SPACING = 70
local MAX_SLOTS = 7
local MAX_BASE_LEVEL = 4

local used = {}
local speedConnections = {}
local playerBases = {}

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
	for _, name in ipairs({"HasTreasure","TreasureValue","TreasureType","TreasureLevel","TreasureDisplayName"}) do
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
	local config = TreasureConfig.GetRarity(typeName)
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

local function getBaseUpgradeCost(level)
	return math.floor(10000 * (4 ^ (level - 1)))
end

local function getSellPrice(typeName, level)
	local config = TreasureConfig.GetRarity(typeName)
	if not config then return 0 end

	local baseValue = 50
	return math.floor(baseValue * config.rarityMultiplier * (1.5 ^ (level - 1)))
end

local function applySpeed(player, character)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if not leaderstats then return end
		local speed = leaderstats:WaitForChild("Speed", 10)

		if not humanoid or not speed then return end

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
	end)
end

-- =========================
-- SLOT
-- =========================
local function setupSlot(player, base, slot)

	local touchPart = slot:FindFirstChild("TouchArea") or (slot:IsA("BasePart") and slot)
	local placePart = slot:FindFirstChild("ItemArea")
	if not touchPart or not placePart then return end

	local attachment = placePart:FindFirstChild("PromptAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "PromptAttachment"
		attachment.Position = Vector3.new(0, 2, 0)
		attachment.Parent = placePart
	end

	local sellAttachment = placePart:FindFirstChild("SellPromptAttachment")
	if not sellAttachment then
		sellAttachment = Instance.new("Attachment")
		sellAttachment.Name = "SellPromptAttachment"
		sellAttachment.Position = Vector3.new(0, 4, 0)
		sellAttachment.Parent = placePart
	end

	local prompt = attachment:FindFirstChild("ActionPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ActionPrompt"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 20
		prompt.Parent = attachment
	end

	local sellPrompt = sellAttachment:FindFirstChild("SellPrompt")
	if not sellPrompt then
		sellPrompt = Instance.new("ProximityPrompt")
		sellPrompt.Name = "SellPrompt"
		sellPrompt.HoldDuration = 1.0
		sellPrompt.ActionText = "Sell"
		sellPrompt.KeyboardKeyCode = Enum.KeyCode.F
		sellPrompt.RequiresLineOfSight = false
		sellPrompt.MaxActivationDistance = 20
		sellPrompt.Parent = sellAttachment
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
				if surfaceGui and surfaceGui:FindFirstChild("Label") then
					surfaceGui.Label.Text = "0"
				end
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
		text.TextColor3 = Color3.new(0,0,0)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = itemSurfaceGui
	end

	-- UI更新
	task.spawn(function()
		while base.Parent do
			local success, err = pcall(function()
				local stored = placePart:FindFirstChild("StoredItem")
				local hasTreasure = player:FindFirstChild("HasTreasure")
				local item = (stored and stored.Value and stored.Value:IsDescendantOf(game)) and stored.Value or nil
				local level = placePart:GetAttribute("Level") or 1

				local current, maxCap = updateSlot()

				local canPickup = item ~= nil and not hasTreasure
				local canPlace = hasTreasure and not item

				prompt.Enabled = canPickup or canPlace
				sellPrompt.Enabled = (item ~= nil)

				if item then
					local displayName = item:GetAttribute("DisplayName") or item.Name
					prompt.ObjectText = displayName
					prompt.ActionText = "Pick Up"

					local sellPrice = getSellPrice(item.Name, level)
					sellPrompt.ObjectText = displayName .. " (" .. formatNumber(sellPrice) .. ")"
					
					local config = TreasureConfig.GetRarity(item.Name)
					local rarityName = config and config.name or item.Name

					local cps, _ = getStats(player, item.Name, level)
					local statusText = rarityName .. " Lv." .. level .. "\n"
					local coinText = formatNumber(current)
					if current >= maxCap then
						statusText = statusText .. "FULL!"
						coinText = "FULL\n" .. coinText
						billboard.Label.TextColor3 = Color3.fromRGB(255, 255, 0)
						surfaceGui.Label.TextColor3 = Color3.fromRGB(255, 255, 0)
						touchPart.Color = Color3.fromRGB(255, 255, 0)
					else
						statusText = statusText .. "+" .. formatNumber(cps) .. "/s"
						billboard.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
						surfaceGui.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
						touchPart.Color = Color3.fromRGB(255, 0, 0)
					end
					billboard.Label.Text = statusText

					if item.PrimaryPart then
						billboard.Adornee = item.PrimaryPart
						billboard.StudsOffset = Vector3.new(0, item:GetExtentsSize().Y / 2 + 2, 0)
					else
						billboard.Adornee = touchPart
						billboard.StudsOffset = Vector3.new(0, 6, 0)
					end

					billboard.Enabled = true
					surfaceGui.Label.Text = coinText
					surfaceGui.Enabled = true

					local upCost = getUpgradeCost(level)
					itemSurfaceGui.Label.Text = "Lv." .. level .. " -> " .. (level + 1) .. "\n(" .. formatNumber(upCost) .. ")"
					itemSurfaceGui.Enabled = true

					clickDetector.MaxActivationDistance = 32
			elseif canPlace then
				prompt.ActionText = "Place"
				prompt.ObjectText = "Empty Slot"
				touchPart.Color = Color3.fromRGB(255, 0, 0)
				billboard.Adornee = touchPart
				billboard.Enabled = false
				surfaceGui.Enabled = false
				itemSurfaceGui.Enabled = false
				clickDetector.MaxActivationDistance = 32
			else
				prompt.Enabled = false
				touchPart.Color = Color3.fromRGB(255, 0, 0)
				billboard.Adornee = touchPart
				billboard.Enabled = false
				surfaceGui.Enabled = false
				itemSurfaceGui.Enabled = false
				clickDetector.MaxActivationDistance = 0
			end
			end)
			if not success then
				warn("UI Update Error in setupSlot: " .. tostring(err))
			end
			task.wait(1)
		end
	end)

	-- 処理 (売却)
	sellPrompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player or promptDebounce then return end
		promptDebounce = true

		local success, err = pcall(function()
			local stored = placePart:FindFirstChild("StoredItem")
			local item = stored and stored.Value
			if not item then return end

			local level = placePart:GetAttribute("Level") or 1
			local price = getSellPrice(item.Name, level)

			local leaderstats = player:FindFirstChild("leaderstats")
			local coins = leaderstats and leaderstats:FindFirstChild("Coins")

			if coins then
				coins.Value = coins.Value + price
				item:Destroy()
				if stored then stored:Destroy() end
			end
		end)

		if not success then warn("Sell error: " .. tostring(err)) end
		promptDebounce = false
	end)

	-- 処理 (レベルアップ)
	clickDetector.MouseClick:Connect(function(triggerPlayer)
		if triggerPlayer ~= player or promptDebounce then return end
		promptDebounce = true

		local success, err = pcall(function()
			local stored = placePart:FindFirstChild("StoredItem")
			local item = stored and stored.Value
			if not item then return end

			local level = placePart:GetAttribute("Level") or 1
			local cost = getUpgradeCost(level)

			local leaderstats = player:FindFirstChild("leaderstats")
			local coins = leaderstats and leaderstats:FindFirstChild("Coins")

			if coins and coins.Value >= cost then
				coins.Value = coins.Value - cost
				placePart:SetAttribute("Level", level + 1)
			end
		end)

		if not success then warn("Level up error: " .. tostring(err)) end
		promptDebounce = false
	end)

	-- 処理 (配置/回収)
	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player or promptDebounce then return end
		promptDebounce = true

		local success, err = pcall(function()
			local character = player.Character
			if not character then return end

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

				local displayNameValue = Instance.new("StringValue", player)
				displayNameValue.Name = "TreasureDisplayName"
				displayNameValue.Value = item:GetAttribute("DisplayName") or item.Name

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
				if stored then stored:Destroy() end

			-- 設置
			elseif hasTreasure and (not stored or not stored.Value) then
				if stored then stored:Destroy() end

				local typeValue = player:FindFirstChild("TreasureType")
				if not typeValue then 
					warn("Placement failed: No TreasureType value on player")
					return 
				end

				local displayNameValue = player:FindFirstChild("TreasureDisplayName")
				local dName = displayNameValue and displayNameValue.Value or typeValue.Value

				local levelValue = player:FindFirstChild("TreasureLevel")
				local tLevel = levelValue and levelValue.Value or 1

				local template = treasureFolder:FindFirstChild(typeValue.Value)
				if not template then return end

				local item = template:Clone()
				item:SetAttribute("DisplayName", dName)
				item.Parent = base
				placePart:SetAttribute("Level", tLevel)
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
		end)

		if not success then warn("Placement/Recovery error: " .. tostring(err)) end
		promptDebounce = false
	end)
end

local function setVisible(obj, visible)
	if not obj then return end
	if obj:IsA("BasePart") then
		obj.Transparency = visible and 0 or 1
		obj.CanCollide = visible
		obj.CanQuery = visible
		obj.CanTouch = visible
	elseif obj:IsA("Model") then
		for _, child in ipairs(obj:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = visible and 0 or 1
				child.CanCollide = visible
				child.CanQuery = visible
				child.CanTouch = visible
			elseif child:IsA("ProximityPrompt") then
				child.Enabled = visible
			elseif child:IsA("LayerCollector") then -- BillboardGui, SurfaceGui
				child.Enabled = visible
			end
		end
	end
end

local function refreshBaseVisibility(base)
	local currentLevel = base:GetAttribute("BaseLevel") or 1
	
	local function updateFloorVisibility(floor, floorNum)
		local board = floor:FindFirstChild("Board")
		local stair = floor:FindFirstChild("Stair")
		
		-- Stair: 現在の階より上の階が存在する場合のみ表示
		setVisible(stair, floorNum < currentLevel)
		
		-- Board: 1階は常に表示
		local boardVisible = (floorNum == 1)
		setVisible(board, boardVisible)
	end

	-- 初期階
	updateFloorVisibility(base, 1)

	-- 追加階
	for i = 2, MAX_BASE_LEVEL do
		local floor = base:FindFirstChild("Floor" .. i)
		if floor then
			updateFloorVisibility(floor, i)
		end
	end
end

local function setupBoardUpgrade(player, base, board, floorLevel)
	local displayPart = board.PrimaryPart or board:FindFirstChildWhichIsA("BasePart")
	if not displayPart then return end

	local prompt = board:FindFirstChildWhichIsA("ProximityPrompt") or Instance.new("ProximityPrompt")
	prompt.ActionText = "Upgrade Base"
	prompt.KeyboardKeyCode = Enum.KeyCode.G
	prompt.Parent = displayPart

	local gui = board:FindFirstChild("UpgradeUI")
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "UpgradeUI"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.Parent = displayPart

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0.5, 0)
		label.Position = UDim2.new(0, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = gui
	end

	local function updateBoard()
		local level = base:GetAttribute("BaseLevel") or 1
		if level >= MAX_BASE_LEVEL then
			prompt.Enabled = false
			gui.Label.Text = "LEVEL MAX"
		else
			local cost = getBaseUpgradeCost(level + 1)
			prompt.ObjectText = "Level " .. (level + 1)
			gui.Label.Text = "Upgrade Base\n" .. formatNumber(cost) .. " Coins"
			prompt.Enabled = true
		end
	end

	base:GetAttributeChangedSignal("BaseLevel"):Connect(updateBoard)
	updateBoard()

	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer ~= player then return end
		local level = base:GetAttribute("BaseLevel") or 1
		if level >= MAX_BASE_LEVEL then return end

		local cost = getBaseUpgradeCost(level + 1)
		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")

		if coins and coins.Value >= cost then
			coins.Value = coins.Value - cost
			local nextLevel = level + 1
			base:SetAttribute("BaseLevel", nextLevel)

			local baseLevelStat = leaderstats:FindFirstChild("BaseLevel")
			if baseLevelStat then baseLevelStat.Value = nextLevel end

			-- 新しい階層を積み上げる
			local newFloor = baseTemplate:Clone()
			newFloor.Name = "Floor" .. nextLevel
			newFloor.Parent = base

			local floorHeight = 30
			newFloor:PivotTo(base.PrimaryPart.CFrame * CFrame.new(0, floorHeight * (nextLevel - 1), 0))

			local function setupFloorInternal(targetFloor, num)
				local basePart = targetFloor:FindFirstChild("Base")
				if basePart then
					for _, child in ipairs(basePart:GetChildren()) do
						if child:IsA("Model") then
							setupSlot(player, base, child)
						end
					end
				end
				local boardModel = targetFloor:FindFirstChild("Board")
				if boardModel then
					setupBoardUpgrade(player, base, boardModel, num)
				end
			end

			setupFloorInternal(newFloor, nextLevel)
			
			-- オーナー名タグを最新の階の頂上へ移動
			local ownerTag = base:FindFirstChild("OwnerTag")
			if ownerTag then
				ownerTag.Adornee = newFloor.PrimaryPart or newFloor:FindFirstChildWhichIsA("BasePart")
			end

			refreshBaseVisibility(base)
		end
	end)
end

local function setupFloor(player, base, floorModel, floorLevel)
	local basePart = floorModel:FindFirstChild("Base")
	if basePart then
		for _, child in ipairs(basePart:GetChildren()) do
			if child:IsA("Model") then
				setupSlot(player, base, child)
			end
		end
	end

	local board = floorModel:FindFirstChild("Board")
	if board then
		setupBoardUpgrade(player, base, board, floorLevel)
	end
end

-- =========================
-- Base生成
-- =========================
local function createBase(player)

	local old = workspace:FindFirstChild(player.Name .. "_Base")
	if old then old:Destroy() end

	local pos, slotIndex = assignSlot(player)

	if not pos then
		local success, result = pcall(function()
			return TeleportService:TeleportAsync(game.PlaceId, {player})
		end)
		if not success then
			warn("Teleport failed: " .. tostring(result))
			player:Kick("Server is full and teleport failed.")
		end
		return nil
	end

	local base = baseTemplate:Clone()
	base.Name = player.Name .. "_Base"
	base.Parent = workspace

	base.PrimaryPart = base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")
	base:SetAttribute("BaseLevel", 1)

	if base.PrimaryPart then
		base:PivotTo(goal.CFrame + pos)
	else
		base:MoveTo((goal.CFrame + pos).Position)
	end

	-- ユーザー名表示 (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OwnerTag"
	billboard.Size = UDim2.new(0, 150, 0, 45)
	billboard.StudsOffset = Vector3.new(0, 20, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")
	billboard.Parent = base

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = player.DisplayName .. "'s Base"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	refreshBaseVisibility(base)

	return base
end

-- =========================
-- Player
-- =========================
local function handlePlayer(player)
	local base = createBase(player)
	if not base then return end
	playerBases[player] = base

	setupFloor(player, base, base, 1)

	-- ロードされたレベルに合わせて階層を復元
	task.spawn(function()
		-- データのロード完了を待つ
		while not player:GetAttribute("DataLoaded") do
			task.wait(0.1)
		end

		local leaderstats = player:WaitForChild("leaderstats", 10)
		if not leaderstats then return end
		local baseLevelStat = leaderstats:WaitForChild("BaseLevel", 10)
		if not baseLevelStat then return end

		local targetLevel = baseLevelStat.Value
		for i = 2, targetLevel do
			local nextLevel = i

			local newFloor = baseTemplate:Clone()
			newFloor.Name = "Floor" .. nextLevel
			newFloor.Parent = base

			local floorHeight = 30
			newFloor:PivotTo(base.PrimaryPart.CFrame * CFrame.new(0, floorHeight * (nextLevel - 1), 0))

			setupFloor(player, base, newFloor, nextLevel)
			base:SetAttribute("BaseLevel", nextLevel)

			-- オーナー名タグを最新の階の頂上へ移動
			local ownerTag = base:FindFirstChild("OwnerTag")
			if ownerTag then
				ownerTag.Adornee = newFloor.PrimaryPart or newFloor:FindFirstChildWhichIsA("BasePart")
			end
		end
		refreshBaseVisibility(base)
	end)

	local function handleCharacter(character)
		clearTreasure(player, character)
		applySpeed(player, character)

		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not hrp then return end

		if base and base.PrimaryPart then
			character:PivotTo(base.PrimaryPart.CFrame * CFrame.new(0, 5, 0))
		end
	end

	player.CharacterAdded:Connect(handleCharacter)
	if player.Character then
		handleCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(handlePlayer)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayer, player)
end

Players.PlayerRemoving:Connect(function(player)

	releaseSlot(player)
	playerBases[player] = nil

	if speedConnections[player] then
		speedConnections[player]:Disconnect()
		speedConnections[player] = nil
	end
end)
