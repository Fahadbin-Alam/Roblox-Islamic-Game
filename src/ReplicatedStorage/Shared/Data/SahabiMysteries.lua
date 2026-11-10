--!strict

-- Sahabi discovery quests: escape-room mysteries about the companions.
--
-- Each mystery is a locked room with clue objects. Players (alone or together: clues found by
-- anyone in the room are shared) read the clues, may take hints, and open the lock by
-- answering questions that the clues answer. Behind the door is a playable episode: a short
-- task drawn from the companion's life. The conclusion explains what happened, lists the
-- sources, and says which parts were game invention.
--
-- Companions are only named in text. The episode yard has no character models of them.

export type Clue = {
    Id: string,
    Object: string,
    Text: string,
    Offset: Vector3,
}

export type LockQuestion = {
    Prompt: string,
    Options: { string },
    CorrectIndex: number,
}

export type Station = {
    Name: string,
    Offset: Vector3,
}

export type Episode = {
    Title: string,
    Description: string,
    -- Stations visited in order when Ordered, any order otherwise.
    Ordered: boolean,
    Stations: { Station },
    FinishText: string,
}

export type Mystery = {
    Id: string,
    Companion: string,
    Title: string,
    Tagline: string,
    Intro: { string },
    Clues: { Clue },
    Hints: { string },
    Lock: { LockQuestion },
    Episode: Episode,
    Conclusion: { string },
    Sources: { string },
    FictionNote: string,
}

local IBN_HISHAM = "Ibn Hisham, al-Sirah al-Nabawiyyah (trans. A. Guillaume)"
local DHAHABI = "Al-Dhahabi, Siyar A'lam al-Nubala'"

local mysteries: { Mystery } = {
    {
        Id = "bilal",
        Companion = "Bilal ibn Rabah",
        Title = "The Voice from the Rooftop",
        Tagline = "Someone left these things in a locked storeroom. Whose life do they tell?",
        Intro = {
            "You wake in a locked storeroom in old Madinah. Five objects lie around the room, each with a note.",
            "Find out whose story they tell. The door's lock asks two questions only that person's story can answer.",
        },
        Clues = {
            { Id = "chain", Object = "Broken iron chain", Text = "Links of the kind put on enslaved people in Makkah. A tag reads: \"Property of Umayyah ibn Khalaf\".", Offset = Vector3.new(-40, 0, -38) },
            { Id = "rock", Object = "Heavy flat rock", Text = "It was laid on a man's chest on the burning sand. Scratched into it, again and again, is one word: \"Ahad\" (One).", Offset = Vector3.new(38, 0, -36) },
            { Id = "receipt", Object = "Merchant's receipt", Text = "\"Paid by Abu Bakr to Umayyah ibn Khalaf: the price of an Abyssinian man's freedom.\"", Offset = Vector3.new(-44, 0, 20) },
            { Id = "dream", Object = "Folded note", Text = "\"Abdullah ibn Zayd saw the words of the adhan in a dream. He was told: teach them to this man, for his voice is stronger than yours.\"", Offset = Vector3.new(42, 0, 24) },
            { Id = "map", Object = "Map of Makkah", Text = "Marked \"8 AH\". An arrow points to the roof of the Kaaba: \"He climbed here and called the adhan on the day Makkah was opened.\"", Offset = Vector3.new(0, 0, -44) },
        },
        Hints = {
            "The chain and the rock tell you he was enslaved and tortured in Makkah.",
            "Abu Bakr bought the freedom of several believers. Which one later became famous for his voice?",
            "He was the first mu'adhdhin of Islam. His name begins with B.",
        },
        Lock = {
            { Prompt = "Whose story do these objects tell?", Options = { "Ammar ibn Yasir", "Bilal ibn Rabah", "Zayd ibn Harithah", "Salman al-Farisi" }, CorrectIndex = 2 },
            { Prompt = "Which word did he repeat while he was tortured?", Options = { "Ahad (One)", "Sabr (Patience)", "Salam (Peace)", "Haqq (Truth)" }, CorrectIndex = 1 },
        },
        Episode = {
            Title = "Up to the Rooftop",
            Description = "The time for prayer has come. Climb the stairs to the rooftop where the adhan was called. Reach each landing in order.",
            Ordered = true,
            Stations = {
                { Name = "Foot of the stairs", Offset = Vector3.new(-30, 0, -20) },
                { Name = "First landing", Offset = Vector3.new(-30, 12, 10) },
                { Name = "Second landing", Offset = Vector3.new(0, 24, 26) },
                { Name = "The rooftop", Offset = Vector3.new(26, 36, 26) },
            },
            FinishText = "From the rooftop the words of the adhan carried over Madinah: Allahu Akbar, Allah is the Greatest.",
        },
        Conclusion = {
            "Bilal ibn Rabah was an Abyssinian man enslaved in Makkah. His master, Umayyah ibn Khalaf, tortured him on the hot sand to make him give up Islam, but he only repeated \"Ahad, Ahad\".",
            "Abu Bakr bought and freed him. Umar later said: Abu Bakr is our master, and he freed our master.",
            "In Madinah he became the first mu'adhdhin. On the day Makkah was opened, he called the adhan from the roof of the Kaaba.",
        },
        Sources = { IBN_HISHAM, "Sahih al-Bukhari 3754 (Umar on Abu Bakr and Bilal)", "Sunan Abi Dawud 499 (the dream of the adhan)" },
        FictionNote = "Invented for the game: the storeroom, the notes, the receipt, and the map. The events the notes describe are documented in the sources.",
    },
    {
        Id = "salman",
        Companion = "Salman al-Farisi",
        Title = "The Long Search",
        Tagline = "A traveller's belongings, from Persia to Madinah. Follow the trail.",
        Intro = {
            "A traveller's pack has been left in a locked guest room. Its objects come from many lands.",
            "Work out who travelled this far, and why.",
        },
        Clues = {
            { Id = "lamp", Object = "Cold fire-temple lamp", Text = "From near Isfahan in Persia. A note: \"My father made me keeper of the fire that must never go out.\"", Offset = Vector3.new(-40, 0, -38) },
            { Id = "bell", Object = "Small church bell", Text = "\"I heard Christians praying and loved their worship more than ours. I left home to learn from their monks: in Syria, Mosul, Nusaybin, then Amuriyah.\"", Offset = Vector3.new(38, 0, -36) },
            { Id = "prophecy", Object = "Monk's parchment", Text = "\"A prophet will appear in a land of palm trees between two lava fields. He accepts gifts but not charity, and between his shoulders is the seal of prophethood.\"", Offset = Vector3.new(-44, 0, 20) },
            { Id = "contract", Object = "Contract of sale", Text = "\"Sold by travelling merchants of the Banu Kalb, who betrayed him, to a man of Yathrib.\"", Offset = Vector3.new(42, 0, 24) },
            { Id = "sapling", Object = "Date-palm sapling", Text = "\"His freedom was agreed for three hundred palm trees planted and forty measures of gold. The Prophet ﷺ planted the saplings with his own hands.\"", Offset = Vector3.new(0, 0, -44) },
        },
        Hints = {
            "He began in Persia and kept searching for the truth through many teachers.",
            "His name tells you where he came from: al-Farisi means \"the Persian\".",
            "His freedom was paid for in palm trees.",
        },
        Lock = {
            { Prompt = "Whose journey is this?", Options = { "Suhayb al-Rumi", "Salman al-Farisi", "Bilal ibn Rabah", "Abu Dharr al-Ghifari" }, CorrectIndex = 2 },
            { Prompt = "What was part of the price of his freedom?", Options = { "A hundred camels", "A house in Makkah", "Three hundred palm trees", "A year of service" }, CorrectIndex = 3 },
        },
        Episode = {
            Title = "Dig the Trench",
            Description = "Years later, an army of ten thousand is coming. Salman suggests a trench, as they dug in Persia. Dig all four sections. Friends can dig together.",
            Ordered = false,
            Stations = {
                { Name = "West section", Offset = Vector3.new(-36, 0, 20) },
                { Name = "West-centre section", Offset = Vector3.new(-12, 0, 20) },
                { Name = "East-centre section", Offset = Vector3.new(12, 0, 20) },
                { Name = "East section", Offset = Vector3.new(36, 0, 20) },
            },
            FinishText = "The trench is finished. The confederate army was stopped at it, and after about a month a cold wind sent them home.",
        },
        Conclusion = {
            "Salman al-Farisi grew up in Persia as keeper of a sacred fire. Searching for the truth, he left home and studied under a chain of Christian monks.",
            "The last one told him of a prophet who would appear in a land of palm trees. On the way there he was betrayed and sold into slavery in Yathrib, which became Madinah.",
            "He met the Prophet ﷺ there and accepted Islam. His freedom was bought with palm trees planted and gold, with the Prophet's ﷺ help. At the Battle of the Trench, his idea helped save Madinah.",
        },
        Sources = { "Musnad Ahmad, Salman's own account of his search", IBN_HISHAM, DHAHABI },
        FictionNote = "Invented for the game: the guest room and the objects. The journey, the price of his freedom, and the trench are reported in the sources.",
    },
    {
        Id = "uthman",
        Companion = "Uthman ibn Affan",
        Title = "The Well of Rumah",
        Tagline = "A bucket, a ledger, two rings, and a sealed box. Who gave so much?",
        Intro = {
            "You are locked in a merchant's counting room. A generous man's records are scattered about.",
            "Discover who he was and what he gave.",
        },
        Clues = {
            { Id = "bucket", Object = "Wooden bucket", Text = "From Rumah, a sweet-water well in Madinah. Its owner sold every bucket, and the poor went thirsty.", Offset = Vector3.new(-40, 0, -38) },
            { Id = "ledger", Object = "Ledger", Text = "\"Bought: the well of Rumah. Price paid in full. Its water is now free for all Muslims.\"", Offset = Vector3.new(38, 0, -36) },
            { Id = "rings", Object = "Two wedding rings", Text = "He married Ruqayyah, a daughter of the Prophet ﷺ, and after her death her sister Umm Kulthum. People called him Dhu al-Nurayn, the Possessor of the Two Lights.", Offset = Vector3.new(-44, 0, 20) },
            { Id = "saddle", Object = "Camel saddle", Text = "\"For the army of Tabuk: camels, saddles, and supplies, all paid for by one man.\"", Offset = Vector3.new(42, 0, 24) },
            { Id = "box", Object = "Sealed box", Text = "Inside, a note: \"As caliph he had copies of the Qur'an written to one standard and sent to the great cities.\"", Offset = Vector3.new(0, 0, -44) },
        },
        Hints = {
            "This man married two daughters of the Prophet ﷺ.",
            "He was the third caliph, after Abu Bakr and Umar.",
            "His title, Dhu al-Nurayn, is written on the rings' note.",
        },
        Lock = {
            { Prompt = "Who bought the well of Rumah?", Options = { "Abd al-Rahman ibn Awf", "Abu Bakr al-Siddiq", "Uthman ibn Affan", "Talhah ibn Ubaydullah" }, CorrectIndex = 3 },
            { Prompt = "What did he do with the well's water?", Options = { "Sold it at a fair price", "Made it free for everyone", "Kept it for his family", "Gave it to the army only" }, CorrectIndex = 2 },
        },
        Episode = {
            Title = "Water for Madinah",
            Description = "Fill the bucket at the well, then carry water to three houses in order.",
            Ordered = true,
            Stations = {
                { Name = "The well of Rumah", Offset = Vector3.new(0, 0, 0) },
                { Name = "First house", Offset = Vector3.new(-36, 0, 30) },
                { Name = "Second house", Offset = Vector3.new(0, 0, 40) },
                { Name = "Third house", Offset = Vector3.new(36, 0, 30) },
            },
            FinishText = "Every house has water. Uthman's gift of the well was remembered as a charity that kept on giving.",
        },
        Conclusion = {
            "Uthman ibn Affan was a wealthy, gentle, and modest merchant among the first to accept Islam.",
            "He bought the well of Rumah and made its water free, equipped a large part of the army of Tabuk, and married two daughters of the Prophet ﷺ, earning the title Dhu al-Nurayn.",
            "As the third caliph he had the Qur'an copied to one standard and sent to the main cities, so Muslims everywhere read the same text.",
        },
        Sources = { "Jami' al-Tirmidhi, Book of Virtues (Uthman and the well of Rumah)", "Sahih al-Bukhari 4987 (the copying of the Qur'an)", DHAHABI },
        FictionNote = "Invented for the game: the counting room, ledger, and carrying water house to house.",
    },
    {
        Id = "asma",
        Companion = "Asma bint Abi Bakr",
        Title = "She of the Two Belts",
        Tagline = "A torn belt and a secret night journey. Who kept the secret?",
        Intro = {
            "You are in a house in old Makkah the night after the Hijrah began. The door is barred.",
            "Search the room and find out who was trusted with the greatest secret in Makkah.",
        },
        Clues = {
            { Id = "belt", Object = "Torn belt", Text = "A woman's waist-belt torn in two. One half tied the food bundle, the other the water skin.", Offset = Vector3.new(-40, 0, -38) },
            { Id = "bundle", Object = "Empty food cloth", Text = "\"Carried at night up Mount Thawr for three nights, to the cave where my father and the Prophet ﷺ hid.\"", Offset = Vector3.new(38, 0, -36) },
            { Id = "stones", Object = "Cloth of pebbles", Text = "\"My blind grandfather feared my father had left us nothing. I put stones where the money was kept and laid his hand on them so he would feel at ease.\"", Offset = Vector3.new(-44, 0, 20) },
            { Id = "door", Object = "Note by the door", Text = "\"Abu Jahl came demanding to know where my father was. I would not tell him, and he struck me.\"", Offset = Vector3.new(42, 0, 24) },
            { Id = "cradle", Object = "Baby's cradle", Text = "\"My son Abdullah ibn al-Zubayr: the first child born to the emigrants in Madinah.\"", Offset = Vector3.new(0, 0, -44) },
        },
        Hints = {
            "Her father went on the Hijrah with the Prophet ﷺ.",
            "Her father was Abu Bakr. Her sister was Aisha.",
            "She tore her belt in two, so she was called \"She of the Two Belts\".",
        },
        Lock = {
            { Prompt = "Who is the owner of the torn belt?", Options = { "Aisha bint Abi Bakr", "Asma bint Abi Bakr", "Fatimah bint Muhammad", "Umm Salamah" }, CorrectIndex = 2 },
            { Prompt = "What would she not tell Abu Jahl?", Options = { "Where her father was", "Her own name", "Where the Kaaba key was", "Who her husband was" }, CorrectIndex = 1 },
        },
        Episode = {
            Title = "Night Run to Thawr",
            Description = "Take the food bundle and climb the path to the cave in order, staying on the path.",
            Ordered = true,
            Stations = {
                { Name = "Pick up the food bundle", Offset = Vector3.new(-36, 0, -30) },
                { Name = "Foot of Mount Thawr", Offset = Vector3.new(-20, 4, 6) },
                { Name = "Rocky switchback", Offset = Vector3.new(10, 12, 22) },
                { Name = "Mouth of the cave", Offset = Vector3.new(34, 20, 34) },
            },
            FinishText = "The food reached the cave safely. For three nights Asma kept the secret and the supplies coming.",
        },
        Conclusion = {
            "Asma bint Abi Bakr was the elder sister of Aisha. During the Hijrah she carried food to the cave of Thawr, tearing her belt in two to tie it, and was called Dhat al-Nitaqayn, She of the Two Belts.",
            "She refused to tell Abu Jahl where her father was, even when he struck her, and comforted her blind grandfather with a cloth of stones.",
            "She lived to about a hundred. Her son Abdullah ibn al-Zubayr was the first child born to the emigrants in Madinah.",
        },
        Sources = { "Sahih al-Bukhari 3905 (the two belts)", "Sahih al-Bukhari 3909 (the birth of Abdullah ibn al-Zubayr)", IBN_HISHAM },
        FictionNote = "Invented for the game: the barred house, the notes in her words, and the path stations.",
    },
    {
        Id = "musab",
        Companion = "Mus'ab ibn Umayr",
        Title = "The Ambassador",
        Tagline = "Perfume, a locked chest, and a cloak too short. Who gave up everything?",
        Intro = {
            "A once-rich young man's room has been locked from the outside.",
            "Find out who he was, what he gave up, and where he was sent.",
        },
        Clues = {
            { Id = "perfume", Object = "Perfume bottle", Text = "\"The best-dressed, best-scented young man in Makkah,\" a note says. \"His mother gave him everything.\"", Offset = Vector3.new(-40, 0, -38) },
            { Id = "chest", Object = "Locked chest", Text = "\"When his mother learned he had become Muslim, she locked him up and cut him off from her wealth.\"", Offset = Vector3.new(38, 0, -36) },
            { Id = "pledge", Object = "Letter of the pledge", Text = "\"After the First Pledge of al-Aqabah, he went back with the people of Yathrib to teach them the Qur'an.\"", Offset = Vector3.new(-44, 0, 20) },
            { Id = "spear", Object = "Spear set down", Text = "\"Usayd ibn Hudayr came at him with a spear. He said: sit and listen; if you like it, accept it, and if not, we will stop. Usayd sat, listened, and accepted Islam, and so did Sa'd ibn Mu'adh.\"", Offset = Vector3.new(42, 0, 24) },
            { Id = "cloak", Object = "Short cloak", Text = "\"Martyred at Uhud holding the banner. His only cloak could cover his head or his feet, not both.\"", Offset = Vector3.new(0, 0, -44) },
        },
        Hints = {
            "He was rich in Makkah and gave it all up for Islam.",
            "He was the first teacher sent to Yathrib.",
            "His name begins with M and he carried the banner at Uhud.",
        },
        Lock = {
            { Prompt = "Who was this young man?", Options = { "Mus'ab ibn Umayr", "Sa'd ibn Abi Waqqas", "Usayd ibn Hudayr", "Khalid ibn al-Walid" }, CorrectIndex = 1 },
            { Prompt = "What was he sent to Yathrib to do?", Options = { "Trade", "Lead an army", "Teach the Qur'an", "Collect taxes" }, CorrectIndex = 3 },
        },
        Episode = {
            Title = "Teach Yathrib",
            Description = "Take Qur'an lessons to four households of Yathrib. Visit them in any order. Friends can split the houses.",
            Ordered = false,
            Stations = {
                { Name = "House of the Banu Abd al-Ashhal", Offset = Vector3.new(-36, 0, -24) },
                { Name = "House by the palm grove", Offset = Vector3.new(36, 0, -24) },
                { Name = "House by the well", Offset = Vector3.new(-36, 0, 30) },
                { Name = "House at the market", Offset = Vector3.new(36, 0, 30) },
            },
            FinishText = "By the next pilgrimage season, there was hardly a house in Yathrib without someone who had accepted Islam.",
        },
        Conclusion = {
            "Mus'ab ibn Umayr gave up wealth and comfort in Makkah when he accepted Islam, and his mother cut him off.",
            "He was sent to Yathrib as its first teacher. Through his patience and gentle words, leaders like Usayd ibn Hudayr and Sa'd ibn Mu'adh accepted Islam, and the city was ready for the Hijrah.",
            "He was martyred at Uhud carrying the banner. His cloak was too short to cover him fully, so his feet were covered with grass.",
        },
        Sources = { IBN_HISHAM, "Sahih al-Bukhari 1276 (narrated by Khabbab, on Mus'ab's shroud)", DHAHABI },
        FictionNote = "Invented for the game: the locked room, the notes, and delivering lessons house to house.",
    },
}

return {
    Mysteries = mysteries,
    -- Fewer hints and fewer wrong lock tries earn more stars.
    MaxStars = 3,
    -- Size of each room and its episode yard, in studs.
    RoomSize = 120,
    -- How close a player must be to a station to activate it.
    StationRadius = 10,
}
