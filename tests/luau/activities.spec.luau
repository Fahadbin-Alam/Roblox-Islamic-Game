local ParkourRules = load("Modules/ParkourRules")
local PvpMatch = load("Modules/PvpMatch")
local Progression = load("Modules/Progression")
local TravelRoute = load("Data/TravelRoute")

local course = { Id = "test", Checkpoints = 4, MinSeconds = 10 }

test("parkour checkpoints count only in order and time the run", function()
    local run = ParkourRules.NewRun(course)
    expectEqual(ParkourRules.Touch(course, run, 2, 0), "ignored", "needs the start first")
    expectEqual(ParkourRules.Touch(course, run, 1, 100), "start", "start")
    expectEqual(ParkourRules.Touch(course, run, 3, 101), "ignored", "cannot skip")
    expectEqual(ParkourRules.Touch(course, run, 2, 104), "checkpoint", "cp 2")
    expectEqual(ParkourRules.RespawnIndex(run), 2, "respawn at last checkpoint")
    expectEqual(ParkourRules.Touch(course, run, 3, 108), "checkpoint", "cp 3")
    expectEqual(ParkourRules.Touch(course, run, 4, 125), "finish", "finish")
    expectEqual(run.FinishedSeconds, 25, "time")
    expectEqual(ParkourRules.Touch(course, run, 4, 126), "ignored", "finish counts once")
    assert(ParkourRules.IsBetter(nil, 25) and ParkourRules.IsBetter(30, 25) and not ParkourRules.IsBetter(20, 25), "best time")
    expectEqual(ParkourRules.FormatTime(65.4), "1:05.4", "format")
end)

test("impossibly fast parkour runs are rejected", function()
    local run = ParkourRules.NewRun(course)
    ParkourRules.Touch(course, run, 1, 0)
    ParkourRules.Touch(course, run, 2, 1)
    ParkourRules.Touch(course, run, 3, 2)
    expectEqual(ParkourRules.Touch(course, run, 4, 3), "rejected", "too fast")
    expectEqual(run.FinishedSeconds, nil, "no time saved")
end)

test("two players play a full PvP match and a rematch", function()
    local match = PvpMatch.New()
    assert(PvpMatch.AddPlayer(match, 1), "player 1 joins")
    assert(not PvpMatch.CanStartRound(match), "one player cannot start")
    assert(PvpMatch.AddPlayer(match, 2), "player 2 joins")
    assert(not PvpMatch.AddPlayer(match, 2), "no double join")

    for round = 1, 3 do
        assert(PvpMatch.StartRound(match), "round " .. round .. " starts")
        assert(not PvpMatch.AddPlayer(match, 3), "nobody joins mid-round")
        assert(not PvpMatch.Knockout(match, 3, 1), "outsiders cannot be knocked out")
        assert(PvpMatch.Knockout(match, 2, 1), "player 1 knocks out player 2")
        expectEqual(match.RoundWinner, 1, "round winner")
    end

    expectEqual(match.Phase, "Over", "match over at 3 wins")
    expectEqual(match.MatchWinner, 1, "match winner")
    expectEqual(match.Knockouts[1], 3, "knockouts credited")

    assert(not PvpMatch.VoteRematch(match, 1), "waits for everyone")
    assert(PvpMatch.VoteRematch(match, 2), "rematch starts when all vote")
    expectEqual(match.Wins[1], 0, "scores reset")
    assert(PvpMatch.StartRound(match), "rematch round starts")
end)

test("PvP timeouts, draws, and leavers end rounds fairly", function()
    local match = PvpMatch.New()
    PvpMatch.AddPlayer(match, 1)
    PvpMatch.AddPlayer(match, 2)
    PvpMatch.AddPlayer(match, 3)
    PvpMatch.StartRound(match)
    PvpMatch.Timeout(match, { [1] = 50, [2] = 80, [3] = 20 })
    expectEqual(match.RoundWinner, 2, "most health wins on time")

    PvpMatch.StartRound(match)
    PvpMatch.Timeout(match, { [1] = 60, [2] = 60, [3] = 10 })
    expectEqual(match.RoundWinner, nil, "tie is a draw")
    expectEqual(match.Phase, "Intermission", "draw goes to intermission")

    PvpMatch.StartRound(match)
    PvpMatch.Knockout(match, 3, 1)
    PvpMatch.RemovePlayer(match, 2)
    expectEqual(match.RoundWinner, 1, "last standing after a leaver wins")
    PvpMatch.RemovePlayer(match, 3)
    expectEqual(match.Phase, "Waiting", "one player left waits")
    assert(not PvpMatch.StartRound(match), "cannot start alone")
end)

test("new activities are saved categories with rewards, badges, and reachable path steps", function()
    for _, category in ipairs({ "seerah", "mystery", "parkour", "coop" }) do
        assert(Progression.GetCompletionReward(category, true) > 0, category .. " pays XP")
    end

    local profile = Progression.NewProfile()
    assert(profile.Completed.seerah and profile.Completed.mystery, "new profiles have the categories")

    local saved = Progression.Sanitize({ XP = 10, Completed = { seerah = { year_of_elephant = true } }, Stats = { ParkourBest_lobby_tower = 42.5 } })
    assert(saved.Completed.seerah.year_of_elephant, "campaign progress survives a save round trip")
    expectEqual(saved.Stats.ParkourBest_lobby_tower, 42.5, "best time survives")

    for _, step in ipairs(Progression.Path) do
        if step.Destination then
            assert(TravelRoute.GetDestinationById(step.Destination), step.Id .. " points at unknown destination " .. step.Destination)
        end
    end

    local ids = {}
    for _, badge in ipairs(Progression.Badges) do
        assert(not ids[badge.Id], "duplicate badge " .. badge.Id)
        ids[badge.Id] = true
    end
    assert(ids.seerah_complete and ids.mystery_all and ids.coop_trials and ids.pvp_match, "new badges exist")
end)

test("every jump on the parkour tower is possible with default Roblox movement", function()
    local ParkourCourses = load("Data/ParkourCourses")
    local course = ParkourCourses.LobbyTower
    local gravity = 196.2
    local launch = math.sqrt(2 * gravity * ParkourCourses.Movement.JumpHeight)
    local speed = ParkourCourses.Movement.WalkSpeed

    -- Longest horizontal distance covered while still above `rise` studs.
    local function reach(rise)
        local disc = launch * launch - 2 * gravity * rise
        assert(disc > 0, "rise " .. rise .. " is above jump height")
        return speed * (launch + math.sqrt(disc)) / gravity
    end

    -- Edge-to-edge distance between two platforms on the spiral, measured along the spiral
    -- (platforms are 10 long along it).
    local function flat(a, b)
        return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
    end

    local steps = {}
    table.insert(steps, { From = course.StartOffset, To = course.Platforms[1].Offset, HalfFrom = course.StartSize.X / 2, HalfTo = 5, Label = "start -> 1" })

    for index = 2, #course.Platforms do
        table.insert(steps, { From = course.Platforms[index - 1].Offset, To = course.Platforms[index].Offset, HalfFrom = 5, HalfTo = 5, Label = (index - 1) .. " -> " .. index })
    end

    local last = course.Platforms[#course.Platforms]

    for _, step in ipairs(steps) do
        local rise = step.To.Y - step.From.Y
        local gap = flat(step.From, step.To) - step.HalfFrom - step.HalfTo
        assert(rise <= 5, step.Label .. " rises " .. rise)
        assert(gap <= reach(math.max(rise, 0)) - 1, string.format("%s gap %.1f is too far for a %.1f rise", step.Label, gap, rise))
    end

    -- Last step onto the round summit: inner edge of the platform to the summit's rim.
    local rise = course.SummitHeight - last.Offset.Y
    local gap = course.Radius - last.Size.X / 2 - course.SummitRadius
    assert(gap >= 0 and gap <= reach(rise) - 1, string.format("summit gap %.1f for rise %.1f", gap, rise))

    -- No platform sits under the summit deck, where a player would hit their head.
    for index, platform in ipairs(course.Platforms) do
        local inner = course.Radius - platform.Size.X / 2
        assert(inner > course.SummitRadius or platform.Offset.Y < course.SummitHeight - course.SummitThickness - 12, "platform " .. index .. " is under the summit")
    end

    expectEqual(course.Checkpoints[#course.Checkpoints].Name, "Summit", "finish is the summit")
end)

test("retention counts new players, returns, and D1/D7/D30 correctly", function()
    local Retention = load("Modules/Retention")
    local new = Retention.Fields(nil, nil, 100)
    expectEqual(new.Joins, 1, "a join is counted")
    expectEqual(new.NewPlayers, 1, "first visit is a new player")
    expectEqual(new.ReturningPlayers, nil, "a new player is not returning")

    local sameDay = Retention.Fields(100, 100, 100)
    expectEqual(sameDay.ReturningPlayers, nil, "a second join the same day is not a return")

    expectEqual(Retention.Fields(100, 100, 101).D1Returns, 1, "next day is D1")
    expectEqual(Retention.Fields(100, 103, 107).D7Returns, 1, "seventh day is D7")
    expectEqual(Retention.Fields(100, 120, 130).D30Returns, 1, "thirtieth day is D30")

    local later = Retention.Fields(100, 101, 105)
    expectEqual(later.ReturningPlayers, 1, "any later day is a return")
    expectEqual(later.D1Returns, nil, "day 5 is not D1")
    expectEqual(later.D7Returns, nil, "day 5 is not D7")
end)
