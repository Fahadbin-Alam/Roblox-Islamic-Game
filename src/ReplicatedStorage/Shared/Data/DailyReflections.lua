--!strict

-- One reflection is shown each day in the Islamic Studies hall, cycling through this list.
-- Every entry is a short, widely known ayah or authentic hadith with its reference.

export type Reflection = {
    Text: string,
    Source: string,
    Thought: string,
}

local DailyReflections: { Reflection } = {
    {
        Text = "Indeed, with hardship comes ease.",
        Source = "Qur'an 94:6",
        Thought = "When something feels hard today, remember that Allah has promised ease alongside it.",
    },
    {
        Text = "So remember Me; I will remember you.",
        Source = "Qur'an 2:152",
        Thought = "Say SubhanAllah, Alhamdulillah, or Allahu Akbar a few times today and remember Allah is remembering you.",
    },
    {
        Text = "Allah does not burden a soul beyond what it can bear.",
        Source = "Qur'an 2:286",
        Thought = "Whatever you are facing, you have been given the strength to handle it.",
    },
    {
        Text = "And speak to people good words.",
        Source = "Qur'an 2:83",
        Thought = "Try to say something kind to every person you talk to today, online or offline.",
    },
    {
        Text = "Indeed, Allah is with the patient.",
        Source = "Qur'an 2:153",
        Thought = "Patience is not doing nothing. It is staying calm and doing the right thing while you wait.",
    },
    {
        Text = "Verily, in the remembrance of Allah do hearts find rest.",
        Source = "Qur'an 13:28",
        Thought = "If you feel worried, take a quiet minute to make dua.",
    },
    {
        Text = "Whoever does an atom's weight of good will see it.",
        Source = "Qur'an 99:7",
        Thought = "No good deed is too small. Holding a door or sharing a snack counts.",
    },
    {
        Text = "The most noble of you in the sight of Allah is the most righteous of you.",
        Source = "Qur'an 49:13",
        Thought = "What makes someone great is their character, not their looks, money, or where they come from.",
    },
    {
        Text = "Actions are judged by intentions.",
        Source = "Sahih al-Bukhari 1",
        Thought = "Before you start something, make the intention to do it for Allah. Even studying can become worship.",
    },
    {
        Text = "None of you truly believes until he loves for his brother what he loves for himself.",
        Source = "Sahih al-Bukhari 13",
        Thought = "Cheer for your friends when they win, the way you would want them to cheer for you.",
    },
    {
        Text = "The strong person is not the one who wrestles others down, but the one who controls himself when angry.",
        Source = "Sahih al-Bukhari 6114",
        Thought = "If a game or a person makes you angry today, pause and breathe before you react.",
    },
    {
        Text = "Whoever believes in Allah and the Last Day, let him speak good or stay silent.",
        Source = "Sahih al-Bukhari 6018",
        Thought = "Check your words in chat today: if it isn't good, it's better not to send it.",
    },
    {
        Text = "The best of you are those who learn the Qur'an and teach it.",
        Source = "Sahih al-Bukhari 5027",
        Thought = "Learn one new ayah or its meaning today, then share it with someone.",
    },
    {
        Text = "Make things easy and do not make them difficult.",
        Source = "Sahih al-Bukhari 69",
        Thought = "Help a new player or a younger sibling today instead of making things harder for them.",
    },
    {
        Text = "Allah does not look at your appearance or wealth, but He looks at your hearts and deeds.",
        Source = "Sahih Muslim 2564",
        Thought = "Focus on being a good person rather than on looking cool.",
    },
    {
        Text = "Your smile in the face of your brother is charity.",
        Source = "Jami' at-Tirmidhi 1956",
        Thought = "Smiling is a sadaqah you can give for free, as many times as you like.",
    },
    {
        Text = "The most beloved deeds to Allah are those done regularly, even if they are small.",
        Source = "Sahih al-Bukhari 6464",
        Thought = "Coming back every day to learn a little is exactly the kind of habit Allah loves.",
    },
    {
        Text = "Whoever takes a path seeking knowledge, Allah makes easy for him a path to Paradise.",
        Source = "Sahih Muslim 2699",
        Thought = "Every lesson you finish here is a step on that path.",
    },
    {
        Text = "Do not become angry.",
        Source = "Sahih al-Bukhari 6116",
        Thought = "This was the advice given to a man who asked for something short to remember. Try it today.",
    },
    {
        Text = "My Lord, increase me in knowledge.",
        Source = "Qur'an 20:114",
        Thought = "Make this dua before you start a lesson or your homework.",
    },
}

return DailyReflections
