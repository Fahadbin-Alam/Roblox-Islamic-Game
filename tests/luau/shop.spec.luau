-- Roblox's rewarded video ad rules: the reward must "be a developer product which would
-- normally be available to purchase with Robux inside an in-game shop" and must not be
-- randomized. https://create.roblox.com/docs/production/promotion/rewarded-video-ads
local ShopCatalog = load("Data/ShopCatalog")
local MonetizationConfig = load("Config/MonetizationConfig")

test("the rewarded-ad product is a normal shop product", function()
    local rewards = {}

    for _, item in ipairs(ShopCatalog.DeveloperProducts) do
        expectEqual(item.Hidden, nil, item.Key .. " must not be hidden from the shop")

        if item.RewardedAdReward then
            table.insert(rewards, item)
        end
    end

    expectEqual(#rewards, 1, "exactly one product is the ad reward")
    local reward = rewards[1]
    expectEqual(reward.Key, ShopCatalog.RewardedAds.RewardProductKey, "the kiosk names the same product")
    expectEqual(reward.ProductId, MonetizationConfig.RewardedAd.DevProductId, "the ad grants the product the shop sells")
    assert(reward.Type ~= "AdReward", "the ad reward is sold as an ordinary pack, not a special ad-only type")
    expectEqual(reward.Grants.KnowledgeTokens, MonetizationConfig.RewardedAd.RewardTokens, "a fixed, non-random grant")
end)

test("the ad reward is smaller than the paid token bundle", function()
    local largest = 0

    for _, item in ipairs(ShopCatalog.DeveloperProducts) do
        if not item.RewardedAdReward and item.Grants and item.Grants.KnowledgeTokens then
            largest = math.max(largest, item.Grants.KnowledgeTokens)
        end
    end

    assert(MonetizationConfig.RewardedAd.RewardTokens < largest, "an ad must not out-earn buying tokens")
end)
