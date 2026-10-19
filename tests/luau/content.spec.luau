local IslamicStudies = load("Data/IslamicStudies")
local TriviaQuestions = load("Data/TriviaQuestions")

test("every Islamic Studies lesson is well formed", function()
    local seen = {}

    assert(#IslamicStudies.Units > 0, "no units")

    for _, unit in ipairs(IslamicStudies.Units) do
        assert(#unit.AccentRGB == 3, unit.Id .. " needs an RGB accent")
        assert(#unit.Lessons > 0, unit.Id .. " has no lessons")

        for _, lesson in ipairs(unit.Lessons) do
            assert(not seen[lesson.Id], "duplicate lesson id " .. lesson.Id)
            seen[lesson.Id] = true
            assert(#lesson.Pages > 0, lesson.Id .. " has no pages")
            assert(#lesson.Quiz >= 2, lesson.Id .. " needs at least two quiz questions")

            for index, question in ipairs(lesson.Quiz) do
                local where = string.format("%s question %d", lesson.Id, index)
                assert(#question.Options >= 2, where .. " needs options")
                assert(question.CorrectIndex >= 1 and question.CorrectIndex <= #question.Options, where .. " CorrectIndex out of range")
                assert(question.Explanation ~= "", where .. " needs an explanation")

                local optionSeen = {}

                for _, option in ipairs(question.Options) do
                    assert(not optionSeen[option], where .. " repeats option " .. option)
                    optionSeen[option] = true
                end
            end
        end
    end
end)

test("pass ratio leaves room for one mistake on longer quizzes", function()
    assert(IslamicStudies.PassRatio > 0 and IslamicStudies.PassRatio < 1, "PassRatio must be between 0 and 1")
    expectEqual(math.ceil(3 * IslamicStudies.PassRatio), 2, "3-question quizzes need 2 correct")
end)

test("trivia answers point at a real option", function()
    for index, question in ipairs(TriviaQuestions.Questions) do
        assert(question.CorrectIndex >= 1 and question.CorrectIndex <= #question.Options, "trivia question " .. index)
    end
end)
