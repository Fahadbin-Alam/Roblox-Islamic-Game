--!strict

-- Loads and saves player progress, and runs the Islamic Studies hall: the client reads a
-- lesson, submits quiz answers here, and the server grades them before awarding anything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local IslamicStudies = require(Shared.Data.IslamicStudies)
local Progression = require(Shared.Modules.Progression)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local progressFolder = remotesFolder:WaitForChild("Progress")
local learningFolder = remotesFolder:WaitForChild("Learning")
local requestProfile = progressFolder:WaitForChild("RequestProfile") :: RemoteEvent
local openLearningHall = learningFolder:WaitForChild("OpenLearningHall") :: RemoteEvent
local submitQuiz = learningFolder:WaitForChild("SubmitQuiz") :: RemoteEvent
local quizResult = learningFolder:WaitForChild("QuizResult") :: RemoteEvent

local AUTOSAVE_SECONDS = 120
local SUBMIT_COOLDOWN_SECONDS = 1

local lessonById = {}

for _, unit in ipairs(IslamicStudies.Units) do
    for _, lesson in ipairs(unit.Lessons) do
        assert(lessonById[lesson.Id] == nil, string.format("Duplicate Islamic Studies lesson id %s", lesson.Id))
        lessonById[lesson.Id] = lesson
    end
end

local lastSubmitAt: { [Player]: number } = {}
local promptConnections: { [ProximityPrompt]: RBXScriptConnection } = {}

local function gradeQuiz(lesson: IslamicStudies.Lesson, answers: { any })
    local results = {}
    local correctCount = 0

    for index, question in ipairs(lesson.Quiz) do
        local answer = answers[index]
        local correct = type(answer) == "number" and answer == question.CorrectIndex

        if correct then
            correctCount += 1
        end

        table.insert(results, {
            Correct = correct,
            CorrectIndex = question.CorrectIndex,
            Explanation = question.Explanation,
        })
    end

    local required = math.ceil(#lesson.Quiz * IslamicStudies.PassRatio)

    return {
        LessonId = lesson.Id,
        Correct = correctCount,
        Total = #lesson.Quiz,
        Required = required,
        Passed = correctCount >= required,
        Results = results,
        FirstTime = false,
        XPAwarded = 0,
    }
end

submitQuiz.OnServerEvent:Connect(function(player: Player, lessonId: any, answers: any)
    if typeof(lessonId) ~= "string" or typeof(answers) ~= "table" then
        return
    end

    local now = os.clock()

    if now - (lastSubmitAt[player] or 0) < SUBMIT_COOLDOWN_SECONDS then
        return
    end

    lastSubmitAt[player] = now

    local lesson = lessonById[lessonId]

    if not lesson then
        return
    end

    local result = gradeQuiz(lesson, answers)

    if result.Passed then
        local firstTime = PlayerProgress.RecordCompletion(player, Progression.Categories.Lesson, lesson.Id, lesson.DisplayName)
        result.FirstTime = firstTime
        result.XPAwarded = Progression.GetCompletionReward(Progression.Categories.Lesson, firstTime)
    end

    quizResult:FireClient(player, result)
end)

requestProfile.OnServerEvent:Connect(function(player: Player)
    PlayerProgress.SendSnapshot(player)
end)

local function connectPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] or prompt:GetAttribute("PromptAction") ~= "OpenLearningHall" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        if player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true then
            return
        end

        local unitId = prompt:GetAttribute("UnitId")
        openLearningHall:FireClient(player, {
            UnitId = if typeof(unitId) == "string" then unitId else nil,
        })
    end)

    prompt.Destroying:Connect(function()
        local connection = promptConnections[prompt]

        if connection then
            connection:Disconnect()
            promptConnections[prompt] = nil
        end
    end)
end

local function onPlayerAdded(player: Player)
    PlayerProgress.Load(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
    lastSubmitAt[player] = nil
    PlayerProgress.Release(player)
end)

game:BindToClose(PlayerProgress.SaveAll)

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_SECONDS)

        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(PlayerProgress.Save, player)
        end
    end
end)

task.spawn(function()
    local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 30)

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
            task.defer(connectPrompt, descendant)
        end
    end)
end)
