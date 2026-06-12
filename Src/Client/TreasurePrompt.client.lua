local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreasureTranslation = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreasureTranslation"))
local player = Players.LocalPlayer

local function checkPrompt(prompt)
	if prompt.ActionText == "Pick Up" or prompt:GetAttribute("OriginalActionText") == "Pick Up" then
		if not prompt:GetAttribute("OriginalActionText") then
			prompt:SetAttribute("OriginalActionText", prompt.ActionText)
			prompt:SetAttribute("OriginalObjectText", prompt.ObjectText)
		end

		local localeId = player.LocaleId
		prompt.ActionText = TreasureTranslation.Translate(prompt:GetAttribute("OriginalActionText"), localeId)
		if prompt:GetAttribute("OriginalObjectText") and prompt:GetAttribute("OriginalObjectText") ~= "" then
			prompt.ObjectText = TreasureTranslation.Translate(prompt:GetAttribute("OriginalObjectText"), localeId)
		end

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
