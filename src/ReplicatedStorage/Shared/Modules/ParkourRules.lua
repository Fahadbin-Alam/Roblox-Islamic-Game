--!strict

-- Pure rules for timed parkour runs: checkpoints must be touched in order, the finish is the
-- last checkpoint, and a run faster than the course's minimum time is rejected as impossible
-- (teleport or exploit), so the best-time board stays honest.

local ParkourRules = {}

export type Course = {
    Id: string,
    Checkpoints: number,
    MinSeconds: number,
}

export type Run = {
    CourseId: string,
    Last: number,
    StartedAt: number?,
    FinishedSeconds: number?,
}

function ParkourRules.NewRun(course: Course): Run
    return { CourseId = course.Id, Last = 0, StartedAt = nil, FinishedSeconds = nil }
end

-- Checkpoint 1 is the start pad. Touching it again restarts the timer.
-- Returns "start", "checkpoint", "finish", "rejected", or "ignored".
function ParkourRules.Touch(course: Course, run: Run, index: number, now: number): string
    if index == 1 then
        run.Last = 1
        run.StartedAt = now
        run.FinishedSeconds = nil
        return "start"
    end

    if run.StartedAt == nil or run.FinishedSeconds ~= nil or index ~= run.Last + 1 then
        return "ignored"
    end

    run.Last = index

    if index < course.Checkpoints then
        return "checkpoint"
    end

    local elapsed = now - (run.StartedAt :: number)

    if elapsed < course.MinSeconds then
        run.StartedAt = nil
        run.Last = 0
        return "rejected"
    end

    run.FinishedSeconds = elapsed

    return "finish"
end

-- Where a fallen player goes back to: the last checkpoint reached (1 = start).
function ParkourRules.RespawnIndex(run: Run): number
    return math.max(1, run.Last)
end

function ParkourRules.IsBetter(previousBest: number?, seconds: number): boolean
    return previousBest == nil or previousBest <= 0 or seconds < previousBest
end

function ParkourRules.FormatTime(seconds: number): string
    local whole = math.floor(seconds)

    return string.format("%d:%02d.%d", whole // 60, whole % 60, math.floor((seconds - whole) * 10))
end

return ParkourRules
