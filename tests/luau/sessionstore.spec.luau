local SessionStore = load("Server/SessionStore")

-- An in-memory DataStore. UpdateAsync copies values in and out the way the real one
-- serialises them, and `failures` makes the next N calls throw like a DataStore outage.
local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}

    for key, inner in pairs(value) do
        copy[key] = deepCopy(inner)
    end

    return copy
end

local function fakeStore()
    local store = { Data = {}, Calls = 0, Failures = 0 }

    function store:UpdateAsync(key, transform)
        self.Calls += 1

        if self.Failures > 0 then
            self.Failures -= 1
            error("502: DataStore request failed")
        end

        local result = transform(deepCopy(self.Data[key]))

        if result ~= nil then
            self.Data[key] = deepCopy(result)
        end

        return result
    end

    return store
end

local function makeServer(store, jobId, clock, onWait)
    local counter = 0

    return SessionStore.new(store, {
        JobId = jobId,
        Now = function()
            return clock.Now
        end,
        Wait = function(seconds)
            clock.Now += seconds
            clock.Waited += seconds

            if onWait then
                onWait(seconds)
            end
        end,
        NewId = function()
            counter += 1
            return string.format("%s-session-%d", jobId, counter)
        end,
    })
end

local function newClock()
    return { Now = 1000000, Waited = 0 }
end

test("a new player opens an empty session and the key is locked", function()
    local store = fakeStore()
    local server = makeServer(store, "server-a", newClock())
    local session, data = server:Open("player_1")

    assert(session ~= nil, "session opens")
    expectEqual(data, nil, "no saved data yet")
    expectEqual(store.Data.player_1.SessionLock.JobId, "server-a", "lock owner")
end)

test("saved data loads without the lock field, including records saved before locking", function()
    local store = fakeStore()
    store.Data.player_1 = { XP = 40 }
    local server = makeServer(store, "server-a", newClock())
    local _, data = server:Open("player_1")

    expectEqual(data.XP, 40, "keeps saved XP")
    expectEqual(data.SessionLock, nil, "lock is not handed to the caller")
end)

test("save keeps the lock and close releases it", function()
    local store = fakeStore()
    local server = makeServer(store, "server-a", newClock())
    local session = server:Open("player_1")

    expectEqual(session:Save({ XP = 10 }), true, "save succeeds")
    expectEqual(store.Data.player_1.XP, 10, "data written")
    assert(store.Data.player_1.SessionLock ~= nil, "still locked while playing")

    expectEqual(session:Close({ XP = 25 }), true, "close succeeds")
    expectEqual(store.Data.player_1.XP, 25, "final data written")
    expectEqual(store.Data.player_1.SessionLock, nil, "lock released")
    expectEqual(session:Save({ XP = 99 }), false, "no saves after close")
    expectEqual(store.Data.player_1.XP, 25, "closed session cannot write")
end)

test("a server hop waits for the old server's final save", function()
    local store = fakeStore()
    local clock = newClock()
    local serverA = makeServer(store, "server-a", clock)
    local sessionA = serverA:Open("player_1")
    sessionA:Save({ XP = 50 })

    -- Server A's final save lands while server B is waiting on the lock.
    local serverB = makeServer(store, "server-b", clock, function()
        if not sessionA.Closed then
            sessionA:Close({ XP = 80 })
        end
    end)

    local sessionB, data = serverB:Open("player_1")

    assert(sessionB ~= nil, "server B opens")
    expectEqual(data.XP, 80, "server B sees server A's final save, not the stale 50")
    expectEqual(store.Data.player_1.SessionLock.JobId, "server-b", "server B holds the lock")
end)

test("a lock that is never released is taken over, and the old server can no longer write", function()
    local store = fakeStore()
    local clock = newClock()
    local serverA = makeServer(store, "server-a", clock)
    local sessionA = serverA:Open("player_1")
    sessionA:Save({ XP = 50 })

    local serverB = makeServer(store, "server-b", clock)
    local sessionB, data = serverB:Open("player_1")

    assert(sessionB ~= nil, "server B takes over after waiting")
    assert(clock.Waited >= serverB.LockWaitAttempts * serverB.LockWaitSeconds, "it waited first")
    expectEqual(data.XP, 50, "server B starts from the last good save")

    sessionB:Save({ XP = 60 })
    expectEqual(sessionA:Save({ XP = 51 }), false, "stale server A is refused")
    expectEqual(sessionA.Lost, true, "server A knows it lost the lock")
    expectEqual(store.Data.player_1.XP, 60, "server B's data survives")
end)

test("a stale lock from a crashed server is taken over at once", function()
    local store = fakeStore()
    local clock = newClock()
    store.Data.player_1 = {
        XP = 30,
        SessionLock = { JobId = "crashed", SessionId = "old", LockedAt = clock.Now - 2 * 60 * 60 },
    }
    local server = makeServer(store, "server-b", clock)
    local session, data = server:Open("player_1")

    assert(session ~= nil, "opens")
    expectEqual(clock.Waited, 0, "no waiting on a stale lock")
    expectEqual(data.XP, 30, "keeps data")
end)

test("a lock left by this same server is reused without waiting", function()
    local store = fakeStore()
    local clock = newClock()
    store.Data.player_1 = { XP = 5, SessionLock = { JobId = "server-a", SessionId = "earlier", LockedAt = clock.Now } }
    local server = makeServer(store, "server-a", clock)
    local session = server:Open("player_1")

    assert(session ~= nil, "opens")
    expectEqual(clock.Waited, 0, "no waiting")
end)

test("failed DataStore calls are retried with exponential backoff", function()
    local store = fakeStore()
    local clock = newClock()
    local server = makeServer(store, "server-a", clock)
    local session = server:Open("player_1")

    store.Failures = 2
    expectEqual(session:Save({ XP = 7 }), true, "third attempt succeeds")
    expectEqual(store.Data.player_1.XP, 7, "data written")
    expectEqual(clock.Waited, 3, "waited 1s then 2s")
end)

test("an outage on load returns no session so nothing blank is ever saved", function()
    local store = fakeStore()
    store.Data.player_1 = { XP = 500 }
    store.Failures = 100
    local server = makeServer(store, "server-a", newClock())
    local session = server:Open("player_1")

    expectEqual(session, nil, "no session")
    expectEqual(store.Data.player_1.XP, 500, "real data untouched")
end)
