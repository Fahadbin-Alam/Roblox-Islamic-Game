--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MannersLessons = require(Shared.Data.MannersLessons)
local TravelRoute = require(Shared.Data.TravelRoute)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local mannersFolder = remotesFolder:WaitForChild("Manners")
local requestLesson = mannersFolder:WaitForChild("RequestLesson") :: RemoteEvent
local showMannersLesson = mannersFolder:WaitForChild("ShowMannersLesson") :: RemoteEvent

local lessonById = {}
local promptConnections = {}

for _, lesson in ipairs(MannersLessons) do
    lessonById[lesson.Id] = lesson
end

local function showLesson(player: Player, lessonId: string)
    local lesson = lessonById[lessonId]

    if not lesson then
        return
    end

    showMannersLesson:FireClient(player, {
        Id = lesson.Id,
        DisplayName = lesson.DisplayName,
        Subtitle = lesson.Subtitle,
        Lines = lesson.Lines,
        AccentColor = lesson.AccentColor,
        LinkedStoryId = lesson.LinkedStoryId,
    })
end

local function connectPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    if prompt:GetAttribute("PromptAction") ~= "OpenManners" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        local lessonId = prompt:GetAttribute("LessonId")

        if typeof(lessonId) == "string" then
            showLesson(player, lessonId)
        end
    end)
end

requestLesson.OnServerEvent:Connect(function(player: Player, lessonId: string)
    if typeof(lessonId) == "string" then
        showLesson(player, lessonId)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    for prompt, connection in pairs(promptConnections) do
        if not prompt.Parent then
            connection:Disconnect()
            promptConnections[prompt] = nil
        end
    end
end)

task.spawn(function()
    local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 10)

    if not worldFolder then
        return
    end

    for _, descendant in ipairs(worldFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            connectPrompt(descendant)
        end
    end

    worldFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            connectPrompt(descendant)
        end
    end)
end)
