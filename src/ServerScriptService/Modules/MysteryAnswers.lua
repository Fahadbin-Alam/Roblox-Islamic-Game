--!strict

-- Lock answers for the Sahabi mysteries (Shared/Data/SahabiMysteries.lua): one option index per
-- lock question, in order. Server only, so the lock cannot be read off the client.
-- JourneyGrading.CheckMysteryKeys verifies at startup and in tests/luau that every mystery
-- has one valid key per lock question.

local keys: { [string]: { number } } = {
    bilal = table.freeze({ 2, 1 }),
    salman = table.freeze({ 2, 3 }),
    uthman = table.freeze({ 3, 2 }),
    asma = table.freeze({ 2, 1 }),
    musab = table.freeze({ 1, 3 }),
}

return table.freeze(keys)
