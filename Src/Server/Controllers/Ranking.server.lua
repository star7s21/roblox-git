local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local coinRankingStore = DataStoreService:GetOrderedDataStore("CoinRankingStore_v1")

-- =========================
-- ランキング表示処理（RankingCoin）
-- =========================
task.spawn(function()
	local rankingCoin = workspace:WaitForChild("RankingCoin", 10)
	if not rankingCoin then
		warn("RankingCoin not found in Workspace")
		return
	end

	-- SurfaceGui のセットアップ
	local surfaceGui = rankingCoin:FindFirstChild("RankingGui")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "RankingGui"
		surfaceGui.Face = Enum.NormalId.Front -- 前面に表示
		surfaceGui.CanvasSize = Vector2.new(800, 600)
		surfaceGui.Parent = rankingCoin
	end

	local textLabel = surfaceGui:FindFirstChild("RankingText")
	if not textLabel then
		textLabel = Instance.new("TextLabel")
		textLabel.Name = "RankingText"
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 24
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.TextXAlignment = Enum.TextXAlignment.Center
		textLabel.TextYAlignment = Enum.TextYAlignment.Center
		textLabel.RichText = true
		textLabel.Parent = surfaceGui
	end

	while true do
		local success, pages = pcall(function()
			return coinRankingStore:GetSortedAsync(false, 10)
		end)

		if success and pages then
			local chunk = pages:GetCurrentPage()
			local displayText = "<font color='#FFD700' size='36'><b>★ COIN RANKING ★</b></font>\n\n"

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

				displayText = displayText .. string.format("%d. %s - %s Coins\n", rank, name, tostring(score))
			end

			if #chunk == 0 then
				displayText = displayText .. "No ranking data yet."
			end

			textLabel.Text = displayText
		else
			warn("Failed to load ranking data from OrderedDataStore")
		end

		task.wait(60) -- 60秒毎にランキングを更新
	end
end)
