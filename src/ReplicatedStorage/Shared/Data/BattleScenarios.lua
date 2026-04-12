--!strict

local BattleScenarios = {
    {
        Id = "badr",
        DisplayName = "Battle of Badr",
        QueuePrompt = "Join the Battle of Badr queue.",
        Format = "TeamBattleScenario",
        ArenaTheme = "DesertValley",
        RecommendedPlayers = 60,
        MinPlayersToLaunch = 1,
        PlayersPerTeam = 30,
        CountdownSeconds = 8,
        RoundDurationSeconds = 240,
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
        Commander = {
            TeamId = "makkah",
            DisplayName = "Quraysh Commander",
            RoleText = "A stronger opposing-side commander role. If a player is on this side, one player becomes the commander. If not, the game creates a boss dummy.",
            Health = 260,
            DefeatedWinnerTeamId = "medina",
            DefeatedMessage = "Medina Side completes the scenario: the Quraysh commander was defeated.",
        },
        KeyFigures = {
            Medina = "Medina side: Prophet Muhammad, peace be upon him, led the Muslims but is never depicted. Companions connected to this period include Abu Bakr, Umar, Ali, Hamzah, and Bilal, may Allah be pleased with them.",
            Makkah = "Makkah Quraysh side: leaders remembered in the conflict include Abu Jahl, Umayyah ibn Khalaf, Utbah ibn Rabi'ah, and other chiefs of Quraysh.",
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
                    Title = "17 Ramadan, 2 AH | 624 CE",
                    Body = "Badr happened after the Hijrah, when the Muslims had settled in Medina and conflict with the Quraysh of Makkah was still rising.",
                    DurationSeconds = 7,
                    FieldOfView = 62,
                },
                {
                    CameraName = "BriefingMap2",
                    Title = "The Situation",
                    Body = "The young Muslim community in Medina faced pressure from Quraysh power in Makkah. Badr became the first major battle between the two sides.",
                    DurationSeconds = 8,
                    FieldOfView = 58,
                },
                {
                    CameraName = "BriefingMap3",
                    Title = "Main People To Know",
                    Body = "Medina side: the Prophet, peace be upon him, led but is not depicted. Companions such as Abu Bakr, Umar, Ali, Hamzah, and Bilal, may Allah be pleased with them, are connected to this period.",
                    DurationSeconds = 9,
                    FieldOfView = 64,
                },
                {
                    CameraName = "BriefingMap4",
                    Title = "Opposing Commanders",
                    Body = "Quraysh leaders remembered in this conflict include Abu Jahl, Umayyah ibn Khalaf, and Utbah ibn Rabi'ah. The boss role represents an opposing commander without making a sacred figure playable.",
                    DurationSeconds = 8,
                    FieldOfView = 60,
                },
                {
                    CameraName = "BriefingMap5",
                    Title = "Your Objective",
                    Body = "Fight the round, look for the Quraysh Commander boss, then watch the reenactment to connect the action to courage, preparation, unity, and gratitude.",
                    DurationSeconds = 7,
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
                    Body = "17 Ramadan, 2 AH. The valley and wells mattered because preparation and position shaped what happened before the clash.",
                    DurationSeconds = 7,
                },
                {
                    CameraName = "Scene2",
                    Title = "Standing Together",
                    Body = "The Medina side was a small, vulnerable community under pressure. The scene keeps the Prophet, peace be upon him, out of visual depiction.",
                    DurationSeconds = 8,
                },
                {
                    CameraName = "Scene3",
                    Title = "The Opposing Command",
                    Body = "The Quraysh side had powerful chiefs and confidence from Makkah. In gameplay, the commander boss gives players a clear objective.",
                    DurationSeconds = 7,
                },
                {
                    CameraName = "Scene4",
                    Title = "A Turning Point",
                    Body = "Badr raised morale and changed how the community was seen. The ending should feel like a lesson, not only a scoreboard.",
                    DurationSeconds = 7,
                },
                {
                    CameraName = "Scene5",
                    Title = "What Players Should Remember",
                    Body = "In the game you fought for fun. In the lesson, remember preparation, unity, gratitude, and responsibility after victory.",
                    DurationSeconds = 7,
                },
            },
        },
        StorySummary = {
            Title = "What Happened At Badr",
            Lines = {
                "Badr took place on 17 Ramadan, 2 AH / 624 CE and became a major victory for the early Muslim community.",
                "The battle strengthened morale and marked a turning point in the public standing of the community.",
                "This battle mode uses a commander boss objective for gameplay while the reenactment keeps the historical meaning in view.",
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
        RecommendedPlayers = 60,
        MinPlayersToLaunch = 1,
        PlayersPerTeam = 30,
        CountdownSeconds = 8,
        RoundDurationSeconds = 250,
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
        Commander = {
            TeamId = "makkah",
            DisplayName = "Quraysh Cavalry Commander",
            RoleText = "A stronger opposing-side commander role. If a player is on this side, one player becomes the commander. If not, the game creates a boss dummy.",
            Health = 280,
            DefeatedWinnerTeamId = "medina",
            DefeatedMessage = "Medina Side completes the scenario: the Quraysh cavalry commander was defeated.",
        },
        KeyFigures = {
            Medina = "Medina side: Prophet Muhammad, peace be upon him, led the Muslims but is never depicted. Companions connected to Uhud include Hamzah ibn Abd al-Muttalib, Mus'ab ibn Umayr, and Nusaybah bint Ka'b, may Allah be pleased with them.",
            Makkah = "Makkah Quraysh side: leaders and commanders connected to Uhud include Abu Sufyan and Khalid ibn al-Walid before he accepted Islam. The game uses a generic commander role instead of making them playable.",
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
                    Title = "7 Shawwal, 3 AH | 625 CE",
                    Body = "Uhud happened the year after Badr, near Mount Uhud outside Medina, as the Quraysh came again after their earlier defeat.",
                    DurationSeconds = 7,
                    FieldOfView = 62,
                },
                {
                    CameraName = "BriefingMap2",
                    Title = "The Situation",
                    Body = "The battle was connected to the continuing conflict between Makkah and Medina after Badr. Quraysh wanted to answer that loss near Medina.",
                    DurationSeconds = 8,
                    FieldOfView = 58,
                },
                {
                    CameraName = "BriefingMap3",
                    Title = "Main People To Know",
                    Body = "Medina side: the Prophet, peace be upon him, is not depicted. Companions connected to Uhud include Hamzah, Mus'ab ibn Umayr, and Nusaybah bint Ka'b, may Allah be pleased with them.",
                    DurationSeconds = 9,
                    FieldOfView = 60,
                },
                {
                    CameraName = "BriefingMap4",
                    Title = "The Mountain And Ridge",
                    Body = "The map shows Mount Uhud, the pass, and the archer ridge. This battle teaches that position and discipline can change everything.",
                    DurationSeconds = 7,
                    FieldOfView = 60,
                },
                {
                    CameraName = "BriefingMap5",
                    Title = "Your Objective",
                    Body = "Fight the round, watch for the Quraysh Cavalry Commander boss, and then study how momentum shifted near the ridge.",
                    DurationSeconds = 7,
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
                    Body = "7 Shawwal, 3 AH. The reenactment begins near Mount Uhud, where terrain and assigned positions shaped what happened next.",
                    DurationSeconds = 7,
                },
                {
                    CameraName = "Scene2",
                    Title = "The Archer Ridge",
                    Body = "A major lesson of Uhud is to hold the assigned position even when the battle seems to be going your way.",
                    DurationSeconds = 7,
                },
                {
                    CameraName = "Scene3",
                    Title = "Opposing Cavalry Pressure",
                    Body = "Quraysh cavalry pressure is represented by a commander boss in gameplay, while real historical figures are taught through text rather than made into avatars.",
                    DurationSeconds = 8,
                },
                {
                    CameraName = "Scene4",
                    Title = "A Hard Turn",
                    Body = "Momentum changed during the fighting, and the community faced a painful test near the mountain.",
                    DurationSeconds = 7,
                },
                {
                    CameraName = "Scene5",
                    Title = "The Lesson Of Uhud",
                    Body = "In the game you fought for fun. In the lesson, remember that courage must stay joined to discipline and steady judgment.",
                    DurationSeconds = 7,
                },
            },
        },
        StorySummary = {
            Title = "What Happened At Uhud",
            Lines = {
                "Uhud took place on 7 Shawwal, 3 AH / 625 CE near Mount Uhud and became a hard lesson about discipline and battlefield positioning.",
                "Early momentum shifted during the fighting, and the battle became a reminder that courage must stay tied to obedience and steady judgment.",
                "This round uses a commander boss objective for clarity, while the reenactment keeps the historical lesson connected to the gameplay.",
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
