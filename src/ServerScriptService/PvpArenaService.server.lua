--!strict

-- Training Grounds: free-for-all sparring for 2-8 players, first to 3 round wins, with a
-- rematch vote at the end. This is present-day sport practice, not a historical battle, so it
-- never puts players on the side of any historical army.
--
-- Rounds, knockouts, timeouts, and rematches follow Shared/Modules/PvpMatch (unit tested).
-- Damage comes from the same server-side battle tools as the story battles (BattleLoadout), so
-- every client sees the same health: the server applies every hit.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PvpMatch = require(Shared.Modules.PvpMatch)
local Progression = require(Shared.Modules.Progression)
local TravelRoute = require(Shared.Data.TravelRoute)
local BuildUtils = require(script.Parent.Modules.BuildUtils)
local BattleLoadout = require(script.Parent.Modules.BattleLoadout)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local Analytics = require(script.Parent.Modules.Analytics)

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pvp")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local COMBATANT_TAG = "BattleCombatant"
local CENTER = (TravelRoute.GetDestinationById("training_grounds") :: any).Position - Vector3.new(0, 4, 0)
local G = 4
local RING_RADIUS = 52
local COUNTDOWN = 5
local INTERMISSION = 6

local match = PvpMatch.New()
local roundToken = 0
local countdownRunning = false

-- Arena -----------------------------------------------------------------------------------

local existing = Workspace:FindFirstChild("TrainingGrounds")

if existing then
    existing:Destroy()
end

local arena = BuildUtils.CreateFolder(Workspace, "TrainingGrounds")

BuildUtils.CreatePart(arena, "SafetyPlate", Vector3.new(400, 10, 400), CFrame.new(CENTER + Vector3.new(0, -8, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, nil, 1)
BuildUtils.CreatePart(arena, "Ground", Vector3.new(300, G, 300), CFrame.new(CENTER + Vector3.new(0, G / 2, 0)), Color3.fromRGB(190, 176, 150), Enum.Material.Sandstone, nil, nil)
BuildUtils.CreateVerticalCylinder(arena, "Ring", 0.6, RING_RADIUS + 4, CENTER + Vector3.new(0, G + 0.3, 0), Color3.fromRGB(176, 134, 92), Enum.Material.Sand, nil)
BuildUtils.CreateVerticalCylinder(arena, "RingEdge", 0.7, RING_RADIUS + 6, CENTER + Vector3.new(0, G + 0.25, 0), Color3.fromRGB(128, 70, 62), Enum.Material.Fabric, nil)

for index = 1, 16 do
    local angle = math.rad(index * 22.5)
    local position = CENTER + Vector3.new(math.cos(angle) * (RING_RADIUS + 8), G + 2, math.sin(angle) * (RING_RADIUS + 8))
    BuildUtils.CreatePart(arena, "RingPost" .. index, Vector3.new(1.4, 4, 1.4), CFrame.new(position), Color3.fromRGB(96, 72, 50), Enum.Material.Wood, nil, nil)
end

-- Benches where knocked-out players wait for the next round.
local bench = CENTER + Vector3.new(0, G, -RING_RADIUS - 30)
BuildUtils.CreatePart(arena, "Bench", Vector3.new(60, 2, 10), CFrame.new(bench + Vector3.new(0, 1, 0)), Color3.fromRGB(120, 92, 64), Enum.Material.WoodPlanks, nil, nil)

local joinPad = BuildUtils.CreatePart(arena, "JoinPad", Vector3.new(14, 1, 14), CFrame.new(CENTER + Vector3.new(0, G + 0.5, -RING_RADIUS - 60)), Color3.fromRGB(128, 70, 62), Enum.Material.Neon, nil, 0.2)
BuildUtils.AttachPrompt(joinPad, "Join sparring", "Training Grounds", { PromptAction = "PvpJoin" })

local boardSign = BuildUtils.CreateBoardSign(arena, "RulesSign", CENTER + Vector3.new(0, G, -RING_RADIUS - 76), "Training Grounds", "Practice sparring, 2 to 8 players. Last one standing wins the round; first to 3 rounds wins. Play fair, shake hands after. Not a historical battle.", Color3.fromRGB(128, 70, 62), nil)
boardSign.Orientation = Vector3.new(0, 0, 0)

-- Helpers -----------------------------------------------------------------------------------

local function byId(userId: number): Player?
    return Players:GetPlayerByUserId(userId)
end

local function getHumanoid(player: Player): Humanoid?
    local character = player.Character

    return character and character:FindFirstChildOfClass("Humanoid")
end

local function send(player: Player, extra: { [string]: any }?)
    local snapshot: { [string]: any } = PvpMatch.Snapshot(match)
    snapshot.InMatch = PvpMatch.Has(match, player.UserId)
    snapshot.Names = {}

    for _, row in ipairs(snapshot.Players) do
        local other = byId(row.UserId)
        snapshot.Names[tostring(row.UserId)] = if other then other.DisplayName else "Player"
    end

    if extra then
        for key, value in pairs(extra) do
            snapshot[key] = value
        end
    end

    stateEvent:FireClient(player, snapshot)
end

local function broadcast(extra: { [string]: any }?)
    for _, userId in ipairs(match.Players) do
        local player = byId(userId)

        if player then
            send(player, extra)
        end
    end
end

local function setFighter(player: Player, fighting: boolean)
    local character = player.Character

    player:SetAttribute("InBattle", if fighting then true else nil)
    player:SetAttribute("InSparring", if fighting then true else nil)

    if not character then
        return
    end

    if fighting then
        -- A team of one: every other fighter is an opponent.
        character:SetAttribute("BattleTeam", "spar_" .. player.UserId)
        CollectionService:AddTag(character, COMBATANT_TAG)
        BattleLoadout.GiveToPlayer(player)
    else
        character:SetAttribute("BattleTeam", nil)

        if CollectionService:HasTag(character, COMBATANT_TAG) then
            CollectionService:RemoveTag(character, COMBATANT_TAG)
        end

        BattleLoadout.ClearForPlayer(player)
    end
end

local function placeOnBench(player: Player)
    local character = player.Character

    if character then
        local slot = (player.UserId % 8) - 3.5
        character:PivotTo(CFrame.new(bench + Vector3.new(slot * 6, 5, -2)))
    end
end

local function ringSpawn(index: number, count: number): CFrame
    local angle = (index - 1) * (2 * math.pi / math.max(count, 2))
    local position = CENTER + Vector3.new(math.cos(angle) * (RING_RADIUS - 12), G + 4, math.sin(angle) * (RING_RADIUS - 12))

    return CFrame.lookAt(position, Vector3.new(CENTER.X, position.Y, CENTER.Z))
end

local function ensureAlive(player: Player)
    local humanoid = getHumanoid(player)

    if not humanoid or humanoid.Health <= 0 then
        player:LoadCharacter()
        local character = player.Character or player.CharacterAdded:Wait()
        character:WaitForChild("HumanoidRootPart", 5)
    end
end

-- Rounds ------------------------------------------------------------------------------------

local startRoundSoon

local function endRound()
    roundToken += 1

    for _, userId in ipairs(match.Players) do
        local player = byId(userId)

        if player then
            setFighter(player, false)
        end
    end

    local winner = match.RoundWinner and byId(match.RoundWinner)

    if winner then
        PlayerProgress.AddXP(winner, Progression.Rewards.PvpRoundWin, "Won a sparring round")
    end

    if match.Phase == "Over" then
        local champion = match.MatchWinner and byId(match.MatchWinner)

        if champion then
            PlayerProgress.AddXP(champion, Progression.Rewards.PvpMatchWin, "Won a sparring match")
            PlayerProgress.IncrementStat(champion, "PvpMatchWins", 1)
        end

        for _, userId in ipairs(match.Players) do
            local player = byId(userId)

            if player then
                PlayerProgress.IncrementStat(player, "PvpMatches", 1)
                Analytics.Custom(player, "PvpMatchDone", if player == champion then 1 else 0)
            end
        end

        broadcast({ Banner = string.format("%s wins the match!", if champion then champion.DisplayName else "Nobody") })
        return
    end

    broadcast({ Banner = if winner then string.format("%s wins round %d", winner.DisplayName, match.Round) else "Round drawn" })
    startRoundSoon(INTERMISSION)
end

local function startRound()
    if not PvpMatch.StartRound(match) then
        broadcast()
        return
    end

    roundToken += 1
    local token = roundToken
    local fighters = table.clone(match.Players)

    for index, userId in ipairs(fighters) do
        local player = byId(userId)

        if player then
            ensureAlive(player)
            local character = player.Character
            local humanoid = getHumanoid(player)

            if character and humanoid then
                humanoid.Health = humanoid.MaxHealth
                humanoid:SetAttribute("LastAttackerUserId", nil)
                character:PivotTo(ringSpawn(index, #fighters))
                setFighter(player, true)
            end
        end
    end

    broadcast({ Banner = string.format("Round %d: fight fair!", match.Round), RoundEndsAt = Workspace:GetServerTimeNow() + match.Config.RoundSeconds })

    task.delay(match.Config.RoundSeconds, function()
        if token ~= roundToken or match.Phase ~= "Round" then
            return
        end

        local health = {}

        for _, userId in ipairs(match.Players) do
            local player = byId(userId)
            local humanoid = player and getHumanoid(player)
            health[userId] = if humanoid then humanoid.Health else 0
        end

        PvpMatch.Timeout(match, health)
        endRound()
    end)
end

startRoundSoon = function(delaySeconds: number)
    if countdownRunning then
        return
    end

    countdownRunning = true
    broadcast({ CountdownEndsAt = Workspace:GetServerTimeNow() + delaySeconds })

    task.delay(delaySeconds, function()
        countdownRunning = false

        if PvpMatch.CanStartRound(match) then
            startRound()
        else
            broadcast({ Banner = "Waiting for another player to join." })
        end
    end)
end

local function afterChange()
    if match.Phase == "Round" then
        return
    end

    if match.RoundWinner ~= nil or match.Phase == "Over" then
        return
    end

    if PvpMatch.CanStartRound(match) then
        startRoundSoon(COUNTDOWN)
    end
end

local function join(player: Player)
    if player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true then
        send(player, { Banner = "Finish what you are doing first." })
        return
    end

    if match.Phase == "Over" then
        -- A finished match waits for its rematch vote; newcomers wait for the next one.
        send(player, { Banner = "A match just ended. Wait for the rematch vote to finish." })
        return
    end

    if not PvpMatch.AddPlayer(match, player.UserId) then
        send(player, { Banner = if match.Phase == "Round" then "A round is on. You will join the next one." else "The arena is full." })
        return
    end

    placeOnBench(player)
    broadcast({ Banner = string.format("%s joined the sparring.", player.DisplayName) })

    if PvpMatch.CanStartRound(match) then
        startRoundSoon(COUNTDOWN)
    end
end

local function leave(player: Player, reason: string?)
    if not PvpMatch.Has(match, player.UserId) then
        return
    end

    local wasRound = match.Phase == "Round"
    PvpMatch.RemovePlayer(match, player.UserId)

    if player.Parent then
        setFighter(player, false)
        send(player, { InMatch = false, Banner = reason or "You left the sparring." })
    end

    if wasRound and match.Phase ~= "Round" then
        endRound()
    else
        broadcast()
    end

    if match.Phase == "Over" and #match.Players < match.Config.MinPlayers then
        -- Nobody left to rematch with: start fresh.
        local remaining = table.clone(match.Players)
        match = PvpMatch.New()

        for _, userId in ipairs(remaining) do
            PvpMatch.AddPlayer(match, userId)
        end
    end

    afterChange()
end

-- Events ------------------------------------------------------------------------------------

local function watchCharacter(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end

    humanoid.Died:Connect(function()
        if match.Phase ~= "Round" or not match.Alive[player.UserId] then
            return
        end

        local attacker = humanoid:GetAttribute("LastAttackerUserId")
        PvpMatch.Knockout(match, player.UserId, if type(attacker) == "number" then attacker else nil)
        local attackerPlayer = type(attacker) == "number" and byId(attacker)
        broadcast({ Banner = if attackerPlayer then string.format("%s knocked out %s", attackerPlayer.DisplayName, player.DisplayName) else string.format("%s is out", player.DisplayName) })

        if match.Phase ~= "Round" then
            endRound()
        end
    end)

    -- Knocked-out fighters respawn on the bench, not in the hub.
    if PvpMatch.Has(match, player.UserId) then
        task.defer(function()
            character:WaitForChild("HumanoidRootPart", 5)

            -- A fighter revived for a new round is placed in the ring by startRound instead.
            if not (match.Phase == "Round" and match.Alive[player.UserId]) then
                placeOnBench(player)
            end
        end)
    end
end

local function onPlayer(player: Player)
    player.CharacterAdded:Connect(function(character)
        watchCharacter(player, character)
    end)

    if player.Character then
        watchCharacter(player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayer(player)
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player: Player)
    leave(player, nil)
end)

joinPad:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(join)

request.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "Join" then
        join(player)
    elseif action == "Leave" then
        leave(player, nil)
    elseif action == "Rematch" then
        if PvpMatch.VoteRematch(match, player.UserId) then
            broadcast({ Banner = "Rematch! Get ready." })
            startRoundSoon(COUNTDOWN)
        else
            broadcast()
        end
    elseif action == "State" then
        send(player)
    elseif action == "Teleport" then
        local character = player.Character

        if character and player:GetAttribute("InBattle") ~= true and player:GetAttribute("InStory") ~= true then
            character:PivotTo(CFrame.new(CENTER + Vector3.new(0, G + 4, -RING_RADIUS - 50)))
        end
    end
end)

-- Fighters who walk out of the ring area forfeit the round; anyone far away leaves the match.
task.spawn(function()
    while true do
        task.wait(0.5)

        for _, userId in ipairs(table.clone(match.Players)) do
            local player = byId(userId)
            local character = player and player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if player and root and root:IsA("BasePart") then
                local offset = root.Position - CENTER
                local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude

                if flat > 220 then
                    leave(player, "You left the Training Grounds.")
                elseif match.Phase == "Round" and match.Alive[userId] and (flat > RING_RADIUS + 10 or offset.Y < -2) then
                    local humanoid = getHumanoid(player)

                    if humanoid then
                        humanoid.Health = 0
                    end
                end
            end
        end
    end
end)

arena:SetAttribute("Built", true)
