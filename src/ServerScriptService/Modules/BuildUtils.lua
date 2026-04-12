--!strict

local Workspace = game:GetService("Workspace")

local BuildUtils = {}

function BuildUtils.CreateFolder(parent: Instance, name: string): Folder
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent

    return folder
end

function BuildUtils.CreatePart(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    shape: Enum.PartType?,
    transparency: number?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material

    if shape then
        part.Shape = shape
    end

    if transparency then
        part.Transparency = transparency
    end

    part.Parent = parent

    return part
end

function BuildUtils.CreateTeleportAnchor(parent: Instance, name: string, position: Vector3): Part
    local anchor = BuildUtils.CreatePart(
        parent,
        name,
        Vector3.new(12, 1, 12),
        CFrame.new(position + Vector3.new(0, 2, 0)),
        Color3.fromRGB(255, 255, 255),
        Enum.Material.SmoothPlastic,
        nil,
        1
    )
    anchor.CanCollide = false

    return anchor
end

function BuildUtils.AddPointLight(parent: BasePart, color: Color3, brightness: number, range: number)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Parent = parent
end

function BuildUtils.AttachPrompt(
    parent: BasePart,
    actionText: string,
    objectText: string,
    attributes: { [string]: any }?
): ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent

    if attributes then
        for key, value in pairs(attributes) do
            prompt:SetAttribute(key, value)
        end
    end

    return prompt
end

local function createSignLabel(board: BasePart, title: string, subtitle: string, titleColor: Color3)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.CanvasSize = Vector2.new(760, 280)
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 60
    surfaceGui.Parent = board

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(26, 18)
    titleLabel.Size = UDim2.new(1, -52, 0, 110)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = titleColor
    titleLabel.TextScaled = true
    titleLabel.TextWrapped = true
    titleLabel.Parent = surfaceGui

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(26, 122)
    subtitleLabel.Size = UDim2.new(1, -52, 0, 110)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(228, 226, 221)
    subtitleLabel.TextScaled = true
    subtitleLabel.TextWrapped = true
    subtitleLabel.Parent = surfaceGui
end

function BuildUtils.CreateBoardSign(
    parent: Instance,
    name: string,
    position: Vector3,
    title: string,
    subtitle: string,
    accentColor: Color3,
    promptAttributes: { [string]: any }?
): BasePart
    local post = BuildUtils.CreatePart(
        parent,
        string.format("%s_Post", name),
        Vector3.new(2, 11, 2),
        CFrame.new(position + Vector3.new(0, 5.5, 0)),
        Color3.fromRGB(112, 79, 48),
        Enum.Material.WoodPlanks,
        nil,
        nil
    )

    local board = BuildUtils.CreatePart(
        parent,
        string.format("%s_Board", name),
        Vector3.new(18, 9, 1.2),
        CFrame.new(position + Vector3.new(0, 10.8, 0)),
        accentColor,
        Enum.Material.WoodPlanks,
        nil,
        nil
    )
    board.Orientation = Vector3.new(0, 180, 0)

    createSignLabel(board, title, subtitle, Color3.fromRGB(252, 249, 242))

    if promptAttributes then
        BuildUtils.AttachPrompt(board, promptAttributes.ActionText, promptAttributes.ObjectText, promptAttributes.Attributes)
    end

    return board
end

function BuildUtils.CreateWallSign(
    parent: Instance,
    name: string,
    position: Vector3,
    size: Vector3,
    title: string,
    subtitle: string,
    wallColor: Color3,
    promptAttributes: { [string]: any }?
): BasePart
    local wall = BuildUtils.CreatePart(
        parent,
        name,
        size,
        CFrame.new(position + Vector3.new(0, size.Y * 0.5, 0)),
        wallColor,
        Enum.Material.Marble,
        nil,
        nil
    )

    createSignLabel(wall, title, subtitle, Color3.fromRGB(252, 249, 242))

    if promptAttributes then
        BuildUtils.AttachPrompt(wall, promptAttributes.ActionText, promptAttributes.ObjectText, promptAttributes.Attributes)
    end

    return wall
end

function BuildUtils.CreateBanner(parent: Instance, name: string, position: Vector3, clothColor: Color3)
    BuildUtils.CreatePart(parent, string.format("%s_Pole", name), Vector3.new(1, 16, 1), CFrame.new(position + Vector3.new(0, 8, 0)), Color3.fromRGB(111, 83, 53), Enum.Material.Wood, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Cloth", name), Vector3.new(7, 8, 0.6), CFrame.new(position + Vector3.new(3.6, 10.5, 0)), clothColor, Enum.Material.Fabric, nil, nil)
end

function BuildUtils.CreateLantern(parent: Instance, name: string, position: Vector3, accentColor: Color3)
    BuildUtils.CreatePart(parent, string.format("%s_Post", name), Vector3.new(1.4, 11, 1.4), CFrame.new(position + Vector3.new(0, 5.5, 0)), Color3.fromRGB(98, 73, 49), Enum.Material.WoodPlanks, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Arm", name), Vector3.new(5, 0.8, 0.8), CFrame.new(position + Vector3.new(1.8, 10.2, 0)), Color3.fromRGB(96, 78, 48), Enum.Material.WoodPlanks, nil, nil)

    local housing = BuildUtils.CreatePart(parent, string.format("%s_Housing", name), Vector3.new(2.5, 3.5, 2.5), CFrame.new(position + Vector3.new(3.8, 8.4, 0)), accentColor, Enum.Material.Metal, nil, nil)
    local glow = BuildUtils.CreatePart(parent, string.format("%s_Glow", name), Vector3.new(1.2, 1.8, 1.2), housing.CFrame, Color3.fromRGB(255, 223, 158), Enum.Material.Neon, nil, nil)
    BuildUtils.AddPointLight(glow, Color3.fromRGB(255, 224, 167), 1.5, 20)
end

function BuildUtils.CreatePalmTree(parent: Instance, name: string, position: Vector3)
    BuildUtils.CreatePart(parent, string.format("%s_Trunk", name), Vector3.new(3, 18, 3), CFrame.new(position + Vector3.new(0, 9, 0)), Color3.fromRGB(126, 87, 55), Enum.Material.Wood, nil, nil)

    for _, offset in ipairs({
        Vector3.new(0, 19, -5),
        Vector3.new(0, 19, 5),
        Vector3.new(5, 19, 0),
        Vector3.new(-5, 19, 0),
        Vector3.new(0, 21, 0),
    }) do
        BuildUtils.CreatePart(parent, string.format("%s_Leaf_%d_%d", name, offset.X, offset.Z), Vector3.new(18, 1.6, 6), CFrame.new(position + offset), Color3.fromRGB(71, 132, 73), Enum.Material.Grass, nil, nil)
    end
end

function BuildUtils.CreatePlanter(parent: Instance, name: string, position: Vector3, size: Vector3)
    BuildUtils.CreatePart(parent, string.format("%s_Border", name), size, CFrame.new(position + Vector3.new(0, 1.5, 0)), Color3.fromRGB(171, 153, 120), Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Green", name), Vector3.new(size.X - 6, 2, size.Z - 6), CFrame.new(position + Vector3.new(0, 2.6, 0)), Color3.fromRGB(116, 149, 99), Enum.Material.Grass, nil, nil)
end

function BuildUtils.CreateHouse(parent: Instance, name: string, position: Vector3, footprint: Vector3, roofColor: Color3)
    BuildUtils.CreatePart(parent, string.format("%s_Base", name), Vector3.new(footprint.X, 20, footprint.Z), CFrame.new(position + Vector3.new(0, 10, 0)), Color3.fromRGB(226, 219, 196), Enum.Material.Limestone, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Roof", name), Vector3.new(footprint.X + 4, 3, footprint.Z + 4), CFrame.new(position + Vector3.new(0, 21.5, 0)), roofColor, Enum.Material.Sandstone, nil, nil)
    BuildUtils.CreatePart(parent, string.format("%s_Door", name), Vector3.new(4, 9, 1), CFrame.new(position + Vector3.new(0, 4.5, footprint.Z * -0.5 - 0.5)), Color3.fromRGB(110, 82, 49), Enum.Material.Wood, nil, nil)
end

function BuildUtils.CreateWedge(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    transparency: number?
): WedgePart
    local wedge = Instance.new("WedgePart")
    wedge.Name = name
    wedge.Anchored = true
    wedge.CanCollide = true
    wedge.TopSurface = Enum.SurfaceType.Smooth
    wedge.BottomSurface = Enum.SurfaceType.Smooth
    wedge.Size = size
    wedge.CFrame = cframe
    wedge.Color = color
    wedge.Material = material

    if transparency then
        wedge.Transparency = transparency
    end

    wedge.Parent = parent

    return wedge
end

local function scaleColor(color: Color3, scale: number): Color3
    return Color3.fromRGB(
        math.clamp(math.floor(color.R * 255 * scale), 0, 255),
        math.clamp(math.floor(color.G * 255 * scale), 0, 255),
        math.clamp(math.floor(color.B * 255 * scale), 0, 255)
    )
end

local function fillTerrainBall(position: Vector3, radius: number, material: Enum.Material)
    pcall(function()
        Workspace.Terrain:FillBall(position, radius, material)
    end)
end

local function fillTerrainBlock(cframe: CFrame, size: Vector3, material: Enum.Material)
    pcall(function()
        Workspace.Terrain:FillBlock(cframe, size, material)
    end)
end

function BuildUtils.CreateMountain(
    parent: Instance,
    name: string,
    position: Vector3,
    baseWidth: number,
    height: number,
    depth: number,
    color: Color3,
    yawDegrees: number?
)
    local folder = BuildUtils.CreateFolder(parent, name)
    local yaw = math.rad(yawDegrees or 0)
    local baseCFrame = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    folder:SetAttribute("TerrainMountain", true)
    folder:SetAttribute("ColorPreview", color)

    fillTerrainBlock(
        baseCFrame * CFrame.new(0, math.max(4, height * 0.08), 0),
        Vector3.new(baseWidth * 0.94, math.max(10, height * 0.16), depth * 0.82),
        Enum.Material.Rock
    )

    for index = -3, 3 do
        local alpha = index / 3
        local widthFalloff = 1 - math.abs(alpha) * 0.38
        local ridgeHeight = height * (0.46 + widthFalloff * 0.34)
        local radius = math.max(18, math.min(baseWidth, depth) * (0.28 + widthFalloff * 0.18))
        local lateral = alpha * baseWidth * 0.32
        local offsetZ = math.sin(index * 1.7) * depth * 0.08
        local centerPosition = (baseCFrame * CFrame.new(lateral, ridgeHeight * 0.48, offsetZ)).Position

        fillTerrainBall(centerPosition, radius, Enum.Material.Rock)
        fillTerrainBall(centerPosition + Vector3.new(0, radius * 0.32, 0), radius * 0.68, Enum.Material.Rock)

        if index % 2 == 0 then
            fillTerrainBall(
                (baseCFrame * CFrame.new(lateral * 0.9, ridgeHeight * 0.42, offsetZ + depth * 0.22)).Position,
                radius * 0.64,
                Enum.Material.Sandstone
            )
        end
    end

    for index = 1, 7 do
        local alpha = index / 8
        local x = (alpha - 0.5) * baseWidth * 0.92
        local y = height * (0.22 + alpha * 0.16)
        local z = ((index % 2 == 0) and -1 or 1) * depth * (0.28 + alpha * 0.08)
        local shoulderCFrame = baseCFrame
            * CFrame.new(x, y, z)
            * CFrame.Angles(0, math.rad((index % 2 == 0) and 14 or -18), math.rad((index % 3 - 1) * 5))

        fillTerrainBlock(
            shoulderCFrame,
            Vector3.new(baseWidth * (0.22 + alpha * 0.05), math.max(9, height * 0.08), depth * 0.08),
            index % 2 == 0 and Enum.Material.Rock or Enum.Material.Sandstone
        )
    end
end

function BuildUtils.CreateDune(parent: Instance, name: string, position: Vector3, size: Vector3, color: Color3)
    local folder = BuildUtils.CreateFolder(parent, name)
    folder:SetAttribute("TerrainDune", true)
    folder:SetAttribute("ColorPreview", color)

    fillTerrainBlock(
        CFrame.new(position + Vector3.new(0, math.max(4, size.Y * 0.1), 0)),
        Vector3.new(size.X * 0.88, math.max(8, size.Y * 0.22), size.Z * 0.78),
        Enum.Material.Sand
    )

    for index = -2, 2 do
        local alpha = index / 2
        local radius = math.max(14, math.min(size.X, size.Z) * (0.24 + (1 - math.abs(alpha)) * 0.1))
        local centerPosition = position
            + Vector3.new(alpha * size.X * 0.28, size.Y * (0.22 + (1 - math.abs(alpha)) * 0.18), math.sin(index * 1.3) * size.Z * 0.14)

        fillTerrainBall(centerPosition, radius, Enum.Material.Sand)
    end

    fillTerrainBlock(
        CFrame.new(position + Vector3.new(0, math.max(3, size.Y * 0.08), size.Z * -0.32)) * CFrame.Angles(0, math.rad(9), 0),
        Vector3.new(size.X * 0.72, math.max(5, size.Y * 0.12), size.Z * 0.16),
        Enum.Material.Sandstone
    )
end

function BuildUtils.CreateRockCluster(parent: Instance, name: string, position: Vector3)
    local folder = BuildUtils.CreateFolder(parent, name)
    folder:SetAttribute("TerrainRockCluster", true)

    fillTerrainBlock(
        CFrame.new(position + Vector3.new(4, 4, -2)) * CFrame.Angles(0, math.rad(-12), 0),
        Vector3.new(52, 8, 38),
        Enum.Material.Rock
    )

    for index, offset in ipairs({
        Vector3.new(-16, 12, -16),
        Vector3.new(8, 16, 12),
        Vector3.new(24, 10, -10),
        Vector3.new(-4, 8, 18),
    }) do
        fillTerrainBall(
            position + offset,
            index == 2 and 18 or 13,
            index == 3 and Enum.Material.Sandstone or Enum.Material.Rock
        )
    end
end

function BuildUtils.CreateVerticalCylinder(
    parent: Instance,
    name: string,
    height: number,
    radius: number,
    position: Vector3,
    color: Color3,
    material: Enum.Material,
    transparency: number?
): Part
    return BuildUtils.CreatePart(
        parent,
        name,
        Vector3.new(height, radius * 2, radius * 2),
        CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
        color,
        material,
        Enum.PartType.Cylinder,
        transparency
    )
end

function BuildUtils.CreateSphere(
    parent: Instance,
    name: string,
    diameter: number,
    position: Vector3,
    color: Color3,
    material: Enum.Material,
    transparency: number?
): Part
    return BuildUtils.CreatePart(
        parent,
        name,
        Vector3.new(diameter, diameter, diameter),
        CFrame.new(position),
        color,
        material,
        Enum.PartType.Ball,
        transparency
    )
end

function BuildUtils.CreateModernTower(
    parent: Instance,
    name: string,
    position: Vector3,
    footprint: Vector2,
    height: number,
    bodyColor: Color3,
    windowColor: Color3
)
    local podiumHeight = math.max(14, math.floor(height * 0.18))
    local shaftHeight = height

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Podium", name),
        Vector3.new(footprint.X + 16, podiumHeight, footprint.Y + 16),
        CFrame.new(position + Vector3.new(0, podiumHeight * 0.5, 0)),
        Color3.fromRGB(238, 237, 233),
        Enum.Material.Marble,
        nil,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Shaft", name),
        Vector3.new(footprint.X, shaftHeight, footprint.Y),
        CFrame.new(position + Vector3.new(0, podiumHeight + shaftHeight * 0.5, 0)),
        bodyColor,
        Enum.Material.Marble,
        nil,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_GlassFront", name),
        Vector3.new(math.max(8, footprint.X * 0.42), math.max(16, shaftHeight - 18), 1.2),
        CFrame.new(position + Vector3.new(0, podiumHeight + shaftHeight * 0.5 + 2, footprint.Y * -0.5 - 0.7)),
        windowColor,
        Enum.Material.Glass,
        nil,
        0.2
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_GlassBack", name),
        Vector3.new(math.max(8, footprint.X * 0.42), math.max(16, shaftHeight - 18), 1.2),
        CFrame.new(position + Vector3.new(0, podiumHeight + shaftHeight * 0.5 + 2, footprint.Y * 0.5 + 0.7)),
        windowColor,
        Enum.Material.Glass,
        nil,
        0.2
    )

    local windowRows = math.clamp(math.floor(shaftHeight / 34), 4, 11)
    local windowRowSpacing = shaftHeight / (windowRows + 1)

    for row = 1, windowRows do
        local y = podiumHeight + row * windowRowSpacing

        BuildUtils.CreatePart(
            parent,
            string.format("%s_FloorLineFront_%d", name, row),
            Vector3.new(math.max(10, footprint.X - 8), 0.8, 1.35),
            CFrame.new(position + Vector3.new(0, y, footprint.Y * -0.5 - 1)),
            Color3.fromRGB(236, 229, 211),
            Enum.Material.Metal,
            nil,
            nil
        )

        BuildUtils.CreatePart(
            parent,
            string.format("%s_FloorLineBack_%d", name, row),
            Vector3.new(math.max(10, footprint.X - 8), 0.8, 1.35),
            CFrame.new(position + Vector3.new(0, y, footprint.Y * 0.5 + 1)),
            Color3.fromRGB(236, 229, 211),
            Enum.Material.Metal,
            nil,
            nil
        )

        BuildUtils.CreatePart(
            parent,
            string.format("%s_SideGlassWest_%d", name, row),
            Vector3.new(1.25, 6, math.max(10, footprint.Y * 0.42)),
            CFrame.new(position + Vector3.new(footprint.X * -0.5 - 0.8, y + 3, 0)),
            windowColor,
            Enum.Material.Glass,
            nil,
            0.24
        )

        BuildUtils.CreatePart(
            parent,
            string.format("%s_SideGlassEast_%d", name, row),
            Vector3.new(1.25, 6, math.max(10, footprint.Y * 0.42)),
            CFrame.new(position + Vector3.new(footprint.X * 0.5 + 0.8, y + 3, 0)),
            windowColor,
            Enum.Material.Glass,
            nil,
            0.24
        )
    end

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Crown", name),
        Vector3.new(footprint.X - 6, 8, footprint.Y - 6),
        CFrame.new(position + Vector3.new(0, podiumHeight + shaftHeight + 4, 0)),
        Color3.fromRGB(233, 231, 225),
        Enum.Material.Marble,
        nil,
        nil
    )
end

function BuildUtils.CreateMinaret(parent: Instance, name: string, position: Vector3, height: number, bodyColor: Color3, accentColor: Color3)
    local baseHeight = math.max(16, math.floor(height * 0.18))
    local lowerHeight = math.max(24, math.floor(height * 0.34))
    local upperHeight = math.max(20, math.floor(height * 0.24))
    local capHeight = math.max(10, math.floor(height * 0.12))

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Base", name),
        Vector3.new(14, baseHeight, 14),
        CFrame.new(position + Vector3.new(0, baseHeight * 0.5, 0)),
        bodyColor,
        Enum.Material.Marble,
        nil,
        nil
    )

    BuildUtils.CreateVerticalCylinder(
        parent,
        string.format("%s_Lower", name),
        lowerHeight,
        4,
        position + Vector3.new(0, baseHeight + lowerHeight * 0.5, 0),
        bodyColor,
        Enum.Material.Marble,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_BalconyLower", name),
        Vector3.new(12, 2, 12),
        CFrame.new(position + Vector3.new(0, baseHeight + lowerHeight + 1, 0)),
        accentColor,
        Enum.Material.Marble,
        nil,
        nil
    )

    BuildUtils.CreateVerticalCylinder(
        parent,
        string.format("%s_Upper", name),
        upperHeight,
        2.6,
        position + Vector3.new(0, baseHeight + lowerHeight + 2 + upperHeight * 0.5, 0),
        bodyColor,
        Enum.Material.Marble,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_BalconyUpper", name),
        Vector3.new(9, 2, 9),
        CFrame.new(position + Vector3.new(0, baseHeight + lowerHeight + upperHeight + 3, 0)),
        accentColor,
        Enum.Material.Marble,
        nil,
        nil
    )

    BuildUtils.CreateVerticalCylinder(
        parent,
        string.format("%s_Cap", name),
        capHeight,
        1.7,
        position + Vector3.new(0, baseHeight + lowerHeight + upperHeight + 3 + capHeight * 0.5 + 1, 0),
        bodyColor,
        Enum.Material.Marble,
        nil
    )

    BuildUtils.CreateSphere(
        parent,
        string.format("%s_Dome", name),
        4.8,
        position + Vector3.new(0, baseHeight + lowerHeight + upperHeight + capHeight + 7, 0),
        accentColor,
        Enum.Material.SmoothPlastic,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Spire", name),
        Vector3.new(1, 8, 1),
        CFrame.new(position + Vector3.new(0, baseHeight + lowerHeight + upperHeight + capHeight + 12, 0)),
        Color3.fromRGB(205, 176, 108),
        Enum.Material.Metal,
        nil,
        nil
    )
end

function BuildUtils.CreateCourtyardCanopy(parent: Instance, name: string, position: Vector3, canopyColor: Color3, poleColor: Color3)
    BuildUtils.CreateVerticalCylinder(
        parent,
        string.format("%s_Pole", name),
        16,
        0.7,
        position + Vector3.new(0, 8, 0),
        poleColor,
        Enum.Material.Metal,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Canopy", name),
        Vector3.new(22, 1, 22),
        CFrame.new(position + Vector3.new(0, 16.5, 0)),
        canopyColor,
        Enum.Material.Fabric,
        nil,
        nil
    )

    BuildUtils.CreatePart(
        parent,
        string.format("%s_Cap", name),
        Vector3.new(7, 1, 7),
        CFrame.new(position + Vector3.new(0, 17.3, 0)),
        Color3.fromRGB(243, 242, 238),
        Enum.Material.Marble,
        nil,
        nil
    )

    for index, offset in ipairs({
        Vector3.new(-8.5, 15.8, -8.5),
        Vector3.new(8.5, 15.8, -8.5),
        Vector3.new(-8.5, 15.8, 8.5),
        Vector3.new(8.5, 15.8, 8.5),
    }) do
        BuildUtils.CreateSphere(
            parent,
            string.format("%s_Tip_%d", name, index),
            2.2,
            position + offset,
            canopyColor,
            Enum.Material.SmoothPlastic,
            nil
        )
    end
end

return BuildUtils
