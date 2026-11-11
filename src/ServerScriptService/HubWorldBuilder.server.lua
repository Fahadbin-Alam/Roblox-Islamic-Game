--!strict

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CompanionStories = require(Shared.Data.CompanionStories)
local HaramLearningTrail = require(Shared.Data.HaramLearningTrail)
local MannersLessons = require(Shared.Data.MannersLessons)
local TravelRoute = require(Shared.Data.TravelRoute)
local BuildUtils = require(script.Parent.Modules.BuildUtils)
local Decor = require(script.Parent.Modules.Decor)
local ParkourCourses = require(Shared.Data.ParkourCourses)
local MasjidAlHaram = require(script.Parent.Modules.MasjidAlHaram)

local MECCA_STONE = Color3.fromRGB(196, 186, 168)
local MECCA_MARBLE = Color3.fromRGB(214, 208, 196)
local MECCA_DARK = Color3.fromRGB(124, 106, 80)
local DESERT_SAND = Color3.fromRGB(188, 166, 121)
local DESERT_ROCK = Color3.fromRGB(138, 110, 80)
local MEDINA_WHITE = Color3.fromRGB(232, 231, 224)
local MEDINA_GREEN = Color3.fromRGB(77, 128, 88)
local MEDINA_STONE = Color3.fromRGB(214, 210, 198)
local GOLD_ACCENT = Color3.fromRGB(193, 162, 86)
local GLASS_TINT = Color3.fromRGB(108, 119, 132)

local function scaleColor(color: Color3, scale: number): Color3
    return Color3.fromRGB(
        math.clamp(math.floor(color.R * 255 * scale), 0, 255),
        math.clamp(math.floor(color.G * 255 * scale), 0, 255),
        math.clamp(math.floor(color.B * 255 * scale), 0, 255)
    )
end

local function makeDecorativePart(part: BasePart): BasePart
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = true

    return part
end

local function createStylizedRidge(parent: Instance, name: string, center: Vector3, yawDegrees: number, length: number, height: number, depth: number, color: Color3)
    local ridge = BuildUtils.CreateFolder(parent, name)
    local baseCFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(yawDegrees), 0)

    makeDecorativePart(BuildUtils.CreatePart(
        ridge,
        "MassCore",
        Vector3.new(length * 0.94, height * 0.34, depth * 0.82),
        baseCFrame * CFrame.new(0, height * 0.17, 0),
        scaleColor(color, 0.9),
        Enum.Material.Rock,
        nil,
        nil
    ))

    makeDecorativePart(BuildUtils.CreatePart(
        ridge,
        "MesaShelf",
        Vector3.new(length * 0.72, height * 0.18, depth * 0.58),
        baseCFrame * CFrame.new(0, height * 0.38, -depth * 0.02),
        scaleColor(color, 1.03),
        Enum.Material.Slate,
        nil,
        nil
    ))

    for segment = 1, 7 do
        local alpha = (segment - 4) / 3
        local widthFactor = 1 - math.abs(alpha) * 0.3
        local segmentLength = length * (0.13 + widthFactor * 0.035)
        local segmentHeight = height * (0.62 + widthFactor * 0.22)
        local segmentDepth = depth * (0.52 + widthFactor * 0.16)
        local x = alpha * length * 0.37
        local z = math.sin(segment * 1.11) * depth * 0.06
        local cframe = baseCFrame
            * CFrame.new(x, segmentHeight * 0.38, z)
            * CFrame.Angles(math.rad((segment % 3 - 1) * 3), math.rad((segment % 2 == 0) and -5 or 6), math.rad((segment % 4 - 1.5) * 2))

        makeDecorativePart(BuildUtils.CreateWedge(
            ridge,
            string.format("Face_%d", segment),
            Vector3.new(segmentLength, segmentHeight, segmentDepth),
            cframe,
            scaleColor(color, 0.8 + widthFactor * 0.18),
            Enum.Material.Rock,
            nil
        ))
    end

    for layer = 1, 3 do
        makeDecorativePart(BuildUtils.CreatePart(
            ridge,
            string.format("Strata_%d", layer),
            Vector3.new(length * (0.82 - layer * 0.12), 0.3, 1.4),
            baseCFrame * CFrame.new(0, height * (0.2 + layer * 0.17), depth * (-0.26 + layer * 0.14)) * CFrame.Angles(0, math.rad((layer % 2 == 0) and -4 or 5), 0),
            scaleColor(color, 0.6 + layer * 0.08),
            Enum.Material.Slate,
            nil,
            0.04
        ))
    end

    return ridge
end

local function createPromenadePath(parent: Instance, name: string, startPosition: Vector3, endPosition: Vector3, width: number, baseColor: Color3, edgeColor: Color3)
    local difference = endPosition - startPosition
    local length = difference.Magnitude

    if length < 1 then
        return
    end

    local midpoint = startPosition:Lerp(endPosition, 0.5)
    local yaw = math.atan2(difference.X, difference.Z)
    local baseY = math.max(startPosition.Y, endPosition.Y) + 4.3

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Base", name),
        Vector3.new(width, 0.9, length),
        CFrame.new(midpoint.X, baseY, midpoint.Z) * CFrame.Angles(0, yaw, 0),
        baseColor,
        Enum.Material.Sandstone,
        nil,
        nil
    )
    BuildUtils.CreatePart(
        parent,
        string.format("%s_EdgeWest", name),
        Vector3.new(2.2, 0.24, length),
        CFrame.new(midpoint.X, baseY + 0.48, midpoint.Z) * CFrame.Angles(0, yaw, 0) * CFrame.new(width * -0.5 + 1.1, 0, 0),
        edgeColor,
        Enum.Material.Slate,
        nil,
        nil
    ).CanCollide = false
    BuildUtils.CreatePart(
        parent,
        string.format("%s_EdgeEast", name),
        Vector3.new(2.2, 0.24, length),
        CFrame.new(midpoint.X, baseY + 0.48, midpoint.Z) * CFrame.Angles(0, yaw, 0) * CFrame.new(width * 0.5 - 1.1, 0, 0),
        edgeColor,
        Enum.Material.Slate,
        nil,
        nil
    ).CanCollide = false
    BuildUtils.CreatePart(
        parent,
        string.format("%s_Inlay", name),
        Vector3.new(6, 0.22, length - 18),
        CFrame.new(midpoint.X, baseY + 0.5, midpoint.Z) * CFrame.Angles(0, yaw, 0),
        Color3.fromRGB(231, 216, 181),
        Enum.Material.Marble,
        nil,
        nil
    ).CanCollide = false

    -- A palm and a lantern on each side, a third of the way along, so the walk is not bare.
    local top = baseY + 0.45
    local frame = CFrame.new(midpoint.X, top, midpoint.Z) * CFrame.Angles(0, yaw, 0)
    for _, side in ipairs({ -1, 1 }) do
        local palmAt = (frame * CFrame.new(side * (width * 0.5 - 4), 0, -length / 6)).Position
        Decor.Palm(parent, string.format("%s_Palm", name), palmAt, 18, #name + side, true)
        local lampAt = (frame * CFrame.new(side * (width * 0.5 - 3), 0, length / 6)).Position
        Decor.LanternPost(parent, string.format("%s_Lantern", name), lampAt, 10)
    end
end

local function createSafetyBounds(parent: Instance, namePrefix: string, center: Vector3, footprint: Vector3)
    local barrierHeight = 110
    local thickness = 12
    local barrierYOffset = 28

    -- Each wall is split in two halves because Roblox caps a part at 2048 studs per side.
    for _, wall in ipairs({
        { Name = "North", Offset = Vector3.new(0, 0, footprint.Z * -0.5), Along = Vector3.new(1, 0, 0), Length = footprint.X },
        { Name = "South", Offset = Vector3.new(0, 0, footprint.Z * 0.5), Along = Vector3.new(1, 0, 0), Length = footprint.X },
        { Name = "West", Offset = Vector3.new(footprint.X * -0.5, 0, 0), Along = Vector3.new(0, 0, 1), Length = footprint.Z },
        { Name = "East", Offset = Vector3.new(footprint.X * 0.5, 0, 0), Along = Vector3.new(0, 0, 1), Length = footprint.Z },
    }) do
        for half = -1, 1, 2 do
            local size = wall.Along * (wall.Length * 0.5) + Vector3.new(0, barrierHeight, 0) + (Vector3.new(1, 0, 1) - wall.Along) * thickness
            local position = center + wall.Offset + wall.Along * (half * wall.Length * 0.25) + Vector3.new(0, barrierYOffset, 0)
            BuildUtils.CreatePart(parent, string.format("%s_%sBarrier_%d", namePrefix, wall.Name, half), size, CFrame.new(position), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
        end
    end
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

local function createFloorPlaque(
    parent: Instance,
    name: string,
    cframe: CFrame,
    size: Vector3,
    title: string,
    subtitle: string,
    plaqueColor: Color3,
    promptData
): BasePart
    local plaque = BuildUtils.CreatePart(parent, name, size, cframe, plaqueColor, Enum.Material.Slate, nil, nil)
    plaque.CanCollide = false

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.CanvasSize = Vector2.new(760, 260)
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 46
    surfaceGui.Parent = plaque

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(24, 18)
    titleLabel.Size = UDim2.new(1, -48, 0, 92)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(250, 245, 230)
    titleLabel.TextScaled = true
    titleLabel.TextWrapped = true
    titleLabel.Parent = surfaceGui

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(28, 120)
    subtitleLabel.Size = UDim2.new(1, -56, 0, 112)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(222, 215, 196)
    subtitleLabel.TextScaled = true
    subtitleLabel.TextWrapped = true
    subtitleLabel.Parent = surfaceGui

    if promptData then
        BuildUtils.AttachPrompt(plaque, promptData.ActionText, promptData.ObjectText, promptData.Attributes)
    end

    return plaque
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

local function createLowBollard(parent: Instance, name: string, position: Vector3, accentColor: Color3)
    BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Post", name), 5.5, 0.45, position + Vector3.new(0, 2.75, 0), Color3.fromRGB(117, 102, 77), Enum.Material.Metal, nil)
    BuildUtils.CreateSphere(parent, string.format("%s_Glow", name), 1.7, position + Vector3.new(0, 5.8, 0), accentColor, Enum.Material.Neon, nil)
end

-- `skip` names ridges or aprons (e.g. "NorthFrame", "Apron_3") that would land inside a
-- neighbouring district.
local function createDistrictTerrainBand(parent: Instance, namePrefix: string, center: Vector3, radiusX: number, radiusZ: number, rockColor: Color3, skip: { [string]: boolean }?)
    local band = BuildUtils.CreateFolder(parent, string.format("%sTerrainBand", namePrefix))
    local skipped = skip or {}

    for index, ridge in ipairs({
        { Name = "WestNorthFrame", Offset = Vector3.new(-radiusX * 1.02, 0, -radiusZ * 0.52), Yaw = -20, Length = 360, Height = 122, Depth = 136 },
        { Name = "EastNorthFrame", Offset = Vector3.new(radiusX * 1.02, 0, -radiusZ * 0.48), Yaw = 18, Length = 350, Height = 118, Depth = 132 },
        { Name = "WestSouthFrame", Offset = Vector3.new(-radiusX * 0.98, 0, radiusZ * 0.58), Yaw = -16, Length = 374, Height = 126, Depth = 142 },
        { Name = "EastSouthFrame", Offset = Vector3.new(radiusX * 1.04, 0, radiusZ * 0.62), Yaw = 16, Length = 366, Height = 124, Depth = 140 },
        { Name = "NorthFrame", Offset = Vector3.new(0, 0, -radiusZ * 1.08), Yaw = 0, Length = 470, Height = 136, Depth = 108 },
        { Name = "SouthFrame", Offset = Vector3.new(0, 0, radiusZ * 1.12), Yaw = 180, Length = 500, Height = 142, Depth = 112 },
    }) do
        if skipped[ridge.Name] then
            continue
        end

        createStylizedRidge(
            band,
            string.format("%s_%s_%d", namePrefix, ridge.Name, index),
            center + ridge.Offset,
            ridge.Yaw,
            ridge.Length,
            ridge.Height,
            ridge.Depth,
            rockColor
        )
    end

    for index, apron in ipairs({
        { Offset = Vector3.new(-radiusX * 0.86, 5, 0), Size = Vector3.new(224, 12, 164), Yaw = -10 },
        { Offset = Vector3.new(radiusX * 0.86, 5, 0), Size = Vector3.new(224, 12, 164), Yaw = 10 },
        { Offset = Vector3.new(0, 4, -radiusZ * 0.94), Size = Vector3.new(300, 10, 118), Yaw = 0 },
        { Offset = Vector3.new(0, 4, radiusZ * 0.98), Size = Vector3.new(320, 10, 122), Yaw = 0 },
    }) do
        if skipped[string.format("Apron_%d", index)] then
            continue
        end

        makeDecorativePart(BuildUtils.CreatePart(
            band,
            string.format("%sApron_%d", namePrefix, index),
            apron.Size,
            CFrame.new(center + apron.Offset) * CFrame.Angles(0, math.rad(apron.Yaw), 0),
            scaleColor(rockColor, 1.08),
            Enum.Material.Sandstone,
            nil,
            nil
        ))
    end
end

local function createWorldBackdrop(parent: Instance, center: Vector3)
    local backdrop = BuildUtils.CreateFolder(parent, "WorldBackdrop")

    for index, ridge in ipairs({
        { Name = "FarNorthWest", Position = center + Vector3.new(-1560, 0, -1180), Length = 560, Height = 196, Depth = 194, Yaw = 16, Color = DESERT_ROCK },
        { Name = "FarNorth", Position = center + Vector3.new(0, 0, -1990), Length = 760, Height = 228, Depth = 186, Yaw = -2, Color = Color3.fromRGB(142, 114, 83) },
        { Name = "FarNorthEast", Position = center + Vector3.new(1120, 0, -1160), Length = 560, Height = 192, Depth = 190, Yaw = -16, Color = DESERT_ROCK },
        { Name = "FarWest", Position = center + Vector3.new(-1320, 0, 260), Length = 470, Height = 182, Depth = 214, Yaw = 26, Color = Color3.fromRGB(136, 108, 79) },
        { Name = "FarEast", Position = center + Vector3.new(1320, 0, 260), Length = 470, Height = 182, Depth = 214, Yaw = -24, Color = Color3.fromRGB(140, 112, 81) },
        { Name = "FarSouthWest", Position = center + Vector3.new(-1080, 0, 1290), Length = 540, Height = 184, Depth = 166, Yaw = 18, Color = DESERT_ROCK },
        { Name = "FarSouth", Position = center + Vector3.new(0, 0, 1360), Length = 760, Height = 208, Depth = 154, Yaw = 0, Color = Color3.fromRGB(146, 118, 86) },
        { Name = "FarSouthEast", Position = center + Vector3.new(1080, 0, 1290), Length = 540, Height = 184, Depth = 166, Yaw = -18, Color = DESERT_ROCK },
    }) do
        createStylizedRidge(backdrop, string.format("%sBackdrop_%d", ridge.Name, index), ridge.Position, ridge.Yaw, ridge.Length, ridge.Height, ridge.Depth, ridge.Color)
    end
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

    -- The sign stands beside the passage so it never blocks the way through the gate.
    local signOffset = Vector3.new(-30, 0, 10)
    local signPosition = (CFrame.new(center) * rotation * CFrame.new(signOffset)).Position
    createWallPanel(gateFolder, "GateSign", signPosition, Vector3.new(40, 10, 2), title, subtitle, Color3.fromRGB(58, 90, 63), orientationY + 180, nil)
end

local function makeCamelPart(part: BasePart)
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = true
end

local function createRideableCamel(parent: Instance, name: string, position: Vector3, orientationY: number)
    local camel = Instance.new("Model")
    camel.Name = name
    camel:SetAttribute("CamelSpeed", 46)
    camel:SetAttribute("CamelTurnRate", 2.2)
    camel:SetAttribute("StridePhase", (position.X + position.Z) * 0.013)
    camel.Parent = parent

    local baseCFrame = CFrame.new(position + Vector3.new(0, 13.5, 0)) * CFrame.Angles(0, math.rad(orientationY), 0)
    local bodyColor = Color3.fromRGB(171, 125, 76)
    local shadowColor = Color3.fromRGB(122, 82, 48)
    local clothColor = Color3.fromRGB(98, 87, 65)
    local saddleColor = Color3.fromRGB(73, 56, 41)

    local root = BuildUtils.CreatePart(camel, "CamelRoot", Vector3.new(2, 2, 2), baseCFrame, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = false
    camel.PrimaryPart = root

    for _, part in ipairs({
        BuildUtils.CreatePart(camel, "Body", Vector3.new(16, 6, 6), baseCFrame * CFrame.new(0, 1.2, 0), bodyColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreateWedge(camel, "Hump", Vector3.new(8, 5, 7), baseCFrame * CFrame.new(-1.6, 5.2, 0) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(149, 102, 61), Enum.Material.Fabric, nil),
        BuildUtils.CreatePart(camel, "Chest", Vector3.new(5.5, 5.5, 5.8), baseCFrame * CFrame.new(-7.2, 1.4, 0), bodyColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "Neck", Vector3.new(3.2, 9, 3), baseCFrame * CFrame.new(-10, 6.6, 0) * CFrame.Angles(0, 0, math.rad(-18)), bodyColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "Head", Vector3.new(5.6, 3.2, 3), baseCFrame * CFrame.new(-11.9, 10.8, 0), bodyColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "Muzzle", Vector3.new(2.8, 2, 2.4), baseCFrame * CFrame.new(-15.4, 10.3, 0), shadowColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "LeftEar", Vector3.new(0.8, 2.2, 0.7), baseCFrame * CFrame.new(-11.7, 13.1, -1.15) * CFrame.Angles(math.rad(12), 0, math.rad(-10)), shadowColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "RightEar", Vector3.new(0.8, 2.2, 0.7), baseCFrame * CFrame.new(-11.7, 13.1, 1.15) * CFrame.Angles(math.rad(-12), 0, math.rad(-10)), shadowColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "Tail", Vector3.new(1, 7, 1), baseCFrame * CFrame.new(8.8, 2.7, 0) * CFrame.Angles(0, 0, math.rad(34)), shadowColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "SaddleBlanket", Vector3.new(8.5, 0.7, 7.4), baseCFrame * CFrame.new(1.2, 5, 0), clothColor, Enum.Material.Fabric, nil, nil),
        BuildUtils.CreatePart(camel, "SaddleBack", Vector3.new(1.2, 2.4, 6.2), baseCFrame * CFrame.new(4.2, 6.1, 0), saddleColor, Enum.Material.Wood, nil, nil),
        BuildUtils.CreatePart(camel, "SaddleFront", Vector3.new(1.2, 2.1, 6.2), baseCFrame * CFrame.new(-2.4, 5.95, 0), saddleColor, Enum.Material.Wood, nil, nil),
    }) do
        makeCamelPart(part)
    end

    for index, localOffset in ipairs({
        Vector3.new(-5.2, -3.2, -2.1),
        Vector3.new(-5.2, -3.2, 2.1),
        Vector3.new(5.2, -3.2, -2.1),
        Vector3.new(5.2, -3.2, 2.1),
    }) do
        local leg = BuildUtils.CreatePart(camel, string.format("Leg_%d", index), Vector3.new(1.4, 9, 1.4), baseCFrame * CFrame.new(localOffset), shadowColor, Enum.Material.Fabric, nil, nil)
        local hoof = BuildUtils.CreatePart(camel, string.format("Hoof_%d", index), Vector3.new(2.4, 0.8, 2.2), baseCFrame * CFrame.new(localOffset + Vector3.new(0, -4.9, 0)), Color3.fromRGB(79, 58, 42), Enum.Material.Slate, nil, nil)
        makeCamelPart(leg)
        makeCamelPart(hoof)
    end

    local seat = Instance.new("VehicleSeat")
    seat.Name = "CamelSeat"
    seat.Anchored = true
    seat.CanCollide = false
    seat.CanTouch = true
    seat.CanQuery = true
    seat.Transparency = 1
    seat.Size = Vector3.new(5.8, 1.2, 4.8)
    seat.CFrame = baseCFrame * CFrame.new(1.1, 6.2, 0)
    seat.Parent = camel
    seat:SetAttribute("PromptAction", "RideCamel")

    local marker = BuildUtils.CreatePart(camel, "PromptMarker", Vector3.new(5.6, 0.5, 5.6), baseCFrame * CFrame.new(1.1, -2.8, 0), Color3.fromRGB(214, 178, 99), Enum.Material.Metal, nil, 0.18)
    makeCamelPart(marker)
    BuildUtils.AttachPrompt(marker, "Ride Camel", "Travel Mount", {
        PromptAction = "RideCamel",
    })

    CollectionService:AddTag(camel, "RideableCamel")

    return camel
end

local function buildDesertRoute(parent: Instance, startPosition: Vector3, stopPosition: Vector3, endPosition: Vector3)
    local district = BuildUtils.CreateFolder(parent, "DesertRoute")
    local routeEntryPosition = Vector3.new(startPosition.X, startPosition.Y, startPosition.Z + 820)
    local routeCenter = (routeEntryPosition + endPosition) * 0.5
    local routeLength = math.abs(endPosition.Z - routeEntryPosition.Z) + 220

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(1020, 10, routeLength + 260), CFrame.new(routeCenter + Vector3.new(0, -9, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "DesertBase", Vector3.new(860, 4, routeLength), CFrame.new(routeCenter + Vector3.new(0, 2, 0)), DESERT_SAND, Enum.Material.Sand, nil, nil)
    BuildUtils.CreateDune(district, "RouteLongWestDune", routeCenter + Vector3.new(-220, 0, -120), Vector3.new(420, 62, routeLength * 0.42), Color3.fromRGB(204, 179, 132))
    BuildUtils.CreateDune(district, "RouteLongEastDune", routeCenter + Vector3.new(226, 0, 160), Vector3.new(440, 66, routeLength * 0.45), Color3.fromRGB(199, 175, 129))
    BuildUtils.CreatePart(district, "TravelPath", Vector3.new(102, 1, routeLength - 140), CFrame.new(routeCenter + Vector3.new(0, 4.55, 0)), Color3.fromRGB(182, 154, 110), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "TravelPathCenterInlay", Vector3.new(7, 0.24, routeLength - 180), CFrame.new(routeCenter + Vector3.new(0, 5.16, 0)), Color3.fromRGB(232, 212, 168), Enum.Material.Marble, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "TravelPathWestEdge", Vector3.new(3, 0.24, routeLength - 180), CFrame.new(routeCenter + Vector3.new(-51, 5.18, 0)), Color3.fromRGB(133, 108, 76), Enum.Material.Slate, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "TravelPathEastEdge", Vector3.new(3, 0.24, routeLength - 180), CFrame.new(routeCenter + Vector3.new(51, 5.18, 0)), Color3.fromRGB(133, 108, 76), Enum.Material.Slate, nil, nil).CanCollide = false

    local camelFolder = BuildUtils.CreateFolder(district, "RouteCamels")
    createRideableCamel(camelFolder, "MakkahRouteCamel", routeEntryPosition + Vector3.new(-78, 0, 186), 0)
    createRideableCamel(camelFolder, "DesertRouteCamel", stopPosition + Vector3.new(98, 0, -96), 180)
    createRideableCamel(camelFolder, "MedinaRouteCamel", endPosition + Vector3.new(82, 0, -206), 180)

    local mountainFolder = BuildUtils.CreateFolder(district, "RouteMountainWalls")
    local mountainIndex = 0

    for z = routeEntryPosition.Z + 220, endPosition.Z - 260, 460 do
        mountainIndex += 1
        local heightOffset = (mountainIndex % 3) * 12
        createStylizedRidge(mountainFolder, string.format("WestRouteMountain_%d", mountainIndex), Vector3.new(-356, 0, z), 22, 238 + heightOffset * 1.8, 98 + heightOffset, 98, DESERT_ROCK)
        createStylizedRidge(mountainFolder, string.format("EastRouteMountain_%d", mountainIndex), Vector3.new(356, 0, z + 88), -24, 252 + heightOffset * 1.8, 104 + heightOffset, 102, Color3.fromRGB(157, 126, 88))
        createStylizedRidge(mountainFolder, string.format("RouteMidRidge_%d", mountainIndex), Vector3.new(((mountainIndex % 2 == 0) and -1 or 1) * 252, 0, z - 128), (mountainIndex % 2 == 0) and -10 or 10, 170 + heightOffset, 54 + heightOffset * 0.45, 74, Color3.fromRGB(145, 117, 85))
    end

    local lampIndex = 0

    for z = routeEntryPosition.Z + 170, endPosition.Z - 210, 280 do
        lampIndex += 1
        createLowBollard(district, string.format("RouteGuideLampWest_%d", lampIndex), Vector3.new(-66, 0, z), Color3.fromRGB(255, 229, 170))
        createLowBollard(district, string.format("RouteGuideLampEast_%d", lampIndex), Vector3.new(66, 0, z), Color3.fromRGB(255, 229, 170))
    end

    local stepIndex = 0
    for z = routeEntryPosition.Z + 160, endPosition.Z - 160, 220 do
        stepIndex += 1
        local xShift = (stepIndex % 2 == 0) and 190 or -190
        BuildUtils.CreateDune(district, string.format("RouteDuneA_%d", stepIndex), Vector3.new(xShift, 0, z), Vector3.new(180, 40, 90), Color3.fromRGB(219, 190, 136))
        BuildUtils.CreateDune(district, string.format("RouteDuneB_%d", stepIndex), Vector3.new(xShift * -0.65, 0, z + 60), Vector3.new(130, 34, 82), Color3.fromRGB(211, 181, 129))
        makeDecorativePart(BuildUtils.CreatePart(
            district,
            string.format("RouteShoulder_%d", stepIndex),
            Vector3.new(78, 12, 34),
            CFrame.new(Vector3.new(xShift * 0.58, 8, z - 28)) * CFrame.Angles(0, math.rad((stepIndex % 2 == 0) and -18 or 18), 0),
            Color3.fromRGB(165, 136, 96),
            Enum.Material.Sandstone,
            nil,
            nil
        ))
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
    createWallPanel(district, "MakkahRouteStartSign", routeEntryPosition + Vector3.new(0, 0, 96), Vector3.new(76, 12, 2.5), "Makkah To Medina Route", "Ride a camel or follow the lamp markers. This long path teaches distance and migration without depicting the Prophet.", Color3.fromRGB(105, 83, 55), 0, nil)
    createWallPanel(district, "CampSign", stopPosition + Vector3.new(0, 0, -76), Vector3.new(72, 12, 2.5), "Desert Route Camp", "A longer travel stretch now separates Makkah and Medina, with a mid-route camp for reflection and story stops.", Color3.fromRGB(111, 88, 58), 0, nil)
    createWallPanel(district, "MedinaRouteArrivalSign", endPosition + Vector3.new(0, 0, -132), Vector3.new(76, 12, 2.5), "Medina Approach", "The route ends at a green-and-white Medina district with gates, courtyard markers, and a respectful visitation path.", Color3.fromRGB(58, 91, 66), 180, nil)

    -- A Bedouin camp and a small palm oasis at the mid-route stop, and scrub and boulders along
    -- the way. All of it stands clear of the path (|x| < 51) and the camp court entrance.
    local camp = BuildUtils.CreateFolder(district, "CampDressing")
    -- The desert surface along the route is 4 studs above the route points.
    local campFloor = stopPosition + Vector3.new(0, 4, 0)
    Decor.Tent(camp, "GoatHairTentWest", CFrame.new(campFloor + Vector3.new(-80, 0, 58)) * CFrame.Angles(0, math.rad(180), 0), 20, 3)
    Decor.Tent(camp, "GoatHairTentEast", CFrame.new(campFloor + Vector3.new(80, 0, 58)) * CFrame.Angles(0, math.rad(180), 0), 18, 7)
    Decor.Well(camp, "CampWell", campFloor + Vector3.new(-60, 0, -40))
    Decor.Camel(camp, "RestingCamelA", CFrame.new(campFloor + Vector3.new(-88, 0, 10)) * CFrame.Angles(0, math.rad(80), 0), 1)
    Decor.Camel(camp, "RestingCamelB", CFrame.new(campFloor + Vector3.new(90, 0, 4)) * CFrame.Angles(0, math.rad(-100), 0), 2)

    for index = 1, 3 do
        Decor.Rug(camp, "CampRug", CFrame.new(campFloor + Vector3.new(-20 + index * 10, 0, 62)) * CFrame.Angles(0, index * 0.3, 0), 6, 9, index)
    end

    for index = 1, 9 do
        local angle = index * 0.7
        Decor.Palm(camp, "OasisPalm", campFloor + Vector3.new(130 + math.cos(angle) * 30, 0, -10 + math.sin(angle) * 40), 18 + index % 4 * 2, index * 13, true)
        Decor.Palm(camp, "OasisPalm", campFloor + Vector3.new(-140 + math.cos(angle) * 26, 0, 30 + math.sin(angle) * 34), 17 + index % 3 * 2, index * 17, true)
    end

    local scrub = BuildUtils.CreateFolder(district, "RouteScrub")
    local stepZ = 0

    for z = routeEntryPosition.Z + 120, endPosition.Z - 200, 70 do
        stepZ += 1
        local side = if stepZ % 2 == 0 then 1 else -1
        local x = side * (80 + (stepZ * 37) % 90)

        if math.abs(z - stopPosition.Z) > 110 then
            if stepZ % 3 == 0 then
                Decor.Rocks(scrub, "RouteBoulders", Vector3.new(x, 8, z), 5 + stepZ % 4, stepZ)
            else
                Decor.Shrub(scrub, "RouteShrub", Vector3.new(x, 8, z), stepZ)
            end
        end
    end
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

-- Shared dressing for the learning courts: arched niches and battlements along the back wall,
-- and shaded colonnades down both sides. Columns are spaced 24 apart so the sides stay open.
local function dressCourt(district: Instance, center: Vector3, width: number, depth: number, backZ: number, wallHeight: number, accent: Color3)
    local dress = BuildUtils.CreateFolder(district, "Dressing")
    local face = backZ + 4.3
    local bays = 9
    local bay = (width - 20) / bays

    for index = 1, bays do
        local x = -(width - 20) / 2 + (index - 0.5) * bay
        Decor.Deco(dress, "NicheRecess", Vector3.new(bay - 6, wallHeight - 9, 0.4), CFrame.new(center + Vector3.new(x, 4 + (wallHeight - 9) / 2 + 1, face)), Color3.fromRGB(184, 172, 150), Enum.Material.Marble)
        Decor.Deco(dress, "NicheArch", Vector3.new(0.5, bay - 6, bay - 6), CFrame.new(center + Vector3.new(x, 4 + wallHeight - 8, face)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(184, 172, 150), Enum.Material.Marble, Enum.PartType.Cylinder)
        Decor.Deco(dress, "NicheTile", Vector3.new(bay - 9, 1.2, 0.5), CFrame.new(center + Vector3.new(x, 7, face + 0.1)), accent, Enum.Material.Glass)
    end

    for index = 1, math.floor(width / 10) do
        local x = -width / 2 + (index - 0.5) * (width / math.floor(width / 10))
        Decor.Deco(dress, "Merlon", Vector3.new(3.4, 3, 3), CFrame.new(center + Vector3.new(x, wallHeight + 4 + 1.5, backZ)), Color3.fromRGB(206, 195, 171), Enum.Material.Marble)
    end

    for _, side in ipairs({ -1, 1 }) do
        local x = side * (width / 2 - 3)
        local zFrom, zTo = backZ + 14, depth / 2 - 8

        for z = zFrom, zTo, 24 do
            BuildUtils.CreateVerticalCylinder(dress, "Colonnade", 16, 1.1, center + Vector3.new(x, 12, z), Color3.fromRGB(236, 230, 216), Enum.Material.Marble, nil)
            Decor.Deco(dress, "ColonnadeCapital", Vector3.new(3.2, 1.4, 3.2), CFrame.new(center + Vector3.new(x, 20.4, z)), GOLD_ACCENT, Enum.Material.Metal)
        end

        Decor.Deco(dress, "ColonnadeBeam", Vector3.new(4, 2, zTo - zFrom + 4), CFrame.new(center + Vector3.new(x, 22, (zFrom + zTo) / 2)), Color3.fromRGB(206, 195, 171), Enum.Material.Marble)
        Decor.Deco(dress, "ColonnadeShade", Vector3.new(16, 0.3, zTo - zFrom), CFrame.new(center + Vector3.new(x - side * 8, 21, (zFrom + zTo) / 2)) * CFrame.Angles(0, 0, math.rad(side * 10)), Color3.fromRGB(244, 240, 228), Enum.Material.Fabric)

        -- Seating under the colonnade: rugs with cushions, and a lantern at each end.
        for index, z in ipairs({ backZ + 30, (backZ + depth / 2) / 2 + 10 }) do
            local rugAt = center + Vector3.new(x - side * 9, 5.1, z)
            Decor.Rug(dress, "CourtRug", CFrame.new(rugAt), 8, 14, index + (if side < 0 then 0 else 4))
            for cushion = -1, 1, 2 do
                Decor.Deco(dress, "Cushion", Vector3.new(2.2, 1, 3), CFrame.new(rugAt + Vector3.new(side * 3, 0.6, cushion * 4)), accent, Enum.Material.Fabric)
            end
        end
        Decor.LanternPost(dress, "CourtLantern", center + Vector3.new(x - side * 4, 5, depth / 2 - 14), 10)
    end

    -- Floor inlay: a border band and an eight-pointed star in the middle of the court.
    local inlayY = 5.12
    local inner = Vector3.new(width - 44, 0, depth - 46)
    local band = Color3.fromRGB(196, 184, 160)
    for _, edge in ipairs({
        { Size = Vector3.new(inner.X, 0.12, 1.6), Offset = Vector3.new(0, 0, inner.Z / 2) },
        { Size = Vector3.new(inner.X, 0.12, 1.6), Offset = Vector3.new(0, 0, -inner.Z / 2) },
        { Size = Vector3.new(1.6, 0.12, inner.Z), Offset = Vector3.new(inner.X / 2, 0, 0) },
        { Size = Vector3.new(1.6, 0.12, inner.Z), Offset = Vector3.new(-inner.X / 2, 0, 0) },
    }) do
        Decor.Deco(dress, "InlayBorder", edge.Size, CFrame.new(center + edge.Offset + Vector3.new(0, inlayY, (backZ + depth / 2) / 2 - 0)), band, Enum.Material.Marble)
    end
    local starAt = center + Vector3.new(0, inlayY, (backZ + depth / 2) / 2)
    for turn = 0, 1 do
        Decor.Deco(dress, "InlayStar", Vector3.new(22, 0.14, 22), CFrame.new(starAt) * CFrame.Angles(0, math.rad(45 * turn), 0), band, Enum.Material.Marble)
        Decor.Deco(dress, "InlayStarCore", Vector3.new(15, 0.16, 15), CFrame.new(starAt) * CFrame.Angles(0, math.rad(45 * turn), 0), accent, Enum.Material.Marble)
    end
    Decor.Deco(dress, "InlayStarEye", Vector3.new(0.18, 8, 8), CFrame.new(starAt + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 232, 214), Enum.Material.Marble, Enum.PartType.Cylinder)
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
        center + Vector3.new(-72, 0, -14),
        center + Vector3.new(0, 0, -14),
        center + Vector3.new(72, 0, -14),
        center + Vector3.new(-36, 0, 56),
        center + Vector3.new(36, 0, 56),
    }

    for index, story in ipairs(CompanionStories) do
        local boardPosition = boardPositions[index] or (center + Vector3.new(-72 + ((index - 1) % 3) * 72, 0, 56 + math.floor((index - 1) / 3) * 70))
        local board = BuildUtils.CreateBoardSign(
            district,
            string.format("StoryBoard_%s", story.Id),
            boardPosition,
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

    dressCourt(district, center, 220, 150, -72, 22, Color3.fromRGB(73, 96, 77))
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

    dressCourt(district, center, 230, 162, -78, 23, Color3.fromRGB(98, 119, 76))
end

local function buildTriviaCourt(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "TriviaCourt")

    BuildUtils.CreatePart(district, "Floor", Vector3.new(238, 4, 168), CFrame.new(center + Vector3.new(0, 2, 0)), Color3.fromRGB(224, 216, 198), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "CenterCarpet", Vector3.new(174, 1, 106), CFrame.new(center + Vector3.new(0, 4.6, 8)), Color3.fromRGB(63, 98, 88), Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(district, "QuizLineGold", Vector3.new(166, 0.35, 3), CFrame.new(center + Vector3.new(0, 5.22, -30)), GOLD_ACCENT, Enum.Material.Metal, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "QuizLineGreen", Vector3.new(166, 0.35, 3), CFrame.new(center + Vector3.new(0, 5.24, 46)), Color3.fromRGB(93, 130, 102), Enum.Material.Metal, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "BackWall", Vector3.new(226, 24, 8), CFrame.new(center + Vector3.new(0, 12, -82)), Color3.fromRGB(206, 195, 171), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "RoofBand", Vector3.new(232, 4, 14), CFrame.new(center + Vector3.new(0, 24, -82)), Color3.fromRGB(63, 98, 88), Enum.Material.Marble, nil, nil)

    createWallPanel(
        district,
        "TriviaStartPanel",
        center + Vector3.new(0, 0, -76),
        Vector3.new(118, 13, 2.5),
        "Islamic Trivia Challenge",
        "Compete with everyone on the server. Questions start easy, then get harder each round.",
        Color3.fromRGB(63, 98, 88),
        180,
        {
            ActionText = "Start Trivia",
            ObjectText = "Trivia Court",
            Attributes = {
                PromptAction = "StartTrivia",
            },
        }
    )

    local podiums: { any } = {
        {
            Name = "BasicsPodium",
            Offset = Vector3.new(-68, 0, 12),
            Color = Color3.fromRGB(92, 119, 82),
            Title = "Islamic Studies",
            Body = "Pillars, salah, duas, and Prophets.",
            CirclePrompt = true,
            Prompt = {
                ActionText = "Study",
                ObjectText = "Islamic Studies",
                Attributes = {
                    PromptAction = "OpenLearningHall",
                },
            },
        },
        { Name = "SeerahPodium", Offset = Vector3.new(0, 0, 22), Color = Color3.fromRGB(121, 94, 63), Title = "Seerah", Body = "Hijrah, Badr, Uhud, and Medina." },
        { Name = "SahabiPodium", Offset = Vector3.new(68, 0, 12), Color = Color3.fromRGB(112, 98, 64), Title = "Sahabi", Body = "Companions and big story moments." },
    }

    for _, podium in ipairs(podiums) do
        local base = BuildUtils.CreatePart(district, string.format("%s_Base", podium.Name), Vector3.new(48, 6, 30), CFrame.new(center + podium.Offset + Vector3.new(0, 3, 0)), podium.Color, Enum.Material.Sandstone, nil, nil)
        BuildUtils.CreatePart(district, string.format("%s_Glow", podium.Name), Vector3.new(42, 0.5, 24), CFrame.new(center + podium.Offset + Vector3.new(0, 6.35, 0)), Color3.fromRGB(245, 217, 153), Enum.Material.Neon, nil, 0.28).CanCollide = false
        local board = BuildUtils.CreateBoardSign(district, podium.Name, center + podium.Offset + Vector3.new(0, 0, 28), podium.Title, podium.Body, podium.Color, podium.Prompt)
        board.Orientation = Vector3.new(0, 180, 0)

        if podium.CirclePrompt then
            local circlePrompt = BuildUtils.AttachPrompt(base, "Start Study Circle", "Group Lesson", {
                PromptAction = "StartStudyCircle",
            })
            circlePrompt.MaxActivationDistance = 26
        end
    end

    createLightPost(district, "TriviaLightWest", center + Vector3.new(-104, 0, -28), Color3.fromRGB(118, 105, 84))
    createLightPost(district, "TriviaLightEast", center + Vector3.new(104, 0, -28), Color3.fromRGB(118, 105, 84))
    BuildUtils.CreatePlanter(district, "TriviaPlanterWest", center + Vector3.new(-104, 0, 50), Vector3.new(28, 3, 20))
    BuildUtils.CreatePlanter(district, "TriviaPlanterEast", center + Vector3.new(104, 0, 50), Vector3.new(28, 3, 20))
    BuildUtils.CreatePalmTree(district, "TriviaPalmWest", center + Vector3.new(-104, 0, 50))
    BuildUtils.CreatePalmTree(district, "TriviaPalmEast", center + Vector3.new(104, 0, 50))

    dressCourt(district, center, 238, 168, -82, 24, Color3.fromRGB(63, 98, 88))
end

local function buildParkourCourse(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "ParkourCourse")
    local course = ParkourCourses.LobbyTower

    BuildUtils.CreatePart(district, "BaseDeck", Vector3.new(160, 4, 100), CFrame.new(center + Vector3.new(0, 2, 0)), Color3.fromRGB(220, 210, 193), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "TowerCore", course.CoreSize, CFrame.new(center + Vector3.new(0, 4 + course.CoreSize.Y / 2, 0)), MECCA_DARK, Enum.Material.Marble, nil, nil)
    BuildUtils.CreateVerticalCylinder(district, "TowerTop", course.SummitThickness, course.SummitRadius, center + Vector3.new(0, course.SummitHeight - course.SummitThickness / 2, 0), Color3.fromRGB(237, 232, 221), Enum.Material.Marble, nil)

    -- A spiral of steps around the core (see Shared/Data/ParkourCourses; the unit tests check
    -- every jump is possible with default movement). Checkpoint steps are gold.
    local checkpointPlatforms = {}

    for _, checkpoint in ipairs(course.Checkpoints) do
        checkpointPlatforms[checkpoint.Offset] = true
    end

    for index, platform in ipairs(course.Platforms) do
        local isCheckpoint = checkpointPlatforms[platform.Offset] == true
        local color = if isCheckpoint then Color3.fromRGB(214, 178, 99) elseif index % 4 == 0 then Color3.fromRGB(150, 120, 86) elseif index % 2 == 0 then Color3.fromRGB(198, 181, 149) else Color3.fromRGB(232, 224, 209)
        BuildUtils.CreatePart(
            district,
            string.format("Platform_%d", index),
            platform.Size,
            CFrame.new(center + platform.Offset - Vector3.new(0, platform.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(platform.Yaw), 0),
            color,
            Enum.Material.Marble,
            nil,
            nil
        )
    end

    BuildUtils.CreatePart(district, "StartPad", course.StartSize, CFrame.new(center + course.StartOffset - Vector3.new(0, course.StartSize.Y / 2, 0)), Color3.fromRGB(94, 128, 88), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "FinishPad", Vector3.new(12, 0.4, 12), CFrame.new(center + Vector3.new(0, course.SummitHeight + 0.2, 0)), Color3.fromRGB(182, 152, 84), Enum.Material.Marble, nil, nil).CanCollide = false
    createWallPanel(
        district,
        "ParkourSign",
        center + Vector3.new(-62, 0, -34),
        Vector3.new(52, 11, 2.5),
        "Lobby Parkour",
        "Step on the green pad to start the timer. Gold steps are checkpoints: fall and you return to the last one.",
        Color3.fromRGB(63, 94, 66),
        90,
        nil
    )
    createWallPanel(
        district,
        "SummitSign",
        center + Vector3.new(0, course.SummitHeight, 12),
        Vector3.new(30, 8, 2),
        "Summit",
        "The top gives you a wide view over Makkah, the desert route, and Medina.",
        GOLD_ACCENT,
        180,
        nil
    )
    createLightPost(district, "ParkourLightWest", center + Vector3.new(-62, 0, 32))
    createLightPost(district, "ParkourLightEast", center + Vector3.new(62, 0, 32))

    -- Dress the core like a minaret shaft: stone bands, tall arched windows on every face and
    -- gold finials round the summit. All decorative and non-colliding, so the jumps are
    -- exactly as the unit tests measured them.
    local core = course.CoreSize
    local coreBase = center + Vector3.new(0, 4, 0)

    for level = 1, math.floor(core.Y / 14) do
        Decor.Deco(district, "CoreBand", Vector3.new(core.X + 0.8, 1.2, core.Z + 0.8), CFrame.new(coreBase + Vector3.new(0, level * 14, 0)), Color3.fromRGB(196, 176, 140), Enum.Material.Marble)

        for face = 0, 3 do
            local yaw = math.rad(face * 90)
            local window = CFrame.new(coreBase + Vector3.new(0, level * 14 - 6, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, core.Z / 2 + 0.15)
            Decor.Deco(district, "CoreWindow", Vector3.new(3.4, 7, 0.3), window, Color3.fromRGB(36, 30, 26), Enum.Material.Wood)
            Decor.Deco(district, "CoreWindowArch", Vector3.new(0.3, 3.4, 3.4), window * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(36, 30, 26), Enum.Material.Wood, Enum.PartType.Cylinder)
        end
    end

    for index = 1, 8 do
        local angle = math.rad(index * 45)
        local at = center + Vector3.new(math.cos(angle) * (course.SummitRadius - 1), course.SummitHeight, math.sin(angle) * (course.SummitRadius - 1))
        Decor.Deco(district, "SummitFinial", Vector3.new(1, 3, 1), CFrame.new(at + Vector3.new(0, 1.5, 0)), GOLD_ACCENT, Enum.Material.Metal)
        Decor.Deco(district, "SummitFinialTip", Vector3.new(1.4, 1.4, 1.4), CFrame.new(at + Vector3.new(0, 3.4, 0)), GOLD_ACCENT, Enum.Material.Metal, Enum.PartType.Ball)
    end

    BuildUtils.CreateVerticalCylinder(district, "SummitRim", 1.6, course.SummitRadius + 1, center + Vector3.new(0, course.SummitHeight - course.SummitThickness - 0.8, 0), Color3.fromRGB(196, 176, 140), Enum.Material.Marble, nil).CanCollide = false

    -- Palms in planters at the corners of the deck and a ring of mosaic round the core.
    for _, corner in ipairs({ Vector3.new(-70, 0, -40), Vector3.new(70, 0, -40), Vector3.new(-70, 0, 40), Vector3.new(70, 0, 40) }) do
        BuildUtils.CreatePart(district, "Planter", Vector3.new(10, 2.4, 10), CFrame.new(center + corner + Vector3.new(0, 5.2, 0)), Color3.fromRGB(196, 176, 140), Enum.Material.Marble, nil, nil)
        Decor.Palm(district, "DeckPalm", center + corner + Vector3.new(0, 6.4, 0), 20, corner.X + corner.Z, nil)
    end

    BuildUtils.CreateVerticalCylinder(district, "CoreMosaic", 0.1, 30, center + Vector3.new(0, 4.06, 0), Color3.fromRGB(70, 104, 120), Enum.Material.Glass, nil).CanCollide = false
    BuildUtils.CreateVerticalCylinder(district, "CoreMosaicInner", 0.12, 27, center + Vector3.new(0, 4.08, 0), Color3.fromRGB(226, 216, 196), Enum.Material.Marble, nil).CanCollide = false
end

local function createTrailPulse(parent: Instance, name: string, position: Vector3, phase: number)
    local pulse = BuildUtils.CreateSphere(parent, name, 2, position + Vector3.new(0, 8.2, 0), Color3.fromRGB(247, 208, 117), Enum.Material.Neon, 0.22)
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse:SetAttribute("PulsePhase", phase)
    CollectionService:AddTag(pulse, "TrailPulse")

    return pulse
end

local function createTrailDotsBetween(parent: Instance, namePrefix: string, startPosition: Vector3, endPosition: Vector3, phaseOffset: number)
    local difference = endPosition - startPosition
    local distance = difference.Magnitude
    local dotCount = math.max(2, math.floor(distance / 28))

    for dotIndex = 1, dotCount - 1 do
        local alpha = dotIndex / dotCount
        createTrailPulse(parent, string.format("%s_Dot_%d", namePrefix, dotIndex), startPosition:Lerp(endPosition, alpha), phaseOffset + dotIndex * 0.45)
    end
end

local function createLearningTrailStation(parent: Instance, step, stepIndex: number, position: Vector3, orientationY: number)
    local station = BuildUtils.CreateFolder(parent, string.format("LearningTrailStop_%d", stepIndex))
    local accentColor = (stepIndex == 1) and Color3.fromRGB(211, 172, 82) or Color3.fromRGB(193, 162, 86)
    local plaqueCFrame = CFrame.new(position + Vector3.new(0, 7.16, 0)) * CFrame.Angles(0, math.rad(orientationY), 0)

    BuildUtils.CreatePart(station, "Base", Vector3.new(18, 1.2, 18), CFrame.new(position + Vector3.new(0, 6.15, 0)), Color3.fromRGB(230, 222, 204), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(station, "GoldInlay", Vector3.new(13, 0.4, 13), CFrame.new(position + Vector3.new(0, 6.98, 0)), accentColor, Enum.Material.Metal, nil, nil)
    BuildUtils.CreateVerticalCylinder(station, "BeaconStem", 10, 0.45, position + Vector3.new(0, 12.1, 0), Color3.fromRGB(118, 101, 72), Enum.Material.Metal, nil)
    createTrailPulse(station, "BeaconPulse", position + Vector3.new(0, 8.2, 0), stepIndex * 0.9)

    local sign = createFloorPlaque(
        station,
        "TeachingPlaque",
        plaqueCFrame,
        Vector3.new(24, 0.5, 14),
        step.Title,
        step.LocationName,
        Color3.fromRGB(28, 70, 54),
        {
            ActionText = (stepIndex == 1) and "Begin Walk" or "Study Stop",
            ObjectText = "Learning Trail",
            Attributes = {
                PromptAction = "HaramTrailStep",
                StepIndex = stepIndex,
            },
        }
    )
    sign.Material = Enum.Material.Metal
end

-- Stops sit beside the landmarks they teach about, on the open mataf floor (and the last one
-- under the multi-level mataf expansion), with plaques turned to face the Kaaba.
local function createHaramLearningTrail(parent: Instance, center: Vector3, landmarks: MasjidAlHaram.Landmarks)
    local trailFolder = BuildUtils.CreateFolder(parent, "HaramLearningTrail")
    local floorOffset = Vector3.new(0, MasjidAlHaram.FloorHeight - 6.6, 0)

    local function besideLandmark(landmark: Vector3, distance: number): Vector3
        local flat = Vector3.new(landmark.X - center.X, 0, landmark.Z - center.Z)
        return center + flat.Unit * (flat.Magnitude + distance)
    end

    local blackStoneCorner = (landmarks.Kaaba * CFrame.new(-26, 0, 22)).Position
    local stationPositions = {
        center + Vector3.new(0, 0, 150), -- arrival side, north
        besideLandmark(blackStoneCorner, 70), -- facing the Black Stone corner, east
        center + Vector3.new(150, 0, -30), -- west side of the tawaf circle
        besideLandmark(landmarks.MaqamIbrahim, 22),
        besideLandmark(landmarks.HijrIsmail, 24),
        center + Vector3.new(-40, 0, 232), -- under the mataf expansion galleries, north
    }

    for index, step in ipairs(HaramLearningTrail.Steps) do
        local position = stationPositions[index]

        if position then
            position += floorOffset
            local toKaaba = center - position
            local facing = math.deg(math.atan2(-toKaaba.X, -toKaaba.Z))
            createLearningTrailStation(trailFolder, step, index, position, facing)

            if index > 1 then
                createTrailDotsBetween(trailFolder, string.format("Trail_%d_%d", index - 1, index), stationPositions[index - 1] + floorOffset, position, index)
            end
        end
    end
end

local function buildKaabaHub(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "KaabaHub")

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(1760, 12, 1760), CFrame.new(center + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "ExpansionDeck", Vector3.new(1600, 4, 1600), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(207, 196, 176), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "StonePlaza", Vector3.new(1420, 4, 1420), CFrame.new(center + Vector3.new(0, 2.3, 0)), Color3.fromRGB(228, 223, 212), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "OuterWalk", Vector3.new(1010, 1, 1010), CFrame.new(center + Vector3.new(0, 4.85, 0)), MECCA_MARBLE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "SouthPlaza", Vector3.new(560, 1, 300), CFrame.new(center + Vector3.new(0, 4.86, -600)), Color3.fromRGB(236, 233, 226), Enum.Material.Marble, nil, nil)

    local landmarks = MasjidAlHaram.Build(district, center)
    createHaramLearningTrail(district, center, landmarks)

    -- Hotels around the sanctuary; the Abraj Al-Bait complex itself is built by MasjidAlHaram.
    BuildUtils.CreateModernTower(district, "MakkahTowerWest", center + Vector3.new(-560, 0, -844), Vector2.new(72, 54), 224, Color3.fromRGB(210, 201, 186), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahTowerEast", center + Vector3.new(560, 0, -844), Vector2.new(72, 54), 224, Color3.fromRGB(210, 201, 186), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahHotelSouthWest", center + Vector3.new(-812, 0, 676), Vector2.new(78, 60), 198, Color3.fromRGB(215, 208, 194), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahHotelSouthEast", center + Vector3.new(812, 0, 676), Vector2.new(78, 60), 198, Color3.fromRGB(215, 208, 194), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahHotelNorthWest", center + Vector3.new(-836, 0, -542), Vector2.new(74, 56), 208, Color3.fromRGB(214, 207, 193), GLASS_TINT)
    BuildUtils.CreateModernTower(district, "MakkahHotelNorthEast", center + Vector3.new(836, 0, -542), Vector2.new(74, 56), 208, Color3.fromRGB(214, 207, 193), GLASS_TINT)
end

-- One of the big white umbrellas of the Prophet's Mosque piazza: a clad steel column and a
-- square fabric canopy that slopes down from the top of the column to its four edges.
local function createMedinaUmbrella(parent: Instance, name: string, ground: Vector3, size: number)
    local umbrella = Instance.new("Model")
    umbrella.Name = name
    umbrella.Parent = parent

    local top = ground + Vector3.new(0, 30, 0)
    BuildUtils.CreateVerticalCylinder(umbrella, "Column", 30, 0.9, ground + Vector3.new(0, 15, 0), Color3.fromRGB(206, 208, 210), Enum.Material.Metal, nil)
    BuildUtils.CreateVerticalCylinder(umbrella, "Cladding", 9, 1.6, ground + Vector3.new(0, 4.5, 0), Color3.fromRGB(228, 226, 218), Enum.Material.Marble, nil)
    BuildUtils.CreateVerticalCylinder(umbrella, "CladdingBand", 0.8, 1.75, ground + Vector3.new(0, 8.6, 0), GOLD_ACCENT, Enum.Material.Metal, nil).CanCollide = false
    local cap = BuildUtils.CreateSphere(umbrella, "Cap", 2.4, top + Vector3.new(0, 0.6, 0), Color3.fromRGB(226, 228, 230), Enum.Material.Metal, nil)
    cap.CanCollide = false

    for index, direction in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
        local edge = top + direction * (size / 2) + Vector3.new(0, -5, 0)
        local mid = (top + edge) / 2
        local panel = BuildUtils.CreatePart(umbrella, "Canopy" .. index, Vector3.new(size, 0.3, (edge - top).Magnitude), CFrame.lookAt(mid, edge), Color3.fromRGB(246, 245, 240), Enum.Material.Fabric, nil, nil)
        panel.CanCollide = false
    end

    return umbrella
end

-- A facade of arched bays between piers. `doors` lists bay numbers left open at ground level.
local function createArchedFacade(parent: Instance, name: string, origin: CFrame, length: number, bays: number, height: number, doors: { [number]: boolean })
    local bay = length / bays
    local pier = 2.6
    local opening = bay - pier
    local archTop = height - 7

    for index = 1, bays + 1 do
        local x = -length / 2 + (index - 1) * bay
        BuildUtils.CreatePart(parent, string.format("%s_Pier%d", name, index), Vector3.new(pier, height, 3.4), origin * CFrame.new(x, height / 2, 0), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    end

    for index = 1, bays do
        local x = -length / 2 + (index - 0.5) * bay
        local isDoor = doors[index] == true
        -- Spandrel above the arch, with a gold band.
        BuildUtils.CreatePart(parent, string.format("%s_Spandrel%d", name, index), Vector3.new(opening, height - archTop, 3), origin * CFrame.new(x, archTop + (height - archTop) / 2, 0), MEDINA_WHITE, Enum.Material.Marble, nil, nil)
        -- Round arch head: a cylinder along the wall normal, half inside the spandrel.
        BuildUtils.CreatePart(parent, string.format("%s_Arch%d", name, index), Vector3.new(3.1, opening, opening), origin * CFrame.new(x, archTop, 0) * CFrame.Angles(0, math.rad(90), 0), MEDINA_WHITE, Enum.Material.Marble, Enum.PartType.Cylinder, nil)

        if isDoor then
            -- An open doorway with a carved wooden-and-brass door folded back inside.
            BuildUtils.CreatePart(parent, string.format("%s_DoorLeaf%d", name, index), Vector3.new(0.6, archTop - opening / 2 - 0.5, opening * 0.45), origin * CFrame.new(x - opening / 2 + 0.6, (archTop - opening / 2) / 2, 3.2), Color3.fromRGB(122, 84, 46), Enum.Material.Wood, nil, nil).CanCollide = false
        else
            BuildUtils.CreatePart(parent, string.format("%s_Panel%d", name, index), Vector3.new(opening, archTop - opening / 2, 1.6), origin * CFrame.new(x, (archTop - opening / 2) / 2, 0.4), MEDINA_WHITE, Enum.Material.Marble, nil, nil)
            BuildUtils.CreatePart(parent, string.format("%s_Window%d", name, index), Vector3.new(opening - 3, archTop - opening / 2 - 9, 0.4), origin * CFrame.new(x, 6 + (archTop - opening / 2 - 9) / 2 + 1, -0.5), GLASS_TINT, Enum.Material.Glass, nil, 0.15)
        end
    end

    BuildUtils.CreatePart(parent, name .. "_Cornice", Vector3.new(length + 4, 1.6, 4.4), origin * CFrame.new(0, height + 0.8, 0), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(parent, name .. "_GoldBand", Vector3.new(length + 0.5, 0.8, 3.6), origin * CFrame.new(0, height - 2.4, -0.1), GOLD_ACCENT, Enum.Material.Metal, nil, nil).CanCollide = false
end

-- Present-day Al-Masjid an-Nabawi, simplified: a walk-in prayer hall with arched facades,
-- red carpets, rows of columns and the green-carpeted Rawdah; a roof of small domes with the
-- Green Dome over the sacred chamber marker; tall minarets; and a marble piazza shaded by
-- big white umbrellas. Respectful markers only: no burial chamber interior is modelled.
local function buildMedinaDistrict(parent: Instance, center: Vector3)
    local district = BuildUtils.CreateFolder(parent, "MedinaDistrict")
    local floorY = center.Y + 4
    local hallCenter = Vector3.new(center.X, floorY, center.Z - 80)
    local hallWidth, hallDepth, hallHeight = 280, 200, 30
    local chamber = Vector3.new(center.X + 60, floorY, center.Z - 146.7)

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(920, 12, 760), CFrame.new(center + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "OuterCourt", Vector3.new(620, 4, 500), CFrame.new(center + Vector3.new(0, 2, 0)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    -- Piazza paving: white marble with a grey grid and a darker band round the mosque.
    BuildUtils.CreatePart(district, "PiazzaWhite", Vector3.new(600, 0.2, 480), CFrame.new(center + Vector3.new(0, 4.1, 0)), MEDINA_WHITE, Enum.Material.Marble, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "HallSurround", Vector3.new(hallWidth + 24, 0.24, hallDepth + 24), CFrame.new(hallCenter + Vector3.new(0, 0.12, 0)), Color3.fromRGB(190, 186, 176), Enum.Material.Marble, nil, nil).CanCollide = false
    createFloorInlayGrid(district, "MedinaMarbleInlay", center, 234, 36, Color3.fromRGB(200, 198, 190), 4.22)

    -- Prayer hall: four arched facades, open doorways on every side but the qibla bays.
    local facades = BuildUtils.CreateFolder(district, "PrayerHall")
    createArchedFacade(facades, "NorthFacade", CFrame.new(hallCenter + Vector3.new(0, 0, hallDepth / 2)) * CFrame.Angles(0, math.rad(180), 0), hallWidth, 21, hallHeight, { [3] = true, [7] = true, [11] = true, [15] = true, [19] = true })
    createArchedFacade(facades, "SouthFacade", CFrame.new(hallCenter + Vector3.new(0, 0, -hallDepth / 2)), hallWidth, 21, hallHeight, { [3] = true, [19] = true })
    -- Side doors: bay 3 on the west and bay 13 on the east line up with the visitation route.
    createArchedFacade(facades, "WestFacade", CFrame.new(hallCenter + Vector3.new(-hallWidth / 2, 0, 0)) * CFrame.Angles(0, math.rad(-90), 0), hallDepth, 15, hallHeight, { [3] = true, [8] = true, [13] = true })
    createArchedFacade(facades, "EastFacade", CFrame.new(hallCenter + Vector3.new(hallWidth / 2, 0, 0)) * CFrame.Angles(0, math.rad(90), 0), hallDepth, 15, hallHeight, { [3] = true, [8] = true, [13] = true })

    BuildUtils.CreatePart(facades, "Carpet", Vector3.new(hallWidth - 4, 0.2, hallDepth - 4), CFrame.new(hallCenter + Vector3.new(0, 0.4, 0)), Color3.fromRGB(150, 40, 44), Enum.Material.Fabric, nil, nil).CanCollide = false

    -- Rows of columns, leaving the visitation route (between the first two rows) open.
    local columnIndex = 0

    for _, dz in ipairs({ -85, -55, -25, 5, 35, 65 }) do
        for dx = -126, 126, 28 do
            columnIndex += 1
            local base = hallCenter + Vector3.new(dx, 0, dz)
            BuildUtils.CreateVerticalCylinder(facades, "Column" .. columnIndex, hallHeight, 1.4, base + Vector3.new(0, hallHeight / 2, 0), MEDINA_WHITE, Enum.Material.Marble, nil)
            BuildUtils.CreatePart(facades, "ColumnCapital" .. columnIndex, Vector3.new(4.4, 2, 4.4), CFrame.new(base + Vector3.new(0, hallHeight - 3, 0)), GOLD_ACCENT, Enum.Material.Metal, nil, nil).CanCollide = false
            BuildUtils.CreatePart(facades, "ColumnBase" .. columnIndex, Vector3.new(4, 2.4, 4), CFrame.new(base + Vector3.new(0, 1.2, 0)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
        end
    end

    -- Roof with a parapet and a grid of small domes; the Green Dome over the chamber marker.
    local roofY = floorY + hallHeight + 1.6
    BuildUtils.CreatePart(facades, "Roof", Vector3.new(hallWidth + 4, 3, hallDepth + 4), CFrame.new(hallCenter + Vector3.new(0, hallHeight + 1.5, 0)), MEDINA_STONE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(facades, "Ceiling", Vector3.new(hallWidth - 4, 0.3, hallDepth - 4), CFrame.new(hallCenter + Vector3.new(0, hallHeight - 0.2, 0)), Color3.fromRGB(226, 214, 186), Enum.Material.WoodPlanks, nil, nil).CanCollide = false

    -- Brass chandeliers hanging between the column rows, lit at night.
    local chandelierIndex = 0
    for _, dx in ipairs({ -84, 0, 84 }) do
        for _, dz in ipairs({ -50, 50 }) do
            chandelierIndex += 1
            local at = hallCenter + Vector3.new(dx, hallHeight - 9, dz)
            local chain = BuildUtils.CreatePart(facades, "ChandelierChain" .. chandelierIndex, Vector3.new(0.2, 8.6, 0.2), CFrame.new(at + Vector3.new(0, 4.6, 0)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
            chain.CanCollide = false
            local ring = BuildUtils.CreateVerticalCylinder(facades, "ChandelierRing" .. chandelierIndex, 0.6, 9, at, GOLD_ACCENT, Enum.Material.Metal, nil)
            ring.CanCollide = false
            local glow = BuildUtils.CreateSphere(facades, "ChandelierGlow" .. chandelierIndex, 2.6, at + Vector3.new(0, -0.9, 0), Color3.fromRGB(255, 226, 168), Enum.Material.Neon, nil)
            glow.CanCollide = false
            BuildUtils.AddPointLight(glow, Color3.fromRGB(255, 214, 150), 1.4, 40)
        end
    end

    local domeIndex = 0

    for dz = -70, 70, 46 do
        for dx = -112, 112, 44.8 do
            local at = hallCenter + Vector3.new(dx, 0, dz)

            if (Vector3.new(at.X, 0, at.Z) - Vector3.new(chamber.X, 0, chamber.Z)).Magnitude > 34 then
                domeIndex += 1
                BuildUtils.CreateVerticalCylinder(facades, "RoofDomeDrum" .. domeIndex, 6, 9, Vector3.new(at.X, roofY + 4.2, at.Z), MEDINA_STONE, Enum.Material.Marble, nil)
                BuildUtils.CreateSphere(facades, "RoofDome" .. domeIndex, 17, Vector3.new(at.X, roofY + 7.2, at.Z), Color3.fromRGB(208, 202, 186), Enum.Material.Marble, nil)
                BuildUtils.CreatePart(facades, "RoofDomeFinial" .. domeIndex, Vector3.new(0.6, 3, 0.6), CFrame.new(at.X, roofY + 17, at.Z), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
            end
        end
    end

    BuildUtils.CreateVerticalCylinder(district, "GreenDomeDrum", 12, 14, Vector3.new(chamber.X, roofY + 6, chamber.Z), MEDINA_WHITE, Enum.Material.Marble, nil)
    BuildUtils.CreateVerticalCylinder(district, "GreenDomeDrumBand", 1.4, 14.4, Vector3.new(chamber.X, roofY + 11, chamber.Z), GOLD_ACCENT, Enum.Material.Metal, nil)
    BuildUtils.CreateSphere(district, "GreenDome", 28, Vector3.new(chamber.X, roofY + 16, chamber.Z), MEDINA_GREEN, Enum.Material.SmoothPlastic, nil)
    BuildUtils.CreateSphere(district, "GreenDomeLantern", 4, Vector3.new(chamber.X, roofY + 31, chamber.Z), MEDINA_GREEN, Enum.Material.SmoothPlastic, nil)
    BuildUtils.CreatePart(district, "DomeSpire", Vector3.new(1, 9, 1), CFrame.new(chamber.X, roofY + 37, chamber.Z), GOLD_ACCENT, Enum.Material.Metal, nil, nil)

    -- Minarets at the corners of the hall and of the piazza.
    for index, offset in ipairs({
        Vector3.new(-148, 0, -188), Vector3.new(148, 0, -188), Vector3.new(-148, 0, 28), Vector3.new(148, 0, 28),
        Vector3.new(-300, 0, 236), Vector3.new(300, 0, 236),
    }) do
        local names = { "SouthWestMinaret", "SouthEastMinaret", "NorthWestMinaret", "NorthEastMinaret", "PiazzaWestMinaret", "PiazzaEastMinaret" }
        BuildUtils.CreateMinaret(district, names[index], center + offset, if index <= 4 then 118 else 104, MEDINA_WHITE, MEDINA_GREEN)
    end

    -- Inside: mihrab and minbar on the qibla wall, the Rawdah carpet and the visitation route.
    BuildUtils.CreatePart(district, "Mihrab", Vector3.new(10, 16, 1.4), CFrame.new(hallCenter + Vector3.new(0, 8, -hallDepth / 2 + 2.4)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(district, "MihrabNiche", Vector3.new(7, 12, 0.6), CFrame.new(hallCenter + Vector3.new(0, 6.5, -hallDepth / 2 + 3.2)), MEDINA_GREEN, Enum.Material.Marble, nil, nil).CanCollide = false

    for step = 1, 5 do
        BuildUtils.CreatePart(district, "MinbarStep" .. step, Vector3.new(4, step * 1.4, 2), CFrame.new(hallCenter + Vector3.new(-14, step * 0.7, -hallDepth / 2 + 4 + (5 - step) * 2)), MEDINA_WHITE, Enum.Material.Marble, nil, nil)
    end

    BuildUtils.CreatePart(district, "RawdahPath", Vector3.new(200, 0.3, 16), CFrame.new(Vector3.new(center.X - 50, floorY + 0.58, chamber.Z)), Color3.fromRGB(89, 132, 82), Enum.Material.Fabric, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "RawdahArea", Vector3.new(70, 0.3, 30), CFrame.new(Vector3.new(center.X + 8, floorY + 0.6, chamber.Z)), Color3.fromRGB(82, 125, 76), Enum.Material.Fabric, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "RawdahGoldEdgeA", Vector3.new(200, 0.35, 1.4), CFrame.new(Vector3.new(center.X - 50, floorY + 0.65, chamber.Z - 8.5)), GOLD_ACCENT, Enum.Material.Metal, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "RawdahGoldEdgeB", Vector3.new(200, 0.35, 1.4), CFrame.new(Vector3.new(center.X - 50, floorY + 0.65, chamber.Z + 8.5)), GOLD_ACCENT, Enum.Material.Metal, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "SacredChamberMarker", Vector3.new(28, 16, 22), CFrame.new(chamber + Vector3.new(4, 8, 0)), Color3.fromRGB(198, 184, 153), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "SacredChamberGrille", Vector3.new(1.2, 14, 26), CFrame.new(chamber + Vector3.new(-11, 7, 0)), GOLD_ACCENT, Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(district, "SacredChamberGrilleCloth", Vector3.new(1.4, 3, 26.4), CFrame.new(chamber + Vector3.new(-11, 15.5, 0)), MEDINA_GREEN, Enum.Material.Fabric, nil, nil)

    for index, dz in ipairs({ -6, 0, 6 }) do
        BuildUtils.CreatePart(district, "CompanionMarker" .. string.char(64 + index), Vector3.new(5, 0.6, 5), CFrame.new(chamber + Vector3.new(-16, 0.3, dz)), Color3.fromRGB(214, 204, 181), Enum.Material.Marble, nil, nil).CanCollide = false
    end

    createWallPanel(district, "VisitationSign", Vector3.new(center.X - 170, center.Y, chamber.Z + 22), Vector3.new(60, 12, 2.5), "Bab as-Salam Visitation Route", "Enter from Bab as-Salam, follow the marked walkway, and approach the sacred chamber area respectfully and quietly.", Color3.fromRGB(52, 88, 58), 90, nil)
    createWallPanel(district, "ChamberSign", Vector3.new(chamber.X - 30, center.Y, chamber.Z + 30), Vector3.new(40, 10, 2.5), "Sacred Chamber Marker", "This is a respectful marker for the visitation area and route, not a 1:1 interior reconstruction.", Color3.fromRGB(86, 92, 67), 180, nil)

    -- Gates at the edge of the piazza.
    createMedinaGate(district, "BabAsSalamGate", center + Vector3.new(-290, 0, -146.7), 90, "Bab as-Salam", "Traditional entry gate for the visitation route.")
    createMedinaGate(district, "BabAbuBakrGate", center + Vector3.new(-290, 0, -60), 90, "Bab Abu Bakr", "A west-side gate near the older visitation approach.")
    createMedinaGate(district, "BabRahmahGate", center + Vector3.new(-290, 0, 30), 90, "Bab ar-Rahmah", "A named western gate on the Medina side.")
    createMedinaGate(district, "BabJibrilGate", center + Vector3.new(290, 0, -146.7), 270, "Bab Jibril", "An eastern gate associated with the Jibril side of the mosque.")
    createMedinaGate(district, "BabBaqiGate", center + Vector3.new(290, 0, -60), 270, "Bab al-Baqi'", "An eastern gate toward the al-Baqi' side.")
    createMedinaGate(district, "BabNisaGate", center + Vector3.new(290, 0, 30), 270, "Bab an-Nisa", "A named gate on the eastern side of the Medina complex.")

    -- Umbrellas over the north piazza and the side courts, keeping the arrival point and
    -- the walkway into the north doors clear of columns.
    local umbrellas = BuildUtils.CreateFolder(district, "Umbrellas")
    local umbrellaIndex = 0

    for _, dz in ipairs({ 58, 96, 172, 210 }) do
        for dx = -266, 266, 38 do
            if math.abs(dx) > 12 then
                umbrellaIndex += 1
                createMedinaUmbrella(umbrellas, "Umbrella" .. umbrellaIndex, Vector3.new(center.X + dx, floorY, center.Z + dz), 36)
            end
        end
    end

    for _, dx in ipairs({ -226, -188, 188, 226 }) do
        for dz = -168, 0, 42 do
            umbrellaIndex += 1
            createMedinaUmbrella(umbrellas, "Umbrella" .. umbrellaIndex, Vector3.new(center.X + dx, floorY, center.Z + dz), 36)
        end
    end

    -- Every third umbrella carries a lamp under its cap, so the piazza is lit at night.
    for index, umbrella in ipairs(umbrellas:GetChildren()) do
        local column = umbrella:FindFirstChild("Column")
        if index % 3 == 1 and column and column:IsA("BasePart") then
            local lamp = BuildUtils.CreatePart(umbrella, "UnderLamp", Vector3.new(1.4, 1, 1.4), CFrame.new(column.Position + Vector3.new(0, 12.5, 0)), Color3.fromRGB(255, 232, 186), Enum.Material.Neon, nil, nil)
            lamp.CanCollide = false
            BuildUtils.AddPointLight(lamp, Color3.fromRGB(255, 226, 176), 1.2, 34)
        end
    end

    -- Lamp posts along the arrival walkway.
    for _, dz in ipairs({ 40, 80, 120, 160, 200 }) do
        for _, dx in ipairs({ -20, 20 }) do
            local post = BuildUtils.CreateVerticalCylinder(district, "WalkLampPost", 14, 0.4, Vector3.new(center.X + dx, floorY + 7, center.Z + dz), Color3.fromRGB(70, 74, 72), Enum.Material.Metal, nil)
            local lamp = BuildUtils.CreatePart(district, "WalkLamp", Vector3.new(1.6, 2.2, 1.6), CFrame.new(post.Position + Vector3.new(0, 8, 0)), Color3.fromRGB(255, 226, 168), Enum.Material.Neon, nil, nil)
            lamp.CanCollide = false
            BuildUtils.AddPointLight(lamp, Color3.fromRGB(255, 220, 160), 1.3, 26)
        end
    end
end

local function buildBattleGate(parent: Instance, name: string, center: Vector3, accentColor: Color3, scenarioId: string, title: string)
    local district = BuildUtils.CreateFolder(parent, string.format("%sDistrict", name))

    BuildUtils.CreatePart(district, "SafetyPlate", Vector3.new(300, 12, 240), CFrame.new(center + Vector3.new(0, -10, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(district, "Forecourt", Vector3.new(244, 4, 176), CFrame.new(center + Vector3.new(0, 2, 0)), Color3.fromRGB(205, 182, 141), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "QueuePad", Vector3.new(136, 1, 62), CFrame.new(center + Vector3.new(0, 4.55, -24)), Color3.fromRGB(225, 213, 190), Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(district, "QueuePadInset", Vector3.new(10, 0.2, 56), CFrame.new(center + Vector3.new(0, 5.16, -24)), GOLD_ACCENT, Enum.Material.Metal, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "EntryPath", Vector3.new(74, 1, 104), CFrame.new(center + Vector3.new(0, 4.52, 58)), Color3.fromRGB(187, 159, 118), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "EntryPathInset", Vector3.new(6, 0.2, 94), CFrame.new(center + Vector3.new(0, 5.14, 58)), Color3.fromRGB(229, 212, 180), Enum.Material.Marble, nil, nil).CanCollide = false
    BuildUtils.CreatePart(district, "LeftWall", Vector3.new(18, 26, 86), CFrame.new(center + Vector3.new(-92, 13, 16)), Color3.fromRGB(187, 166, 132), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "RightWall", Vector3.new(18, 26, 86), CFrame.new(center + Vector3.new(92, 13, 16)), Color3.fromRGB(187, 166, 132), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "LeftTower", Vector3.new(20, 30, 20), CFrame.new(center + Vector3.new(-58, 15, 0)), Color3.fromRGB(189, 167, 131), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "RightTower", Vector3.new(20, 30, 20), CFrame.new(center + Vector3.new(58, 15, 0)), Color3.fromRGB(189, 167, 131), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(district, "GateBeam", Vector3.new(94, 9, 16), CFrame.new(center + Vector3.new(0, 25, 0)), accentColor, Enum.Material.Sandstone, nil, nil)
    -- Dressing (none of it collides): battlements on the walls and towers, banners in the
    -- gate colour, fire bowls, palms and supplies beside the forecourt.
    local dressing = BuildUtils.CreateFolder(district, "Dressing")
    for _, side in ipairs({ -1, 1 }) do
        for index = 1, 6 do
            local z = 16 - 43 + (index - 0.5) * (86 / 6)
            Decor.Deco(dressing, "WallMerlon", Vector3.new(4, 3, 5), CFrame.new(center + Vector3.new(side * 92, 27.5, z)), Color3.fromRGB(176, 154, 120), Enum.Material.Sandstone)
        end
        for _, dx in ipairs({ -7, 0, 7 }) do
            for _, dz in ipairs({ -7, 7 }) do
                Decor.Deco(dressing, "TowerMerlon", Vector3.new(3.5, 3.5, 3.5), CFrame.new(center + Vector3.new(side * 58 + dx, 31.75, dz)), Color3.fromRGB(178, 156, 120), Enum.Material.Sandstone)
            end
        end
        Decor.Deco(dressing, "TowerBand", Vector3.new(21, 1.6, 21), CFrame.new(center + Vector3.new(side * 58, 24, 0)), accentColor, Enum.Material.Sandstone)
        Decor.Banner(dressing, "GateBanner", center + Vector3.new(side * 40, 5, 14), accentColor, 22)
        Decor.Banner(dressing, "WallBanner", center + Vector3.new(side * 76, 5, 34), Decor.Colors.Cloths[if side < 0 then 1 else 2], 18)
        Decor.Brazier(dressing, "GateBrazier", center + Vector3.new(side * 30, 5, 8))
        Decor.Palm(dressing, "ForecourtPalm", center + Vector3.new(side * 108, 4, 74), 20, 17 + side, true)
        for index = 1, 2 do
            Decor.Crate(dressing, "SupplyCrate", CFrame.new(center + Vector3.new(side * (66 + index * 3), 5.2, 52)) * CFrame.Angles(0, index * 0.4, 0), 2.2)
            Decor.Jar(dressing, "WaterJar", center + Vector3.new(side * (66 + index * 2.4), 4, 60), 0.9, nil)
        end
    end

    createLightPost(district, string.format("%sLightLeft", name), center + Vector3.new(-38, 0, -52), Color3.fromRGB(120, 103, 80))
    createLightPost(district, string.format("%sLightRight", name), center + Vector3.new(38, 0, -52), Color3.fromRGB(120, 103, 80))

    createWallPanel(
        district,
        string.format("%sBoard", name),
        center + Vector3.new(0, 0, -70),
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

-- Roblox caps a part at 2048 studs per side, so the ground is laid in tiles.
for tileX = -1, 1, 2 do
    for tileZ = -1, 1, 2 do
        local tileCenter = Vector3.new(tileX * 650, 0, 720 + tileZ * 770)
        BuildUtils.CreatePart(geometryFolder, string.format("WorldGround_%d_%d", tileX, tileZ), Vector3.new(1300, 2, 1540), CFrame.new(tileCenter + Vector3.new(0, -1, 0)), DESERT_SAND, Enum.Material.Sand, nil, nil)
        BuildUtils.CreatePart(geometryFolder, string.format("WorldSafetyPlate_%d_%d", tileX, tileZ), Vector3.new(1400, 14, 1650), CFrame.new(tileCenter + Vector3.new(tileX * 50, -14, tileZ * 55)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    end
end

-- Desert beyond the south plaza, under the Abraj Al-Bait towers and the far ridge.
for tileX = -1, 1, 2 do
    BuildUtils.CreatePart(geometryFolder, string.format("WorldGroundSouth_%d", tileX), Vector3.new(1300, 2, 760), CFrame.new(tileX * 650, -1, -1200), DESERT_SAND, Enum.Material.Sand, nil, nil)
end
createSafetyBounds(geometryFolder, "HubBounds", Vector3.new(0, 0, 720), Vector3.new(2360, 0, 2760))

for _, destination in ipairs(TravelRoute.Destinations) do
    BuildUtils.CreateTeleportAnchor(teleportFolder, destination.Id, destination.TeleportPosition or destination.Position)
end

local meccaCenter = TravelRoute.GetDestinationById("kaaba_courtyard").Position
local desertCenter = TravelRoute.GetDestinationById("journey_reflection").Position
local medinaCenter = TravelRoute.GetDestinationById("medina_courtyard").Position
local storyCenter = TravelRoute.GetDestinationById("story_court").Position
local mannersCenter = TravelRoute.GetDestinationById("manners_court").Position
local triviaCenter = TravelRoute.GetDestinationById("trivia_court").Position
local parkourCenter = TravelRoute.GetDestinationById("parkour_tower").Position
local badrGateCenter = TravelRoute.GetDestinationById("badr_gate").Position
local uhudGateCenter = TravelRoute.GetDestinationById("uhud_gate").Position
local supportCenter = Vector3.new(920, 0, -560)

buildDesertRoute(geometryFolder, meccaCenter, desertCenter, medinaCenter)
buildKaabaHub(geometryFolder, meccaCenter)
buildSupportLounge(geometryFolder, supportCenter)
buildStoryCourt(geometryFolder, storyCenter)
buildMannersCourt(geometryFolder, mannersCenter)
buildTriviaCourt(geometryFolder, triviaCenter)
buildParkourCourse(geometryFolder, parkourCenter)
buildMedinaDistrict(geometryFolder, medinaCenter)
buildBattleGate(geometryFolder, "BadrGate", badrGateCenter, Color3.fromRGB(141, 107, 58), "badr", "Badr Gate")
buildBattleGate(geometryFolder, "UhudGate", uhudGateCenter, Color3.fromRGB(114, 92, 71), "uhud", "Uhud Gate")
createPromenadePath(geometryFolder, "StoryPromenade", meccaCenter + Vector3.new(714, 0, 220), storyCenter + Vector3.new(-122, 0, 0), 54, Color3.fromRGB(205, 190, 162), Color3.fromRGB(128, 109, 82))
createPromenadePath(geometryFolder, "TriviaPromenade", meccaCenter + Vector3.new(714, 0, -240), triviaCenter + Vector3.new(-122, 0, 0), 54, Color3.fromRGB(205, 190, 162), Color3.fromRGB(128, 109, 82))
createPromenadePath(geometryFolder, "MannersPromenade", meccaCenter + Vector3.new(-714, 0, -240), mannersCenter + Vector3.new(122, 0, 0), 54, Color3.fromRGB(205, 190, 162), Color3.fromRGB(128, 109, 82))
createPromenadePath(geometryFolder, "ParkourPromenade", meccaCenter + Vector3.new(-714, 0, 220), parkourCenter + Vector3.new(122, 0, 0), 54, Color3.fromRGB(205, 190, 162), Color3.fromRGB(128, 109, 82))
createPromenadePath(geometryFolder, "SupportPromenade", meccaCenter + Vector3.new(714, 0, -560), supportCenter + Vector3.new(-84, 0, 0), 54, Color3.fromRGB(199, 184, 156), Color3.fromRGB(128, 109, 82))
createPromenadePath(geometryFolder, "BadrGatePromenade", meccaCenter + Vector3.new(-714, 0, -560), badrGateCenter + Vector3.new(98, 0, 0), 62, Color3.fromRGB(191, 171, 136), Color3.fromRGB(118, 96, 70))
createPromenadePath(geometryFolder, "UhudGatePromenade", meccaCenter + Vector3.new(-714, 0, 520), uhudGateCenter + Vector3.new(98, 0, 0), 62, Color3.fromRGB(191, 171, 136), Color3.fromRGB(118, 96, 70))
createPromenadePath(geometryFolder, "JourneyPromenade", meccaCenter + Vector3.new(0, 0, 714), desertCenter + Vector3.new(0, 0, -152), 70, Color3.fromRGB(202, 187, 159), Color3.fromRGB(128, 109, 82))
-- The north ridge and apron of the Makkah band would sit on the Abraj Al-Bait site, the two
-- west ridges on the Badr and Uhud gates, and the south ridge and apron across the Journey road.
createDistrictTerrainBand(geometryFolder, "MeccaWorld", meccaCenter, 980, 940, DESERT_ROCK, { NorthFrame = true, Apron_3 = true, WestNorthFrame = true, WestSouthFrame = true, SouthFrame = true, Apron_4 = true })
-- Its north ridge would sit across the Journey road beside the reflection site.
createDistrictTerrainBand(geometryFolder, "MedinaWorld", medinaCenter, 640, 540, Color3.fromRGB(133, 110, 84), { NorthFrame = true })
-- Its northern ridges would land inside Masjid al-Haram and its south ridge in the Medina courtyard.
createDistrictTerrainBand(geometryFolder, "JourneyWorld", desertCenter, 520, 720, Color3.fromRGB(141, 114, 84), { NorthFrame = true, SouthFrame = true, WestNorthFrame = true, EastNorthFrame = true, Apron_3 = true, Apron_4 = true })
createWorldBackdrop(geometryFolder, Vector3.new(0, 0, 720))

-- Lantern posts at every hub arrival point so nobody lands in the dark at night.
local arrivalLights = BuildUtils.CreateFolder(geometryFolder, "ArrivalLanterns")
for _, destination in ipairs(TravelRoute.Destinations) do
    local landing = destination.TeleportPosition or destination.Position
    if math.abs(landing.X) < 2000 and math.abs(landing.Z) < 2400 and destination.Id ~= "kaaba_courtyard" then
        local ground = if destination.Id == "medina_courtyard" then landing.Y + 4 else landing.Y
        Decor.ArrivalLanterns(arrivalLights, destination.Id, landing, ground)
    end
end

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "JourneySpawn"
spawnLocation.Anchored = true
spawnLocation.Neutral = true
spawnLocation.Size = Vector3.new(18, 1, 18)
spawnLocation.Transparency = 1
spawnLocation.CanCollide = true
spawnLocation.CFrame = CFrame.new(meccaCenter + Vector3.new(0, 5, 92))
spawnLocation.Parent = geometryFolder

-- Lets scripts that place things on the finished hub (guides, the leaderboard) know it is ready.
worldFolder:SetAttribute("Built", true)
