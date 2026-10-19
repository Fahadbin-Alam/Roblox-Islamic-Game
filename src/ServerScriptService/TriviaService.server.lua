--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TravelRoute = require(Shared.Data.TravelRoute)
local TriviaQuestions = require(Shared.Data.TriviaQuestions)
local Progression = require(Shared.Modules.Progression)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local triviaFolder = remotesFolder:WaitForChild("Trivia")
local requestStartTrivia = triviaFolder:WaitForChild("RequestStartTrivia") :: RemoteEvent
local submitTriviaAnswer = triviaFolder:WaitForChild("SubmitTriviaAnswer") :: RemoteEvent
local showTriviaQuestion = triviaFolder:WaitForChild("ShowTriviaQuestion") :: RemoteEvent
local showTriviaResult = triviaFolder:WaitForChild("ShowTriviaResult") :: RemoteEvent
local updateTriviaScores = triviaFolder:WaitForChild("UpdateTriviaScores") :: RemoteEvent
local clearTrivia = triviaFolder:WaitForChild("ClearTrivia") :: RemoteEvent

local QUESTION_SECONDS = 16
local RESULT_SECONDS = 4
local MAX_ROUNDS = math.min(12, #TriviaQuestions.Questions)

type ScoreState = {
    PlayerName: string,
    Score: number,
    Correct: number,
    Streak: number,
}

local active = false
local acceptingAnswers = false
local currentRound = 0
local currentQuestion: any = nil
local answeredPlayers: { [number]: boolean } = {}
local scores: { [number]: ScoreState } = {}
local promptConnections: { [ProximityPrompt]: RBXScriptConnection } = {}

local function ensureScore(player: Player): ScoreState
    local score = scores[player.UserId]

    if score then
        score.PlayerName = player.DisplayName
        return score
    end

    score = {
        PlayerName = player.DisplayName,
        Score = 0,
        Correct = 0,
        Streak = 0,
    }
    scores[player.UserId] = score

    return score
end

local function getScoreboard()
    local rows = {}

    for userId, score in pairs(scores) do
        table.insert(rows, {
            UserId = userId,
            PlayerName = score.PlayerName,
            Score = score.Score,
            Correct = score.Correct,
            Streak = score.Streak,
        })
    end

    table.sort(rows, function(left, right)
        if left.Score == right.Score then
            return left.PlayerName < right.PlayerName
        end

        return left.Score > right.Score
    end)

    return rows
end

local function broadcastScores()
    updateTriviaScores:FireAllClients({
        Active = active,
        Round = currentRound,
        TotalRounds = MAX_ROUNDS,
        Scoreboard = getScoreboard(),
    })
end

local function allActivePlayersAnswered(): boolean
    for _, player in ipairs(Players:GetPlayers()) do
        if not answeredPlayers[player.UserId] then
            return false
        end
    end

    return true
end

local function resetScores()
    scores = {}

    for _, player in ipairs(Players:GetPlayers()) do
        ensureScore(player)
    end
end

local function getRoundQuestion(roundIndex: number)
    return TriviaQuestions.Questions[roundIndex]
end

local function sendCurrentQuestionTo(player: Player)
    if not active or not currentQuestion then
        return
    end

    showTriviaQuestion:FireClient(player, {
        DisplayName = TriviaQuestions.DisplayName,
        Round = currentRound,
        TotalRounds = MAX_ROUNDS,
        Difficulty = currentQuestion.Difficulty,
        Prompt = currentQuestion.Prompt,
        Options = currentQuestion.Options,
        TimeLimit = QUESTION_SECONDS,
    })
end

local function finishCurrentRound()
    if not currentQuestion then
        return
    end

    acceptingAnswers = false

    showTriviaResult:FireAllClients({
        Round = currentRound,
        TotalRounds = MAX_ROUNDS,
        CorrectIndex = currentQuestion.CorrectIndex,
        CorrectText = currentQuestion.Options[currentQuestion.CorrectIndex],
        Explanation = currentQuestion.Explanation,
        Scoreboard = getScoreboard(),
    })
end

local function runTriviaSession()
    if active then
        return
    end

    active = true
    currentRound = 0
    resetScores()
    broadcastScores()

    for roundIndex = 1, MAX_ROUNDS do
        currentRound = roundIndex
        currentQuestion = getRoundQuestion(roundIndex)
        answeredPlayers = {}
        acceptingAnswers = true

        for _, player in ipairs(Players:GetPlayers()) do
            ensureScore(player)
        end

        showTriviaQuestion:FireAllClients({
            DisplayName = TriviaQuestions.DisplayName,
            Round = currentRound,
            TotalRounds = MAX_ROUNDS,
            Difficulty = currentQuestion.Difficulty,
            Prompt = currentQuestion.Prompt,
            Options = currentQuestion.Options,
            TimeLimit = QUESTION_SECONDS,
        })
        broadcastScores()

        local roundStartedAt = os.clock()

        while acceptingAnswers and os.clock() - roundStartedAt < QUESTION_SECONDS do
            if allActivePlayersAnswered() then
                break
            end

            task.wait(0.25)
        end

        finishCurrentRound()
        broadcastScores()
        task.wait(RESULT_SECONDS)
    end

    active = false
    acceptingAnswers = false
    currentRound = 0
    currentQuestion = nil
    clearTrivia:FireAllClients({
        Final = true,
        Scoreboard = getScoreboard(),
        Message = "Trivia finished. Highest score wins this round.",
    })
    broadcastScores()
end

local function startTriviaFor(player: Player?)
    if player and (player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true) then
        return
    end

    if player then
        ensureScore(player)
    end

    if active then
        if player then
            sendCurrentQuestionTo(player)
            updateTriviaScores:FireClient(player, {
                Active = true,
                Round = currentRound,
                TotalRounds = MAX_ROUNDS,
                Scoreboard = getScoreboard(),
            })
        end

        return
    end

    task.spawn(runTriviaSession)
end

submitTriviaAnswer.OnServerEvent:Connect(function(player: Player, answerIndex)
    if not active or not acceptingAnswers or not currentQuestion then
        return
    end

    if typeof(answerIndex) ~= "number" then
        return
    end

    answerIndex = math.floor(answerIndex)

    if answerIndex < 1 or answerIndex > #currentQuestion.Options then
        return
    end

    if answeredPlayers[player.UserId] then
        return
    end

    answeredPlayers[player.UserId] = true

    local score = ensureScore(player)
    local correct = answerIndex == currentQuestion.CorrectIndex

    if correct then
        score.Streak += 1
        score.Correct += 1
        score.Score += currentQuestion.Points + math.min(20, score.Streak * 3)
        PlayerProgress.IncrementStat(player, "TriviaCorrect", 1)
        PlayerProgress.AddXP(player, Progression.Rewards.TriviaCorrect)
    else
        score.Streak = 0
    end

    showTriviaResult:FireClient(player, {
        Personal = true,
        Round = currentRound,
        TotalRounds = MAX_ROUNDS,
        Correct = correct,
        SelectedIndex = answerIndex,
        CorrectIndex = currentQuestion.CorrectIndex,
        CorrectText = currentQuestion.Options[currentQuestion.CorrectIndex],
        Explanation = currentQuestion.Explanation,
        Scoreboard = getScoreboard(),
    })
    broadcastScores()
end)

requestStartTrivia.OnServerEvent:Connect(function(player: Player)
    startTriviaFor(player)
end)

local function connectTriviaPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    if prompt:GetAttribute("PromptAction") ~= "StartTrivia" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        startTriviaFor(player)
    end)
end

task.spawn(function()
    local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 10)

    if not worldFolder then
        return
    end

    for _, descendant in ipairs(worldFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            connectTriviaPrompt(descendant)
        end
    end

    worldFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            connectTriviaPrompt(descendant)
        end
    end)
end)

Players.PlayerAdded:Connect(function(player)
    if active then
        ensureScore(player)
        task.defer(function()
            sendCurrentQuestionTo(player)
            broadcastScores()
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    answeredPlayers[player.UserId] = nil
end)
