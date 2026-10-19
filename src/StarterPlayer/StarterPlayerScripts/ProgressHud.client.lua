--!strict

-- Shows the player's level and XP bar, plus short toasts for XP, level ups, and badges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local progressFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Progress")
local requestProfile = progressFolder:WaitForChild("RequestProfile") :: RemoteEvent
local profileUpdated = progressFolder:WaitForChild("ProfileUpdated") :: RemoteEvent
local progressToast = progressFolder:WaitForChild("ProgressToast") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAX_TOASTS = 3
local TOAST_SECONDS = 3.2
local TOAST_COLORS = {
    xp = Color3.fromRGB(63, 98, 88),
    level = Color3.fromRGB(176, 140, 62),
    badge = Color3.fromRGB(121, 94, 63),
    warning = Color3.fromRGB(150, 74, 60),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProgressHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 90
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local levelPill = Instance.new("Frame")
levelPill.Name = "LevelPill"
-- Top-left is free in the hub; the story mission card uses it, so the pill hides during stories.
levelPill.Position = UDim2.fromOffset(22, 22)
levelPill.Size = UDim2.fromOffset(260, 46)
levelPill.BackgroundColor3 = Color3.fromRGB(31, 46, 38)
levelPill.BackgroundTransparency = 0.12
levelPill.Visible = false
levelPill.Parent = screenGui

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 12)
pillCorner.Parent = levelPill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = Color3.fromRGB(193, 162, 86)
pillStroke.Thickness = 1.4
pillStroke.Transparency = 0.2
pillStroke.Parent = levelPill

local levelLabel = Instance.new("TextLabel")
levelLabel.BackgroundTransparency = 1
levelLabel.Position = UDim2.fromOffset(12, 4)
levelLabel.Size = UDim2.new(1, -24, 0, 20)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Text = ""
levelLabel.TextColor3 = Color3.fromRGB(250, 246, 234)
levelLabel.TextSize = 15
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = levelPill

local xpLabel = Instance.new("TextLabel")
xpLabel.BackgroundTransparency = 1
xpLabel.Position = UDim2.fromOffset(12, 4)
xpLabel.Size = UDim2.new(1, -24, 0, 20)
xpLabel.Font = Enum.Font.GothamMedium
xpLabel.Text = ""
xpLabel.TextColor3 = Color3.fromRGB(226, 214, 180)
xpLabel.TextSize = 13
xpLabel.TextXAlignment = Enum.TextXAlignment.Right
xpLabel.Parent = levelPill

local barTrack = Instance.new("Frame")
barTrack.Position = UDim2.new(0, 12, 0, 28)
barTrack.Size = UDim2.new(1, -24, 0, 8)
barTrack.BackgroundColor3 = Color3.fromRGB(16, 24, 20)
barTrack.BorderSizePixel = 0
barTrack.Parent = levelPill

local barTrackCorner = Instance.new("UICorner")
barTrackCorner.CornerRadius = UDim.new(1, 0)
barTrackCorner.Parent = barTrack

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(214, 180, 98)
barFill.BorderSizePixel = 0
barFill.Parent = barTrack

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local toastStack = Instance.new("Frame")
toastStack.Name = "Toasts"
-- Middle-right stays clear of the trivia panel (top center) and learning walk card (top right).
toastStack.AnchorPoint = Vector2.new(1, 0.5)
toastStack.Position = UDim2.new(1, -16, 0.45, 0)
toastStack.Size = UDim2.fromOffset(300, 260)
toastStack.BackgroundTransparency = 1
toastStack.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.Parent = toastStack

local toastOrder = 0

local function updateVisibility()
    local busy = player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true
    levelPill.Visible = not busy and levelLabel.Text ~= ""
end

local function applySnapshot(snapshot: any)
    if type(snapshot) ~= "table" or type(snapshot.Level) ~= "number" then
        return
    end

    levelLabel.Text = string.format("Lv %d  ·  %s", snapshot.Level, tostring(snapshot.RankTitle or ""))
    xpLabel.Text = string.format("%d / %d XP", snapshot.XPIntoLevel or 0, snapshot.XPForNext or 0)

    local ratio = 0

    if type(snapshot.XPForNext) == "number" and snapshot.XPForNext > 0 then
        ratio = math.clamp((snapshot.XPIntoLevel or 0) / snapshot.XPForNext, 0, 1)
    end

    TweenService:Create(barFill, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(ratio, 1),
    }):Play()

    updateVisibility()
end

local function showToast(payload: any)
    if type(payload) ~= "table" or type(payload.Title) ~= "string" then
        return
    end

    local toasts = {}

    for _, child in ipairs(toastStack:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(toasts, child)
        end
    end

    table.sort(toasts, function(a, b)
        return a.LayoutOrder < b.LayoutOrder
    end)

    for index = 1, #toasts - MAX_TOASTS + 1 do
        toasts[index]:Destroy()
    end

    toastOrder += 1

    local hasBody = type(payload.Body) == "string" and payload.Body ~= ""
    local toast = Instance.new("Frame")
    toast.LayoutOrder = toastOrder
    toast.Size = UDim2.fromOffset(300, if hasBody then 62 else 40)
    toast.BackgroundColor3 = TOAST_COLORS[payload.Kind] or TOAST_COLORS.xp
    toast.BackgroundTransparency = 0.06
    toast.Parent = toastStack

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toast

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -24, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.Text = payload.Title
    title.TextColor3 = Color3.fromRGB(252, 248, 236)
    title.TextSize = 15
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = toast

    if hasBody then
        local body = Instance.new("TextLabel")
        body.BackgroundTransparency = 1
        body.Position = UDim2.fromOffset(12, 30)
        body.Size = UDim2.new(1, -24, 0, 26)
        body.Font = Enum.Font.Gotham
        body.Text = payload.Body
        body.TextColor3 = Color3.fromRGB(236, 228, 206)
        body.TextSize = 13
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = toast
    end

    task.delay(TOAST_SECONDS, function()
        if toast.Parent then
            local fade = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
            fade:Play()
            fade.Completed:Wait()
            toast:Destroy()
        end
    end)
end

profileUpdated.OnClientEvent:Connect(applySnapshot)
progressToast.OnClientEvent:Connect(showToast)
player:GetAttributeChangedSignal("InBattle"):Connect(updateVisibility)
player:GetAttributeChangedSignal("InStory"):Connect(updateVisibility)

-- The server pushes a snapshot when the profile loads, but this script may start after that.
requestProfile:FireServer()
