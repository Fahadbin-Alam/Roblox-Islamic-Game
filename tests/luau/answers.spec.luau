-- The answer keys live on the server (ServerScriptService/Modules/LessonAnswers.lua); the
-- lesson file every client receives must not contain them. These tests keep the two files
-- in step and check the server-side grading.
local IslamicStudies = load("Data/IslamicStudies")
local LessonAnswers = load("Server/LessonAnswers")
local LessonGrading = load("Server/LessonGrading")

local index = LessonGrading.BuildIndex(IslamicStudies, LessonAnswers)

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, inner in pairs(value) do
        copy[key] = deepCopy(inner)
    end

    return copy
end

test("answers: the replicated lesson file holds no answers", function()
    for _, unit in ipairs(IslamicStudies.Units) do
        for _, lesson in ipairs(unit.Lessons) do
            for questionIndex, question in ipairs(lesson.Quiz) do
                local where = lesson.Id .. " question " .. questionIndex

                for field in pairs(question) do
                    assert(field == "Prompt" or field == "Options", where .. " has field " .. tostring(field) .. " the client must not see")
                end
            end

            if lesson.Order then
                for field in pairs(lesson.Order) do
                    assert(field == "Prompt" or field == "Steps", lesson.Id .. " puzzle has field " .. tostring(field))
                end

                local sorted = table.clone(lesson.Order.Steps)
                table.sort(sorted, function(a, b)
                    return string.lower(a) < string.lower(b)
                end)

                for position, step in ipairs(lesson.Order.Steps) do
                    expectEqual(step, sorted[position], lesson.Id .. " puzzle steps must be listed alphabetically")
                end
            end
        end
    end
end)

test("answers: every lesson has a key that lines up with it", function()
    local lessons, keys = 0, 0

    for _, unit in ipairs(IslamicStudies.Units) do
        for _, lesson in ipairs(unit.Lessons) do
            lessons += 1
            assert(index[lesson.Id], "no entry for " .. lesson.Id)
        end
    end

    for _ in pairs(LessonAnswers) do
        keys += 1
    end

    expectEqual(keys, lessons, "one key per lesson")
end)

test("answers: BuildIndex refuses keys that drift from the lessons", function()
    local function rejects(mutate, message)
        local studies, answers = deepCopy(IslamicStudies), deepCopy(LessonAnswers)
        mutate(studies, answers)
        local ok = pcall(LessonGrading.BuildIndex, studies, answers)
        assert(not ok, message)
    end

    local first = IslamicStudies.Units[1].Lessons[1]

    rejects(function(_, answers)
        answers[first.Id] = nil
    end, "missing key")
    rejects(function(_, answers)
        table.remove(answers[first.Id].Quiz)
    end, "one key short")
    rejects(function(_, answers)
        answers[first.Id].Quiz[1].CorrectIndex = #first.Quiz[1].Options + 1
    end, "CorrectIndex past the options")
    rejects(function(_, answers)
        answers.not_a_lesson = { Quiz = {} }
    end, "key without a lesson")

    local puzzleId

    for id, entry in pairs(index) do
        if entry.OrderSequence then
            puzzleId = id
        end
    end

    rejects(function(_, answers)
        answers[puzzleId].Order.Steps[1] = "A step that is not in the lesson"
    end, "puzzle step typo")
end)

test("answers: Choice accepts only whole numbers within the options", function()
    expectEqual(LessonGrading.Choice(2, 4), 2, "valid")
    expectEqual(LessonGrading.Choice(4, 4), 4, "last option")
    expectEqual(LessonGrading.Choice(0, 4), nil, "zero")
    expectEqual(LessonGrading.Choice(5, 4), nil, "past the end")
    expectEqual(LessonGrading.Choice(1.5, 4), nil, "fraction")
    expectEqual(LessonGrading.Choice(0 / 0, 4), nil, "NaN")
    expectEqual(LessonGrading.Choice(math.huge, 4), nil, "infinity")
    expectEqual(LessonGrading.Choice("2", 4), nil, "string")
    expectEqual(LessonGrading.Choice({}, 4), nil, "table")
end)

test("answers: quizzes are graded against the server key", function()
    local entry = index.pillars_intro
    local right, wrong = {}, {}

    for questionIndex, key in ipairs(entry.Key.Quiz) do
        right[questionIndex] = key.CorrectIndex
        wrong[questionIndex] = if key.CorrectIndex == 1 then 2 else 1
    end

    local passed = LessonGrading.Quiz(entry, right, IslamicStudies.PassRatio)
    expectEqual(passed.Passed, true, "all right passes")
    expectEqual(passed.Correct, #entry.Lesson.Quiz, "all counted")
    expectEqual(passed.Results[1].CorrectIndex, entry.Key.Quiz[1].CorrectIndex, "result reveals the answer after grading")
    assert(passed.Results[1].Explanation ~= "", "result carries the explanation")

    local failed = LessonGrading.Quiz(entry, wrong, IslamicStudies.PassRatio)
    expectEqual(failed.Passed, false, "all wrong fails")
    expectEqual(failed.Correct, 0, "none counted")

    local junk = LessonGrading.Quiz(entry, { "2", 2.5, 0 / 0, {} }, IslamicStudies.PassRatio)
    expectEqual(junk.Correct, 0, "junk answers count as wrong")
    expectEqual(LessonGrading.Quiz(entry, "junk", IslamicStudies.PassRatio).Correct, 0, "non-table answers")
end)

test("answers: order puzzles are graded against the server key", function()
    local entry = index.wudu
    assert(entry and entry.OrderSequence, "wudu has a puzzle")
    local steps = entry.Lesson.Order.Steps

    for position, stepIndex in ipairs(entry.OrderSequence) do
        expectEqual(steps[stepIndex], entry.Key.Order.Steps[position], "sequence maps to the key's order")
    end

    local inPlace, correctCount, solved = LessonGrading.Order(entry, entry.OrderSequence)
    expectEqual(solved, true, "the key order solves it")
    expectEqual(correctCount, #steps, "every step in place")
    expectEqual(inPlace[1], true, "first in place")

    local listed = {}

    for position = 1, #steps do
        listed[position] = position
    end

    local _, listedCount, listedSolved = LessonGrading.Order(entry, listed)
    expectEqual(listedSolved, false, "the alphabetical order shown to the client is not the answer")
    assert(listedCount < #steps, "some steps out of place")

    local _, junkCount, junkSolved = LessonGrading.Order(entry, { "1", 1.5 })
    expectEqual(junkSolved, false, "junk does not solve")
    expectEqual(junkCount, 0, "junk scores nothing")
end)

test("answers: single questions (daily, study circle) use the same key", function()
    local entry = index.pillars_intro
    local key = entry.Key.Quiz[1]
    local correct, revealed = LessonGrading.Question(entry, 1, key.CorrectIndex)
    expectEqual(correct, true, "right answer")
    expectEqual(revealed.CorrectIndex, key.CorrectIndex, "reveals the key")
    expectEqual((LessonGrading.Question(entry, 1, 99)), false, "out of range is wrong")
    expectEqual((LessonGrading.Question(entry, 1, nil)), false, "no answer is wrong")
end)

test("answers: trivia shuffles options and tracks where the answer went", function()
    local options = { "Ramadan", "Shawwal", "Rajab", "Muharram" }
    local seenPositions = {}
    local seed = 0

    -- A small deterministic generator, so the test is repeatable.
    local function randomInteger(low, high)
        seed = (seed * 1103515245 + 12345) % 2147483648
        return low + math.floor(seed / 65536) % (high - low + 1)
    end

    for _ = 1, 40 do
        local shuffled, correctIndex = LessonGrading.ShuffleOptions(options, 1, randomInteger)
        expectEqual(#shuffled, #options, "same number of options")
        expectEqual(shuffled[correctIndex], "Ramadan", "correct index follows the answer")
        seenPositions[correctIndex] = true

        local seen = {}

        for _, option in ipairs(shuffled) do
            assert(not seen[option], "option repeated")
            seen[option] = true
        end
    end

    local positions = 0

    for _ in pairs(seenPositions) do
        positions += 1
    end

    assert(positions >= 3, "the answer should land in different positions")
    expectEqual(options[1], "Ramadan", "the source list is not modified")
end)
