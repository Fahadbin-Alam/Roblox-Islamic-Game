--!strict

-- Builds the hub's guide teachers (see Shared/Data/Guides). Talking to one opens a dialogue
-- on the client that names the player's next quest and can take them straight there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Guides = require(Shared.Data.Guides)
local TravelRoute = require(Shared.Data.TravelRoute)

local worldFolder = Workspace:WaitForChild(TravelRoute.WorldFolderName)

while worldFolder:GetAttribute("Built") ~= true do
    worldFolder:GetAttributeChangedSignal("Built"):Wait()
end

local function rgb(values: { number }): Color3
    return Color3.fromRGB(values[1], values[2], values[3])
end

-- Finds the walkable surface under a point so guides stand on whatever the hub built there.
-- The ray starts just above head height so canopies and roofs overhead are never hit.
local function groundBelow(position: Vector3, ignore: { Instance }): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore

    local result = Workspace:Raycast(position + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)

    return if result then result.Position else position
end

local function buildAvatar(guide: Guides.Guide): Model
    local description = Instance.new("HumanoidDescription")
    local skin = rgb(guide.SkinRGB)
    description.HeadColor = skin
    description.LeftArmColor = skin
    description.RightArmColor = skin
    description.TorsoColor = rgb(guide.RobeRGB)
    description.LeftLegColor = rgb(guide.RobeRGB)
    description.RightLegColor = rgb(guide.RobeRGB)

    local ok, result = pcall(function()
        return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
    end)

    description:Destroy()

    if ok and result then
        return result
    end

    warn(string.format("[GuideService] Avatar for %s fell back to a simple figure: %s", guide.DisplayName, tostring(result)))

    -- Fallback: a plain robed figure so the guide still exists if avatar loading fails.
    local model = Instance.new("Model")
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 5, 1.4)
    root.Color = rgb(guide.RobeRGB)
    root.Material = Enum.Material.Fabric
    root.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.6, 1.6, 1.6)
    head.Color = skin
    head.CFrame = root.CFrame * CFrame.new(0, 3.3, 0)
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = head
    weld.Parent = root

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = model
    model.PrimaryPart = root

    return model
end

local function buildGuide(parent: Instance, guide: Guides.Guide)
    local destination = TravelRoute.GetDestinationById(guide.Destination)

    if not destination then
        warn(string.format("[GuideService] Unknown destination %s for guide %s", guide.Destination, guide.Id))
        return
    end

    local anchor = destination.TeleportPosition or destination.Position
    local model = buildAvatar(guide)
    model.Name = guide.Id

    local humanoid = model:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.DisplayName = guide.DisplayName
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        humanoid.BreakJointsOnDeath = false
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
        end
    end

    local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        model:Destroy()
        return
    end

    root.CanCollide = true

    local hipHeight = if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight + root.Size.Y / 2 else root.Size.Y / 2
    local feet = groundBelow(anchor + guide.Offset, { model, parent })
    -- Face the teleport point, which is where players arrive.
    local standAt = feet + Vector3.new(0, hipHeight, 0)
    local lookAt = Vector3.new(anchor.X, standAt.Y, anchor.Z)
    model:PivotTo(if (lookAt - standAt).Magnitude > 0.1 then CFrame.lookAt(standAt, lookAt) else CFrame.new(standAt))
    model.Parent = parent

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.fromOffset(220, 54)
    billboard.StudsOffset = Vector3.new(0, 4.2, 0)
    billboard.MaxDistance = 90
    billboard.AlwaysOnTop = false
    billboard.Parent = root

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 28)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = guide.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(250, 246, 234)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextSize = 20
    nameLabel.Parent = billboard

    local roleLabel = Instance.new("TextLabel")
    roleLabel.BackgroundTransparency = 1
    roleLabel.Position = UDim2.fromOffset(0, 28)
    roleLabel.Size = UDim2.new(1, 0, 0, 20)
    roleLabel.Font = Enum.Font.GothamMedium
    roleLabel.Text = string.format("! %s", guide.Role)
    roleLabel.TextColor3 = Color3.fromRGB(240, 207, 120)
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.TextSize = 15
    roleLabel.Parent = billboard

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Talk"
    prompt.ObjectText = guide.DisplayName
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("PromptAction", "TalkToGuide")
    prompt:SetAttribute("GuideId", guide.Id)
    prompt.Parent = root
end

local guidesFolder = Instance.new("Folder")
guidesFolder.Name = "Guides"
guidesFolder.Parent = worldFolder

for _, guide in ipairs(Guides) do
    local ok: boolean, err: any = pcall(function()
        buildGuide(guidesFolder, guide)
    end)

    if not ok then
        warn(string.format("[GuideService] Could not build guide %s: %s", guide.Id, tostring(err)))
    end
end
