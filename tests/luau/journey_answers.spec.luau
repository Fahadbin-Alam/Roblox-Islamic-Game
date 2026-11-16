-- The Seerah and mystery answer keys live on the server (ServerScriptService/Modules), not in
-- the Shared/Data files every client downloads.
local SeerahCampaign = load("Data/SeerahCampaign")
local SahabiMysteries = load("Data/SahabiMysteries")
local JourneyGrading = load("Server/JourneyGrading")
local SeerahAnswers = load("Server/SeerahAnswers")
local MysteryAnswers = load("Server/MysteryAnswers")

test("every Seerah chapter has one valid server-side answer key", function()
    JourneyGrading.CheckSeerahKeys(SeerahCampaign.Chapters, SeerahAnswers)
end)

test("every mystery lock has one valid server-side answer per question", function()
    JourneyGrading.CheckMysteryKeys(SahabiMysteries.Mysteries, MysteryAnswers)
end)

test("no answer or explanation is left in the client-visible Journeys data", function()
    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        for field in pairs(chapter.Decision) do
            assert(field == "Prompt" or field == "Options", chapter.Id .. " decision carries " .. tostring(field))
        end
    end

    for _, mystery in ipairs(SahabiMysteries.Mysteries) do
        for index, question in ipairs(mystery.Lock) do
            for field in pairs(question) do
                assert(field == "Prompt" or field == "Options", mystery.Id .. " lock " .. index .. " carries " .. tostring(field))
            end
        end
    end
end)

test("key drift stops the server", function()
    local ok = pcall(JourneyGrading.CheckSeerahKeys, SeerahCampaign.Chapters, {})
    assert(not ok, "missing keys are caught")
    local extra = table.clone(MysteryAnswers)
    extra.nobody = { 1, 1 }
    ok = pcall(JourneyGrading.CheckMysteryKeys, SahabiMysteries.Mysteries, extra)
    assert(not ok, "a key with no mystery is caught")
    local short = table.clone(MysteryAnswers)
    short.bilal = { 2 }
    ok = pcall(JourneyGrading.CheckMysteryKeys, SahabiMysteries.Mysteries, short)
    assert(not ok, "a short key is caught")
end)

test("only whole option numbers in range are accepted from clients", function()
    expectEqual(JourneyGrading.Choice(2, 4), 2, "a real option")
    expectEqual(JourneyGrading.Choice(0, 4), nil, "zero")
    expectEqual(JourneyGrading.Choice(5, 4), nil, "past the end")
    expectEqual(JourneyGrading.Choice(1.5, 4), nil, "fraction")
    expectEqual(JourneyGrading.Choice(0 / 0, 4), nil, "NaN")
    expectEqual(JourneyGrading.Choice("2", 4), nil, "string")
    expectEqual(JourneyGrading.Choice({}, 4), nil, "table")
end)
