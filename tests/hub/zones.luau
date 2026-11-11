-- Checks on the activity zones built outside the hub: the historical Seerah towns, the Sahabi
-- mystery wing, the co-op trials, and the PvP training grounds (see run.sh).
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SeerahCampaign = require(Shared.Data.SeerahCampaign)
local HistoricalSites = require(Shared.Data.HistoricalSites)
local SahabiMysteries = require(Shared.Data.SahabiMysteries)
local zoneFailures = 0

local function zcheck(ok, message)
    if ok then
        print("ok   " .. message)
    else
        zoneFailures += 1
        print("FAIL " .. message)
    end
end

local function stats(root)
    local parts = 0
    local lo = Vector3.new(math.huge, math.huge, math.huge)
    local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("BasePart") then
            parts += 1
            local p = item.Position
            lo = Vector3.new(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z))
            hi = Vector3.new(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z))
        end
    end
    return parts, lo, hi
end

local zones = {
    { Name = HistoricalSites.FolderName, Budget = 15000 },
    { Name = "MysteryWing", Budget = 2500 },
    { Name = "CoopTrials", Budget = 400 },
    { Name = "TrainingGrounds", Budget = 1000 },
}
local boxes = {}

for _, zone in ipairs(zones) do
    local folder = Workspace:FindFirstChild(zone.Name)
    zcheck(folder ~= nil and folder:GetAttribute("Built") == true, zone.Name .. " is built")
    if folder then
        local parts, lo, hi = stats(folder)
        print(string.format("info %-16s %5d parts, x %.0f..%.0f, z %.0f..%.0f", zone.Name, parts, lo.X, hi.X, lo.Z, hi.Z))
        zcheck(parts <= zone.Budget, string.format("%s stays under %d parts", zone.Name, zone.Budget))
        -- The hub (present-day Makkah and Madinah) stays inside about +/-2400 studs.
        zcheck(math.min(math.abs(lo.X), math.abs(hi.X)) > 2600 and lo.X * hi.X > 0, zone.Name .. " is kept apart from the present-day hub")
        table.insert(boxes, { Name = zone.Name, Lo = lo, Hi = hi })
    end
end

for i = 1, #boxes do
    for j = i + 1, #boxes do
        local a, b = boxes[i], boxes[j]
        local overlap = a.Lo.X < b.Hi.X and b.Lo.X < a.Hi.X and a.Lo.Z < b.Hi.Z and b.Lo.Z < a.Hi.Z
        zcheck(not overlap, a.Name .. " and " .. b.Name .. " do not overlap")
    end
end

local historical = Workspace:FindFirstChild(HistoricalSites.FolderName)
if historical then
    local missingRings, badItems = {}, {}
    for _, site in ipairs(HistoricalSites.Sites) do
        local found = false
        for _, item in ipairs(historical:GetDescendants()) do
            if item.Name == site.Id and item:FindFirstChild("ChapterRing") then
                found = true
                break
            end
        end
        if not found then
            table.insert(missingRings, site.Id)
        end
    end
    zcheck(#missingRings == 0, "every Seerah site has a chapter ring" .. (#missingRings > 0 and (": " .. table.concat(missingRings, ", ")) or ""))

    local items = historical:FindFirstChild("CampaignItems")
    for _, chapter in ipairs(SeerahCampaign.Chapters) do
        if chapter.Activity and chapter.Activity.Kind == "Collect" then
            local folder = items and items:FindFirstChild(chapter.Id)
            local count = 0
            if folder then
                for _, item in ipairs(folder:GetChildren()) do
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if item:IsA("BasePart") and prompt and item:GetAttribute("ChapterId") == chapter.Id then
                        count += 1
                    end
                end
            end
            if count ~= chapter.Activity.Count then
                table.insert(badItems, string.format("%s (%d/%d)", chapter.Id, count, chapter.Activity.Count))
            end
        end
    end
    zcheck(#badItems == 0, "every collect chapter has its items with prompts" .. (#badItems > 0 and (": " .. table.concat(badItems, ", ")) or ""))

    -- Dense towns must not wall off any place a player has to stand: every arrival point,
    -- travel point and campaign item must be free of colliding parts at body height.
    local solids = {}
    for _, part in ipairs(historical:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 and part.Name ~= "Ground" then
            table.insert(solids, part)
        end
    end

    local function blockedBy(point)
        for _, part in ipairs(solids) do
            local localPoint = part.CFrame:PointToObjectSpace(point)
            local h = part.Size / 2
            if math.abs(localPoint.X) < h.X + 1 and math.abs(localPoint.Y) < h.Y and math.abs(localPoint.Z) < h.Z + 1 then
                return part
            end
        end
        return nil
    end

    local blocked = {}
    local function probe(label, point)
        for _, lift in ipairs({ 1.5, 3.5 }) do
            local hit = blockedBy(point + Vector3.new(0, lift, 0))
            if hit then
                table.insert(blocked, string.format("%s (%s)", label, hit:GetFullName()))
                return
            end
        end
    end

    for _, site in ipairs(HistoricalSites.Sites) do
        local arrival = HistoricalSites.ArrivalPoint(site)
        probe(site.Id .. " arrival", arrival)
        if site.Kind ~= "Mountain" then
            probe(site.Id .. " travel point", arrival + Vector3.new(0, 0, -42))
        end
    end

    if items then
        for _, folder in ipairs(items:GetChildren()) do
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("BasePart") then
                    probe(folder.Name .. "/" .. item.Name, item.Position - Vector3.new(0, 1.2, 0))
                end
            end
        end
    end

    -- No large non-colliding scenery (ridges, groves, canopies) surrounds a player's eye at
    -- any arrival ring or within 20 studs of it.
    local sceneryParts = {}
    for _, part in ipairs(historical:GetDescendants()) do
        if part:IsA("BasePart") and not part.CanCollide and part.Transparency < 0.5 and part.Size.Magnitude > 30 then
            table.insert(sceneryParts, part)
        end
    end
    local buried = {}
    for _, site in ipairs(HistoricalSites.Sites) do
        local arrival = HistoricalSites.ArrivalPoint(site)
        for step = -1, 7 do
            local probe = if step < 0 then arrival else arrival + Vector3.new(math.cos(step * math.pi / 4) * 20, 0, math.sin(step * math.pi / 4) * 20)
            local eye = probe + Vector3.new(0, 5, 0)
            local hit = nil
            for _, part in ipairs(sceneryParts) do
                local l = part.CFrame:PointToObjectSpace(eye)
                local h = part.Size / 2
                if math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
                    hit = part
                    break
                end
            end
            if hit then
                table.insert(buried, string.format("%s (%s)", site.Id, hit:GetFullName()))
                break
            end
        end
    end
    zcheck(#buried == 0, "no Seerah site is buried in scenery" .. (#buried > 0 and (": " .. table.concat(buried, "; ")) or ""))

    -- Every historical site has a fire within 30 studs of its arrival ring, for night play.
    local fires = {}
    for _, light in ipairs(historical:GetDescendants()) do
        if light:IsA("Light") and light.Parent and light.Parent:IsA("BasePart") then
            table.insert(fires, light.Parent.Position)
        end
    end
    local dark = {}
    for _, site in ipairs(HistoricalSites.Sites) do
        local arrival = HistoricalSites.ArrivalPoint(site)
        local lit = false
        for _, position in ipairs(fires) do
            if (position - arrival).Magnitude < 30 then
                lit = true
                break
            end
        end
        if not lit then
            table.insert(dark, site.Id)
        end
    end
    zcheck(#dark == 0, "every historical site is lit at night" .. (#dark > 0 and (": " .. table.concat(dark, ", ")) or ""))

    zcheck(#blocked == 0, "every arrival point, travel point and campaign item is free of walls" .. (#blocked > 0 and (": " .. table.concat(blocked, "; ")) or ""))
    zcheck((historical:GetAttribute("MakkahHouses") or 0) >= 40 and (historical:GetAttribute("MadinahHouses") or 0) >= 25, string.format("historical towns are dense (Makkah %s houses, Madinah %s)", tostring(historical:GetAttribute("MakkahHouses")), tostring(historical:GetAttribute("MadinahHouses"))))
end

local wing = Workspace:FindFirstChild("MysteryWing")
if wing then
    local missing = {}
    for _, mystery in ipairs(SahabiMysteries.Mysteries) do
        local room = wing:FindFirstChild(mystery.Id)
        local clues = 0
        if room then
            for _, item in ipairs(room:GetDescendants()) do
                if string.sub(item.Name, 1, 5) == "Clue_" then
                    clues += 1
                end
            end
        end
        if not room or not room:FindFirstChild("LockDoor", true) or clues ~= #mystery.Clues then
            table.insert(missing, mystery.Id)
        end
    end
    zcheck(#missing == 0, "every mystery room has its clues and a locked door" .. (#missing > 0 and (": " .. table.concat(missing, ", ")) or ""))
end

-- A part built with a nil colour errors on a real server, so every part must have one.
local uncoloured = {}
for _, part in ipairs(Workspace:GetDescendants()) do
    if part:IsA("BasePart") and part.Color == nil and #uncoloured < 5 then
        table.insert(uncoloured, part:GetFullName())
    end
end
zcheck(#uncoloured == 0, "every part has a colour" .. (#uncoloured > 0 and (": " .. table.concat(uncoloured, ", ")) or ""))

-- Walking routes inside the activity zones: from each landing point to where the activity
-- happens, a body-sized column (2 to 5 studs above the floor, so small steps are allowed) stays
-- clear of colliding parts the whole way.
do
    local TravelRoute = require(game:GetService("ReplicatedStorage").Shared.Data.TravelRoute)
    local SahabiMysteries = require(game:GetService("ReplicatedStorage").Shared.Data.SahabiMysteries)
    local solids = {}
    for _, name in ipairs({ "MysteryWing", "TrainingGrounds", "CoopTrials" }) do
        local zone = game:GetService("Workspace"):FindFirstChild(name)
        if zone then
            for _, part in ipairs(zone:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 then
                    table.insert(solids, part)
                end
            end
        end
    end
    local function blocker(point)
        for _, part in ipairs(solids) do
            local l = part.CFrame:PointToObjectSpace(point)
            local h = part.Size / 2
            if math.abs(l.X) < h.X + 0.8 and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z + 0.8 then
                return part
            end
        end
        return nil
    end
    local function walk(points, label)
        for leg = 1, #points - 1 do
            local a, b = points[leg], points[leg + 1]
            local steps = math.ceil((b - a).Magnitude / 2)
            for i = 0, steps do
                local p = a:Lerp(b, i / steps)
                for dy = 2, 5 do
                    local hit = blocker(p + Vector3.new(0, dy, 0))
                    if hit then
                        zcheck(false, string.format("%s is walkable (blocked by %s near %s)", label, hit:GetFullName(), tostring(p)))
                        return
                    end
                end
            end
        end
        zcheck(true, label .. " is walkable")
    end
    local function landing(id)
        local d = TravelRoute.GetDestinationById(id)
        local at = d.TeleportPosition or d.Position
        return Vector3.new(at.X, 4, at.Z)
    end

    local arena = landing("training_grounds")
    walk({ arena, Vector3.new(4000, 4, -1900) }, "Training Grounds landing to the centre of the ring")

    local wing = landing("mystery_wing")
    for index, mystery in ipairs(SahabiMysteries.Mysteries) do
        local x = -4000 + (index - (#SahabiMysteries.Mysteries + 1) / 2) * 260
        walk({ wing, Vector3.new(wing.X, 4, -110), Vector3.new(x, 4, -110), Vector3.new(x, 4, -52) }, "mystery lobby through the door of " .. mystery.Id .. "'s room")
    end

    local coop = landing("coop_trials")
    walk({ coop, Vector3.new(-4000, 4, 1490 + 6) }, "Co-op landing to the start rugs")
end

if zoneFailures > 0 then
    error(string.format("%d zone check(s) failed", zoneFailures))
end
print("All zone checks passed.")
