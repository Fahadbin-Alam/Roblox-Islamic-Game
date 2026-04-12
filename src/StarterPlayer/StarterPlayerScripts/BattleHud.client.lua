--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local battleFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Battle")
local showBattleMessage = battleFolder:WaitForChild("ShowBattleMessage") :: RemoteEvent
local showBattleSummary = battleFolder:WaitForChild("ShowBattleSummary") :: RemoteEvent
local playReenactment = battleFolder:WaitForChild("PlayReenactment") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BattleHud"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, -80)
toast.Size = UDim2.fromOffset(620, 56)
toast.BackgroundColor3 = Color3.fromRGB(30, 35, 32)
toast.BackgroundTransparency = 0.08
toast.Font = Enum.Font.GothamBold
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(247, 243, 228)
toast.TextSize = 20
toast.TextWrapped = true
toast.Visible = false
toast.Parent = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 16)
toastCorner.Parent = toast

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(166, 147, 101)
toastStroke.Thickness = 1.5
toastStroke.Parent = toast

local summaryFrame = Instance.new("Frame")
summaryFrame.Name = "Summary"
summaryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
summaryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
summaryFrame.Size = UDim2.fromOffset(700, 420)
summaryFrame.BackgroundColor3 = Color3.fromRGB(245, 236, 216)
summaryFrame.Visible = false
summaryFrame.Parent = screenGui

local summaryCorner = Instance.new("UICorner")
summaryCorner.CornerRadius = UDim.new(0, 20)
summaryCorner.Parent = summaryFrame

local summaryStroke = Instance.new("UIStroke")
summaryStroke.Color = Color3.fromRGB(112, 94, 66)
summaryStroke.Thickness = 2
summaryStroke.Parent = summaryFrame

local scenarioLabel = Instance.new("TextLabel")
scenarioLabel.BackgroundTransparency = 1
scenarioLabel.Position = UDim2.fromOffset(24, 18)
scenarioLabel.Size = UDim2.new(1, -48, 0, 36)
scenarioLabel.Font = Enum.Font.GothamBold
scenarioLabel.Text = ""
scenarioLabel.TextColor3 = Color3.fromRGB(55, 47, 36)
scenarioLabel.TextSize = 28
scenarioLabel.TextXAlignment = Enum.TextXAlignment.Left
scenarioLabel.Parent = summaryFrame

local winnerLabel = Instance.new("TextLabel")
winnerLabel.BackgroundTransparency = 1
winnerLabel.Position = UDim2.fromOffset(24, 60)
winnerLabel.Size = UDim2.new(1, -48, 0, 28)
winnerLabel.Font = Enum.Font.GothamMedium
winnerLabel.Text = ""
winnerLabel.TextColor3 = Color3.fromRGB(72, 106, 78)
winnerLabel.TextSize = 18
winnerLabel.TextXAlignment = Enum.TextXAlignment.Left
winnerLabel.Parent = summaryFrame

local summaryTitle = Instance.new("TextLabel")
summaryTitle.BackgroundTransparency = 1
summaryTitle.Position = UDim2.fromOffset(24, 106)
summaryTitle.Size = UDim2.new(1, -48, 0, 30)
summaryTitle.Font = Enum.Font.GothamBold
summaryTitle.Text = ""
summaryTitle.TextColor3 = Color3.fromRGB(86, 67, 44)
summaryTitle.TextSize = 22
summaryTitle.TextXAlignment = Enum.TextXAlignment.Left
summaryTitle.Parent = summaryFrame

local linesLabel = Instance.new("TextLabel")
linesLabel.BackgroundTransparency = 1
linesLabel.Position = UDim2.fromOffset(24, 148)
linesLabel.Size = UDim2.new(1, -48, 1, -214)
linesLabel.Font = Enum.Font.Gotham
linesLabel.Text = ""
linesLabel.TextColor3 = Color3.fromRGB(76, 69, 58)
linesLabel.TextSize = 18
linesLabel.TextWrapped = true
linesLabel.TextXAlignment = Enum.TextXAlignment.Left
linesLabel.TextYAlignment = Enum.TextYAlignment.Top
linesLabel.Parent = summaryFrame

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(0.5, 1)
closeButton.Position = UDim2.new(0.5, 0, 1, -22)
closeButton.Size = UDim2.fromOffset(180, 42)
closeButton.BackgroundColor3 = Color3.fromRGB(77, 117, 83)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(248, 245, 233)
closeButton.TextSize = 18
closeButton.Parent = summaryFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeButton

local cutsceneFrame = Instance.new("Frame")
cutsceneFrame.Name = "Reenactment"
cutsceneFrame.Size = UDim2.fromScale(1, 1)
cutsceneFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
cutsceneFrame.BackgroundTransparency = 1
cutsceneFrame.Visible = false
cutsceneFrame.Parent = screenGui

local cinematicTop = Instance.new("Frame")
cinematicTop.Size = UDim2.new(1, 0, 0, 74)
cinematicTop.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
cinematicTop.BackgroundTransparency = 0.38
cinematicTop.Parent = cutsceneFrame

local cinematicBottom = Instance.new("Frame")
cinematicBottom.AnchorPoint = Vector2.new(0, 1)
cinematicBottom.Position = UDim2.new(0, 0, 1, 0)
cinematicBottom.Size = UDim2.new(1, 0, 0, 158)
cinematicBottom.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
cinematicBottom.BackgroundTransparency = 0.3
cinematicBottom.Parent = cutsceneFrame

local vignette = Instance.new("Frame")
vignette.AnchorPoint = Vector2.new(0.5, 0.5)
vignette.Position = UDim2.fromScale(0.5, 0.5)
vignette.Size = UDim2.new(1, -80, 1, -236)
vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vignette.BackgroundTransparency = 0.93
vignette.Parent = cutsceneFrame

local vignetteCorner = Instance.new("UICorner")
vignetteCorner.CornerRadius = UDim.new(0, 28)
vignetteCorner.Parent = vignette

local accentBar = Instance.new("Frame")
accentBar.Position = UDim2.fromOffset(28, 98)
accentBar.Size = UDim2.new(0, 4, 1, -252)
accentBar.BackgroundColor3 = Color3.fromRGB(205, 169, 94)
accentBar.BackgroundTransparency = 0.32
accentBar.Parent = cutsceneFrame

local progressTrack = Instance.new("Frame")
progressTrack.AnchorPoint = Vector2.new(0, 1)
progressTrack.Position = UDim2.new(0, 30, 1, -14)
progressTrack.Size = UDim2.new(1, -60, 0, 4)
progressTrack.BackgroundColor3 = Color3.fromRGB(61, 54, 42)
progressTrack.BackgroundTransparency = 0.12
progressTrack.BorderSizePixel = 0
progressTrack.Parent = cinematicBottom

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.fromScale(0, 1)
progressBar.BackgroundColor3 = Color3.fromRGB(218, 184, 104)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressTrack

local introLabel = Instance.new("TextLabel")
introLabel.BackgroundTransparency = 1
introLabel.Position = UDim2.fromOffset(28, 18)
introLabel.Size = UDim2.new(1, -56, 0, 24)
introLabel.Font = Enum.Font.GothamBold
introLabel.Text = ""
introLabel.TextColor3 = Color3.fromRGB(232, 220, 191)
introLabel.TextSize = 18
introLabel.TextXAlignment = Enum.TextXAlignment.Left
introLabel.Parent = cinematicTop

local cutsceneScenario = Instance.new("TextLabel")
cutsceneScenario.BackgroundTransparency = 1
cutsceneScenario.Position = UDim2.fromOffset(28, 40)
cutsceneScenario.Size = UDim2.new(1, -56, 0, 30)
cutsceneScenario.Font = Enum.Font.GothamBold
cutsceneScenario.Text = ""
cutsceneScenario.TextColor3 = Color3.fromRGB(255, 248, 226)
cutsceneScenario.TextSize = 26
cutsceneScenario.TextXAlignment = Enum.TextXAlignment.Left
cutsceneScenario.Parent = cinematicTop

local cutsceneWinner = Instance.new("TextLabel")
cutsceneWinner.BackgroundTransparency = 1
cutsceneWinner.AnchorPoint = Vector2.new(1, 0)
cutsceneWinner.Position = UDim2.new(1, -24, 0, 22)
cutsceneWinner.Size = UDim2.fromOffset(280, 30)
cutsceneWinner.Font = Enum.Font.GothamMedium
cutsceneWinner.Text = ""
cutsceneWinner.TextColor3 = Color3.fromRGB(187, 201, 165)
cutsceneWinner.TextSize = 16
cutsceneWinner.TextXAlignment = Enum.TextXAlignment.Right
cutsceneWinner.Parent = cinematicTop

local sceneTitle = Instance.new("TextLabel")
sceneTitle.BackgroundTransparency = 1
sceneTitle.Position = UDim2.new(0, 30, 1, -132)
sceneTitle.Size = UDim2.new(1, -60, 0, 30)
sceneTitle.Font = Enum.Font.GothamBold
sceneTitle.Text = ""
sceneTitle.TextColor3 = Color3.fromRGB(251, 243, 225)
sceneTitle.TextSize = 24
sceneTitle.TextXAlignment = Enum.TextXAlignment.Left
sceneTitle.Parent = cinematicBottom

local sceneBody = Instance.new("TextLabel")
sceneBody.BackgroundTransparency = 1
sceneBody.Position = UDim2.new(0, 30, 1, -96)
sceneBody.Size = UDim2.new(1, -60, 0, 68)
sceneBody.Font = Enum.Font.Gotham
sceneBody.Text = ""
sceneBody.TextColor3 = Color3.fromRGB(220, 214, 199)
sceneBody.TextSize = 16
sceneBody.TextWrapped = true
sceneBody.TextXAlignment = Enum.TextXAlignment.Left
sceneBody.TextYAlignment = Enum.TextYAlignment.Top
sceneBody.Parent = cinematicBottom

local sceneCounter = Instance.new("TextLabel")
sceneCounter.BackgroundTransparency = 1
sceneCounter.Position = UDim2.new(0, 30, 1, -26)
sceneCounter.Size = UDim2.new(1, -60, 0, 20)
sceneCounter.Font = Enum.Font.GothamMedium
sceneCounter.Text = ""
sceneCounter.TextColor3 = Color3.fromRGB(174, 166, 148)
sceneCounter.TextSize = 14
sceneCounter.TextXAlignment = Enum.TextXAlignment.Left
sceneCounter.Parent = cinematicBottom

local toastToken = 0
local cutsceneToken = 0

local function showToast(text: string, duration: number)
    toastToken += 1
    local currentToken = toastToken

    toast.Text = text
    toast.Visible = true
    toast.Position = UDim2.new(0.5, 0, 0, -80)

    TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 18),
    }):Play()

    task.delay(duration, function()
        if currentToken ~= toastToken then
            return
        end

        local tween = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -80),
        })
        tween:Play()
        tween.Completed:Wait()

        if currentToken == toastToken then
            toast.Visible = false
        end
    end)
end

local function restoreCamera(cameraState)
    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    camera.CameraType = Enum.CameraType.Custom
    camera.FieldOfView = cameraState.FieldOfView or 70

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        camera.CameraSubject = humanoid
    end
end

local function getKindLabel(kind: string?): string
    if kind == "Briefing" then
        return "Animated Battle Briefing"
    end

    return "Historical Reenactment"
end

local function tweenCutsceneFrameIn()
    cutsceneFrame.BackgroundTransparency = 1
    TweenService:Create(cutsceneFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.76,
    }):Play()
end

local function tweenCutsceneFrameOut()
    local tween = TweenService:Create(cutsceneFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    })
    tween:Play()
    tween.Completed:Wait()
end

local function tweenCameraTo(camera: Camera, cframe: CFrame, fieldOfView: number?, duration: number)
    local tweenDuration = math.min(1.35, math.max(0.45, duration * 0.28))
    local tween = TweenService:Create(camera, TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        CFrame = cframe,
        FieldOfView = fieldOfView or 66,
    })
    tween:Play()
    tween.Completed:Wait()

    return tweenDuration
end

showBattleMessage.OnClientEvent:Connect(function(payload)
    showToast(payload.Text or "", payload.Duration or 4)
end)

showBattleSummary.OnClientEvent:Connect(function(payload)
    scenarioLabel.Text = payload.ScenarioName or ""
    winnerLabel.Text = payload.WinnerText or ""
    summaryTitle.Text = payload.SummaryTitle or ""
    linesLabel.Text = table.concat(payload.SummaryLines or {}, "\n\n")
    summaryFrame.Visible = true
end)

playReenactment.OnClientEvent:Connect(function(payload)
    cutsceneToken += 1
    local currentToken = cutsceneToken
    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    local cameraState = {
        FieldOfView = camera.FieldOfView,
    }

    summaryFrame.Visible = false
    cutsceneFrame.Visible = true
    tweenCutsceneFrameIn()
    introLabel.Text = string.format("%s | %s", getKindLabel(payload.Kind), payload.IntroTitle or "")
    cutsceneScenario.Text = payload.ScenarioName or ""
    cutsceneWinner.Text = payload.WinnerText or ""
    cutsceneWinner.Visible = payload.Kind ~= "Briefing"
    progressBar.Size = UDim2.fromScale(0, 1)
    camera.CameraType = Enum.CameraType.Scriptable

    local scenes = payload.Scenes or {}
    local totalDuration = 0

    for _, scene in ipairs(scenes) do
        totalDuration += scene.DurationSeconds or 5
    end

    local elapsedDuration = 0

    for index, scene in ipairs(scenes) do
        if currentToken ~= cutsceneToken then
            break
        end

        sceneTitle.Text = scene.Title or ""
        sceneBody.Text = scene.Body or ""
        sceneCounter.Text = string.format("%s %d of %d", payload.Kind == "Briefing" and "Briefing" or "Scene", index, #scenes)

        local sceneDuration = scene.DurationSeconds or 5
        local cameraTweenDuration = 0

        progressBar.Size = UDim2.fromScale(math.clamp(elapsedDuration / math.max(totalDuration, 1), 0, 1), 1)
        TweenService:Create(progressBar, TweenInfo.new(sceneDuration, Enum.EasingStyle.Linear), {
            Size = UDim2.fromScale(math.clamp((elapsedDuration + sceneDuration) / math.max(totalDuration, 1), 0, 1), 1),
        }):Play()

        if scene.CameraCFrame then
            cameraTweenDuration = tweenCameraTo(camera, scene.CameraCFrame, scene.FieldOfView, sceneDuration)
        end

        task.wait(math.max(0, sceneDuration - cameraTweenDuration))
        elapsedDuration += sceneDuration
    end

    if currentToken == cutsceneToken then
        tweenCutsceneFrameOut()
        cutsceneFrame.Visible = false
        restoreCamera(cameraState)
    end
end)

closeButton.MouseButton1Click:Connect(function()
    summaryFrame.Visible = false
end)
