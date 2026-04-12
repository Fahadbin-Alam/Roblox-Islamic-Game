--!strict

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopCatalog = require(Shared.Data.ShopCatalog)
local battleFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Battle")
local requestBlock = battleFolder:WaitForChild("RequestBlock") :: RemoteEvent

local BattleLoadout = {}

local SWORD_SWING_SOUND = "rbxasset://sounds/swordslash.wav"
local SWORD_HIT_SOUND = "rbxasset://sounds/swordlunge.wav"
local SWORD_DRAW_SOUND = "rbxasset://sounds/unsheath.wav"
local BOW_DRAW_SOUND = "rbxasset://sounds/unsheath.wav"
local BOW_RELEASE_SOUND = "rbxasset://sounds/swordslash.wav"
local BOW_HIT_SOUND = "rbxasset://sounds/collide.wav"
local BLOCK_SOUND = "rbxasset://sounds/collide.wav"

local BLOCK_WINDOW_SECONDS = 1.1
local BLOCK_COOLDOWN_SECONDS = 1.8
local BLOCK_DAMAGE_MULTIPLIER = 0.28
local SWORD_SWING_COOLDOWN_SECONDS = 0.36
local SWORD_SWING_RANGE = 12
local BOW_DRAW_TIME_SECONDS = 0.9
local BOW_SHOT_COOLDOWN_SECONDS = 0.32
local blockCooldowns: { [Player]: number } = {}
local COMBATANT_TAG = "BattleCombatant"

local SWORD_IDLE_GRIP = CFrame.new(0.16, -0.95, -0.12) * CFrame.Angles(math.rad(-18), math.rad(12), math.rad(-10))
local SWORD_WINDUP_GRIP = CFrame.new(0.22, -0.82, -0.08) * CFrame.Angles(math.rad(-70), math.rad(18), math.rad(18))
local SWORD_STRIKE_GRIP = CFrame.new(0.08, -1.0, -0.2) * CFrame.Angles(math.rad(18), math.rad(-8), math.rad(-42))
local SWORD_RECOVER_GRIP = CFrame.new(0.14, -0.96, -0.14) * CFrame.Angles(math.rad(-24), math.rad(6), math.rad(-12))
local BOW_IDLE_GRIP = CFrame.new(0, -0.2, 0.04) * CFrame.Angles(0, math.rad(90), 0)
local BOW_DRAW_GRIP = CFrame.new(-0.24, -0.05, 0.16) * CFrame.Angles(math.rad(-10), math.rad(96), math.rad(-6))

local function getCharacterHumanoid(model: Instance): Humanoid?
    if not model:IsA("Model") then
        return nil
    end

    return model:FindFirstChildOfClass("Humanoid")
end

local function findFirstBodyPart(character: Model, names: { string }): BasePart?
    for _, name in ipairs(names) do
        local part = character:FindFirstChild(name)

        if part and part:IsA("BasePart") then
            return part
        end
    end

    return nil
end

local function findEnemyHumanoid(originCharacter: Model, maxDistance: number): Humanoid?
    local root = originCharacter:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return nil
    end

    local originTeam = originCharacter:GetAttribute("BattleTeam")
    local bestHumanoid = nil
    local bestDistance = maxDistance

    for _, candidateModel in ipairs(CollectionService:GetTagged(COMBATANT_TAG)) do
        if candidateModel:IsA("Model") and candidateModel ~= originCharacter then
            local candidate = candidateModel:FindFirstChildOfClass("Humanoid")
            local candidateRoot = candidateModel:FindFirstChild("HumanoidRootPart")

            if candidate and candidate.Health > 0 and candidateRoot and candidateRoot:IsA("BasePart") then
                local candidateTeam = candidateModel:GetAttribute("BattleTeam")

                if candidateTeam and candidateTeam ~= originTeam then
                    local distance = (candidateRoot.Position - root.Position).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestHumanoid = candidate
                    end
                end
            end
        end
    end

    return bestHumanoid
end

local function findSwordTarget(originCharacter: Model, maxDistance: number): Humanoid?
    local root = originCharacter:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return nil
    end

    local originTeam = originCharacter:GetAttribute("BattleTeam")
    local bestHumanoid = nil
    local bestScore = math.huge

    for _, candidateModel in ipairs(CollectionService:GetTagged(COMBATANT_TAG)) do
        if candidateModel:IsA("Model") and candidateModel ~= originCharacter then
            local candidateHumanoid = candidateModel:FindFirstChildOfClass("Humanoid")
            local candidateRoot = candidateModel:FindFirstChild("HumanoidRootPart")

            if candidateHumanoid and candidateHumanoid.Health > 0 and candidateRoot and candidateRoot:IsA("BasePart") then
                local candidateTeam = candidateModel:GetAttribute("BattleTeam")

                if candidateTeam and candidateTeam ~= originTeam then
                    local offset = candidateRoot.Position - root.Position
                    local distance = offset.Magnitude

                    if distance > 0.05 and distance <= maxDistance then
                        local alignment = root.CFrame.LookVector:Dot(offset.Unit)

                        if alignment > 0.18 then
                            local score = distance - alignment * 2.6

                            if score < bestScore then
                                bestScore = score
                                bestHumanoid = candidateHumanoid
                            end
                        end
                    end
                end
            end
        end
    end

    return bestHumanoid
end

local function playOneShotSound(parent: Instance, soundId: string, volume: number, playbackSpeed: number?)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume

    if playbackSpeed then
        sound.PlaybackSpeed = playbackSpeed
    end

    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 3)
end

local function attachTrail(part: BasePart, colorA: Color3, colorB: Color3, a0: Vector3, a1: Vector3): Trail
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = a0
    attachment0.Parent = part

    local attachment1 = Instance.new("Attachment")
    attachment1.Position = a1
    attachment1.Parent = part

    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = ColorSequence.new(colorA, colorB)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Lifetime = 0.08
    trail.MinLength = 0.06
    trail.FaceCamera = true
    trail.Enabled = false
    trail.Parent = part

    return trail
end

local function animateToolGrip(tool: Tool, targetGrip: CFrame, duration: number)
    local startGrip = tool.Grip
    local elapsed = 0

    while elapsed < duration and tool.Parent do
        elapsed += RunService.Heartbeat:Wait()
        tool.Grip = startGrip:Lerp(targetGrip, math.clamp(elapsed / duration, 0, 1))
    end

    if tool.Parent then
        tool.Grip = targetGrip
    end
end

local function isBlocking(character: Model): boolean
    local blockingUntil = character:GetAttribute("BlockingUntil")

    return type(blockingUntil) == "number" and blockingUntil > os.clock()
end

local function applyDamage(attackerCharacter: Model, targetHumanoid: Humanoid?, damage: number, hitSoundId: string?)
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        return false
    end

    local targetModel = targetHumanoid.Parent

    if not targetModel or not targetModel:IsA("Model") then
        return false
    end

    if targetModel:GetAttribute("BattleTeam") == attackerCharacter:GetAttribute("BattleTeam") then
        return false
    end

    local finalDamage = damage
    local blocked = isBlocking(targetModel)

    if blocked then
        finalDamage = math.max(3, math.floor(damage * BLOCK_DAMAGE_MULTIPLIER))
    end

    targetHumanoid:TakeDamage(finalDamage)

    if blocked then
        local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")

        if targetRoot and targetRoot:IsA("BasePart") then
            playOneShotSound(targetRoot, BLOCK_SOUND, 0.65, 1.08)

            local flash = Instance.new("Part")
            flash.Name = "BlockFlash"
            flash.Shape = Enum.PartType.Ball
            flash.Size = Vector3.new(3, 3, 3)
            flash.Material = Enum.Material.Neon
            flash.Color = Color3.fromRGB(222, 198, 126)
            flash.Transparency = 0.35
            flash.Anchored = true
            flash.CanCollide = false
            flash.CanTouch = false
            flash.CanQuery = false
            flash.CFrame = targetRoot.CFrame
            flash.Parent = Workspace
            Debris:AddItem(flash, 0.22)
        end
    elseif hitSoundId then
        local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")

        if targetRoot and targetRoot:IsA("BasePart") then
            playOneShotSound(targetRoot, hitSoundId, 0.55, 1)
        end
    end

    return true
end

local function setBlocking(player: Player)
    if player:GetAttribute("InBattle") ~= true then
        return
    end

    local now = os.clock()
    local lastBlock = blockCooldowns[player]

    if lastBlock and now - lastBlock < BLOCK_COOLDOWN_SECONDS then
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return
    end

    blockCooldowns[player] = now
    character:SetAttribute("BlockingUntil", now + BLOCK_WINDOW_SECONDS)
    playOneShotSound(root, BLOCK_SOUND, 0.5, 1.2)
end

local function createCosmeticPart(name: string, size: Vector3, color: Color3, material: Enum.Material, transparency: number?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    return part
end

local function attachPart(parent: Instance, part: Part, basePart: BasePart, offset: CFrame)
    part.CFrame = basePart.CFrame * offset
    part.Parent = parent

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = basePart
    weld.Part1 = part
    weld.Parent = part
end

local function clearSkinCosmetics(character: Model)
    local existing = character:FindFirstChild("BattleCosmetics")

    if existing then
        existing:Destroy()
    end
end

local function applySkinCosmetics(player: Player)
    local character = player.Character

    if not character then
        return
    end

    clearSkinCosmetics(character)

    local root = findFirstBodyPart(character, { "HumanoidRootPart" })
    local head = findFirstBodyPart(character, { "Head" })
    local torso = findFirstBodyPart(character, { "UpperTorso", "Torso", "LowerTorso" })
    local leftArm = findFirstBodyPart(character, { "LeftUpperArm", "Left Arm" })
    local rightArm = findFirstBodyPart(character, { "RightUpperArm", "Right Arm" })
    local leftLeg = findFirstBodyPart(character, { "LeftUpperLeg", "Left Leg" })
    local rightLeg = findFirstBodyPart(character, { "RightUpperLeg", "Right Leg" })

    if not root or not head or not torso then
        return
    end

    local skinId = player:GetAttribute("EquippedBattleSkin")

    if typeof(skinId) ~= "string" then
        skinId = "default"
    end

    local skin = ShopCatalog.SkinDefinitions[skinId] or ShopCatalog.SkinDefinitions.default
    local cosmetics = Instance.new("Folder")
    cosmetics.Name = "BattleCosmetics"
    cosmetics.Parent = character

    local cuirass = createCosmeticPart("Cuirass", Vector3.new(2.5, 2.6, 1.4), skin.PrimaryColor, Enum.Material.Metal, nil)
    attachPart(cosmetics, cuirass, torso, CFrame.new(0, 0.05, 0))

    local waistGuard = createCosmeticPart("WaistGuard", Vector3.new(2.7, 0.45, 1.45), skin.AccentColor, Enum.Material.Metal, nil)
    attachPart(cosmetics, waistGuard, torso, CFrame.new(0, 0.82, 0))

    local backCape = createCosmeticPart("BackCape", Vector3.new(2.8, 3.3, 0.2), skin.CapeColor, Enum.Material.Fabric, 0.05)
    attachPart(cosmetics, backCape, torso, CFrame.new(0, -0.18, 0.76))

    local helmetBand = createCosmeticPart("HelmetBand", Vector3.new(2.12, 0.34, 1.1), skin.SecondaryColor, Enum.Material.Metal, nil)
    attachPart(cosmetics, helmetBand, head, CFrame.new(0, 0.18, 0))

    local crest = createCosmeticPart("HelmetCrest", Vector3.new(0.32, 0.9, 1.2), skin.AccentColor, Enum.Material.Fabric, nil)
    attachPart(cosmetics, crest, head, CFrame.new(0, -0.48, 0))

    if leftArm then
        local leftShoulder = createCosmeticPart("LeftShoulder", Vector3.new(0.95, 0.62, 1.15), skin.PrimaryColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, leftShoulder, leftArm, CFrame.new(0, -0.52, 0))

        local leftBracer = createCosmeticPart("LeftBracer", Vector3.new(0.82, 1.05, 0.82), skin.SecondaryColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, leftBracer, leftArm, CFrame.new(0, 0.52, 0))

        local shieldPlate = createCosmeticPart("BattleShieldPlate", Vector3.new(0.26, 3.2, 2.6), skin.PrimaryColor, Enum.Material.WoodPlanks, nil)
        attachPart(cosmetics, shieldPlate, leftArm, CFrame.new(0.75, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)))

        local shieldRim = createCosmeticPart("BattleShieldRim", Vector3.new(0.32, 3.4, 2.8), skin.AccentColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, shieldRim, leftArm, CFrame.new(0.78, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)))

        local shieldBoss = createCosmeticPart("BattleShieldBoss", Vector3.new(0.5, 0.8, 0.8), Color3.fromRGB(192, 160, 90), Enum.Material.Metal, nil)
        attachPart(cosmetics, shieldBoss, leftArm, CFrame.new(0.92, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)))
    end

    if rightArm then
        local rightShoulder = createCosmeticPart("RightShoulder", Vector3.new(0.95, 0.62, 1.15), skin.PrimaryColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, rightShoulder, rightArm, CFrame.new(0, -0.52, 0))

        local rightBracer = createCosmeticPart("RightBracer", Vector3.new(0.82, 1.05, 0.82), skin.SecondaryColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, rightBracer, rightArm, CFrame.new(0, 0.52, 0))
    end

    if leftLeg then
        local leftGreave = createCosmeticPart("LeftGreave", Vector3.new(0.82, 1.18, 0.82), skin.SecondaryColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, leftGreave, leftLeg, CFrame.new(0, 0.3, 0))
    end

    if rightLeg then
        local rightGreave = createCosmeticPart("RightGreave", Vector3.new(0.82, 1.18, 0.82), skin.SecondaryColor, Enum.Material.Metal, nil)
        attachPart(cosmetics, rightGreave, rightLeg, CFrame.new(0, 0.3, 0))
    end

    if player:GetAttribute("HasFounderSupport") then
        local founderBand = createCosmeticPart("FounderBand", Vector3.new(0.24, 2.7, 1.18), Color3.fromRGB(208, 174, 92), Enum.Material.Metal, nil)
        attachPart(cosmetics, founderBand, torso, CFrame.new(1.05, 0, 0))
    end

    local aura = createCosmeticPart("AuraPlate", Vector3.new(2.8, 0.14, 2.8), skin.AccentColor, Enum.Material.Neon, 0.42)
    attachPart(cosmetics, aura, root, CFrame.new(0, -2.68, 0))

    local torchGlow = createCosmeticPart("BattleTorchGlow", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 187, 94), Enum.Material.Neon, 0.08)
    attachPart(cosmetics, torchGlow, root, CFrame.new(0, 1.45, -2.3))

    local torchLight = Instance.new("PointLight")
    torchLight.Name = "BattleTorchLight"
    torchLight.Color = Color3.fromRGB(255, 190, 116)
    torchLight.Brightness = 1.65
    torchLight.Range = 32
    torchLight.Shadows = true
    torchLight.Parent = torchGlow
end

local function createWeaponVisualPart(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    return part
end

local function weldToHandle(handle: BasePart, part: BasePart, offset: CFrame): Weld
    part.CFrame = handle.CFrame * offset
    part.Parent = handle.Parent

    local weld = Instance.new("Weld")
    weld.Part0 = handle
    weld.Part1 = part
    weld.C0 = offset
    weld.Parent = part

    return weld
end

local function createSwordTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Training Sword"
    tool.RequiresHandle = true
    tool.Grip = SWORD_IDLE_GRIP

    local handle = createWeaponVisualPart("Handle", Vector3.new(0.32, 2.25, 0.32), Color3.fromRGB(98, 66, 38), Enum.Material.Wood)
    handle.Parent = tool

    local grip = createWeaponVisualPart("Grip", Vector3.new(0.42, 1.55, 0.42), Color3.fromRGB(81, 52, 33), Enum.Material.Wood)
    local pommel = createWeaponVisualPart("Pommel", Vector3.new(0.5, 0.32, 0.5), Color3.fromRGB(177, 146, 78), Enum.Material.Metal)
    local guard = createWeaponVisualPart("Crossguard", Vector3.new(2.1, 0.24, 0.38), Color3.fromRGB(179, 149, 87), Enum.Material.Metal)
    local blade = createWeaponVisualPart("Blade", Vector3.new(0.24, 3.05, 0.36), Color3.fromRGB(216, 216, 216), Enum.Material.Metal)
    local tip = createWeaponVisualPart("BladeTip", Vector3.new(0.12, 0.52, 0.16), Color3.fromRGB(228, 228, 226), Enum.Material.Metal)
    local bladeTrail = attachTrail(blade, Color3.fromRGB(255, 235, 189), Color3.fromRGB(232, 215, 175), Vector3.new(0, -1.45, 0), Vector3.new(0, 1.45, 0))

    weldToHandle(handle, grip, CFrame.new(0, 0, 0))
    weldToHandle(handle, pommel, CFrame.new(0, -1.25, 0))
    weldToHandle(handle, guard, CFrame.new(0, 1.08, 0))
    weldToHandle(handle, blade, CFrame.new(0, 2.72, 0))
    weldToHandle(handle, tip, CFrame.new(0, 4.48, 0))

    local cooldown = false
    local swingToken = 0

    tool.Equipped:Connect(function()
        swingToken += 1
        tool.Grip = SWORD_IDLE_GRIP
        playOneShotSound(handle, SWORD_DRAW_SOUND, 0.45, 1)
    end)

    tool.Unequipped:Connect(function()
        swingToken += 1
        cooldown = false
        tool.Grip = SWORD_IDLE_GRIP
    end)

    tool.Activated:Connect(function()
        if cooldown then
            return
        end

        local character = tool.Parent

        if not character or not character:IsA("Model") then
            return
        end

        local humanoid = getCharacterHumanoid(character)
        local root = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
            return
        end

        cooldown = true
        swingToken += 1
        local currentSwing = swingToken

        task.spawn(function()
            animateToolGrip(tool, SWORD_WINDUP_GRIP, 0.1)

            if currentSwing ~= swingToken then
                return
            end

            playOneShotSound(handle, SWORD_SWING_SOUND, 0.56, 1.02)
            bladeTrail.Enabled = true
            animateToolGrip(tool, SWORD_STRIKE_GRIP, 0.08)

            if currentSwing ~= swingToken then
                return
            end

            animateToolGrip(tool, SWORD_RECOVER_GRIP, 0.11)

            if currentSwing ~= swingToken then
                return
            end

            animateToolGrip(tool, SWORD_IDLE_GRIP, 0.13)
        end)

        task.delay(0.16, function()
            bladeTrail.Enabled = false
        end)

        task.delay(0.12, function()
            if currentSwing ~= swingToken then
                return
            end

            local hitCharacter = tool.Parent
            local hitRoot = hitCharacter and hitCharacter:FindFirstChild("HumanoidRootPart")

            if not hitCharacter or not hitCharacter:IsA("Model") or not hitRoot or not hitRoot:IsA("BasePart") then
                return
            end

            local direction = hitRoot.CFrame.LookVector * 11
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = { hitCharacter, tool }

            local result = Workspace:Raycast(hitRoot.Position, direction, raycastParams)
            local targetHumanoid = nil

            if result then
                local target = result.Instance:FindFirstAncestorOfClass("Model")

                if target then
                    targetHumanoid = getCharacterHumanoid(target)
                end
            end

            if not targetHumanoid then
                targetHumanoid = findSwordTarget(hitCharacter, SWORD_SWING_RANGE) or findEnemyHumanoid(hitCharacter, SWORD_SWING_RANGE)
            end

            applyDamage(hitCharacter, targetHumanoid, 32, SWORD_HIT_SOUND)
        end)

        task.delay(SWORD_SWING_COOLDOWN_SECONDS, function()
            cooldown = false
        end)
    end)

    return tool
end

local function createBowTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Bow"
    tool.RequiresHandle = true
    tool.Grip = BOW_IDLE_GRIP

    local handle = createWeaponVisualPart("Handle", Vector3.new(0.36, 3.2, 0.36), Color3.fromRGB(108, 74, 42), Enum.Material.Wood)
    handle.Parent = tool

    local upperLimb = createWeaponVisualPart("UpperLimb", Vector3.new(0.26, 3.4, 0.26), Color3.fromRGB(116, 82, 48), Enum.Material.Wood)
    local lowerLimb = createWeaponVisualPart("LowerLimb", Vector3.new(0.26, 3.4, 0.26), Color3.fromRGB(116, 82, 48), Enum.Material.Wood)
    local upperString = createWeaponVisualPart("UpperString", Vector3.new(0.08, 1.8, 0.08), Color3.fromRGB(228, 223, 207), Enum.Material.SmoothPlastic)
    local lowerString = createWeaponVisualPart("LowerString", Vector3.new(0.08, 1.8, 0.08), Color3.fromRGB(228, 223, 207), Enum.Material.SmoothPlastic)
    local displayArrow = createWeaponVisualPart("DisplayArrow", Vector3.new(0.18, 0.18, 2.8), Color3.fromRGB(124, 88, 48), Enum.Material.Wood)

    local upperLimbOffset = CFrame.new(0.56, -1.38, 0) * CFrame.Angles(0, 0, math.rad(26))
    local lowerLimbOffset = CFrame.new(0.56, 1.38, 0) * CFrame.Angles(0, 0, math.rad(-26))
    local upperStringIdleOffset = CFrame.new(1.0, -2.18, 0)
    local lowerStringIdleOffset = CFrame.new(1.0, 2.18, 0)
    local upperStringDrawOffset = CFrame.new(0.52, -2.18, 0)
    local lowerStringDrawOffset = CFrame.new(0.52, 2.18, 0)
    local displayArrowIdleOffset = CFrame.new(-0.32, 0, -0.7) * CFrame.Angles(math.rad(90), 0, 0)
    local displayArrowDrawOffset = CFrame.new(-0.98, 0, -0.7) * CFrame.Angles(math.rad(90), 0, 0)

    weldToHandle(handle, upperLimb, upperLimbOffset)
    weldToHandle(handle, lowerLimb, lowerLimbOffset)
    local upperStringWeld = weldToHandle(handle, upperString, upperStringIdleOffset)
    local lowerStringWeld = weldToHandle(handle, lowerString, lowerStringIdleOffset)
    local displayArrowWeld = weldToHandle(handle, displayArrow, displayArrowIdleOffset)

    local cooldown = false
    local drawing = false
    local drawStart = 0
    local currentDrawAlpha = 0
    local drawToken = 0

    local function setDrawVisual(drawAlpha: number)
        currentDrawAlpha = math.clamp(drawAlpha, 0, 1)
        tool.Grip = BOW_IDLE_GRIP:Lerp(BOW_DRAW_GRIP, currentDrawAlpha)
        upperStringWeld.C0 = upperStringIdleOffset:Lerp(upperStringDrawOffset, currentDrawAlpha)
        lowerStringWeld.C0 = lowerStringIdleOffset:Lerp(lowerStringDrawOffset, currentDrawAlpha)
        displayArrowWeld.C0 = displayArrowIdleOffset:Lerp(displayArrowDrawOffset, currentDrawAlpha)
    end

    local function easeDrawVisual(targetAlpha: number, duration: number)
        local startAlpha = currentDrawAlpha
        local elapsed = 0

        while elapsed < duration and tool.Parent do
            elapsed += RunService.Heartbeat:Wait()
            setDrawVisual(startAlpha + (targetAlpha - startAlpha) * math.clamp(elapsed / duration, 0, 1))
        end

        if tool.Parent then
            setDrawVisual(targetAlpha)
        end
    end

    tool.Equipped:Connect(function()
        drawToken += 1
        drawing = false
        displayArrow.Transparency = 0
        setDrawVisual(0)
    end)

    tool.Unequipped:Connect(function()
        drawToken += 1
        drawing = false
        cooldown = false
        displayArrow.Transparency = 0
        setDrawVisual(0)
    end)

    tool.Activated:Connect(function()
        if cooldown or drawing then
            return
        end

        local character = tool.Parent

        if not character or not character:IsA("Model") then
            return
        end

        local humanoid = getCharacterHumanoid(character)
        local root = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
            return
        end

        drawing = true
        drawStart = os.clock()
        drawToken += 1
        local currentToken = drawToken
        playOneShotSound(handle, BOW_DRAW_SOUND, 0.35, 0.9)

        task.spawn(function()
            while drawing and drawToken == currentToken and tool.Parent == character do
                local alpha = math.clamp((os.clock() - drawStart) / BOW_DRAW_TIME_SECONDS, 0, 1)
                setDrawVisual(alpha)
                RunService.Heartbeat:Wait()
            end
        end)
    end)

    tool.Deactivated:Connect(function()
        if not drawing then
            return
        end

        local character = tool.Parent

        if not character or not character:IsA("Model") then
            drawing = false
            setDrawVisual(0)
            return
        end

        local humanoid = getCharacterHumanoid(character)
        local root = character:FindFirstChild("HumanoidRootPart")

        drawing = false

        if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
            setDrawVisual(0)
            return
        end

        local chargeAlpha = math.clamp((os.clock() - drawStart) / BOW_DRAW_TIME_SECONDS, 0, 1)

        if chargeAlpha < 0.08 then
            task.spawn(function()
                easeDrawVisual(0, 0.1)
            end)
            return
        end

        cooldown = true
        setDrawVisual(chargeAlpha)
        displayArrow.Transparency = 1
        playOneShotSound(handle, BOW_RELEASE_SOUND, 0.42 + chargeAlpha * 0.2, 1.08 + chargeAlpha * 0.14)

        local arrow = Instance.new("Part")
        arrow.Name = "BattleArrow"
        arrow.Size = Vector3.new(0.22, 0.22, 4.2)
        arrow.Color = Color3.fromRGB(113, 77, 44)
        arrow.Material = Enum.Material.Wood
        arrow.CanCollide = false
        arrow.CanTouch = true
        arrow.CanQuery = true
        local arrowSpawn = root.Position + root.CFrame.LookVector * 3.6 + Vector3.new(0, 1.5, 0)
        arrow.CFrame = CFrame.lookAt(arrowSpawn, arrowSpawn + root.CFrame.LookVector)
        arrow.Parent = Workspace
        arrow.AssemblyLinearVelocity = root.CFrame.LookVector * (132 + chargeAlpha * 94) + Vector3.new(0, 3 + chargeAlpha * 7, 0)

        local arrowTip = createWeaponVisualPart("ArrowTip", Vector3.new(0.28, 0.28, 0.52), Color3.fromRGB(191, 191, 191), Enum.Material.Metal)
        weldToHandle(arrow, arrowTip, CFrame.new(0, 0, -2.15))

        local featherA = createWeaponVisualPart("FeatherA", Vector3.new(0.12, 0.36, 0.44), Color3.fromRGB(224, 228, 233), Enum.Material.Fabric)
        local featherB = createWeaponVisualPart("FeatherB", Vector3.new(0.12, 0.36, 0.44), Color3.fromRGB(224, 228, 233), Enum.Material.Fabric)
        weldToHandle(arrow, featherA, CFrame.new(0.12, 0, 1.6))
        weldToHandle(arrow, featherB, CFrame.new(-0.12, 0, 1.6))

        local arrowTrail = attachTrail(arrow, Color3.fromRGB(227, 211, 170), Color3.fromRGB(255, 237, 198), Vector3.new(0, 0, -2.1), Vector3.new(0, 0, 2.1))
        arrowTrail.Lifetime = 0.14
        arrowTrail.Enabled = true

        local damaged = false
        local arrowAlignConnection

        arrow.Touched:Connect(function(hitPart)
            if damaged then
                return
            end

            local target = hitPart:FindFirstAncestorOfClass("Model")

            if target == character then
                return
            end

            local targetHumanoid = target and getCharacterHumanoid(target) or nil

            if targetHumanoid then
                local hitApplied = applyDamage(character, targetHumanoid, math.floor(18 + chargeAlpha * 24), BOW_HIT_SOUND)

                if hitApplied then
                    damaged = true

                    if arrowAlignConnection then
                        arrowAlignConnection:Disconnect()
                    end

                    arrow:Destroy()
                end

                return
            end

            damaged = true
            playOneShotSound(arrow, BOW_HIT_SOUND, 0.4, 0.96)

            if arrowAlignConnection then
                arrowAlignConnection:Disconnect()
            end

            arrow:Destroy()
        end)

        arrowAlignConnection = RunService.Heartbeat:Connect(function()
            if not arrow.Parent then
                if arrowAlignConnection then
                    arrowAlignConnection:Disconnect()
                end

                return
            end

            local velocity = arrow.AssemblyLinearVelocity

            if velocity.Magnitude > 0.2 then
                arrow.CFrame = CFrame.lookAt(arrow.Position, arrow.Position + velocity.Unit)
            end
        end)

        Debris:AddItem(arrow, 3.6 + chargeAlpha * 1.6)
        task.delay(4.8, function()
            if arrowAlignConnection then
                arrowAlignConnection:Disconnect()
            end
        end)

        task.spawn(function()
            easeDrawVisual(0, 0.16)
            displayArrow.Transparency = 0
        end)

        task.delay(BOW_SHOT_COOLDOWN_SECONDS, function()
            cooldown = false
        end)
    end)

    return tool
end

function BattleLoadout.ClearForPlayer(player: Player)
    local backpack = player:FindFirstChildOfClass("Backpack")

    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name == "Training Sword" or item.Name == "Bow") then
                item:Destroy()
            end
        end
    end

    local character = player.Character

    if character then
        clearSkinCosmetics(character)
        character:SetAttribute("BlockingUntil", nil)

        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name == "Training Sword" or item.Name == "Bow") then
                item:Destroy()
            end
        end
    end
end

function BattleLoadout.ApplyCurrentSkin(player: Player)
    applySkinCosmetics(player)
end

function BattleLoadout.GiveToPlayer(player: Player)
    BattleLoadout.ClearForPlayer(player)

    local backpack = player:FindFirstChildOfClass("Backpack")

    if not backpack then
        return
    end

    createSwordTool().Parent = backpack
    createBowTool().Parent = backpack
    applySkinCosmetics(player)
end

requestBlock.OnServerEvent:Connect(function(player: Player)
    setBlocking(player)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
    blockCooldowns[player] = nil
end)

return BattleLoadout
