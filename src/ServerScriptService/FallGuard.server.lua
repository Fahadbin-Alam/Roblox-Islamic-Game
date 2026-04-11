--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TravelRoute = require(Shared.Data.TravelRoute)

local FALL_LIMIT_Y = -20

local function findFirstBasePart(parent: Instance?): BasePart?
    if not parent then
        return nil
    end

    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end

    return nil
end

local function getHubAnchor(): BasePart?
    local hubFolder = Workspace:FindFirstChild(TravelRoute.WorldFolderName)

    if not hubFolder then
        return nil
    end

    local teleportFolder = hubFolder:FindFirstChild("TeleportPoints")

    if not teleportFolder then
        return nil
    end

    local anchor = teleportFolder:FindFirstChild(TravelRoute.StartDestinationId)

    if anchor and anchor:IsA("BasePart") then
        return anchor
    end

    return nil
end

local function getBattleAnchor(character: Model): BasePart?
    local scenarioId = character:GetAttribute("ScenarioId")
    local teamId = character:GetAttribute("BattleTeam")

    if typeof(scenarioId) ~= "string" or typeof(teamId) ~= "string" then
        return nil
    end

    local battlesFolder = Workspace:FindFirstChild("GeneratedBattles")
    local scenarioFolder = battlesFolder and battlesFolder:FindFirstChild(scenarioId)
    local spawns = scenarioFolder and scenarioFolder:FindFirstChild("Spawns")
    local teamFolder = spawns and spawns:FindFirstChild(teamId)

    return findFirstBasePart(teamFolder)
end

local function getStoryAnchor(player: Player): BasePart?
    local storyId = player:GetAttribute("CurrentStoryId")

    if typeof(storyId) ~= "string" then
        return nil
    end

    local storiesFolder = Workspace:FindFirstChild("GeneratedStories")
    local zoneFolder = storiesFolder and storiesFolder:FindFirstChild(storyId)
    local anchors = zoneFolder and zoneFolder:FindFirstChild("Anchors")
    local stepIndex = player:GetAttribute("CurrentStoryStepIndex")
    local preferredName = nil

    if type(stepIndex) == "number" then
        preferredName = string.format("Step_%d", stepIndex)
    end

    local preferredAnchor = preferredName and anchors and anchors:FindFirstChild(preferredName)

    if preferredAnchor and preferredAnchor:IsA("BasePart") then
        return preferredAnchor
    end

    local entryAnchor = anchors and anchors:FindFirstChild("Entry")

    if entryAnchor and entryAnchor:IsA("BasePart") then
        return entryAnchor
    end

    return nil
end

local function moveCharacterToAnchor(character: Model, anchor: BasePart)
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return
    end

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(anchor.CFrame + Vector3.new(0, 5, 0))
end

task.spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character

            if character then
                local root = character:FindFirstChild("HumanoidRootPart")

                if root and root:IsA("BasePart") and root.Position.Y < FALL_LIMIT_Y then
                    local anchor = getBattleAnchor(character) or getStoryAnchor(player) or getHubAnchor()

                    if anchor then
                        moveCharacterToAnchor(character, anchor)
                    end
                end
            end
        end

        task.wait(0.35)
    end
end)
