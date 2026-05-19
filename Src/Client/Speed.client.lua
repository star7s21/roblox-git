local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local formatNumber = Utils.formatNumber

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
