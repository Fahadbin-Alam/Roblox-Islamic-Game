--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CompanionStories = require(Shared.Data.CompanionStories)
local BuildUtils = require(script.Parent.Modules.BuildUtils)

local STORY_FOLDER_NAME = "GeneratedStories"
local BASE_STONE = Color3.fromRGB(223, 214, 196)
local COURT_WHITE = Color3.fromRGB(239, 234, 224)
local SAND_ACCENT = Color3.fromRGB(204, 182, 137)
local GARDEN_GREEN = Color3.fromRGB(93, 133, 87)

local STORY_CENTERS = {
    abu_bakr_as_siddiq = Vector3.new(840, 4, -720),
    bilal_ibn_rabah = Vector3.new(840, 4, -320),
    musab_ibn_umayr = Vector3.new(840, 4, 80),
    nusaybah_bint_kaab = Vector3.new(840, 4, 500),
    umar_ibn_al_khattab = Vector3.new(840, 4, 900),
}

local function createNpc(parent: Instance, name: string, cframe: CFrame, outfitColor: Color3, accentColor: Color3): Model
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local root = BuildUtils.CreatePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), cframe, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    root.CanCollide = false

    BuildUtils.CreatePart(model, "Torso", Vector3.new(3, 4, 2), cframe * CFrame.new(0, 3, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "Head", Vector3.new(2, 2, 2), cframe * CFrame.new(0, 6, 0), Color3.fromRGB(229, 201, 171), Enum.Material.SmoothPlastic, nil, nil)
    BuildUtils.CreatePart(model, "HeadWrap", Vector3.new(2.3, 1.1, 2.3), cframe * CFrame.new(0, 6.65, 0), accentColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "LeftArm", Vector3.new(1.2, 3.5, 1.2), cframe * CFrame.new(-2.05, 3.1, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "RightArm", Vector3.new(1.2, 3.5, 1.2), cframe * CFrame.new(2.05, 3.1, 0), outfitColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "LeftLeg", Vector3.new(1.2, 3.6, 1.2), cframe * CFrame.new(-0.8, 0.6, 0), accentColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "RightLeg", Vector3.new(1.2, 3.6, 1.2), cframe * CFrame.new(0.8, 0.6, 0), accentColor, Enum.Material.Fabric, nil, nil)

    model.PrimaryPart = root

    return model
end

local function createZoneBounds(parent: Instance, center: Vector3, size: Vector3)
    local thickness = 10
    local wallHeight = 64

    BuildUtils.CreatePart(parent, "SafetyPlate", Vector3.new(size.X + 100, 10, size.Z + 100), CFrame.new(center + Vector3.new(0, -8, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "NorthBarrier", Vector3.new(size.X + 100, wallHeight, thickness), CFrame.new(center + Vector3.new(0, 22, size.Z * -0.5 - 50)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "SouthBarrier", Vector3.new(size.X + 100, wallHeight, thickness), CFrame.new(center + Vector3.new(0, 22, size.Z * 0.5 + 50)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "WestBarrier", Vector3.new(thickness, wallHeight, size.Z + 100), CFrame.new(center + Vector3.new(size.X * -0.5 - 50, 22, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
    BuildUtils.CreatePart(parent, "EastBarrier", Vector3.new(thickness, wallHeight, size.Z + 100), CFrame.new(center + Vector3.new(size.X * 0.5 + 50, 22, 0)), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, 1)
end

local function createStepStation(zone: Folder, story, step, stepIndex: number, position: Vector3)
    local stations = zone:FindFirstChild("Stations") or BuildUtils.CreateFolder(zone, "Stations")
    local prompts = zone:FindFirstChild("Prompts") or BuildUtils.CreateFolder(zone, "Prompts")
    local anchors = zone:FindFirstChild("Anchors") or BuildUtils.CreateFolder(zone, "Anchors")

    local stationFolder = BuildUtils.CreateFolder(stations, step.Id)
    BuildUtils.CreatePart(stationFolder, "Court", Vector3.new(72, 1, 72), CFrame.new(position + Vector3.new(0, 4.55, 0)), COURT_WHITE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(stationFolder, "Trim", Vector3.new(84, 2, 84), CFrame.new(position + Vector3.new(0, 1, 0)), BASE_STONE, Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreateWallSign(stationFolder, "StorySign", position + Vector3.new(0, 0, -26), Vector3.new(52, 10, 2), step.Title, step.LocationName, story.AccentColor, nil)

    local npc = createNpc(stationFolder, step.NpcName, CFrame.new(position + Vector3.new(0, 0, 12)) * CFrame.Angles(0, math.rad(180), 0), story.AccentColor, Color3.fromRGB(62, 58, 48))

    local promptBase = BuildUtils.CreatePart(prompts, string.format("%sPromptBase", step.Id), Vector3.new(8, 1, 8), CFrame.new(position + Vector3.new(0, 5, 4)), Color3.fromRGB(201, 182, 140), Enum.Material.Sandstone, nil, nil)
    BuildUtils.AttachPrompt(promptBase, step.PromptText, step.NpcName, {
        PromptAction = "StoryStep",
        StoryId = story.Id,
        StepIndex = stepIndex,
    })

    local anchor = BuildUtils.CreateTeleportAnchor(anchors, string.format("Step_%d", stepIndex), position + Vector3.new(0, 0, 24))
    anchor:SetAttribute("StoryId", story.Id)

    if story.Id == "abu_bakr_as_siddiq" then
        BuildUtils.CreateLantern(stationFolder, string.format("%sLantern", step.Id), position + Vector3.new(-22, 0, 16), Color3.fromRGB(207, 168, 86))
        BuildUtils.CreateBanner(stationFolder, string.format("%sBanner", step.Id), position + Vector3.new(22, 0, 16), Color3.fromRGB(124, 108, 67))
        BuildUtils.CreatePart(stationFolder, string.format("%sTrustArchLeft", step.Id), Vector3.new(5, 20, 5), CFrame.new(position + Vector3.new(-18, 10, -4)), BASE_STONE, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(stationFolder, string.format("%sTrustArchRight", step.Id), Vector3.new(5, 20, 5), CFrame.new(position + Vector3.new(18, 10, -4)), BASE_STONE, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(stationFolder, string.format("%sTrustArchTop", step.Id), Vector3.new(41, 5, 6), CFrame.new(position + Vector3.new(0, 20, -4)), BASE_STONE, Enum.Material.Marble, nil, nil)
    elseif story.Id == "bilal_ibn_rabah" then
        BuildUtils.CreateLantern(stationFolder, string.format("%sLantern", step.Id), position + Vector3.new(-22, 0, 16), Color3.fromRGB(182, 152, 87))
        BuildUtils.CreateHouse(stationFolder, string.format("%sHouse", step.Id), position + Vector3.new(22, 0, -6), Vector3.new(34, 28, 28), SAND_ACCENT)
    elseif story.Id == "musab_ibn_umayr" then
        BuildUtils.CreatePlanter(stationFolder, string.format("%sPlanter", step.Id), position + Vector3.new(-18, 0, 20), Vector3.new(26, 3, 18))
        BuildUtils.CreatePalmTree(stationFolder, string.format("%sPalm", step.Id), position + Vector3.new(-18, 0, 20))
        BuildUtils.CreateBanner(stationFolder, string.format("%sBanner", step.Id), position + Vector3.new(24, 0, 16), Color3.fromRGB(118, 96, 55))
    elseif story.Id == "nusaybah_bint_kaab" then
        BuildUtils.CreateLantern(stationFolder, string.format("%sLantern", step.Id), position + Vector3.new(22, 0, 20), Color3.fromRGB(170, 146, 79))
        BuildUtils.CreatePart(stationFolder, string.format("%sCover", step.Id), Vector3.new(18, 10, 14), CFrame.new(position + Vector3.new(-24, 5, 0)), Color3.fromRGB(199, 187, 168), Enum.Material.Fabric, nil, nil)
        BuildUtils.CreateBanner(stationFolder, string.format("%sBanner", step.Id), position + Vector3.new(-18, 0, 18), GARDEN_GREEN)
    elseif story.Id == "umar_ibn_al_khattab" then
        BuildUtils.CreatePart(stationFolder, string.format("%sArchLeft", step.Id), Vector3.new(6, 24, 6), CFrame.new(position + Vector3.new(-18, 12, -4)), BASE_STONE, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(stationFolder, string.format("%sArchRight", step.Id), Vector3.new(6, 24, 6), CFrame.new(position + Vector3.new(18, 12, -4)), BASE_STONE, Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(stationFolder, string.format("%sArchTop", step.Id), Vector3.new(42, 6, 7), CFrame.new(position + Vector3.new(0, 23, -4)), BASE_STONE, Enum.Material.Marble, nil, nil)
    end

    return npc
end

local function buildStoryZone(parent: Instance, story, center: Vector3)
    local zone = BuildUtils.CreateFolder(parent, story.Id)
    zone:SetAttribute("StoryId", story.Id)

    local zoneSize = Vector3.new(340, 2, 260)
    createZoneBounds(zone, center, zoneSize)

    BuildUtils.CreatePart(zone, "BaseFloor", Vector3.new(320, 4, 240), CFrame.new(center + Vector3.new(0, 2, 0)), BASE_STONE, Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(zone, "InnerCourt", Vector3.new(236, 1, 168), CFrame.new(center + Vector3.new(0, 4.55, 0)), COURT_WHITE, Enum.Material.Marble, nil, nil)
    BuildUtils.CreatePart(zone, "EntryPath", Vector3.new(32, 1, 100), CFrame.new(center + Vector3.new(0, 4.65, 74)), Color3.fromRGB(217, 206, 182), Enum.Material.Marble, nil, nil)
    BuildUtils.CreateWallSign(zone, "TitleBoard", center + Vector3.new(0, 0, 104), Vector3.new(78, 12, 2.5), story.DisplayName, story.Summary, story.AccentColor, nil)

    local anchors = BuildUtils.CreateFolder(zone, "Anchors")
    local entryAnchor = BuildUtils.CreateTeleportAnchor(anchors, "Entry", center + Vector3.new(0, 0, 88))
    entryAnchor:SetAttribute("StoryId", story.Id)

    local exitBoard = BuildUtils.CreateBoardSign(
        zone,
        "ReturnBoard",
        center + Vector3.new(-116, 0, 78),
        "Return To Hub",
        "Leave this sahabi playthrough and go back to the main courtyard.",
        Color3.fromRGB(72, 94, 71),
        {
            ActionText = "Return",
            ObjectText = "Hub Exit",
            Attributes = {
                PromptAction = "ReturnToHub",
                StoryId = story.Id,
            },
        }
    )
    exitBoard.Orientation = Vector3.new(0, 180, 0)

    local stepPositions = {
        center + Vector3.new(-86, 0, 18),
        center + Vector3.new(86, 0, 18),
        center + Vector3.new(-86, 0, -84),
        center + Vector3.new(86, 0, -84),
    }

    for index, step in ipairs(story.ScenarioSteps) do
        createStepStation(zone, story, step, index, stepPositions[index])
    end

    if story.Id == "abu_bakr_as_siddiq" then
        BuildUtils.CreatePart(zone, "SiddiqLeadershipHall", Vector3.new(104, 30, 52), CFrame.new(center + Vector3.new(0, 15, -126)), Color3.fromRGB(218, 211, 194), Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(zone, "SiddiqLeadershipRoof", Vector3.new(116, 5, 64), CFrame.new(center + Vector3.new(0, 32, -126)), Color3.fromRGB(124, 108, 67), Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(zone, "SiddiqCaveMarker", Vector3.new(46, 18, 24), CFrame.new(center + Vector3.new(-124, 9, -118)), Color3.fromRGB(112, 101, 82), Enum.Material.Rock, nil, nil)
        BuildUtils.CreateLantern(zone, "SiddiqLanternA", center + Vector3.new(-136, 0, 70), Color3.fromRGB(207, 168, 86))
        BuildUtils.CreateLantern(zone, "SiddiqLanternB", center + Vector3.new(136, 0, 70), Color3.fromRGB(207, 168, 86))
    elseif story.Id == "bilal_ibn_rabah" then
        BuildUtils.CreateHouse(zone, "BilalHome", center + Vector3.new(0, 0, -120), Vector3.new(48, 26, 34), SAND_ACCENT)
        BuildUtils.CreateLantern(zone, "BilalLanternA", center + Vector3.new(-136, 0, 70), Color3.fromRGB(174, 147, 80))
        BuildUtils.CreateLantern(zone, "BilalLanternB", center + Vector3.new(136, 0, 70), Color3.fromRGB(174, 147, 80))
    elseif story.Id == "musab_ibn_umayr" then
        BuildUtils.CreateHouse(zone, "MusabHouseA", center + Vector3.new(-122, 0, -130), Vector3.new(42, 24, 30), Color3.fromRGB(197, 183, 150))
        BuildUtils.CreateHouse(zone, "MusabHouseB", center + Vector3.new(126, 0, -128), Vector3.new(42, 24, 30), Color3.fromRGB(197, 183, 150))
        BuildUtils.CreatePlanter(zone, "MusabGarden", center + Vector3.new(0, 0, -124), Vector3.new(58, 3, 24))
    elseif story.Id == "nusaybah_bint_kaab" then
        BuildUtils.CreatePalmTree(zone, "NusaybahPalmA", center + Vector3.new(-128, 0, -122))
        BuildUtils.CreatePalmTree(zone, "NusaybahPalmB", center + Vector3.new(126, 0, -120))
        BuildUtils.CreatePart(zone, "NusaybahLine", Vector3.new(180, 10, 18), CFrame.new(center + Vector3.new(0, 5, -132)), Color3.fromRGB(160, 142, 110), Enum.Material.Sandstone, nil, nil)
    elseif story.Id == "umar_ibn_al_khattab" then
        BuildUtils.CreatePart(zone, "JusticeHall", Vector3.new(96, 28, 48), CFrame.new(center + Vector3.new(0, 14, -126)), Color3.fromRGB(216, 212, 204), Enum.Material.Marble, nil, nil)
        BuildUtils.CreatePart(zone, "JusticeHallRoof", Vector3.new(108, 4, 60), CFrame.new(center + Vector3.new(0, 30, -126)), Color3.fromRGB(197, 190, 176), Enum.Material.Marble, nil, nil)
    end
end

local existingFolder = Workspace:FindFirstChild(STORY_FOLDER_NAME)

if existingFolder and existingFolder:GetAttribute("GeneratedBy") == "StoryWorldBuilder" then
    existingFolder:Destroy()
end

local storyFolder = Instance.new("Folder")
storyFolder.Name = STORY_FOLDER_NAME
storyFolder:SetAttribute("GeneratedBy", "StoryWorldBuilder")
storyFolder.Parent = Workspace

for _, story in ipairs(CompanionStories) do
    local center = STORY_CENTERS[story.Id]

    if center then
        buildStoryZone(storyFolder, story, center)
    end
end
