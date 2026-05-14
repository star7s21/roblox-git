local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

ProximityPromptService.PromptShown:Connect(function(prompt)
	-- 「Pick Up」というアクション名のUIを表示しようとした時
	if prompt.ActionText == "Pick Up" then
		-- 既にお宝を持っているなら表示を無効化する
		if player:FindFirstChild("HasTreasure") then
			prompt.Enabled = false
		end
	end
end)
