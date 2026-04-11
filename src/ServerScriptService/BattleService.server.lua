--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattleScenarios = require(Shared.Data.BattleScenarios)
local TravelRoute = require(Shared.Data.TravelRoute)
local BattleLoadout = require(script.Parent.Modules.BattleLoadout)

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

local function createDummy(parent: Instance, name: string, teamId: string, scenarioId: string, position: Vector3, accentColor: Color3): Model
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("BattleTeam", teamId)
    model:SetAttribute("ScenarioId", scenarioId)
    model.Parent = parent

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = false
    root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    root.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Anchored = true
    torso.Color = accentColor
    torso.Material = Enum.Material.Fabric
    torso.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Anchored = true
    head.Color = Color3.fromRGB(232, 201, 167)
    head.CFrame = CFrame.new(position + Vector3.new(0, 4.5, 0))
    head.Parent = model

    for partName, offset in pairs({
        ["Left Arm"] = Vector3.new(-1.5, 3, 0),
        ["Right Arm"] = Vector3.new(1.5, 3, 0),
        ["Left Leg"] = Vector3.new(-0.5, 1, 0),
        ["Right Leg"] = Vector3.new(0.5, 1, 0),
    }) do
        local part = Instance.new("Part")
        part.Name = partName
        part.Size = Vector3.new(1, 2, 1)
        part.Anchored = true
        part.Color = accentColor
        part.Material = Enum.Material.Fabric
        part.CFrame = CFrame.new(position + offset)
        part.Parent = model
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 90
    humanoid.Health = 90
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

local function clearPlayerBattleState(player: Player)
    playerToSession[player] = nil
    BattleLoadout.ClearForPlayer(player)
    player:SetAttribute("InBattle", false)
    player:SetAttribute("CurrentScenarioId", nil)
    player:SetAttribute("CurrentBattleTeam", nil)

    if player.Character then
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

local function getLivingCount(session, teamId: string): number
    local living = 0

    for _, entry in ipairs(session.Teams[teamId]) do
        if entry.Alive then
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

local function tweenModelTo(model: Model, targetCFrame: CFrame, duration: number)
    local startCFrame = model:GetPivot()
    local elapsed = 0

    while elapsed < duration and model.Parent do
        elapsed += RunService.Heartbeat:Wait()
        local alpha = math.clamp(elapsed / duration, 0, 1)
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
        local alpha = math.clamp(elapsed / duration, 0, 1)
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

    if not medinaLeadStart or not medinaSupportStart or not medinaLeadAdvance or not medinaSupportAdvance or not makkahLeadStart or not makkahSupportStart or not makkahLeadRetreat or not makkahSupportRetreat then
        return
    end

    medinaLead:PivotTo(medinaLeadStart.CFrame)
    medinaSupport:PivotTo(medinaSupportStart.CFrame)
    makkahLead:PivotTo(makkahLeadStart.CFrame)
    makkahSupport:PivotTo(makkahSupportStart.CFrame)

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

    if winnerTeamId then
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

    local firstLiving = getLivingCount(session, firstTeamId)
    local secondLiving = getLivingCount(session, secondTeamId)

    if firstLiving <= 0 and secondLiving <= 0 then
        endSession(session, nil, "The round ended in a draw.")
    elseif firstLiving <= 0 then
        endSession(session, secondTeamId, "")
    elseif secondLiving <= 0 then
        endSession(session, firstTeamId, "")
    end
end

local function registerEntry(session, teamId: string, entry)
    table.insert(session.Teams[teamId], entry)

    local diedConnection = entry.Humanoid.Died:Connect(function()
        entry.Alive = false

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
        Dummies = {},
        Connections = {},
        Ended = false,
    }

    activeSessions[scenarioId] = session

    local spawnFolder = arenaFolder:FindFirstChild("Spawns")
    local dummySpawnFolder = arenaFolder:FindFirstChild("DummySpawns")

    if not spawnFolder or not dummySpawnFolder then
        endSession(session, nil, "The arena is missing spawn points.")
        return
    end

    for index, player in ipairs(queuedPlayers) do
        local team = scenario.Teams[((index - 1) % #scenario.Teams) + 1]
        local anchors = getAnchors(spawnFolder, team.Id)
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
                    Humanoid = humanoid,
                    Alive = true,
                })
                playerToSession[player] = session
            end
        end
    end

    for _, team in ipairs(scenario.Teams) do
        local dummyAnchors = getAnchors(dummySpawnFolder, team.Id)
        local dummyIndex = 1

        while #session.Teams[team.Id] < scenario.PlayersPerTeam and dummyIndex <= #dummyAnchors do
            local dummyAnchor = dummyAnchors[dummyIndex]
            local dummy = createDummy(arenaFolder, string.format("%s Dummy %d", team.DisplayName, dummyIndex), team.Id, scenario.Id, dummyAnchor.Position, team.AccentColor)
            local humanoid = dummy:FindFirstChildOfClass("Humanoid")

            if humanoid then
                registerEntry(session, team.Id, {
                    Kind = "Dummy",
                    Model = dummy,
                    Humanoid = humanoid,
                    Alive = true,
                })
                table.insert(session.Dummies, dummy)
            end

            dummyIndex += 1
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
