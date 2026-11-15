-- A live layer on top of tests/hub/mock.luau: virtual time, players with characters and
-- humanoids, remotes the test can fire, a recording FireClient, and an in-memory DataStore
-- that copies data the way Roblox serializes it. Server scripts run unchanged on top of it.

sim = {}

local Instance_ = mock.Instance_
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

---------------------------------------------------------------- Virtual time
local now = 0
local queue = {}
local sequence = 0
local realOs = os

local function resume(co, ...)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        error(debug.traceback(co, tostring(err)), 0)
    end
end

local function schedule(at, co, args)
    sequence += 1
    table.insert(queue, { At = at, Co = co, Args = args, Seq = sequence })
end

local function run(fn, ...)
    resume(coroutine.create(fn), ...)
end

task = {
    spawn = function(fn, ...)
        if type(fn) == "thread" then
            resume(fn, ...)
        else
            run(fn, ...)
        end
    end,
    defer = function(fn, ...)
        schedule(now, coroutine.create(fn), table.pack(...))
    end,
    delay = function(seconds, fn, ...)
        schedule(now + (seconds or 0), coroutine.create(fn), table.pack(...))
    end,
    wait = function(seconds)
        assert(coroutine.isyieldable(), "task.wait called outside a coroutine")
        schedule(now + math.max(seconds or 0, 1 / 60), coroutine.running(), { n = 0 })
        coroutine.yield()
        return seconds or 0
    end,
    cancel = function() end,
}
wait = task.wait
mock.spawnHandler = run
-- Signal:Wait() resumes after one frame (enough for RunService.Heartbeat:Wait()).
mock.signalWait = function()
    return task.wait(1 / 60)
end

os = setmetatable({
    clock = function()
        return now
    end,
    time = function(t)
        if t then
            return realOs.time(t)
        end
        return 1794000000 + math.floor(now + sim.dayOffset * 86400)
    end,
}, { __index = realOs })

sim.dayOffset = 0

-- Moves the calendar forward without running a day of server loops (as if the player came
-- back in a new server tomorrow).
function sim.skipDays(days)
    sim.dayOffset += days
end

function sim.now()
    return now
end

-- Runs every task due in the next `seconds` of game time, in order.
function sim.advance(seconds)
    local target = now + seconds
    while true do
        table.sort(queue, function(a, b)
            if a.At == b.At then
                return a.Seq < b.Seq
            end
            return a.At < b.At
        end)
        local item = queue[1]
        if not item or item.At > target then
            break
        end
        table.remove(queue, 1)
        now = math.max(now, item.At)
        if coroutine.status(item.Co) == "suspended" then
            resume(item.Co, table.unpack(item.Args, 1, item.Args.n))
        end
    end
    now = target
end

-- Runs a server script body inside a coroutine so it may wait like a real Script.
function sim.runScript(name, body)
    local co = coroutine.create(body)
    local ok, err = coroutine.resume(co)
    if not ok then
        error(name .. " failed: " .. debug.traceback(co, tostring(err)), 0)
    end
end

---------------------------------------------------------------- Engine calls
RaycastParams = RaycastParams or { new = function() return {} end }
OverlapParams = OverlapParams or { new = function() return {} end }
-- WaitForChild yields like the engine: until the child appears, or nil after the timeout.
function Instance_.WaitForChild(self, name, timeout)
    local waited = 0
    while true do
        local child = self:FindFirstChild(name)
        if child then
            return child
        end
        if timeout and waited >= timeout then
            return nil
        end
        if not coroutine.isyieldable() then
            error("WaitForChild would hang: " .. tostring(self.Name) .. "." .. name, 2)
        end
        task.wait(0.1)
        waited += 0.1
    end
end
function Instance_.GetServerTimeNow()
    return now
end
function Instance_.AddItem() end
function Instance_.BindToClose() end
function Instance_.FindFirstAncestorOfClass(self, cls)
    local node = self.Parent
    while node do
        if node.ClassName == cls then
            return node
        end
        node = node.Parent
    end
    return nil
end
function Instance_.FindFirstAncestorWhichIsA(self, cls)
    local node = self.Parent
    while node do
        if node:IsA(cls) then
            return node
        end
        node = node.Parent
    end
    return nil
end
function Instance_.RemoveTag(self, objectOrTag, maybeTag)
    local object, tag = self, objectOrTag
    if self == game:GetService("CollectionService") then
        object, tag = objectOrTag, maybeTag
    end
    object.Tags[tag] = nil
    local list = mock.tags[tag] or {}
    for i = #list, 1, -1 do
        if list[i] == object then
            table.remove(list, i)
        end
    end
end
local baseGetTagged = Instance_.GetTagged
function Instance_.GetTagged(self, tag)
    local result = {}
    for _, object in ipairs(baseGetTagged(self, tag)) do
        if object.Tags[tag] then
            table.insert(result, object)
        end
    end
    return result
end
local basePivotTo = Instance_.PivotTo
function Instance_.PivotTo(self, target)
    if self.ClassName == "Model" then
        local root = self:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = target
        end
        return
    end
    basePivotTo(self, target)
end
local baseGetPivot = Instance_.GetPivot
function Instance_.GetPivot(self)
    if self.ClassName == "Model" then
        local root = self:FindFirstChild("HumanoidRootPart")
        if root then
            return root.CFrame
        end
    end
    return baseGetPivot(self)
end

---------------------------------------------------------------- Humanoids
local dead = {}

mock.setHooks.Humanoid = function(humanoid, key, value)
    if key == "Health" and value <= 0 and not dead[humanoid] then
        dead[humanoid] = true
        humanoid.Died._fire()
    end
end

function Instance_.TakeDamage(self, amount)
    self.Health = math.max(0, self.Health - amount)
end
function Instance_.UnequipTools() end
function Instance_.MoveTo() end

---------------------------------------------------------------- Players
local players = {}
sim.players = players

function Instance_.GetPlayers(self)
    if self == Players then
        return table.clone(players)
    end
    return {}
end
function Instance_.GetPlayerByUserId(_, userId)
    for _, player in ipairs(players) do
        if player.UserId == userId then
            return player
        end
    end
    return nil
end
function Instance_.GetPlayerFromCharacter(_, character)
    for _, player in ipairs(players) do
        if player.Character == character then
            return player
        end
    end
    return nil
end
function Instance_.IsFriendsWith(self, userId)
    local friends = rawget(self, "__friends") or {}
    return friends[userId] == true
end
function Instance_.Kick(self)
    sim.removePlayer(self)
end

function sim.spawnCharacter(player, at)
    local old = player.Character
    if old then
        old:Destroy()
    end
    local model = Instance.new("Model")
    model.Name = player.Name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.CFrame = CFrame.new(at or Vector3.new(0, 10, 0))
    root.Parent = model
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.Parent = model
    model.PrimaryPart = root
    model.Parent = Workspace
    player.Character = model
    player.CharacterAdded._fire(model)
    return model
end

function Instance_.LoadCharacter(self)
    sim.spawnCharacter(self)
end
Instance_.LoadCharacterAsync = Instance_.LoadCharacter

function sim.addPlayer(userId, name)
    local player = mock.newInstance("Player")
    player.Name = name
    player.DisplayName = name
    player.UserId = userId
    player.AccountAge = 400
    player.Parent = Players
    local backpack = Instance.new("Backpack")
    backpack.Name = "Backpack"
    backpack.Parent = player
    table.insert(players, player)
    sim.spawnCharacter(player)
    Players.PlayerAdded._fire(player)
    return player
end

function sim.removePlayer(player)
    for i, other in ipairs(players) do
        if other == player then
            table.remove(players, i)
            break
        end
    end
    Players.PlayerRemoving._fire(player)
    player.Parent = nil
end

function sim.makeFriends(a, b)
    local fa = rawget(a, "__friends") or {}
    local fb = rawget(b, "__friends") or {}
    fa[b.UserId] = true
    fb[a.UserId] = true
    rawset(a, "__friends", fa)
    rawset(b, "__friends", fb)
end

function sim.root(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

function sim.humanoid(player)
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- Stands `player` at `position`, facing `target`.
function sim.place(player, position, target)
    sim.root(player).CFrame = CFrame.lookAt(position, Vector3.new(target.X, position.Y, target.Z))
end

-- Equips the named tool and clicks once, the way a player's mouse click reaches the server.
function sim.click(player, toolName)
    local character = player.Character
    local tool = character:FindFirstChild(toolName)
    if not tool then
        local backpack = player:FindFirstChildOfClass("Backpack")
        tool = backpack and backpack:FindFirstChild(toolName)
        assert(tool, player.Name .. " has no " .. toolName)
        tool.Parent = character
        tool.Equipped._fire()
    end
    tool.Activated._fire()
end

---------------------------------------------------------------- Remotes
sim.sent = {}

function Instance_.FireClient(remote, player, ...)
    table.insert(sim.sent, { Remote = remote:GetFullName(), Player = player, Args = table.pack(...), At = now })
end
function Instance_.FireAllClients(remote, ...)
    for _, player in ipairs(players) do
        Instance_.FireClient(remote, player, ...)
    end
end

function sim.remote(path)
    local node = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    for segment in string.gmatch(path, "[^/]+") do
        node = node:WaitForChild(segment)
    end
    return node
end

-- What a client sends with RemoteEvent:FireServer.
function sim.fireServer(player, path, ...)
    sim.remote(path).OnServerEvent._fire(player, ...)
end

-- Every payload `player` received on the remote at `path` (e.g. "Pvp/State").
function sim.received(player, path)
    local suffix = "Remotes." .. string.gsub(path, "/", ".")
    local result = {}
    for _, entry in ipairs(sim.sent) do
        if entry.Player == player and string.sub(entry.Remote, -#suffix) == suffix then
            table.insert(result, entry.Args[1])
        end
    end
    return result
end

function sim.last(player, path)
    local list = sim.received(player, path)
    return list[#list]
end

---------------------------------------------------------------- DataStore
-- Values are copied in and out like Roblox's JSON storage, and the same things are refused:
-- functions, Instances, Vector3s, mixed or sparse arrays, and non-string keys in dictionaries.
local function serialize(value, path)
    local kind = type(value)
    if kind == "number" then
        assert(value == value and value ~= math.huge and value ~= -math.huge, "cannot store NaN or inf at " .. path)
        return value
    elseif kind == "string" or kind == "boolean" or kind == "nil" then
        return value
    elseif kind ~= "table" or getmetatable(value) ~= nil then
        error("cannot store " .. kind .. " (" .. tostring(value) .. ") at " .. path, 0)
    end
    local count, maxIndex, stringKeys = 0, 0, 0
    for key in pairs(value) do
        count += 1
        if type(key) == "number" and key % 1 == 0 and key > 0 then
            maxIndex = math.max(maxIndex, key)
        elseif type(key) == "string" then
            stringKeys += 1
        else
            error("cannot store key " .. tostring(key) .. " at " .. path, 0)
        end
    end
    assert(stringKeys == 0 or stringKeys == count, "cannot store a mixed table at " .. path)
    assert(stringKeys > 0 or maxIndex == count, "cannot store a sparse array at " .. path)
    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = serialize(inner, path .. "." .. tostring(key))
    end
    return copy
end
sim.serialize = serialize

local stores = {}
sim.stores = stores
sim.dataStoreDown = false

local function storeNamed(name)
    if stores[name] then
        return stores[name]
    end
    local data = {}
    local object = { Data = data, Writes = 0 }
    function object.GetAsync(_, key)
        assert(not sim.dataStoreDown, "DataStore request failed (simulated outage)")
        return serialize(data[key], key)
    end
    function object.SetAsync(_, key, value)
        assert(not sim.dataStoreDown, "DataStore request failed (simulated outage)")
        data[key] = serialize(value, key)
        object.Writes += 1
    end
    function object.UpdateAsync(_, key, transform)
        assert(not sim.dataStoreDown, "DataStore request failed (simulated outage)")
        local result = transform(serialize(data[key], key))
        if result ~= nil then
            data[key] = serialize(result, key)
            object.Writes += 1
        end
        return result
    end
    function object.RemoveAsync(_, key)
        data[key] = nil
    end
    stores[name] = object
    return object
end

function Instance_.GetDataStore(_, name)
    return storeNamed(name)
end
function Instance_.GetOrderedDataStore(_, name)
    return storeNamed("ordered:" .. name)
end

---------------------------------------------------------------- Analytics and platform services
sim.analytics = {}
for _, name in ipairs({ "LogCustomEvent", "LogFunnelStepEvent", "LogEconomyEvent", "LogOnboardingFunnelStepEvent", "LogProgressionEvent" }) do
    Instance_[name] = function(_, player, ...)
        table.insert(sim.analytics, { Kind = name, Player = player, Args = table.pack(...) })
    end
end

function sim.analyticsFor(player, kind, eventName)
    local result = {}
    for _, entry in ipairs(sim.analytics) do
        if entry.Player == player and entry.Kind == kind and (eventName == nil or entry.Args[1] == eventName) then
            table.insert(result, entry)
        end
    end
    return result
end

sim.voiceUsers = {}
function Instance_.IsVoiceEnabledForUserIdAsync(_, userId)
    return sim.voiceUsers[userId] == true
end

function Instance_.SetUserIdAccessList(self, list)
    rawset(self, "__accessList", table.clone(list))
end

-- ChildAdded fires when something is parented, as in the engine.
mock.onParented = function(child, parent)
    parent.ChildAdded._fire(child)
end

-- TextChatService makes its TextChannels folder at startup.
local textChannels = Instance.new("Folder")
textChannels.Name = "TextChannels"
textChannels.Parent = game:GetService("TextChatService")

-- TweenService: tweens finish at once (the simulation checks end states, not motion).
function Instance_.Create(service, instance, _, goals)
    assert(service == game:GetService("TweenService"), "Create is only mocked for TweenService")
    local tween = mock.newInstance("Tween")
    local completed = mock.signal()
    rawset(tween, "Completed", completed)
    rawset(tween, "Play", function()
        for key, value in pairs(goals) do
            instance[key] = value
        end
        completed._fire(Enum.PlaybackState.Completed)
    end)
    rawset(tween, "Cancel", function() end)
    rawset(tween, "Pause", function() end)
    return tween
end
