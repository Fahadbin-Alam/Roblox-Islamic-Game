--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hubFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hub")
local showLearningTrail = hubFolder:WaitForChild("ShowLearningTrail") :: RemoteEvent
local updateLearningTrail = hubFolder:WaitForChild("UpdateLearningTrail") :: RemoteEvent
local clearLearningTrail = hubFolder:WaitForChild("ClearLearningTrail") :: RemoteEvent

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LearningTrailHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 17
screenGui.Parent = playerGui

local missionFrame = Instance.new("Frame")
missionFrame.AnchorPoint = Vector2.new(1, 0)
missionFrame.Position = UDim2.new(1, -22, 0, 22)
missionFrame.Size = UDim2.new(0.92, 0, 0, 112)
missionFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 34)
missionFrame.BackgroundTransparency = 0.08
missionFrame.Visible = false
missionFrame.Parent = screenGui

local missionSize = Instance.new("UISizeConstraint")
missionSize.MaxSize = Vector2.new(340, 112)
missionSize.MinSize = Vector2.new(260, 112)
missionSize.Parent = missionFrame

local missionCorner = Instance.new("UICorner")
missionCorner.CornerRadius = UDim.new(0, 8)
missionCorner.Parent = missionFrame

local missionStroke = Instance.new("UIStroke")
missionStroke.Color = Color3.fromRGB(198, 164, 88)
missionStroke.Thickness = 1.4
missionStroke.Parent = missionFrame

local missionTitle = Instance.new("TextLabel")
missionTitle.BackgroundTransparency = 1
missionTitle.Position = UDim2.fromOffset(16, 12)
missionTitle.Size = UDim2.new(1, -32, 0, 22)
missionTitle.Font = Enum.Font.GothamBold
missionTitle.Text = ""
missionTitle.TextColor3 = Color3.fromRGB(248, 239, 216)
missionTitle.TextSize = 17
missionTitle.TextXAlignment = Enum.TextXAlignment.Left
missionTitle.Parent = missionFrame

local missionStep = Instance.new("TextLabel")
missionStep.BackgroundTransparency = 1
missionStep.Position = UDim2.fromOffset(16, 38)
missionStep.Size = UDim2.new(1, -32, 0, 18)
missionStep.Font = Enum.Font.GothamMedium
missionStep.Text = ""
missionStep.TextColor3 = Color3.fromRGB(223, 190, 112)
missionStep.TextSize = 14
missionStep.TextXAlignment = Enum.TextXAlignment.Left
missionStep.Parent = missionFrame

local missionObjective = Instance.new("TextLabel")
missionObjective.BackgroundTransparency = 1
missionObjective.Position = UDim2.fromOffset(16, 61)
missionObjective.Size = UDim2.new(1, -32, 0, 32)
missionObjective.Font = Enum.Font.Gotham
missionObjective.Text = ""
missionObjective.TextColor3 = Color3.fromRGB(235, 231, 219)
missionObjective.TextSize = 14
missionObjective.TextWrapped = true
missionObjective.TextXAlignment = Enum.TextXAlignment.Left
missionObjective.TextYAlignment = Enum.TextYAlignment.Top
missionObjective.Parent = missionFrame

local locationLabel = Instance.new("TextLabel")
locationLabel.BackgroundTransparency = 1
locationLabel.Position = UDim2.fromOffset(16, 91)
locationLabel.Size = UDim2.new(1, -32, 0, 16)
locationLabel.Font = Enum.Font.GothamMedium
locationLabel.Text = ""
locationLabel.TextColor3 = Color3.fromRGB(183, 198, 174)
locationLabel.TextSize = 12
locationLabel.TextXAlignment = Enum.TextXAlignment.Left
locationLabel.Parent = missionFrame

local dialogueFrame = Instance.new("Frame")
dialogueFrame.AnchorPoint = Vector2.new(0.5, 1)
dialogueFrame.Position = UDim2.new(0.5, 0, 1, -220)
dialogueFrame.Size = UDim2.new(0.92, 0, 0, 132)
dialogueFrame.BackgroundColor3 = Color3.fromRGB(26, 27, 25)
dialogueFrame.BackgroundTransparency = 0.05
dialogueFrame.Visible = false
dialogueFrame.Parent = screenGui

local dialogueSize = Instance.new("UISizeConstraint")
dialogueSize.MaxSize = Vector2.new(660, 132)
dialogueSize.MinSize = Vector2.new(300, 132)
dialogueSize.Parent = dialogueFrame

local dialogueCorner = Instance.new("UICorner")
dialogueCorner.CornerRadius = UDim.new(0, 8)
dialogueCorner.Parent = dialogueFrame

local dialogueStroke = Instance.new("UIStroke")
dialogueStroke.Color = Color3.fromRGB(198, 164, 88)
dialogueStroke.Thickness = 1.4
dialogueStroke.Parent = dialogueFrame

local dialogueTitle = Instance.new("TextLabel")
dialogueTitle.BackgroundTransparency = 1
dialogueTitle.Position = UDim2.fromOffset(18, 12)
dialogueTitle.Size = UDim2.new(1, -36, 0, 22)
dialogueTitle.Font = Enum.Font.GothamBold
dialogueTitle.Text = ""
dialogueTitle.TextColor3 = Color3.fromRGB(248, 239, 216)
dialogueTitle.TextSize = 17
dialogueTitle.TextXAlignment = Enum.TextXAlignment.Left
dialogueTitle.Parent = dialogueFrame

local dialogueSpeaker = Instance.new("TextLabel")
dialogueSpeaker.BackgroundTransparency = 1
dialogueSpeaker.Position = UDim2.fromOffset(18, 39)
dialogueSpeaker.Size = UDim2.new(1, -36, 0, 18)
dialogueSpeaker.Font = Enum.Font.GothamMedium
dialogueSpeaker.Text = ""
dialogueSpeaker.TextColor3 = Color3.fromRGB(183, 211, 177)
dialogueSpeaker.TextSize = 14
dialogueSpeaker.TextXAlignment = Enum.TextXAlignment.Left
dialogueSpeaker.Parent = dialogueFrame

local dialogueBody = Instance.new("TextLabel")
dialogueBody.BackgroundTransparency = 1
dialogueBody.Position = UDim2.fromOffset(18, 62)
dialogueBody.Size = UDim2.new(1, -36, 1, -74)
dialogueBody.Font = Enum.Font.Gotham
dialogueBody.Text = ""
dialogueBody.TextColor3 = Color3.fromRGB(239, 235, 224)
dialogueBody.TextSize = 16
dialogueBody.TextWrapped = true
dialogueBody.TextXAlignment = Enum.TextXAlignment.Left
dialogueBody.TextYAlignment = Enum.TextYAlignment.Top
dialogueBody.Parent = dialogueFrame

local dialogueToken = 0
local LINE_DURATION_SECONDS = 2.45

local function normalizeDialogueLine(rawLine)
    if typeof(rawLine) == "table" then
        return rawLine.Speaker or "", rawLine.Text or ""
    end

    return "", tostring(rawLine)
end

updateLearningTrail.OnClientEvent:Connect(function(payload)
    missionFrame.Visible = true
    missionTitle.Text = payload.TrailName or "Learning Walk"
    missionStep.Text = payload.StepLabel or ""
    missionObjective.Text = payload.Objective or ""
    locationLabel.Text = payload.LocationName or ""
end)

showLearningTrail.OnClientEvent:Connect(function(payload)
    dialogueToken += 1
    local currentToken = dialogueToken
    local lines = payload.Lines or {}

    dialogueFrame.Visible = true
    dialogueTitle.Text = payload.Title or payload.TrailName or "Learning Walk"

    for _, rawLine in ipairs(lines) do
        if currentToken ~= dialogueToken then
            return
        end

        local speaker, body = normalizeDialogueLine(rawLine)
        dialogueSpeaker.Text = speaker
        dialogueBody.Text = body
        task.wait(LINE_DURATION_SECONDS)
    end

    if currentToken == dialogueToken then
        dialogueFrame.Visible = false
    end
end)

clearLearningTrail.OnClientEvent:Connect(function()
    dialogueToken += 1
    missionFrame.Visible = false
    dialogueFrame.Visible = false
end)
