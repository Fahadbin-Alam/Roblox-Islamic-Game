--!strict

-- Layout of the Lobby Parkour Tower, shared by the hub builder (which builds it), the
-- parkour service (which times runs), and the unit tests (which check every jump can be made
-- with Roblox's default character: about 7.2 studs of jump height at 16 walk speed).
--
-- The course spirals up around the tower core. Offsets are from the parkour district centre
-- and give the centre of each platform's top surface.

export type Platform = {
    Offset: Vector3,
    Size: Vector3,
    Yaw: number,
}

export type Checkpoint = {
    Name: string,
    Offset: Vector3,
}

local DECK_TOP = 4
local RISE = 3.5
local RADIUS = 30
local PER_TURN = 12
local COUNT = 24

local platforms: { Platform } = {}

for index = 1, COUNT do
    local angle = math.rad(180 + (index - 1) * (360 / PER_TURN))
    -- Every fourth platform is a narrow beam (5 studs deep); the rest are full steps.
    -- Local X points away from the core, local Z along the spiral.
    local width = if index % 4 == 0 then 5 else 10
    table.insert(platforms, {
        Offset = Vector3.new(math.cos(angle) * RADIUS, DECK_TOP + RISE * index, math.sin(angle) * RADIUS),
        Size = Vector3.new(width, 1.5, 10),
        Yaw = -math.deg(angle),
    })
end

local summitHeight = DECK_TOP + RISE * COUNT + 4
local startOffset = Vector3.new(-RADIUS - 2, DECK_TOP + 1, -14)

local checkpoints: { Checkpoint } = {
    { Name = "Start", Offset = startOffset },
    { Name = "Checkpoint 1", Offset = platforms[8].Offset },
    { Name = "Checkpoint 2", Offset = platforms[16].Offset },
    { Name = "Summit", Offset = Vector3.new(0, summitHeight, 0) },
}

return {
    LobbyTower = {
        Id = "lobby_tower",
        DisplayName = "Lobby Parkour Tower",
        Platforms = platforms,
        StartOffset = startOffset,
        StartSize = Vector3.new(14, 2, 14),
        SummitHeight = summitHeight,
        -- The summit is a round deck so no platform below ever passes under its edge.
        SummitRadius = 23,
        SummitThickness = 4,
        CoreSize = Vector3.new(20, summitHeight - 4, 20),
        Radius = RADIUS,
        Checkpoints = checkpoints,
        -- A real climb takes well over this; anything faster is a teleport or an exploit.
        MinSeconds = 20,
    },
    -- Default Roblox character movement the layout is designed for.
    Movement = {
        JumpHeight = 7.2,
        WalkSpeed = 16,
        -- Longest edge-to-edge gap a default jump clears at equal height, with margin.
        MaxGap = 9,
    },
}
