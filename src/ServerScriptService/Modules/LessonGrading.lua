--!strict

-- Server-side grading for the Islamic Studies quizzes and order puzzles (and the shared
-- choice validation and option shuffling the trivia rounds use). The lessons the
-- client sees (Shared/Data/IslamicStudies.lua) carry no answers; the keys are in
-- LessonAnswers.lua next to this file, which never leaves the server. Pure functions with
-- no Roblox services, so tests/luau/answers.spec.luau can run them.

local LessonGrading = {}

export type QuizResult = {
    LessonId: string,
    Correct: number,
    Total: number,
    Required: number,
    Passed: boolean,
    Results: { { Correct: boolean, CorrectIndex: number, Explanation: string } },
    FirstTime: boolean,
    XPAwarded: number,
}

-- A lesson with its answer key, and for an order puzzle the correct sequence as indexes
-- into the lesson's (alphabetical) Steps list.
export type Entry = {
    Lesson: any,
    Key: any,
    OrderSequence: { number }?,
}

-- The option a client picked, or nil unless it is a whole number from 1 to optionCount.
-- Remote arguments are untrusted: NaN, 2.5, -1, strings and tables all come back nil.
function LessonGrading.Choice(value: any, optionCount: number): number?
    if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
        return nil
    end

    if value < 1 or value > optionCount then
        return nil
    end

    return value
end

-- Indexes into `shownSteps` in the order `correctSteps` lists them. Errors if the two lists
-- do not hold exactly the same steps, so a typo in either file stops the server at startup.
function LessonGrading.OrderSequence(shownSteps: { string }, correctSteps: { string }, where: string): { number }
    assert(#shownSteps == #correctSteps, string.format("%s: lesson lists %d steps, key lists %d", where, #shownSteps, #correctSteps))

    local indexByStep = {}

    for index, step in ipairs(shownSteps) do
        assert(indexByStep[step] == nil, string.format("%s: duplicate step %q", where, step))
        indexByStep[step] = index
    end

    local sequence = {}

    for position, step in ipairs(correctSteps) do
        local index = indexByStep[step]
        assert(index ~= nil, string.format("%s: key step %q is not in the lesson", where, step))
        indexByStep[step] = nil
        sequence[position] = index
    end

    return sequence
end

-- Pairs every lesson with its key, checking that they line up: one key per question, each
-- CorrectIndex pointing at a real option, and puzzle steps that match. Errors on any drift.
function LessonGrading.BuildIndex(studies: any, answers: { [string]: any }): { [string]: Entry }
    local index: { [string]: Entry } = {}

    for _, unit in ipairs(studies.Units) do
        for _, lesson in ipairs(unit.Lessons) do
            local id = lesson.Id
            local key = answers[id]
            assert(index[id] == nil, string.format("Duplicate Islamic Studies lesson id %s", id))
            assert(key ~= nil, string.format("No answer key for lesson %s", id))
            assert(#key.Quiz == #lesson.Quiz, string.format("%s: %d questions but %d keys", id, #lesson.Quiz, #key.Quiz))

            for questionIndex, question in ipairs(lesson.Quiz) do
                local questionKey = key.Quiz[questionIndex]
                local where = string.format("%s question %d", id, questionIndex)
                assert(LessonGrading.Choice(questionKey.CorrectIndex, #question.Options) ~= nil, where .. ": CorrectIndex out of range")
                assert(type(questionKey.Explanation) == "string" and questionKey.Explanation ~= "", where .. ": missing explanation")
            end

            local sequence = nil

            if lesson.Order or key.Order then
                assert(lesson.Order and key.Order, string.format("%s: puzzle and key must both exist", id))
                sequence = LessonGrading.OrderSequence(lesson.Order.Steps, key.Order.Steps, id)
            end

            index[id] = { Lesson = lesson, Key = key, OrderSequence = sequence }
        end
    end

    for id in pairs(answers) do
        assert(index[id] ~= nil, string.format("Answer key %s has no lesson", id))
    end

    return index
end

-- Grades a whole quiz. `answers[i]` is the option chosen for question i; anything invalid
-- counts as wrong. The result reveals each right answer, which the hall shows afterwards.
function LessonGrading.Quiz(entry: Entry, answers: any, passRatio: number): QuizResult
    local lesson = entry.Lesson
    local results = {}
    local correctCount = 0
    local given = if type(answers) == "table" then answers else {}

    for index, question in ipairs(lesson.Quiz) do
        local key = entry.Key.Quiz[index]
        local chosen = LessonGrading.Choice(given[index], #question.Options)
        local correct = chosen ~= nil and chosen == key.CorrectIndex

        if correct then
            correctCount += 1
        end

        table.insert(results, {
            Correct = correct,
            CorrectIndex = key.CorrectIndex,
            Explanation = key.Explanation,
        })
    end

    local required = math.ceil(#lesson.Quiz * passRatio)

    return {
        LessonId = lesson.Id,
        Correct = correctCount,
        Total = #lesson.Quiz,
        Required = required,
        Passed = correctCount >= required,
        Results = results,
        FirstTime = false,
        XPAwarded = 0,
    }
end

-- Grades an order puzzle. `placed[i]` is the index (into the lesson's Steps) of the step the
-- player put in position i. Returns which positions are right and whether all of them are.
function LessonGrading.Order(entry: Entry, placed: any): ({ boolean }, number, boolean)
    local sequence = entry.OrderSequence or {}
    local given = if type(placed) == "table" then placed else {}
    local inPlace = {}
    local correctCount = 0

    for position, stepIndex in ipairs(sequence) do
        local right = LessonGrading.Choice(given[position], #sequence) == stepIndex
        inPlace[position] = right

        if right then
            correctCount += 1
        end
    end

    return inPlace, correctCount, #sequence > 0 and correctCount == #sequence
end

-- Returns the options in a random order and where the correct one moved to. Trivia uses it
-- each round so the answer's position is never something a player can memorise.
-- `randomInteger(low, high)` is injected so tests can make it deterministic.
function LessonGrading.ShuffleOptions(options: { string }, correctIndex: number, randomInteger: (number, number) -> number): ({ string }, number)
    local order = {}

    for index = 1, #options do
        order[index] = index
    end

    for index = #order, 2, -1 do
        local swap = randomInteger(1, index)
        order[index], order[swap] = order[swap], order[index]
    end

    local shuffled = {}
    local newCorrect = 1

    for position, original in ipairs(order) do
        shuffled[position] = options[original]

        if original == correctIndex then
            newCorrect = position
        end
    end

    return shuffled, newCorrect
end

-- Checks one question on its own (the daily question and the study circle).
function LessonGrading.Question(entry: Entry, questionIndex: number, chosen: any): (boolean, { CorrectIndex: number, Explanation: string })
    local question = entry.Lesson.Quiz[questionIndex]
    local key = entry.Key.Quiz[questionIndex]
    local choice = LessonGrading.Choice(chosen, #question.Options)

    return choice ~= nil and choice == key.CorrectIndex, key
end

return LessonGrading
