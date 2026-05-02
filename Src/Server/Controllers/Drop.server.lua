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
	local valueObj = player:FindFirstChild("TreasureValue")
	local typeObj = player:FindFirstChild("TreasureType")

	local value = valueObj and valueObj.Value or 0
	local typeName = typeObj and typeObj.Value or carried.Name

	-- =========================
	-- 新しく生成（←ここが核心）
	-- =========================
	local template = treasureFolder:FindFirstChild(typeName)
	if not template then return end

	local item = template:Clone()
	item:SetAttribute("Value", value)
	item.Parent = workspace

	item.PrimaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")

	if item.PrimaryPart then
		item:PivotTo(root.CFrame * CFrame.new(0, 0, -6))
	else
		item:MoveTo(root.Position + Vector3.new(0,0,-6))
	end

	-- =========================
	-- プレイヤー状態クリア
	-- =========================
	local tag = player:FindFirstChild("HasTreasure")
	if tag then tag:Destroy() end

	if valueObj then valueObj:Destroy() end
	if typeObj then typeObj:Destroy() end

	carried:Destroy()

	-- =========================
	-- 拾える状態にする
	-- =========================
	TreasureModule.setupTreasure(item)

	print("DROP成功:", typeName, value)
end)