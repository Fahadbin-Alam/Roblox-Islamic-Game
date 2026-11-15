local BattleMissions = load("Data/BattleMissions")
local BattleScenarios = load("Data/BattleScenarios")
local MissionRules = load("Modules/MissionRules")
local Progression = load("Modules/Progression")

test("every battle scenario has a story mission", function()
    for _, scenario in ipairs(BattleScenarios) do
        assert(BattleMissions.Get(scenario.Id), "no mission for " .. scenario.Id)
    end
end)

test("missions are well formed", function()
    local types = { Reach = true, Hold = true, Defend = true, Defeat = true, Discipline = true, Narration = true }

    for _, id in ipairs(BattleMissions.Order) do
        local mission = BattleMissions.Get(id)
        local seen = {}

        for _, objective in ipairs(mission.Objectives) do
            assert(types[objective.Type], id .. ": unknown objective type " .. tostring(objective.Type))
            assert(not seen[objective.Id], id .. ": duplicate objective " .. objective.Id)
            seen[objective.Id] = true
            assert(objective.Narration and objective.Narration.Reference and #objective.Narration.Reference > 0, objective.Id .. " narration must cite a source")

            if objective.Type == "Hold" or objective.Type == "Discipline" or objective.Type == "Narration" then
                assert(type(objective.Seconds) == "number" and objective.Seconds > 0, objective.Id .. " needs Seconds")
            end

            if objective.Type == "Reach" or objective.Type == "Hold" or objective.Type == "Discipline" then
                assert(mission.Layout.Points[objective.Zone], objective.Id .. " zone missing")
                assert(type(objective.Radius) == "number", objective.Id .. " needs Radius")
            end

            if objective.Type == "Defend" then
                assert(mission.Layout.Points[objective.Target], objective.Id .. " target missing")
                assert(objective.TargetHealth > 0, objective.Id .. " target health")
            end

            if objective.Type == "Defend" or objective.Type == "Defeat" then
                assert(objective.Waves and #objective.Waves > 0, objective.Id .. " needs waves")
            end

            for _, wave in ipairs(objective.Waves or {}) do
                assert(wave.AtSecond or wave.AfterCleared, objective.Id .. " wave needs a trigger")

                for _, spawn in ipairs(wave.Spawns) do
                    local unit = BattleMissions.Units[spawn.Unit]
                    assert(unit, "unknown unit " .. spawn.Unit)
                    assert(unit.Team == "makkah", "waves spawn opponents only: " .. spawn.Unit)
                    assert(mission.Layout.Lanes[spawn.Lane], "unknown lane " .. spawn.Lane)
                end
            end
        end

        assert(seen[mission.Steadfast.Objective], id .. " steadfast objective missing")
        assert(#mission.Reflection >= 3, id .. " needs reflection questions")

        for _, question in ipairs(mission.Reflection) do
            assert(question.Answer >= 1 and question.Answer <= #question.Choices, question.Id .. " answer out of range")
        end

        for _, ally in ipairs(mission.Allies) do
            assert(BattleMissions.Units[ally.Unit].Team == "medina", "allies must be on the Medina side")
            assert(mission.Layout.Points[ally.Point], "ally point missing " .. ally.Point)
        end
    end
end)

test("no unit or narration title presents the Prophet as a character", function()
    for name, unit in pairs(BattleMissions.Units) do
        local display = string.lower(unit.DisplayName)
        assert(not string.find(display, "prophet") and not string.find(display, "muhammad") and not string.find(display, "messenger"), name)
    end
end)

test("opponent counts grow with players", function()
    expectEqual(MissionRules.ScaleCount({ Count = 3, PerExtraPlayer = 1 }, 1), 3, "solo")
    expectEqual(MissionRules.ScaleCount({ Count = 3, PerExtraPlayer = 1 }, 4), 6, "four players")
    expectEqual(MissionRules.ScaleCount({ Count = 1, PerExtraPlayer = 0.5 }, 2), 2, "half per player rounds")
    expectEqual(MissionRules.ScaleCount({ Count = 1 }, 8), 1, "bosses stay single")
    assert(MissionRules.HealthMultiplier(1) == 1, "solo health")
    assert(MissionRules.HealthMultiplier(20) <= 2.2, "health capped")
    assert(MissionRules.MaxAliveEnemies(50) == MissionRules.MaxAliveEnemiesCap, "alive cap")
end)

test("hold timer needs a player and pauses when overrun", function()
    local progress, state = MissionRules.StepHold(5, 1, 40, 0, 0)
    expectEqual(progress, 5, "empty ring keeps progress")
    expectEqual(state, "Empty", "empty state")
    progress, state = MissionRules.StepHold(5, 1, 40, 1, 3)
    expectEqual(state, "Contested", "overrun")
    expectEqual(progress, 5, "contested keeps progress")
    progress, state = MissionRules.StepHold(39.5, 1, 40, 2, 1)
    expectEqual(progress, 40, "caps at required")
    expectEqual(state, "Holding", "holding")
end)

test("stars reward completion, steadfastness, and few falls", function()
    local mission = BattleMissions.Get("uhud")
    local stars = MissionRules.ComputeStars(mission, { Completed = true, Falls = 0, PlayerCount = 1, SteadfastKept = true })
    expectEqual(stars, 3, "perfect")
    stars = MissionRules.ComputeStars(mission, { Completed = true, Falls = 3, PlayerCount = 2, SteadfastKept = false })
    expectEqual(stars, 1, "completed only")
    stars = MissionRules.ComputeStars(mission, { Completed = false, Falls = 0, PlayerCount = 1, SteadfastKept = true })
    expectEqual(stars, 0, "failed missions earn nothing")
    expectEqual(MissionRules.StarBonus(1, 3), 80, "two new stars")
    expectEqual(MissionRules.StarBonus(3, 2), 0, "no bonus below best")
end)

test("reflection grading hides answers from the client", function()
    local mission = BattleMissions.Get("badr")
    local graded = MissionRules.GradeReflection(mission, { 1, 2, 1 })
    expectEqual(graded.Total, 3, "total")
    expectEqual(graded.Correct, 2, "two right")
    expectEqual(MissionRules.GradeReflection(mission, "junk").Correct, 0, "junk answers")

    for _, question in ipairs(MissionRules.ReflectionForClient(mission)) do
        expectEqual(question.Answer, nil, "answer must not be sent")
        expectEqual(question.Explanation, nil, "explanation must not be sent")
    end
end)

test("battle mission badges", function()
    local profile = Progression.NewProfile()
    local function has(id)
        for _, badge in ipairs(Progression.FindNewBadges(profile)) do
            if badge.Id == id then
                return true
            end
        end
        return false
    end

    assert(not has("badr_three_stars"), "not yet")
    profile.Stats.BestStars_badr = 3
    profile.Stats.UhudPostKept = 1
    assert(has("badr_three_stars"), "three stars at Badr")
    assert(has("uhud_kept_post"), "kept the post")

    for _, id in ipairs(BattleMissions.Order) do
        for _, question in ipairs(BattleMissions.Get(id).Reflection) do
            profile.Completed.reflection[question.Id] = true
        end
    end

    assert(has("battle_lessons"), "all reflections")
    assert(Progression.GetCompletionReward("reflection", true) > 0, "reflection pays XP")
end)
