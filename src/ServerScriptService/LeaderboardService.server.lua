--!strict

-- A "Top Learners" board beside the spawn point, ranking players across every server by
-- total XP. Scores live in an OrderedDataStore and only ever go up, so a stale write from
-- another server can never lower anyone's score.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Modules.Progression)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)

local STORE_NAME = "TopLearnersXP_v1"
local REFRESH_SECONDS = 120
local BOARD_SIZE = 10
-- Beside the Kaaba courtyard spawn, turned to face players as they arrive.
local BOARD_OFFSET = Vector3.new(-30, 0, 4)

local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName)

while worldFolder:GetAttribute("Built") ~= true do
    worldFolder:GetAttributeChangedSignal("Built"):Wait()
end

local store: OrderedDataStore? = nil
local storeOk, storeResult = pcall(function()
    return DataStoreService:GetOrderedDataStore(STORE_NAME)
end)

if storeOk then
    store = storeResult
else
    warn(string.format("[Leaderboard] OrderedDataStore unavailable: %s", tostring(storeResult)))
end

-- Last XP written per player, so unchanged scores are not written again.
local posted: { [number]: number } = {}
-- Players whose profile loaded for real; failed loads never touch the board.
local eligible: { [Player]: boolean } = {}
local nameCache: { [number]: string } = {}

local function postScore(userId: number, xp: number)
    if not store or xp <= 0 or posted[userId] == xp then
        return
    end

    local ok, err = pcall(function()
        (store :: OrderedDataStore):UpdateAsync(string.format("player_%d", userId), function(old: number?)
            local previous: number = old or 0

            -- Returning nil cancels the write when the stored score is already as high.
            return (if xp > previous then xp else nil) :: any
        end)
    end)

    if ok then
        posted[userId] = xp
    else
        warn(string.format("[Leaderboard] Could not post score for %d: %s", userId, tostring(err)))
    end
end

local function nameFor(userId: number): string
    local cached = nameCache[userId]

    if cached then
        return cached
    end

    local player = Players:GetPlayerByUserId(userId)
    local name = player and player.DisplayName

    if not name then
        local ok, result = pcall(function()
            return Players:GetNameFromUserIdAsync(userId)
        end)
        name = if ok and type(result) == "string" then result else "A learner"
    end

    nameCache[userId] = name :: string

    return name :: string
end

-- Board -----------------------------------------------------------------------------------

local spawnDestination = TravelRoute.GetDestinationById("kaaba_courtyard")
local arrival = spawnDestination.TeleportPosition or spawnDestination.Position

local function groundBelow(position: Vector3): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {}

    local result = Workspace:Raycast(position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)

    return if result then result.Position else position
end

local BOARD_WIDTH = 16
local BOARD_HEIGHT = 12

local feet = groundBelow(arrival + BOARD_OFFSET)
local boardCenter = feet + Vector3.new(0, 1.5 + BOARD_HEIGHT / 2, 0)
local facing = Vector3.new(arrival.X, boardCenter.Y, arrival.Z)

local boardModel = Instance.new("Model")
boardModel.Name = "TopLearnersBoard"

local board = Instance.new("Part")
board.Name = "Board"
board.Anchored = true
board.Size = Vector3.new(BOARD_WIDTH, BOARD_HEIGHT, 0.8)
board.CFrame = CFrame.lookAt(boardCenter, facing)
board.Color = Color3.fromRGB(39, 58, 48)
board.Material = Enum.Material.Wood
board.Parent = boardModel

local frame = Instance.new("Part")
frame.Name = "Frame"
frame.Anchored = true
frame.CanCollide = false
frame.Size = Vector3.new(BOARD_WIDTH + 1, BOARD_HEIGHT + 1, 0.6)
frame.CFrame = board.CFrame * CFrame.new(0, 0, 0.3)
frame.Color = Color3.fromRGB(193, 162, 86)
frame.Material = Enum.Material.Metal
frame.Parent = boardModel

for _, side in ipairs({ -1, 1 }) do
    local post = Instance.new("Part")
    post.Name = "Post"
    post.Anchored = true
    post.Size = Vector3.new(0.8, 1.5 + BOARD_HEIGHT, 0.8)
    post.CFrame = board.CFrame * CFrame.new(side * (BOARD_WIDTH / 2 - 1), -(1.5 / 2), 0.6)
    post.Color = Color3.fromRGB(118, 96, 70)
    post.Material = Enum.Material.Wood
    post.Parent = boardModel
end

boardModel.Parent = worldFolder

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Face = Enum.NormalId.Front
surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surfaceGui.PixelsPerStud = 40
surfaceGui.LightInfluence = 0.2
surfaceGui.Parent = board

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(20, 16)
titleLabel.Size = UDim2.new(1, -40, 0, 56)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Top Learners"
titleLabel.TextColor3 = Color3.fromRGB(240, 207, 120)
titleLabel.TextScaled = true
titleLabel.Parent = surfaceGui

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Position = UDim2.fromOffset(20, 72)
subtitleLabel.Size = UDim2.new(1, -40, 0, 26)
subtitleLabel.Font = Enum.Font.GothamMedium
subtitleLabel.Text = "Earn XP from lessons, stories, quizzes, and daily visits."
subtitleLabel.TextColor3 = Color3.fromRGB(226, 214, 180)
subtitleLabel.TextScaled = true
subtitleLabel.Parent = surfaceGui

local rowLabels: { TextLabel } = {}

for index = 1, BOARD_SIZE do
    local row = Instance.new("TextLabel")
    row.BackgroundTransparency = 1
    row.Position = UDim2.fromOffset(40, 108 + (index - 1) * 34)
    row.Size = UDim2.new(1, -80, 0, 30)
    row.Font = if index <= 3 then Enum.Font.GothamBold else Enum.Font.GothamMedium
    row.Text = ""
    row.TextColor3 = Color3.fromRGB(250, 246, 234)
    row.TextScaled = true
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Parent = surfaceGui
    rowLabels[index] = row
end

local function showMessage(message: string)
    for index, row in ipairs(rowLabels) do
        row.Text = if index == 1 then message else ""
    end
end

local function refreshBoard()
    if not store then
        showMessage("The board shows up in the published game.")
        return
    end

    local ok, result = pcall(function()
        return (store :: OrderedDataStore):GetSortedAsync(false, BOARD_SIZE):GetCurrentPage()
    end)

    if not ok then
        warn(string.format("[Leaderboard] Could not read the board: %s", tostring(result)))
        showMessage("The board is resting. It will be back shortly.")
        return
    end

    local entries = result :: { { key: string, value: number } }

    if #entries == 0 then
        showMessage("Be the first learner on the board!")
        return
    end

    for index, row in ipairs(rowLabels) do
        local entry = entries[index]

        if entry then
            local userId = tonumber(string.match(entry.key, "%d+")) or 0
            local level = Progression.GetLevelInfo(entry.value).Level
            row.Text = string.format("%d.  %s   ·   Level %d   ·   %d XP", index, nameFor(userId), level, entry.value)
        else
            row.Text = ""
        end
    end
end

-- Score posting ---------------------------------------------------------------------------

local function postOnlinePlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if PlayerProgress.IsSaveable(player) then
            eligible[player] = true
            local profile = PlayerProgress.Get(player)

            if profile then
                postScore(player.UserId, profile.XP)
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    local xp = player:GetAttribute("XP")

    if eligible[player] and type(xp) == "number" then
        postScore(player.UserId, xp)
    end

    eligible[player] = nil
    posted[player.UserId] = nil
end)

task.spawn(function()
    while true do
        postOnlinePlayers()
        refreshBoard()
        task.wait(REFRESH_SECONDS)
    end
end)
