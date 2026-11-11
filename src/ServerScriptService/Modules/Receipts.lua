--!strict

-- Developer-product receipt handling, kept free of Roblox services so it can be unit tested
-- (tests/luau/receipts.spec.luau). ShopService wires it to MarketplaceService.ProcessReceipt.
--
-- The rule: report "PurchaseGranted" to Roblox only after the grant and the receipt's
-- PurchaseId are saved in the same record. Anything else returns "NotProcessedYet", and
-- Roblox calls ProcessReceipt again later (also when the player next joins a server).

local Receipts = {}

Receipts.Granted = "PurchaseGranted"
Receipts.NotProcessedYet = "NotProcessedYet"
-- How many recent PurchaseIds a profile remembers. Roblox only retries recent receipts.
Receipts.MaxRemembered = 100

export type Grants = {
    UltimateCharges: number?,
    KnowledgeTokens: number?,
    SupportPoints: number?,
}

export type Product = {
    DisplayName: string,
    Grants: Grants?,
}

export type Profile = {
    UltimateCharges: number,
    KnowledgeTokens: number,
    SupportPoints: number,
    PurchaseIds: { string },
}

export type Options = {
    -- The catalog entry for a product id, or nil if this game does not sell it.
    FindProduct: (productId: number) -> Product?,
    -- The buyer's profile, or nil unless they are in this server with a loaded profile
    -- that can be saved (an unsaveable default profile must never take a grant).
    FindProfile: (playerId: number) -> Profile?,
    -- Saves the buyer's profile now and yields until the DataStore answers.
    Save: (playerId: number) -> boolean,
    -- Called after a grant is saved, to update the buyer's UI.
    OnGranted: ((playerId: number, product: Product) -> ())?,
    Log: ((message: string) -> ())?,
}

local function applyGrants(profile: Profile, product: Product, sign: number)
    local grants = product.Grants

    if not grants then
        return
    end

    profile.UltimateCharges += sign * (grants.UltimateCharges or 0)
    profile.KnowledgeTokens += sign * (grants.KnowledgeTokens or 0)
    profile.SupportPoints += sign * (grants.SupportPoints or 0)
end

function Receipts.new(options: Options)
    local processor = {}
    -- PurchaseIds whose save is still in flight. Roblox can call ProcessReceipt again for
    -- the same receipt before the first call returns; that call must not report success
    -- for a grant that might still fail to save.
    local inFlight: { [string]: boolean } = {}

    local function log(message: string)
        if options.Log then
            options.Log(message)
        end
    end

    function processor.Process(receiptInfo: { [string]: any }): string
        local product = options.FindProduct(receiptInfo.ProductId)

        if not product then
            log(string.format("No receipt handler for product id %s", tostring(receiptInfo.ProductId)))
            return Receipts.NotProcessedYet
        end

        local playerId = receiptInfo.PlayerId
        local profile = options.FindProfile(playerId)

        if not profile then
            return Receipts.NotProcessedYet
        end

        local purchaseId = tostring(receiptInfo.PurchaseId)

        if inFlight[purchaseId] then
            return Receipts.NotProcessedYet
        end

        -- Already granted and saved by an earlier call: acknowledge without granting again.
        if table.find(profile.PurchaseIds, purchaseId) then
            return Receipts.Granted
        end

        inFlight[purchaseId] = true
        applyGrants(profile, product, 1)
        table.insert(profile.PurchaseIds, purchaseId)

        local forgotten: { string } = {}

        while #profile.PurchaseIds > Receipts.MaxRemembered do
            table.insert(forgotten, table.remove(profile.PurchaseIds, 1) :: string)
        end

        local ok, saved = pcall(options.Save, playerId)
        inFlight[purchaseId] = nil

        if not ok or not saved then
            -- Undo in memory so the next save cannot store a grant Roblox will send again.
            applyGrants(profile, product, -1)
            local index = table.find(profile.PurchaseIds, purchaseId)

            if index then
                table.remove(profile.PurchaseIds, index)
            end

            for position, oldId in ipairs(forgotten) do
                table.insert(profile.PurchaseIds, position, oldId)
            end

            if not ok then
                log(string.format("Save threw while granting %s: %s", purchaseId, tostring(saved)))
            end

            return Receipts.NotProcessedYet
        end

        local onGranted = options.OnGranted

        if onGranted then
            -- The grant is already saved, so a UI error must not turn this into a retry.
            xpcall(onGranted, function(uiError)
                log(string.format("OnGranted failed for %s: %s", purchaseId, tostring(uiError)))
            end, playerId, product)
        end

        return Receipts.Granted
    end

    return processor
end

return Receipts
