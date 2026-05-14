local ProximityPromptService = game:GetService("ProximityPromptService")
local player = game.Players.LocalPlayer

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

local function updatePrompt(prompt)
	local costValue = player:FindFirstChild("UpgradeCost")
	local cost = costValue and costValue.Value or 50
	prompt.ObjectText = "Cost: " .. formatNumber(cost)
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Parent and prompt.Parent.Name == "SpeedUpgrade" then
		updatePrompt(prompt)
	end
end)

-- コスト変更時は「表示中のpromptだけ更新」
local costValue = player:WaitForChild("UpgradeCost")

costValue:GetPropertyChangedSignal("Value"):Connect(function()
	local prompt = workspace.SpeedUpgrade:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		updatePrompt(prompt)
	end
end)
