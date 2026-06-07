local remote = game.ReplicatedStorage:WaitForChild("DropTreasureEvent")

local TreasureModule = require(game.ServerScriptService.Server.Services.Treasure)
local treasureFolder = game.ReplicatedStorage:WaitForChild("Treasures")

remote.OnServerEvent:Connect(function(player)

	local char = player.Character
	if not char then return end

	local carried = char:FindFirstChild("CarriedTreasure")
	if not carried then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- =========================
	-- データ取得
	-- =========================
	local typeObj = player:FindFirstChild("TreasureType")
	local typeName = typeObj and typeObj.Value or carried.Name

	-- =========================
	-- 新しく生成（←ここが核心）
	-- =========================
	local template = treasureFolder:FindFirstChild(typeName)
	if not template then return end

	local levelObj = player:FindFirstChild("TreasureLevel")
	local level = levelObj and levelObj.Value or 1

	local item = template:Clone()
	item.Parent = workspace

	item:SetAttribute("Level", level)
	item.PrimaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")

	local spawnPos = root.Position + Vector3.new(0, 0, -10)
	if item.PrimaryPart then
		spawnPos = (root.CFrame * CFrame.new(0, 0, -10)).Position
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {char, item}
	local raycastResult = workspace:Raycast(spawnPos + Vector3.new(0, 5, 0), Vector3.new(0, -1000, 0), raycastParams)
	local groundPos = raycastResult and raycastResult.Position or Vector3.new(spawnPos.X, 0, spawnPos.Z)

	local offset = Vector3.new(0, 0, 0)
	if item.PrimaryPart then
		local size = item:GetExtentsSize()
		offset = Vector3.new(0, size.Y / 2, 0)
	end

	if item.PrimaryPart then
		item:PivotTo(CFrame.new(groundPos + offset))
	else
		item:MoveTo(groundPos)
	end

	-- 拾える状態にする（プレイヤー状態クリアより前に実行）
	TreasureModule.setupTreasure(item)

	-- =========================
	-- プレイヤー状態クリア
	-- =========================
	local tag = player:FindFirstChild("HasTreasure")
	if tag then tag:Destroy() end

	if typeObj then typeObj:Destroy() end

	carried:Destroy()

	print("DROP成功:", typeName, value)
end)
