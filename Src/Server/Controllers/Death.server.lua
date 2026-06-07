local TreasureModule = require(game.ServerScriptService.Server.Services.Treasure)
local treasureFolder = game.ReplicatedStorage:WaitForChild("Treasures")

game.Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(character)

		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()

			local carried = character:FindFirstChild("CarriedTreasure")
			if not carried then return end

			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then return end

			-- データ取得
			local valueObj = player:FindFirstChild("TreasureValue")
			local typeObj = player:FindFirstChild("TreasureType")

			local value = valueObj and valueObj.Value or 0
			local typeName = typeObj and typeObj.Value or carried.Name

			-- 新規生成（←重要）
			local template = treasureFolder:FindFirstChild(typeName)
			if not template then return end

			local item = template:Clone()
			item:SetAttribute("Value", value)
			item.Parent = workspace

			item.PrimaryPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")

			local spawnPos = root.Position + Vector3.new(0, 0, -5)
			if item.PrimaryPart then
				spawnPos = (root.CFrame * CFrame.new(0, 0, -5)).Position
			end

			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {character, item}
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

			-- 再取得可能にする（プレイヤー状態クリアより前に実行）
			TreasureModule.setupTreasure(item)

			-- プレイヤー状態クリア（完全）
			for _, name in ipairs({"HasTreasure","TreasureValue","TreasureType"}) do
				local v = player:FindFirstChild(name)
				if v then v:Destroy() end
			end

			carried:Destroy()

			print("死亡ドロップ:", typeName, value)
		end)

	end)

end)
