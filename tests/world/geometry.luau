-- Collision queries over the parts and terrain the mock engine recorded.
-- Each solid becomes a convex shape in its own local space (box, wedge, ball; cylinders are
-- treated as their bounding box). A vertical line through (x, z) cuts every solid it meets in
-- one interval of y, which is all a walking character cares about.

Geometry = {}

local CELL = 16
local grid = {}
local solids = {}

local function cellKey(cx, cz)
    return cx * 100003 + cz
end

local function addSolid(kind, cframe, size)
    local half = size * 0.5
    local solid = { Kind = kind, CFrame = cframe, Inverse = cframe:Inverse(), Half = half }

    -- World-space bounding box from the eight corners.
    local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
    for _, sx in ipairs({ -1, 1 }) do
        for _, sy in ipairs({ -1, 1 }) do
            for _, sz in ipairs({ -1, 1 }) do
                local corner = cframe * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
                minX = math.min(minX, corner.X)
                maxX = math.max(maxX, corner.X)
                minZ = math.min(minZ, corner.Z)
                maxZ = math.max(maxZ, corner.Z)
            end
        end
    end

    table.insert(solids, solid)

    for cx = math.floor(minX / CELL), math.floor(maxX / CELL) do
        for cz = math.floor(minZ / CELL), math.floor(maxZ / CELL) do
            local key = cellKey(cx, cz)
            local bucket = grid[key]
            if not bucket then
                bucket = {}
                grid[key] = bucket
            end
            table.insert(bucket, solid)
        end
    end
end

function Geometry.Build(root, filter)
    grid = {}
    solids = {}

    for _, part in ipairs(getAllParts()) do
        local include = part.CanCollide == true
        if include and root then
            include = false
            local node = part.Parent
            while node do
                if node == root then
                    include = true
                    break
                end
                node = node.Parent
            end
        end
        if include and filter then
            include = filter(part)
        end
        if include then
            local kind = "Block"
            if part.ClassName == "WedgePart" then
                kind = "Wedge"
            elseif part.Shape and part.Shape.Name == "Ball" then
                kind = "Ball"
            end
            addSolid(kind, part.CFrame, part.Size)
        end
    end

    for _, fill in ipairs(terrainSolids) do
        addSolid(fill.Kind, fill.CFrame, fill.Size)
    end

    return #solids
end

-- Interval of t (world y offset from origin.Y) where the vertical line hits the solid.
local function clipPlane(t0, t1, a, b)
    -- Keep t where a + b * t <= 0.
    if math.abs(b) < 1e-9 then
        if a > 0 then
            return nil
        end
        return t0, t1
    end
    local t = -a / b
    if b > 0 then
        t1 = math.min(t1, t)
    else
        t0 = math.max(t0, t)
    end
    if t0 > t1 then
        return nil
    end
    return t0, t1
end

local function verticalInterval(solid, x, z)
    local o = solid.Inverse * Vector3.new(x, 0, z)
    local d = solid.Inverse:VectorToWorldSpace(Vector3.new(0, 1, 0))
    local h = solid.Half

    if solid.Kind == "Ball" then
        local r = math.min(h.X, h.Y, h.Z)
        -- |o + d t|^2 <= r^2, d is unit.
        local bq = o:Dot(d)
        local c = o:Dot(o) - r * r
        local disc = bq * bq - c
        if disc < 0 then
            return nil
        end
        local s = math.sqrt(disc)
        return -bq - s, -bq + s
    end

    local t0, t1 = -1e6, 1e6
    for _, axis in ipairs({ "X", "Y", "Z" }) do
        t0, t1 = clipPlane(t0, t1, o[axis] - h[axis], d[axis])
        if not t0 then
            return nil
        end
        t0, t1 = clipPlane(t0, t1, -o[axis] - h[axis], -d[axis])
        if not t0 then
            return nil
        end
    end

    if solid.Kind == "Wedge" then
        -- Solid where y * hz - z * hy <= 0 (high edge at the back, slope facing front).
        t0, t1 = clipPlane(t0, t1, o.Y * h.Z - o.Z * h.Y, d.Y * h.Z - d.Z * h.Y)
        if not t0 then
            return nil
        end
    end

    return t0, t1
end

-- Sorted, merged solid intervals along the vertical line through (x, z).
function Geometry.Column(x, z)
    local bucket = grid[cellKey(math.floor(x / CELL), math.floor(z / CELL))]
    local spans = {}

    if bucket then
        for _, solid in ipairs(bucket) do
            local a, b = verticalInterval(solid, x, z)
            if a and b - a > 0.05 then
                table.insert(spans, { a, b })
            end
        end
    end

    table.sort(spans, function(p, q)
        return p[1] < q[1]
    end)

    local merged = {}
    for _, span in ipairs(spans) do
        local last = merged[#merged]
        if last and span[1] <= last[2] + 0.05 then
            last[2] = math.max(last[2], span[2])
        else
            table.insert(merged, { span[1], span[2] })
        end
    end

    return merged
end

Geometry.Headroom = 5
Geometry.StepUp = 2.4
Geometry.MaxDrop = 40

-- Highest standable surface at (x, z) no higher than maxY, with headroom above it.
function Geometry.GroundBelow(x, z, maxY)
    local column = Geometry.Column(x, z)
    local best = nil

    for index, span in ipairs(column) do
        local top = span[2]
        if top <= maxY then
            local above = column[index + 1]
            if not above or above[1] >= top + Geometry.Headroom then
                best = top
            end
        end
    end

    return best
end

-- Top of the highest surface with headroom anywhere in the column (what a drop from the sky lands on).
function Geometry.TopSurface(x, z)
    return Geometry.GroundBelow(x, z, 1e5)
end

function Geometry.IsBlockedAt(position)
    for _, span in ipairs(Geometry.Column(position.X, position.Z)) do
        if position.Y > span[1] and position.Y < span[2] then
            return true
        end
    end
    return false
end

-- Walks a straight line the way a Humanoid following MoveTo would: it may step up a little,
-- drop down, and needs headroom. Returns ok, and on failure the point where it got stuck.
function Geometry.Walk(from, to, startY)
    local delta = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
    local distance = delta.Magnitude
    local steps = math.max(1, math.ceil(distance))
    local y = startY or Geometry.GroundBelow(from.X, from.Z, from.Y + Geometry.StepUp)

    if not y then
        return false, from, "no ground at start"
    end

    for i = 1, steps do
        local p = from + delta * (i / steps)
        local nextY = Geometry.GroundBelow(p.X, p.Z, y + Geometry.StepUp)

        if not nextY or nextY < y - Geometry.MaxDrop then
            return false, Vector3.new(p.X, y, p.Z), "wall or cliff"
        end

        y = nextY
    end

    return true, Vector3.new(to.X, y, to.Z), nil
end
