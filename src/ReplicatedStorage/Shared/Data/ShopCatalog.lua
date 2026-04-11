--!strict

-- Replace placeholder ProductId values after creating the real Roblox products.
local ShopCatalog = {
    GamePasses = {
        {
            Key = "founder_support",
            DisplayName = "Founder Support Pack",
            ProductId = 0,
            Type = "Supporter",
            Benefit = "Founder tag, premium battle banner trim, and support recognition.",
        },
        {
            Key = "vip_courtyard",
            DisplayName = "VIP Courtyard Access",
            ProductId = 0,
            Type = "Convenience",
            Benefit = "Access to a VIP social area and extra profile flair.",
        },
        {
            Key = "desert_commander_skin",
            DisplayName = "Desert Commander Skin",
            ProductId = 0,
            Type = "Cosmetic",
            SkinId = "desert_commander",
            Benefit = "A gold-and-sand battle outfit with commander trim.",
        },
        {
            Key = "medina_guard_skin",
            DisplayName = "Medina Guard Skin",
            ProductId = 0,
            Type = "Cosmetic",
            SkinId = "medina_guard",
            Benefit = "A green-and-white guard outfit inspired by Medina colors.",
        },
    },
    DeveloperProducts = {
        {
            Key = "support_tip_small",
            DisplayName = "Small Support Tip",
            ProductId = 0,
            Type = "Supporter",
            Benefit = "A simple way to support development.",
            Grants = {
                SupportPoints = 1,
            },
        },
        {
            Key = "knowledge_bundle_small",
            DisplayName = "Knowledge Token Bundle",
            ProductId = 0,
            Type = "Progression",
            Benefit = "Adds a modest bundle of Knowledge Tokens.",
            Grants = {
                KnowledgeTokens = 250,
            },
        },
        {
            Key = "ultimate_charge_single",
            DisplayName = "Battle Ultimate Charge",
            ProductId = 0,
            Type = "Battle",
            Benefit = "Adds 1 battle ultimate charge for the shockwave ability.",
            Grants = {
                UltimateCharges = 1,
            },
        },
        {
            Key = "ultimate_charge_bundle",
            DisplayName = "Ultimate Charge Bundle",
            ProductId = 0,
            Type = "Battle",
            Benefit = "Adds 5 battle ultimate charges for repeated battles.",
            Grants = {
                UltimateCharges = 5,
            },
        },
    },
    RewardedAds = {
        Enabled = true,
        PlacementId = 0,
        RewardProductKey = "ultimate_charge_single",
        DisplayName = "Rewarded Video Kiosk",
        Benefit = "Watch a short ad to earn 1 free ultimate charge.",
        Disclosure = "Rewards must be developer products. Players do not receive Robux from ads.",
    },
    SkinDefinitions = {
        default = {
            DisplayName = "Pilgrim Standard",
            UnlockType = "Default",
            PrimaryColor = Color3.fromRGB(229, 223, 209),
            SecondaryColor = Color3.fromRGB(72, 72, 72),
            AccentColor = Color3.fromRGB(188, 165, 116),
            CapeColor = Color3.fromRGB(240, 237, 230),
        },
        desert_commander = {
            DisplayName = "Desert Commander",
            UnlockType = "GamePass",
            UnlockKey = "desert_commander_skin",
            PrimaryColor = Color3.fromRGB(194, 153, 88),
            SecondaryColor = Color3.fromRGB(87, 61, 38),
            AccentColor = Color3.fromRGB(231, 197, 119),
            CapeColor = Color3.fromRGB(128, 92, 55),
        },
        medina_guard = {
            DisplayName = "Medina Guard",
            UnlockType = "GamePass",
            UnlockKey = "medina_guard_skin",
            PrimaryColor = Color3.fromRGB(79, 128, 89),
            SecondaryColor = Color3.fromRGB(244, 243, 239),
            AccentColor = Color3.fromRGB(204, 179, 111),
            CapeColor = Color3.fromRGB(57, 95, 65),
        },
    },
    Rules = {
        "Avoid locking core learning content behind payments.",
        "Favor cosmetics, support products, and convenience perks first.",
        "Keep ultimate purchases moderate so battles stay fun instead of unfair.",
        "Place ad monetization in lobbies, menus, and support lounges instead of sacred focal points.",
    },
}

return table.freeze(ShopCatalog)
