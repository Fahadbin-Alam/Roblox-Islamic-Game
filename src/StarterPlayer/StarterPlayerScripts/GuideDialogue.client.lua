--!strict

-- Dialogue box for the hub's guide teachers. The guide greets the player, names their next
-- quest from the suggested path, and offers to take them there.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Guides = require(Shared.Data.Guides)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestTeleport = remotes:WaitForChild("Hub"):WaitForChild("RequestTeleport") :: RemoteEvent
local profileUpdated = remotes:WaitForChild("Progress"):WaitForChild("ProfileUpdated") :: RemoteEvent
local requestProfile = remotes:WaitForChild("Progress"):WaitForChild("RequestProfile") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
    Panel = Color3.fromRGB(250, 244, 230),
    Border = Color3.fromRGB(193, 162, 86),
    Ink = Color3.fromRGB(46, 38, 28),
    Muted = Color3.fromRGB(110, 94, 70),
    Accent = Color3.fromRGB(63, 98, 88),
    Quiet = Color3.fromRGB(206, 194, 168),
    White = Color3.fromRGB(250, 246, 234),
}

local guideById: { [string]: Guides.Guide } = {}

for _, guide in ipairs(Guides) do
    guideById[guide.Id] = guide
end

local snapshot: any = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GuideDialogue"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 95
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -24)
panel.Size = UDim2.new(0.92, 0, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = COLORS.Panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(620, math.huge)
sizeLimit.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.Border
stroke.Thickness = 2
stroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 18)
padding.PaddingRight = UDim.new(0, 18)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function textLine(order: number, size: number, font: Enum.Font, color: Color3): TextLabel
    local line = Instance.new("TextLabel")
    line.BackgroundTransparency = 1
    line.Size = UDim2.new(1, 0, 0, 0)
    line.AutomaticSize = Enum.AutomaticSize.Y
    line.Font = font
    line.TextColor3 = color
    line.TextSize = size
    line.TextWrapped = true
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.LayoutOrder = order
    line.Text = ""
    line.Parent = panel

    return line
end

local nameLabel = textLine(1, 18, Enum.Font.GothamBold, COLORS.Accent)
local greetingLabel = textLine(2, 16, Enum.Font.GothamMedium, COLORS.Ink)
local questLabel = textLine(3, 16, Enum.Font.GothamBold, COLORS.Ink)
local hintLabel = textLine(4, 14, Enum.Font.Gotham, COLORS.Muted)
local sayingLabel = textLine(5, 14, Enum.Font.GothamMedium, COLORS.Muted)

local buttonRow = Instance.new("Frame")
buttonRow.BackgroundTransparency = 1
buttonRow.Size = UDim2.new(1, 0, 0, 40)
buttonRow.LayoutOrder = 6
buttonRow.Parent = panel

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rowLayout.Padding = UDim.new(0, 10)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = buttonRow

local function button(text: string, order: number, color: Color3, textColor: Color3): TextButton
    local newButton = Instance.new("TextButton")
    newButton.AutoButtonColor = true
    newButton.BackgroundColor3 = color
    newButton.Size = UDim2.fromOffset(150, 40)
    newButton.Font = Enum.Font.GothamBold
    newButton.Text = text
    newButton.TextColor3 = textColor
    newButton.TextSize = 15
    newButton.LayoutOrder = order
    newButton.Parent = buttonRow

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = newButton

    return newButton
end

local goButton = button("Take me there", 1, COLORS.Accent, COLORS.White)
local closeButton = button("Goodbye", 2, COLORS.Quiet, COLORS.Ink)

local currentStep: any = nil
local currentGuide: Guides.Guide? = nil

local function close()
    panel.Visible = false
    currentStep = nil
    currentGuide = nil
end

local function isBusy(): boolean
    return player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true
end

local function render(guide: Guides.Guide)
    local step = snapshot and snapshot.NextStep
    currentStep = step
    nameLabel.Text = string.format("%s  ·  %s", guide.DisplayName, guide.Role)
    greetingLabel.Text = guide.Greeting

    if not snapshot then
        questLabel.Text = "Your journal is still opening."
        hintLabel.Text = "Talk to me again in a moment and I will tell you what to do next."
        goButton.Visible = false
    elseif step then
        questLabel.Text = string.format("Your next quest: %s", tostring(step.Title))
        hintLabel.Text = tostring(step.Hint or "")
        goButton.Visible = true
        goButton.Text = if step.HallUnitId or not step.Destination then "Open the lesson" else "Take me there"
    else
        questLabel.Text = "MashaAllah, you have finished every quest on the path!"
        hintLabel.Text = "Keep the daily streak going, replay stories, and bring friends to a study circle."
        goButton.Visible = false
    end
end

local function open(guide: Guides.Guide)
    if isBusy() then
        return
    end

    currentGuide = guide
    sayingLabel.Text = guide.Sayings[math.random(1, #guide.Sayings)]
    render(guide)
    panel.Visible = true
end

goButton.Activated:Connect(function()
    local step = currentStep
    close()

    if not step then
        return
    end

    if step.Destination and not step.HallUnitId then
        requestTeleport:FireServer(step.Destination)
        return
    end

    local hall = playerGui:FindFirstChild("LearningHall")
    local openRequest = hall and hall:FindFirstChild("Open")

    if openRequest and openRequest:IsA("BindableEvent") then
        openRequest:Fire(step.HallUnitId)
    end
end)

closeButton.Activated:Connect(close)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
    if triggeringPlayer ~= player or prompt:GetAttribute("PromptAction") ~= "TalkToGuide" then
        return
    end

    local guide = guideById[tostring(prompt:GetAttribute("GuideId"))]

    if guide then
        open(guide)
    end
end)

-- Walking away from the guide ends the conversation.
ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
    if panel.Visible and prompt:GetAttribute("PromptAction") == "TalkToGuide" and currentGuide and prompt:GetAttribute("GuideId") == currentGuide.Id then
        close()
    end
end)

profileUpdated.OnClientEvent:Connect(function(payload: any)
    if type(payload) ~= "table" or type(payload.Level) ~= "number" then
        return
    end

    snapshot = payload

    if panel.Visible and currentGuide then
        render(currentGuide)
    end
end)

player:GetAttributeChangedSignal("InBattle"):Connect(function()
    if isBusy() then
        close()
    end
end)

player:GetAttributeChangedSignal("InStory"):Connect(function()
    if isBusy() then
        close()
    end
end)

-- The first snapshot may have been sent before this script was listening.
requestProfile:FireServer()
