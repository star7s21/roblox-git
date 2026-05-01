local module = {}

function module.setupTreasure(treasure)

	local picked = false

	for _, part in ipairs(treasure:GetDescendants()) do
		if part:IsA("BasePart") then

			part.Touched:Connect(function(hit)

				if picked then return end

				local player = game.Players:GetPlayerFromCharacter(hit.Parent)
				if not player then return end

				if player:FindFirstChild("HasTreasure") then return end

				picked = true

				-- =========================
				-- 価値取得（修正ポイント）
				-- =========================
				local value = 0

				local coinValue = treasure:FindFirstChild("CoinValue")
				if coinValue then
					value = coinValue.Value
				else
					value = treasure:GetAttribute("Value") or 0
				end

				-- =========================
				-- タグ
				-- =========================
				local tag = Instance.new("BoolValue")
				tag.Name = "HasTreasure"
				tag.Parent = player

				local storedValue = Instance.new("IntValue")
				storedValue.Name = "TreasureValue"
				storedValue.Value = value
				storedValue.Parent = player

				local typeValue = Instance.new("StringValue")
				typeValue.Name = "TreasureType"
				typeValue.Value = treasure.Name
				typeValue.Parent = player

				print(player.Name .. " picked " .. typeValue.Value)

				-- =========================
				-- 見た目
				-- =========================
				local character = hit.Parent
				local head = character:FindFirstChild("Head")

				if head then
					local clone = treasure:Clone()
					clone.Name = "CarriedTreasure"
					clone.Parent = character

					if not clone.PrimaryPart then
						local root = clone:FindFirstChildWhichIsA("BasePart")
						if root then
							clone.PrimaryPart = root
						end
					end

					for _, p in ipairs(clone:GetDescendants()) do
						if p:IsA("BasePart") then
							p.Anchored = false
							p.CanCollide = false
							p.Massless = true
						end
					end

					if clone.PrimaryPart then
						for _, p in ipairs(clone:GetDescendants()) do
							if p:IsA("BasePart") and p ~= clone.PrimaryPart then
								local weld = Instance.new("WeldConstraint")
								weld.Part0 = clone.PrimaryPart
								weld.Part1 = p
								weld.Parent = p
							end
						end

						clone:PivotTo(head.CFrame * CFrame.new(0, 2, 2))

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = clone.PrimaryPart
						weld.Part1 = head
						weld.Parent = clone.PrimaryPart
					end
				end

				-- 元削除
				treasure:Destroy()
			end)
		end
	end
end

return module