local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreasureTranslation = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreasureTranslation"))
local player = Players.LocalPlayer

local function checkPrompt(prompt)
	if not prompt:GetAttribute("OriginalActionText") then
		prompt:SetAttribute("OriginalActionText", prompt.ActionText)
	end
	if not prompt:GetAttribute("OriginalObjectText") then
		prompt:SetAttribute("OriginalObjectText", prompt.ObjectText)
	end

	local localeId = player.LocaleId

	local origAction = prompt:GetAttribute("OriginalActionText")
	if origAction and origAction ~= "" then
		prompt.ActionText = TreasureTranslation.Translate(origAction, localeId)
	end

	local origObject = prompt:GetAttribute("OriginalObjectText")
	if origObject and origObject ~= "" then
		-- "Bear (150)" のような数値付き表示に対応するため、括弧で分割して名前のみを翻訳する
		local nameOnly, extra = string.match(origObject, "^([^(]+)%s*(%(.*%))$")
		if nameOnly and extra then
			-- 左右のスペースを除去
			nameOnly = string.gsub(nameOnly, "^%s*(.-)%s*$", "%1")
			local transName = TreasureTranslation.Translate(nameOnly, localeId)
			prompt.ObjectText = transName .. " " .. extra
		else
			prompt.ObjectText = TreasureTranslation.Translate(origObject, localeId)
		end
	end

	if origAction == "Pick Up" and player:FindFirstChild("HasTreasure") then
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

ProximityPromptService.PromptShown:Connect(checkPrompt)
