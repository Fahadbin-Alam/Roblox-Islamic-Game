--!strict

-- Builds the two historical zones of the Seerah campaign: Makkah c. 570-630 CE and Madinah
-- c. 622-632 CE (see Shared/Data/HistoricalSites). They are deliberately plain: mud brick,
-- palm wood, tents, and bare hills, so they never look like the present-day hub with its
-- marble mosque. Every sign says "Historical reconstruction".
--
-- Each town is filled with lanes of flat-roofed mud-brick houses (Modules/Decor), with palm
-- groves, wells, camels and market stalls. Houses never stand on a site, an arrival point, a
-- travel point or a campaign item: the clearings below keep those open, and tests/hub/zones
-- checks that every arrival point and item can be reached.
--
-- No figure in these zones stands for the Prophet ﷺ or any named companion. Townspeople, where
-- used, are generic and have blank faces.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HistoricalSites = require(Shared.Data.HistoricalSites)
local SeerahCampaign = require(Shared.Data.SeerahCampaign)
local CampaignRules = require(Shared.Modules.CampaignRules)
local BuildUtils = require(script.Parent.Modules.BuildUtils)
local Figures = require(script.Parent.Modules.Figures)
local Decor = require(script.Parent.Modules.Decor)

local GROUND_TOP = HistoricalSites.GroundTop
local SAND = Color3.fromRGB(205, 178, 132)
local MUD = Color3.fromRGB(176, 136, 96)
local MUD_DARK = Color3.fromRGB(143, 106, 72)
local PALM_WOOD = Color3.fromRGB(112, 84, 56)
local FROND = Color3.fromRGB(104, 128, 72)
local ROCK = Color3.fromRGB(128, 104, 82)
local CLOTH = { Color3.fromRGB(150, 62, 48), Color3.fromRGB(64, 92, 120), Color3.fromRGB(196, 168, 112), Color3.fromRGB(92, 116, 74) }

local existing = Workspace:FindFirstChild(HistoricalSites.FolderName)

if existing then
    existing:Destroy()
end

local root = BuildUtils.CreateFolder(Workspace, HistoricalSites.FolderName)

local function sign(parent: Instance, name: string, position: Vector3, title: string, body: string, yaw: number)
    local board = BuildUtils.CreateBoardSign(parent, name, position, title, body, Color3.fromRGB(122, 92, 58), nil)
    board.Orientation = Vector3.new(0, yaw, 0)
end

local function mudHouse(parent: Instance, name: string, position: Vector3, size: Vector3, yaw: number, options: Decor.HouseOptions?)
    local base = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
    Decor.MudHouse(parent, name, base, size.X, size.Z, size.Y, position.X * 0.37 + position.Z * 0.11, options)
end

local function palm(parent: Instance, name: string, position: Vector3)
    -- `position` is on the ground surface.
    local seed = position.X * 0.13 + position.Z * 0.29
    Decor.Palm(parent, name, position, 16 + (math.abs(seed * 7.3) % 9), seed)
end

local function tent(parent: Instance, name: string, position: Vector3, yaw: number, _color: Color3)
    Decor.Tent(parent, name, CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0), 18, position.X * 0.21 + position.Z * 0.17)
end

local function rockMass(parent: Instance, name: string, position: Vector3, size: Vector3, yaw: number)
    local frame = CFrame.new(position + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, math.rad(yaw), 0)
    BuildUtils.CreatePart(parent, name, size, frame, ROCK, Enum.Material.Slate, nil, nil)
    -- A smaller, tilted cap and a weathered shoulder break up the box shape.
    BuildUtils.CreatePart(parent, name .. "_Cap", Vector3.new(size.X * 0.6, size.Y * 0.45, size.Z * 0.7), frame * CFrame.new(size.X * 0.08, size.Y * 0.55, -size.Z * 0.05) * CFrame.Angles(0.05, 0.3, -0.06), Decor.Colors.RockDark, Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_Shoulder", Vector3.new(size.X * 0.45, size.Y * 0.6, size.Z * 0.9), frame * CFrame.new(-size.X * 0.42, -size.Y * 0.2, size.Z * 0.1) * CFrame.Angles(0, -0.2, 0.12), Decor.Colors.RockLight, Enum.Material.Slate, nil, nil)
end

-- A stepped hill with ramps up its south side and a dark cave mouth on the ledge.
local function mountain(parent: Instance, name: string, position: Vector3)
    local ledge = HistoricalSites.MountainLedge
    local levels = 3
    local step = ledge / levels

    for level = 1, levels do
        local width = 140 - (level - 1) * 40
        BuildUtils.CreatePart(parent, string.format("%s_Level%d", name, level), Vector3.new(width, step, width), CFrame.new(position + Vector3.new(0, GROUND_TOP + step * (level - 0.5), 0)), ROCK, Enum.Material.Slate, nil, nil)
        -- Ramp from the level below onto this level, on the south (-Z) face.
        local rampLength = 26
        local faceZ = -width / 2 - rampLength / 2 + 0.5
        local xShift = (level % 2 == 0) and 18 or -18
        BuildUtils.CreateWedge(
            parent,
            string.format("%s_Ramp%d", name, level),
            Vector3.new(10, step, rampLength),
            CFrame.new(position + Vector3.new(xShift, GROUND_TOP + step * (level - 0.5), faceZ)),
            ROCK,
            Enum.Material.Slate,
            nil
        )
    end

    -- Sloped rock skirts on the north, east and west faces of each terrace (they do not
    -- collide), so the terraces read as a mountainside. The south face keeps its ramps clear.
    local function skirt(label: string, size: Vector3, at: Vector3, outward: Vector3, shade: number)
        local wedge = BuildUtils.CreateWedge(parent, label, size, CFrame.lookAt(at, at + outward), Decor.Shade(ROCK, shade), Enum.Material.Slate, nil)
        wedge.CanCollide = false
        wedge.CanQuery = false
        wedge.CanTouch = false
    end

    for level = 1, levels do
        local width = 140 - (level - 1) * 40
        local slope = 14 + level * 2
        local y = GROUND_TOP + step * (level - 0.5)
        skirt(string.format("%s_SkirtN%d", name, level), Vector3.new(width + slope, step, slope), position + Vector3.new(0, y, width / 2 + slope / 2), Vector3.new(0, 0, 1), 0.92)
        skirt(string.format("%s_SkirtE%d", name, level), Vector3.new(width, step, slope), position + Vector3.new(width / 2 + slope / 2, y, 0), Vector3.new(1, 0, 0), 0.86)
        skirt(string.format("%s_SkirtW%d", name, level), Vector3.new(width, step, slope), position + Vector3.new(-width / 2 - slope / 2, y, 0), Vector3.new(-1, 0, 0), 0.98)
        -- South: two pieces either side of this level's ramp.
        local rampX = (level % 2 == 0) and 18 or -18
        for _, piece in ipairs({ { -width / 2, rampX - 7 }, { rampX + 7, width / 2 } }) do
            local length = piece[2] - piece[1]
            if length > 4 then
                skirt(string.format("%s_SkirtS%d", name, level), Vector3.new(length, step, slope * 0.6), position + Vector3.new((piece[1] + piece[2]) / 2, y, -width / 2 - slope * 0.3), Vector3.new(0, 0, -1), 1.04)
            end
        end
    end

    -- A craggy summit rising behind the cave.
    local summit = position + Vector3.new(0, GROUND_TOP + ledge, 0)
    for index, crag in ipairs({
        { Offset = Vector3.new(0, 20, 46), Size = Vector3.new(44, 40, 22), Out = Vector3.new(0, 0, -1) },
        { Offset = Vector3.new(-24, 14, 46), Size = Vector3.new(22, 28, 24), Out = Vector3.new(-1, 0, 0) },
        { Offset = Vector3.new(25, 12, 45), Size = Vector3.new(22, 24, 24), Out = Vector3.new(1, 0, 0) },
        { Offset = Vector3.new(4, 48, 54), Size = Vector3.new(20, 16, 14), Out = Vector3.new(0, 0, -1) },
    }) do
        skirt(string.format("%s_Crag%d", name, index), crag.Size, summit + crag.Offset, crag.Out, 0.8 + index * 0.05)
    end

    local top = position + Vector3.new(0, GROUND_TOP + ledge, 0)
    BuildUtils.CreatePart(parent, name .. "_CaveRock", Vector3.new(30, 16, 14), CFrame.new(top + Vector3.new(0, 8, 27)), Color3.fromRGB(104, 84, 66), Enum.Material.Slate, nil, nil)
    Decor.Deco(parent, name .. "_CaveMouth", Vector3.new(7, 7, 1), CFrame.new(top + Vector3.new(0, 3.5, 19.6)), Color3.fromRGB(22, 18, 14), Enum.Material.Slate)

    -- Boulders on the north and side faces (never on the south ramps) so it reads as a
    -- mountain rather than a stack of boxes.
    for index = 1, 8 do
        local angle = math.rad(20 + index * 18)
        local reach = 74 + (index % 3) * 6
        Decor.Rocks(parent, string.format("%s_Boulders%d", name, index), position + Vector3.new(math.cos(angle) * reach, GROUND_TOP, math.sin(angle) * reach), 9 + (index % 4) * 3, index * 11 + position.X)
    end

    for level = 1, levels - 1 do
        local width = 140 - (level - 1) * 40
        Decor.Rocks(parent, string.format("%s_LedgeRocks%d", name, level), position + Vector3.new(-width / 2 + 10, GROUND_TOP + step * level, width / 2 - 10), 5, level * 3)
        Decor.Shrub(parent, string.format("%s_Shrub%d", name, level), position + Vector3.new(width / 2 - 8, GROUND_TOP + step * level, width / 2 - 12), level * 5)
    end
end

-- Two facing rows of stalls along a lane, with camels, sacks, rugs and jars.
local function market(parent: Instance, name: string, position: Vector3)
    local base = position + Vector3.new(0, GROUND_TOP, 0)

    -- Two rows of stalls facing an aisle. The middle of the south row is left open as the way in.
    for index = 1, 10 do
        local column = (index - 1) % 5
        local north = index > 5
        local x = (column - 2) * 13
        if north or column ~= 2 then
            local frame = CFrame.new(base + Vector3.new(x, 0, if north then 13 else -13)) * CFrame.Angles(0, if north then math.rad(180) else 0, 0)
            Decor.Stall(parent, string.format("%s_Stall%d", name, index), frame, index * 7 + position.X)
        end
    end

    Decor.Rug(parent, name .. "_RugA", CFrame.new(base + Vector3.new(-30, 0, 0)), 6, 9, 3)
    Decor.Rug(parent, name .. "_RugB", CFrame.new(base + Vector3.new(36, 0, -3)) * CFrame.Angles(0, 0.4, 0), 5, 8, 8)
    Decor.Camel(parent, name .. "_CamelA", CFrame.new(base + Vector3.new(44, 0, 18)) * CFrame.Angles(0, math.rad(80), 0), 1)
    Decor.Camel(parent, name .. "_CamelB", CFrame.new(base + Vector3.new(48, 0, 8)) * CFrame.Angles(0, math.rad(100), 0), 2)

    for index = 1, 4 do
        Decor.Jar(parent, string.format("%s_Jar%d", name, index), base + Vector3.new(-40 + index * 1.9, 0, -24 + (index % 2) * 1.6), 0.8 + (index % 2) * 0.3, nil)
        Decor.Sack(parent, string.format("%s_Sack%d", name, index), base + Vector3.new(30 + index * 1.7, 0, -22), nil)
    end
end

-- The early mosque: a stone footing under mud-brick walls, palm-trunk pillars and a
-- palm-frond roof over the north side, an open courtyard, and doors in the side walls.
-- The large version (Madinah) also has the chambers of the Prophet's ﷺ household on the
-- east side, and bricks and trunks from the building work. No people are shown.
local function earlyMosque(parent: Instance, name: string, position: Vector3, width: number, depth: number)
    local wallHeight = 9
    local large = width >= 80
    local base = position + Vector3.new(0, GROUND_TOP, 0)
    local door = if large then 8 else 6
    BuildUtils.CreatePart(parent, name .. "_Floor", Vector3.new(width, 0.4, depth), CFrame.new(base + Vector3.new(0, 0.2, 0)), Color3.fromRGB(196, 170, 128), Enum.Material.Sand, nil, nil)

    -- Walls with a door in the middle of the south, west and east sides.
    local sideHalf = (depth - door) / 2
    for _, wall in ipairs({
        { Name = "North", Size = Vector3.new(width, wallHeight, 2), Offset = Vector3.new(0, wallHeight / 2, depth / 2) },
        { Name = "WestNorth", Size = Vector3.new(2, wallHeight, sideHalf), Offset = Vector3.new(-width / 2, wallHeight / 2, depth / 2 - sideHalf / 2) },
        { Name = "WestSouth", Size = Vector3.new(2, wallHeight, sideHalf), Offset = Vector3.new(-width / 2, wallHeight / 2, -depth / 2 + sideHalf / 2) },
        { Name = "EastNorth", Size = Vector3.new(2, wallHeight, sideHalf), Offset = Vector3.new(width / 2, wallHeight / 2, depth / 2 - sideHalf / 2) },
        { Name = "EastSouth", Size = Vector3.new(2, wallHeight, sideHalf), Offset = Vector3.new(width / 2, wallHeight / 2, -depth / 2 + sideHalf / 2) },
        { Name = "SouthWest", Size = Vector3.new(width / 2 - 8, wallHeight, 2), Offset = Vector3.new(-width / 4 - 4, wallHeight / 2, -depth / 2) },
        { Name = "SouthEast", Size = Vector3.new(width / 2 - 8, wallHeight, 2), Offset = Vector3.new(width / 4 + 4, wallHeight / 2, -depth / 2) },
    }) do
        BuildUtils.CreatePart(parent, name .. "_Wall" .. wall.Name, wall.Size, CFrame.new(base + wall.Offset), MUD, Enum.Material.Sandstone, nil, nil)
        -- Stone footing, a darker plaster band and a rounded coping on top (all decoration).
        local footing = Vector3.new(wall.Size.X + 0.6, 2, wall.Size.Z + 0.6)
        Decor.Deco(parent, name .. "_Footing" .. wall.Name, footing, CFrame.new(base + Vector3.new(wall.Offset.X, 1, wall.Offset.Z)), ROCK, Enum.Material.Cobblestone)
        Decor.Deco(parent, name .. "_Coping" .. wall.Name, Vector3.new(wall.Size.X + 0.4, 0.6, wall.Size.Z + 0.4), CFrame.new(base + Vector3.new(wall.Offset.X, wallHeight + 0.2, wall.Offset.Z)), MUD_DARK, Enum.Material.Sandstone)
    end

    -- Door frames: palm-trunk posts and a lintel at each opening.
    for index, opening in ipairs({
        { Center = Vector3.new(0, 0, -depth / 2), Along = Vector3.new(1, 0, 0), Span = 16 },
        { Center = Vector3.new(-width / 2, 0, 0), Along = Vector3.new(0, 0, 1), Span = door },
        { Center = Vector3.new(width / 2, 0, 0), Along = Vector3.new(0, 0, 1), Span = door },
    }) do
        for _, side in ipairs({ -1, 1 }) do
            local post = base + opening.Center + opening.Along * (side * (opening.Span / 2 - 0.4))
            Decor.Rod(parent, string.format("%s_DoorPost%d_%d", name, index, side), post, post + Vector3.new(0, wallHeight - 1, 0), 0.45, PALM_WOOD, Enum.Material.Wood, false)
        end
        local a = base + opening.Center - opening.Along * (opening.Span / 2) + Vector3.new(0, wallHeight - 1, 0)
        Decor.Rod(parent, string.format("%s_Lintel%d", name, index), a, a + opening.Along * opening.Span, 0.5, Decor.Colors.TrunkDark, Enum.Material.Wood, false)
    end

    -- The roofed prayer area: rows of palm-trunk pillars with ring marks.
    local roofDepth = depth * 0.35
    local columns = math.floor(width / 14)
    local rows = if large then 3 else 2

    for row = 1, rows do
        for column = 1, columns do
            local x = -width / 2 + (column - 0.5) * (width / columns)
            local z = depth / 2 - roofDepth * (row / (rows + 0.2))
            local foot = base + Vector3.new(x, 0, z)
            BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Pillar%d_%d", name, row, column), wallHeight, 0.8, foot + Vector3.new(0, wallHeight / 2, 0), PALM_WOOD, Enum.Material.Wood, nil)
            for ring = 1, 2 do
                Decor.Deco(parent, string.format("%s_PillarRing%d_%d_%d", name, row, column, ring), Vector3.new(0.35, 1.75, 1.75), CFrame.new(foot + Vector3.new(0, ring * 3.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Decor.Colors.TrunkDark, Enum.Material.Wood, Enum.PartType.Cylinder)
            end
        end
    end

    -- Frond roof: a base layer, uneven bundles on top, and a ragged edge facing the courtyard.
    local roofCenter = base + Vector3.new(0, wallHeight + 0.4, depth / 2 - roofDepth / 2)
    BuildUtils.CreatePart(parent, name .. "_FrondRoof", Vector3.new(width, 0.8, roofDepth), CFrame.new(roofCenter), FROND, Enum.Material.Grass, nil, nil)
    local r = Decor.Rng(math.floor(width * 7 + depth))
    local bundles = if large then 22 else 8

    for index = 1, bundles do
        local x = r(-width / 2 + 3, width / 2 - 3)
        local z = r(-roofDepth / 2 + 2, roofDepth / 2 - 2)
        local tint = if index % 3 == 0 then Decor.Colors.FrondDry elseif index % 3 == 1 then Decor.Shade(FROND, 0.82) else Decor.Shade(FROND, 1.12)
        Decor.Deco(parent, string.format("%s_FrondBundle%d", name, index), Vector3.new(r(5, 9), 0.4, r(2, 3.5)), CFrame.new(roofCenter + Vector3.new(x, 0.55, z)) * CFrame.Angles(0, r(-0.6, 0.6), r(-0.06, 0.06)), tint, Enum.Material.Grass)
    end

    local rafters = math.floor(width / 7)

    for index = 1, rafters do
        local x = -width / 2 + (index - 0.5) * (width / rafters)
        Decor.Rod(parent, string.format("%s_Rafter%d", name, index), base + Vector3.new(x, wallHeight - 0.3, depth / 2), base + Vector3.new(x, wallHeight - 0.3, depth / 2 - roofDepth), 0.35, Decor.Colors.TrunkDark, Enum.Material.Wood, false)
        Decor.Deco(parent, string.format("%s_FrondEdge%d", name, index), Vector3.new(width / rafters + 1, 0.3, 2.4), CFrame.new(base + Vector3.new(x, wallHeight + 0.1, depth / 2 - roofDepth - 0.6)) * CFrame.Angles(math.rad(-25), (index % 3 - 1) * 0.08, 0), if index % 2 == 0 then Decor.Colors.FrondDry else FROND, Enum.Material.Grass)
    end

    -- Palm-fibre mats under the roof, and water jars by the south door.
    local mats = if large then 6 else 2
    for index = 1, mats do
        local x = -width / 2 + (index - 0.5) * (width / mats)
        Decor.Deco(parent, string.format("%s_Mat%d", name, index), Vector3.new(width / mats - 2, 0.12, roofDepth - 4), CFrame.new(base + Vector3.new(x, 0.46, depth / 2 - roofDepth / 2 - 0.5)), if index % 2 == 0 then Color3.fromRGB(184, 156, 104) else Color3.fromRGB(168, 140, 92), Enum.Material.Fabric)
    end

    for _, side in ipairs({ -1, 1 }) do
        Decor.Jar(parent, string.format("%s_GateJar%d", name, side), base + Vector3.new(side * 12, 0, -depth / 2 - 3), 0.9, nil)
    end

    -- Pebble patches in the open courtyard.
    for index = 1, (if large then 14 else 5) do
        Decor.Deco(parent, string.format("%s_Pebbles%d", name, index), Vector3.new(r(4, 8), 0.1, r(3, 6)), CFrame.new(base + Vector3.new(r(-width / 2 + 6, width / 2 - 6), 0.42, r(-depth / 2 + 6, depth / 2 - roofDepth - 4))) * CFrame.Angles(0, r(0, 3), 0), Color3.fromRGB(172, 150, 116), Enum.Material.Pebble)
    end

    if large then
        -- The household chambers along the outside of the east wall, with hanging
        -- curtains of dark hair cloth for doors.
        local roomDepth = 14
        -- They sit back to back with the wall (doors facing out), clear of the east door.
        for index, z in ipairs({ depth / 2 - 10, depth / 2 - 25, -depth / 2 + 20 }) do
            local roomBase = CFrame.new(base + Vector3.new(width / 2 + 1 + 6, 0, z)) * CFrame.Angles(0, math.rad(-90), 0)
            Decor.MudHouse(parent, string.format("%s_Chamber%d", name, index), roomBase, roomDepth, 12, 8, 900 + index, { Color = MUD })
            Decor.Deco(parent, string.format("%s_Curtain%d", name, index), Vector3.new(0.2, 5.5, 3.2), CFrame.new(base + Vector3.new(width / 2 - 1.15, 3.2, z)), Color3.fromRGB(46, 38, 32), Enum.Material.Fabric)
        end

        -- Building work: stacks of mud bricks, brick moulds and spare palm trunks by the west wall.
        for stack = 1, 3 do
            local corner = base + Vector3.new(-width / 2 + 8 + stack * 6, 0, -depth / 2 + 8)
            for layer = 1, 3 do
                for brick = 1, 3 - math.floor(layer / 2) do
                    Decor.Deco(parent, string.format("%s_Bricks%d_%d_%d", name, stack, layer, brick), Vector3.new(1.6, 0.7, 1), CFrame.new(corner + Vector3.new((brick - 2) * 1.7, 0.4 + layer * 0.7, (layer % 2) * 0.4)), Decor.Shade(MUD, 0.92 + (brick % 2) * 0.1), Enum.Material.Sandstone)
                end
            end
        end
        Decor.Deco(parent, name .. "_BrickMould", Vector3.new(2.2, 0.5, 1.4), CFrame.new(base + Vector3.new(-width / 2 + 34, 0.65, -depth / 2 + 8)), PALM_WOOD, Enum.Material.WoodPlanks)
        for trunk = 1, 3 do
            local a = base + Vector3.new(-width / 2 + 6, 0.9 + (trunk == 3 and 1.4 or 0), -depth / 2 + 16 + trunk * 1.6 - (trunk == 3 and 2.4 or 0))
            Decor.Rod(parent, string.format("%s_SpareTrunk%d", name, trunk), a, a + Vector3.new(14, 0, 0), 0.75, PALM_WOOD, Enum.Material.Wood, false)
        end
    end

    Decor.Deco(parent, name .. "_WallCap", Vector3.new(width + 1, 0.5, 2.6), CFrame.new(base + Vector3.new(0, wallHeight + 0.2, depth / 2)), MUD_DARK, Enum.Material.Sandstone)
end

local function siteBuild(parent: Instance, site: HistoricalSites.Site)
    local folder = BuildUtils.CreateFolder(parent, site.Id)
    local p = site.Position
    local kind = site.Kind

    if kind == "Kaaba" then
        -- The Kaaba as Quraysh rebuilt it, with a plain open area and houses close by.
        BuildUtils.CreatePart(folder, "OpenGround", Vector3.new(90, 0.3, 90), CFrame.new(p + Vector3.new(0, GROUND_TOP + 0.15, 0)), Color3.fromRGB(214, 190, 150), Enum.Material.Sandstone, nil, nil)
        BuildUtils.CreatePart(folder, "Kaaba", Vector3.new(22, 26, 18), CFrame.new(p + Vector3.new(0, GROUND_TOP + 13, 40)), Color3.fromRGB(26, 24, 22), Enum.Material.Fabric, nil, nil)
        BuildUtils.CreatePart(folder, "KaabaBase", Vector3.new(23, 1.5, 19), CFrame.new(p + Vector3.new(0, GROUND_TOP + 0.75, 40)), Color3.fromRGB(150, 130, 104), Enum.Material.Slate, nil, nil)
        BuildUtils.CreatePart(folder, "BlackStone", Vector3.new(1.2, 1.6, 1.2), CFrame.new(p + Vector3.new(-11.2, GROUND_TOP + 5, 31.2)), Color3.fromRGB(12, 10, 10), Enum.Material.Basalt, nil, nil)

        -- Quraysh raised the door above the ground; the Hijr is marked by a low curved wall.
        BuildUtils.CreatePart(folder, "KaabaDoor", Vector3.new(4, 7, 0.5), CFrame.new(p + Vector3.new(-4, GROUND_TOP + 9.5, 30.9)), Color3.fromRGB(84, 60, 36), Enum.Material.WoodPlanks, nil, nil)
        BuildUtils.CreatePart(folder, "KaabaBand", Vector3.new(22.4, 2, 18.4), CFrame.new(p + Vector3.new(0, GROUND_TOP + 19, 40)), Color3.fromRGB(46, 40, 34), Enum.Material.Fabric, nil, nil)

        for index = 0, 8 do
            local a = math.rad(index * 22.5)
            Decor.Solid(folder, "HijrWall" .. index, Vector3.new(1.2, 2.6, 4.6), CFrame.new(p + Vector3.new(math.cos(a) * 10, GROUND_TOP + 1.3, 49 + math.sin(a) * 9)) * CFrame.Angles(0, -a, 0), Color3.fromRGB(176, 150, 112), Enum.Material.Sandstone)
        end

        Decor.Well(folder, "Zamzam", p + Vector3.new(26, GROUND_TOP, 24))

        for index = 1, 14 do
            local angle = math.rad(index * (360 / 14) + 10)
            local houseAt = p + Vector3.new(math.cos(angle) * 80, GROUND_TOP, 40 + math.sin(angle) * 80)
            -- Leave both ends open: the chapter's travel point and path in (-Z), and the town
            -- arrival with room for the camera behind arriving players (+Z).
            if math.abs(math.sin(angle)) < 0.8 then
                mudHouse(folder, string.format("House%d", index), houseAt, Vector3.new(17 + (index % 3) * 2, 11 + (index % 3) * 2, 15), -math.deg(angle) + 90, nil)
            end
        end
    elseif kind == "House" then
        local storeys = if site.Id == "abu_ayyub_house" then 2 else nil
        -- The house stands behind a yard, beyond the ring where chapter items are placed.
        mudHouse(folder, "House", p + Vector3.new(0, GROUND_TOP, 58), Vector3.new(26, 13, 20), 0, { Storeys = storeys, Awning = true, Bench = true })
        BuildUtils.CreatePart(folder, "Yard", Vector3.new(34, 0.3, 46), CFrame.new(p + Vector3.new(0, GROUND_TOP + 0.15, 24)), Color3.fromRGB(190, 164, 124), Enum.Material.Sandstone, nil, nil)
        palm(folder, "Palm", p + Vector3.new(-21, GROUND_TOP, 52))
        Decor.Jar(folder, "JarA", p + Vector3.new(11, GROUND_TOP, 30), 1, nil)
        Decor.Jar(folder, "JarB", p + Vector3.new(12.6, GROUND_TOP, 28.4), 0.8, nil)
        Decor.Rug(folder, "Rug", CFrame.new(p + Vector3.new(-6, GROUND_TOP + 0.3, 6)), 5, 7, #site.Id)
    elseif kind == "Market" then
        market(folder, "Market", p)
    elseif kind == "Mountain" then
        mountain(folder, "Mountain", p)
    elseif kind == "Hill" then
        rockMass(folder, "Hill", p + Vector3.new(0, GROUND_TOP, 26), Vector3.new(50, 10, 34), 0)
        BuildUtils.CreateWedge(folder, "HillSlope", Vector3.new(16, 10, 22), CFrame.new(p + Vector3.new(0, GROUND_TOP + 5, 14)), ROCK, Enum.Material.Slate, nil)

        for index = 1, 4 do
            Decor.Rocks(folder, "Boulders" .. index, p + Vector3.new(-34 + (index - 1) * 22, GROUND_TOP, 46 + (index % 2) * 4), 6 + index, index + #site.Id)
        end
    elseif kind == "Valley" then
        -- The valley walls stand outside the ring where chapter items are placed.
        rockMass(folder, "WallWest", p + Vector3.new(-62, GROUND_TOP, 0), Vector3.new(24, 28, 130), 4)
        rockMass(folder, "WallEast", p + Vector3.new(62, GROUND_TOP, 0), Vector3.new(24, 24, 130), -6)

        for index = 1, 6 do
            local side = if index % 2 == 0 then 1 else -1
            Decor.Rocks(folder, "Scree" .. index, p + Vector3.new(side * 56, GROUND_TOP, -50 + index * 16), 5 + (index % 3) * 2, index * 13 + #site.Id)
        end

        Decor.Shrub(folder, "ShrubA", p + Vector3.new(-12, GROUND_TOP, -30), 4)
        Decor.Shrub(folder, "ShrubB", p + Vector3.new(16, GROUND_TOP, 52), 9)

        for index = 1, 3 do
            tent(folder, "Tent" .. index, p + Vector3.new(-14 + (index - 1) * 14, GROUND_TOP, 30 + (index % 2) * 10), 180, CLOTH[index])
        end
    elseif kind == "Harbour" then
        BuildUtils.CreatePart(folder, "Sea", Vector3.new(160, 1, 120), CFrame.new(p + Vector3.new(80, GROUND_TOP - 1.4, 0)), Color3.fromRGB(52, 102, 130), Enum.Material.Glass, nil, 0.15).CanCollide = false
        BuildUtils.CreatePart(folder, "SeaBed", Vector3.new(160, 1, 120), CFrame.new(p + Vector3.new(80, GROUND_TOP - 6, 0)), Color3.fromRGB(160, 140, 104), Enum.Material.Sand, nil, nil)
        BuildUtils.CreatePart(folder, "Pier", Vector3.new(40, 1, 8), CFrame.new(p + Vector3.new(20, GROUND_TOP + 0.5, 0)), PALM_WOOD, Enum.Material.WoodPlanks, nil, nil)
        BuildUtils.CreatePart(folder, "BoatHull", Vector3.new(26, 4, 9), CFrame.new(p + Vector3.new(50, GROUND_TOP - 0.5, 10)), Color3.fromRGB(98, 70, 46), Enum.Material.WoodPlanks, nil, nil)
        BuildUtils.CreatePart(folder, "BoatMast", Vector3.new(0.8, 22, 0.8), CFrame.new(p + Vector3.new(50, GROUND_TOP + 12, 10)), PALM_WOOD, Enum.Material.Wood, nil, nil)
        BuildUtils.CreatePart(folder, "BoatSail", Vector3.new(0.3, 14, 12), CFrame.new(p + Vector3.new(50.6, GROUND_TOP + 14, 10)), Color3.fromRGB(226, 214, 186), Enum.Material.Fabric, nil, nil).CanCollide = false
        -- A hall standing for the Najashi's court across the sea.
        earlyMosque(folder, "CourtHall", p + Vector3.new(-40, 0, 30), 44, 30)

        for index = 1, 5 do
            Decor.Crate(folder, "Crate" .. index, CFrame.new(p + Vector3.new(4 + index * 5, GROUND_TOP + 1, 2.4 - (index % 2) * 4.8)) * CFrame.Angles(0, index * 0.4, 0), 2.4)
        end

        Decor.Jar(folder, "JarA", p + Vector3.new(-2, GROUND_TOP, 6), 1.1, nil)
        Decor.Jar(folder, "JarB", p + Vector3.new(-3.8, GROUND_TOP, 4), 0.9, nil)
        Decor.Rod(folder, "Rope", p + Vector3.new(38, GROUND_TOP + 1.2, 3.6), p + Vector3.new(44, GROUND_TOP + 1.6, 6), 0.12, Color3.fromRGB(196, 170, 120), Enum.Material.Fabric, false)
        palm(folder, "ShorePalmA", p + Vector3.new(-6, GROUND_TOP, -24))
        palm(folder, "ShorePalmB", p + Vector3.new(10, GROUND_TOP, -34))
    elseif kind == "Orchard" then
        -- The walls stand outside the ring where chapter items are placed, with a gate south.
        local corners = { p + Vector3.new(-52, GROUND_TOP, -52), p + Vector3.new(52, GROUND_TOP, -52), p + Vector3.new(52, GROUND_TOP, 52), p + Vector3.new(-52, GROUND_TOP, 52) }
        Decor.Wall(folder, "WallSouthW", corners[1], p + Vector3.new(-10, GROUND_TOP, -52), 6, 2, nil)
        Decor.Wall(folder, "WallSouthE", p + Vector3.new(10, GROUND_TOP, -52), corners[2], 6, 2, nil)
        Decor.Wall(folder, "WallEast", corners[2], corners[3], 6, 2, nil)
        Decor.Wall(folder, "WallNorth", corners[3], corners[4], 6, 2, nil)
        Decor.Wall(folder, "WallWest", corners[4], corners[1], 6, 2, nil)

        -- Rows of vines on trellis poles, with palms between the rows.
        for row = -1, 1 do
            local z = row * 18
            -- Vines are walk-through so they never hide an item or block the ring.
            Decor.Deco(folder, "Vines" .. row, Vector3.new(50, 3, 3), CFrame.new(p + Vector3.new(0, GROUND_TOP + 2.6, z)), Color3.fromRGB(86, 120, 60), Enum.Material.Grass)

            for post = 0, 5 do
                Decor.Rod(folder, string.format("Trellis%d_%d", row + 2, post), p + Vector3.new(-25 + post * 10, GROUND_TOP, z), p + Vector3.new(-25 + post * 10, GROUND_TOP + 4.4, z), 0.15, Decor.Colors.WoodDark, Enum.Material.Wood, false)
            end

            for bunch = 1, 6 do
                Decor.Deco(folder, string.format("Grapes%d_%d", row + 2, bunch), Vector3.new(1, 1.3, 1), CFrame.new(p + Vector3.new(-22 + bunch * 7.4, GROUND_TOP + 1.2, z - 1.7)), Color3.fromRGB(96, 52, 88), Enum.Material.Pebble, Enum.PartType.Ball)
            end
        end

        palm(folder, "PalmNW", p + Vector3.new(-47, GROUND_TOP, 47))
        palm(folder, "PalmNE", p + Vector3.new(47, GROUND_TOP, 46))
        palm(folder, "PalmSE", p + Vector3.new(46, GROUND_TOP, -47))
    elseif kind == "Camp" then
        for index = 1, 4 do
            local angle = math.rad(index * 90 + 45)
            tent(folder, "Tent" .. index, p + Vector3.new(math.cos(angle) * 30, GROUND_TOP, math.sin(angle) * 30), -math.deg(angle) - 90, CLOTH[index])
        end

        Decor.Well(folder, "Well", p + Vector3.new(0, GROUND_TOP, 10))
        palm(folder, "PalmA", p + Vector3.new(-12, GROUND_TOP, 20))
        palm(folder, "PalmB", p + Vector3.new(14, GROUND_TOP, 26))
        Decor.Camel(folder, "CamelA", CFrame.new(p + Vector3.new(-34, GROUND_TOP, 12)) * CFrame.Angles(0, math.rad(70), 0), #site.Id)
        Decor.Camel(folder, "CamelB", CFrame.new(p + Vector3.new(-37, GROUND_TOP, 4)) * CFrame.Angles(0, math.rad(95), 0), #site.Id + 3)

        if site.Id == "war_council" or site.Id == "tabuk_camp" then
            for index = 1, 3 do
                Decor.Banner(folder, "Banner" .. index, p + Vector3.new(-16 + index * 8, GROUND_TOP, 34), Decor.Colors.Cloths[index + 1], 14)
            end
        end
    elseif kind == "Plain" then
        BuildUtils.CreatePart(folder, "MountOfMercy", Vector3.new(40, 12, 40), CFrame.new(p + Vector3.new(0, GROUND_TOP + 6, 50)) * CFrame.Angles(0, math.rad(45), 0), ROCK, Enum.Material.Slate, nil, nil)
        BuildUtils.CreateVerticalCylinder(folder, "Marker", 10, 1.2, p + Vector3.new(0, GROUND_TOP + 17, 50), Color3.fromRGB(226, 218, 200), Enum.Material.Limestone, nil)

        for index = 1, 5 do
            Decor.Rocks(folder, "Boulders" .. index, p + Vector3.new(math.cos(index * 1.25) * 30, GROUND_TOP, 50 + math.sin(index * 1.25) * 30), 6, index + 40)
        end

        -- Pilgrims' and travellers' tents at the edge of the plain.
        for index = 1, 4 do
            tent(folder, "PlainTent" .. index, p + Vector3.new(-66 + (index - 1) * 44, GROUND_TOP, -62 - (index % 2) * 10), 180, CLOTH[index])
        end
    elseif kind == "Mosque" then
        local size = if site.Id == "masjid_early" then Vector3.new(100, 0, 80) else Vector3.new(50, 0, 40)
        earlyMosque(folder, "Mosque", p + Vector3.new(0, 0, size.Z / 2 + 6), size.X, size.Z)
    elseif kind == "Trench" then
        BuildUtils.CreatePart(folder, "TrenchFloor", Vector3.new(220, 0.4, 12), CFrame.new(p + Vector3.new(0, GROUND_TOP - 5.8, 30)), Color3.fromRGB(120, 96, 70), Enum.Material.Ground, nil, nil)
        BuildUtils.CreatePart(folder, "TrenchLipSouth", Vector3.new(220, 3, 4), CFrame.new(p + Vector3.new(0, GROUND_TOP + 1.5, 22)), Color3.fromRGB(150, 120, 88), Enum.Material.Ground, nil, nil)
        BuildUtils.CreatePart(folder, "TrenchLipNorth", Vector3.new(220, 3, 4), CFrame.new(p + Vector3.new(0, GROUND_TOP + 1.5, 38)), Color3.fromRGB(150, 120, 88), Enum.Material.Ground, nil, nil)

        -- Spoil heaps along the inner lip, baskets and digging tools.
        for index = 1, 9 do
            local x = -100 + (index - 1) * 25
            Decor.Deco(folder, "Spoil" .. index, Vector3.new(10, 4, 7), CFrame.new(p + Vector3.new(x, GROUND_TOP + 0.6, 45)) * CFrame.Angles(0, index * 0.5, 0), Color3.fromRGB(140, 110, 80), Enum.Material.Ground, Enum.PartType.Ball)
            Decor.Deco(folder, "Basket" .. index, Vector3.new(1.2, 2, 2), CFrame.new(p + Vector3.new(x + 6, GROUND_TOP + 0.6, 18)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(170, 132, 80), Enum.Material.Fabric, Enum.PartType.Cylinder)
        end
    end

    local arrival = HistoricalSites.ArrivalPoint(site)
    -- Beside the walk in from the travel point, not across it.
    sign(folder, "Sign", arrival + Vector3.new(-16, 0, -12), site.DisplayName, "Historical reconstruction. " .. site.Description, 180)

    -- Two fire bowls beside the sign, so every site is lit and easy to find at night.
    for _, side in ipairs({ -1, 1 }) do
        Decor.Brazier(folder, if side < 0 then "BrazierWest" else "BrazierEast", arrival + Vector3.new(side * 6, 0, -24))
    end

    -- A soft ring marks where chapters begin; the campaign HUD points players to it.
    local ring = BuildUtils.CreateVerticalCylinder(folder, "ChapterRing", 0.3, 9, arrival + Vector3.new(0, 0.2, 0), Color3.fromRGB(247, 208, 117), Enum.Material.Neon, 0.55)
    ring.CanCollide = false
    ring.CanQuery = false
    ring.CanTouch = false
end

-- Ground kept clear of houses: each site's footprint, every arrival point with its item ring,
-- and every travel point.
type Clearing = { At: Vector3, Radius: number }

local function clearingsFor(zoneId: string): { Clearing }
    local list: { Clearing } = {}

    local function add(at: Vector3, radius: number)
        table.insert(list, { At = Vector3.new(at.X, 0, at.Z), Radius = radius })
    end

    for _, site in ipairs(HistoricalSites.Sites) do
        if site.Zone == zoneId then
            local p = site.Position
            local kind = site.Kind

            if kind == "Kaaba" then
                add(p + Vector3.new(0, 0, 40), 104)
            elseif kind == "Mountain" then
                add(p, 120)
            elseif kind == "Valley" then
                add(p, 100)
            elseif kind == "Harbour" then
                add(p + Vector3.new(40, 0, 10), 150)
            elseif kind == "Orchard" then
                add(p, 76)
            elseif kind == "Camp" or kind == "Market" then
                add(p, 62)
            elseif kind == "Plain" then
                add(p + Vector3.new(0, 0, 10), 90)
            elseif kind == "Mosque" then
                add(p + Vector3.new(0, 0, if site.Id == "masjid_early" then 46 else 26), if site.Id == "masjid_early" then 84 else 46)
            elseif kind == "Trench" then
                for x = -120, 120, 30 do
                    add(p + Vector3.new(x, 0, 30), 30)
                end
            elseif kind == "House" then
                add(p + Vector3.new(0, 0, 40), 40)
            end

            local arrival = HistoricalSites.ArrivalPoint(site)
            add(arrival, 52)
            add(arrival + Vector3.new(0, 0, -42), 16)
        end
    end

    return list
end

local function isClear(clearings: { Clearing }, at: Vector3, footprint: number): boolean
    local flat = Vector3.new(at.X, 0, at.Z)

    for _, clearing in ipairs(clearings) do
        if (clearing.At - flat).Magnitude < clearing.Radius + footprint then
            return false
        end
    end

    return true
end

-- Yaw that turns a Decor house (door on -Z) to face `target`.
local function yawToward(from: Vector3, target: Vector3): number
    local d = target - from
    return math.deg(math.atan2(-d.X, -d.Z))
end

-- Outlying houses on a jittered grid between `inner` and `radius`, thinning out towards the
-- edge. Two main streets cross at the centre and every house faces the nearest one.
-- `occupied` holds the footprints of the block houses, so the two never overlap.
local function buildTown(parent: Instance, zone: HistoricalSites.Zone, clearings: { Clearing }, occupied: { Clearing }, inner: number, radius: number, cell: number, seed: number): number
    local c = zone.Center
    local r = Decor.Rng(seed)
    local houses = 0
    local steps = math.floor(radius / cell)

    for gx = -steps, steps do
        for gz = -steps, steps do
            local roll = r()
            local jx, jz = r(-cell * 0.12, cell * 0.12), r(-cell * 0.12, cell * 0.12)
            local offset = Vector3.new(gx * cell + jx, 0, gz * cell + jz)
            local distance = offset.Magnitude
            local onStreet = math.abs(offset.X) < 16 or math.abs(offset.Z) < 16
            -- Fewer houses towards the edge of town.
            local density = 0.75 - 0.5 * (distance / radius)

            if distance >= inner and distance < radius and not onStreet and roll < density then
                local width, depth, height = r(14, 22), r(12, 18), r(10, 15)
                local at = c + offset + Vector3.new(0, GROUND_TOP, 0)

                if isClear(clearings, at, math.max(width, depth) * 0.75) and isClear(occupied, at, math.max(width, depth) * 0.6) then
                    local street = if math.abs(offset.X) < math.abs(offset.Z) then c + Vector3.new(0, 0, offset.Z) else c + Vector3.new(offset.X, 0, 0)
                    local yaw = math.floor(yawToward(at, street + Vector3.new(0, GROUND_TOP, 0)) / 90 + 0.5) * 90 + r(-4, 4)
                    houses += 1
                    mudHouse(parent, string.format("House_%d_%d", gx, gz), at, Vector3.new(width, height, depth), yaw, { Lite = r() < 0.6 })

                    -- Jars, sacks or a tethered camel at some doors.
                    local front = CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(width / 2 - 2, 0, -depth / 2 - 2.6)
                    local extra = r()

                    if extra < 0.18 then
                        Decor.Jar(parent, string.format("Jar_%d_%d", gx, gz), front.Position, r(0.8, 1.1), nil)
                    elseif extra < 0.28 then
                        Decor.Sack(parent, string.format("Sack_%d_%d", gx, gz), front.Position, nil)
                    elseif extra < 0.33 then
                        Decor.Camel(parent, string.format("Camel_%d_%d", gx, gz), front * CFrame.new(3, 0, -4) * CFrame.Angles(0, math.rad(90), 0), gx * 7 + gz)
                    end
                end
            end
        end
    end

    return houses
end

-- Palm groves: clusters of palms with low garden walls, outside the town.
local function buildGroves(parent: Instance, zone: HistoricalSites.Zone, clearings: { Clearing }, count: number, inner: number, outer: number, perGrove: number, seed: number)
    local c = zone.Center
    local r = Decor.Rng(seed)

    for grove = 1, count do
        local angle = r(0, math.pi * 2)
        local reach = r(inner, outer)
        local centre = c + Vector3.new(math.cos(angle) * reach, GROUND_TOP, math.sin(angle) * reach)

        if isClear(clearings, centre, 30) then
            local folder = BuildUtils.CreateFolder(parent, "Grove" .. grove)
            -- Darker, greener ground where the grove is watered.
            Decor.Deco(folder, "Soil", Vector3.new(66, 0.1, 66), CFrame.new(centre + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, r(0, 1.5), 0), Color3.fromRGB(150, 140, 92), Enum.Material.Grass)

            for index = 1, perGrove do
                local at = centre + Vector3.new(r(-26, 26), 0, r(-26, 26))
                Decor.Palm(folder, "Palm" .. index, at, r(15, 26), grove * 31 + index, true)
            end

            if r() > 0.4 then
                Decor.Wall(folder, "GardenWall", centre + Vector3.new(-28, 0, -28), centre + Vector3.new(28, 0, -28), 3.5, 1.4, nil)
            end

            for index = 1, 2 do
                Decor.Shrub(folder, "Shrub" .. index, centre + Vector3.new(r(-24, 24), 0, r(-24, 24)), grove + index * 3)
            end
        end
    end
end

-- A mountain ridge: two wedges back to back make a triangular profile, with a tilted rock
-- on the crest so the skyline is not a straight line.
local function ridge(parent: Instance, name: string, ground: Vector3, length: number, height: number, depth: number, yaw: number, seed: number)
    local r = Decor.Rng(seed)
    local frame = CFrame.new(ground) * CFrame.Angles(0, math.rad(yaw), 0)
    local colors = { ROCK, Decor.Colors.RockDark, Decor.Colors.RockLight }
    local tint = colors[math.floor(r(1, 3.999))]
    BuildUtils.CreateWedge(parent, name .. "_Front", Vector3.new(length, height, depth / 2), frame * CFrame.new(0, height / 2, -depth / 4), tint, Enum.Material.Slate, nil)
    BuildUtils.CreateWedge(parent, name .. "_Back", Vector3.new(length, height, depth / 2), frame * CFrame.new(0, height / 2, depth / 4) * CFrame.Angles(0, math.pi, 0), Decor.Shade(tint, 0.88), Enum.Material.Slate, nil)
    -- A shorter spur across the ridge breaks up the long crest.
    local spur = r(0.45, 0.75)
    local spurFrame = frame * CFrame.new(r(-length * 0.3, length * 0.3), 0, 0) * CFrame.Angles(0, math.rad(90 + r(-20, 20)), 0)
    BuildUtils.CreateWedge(parent, name .. "_SpurA", Vector3.new(depth * 0.7, height * spur, depth * 0.45), spurFrame * CFrame.new(0, height * spur / 2, -depth * 0.225), Decor.Shade(tint, 1.06), Enum.Material.Slate, nil)
    BuildUtils.CreateWedge(parent, name .. "_SpurB", Vector3.new(depth * 0.7, height * spur, depth * 0.45), spurFrame * CFrame.new(0, height * spur / 2, depth * 0.225) * CFrame.Angles(0, math.pi, 0), Decor.Shade(tint, 0.94), Enum.Material.Slate, nil)
    BuildUtils.CreatePart(parent, name .. "_Crag", Vector3.new(r(10, 18), r(8, 14), r(8, 14)), frame * CFrame.new(r(-length * 0.25, length * 0.25), height - 3, 0) * CFrame.Angles(r(-0.4, 0.4), r(0, 3), r(-0.4, 0.4)), Decor.Colors.RockDark, Enum.Material.Slate, nil, nil)
end

-- A ring of bare mountains around the valley: high ridges at the edge and lower hills
-- in front of them.
local function buildRange(parent: Instance, zone: HistoricalSites.Zone, clearings: { Clearing }, seed: number)
    local c = zone.Center
    local half = zone.Size / 2
    local r = Decor.Rng(seed)

    for layer = 1, 2 do
        local count = if layer == 1 then 20 else 16
        local reach = if layer == 1 then 1.02 else 0.9

        for index = 1, count do
            local angle = ((index + layer * 0.5) / count) * math.pi * 2 + r(-0.06, 0.06)
            local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local at = c + Vector3.new(outward.X * half.X * reach, GROUND_TOP, outward.Z * half.Z * reach)
            local height = if layer == 1 then r(70, 150) else r(26, 60)
            local depth = if layer == 1 then r(110, 160) else r(60, 90)

            local length = r(150, 230)

            -- Pull back where a site or its item ring sits near the edge, and leave the gap
            -- open if that is not enough.
            while not isClear(clearings, at, math.max(length, depth) * 0.5) and (at - c).Magnitude < half.X * 1.25 do
                at += outward * 12
            end

            if isClear(clearings, at, math.max(length, depth) * 0.5) then
                ridge(parent, string.format("Ridge%d_%d", layer, index), at, length, height, depth, math.deg(angle) + 90 + r(-15, 15), seed + layer * 100 + index)
            end
        end
    end
end

-- Packed town blocks: a grid of streets, each block lined on all four sides with attached
-- houses facing outwards, around a shared inner yard.
local function buildBlocks(parent: Instance, zone: HistoricalSites.Zone, clearings: { Clearing }, occupied: { Clearing }, radius: number, spacing: number, seed: number): number
    local c = zone.Center
    local r = Decor.Rng(seed)
    local street = 12
    local block = spacing - street
    local steps = math.floor(radius / spacing)
    local houses = 0

    for bx = -steps, steps - 1 do
        for bz = -steps, steps - 1 do
            local blockCentre = Vector3.new((bx + 0.5) * spacing, 0, (bz + 0.5) * spacing)

            if blockCentre.Magnitude < radius then
                -- A lantern at every other street crossing, so the streets are lit at night.
                local crossing = c + Vector3.new(bx * spacing + 4, GROUND_TOP, bz * spacing + 4)
                if (bx + bz) % 2 == 0 and isClear(clearings, crossing, 4) then
                    Decor.LanternPost(parent, string.format("StreetLantern_%d_%d", bx, bz), crossing, 10)
                end

                -- Each side of the block: start corner, direction along the side, outward normal.
                for side = 1, 4 do
                    local along, outward, length

                    if side == 1 then
                        along, outward, length = Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), block
                    elseif side == 2 then
                        along, outward, length = Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), block
                    elseif side == 3 then
                        along, outward, length = Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), block - 36
                    else
                        along, outward, length = Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), block - 36
                    end

                    local depth = 17
                    local cursor = -length / 2

                    while cursor < length / 2 - 8 do
                        local width = math.min(r(12, 19), length / 2 - cursor)
                        local centreOffset = outward * (block / 2 - depth / 2) + along * (cursor + width / 2)
                        local at = c + blockCentre + centreOffset + Vector3.new(0, GROUND_TOP, 0)
                        cursor += width

                        if width >= 9 and r() < 0.88 and isClear(clearings, at, math.max(width, depth) * 0.6) then
                            local yaw = math.deg(math.atan2(-outward.X, -outward.Z))
                            houses += 1
                            mudHouse(parent, string.format("Block_%d_%d_%d_%d", bx, bz, side, houses), at, Vector3.new(width - 0.4, r(10, 17), depth), yaw, { Lite = true })
                            table.insert(occupied, { At = Vector3.new(at.X, 0, at.Z), Radius = math.max(width, depth) * 0.6 })
                        end
                    end
                end
            end
        end
    end

    return houses
end

-- Scattered shrubs and stones on the open ground.
local function scatter(parent: Instance, zone: HistoricalSites.Zone, clearings: { Clearing }, count: number, seed: number)
    local r = Decor.Rng(seed)

    for index = 1, count do
        local at = zone.Center + Vector3.new(r(-560, 560), GROUND_TOP, r(-560, 560))

        if isClear(clearings, at, 6) then
            if index % 3 == 0 then
                Decor.Rocks(parent, "Stones" .. index, at, r(2, 4), index + seed)
            else
                Decor.Shrub(parent, "Shrub" .. index, at, index + seed)
            end
        end
    end
end

local function townspeople(parent: Instance, center: Vector3, count: number)
    for index = 1, count do
        -- Along the two main streets, facing along them.
        local along = -280 + (index * 97) % 560
        if math.abs(along) < 120 then
            -- Keep clear of the Kaaba and the first mosque in the middle of each town.
            along += if along < 0 then -150 else 150
        end
        local onX = index % 2 == 0
        local side = if index % 4 < 2 then -4 else 4
        local position = center + (if onX then Vector3.new(along, GROUND_TOP, side) else Vector3.new(side, GROUND_TOP, along))
        local yaw = if onX then (if index % 3 == 0 then 90 else -90) else (if index % 3 == 0 then 0 else 180)
        Figures.CreateTownsperson(parent, string.format("Townsperson_%d", index), CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0), CLOTH[(index % #CLOTH) + 1])
    end
end

local townStats: { [string]: number } = {}

for zoneIndex, zone in ipairs(HistoricalSites.Zones) do
    local zoneFolder = BuildUtils.CreateFolder(root, zone.Id)
    local c = zone.Center
    local isMakkah = zone.Id == "makkah_610"
    BuildUtils.CreatePart(zoneFolder, "SafetyPlate", Vector3.new(zone.Size.X + 200, 10, zone.Size.Z + 200), CFrame.new(c + Vector3.new(0, -8, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(zoneFolder, "Ground", Vector3.new(zone.Size.X, GROUND_TOP, zone.Size.Z), CFrame.new(c + Vector3.new(0, GROUND_TOP / 2, 0)), SAND, Enum.Material.Sand, nil, nil)

    -- Packed-earth streets and patches of lighter and darker sand.
    for _, street in ipairs({ Vector3.new(zone.Size.X - 260, 0.12, 18), Vector3.new(18, 0.12, zone.Size.Z - 260) }) do
        Decor.Deco(zoneFolder, "Street", street, CFrame.new(c + Vector3.new(0, GROUND_TOP + 0.06, 0)), Color3.fromRGB(180, 150, 108), Enum.Material.Ground)
    end

    local patchRng = Decor.Rng(zoneIndex * 101)

    for index = 1, 28 do
        local at = c + Vector3.new(patchRng(-560, 560), GROUND_TOP + 0.04, patchRng(-560, 560))
        local tint = if index % 2 == 0 then Color3.fromRGB(214, 190, 146) else Color3.fromRGB(190, 160, 116)
        Decor.Deco(zoneFolder, "SandPatch", Vector3.new(patchRng(40, 110), 0.08, patchRng(30, 90)), CFrame.new(at) * CFrame.Angles(0, patchRng(0, 3.14), 0), tint, Enum.Material.Sand)
    end

    -- Invisible walls keep players inside the reconstruction.
    local half = zone.Size / 2

    for _, wall in ipairs({
        { Vector3.new(zone.Size.X, 80, 4), Vector3.new(0, 40, half.Z) },
        { Vector3.new(zone.Size.X, 80, 4), Vector3.new(0, 40, -half.Z) },
        { Vector3.new(4, 80, zone.Size.Z), Vector3.new(half.X, 40, 0) },
        { Vector3.new(4, 80, zone.Size.Z), Vector3.new(-half.X, 40, 0) },
    }) do
        BuildUtils.CreatePart(zoneFolder, "Boundary", wall[1], CFrame.new(c + wall[2]), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    end

    -- Bare mountains around the edge give the valley feel of both towns.
    local entrance = if isMakkah then c + Vector3.new(0, 0, 110) else c + Vector3.new(0, 0, -90)
    -- Beside the arrival spot, not in front of or behind it (where it would fill the view).
    sign(zoneFolder, "EntranceSign", entrance + Vector3.new(-26, 0, if isMakkah then -10 else 10), zone.DisplayName, zone.Disclaimer, if isMakkah then 180 else 0)

    local clearings = clearingsFor(zone.Id)
    table.insert(clearings, { At = Vector3.new(entrance.X, 0, entrance.Z), Radius = 40 })
    buildRange(BuildUtils.CreateFolder(zoneFolder, "Mountains"), zone, clearings, zoneIndex * 7)

    -- Makkah is a tight town of houses in a dry valley; Madinah is a looser settlement among
    -- palm groves.
    local town = BuildUtils.CreateFolder(zoneFolder, "Town")
    local occupied: { Clearing } = {}
    local blockHouses = buildBlocks(town, zone, clearings, occupied, if isMakkah then 250 else 200, 70, zoneIndex * 19)
    townStats[zone.Id] = blockHouses + buildTown(town, zone, clearings, occupied, if isMakkah then 250 else 170, if isMakkah then 380 else 330, 46, zoneIndex * 13)
    scatter(BuildUtils.CreateFolder(zoneFolder, "Scrub"), zone, clearings, 50, zoneIndex * 23)
    buildGroves(BuildUtils.CreateFolder(zoneFolder, "Groves"), zone, clearings, if isMakkah then 8 else 64, if isMakkah then 380 else 190, 570, if isMakkah then 3 else 10, zoneIndex * 17)

    local sitesFolder = BuildUtils.CreateFolder(zoneFolder, "Sites")

    for _, site in ipairs(HistoricalSites.Sites) do
        if site.Zone == zone.Id then
            local ok, err = pcall(siteBuild, sitesFolder, site)

            if not ok then
                warn(string.format("[HistoricalWorldBuilder] Site %s failed: %s", site.Id, tostring(err)))
            end
        end
    end

    townspeople(BuildUtils.CreateFolder(zoneFolder, "Townspeople"), c, 18)
end

root:SetAttribute("MakkahHouses", townStats.makkah_610 or 0)
root:SetAttribute("MadinahHouses", townStats.madinah_622 or 0)

-- Items for Collect chapters. They start hidden; the campaign HUD shows a player only the items
-- of the chapter they are playing, and the server checks every pickup.
local itemsFolder = BuildUtils.CreateFolder(root, "CampaignItems")

for _, chapter in ipairs(SeerahCampaign.Chapters) do
    local activity = chapter.Activity
    local site = HistoricalSites.GetSite(chapter.Site)

    if activity and activity.Kind == "Collect" and site then
        local chapterFolder = BuildUtils.CreateFolder(itemsFolder, chapter.Id)
        local arrival = HistoricalSites.ArrivalPoint(site)
        local onLedge = site.Kind == "Mountain"

        for index = 1, activity.Count or 0 do
            local position = arrival + CampaignRules.ItemOffset(chapter, index, onLedge) + Vector3.new(0, 1.2, 0)
            local item = BuildUtils.CreatePart(chapterFolder, string.format("Item_%d", index), Vector3.new(2, 2, 2), CFrame.new(position), Color3.fromRGB(240, 206, 120), Enum.Material.Neon, nil, 1)
            item.CanCollide = false
            item.CanTouch = false
            item:SetAttribute("ChapterId", chapter.Id)
            item:SetAttribute("ItemIndex", index)

            local prompt = BuildUtils.AttachPrompt(item, "Pick up", activity.Item or "item", {
                PromptAction = "CampaignCollect",
                ChapterId = chapter.Id,
                ItemIndex = index,
            })
            prompt.Enabled = false
        end
    end
end

-- Lantern posts at the two town arrival points used by the travel menu.
local TravelRoute = require(Shared.Data.TravelRoute)
local arrivalLights = BuildUtils.CreateFolder(root, "ArrivalLanterns")
for _, id in ipairs({ "seerah_campaign", "seerah_madinah" }) do
    local destination = TravelRoute.GetDestinationById(id)
    if destination then
        local landing = destination.TeleportPosition or destination.Position
        Decor.ArrivalLanterns(arrivalLights, id, landing, GROUND_TOP)
    end
end

root:SetAttribute("Built", true)
