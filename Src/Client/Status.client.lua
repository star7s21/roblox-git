local player = game.Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")

local coins = leaderstats:WaitForChild("Coins")
local speed = leaderstats:WaitForChild("Speed")
local rebirths = leaderstats:WaitForChild("Rebirths")

local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,200,0,50)
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -10, 0, 10)
label.BackgroundColor3 = Color3.fromRGB(0,0,0)
label.TextColor3 = Color3.fromRGB(255,255,255)
label.Parent = gui

local function update()
	label.Text = "Rebirths: "..rebirths.Value.." | Coins: "..coins.Value.." | Speed: "..speed.Value
end

coins.Changed:Connect(update)
speed.Changed:Connect(update)
rebirths.Changed:Connect(update)

update()
