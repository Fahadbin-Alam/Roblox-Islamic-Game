--!strict

-- Pure rules for the battle story missions, shared by the server (which runs the mission)
-- and the client (which shows it). No Roblox services, so it can be unit tested.

local MissionRules = {}

MissionRules.StarBonusXP = 40
MissionRules.MaxAliveEnemiesBase = 10
MissionRules.MaxAliveEnemiesPerPlayer = 3
MissionRules.MaxAliveEnemiesCap = 26

-- Opponent count for one spawn entry, grown for each player beyond the first.
function MissionRules.ScaleCount(spawn: { Count: number, PerExtraPlayer: number? }, playerCount: number): number
    local extraPlayers = math.max(0, math.floor(playerCount) - 1)
    local count = spawn.Count + (spawn.PerExtraPlayer or 0) * extraPlayers

    return math.max(0, math.floor(count + 0.5))
end

-- Opponents get a little tougher as more players join, so co-op stays a challenge.
function MissionRules.HealthMultiplier(playerCount: number): number
    return math.min(2.2, 1 + 0.18 * math.max(0, playerCount - 1))
end

function MissionRules.MaxAliveEnemies(playerCount: number): number
    return math.min(
        MissionRules.MaxAliveEnemiesCap,
        MissionRules.MaxAliveEnemiesBase + MissionRules.MaxAliveEnemiesPerPlayer * math.max(1, playerCount)
    )
end

-- Advances a hold timer. Holding needs at least one player in the ring, and pauses while the
-- ring is contested by more than twice as many opponents as players.
function MissionRules.StepHold(progress: number, deltaSeconds: number, required: number, playersInZone: number, enemiesInZone: number): (number, string)
    if playersInZone <= 0 then
        return progress, "Empty"
    end

    if enemiesInZone > playersInZone * 2 then
        return progress, "Contested"
    end

    return math.min(required, progress + deltaSeconds), "Holding"
end

export type MissionResult = {
    Completed: boolean,
    Falls: number,
    PlayerCount: number,
    SteadfastKept: boolean,
}

-- Three stars: finish the mission, keep the mission's steadfast condition, and fall no more
-- than once per player.
function MissionRules.ComputeStars(mission: any, result: MissionResult): (number, { { Label: string, Earned: boolean } })
    local details = {
        { Label = "Complete the mission", Earned = result.Completed },
        { Label = (mission.Steadfast and mission.Steadfast.Label) or "Stay steadfast", Earned = result.Completed and result.SteadfastKept },
        { Label = "No more than one fall per player", Earned = result.Completed and result.Falls <= math.max(1, result.PlayerCount) },
    }
    local stars = 0

    for _, detail in ipairs(details) do
        if detail.Earned then
            stars += 1
        end
    end

    return stars, details
end

-- XP for beating a previous best star count. Replays only pay for new stars.
function MissionRules.StarBonus(previousBest: number, stars: number): number
    return math.max(0, stars - math.max(0, previousBest)) * MissionRules.StarBonusXP
end

-- Grades reflection answers. `answers[i]` is the chosen index for question i.
function MissionRules.GradeReflection(mission: any, answers: any)
    local results = {}
    local correct = 0
    local questions = mission.Reflection or {}

    for index, question in ipairs(questions) do
        local chosen = type(answers) == "table" and answers[index] or nil
        local isCorrect = type(chosen) == "number" and chosen == question.Answer

        if isCorrect then
            correct += 1
        end

        table.insert(results, {
            Id = question.Id,
            Correct = isCorrect,
            Answer = question.Answer,
            Explanation = question.Explanation,
        })
    end

    return {
        Correct = correct,
        Total = #questions,
        Results = results,
    }
end

-- Questions as the client sees them: no answers.
function MissionRules.ReflectionForClient(mission: any)
    local questions = {}

    for _, question in ipairs(mission.Reflection or {}) do
        table.insert(questions, {
            Id = question.Id,
            Prompt = question.Prompt,
            Choices = question.Choices,
        })
    end

    return questions
end

return MissionRules
