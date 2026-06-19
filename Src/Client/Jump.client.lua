local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))
local formatNumber = Utils.formatNumber

local TREASURE_TRANSLATION = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreasureTranslation"))
local TreasureConfig = require(ReplicatedStorage:WaitForChild("Server"):WaitForChild("Services"):WaitForChild("TreasureConfig"))

local carryLevel = player:WaitForChild("CarryLevel")
local carryCostValue = player:WaitForChild("CarryCost")

local carryUpgradePad = workspace:WaitForChild("CarryUpgrade")
local carryStorageContainer = workspace:WaitForChild(player.Name .. "_Base"):WaitForChild("CarryStorageContainer") or player:SetAttribute("CarryStorageContainer", Instance.new("Folder", player.Character.PrimaryPart)) -- Placeholder until base is created

local function updateCarryPrompt(prompt)
	local cost = carryCostValue and carryCostValue.Value or 500
	prompt.ObjectText = "Coins: " .. formatNumber(cost)
end

local function updateCarryStorageUI()
	if not carryStorageContainer then return end

	-- Clear existing UI
	for _, child in ipairs(carryStorageContainer:GetChildren()) do
		if child:IsA("ScreenGui") then
			child:Destroy()
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CarryStorageGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = carryStorageContainer

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 40 * carryLevel.Value) -- Adjust height based on level
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -10) -- Position at the bottom center
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	-- Spawn existing treasures in the container
	-- Assuming treasures are stored with specific attributes or names
	-- This part needs more context on how treasures are identified in the container
	local treasures = {} -- Placeholder for actual treasure retrieval
	-- Example: Find treasures based on a tag or attribute.
	-- for _, item in ipairs(carryStorageContainer:GetChildren()) do
	-- 	if item:GetAttribute("IsCarryTreasure") then
	-- 		table.insert(treasures, item)
	-- 	end
	-- end


	-- Placeholder for displaying treasures. This needs to be integrated with actual treasure data.
	-- For now, let's just show a placeholder for each level.
	for i = 1, carryLevel.Value do
		local slotFrame = Instance.new("Frame")
		slotFrame.Size = UDim2.new(1, 0, 0, 40)
		slotFrame.BackgroundTransparency = 1
		slotFrame.LayoutOrder = i
		slotFrame.Parent = frame

		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, 0, 0, 40)
		slotLabel.Text = "Slot " .. i .. ": Empty"
		slotLabel.TextColor3 = Color3.new(1,1,1)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Parent = slotFrame
	end
end


ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Parent and prompt.Parent.Name == "CarryUpgrade" then
		updateCarryPrompt(prompt)
	end
end)

carryLevel:GetPropertyChangedSignal("Value"):Connect(function()
	updateCarryStorageUI()
end)

carryCostValue:GetPropertyChangedSignal("Value"):Connect(function()
	local prompt = carryUpgradePad:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		updateCarryPrompt(prompt)
	end
end)

-- Initial UI update
if player.Character then
	carryStorageContainer = player.Character:FindFirstChild("CarryStorageContainer") or Instance.new("Folder", player.Character)
	carryStorageContainer.Name = "CarryStorageContainer"
	updateCarryStorageUI()
end

player.CharacterAdded:Connect(function(character)
	carryStorageContainer = character:FindFirstChild("CarryStorageContainer") or Instance.new("Folder", character)
	carryStorageContainer.Name = "CarryStorageContainer"
	updateCarryStorageUI()
end)

