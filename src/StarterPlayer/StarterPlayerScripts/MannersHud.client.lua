--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mannersFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Manners")
local showMannersLesson = mannersFolder:WaitForChild("ShowMannersLesson") :: RemoteEvent

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MannersHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 16
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(700, 460)
panel.BackgroundColor3 = Color3.fromRGB(248, 240, 220)
panel.Visible = false
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(101, 83, 55)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(24, 20)
title.Size = UDim2.new(1, -92, 0, 34)
title.Font = Enum.Font.GothamBold
title.Text = ""
title.TextColor3 = Color3.fromRGB(48, 43, 34)
title.TextSize = 27
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(24, 60)
subtitle.Size = UDim2.new(1, -48, 0, 44)
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = ""
subtitle.TextColor3 = Color3.fromRGB(77, 97, 68)
subtitle.TextSize = 16
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextYAlignment = Enum.TextYAlignment.Top
subtitle.Parent = panel

local bodyScroll = Instance.new("ScrollingFrame")
bodyScroll.Name = "BodyScroll"
bodyScroll.Active = true
bodyScroll.BackgroundTransparency = 1
bodyScroll.BorderSizePixel = 0
bodyScroll.Position = UDim2.fromOffset(24, 122)
bodyScroll.Size = UDim2.new(1, -48, 1, -190)
bodyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
bodyScroll.CanvasSize = UDim2.new()
bodyScroll.ScrollBarThickness = 8
bodyScroll.ScrollBarImageColor3 = Color3.fromRGB(151, 133, 99)
bodyScroll.Parent = panel

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.new()
body.Size = UDim2.new(1, -10, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.Font = Enum.Font.Gotham
body.Text = ""
body.TextColor3 = Color3.fromRGB(70, 62, 49)
body.TextSize = 18
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.Parent = bodyScroll

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(0.5, 1)
closeButton.Position = UDim2.new(0.5, 0, 1, -22)
closeButton.Size = UDim2.fromOffset(180, 42)
closeButton.BackgroundColor3 = Color3.fromRGB(91, 125, 83)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(249, 244, 231)
closeButton.TextSize = 18
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeButton

showMannersLesson.OnClientEvent:Connect(function(payload)
    title.Text = payload.DisplayName or "Manners Lesson"
    subtitle.Text = payload.Subtitle or ""
    body.Text = table.concat(payload.Lines or {}, "\n\n")
    bodyScroll.CanvasPosition = Vector2.zero

    if payload.AccentColor then
        stroke.Color = payload.AccentColor
        closeButton.BackgroundColor3 = payload.AccentColor
    end

    panel.Visible = true
end)

closeButton.MouseButton1Click:Connect(function()
    panel.Visible = false
    bodyScroll.CanvasPosition = Vector2.zero
end)
