-- Muting, joining friends, friend notices and voice status through the real SocialService.
local TextChatService = game:GetService("TextChatService")

-- The default channel appears after the server has started, as it can in Roblox.
local general = Instance.new("TextChannel")
general.Name = "RBXGeneral"
general.Parent = TextChatService:WaitForChild("TextChannels")

local sara = sim.addPlayer(9201, "Sara")
local omar = sim.addPlayer(9202, "Omar")
local zaid = sim.addPlayer(9203, "Zaid")
sim.advance(1)

local function delivered(sender, recipient)
    local callback = general.ShouldDeliverCallback
    expectTrue(type(callback) == "function", "the chat channel has a delivery filter")
    return callback({ TextSource = { UserId = sender.UserId } }, { UserId = recipient.UserId })
end

local function lastMessage(player)
    local state = sim.last(player, "Social/State")
    return state and state.Message or ""
end

test("muting a player hides their chat from you only", function()
    expectEqual(delivered(omar, sara), true, "chat is delivered before muting")
    sim.fireServer(sara, "Social/Request", "Mute", { UserId = omar.UserId, Muted = true })
    expectEqual(delivered(omar, sara), false, "Sara no longer receives Omar's messages")
    expectEqual(delivered(omar, zaid), true, "Zaid still receives Omar's messages")
    expectEqual(delivered(sara, omar), true, "Omar still receives Sara's messages")
    sim.fireServer(sara, "Social/Request", "Mute", { UserId = omar.UserId, Muted = false })
    expectEqual(delivered(omar, sara), true, "unmuting restores chat")
end)

test("muting also denies the muted player's microphone to you", function()
    local mic = Instance.new("AudioDeviceInput")
    mic.Parent = omar
    sim.fireServer(zaid, "Social/Request", "Mute", { UserId = omar.UserId, Muted = true })
    local list = rawget(mic, "__accessList") or {}
    expectEqual(#list, 1, "one listener is denied")
    expectEqual(list[1], zaid.UserId, "Zaid is the denied listener")
    expectTrue(string.find(lastMessage(zaid), "and voice") ~= nil, "Zaid is told voice is muted too")
end)

test("a muted list is cleared when the player leaves", function()
    sim.fireServer(sara, "Social/Request", "Mute", { UserId = omar.UserId, Muted = true })
    sim.removePlayer(sara)
    local again = sim.addPlayer(9201, "Sara")
    sim.advance(0.5)
    expectEqual(delivered(omar, again), true, "a rejoined player starts with nobody muted")
    sara = again
end)

test("you can only jump to friends, with a cooldown", function()
    sim.place(omar, Vector3.new(500, 10, 500), Vector3.new(0, 10, 0))
    sim.fireServer(sara, "Social/Request", "JumpTo", omar.UserId)
    expectTrue(string.find(lastMessage(sara), "friends list") ~= nil, "strangers cannot be followed")
    sim.makeFriends(sara, omar)
    sim.fireServer(sara, "Social/Request", "JumpTo", omar.UserId)
    local gap = (sim.root(sara).Position - sim.root(omar).Position).Magnitude
    expectTrue(gap < 10, "Sara is next to Omar")
    expectTrue(string.find(lastMessage(omar), "Sara joined you") ~= nil, "Omar is told")
    sim.place(sara, Vector3.new(0, 10, 0), Vector3.new(1, 10, 0))
    sim.fireServer(sara, "Social/Request", "JumpTo", omar.UserId)
    expectTrue((sim.root(sara).Position - sim.root(omar).Position).Magnitude > 100, "a second jump within 5 seconds is ignored")
end)

test("friends already in the server are told when a friend arrives", function()
    local layla = sim.addPlayer(9204, "Layla")
    sim.removePlayer(layla)
    sim.makeFriends(zaid, layla)
    sim.addPlayer(9204, "Layla")
    sim.advance(0.5)
    expectTrue(string.find(lastMessage(zaid), "Your friend Layla joined") ~= nil, "Zaid gets a friend notice")
end)

test("voice status reports only eligible players", function()
    sim.voiceUsers[omar.UserId] = true
    sim.fireServer(zaid, "Social/Request", "Voice")
    local voice = sim.last(zaid, "Social/State").Voice
    expectEqual(voice[tostring(omar.UserId)], true, "Omar can use voice")
    expectEqual(voice[tostring(zaid.UserId)], false, "Zaid cannot")
end)
