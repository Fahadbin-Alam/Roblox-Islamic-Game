--!nonstrict

-- Runs one battle story mission: walks through its objectives in order, spawns the waves,
-- keeps allies at their posts, tracks falls and the steadfast condition, respawns players,
-- and streams the state to every player's mission HUD.
--
-- BattleService owns the session (queue, briefing, reenactment, rewards) and hands this module
-- the players and two callbacks: Respawn(player, cframe) and OnFinished(result).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattleMissions = require(Shared.Data.BattleMissions)
local MissionRules = require(Shared.Modules.MissionRules)
local BattleNpc = require(script.Parent.BattleNpc)
local PlayerProgress = require(script.Parent.PlayerProgress)

local MissionDirector = {}
MissionDirector.__index = MissionDirector

local TICK_SECONDS = 0.25
local STATE_EVERY_TICKS = 2
local DISCIPLINE_GRACE_SECONDS = 8
local ZONE_COLOR = Color3.fromRGB(236, 200, 112)
local MEDINA_GREEN = Color3.fromRGB(62, 125, 82)

local function flatDistance(a: Vector3, b: Vector3): number
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function anchoredPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, transparency: number?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Parent = parent

    return part
end

-- options: Mission, Arena, Players (array), Send(player, payload), Respawn(player, cframe) -> Model?,
-- OnFinished(result)
function MissionDirector.new(options)
    local mission = options.Mission
    local runtime = Instance.new("Folder")
    runtime.Name = "MissionRuntime"
    runtime.Parent = options.Arena

    local self = setmetatable({
        Mission = mission,
        Arena = options.Arena,
        Runtime = runtime,
        Players = options.Players,
        Send = function(player: Player, payload)
            -- A player who is leaving can no longer be messaged; never let that stop the mission.
            pcall(options.Send, player, payload)
        end,
        Respawn = options.Respawn,
        OnFinished = options.OnFinished,
        Points = {},
        Lanes = {},
        PlayerState = {},
        Connections = {},
        Finished = false,
        StartedAt = os.clock(),
        TeamFalls = 0,
        PeakPlayers = #options.Players,
        OrderBroken = false,
        ObjectivesDone = 0,
        Objective = nil,
        ObjectiveIndex = 0,
        ObjectiveState = {},
        SpawnQueue = {},
        ObjectiveEnemies = {},
        Zone = nil,
        Structure = nil,
        StructureFractions = {},
    }, MissionDirector)

    self:ResolveLayout()

    self.World = BattleNpc.NewWorld({
        Folder = runtime,
        GetPlayers = function()
            return self.Players
        end,
        OnDeath = function(npc, killer)
            self:OnNpcDeath(npc, killer)
        end,
        OnStructureDamaged = function(structure)
            self:UpdateStructureVisual(structure)
        end,
    })
    self.World.HealthMultiplier = MissionRules.HealthMultiplier(#self.Players)

    return self
end

-- Drops a battlefield point onto the ground under it.
function MissionDirector:Drop(point: Vector3): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = { self.Runtime }

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(exclude, player.Character)
        end
    end

    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true

    local result = Workspace:Raycast(Vector3.new(point.X, 400, point.Z), Vector3.new(0, -600, 0), params)

    if result then
        return result.Position
    end

    return Vector3.new(point.X, 2, point.Z)
end

function MissionDirector:ResolveLayout()
    local layout = self.Mission.Layout

    for name, point in pairs(layout.Points) do
        self.Points[name] = self:Drop(point)
    end

    for name, lane in pairs(layout.Lanes) do
        local resolved = {}

        for _, point in ipairs(lane) do
            table.insert(resolved, self:Drop(point))
        end

        self.Lanes[name] = resolved
    end

    self.Facing = self:Drop(layout.SpawnFacing)
end

-- Messaging -------------------------------------------------------------------------------

function MissionDirector:Broadcast(payload)
    for _, player in ipairs(self.Players) do
        if player.Parent then
            self.Send(player, payload)
        end
    end
end

function MissionDirector:Toast(text: string, players: { Player }?)
    local payload = { Kind = "Toast", Text = text }

    for _, player in ipairs(players or self.Players) do
        if player.Parent then
            self.Send(player, payload)
        end
    end
end

-- Players ----------------------------------------------------------------------------------

function MissionDirector:GetState(player: Player)
    local state = self.PlayerState[player]

    if not state then
        state = { Falls = 0, Defeated = 0, Connections = {}, Respawning = false, OutsideSince = nil, BrokeOrder = false }
        self.PlayerState[player] = state
    end

    return state
end

function MissionDirector:WatchCharacter(player: Player, character: Model)
    local state = self:GetState(player)
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    for _, connection in ipairs(state.Connections) do
        connection:Disconnect()
    end

    table.clear(state.Connections)

    if not humanoid then
        return
    end

    table.insert(state.Connections, humanoid.Died:Connect(function()
        self:OnPlayerFell(player)
    end))
end

function MissionDirector:GetRespawnPoint(): Vector3
    local objective = self.Objective
    local name = (objective and objective.RespawnPoint) or "Camp"

    return self.Points[name] or self.Points.Camp
end

function MissionDirector:RespawnCFrame(index: number): CFrame
    local base = self:GetRespawnPoint()
    local angle = (index % 8) * math.pi / 4
    local position = base + Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
    position = self:Drop(position) + Vector3.new(0, 3, 0)

    return CFrame.lookAt(position, Vector3.new(self.Facing.X, position.Y, self.Facing.Z))
end

function MissionDirector:OnPlayerFell(player: Player)
    if self.Finished then
        return
    end

    local state = self:GetState(player)

    if state.Respawning then
        return
    end

    state.Respawning = true
    state.Falls += 1
    self.TeamFalls += 1
    self:Toast(string.format("%s fell. Back on your feet in %d seconds.", player.DisplayName, self.Mission.RespawnSeconds))

    task.delay(self.Mission.RespawnSeconds, function()
        state.Respawning = false

        if self.Finished or not player.Parent or not table.find(self.Players, player) then
            return
        end

        local character = self.Respawn(player, self:RespawnCFrame(table.find(self.Players, player) or 1))

        if character then
            self:WatchCharacter(player, character)
        end
    end)
end

function MissionDirector:AddPlayer(player: Player)
    if self.Finished or table.find(self.Players, player) then
        return
    end

    table.insert(self.Players, player)
    self.PeakPlayers = math.max(self.PeakPlayers, #self.Players)
    self.World.HealthMultiplier = MissionRules.HealthMultiplier(#self.Players)

    local character = self.Respawn(player, self:RespawnCFrame(#self.Players))

    if character then
        self:WatchCharacter(player, character)
    end

    self:Toast(string.format("%s joined the mission.", player.DisplayName))

    if self.Objective then
        self.Send(player, {
            Kind = "Narration",
            Title = self.Objective.Narration.Title,
            Body = self.Objective.Narration.Body,
            Reference = self.Objective.Narration.Reference,
            ObjectiveTitle = self.Objective.Title,
        })
    end
end

function MissionDirector:RemovePlayer(player: Player)
    local index = table.find(self.Players, player)

    if index then
        table.remove(self.Players, index)
    end

    local state = self.PlayerState[player]

    if state then
        for _, connection in ipairs(state.Connections) do
            connection:Disconnect()
        end
    end

    self.Send(player, { Kind = "Clear" })

    if not self.Finished and #self.Players == 0 then
        self:Finish(false, "Everyone left the battlefield.")
    end
end

local function getRoot(player: Player): BasePart?
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return root
    end

    return nil
end

function MissionDirector:InZone(position: Vector3, center: Vector3, radius: number): boolean
    return flatDistance(position, center) <= radius and math.abs(position.Y - center.Y) <= 22
end

function MissionDirector:PlayersInZone(center: Vector3, radius: number): { Player }
    local inside = {}

    for _, player in ipairs(self.Players) do
        local root = getRoot(player)

        if root and self:InZone(root.Position, center, radius) then
            table.insert(inside, player)
        end
    end

    return inside
end

function MissionDirector:EnemiesInZone(center: Vector3, radius: number): number
    local count = 0

    for _, npc in ipairs(self.World:GetAlive("makkah")) do
        if self:InZone(npc.Root.Position, center, radius) then
            count += 1
        end
    end

    return count
end

function MissionDirector:HealPlayers()
    for _, player in ipairs(self.Players) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 then
            humanoid.Health = humanoid.MaxHealth
        end
    end
end

-- Soldiers -----------------------------------------------------------------------------------

function MissionDirector:OnNpcDeath(npc, killer: Player?)
    if npc.Team ~= "makkah" then
        if npc.Team == "medina" and not self.Finished then
            self:Toast("A Medina soldier has fallen.")
        end

        return
    end

    if killer then
        local state = self:GetState(killer)
        state.Defeated += 1
    end
end

function MissionDirector:SpawnAllies()
    for _, group in ipairs(self.Mission.Allies) do
        local unit = BattleMissions.Units[group.Unit]
        local base = self.Points[group.Point]

        for index = 1, group.Count do
            local offset = self:FormationOffset(index, group.Count, group.Tag ~= nil)
            local position = self:Drop(base + offset)
            local npc = self.World:Spawn(unit, position, self.Facing, {
                Tag = group.Tag,
                HoldPoint = base,
                FormationOffset = offset,
            })
            npc.HomePoint = group.Point
        end
    end
end

-- A loose line facing the enemy, or a tight cluster for archers on a hilltop.
function MissionDirector:FormationOffset(index: number, count: number, tight: boolean): Vector3
    if tight then
        local angle = (index / math.max(1, count)) * math.pi * 2
        return Vector3.new(math.cos(angle) * 9, 0, math.sin(angle) * 9)
    end

    local toward = (self.Facing - (self.Points.Line or self.Points.Camp))
    toward = Vector3.new(toward.X, 0, toward.Z)
    local forward = toward.Magnitude > 0.1 and toward.Unit or Vector3.xAxis
    local side = Vector3.new(-forward.Z, 0, forward.X)
    local column = index - (count + 1) / 2

    return side * (column * 7) + forward * ((index % 2 == 0) and 3 or -3)
end

function MissionDirector:SetAllyPoint(pointName: string?)
    local point = pointName and self.Points[pointName]

    if not point then
        return
    end

    for _, npc in ipairs(self.World:GetAlive("medina")) do
        if not npc.ForcedDestination then
            -- Hill archers keep their own post until they desert it.
            if npc.Tag == "HillArcher" and not npc.Deserted then
                continue
            end

            npc.HoldPoint = point
        end
    end
end

function MissionDirector:QueueSpawns(spawns)
    local playerCount = math.max(1, #self.Players)

    for _, spawn in ipairs(spawns) do
        local unit = BattleMissions.Units[spawn.Unit]
        local count = MissionRules.ScaleCount(spawn, playerCount)

        for _ = 1, count do
            table.insert(self.SpawnQueue, { Unit = unit, Lane = spawn.Lane })
        end
    end
end

function MissionDirector:PumpSpawns()
    local limit = MissionRules.MaxAliveEnemies(#self.Players)
    local spawned = 0

    while #self.SpawnQueue > 0 and spawned < 2 and self.World:CountAlive("makkah") < limit do
        local request = table.remove(self.SpawnQueue, 1)
        local lane = self.Lanes[request.Lane]
        local start = lane[1]
        local jitter = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
        local position = self:Drop(start + jitter)
        local laneCopy = {}

        for index = 2, #lane do
            table.insert(laneCopy, lane[index] + jitter * 0.4)
        end

        local goal = (self.Objective and self:ObjectiveFocus(self.Objective)) or lane[#lane]
        local npc = self.World:Spawn(request.Unit, position, lane[2] or goal, {
            Lane = laneCopy,
            Goal = goal,
            FormationOffset = jitter * 0.5,
        })
        table.insert(self.ObjectiveEnemies, npc)

        if request.Unit.Boss then
            self.Boss = npc
            self:Toast(string.format("%s has entered the field.", request.Unit.DisplayName))
        end

        spawned += 1
    end
end

function MissionDirector:ObjectiveFocus(objective): Vector3?
    if objective.Target then
        return self.Points[objective.Target]
    end

    if objective.Zone then
        return self.Points[objective.Zone]
    end

    if objective.AllyPoint then
        return self.Points[objective.AllyPoint]
    end

    return nil
end

function MissionDirector:ObjectiveEnemiesAlive(): number
    local alive = 0

    for _, npc in ipairs(self.ObjectiveEnemies) do
        if npc.Alive then
            alive += 1
        end
    end

    return alive
end

-- Fires due waves. Returns true once every wave has spawned and been driven back.
function MissionDirector:UpdateWaves(objective, elapsed: number): boolean
    local waves = objective.Waves

    if not waves then
        return true
    end

    local state = self.ObjectiveState
    state.NextWave = state.NextWave or 1

    local wave = waves[state.NextWave]

    if wave then
        local due = false

        if wave.AtSecond then
            due = elapsed >= wave.AtSecond
        elseif wave.AfterCleared then
            if #self.SpawnQueue == 0 and self:ObjectiveEnemiesAlive() == 0 then
                state.ClearedAt = state.ClearedAt or elapsed
                due = elapsed - state.ClearedAt >= 3
            else
                state.ClearedAt = nil
            end
        end

        if due then
            local spawns = table.clone(wave.Spawns)

            if state.NextWave == 1 and self.OrderBroken and objective.BrokenOrderExtra then
                for _, extra in ipairs(objective.BrokenOrderExtra) do
                    table.insert(spawns, extra)
                end

                self:Toast("The hill was left open. More riders pour through the gap.")
            end

            self:QueueSpawns(spawns)
            state.NextWave += 1
            state.ClearedAt = nil

            if state.NextWave > 2 then
                self:Toast(string.format("Wave %d of %d.", state.NextWave - 1, #waves))
            end
        end
    end

    self:PumpSpawns()

    return state.NextWave > #waves and #self.SpawnQueue == 0 and self:ObjectiveEnemiesAlive() == 0
end

-- Zone and structure visuals ----------------------------------------------------------------

function MissionDirector:ShowZone(center: Vector3, radius: number)
    self:HideZone()

    local folder = Instance.new("Folder")
    folder.Name = "ObjectiveZone"
    folder.Parent = self.Runtime

    anchoredPart(folder, "Disc", Vector3.new(0.3, radius * 2, radius * 2), CFrame.new(center + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), ZONE_COLOR, Enum.Material.Neon, 0.82).Shape = Enum.PartType.Cylinder
    anchoredPart(folder, "Ring", Vector3.new(0.5, radius * 2 + 1.2, radius * 2 + 1.2), CFrame.new(center + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)), ZONE_COLOR, Enum.Material.Neon, 0.55).Shape = Enum.PartType.Cylinder
    local beam = anchoredPart(folder, "Beacon", Vector3.new(1.4, 90, 1.4), CFrame.new(center + Vector3.new(0, 45, 0)), ZONE_COLOR, Enum.Material.Neon, 0.7)
    local light = Instance.new("PointLight")
    light.Color = ZONE_COLOR
    light.Range = 24
    light.Brightness = 1.4
    light.Parent = beam

    self.Zone = folder
end

function MissionDirector:HideZone()
    if self.Zone then
        self.Zone:Destroy()
        self.Zone = nil
    end
end

function MissionDirector:BuildStructure(center: Vector3, health: number)
    local model = Instance.new("Model")
    model.Name = "MedinaBanner"
    model.Parent = self.Runtime

    anchoredPart(model, "Base", Vector3.new(6, 1.2, 6), CFrame.new(center + Vector3.new(0, 0.6, 0)), Color3.fromRGB(150, 128, 96), Enum.Material.Slate).CanCollide = true
    anchoredPart(model, "Pole", Vector3.new(0.8, 18, 0.8), CFrame.new(center + Vector3.new(0, 9.6, 0)), Color3.fromRGB(110, 80, 50), Enum.Material.Wood).CanCollide = true
    anchoredPart(model, "Cloth", Vector3.new(0.3, 5, 7.5), CFrame.new(center + Vector3.new(0, 15, 3.9)), MEDINA_GREEN, Enum.Material.Fabric)
    anchoredPart(model, "Finial", Vector3.new(1.2, 1.2, 1.2), CFrame.new(center + Vector3.new(0, 19.2, 0)), Color3.fromRGB(214, 180, 96), Enum.Material.Metal).Shape = Enum.PartType.Ball

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthBar"
    billboard.Size = UDim2.fromOffset(160, 22)
    billboard.StudsOffset = Vector3.new(0, 22, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 220
    billboard.Adornee = model:FindFirstChild("Pole") :: BasePart
    billboard.Parent = model

    local back = Instance.new("Frame")
    back.Size = UDim2.fromScale(1, 1)
    back.BackgroundColor3 = Color3.fromRGB(32, 28, 24)
    back.BorderSizePixel = 0
    back.Parent = billboard

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(96, 178, 112)
    fill.BorderSizePixel = 0
    fill.Parent = back

    local structure = {
        Name = "Medina Banner",
        Position = center,
        Health = health,
        MaxHealth = health,
        Model = model,
        Fill = fill,
    }

    self.World:AddStructure(structure)
    self.Structure = structure

    return structure
end

function MissionDirector:UpdateStructureVisual(structure)
    local fraction = structure.Health / structure.MaxHealth

    if structure.Fill then
        structure.Fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
        structure.Fill.BackgroundColor3 = fraction > 0.5 and Color3.fromRGB(96, 178, 112) or (fraction > 0.25 and Color3.fromRGB(222, 176, 82) or Color3.fromRGB(206, 86, 70))
    end

    local now = os.clock()

    if fraction < 0.5 and not structure.WarnedHalf then
        structure.WarnedHalf = true
        self:Toast("The banner is under heavy attack. Protect it!")
    elseif now - (structure.LastHitToast or 0) > 8 then
        structure.LastHitToast = now
        self:Toast("Opponents are attacking the banner!")
    end
end

function MissionDirector:RemoveStructure()
    if self.Structure then
        self.Structure.Alive = false

        if self.Structure.Model then
            self.Structure.Model:Destroy()
        end

        table.clear(self.World.Structures)
        self.Structure = nil
    end
end

function MissionDirector:BuildSpoils(center: Vector3)
    local folder = Instance.new("Model")
    folder.Name = "Spoils"
    folder.Parent = self.Runtime
    local gold = Color3.fromRGB(226, 186, 92)

    for index = 1, 5 do
        local angle = index * 1.3
        local offset = Vector3.new(math.cos(angle) * (3 + index), 0, math.sin(angle) * (3 + index))
        local crate = anchoredPart(folder, "Crate", Vector3.new(3, 2.2, 2.4), CFrame.new(self:Drop(center + offset) + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, angle, 0), Color3.fromRGB(122, 86, 52), Enum.Material.WoodPlanks)
        crate.CanCollide = true
        anchoredPart(folder, "Coins", Vector3.new(2.4, 0.5, 1.8), crate.CFrame * CFrame.new(0, 1.3, 0), gold, Enum.Material.Neon, 0.1)
    end

    local anchor = anchoredPart(folder, "PromptAnchor", Vector3.new(1, 1, 1), CFrame.new(self:Drop(center) + Vector3.new(0, 2, 0)), gold, Enum.Material.Neon, 1)
    local sparkle = Instance.new("Sparkles")
    sparkle.SparkleColor = gold
    sparkle.Parent = anchor

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Collect the spoils"
    prompt.ObjectText = "Spoils of the field"
    prompt.HoldDuration = 0.4
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = anchor

    table.insert(self.Connections, prompt.Triggered:Connect(function(player)
        if table.find(self.Players, player) then
            self:BreakOrder(player, "left the hill for the spoils")
        end
    end))

    self.Spoils = folder
end

function MissionDirector:RemoveSpoils()
    if self.Spoils then
        self.Spoils:Destroy()
        self.Spoils = nil
    end
end

function MissionDirector:BreakOrder(player: Player, why: string)
    local state = self:GetState(player)

    if state.BrokeOrder then
        return
    end

    state.BrokeOrder = true
    self.OrderBroken = true
    self:Toast(string.format("%s %s. The order was to stay.", player.DisplayName, why))
end

-- Objectives ------------------------------------------------------------------------------------

function MissionDirector:BeginObjective(index: number, objective)
    self.Objective = objective
    self.ObjectiveIndex = index
    self.ObjectiveState = {}
    self.ObjectiveEnemies = {}
    self.SpawnQueue = {}
    self.Boss = nil

    if objective.ClearEnemies then
        self.World:DismissTeam("makkah")
    end

    if objective.HealPlayers then
        self:HealPlayers()
    end

    self:SetAllyPoint(objective.AllyPoint)

    local focus = self:ObjectiveFocus(objective)

    if objective.Zone then
        self:ShowZone(self.Points[objective.Zone], objective.Radius)
    else
        self:HideZone()
    end

    -- Opponents already on the field turn toward the new objective.
    if focus then
        for _, npc in ipairs(self.World:GetAlive("makkah")) do
            npc.Goal = focus
        end
    end

    if objective.Type == "Defend" then
        self:BuildStructure(self.Points[objective.Target], objective.TargetHealth)
    end

    if objective.Type == "Discipline" then
        self:BuildSpoils(self.Points.Spoils or focus)

        local desert = objective.DesertingAllies

        if desert then
            local archers = self.World:GetAlive("medina", desert.Tag)

            for archerIndex, npc in ipairs(archers) do
                if archerIndex > (desert.Keep or 0) then
                    task.delay(2 + archerIndex * 1.2, function()
                        if npc.Alive then
                            npc.Deserted = true
                            npc.ForcedDestination = self.Points[desert.To] + Vector3.new(archerIndex * 3, 0, 0)
                        end
                    end)
                end
            end
        end
    end

    self:Broadcast({
        Kind = "Narration",
        Title = objective.Narration.Title,
        Body = objective.Narration.Body,
        Reference = objective.Narration.Reference,
        ObjectiveTitle = objective.Title,
    })
end

function MissionDirector:EndObjective(objective)
    self.ObjectivesDone += 1

    for _, player in ipairs(self.Players) do
        PlayerProgress.IncrementStat(player, "BattleObjectives", 1)
    end

    if objective.Type == "Defend" and self.Structure then
        self.StructureFractions[objective.Id] = self.Structure.Health / self.Structure.MaxHealth
        self:RemoveStructure()
    end

    if objective.Type == "Discipline" then
        self:RemoveSpoils()

        -- The archers who left are now caught on the open field; send them back to the line.
        for _, npc in ipairs(self.World:GetAlive("medina")) do
            if npc.ForcedDestination then
                npc.ForcedDestination = nil
                npc.HoldPoint = self.Points.Line or self.Points.Camp
            end
        end

        if self.OrderBroken then
            self:Toast("Not everyone kept their post.")
        else
            self:Toast("Every player kept their post. Well done.")
        end
    end

    self:HideZone()
    self:Broadcast({ Kind = "ObjectiveComplete", Title = objective.Title })
end

-- Runs one objective. Returns "done", "failed" (with a reason), or "stopped".
function MissionDirector:RunObjective(objective): (string, string?)
    local elapsed = 0
    local tick = 0
    local holdProgress = 0
    local holdStatus = "Empty"
    local mission = self.Mission

    while true do
        task.wait(TICK_SECONDS)
        elapsed += TICK_SECONDS
        tick += 1

        if self.Finished then
            return "stopped"
        end

        if os.clock() - self.StartedAt > mission.TimeLimitSeconds then
            return "failed", "The day ran out before the mission was finished."
        end

        local done = false
        local progress = nil
        local progressText = nil
        local zoneCenter = objective.Zone and self.Points[objective.Zone]
        local wavesDone = self:UpdateWaves(objective, elapsed)

        if objective.Type == "Reach" then
            local nearest = math.huge

            for _, player in ipairs(self.Players) do
                local root = getRoot(player)

                if root then
                    nearest = math.min(nearest, flatDistance(root.Position, zoneCenter))
                end
            end

            done = #self:PlayersInZone(zoneCenter, objective.Radius) > 0
            progressText = nearest < math.huge and string.format("%d studs away", math.max(0, math.floor(nearest - objective.Radius))) or nil
        elseif objective.Type == "Hold" then
            local inside = #self:PlayersInZone(zoneCenter, objective.Radius)
            local enemies = self:EnemiesInZone(zoneCenter, objective.Radius)
            holdProgress, holdStatus = MissionRules.StepHold(holdProgress, TICK_SECONDS, objective.Seconds, inside, enemies)

            for _, player in ipairs(self:PlayersInZone(zoneCenter, objective.Radius)) do
                local state = self:GetState(player)
                state.HeldSeconds = (state.HeldSeconds or 0) + TICK_SECONDS
            end

            progress = holdProgress / objective.Seconds
            progressText = string.format("%s %d / %d s", holdStatus == "Contested" and "Contested!" or (holdStatus == "Empty" and "Step into the ring" or "Holding"), math.floor(holdProgress), objective.Seconds)
            done = holdProgress >= objective.Seconds
        elseif objective.Type == "Defend" then
            local structure = self.Structure

            if structure and not structure.Alive then
                return "failed", "The banner of the Medina line fell."
            end

            progress = structure and structure.Health / structure.MaxHealth or 0
            progressText = string.format("Banner %d / %d", structure and math.ceil(structure.Health) or 0, structure and structure.MaxHealth or 0)
            done = wavesDone
        elseif objective.Type == "Defeat" then
            local remaining = self:ObjectiveEnemiesAlive() + #self.SpawnQueue
            progressText = remaining > 0 and string.format("%d opponents on the field", remaining) or "Waiting for the next wave"
            done = wavesDone
        elseif objective.Type == "Discipline" then
            local insidePlayers = self:PlayersInZone(zoneCenter, objective.Radius)

            if elapsed > DISCIPLINE_GRACE_SECONDS then
                for _, player in ipairs(self.Players) do
                    local root = getRoot(player)

                    if root and not table.find(insidePlayers, player) then
                        self:BreakOrder(player, "left the hill")
                    end
                end
            elseif tick % 8 == 0 then
                for _, player in ipairs(self.Players) do
                    local root = getRoot(player)

                    if root and not table.find(insidePlayers, player) then
                        self:Toast("Get back on the hill. Your post is up there.", { player })
                    end
                end
            end

            progress = math.min(1, elapsed / objective.Seconds)
            progressText = string.format("Hold your post %d / %d s", math.floor(math.min(elapsed, objective.Seconds)), objective.Seconds)
            done = elapsed >= objective.Seconds
        elseif objective.Type == "Narration" then
            progress = math.min(1, elapsed / objective.Seconds)
            done = elapsed >= objective.Seconds
        end

        if tick % STATE_EVERY_TICKS == 0 or done then
            self:SendState(objective, progress, progressText, holdStatus)
        end

        if done then
            return "done"
        end
    end
end

function MissionDirector:SendState(objective, progress: number?, progressText: string?, holdStatus: string?)
    local boss = nil

    if self.Boss and self.Boss.Alive then
        boss = {
            Name = self.Boss.Unit.DisplayName,
            Health = self.Boss.Humanoid.Health / self.Boss.Humanoid.MaxHealth,
        }
    end

    local zone = objective.Zone and self.Points[objective.Zone]
    local target = objective.Target and self.Points[objective.Target]

    self:Broadcast({
        Kind = "State",
        Mission = self.Mission.DisplayName,
        Subtitle = self.Mission.Subtitle,
        Index = self.ObjectiveIndex,
        Count = #self.Mission.Objectives,
        Title = objective.Title,
        Instruction = objective.Instruction,
        Type = objective.Type,
        Progress = progress,
        ProgressText = progressText,
        Contested = holdStatus == "Contested",
        ZonePosition = zone,
        ZoneRadius = objective.Radius,
        TargetPosition = target,
        EnemiesLeft = self.World:CountAlive("makkah") + #self.SpawnQueue,
        AlliesLeft = self.World:CountAlive("medina"),
        Boss = boss,
        Falls = self.TeamFalls,
        OrderKept = if self.Mission.Steadfast.Kind == "Discipline" and self.ObjectiveIndex > self:IndexOf(self.Mission.Steadfast.Objective) - 1 then not self.OrderBroken else nil,
        Elapsed = os.clock() - self.StartedAt,
        TimeLimit = self.Mission.TimeLimitSeconds,
    })
end

function MissionDirector:IndexOf(objectiveId: string): number
    for index, objective in ipairs(self.Mission.Objectives) do
        if objective.Id == objectiveId then
            return index
        end
    end

    return math.huge
end

function MissionDirector:SteadfastKept(): boolean
    local rule = self.Mission.Steadfast

    if rule.Kind == "Discipline" then
        return not self.OrderBroken
    elseif rule.Kind == "TargetHealth" then
        local fraction = self.StructureFractions[rule.Objective]
        return fraction ~= nil and fraction >= rule.Fraction
    end

    return true
end

function MissionDirector:Start()
    for index, player in ipairs(self.Players) do
        local character = player.Character

        if character then
            self:WatchCharacter(player, character)
            character:PivotTo(self:RespawnCFrame(index))
        end
    end

    self:SpawnAllies()

    task.spawn(function()
        for index, objective in ipairs(self.Mission.Objectives) do
            if self.Finished then
                return
            end

            self:BeginObjective(index, objective)
            local outcome, reason = self:RunObjective(objective)

            if outcome == "stopped" then
                return
            elseif outcome == "failed" then
                self:Finish(false, reason or "The mission failed.")
                return
            end

            self:EndObjective(objective)
            task.wait(1.5)
        end

        self:Finish(true, string.format("%s complete.", self.Mission.DisplayName))
    end)
end

function MissionDirector:Finish(completed: boolean, reason: string)
    if self.Finished then
        return
    end

    self.Finished = true

    local perPlayer = {}

    for player, state in pairs(self.PlayerState) do
        perPlayer[player] = {
            Falls = state.Falls,
            Defeated = state.Defeated,
            HeldSeconds = math.floor(state.HeldSeconds or 0),
            BrokeOrder = state.BrokeOrder,
        }
    end

    local result = {
        Completed = completed,
        Reason = reason,
        Falls = self.TeamFalls,
        PlayerCount = math.max(1, self.PeakPlayers),
        SteadfastKept = completed and self:SteadfastKept(),
        OrderBroken = self.OrderBroken,
        ObjectivesDone = self.ObjectivesDone,
        PerPlayer = perPlayer,
    }

    self:Broadcast({ Kind = "Clear" })
    self:Cleanup()

    if self.OnFinished then
        task.spawn(self.OnFinished, result)
    end
end

function MissionDirector:Stop()
    if self.Finished then
        return
    end

    self.Finished = true
    self:Broadcast({ Kind = "Clear" })
    self:Cleanup()
end

function MissionDirector:Cleanup()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    for _, state in pairs(self.PlayerState) do
        for _, connection in ipairs(state.Connections) do
            connection:Disconnect()
        end
    end

    self.World:Destroy()
    self.Runtime:Destroy()
end

return MissionDirector
