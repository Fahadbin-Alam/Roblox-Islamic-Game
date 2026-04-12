--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local triviaFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Trivia")
local submitTriviaAnswer = triviaFolder:WaitForChild("SubmitTriviaAnswer") :: RemoteEvent
local showTriviaQuestion = triviaFolder:WaitForChild("ShowTriviaQuestion") :: RemoteEvent
local showTriviaResult = triviaFolder:WaitForChild("ShowTriviaResult") :: RemoteEvent
local updateTriviaScores = triviaFolder:WaitForChild("UpdateTriviaScores") :: RemoteEvent
local clearTrivia = triviaFolder:WaitForChild("ClearTrivia") :: RemoteEvent

local selectedThisRound = false
local questionEndsAt = 0
local answerButtons: { TextButton } = {}
local scoreRows: { TextLabel } = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TriviaHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 28
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 20)
panel.Size = UDim2.fromOffset(660, 408)
panel.BackgroundColor3 = Color3.fromRGB(245, 239, 224)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(75, 67, 51)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(18, 14)
titleLabel.Size = UDim2.new(1, -36, 0, 30)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Islamic Trivia Challenge"
titleLabel.TextColor3 = Color3.fromRGB(38, 35, 28)
titleLabel.TextSize = 23
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = panel

local metaLabel = Instance.new("TextLabel")
metaLabel.BackgroundTransparency = 1
metaLabel.Position = UDim2.fromOffset(18, 48)
metaLabel.Size = UDim2.new(1, -36, 0, 24)
metaLabel.Font = Enum.Font.GothamMedium
metaLabel.Text = "Round 1"
metaLabel.TextColor3 = Color3.fromRGB(93, 80, 54)
metaLabel.TextSize = 14
metaLabel.TextXAlignment = Enum.TextXAlignment.Left
metaLabel.Parent = panel

local timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(1, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Position = UDim2.new(1, -18, 0, 48)
timerLabel.Size = UDim2.fromOffset(120, 24)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(87, 99, 67)
timerLabel.TextSize = 14
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Parent = panel

local questionLabel = Instance.new("TextLabel")
questionLabel.BackgroundTransparency = 1
questionLabel.Position = UDim2.fromOffset(18, 82)
questionLabel.Size = UDim2.new(1, -36, 0, 74)
questionLabel.Font = Enum.Font.GothamBold
questionLabel.Text = ""
questionLabel.TextColor3 = Color3.fromRGB(43, 39, 31)
questionLabel.TextSize = 20
questionLabel.TextWrapped = true
questionLabel.TextXAlignment = Enum.TextXAlignment.Left
questionLabel.TextYAlignment = Enum.TextYAlignment.Top
questionLabel.Parent = panel

local answersFrame = Instance.new("Frame")
answersFrame.BackgroundTransparency = 1
answersFrame.Position = UDim2.fromOffset(18, 166)
answersFrame.Size = UDim2.new(0.62, -22, 0, 208)
answersFrame.Parent = panel

local answerLayout = Instance.new("UIListLayout")
answerLayout.Padding = UDim.new(0, 8)
answerLayout.Parent = answersFrame

local scoreboardFrame = Instance.new("Frame")
scoreboardFrame.Position = UDim2.new(0.62, 6, 0, 166)
scoreboardFrame.Size = UDim2.new(0.38, -24, 0, 208)
scoreboardFrame.BackgroundColor3 = Color3.fromRGB(232, 225, 209)
scoreboardFrame.Parent = panel

local scoreboardCorner = Instance.new("UICorner")
scoreboardCorner.CornerRadius = UDim.new(0, 8)
scoreboardCorner.Parent = scoreboardFrame

local scoreboardTitle = Instance.new("TextLabel")
scoreboardTitle.BackgroundTransparency = 1
scoreboardTitle.Position = UDim2.fromOffset(12, 10)
scoreboardTitle.Size = UDim2.new(1, -24, 0, 22)
scoreboardTitle.Font = Enum.Font.GothamBold
scoreboardTitle.Text = "Leaderboard"
scoreboardTitle.TextColor3 = Color3.fromRGB(46, 42, 34)
scoreboardTitle.TextSize = 15
scoreboardTitle.TextXAlignment = Enum.TextXAlignment.Left
scoreboardTitle.Parent = scoreboardFrame

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.Position = UDim2.fromOffset(18, 372)
feedbackLabel.Size = UDim2.new(1, -36, 0, 26)
feedbackLabel.Font = Enum.Font.GothamMedium
feedbackLabel.Text = "Pick one answer before time runs out."
feedbackLabel.TextColor3 = Color3.fromRGB(66, 91, 67)
feedbackLabel.TextSize = 14
feedbackLabel.TextWrapped = true
feedbackLabel.TextXAlignment = Enum.TextXAlignment.Left
feedbackLabel.Parent = panel

local function setAnswerButtonsEnabled(enabled: boolean)
    for _, button in ipairs(answerButtons) do
        button.Active = enabled
        button.AutoButtonColor = enabled
        button.BackgroundTransparency = enabled and 0 or 0.18
    end
end

local function clearAnswers()
    for _, button in ipairs(answerButtons) do
        button:Destroy()
    end

    answerButtons = {}
end

local function buildAnswerButton(optionText: string, index: number)
    local button = Instance.new("TextButton")
    button.Name = string.format("Answer_%d", index)
    button.Size = UDim2.new(1, 0, 0, 46)
    button.BackgroundColor3 = Color3.fromRGB(76, 96, 73)
    button.Font = Enum.Font.GothamBold
    button.Text = string.format("%d. %s", index, optionText)
    button.TextColor3 = Color3.fromRGB(250, 246, 234)
    button.TextSize = 15
    button.TextWrapped = true
    button.Parent = answersFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.Activated:Connect(function()
        if selectedThisRound then
            return
        end

        selectedThisRound = true
        feedbackLabel.Text = "Answer sent. Waiting for the round result."
        setAnswerButtonsEnabled(false)
        submitTriviaAnswer:FireServer(index)
    end)

    table.insert(answerButtons, button)
end

local function updateScoreboard(rows)
    for _, row in ipairs(scoreRows) do
        row:Destroy()
    end

    scoreRows = {}

    for index = 1, 5 do
        local rowData = rows and rows[index]
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(12, 36 + (index - 1) * 31)
        label.Size = UDim2.new(1, -24, 0, 28)
        label.Font = Enum.Font.GothamMedium
        label.TextColor3 = Color3.fromRGB(55, 49, 38)
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = rowData and string.format("%d. %s - %d", index, rowData.PlayerName, rowData.Score) or string.format("%d. Waiting...", index)
        label.Parent = scoreboardFrame
        table.insert(scoreRows, label)
    end
end

showTriviaQuestion.OnClientEvent:Connect(function(payload)
    panel.Visible = true
    selectedThisRound = false
    questionEndsAt = os.clock() + (payload.TimeLimit or 16)
    titleLabel.Text = payload.DisplayName or "Islamic Trivia Challenge"
    metaLabel.Text = string.format("Round %d of %d | Difficulty %d", payload.Round or 1, payload.TotalRounds or 1, payload.Difficulty or 1)
    questionLabel.Text = payload.Prompt or ""
    feedbackLabel.Text = "Pick one answer before time runs out."
    clearAnswers()

    for index, optionText in ipairs(payload.Options or {}) do
        buildAnswerButton(optionText, index)
    end
end)

showTriviaResult.OnClientEvent:Connect(function(payload)
    panel.Visible = true

    if payload.Personal then
        feedbackLabel.Text = payload.Correct and "Correct. Nice streak." or string.format("Not this time. Correct answer: %s", payload.CorrectText or "")
    else
        feedbackLabel.Text = string.format("Correct answer: %s. %s", payload.CorrectText or "", payload.Explanation or "")
        setAnswerButtonsEnabled(false)
    end

    if payload.Scoreboard then
        updateScoreboard(payload.Scoreboard)
    end
end)

updateTriviaScores.OnClientEvent:Connect(function(payload)
    if payload.Scoreboard then
        updateScoreboard(payload.Scoreboard)
    end
end)

clearTrivia.OnClientEvent:Connect(function(payload)
    panel.Visible = true
    selectedThisRound = true
    questionEndsAt = 0
    clearAnswers()
    titleLabel.Text = "Trivia Complete"
    metaLabel.Text = "Final scoreboard"
    timerLabel.Text = ""
    questionLabel.Text = payload.Message or "Trivia finished."
    feedbackLabel.Text = "Start again from the trivia court or the menu."

    if payload.Scoreboard then
        updateScoreboard(payload.Scoreboard)
    end
end)

RunService.RenderStepped:Connect(function()
    if not panel.Visible or questionEndsAt <= 0 then
        return
    end

    local remaining = math.max(0, math.ceil(questionEndsAt - os.clock()))
    timerLabel.Text = string.format("%ds", remaining)

    if remaining <= 0 and not selectedThisRound then
        selectedThisRound = true
        feedbackLabel.Text = "Time is up. Waiting for the answer."
        setAnswerButtonsEnabled(false)
    end
end)
