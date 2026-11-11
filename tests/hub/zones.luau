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
            -- The 42-stud walk from the travel point to the chapter ring is open all the way.
            for step = 1, 13 do
                local before = #blocked
                probe(site.Id .. " walk from travel point", arrival + Vector3.new(0, 0, -42 + step * 3))
                if #blocked > before then
                    break
                end
            end
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
    for _, z in ipairs({ 1, -1 }) do
        walk({ Vector3.new(4000, 4, -1900 + z * 175), Vector3.new(4000, 4, -1900 + z * 100) }, string.format("Training Grounds gate at z %+d from the desert", z * 140))
    end

    local wing = landing("mystery_wing")
    for index, mystery in ipairs(SahabiMysteries.Mysteries) do
        local x = -4000 + (index - (#SahabiMysteries.Mysteries + 1) / 2) * 260
        walk({ wing, Vector3.new(wing.X, 4, -170), Vector3.new(wing.X, 4, -110), Vector3.new(x, 4, -110), Vector3.new(x, 4, -52) }, "mystery lobby through the door of " .. mystery.Id .. "'s room")
    end

    local coop = landing("coop_trials")
    walk({ coop, Vector3.new(-4000, 4, 1515) }, "Co-op landing to the first stage")
end

-- Every Seerah site (except the mountain caves) can be reached on foot from its town's
-- arrival point: a path search on a 3-stud grid through the streets, where a cell is blocked
-- if a colliding part fills the body's height (1.7 to 5 studs above the ground) there.
if historical then
    local TravelRoute = require(game:GetService("ReplicatedStorage").Shared.Data.TravelRoute)
    local GT = HistoricalSites.GroundTop
    local CELL = 3
    for _, entry in ipairs({ { Zone = "makkah_610", From = "seerah_campaign" }, { Zone = "madinah_622", From = "seerah_madinah" } }) do
        local zone = HistoricalSites.GetZone(entry.Zone)
        local folder = historical:FindFirstChild(entry.Zone)
        local half = zone.Size.X / 2
        local n = math.floor(zone.Size.X / CELL)
        local origin = zone.Center - Vector3.new(half, 0, half)
        local blocked = {}
        local function key(i, j)
            return i * (n + 1) + j
        end
        for _, part in ipairs(folder and folder:GetDescendants() or {}) do
            if part:IsA("BasePart") and part.CanCollide and part.Transparency < 1 and part.Name ~= "Ground" then
                local cf, size = part.CFrame, part.Size
                local r = cf.RightVector * size.X / 2
                local u = cf.UpVector * size.Y / 2
                local b = cf.LookVector * size.Z / 2
                local ext = Vector3.new(
                    math.abs(r.X) + math.abs(u.X) + math.abs(b.X),
                    math.abs(r.Y) + math.abs(u.Y) + math.abs(b.Y),
                    math.abs(r.Z) + math.abs(u.Z) + math.abs(b.Z)
                )
                local low, high = cf.Position.Y - ext.Y, cf.Position.Y + ext.Y
                if high > GT + 1.7 and low < GT + 5 then
                    local i0 = math.max(0, math.floor((cf.Position.X - ext.X - 1 - origin.X) / CELL))
                    local i1 = math.min(n, math.ceil((cf.Position.X + ext.X + 1 - origin.X) / CELL))
                    local j0 = math.max(0, math.floor((cf.Position.Z - ext.Z - 1 - origin.Z) / CELL))
                    local j1 = math.min(n, math.ceil((cf.Position.Z + ext.Z + 1 - origin.Z) / CELL))
                    for i = i0, i1 do
                        for j = j0, j1 do
                            local k = key(i, j)
                            if not blocked[k] then
                                local hits = false
                                for _, dy in ipairs({ 2, 3.5, 4.8 }) do
                                    local l = cf:PointToObjectSpace(Vector3.new(origin.X + i * CELL, GT + dy, origin.Z + j * CELL))
                                    if math.abs(l.X) < size.X / 2 + 1 and math.abs(l.Y) < size.Y / 2 and math.abs(l.Z) < size.Z / 2 + 1 then
                                        hits = true
                                        break
                                    end
                                end
                                if hits then
                                    blocked[k] = true
                                end
                            end
                        end
                    end
                end
            end
        end

        local function cellOf(position)
            return math.floor((position.X - origin.X) / CELL + 0.5), math.floor((position.Z - origin.Z) / CELL + 0.5)
        end
        local landing = TravelRoute.GetDestinationById(entry.From)
        local si, sj = cellOf(landing.TeleportPosition or landing.Position)
        local seen = { [key(si, sj)] = true }
        local queue, head = { { si, sj } }, 1
        while head <= #queue do
            local i, j = queue[head][1], queue[head][2]
            head += 1
            for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                local a, c = i + d[1], j + d[2]
                if a >= 0 and a <= n and c >= 0 and c <= n then
                    local k = key(a, c)
                    if not seen[k] and not blocked[k] then
                        seen[k] = true
                        table.insert(queue, { a, c })
                    end
                end
            end
        end

        local stranded = {}
        for _, site in ipairs(HistoricalSites.Sites) do
            if site.Zone == entry.Zone and site.Kind ~= "Mountain" then
                local i, j = cellOf(HistoricalSites.ArrivalPoint(site))
                local reached = false
                for di = -1, 1 do
                    for dj = -1, 1 do
                        if seen[key(i + di, j + dj)] then
                            reached = true
                        end
                    end
                end
                if not reached then
                    table.insert(stranded, site.Id)
                end
            end
        end
        zcheck(#stranded == 0, string.format("every %s site can be reached on foot from the town arrival (%d cells open)", entry.Zone, #queue) .. (#stranded > 0 and (": " .. table.concat(stranded, ", ")) or ""))
    end
end

-- The Badr and Uhud battle arenas share the Workspace with the hub, so no visible hub part may
-- stand inside an arena's play space (its floor footprint, from the floor up to 80 studs).
do
    local arenas = Workspace:FindFirstChild("GeneratedBattles")
    local hub = Workspace:FindFirstChild("GeneratedHub")
    local function aabb(part)
        local cf, size = part.CFrame, part.Size
        local r = cf.RightVector * size.X / 2
        local u = cf.UpVector * size.Y / 2
        local b = cf.LookVector * size.Z / 2
        local ext = Vector3.new(math.abs(r.X) + math.abs(u.X) + math.abs(b.X), math.abs(r.Y) + math.abs(u.Y) + math.abs(b.Y), math.abs(r.Z) + math.abs(u.Z) + math.abs(b.Z))
        return cf.Position - ext, cf.Position + ext
    end
    zcheck(arenas ~= nil and #arenas:GetChildren() >= 2, "both battle arenas are built")
    if arenas and hub then
        for _, arena in ipairs(arenas:GetChildren()) do
            local floor = arena:FindFirstChild("BaseFloor", true)
            if floor then
                local lo, hi = aabb(floor)
                hi = Vector3.new(hi.X, hi.Y + 80, hi.Z)
                lo = Vector3.new(lo.X, hi.Y - 80 + 0.2, lo.Z)
                local intruders, seen = {}, {}
                for _, part in ipairs(hub:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency < 0.5 then
                        local plo, phi = aabb(part)
                        if plo.X < hi.X and phi.X > lo.X and plo.Y < hi.Y and phi.Y > lo.Y and plo.Z < hi.Z and phi.Z > lo.Z then
                            local top = part
                            while top.Parent and top.Parent ~= hub and top.Parent.Parent ~= hub do
                                top = top.Parent
                            end
                            if not seen[top.Name] and #intruders < 8 then
                                seen[top.Name] = true
                                table.insert(intruders, top.Name)
                            end
                        end
                    end
                end
                zcheck(#intruders == 0, string.format("no hub scenery inside the %s arena", arena.Name) .. (#intruders > 0 and (": " .. table.concat(intruders, ", ")) or ""))
            end
        end
    end
end

-- Z-fighting: two visible, upright blocks whose tops sit at the same height, overlap, and look
-- different (colour or material) flicker in Roblox as the camera moves. Covers the whole world.
do
    local byTop = {}
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item.ClassName == "Part" and (item.Shape == nil or item.Shape.Name == "Block") and (item.Transparency or 0) < 0.9 then
            local cf = item.CFrame
            local up = cf.UpVector
            local right = cf.RightVector
            if math.abs(up.Y) > 0.999 and (math.abs(right.X) > 0.999 or math.abs(right.Z) > 0.999) then
                local size = item.Size
                local sx, sz = size.X, size.Z
                if math.abs(right.Z) > 0.999 then
                    sx, sz = sz, sx
                end
                if sx * sz > 16 then
                    local p = cf.Position
                    local key = math.floor((p.Y + size.Y / 2) * 100 + 0.5)
                    byTop[key] = byTop[key] or {}
                    table.insert(byTop[key], { item, p.X - sx / 2, p.X + sx / 2, p.Z - sz / 2, p.Z + sz / 2 })
                end
            end
        end
    end
    local found, seen = {}, {}
    for key, list in pairs(byTop) do
        -- Bucket on a 64-stud grid so each pair is compared only when near.
        local cells = {}
        for index, entry in ipairs(list) do
            for cx = math.floor(entry[2] / 64), math.floor(entry[3] / 64) do
                for cz = math.floor(entry[4] / 64), math.floor(entry[5] / 64) do
                    local cell = cx .. ":" .. cz
                    cells[cell] = cells[cell] or {}
                    table.insert(cells[cell], index)
                end
            end
        end
        for _, members in pairs(cells) do
            for i = 1, #members do
                for j = i + 1, #members do
                    local a, b = list[members[i]], list[members[j]]
                    local ix = math.min(a[3], b[3]) - math.max(a[2], b[2])
                    local iz = math.min(a[5], b[5]) - math.max(a[4], b[4])
                    if ix > 0 and iz > 0 and ix * iz > 16 then
                        local pa, pb = a[1], b[1]
                        local ca, cb = pa.Color, pb.Color
                        local tint = math.abs(ca.R - cb.R) + math.abs(ca.G - cb.G) + math.abs(ca.B - cb.B)
                        if tint > 0.01 or tostring(pa.Material and pa.Material.Name) ~= tostring(pb.Material and pb.Material.Name) then
                            local label = string.format("%s / %s at y=%.2f (%.0f sq studs)", (string.gsub(pa:GetFullName(), "^game%.Workspace%.", "")), pb.Name, key / 100, ix * iz)
                            if not seen[label] then
                                seen[label] = true
                                table.insert(found, label)
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(found)
    local shown = {}
    for i = 1, math.min(#found, 40) do
        shown[i] = found[i]
    end
    zcheck(#found == 0, string.format("no coplanar overlapping surfaces flicker (%d found)", #found) .. (#found > 0 and (": " .. table.concat(shown, "; ")) or ""))
end

if zoneFailures > 0 then
    error(string.format("%d zone check(s) failed", zoneFailures))
end
print("All zone checks passed.")
