--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ContentIndex = require(Shared.Modules.ContentIndex)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local hubFolder = remotesFolder:WaitForChild("Hub")
local battleFolder = remotesFolder:WaitForChild("Battle")
local storyFolder = remotesFolder:WaitForChild("Story")
local mannersFolder = remotesFolder:WaitForChild("Manners")
local requestTeleport = hubFolder:WaitForChild("RequestTeleport") :: RemoteEvent
local requestJoinBattle = battleFolder:WaitForChild("RequestJoinBattle") :: RemoteEvent
local requestStartStory = storyFolder:WaitForChild("RequestStartStory") :: RemoteEvent
local requestMannersLesson = mannersFolder:WaitForChild("RequestLesson") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local content = ContentIndex.GetStartupPayload()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenu"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 14
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "MenuButton"
toggleButton.AnchorPoint = Vector2.new(0, 1)
toggleButton.Position = UDim2.new(0, 20, 1, -132)
toggleButton.Size = UDim2.fromOffset(136, 46)
toggleButton.AutoButtonColor = true
toggleButton.BackgroundColor3 = Color3.fromRGB(34, 44, 39)
toggleButton.Text = "Menu"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.fromRGB(247, 241, 221)
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(20, 20)
panel.Size = UDim2.fromOffset(760, 540)
panel.BackgroundColor3 = Color3.fromRGB(244, 235, 214)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(91, 76, 51)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(22, 18)
titleLabel.Size = UDim2.new(1, -44, 0, 34)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Path Menu"
titleLabel.TextColor3 = Color3.fromRGB(39, 36, 29)
titleLabel.TextSize = 26
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = panel

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Position = UDim2.fromOffset(22, 56)
subtitleLabel.Size = UDim2.new(1, -44, 0, 26)
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.Text = "Choose a battle, sahabi story, manners lesson, or travel destination."
subtitleLabel.TextColor3 = Color3.fromRGB(76, 67, 52)
subtitleLabel.TextSize = 15
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = panel

local categoryFrame = Instance.new("Frame")
categoryFrame.Position = UDim2.fromOffset(16, 98)
categoryFrame.Size = UDim2.fromOffset(172, 380)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = panel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.Padding = UDim.new(0, 10)
categoryLayout.Parent = categoryFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "Cards"
scrollingFrame.Position = UDim2.fromOffset(206, 96)
scrollingFrame.Size = UDim2.new(1, -226, 1, -154)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.CanvasSize = UDim2.zero
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.Parent = panel

local cardLayout = Instance.new("UIListLayout")
cardLayout.Padding = UDim.new(0, 12)
cardLayout.Parent = scrollingFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 22, 1, -42)
statusLabel.Size = UDim2.new(1, -44, 0, 26)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "Open a section and choose what to do next."
statusLabel.TextColor3 = Color3.fromRGB(64, 91, 69)
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

local selectedCategoryId = "start"
local categoryButtons = {}

local function getDestination(destinationId: string)
    for _, destination in ipairs(content.TravelRoute.Destinations) do
        if destination.Id == destinationId then
            return destination
        end
    end

    return nil
end

local function updateCanvas()
    scrollingFrame.CanvasSize = UDim2.fromOffset(0, cardLayout.AbsoluteContentSize.Y + 12)
end

local function clearCards()
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function createSectionHeader(text: string, subtitle: string?)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -12, 0, subtitle and 70 or 40)
    header.BackgroundTransparency = 1
    header.Parent = scrollingFrame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Font = Enum.Font.GothamBold
    title.Text = text
    title.TextColor3 = Color3.fromRGB(45, 41, 34)
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    if subtitle then
        local sub = Instance.new("TextLabel")
        sub.BackgroundTransparency = 1
        sub.Position = UDim2.fromOffset(0, 34)
        sub.Size = UDim2.new(1, 0, 0, 34)
        sub.Font = Enum.Font.Gotham
        sub.Text = subtitle
        sub.TextColor3 = Color3.fromRGB(82, 73, 58)
        sub.TextSize = 14
        sub.TextWrapped = true
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextYAlignment = Enum.TextYAlignment.Top
        sub.Parent = header
    end
end

local function createActionCard(title: string, subtitle: string, buttonText: string, accentColor: Color3, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -12, 0, 108)
    card.BackgroundColor3 = Color3.fromRGB(255, 250, 238)
    card.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.4
    stroke.Parent = card

    local titleText = Instance.new("TextLabel")
    titleText.BackgroundTransparency = 1
    titleText.Position = UDim2.fromOffset(16, 12)
    titleText.Size = UDim2.new(1, -140, 0, 24)
    titleText.Font = Enum.Font.GothamBold
    titleText.Text = title
    titleText.TextColor3 = Color3.fromRGB(39, 36, 29)
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = card

    local bodyText = Instance.new("TextLabel")
    bodyText.BackgroundTransparency = 1
    bodyText.Position = UDim2.fromOffset(16, 42)
    bodyText.Size = UDim2.new(1, -154, 0, 52)
    bodyText.Font = Enum.Font.Gotham
    bodyText.Text = subtitle
    bodyText.TextColor3 = Color3.fromRGB(81, 72, 58)
    bodyText.TextSize = 14
    bodyText.TextWrapped = true
    bodyText.TextXAlignment = Enum.TextXAlignment.Left
    bodyText.TextYAlignment = Enum.TextYAlignment.Top
    bodyText.Parent = card

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -14, 0.5, 0)
    button.Size = UDim2.fromOffset(112, 42)
    button.BackgroundColor3 = accentColor
    button.Font = Enum.Font.GothamBold
    button.Text = buttonText
    button.TextColor3 = Color3.fromRGB(250, 245, 232)
    button.TextSize = 16
    button.Parent = card

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 12)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(onClick)
end

local function teleport(destinationId: string, label: string)
    requestTeleport:FireServer(destinationId)
    statusLabel.Text = string.format("Teleport requested: %s", label)
    panel.Visible = false
end

local function queueBattle(scenario)
    requestJoinBattle:FireServer(scenario.Id)
    statusLabel.Text = string.format("Queue requested: %s", scenario.DisplayName)
    panel.Visible = false
end

local function startStory(story)
    requestStartStory:FireServer(story.Id)
    statusLabel.Text = string.format("Story requested: %s", story.DisplayName)
    panel.Visible = false
end

local function openMannersLesson(lesson)
    requestTeleport:FireServer("manners_court")
    requestMannersLesson:FireServer(lesson.Id)
    statusLabel.Text = string.format("Lesson opened: %s", lesson.DisplayName)
    panel.Visible = false
end

local function buildStart()
    createSectionHeader("Start Here", "Pick the main experience you want: battle, sahabi story, manners lesson, or the travel route between Makkah and Medina.")

    local desert = getDestination("journey_reflection")
    local medina = getDestination("medina_courtyard")
    local storyCourt = getDestination("story_court")
    local mannersCourt = getDestination("manners_court")

    if content.Battles[1] then
        createActionCard("Join Battle Of Badr", "Enter the Badr arena, fight in first person, then watch the reenactment at the end.", "Join", content.Battles[1].Teams[1].AccentColor, function()
            queueBattle(content.Battles[1])
        end)
    end

    if storyCourt then
        createActionCard("Learn A Sahabi", "Go to the story court and pick a sahabi playthrough with NPC scenes and guided objectives.", "Stories", storyCourt.AccentColor, function()
            teleport(storyCourt.Id, storyCourt.DisplayName)
        end)
    end

    if desert then
        createActionCard("Walk The Prophet's Footsteps", "Travel through the desert route between Makkah and Medina without depicting the Prophet directly.", "Travel", desert.AccentColor, function()
            teleport(desert.Id, desert.DisplayName)
        end)
    end

    if mannersCourt then
        createActionCard("Manners For Kids", "Learn adab like truthfulness, respect, mercy, keeping promises, and good speech.", "Learn", mannersCourt.AccentColor, function()
            teleport(mannersCourt.Id, mannersCourt.DisplayName)
        end)
    end

    if medina then
        createActionCard("Visit Medina", "Teleport to the Prophet's Mosque-inspired courtyard, gates, green dome area, and visitation route.", "Go", medina.AccentColor, function()
            teleport(medina.Id, medina.DisplayName)
        end)
    end
end

local function buildBattles()
    createSectionHeader("Battles", "Queue directly for Badr or Uhud. Players fight first, then watch a cleaner historical reenactment.")

    for _, battle in ipairs(content.Battles) do
        createActionCard(battle.DisplayName, battle.LearningGoal, "Queue", battle.Teams[1].AccentColor, function()
            queueBattle(battle)
        end)
    end
end

local function buildStories()
    createSectionHeader("Sahabi Learning", "Start a playable sahabi story route with NPC dialogue, objectives, and reflection moments.")

    for _, story in ipairs(content.Stories) do
        createActionCard(story.DisplayName, story.Summary, "Start", story.AccentColor, function()
            startStory(story)
        end)
    end
end

local function buildFootsteps()
    createSectionHeader("Walk The Prophet's Footsteps", "Travel the Makkah-to-Medina route respectfully. The route teaches the feeling of distance without depicting the Prophet.")

    for _, destinationId in ipairs({ "kaaba_courtyard", "journey_reflection", "medina_courtyard" }) do
        local destination = getDestination(destinationId)

        if destination then
            createActionCard(destination.DisplayName, destination.Description, "Go", destination.AccentColor, function()
                teleport(destination.Id, destination.DisplayName)
            end)
        end
    end
end

local function buildManners()
    createSectionHeader("Manners", "Short kid-friendly adab lessons. This is the first foundation for a bigger manners section later.")

    local mannersCourt = getDestination("manners_court")

    if mannersCourt then
        createActionCard("Go To Manners Court", mannersCourt.Description, "Go", mannersCourt.AccentColor, function()
            teleport(mannersCourt.Id, mannersCourt.DisplayName)
        end)
    end

    for _, lesson in ipairs(content.Manners) do
        createActionCard(lesson.DisplayName, lesson.Subtitle, "Learn", lesson.AccentColor, function()
            openMannersLesson(lesson)
        end)
    end
end

local function buildPlaces()
    createSectionHeader("Places", "Jump to any major place in the current prototype.")

    for _, destination in ipairs(content.TravelRoute.Destinations) do
        createActionCard(destination.DisplayName, destination.Description, "Go", destination.AccentColor, function()
            teleport(destination.Id, destination.DisplayName)
        end)
    end
end

local categoryDefinitions = {
    { Id = "start", Label = "Start", Build = buildStart },
    { Id = "battles", Label = "Battles", Build = buildBattles },
    { Id = "stories", Label = "Sahabi", Build = buildStories },
    { Id = "footsteps", Label = "Footsteps", Build = buildFootsteps },
    { Id = "manners", Label = "Manners", Build = buildManners },
    { Id = "places", Label = "Places", Build = buildPlaces },
}

local function rebuildCategory()
    clearCards()

    for _, category in ipairs(categoryDefinitions) do
        if category.Id == selectedCategoryId then
            category.Build()
            break
        end
    end

    for categoryId, button in pairs(categoryButtons) do
        button.BackgroundColor3 = (categoryId == selectedCategoryId) and Color3.fromRGB(67, 92, 70) or Color3.fromRGB(104, 91, 67)
    end

    updateCanvas()
end

for _, category in ipairs(categoryDefinitions) do
    local button = Instance.new("TextButton")
    button.Name = category.Id
    button.Size = UDim2.new(1, 0, 0, 44)
    button.BackgroundColor3 = Color3.fromRGB(104, 91, 67)
    button.Font = Enum.Font.GothamBold
    button.Text = category.Label
    button.TextColor3 = Color3.fromRGB(250, 245, 232)
    button.TextSize = 16
    button.Parent = categoryFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    categoryButtons[category.Id] = button

    button.MouseButton1Click:Connect(function()
        selectedCategoryId = category.Id
        rebuildCategory()
    end)
end

local function updateAvailability()
    local blocked = player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true

    toggleButton.Visible = not blocked

    if blocked then
        panel.Visible = false
    end
end

cardLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
toggleButton.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)
player:GetAttributeChangedSignal("InBattle"):Connect(updateAvailability)
player:GetAttributeChangedSignal("InStory"):Connect(updateAvailability)

rebuildCategory()
updateAvailability()
