--!strict

-- Records the real numbers behind the business goal: Robux revenue from purchases, rewarded ads
-- watched, joins, new players, and day-1 / day-7 returns. One DataStore row per UTC day, updated
-- with UpdateAsync so every server adds to the same totals. The creator can read the last two
-- weeks in game (Journeys > Support > Creator numbers); Creator Hub has the official figures.
--
-- Counts are added up in memory and written once every FLUSH_SECONDS per server (and once at
-- shutdown), not on every join, leave and purchase. That keeps the shared daily key from
-- being hammered by every server and leaves the DataStore budget for player saves. A failed
-- write keeps its counts for the next flush.
--
-- Retention is measured from each profile's first-visit day (Stats.FirstDay).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.MonetizationConfig)
local Retention = require(ReplicatedStorage:WaitForChild("Shared").Modules.Retention)

local BusinessMetrics = {}

local storeOk, store = pcall(function()
    return DataStoreService:GetDataStore(MonetizationConfig.LedgerStore)
end)

local function today(): number
    return math.floor(os.time() / 86400)
end

-- Seconds between writes from one server. Each server writes its own totals at most this often.
local FLUSH_SECONDS = 90
-- Shutdown waits up to this long for leaving players' session minutes before the last write.
local SHUTDOWN_WAIT_SECONDS = 5

-- Counts not yet written, per UTC day.
local pending: { [number]: { [string]: number } } = {}

local function merge(day: number, fields: { [string]: number })
    local row = pending[day] or {}
    pending[day] = row

    for key, amount in pairs(fields) do
        row[key] = (row[key] or 0) + amount
    end
end

local function add(fields: { [string]: number })
    merge(today(), fields)
end

-- Writes every pending count with one UpdateAsync per day. Yields.
function BusinessMetrics.Flush()
    if not storeOk or not store then
        return
    end

    local batch = pending
    pending = {}

    for day, fields in pairs(batch) do
        local ok, err = pcall(function()
            (store :: DataStore):UpdateAsync(string.format("day_%d", day), function(row)
                local data = if type(row) == "table" then row else {}

                for key, amount in pairs(fields) do
                    data[key] = (tonumber(data[key]) or 0) + amount
                end

                return data
            end)
        end)

        if not ok then
            -- Keep the counts and try again at the next flush.
            merge(day, fields)
            warn("[BusinessMetrics] " .. tostring(err))
        end
    end
end

-- Pending counts for today, not yet written. Exposed for tests.
function BusinessMetrics.Pending(): { [string]: number }
    return pending[today()] or {}
end

task.spawn(function()
    while true do
        task.wait(FLUSH_SECONDS)
        BusinessMetrics.Flush()
    end
end)

game:BindToClose(function()
    -- PlayerRemoving (and its session minutes) still runs for everyone during shutdown.
    local deadline = os.clock() + SHUTDOWN_WAIT_SECONDS

    while #Players:GetPlayers() > 0 and os.clock() < deadline do
        task.wait(0.25)
    end

    BusinessMetrics.Flush()
end)

-- Pure: which retention counters a visit adds to. Exposed for tests.
BusinessMetrics.RetentionFields = Retention.Fields

-- Called once per join with the loaded profile's Stats table (it is updated in place).
function BusinessMetrics.RecordJoin(stats: { [string]: number })
    local day = today()
    add(BusinessMetrics.RetentionFields(stats.FirstDay, stats.LastJoinDay, day))
    stats.FirstDay = stats.FirstDay or day
    stats.LastJoinDay = day
end

function BusinessMetrics.RecordPurchase(robuxSpent: number, productKey: string)
    add({ RobuxSpent = math.max(0, robuxSpent), Purchases = 1, ["Product_" .. productKey] = 1 })
end

function BusinessMetrics.RecordAdReward()
    add({ AdRewards = 1 })
end

function BusinessMetrics.RecordSessionMinutes(minutes: number)
    add({ SessionMinutes = math.floor(minutes), Sessions = 1 })
end

-- The last `days` rows, newest first. Writes this server's pending counts first, so they show.
-- Yields.
function BusinessMetrics.ReadRecent(days: number): { { Day: number, Data: { [string]: number } } }
    local rows = {}

    if not storeOk or not store then
        return rows
    end

    BusinessMetrics.Flush()

    for offset = 0, days - 1 do
        local day = today() - offset
        local ok, data = pcall(function()
            return (store :: DataStore):GetAsync(string.format("day_%d", day))
        end)

        table.insert(rows, { Day = day, Data = if ok and type(data) == "table" then data else {} })
    end

    return rows
end

return BusinessMetrics
