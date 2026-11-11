--!strict

-- Builds the Sahabi Mystery Rooms and runs them (content in Shared/Data/SahabiMysteries, rules in
-- Shared/Modules/MysteryRules).
--
-- Layout: a lobby with five doorways; behind each a locked room of clues; through the room's
-- locked door an open yard where the companion's episode is played. A room's run is shared by
-- everyone inside it, so friends solve it together. When the episode is finished, everyone in
-- the room or yard is credited and the room resets for the next group.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SahabiMysteries = require(Shared.Data.SahabiMysteries)
local MysteryRules = require(Shared.Modules.MysteryRules)
local TravelRoute = require(Shared.Data.TravelRoute)
local BuildUtils = require(script.Parent.Modules.BuildUtils)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local Analytics = require(script.Parent.Modules.Analytics)

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mystery")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local CENTER = (TravelRoute.GetDestinationById("mystery_wing") :: any).Position - Vector3.new(0, 4, 0)
local FLOOR_TOP = 4
local ROOM = SahabiMysteries.RoomSize
local SPACING = 260
local YARD_Z = 150
local WALL_HEIGHT = 24
local RESET_AFTER_DONE = 40
local RESET_WHEN_EMPTY = 150

local STONE = Color3.fromRGB(196, 176, 146)
local DARK = Color3.fromRGB(88, 70, 52)
local GOLD = Color3.fromRGB(226, 186, 96)

type Room = {
    Mystery: SahabiMysteries.Mystery,
    Center: Vector3,
    YardCenter: Vector3,
    Run: MysteryRules.Run,
    Door: BasePart,
    StationParts: { BasePart },
    EmptySince: number?,
    DoneAt: number?,
}

local rooms: { [string]: Room } = {}
local roomOrder: { Room } = {}
local playerRoom: { [Player]: string } = {}

local existing = Workspace:FindFirstChild("MysteryWing")

if existing then
    existing:Destroy()
end

local wing = BuildUtils.CreateFolder(Workspace, "MysteryWing")

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, transparency: number?): Part
    return BuildUtils.CreatePart(parent, name, size, CFrame.new(position), color, material or Enum.Material.Sandstone, nil, transparency)
end

local function label(parent: BasePart, text: string, offsetY: number)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(200, 40)
    billboard.StudsOffset = Vector3.new(0, offsetY, 0)
    billboard.MaxDistance = 60
    billboard.Parent = parent

    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(250, 240, 210)
    textLabel.TextStrokeTransparency = 0.4
    textLabel.TextScaled = true
    textLabel.Parent = billboard
end

-- Four walls; the south wall has an open doorway and the north wall a locked door.
local function buildRoom(folder: Folder, center: Vector3, mystery: SahabiMysteries.Mystery): BasePart
    local half = ROOM / 2
    local y = FLOOR_TOP + WALL_HEIGHT / 2
    part(folder, "Floor", Vector3.new(ROOM, 1, ROOM), center + Vector3.new(0, FLOOR_TOP - 0.5, 0), Color3.fromRGB(150, 118, 84), Enum.Material.WoodPlanks)
    part(folder, "Rug", Vector3.new(40, 0.2, 30), center + Vector3.new(0, FLOOR_TOP + 0.1, 0), Color3.fromRGB(128, 52, 46), Enum.Material.Fabric).CanCollide = false
    part(folder, "WallWest", Vector3.new(2, WALL_HEIGHT, ROOM), center + Vector3.new(-half, y, 0), STONE)
    part(folder, "WallEast", Vector3.new(2, WALL_HEIGHT, ROOM), center + Vector3.new(half, y, 0), STONE)

    for _, side in ipairs({ -1, 1 }) do
        local z = side * half
        local gap = if side == -1 then 12 else 10
        local segment = (ROOM - gap) / 2
        part(folder, "WallLeft" .. side, Vector3.new(segment, WALL_HEIGHT, 2), center + Vector3.new(-gap / 2 - segment / 2, y, z), STONE)
        part(folder, "WallRight" .. side, Vector3.new(segment, WALL_HEIGHT, 2), center + Vector3.new(gap / 2 + segment / 2, y, z), STONE)
        part(folder, "Lintel" .. side, Vector3.new(gap, WALL_HEIGHT - 14, 2), center + Vector3.new(0, FLOOR_TOP + 14 + (WALL_HEIGHT - 14) / 2, z), STONE)
    end

    local roof = part(folder, "Roof", Vector3.new(ROOM + 2, 1, ROOM + 2), center + Vector3.new(0, FLOOR_TOP + WALL_HEIGHT + 0.5, 0), DARK, Enum.Material.WoodPlanks)
    roof.CastShadow = false

    for index, offset in ipairs({ Vector3.new(-30, 0, -30), Vector3.new(30, 0, -30), Vector3.new(-30, 0, 30), Vector3.new(30, 0, 30) }) do
        local lamp = part(folder, "Lamp" .. index, Vector3.new(1.4, 2, 1.4), center + offset + Vector3.new(0, FLOOR_TOP + WALL_HEIGHT - 3, 0), GOLD, Enum.Material.Neon)
        lamp.CanCollide = false
        BuildUtils.AddPointLight(lamp, Color3.fromRGB(255, 214, 150), 1.6, 46)
    end

    local door = part(folder, "LockDoor", Vector3.new(10, 14, 1.4), center + Vector3.new(0, FLOOR_TOP + 7, half), Color3.fromRGB(104, 72, 44), Enum.Material.WoodPlanks)
    local plate = part(folder, "LockPlate", Vector3.new(2.2, 2.2, 0.4), center + Vector3.new(0, FLOOR_TOP + 6, half - 1), GOLD, Enum.Material.Metal)
    plate.CanCollide = false
    BuildUtils.AttachPrompt(plate, "Open the lock", mystery.Title, { PromptAction = "MysteryLock", MysteryId = mystery.Id })

    local hintStand = part(folder, "HintStand", Vector3.new(4, 4, 2), center + Vector3.new(-half + 8, FLOOR_TOP + 2, half - 10), Color3.fromRGB(70, 96, 82), Enum.Material.Wood)
    BuildUtils.AttachPrompt(hintStand, "Ask for a hint", "Hint scroll", { PromptAction = "MysteryHint", MysteryId = mystery.Id })
    label(hintStand, "Hints", 4)

    for _, clue in ipairs(mystery.Clues) do
        local at = center + clue.Offset + Vector3.new(0, FLOOR_TOP, 0)
        part(folder, "Pedestal_" .. clue.Id, Vector3.new(4, 3, 4), at + Vector3.new(0, 1.5, 0), Color3.fromRGB(122, 98, 72), Enum.Material.Wood)
        local object = part(folder, "Clue_" .. clue.Id, Vector3.new(2, 1.4, 2), at + Vector3.new(0, 3.7, 0), GOLD, Enum.Material.SmoothPlastic)
        object.CanCollide = false
        BuildUtils.AttachPrompt(object, "Examine", clue.Object, { PromptAction = "MysteryClue", MysteryId = mystery.Id, ClueId = clue.Id })
    end

    -- A corridor from the locked door to the yard.
    part(folder, "Corridor", Vector3.new(12, 1, YARD_Z - ROOM), center + Vector3.new(0, FLOOR_TOP - 0.5, half + (YARD_Z - ROOM) / 2), Color3.fromRGB(176, 150, 112))

    return door
end

local function buildYard(folder: Folder, yardCenter: Vector3, mystery: SahabiMysteries.Mystery): { BasePart }
    local half = ROOM / 2
    part(folder, "YardGround", Vector3.new(ROOM, 1, ROOM), yardCenter + Vector3.new(0, FLOOR_TOP - 0.5, 0), Color3.fromRGB(206, 182, 140), Enum.Material.Sand)

    for _, wall in ipairs({
        { Vector3.new(ROOM, 6, 2), Vector3.new(0, 0, half) },
        { Vector3.new(2, 6, ROOM), Vector3.new(-half, 0, 0) },
        { Vector3.new(2, 6, ROOM), Vector3.new(half, 0, 0) },
        { Vector3.new((ROOM - 12) / 2, 6, 2), Vector3.new(-(ROOM + 12) / 4, 0, -half) },
        { Vector3.new((ROOM - 12) / 2, 6, 2), Vector3.new((ROOM + 12) / 4, 0, -half) },
    }) do
        part(folder, "YardWall", wall[1], yardCenter + wall[2] + Vector3.new(0, FLOOR_TOP + 3, 0), Color3.fromRGB(170, 132, 94))
    end

    local stations = {}
    local previous: Vector3? = nil

    for index, station in ipairs(mystery.Episode.Stations) do
        local top = yardCenter + station.Offset + Vector3.new(0, FLOOR_TOP, 0)

        if station.Offset.Y > 0 then
            part(folder, "Landing" .. index, Vector3.new(10, 1, 10), top - Vector3.new(0, 0.5, 0), Color3.fromRGB(150, 120, 88), Enum.Material.WoodPlanks)
            BuildUtils.CreateVerticalCylinder(folder, "Post" .. index, station.Offset.Y, 1, top - Vector3.new(0, station.Offset.Y / 2 + 1, 0), Color3.fromRGB(110, 84, 58), Enum.Material.Wood, nil)
        end

        -- Ordered episodes with height get a ramp from each station to the next.
        if previous and mystery.Episode.Ordered and (top.Y > (previous :: Vector3).Y) then
            local from = previous :: Vector3
            local length = (top - from).Magnitude
            local ramp = BuildUtils.CreatePart(folder, "Ramp" .. index, Vector3.new(6, 1, length), CFrame.lookAt((from + top) / 2 - Vector3.new(0, 0.5, 0), top - Vector3.new(0, 0.5, 0)), Color3.fromRGB(140, 110, 80), Enum.Material.WoodPlanks, nil, nil)
            ramp.Name = "Ramp" .. index
        end

        local marker = part(folder, "Station" .. index, Vector3.new(4, 4, 4), top + Vector3.new(0, 2, 0), Color3.fromRGB(120, 150, 110), Enum.Material.SmoothPlastic, 0.2)
        marker.CanCollide = false
        BuildUtils.AttachPrompt(marker, "Do this step", station.Name, { PromptAction = "MysteryStation", MysteryId = mystery.Id, StationIndex = index })
        label(marker, string.format("%d. %s", index, station.Name), 4)
        table.insert(stations, marker)
        previous = top
    end

    return stations
end

local function buildWing()
    part(wing, "SafetyPlate", Vector3.new(1500, 10, 700), CENTER + Vector3.new(0, -8, 40), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, 1)
    part(wing, "Ground", Vector3.new(1400, 4, 600), CENTER + Vector3.new(0, 2, 40), Color3.fromRGB(196, 172, 132), Enum.Material.Sand)
    part(wing, "LobbyFloor", Vector3.new(1260, 0.4, 70), CENTER + Vector3.new(0, FLOOR_TOP + 0.2, -ROOM / 2 - 45), Color3.fromRGB(226, 214, 192), Enum.Material.Marble)

    local entrance = BuildUtils.CreateBoardSign(wing, "WingSign", CENTER + Vector3.new(0, FLOOR_TOP, -ROOM / 2 - 100), "Sahabi Mystery Rooms", "Each room hides a companion's story. Find the clues, open the lock, then play their episode. Clues are game props; the stories are documented.", Color3.fromRGB(96, 76, 112), nil)
    entrance.Orientation = Vector3.new(0, 0, 0)

    for index, mystery in ipairs(SahabiMysteries.Mysteries) do
        local center = CENTER + Vector3.new((index - (#SahabiMysteries.Mysteries + 1) / 2) * SPACING, 0, 0)
        local yardCenter = center + Vector3.new(0, 0, YARD_Z)
        local folder = BuildUtils.CreateFolder(wing, mystery.Id)
        local door = buildRoom(folder, center, mystery)
        local stations = buildYard(folder, yardCenter, mystery)

        local board = BuildUtils.CreateBoardSign(folder, "RoomSign", center + Vector3.new(0, FLOOR_TOP, -ROOM / 2 - 14), mystery.Title, mystery.Tagline, Color3.fromRGB(96, 76, 112), nil)
        board.Orientation = Vector3.new(0, 0, 0)

        local room: Room = {
            Mystery = mystery,
            Center = center,
            YardCenter = yardCenter,
            Run = MysteryRules.NewRun(mystery.Id) :: MysteryRules.Run,
            Door = door,
            StationParts = stations,
            EmptySince = nil,
            DoneAt = nil,
        }
        rooms[mystery.Id] = room
        table.insert(roomOrder, room)
    end
end

buildWing()

local function inside(position: Vector3, center: Vector3): boolean
    local offset = position - center
    local half = ROOM / 2 + 2

    return math.abs(offset.X) <= half and math.abs(offset.Z) <= half and offset.Y > -10 and offset.Y < 60
end

local function locate(player: Player): string?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return nil
    end

    for _, room in ipairs(roomOrder) do
        if inside(root.Position, room.Center) or inside(root.Position, room.YardCenter) then
            return room.Mystery.Id
        end
    end

    return nil
end

local function occupants(room: Room): { Player }
    local list = {}

    for player, id in pairs(playerRoom) do
        if id == room.Mystery.Id and player.Parent then
            table.insert(list, player)
        end
    end

    return list
end

local function payload(room: Room?, extra: { [string]: any }?)
    if not room then
        return { InRoom = false }
    end

    local run = room.Run
    local found = {}

    for _, clue in ipairs(room.Mystery.Clues) do
        if run.Found[clue.Id] then
            table.insert(found, clue.Id)
        end
    end

    local stationsDone = {}

    for index in pairs(run.StationsDone) do
        table.insert(stationsDone, index)
    end

    local data: { [string]: any } = {
        InRoom = true,
        MysteryId = room.Mystery.Id,
        Found = found,
        HintsUsed = run.HintsUsed,
        WrongTries = run.WrongTries,
        LockOpen = run.LockOpen,
        StationsDone = stationsDone,
        NextStation = MysteryRules.NextStation(run),
        Done = run.Done,
        Stars = MysteryRules.Stars(run),
        Players = #occupants(room),
    }

    if extra then
        for key, value in pairs(extra) do
            data[key] = value
        end
    end

    return data
end

local function broadcast(room: Room, extra: { [string]: any }?)
    local data = payload(room, extra)

    for _, player in ipairs(occupants(room)) do
        stateEvent:FireClient(player, data)
    end
end

local function setDoor(room: Room, open: boolean)
    room.Door.CanCollide = not open
    room.Door.Transparency = if open then 0.85 else 0
end

local function setStation(room: Room, index: number, done: boolean)
    local marker = room.StationParts[index]

    if marker then
        marker.Color = if done then Color3.fromRGB(226, 186, 96) else Color3.fromRGB(120, 150, 110)
        marker.Material = if done then Enum.Material.Neon else Enum.Material.SmoothPlastic
    end
end

local function resetRoom(room: Room)
    room.Run = MysteryRules.NewRun(room.Mystery.Id) :: MysteryRules.Run
    room.DoneAt = nil
    setDoor(room, false)

    for index in ipairs(room.StationParts) do
        setStation(room, index, false)
    end

    broadcast(room, { Reset = true })
end

local function finish(room: Room)
    room.DoneAt = os.clock()
    local stars = MysteryRules.Stars(room.Run)

    for _, player in ipairs(occupants(room)) do
        local firstTime = PlayerProgress.RecordCompletion(player, "mystery", room.Mystery.Id, room.Mystery.Title)
        PlayerProgress.SetStatMax(player, "MysteryStars_" .. room.Mystery.Id, stars)

        if firstTime then
            PlayerProgress.IncrementStat(player, "MysteriesSolved", 1)
        end

        Analytics.Custom(player, "MysterySolved", stars)
    end

    broadcast(room, { Finished = true, FinishText = room.Mystery.Episode.FinishText })
end

local actions = {}

function actions.State(player: Player)
    local id = playerRoom[player]
    stateEvent:FireClient(player, payload(if id then rooms[id] else nil))
end

function actions.Lock(player: Player, answers: any)
    local id = playerRoom[player]
    local room = id and rooms[id]

    if not room or type(answers) ~= "table" then
        return
    end

    local clean = {}

    for index = 1, #room.Mystery.Lock do
        clean[index] = if type(answers[index]) == "number" then answers[index] else 0
    end

    if MysteryRules.TryLock(room.Run, clean) then
        setDoor(room, true)
        broadcast(room, { Toast = "The lock clicks open. Go through the door to play the episode." })
    else
        broadcast(room, { Toast = "The lock does not move. Check the clues again." })
    end
end

function actions.Hint(player: Player)
    local id = playerRoom[player]
    local room = id and rooms[id]

    if room then
        local hint = MysteryRules.TakeHint(room.Run)
        broadcast(room, { Toast = hint or "There are no more hints. You have everything you need." })
    end
end

function actions.Teleport(player: Player, mysteryId: any)
    local room = type(mysteryId) == "string" and rooms[mysteryId]
    local character = player.Character

    if room and character and player:GetAttribute("InBattle") ~= true and player:GetAttribute("InStory") ~= true then
        character:PivotTo(CFrame.new(room.Center + Vector3.new(0, FLOOR_TOP + 4, -ROOM / 2 - 22)))
    end
end

request.OnServerEvent:Connect(function(player: Player, action: any, argument: any)
    local handler = type(action) == "string" and actions[action]

    if handler then
        handler(player, argument)
    end
end)

local function onPrompt(prompt: ProximityPrompt, player: Player)
    local id = prompt:GetAttribute("MysteryId")
    local room = type(id) == "string" and rooms[id]

    if not room then
        return
    end

    -- Presence updates every half second; a prompt use counts as being in the room.
    playerRoom[player] = room.Mystery.Id
    local action = prompt:GetAttribute("PromptAction")

    if action == "MysteryClue" then
        local clue = MysteryRules.FindClue(room.Run, prompt:GetAttribute("ClueId"))
        local clueId = prompt:GetAttribute("ClueId")

        for _, entry in ipairs(room.Mystery.Clues) do
            if entry.Id == clueId then
                -- Show the clue to whoever examined it, and tell the room it was found.
                stateEvent:FireClient(player, payload(room, { ShowClue = entry.Id }))
            end
        end

        if clue then
            broadcast(room, { Toast = string.format("%s found: %s", player.DisplayName, clue.Object) })
        end
    elseif action == "MysteryHint" then
        actions.Hint(player)
    elseif action == "MysteryLock" then
        stateEvent:FireClient(player, payload(room, { OpenLock = true }))
    elseif action == "MysteryStation" then
        local index = prompt:GetAttribute("StationIndex")

        if type(index) ~= "number" then
            return
        end

        local counted, finished = MysteryRules.VisitStation(room.Run, index)

        if counted then
            setStation(room, index, true)
            broadcast(room, { Toast = string.format("%s: %s done", player.DisplayName, room.Mystery.Episode.Stations[index].Name) })
        elseif not room.Run.LockOpen then
            stateEvent:FireClient(player, payload(room, { Toast = "Open the lock in the room first." }))
        elseif room.Mystery.Episode.Ordered and not room.Run.Done then
            stateEvent:FireClient(player, payload(room, { Toast = "Do the steps in order." }))
        end

        if finished and room.DoneAt == nil then
            finish(room)
        end
    end
end

for _, descendant in ipairs(wing:GetDescendants()) do
    if descendant:IsA("ProximityPrompt") then
        local prompt = descendant
        prompt.Triggered:Connect(function(player: Player)
            onPrompt(prompt, player)
        end)
    end
end

-- Presence, resets, and room entry/exit.
task.spawn(function()
    while true do
        task.wait(0.5)

        for _, player in ipairs(Players:GetPlayers()) do
            local now = locate(player)
            local before = playerRoom[player]

            if now ~= before then
                playerRoom[player] = now
                stateEvent:FireClient(player, payload(if now then rooms[now] else nil))

                if before and rooms[before] then
                    broadcast(rooms[before])
                end

                if now and rooms[now] then
                    broadcast(rooms[now])
                end
            end
        end

        local clock = os.clock()

        for _, room in ipairs(roomOrder) do
            local present = #occupants(room)

            if room.DoneAt and clock - room.DoneAt > RESET_AFTER_DONE then
                resetRoom(room)
            elseif present == 0 then
                room.EmptySince = room.EmptySince or clock

                local started = room.Run.LockOpen or MysteryRules.FoundCount(room.Run) > 0 or room.Run.HintsUsed > 0

                if started and clock - (room.EmptySince :: number) > RESET_WHEN_EMPTY then
                    resetRoom(room)
                end
            else
                room.EmptySince = nil
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player: Player)
    local id = playerRoom[player]
    playerRoom[player] = nil

    if id and rooms[id] then
        broadcast(rooms[id])
    end
end)

wing:SetAttribute("Built", true)
