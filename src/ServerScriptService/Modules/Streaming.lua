--!strict

-- Helpers for Workspace.StreamingEnabled. With streaming on, a client only holds the parts
-- near its character, so before a long teleport the server asks Roblox to send the parts
-- around the destination first. Otherwise the player could arrive before the floor has
-- loaded. Does nothing when streaming is off.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Streaming = {}

function Streaming.PrepareArrival(who: Player | Model, position: Vector3)
    if not (Workspace :: any).StreamingEnabled then
        return
    end

    local player = if typeof(who) == "Instance" and who:IsA("Player") then who else Players:GetPlayerFromCharacter(who :: Model)

    if player then
        -- Yields until the area is sent, or fails quietly (for example if the player left).
        pcall(function()
            (player :: Player):RequestStreamAroundAsync(position, 5)
        end)
    end
end

-- Keeps a model loaded on every client wherever the player is, for things a client script
-- drives itself (such as the Tawaf ambience figures).
function Streaming.KeepLoaded(model: Model)
    pcall(function()
        (model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    end)
end

return Streaming
