--!strict

local destinations = {
    {
        Id = "kaaba_courtyard",
        DisplayName = "Masjid al-Haram",
        Description = "The Makkah sanctuary hub around the Kaaba, with warmer stone, arcades, and battle boards.",
        Theme = "Mecca",
        Position = Vector3.new(0, 4, 0),
        TeleportPosition = Vector3.new(0, 4, 92),
        AccentColor = Color3.fromRGB(35, 35, 35),
    },
    {
        Id = "journey_reflection",
        DisplayName = "Desert Route Camp",
        Description = "A long desert route stop between Makkah and Medina with dunes, camp structures, and reflection signs.",
        Theme = "Reflection",
        Position = Vector3.new(0, 4, 760),
        TeleportPosition = Vector3.new(0, 4, 704),
        AccentColor = Color3.fromRGB(118, 92, 58),
    },
    {
        Id = "medina_courtyard",
        DisplayName = "Prophet's Mosque Courtyard",
        Description = "A larger Medina district inspired by Al-Masjid an-Nabawi, with gate names, a green dome, and a visitation route.",
        Theme = "Medina",
        Position = Vector3.new(0, 4, 1500),
        TeleportPosition = Vector3.new(0, 4, 1636),
        AccentColor = Color3.fromRGB(69, 121, 77),
    },
    {
        Id = "story_court",
        DisplayName = "Sahabi Story Court",
        Description = "Choose a sahabi playthrough and learn through guided NPC story scenes.",
        Theme = "Stories",
        Position = Vector3.new(346, 4, 214),
        TeleportPosition = Vector3.new(346, 4, 270),
        AccentColor = Color3.fromRGB(73, 96, 77),
    },
    {
        Id = "manners_court",
        DisplayName = "Manners Court",
        Description = "A kid-friendly learning area for adab, respect, honesty, mercy, and good speech.",
        Theme = "Manners",
        Position = Vector3.new(-346, 4, -360),
        TeleportPosition = Vector3.new(-346, 4, -302),
        AccentColor = Color3.fromRGB(98, 119, 76),
    },
    {
        Id = "trivia_court",
        DisplayName = "Trivia Court",
        Description = "A live Islamic trivia area where everyone on the server can compete through harder and harder questions.",
        Theme = "Trivia",
        Position = Vector3.new(346, 4, -438),
        TeleportPosition = Vector3.new(346, 4, -366),
        AccentColor = Color3.fromRGB(63, 98, 88),
    },
    {
        Id = "parkour_tower",
        DisplayName = "Lobby Parkour Tower",
        Description = "A climbing challenge in the lobby for players waiting between stories and battles.",
        Theme = "Parkour",
        Position = Vector3.new(-358, 4, 196),
        TeleportPosition = Vector3.new(-416, 8, 196),
        AccentColor = Color3.fromRGB(182, 152, 84),
    },
    {
        Id = "badr_gate",
        DisplayName = "Badr Gate",
        Description = "The battle gate and staging point for the Battle of Badr scenario.",
        Theme = "BattleGate",
        Position = Vector3.new(-520, 4, -140),
        TeleportPosition = Vector3.new(-520, 4, -98),
        AccentColor = Color3.fromRGB(141, 107, 58),
    },
    {
        Id = "uhud_gate",
        DisplayName = "Uhud Gate",
        Description = "The battle gate and staging point for the Battle of Uhud scenario.",
        Theme = "BattleGate",
        Position = Vector3.new(-520, 4, 120),
        TeleportPosition = Vector3.new(-520, 4, 162),
        AccentColor = Color3.fromRGB(114, 92, 71),
    },
}

local destinationById = {}

for _, destination in ipairs(destinations) do
    destinationById[destination.Id] = destination
end

local TravelRoute = {
    RouteName = "Main Menu",
    WorldFolderName = "GeneratedHub",
    StartDestinationId = "kaaba_courtyard",
    EndDestinationId = "medina_courtyard",
    WalkPrompt = "Use the main menu to jump between Makkah, the desert route, Medina, stories, manners, parkour, and battle gates.",
    Destinations = destinations,
}

function TravelRoute.GetDestinationById(destinationId: string)
    return destinationById[destinationId]
end

return table.freeze(TravelRoute)
