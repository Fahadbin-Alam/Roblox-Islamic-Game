--!strict

-- Pure rules for the Seerah campaign. The server keeps one run per player and moves it
-- through the stages below. No Roblox services are used, so the rules are unit tested.
--
-- Stages: Travel (walk to the chapter's site) -> Story (read the narration) -> Activity
-- (collect items or finish the battle mission, if the chapter has one) -> Decision (answer the
-- question about what was decided) -> Done.

local SeerahCampaign = require(script.Parent.Parent.Data.SeerahCampaign)

local CampaignRules = {}

export type Run = {
    ChapterId: string,
    Stage: string,
    Collected: { [number]: boolean },
    WrongAnswers: number,
}

local chapterById = {}

for index, chapter in ipairs(SeerahCampaign.Chapters) do
    chapterById[chapter.Id] = { Chapter = chapter, Index = index }
end

function CampaignRules.GetChapter(id: string): SeerahCampaign.Chapter?
    local entry = chapterById[id]

    return entry and entry.Chapter
end

function CampaignRules.IndexOf(id: string): number?
    local entry = chapterById[id]

    return entry and entry.Index
end

-- Chapters open one at a time, in order. `completed` is the saved set of finished chapter ids.
function CampaignRules.IsUnlocked(completed: { [string]: boolean }, id: string): boolean
    local index = CampaignRules.IndexOf(id)

    if not index then
        return false
    end

    if index == 1 then
        return true
    end

    return completed[SeerahCampaign.Chapters[index - 1].Id] == true
end

function CampaignRules.NextChapter(completed: { [string]: boolean }): SeerahCampaign.Chapter?
    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        if completed[chapter.Id] ~= true then
            return chapter
        end
    end

    return nil
end

function CampaignRules.Checklist(completed: { [string]: boolean })
    local list = {}

    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        table.insert(list, {
            Id = chapter.Id,
            Number = chapter.Number,
            Title = chapter.Title,
            When = chapter.When,
            Era = chapter.Era,
            Done = completed[chapter.Id] == true,
            Unlocked = CampaignRules.IsUnlocked(completed, chapter.Id),
        })
    end

    return list
end

function CampaignRules.CountDone(completed: { [string]: boolean }): number
    local count = 0

    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        if completed[chapter.Id] == true then
            count += 1
        end
    end

    return count
end

function CampaignRules.NewRun(id: string): Run?
    if not chapterById[id] then
        return nil
    end

    return {
        ChapterId = id,
        Stage = "Travel",
        Collected = {},
        WrongAnswers = 0,
    }
end

local function afterStory(chapter: SeerahCampaign.Chapter): string
    return if chapter.Activity then "Activity" else "Decision"
end

function CampaignRules.Arrive(run: Run): boolean
    if run.Stage ~= "Travel" then
        return false
    end

    run.Stage = "Story"

    return true
end

function CampaignRules.FinishStory(run: Run): boolean
    if run.Stage ~= "Story" then
        return false
    end

    run.Stage = afterStory(chapterById[run.ChapterId].Chapter)

    return true
end

function CampaignRules.CollectCount(run: Run): number
    local count = 0

    for _ in pairs(run.Collected) do
        count += 1
    end

    return count
end

-- Records one collected item. Returns true when the item counted.
function CampaignRules.Collect(run: Run, itemIndex: number): boolean
    local chapter = chapterById[run.ChapterId].Chapter
    local activity = chapter.Activity

    if run.Stage ~= "Activity" or not activity or activity.Kind ~= "Collect" then
        return false
    end

    local count = activity.Count or 0

    if type(itemIndex) ~= "number" or itemIndex % 1 ~= 0 or itemIndex < 1 or itemIndex > count or run.Collected[itemIndex] then
        return false
    end

    run.Collected[itemIndex] = true

    if CampaignRules.CollectCount(run) >= count then
        run.Stage = "Decision"
    end

    return true
end

-- For Battle activities: the server calls this once the player has finished the mission.
function CampaignRules.BattleDone(run: Run, battleCompleted: boolean): boolean
    local activity = chapterById[run.ChapterId].Chapter.Activity

    if run.Stage ~= "Activity" or not activity or activity.Kind ~= "Battle" or not battleCompleted then
        return false
    end

    run.Stage = "Decision"

    return true
end

-- Grades the decision. A wrong answer explains nothing yet and lets the player try again.
function CampaignRules.Answer(run: Run, optionIndex: number): (boolean, string?)
    if run.Stage ~= "Decision" then
        return false, nil
    end

    local decision = chapterById[run.ChapterId].Chapter.Decision

    if optionIndex == decision.CorrectIndex then
        run.Stage = "Done"

        return true, decision.Explanation
    end

    run.WrongAnswers += 1

    return false, nil
end

-- Where item `index` of a Collect chapter lies, as an offset from the site's arrival point.
-- Items ring the site at two distances; on mountain ledges they stay close to the cave.
function CampaignRules.ItemOffset(chapter: SeerahCampaign.Chapter, index: number, onLedge: boolean): Vector3
    local count = (chapter.Activity and chapter.Activity.Count) or 1
    local angle = (index - 1) * (2 * math.pi / count) + chapter.Number * 0.7
    local near, far = if onLedge then 10 else 24, if onLedge then 18 else 44
    local radius = if index % 2 == 0 then far else near

    return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

return CampaignRules
