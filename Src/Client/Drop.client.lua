local player = game.Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("DropTreasureEvent")

local gui = player:WaitForChild("PlayerGui"):WaitForChild("DropUI")
local frame = gui.Frame
local button = frame.DropButton

local function isHolding()
	return player:FindFirstChild("HasTreasure") ~= nil
end

-- 表示制御
task.spawn(function()
	while true do
		task.wait(0.2)
		frame.Visible = isHolding()
	end
end)

-- クリックで即ドロップ
button.MouseButton1Click:Connect(function()
	if not isHolding() then return end
	remote:FireServer()
end)