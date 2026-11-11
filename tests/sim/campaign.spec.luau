-- One player plays all 30 Seerah chapters in order through the real SeerahCampaignService and
-- the historical world it runs in: travel, walk to the site, story, items, battles, decisions.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SeerahCampaign = require(ReplicatedStorage.Shared.Data.SeerahCampaign)
local HistoricalSites = require(ReplicatedStorage.Shared.Data.HistoricalSites)
local PlayerProgress = require(game:GetService("ServerScriptService").Modules.PlayerProgress)

local student = sim.addPlayer(9501, "Maryam")
sim.advance(0.5)

local function state()
    return sim.last(student, "Campaign/State")
end

local function stage()
    local s = state()
    return s and s.Run and s.Run.Stage
end

local function act(action, argument)
    sim.fireServer(student, "Campaign/Request", action, argument)
end

local itemsFolder = Workspace:WaitForChild(HistoricalSites.FolderName):WaitForChild("CampaignItems")

test("a later chapter stays locked until the earlier ones are done", function()
    act("Start", SeerahCampaign.Chapters[3].Id)
    expectEqual(state().Feedback and state().Feedback.Kind, "warning", "chapter 3 is locked")
    expectEqual(state().Run, nil, "no run started")
end)

local timeline = {}

test("all 30 chapters can be played in order to the end", function()
    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        local site = HistoricalSites.GetSite(chapter.Site)
        act("Start", chapter.Id)
        expectEqual(stage(), "Travel", chapter.Id .. " starts with travel")

        act("Travel")
        local arrival = HistoricalSites.ArrivalPoint(site)
        local dropped = sim.root(student).Position
        expectTrue((dropped - arrival).Magnitude < 130, chapter.Id .. ": travel drops the player near the site")
        sim.advance(0.5)
        expectEqual(stage(), "Travel", chapter.Id .. ": the story waits until the player walks up")

        sim.place(student, arrival + Vector3.new(0, 3, 0), site.Position)
        sim.advance(0.5)
        expectEqual(stage(), "Story", chapter.Id .. ": arriving at the site starts the story")

        act("FinishStory")
        local activity = chapter.Activity
        if activity and activity.Kind == "Collect" then
            expectEqual(stage(), "Activity", chapter.Id .. " has a collect activity")
            local folder = itemsFolder:WaitForChild(chapter.Id)
            for _, item in ipairs(folder:GetChildren()) do
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                -- From too far away the pickup does not count.
                sim.place(student, item.Position + Vector3.new(60, 0, 0), item.Position)
                prompt.Triggered._fire(student)
                sim.place(student, item.Position + Vector3.new(4, 0, 0), item.Position)
                prompt.Triggered._fire(student)
            end
            expectEqual(#state().Run.Collected, activity.Count, chapter.Id .. ": every item collected")
            expectEqual(stage(), "Decision", chapter.Id .. ": collecting everything leads to the decision")
        elseif activity and activity.Kind == "Battle" then
            expectEqual(stage(), "Activity", chapter.Id .. " waits for the battle")
            act("CheckBattle")
            expectEqual(stage(), "Activity", chapter.Id .. ": not done before the mission")
            -- The Story Mission itself is covered by tests/world; here it records its result.
            PlayerProgress.RecordCompletion(student, "battle", activity.ScenarioId, activity.ScenarioId)
            act("CheckBattle")
            expectEqual(stage(), "Decision", chapter.Id .. ": the finished mission unlocks the decision")
        else
            expectEqual(stage(), "Decision", chapter.Id .. " goes straight to the decision")
        end

        local wrong = if chapter.Decision.CorrectIndex == 1 then 2 else 1
        act("Answer", wrong)
        expectEqual(state().Feedback.Kind, "retry", chapter.Id .. ": a wrong answer asks to try again")
        act("Answer", chapter.Decision.CorrectIndex)
        expectEqual(state().Feedback.Kind, "success", chapter.Id .. ": the right answer finishes the chapter")
        expectTrue(#(state().Feedback.Text or "") > 20, chapter.Id .. ": the explanation is shown")
        expectTrue(PlayerProgress.HasCompleted(student, "seerah", chapter.Id), chapter.Id .. " is saved as completed")
        table.insert(timeline, chapter.Number)
        act("Close")
    end
    expectEqual(#timeline, 30, "all chapters played")
end)

test("the checklist shows all 30 chapters done", function()
    act("State")
    expectEqual(state().DoneCount, 30, "30 of 30 done")
    expectEqual(PlayerProgress.GetStat(student, "SeerahChapters"), 30, "chapter count stat")
    for _, row in ipairs(state().Checklist) do
        expectTrue(row.Done, row.Id .. " is ticked")
    end
end)

test("replaying a finished chapter does not pay out twice", function()
    act("Start", SeerahCampaign.Chapters[1].Id)
    expectEqual(stage(), "Travel", "a finished chapter can be replayed")
    expectEqual(PlayerProgress.GetStat(student, "SeerahChapters"), 30, "replay starts without changing the count")
    act("Close")
end)
