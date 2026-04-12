--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattleAnimationLibrary = require(Shared.Config.BattleAnimationLibrary)

local player = Players.LocalPlayer
local toolConnections: { [Tool]: { RBXScriptConnection } } = {}
local lifecycleConnections: { RBXScriptConnection } = {}
local toolAnimationStates: { [Tool]: { Animator: Animator?, Tracks: { [string]: AnimationTrack } } } = {}

local SWORD_IDLE_GRIP = CFrame.new(0.16, -0.95, -0.12) * CFrame.Angles(math.rad(-18), math.rad(12), math.rad(-10))
local SWORD_WINDUP_GRIP = CFrame.new(0.22, -0.82, -0.08) * CFrame.Angles(math.rad(-70), math.rad(18), math.rad(18))
local SWORD_MID_SWING_GRIP = CFrame.new(0.18, -0.9, -0.11) * CFrame.Angles(math.rad(-14), math.rad(10), math.rad(-8))
local SWORD_STRIKE_GRIP = CFrame.new(0.08, -1.0, -0.2) * CFrame.Angles(math.rad(18), math.rad(-8), math.rad(-42))
local SWORD_FOLLOW_THROUGH_GRIP = CFrame.new(0.04, -0.98, -0.26) * CFrame.Angles(math.rad(28), math.rad(-14), math.rad(-56))
local SWORD_RECOVER_GRIP = CFrame.new(0.14, -0.96, -0.14) * CFrame.Angles(math.rad(-24), math.rad(6), math.rad(-12))
local BOW_IDLE_GRIP = CFrame.new(0, -0.2, 0.04) * CFrame.Angles(0, math.rad(90), 0)
local BOW_DRAW_GRIP = CFrame.new(-0.24, -0.05, 0.16) * CFrame.Angles(math.rad(-10), math.rad(96), math.rad(-6))

local BOW_DRAW_TIME_SECONDS = 0.9
local BOW_RELEASE_RESET_SECONDS = 0.22
local SWORD_SWING_SECONDS = 0.44

local function smoothStep(alpha: number): number
    local clamped = math.clamp(alpha, 0, 1)
    return clamped * clamped * (3 - 2 * clamped)
end

local function animateGrip(tool: Tool, target: CFrame, duration: number, tokenGetter: () -> number)
    local startGrip = tool.Grip
    local elapsed = 0
    local token = tokenGetter()

    while elapsed < duration and tool.Parent and token == tokenGetter() do
        elapsed += RunService.RenderStepped:Wait()
        local alpha = smoothStep(elapsed / duration)
        tool.Grip = startGrip:Lerp(target, alpha)
    end

    if tool.Parent and token == tokenGetter() then
        tool.Grip = target
    end
end

local function kickCamera(offsetDegrees: number, duration: number)
    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    local startFov = camera.FieldOfView
    local peakFov = startFov + offsetDegrees
    local elapsed = 0

    while elapsed < duration do
        elapsed += RunService.RenderStepped:Wait()
        local alpha = smoothStep(elapsed / duration)
        camera.FieldOfView = startFov + (peakFov - startFov) * (1 - alpha)
    end

    camera.FieldOfView = startFov
end

local function findPartWeld(part: BasePart?): Weld?
    if not part then
        return nil
    end

    local weld = part:FindFirstChildOfClass("Weld")

    if weld then
        return weld
    end

    return nil
end

local function getHumanoidFromTool(tool: Tool): Humanoid?
    local parent = tool.Parent

    if not parent or not parent:IsA("Model") then
        return nil
    end

    return parent:FindFirstChildOfClass("Humanoid")
end

local function getAnimatorFromTool(tool: Tool): Animator?
    local humanoid = getHumanoidFromTool(tool)

    if not humanoid then
        return nil
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")

    if animator then
        return animator
    end

    animator = Instance.new("Animator")
    animator.Parent = humanoid

    return animator
end

local function normalizeAnimationId(animationId: string): string
    if string.find(animationId, "rbxassetid://", 1, true) == 1 then
        return animationId
    end

    return "rbxassetid://" .. animationId
end

local function getAnimationState(tool: Tool, animator: Animator?): { Animator: Animator?, Tracks: { [string]: AnimationTrack } }
    local state = toolAnimationStates[tool]

    if state and state.Animator ~= animator then
        for _, track in pairs(state.Tracks) do
            pcall(function()
                track:Stop(0.08)
                track:Destroy()
            end)
        end

        state = nil
        toolAnimationStates[tool] = nil
    end

    if state then
        return state
    end

    state = {
        Animator = animator,
        Tracks = {},
    }
    toolAnimationStates[tool] = state

    return state
end

local function loadTrack(tool: Tool, key: string, entry): AnimationTrack?
    if not BattleAnimationLibrary.HasAnimation(entry) then
        return nil
    end

    local animator = getAnimatorFromTool(tool)

    if not animator then
        return nil
    end

    local state = getAnimationState(tool, animator)
    local existing = state.Tracks[key]

    if existing then
        return existing
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = normalizeAnimationId(entry.AnimationId)

    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)

    animation:Destroy()

    if not ok or not track then
        return nil
    end

    track.Priority = entry.Priority or Enum.AnimationPriority.Action
    track.Looped = entry.Looped == true
    state.Tracks[key] = track

    return track
end

local function playConfiguredTrack(tool: Tool, key: string, entry)
    local track = loadTrack(tool, key, entry)

    if not track then
        return nil
    end

    if track.IsPlaying then
        track:Stop(entry.FadeTime or 0.08)
    end

    track.TimePosition = 0
    track:Play(entry.FadeTime or 0.08, 1, entry.Speed or 1)

    return track
end

local function stopConfiguredTrack(tool: Tool, key: string, fadeTime: number?)
    local state = toolAnimationStates[tool]

    if not state then
        return
    end

    local track = state.Tracks[key]

    if not track then
        return
    end

    pcall(function()
        track:Stop(fadeTime or 0.08)
    end)
end

local function stopAllConfiguredTracks(tool: Tool)
    local state = toolAnimationStates[tool]

    if not state then
        return
    end

    for _, track in pairs(state.Tracks) do
        pcall(function()
            track:Stop(0.08)
            track:Destroy()
        end)
    end

    toolAnimationStates[tool] = nil
end

local function disconnectTool(tool: Tool)
    local connections = toolConnections[tool]

    if not connections then
        return
    end

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    stopAllConfiguredTracks(tool)
    toolConnections[tool] = nil
end

local function clearLifecycleConnections()
    for _, connection in ipairs(lifecycleConnections) do
        connection:Disconnect()
    end

    table.clear(lifecycleConnections)
end

local function trackLifecycle(connection: RBXScriptConnection)
    table.insert(lifecycleConnections, connection)
end

local function trackConnection(tool: Tool, connection: RBXScriptConnection)
    local list = toolConnections[tool]

    if not list then
        list = {}
        toolConnections[tool] = list
    end

    table.insert(list, connection)
end

local function attachSwordAnimation(tool: Tool)
    local animationToken = 0
    local swinging = false
    local swordConfig = BattleAnimationLibrary.Sword

    local function getToken(): number
        return animationToken
    end

    local function resumeIdle()
        playConfiguredTrack(tool, "SwordIdle", swordConfig.Idle)
    end

    local function resetSword()
        animationToken += 1
        swinging = false
        tool.Grip = SWORD_IDLE_GRIP
        stopConfiguredTrack(tool, "SwordSlash", 0.08)
        resumeIdle()
    end

    trackConnection(tool, tool.Equipped:Connect(function()
        tool.Grip = SWORD_IDLE_GRIP
        playConfiguredTrack(tool, "SwordEquip", swordConfig.Equip)
        task.delay(0.08, function()
            if tool.Parent then
                resumeIdle()
            end
        end)
    end))

    trackConnection(tool, tool.Unequipped:Connect(function()
        animationToken += 1
        swinging = false
        stopAllConfiguredTracks(tool)
        tool.Grip = SWORD_IDLE_GRIP
    end))

    trackConnection(tool, tool.Activated:Connect(function()
        if swinging then
            return
        end

        if player:GetAttribute("InBattle") ~= true then
            return
        end

        swinging = true
        animationToken += 1
        stopConfiguredTrack(tool, "SwordIdle", 0.05)
        playConfiguredTrack(tool, "SwordSlash", swordConfig.Slash)

        task.spawn(function()
            animateGrip(tool, SWORD_WINDUP_GRIP, 0.1, getToken)
            animateGrip(tool, SWORD_MID_SWING_GRIP, 0.05, getToken)
            animateGrip(tool, SWORD_STRIKE_GRIP, 0.06, getToken)
            animateGrip(tool, SWORD_FOLLOW_THROUGH_GRIP, 0.08, getToken)
            animateGrip(tool, SWORD_RECOVER_GRIP, 0.08, getToken)
            animateGrip(tool, SWORD_IDLE_GRIP, 0.14, getToken)
        end)

        task.spawn(function()
            kickCamera(1.6, 0.16)
        end)

        task.delay(SWORD_SWING_SECONDS, function()
            swinging = false

            if tool.Parent then
                resumeIdle()
            end
        end)
    end))

    if tool.Parent then
        resetSword()
    end
end

local function attachBowAnimation(tool: Tool)
    local animationToken = 0
    local drawing = false
    local drawStartedAt = 0
    local bowConfig = BattleAnimationLibrary.Bow

    local upperString = tool:FindFirstChild("UpperString", true)
    local lowerString = tool:FindFirstChild("LowerString", true)
    local displayArrow = tool:FindFirstChild("DisplayArrow", true)
    local upperStringPart = (upperString and upperString:IsA("BasePart")) and upperString or nil
    local lowerStringPart = (lowerString and lowerString:IsA("BasePart")) and lowerString or nil
    local displayArrowPart = (displayArrow and displayArrow:IsA("BasePart")) and displayArrow or nil

    local upperStringWeld = findPartWeld(upperStringPart)
    local lowerStringWeld = findPartWeld(lowerStringPart)
    local displayArrowWeld = findPartWeld(displayArrowPart)

    local upperIdle = CFrame.new(1.0, -2.18, 0)
    local lowerIdle = CFrame.new(1.0, 2.18, 0)
    local upperDraw = CFrame.new(0.52, -2.18, 0)
    local lowerDraw = CFrame.new(0.52, 2.18, 0)
    local arrowIdle = CFrame.new(-0.32, 0, -0.7) * CFrame.Angles(math.rad(90), 0, 0)
    local arrowDraw = CFrame.new(-0.98, 0, -0.7) * CFrame.Angles(math.rad(90), 0, 0)

    local function getToken(): number
        return animationToken
    end

    local function setDrawPose(alpha: number)
        local clamped = math.clamp(alpha, 0, 1)
        tool.Grip = BOW_IDLE_GRIP:Lerp(BOW_DRAW_GRIP, clamped)

        if upperStringWeld then
            upperStringWeld.C0 = upperIdle:Lerp(upperDraw, clamped)
        end

        if lowerStringWeld then
            lowerStringWeld.C0 = lowerIdle:Lerp(lowerDraw, clamped)
        end

        if displayArrowWeld then
            displayArrowWeld.C0 = arrowIdle:Lerp(arrowDraw, clamped)
        end
    end

    local function resumeIdle()
        playConfiguredTrack(tool, "BowIdle", bowConfig.Idle)
    end

    local function resetBow()
        animationToken += 1
        drawing = false
        tool.Grip = BOW_IDLE_GRIP
        setDrawPose(0)
        stopConfiguredTrack(tool, "BowDrawLoop", 0.08)
        stopConfiguredTrack(tool, "BowRelease", 0.08)
        resumeIdle()

        if displayArrowPart then
            displayArrowPart.Transparency = 0
        end
    end

    trackConnection(tool, tool.Equipped:Connect(function()
        playConfiguredTrack(tool, "BowEquip", bowConfig.Equip)
        task.delay(0.08, function()
            if tool.Parent then
                resetBow()
            end
        end)
    end))

    trackConnection(tool, tool.Unequipped:Connect(function()
        animationToken += 1
        drawing = false
        stopAllConfiguredTracks(tool)
        tool.Grip = BOW_IDLE_GRIP
        setDrawPose(0)

        if displayArrowPart then
            displayArrowPart.Transparency = 0
        end
    end))

    trackConnection(tool, tool.Activated:Connect(function()
        if drawing then
            return
        end

        if player:GetAttribute("InBattle") ~= true then
            return
        end

        drawing = true
        drawStartedAt = os.clock()
        animationToken += 1
        local activeToken = animationToken

        stopConfiguredTrack(tool, "BowIdle", 0.05)
        playConfiguredTrack(tool, "BowDrawLoop", bowConfig.DrawLoop)

        task.spawn(function()
            while drawing and activeToken == animationToken and tool.Parent do
                local elapsed = os.clock() - drawStartedAt
                setDrawPose(smoothStep(elapsed / BOW_DRAW_TIME_SECONDS))
                RunService.RenderStepped:Wait()
            end
        end)
    end))

    trackConnection(tool, tool.Deactivated:Connect(function()
        if not drawing then
            return
        end

        drawing = false
        stopConfiguredTrack(tool, "BowDrawLoop", 0.08)
        playConfiguredTrack(tool, "BowRelease", bowConfig.Release)

        if displayArrowPart then
            displayArrowPart.Transparency = 1
        end

        local releaseToken = animationToken

        task.spawn(function()
            local elapsed = 0
            local startGrip = tool.Grip

            while elapsed < BOW_RELEASE_RESET_SECONDS and tool.Parent and releaseToken == animationToken do
                elapsed += RunService.RenderStepped:Wait()
                local alpha = smoothStep(elapsed / BOW_RELEASE_RESET_SECONDS)
                local nextGrip = startGrip:Lerp(BOW_IDLE_GRIP, alpha)
                tool.Grip = nextGrip
                setDrawPose(1 - alpha)
            end

            if tool.Parent and releaseToken == animationToken then
                setDrawPose(0)

                if displayArrowPart then
                    displayArrowPart.Transparency = 0
                end

                resumeIdle()
            end
        end)

        task.spawn(function()
            kickCamera(2.1, 0.22)
        end)
    end))

    if tool.Parent then
        resetBow()
    end
end

local function tryAttachTool(tool: Tool)
    if toolConnections[tool] then
        return
    end

    if tool.Name == "Training Sword" then
        attachSwordAnimation(tool)
    elseif tool.Name == "Bow" then
        attachBowAnimation(tool)
    else
        return
    end

    trackConnection(tool, tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            disconnectTool(tool)
        end
    end))
end

local function attachCharacter(character: Model)
    clearLifecycleConnections()

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            tryAttachTool(child)
        end
    end

    local backpack = player:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                tryAttachTool(child)
            end
        end
    end

    trackLifecycle(character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            tryAttachTool(child)
        end
    end))

    if backpack then
        trackLifecycle(backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                tryAttachTool(child)
            end
        end))
    end
end

if player.Character then
    attachCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
    attachCharacter(character)
end)
