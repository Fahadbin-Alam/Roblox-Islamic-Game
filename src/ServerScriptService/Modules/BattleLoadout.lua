--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopCatalog = require(Shared.Data.ShopCatalog)
local battleFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Battle")
local requestBlock = battleFolder:WaitForChild("RequestBlock") :: RemoteEvent

local BattleLoadout = {}

local SWORD_SWING_SOUND = "rbxasset://sounds/swordslash.wav"
local SWORD_HIT_SOUND = "rbxasset://sounds/swordlunge.wav"
local SWORD_DRAW_SOUND = "rbxasset://sounds/unsheath.wav"
local BOW_RELEASE_SOUND = "rbxasset://sounds/action_jump.mp3"
local BOW_HIT_SOUND = "rbxasset://sounds/impact_water.mp3"
local BLOCK_SOUND = "rbxasset://sounds/collide.wav"

local BLOCK_WINDOW_SECONDS = 1.1
local BLOCK_COOLDOWN_SECONDS = 1.8
local BLOCK_DAMAGE_MULTIPLIER = 0.28
local blockCooldowns: { [Player]: number } = {}

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

    for _, candidate in ipairs(Workspace:GetDescendants()) do
        if candidate:IsA("Humanoid") and candidate.Health > 0 then
            local candidateModel = candidate.Parent

            if candidateModel and candidateModel:IsA("Model") and candidateModel ~= originCharacter then
                local candidateRoot = candidateModel:FindFirstChild("HumanoidRootPart")

                if candidateRoot and candidateRoot:IsA("BasePart") then
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

local function weldToHandle(handle: BasePart, part: BasePart, offset: CFrame)
    part.CFrame = handle.CFrame * offset
    part.Parent = handle.Parent

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = part
    weld.Parent = part
end

local function createSwordTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Training Sword"
    tool.RequiresHandle = true
    tool.Grip = CFrame.new(0, -0.65, 0)

    local handle = createWeaponVisualPart("Handle", Vector3.new(0.42, 3.3, 0.42), Color3.fromRGB(98, 66, 38), Enum.Material.Wood)
    handle.Parent = tool

    local grip = createWeaponVisualPart("Grip", Vector3.new(0.54, 2.4, 0.54), Color3.fromRGB(81, 52, 33), Enum.Material.Wood)
    local pommel = createWeaponVisualPart("Pommel", Vector3.new(0.7, 0.45, 0.7), Color3.fromRGB(177, 146, 78), Enum.Material.Metal)
    local guard = createWeaponVisualPart("Crossguard", Vector3.new(3.2, 0.3, 0.5), Color3.fromRGB(179, 149, 87), Enum.Material.Metal)
    local blade = createWeaponVisualPart("Blade", Vector3.new(0.34, 4.8, 0.54), Color3.fromRGB(216, 216, 216), Enum.Material.Metal)
    local tip = createWeaponVisualPart("BladeTip", Vector3.new(0.18, 0.8, 0.24), Color3.fromRGB(228, 228, 226), Enum.Material.Metal)

    weldToHandle(handle, grip, CFrame.new(0, 0, 0))
    weldToHandle(handle, pommel, CFrame.new(0, -1.85, 0))
    weldToHandle(handle, guard, CFrame.new(0, 1.54, 0))
    weldToHandle(handle, blade, CFrame.new(0, 4.2, 0))
    weldToHandle(handle, tip, CFrame.new(0, 7.0, 0))

    tool.Equipped:Connect(function()
        playOneShotSound(handle, SWORD_DRAW_SOUND, 0.45, 1)
    end)

    local cooldown = false

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
        playOneShotSound(handle, SWORD_SWING_SOUND, 0.5, 1.05)

        local direction = root.CFrame.LookVector * 11
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { character, tool }

        local result = Workspace:Raycast(root.Position, direction, raycastParams)
        local targetHumanoid = nil

        if result then
            local target = result.Instance:FindFirstAncestorOfClass("Model")

            if target then
                targetHumanoid = getCharacterHumanoid(target)
            end
        end

        if not targetHumanoid then
            targetHumanoid = findEnemyHumanoid(character, 11)
        end

        applyDamage(character, targetHumanoid, 28, SWORD_HIT_SOUND)

        task.delay(0.58, function()
            cooldown = false
        end)
    end)

    return tool
end

local function createBowTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Bow"
    tool.RequiresHandle = true

    local handle = createWeaponVisualPart("Handle", Vector3.new(0.36, 3.2, 0.36), Color3.fromRGB(108, 74, 42), Enum.Material.Wood)
    handle.Parent = tool

    local upperLimb = createWeaponVisualPart("UpperLimb", Vector3.new(0.26, 3.4, 0.26), Color3.fromRGB(116, 82, 48), Enum.Material.Wood)
    local lowerLimb = createWeaponVisualPart("LowerLimb", Vector3.new(0.26, 3.4, 0.26), Color3.fromRGB(116, 82, 48), Enum.Material.Wood)
    local upperString = createWeaponVisualPart("UpperString", Vector3.new(0.08, 1.8, 0.08), Color3.fromRGB(228, 223, 207), Enum.Material.SmoothPlastic)
    local lowerString = createWeaponVisualPart("LowerString", Vector3.new(0.08, 1.8, 0.08), Color3.fromRGB(228, 223, 207), Enum.Material.SmoothPlastic)
    local displayArrow = createWeaponVisualPart("DisplayArrow", Vector3.new(0.18, 0.18, 2.8), Color3.fromRGB(124, 88, 48), Enum.Material.Wood)

    weldToHandle(handle, upperLimb, CFrame.new(0.56, -1.38, 0) * CFrame.Angles(0, 0, math.rad(26)))
    weldToHandle(handle, lowerLimb, CFrame.new(0.56, 1.38, 0) * CFrame.Angles(0, 0, math.rad(-26)))
    weldToHandle(handle, upperString, CFrame.new(1.0, -2.18, 0))
    weldToHandle(handle, lowerString, CFrame.new(1.0, 2.18, 0))
    weldToHandle(handle, displayArrow, CFrame.new(-0.32, 0, -0.7) * CFrame.Angles(math.rad(90), 0, 0))

    local cooldown = false

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
        playOneShotSound(handle, BOW_RELEASE_SOUND, 0.35, 1.2)

        local arrow = Instance.new("Part")
        arrow.Name = "BattleArrow"
        arrow.Size = Vector3.new(0.22, 0.22, 4.2)
        arrow.Color = Color3.fromRGB(113, 77, 44)
        arrow.Material = Enum.Material.Wood
        arrow.CanCollide = false
        arrow.CFrame = root.CFrame * CFrame.new(0, 1.5, -3.8)
        arrow.Parent = Workspace
        arrow.AssemblyLinearVelocity = root.CFrame.LookVector * 162

        local arrowTip = createWeaponVisualPart("ArrowTip", Vector3.new(0.28, 0.28, 0.52), Color3.fromRGB(191, 191, 191), Enum.Material.Metal)
        weldToHandle(arrow, arrowTip, CFrame.new(0, 0, -2.15))

        local featherA = createWeaponVisualPart("FeatherA", Vector3.new(0.12, 0.36, 0.44), Color3.fromRGB(224, 228, 233), Enum.Material.Fabric)
        local featherB = createWeaponVisualPart("FeatherB", Vector3.new(0.12, 0.36, 0.44), Color3.fromRGB(224, 228, 233), Enum.Material.Fabric)
        weldToHandle(arrow, featherA, CFrame.new(0.12, 0, 1.6))
        weldToHandle(arrow, featherB, CFrame.new(-0.12, 0, 1.6))

        local damaged = false

        arrow.Touched:Connect(function(hitPart)
            if damaged then
                return
            end

            local target = hitPart:FindFirstAncestorOfClass("Model")

            if not target or target == character then
                return
            end

            local targetHumanoid = getCharacterHumanoid(target)

            if not targetHumanoid then
                return
            end

            damaged = true
            applyDamage(character, targetHumanoid, 20, BOW_HIT_SOUND)
            arrow:Destroy()
        end)

        Debris:AddItem(arrow, 4)

        task.delay(1.05, function()
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
