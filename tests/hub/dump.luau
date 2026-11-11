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
