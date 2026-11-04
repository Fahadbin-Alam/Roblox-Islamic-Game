--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MENU_ITEMS = {
    {
        Label = "Battle of Badr",
        Detail = "Join the Badr battle route and watch the lesson briefing.",
        Accent = Color3.fromRGB(118, 91, 54),
        Action = "battle",
        Id = "badr",
    },
    {
        Label = "Battle of Uhud",
        Detail = "Join the Uhud route with the mountain pass and archer ridge lesson.",
        Accent = Color3.fromRGB(92, 77, 59),
        Action = "battle",
        Id = "uhud",
    },
    {
        Label = "Learn About Sahabis",
        Detail = "Open the sahabi story menu and choose who to learn about.",
        Accent = Color3.fromRGB(73, 96, 77),
        Action = "sahabi_menu",
    },
    {
        Label = "Manners Lessons",
        Detail = "Open the manners lessons menu.",
        Accent = Color3.fromRGB(98, 119, 76),
        Action = "manners_menu",
    },
    {
        Label = "Trivia Challenge",
        Detail = "Start Islamic trivia with the server.",
        Accent = Color3.fromRGB(63, 98, 88),
        Action = "trivia",
    },
    {
        Label = "Travel To Medina",
        Detail = "Travel to the Medina courtyard.",
        Accent = Color3.fromRGB(69, 121, 77),
        Action = "travel",
        Id = "medina_courtyard",
    },
}

local SAHABI_ITEMS = {
    {
        Label = "Abu Bakr as-Siddiq (RA)",
        Detail = "His title, early support, Hijrah companionship, and first caliph leadership.",
        Accent = Color3.fromRGB(124, 108, 67),
        Id = "abu_bakr_as_siddiq",
    },
}

local MANNERS_ITEMS = {
    {
        Label = "Truthfulness",
        Detail = "Say what is true and be someone others can trust.",
        Accent = Color3.fromRGB(91, 125, 83),
        Id = "truthfulness",
    },
    {
        Label = "Respect",
        Detail = "Speak gently and treat family and elders with care.",
        Accent = Color3.fromRGB(123, 101, 70),
        Id = "respect",
    },
    {
        Label = "Mercy And Kindness",
        Detail = "Be gentle with people, animals, and anyone who needs help.",
        Accent = Color3.fromRGB(82, 127, 111),
        Id = "mercy",
    },
    {
        Label = "Keeping Promises",
        Detail = "Follow through when you say you will do something good.",
        Accent = Color3.fromRGB(89, 92, 125),
        Id = "keeping_promises",
    },
    {
        Label = "Good Speech",
        Detail = "Use words that are clean, calm, and useful.",
        Accent = Color3.fromRGB(125, 91, 83),
        Id = "good_speech",
    },
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenu"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(56, 76)
panel.Size = UDim2.fromOffset(800, 540)
panel.BackgroundColor3 = Color3.fromRGB(244, 235, 214)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 10
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(91, 76, 51)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(24, 18)
titleLabel.Size = UDim2.new(1, -96, 0, 34)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Path Menu"
titleLabel.TextColor3 = Color3.fromRGB(39, 36, 29)
titleLabel.TextSize = 26
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 11
titleLabel.Parent = panel

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Position = UDim2.fromOffset(24, 56)
subtitleLabel.Size = UDim2.new(1, -48, 0, 26)
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.Text = "Choose a battle, sahabi story, manners lesson, trivia, or Medina travel."
subtitleLabel.TextColor3 = Color3.fromRGB(76, 67, 52)
subtitleLabel.TextSize = 15
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.ZIndex = 11
subtitleLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -18, 0, 16)
closeButton.Size = UDim2.fromOffset(48, 40)
closeButton.Active = true
closeButton.AutoButtonColor = true
closeButton.BackgroundColor3 = Color3.fromRGB(91, 76, 51)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Selectable = true
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(250, 245, 232)
closeButton.TextSize = 18
closeButton.ZIndex = 100
closeButton.Parent = panel

pcall(function()
    closeButton.Modal = true
end)

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local sectionTitle = Instance.new("TextLabel")
sectionTitle.Name = "SectionTitle"
sectionTitle.BackgroundTransparency = 1
sectionTitle.Position = UDim2.fromOffset(24, 96)
sectionTitle.Size = UDim2.new(1, -48, 0, 30)
sectionTitle.Font = Enum.Font.GothamBold
sectionTitle.Text = "Choose What To Do"
sectionTitle.TextColor3 = Color3.fromRGB(45, 41, 34)
sectionTitle.TextSize = 22
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.ZIndex = 11
sectionTitle.Parent = panel

local sectionSubtitle = Instance.new("TextLabel")
sectionSubtitle.Name = "SectionSubtitle"
sectionSubtitle.BackgroundTransparency = 1
sectionSubtitle.Position = UDim2.fromOffset(24, 130)
sectionSubtitle.Size = UDim2.new(1, -48, 0, 28)
sectionSubtitle.Font = Enum.Font.Gotham
sectionSubtitle.Text = "Click a large button below. The menu closes after you join or travel."
sectionSubtitle.TextColor3 = Color3.fromRGB(82, 73, 58)
sectionSubtitle.TextSize = 14
sectionSubtitle.TextWrapped = true
sectionSubtitle.TextXAlignment = Enum.TextXAlignment.Left
sectionSubtitle.ZIndex = 11
sectionSubtitle.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 24, 1, -42)
statusLabel.Size = UDim2.new(1, -48, 0, 28)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = "Pick where you want to go."
statusLabel.TextColor3 = Color3.fromRGB(64, 91, 69)
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.ZIndex = 11
statusLabel.Parent = panel

local currentButtons = {}

local function clearButtons()
    for _, button in ipairs(currentButtons) do
        button:Destroy()
    end

    table.clear(currentButtons)
end

local function connectButton(button, callback)
    local lastClickAt = 0

    local function run()
        local now = os.clock()

        if now - lastClickAt < 0.12 then
            return
        end

        lastClickAt = now
        callback()
    end

    button.Activated:Connect(run)
    button.MouseButton1Click:Connect(run)

    pcall(function()
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                run()
            end
        end)
    end)
end

local function getRemote(folderName, remoteName)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)

    if not remotes then
        return nil
    end

    local folder = remotes:FindFirstChild(folderName) or remotes:WaitForChild(folderName, 5)

    if not folder then
        return nil
    end

    local remote = folder:FindFirstChild(remoteName) or folder:WaitForChild(remoteName, 5)

    if remote and remote:IsA("RemoteEvent") then
        return remote
    end

    return nil
end

local function fireRemote(folderName, remoteName, ...)
    local remote = getRemote(folderName, remoteName)

    if not remote then
        statusLabel.Text = "That system is still loading. Try again in a second."
        return false
    end

    remote:FireServer(...)
    return true
end

local function closeMenu()
    panel.Visible = false
end

local function lockMessage()
    if player:GetAttribute("InBattle") == true then
        return "Finish the current battle before starting another menu activity."
    end

    if player:GetAttribute("InStory") == true then
        return "Finish the current sahabi story before starting another menu activity."
    end

    return nil
end

local function canUseMenu()
    local message = lockMessage()

    if message then
        statusLabel.Text = message
        return false
    end

    return true
end

local function joinBattle(scenarioId, label)
    if canUseMenu() and fireRemote("Battle", "RequestJoinBattle", scenarioId) then
        statusLabel.Text = "Joining: " .. label
        closeMenu()
    end
end

local function startStory(storyId, label)
    if canUseMenu() and fireRemote("Story", "RequestStartStory", storyId) then
        statusLabel.Text = "Opening story: " .. label
        closeMenu()
    end
end

local function startMannersLesson(lessonId, label)
    if not canUseMenu() then
        return
    end

    fireRemote("Hub", "RequestTeleport", "manners_court")

    if fireRemote("Manners", "RequestLesson", lessonId) then
        statusLabel.Text = "Opening lesson: " .. label
        closeMenu()
    end
end

local function startTrivia()
    if not canUseMenu() then
        return
    end

    fireRemote("Hub", "RequestTeleport", "trivia_court")

    if fireRemote("Trivia", "RequestStartTrivia") then
        statusLabel.Text = "Starting trivia."
        closeMenu()
    end
end

local function travelToMedina()
    if canUseMenu() and fireRemote("Hub", "RequestTeleport", "medina_courtyard") then
        statusLabel.Text = "Traveling to Medina."
        closeMenu()
    end
end

local function addMenuButton(index, item, callback)
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    local button = Instance.new("TextButton")
    button.Name = item.Label:gsub("%W+", "")
    button.Position = UDim2.fromOffset(24 + (column * 378), 174 + (row * 98))
    button.Size = UDim2.fromOffset(350, 82)
    button.Active = true
    button.AutoButtonColor = true
    button.BackgroundColor3 = Color3.fromRGB(255, 250, 238)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.Gotham
    button.Text = ""
    button.ZIndex = 12
    button.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = item.Accent
    stroke.Thickness = 1.6
    stroke.Parent = button

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 10)
    title.Size = UDim2.new(1, -28, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.Text = item.Label
    title.TextColor3 = Color3.fromRGB(39, 36, 29)
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 13
    title.Parent = button

    local detail = Instance.new("TextLabel")
    detail.BackgroundTransparency = 1
    detail.Position = UDim2.fromOffset(14, 38)
    detail.Size = UDim2.new(1, -28, 0, 34)
    detail.Font = Enum.Font.Gotham
    detail.Text = item.Detail
    detail.TextColor3 = Color3.fromRGB(81, 72, 58)
    detail.TextSize = 13
    detail.TextWrapped = true
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextYAlignment = Enum.TextYAlignment.Top
    detail.ZIndex = 13
    detail.Parent = button

    table.insert(currentButtons, button)
    connectButton(button, callback)

    return button
end

local showSahabiMenu: () -> ()
local showMannersMenu: () -> ()

local function showHome()
    clearButtons()
    sectionTitle.Text = "Choose What To Do"
    sectionSubtitle.Text = "Click a large button below. The menu closes after you join or travel."

    for index, item in ipairs(MENU_ITEMS) do
        addMenuButton(index, item, function()
            if item.Action == "battle" then
                joinBattle(item.Id, item.Label)
            elseif item.Action == "sahabi_menu" then
                showSahabiMenu()
            elseif item.Action == "manners_menu" then
                showMannersMenu()
            elseif item.Action == "trivia" then
                startTrivia()
            elseif item.Action == "travel" then
                travelToMedina()
            end
        end)
    end
end

showSahabiMenu = function()
    clearButtons()
    sectionTitle.Text = "Learn About Sahabis"
    sectionSubtitle.Text = "Choose a sahabi story route. More companions can be added here."

    addMenuButton(1, {
        Label = "Back To Main Menu",
        Detail = "Return to battles, manners, trivia, and Medina travel.",
        Accent = Color3.fromRGB(104, 91, 67),
    }, showHome)

    for index, item in ipairs(SAHABI_ITEMS) do
        addMenuButton(index + 1, item, function()
            startStory(item.Id, item.Label)
        end)
    end
end

showMannersMenu = function()
    clearButtons()
    sectionTitle.Text = "Manners Lessons"
    sectionSubtitle.Text = "Choose a manners lesson. The menu closes after the lesson opens."

    addMenuButton(1, {
        Label = "Back To Main Menu",
        Detail = "Return to battles, sahabis, trivia, and Medina travel.",
        Accent = Color3.fromRGB(104, 91, 67),
    }, showHome)

    for index, item in ipairs(MANNERS_ITEMS) do
        addMenuButton(index + 1, item, function()
            startMannersLesson(item.Id, item.Label)
        end)
    end
end

local function pointInside(guiObject, point)
    local position = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize

    return point.X >= position.X
        and point.X <= position.X + size.X
        and point.Y >= position.Y
        and point.Y <= position.Y + size.Y
end

connectButton(closeButton, closeMenu)
UserInputService.InputBegan:Connect(function(input)
    if not panel.Visible then
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape then
        closeMenu()
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if pointInside(closeButton, input.Position) then
            closeMenu()
        end
    end
end)

player:GetAttributeChangedSignal("InBattle"):Connect(function()
    if player:GetAttribute("InBattle") == true then
        closeMenu()
    end
end)

player:GetAttributeChangedSignal("InStory"):Connect(function()
    if player:GetAttribute("InStory") == true then
        closeMenu()
    end
end)

showHome()
