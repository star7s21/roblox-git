local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage:WaitForChild("AdminUpdateStat")
local Players = game:GetService("Players")

-- 管理者のUserIdリスト
local ADMIN_IDS = {
	3994115949,
	10688061205
}

local ALLOWED_STATS = {
	Coins = true,
	Rebirths = true,
	Speed = true,
	Jump = true,
	BaseLevel = true,
}

local STAT_LIMITS = {
	Coins = {
		min = 0,
		max = 999999999999999999
	},

	Rebirths = {
		min = 0,
		max = 9999
	},

	Speed = {
		min = 16,
		max = 500
	},

	Jump = {
		min = 50,
		max = 1000
	},

	BaseLevel = {
		min = 1,
		max = 4
	},

	CarryLevel = {
		min = 1,
		max = 5
	},

	CarryCost = {
		min = 0,
		max = 999999999999999999
	}
}

local function isAdmin(player)
	return table.find(ADMIN_IDS, player.UserId) ~= nil
end

remoteEvent.OnServerEvent:Connect(function(player, statName, increment)
	if not isAdmin(player) then
		warn("Unauthorized admin access attempt:", player.Name)
		return
	end

	if not ALLOWED_STATS[statName] then
		warn("Invalid stat edit attempt:", statName)
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		stat = player:FindFirstChild(statName)
	end

	if stat and (stat:IsA("IntValue") or stat:IsA("NumberValue")) then

		local limits = STAT_LIMITS[statName]

		local newValue = stat.Value + increment

		if limits then
			newValue = math.clamp(
				newValue,
				limits.min,
				limits.max
			)
		end

		stat.Value = newValue

		print("Admin Updated:", player.Name, statName, "to", stat.Value)
	end
end)

Players.PlayerAdded:Connect(function(player)
	if isAdmin(player) then
		player:SetAttribute("IsAdmin", true)
	end
end)
