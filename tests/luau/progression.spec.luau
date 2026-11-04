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

test("Uhud unlocks after Badr or at level 3", function()
    local profile = Progression.NewProfile()
    assert(Progression.GetBattleLockReason(profile, "uhud"), "new players are locked out of Uhud")
    expectEqual(Progression.GetBattleLockReason(profile, "badr"), nil, "Badr is always open")
    expectEqual(Progression.GetBattleLockReason(nil, "uhud"), nil, "unloaded profiles are never blocked")

    profile.Completed.battle.badr = true
    expectEqual(Progression.GetBattleLockReason(profile, "uhud"), nil, "open after Badr")

    local leveled = Progression.NewProfile()
    leveled.XP = Progression.XPForNextLevel(1) + Progression.XPForNextLevel(2)
    expectEqual(Progression.GetBattleLockReason(leveled, "uhud"), nil, "open at level 3")
end)

test("path suggests the first unfinished step", function()
    local profile = Progression.NewProfile()
    expectEqual(Progression.GetNextStep(profile).Id, "haram_walk", "new players start with the walk")

    profile.Completed.trail.haram_learning_walk = true
    expectEqual(Progression.GetNextStep(profile).Id, "pillars", "then the pillars")

    local snapshot = Progression.BuildSnapshot(profile)
    expectEqual(snapshot.Path[1].Done, true, "walk shows done")
    expectEqual(snapshot.NextStep.Title, Progression.Path[2].Title, "snapshot next step")
    expectEqual(snapshot.Path[1].IsDone, nil, "no functions in path")
end)

test("path steps are rewarded once and point somewhere real", function()
    local TravelRoute = load("Data/TravelRoute")
    local unitIds = {}

    for _, unit in ipairs(IslamicStudies.Units) do
        unitIds[unit.Id] = true
    end

    for _, step in ipairs(Progression.Path) do
        if step.Destination then
            assert(TravelRoute.GetDestinationById(step.Destination), "unknown destination for " .. step.Id)
        end

        if step.HallUnitId then
            assert(unitIds[step.HallUnitId], "unknown unit for " .. step.Id)
        end
    end

    local profile = Progression.NewProfile()
    expectEqual(#Progression.FindNewlyCompletedSteps(profile), 0, "nothing done yet")

    profile.Completed.trail = { kaaba = true }
    local done = Progression.FindNewlyCompletedSteps(profile)
    expectEqual(#done, 1, "trail step done")
    expectEqual(done[1].Id, "haram_walk", "first step")

    profile.Completed.path = { haram_walk = true }
    expectEqual(#Progression.FindNewlyCompletedSteps(profile), 0, "already rewarded")
    expectEqual((Progression.GetNextStep(profile) :: any).Id, "pillars", "next step")
end)

test("guides stand at real destinations", function()
    local Guides = load("Data/Guides")
    local TravelRoute = load("Data/TravelRoute")
    local seen = {}

    for _, guide in ipairs(Guides) do
        assert(not seen[guide.Id], "duplicate guide " .. guide.Id)
        seen[guide.Id] = true
        assert(TravelRoute.GetDestinationById(guide.Destination), "unknown destination for " .. guide.Id)
        assert(#guide.Sayings > 0, "guide has sayings")
    end
end)
