--!strict

-- The land around every play area: a sand floor under the whole map, rolling dunes that rise
-- gently from the edge of each area, and rocky mountain ranges further out and between the
-- areas. It is Roblox Terrain, so it costs no parts and smooths itself, and the mountains
-- hide the present-day hub, the historical towns and the activity zones from each other.
--
-- Rule kept by tests/hub/zones.luau: no terrain built here rises above the floor anywhere
-- inside a play area.

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Decor = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Decor"))

local terrain = Workspace.Terrain

-- Yield now and then while building on a live server (the test engine cannot yield here).
local okRunning, running = pcall(function()
    return game:GetService("RunService"):IsRunning()
end)
local canYield = okRunning and running == true

-- Play areas: x/z extent and the height of their floor. Terrain stays below the floor inside
-- each one. (Hub ground, the two battle arenas, historical Makkah and Madinah, the mystery
-- wing, the co-op course and the Training Grounds desert.)
type Area = { MinX: number, MaxX: number, MinZ: number, MaxZ: number, Top: number }

local AREAS: { Area } = {
    { MinX = -1300, MaxX = 1300, MinZ = -1580, MaxZ = 2260, Top = 0 },
    { MinX = -1600, MaxX = -700, MinZ = 470, MaxZ = 1470, Top = 0 },
    { MinX = 3350, MaxX = 4650, MinZ = -650, MaxZ = 650, Top = 4 },
    { MinX = 3350, MaxX = 4650, MinZ = 1250, MaxZ = 2550, Top = 4 },
    { MinX = -4700, MaxX = -3300, MinZ = -260, MaxZ = 340, Top = 3.9 },
    { MinX = -4150, MaxX = -3850, MinZ = 1400, MaxZ = 1800, Top = 3.8 },
    { MinX = 3400, MaxX = 4600, MinZ = -2500, MaxZ = -1300, Top = 3.9 },
}

local BASE_TOP = -0.5
local MIN_X, MAX_X, MIN_Z, MAX_Z = -6200, 6200, -3800, 4400

-- Horizontal distance from a point to an area (0 inside it).
local function distanceTo(area: Area, x: number, z: number): number
    local dx = math.max(area.MinX - x, 0, x - area.MaxX)
    local dz = math.max(area.MinZ - z, 0, z - area.MaxZ)

    return math.sqrt(dx * dx + dz * dz)
end

local function nearest(x: number, z: number): number
    local best = math.huge

    for _, area in ipairs(AREAS) do
        best = math.min(best, distanceTo(area, x, z))
    end

    return best
end

-- True when a terrain ball stays at or below the floor inside every play area.
local function fits(center: Vector3, radius: number): boolean
    for _, area in ipairs(AREAS) do
        local d = distanceTo(area, center.X, center.Z)

        if d < radius and center.Y + math.sqrt(radius * radius - d * d) > area.Top then
            return false
        end
    end

    return true
end

local fills = 0

local function ball(center: Vector3, radius: number, material: Enum.Material)
    terrain:FillBall(center, radius, material)
    fills += 1

    -- Let the server breathe while the land is built.
    if canYield and fills % 250 == 0 then
        task.wait()
    end
end

-- A dune `height` studs tall: a long, low crescent of overlapping balls lying across the wind,
-- highest in the middle and tapering at both horns. Shrinks (or is skipped) where it would reach
-- into a play area.
local function dune(x: number, z: number, height: number, length: number, r: (number?, number?) -> number)
    local radius = math.max(height * 3, length * 0.3)
    local turn = r(-0.5, 0.5)
    local along = Vector3.new(math.cos(turn) * 0.8 - math.sin(turn) * 0.6, 0, -(math.sin(turn) * 0.8 + math.cos(turn) * 0.6))
    local across = Vector3.new(-along.Z, 0, along.X)

    for step = -2, 2 do
        local taper = if step == 0 then 1 elseif math.abs(step) == 1 then r(0.7, 0.85) else r(0.4, 0.55)
        local h = height * taper
        local rr = radius * (1 - math.abs(step) * 0.14)
        -- The horns sweep downwind, which gives the ridge its crescent shape.
        local offset = along * (step * length * 0.22) + across * (step * step * length * 0.05)
        local center = Vector3.new(x + offset.X, BASE_TOP + h - rr, z + offset.Z)

        -- Lower the ball until it fits; give up if it would vanish.
        local tries = 0
        while not fits(center, rr) and tries < 6 do
            h *= 0.6
            center = Vector3.new(center.X, BASE_TOP + h - rr, center.Z)
            tries += 1
        end

        if h > 1.5 and fits(center, rr) then
            ball(center, rr, Enum.Material.Sand)
        end
    end
end

-- A rocky mountain: a broad sandstone foot, a rock body and a few crags on top.
local function mountain(x: number, z: number, height: number, r: (number?, number?) -> number)
    local footRadius = height * 1.5
    local foot = Vector3.new(x, BASE_TOP + height * 0.35 - footRadius, z)

    if not fits(foot, footRadius) then
        return
    end

    ball(foot, footRadius, Enum.Material.Sandstone)

    local bodyRadius = height * 0.85
    local body = Vector3.new(x + r(-20, 20), BASE_TOP + height - bodyRadius, z + r(-20, 20))
    if fits(body, bodyRadius) then
        ball(body, bodyRadius, Enum.Material.Rock)
    end

    for index = 1, 3 do
        local a = r(0, math.pi * 2)
        local spread = height * r(0.35, 0.7)
        local cragRadius = height * r(0.3, 0.5)
        local crag = Vector3.new(x + math.cos(a) * spread, BASE_TOP + height * r(0.55, 0.85) - cragRadius * 0.4, z + math.sin(a) * spread)
        if fits(crag, cragRadius) then
            ball(crag, cragRadius, if index == 3 then Enum.Material.Sandstone else Enum.Material.Rock)
        end
    end
end

-- Sand floor under the whole map, just below every play area's floor.
terrain:FillBlock(CFrame.new((MIN_X + MAX_X) / 2, BASE_TOP - 8, (MIN_Z + MAX_Z) / 2), Vector3.new(MAX_X - MIN_X, 16, MAX_Z - MIN_Z), Enum.Material.Sand)
fills += 1

pcall(function()
    terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(222, 192, 140))
    terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(196, 158, 112))
    terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(132, 110, 92))
end)

-- Oases in the dunes (built at the end), in sight of the play areas: a pool of still water ringed with grass, date
-- palms and shrubs. Each sits well clear of every play area and its edge ramp.
local OASES = {
    { 1520, 120 }, { -1520, -820 }, -- hub
    { 3180, 40 }, { 4060, 950 }, { 4860, 1880 }, -- historical Makkah and Madinah
    { 4830, -1920 }, -- PvP
    { -4020, -520 }, { -3690, 1620 }, { -3990, 920 }, -- mystery wing and co-op
}
local POOL = 34

-- True when a point is close enough to an oasis that a dune or mountain there would bury it.
local function nearOasis(x: number, z: number): boolean
    for _, spot in ipairs(OASES) do
        if (spot[1] - x) ^ 2 + (spot[2] - z) ^ 2 < 170 * 170 then
            return true
        end
    end

    return false
end

local r = Decor.Rng(1447)
local CELL = 180

for gx = MIN_X + CELL / 2, MAX_X - CELL / 2, CELL do
    for gz = MIN_Z + CELL / 2, MAX_Z - CELL / 2, CELL do
        local x = gx + r(-CELL * 0.35, CELL * 0.35)
        local z = gz + r(-CELL * 0.35, CELL * 0.35)
        local d = nearest(x, z)
        local roll = r()

        -- Beyond about 1,900 studs the haze hides the land, so nothing is built there.
        if d > 30 and d < 1900 and not nearOasis(x, z) then
            if d > 650 and roll < 0.42 then
                -- Mountains further out: taller the further from the play areas.
                mountain(x, z, math.min(70 + (d - 650) * 0.22, 260) * r(0.7, 1.15), r)
            elseif roll < 0.85 then
                -- Dunes: low near the play areas, bigger further out.
                local height = math.clamp(6 + d * 0.05, 6, 42) * r(0.6, 1.2)
                dune(x, z, height, r(90, 170), r)
            end
        end
    end
end

-- A smooth sand ramp along every raised play area's edge, so its floor meets the sand without a
-- step: one wedge per side, falling away from the edge, and a wide low dome at each corner.
local RAMP = 60

for _, area in ipairs(AREAS) do
    local height = area.Top - BASE_TOP

    if height >= 1 then
        local midY = BASE_TOP + height / 2
        local width = area.MaxX - area.MinX
        local depth = area.MaxZ - area.MinZ
        local cx, cz = (area.MinX + area.MaxX) / 2, (area.MinZ + area.MaxZ) / 2

        -- A wedge's tall face is at its local +Z, so each one is turned to face the area.
        local sides = {
            { CFrame.new(cx, midY, area.MinZ - RAMP / 2), width },
            { CFrame.new(cx, midY, area.MaxZ + RAMP / 2) * CFrame.Angles(0, math.pi, 0), width },
            { CFrame.new(area.MinX - RAMP / 2, midY, cz) * CFrame.Angles(0, math.pi / 2, 0), depth },
            { CFrame.new(area.MaxX + RAMP / 2, midY, cz) * CFrame.Angles(0, -math.pi / 2, 0), depth },
        }

        for _, side in ipairs(sides) do
            terrain:FillWedge(side[1], Vector3.new(side[2], height, RAMP), Enum.Material.Sand)
            fills += 1
        end

        -- A ball whose top touches the floor height at the corner and meets the sand RAMP studs out.
        local radius = (RAMP * RAMP + height * height) / (2 * height)
        for _, corner in ipairs({ { area.MinX, area.MinZ }, { area.MinX, area.MaxZ }, { area.MaxX, area.MinZ }, { area.MaxX, area.MaxZ } }) do
            local center = Vector3.new(corner[1], area.Top - radius, corner[2])
            if fits(center, radius) then
                ball(center, radius, Enum.Material.Sand)
            end
        end
    end
end

local scenery = Instance.new("Folder")
scenery.Name = "WorldScenery"
scenery.Parent = Workspace
local oasisCount = 0

for index, spot in ipairs(OASES) do
    local x, z = spot[1], spot[2]

    if nearest(x, z) > POOL + 40 + RAMP then
        oasisCount += 1
        local o = Decor.Rng(900 + index)
        local folder = Instance.new("Folder")
        folder.Name = "Oasis" .. index
        folder.Parent = scenery

        -- The grid leaves the ground here flat. Lay a grass ring a little proud of the sand, then
        -- sink the pool into it: clear the top, fill the basin with water.
        terrain:FillCylinder(CFrame.new(x, BASE_TOP - 0.9, z), 2.2, POOL + 18, Enum.Material.LeafyGrass)
        terrain:FillCylinder(CFrame.new(x, BASE_TOP + 2, z), 6, POOL, Enum.Material.Air)
        terrain:FillCylinder(CFrame.new(x, BASE_TOP - 2.6, z), 4, POOL, Enum.Material.Water)
        fills += 3

        for palm = 1, 8 do
            local a = (palm / 8) * math.pi * 2 + o(-0.25, 0.25)
            local out = POOL + o(4, 14)
            Decor.Palm(folder, "Palm" .. palm, Vector3.new(x + math.cos(a) * out, BASE_TOP, z + math.sin(a) * out), o(16, 26), index * 40 + palm, true)
        end

        for shrub = 1, 5 do
            local a = o(0, math.pi * 2)
            local out = POOL + o(6, 17)
            Decor.Shrub(folder, "Shrub" .. shrub, Vector3.new(x + math.cos(a) * out, BASE_TOP, z + math.sin(a) * out), index * 50 + shrub)
        end
    end
end

Workspace:SetAttribute("WorldOases", oasisCount)
Workspace:SetAttribute("WorldTerrainFills", fills)
