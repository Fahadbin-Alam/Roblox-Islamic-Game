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
                    Title = "Dawn At Uhud | 3 AH / 625 CE",
                    Body = "Qur'an 3:121 remembers the believers being placed into battle positions. This opening view frames Mount Uhud, the approaches from Medina, and the ground where the lines were formed before the clash.",
                    DurationSeconds = 8,
                    FieldOfView = 62,
                    Reference = "Qur'an 3:121 · Quran.com",
                },
                {
                    CameraName = "BriefingMap2",
                    Title = "The Archer Ridge Must Hold",
                    Body = "Sunan Abi Dawud 2662 reports that 'Abd Allah ibn Jubayr led fifty archers with a strict order: hold the ridge and do not leave, even if the battlefield appears won.",
                    DurationSeconds = 9,
                    FieldOfView = 58,
                    Reference = "Sunan Abi Dawud 2662 · Sunnah.com",
                },
                {
                    CameraName = "BriefingMap3",
                    Title = "Early Pressure On Quraysh",
                    Body = "Qur'an 3:152 describes the early stage when victory seemed within reach. In the game camera pass, the Medina line pushes forward while the ridge still protects the flank.",
                    DurationSeconds = 9,
                    FieldOfView = 60,
                    Reference = "Qur'an 3:152 · Quran.com",
                },
                {
                    CameraName = "BriefingMap4",
                    Title = "The Turn In The Field",
                    Body = "Qur'an 3:152-153 links the setback to dispute and disobedience after success. Once the ridge opened, the field broke, people ran uphill in confusion, and the battle changed in moments.",
                    DurationSeconds = 9,
                    FieldOfView = 60,
                    Reference = "Qur'an 3:152-153 · Quran.com",
                },
                {
                    CameraName = "BriefingMap5",
                    Title = "Wounds And Protection",
                    Body = "Sahih Muslim 1790a records the injuries of that day: the Messenger of Allah, peace be upon him, was wounded, and Fatimah and 'Ali worked urgently to stop the bleeding.",
                    DurationSeconds = 8,
                    FieldOfView = 60,
                    Reference = "Sahih Muslim 1790a · Sunnah.com",
                },
                {
                    CameraName = "BriefingMap6",
                    Title = "After The Shock",
                    Body = "Qur'an 3:172 and Sahih al-Bukhari 4077 preserve that wounded believers still answered the call after Uhud. The lesson is not surface-level victory, but obedience, endurance, and return after pain.",
                    DurationSeconds = 9,
                    FieldOfView = 57,
                    Reference = "Qur'an 3:172 · Sahih al-Bukhari 4077",
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
                    Reference = "Sahih al-Bukhari 4422 · Sunnah.com",
                },
                {
                    CameraName = "Scene2",
                    Title = "Stations For Battle",
                    Body = "Qur'an 3:121 recalls the believers being placed into battle positions. This scene turns from the mountain face to the ridge and pass so players can connect the reports to the actual terrain.",
                    DurationSeconds = 9,
                    Reference = "Qur'an 3:121 · Quran.com",
                },
                {
                    CameraName = "Scene3",
                    Title = "The Ridge Must Hold",
                    Body = "Sunan Abi Dawud 2662 ties Uhud to the order given to the archers not to leave their place, even when the field looked won and the temptation of booty appeared.",
                    DurationSeconds = 9,
                    Reference = "Sunan Abi Dawud 2662 · Sunnah.com",
                },
                {
                    CameraName = "Scene4",
                    Title = "Confusion And The Uphill Flight",
                    Body = "Qur'an 3:153 describes the believers climbing and not looking back while the Messenger called from behind. Sahih Muslim 1789 remembers how fiercely the pressure closed in during the late battle.",
                    DurationSeconds = 9,
                    Reference = "Qur'an 3:153 · Sahih Muslim 1789",
                },
                {
                    CameraName = "Scene5",
                    Title = "Wounds And Rescue",
                    Body = "Sahih Muslim 1790a records the injuries suffered that day and the urgent effort to stop the bleeding. Uhud is taught here as pain, rescue, loss, and steadfast protection under pressure.",
                    DurationSeconds = 9,
                    Reference = "Sahih Muslim 1790a · Sunnah.com",
                },
                {
                    CameraName = "Scene6",
                    Title = "Martyrs, Grief, And Response",
                    Body = "Sahih Muslim 940a remembers Mus'ab ibn Umayr among the martyrs of Uhud. Qur'an 3:169 and 3:172 turn the lesson toward honor, patience, and answering again after being wounded.",
                    DurationSeconds = 9,
                    Reference = "Qur'an 3:169-172 · Sahih Muslim 940a",
                },
            },
        },
        StorySummary = {
            Title = "What Happened At Uhud",
            Lines = {
                "Qur'an 3:121, 3:152, and 3:153 frame Uhud through placement, early success, disobedience, confusion, and the cost of a broken position.",
                "Sunan Abi Dawud 2662 preserves the command to the archers, while Sahih Muslim 1789 and 1790a preserve the pressure, wounds, and rescue of the late battle.",
                "Uhud now runs as a player-only battle with no filler bots, so the focus stays on the field, the ridge, and the lesson itself.",
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
