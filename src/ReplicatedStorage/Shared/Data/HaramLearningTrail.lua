--!strict

local HaramLearningTrail = {
    Id = "haram_learning_walk",
    DisplayName = "Haram Learning Walk",
    RewardTokens = 35,
    AccentColor = Color3.fromRGB(193, 162, 86),
    StartObjective = "Begin at the gold learning marker on the south side of the Kaaba courtyard.",
    Steps = {
        {
            Title = "Enter With Respect",
            LocationName = "Orientation Marker",
            Objective = "Begin at the gold learning marker on the south side of the courtyard.",
            Lines = {
                { Speaker = "Guide", Text = "Start by slowing down and looking around. This hub is for learning and respectful exploration." },
                { Speaker = "Guide", Text = "Follow the gold trail lights. Each stop teaches one landmark or idea without turning worship into a game objective." },
            },
        },
        {
            Title = "The Kaaba As A Direction",
            LocationName = "Kaaba View Stop",
            Objective = "Walk to the Kaaba view stop near the front-right side of the courtyard.",
            Lines = {
                { Speaker = "Guide", Text = "The Kaaba is the central landmark of Masjid al-Haram and the direction Muslims face in prayer." },
                { Speaker = "Guide", Text = "This build uses a respectful learning model, not a perfect replica of the real sacred site." },
            },
        },
        {
            Title = "The Tawaf Flow",
            LocationName = "Tawaf Path Stop",
            Objective = "Follow the gold trail to the circular path marker on the west side.",
            Lines = {
                { Speaker = "Guide", Text = "The circular guide lights help you understand movement around the Kaaba." },
                { Speaker = "Guide", Text = "In real life, tawaf is worship. Here, the path is only a learning and navigation guide." },
            },
        },
        {
            Title = "Maqam Ibrahim Marker",
            LocationName = "Maqam Stop",
            Objective = "Study the Maqam Ibrahim marker near the gold-and-glass station.",
            Lines = {
                { Speaker = "Guide", Text = "This marker points players toward Maqam Ibrahim as an important Kaaba-side landmark." },
                { Speaker = "Guide", Text = "The game keeps it symbolic so players can recognize the idea without pretending it is the real place." },
            },
        },
        {
            Title = "Hijr / Hateem Marker",
            LocationName = "Curved Boundary Stop",
            Objective = "Walk to the curved low boundary marker near the north side of the Kaaba.",
            Lines = {
                { Speaker = "Guide", Text = "The curved boundary helps you notice another landmark connected to the Kaaba area." },
                { Speaker = "Guide", Text = "Small markers like this make the courtyard easier to learn without crowding the center." },
            },
        },
        {
            Title = "Arcades, Gates, And Scale",
            LocationName = "North Arcade Stop",
            Objective = "Finish at the north arcade stop and look back over the whole courtyard.",
            Lines = {
                { Speaker = "Guide", Text = "The surrounding arcades, gates, towers, and minarets help the place feel large and alive." },
                { Speaker = "Guide", Text = "A good learning hub gives you orientation first, then lets stories, battles, and manners lessons branch out naturally." },
            },
        },
    },
    Completion = {
        Title = "Learning Walk Complete",
        Lines = {
            { Speaker = "Guide", Text = "You finished the Haram Learning Walk. Now you know the main landmarks this hub is trying to teach." },
            { Speaker = "Guide", Text = "Next, try a sahabi story, manners lesson, or battle scenario to keep learning through play." },
        },
    },
}

return table.freeze(HaramLearningTrail)
