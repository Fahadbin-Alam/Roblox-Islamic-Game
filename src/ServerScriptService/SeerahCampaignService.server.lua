--!strict

-- Runs the Seerah campaign (Shared/Data/SeerahCampaign, rules in Shared/Modules/CampaignRules).
-- Each player has at most one chapter in progress. The server owns every step: it detects
-- arrival at the chapter's site, checks each item pickup and the battle mission, grades the
-- decision, and saves the finished chapter to the player's profile.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CampaignRules = require(Shared.Modules.CampaignRules)
local HistoricalSites = require(Shared.Data.HistoricalSites)
local SeerahCampaign = require(Shared.Data.SeerahCampaign)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local Analytics = require(script.Parent.Modules.Analytics)

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Campaign")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local CATEGORY = "seerah"
local runs: { [Player]: CampaignRules.Run } = {}

local function completedSet(player: Player): { [string]: boolean }
    local profile = PlayerProgress.Get(player)

    return (profile and profile.Completed[CATEGORY]) or {}
end

local function sendState(player: Player, feedback: { Kind: string, Text: string }?)
    local run = runs[player]
    local completed = completedSet(player)
    local collected = {}

    if run then
        for index in pairs(run.Collected) do
            table.insert(collected, index)
        end
    end

    stateEvent:FireClient(player, {
        Checklist = CampaignRules.Checklist(completed),
        DoneCount = CampaignRules.CountDone(completed),
        Total = #SeerahCampaign.Chapters,
        Run = run and {
            ChapterId = run.ChapterId,
            Stage = run.Stage,
            Collected = collected,
            WrongAnswers = run.WrongAnswers,
        } or nil,
        Feedback = feedback,
    })
end

local function getRoot(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    return if root and root:IsA("BasePart") then root else nil
end

local function isBusy(player: Player): boolean
    return player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true
end

local function teleport(player: Player, position: Vector3, lookAt: Vector3?)
    local character = player.Character

    if not character then
        return
    end

    local target = if lookAt then CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)) else CFrame.new(position)
    character:PivotTo(target)
end

local function siteFor(run: CampaignRules.Run): HistoricalSites.Site?
    local chapter = CampaignRules.GetChapter(run.ChapterId)

    return chapter and HistoricalSites.GetSite(chapter.Site)
end

-- Players arrive a short walk from the site so they explore a little; on mountains they start
-- at the foot and climb.
local function travelPoint(site: HistoricalSites.Site): Vector3
    if site.Kind == "Mountain" then
        return site.Position + Vector3.new(0, HistoricalSites.GroundTop + 4, -104)
    end

    return HistoricalSites.ArrivalPoint(site) + Vector3.new(0, 4, -42)
end

local function battleDone(player: Player, run: CampaignRules.Run): boolean
    local chapter = CampaignRules.GetChapter(run.ChapterId)
    local activity = chapter and chapter.Activity

    if activity and activity.Kind == "Battle" and activity.ScenarioId then
        return CampaignRules.BattleDone(run, PlayerProgress.HasCompleted(player, "battle", activity.ScenarioId))
    end

    return false
end

local actions = {}

function actions.State(player: Player)
    sendState(player)
end

function actions.Start(player: Player, chapterId: any)
    if type(chapterId) ~= "string" then
        return
    end

    local completed = completedSet(player)

    if not CampaignRules.IsUnlocked(completed, chapterId) then
        sendState(player, { Kind = "warning", Text = "Finish the chapter before this one first." })
        return
    end

    runs[player] = CampaignRules.NewRun(chapterId)
    Analytics.Funnel(player, "SeerahChapter", CampaignRules.IndexOf(chapterId) or 0, chapterId)
    sendState(player)
end

function actions.Travel(player: Player)
    local run = runs[player]
    local site = run and siteFor(run)

    if not run or not site then
        return
    end

    if isBusy(player) then
        sendState(player, { Kind = "warning", Text = "Finish your battle or story first." })
        return
    end

    teleport(player, travelPoint(site), HistoricalSites.ArrivalPoint(site))
end

function actions.FinishStory(player: Player)
    local run = runs[player]

    if run and CampaignRules.FinishStory(run) then
        -- Players who already finished the battle mission go straight to the decision.
        battleDone(player, run)
        sendState(player)
    end
end

function actions.CheckBattle(player: Player)
    local run = runs[player]

    if not run then
        return
    end

    if battleDone(player, run) then
        sendState(player, { Kind = "success", Text = "Mission complete. Answer the chapter question to finish." })
    else
        sendState(player, { Kind = "info", Text = "Finish the Story Mission at the battle gate, then come back." })
    end
end

function actions.GoBattle(player: Player)
    local run = runs[player]
    local chapter = run and CampaignRules.GetChapter(run.ChapterId)
    local activity = chapter and chapter.Activity

    if not activity or activity.Kind ~= "Battle" or isBusy(player) then
        return
    end

    local hub = Workspace:FindFirstChild(TravelRoute.WorldFolderName)
    local points = hub and hub:FindFirstChild("TeleportPoints")
    local anchor = points and points:FindFirstChild(string.format("%s_gate", activity.ScenarioId or ""))

    if anchor and anchor:IsA("BasePart") then
        teleport(player, anchor.Position + Vector3.new(0, 4, 0), nil)
    end
end

function actions.Answer(player: Player, optionIndex: any)
    local run = runs[player]

    if not run or type(optionIndex) ~= "number" then
        return
    end

    local chapter = CampaignRules.GetChapter(run.ChapterId)
    local correct, explanation = CampaignRules.Answer(run, optionIndex)

    if not chapter then
        return
    end

    if not correct then
        sendState(player, { Kind = "retry", Text = "Not quite. Look back at the story and try again." })
        return
    end

    local firstTime = PlayerProgress.RecordCompletion(player, CATEGORY, chapter.Id, string.format("Seerah %d: %s", chapter.Number, chapter.Title))

    if firstTime then
        PlayerProgress.IncrementStat(player, "SeerahChapters", 1)
        Analytics.Custom(player, "SeerahChapterDone", chapter.Number)
    end

    sendState(player, { Kind = "success", Text = explanation or "" })
end

function actions.Close(player: Player)
    runs[player] = nil
    sendState(player)
end

request.OnServerEvent:Connect(function(player: Player, action: any, argument: any)
    local handler = type(action) == "string" and actions[action]

    if handler then
        handler(player, argument)
    end
end)

-- Item pickups. The prompts are hidden for everyone except players on that chapter, but the
-- server checks the run and the distance anyway.
local function connectItemPrompt(prompt: ProximityPrompt)
    if prompt:GetAttribute("PromptAction") ~= "CampaignCollect" then
        return
    end

    prompt.Triggered:Connect(function(player: Player)
        local run = runs[player]
        local item = prompt.Parent
        local root = getRoot(player)

        if not run or run.ChapterId ~= prompt:GetAttribute("ChapterId") or not item or not item:IsA("BasePart") or not root then
            return
        end

        if (root.Position - item.Position).Magnitude > prompt.MaxActivationDistance + 6 then
            return
        end

        local index = prompt:GetAttribute("ItemIndex")

        if type(index) == "number" and CampaignRules.Collect(run, index) then
            sendState(player)
        end
    end)
end

task.spawn(function()
    local world = Workspace:WaitForChild(HistoricalSites.FolderName)

    while world:GetAttribute("Built") ~= true do
        world:GetAttributeChangedSignal("Built"):Wait()
    end

    for _, descendant in ipairs(world:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            connectItemPrompt(descendant)
        end
    end
end)

-- Arrival: a chapter's story starts once the player stands at its site.
task.spawn(function()
    while true do
        task.wait(0.4)

        for player, run in pairs(runs) do
            if run.Stage == "Travel" then
                local site = siteFor(run)
                local root = getRoot(player)

                if site and root then
                    local arrival = HistoricalSites.ArrivalPoint(site)
                    local offset = root.Position - arrival

                    if Vector3.new(offset.X, 0, offset.Z).Magnitude <= SeerahCampaign.StartRadius and offset.Y > -3 and offset.Y < 14 then
                        CampaignRules.Arrive(run)
                        sendState(player)
                    end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player: Player)
    runs[player] = nil
end)
