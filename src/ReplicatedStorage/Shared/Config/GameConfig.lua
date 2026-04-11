--!strict

local GameConfig = {
    GameName = "Path of the Sahabah",
    Genre = "Educational Adventure",
    Engine = "Luau",
    TargetAudience = "Ages 9-17",
    HubName = "Makkah Courtyard",
    TravelRouteName = "Main Menu",
    StartingStoryId = "bilal_ibn_rabah",
    StartingBattleId = "badr",
    StartingDestinationId = "kaaba_courtyard",
    DefaultCurrency = "Knowledge Tokens",
    TeleportMenuEnabled = true,
    CorePillars = {
        "StoryDrivenLearning",
        "ObjectiveBasedBattles",
        "HubBasedExploration",
        "RespectfulPresentation",
        "CosmeticFirstMonetization",
    },
    ContentRules = {
        AvoidDepictingProphets = true,
        UseNarrationForHistoricalContext = true,
        KeepCombatAgeAppropriate = true,
        RewardLearningAsMuchAsCombat = true,
        TreatSacredSpacesWithRespect = true,
    },
}

return table.freeze(GameConfig)
