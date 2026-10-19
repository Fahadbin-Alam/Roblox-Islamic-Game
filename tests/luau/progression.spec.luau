local Progression = load("Modules/Progression")
local IslamicStudies = load("Data/IslamicStudies")

test("level curve starts at level 1 and rolls over exactly", function()
    expectEqual(Progression.GetLevelInfo(0).Level, 1, "0 XP")
    expectEqual(Progression.GetLevelInfo(99).Level, 1, "99 XP")

    local atTwo = Progression.GetLevelInfo(100)
    expectEqual(atTwo.Level, 2, "100 XP")
    expectEqual(atTwo.XPIntoLevel, 0, "XP into level 2")
    expectEqual(atTwo.XPForNext, Progression.XPForNextLevel(2), "XP for level 3")
end)

test("rank titles follow level", function()
    expectEqual(Progression.GetRankTitle(1), "Seeker", "level 1")
    expectEqual(Progression.GetRankTitle(3), "Student", "level 3")
    expectEqual(Progression.GetRankTitle(99), "Guardian Of Knowledge", "level 99")
end)

test("repeat completions earn a reduced reward", function()
    local first = Progression.GetCompletionReward("lesson", true)
    local repeatReward = Progression.GetCompletionReward("lesson", false)
    assert(first > 0, "first completion pays")
    assert(repeatReward < first, "repeat pays less")
    expectEqual(Progression.GetCompletionReward("unknown", true), 0, "unknown category")
end)

test("sanitize keeps valid data and drops junk", function()
    local profile = Progression.Sanitize({
        XP = 250.7,
        Completed = { lesson = { wudu = true, bad = "yes" }, [5] = {} },
        Badges = { first_lesson = 123, broken = "x" },
        Stats = { TriviaCorrect = 3, Junk = "no" },
    })

    expectEqual(profile.XP, 250, "XP floors")
    expectEqual(profile.Completed.lesson.wudu, true, "keeps lesson")
    expectEqual(profile.Completed.lesson.bad, nil, "drops non-true")
    expectEqual(profile.Badges.first_lesson, 123, "keeps badge")
    expectEqual(profile.Badges.broken, nil, "drops bad badge")
    expectEqual(profile.Stats.TriviaCorrect, 3, "keeps stat")
    expectEqual(profile.Stats.Junk, nil, "drops bad stat")
    expectEqual(Progression.Sanitize("garbage").XP, 0, "non-table input")
    assert(Progression.Sanitize(nil).Completed.story, "default categories exist")
end)

test("badge ids are unique", function()
    local seen = {}

    for _, badge in ipairs(Progression.Badges) do
        assert(not seen[badge.Id], "duplicate badge " .. badge.Id)
        seen[badge.Id] = true
    end
end)

test("finishing a unit earns its badge exactly once", function()
    local profile = Progression.NewProfile()
    local unit = IslamicStudies.Units[1]

    for _, lesson in ipairs(unit.Lessons) do
        profile.Completed.lesson[lesson.Id] = true
    end

    local earned = {}

    for _, badge in ipairs(Progression.FindNewBadges(profile)) do
        earned[badge.Id] = true
        profile.Badges[badge.Id] = 1
    end

    assert(earned["unit_" .. unit.Id], "unit badge awarded")
    assert(earned.first_lesson, "first lesson badge awarded")
    expectEqual(#Progression.FindNewBadges(profile), 0, "nothing new on second check")
end)

test("snapshot is plain data", function()
    local snapshot = Progression.BuildSnapshot(Progression.NewProfile())

    for _, badge in ipairs(snapshot.Badges) do
        expectEqual(badge.IsEarned, nil, "no functions sent to client")
    end

    expectEqual(snapshot.Level, 1, "level")
end)
