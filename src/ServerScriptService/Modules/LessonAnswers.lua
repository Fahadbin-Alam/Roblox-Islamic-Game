--!strict

-- Answer keys for the Islamic Studies lessons in ReplicatedStorage/Shared/Data/IslamicStudies.lua.
-- This module is in ServerScriptService, which Roblox never sends to clients: players get the
-- questions and options, the server keeps the answers, grades, and only then reveals the
-- right answer and explanation. It is also used by the daily question and the study circle.
--
-- Quiz[i] is the key for lesson.Quiz[i] (the comment repeats the prompt to keep them lined up).
-- Order.Steps lists an order puzzle's steps in the correct order; the shared lesson file lists
-- the same steps alphabetically. tests/luau/answers.spec.luau fails if the two files drift.

export type QuizKey = {
    CorrectIndex: number,
    Explanation: string,
}

export type OrderKey = {
    Steps: { string },
    Explanation: string,
}

export type LessonKey = {
    Quiz: { QuizKey },
    Order: OrderKey?,
}

local LessonAnswers: { [string]: LessonKey } = {
    pillars_intro = {
        Quiz = {
            -- How many pillars of Islam are there?
            { CorrectIndex = 2, Explanation = "Islam is built on five pillars, as taught in Sahih al-Bukhari 8." },
            -- Which of these is NOT one of the five pillars?
            { CorrectIndex = 3, Explanation = "Reading is a great habit, but the pillars are Shahadah, Salah, Zakah, Sawm, and Hajj." },
            -- Why are they called pillars?
            { CorrectIndex = 2, Explanation = "Like pillars holding up a building, these five acts hold up a Muslim's religion." },
        },
    },
    shahadah = {
        Quiz = {
            -- What does 'la ilaha illa Allah' mean?
            { CorrectIndex = 2, Explanation = "It is the declaration of tawhid: worship belongs to Allah alone." },
            -- What is the belief that Allah is One with no partner called?
            { CorrectIndex = 1, Explanation = "Tawhid means the Oneness of Allah." },
            -- Which pillar comes first?
            { CorrectIndex = 3, Explanation = "The Shahadah is the first pillar and the foundation for the rest." },
        },
    },
    salah_pillar = {
        Quiz = {
            -- How many obligatory prayers are there each day?
            { CorrectIndex = 3, Explanation = "Fajr, Dhuhr, Asr, Maghrib, and Isha." },
            -- Which prayer is prayed just after sunset?
            { CorrectIndex = 2, Explanation = "Maghrib begins right after the sun sets and has 3 rak'ahs." },
            -- What is the direction Muslims face in prayer called?
            { CorrectIndex = 1, Explanation = "The qiblah is the direction of the Kaaba in Makkah." },
            -- How many rak'ahs does Fajr have?
            { CorrectIndex = 1, Explanation = "The obligatory Fajr prayer has 2 rak'ahs." },
        },
    },
    zakah = {
        Quiz = {
            -- What does the word Zakah mean?
            { CorrectIndex = 2, Explanation = "Zakah purifies wealth and makes it grow in blessing." },
            -- What portion of qualifying savings is given as Zakah?
            { CorrectIndex = 2, Explanation = "Zakah on savings is 2.5% once they have stayed above the nisab for a lunar year." },
            -- What is voluntary charity called?
            { CorrectIndex = 1, Explanation = "Sadaqah is any voluntary charity, even a kind smile." },
        },
    },
    sawm = {
        Quiz = {
            -- In which month do Muslims fast?
            { CorrectIndex = 2, Explanation = "The obligatory fast is in Ramadan, the ninth month of the Islamic calendar." },
            -- What is the meal before dawn called?
            { CorrectIndex = 2, Explanation = "Suhur is eaten before dawn; iftar breaks the fast at sunset." },
            -- According to Qur'an 2:183, fasting helps us gain what?
            { CorrectIndex = 1, Explanation = "Fasting was prescribed so that believers may gain taqwa, mindfulness of Allah." },
        },
    },
    hajj = {
        Quiz = {
            -- How often must an able Muslim perform Hajj?
            { CorrectIndex = 2, Explanation = "Hajj is obligatory once in a lifetime for those who are able." },
            -- What is walking around the Kaaba seven times called?
            { CorrectIndex = 2, Explanation = "Tawaf is circling the Kaaba seven times. Sa'i is walking between Safa and Marwah." },
            -- Who raised the foundations of the Kaaba?
            { CorrectIndex = 2, Explanation = "Qur'an 2:127 tells of Ibrahim and Isma'il, peace be upon them, raising the House." },
        },
    },
    wudu = {
        Quiz = {
            -- What do you say when beginning wudu?
            { CorrectIndex = 2, Explanation = "Begin wudu with the intention and Bismillah, in the name of Allah." },
            -- How far are the arms washed in wudu?
            { CorrectIndex = 2, Explanation = "Qur'an 5:6 says to wash the arms up to the elbows." },
            -- Which side do you wash first for arms and feet?
            { CorrectIndex = 2, Explanation = "The Sunnah is to begin with the right side." },
            -- What is done to the head in wudu?
            { CorrectIndex = 1, Explanation = "The head is wiped with wet hands, not washed." },
        },
        Order = {
            Steps = {
                "Intention and Bismillah",
                "Wash the hands",
                "Rinse the mouth",
                "Rinse the nose",
                "Wash the face",
                "Wash the arms to the elbows, right first",
                "Wipe the head and ears",
                "Wash the feet to the ankles, right first",
            },
            Explanation = "This is the order taught in the lesson, following Qur'an 5:6 and the Sunnah.",
        },
    },
    salah_steps = {
        Quiz = {
            -- What words begin the prayer?
            { CorrectIndex = 2, Explanation = "The opening takbir, 'Allahu Akbar', begins the prayer." },
            -- Which surah is recited in every rak'ah?
            { CorrectIndex = 2, Explanation = "Surah Al-Fatihah is recited while standing in every rak'ah." },
            -- What is the bowing position called?
            { CorrectIndex = 3, Explanation = "Ruku' is bowing; sujud is prostrating with the forehead on the ground." },
            -- What do you say in sujud?
            { CorrectIndex = 1, Explanation = "In sujud: Glory be to my Lord, the Most High. In ruku': the Most Great." },
            -- How does the prayer end?
            { CorrectIndex = 2, Explanation = "The prayer ends with 'As-salamu 'alaykum wa rahmatullah', right then left." },
        },
        Order = {
            Steps = {
                "Face the qiblah with the intention",
                "Opening takbir: Allahu Akbar",
                "Stand and recite Al-Fatihah",
                "Bow in ruku'",
                "Rise: Sami'a Allahu liman hamidah",
                "Prostrate in sujud twice",
                "Sit for the tashahhud",
                "End with salam, right then left",
            },
            Explanation = "Each rak'ah repeats standing, ruku', rising, and two sujud. The tashahhud and salam come at the end.",
        },
    },
    duas_eating = {
        Quiz = {
            -- What do you say before eating?
            { CorrectIndex = 1, Explanation = "Begin every meal with Bismillah." },
            -- If you forgot Bismillah at the start of a meal, what do you say?
            { CorrectIndex = 2, Explanation = "In the name of Allah, at its beginning and its end." },
            -- Which hand is the Sunnah for eating?
            { CorrectIndex = 2, Explanation = "The Prophet, peace be upon him, taught: eat with your right hand." },
        },
    },
    duas_sleep = {
        Quiz = {
            -- What does 'Bismika Allahumma amutu wa ahya' mean?
            { CorrectIndex = 1, Explanation = "It is the dua before sleeping." },
            -- When do you say 'Alhamdu lillahil-ladhi ahyana...'?
            { CorrectIndex = 2, Explanation = "It thanks Allah for giving us life again after sleep." },
        },
    },
    duas_home_masjid = {
        Quiz = {
            -- Which foot do you enter the masjid with?
            { CorrectIndex = 2, Explanation = "Enter with the right foot and leave with the left." },
            -- Entering the masjid, you ask Allah to open the doors of His...
            { CorrectIndex = 1, Explanation = "'Allahummaf-tah li abwaba rahmatik': O Allah, open for me the doors of Your mercy." },
            -- What does 'tawakkaltu 'alallah' mean?
            { CorrectIndex = 1, Explanation = "It is said when leaving home, placing your trust in Allah." },
        },
    },
    duas_everyday = {
        Quiz = {
            -- Someone sneezes and says Alhamdulillah. What do you reply?
            { CorrectIndex = 2, Explanation = "Reply 'Yarhamukallah', may Allah have mercy on you." },
            -- 'Rabbi zidni 'ilma' asks Allah for more...
            { CorrectIndex = 2, Explanation = "My Lord, increase me in knowledge (Qur'an 20:114)." },
            -- Which dua is for your parents?
            { CorrectIndex = 1, Explanation = "My Lord, have mercy on them as they raised me when I was small (Qur'an 17:24)." },
        },
    },
    iman_six = {
        Quiz = {
            -- How many articles of iman are there?
            { CorrectIndex = 3, Explanation = "Allah, angels, books, messengers, the Last Day, and qadr." },
            -- Which angel brought revelation to the prophets?
            { CorrectIndex = 1, Explanation = "Jibril, peace be upon him, brought Allah's revelation." },
            -- Which book was given to Prophet Musa?
            { CorrectIndex = 3, Explanation = "The Tawrah was revealed to Musa, peace be upon him." },
        },
    },
    prophet_nuh = {
        Quiz = {
            -- What did Allah command Nuh to build?
            { CorrectIndex = 2, Explanation = "Qur'an 11:37: build the ark under Our eyes and Our inspiration." },
            -- What is the main lesson from Nuh's story?
            { CorrectIndex = 2, Explanation = "Nuh stayed patient and faithful for centuries." },
        },
    },
    prophet_ibrahim = {
        Quiz = {
            -- What did Allah command the fire to be for Ibrahim?
            { CorrectIndex = 2, Explanation = "Qur'an 21:69: be coolness and safety upon Ibrahim." },
            -- Who helped Ibrahim build the Kaaba?
            { CorrectIndex = 2, Explanation = "Ibrahim and Isma'il raised its foundations together (Qur'an 2:127)." },
        },
    },
    prophet_yusuf = {
        Quiz = {
            -- What did Yusuf say to his brothers at the end?
            { CorrectIndex = 2, Explanation = "He forgave them completely (Qur'an 12:92)." },
            -- What does Allah call Yusuf's story?
            { CorrectIndex = 1, Explanation = "Qur'an 12:3 calls it the best of stories." },
        },
    },
    prophet_musa = {
        Quiz = {
            -- What did Musa say when the army was behind them?
            { CorrectIndex = 2, Explanation = "Qur'an 26:62 records his complete trust in Allah." },
            -- What happened when Musa struck the sea?
            { CorrectIndex = 2, Explanation = "By Allah's command, the sea parted (Qur'an 26:63)." },
        },
    },
    prophet_yunus = {
        Quiz = {
            -- Where was Yunus when he made his famous dua?
            { CorrectIndex = 2, Explanation = "He called to Allah from inside the fish (Qur'an 21:87)." },
            -- What is the lesson of Yunus's dua?
            { CorrectIndex = 2, Explanation = "He admitted his mistake and Allah saved him." },
        },
    },
    prophet_adam = {
        Quiz = {
            -- What did Allah teach Adam?
            { CorrectIndex = 2, Explanation = "Qur'an 2:31: Allah taught Adam the names of all things." },
            -- What did Adam and his wife do after their mistake?
            { CorrectIndex = 2, Explanation = "They repented with the dua in Qur'an 7:23, and Allah forgave them." },
        },
    },
    prophet_ayyub = {
        Quiz = {
            -- What quality is Ayyub most famous for?
            { CorrectIndex = 2, Explanation = "Qur'an 38:44: We found him patient. An excellent servant." },
            -- How did Ayyub ask Allah for help?
            { CorrectIndex = 2, Explanation = "His dua in Qur'an 21:83 names Allah as the Most Merciful of the merciful." },
        },
    },
    prophet_sulayman = {
        Quiz = {
            -- Who warned the others about Sulayman's army?
            { CorrectIndex = 2, Explanation = "An ant warned its colony (Qur'an 27:18)." },
            -- How did Sulayman respond?
            { CorrectIndex = 2, Explanation = "He prayed to be grateful for Allah's favours (Qur'an 27:19)." },
        },
    },
    prophet_isa = {
        Quiz = {
            -- What did baby Isa say from the cradle?
            { CorrectIndex = 2, Explanation = "Qur'an 19:30: I am the servant of Allah; He gave me the Scripture and made me a prophet." },
            -- Which book was given to Isa?
            { CorrectIndex = 3, Explanation = "The Injil was revealed to Isa, peace be upon him." },
            -- By whose permission did Isa perform miracles?
            { CorrectIndex = 2, Explanation = "Qur'an 5:110 repeats: by My permission." },
        },
        Order = {
            Steps = {
                "Adam",
                "Nuh",
                "Ibrahim",
                "Yusuf",
                "Musa",
                "Sulayman",
                "Isa",
            },
            Explanation = "Adam was the first human. Yusuf was Ibrahim's great-grandson, Musa came after Yusuf's family settled in Egypt, Sulayman was the son of Dawud, and Isa came last before Muhammad, peace be upon them all.",
        },
    },
    seerah_early_life = {
        Quiz = {
            -- What was the Prophet called because of his honesty?
            { CorrectIndex = 1, Explanation = "Al-Amin means the trustworthy one." },
            -- Which surah tells of the army with elephants?
            { CorrectIndex = 1, Explanation = "Surah Al-Fil (105) describes how Allah protected the Kaaba." },
            -- Who raised him after his grandfather died?
            { CorrectIndex = 2, Explanation = "His uncle Abu Talib raised and protected him." },
        },
    },
    seerah_first_revelation = {
        Quiz = {
            -- Where did the first revelation come?
            { CorrectIndex = 2, Explanation = "The first verses came in the cave of Hira." },
            -- What was the first word revealed?
            { CorrectIndex = 2, Explanation = "Qur'an 96:1 begins 'Read' (Iqra)." },
            -- Who was the first person to believe?
            { CorrectIndex = 1, Explanation = "Khadijah, may Allah be pleased with her, believed first." },
        },
    },
    seerah_hijrah = {
        Quiz = {
            -- Which city did the Muslims migrate to?
            { CorrectIndex = 2, Explanation = "The Hijrah was to Yathrib, which became Madinah." },
            -- Who travelled with the Prophet on the Hijrah?
            { CorrectIndex = 1, Explanation = "Abu Bakr as-Siddiq was his companion in the cave (Qur'an 9:40)." },
            -- What were the helpers of Madinah called?
            { CorrectIndex = 2, Explanation = "The Ansar helped the Muhajirun who migrated." },
            -- What does AH stand for?
            { CorrectIndex = 2, Explanation = "The Islamic calendar counts from the Hijrah." },
        },
    },
    seerah_hudaybiyyah = {
        Quiz = {
            -- What did the Prophet choose at Hudaybiyyah?
            { CorrectIndex = 2, Explanation = "He agreed to a treaty of peace." },
            -- What did the Qur'an call the treaty?
            { CorrectIndex = 2, Explanation = "Qur'an 48:1: We have given you a clear victory." },
        },
    },
    seerah_conquest_makkah = {
        Quiz = {
            -- What did the Prophet recite while removing the idols?
            { CorrectIndex = 1, Explanation = "Qur'an 17:81, as narrated in Sahih al-Bukhari 4287." },
            -- How did the Prophet treat the people of Makkah?
            { CorrectIndex = 2, Explanation = "His forgiveness led many to embrace Islam." },
        },
    },
    seerah_farewell = {
        Quiz = {
            -- How many times did the Prophet perform Hajj?
            { CorrectIndex = 1, Explanation = "His only Hajj was the Farewell Hajj in 10 AH." },
            -- Which verse was revealed at Arafah during the Farewell Hajj?
            { CorrectIndex = 1, Explanation = "Qur'an 5:3, as Sahih al-Bukhari 45 reports." },
            -- Where did the Prophet pass away?
            { CorrectIndex = 2, Explanation = "He passed away in Madinah in 11 AH." },
        },
        Order = {
            Steps = {
                "Birth in Makkah, in the Year of the Elephant",
                "First revelation in the cave of Hira",
                "The Hijrah to Madinah",
                "The Battle of Badr",
                "The Battle of Uhud",
                "The Treaty of Hudaybiyyah",
                "The Conquest of Makkah",
                "The Farewell Hajj",
            },
            Explanation = "Birth around 570 CE, first revelation at age 40, Hijrah in 1 AH, Badr in 2 AH, Uhud in 3 AH, Hudaybiyyah in 6 AH, the Conquest in 8 AH, and the Farewell Hajj in 10 AH.",
        },
    },
    eid_two = {
        Quiz = {
            -- Which Eid comes right after Ramadan?
            { CorrectIndex = 2, Explanation = "Eid al-Fitr is on 1 Shawwal, ending Ramadan." },
            -- Which Prophet's story is remembered on Eid al-Adha?
            { CorrectIndex = 2, Explanation = "Ibrahim's readiness to sacrifice, and Allah's mercy (Qur'an 37:102-107)." },
            -- What charity is given before the Eid al-Fitr prayer?
            { CorrectIndex = 1, Explanation = "Zakat al-Fitr helps everyone enjoy Eid." },
        },
    },
    special_days = {
        Quiz = {
            -- What is the weekly gathering prayer called?
            { CorrectIndex = 1, Explanation = "The Friday prayer is Jumu'ah (Qur'an 62:9)." },
            -- Laylat al-Qadr is better than how many months?
            { CorrectIndex = 3, Explanation = "Qur'an 97:3: better than a thousand months." },
            -- On which date is the Day of Arafah?
            { CorrectIndex = 2, Explanation = "Arafah is on 9 Dhul-Hijjah." },
        },
    },
}

return LessonAnswers
