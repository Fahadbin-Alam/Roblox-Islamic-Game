--!strict

-- Records the real numbers behind the business goal: Robux revenue from purchases, rewarded ads
-- watched, joins, new players, and day-1 / day-7 returns. One DataStore row per UTC day, updated
-- with UpdateAsync so every server adds to the same totals. The creator can read the last two
-- weeks in game (Journeys > Support > Creator numbers); Creator Hub has the official figures.
--
-- Retention is measured from each profile's first-visit day (Stats.FirstDay).

local DataStoreService = game:GetService("DataStoreService")
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

local function add(fields: { [string]: number })
    if not storeOk or not store then
        return
    end

    task.spawn(function()
        local ok, err = pcall(function()
            (store :: DataStore):UpdateAsync(string.format("day_%d", today()), function(row)
                local data = if type(row) == "table" then row else {}

                for key, amount in pairs(fields) do
                    data[key] = (tonumber(data[key]) or 0) + amount
                end

                return data
            end)
        end)

        if not ok then
            warn("[BusinessMetrics] " .. tostring(err))
        end
    end)
end

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

-- The last `days` rows, newest first. Yields.
function BusinessMetrics.ReadRecent(days: number): { { Day: number, Data: { [string]: number } } }
    local rows = {}

    if not storeOk or not store then
        return rows
    end

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
