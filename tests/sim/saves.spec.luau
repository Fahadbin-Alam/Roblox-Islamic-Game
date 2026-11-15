-- Progress is saved when a player leaves and comes back the same, through the real
-- PlayerProgress and ProgressionService, with a DataStore that serializes like Roblox's.
local PlayerProgress = require(game:GetService("ServerScriptService").Modules.PlayerProgress)
local MonetizationConfig = require(game:GetService("ReplicatedStorage").Shared.Config.MonetizationConfig)

local USER = 9101
local KEY = "player_" .. USER

local function ledgerToday()
    local ledger = sim.stores[MonetizationConfig.LedgerStore]
    return ledger and ledger.Data[string.format("day_%d", math.floor(os.time() / 86400))] or {}
end

local before
local saved

test("a new player's progress is saved when they leave", function()
    local joinsBefore = ledgerToday().Joins or 0
    local player = sim.addPlayer(USER, "Hamza")
    sim.advance(0.5)
    expectTrue(PlayerProgress.IsSaveable(player), "the profile loaded from the DataStore and will be saved")
    expectEqual(ledgerToday().Joins, joinsBefore + 1, "the join is counted in the business ledger")

    PlayerProgress.AddXP(player, 150, "test")
    PlayerProgress.RecordCompletion(player, "seerah", "year_of_elephant", "The Year of the Elephant")
    PlayerProgress.RecordCompletion(player, "mystery", "bilal", "The Voice from the Rooftop")
    PlayerProgress.IncrementStat(player, "CoopFinishes", 2)
    PlayerProgress.SetStatMin(player, "ParkourBest_lobby_tower", 41.5)
    before = PlayerProgress.Get(player)
    local xp = before.XP

    sim.removePlayer(player)
    sim.advance(0.5)
    saved = sim.stores.PlayerProgress_v1.Data[KEY]
    expectTrue(saved ~= nil, "a save was written on leave")
    expectEqual(saved.XP, xp, "XP is saved")
    expectEqual(saved.Stats.CoopFinishes, 2, "stats are saved")
end)

test("the player gets the same progress back next time", function()
    sim.skipDays(1)
    local player = sim.addPlayer(USER, "Hamza")
    sim.advance(0.5)
    local profile = PlayerProgress.Get(player)
    expectTrue(profile.XP >= saved.XP, "XP came back (plus any daily visit reward)")
    expectTrue(PlayerProgress.HasCompleted(player, "seerah", "year_of_elephant"), "Seerah chapter came back")
    expectTrue(PlayerProgress.HasCompleted(player, "mystery", "bilal"), "mystery came back")
    expectEqual(PlayerProgress.GetStat(player, "CoopFinishes"), 2, "co-op count came back")
    expectEqual(PlayerProgress.GetStat(player, "ParkourBest_lobby_tower"), 41.5, "parkour best came back")
    expectEqual(ledgerToday().D1Returns, 1, "a next-day return counts as day-1 retention")
    sim.removePlayer(player)
    sim.advance(0.5)
end)

test("a DataStore outage never overwrites saved progress", function()
    local good = sim.serialize(sim.stores.PlayerProgress_v1.Data[KEY], KEY)
    sim.dataStoreDown = true
    local player = sim.addPlayer(USER, "Hamza")
    sim.advance(10)
    expectTrue(PlayerProgress.Get(player) ~= nil, "the player can still play")
    expectTrue(not PlayerProgress.IsSaveable(player), "the blank profile is marked not to save")
    local warned = false
    for _, toast in ipairs(sim.received(player, "Progress/ProgressToast")) do
        if type(toast) == "table" and string.find(tostring(toast.Title), "could not load") then
            warned = true
        end
    end
    expectTrue(warned, "the player is told progress will not save")
    sim.dataStoreDown = false
    PlayerProgress.AddXP(player, 5, "test")
    sim.removePlayer(player)
    sim.advance(0.5)
    expectEqual(sim.stores.PlayerProgress_v1.Data[KEY].XP, good.XP, "saved XP is untouched")
end)
