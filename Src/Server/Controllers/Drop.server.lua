local remote = game.ReplicatedStorage:WaitForChild("DropTreasureEvent")

remote.OnServerEvent:Connect(function(player)

	local char = player.Character
	if not char then return end

	local item = char:FindFirstChild("CarriedTreasure")
	if not item then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- =========================
	-- 先に値を取得
	-- =========================
	local valueObj = player:FindFirstChild("TreasureValue")
	local typeObj = player:FindFirstChild("TreasureType")

	local value = valueObj and valueObj.Value or 0
	local typeName = typeObj and typeObj.Value or item.Name

	-- Valueを戻す
	item:SetAttribute("Value", value)
	item.Name = typeName -- 念のため統一

	-- =========================
	-- タグ削除
	-- =========================
	local tag = player:FindFirstChild("HasTreasure")
	if tag then tag:Destroy() end

	if valueObj then valueObj:Destroy() end
	if typeObj then typeObj:Destroy() end

	-- =========================
	-- Weld削除
	-- =========================
	for _, v in ipairs(item:GetDescendants()) do
		if v:IsA("WeldConstraint") then
			v:Destroy()
		end
	end

	-- =========================
	-- 物理戻す
	-- =========================
	for _, p in ipairs(item:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = true
			p.Massless = false
		end
	end

	-- =========================
	-- PrimaryPart補正
	-- =========================
	if item:IsA("Model") and not item.PrimaryPart then
		local p = item:FindFirstChildWhichIsA("BasePart")
		if p then item.PrimaryPart = p end
	end

	-- =========================
	-- ワールドへ
	-- =========================
	item.Parent = workspace

	if item:IsA("Model") and item.PrimaryPart then
		item:PivotTo(root.CFrame * CFrame.new(0, 0, -6))
	else
		item:MoveTo(root.Position + Vector3.new(0,0,-6))
	end

	-- =========================
	-- 再取得可能にする
	-- =========================
	local TreasureModule = require(game.ServerScriptService.Server.Services.Treasure)
	TreasureModule.setupTreasure(item)

	print("DROP成功:", typeName, value)
end)