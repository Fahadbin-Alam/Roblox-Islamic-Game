--!strict

-- Times runs on the Lobby Parkour Tower (layout in Shared/Data/ParkourCourses, rules in
-- Shared/Modules/ParkourRules). The server watches each climber's position, so checkpoints work
-- the same on every device: step on the green start pad to start the clock, reach the gold
-- checkpoint steps in order, and the summit stops it. Falling to the deck (or resetting) puts
-- the climber back on their last checkpoint. Best times are saved.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ParkourCourses = require(Shared.Data.ParkourCourses)
local ParkourRules = require(Shared.Modules.ParkourRules)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local Analytics = require(script.Parent.Modules.Analytics)

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Parkour")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local course = ParkourCourses.LobbyTower
local rulesCourse: ParkourRules.Course = { Id = course.Id, Checkpoints = #course.Checkpoints, MinSeconds = course.MinSeconds }
local center = (TravelRoute.GetDestinationById("parkour_tower") :: any).Position - Vector3.new(0, 4, 0)
local BEST_STAT = "ParkourBest_" .. course.Id

local runs: { [Player]: ParkourRules.Run } = {}

local function checkpointWorld(index: number): Vector3
    return center + course.Checkpoints[index].Offset
end

local function onCheckpoint(position: Vector3, index: number): boolean
    local target = checkpointWorld(index)
    local offset = position - target
    local radius = if index == #course.Checkpoints then course.SummitRadius - 1 elseif index == 1 then course.StartSize.X / 2 else 5.5

    return Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and offset.Y >= 1 and offset.Y <= 6
end

local function send(player: Player, event: string, extra: { [string]: any }?)
    local run = runs[player]
    local data: { [string]: any } = {
        Event = event,
        Active = run ~= nil and run.StartedAt ~= nil and run.FinishedSeconds == nil,
        Checkpoint = run and run.Last or 0,
        Total = #course.Checkpoints,
        StartedAt = run and run.StartedAt,
        ServerNow = Workspace:GetServerTimeNow(),
        Best = PlayerProgress.GetStat(player, BEST_STAT),
    }

    if extra then
        for key, value in pairs(extra) do
            data[key] = value
        end
    end

    stateEvent:FireClient(player, data)
end

local function returnToCheckpoint(player: Player)
    local run = runs[player]
    local character = player.Character

    if not run or not character then
        return
    end

    local index = ParkourRules.RespawnIndex(run)
    character:PivotTo(CFrame.new(checkpointWorld(index) + Vector3.new(0, 4, 0)))
end

local function step(player: Player, root: BasePart)
    local run = runs[player]

    if not run then
        run = ParkourRules.NewRun(rulesCourse)
        runs[player] = run
    end

    local position = root.Position
    local now = Workspace:GetServerTimeNow()

    -- Only the start pad and the next checkpoint can count.
    for _, index in ipairs({ 1, run.Last + 1 }) do
        if index <= #course.Checkpoints and onCheckpoint(position, index) and not (index == 1 and run.Last == 1 and run.FinishedSeconds == nil and run.StartedAt ~= nil) then
            local result = ParkourRules.Touch(rulesCourse, run, index, now)

            if result == "finish" then
                local seconds = run.FinishedSeconds :: number
                local previous = PlayerProgress.GetStat(player, BEST_STAT)
                local improved = ParkourRules.IsBetter(previous, seconds)

                if improved then
                    PlayerProgress.SetStatMin(player, BEST_STAT, seconds)
                end

                PlayerProgress.RecordCompletion(player, "parkour", course.Id, course.DisplayName)
                Analytics.Custom(player, "ParkourFinish", math.floor(seconds))
                send(player, "finish", { Seconds = seconds, Improved = improved, Text = ParkourRules.FormatTime(seconds) })
            elseif result == "rejected" then
                send(player, "rejected")
            elseif result == "start" or result == "checkpoint" then
                send(player, result)
            end

            return
        end
    end

    -- Fell back to the deck during a run: return to the last checkpoint.
    if run.StartedAt and run.FinishedSeconds == nil and run.Last >= 2 then
        local last = checkpointWorld(run.Last)
        local onDeck = position.Y < center.Y + 4 + 6
        local offset = position - center

        if onDeck and Vector3.new(offset.X, 0, offset.Z).Magnitude < 90 and position.Y < last.Y - 12 then
            returnToCheckpoint(player)
            send(player, "fell")
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.15)

        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if root and root:IsA("BasePart") then
                local offset = root.Position - center

                if math.abs(offset.X) < 100 and math.abs(offset.Z) < 80 and offset.Y < course.SummitHeight + 30 then
                    step(player, root)
                elseif runs[player] and runs[player].StartedAt and runs[player].FinishedSeconds == nil then
                    -- Left the course (teleported away): the run is over.
                    runs[player] = nil
                    send(player, "left")
                end
            end
        end
    end
end)

request.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "Checkpoint" then
        returnToCheckpoint(player)
    elseif action == "Quit" then
        runs[player] = nil
        send(player, "left")
    elseif action == "State" then
        send(player, "state")
    end
end)

-- A climber who resets their character mid-run reappears at their checkpoint.
local function watch(player: Player)
    player.CharacterAdded:Connect(function(character)
        local run = runs[player]

        if run and run.StartedAt and run.FinishedSeconds == nil and run.Last >= 2 then
            local root = character:WaitForChild("HumanoidRootPart", 5)

            if root then
                task.wait(0.1)
                returnToCheckpoint(player)
            end
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    watch(player)
end

Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(player: Player)
    runs[player] = nil
end)
