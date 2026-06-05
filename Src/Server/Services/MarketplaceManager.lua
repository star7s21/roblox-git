local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local MarketplaceConfig = require(script.Parent.MarketplaceConfig)

local MarketplaceManager = {}

local pendingPurchases = {}
local registeredUpgrades = {}

function MarketplaceManager.RegisterUpgrade(productType, callback)
	registeredUpgrades[productType] = callback
end

function MarketplaceManager.PromptPurchase(player, productType, extraData)
	local productId = MarketplaceConfig.Products[productType]
	if not productId then
		warn("No product ID registered for: " .. tostring(productType))
		return
	end

	pendingPurchases[player.UserId] = {
		Type = productType,
		ExtraData = extraData
	}

	MarketplaceService:PromptProductPurchase(player, productId)
end

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(userId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local pending = pendingPurchases[userId]
	if not pending then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local productType = pending.Type
	local targetId = MarketplaceConfig.Products[productType]

	if productId == targetId then
		local callback = registeredUpgrades[productType]
		if callback then
			local success, err = pcall(callback, player, pending.ExtraData)
			if not success then
				warn("Error running upgrade callback for " .. tostring(productType) .. ": " .. tostring(err))
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
	end

	pendingPurchases[userId] = nil
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt

return MarketplaceManager
