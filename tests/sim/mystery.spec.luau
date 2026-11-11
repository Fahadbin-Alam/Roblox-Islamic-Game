-- Two friends solve Bilal's mystery together through the real MysteryService: shared clues,
-- a hint, a wrong and a right lock answer, the ordered episode, and credit for both.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SahabiMysteries = require(ReplicatedStorage.Shared.Data.SahabiMysteries)
local PlayerProgress = require(game:GetService("ServerScriptService").Modules.PlayerProgress)

local mystery = SahabiMysteries.Mysteries[1]
local room = Workspace:WaitForChild("MysteryWing"):WaitForChild(mystery.Id)
local hana = sim.addPlayer(9601, "Hana")
local idris = sim.addPlayer(9602, "Idris")
sim.advance(0.5)

local function prompts(action)
    local list = {}
    for _, item in ipairs(room:GetDescendants()) do
        if item.ClassName == "ProximityPrompt" and item:GetAttribute("PromptAction") == action then
            table.insert(list, item)
        end
    end
    table.sort(list, function(a, b)
        return tostring(a:GetAttribute("StationIndex") or a:GetAttribute("ClueId")) < tostring(b:GetAttribute("StationIndex") or b:GetAttribute("ClueId"))
    end)
    return list
end

local function use(player, prompt)
    local part = prompt.Parent
    sim.place(player, part.Position + Vector3.new(3, 1, 0), part.Position)
    prompt.Triggered._fire(player)
end

local function state(player)
    return sim.last(player, "Mystery/State")
end

test("both players teleport in and are seen in the same room", function()
    sim.fireServer(hana, "Mystery/Request", "Teleport", mystery.Id)
    sim.fireServer(idris, "Mystery/Request", "Teleport", mystery.Id)
    local door = room:FindFirstChild("LockDoor", true)
    sim.place(hana, door.Position + Vector3.new(0, -3, -10), door.Position)
    sim.place(idris, door.Position + Vector3.new(4, -3, -10), door.Position)
    sim.advance(1)
    expectEqual(state(hana).MysteryId, mystery.Id, "Hana is in the room")
    expectEqual(state(idris).Players, 2, "the room sees two players")
end)

test("clues found by either player count for both", function()
    local clues = prompts("MysteryClue")
    expectEqual(#clues, #mystery.Clues, "every clue has a prompt")
    for index, prompt in ipairs(clues) do
        use(if index % 2 == 0 then idris else hana, prompt)
    end
    expectEqual(#state(hana).Found, #mystery.Clues, "Hana sees every clue found")
    expectEqual(#state(idris).Found, #mystery.Clues, "Idris sees every clue found")
end)

test("a hint is shared and a wrong lock answer keeps the door shut", function()
    use(idris, prompts("MysteryHint")[1])
    expectEqual(state(hana).HintsUsed, 1, "the hint counts for the room")
    local wrong = {}
    for index, question in ipairs(mystery.Lock) do
        wrong[index] = if question.CorrectIndex == 1 then 2 else 1
    end
    sim.fireServer(hana, "Mystery/Request", "Lock", wrong)
    expectEqual(state(idris).LockOpen, false, "the lock stays shut")
    expectEqual(room:FindFirstChild("LockDoor", true).CanCollide, true, "the door is solid")
end)

test("the episode cannot start before the lock opens", function()
    use(hana, prompts("MysteryStation")[1])
    expectEqual(#state(hana).StationsDone, 0, "no station counted")
end)

test("the right answers open the door for everyone", function()
    local right = {}
    for index, question in ipairs(mystery.Lock) do
        right[index] = question.CorrectIndex
    end
    sim.fireServer(idris, "Mystery/Request", "Lock", right)
    expectEqual(state(hana).LockOpen, true, "Hana sees the lock open")
    expectEqual(room:FindFirstChild("LockDoor", true).CanCollide, false, "the door can be walked through")
end)

test("the episode is played in order and both players get the credit", function()
    local stations = prompts("MysteryStation")
    expectEqual(#stations, #mystery.Episode.Stations, "every station has a prompt")
    if mystery.Episode.Ordered and #stations > 1 then
        use(hana, stations[2])
        expectEqual(#state(hana).StationsDone, 0, "skipping ahead does not count")
    end
    for index, prompt in ipairs(stations) do
        use(if index % 2 == 0 then idris else hana, prompt)
        sim.advance(0.5)
    end
    for _, player in ipairs({ hana, idris }) do
        expectTrue(PlayerProgress.HasCompleted(player, "mystery", mystery.Id), player.Name .. " solved the mystery")
        local stars = PlayerProgress.GetStat(player, "MysteryStars_" .. mystery.Id)
        expectEqual(stars, 3, player.Name .. " keeps 3 stars (one hint and one wrong try are free)")
    end
    local finished = false
    for _, payload in ipairs(sim.received(hana, "Mystery/State")) do
        if payload.Finished and payload.FinishText then
            finished = true
        end
    end
    expectTrue(finished, "the conclusion is shown")
end)

test("a finished room resets for the next group", function()
    sim.advance(45)
    expectEqual(state(hana).LockOpen, false, "the lock is shut again")
    expectEqual(#state(hana).Found, 0, "clues are back in place")
end)

-- The other four rooms, each solved start to finish by a new pair through the same service.
for number = 2, #SahabiMysteries.Mysteries do
    local other = SahabiMysteries.Mysteries[number]
    test(string.format("room %d (%s) can be solved start to finish", number, other.Id), function()
        local otherRoom = Workspace.MysteryWing:FindFirstChild(other.Id)
        expectTrue(otherRoom ~= nil, "the room is built")
        local a = sim.addPlayer(9700 + number * 2, "Solver" .. number .. "A")
        local b = sim.addPlayer(9701 + number * 2, "Solver" .. number .. "B")
        sim.advance(0.5)

        local function roomPrompts(action)
            local list = {}
            for _, item in ipairs(otherRoom:GetDescendants()) do
                if item.ClassName == "ProximityPrompt" and item:GetAttribute("PromptAction") == action then
                    table.insert(list, item)
                end
            end
            table.sort(list, function(x, y)
                return tostring(x:GetAttribute("StationIndex") or x:GetAttribute("ClueId")) < tostring(y:GetAttribute("StationIndex") or y:GetAttribute("ClueId"))
            end)
            return list
        end

        sim.fireServer(a, "Mystery/Request", "Teleport", other.Id)
        sim.fireServer(b, "Mystery/Request", "Teleport", other.Id)
        local door = otherRoom:FindFirstChild("LockDoor", true)
        sim.place(a, door.Position + Vector3.new(0, -3, -10), door.Position)
        sim.place(b, door.Position + Vector3.new(4, -3, -10), door.Position)
        sim.advance(1)
        expectEqual(sim.last(a, "Mystery/State").MysteryId, other.Id, "the pair is in the room")

        local clues = roomPrompts("MysteryClue")
        expectEqual(#clues, #other.Clues, "every clue has a prompt")
        for index, prompt in ipairs(clues) do
            local who = if index % 2 == 0 then b else a
            sim.place(who, prompt.Parent.Position + Vector3.new(3, 1, 0), prompt.Parent.Position)
            prompt.Triggered._fire(who)
        end
        expectEqual(#sim.last(b, "Mystery/State").Found, #other.Clues, "every clue is found")

        local right = {}
        for index, question in ipairs(other.Lock) do
            right[index] = question.CorrectIndex
        end
        sim.fireServer(a, "Mystery/Request", "Lock", right)
        expectEqual(sim.last(b, "Mystery/State").LockOpen, true, "the lock opens")

        local stations = roomPrompts("MysteryStation")
        expectEqual(#stations, #other.Episode.Stations, "every station has a prompt")
        for index, prompt in ipairs(stations) do
            local who = if index % 2 == 0 then b else a
            sim.place(who, prompt.Parent.Position + Vector3.new(3, 1, 0), prompt.Parent.Position)
            prompt.Triggered._fire(who)
            sim.advance(0.5)
        end
        for _, player in ipairs({ a, b }) do
            expectTrue(PlayerProgress.HasCompleted(player, "mystery", other.Id), player.Name .. " solved " .. other.Id)
            expectEqual(PlayerProgress.GetStat(player, "MysteryStars_" .. other.Id), 3, player.Name .. " gets 3 stars with no hints")
        end
        sim.removePlayer(a)
        sim.removePlayer(b)
        sim.advance(1)
    end)
end
