--!strict

-- Pure retention bookkeeping, kept apart from the DataStore code so it can be unit tested.
-- Days are whole UTC days (os.time() // 86400). A player counts as returning when they join
-- on a different day from their last join; D1/D7/D30 count returns exactly that many days
-- after their first visit.

local Retention = {}

function Retention.Fields(firstDay: number?, lastDay: number?, day: number): { [string]: number }
    local fields: { [string]: number } = { Joins = 1 }

    if firstDay == nil then
        fields.NewPlayers = 1
        return fields
    end

    if lastDay ~= day then
        fields.ReturningPlayers = 1

        if day - firstDay == 1 then
            fields.D1Returns = 1
        elseif day - firstDay == 7 then
            fields.D7Returns = 1
        elseif day - firstDay == 30 then
            fields.D30Returns = 1
        end
    end

    return fields
end

return Retention
