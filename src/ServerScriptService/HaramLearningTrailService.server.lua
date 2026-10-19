--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HaramLearningTrail = require(Shared.Data.HaramLearningTrail)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local hubFolder = remotesFolder:WaitForChild("Hub")
local shopFolder = remotesFolder:WaitForChild("Shop")
local requestHaramTrail = hubFolder:WaitForChild("RequestHaramTrail") :: RemoteEvent
local showLearningTrail = hubFolder:WaitForChild("ShowLearningTrail") :: RemoteEvent
local updateLearningTrail = hubFolder:WaitForChild("UpdateLearningTrail") :: RemoteEvent
local clearLearningTrail = hubFolder:WaitForChild("ClearLearningTrail") :: RemoteEvent

local LINE_DURATION_SECONDS = 2.45
local activeTrails = {}
local rewardedPlayers = {}
local promptConnections = {}

local function getGrantCurrencyBindable(): BindableEvent?
    local bindable = shopFolder:FindFirstChild("GrantCurrency")

    if bindable and bindable:IsA("BindableEvent") then
        return bindable
    end

    return nil
end

local function awardKnowledgeTokens(player: Player, amount: number, reason: string)
    if amount <= 0 or rewardedPlayers[player] == true then
        return
    end

    rewardedPlayers[player] = true

    local bindable = getGrantCurrencyBindable()

    if bindable then
        bindable:Fire(player, amount, reason)
        return
    end

    local currentTokens = player:GetAttribute("KnowledgeTokens")

    if type(currentTokens) ~= "number" then
        currentTokens = 0
    end

    player:SetAttribute("KnowledgeTokens", currentTokens + amount)
end

local function canUseTrail(player: Player): boolean
    return player:GetAttribute("InBattle") ~= true and player:GetAttribute("InStory") ~= true
end

local function showTrailMessage(player: Player, title: string, lines)
    showLearningTrail:FireClient(player, {
        TrailName = HaramLearningTrail.DisplayName,
        Title = title,
        Lines = lines,
        AccentColor = HaramLearningTrail.AccentColor,
    })
end

local function updateTrailMission(player: Player)
    local state = activeTrails[player]

    if not state then
        clearLearningTrail:FireClient(player)
        return
    end

    local step = HaramLearningTrail.Steps[state.StepIndex]

    if not step then
        clearLearningTrail:FireClient(player)
        return
    end

    updateLearningTrail:FireClient(player, {
        TrailName = HaramLearningTrail.DisplayName,
        StepLabel = string.format("Stop %d of %d", state.StepIndex, #HaramLearningTrail.Steps),
        Objective = step.Objective,
        LocationName = step.LocationName,
        AccentColor = HaramLearningTrail.AccentColor,
    })
end

local function startTrail(player: Player)
    if not canUseTrail(player) then
        return
    end

    local existingState = activeTrails[player]

    if existingState then
        updateTrailMission(player)
        return
    end

    activeTrails[player] = {
        StepIndex = 1,
        StepLocked = false,
    }

    player:SetAttribute("CurrentLearningTrailId", HaramLearningTrail.Id)
    player:SetAttribute("CurrentLearningTrailStep", 1)
    updateTrailMission(player)
    showTrailMessage(player, "Learning Walk Started", {
        { Speaker = "Guide", Text = HaramLearningTrail.StartObjective },
    })
end

local function completeTrail(player: Player, state)
    showTrailMessage(player, HaramLearningTrail.Completion.Title, HaramLearningTrail.Completion.Lines)
    awardKnowledgeTokens(player, HaramLearningTrail.RewardTokens or 0, HaramLearningTrail.DisplayName)
    PlayerProgress.RecordCompletion(player, "trail", HaramLearningTrail.Id, HaramLearningTrail.DisplayName)

    task.delay(math.max(5, #HaramLearningTrail.Completion.Lines * LINE_DURATION_SECONDS + 0.8), function()
        if activeTrails[player] ~= state then
            return
        end

        activeTrails[player] = nil
        player:SetAttribute("CurrentLearningTrailId", nil)
        player:SetAttribute("CurrentLearningTrailStep", nil)
        clearLearningTrail:FireClient(player)
    end)
end

local function triggerTrailStep(player: Player, stepIndex: number)
    if not canUseTrail(player) then
        return
    end

    if not activeTrails[player] and stepIndex == 1 then
        startTrail(player)
    elseif not activeTrails[player] then
        showTrailMessage(player, "Start The Walk First", {
            { Speaker = "Guide", Text = HaramLearningTrail.StartObjective },
        })
        return
    end

    local state = activeTrails[player]

    if not state or state.StepLocked == true then
        return
    end

    if state.StepIndex ~= stepIndex then
        local currentStep = HaramLearningTrail.Steps[state.StepIndex]

        if currentStep then
            showTrailMessage(player, "Follow The Gold Trail", {
                { Speaker = "Guide", Text = currentStep.Objective },
            })
        end

        return
    end

    local step = HaramLearningTrail.Steps[stepIndex]

    if not step then
        return
    end

    state.StepLocked = true
    showTrailMessage(player, step.Title, step.Lines)

    local holdDuration = math.max(3.2, #step.Lines * LINE_DURATION_SECONDS + 0.75)

    task.delay(holdDuration, function()
        if activeTrails[player] ~= state then
            return
        end

        if state.StepIndex ~= stepIndex then
            return
        end

        if stepIndex >= #HaramLearningTrail.Steps then
            state.StepLocked = false
            completeTrail(player, state)
            return
        end

        state.StepIndex += 1
        state.StepLocked = false
        player:SetAttribute("CurrentLearningTrailStep", state.StepIndex)
        updateTrailMission(player)
    end)
end

local function connectPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    if prompt:GetAttribute("PromptAction") ~= "HaramTrailStep" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        local stepIndex = prompt:GetAttribute("StepIndex")

        if type(stepIndex) == "number" then
            triggerTrailStep(player, stepIndex)
        end
    end)
end

local function connectPromptsIn(instance: Instance)
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            connectPrompt(descendant)
        end
    end

    instance.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            connectPrompt(descendant)
        end
    end)
end

requestHaramTrail.OnServerEvent:Connect(function(player: Player)
    startTrail(player)
end)

task.spawn(function()
    local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 10)

    if worldFolder then
        connectPromptsIn(worldFolder)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    activeTrails[player] = nil
    rewardedPlayers[player] = nil
end)
