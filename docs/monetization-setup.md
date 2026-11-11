# Monetization Setup

This project now includes a working in-game shop, purchasable battle skins, repeat-purchase ultimate charges, and ad-ready support lounge screens.

## 1. Create the Roblox products

Create these in Creator Hub for the same experience:

- Game passes
  - `founder_support`
  - `vip_courtyard`
  - `desert_commander_skin`
  - `medina_guard_skin`
- Developer products
  - `support_tip_small`
  - `knowledge_bundle_small`
  - `ultimate_charge_single`
  - `ultimate_charge_bundle`

After you create them, copy each asset ID into:

- `src/ReplicatedStorage/Shared/Data/ShopCatalog.lua`

## 2. Turn on sales flow

The shop prompt flow and `ProcessReceipt` handling already exist in:

- `src/ServerScriptService/ShopService.server.lua`

If you change product names or add new items, update both the catalog and the server grant logic.

## 3. Rewarded ads (code is done, live ads are blocked until setup)

The game uses Roblox's rewarded video ads (`AdService`). Players open **Journeys > Support >
Watch a video** and receive Knowledge Tokens after a completed view. The flow is in
`src/ServerScriptService/SupportService.server.lua`:

1. The button only works when `MonetizationConfig.RewardedAd.DevProductId` is set.
2. The server checks the daily limit (`DailyLimit`, 3 by default) and
   `AdService:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)`.
3. It builds the reward with `AdService:CreateAdRewardFromDevProductId` and calls
   `ShowRewardedVideoAdAsync`. Roblox then grants the hidden developer product
   `ad_reward_tokens`, which goes through the normal `ProcessReceipt` and is logged as an ad
   reward.

To turn it on:

1. Publish the experience and complete the Maturity and Compliance Questionnaire.
2. Check ad eligibility in Creator Hub. Roblox does not show ads to users under 13, so a large
   part of a 9-17 audience will never see the button work. That is a platform rule, not a bug.
3. In Creator Hub, create a developer product for the ad reward (price does not matter) and
   enable Rewarded Video Ads for the experience.
4. Put the product ID in `src/ReplicatedStorage/Shared/Config/MonetizationConfig.lua`
   (`RewardedAd.DevProductId`) and, if you made one, the placement ID (`PlacementId`).
5. Test in a live server with an eligible account. Studio cannot show real ads.

## 4. Revenue, retention and costs

Two layers of tracking:

- **Roblox Analytics** (official numbers). `Modules/Analytics.lua` logs onboarding steps,
  funnels (Seerah chapters, mysteries), custom events (parkour, co-op, PvP finishes) and economy
  events. View them in Creator Hub > Analytics. Revenue, DAU and D1/D7/D30 retention are also
  there once the game has traffic.
- **The in-game business ledger** (`Modules/BusinessMetrics.lua`). One DataStore row per UTC
  day (`BusinessLedger_v1`), updated with `UpdateAsync` so all servers add to the same totals:
  joins, new players, returning players, D1/D7/D30 returns, purchases, Robux spent per product,
  ad rewards, sessions and play minutes. The retention rules are unit tested
  (`Modules/Retention.lua`). The creator sees the last 14 days under **Journeys > Support >
  Creator numbers** (only `game.CreatorId` can open it).
- **Costs** are entered by hand in `MonetizationConfig.MonthlyCostsRobux` (sponsored ads,
  asset uploads, other). The ledger screen spreads them over the days shown and subtracts them from the Robux players spent. Robux spent
  is the price the player paid; your actual earnings after the Roblox fee are in Creator Hub.

## 5. Respectful placement

The code places monetization screens in a support lounge at the outer edge of the Makkah hub, not beside the Kaaba itself. That keeps monetization present in the experience while protecting the main sacred space from feeling commercialized.
