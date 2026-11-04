--!strict

-- Shows the shared study circle quiz: gathering countdown, each question, the group's result
-- for it, and the final pass or fail for the whole circle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local learningFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Learning")
local circleUpdate = learningFolder:WaitForChild("StudyCircleUpdate") :: RemoteEvent
local circleAnswer = learningFolder:WaitForChild("StudyCircleAnswer") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
    Panel = Color3.fromRGB(246, 238, 218),
    Ink = Color3.fromRGB(42, 38, 30),
    SoftInk = Color3.fromRGB(88, 78, 62),
    Option = Color3.fromRGB(63, 98, 88),
    Selected = Color3.fromRGB(176, 140, 62),
    Correct = Color3.fromRGB(63, 120, 78),
    Wrong = Color3.fromRGB(150, 74, 60),
    Muted = Color3.fromRGB(150, 142, 126),
    Light = Color3.fromRGB(250, 246, 234),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StudyCircleHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 29
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 20)
panel.Size = UDim2.new(0.9, 0, 0, 330)
panel.BackgroundColor3 = COLORS.Panel
panel.Visible = false
panel.Parent = screenGui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(620, 330)
sizeLimit.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(101, 83, 55)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local function makeLabel(position: UDim2, size: UDim2, textSize: number, font: Enum.Font, color: Color3): TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Position = position
    textLabel.Size = size
    textLabel.Font = font
    textLabel.Text = ""
    textLabel.TextColor3 = color
    textLabel.TextSize = textSize
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Parent = panel

    return textLabel
end

local titleLabel = makeLabel(UDim2.fromOffset(18, 14), UDim2.new(1, -36, 0, 26), 20, Enum.Font.GothamBold, COLORS.Ink)
local metaLabel = makeLabel(UDim2.fromOffset(18, 42), UDim2.new(1, -36, 0, 20), 14, Enum.Font.GothamMedium, COLORS.SoftInk)
local bodyLabel = makeLabel(UDim2.fromOffset(18, 68), UDim2.new(1, -36, 0, 62), 18, Enum.Font.GothamBold, COLORS.Ink)
local footerLabel = makeLabel(UDim2.new(0, 18, 1, -48), UDim2.new(1, -36, 0, 40), 14, Enum.Font.Gotham, COLORS.SoftInk)

local optionsFrame = Instance.new("Frame")
optionsFrame.BackgroundTransparency = 1
optionsFrame.Position = UDim2.fromOffset(18, 136)
optionsFrame.Size = UDim2.new(1, -36, 0, 140)
optionsFrame.Parent = panel

local optionsLayout = Instance.new("UIGridLayout")
optionsLayout.CellPadding = UDim2.fromOffset(10, 10)
optionsLayout.CellSize = UDim2.new(0.5, -5, 0, 62)
optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
optionsLayout.Parent = optionsFrame

local optionButtons: { TextButton } = {}
local currentQuestion = 0
local selectedIndex: number? = nil
local hideToken = 0

for index = 1, 4 do
    local optionButton = Instance.new("TextButton")
    optionButton.AutoButtonColor = true
    optionButton.BackgroundColor3 = COLORS.Option
    optionButton.BorderSizePixel = 0
    optionButton.Font = Enum.Font.GothamBold
    optionButton.LayoutOrder = index
    optionButton.Text = ""
    optionButton.TextColor3 = COLORS.Light
    optionButton.TextSize = 15
    optionButton.TextWrapped = true
    optionButton.Visible = false
    optionButton.Parent = optionsFrame

    local optionCorner = Instance.new("UICorner")
    optionCorner.CornerRadius = UDim.new(0, 8)
    optionCorner.Parent = optionButton

    optionButton.Activated:Connect(function()
        if selectedIndex ~= nil or currentQuestion == 0 then
            return
        end

        selectedIndex = index

        for otherIndex, other in ipairs(optionButtons) do
            other.BackgroundColor3 = if otherIndex == index then COLORS.Selected else COLORS.Muted
        end

        footerLabel.Text = "Answer locked in. Waiting for the rest of the circle..."
        circleAnswer:FireServer(currentQuestion, index)
    end)

    optionButtons[index] = optionButton
end

local function showOptions(options: { string }?)
    for index, optionButton in ipairs(optionButtons) do
        local text = options and options[index]
        optionButton.Visible = text ~= nil
        optionButton.Text = text or ""
        optionButton.BackgroundColor3 = COLORS.Option
    end
end

local function hideLater(seconds: number)
    hideToken += 1
    local token = hideToken

    task.delay(seconds, function()
        if token == hideToken then
            panel.Visible = false
        end
    end)
end

local function show()
    hideToken += 1
    panel.Visible = true
end

circleUpdate.OnClientEvent:Connect(function(payload: any)
    if type(payload) ~= "table" then
        return
    end

    local phase = payload.Phase

    if phase == "notice" then
        show()
        titleLabel.Text = "Study Circle"
        metaLabel.Text = ""
        bodyLabel.Text = tostring(payload.Text or "")
        footerLabel.Text = ""
        showOptions(nil)
        hideLater(4)
    elseif phase == "gathering" then
        show()
        currentQuestion = 0
        titleLabel.Text = "Study Circle Gathering"
        metaLabel.Text = string.format("Starting in %d seconds", payload.Seconds or 0)
        bodyLabel.Text = tostring(payload.Text or "")
        footerLabel.Text = "Answer together. The whole circle passes or fails as a group."
        showOptions(nil)
    elseif phase == "question" then
        show()
        currentQuestion = payload.Index
        selectedIndex = nil
        titleLabel.Text = string.format("Study Circle: %s", tostring(payload.LessonName))
        metaLabel.Text = string.format("Question %d of %d  ·  %d in the circle  ·  %d seconds", payload.Index, payload.Total, payload.Participants or 1, payload.TimeLimit or 0)
        bodyLabel.Text = tostring(payload.Prompt)
        footerLabel.Text = "Choose an answer. Talk it through with your circle in chat!"
        showOptions(payload.Options)
    elseif phase == "reveal" then
        show()
        currentQuestion = 0

        for index, optionButton in ipairs(optionButtons) do
            if index == payload.CorrectIndex then
                optionButton.BackgroundColor3 = COLORS.Correct
            elseif index == selectedIndex then
                optionButton.BackgroundColor3 = COLORS.Wrong
            else
                optionButton.BackgroundColor3 = COLORS.Muted
            end
        end

        footerLabel.Text = string.format("%d of %d answered correctly. %s", payload.CorrectCount or 0, payload.Participants or 1, tostring(payload.Explanation or ""))
    elseif phase == "finished" then
        show()
        currentQuestion = 0
        titleLabel.Text = if payload.Passed then "Study circle passed!" else "Study circle complete"
        metaLabel.Text = string.format("%s  ·  The circle scored %d%%", tostring(payload.LessonName), payload.Percent or 0)

        if payload.Passed then
            bodyLabel.Text = string.format("Everyone in the circle earns %d XP.", payload.XP or 0)
        else
            bodyLabel.Text = "Review the lesson in the Islamic Studies hall and try another circle together."
        end

        footerLabel.Text = if payload.IsGroup then "" else "Study with at least one other player to earn the Halaqah Member badge."
        showOptions(nil)
        hideLater(7)
    end
end)

-- Joining a battle or story removes the player from the circle, so close the panel too.
local function hideIfBusy()
    if player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true then
        currentQuestion = 0
        panel.Visible = false
    end
end

player:GetAttributeChangedSignal("InBattle"):Connect(hideIfBusy)
player:GetAttributeChangedSignal("InStory"):Connect(hideIfBusy)
