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

local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,220,0,70)
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -10, 0, 10)
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.TextColor3 = Color3.fromRGB(255,255,255)
label.TextWrapped = true
label.TextSize = 14
label.Font = Enum.Font.GothamBold
label.Parent = gui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Size = UDim2.new(0,220,0,40)
rebirthButton.AnchorPoint = Vector2.new(1, 0)
rebirthButton.Position = UDim2.new(1, -10, 0, 90)
rebirthButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextScaled = true
rebirthButton.Parent = gui

local function update()
	label.Text = "Rebirths: "..formatNumber(rebirths.Value).." | Coins: "..formatNumber(coins.Value).."\nSpeed: "..formatNumber(speed.Value).." | Jump: "..formatNumber(jump.Value)
	
	local cost = BASE_REBIRTH_COST * (COST_MULTIPLIER ^ rebirths.Value)
	rebirthButton.Text = "Rebirth (Cost: " .. formatNumber(cost) .. ")"
	
	if coins.Value >= cost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	end
end

rebirthButton.MouseButton1Click:Connect(function()
	local remote = ReplicatedStorage:FindFirstChild("RebirthEvent")
	if remote then
		remote:FireServer()
	end
end)

coins.Changed:Connect(update)
speed.Changed:Connect(update)
jump.Changed:Connect(update)
rebirths.Changed:Connect(update)

update()
