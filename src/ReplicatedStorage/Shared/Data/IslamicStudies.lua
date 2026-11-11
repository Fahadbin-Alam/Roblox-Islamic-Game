--!strict

-- Lessons for the Islamic Studies hall. Each lesson is a few short pages followed by a
-- checkpoint quiz; passing the quiz marks the lesson complete and awards XP.
-- Prophets are taught through narration only and are never shown as characters.
-- Rulings that differ between schools of thought are kept general on purpose, and the
-- lessons point players to a trusted teacher for the details of their own madhhab.
--
-- This file replicates to every client, so it holds no answers. The correct option and
-- explanation for each quiz question, and the correct order of each puzzle, are in
-- ServerScriptService/Modules/LessonAnswers.lua, which only the server can read.

export type QuizQuestion = {
    Prompt: string,
    Options: { string },
}

-- An optional bonus puzzle: put the steps back in the right order.
export type OrderPuzzle = {
    Prompt: string,
    -- Listed alphabetically so the order gives nothing away; the hall shuffles them for
    -- the player, and the server checks the order against LessonAnswers.
    Steps: { string },
}

export type Lesson = {
    Id: string,
    DisplayName: string,
    Summary: string,
    Pages: { string },
    Quiz: { QuizQuestion },
    Order: OrderPuzzle?,
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
                        },
                        {
                            Prompt = "Which of these is NOT one of the five pillars?",
                            Options = { "Salah", "Zakah", "Reading every night", "Hajj" },
                        },
                        {
                            Prompt = "Why are they called pillars?",
                            Options = { "They are made of stone", "They hold up a Muslim's faith and practice", "They are only for scholars", "They are optional" },
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
                        },
                        {
                            Prompt = "What is the belief that Allah is One with no partner called?",
                            Options = { "Tawhid", "Sadaqah", "Hijrah", "Sunnah" },
                        },
                        {
                            Prompt = "Which pillar comes first?",
                            Options = { "Hajj", "Sawm", "Shahadah", "Zakah" },
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
                        },
                        {
                            Prompt = "Which prayer is prayed just after sunset?",
                            Options = { "Fajr", "Maghrib", "Dhuhr", "Isha" },
                        },
                        {
                            Prompt = "What is the direction Muslims face in prayer called?",
                            Options = { "Qiblah", "Minbar", "Mihrab", "Adhan" },
                        },
                        {
                            Prompt = "How many rak'ahs does Fajr have?",
                            Options = { "2", "3", "4", "5" },
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
                        },
                        {
                            Prompt = "What portion of qualifying savings is given as Zakah?",
                            Options = { "1%", "2.5%", "10%", "50%" },
                        },
                        {
                            Prompt = "What is voluntary charity called?",
                            Options = { "Sadaqah", "Sawm", "Qiblah", "Tawaf" },
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
                        },
                        {
                            Prompt = "What is the meal before dawn called?",
                            Options = { "Iftar", "Suhur", "Walimah", "Eid" },
                        },
                        {
                            Prompt = "According to Qur'an 2:183, fasting helps us gain what?",
                            Options = { "Taqwa", "Wealth", "Fame", "Strength in battle" },
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
                        },
                        {
                            Prompt = "What is walking around the Kaaba seven times called?",
                            Options = { "Sa'i", "Tawaf", "Ruku'", "Wudu" },
                        },
                        {
                            Prompt = "Who raised the foundations of the Kaaba?",
                            Options = { "Nuh and his sons", "Ibrahim and Isma'il", "Musa and Harun", "Dawud and Sulayman" },
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
                    Order = {
                        Prompt = "Put the steps of wudu in order.",
                        Steps = {
                            "Intention and Bismillah",
                            "Rinse the mouth",
                            "Rinse the nose",
                            "Wash the arms to the elbows, right first",
                            "Wash the face",
                            "Wash the feet to the ankles, right first",
                            "Wash the hands",
                            "Wipe the head and ears",
                        },
                    },
                    Quiz = {
                        {
                            Prompt = "What do you say when beginning wudu?",
                            Options = { "Ameen", "Bismillah", "Subhanallah", "Allahu Akbar" },
                        },
                        {
                            Prompt = "How far are the arms washed in wudu?",
                            Options = { "Only the hands", "To the elbows", "To the shoulders", "They are only wiped" },
                        },
                        {
                            Prompt = "Which side do you wash first for arms and feet?",
                            Options = { "Left", "Right", "Either, it never matters", "Both together only" },
                        },
                        {
                            Prompt = "What is done to the head in wudu?",
                            Options = { "It is wiped with wet hands", "It is washed three times", "Nothing", "It is covered" },
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
                    Order = {
                        Prompt = "Put the steps of one rak'ah and the end of the prayer in order.",
                        Steps = {
                            "Bow in ruku'",
                            "End with salam, right then left",
                            "Face the qiblah with the intention",
                            "Opening takbir: Allahu Akbar",
                            "Prostrate in sujud twice",
                            "Rise: Sami'a Allahu liman hamidah",
                            "Sit for the tashahhud",
                            "Stand and recite Al-Fatihah",
                        },
                    },
                    Quiz = {
                        {
                            Prompt = "What words begin the prayer?",
                            Options = { "As-salamu 'alaykum", "Allahu Akbar", "Ameen", "Alhamdulillah" },
                        },
                        {
                            Prompt = "Which surah is recited in every rak'ah?",
                            Options = { "Al-Ikhlas", "Al-Fatihah", "Al-Baqarah", "An-Nas" },
                        },
                        {
                            Prompt = "What is the bowing position called?",
                            Options = { "Sujud", "Qiyam", "Ruku'", "Tashahhud" },
                        },
                        {
                            Prompt = "What do you say in sujud?",
                            Options = { "Subhana Rabbiyal-A'la", "Subhana Rabbiyal-'Adhim", "Bismillah", "Ameen" },
                        },
                        {
                            Prompt = "How does the prayer end?",
                            Options = { "Standing up", "Saying salam to the right then left", "Clapping", "Saying Allahu Akbar" },
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
                        },
                        {
                            Prompt = "If you forgot Bismillah at the start of a meal, what do you say?",
                            Options = { "Nothing, it is too late", "Bismillahi awwalahu wa akhirahu", "Allahu Akbar", "As-salamu 'alaykum" },
                        },
                        {
                            Prompt = "Which hand is the Sunnah for eating?",
                            Options = { "Left", "Right", "Either", "Both" },
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
                        },
                        {
                            Prompt = "When do you say 'Alhamdu lillahil-ladhi ahyana...'?",
                            Options = { "Before eating", "When waking up", "When sneezing", "Entering the masjid" },
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
                        },
                        {
                            Prompt = "Entering the masjid, you ask Allah to open the doors of His...",
                            Options = { "Mercy", "Treasure", "Kingdom", "Gardens" },
                        },
                        {
                            Prompt = "What does 'tawakkaltu 'alallah' mean?",
                            Options = { "I trust in Allah", "Allah is One", "I seek forgiveness", "Peace be upon you" },
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
                        },
                        {
                            Prompt = "'Rabbi zidni 'ilma' asks Allah for more...",
                            Options = { "Wealth", "Knowledge", "Friends", "Time" },
                        },
                        {
                            Prompt = "Which dua is for your parents?",
                            Options = { "Rabbir-hamhuma kama rabbayani saghira", "Subhana Rabbiyal-A'la", "Allahumma inni as'aluka min fadlik", "Bismika Allahumma amutu wa ahya" },
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
                        },
                        {
                            Prompt = "Which angel brought revelation to the prophets?",
                            Options = { "Jibril", "Mika'il", "Israfil", "Malik" },
                        },
                        {
                            Prompt = "Which book was given to Prophet Musa?",
                            Options = { "Zabur", "Injil", "Tawrah", "Qur'an" },
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
                        },
                        {
                            Prompt = "What is the main lesson from Nuh's story?",
                            Options = { "Give up when people mock you", "Stay patient and keep doing right", "Only work alone", "Build big ships" },
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
                        },
                        {
                            Prompt = "Who helped Ibrahim build the Kaaba?",
                            Options = { "Ishaq", "Isma'il", "Lut", "Yusuf" },
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
                        },
                        {
                            Prompt = "What does Allah call Yusuf's story?",
                            Options = { "The best of stories", "The oldest story", "A secret", "A short tale" },
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
                        },
                        {
                            Prompt = "What happened when Musa struck the sea?",
                            Options = { "It froze", "It parted", "It dried up slowly", "Nothing" },
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
                        },
                        {
                            Prompt = "What is the lesson of Yunus's dua?",
                            Options = { "Hide your mistakes", "Admit mistakes and turn back to Allah", "Blame others", "Never travel" },
                        },
                    },
                },
                {
                    Id = "prophet_adam",
                    DisplayName = "Adam: The First Human",
                    Summary = "Learning, mistakes, and repentance.",
                    Pages = {
                        "Allah created Adam, peace be upon him, the first human, and told the angels He was placing a successor on earth (Qur'an 2:30).",
                        "Allah taught Adam the names of all things, honouring him with knowledge (Qur'an 2:31).",
                        "Adam and his wife lived in the Garden but were tricked by Shaytan into eating from the one tree they were told to avoid.",
                        "They did not blame anyone. They prayed: 'Rabbana zalamna anfusana...' (Our Lord, we have wronged ourselves; if You do not forgive us and have mercy on us, we will surely be among the losers) (Qur'an 7:23). Allah accepted their repentance (Qur'an 2:37).",
                        "Lesson: everyone makes mistakes. The believer owns the mistake and asks Allah for forgiveness.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did Allah teach Adam?",
                            Options = { "How to build", "The names of all things", "How to fight", "Nothing" },
                        },
                        {
                            Prompt = "What did Adam and his wife do after their mistake?",
                            Options = { "Blamed each other", "Asked Allah for forgiveness", "Ran away", "Stayed silent" },
                        },
                    },
                },
                {
                    Id = "prophet_ayyub",
                    DisplayName = "Ayyub: Patience In Illness",
                    Summary = "Staying grateful when things are hard.",
                    Pages = {
                        "Prophet Ayyub, peace be upon him, was tested with the loss of his health, wealth, and family for many years.",
                        "He never complained against Allah. He called out gently: 'Indeed, hardship has touched me, and You are the Most Merciful of the merciful' (Qur'an 21:83).",
                        "Allah answered him, removed his hardship, and restored his family and more, as a mercy and a reminder for worshippers (Qur'an 21:84).",
                        "Allah praised him: 'Indeed, We found him patient. An excellent servant!' (Qur'an 38:44).",
                        "Lesson: when you are sick or sad, it's okay to tell Allah how you feel. Keep trusting Him.",
                    },
                    Quiz = {
                        {
                            Prompt = "What quality is Ayyub most famous for?",
                            Options = { "Wealth", "Patience", "Strength", "Speed" },
                        },
                        {
                            Prompt = "How did Ayyub ask Allah for help?",
                            Options = { "He complained angrily", "He called on Allah as the Most Merciful", "He gave up", "He asked people only" },
                        },
                    },
                },
                {
                    Id = "prophet_sulayman",
                    DisplayName = "Sulayman And The Ant",
                    Summary = "Power used with gratitude.",
                    Pages = {
                        "Prophet Sulayman, peace be upon him, was a king and a prophet. Allah gave him the ability to understand the speech of birds and animals.",
                        "Once, as his great army marched, an ant warned the others: 'Enter your homes so Sulayman and his soldiers do not crush you without knowing' (Qur'an 27:18).",
                        "Sulayman smiled and, instead of feeling proud, prayed: 'My Lord, enable me to be grateful for Your favour' (Qur'an 27:19).",
                        "Lesson: whatever gifts you have, say Alhamdulillah, and be gentle even with the smallest creatures.",
                    },
                    Quiz = {
                        {
                            Prompt = "Who warned the others about Sulayman's army?",
                            Options = { "A bird", "An ant", "A lion", "A fish" },
                        },
                        {
                            Prompt = "How did Sulayman respond?",
                            Options = { "He was proud", "He thanked Allah and asked to stay grateful", "He ignored it", "He got angry" },
                        },
                    },
                },
                {
                    Id = "prophet_isa",
                    DisplayName = "Isa, Son Of Maryam",
                    Summary = "A mighty messenger and his miracles.",
                    Pages = {
                        "Maryam, peace be upon her, was a pious woman honoured above the women of the worlds (Qur'an 3:42). Allah gave her a son, Isa, without a father, as a sign (Qur'an 19:16-21).",
                        "As a baby in the cradle, Isa spoke: 'Indeed, I am the servant of Allah. He has given me the Scripture and made me a prophet' (Qur'an 19:30).",
                        "By Allah's permission, he healed the blind and the sick and brought the dead back to life (Qur'an 5:110). The book given to him is the Injil.",
                        "Muslims love and believe in Isa, peace be upon him, as one of the greatest messengers of Allah.",
                        "Lesson: miracles come only by Allah's permission, and the prophets always pointed people to worship Allah alone.",
                    },
                    Order = {
                        Prompt = "Put these Prophets in the order they lived, earliest first.",
                        Steps = {
                            "Adam",
                            "Ibrahim",
                            "Isa",
                            "Musa",
                            "Nuh",
                            "Sulayman",
                            "Yusuf",
                        },
                    },
                    Quiz = {
                        {
                            Prompt = "What did baby Isa say from the cradle?",
                            Options = { "I am a king", "I am the servant of Allah", "I am hungry", "Nothing" },
                        },
                        {
                            Prompt = "Which book was given to Isa?",
                            Options = { "Tawrah", "Zabur", "Injil", "Qur'an" },
                        },
                        {
                            Prompt = "By whose permission did Isa perform miracles?",
                            Options = { "His own", "Allah's", "The people's", "The angels'" },
                        },
                    },
                },
            },
        },
        {
            Id = "seerah",
            DisplayName = "The Seerah",
            Summary = "The life of the Prophet, peace be upon him, told through narration.",
            AccentRGB = { 121, 94, 63 },
            Lessons = {
                {
                    Id = "seerah_early_life",
                    DisplayName = "The Early Life Of The Prophet",
                    Summary = "Makkah, family, and the trustworthy one.",
                    Pages = {
                        "Prophet Muhammad, peace be upon him, was born in Makkah around 570 CE, known as the Year of the Elephant, when Allah protected the Kaaba from an army with elephants (Surah Al-Fil, 105).",
                        "His father Abdullah died before he was born, and his mother Aminah died when he was six. He was raised by his grandfather Abdul-Muttalib, then by his uncle Abu Talib.",
                        "He worked as a shepherd and later as a trader. People called him al-Amin, the trustworthy, and left their valuables with him.",
                        "At about 25 he married Khadijah, may Allah be pleased with her, a respected businesswoman known for her wisdom and kindness.",
                        "In this game the Prophet, peace be upon him, is never shown. We learn about him through narration, as Muslims have done for centuries.",
                    },
                    Quiz = {
                        {
                            Prompt = "What was the Prophet called because of his honesty?",
                            Options = { "Al-Amin", "Al-Faruq", "As-Siddiq", "Saifullah" },
                        },
                        {
                            Prompt = "Which surah tells of the army with elephants?",
                            Options = { "Al-Fil", "Al-Kahf", "Yasin", "Al-Mulk" },
                        },
                        {
                            Prompt = "Who raised him after his grandfather died?",
                            Options = { "Abu Lahab", "His uncle Abu Talib", "Abu Bakr", "Umar" },
                        },
                    },
                },
                {
                    Id = "seerah_first_revelation",
                    DisplayName = "The First Revelation",
                    Summary = "The cave of Hira and the word 'Read'.",
                    Pages = {
                        "Before prophethood, he would go to the cave of Hira on the mountain Jabal an-Nur near Makkah to reflect and worship.",
                        "At about 40 years old, the angel Jibril came to him in the cave and brought the first verses of the Qur'an: 'Read in the name of your Lord who created...' (Qur'an 96:1-5).",
                        "He returned home shaken, and Khadijah comforted him, reminding him that Allah would never disgrace someone who is kind to family, helps the weak, and honours guests (Sahih al-Bukhari 3).",
                        "Khadijah became the first person to believe in his message.",
                        "Lesson: the very first command of the Qur'an is to read. Seeking knowledge is part of Islam from its first day.",
                    },
                    Quiz = {
                        {
                            Prompt = "Where did the first revelation come?",
                            Options = { "Cave of Thawr", "Cave of Hira", "Masjid an-Nabawi", "Mount Uhud" },
                        },
                        {
                            Prompt = "What was the first word revealed?",
                            Options = { "Pray", "Read", "Fast", "Give" },
                        },
                        {
                            Prompt = "Who was the first person to believe?",
                            Options = { "Khadijah", "Umar", "Abu Sufyan", "Bilal" },
                        },
                    },
                },
                {
                    Id = "seerah_hijrah",
                    DisplayName = "The Hijrah To Madinah",
                    Summary = "Leaving home for the sake of Allah.",
                    Pages = {
                        "For thirteen years in Makkah, the Muslims were mocked and persecuted for their faith.",
                        "In 622 CE, the Prophet, peace be upon him, migrated to Yathrib, later called Madinah, with Abu Bakr. This journey is the Hijrah.",
                        "They hid for three days in the cave of Thawr. When Abu Bakr worried, the Prophet said: 'Do not grieve; indeed Allah is with us' (Qur'an 9:40).",
                        "In Madinah, the Muslims who migrated (the Muhajirun) were joined as brothers with the Muslims of Madinah who helped them (the Ansar).",
                        "The Islamic calendar counts its years from the Hijrah. That is why years are written as AH, after Hijrah.",
                    },
                    Quiz = {
                        {
                            Prompt = "Which city did the Muslims migrate to?",
                            Options = { "Ta'if", "Madinah", "Jerusalem", "Damascus" },
                        },
                        {
                            Prompt = "Who travelled with the Prophet on the Hijrah?",
                            Options = { "Abu Bakr", "Umar", "Ali", "Uthman" },
                        },
                        {
                            Prompt = "What were the helpers of Madinah called?",
                            Options = { "Muhajirun", "Ansar", "Quraysh", "Sahabah of Badr" },
                        },
                        {
                            Prompt = "What does AH stand for?",
                            Options = { "After Hajj", "After Hijrah", "Arabian History", "After Hira" },
                        },
                    },
                },
                {
                    Id = "seerah_hudaybiyyah",
                    DisplayName = "The Treaty Of Hudaybiyyah",
                    Summary = "Patience that led to a clear victory.",
                    Pages = {
                        "In 6 AH, the Prophet, peace be upon him, set out with his companions to perform 'umrah, but the Quraysh blocked them at Hudaybiyyah, outside Makkah.",
                        "Instead of fighting, he agreed to a peace treaty. Some terms looked unfair to the Muslims, and some companions were upset.",
                        "Allah then revealed: 'Indeed, We have given you a clear victory' (Qur'an 48:1). The peace allowed Islam to spread quickly as people met Muslims freely.",
                        "Lesson: patience and peace can achieve more than anger. What looks like a loss today can be a victory later.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did the Prophet choose at Hudaybiyyah?",
                            Options = { "A battle", "A peace treaty", "Going home angry", "Breaking the Kaaba's door" },
                        },
                        {
                            Prompt = "What did the Qur'an call the treaty?",
                            Options = { "A defeat", "A clear victory", "A mistake", "A delay" },
                        },
                    },
                },
                {
                    Id = "seerah_conquest_makkah",
                    DisplayName = "The Return To Makkah",
                    Summary = "Forgiveness at the moment of victory.",
                    Pages = {
                        "In 8 AH, after the Quraysh broke the treaty, the Prophet, peace be upon him, returned to Makkah with a large army. The city opened with almost no fighting.",
                        "He removed the idols from around the Kaaba, reciting: 'Truth has come and falsehood has vanished' (Qur'an 17:81; Sahih al-Bukhari 4287).",
                        "Many of the people who had persecuted the Muslims for years were forgiven, and many of them embraced Islam.",
                        "Lesson: true strength is forgiving people when you finally have the power to punish them.",
                    },
                    Quiz = {
                        {
                            Prompt = "What did the Prophet recite while removing the idols?",
                            Options = { "Truth has come and falsehood has vanished", "Allah is the Greatest", "Peace be upon you", "In the name of Allah" },
                        },
                        {
                            Prompt = "How did the Prophet treat the people of Makkah?",
                            Options = { "He took revenge", "He forgave many of them", "He expelled everyone", "He ignored them" },
                        },
                    },
                },
                {
                    Id = "seerah_farewell",
                    DisplayName = "The Farewell Hajj",
                    Summary = "The final message to the ummah.",
                    Pages = {
                        "In 10 AH, the Prophet, peace be upon him, performed his only Hajj, with a huge number of Muslims. It is called the Farewell Hajj.",
                        "At Arafah, Allah revealed: 'This day I have perfected for you your religion' (Qur'an 5:3; Sahih al-Bukhari 45).",
                        "In his sermon he reminded the people that their lives, property, and honour are sacred, told them to treat women kindly, and asked them to convey the message to those who were absent.",
                        "He passed away in Madinah in 11 AH (632 CE). His message lives on in the Qur'an and his Sunnah.",
                        "Lesson: every Muslim helps carry the message forward by learning it and living it.",
                    },
                    Order = {
                        Prompt = "Put these events from the Seerah in order, earliest first.",
                        Steps = {
                            "Birth in Makkah, in the Year of the Elephant",
                            "First revelation in the cave of Hira",
                            "The Battle of Badr",
                            "The Battle of Uhud",
                            "The Conquest of Makkah",
                            "The Farewell Hajj",
                            "The Hijrah to Madinah",
                            "The Treaty of Hudaybiyyah",
                        },
                    },
                    Quiz = {
                        {
                            Prompt = "How many times did the Prophet perform Hajj?",
                            Options = { "Once", "Twice", "Every year", "Never" },
                        },
                        {
                            Prompt = "Which verse was revealed at Arafah during the Farewell Hajj?",
                            Options = { "This day I have perfected for you your religion", "Read in the name of your Lord", "Indeed, with hardship comes ease", "Say, He is Allah, the One" },
                        },
                        {
                            Prompt = "Where did the Prophet pass away?",
                            Options = { "Makkah", "Madinah", "Ta'if", "Jerusalem" },
                        },
                    },
                },
            },
        },
        {
            Id = "calendar",
            DisplayName = "Eids And Special Days",
            Summary = "Celebrations and blessed times in the Islamic year.",
            AccentRGB = { 176, 140, 62 },
            Lessons = {
                {
                    Id = "eid_two",
                    DisplayName = "The Two Eids",
                    Summary = "Celebrations given to the Muslims.",
                    Pages = {
                        "Muslims have two yearly celebrations, Eid al-Fitr and Eid al-Adha.",
                        "Eid al-Fitr comes on 1 Shawwal, right after Ramadan. Before the Eid prayer, families give Zakat al-Fitr, a small charity so that everyone can celebrate.",
                        "Eid al-Adha comes on 10 Dhul-Hijjah, during the days of Hajj. It remembers Prophet Ibrahim's readiness to sacrifice his son for Allah, and Allah's mercy in replacing him with a ram (Qur'an 37:102-107).",
                        "On Eid, Muslims pray the Eid prayer together, wear their best clothes, say takbir (Allahu Akbar), visit family, and share food and gifts.",
                    },
                    Quiz = {
                        {
                            Prompt = "Which Eid comes right after Ramadan?",
                            Options = { "Eid al-Adha", "Eid al-Fitr", "Mawlid", "Ashura" },
                        },
                        {
                            Prompt = "Which Prophet's story is remembered on Eid al-Adha?",
                            Options = { "Musa", "Ibrahim", "Yusuf", "Nuh" },
                        },
                        {
                            Prompt = "What charity is given before the Eid al-Fitr prayer?",
                            Options = { "Zakat al-Fitr", "Hajj fee", "Waqf", "Jizyah" },
                        },
                    },
                },
                {
                    Id = "special_days",
                    DisplayName = "Special Days And Nights",
                    Summary = "Jumu'ah, Laylat al-Qadr, and Arafah.",
                    Pages = {
                        "Every Friday is Jumu'ah. Muslims gather for the Friday prayer and sermon at midday; Allah commands the believers to hurry to it (Qur'an 62:9).",
                        "Laylat al-Qadr, the Night of Decree, is in the last ten nights of Ramadan. It is better than a thousand months (Qur'an 97:3).",
                        "The Day of Arafah, 9 Dhul-Hijjah, is the greatest day of Hajj. For those not on Hajj, fasting it is hoped to wipe away the sins of the previous year and the coming year (Sahih Muslim 1162).",
                        "Lesson: Allah gives us special times when good deeds count for even more. Make the most of them.",
                    },
                    Quiz = {
                        {
                            Prompt = "What is the weekly gathering prayer called?",
                            Options = { "Jumu'ah", "Tarawih", "Eid", "Witr" },
                        },
                        {
                            Prompt = "Laylat al-Qadr is better than how many months?",
                            Options = { "Ten", "One hundred", "One thousand", "Twelve" },
                        },
                        {
                            Prompt = "On which date is the Day of Arafah?",
                            Options = { "1 Shawwal", "9 Dhul-Hijjah", "27 Ramadan", "10 Muharram" },
                        },
                    },
                },
            },
        },
    },
}

return IslamicStudies
