--!strict

-- Builds the two historical zones of the Seerah campaign: Makkah c. 570-630 CE and Madinah
-- c. 622-632 CE (see Shared/Data/HistoricalSites). They are deliberately plain: mud brick,
-- palm wood, tents, and bare hills, so they never look like the present-day hub with its
-- marble mosque. Every sign says "Historical reconstruction".
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

local function mudHouse(parent: Instance, name: string, position: Vector3, size: Vector3, yaw: number)
    local base = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
    BuildUtils.CreatePart(parent, name .. "_Walls", size, base * CFrame.new(0, size.Y / 2, 0), MUD, Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_Roof", Vector3.new(size.X + 1.5, 1.2, size.Z + 1.5), base * CFrame.new(0, size.Y + 0.6, 0), PALM_WOOD, Enum.Material.WoodPlanks, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_Door", Vector3.new(4, 8, 0.6), base * CFrame.new(0, 4, -size.Z / 2 - 0.3), Color3.fromRGB(86, 62, 40), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_Window", Vector3.new(2.4, 2, 0.4), base * CFrame.new(size.X / 4, size.Y * 0.7, -size.Z / 2 - 0.2), Color3.fromRGB(40, 30, 24), Enum.Material.Wood, nil, nil)
end

local function palm(parent: Instance, name: string, position: Vector3)
    -- `position` is on the ground surface, as the hub's palms are.
    BuildUtils.CreatePalmTree(parent, name, position)
end

local function tent(parent: Instance, name: string, position: Vector3, yaw: number, color: Color3)
    local base = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0)
    BuildUtils.CreatePart(parent, name .. "_Rug", Vector3.new(18, 0.4, 14), base * CFrame.new(0, 0.2, 0), Color3.fromRGB(150, 110, 70), Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_RoofL", Vector3.new(10, 0.6, 14), base * CFrame.new(-4.4, 5.2, 0) * CFrame.Angles(0, 0, math.rad(28)), color, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_RoofR", Vector3.new(10, 0.6, 14), base * CFrame.new(4.4, 5.2, 0) * CFrame.Angles(0, 0, math.rad(-28)), color, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_Back", Vector3.new(14, 7, 0.4), base * CFrame.new(0, 3.5, 6.8), color, Enum.Material.Fabric, nil, nil)
end

local function rockMass(parent: Instance, name: string, position: Vector3, size: Vector3, yaw: number)
    BuildUtils.CreatePart(parent, name, size, CFrame.new(position + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, math.rad(yaw), 0), ROCK, Enum.Material.Slate, nil, nil)
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

    local top = position + Vector3.new(0, GROUND_TOP + ledge, 0)
    BuildUtils.CreatePart(parent, name .. "_CaveRock", Vector3.new(30, 16, 14), CFrame.new(top + Vector3.new(0, 8, 20)), Color3.fromRGB(104, 84, 66), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_CaveMouth", Vector3.new(7, 7, 1), CFrame.new(top + Vector3.new(0, 3.5, 12.6)), Color3.fromRGB(22, 18, 14), Enum.Material.Slate, nil, nil)
end

local function market(parent: Instance, name: string, position: Vector3)
    for index = 1, 6 do
        local x = ((index - 1) % 3 - 1) * 22
        local z = if index <= 3 then -14 else 14
        local base = position + Vector3.new(x, GROUND_TOP, z)
        BuildUtils.CreatePart(parent, string.format("%s_Stall%d", name, index), Vector3.new(10, 3, 5), CFrame.new(base + Vector3.new(0, 1.5, 0)), PALM_WOOD, Enum.Material.WoodPlanks, nil, nil)
        BuildUtils.CreatePart(parent, string.format("%s_Awning%d", name, index), Vector3.new(12, 0.4, 8), CFrame.new(base + Vector3.new(0, 8, 0)) * CFrame.Angles(math.rad(8), 0, 0), CLOTH[(index % #CLOTH) + 1], Enum.Material.Fabric, nil, nil)
        for _, px in ipairs({ -5.5, 5.5 }) do
            BuildUtils.CreatePart(parent, string.format("%s_Pole%d_%d", name, index, px), Vector3.new(0.6, 8, 0.6), CFrame.new(base + Vector3.new(px, 4, -3.5)), PALM_WOOD, Enum.Material.Wood, nil, nil)
        end
        BuildUtils.CreatePart(parent, string.format("%s_Goods%d", name, index), Vector3.new(3, 1.6, 2), CFrame.new(base + Vector3.new(-2, 3.8, 0)), CLOTH[((index + 1) % #CLOTH) + 1], Enum.Material.Fabric, nil, nil)
    end
end

-- The early mosque: mud walls, palm-trunk pillars, and a palm-frond roof over the north side.
local function earlyMosque(parent: Instance, name: string, position: Vector3, width: number, depth: number)
    local wallHeight = 9
    local base = position + Vector3.new(0, GROUND_TOP, 0)
    BuildUtils.CreatePart(parent, name .. "_Floor", Vector3.new(width, 0.4, depth), CFrame.new(base + Vector3.new(0, 0.2, 0)), Color3.fromRGB(196, 170, 128), Enum.Material.Sand, nil, nil)

    for _, wall in ipairs({
        { Name = "North", Size = Vector3.new(width, wallHeight, 2), Offset = Vector3.new(0, wallHeight / 2, depth / 2) },
        { Name = "West", Size = Vector3.new(2, wallHeight, depth), Offset = Vector3.new(-width / 2, wallHeight / 2, 0) },
        { Name = "East", Size = Vector3.new(2, wallHeight, depth), Offset = Vector3.new(width / 2, wallHeight / 2, 0) },
        { Name = "SouthWest", Size = Vector3.new(width / 2 - 8, wallHeight, 2), Offset = Vector3.new(-width / 4 - 4, wallHeight / 2, -depth / 2) },
        { Name = "SouthEast", Size = Vector3.new(width / 2 - 8, wallHeight, 2), Offset = Vector3.new(width / 4 + 4, wallHeight / 2, -depth / 2) },
    }) do
        BuildUtils.CreatePart(parent, name .. "_Wall" .. wall.Name, wall.Size, CFrame.new(base + wall.Offset), MUD, Enum.Material.Sandstone, nil, nil)
    end

    local roofDepth = depth * 0.35
    local columns = math.floor(width / 14)

    for row = 1, 2 do
        for column = 1, columns do
            local x = -width / 2 + (column - 0.5) * (width / columns)
            local z = depth / 2 - roofDepth * (row / 2.2)
            BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Pillar%d_%d", name, row, column), wallHeight, 0.8, base + Vector3.new(x, wallHeight / 2, z), PALM_WOOD, Enum.Material.Wood, nil)
        end
    end

    BuildUtils.CreatePart(parent, name .. "_FrondRoof", Vector3.new(width, 0.8, roofDepth), CFrame.new(base + Vector3.new(0, wallHeight + 0.4, depth / 2 - roofDepth / 2)), FROND, Enum.Material.Grass, nil, nil)
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

        for index = 1, 10 do
            local angle = math.rad(index * 36 + 10)
            local houseAt = p + Vector3.new(math.cos(angle) * 78, GROUND_TOP, 40 + math.sin(angle) * 78)
            mudHouse(folder, string.format("House%d", index), houseAt, Vector3.new(16, 11 + (index % 3) * 2, 14), -math.deg(angle) + 90)
        end
    elseif kind == "House" then
        mudHouse(folder, "House", p + Vector3.new(0, GROUND_TOP, 22), Vector3.new(26, 13, 20), 0)
        BuildUtils.CreatePart(folder, "Yard", Vector3.new(30, 0.3, 18), CFrame.new(p + Vector3.new(0, GROUND_TOP + 0.15, 4)), Color3.fromRGB(190, 164, 124), Enum.Material.Sandstone, nil, nil)
        palm(folder, "Palm", p + Vector3.new(-20, GROUND_TOP, 6))
    elseif kind == "Market" then
        market(folder, "Market", p)
    elseif kind == "Mountain" then
        mountain(folder, "Mountain", p)
    elseif kind == "Hill" then
        rockMass(folder, "Hill", p + Vector3.new(0, GROUND_TOP, 26), Vector3.new(50, 10, 34), 0)
        BuildUtils.CreateWedge(folder, "HillSlope", Vector3.new(16, 10, 22), CFrame.new(p + Vector3.new(0, GROUND_TOP + 5, -2)), ROCK, Enum.Material.Slate, nil)
    elseif kind == "Valley" then
        rockMass(folder, "WallWest", p + Vector3.new(-40, GROUND_TOP, 0), Vector3.new(20, 28, 120), 4)
        rockMass(folder, "WallEast", p + Vector3.new(40, GROUND_TOP, 0), Vector3.new(20, 24, 120), -6)

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
    elseif kind == "Orchard" then
        for index = 1, 4 do
            local side = ({ Vector3.new(0, 0, 36), Vector3.new(0, 0, -36), Vector3.new(36, 0, 0), Vector3.new(-36, 0, 0) })[index]
            local size = if index <= 2 then Vector3.new(72, 6, 2) else Vector3.new(2, 6, 72)
            if index == 2 then
                -- Leave a gate in the south wall.
                BuildUtils.CreatePart(folder, "WallSouthW", Vector3.new(28, 6, 2), CFrame.new(p + side + Vector3.new(-22, GROUND_TOP + 3, 0)), MUD, Enum.Material.Sandstone, nil, nil)
                BuildUtils.CreatePart(folder, "WallSouthE", Vector3.new(28, 6, 2), CFrame.new(p + side + Vector3.new(22, GROUND_TOP + 3, 0)), MUD, Enum.Material.Sandstone, nil, nil)
            else
                BuildUtils.CreatePart(folder, "Wall" .. index, size, CFrame.new(p + side + Vector3.new(0, GROUND_TOP + 3, 0)), MUD, Enum.Material.Sandstone, nil, nil)
            end
        end

        for row = -1, 1 do
            BuildUtils.CreatePart(folder, "Vines" .. row, Vector3.new(50, 4, 3), CFrame.new(p + Vector3.new(0, GROUND_TOP + 2, row * 18)), Color3.fromRGB(86, 120, 60), Enum.Material.Grass, nil, nil)
        end
    elseif kind == "Camp" then
        for index = 1, 4 do
            local angle = math.rad(index * 90 + 45)
            tent(folder, "Tent" .. index, p + Vector3.new(math.cos(angle) * 30, GROUND_TOP, math.sin(angle) * 30), -math.deg(angle) - 90, CLOTH[index])
        end

        BuildUtils.CreateVerticalCylinder(folder, "Well", 3, 3, p + Vector3.new(0, GROUND_TOP + 1.5, 10), Color3.fromRGB(150, 128, 98), Enum.Material.Slate, nil)
        palm(folder, "PalmA", p + Vector3.new(-12, GROUND_TOP, 20))
    elseif kind == "Plain" then
        BuildUtils.CreatePart(folder, "MountOfMercy", Vector3.new(40, 12, 40), CFrame.new(p + Vector3.new(0, GROUND_TOP + 6, 50)) * CFrame.Angles(0, math.rad(45), 0), ROCK, Enum.Material.Slate, nil, nil)
        BuildUtils.CreateVerticalCylinder(folder, "Marker", 10, 1.2, p + Vector3.new(0, GROUND_TOP + 17, 50), Color3.fromRGB(226, 218, 200), Enum.Material.Limestone, nil)
    elseif kind == "Mosque" then
        local size = if site.Id == "masjid_early" then Vector3.new(100, 0, 80) else Vector3.new(50, 0, 40)
        earlyMosque(folder, "Mosque", p + Vector3.new(0, 0, size.Z / 2 + 6), size.X, size.Z)
    elseif kind == "Trench" then
        BuildUtils.CreatePart(folder, "TrenchFloor", Vector3.new(220, 0.4, 12), CFrame.new(p + Vector3.new(0, GROUND_TOP - 5.8, 30)), Color3.fromRGB(120, 96, 70), Enum.Material.Ground, nil, nil)
        BuildUtils.CreatePart(folder, "TrenchLipSouth", Vector3.new(220, 3, 4), CFrame.new(p + Vector3.new(0, GROUND_TOP + 1.5, 22)), Color3.fromRGB(150, 120, 88), Enum.Material.Ground, nil, nil)
        BuildUtils.CreatePart(folder, "TrenchLipNorth", Vector3.new(220, 3, 4), CFrame.new(p + Vector3.new(0, GROUND_TOP + 1.5, 38)), Color3.fromRGB(150, 120, 88), Enum.Material.Ground, nil, nil)
    end

    local arrival = HistoricalSites.ArrivalPoint(site)
    sign(folder, "Sign", arrival + Vector3.new(0, 0, -12), site.DisplayName, "Historical reconstruction. " .. site.Description, 180)

    -- A soft ring marks where chapters begin; the campaign HUD points players to it.
    local ring = BuildUtils.CreateVerticalCylinder(folder, "ChapterRing", 0.3, 9, arrival + Vector3.new(0, 0.2, 0), Color3.fromRGB(247, 208, 117), Enum.Material.Neon, 0.55)
    ring.CanCollide = false
    ring.CanQuery = false
    ring.CanTouch = false
end

local function townspeople(parent: Instance, center: Vector3, count: number)
    for index = 1, count do
        local angle = index * 2.4
        local radius = 120 + (index % 5) * 70
        local position = center + Vector3.new(math.cos(angle) * radius, GROUND_TOP, math.sin(angle) * radius)
        Figures.CreateTownsperson(parent, string.format("Townsperson_%d", index), CFrame.new(position) * CFrame.Angles(0, angle, 0), CLOTH[(index % #CLOTH) + 1])
    end
end

for _, zone in ipairs(HistoricalSites.Zones) do
    local zoneFolder = BuildUtils.CreateFolder(root, zone.Id)
    local c = zone.Center
    BuildUtils.CreatePart(zoneFolder, "SafetyPlate", Vector3.new(zone.Size.X + 200, 10, zone.Size.Z + 200), CFrame.new(c + Vector3.new(0, -8, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(zoneFolder, "Ground", Vector3.new(zone.Size.X, GROUND_TOP, zone.Size.Z), CFrame.new(c + Vector3.new(0, GROUND_TOP / 2, 0)), SAND, Enum.Material.Sand, nil, nil)

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

    -- Low hills around the edge give the valley feel of both towns.
    for index = 1, 12 do
        local angle = math.rad(index * 30)
        local at = c + Vector3.new(math.cos(angle) * (half.X - 40), 0, math.sin(angle) * (half.Z - 40))
        rockMass(zoneFolder, "EdgeHill" .. index, at + Vector3.new(0, GROUND_TOP, 0), Vector3.new(90, 30 + (index % 3) * 14, 50), math.deg(angle) + 90)
    end

    for index = 1, 26 do
        local angle = index * 1.7
        local radius = 90 + (index * 37) % 420
        palm(zoneFolder, "Palm" .. index, c + Vector3.new(math.cos(angle) * radius, GROUND_TOP, math.sin(angle) * radius))
    end

    local entrance = if zone.Id == "makkah_610" then c + Vector3.new(0, 0, 110) else c + Vector3.new(0, 0, -90)
    sign(zoneFolder, "EntranceSign", entrance + Vector3.new(0, 0, if zone.Id == "makkah_610" then 14 else -14), zone.DisplayName, zone.Disclaimer, if zone.Id == "makkah_610" then 0 else 180)

    local sitesFolder = BuildUtils.CreateFolder(zoneFolder, "Sites")

    for _, site in ipairs(HistoricalSites.Sites) do
        if site.Zone == zone.Id then
            local ok, err = pcall(siteBuild, sitesFolder, site)

            if not ok then
                warn(string.format("[HistoricalWorldBuilder] Site %s failed: %s", site.Id, tostring(err)))
            end
        end
    end

    townspeople(BuildUtils.CreateFolder(zoneFolder, "Townspeople"), c, 10)
end

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

root:SetAttribute("Built", true)
