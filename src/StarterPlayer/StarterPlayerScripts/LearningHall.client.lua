--!strict

-- Islamic Studies hall: browse units, read a lesson page by page, take its checkpoint quiz
-- (graded by the server), and view the journal of levels and badges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local IslamicStudies = require(Shared.Data.IslamicStudies)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local progressFolder = remotesFolder:WaitForChild("Progress")
local learningFolder = remotesFolder:WaitForChild("Learning")
local profileUpdated = progressFolder:WaitForChild("ProfileUpdated") :: RemoteEvent
local openLearningHall = learningFolder:WaitForChild("OpenLearningHall") :: RemoteEvent
local submitQuiz = learningFolder:WaitForChild("SubmitQuiz") :: RemoteEvent
local quizResult = learningFolder:WaitForChild("QuizResult") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
    Parchment = Color3.fromRGB(246, 238, 218),
    Card = Color3.fromRGB(255, 251, 240),
    Ink = Color3.fromRGB(42, 38, 30),
    SoftInk = Color3.fromRGB(88, 78, 62),
    Border = Color3.fromRGB(101, 83, 55),
    Gold = Color3.fromRGB(193, 162, 86),
    Success = Color3.fromRGB(63, 120, 78),
    Danger = Color3.fromRGB(150, 74, 60),
    Locked = Color3.fromRGB(176, 168, 150),
    Light = Color3.fromRGB(250, 246, 234),
}

type Snapshot = {
    Level: number,
    XP: number,
    XPIntoLevel: number,
    XPForNext: number,
    RankTitle: string,
    Badges: { { Id: string, DisplayName: string, Description: string, Earned: boolean } },
    Completed: { [string]: { string } },
    Stats: { [string]: number },
}

local snapshot: Snapshot? = nil
local currentUnitId: string? = nil
local pendingLessonId: string? = nil
local refreshCurrentView: (() -> ())? = nil

local unitById = {}
local lessonById = {}
local unitIdByLessonId = {}

for _, unit in ipairs(IslamicStudies.Units) do
    unitById[unit.Id] = unit

    for _, lesson in ipairs(unit.Lessons) do
        lessonById[lesson.Id] = lesson
        unitIdByLessonId[lesson.Id] = unit.Id
    end
end

local function rgb(values: { number }): Color3
    return Color3.fromRGB(values[1], values[2], values[3])
end

local function completedSet(category: string): { [string]: boolean }
    local set = {}

    if snapshot and snapshot.Completed[category] then
        for _, id in ipairs(snapshot.Completed[category]) do
            set[id] = true
        end
    end

    return set
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LearningHall"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1001
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.Size = UDim2.fromScale(0.94, 0.86)
panel.BackgroundColor3 = COLORS.Parchment
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MaxSize = Vector2.new(900, 600)
panelLimit.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.Border
panelStroke.Thickness = 2
panelStroke.Parent = panel

local function label(parent: Instance, text: string, size: number, font: Enum.Font, color: Color3): TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Font = font
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextSize = size
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Parent = parent

    return textLabel
end

local function corner(parent: Instance, radius: number)
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, radius)
    uiCorner.Parent = parent
end

local function button(parent: Instance, text: string, color: Color3, onClick: () -> ()): TextButton
    local textButton = Instance.new("TextButton")
    textButton.AutoButtonColor = true
    textButton.BackgroundColor3 = color
    textButton.BorderSizePixel = 0
    textButton.Font = Enum.Font.GothamBold
    textButton.Text = text
    textButton.TextColor3 = COLORS.Light
    textButton.TextSize = 16
    textButton.TextWrapped = true
    textButton.Parent = parent
    corner(textButton, 8)

    local lastClickAt = 0

    textButton.Activated:Connect(function()
        local now = os.clock()

        if now - lastClickAt < 0.2 then
            return
        end

        lastClickAt = now
        onClick()
    end)

    return textButton
end

local titleLabel = label(panel, "Islamic Studies", 26, Enum.Font.GothamBold, COLORS.Ink)
titleLabel.Position = UDim2.fromOffset(22, 16)
titleLabel.Size = UDim2.new(1, -90, 0, 32)

local subtitleLabel = label(panel, "Learn, take the checkpoint quiz, and earn XP and badges.", 15, Enum.Font.GothamMedium, COLORS.SoftInk)
subtitleLabel.Position = UDim2.fromOffset(22, 50)
subtitleLabel.Size = UDim2.new(1, -90, 0, 20)

local closeButton = button(panel, "X", COLORS.Border, function()
    panel.Visible = false
end)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 16)
closeButton.Size = UDim2.fromOffset(42, 42)

local sidebar = Instance.new("ScrollingFrame")
sidebar.Name = "Units"
sidebar.Position = UDim2.fromOffset(16, 84)
sidebar.Size = UDim2.new(0.28, -16, 1, -100)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel = 0
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.CanvasSize = UDim2.new()
sidebar.ScrollBarThickness = 4
sidebar.Parent = panel

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 8)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.new(0.28, 12, 0, 84)
content.Size = UDim2.new(0.72, -28, 1, -100)
content.BackgroundColor3 = COLORS.Card
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = panel
corner(content, 12)

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 14)
contentPadding.PaddingBottom = UDim.new(0, 14)
contentPadding.PaddingLeft = UDim.new(0, 16)
contentPadding.PaddingRight = UDim.new(0, 16)
contentPadding.Parent = content

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

-- A vertical scrolling list filling the content area above an optional footer bar.
local function contentList(footerHeight: number): ScrollingFrame
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, 0, 1, -footerHeight)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 5
    list.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = list

    return list
end

local function autoLabel(parent: Instance, text: string, size: number, font: Enum.Font, color: Color3, order: number): TextLabel
    local textLabel = label(parent, text, size, font, color)
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Size = UDim2.new(1, 0, 0, 0)
    textLabel.LayoutOrder = order

    return textLabel
end

local function footer(): Frame
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.fromScale(0, 1)
    bar.Size = UDim2.new(1, 0, 0, 46)
    bar.BackgroundTransparency = 1
    bar.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bar

    return bar
end

local function footerButton(bar: Frame, text: string, color: Color3, order: number, onClick: () -> ())
    local footerBtn = button(bar, text, color, onClick)
    footerBtn.Size = UDim2.new(0.32, 0, 0, 42)
    footerBtn.LayoutOrder = order
end

local showUnit: (unitId: string) -> ()
local showLesson: (lessonId: string, pageIndex: number) -> ()
local showJournal: () -> ()

local function showQuestion(lessonId: string, questionIndex: number, answers: { number })
    local lesson = lessonById[lessonId]
    local question = lesson.Quiz[questionIndex]
    refreshCurrentView = nil
    clearContent()

    local list = contentList(56)
    autoLabel(list, string.format("Checkpoint quiz  ·  Question %d of %d", questionIndex, #lesson.Quiz), 14, Enum.Font.GothamBold, COLORS.SoftInk, 1)
    autoLabel(list, question.Prompt, 21, Enum.Font.GothamBold, COLORS.Ink, 2)

    for optionIndex, optionText in ipairs(question.Options) do
        local optionButton = button(list, optionText, rgb(unitById[unitIdByLessonId[lessonId]].AccentRGB), function()
            answers[questionIndex] = optionIndex

            if questionIndex < #lesson.Quiz then
                showQuestion(lessonId, questionIndex + 1, answers)
            else
                clearContent()
                autoLabel(content, "Checking your answers...", 18, Enum.Font.GothamMedium, COLORS.SoftInk, 1)
                pendingLessonId = lessonId
                submitQuiz:FireServer(lessonId, answers)

                task.delay(6, function()
                    if pendingLessonId == lessonId then
                        pendingLessonId = nil
                        clearContent()
                        autoLabel(content, "We could not check your answers. Please try again.", 18, Enum.Font.GothamMedium, COLORS.Danger, 1)
                        footerButton(footer(), "Back To Lesson", COLORS.Border, 1, function()
                            showLesson(lessonId, 1)
                        end)
                    end
                end)
            end
        end)
        optionButton.Size = UDim2.new(1, 0, 0, 48)
        optionButton.LayoutOrder = 2 + optionIndex
    end

    local bar = footer()
    footerButton(bar, "Back To Lesson", COLORS.Border, 1, function()
        showLesson(lessonId, 1)
    end)
end

local function showResult(result: any)
    local lesson = lessonById[result.LessonId]

    if not lesson then
        return
    end

    refreshCurrentView = nil
    clearContent()

    local list = contentList(56)
    local headline = if result.Passed then "Lesson complete!" else "Almost there"
    autoLabel(list, headline, 24, Enum.Font.GothamBold, if result.Passed then COLORS.Success else COLORS.Danger, 1)

    local summary = string.format("You answered %d of %d correctly.", result.Correct, result.Total)

    if result.Passed and result.XPAwarded > 0 then
        summary ..= string.format(" +%d XP", result.XPAwarded)
    elseif not result.Passed then
        summary ..= string.format(" You need %d to pass. Review the lesson and try again.", result.Required)
    end

    autoLabel(list, summary, 16, Enum.Font.GothamMedium, COLORS.Ink, 2)

    for index, question in ipairs(lesson.Quiz) do
        local entry = result.Results[index]

        if entry then
            local mark = if entry.Correct then "Correct" else "Not quite"
            local text = string.format("%d. %s\n%s: %s\n%s", index, question.Prompt, mark, question.Options[entry.CorrectIndex] or "", entry.Explanation)
            local textLabel = autoLabel(list, text, 15, Enum.Font.Gotham, if entry.Correct then COLORS.Ink else COLORS.Danger, 2 + index)
            textLabel.LineHeight = 1.1
        end
    end

    local bar = footer()

    if not result.Passed then
        footerButton(bar, "Try Again", COLORS.Gold, 1, function()
            showQuestion(lesson.Id, 1, {})
        end)
    end

    footerButton(bar, "Back To Lessons", COLORS.Border, 2, function()
        showUnit(unitIdByLessonId[lesson.Id])
    end)
end

showLesson = function(lessonId: string, pageIndex: number)
    local lesson = lessonById[lessonId]
    refreshCurrentView = nil
    clearContent()

    local list = contentList(56)
    autoLabel(list, lesson.DisplayName, 22, Enum.Font.GothamBold, COLORS.Ink, 1)
    autoLabel(list, string.format("Page %d of %d", pageIndex, #lesson.Pages), 14, Enum.Font.GothamMedium, COLORS.SoftInk, 2)
    local body = autoLabel(list, lesson.Pages[pageIndex], 19, Enum.Font.Gotham, COLORS.Ink, 3)
    body.LineHeight = 1.15

    local bar = footer()

    if pageIndex > 1 then
        footerButton(bar, "Previous", COLORS.Border, 1, function()
            showLesson(lessonId, pageIndex - 1)
        end)
    else
        footerButton(bar, "All Lessons", COLORS.Border, 1, function()
            showUnit(unitIdByLessonId[lessonId])
        end)
    end

    if pageIndex < #lesson.Pages then
        footerButton(bar, "Next", COLORS.Success, 2, function()
            showLesson(lessonId, pageIndex + 1)
        end)
    else
        footerButton(bar, "Take The Quiz", COLORS.Gold, 2, function()
            showQuestion(lessonId, 1, {})
        end)
    end
end

showUnit = function(unitId: string)
    local unit = unitById[unitId] or IslamicStudies.Units[1]
    currentUnitId = unit.Id
    clearContent()

    local done = completedSet("lesson")
    local finished = 0

    for _, lesson in ipairs(unit.Lessons) do
        if done[lesson.Id] then
            finished += 1
        end
    end

    local list = contentList(0)
    autoLabel(list, unit.DisplayName, 24, Enum.Font.GothamBold, COLORS.Ink, 1)
    autoLabel(list, string.format("%s  ·  %d of %d complete", unit.Summary, finished, #unit.Lessons), 15, Enum.Font.GothamMedium, COLORS.SoftInk, 2)

    for index, lesson in ipairs(unit.Lessons) do
        local card = Instance.new("TextButton")
        card.AutoButtonColor = true
        card.BackgroundColor3 = COLORS.Parchment
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, 68)
        card.Text = ""
        card.LayoutOrder = 2 + index
        card.Parent = list
        corner(card, 10)

        local stroke = Instance.new("UIStroke")
        stroke.Color = if done[lesson.Id] then COLORS.Success else rgb(unit.AccentRGB)
        stroke.Thickness = 1.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = card

        local name = label(card, lesson.DisplayName, 17, Enum.Font.GothamBold, COLORS.Ink)
        name.Position = UDim2.fromOffset(14, 10)
        name.Size = UDim2.new(1, -130, 0, 22)
        name.TextTruncate = Enum.TextTruncate.AtEnd

        local blurb = label(card, lesson.Summary, 14, Enum.Font.Gotham, COLORS.SoftInk)
        blurb.Position = UDim2.fromOffset(14, 36)
        blurb.Size = UDim2.new(1, -130, 0, 22)
        blurb.TextTruncate = Enum.TextTruncate.AtEnd

        local status = label(card, if done[lesson.Id] then "Completed" else "Start", 15, Enum.Font.GothamBold, if done[lesson.Id] then COLORS.Success else rgb(unit.AccentRGB))
        status.AnchorPoint = Vector2.new(1, 0.5)
        status.Position = UDim2.new(1, -14, 0.5, 0)
        status.Size = UDim2.fromOffset(100, 22)
        status.TextXAlignment = Enum.TextXAlignment.Right
        status.TextYAlignment = Enum.TextYAlignment.Center

        card.Activated:Connect(function()
            showLesson(lesson.Id, 1)
        end)
    end

    refreshCurrentView = function()
        showUnit(unit.Id)
    end
end

showJournal = function()
    currentUnitId = nil
    clearContent()

    local list = contentList(0)
    autoLabel(list, "My Journal", 24, Enum.Font.GothamBold, COLORS.Ink, 1)

    if not snapshot then
        autoLabel(list, "Loading your progress...", 16, Enum.Font.GothamMedium, COLORS.SoftInk, 2)
        refreshCurrentView = showJournal
        return
    end

    local current = snapshot :: Snapshot
    local lessonsDone = #(current.Completed.lesson or {})
    local lessonsTotal = 0

    for _ in pairs(lessonById) do
        lessonsTotal += 1
    end

    local earnedCount = 0

    for _, badge in ipairs(current.Badges) do
        if badge.Earned then
            earnedCount += 1
        end
    end

    autoLabel(list, string.format(
        "Level %d  ·  %s  ·  %d XP total\nLessons passed: %d of %d   Stories: %d   Battles: %d   Trivia correct: %d\nBadges: %d of %d",
        current.Level,
        current.RankTitle,
        current.XP,
        lessonsDone,
        lessonsTotal,
        #(current.Completed.story or {}),
        #(current.Completed.battle or {}),
        current.Stats.TriviaCorrect or 0,
        earnedCount,
        #current.Badges
    ), 15, Enum.Font.GothamMedium, COLORS.SoftInk, 2)

    local grid = Instance.new("Frame")
    grid.BackgroundTransparency = 1
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.Size = UDim2.new(1, 0, 0, 0)
    grid.LayoutOrder = 3
    grid.Parent = list

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellPadding = UDim2.fromOffset(10, 10)
    gridLayout.CellSize = UDim2.new(0.5, -5, 0, 74)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = grid

    for index, badge in ipairs(current.Badges) do
        local tile = Instance.new("Frame")
        tile.BackgroundColor3 = if badge.Earned then COLORS.Gold else COLORS.Locked
        tile.BackgroundTransparency = if badge.Earned then 0 else 0.35
        tile.LayoutOrder = if badge.Earned then index else 1000 + index
        tile.Parent = grid
        corner(tile, 10)

        local name = label(tile, badge.DisplayName, 15, Enum.Font.GothamBold, if badge.Earned then COLORS.Ink else COLORS.SoftInk)
        name.Position = UDim2.fromOffset(10, 8)
        name.Size = UDim2.new(1, -20, 0, 20)
        name.TextTruncate = Enum.TextTruncate.AtEnd

        local description = label(tile, badge.Description, 13, Enum.Font.Gotham, COLORS.Ink)
        description.Position = UDim2.fromOffset(10, 30)
        description.Size = UDim2.new(1, -20, 0, 36)
    end

    refreshCurrentView = showJournal
end

local function buildSidebar()
    for index, unit in ipairs(IslamicStudies.Units) do
        local unitButton = button(sidebar, unit.DisplayName, rgb(unit.AccentRGB), function()
            showUnit(unit.Id)
        end)
        unitButton.Size = UDim2.new(1, -6, 0, 50)
        unitButton.LayoutOrder = index
        unitButton.TextSize = 15
    end

    local journalButton = button(sidebar, "My Journal", COLORS.Border, showJournal)
    journalButton.Size = UDim2.new(1, -6, 0, 50)
    journalButton.LayoutOrder = #IslamicStudies.Units + 1
    journalButton.TextSize = 15
end

buildSidebar()

local function openHall(unitId: string?)
    if player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true then
        return
    end

    for _, guiName in ipairs({ "MainMenu", "ShopMenu" }) do
        local gui = playerGui:FindFirstChild(guiName)
        local otherPanel = gui and gui:FindFirstChild("Panel")

        if otherPanel and otherPanel:IsA("GuiObject") then
            otherPanel.Visible = false
        end
    end

    showUnit(unitId or currentUnitId or IslamicStudies.Units[1].Id)
    panel.Visible = true
end

-- Opening the panel from elsewhere (the quick button toggles Visible) lands on a lesson list.
panel:GetPropertyChangedSignal("Visible"):Connect(function()
    if panel.Visible and #content:GetChildren() <= 1 then
        showUnit(currentUnitId or IslamicStudies.Units[1].Id)
    end
end)

openLearningHall.OnClientEvent:Connect(function(payload: any)
    local unitId = if type(payload) == "table" and type(payload.UnitId) == "string" then payload.UnitId else nil
    openHall(unitId)
end)

quizResult.OnClientEvent:Connect(function(result: any)
    if type(result) ~= "table" or result.LessonId ~= pendingLessonId then
        return
    end

    pendingLessonId = nil
    showResult(result)
end)

profileUpdated.OnClientEvent:Connect(function(payload: any)
    if type(payload) ~= "table" or type(payload.Level) ~= "number" then
        return
    end

    snapshot = payload
    subtitleLabel.Text = string.format("Level %d  ·  %s  ·  Learn, take the checkpoint quiz, and earn XP and badges.", payload.Level, tostring(payload.RankTitle))

    if panel.Visible and refreshCurrentView then
        refreshCurrentView()
    end
end)

local function closeIfBusy()
    if player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true then
        panel.Visible = false
    end
end

player:GetAttributeChangedSignal("InBattle"):Connect(closeIfBusy)
player:GetAttributeChangedSignal("InStory"):Connect(closeIfBusy)
