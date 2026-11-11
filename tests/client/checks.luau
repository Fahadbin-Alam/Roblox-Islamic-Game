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

-- Screen layout at first sight, on a small phone held sideways (667 x 375) and on a laptop
-- (1280 x 720): every visible button lies on the screen, is big enough to tap, and does not
-- sit on top of another visible button. Buttons placed by a list or grid layout, inside a
-- scrolling frame, or under a size constraint are left out (their real size depends on Roblox).
local LAYOUTS = { UIListLayout = true, UIGridLayout = true, UIPageLayout = true, UITableLayout = true }
local CONSTRAINTS = { UIScale = true, UISizeConstraint = true, UIAspectRatioConstraint = true }

local function shown(gui)
    local node = gui
    while node and node.ClassName ~= "ScreenGui" do
        if node.Visible == false then
            return false
        end
        node = node.Parent
    end
    return node ~= nil and node.Enabled ~= false
end

local function measurable(gui)
    local node = gui
    while node and node.ClassName ~= "ScreenGui" do
        if node.ClassName == "ScrollingFrame" and node ~= gui then
            return false
        end
        for _, child in ipairs(node:GetChildren()) do
            if CONSTRAINTS[child.ClassName] and child.Name ~= "FitScale" then
                return false
            end
        end
        local parent = node.Parent
        if parent then
            for _, sibling in ipairs(parent:GetChildren()) do
                if LAYOUTS[sibling.ClassName] then
                    return false
                end
            end
        end
        node = parent
    end
    return node ~= nil
end

-- Same rule as UiKit.FitScale: the largest scale (at most 1) that keeps a fixed-size panel on
-- the screen with a margin, around its anchor point.
local function fitScale(gui, length, at, anchor, view, margin)
    local scale = 1
    if length > 0 then
        if anchor < 1 then
            scale = math.min(scale, (view - margin - at) / (length * (1 - anchor)))
        end
        if anchor > 0 then
            scale = math.min(scale, (at - margin) / (length * anchor))
        end
    end
    return scale
end

-- Absolute rectangle of a GuiObject on a w x h screen, and the accumulated UIScale factor that
-- applies to its children's pixel offsets.
local function rect(gui, w, h)
    if gui.ClassName == "ScreenGui" then
        return 0, 0, w, h, 1
    end
    local px, py, pw, ph, k = rect(gui.Parent, w, h)
    local size = gui.Size or UDim2.new(0, 0, 0, 0)
    local position = gui.Position or UDim2.new(0, 0, 0, 0)
    local anchor = gui.AnchorPoint or Vector2.new(0, 0)
    local sw = size.X.Scale * pw + size.X.Offset * k
    local sh = size.Y.Scale * ph + size.Y.Offset * k
    local ax = px + position.X.Scale * pw + position.X.Offset * k
    local ay = py + position.Y.Scale * ph + position.Y.Offset * k
    local fit = gui:FindFirstChild("FitScale")
    if fit then
        local margin = fit:GetAttribute("Margin") or 10
        local s = math.max(0.3, math.min(fitScale(gui, sw, ax, anchor.X, w, margin), fitScale(gui, sh, ay, anchor.Y, h, margin)))
        sw, sh, k = sw * s, sh * s, k * s
    end
    return ax - anchor.X * sw, ay - anchor.Y * sh, sw, sh, k
end

local layoutIssues = { offscreen = {}, tiny = {}, overlapping = {} }
local measuredTotal = 0

local function measureScreens(stateLabel)
    for _, screen in ipairs({ { 667, 375, "phone" }, { 1280, 720, "laptop" } }) do
        local w, h = screen[1], screen[2]
        local measured = {}
        for _, item in ipairs(playerGui:GetDescendants()) do
            if (item.ClassName == "TextButton" or item.ClassName == "ImageButton") and shown(item) and measurable(item) then
                local x, y, bw, bh = rect(item, w, h)
                table.insert(measured, { item, x, y, bw, bh })
                if x < -1 or y < -1 or x + bw > w + 1 or y + bh > h + 1 then
                    layoutIssues.offscreen[string.format("%s on a %s %s (%d,%d %dx%d)", item:GetFullName(), screen[3], stateLabel, x, y, bw, bh)] = true
                end
                if bw < 28 or bh < 28 then
                    layoutIssues.tiny[string.format("%s on a %s (%dx%d)", item:GetFullName(), screen[3], bw, bh)] = true
                end
            end
        end
        measuredTotal += #measured
        for i = 1, #measured do
            for j = i + 1, #measured do
                local a, b = measured[i], measured[j]
                local ix = math.min(a[2] + a[4], b[2] + b[4]) - math.max(a[2], b[2])
                local iy = math.min(a[3] + a[5], b[3] + b[5]) - math.max(a[3], b[3])
                local smaller = math.min(a[4] * a[5], b[4] * b[5])
                if ix > 0 and iy > 0 and smaller > 0 and ix * iy > 0.25 * smaller and not a[1]:IsDescendantOf(b[1]) and not b[1]:IsDescendantOf(a[1]) then
                    layoutIssues.overlapping[string.format("%s and %s on a %s %s", a[1]:GetFullName(), b[1]:GetFullName(), screen[3], stateLabel)] = true
                end
            end
        end
    end
end

local function keys(set)
    local list = {}
    for key in pairs(set) do
        table.insert(list, key)
    end
    table.sort(list)
    return list
end

-- First sight, then with each first-sight button's panel opened in turn.
measureScreens("at first sight")
local firstSight = {}
for _, item in ipairs(playerGui:GetDescendants()) do
    if (item.ClassName == "TextButton" or item.ClassName == "ImageButton") and shown(item) then
        table.insert(firstSight, item)
    end
end
for _, button in ipairs(firstSight) do
    pcall(function()
        button.Activated._fire()
    end)
    sim.advance(0.5)
    measureScreens("after pressing " .. button.Name)
    pcall(function()
        button.Activated._fire()
    end)
    sim.advance(0.5)
end

print(string.format("info measured %d button placements", measuredTotal))
local offscreen, tiny, overlapping = keys(layoutIssues.offscreen), keys(layoutIssues.tiny), keys(layoutIssues.overlapping)
check(#offscreen == 0, "every visible button fits on phone and laptop screens" .. (#offscreen > 0 and (": " .. table.concat(offscreen, "; ")) or ""))
check(#tiny == 0, "every visible button is big enough to tap" .. (#tiny > 0 and (": " .. table.concat(tiny, "; ")) or ""))
check(#overlapping == 0, "no visible buttons overlap" .. (#overlapping > 0 and (": " .. table.concat(overlapping, "; ")) or ""))

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
