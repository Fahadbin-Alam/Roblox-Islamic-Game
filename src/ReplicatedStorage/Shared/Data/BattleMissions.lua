--!nonstrict

-- Story missions for the battle scenarios: solo or co-op, every player on the Medina side,
-- fighting generic, unnamed Quraysh soldiers controlled by the server.
--
-- Content rules for this file:
-- * The Prophet Muhammad, peace be upon him, is never shown, voiced, or represented by any
--   character. Narration may describe what happened, the way a teacher would.
-- * Named companions are not played by NPCs either. Allies and opponents are generic soldiers
--   ("Medina Fighter", "Quraysh Swordsman"); named people appear only in narration.
-- * Every narration line that states a historical detail cites its Qur'an, hadith, or sirah source.
-- * Fallen soldiers simply fade away; there is no gore.
--
-- Positions are battlefield coordinates. Their Y is ignored: the server drops every point onto
-- the ground under it, and tests/world/ checks that each point has ground and that each lane
-- can be walked in straight lines.

local BattleMissions = {}

-- Soldier types. Team "makkah" are opponents, team "medina" are allies of the players.
BattleMissions.Units = {
    Swordsman = {
        DisplayName = "Quraysh Swordsman",
        Team = "makkah",
        Style = "Melee",
        Health = 80,
        WalkSpeed = 14,
        Damage = 9,
        Reach = 6.5,
        WindupSeconds = 0.5,
        CooldownSeconds = 1.5,
        Robe = Color3.fromRGB(122, 64, 52),
        Accent = Color3.fromRGB(64, 40, 34),
        Weapon = "Sword",
    },
    Spearman = {
        DisplayName = "Quraysh Spearman",
        Team = "makkah",
        Style = "Melee",
        Health = 95,
        WalkSpeed = 13,
        Damage = 11,
        Reach = 8.5,
        WindupSeconds = 0.62,
        CooldownSeconds = 1.8,
        Robe = Color3.fromRGB(110, 78, 50),
        Accent = Color3.fromRGB(58, 44, 32),
        Weapon = "Spear",
    },
    Archer = {
        DisplayName = "Quraysh Archer",
        Team = "makkah",
        Style = "Ranged",
        Health = 60,
        WalkSpeed = 13,
        Damage = 8,
        Reach = 95,
        MinRange = 26,
        WindupSeconds = 0.9,
        CooldownSeconds = 2.4,
        Robe = Color3.fromRGB(132, 92, 60),
        Accent = Color3.fromRGB(70, 48, 36),
        Weapon = "Bow",
    },
    Raider = {
        DisplayName = "Quraysh Flank Rider",
        Team = "makkah",
        Style = "Melee",
        Health = 90,
        WalkSpeed = 21,
        Damage = 11,
        Reach = 7,
        WindupSeconds = 0.45,
        CooldownSeconds = 1.4,
        Robe = Color3.fromRGB(86, 52, 46),
        Accent = Color3.fromRGB(40, 30, 28),
        Weapon = "Spear",
    },
    Captain = {
        DisplayName = "Quraysh Vanguard Captain",
        Team = "makkah",
        Style = "Melee",
        Health = 520,
        WalkSpeed = 13,
        Damage = 16,
        Reach = 7.5,
        WindupSeconds = 0.7,
        CooldownSeconds = 1.6,
        Robe = Color3.fromRGB(96, 40, 38),
        Accent = Color3.fromRGB(193, 162, 86),
        Weapon = "Sword",
        Boss = true,
        Scale = 1.2,
    },
    AllyFighter = {
        DisplayName = "Medina Fighter",
        Team = "medina",
        Style = "Melee",
        Health = 170,
        WalkSpeed = 15,
        Damage = 10,
        Reach = 6.5,
        WindupSeconds = 0.5,
        CooldownSeconds = 1.6,
        Robe = Color3.fromRGB(226, 220, 204),
        Accent = Color3.fromRGB(62, 125, 82),
        Weapon = "Sword",
    },
    AllyArcher = {
        DisplayName = "Medina Archer",
        Team = "medina",
        Style = "Ranged",
        Health = 120,
        WalkSpeed = 14,
        Damage = 8,
        Reach = 100,
        MinRange = 18,
        WindupSeconds = 0.9,
        CooldownSeconds = 2.6,
        Robe = Color3.fromRGB(214, 206, 186),
        Accent = Color3.fromRGB(48, 108, 70),
        Weapon = "Bow",
    },
}

BattleMissions.Missions = {
    badr = {
        Id = "badr",
        DisplayName = "Battle of Badr",
        Subtitle = "17 Ramadan, 2 AH | 624 CE",
        MaxPlayers = 8,
        RespawnSeconds = 4,
        TimeLimitSeconds = 900,
        Layout = {
            Points = {
                Camp = Vector3.new(-1470, 0, 630),
                Wells = Vector3.new(-1215, 0, 706),
                Banner = Vector3.new(-1252, 0, 700),
                Line = Vector3.new(-1268, 0, 706),
            },
            SpawnFacing = Vector3.new(-1215, 0, 706),
            Lanes = {
                North = {
                    Vector3.new(-870, 0, 630),
                    Vector3.new(-1150, 0, 630),
                    Vector3.new(-1205, 0, 688),
                },
                South = {
                    Vector3.new(-880, 0, 750),
                    Vector3.new(-1180, 0, 750),
                    Vector3.new(-1212, 0, 722),
                },
            },
            -- Straight walks a player is expected to make between objectives.
            Routes = {
                { From = "Camp", To = "Wells" },
                { From = "Wells", To = "Camp" },
            },
        },
        Allies = {
            { Unit = "AllyFighter", Count = 5, Point = "Line" },
        },
        Objectives = {
            {
                Id = "march",
                Type = "Reach",
                Title = "March To The Wells",
                Instruction = "Lead the way east to the wells of Badr.",
                Zone = "Wells",
                Radius = 34,
                AllyPoint = "Line",
                Narration = {
                    Title = "The Small Army",
                    Body = "About three hundred and thirteen believers came to Badr, facing a Quraysh army roughly three times larger.",
                    Reference = "Sahih al-Bukhari 3959",
                },
            },
            {
                Id = "wells",
                Type = "Hold",
                Title = "Secure The Wells",
                Instruction = "Stand inside the ring by the wells. Quraysh scouts will try to push you off.",
                Zone = "Wells",
                Radius = 34,
                Seconds = 40,
                AllyPoint = "Wells",
                Narration = {
                    Title = "Taking The Wells",
                    Body = "The sirah reports that the companion al-Hubab ibn al-Mundhir advised camping by the nearest well, so the army would hold the water.",
                    Reference = "Sirat Ibn Hisham",
                },
                Waves = {
                    { AtSecond = 2, Spawns = { { Unit = "Swordsman", Count = 2, PerExtraPlayer = 1, Lane = "North" } } },
                    { AtSecond = 16, Spawns = { { Unit = "Swordsman", Count = 2, PerExtraPlayer = 1, Lane = "South" } } },
                    { AtSecond = 28, Spawns = { { Unit = "Archer", Count = 1, PerExtraPlayer = 1, Lane = "North" } } },
                },
            },
            {
                Id = "rain",
                Type = "Narration",
                Title = "Rain And Calm",
                Instruction = "Rest a moment. Your strength returns.",
                Seconds = 9,
                HealPlayers = true,
                ClearEnemies = true,
                AllyPoint = "Line",
                Narration = {
                    Title = "Rain Before The Battle",
                    Body = "Allah sent rest over the believers and rain from the sky to purify them and make their footing firm.",
                    Reference = "Qur'an 8:11",
                },
            },
            {
                Id = "line",
                Type = "Defend",
                Title = "Hold The Line",
                Instruction = "Protect the banner of the Medina line until every wave is driven back.",
                Target = "Banner",
                TargetHealth = 600,
                AllyPoint = "Line",
                Narration = {
                    Title = "Stand Firm",
                    Body = "When you meet a force, stand firm and remember Allah much. Obey, do not dispute with one another, and be patient.",
                    Reference = "Qur'an 8:45-46",
                },
                Waves = {
                    { AtSecond = 2, Spawns = {
                        { Unit = "Swordsman", Count = 3, PerExtraPlayer = 1, Lane = "North" },
                        { Unit = "Spearman", Count = 1, PerExtraPlayer = 1, Lane = "South" },
                    } },
                    { AfterCleared = true, Spawns = {
                        { Unit = "Spearman", Count = 2, PerExtraPlayer = 1, Lane = "North" },
                        { Unit = "Swordsman", Count = 2, PerExtraPlayer = 1, Lane = "South" },
                        { Unit = "Archer", Count = 1, PerExtraPlayer = 0.5, Lane = "South" },
                    } },
                    { AfterCleared = true, Spawns = {
                        { Unit = "Swordsman", Count = 3, PerExtraPlayer = 1, Lane = "South" },
                        { Unit = "Spearman", Count = 2, PerExtraPlayer = 1, Lane = "North" },
                        { Unit = "Archer", Count = 2, PerExtraPlayer = 0.5, Lane = "North" },
                    } },
                },
            },
            {
                Id = "captain",
                Type = "Defeat",
                Title = "Break The Advance",
                Instruction = "The Quraysh vanguard makes a final push. Defeat its captain and his guard.",
                AllyPoint = "Wells",
                Narration = {
                    Title = "The Opening Duels",
                    Body = "Before the main clash, Hamzah, 'Ali, and 'Ubaydah ibn al-Harith answered the Quraysh challenge to single combat. The verse 'These are two opponents' was revealed about that day.",
                    Reference = "Sahih al-Bukhari 3965 · Qur'an 22:19",
                },
                Waves = {
                    { AtSecond = 1, Spawns = {
                        { Unit = "Captain", Count = 1, Lane = "North" },
                        { Unit = "Swordsman", Count = 2, PerExtraPlayer = 1, Lane = "North" },
                        { Unit = "Spearman", Count = 2, PerExtraPlayer = 1, Lane = "South" },
                    } },
                },
            },
            {
                Id = "mercy",
                Type = "Reach",
                Title = "Mercy After Victory",
                Instruction = "Return to the Medina camp in the west.",
                Zone = "Camp",
                Radius = 30,
                ClearEnemies = true,
                AllyPoint = "Camp",
                Narration = {
                    Title = "How The Captives Were Treated",
                    Body = "Captives who could not pay a ransom could earn their freedom by teaching the children of Medina to read and write.",
                    Reference = "Musnad Ahmad 2216 · Qur'an 8:70",
                },
            },
        },
        Steadfast = {
            Label = "Banner kept above half strength",
            Kind = "TargetHealth",
            Objective = "line",
            Fraction = 0.5,
        },
        Reflection = {
            {
                Id = "badr_stand_firm",
                Prompt = "What did Qur'an 8:45-46 tell the believers to do when they meet an army?",
                Choices = {
                    "Wait for the other side to leave",
                    "Stand firm, remember Allah, obey, and not dispute",
                    "Each person should fight their own way",
                },
            },
            {
                Id = "badr_numbers",
                Prompt = "About how many believers fought at Badr?",
                Choices = { "About 10,000", "About 3,000", "About 313" },
            },
            {
                Id = "badr_captives",
                Prompt = "How could some captives of Badr earn their freedom?",
                Choices = { "By leaving Arabia", "There was no way", "By teaching children to read and write" },
            },
        },
    },
    uhud = {
        Id = "uhud",
        DisplayName = "Battle of Uhud",
        Subtitle = "Shawwal, 3 AH | 625 CE",
        MaxPlayers = 8,
        RespawnSeconds = 4,
        TimeLimitSeconds = 960,
        Layout = {
            Points = {
                Camp = Vector3.new(-1430, 0, 1272),
                Line = Vector3.new(-1395, 0, 1270),
                HillTop = Vector3.new(-1470, 0, 1357),
                HillFoot = Vector3.new(-1470, 0, 1300),
                Spoils = Vector3.new(-1330, 0, 1300),
                RampFoot = Vector3.new(-1540, 0, 1306),
                Rally = Vector3.new(-1540, 0, 1195),
            },
            SpawnFacing = Vector3.new(-1150, 0, 1260),
            Lanes = {
                Front = {
                    Vector3.new(-1165, 0, 1272),
                    Vector3.new(-1375, 0, 1272),
                },
                FrontSouth = {
                    Vector3.new(-1170, 0, 1290),
                    Vector3.new(-1330, 0, 1296),
                    Vector3.new(-1420, 0, 1296),
                },
                Flank = {
                    Vector3.new(-1560, 0, 1440),
                    Vector3.new(-1530, 0, 1312),
                    Vector3.new(-1440, 0, 1286),
                },
                Mountain = {
                    Vector3.new(-1165, 0, 1272),
                    Vector3.new(-1395, 0, 1288),
                    Vector3.new(-1540, 0, 1304),
                    Vector3.new(-1540, 0, 1210),
                },
                MountainFlank = {
                    Vector3.new(-1560, 0, 1440),
                    Vector3.new(-1540, 0, 1304),
                    Vector3.new(-1540, 0, 1210),
                },
            },
            Routes = {
                { From = "Camp", To = "HillFoot" },
                { From = "HillFoot", To = "HillTop" },
                { From = "HillTop", To = "HillFoot" },
                { From = "HillFoot", To = "Spoils" },
                { From = "Spoils", To = "RampFoot" },
                { From = "HillFoot", To = "RampFoot" },
                { From = "RampFoot", To = "Rally" },
            },
        },
        -- The Archers' Hill and the path up the slope of Uhud are built only for this layout.
        Structures = {
            ArchersHill = { Center = Vector3.new(-1470, 0, 1357), Size = Vector3.new(46, 14, 40), Slope = 26 },
            -- A rock shelf against the west face of the mountain, reached by a path from the field.
            MountainShelf = { Center = Vector3.new(-1540, 0, 1198), Size = Vector3.new(60, 30, 72), PathWidth = 24, PathRun = 62 },
        },
        Allies = {
            { Unit = "AllyFighter", Count = 4, Point = "Line" },
            { Unit = "AllyArcher", Count = 4, Point = "HillTop", Tag = "HillArcher" },
        },
        Objectives = {
            {
                Id = "post",
                Type = "Reach",
                Title = "Take Your Post",
                Instruction = "Climb the Archers' Hill south-west of the camp. Use the slope on its north side.",
                Zone = "HillTop",
                Radius = 22,
                AllyPoint = "Line",
                Narration = {
                    Title = "The Order To The Archers",
                    Body = "Fifty archers under 'Abdullah ibn Jubayr were placed on the hill and told: do not leave your place, even if you see birds snatching us, until you are sent for.",
                    Reference = "Sahih al-Bukhari 3039",
                },
            },
            {
                Id = "cover",
                Type = "Defeat",
                Title = "Cover The Line",
                Instruction = "Stay on the hill and drive back the Quraysh advance with your bow.",
                RespawnPoint = "HillFoot",
                Zone = "HillTop",
                Radius = 22,
                AllyPoint = "Line",
                Narration = {
                    Title = "Early Success",
                    Body = "Allah fulfilled His promise to you when you were defeating them by His permission.",
                    Reference = "Qur'an 3:152",
                },
                Waves = {
                    { AtSecond = 1, Spawns = {
                        { Unit = "Swordsman", Count = 3, PerExtraPlayer = 1, Lane = "Front" },
                        { Unit = "Spearman", Count = 2, PerExtraPlayer = 1, Lane = "FrontSouth" },
                    } },
                    { AfterCleared = true, Spawns = {
                        { Unit = "Swordsman", Count = 3, PerExtraPlayer = 1, Lane = "FrontSouth" },
                        { Unit = "Archer", Count = 2, PerExtraPlayer = 0.5, Lane = "Front" },
                    } },
                },
            },
            {
                Id = "spoils",
                Type = "Discipline",
                Title = "The Test Of The Spoils",
                Instruction = "The field looks won and spoils lie below. Your order is to stay on the hill.",
                Zone = "HillTop",
                Radius = 22,
                Seconds = 25,
                ClearEnemies = true,
                AllyPoint = "Line",
                -- Most of the hill archers leave, as the report describes.
                DesertingAllies = { Tag = "HillArcher", Keep = 1, To = "Spoils" },
                Narration = {
                    Title = "\"The Spoils!\"",
                    Body = "When the archers saw the enemy fleeing, most of them said 'The spoils!' Their commander reminded them of the order, but they left the hill anyway.",
                    Reference = "Sahih al-Bukhari 3039",
                },
            },
            {
                Id = "flank",
                Type = "Defeat",
                Title = "The Flank Turns",
                Instruction = "Riders sweep around the hill from behind. Hold together and drive them off.",
                AllyPoint = "Line",
                Narration = {
                    Title = "From Behind The Hill",
                    Body = "Among you were some who desired this world and some who desired the Hereafter. Then He turned you back from them to test you.",
                    Reference = "Qur'an 3:152",
                },
                Waves = {
                    { AtSecond = 1, Spawns = {
                        { Unit = "Raider", Count = 4, PerExtraPlayer = 1, Lane = "Flank" },
                        { Unit = "Swordsman", Count = 2, PerExtraPlayer = 1, Lane = "Front" },
                    } },
                    { AtSecond = 12, Spawns = {
                        { Unit = "Raider", Count = 2, PerExtraPlayer = 1, Lane = "Flank" },
                    } },
                },
                -- Leaving the hill during the test of the spoils brings a larger flank attack.
                BrokenOrderExtra = { { Unit = "Raider", Count = 3, PerExtraPlayer = 1, Lane = "Flank" } },
            },
            {
                Id = "climb",
                Type = "Reach",
                Title = "Climb The Slope Of Uhud",
                Instruction = "Regroup on the mountain. Take the stone path up to the shelf in the north-west.",
                Zone = "Rally",
                Radius = 24,
                AllyPoint = "Rally",
                Narration = {
                    Title = "Up The Mountain",
                    Body = "You were climbing and not looking back at anyone, while the Messenger was calling you from behind.",
                    Reference = "Qur'an 3:153",
                },
            },
            {
                Id = "mountain",
                Type = "Hold",
                Title = "Hold The Mountain Path",
                Instruction = "Hold the ground on the slope until the attack breaks.",
                RespawnPoint = "Rally",
                Zone = "Rally",
                Radius = 24,
                Seconds = 50,
                AllyPoint = "Rally",
                Narration = {
                    Title = "The Few Who Stood",
                    Body = "When the pressure closed in, a small group of the Ansar stood their ground one after another to protect the Messenger of Allah, peace be upon him.",
                    Reference = "Sahih Muslim 1789",
                },
                Waves = {
                    { AtSecond = 3, Spawns = {
                        { Unit = "Swordsman", Count = 3, PerExtraPlayer = 1, Lane = "Mountain" },
                        { Unit = "Spearman", Count = 1, PerExtraPlayer = 1, Lane = "MountainFlank" },
                    } },
                    { AtSecond = 20, Spawns = {
                        { Unit = "Raider", Count = 2, PerExtraPlayer = 1, Lane = "MountainFlank" },
                        { Unit = "Archer", Count = 1, PerExtraPlayer = 0.5, Lane = "Mountain" },
                    } },
                    { AtSecond = 34, Spawns = {
                        { Unit = "Swordsman", Count = 2, PerExtraPlayer = 1, Lane = "Mountain" },
                        { Unit = "Spearman", Count = 2, PerExtraPlayer = 1, Lane = "MountainFlank" },
                    } },
                },
            },
            {
                Id = "withdraw",
                Type = "Narration",
                Title = "The Quraysh Withdraw",
                Instruction = "The attack breaks and Quraysh turn back toward Makkah.",
                RespawnPoint = "Rally",
                Seconds = 10,
                ClearEnemies = true,
                HealPlayers = true,
                AllyPoint = "Rally",
                Narration = {
                    Title = "Do Not Weaken",
                    Body = "Do not weaken and do not grieve, for you will be superior if you are believers. Those who answered Allah and the Messenger after being wounded have a great reward.",
                    Reference = "Qur'an 3:139 · Qur'an 3:172",
                },
            },
        },
        Steadfast = {
            Label = "Every player kept their post on the hill",
            Kind = "Discipline",
            Objective = "spoils",
        },
        Reflection = {
            {
                Id = "uhud_order",
                Prompt = "What order were the archers given at Uhud?",
                Choices = {
                    "Join the fighting once it looks won",
                    "Stay on the hill no matter what, until sent for",
                    "Collect the spoils first",
                },
            },
            {
                Id = "uhud_turn",
                Prompt = "What turned the battle at Uhud?",
                Choices = {
                    "Most archers left their post for the spoils",
                    "The Muslims ran out of water",
                    "A storm stopped the fighting",
                },
            },
            {
                Id = "uhud_lesson",
                Prompt = "What does Qur'an 3:139 tell the believers after Uhud?",
                Choices = { "Never fight again", "Blame one another", "Do not weaken and do not grieve" },
            },
        },
    },
}

BattleMissions.Order = { "badr", "uhud" }

function BattleMissions.Get(scenarioId: string)
    return (BattleMissions.Missions :: any)[scenarioId]
end

return BattleMissions
