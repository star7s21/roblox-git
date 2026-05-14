local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function checkPrompt(prompt)
	if prompt.ActionText == "Pick Up" then
		if player:FindFirstChild("HasTreasure") then
			prompt.Enabled = false
			
			-- お宝を離した時に再有効化するための監視
			task.spawn(function()
				while player:FindFirstChild("HasTreasure") do
					task.wait(0.5)
				end
				prompt.Enabled = true
			end)
		end
	end
end

ProximityPromptService.PromptShown:Connect(checkPrompt)
