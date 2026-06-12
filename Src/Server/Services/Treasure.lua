local TreasureConfig = require(script.Parent.TreasureConfig)

local module = {}

function module.setupTreasure(treasure)
	local primary = (treasure:IsA("BasePart") and treasure) or treasure.PrimaryPart or treasure:FindFirstChildWhichIsA("BasePart")
	if not primary then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "PromptAttachment"
	attachment.Parent = primary

	local modelName = treasure:GetAttribute("Model") or treasure.Name
	local displayName = TreasureConfig.GetDisplayName(modelName)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = displayName
	prompt.HoldDuration = 1.0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 15
	prompt.Parent = attachment

	prompt.Triggered:Connect(function(player)
		-- 多重防止（重要）
		if treasure:GetAttribute("Picked") then return end
		if player:FindFirstChild("HasTreasure") then return end

		local level = treasure:GetAttribute("Level") or 1

		-- 状態
		local tag = Instance.new("BoolValue")
		tag.Name = "HasTreasure"
		tag.Parent = player

		-- Picked属性をtrueにする（他のプレイヤーが拾えないようにする）
		treasure:SetAttribute("Picked", true)

		local storedValue = Instance.new("IntValue")
		storedValue.Name = "TreasureLevel"
		storedValue.Value = level
		storedValue.Parent = player

		local typeValue = Instance.new("StringValue")
		typeValue.Name = "TreasureType"
		typeValue.Value = treasure:GetAttribute("Model") or treasure.Name
		typeValue.Parent = player

		local displayNameValue = Instance.new("StringValue")
		displayNameValue.Name = "TreasureDisplayName"
		displayNameValue.Value = TreasureConfig.GetLocalizedDisplayName(treasure:GetAttribute("Model") or treasure.Name, player)
		displayNameValue.Parent = player

		-- 見た目
		local character = player.Character
		local head = character and character:FindFirstChild("Head")

		if head then
			local clone = treasure:Clone()
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
				clone:PivotTo(head.CFrame * CFrame.new(0,2,2))

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = clone.PrimaryPart
				weld.Part1 = head
				weld.Parent = clone.PrimaryPart
			end
		end

		treasure:Destroy()
	end)
end

return module
