-- Two players clear the Trials of Brotherhood through the real CoopTrialsService, and one
-- player alone cannot get through the first gate.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TravelRoute = require(ReplicatedStorage.Shared.Data.TravelRoute)
local PlayerProgress = require(game:GetService("ServerScriptService").Modules.PlayerProgress)

local CENTER = TravelRoute.GetDestinationById("coop_trials").Position - Vector3.new(0, 4, 0)
local G, LEDGE = 4, 20
local course = Workspace:WaitForChild("CoopTrials")
local gate = course:WaitForChild("Gate")
local lift = course:WaitForChild("Lift")
local stairs = course:WaitForChild("Stairway")

local helper = sim.addPlayer(9301, "Ali")
local emigrant = sim.addPlayer(9302, "Bilal")
sim.advance(0.5)

local function stand(player, offset)
    local at = CENTER + offset + Vector3.new(0, 3, 0)
    sim.place(player, at, at + Vector3.new(0, 0, 1))
end

local PLATE_A = Vector3.new(-28, G, -62)
local PLATE_B = Vector3.new(-28, G, -24)
local COUNTERWEIGHT = Vector3.new(6, G, -12)
local PLATE_C = Vector3.new(0, G + LEDGE, 24)
local START = Vector3.new(0, G, -110)

test("the gate is shut while nobody holds a plate", function()
    stand(helper, START)
    stand(emigrant, START + Vector3.new(4, 0, 0))
    sim.advance(0.3)
    expectEqual(gate.CanCollide, true, "gate starts shut")
end)

test("one player alone cannot keep the gate open behind them", function()
    stand(helper, PLATE_A)
    sim.advance(0.3)
    expectEqual(gate.CanCollide, false, "standing on plate A opens the gate")
    stand(helper, Vector3.new(0, G, -44))
    sim.advance(0.3)
    expectEqual(gate.CanCollide, true, "stepping off the plate shuts it before they reach it")
end)

test("one holds the gate, the other goes through and holds it back", function()
    stand(helper, PLATE_A)
    sim.advance(0.3)
    expectEqual(gate.CanCollide, false, "Ali holds the gate open")
    stand(emigrant, PLATE_B)
    sim.advance(0.3)
    stand(helper, Vector3.new(0, G, -30))
    sim.advance(0.3)
    expectEqual(gate.CanCollide, false, "Bilal on plate B keeps it open for Ali")
    local lastState = sim.last(helper, "Coop/State")
    expectEqual(lastState and lastState.GateOpen, true, "players in the course are told the gate is open")
end)

test("the counterweight lifts the partner and the ledge plate lowers the stairs", function()
    stand(emigrant, Vector3.new(-24, G + 1, 4))
    stand(helper, COUNTERWEIGHT)
    sim.advance(0.3)
    expectTrue(lift.Position.Y > CENTER.Y + G + LEDGE - 1, "the lift is at the ledge")
    stand(emigrant, PLATE_C)
    sim.advance(0.3)
    expectEqual(stairs.CanCollide, true, "the stairway is solid while the plate is held")
    expectEqual(stairs.Transparency, 0, "and visible")
    stand(helper, Vector3.new(14, G + LEDGE, 40))
    stand(emigrant, Vector3.new(-6, G + LEDGE, 40))
    sim.advance(0.3)
    expectEqual(stairs.CanCollide, false, "stepping off hides the stairway again")
end)

test("a single player on both pads does not count", function()
    stand(helper, Vector3.new(-14, G + LEDGE, 104))
    sim.advance(0.3)
    expectTrue(not PlayerProgress.HasCompleted(helper, "coop", "brotherhood_trials"), "one pad is not a finish")
end)

test("two players on the twin pads finish together and both get credit", function()
    stand(emigrant, Vector3.new(14, G + LEDGE, 104))
    sim.advance(0.3)
    for _, player in ipairs({ helper, emigrant }) do
        expectTrue(PlayerProgress.HasCompleted(player, "coop", "brotherhood_trials"), player.Name .. " finished the trial")
        expectEqual(PlayerProgress.GetStat(player, "CoopFinishes"), 1, player.Name .. " has one co-op finish")
        local finish = false
        for _, payload in ipairs(sim.received(player, "Coop/State")) do
            if payload.Event == "finish" and payload.Players == 2 then
                finish = true
            end
        end
        expectTrue(finish, player.Name .. " saw the finish")
    end
    sim.advance(30)
    expectEqual(PlayerProgress.GetStat(helper, "CoopFinishes"), 1, "standing on the pads for 30 seconds does not farm finishes")
    stand(helper, Vector3.new(0, G + LEDGE, 90))
    stand(emigrant, Vector3.new(4, G + LEDGE, 90))
    sim.advance(1)
end)
