--!strict

-- Lessons for the Islamic Studies hall. Each lesson is a few short pages followed by a
-- checkpoint quiz; passing the quiz marks the lesson complete and awards XP.
-- Prophets are taught through narration only and are never shown as characters.
-- Rulings that differ between schools of thought are kept general on purpose, and the
-- lessons point players to a trusted teacher for the details of their own madhhab.

export type QuizQuestion = {
    Prompt: string,
    Options: { string },
    CorrectIndex: number,
    Explanation: string,
}

export type Lesson = {
    Id: string,
    DisplayName: string,
    Summary: string,
    Pages: { string },
    Quiz: { QuizQuestion },
}

export type Unit = {
    Id: string,
    DisplayName: string,
    Summary: string,
    AccentRGB: { number },
    Lessons: { Lesson },
}

local IslamicStudies: { Units: { Unit }, PassRatio: number } = {
    -- Fraction of quiz questions a player must answer correctly to complete a lesson.
    PassRatio = 0.66,
    Units = {
        {
            Id = "pillars",
            DisplayName = "The Five Pillars",
            Summary = "The five acts every Muslim builds their life on.",
            AccentRGB = { 63, 98, 88 },
            Lessons = {
                {
                    Id = "pillars_intro",
                    DisplayName = "Islam Is Built On Five",
                    Summary = "Why these five acts are called pillars.",
                    Pages = {
                        "A pillar holds a building up. The Prophet, peace be upon him, taught that Islam is built on five pillars (Sahih al-Bukhari 8, Sahih Muslim 16).",
                        "The five pillars are: the Shahadah (declaring faith), Salah (prayer), Zakah (charity), Sawm (fasting in Ramadan), and Hajj (pilgrimage to Makkah).",
                        "Each pillar connects a Muslim to Allah and to other people. Together they shape a believer's day, year, wealth, and whole life.",
                    },
                    Quiz = {
                        {
                            Prompt = "How many pillars of Islam are there?",
                            Options = { "Three", "Five", "Six", "Seven" },
                            CorrectIndex = 2,
                            Explanation = "Islam is built on five pillars, as taught in Sahih al-Bukhari 8.",
                        },
                        {
                            Prompt = "Which of these is NOT one of the five pillars?",
                            Options = { "Salah", "Zakah", "Reading every night", "Hajj" },
                            CorrectIndex = 3,
                            Explanation = "Reading is a great habit, but the pillars are Shahadah, Salah, Zakah, Sawm, and Hajj.",
                        },
                        {
                            Prompt = "Why are they called pillars?",
                            Options = { "They are made of stone", "They hold up a Muslim's faith and practice", "They are only for scholars", "They are optional" },
                            CorrectIndex = 2,
                            Explanation = "Like pillars holding up a building, these five acts hold up a Muslim's religion.",
                        },
                    },
                },
                {
                    Id = "shahadah",
                    DisplayName = "Shahadah: The Declaration Of Faith",
                    Summary = "The first pillar and the meaning of its words.",
                    Pages = {
                        "The Shahadah is: Ash-hadu an la ilaha illa Allah, wa ash-hadu anna Muhammadan rasulullah.",
                        "It means: I bear witness that there is no god worthy of worship except Allah, and I bear witness that Muhammad is the Messenger of Allah.",
                        "The first part is tawhid: believing Allah is One, with no partner. The second part means following the guidance Allah sent through His final Messenger.",
                        "A person becomes Muslim by sincerely believing and saying the Shahadah. Muslims repeat it in every prayer and in the call to prayer.",
                    },
                    Quiz = {
                        {
                            Prompt = "What does 'la ilaha illa Allah' mean?",
                            Options = { "Allah is great", "There is no god worthy of worship except Allah", "All praise is for Allah", "In the name of Allah" },
                            CorrectIndex = 2,
                            Explanation = "It is the declaration of tawhid: worship belongs to Allah alone.",
                        },
                        {
                            Prompt = "What is the belief that Allah is One with no partner called?",
                            Options = { "Tawhid", "Sadaqah", "Hijrah", "Sunnah" },
                            CorrectIndex = 1,
                            Explanation = "Tawhid means the Oneness of Allah.",
                        },
                        {
                            Prompt = "Which pillar comes first?",
                            Options = { "Hajj", "Sawm", "Shahadah", "Zakah" },
                            CorrectIndex = 3,
                            Explanation = "The Shahadah is the first pillar and the foundation for the rest.",
                        },
                    },
                },
                {
                    Id = "salah_pillar",
                    DisplayName = "Salah: The Five Daily Prayers",
                    Summary = "The names and times of the five prayers.",
                    Pages = {
                        "Salah is the second pillar. Muslims pray five times every day, facing the Kaaba in Makkah. This direction is called the qiblah.",
                        "Fajr is prayed before sunrise (2 rak'ahs). Dhuhr is just after midday (4). Asr is in the afternoon (4). Maghrib is just after sunset (3). Isha is at night (4).",
                        "Allah says: 'Indeed, prayer has been decreed upon the believers at fixed times' (Qur'an 4:103).",
                        "Salah is a daily meeting with Allah. It keeps a believer close to Him and away from wrongdoing (Qur'an 29:45).",
                    },
                    Quiz = {
                        {
                            Prompt = "How many obligatory prayers are there each day?",
                            Options = { "Three", "Four", "Five", "Seven" },
                            CorrectIndex = 3,
                            Explanation = "Fajr, Dhuhr, Asr, Maghrib, and Isha.",
                        },
                        {
                            Prompt = "Which prayer is prayed just after sunset?",
                            Options = { "Fajr", "Maghrib", "Dhuhr", "Isha" },
                            CorrectIndex = 2,
                            Explanation = "Maghrib begins right after the sun sets and has 3 rak'ahs.",
                        },
                        {
                            Prompt = "What is the direction Muslims face in prayer called?",
                            Options = { "Qiblah", "Minbar", "Mihrab", "Adhan" },
                            CorrectIndex = 1,
                            Explanation = "The qiblah is the direction of the Kaaba in Makkah.",
                        },
                        {
                            Prompt = "How many rak'ahs does Fajr have?",
                            Options = { "2", "3", "4", "5" },
                            CorrectIndex = 1,
                            Explanation = "The obligatory Fajr prayer has 2 rak'ahs.",
                        },
                    },
                },
                {
                    Id = "zakah",
                    DisplayName = "Zakah: Purifying Wealth",
                    Summary = "Sharing wealth with people in need.",
                    Pages = {
                        "Zakah is the third pillar. The word means purification and growth: giving purifies wealth and the heart.",
                        "A Muslim whose savings stay above a set minimum (the nisab) for a full lunar year gives 2.5% of those savings as Zakah.",
                        "The Qur'an names who may receive Zakah, including the poor, the needy, and travellers in difficulty (Qur'an 9:60).",
                        "Beyond Zakah, any voluntary charity is called sadaqah. Even a smile for your brother is charity (Jami' at-Tirmidhi 1956).",
                    },
                    Quiz = {
                        {
                            Prompt = "What does the word Zakah mean?",
                            Options = { "Fasting", "Purification and growth", "Journey", "Prayer" },
                            CorrectIndex = 2,
                            Explanation = "Zakah purifies wealth and makes it grow in blessing.",
                        },
                        {
                            Prompt = "What portion of qualifying savings is given as Zakah?",
                            Options = { "1%", "2.5%", "10%", "50%" },
                            CorrectIndex = 2,
                            Explanation = "Zakah on savings is 2.5% once they have stayed above the nisab for a lunar year.",
                        },
                        {
                            Prompt = "What is voluntary charity called?",
                            Options = { "Sadaqah", "Sawm", "Qiblah", "Tawaf" },
                            CorrectIndex = 1,
                            Explanation = "Sadaqah is any voluntary charity, even a kind smile.",
                        },
                    },
                },
                {
                    Id = "sawm",
                    DisplayName = "Sawm: Fasting In Ramadan",
                    Summary = "Fasting from dawn to sunset in the holy month.",
                    Pages = {
                        "Sawm is the fourth pillar. In the month of Ramadan, adult Muslims who are able fast from dawn until sunset.",
                        "Fasting means no food, no drink, and keeping away from bad words and actions. Allah says fasting was prescribed so that you may gain taqwa, awareness of Him (Qur'an 2:183).",
                        "The meal before dawn is suhur, and the meal that breaks the fast at sunset is iftar. Ramadan is also the month the Qur'an began to be revealed (Qur'an 2:185).",
                        "People who are ill, travelling, or otherwise unable may be excused and make up the days later, as Allah wants ease for us (Qur'an 2:185). Ramadan ends with the celebration of Eid al-Fitr.",
                    },
                    Quiz = {
                        {
                            Prompt = "In which month do Muslims fast?",
                            Options = { "Muharram", "Ramadan", "Shawwal", "Dhul-Hijjah" },
                            CorrectIndex = 2,
                            Explanation = "The obligatory fast is in Ramadan, the ninth month of the Islamic calendar.",
                        },
                        {
                            Prompt = "What is the meal before dawn called?",
                            Options = { "Iftar", "Suhur", "Walimah", "Eid" },
                            CorrectIndex = 2,
                            Explanation = "Suhur is eaten before dawn; iftar breaks the fast at sunset.",
                        },
                        {
                            Prompt = "According to Qur'an 2:183, fasting helps us gain what?",
                            Options = { "Taqwa", "Wealth", "Fame", "Strength in battle" },
                            CorrectIndex = 1,
                            Explanation = "Fasting was prescribed so that believers may gain taqwa, mindfulness of Allah.",
                        },
                    },
                },
                {
                    Id = "hajj",
                    DisplayName = "Hajj: The Pilgrimage",
                    Summary = "The journey to Makkah, once in a lifetime for those able.",
                    Pages = {
                        "Hajj is the fifth pillar. Every adult Muslim who is physically and financially able must perform it once in their life (Qur'an 3:97).",
                        "Hajj takes place in the month of Dhul-Hijjah. Pilgrims wear simple clothing called ihram, so rich and poor stand together as equals.",
                        "Rites include tawaf (walking around the Kaaba seven times), walking between Safa and Marwah, and standing in prayer at Arafah.",
                        "The Kaaba's foundations were raised by Prophet Ibrahim and his son Isma'il, peace be upon them (Qur'an 2:127). You can see the Kaaba in the hub courtyard.",
                    },
                    Quiz = {
                        {
                            Prompt = "How often must an able Muslim perform Hajj?",
                            Options = { "Every year", "Once in a lifetime", "Every Ramadan", "Twice" },
                            CorrectIndex = 2,
                            Explanation = "Hajj is obligatory once in a lifetime for those who are able.",
                        },
                        {
                            Prompt = "What is walking around the Kaaba seven times called?",
                            Options = { "Sa'i", "Tawaf", "Ruku'", "Wudu" },
                            CorrectIndex = 2,
                            Explanation = "Tawaf is circling the Kaaba seven times. Sa'i is walking between Safa and Marwah.",
                        },
                        {
                            Prompt = "Who raised the foundations of the Kaaba?",
                            Options = { "Nuh and his sons", "Ibrahim and Isma'il", "Musa and Harun", "Dawud and Sulayman" },
                            CorrectIndex = 2,
                            Explanation = "Qur'an 2:127 tells of Ibrahim and Isma'il, peace be upon them, raising the House.",
                        },
                    },
                },
            },
        },
        {
            Id = "prayer",
            DisplayName = "How To Pray",
            Summary = "Wudu and the steps of Salah, one at a time.",
            AccentRGB = { 92, 119, 82 },
            Lessons = {
                {
                    Id = "wudu",
                    DisplayName = "Wudu: Getting Ready To Pray",
                    Summary = "The washing a Muslim does before Salah.",
                    Pages = {
                        "Before praying, a Muslim makes wudu, a washing that brings purity. Qur'an 5:6 commands washing the face, the arms to the elbows, wiping the head, and washing the feet to the ankles.",
                        "Steps: 1) Make the intention in your heart and say Bismillah. 2) Wash your hands three times. 3) Rinse your mouth three times. 4) Rinse your nose three times.",
                        "5) Wash your face three times. 6) Wash your right arm to the elbow, then the left, three times each. 7) Wipe over your head once, and wipe your ears.",
                        "8) Wash your right foot to the ankle, then the left, three times each. Wudu is broken by things like using the toilet or deep sleep, so renew it before the next prayer.",
                        "Details can differ slightly between schools of thought. Ask a parent, teacher, or imam to show you the way your community follows.",
                    },
                    Quiz = {
                        {
                            Prompt = "What do you say when beginning wudu?",
                            Options = { "Ameen", "Bismillah", "Subhanallah", "Allahu Akbar" },
                            CorrectIndex = 2,
                            Explanation = "Begin wudu with the intention and Bismillah, in the name of Allah.",
                        },
                        {
                            Prompt = "How far are the arms washed in wudu?",
                            Options = { "Only the hands", "To the elbows", "To the shoulders", "They are only wiped" },
                            CorrectIndex = 2,
                            Explanation = "Qur'an 5:6 says to wash the arms up to the elbows.",
                        },
                        {
                            Prompt = "Which side do you wash first for arms and feet?",
                            Options = { "Left", "Right", "Either, it never matters", "Both together only" },
                            CorrectIndex = 2,
                            Explanation = "The Sunnah is to begin with the right side.",
                        },
                        {
                            Prompt = "What is done to the head in wudu?",
                            Options = { "It is wiped with wet hands", "It is washed three times", "Nothing", "It is covered" },
                            CorrectIndex = 1,
                            Explanation = "The head is wiped with wet hands, not washed.",
                        },
                    },
                },
                {
                    Id = "salah_steps",
                    DisplayName = "The Steps Of Salah",
                    Summary = "Standing, bowing, prostrating, and sitting.",
                    Pages = {
                        "1) Stand facing the qiblah and make the intention in your heart for the prayer you are about to pray.",
                        "2) Raise your hands and say 'Allahu Akbar' (Allah is the Greatest). This opening takbir begins the prayer.",
                        "3) Standing (qiyam): recite Surah Al-Fatihah, then in the first two rak'ahs recite another short surah or verses.",
                        "4) Bowing (ruku'): say 'Allahu Akbar', bow with hands on knees and back straight, and say 'Subhana Rabbiyal-'Adhim' (Glory be to my Lord, the Most Great).",
                        "5) Rise saying 'Sami'a Allahu liman hamidah' (Allah hears whoever praises Him), then 'Rabbana wa lakal-hamd' (Our Lord, to You belongs all praise).",
                        "6) Prostration (sujud): with forehead and nose, palms, knees, and toes on the ground, say 'Subhana Rabbiyal-A'la' (Glory be to my Lord, the Most High). Sit briefly, then make a second sujud.",
                        "That completes one rak'ah. After every two rak'ahs, and at the end, you sit and recite the tashahhud. The prayer ends by turning the head right then left saying 'As-salamu 'alaykum wa rahmatullah'.",
                        "Small details differ between schools of thought. Learn the full prayer with a trusted teacher or imam, and practice with your family.",
                    },
                    Quiz = {
                        {
                            Prompt = "What words begin the prayer?",
                            Options = { "As-salamu 'alaykum", "Allahu Akbar", "Ameen", "Alhamdulillah" },
                            CorrectIndex = 2,
                            Explanation = "The opening takbir, 'Allahu Akbar', begins the prayer.",
                        },
                        {
                            Prompt = "Which surah is recited in every rak'ah?",
                            Options = { "Al-Ikhlas", "Al-Fatihah", "Al-Baqarah", "An-Nas" },
                            CorrectIndex = 2,
                            Explanation = "Surah Al-Fatihah is recited while standing in every rak'ah.",
                        },
                        {
                            Prompt = "What is the bowing position called?",
                            Options = { "Sujud", "Qiyam", "Ruku'", "Tashahhud" },
                            CorrectIndex = 3,
                            Explanation = "Ruku' is bowing; sujud is prostrating with the forehead on the ground.",
                        },
                        {
                            Prompt = "What do you say in sujud?",
                            Options = { "Subhana Rabbiyal-A'la", "Subhana Rabbiyal-'Adhim", "Bismillah", "Ameen" },
                            CorrectIndex = 1,
                            Explanation = "In sujud: Glory be to my Lord, the Most High. In ruku': the Most Great.",
                        },
                        {
                            Prompt = "How does the prayer end?",
                            Options = { "Standing up", "Saying salam to the right then left", "Clapping", "Saying Allahu Akbar" },
                            CorrectIndex = 2,
                            Explanation = "The prayer ends with 'As-salamu 'alaykum wa rahmatullah', right then left.",
                        },
                    },
                },
            },
        },
        {
            Id = "duas",
            DisplayName = "Daily Duas",
            Summary = "Short prayers for everyday moments.",
            AccentRGB = { 121, 94, 63 },
            Lessons = {
                {
                    Id = "duas_eating",
                    DisplayName = "Duas For Eating",
                    Summary = "Before and after a meal.",
                    Pages = {
                        "Before eating, say: 'Bismillah' (In the name of Allah). If you forget at the start, say: 'Bismillahi awwalahu wa akhirahu' (In the name of Allah, at its beginning and its end) (Sunan Abi Dawud 3767).",
                        "Eat with your right hand and from what is in front of you, as the Prophet, peace be upon him, taught a young boy (Sahih al-Bukhari 5376).",
                        "After eating, say: 'Alhamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah' (Praise be to Allah who fed me this and provided it for me without any power or strength from me) (Sunan Abi Dawud 4023).",
                    },
                    Quiz = {
                        {
                            Prompt = "What do you say before eating?",
                            Options = { "Bismillah", "Ameen", "Ghufranak", "Yarhamukallah" },
                            CorrectIndex = 1,
                            Explanation = "Begin every meal with Bismillah.",
                        },
                        {
                            Prompt = "If you forgot Bismillah at the start of a meal, what do you say?",
                            Options = { "Nothing, it is too late", "Bismillahi awwalahu wa akhirahu", "Allahu Akbar", "As-salamu 'alaykum" },
                            CorrectIndex = 2,
                            Explanation = "In the name of Allah, at its beginning and its end.",
                        },
                        {
                            Prompt = "Which hand is the Sunnah for eating?",
                            Options = { "Left", "Right", "Either", "Both" },
                            CorrectIndex = 2,
                            Explanation = "The Prophet, peace be upon him, taught: eat with your right hand.",
                        },
                    },
                },
                {
                    Id = "duas_sleep",
                    DisplayName = "Duas For Sleeping And Waking",
                    Summary = "Ending and starting the day with Allah's name.",
                    Pages = {
                        "Before sleeping, say: 'Bismika Allahumma amutu wa ahya' (In Your name, O Allah, I die and I live) (Sahih al-Bukhari 6324).",
                        "Sleep is like a small death, and waking is a gift of new life and a new chance to do good.",
                        "On waking, say: 'Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur' (Praise be to Allah who gave us life after causing us to die, and to Him is the return) (Sahih al-Bukhari 6324).",
                    },
                    Quiz = {
                        {
                            Prompt = "What does 'Bismika Allahumma amutu wa ahya' mean?",
                            Options = { "In Your name, O Allah, I die and I live", "Allah is the Greatest", "Praise be to Allah", "O Allah, forgive me" },
                            CorrectIndex = 1,
                            Explanation = "It is the dua before sleeping.",
                        },
                        {
                            Prompt = "When do you say 'Alhamdu lillahil-ladhi ahyana...'?",
                            Options = { "Before eating", "When waking up", "When sneezing", "Entering the masjid" },
                            CorrectIndex = 2,
                            Explanation = "It thanks Allah for giving us life again after sleep.",
                        },
                    },
                },
                {
                    Id = "duas_home_masjid",
                    DisplayName = "Duas For Home And Masjid",
                    Summary = "Leaving the house and entering the masjid.",
                    Pages = {
                        "Leaving home, say: 'Bismillah, tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah' (In the name of Allah, I trust in Allah, and there is no power or strength except with Allah) (Sunan Abi Dawud 5095).",
                        "Entering the masjid, step in with the right foot and say: 'Allahummaf-tah li abwaba rahmatik' (O Allah, open for me the doors of Your mercy) (Sahih Muslim 713).",
                        "Leaving the masjid, step out with the left foot and say: 'Allahumma inni as'aluka min fadlik' (O Allah, I ask You from Your bounty) (Sahih Muslim 713).",
                    },
                    Quiz = {
                        {
                            Prompt = "Which foot do you enter the masjid with?",
                            Options = { "Left", "Right", "Either", "Jump with both" },
                            CorrectIndex = 2,
                            Explanation = "Enter with the right foot and leave with the left.",
                        },
                        {
                            Prompt = "Entering the masjid, you ask Allah to open the doors of His...",
                            Options = { "Mercy", "Treasure", "Kingdom", "Gardens" },
                            CorrectIndex = 1,
                            Explanation = "'Allahummaf-tah li abwaba rahmatik': O Allah, open for me the doors of Your mercy.",
                        },
                        {
                            Prompt = "What does 'tawakkaltu 'alallah' mean?",
                            Options = { "I trust in Allah", "Allah is One", "I seek forgiveness", "Peace be upon you" },
                            CorrectIndex = 1,
                            Explanation = "It is said when leaving home, placing your trust in Allah.",
                        },
                    },
                },
                {
                    Id = "duas_everyday",
                    DisplayName = "Everyday Words Of Remembrance",
                    Summary = "Sneezing, learning, parents, and travel.",
                    Pages = {
                        "When you sneeze, say 'Alhamdulillah'. Whoever hears it replies 'Yarhamukallah' (May Allah have mercy on you), and you answer 'Yahdikumullahu wa yuslihu balakum' (May Allah guide you and set your affairs right) (Sahih al-Bukhari 6224).",
                        "For knowledge: 'Rabbi zidni 'ilma' (My Lord, increase me in knowledge) (Qur'an 20:114).",
                        "For parents: 'Rabbir-hamhuma kama rabbayani saghira' (My Lord, have mercy on them as they raised me when I was small) (Qur'an 17:24).",
                        "When riding or travelling: 'Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila rabbina lamunqalibun' (Glory be to the One who made this serve us, which we could not have done ourselves, and to our Lord we will return) (Qur'an 43:13-14). Try it on a camel in the hub!",
                    },
                    Quiz = {
                        {
                            Prompt = "Someone sneezes and says Alhamdulillah. What do you reply?",
                            Options = { "Ameen", "Yarhamukallah", "Bismillah", "Ghufranak" },
                            CorrectIndex = 2,
                            Explanation = "Reply 'Yarhamukallah', may Allah have mercy on you.",
                        },
                        {
                            Prompt = "'Rabbi zidni 'ilma' asks Allah for more...",
                            Options = { "Wealth", "Knowledge", "Friends", "Time" },
                            CorrectIndex = 2,
                            Explanation = "My Lord, increase me in knowledge (Qur'an 20:114).",
                        },
                        {
                            Prompt = "Which dua is for your parents?",
                            Options = { "Rabbir-hamhuma kama rabbayani saghira", "Subhana Rabbiyal-A'la", "Allahumma inni as'aluka min fadlik", "Bismika Allahumma amutu wa ahya" },
                            CorrectIndex = 1,
                            Explanation = "My Lord, have mercy on them as they raised me when I was small (Qur'an 17:24).",
                        },
                    },
                },
            },
        },
        {
            Id = "faith",
            DisplayName = "Pillars Of Faith",
            Summary = "The six things every Muslim believes in.",
            AccentRGB = { 112, 98, 64 },
            Lessons = {
                {
                    Id = "iman_six",
                    DisplayName = "The Six Articles Of Iman",
                    Summary = "What a Muslim believes in their heart.",
                    Pages = {
                        "Islam is what we do, and iman is what we believe. When the angel Jibril asked about iman, the Prophet, peace be upon him, named six beliefs (Sahih Muslim 8).",
                        "Belief in 1) Allah, 2) His angels, 3) His revealed books, 4) His messengers, 5) the Last Day, and 6) qadr, Allah's decree of good and bad.",
                        "The revealed books include the Tawrah given to Musa, the Zabur given to Dawud, the Injil given to Isa, and the Qur'an, the final book, given to Muhammad, peace be upon them all.",
                        "The angels never disobey Allah. Jibril brought revelation to the prophets. Believing in the Last Day reminds us that every good deed counts.",
                    },
                    Quiz = {
                        {
                            Prompt = "How many articles of iman are there?",
                            Options = { "Four", "Five", "Six", "Ten" },
                            CorrectIndex = 3,
                            Explanation = "Allah, angels, books, messengers, the Last Day, and qadr.",
                        },
                        {
                            Prompt = "Which angel brought revelation to the prophets?",
                            Options = { "Jibril", "Mika'il", "Israfil", "Malik" },
                            CorrectIndex = 1,
                            Explanation = "Jibril, peace be upon him, brought Allah's revelation.",
                        },
                        {
                            Prompt = "Which book was given to Prophet Musa?",
                            Options = { "Zabur", "Injil", "Tawrah", "Qur'an" },
                            CorrectIndex = 3,
                            Explanation = "The Tawrah was revealed to Musa, peace be upon him.",
                        },
                    },
                },
            },
        },
        {
            Id = "prophets",
            DisplayName = "Stories Of The Prophets",
            Summary = "Lessons from the messengers of Allah, told through narration.",
            AccentRGB = { 82, 127, 111 },
            Lessons = {
                {
                    Id = "prophet_nuh",
                    DisplayName = "Nuh And The Ark",
                    Summary = "Patience while calling people to good.",
                    Pages = {
                        "Prophet Nuh, peace be upon him, called his people to worship Allah alone for 950 years (Qur'an 29:14). Most of them mocked him, but he never gave up.",
                        "Allah commanded him to build an ark (Qur'an 11:37). People laughed at him for building a ship on dry land, yet he kept working in trust.",
                        "When the flood came, the believers and pairs of animals were saved on the ark (Qur'an 11:40-44).",
                        "Lesson: keep doing what is right with patience, even when people laugh at you.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did Allah command Nuh to build?",
                            Options = { "A tower", "An ark", "A wall", "A city" },
                            CorrectIndex = 2,
                            Explanation = "Qur'an 11:37: build the ark under Our eyes and Our inspiration.",
                        },
                        {
                            Prompt = "What is the main lesson from Nuh's story?",
                            Options = { "Give up when people mock you", "Stay patient and keep doing right", "Only work alone", "Build big ships" },
                            CorrectIndex = 2,
                            Explanation = "Nuh stayed patient and faithful for centuries.",
                        },
                    },
                },
                {
                    Id = "prophet_ibrahim",
                    DisplayName = "Ibrahim And The Kaaba",
                    Summary = "Tawhid, courage, and building the House of Allah.",
                    Pages = {
                        "As a young man, Prophet Ibrahim, peace be upon him, saw his people worshipping idols. He used reason to show them that idols cannot help or harm (Qur'an 21:51-67).",
                        "When they threw him into a fire, Allah said: 'O fire, be coolness and safety upon Ibrahim' (Qur'an 21:69).",
                        "Later, Ibrahim and his son Isma'il raised the foundations of the Kaaba, praying: 'Our Lord, accept this from us' (Qur'an 2:127).",
                        "Lesson: stand firm for tawhid, trust Allah in hard moments, and ask Him to accept your good deeds.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did Allah command the fire to be for Ibrahim?",
                            Options = { "Hotter", "Coolness and safety", "Brighter", "Gone forever" },
                            CorrectIndex = 2,
                            Explanation = "Qur'an 21:69: be coolness and safety upon Ibrahim.",
                        },
                        {
                            Prompt = "Who helped Ibrahim build the Kaaba?",
                            Options = { "Ishaq", "Isma'il", "Lut", "Yusuf" },
                            CorrectIndex = 2,
                            Explanation = "Ibrahim and Isma'il raised its foundations together (Qur'an 2:127).",
                        },
                    },
                },
                {
                    Id = "prophet_yusuf",
                    DisplayName = "Yusuf: Patience And Forgiveness",
                    Summary = "From the well to the palace.",
                    Pages = {
                        "Prophet Yusuf, peace be upon him, was thrown into a well by his jealous brothers. Allah calls his story the best of stories (Qur'an 12:3).",
                        "He was sold as a servant, then wrongly put in prison, but he stayed honest and kept teaching people about Allah even there.",
                        "Allah raised him to look after the stores of Egypt. When his brothers came asking for food, he forgave them: 'No blame upon you today' (Qur'an 12:92).",
                        "Lesson: be patient in hardship, stay honest when nobody is watching, and forgive people who hurt you.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did Yusuf say to his brothers at the end?",
                            Options = { "You will be punished", "No blame upon you today", "Go away", "I never knew you" },
                            CorrectIndex = 2,
                            Explanation = "He forgave them completely (Qur'an 12:92).",
                        },
                        {
                            Prompt = "What does Allah call Yusuf's story?",
                            Options = { "The best of stories", "The oldest story", "A secret", "A short tale" },
                            CorrectIndex = 1,
                            Explanation = "Qur'an 12:3 calls it the best of stories.",
                        },
                    },
                },
                {
                    Id = "prophet_musa",
                    DisplayName = "Musa And The Sea",
                    Summary = "Trusting Allah when there seems to be no way out.",
                    Pages = {
                        "Prophet Musa, peace be upon him, was sent to Pharaoh, a tyrant who oppressed the Children of Israel.",
                        "When Musa led the believers out of Egypt, Pharaoh's army chased them to the sea. The people cried, 'We will surely be caught!'",
                        "Musa answered: 'No! My Lord is with me; He will guide me' (Qur'an 26:62). Allah told him to strike the sea with his staff, and it parted (Qur'an 26:63).",
                        "Lesson: when a problem looks impossible, trust Allah and keep moving forward.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did Musa say when the army was behind them?",
                            Options = { "We are lost", "My Lord is with me; He will guide me", "Let us surrender", "Run back" },
                            CorrectIndex = 2,
                            Explanation = "Qur'an 26:62 records his complete trust in Allah.",
                        },
                        {
                            Prompt = "What happened when Musa struck the sea?",
                            Options = { "It froze", "It parted", "It dried up slowly", "Nothing" },
                            CorrectIndex = 2,
                            Explanation = "By Allah's command, the sea parted (Qur'an 26:63).",
                        },
                    },
                },
                {
                    Id = "prophet_yunus",
                    DisplayName = "Yunus In The Whale",
                    Summary = "Turning back to Allah from the darkness.",
                    Pages = {
                        "Prophet Yunus, peace be upon him, left his people in frustration when they would not listen, and was swallowed by a great fish (Qur'an 37:139-142).",
                        "In the darkness he called out: 'La ilaha illa anta, subhanaka, inni kuntu minaz-zalimin' (There is no god but You, glory be to You, I was among the wrongdoers) (Qur'an 21:87).",
                        "Allah answered him and saved him from distress, and said He saves the believers in the same way (Qur'an 21:88).",
                        "Lesson: when you make a mistake, admit it and turn back to Allah. He always listens.",
                    },
                    Quiz = {
                        {
                            Prompt = "Where was Yunus when he made his famous dua?",
                            Options = { "On a mountain", "Inside a great fish", "In a palace", "In the desert" },
                            CorrectIndex = 2,
                            Explanation = "He called to Allah from inside the fish (Qur'an 21:87).",
                        },
                        {
                            Prompt = "What is the lesson of Yunus's dua?",
                            Options = { "Hide your mistakes", "Admit mistakes and turn back to Allah", "Blame others", "Never travel" },
                            CorrectIndex = 2,
                            Explanation = "He admitted his mistake and Allah saved him.",
                        },
                    },
                },
            },
        },
    },
}

return IslamicStudies
