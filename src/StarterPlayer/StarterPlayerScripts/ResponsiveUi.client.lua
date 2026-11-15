--!strict

-- Many panels are laid out in fixed pixel sizes that overflow phone screens. This shrinks each
-- such panel with a UIScale just enough to keep it fully on screen, and leaves it at full size
-- wherever it already fits.

local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local MARGIN = 12
local MIN_SCALE = 0.5

-- ScreenGuis whose top-level frames use fixed pixel sizes. The main menu also moves to the
-- center of the screen when it has to shrink, which leaves it the most room.
local TARGETS: { [string]: { Recenter: boolean } } = {
    MainMenu = { Recenter = true },
    ShopMenu = { Recenter = false },
    MannersHud = { Recenter = false },
    TriviaHud = { Recenter = false },
    StoryHud = { Recenter = false },
    LearningTrailHud = { Recenter = false },
    BattleHud = { Recenter = false },
    MissionHud = { Recenter = false },
}

type Original = { AnchorPoint: Vector2, Position: UDim2 }

local originals: { [GuiObject]: Original } = {}

-- Largest scale (at most 1) that keeps one axis of the frame inside the screen, given that a
-- UIScale grows and shrinks a frame around its anchor point.
local function fitAxis(screen: number, position: number, anchor: number, length: number): number
    local fit = math.huge

    if anchor > 0 then
        fit = math.min(fit, (position - MARGIN) / (anchor * length))
    end

    if anchor < 1 then
        fit = math.min(fit, (screen - MARGIN - position) / ((1 - anchor) * length))
    end

    return fit
end

local function fitFrame(screenGui: ScreenGui, frame: GuiObject, recenter: boolean)
    local size = frame.Size

    if size.X.Scale ~= 0 or size.Y.Scale ~= 0 or size.X.Offset <= 0 or size.Y.Offset <= 0 then
        return
    end

    local screen = screenGui.AbsoluteSize

    if screen.X <= 0 or screen.Y <= 0 then
        return
    end

    local original: Original = originals[frame] or { AnchorPoint = frame.AnchorPoint, Position = frame.Position }
    originals[frame] = original

    local function scaleAt(anchorPoint: Vector2, position: UDim2): number
        local x = position.X.Scale * screen.X + position.X.Offset
        local y = position.Y.Scale * screen.Y + position.Y.Offset

        return math.min(
            1,
            fitAxis(screen.X, x, anchorPoint.X, size.X.Offset),
            fitAxis(screen.Y, y, anchorPoint.Y, size.Y.Offset)
        )
    end

    local scale = scaleAt(original.AnchorPoint, original.Position)

    if recenter and scale < 1 then
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        scale = scaleAt(frame.AnchorPoint, frame.Position)
    else
        frame.AnchorPoint = original.AnchorPoint
        frame.Position = original.Position
    end

    local existing = frame:FindFirstChild("ResponsiveScale")
    local uiScale: UIScale

    if existing and existing:IsA("UIScale") then
        uiScale = existing
    else
        uiScale = Instance.new("UIScale")
        uiScale.Name = "ResponsiveScale"
        uiScale.Parent = frame
    end

    uiScale.Scale = math.max(MIN_SCALE, scale)
end

local function fitScreenGui(screenGui: ScreenGui)
    local config = TARGETS[screenGui.Name]

    if not config then
        return
    end

    for _, child in ipairs(screenGui:GetChildren()) do
        if child:IsA("GuiObject") then
            fitFrame(screenGui, child, config.Recenter)
        end
    end
end

local watched: { [ScreenGui]: boolean } = {}

local function watch(instance: Instance)
    if not instance:IsA("ScreenGui") or not TARGETS[instance.Name] or watched[instance] then
        return
    end

    local screenGui = instance
    watched[screenGui] = true

    -- Frames are created right after the ScreenGui, so wait a frame before measuring.
    task.defer(fitScreenGui, screenGui)
    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        fitScreenGui(screenGui)
    end)
    screenGui.ChildAdded:Connect(function()
        task.defer(fitScreenGui, screenGui)
    end)
end

for _, child in ipairs(playerGui:GetChildren()) do
    watch(child)
end

playerGui.ChildAdded:Connect(watch)
