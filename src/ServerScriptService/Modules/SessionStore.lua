--!strict

-- Session-locked saves on top of a DataStore, shared by PlayerProgress and ShopService.
--
-- The problem it solves: when a player leaves server A and joins server B, B can read the
-- player's key before A's final save lands, and A's late write then overwrites whatever B
-- saves (or B overwrites A). Either way progress or a paid purchase is lost.
--
-- How it works:
--   * Every read and write goes through UpdateAsync, so each one sees the current record.
--   * Open() stamps the record with a SessionLock { JobId, SessionId, LockedAt }. If another
--     server holds a fresh lock, Open() waits for it to be released, then takes it over.
--     A lock older than LockTimeout (a crashed server) is taken over at once.
--   * Save() only writes while the record still carries this session's SessionId. If another
--     server took the lock, the write is cancelled and the session is marked Lost, so a
--     stale server can never overwrite newer data.
--   * Close() does a final save and clears the lock.
--   * Every DataStore call is wrapped in pcall and retried with exponential backoff.
--
-- The module never touches Roblox services itself (the caller passes the store, JobId, clock
-- and wait function), so the locking rules are unit tested outside Studio in
-- tests/luau/sessionstore.spec.luau.

export type Options = {
    JobId: string,
    -- Seconds since the epoch, os.time in production.
    Now: () -> number,
    -- Yields for the given seconds, task.wait in production.
    Wait: (seconds: number) -> (),
    -- Makes a unique id per session, HttpService:GenerateGUID in production.
    NewId: () -> string,
    -- Attempts per DataStore call before giving up.
    Attempts: number?,
    -- First retry delay in seconds; doubles each attempt.
    RetryDelay: number?,
    -- A lock not refreshed for this many seconds belongs to a server that is gone.
    LockTimeout: number?,
    -- How many times Open() waits on another server's live lock before taking it over.
    LockWaitAttempts: number?,
    LockWaitSeconds: number?,
    Log: ((message: string) -> ())?,
}

type StoreLike = {
    UpdateAsync: (self: any, key: string, transform: (old: any) -> ...any) -> ...any,
}

local SessionStore = {}
SessionStore.__index = SessionStore

local Session = {}
Session.__index = Session

SessionStore.LockField = "SessionLock"

local function shallowCopy(source: { [any]: any }): { [any]: any }
    local copy = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

function SessionStore.new(store: StoreLike, options: Options)
    local self = setmetatable({}, SessionStore) :: any
    self.Store = store
    self.JobId = options.JobId
    self.Now = options.Now
    self.Wait = options.Wait
    self.NewId = options.NewId
    self.Attempts = options.Attempts or 4
    self.RetryDelay = options.RetryDelay or 1
    self.LockTimeout = options.LockTimeout or 30 * 60
    self.LockWaitAttempts = options.LockWaitAttempts or 5
    self.LockWaitSeconds = options.LockWaitSeconds or 5
    self.Log = options.Log or function(_message: string) end
    -- Keys whose session in this server is still closing. A player who rejoins the same
    -- server waits for that final save instead of reading data that is about to change.
    self.Closing = {} :: { [string]: boolean }

    return self
end

-- Runs a DataStore call in pcall, retrying with exponential backoff (1s, 2s, 4s, ...).
function SessionStore.Retry(self: any, label: string, call: () -> ()): (boolean, string?)
    local delay: number = self.RetryDelay
    local lastError: string? = nil

    for attempt = 1, self.Attempts do
        local ok, err = pcall(call :: any)

        if ok then
            return true, nil
        end

        local message = tostring(err)
        lastError = message
        self.Log(string.format("%s failed (attempt %d of %d): %s", label, attempt, self.Attempts, message))

        if attempt < self.Attempts then
            self.Wait(delay)
            delay *= 2
        end
    end

    return false, lastError
end

function SessionStore.IsHeldElsewhere(self: any, lock: any, now: number): boolean
    if type(lock) ~= "table" then
        return false
    end

    -- A lock left by this same server (for example a Studio session that stopped without
    -- closing) is ours to take.
    if lock.JobId == self.JobId then
        return false
    end

    return type(lock.LockedAt) == "number" and now - lock.LockedAt < self.LockTimeout
end

-- Locks the key for this server and returns (session, data). `data` is the saved table
-- without the lock field, or nil for a new player. Returns nil when the DataStore could not
-- be read; the caller must then treat the player's data as unsaveable for this visit.
function SessionStore.Open(self: any, key: string, userIds: { number }?): (any, any)
    local waited = 0

    while self.Closing[key] and waited < self.LockWaitAttempts * self.LockWaitSeconds do
        self.Wait(0.25)
        waited += 0.25
    end

    local sessionId = self.NewId()

    for lockAttempt = 0, self.LockWaitAttempts do
        local verdict = "locked"
        local loaded: any = nil
        local mayTakeOver = lockAttempt >= self.LockWaitAttempts

        local ok, err = self:Retry(string.format("Open %s", key), function()
            self.Store:UpdateAsync(key, function(old: any): (any, any)
                local now = self.Now()
                local lock = if type(old) == "table" then old[SessionStore.LockField] else nil

                if self:IsHeldElsewhere(lock, now) and not mayTakeOver then
                    verdict = "locked"
                    return nil
                end

                verdict = if self:IsHeldElsewhere(lock, now) then "taken" else "acquired"

                local record = if type(old) == "table" then shallowCopy(old) else {}
                record[SessionStore.LockField] = nil
                loaded = if type(old) == "table" then shallowCopy(record) else nil
                record[SessionStore.LockField] = {
                    JobId = self.JobId,
                    SessionId = sessionId,
                    LockedAt = now,
                }

                return record, userIds
            end)
        end)

        if not ok then
            self.Log(string.format("Could not open %s: %s", key, tostring(err)))
            return nil, nil
        end

        if verdict ~= "locked" then
            if verdict == "taken" then
                self.Log(string.format("Took over the session lock on %s from a server that did not release it", key))
            end

            local session = setmetatable({
                Owner = self,
                Key = key,
                SessionId = sessionId,
                UserIds = userIds,
                Lost = false,
                Closed = false,
                Busy = false,
                LastSavedAt = self.Now(),
            }, Session)

            return session, loaded
        end

        self.Wait(self.LockWaitSeconds)
    end

    return nil, nil
end

-- Writes `data` if this session still owns the lock. Saves of one session never overlap,
-- so an older snapshot can never land after a newer one. Returns true when the data is
-- stored, false when the write failed or the lock was lost (check session.Lost).
function Session.Save(self: any, data: { [any]: any }, release: boolean?): boolean
    local owner = self.Owner

    if self.Lost or self.Closed then
        return false
    end

    while self.Busy do
        owner.Wait(0.05)
    end

    if self.Lost or self.Closed then
        return false
    end

    self.Busy = true
    local record = shallowCopy(data)
    local lostLock = false

    local ok = owner:Retry(string.format("Save %s", self.Key), function()
        owner.Store:UpdateAsync(self.Key, function(old: any): (any, any)
            local lock = if type(old) == "table" then old[SessionStore.LockField] else nil

            if type(lock) ~= "table" or lock.SessionId ~= self.SessionId then
                lostLock = true
                return nil
            end

            lostLock = false
            record[SessionStore.LockField] = if release
                then nil
                else {
                    JobId = owner.JobId,
                    SessionId = self.SessionId,
                    LockedAt = owner.Now(),
                }

            return record, self.UserIds
        end)
    end)

    self.Busy = false

    if lostLock then
        self.Lost = true
        owner.Log(string.format("Session lock on %s was taken by another server; this server will not save it again", self.Key))
        return false
    end

    if ok then
        self.LastSavedAt = owner.Now()
    end

    return ok
end

-- Final save that also releases the lock. Safe to call more than once.
function Session.Close(self: any, data: { [any]: any }): boolean
    local owner = self.Owner

    if self.Closed then
        return true
    end

    owner.Closing[self.Key] = true
    local saved = self:Save(data, true)
    self.Closed = true
    owner.Closing[self.Key] = nil

    return saved
end

return SessionStore
