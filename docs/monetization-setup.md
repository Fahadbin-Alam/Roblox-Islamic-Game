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

## 3. Rewarded ads

The map includes ad-ready support screens, but real rewarded ad revenue still requires Roblox setup:

1. Publish the experience.
2. Complete the Maturity and Compliance Questionnaire.
3. Meet Roblox ad eligibility requirements.
4. Enable Rewarded Video Ads in `Experience Settings > Monetization`.
5. Create a rewarded ad placement in Creator Hub.
6. Replace the placeholder `PlacementId` in `ShopCatalog.lua`.

## 4. Respectful placement

The code places monetization screens in a support lounge at the outer edge of the Makkah hub, not beside the Kaaba itself. That keeps monetization present in the experience while protecting the main sacred space from feeling commercialized.
