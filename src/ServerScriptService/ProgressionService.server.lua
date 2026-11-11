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
local submitOrder = learningFolder:WaitForChild("SubmitOrder") :: RemoteEvent
local orderResult = learningFolder:WaitForChild("OrderResult") :: RemoteEvent
local submitDailyAnswer = learningFolder:WaitForChild("SubmitDailyAnswer") :: RemoteEvent
local dailyResult = learningFolder:WaitForChild("DailyResult") :: RemoteEvent

local AUTOSAVE_SECONDS = 120
local SUBMIT_COOLDOWN_SECONDS = 1
-- Several HUD scripts ask for the profile when they start, so allow a small burst.
local PROFILE_REQUESTS_PER_WINDOW = 6
local PROFILE_REQUEST_WINDOW_SECONDS = 10

local lessonById = {}

for _, unit in ipairs(IslamicStudies.Units) do
    for _, lesson in ipairs(unit.Lessons) do
        assert(lessonById[lesson.Id] == nil, string.format("Duplicate Islamic Studies lesson id %s", lesson.Id))
        lessonById[lesson.Id] = lesson
    end
end

local lastSubmitAt: { [Player]: number } = {}
local profileRequests: { [Player]: { WindowStart: number, Count: number } } = {}
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
        local firstTime, awarded = PlayerProgress.RecordCompletion(player, Progression.Categories.Lesson, lesson.Id, lesson.DisplayName)
        result.FirstTime = firstTime
        result.XPAwarded = awarded
    end

    quizResult:FireClient(player, result)
end)

-- Grades a lesson's order puzzle. The client sends step numbers (indexes into
-- lesson.Order.Steps) in the order the player placed them.
submitOrder.OnServerEvent:Connect(function(player: Player, lessonId: any, placed: any)
    if typeof(lessonId) ~= "string" or typeof(placed) ~= "table" then
        return
    end

    local now = os.clock()

    if now - (lastSubmitAt[player] or 0) < SUBMIT_COOLDOWN_SECONDS then
        return
    end

    lastSubmitAt[player] = now

    local lesson = lessonById[lessonId]
    local puzzle = lesson and lesson.Order

    if not lesson or not puzzle then
        return
    end

    local inPlace = {}
    local correctCount = 0

    for index = 1, #puzzle.Steps do
        local right = placed[index] == index
        inPlace[index] = right

        if right then
            correctCount += 1
        end
    end

    local solved = correctCount == #puzzle.Steps
    local xpAwarded = 0

    if solved then
        local _firstTime, awarded = PlayerProgress.RecordCompletion(player, Progression.Categories.Order, lesson.Id, string.format("%s puzzle", lesson.DisplayName))
        xpAwarded = awarded
    end

    orderResult:FireClient(player, {
        LessonId = lesson.Id,
        Solved = solved,
        InPlace = inPlace,
        CorrectCount = correctCount,
        Total = #puzzle.Steps,
        XPAwarded = xpAwarded,
    })
end)

submitDailyAnswer.OnServerEvent:Connect(function(player: Player, answerIndex: any)
    if typeof(answerIndex) ~= "number" then
        return
    end

    local result = PlayerProgress.AnswerDailyQuestion(player, answerIndex)

    if result then
        dailyResult:FireClient(player, result)
    end
end)

requestProfile.OnServerEvent:Connect(function(player: Player)
    -- Snapshots are pushed on every change anyway; this only serves a HUD that just opened,
    -- so a client spamming the remote cannot make the server rebuild snapshots in a loop.
    local now = os.clock()
    local window = profileRequests[player]

    if not window or now - window.WindowStart >= PROFILE_REQUEST_WINDOW_SECONDS then
        window = { WindowStart = now, Count = 0 }
        profileRequests[player] = window
    end

    local current = window :: { WindowStart: number, Count: number }

    if current.Count >= PROFILE_REQUESTS_PER_WINDOW then
        return
    end

    current.Count += 1
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
    profileRequests[player] = nil
    PlayerProgress.Release(player)
end)

game:BindToClose(PlayerProgress.SaveAll)

task.spawn(function()
    while true do
        task.wait(AUTOSAVE_SECONDS)

        for _, player in ipairs(Players:GetPlayers()) do
            -- Also catches the new UTC day for players who stay in one server past midnight.
            PlayerProgress.RecordDailyVisit(player)
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
