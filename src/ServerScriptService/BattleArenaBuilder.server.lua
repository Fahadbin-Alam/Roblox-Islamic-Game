--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattleScenarios = require(Shared.Data.BattleScenarios)
local BuildUtils = require(script.Parent.Modules.BuildUtils)

local ARENA_FOLDER_NAME = "GeneratedBattles"

local function scaleColor(color: Color3, scale: number): Color3
    return Color3.fromRGB(
        math.clamp(math.floor(color.R * 255 * scale), 0, 255),
        math.clamp(math.floor(color.G * 255 * scale), 0, 255),
        math.clamp(math.floor(color.B * 255 * scale), 0, 255)
    )
end

local function makeVisualOnly(part: BasePart): BasePart
    part.CanCollide = false
    part.CastShadow = true

    return part
end

local function createMountain(parent: Instance, name: string, position: Vector3, baseWidth: number, height: number, depth: number, color: Color3)
    BuildUtils.CreateMountain(parent, name, position, baseWidth, height, depth, color, 0)
end

local function createMountainFaceDetails(parent: Instance, name: string, position: Vector3, yawDegrees: number, width: number, height: number, depth: number, color: Color3)
    local folder = BuildUtils.CreateFolder(parent, name)
    local baseCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yawDegrees), 0)

    for layer = 1, 4 do
        local layerHeight = height * (0.18 + layer * 0.13)
        local layerWidth = width * (0.95 - layer * 0.12)
        local forward = depth * (-0.42 + layer * 0.06)
        local shade = scaleColor(color, 0.74 + layer * 0.05)

        for segment = 1, 7 do
            local alpha = (segment - 4) / 3
            local segmentWidth = layerWidth * (0.12 + (1 - math.abs(alpha)) * 0.04)
            local segmentHeight = math.max(5, height * (0.035 + layer * 0.006))
            local segmentDepth = depth * (0.09 + (segment % 3) * 0.012)
            local x = alpha * layerWidth * 0.43
            local z = forward + math.sin(segment * 1.37 + layer) * depth * 0.03
            local tilt = math.rad((segment % 3 - 1) * 4)
            local yaw = math.rad((segment % 2 == 0 and -7 or 6) + layer * 2)

            makeVisualOnly(BuildUtils.CreateWedge(
                folder,
                string.format("Crag_%d_%d", layer, segment),
                Vector3.new(segmentWidth, segmentHeight, segmentDepth),
                baseCFrame * CFrame.new(x, layerHeight, z) * CFrame.Angles(tilt, yaw, math.rad((layer % 2 == 0) and 2 or -2)),
                shade,
                Enum.Material.Slate,
                nil
            ))
        end
    end

    for index = 1, 11 do
        local alpha = (index - 6) / 5
        local heightOffset = height * (0.24 + (1 - math.abs(alpha)) * 0.34)
        local x = alpha * width * 0.38
        local z = depth * (0.04 + math.sin(index * 1.9) * 0.08)

        makeVisualOnly(BuildUtils.CreatePart(
            folder,
            string.format("StoneSeam_%d", index),
            Vector3.new(width * 0.09, math.max(1.6, height * 0.015), 2.2),
            baseCFrame * CFrame.new(x, heightOffset, z) * CFrame.Angles(0, math.rad(index % 2 == 0 and -9 or 8), math.rad((index % 3 - 1) * 7)),
            scaleColor(color, 0.62),
            Enum.Material.Slate,
            nil,
            0.08
        ))
    end
end

local function createArenaTorch(parent: Instance, name: string, position: Vector3)
    BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Post", name), 15, 0.6, position + Vector3.new(0, 7.5, 0), Color3.fromRGB(88, 62, 38), Enum.Material.Wood, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Basket", name), Vector3.new(3.2, 1.1, 3.2), CFrame.new(position + Vector3.new(0, 15.4, 0)), Color3.fromRGB(79, 61, 43), Enum.Material.Metal, nil, nil)

    local glow = BuildUtils.CreateSphere(parent, string.format("%s_FlameGlow", name), 3.4, position + Vector3.new(0, 16.3, 0), Color3.fromRGB(255, 183, 84), Enum.Material.Neon, nil)
    glow.CanCollide = false
    BuildUtils.AddPointLight(glow, Color3.fromRGB(255, 187, 106), 2.8, 62)
end

local function createArenaStorySign(parent: Instance, name: string, position: Vector3, yawDegrees: number, title: string, subtitle: string, color: Color3)
    local sign = BuildUtils.CreateWallSign(parent, name, position, Vector3.new(86, 14, 2.5), title, subtitle, color, nil)
    sign.Orientation = Vector3.new(0, yawDegrees, 0)

    return sign
end

local function createCampShelter(parent: Instance, name: string, position: Vector3, clothColor: Color3)
    BuildUtils.CreatePart(parent, string.format("%s_Floor", name), Vector3.new(34, 1, 22), CFrame.new(position + Vector3.new(0, 0.5, 0)), Color3.fromRGB(171, 145, 102), Enum.Material.Sandstone, nil, nil)

    local leftRoof = BuildUtils.CreatePart(parent, string.format("%s_LeftRoof", name), Vector3.new(18, 1, 22), CFrame.new(position + Vector3.new(-8.4, 7.4, 0)) * CFrame.Angles(0, 0, math.rad(22)), clothColor, Enum.Material.Fabric, nil, nil)
    local rightRoof = BuildUtils.CreatePart(parent, string.format("%s_RightRoof", name), Vector3.new(18, 1, 22), CFrame.new(position + Vector3.new(8.4, 7.4, 0)) * CFrame.Angles(0, 0, math.rad(-22)), clothColor, Enum.Material.Fabric, nil, nil)
    leftRoof.CanCollide = true
    rightRoof.CanCollide = true

    BuildUtils.CreatePart(parent, string.format("%s_PoleWest", name), Vector3.new(1, 10, 1), CFrame.new(position + Vector3.new(-9.5, 5, 0)), Color3.fromRGB(95, 70, 44), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_PoleEast", name), Vector3.new(1, 10, 1), CFrame.new(position + Vector3.new(9.5, 5, 0)), Color3.fromRGB(95, 70, 44), Enum.Material.Wood, nil, nil)
end

local function createWell(parent: Instance, name: string, position: Vector3)
    BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Wall", name), 4, 7, position + Vector3.new(0, 2, 0), Color3.fromRGB(168, 143, 107), Enum.Material.Sandstone, nil)
    BuildUtils.CreateVerticalCylinder(parent, string.format("%s_Water", name), 2, 4.8, position + Vector3.new(0, 1.3, 0), Color3.fromRGB(84, 131, 164), Enum.Material.Glass, 0.2)
    BuildUtils.CreatePart(parent, string.format("%s_Beam", name), Vector3.new(20, 1, 1), CFrame.new(position + Vector3.new(0, 8, 0)), Color3.fromRGB(113, 82, 49), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_PostA", name), Vector3.new(1, 10, 1), CFrame.new(position + Vector3.new(-8, 5, 0)), Color3.fromRGB(113, 82, 49), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_PostB", name), Vector3.new(1, 10, 1), CFrame.new(position + Vector3.new(8, 5, 0)), Color3.fromRGB(113, 82, 49), Enum.Material.Wood, nil, nil)
end

local function createBattleMapLabel(parent: BasePart, title: string, subtitle: string)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.CanvasSize = Vector2.new(860, 420)
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 26
    surfaceGui.Parent = parent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(28, 22)
    titleLabel.Size = UDim2.new(0.46, 0, 0, 42)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(55, 45, 31)
    titleLabel.TextSize = 30
    titleLabel.TextWrapped = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = surfaceGui

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(30, 70)
    subtitleLabel.Size = UDim2.new(0.48, 0, 0, 76)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(84, 69, 48)
    subtitleLabel.TextSize = 21
    subtitleLabel.TextWrapped = true
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextYAlignment = Enum.TextYAlignment.Top
    subtitleLabel.Parent = surfaceGui
end

local function createBriefingMarker(parent: Instance, name: string, cframe: CFrame, color: Color3): BasePart
    local marker = BuildUtils.CreatePart(parent, name, Vector3.new(7, 3, 7), cframe, color, Enum.Material.Neon, Enum.PartType.Cylinder, nil)
    marker.CanCollide = false

    return marker
end

local function createBriefingPath(parent: Instance, name: string, cframe: CFrame, color: Color3)
    local path = BuildUtils.CreatePart(parent, name, Vector3.new(54, 0.28, 2.8), cframe, color, Enum.Material.Neon, nil, 0.18)
    path.CanCollide = false
end

local function createTacticalRidge(parent: Instance, name: string, center: Vector3, yawDegrees: number, length: number, height: number, depth: number, color: Color3)
    local folder = BuildUtils.CreateFolder(parent, name)
    local baseCFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(yawDegrees), 0)

    for segment = 1, 9 do
        local alpha = (segment - 5) / 4
        local widthFalloff = 1 - math.abs(alpha) * 0.42
        local segmentLength = length * (0.13 + widthFalloff * 0.035)
        local segmentHeight = height * (0.58 + widthFalloff * 0.48)
        local segmentDepth = depth * (0.54 + widthFalloff * 0.26)
        local x = alpha * length * 0.4
        local z = math.sin(segment * 1.41) * depth * 0.1
        local ridgeCFrame = baseCFrame
            * CFrame.new(x, segmentHeight * 0.5, z)
            * CFrame.Angles(math.rad((segment % 3 - 1) * 4), math.rad(segment % 2 == 0 and -6 or 8), math.rad((segment % 4 - 1.5) * 3))

        makeVisualOnly(BuildUtils.CreateWedge(
            folder,
            string.format("RidgeFace_%d", segment),
            Vector3.new(segmentLength, segmentHeight, segmentDepth),
            ridgeCFrame,
            scaleColor(color, 0.82 + widthFalloff * 0.18),
            Enum.Material.Rock,
            nil
        ))
    end

    for layer = 1, 3 do
        makeVisualOnly(BuildUtils.CreatePart(
            folder,
            string.format("Strata_%d", layer),
            Vector3.new(length * (0.86 - layer * 0.12), 0.28, 1.15),
            baseCFrame * CFrame.new(0, height * (0.2 + layer * 0.18), depth * (-0.32 + layer * 0.16)) * CFrame.Angles(0, math.rad(layer % 2 == 0 and -5 or 4), 0),
            scaleColor(color, 0.58 + layer * 0.08),
            Enum.Material.Slate,
            nil,
            0.05
        ))
    end
end

local function createSafetyBounds(parent: Instance, center: Vector3, size: Vector3)
    local wallHeight = 90
    local thickness = 10

    BuildUtils.CreatePart(parent, "SafetyFloor", Vector3.new(size.X + 180, 10, size.Z + 180), CFrame.new(center + Vector3.new(0, -8, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "NorthBarrier", Vector3.new(size.X + 180, wallHeight, thickness), CFrame.new(center + Vector3.new(0, 22, size.Z * -0.5 - 90)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "SouthBarrier", Vector3.new(size.X + 180, wallHeight, thickness), CFrame.new(center + Vector3.new(0, 22, size.Z * 0.5 + 90)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "WestBarrier", Vector3.new(thickness, wallHeight, size.Z + 180), CFrame.new(center + Vector3.new(size.X * -0.5 - 90, 22, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "EastBarrier", Vector3.new(thickness, wallHeight, size.Z + 180), CFrame.new(center + Vector3.new(size.X * 0.5 + 90, 22, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
end

local function createActorRig(parent: Instance, name: string, cframe: CFrame, outfitColor: Color3, accentColor: Color3, scale: number?): Model
    local s = scale or 1
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local root = BuildUtils.CreatePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1) * s, cframe, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    root.CanCollide = false

    BuildUtils.CreatePart(model, "Torso", Vector3.new(3.2, 4.2, 2.1) * s, cframe * CFrame.new(0, 3.2 * s, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "ChestSash", Vector3.new(3.55, 0.5, 2.25) * s, cframe * CFrame.new(0, 4.15 * s, -0.05 * s) * CFrame.Angles(0, 0, math.rad(-9)), accentColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreateSphere(model, "Head", 2.05 * s, (cframe * CFrame.new(0, 6.1 * s, 0)).Position, Color3.fromRGB(229, 201, 171), Enum.Material.SmoothPlastic, nil)
    BuildUtils.CreatePart(model, "HeadWrap", Vector3.new(2.45, 1.0, 2.45) * s, cframe * CFrame.new(0, 6.76 * s, 0), accentColor, Enum.Material.Fabric, Enum.PartType.Ball, nil)
    BuildUtils.CreateVerticalCylinder(model, "LeftArm", 3.6 * s, 0.58 * s, (cframe * CFrame.new(-2.1 * s, 3.1 * s, 0)).Position, outfitColor, Enum.Material.Fabric, nil)
    BuildUtils.CreateVerticalCylinder(model, "RightArm", 3.6 * s, 0.58 * s, (cframe * CFrame.new(2.1 * s, 3.1 * s, 0)).Position, outfitColor, Enum.Material.Fabric, nil)
    BuildUtils.CreateSphere(model, "LeftShoulder", 1.2 * s, (cframe * CFrame.new(-2.05 * s, 4.8 * s, 0)).Position, outfitColor, Enum.Material.Fabric, nil)
    BuildUtils.CreateSphere(model, "RightShoulder", 1.2 * s, (cframe * CFrame.new(2.05 * s, 4.8 * s, 0)).Position, outfitColor, Enum.Material.Fabric, nil)
    BuildUtils.CreateVerticalCylinder(model, "LeftLeg", 3.8 * s, 0.58 * s, (cframe * CFrame.new(-0.8 * s, 0.7 * s, 0)).Position, accentColor, Enum.Material.Fabric, nil)
    BuildUtils.CreateVerticalCylinder(model, "RightLeg", 3.8 * s, 0.58 * s, (cframe * CFrame.new(0.8 * s, 0.7 * s, 0)).Position, accentColor, Enum.Material.Fabric, nil)
    BuildUtils.CreatePart(model, "SwordHandle", Vector3.new(0.28, 1.2, 0.28) * s, cframe * CFrame.new(2.72 * s, 3.6 * s, -0.2 * s), Color3.fromRGB(96, 62, 37), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(model, "SwordBlade", Vector3.new(0.2, 4.2, 0.34) * s, cframe * CFrame.new(2.72 * s, 5.9 * s, -0.2 * s), Color3.fromRGB(214, 214, 210), Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(model, "Shield", Vector3.new(0.42, 2.5, 2.2) * s, cframe * CFrame.new(-2.8 * s, 3.3 * s, -0.1 * s), Color3.fromRGB(103, 78, 47), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(model, "ShieldBoss", Vector3.new(0.5, 0.72, 0.72) * s, cframe * CFrame.new(-3.04 * s, 3.3 * s, -0.1 * s), Color3.fromRGB(179, 149, 87), Enum.Material.Metal, Enum.PartType.Ball, nil)

    model.PrimaryPart = root

    return model
end

local function createArenaBase(parent: Instance, scenarioId: string, center: Vector3, size: Vector3, color: Color3)
    local arenaFolder = BuildUtils.CreateFolder(parent, scenarioId)
    local geometry = BuildUtils.CreateFolder(arenaFolder, "Geometry")
    local spawns = BuildUtils.CreateFolder(arenaFolder, "Spawns")
    local dummies = BuildUtils.CreateFolder(arenaFolder, "DummySpawns")

    BuildUtils.CreatePart(geometry, "BaseFloor", size, CFrame.new(center + Vector3.new(0, 1, 0)), color, Enum.Material.Sand, nil, nil)
    createSafetyBounds(geometry, center, size)

    return arenaFolder, geometry, spawns, dummies
end

local function addSpawnAnchors(parent: Instance, teamId: string, positions: { Vector3 })
    local teamFolder = BuildUtils.CreateFolder(parent, teamId)

    for index, position in ipairs(positions) do
        BuildUtils.CreateTeleportAnchor(teamFolder, string.format("%s_%d", teamId, index), position)
    end
end

local function createReenactmentSection(arenaFolder: Folder, center: Vector3, scenarioId: string, medinaColor: Color3, makkahColor: Color3)
    local reenactment = BuildUtils.CreateFolder(arenaFolder, "Reenactment")
    local geometry = BuildUtils.CreateFolder(reenactment, "Geometry")
    local cameras = BuildUtils.CreateFolder(reenactment, "Cameras")
    local marks = BuildUtils.CreateFolder(reenactment, "Marks")
    local actors = BuildUtils.CreateFolder(reenactment, "Actors")

    BuildUtils.CreatePart(geometry, "StageFloor", Vector3.new(156, 2, 118), CFrame.new(center + Vector3.new(0, 1.1, 0)), Color3.fromRGB(182, 154, 112), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(geometry, "BackRock", Vector3.new(168, 32, 28), CFrame.new(center + Vector3.new(0, 16, -64)), Color3.fromRGB(147, 119, 83), Enum.Material.Rock, nil, nil)
    BuildUtils.CreatePart(geometry, "ForegroundRise", Vector3.new(142, 8, 22), CFrame.new(center + Vector3.new(0, 4.2, 52)), Color3.fromRGB(167, 137, 94), Enum.Material.Rock, nil, nil)

    if scenarioId == "uhud" then
        createTacticalRidge(geometry, "UhudBackdropMass", center + Vector3.new(0, 8, -50), -2, 138, 34, 30, Color3.fromRGB(132, 104, 74))
        createTacticalRidge(geometry, "UhudBackdropRidge", center + Vector3.new(-34, 7.2, -12), -18, 54, 18, 20, Color3.fromRGB(111, 90, 66))
        BuildUtils.CreatePart(geometry, "UhudRidgeShelf", Vector3.new(58, 2.2, 18), CFrame.new(center + Vector3.new(-30, 10, -10)) * CFrame.Angles(0, math.rad(-18), 0), Color3.fromRGB(122, 98, 73), Enum.Material.Slate, nil, nil)
        BuildUtils.CreatePart(geometry, "UhudDustBand", Vector3.new(120, 0.3, 20), CFrame.new(center + Vector3.new(8, 2.5, 20)), Color3.fromRGB(216, 193, 151), Enum.Material.Sand, nil, 0.2)
        createArenaTorch(geometry, "ReenactmentTorchWest", center + Vector3.new(-58, 0, 36))
        createArenaTorch(geometry, "ReenactmentTorchEast", center + Vector3.new(58, 0, 30))
    end

    local camera1 = BuildUtils.CreateTeleportAnchor(cameras, "Scene1", center + Vector3.new(-48, 22, 42))
    camera1.CFrame = CFrame.new(center + Vector3.new(-48, 22, 42), center + Vector3.new(0, 8, -4))
    local camera2 = BuildUtils.CreateTeleportAnchor(cameras, "Scene2", center + Vector3.new(0, 18, 58))
    camera2.CFrame = CFrame.new(center + Vector3.new(0, 18, 58), center + Vector3.new(0, 8, 0))
    local camera3 = BuildUtils.CreateTeleportAnchor(cameras, "Scene3", center + Vector3.new(52, 26, 36))
    camera3.CFrame = CFrame.new(center + Vector3.new(52, 26, 36), center + Vector3.new(0, 10, -6))
    local camera4 = BuildUtils.CreateTeleportAnchor(cameras, "Scene4", center + Vector3.new(0, 30, -78))
    camera4.CFrame = CFrame.new(center + Vector3.new(0, 30, -78), center + Vector3.new(0, 9, 8))
    local camera5 = BuildUtils.CreateTeleportAnchor(cameras, "Scene5", center + Vector3.new(-18, 24, 86))
    camera5.CFrame = CFrame.new(center + Vector3.new(-18, 24, 86), center + Vector3.new(0, 9, -8))

    local medinaLeadStart = BuildUtils.CreateTeleportAnchor(marks, "MedinaLeadStart", center + Vector3.new(-26, 0, 12))
    medinaLeadStart.CFrame = CFrame.new(medinaLeadStart.Position, center + Vector3.new(12, 0, 0))
    local medinaSupportStart = BuildUtils.CreateTeleportAnchor(marks, "MedinaSupportStart", center + Vector3.new(-40, 0, -2))
    medinaSupportStart.CFrame = CFrame.new(medinaSupportStart.Position, center + Vector3.new(14, 0, 0))
    local medinaLeadAdvance = BuildUtils.CreateTeleportAnchor(marks, "MedinaLeadAdvance", center + Vector3.new(-4, 0, 6))
    medinaLeadAdvance.CFrame = CFrame.new(medinaLeadAdvance.Position, center + Vector3.new(18, 0, 0))
    local medinaSupportAdvancePosition = (scenarioId == "uhud") and (center + Vector3.new(-6, 0, -20)) or (center + Vector3.new(-18, 0, -8))
    local medinaSupportAdvance = BuildUtils.CreateTeleportAnchor(marks, "MedinaSupportAdvance", medinaSupportAdvancePosition)
    medinaSupportAdvance.CFrame = CFrame.new(medinaSupportAdvance.Position, center + Vector3.new(16, 0, 0))
    local makkahLeadStart = BuildUtils.CreateTeleportAnchor(marks, "MakkahLeadStart", center + Vector3.new(28, 0, 6))
    makkahLeadStart.CFrame = CFrame.new(makkahLeadStart.Position, center + Vector3.new(-16, 0, 0))
    local makkahSupportStart = BuildUtils.CreateTeleportAnchor(marks, "MakkahSupportStart", center + Vector3.new(40, 0, -10))
    makkahSupportStart.CFrame = CFrame.new(makkahSupportStart.Position, center + Vector3.new(-14, 0, 0))
    local makkahLeadRetreatPosition = (scenarioId == "uhud") and (center + Vector3.new(18, 0, 18)) or (center + Vector3.new(52, 0, 18))
    local makkahLeadRetreat = BuildUtils.CreateTeleportAnchor(marks, "MakkahLeadRetreat", makkahLeadRetreatPosition)
    makkahLeadRetreat.CFrame = CFrame.new(makkahLeadRetreat.Position, center + Vector3.new(-22, 0, 0))
    local makkahSupportRetreatPosition = (scenarioId == "uhud") and (center + Vector3.new(34, 0, 6)) or (center + Vector3.new(60, 0, -2))
    local makkahSupportRetreat = BuildUtils.CreateTeleportAnchor(marks, "MakkahSupportRetreat", makkahSupportRetreatPosition)
    makkahSupportRetreat.CFrame = CFrame.new(makkahSupportRetreat.Position, center + Vector3.new(-22, 0, 0))
    local makkahCommanderStart = BuildUtils.CreateTeleportAnchor(marks, "MakkahCommanderStart", center + Vector3.new(58, 0, 24))
    makkahCommanderStart.CFrame = CFrame.new(makkahCommanderStart.Position, center + Vector3.new(-16, 0, -6))
    local makkahCommanderAdvance = BuildUtils.CreateTeleportAnchor(marks, "MakkahCommanderAdvance", center + Vector3.new(16, 0, 18))
    makkahCommanderAdvance.CFrame = CFrame.new(makkahCommanderAdvance.Position, center + Vector3.new(-22, 0, 0))
    local makkahCommanderDefeat = BuildUtils.CreateTeleportAnchor(marks, "MakkahCommanderDefeat", center + Vector3.new(36, 0, 36))
    makkahCommanderDefeat.CFrame = CFrame.new(makkahCommanderDefeat.Position, center + Vector3.new(-18, 0, -8))

    createActorRig(actors, "MedinaLead", medinaLeadStart.CFrame, medinaColor, Color3.fromRGB(40, 71, 48))
    createActorRig(actors, "MedinaSupport", medinaSupportStart.CFrame, medinaColor, Color3.fromRGB(40, 71, 48))
    createActorRig(actors, "MakkahLead", makkahLeadStart.CFrame, makkahColor, Color3.fromRGB(97, 67, 43))
    createActorRig(actors, "MakkahSupport", makkahSupportStart.CFrame, makkahColor, Color3.fromRGB(97, 67, 43))
    createActorRig(actors, "MakkahCommander", makkahCommanderStart.CFrame, Color3.fromRGB(173, 108, 56), Color3.fromRGB(112, 63, 35), 1.35)
    BuildUtils.CreateBanner(actors, "MakkahCommanderBanner", center + Vector3.new(63, 0, 30), Color3.fromRGB(146, 82, 48))
    BuildUtils.CreateBanner(actors, "MedinaStandard", center + Vector3.new(-58, 0, 24), medinaColor)

    local rankCount = (scenarioId == "uhud") and 5 or 3

    for index = 1, rankCount do
        createActorRig(actors, string.format("MedinaRank%d", index), CFrame.new(center + Vector3.new(-48, 0, -26 + index * 12), center + Vector3.new(8, 0, 0)), medinaColor, Color3.fromRGB(40, 71, 48))
        createActorRig(actors, string.format("MakkahRank%d", index), CFrame.new(center + Vector3.new(52, 0, -28 + index * 12), center + Vector3.new(-8, 0, 0)), makkahColor, Color3.fromRGB(97, 67, 43))
    end

    local spectatorAnchor = BuildUtils.CreateTeleportAnchor(arenaFolder, "SpectatorAnchor", center + Vector3.new(0, 34, 176))
    spectatorAnchor.CFrame = CFrame.new(spectatorAnchor.Position, center)
end

local function createBriefingSection(arenaFolder: Folder, center: Vector3, scenarioId: string, medinaColor: Color3, makkahColor: Color3)
    local briefing = BuildUtils.CreateFolder(arenaFolder, "Briefing")
    local geometry = BuildUtils.CreateFolder(briefing, "Geometry")
    local cameras = BuildUtils.CreateFolder(briefing, "Cameras")
    local markers = BuildUtils.CreateFolder(briefing, "Markers")
    local actors = BuildUtils.CreateFolder(briefing, "Actors")

    if scenarioId == "uhud" then
        BuildUtils.CreatePart(geometry, "BriefingGround", Vector3.new(176, 2, 128), CFrame.new(center + Vector3.new(0, 1, 0)), Color3.fromRGB(188, 160, 120), Enum.Material.Sand, nil, nil)
        BuildUtils.CreateDune(geometry, "BriefingFrontRise", center + Vector3.new(0, 0, 46), Vector3.new(164, 34, 56), Color3.fromRGB(198, 170, 126))
        BuildUtils.CreateDune(geometry, "BriefingRearSlope", center + Vector3.new(0, 0, -34), Vector3.new(146, 28, 44), Color3.fromRGB(186, 156, 118))
        BuildUtils.CreateMountain(geometry, "BriefingUhudMass", center + Vector3.new(8, 0, -34), 216, 112, 84, Color3.fromRGB(145, 116, 83), -4)
        BuildUtils.CreateMountain(geometry, "BriefingUhudWestRidge", center + Vector3.new(-50, 0, 10), 132, 54, 54, Color3.fromRGB(132, 106, 79), -18)
        BuildUtils.CreateMountain(geometry, "BriefingUhudFlankShelf", center + Vector3.new(48, 0, 20), 120, 44, 48, Color3.fromRGB(139, 112, 82), 16)
        createMountainFaceDetails(geometry, "BriefingUhudMassFaces", center + Vector3.new(8, 0, -28), -4, 216, 112, 84, Color3.fromRGB(145, 116, 83))
        createMountainFaceDetails(geometry, "BriefingUhudWestFaces", center + Vector3.new(-50, 0, 14), -18, 132, 54, 54, Color3.fromRGB(132, 106, 79))
        createMountainFaceDetails(geometry, "BriefingUhudFlankFaces", center + Vector3.new(48, 0, 24), 16, 120, 44, 48, Color3.fromRGB(139, 112, 82))
        BuildUtils.CreatePart(geometry, "BriefingPass", Vector3.new(122, 1, 26), CFrame.new(center + Vector3.new(-2, 2.05, 10)) * CFrame.Angles(0, math.rad(-8), 0), Color3.fromRGB(170, 141, 102), Enum.Material.Sandstone, nil, nil)
        BuildUtils.CreatePart(geometry, "BriefingArcherShelf", Vector3.new(78, 2.2, 18), CFrame.new(center + Vector3.new(-44, 18, -2)) * CFrame.Angles(0, math.rad(-18), 0), Color3.fromRGB(127, 103, 79), Enum.Material.Slate, nil, nil)
        BuildUtils.CreatePart(geometry, "BriefingFlankPath", Vector3.new(72, 1.2, 18), CFrame.new(center + Vector3.new(38, 14, 18)) * CFrame.Angles(0, math.rad(18), 0), Color3.fromRGB(142, 117, 90), Enum.Material.Slate, nil, nil)
        BuildUtils.CreateRockCluster(geometry, "BriefingPassRocksWest", center + Vector3.new(-46, 0, 24))
        BuildUtils.CreateRockCluster(geometry, "BriefingPassRocksCenter", center + Vector3.new(2, 0, 18))
        BuildUtils.CreateRockCluster(geometry, "BriefingPassRocksEast", center + Vector3.new(40, 0, 26))
        createCampShelter(geometry, "BriefingCampWest", center + Vector3.new(-64, 0, 34), Color3.fromRGB(74, 121, 82))
        createCampShelter(geometry, "BriefingCampEast", center + Vector3.new(66, 0, 34), Color3.fromRGB(143, 101, 66))
        BuildUtils.CreateBanner(geometry, "BriefingBannerWest", center + Vector3.new(-76, 0, 16), medinaColor)
        BuildUtils.CreateBanner(geometry, "BriefingBannerEast", center + Vector3.new(78, 0, 24), makkahColor)
        createArenaTorch(geometry, "BriefingTorchWest", center + Vector3.new(-74, 0, 52))
        createArenaTorch(geometry, "BriefingTorchEast", center + Vector3.new(76, 0, 52))
        createArenaStorySign(geometry, "BriefingRidgeSign", center + Vector3.new(-58, 0, -8), 150, "Archer Ridge", "The ridge is shown as a real shelf above the pass so the command to hold it feels physical, not abstract.", Color3.fromRGB(77, 96, 72))
        createArenaStorySign(geometry, "BriefingPassSign", center + Vector3.new(24, 0, 54), 0, "The Pass", "This route lets players see how one opening could reshape the whole battle.", Color3.fromRGB(108, 80, 55))

        local camera1 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap1", center + Vector3.new(-116, 40, 88))
        camera1.CFrame = CFrame.new(camera1.Position, center + Vector3.new(-12, 16, 2))
        local camera2 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap2", center + Vector3.new(-74, 34, 34))
        camera2.CFrame = CFrame.new(camera2.Position, center + Vector3.new(-46, 22, -2))
        local camera3 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap3", center + Vector3.new(-8, 30, 80))
        camera3.CFrame = CFrame.new(camera3.Position, center + Vector3.new(-4, 10, 10))
        local camera4 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap4", center + Vector3.new(70, 36, 58))
        camera4.CFrame = CFrame.new(camera4.Position, center + Vector3.new(28, 16, 18))
        local camera5 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap5", center + Vector3.new(26, 24, -66))
        camera5.CFrame = CFrame.new(camera5.Position, center + Vector3.new(4, 12, 8))
        local camera6 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap6", center + Vector3.new(-12, 46, -28))
        camera6.CFrame = CFrame.new(camera6.Position, center + Vector3.new(-6, 10, 12))

        local medinaLeadStart = BuildUtils.CreateTeleportAnchor(markers, "BriefingMedinaLeadStart", center + Vector3.new(-62, 0, 10))
        medinaLeadStart.CFrame = CFrame.new(medinaLeadStart.Position, center + Vector3.new(-6, 0, 8))
        local medinaLeadAdvance = BuildUtils.CreateTeleportAnchor(markers, "BriefingMedinaLeadAdvance", center + Vector3.new(-12, 0, 12))
        medinaLeadAdvance.CFrame = CFrame.new(medinaLeadAdvance.Position, center + Vector3.new(18, 0, 8))
        local medinaSupportStart = BuildUtils.CreateTeleportAnchor(markers, "BriefingMedinaSupportStart", center + Vector3.new(-80, 0, 24))
        medinaSupportStart.CFrame = CFrame.new(medinaSupportStart.Position, center + Vector3.new(-18, 0, 12))
        local medinaSupportAdvance = BuildUtils.CreateTeleportAnchor(markers, "BriefingMedinaSupportAdvance", center + Vector3.new(-30, 0, 16))
        medinaSupportAdvance.CFrame = CFrame.new(medinaSupportAdvance.Position, center + Vector3.new(12, 0, 8))
        local makkahLeadStart = BuildUtils.CreateTeleportAnchor(markers, "BriefingMakkahLeadStart", center + Vector3.new(74, 14, 30))
        makkahLeadStart.CFrame = CFrame.new(makkahLeadStart.Position, center + Vector3.new(18, 8, 16))
        local makkahLeadAdvance = BuildUtils.CreateTeleportAnchor(markers, "BriefingMakkahLeadAdvance", center + Vector3.new(26, 6, 18))
        makkahLeadAdvance.CFrame = CFrame.new(makkahLeadAdvance.Position, center + Vector3.new(-12, 4, 10))
        local makkahSupportStart = BuildUtils.CreateTeleportAnchor(markers, "BriefingMakkahSupportStart", center + Vector3.new(86, 14, 14))
        makkahSupportStart.CFrame = CFrame.new(makkahSupportStart.Position, center + Vector3.new(22, 8, 8))
        local makkahSupportAdvance = BuildUtils.CreateTeleportAnchor(markers, "BriefingMakkahSupportAdvance", center + Vector3.new(40, 6, 4))
        makkahSupportAdvance.CFrame = CFrame.new(makkahSupportAdvance.Position, center + Vector3.new(-6, 4, 2))

        createActorRig(actors, "BriefingMedinaLead", medinaLeadStart.CFrame, medinaColor, Color3.fromRGB(40, 71, 48))
        createActorRig(actors, "BriefingMedinaSupport", medinaSupportStart.CFrame, medinaColor, Color3.fromRGB(40, 71, 48))
        createActorRig(actors, "BriefingMakkahLead", makkahLeadStart.CFrame, makkahColor, Color3.fromRGB(97, 67, 43))
        createActorRig(actors, "BriefingMakkahSupport", makkahSupportStart.CFrame, makkahColor, Color3.fromRGB(97, 67, 43))

        for index = 1, 4 do
            local archerPosition = center + Vector3.new(-68 + index * 12, 20.4, -6 + ((index % 2 == 0) and -1.2 or 1.2))
            createActorRig(
                actors,
                string.format("BriefingArcher%d", index),
                CFrame.new(archerPosition, center + Vector3.new(22, 10, 10)),
                medinaColor,
                Color3.fromRGB(51, 83, 58),
                0.94
            )
        end

        for index = 1, 4 do
            createActorRig(
                actors,
                string.format("BriefingMedinaRank%d", index),
                CFrame.new(center + Vector3.new(-70 + index * 8, 0, 32 + index * 4), center + Vector3.new(12, 0, 16)),
                medinaColor,
                Color3.fromRGB(40, 71, 48),
                0.96
            )
            createActorRig(
                actors,
                string.format("BriefingMakkahRank%d", index),
                CFrame.new(center + Vector3.new(50 + index * 7, 14, 30 - index * 5), center + Vector3.new(-10, 8, 10)),
                makkahColor,
                Color3.fromRGB(97, 67, 43),
                0.96
            )
        end

        return
    end

    BuildUtils.CreatePart(geometry, "BriefingDeck", Vector3.new(150, 3, 118), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(169, 140, 101), Enum.Material.Sandstone, nil, nil)
    local tableTop = BuildUtils.CreatePart(geometry, "AnimatedMapTable", Vector3.new(116, 2, 72), CFrame.new(center + Vector3.new(0, 6, 0)), Color3.fromRGB(225, 203, 160), Enum.Material.WoodPlanks, nil, nil)
    createBattleMapLabel(
        tableTop,
        "Badr Tactical Map",
        "Route, valley, wells, and two approaching sides."
    )

    BuildUtils.CreatePart(geometry, "MapFrameNorth", Vector3.new(122, 3, 4), CFrame.new(center + Vector3.new(0, 8, -38)), Color3.fromRGB(97, 67, 42), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(geometry, "MapFrameSouth", Vector3.new(122, 3, 4), CFrame.new(center + Vector3.new(0, 8, 38)), Color3.fromRGB(97, 67, 42), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(geometry, "MapFrameWest", Vector3.new(4, 3, 78), CFrame.new(center + Vector3.new(-62, 8, 0)), Color3.fromRGB(97, 67, 42), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(geometry, "MapFrameEast", Vector3.new(4, 3, 78), CFrame.new(center + Vector3.new(62, 8, 0)), Color3.fromRGB(97, 67, 42), Enum.Material.Wood, nil, nil)

    local camera1 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap1", center + Vector3.new(-84, 34, 72))
    camera1.CFrame = CFrame.new(camera1.Position, center + Vector3.new(0, 7, 0))
    local camera2 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap2", center + Vector3.new(0, 68, 8))
    camera2.CFrame = CFrame.new(camera2.Position, center + Vector3.new(0, 6, 0))
    local camera3 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap3", center + Vector3.new(76, 34, 62))
    camera3.CFrame = CFrame.new(camera3.Position, center + Vector3.new(0, 7, 0))
    local camera4 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap4", center + Vector3.new(0, 30, -76))
    camera4.CFrame = CFrame.new(camera4.Position, center + Vector3.new(0, 8, 6))
    local camera5 = BuildUtils.CreateTeleportAnchor(cameras, "BriefingMap5", center + Vector3.new(-64, 30, -58))
    camera5.CFrame = CFrame.new(camera5.Position, center + Vector3.new(4, 8, 4))

    createBriefingPath(markers, "RoutePath", CFrame.new(center + Vector3.new(-8, 8.1, 0)) * CFrame.Angles(0, math.rad(14), 0), Color3.fromRGB(246, 221, 143))
    BuildUtils.CreateVerticalCylinder(markers, "WellMarkerA", 1.4, 4.2, center + Vector3.new(20, 9, -14), Color3.fromRGB(86, 145, 174), Enum.Material.Glass, 0.2)
    BuildUtils.CreateVerticalCylinder(markers, "WellMarkerB", 1.4, 3.6, center + Vector3.new(30, 9, 6), Color3.fromRGB(86, 145, 174), Enum.Material.Glass, 0.2)
    createTacticalRidge(markers, "ValleyRidge", center + Vector3.new(0, 8.2, -26), 2, 96, 5.5, 10, Color3.fromRGB(139, 111, 76))
    createBriefingMarker(markers, "MedinaMapMarker", CFrame.new(center + Vector3.new(-42, 10, 16)), medinaColor)
    createBriefingMarker(markers, "MakkahMapMarker", CFrame.new(center + Vector3.new(48, 10, -12)), makkahColor)
    local medinaTarget = createBriefingMarker(markers, "MedinaMapTarget", CFrame.new(center + Vector3.new(-10, 10, 8)), medinaColor)
    medinaTarget.Transparency = 1
    local makkahTarget = createBriefingMarker(markers, "MakkahMapTarget", CFrame.new(center + Vector3.new(12, 10, -4)), makkahColor)
    makkahTarget.Transparency = 1

    createActorRig(geometry, "BriefingGuide", CFrame.new(center + Vector3.new(0, 0, 58), center), Color3.fromRGB(92, 112, 82), Color3.fromRGB(57, 68, 50))
    BuildUtils.CreateBanner(geometry, "BriefingBannerWest", center + Vector3.new(-68, 0, 42), medinaColor)
    BuildUtils.CreateBanner(geometry, "BriefingBannerEast", center + Vector3.new(68, 0, 42), makkahColor)
end

local function buildBadrArena(parent: Instance, scenario)
    local arenaFolder, geometry, spawns, dummies = createArenaBase(
        parent,
        scenario.Id,
        Vector3.new(-1150, 0, 720),
        Vector3.new(760, 2, 460),
        Color3.fromRGB(209, 181, 131)
    )

    createMountain(geometry, "NorthMountainA", Vector3.new(-1400, 0, 520), 280, 156, 160, Color3.fromRGB(154, 126, 89))
    createMountain(geometry, "NorthMountainB", Vector3.new(-1138, 0, 500), 320, 172, 176, Color3.fromRGB(149, 121, 86))
    createMountain(geometry, "NorthMountainC", Vector3.new(-900, 0, 524), 240, 136, 140, Color3.fromRGB(151, 123, 89))
    createMountain(geometry, "SouthMountainA", Vector3.new(-1372, 0, 958), 296, 144, 176, Color3.fromRGB(158, 130, 96))
    createMountain(geometry, "SouthMountainB", Vector3.new(-1098, 0, 978), 342, 176, 190, Color3.fromRGB(150, 122, 86))
    createMountain(geometry, "SouthMountainC", Vector3.new(-886, 0, 952), 238, 132, 156, Color3.fromRGB(153, 125, 88))
    createMountainFaceDetails(geometry, "BadrNorthMountainFaces", Vector3.new(-1138, 0, 506), 0, 660, 172, 176, Color3.fromRGB(149, 121, 86))
    createMountainFaceDetails(geometry, "BadrSouthMountainFaces", Vector3.new(-1120, 0, 956), 180, 700, 176, 190, Color3.fromRGB(153, 125, 88))
    BuildUtils.CreateDune(geometry, "ValleyDuneWest", Vector3.new(-1368, 0, 730), Vector3.new(170, 34, 82), Color3.fromRGB(220, 189, 130))
    BuildUtils.CreateDune(geometry, "ValleyDuneEast", Vector3.new(-938, 0, 698), Vector3.new(170, 34, 88), Color3.fromRGB(218, 186, 128))
    BuildUtils.CreateDune(geometry, "CentralRise", Vector3.new(-1142, 0, 790), Vector3.new(220, 28, 66), Color3.fromRGB(211, 181, 126))
    BuildUtils.CreateRockCluster(geometry, "ValleyRocksWest", Vector3.new(-1290, 0, 784))
    BuildUtils.CreateRockCluster(geometry, "ValleyRocksEast", Vector3.new(-1002, 0, 664))
    BuildUtils.CreateRockCluster(geometry, "ValleyRocksCenter", Vector3.new(-1136, 0, 708))
    BuildUtils.CreatePart(geometry, "CentralPath", Vector3.new(440, 1, 70), CFrame.new(-1150, 2.05, 720), Color3.fromRGB(184, 152, 103), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(geometry, "MedinaCamp", Vector3.new(136, 2, 96), CFrame.new(-1376, 2.1, 720), Color3.fromRGB(168, 139, 93), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(geometry, "MakkahCamp", Vector3.new(136, 2, 96), CFrame.new(-924, 2.1, 720), Color3.fromRGB(171, 139, 90), Enum.Material.Sandstone, nil, nil)
    createCampShelter(geometry, "MedinaCampShelter", Vector3.new(-1376, 0, 720), Color3.fromRGB(74, 121, 82))
    createCampShelter(geometry, "MakkahCampShelter", Vector3.new(-924, 0, 720), Color3.fromRGB(143, 101, 66))
    BuildUtils.CreateBanner(geometry, "BadrBannerWest", Vector3.new(-1342, 0, 694), Color3.fromRGB(62, 125, 82))
    BuildUtils.CreateBanner(geometry, "BadrBannerEast", Vector3.new(-954, 0, 746), Color3.fromRGB(155, 108, 58))
    createWell(geometry, "WellA", Vector3.new(-1230, 0, 674))
    createWell(geometry, "WellB", Vector3.new(-1212, 0, 744))
    createWell(geometry, "WellC", Vector3.new(-1190, 0, 702))
    createArenaTorch(geometry, "BadrTorchMedinaCampA", Vector3.new(-1320, 0, 634))
    createArenaTorch(geometry, "BadrTorchMedinaCampB", Vector3.new(-1320, 0, 806))
    createArenaTorch(geometry, "BadrTorchMakkahCampA", Vector3.new(-980, 0, 634))
    createArenaTorch(geometry, "BadrTorchMakkahCampB", Vector3.new(-980, 0, 806))
    createArenaTorch(geometry, "BadrTorchWells", Vector3.new(-1210, 0, 628))
    createArenaStorySign(geometry, "BadrWellsStory", Vector3.new(-1210, 0, 612), 0, "The Wells Of Badr", "Badr took place in 2 AH / 624 CE. The wells and valley position shaped how the scene is taught here.", Color3.fromRGB(96, 78, 52))

    addSpawnAnchors(spawns, "medina", scenario.SpawnPositions.medina)
    addSpawnAnchors(spawns, "makkah", scenario.SpawnPositions.makkah)
    addSpawnAnchors(dummies, "medina", {
        Vector3.new(-1322, 10, 770),
        Vector3.new(-1305, 10, 670),
        Vector3.new(-1286, 10, 722),
    })
    addSpawnAnchors(dummies, "makkah", {
        Vector3.new(-980, 10, 772),
        Vector3.new(-995, 10, 668),
        Vector3.new(-1012, 10, 724),
    })

    createReenactmentSection(arenaFolder, Vector3.new(-1150, 0, 532), scenario.Id, Color3.fromRGB(71, 127, 86), Color3.fromRGB(149, 102, 61))
    createBriefingSection(arenaFolder, Vector3.new(-790, 0, 720), scenario.Id, Color3.fromRGB(71, 127, 86), Color3.fromRGB(149, 102, 61))
    arenaFolder:SetAttribute("ScenarioId", scenario.Id)
end

local function buildUhudArena(parent: Instance, scenario)
    local arenaFolder, geometry, spawns, dummies = createArenaBase(
        parent,
        scenario.Id,
        Vector3.new(-1150, 0, 1180),
        Vector3.new(860, 2, 540),
        Color3.fromRGB(198, 169, 127)
    )

    createMountain(geometry, "UhudRidgeWest", Vector3.new(-1458, 0, 990), 344, 214, 196, Color3.fromRGB(147, 118, 84))
    createMountain(geometry, "UhudMainMass", Vector3.new(-1150, 0, 944), 548, 272, 246, Color3.fromRGB(144, 116, 82))
    createMountain(geometry, "UhudRidgeEast", Vector3.new(-854, 0, 1002), 338, 206, 194, Color3.fromRGB(149, 121, 86))
    createMountain(geometry, "UhudRearSlope", Vector3.new(-1152, 0, 842), 420, 146, 136, Color3.fromRGB(145, 118, 86))
    createMountain(geometry, "UhudNorthWall", Vector3.new(-1152, 0, 730), 626, 178, 110, Color3.fromRGB(132, 106, 77))
    createMountain(geometry, "UhudPassShelfWest", Vector3.new(-1360, 0, 1168), 228, 84, 122, Color3.fromRGB(136, 110, 81))
    createMountain(geometry, "UhudPassShelfEast", Vector3.new(-964, 0, 1108), 224, 72, 116, Color3.fromRGB(141, 115, 84))
    createMountainFaceDetails(geometry, "UhudWestRidgeFaces", Vector3.new(-1458, 0, 1002), 2, 344, 214, 196, Color3.fromRGB(147, 118, 84))
    createMountainFaceDetails(geometry, "UhudMainMassFaces", Vector3.new(-1150, 0, 962), 0, 548, 272, 246, Color3.fromRGB(144, 116, 82))
    createMountainFaceDetails(geometry, "UhudEastRidgeFaces", Vector3.new(-854, 0, 1010), -3, 338, 206, 194, Color3.fromRGB(149, 121, 86))
    createMountainFaceDetails(geometry, "UhudRearSlopeFaces", Vector3.new(-1152, 0, 842), 180, 420, 146, 136, Color3.fromRGB(145, 118, 86))
    createMountainFaceDetails(geometry, "UhudNorthWallFaces", Vector3.new(-1152, 0, 734), 180, 626, 178, 110, Color3.fromRGB(132, 106, 77))
    BuildUtils.CreateDune(geometry, "SouthSlope", Vector3.new(-1180, 0, 1416), Vector3.new(404, 58, 144), Color3.fromRGB(194, 164, 122))
    BuildUtils.CreateDune(geometry, "SouthFlankRise", Vector3.new(-982, 0, 1298), Vector3.new(232, 46, 104), Color3.fromRGB(188, 159, 118))
    BuildUtils.CreatePart(geometry, "BattlePass", Vector3.new(470, 1, 82), CFrame.new(-1150, 2.05, 1180), Color3.fromRGB(173, 142, 101), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(geometry, "BattlePassDustBand", Vector3.new(456, 0.26, 48), CFrame.new(-1150, 2.68, 1182), Color3.fromRGB(210, 186, 145), Enum.Material.Sand, nil, 0.18)
    BuildUtils.CreateMountain(geometry, "ArcherRidgeTerrain", Vector3.new(-1298, 0, 1112), 242, 86, 132, Color3.fromRGB(132, 108, 82), -8)
    BuildUtils.CreateMountain(geometry, "SouthShelfTerrain", Vector3.new(-990, 0, 1244), 214, 64, 110, Color3.fromRGB(137, 112, 84), 18)
    BuildUtils.CreateMountain(geometry, "LastStandShelfTerrain", Vector3.new(-956, 0, 1176), 174, 76, 126, Color3.fromRGB(134, 109, 82), -16)
    createMountainFaceDetails(geometry, "LastStandShelfFaces", Vector3.new(-956, 0, 1182), -16, 174, 76, 126, Color3.fromRGB(134, 109, 82))
    BuildUtils.CreatePart(geometry, "ArcherRidgeLookout", Vector3.new(108, 2.8, 30), CFrame.new(-1298, 48, 1112) * CFrame.Angles(0, math.rad(-8), 0), Color3.fromRGB(125, 103, 80), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(geometry, "ArcherRidgeTrail", Vector3.new(94, 1.4, 16), CFrame.new(-1332, 22, 1156) * CFrame.Angles(0, math.rad(32), 0), Color3.fromRGB(137, 114, 88), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(geometry, "SouthShelfPath", Vector3.new(98, 2.2, 22), CFrame.new(-990, 34, 1244) * CFrame.Angles(0, math.rad(18), 0), Color3.fromRGB(134, 111, 84), Enum.Material.Slate, nil, nil)
    BuildUtils.CreatePart(geometry, "LastStandPath", Vector3.new(114, 1.6, 20), CFrame.new(-958, 24, 1184) * CFrame.Angles(0, math.rad(-16), 0), Color3.fromRGB(132, 109, 84), Enum.Material.Slate, nil, nil)
    BuildUtils.CreateRockCluster(geometry, "PassRocksWest", Vector3.new(-1324, 0, 1238))
    BuildUtils.CreateRockCluster(geometry, "PassRocksEast", Vector3.new(-990, 0, 1124))
    BuildUtils.CreateRockCluster(geometry, "PassRocksCenter", Vector3.new(-1156, 0, 1210))
    BuildUtils.CreateRockCluster(geometry, "FinalStandRocks", Vector3.new(-954, 0, 1182))
    BuildUtils.CreateRockCluster(geometry, "RidgeFootRocks", Vector3.new(-1258, 0, 1088))
    BuildUtils.CreateRockCluster(geometry, "LastStandOuterRocks", Vector3.new(-898, 0, 1210))
    createCampShelter(geometry, "UhudCampWest", Vector3.new(-1376, 0, 1190), Color3.fromRGB(74, 121, 82))
    createCampShelter(geometry, "UhudCampEast", Vector3.new(-932, 0, 1190), Color3.fromRGB(143, 101, 66))
    BuildUtils.CreateBanner(geometry, "UhudBannerWest", Vector3.new(-1338, 0, 1158), Color3.fromRGB(62, 125, 82))
    BuildUtils.CreateBanner(geometry, "UhudBannerEast", Vector3.new(-962, 0, 1200), Color3.fromRGB(147, 104, 72))
    createArenaTorch(geometry, "UhudTorchRidgeA", Vector3.new(-1328, 0, 1104))
    createArenaTorch(geometry, "UhudTorchRidgeB", Vector3.new(-1254, 0, 1138))
    createArenaTorch(geometry, "UhudTorchPassA", Vector3.new(-1180, 0, 1228))
    createArenaTorch(geometry, "UhudTorchPassB", Vector3.new(-1060, 0, 1134))
    createArenaTorch(geometry, "UhudTorchCampMedina", Vector3.new(-1376, 0, 1254))
    createArenaTorch(geometry, "UhudTorchCampMakkah", Vector3.new(-932, 0, 1254))
    createArenaTorch(geometry, "UhudTorchFinalStandA", Vector3.new(-988, 18, 1160))
    createArenaTorch(geometry, "UhudTorchFinalStandB", Vector3.new(-924, 18, 1202))
    createArenaStorySign(geometry, "UhudMountainStory", Vector3.new(-1150, 0, 1048), 180, "Mount Uhud", "Sahih al-Bukhari 4422 preserves the words that Uhud is a mountain that loves us and is loved by us.", Color3.fromRGB(89, 75, 56))
    createArenaStorySign(geometry, "UhudArcherRidgeStory", Vector3.new(-1328, 0, 1078), 150, "The Archer Ridge", "Sunan Abi Dawud 2662 records the order to hold this position and not leave it even if victory seemed clear.", Color3.fromRGB(68, 91, 66))
    createArenaStorySign(geometry, "UhudFlankStory", Vector3.new(-1000, 0, 1290), 320, "The Hard Turn", "Sahih Muslim 1789 remembers the pressure of the late battle when only a few defenders remained in the last stand.", Color3.fromRGB(112, 76, 51))
    createArenaStorySign(geometry, "UhudFinalStandStory", Vector3.new(-946, 24, 1130), 210, "Steadfast Ground", "Qur'an 3:172 and Sahih al-Bukhari 4077 turn the memory of Uhud toward those who answered again after being wounded.", Color3.fromRGB(101, 72, 52))

    addSpawnAnchors(spawns, "medina", scenario.SpawnPositions.medina)
    addSpawnAnchors(spawns, "makkah", scenario.SpawnPositions.makkah)
    addSpawnAnchors(dummies, "medina", {
        Vector3.new(-1322, 10, 1245),
        Vector3.new(-1298, 10, 1112),
        Vector3.new(-1286, 10, 1184),
    })
    addSpawnAnchors(dummies, "makkah", {
        Vector3.new(-958, 22, 1182),
        Vector3.new(-1000, 18, 1110),
        Vector3.new(-1014, 10, 1240),
    })

    createReenactmentSection(arenaFolder, Vector3.new(-1150, 0, 1394), scenario.Id, Color3.fromRGB(71, 127, 86), Color3.fromRGB(149, 102, 61))
    createBriefingSection(arenaFolder, Vector3.new(-790, 0, 1180), scenario.Id, Color3.fromRGB(71, 127, 86), Color3.fromRGB(149, 102, 61))
    arenaFolder:SetAttribute("ScenarioId", scenario.Id)
end

local existingFolder = Workspace:FindFirstChild(ARENA_FOLDER_NAME)

if existingFolder and existingFolder:GetAttribute("GeneratedBy") == "BattleArenaBuilder" then
    existingFolder:Destroy()
end

local arenasFolder = Instance.new("Folder")
arenasFolder.Name = ARENA_FOLDER_NAME
arenasFolder:SetAttribute("GeneratedBy", "BattleArenaBuilder")
arenasFolder.Parent = Workspace

for _, scenario in ipairs(BattleScenarios) do
    if scenario.Id == "badr" then
        buildBadrArena(arenasFolder, scenario)
    elseif scenario.Id == "uhud" then
        buildUhudArena(arenasFolder, scenario)
    end
end
