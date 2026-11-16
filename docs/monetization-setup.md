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
3. It refuses while the player is in a battle, a sparring match or a story (`InBattle`,
   `InSparring`, `InStory`), so a video never leaves a character open to damage.
4. It builds the reward with `AdService:CreateAdRewardFromDevProductId` and calls
   `ShowRewardedVideoAdAsync`. Roblox then grants the developer product `ad_reward_tokens`
   ("Knowledge Token Pouch"), which goes through the normal `ProcessReceipt`. A completed
   video is logged as an ad reward; only receipts with Robux spent count as purchases.

Roblox's rules for the reward ([Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)):
it must be a developer product "which would normally be available to purchase with Robux
inside an in-game shop", not randomized, and must not inflate the economy. So the Knowledge
Token Pouch is **sold in the shop** like any other pack (it must never be hidden), and its 40
tokens are well below the paid 250-token bundle. `tests/luau/shop.spec.luau` checks both.

To turn it on:

1. Publish the experience and complete the Maturity and Compliance Questionnaire.
2. Check ad eligibility in Creator Hub. Roblox does not show ads to users under 13, so a large
   part of a 9-17 audience will never see the button work. That is a platform rule, not a bug.
3. In Creator Hub, create the "Knowledge Token Pouch" developer product with a real Robux
   price (players can buy it in the shop), and enable Rewarded Video Ads for the experience.
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
