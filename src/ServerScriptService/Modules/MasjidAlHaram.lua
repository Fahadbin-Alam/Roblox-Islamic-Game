--!strict

-- Builds the Masjid al-Haram hub from parts, modelled on the mosque as it stands today:
--   * the Kaaba with its black kiswa, gold hizam band, sitara door curtain, Black Stone in its
--     silver frame, Rukn al-Yamani, the gold Mizab and the Shadharwan base,
--   * Hijr Ismail, Maqam Ibrahim in its gold-and-glass case and the white marble mataf,
--   * the multi-level mataf expansion (walkable by ramps), the Ottoman riwaq ring,
--   * the first Saudi galleries, the Safa-Marwa mas'a with its green-lit stretch,
--   * the King Fahd and King Abdullah expansions with their named gates,
--   * thirteen minarets in the gate pairs, and the Abraj Al-Bait clock tower to the south.
--
-- Compass in this world: +Z is north (towards Madinah), -Z south, -X east, +X west.
-- The Kaaba is turned 45 degrees so its corners point to the compass like the real one:
-- the Black Stone corner faces east, the door is on the north-east face and Hijr Ismail
-- is on the north-west side.
--
-- Scale: the Kaaba and the mataf use about 4 studs per metre. The galleries and skyline are
-- compressed so the whole sanctuary fits the hub; the clock tower is drawn to read as the
-- tallest landmark rather than at its true 601 m.
--
-- Performance: decorative parts do not collide, touch or cast shadows; calligraphy and kiswa
-- patterns are SurfaceGui frames rather than parts; night lights are tagged and only enabled
-- at night by HaramTimeService.

local CollectionService = game:GetService("CollectionService")

local BuildUtils = require(script.Parent.BuildUtils)

local MasjidAlHaram = {}

MasjidAlHaram.FloorHeight = 6.6
MasjidAlHaram.MatafOpenRadius = 200
MasjidAlHaram.NightLightTag = "HaramNightLight"
MasjidAlHaram.NightGlowTag = "HaramNightGlow"
MasjidAlHaram.ClockHandTag = "HaramClockHand"

local FLOOR = MasjidAlHaram.FloorHeight

-- Ring storeys of the mataf expansion and the galleries (heights of each walking surface).
local LEVELS = { FLOOR, 30, 54, 78 }

local KISWA_BLACK = Color3.fromRGB(14, 14, 14)
local KISWA_WEAVE = Color3.fromRGB(30, 30, 29)
local EMBROIDERY_GOLD = Color3.fromRGB(214, 172, 74)
local BRIGHT_GOLD = Color3.fromRGB(232, 194, 96)
local SILVER = Color3.fromRGB(205, 208, 212)
local MATAF_WHITE = Color3.fromRGB(242, 242, 238)
local GALLERY_CREAM = Color3.fromRGB(233, 226, 210)
local COLUMN_WHITE = Color3.fromRGB(240, 236, 226)
local ARCH_STONE = Color3.fromRGB(219, 208, 186)
local OTTOMAN_STONE = Color3.fromRGB(176, 168, 152)
local OTTOMAN_DOME = Color3.fromRGB(212, 208, 198)
local WINDOW_GLASS = Color3.fromRGB(96, 116, 128)
local LIGHT_WARM = Color3.fromRGB(255, 236, 204)
local SAI_GREEN = Color3.fromRGB(40, 200, 110)
local MINARET_WHITE = Color3.fromRGB(236, 232, 222)
local CLOCK_GREEN = Color3.fromRGB(26, 92, 64)

type PartOptions = {
    Shape: Enum.PartType?,
    Transparency: number?,
    Decor: boolean?,
}

---------------------------------------------------------------------------- helpers

local function makeDecor(part: BasePart): BasePart
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    return part
end

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, options: PartOptions?): Part
    local created = BuildUtils.CreatePart(parent, name, size, cframe, color, material, options and options.Shape, options and options.Transparency)

    if options and options.Decor then
        makeDecor(created)
    end

    return created
end

local function decor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, transparency: number?): Part
    return part(parent, name, size, cframe, color, material, { Decor = true, Transparency = transparency })
end

local function vcyl(parent: Instance, name: string, height: number, radius: number, position: Vector3, color: Color3, material: Enum.Material, isDecor: boolean?): Part
    local created = part(parent, name, Vector3.new(height, radius * 2, radius * 2), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, material, { Shape = Enum.PartType.Cylinder, Decor = isDecor })
    return created
end

local function ball(parent: Instance, name: string, diameter: number, position: Vector3, color: Color3, material: Enum.Material, isDecor: boolean?): Part
    return part(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(position), color, material, { Shape = Enum.PartType.Ball, Decor = isDecor })
end

-- A frame whose local +Z points away from `center` along `angle` (radians, measured from +X
-- towards +Z) and whose local +X runs along the circle.
local function radialFrame(center: Vector3, angle: number, radius: number, y: number): CFrame
    return CFrame.new(center + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)) * CFrame.Angles(0, math.pi * 0.5 - angle, 0)
end

local function chordWidth(radius: number, segmentAngle: number): number
    return 2 * radius * math.sin(segmentAngle * 0.5)
end

local function addNightLight(host: BasePart, color: Color3, brightness: number, range: number)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = false
    light.Enabled = false
    light.Parent = host
    CollectionService:AddTag(light, MasjidAlHaram.NightLightTag)
    return light
end

-- Parts that switch to Neon after dark (lamps, clock faces, the green sa'i lights).
local function glowAtNight(target: BasePart)
    target:SetAttribute("DayMaterial", target.Material.Name)
    CollectionService:AddTag(target, MasjidAlHaram.NightGlowTag)
end

-- An invisible anchor that only carries a night light.
local function lightAnchor(parent: Instance, name: string, position: Vector3, color: Color3, brightness: number, range: number)
    local anchor = decor(parent, name, Vector3.new(1, 1, 1), CFrame.new(position), color, Enum.Material.SmoothPlastic, 1)
    addNightLight(anchor, color, brightness, range)
    return anchor
end

-- Two leaning bars meeting at a point: a pointed arch outline between two columns.
local function pointedArch(parent: Instance, name: string, frame: CFrame, span: number, rise: number, thickness: number, depth: number, color: Color3)
    local half = span * 0.5
    local length = math.sqrt(half * half + rise * rise) + thickness * 0.5
    local tilt = math.atan2(rise, half)

    decor(parent, name .. "_L", Vector3.new(length, thickness, depth), frame * CFrame.new(-half * 0.5, rise * 0.5, 0) * CFrame.Angles(0, 0, tilt), color, Enum.Material.Marble)
    decor(parent, name .. "_R", Vector3.new(length, thickness, depth), frame * CFrame.new(half * 0.5, rise * 0.5, 0) * CFrame.Angles(0, 0, -tilt), color, Enum.Material.Marble)
end

local function wedge(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): WedgePart
    local created = BuildUtils.CreateWedge(parent, name, size, cframe, color, material, nil)
    makeDecor(created)
    return created
end

-- A filled pointed-arch bay: two triangular spandrels (wedges) above the arch legs, so the
-- wall between two columns reads as solid masonry with a pointed opening below.
-- `frame` is the bay centre at ground level, local X along the arcade, local Z outward.
local function arcadeBay(parent: Instance, name: string, frame: CFrame, half: number, springY: number, topY: number, thickness: number, fillColor: Color3, archColor: Color3)
    local rise = topY - springY
    if rise <= 0.5 or half <= 0.5 then
        return
    end
    local midY = (springY + topY) * 0.5
    -- Wedge right angles sit at the top corners beside each column.
    wedge(parent, name .. "_SpandrelL", Vector3.new(thickness, rise, half), frame * CFrame.fromMatrix(Vector3.new(-half * 0.5, midY, 0), Vector3.new(0, 0, -1), Vector3.new(0, -1, 0), Vector3.new(-1, 0, 0)), fillColor, Enum.Material.Marble)
    wedge(parent, name .. "_SpandrelR", Vector3.new(thickness, rise, half), frame * CFrame.fromMatrix(Vector3.new(half * 0.5, midY, 0), Vector3.new(0, 0, 1), Vector3.new(0, -1, 0), Vector3.new(1, 0, 0)), fillColor, Enum.Material.Marble)
    local length = math.sqrt(half * half + rise * rise) + 0.6
    local tilt = math.atan2(rise, half)
    decor(parent, name .. "_ArchL", Vector3.new(length, 0.9, thickness + 0.3), frame * CFrame.new(-half * 0.5, midY, 0) * CFrame.Angles(0, 0, tilt), archColor, Enum.Material.Marble)
    decor(parent, name .. "_ArchR", Vector3.new(length, 0.9, thickness + 0.3), frame * CFrame.new(half * 0.5, midY, 0) * CFrame.Angles(0, 0, -tilt), archColor, Enum.Material.Marble)
end

---------------------------------------------------------------------------- SurfaceGui patterns

local function newSurfaceGui(host: BasePart, face: Enum.NormalId, pixelsPerStud: number): SurfaceGui
    local gui = Instance.new("SurfaceGui")
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = pixelsPerStud
    gui.LightInfluence = 1
    gui.ClipsDescendants = true
    gui.Parent = host
    return gui
end

-- Places a frame using stud units on a face that is `width` x `height` studs.
local function guiBox(gui: SurfaceGui, width: number, height: number, x: number, y: number, w: number, h: number, color: Color3, rotation: number?, round: boolean?): Frame
    local box = Instance.new("Frame")
    box.BorderSizePixel = 0
    box.BackgroundColor3 = color
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(x / width, y / height)
    box.Size = UDim2.fromScale(w / width, h / height)
    box.Rotation = rotation or 0

    if round then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = box
    end

    box.Parent = gui
    return box
end

-- Deterministic pseudo-random numbers so every server builds the same pattern.
local function makeRandom(seed: number)
    local state = seed
    return function(low: number, high: number): number
        state = (state * 1103515245 + 12345) % 2147483648
        return low + (high - low) * (state / 2147483648)
    end
end

-- Draws a row of stylised gold thuluth-like strokes (tall uprights, bowls, connecting
-- baselines, sweeping diagonals and dots). It is decorative script, deliberately not a
-- readable verse, so no sacred text is ever shown distorted.
local function scriptRow(gui: SurfaceGui, faceW: number, faceH: number, x0: number, x1: number, baseline: number, scale: number, seed: number, color: Color3)
    local random = makeRandom(seed)
    local x = x0 + 0.2 * scale

    guiBox(gui, faceW, faceH, (x0 + x1) * 0.5, baseline, x1 - x0, 0.09 * scale, color)

    while x < x1 - 0.4 * scale do
        local choice = random(0, 1)

        if choice < 0.34 then
            local tall = random(1.1, 1.75) * scale
            guiBox(gui, faceW, faceH, x, baseline - tall * 0.5, 0.13 * scale, tall, color, random(-6, 6))
            x += random(0.22, 0.4) * scale
        elseif choice < 0.56 then
            local size = random(0.42, 0.62) * scale
            guiBox(gui, faceW, faceH, x + size * 0.5, baseline - size * 0.45, size, size * 0.8, color, nil, true)
            x += size + 0.12 * scale
        elseif choice < 0.78 then
            local length = random(0.6, 1.2) * scale
            guiBox(gui, faceW, faceH, x + length * 0.5, baseline - length * 0.3, length, 0.1 * scale, color, random(-38, -24))
            x += length * 0.75
        else
            guiBox(gui, faceW, faceH, x, baseline - random(1.15, 1.55) * scale, 0.16 * scale, 0.16 * scale, color, 45)
            guiBox(gui, faceW, faceH, x + 0.18 * scale, baseline + 0.32 * scale, 0.13 * scale, 0.13 * scale, color, 45)
            x += 0.3 * scale
        end
    end
end

local function roundel(gui: SurfaceGui, faceW: number, faceH: number, x: number, y: number, diameter: number)
    guiBox(gui, faceW, faceH, x, y, diameter, diameter, EMBROIDERY_GOLD, nil, true)
    guiBox(gui, faceW, faceH, x, y, diameter * 0.8, diameter * 0.8, KISWA_BLACK, nil, true)
    guiBox(gui, faceW, faceH, x, y, diameter * 0.46, diameter * 0.46, EMBROIDERY_GOLD, nil, true)
    guiBox(gui, faceW, faceH, x, y, diameter * 0.3, diameter * 0.3, KISWA_BLACK, nil, true)
end

---------------------------------------------------------------------------- the Kaaba

local KAABA_LENGTH = 51.4 -- north-east and south-west faces (about 12.9 m)
local KAABA_WIDTH = 44.1 -- north-west and south-east faces (about 11 m)
local KAABA_HEIGHT = 52.4 -- about 13.1 m
local HIZAM_CENTER = 38.2
local HIZAM_HEIGHT = 4.2

type FaceInfo = { Name: string, Normal: Vector3, Width: number }

local KAABA_FACES: { FaceInfo } = {
    { Name = "NorthEast", Normal = Vector3.new(0, 0, 1), Width = KAABA_LENGTH },
    { Name = "SouthWest", Normal = Vector3.new(0, 0, -1), Width = KAABA_LENGTH },
    { Name = "NorthWest", Normal = Vector3.new(1, 0, 0), Width = KAABA_WIDTH },
    { Name = "SouthEast", Normal = Vector3.new(-1, 0, 0), Width = KAABA_WIDTH },
}

-- A thin panel standing just outside a Kaaba face; its Front face looks outward.
local function facePanel(parent: Instance, name: string, kaaba: CFrame, face: FaceInfo, lateral: number, y: number, width: number, height: number, standOff: number, color: Color3, material: Enum.Material): Part
    local halfDepth = if face.Normal.X ~= 0 then KAABA_LENGTH * 0.5 else KAABA_WIDTH * 0.5
    local side = Vector3.new(face.Normal.Z, 0, -face.Normal.X)
    local localCenter = face.Normal * (halfDepth + standOff) + side * lateral + Vector3.new(0, y, 0)
    local frame = kaaba * CFrame.lookAt(localCenter, localCenter + face.Normal)
    return decor(parent, name, Vector3.new(width, height, 0.25), frame, color, material)
end

local function decorateKiswaFace(parent: Instance, kaaba: CFrame, face: FaceInfo, faceIndex: number)
    local width = face.Width

    -- Woven jacquard: the faint diagonal lattice of the black silk.
    local weave = facePanel(parent, "KiswaWeave_" .. face.Name, kaaba, face, 0, KAABA_HEIGHT * 0.5 + 1, width, KAABA_HEIGHT - 2, 0.06, KISWA_BLACK, Enum.Material.Fabric)
    local weaveGui = newSurfaceGui(weave, Enum.NormalId.Front, 12)
    local weaveH = KAABA_HEIGHT - 2
    local step = 3.4
    local diagonal = math.sqrt(width * width + weaveH * weaveH) * 2
    local offset = -weaveH
    while offset < width + weaveH do
        guiBox(weaveGui, width, weaveH, offset, weaveH * 0.5, 0.12, diagonal, KISWA_WEAVE, 35)
        guiBox(weaveGui, width, weaveH, offset, weaveH * 0.5, 0.12, diagonal, KISWA_WEAVE, -35)
        offset += step
    end

    -- The kiswa is sewn from long vertical panels; their seams show as faint lines.
    local panelW = 4.3
    local seamX = panelW
    while seamX < width - 1 do
        guiBox(weaveGui, width, weaveH, seamX, weaveH * 0.5, 0.08, weaveH, Color3.fromRGB(6, 6, 6))
        seamX += panelW
    end

    -- Embroidered roundels at each corner just under the band, and a small inscription panel
    -- near the hem, both in gold thread.
    local underBand = KAABA_HEIGHT - (HIZAM_CENTER - HIZAM_HEIGHT * 0.5) + 2.6
    roundel(weaveGui, width, weaveH, 3.2, underBand, 3.4)
    roundel(weaveGui, width, weaveH, width - 3.2, underBand, 3.4)
    guiBox(weaveGui, width, weaveH, width * 0.5, weaveH - 3.1, width - 2, 0.12, EMBROIDERY_GOLD)
    guiBox(weaveGui, width, weaveH, width * 0.5, weaveH - 1.1, width - 2, 0.12, EMBROIDERY_GOLD)
    scriptRow(weaveGui, width, weaveH, 1.6, width - 1.6, weaveH - 1.5, 0.75, faceIndex * 211, Color3.fromRGB(176, 140, 62))

    -- Hizam: the embroidered band two-thirds up, panels of script between roundels.
    local band = facePanel(parent, "Hizam_" .. face.Name, kaaba, face, 0, HIZAM_CENTER, width + 0.6, HIZAM_HEIGHT, 0.2, Color3.fromRGB(22, 19, 14), Enum.Material.Fabric)
    local bandGui = newSurfaceGui(band, Enum.NormalId.Front, 40)
    local bandW = width + 0.6
    guiBox(bandGui, bandW, HIZAM_HEIGHT, bandW * 0.5, 0.18, bandW, 0.22, EMBROIDERY_GOLD)
    guiBox(bandGui, bandW, HIZAM_HEIGHT, bandW * 0.5, HIZAM_HEIGHT - 0.18, bandW, 0.22, EMBROIDERY_GOLD)
    guiBox(bandGui, bandW, HIZAM_HEIGHT, bandW * 0.5, 0.42, bandW, 0.06, EMBROIDERY_GOLD)
    guiBox(bandGui, bandW, HIZAM_HEIGHT, bandW * 0.5, HIZAM_HEIGHT - 0.42, bandW, 0.06, EMBROIDERY_GOLD)

    local panelCount = 4
    local panelW = bandW / panelCount
    for panel = 1, panelCount do
        local x0 = (panel - 1) * panelW
        scriptRow(bandGui, bandW, HIZAM_HEIGHT, x0 + 1.9, x0 + panelW - 1.9, HIZAM_HEIGHT * 0.66, 1.2, faceIndex * 97 + panel * 13, EMBROIDERY_GOLD)
        if panel > 1 then
            roundel(bandGui, bandW, HIZAM_HEIGHT, x0, HIZAM_HEIGHT * 0.5, 3.0)
        end
    end
    roundel(bandGui, bandW, HIZAM_HEIGHT, 1.6, HIZAM_HEIGHT * 0.5, 2.8)
    roundel(bandGui, bandW, HIZAM_HEIGHT, bandW - 1.6, HIZAM_HEIGHT * 0.5, 2.8)

    -- Qanadil: the lamp-shaped embroidered panels hanging under the band.
    local lampCount = if face.Name == "NorthEast" then 2 else 3
    for lamp = 1, lampCount do
        local lateral = (lamp - (lampCount + 1) * 0.5) * (width / (lampCount + 0.6))
        if face.Name == "NorthEast" then
            lateral = if lamp == 1 then 9 else 20
        end
        local panelH = 6.4
        local lampPanel = facePanel(parent, string.format("Qandil_%s_%d", face.Name, lamp), kaaba, face, lateral, HIZAM_CENTER - HIZAM_HEIGHT * 0.5 - panelH * 0.5 - 0.6, 4.4, panelH, 0.18, KISWA_BLACK, Enum.Material.Fabric)
        local lampGui = newSurfaceGui(lampPanel, Enum.NormalId.Front, 40)
        guiBox(lampGui, 4.4, panelH, 2.2, 0.4, 0.5, 0.8, EMBROIDERY_GOLD)
        guiBox(lampGui, 4.4, panelH, 2.2, 1.7, 2.6, 2.0, EMBROIDERY_GOLD, nil, true)
        guiBox(lampGui, 4.4, panelH, 2.2, 3.9, 4.0, 4.2, EMBROIDERY_GOLD)
        guiBox(lampGui, 4.4, panelH, 2.2, 3.9, 3.5, 3.7, KISWA_BLACK)
        scriptRow(lampGui, 4.4, panelH, 0.6, 3.8, 3.4, 0.55, faceIndex * 31 + lamp, EMBROIDERY_GOLD)
        scriptRow(lampGui, 4.4, panelH, 0.6, 3.8, 5.0, 0.5, faceIndex * 53 + lamp, EMBROIDERY_GOLD)
    end
end

local function buildKaaba(parent: Instance, center: Vector3): CFrame
    local folder = BuildUtils.CreateFolder(parent, "Kaaba")
    local kaaba = CFrame.new(center + Vector3.new(0, FLOOR, 0)) * CFrame.Angles(0, math.rad(-45), 0)
    local halfL, halfW = KAABA_LENGTH * 0.5, KAABA_WIDTH * 0.5

    -- Shadharwan: the sloping marble skirt with brass rings for the kiswa ropes.
    part(folder, "Shadharwan", Vector3.new(KAABA_LENGTH + 5, 2.2, KAABA_WIDTH + 5), kaaba * CFrame.new(0, 1.1, 0), Color3.fromRGB(226, 222, 212), Enum.Material.Marble)
    part(folder, "ShadharwanSlope", Vector3.new(KAABA_LENGTH + 2.6, 1.1, KAABA_WIDTH + 2.6), kaaba * CFrame.new(0, 2.75, 0), Color3.fromRGB(214, 209, 198), Enum.Material.Marble)

    for _, face in ipairs(KAABA_FACES) do
        local halfDepth = if face.Normal.X ~= 0 then halfL else halfW
        local side = Vector3.new(face.Normal.Z, 0, -face.Normal.X)
        for ring = 1, 6 do
            local lateral = (ring - 3.5) * (face.Width / 6.6)
            local p = face.Normal * (halfDepth + 1.9) + side * lateral + Vector3.new(0, 2.6, 0)
            decor(folder, string.format("ShadharwanRing_%s_%d", face.Name, ring), Vector3.new(0.9, 0.9, 0.3), kaaba * CFrame.lookAt(p, p + face.Normal), BRIGHT_GOLD, Enum.Material.Metal)
        end
    end

    -- The stone body wrapped in the black kiswa.
    part(folder, "KaabaBody", Vector3.new(KAABA_LENGTH, KAABA_HEIGHT, KAABA_WIDTH), kaaba * CFrame.new(0, KAABA_HEIGHT * 0.5, 0), KISWA_BLACK, Enum.Material.Fabric)
    part(folder, "KaabaRoof", Vector3.new(KAABA_LENGTH - 0.6, 0.8, KAABA_WIDTH - 0.6), kaaba * CFrame.new(0, KAABA_HEIGHT + 0.4, 0), Color3.fromRGB(176, 170, 160), Enum.Material.Marble)
    decor(folder, "KiswaTopFold", Vector3.new(KAABA_LENGTH + 0.4, 1.4, KAABA_WIDTH + 0.4), kaaba * CFrame.new(0, KAABA_HEIGHT - 0.5, 0), Color3.fromRGB(10, 10, 10), Enum.Material.Fabric)

    for index, face in ipairs(KAABA_FACES) do
        decorateKiswaFace(folder, kaaba, face, index)
    end

    -- Door on the north-east face, raised about 2.1 m, covered by the embroidered sitara.
    local doorLateral = -halfL + 15.5
    local northEast = KAABA_FACES[1]
    facePanel(folder, "KaabaDoorFrame", kaaba, northEast, doorLateral, 8.6 + 7, 9.4, 14.2, 0.32, EMBROIDERY_GOLD, Enum.Material.Metal)
    facePanel(folder, "KaabaDoorSill", kaaba, northEast, doorLateral, 8.2, 17.4, 0.8, 0.9, BRIGHT_GOLD, Enum.Material.Metal)
    facePanel(folder, "KaabaDoorSillMarble", kaaba, northEast, doorLateral, 7.6, 18.2, 0.6, 0.7, Color3.fromRGB(226, 222, 212), Enum.Material.Marble)
    local sitaraH = 27
    local sitara = facePanel(folder, "Sitara", kaaba, northEast, doorLateral, 8.6 + sitaraH * 0.5 - 0.4, 15.6, sitaraH, 0.45, KISWA_BLACK, Enum.Material.Fabric)
    local sitaraGui = newSurfaceGui(sitara, Enum.NormalId.Front, 30)
    guiBox(sitaraGui, 15.6, sitaraH, 7.8, sitaraH * 0.5, 15.0, sitaraH - 0.6, EMBROIDERY_GOLD)
    guiBox(sitaraGui, 15.6, sitaraH, 7.8, sitaraH * 0.5, 14.2, sitaraH - 1.4, KISWA_BLACK)
    for row = 1, 5 do
        local baseline = 1.9 + (row - 1) * 2.2
        scriptRow(sitaraGui, 15.6, sitaraH, 1.3, 14.3, baseline, 0.8, 400 + row * 7, EMBROIDERY_GOLD)
    end
    guiBox(sitaraGui, 15.6, sitaraH, 7.8, 12.8, 13.4, 0.18, EMBROIDERY_GOLD)
    roundel(sitaraGui, 15.6, sitaraH, 7.8, 16.4, 5.0)
    roundel(sitaraGui, 15.6, sitaraH, 3.6, 21.6, 3.0)
    roundel(sitaraGui, 15.6, sitaraH, 12.0, 21.6, 3.0)
    for row = 1, 2 do
        scriptRow(sitaraGui, 15.6, sitaraH, 1.3, 14.3, 23.8 + row * 1.2, 0.5, 500 + row, EMBROIDERY_GOLD)
    end

    -- Black Stone in its silver frame, set into the eastern corner about 1.5 m up.
    local corner = Vector3.new(-halfL, 6.0, halfW)
    local outward = Vector3.new(-1, 0, 1).Unit
    local stoneFrame = kaaba * CFrame.lookAt(corner + outward * 0.4, corner + outward * 2)
    part(folder, "BlackStoneSilverFrame", Vector3.new(3.4, 4.4, 2.2), stoneFrame, SILVER, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
    decor(folder, "BlackStone", Vector3.new(1.9, 2.3, 1.3), stoneFrame * CFrame.new(0, 0.1, -0.75), Color3.fromRGB(38, 28, 28), Enum.Material.Slate)
    decor(folder, "BlackStoneSilverRim", Vector3.new(4.0, 5.2, 1.0), stoneFrame * CFrame.new(0, 0, 0.35), Color3.fromRGB(176, 180, 186), Enum.Material.Metal).Shape = Enum.PartType.Ball
    -- The kiswa is cut back around the stone and edged with gold embroidery on both faces.
    for _, side in ipairs({ { Face = KAABA_FACES[1], Lateral = -halfL + 2.6 }, { Face = KAABA_FACES[4], Lateral = halfW - 2.6 } }) do
        local edge = facePanel(folder, "BlackStoneKiswaEdge_" .. side.Face.Name, kaaba, side.Face, side.Lateral, 6.0, 4.6, 9.6, 0.3, KISWA_BLACK, Enum.Material.Fabric)
        local edgeGui = newSurfaceGui(edge, Enum.NormalId.Front, 40)
        guiBox(edgeGui, 4.6, 9.6, 2.3, 4.8, 4.4, 9.4, EMBROIDERY_GOLD)
        guiBox(edgeGui, 4.6, 9.6, 2.3, 4.8, 3.8, 8.8, KISWA_BLACK)
        scriptRow(edgeGui, 4.6, 9.6, 0.6, 4.0, 2.4, 0.5, 900 + side.Lateral, EMBROIDERY_GOLD)
        scriptRow(edgeGui, 4.6, 9.6, 0.6, 4.0, 8.4, 0.5, 950 + side.Lateral, EMBROIDERY_GOLD)
    end

    -- Rukn al-Yamani: the southern corner where the stone shows beneath the kiswa.
    local yemeni = Vector3.new(-halfL, 0, -halfW)
    local yemeniOut = Vector3.new(-1, 0, -1).Unit
    decor(folder, "RuknYamani", Vector3.new(3.2, 7.2, 0.4), kaaba * CFrame.lookAt(yemeni + yemeniOut * 0.35 + Vector3.new(0, 6.4, 0), yemeni + yemeniOut * 2 + Vector3.new(0, 6.4, 0)), Color3.fromRGB(128, 118, 104), Enum.Material.Slate)

    -- Mizab al-Rahmah: the gold rain spout on the north-west roof edge, over Hijr Ismail.
    decor(folder, "MizabSpout", Vector3.new(8.2, 0.9, 1.4), kaaba * CFrame.new(halfL + 3.6, KAABA_HEIGHT - 0.4, 0), BRIGHT_GOLD, Enum.Material.Metal)
    decor(folder, "MizabSideA", Vector3.new(8.2, 1.2, 0.25), kaaba * CFrame.new(halfL + 3.6, KAABA_HEIGHT, 0.7), BRIGHT_GOLD, Enum.Material.Metal)
    decor(folder, "MizabSideB", Vector3.new(8.2, 1.2, 0.25), kaaba * CFrame.new(halfL + 3.6, KAABA_HEIGHT, -0.7), BRIGHT_GOLD, Enum.Material.Metal)

    return kaaba
end

---------------------------------------------------------------------------- Hijr Ismail and Maqam Ibrahim

local function buildHijrIsmail(parent: Instance, kaaba: CFrame): Vector3
    local folder = BuildUtils.CreateFolder(parent, "HijrIsmail")
    local faceX = KAABA_LENGTH * 0.5
    local depth = 34 -- about 8.5 m out from the wall
    local halfSpan = KAABA_WIDTH * 0.5 + 1.5
    local segments = 14
    local startAngle, endAngle = math.rad(-72), math.rad(72)

    local function point(t: number): Vector3
        return Vector3.new(faceX + math.cos(t) * depth, 0, math.sin(t) * halfSpan)
    end

    for index = 1, segments do
        local a = startAngle + (endAngle - startAngle) * (index - 1) / segments
        local b = startAngle + (endAngle - startAngle) * index / segments
        local p0, p1 = point(a), point(b)
        local mid = (p0 + p1) * 0.5
        local length = (p1 - p0).Magnitude + 0.9
        local frame = kaaba * CFrame.lookAt(mid + Vector3.new(0, 2.65, 0), p1 + Vector3.new(0, 2.65, 0))
        part(folder, string.format("HijrWall_%02d", index), Vector3.new(5.2, 5.3, length), frame, Color3.fromRGB(240, 238, 232), Enum.Material.Marble)
        decor(folder, string.format("HijrCoping_%02d", index), Vector3.new(5.6, 0.5, length + 0.1), frame * CFrame.new(0, 2.85, 0), Color3.fromRGB(206, 198, 184), Enum.Material.Marble)
        decor(folder, string.format("HijrInlay_%02d", index), Vector3.new(5.35, 0.35, length), frame * CFrame.new(0, 1.4, 0), Color3.fromRGB(178, 164, 132), Enum.Material.Marble)
    end

    for index, t in ipairs({ startAngle, endAngle }) do
        local p = point(t)
        vcyl(folder, string.format("HijrWallEnd_%d", index), 5.8, 2.9, (kaaba * CFrame.new(p + Vector3.new(0, 2.9, 0))).Position, Color3.fromRGB(240, 238, 232), Enum.Material.Marble)
    end

    -- The two openings between the wall ends and the Kaaba corners, paved in grey marble.
    for index, sign in ipairs({ -1, 1 }) do
        decor(folder, string.format("HijrOpening_%d", index), Vector3.new(6.5, 0.12, 6), kaaba * CFrame.new(faceX + 4.5, 0.06, sign * (halfSpan - 2.5)), Color3.fromRGB(196, 192, 184), Enum.Material.Marble)
    end
    -- Brass lamps along the top of the wall.
    for index, t in ipairs({ math.rad(-40), math.rad(0), math.rad(40) }) do
        local p = point(t)
        local lampBase = (kaaba * CFrame.new(p + Vector3.new(0, 5.6, 0))).Position
        decor(folder, string.format("HijrLampStem_%d", index), Vector3.new(0.4, 3.2, 0.4), CFrame.new(lampBase + Vector3.new(0, 1.6, 0)), BRIGHT_GOLD, Enum.Material.Metal)
        local glass = decor(folder, string.format("HijrLamp_%d", index), Vector3.new(1.3, 1.8, 1.3), CFrame.new(lampBase + Vector3.new(0, 3.9, 0)), Color3.fromRGB(255, 236, 196), Enum.Material.Glass, 0.2)
        glowAtNight(glass)
        decor(folder, string.format("HijrLampCap_%d", index), Vector3.new(1.6, 0.4, 1.6), CFrame.new(lampBase + Vector3.new(0, 4.95, 0)), BRIGHT_GOLD, Enum.Material.Metal)
    end

    decor(folder, "HijrFloor", Vector3.new(depth - 2, 0.1, halfSpan * 2 - 4), kaaba * CFrame.new(faceX + depth * 0.45, 0.05, 0), Color3.fromRGB(236, 235, 230), Enum.Material.Marble)

    return (kaaba * CFrame.new(faceX + depth + 4, 0, 0)).Position
end

local function buildMaqamIbrahim(parent: Instance, kaaba: CFrame): Vector3
    local folder = BuildUtils.CreateFolder(parent, "MaqamIbrahim")
    -- About 11 m in front of the door face, slightly towards the north (Iraqi) corner.
    local base = (kaaba * CFrame.new(-8, 0, KAABA_WIDTH * 0.5 + 44)).Position

    vcyl(folder, "MaqamGraniteRing", 0.6, 5.2, base + Vector3.new(0, 0.3, 0), Color3.fromRGB(58, 58, 60), Enum.Material.Granite)
    vcyl(folder, "MaqamPedestal", 1.6, 4.3, base + Vector3.new(0, 1.2, 0), Color3.fromRGB(238, 236, 230), Enum.Material.Marble)
    vcyl(folder, "MaqamGoldBase", 0.9, 3.4, base + Vector3.new(0, 2.45, 0), BRIGHT_GOLD, Enum.Material.Metal)
    part(folder, "MaqamGlassCase", Vector3.new(7.4, 5.8, 5.8), CFrame.new(base + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(214, 232, 238), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.6 })
    decor(folder, "MaqamStone", Vector3.new(2.4, 2.0, 2.4), CFrame.new(base + Vector3.new(0, 3.9, 0)), Color3.fromRGB(176, 150, 112), Enum.Material.Slate)
    decor(folder, "MaqamFootprintsGold", Vector3.new(2.0, 0.2, 1.6), CFrame.new(base + Vector3.new(0, 4.95, 0)), Color3.fromRGB(196, 168, 108), Enum.Material.Metal)

    for bar = 1, 8 do
        local angle = (bar / 8) * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * 2.95, 6.6, math.sin(angle) * 2.95)
        decor(folder, string.format("MaqamLatticeBar_%d", bar), Vector3.new(0.3, 7.4, 0.3), CFrame.new(base + offset), BRIGHT_GOLD, Enum.Material.Metal)
    end
    for ring = 1, 3 do
        local y = 3.6 + ring * 2.2
        local r = part(folder, string.format("MaqamLatticeRing_%d", ring), Vector3.new(0.3, 6.2, 6.2), CFrame.new(base + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)), BRIGHT_GOLD, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder, Decor = true })
        r.Transparency = 0
    end

    local crystal = part(folder, "MaqamCrystalDome", Vector3.new(3.4, 3.0, 3.4), CFrame.new(base + Vector3.new(0, 5.6, 0)), Color3.fromRGB(226, 240, 246), Enum.Material.Glass, { Shape = Enum.PartType.Ball, Transparency = 0.45, Decor = true })
    crystal.CastShadow = false
    for side = 1, 6 do
        local a = side / 6 * math.pi * 2
        decor(folder, string.format("MaqamBasePlate_%d", side), Vector3.new(3.6, 1.0, 0.35), CFrame.new(base + Vector3.new(math.cos(a) * 3.55, 2.45, math.sin(a) * 3.55)) * CFrame.Angles(0, math.pi * 0.5 - a, 0), Color3.fromRGB(196, 160, 82), Enum.Material.Metal)
    end
    vcyl(folder, "MaqamDomeBand", 0.7, 3.25, base + Vector3.new(0, 10.6, 0), Color3.fromRGB(196, 160, 82), Enum.Material.Metal, true)
    ball(folder, "MaqamDome", 6.4, base + Vector3.new(0, 10.4, 0), BRIGHT_GOLD, Enum.Material.Metal, true)
    vcyl(folder, "MaqamDomeNeck", 1.2, 0.8, base + Vector3.new(0, 14.0, 0), BRIGHT_GOLD, Enum.Material.Metal, true)
    ball(folder, "MaqamFinialBall", 1.3, base + Vector3.new(0, 15.1, 0), BRIGHT_GOLD, Enum.Material.Metal, true)
    decor(folder, "MaqamFinialCrescentA", Vector3.new(0.25, 1.2, 0.25), CFrame.new(base + Vector3.new(-0.35, 16.2, 0)) * CFrame.Angles(0, 0, math.rad(25)), BRIGHT_GOLD, Enum.Material.Metal)
    decor(folder, "MaqamFinialCrescentB", Vector3.new(0.25, 1.2, 0.25), CFrame.new(base + Vector3.new(0.35, 16.2, 0)) * CFrame.Angles(0, 0, math.rad(-25)), BRIGHT_GOLD, Enum.Material.Metal)

    return base
end

---------------------------------------------------------------------------- mataf floor and expansion ring

local RING_SEGMENTS = 40
local RING_INNER = MasjidAlHaram.MatafOpenRadius
local RING_MID = 246
local RING_OUTER = 292
local RAMP_RADIUS = 268

-- Ramps between storeys: { segment where the ramp starts, storey it climbs to }.
-- Each ramp spans two segments; the slab above those two segments is left open.
local RAMPS = {
    { Segment = 6, Level = 2 }, { Segment = 16, Level = 2 }, { Segment = 26, Level = 2 }, { Segment = 36, Level = 2 },
    { Segment = 9, Level = 3 }, { Segment = 29, Level = 3 },
    { Segment = 12, Level = 4 }, { Segment = 32, Level = 4 },
}

-- Bay centres fall on the compass axes so the four main routes pass between columns.
local function segmentAngle(index: number): number
    return (index - 1) * (math.pi * 2 / RING_SEGMENTS)
end

local function buildMatafFloor(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, "Mataf")
    vcyl(folder, "MatafMarble", 1, 342, center + Vector3.new(0, FLOOR - 0.5, 0), MATAF_WHITE, Enum.Material.Marble)
end

local function buildMatafExpansion(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, "MatafExpansion")
    local step = math.pi * 2 / RING_SEGMENTS
    local openSlabs: { [string]: boolean } = {}

    for _, ramp in ipairs(RAMPS) do
        openSlabs[string.format("%d_%d", ramp.Level, ramp.Segment)] = true
        openSlabs[string.format("%d_%d", ramp.Level, ramp.Segment % RING_SEGMENTS + 1)] = true
    end

    for segment = 1, RING_SEGMENTS do
        local angle = segmentAngle(segment)
        local boundary = angle - step * 0.5
        local name = string.format("Seg%02d", segment)

        for level = 2, #LEVELS do
            local top = LEVELS[level]
            local innerWidth = chordWidth(RING_MID, step) + 1.2
            local outerWidth = chordWidth(RING_OUTER, step) + 1.2
            part(folder, string.format("%s_L%d_InnerSlab", name, level), Vector3.new(innerWidth, 2.4, RING_MID - RING_INNER + 1), radialFrame(center, angle, (RING_INNER + RING_MID) * 0.5 - 0.5, top - 1.2), GALLERY_CREAM, Enum.Material.Marble)
            if not openSlabs[string.format("%d_%d", level, segment)] then
                part(folder, string.format("%s_L%d_OuterSlab", name, level), Vector3.new(outerWidth, 2.4, RING_OUTER - RING_MID), radialFrame(center, angle, (RING_MID + RING_OUTER) * 0.5, top - 1.2), GALLERY_CREAM, Enum.Material.Marble)
            end

            -- Fascia with a gold line along the slab edge facing the Kaaba.
            local fasciaWidth = chordWidth(RING_INNER, step) + 0.4
            decor(folder, string.format("%s_L%d_Fascia", name, level), Vector3.new(fasciaWidth, 5.04, 1.4), radialFrame(center, angle, RING_INNER - 0.3, top - 2.48), Color3.fromRGB(238, 232, 218), Enum.Material.Marble)
            decor(folder, string.format("%s_L%d_GoldLine", name, level), Vector3.new(fasciaWidth, 0.35, 1.6), radialFrame(center, angle, RING_INNER - 0.4, top - 4.4), EMBROIDERY_GOLD, Enum.Material.Metal)

            -- Solid balustrade with a gold handrail, like the stone parapets of the real galleries.
            part(folder, string.format("%s_L%d_Parapet", name, level), Vector3.new(fasciaWidth, 3.4, 1), radialFrame(center, angle, RING_INNER + 0.4, top + 1.7), Color3.fromRGB(236, 230, 216), Enum.Material.Marble)
            decor(folder, string.format("%s_L%d_Handrail", name, level), Vector3.new(fasciaWidth, 0.4, 1.4), radialFrame(center, angle, RING_INNER + 0.4, top + 3.5), EMBROIDERY_GOLD, Enum.Material.Metal)
        end

        -- Columns and pointed arches facing the Kaaba on every storey, plus a back row.
        for level = 1, #LEVELS - 1 do
            local floorY = LEVELS[level]
            local ceiling = LEVELS[level + 1] - 2.4
            local columnH = ceiling - floorY
            local columnPos = center + Vector3.new(math.cos(boundary) * (RING_INNER + 1.5), floorY + columnH * 0.5, math.sin(boundary) * (RING_INNER + 1.5))
            vcyl(folder, string.format("%s_L%d_Column", name, level), columnH, 1.5, columnPos, COLUMN_WHITE, Enum.Material.Marble)
            decor(folder, string.format("%s_L%d_Capital", name, level), Vector3.new(3.8, 1.2, 3.8), CFrame.new(columnPos + Vector3.new(0, columnH * 0.5 - 1.6, 0)) * CFrame.Angles(0, -boundary, 0), EMBROIDERY_GOLD, Enum.Material.Metal)
            local backPos = center + Vector3.new(math.cos(boundary) * (RING_OUTER - 2), floorY + columnH * 0.5, math.sin(boundary) * (RING_OUTER - 2))
            part(folder, string.format("%s_L%d_BackPier", name, level), Vector3.new(3.4, columnH, 3.4), CFrame.new(backPos) * CFrame.Angles(0, -boundary, 0), GALLERY_CREAM, Enum.Material.Marble)

            local half = (chordWidth(RING_INNER + 1.5, step) - 3) * 0.5
            arcadeBay(folder, string.format("%s_L%d_Arch", name, level), radialFrame(center, angle, RING_INNER + 0.6, 0), half, floorY + columnH * 0.55, LEVELS[level + 1] - 4.8, 1.2, Color3.fromRGB(236, 229, 213), ARCH_STONE)
        end

        -- A brass-and-glass lantern hangs in each ground-floor arch.
        local lanternAt = center + Vector3.new(math.cos(angle) * (RING_INNER + 1.4), LEVELS[2] - 9.5, math.sin(angle) * (RING_INNER + 1.4))
        decor(folder, string.format("%s_LanternChain", name), Vector3.new(0.25, 3.2, 0.25), CFrame.new(lanternAt + Vector3.new(0, 2.6, 0)), BRIGHT_GOLD, Enum.Material.Metal)
        local lantern = decor(folder, string.format("%s_Lantern", name), Vector3.new(1.8, 2.6, 1.8), CFrame.new(lanternAt) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(255, 232, 186), Enum.Material.Glass, 0.15)
        glowAtNight(lantern)

        -- Roof parapet.
        decor(folder, string.format("%s_RoofParapet", name), Vector3.new(chordWidth(RING_OUTER, step) + 1, 3, 2), radialFrame(center, angle, RING_OUTER - 1, LEVELS[#LEVELS] + 1.5), GALLERY_CREAM, Enum.Material.Marble)

        -- Warm lights under each storey (every fourth bay) for the night view.
        if segment % 4 == 0 then
            for level = 1, #LEVELS - 1 do
                lightAnchor(folder, string.format("%s_L%d_Lamp", name, level), center + Vector3.new(math.cos(angle) * (RING_INNER + 8), LEVELS[level + 1] - 4, math.sin(angle) * (RING_INNER + 8)), LIGHT_WARM, 1.3, 46)
            end
        end
    end

    -- Ramps run along the outer lane, climbing anticlockwise over two segments.
    for index, ramp in ipairs(RAMPS) do
        local a0 = segmentAngle(ramp.Segment) - step * 0.5 + math.rad(0.6)
        local a1 = a0 + step * 2 - math.rad(1.2)
        local low = LEVELS[ramp.Level - 1]
        local high = LEVELS[ramp.Level]
        local p0 = center + Vector3.new(math.cos(a0) * RAMP_RADIUS, low, math.sin(a0) * RAMP_RADIUS)
        local p1 = center + Vector3.new(math.cos(a1) * RAMP_RADIUS, high, math.sin(a1) * RAMP_RADIUS)
        local length = (p1 - p0).Magnitude
        local frame = CFrame.lookAt((p0 + p1) * 0.5, p1)
        part(folder, string.format("Ramp_%d_ToLevel%d", index, ramp.Level - 1), Vector3.new(30, 1.2, length + 2), frame * CFrame.new(0, -0.6, 0), Color3.fromRGB(226, 220, 206), Enum.Material.Marble)
        decor(folder, string.format("Ramp_%d_RailA", index), Vector3.new(0.4, 0.4, length), frame * CFrame.new(-15, 3.2, 0), EMBROIDERY_GOLD, Enum.Material.Metal)
        decor(folder, string.format("Ramp_%d_RailB", index), Vector3.new(0.4, 0.4, length), frame * CFrame.new(15, 3.2, 0), EMBROIDERY_GOLD, Enum.Material.Metal)
    end
end

---------------------------------------------------------------------------- Ottoman riwaq

local function buildOttomanRiwaq(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, "OttomanRiwaq")
    local inner, outer = RING_OUTER, 336
    local step = math.pi * 2 / RING_SEGMENTS
    local roofY = 26

    for segment = 1, RING_SEGMENTS do
        local angle = segmentAngle(segment)
        local boundary = angle - step * 0.5
        local name = string.format("Riwaq%02d", segment)
        part(folder, name .. "_Roof", Vector3.new(chordWidth(outer, step) + 1, 2, outer - inner), radialFrame(center, angle, (inner + outer) * 0.5, roofY - 1), OTTOMAN_STONE, Enum.Material.Limestone)
        ball(folder, name .. "_Dome", 15, center + Vector3.new(math.cos(angle) * (inner + outer) * 0.5, roofY - 1.5, math.sin(angle) * (inner + outer) * 0.5), OTTOMAN_DOME, Enum.Material.Plaster, true)
        decor(folder, name .. "_Finial", Vector3.new(0.6, 3, 0.6), CFrame.new(center + Vector3.new(math.cos(angle) * (inner + outer) * 0.5, roofY + 7.2, math.sin(angle) * (inner + outer) * 0.5)), BRIGHT_GOLD, Enum.Material.Metal)
        local pierPos = center + Vector3.new(math.cos(boundary) * (outer - 2), FLOOR + (roofY - 2 - FLOOR) * 0.5, math.sin(boundary) * (outer - 2))
        part(folder, name .. "_Pier", Vector3.new(4, roofY - 2 - FLOOR, 4), CFrame.new(pierPos) * CFrame.Angles(0, -boundary, 0), OTTOMAN_STONE, Enum.Material.Limestone)
        arcadeBay(folder, name .. "_Arch", radialFrame(center, angle, outer - 1, 0), (chordWidth(outer - 2, step) - 4) * 0.5, FLOOR + 9, roofY - 2, 1.2, OTTOMAN_STONE, Color3.fromRGB(150, 140, 124))
    end
end

---------------------------------------------------------------------------- galleries, mas'a, wings

type WingConfig = {
    Name: string,
    Angle: number, -- outward direction of the side
    InnerDistance: number,
    OuterDistance: number,
    From: number, -- extent along the side (local X)
    To: number,
    Levels: { number },
    BaySpacing: number,
    InnerArches: boolean,
    InteriorColumns: boolean,
    DoorGap: number?, -- half-width of a gate opening centred on local x = 0 of the outer facade
}

-- One straight multi-storey gallery block: arcade towards the Kaaba, piered facade outside,
-- floor slabs and a roof parapet. Piers leave gaps so players can walk through at ground level.
local function buildWing(parent: Instance, center: Vector3, config: WingConfig)
    local folder = BuildUtils.CreateFolder(parent, config.Name)
    local depth = config.OuterDistance - config.InnerDistance
    local length = config.To - config.From
    local mid = (config.From + config.To) * 0.5
    local base = radialFrame(center, config.Angle, (config.InnerDistance + config.OuterDistance) * 0.5, 0)
    local levels = config.Levels
    local bays = math.max(1, math.floor(length / config.BaySpacing + 0.5))
    local bayW = length / bays
    -- Keep a column from landing on the centre line, where the gates and main routes pass.
    local nearestBoundary = config.From + math.floor((0 - config.From) / bayW + 0.5) * bayW
    if math.abs(nearestBoundary) < 6 then
        bays += 1
        bayW = length / bays
    end

    for level = 2, #levels do
        part(folder, string.format("L%d_Slab", level), Vector3.new(length, 2.6, depth), base * CFrame.new(mid, levels[level] - 1.3, 0), GALLERY_CREAM, Enum.Material.Marble)
    end
    local roofY = levels[#levels]
    decor(folder, "RoofParapetInner", Vector3.new(length, 3.2, 2), base * CFrame.new(mid, roofY + 1.6, -depth * 0.5 + 1), GALLERY_CREAM, Enum.Material.Marble)
    decor(folder, "RoofParapetOuter", Vector3.new(length, 4.2, 2), base * CFrame.new(mid, roofY + 2.1, depth * 0.5 - 1), GALLERY_CREAM, Enum.Material.Marble)
    decor(folder, "RoofGoldTrim", Vector3.new(length, 0.5, 2.3), base * CFrame.new(mid, roofY + 4.3, depth * 0.5 - 1), EMBROIDERY_GOLD, Enum.Material.Metal)

    for bay = 0, bays do
        local x = config.From + bay * bayW
        for level = 1, #levels - 1 do
            local floorY = levels[level]
            local columnH = levels[level + 1] - 2.6 - floorY
            local y = floorY + columnH * 0.5

            -- Inner arcade (towards the mosque centre).
            if config.InnerArches then
                vcyl(folder, string.format("InnerColumn_%d_L%d", bay, level), columnH, 1.7, (base * CFrame.new(x, y, -depth * 0.5 + 2)).Position, COLUMN_WHITE, Enum.Material.Marble)
            else
                part(folder, string.format("InnerPier_%d_L%d", bay, level), Vector3.new(5, columnH, 5), base * CFrame.new(x, y, -depth * 0.5 + 2.5), GALLERY_CREAM, Enum.Material.Marble)
            end
            -- Outer facade piers, left out where a gate portal opens the facade.
            local inDoorway = config.DoorGap ~= nil and level == 1 and math.abs(x) < (config.DoorGap :: number)
            if not inDoorway then part(folder, string.format("OuterPier_%d_L%d", bay, level), Vector3.new(9, columnH, 6), base * CFrame.new(x, y, depth * 0.5 - 3), GALLERY_CREAM, Enum.Material.Marble) end

            if bay < bays then
                local bayCenter = x + bayW * 0.5
                if config.InnerArches then
                    arcadeBay(folder, string.format("InnerArch_%d_L%d", bay, level), base * CFrame.new(bayCenter, 0, -depth * 0.5 + 1.6), (bayW - 3.4) * 0.5, floorY + columnH * 0.55, floorY + columnH, 1.2, Color3.fromRGB(232, 224, 207), ARCH_STONE)
                end
                local doorway = config.DoorGap ~= nil and level == 1 and math.abs(bayCenter) < (config.DoorGap :: number)
                if level == 1 and not doorway then
                    -- Arched doorways along the street front.
                    arcadeBay(folder, string.format("Doorway_%d", bay), base * CFrame.new(bayCenter, 0, depth * 0.5 - 1.6), (bayW - 9) * 0.5, floorY + columnH * 0.5, floorY + columnH, 1.4, GALLERY_CREAM, ARCH_STONE)
                elseif level > 1 then
                    -- Solid marble wall with a tall arched window.
                    decor(folder, string.format("Wall_%d_L%d", bay, level), Vector3.new(bayW - 8.6, columnH, 1.6), base * CFrame.new(bayCenter, floorY + columnH * 0.5, depth * 0.5 - 2), GALLERY_CREAM, Enum.Material.Marble)
                    decor(folder, string.format("Window_%d_L%d", bay, level), Vector3.new(math.max(6, bayW - 24), columnH * 0.55, 0.5), base * CFrame.new(bayCenter, floorY + columnH * 0.44, depth * 0.5 - 1), WINDOW_GLASS, Enum.Material.Glass)
                    pointedArch(folder, string.format("WindowArch_%d_L%d", bay, level), base * CFrame.new(bayCenter, floorY + columnH * 0.715, depth * 0.5 - 0.9), math.max(6, bayW - 24), columnH * 0.14, 0.9, 0.8, ARCH_STONE)
                end
            end
        end

        -- Interior columns so deep blocks do not look hollow.
        if config.InteriorColumns and bay % 2 == 0 and depth > 100 then
            local rows = math.floor(depth / 56)
            for row = 1, rows do
                local z = -depth * 0.5 + row * depth / (rows + 1)
                local h = levels[2] - 2.6 - levels[1]
                vcyl(folder, string.format("HallColumn_%d_%d", bay, row), h, 2, (base * CFrame.new(x, levels[1] + h * 0.5, z)).Position, COLUMN_WHITE, Enum.Material.Marble)
            end
        end
    end

    -- Storey bands on the outside face.
    for level = 2, #levels do
        decor(folder, string.format("FacadeBand_L%d", level), Vector3.new(length + 1, 3.08, 1), base * CFrame.new(mid, levels[level] - 1.46, depth * 0.5 + 0.2), Color3.fromRGB(222, 212, 192), Enum.Material.Marble)
        decor(folder, string.format("FacadeGold_L%d", level), Vector3.new(length + 1, 0.4, 1.2), base * CFrame.new(mid, levels[level] - 3.2, depth * 0.5 + 0.25), EMBROIDERY_GOLD, Enum.Material.Metal)
    end

    return base
end

local function buildMasa(parent: Instance, center: Vector3): (Vector3, Vector3)
    local folder = BuildUtils.CreateFolder(parent, "Masa")
    local x0, x1 = -430, -340
    local z0, z1 = -470, 470
    local midX = (x0 + x1) * 0.5
    local width = x1 - x0
    local length = z1 - z0
    local levels = LEVELS

    for level = 2, #levels do
        part(folder, string.format("MasaL%d_Slab", level), Vector3.new(width, 2.6, length), CFrame.new(center + Vector3.new(midX, levels[level] - 1.3, 0)), GALLERY_CREAM, Enum.Material.Marble)
    end
    decor(folder, "MasaRoofParapetEast", Vector3.new(2, 4, length), CFrame.new(center + Vector3.new(x0 + 1, levels[#levels] + 2, 0)), GALLERY_CREAM, Enum.Material.Marble)
    decor(folder, "MasaRoofParapetWest", Vector3.new(2, 3, length), CFrame.new(center + Vector3.new(x1 - 1, levels[#levels] + 1.5, 0)), GALLERY_CREAM, Enum.Material.Marble)

    local bays = 25 -- odd, so the middle of the mas'a (Bab as-Salam) is between columns
    local bayL = length / bays
    for bay = 0, bays do
        local z = z0 + bay * bayL
        for level = 1, #levels - 1 do
            local floorY = levels[level]
            local h = levels[level + 1] - 2.6 - floorY
            vcyl(folder, string.format("MasaInnerColumn_%d_L%d", bay, level), h, 1.6, center + Vector3.new(x1 - 2, floorY + h * 0.5, z), COLUMN_WHITE, Enum.Material.Marble)
            if not (level == 1 and math.abs(z) < 30) then part(folder, string.format("MasaOuterPier_%d_L%d", bay, level), Vector3.new(6, h, 8), CFrame.new(center + Vector3.new(x0 + 3, floorY + h * 0.5, z)), GALLERY_CREAM, Enum.Material.Marble) end
            if bay < bays then
                local frame = CFrame.new(center + Vector3.new(x1 - 1.4, 0, z + bayL * 0.5)) * CFrame.Angles(0, math.rad(90), 0)
                arcadeBay(folder, string.format("MasaArch_%d_L%d", bay, level), frame, (bayL - 3.2) * 0.5, floorY + h * 0.55, floorY + h, 1.2, Color3.fromRGB(232, 224, 207), ARCH_STONE)
                if level > 1 then
                    decor(folder, string.format("MasaWall_%d_L%d", bay, level), Vector3.new(1.6, h, bayL - 5.6), CFrame.new(center + Vector3.new(x0 + 2, floorY + h * 0.5, z + bayL * 0.5)), GALLERY_CREAM, Enum.Material.Marble)
                    decor(folder, string.format("MasaWindow_%d_L%d", bay, level), Vector3.new(0.5, h * 0.55, bayL - 16), CFrame.new(center + Vector3.new(x0 + 1, floorY + h * 0.44, z + bayL * 0.5)), WINDOW_GLASS, Enum.Material.Glass)
                end
            end
        end
        if bay % 2 == 1 then
            lightAnchor(folder, string.format("MasaLamp_%d", bay), center + Vector3.new(midX, levels[2] - 5, z), LIGHT_WARM, 1.2, 50)
        end
    end

    -- Lanes: a low marble divider down the middle (one way to Marwa, the other back to Safa).
    -- Four runs leave a crossing in the middle, in line with Bab as-Salam.
    for index = 1, 4 do
        local zc = z0 + 90 + (index - 1) * ((length - 180) / 3)
        part(folder, string.format("MasaLaneDivider_%d", index), Vector3.new(3, 2.6, (length - 260) / 4), CFrame.new(center + Vector3.new(midX, FLOOR + 1.3, zc)), Color3.fromRGB(214, 206, 190), Enum.Material.Marble)
    end

    -- The green-lit stretch between the two green markers, nearer Safa.
    local greenFrom, greenTo = z0 + 150, z0 + 250
    for index = 0, 5 do
        local z = greenFrom + index * (greenTo - greenFrom) / 5
        local strip = decor(folder, string.format("SaiGreenLight_%d", index), Vector3.new(width - 8, 0.5, 2.2), CFrame.new(center + Vector3.new(midX, levels[2] - 2.9, z)), SAI_GREEN, Enum.Material.SmoothPlastic)
        glowAtNight(strip)
    end
    for _, z in ipairs({ greenFrom, greenTo }) do
        for _, x in ipairs({ x0 + 6.5, x1 - 4.5 }) do
            local marker = decor(folder, string.format("SaiGreenMarker_%d_%d", z, x), Vector3.new(1.2, 10, 3), CFrame.new(center + Vector3.new(x, FLOOR + 14, z)), SAI_GREEN, Enum.Material.SmoothPlastic)
            glowAtNight(marker)
        end
        lightAnchor(folder, string.format("SaiGreenGlow_%d", z), center + Vector3.new(midX, levels[2] - 6, z), SAI_GREEN, 1.6, 40)
    end

    -- Safa (south end) and Marwa (north end): the remaining rock of each hill behind a glass rail.
    local function hill(name: string, z: number, direction: number): Vector3
        local hillFolder = BuildUtils.CreateFolder(folder, name)
        local rock = Color3.fromRGB(132, 116, 98)
        local hc = center + Vector3.new(midX, FLOOR, z)
        for index, boulder in ipairs({
            { Offset = Vector3.new(0, 4, 0), Size = Vector3.new(30, 9, 18), Yaw = 8, Tilt = 6 },
            { Offset = Vector3.new(-9, 7, direction * 4), Size = Vector3.new(14, 9, 12), Yaw = -20, Tilt = -10 },
            { Offset = Vector3.new(10, 6, direction * 2), Size = Vector3.new(12, 8, 13), Yaw = 34, Tilt = 12 },
            { Offset = Vector3.new(2, 10, direction * 6), Size = Vector3.new(10, 6, 9), Yaw = 12, Tilt = 18 },
        }) do
            part(hillFolder, string.format("%sRock_%d", name, index), boulder.Size, CFrame.new(hc + boulder.Offset) * CFrame.Angles(math.rad(boulder.Tilt), math.rad(boulder.Yaw), math.rad(boulder.Tilt * 0.5)), rock, Enum.Material.Rock)
        end
        local rail = part(hillFolder, name .. "GlassRail", Vector3.new(44, 4, 0.5), CFrame.new(hc + Vector3.new(0, 2, -direction * 14)), Color3.fromRGB(196, 214, 222), Enum.Material.Glass, { Transparency = 0.55 })
        rail.CastShadow = false
        decor(hillFolder, name .. "RailGold", Vector3.new(44, 0.4, 0.7), CFrame.new(hc + Vector3.new(0, 4.1, -direction * 14)), EMBROIDERY_GOLD, Enum.Material.Metal)
        -- Dome over each hill on the mas'a roof.
        local roof = center + Vector3.new(midX, levels[#levels], z)
        vcyl(hillFolder, name .. "DomeDrum", 6, 22, roof + Vector3.new(0, 3, 0), GALLERY_CREAM, Enum.Material.Marble, true)
        ball(hillFolder, name .. "Dome", 40, roof + Vector3.new(0, 5, 0), OTTOMAN_DOME, Enum.Material.Plaster, true)
        decor(hillFolder, name .. "DomeFinial", Vector3.new(1, 6, 1), CFrame.new(roof + Vector3.new(0, 27, 0)), BRIGHT_GOLD, Enum.Material.Metal)
        lightAnchor(hillFolder, name .. "Glow", hc + Vector3.new(0, 18, 0), LIGHT_WARM, 1.6, 40)
        return hc
    end

    local safa = hill("Safa", z0 + 18, -1)
    local marwa = hill("Marwa", z1 - 18, 1)

    return safa, marwa
end

---------------------------------------------------------------------------- minarets and gates

-- The Haram minaret profile: square base, three tapering shafts with balconies, an arcaded
-- lantern, a pointed cap and a gold crescent finial.
local function buildMinaret(parent: Instance, name: string, position: Vector3, height: number)
    local folder = BuildUtils.CreateFolder(parent, name)
    local base = position
    local h = height
    local plinthTop = h * 0.2

    part(folder, "Plinth", Vector3.new(20, plinthTop, 20), CFrame.new(base + Vector3.new(0, plinthTop * 0.5, 0)), MINARET_WHITE, Enum.Material.Marble)
    decor(folder, "PlinthBand", Vector3.new(20.6, 1.4, 20.6), CFrame.new(base + Vector3.new(0, plinthTop - 1, 0)), EMBROIDERY_GOLD, Enum.Material.Metal)
    decor(folder, "PlinthCap", Vector3.new(21.8, 2.4, 21.8), CFrame.new(base + Vector3.new(0, plinthTop + 1, 0)), MINARET_WHITE, Enum.Material.Marble)

    local sections = {
        { From = 0.2, To = 0.46, Radius = 6.6, Balcony = 9.4 },
        { From = 0.46, To = 0.66, Radius = 5.4, Balcony = 7.9 },
        { From = 0.66, To = 0.8, Radius = 4.5, Balcony = 6.6 },
    }
    for index, section in ipairs(sections) do
        local y0, y1 = h * section.From + 2, h * section.To
        vcyl(folder, string.format("Shaft_%d", index), y1 - y0, section.Radius, base + Vector3.new(0, (y0 + y1) * 0.5, 0), MINARET_WHITE, Enum.Material.Marble)
        vcyl(folder, string.format("Balcony_%d", index), 2.2, section.Balcony, base + Vector3.new(0, y1 + 1.1, 0), MINARET_WHITE, Enum.Material.Marble, true)
        vcyl(folder, string.format("BalconyGold_%d", index), 0.5, section.Balcony + 0.2, base + Vector3.new(0, y1 + 2.4, 0), EMBROIDERY_GOLD, Enum.Material.Metal, true)
        decor(folder, string.format("ShaftInlay_%d", index), Vector3.new(section.Radius * 2.06, (y1 - y0) * 0.5, 0.6), CFrame.new(base + Vector3.new(0, (y0 + y1) * 0.5, 0)) * CFrame.Angles(0, math.rad(45 * index), 0), Color3.fromRGB(214, 206, 188), Enum.Material.Marble)
    end

    -- Lantern with green night glow, then the cap and crescent.
    local lanternY0, lanternY1 = h * 0.8 + 2.4, h * 0.88
    vcyl(folder, "Lantern", lanternY1 - lanternY0, 3.9, base + Vector3.new(0, (lanternY0 + lanternY1) * 0.5, 0), Color3.fromRGB(206, 200, 186), Enum.Material.Marble, true)
    local glow = vcyl(folder, "LanternGlow", (lanternY1 - lanternY0) * 0.55, 4.05, base + Vector3.new(0, (lanternY0 + lanternY1) * 0.5, 0), Color3.fromRGB(70, 196, 120), Enum.Material.Glass, true)
    glow.Transparency = 0.25
    glowAtNight(glow)
    local capBase = lanternY1
    for index, tier in ipairs({ { 3.8, 0.035 }, { 2.9, 0.03 }, { 1.9, 0.025 }, { 1.0, 0.02 } }) do
        local tierH = h * tier[2]
        vcyl(folder, string.format("Cap_%d", index), tierH, tier[1], base + Vector3.new(0, capBase + tierH * 0.5, 0), MINARET_WHITE, Enum.Material.Marble, true)
        capBase += tierH
    end
    ball(folder, "FinialBall", 2.4, base + Vector3.new(0, capBase + 1.1, 0), BRIGHT_GOLD, Enum.Material.Metal, true)
    decor(folder, "FinialRod", Vector3.new(0.5, 4, 0.5), CFrame.new(base + Vector3.new(0, capBase + 3.6, 0)), BRIGHT_GOLD, Enum.Material.Metal)
    for index = 0, 4 do
        local a = math.rad(-70 + index * 35)
        decor(folder, string.format("Crescent_%d", index), Vector3.new(0.5, 1.4, 0.5), CFrame.new(base + Vector3.new(math.sin(a) * 1.7, capBase + 7.4 + math.cos(a) * 1.7, 0)) * CFrame.Angles(0, 0, -a), BRIGHT_GOLD, Enum.Material.Metal)
    end
end

local function gateLabel(host: BasePart, title: string, subtitle: string)
    local gui = newSurfaceGui(host, Enum.NormalId.Front, 18)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.fromScale(1, 0.62)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = Color3.fromRGB(58, 44, 18)
    titleLabel.Parent = gui
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromScale(0.05, 0.62)
    subtitleLabel.Size = UDim2.fromScale(0.9, 0.34)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = subtitle
    subtitleLabel.TextScaled = true
    subtitleLabel.TextColor3 = Color3.fromRGB(70, 56, 30)
    subtitleLabel.Parent = gui
end

-- A grand gate portal. `frame` sits on the facade at ground level with local +Z pointing out.
local function buildGate(parent: Instance, name: string, frame: CFrame, width: number, height: number, title: string, subtitle: string)
    local folder = BuildUtils.CreateFolder(parent, name)
    local pylonW = 20
    local half = width * 0.5

    for side = -1, 1, 2 do
        part(folder, string.format("Pylon_%d", side), Vector3.new(pylonW, height, 22), frame * CFrame.new(side * (half + pylonW * 0.5), FLOOR + height * 0.5, 4), GALLERY_CREAM, Enum.Material.Marble)
        decor(folder, string.format("PylonInlay_%d", side), Vector3.new(pylonW - 6, height - 18, 0.6), frame * CFrame.new(side * (half + pylonW * 0.5), FLOOR + height * 0.5 - 3, 15.2), Color3.fromRGB(214, 202, 178), Enum.Material.Marble)
    end
    part(folder, "Lintel", Vector3.new(width + pylonW * 2 + 2, 16, 24), frame * CFrame.new(0, FLOOR + height + 8, 4), GALLERY_CREAM, Enum.Material.Marble)
    decor(folder, "LintelGold", Vector3.new(width + pylonW * 2 + 2.4, 0.8, 24.4), frame * CFrame.new(0, FLOOR + height + 0.6, 4), EMBROIDERY_GOLD, Enum.Material.Metal)
    local plate = decor(folder, "NamePlate", Vector3.new(width * 0.8, 9, 0.6), frame * CFrame.new(0, FLOOR + height + 8, 16.4), Color3.fromRGB(226, 190, 104), Enum.Material.Metal)
    -- Face the label outward: the plate's Front must look along +Z of the gate frame.
    plate.CFrame = frame * CFrame.new(0, FLOOR + height + 8, 16.4) * CFrame.Angles(0, math.pi, 0)
    gateLabel(plate, title, subtitle)

    local openings = 3
    local openingW = width / openings
    for index = 1, openings do
        local x = -half + (index - 0.5) * openingW
        pointedArch(folder, string.format("PortalArch_%d", index), frame * CFrame.new(x, FLOOR + height * 0.62, 15.6) * CFrame.Angles(0, math.pi, 0), openingW - 3, height * 0.3, 1.8, 2, BRIGHT_GOLD)
        if index > 1 then
            vcyl(folder, string.format("PortalColumn_%d", index), height - 1, 1.6, (frame * CFrame.new(x - openingW * 0.5, FLOOR + (height - 1) * 0.5, 14)).Position, COLUMN_WHITE, Enum.Material.Marble)
        end
    end

    for index = -1, 1, 2 do
        ball(folder, string.format("LintelDome_%d", index), 12, (frame * CFrame.new(index * (half * 0.55), FLOOR + height + 16, 4)).Position, OTTOMAN_DOME, Enum.Material.Plaster, true)
    end

    local lamp = lightAnchor(folder, "GateGlow", (frame * CFrame.new(0, FLOOR + height * 0.7, 24)).Position, LIGHT_WARM, 1.5, 50)
    lamp.Name = "GateGlow"
end

---------------------------------------------------------------------------- Abraj Al-Bait

local function buildSkylineTower(parent: Instance, name: string, position: Vector3, footprint: Vector2, height: number)
    local folder = BuildUtils.CreateFolder(parent, name)
    local podium = 60
    part(folder, "Shaft", Vector3.new(footprint.X, height, footprint.Y), CFrame.new(position + Vector3.new(0, podium + height * 0.5, 0)), Color3.fromRGB(222, 214, 198), Enum.Material.Concrete)
    for side = -1, 1, 2 do
        decor(folder, string.format("GlassZ_%d", side), Vector3.new(footprint.X * 0.5, height - 20, 0.6), CFrame.new(position + Vector3.new(0, podium + height * 0.5, side * (footprint.Y * 0.5 + 0.2))), WINDOW_GLASS, Enum.Material.Glass)
        decor(folder, string.format("GlassX_%d", side), Vector3.new(0.6, height - 20, footprint.Y * 0.45), CFrame.new(position + Vector3.new(side * (footprint.X * 0.5 + 0.2), podium + height * 0.5, 0)), WINDOW_GLASS, Enum.Material.Glass)
    end
    for band = 1, 4 do
        decor(folder, string.format("Band_%d", band), Vector3.new(footprint.X + 1.4, 2, footprint.Y + 1.4), CFrame.new(position + Vector3.new(0, podium + height * band / 5, 0)), Color3.fromRGB(236, 230, 216), Enum.Material.Concrete)
    end
    part(folder, "Crown", Vector3.new(footprint.X - 8, 14, footprint.Y - 8), CFrame.new(position + Vector3.new(0, podium + height + 7, 0)), Color3.fromRGB(232, 226, 212), Enum.Material.Concrete)
    ball(folder, "CrownDome", footprint.X * 0.36, position + Vector3.new(0, podium + height + 14, 0), Color3.fromRGB(196, 170, 104), Enum.Material.Metal, true)
end

local function buildClockFace(parent: Instance, name: string, faceFrame: CFrame, diameter: number)
    local folder = BuildUtils.CreateFolder(parent, name)
    local surround = diameter + 10

    decor(folder, "Surround", Vector3.new(surround, surround, 1.6), faceFrame * CFrame.new(0, 0, 0.4), CLOCK_GREEN, Enum.Material.SmoothPlastic)
    decor(folder, "SurroundGold", Vector3.new(surround + 2, surround + 2, 1.2), faceFrame * CFrame.new(0, 0, 0.9), EMBROIDERY_GOLD, Enum.Material.Metal)
    local face = part(folder, "Dial", Vector3.new(1, diameter, diameter), faceFrame * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(246, 244, 236), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Decor = true })
    glowAtNight(face)
    local ring = part(folder, "DialRing", Vector3.new(0.8, diameter + 3, diameter + 3), faceFrame * CFrame.new(0, 0, -0.3) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(60, 170, 110), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Decor = true })
    glowAtNight(ring)

    for tick = 1, 12 do
        local angle = tick / 12 * math.pi * 2
        local r = diameter * 0.42
        decor(folder, string.format("Marker_%d", tick), Vector3.new(1.6, (tick % 3 == 0) and 6 or 3.6, 0.6), faceFrame * CFrame.Angles(0, 0, angle) * CFrame.new(0, r, -1.3), Color3.fromRGB(34, 34, 34), Enum.Material.SmoothPlastic)
    end

    for _, hand in ipairs({ { Name = "HourHand", Length = diameter * 0.27, Width = 2.2, Depth = -1.6 }, { Name = "MinuteHand", Length = diameter * 0.4, Width = 1.4, Depth = -2.0 } }) do
        local handPart = decor(folder, hand.Name, Vector3.new(hand.Width, hand.Length, 0.5), faceFrame * CFrame.new(0, hand.Length * 0.4, hand.Depth), Color3.fromRGB(28, 28, 28), Enum.Material.Metal)
        handPart:SetAttribute("Pivot", faceFrame * CFrame.new(0, 0, hand.Depth))
        handPart:SetAttribute("HandType", if hand.Name == "HourHand" then "Hour" else "Minute")
        handPart:SetAttribute("Offset", hand.Length * 0.4)
        CollectionService:AddTag(handPart, MasjidAlHaram.ClockHandTag)
    end
    ball(folder, "Pin", 3, (faceFrame * CFrame.new(0, 0, -2.4)).Position, EMBROIDERY_GOLD, Enum.Material.Metal, true)
end

local function buildAbrajAlBait(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, "AbrajAlBait")
    local site = center + Vector3.new(0, 0, -1000)
    local cream = Color3.fromRGB(226, 218, 200)

    -- Podium (the shopping and hotel base), stepping up in two terraces.
    part(folder, "Podium", Vector3.new(560, 44, 280), CFrame.new(site + Vector3.new(0, 22, 0)), cream, Enum.Material.Concrete)
    part(folder, "PodiumUpper", Vector3.new(470, 18, 230), CFrame.new(site + Vector3.new(0, 53, -10)), Color3.fromRGB(232, 225, 210), Enum.Material.Concrete)
    decor(folder, "PodiumGlass", Vector3.new(520, 22, 0.8), CFrame.new(site + Vector3.new(0, 24, 140.5)), WINDOW_GLASS, Enum.Material.Glass)
    decor(folder, "PodiumGoldBand", Vector3.new(562, 1.2, 282), CFrame.new(site + Vector3.new(0, 44.2, 0)), EMBROIDERY_GOLD, Enum.Material.Metal)

    -- The six surrounding towers.
    for index, tower in ipairs({
        { Offset = Vector3.new(-205, 0, 40), Height = 300 },
        { Offset = Vector3.new(205, 0, 40), Height = 300 },
        { Offset = Vector3.new(-200, 0, -80), Height = 260 },
        { Offset = Vector3.new(200, 0, -80), Height = 260 },
        { Offset = Vector3.new(-95, 0, -110), Height = 230 },
        { Offset = Vector3.new(95, 0, -110), Height = 230 },
    }) do
        buildSkylineTower(folder, string.format("Tower_%d", index), site + tower.Offset, Vector2.new(78, 62), tower.Height)
    end

    -- Central clock tower: hotel shaft, setbacks, the clock block, crown, lantern and spire.
    local shaftTop = 440
    part(folder, "ClockTowerShaft", Vector3.new(104, shaftTop - 60, 104), CFrame.new(site + Vector3.new(0, 60 + (shaftTop - 60) * 0.5, 0)), Color3.fromRGB(224, 216, 200), Enum.Material.Concrete)
    for side = -1, 1, 2 do
        decor(folder, string.format("ClockTowerGlassZ_%d", side), Vector3.new(52, shaftTop - 90, 0.8), CFrame.new(site + Vector3.new(0, 60 + (shaftTop - 60) * 0.5, side * 52.4)), WINDOW_GLASS, Enum.Material.Glass)
        decor(folder, string.format("ClockTowerGlassX_%d", side), Vector3.new(0.8, shaftTop - 90, 52), CFrame.new(site + Vector3.new(side * 52.4, 60 + (shaftTop - 60) * 0.5, 0)), WINDOW_GLASS, Enum.Material.Glass)
        part(folder, string.format("ClockTowerWing_%d", side), Vector3.new(34, 300, 74), CFrame.new(site + Vector3.new(side * 69, 60 + 150, 0)), Color3.fromRGB(218, 210, 194), Enum.Material.Concrete)
    end
    for band = 1, 6 do
        decor(folder, string.format("ClockTowerBand_%d", band), Vector3.new(106, 2, 106), CFrame.new(site + Vector3.new(0, 60 + band * 60, 0)), Color3.fromRGB(238, 232, 218), Enum.Material.Concrete)
    end

    local clockY0, clockY1 = shaftTop, shaftTop + 96
    part(folder, "ClockBlock", Vector3.new(112, clockY1 - clockY0, 112), CFrame.new(site + Vector3.new(0, (clockY0 + clockY1) * 0.5, 0)), Color3.fromRGB(232, 226, 212), Enum.Material.Concrete)
    local clockMid = (clockY0 + clockY1) * 0.5 - 4
    local faceDiameter = 66
    for _, side in ipairs({
        { Name = "ClockFaceNorth", Normal = Vector3.new(0, 0, 1) },
        { Name = "ClockFaceSouth", Normal = Vector3.new(0, 0, -1) },
        { Name = "ClockFaceEast", Normal = Vector3.new(-1, 0, 0) },
        { Name = "ClockFaceWest", Normal = Vector3.new(1, 0, 0) },
    }) do
        local p = site + Vector3.new(0, clockMid, 0) + side.Normal * 57.6
        buildClockFace(folder, side.Name, CFrame.lookAt(p, p + side.Normal), faceDiameter)
    end
    -- "Allahu Akbar" band in gold over the clock faces.
    local bandPart = decor(folder, "TakbirBand", Vector3.new(96, 9, 0.6), CFrame.lookAt(site + Vector3.new(0, clockY1 - 5, 57), site + Vector3.new(0, clockY1 - 5, 70)), CLOCK_GREEN, Enum.Material.SmoothPlastic)
    local bandGui = newSurfaceGui(bandPart, Enum.NormalId.Front, 10)
    local takbir = Instance.new("TextLabel")
    takbir.BackgroundTransparency = 1
    takbir.Size = UDim2.fromScale(1, 1)
    takbir.Font = Enum.Font.GothamBold
    takbir.Text = "ALLAHU AKBAR"
    takbir.TextScaled = true
    takbir.TextColor3 = BRIGHT_GOLD
    takbir.Parent = bandGui

    -- Crown, green-lit lantern and gold spire with the crescent.
    part(folder, "Crown", Vector3.new(92, 34, 92), CFrame.new(site + Vector3.new(0, clockY1 + 17, 0)), Color3.fromRGB(236, 230, 216), Enum.Material.Concrete)
    decor(folder, "CrownGold", Vector3.new(94, 3, 94), CFrame.new(site + Vector3.new(0, clockY1 + 35, 0)), EMBROIDERY_GOLD, Enum.Material.Metal)
    local lantern = part(folder, "Lantern", Vector3.new(50, 40, 50), CFrame.new(site + Vector3.new(0, clockY1 + 56, 0)), Color3.fromRGB(70, 180, 120), Enum.Material.Glass, { Transparency = 0.15 })
    glowAtNight(lantern)
    decor(folder, "LanternCap", Vector3.new(56, 4, 56), CFrame.new(site + Vector3.new(0, clockY1 + 78, 0)), EMBROIDERY_GOLD, Enum.Material.Metal)
    vcyl(folder, "SpireBase", 30, 12, site + Vector3.new(0, clockY1 + 95, 0), Color3.fromRGB(226, 220, 206), Enum.Material.Concrete, true)
    vcyl(folder, "Spire", 70, 4.2, site + Vector3.new(0, clockY1 + 145, 0), BRIGHT_GOLD, Enum.Material.Metal, true)
    ball(folder, "SpireBall", 11, site + Vector3.new(0, clockY1 + 182, 0), BRIGHT_GOLD, Enum.Material.Metal, true)
    for index = 0, 6 do
        local a = math.rad(-75 + index * 25)
        decor(folder, string.format("Crescent_%d", index), Vector3.new(2.4, 6.5, 2.4), CFrame.new(site + Vector3.new(math.sin(a) * 9, clockY1 + 199 + math.cos(a) * 9, 0)) * CFrame.Angles(0, 0, -a), BRIGHT_GOLD, Enum.Material.Metal)
    end
    lightAnchor(folder, "LanternLight", site + Vector3.new(0, clockY1 + 56, 30), Color3.fromRGB(120, 255, 170), 3, 60)
end

---------------------------------------------------------------------------- Zamzam and night lighting

local function zamzamLabel(host: BasePart)
    local gui = newSurfaceGui(host, Enum.NormalId.Front, 30)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = "ZAMZAM"
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(22, 82, 58)
    label.Parent = gui
end

local function buildZamzamStations(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, "ZamzamStations")
    for index = 1, 8 do
        local angle = segmentAngle(index * 5 - 2) + math.rad(4.5)
        local frame = radialFrame(center, angle, RING_INNER + 9, FLOOR)
        local station = BuildUtils.CreateFolder(folder, string.format("Zamzam_%d", index))
        part(station, "Cooler", Vector3.new(7, 6.4, 3.2), frame * CFrame.new(0, 3.2, 0), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
        decor(station, "Taps", Vector3.new(5.6, 0.5, 0.6), frame * CFrame.new(0, 3.6, -1.8), SILVER, Enum.Material.Metal)
        local sign = decor(station, "Sign", Vector3.new(6.4, 1.6, 0.2), frame * CFrame.new(0, 5.4, -1.72), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
        sign.CFrame = frame * CFrame.new(0, 5.4, -1.72)
        zamzamLabel(sign)
    end
end

local function buildCourtyardLights(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, "NightLighting")
    -- Hidden floodlights that wash the kiswa and the inner mataf after dark.
    for index = 1, 8 do
        local angle = index / 8 * math.pi * 2 + math.rad(22.5)
        lightAnchor(folder, string.format("KaabaWash_%d", index), center + Vector3.new(math.cos(angle) * 58, FLOOR + 30, math.sin(angle) * 58), Color3.fromRGB(255, 244, 226), 1.8, 52)
    end
    for index = 1, 10 do
        local angle = index / 10 * math.pi * 2
        lightAnchor(folder, string.format("MatafWash_%d", index), center + Vector3.new(math.cos(angle) * 135, FLOOR + 36, math.sin(angle) * 135), Color3.fromRGB(255, 246, 232), 1.4, 60)
    end

    -- Green light on the gallery facing the Black Stone corner: where each tawaf round begins.
    local eastAngle = math.pi
    decor(folder, "TawafStartLight", Vector3.new(5, 5, 0.6), radialFrame(center, eastAngle, RING_INNER - 1.4, LEVELS[2] - 6), SAI_GREEN, Enum.Material.Neon)
end

---------------------------------------------------------------------------- pilgrims

MasjidAlHaram.PilgrimFolderName = "TawafPilgrims"

-- Bands of the mataf the pilgrims walk in. They keep clear of Hijr Ismail and Maqam Ibrahim
-- (inside 74 studs) and of the arrival spawn, guide and leaderboard (about 88 to 112).
local PILGRIM_RINGS = { 84, 92, 118, 126, 135, 145, 156, 168 }
local SKIN_TONES = {
    Color3.fromRGB(234, 192, 160), Color3.fromRGB(198, 146, 108), Color3.fromRGB(160, 110, 74),
    Color3.fromRGB(112, 76, 52), Color3.fromRGB(222, 176, 138), Color3.fromRGB(86, 58, 40),
}
local ABAYA_COLOURS = { Color3.fromRGB(24, 24, 28), Color3.fromRGB(32, 36, 52), Color3.fromRGB(236, 234, 228), Color3.fromRGB(58, 48, 44) }
local IHRAM_WHITE = Color3.fromRGB(242, 242, 238)

-- Simple figures in ihram (men in two white sheets, women in modest abayas) walking
-- anticlockwise, so the Kaaba is on their left. The server places them once; the
-- TawafAmbience client script moves them locally so nothing is sent over the network.
local function buildTawafPilgrims(parent: Instance, center: Vector3)
    local folder = BuildUtils.CreateFolder(parent, MasjidAlHaram.PilgrimFolderName)
    folder:SetAttribute("Center", center)
    folder:SetAttribute("FloorY", center.Y + FLOOR)
    local random = makeRandom(2024)
    local index = 0

    for ringIndex, radius in ipairs(PILGRIM_RINGS) do
        for slot = 1, 4 do
            index += 1
            local pilgrim = BuildUtils.CreateFolder(folder, string.format("Pilgrim_%02d", index))
            local startAngle = (slot - 1) * math.pi * 0.5 + ringIndex * 0.7 + random(-0.3, 0.3)
            local speed = random(4.2, 5.6) / radius
            pilgrim:SetAttribute("Radius", radius + random(-2, 2))
            pilgrim:SetAttribute("StartAngle", startAngle)
            pilgrim:SetAttribute("AngularSpeed", speed)
            pilgrim:SetAttribute("Phase", random(0, 6.28))

            local skin = SKIN_TONES[math.floor(random(1, #SKIN_TONES + 0.999))]
            local woman = random(0, 1) < 0.4
            local cloth = if woman then ABAYA_COLOURS[math.floor(random(1, #ABAYA_COLOURS + 0.999))] else IHRAM_WHITE
            local scarf = if woman then (if random(0, 1) < 0.5 then IHRAM_WHITE else Color3.fromRGB(30, 30, 34)) else skin
            local pieces = {
                { Name = "Lower", Size = Vector3.new(1.9, 2.7, 1.1), Offset = CFrame.new(0, 1.35, 0), Color = cloth },
                { Name = "Upper", Size = Vector3.new(2.0, 2.0, 1.05), Offset = CFrame.new(0, 3.7, 0), Color = cloth },
                { Name = "ArmLeft", Size = Vector3.new(0.55, 2.0, 0.65), Offset = CFrame.new(-1.3, 3.55, 0), Color = if woman then cloth else skin },
                { Name = "ArmRight", Size = Vector3.new(0.55, 2.0, 0.65), Offset = CFrame.new(1.3, 3.55, 0), Color = if woman then cloth else skin },
                { Name = "Head", Size = Vector3.new(1.3, 1.3, 1.3), Offset = CFrame.new(0, 5.35, 0), Color = scarf },
            }

            for _, piece in ipairs(pieces) do
                local figurePart = decor(pilgrim, piece.Name, piece.Size, CFrame.new(center + Vector3.new(math.cos(startAngle) * radius, FLOOR, math.sin(startAngle) * radius)) * piece.Offset, piece.Color, Enum.Material.Fabric)
                figurePart:SetAttribute("Offset", piece.Offset)
                if piece.Name == "Head" then
                    figurePart.Shape = Enum.PartType.Ball
                    figurePart.Material = Enum.Material.SmoothPlastic
                end
            end

            if woman then
                local face = decor(pilgrim, "Face", Vector3.new(0.8, 0.9, 0.2), CFrame.new(center + Vector3.new(math.cos(startAngle) * radius, FLOOR, math.sin(startAngle) * radius)) * CFrame.new(0, 5.3, -0.6), skin, Enum.Material.SmoothPlastic)
                face:SetAttribute("Offset", CFrame.new(0, 5.3, -0.6))
            end
        end
    end
end

---------------------------------------------------------------------------- public

export type Landmarks = {
    Kaaba: CFrame,
    MaqamIbrahim: Vector3,
    HijrIsmail: Vector3,
    Safa: Vector3,
    Marwa: Vector3,
}

function MasjidAlHaram.Build(parent: Instance, center: Vector3): Landmarks
    local root = BuildUtils.CreateFolder(parent, "MasjidAlHaram")

    buildMatafFloor(root, center)
    local kaaba = buildKaaba(root, center)
    local hijr = buildHijrIsmail(root, kaaba)
    local maqam = buildMaqamIbrahim(root, kaaba)
    buildMatafExpansion(root, center)
    buildOttomanRiwaq(root, center)
    buildZamzamStations(root, center)
    buildTawafPilgrims(root, center)
    buildCourtyardLights(root, center)

    -- First Saudi galleries on the south, west and north sides; the mas'a closes the east.
    local galleries = BuildUtils.CreateFolder(root, "SaudiGalleries")
    local galleryLevels = { FLOOR, 34, 62 }
    buildWing(galleries, center, { Name = "SouthGallery", Angle = -math.pi * 0.5, InnerDistance = 340, OuterDistance = 430, From = -430, To = 340, Levels = galleryLevels, BaySpacing = 41, InnerArches = true, InteriorColumns = false, DoorGap = 45 })
    buildWing(galleries, center, { Name = "NorthGallery", Angle = math.pi * 0.5, InnerDistance = 340, OuterDistance = 430, From = -340, To = 430, Levels = galleryLevels, BaySpacing = 41, InnerArches = true, InteriorColumns = false })
    buildWing(galleries, center, { Name = "WestGallery", Angle = 0, InnerDistance = 340, OuterDistance = 430, From = -340, To = 340, Levels = galleryLevels, BaySpacing = 41, InnerArches = true, InteriorColumns = false })
    local safa, marwa = buildMasa(root, center)

    -- King Fahd expansion (west) and King Abdullah expansion (north).
    local expansions = BuildUtils.CreateFolder(root, "Expansions")
    buildWing(expansions, center, { Name = "KingFahdExpansion", Angle = 0, InnerDistance = 440, OuterDistance = 600, From = -330, To = 330, Levels = { FLOOR, 34, 62 }, BaySpacing = 44, InnerArches = false, InteriorColumns = true, DoorGap = 45 })
    buildWing(expansions, center, { Name = "KingAbdullahExpansion", Angle = math.pi * 0.5, InnerDistance = 450, OuterDistance = 650, From = -440, To = 440, Levels = { FLOOR, 34, 62, 90 }, BaySpacing = 48, InnerArches = false, InteriorColumns = true, DoorGap = 56 })
    for index, x in ipairs({ -260, 0, 260 }) do
        ball(expansions, string.format("KingAbdullahRoofDome_%d", index), 46, center + Vector3.new(x, 90, 550), OTTOMAN_DOME, Enum.Material.Plaster, true)
        decor(expansions, string.format("KingAbdullahDomeFinial_%d", index), Vector3.new(1.2, 8, 1.2), CFrame.new(center + Vector3.new(x, 117, 550)), BRIGHT_GOLD, Enum.Material.Metal)
    end
    ball(expansions, "KingFahdRoofDome", 40, center + Vector3.new(520, 62, 0), OTTOMAN_DOME, Enum.Material.Plaster, true)

    -- Named gates. Each frame's +Z points out of the mosque.
    local gates = BuildUtils.CreateFolder(root, "Gates")
    buildGate(gates, "KingAbdulazizGate", radialFrame(center, -math.pi * 0.5, 430, 0), 66, 58, "King Abdulaziz Gate", "Bab al-Malik Abd al-Aziz - faces the clock tower")
    buildGate(gates, "KingFahdGate", radialFrame(center, 0, 600, 0), 66, 58, "King Fahd Gate", "Bab al-Malik Fahd - King Fahd expansion")
    buildGate(gates, "KingAbdullahGate", radialFrame(center, math.pi * 0.5, 650, 0), 84, 74, "King Abdullah Gate", "Bab al-Malik Abdullah - King Abdullah expansion")
    buildGate(gates, "BabAsSalam", radialFrame(center, math.pi, 430, 0), 48, 40, "Bab as-Salam", "Gate of Peace - beside the mas'a")

    -- Thirteen minarets: pairs at the main gates plus the single minaret by Safa.
    local minarets = BuildUtils.CreateFolder(root, "Minarets")
    local standard, tallest = 168, 236
    for _, spec in ipairs({
        { Name = "KingAbdulaziz_A", Offset = Vector3.new(-62, 0, -452), Height = standard },
        { Name = "KingAbdulaziz_B", Offset = Vector3.new(62, 0, -452), Height = standard },
        { Name = "KingFahd_A", Offset = Vector3.new(622, 0, -64), Height = standard },
        { Name = "KingFahd_B", Offset = Vector3.new(622, 0, 64), Height = standard },
        { Name = "KingAbdullah_A", Offset = Vector3.new(-76, 0, 672), Height = tallest },
        { Name = "KingAbdullah_B", Offset = Vector3.new(76, 0, 672), Height = tallest },
        { Name = "BabAlUmrah_A", Offset = Vector3.new(478, 0, 520), Height = standard },
        { Name = "BabAlUmrah_B", Offset = Vector3.new(538, 0, 468), Height = standard },
        { Name = "BabAlFath_A", Offset = Vector3.new(-478, 0, 520), Height = standard },
        { Name = "BabAlFath_B", Offset = Vector3.new(-538, 0, 468), Height = standard },
        { Name = "BabAsSalam_A", Offset = Vector3.new(-454, 0, -62), Height = standard },
        { Name = "BabAsSalam_B", Offset = Vector3.new(-454, 0, 62), Height = standard },
        { Name = "Safa", Offset = Vector3.new(-470, 0, -500), Height = standard },
    }) do
        buildMinaret(minarets, "Minaret_" .. spec.Name, center + spec.Offset, spec.Height)
    end

    buildAbrajAlBait(root, center)

    return {
        Kaaba = kaaba,
        MaqamIbrahim = maqam,
        HijrIsmail = hijr,
        Safa = safa,
        Marwa = marwa,
    }
end

return MasjidAlHaram
