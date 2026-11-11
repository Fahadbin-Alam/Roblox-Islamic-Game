-- Drives the client HUDs and reports.
local passed, failed = 0, 0
local function check(ok, message)
    if ok then
        passed += 1
        print("ok   " .. message)
    else
        failed += 1
        print("FAIL " .. message)
    end
end

sim.advance(10)

for _, failure in ipairs(serverFailures) do
    print("info server script did not start in the mock: " .. string.sub(failure, 1, 300))
end

local playerGui = localPlayer:FindFirstChild("PlayerGui")
local loadErrors = #clientErrors
check(loadErrors == 0, string.format("all %d client scripts load without errors", #loadedClients))

local screens = 0
for _, child in ipairs(playerGui:GetChildren()) do
    if child.ClassName == "ScreenGui" then
        screens += 1
    end
end
check(screens >= 5, string.format("HUDs create their screens (%d ScreenGuis)", screens))

-- Press every button, twice (open, then close), letting the game run between presses.
local function buttons()
    local list = {}
    for _, item in ipairs(playerGui:GetDescendants()) do
        if item.ClassName == "TextButton" or item.ClassName == "ImageButton" then
            table.insert(list, item)
        end
    end
    return list
end

local before = #clientErrors
local pressed = 0
for round = 1, 2 do
    for _, button in ipairs(buttons()) do
        if button.Parent then
            pressed += 1
            local ok, err = xpcall(function()
                button.Activated._fire()
                button.MouseButton1Click._fire()
            end, debug.traceback)
            if not ok then
                table.insert(clientErrors, "pressing " .. button:GetFullName() .. ": " .. tostring(err))
            end
            sim.advance(0.3)
        end
    end
end
check(#clientErrors == before, string.format("pressing every button (%d presses) raises no errors", pressed))

-- Walk the player through the main journeys so the HUDs receive real server state.
local before2 = #clientErrors
local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
local function tryFire(path, ...)
    local node = remotes
    for segment in string.gmatch(path, "[^/]+") do
        node = node and node:FindFirstChild(segment)
    end
    if node then
        node:FireServer(...)
        sim.advance(1)
        return true
    end
    return false
end
local SeerahCampaign = require(game:GetService("ReplicatedStorage").Shared.Data.SeerahCampaign)
local firstChapter = SeerahCampaign.Chapters[1].Id
-- A second player so the PvP match actually starts and sends round state.
local rival = sim.addPlayer(9002, "Rival")
local journeys = 0
for _, step in ipairs({
    { "Campaign/Request", "State" },
    { "Campaign/Request", "Start", firstChapter },
    { "Campaign/Request", "Travel", firstChapter },
    { "Campaign/Request", "FinishStory", firstChapter },
    { "Campaign/Request", "Answer", firstChapter, 1 },
    { "Campaign/Request", "Close" },
    { "Social/Request", "Voice" },
    { "Social/Request", "Mute", { UserId = 9002, Muted = true } },
}) do
    if tryFire(table.unpack(step)) then
        journeys += 1
    end
end
-- Into Bilal's room: teleport to its door, then walk inside.
tryFire("Mystery/Request", "Teleport", "bilal")
local wing = workspace:FindFirstChild("MysteryWing")
local room = wing and wing:FindFirstChild("bilal")
local floor = room and room:FindFirstChild("Floor", true)
if floor then
    sim.place(localPlayer, floor.Position + Vector3.new(0, 4, 0), floor.Position + Vector3.new(0, 4, 10))
    sim.advance(3)
end
tryFire("Pvp/Request", "Teleport")
tryFire("Pvp/Request", "Join")
sim.fireServer(rival, "Pvp/Request", "Teleport")
sim.fireServer(rival, "Pvp/Request", "Join")
sim.advance(10)
sim.advance(20)
local received = {}
for _, entry in ipairs(sim.sent) do
    if entry.Player == localPlayer then
        received[entry.Remote] = true
    end
end
local kinds = 0
for _ in pairs(received) do
    kinds += 1
end
check(#clientErrors == before2, string.format("HUDs handle server state from %d requests (%d different messages received) without errors", journeys, kinds))
for name in pairs(received) do print("info received " .. name) end
check(received["game.ReplicatedStorage.Remotes.Campaign.State"] and received["game.ReplicatedStorage.Remotes.Pvp.State"] and received["game.ReplicatedStorage.Remotes.Mystery.State"], "campaign, PvP and mystery HUDs all received state")

-- Press everything again now the campaign, mystery and PvP panels are showing.
local before3 = #clientErrors
local pressed2 = 0
for _, button in ipairs(buttons()) do
    if button.Parent then
        pressed2 += 1
        local ok, err = xpcall(function()
            button.Activated._fire()
            button.MouseButton1Click._fire()
        end, debug.traceback)
        if not ok then
            table.insert(clientErrors, "pressing " .. button:GetFullName() .. ": " .. tostring(err))
        end
        sim.advance(0.3)
    end
end
check(#clientErrors == before3, string.format("pressing every button mid-journey (%d presses) raises no errors", pressed2))

for _, message in ipairs(clientErrors) do
    print("    " .. string.sub(message, 1, 900))
end

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then
    error("client checks failed")
end
