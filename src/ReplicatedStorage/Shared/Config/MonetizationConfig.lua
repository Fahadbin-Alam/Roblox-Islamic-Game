--!strict

-- Settings for platform-supported monetization. Fill the ids in after creating the products in
-- Creator Hub (see docs/monetization-setup.md). While an id is 0 the feature stays switched off
-- and the game says so instead of failing.

return table.freeze({
    RewardedAd = table.freeze({
        -- A developer product used as the reward for a rewarded video ad (AdService).
        DevProductId = 0,
        -- Optional ad placement id from Creator Hub; nil uses the default placement.
        PlacementId = nil :: number?,
        RewardTokens = 40,
        -- Rewarded ads a player can watch per UTC day. Ads are optional and never block play.
        DailyLimit = 3,
    }),
    -- DataStore with one row per UTC day of business numbers (revenue, retention, joins).
    LedgerStore = "BusinessLedger_v1",
    -- Monthly operating costs you enter yourself, in Robux, so the ledger can show net income.
    -- Roblox hosts servers for free; typical costs are sponsored ads and asset uploads.
    MonthlyCostsRobux = table.freeze({
        SponsoredAds = 0,
        AssetUploads = 0,
        Other = 0,
    }),
})
