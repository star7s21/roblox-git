local SlotManager = {}

local SPACING = 70
-- CarryConfig から最大スロット数を取得
local CarryConfig = require(game:GetService("ReplicatedStorage").Shared.CarryConfig) -- パスは環境に合わせて調整してください
local MAX_SLOTS = CarryConfig.MaxCarrySlots -- CarryConfigから最大スロット数を取得
local used = {}

function SlotManager.assignSlot(player)
	for i = 1, MAX_SLOTS do
		if not used[i] then
			used[i] = player.UserId

			local offsetIndex = i - 1
			local direction = (offsetIndex % 2 == 0) and 1 or -1
			local step = math.ceil(offsetIndex / 2)

			local x = step * SPACING * direction
			return Vector3.new(x, 7.5, 0), i
		end
	end

	warn("Server full!")
	return nil, nil
end

function SlotManager.releaseSlot(player)
	for i, id in pairs(used) do
		if id == player.UserId then
			used[i] = nil
		end
	end
end

return SlotManager
