--!nonstrict

-- Server-controlled soldiers for the story missions: an R6 rig built from parts, dressed in
-- simple robes, driven by Humanoid:MoveTo so it walks on the real ground, and animated with
-- Roblox's stock R6 animations. Opponents and allies share this code; `Team` decides who they fight.
--
-- Soldiers are generic and unnamed. Nothing here represents the Prophet, peace be upon him,
-- or any named companion.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BattleNpc = {}

local COMBATANT_TAG = "BattleCombatant"
local BLOCK_DAMAGE_MULTIPLIER = 0.28
local THINK_SECONDS = 0.2
local AGGRO_RADIUS = 75
local ALLY_AGGRO_RADIUS = 60
local ALLY_LEASH = 46
local STRUCTURE_AGGRO = 46
local ARROW_SPEED = 120
local ARROW_GRAVITY = 38

-- Stock Roblox R6 animations (the same ones the default Animate script uses).
local ANIMATIONS = {
    Idle = "rbxassetid://180435571",
    Walk = "rbxassetid://180426354",
    Slash = "rbxassetid://129967390",
    Lunge = "rbxassetid://129967478",
    Hold = "rbxassetid://182393478",
}

local SWING_SOUND = "rbxasset://sounds/swordslash.wav"
local HIT_SOUND = "rbxasset://sounds/swordlunge.wav"
local BOW_SOUND = "rbxasset://sounds/unsheath.wav"
local BLOCK_SOUND = "rbxasset://sounds/collide.wav"

local SKIN_TONES = {
    Color3.fromRGB(198, 150, 110),
    Color3.fromRGB(176, 127, 88),
    Color3.fromRGB(150, 104, 70),
    Color3.fromRGB(214, 172, 130),
    Color3.fromRGB(124, 86, 58),
}

-- Standard R6 joint frames.
local JOINTS = {
    { Name = "RootJoint", Part0 = "HumanoidRootPart", Part1 = "Torso", C0 = { 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0 }, C1 = { 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0 } },
    { Name = "Neck", Part0 = "Torso", Part1 = "Head", C0 = { 0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0 }, C1 = { 0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0 } },
    { Name = "Right Shoulder", Part0 = "Torso", Part1 = "Right Arm", C0 = { 1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0 }, C1 = { -0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0 } },
    { Name = "Left Shoulder", Part0 = "Torso", Part1 = "Left Arm", C0 = { -1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0 }, C1 = { 0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0 } },
    { Name = "Right Hip", Part0 = "Torso", Part1 = "Right Leg", C0 = { 1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0 }, C1 = { 0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0 } },
    { Name = "Left Hip", Part0 = "Torso", Part1 = "Left Leg", C0 = { -1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0 }, C1 = { -0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0 } },
}

local function scaledFrame(values, scale: number): CFrame
    return CFrame.new(
        values[1] * scale, values[2] * scale, values[3] * scale,
        values[4], values[5], values[6],
        values[7], values[8], values[9],
        values[10], values[11], values[12]
    )
end

local function shade(color: Color3, factor: number): Color3
    return Color3.new(math.clamp(color.R * factor, 0, 1), math.clamp(color.G * factor, 0, 1), math.clamp(color.B * factor, 0, 1))
end

local function playSound(parent: Instance, soundId: string, volume: number, speed: number?)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.PlaybackSpeed = speed or 1
    sound.RollOffMaxDistance = 120
    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 3)
end

local function bodyPart(model: Model, name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CanCollide = false
    part.Parent = model

    return part
end

-- Decorative part welded to a body part. Massless and non-colliding so it never trips the rig.
local function dress(model: Model, base: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.CanCollide = false
    part.CanTouch = true
    part.CanQuery = true
    part.Massless = true
    part.CastShadow = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    if shape then
        part.Shape = shape
    end

    part.CFrame = base.CFrame * offset
    part.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = base
    weld.Part1 = part
    weld.Parent = part

    return part
end

local function dressWeapon(model: Model, unit, scale: number)
    local rightArm = model:FindFirstChild("Right Arm") :: BasePart
    local leftArm = model:FindFirstChild("Left Arm") :: BasePart
    local torso = model:FindFirstChild("Torso") :: BasePart
    local wood = Color3.fromRGB(104, 72, 44)
    local steel = Color3.fromRGB(205, 205, 200)
    local s = scale

    if unit.Weapon == "Sword" then
        -- Held point-forward from the right hand.
        dress(model, rightArm, "SwordGrip", Vector3.new(0.3, 0.3, 1.1) * s, CFrame.new(0, -1.05 * s, -0.4 * s), wood, Enum.Material.Wood)
        dress(model, rightArm, "SwordGuard", Vector3.new(1.2, 0.2, 0.25) * s, CFrame.new(0, -1.05 * s, -1 * s), Color3.fromRGB(184, 152, 88), Enum.Material.Metal)
        dress(model, rightArm, "SwordBlade", Vector3.new(0.18, 0.32, 3.2) * s, CFrame.new(0, -1.05 * s, -2.7 * s), steel, Enum.Material.Metal)
        dress(model, leftArm, "Shield", Vector3.new(0.3, 2.6, 2.6) * s, CFrame.new(-0.62 * s, -0.2 * s, 0), Color3.fromRGB(98, 74, 46), Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
        dress(model, leftArm, "ShieldBoss", Vector3.new(0.4, 0.7, 0.7) * s, CFrame.new(-0.8 * s, -0.2 * s, 0), Color3.fromRGB(184, 152, 88), Enum.Material.Metal, Enum.PartType.Ball)
    elseif unit.Weapon == "Spear" then
        dress(model, rightArm, "SpearShaft", Vector3.new(0.22, 0.22, 8.5) * s, CFrame.new(0, -1.05 * s, -1.6 * s), wood, Enum.Material.Wood)
        dress(model, rightArm, "SpearHead", Vector3.new(0.3, 0.12, 1.1) * s, CFrame.new(0, -1.05 * s, -6.3 * s), steel, Enum.Material.Metal)
        dress(model, leftArm, "Shield", Vector3.new(0.3, 2.3, 2.3) * s, CFrame.new(-0.62 * s, -0.2 * s, 0), Color3.fromRGB(110, 84, 52), Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
    elseif unit.Weapon == "Bow" then
        dress(model, leftArm, "BowGrip", Vector3.new(0.2, 0.2, 0.5) * s, CFrame.new(0, -1.05 * s, -0.3 * s), wood, Enum.Material.Wood)
        dress(model, leftArm, "BowUpper", Vector3.new(0.16, 2.1, 0.16) * s, CFrame.new(0, -0.1 * s, -0.55 * s) * CFrame.Angles(math.rad(-16), 0, 0), wood, Enum.Material.Wood)
        dress(model, leftArm, "BowLower", Vector3.new(0.16, 2.1, 0.16) * s, CFrame.new(0, -2 * s, -0.55 * s) * CFrame.Angles(math.rad(16), 0, 0), wood, Enum.Material.Wood)
        dress(model, torso, "Quiver", Vector3.new(0.8, 2.2, 0.8) * s, CFrame.new(0.5 * s, 0.4 * s, 0.75 * s) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(96, 64, 40), Enum.Material.Fabric)
    end
end

local function buildRig(unit, name: string, position: Vector3, facing: Vector3): Model
    local s = unit.Scale or 1
    local model = Instance.new("Model")
    model.Name = name
    local skin = SKIN_TONES[math.random(1, #SKIN_TONES)]
    local robe: Color3 = unit.Robe
    local accent: Color3 = unit.Accent

    local root = bodyPart(model, "HumanoidRootPart", Vector3.new(2, 2, 1) * s, robe)
    root.Transparency = 1
    root.CanCollide = true
    local torso = bodyPart(model, "Torso", Vector3.new(2, 2, 1) * s, robe, Enum.Material.Fabric)
    torso.CanCollide = true
    local head = bodyPart(model, "Head", Vector3.new(2, 1, 1) * s, skin)
    head.CanCollide = true
    bodyPart(model, "Right Arm", Vector3.new(1, 2, 1) * s, robe, Enum.Material.Fabric)
    bodyPart(model, "Left Arm", Vector3.new(1, 2, 1) * s, robe, Enum.Material.Fabric)
    bodyPart(model, "Right Leg", Vector3.new(1, 2, 1) * s, shade(robe, 0.86), Enum.Material.Fabric)
    bodyPart(model, "Left Leg", Vector3.new(1, 2, 1) * s, shade(robe, 0.86), Enum.Material.Fabric)

    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
    headMesh.Parent = head

    local face = Instance.new("Decal")
    face.Name = "face"
    face.Texture = "rbxasset://textures/face.png"
    face.Face = Enum.NormalId.Front
    face.Parent = head

    local rootFrame = CFrame.lookAt(position, Vector3.new(facing.X, position.Y, facing.Z))
    root.CFrame = rootFrame
    torso.CFrame = rootFrame
    head.CFrame = rootFrame * CFrame.new(0, 1.5 * s, 0)
    for limbName, offset in pairs({
        ["Right Arm"] = Vector3.new(1.5, 0, 0),
        ["Left Arm"] = Vector3.new(-1.5, 0, 0),
        ["Right Leg"] = Vector3.new(0.5, -2, 0),
        ["Left Leg"] = Vector3.new(-0.5, -2, 0),
    }) do
        local limb = model:FindFirstChild(limbName) :: BasePart
        limb.CFrame = rootFrame * CFrame.new(offset * s)
    end

    for _, joint in ipairs(JOINTS) do
        local motor = Instance.new("Motor6D")
        motor.Name = joint.Name
        motor.Part0 = model:FindFirstChild(joint.Part0) :: BasePart
        motor.Part1 = model:FindFirstChild(joint.Part1) :: BasePart
        motor.C0 = scaledFrame(joint.C0, s)
        motor.C1 = scaledFrame(joint.C1, s)
        motor.MaxVelocity = 0.1
        motor.Parent = joint.Part0 == "HumanoidRootPart" and root or torso
    end

    -- Clothing: a long robe over the legs, a sash, and a head wrap.
    dress(model, torso, "Robe", Vector3.new(2.15, 2.5, 1.2) * s, CFrame.new(0, -1.9 * s, 0), robe, Enum.Material.Fabric)
    dress(model, torso, "Belt", Vector3.new(2.12, 0.3, 1.12) * s, CFrame.new(0, -0.8 * s, 0), accent, Enum.Material.Fabric)
    dress(model, torso, "Sash", Vector3.new(0.36, 2.25, 1.1) * s, CFrame.new(0.2 * s, 0.05 * s, 0) * CFrame.Angles(0, 0, math.rad(-38)), accent, Enum.Material.Fabric)
    dress(model, head, "HeadWrap", Vector3.new(1.45, 0.75, 1.45) * s, CFrame.new(0, 0.42 * s, 0), unit.Team == "medina" and Color3.fromRGB(236, 232, 220) or shade(accent, 1.4), Enum.Material.Fabric, Enum.PartType.Ball)
    dress(model, head, "WrapTail", Vector3.new(0.5, 1, 0.25) * s, CFrame.new(0, -0.2 * s, 0.62 * s), unit.Team == "medina" and Color3.fromRGB(228, 222, 206) or accent, Enum.Material.Fabric)

    if unit.Boss then
        dress(model, torso, "Mantle", Vector3.new(2.6, 0.5, 1.4) * s, CFrame.new(0, 0.95 * s, 0), accent, Enum.Material.Metal)
        dress(model, torso, "Cape", Vector3.new(2.3, 3.6, 0.2) * s, CFrame.new(0, -0.7 * s, 0.62 * s), Color3.fromRGB(110, 34, 30), Enum.Material.Fabric)
    end

    dressWeapon(model, unit, s)

    local humanoid = Instance.new("Humanoid")
    humanoid.RigType = Enum.HumanoidRigType.R6
    humanoid.MaxHealth = unit.Health
    humanoid.Health = unit.Health
    humanoid.WalkSpeed = unit.WalkSpeed
    humanoid.DisplayName = unit.DisplayName
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
    humanoid.NameDisplayDistance = unit.Boss and 140 or 55
    humanoid.HealthDisplayDistance = unit.Boss and 140 or 55
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = model

    local animator = Instance.new("Animator")
    animator.Parent = humanoid

    model.PrimaryPart = root

    return model
end

local function loadTrack(animator: Animator, id: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack?
    local animation = Instance.new("Animation")
    animation.AnimationId = id

    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)

    if not ok or not track then
        return nil
    end

    track.Priority = priority
    track.Looped = looped

    return track
end

local function flatDistance(a: Vector3, b: Vector3): number
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function isBlocking(model: Instance): boolean
    local untilTime = model:GetAttribute("BlockingUntil")

    return type(untilTime) == "number" and untilTime > os.clock()
end

local function flash(position: Vector3, color: Color3, size: number)
    local part = Instance.new("Part")
    part.Name = "HitFlash"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.35
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CFrame = CFrame.new(position)
    part.Parent = Workspace
    Debris:AddItem(part, 0.18)
end

local function showWarning(npc)
    local head = npc.Model:FindFirstChild("Head")

    if not head then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AttackWarning"
    billboard.Size = UDim2.fromOffset(34, 34)
    billboard.StudsOffset = Vector3.new(0, 2.6 * (npc.Unit.Scale or 1), 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 70
    billboard.Adornee = head
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = "!"
    label.TextScaled = true
    label.TextColor3 = npc.Team == "makkah" and Color3.fromRGB(255, 120, 82) or Color3.fromRGB(150, 230, 160)
    label.TextStrokeTransparency = 0.2
    label.Parent = billboard

    Debris:AddItem(billboard, npc.Unit.WindupSeconds + 0.1)
end

-- World -------------------------------------------------------------------------------

local World = {}
World.__index = World

-- `options.Folder`: where soldiers and arrows live. `options.GetPlayers`: players in the mission.
-- `options.OnDeath(npc, killerPlayer)`: called once when a soldier falls.
function BattleNpc.NewWorld(options)
    local world = setmetatable({
        Folder = options.Folder,
        GetPlayers = options.GetPlayers,
        OnDeath = options.OnDeath,
        OnStructureDamaged = options.OnStructureDamaged,
        Npcs = {},
        Structures = {},
        Running = true,
        HealthMultiplier = 1,
        DamageMultiplier = 1,
    }, World)

    local arrowFolder = Instance.new("Folder")
    arrowFolder.Name = "Arrows"
    arrowFolder.Parent = options.Folder
    world.ArrowFolder = arrowFolder

    local cursor = 0

    world.Connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not world.Running then
            return
        end

        -- Spread the thinking across frames so every soldier thinks about every THINK_SECONDS.
        local count = #world.Npcs

        if count == 0 then
            return
        end

        local budget = math.clamp(math.ceil(count * deltaTime / THINK_SECONDS), 1, count)

        for _ = 1, budget do
            cursor = (cursor % count) + 1
            local npc = world.Npcs[cursor]

            if npc and npc.Alive then
                local ok, err = pcall(world.Think, world, npc)

                if not ok then
                    warn("[BattleNpc] think failed:", err)
                end
            end
        end
    end)

    return world
end

-- A destructible objective (the Badr banner). Opponents attack it when no one stands in the way.
function World:AddStructure(structure)
    structure.Alive = true
    table.insert(self.Structures, structure)
end

function World:DamageStructure(structure, amount: number)
    if not structure.Alive then
        return
    end

    structure.Health = math.max(0, structure.Health - amount)

    if self.OnStructureDamaged then
        self.OnStructureDamaged(structure)
    end

    if structure.Health <= 0 then
        structure.Alive = false
    end
end

function World:CountAlive(team: string, tag: string?): number
    local count = 0

    for _, npc in ipairs(self.Npcs) do
        if npc.Alive and npc.Team == team and (tag == nil or npc.Tag == tag) then
            count += 1
        end
    end

    return count
end

function World:GetAlive(team: string, tag: string?)
    local list = {}

    for _, npc in ipairs(self.Npcs) do
        if npc.Alive and npc.Team == team and (tag == nil or npc.Tag == tag) then
            table.insert(list, npc)
        end
    end

    return list
end

-- Spawns one soldier standing at `position` (already on the ground). `lane` is an optional
-- list of ground points to walk through before fighting at `goal`.
function World:Spawn(unit, position: Vector3, facing: Vector3, options)
    options = options or {}
    local s = unit.Scale or 1
    local model = buildRig(unit, unit.DisplayName, position + Vector3.new(0, 3 * s + 0.2, 0), facing)
    local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
    local root = model:FindFirstChild("HumanoidRootPart") :: BasePart

    if not unit.Boss and self.HealthMultiplier ~= 1 and unit.Team == "makkah" then
        humanoid.MaxHealth = math.floor(unit.Health * self.HealthMultiplier)
        humanoid.Health = humanoid.MaxHealth
    elseif unit.Boss then
        humanoid.MaxHealth = math.floor(unit.Health * (1 + (self.HealthMultiplier - 1) * 1.5))
        humanoid.Health = humanoid.MaxHealth
    end

    model:SetAttribute("BattleTeam", unit.Team)
    model:SetAttribute("MissionNpc", true)
    model:SetAttribute("BattleCommander", unit.Boss == true)
    model.Parent = self.Folder
    CollectionService:AddTag(model, COMBATANT_TAG)

    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator
    local npc = {
        Unit = unit,
        Team = unit.Team,
        Tag = options.Tag,
        Model = model,
        Humanoid = humanoid,
        Root = root,
        Alive = true,
        Lane = options.Lane,
        LaneIndex = 1,
        Goal = options.Goal,
        HoldPoint = options.HoldPoint,
        FormationOffset = options.FormationOffset or Vector3.zero,
        LastAttack = os.clock() + math.random() * 0.8,
        Busy = false,
        LastPosition = root.Position,
        LastMovedAt = os.clock(),
        Path = nil,
        PathIndex = 0,
        PathUntil = 0,
        Tracks = {
            Idle = loadTrack(animator, ANIMATIONS.Idle, Enum.AnimationPriority.Idle, true),
            Walk = loadTrack(animator, ANIMATIONS.Walk, Enum.AnimationPriority.Movement, true),
            Slash = loadTrack(animator, unit.Weapon == "Spear" and ANIMATIONS.Lunge or ANIMATIONS.Slash, Enum.AnimationPriority.Action, false),
            Hold = loadTrack(animator, ANIMATIONS.Hold, Enum.AnimationPriority.Core, true),
        },
    }

    if npc.Tracks.Idle then
        npc.Tracks.Idle:Play()
    end

    if npc.Tracks.Hold then
        npc.Tracks.Hold:Play()
    end

    humanoid.Running:Connect(function(speed)
        local walk = npc.Tracks.Walk

        if not walk then
            return
        end

        if speed > 0.6 and not walk.IsPlaying then
            walk:Play(0.15)
        elseif speed <= 0.6 and walk.IsPlaying then
            walk:Stop(0.2)
        end

        if walk.IsPlaying then
            walk:AdjustSpeed(math.clamp(speed / 14, 0.6, 1.6))
        end
    end)

    humanoid.Died:Connect(function()
        self:HandleDeath(npc)
    end)

    -- Forget soldiers whose fade-out has finished.
    for index = #self.Npcs, 1, -1 do
        local old = self.Npcs[index]

        if not old.Alive and not old.Model.Parent then
            table.remove(self.Npcs, index)
        end
    end

    table.insert(self.Npcs, npc)

    return npc
end

function World:HandleDeath(npc)
    if not npc.Alive then
        return
    end

    npc.Alive = false
    CollectionService:RemoveTag(npc.Model, COMBATANT_TAG)

    local killer = nil
    local attackerId = npc.Humanoid:GetAttribute("LastAttackerUserId")

    if type(attackerId) == "number" then
        killer = Players:GetPlayerByUserId(attackerId)
    end

    if self.OnDeath then
        task.spawn(self.OnDeath, npc, killer)
    end

    -- Fade away rather than lying on the field.
    task.spawn(function()
        task.wait(0.6)

        for step = 1, 10 do
            for _, part in ipairs(npc.Model:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = math.max(part.Transparency, step / 10)
                elseif part:IsA("Decal") then
                    part.Transparency = step / 10
                end
            end

            task.wait(0.06)
        end

        npc.Model:Destroy()
    end)
end

-- Removes a soldier quietly (end of an objective, or the mission is over).
function World:Dismiss(npc)
    if not npc.Alive then
        return
    end

    npc.Alive = false
    CollectionService:RemoveTag(npc.Model, COMBATANT_TAG)

    task.spawn(function()
        for step = 1, 8 do
            for _, part in ipairs(npc.Model:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = math.max(part.Transparency, step / 8)
                elseif part:IsA("Decal") then
                    part.Transparency = step / 8
                end
            end

            task.wait(0.05)
        end

        npc.Model:Destroy()
    end)
end

function World:DismissTeam(team: string)
    for _, npc in ipairs(self.Npcs) do
        if npc.Alive and npc.Team == team then
            self:Dismiss(npc)
        end
    end
end

function World:Destroy()
    self.Running = false

    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    for _, npc in ipairs(self.Npcs) do
        if npc.Model.Parent then
            CollectionService:RemoveTag(npc.Model, COMBATANT_TAG)
            npc.Model:Destroy()
        end
    end

    table.clear(self.Npcs)
    self.ArrowFolder:Destroy()
end

-- Target selection ------------------------------------------------------------------------

local function characterTarget(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return { Kind = "Character", Model = character, Humanoid = humanoid, Root = root }
    end

    return nil
end

function World:FindTarget(npc)
    local origin = npc.Root.Position
    local radius = npc.Team == "makkah" and AGGRO_RADIUS or ALLY_AGGRO_RADIUS
    local best, bestScore = nil, math.huge

    if npc.Team == "makkah" then
        for _, player in ipairs(self.GetPlayers()) do
            local character = player.Character

            if character and character:GetAttribute("BattleTeam") == "medina" then
                local target = characterTarget(character)

                if target then
                    -- Players are preferred a little over allied soldiers.
                    local score = (target.Root.Position - origin).Magnitude - 6

                    if score < radius and score < bestScore then
                        best, bestScore = target, score
                    end
                end
            end
        end
    end

    for _, other in ipairs(self.Npcs) do
        if other.Alive and other.Team ~= npc.Team then
            local score = (other.Root.Position - origin).Magnitude

            if score < radius and score < bestScore then
                best, bestScore = { Kind = "Npc", Npc = other, Model = other.Model, Humanoid = other.Humanoid, Root = other.Root }, score
            end
        end
    end

    if npc.Team == "makkah" then
        for _, structure in ipairs(self.Structures) do
            if structure.Alive then
                local distance = flatDistance(structure.Position, origin)

                -- Go for the banner when it is close and nobody is closer to fight.
                if distance < STRUCTURE_AGGRO and (best == nil or bestScore > 14) then
                    best, bestScore = { Kind = "Structure", Structure = structure, Position = structure.Position }, distance
                end
            end
        end
    end

    return best
end

local function targetPosition(target): Vector3
    if target.Kind == "Structure" then
        return target.Position
    end

    return target.Root.Position
end

local function targetAlive(target): boolean
    if target.Kind == "Structure" then
        return target.Structure.Alive
    end

    return target.Humanoid.Health > 0 and target.Model.Parent ~= nil
end

-- Movement ----------------------------------------------------------------------------

function World:MoveTowards(npc, destination: Vector3)
    local now = os.clock()
    local root = npc.Root
    local humanoid = npc.Humanoid
    humanoid.AutoRotate = true

    if (root.Position - npc.LastPosition).Magnitude > 1.2 then
        npc.LastPosition = root.Position
        npc.LastMovedAt = now
    end

    -- Following a computed path around an obstacle.
    if npc.Path and now < npc.PathUntil then
        local waypoint = npc.Path[npc.PathIndex]

        if waypoint then
            if flatDistance(waypoint.Position, root.Position) < 4 then
                npc.PathIndex += 1
                waypoint = npc.Path[npc.PathIndex]
            end

            if waypoint then
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end

                humanoid:MoveTo(waypoint.Position)

                return
            end
        end

        npc.Path = nil
    end

    humanoid:MoveTo(destination)

    local stuckFor = now - npc.LastMovedAt

    if stuckFor > 1.1 and flatDistance(destination, root.Position) > 6 then
        humanoid.Jump = true
    end

    if stuckFor > 2.4 and flatDistance(destination, root.Position) > 8 and not npc.Pathing then
        npc.Pathing = true
        npc.LastMovedAt = now

        task.spawn(function()
            local path = PathfindingService:CreatePath({
                AgentRadius = 2 * (npc.Unit.Scale or 1),
                AgentHeight = 5 * (npc.Unit.Scale or 1),
                AgentCanJump = true,
            })
            local ok = pcall(function()
                path:ComputeAsync(root.Position, destination)
            end)

            if ok and path.Status == Enum.PathStatus.Success and npc.Alive then
                npc.Path = path:GetWaypoints()
                npc.PathIndex = 2
                npc.PathUntil = os.clock() + 8
            end

            npc.Pathing = false
        end)
    end
end

function World:StopMoving(npc)
    npc.Humanoid:MoveTo(npc.Root.Position)
    npc.LastMovedAt = os.clock()
end

local function faceTowards(npc, position: Vector3)
    local root = npc.Root
    local flat = Vector3.new(position.X, root.Position.Y, position.Z)

    if (flat - root.Position).Magnitude > 0.1 then
        npc.Humanoid.AutoRotate = false
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end
end

-- Combat ------------------------------------------------------------------------------

function World:ApplyHit(npc, target, damage: number, impact: Vector3)
    if target.Kind == "Structure" then
        self:DamageStructure(target.Structure, damage)
        flash(impact, Color3.fromRGB(240, 196, 120), 2.2)
        return
    end

    local humanoid = target.Humanoid
    local model = target.Model

    if humanoid.Health <= 0 or model:GetAttribute("BattleTeam") == npc.Team then
        return
    end

    local finalDamage = damage

    if isBlocking(model) then
        finalDamage = math.max(2, math.floor(damage * BLOCK_DAMAGE_MULTIPLIER))
        playSound(target.Root, BLOCK_SOUND, 0.7, 1.1)
        flash(impact, Color3.fromRGB(222, 198, 126), 3)
    else
        playSound(target.Root, HIT_SOUND, 0.5, 1)
        flash(impact, npc.Team == "makkah" and Color3.fromRGB(214, 120, 84) or Color3.fromRGB(120, 196, 140), 2)
    end

    humanoid:TakeDamage(finalDamage)
end

function World:MeleeAttack(npc, target)
    npc.Busy = true
    npc.LastAttack = os.clock()
    showWarning(npc)

    if npc.Tracks.Slash then
        npc.Tracks.Slash:Play(0.05, 1, 0.85)
    end

    task.delay(npc.Unit.WindupSeconds, function()
        npc.Busy = false

        if not npc.Alive or not targetAlive(target) then
            return
        end

        local reach = npc.Unit.Reach + (target.Kind == "Structure" and 3 or 1.8)
        local position = targetPosition(target)

        if flatDistance(position, npc.Root.Position) > reach then
            return
        end

        playSound(npc.Root, SWING_SOUND, 0.45, 0.95 + math.random() * 0.1)
        local damage = math.floor(npc.Unit.Damage * (npc.Team == "makkah" and self.DamageMultiplier or 1))
        self:ApplyHit(npc, target, damage, position + Vector3.new(0, 1.5, 0))
    end)
end

function World:FireArrow(npc, target)
    npc.Busy = true
    npc.LastAttack = os.clock()
    showWarning(npc)

    task.delay(npc.Unit.WindupSeconds, function()
        npc.Busy = false

        if not npc.Alive or not targetAlive(target) or target.Kind == "Structure" then
            return
        end

        local origin = npc.Root.Position + Vector3.new(0, 1.6 * (npc.Unit.Scale or 1), 0)
        local aimPoint = target.Root.Position + Vector3.new(0, 0.8, 0)
        local velocity = target.Root.AssemblyLinearVelocity
        local travel = (aimPoint - origin).Magnitude / ARROW_SPEED
        -- Lead the target a little and aim up to cancel the drop, with a small spread.
        aimPoint += Vector3.new(velocity.X, 0, velocity.Z) * travel * 0.6
        aimPoint += Vector3.new(0, 0.5 * ARROW_GRAVITY * travel * travel, 0)
        aimPoint += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * (2 + travel * 6)

        playSound(npc.Root, BOW_SOUND, 0.4, 1.3)
        self:LaunchArrow(npc, origin, (aimPoint - origin).Unit * ARROW_SPEED)
    end)
end

function World:LaunchArrow(npc, origin: Vector3, velocity: Vector3)
    local arrow = Instance.new("Part")
    arrow.Name = "Arrow"
    arrow.Size = Vector3.new(0.18, 0.18, 3.4)
    arrow.Color = Color3.fromRGB(116, 80, 48)
    arrow.Material = Enum.Material.Wood
    arrow.Anchored = true
    arrow.CanCollide = false
    arrow.CanTouch = false
    arrow.CanQuery = false
    arrow.CFrame = CFrame.lookAt(origin, origin + velocity)
    arrow.Parent = self.ArrowFolder

    local tip = Instance.new("Part")
    tip.Name = "Tip"
    tip.Size = Vector3.new(0.26, 0.26, 0.5)
    tip.Color = Color3.fromRGB(190, 190, 186)
    tip.Material = Enum.Material.Metal
    tip.Anchored = true
    tip.CanCollide = false
    tip.CanTouch = false
    tip.CanQuery = false
    tip.Parent = arrow

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { npc.Model, self.ArrowFolder }

    local position = origin
    local currentVelocity = velocity
    local age = 0
    local connection

    connection = RunService.Heartbeat:Connect(function(deltaTime)
        age += deltaTime

        if age > 3 or not arrow.Parent then
            connection:Disconnect()
            arrow:Destroy()
            return
        end

        currentVelocity += Vector3.new(0, -ARROW_GRAVITY * deltaTime, 0)
        local step = currentVelocity * deltaTime
        local result = Workspace:Raycast(position, step, params)

        if result then
            connection:Disconnect()
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            local humanoid = hitModel and hitModel:FindFirstChildOfClass("Humanoid")

            if humanoid and hitModel:GetAttribute("BattleTeam") and hitModel:GetAttribute("BattleTeam") ~= npc.Team then
                local hitRoot = hitModel:FindFirstChild("HumanoidRootPart")
                self:ApplyHit(npc, {
                    Kind = "Character",
                    Model = hitModel,
                    Humanoid = humanoid,
                    Root = hitRoot and hitRoot:IsA("BasePart") and hitRoot or result.Instance,
                }, npc.Unit.Damage, result.Position)
                arrow:Destroy()
            else
                -- Stick in the ground for a moment.
                arrow.CFrame = CFrame.lookAt(result.Position, result.Position + currentVelocity)
                tip.CFrame = arrow.CFrame * CFrame.new(0, 0, -1.6)
                Debris:AddItem(arrow, 2)
            end

            return
        end

        position += step
        arrow.CFrame = CFrame.lookAt(position, position + currentVelocity)
        tip.CFrame = arrow.CFrame * CFrame.new(0, 0, -1.8)
    end)
end

-- Thinking ----------------------------------------------------------------------------

function World:Think(npc)
    local humanoid = npc.Humanoid

    if humanoid.Health <= 0 or not npc.Model.Parent then
        return
    end

    if npc.Busy then
        return
    end

    local root = npc.Root
    local unit = npc.Unit
    local origin = root.Position

    -- Deserting allies walk to their destination and ignore the fight.
    if npc.ForcedDestination then
        humanoid.AutoRotate = true

        if flatDistance(npc.ForcedDestination, origin) > 5 then
            self:MoveTowards(npc, npc.ForcedDestination)
        else
            self:StopMoving(npc)
        end

        return
    end

    -- Follow the approach lane first.
    if npc.Lane and npc.LaneIndex <= #npc.Lane then
        local waypoint = npc.Lane[npc.LaneIndex]

        if flatDistance(waypoint, origin) < 9 then
            npc.LaneIndex += 1
        end

        local nearby = self:FindTarget(npc)

        if not nearby or (targetPosition(nearby) - origin).Magnitude > 32 then
            if npc.LaneIndex <= #npc.Lane then
                humanoid.AutoRotate = true
                self:MoveTowards(npc, npc.Lane[npc.LaneIndex])
                return
            end
        else
            npc.LaneIndex = #npc.Lane + 1
        end
    end

    local target = self:FindTarget(npc)

    -- Allies stay near the point they were told to hold.
    if npc.Team == "medina" and npc.HoldPoint then
        local holdPoint = npc.HoldPoint + npc.FormationOffset

        if flatDistance(holdPoint, origin) > ALLY_LEASH or (target and flatDistance(targetPosition(target), holdPoint) > ALLY_LEASH + 12) then
            humanoid.AutoRotate = true
            self:MoveTowards(npc, holdPoint)
            return
        end

        if not target then
            if flatDistance(holdPoint, origin) > 4 then
                humanoid.AutoRotate = true
                self:MoveTowards(npc, holdPoint)
            else
                self:StopMoving(npc)
            end

            return
        end
    end

    if not target then
        local goal = npc.Goal

        if goal and flatDistance(goal, origin) > 6 then
            humanoid.AutoRotate = true
            self:MoveTowards(npc, goal + npc.FormationOffset)
        else
            self:StopMoving(npc)
        end

        return
    end

    local position = targetPosition(target)
    local distance = flatDistance(position, origin)
    local now = os.clock()

    if unit.Style == "Ranged" and target.Kind ~= "Structure" then
        if distance > unit.Reach then
            humanoid.AutoRotate = true
            self:MoveTowards(npc, position)
        elseif distance < (unit.MinRange or 20) then
            local away = (origin - position)
            away = Vector3.new(away.X, 0, away.Z)
            humanoid.AutoRotate = true
            self:MoveTowards(npc, origin + (away.Magnitude > 0.1 and away.Unit or Vector3.xAxis) * 14)
        else
            self:StopMoving(npc)
            faceTowards(npc, position)

            if now - npc.LastAttack >= unit.CooldownSeconds then
                self:FireArrow(npc, target)
            end
        end

        return
    end

    local reach = unit.Reach + (target.Kind == "Structure" and 2.5 or 0)

    if distance > reach then
        humanoid.AutoRotate = true
        self:MoveTowards(npc, position)
        return
    end

    self:StopMoving(npc)
    faceTowards(npc, position)

    if now - npc.LastAttack >= unit.CooldownSeconds then
        self:MeleeAttack(npc, target)
    end
end

return BattleNpc
