-- Runs after BattleArenaBuilder has built both arenas into the mock workspace.
local BattleMissions = require(game:GetService("ReplicatedStorage").Shared.Data.BattleMissions)
local BattleScenarios = require(game:GetService("ReplicatedStorage").Shared.Data.BattleScenarios)

local arenas = game:GetService("Workspace"):FindFirstChild("GeneratedBattles")
assert(arenas, "BattleArenaBuilder did not create GeneratedBattles")
Geometry.Build(arenas)

local passed, failed = 0, 0

local function check(name, ok, detail)
    if ok then
        passed += 1
    else
        failed += 1
        print("FAIL " .. name .. (detail and ("\n    " .. detail) or ""))
    end
end

local function describe(v)
    return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
end

-- Same rule the server uses: drop the point onto the highest surface under it.
local function drop(point)
    local y = Geometry.TopSurface(point.X, point.Z)
    return y and Vector3.new(point.X, y, point.Z) or nil
end

local function checkStandable(label, point)
    local ground = drop(point)
    check(label .. " has ground", ground ~= nil, describe(point))

    if ground then
        check(label .. " is at a sensible height", ground.Y > -1 and ground.Y < 80, "ground at " .. describe(ground))
        check(label .. " has room to stand", not Geometry.IsBlockedAt(ground + Vector3.new(0, 3, 0)), describe(ground))
    end

    return ground
end

local function checkWalk(label, from, to)
    local start = drop(from)

    if not start then
        check(label, false, "no ground at " .. describe(from))
        return
    end

    local ok, stuckAt, why = Geometry.Walk(from, to, start.Y)
    check(label, ok, ok and nil or string.format("%s at %s", tostring(why), describe(stuckAt)))
end

for _, missionId in ipairs(BattleMissions.Order) do
    local mission = BattleMissions.Get(missionId)
    local layout = mission.Layout
    check(missionId .. " arena exists", arenas:FindFirstChild(missionId) ~= nil)

    for name, point in pairs(layout.Points) do
        checkStandable(string.format("%s point %s", missionId, name), point)
    end

    for laneName, lane in pairs(layout.Lanes) do
        checkStandable(string.format("%s lane %s spawn", missionId, laneName), lane[1])

        for index = 1, #lane - 1 do
            checkWalk(string.format("%s lane %s leg %d walkable", missionId, laneName, index), lane[index], lane[index + 1])
        end
    end

    for _, route in ipairs(layout.Routes) do
        checkWalk(string.format("%s route %s -> %s walkable", missionId, route.From, route.To), layout.Points[route.From], layout.Points[route.To])
    end

    for _, objective in ipairs(mission.Objectives) do
        if objective.Zone then
            check(string.format("%s objective %s zone exists", missionId, objective.Id), layout.Points[objective.Zone] ~= nil, objective.Zone)
        end
        if objective.Target then
            check(string.format("%s objective %s target exists", missionId, objective.Id), layout.Points[objective.Target] ~= nil, objective.Target)
        end
        if objective.AllyPoint then
            check(string.format("%s objective %s ally point exists", missionId, objective.Id), layout.Points[objective.AllyPoint] ~= nil, objective.AllyPoint)
        end
        for _, wave in ipairs(objective.Waves or {}) do
            for _, spawn in ipairs(wave.Spawns) do
                check(string.format("%s objective %s lane %s exists", missionId, objective.Id, spawn.Lane), layout.Lanes[spawn.Lane] ~= nil)
                check(string.format("%s objective %s unit %s exists", missionId, objective.Id, spawn.Unit), BattleMissions.Units[spawn.Unit] ~= nil)
            end
        end
    end
end

-- The Uhud hill and mountain path must actually lift players off the field.
local uhud = BattleMissions.Get("uhud").Layout.Points
local hillTop = drop(uhud.HillTop)
check("Archers' Hill top is raised", hillTop ~= nil and hillTop.Y > 12, hillTop and describe(hillTop) or "no ground")
local rally = drop(uhud.Rally)
check("Uhud rally point is up the mountain", rally ~= nil and rally.Y > 25, rally and describe(rally) or "no ground")

-- Team skirmish spawns: characters are placed 6 studs above the configured position.
for _, scenario in ipairs(BattleScenarios) do
    for teamId, positions in pairs(scenario.SpawnPositions) do
        for index, position in ipairs(positions) do
            local label = string.format("%s skirmish spawn %s %d", scenario.Id, teamId, index)
            local placed = position + Vector3.new(0, 6, 0)
            check(label .. " is not inside rock", not Geometry.IsBlockedAt(placed), describe(placed))
            local ground = Geometry.GroundBelow(position.X, position.Z, placed.Y)
            check(label .. " lands on ground close below", ground ~= nil and placed.Y - ground < 16, ground and ("ground " .. ground) or "none")
        end
    end
end

print(string.format("%d passed, %d failed", passed, failed))

if failed > 0 then
    error("world checks failed")
end
