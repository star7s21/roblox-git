local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("AdminUpdateStat")

-- 管理者のUserIdリスト（サーバー側と合わせてください）
local ADMIN_IDS = {1, 23456789} 

local function isAdmin()
	return table.find(ADMIN_IDS, player.UserId) ~= nil
end

if not isAdmin() then return end

-- UI作成
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 歯車アイコン（ImageButton）
local gearButton = Instance.new("ImageButton")
gearButton.Name = "GearButton"
gearButton.Size = UDim2.new(0, 40, 0, 40)
gearButton.Position = UDim2.new(0, 10, 0, 10)
gearButton.Image = "rbxassetid://7072717697" -- 歯車アイコン
gearButton.BackgroundTransparency = 0.5
gearButton.BackgroundColor3 = Color3.new(0,0,0)
gearButton.Parent = screenGui

-- 管理パネル
local panel = Instance.new("Frame")
panel.Name = "AdminPanel"
panel.Size = UDim2.new(0, 200, 0, 250)
panel.Position = UDim2.new(0, 10, 0, 60)
panel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
panel.Visible = false
panel.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = panel

local function createStatControl(name, statName, smallInc, largeInc)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.BackgroundTransparency = 1
	frame.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Text = name
	label.TextColor3 = Color3.new(1,1,1)
	label.BackgroundTransparency = 1
	label.Parent = frame

	local btnMinus = Instance.new("TextButton")
	btnMinus.Size = UDim2.new(0.5, -2, 0, 20)
	btnMinus.Position = UDim2.new(0, 0, 0, 20)
	btnMinus.Text = "-" .. (smallInc or 1)
	btnMinus.Parent = frame

	local btnPlus = Instance.new("TextButton")
	btnPlus.Size = UDim2.new(0.5, -2, 0, 20)
	btnPlus.Position = UDim2.new(0.5, 2, 0, 20)
	btnPlus.Text = "+" .. (smallInc or 1)
	btnPlus.Parent = frame

	btnMinus.MouseButton1Click:Connect(function()
		remoteEvent:FireServer(statName, -(smallInc or 1))
	end)
	btnPlus.MouseButton1Click:Connect(function()
		remoteEvent:FireServer(statName, (smallInc or 1))
	end)
end

-- 各ステータスのコントロールを追加
createStatControl("Coins", "Coins", 1000)
createStatControl("Rebirths", "Rebirths", 1)
createStatControl("Speed", "Speed", 1)
createStatControl("BaseLevel", "BaseLevel", 1)

-- 表示切り替え
gearButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)
