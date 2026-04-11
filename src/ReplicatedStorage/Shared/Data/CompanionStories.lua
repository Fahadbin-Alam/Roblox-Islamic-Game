--!strict

local CompanionStories = {
    {
        Id = "bilal_ibn_rabah",
        DisplayName = "Bilal ibn Rabah (RA)",
        Theme = "Perseverance and faith",
        Summary = "Walk through Bilal's early faith, service to the community, and lasting resilience.",
        Difficulty = "Beginner",
        AccentColor = Color3.fromRGB(101, 78, 49),
        KeyLessons = {
            "Perseverance",
            "Faith under pressure",
            "Service to the community",
        },
        Introduction = {
            "Begin in Makkah and follow Bilal's path from hardship to honor in the Muslim community.",
            "Talk to the guides at each station to unlock the next part of the journey.",
        },
        ScenarioSteps = {
            {
                Id = "early_faith",
                Title = "Early Faith In Makkah",
                Objective = "Speak to the market guide to learn how Bilal accepted Islam.",
                NpcName = "Makkah Story Guide",
                PromptText = "Talk",
                LocationName = "Makkah Market Court",
                Dialogue = {
                    { Speaker = "Guide", Text = "Bilal was among the early people who believed in Islam in Makkah." },
                    { Speaker = "Guide", Text = "He stayed firm even when his master punished him and tried to force him to turn away." },
                    { Speaker = "Bilal's Story", Text = "His faith became an example of patience and trust in Allah." },
                },
            },
            {
                Id = "steadfastness",
                Title = "Steadfastness",
                Objective = "Go to the shaded courtyard and hear how Bilal stayed steadfast through hardship.",
                NpcName = "Courtyard Elder",
                PromptText = "Listen",
                LocationName = "Courtyard of Patience",
                Dialogue = {
                    { Speaker = "Elder", Text = "Bilal is remembered for repeating words of tawhid while enduring severe hardship." },
                    { Speaker = "Elder", Text = "His story teaches players that dignity and faith are not taken away by pressure." },
                    { Speaker = "Narrator", Text = "Steadfast hearts often change the future of a community." },
                },
            },
            {
                Id = "community_service",
                Title = "Serving The Community",
                Objective = "Walk to the masjid court and learn how Bilal served the growing Muslim community.",
                NpcName = "Masjid Caretaker",
                PromptText = "Learn",
                LocationName = "Masjid Court",
                Dialogue = {
                    { Speaker = "Caretaker", Text = "Bilal became known for his beautiful call to prayer and his service among the believers." },
                    { Speaker = "Caretaker", Text = "In the game, this station reminds players that strength is not only on the battlefield." },
                    { Speaker = "Narrator", Text = "Service, loyalty, and consistency made Bilal beloved in the community." },
                },
            },
            {
                Id = "legacy",
                Title = "Bilal's Legacy",
                Objective = "Reach the reflection garden and hear the final lesson from Bilal's journey.",
                NpcName = "Reflection Guide",
                PromptText = "Reflect",
                LocationName = "Reflection Garden",
                Dialogue = {
                    { Speaker = "Guide", Text = "Bilal lived on after the earliest battles and remained honored for his faith and sincerity." },
                    { Speaker = "Guide", Text = "He is remembered as one of the best-known voices of the early Muslim community." },
                    { Speaker = "Reflection", Text = "The lasting lesson is courage with humility and service." },
                },
            },
        },
        Completion = {
            Title = "Bilal Story Complete",
            Lines = {
                "Bilal's journey teaches resilience, faith, and service.",
                "You completed the Bilal ibn Rabah playthrough.",
            },
        },
        LinkedBattles = {
            "badr",
        },
        RewardTokens = 40,
    },
    {
        Id = "musab_ibn_umayr",
        DisplayName = "Mus'ab ibn Umayr (RA)",
        Theme = "Sacrifice and leadership",
        Summary = "Travel through Mus'ab's conversion, teaching mission, and sacrifice at Uhud.",
        Difficulty = "Intermediate",
        AccentColor = Color3.fromRGB(95, 91, 58),
        KeyLessons = {
            "Sacrifice",
            "Leadership",
            "Teaching others",
        },
        Introduction = {
            "This story follows Mus'ab from the comfort of Makkah to the mission of teaching Islam in Yathrib.",
            "Each stop focuses on a moment that made him one of the great teachers of the early community.",
        },
        ScenarioSteps = {
            {
                Id = "private_conversion",
                Title = "A Quiet Conversion",
                Objective = "Speak to the house guide to learn how Mus'ab accepted Islam.",
                NpcName = "House Guide",
                PromptText = "Enter",
                LocationName = "Private Courtyard",
                Dialogue = {
                    { Speaker = "Guide", Text = "Mus'ab was known for comfort and refinement before Islam reached his heart." },
                    { Speaker = "Guide", Text = "After hearing the message, he chose faith even though it cost him ease and status." },
                    { Speaker = "Narrator", Text = "The first lesson of Mus'ab's life is that truth can demand sacrifice." },
                },
            },
            {
                Id = "teacher_of_medina",
                Title = "Teacher Of Medina",
                Objective = "Visit the teaching hall and hear how Mus'ab taught the people of Yathrib.",
                NpcName = "Teaching Elder",
                PromptText = "Study",
                LocationName = "Teaching Hall",
                Dialogue = {
                    { Speaker = "Elder", Text = "Mus'ab was sent ahead to Yathrib to teach Islam and help prepare the city for the Hijrah." },
                    { Speaker = "Elder", Text = "He taught with wisdom, patience, and strong character." },
                    { Speaker = "Narrator", Text = "This is why he is remembered as one of the first great teachers in Medina." },
                },
            },
            {
                Id = "banner_bearer",
                Title = "Banner Bearer",
                Objective = "Climb to the ridge and learn about Mus'ab carrying the banner in battle.",
                NpcName = "Battle Guide",
                PromptText = "Hear Story",
                LocationName = "Banner Ridge",
                Dialogue = {
                    { Speaker = "Battle Guide", Text = "Mus'ab carried the banner in battle and stood firm when the fighting became difficult." },
                    { Speaker = "Battle Guide", Text = "His courage showed leadership through action, not only words." },
                    { Speaker = "Narrator", Text = "Players see that teaching and bravery can live in the same person." },
                },
            },
            {
                Id = "martyrdom",
                Title = "A Lasting Sacrifice",
                Objective = "Reach the remembrance court to reflect on Mus'ab's martyrdom at Uhud.",
                NpcName = "Remembrance Guide",
                PromptText = "Reflect",
                LocationName = "Remembrance Court",
                Dialogue = {
                    { Speaker = "Guide", Text = "Mus'ab was martyred at Uhud after a life of sacrifice and service." },
                    { Speaker = "Guide", Text = "His story is remembered because he gave up comfort, then gave his effort, and finally gave his life." },
                    { Speaker = "Reflection", Text = "Mus'ab teaches sincere leadership and sacrifice for the truth." },
                },
            },
        },
        Completion = {
            Title = "Mus'ab Story Complete",
            Lines = {
                "Mus'ab ibn Umayr is remembered for sacrifice, teaching, and courage.",
                "You completed the Mus'ab ibn Umayr playthrough.",
            },
        },
        LinkedBattles = {
            "uhud",
        },
        RewardTokens = 45,
    },
    {
        Id = "nusaybah_bint_kaab",
        DisplayName = "Nusaybah bint Ka'b (RA)",
        Theme = "Courage and protection",
        Summary = "Play through Nusaybah's courage, service, and defense of the community.",
        Difficulty = "Intermediate",
        AccentColor = Color3.fromRGB(73, 111, 76),
        KeyLessons = {
            "Courage",
            "Protection",
            "Commitment",
        },
        Introduction = {
            "Walk through a story of courage and loyalty with Nusaybah bint Ka'b.",
            "This route focuses on service, bravery, and standing firm when the community needed protection.",
        },
        ScenarioSteps = {
            {
                Id = "pledge_and_commitment",
                Title = "Commitment To The Cause",
                Objective = "Talk to the family elder to learn about Nusaybah's commitment to Islam.",
                NpcName = "Family Elder",
                PromptText = "Talk",
                LocationName = "Family Courtyard",
                Dialogue = {
                    { Speaker = "Elder", Text = "Nusaybah became known among the Ansar for firm commitment and loyalty." },
                    { Speaker = "Elder", Text = "She is remembered as one of the courageous companions who supported the Muslim community." },
                    { Speaker = "Narrator", Text = "Her story begins with sincere faith and readiness to serve." },
                },
            },
            {
                Id = "service",
                Title = "Service In The Community",
                Objective = "Visit the aid station and hear about serving and supporting others.",
                NpcName = "Aid Guide",
                PromptText = "Serve",
                LocationName = "Aid Station",
                Dialogue = {
                    { Speaker = "Aid Guide", Text = "Nusaybah's story includes service, family commitment, and strong support for the believers." },
                    { Speaker = "Aid Guide", Text = "Great courage is often built from everyday loyalty and service." },
                    { Speaker = "Narrator", Text = "This station connects bravery to care, readiness, and responsibility." },
                },
            },
            {
                Id = "uhud_defense",
                Title = "Defense At Uhud",
                Objective = "Move to the defense line and learn why Nusaybah is remembered at Uhud.",
                NpcName = "Defense Guide",
                PromptText = "Stand Firm",
                LocationName = "Defense Line",
                Dialogue = {
                    { Speaker = "Defense Guide", Text = "At Uhud, Nusaybah became famous for defending the Messenger's side during a difficult moment." },
                    { Speaker = "Defense Guide", Text = "Her courage made her one of the most memorable figures of that battle." },
                    { Speaker = "Narrator", Text = "Players are meant to feel the urgency of protection and commitment here." },
                },
            },
            {
                Id = "later_life",
                Title = "A Life Of Commitment",
                Objective = "Finish at the remembrance canopy and hear the final lesson from her life.",
                NpcName = "Remembrance Guide",
                PromptText = "Reflect",
                LocationName = "Remembrance Canopy",
                Dialogue = {
                    { Speaker = "Guide", Text = "Nusaybah remained known for courage and commitment beyond a single moment on the battlefield." },
                    { Speaker = "Guide", Text = "Her story reminds players that bravery can belong to those who protect faith, family, and community." },
                    { Speaker = "Reflection", Text = "The lesson of Nusaybah is courage joined with loyalty." },
                },
            },
        },
        Completion = {
            Title = "Nusaybah Story Complete",
            Lines = {
                "Nusaybah bint Ka'b is remembered for courage, protection, and loyalty.",
                "You completed the Nusaybah bint Ka'b playthrough.",
            },
        },
        LinkedBattles = {
            "uhud",
        },
        RewardTokens = 45,
    },
    {
        Id = "umar_ibn_al_khattab",
        DisplayName = "Umar ibn al-Khattab (RA)",
        Theme = "Justice and strength",
        Summary = "Experience Umar's turning point, public strength, justice, and lasting legacy.",
        Difficulty = "Intermediate",
        AccentColor = Color3.fromRGB(82, 90, 99),
        KeyLessons = {
            "Justice",
            "Discipline",
            "Strength with principle",
        },
        Introduction = {
            "This story route explores Umar's change, leadership, and reputation for justice.",
            "Move from the moment of turning to the legacy of principled strength.",
        },
        ScenarioSteps = {
            {
                Id = "turning_point",
                Title = "A Turning Point",
                Objective = "Speak to the street guide to learn about Umar's change of heart.",
                NpcName = "Street Guide",
                PromptText = "Hear Story",
                LocationName = "Stone Street",
                Dialogue = {
                    { Speaker = "Guide", Text = "Umar is remembered for a powerful turning point that brought him into Islam." },
                    { Speaker = "Guide", Text = "His strength, once feared, later became a source of support for the Muslim community." },
                    { Speaker = "Narrator", Text = "The story begins with change, humility, and truth." },
                },
            },
            {
                Id = "public_strength",
                Title = "Strength In Public",
                Objective = "Walk to the gate court and hear how Umar stood openly with the believers.",
                NpcName = "Gate Elder",
                PromptText = "Listen",
                LocationName = "Gate Court",
                Dialogue = {
                    { Speaker = "Elder", Text = "Umar became known for visible strength and confidence once he embraced Islam." },
                    { Speaker = "Elder", Text = "Players learn here that strong personalities can become forces for good when guided by principle." },
                    { Speaker = "Narrator", Text = "Public courage can help protect a growing community." },
                },
            },
            {
                Id = "justice",
                Title = "Justice And Responsibility",
                Objective = "Visit the justice court and hear why Umar is remembered for fairness.",
                NpcName = "Justice Guide",
                PromptText = "Learn",
                LocationName = "Justice Court",
                Dialogue = {
                    { Speaker = "Justice Guide", Text = "Umar is widely remembered for justice, discipline, and responsibility." },
                    { Speaker = "Justice Guide", Text = "His legacy shows that power must be tied to fairness and accountability." },
                    { Speaker = "Narrator", Text = "This station turns strength into a lesson about responsibility." },
                },
            },
            {
                Id = "legacy",
                Title = "A Lasting Legacy",
                Objective = "Reach the legacy hall and hear the final lesson from Umar's life.",
                NpcName = "Legacy Guide",
                PromptText = "Reflect",
                LocationName = "Legacy Hall",
                Dialogue = {
                    { Speaker = "Guide", Text = "Umar died later in Medina after a life remembered for leadership, strength, and justice." },
                    { Speaker = "Guide", Text = "His story remains one of disciplined power used with responsibility." },
                    { Speaker = "Reflection", Text = "The lasting lesson is that justice must stay at the center of strength." },
                },
            },
        },
        Completion = {
            Title = "Umar Story Complete",
            Lines = {
                "Umar ibn al-Khattab is remembered for justice, strength, and responsibility.",
                "You completed the Umar ibn al-Khattab playthrough.",
            },
        },
        LinkedBattles = {
            "badr",
        },
        RewardTokens = 45,
    },
}

return table.freeze(CompanionStories)
