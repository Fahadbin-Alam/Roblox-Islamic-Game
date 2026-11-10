--!nonstrict

-- Story mission HUD: the objective tracker, a waypoint to the current objective, cited
-- narration cards, the opponent captain's health bar, and the results screen with stars and
-- the after-battle reflection questions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local battleFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Battle")
local missionUpdate = battleFolder:WaitForChild("MissionUpdate") :: RemoteEvent
local missionResult = battleFolder:WaitForChild("MissionResult") :: RemoteEvent
local submitReflection = battleFolder:WaitForChild("SubmitReflection") :: RemoteEvent
local reflectionResult = battleFolder:WaitForChild("ReflectionResult") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD = Color3.fromRGB(226, 192, 112)
local CREAM = Color3.fromRGB(247, 242, 226)
local MUTED = Color3.fromRGB(205, 196, 172)
local PANEL = Color3.fromRGB(28, 33, 29)
local GREEN = Color3.fromRGB(86, 168, 104)
local RED = Color3.fromRGB(206, 92, 74)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionHud"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 30
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function corner(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
end

local function label(parent: Instance, name: string, text: string, font: Enum.Font, size: number, color: Color3, position: UDim2, frameSize: UDim2): TextLabel
    local l = Instance.new("TextLabel")
    l.Name = name
    l.BackgroundTransparency = 1
    l.Font = font
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.Position = position
    l.Size = frameSize
    l.Parent = parent

    return l
end

local function bar(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3): (Frame, Frame)
    local track = Instance.new("Frame")
    track.Name = name
    track.BackgroundColor3 = Color3.fromRGB(14, 16, 14)
    track.BorderSizePixel = 0
    track.Position = position
    track.Size = size
    track.Parent = parent
    corner(track, 5)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(0, 1)
    fill.Parent = track
    corner(fill, 5)

    return track, fill
end

-- Objective tracker -----------------------------------------------------------------------

local tracker = Instance.new("Frame")
tracker.Name = "Tracker"
tracker.Position = UDim2.fromOffset(18, 70)
tracker.Size = UDim2.fromOffset(360, 196)
tracker.BackgroundColor3 = PANEL
tracker.BackgroundTransparency = 0.12
tracker.Visible = false
tracker.Parent = screenGui
corner(tracker, 14)
stroke(tracker, GOLD, 1.5, 0.25)

local missionLabel = label(tracker, "Mission", "", Enum.Font.GothamBold, 13, GOLD, UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 16))
local stepLabel = label(tracker, "Step", "", Enum.Font.Gotham, 12, MUTED, UDim2.fromOffset(14, 26), UDim2.new(1, -28, 0, 14))
local titleLabel = label(tracker, "Title", "", Enum.Font.GothamBlack, 20, CREAM, UDim2.fromOffset(14, 44), UDim2.new(1, -28, 0, 24))
local instructionLabel = label(tracker, "Instruction", "", Enum.Font.Gotham, 14, MUTED, UDim2.fromOffset(14, 70), UDim2.new(1, -28, 0, 40))
local progressTrack, progressFill = bar(tracker, "Progress", UDim2.fromOffset(14, 116), UDim2.new(1, -28, 0, 10), GOLD)
local progressLabel = label(tracker, "ProgressText", "", Enum.Font.GothamBold, 13, CREAM, UDim2.fromOffset(14, 130), UDim2.new(1, -28, 0, 16))
local infoLabel = label(tracker, "Info", "", Enum.Font.Gotham, 12, MUTED, UDim2.fromOffset(14, 150), UDim2.new(1, -28, 0, 16))
local orderLabel = label(tracker, "Order", "", Enum.Font.GothamBold, 12, GREEN, UDim2.fromOffset(14, 168), UDim2.new(1, -28, 0, 16))

-- Captain health bar --------------------------------------------------------------------

local bossFrame = Instance.new("Frame")
bossFrame.Name = "Boss"
bossFrame.AnchorPoint = Vector2.new(0.5, 0)
bossFrame.Position = UDim2.new(0.5, 0, 0, 86)
bossFrame.Size = UDim2.fromOffset(420, 46)
bossFrame.BackgroundColor3 = Color3.fromRGB(40, 24, 22)
bossFrame.BackgroundTransparency = 0.15
bossFrame.Visible = false
bossFrame.Parent = screenGui
corner(bossFrame, 10)
stroke(bossFrame, Color3.fromRGB(196, 120, 92), 1.5, 0.2)
local bossName = label(bossFrame, "Name", "", Enum.Font.GothamBold, 14, CREAM, UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 16))
bossName.TextXAlignment = Enum.TextXAlignment.Center
local _, bossFill = bar(bossFrame, "Health", UDim2.fromOffset(12, 26), UDim2.new(1, -24, 0, 12), RED)

-- Narration card ------------------------------------------------------------------------

local narration = Instance.new("Frame")
narration.Name = "Narration"
narration.AnchorPoint = Vector2.new(0.5, 1)
narration.Position = UDim2.new(0.5, 0, 1, -110)
narration.Size = UDim2.fromOffset(640, 130)
narration.BackgroundColor3 = Color3.fromRGB(34, 30, 24)
narration.BackgroundTransparency = 0.08
narration.Visible = false
narration.Parent = screenGui
corner(narration, 14)
stroke(narration, GOLD, 1.5, 0.15)

local narrationKicker = label(narration, "Kicker", "", Enum.Font.GothamBold, 12, GOLD, UDim2.fromOffset(18, 12), UDim2.new(1, -36, 0, 14))
local narrationTitle = label(narration, "Title", "", Enum.Font.GothamBlack, 20, CREAM, UDim2.fromOffset(18, 28), UDim2.new(1, -36, 0, 24))
local narrationBody = label(narration, "Body", "", Enum.Font.Gotham, 15, Color3.fromRGB(232, 226, 210), UDim2.fromOffset(18, 54), UDim2.new(1, -36, 0, 50))
local narrationReference = label(narration, "Reference", "", Enum.Font.GothamBold, 12, Color3.fromRGB(176, 214, 180), UDim2.new(0, 18, 1, -24), UDim2.new(1, -36, 0, 14))

-- Center banner and toasts ----------------------------------------------------------------

local banner = label(screenGui, "Banner", "", Enum.Font.GothamBlack, 30, CREAM, UDim2.new(0.5, -320, 0.32, 0), UDim2.fromOffset(640, 44))
banner.TextXAlignment = Enum.TextXAlignment.Center
banner.TextStrokeTransparency = 0.4
banner.Visible = false

local toastLabel = label(screenGui, "Toast", "", Enum.Font.GothamBold, 16, CREAM, UDim2.new(0.5, -260, 0, 140), UDim2.fromOffset(520, 34))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.TextYAlignment = Enum.TextYAlignment.Center
toastLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 32)
toastLabel.BackgroundTransparency = 0.2
toastLabel.Visible = false
corner(toastLabel, 10)

-- Waypoint ---------------------------------------------------------------------------------

local waypointPart = Instance.new("Part")
waypointPart.Name = "MissionWaypoint"
waypointPart.Anchored = true
waypointPart.CanCollide = false
waypointPart.CanQuery = false
waypointPart.CanTouch = false
waypointPart.Transparency = 1
waypointPart.Size = Vector3.new(1, 1, 1)

local waypoint = Instance.new("BillboardGui")
waypoint.Name = "MissionWaypoint"
waypoint.AlwaysOnTop = true
waypoint.Size = UDim2.fromOffset(150, 46)
waypoint.LightInfluence = 0
waypoint.Adornee = waypointPart
waypoint.Enabled = false
waypoint.Parent = screenGui

local waypointLabel = label(waypoint, "Text", "", Enum.Font.GothamBold, 14, GOLD, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
waypointLabel.TextXAlignment = Enum.TextXAlignment.Center
waypointLabel.TextYAlignment = Enum.TextYAlignment.Center
waypointLabel.TextStrokeTransparency = 0.3

local waypointPosition: Vector3? = nil
local waypointKind = ""

local function setWaypoint(position: Vector3?, kind: string)
    waypointPosition = position
    waypointKind = kind

    if position then
        waypointPart.Position = position + Vector3.new(0, 7, 0)
        waypointPart.Parent = Workspace
        waypoint.Enabled = true
    else
        waypoint.Enabled = false
        waypointPart.Parent = nil
    end
end

RunService.RenderStepped:Connect(function()
    if not waypointPosition then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root and root:IsA("BasePart") then
        local distance = math.floor((root.Position - waypointPosition).Magnitude)
        waypointLabel.Text = string.format("%s\n%d studs", waypointKind, distance)
    end
end)

-- Behaviour ------------------------------------------------------------------------------

local toastToken = 0
local bannerToken = 0
local narrationToken = 0

local function showToast(text: string)
    toastToken += 1
    local token = toastToken
    toastLabel.Text = text
    toastLabel.Visible = true

    task.delay(3.2, function()
        if token == toastToken then
            toastLabel.Visible = false
        end
    end)
end

local function showBanner(text: string, color: Color3)
    bannerToken += 1
    local token = bannerToken
    banner.Text = text
    banner.TextColor3 = color
    banner.TextTransparency = 1
    banner.Visible = true
    TweenService:Create(banner, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

    task.delay(2.6, function()
        if token == bannerToken then
            TweenService:Create(banner, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
            task.wait(0.45)

            if token == bannerToken then
                banner.Visible = false
            end
        end
    end)
end

local function showNarration(payload)
    narrationToken += 1
    local token = narrationToken
    narrationKicker.Text = string.upper(payload.ObjectiveTitle or "")
    narrationTitle.Text = payload.Title or ""
    narrationBody.Text = payload.Body or ""
    narrationReference.Text = payload.Reference and ("Source: " .. payload.Reference) or ""
    narration.BackgroundTransparency = 1
    narration.Visible = true
    TweenService:Create(narration, TweenInfo.new(0.35), { BackgroundTransparency = 0.08 }):Play()

    -- Longer passages stay up longer.
    local readSeconds = math.clamp(#(payload.Body or "") / 18, 7, 13)

    task.delay(readSeconds, function()
        if token == narrationToken then
            narration.Visible = false
        end
    end)
end

local TYPE_LABELS = {
    Reach = "Go to the marker",
    Hold = "Hold the ring",
    Defend = "Protect the banner",
    Defeat = "Drive them back",
    Discipline = "Keep your post",
    Narration = "Listen",
}

local function formatTime(seconds: number): string
    seconds = math.max(0, math.floor(seconds))
    return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function applyState(state)
    tracker.Visible = true
    missionLabel.Text = string.format("%s  ·  %s", state.Mission or "", state.Subtitle or "")
    stepLabel.Text = string.format("Objective %d of %d  ·  %s", state.Index or 0, state.Count or 0, TYPE_LABELS[state.Type] or "")
    titleLabel.Text = state.Title or ""
    instructionLabel.Text = state.Instruction or ""

    if state.Progress then
        progressTrack.Visible = true
        progressFill.Size = UDim2.fromScale(math.clamp(state.Progress, 0, 1), 1)
        progressFill.BackgroundColor3 = state.Contested and RED or (state.Type == "Defend" and GREEN or GOLD)
    else
        progressTrack.Visible = false
    end

    progressLabel.Text = state.ProgressText or ""
    progressLabel.TextColor3 = state.Contested and RED or CREAM

    local remaining = (state.TimeLimit or 0) - (state.Elapsed or 0)
    infoLabel.Text = string.format("Opponents %d  ·  Allies %d  ·  Falls %d  ·  Time %s", state.EnemiesLeft or 0, state.AlliesLeft or 0, state.Falls or 0, formatTime(remaining))

    if state.OrderKept == nil then
        orderLabel.Text = ""
    elseif state.OrderKept then
        orderLabel.Text = "The order is being kept."
        orderLabel.TextColor3 = GREEN
    else
        orderLabel.Text = "The order was broken. Expect a harder fight."
        orderLabel.TextColor3 = RED
    end

    if state.Boss then
        bossFrame.Visible = true
        bossName.Text = state.Boss.Name
        bossFill.Size = UDim2.fromScale(math.clamp(state.Boss.Health, 0, 1), 1)
    else
        bossFrame.Visible = false
    end

    if state.ZonePosition then
        setWaypoint(state.ZonePosition, state.Title or "Objective")
    elseif state.TargetPosition then
        setWaypoint(state.TargetPosition, "Banner")
    else
        setWaypoint(nil, "")
    end
end

local function clearHud()
    tracker.Visible = false
    bossFrame.Visible = false
    narration.Visible = false
    setWaypoint(nil, "")
end

missionUpdate.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.Kind == "State" then
        applyState(payload)
    elseif payload.Kind == "Narration" then
        showNarration(payload)
    elseif payload.Kind == "Toast" then
        showToast(payload.Text or "")
    elseif payload.Kind == "ObjectiveComplete" then
        showBanner("Objective complete: " .. (payload.Title or ""), GOLD)
    elseif payload.Kind == "Clear" then
        clearHud()
    end
end)

player:GetAttributeChangedSignal("InBattle"):Connect(function()
    if player:GetAttribute("InBattle") ~= true then
        clearHud()
    end
end)

-- Results and reflection -------------------------------------------------------------------

local results = Instance.new("Frame")
results.Name = "Results"
results.AnchorPoint = Vector2.new(0.5, 0.5)
results.Position = UDim2.fromScale(0.5, 0.5)
results.Size = UDim2.fromOffset(620, 520)
results.BackgroundColor3 = Color3.fromRGB(30, 34, 30)
results.Visible = false
results.Parent = screenGui
corner(results, 18)
stroke(results, GOLD, 2, 0.1)

local resultsTitle = label(results, "Title", "", Enum.Font.GothamBlack, 26, CREAM, UDim2.fromOffset(24, 18), UDim2.new(1, -48, 0, 32))
local resultsReason = label(results, "Reason", "", Enum.Font.Gotham, 14, MUTED, UDim2.fromOffset(24, 52), UDim2.new(1, -48, 0, 18))
local starsLabel = label(results, "Stars", "", Enum.Font.GothamBlack, 34, GOLD, UDim2.fromOffset(24, 76), UDim2.new(1, -48, 0, 40))
local starDetails = label(results, "StarDetails", "", Enum.Font.Gotham, 14, CREAM, UDim2.fromOffset(24, 118), UDim2.new(1, -48, 0, 64))
local statsLabel = label(results, "Stats", "", Enum.Font.GothamBold, 13, MUTED, UDim2.fromOffset(24, 186), UDim2.new(1, -48, 0, 18))

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Position = UDim2.fromOffset(24, 212)
body.Size = UDim2.new(1, -48, 1, -276)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 6
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.new()
body.Parent = results

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 8)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = body

local function makeButton(parent: Instance, text: string, color: Color3): TextButton
    local button = Instance.new("TextButton")
    button.AutoButtonColor = true
    button.BackgroundColor3 = color
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextSize = 15
    button.TextColor3 = CREAM
    button.TextWrapped = true
    button.Parent = parent
    corner(button, 10)

    return button
end

local submitButton = makeButton(results, "Submit Reflection", Color3.fromRGB(70, 118, 82))
submitButton.AnchorPoint = Vector2.new(0, 1)
submitButton.Position = UDim2.new(0, 24, 1, -16)
submitButton.Size = UDim2.fromOffset(250, 44)

local closeButton = makeButton(results, "Close", Color3.fromRGB(96, 84, 64))
closeButton.AnchorPoint = Vector2.new(1, 1)
closeButton.Position = UDim2.new(1, -24, 1, -16)
closeButton.Size = UDim2.fromOffset(150, 44)

local currentResult = nil
local answers = {}
local questionWidgets = {}

local function clearBody()
    for _, child in ipairs(body:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    table.clear(questionWidgets)
end

local function bodyText(text: string, font: Enum.Font, size: number, color: Color3, order: number): TextLabel
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = font
    l.TextSize = size
    l.TextColor3 = color
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Size = UDim2.new(1, -10, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.LayoutOrder = order
    l.Parent = body

    return l
end

local function refreshChoices(questionIndex: number)
    local widget = questionWidgets[questionIndex]

    for choiceIndex, button in ipairs(widget.Buttons) do
        button.BackgroundColor3 = answers[questionIndex] == choiceIndex and Color3.fromRGB(150, 122, 62) or Color3.fromRGB(58, 64, 56)
    end
end

local function buildReflection(questions)
    local order = 10
    bodyText("Reflect on the battle", Enum.Font.GothamBlack, 18, GOLD, order)

    for questionIndex, question in ipairs(questions) do
        order += 1
        bodyText(string.format("%d. %s", questionIndex, question.Prompt), Enum.Font.GothamBold, 15, CREAM, order)

        local widget = { Buttons = {} }

        for choiceIndex, choice in ipairs(question.Choices) do
            order += 1
            local button = makeButton(body, choice, Color3.fromRGB(58, 64, 56))
            button.Size = UDim2.new(1, -10, 0, 36)
            button.TextSize = 14
            button.LayoutOrder = order
            button.Activated:Connect(function()
                if submitButton.Active then
                    answers[questionIndex] = choiceIndex
                    refreshChoices(questionIndex)
                end
            end)
            table.insert(widget.Buttons, button)
        end

        questionWidgets[questionIndex] = widget
    end
end

missionResult.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    currentResult = payload
    table.clear(answers)
    clearBody()

    resultsTitle.Text = payload.Completed and (payload.MissionName .. " complete") or (payload.MissionName .. ": try again")
    resultsTitle.TextColor3 = payload.Completed and CREAM or Color3.fromRGB(240, 196, 170)
    resultsReason.Text = payload.Reason or ""
    starsLabel.Text = string.rep("★", payload.Stars or 0) .. string.rep("☆", 3 - (payload.Stars or 0))

    local lines = {}

    for _, detail in ipairs(payload.StarDetails or {}) do
        table.insert(lines, string.format("%s  %s", detail.Earned and "✓" or "✗", detail.Label))
    end

    if (payload.StarBonus or 0) > 0 then
        table.insert(lines, string.format("+%d XP for new stars", payload.StarBonus))
    end

    starDetails.Text = table.concat(lines, "\n")
    statsLabel.Text = string.format("Objectives %d / %d  ·  Opponents you drove back %d  ·  Your falls %d", payload.ObjectivesDone or 0, payload.ObjectiveCount or 0, payload.Defeated or 0, payload.Falls or 0)

    if payload.LessonTitle then
        bodyText(payload.LessonTitle, Enum.Font.GothamBlack, 18, GOLD, 1)
        bodyText(table.concat(payload.LessonLines or {}, "\n\n"), Enum.Font.Gotham, 14, Color3.fromRGB(226, 220, 204), 2)
    end

    local questions = payload.Reflection or {}

    if #questions > 0 then
        buildReflection(questions)
        submitButton.Visible = true
        submitButton.Active = true
        submitButton.Text = "Submit Reflection"
    else
        submitButton.Visible = false
    end

    results.Visible = true
end)

submitButton.Activated:Connect(function()
    if not currentResult or not submitButton.Active then
        return
    end

    local questions = currentResult.Reflection or {}

    for index = 1, #questions do
        if not answers[index] then
            submitButton.Text = "Answer every question first"
            task.delay(1.6, function()
                if submitButton.Active then
                    submitButton.Text = "Submit Reflection"
                end
            end)
            return
        end
    end

    submitButton.Active = false
    submitButton.Text = "Checking..."
    submitReflection:FireServer(currentResult.ScenarioId, answers)
end)

reflectionResult.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" or not currentResult or payload.ScenarioId ~= currentResult.ScenarioId then
        return
    end

    for index, result in ipairs(payload.Results or {}) do
        local widget = questionWidgets[index]

        if widget then
            for choiceIndex, button in ipairs(widget.Buttons) do
                if choiceIndex == result.Answer then
                    button.BackgroundColor3 = Color3.fromRGB(64, 132, 82)
                elseif choiceIndex == answers[index] then
                    button.BackgroundColor3 = Color3.fromRGB(150, 70, 58)
                end
            end
        end

        bodyText(string.format("%d. %s", index, result.Explanation or ""), Enum.Font.Gotham, 13, result.Correct and Color3.fromRGB(176, 220, 184) or Color3.fromRGB(240, 196, 170), 100 + index)
    end

    submitButton.Text = string.format("%d / %d correct  ·  +%d XP", payload.Correct or 0, payload.Total or 0, payload.XPAwarded or 0)
end)

closeButton.Activated:Connect(function()
    results.Visible = false
    currentResult = nil
end)
