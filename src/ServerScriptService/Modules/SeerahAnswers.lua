--!strict

-- Answer keys for the Seerah campaign's chapter decisions (Shared/Data/SeerahCampaign.lua).
-- Server only: the chapters the client sees carry the prompt and options, never the answer or
-- the explanation (which gives the answer away). JourneyGrading.CheckSeerahKeys verifies at
-- startup and in tests/luau that every chapter has exactly one valid key here.
--
-- The text below was moved here unchanged from SeerahCampaign.lua.

export type Key = { CorrectIndex: number, Explanation: string }

local keys: { [string]: Key } = {
    year_of_elephant = table.freeze({ CorrectIndex = 2, Explanation = "He asked for his camels and trusted that the House had a Lord who would protect it." }),
    orphan_years = table.freeze({ CorrectIndex = 3, Explanation = "Abu Talib took him in when he was about eight and protected him for decades." }),
    al_amin = table.freeze({ CorrectIndex = 2, Explanation = "Quraysh leaders swore to support the oppressed until justice was done, whoever they were." }),
    khadijah = table.freeze({ CorrectIndex = 3, Explanation = "His reputation for honesty led her to trust him with her goods." }),
    black_stone = table.freeze({ CorrectIndex = 3, Explanation = "Every clan shared the honour, so no one was left out and no blood was shed." }),
    first_revelation = table.freeze({ CorrectIndex = 2, Explanation = "She reassured him by naming his good character and sought advice from a wise relative." }),
    first_believers = table.freeze({ CorrectIndex = 1, Explanation = "The community was small and could be harmed, so they learned in a safe place first." }),
    call_from_safa = table.freeze({ CorrectIndex = 2, Explanation = "Even the people who rejected his message admitted they had never known him to lie." }),
    persecution = table.freeze({ CorrectIndex = 3, Explanation = "Abu Bakr spent his own wealth to free Bilal and other enslaved believers." }),
    abyssinia = table.freeze({ CorrectIndex = 2, Explanation = "Moved by what he heard, the just king protected the emigrants." }),
    umar_islam = table.freeze({ CorrectIndex = 2, Explanation = "The opening verses of Surah Ta-Ha softened Umar's heart." }),
    boycott = table.freeze({ CorrectIndex = 2, Explanation = "Some of Quraysh themselves campaigned against the injustice, and the document was found destroyed." }),
    year_of_sorrow = table.freeze({ CorrectIndex = 2, Explanation = "He lost both his protector and his closest support in the same year." }),
    taif = table.freeze({ CorrectIndex = 3, Explanation = "Even after being hurt, he chose mercy and hoped for their future guidance." }),
    isra_miraj = table.freeze({ CorrectIndex = 2, Explanation = "The five daily prayers were given on that night, which shows how central salah is." }),
    aqabah = table.freeze({ CorrectIndex = 1, Explanation = "Mus'ab ibn Umayr taught the Qur'an in Yathrib, and many families accepted Islam through him." }),
    hijrah = table.freeze({ CorrectIndex = 2, Explanation = "Ali took his place so he could leave safely, and then returned the trusts to their owners." }),
    arrival_madinah = table.freeze({ CorrectIndex = 2, Explanation = "He let the camel choose so no family would feel passed over, and paid the orphans for their land." }),
    mosque_brotherhood = table.freeze({ CorrectIndex = 3, Explanation = "He thanked Sa'd for his generosity but chose to earn his own living." }),
    charter_madinah = table.freeze({ CorrectIndex = 2, Explanation = "It was an agreement of rights, duties, and shared defence among Madinah's communities." }),
    qiblah = table.freeze({ CorrectIndex = 2, Explanation = "Since then, Muslims everywhere face the Kaaba in prayer." }),
    badr = table.freeze({ CorrectIndex = 2, Explanation = "Teaching children to read shows how much Islam valued learning, even from former enemies." }),
    uhud = table.freeze({ CorrectIndex = 2, Explanation = "Leaving the post opened the way for the cavalry attack from behind." }),
    trench = table.freeze({ CorrectIndex = 2, Explanation = "Salman knew the defence from Persia, and his advice was taken." }),
    hudaybiyyah = table.freeze({ CorrectIndex = 2, Explanation = "In the two years of peace, more people entered Islam than in all the years before." }),
    letters = table.freeze({ CorrectIndex = 1, Explanation = "Even an opponent, questioned by an emperor, could not accuse him of lying." }),
    conquest_makkah = table.freeze({ CorrectIndex = 2, Explanation = "A general amnesty was given. Mercy, not revenge, marked the return to Makkah." }),
    tabuk = table.freeze({ CorrectIndex = 2, Explanation = "He chose honesty though it was hard, and Allah accepted his repentance." }),
    farewell_hajj = table.freeze({ CorrectIndex = 3, Explanation = "Only piety, which Allah alone can fully judge, makes one person better than another." }),
    passing = table.freeze({ CorrectIndex = 2, Explanation = "Abu Bakr steadied the community by pointing them to Allah, who never dies, and to Qur'an 3:144." }),
}

return table.freeze(keys)
