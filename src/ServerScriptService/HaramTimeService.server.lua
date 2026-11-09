--!strict

-- Keeps the Masjid al-Haram hub alive over the day cycle:
--   * the four Abraj Al-Bait clock faces show the real time in Makkah (UTC+3),
--   * night lights (tagged by MasjidAlHaram) switch on after dark, and lamps, clock dials and
--     the green sa'i lights glow as Neon at night and return to their day material at dawn.
-- HubAtmosphere drives Lighting.ClockTime; this script only reads it.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local MasjidAlHaram = require(script.Parent.Modules.MasjidAlHaram)

local MAKKAH_UTC_OFFSET = 3 * 3600
local NIGHT_STARTS = 18.1
local NIGHT_ENDS = 6.2

local function isNight(clockTime: number): boolean
    return clockTime >= NIGHT_STARTS or clockTime < NIGHT_ENDS
end

local function setNight(night: boolean)
    for _, light in ipairs(CollectionService:GetTagged(MasjidAlHaram.NightLightTag)) do
        if light:IsA("Light") then
            light.Enabled = night
        end
    end

    for _, glowing in ipairs(CollectionService:GetTagged(MasjidAlHaram.NightGlowTag)) do
        if glowing:IsA("BasePart") then
            if night then
                glowing.Material = Enum.Material.Neon
            else
                local dayMaterial = glowing:GetAttribute("DayMaterial")
                local ok, material = pcall(function()
                    return (Enum.Material :: any)[dayMaterial]
                end)
                glowing.Material = if ok and material then material else Enum.Material.SmoothPlastic
            end
        end
    end
end

local function updateClockHands()
    local now = os.time() + MAKKAH_UTC_OFFSET
    local minutes = (now % 3600) / 60
    local hours = (now % 43200) / 3600

    for _, hand in ipairs(CollectionService:GetTagged(MasjidAlHaram.ClockHandTag)) do
        if hand:IsA("BasePart") then
            local pivot = hand:GetAttribute("Pivot")
            local offset = hand:GetAttribute("Offset")

            if typeof(pivot) == "CFrame" and type(offset) == "number" then
                local turns = if hand:GetAttribute("HandType") == "Hour" then hours / 12 else minutes / 60
                -- Positive rotation about the face's Z axis reads as clockwise from the front.
                hand.CFrame = pivot * CFrame.Angles(0, 0, turns * math.pi * 2) * CFrame.new(0, offset, 0)
            end
        end
    end
end

local nightShown: boolean? = nil

task.spawn(function()
    while true do
        local night = isNight(Lighting.ClockTime)

        if night ~= nightShown then
            nightShown = night
            setNight(night)
        end

        updateClockHands()
        task.wait(2)
    end
end)
