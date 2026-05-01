local player = game.Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("DropTreasureEvent")

local gui = player:WaitForChild("PlayerGui"):WaitForChild("DropUI")
local frame = gui:WaitForChild("Frame")
local button = frame.DropButton
local bar = frame.Progress.Bar

frame.Visible = false

-- =========================
-- 🎒 持ってるか判定
-- =========================
local function isHolding()
	local char = player.Character
	if not char then return false end

	return char:FindFirstChild("CarriedTreasure") ~= nil
end

-- UI表示管理
task.spawn(function()
	while true do
		task.wait(0.3)
		frame.Visible = isHolding()
	end
end)

-- =========================
-- ⏳ 長押し処理
-- =========================
local holdTime = 1
local holding = false

button.MouseButton1Down:Connect(function()
	if not isHolding() then return end

	holding = true
	bar.Size = UDim2.new(0,0,1,0)

	local start = tick()

	while holding do
		local elapsed = tick() - start
		local progress = math.clamp(elapsed / holdTime, 0, 1)

		bar.Size = UDim2.new(progress,0,1,0)

		if progress >= 1 then
			remote:FireServer()
			break
		end

		task.wait()
	end

	bar.Size = UDim2.new(0,0,1,0)
end)

button.MouseButton1Up:Connect(function()
	holding = false
end)