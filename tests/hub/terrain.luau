-- Terrain fills (recorded by the mock engine) as stand-ins for parts, so checks that look
-- for solid things in the way also see Roblox Terrain. `builtTerrain` holds the fills made by
-- the world builders (dunes and rock in the hub and arenas, ridges around the towns);
-- `worldTerrain` holds the land around the play areas from WorldTerrain.server.lua.
local function proxy(index, fill)
    local name = "Terrain fill " .. index .. " (" .. (fill.Material and fill.Material.Name or "?") .. " " .. fill.Kind .. ")"
    return {
        Name = name,
        ClassName = if fill.Kind == "Wedge" then "WedgePart" else "Part",
        CFrame = fill.CFrame,
        Position = fill.CFrame.Position,
        Size = fill.Size,
        Shape = { Name = if fill.Kind == "Ball" then "Ball" elseif fill.Kind == "Cylinder" then "Cylinder" else "Block" },
        CanCollide = true,
        Transparency = 0,
        Material = fill.Material,
        IsA = function(_, className)
            return className == "BasePart" or className == "Part"
        end,
        GetFullName = function()
            return name
        end,
        IsDescendantOf = function()
            return false
        end,
    }
end

builtTerrain, worldTerrain = {}, {}
local worldFrom = mock.worldTerrainFrom or (#mock.terrain + 1)
for index, fill in ipairs(mock.terrain) do
    if not (fill.Material and fill.Material.Name == "Air") then
        table.insert(if index >= worldFrom then worldTerrain else builtTerrain, proxy(index, fill))
    end
end

-- True if `point` is inside `part` (a part or a terrain stand-in), widened sideways by `pad`.
-- Balls, cylinders and wedges use their real shape; everything else is a box.
function solidAt(part, point, pad)
    local l = part.CFrame:PointToObjectSpace(point)
    local s = part.Size / 2
    local shape = part.Shape and part.Shape.Name
    if shape == "Ball" then
        return l.Magnitude < math.min(s.X, s.Y, s.Z) + pad
    elseif shape == "Cylinder" then
        local r = math.min(s.Y, s.Z) + pad
        return math.abs(l.X) < s.X and l.Y * l.Y + l.Z * l.Z < r * r
    elseif part.ClassName == "WedgePart" then
        if math.abs(l.X) >= s.X + pad or math.abs(l.Z) >= s.Z + pad or l.Y <= -s.Y then
            return false
        end
        local z = math.min(l.Z + pad, s.Z)
        return l.Y < -s.Y + part.Size.Y * (z + s.Z) / part.Size.Z
    end
    return math.abs(l.X) < s.X + pad and math.abs(l.Y) < s.Y and math.abs(l.Z) < s.Z + pad
end
