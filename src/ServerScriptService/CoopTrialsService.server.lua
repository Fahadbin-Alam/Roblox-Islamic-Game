--!strict

-- Trials of Brotherhood: a two-player co-op puzzle course. Its theme is the brotherhood between
-- the Muhajirun and the Ansar in Madinah (Seerah chapter 19); the puzzles themselves are game
-- inventions and the signs say so.
--
-- 1. Twin Plates: a gate opens only while someone stands on a plate. One plate is before the
--    gate and one after it, so one player holds it for the other, who then holds it back.
-- 2. The Lift: the lift rises while a partner stands on the counterweight. On the ledge, the
--    rider holds a plate that lowers the stairway for the partner below.
-- 3. Together: the finish counts only when two players stand on the twin pads at once.
--
-- One player can never pass gate 1 alone: the gate shuts the moment its plate is empty.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TravelRoute = require(Shared.Data.TravelRoute)
local BuildUtils = require(script.Parent.Modules.BuildUtils)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local Analytics = require(script.Parent.Modules.Analytics)

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Coop")
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local CENTER = (TravelRoute.GetDestinationById("coop_trials") :: any).Position - Vector3.new(0, 4, 0)
local G = 4 -- ground top
local LEDGE = 20
local STONE = Color3.fromRGB(184, 172, 150)
local TEAL = Color3.fromRGB(71, 112, 128)

local existing = Workspace:FindFirstChild("CoopTrials")

if existing then
    existing:Destroy()
end

local folder = BuildUtils.CreateFolder(Workspace, "CoopTrials")

local function block(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?, transparency: number?): Part
    return BuildUtils.CreatePart(folder, name, size, CFrame.new(CENTER + offset), color, material or Enum.Material.Slate, nil, transparency)
end

local function boardAt(name: string, offset: Vector3, title: string, body: string)
    local board = BuildUtils.CreateBoardSign(folder, name, CENTER + offset, title, body, TEAL, nil)
    board.Orientation = Vector3.new(0, 0, 0)
end

-- Ground, side walls, and the start area.
block("SafetyPlate", Vector3.new(300, 10, 400), Vector3.new(0, -8, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1)
block("Ground", Vector3.new(84, G, 260), Vector3.new(0, G / 2, 0), Color3.fromRGB(208, 196, 172), Enum.Material.Sandstone)
block("WallWest", Vector3.new(2, 34, 260), Vector3.new(-42, G + 17, 0), STONE)
block("WallEast", Vector3.new(2, 34, 260), Vector3.new(42, G + 17, 0), STONE)
block("WallBack", Vector3.new(84, 34, 2), Vector3.new(0, G + 17, -130), STONE)
boardAt("StartSign", Vector3.new(0, G, -100), "Trials of Brotherhood", "A co-op course for two or more. In Madinah, each emigrant was paired with a helper of the Ansar. Help each other through. The puzzles are a game; the brotherhood is history.")

-- Stage 1: gate wall with a doorway, plate A before it and plate B after it.
block("GateWallWest", Vector3.new(37, 34, 2), Vector3.new(-23.5, G + 17, -40), STONE)
block("GateWallEast", Vector3.new(37, 34, 2), Vector3.new(23.5, G + 17, -40), STONE)
local gate = block("Gate", Vector3.new(10, 34, 1.6), Vector3.new(0, G + 17, -40), Color3.fromRGB(110, 80, 52), Enum.Material.WoodPlanks)
local plateA = block("PlateA", Vector3.new(8, 0.6, 8), Vector3.new(-28, G + 0.3, -62), Color3.fromRGB(196, 150, 70), Enum.Material.Metal)
local plateB = block("PlateB", Vector3.new(8, 0.6, 8), Vector3.new(-28, G + 0.3, -24), Color3.fromRGB(196, 150, 70), Enum.Material.Metal)
boardAt("Stage1Sign", Vector3.new(0, G, -72), "1. Twin Plates", "The gate stays open only while someone stands on a gold plate. One of you holds it, the other goes through and holds the far plate.")

-- Stage 2: the ledge, the lift, the counterweight, and the hidden stairway.
block("LedgeFace", Vector3.new(84, LEDGE, 120), Vector3.new(0, G + LEDGE / 2, 70), STONE)
local lift = block("Lift", Vector3.new(10, 1, 10), Vector3.new(-24, G + 0.5, 4), TEAL, Enum.Material.Metal)
local liftBottom = lift.CFrame
local liftTop = lift.CFrame + Vector3.new(0, LEDGE, 0)
local counterweight = block("Counterweight", Vector3.new(8, 0.6, 8), Vector3.new(6, G + 0.3, -12), Color3.fromRGB(196, 150, 70), Enum.Material.Metal)
local plateC = block("PlateC", Vector3.new(8, 0.6, 8), Vector3.new(0, G + LEDGE + 0.3, 24), Color3.fromRGB(196, 150, 70), Enum.Material.Metal)
local stairs = BuildUtils.CreateWedge(folder, "Stairway", Vector3.new(10, LEDGE, 34), CFrame.new(CENTER + Vector3.new(26, G + LEDGE / 2, -7)), Color3.fromRGB(160, 140, 112), Enum.Material.Slate, 0.85)
stairs.CanCollide = false
boardAt("Stage2Sign", Vector3.new(-14, G, -34), "2. The Lift", "Stand on the counterweight to raise your partner's lift. Up on the ledge, hold the plate to lower the stairway for the one below.")

-- Stage 3: twin finish pads on the ledge.
local padLeft = block("FinishLeft", Vector3.new(8, 0.6, 8), Vector3.new(-14, G + LEDGE + 0.3, 104), Color3.fromRGB(120, 170, 120), Enum.Material.Neon)
local padRight = block("FinishRight", Vector3.new(8, 0.6, 8), Vector3.new(14, G + LEDGE + 0.3, 104), Color3.fromRGB(120, 170, 120), Enum.Material.Neon)
boardAt("Stage3Sign", Vector3.new(0, G + LEDGE, 84), "3. Together", "Stand on both green pads at the same time to finish the trial together.")

local function playersOn(plate: BasePart): { Player }
    local list = {}
    local half = plate.Size / 2

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
            local offset = plate.CFrame:PointToObjectSpace(root.Position)

            if math.abs(offset.X) <= half.X + 1 and math.abs(offset.Z) <= half.Z + 1 and offset.Y > 0 and offset.Y < 6 then
                table.insert(list, player)
            end
        end
    end

    return list
end

local function inCourse(player: Player): boolean
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return false
    end

    local offset = root.Position - CENTER

    return math.abs(offset.X) < 44 and math.abs(offset.Z) < 132 and offset.Y < 70
end

local function setLit(plate: BasePart, lit: boolean)
    plate.Material = if lit then Enum.Material.Neon else Enum.Material.Metal
end

local liftUp = false
local liftTween: Tween? = nil
local finishedAt = -math.huge
-- A finish counts once per arrival: players must step off the pads before it can count again,
-- so standing still on them never farms finishes.
local wasTogether = false

local function moveLift(up: boolean)
    if up == liftUp then
        return
    end

    liftUp = up

    if liftTween then
        liftTween:Cancel()
    end

    local tween = TweenService:Create(lift, TweenInfo.new(if up then 3 else 1.5, Enum.EasingStyle.Sine), { CFrame = if up then liftTop else liftBottom })
    liftTween = tween
    tween:Play()
end

local lastState = ""

task.spawn(function()
    while true do
        task.wait(0.1)

        local onA, onB = playersOn(plateA), playersOn(plateB)
        local gateOpen = #onA > 0 or #onB > 0
        gate.CanCollide = not gateOpen
        gate.Transparency = if gateOpen then 0.8 else 0
        setLit(plateA, #onA > 0)
        setLit(plateB, #onB > 0)

        -- The counterweight only works when the person on it is not also riding the lift.
        local weight = playersOn(counterweight)
        moveLift(#weight > 0)
        setLit(counterweight, #weight > 0)

        local onC = playersOn(plateC)
        local stairsDown = #onC > 0
        stairs.CanCollide = stairsDown
        stairs.Transparency = if stairsDown then 0 else 0.85
        setLit(plateC, stairsDown)

        local left, right = playersOn(padLeft), playersOn(padRight)
        local together = {}

        for _, player in ipairs(left) do
            together[player] = true
        end

        for _, player in ipairs(right) do
            together[player] = true
        end

        local distinct = 0

        for _ in pairs(together) do
            distinct += 1
        end

        local isTogether = #left > 0 and #right > 0 and distinct >= 2
        local arrived = isTogether and not wasTogether
        wasTogether = isTogether

        if arrived and os.clock() - finishedAt > 8 then
            finishedAt = os.clock()

            for _, player in ipairs(Players:GetPlayers()) do
                if inCourse(player) then
                    PlayerProgress.RecordCompletion(player, "coop", "brotherhood_trials", "Trials of Brotherhood")
                    PlayerProgress.IncrementStat(player, "CoopFinishes", 1)
                    Analytics.Custom(player, "CoopFinish", distinct)
                    stateEvent:FireClient(player, { Event = "finish", Players = distinct })
                end
            end
        end

        local state = string.format("%s%s%s%s", tostring(gateOpen), tostring(liftUp), tostring(stairsDown), tostring(#left > 0 and #right > 0))

        if state ~= lastState then
            lastState = state

            for _, player in ipairs(Players:GetPlayers()) do
                if inCourse(player) then
                    stateEvent:FireClient(player, { Event = "state", GateOpen = gateOpen, LiftUp = liftUp, StairsDown = stairsDown })
                end
            end
        end
    end
end)

folder:SetAttribute("Built", true)
