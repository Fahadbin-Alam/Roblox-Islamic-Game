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
