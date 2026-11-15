-- A player climbs the parkour tower platform by platform at walking pace, through the real
-- ParkourService: checkpoints in order, a fall back to the last checkpoint, and a saved time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParkourCourses = require(ReplicatedStorage.Shared.Data.ParkourCourses)
local TravelRoute = require(ReplicatedStorage.Shared.Data.TravelRoute)
local PlayerProgress = require(game:GetService("ServerScriptService").Modules.PlayerProgress)

local course = ParkourCourses.LobbyTower
local center = TravelRoute.GetDestinationById("parkour_tower").Position - Vector3.new(0, 4, 0)
local climber = sim.addPlayer(9401, "Khalid")
sim.advance(0.5)

local function stand(offset, top)
    local at = center + offset + Vector3.new(0, (top or 0) + 3, 0)
    sim.place(climber, at, at + Vector3.new(1, 0, 0))
end

local function events()
    local list = {}
    for _, payload in ipairs(sim.received(climber, "Parkour/State")) do
        table.insert(list, payload.Event)
    end
    return list
end

local function lastEvent()
    local list = events()
    return list[#list]
end

test("stepping on the start pad starts the clock", function()
    stand(course.Checkpoints[1].Offset, 0)
    sim.advance(0.5)
    expectEqual(lastEvent(), "start", "the run started")
end)

test("skipping ahead to a later checkpoint does not count", function()
    stand(course.Checkpoints[3].Offset, 0.75)
    sim.advance(0.5)
    expectEqual(sim.last(climber, "Parkour/State").Checkpoint, 1, "still at the start")
end)

test("climbing every platform in order reaches each checkpoint", function()
    for index, platform in ipairs(course.Platforms) do
        stand(platform.Offset, platform.Size.Y / 2)
        sim.advance(1)
        if index == 8 or index == 16 then
            expectEqual(lastEvent(), "checkpoint", "checkpoint at platform " .. index)
        end
    end
    expectEqual(sim.last(climber, "Parkour/State").Checkpoint, 3, "two checkpoints reached")
end)

test("falling to the deck returns the climber to the last checkpoint", function()
    stand(Vector3.new(0, 0, -45), 1)
    sim.advance(0.5)
    expectEqual(lastEvent(), "fell", "the fall was noticed")
    local back = sim.root(climber).Position - (center + course.Checkpoints[3].Offset)
    expectTrue(Vector3.new(back.X, 0, back.Z).Magnitude < 2, "back on checkpoint 2")
end)

test("reaching the summit finishes the run and saves the best time", function()
    stand(Vector3.new(0, course.SummitHeight, 0), 0)
    sim.advance(0.5)
    local finish = sim.last(climber, "Parkour/State")
    expectEqual(finish.Event, "finish", "the summit stops the clock")
    expectTrue(finish.Seconds >= course.MinSeconds, "the time is realistic")
    expectEqual(PlayerProgress.GetStat(climber, "ParkourBest_" .. course.Id), finish.Seconds, "best time is saved")
    expectTrue(PlayerProgress.HasCompleted(climber, "parkour", course.Id), "the tower counts as completed")
end)
