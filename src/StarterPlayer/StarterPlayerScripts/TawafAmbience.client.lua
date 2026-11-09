--!strict

-- Walks the pilgrim figures built by MasjidAlHaram around the Kaaba, anticlockwise as in
-- tawaf. Movement is local to each client (the server only places them), so it costs no
-- network traffic, and it pauses when the player is far from the mataf.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FOLDER_NAME = "TawafPilgrims"
local ACTIVE_DISTANCE = 700
local UPDATE_INTERVAL = 1 / 30

type Pilgrim = {
    Parts: { BasePart },
    Offsets: { CFrame },
    Radius: number,
    StartAngle: number,
    AngularSpeed: number,
    Phase: number,
}

local player = Players.LocalPlayer

local function numberAttribute(instance: Instance, name: string, fallback: number): number
    local value = instance:GetAttribute(name)
    return if type(value) == "number" then value else fallback
end

local function findFolder(): Instance?
    local hub = Workspace:WaitForChild("GeneratedHub", 60)
    if not hub then
        return nil
    end

    for _ = 1, 120 do
        local folder = hub:FindFirstChild(FOLDER_NAME, true)
        if folder then
            return folder
        end
        task.wait(0.5)
    end

    return nil
end

local folder = findFolder()
if not folder then
    return
end

local centerValue = folder:GetAttribute("Center")
local center: Vector3 = if typeof(centerValue) == "Vector3" then centerValue else Vector3.zero
local floorY = numberAttribute(folder, "FloorY", center.Y)

local pilgrims: { Pilgrim } = {}
local allParts: { BasePart } = {}

for _, figure in ipairs(folder:GetChildren()) do
    local entry: Pilgrim = {
        Parts = {},
        Offsets = {},
        Radius = numberAttribute(figure, "Radius", 100),
        StartAngle = numberAttribute(figure, "StartAngle", 0),
        AngularSpeed = numberAttribute(figure, "AngularSpeed", 0.04),
        Phase = numberAttribute(figure, "Phase", 0),
    }

    for _, piece in ipairs(figure:GetChildren()) do
        local offset = piece:GetAttribute("Offset")
        if piece:IsA("BasePart") and typeof(offset) == "CFrame" then
            table.insert(entry.Parts, piece)
            table.insert(entry.Offsets, offset)
        end
    end

    if #entry.Parts > 0 then
        table.insert(pilgrims, entry)
    end
end

local function nearMataf(): boolean
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return (root.Position - center).Magnitude < ACTIVE_DISTANCE
    end
    return false
end

local elapsed = 0
local startClock = os.clock()

RunService.Heartbeat:Connect(function(dt: number)
    elapsed += dt
    if elapsed < UPDATE_INTERVAL then
        return
    end
    elapsed = 0

    if not nearMataf() then
        return
    end

    local t = os.clock() - startClock
    local targets: { CFrame } = {}
    local parts = allParts
    table.clear(parts)

    for _, pilgrim in ipairs(pilgrims) do
        -- Decreasing angle with +Z north and +X west reads as anticlockwise from above.
        local angle = pilgrim.StartAngle - pilgrim.AngularSpeed * t
        local stride = t * pilgrim.AngularSpeed * pilgrim.Radius * 1.6 + pilgrim.Phase
        local bob = math.abs(math.sin(stride)) * 0.18
        local position = center + Vector3.new(math.cos(angle) * pilgrim.Radius, 0, math.sin(angle) * pilgrim.Radius)
        position = Vector3.new(position.X, floorY + bob, position.Z)
        local heading = Vector3.new(math.sin(angle), 0, -math.cos(angle))
        local root = CFrame.lookAt(position, position + heading)
        local swing = math.sin(stride) * 0.35

        for index, piece in ipairs(pilgrim.Parts) do
            local offset = pilgrim.Offsets[index]
            if piece.Name == "ArmLeft" then
                offset = offset * CFrame.new(0, 0.9, 0) * CFrame.Angles(swing, 0, 0) * CFrame.new(0, -0.9, 0)
            elseif piece.Name == "ArmRight" then
                offset = offset * CFrame.new(0, 0.9, 0) * CFrame.Angles(-swing, 0, 0) * CFrame.new(0, -0.9, 0)
            end
            table.insert(parts, piece)
            table.insert(targets, root * offset)
        end
    end

    Workspace:BulkMoveTo(parts, targets, Enum.BulkMoveMode.FireCFrameChanged)
end)
