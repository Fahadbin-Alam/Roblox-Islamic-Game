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
        { Name = "FarNorthWest", Position = center + Vector3.new(-1120, 0, -1180), Length = 560, Height = 196, Depth = 194, Yaw = 16, Color = DESERT_ROCK },
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

    local signOffset = Vector3.new(0, 0, 14)
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
-- The north ridge and apron of the Makkah band would sit on the Abraj Al-Bait site.
createDistrictTerrainBand(geometryFolder, "MeccaWorld", meccaCenter, 980, 940, DESERT_ROCK, { NorthFrame = true, Apron_3 = true })
createDistrictTerrainBand(geometryFolder, "MedinaWorld", medinaCenter, 640, 540, Color3.fromRGB(133, 110, 84))
-- Its northern ridges would land inside Masjid al-Haram and its south ridge in the Medina courtyard.
createDistrictTerrainBand(geometryFolder, "JourneyWorld", desertCenter, 520, 720, Color3.fromRGB(141, 114, 84), { NorthFrame = true, SouthFrame = true, WestNorthFrame = true, EastNorthFrame = true, Apron_3 = true, Apron_4 = true })
createWorldBackdrop(geometryFolder, Vector3.new(0, 0, 720))

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
