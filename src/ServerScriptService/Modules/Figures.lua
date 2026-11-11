--!strict

-- Generic human figures for the game's scenes, and the rule that keeps every figure faceless.
--
-- Companions (sahabah) and townspeople are shown with blank faces: no face decal, no facial
-- features. The Prophet ﷺ is never shown at all. Avatar-based NPCs (like the guide teachers)
-- get their default face removed with StripFaces.

local BuildUtils = require(script.Parent.BuildUtils)

local Figures = {}

local SKIN_TONES = {
    Color3.fromRGB(224, 190, 152),
    Color3.fromRGB(190, 146, 104),
    Color3.fromRGB(150, 106, 70),
    Color3.fromRGB(108, 74, 48),
}

-- Removes every face decal or texture on a figure's head, and any face accessory mesh.
function Figures.StripFaces(model: Instance)
    for _, descendant in ipairs(model:GetDescendants()) do
        if (descendant:IsA("Decal") or descendant:IsA("Texture")) and descendant.Parent and descendant.Parent.Name == "Head" then
            descendant:Destroy()
        elseif descendant:IsA("Accessory") and descendant.AccessoryType == Enum.AccessoryType.Face then
            descendant:Destroy()
        end
    end

    local head = model:FindFirstChild("Head")

    if head and head:IsA("MeshPart") then
        -- Dynamic heads carry their face in the mesh texture; make it plain.
        head.TextureID = ""
    end
end

function Figures.IsFaceless(model: Instance): boolean
    for _, descendant in ipairs(model:GetDescendants()) do
        if (descendant:IsA("Decal") or descendant:IsA("Texture")) and descendant.Parent and descendant.Parent.Name == "Head" then
            return false
        end
    end

    return true
end

-- A simple anchored robed figure with a blank head and head wrap. Decoration only.
function Figures.CreateTownsperson(parent: Instance, name: string, cframe: CFrame, robeColor: Color3): Model
    local model = Instance.new("Model")
    model.Name = name

    local skin = SKIN_TONES[(#name % #SKIN_TONES) + 1]
    local root = BuildUtils.CreatePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), cframe * CFrame.new(0, 3, 0), robeColor, Enum.Material.Fabric, nil, 1)
    root.CanCollide = false
    BuildUtils.CreatePart(model, "Robe", Vector3.new(2.6, 5.2, 1.6), cframe * CFrame.new(0, 2.6, 0), robeColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "Head", Vector3.new(1.3, 1.4, 1.3), cframe * CFrame.new(0, 5.9, 0), skin, Enum.Material.SmoothPlastic, nil, nil)
    BuildUtils.CreatePart(model, "HeadWrap", Vector3.new(1.5, 0.7, 1.5), cframe * CFrame.new(0, 6.6, 0), Color3.fromRGB(232, 224, 206), Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "LeftArm", Vector3.new(0.7, 3, 0.7), cframe * CFrame.new(-1.6, 3.3, 0), robeColor, Enum.Material.Fabric, nil, nil)
    BuildUtils.CreatePart(model, "RightArm", Vector3.new(0.7, 3, 0.7), cframe * CFrame.new(1.6, 3.3, 0), robeColor, Enum.Material.Fabric, nil, nil)

    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
        end
    end

    model.PrimaryPart = root
    model:SetAttribute("Faceless", true)
    model.Parent = parent

    return model
end

return Figures
