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
local Decor = require(script.Parent.Modules.Decor)
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
-- Open desert around the arena, a hair below the arena floor, so the walls and palms do not
-- stand at the edge of the void.
BuildUtils.CreatePart(arena, "Desert", Vector3.new(1200, G - 0.1, 1200), CFrame.new(CENTER + Vector3.new(0, (G - 0.1) / 2, 0)), Color3.fromRGB(214, 188, 140), Enum.Material.Sand, nil, nil)
BuildUtils.CreatePart(arena, "Ground", Vector3.new(300, G, 300), CFrame.new(CENTER + Vector3.new(0, G / 2, 0)), Color3.fromRGB(190, 176, 150), Enum.Material.Sandstone, nil, nil)

local STONE = Color3.fromRGB(206, 190, 160)
local STONE_DARK = Color3.fromRGB(168, 150, 120)
local RED = Color3.fromRGB(128, 70, 62)
local SAND_CLOTH = Color3.fromRGB(222, 204, 160)

-- Paving: a lighter stone court around the ring with a darker band.
Decor.Deco(arena, "Court", Vector3.new(220, 0.1, 220), CFrame.new(CENTER + Vector3.new(0, G + 0.05, 0)), Color3.fromRGB(214, 200, 172), Enum.Material.Limestone)
BuildUtils.CreateVerticalCylinder(arena, "CourtBand", 0.12, RING_RADIUS + 14, CENTER + Vector3.new(0, G + 0.1, 0), STONE_DARK, Enum.Material.Slate, nil).CanCollide = false

BuildUtils.CreateVerticalCylinder(arena, "Ring", 0.6, RING_RADIUS + 4, CENTER + Vector3.new(0, G + 0.3, 0), Color3.fromRGB(176, 134, 92), Enum.Material.Sand, nil)
BuildUtils.CreateVerticalCylinder(arena, "RingEdge", 0.7, RING_RADIUS + 6, CENTER + Vector3.new(0, G + 0.25, 0), RED, Enum.Material.Fabric, nil)
-- A painted eight-point star in the centre of the ring.
for index = 0, 1 do
    Decor.Deco(arena, "CentreStar" .. index, Vector3.new(14, 0.08, 14), CFrame.new(CENTER + Vector3.new(0, G + 0.64, 0)) * CFrame.Angles(0, math.rad(index * 45), 0), Color3.fromRGB(150, 104, 70), Enum.Material.Sand)
end
BuildUtils.CreateVerticalCylinder(arena, "StartLine", 0.07, RING_RADIUS - 10, CENTER + Vector3.new(0, G + 0.62, 0), Color3.fromRGB(190, 150, 104), Enum.Material.Sand, nil).CanCollide = false
BuildUtils.CreateVerticalCylinder(arena, "StartLineInner", 0.08, RING_RADIUS - 11, CENTER + Vector3.new(0, G + 0.63, 0), Color3.fromRGB(176, 134, 92), Enum.Material.Sand, nil).CanCollide = false

-- Posts with ropes between them. The ropes do not collide, so a ring-out is still possible.
local postTops = {}

-- Offset by half a step so no post stands on the straight path in from the gates.
for index = 1, 16 do
    local angle = math.rad((index - 0.5) * 22.5)
    local position = CENTER + Vector3.new(math.cos(angle) * (RING_RADIUS + 8), G + 2, math.sin(angle) * (RING_RADIUS + 8))
    BuildUtils.CreatePart(arena, "RingPost" .. index, Vector3.new(1.4, 4, 1.4), CFrame.new(position), Color3.fromRGB(96, 72, 50), Enum.Material.Wood, nil, nil)
    Decor.Deco(arena, "RingPostCap" .. index, Vector3.new(1.8, 0.5, 1.8), CFrame.new(position + Vector3.new(0, 2.2, 0)), Color3.fromRGB(193, 162, 86), Enum.Material.Metal)
    postTops[index] = position + Vector3.new(0, 1.4, 0)
end

for index = 1, 16 do
    Decor.Rod(arena, "Rope" .. index, postTops[index], postTops[(index % 16) + 1], 0.16, RED, Enum.Material.Fabric, false)
end

-- Braziers between the ring and the stands.
for index = 1, 8 do
    local angle = math.rad(index * 45 + 22.5)
    Decor.Brazier(arena, "Brazier" .. index, CENTER + Vector3.new(math.cos(angle) * (RING_RADIUS + 16), G, math.sin(angle) * (RING_RADIUS + 16)))
end

-- Stepped stone stands to the east and west, with cloth shades. North (the arrival path)
-- and south (benches and the join pad) stay open.
local stands = BuildUtils.CreateFolder(arena, "Stands")

for _, side in ipairs({ 0, 180 }) do
    for segment = -5, 5 do
        local angle = math.rad(side + segment * 8)
        local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local yaw = -math.deg(angle) + 90

        for tier = 1, 3 do
            local reach = RING_RADIUS + 26 + tier * 6
            local height = tier * 2.2
            local at = CENTER + outward * reach + Vector3.new(0, G + height / 2, 0)
            BuildUtils.CreatePart(stands, string.format("Tier%d_%d_%d", side, segment + 6, tier), Vector3.new(reach * 0.15, height, 6.2), CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0), if tier % 2 == 0 then STONE_DARK else STONE, Enum.Material.Sandstone, nil, nil)
            -- Cushions along the seats.
            if (segment + tier) % 2 == 0 then
                Decor.Deco(stands, "Cushion", Vector3.new(reach * 0.12, 0.4, 2.6), CFrame.new(CENTER + outward * (reach - 1.2) + Vector3.new(0, G + height + 0.2, 0)) * CFrame.Angles(0, math.rad(yaw), 0), Decor.Colors.Cloths[(segment % 5) + 1], Enum.Material.Fabric)
            end
        end

        local back = CENTER + outward * (RING_RADIUS + 48) + Vector3.new(0, G + 6, 0)
        BuildUtils.CreatePart(stands, "BackWall", Vector3.new((RING_RADIUS + 48) * 0.15, 12, 2), CFrame.new(back) * CFrame.Angles(0, math.rad(yaw), 0), STONE, Enum.Material.Sandstone, nil, nil)

        if segment % 2 == 0 then
            -- Shade sail from the back wall out over the seats, on a pole.
            local poleBase = CENTER + outward * (RING_RADIUS + 47) + Vector3.new(0, G, 0)
            Decor.Rod(stands, "ShadePole", poleBase, poleBase + Vector3.new(0, 22, 0), 0.35, Color3.fromRGB(96, 72, 50), Enum.Material.Wood, true)
            Decor.Blade(stands, "ShadeSail", poleBase + Vector3.new(0, 21, 0), CENTER + outward * (RING_RADIUS + 28) + Vector3.new(0, G + 15, 0), 15, 0.25, if segment % 4 == 0 then RED else SAND_CLOTH, Enum.Material.Fabric)
            Decor.Banner(stands, "Banner", poleBase + outward * 1.5, if segment % 4 == 0 then SAND_CLOTH else RED, 26)
        end
    end
end

-- An outer wall with corner towers and gates north and south.
local wallColor = Color3.fromRGB(196, 170, 128)

for index, run in ipairs({
    { Vector3.new(-140, 0, 140), Vector3.new(-18, 0, 140) }, { Vector3.new(18, 0, 140), Vector3.new(140, 0, 140) },
    { Vector3.new(-140, 0, -140), Vector3.new(-18, 0, -140) }, { Vector3.new(18, 0, -140), Vector3.new(140, 0, -140) },
    { Vector3.new(140, 0, -140), Vector3.new(140, 0, 140) }, { Vector3.new(-140, 0, -140), Vector3.new(-140, 0, 140) },
}) do
    local a, b = CENTER + run[1] + Vector3.new(0, G, 0), CENTER + run[2] + Vector3.new(0, G, 0)
    local mid, length = (a + b) / 2, (b - a).Magnitude
    local frame = CFrame.lookAt(mid, b)
    BuildUtils.CreatePart(arena, "OuterWall" .. index, Vector3.new(3, 14, length), frame * CFrame.new(0, 7, 0), wallColor, Enum.Material.Sandstone, nil, nil)
    Decor.Deco(arena, "OuterWallCap" .. index, Vector3.new(4, 1, length), frame * CFrame.new(0, 14.5, 0), Decor.Shade(wallColor, 0.85), Enum.Material.Sandstone)

    for merlon = 1, math.floor(length / 12) do
        Decor.Deco(arena, "Merlon", Vector3.new(3, 2.4, 3), frame * CFrame.new(0, 16, -length / 2 + (merlon - 0.5) * (length / math.floor(length / 12))), wallColor, Enum.Material.Sandstone)
    end
end

for _, corner in ipairs({ Vector3.new(-140, 0, -140), Vector3.new(140, 0, -140), Vector3.new(-140, 0, 140), Vector3.new(140, 0, 140) }) do
    local at = CENTER + corner + Vector3.new(0, G, 0)
    BuildUtils.CreatePart(arena, "Tower", Vector3.new(12, 24, 12), CFrame.new(at + Vector3.new(0, 12, 0)), Decor.Shade(wallColor, 0.95), Enum.Material.Sandstone, nil, nil)
    Decor.Deco(arena, "TowerCap", Vector3.new(14, 1.4, 14), CFrame.new(at + Vector3.new(0, 24.7, 0)), Decor.Shade(wallColor, 0.8), Enum.Material.Sandstone)
    Decor.Deco(arena, "TowerWindow", Vector3.new(12.2, 4, 2), CFrame.new(at + Vector3.new(0, 18, 0)), Color3.fromRGB(46, 36, 30), Enum.Material.Wood)
end

for _, z in ipairs({ 140, -140 }) do
    local gate = CENTER + Vector3.new(0, G, z)
    for _, x in ipairs({ -18, 18 }) do
        BuildUtils.CreatePart(arena, "GatePier", Vector3.new(6, 22, 6), CFrame.new(gate + Vector3.new(x, 11, 0)), Decor.Shade(wallColor, 0.92), Enum.Material.Sandstone, nil, nil)
    end
    -- Chamfered top corners give the opening an arch shape; a stepped crest sits on the lintel.
    for _, side in ipairs({ -1, 1 }) do
        Decor.Deco(arena, "GateSpandrel", Vector3.new(9, 9, 5), CFrame.new(gate + Vector3.new(side * 15, 22, 0)) * CFrame.Angles(0, 0, math.rad(45)), Decor.Shade(wallColor, 0.92), Enum.Material.Sandstone)
    end
    Decor.Deco(arena, "GateCrest", Vector3.new(30, 5, 5), CFrame.new(gate + Vector3.new(0, 30.5, 0)), Decor.Shade(wallColor, 0.92), Enum.Material.Sandstone)
    Decor.Deco(arena, "GateCrestTop", Vector3.new(16, 4, 5), CFrame.new(gate + Vector3.new(0, 35, 0)), Decor.Shade(wallColor, 0.85), Enum.Material.Sandstone)
    BuildUtils.CreatePart(arena, "GateLintel", Vector3.new(42, 6, 6), CFrame.new(gate + Vector3.new(0, 25, 0)), Decor.Shade(wallColor, 0.85), Enum.Material.Sandstone, nil, nil)
    Decor.Deco(arena, "GateTile", Vector3.new(24, 3, 0.4), CFrame.new(gate + Vector3.new(0, 25, if z > 0 then 3.2 else -3.2)), Color3.fromRGB(44, 96, 120), Enum.Material.Glass)
end

-- Palms outside the walls, and practice racks by the benches.
for index = 1, 12 do
    local angle = index * 0.52
    local reach = 165 + (index % 3) * 8
    -- Keep the walk out of the two gates (on the z axis) clear.
    if math.abs(math.cos(angle) * reach) < 30 then
        angle += if math.cos(angle) >= 0 then 0.2 else -0.2
    end
    Decor.Palm(arena, "Palm" .. index, CENTER + Vector3.new(math.cos(angle) * reach, G, math.sin(angle) * reach) - Vector3.new(0, 0.1, 0), 18 + (index % 4) * 2, index * 9, true)
end

-- Rock outcrops out in the desert, so the horizon is not empty.
for index = 1, 10 do
    local angle = index * 0.63 + 0.3
    local reach = 330 + (index % 4) * 55
    Decor.Rocks(arena, "Outcrop" .. index, CENTER + Vector3.new(math.cos(angle) * reach, G - 0.1, math.sin(angle) * reach), 14 + (index % 3) * 8, index * 7)
end

for _, x in ipairs({ -40, 40 }) do
    local rack = CENTER + Vector3.new(x, G, -RING_RADIUS - 34)
    Decor.Rod(arena, "RackBar", rack + Vector3.new(-5, 4, 0), rack + Vector3.new(5, 4, 0), 0.2, Color3.fromRGB(96, 72, 50), Enum.Material.Wood, false)

    for slot = -2, 2 do
        Decor.Rod(arena, "PracticeSword", rack + Vector3.new(slot * 2, 0.2, 0.4), rack + Vector3.new(slot * 2 + 0.4, 5.2, -0.3), 0.14, Color3.fromRGB(150, 116, 76), Enum.Material.Wood, false)
    end
end

-- Benches where knocked-out players wait for the next round.
local bench = CENTER + Vector3.new(0, G, -RING_RADIUS - 30)
BuildUtils.CreatePart(arena, "Bench", Vector3.new(60, 2, 10), CFrame.new(bench + Vector3.new(0, 1, 0)), Color3.fromRGB(120, 92, 64), Enum.Material.WoodPlanks, nil, nil)

local joinPad = BuildUtils.CreatePart(arena, "JoinPad", Vector3.new(14, 1, 14), CFrame.new(CENTER + Vector3.new(0, G + 0.5, -RING_RADIUS - 60)), Color3.fromRGB(128, 70, 62), Enum.Material.Neon, nil, 0.2)
BuildUtils.AttachPrompt(joinPad, "Join sparring", "Training Grounds", { PromptAction = "PvpJoin" })

local boardSign = BuildUtils.CreateBoardSign(arena, "RulesSign", CENTER + Vector3.new(-26, G, -RING_RADIUS - 76), "Training Grounds", "Practice sparring, 2 to 8 players. Last one standing wins the round; first to 3 rounds wins. Play fair, shake hands after. Not a historical battle.", Color3.fromRGB(128, 70, 62), nil)
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
