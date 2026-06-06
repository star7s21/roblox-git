local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local formatNumber = Utils.formatNumber

local function updatePrompt(prompt)
	local costValue = player:FindFirstChild("UpgradeCost")
	local cost = costValue and costValue.Value or 50
	prompt.ObjectText = "Cost: " .. formatNumber(cost)
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Parent and prompt.Parent.Name == "SpeedUpgrade" then
		updatePrompt(prompt)
	end
end)

-- コスト変更時は「表示中のpromptだけ更新」
local costValue = player:WaitForChild("UpgradeCost")

costValue:GetPropertyChangedSignal("Value"):Connect(function()
	local prompt = workspace.SpeedUpgrade:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		updatePrompt(prompt)
	end
end)

-- =========================
-- スピード制限スイッチUI
-- =========================
local toggleRemote = ReplicatedStorage:WaitForChild("ToggleSpeedLimit", 10)

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("LimitToggleGui")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LimitToggleGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
end

local frame = screenGui:FindFirstChild("ToggleFrame")
if not frame then
	frame = Instance.new("Frame")
	frame.Name = "ToggleFrame"
	frame.Size = UDim2.new(0, 150, 0, 100)
	frame.Position = UDim2.new(0, 10, 0.5, -50)
	frame.BackgroundTransparency = 1
	frame.Parent = screenGui
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = frame
end

local speedBtn = frame:FindFirstChild("SpeedToggle")
if not speedBtn then
	speedBtn = Instance.new("TextButton")
	speedBtn.Name = "SpeedToggle"
	speedBtn.Size = UDim2.new(1, 0, 0, 40)
	speedBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
	speedBtn.TextColor3 = Color3.new(1, 1, 1)
	speedBtn.TextSize = 14
	speedBtn.Font = Enum.Font.SourceSansBold
	speedBtn.Text = "Speed Limit: OFF"
	speedBtn.Parent = frame

	local isLimited = false
	speedBtn.MouseButton1Click:Connect(function()
		isLimited = not isLimited
		if isLimited then
			speedBtn.Text = "Speed Limit: ON"
			speedBtn.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
		else
			speedBtn.Text = "Speed Limit: OFF"
			speedBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
		end
		if toggleRemote then
			toggleRemote:FireServer(isLimited)
		end
	end)
end
