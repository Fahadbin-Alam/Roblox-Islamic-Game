-- Two players play a full sparring match through the real PvpArenaService and BattleLoadout:
-- join, three rounds of sword fighting, a ring-out, the match result, and a rematch.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TravelRoute = require(ReplicatedStorage.Shared.Data.TravelRoute)
local PlayerProgress = require(game:GetService("ServerScriptService").Modules.PlayerProgress)
local center = TravelRoute.GetDestinationById("training_grounds").Position - Vector3.new(0, 4, 0)

local amina = sim.addPlayer(9001, "Amina")
local yusuf = sim.addPlayer(9002, "Yusuf")
sim.advance(1)

local function state(player)
    return sim.last(player, "Pvp/State")
end

local function face(attacker, target, gap)
    local at = center + Vector3.new(-gap / 2, 6, 0)
    sim.place(attacker, at, at + Vector3.new(1, 0, 0))
    sim.place(target, at + Vector3.new(gap, 0, 0), at)
end

-- Swings until the target is down or `limit` swings are used. Returns the health after each hit.
local function fightUntilDown(attacker, target, limit)
    local trace = {}
    for _ = 1, limit do
        face(attacker, target, 6)
        sim.click(attacker, "Training Sword")
        sim.advance(0.5)
        table.insert(trace, sim.humanoid(target).Health)
        if sim.humanoid(target).Health <= 0 then
            break
        end
    end
    return trace
end

test("both players load a profile and can reach the Training Grounds", function()
    expectTrue(PlayerProgress.Get(amina) ~= nil, "Amina has a profile")
    expectTrue(PlayerProgress.Get(yusuf) ~= nil, "Yusuf has a profile")
    sim.fireServer(amina, "Pvp/Request", "Teleport")
    sim.fireServer(yusuf, "Pvp/Request", "Teleport")
    local offset = sim.root(amina).Position - center
    expectTrue(Vector3.new(offset.X, 0, offset.Z).Magnitude < 120, "Amina is at the arena")
end)

test("two players join and a round starts after the countdown", function()
    sim.fireServer(amina, "Pvp/Request", "Join")
    expectEqual(state(amina).InMatch, true, "Amina is in the match")
    expectEqual(state(amina).Phase, "Waiting", "one player waits")
    sim.fireServer(yusuf, "Pvp/Request", "Join")
    expectTrue(state(yusuf).CountdownEndsAt ~= nil, "a countdown starts with two players")
    sim.advance(5.5)
    expectEqual(state(amina).Phase, "Round", "round 1 is on")
    expectEqual(state(amina).Round, 1, "round number")
    for _, player in ipairs({ amina, yusuf }) do
        local character = player.Character
        expectTrue(character.Tags.BattleCombatant, player.Name .. " is a combatant")
        expectEqual(character:GetAttribute("BattleTeam"), "spar_" .. player.UserId, player.Name .. " fights for themself")
        expectTrue(player.Backpack:FindFirstChild("Training Sword") ~= nil, player.Name .. " has a sword")
        expectEqual(sim.humanoid(player).Health, 100, player.Name .. " starts at full health")
    end
end)

test("sword hits do the same server-side damage and a knockout ends the round", function()
    local trace = fightUntilDown(amina, yusuf, 6)
    expectEqual(trace[1], 68, "first hit does 32")
    expectEqual(trace[2], 36, "second hit does 32")
    expectEqual(trace[3], 4, "third hit does 32")
    expectEqual(trace[4], 0, "fourth hit knocks out")
    expectEqual(sim.humanoid(amina).Health, 100, "the attacker is untouched")
    local a, y = state(amina), state(yusuf)
    expectEqual(a.Phase, "Intermission", "round over")
    expectEqual(a.RoundWinner, amina.UserId, "Amina won the round")
    -- Both clients get the same result from the server.
    expectEqual(y.RoundWinner, a.RoundWinner, "both see the same winner")
    expectEqual(y.Round, a.Round, "both see the same round")
    expectEqual(amina.Character:GetAttribute("BattleTeam"), nil, "fighters are disarmed between rounds")
end)

test("a hit out of reach does nothing", function()
    sim.advance(6.5)
    expectEqual(state(amina).Phase, "Round", "round 2 is on")
    expectEqual(sim.humanoid(yusuf).Health, 100, "the knocked-out player is back at full health")
    face(amina, yusuf, 30)
    sim.click(amina, "Training Sword")
    sim.advance(0.5)
    expectEqual(sim.humanoid(yusuf).Health, 100, "30 studs is out of sword range")
end)

test("the other player can win a round, and leaving the ring is a knockout", function()
    local trace = fightUntilDown(yusuf, amina, 6)
    expectEqual(trace[#trace], 0, "Yusuf knocks Amina out")
    expectEqual(state(yusuf).RoundWinner, yusuf.UserId, "Yusuf won round 2")
    sim.advance(6.5)
    expectEqual(state(yusuf).Round, 3, "round 3 is on")
    -- Yusuf steps out of the ring.
    sim.place(yusuf, center + Vector3.new(80, 6, 0), center)
    sim.advance(1)
    expectEqual(sim.humanoid(yusuf).Health, 0, "ring-out knocks the player out")
    expectEqual(state(amina).RoundWinner, amina.UserId, "Amina wins round 3")
end)

test("first to three round wins takes the match and both see the result", function()
    sim.advance(6.5)
    fightUntilDown(amina, yusuf, 6)
    local a, y = state(amina), state(yusuf)
    expectEqual(a.Phase, "Over", "the match is over")
    expectEqual(a.MatchWinner, amina.UserId, "Amina won 3-1")
    expectEqual(y.MatchWinner, amina.UserId, "Yusuf sees the same winner")
    expectTrue(string.find(a.Banner or "", "Amina wins the match") ~= nil, "winner banner")
    expectEqual(PlayerProgress.GetStat(amina, "PvpMatchWins"), 1, "match win is saved to Amina's stats")
    expectEqual(PlayerProgress.GetStat(yusuf, "PvpMatches"), 1, "match played is counted for Yusuf")
end)

test("both players vote to play again and a fresh match starts", function()
    sim.fireServer(amina, "Pvp/Request", "Rematch")
    expectEqual(state(amina).Phase, "Over", "one vote is not enough")
    sim.fireServer(yusuf, "Pvp/Request", "Rematch")
    sim.advance(5.5)
    local a = state(amina)
    expectEqual(a.Phase, "Round", "the rematch round is on")
    expectEqual(a.Round, 1, "the rematch starts at round 1")
    for _, row in ipairs(a.Players) do
        expectEqual(row.Wins or 0, 0, "scores are reset")
    end
end)

test("a player who leaves mid-round hands the round to the other", function()
    sim.fireServer(yusuf, "Pvp/Request", "Leave")
    expectEqual(state(yusuf).InMatch, false, "Yusuf is out of the match")
    expectEqual(yusuf:GetAttribute("InBattle"), nil, "Yusuf is no longer marked in battle")
    expectTrue(state(amina).Phase ~= "Round", "the round ends when only one fighter is left")
end)

test("match results reach Roblox Analytics", function()
    expectTrue(#sim.analyticsFor(amina, "LogCustomEvent", "PvpMatchDone") >= 1, "a PvpMatchDone event was logged for Amina")
end)
