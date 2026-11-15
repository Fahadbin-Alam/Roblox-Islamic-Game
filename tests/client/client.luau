-- Client layer for tests/client: one simulated player becomes Players.LocalPlayer, server
-- messages reach the client's OnClientEvent handlers, and FireServer reaches the server.
local Instance_ = mock.Instance_
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

sim.advance(2)
localPlayer = sim.addPlayer(9001, "LocalTester")
rawset(Players, "LocalPlayer", localPlayer)
local playerGui = Instance.new("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
local playerScripts = Instance.new("PlayerScripts")
playerScripts.Name = "PlayerScripts"
playerScripts.Parent = localPlayer

local camera = Instance.new("Camera")
camera.Name = "Camera"
camera.ViewportSize = Vector2.new(1280, 720)
camera.CFrame = CFrame.new(0, 20, 0)
camera.Parent = Workspace
rawset(Workspace, "CurrentCamera", camera)

clientErrors = {}

local function report(where, err)
    table.insert(clientErrors, where .. ": " .. tostring(err))
end

-- A script error inside a waiting thread ends that thread (as in Roblox) and is recorded;
-- time keeps running for everything else.
local rawAdvance = sim.advance
function sim.advance(seconds)
    local target = sim.now() + seconds
    while true do
        local ok, err = pcall(rawAdvance, math.max(0, target - sim.now()))
        if ok then
            return
        end
        report("running thread", err)
    end
end

-- Errors inside client handlers are recorded and the run carries on, so one broken HUD does
-- not hide the others.
local inClient = false
local baseFireClient = Instance_.FireClient
function Instance_.FireClient(remote, player, ...)
    baseFireClient(remote, player, ...)
    if player == localPlayer then
        local args = table.pack(...)
        local ok, err = xpcall(function()
            remote.OnClientEvent._fire(table.unpack(args, 1, args.n))
        end, debug.traceback)
        if not ok then
            report("handling " .. remote:GetFullName(), err)
        end
    end
end
function Instance_.FireServer(remote, ...)
    local args = table.pack(...)
    local ok, err = xpcall(function()
        remote.OnServerEvent._fire(localPlayer, table.unpack(args, 1, args.n))
    end, debug.traceback)
    if not ok then
        report("server handling " .. remote:GetFullName(), err)
    end
end
local uis = game:GetService("UserInputService")
uis.TouchEnabled = false
uis.KeyboardEnabled = true
uis.MouseEnabled = true
uis.GamepadEnabled = false
local runService = game:GetService("RunService")
rawset(Instance_, "IsClient", function()
    return true
end)
rawset(Instance_, "IsServer", function()
    return false
end)

-- A frame loop so RenderStepped/Heartbeat handlers run.
task.spawn(function()
    while true do
        local dt = task.wait(1 / 30)
        local ok, err = xpcall(function()
            runService.RenderStepped._fire(dt)
            runService.Heartbeat._fire(dt)
            runService.Stepped._fire(sim.now(), dt)
        end, debug.traceback)
        if not ok then
            report("frame loop", err)
            break
        end
    end
end)

loadedClients = {}

function runClient(name, body)
    local co = coroutine.create(function()
        local ok, err = xpcall(body, debug.traceback)
        if not ok then
            report(name .. " (while loading)", err)
        end
    end)
    local ok, err = coroutine.resume(co)
    if not ok then
        report(name .. " (while loading)", err)
    end
    table.insert(loadedClients, name)
end
