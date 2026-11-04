local Daily = load("Modules/Daily")
local DailyReflections = load("Data/DailyReflections")

test("streak grows on consecutive days and resets after a gap", function()
    local stats = {}
    local streak, first = Daily.RecordVisit(stats, 100)
    expectEqual(streak, 1, "first visit")
    expectEqual(first, true, "first visit of the day")

    streak, first = Daily.RecordVisit(stats, 100)
    expectEqual(first, false, "same day again")
    expectEqual(streak, 1, "streak unchanged")

    streak = Daily.RecordVisit(stats, 101)
    expectEqual(streak, 2, "next day")

    streak = Daily.RecordVisit(stats, 104)
    expectEqual(streak, 1, "gap resets")
    expectEqual(stats.DailyBestStreak, 2, "best streak kept")
end)

test("visit reward grows with the streak and is capped", function()
    expectEqual(Daily.VisitReward(1), Daily.Rewards.VisitBase, "day one")
    assert(Daily.VisitReward(3) > Daily.VisitReward(2), "grows")
    expectEqual(Daily.VisitReward(30), Daily.VisitReward(Daily.Rewards.VisitStreakCap), "capped")
end)

test("daily question rotation reaches every question", function()
    local seen, distinct = {}, 0

    for day = 1, Daily.QuestionCount() do
        local entry = Daily.GetQuestion(day)
        local key = entry.LessonId .. "#" .. entry.QuestionIndex

        if not seen[key] then
            seen[key] = true
            distinct += 1
        end
    end

    expectEqual(distinct, Daily.QuestionCount(), "no repeats within one cycle")
end)

test("daily payload hides the answer and reflections are cited", function()
    local payload = Daily.BuildPayload({}, 5)
    expectEqual(payload.Question.CorrectIndex, nil, "no answer sent")
    expectEqual(payload.QuestionAnswered, false, "not answered")

    for index, reflection in ipairs(DailyReflections) do
        assert(reflection.Source ~= "" and reflection.Text ~= "" and reflection.Thought ~= "", "reflection " .. index)
    end
end)
