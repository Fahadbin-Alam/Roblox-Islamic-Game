--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TravelRoute = require(Shared.Data.TravelRoute)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local hubFolder = remotesFolder:WaitForChild("Hub")
local requestTeleport = hubFolder:WaitForChild("RequestTeleport") :: RemoteEvent

local cooldowns = {}
local promptConnections = {}

local function getTeleportAnchor(destinationId: string): BasePart?
    local worldFolder = Workspace:FindFirstChild(TravelRoute.WorldFolderName)

    if not worldFolder then
        return nil
    end

    local teleportFolder = worldFolder:FindFirstChild("TeleportPoints")

    if not teleportFolder then
        return nil
    end

    local anchor = teleportFolder:FindFirstChild(destinationId)

    if anchor and anchor:IsA("BasePart") then
        return anchor
    end

    return nil
end

local function teleportPlayerToDestination(player: Player, destinationId: string)
    if typeof(destinationId) ~= "string" then
        return
    end

    if not TravelRoute.GetDestinationById(destinationId) then
        return
    end

    local now = os.clock()
    local lastTeleport = cooldowns[player]

    if lastTeleport and now - lastTeleport < 1 then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local anchor = getTeleportAnchor(destinationId)

    if not anchor then
        return
    end

    cooldowns[player] = now
    character:PivotTo(anchor.CFrame * CFrame.new(0, 4, 0))
end

requestTeleport.OnServerEvent:Connect(function(player: Player, destinationId: string)
    teleportPlayerToDestination(player, destinationId)
end)

local function connectTeleportPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    if prompt:GetAttribute("PromptAction") ~= "Teleport" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        local destinationId = prompt:GetAttribute("DestinationId")

        if typeof(destinationId) == "string" then
            teleportPlayerToDestination(player, destinationId)
        end
    end)
end

task.spawn(function()
    local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 10)

    if not worldFolder then
        return
    end

    for _, descendant in ipairs(worldFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            connectTeleportPrompt(descendant)
        end
    end

    worldFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            connectTeleportPrompt(descendant)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    cooldowns[player] = nil
end)
