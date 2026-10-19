--!strict

local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CompanionStories = require(Shared.Data.CompanionStories)
local TravelRoute = require(Shared.Data.TravelRoute)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local shopFolder = remotesFolder:WaitForChild("Shop")
local storyFolder = remotesFolder:WaitForChild("Story")
local showStoryDialogue = storyFolder:WaitForChild("ShowStoryDialogue") :: RemoteEvent
local updateStoryMission = storyFolder:WaitForChild("UpdateStoryMission") :: RemoteEvent
local clearStoryMission = storyFolder:WaitForChild("ClearStoryMission") :: RemoteEvent
local requestStartStory = storyFolder:WaitForChild("RequestStartStory") :: RemoteEvent

local STORY_WORLD_NAME = "GeneratedStories"
local LINE_DURATION_SECONDS = 2.4
local promptConnections = {}
local activeStories = {}
local storyById = {}

for _, story in ipairs(CompanionStories) do
    storyById[story.Id] = story
end

local function getGrantCurrencyBindable()
    local bindable = shopFolder:FindFirstChild("GrantCurrency")

    if bindable and bindable:IsA("BindableEvent") then
        return bindable
    end

    return nil
end

local function awardKnowledgeTokens(player: Player, amount: number, reason: string)
    if amount <= 0 then
        return
    end

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

local function getStoryWorld(): Folder?
    local folder = Workspace:FindFirstChild(STORY_WORLD_NAME)

    if folder and folder:IsA("Folder") then
        return folder
    end

    return nil
end

local function getStoryZone(storyId: string): Folder?
    local worldFolder = getStoryWorld()
    local zone = worldFolder and worldFolder:FindFirstChild(storyId)

    if zone and zone:IsA("Folder") then
        return zone
    end

    return nil
end

local function getAnchor(zone: Folder, anchorName: string): BasePart?
    local anchors = zone:FindFirstChild("Anchors")
    local anchor = anchors and anchors:FindFirstChild(anchorName)

    if anchor and anchor:IsA("BasePart") then
        return anchor
    end

    return nil
end

local function getHubAnchor(): BasePart?
    local hubFolder = Workspace:FindFirstChild(TravelRoute.WorldFolderName)
    local teleportFolder = hubFolder and hubFolder:FindFirstChild("TeleportPoints")
    local anchor = teleportFolder and teleportFolder:FindFirstChild(TravelRoute.StartDestinationId)

    if anchor and anchor:IsA("BasePart") then
        return anchor
    end

    return nil
end

local function getCharacter(player: Player): Model?
    if player.Character then
        return player.Character
    end

    local ok, character = pcall(function()
        return player.CharacterAdded:Wait()
    end)

    if ok then
        return character
    end

    return nil
end

local function getReadyCharacter(player: Player, timeoutSeconds: number): Model?
    local deadline = os.clock() + timeoutSeconds

    while os.clock() < deadline do
        local character = player.Character

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                return character
            end
        end

        task.wait(0.15)
    end

    return nil
end

local function teleportPlayerToAnchor(player: Player, anchor: BasePart)
    local character = getCharacter(player)

    if character then
        character:PivotTo(anchor.CFrame * CFrame.new(0, 4, 0))
    end
end

local function findNpcHead(zone: Folder, npcName: string): BasePart?
    local stations = zone:FindFirstChild("Stations")

    if not stations then
        return nil
    end

    for _, station in ipairs(stations:GetDescendants()) do
        if station:IsA("Model") and station.Name == npcName then
            local head = station:FindFirstChild("Head")

            if head and head:IsA("BasePart") then
                return head
            end
        end
    end

    return nil
end

local function speakDialogueBubble(zone: Folder, npcName: string, dialogueLines)
    local head = findNpcHead(zone, npcName)

    if not head then
        return
    end

    task.spawn(function()
        for _, line in ipairs(dialogueLines) do
            local text = line.Text or line

            if type(text) == "string" then
                Chat:Chat(head, text, Enum.ChatColor.White)
                task.wait(LINE_DURATION_SECONDS)
            end
        end
    end)
end

local function fireDialogue(player: Player, story, title: string, dialogueLines)
    showStoryDialogue:FireClient(player, {
        StoryName = story.DisplayName,
        Title = title,
        Lines = dialogueLines,
        AccentColor = story.AccentColor,
    })
end

local function getCurrentStep(state)
    return state.Story.ScenarioSteps[state.StepIndex]
end

local function updateMissionForPlayer(player: Player)
    local state = activeStories[player]

    if not state then
        clearStoryMission:FireClient(player)
        return
    end

    local step = getCurrentStep(state)

    if not step then
        clearStoryMission:FireClient(player)
        return
    end

    updateStoryMission:FireClient(player, {
        StoryName = state.Story.DisplayName,
        StepLabel = string.format("Step %d of %d", state.StepIndex, #state.Story.ScenarioSteps),
        Objective = step.Objective,
        LocationName = step.LocationName,
    })
end

local function clearStoryState(player: Player)
    activeStories[player] = nil
    player:SetAttribute("InStory", false)
    player:SetAttribute("CurrentStoryId", nil)
    player:SetAttribute("CurrentStoryStepIndex", nil)
    clearStoryMission:FireClient(player)
end

local function returnPlayerToHub(player: Player)
    local hubAnchor = getHubAnchor()

    if not hubAnchor then
        return
    end

    teleportPlayerToAnchor(player, hubAnchor)
end

local function completeStory(player: Player)
    local state = activeStories[player]

    if not state then
        return
    end

    fireDialogue(player, state.Story, state.Story.Completion.Title, state.Story.Completion.Lines)
    awardKnowledgeTokens(player, state.Story.RewardTokens or 0, string.format("%s story complete", state.Story.DisplayName))
    PlayerProgress.RecordCompletion(player, "story", state.Story.Id, state.Story.DisplayName)

    local returnDelay = math.max(5.5, #state.Story.Completion.Lines * LINE_DURATION_SECONDS + 0.7)

    task.delay(returnDelay, function()
        if activeStories[player] ~= state then
            return
        end

        clearStoryState(player)
        returnPlayerToHub(player)
    end)
end

local function triggerStoryStep(player: Player, storyId: string, stepIndex: number)
    local state = activeStories[player]

    if not state or state.Story.Id ~= storyId or state.StepIndex ~= stepIndex or state.StepLocked == true then
        return
    end

    local step = state.Story.ScenarioSteps[stepIndex]

    if not step then
        return
    end

    state.StepLocked = true

    speakDialogueBubble(state.Zone, step.NpcName, step.Dialogue)
    fireDialogue(player, state.Story, step.Title, step.Dialogue)

    local holdDuration = math.max(3.2, #step.Dialogue * LINE_DURATION_SECONDS + 0.7)

    task.delay(holdDuration, function()
        if activeStories[player] ~= state then
            return
        end

        if state.StepIndex ~= stepIndex then
            return
        end

        if stepIndex >= #state.Story.ScenarioSteps then
            state.StepLocked = false
            completeStory(player)
            return
        end

        state.StepIndex += 1
        state.StepLocked = false
        player:SetAttribute("CurrentStoryStepIndex", state.StepIndex)
        updateMissionForPlayer(player)
    end)
end

local function startStory(player: Player, storyId: string)
    local story = storyById[storyId]

    if not story then
        return
    end

    if player:GetAttribute("InBattle") == true then
        return
    end

    local zone = getStoryZone(storyId)
    local entryAnchor = zone and getAnchor(zone, "Entry")

    if not zone or not entryAnchor then
        return
    end

    local state = {
        Story = story,
        Zone = zone,
        StepIndex = 1,
    }

    activeStories[player] = state
    player:SetAttribute("InStory", true)
    player:SetAttribute("CurrentStoryId", story.Id)
    player:SetAttribute("CurrentStoryStepIndex", 1)

    teleportPlayerToAnchor(player, entryAnchor)
    fireDialogue(player, story, "Story Start", story.Introduction)
    updateMissionForPlayer(player)
end

local function exitStory(player: Player)
    if not activeStories[player] then
        return
    end

    clearStoryState(player)
    returnPlayerToHub(player)
end

requestStartStory.OnServerEvent:Connect(function(player: Player, storyId: string)
    if typeof(storyId) == "string" then
        startStory(player, storyId)
    end
end)

local function connectPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    local action = prompt:GetAttribute("PromptAction")

    if action ~= "StartStory" and action ~= "StoryStep" and action ~= "ReturnToHub" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        if action == "StartStory" then
            local storyId = prompt:GetAttribute("StoryId")

            if typeof(storyId) == "string" then
                startStory(player, storyId)
            end
        elseif action == "StoryStep" then
            local storyId = prompt:GetAttribute("StoryId")
            local stepIndex = prompt:GetAttribute("StepIndex")

            if typeof(storyId) == "string" and type(stepIndex) == "number" then
                triggerStoryStep(player, storyId, stepIndex)
            end
        elseif action == "ReturnToHub" then
            exitStory(player)
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

task.spawn(function()
    local hubFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 10)

    if hubFolder then
        connectPromptsIn(hubFolder)
    end
end)

task.spawn(function()
    local storyWorld = Workspace:WaitForChild(STORY_WORLD_NAME, 10)

    if storyWorld then
        connectPromptsIn(storyWorld)
    end
end)

local function handleCharacterAdded(player: Player, _character: Model)
    local state = activeStories[player]

    if not state then
        return
    end

    task.delay(0.4, function()
        if activeStories[player] ~= state then
            return
        end

        local anchor = getAnchor(state.Zone, string.format("Step_%d", state.StepIndex)) or getAnchor(state.Zone, "Entry")

        if anchor then
            teleportPlayerToAnchor(player, anchor)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        handleCharacterAdded(player, character)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(character)
        handleCharacterAdded(player, character)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    activeStories[player] = nil
end)
