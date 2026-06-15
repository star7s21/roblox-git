local BaseUpgradeService = {}

BaseUpgradeService.MAX_BASE_LEVEL = 4

local function setVisible(obj, visible)
	if not obj then return end
	if obj:IsA("BasePart") then
		obj.Transparency = visible and 0 or 1
		obj.CanCollide = visible
		obj.CanQuery = visible
		obj.CanTouch = visible
	elseif obj:IsA("Model") then
		for _, child in ipairs(obj:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = visible and 0 or 1
				child.CanCollide = visible
				child.CanQuery = visible
				child.CanTouch = visible
			elseif child:IsA("ProximityPrompt") then
				if not visible then
					child.Enabled = false
				end
			elseif child:IsA("LayerCollector") then -- BillboardGui, SurfaceGui
				child.Enabled = visible
			end
		end
	end
end

function BaseUpgradeService.refreshBaseVisibility(base)
	local currentLevel = base:GetAttribute("BaseLevel") or 1
	
	local function updateFloorVisibility(floor, floorNum)
		local board = floor:FindFirstChild("Board")
		local stair = floor:FindFirstChild("Stair")
		
		-- Stair: 現在の階より上の階が存在する場合のみ表示
		setVisible(stair, floorNum < currentLevel)
		
		-- Board: 1階は常に表示
		local boardVisible = (floorNum == 1)
		setVisible(board, boardVisible)
	end

	-- 初期階
	updateFloorVisibility(base, 1)

	-- 追加階
	for i = 2, BaseUpgradeService.MAX_BASE_LEVEL do
		local floor = base:FindFirstChild("Floor" .. i)
		if floor then
			updateFloorVisibility(floor, i)
		end
	end
end

function BaseUpgradeService.getBaseUpgradeCost(level)
	return math.floor(10000 * (4 ^ (level - 1)))
end

return BaseUpgradeService
