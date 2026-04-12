--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storyFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Story")
local showStoryDialogue = storyFolder:WaitForChild("ShowStoryDialogue") :: RemoteEvent
local updateStoryMission = storyFolder:WaitForChild("UpdateStoryMission") :: RemoteEvent
local clearStoryMission = storyFolder:WaitForChild("ClearStoryMission") :: RemoteEvent

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StoryHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 18
screenGui.Parent = playerGui

local missionFrame = Instance.new("Frame")
missionFrame.AnchorPoint = Vector2.new(0, 0)
missionFrame.Position = UDim2.fromOffset(22, 22)
missionFrame.Size = UDim2.fromOffset(360, 116)
missionFrame.BackgroundColor3 = Color3.fromRGB(248, 240, 220)
missionFrame.Visible = false
missionFrame.Parent = screenGui

local missionCorner = Instance.new("UICorner")
missionCorner.CornerRadius = UDim.new(0, 16)
missionCorner.Parent = missionFrame

local missionStroke = Instance.new("UIStroke")
missionStroke.Color = Color3.fromRGB(111, 92, 61)
missionStroke.Thickness = 1.6
missionStroke.Parent = missionFrame

local storyNameLabel = Instance.new("TextLabel")
storyNameLabel.BackgroundTransparency = 1
storyNameLabel.Position = UDim2.fromOffset(16, 14)
storyNameLabel.Size = UDim2.new(1, -32, 0, 22)
storyNameLabel.Font = Enum.Font.GothamBold
storyNameLabel.Text = ""
storyNameLabel.TextColor3 = Color3.fromRGB(63, 57, 45)
storyNameLabel.TextSize = 18
storyNameLabel.TextXAlignment = Enum.TextXAlignment.Left
storyNameLabel.Parent = missionFrame

local stepLabel = Instance.new("TextLabel")
stepLabel.BackgroundTransparency = 1
stepLabel.Position = UDim2.fromOffset(16, 40)
stepLabel.Size = UDim2.new(1, -32, 0, 18)
stepLabel.Font = Enum.Font.GothamMedium
stepLabel.Text = ""
stepLabel.TextColor3 = Color3.fromRGB(78, 111, 83)
stepLabel.TextSize = 14
stepLabel.TextXAlignment = Enum.TextXAlignment.Left
stepLabel.Parent = missionFrame

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.BackgroundTransparency = 1
objectiveLabel.Position = UDim2.fromOffset(16, 62)
objectiveLabel.Size = UDim2.new(1, -32, 0, 28)
objectiveLabel.Font = Enum.Font.Gotham
objectiveLabel.Text = ""
objectiveLabel.TextColor3 = Color3.fromRGB(84, 74, 59)
objectiveLabel.TextSize = 15
objectiveLabel.TextWrapped = true
objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
objectiveLabel.Parent = missionFrame

local locationLabel = Instance.new("TextLabel")
locationLabel.BackgroundTransparency = 1
locationLabel.Position = UDim2.fromOffset(16, 90)
locationLabel.Size = UDim2.new(1, -32, 0, 18)
locationLabel.Font = Enum.Font.GothamMedium
locationLabel.Text = ""
locationLabel.TextColor3 = Color3.fromRGB(115, 100, 74)
locationLabel.TextSize = 13
locationLabel.TextXAlignment = Enum.TextXAlignment.Left
locationLabel.Parent = missionFrame

local dialogueFrame = Instance.new("Frame")
dialogueFrame.AnchorPoint = Vector2.new(0.5, 1)
dialogueFrame.Position = UDim2.new(0.5, 0, 1, -42)
dialogueFrame.Size = UDim2.fromOffset(840, 196)
dialogueFrame.BackgroundColor3 = Color3.fromRGB(30, 27, 24)
dialogueFrame.BackgroundTransparency = 0.08
dialogueFrame.Visible = false
dialogueFrame.Parent = screenGui

local dialogueCorner = Instance.new("UICorner")
dialogueCorner.CornerRadius = UDim.new(0, 18)
dialogueCorner.Parent = dialogueFrame

local dialogueStroke = Instance.new("UIStroke")
dialogueStroke.Color = Color3.fromRGB(174, 145, 87)
dialogueStroke.Thickness = 1.5
dialogueStroke.Parent = dialogueFrame

local dialogueTitle = Instance.new("TextLabel")
dialogueTitle.BackgroundTransparency = 1
dialogueTitle.Position = UDim2.fromOffset(20, 14)
dialogueTitle.Size = UDim2.new(1, -40, 0, 22)
dialogueTitle.Font = Enum.Font.GothamBold
dialogueTitle.Text = ""
dialogueTitle.TextColor3 = Color3.fromRGB(233, 215, 179)
dialogueTitle.TextSize = 18
dialogueTitle.TextXAlignment = Enum.TextXAlignment.Left
dialogueTitle.Parent = dialogueFrame

local dialogueSpeaker = Instance.new("TextLabel")
dialogueSpeaker.BackgroundTransparency = 1
dialogueSpeaker.Position = UDim2.fromOffset(20, 40)
dialogueSpeaker.Size = UDim2.new(1, -40, 0, 20)
dialogueSpeaker.Font = Enum.Font.GothamMedium
dialogueSpeaker.Text = ""
dialogueSpeaker.TextColor3 = Color3.fromRGB(160, 194, 164)
dialogueSpeaker.TextSize = 15
dialogueSpeaker.TextXAlignment = Enum.TextXAlignment.Left
dialogueSpeaker.Parent = dialogueFrame

local dialogueBody = Instance.new("TextLabel")
dialogueBody.BackgroundTransparency = 1
dialogueBody.Position = UDim2.fromOffset(20, 66)
dialogueBody.Size = UDim2.new(1, -40, 1, -86)
dialogueBody.Font = Enum.Font.Gotham
dialogueBody.Text = ""
dialogueBody.TextColor3 = Color3.fromRGB(240, 236, 226)
dialogueBody.TextSize = 19
dialogueBody.TextWrapped = true
dialogueBody.TextXAlignment = Enum.TextXAlignment.Left
dialogueBody.TextYAlignment = Enum.TextYAlignment.Top
dialogueBody.Parent = dialogueFrame

local dialogueToken = 0
local MIN_LINE_DURATION_SECONDS = 2.7
local MAX_LINE_DURATION_SECONDS = 7.2
local REFERENCE_SPEAKER_COLOR = Color3.fromRGB(215, 189, 126)
local DEFAULT_SPEAKER_COLOR = Color3.fromRGB(160, 194, 164)

local function normalizeDialogueLine(rawLine)
    if typeof(rawLine) == "table" then
        return rawLine.Speaker or "", rawLine.Text or ""
    end

    return "", tostring(rawLine)
end

local function getLineDuration(body: string): number
    local characters = string.len(body)
    return math.clamp(2.1 + characters * 0.028, MIN_LINE_DURATION_SECONDS, MAX_LINE_DURATION_SECONDS)
end

showStoryDialogue.OnClientEvent:Connect(function(payload)
    dialogueToken += 1
    local currentToken = dialogueToken
    local lines = payload.Lines or {}

    dialogueFrame.Visible = true
    dialogueTitle.Text = payload.Title or payload.StoryName or "Story"

    for _, rawLine in ipairs(lines) do
        if currentToken ~= dialogueToken then
            return
        end

        local speaker, body = normalizeDialogueLine(rawLine)
        dialogueSpeaker.Text = speaker
        dialogueSpeaker.TextColor3 = string.find(string.lower(speaker), "reference", 1, true) and REFERENCE_SPEAKER_COLOR or DEFAULT_SPEAKER_COLOR
        dialogueBody.Text = body
        task.wait(getLineDuration(body))
    end

    if currentToken == dialogueToken then
        dialogueFrame.Visible = false
    end
end)

updateStoryMission.OnClientEvent:Connect(function(payload)
    missionFrame.Visible = true
    storyNameLabel.Text = payload.StoryName or ""
    stepLabel.Text = payload.StepLabel or ""
    objectiveLabel.Text = payload.Objective or ""
    locationLabel.Text = payload.LocationName or ""
end)

clearStoryMission.OnClientEvent:Connect(function()
    missionFrame.Visible = false
    dialogueFrame.Visible = false
end)
