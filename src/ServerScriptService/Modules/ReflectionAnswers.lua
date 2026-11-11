--!strict

-- Answer keys for the after-battle reflection questions in
-- ReplicatedStorage/Shared/Data/BattleMissions.lua, keyed by question Id. Kept in
-- ServerScriptService so clients never receive them; MissionRules.GradeReflection grades
-- against this table and only then sends back the answer and explanation.
-- `Answer` is the index into that question's Choices. tests/luau/missions.spec.luau checks
-- that every question has a key and that each Answer points at a real choice.

export type ReflectionKey = {
    Answer: number,
    Explanation: string,
}

local ReflectionAnswers: { [string]: ReflectionKey } = {
    -- Badr
    badr_stand_firm = {
        Answer = 2,
        Explanation = "Firmness, remembrance, obedience, and unity are the lessons of Badr. Arguing breaks courage.",
    },
    badr_numbers = {
        Answer = 3,
        Explanation = "Sahih al-Bukhari 3959 says they were three hundred and ten-odd, facing a much larger army.",
    },
    badr_captives = {
        Answer = 3,
        Explanation = "Knowledge was valued so highly that teaching it could pay a ransom (Musnad Ahmad 2216).",
    },

    -- Uhud
    uhud_order = {
        Answer = 2,
        Explanation = "Sahih al-Bukhari 3039: do not leave your place even if you see birds snatching us.",
    },
    uhud_turn = {
        Answer = 1,
        Explanation = "When the hill was left open, riders came around behind the Muslim line (Qur'an 3:152).",
    },
    uhud_lesson = {
        Answer = 3,
        Explanation = "Uhud teaches obedience, patience after pain, and getting back up.",
    },
}

return ReflectionAnswers
