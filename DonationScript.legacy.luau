local marketplaceService = game:GetService("MarketplaceService")
local function processReceipt(receiptInfo)
    local userId = receiptInfo.PlayerId
    local productId = receiptInfo.ProductId
    local player = game.Players:GetPlayerByUserId(userId)
    if player then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    return Enum.ProductPurchaseDecision.NotProcessedYet
end
marketplaceService.ProcessReceipt = processReceipt