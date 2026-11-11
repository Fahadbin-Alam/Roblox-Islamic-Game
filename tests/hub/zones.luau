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
    { Name = HistoricalSites.FolderName, Budget = 6000 },
    { Name = "MysteryWing", Budget = 2500 },
    { Name = "CoopTrials", Budget = 400 },
    { Name = "TrainingGrounds", Budget = 600 },
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

if zoneFailures > 0 then
    error(string.format("%d zone check(s) failed", zoneFailures))
end
print("All zone checks passed.")
