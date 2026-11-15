-- Prints every visible part of the generated world as one line for tests/hub/render.py.
-- DUMP_ALL (set by run.sh --dump-all) prints the whole Workspace: hub plus activity zones.
local workspaceRoot = game:GetService("Workspace")
local world = if DUMP_ALL then workspaceRoot else (workspaceRoot:FindFirstChild("GeneratedHub") or workspaceRoot)

for _, part in ipairs(world:GetDescendants()) do
    if part:IsA("BasePart") and part.Color == nil then
        error("part without a colour: " .. part:GetFullName())
    end
    if part:IsA("BasePart") and part.Transparency < 0.98 then
        local c = part.CFrame
        local shape = part.Shape and part.Shape.Name or "Block"
        if part.ClassName == "WedgePart" then
            shape = "Wedge"
        end
        local glow = 0
        if part.Material and part.Material.Name == "Neon" then
            glow = 1
        end
        print(string.format(
            "PART|%s|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.3f|%.3f|%.3f|%.3f|%s|%d|%s",
            part.Name, part.Size.X, part.Size.Y, part.Size.Z,
            c.px, c.py, c.pz, c.r00, c.r01, c.r02, c.r10, c.r11, c.r12, c.r20, c.r21, c.r22,
            part.Color.R, part.Color.G, part.Color.B, part.Transparency, shape, glow, part.Material and part.Material.Name or "Plastic"
        ))
    end
    if part.ClassName == "PointLight" and part.Parent and part.Parent:IsA("BasePart") and part.Enabled ~= false then
        local at = part.Parent.Position
        print(string.format("LIGHT|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f", at.X, at.Y, at.Z, part.Color.R, part.Color.G, part.Color.B, part.Brightness, part.Range))
    end
end

-- Terrain fills, drawn as parts in the colour Roblox gives each terrain material.
local TERRAIN_COLOURS = {
    Sand = { 0.84, 0.74, 0.55 }, Sandstone = { 0.76, 0.62, 0.45 }, Rock = { 0.50, 0.45, 0.40 },
    Grass = { 0.42, 0.55, 0.30 }, LeafyGrass = { 0.40, 0.54, 0.28 }, Mud = { 0.45, 0.36, 0.27 },
    Ground = { 0.55, 0.45, 0.33 }, Water = { 0.20, 0.42, 0.50 }, Limestone = { 0.82, 0.78, 0.68 },
    Basalt = { 0.25, 0.24, 0.24 }, Slate = { 0.40, 0.40, 0.38 }, Salt = { 0.92, 0.90, 0.86 },
}
if DUMP_ALL or true then
    for index, fill in ipairs(mock.terrain or {}) do
        local name = fill.Material and fill.Material.Name or "Ground"
        if name ~= "Air" then
            local colour = TERRAIN_COLOURS[name] or { 0.6, 0.5, 0.4 }
            local c = fill.CFrame
            if name == "Water" then
                -- The renderer cannot carve Air out of earlier fills, so a pool sunk into grass is
                -- drawn a stud higher to show above the grass it replaced.
                c = c + Vector3.new(0, 1, 0)
            end
            local transparency = if name == "Water" then 0.3 else 0

            if fill.Kind == "Block" and math.max(fill.Size.X, fill.Size.Z) > 1000 then
                -- A huge flat block (the sand floor under the map) is drawn as tiles of its top face:
                -- one polygon thousands of studs wide does not project well.
                local TILE = 400
                -- Drawn a little low, so terrain laid into its surface (grass, pools) shows.
                local top = c.py + fill.Size.Y / 2 - 1.5
                for tx = c.px - fill.Size.X / 2, c.px + fill.Size.X / 2 - 1, TILE do
                    for tz = c.pz - fill.Size.Z / 2, c.pz + fill.Size.Z / 2 - 1, TILE do
                        print(string.format(
                            "PART|Terrain%s_%d|%.3f|2|%.3f|%.3f|%.3f|%.3f|1|0|0|0|1|0|0|0|1|%.3f|%.3f|%.3f|%.3f|Block|0|%s",
                            name, index, TILE, TILE, tx + TILE / 2, top - 1, tz + TILE / 2,
                            colour[1], colour[2], colour[3], transparency, name
                        ))
                    end
                end
                continue
            end

            print(string.format(
                "PART|Terrain%s_%d|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.3f|%.3f|%.3f|%.3f|%s|%d|%s",
                name, index, fill.Size.X, fill.Size.Y, fill.Size.Z,
                c.px, c.py, c.pz, c.r00, c.r01, c.r02, c.r10, c.r11, c.r12, c.r20, c.r21, c.r22,
                colour[1], colour[2], colour[3], transparency, fill.Kind, 0, name
            ))
        end
    end
end
