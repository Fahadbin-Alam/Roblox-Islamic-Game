--!strict

local BattleScenarios = {
    {
        Id = "badr",
        DisplayName = "Battle of Badr",
        QueuePrompt = "Join the Battle of Badr queue.",
        Format = "TeamBattleScenario",
        ArenaTheme = "DesertValley",
        RecommendedPlayers = 6,
        MinPlayersToLaunch = 1,
        PlayersPerTeam = 3,
        CountdownSeconds = 8,
        RoundDurationSeconds = 170,
        LearningGoal = "Teach courage, preparation, unity, and the importance of a major early turning point.",
        Teams = {
            {
                Id = "medina",
                DisplayName = "Medina Side",
                AccentColor = Color3.fromRGB(56, 123, 79),
            },
            {
                Id = "makkah",
                DisplayName = "Makkah Side",
                AccentColor = Color3.fromRGB(160, 109, 60),
            },
        },
        SpawnPositions = {
            medina = {
                Vector3.new(-1320, 10, 720),
                Vector3.new(-1310, 10, 752),
                Vector3.new(-1290, 10, 692),
            },
            makkah = {
                Vector3.new(-982, 10, 720),
                Vector3.new(-996, 10, 752),
                Vector3.new(-1010, 10, 692),
            },
        },
        GameplayPhases = {
            {
                Id = "briefing",
                Title = "Briefing",
                Objective = "Enter the valley, study the wells and ridges, and prepare your side for the clash.",
            },
            {
                Id = "clash",
                Title = "Main Clash",
                Objective = "Push through the valley with swords and arrows while using terrain and cover.",
            },
            {
                Id = "reenactment",
                Title = "Historical Reenactment",
                Objective = "Watch the battle aftermath play out through a short staged retelling.",
            },
        },
        Briefing = {
            IntroTitle = "Before The Battle",
            Scenes = {
                {
                    CameraName = "BriefingMap1",
                    Title = "624 CE | 2 AH",
                    Body = "Badr happened after the Hijrah, when the Muslims had settled in Medina and tension with the Quraysh of Makkah was still rising.",
                    DurationSeconds = 7,
                    FieldOfView = 62,
                },
                {
                    CameraName = "BriefingMap2",
                    Title = "Why The Fight Happened",
                    Body = "This briefing keeps the history simple: the young Muslim community and the Quraysh were in open conflict, and Badr became the first major battle between them.",
                    DurationSeconds = 7,
                    FieldOfView = 58,
                },
                {
                    CameraName = "BriefingMap3",
                    Title = "The Valley And Wells",
                    Body = "The map shows the valley, travel route, and wells. Players should notice that terrain and preparation mattered before the clash began.",
                    DurationSeconds = 6,
                    FieldOfView = 64,
                },
                {
                    CameraName = "BriefingMap4",
                    Title = "Your Objective",
                    Body = "Fight the round for fun. The lesson is that Badr became a turning point remembered for courage, unity, preparation, and gratitude.",
                    DurationSeconds = 6,
                    FieldOfView = 60,
                },
            },
        },
        Reenactment = {
            IntroTitle = "Badr Reenactment",
            Scenes = {
                {
                    CameraName = "Scene1",
                    Title = "The Wells Of Badr",
                    Body = "The reenactment returns to the valley of Badr in 624 CE, where the battle became a defining moment for the early Muslim community.",
                    DurationSeconds = 6,
                },
                {
                    CameraName = "Scene2",
                    Title = "Standing Together",
                    Body = "The lesson is not just that a fight happened. It is that a small, vulnerable community stood together under pressure.",
                    DurationSeconds = 6,
                },
                {
                    CameraName = "Scene3",
                    Title = "A Turning Point",
                    Body = "Badr raised morale and changed how the community was seen. That is why the round ends with reflection, not just a scoreboard.",
                    DurationSeconds = 6,
                },
                {
                    CameraName = "Scene4",
                    Title = "What Players Should Remember",
                    Body = "In the game you fought for fun. In the lesson, remember preparation, unity, gratitude, and responsibility after victory.",
                    DurationSeconds = 6,
                },
            },
        },
        StorySummary = {
            Title = "What Happened At Badr",
            Lines = {
                "Badr took place in 624 CE and became a major victory for the early Muslim community.",
                "The battle strengthened morale and marked a turning point in the public standing of the community.",
                "This battle mode lets players have fun with the action while the reenactment keeps the historical meaning in view.",
            },
        },
        Rewards = {
            KnowledgeTokens = 100,
            UnlockStoryIds = {
                "bilal_ibn_rabah",
                "umar_ibn_al_khattab",
            },
        },
    },
    {
        Id = "uhud",
        DisplayName = "Battle of Uhud",
        QueuePrompt = "Join the Battle of Uhud queue.",
        Format = "TeamBattleScenario",
        ArenaTheme = "MountainPass",
        RecommendedPlayers = 6,
        MinPlayersToLaunch = 1,
        PlayersPerTeam = 3,
        CountdownSeconds = 8,
        RoundDurationSeconds = 180,
        LearningGoal = "Teach discipline, positioning, and how quickly momentum can change in battle.",
        Teams = {
            {
                Id = "medina",
                DisplayName = "Medina Side",
                AccentColor = Color3.fromRGB(63, 132, 86),
            },
            {
                Id = "makkah",
                DisplayName = "Makkah Side",
                AccentColor = Color3.fromRGB(143, 101, 68),
            },
        },
        SpawnPositions = {
            medina = {
                Vector3.new(-1320, 10, 1180),
                Vector3.new(-1304, 10, 1210),
                Vector3.new(-1288, 10, 1148),
            },
            makkah = {
                Vector3.new(-982, 10, 1180),
                Vector3.new(-996, 10, 1210),
                Vector3.new(-1010, 10, 1148),
            },
        },
        GameplayPhases = {
            {
                Id = "briefing",
                Title = "Briefing",
                Objective = "Study the mountain pass, the archer ridge, and the approaches before the clash begins.",
            },
            {
                Id = "clash",
                Title = "Main Clash",
                Objective = "Fight through the pass with swords and arrows while using the ridge and rocky cover.",
            },
            {
                Id = "reenactment",
                Title = "Historical Reenactment",
                Objective = "Watch the mountain-side story retold through a short staged scene.",
            },
        },
        Briefing = {
            IntroTitle = "Before The Battle",
            Scenes = {
                {
                    CameraName = "BriefingMap1",
                    Title = "625 CE | 3 AH",
                    Body = "Uhud happened the year after Badr, near Mount Uhud outside Medina, as the Quraysh came again after their earlier defeat.",
                    DurationSeconds = 7,
                    FieldOfView = 62,
                },
                {
                    CameraName = "BriefingMap2",
                    Title = "Why The Fight Happened",
                    Body = "The battle was connected to the continuing conflict between Makkah and Medina after Badr. The Quraysh wanted to answer that loss.",
                    DurationSeconds = 7,
                    FieldOfView = 58,
                },
                {
                    CameraName = "BriefingMap3",
                    Title = "The Mountain And Ridge",
                    Body = "The map shows Mount Uhud, the pass, and the archer ridge. This battle teaches that position and discipline can change everything.",
                    DurationSeconds = 7,
                    FieldOfView = 60,
                },
                {
                    CameraName = "BriefingMap4",
                    Title = "Your Objective",
                    Body = "Fight the round with swords and bows, then watch the ending reenactment to connect the gameplay to the lesson.",
                    DurationSeconds = 5,
                    FieldOfView = 60,
                },
            },
        },
        Reenactment = {
            IntroTitle = "Uhud Reenactment",
            Scenes = {
                {
                    CameraName = "Scene1",
                    Title = "Mount Uhud And The Pass",
                    Body = "The reenactment returns to 625 CE near Mount Uhud, where the terrain shaped the way the battle unfolded.",
                    DurationSeconds = 6,
                },
                {
                    CameraName = "Scene2",
                    Title = "The Archer Ridge",
                    Body = "A major lesson of Uhud is to hold the assigned position even when the battle seems to be going your way.",
                    DurationSeconds = 6,
                },
                {
                    CameraName = "Scene3",
                    Title = "A Hard Turn",
                    Body = "Momentum changed during the fighting, and the community faced a painful test near the mountain.",
                    DurationSeconds = 6,
                },
                {
                    CameraName = "Scene4",
                    Title = "The Lesson Of Uhud",
                    Body = "In the game you fought for fun. In the lesson, remember that courage must stay joined to discipline and steady judgment.",
                    DurationSeconds = 6,
                },
            },
        },
        StorySummary = {
            Title = "What Happened At Uhud",
            Lines = {
                "Uhud took place in 625 CE near Mount Uhud and became a hard lesson about discipline and battlefield positioning.",
                "Early momentum shifted during the fighting, and the battle became a reminder that courage must stay tied to obedience and steady judgment.",
                "This round lets players enjoy the action, while the reenactment keeps the historical lesson connected to the gameplay.",
            },
        },
        Rewards = {
            KnowledgeTokens = 125,
            UnlockStoryIds = {
                "musab_ibn_umayr",
                "nusaybah_bint_kaab",
            },
        },
    },
}

return table.freeze(BattleScenarios)
