--!strict

-- Pure rules for the Sahabi mysteries. One run is shared by everyone in a room, so clues,
-- hints, and episode stations found by one player count for the whole group.

local SahabiMysteries = require(script.Parent.Parent.Data.SahabiMysteries)

local MysteryRules = {}

export type Run = {
    MysteryId: string,
    Found: { [string]: boolean },
    HintsUsed: number,
    WrongTries: number,
    LockOpen: boolean,
    StationsDone: { [number]: boolean },
    Done: boolean,
}

local byId = {}

for _, mystery in ipairs(SahabiMysteries.Mysteries) do
    byId[mystery.Id] = mystery
end

function MysteryRules.Get(id: string): SahabiMysteries.Mystery?
    return byId[id]
end

function MysteryRules.NewRun(id: string): Run?
    if not byId[id] then
        return nil
    end

    return {
        MysteryId = id,
        Found = {},
        HintsUsed = 0,
        WrongTries = 0,
        LockOpen = false,
        StationsDone = {},
        Done = false,
    }
end

function MysteryRules.FoundCount(run: Run): number
    local count = 0

    for _ in pairs(run.Found) do
        count += 1
    end

    return count
end

-- Returns the clue when it was newly found.
function MysteryRules.FindClue(run: Run, clueId: string): SahabiMysteries.Clue?
    if run.Found[clueId] then
        return nil
    end

    for _, clue in ipairs(byId[run.MysteryId].Clues) do
        if clue.Id == clueId then
            run.Found[clueId] = true
            return clue
        end
    end

    return nil
end

function MysteryRules.AllCluesFound(run: Run): boolean
    return MysteryRules.FoundCount(run) >= #byId[run.MysteryId].Clues
end

-- Hints are given in order. Returns nil when none are left.
function MysteryRules.TakeHint(run: Run): string?
    local hints = byId[run.MysteryId].Hints

    if run.HintsUsed >= #hints then
        return nil
    end

    run.HintsUsed += 1

    return hints[run.HintsUsed]
end

-- `answers` holds one option index per lock question. All must be right to open the door.
function MysteryRules.TryLock(run: Run, answers: { number }): boolean
    if run.LockOpen then
        return true
    end

    if type(answers) ~= "table" then
        return false
    end

    for index, question in ipairs(byId[run.MysteryId].Lock) do
        if answers[index] ~= question.CorrectIndex then
            run.WrongTries += 1
            return false
        end
    end

    run.LockOpen = true

    return true
end

function MysteryRules.NextStation(run: Run): number?
    for index in ipairs(byId[run.MysteryId].Episode.Stations) do
        if not run.StationsDone[index] then
            return index
        end
    end

    return nil
end

-- Returns (counted, finished). Stations open only after the lock; ordered episodes take
-- stations one after another.
function MysteryRules.VisitStation(run: Run, index: number): (boolean, boolean)
    local episode = byId[run.MysteryId].Episode

    if not run.LockOpen or run.Done or type(index) ~= "number" or not episode.Stations[index] or run.StationsDone[index] then
        return false, run.Done
    end

    if episode.Ordered and MysteryRules.NextStation(run) ~= index then
        return false, false
    end

    run.StationsDone[index] = true

    if MysteryRules.NextStation(run) == nil then
        run.Done = true
    end

    return true, run.Done
end

-- Three stars, minus one for leaning on hints (two or more) and one for guessing at the lock
-- (two or more wrong tries). Never below one.
function MysteryRules.Stars(run: Run): number
    local stars = SahabiMysteries.MaxStars

    if run.HintsUsed >= 2 then
        stars -= 1
    end

    if run.WrongTries >= 2 then
        stars -= 1
    end

    return math.max(1, stars)
end

return MysteryRules
