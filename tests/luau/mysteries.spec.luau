local SahabiMysteries = load("Data/SahabiMysteries")
local MysteryRules = load("Modules/MysteryRules")

test("every mystery has clues, hints, a lock, an episode, and sources", function()
    assert(#SahabiMysteries.Mysteries >= 5, "at least five mysteries")
    local seen = {}

    for _, mystery in ipairs(SahabiMysteries.Mysteries) do
        local where = mystery.Id
        assert(not seen[where], "duplicate " .. where)
        seen[where] = true
        assert(#mystery.Clues >= 4, where .. " needs clues")
        assert(#mystery.Hints >= 3, where .. " needs three hints")
        assert(#mystery.Lock >= 2, where .. " needs two lock questions")
        assert(#mystery.Episode.Stations >= 3, where .. " episode needs stations")
        assert(#mystery.Conclusion >= 2, where .. " needs a conclusion")
        assert(#mystery.Sources >= 2, where .. " needs sources")
        assert(string.find(mystery.FictionNote, "Invented", 1, true), where .. " must say what was invented")

        local half = SahabiMysteries.RoomSize / 2
        local clueIds = {}

        for _, clue in ipairs(mystery.Clues) do
            assert(not clueIds[clue.Id], where .. " repeats clue " .. clue.Id)
            clueIds[clue.Id] = true
            assert(math.abs(clue.Offset.X) < half - 6 and math.abs(clue.Offset.Z) < half - 6, where .. " clue " .. clue.Id .. " is outside the room")
        end

        for _, station in ipairs(mystery.Episode.Stations) do
            assert(math.abs(station.Offset.X) < half - 6 and math.abs(station.Offset.Z) < half - 6, where .. " station outside the yard")
        end

        for index, question in ipairs(mystery.Lock) do
            assert(question.CorrectIndex >= 1 and question.CorrectIndex <= #question.Options, where .. " lock " .. index .. " answer out of range")
        end

        -- The first lock question always asks who the companion is.
        expectEqual(mystery.Lock[1].Options[mystery.Lock[1].CorrectIndex], mystery.Companion, where .. " first lock answer")
    end
end)

test("a shared run goes clue, hint, lock, episode, done", function()
    local mystery = MysteryRules.Get("bilal")
    local run = MysteryRules.NewRun("bilal")

    assert(MysteryRules.FindClue(run, "chain"), "finds a clue")
    assert(MysteryRules.FindClue(run, "chain") == nil, "same clue only once")
    assert(MysteryRules.FindClue(run, "nope") == nil, "unknown clue")
    expectEqual(MysteryRules.FoundCount(run), 1, "one clue")

    expectEqual(MysteryRules.TakeHint(run), mystery.Hints[1], "first hint")
    expectEqual(MysteryRules.TakeHint(run), mystery.Hints[2], "second hint")
    MysteryRules.TakeHint(run)
    expectEqual(MysteryRules.TakeHint(run), nil, "no fourth hint")

    local counted = MysteryRules.VisitStation(run, 1)
    assert(not counted, "stations stay closed until the lock opens")

    assert(not MysteryRules.TryLock(run, { 1, 1 }), "wrong lock")
    assert(not MysteryRules.TryLock(run, "bad"), "bad input")
    assert(MysteryRules.TryLock(run, { 2, 1 }), "right lock")

    assert(not (MysteryRules.VisitStation(run, 2)), "ordered episode refuses station 2 first")
    for index = 1, #mystery.Episode.Stations do
        local ok, finished = MysteryRules.VisitStation(run, index)
        assert(ok, "station " .. index)
        expectEqual(finished, index == #mystery.Episode.Stations, "finished flag at " .. index)
    end

    assert(run.Done, "done")
    -- 3 hints taken and 1 wrong try: one star off.
    expectEqual(MysteryRules.Stars(run), 2, "stars")
end)

test("unordered episodes accept stations in any order", function()
    local run = MysteryRules.NewRun("salman")
    MysteryRules.TryLock(run, { 2, 3 })
    assert(run.LockOpen, "lock open")
    assert(MysteryRules.VisitStation(run, 4), "last first")
    assert(MysteryRules.VisitStation(run, 2), "then second")
    expectEqual(MysteryRules.Stars(run), 3, "clean run keeps three stars")
end)
