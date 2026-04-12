--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattleScenarios = require(Shared.Data.BattleScenarios)
local TravelRoute = require(Shared.Data.TravelRoute)
local BattleLoadout = require(script.Parent.Modules.BattleLoadout)
local BattleBots = require(script.Parent.Modules.BattleBots)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local battleFolder = remotesFolder:WaitForChild("Battle")
local shopFolder = remotesFolder:WaitForChild("Shop")
local showBattleMessage = battleFolder:WaitForChild("ShowBattleMessage") :: RemoteEvent
local showBattleSummary = battleFolder:WaitForChild("ShowBattleSummary") :: RemoteEvent
local playReenactment = battleFolder:WaitForChild("PlayReenactment") :: RemoteEvent
local requestJoinBattle = battleFolder:WaitForChild("RequestJoinBattle") :: RemoteEvent

local scenarioById = {}
local queues = {}
local queueCountdowns = {}
local activeSessions = {}
local playerToSession = {}
local promptConnections = {}
local startSession
local COMBATANT_TAG = "BattleCombatant"

for _, scenario in ipairs(BattleScenarios) do
    scenarioById[scenario.Id] = scenario
    queues[scenario.Id] = {}
end

local function sendMessage(playersList, text: string, duration: number?)
    for _, player in ipairs(playersList) do
        showBattleMessage:FireClient(player, {
            Text = text,
            Duration = duration or 4,
        })
    end
end

local function awardKnowledgeTokens(player: Player, amount: number, reason: string)
    if amount <= 0 then
        return
    end

    local bindable = shopFolder:FindFirstChild("GrantCurrency")

    if bindable and bindable:IsA("BindableEvent") then
        bindable:Fire(player, amount, reason)
        return
    end

    local currentTokens = player:GetAttribute("KnowledgeTokens")

    if type(currentTokens) ~= "number" then
        currentTokens = 0
    end

    player:SetAttribute("KnowledgeTokens", currentTokens + amount)
end

local function removePlayerFromQueues(player: Player)
    for _, queuedPlayers in pairs(queues) do
        for index = #queuedPlayers, 1, -1 do
            if queuedPlayers[index] == player then
                table.remove(queuedPlayers, index)
            end
        end
    end
end

local function startQueueCountdown(scenarioId: string)
    if queueCountdowns[scenarioId] then
        return
    end

    local scenario = scenarioById[scenarioId]

    if not scenario then
        return
    end

    queueCountdowns[scenarioId] = true

    task.spawn(function()
        task.wait(scenario.CountdownSeconds)
        queueCountdowns[scenarioId] = nil

        if not activeSessions[scenarioId] then
            startSession(scenarioId)
        end
    end)
end

local function getArenaFolder(scenarioId: string): Folder?
    local arenasFolder = Workspace:FindFirstChild("GeneratedBattles")

    if not arenasFolder then
        return nil
    end

    local arenaFolder = arenasFolder:FindFirstChild(scenarioId)

    if arenaFolder and arenaFolder:IsA("Folder") then
        return arenaFolder
    end

    return nil
end

local function getAnchors(container: Instance, childName: string): { BasePart }
    local results = {}
    local child = container:FindFirstChild(childName)

    if not child then
        return results
    end

    for _, descendant in ipairs(child:GetChildren()) do
        if descendant:IsA("BasePart") then
            table.insert(results, descendant)
        end
    end

    table.sort(results, function(a, b)
        return a.Name < b.Name
    end)

    return results
end

local function getAveragePosition(parts: { BasePart }): Vector3?
    if #parts == 0 then
        return nil
    end

    local total = Vector3.zero

    for _, part in ipairs(parts) do
        total += part.Position
    end

    return total / #parts
end

local function getAverageVector(values: { Vector3 }): Vector3?
    if #values == 0 then
        return nil
    end

    local total = Vector3.zero

    for _, value in ipairs(values) do
        total += value
    end

    return total / #values
end

local function getTeamAdvanceVector(scenario, teamId: string): Vector3
    return scenario.Teams[1].Id == teamId and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0)
end

local function buildFormationPositions(scenario, teamId: string, count: number, dummyAnchors: { BasePart }, spawnAnchors: { BasePart }): { Vector3 }
    local results = {}
    local basePosition = getAveragePosition(dummyAnchors) or getAveragePosition(spawnAnchors)

    if not basePosition and scenario.SpawnPositions and scenario.SpawnPositions[teamId] and #scenario.SpawnPositions[teamId] > 0 then
        basePosition = getAverageVector(scenario.SpawnPositions[teamId])
    end

    if not basePosition then
        basePosition = Vector3.zero
    end

    local advance = getTeamAdvanceVector(scenario, teamId)
    local sideways = Vector3.new(0, 0, 1)
    local columnOffsets = { 0, -1, 1, -2, 2, -3 }
    local rowSpacing = 9.5
    local columnSpacing = 10.5

    for index = 1, count do
        local row = math.floor((index - 1) / #columnOffsets)
        local column = columnOffsets[((index - 1) % #columnOffsets) + 1]
        local lateralOffset = sideways * (column * columnSpacing)
        local depthOffset = advance * (-row * rowSpacing)
        local stagger = advance * (((index % 2 == 0) and 1 or -1) * 0.8)
        table.insert(results, basePosition + lateralOffset + depthOffset + stagger)
    end

    return results
end

local function getDummyBotStyle(formationIndex: number, teamSize: number): string
    local row = math.floor((formationIndex - 1) / 6)

    if row >= 2 and (formationIndex % 2 == 0 or formationIndex > math.floor(teamSize * 0.6)) then
        return "Archer"
    end

    return "Melee"
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

local function teleportCharacterToAnchor(character: Model, anchor: BasePart)
    character:PivotTo(anchor.CFrame * CFrame.new(0, 4, 0))
end

local function createDummy(parent: Instance, name: string, teamId: string, scenarioId: string, position: Vector3, accentColor: Color3, isCommander: boolean?, commanderHealth: number?, botStyle: string?): Model
    local scale = isCommander and 1.45 or 1
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("BattleTeam", teamId)
    model:SetAttribute("ScenarioId", scenarioId)
    model:SetAttribute("BattleCommander", isCommander == true)
    model:SetAttribute("BotStyle", botStyle or "Melee")
    model.Parent = parent

    local limbs = {}

    local function createVisualPart(partName: string, size: Vector3, color: Color3, material: Enum.Material, cframe: CFrame): Part
        local part = Instance.new("Part")
        part.Name = partName
        part.Size = size
        part.Color = color
        part.Material = material
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CFrame = cframe
        part.Parent = model

        return part
    end

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1) * scale
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = false
    root.CFrame = CFrame.new(position + Vector3.new(0, 3 * scale, 0))
    root.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2.4, 2.8, 1.35) * scale
    torso.Anchored = true
    torso.Color = accentColor
    torso.Material = Enum.Material.Fabric
    torso.CFrame = CFrame.new(position + Vector3.new(0, 3.1 * scale, 0))
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2, 2, 2) * scale
    head.Anchored = true
    head.Color = Color3.fromRGB(232, 201, 167)
    head.CFrame = CFrame.new(position + Vector3.new(0, 5.2 * scale, 0))
    head.Parent = model

    local wrap = Instance.new("Part")
    wrap.Name = "HeadWrap"
    wrap.Shape = Enum.PartType.Ball
    wrap.Size = Vector3.new(2.15, 0.9, 2.15) * scale
    wrap.Anchored = true
    wrap.Color = isCommander and Color3.fromRGB(106, 58, 35) or accentColor
    wrap.Material = Enum.Material.Fabric
    wrap.CFrame = CFrame.new(position + Vector3.new(0, 5.88 * scale, 0))
    wrap.Parent = model

    createVisualPart("ShoulderMantle", Vector3.new(3.2, 0.55, 1.8) * scale, isCommander and Color3.fromRGB(132, 78, 52) or Color3.fromRGB(
        math.clamp(math.floor(accentColor.R * 255) + 24, 0, 255),
        math.clamp(math.floor(accentColor.G * 255) + 20, 0, 255),
        math.clamp(math.floor(accentColor.B * 255) + 18, 0, 255)
    ), Enum.Material.Fabric, CFrame.new(position + Vector3.new(0, 4.1 * scale, 0)))
    createVisualPart("WaistBelt", Vector3.new(2.7, 0.32, 1.5) * scale, Color3.fromRGB(114, 79, 48), Enum.Material.Fabric, CFrame.new(position + Vector3.new(0, 2.25 * scale, 0)))
    createVisualPart("RobeSkirt", Vector3.new(2.9, 2.2, 1.8) * scale, accentColor, Enum.Material.Fabric, CFrame.new(position + Vector3.new(0, 1.42 * scale, 0)))
    createVisualPart("TurbanTail", Vector3.new(0.35, 1.7, 0.75) * scale, wrap.Color, Enum.Material.Fabric, CFrame.new(position + Vector3.new(-0.5, 4.85, 0.85) * scale) * CFrame.Angles(math.rad(18), 0, math.rad(10)))
    createVisualPart("SandalLeft", Vector3.new(0.72, 0.22, 1.18) * scale, Color3.fromRGB(96, 67, 43), Enum.Material.Fabric, CFrame.new(position + Vector3.new(-0.5, 0.05, 0.1) * scale))
    createVisualPart("SandalRight", Vector3.new(0.72, 0.22, 1.18) * scale, Color3.fromRGB(96, 67, 43), Enum.Material.Fabric, CFrame.new(position + Vector3.new(0.5, 0.05, 0.1) * scale))

    for partName, offset in pairs({
        ["Left Arm"] = Vector3.new(-1.5, 3, 0),
        ["Right Arm"] = Vector3.new(1.5, 3, 0),
        ["Left Leg"] = Vector3.new(-0.5, 1, 0),
        ["Right Leg"] = Vector3.new(0.5, 1, 0),
    }) do
        local part = Instance.new("Part")
        part.Name = partName
        part.Shape = Enum.PartType.Cylinder
        part.Size = Vector3.new(1, 2, 1) * scale
        part.Anchored = true
        part.Color = accentColor
        part.Material = Enum.Material.Fabric
        part.CFrame = CFrame.new(position + offset * scale) * CFrame.Angles(0, 0, math.rad(90))
        part.Parent = model
        limbs[partName] = part
    end

    createVisualPart("ArmCuffLeft", Vector3.new(0.9, 0.24, 0.9) * scale, GOLD_ACCENT, Enum.Material.Metal, CFrame.new(position + Vector3.new(-1.5, 3.95, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)))
    createVisualPart("ArmCuffRight", Vector3.new(0.9, 0.24, 0.9) * scale, GOLD_ACCENT, Enum.Material.Metal, CFrame.new(position + Vector3.new(1.5, 3.95, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)))
    createVisualPart("LegWrapLeft", Vector3.new(0.8, 0.2, 0.8) * scale, Color3.fromRGB(214, 205, 183), Enum.Material.Fabric, CFrame.new(position + Vector3.new(-0.5, 0.85, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)))
    createVisualPart("LegWrapRight", Vector3.new(0.8, 0.2, 0.8) * scale, Color3.fromRGB(214, 205, 183), Enum.Material.Fabric, CFrame.new(position + Vector3.new(0.5, 0.85, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)))

    if (botStyle or "Melee") == "Archer" then
        createVisualPart("BowGrip", Vector3.new(0.16, 1.8, 0.16) * scale, Color3.fromRGB(112, 76, 46), Enum.Material.Wood, CFrame.new(position + Vector3.new(1.58, 3.05, -0.35) * scale))
        createVisualPart("BowUpper", Vector3.new(0.14, 2.2, 0.14) * scale, Color3.fromRGB(129, 90, 56), Enum.Material.Wood, CFrame.new(position + Vector3.new(1.94, 4.05, -0.35) * scale) * CFrame.Angles(0, 0, math.rad(24)))
        createVisualPart("BowLower", Vector3.new(0.14, 2.2, 0.14) * scale, Color3.fromRGB(129, 90, 56), Enum.Material.Wood, CFrame.new(position + Vector3.new(1.94, 2.05, -0.35) * scale) * CFrame.Angles(0, 0, math.rad(-24)))
        createVisualPart("BowString", Vector3.new(0.06, 4.2, 0.06) * scale, Color3.fromRGB(230, 223, 202), Enum.Material.SmoothPlastic, CFrame.new(position + Vector3.new(2.24, 3.05, -0.35) * scale))
        createVisualPart("QuiverBody", Vector3.new(0.82, 2.3, 0.82) * scale, Color3.fromRGB(110, 73, 44), Enum.Material.Fabric, CFrame.new(position + Vector3.new(-0.95, 3.2, 0.72) * scale) * CFrame.Angles(math.rad(24), 0, math.rad(24)))

        for arrowIndex, yOffset in ipairs({ 0.7, 1.0, 1.3 }) do
            createVisualPart(string.format("QuiverArrow_%d", arrowIndex), Vector3.new(0.1, 1.45, 0.1) * scale, Color3.fromRGB(205, 200, 191), Enum.Material.Metal, CFrame.new(position + Vector3.new(-0.95, 3.6 + yOffset, 0.72) * scale) * CFrame.Angles(math.rad(24), 0, math.rad(24)))
        end
    else
        createVisualPart("SwordHandle", Vector3.new(0.24, 1.2, 0.24) * scale, Color3.fromRGB(98, 66, 38), Enum.Material.Wood, CFrame.new(position + Vector3.new(1.62, 2.62, -0.2) * scale))
        createVisualPart("SwordGuard", Vector3.new(1.35, 0.16, 0.24) * scale, Color3.fromRGB(179, 149, 87), Enum.Material.Metal, CFrame.new(position + Vector3.new(1.62, 3.18, -0.2) * scale))
        createVisualPart("SwordBlade", Vector3.new(0.16, 2.8, 0.24) * scale, Color3.fromRGB(216, 216, 216), Enum.Material.Metal, CFrame.new(position + Vector3.new(1.62, 4.62, -0.2) * scale))

        if limbs["Left Arm"] then
            createVisualPart("ShieldPlate", Vector3.new(0.2, 2.4, 1.9) * scale, Color3.fromRGB(95, 72, 46), Enum.Material.WoodPlanks, CFrame.new(position + Vector3.new(-2.15, 3.05, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)))
            createVisualPart("ShieldBoss", Vector3.new(0.36, 0.66, 0.66) * scale, Color3.fromRGB(192, 160, 90), Enum.Material.Metal, CFrame.new(position + Vector3.new(-2.3, 3.05, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)))
        end
    end

    if isCommander then
        createVisualPart("CommanderShoulderLeft", Vector3.new(1.25, 0.5, 1.5) * scale, Color3.fromRGB(205, 165, 91), Enum.Material.Metal, CFrame.new(position + Vector3.new(-1.42, 4.2, 0) * scale))
        createVisualPart("CommanderShoulderRight", Vector3.new(1.25, 0.5, 1.5) * scale, Color3.fromRGB(205, 165, 91), Enum.Material.Metal, CFrame.new(position + Vector3.new(1.42, 4.2, 0) * scale))
        local cape = Instance.new("Part")
        cape.Name = "CommanderCape"
        cape.Size = Vector3.new(3.4, 4.2, 0.4) * scale
        cape.Anchored = true
        cape.CanCollide = false
        cape.Color = Color3.fromRGB(119, 60, 36)
        cape.Material = Enum.Material.Fabric
        cape.CFrame = CFrame.new(position + Vector3.new(0, 2.75 * scale, 0.95 * scale))
        cape.Parent = model

        local crest = Instance.new("Part")
        crest.Name = "CommanderCrest"
        crest.Size = Vector3.new(0.8, 1.6, 1.8) * scale
        crest.Anchored = true
        crest.Color = Color3.fromRGB(218, 173, 86)
        crest.Material = Enum.Material.Metal
        crest.CFrame = CFrame.new(position + Vector3.new(0, 6.45 * scale, 0))
        crest.Parent = model
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = commanderHealth or (isCommander and 240 or 90)
    humanoid.Health = humanoid.MaxHealth
    humanoid.DisplayName = name
    humanoid.Parent = model

    model.PrimaryPart = root

    return model
end

local function getHubReturnAnchor(): BasePart?
    local worldFolder = Workspace:FindFirstChild(TravelRoute.WorldFolderName)

    if not worldFolder then
        return nil
    end

    local teleportFolder = worldFolder:FindFirstChild("TeleportPoints")

    if not teleportFolder then
        return nil
    end

    local anchor = teleportFolder:FindFirstChild(TravelRoute.StartDestinationId)

    if anchor and anchor:IsA("BasePart") then
        return anchor
    end

    return nil
end

local function getSpectatorAnchor(arenaFolder: Folder): BasePart?
    local anchor = arenaFolder:FindFirstChild("SpectatorAnchor")

    if anchor and anchor:IsA("BasePart") then
        return anchor
    end

    return nil
end

local function setCharacterAttributes(character: Model, scenarioId: string?, teamId: string?)
    character:SetAttribute("ScenarioId", scenarioId)
    character:SetAttribute("BattleTeam", teamId)
end

local function clearCommanderVisuals(character: Model)
    local existingHighlight = character:FindFirstChild("CommanderHighlight")

    if existingHighlight then
        existingHighlight:Destroy()
    end

    local existingBadge = character:FindFirstChild("CommanderBadge")

    if existingBadge then
        existingBadge:Destroy()
    end
end

local function clearCombatantTag(character: Model)
    if CollectionService:HasTag(character, COMBATANT_TAG) then
        CollectionService:RemoveTag(character, COMBATANT_TAG)
    end

    character:SetAttribute("BattleCommander", nil)
    character:SetAttribute("BattleCommanderName", nil)
    clearCommanderVisuals(character)
end

local function applyCommanderVisuals(character: Model, label: string, color: Color3)
    clearCommanderVisuals(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = "CommanderHighlight"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 219, 128)
    highlight.FillTransparency = 0.72
    highlight.OutlineTransparency = 0.08
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return
    end

    local badge = Instance.new("BillboardGui")
    badge.Name = "CommanderBadge"
    badge.AlwaysOnTop = true
    badge.Size = UDim2.fromOffset(210, 54)
    badge.StudsOffset = Vector3.new(0, 7, 0)
    badge.Parent = character
    badge.Adornee = root

    local labelGui = Instance.new("TextLabel")
    labelGui.BackgroundColor3 = Color3.fromRGB(38, 28, 22)
    labelGui.BackgroundTransparency = 0.12
    labelGui.Size = UDim2.fromScale(1, 1)
    labelGui.Font = Enum.Font.GothamBold
    labelGui.Text = label
    labelGui.TextColor3 = Color3.fromRGB(255, 235, 185)
    labelGui.TextScaled = true
    labelGui.TextWrapped = true
    labelGui.Parent = badge

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = labelGui
end

local function tagCombatant(character: Model, isCommander: boolean?, commanderLabel: string?, color: Color3?)
    if not CollectionService:HasTag(character, COMBATANT_TAG) then
        CollectionService:AddTag(character, COMBATANT_TAG)
    end

    character:SetAttribute("BattleCommander", isCommander == true)
    character:SetAttribute("BattleCommanderName", isCommander and commanderLabel or nil)

    if isCommander then
        applyCommanderVisuals(character, commanderLabel or "Commander", color or Color3.fromRGB(180, 114, 64))
    else
        clearCommanderVisuals(character)
    end
end

local function clearPlayerBattleState(player: Player)
    playerToSession[player] = nil
    BattleLoadout.ClearForPlayer(player)
    player:SetAttribute("InBattle", false)
    player:SetAttribute("CurrentScenarioId", nil)
    player:SetAttribute("CurrentBattleTeam", nil)

    if player.Character then
        clearCombatantTag(player.Character)
        setCharacterAttributes(player.Character, nil, nil)
    end
end

local function returnPlayerToHub(player: Player, delaySeconds: number)
    task.delay(delaySeconds, function()
        if not player.Parent then
            return
        end

        local returnAnchor = getHubReturnAnchor()

        if not returnAnchor then
            return
        end

        local success = pcall(function()
            player:LoadCharacter()
        end)

        if not success then
            return
        end

        local readyCharacter = getReadyCharacter(player, 10)

        if readyCharacter then
            teleportCharacterToAnchor(readyCharacter, returnAnchor)
        end
    end)
end

local function getTeamDisplayName(session, teamId: string): string
    for _, team in ipairs(session.Scenario.Teams) do
        if team.Id == teamId then
            return team.DisplayName
        end
    end

    return teamId
end

local function getHumanLivingCount(session, teamId: string): number
    local living = 0

    for _, entry in ipairs(session.Teams[teamId]) do
        if entry.Alive and entry.Kind == "Player" then
            living += 1
        end
    end

    return living
end

local function cleanupSession(session)
    for _, connection in ipairs(session.Connections) do
        connection:Disconnect()
    end

    for _, dummy in ipairs(session.Dummies) do
        if dummy.Parent then
            clearCombatantTag(dummy)
            dummy:Destroy()
        end
    end
end

local function sendSummary(player: Player, scenario, winnerText: string)
    showBattleSummary:FireClient(player, {
        ScenarioName = scenario.DisplayName,
        WinnerText = winnerText,
        SummaryTitle = scenario.StorySummary.Title,
        SummaryLines = scenario.StorySummary.Lines,
    })
end

local function smoothStep(alpha: number): number
    local clamped = math.clamp(alpha, 0, 1)

    return clamped * clamped * (3 - 2 * clamped)
end

local function tweenModelTo(model: Model, targetCFrame: CFrame, duration: number)
    local startCFrame = model:GetPivot()
    local elapsed = 0

    while elapsed < duration and model.Parent do
        elapsed += RunService.Heartbeat:Wait()
        local alpha = smoothStep(elapsed / duration)
        model:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
    end

    if model.Parent then
        model:PivotTo(targetCFrame)
    end
end

local function getReenactmentPart(arenaFolder: Folder, folderName: string, partName: string): BasePart?
    local reenactmentFolder = arenaFolder:FindFirstChild("Reenactment")
    local innerFolder = reenactmentFolder and reenactmentFolder:FindFirstChild(folderName)
    local part = innerFolder and innerFolder:FindFirstChild(partName)

    if part and part:IsA("BasePart") then
        return part
    end

    return nil
end

local function getBriefingPart(arenaFolder: Folder, folderName: string, partName: string): BasePart?
    local briefingFolder = arenaFolder:FindFirstChild("Briefing")
    local innerFolder = briefingFolder and briefingFolder:FindFirstChild(folderName)
    local part = innerFolder and innerFolder:FindFirstChild(partName)

    if part and part:IsA("BasePart") then
        return part
    end

    return nil
end

local function getReenactmentActor(arenaFolder: Folder, actorName: string): Model?
    local reenactmentFolder = arenaFolder:FindFirstChild("Reenactment")
    local actorsFolder = reenactmentFolder and reenactmentFolder:FindFirstChild("Actors")
    local actor = actorsFolder and actorsFolder:FindFirstChild(actorName)

    if actor and actor:IsA("Model") then
        return actor
    end

    return nil
end

local function getReenactmentActorsWithPrefix(arenaFolder: Folder, prefix: string): { Model }
    local results = {}
    local reenactmentFolder = arenaFolder:FindFirstChild("Reenactment")
    local actorsFolder = reenactmentFolder and reenactmentFolder:FindFirstChild("Actors")

    if not actorsFolder then
        return results
    end

    for _, child in ipairs(actorsFolder:GetChildren()) do
        if child:IsA("Model") and string.sub(child.Name, 1, #prefix) == prefix then
            table.insert(results, child)
        end
    end

    table.sort(results, function(a, b)
        return a.Name < b.Name
    end)

    return results
end

local function tweenPartTo(part: BasePart, targetCFrame: CFrame, duration: number)
    local startCFrame = part.CFrame
    local elapsed = 0

    while elapsed < duration and part.Parent do
        elapsed += RunService.Heartbeat:Wait()
        local alpha = smoothStep(elapsed / duration)
        part.CFrame = startCFrame:Lerp(targetCFrame, alpha)
    end

    if part.Parent then
        part.CFrame = targetCFrame
    end
end

local function animateBriefing(session)
    local medinaMarker = getBriefingPart(session.Arena, "Markers", "MedinaMapMarker")
    local makkahMarker = getBriefingPart(session.Arena, "Markers", "MakkahMapMarker")
    local medinaTarget = getBriefingPart(session.Arena, "Markers", "MedinaMapTarget")
    local makkahTarget = getBriefingPart(session.Arena, "Markers", "MakkahMapTarget")

    if not medinaMarker or not makkahMarker or not medinaTarget or not makkahTarget then
        return
    end

    local medinaStart = medinaMarker.CFrame
    local makkahStart = makkahMarker.CFrame

    medinaMarker.CFrame = medinaStart
    makkahMarker.CFrame = makkahStart

    task.spawn(function()
        task.wait(3)
        tweenPartTo(medinaMarker, medinaTarget.CFrame, 4)
        task.wait(3)
        tweenPartTo(medinaMarker, medinaStart, 1.2)
    end)

    task.spawn(function()
        task.wait(3.7)
        tweenPartTo(makkahMarker, makkahTarget.CFrame, 4.2)
        task.wait(2.2)
        tweenPartTo(makkahMarker, makkahStart, 1.2)
    end)
end

local function animateReenactment(session)
    local scenarioId = session.Scenario.Id
    local medinaLead = getReenactmentActor(session.Arena, "MedinaLead")
    local medinaSupport = getReenactmentActor(session.Arena, "MedinaSupport")
    local makkahLead = getReenactmentActor(session.Arena, "MakkahLead")
    local makkahSupport = getReenactmentActor(session.Arena, "MakkahSupport")
    local makkahCommander = getReenactmentActor(session.Arena, "MakkahCommander")

    if not medinaLead or not medinaSupport or not makkahLead or not makkahSupport then
        return
    end

    local medinaLeadStart = getReenactmentPart(session.Arena, "Marks", "MedinaLeadStart")
    local medinaSupportStart = getReenactmentPart(session.Arena, "Marks", "MedinaSupportStart")
    local medinaLeadAdvance = getReenactmentPart(session.Arena, "Marks", "MedinaLeadAdvance")
    local medinaSupportAdvance = getReenactmentPart(session.Arena, "Marks", "MedinaSupportAdvance")
    local makkahLeadStart = getReenactmentPart(session.Arena, "Marks", "MakkahLeadStart")
    local makkahSupportStart = getReenactmentPart(session.Arena, "Marks", "MakkahSupportStart")
    local makkahLeadRetreat = getReenactmentPart(session.Arena, "Marks", "MakkahLeadRetreat")
    local makkahSupportRetreat = getReenactmentPart(session.Arena, "Marks", "MakkahSupportRetreat")
    local makkahCommanderStart = getReenactmentPart(session.Arena, "Marks", "MakkahCommanderStart")
    local makkahCommanderAdvance = getReenactmentPart(session.Arena, "Marks", "MakkahCommanderAdvance")
    local makkahCommanderDefeat = getReenactmentPart(session.Arena, "Marks", "MakkahCommanderDefeat")

    if not medinaLeadStart or not medinaSupportStart or not medinaLeadAdvance or not medinaSupportAdvance or not makkahLeadStart or not makkahSupportStart or not makkahLeadRetreat or not makkahSupportRetreat then
        return
    end

    medinaLead:PivotTo(medinaLeadStart.CFrame)
    medinaSupport:PivotTo(medinaSupportStart.CFrame)
    makkahLead:PivotTo(makkahLeadStart.CFrame)
    makkahSupport:PivotTo(makkahSupportStart.CFrame)

    if makkahCommander and makkahCommanderStart then
        makkahCommander:PivotTo(makkahCommanderStart.CFrame)
    end

    local medinaRanks = getReenactmentActorsWithPrefix(session.Arena, "MedinaRank")
    local makkahRanks = getReenactmentActorsWithPrefix(session.Arena, "MakkahRank")

    for index, actor in ipairs(medinaRanks) do
        local startCFrame = actor:GetPivot()
        actor:PivotTo(startCFrame)
        task.spawn(function()
            task.wait(1.5 + index * 0.25)
            tweenModelTo(actor, startCFrame * CFrame.new(22, 0, index % 2 == 0 and -3 or 3), 2.2)
            task.wait(4)
            tweenModelTo(actor, startCFrame, 1.2)
        end)
    end

    for index, actor in ipairs(makkahRanks) do
        local startCFrame = actor:GetPivot()
        actor:PivotTo(startCFrame)
        task.spawn(function()
            task.wait(3 + index * 0.18)
            local retreatX = scenarioId == "uhud" and -18 or 24
            tweenModelTo(actor, startCFrame * CFrame.new(retreatX, 0, index % 2 == 0 and 8 or -8), 2.4)
            task.wait(3)
            tweenModelTo(actor, startCFrame, 1.2)
        end)
    end

    task.spawn(function()
        task.wait(1)
        tweenModelTo(medinaLead, medinaLeadAdvance.CFrame, 1.6)
    end)

    task.spawn(function()
        task.wait(1.2)
        tweenModelTo(medinaSupport, medinaSupportAdvance.CFrame, 1.8)
    end)

    if scenarioId == "badr" then
        task.spawn(function()
            task.wait(3.6)
            tweenModelTo(makkahLead, makkahLeadRetreat.CFrame, 1.5)
        end)

        task.spawn(function()
            task.wait(3.9)
            tweenModelTo(makkahSupport, makkahSupportRetreat.CFrame, 1.7)
        end)
    else
        task.spawn(function()
            task.wait(3)
            tweenModelTo(makkahLead, makkahLeadRetreat.CFrame, 1.4)
        end)

        task.spawn(function()
            task.wait(3.3)
            tweenModelTo(makkahSupport, makkahSupportRetreat.CFrame, 1.6)
        end)
    end

    if makkahCommander and makkahCommanderAdvance and makkahCommanderDefeat then
        task.spawn(function()
            task.wait(2.2)
            tweenModelTo(makkahCommander, makkahCommanderAdvance.CFrame, 2)
            task.wait(2.8)
            tweenModelTo(makkahCommander, makkahCommanderDefeat.CFrame * CFrame.Angles(0, 0, math.rad(68)), 1.8)
        end)
    end
end

local function buildReenactmentPayload(session, winnerText: string)
    local scenario = session.Scenario
    local scenePayloads = {}

    if not scenario.Reenactment or not scenario.Reenactment.Scenes then
        return nil
    end

    for _, scene in ipairs(scenario.Reenactment.Scenes) do
        local cameraPart = getReenactmentPart(session.Arena, "Cameras", scene.CameraName)

        if cameraPart then
            table.insert(scenePayloads, {
                Title = scene.Title,
                Body = scene.Body,
                DurationSeconds = scene.DurationSeconds,
                CameraCFrame = cameraPart.CFrame,
            })
        end
    end

    if #scenePayloads == 0 then
        return nil
    end

    return {
        Kind = "Reenactment",
        ScenarioName = scenario.DisplayName,
        WinnerText = winnerText,
        IntroTitle = scenario.Reenactment.IntroTitle,
        Scenes = scenePayloads,
    }
end

local function buildBriefingPayload(session)
    local scenario = session.Scenario
    local scenePayloads = {}

    if not scenario.Briefing or not scenario.Briefing.Scenes then
        return nil
    end

    for _, scene in ipairs(scenario.Briefing.Scenes) do
        local cameraPart = getBriefingPart(session.Arena, "Cameras", scene.CameraName)

        if cameraPart then
            table.insert(scenePayloads, {
                Title = scene.Title,
                Body = scene.Body,
                DurationSeconds = scene.DurationSeconds,
                CameraCFrame = cameraPart.CFrame,
                FieldOfView = scene.FieldOfView,
            })
        end
    end

    if #scenePayloads == 0 then
        return nil
    end

    return {
        Kind = "Briefing",
        ScenarioName = scenario.DisplayName,
        WinnerText = "",
        IntroTitle = scenario.Briefing.IntroTitle,
        Scenes = scenePayloads,
    }
end

local function freezePlayersForCutscene(playersList)
    for _, player in ipairs(playersList) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false
        end
    end
end

local function unfreezePlayersForBattle(playersList)
    for _, player in ipairs(playersList) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            humanoid.AutoRotate = true
        end
    end
end

local function respawnPlayerToSpectator(player: Player, session)
    if session.Ended or not player.Parent then
        return
    end

    local spectatorAnchor = getSpectatorAnchor(session.Arena)

    if not spectatorAnchor then
        return
    end

    BattleLoadout.ClearForPlayer(player)
    player:SetAttribute("InBattle", false)
    player:SetAttribute("CurrentBattleTeam", nil)

    local success = pcall(function()
        player:LoadCharacter()
    end)

    if not success then
        return
    end

    local character = getReadyCharacter(player, 10)

    if not character then
        return
    end

    setCharacterAttributes(character, nil, nil)
    character:PivotTo(spectatorAnchor.CFrame)
end

local function endSession(session, winnerTeamId: string?, reason: string)
    if session.Ended then
        return
    end

    session.Ended = true
    activeSessions[session.Scenario.Id] = nil

    local winnerText = "Round complete."

    if winnerTeamId and reason ~= "" then
        winnerText = reason
    elseif winnerTeamId then
        for _, team in ipairs(session.Scenario.Teams) do
            if team.Id == winnerTeamId then
                winnerText = string.format("%s wins the round.", team.DisplayName)
                break
            end
        end
    elseif reason ~= "" then
        winnerText = reason
    end

    task.spawn(function()
        freezePlayersForCutscene(session.Players)

        local payload = buildReenactmentPayload(session, winnerText)
        local totalDuration = 0

        if payload then
            animateReenactment(session)

            for _, scene in ipairs(payload.Scenes) do
                totalDuration += scene.DurationSeconds or 5
            end

            for _, player in ipairs(session.Players) do
                playReenactment:FireClient(player, payload)
            end
        else
            totalDuration = 6

            for _, player in ipairs(session.Players) do
                sendSummary(player, session.Scenario, winnerText)
            end
        end

        task.wait(totalDuration + 0.4)

        for _, player in ipairs(session.Players) do
            awardKnowledgeTokens(player, session.Scenario.Rewards.KnowledgeTokens or 0, string.format("%s complete", session.Scenario.DisplayName))
            clearPlayerBattleState(player)
            returnPlayerToHub(player, 0.15)
        end

        cleanupSession(session)

        if #queues[session.Scenario.Id] > 0 then
            startQueueCountdown(session.Scenario.Id)
        end
    end)
end

local function evaluateVictory(session)
    local firstTeamId = session.Scenario.Teams[1].Id
    local secondTeamId = session.Scenario.Teams[2].Id
    local firstStartedHumans = session.InitialHumanCounts[firstTeamId] or 0
    local secondStartedHumans = session.InitialHumanCounts[secondTeamId] or 0

    local firstLivingHumans = getHumanLivingCount(session, firstTeamId)
    local secondLivingHumans = getHumanLivingCount(session, secondTeamId)

    if firstStartedHumans > 0 and secondStartedHumans > 0 then
        if firstLivingHumans <= 0 and secondLivingHumans <= 0 then
            endSession(session, nil, "Both player teams fell. The round ended in a draw.")
        elseif firstLivingHumans <= 0 then
            endSession(session, secondTeamId, string.format("%s players held the field after the opposing players fell.", getTeamDisplayName(session, secondTeamId)))
        elseif secondLivingHumans <= 0 then
            endSession(session, firstTeamId, string.format("%s players held the field after the opposing players fell.", getTeamDisplayName(session, firstTeamId)))
        end

        return
    end

    if firstStartedHumans > 0 and firstLivingHumans <= 0 then
        endSession(session, secondTeamId, string.format("%s players were defeated before finishing the objective.", getTeamDisplayName(session, firstTeamId)))
        return
    end

    if secondStartedHumans > 0 and secondLivingHumans <= 0 then
        endSession(session, firstTeamId, string.format("%s players were defeated before finishing the objective.", getTeamDisplayName(session, secondTeamId)))
    end
end

local function getCommanderConfig(session)
    return session.Scenario.Commander
end

local function shouldAssignCommander(session, teamId: string): boolean
    local commander = getCommanderConfig(session)

    if not commander then
        return false
    end

    return commander.TeamId == teamId and not session.CommanderEntry
end

local function configureCommanderEntry(session, entry, teamAccentColor: Color3)
    local commander = getCommanderConfig(session)

    if not commander or not entry.IsCommander then
        return
    end

    session.CommanderEntry = entry

    if entry.Humanoid then
        entry.Humanoid.MaxHealth = commander.Health or entry.Humanoid.MaxHealth
        entry.Humanoid.Health = entry.Humanoid.MaxHealth
        entry.Humanoid.DisplayName = commander.DisplayName or "Commander"
    end

    local character = entry.Model or (entry.Player and entry.Player.Character)

    if character and character:IsA("Model") then
        tagCombatant(character, true, commander.DisplayName or "Commander", teamAccentColor)
    end

    if entry.Player then
        sendMessage({ entry.Player }, string.format("You are the %s boss. If you fall, the scenario ends.", commander.DisplayName or "opposing commander"), 6)
    end
end

local function registerEntry(session, teamId: string, entry)
    entry.TeamId = teamId
    table.insert(session.Teams[teamId], entry)

    local teamAccentColor = Color3.fromRGB(180, 114, 64)

    for _, team in ipairs(session.Scenario.Teams) do
        if team.Id == teamId then
            teamAccentColor = team.AccentColor
            break
        end
    end

    local character = entry.Model or (entry.Player and entry.Player.Character)

    if character and character:IsA("Model") and not entry.IsCommander then
        tagCombatant(character, false, nil, nil)
    end

    configureCommanderEntry(session, entry, teamAccentColor)

    local diedConnection = entry.Humanoid.Died:Connect(function()
        entry.Alive = false

        if entry.IsCommander then
            local commander = getCommanderConfig(session)
            local winnerTeamId = commander and commander.DefeatedWinnerTeamId or nil
            local message = commander and commander.DefeatedMessage or "The commander was defeated. The scenario is complete."

            endSession(session, winnerTeamId, message)
            return
        end

        if entry.Kind == "Player" and entry.Player then
            sendMessage({ entry.Player }, "You fell in battle. You will watch the reenactment from the ridge.", 4)
            task.spawn(function()
                task.wait(1.25)
                respawnPlayerToSpectator(entry.Player, session)
            end)
        end

        evaluateVictory(session)
    end)

    table.insert(session.Connections, diedConnection)
end

startSession = function(scenarioId: string)
    if activeSessions[scenarioId] then
        return
    end

    local scenario = scenarioById[scenarioId]
    local arenaFolder = getArenaFolder(scenarioId)

    if not scenario or not arenaFolder then
        return
    end

    local queuedPlayers = {}
    local maxHumans = scenario.PlayersPerTeam * 2

    while #queues[scenarioId] > 0 and #queuedPlayers < maxHumans do
        table.insert(queuedPlayers, table.remove(queues[scenarioId], 1))
    end

    if #queuedPlayers < scenario.MinPlayersToLaunch then
        return
    end

    local session = {
        Scenario = scenario,
        Arena = arenaFolder,
        Players = queuedPlayers,
        Teams = {
            [scenario.Teams[1].Id] = {},
            [scenario.Teams[2].Id] = {},
        },
        InitialHumanCounts = {
            [scenario.Teams[1].Id] = 0,
            [scenario.Teams[2].Id] = 0,
        },
        Dummies = {},
        Connections = {},
        Ended = false,
        CommanderEntry = nil,
    }

    activeSessions[scenarioId] = session

    local spawnFolder = arenaFolder:FindFirstChild("Spawns")
    local dummySpawnFolder = arenaFolder:FindFirstChild("DummySpawns")

    if not spawnFolder then
        endSession(session, nil, "The arena is missing spawn points.")
        return
    end

    local teamSpawnAnchors = {
        [scenario.Teams[1].Id] = getAnchors(spawnFolder, scenario.Teams[1].Id),
        [scenario.Teams[2].Id] = getAnchors(spawnFolder, scenario.Teams[2].Id),
    }

    for index, player in ipairs(queuedPlayers) do
        local team = scenario.Teams[((index - 1) % #scenario.Teams) + 1]
        local anchors = teamSpawnAnchors[team.Id]
        local anchor = nil

        if #anchors > 0 then
            anchor = anchors[((#session.Teams[team.Id]) % #anchors) + 1]
        end

        local character = getCharacter(player)

        if character and anchor then
            teleportCharacterToAnchor(character, anchor)
            setCharacterAttributes(character, scenario.Id, team.Id)
            player:SetAttribute("InBattle", true)
            player:SetAttribute("CurrentScenarioId", scenario.Id)
            player:SetAttribute("CurrentBattleTeam", team.Id)
            BattleLoadout.GiveToPlayer(player)

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
                humanoid.AutoRotate = true

                registerEntry(session, team.Id, {
                    Kind = "Player",
                    Player = player,
                    Model = character,
                    Humanoid = humanoid,
                    Alive = true,
                    IsCommander = shouldAssignCommander(session, team.Id),
                })
                session.InitialHumanCounts[team.Id] += 1
                playerToSession[player] = session
            end
        end
    end

    for _, team in ipairs(scenario.Teams) do
        local dummyAnchors = dummySpawnFolder and getAnchors(dummySpawnFolder, team.Id) or {}
        local formationPositions = buildFormationPositions(scenario, team.Id, scenario.PlayersPerTeam, dummyAnchors, teamSpawnAnchors[team.Id])

        while #session.Teams[team.Id] < scenario.PlayersPerTeam do
            local formationIndex = #session.Teams[team.Id] + 1
            local dummyPosition = formationPositions[formationIndex]

            if not dummyPosition then
                break
            end

            local isCommander = shouldAssignCommander(session, team.Id)
            local commander = getCommanderConfig(session)
            local botStyle = isCommander and "Melee" or getDummyBotStyle(formationIndex, scenario.PlayersPerTeam)
            local dummyName = (isCommander and commander and commander.DisplayName) or string.format("%s %s %d", team.DisplayName, botStyle, formationIndex)
            local dummy = createDummy(arenaFolder, dummyName, team.Id, scenario.Id, dummyPosition, team.AccentColor, isCommander, commander and commander.Health or nil, botStyle)
            local humanoid = dummy:FindFirstChildOfClass("Humanoid")

            if humanoid then
                registerEntry(session, team.Id, {
                    Kind = "Dummy",
                    Model = dummy,
                    Humanoid = humanoid,
                    Alive = true,
                    IsCommander = isCommander,
                    BotStyle = botStyle,
                    FormationIndex = formationIndex,
                    LastAttackAt = 0,
                })
                table.insert(session.Dummies, dummy)
            end
        end
    end

    freezePlayersForCutscene(queuedPlayers)

    local briefingPayload = buildBriefingPayload(session)
    local briefingDuration = 0

    if briefingPayload then
        animateBriefing(session)

        for _, scene in ipairs(briefingPayload.Scenes) do
            briefingDuration += scene.DurationSeconds or 5
        end

        for _, player in ipairs(queuedPlayers) do
            playReenactment:FireClient(player, briefingPayload)
        end
    end

    task.delay(briefingDuration + 0.4, function()
        if session.Ended then
            return
        end

        unfreezePlayersForBattle(queuedPlayers)
        sendMessage(queuedPlayers, string.format("%s begins now. Fight in first person with your sword and bow, then watch the reenactment at the end.", scenario.DisplayName), 6)

        if scenario.Commander then
            sendMessage(queuedPlayers, string.format("Boss objective: defeat the %s to end the scenario.", scenario.Commander.DisplayName), 6)
        end

        sendMessage(queuedPlayers, string.format("Field strength: up to %d fighters per side. AI fills empty slots, but players still decide the round.", scenario.PlayersPerTeam), 6)
        sendMessage(queuedPlayers, "Combat tips: left click to attack, hold and release the bow to fire, and right click to raise your shield block.", 6)
        BattleBots.Start(session)

        task.delay(scenario.RoundDurationSeconds, function()
            if not session.Ended then
                endSession(session, nil, "Time is up. The round has ended.")
            end
        end)
    end)
end

local function joinQueue(player: Player, scenarioId: string)
    local scenario = scenarioById[scenarioId]

    if not scenario then
        return
    end

    if player:GetAttribute("InStory") == true then
        sendMessage({ player }, "Finish your sahabi playthrough before joining a battle.", 3)
        return
    end

    if playerToSession[player] then
        sendMessage({ player }, "You are already inside a battle round.", 3)
        return
    end

    if activeSessions[scenarioId] then
        sendMessage({ player }, string.format("%s is already running. You are queued for the next round.", scenario.DisplayName), 4)
    end

    for _, queuedPlayer in ipairs(queues[scenarioId]) do
        if queuedPlayer == player then
            sendMessage({ player }, string.format("You are already queued for %s.", scenario.DisplayName), 3)
            return
        end
    end

    removePlayerFromQueues(player)
    table.insert(queues[scenarioId], player)
    sendMessage({ player }, string.format("Queued for %s. The round will begin soon.", scenario.DisplayName), 4)
    startQueueCountdown(scenarioId)
end

requestJoinBattle.OnServerEvent:Connect(function(player: Player, scenarioId: string)
    if typeof(scenarioId) == "string" then
        joinQueue(player, scenarioId)
    end
end)

local function connectBattlePrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        local scenarioId = prompt:GetAttribute("ScenarioId")

        if typeof(scenarioId) == "string" then
            joinQueue(player, scenarioId)
        end
    end)
end

task.spawn(function()
    local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName, 10)

    if not worldFolder then
        return
    end

    for _, descendant in ipairs(worldFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant:GetAttribute("PromptAction") == "JoinBattle" then
            connectBattlePrompt(descendant)
        end
    end

    worldFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") and descendant:GetAttribute("PromptAction") == "JoinBattle" then
            connectBattlePrompt(descendant)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerFromQueues(player)

    local session = playerToSession[player]

    if session then
        for _, team in ipairs(session.Scenario.Teams) do
            for _, entry in ipairs(session.Teams[team.Id]) do
                if entry.Player == player then
                    entry.Alive = false
                end
            end
        end

        evaluateVictory(session)
    end
end)
