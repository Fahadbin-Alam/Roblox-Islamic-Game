--!strict

-- Detailed prefabs for dressing the world: mud-brick houses with parapets, beams and shuttered
-- windows, curved date palms, market stalls, Bedouin tents, wells, jars, rugs, camels, rocks
-- and shrubs. Everything is anchored and decorative parts do not collide, so dense scenes stay
-- cheap for physics.
--
-- Every prefab takes a `seed` so the same place always builds the same way (no math.random).

local BuildUtils = require(script.Parent.BuildUtils)

local Decor = {}

Decor.Colors = {
    Mud = Color3.fromRGB(181, 141, 99),
    MudLight = Color3.fromRGB(199, 166, 122),
    Plaster = Color3.fromRGB(214, 194, 160),
    MudDark = Color3.fromRGB(150, 113, 78),
    Wood = Color3.fromRGB(108, 77, 50),
    WoodDark = Color3.fromRGB(74, 52, 35),
    Opening = Color3.fromRGB(38, 28, 22),
    Trunk = Color3.fromRGB(122, 94, 66),
    TrunkDark = Color3.fromRGB(98, 74, 52),
    Frond = Color3.fromRGB(96, 128, 66),
    FrondDark = Color3.fromRGB(74, 104, 54),
    FrondDry = Color3.fromRGB(150, 140, 80),
    Dates = Color3.fromRGB(168, 92, 38),
    Rock = Color3.fromRGB(136, 112, 88),
    RockDark = Color3.fromRGB(112, 90, 70),
    RockLight = Color3.fromRGB(164, 138, 108),
    GoatHair = Color3.fromRGB(52, 42, 36),
    Cloths = {
        Color3.fromRGB(160, 58, 46),
        Color3.fromRGB(58, 90, 124),
        Color3.fromRGB(206, 168, 96),
        Color3.fromRGB(88, 118, 70),
        Color3.fromRGB(130, 70, 110),
        Color3.fromRGB(214, 200, 170),
    },
    Spices = {
        Color3.fromRGB(196, 120, 40),
        Color3.fromRGB(170, 50, 36),
        Color3.fromRGB(214, 176, 60),
        Color3.fromRGB(110, 128, 60),
    },
}

local C = Decor.Colors

-- Small deterministic random source: rng(a, b) returns a number in [a, b].
function Decor.Rng(seed: number): (number?, number?) -> number
    local state = math.floor(math.abs(seed) * 7919 + 17) % 2147483647

    if state <= 0 then
        state += 2147483646
    end

    return function(a: number?, b: number?): number
        state = (state * 16807) % 2147483647
        local f = (state - 1) / 2147483646

        if a == nil then
            return f
        end

        return (a :: number) + ((b or 1) - (a :: number)) * f
    end
end

local function shade(color: Color3, scale: number): Color3
    return Color3.new(math.clamp(color.R * scale, 0, 1), math.clamp(color.G * scale, 0, 1), math.clamp(color.B * scale, 0, 1))
end

Decor.Shade = shade

local function solid(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
    return BuildUtils.CreatePart(parent, name, size, cframe, color, material, shape, nil)
end

-- Decoration that players walk through: no collision, queries or touches.
local function deco(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
    local part = BuildUtils.CreatePart(parent, name, size, cframe, color, material, shape, nil)
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false

    return part
end

Decor.Solid = solid
Decor.Deco = deco

-- A cylinder from `a` to `b` (Roblox cylinders run along their X axis).
local function rod(parent: Instance, name: string, a: Vector3, b: Vector3, radius: number, color: Color3, material: Enum.Material, collide: boolean?): Part
    local mid = (a + b) / 2
    local length = (b - a).Magnitude
    local cframe = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
    local make = if collide then solid else deco

    return make(parent, name, Vector3.new(length, radius * 2, radius * 2), cframe, color, material, Enum.PartType.Cylinder)
end

Decor.Rod = rod

-- A flat blade from `a` towards `b` (a palm frond, a rope, a pole): width across, thin.
local function blade(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, thickness: number, color: Color3, material: Enum.Material): Part
    local mid = (a + b) / 2
    local length = (b - a).Magnitude

    return deco(parent, name, Vector3.new(width, thickness, length), CFrame.lookAt(mid, b), color, material)
end

Decor.Blade = blade

local function model(parent: Instance, name: string): Model
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent

    return m
end

---------------------------------------------------------------- Houses

export type HouseOptions = {
    Color: Color3?,
    Storeys: number?,
    Awning: boolean?,
    Bench: boolean?,
    -- Lite houses skip small details (merlons, extra beams, roof clutter): about half the
    -- parts, for packed town blocks seen mostly from a distance.
    Lite: boolean?,
}

-- A flat-roofed mud-brick house. `base` is the ground centre, door facing -Z.
function Decor.MudHouse(parent: Instance, name: string, base: CFrame, width: number, depth: number, height: number, seed: number, options: HouseOptions?): Model
    local opts: HouseOptions = options or {}
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local palette = { C.Mud, C.MudLight, C.Plaster, C.Mud }
    local color = opts.Color or palette[math.floor(r(1, 4.999))]
    local trim = shade(color, 0.82)
    local hw, hd = width / 2, depth / 2
    local lite = opts.Lite == true

    solid(m, "Plinth", Vector3.new(width + 0.8, 1.2, depth + 0.8), base * CFrame.new(0, 0.6, 0), trim, Enum.Material.Sandstone)
    solid(m, "Walls", Vector3.new(width, height, depth), base * CFrame.new(0, height / 2, 0), color, Enum.Material.Sandstone)
    deco(m, "RoofBand", Vector3.new(width + 0.3, 0.5, depth + 0.3), base * CFrame.new(0, height - 0.4, 0), trim, Enum.Material.Sandstone)

    -- Parapet around the flat roof.
    local ph, t = 1.6, 0.8
    solid(m, "ParapetFront", Vector3.new(width, ph, t), base * CFrame.new(0, height + ph / 2, -hd + t / 2), color, Enum.Material.Sandstone)
    solid(m, "ParapetBack", Vector3.new(width, ph, t), base * CFrame.new(0, height + ph / 2, hd - t / 2), color, Enum.Material.Sandstone)
    solid(m, "ParapetLeft", Vector3.new(t, ph, depth - 2 * t), base * CFrame.new(-hw + t / 2, height + ph / 2, 0), color, Enum.Material.Sandstone)
    solid(m, "ParapetRight", Vector3.new(t, ph, depth - 2 * t), base * CFrame.new(hw - t / 2, height + ph / 2, 0), color, Enum.Material.Sandstone)

    -- Stepped merlons on the front parapet.
    local merlons = if lite then 0 else math.max(2, math.floor(width / 5))

    for index = 1, merlons do
        local x = -hw + (index - 0.5) * (width / merlons)
        deco(m, "Merlon" .. index, Vector3.new(1.3, 1.1, t), base * CFrame.new(x, height + ph + 0.55, -hd + t / 2), color, Enum.Material.Sandstone)
    end

    -- Palm-trunk roof beams poking through the front wall.
    local beams = if lite then 2 else math.max(2, math.floor(width / 4))

    for index = 1, beams do
        local x = -hw + (index - 0.5) * (width / beams)
        local y = height - 1.3
        rod(m, "Beam" .. index, (base * CFrame.new(x, y, -hd + 0.2)).Position, (base * CFrame.new(x, y, -hd - 1.4)).Position, 0.32, C.WoodDark, Enum.Material.Wood)
    end

    -- Door with a dark frame and a wooden lintel.
    local doorX = if width > 12 then r(-hw * 0.35, hw * 0.35) else 0
    deco(m, "DoorFrame", Vector3.new(4.4, 7.6, 0.3), base * CFrame.new(doorX, 3.8, -hd - 0.12), C.Opening, Enum.Material.Wood)
    deco(m, "Door", Vector3.new(3.4, 7, 0.36), base * CFrame.new(doorX, 3.5, -hd - 0.2), if r() > 0.5 then C.Wood else shade(C.Cloths[2], 0.8), Enum.Material.WoodPlanks)
    deco(m, "Lintel", Vector3.new(5.6, 0.7, 0.9), base * CFrame.new(doorX, 7.9, -hd - 0.3), C.WoodDark, Enum.Material.Wood)

    -- Small high windows with sills.
    local windowY = math.max(6, height * 0.66)
    local windowXs = if width > 14 and not lite then { doorX - 5.5, doorX + 5.5 } else { doorX + (if doorX > 0 then -4.5 else 4.5) }

    for index, x in ipairs(windowXs) do
        if math.abs(x) < hw - 1.6 then
            deco(m, "Window" .. index, Vector3.new(1.6, 2.2, 0.3), base * CFrame.new(x, windowY, -hd - 0.1), C.Opening, Enum.Material.Wood)
            deco(m, "Sill" .. index, Vector3.new(2.6, 0.35, 0.7), base * CFrame.new(x, windowY - 1.3, -hd - 0.3), trim, Enum.Material.Sandstone)
        end
    end

    if lite then
        local storeysLite = opts.Storeys or (if width >= 13 and r() > 0.6 then 2 else 1)

        if storeysLite >= 2 then
            local uw, ud, uh = width * 0.5, depth * 0.55, height * 0.62
            local upper = base * CFrame.new(hw - uw / 2 - 0.8, height, hd - ud / 2 - 0.8)
            solid(m, "Upper", Vector3.new(uw, uh, ud), upper * CFrame.new(0, uh / 2, 0), color, Enum.Material.Sandstone)
            deco(m, "UpperParapet", Vector3.new(uw + 0.2, 1.1, ud + 0.2), upper * CFrame.new(0, uh + 0.55, 0), trim, Enum.Material.Sandstone)
            deco(m, "UpperWindow", Vector3.new(1.6, 2, 0.3), upper * CFrame.new(0, uh * 0.55, -ud / 2 - 0.1), C.Opening, Enum.Material.Wood)
        end

        return m
    end

    -- A window on one side wall too.
    deco(m, "SideWindow", Vector3.new(0.3, 2, 1.6), base * CFrame.new(hw + 0.1, windowY, r(-hd * 0.4, hd * 0.4)), C.Opening, Enum.Material.Wood)
    -- Rain spout.
    deco(m, "Spout", Vector3.new(0.5, 0.5, 2), base * CFrame.new(-hw + 1, height + 0.3, -hd - 0.9), C.WoodDark, Enum.Material.Wood)

    local storeys = opts.Storeys or (if width >= 13 and r() > 0.55 then 2 else 1)

    if storeys >= 2 then
        local uw, ud, uh = width * 0.5, depth * 0.55, height * 0.62
        local upper = base * CFrame.new(hw - uw / 2 - 0.8, height, hd - ud / 2 - 0.8)
        solid(m, "Upper", Vector3.new(uw, uh, ud), upper * CFrame.new(0, uh / 2, 0), color, Enum.Material.Sandstone)
        deco(m, "UpperBand", Vector3.new(uw + 0.3, 0.5, ud + 0.3), upper * CFrame.new(0, uh - 0.3, 0), trim, Enum.Material.Sandstone)
        deco(m, "UpperParapet", Vector3.new(uw + 0.2, 1.1, ud + 0.2), upper * CFrame.new(0, uh + 0.55, 0), color, Enum.Material.Sandstone)
        -- A latticed wooden bay window (mashrabiya) on the upper floor.
        local bay = upper * CFrame.new(0, uh * 0.5, -ud / 2 - 0.7)
        deco(m, "Mashrabiya", Vector3.new(3.4, 3.2, 1.4), bay, C.Wood, Enum.Material.Wood)
        deco(m, "MashrabiyaLattice", Vector3.new(2.8, 2.4, 0.2), bay * CFrame.new(0, 0, -0.75), shade(C.Wood, 1.35), Enum.Material.WoodPlanks)
        deco(m, "MashrabiyaCap", Vector3.new(3.8, 0.4, 1.8), bay * CFrame.new(0, 1.8, 0), C.WoodDark, Enum.Material.Wood)
    end

    -- Things on the roof.
    if r() > 0.4 then
        rod(m, "RolledMat", (base * CFrame.new(-hw + 2, height + 0.45, -1.5)).Position, (base * CFrame.new(-hw + 2, height + 0.45, 1.5)).Position, 0.45, C.Cloths[math.floor(r(1, 6.999))], Enum.Material.Fabric)
    end

    if r() > 0.5 then
        Decor.Jar(m, "RoofJar", (base * CFrame.new(-hw + 2.2, height, hd - 2.2)).Position, 0.9, nil)
    end

    -- A mud bench (mastaba) beside the door and an awning over it.
    if opts.Bench ~= false and r() > 0.35 then
        local side = if doorX > 0 then -1 else 1
        solid(m, "Bench", Vector3.new(4.5, 1.4, 1.8), base * CFrame.new(doorX + side * 4.8, 0.7, -hd - 0.9), trim, Enum.Material.Sandstone)
    end

    if opts.Awning or (opts.Awning == nil and r() > 0.6) then
        local cloth = C.Cloths[math.floor(r(1, 6.999))]
        deco(m, "Awning", Vector3.new(6, 0.2, 3.4), base * CFrame.new(doorX, 8.6, -hd - 1.6) * CFrame.Angles(math.rad(-14), 0, 0), cloth, Enum.Material.Fabric)
        rod(m, "AwningPoleL", (base * CFrame.new(doorX - 2.8, 0, -hd - 3.1)).Position, (base * CFrame.new(doorX - 2.8, 8.2, -hd - 3.1)).Position, 0.15, C.WoodDark, Enum.Material.Wood)
        rod(m, "AwningPoleR", (base * CFrame.new(doorX + 2.8, 0, -hd - 3.1)).Position, (base * CFrame.new(doorX + 2.8, 8.2, -hd - 3.1)).Position, 0.15, C.WoodDark, Enum.Material.Wood)
    end

    return m
end

-- A mud-brick wall with a capping and small merlons.
function Decor.Wall(parent: Instance, name: string, a: Vector3, b: Vector3, height: number, thickness: number, color: Color3?): Model
    local m = model(parent, name)
    local tint = color or C.Mud
    local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
    local length = flat.Magnitude
    local mid = (a + b) / 2
    local frame = CFrame.lookAt(Vector3.new(mid.X, a.Y, mid.Z), Vector3.new(b.X, a.Y, b.Z))
    solid(m, "Wall", Vector3.new(thickness, height, length), frame * CFrame.new(0, height / 2, 0), tint, Enum.Material.Sandstone)
    deco(m, "Cap", Vector3.new(thickness + 0.5, 0.5, length), frame * CFrame.new(0, height + 0.25, 0), shade(tint, 0.85), Enum.Material.Sandstone)

    local count = math.floor(length / 6)

    for index = 1, count do
        local z = -length / 2 + (index - 0.5) * (length / count)
        deco(m, "Merlon" .. index, Vector3.new(thickness, 1, 1.4), frame * CFrame.new(0, height + 1, z), tint, Enum.Material.Sandstone)
    end

    return m
end

---------------------------------------------------------------- Plants and rocks

-- A date palm with a curved trunk, drooping fronds and, sometimes, hanging dates. `lite`
-- palms (for big groves) use three trunk segments and single-piece fronds: half the parts.
function Decor.Palm(parent: Instance, name: string, ground: Vector3, height: number, seed: number, lite: boolean?): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local leanAngle = r(0, math.pi * 2)
    local leanAmount = r(0.04, 0.2)
    local lean = Vector3.new(math.cos(leanAngle), 0, math.sin(leanAngle))
    local segments = if lite then 3 else 5
    local point = ground
    local segment = height / segments

    for index = 1, segments do
        local bend = leanAmount * (index / segments) * 1.6
        local direction = (Vector3.new(0, 1, 0) + lean * bend).Unit
        local nextPoint = point + direction * segment
        local radius = 0.95 - index * 0.07
        rod(m, "Trunk" .. index, point - direction * 0.2, nextPoint, radius, if index % 2 == 0 then C.TrunkDark else C.Trunk, Enum.Material.Wood, index <= 2)
        point = nextPoint
    end

    local top = point
    deco(m, "Crown", Vector3.new(2.4, 2.4, 2.4), CFrame.new(top), C.FrondDark, Enum.Material.Grass, Enum.PartType.Ball)

    local fronds = if lite then 6 else 7
    local spin = r(0, math.pi * 2)

    for index = 1, fronds do
        if lite then
            local angle = spin + (index / fronds) * math.pi * 2
            local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local tip = top + out * r(6.5, 8) + Vector3.new(0, r(-2.4, -0.6), 0)
            blade(m, "Frond" .. index, top, tip, 2, 0.22, if index % 2 == 0 then C.Frond else C.FrondDark, Enum.Material.Grass)
            continue
        end

        local angle = spin + (index / fronds) * math.pi * 2 + r(-0.2, 0.2)
        local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local length = r(6.5, 8.5)
        local mid = top + out * length * 0.55 + Vector3.new(0, r(0.8, 1.8), 0)
        local tip = top + out * length + Vector3.new(0, r(-3.2, -1.6), 0)
        local color = if r() > 0.85 then C.FrondDry elseif index % 2 == 0 then C.Frond else C.FrondDark
        blade(m, string.format("Frond%dA", index), top, mid, 2.2, 0.22, color, Enum.Material.Grass)
        blade(m, string.format("Frond%dB", index), mid, tip, 1.6, 0.2, color, Enum.Material.Grass)
    end

    if not lite and r() > 0.45 then
        local hang = top + Vector3.new(math.cos(spin + 1), 0, math.sin(spin + 1)) * 1.3 + Vector3.new(0, -1.6, 0)
        deco(m, "Dates", Vector3.new(1.4, 2, 1.4), CFrame.new(hang), C.Dates, Enum.Material.Pebble, Enum.PartType.Ball)
    end

    return m
end

-- A cluster of tilted boulders.
function Decor.Rocks(parent: Instance, name: string, ground: Vector3, size: number, seed: number): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local count = 3 + math.floor(r(0, 2.99))
    local colors = { C.Rock, C.RockDark, C.RockLight }

    for index = 1, count do
        local s = size * r(0.45, 1)
        local offset = Vector3.new(r(-size, size) * 0.6, 0, r(-size, size) * 0.6)
        local cframe = CFrame.new(ground + offset + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(r(-0.35, 0.35), r(0, 6.28), r(-0.35, 0.35))
        solid(m, "Rock" .. index, Vector3.new(s * r(0.9, 1.5), s * r(0.6, 1), s * r(0.8, 1.3)), cframe, colors[(index % 3) + 1], Enum.Material.Slate)
    end

    return m
end

-- A low desert shrub.
function Decor.Shrub(parent: Instance, name: string, ground: Vector3, seed: number): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)

    for index = 1, 3 do
        local s = r(1.4, 2.8)
        deco(m, "Leaf" .. index, Vector3.new(s * 1.3, s, s * 1.3), CFrame.new(ground + Vector3.new(r(-1.2, 1.2), s * 0.35, r(-1.2, 1.2))), if index == 2 then C.FrondDry else Color3.fromRGB(118, 128, 76), Enum.Material.Grass, Enum.PartType.Ball)
    end

    return m
end

---------------------------------------------------------------- Props

function Decor.Jar(parent: Instance, name: string, ground: Vector3, scale: number, color: Color3?): Model
    local m = model(parent, name)
    local tint = color or Color3.fromRGB(176, 108, 70)
    deco(m, "Body", Vector3.new(1.8, 2.2, 1.8) * scale, CFrame.new(ground + Vector3.new(0, 1.1 * scale, 0)), tint, Enum.Material.Slate, Enum.PartType.Ball)
    deco(m, "Neck", Vector3.new(0.7 * scale, 1 * scale, 1 * scale), CFrame.new(ground + Vector3.new(0, 2.35 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), shade(tint, 0.85), Enum.Material.Slate, Enum.PartType.Cylinder)

    return m
end

function Decor.Rug(parent: Instance, name: string, cframe: CFrame, width: number, length: number, seed: number): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local main = C.Cloths[math.floor(r(1, 4.999))]
    deco(m, "Border", Vector3.new(width, 0.12, length), cframe * CFrame.new(0, 0.06, 0), shade(main, 0.6), Enum.Material.Fabric)
    deco(m, "Field", Vector3.new(width - 0.8, 0.14, length - 0.8), cframe * CFrame.new(0, 0.08, 0), main, Enum.Material.Fabric)
    deco(m, "Medallion", Vector3.new(width * 0.35, 0.16, length * 0.3), cframe * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(45), 0), C.Cloths[3], Enum.Material.Fabric)

    return m
end

function Decor.Sack(parent: Instance, name: string, ground: Vector3, color: Color3?): Part
    return deco(parent, name, Vector3.new(1.8, 2.2, 1.6), CFrame.new(ground + Vector3.new(0, 1, 0)), color or Color3.fromRGB(196, 176, 134), Enum.Material.Fabric, Enum.PartType.Ball)
end

function Decor.Crate(parent: Instance, name: string, cframe: CFrame, size: number): Part
    return solid(parent, name, Vector3.new(size, size * 0.8, size), cframe * CFrame.new(0, size * 0.4, 0), C.Wood, Enum.Material.WoodPlanks)
end

-- A stone well with a wooden frame, rope and bucket.
function Decor.Well(parent: Instance, name: string, ground: Vector3): Model
    local m = model(parent, name)
    solid(m, "Ring", Vector3.new(3, 7, 7), CFrame.new(ground + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 130, 104), Enum.Material.Cobblestone, Enum.PartType.Cylinder)
    deco(m, "Water", Vector3.new(0.2, 5.6, 5.6), CFrame.new(ground + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 62, 70), Enum.Material.Glass, Enum.PartType.Cylinder)
    rod(m, "PostL", ground + Vector3.new(-3.2, 0, 0), ground + Vector3.new(-3.2, 7.5, 0), 0.3, C.WoodDark, Enum.Material.Wood, true)
    rod(m, "PostR", ground + Vector3.new(3.2, 0, 0), ground + Vector3.new(3.2, 7.5, 0), 0.3, C.WoodDark, Enum.Material.Wood, true)
    rod(m, "Beam", ground + Vector3.new(-3.6, 7.2, 0), ground + Vector3.new(3.6, 7.2, 0), 0.3, C.Wood, Enum.Material.Wood)
    rod(m, "Rope", ground + Vector3.new(0, 7.1, 0), ground + Vector3.new(0, 4.6, 0), 0.06, Color3.fromRGB(196, 176, 134), Enum.Material.Fabric)
    deco(m, "Bucket", Vector3.new(1.2, 1.4, 1.4), CFrame.new(ground + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(90)), C.Wood, Enum.Material.WoodPlanks, Enum.PartType.Cylinder)

    return m
end

-- A market stall: posts, a sloping cloth canopy with a valance, a counter and goods.
function Decor.Stall(parent: Instance, name: string, base: CFrame, seed: number): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local cloth = C.Cloths[math.floor(r(1, 5.999))]
    local w, d = 10, 7

    for index, offset in ipairs({ Vector3.new(-w / 2, 0, -d / 2), Vector3.new(w / 2, 0, -d / 2), Vector3.new(-w / 2, 0, d / 2), Vector3.new(w / 2, 0, d / 2) }) do
        local tall = if offset.Z < 0 then 7.4 else 8.6
        rod(m, "Post" .. index, (base * CFrame.new(offset)).Position, (base * CFrame.new(offset + Vector3.new(0, tall, 0))).Position, 0.2, C.WoodDark, Enum.Material.Wood, true)
    end

    deco(m, "Canopy", Vector3.new(w + 1.2, 0.2, d + 1.4), base * CFrame.new(0, 8.1, 0) * CFrame.Angles(math.rad(-9.5), 0, 0), cloth, Enum.Material.Fabric)
    deco(m, "Valance", Vector3.new(w + 1.2, 1.1, 0.15), base * CFrame.new(0, 6.8, -d / 2 - 0.65), shade(cloth, 0.75), Enum.Material.Fabric)
    solid(m, "Counter", Vector3.new(w - 1, 3, 2.6), base * CFrame.new(0, 1.5, -d / 2 + 1.6), C.Wood, Enum.Material.WoodPlanks)
    deco(m, "CounterCloth", Vector3.new(w - 0.8, 0.15, 2.8), base * CFrame.new(0, 3.05, -d / 2 + 1.6), C.Cloths[6], Enum.Material.Fabric)

    local goods = math.floor(r(3, 5.99))

    for index = 1, goods do
        local x = -w / 2 + 1.5 + (index - 1) * ((w - 3) / math.max(goods - 1, 1))
        local at = base * CFrame.new(x, 3.1, -d / 2 + 1.6)
        local kind = math.floor(r(1, 3.999))

        if kind == 1 then
            -- A basket of spice with a heaped top.
            deco(m, "Basket" .. index, Vector3.new(0.9, 1.8, 1.8), at * CFrame.new(0, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(170, 132, 80), Enum.Material.Fabric, Enum.PartType.Cylinder)
            deco(m, "Spice" .. index, Vector3.new(1.6, 0.9, 1.6), at * CFrame.new(0, 0.95, 0), C.Spices[math.floor(r(1, 4.999))], Enum.Material.Sand, Enum.PartType.Ball)
        elseif kind == 2 then
            Decor.Jar(m, "Pot" .. index, at.Position, 0.6, nil)
        else
            rod(m, "Bolt" .. index, (at * CFrame.new(-0.6, 0.45, 0)).Position, (at * CFrame.new(0.6, 0.45, 0)).Position, 0.45, C.Cloths[math.floor(r(1, 6.999))], Enum.Material.Fabric)
        end
    end

    Decor.Sack(m, "SackA", (base * CFrame.new(-w / 2 + 1, 0, d / 2 - 1.5)).Position, nil)
    Decor.Sack(m, "SackB", (base * CFrame.new(-w / 2 + 2.6, 0, d / 2 - 1.2)).Position, Color3.fromRGB(180, 150, 104))
    Decor.Crate(m, "Crate", base * CFrame.new(w / 2 - 1.5, 0, d / 2 - 1.5), 2.2)

    return m
end

-- A long, low Bedouin tent of dark goat hair, open at the front, with rugs and a fire.
function Decor.Tent(parent: Instance, name: string, base: CFrame, width: number, seed: number): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local depth = width * 0.6
    local cloth = if r() > 0.3 then C.GoatHair else Color3.fromRGB(96, 74, 56)
    local ridge = 7

    -- Poles along the ridge and the front edge.
    for index = -1, 1 do
        local x = index * width * 0.33
        rod(m, "RidgePole" .. index + 2, (base * CFrame.new(x, 0, 0)).Position, (base * CFrame.new(x, ridge, 0)).Position, 0.25, C.WoodDark, Enum.Material.Wood, true)
        rod(m, "FrontPole" .. index + 2, (base * CFrame.new(x, 0, -depth / 2)).Position, (base * CFrame.new(x, ridge - 2.2, -depth / 2)).Position, 0.18, C.WoodDark, Enum.Material.Wood, true)
    end

    -- Two roof panels meeting at the ridge, with a small dip between poles.
    deco(m, "RoofFront", Vector3.new(width, 0.3, depth / 2 + 0.6), base * CFrame.new(0, ridge - 1.1, -depth / 4) * CFrame.Angles(math.rad(-15), 0, 0), cloth, Enum.Material.Fabric)
    deco(m, "RoofBack", Vector3.new(width, 0.3, depth / 2 + 0.6), base * CFrame.new(0, ridge - 1.6, depth / 4 + 0.3) * CFrame.Angles(math.rad(22), 0, 0), cloth, Enum.Material.Fabric)
    -- Back and side walls hang down from the roof.
    deco(m, "BackWall", Vector3.new(width, ridge - 3, 0.25), base * CFrame.new(0, (ridge - 3) / 2, depth / 2 + 0.2), shade(cloth, 1.1), Enum.Material.Fabric)
    deco(m, "SideWallL", Vector3.new(0.25, ridge - 2.5, depth), base * CFrame.new(-width / 2, (ridge - 2.5) / 2, 0), shade(cloth, 1.1), Enum.Material.Fabric)
    deco(m, "SideWallR", Vector3.new(0.25, ridge - 2.5, depth), base * CFrame.new(width / 2, (ridge - 2.5) / 2, 0), shade(cloth, 1.1), Enum.Material.Fabric)
    -- A woven divider stripe along the front edge.
    deco(m, "Stripe", Vector3.new(width, 0.6, 0.2), base * CFrame.new(0, ridge - 2.6, -depth / 2 - 0.2), C.Cloths[1], Enum.Material.Fabric)

    -- Guy ropes to pegs.
    for index, x in ipairs({ -width / 2, width / 2 }) do
        rod(m, "Rope" .. index, (base * CFrame.new(x, ridge - 2.4, -depth / 2)).Position, (base * CFrame.new(x * 1.25, 0.2, -depth / 2 - 4)).Position, 0.05, Color3.fromRGB(200, 180, 140), Enum.Material.Fabric)
    end

    Decor.Rug(m, "Rug", base * CFrame.new(0, 0, -depth * 0.1), width * 0.7, depth * 0.7, seed)

    for index = 1, 3 do
        local x = (index - 2) * width * 0.22
        deco(m, "Cushion" .. index, Vector3.new(3, 1, 1.4), base * CFrame.new(x, 0.6, depth * 0.3), C.Cloths[(math.floor(index + seed) % 5) + 1], Enum.Material.Fabric)
    end

    -- Fire pit in front: a ring of stones and embers, with a coffee pot.
    local fire = base * CFrame.new(0, 0, -depth / 2 - 5)

    for index = 1, 6 do
        local a = index / 6 * math.pi * 2
        deco(m, "FireStone" .. index, Vector3.new(0.9, 0.7, 0.9), fire * CFrame.new(math.cos(a) * 1.4, 0.35, math.sin(a) * 1.4), C.RockDark, Enum.Material.Slate)
    end

    deco(m, "Embers", Vector3.new(1.6, 0.4, 1.6), fire * CFrame.new(0, 0.25, 0), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, Enum.PartType.Ball)
    Decor.Jar(m, "CoffeePot", (fire * CFrame.new(1.8, 0, 1)).Position, 0.45, Color3.fromRGB(186, 150, 72))

    return m
end

-- A standing camel (decoration). `base` faces -Z.
function Decor.Camel(parent: Instance, name: string, base: CFrame, seed: number): Model
    local r = Decor.Rng(seed)
    local m = model(parent, name)
    local coat = if r() > 0.5 then Color3.fromRGB(184, 146, 100) else Color3.fromRGB(160, 122, 82)
    local dark = shade(coat, 0.8)

    for index, offset in ipairs({ Vector3.new(-0.9, 0, -2), Vector3.new(0.9, 0, -2), Vector3.new(-0.9, 0, 2), Vector3.new(0.9, 0, 2) }) do
        rod(m, "Leg" .. index, (base * CFrame.new(offset)).Position, (base * CFrame.new(offset + Vector3.new(0, 5.4, 0))).Position, 0.35, dark, Enum.Material.Fabric)
    end

    deco(m, "Body", Vector3.new(2.6, 2.8, 6), base * CFrame.new(0, 6.4, 0), coat, Enum.Material.Fabric, Enum.PartType.Ball)
    deco(m, "Hump", Vector3.new(2.2, 2.2, 2.6), base * CFrame.new(0, 7.9, 0.3), coat, Enum.Material.Fabric, Enum.PartType.Ball)
    blade(m, "Neck", (base * CFrame.new(0, 6.6, -2.6)).Position, (base * CFrame.new(0, 9.6, -4.4)).Position, 1.1, 1.2, coat, Enum.Material.Fabric)
    deco(m, "Head", Vector3.new(1.1, 1.1, 2.2), base * CFrame.new(0, 9.9, -5.1), coat, Enum.Material.Fabric)
    deco(m, "Ears", Vector3.new(1.4, 0.4, 0.3), base * CFrame.new(0, 10.5, -4.5), dark, Enum.Material.Fabric)
    blade(m, "Tail", (base * CFrame.new(0, 6.8, 3)).Position, (base * CFrame.new(0, 4.8, 3.5)).Position, 0.3, 0.3, dark, Enum.Material.Fabric)
    deco(m, "Blanket", Vector3.new(2.9, 0.25, 2.6), base * CFrame.new(0, 7.6, -0.9), C.Cloths[math.floor(r(1, 4.999))], Enum.Material.Fabric)

    return m
end

-- A hanging lamp on a bracket, lit at night by HubAtmosphere-style point lights.
function Decor.WallLamp(parent: Instance, name: string, position: Vector3, facing: Vector3): Model
    local m = model(parent, name)
    rod(m, "Bracket", position, position + facing * 1.4, 0.1, C.WoodDark, Enum.Material.Metal)
    local glass = deco(m, "Lamp", Vector3.new(0.9, 1.3, 0.9), CFrame.new(position + facing * 1.4 + Vector3.new(0, -0.8, 0)), Color3.fromRGB(255, 206, 128), Enum.Material.Neon)
    BuildUtils.AddPointLight(glass, Color3.fromRGB(255, 196, 120), 1.2, 14)

    return m
end

-- A tall banner on a pole.
function Decor.Banner(parent: Instance, name: string, ground: Vector3, color: Color3, height: number): Model
    local m = model(parent, name)
    rod(m, "Pole", ground, ground + Vector3.new(0, height, 0), 0.22, C.WoodDark, Enum.Material.Wood, true)
    deco(m, "Cloth", Vector3.new(3.6, height * 0.4, 0.15), CFrame.new(ground + Vector3.new(1.9, height * 0.75, 0)), color, Enum.Material.Fabric)
    deco(m, "Tip", Vector3.new(0.7, 0.7, 0.7), CFrame.new(ground + Vector3.new(0, height + 0.3, 0)), Color3.fromRGB(214, 176, 92), Enum.Material.Metal, Enum.PartType.Ball)

    return m
end

-- A brazier: an iron bowl on legs with a glowing fire.
function Decor.Brazier(parent: Instance, name: string, ground: Vector3): Model
    local m = model(parent, name)

    for index = 1, 3 do
        local a = index / 3 * math.pi * 2
        rod(m, "Leg" .. index, ground + Vector3.new(math.cos(a) * 1.2, 0, math.sin(a) * 1.2), ground + Vector3.new(math.cos(a) * 0.6, 3.4, math.sin(a) * 0.6), 0.12, Color3.fromRGB(60, 54, 50), Enum.Material.Metal)
    end

    deco(m, "Bowl", Vector3.new(0.8, 2.6, 2.6), CFrame.new(ground + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 62, 56), Enum.Material.Metal, Enum.PartType.Cylinder)
    local fire = deco(m, "Fire", Vector3.new(1.8, 1.4, 1.8), CFrame.new(ground + Vector3.new(0, 4.4, 0)), Color3.fromRGB(255, 140, 50), Enum.Material.Neon, Enum.PartType.Ball)
    BuildUtils.AddPointLight(fire, Color3.fromRGB(255, 160, 80), 1.6, 18)

    return m
end

return Decor
