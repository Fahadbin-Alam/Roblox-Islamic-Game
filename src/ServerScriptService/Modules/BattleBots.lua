--!nonstrict

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BattleBots = {}

local BOT_STEP_SECONDS = 0.08
local BOT_MELEE_RANGE = 8.5
local BOT_MELEE_DAMAGE = 13
local BOT_COMMANDER_DAMAGE = 20
local BOT_MELEE_ATTACK_INTERVAL = 1.18
local BOT_ARCHER_RANGE = 124
local BOT_ARCHER_MIN_RANGE = 24
local BOT_ARCHER_PREFERRED_RANGE = 52
local BOT_ARCHER_ATTACK_INTERVAL = 2.2
local BOT_MOVE_SPEED = 18
local BOT_COMMANDER_MOVE_SPEED = 15
local BOT_BLOCK_DAMAGE_MULTIPLIER = 0.42

local function getTeamColor(session, teamId)
    for _, team in ipairs(session.Scenario.Teams) do
        if team.Id == teamId then
            return team.AccentColor
        end
    end

    return Color3.fromRGB(182, 145, 88)
end

local function getEntryModel(entry)
    if entry.Kind == "Player" and entry.Player and entry.Player.Character and entry.Player.Character.Parent then
        return entry.Player.Character
    end

    if entry.Model and entry.Model.Parent then
        return entry.Model
    end

    return nil
end

local function getEntryHumanoid(entry)
    local model = getEntryModel(entry)

    if not model then
        return nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        return humanoid
    end

    return nil
end

local function getEntryRoot(entry)
    local model = getEntryModel(entry)
    local root = model and model:FindFirstChild("HumanoidRootPart")

    if root and root:IsA("BasePart") then
        return root
    end

    return nil
end

local function isBlocking(model)
    local blockingUntil = model:GetAttribute("BlockingUntil")

    return type(blockingUntil) == "number" and blockingUntil > os.clock()
end

local function spawnPulse(position, color, radius, lifetime)
    local pulse = Instance.new("Part")
    pulse.Name = "BattleBotPulse"
    pulse.Shape = Enum.PartType.Ball
    pulse.Size = Vector3.new(radius, radius, radius)
    pulse.Material = Enum.Material.Neon
    pulse.Color = color
    pulse.Transparency = 0.2
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse.CFrame = CFrame.new(position)
    pulse.Parent = Workspace
    Debris:AddItem(pulse, lifetime)
end

local function applyDamage(session, attackerEntry, targetEntry, damage, impactPosition)
    local attackerModel = getEntryModel(attackerEntry)
    local targetModel = getEntryModel(targetEntry)
    local targetHumanoid = getEntryHumanoid(targetEntry)
    local targetRoot = getEntryRoot(targetEntry)

    if not attackerModel or not targetModel or not targetHumanoid then
        return false
    end

    if attackerModel:GetAttribute("BattleTeam") == targetModel:GetAttribute("BattleTeam") then
        return false
    end

    local finalDamage = damage
    local blocked = isBlocking(targetModel)

    if blocked then
        finalDamage = math.max(4, math.floor(damage * BOT_BLOCK_DAMAGE_MULTIPLIER))
    end

    if targetEntry.IsCommander then
        finalDamage = math.min(finalDamage, math.max(0, targetHumanoid.Health - 1))

        if finalDamage <= 0 then
            return false
        end
    end

    targetHumanoid:TakeDamage(finalDamage)

    if impactPosition or targetRoot then
        spawnPulse(impactPosition or targetRoot.Position, blocked and Color3.fromRGB(223, 198, 126) or getTeamColor(session, attackerEntry.TeamId), blocked and 2.6 or 2.1, blocked and 0.2 or 0.16)
    end

    return true
end

local function orientModel(model, fromPosition, lookAtPosition)
    local flatLookAt = Vector3.new(lookAtPosition.X, fromPosition.Y, lookAtPosition.Z)

    if (flatLookAt - fromPosition).Magnitude < 0.05 then
        return
    end

    model:PivotTo(CFrame.lookAt(fromPosition, flatLookAt))
end

local function moveModel(model, currentPosition, nextPosition, lookAtPosition)
    local blendedPosition = currentPosition:Lerp(nextPosition, 0.82)
    local flatLookAt = Vector3.new(lookAtPosition.X, blendedPosition.Y, lookAtPosition.Z)
    model:PivotTo(CFrame.lookAt(blendedPosition, flatLookAt))
end

local function createArrow(teamColor, origin, direction)
    local arrow = Instance.new("Part")
    arrow.Name = "BattleBotArrow"
    arrow.Size = Vector3.new(0.24, 0.24, 4.6)
    arrow.Color = Color3.fromRGB(114, 77, 46)
    arrow.Material = Enum.Material.Wood
    arrow.CanCollide = false
    arrow.CanTouch = true
    arrow.CanQuery = true
    arrow.CFrame = CFrame.lookAt(origin, origin + direction)
    arrow.Parent = Workspace

    local tip = Instance.new("Part")
    tip.Name = "ArrowTip"
    tip.Size = Vector3.new(0.28, 0.28, 0.52)
    tip.Color = Color3.fromRGB(191, 191, 191)
    tip.Material = Enum.Material.Metal
    tip.CanCollide = false
    tip.CanTouch = false
    tip.CanQuery = false
    tip.Massless = true
    tip.CFrame = arrow.CFrame * CFrame.new(0, 0, -2.2)
    tip.Parent = arrow

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = arrow
    weld.Part1 = tip
    weld.Parent = arrow

    local headAttachment = Instance.new("Attachment")
    headAttachment.Position = Vector3.new(0, 0, -2.2)
    headAttachment.Parent = arrow

    local tailAttachment = Instance.new("Attachment")
    tailAttachment.Position = Vector3.new(0, 0, 2.2)
    tailAttachment.Parent = arrow

    local trail = Instance.new("Trail")
    trail.Attachment0 = headAttachment
    trail.Attachment1 = tailAttachment
    trail.Color = ColorSequence.new(teamColor, Color3.fromRGB(239, 216, 171))
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Lifetime = 0.12
    trail.MinLength = 0.1
    trail.FaceCamera = true
    trail.Parent = arrow

    return arrow
end

local function fireArrow(session, entry, targetEntry)
    local model = getEntryModel(entry)
    local root = getEntryRoot(entry)
    local targetRoot = getEntryRoot(targetEntry)

    if not model or not root or not targetRoot then
        return
    end

    local origin = root.Position + Vector3.new(0, 1.6, 0)
    local targetPoint = targetRoot.Position + Vector3.new(0, 1.6, 0)
    local direction = (targetPoint - origin).Unit
    local arrow = createArrow(getTeamColor(session, entry.TeamId), origin, direction)
    local damaged = false
    local touchConnection

    arrow.AssemblyLinearVelocity = direction * 138 + Vector3.new(0, 3.5, 0)

    touchConnection = arrow.Touched:Connect(function(hitPart)
        if damaged then
            return
        end

        local hitModel = hitPart:FindFirstAncestorOfClass("Model")

        if not hitModel or hitModel == model then
            return
        end

        for _, team in ipairs(session.Scenario.Teams) do
            for _, candidate in ipairs(session.Teams[team.Id]) do
                local candidateModel = getEntryModel(candidate)

                if candidate.Alive and candidateModel == hitModel then
                    if applyDamage(session, entry, candidate, entry.IsCommander and 26 or 18, hitPart.Position) then
                        damaged = true
                        if touchConnection then
                            touchConnection:Disconnect()
                        end
                        arrow:Destroy()
                    end

                    return
                end
            end
        end

        damaged = true

        if touchConnection then
            touchConnection:Disconnect()
        end

        spawnPulse(hitPart.Position, getTeamColor(session, entry.TeamId), 1.8, 0.14)
        arrow:Destroy()
    end)

    Debris:AddItem(arrow, 4.8)
end

local function pickTarget(session, entry)
    local root = getEntryRoot(entry)

    if not root then
        return nil
    end

    local bestEntry = nil
    local bestScore = math.huge

    for _, team in ipairs(session.Scenario.Teams) do
        if team.Id ~= entry.TeamId then
            for _, candidate in ipairs(session.Teams[team.Id]) do
                if candidate.Alive then
                    local candidateRoot = getEntryRoot(candidate)
                    local candidateHumanoid = getEntryHumanoid(candidate)

                    if candidateRoot and candidateHumanoid then
                        if candidate.IsCommander then
                            continue
                        end

                        local distance = (candidateRoot.Position - root.Position).Magnitude
                        local score = distance

                        if candidate.Kind == "Player" then
                            score -= 7
                        end

                        if score < bestScore then
                            bestScore = score
                            bestEntry = candidate
                        end
                    end
                end
            end
        end
    end

    return bestEntry
end

local function updateBot(session, entry, stepSeconds)
    local model = getEntryModel(entry)
    local root = getEntryRoot(entry)
    local humanoid = getEntryHumanoid(entry)

    if not entry.Alive or not model or not root or not humanoid then
        entry.Alive = false
        return
    end

    local targetEntry = pickTarget(session, entry)

    if not targetEntry then
        return
    end

    local targetRoot = getEntryRoot(targetEntry)

    if not targetRoot then
        return
    end

    local now = os.clock()
    local offset = targetRoot.Position - root.Position
    local flatOffset = Vector3.new(offset.X, 0, offset.Z)
    local distance = flatOffset.Magnitude
    local style = entry.BotStyle or "Melee"
    local moveSpeed = entry.IsCommander and BOT_COMMANDER_MOVE_SPEED or BOT_MOVE_SPEED

    if distance < 0.05 then
        orientModel(model, root.Position, targetRoot.Position)
        return
    end

    local direction = flatOffset.Unit

    if style == "Archer" then
        if distance > BOT_ARCHER_PREFERRED_RANGE then
            local nextPosition = root.Position + direction * math.min(moveSpeed * stepSeconds, distance - BOT_ARCHER_PREFERRED_RANGE)
            moveModel(model, root.Position, nextPosition, targetRoot.Position)
        elseif distance < BOT_ARCHER_MIN_RANGE then
            local retreatPosition = root.Position - direction * math.min((moveSpeed + 2) * stepSeconds, BOT_ARCHER_MIN_RANGE - distance + 1.5)
            moveModel(model, root.Position, retreatPosition, targetRoot.Position)
        else
            local strafeDirection = entry.StrafeDirection or (((entry.FormationIndex or 1) % 2 == 0) and 1 or -1)
            entry.StrafeDirection = strafeDirection
            local sideways = Vector3.new(-direction.Z, 0, direction.X) * strafeDirection
            local nextPosition = root.Position + sideways * math.min(4.2 * stepSeconds, 1.2)
            moveModel(model, root.Position, nextPosition, targetRoot.Position)
        end

        if distance <= BOT_ARCHER_RANGE and distance >= BOT_ARCHER_MIN_RANGE * 0.8 and now - (entry.LastAttackAt or 0) >= BOT_ARCHER_ATTACK_INTERVAL then
            entry.LastAttackAt = now
            fireArrow(session, entry, targetEntry)
        end

        return
    end

    if distance > BOT_MELEE_RANGE then
        local nextPosition = root.Position + direction * math.min(moveSpeed * stepSeconds, distance - BOT_MELEE_RANGE + 1)
        moveModel(model, root.Position, nextPosition, targetRoot.Position)
        return
    end

    orientModel(model, root.Position, targetRoot.Position)

    if now - (entry.LastAttackAt or 0) < BOT_MELEE_ATTACK_INTERVAL then
        return
    end

    entry.LastAttackAt = now
    spawnPulse(root.Position + direction * 3.8 + Vector3.new(0, 1.3, 0), getTeamColor(session, entry.TeamId), entry.IsCommander and 3.6 or 2.8, 0.12)
    applyDamage(session, entry, targetEntry, entry.IsCommander and BOT_COMMANDER_DAMAGE or BOT_MELEE_DAMAGE, targetRoot.Position + Vector3.new(0, 1.4, 0))
end

function BattleBots.Start(session)
    local accumulator = 0
    local connection

    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if session.Ended then
            if connection then
                connection:Disconnect()
            end
            return
        end

        accumulator += deltaTime

        if accumulator < BOT_STEP_SECONDS then
            return
        end

        local stepSeconds = accumulator
        accumulator = 0

        for _, team in ipairs(session.Scenario.Teams) do
            for _, entry in ipairs(session.Teams[team.Id]) do
                if entry.Kind == "Dummy" then
                    updateBot(session, entry, stepSeconds)
                end
            end
        end
    end)

    table.insert(session.Connections, connection)
end

return BattleBots
