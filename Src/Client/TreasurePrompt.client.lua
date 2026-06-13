local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreasureTranslation = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreasureTranslation"))
local player = Players.LocalPlayer

local function translateTextLabel(label)
	if not label:GetAttribute("OriginalText") then
		label:SetAttribute("OriginalText", label.Text)
	end
	local origText = label:GetAttribute("OriginalText")
	if origText and origText ~= "" then
		local localeId = player.LocaleId
		-- カッコ付き表示 (例: "Bear (Lvl 1)") に対応
		local nameOnly, extra = string.match(origText, "^([^(]+)%s*(%(.*%))$")
		if nameOnly and extra then
			nameOnly = string.gsub(nameOnly, "^%s*(.-)%s*$", "%1")
			local transName = TreasureTranslation.Translate(nameOnly, localeId)
			label.Text = transName .. " " .. extra
		else
			-- 前後のスペースを除去して翻訳
			local cleanText = string.gsub(origText, "^%s*(.-)%s*$", "%1")
			label.Text = TreasureTranslation.Translate(cleanText, localeId)
		end
	end
end

local function checkAndTranslateGui(descendant)
	if descendant:IsA("TextLabel") then
		if descendant:FindFirstAncestorOfClass("BillboardGui") or descendant:FindFirstAncestorOfClass("SurfaceGui") then
			translateTextLabel(descendant)
			descendant:GetPropertyChangedSignal("Text"):Connect(function()
				translateTextLabel(descendant)
			end)
		end
	end
end

-- 既存のテキストラベルをすべて翻訳
for _, desc in ipairs(workspace:GetDescendants()) do
	checkAndTranslateGui(desc)
end

-- 新しく追加されたテキストラベルを翻訳
workspace.DescendantAdded:Connect(checkAndTranslateGui)

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
