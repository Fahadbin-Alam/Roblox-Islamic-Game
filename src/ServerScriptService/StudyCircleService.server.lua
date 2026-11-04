--!strict

-- Study circle (halaqah): a cooperative quiz for everyone standing at the Islamic Studies
-- podium. Players answer together and pass or fail as a group, so helping friends learn is
-- what earns the reward. One circle runs at a time.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local IslamicStudies = require(Shared.Data.IslamicStudies)
local Progression = require(Shared.Modules.Progression)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)

local learningFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Learning")
local circleUpdate = learningFolder:WaitForChild("StudyCircleUpdate") :: RemoteEvent
local circleAnswer = learningFolder:WaitForChild("StudyCircleAnswer") :: RemoteEvent

local GATHER_SECONDS = 10
local QUESTION_SECONDS = 20
local REVEAL_SECONDS = 6
local JOIN_RADIUS = 45
local MIN_PLAYERS_FOR_BADGE = 2

type Circle = {
    Lesson: IslamicStudies.Lesson,
    Participants: { Player },
    QuestionIndex: number,
    AcceptingAnswers: boolean,
    Answers: { [Player]: number },
    TotalCorrect: number,
}

local activeCircle: Circle? = nil
local gathering = false
local promptConnections: { [ProximityPrompt]: RBXScriptConnection } = {}

local allLessons = {}

for _, unit in ipairs(IslamicStudies.Units) do
    for _, lesson in ipairs(unit.Lessons) do
        table.insert(allLessons, lesson)
    end
end

local function isBusy(player: Player): boolean
    return player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true
end

local function playersNear(position: Vector3): { Player }
    local nearby = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root and root:IsA("BasePart") and not isBusy(player) and (root.Position - position).Magnitude <= JOIN_RADIUS then
            table.insert(nearby, player)
        end
    end

    return nearby
end

local function broadcast(circle: Circle, payload: { [string]: any })
    payload.Participants = #circle.Participants

    for _, player in ipairs(circle.Participants) do
        circleUpdate:FireClient(player, payload)
    end
end

local function stillPresent(circle: Circle)
    local present = {}

    for _, player in ipairs(circle.Participants) do
        if player.Parent and not isBusy(player) then
            table.insert(present, player)
        end
    end

    circle.Participants = present
end

local function everyoneAnswered(circle: Circle): boolean
    for _, player in ipairs(circle.Participants) do
        if circle.Answers[player] == nil then
            return false
        end
    end

    return true
end

local function runCircle(circle: Circle)
    local lesson = circle.Lesson

    for index, question in ipairs(lesson.Quiz) do
        stillPresent(circle)

        if #circle.Participants == 0 then
            return
        end

        circle.QuestionIndex = index
        circle.Answers = {}
        circle.AcceptingAnswers = true

        broadcast(circle, {
            Phase = "question",
            LessonName = lesson.DisplayName,
            Index = index,
            Total = #lesson.Quiz,
            Prompt = question.Prompt,
            Options = question.Options,
            TimeLimit = QUESTION_SECONDS,
        })

        local startedAt = os.clock()

        while os.clock() - startedAt < QUESTION_SECONDS and not everyoneAnswered(circle) do
            task.wait(0.25)
            stillPresent(circle)
        end

        circle.AcceptingAnswers = false

        local correctCount = 0
        local answeredCount = 0

        for _, answer in pairs(circle.Answers) do
            answeredCount += 1

            if answer == question.CorrectIndex then
                correctCount += 1
            end
        end

        circle.TotalCorrect += correctCount

        broadcast(circle, {
            Phase = "reveal",
            LessonName = lesson.DisplayName,
            Index = index,
            Total = #lesson.Quiz,
            Prompt = question.Prompt,
            Options = question.Options,
            CorrectIndex = question.CorrectIndex,
            Explanation = question.Explanation,
            CorrectCount = correctCount,
            AnsweredCount = answeredCount,
        })

        task.wait(REVEAL_SECONDS)
    end

    stillPresent(circle)

    local possible = #lesson.Quiz * math.max(1, #circle.Participants)
    local ratio = circle.TotalCorrect / possible
    local passed = ratio >= IslamicStudies.PassRatio
    local isGroup = #circle.Participants >= MIN_PLAYERS_FOR_BADGE

    broadcast(circle, {
        Phase = "finished",
        LessonName = lesson.DisplayName,
        Passed = passed,
        Percent = math.floor(ratio * 100 + 0.5),
        IsGroup = isGroup,
        XP = if passed then Progression.Rewards.StudyCircle else 0,
    })

    if passed then
        for _, player in ipairs(circle.Participants) do
            PlayerProgress.AddXP(player, Progression.Rewards.StudyCircle, string.format("Study circle: %s", lesson.DisplayName))

            if isGroup then
                PlayerProgress.IncrementStat(player, "StudyCircles", 1)
            end
        end
    end
end

local function startCircle(starter: Player, anchor: BasePart)
    if activeCircle or gathering or isBusy(starter) then
        if activeCircle or gathering then
            circleUpdate:FireClient(starter, {
                Phase = "notice",
                Text = "A study circle is already running. Join the next one!",
            })
        end

        return
    end

    gathering = true

    for _, player in ipairs(playersNear(anchor.Position)) do
        circleUpdate:FireClient(player, {
            Phase = "gathering",
            Seconds = GATHER_SECONDS,
            Text = string.format("%s is starting a study circle. Stay near the Islamic Studies podium to join!", starter.DisplayName),
        })
    end

    task.wait(GATHER_SECONDS)

    local participants = playersNear(anchor.Position)
    gathering = false

    if #participants == 0 then
        return
    end

    local circle: Circle = {
        Lesson = allLessons[math.random(1, #allLessons)],
        Participants = participants,
        QuestionIndex = 0,
        AcceptingAnswers = false,
        Answers = {},
        TotalCorrect = 0,
    }

    activeCircle = circle
    local ok, err = pcall(function()
        runCircle(circle)
    end)

    if not ok then
        warn(string.format("[StudyCircleService] Circle failed: %s", tostring(err)))
    end

    activeCircle = nil
end

circleAnswer.OnServerEvent:Connect(function(player: Player, questionIndex: any, answerIndex: any)
    local circle = activeCircle

    if not circle or not circle.AcceptingAnswers or questionIndex ~= circle.QuestionIndex then
        return
    end

    if typeof(answerIndex) ~= "number" or circle.Answers[player] ~= nil or not table.find(circle.Participants, player) then
        return
    end

    local question = circle.Lesson.Quiz[circle.QuestionIndex]

    if answerIndex < 1 or answerIndex > #question.Options then
        return
    end

    circle.Answers[player] = answerIndex
end)

local function connectPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] or prompt:GetAttribute("PromptAction") ~= "StartStudyCircle" then
        return
    end

    local anchor = prompt.Parent

    if not anchor or not anchor:IsA("BasePart") then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        task.spawn(startCircle, player, anchor)
    end)

    prompt.Destroying:Connect(function()
        local connection = promptConnections[prompt]

        if connection then
            connection:Disconnect()
            promptConnections[prompt] = nil
        end
    end)
end

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
