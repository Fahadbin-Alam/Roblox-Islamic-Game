--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattleScenarios = require(Shared.Data.BattleScenarios)
local BuildUtils = require(script.Parent.Modules.BuildUtils)

local ARENA_FOLDER_NAME = "GeneratedBattles"

local function createMountain(parent: Instance, name: string, position: Vector3, baseWidth: number, height: number, depth: number, color: Color3)
    BuildUtils.CreatePart(parent, string.format("%s_Base", name), Vector3.new(baseWidth, height * 0.55, depth), CFrame.new(position + Vector3.new(0, height * 0.22, 0)), color, Enum.Material.Rock, Enum.PartType.Ball, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Peak", name), Vector3.new(baseWidth * 0.52, height * 0.72, depth * 0.5), CFrame.new(position + Vector3.new(0, height * 0.58, 0)), Color3.fromRGB(132, 106, 77), Enum.Material.Rock, Enum.PartType.Ball, nil)
    BuildUtils.CreatePart(parent, string.format("%s_ShoulderWest", name), Vector3.new(baseWidth * 0.44, height * 0.42, depth * 0.48), CFrame.new(position + Vector3.new(baseWidth * -0.24, height * 0.3, 0)), Color3.fromRGB(157, 128, 91), Enum.Material.Rock, Enum.PartType.Ball, nil)
    BuildUtils.CreatePart(parent, string.format("%s_ShoulderEast", name), Vector3.new(baseWidth * 0.44, height * 0.42, depth * 0.48), CFrame.new(position + Vector3.new(baseWidth * 0.24, height * 0.28, 0)), Color3.fromRGB(157, 128, 91), Enum.Material.Rock, Enum.PartType.Ball, nil)
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
    surfaceGui.PixelsPerStud = 20
    surfaceGui.Parent = parent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(26, 18)
    titleLabel.Size = UDim2.new(1, -52, 0, 80)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(55, 45, 31)
    titleLabel.TextScaled = true
    titleLabel.TextWrapped = true
    titleLabel.Parent = surfaceGui

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(30, 112)
    subtitleLabel.Size = UDim2.new(1, -60, 0, 160)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(84, 69, 48)
    subtitleLabel.TextScaled = true
    subtitleLabel.TextWrapped = true
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

local function createSafetyBounds(parent: Instance, center: Vector3, size: Vector3)
    local wallHeight = 90
    local thickness = 10

    BuildUtils.CreatePart(parent, "SafetyFloor", Vector3.new(size.X + 180, 10, size.Z + 180), CFrame.new(center + Vector3.new(0, -8, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "NorthBarrier", Vector3.new(size.X + 180, wallHeight, thickness), CFrame.new(center + Vector3.new(0, 22, size.Z * -0.5 - 90)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "SouthBarrier", Vector3.new(size.X + 180, wallHeight, thickness), CFrame.new(center + Vector3.new(0, 22, size.Z * 0.5 + 90)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "WestBarrier", Vector3.new(thickness, wallHeight, size.Z + 180), CFrame.new(center + Vector3.new(size.X * -0.5 - 90, 22, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "EastBarrier", Vector3.new(thickness, wallHeight, size.Z + 180), CFrame.new(center + Vector3.new(size.X * 0.5 + 90, 22, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
end

local function createActorRig(parent: Instance, name: string, cframe: CFrame, outfitColor: Color3, accentColor: Color3): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local root = BuildUtils.CreatePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), cframe, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    root.CanCollide = false

    BuildUtils.CreatePart(model, "Torso", Vector3.new(3.2, 4.2, 2.1), cframe * CFrame.new(0, 3.2, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "Head", Vector3.new(2, 2, 2), cframe * CFrame.new(0, 6.1, 0), Color3.fromRGB(229, 201, 171), Enum.Material.SmoothPlastic, nil, nil)
    BuildUtils.CreatePart(model, "HeadWrap", Vector3.new(2.3, 1.1, 2.3), cframe * CFrame.new(0, 6.75, 0), accentColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "LeftArm", Vector3.new(1.2, 3.6, 1.2), cframe * CFrame.new(-2.1, 3.1, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "RightArm", Vector3.new(1.2, 3.6, 1.2), cframe * CFrame.new(2.1, 3.1, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "LeftLeg", Vector3.new(1.2, 3.8, 1.2), cframe * CFrame.new(-0.8, 0.7, 0), accentColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "RightLeg", Vector3.new(1.2, 3.8, 1.2), cframe * CFrame.new(0.8, 0.7, 0), accentColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "SwordHandle", Vector3.new(0.28, 1.2, 0.28), cframe * CFrame.new(2.72, 3.6, -0.2), Color3.fromRGB(96, 62, 37), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(model, "SwordBlade", Vector3.new(0.2, 4.2, 0.34), cframe * CFrame.new(2.72, 5.9, -0.2), Color3.fromRGB(214, 214, 210), Enum.Material.Metal, nil, nil)
    BuildUtils.CreatePart(model, "Shield", Vector3.new(0.42, 2.5, 2.2), cframe * CFrame.new(-2.8, 3.3, -0.1), Color3.fromRGB(103, 78, 47), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(model, "ShieldBoss", Vector3.new(0.5, 0.72, 0.72), cframe * CFrame.new(-3.04, 3.3, -0.1), Color3.fromRGB(179, 149, 87), Enum.Material.Metal, Enum.PartType.Ball, nil)

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

    BuildUtils.CreatePart(geometry, "StageFloor", Vector3.new(120, 2, 90), CFrame.new(center + Vector3.new(0, 1.1, 0)), Color3.fromRGB(182, 154, 112), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(geometry, "BackRock", Vector3.new(136, 28, 24), CFrame.new(center + Vector3.new(0, 14, -50)), Color3.fromRGB(147, 119, 83), Enum.Material.Rock, nil, nil)

    local camera1 = BuildUtils.CreateTeleportAnchor(cameras, "Scene1", center + Vector3.new(-48, 22, 42))
    camera1.CFrame = CFrame.new(center + Vector3.new(-48, 22, 42), center + Vector3.new(0, 8, -4))
    local camera2 = BuildUtils.CreateTeleportAnchor(cameras, "Scene2", center + Vector3.new(0, 18, 58))
    camera2.CFrame = CFrame.new(center + Vector3.new(0, 18, 58), center + Vector3.new(0, 8, 0))
    local camera3 = BuildUtils.CreateTeleportAnchor(cameras, "Scene3", center + Vector3.new(52, 26, 36))
    camera3.CFrame = CFrame.new(center + Vector3.new(52, 26, 36), center + Vector3.new(0, 10, -6))
    local camera4 = BuildUtils.CreateTeleportAnchor(cameras, "Scene4", center + Vector3.new(0, 30, -78))
    camera4.CFrame = CFrame.new(center + Vector3.new(0, 30, -78), center + Vector3.new(0, 9, 8))

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

    createActorRig(actors, "MedinaLead", medinaLeadStart.CFrame, medinaColor, Color3.fromRGB(40, 71, 48))
    createActorRig(actors, "MedinaSupport", medinaSupportStart.CFrame, medinaColor, Color3.fromRGB(40, 71, 48))
    createActorRig(actors, "MakkahLead", makkahLeadStart.CFrame, makkahColor, Color3.fromRGB(97, 67, 43))
    createActorRig(actors, "MakkahSupport", makkahSupportStart.CFrame, makkahColor, Color3.fromRGB(97, 67, 43))

    for index = 1, 3 do
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

    BuildUtils.CreatePart(geometry, "BriefingDeck", Vector3.new(150, 3, 118), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(169, 140, 101), Enum.Material.Sandstone, nil, nil)
    local tableTop = BuildUtils.CreatePart(geometry, "AnimatedMapTable", Vector3.new(116, 2, 72), CFrame.new(center + Vector3.new(0, 6, 0)), Color3.fromRGB(225, 203, 160), Enum.Material.WoodPlanks, nil, nil)
    createBattleMapLabel(
        tableTop,
        scenarioId == "badr" and "Badr Tactical Map" or "Uhud Tactical Map",
        scenarioId == "badr" and "Route, valley, wells, and two approaching sides." or "Mountain, pass, archer ridge, and changing momentum."
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

    if scenarioId == "badr" then
        createBriefingPath(markers, "RoutePath", CFrame.new(center + Vector3.new(-8, 8.1, 0)) * CFrame.Angles(0, math.rad(14), 0), Color3.fromRGB(246, 221, 143))
        BuildUtils.CreateVerticalCylinder(markers, "WellMarkerA", 1.4, 4.2, center + Vector3.new(20, 9, -14), Color3.fromRGB(86, 145, 174), Enum.Material.Glass, 0.2)
        BuildUtils.CreateVerticalCylinder(markers, "WellMarkerB", 1.4, 3.6, center + Vector3.new(30, 9, 6), Color3.fromRGB(86, 145, 174), Enum.Material.Glass, 0.2)
        BuildUtils.CreatePart(markers, "ValleyRidge", Vector3.new(96, 1.2, 5), CFrame.new(center + Vector3.new(0, 8.2, -26)), Color3.fromRGB(139, 111, 76), Enum.Material.Rock, nil, nil)
        createBriefingMarker(markers, "MedinaMapMarker", CFrame.new(center + Vector3.new(-42, 10, 16)), medinaColor)
        createBriefingMarker(markers, "MakkahMapMarker", CFrame.new(center + Vector3.new(48, 10, -12)), makkahColor)
        local medinaTarget = createBriefingMarker(markers, "MedinaMapTarget", CFrame.new(center + Vector3.new(-10, 10, 8)), medinaColor)
        medinaTarget.Transparency = 1
        local makkahTarget = createBriefingMarker(markers, "MakkahMapTarget", CFrame.new(center + Vector3.new(12, 10, -4)), makkahColor)
        makkahTarget.Transparency = 1
    else
        BuildUtils.CreatePart(markers, "UhudMountainMap", Vector3.new(92, 8, 13), CFrame.new(center + Vector3.new(0, 11, -24)), Color3.fromRGB(124, 100, 74), Enum.Material.Rock, nil, nil)
        BuildUtils.CreatePart(markers, "ArcherRidgeMap", Vector3.new(34, 4, 8), CFrame.new(center + Vector3.new(-26, 10, -2)), Color3.fromRGB(108, 89, 67), Enum.Material.Rock, nil, nil)
        createBriefingPath(markers, "FlankPath", CFrame.new(center + Vector3.new(14, 8.1, 14)) * CFrame.Angles(0, math.rad(-28), 0), Color3.fromRGB(246, 221, 143))
        createBriefingMarker(markers, "MedinaMapMarker", CFrame.new(center + Vector3.new(-40, 10, 16)), medinaColor)
        createBriefingMarker(markers, "MakkahMapMarker", CFrame.new(center + Vector3.new(50, 10, 12)), makkahColor)
        local medinaTarget = createBriefingMarker(markers, "MedinaMapTarget", CFrame.new(center + Vector3.new(-4, 10, 0)), medinaColor)
        medinaTarget.Transparency = 1
        local makkahTarget = createBriefingMarker(markers, "MakkahMapTarget", CFrame.new(center + Vector3.new(10, 10, 6)), makkahColor)
        makkahTarget.Transparency = 1
    end

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
        Vector3.new(820, 2, 500),
        Color3.fromRGB(198, 169, 127)
    )

    createMountain(geometry, "UhudRidgeWest", Vector3.new(-1428, 0, 996), 300, 188, 178, Color3.fromRGB(147, 118, 84))
    createMountain(geometry, "UhudMainMass", Vector3.new(-1150, 0, 956), 460, 228, 220, Color3.fromRGB(144, 116, 82))
    createMountain(geometry, "UhudRidgeEast", Vector3.new(-892, 0, 1004), 284, 178, 180, Color3.fromRGB(149, 121, 86))
    createMountain(geometry, "UhudRearSlope", Vector3.new(-1152, 0, 860), 360, 124, 120, Color3.fromRGB(145, 118, 86))
    BuildUtils.CreateDune(geometry, "SouthSlope", Vector3.new(-1180, 0, 1398), Vector3.new(360, 54, 122), Color3.fromRGB(194, 164, 122))
    BuildUtils.CreatePart(geometry, "BattlePass", Vector3.new(446, 1, 74), CFrame.new(-1150, 2.05, 1180), Color3.fromRGB(173, 142, 101), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(geometry, "ArcherRise", Vector3.new(168, 36, 84), CFrame.new(-1292, 18, 1112), Color3.fromRGB(136, 111, 81), Enum.Material.Rock, nil, nil)
    BuildUtils.CreatePart(geometry, "SouthShelf", Vector3.new(150, 18, 62), CFrame.new(-1002, 10, 1242), Color3.fromRGB(141, 116, 84), Enum.Material.Rock, nil, nil)
    BuildUtils.CreateRockCluster(geometry, "PassRocksWest", Vector3.new(-1324, 0, 1238))
    BuildUtils.CreateRockCluster(geometry, "PassRocksEast", Vector3.new(-990, 0, 1124))
    BuildUtils.CreateRockCluster(geometry, "PassRocksCenter", Vector3.new(-1156, 0, 1210))
    createCampShelter(geometry, "UhudCampWest", Vector3.new(-1376, 0, 1190), Color3.fromRGB(74, 121, 82))
    createCampShelter(geometry, "UhudCampEast", Vector3.new(-932, 0, 1190), Color3.fromRGB(143, 101, 66))
    BuildUtils.CreateBanner(geometry, "UhudBannerWest", Vector3.new(-1338, 0, 1158), Color3.fromRGB(62, 125, 82))
    BuildUtils.CreateBanner(geometry, "UhudBannerEast", Vector3.new(-962, 0, 1200), Color3.fromRGB(147, 104, 72))

    addSpawnAnchors(spawns, "medina", scenario.SpawnPositions.medina)
    addSpawnAnchors(spawns, "makkah", scenario.SpawnPositions.makkah)
    addSpawnAnchors(dummies, "medina", {
        Vector3.new(-1322, 10, 1245),
        Vector3.new(-1298, 10, 1112),
        Vector3.new(-1286, 10, 1184),
    })
    addSpawnAnchors(dummies, "makkah", {
        Vector3.new(-980, 10, 1246),
        Vector3.new(-1000, 10, 1110),
        Vector3.new(-1014, 10, 1184),
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
