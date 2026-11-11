-- Checks on the hub built by HubWorldBuilder inside the mock engine (see run.sh).
local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("GeneratedHub")
local TravelRoute = require(game:GetService("ReplicatedStorage").Shared.Data.TravelRoute)
local failures = 0

local function check(ok, message)
    if ok then
        print("ok   " .. message)
    else
        failures += 1
        print("FAIL " .. message)
    end
end

check(world ~= nil and world:GetAttribute("Built") == true, "hub world folder is built")

local function countParts(root)
    local parts, lights, guis = 0, 0, 0
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("BasePart") then
            parts += 1
        elseif item:IsA("Light") then
            lights += 1
        elseif item.ClassName == "Frame" then
            guis += 1
        end
    end
    return parts, lights, guis
end

local geometry = world:FindFirstChild("Geometry")
local hub = geometry:FindFirstChild("KaabaHub")
local haram = hub:FindFirstChild("MasjidAlHaram")
local totalParts, totalLights = countParts(world)
local haramParts, haramLights, haramFrames = countParts(haram)
print(string.format("info whole hub: %d parts, %d lights", totalParts, totalLights))
print(string.format("info Masjid al-Haram: %d parts, %d lights, %d SurfaceGui frames", haramParts, haramLights, haramFrames))
for _, section in ipairs(haram:GetChildren()) do
    local sectionParts = countParts(section)
    print(string.format("info   %-16s %5d parts", section.Name, sectionParts))
end

-- Budgets keep the hub light enough for phones; raise them deliberately, not by accident.
check(totalParts <= 9000, "whole hub stays within 9000 parts")
check(haramParts <= 5600, "Masjid al-Haram stays within 5600 parts")
check(haramLights <= 90, "Masjid al-Haram uses at most 90 lights")
check(haramFrames <= 3000, "kiswa and sign patterns use at most 3000 SurfaceGui frames")

check(#mock.oversized == 0, "no part is larger than Roblox's 2048-stud limit" .. (#mock.oversized > 0 and (": " .. table.concat(mock.oversized, "; ")) or ""))

-- run.sh sets the clock to 22:00, so HaramTimeService should have switched to night mode.
local lightsOn, lightsTotal = 0, 0
for _, light in ipairs(haram:GetDescendants()) do
    if light:IsA("Light") then
        lightsTotal += 1
        if light.Enabled == true then
            lightsOn += 1
        end
    end
end
check(lightsTotal > 0 and lightsOn == lightsTotal, string.format("all %d night lights are on at 22:00", lightsTotal))
local glowing = mock.service("CollectionService"):GetTagged("HaramNightGlow")
local neon = 0
for _, item in ipairs(glowing) do
    if item.Material.Name == "Neon" then
        neon += 1
    end
end
check(#glowing > 0 and neon == #glowing, "clock dials, lanterns and sa'i lights glow at night")

-- Clock hands were turned to Makkah time and stay on their dial.
local handsOk = true
for _, hand in ipairs(mock.service("CollectionService"):GetTagged("HaramClockHand")) do
    local pivot = hand:GetAttribute("Pivot")
    local offset = hand:GetAttribute("Offset")
    local fromPivot = (hand.CFrame.Position - pivot.Position).Magnitude
    if math.abs(fromPivot - offset) > 0.01 or math.abs(pivot:PointToObjectSpace(hand.CFrame.Position).Z) > 0.01 then
        handsOk = false
    end
end
check(handsOk, "clock hands turn about the dial centre")

-- Landmarks the learning trail and lessons refer to.
for _, name in ipairs({ "Kaaba", "HijrIsmail", "MaqamIbrahim", "MatafExpansion", "OttomanRiwaq", "Masa", "Minarets", "AbrajAlBait", "Gates" }) do
    check(haram:FindFirstChild(name) ~= nil, "builds " .. name)
end
local minaretCount = #haram:FindFirstChild("Minarets"):GetChildren()
check(minaretCount == 13, string.format("has 13 minarets like today's mosque (found %d)", minaretCount))
check(#mock.service("CollectionService"):GetTagged("HaramClockHand") == 8, "four clock faces with hour and minute hands")

local trail = hub:FindFirstChild("HaramLearningTrail")
local stops = 0
for _, child in ipairs(trail:GetChildren()) do
    if child.Name:match("^LearningTrailStop_") then
        stops += 1
    end
end
check(stops == 6, "learning trail has 6 stops")

-- Geometry helpers.
local center = Vector3.new(0, 4, 0)

local function corners(part)
    local s = part.Size * 0.5
    local result = {}
    for _, x in ipairs({ -1, 1 }) do
        for _, y in ipairs({ -1, 1 }) do
            for _, z in ipairs({ -1, 1 }) do
                table.insert(result, part.CFrame * Vector3.new(s.X * x, s.Y * y, s.Z * z))
            end
        end
    end
    return result
end

local function bounds(part)
    local lo = Vector3.new(math.huge, math.huge, math.huge)
    local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, c in ipairs(corners(part)) do
        lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
        hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
    end
    return lo, hi
end

local function pointInside(part, point)
    local localPoint = part.CFrame:PointToObjectSpace(point)
    local s = part.Size * 0.5
    if part.Shape and part.Shape.Name == "Cylinder" then
        local r = math.min(s.Y, s.Z)
        return math.abs(localPoint.X) <= s.X and (localPoint.Y ^ 2 + localPoint.Z ^ 2) <= r * r
    elseif part.Shape and part.Shape.Name == "Ball" then
        local r = math.min(s.X, s.Y, s.Z)
        return localPoint.Magnitude <= r
    end
    return math.abs(localPoint.X) <= s.X and math.abs(localPoint.Y) <= s.Y and math.abs(localPoint.Z) <= s.Z
end

local collidable = {}
for _, item in ipairs(world:GetDescendants()) do
    if item:IsA("BasePart") and item.CanCollide and item.Transparency < 1 then
        table.insert(collidable, item)
    end
end
-- The battle arenas share the Workspace, and their invisible safety walls block players too.
local battles = game:GetService("Workspace"):FindFirstChild("GeneratedBattles")
for _, item in ipairs(battles and battles:GetDescendants() or {}) do
    if item:IsA("BasePart") and item.CanCollide then
        table.insert(collidable, item)
    end
end

-- Body-sized column of space a player needs (feet slightly above the floor).
local function blockedAt(position, height)
    for _, part in ipairs(collidable) do
        for dy = 1, height, 1 do
            if pointInside(part, position + Vector3.new(0, dy, 0)) then
                return part.Name
            end
        end
    end
    return nil
end

local floorY = center.Y + 6.6

-- Arrival spawn, guides and the leaderboard stand on open floor.
for _, spot in ipairs({
    { "arrival spawn", Vector3.new(0, floorY, 92) },
    { "Haram guide", Vector3.new(16, floorY, 98) },
    { "leaderboard", Vector3.new(-30, floorY, 96) },
}) do
    local blocker = blockedAt(spot[2], 6)
    check(blocker == nil, spot[1] .. " area is clear" .. (blocker and (" (blocked by " .. blocker .. ")") or ""))
end

-- A walk along the tawaf circle (radius 110) never hits a wall.
local tawafBlocked = nil
for step = 0, 71 do
    local a = step / 72 * math.pi * 2
    local blocker = blockedAt(center + Vector3.new(math.cos(a) * 110, 6.6, math.sin(a) * 110), 5)
    if blocker then
        tawafBlocked = blocker
        break
    end
end
check(tawafBlocked == nil, "tawaf circle around the Kaaba is open" .. (tawafBlocked and (" (blocked by " .. tawafBlocked .. ")") or ""))

-- Players can walk out of the mosque at ground level through each named gate.
local function walkable(from, to, label)
    local distance = (to - from).Magnitude
    local steps = math.ceil(distance / 3)
    for i = 0, steps do
        local p = from:Lerp(to, i / steps)
        local blocker = blockedAt(p, 5)
        if blocker then
            check(false, label .. " is walkable (blocked by " .. blocker .. " near " .. tostring(p) .. ")")
            return
        end
    end
    check(true, label .. " is walkable")
end
walkable(Vector3.new(0, floorY, 180), Vector3.new(0, floorY, 760), "north route through King Abdullah Gate to the Medina road")

-- Each promenade from the edge of the Haram terrace leads to its court or gate on foot. The
-- walker follows the floor: at each step it stands on the highest surface it can step onto
-- (at most 3 studs up), and the space for its body there must be clear.
local function surfaceTop(part, x, z)
    if math.abs(part.CFrame.UpVector.Y) < 0.99 then
        return nil
    end
    local l = part.CFrame:PointToObjectSpace(Vector3.new(x, part.Position.Y, z))
    local h = part.Size / 2
    if math.abs(l.X) > h.X or math.abs(l.Z) > h.Z then
        return nil
    end
    if part.ClassName == "WedgePart" then
        return part.Position.Y - h.Y + part.Size.Y * (l.Z + h.Z) / part.Size.Z
    end
    return part.Position.Y + h.Y
end

local function walkOnFloor(points, label)
    local feet = points[1].Y
    local samples = {}
    for leg = 1, #points - 1 do
        local from, to = Vector3.new(points[leg].X, 0, points[leg].Z), Vector3.new(points[leg + 1].X, 0, points[leg + 1].Z)
        local steps = math.ceil((to - from).Magnitude / 2)
        for i = 0, steps do
            table.insert(samples, from:Lerp(to, i / steps))
        end
    end
    for _, p in ipairs(samples) do
        local best = nil
        for _, part in ipairs(collidable) do
            local top = surfaceTop(part, p.X, p.Z)
            if top and top <= feet + 3 and top >= feet - 30 and (best == nil or top > best) then
                best = top
            end
        end
        feet = best or feet
        local blocker = nil
        for _, part in ipairs(collidable) do
            -- Anything whose top the walker can step onto is a step, not a wall.
            local stepTop = surfaceTop(part, p.X, p.Z) or (part.Position.Y + part.Size.Y / 2)
            if stepTop > feet + 3 or math.abs(part.CFrame.UpVector.Y) < 0.99 then
                for dy = 1, 5 do
                    if pointInside(part, Vector3.new(p.X, feet + dy, p.Z)) then
                        blocker = part.Name
                        break
                    end
                end
            end
            if blocker then
                break
            end
        end
        if blocker then
            check(false, label .. " is walkable (blocked by " .. blocker .. " near " .. tostring(p) .. ")")
            return
        end
    end
    check(true, label .. " is walkable")
end

local function v(x, z)
    return Vector3.new(x, 7.5, z)
end
walkOnFloor({ v(714, 220), v(920, 220) }, "promenade into the story court")
walkOnFloor({ v(714, -240), v(920, -240) }, "promenade into the trivia court")
walkOnFloor({ v(-714, -240), v(-920, -240) }, "promenade into the manners court")
walkOnFloor({ v(-714, 220), v(-846, 220) }, "promenade to the parkour tower deck")
walkOnFloor({ v(0, 714), v(0, 980), v(0, 1400) }, "Journey road from the Haram terrace past the camp toward Madinah")
for _, gate in ipairs({ { "badr", -560 }, { "uhud", -860 } }) do
    local z = gate[2]
    walkOnFloor({ v(-714, z), v(-978, z), v(-978, z + 70), v(-1090, z + 70), v(-1090, z - 24) }, "promenade around to the " .. gate[1] .. " gate queue")
end

-- No travel destination drops the player into a wall or a building: the space from 8 to 12
-- studs above each destination point (where the body lands, above any raised floor) is open.
for _, destination in ipairs(TravelRoute.Destinations) do
    local landing = destination.TeleportPosition or destination.Position
    local blocker = blockedAt(landing + Vector3.new(0, 7, 0), 5)
    check(blocker == nil, destination.Id .. " arrival point is clear" .. (blocker and (" (blocked by " .. blocker .. ")") or ""))
end

-- Present-day Madinah: walk from the arrival point through a north door of the prayer hall
-- to the Rawdah, and along the visitation route in from Bab as-Salam.
-- At night every travel destination has a lamp, chandelier or fire within 70 studs, so
-- players never arrive in the dark.
local hubLights = {}
for _, light in ipairs(game:GetService("Workspace"):GetDescendants()) do
    if light:IsA("Light") and light.Parent and light.Parent:IsA("BasePart") then
        table.insert(hubLights, light.Parent.Position)
    end
end
local unlit = {}
for _, destination in ipairs(TravelRoute.Destinations) do
    local landing = destination.TeleportPosition or destination.Position
    local lit = false
    for _, position in ipairs(hubLights) do
        if (position - landing).Magnitude < 70 then
            lit = true
            break
        end
    end
    if not lit then
        table.insert(unlit, destination.Id)
    end
end
check(#unlit == 0, "every travel destination has a light nearby at night" .. (#unlit > 0 and (": " .. table.concat(unlit, ", ")) or ""))

-- No scenery (a decorative rock ridge, a backdrop mountain) swallows a destination: a player's
-- camera at the landing point, at the destination centre or 40 studs around it must not sit
-- inside any large non-colliding part.
local scenery = {}
for _, part in ipairs(game:GetService("Workspace"):GetDescendants()) do
    if part:IsA("BasePart") and not part.CanCollide and part.Transparency < 0.5 and part.Size.Magnitude > 60 then
        table.insert(scenery, part)
    end
end
local swallowed = {}
for _, destination in ipairs(TravelRoute.Destinations) do
    local landing = destination.TeleportPosition or destination.Position
    local probes = { landing, destination.Position }
    for step = 0, 7 do
        local angle = step * math.pi / 4
        table.insert(probes, destination.Position + Vector3.new(math.cos(angle) * 40, 0, math.sin(angle) * 40))
    end
    for _, probe in ipairs(probes) do
        local eye = probe + Vector3.new(0, 6, 0)
        local hit = nil
        for _, part in ipairs(scenery) do
            local l = part.CFrame:PointToObjectSpace(eye)
            local h = part.Size / 2
            if math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
                hit = part
                break
            end
        end
        if hit then
            table.insert(swallowed, string.format("%s (%s)", destination.Id, hit:GetFullName()))
            break
        end
    end
end
check(#swallowed == 0, "no rock ridge or backdrop swallows a travel destination" .. (#swallowed > 0 and (": " .. table.concat(swallowed, "; ")) or ""))

local medina = TravelRoute.GetDestinationById("medina_courtyard").Position
local medinaFloor = medina.Y + 4.6
walkable(Vector3.new(medina.X, medinaFloor, medina.Z + 136), Vector3.new(medina.X, medinaFloor, medina.Z - 120), "Medina arrival through the north door into the prayer hall")
walkable(Vector3.new(medina.X - 280, medinaFloor, medina.Z - 146.7), Vector3.new(medina.X + 40, medinaFloor, medina.Z - 146.7), "Medina visitation route from Bab as-Salam to the chamber marker")

walkable(Vector3.new(0, floorY, -180), Vector3.new(0, floorY, -720), "south route through King Abdulaziz Gate")
walkable(Vector3.new(180, floorY, 0), Vector3.new(720, floorY, 0), "west route through King Fahd Gate")
walkable(Vector3.new(-180, floorY, 0), Vector3.new(-720, floorY, 0), "east route through Bab as-Salam and the mas'a")
walkable(Vector3.new(-405, floorY, -425), Vector3.new(-405, floorY, 425), "sa'i lane from Safa to Marwa")

-- Each ramp up the mataf expansion has headroom all the way and lands on a floor slab.
local ramps, rampProblems = 0, {}
for _, item in ipairs(haram:FindFirstChild("MatafExpansion"):GetChildren()) do
    if item.Name:match("^Ramp_%d+_ToLevel") then
        ramps += 1
        local half = item.Size.Z * 0.5 - 1.5
        for i = 0, 10 do
            local along = -half + (2 * half) * i / 10
            local surface = item.CFrame * Vector3.new(0, item.Size.Y * 0.5, along)
            local blocker = blockedAt(surface + Vector3.new(0, 0.5, 0), 5)
            if blocker then
                table.insert(rampProblems, item.Name .. " blocked by " .. blocker)
                break
            end
        end
        local topEnd = item.CFrame * Vector3.new(0, item.Size.Y * 0.5, item.Size.Z * 0.5 + 3)
        local landed = false
        for _, part in ipairs(collidable) do
            if part ~= item and pointInside(part, topEnd - Vector3.new(0, 0.6, 0)) then
                landed = true
            end
        end
        if not landed then
            table.insert(rampProblems, item.Name .. " has no floor at its top")
        end
    end
end
check(ramps == 8 and #rampProblems == 0, string.format("%d mataf ramps are climbable", ramps) .. (#rampProblems > 0 and (": " .. table.concat(rampProblems, "; ")) or ""))

-- Pilgrims walking tawaf are decoration only, and their circles miss every landmark on the mataf.
local pilgrimFolder = haram:FindFirstChild("TawafPilgrims")
local pilgrimCount, pilgrimSolid, pilgrimHits = 0, 0, {}
local matafSolids = {}
for _, item in ipairs(haram:GetDescendants()) do
    if item:IsA("BasePart") and item.Transparency < 1 and not item:IsDescendantOf(pilgrimFolder) then
        local lo, hi = bounds(item)
        if hi.Y > floorY + 0.5 and lo.Y < floorY + 6 and math.max(math.abs(lo.X), math.abs(hi.X), math.abs(lo.Z), math.abs(hi.Z)) < 200 then
            table.insert(matafSolids, item)
        end
    end
end
for _, pilgrim in ipairs(pilgrimFolder and pilgrimFolder:GetChildren() or {}) do
    pilgrimCount += 1
    for _, piece in ipairs(pilgrim:GetChildren()) do
        if piece:IsA("BasePart") and (piece.CanCollide or piece.CanQuery or piece.CanTouch) then
            pilgrimSolid += 1
        end
    end
    local radius = pilgrim:GetAttribute("Radius")
    for step = 0, 179 do
        local a = step / 180 * math.pi * 2
        local feet = center + Vector3.new(math.cos(a) * radius, 6.6, math.sin(a) * radius)
        local hit = nil
        for _, solid in ipairs(matafSolids) do
            for _, dx in ipairs({ -1.2, 0, 1.2 }) do
                for _, dz in ipairs({ -1.2, 0, 1.2 }) do
                    if pointInside(solid, feet + Vector3.new(dx, 2, dz)) or pointInside(solid, feet + Vector3.new(dx, 4.5, dz)) then
                        hit = solid.Name
                    end
                end
            end
        end
        if hit then
            table.insert(pilgrimHits, pilgrim.Name .. " walks through " .. hit)
            break
        end
    end
end
check(pilgrimCount >= 24 and pilgrimSolid == 0, string.format("%d tawaf pilgrims are non-colliding decoration", pilgrimCount))
check(#pilgrimHits == 0, "tawaf pilgrims never walk through a mataf landmark" .. (#pilgrimHits > 0 and (": " .. table.concat(pilgrimHits, "; ", 1, math.min(#pilgrimHits, 6))) or ""))

-- No other district leaves parts inside the sanctuary footprint.
local intruders = {}
for _, district in ipairs(geometry:GetChildren()) do
    if district ~= hub and district.Name ~= "HubBounds" then
        for _, item in ipairs(district:GetDescendants()) do
            if item:IsA("BasePart") and item.Transparency < 1 then
                local lo, hi = bounds(item)
                if hi.X > center.X - 660 and lo.X < center.X + 660 and hi.Z > center.Z - 660 and lo.Z < center.Z + 660 and hi.Y > center.Y + 12 then
                    table.insert(intruders, district.Name .. "/" .. item.Name)
                end
            end
        end
    end
end
check(#intruders == 0, "no other district's parts stand inside the Haram" .. (#intruders > 0 and (": " .. table.concat(intruders, ", ", 1, math.min(#intruders, 8))) or ""))

if failures > 0 then
    error(string.format("%d hub check(s) failed", failures))
end
print("All hub checks passed.")
