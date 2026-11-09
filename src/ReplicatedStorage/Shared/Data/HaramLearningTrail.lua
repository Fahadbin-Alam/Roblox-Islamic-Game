--!strict

local HaramLearningTrail = {
    Id = "haram_learning_walk",
    DisplayName = "Haram Learning Walk",
    RewardTokens = 35,
    AccentColor = Color3.fromRGB(193, 162, 86),
    StartObjective = "Begin at the gold learning marker on the north side of the mataf, near where you arrive.",
    Steps = {
        {
            Title = "Enter With Respect",
            LocationName = "Orientation Marker",
            Objective = "Begin at the gold learning marker on the north side of the mataf, near where you arrive.",
            Lines = {
                { Speaker = "Guide", Text = "Start by slowing down and looking around. This hub is for learning and respectful exploration." },
                { Speaker = "Guide", Text = "Follow the gold trail lights. Each stop teaches one landmark or idea without turning worship into a game objective." },
            },
        },
        {
            Title = "The Kaaba As A Direction",
            LocationName = "Kaaba View Stop",
            Objective = "Walk to the stop facing the Black Stone corner on the east side of the Kaaba.",
            Lines = {
                { Speaker = "Guide", Text = "The Kaaba is the central landmark of Masjid al-Haram and the direction Muslims face in prayer. Its black cover, the kiswa, has a gold embroidered band called the hizam." },
                { Speaker = "Guide", Text = "The Black Stone sits in a silver frame in this eastern corner. Tawaf begins in line with it, and a green light on the gallery marks the spot." },
                { Speaker = "Guide", Text = "This build is a respectful learning model of today's mosque, not an exact replica of the sacred site." },
            },
        },
        {
            Title = "The Tawaf Flow",
            LocationName = "Tawaf Path Stop",
            Objective = "Follow the gold trail to the marker on the west side of the white marble mataf.",
            Lines = {
                { Speaker = "Guide", Text = "The white marble floor around the Kaaba is the mataf. Pilgrims walk around the Kaaba seven times, keeping it on their left." },
                { Speaker = "Guide", Text = "In real life, tawaf is worship. Here, the path is only a learning and navigation guide." },
            },
        },
        {
            Title = "Maqam Ibrahim Marker",
            LocationName = "Maqam Stop",
            Objective = "Study Maqam Ibrahim, the gold-and-glass case in front of the Kaaba door.",
            Lines = {
                { Speaker = "Guide", Text = "Maqam Ibrahim is the stone Prophet Ibrahim stood on while building the Kaaba, now kept in a gold and glass case facing the door." },
                { Speaker = "Guide", Text = "After tawaf, pilgrims pray two rak'ahs behind it if they can (Qur'an 2:125)." },
            },
        },
        {
            Title = "Hijr / Hateem Marker",
            LocationName = "Hijr Ismail Stop",
            Objective = "Walk to the curved white wall of Hijr Ismail on the north-west side of the Kaaba.",
            Lines = {
                { Speaker = "Guide", Text = "This low curved wall marks Hijr Ismail, also called the Hateem. Part of it was originally inside the Kaaba, so tawaf goes around the outside of the wall." },
                { Speaker = "Guide", Text = "Above it, the gold rain spout on the Kaaba roof is the Mizab ar-Rahmah." },
            },
        },
        {
            Title = "Galleries, Gates, And Minarets",
            LocationName = "Mataf Gallery Stop",
            Objective = "Finish under the multi-level mataf galleries on the north side and look back over the courtyard.",
            Lines = {
                { Speaker = "Guide", Text = "The ring of galleries around you is the mataf expansion, built so more people can make tawaf on every floor. The ramps take you up to see the Kaaba from above." },
                { Speaker = "Guide", Text = "Beyond it are the King Fahd and King Abdullah expansions, the mas'a between Safa and Marwah on the east side, thirteen minarets and the clock tower to the south." },
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
