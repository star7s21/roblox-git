local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage:WaitForChild("AdminUpdateStat")

-- 管理者のUserIdリスト（ここに自分のIDを追加してください）
local ADMIN_IDS = {1, 23456789} 

local function isAdmin(player)
	return table.find(ADMIN_IDS, player.UserId) ~= nil
end

remoteEvent.OnServerEvent:Connect(function(player, statName, increment)
	if not isAdmin(player) then
		warn("Unauthorized admin access attempt:", player.Name)
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		-- UpgradeCostなどはplayer直下にある場合がある
		stat = player:FindFirstChild(statName)
	end

	if stat and stat:IsA("IntValue") or stat:IsA("NumberValue") then
		stat.Value = stat.Value + increment
		print("Admin Updated:", player.Name, statName, "to", stat.Value)
	end
end)
