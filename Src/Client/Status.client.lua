local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local formatNumber = Utils.formatNumber
local leaderstats = player:WaitForChild("leaderstats")

local coins = leaderstats:WaitForChild("Coins")
local speed = leaderstats:WaitForChild("Speed")
local jump = leaderstats:WaitForChild("Jump")
local rebirths = leaderstats:WaitForChild("Rebirths")

local BASE_REBIRTH_COST = 1000
local COST_MULTIPLIER = 2

local toggleSpeedRemote = ReplicatedStorage:WaitForChild("ToggleSpeedLimit", 10)
local toggleJumpRemote = ReplicatedStorage:WaitForChild("ToggleJumpLimit", 10)
local rebirthRemote = ReplicatedStorage:FindFirstChild("RebirthEvent")

local playerGui = player:WaitForChild("PlayerGui")
local menuUi = playerGui:WaitForChild("MenuUI")
local frame = menuUi:WaitForChild("Frame")

local coinText = frame:WaitForChild("CoinText")
local jumpButton = frame:WaitForChild("JumpButton")
local speedButton = frame:WaitForChild("SpeedButton")
local rebirthButton = frame:WaitForChild("RebirthButton")

local jumpText = jumpButton:WaitForChild("Text")
local speedText = speedButton:WaitForChild("Text")
local rebirthText = rebirthButton:WaitForChild("Text")

local isSpeedLimited = false
local isJumpLimited = false

local function update()
	coinText.Text = "Coins: " .. formatNumber(coins.Value)
	
	local cost = BASE_REBIRTH_COST * (COST_MULTIPLIER ^ rebirths.Value)
	rebirthText.Text = "Rebirths: " .. formatNumber(rebirths.Value) .. "\n(Coins: " .. formatNumber(cost) .. ")"
	
	if coins.Value >= cost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	end

	speedText.Text = "Speed: " .. formatNumber(speed.Value) .. "\nLimit: " .. (isSpeedLimited and "ON" or "OFF")
	if isSpeedLimited then
		speedButton.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
	else
		speedButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	end

	jumpText.Text = "Jump: " .. formatNumber(jump.Value) .. "\nLimit: " .. (isJumpLimited and "ON" or "OFF")
	if isJumpLimited then
		jumpButton.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
	else
		jumpButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	end
end

rebirthButton.MouseButton1Click:Connect(function()
	if rebirthRemote then
		rebirthRemote:FireServer()
	end
end)

local function sendSpeedUpdate()
	if toggleSpeedRemote then
		toggleSpeedRemote:FireServer(isSpeedLimited)
	end
end

local function sendJumpUpdate()
	if toggleJumpRemote then
		toggleJumpRemote:FireServer(isJumpLimited)
	end
end

speedButton.MouseButton1Click:Connect(function()
	isSpeedLimited = not isSpeedLimited
	sendSpeedUpdate()
	update()
end)

jumpButton.MouseButton1Click:Connect(function()
	isJumpLimited = not isJumpLimited
	sendJumpUpdate()
	update()
end)

coins.Changed:Connect(update)
speed.Changed:Connect(update)
jump.Changed:Connect(update)
rebirths.Changed:Connect(update)

-- 初回およびリスポーン時の同期
frame.Visible = true
sendSpeedUpdate()
sendJumpUpdate()
update()

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	sendSpeedUpdate()
	sendJumpUpdate()
end)
