local SeerahCampaign = load("Data/SeerahCampaign")
local HistoricalSites = load("Data/HistoricalSites")
local CampaignRules = load("Modules/CampaignRules")
local BattleScenarios = load("Data/BattleScenarios")
local TravelRoute = load("Data/TravelRoute")

local SALLA = "ﷺ"

-- Every mention of the Prophet ﷺ in a string must carry the salutation, and no field may
-- describe a model, voice, or actor for him.
local function checkReverence(text, where)
    local lower = string.lower(text)

    for start in string.gmatch(text, "()[Tt]he Prophet") do
        local after = string.sub(text, start + #"the Prophet", start + #"the Prophet" + 15)
        local isPlural = string.sub(after, 1, 1) == "s"
        local isPossessive = string.sub(after, 1, 2) == "'s"

        if not isPlural then
            local nextWord = string.match(after, "^'?s?%s*(%S+)") or ""
            local named = string.find(after, SALLA, 1, true) ~= nil and (string.sub(nextWord, 1, #SALLA) == SALLA or nextWord == "Muhammad" or isPossessive)
            assert(named,
                where .. " mentions the Prophet without " .. SALLA .. ": " .. string.sub(text, start, start + 40))
        end
    end

    for start in string.gmatch(text, "()Prophet Muhammad") do
        local after = string.sub(text, start + #"Prophet Muhammad", start + #"Prophet Muhammad" + 4)
        assert(string.find(after, SALLA, 1, true) ~= nil, where .. " names Prophet Muhammad without " .. SALLA)
    end

    assert(not string.find(lower, "voiced by", 1, true), where .. " mentions a voice actor")
end

local function eachString(value, where, fn)
    if type(value) == "string" then
        fn(value, where)
    elseif type(value) == "table" then
        for key, child in pairs(value) do
            eachString(child, where .. "." .. tostring(key), fn)
        end
    end
end

test("the campaign has 30 chapters in chronological order", function()
    expectEqual(#SeerahCampaign.Chapters, 30, "chapter count")

    local seen = {}
    local madinahStarted = false

    for index, chapter in ipairs(SeerahCampaign.Chapters) do
        expectEqual(chapter.Number, index, chapter.Id .. " number")
        assert(not seen[chapter.Id], "duplicate chapter " .. chapter.Id)
        seen[chapter.Id] = true

        if chapter.Era == "Madinah" then
            madinahStarted = true
        else
            assert(chapter.Era == "Makkah", chapter.Id .. " has unknown era")
            assert(not madinahStarted, chapter.Id .. " is a Makkah chapter after the Hijrah")
        end
    end

    expectEqual(SeerahCampaign.Chapters[1].Id, "year_of_elephant", "first chapter")
    expectEqual(SeerahCampaign.Chapters[30].Id, "passing", "last chapter")
end)

test("every chapter is complete, sourced, and separates gameplay from history", function()
    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        local where = chapter.Id
        assert(chapter.Title ~= "" and chapter.When ~= "", where .. " needs a title and date")
        assert(#chapter.People >= 1, where .. " needs people")
        assert(#chapter.Story >= 2, where .. " needs at least two narration cards")
        assert(#chapter.Sources >= 1, where .. " needs sources")
        assert(chapter.Consequence ~= "" and chapter.Lesson ~= "", where .. " needs a consequence and lesson")
        assert(chapter.GameplayNote ~= "", where .. " needs a gameplay note")
        assert(HistoricalSites.GetSite(chapter.Site) ~= nil, where .. " uses unknown site " .. chapter.Site)

        local decision = chapter.Decision
        assert(#decision.Options >= 3, where .. " decision needs options")
        assert(decision.CorrectIndex >= 1 and decision.CorrectIndex <= #decision.Options, where .. " decision answer out of range")
        assert(decision.Explanation ~= "", where .. " decision needs an explanation")

        local activity = chapter.Activity

        if activity then
            if activity.Kind == "Collect" then
                assert((activity.Count or 0) >= 1 and (activity.Item or "") ~= "", where .. " collect activity needs an item and count")
                assert(string.find(chapter.GameplayNote, "Fictional", 1, true) or string.find(chapter.GameplayNote, "game", 1, true), where .. " must say the collecting is a game invention")
            elseif activity.Kind == "Battle" then
                local found = false
                for _, scenario in ipairs(BattleScenarios) do
                    if scenario.Id == activity.ScenarioId then found = true end
                end
                assert(found, where .. " links unknown battle " .. tostring(activity.ScenarioId))
            else
                error(where .. " has unknown activity " .. tostring(activity.Kind))
            end
        end
    end
end)

test("the Prophet is always named with salutation and never given a model or voice", function()
    eachString(SeerahCampaign.Chapters, "SeerahCampaign", checkReverence)
    eachString(HistoricalSites.Sites, "HistoricalSites", checkReverence)
    eachString(load("Data/SahabiMysteries").Mysteries, "SahabiMysteries", checkReverence)
end)

test("historical sites sit inside their zone and far from the present-day hub", function()
    for _, site in ipairs(HistoricalSites.Sites) do
        local zone = HistoricalSites.GetZone(site.Zone)
        assert(zone, site.Id .. " has unknown zone")
        assert(math.abs(site.Position.X - zone.Center.X) <= zone.Size.X / 2 and math.abs(site.Position.Z - zone.Center.Z) <= zone.Size.Z / 2, site.Id .. " is outside its zone")
        -- The hub (today's Makkah and Madinah) stays within about 2400 studs of the origin.
        assert(math.abs(site.Position.X) > 3000, site.Id .. " is too close to the present-day hub")
    end

    for _, id in ipairs({ "seerah_campaign", "seerah_madinah" }) do
        local destination = TravelRoute.GetDestinationById(id)
        assert(destination and string.find(destination.DisplayName, "historical", 1, true), id .. " must be labelled historical")
    end

    assert(string.find(TravelRoute.GetDestinationById("kaaba_courtyard").DisplayName, "today", 1, true), "present-day Haram is labelled")
    assert(string.find(TravelRoute.GetDestinationById("medina_courtyard").DisplayName, "today", 1, true), "present-day Madinah is labelled")
end)

test("chapters unlock one at a time in order", function()
    local done = {}
    assert(CampaignRules.IsUnlocked(done, "year_of_elephant"), "chapter 1 is open")
    assert(not CampaignRules.IsUnlocked(done, "orphan_years"), "chapter 2 starts locked")
    done.year_of_elephant = true
    assert(CampaignRules.IsUnlocked(done, "orphan_years"), "chapter 2 opens after 1")
    expectEqual(CampaignRules.NextChapter(done).Id, "orphan_years", "next chapter")
    expectEqual(CampaignRules.CountDone(done), 1, "count")
    expectEqual(#CampaignRules.Checklist(done), 30, "checklist length")
end)

test("a collect chapter runs travel, story, activity, decision", function()
    local run = CampaignRules.NewRun("black_stone")
    expectEqual(run.Stage, "Travel", "starts travelling")
    assert(not CampaignRules.FinishStory(run), "cannot skip travel")
    assert(CampaignRules.Arrive(run), "arrive")
    assert(CampaignRules.FinishStory(run), "story")
    expectEqual(run.Stage, "Activity", "activity next")
    assert(not CampaignRules.Collect(run, 0), "rejects bad index")
    assert(not CampaignRules.Collect(run, 1.5), "rejects fractional index")
    assert(CampaignRules.Collect(run, 1), "collect 1")
    assert(not CampaignRules.Collect(run, 1), "same item twice")
    CampaignRules.Collect(run, 2)
    CampaignRules.Collect(run, 3)
    expectEqual(run.Stage, "Activity", "still collecting")
    CampaignRules.Collect(run, 4)
    expectEqual(run.Stage, "Decision", "decision after collecting all")
    local ok = CampaignRules.Answer(run, 1)
    assert(not ok, "wrong answer")
    expectEqual(run.WrongAnswers, 1, "wrong counted")
    local right, explanation = CampaignRules.Answer(run, CampaignRules.GetChapter("black_stone").Decision.CorrectIndex)
    assert(right and explanation, "right answer explains")
    expectEqual(run.Stage, "Done", "done")
end)

test("battle chapters wait for the mission", function()
    local run = CampaignRules.NewRun("badr")
    CampaignRules.Arrive(run)
    CampaignRules.FinishStory(run)
    expectEqual(run.Stage, "Activity", "battle activity")
    assert(not CampaignRules.Collect(run, 1), "battle chapters do not collect")
    assert(not CampaignRules.BattleDone(run, false), "needs the battle done")
    assert(CampaignRules.BattleDone(run, true), "battle done")
    expectEqual(run.Stage, "Decision", "then decision")
end)

test("narration-only chapters go straight to the decision", function()
    local run = CampaignRules.NewRun("year_of_sorrow")
    CampaignRules.Arrive(run)
    CampaignRules.FinishStory(run)
    expectEqual(run.Stage, "Decision", "no activity")
end)
