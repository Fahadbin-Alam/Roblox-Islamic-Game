--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CompanionStories = require(Shared.Data.CompanionStories)
local MannersLessons = require(Shared.Data.MannersLessons)
local TravelRoute = require(Shared.Data.TravelRoute)
local BuildUtils = require(script.Parent.Modules.BuildUtils)

local MECCA_STONE = Color3.fromRGB(218, 206, 186)
local MECCA_MARBLE = Color3.fromRGB(233, 226, 214)
local MECCA_DARK = Color3.fromRGB(131, 112, 84)
local DESERT_SAND = Color3.fromRGB(206, 183, 138)
local DESERT_ROCK = Color3.fromRGB(147, 118, 82)
local MEDINA_WHITE = Color3.fromRGB(239, 238, 232)
local MEDINA_GREEN = Color3.fromRGB(77, 128, 88)
local MEDINA_STONE = Color3.fromRGB(221, 218, 205)
local GOLD_ACCENT = Color3.fromRGB(193, 162, 86)
local GLASS_TINT = Color3.fromRGB(108, 119, 132)
local DARK_PANEL = Color3.fromRGB(42, 45, 49)

local function createSafetyBounds(parent: Instance, namePrefix: string, center: Vector3, footprint: Vector3)
    local barrierHeight = 110
    local thickness = 12
    local barrierYOffset = 28

    BuildUtils.CreatePart(parent, string.format("%s_NorthBarrier", namePrefix), Vector3.new(footprint.X, barrierHeight, thickness), CFrame.new(center + Vector3.new(0, barrierYOffset, footprint.Z * -0.5)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, string.format("%s_SouthBarrier", namePrefix), Vector3.new(footprint.X, barrierHeight, thickness), CFrame.new(center + Vector3.new(0, barrierYOffset, footprint.Z * 0.5)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, string.format("%s_WestBarrier", namePrefix), Vector3.new(thickness, barrierHeight, footprint.Z), CFrame.new(center + Vector3.new(footprint.X * -0.5, barrierYOffset, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, string.format("%s_EastBarrier", namePrefix), Vector3.new(thickness, barrierHeight, footprint.Z), CFrame.new(center + Vector3.new(footprint.X * 0.5, barrierYOffset, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
end

local function createLightPost(parent: Instance, name: string, position: Vector3, poleColor: Color3?)
    BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Pole", name), 13, 0.6, position + Vector3.new(0, 6.5, 0), poleColor or Color3.fromRGB(124, 107, 84), Enum.Material.Metal, nil)
    BuildUtils.CreateSphere(parent, string.format("%s_Light", name), 3.2, position + Vector3.new(0, 13.4, 0), Color3.fromRGB(255, 242, 206), Enum.Material.Neon, nil)
end

local function createWallPanel(
    parent: Instance,
    name: string,
    position: Vector3,
    size: Vector3,
    title: string,
    subtitle: string,
    wallColor: Color3,
    orientationY: number,
    promptData
)
    local sign = BuildUtils.CreateWallSign(parent, name, position, size, title, subtitle, wallColor, promptData)
    sign.Orientation = Vector3.new(0, orientationY, 0)

    return sign
end

local function createDigitalScreen(parent: Instance, name: string, position: Vector3, size: Vector3, title: string, subtitle: string)
    local screen = BuildUtils.CreatePart(parent, name, size, CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)), Color3.fromRGB(39, 44, 50), Enum.Material.Metal, nil, nil)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.CanvasSize = Vector2.new(760, 360)
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 48
    surfaceGui.Parent = screen

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(30, 24)
    titleLabel.Size = UDim2.new(1, -60, 0, 92)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(246, 240, 220)
    titleLabel.TextScaled = true
    titleLabel.TextWrapped = true
    titleLabel.Parent = surfaceGui

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(30, 130)
    subtitleLabel.Size = UDim2.new(1, -60, 0, 150)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(203, 212, 224)
    subtitleLabel.TextScaled = true
    subtitleLabel.TextWrapped = true
    subtitleLabel.Parent = surfaceGui

    return screen
end

local function createFloorInlayGrid(parent: Instance, namePrefix: string, center: Vector3, extent: number, spacing: number, color: Color3, yOffset: number)
    local lineIndex = 0

    for x = -extent, extent, spacing do
        lineIndex += 1
        BuildUtils.CreatePart(
            parent,
            string.format("%s_X_%d", namePrefix, lineIndex),
            Vector3.new(1.1, 0.18, extent * 2),
            CFrame.new(center + Vector3.new(x, yOffset, 0)),
            color,
            Enum.Material.Marble,
            nil,
            nil
        )
    end

    for z = -extent, extent, spacing do
        lineIndex += 1
        BuildUtils.CreatePart(
            parent,
            string.format("%s_Z_%d", namePrefix, lineIndex),
            Vector3.new(extent * 2, 0.18, 1.1),
            CFrame.new(center + Vector3.new(0, yOffset, z)),
            color,
            Enum.Material.Marble,
            nil,
            nil
        )
    end
end

local function createRingTiles(parent: Instance, namePrefix: string, center: Vector3, radius: number, count: number, color: Color3, yOffset: number)
    for index = 1, count do
        local angle = (math.pi * 2) * (index / count)
        local position = center + Vector3.new(math.cos(angle) * radius, yOffset, math.sin(angle) * radius)
        BuildUtils.CreatePart(
            parent,
            string.format("%s_%d", namePrefix, index),
            Vector3.new(13, 0.22, 2.2),
            CFrame.new(position) * CFrame.Angles(0, -angle, 0),
            color,
            Enum.Material.Marble,
            nil,
            nil
        )
    end
end

local function createLowBollard(parent: Instance, name: string, position: Vector3, accentColor: Color3)
    BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Post", name), 5.5, 0.45, position + Vector3.new(0, 2.75, 0), Color3.fromRGB(117, 102, 77), Enum.Material.Metal, nil)
    BuildUtils.CreateSphere(parent, string.format("%s_Glow", name), 1.7, position + Vector3.new(0, 5.8, 0), accentColor, Enum.Material.Neon, nil)
end

local function createPrayerMatRows(parent: Instance, namePrefix: string, origin: Vector3, rowCount: number, columnCount: number, facingRadians: number, matColor: Color3)
    local spacingX = 10
    local spacingZ = 15

    for row = 1, rowCount do
        for column = 1, columnCount do
            local localX = (column - (columnCount + 1) * 0.5) * spacingX
            local localZ = (row - 1) * spacingZ
            local cframe = CFrame.new(origin) * CFrame.Angles(0, facingRadians, 0) * CFrame.new(localX, 0, localZ)

            BuildUtils.CreatePart(
                parent,
                string.format("%s_%d_%d", namePrefix, row, column),
                Vector3.new(7, 0.18, 12),
                cframe,
                matColor,
                Enum.Material.Fabric,
                nil,
                nil
            )
        end
    end
end

local function createMaqamIbrahimMarker(parent: Instance, center: Vector3)
    local markerFolder = BuildUtils.CreateFolder(parent, "MaqamIbrahimMarker")
    local markerCenter = center + Vector3.new(48, 0, -54)

    BuildUtils.CreateVerticalCylinder(markerFolder, "GoldBase", 2.2, 8, markerCenter + Vector3.new(0, 6.1, 0), GOLD_ACCENT, Enum.Material.Metal, nil)
    BuildUtils.CreateVerticalCylinder(markerFolder, "GlassCover", 9, 5.4, markerCenter + Vector3.new(0, 12, 0), Color3.fromRGB(194, 217, 225), Enum.Material.Glass, 0.42)
    BuildUtils.CreateSphere(markerFolder, "GoldDome", 11, markerCenter + Vector3.new(0, 17.8, 0), GOLD_ACCENT, Enum.Material.Metal, nil)
    BuildUtils.CreatePart(markerFolder, "StoneInside", Vector3.new(5.2, 2.4, 5.2), CFrame.new(markerCenter + Vector3.new(0, 8.3, 0)), Color3.fromRGB(169, 150, 120), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(markerFolder, "FootprintA", Vector3.new(1.2, 0.25, 2), CFrame.new(markerCenter + Vector3.new(-1, 9.62, 0)), Color3.fromRGB(103, 91, 73), Enum.Material.Slate, Enum.PartType.Ball, nil)
    BuildUtils.CreatePart(markerFolder, "FootprintB", Vector3.new(1.2, 0.25, 2), CFrame.new(markerCenter + Vector3.new(1, 9.62, 0)), Color3.fromRGB(103, 91, 73), Enum.Material.Slate, Enum.PartType.Ball, nil)
    createWallPanel(markerFolder, "MaqamSign", markerCenter + Vector3.new(0, 0, -26), Vector3.new(58, 10, 2), "Maqam Ibrahim", "A respectful marker for the station of Ibrahim near the Kaaba. It is not a 1:1 replica.", Color3.fromRGB(107, 85, 46), 180, nil)
end

local function createHijrIsmailMarker(parent: Instance, center: Vector3)
    local markerFolder = BuildUtils.CreateFolder(parent, "HijrIsmailMarker")
    local arcCenter = center + Vector3.new(0, 0, 42)

    for index = 1, 18 do
        local angle = math.rad(180 + (index - 1) * 10)
        local position = arcCenter + Vector3.new(math.cos(angle) * 38, 0, math.sin(angle) * 38)
        BuildUtils.CreatePart(
            markerFolder,
            string.format("LowArcWall_%d", index),
            Vector3.new(9, 3.2, 3.2),
            CFrame.new(position + Vector3.new(0, 7.2, 0)) * CFrame.Angles(0, -angle, 0),
            Color3.fromRGB(235, 230, 218),
            Enum.Material.Marble,
            nil,
            nil
        )
    end

    createWallPanel(markerFolder, "HijrSign", arcCenter + Vector3.new(0, 0, 48), Vector3.new(58, 10, 2), "Hijr / Hateem Marker", "A simple low boundary marker so players recognize another important Kaaba-side landmark.", Color3.fromRGB(86, 79, 65), 0, nil)
end

local function createArcadeBlock(parent: Instance, namePrefix: string, center: Vector3, width: number, depth: number, floorColor: Color3, wallColor: Color3, roofColor: Color3)
    BuildUtils.CreatePart(parent, string.format("%s_Floor", namePrefix), Vector3.new(width, 1, depth), CFrame.new(center + Vector3.new(0, 4.55, 0)), floorColor, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Roof", namePrefix), Vector3.new(width, 4, depth), CFrame.new(center + Vector3.new(0, 22, 0)), roofColor, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_GlassFront", namePrefix), Vector3.new(width - 20, 3, 1.2), CFrame.new(center + Vector3.new(0, 15.5, depth * -0.5 + 3)), GLASS_TINT, Enum.Material.Glass, nil, 0.18)
    BuildUtils.CreatePart(parent, string.format("%s_GlassBack", namePrefix), Vector3.new(width - 20, 3, 1.2), CFrame.new(center + Vector3.new(0, 15.5, depth * 0.5 - 3)), GLASS_TINT, Enum.Material.Glass, nil, 0.18)

    local xCount = math.max(2, math.floor((width - 24) / 32))
    local zCount = math.max(1, math.floor((depth - 24) / 32))

    for index = 0, xCount do
        local alpha = index / xCount
        local x = -width * 0.5 + 12 + alpha * (width - 24)
        BuildUtils.CreatePart(parent, string.format("%s_ColumnFront_%d", namePrefix, index + 1), Vector3.new(4.5, 18, 4.5), CFrame.new(center + Vector3.new(x, 13, depth * -0.5 + 10)), wallColor, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(parent, string.format("%s_ColumnBack_%d", namePrefix, index + 1), Vector3.new(4.5, 18, 4.5), CFrame.new(center + Vector3.new(x, 13, depth * 0.5 - 10)), wallColor, Enum.Material.Marble, nil, nil)
    end

    for index = 1, zCount - 1 do
        local alpha = index / zCount
        local z = -depth * 0.5 + 12 + alpha * (depth - 24)
        BuildUtils.CreatePart(parent, string.format("%s_ColumnLeft_%d", namePrefix, index), Vector3.new(4.5, 18, 4.5), CFrame.new(center + Vector3.new(width * -0.5 + 10, 13, z)), wallColor, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(parent, string.format("%s_ColumnRight_%d", namePrefix, index), Vector3.new(4.5, 18, 4.5), CFrame.new(center + Vector3.new(width * 0.5 - 10, 13, z)), wallColor, Enum.Material.Marble, nil, nil)
    end
end

local function createTent(parent: Instance, name: string, position: Vector3, clothColor: Color3)
    local floor = BuildUtils.CreatePart(parent, string.format("%s_Floor", name), Vector3.new(22, 1, 18), CFrame.new(position + Vector3.new(0, 0.5, 0)), Color3.fromRGB(176, 152, 111), Enum.Material.Sandstone, nil, nil)
    floor.CanCollide = true

    local leftRoof = BuildUtils.CreatePart(parent, string.format("%s_LeftRoof", name), Vector3.new(12, 1, 18), CFrame.new(position + Vector3.new(-5.8, 7.5, 0)) * CFrame.Angles(0, 0, math.rad(24)), clothColor, Enum.Material.Fabric, nil, nil)
    local rightRoof = BuildUtils.CreatePart(parent, string.format("%s_RightRoof", name), Vector3.new(12, 1, 18), CFrame.new(position + Vector3.new(5.8, 7.5, 0)) * CFrame.Angles(0, 0, math.rad(-24)), clothColor, Enum.Material.Fabric, nil, nil)
    leftRoof.CanCollide = true
    rightRoof.CanCollide = true

    BuildUtils.CreatePart(parent, string.format("%s_Back", name), Vector3.new(18, 8, 1), CFrame.new(position + Vector3.new(0, 4, 8.5)), Color3.fromRGB(121, 94, 62), Enum.Material.WoodPlanks, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_PoleA", name), Vector3.new(1, 10, 1), CFrame.new(position + Vector3.new(-6.8, 5, 0)), Color3.fromRGB(108, 78, 48), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_PoleB", name), Vector3.new(1, 10, 1), CFrame.new(position + Vector3.new(6.8, 5, 0)), Color3.fromRGB(108, 78, 48), Enum.Material.Wood, nil, nil)
end

local function createMedinaGate(parent: Instance, name: string, center: Vector3, orientationY: number, title: string, subtitle: string)
    local rotation = CFrame.Angles(0, math.rad(orientationY), 0)
    local gateFolder = BuildUtils.CreateFolder(parent, name)

    BuildUtils.CreatePart(gateFolder, "LeftColumn", Vector3.new(8, 26, 8), CFrame.new(center) * rotation * CFrame.new(-14, 13, 0), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(gateFolder, "RightColumn", Vector3.new(8, 26, 8), CFrame.new(center) * rotation * CFrame.new(14, 13, 0), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(gateFolder, "Beam", Vector3.new(36, 8, 9), CFrame.new(center) * rotation * CFrame.new(0, 24, 0), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(gateFolder, "Threshold", Vector3.new(38, 1, 14), CFrame.new(center) * rotation * CFrame.new(0, 0.5, 0), Color3.fromRGB(218, 214, 202), Enum.Material.Marble, nil, nil)

    local signOffset = Vector3.new(0, 0, 14)
    local signPosition = (CFrame.new(center) * rotation * CFrame.new(signOffset)).Position
    createWallPanel(gateFolder, "GateSign", signPosition, Vector3.new(40, 10, 2), title, subtitle, Color3.fromRGB(58, 90, 63), orientationY + 180, nil)
end

local function buildDesertRoute(parent: Instance, startPosition: Vector3, stopPosition: Vector3, endPosition: Vector3)
    local district = BuildUtils.CreateFolder(parent, "DesertRoute")
    local routeCenter = (startPosition + endPosition) * 0.5
    local routeLength = math.abs(endPosition.Z - startPosition.Z) + 420

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(900, 10, routeLength + 220), CFrame.new(routeCenter + Vector3.new(0, -9, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "DesertBase", Vector3.new(760, 4, routeLength), CFrame.new(routeCenter + Vector3.new(0, 2, 0)), DESERT_SAND, Enum.Material.Sand, nil, nil)
    BuildUtils.CreatePart(district, "TravelPath", Vector3.new(92, 1, routeLength - 140), CFrame.new(routeCenter + Vector3.new(0, 4.55, 0)), Color3.fromRGB(190, 160, 112), Enum.Material.Sandstone, nil, nil)

    local stepIndex = 0
    for z = startPosition.Z + 180, endPosition.Z - 160, 180 do
        stepIndex += 1
        local xShift = (stepIndex % 2 == 0) and 190 or -190
        BuildUtils.CreateDune(district, string.format("RouteDuneA_%d", stepIndex), Vector3.new(xShift, 0, z), Vector3.new(180, 40, 90), Color3.fromRGB(219, 190, 136))
        BuildUtils.CreateDune(district, string.format("RouteDuneB_%d", stepIndex), Vector3.new(xShift * -0.65, 0, z + 60), Vector3.new(130, 34, 82), Color3.fromRGB(211, 181, 129))
        BuildUtils.CreateRockCluster(district, string.format("RouteRocks_%d", stepIndex), Vector3.new(xShift * 0.58, 0, z - 32))
    end

    BuildUtils.CreatePart(district, "CampCourt", Vector3.new(210, 3, 170), CFrame.new(stopPosition + Vector3.new(0, 1.5, 0)), Color3.fromRGB(196, 173, 130), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "CampPath", Vector3.new(82, 1, 120), CFrame.new(stopPosition + Vector3.new(0, 3.55, -6)), Color3.fromRGB(222, 212, 190), Enum.Material.Sandstone, nil, nil)
    createTent(district, "CampTentWest", stopPosition + Vector3.new(-56, 0, 28), Color3.fromRGB(120, 88, 54))
    createTent(district, "CampTentEast", stopPosition + Vector3.new(56, 0, 28), Color3.fromRGB(135, 98, 59))
    BuildUtils.CreatePlanter(district, "OasisPlanter", stopPosition + Vector3.new(0, 0, -42), Vector3.new(56, 3, 46))
    BuildUtils.CreatePalmTree(district, "OasisPalmWest", stopPosition + Vector3.new(-18, 0, -44))
    BuildUtils.CreatePalmTree(district, "OasisPalmEast", stopPosition + Vector3.new(18, 0, -40))
    createLightPost(district, "CampLightWest", stopPosition + Vector3.new(-78, 0, -28))
    createLightPost(district, "CampLightEast", stopPosition + Vector3.new(78, 0, -28))
    createWallPanel(district, "CampSign", stopPosition + Vector3.new(0, 0, -76), Vector3.new(72, 12, 2.5), "Desert Route Camp", "A longer travel stretch now separates Makkah and Medina, with a mid-route camp for reflection and story stops.", Color3.fromRGB(111, 88, 58), 0, nil)
end

local function buildSupportLounge(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "SupportLounge")

    BuildUtils.CreatePart(district, "Floor", Vector3.new(130, 4, 90), CFrame.new(center + Vector3.new(0, 2, 0)), MECCA_MARBLE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "Counter", Vector3.new(60, 10, 16), CFrame.new(center + Vector3.new(0, 5, -25)), MECCA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "BackWall", Vector3.new(118, 28, 8), CFrame.new(center + Vector3.new(0, 14, -40)), MECCA_DARK, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "Roof", Vector3.new(138, 3, 96), CFrame.new(center + Vector3.new(0, 24, 0)), MECCA_STONE, Enum.Material.Marble, nil, nil)

    local leftScreen = createDigitalScreen(district, "SupportScreenLeft", center + Vector3.new(-28, 0, -34.8), Vector3.new(34, 18, 1.4), "Creator Ads", "Keep ad-ready screens and monetization boards in this outer lounge instead of the Kaaba center.")
    leftScreen.Orientation = Vector3.new(0, 180, 0)

    local rightScreen = createDigitalScreen(district, "SupportScreenRight", center + Vector3.new(28, 0, -34.8), Vector3.new(34, 18, 1.4), "Rewarded Video", "Use rewarded video here for battle ultimates or token bonuses once Creator Hub setup is complete.")
    rightScreen.Orientation = Vector3.new(0, 180, 0)

    createWallPanel(district, "SupportSign", center + Vector3.new(0, 0, 36), Vector3.new(74, 12, 2.5), "Creator Support Lounge", "Skins, support products, and ad screens live on the edge of the Makkah hub so the sacred center stays cleaner.", Color3.fromRGB(58, 91, 73), 0, nil)
    createLightPost(district, "SupportLightLeft", center + Vector3.new(-46, 0, 22))
    createLightPost(district, "SupportLightRight", center + Vector3.new(46, 0, 22))
end

local function buildStoryCourt(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "StoryCourt")

    BuildUtils.CreatePart(district, "Floor", Vector3.new(220, 4, 150), CFrame.new(center + Vector3.new(0, 2, 0)), MECCA_MARBLE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "InnerFloor", Vector3.new(180, 1, 112), CFrame.new(center + Vector3.new(0, 4.55, 0)), Color3.fromRGB(250, 244, 233), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "BackWall", Vector3.new(212, 22, 8), CFrame.new(center + Vector3.new(0, 11, -72)), MECCA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "RoofBand", Vector3.new(216, 4, 14), CFrame.new(center + Vector3.new(0, 22, -72)), MECCA_DARK, Enum.Material.Marble, nil, nil)

    createWallPanel(
        district,
        "StoryCourtSign",
        center + Vector3.new(0, 0, -66),
        Vector3.new(98, 12, 2.5),
        "Sahabi Story Playthroughs",
        "Choose a sahabi board, teleport into their scenario, and learn through guided NPC moments.",
        Color3.fromRGB(73, 96, 77),
        180,
        nil
    )

    local boardPositions = {
        center + Vector3.new(-52, 0, -10),
        center + Vector3.new(52, 0, -10),
        center + Vector3.new(-52, 0, 56),
        center + Vector3.new(52, 0, 56),
    }

    for index, story in ipairs(CompanionStories) do
        local board = BuildUtils.CreateBoardSign(
            district,
            string.format("StoryBoard_%s", story.Id),
            boardPositions[index],
            story.DisplayName,
            story.Theme,
            story.AccentColor,
            {
                ActionText = "Play Story",
                ObjectText = "Story Board",
                Attributes = {
                    PromptAction = "StartStory",
                    StoryId = story.Id,
                },
            }
        )
        board.Orientation = Vector3.new(0, 180, 0)
    end

    createLightPost(district, "StoryCourtLightWest", center + Vector3.new(-92, 0, 40), Color3.fromRGB(132, 112, 88))
    createLightPost(district, "StoryCourtLightEast", center + Vector3.new(92, 0, 40), Color3.fromRGB(132, 112, 88))
    BuildUtils.CreatePlanter(district, "StoryCourtPlanterWest", center + Vector3.new(-94, 0, -24), Vector3.new(26, 3, 18))
    BuildUtils.CreatePlanter(district, "StoryCourtPlanterEast", center + Vector3.new(94, 0, -24), Vector3.new(26, 3, 18))
    BuildUtils.CreatePalmTree(district, "StoryCourtPalmWest", center + Vector3.new(-94, 0, -24))
    BuildUtils.CreatePalmTree(district, "StoryCourtPalmEast", center + Vector3.new(94, 0, -24))
end

local function buildMannersCourt(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "MannersCourt")

    BuildUtils.CreatePart(district, "Floor", Vector3.new(230, 4, 162), CFrame.new(center + Vector3.new(0, 2, 0)), Color3.fromRGB(222, 213, 193), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "LearningCarpet", Vector3.new(176, 1, 106), CFrame.new(center + Vector3.new(0, 4.6, 0)), Color3.fromRGB(90, 119, 83), Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(district, "BackWall", Vector3.new(218, 23, 8), CFrame.new(center + Vector3.new(0, 11.5, -78)), Color3.fromRGB(206, 195, 171), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "RoofBand", Vector3.new(224, 4, 14), CFrame.new(center + Vector3.new(0, 24, -78)), Color3.fromRGB(98, 119, 76), Enum.Material.Marble, nil, nil)

    createWallPanel(
        district,
        "MannersCourtSign",
        center + Vector3.new(0, 0, -72),
        Vector3.new(108, 12, 2.5),
        "Manners Court",
        "Learn adab through short kid-friendly lessons. This section can grow into more playable scenarios later.",
        Color3.fromRGB(98, 119, 76),
        180,
        nil
    )

    local boardPositions = {
        center + Vector3.new(-72, 0, -18),
        center + Vector3.new(0, 0, -18),
        center + Vector3.new(72, 0, -18),
        center + Vector3.new(-36, 0, 50),
        center + Vector3.new(36, 0, 50),
    }

    for index, lesson in ipairs(MannersLessons) do
        local board = BuildUtils.CreateBoardSign(
            district,
            string.format("MannersBoard_%s", lesson.Id),
            boardPositions[index],
            lesson.DisplayName,
            lesson.Subtitle,
            lesson.AccentColor,
            {
                ActionText = "Learn",
                ObjectText = "Manners Lesson",
                Attributes = {
                    PromptAction = "OpenManners",
                    LessonId = lesson.Id,
                },
            }
        )
        board.Orientation = Vector3.new(0, 180, 0)
    end

    for _, offset in ipairs({
        Vector3.new(-92, 0, 52),
        Vector3.new(92, 0, 52),
        Vector3.new(-92, 0, -42),
        Vector3.new(92, 0, -42),
    }) do
        BuildUtils.CreatePlanter(district, string.format("MannersPlanter_%d_%d", offset.X, offset.Z), center + offset, Vector3.new(24, 3, 18))
        BuildUtils.CreatePalmTree(district, string.format("MannersPalm_%d_%d", offset.X, offset.Z), center + offset)
    end

    createLightPost(district, "MannersLightWest", center + Vector3.new(-108, 0, 18), Color3.fromRGB(128, 112, 89))
    createLightPost(district, "MannersLightEast", center + Vector3.new(108, 0, 18), Color3.fromRGB(128, 112, 89))
end

local function buildParkourCourse(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "ParkourCourse")

    BuildUtils.CreatePart(district, "BaseDeck", Vector3.new(160, 4, 100), CFrame.new(center + Vector3.new(0, 2, 0)), Color3.fromRGB(220, 210, 193), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "TowerCore", Vector3.new(28, 132, 28), CFrame.new(center + Vector3.new(0, 66, 0)), MECCA_DARK, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "TowerTop", Vector3.new(54, 4, 54), CFrame.new(center + Vector3.new(0, 134, 0)), Color3.fromRGB(237, 232, 221), Enum.Material.Marble, nil, nil)

    local platformOffsets = {
        Vector3.new(-34, 14, 0),
        Vector3.new(28, 24, -16),
        Vector3.new(-18, 34, -38),
        Vector3.new(38, 44, 6),
        Vector3.new(-36, 56, 24),
        Vector3.new(20, 68, 38),
        Vector3.new(-8, 80, -42),
        Vector3.new(42, 92, -12),
        Vector3.new(-40, 104, 8),
        Vector3.new(0, 118, 44),
    }

    for index, offset in ipairs(platformOffsets) do
        BuildUtils.CreatePart(
            district,
            string.format("Platform_%d", index),
            Vector3.new(18, 2, 18),
            CFrame.new(center + offset),
            (index % 2 == 0) and Color3.fromRGB(198, 181, 149) or Color3.fromRGB(232, 224, 209),
            Enum.Material.Marble,
            nil,
            nil
        )
    end

    BuildUtils.CreatePart(district, "StartPad", Vector3.new(24, 2, 24), CFrame.new(center + Vector3.new(-58, 6, 0)), Color3.fromRGB(94, 128, 88), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "FinishPad", Vector3.new(24, 2, 24), CFrame.new(center + Vector3.new(0, 138, 0)), Color3.fromRGB(182, 152, 84), Enum.Material.Marble, nil, nil)
    createWallPanel(
        district,
        "ParkourSign",
        center + Vector3.new(-44, 0, -34),
        Vector3.new(52, 11, 2.5),
        "Lobby Parkour",
        "Climb the tower while you wait for battles, stories, or friends.",
        Color3.fromRGB(63, 94, 66),
        90,
        nil
    )
    createWallPanel(
        district,
        "SummitSign",
        center + Vector3.new(0, 132, 18),
        Vector3.new(44, 10, 2.5),
        "Summit",
        "The top gives you a wide view over Makkah, the desert route, and Medina.",
        GOLD_ACCENT,
        180,
        nil
    )
createLightPost(district, "ParkourLightWest", center + Vector3.new(-62, 0, 32))
createLightPost(district, "ParkourLightEast", center + Vector3.new(62, 0, 32))
end

local function createDetailedKaaba(parent: Instance, center: Vector3)
    local baseY = 7.8
    local bodyHeight = 56
    local bodyHalf = 31
    local bodyCenterY = baseY + bodyHeight * 0.5
    local bandY = baseY + bodyHeight - 11
    local topY = baseY + bodyHeight
    local blackCloth = Color3.fromRGB(12, 12, 12)
    local blackPanel = Color3.fromRGB(22, 21, 20)
    local deepPanel = Color3.fromRGB(7, 7, 7)

    BuildUtils.CreatePart(parent, "KaabaFoundation", Vector3.new(84, 3, 84), CFrame.new(center + Vector3.new(0, 6.9, 0)), Color3.fromRGB(48, 46, 43), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaRaisedMarbleStep", Vector3.new(76, 1.4, 76), CFrame.new(center + Vector3.new(0, 9.1, 0)), Color3.fromRGB(224, 217, 201), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaMainBody", Vector3.new(bodyHalf * 2, bodyHeight, bodyHalf * 2), CFrame.new(center + Vector3.new(0, bodyCenterY, 0)), blackCloth, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaRoofLip", Vector3.new(66, 3.2, 66), CFrame.new(center + Vector3.new(0, topY + 1.6, 0)), Color3.fromRGB(18, 18, 17), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaTopTrim", Vector3.new(70, 1.2, 70), CFrame.new(center + Vector3.new(0, topY + 4, 0)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)

    BuildUtils.CreatePart(parent, "KaabaFrontClothPanel", Vector3.new(58, bodyHeight - 5, 0.7), CFrame.new(center + Vector3.new(0, bodyCenterY - 1, -bodyHalf - 0.45)), blackPanel, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaBackClothPanel", Vector3.new(58, bodyHeight - 5, 0.7), CFrame.new(center + Vector3.new(0, bodyCenterY - 1, bodyHalf + 0.45)), deepPanel, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaLeftClothPanel", Vector3.new(0.7, bodyHeight - 5, 58), CFrame.new(center + Vector3.new(-bodyHalf - 0.45, bodyCenterY - 1, 0)), blackPanel, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaRightClothPanel", Vector3.new(0.7, bodyHeight - 5, 58), CFrame.new(center + Vector3.new(bodyHalf + 0.45, bodyCenterY - 1, 0)), deepPanel, Enum.Material.Fabric, nil, nil)

    for _, side in ipairs({
        { Name = "Front", Size = Vector3.new(67, 3.2, 1), Offset = Vector3.new(0, bandY, -bodyHalf - 1) },
        { Name = "Back", Size = Vector3.new(67, 3.2, 1), Offset = Vector3.new(0, bandY, bodyHalf + 1) },
        { Name = "Left", Size = Vector3.new(1, 3.2, 67), Offset = Vector3.new(-bodyHalf - 1, bandY, 0) },
        { Name = "Right", Size = Vector3.new(1, 3.2, 67), Offset = Vector3.new(bodyHalf + 1, bandY, 0) },
    }) do
        BuildUtils.CreatePart(parent, string.format("KaabaKiswahBand%s", side.Name), side.Size, CFrame.new(center + side.Offset), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
    end

    for _, x in ipairs({ -22, -11, 11, 22 }) do
        BuildUtils.CreatePart(parent, string.format("KaabaFrontSeam_%d", x), Vector3.new(0.7, bodyHeight - 9, 0.82), CFrame.new(center + Vector3.new(x, bodyCenterY - 2, -bodyHalf - 1.05)), Color3.fromRGB(3, 3, 3), Enum.Material.Fabric, nil, nil)
        BuildUtils.CreatePart(parent, string.format("KaabaBackSeam_%d", x), Vector3.new(0.7, bodyHeight - 9, 0.82), CFrame.new(center + Vector3.new(x, bodyCenterY - 2, bodyHalf + 1.05)), Color3.fromRGB(3, 3, 3), Enum.Material.Fabric, nil, nil)
    end

    for _, z in ipairs({ -22, -11, 11, 22 }) do
        BuildUtils.CreatePart(parent, string.format("KaabaLeftSeam_%d", z), Vector3.new(0.82, bodyHeight - 9, 0.7), CFrame.new(center + Vector3.new(-bodyHalf - 1.05, bodyCenterY - 2, z)), Color3.fromRGB(3, 3, 3), Enum.Material.Fabric, nil, nil)
        BuildUtils.CreatePart(parent, string.format("KaabaRightSeam_%d", z), Vector3.new(0.82, bodyHeight - 9, 0.7), CFrame.new(center + Vector3.new(bodyHalf + 1.05, bodyCenterY - 2, z)), Color3.fromRGB(3, 3, 3), Enum.Material.Fabric, nil, nil)
    end

    BuildUtils.CreatePart(parent, "KaabaDoorGoldFrame", Vector3.new(12, 23, 1.4), CFrame.new(center + Vector3.new(0, baseY + 15.8, -bodyHalf - 1.8)), Color3.fromRGB(191, 151, 62), Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaDoorInset", Vector3.new(8.5, 18, 1.6), CFrame.new(center + Vector3.new(0, baseY + 15, -bodyHalf - 2.2)), Color3.fromRGB(145, 104, 37), Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaDoorCenterPattern", Vector3.new(1.2, 17, 1.8), CFrame.new(center + Vector3.new(0, baseY + 15, -bodyHalf - 2.5)), Color3.fromRGB(229, 197, 112), Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(parent, "KaabaDoorUpperPanel", Vector3.new(9.5, 4.4, 1.8), CFrame.new(center + Vector3.new(0, baseY + 23.2, -bodyHalf - 2.55)), Color3.fromRGB(230, 192, 90), Enum.Material.Metal, nil, nil)

    BuildUtils.CreateSphere(parent, "HajarAswadSilverFrame", 7.2, center + Vector3.new(bodyHalf + 0.6, baseY + 10.4, -bodyHalf - 0.6), Color3.fromRGB(205, 207, 203), Enum.Material.Metal, nil)
    BuildUtils.CreateSphere(parent, "HajarAswadMarker", 4.6, center + Vector3.new(bodyHalf + 1.1, baseY + 10.4, -bodyHalf - 1.1), Color3.fromRGB(8, 8, 8), Enum.Material.Slate, nil)
    BuildUtils.CreatePart(parent, "KaabaGoldSpoutMarker", Vector3.new(17, 1.3, 1.8), CFrame.new(center + Vector3.new(-bodyHalf - 8, topY + 0.4, 18)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)

    for index = 1, 8 do
        local angle = (math.pi * 2) * (index / 8)
        createLowBollard(parent, string.format("KaabaInnerLamp_%d", index), center + Vector3.new(math.cos(angle) * 54, 0, math.sin(angle) * 54), Color3.fromRGB(255, 226, 170))
    end
end

local function createGrandArcadeAccent(parent: Instance, center: Vector3, name: string, radius: number, count: number)
    for index = 1, count do
        local angle = (math.pi * 2) * (index / count)
        local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)

        BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Column_%d", name, index), 26, 2.6, position + Vector3.new(0, 17, 0), MECCA_MARBLE, Enum.Material.Marble, nil)

        if index % 2 == 0 then
            BuildUtils.CreatePart(parent, string.format("%s_Lantern_%d", name, index), Vector3.new(3.2, 5.2, 3.2), CFrame.new(position + Vector3.new(0, 33.5, 0)), Color3.fromRGB(255, 228, 175), Enum.Material.Neon, nil, 0.08)
        end
    end
end

local function buildKaabaHub(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "KaabaHub")

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(1420, 12, 1420), CFrame.new(center + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "ExpansionDeck", Vector3.new(1260, 4, 1260), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(207, 196, 176), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "StonePlaza", Vector3.new(1040, 4, 1040), CFrame.new(center + Vector3.new(0, 2.3, 0)), MECCA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "OuterWalk", Vector3.new(760, 1, 760), CFrame.new(center + Vector3.new(0, 4.85, 0)), MECCA_MARBLE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "InnerCourt", Vector3.new(520, 1, 520), CFrame.new(center + Vector3.new(0, 5.95, 0)), Color3.fromRGB(246, 241, 231), Enum.Material.Marble, nil, nil)

    createArcadeBlock(district, "NorthArcade", center + Vector3.new(0, 0, -292), 650, 92, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "SouthArcade", center + Vector3.new(0, 0, 292), 650, 92, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "WestArcade", center + Vector3.new(-292, 0, 0), 92, 530, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "EastArcade", center + Vector3.new(292, 0, 0), 92, 530, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "NorthOuterArcade", center + Vector3.new(0, 0, -560), 1020, 92, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "SouthOuterArcade", center + Vector3.new(0, 0, 560), 1020, 92, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "WestOuterArcade", center + Vector3.new(-560, 0, 0), 92, 1020, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createArcadeBlock(district, "EastOuterArcade", center + Vector3.new(560, 0, 0), 92, 1020, MECCA_MARBLE, MECCA_STONE, MECCA_STONE)
    createGrandArcadeAccent(district, center, "InnerColonnade", 238, 28)
    createGrandArcadeAccent(district, center, "OuterColonnade", 420, 36)

    BuildUtils.CreatePart(district, "NorthGate", Vector3.new(184, 42, 22), CFrame.new(center + Vector3.new(0, 21, -660)), MECCA_DARK, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "SouthGate", Vector3.new(184, 42, 22), CFrame.new(center + Vector3.new(0, 21, 660)), MECCA_DARK, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "EastGate", Vector3.new(22, 42, 184), CFrame.new(center + Vector3.new(660, 21, 0)), MECCA_DARK, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "WestGate", Vector3.new(22, 42, 184), CFrame.new(center + Vector3.new(-660, 21, 0)), MECCA_DARK, Enum.Material.Marble, nil, nil)

    createDetailedKaaba(district, center)

    createFloorInlayGrid(district, "MeccaMarbleInlay", center, 216, 36, Color3.fromRGB(213, 204, 184), 6.28)
    createRingTiles(district, "TawafGuideInner", center, 82, 48, Color3.fromRGB(216, 205, 180), 6.34)
    createRingTiles(district, "TawafGuideOuter", center, 132, 68, Color3.fromRGB(226, 218, 202), 6.36)
    createRingTiles(district, "TawafGuideWide", center, 196, 96, Color3.fromRGB(238, 231, 216), 6.38)
    createMaqamIbrahimMarker(district, center)
    createHijrIsmailMarker(district, center)
    createPrayerMatRows(district, "NorthPrayerMat", center + Vector3.new(0, 6.48, -386), 7, 24, 0, Color3.fromRGB(83, 118, 88))
    createPrayerMatRows(district, "SouthPrayerMat", center + Vector3.new(0, 6.48, 344), 7, 24, math.rad(180), Color3.fromRGB(83, 118, 88))
    createPrayerMatRows(district, "EastPrayerMat", center + Vector3.new(390, 6.48, -104), 7, 15, math.rad(90), Color3.fromRGB(98, 121, 96))
    createPrayerMatRows(district, "WestPrayerMat", center + Vector3.new(-390, 6.48, 104), 7, 15, math.rad(-90), Color3.fromRGB(98, 121, 96))

    for index = 1, 40 do
        local angle = (math.pi * 2) * (index / 40)
        createLowBollard(
            district,
            string.format("KaabaBollard_%d", index),
            center + Vector3.new(math.cos(angle) * 172, 0, math.sin(angle) * 172),
            Color3.fromRGB(255, 234, 185)
        )
    end

    for _, offset in ipairs({
        Vector3.new(-308, 0, -146),
        Vector3.new(308, 0, -146),
        Vector3.new(-308, 0, 146),
        Vector3.new(308, 0, 146),
        Vector3.new(-146, 0, -308),
        Vector3.new(146, 0, -308),
        Vector3.new(-146, 0, 308),
        Vector3.new(146, 0, 308),
        Vector3.new(-430, 0, 0),
        Vector3.new(430, 0, 0),
        Vector3.new(0, 0, -430),
        Vector3.new(0, 0, 430),
    }) do
        createLightPost(district, string.format("MeccaLight_%d_%d", offset.X, offset.Z), center + offset, Color3.fromRGB(128, 112, 89))
    end

    BuildUtils.CreateModernTower(district, "MakkahTowerWest", center + Vector3.new(-500, 0, -760), Vector2.new(58, 48), 184, Color3.fromRGB(210, 201, 186), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahTowerCenter", center + Vector3.new(0, 0, -812), Vector2.new(92, 64), 278, Color3.fromRGB(217, 209, 195), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahTowerEast", center + Vector3.new(500, 0, -760), Vector2.new(58, 48), 184, Color3.fromRGB(210, 201, 186), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahHotelSouthWest", center + Vector3.new(-720, 0, 600), Vector2.new(64, 54), 164, Color3.fromRGB(215, 208, 194), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahHotelSouthEast", center + Vector3.new(720, 0, 600), Vector2.new(64, 54), 164, Color3.fromRGB(215, 208, 194), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahClockHotelMarker", center + Vector3.new(0, 0, -930), Vector2.new(116, 70), 326, Color3.fromRGB(205, 198, 184), GLASS_TINT)
    BuildUtils.CreateMinaret(district, "MakkahNorthWestMinaret", center + Vector3.new(-386, 0, -386), 128, MECCA_MARBLE, GOLD_ACCENT)
    BuildUtils.CreateMinaret(district, "MakkahNorthEastMinaret", center + Vector3.new(386, 0, -386), 128, MECCA_MARBLE, GOLD_ACCENT)
    BuildUtils.CreateMinaret(district, "MakkahSouthWestMinaret", center + Vector3.new(-386, 0, 386), 112, MECCA_MARBLE, GOLD_ACCENT)
    BuildUtils.CreateMinaret(district, "MakkahSouthEastMinaret", center + Vector3.new(386, 0, 386), 112, MECCA_MARBLE, GOLD_ACCENT)
    BuildUtils.CreateMinaret(district, "MakkahFarNorthWestMinaret", center + Vector3.new(-610, 0, -610), 96, MECCA_MARBLE, GOLD_ACCENT)
    BuildUtils.CreateMinaret(district, "MakkahFarNorthEastMinaret", center + Vector3.new(610, 0, -610), 96, MECCA_MARBLE, GOLD_ACCENT)

    for rowIndex, z in ipairs({-226, 226}) do
        for columnIndex, x in ipairs({-226, -150, -74, 74, 150, 226}) do
            BuildUtils.CreateCourtyardCanopy(district, string.format("MeccaShade_%d_%d", rowIndex, columnIndex), center + Vector3.new(x, 0, z), Color3.fromRGB(244, 238, 224), Color3.fromRGB(158, 149, 134))
        end
    end

    createWallPanel(
        district,
        "BadrWallPanel",
        center + Vector3.new(-124, 0, -212),
        Vector3.new(54, 13, 2.5),
        "Battle of Badr",
        "Join Badr from the wall sign, fight the round, and then see the real story summary.",
        DARK_PANEL,
        180,
        {
            ActionText = "Join Badr",
            ObjectText = "Battle Sign",
            Attributes = {
                PromptAction = "JoinBattle",
                ScenarioId = "badr",
            },
        }
    )

    createWallPanel(
        district,
        "UhudWallPanel",
        center + Vector3.new(124, 0, -212),
        Vector3.new(54, 13, 2.5),
        "Battle of Uhud",
        "Join Uhud from the wall sign, fight the pass, and end with the history lesson.",
        DARK_PANEL,
        180,
        {
            ActionText = "Join Uhud",
            ObjectText = "Battle Sign",
            Attributes = {
                PromptAction = "JoinBattle",
                ScenarioId = "uhud",
            },
        }
    )

    createWallPanel(
        district,
        "MedinaTravelPanel",
        center + Vector3.new(-124, 0, 212),
        Vector3.new(54, 13, 2.5),
        "Travel To Medina",
        "Teleport to the Medina district or walk the full desert stretch between the two sacred cities.",
        Color3.fromRGB(57, 94, 62),
        0,
        {
            ActionText = "Go To Medina",
            ObjectText = "Travel Sign",
            Attributes = {
                PromptAction = "Teleport",
                DestinationId = "medina_courtyard",
            },
        }
    )

    createWallPanel(
        district,
        "DesertTravelPanel",
        center + Vector3.new(124, 0, 212),
        Vector3.new(54, 13, 2.5),
        "Desert Route",
        "Jump to the mid-route desert camp or walk the road to experience more space between Makkah and Medina.",
        Color3.fromRGB(114, 90, 60),
        0,
        {
            ActionText = "Open Desert Camp",
            ObjectText = "Travel Sign",
            Attributes = {
                PromptAction = "Teleport",
                DestinationId = "journey_reflection",
            },
        }
    )
end

local function buildMedinaDistrict(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "MedinaDistrict")

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(920, 12, 760), CFrame.new(center + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "OuterCourt", Vector3.new(620, 4, 500), CFrame.new(center + Vector3.new(0, 2, 0)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "InnerCourt", Vector3.new(470, 1, 350), CFrame.new(center + Vector3.new(0, 4.55, 10)), MEDINA_WHITE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "PrayerHall", Vector3.new(320, 28, 200), CFrame.new(center + Vector3.new(24, 14, -52)), MEDINA_WHITE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "PrayerHallRoof", Vector3.new(336, 4, 214), CFrame.new(center + Vector3.new(24, 30, -52)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "SouthPortico", Vector3.new(420, 20, 64), CFrame.new(center + Vector3.new(0, 10, 108)), MEDINA_WHITE, Enum.Material.Marble, nil, nil)
    createFloorInlayGrid(district, "MedinaMarbleInlay", center + Vector3.new(0, 0, 10), 172, 43, Color3.fromRGB(218, 216, 207), 5.2)
    createArcadeBlock(district, "MedinaWestArcade", center + Vector3.new(-212, 0, 0), 82, 380, MEDINA_WHITE, MEDINA_STONE, MEDINA_STONE)
    createArcadeBlock(district, "MedinaEastArcade", center + Vector3.new(212, 0, 0), 82, 380, MEDINA_WHITE, MEDINA_STONE, MEDINA_STONE)
    createArcadeBlock(district, "MedinaNorthArcade", center + Vector3.new(0, 0, -176), 418, 44, MEDINA_WHITE, MEDINA_STONE, MEDINA_STONE)

    BuildUtils.CreateVerticalCylinder(district, "GreenDomeDrum", 16, 12, center + Vector3.new(78, 38, -34), MEDINA_WHITE, Enum.Material.Marble, nil)
    BuildUtils.CreateSphere(district, "GreenDome", 26, center + Vector3.new(78, 52, -34), MEDINA_GREEN, Enum.Material.SmoothPlastic, nil)
    BuildUtils.CreatePart(district, "DomeSpire", Vector3.new(1, 9, 1), CFrame.new(center + Vector3.new(78, 67, -34)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)

    BuildUtils.CreateMinaret(district, "NorthWestMinaret", center + Vector3.new(-248, 0, -184), 88, MEDINA_WHITE, MEDINA_GREEN)
    BuildUtils.CreateMinaret(district, "NorthEastMinaret", center + Vector3.new(248, 0, -184), 88, MEDINA_WHITE, MEDINA_GREEN)
    BuildUtils.CreateMinaret(district, "SouthWestMinaret", center + Vector3.new(-248, 0, 182), 82, MEDINA_WHITE, MEDINA_GREEN)
    BuildUtils.CreateMinaret(district, "SouthEastMinaret", center + Vector3.new(248, 0, 182), 82, MEDINA_WHITE, MEDINA_GREEN)

    for rowIndex, z in ipairs({-18, 44, 106, 168}) do
        for columnIndex, x in ipairs({-166, -100, -34, 34, 100, 166}) do
            BuildUtils.CreateCourtyardCanopy(district, string.format("CourtyardCanopy_%d_%d", rowIndex, columnIndex), center + Vector3.new(x, 0, z), Color3.fromRGB(244, 243, 238), Color3.fromRGB(170, 171, 172))
        end
    end

    for columnIndex, x in ipairs({-112, -72, -32, 8, 48, 88, 128}) do
        BuildUtils.CreatePart(district, string.format("PrayerHallColumn_%d", columnIndex), Vector3.new(5, 26, 5), CFrame.new(center + Vector3.new(x, 13, -90)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(district, string.format("PrayerHallColumnBack_%d", columnIndex), Vector3.new(5, 26, 5), CFrame.new(center + Vector3.new(x, 13, -20)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    end

    BuildUtils.CreatePart(district, "RawdahPath", Vector3.new(220, 0.3, 18), CFrame.new(center + Vector3.new(-72, 5.05, -20)), Color3.fromRGB(89, 132, 82), Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(district, "RawdahArea", Vector3.new(126, 0.3, 28), CFrame.new(center + Vector3.new(8, 5.06, -20)), Color3.fromRGB(82, 125, 76), Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(district, "RawdahGoldEdgeA", Vector3.new(220, 0.35, 2), CFrame.new(center + Vector3.new(-72, 5.28, -30)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(district, "RawdahGoldEdgeB", Vector3.new(220, 0.35, 2), CFrame.new(center + Vector3.new(-72, 5.28, -10)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(district, "SacredChamberMarker", Vector3.new(32, 12, 22), CFrame.new(center + Vector3.new(56, 11, -20)), Color3.fromRGB(198, 184, 153), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "SacredChamberGrille", Vector3.new(34, 10, 2), CFrame.new(center + Vector3.new(39, 10, -20)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(district, "CompanionMarkerA", Vector3.new(6, 1, 6), CFrame.new(center + Vector3.new(56, 5.7, -26)), Color3.fromRGB(214, 204, 181), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "CompanionMarkerB", Vector3.new(6, 1, 6), CFrame.new(center + Vector3.new(56, 5.7, -20)), Color3.fromRGB(214, 204, 181), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "CompanionMarkerC", Vector3.new(6, 1, 6), CFrame.new(center + Vector3.new(56, 5.7, -14)), Color3.fromRGB(214, 204, 181), Enum.Material.Marble, nil, nil)

    createWallPanel(district, "VisitationSign", center + Vector3.new(-144, 0, -60), Vector3.new(74, 12, 2.5), "Bab as-Salam Visitation Route", "Enter from Bab as-Salam, follow the marked walkway, and approach the sacred chamber area respectfully and quietly.", Color3.fromRGB(52, 88, 58), 90, nil)
    createWallPanel(district, "ChamberSign", center + Vector3.new(120, 0, -64), Vector3.new(74, 12, 2.5), "Sacred Chamber Marker", "This is a respectful marker for the visitation area and route, not a 1:1 interior reconstruction.", Color3.fromRGB(86, 92, 67), 270, nil)

    createMedinaGate(district, "BabAsSalamGate", center + Vector3.new(-290, 0, -22), 90, "Bab as-Salam", "Traditional entry gate for the visitation route.")
    createMedinaGate(district, "BabAbuBakrGate", center + Vector3.new(-290, 0, 70), 90, "Bab Abu Bakr", "A west-side gate near the older visitation approach.")
    createMedinaGate(district, "BabRahmahGate", center + Vector3.new(-290, 0, -120), 90, "Bab ar-Rahmah", "A named western gate on the Medina side.")
    createMedinaGate(district, "BabJibrilGate", center + Vector3.new(290, 0, -24), 270, "Bab Jibril", "An eastern gate associated with the Jibril side of the mosque.")
    createMedinaGate(district, "BabBaqiGate", center + Vector3.new(290, 0, 72), 270, "Bab al-Baqi'", "An eastern gate toward the al-Baqi' side.")
    createMedinaGate(district, "BabNisaGate", center + Vector3.new(290, 0, 166), 270, "Bab an-Nisa", "A named gate on the eastern side of the Medina complex.")

    BuildUtils.CreatePlanter(district, "MedinaGardenWest", center + Vector3.new(-182, 0, 208), Vector3.new(64, 3, 34))
    BuildUtils.CreatePlanter(district, "MedinaGardenEast", center + Vector3.new(182, 0, 208), Vector3.new(64, 3, 34))
    BuildUtils.CreatePalmTree(district, "MedinaPalmWest", center + Vector3.new(-182, 0, 208))
    BuildUtils.CreatePalmTree(district, "MedinaPalmEast", center + Vector3.new(182, 0, 208))
end

local function buildBattleGate(parent: Instance, name: string, center: Vector3, accentColor: Color3, scenarioId: string, title: string)
    local district = BuildUtils.CreateFolder(parent, string.format("%sDistrict", name))

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(250, 12, 190), CFrame.new(center + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "Floor", Vector3.new(190, 4, 150), CFrame.new(center + Vector3.new(0, 2, 0)), Color3.fromRGB(205, 182, 141), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "LeftTower", Vector3.new(20, 30, 20), CFrame.new(center + Vector3.new(-58, 15, 0)), Color3.fromRGB(189, 167, 131), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "RightTower", Vector3.new(20, 30, 20), CFrame.new(center + Vector3.new(58, 15, 0)), Color3.fromRGB(189, 167, 131), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "GateBeam", Vector3.new(94, 9, 16), CFrame.new(center + Vector3.new(0, 25, 0)), accentColor, Enum.Material.Sandstone, nil, nil)
    createLightPost(district, string.format("%sLightLeft", name), center + Vector3.new(-20, 0, -34), Color3.fromRGB(120, 103, 80))
    createLightPost(district, string.format("%sLightRight", name), center + Vector3.new(20, 0, -34), Color3.fromRGB(120, 103, 80))

    createWallPanel(
        district,
        string.format("%sBoard", name),
        center + Vector3.new(0, 0, -54),
        Vector3.new(76, 12, 2.5),
        title,
        "Use this sign or the main menu to queue for the battle arena.",
        accentColor,
        180,
        {
            ActionText = "Join Battle",
            ObjectText = title,
            Attributes = {
                PromptAction = "JoinBattle",
                ScenarioId = scenarioId,
            },
        }
    )
end

local existingWorld = Workspace:FindFirstChild(TravelRoute.WorldFolderName)

if existingWorld and existingWorld:GetAttribute("GeneratedBy") == "HubWorldBuilder" then
    existingWorld:Destroy()
end

local worldFolder = Instance.new("Folder")
worldFolder.Name = TravelRoute.WorldFolderName
worldFolder:SetAttribute("GeneratedBy", "HubWorldBuilder")
worldFolder.Parent = Workspace

local geometryFolder = BuildUtils.CreateFolder(worldFolder, "Geometry")
local teleportFolder = BuildUtils.CreateFolder(worldFolder, "TeleportPoints")

BuildUtils.CreatePart(geometryFolder, "WorldGround", Vector3.new(2200, 2, 2600), CFrame.new(0, -1, 720), DESERT_SAND, Enum.Material.Sand, nil, nil)
BuildUtils.CreatePart(geometryFolder, "WorldSafetyPlate", Vector3.new(2400, 14, 2800), CFrame.new(0, -14, 720), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
createSafetyBounds(geometryFolder, "HubBounds", Vector3.new(0, 0, 720), Vector3.new(2360, 0, 2760))

for _, destination in ipairs(TravelRoute.Destinations) do
    BuildUtils.CreateTeleportAnchor(teleportFolder, destination.Id, destination.TeleportPosition or destination.Position)
end

local meccaCenter = TravelRoute.GetDestinationById("kaaba_courtyard").Position
local desertCenter = TravelRoute.GetDestinationById("journey_reflection").Position
local medinaCenter = TravelRoute.GetDestinationById("medina_courtyard").Position

buildDesertRoute(geometryFolder, meccaCenter, desertCenter, medinaCenter)
buildKaabaHub(geometryFolder, meccaCenter)
buildSupportLounge(geometryFolder, meccaCenter + Vector3.new(338, 0, -172))
buildStoryCourt(geometryFolder, meccaCenter + Vector3.new(346, 0, 214))
buildMannersCourt(geometryFolder, meccaCenter + Vector3.new(-346, 0, -360))
buildParkourCourse(geometryFolder, meccaCenter + Vector3.new(-358, 0, 196))
buildMedinaDistrict(geometryFolder, medinaCenter)
buildBattleGate(geometryFolder, "BadrGate", TravelRoute.GetDestinationById("badr_gate").Position, Color3.fromRGB(141, 107, 58), "badr", "Badr Gate")
buildBattleGate(geometryFolder, "UhudGate", TravelRoute.GetDestinationById("uhud_gate").Position, Color3.fromRGB(114, 92, 71), "uhud", "Uhud Gate")

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "JourneySpawn"
spawnLocation.Anchored = true
spawnLocation.Neutral = true
spawnLocation.Size = Vector3.new(18, 1, 18)
spawnLocation.Transparency = 1
spawnLocation.CanCollide = true
spawnLocation.CFrame = CFrame.new(meccaCenter + Vector3.new(0, 5, 92))
spawnLocation.Parent = geometryFolder
