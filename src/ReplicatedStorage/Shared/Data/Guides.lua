--!strict

-- Friendly teachers who stand around the hub and point players to their next quest on the
-- suggested path. They are ordinary present-day teachers, not historical figures, so nobody
-- from the Seerah is ever shown as a character.

export type Guide = {
    Id: string,
    DisplayName: string,
    Role: string,
    -- Placed beside this TravelRoute destination's teleport point, at this offset.
    Destination: string,
    Offset: Vector3,
    -- Body colors for the teacher's avatar (head, torso, arms, legs).
    SkinRGB: { number },
    RobeRGB: { number },
    Greeting: string,
    -- Short reminders, one picked at random each conversation.
    Sayings: { string },
}

local Guides: { Guide } = {
    {
        Id = "noor",
        DisplayName = "Ustadha Noor",
        Role = "Welcome Guide",
        Destination = "kaaba_courtyard",
        Offset = Vector3.new(16, 0, 6),
        SkinRGB = { 198, 150, 112 },
        RobeRGB = { 63, 98, 88 },
        Greeting = "Assalamu alaykum, welcome! I help new students find their way around.",
        Sayings = {
            "The Prophet ﷺ said: \"Whoever takes a path seeking knowledge, Allah makes easy for him a path to Paradise.\" (Sahih Muslim 2699)",
            "Learning a little every day is better than a lot once in a while.",
            "Bring a friend to the Trivia Court and you can study together in a circle.",
        },
    },
    {
        Id = "kareem",
        DisplayName = "Ustadh Kareem",
        Role = "Islamic Studies Teacher",
        Destination = "trivia_court",
        Offset = Vector3.new(-30, 0, 4),
        SkinRGB = { 141, 98, 70 },
        RobeRGB = { 240, 236, 224 },
        Greeting = "Assalamu alaykum! The Islamic Studies podium is right behind me.",
        Sayings = {
            "Allah says: \"Say, are those who know equal to those who do not know?\" (Qur'an 39:9)",
            "Take your time with each lesson page. The quiz is there to help you remember.",
            "Ask your local imam or teacher about anything you want to learn more deeply.",
        },
    },
    {
        Id = "salim",
        DisplayName = "Storyteller Salim",
        Role = "Story Keeper",
        Destination = "story_court",
        Offset = Vector3.new(18, 0, 4),
        SkinRGB = { 176, 128, 92 },
        RobeRGB = { 121, 94, 63 },
        Greeting = "Assalamu alaykum, friend! Every companion's story holds a lesson for us.",
        Sayings = {
            "Allah says: \"In their stories there is truly a lesson for people of understanding.\" (Qur'an 12:111)",
            "The companions were ordinary people who chose to be brave, honest, and kind.",
            "After a story, think about one thing you can do like that companion did.",
        },
    },
}

return Guides
