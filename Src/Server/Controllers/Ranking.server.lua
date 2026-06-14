local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local coinRankingStore = DataStoreService:GetOrderedDataStore("CoinRankingStore_v1")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local formatNumber = Utils.formatNumber

-- =========================
-- ランキング表示処理（RankingCoin）
-- =========================
task.spawn(function()
	local rankingModel = workspace:WaitForChild("RankingCoin", 10)
	if not rankingModel then
		warn("RankingCoin model not found")
		return
	end
	local scoreBlock = rankingModel:WaitForChild("ScoreBlock", 10)
	if not scoreBlock then
		warn("ScoreBlock not found in RankingCoin")
		return
	end

	-- SurfaceGui のセットアップ
	local surfaceGui = scoreBlock:FindFirstChild("RankingGui")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "RankingGui"
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.CanvasSize = Vector2.new(800, 600)
		surfaceGui.Adornee = scoreBlock
		surfaceGui.Parent = scoreBlock
	end

	local textLabel = surfaceGui:FindFirstChild("RankingText")
	if not textLabel then
		textLabel = Instance.new("TextLabel")
		textLabel.Name = "RankingText"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 40
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.RichText = true
		textLabel.Parent = surfaceGui
	end

	while true do
		local success, pages = pcall(function()
			return coinRankingStore:GetSortedAsync(false, 10)
		end)

		if success and pages then
			local chunk = pages:GetCurrentPage()
			local displayText = "<font color='#FFD700' size='36'><b>★ COIN RANKING ★</b></font>\n"

			for rank, data in ipairs(chunk) do
				local userId = tonumber(data.key)
				local score = data.value
				local name = "Unknown"

				if userId then
					local nameSuccess, result = pcall(function()
						return Players:GetNameFromUserIdAsync(userId)
					end)
					if nameSuccess then
						name = result
					else
						name = "ID: " .. tostring(userId)
					end
				end

				displayText = displayText .. string.format("\n%d. %s - %s Coins", rank, name, formatNumber(score))
			end

			if #chunk == 0 then
				displayText = displayText .. "\nNo ranking data yet."
			end

			textLabel.Text = displayText
		else
			warn("Failed to load ranking data from OrderedDataStore")
		end

		task.wait(60) -- 60秒毎にランキングを更新
	end
end)
