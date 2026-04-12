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
        FillEmptySlotsWithBots = false,
        CountdownSeconds = 8,
        RoundDurationSeconds = 250,
        LearningGoal = "Teach discipline, the cost of leaving an assigned post, sacrifice under pressure, and the emotional weight of Uhud.",
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
        FinalBossPhase = {
            Enabled = true,
            Health = 420,
            DisplayNames = {
                medina = "Final Medina Defender",
                makkah = "Final Quraysh Cavalry Commander",
            },
            StartMessageTemplate = "Final phase: the %s enters the field. The surviving team must finish the battle by defeating this boss.",
            DefeatedMessageTemplate = "%s defeated the %s and secured the field at Uhud.",
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
                    Body = "Uhud happened the year after Badr, north of Medina near Mount Uhud, when Quraysh returned looking for a hard answer to their defeat at Badr.",
                    DurationSeconds = 8,
                    FieldOfView = 62,
                },
                {
                    CameraName = "BriefingMap2",
                    Title = "The Archer Order",
                    Body = "Sunan Abi Dawud 2662 reports that 'Abd Allah ibn Jubayr led fifty archers with a clear order: do not leave the ridge even if victory looks certain.",
                    DurationSeconds = 9,
                    FieldOfView = 58,
                },
                {
                    CameraName = "BriefingMap3",
                    Title = "People And Sacrifice",
                    Body = "The route around Uhud is tied to companions remembered in the reports of this battle, including Hamzah, Mus'ab ibn Umayr, and the defenders who stood firm when the field became confused.",
                    DurationSeconds = 9,
                    FieldOfView = 60,
                },
                {
                    CameraName = "BriefingMap4",
                    Title = "The Hard Turn",
                    Body = "Sahih Muslim 1789 describes the pressure of the late battle, when only a few defenders remained in a desperate stand. Uhud teaches that one broken position can change the whole field.",
                    DurationSeconds = 9,
                    FieldOfView = 60,
                },
                {
                    CameraName = "BriefingMap5",
                    Title = "Your Objective",
                    Body = "Fight for control of the pass. When one side breaks, a final boss enters the field and the surviving team must finish the battle there.",
                    DurationSeconds = 8,
                    FieldOfView = 60,
                },
            },
        },
        Reenactment = {
            IntroTitle = "Uhud Reenactment",
            Scenes = {
                {
                    CameraName = "Scene1",
                    Title = "A Mountain With Meaning",
                    Body = "Sahih al-Bukhari 4422 preserves the line that Uhud is a mountain that loves us and is loved by us. The place itself became part of the memory of the battle.",
                    DurationSeconds = 8,
                },
                {
                    CameraName = "Scene2",
                    Title = "The Ridge Must Hold",
                    Body = "Sunan Abi Dawud 2662 ties Uhud to the order given to the archers not to leave their place, even when the field looked won and the temptation of booty appeared.",
                    DurationSeconds = 9,
                },
                {
                    CameraName = "Scene3",
                    Title = "The Last Stand",
                    Body = "Sahih Muslim 1789 describes a terrible moment when only seven Ansar and two Qurashi defenders remained close in protection while the enemy pressed forward.",
                    DurationSeconds = 9,
                },
                {
                    CameraName = "Scene4",
                    Title = "Wounds And Rescue",
                    Body = "Sahih Muslim 1790a records the injuries suffered that day and the urgent effort to stop the bleeding. The battle was not a simple victory story. It was pain, rescue, and endurance.",
                    DurationSeconds = 9,
                },
                {
                    CameraName = "Scene5",
                    Title = "What Uhud Leaves Behind",
                    Body = "Sahih Muslim 940a remembers Mus'ab ibn Umayr among the martyrs of Uhud, and Sahih al-Bukhari 4081 preserves the dream of the broken sword as a sign of the believers' losses.",
                    DurationSeconds = 9,
                },
            },
        },
        StorySummary = {
            Title = "What Happened At Uhud",
            Lines = {
                "Uhud took place on 7 Shawwal, 3 AH / 625 CE near Mount Uhud and became a hard lesson in discipline and battlefield positioning.",
                "Sunan Abi Dawud 2662 preserves the order to the archers to hold their post, while Sahih Muslim 1789 records the fierce pressure of the late battle.",
                "This mode ends with a single final boss instead of filler bots, so the finish feels like one decisive last stand.",
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
