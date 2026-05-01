local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local goal = workspace:WaitForChild("StartArea")
local baseTemplate = ServerStorage:WaitForChild("BaseModel")
local treasureFolder = ReplicatedStorage:WaitForChild("Treasures")

-- =========================
-- コイン生成
-- =========================
local function startGenerating(player, item)
	task.spawn(function()
		while item and item.Parent do
			task.wait(5)

			local value = item:GetAttribute("Value")
			if not value then break end

			local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value += value
			end
		end
	end)
end

-- =========================
-- プレイヤーごと基地生成
-- =========================
Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(char)

		task.wait(1)

		local base = baseTemplate:Clone()
		base.Name = player.Name .. "_Base"
		base.Parent = workspace
		base:PivotTo(goal.CFrame * CFrame.new(0, 10, 0))

		local slots = base:WaitForChild("Base")

		for _, slot in ipairs(slots:GetChildren()) do
			if not slot:IsA("Model") then continue end

			local touchPart = slot:FindFirstChild("TouchArea")
			local placePart = slot:FindFirstChild("ItemArea")
			if not touchPart or not placePart then continue end

			local debounce = false

			touchPart.Touched:Connect(function(hit)
				if debounce then return end

				local character = hit.Parent
				local toucher = Players:GetPlayerFromCharacter(character)
				if toucher ~= player then return end

				-- =========================
				-- 回収処理
				-- =========================
				local stored = placePart:FindFirstChild("StoredItem")

				if stored and stored.Value then

					debounce = true

					local item = stored.Value
					if not item then
						debounce = false
						return
					end

					-- プレイヤーに付与
					local tag = Instance.new("BoolValue")
					tag.Name = "HasTreasure"
					tag.Parent = player

					local value = Instance.new("IntValue")
					value.Name = "TreasureValue"
					value.Value = item:GetAttribute("Value") or 0
					value.Parent = player

					local typeValue = Instance.new("StringValue")
					typeValue.Name = "TreasureType"
					typeValue.Value = item.Name
					typeValue.Parent = player

					-- 見た目（持つ）
					local head = character:FindFirstChild("Head")
					if head then
						local template = treasureFolder:FindFirstChild(item.Name)
						if template then
							local clone = template:Clone()
							clone.Name = "CarriedTreasure"
							clone.Parent = character

							if not clone.PrimaryPart then
								local p = clone:FindFirstChildWhichIsA("BasePart")
								if p then clone.PrimaryPart = p end
							end

							for _, p in ipairs(clone:GetDescendants()) do
								if p:IsA("BasePart") then
									p.Anchored = false
									p.CanCollide = false
									p.Massless = true
								end
							end

							if clone.PrimaryPart then
								clone:PivotTo(head.CFrame * CFrame.new(0, 2, 2))

								local weld = Instance.new("WeldConstraint")
								weld.Part0 = clone.PrimaryPart
								weld.Part1 = head
								weld.Parent = clone.PrimaryPart
							end
						end
					end

					-- 生成停止
					item:Destroy()

					-- スロット初期化
					stored:Destroy()

					task.delay(0.5, function()
						debounce = false
					end)

					return
				end

				-- =========================
				-- 設置処理
				-- =========================
				local hasTreasure = player:FindFirstChild("HasTreasure")
				if not hasTreasure then return end

				local value = player:FindFirstChild("TreasureValue")
				local typeValue = player:FindFirstChild("TreasureType")
				if not value or not typeValue then return end

				if placePart:FindFirstChild("StoredItem") then return end

				debounce = true

				local template = treasureFolder:FindFirstChild(typeValue.Value)
				if not template then
					warn("Treasure not found:", typeValue.Value)
					debounce = false
					return
				end

				local item = template:Clone()
				item.Parent = base

				if item.PrimaryPart then
					item:PivotTo(placePart.CFrame)
				else
					item:MoveTo(placePart.Position)
				end

				item:SetAttribute("Value", value.Value)

				local storedItem = Instance.new("ObjectValue")
				storedItem.Name = "StoredItem"
				storedItem.Value = item
				storedItem.Parent = placePart

				startGenerating(player, item)

				-- プレイヤー状態リセット
				hasTreasure:Destroy()
				value:Destroy()
				typeValue:Destroy()

				local carried = character:FindFirstChild("CarriedTreasure")
				if carried then carried:Destroy() end

				task.delay(0.5, function()
					debounce = false
				end)
			end)
		end
	end)
end)