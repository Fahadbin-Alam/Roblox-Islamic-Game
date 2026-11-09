-- Prints every visible part of the generated world as one line for tests/hub/render.py.
local world = game:GetService("Workspace"):FindFirstChild("GeneratedHub") or game:GetService("Workspace")

for _, part in ipairs(world:GetDescendants()) do
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
            "PART|%s|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.5f|%.3f|%.3f|%.3f|%.3f|%s|%d",
            part.Name, part.Size.X, part.Size.Y, part.Size.Z,
            c.px, c.py, c.pz, c.r00, c.r01, c.r02, c.r10, c.r11, c.r12, c.r20, c.r21, c.r22,
            part.Color.R, part.Color.G, part.Color.B, part.Transparency, shape, glow
        ))
    end
end
