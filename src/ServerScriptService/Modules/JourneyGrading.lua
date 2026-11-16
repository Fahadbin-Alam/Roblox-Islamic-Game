--!strict

-- Server-side checks for the Journeys answer keys (SeerahAnswers.lua and MysteryAnswers.lua,
-- next to this file, which never leave the server). Pure functions with no Roblox services,
-- so tests/luau can run them.
--
-- `Choice` has the same rules as LessonGrading.Choice in PR #6; once both are on one branch
-- this can simply call that instead.

local JourneyGrading = {}

-- The option a client picked, or nil unless it is a whole number from 1 to optionCount.
-- Remote arguments are untrusted: NaN, 2.5, -1, strings and tables all come back nil.
function JourneyGrading.Choice(value: any, optionCount: number): number?
    if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
        return nil
    end

    if value < 1 or value > optionCount then
        return nil
    end

    return value
end

-- Errors unless every chapter has exactly one key, pointing at a real option, with an
-- explanation, and no key is left over. Run at server start so drift stops the server early.
function JourneyGrading.CheckSeerahKeys(chapters: { any }, keys: { [string]: any })
    local seen = {}

    for _, chapter in ipairs(chapters) do
        local key = keys[chapter.Id]
        assert(key ~= nil, string.format("No Seerah answer key for chapter %s", chapter.Id))
        assert(
            JourneyGrading.Choice(key.CorrectIndex, #chapter.Decision.Options) ~= nil,
            string.format("Seerah %s: CorrectIndex %s is not one of its %d options", chapter.Id, tostring(key.CorrectIndex), #chapter.Decision.Options)
        )
        assert(type(key.Explanation) == "string" and key.Explanation ~= "", string.format("Seerah %s: no explanation", chapter.Id))
        seen[chapter.Id] = true
    end

    for id in pairs(keys) do
        assert(seen[id], string.format("Seerah answer key %s has no chapter", id))
    end
end

function JourneyGrading.CheckMysteryKeys(mysteries: { any }, keys: { [string]: { number } })
    local seen = {}

    for _, mystery in ipairs(mysteries) do
        local key = keys[mystery.Id]
        assert(key ~= nil, string.format("No lock key for mystery %s", mystery.Id))
        assert(#key == #mystery.Lock, string.format("Mystery %s: %d lock questions but %d answers", mystery.Id, #mystery.Lock, #key))

        for index, question in ipairs(mystery.Lock) do
            assert(
                JourneyGrading.Choice(key[index], #question.Options) ~= nil,
                string.format("Mystery %s lock %d: answer %s is not one of its options", mystery.Id, index, tostring(key[index]))
            )
        end

        seen[mystery.Id] = true
    end

    for id in pairs(keys) do
        assert(seen[id], string.format("Lock key %s has no mystery", id))
    end
end

return JourneyGrading
