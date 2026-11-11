local Receipts = load("Server/Receipts")

-- A shop with one product, one player, and a save function the test controls. `saves`
-- records a copy of the profile each time a save succeeds, like the DataStore would.
local function fakeShop()
    local shop = {
        Product = { DisplayName = "Ultimate Charge x3", Grants = { UltimateCharges = 3 } },
        Profile = { UltimateCharges = 0, KnowledgeTokens = 0, SupportPoints = 0, PurchaseIds = {} },
        Loaded = true,
        SaveWorks = true,
        Saves = {},
        Granted = 0,
        Logs = {},
    }

    shop.Processor = Receipts.new({
        FindProduct = function(productId)
            return if productId == 1001 then shop.Product else nil
        end,
        FindProfile = function(playerId)
            return if playerId == 7 and shop.Loaded then shop.Profile else nil
        end,
        Save = function(_playerId)
            if shop.OnSave then
                shop.OnSave()
            end

            if shop.SaveWorks == "throw" then
                error("DataStore request failed")
            end

            if shop.SaveWorks then
                table.insert(shop.Saves, { UltimateCharges = shop.Profile.UltimateCharges, PurchaseIds = table.clone(shop.Profile.PurchaseIds) })
            end

            return shop.SaveWorks == true
        end,
        OnGranted = function()
            shop.Granted += 1
        end,
        Log = function(message)
            table.insert(shop.Logs, message)
        end,
    })

    return shop
end

local function receipt(purchaseId)
    return { PlayerId = 7, ProductId = 1001, PurchaseId = purchaseId }
end

test("receipt: grant and save succeed, so Roblox is told PurchaseGranted", function()
    local shop = fakeShop()

    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.Granted, "decision")
    expectEqual(shop.Profile.UltimateCharges, 3, "charges granted")
    expectEqual(#shop.Saves, 1, "saved once")
    expectEqual(shop.Saves[1].UltimateCharges, 3, "the saved record holds the grant")
    expectEqual(shop.Saves[1].PurchaseIds[1], "p1", "and the PurchaseId, in the same write")
    expectEqual(shop.Granted, 1, "UI told once")
end)

test("receipt: failed save returns NotProcessedYet, and the retry grants exactly once", function()
    local shop = fakeShop()
    shop.SaveWorks = false

    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.NotProcessedYet, "decision on failed save")
    expectEqual(shop.Profile.UltimateCharges, 0, "grant undone in memory")
    expectEqual(#shop.Profile.PurchaseIds, 0, "PurchaseId not remembered")
    expectEqual(shop.Granted, 0, "UI not told")

    -- Roblox retries the same receipt once the DataStore is back.
    shop.SaveWorks = true
    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.Granted, "retry is granted")
    expectEqual(shop.Profile.UltimateCharges, 3, "granted once, not twice")
    expectEqual(#shop.Saves, 1, "one successful save")
end)

test("receipt: a save that throws is treated like a failed save", function()
    local shop = fakeShop()
    shop.SaveWorks = "throw"

    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.NotProcessedYet, "decision")
    expectEqual(shop.Profile.UltimateCharges, 0, "grant undone")
    expectEqual(#shop.Logs, 1, "error logged")
end)

test("receipt: a duplicate PurchaseId is acknowledged without a second grant", function()
    local shop = fakeShop()

    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.Granted, "first")
    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.Granted, "duplicate acknowledged")
    expectEqual(shop.Profile.UltimateCharges, 3, "no second grant")
    expectEqual(#shop.Saves, 1, "no second save")
    expectEqual(shop.Granted, 1, "UI told once")

    -- A different purchase of the same product is a new grant.
    expectEqual(shop.Processor.Process(receipt("p2")), Receipts.Granted, "second purchase")
    expectEqual(shop.Profile.UltimateCharges, 6, "second purchase granted")
end)

test("receipt: the same PurchaseId arriving while its save is in flight is not acknowledged", function()
    local shop = fakeShop()
    local nested

    shop.OnSave = function()
        shop.OnSave = nil
        nested = shop.Processor.Process(receipt("p1"))
    end

    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.Granted, "outer call")
    expectEqual(nested, Receipts.NotProcessedYet, "inner call must wait for the save")
    expectEqual(shop.Profile.UltimateCharges, 3, "granted once")
end)

test("receipt: buyer not loaded or unknown product waits for a retry", function()
    local shop = fakeShop()
    shop.Loaded = false
    expectEqual(shop.Processor.Process(receipt("p1")), Receipts.NotProcessedYet, "profile not loaded")
    expectEqual(#shop.Saves, 0, "nothing saved")

    shop.Loaded = true
    expectEqual(shop.Processor.Process({ PlayerId = 7, ProductId = 999, PurchaseId = "p1" }), Receipts.NotProcessedYet, "unknown product")
    expectEqual(shop.Profile.UltimateCharges, 0, "nothing granted")
end)

test("receipt: old PurchaseIds are trimmed, and restored if the save fails", function()
    local shop = fakeShop()

    for index = 1, Receipts.MaxRemembered do
        table.insert(shop.Profile.PurchaseIds, "old" .. index)
    end

    shop.SaveWorks = false
    expectEqual(shop.Processor.Process(receipt("new")), Receipts.NotProcessedYet, "failed save")
    expectEqual(#shop.Profile.PurchaseIds, Receipts.MaxRemembered, "list size unchanged")
    expectEqual(shop.Profile.PurchaseIds[1], "old1", "trimmed id restored")

    shop.SaveWorks = true
    expectEqual(shop.Processor.Process(receipt("new")), Receipts.Granted, "retry")
    expectEqual(#shop.Profile.PurchaseIds, Receipts.MaxRemembered, "still capped")
    expectEqual(shop.Profile.PurchaseIds[Receipts.MaxRemembered], "new", "newest kept")
    expectEqual(shop.Profile.PurchaseIds[1], "old2", "oldest dropped")
end)
