--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local battleFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Battle")
local showBattleMessage = battleFolder:WaitForChild("ShowBattleMessage") :: RemoteEvent
local showBattleSummary = battleFolder:WaitForChild("ShowBattleSummary") :: RemoteEvent
local playReenactment = battleFolder:WaitForChild("PlayReenactment") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existingCutsceneBlur = Lighting:FindFirstChild("BattleHudCutsceneBlur")
local cutsceneBlur: BlurEffect
if existingCutsceneBlur and existingCutsceneBlur:IsA("BlurEffect") then
    cutsceneBlur = existingCutsceneBlur
else
    cutsceneBlur = Instance.new("BlurEffect")
    cutsceneBlur.Name = "BattleHudCutsceneBlur"
    cutsceneBlur.Size = 0
    cutsceneBlur.Enabled = false
    cutsceneBlur.Parent = Lighting
end

local existingCutsceneColor = Lighting:FindFirstChild("BattleHudCutsceneColor")
local cutsceneColor: ColorCorrectionEffect
if existingCutsceneColor and existingCutsceneColor:IsA("ColorCorrectionEffect") then
    cutsceneColor = existingCutsceneColor
else
    cutsceneColor = Instance.new("ColorCorrectionEffect")
    cutsceneColor.Name = "BattleHudCutsceneColor"
    cutsceneColor.Enabled = false
    cutsceneColor.Brightness = 0
    cutsceneColor.Contrast = 0
    cutsceneColor.Saturation = 0
    cutsceneColor.Parent = Lighting
end

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
cinematicBottom.Size = UDim2.new(1, 0, 0, 184)
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
accentBar.Size = UDim2.new(0, 4, 1, -280)
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

local sceneTextPlate = Instance.new("Frame")
sceneTextPlate.Position = UDim2.new(0, 18, 1, -166)
sceneTextPlate.Size = UDim2.new(1, -36, 0, 130)
sceneTextPlate.BackgroundColor3 = Color3.fromRGB(15, 14, 12)
sceneTextPlate.BackgroundTransparency = 0.26
sceneTextPlate.Parent = cinematicBottom

local sceneTextPlateCorner = Instance.new("UICorner")
sceneTextPlateCorner.CornerRadius = UDim.new(0, 18)
sceneTextPlateCorner.Parent = sceneTextPlate

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
sceneTitle.Position = UDim2.new(0, 38, 1, -152)
sceneTitle.Size = UDim2.new(1, -60, 0, 30)
sceneTitle.Font = Enum.Font.GothamBold
sceneTitle.Text = ""
sceneTitle.TextColor3 = Color3.fromRGB(251, 243, 225)
sceneTitle.TextSize = 25
sceneTitle.TextXAlignment = Enum.TextXAlignment.Left
sceneTitle.Parent = cinematicBottom

local sceneBody = Instance.new("TextLabel")
sceneBody.BackgroundTransparency = 1
sceneBody.Position = UDim2.new(0, 38, 1, -112)
sceneBody.Size = UDim2.new(1, -76, 0, 74)
sceneBody.Font = Enum.Font.Gotham
sceneBody.Text = ""
sceneBody.TextColor3 = Color3.fromRGB(220, 214, 199)
sceneBody.TextSize = 17
sceneBody.TextWrapped = true
sceneBody.TextXAlignment = Enum.TextXAlignment.Left
sceneBody.TextYAlignment = Enum.TextYAlignment.Top
sceneBody.Parent = cinematicBottom

local sceneReference = Instance.new("TextLabel")
sceneReference.BackgroundTransparency = 1
sceneReference.Position = UDim2.new(0, 38, 1, -38)
sceneReference.Size = UDim2.new(1, -76, 0, 18)
sceneReference.Font = Enum.Font.GothamMedium
sceneReference.Text = ""
sceneReference.TextColor3 = Color3.fromRGB(205, 187, 145)
sceneReference.TextSize = 13
sceneReference.TextTransparency = 1
sceneReference.TextWrapped = true
sceneReference.TextXAlignment = Enum.TextXAlignment.Left
sceneReference.Parent = cinematicBottom

local sceneCounter = Instance.new("TextLabel")
sceneCounter.BackgroundTransparency = 1
sceneCounter.Position = UDim2.new(0, 38, 1, -20)
sceneCounter.Size = UDim2.new(1, -60, 0, 20)
sceneCounter.Font = Enum.Font.GothamMedium
sceneCounter.Text = ""
sceneCounter.TextColor3 = Color3.fromRGB(174, 166, 148)
sceneCounter.TextSize = 14
sceneCounter.TextXAlignment = Enum.TextXAlignment.Left
sceneCounter.Parent = cinematicBottom

local toastToken = 0
local cutsceneToken = 0

local function smoothStep(alpha: number): number
    local clamped = math.clamp(alpha, 0, 1)
    return clamped * clamped * (3 - 2 * clamped)
end

local function setCoreGuiVisibility(isVisible: boolean)
    for _, coreGuiType in ipairs({
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.Health,
    }) do
        pcall(function()
            StarterGui:SetCoreGuiEnabled(coreGuiType, isVisible)
        end)
    end

    pcall(function()
        StarterGui:SetCore("TopbarEnabled", isVisible)
    end)
end

local function setCutscenePostProcessing(isEnabled: boolean)
    cutsceneBlur.Enabled = true
    TweenService:Create(cutsceneBlur, TweenInfo.new(isEnabled and 0.32 or 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = isEnabled and 10 or 0,
    }):Play()

    cutsceneColor.Enabled = true
    TweenService:Create(cutsceneColor, TweenInfo.new(isEnabled and 0.32 or 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Brightness = isEnabled and -0.03 or 0,
        Contrast = isEnabled and 0.12 or 0,
        Saturation = isEnabled and -0.08 or 0,
    }):Play()

    if not isEnabled then
        task.delay(0.26, function()
            if cutsceneToken == 0 then
                cutsceneColor.Enabled = false
                cutsceneBlur.Enabled = false
            end
        end)
    end
end

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

    cutsceneToken = 0
    setCoreGuiVisibility(true)
    setCutscenePostProcessing(false)
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
        return "Cinematic Battlefield Briefing"
    end

    return "Cinematic Historical Reenactment"
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

local function moveCameraThroughScene(camera: Camera, scene, duration: number, token: number)
    local cframe = scene.CameraCFrame

    if not cframe then
        task.wait(duration)
        return
    end

    local targetFieldOfView = scene.FieldOfView or 66
    local tweenDuration = math.min(1.9, math.max(0.6, duration * 0.34))
    local tween = TweenService:Create(camera, TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        CFrame = cframe,
        FieldOfView = targetFieldOfView,
    })
    tween:Play()
    tween.Completed:Wait()

    if token ~= cutsceneToken then
        return
    end

    local drift = scene.CameraDrift
    local driftDuration = math.max(0, duration - tweenDuration)

    if typeof(drift) ~= "Vector3" or drift.Magnitude <= 0.05 or driftDuration <= 0 then
        if driftDuration > 0 then
            task.wait(driftDuration)
        end

        return
    end

    local baseLookTarget = cframe.Position + cframe.LookVector * 120
    local elapsed = 0

    while elapsed < driftDuration and token == cutsceneToken do
        elapsed += RunService.RenderStepped:Wait()
        local alpha = smoothStep(elapsed / driftDuration)
        local offset = drift * alpha
        local driftedPosition = cframe.Position + offset
        local driftedLook = baseLookTarget + drift * 0.35 * alpha
        camera.CFrame = CFrame.lookAt(driftedPosition, driftedLook)
        camera.FieldOfView = targetFieldOfView
    end
end

local function tweenSceneText(sceneTitleTransparency: number, sceneBodyTransparency: number, sceneCounterTransparency: number, duration: number)
    TweenService:Create(sceneTitle, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = sceneTitleTransparency,
    }):Play()
    TweenService:Create(sceneBody, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = sceneBodyTransparency,
    }):Play()
    TweenService:Create(sceneReference, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = sceneBodyTransparency,
    }):Play()
    TweenService:Create(sceneCounter, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = sceneCounterTransparency,
    }):Play()
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
    setCoreGuiVisibility(false)
    setCutscenePostProcessing(true)
    tweenCutsceneFrameIn()
    introLabel.Text = string.format("%s | %s", getKindLabel(payload.Kind), payload.IntroTitle or "")
    cutsceneScenario.Text = payload.ScenarioName or ""
    cutsceneWinner.Text = payload.WinnerText or ""
    cutsceneWinner.Visible = payload.Kind ~= "Briefing"
    progressBar.Size = UDim2.fromScale(0, 1)
    camera.CameraType = Enum.CameraType.Scriptable

    local scenes = payload.Scenes or {}
    local totalDuration = 0
    sceneTitle.TextTransparency = 1
    sceneBody.TextTransparency = 1
    sceneReference.TextTransparency = 1
    sceneCounter.TextTransparency = 1

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
        sceneReference.Text = scene.Reference or ""
        sceneCounter.Text = string.format("%s %d of %d", payload.Kind == "Briefing" and "Briefing" or "Scene", index, #scenes)
        tweenSceneText(0, 0, 0, 0.22)

        local sceneDuration = scene.DurationSeconds or 5

        progressBar.Size = UDim2.fromScale(math.clamp(elapsedDuration / math.max(totalDuration, 1), 0, 1), 1)
        TweenService:Create(progressBar, TweenInfo.new(sceneDuration, Enum.EasingStyle.Linear), {
            Size = UDim2.fromScale(math.clamp((elapsedDuration + sceneDuration) / math.max(totalDuration, 1), 0, 1), 1),
        }):Play()

        moveCameraThroughScene(camera, scene, math.max(0.4, sceneDuration - 0.18), currentToken)
        tweenSceneText(1, 1, 1, 0.18)
        task.wait(0.18)
        elapsedDuration += sceneDuration
    end

    if currentToken == cutsceneToken then
        tweenCutsceneFrameOut()
        cutsceneFrame.Visible = false
        restoreCamera(cameraState)
    end
end)

closeButton.MouseButton1Click:Connect(function()
    setCoreGuiVisibility(true)
    setCutscenePostProcessing(false)
    summaryFrame.Visible = false
end)
