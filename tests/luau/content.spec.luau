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

test("order puzzles have distinct steps", function()
    local IslamicStudies = load("Data/IslamicStudies")
    local puzzles = 0

    for _, unit in ipairs(IslamicStudies.Units) do
        for _, lesson in ipairs(unit.Lessons) do
            local puzzle = lesson.Order

            if puzzle then
                puzzles += 1
                assert(#puzzle.Steps >= 3, "puzzle too short in " .. lesson.Id)
                assert(puzzle.Prompt ~= "" and puzzle.Explanation ~= "", "puzzle text missing in " .. lesson.Id)
                local seen = {}

                for _, step in ipairs(puzzle.Steps) do
                    assert(not seen[step], "duplicate step in " .. lesson.Id)
                    assert(not string.find(step, "[<>&]"), "rich text character in " .. lesson.Id)
                    seen[step] = true
                end
            end
        end
    end

    assert(puzzles >= 4, "expected the order puzzles")
end)

test("level outfits are free and reachable", function()
    local ShopCatalog = load("Data/ShopCatalog")
    local levelSkins = 0

    for _, skin in pairs(ShopCatalog.SkinDefinitions) do
        if skin.UnlockType == "Level" then
            levelSkins += 1
            assert(type(skin.UnlockLevel) == "number" and skin.UnlockLevel > 1, "bad unlock level for " .. skin.DisplayName)
            assert(skin.UnlockKey == nil, "level outfit must not need a pass")
        end
    end

    assert(levelSkins >= 3, "expected level outfits")
end)
