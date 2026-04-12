--!strict

local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local Workspace = game:GetService("Workspace")

local START_CLOCK_TIME = 9.15
local FULL_CYCLE_SECONDS = 780
local MIN_NIGHT_BRIGHTNESS = 1.2
local MAX_DAY_BRIGHTNESS = 1.82

local function ensureAtmosphere(): Atmosphere
    local existing = Lighting:FindFirstChild("JourneyAtmosphere")

    if existing then
        if existing:IsA("Atmosphere") then
            return existing
        end

        existing:Destroy()
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "JourneyAtmosphere"
    atmosphere.Parent = Lighting

    return atmosphere
end

local function ensureBloom(): BloomEffect
    local existing = Lighting:FindFirstChild("JourneyBloom")

    if existing then
        if existing:IsA("BloomEffect") then
            return existing
        end

        existing:Destroy()
    end

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "JourneyBloom"
    bloom.Parent = Lighting

    return bloom
end

local function ensureColorCorrection(): ColorCorrectionEffect
    local existing = Lighting:FindFirstChild("JourneyColor")

    if existing then
        if existing:IsA("ColorCorrectionEffect") then
            return existing
        end

        existing:Destroy()
    end

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "JourneyColor"
    colorCorrection.Parent = Lighting

    return colorCorrection
end

local function ensureSunRays(): SunRaysEffect
    local existing = Lighting:FindFirstChild("JourneySunRays")

    if existing then
        if existing:IsA("SunRaysEffect") then
            return existing
        end

        existing:Destroy()
    end

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "JourneySunRays"
    sunRays.Parent = Lighting

    return sunRays
end

local function ensureDepthOfField(): DepthOfFieldEffect
    local existing = Lighting:FindFirstChild("JourneyDepthOfField")

    if existing then
        if existing:IsA("DepthOfFieldEffect") then
            return existing
        end

        existing:Destroy()
    end

    local depthOfField = Instance.new("DepthOfFieldEffect")
    depthOfField.Name = "JourneyDepthOfField"
    depthOfField.Parent = Lighting

    return depthOfField
end

local function ensureSky(): Sky
    local existing = Lighting:FindFirstChild("JourneySky")

    if existing then
        if existing:IsA("Sky") then
            return existing
        end

        existing:Destroy()
    end

    local fallback = Lighting:FindFirstChildOfClass("Sky")

    if fallback then
        fallback.Name = "JourneySky"
        return fallback
    end

    local sky = Instance.new("Sky")
    sky.Name = "JourneySky"
    sky.Parent = Lighting

    return sky
end

local function ensureClouds(): Clouds
    local existing = Workspace.Terrain:FindFirstChild("JourneyClouds")

    if existing then
        if existing:IsA("Clouds") then
            return existing
        end

        existing:Destroy()
    end

    local clouds = Instance.new("Clouds")
    clouds.Name = "JourneyClouds"
    clouds.Parent = Workspace.Terrain

    return clouds
end

local function lerpNumber(a: number, b: number, alpha: number): number
    return a + (b - a) * alpha
end

local function lerpColor(a: Color3, b: Color3, alpha: number): Color3
    return Color3.new(
        lerpNumber(a.R, b.R, alpha),
        lerpNumber(a.G, b.G, alpha),
        lerpNumber(a.B, b.B, alpha)
    )
end

local function getDaylightAlpha(clockTime: number): number
    local angular = ((clockTime - 12) / 12) * math.pi
    local cosine = math.cos(angular)

    -- Keep dawn/dusk softer so the switch from day to night feels natural.
    return math.clamp((cosine + 0.25) / 1.25, 0, 1)
end

pcall(function()
    Lighting.Technology = Enum.Technology.Future
end)
pcall(function()
    MaterialService.Use2022Materials = true
end)
pcall(function()
    Workspace.Terrain.Decoration = true
end)
pcall(function()
    Workspace.Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(186, 164, 119))
    Workspace.Terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(160, 132, 94))
    Workspace.Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(109, 98, 86))
end)

local atmosphere = ensureAtmosphere()
local bloom = ensureBloom()
local colorCorrection = ensureColorCorrection()
local sunRays = ensureSunRays()
local depthOfField = ensureDepthOfField()
local sky = ensureSky()
local clouds = ensureClouds()

sky.CelestialBodiesShown = true
pcall(function()
    sky.MoonAngularSize = 18
end)
pcall(function()
    sky.SunAngularSize = 20
end)

local function applyCycleLighting(clockTime: number)
    local dayAlpha = getDaylightAlpha(clockTime)
    local nightAlpha = 1 - dayAlpha

    Lighting.ClockTime = clockTime
    Lighting.Brightness = lerpNumber(MIN_NIGHT_BRIGHTNESS, MAX_DAY_BRIGHTNESS, dayAlpha)
    Lighting.EnvironmentDiffuseScale = lerpNumber(0.36, 0.48, dayAlpha)
    Lighting.EnvironmentSpecularScale = lerpNumber(0.18, 0.3, dayAlpha)
    Lighting.OutdoorAmbient = lerpColor(Color3.fromRGB(63, 70, 88), Color3.fromRGB(152, 145, 132), dayAlpha)
    Lighting.Ambient = lerpColor(Color3.fromRGB(45, 51, 68), Color3.fromRGB(116, 109, 98), dayAlpha)
    Lighting.ColorShift_Top = lerpColor(Color3.fromRGB(105, 120, 162), Color3.fromRGB(221, 207, 186), dayAlpha)
    Lighting.ColorShift_Bottom = lerpColor(Color3.fromRGB(72, 84, 120), Color3.fromRGB(182, 168, 144), dayAlpha)
    Lighting.ShadowSoftness = lerpNumber(0.72, 0.54, dayAlpha)

    pcall(function()
        Lighting.ExposureCompensation = lerpNumber(-0.12, -0.22, dayAlpha)
    end)

    atmosphere.Color = lerpColor(Color3.fromRGB(92, 111, 156), Color3.fromRGB(212, 197, 174), dayAlpha)
    atmosphere.Decay = lerpColor(Color3.fromRGB(69, 88, 129), Color3.fromRGB(179, 158, 129), dayAlpha)
    atmosphere.Density = lerpNumber(0.35, 0.25, dayAlpha)
    atmosphere.Glare = lerpNumber(0.02, 0.08, dayAlpha)
    atmosphere.Haze = lerpNumber(1.26, 1.02, dayAlpha)
    atmosphere.Offset = lerpNumber(0.11, 0.04, dayAlpha)

    bloom.Intensity = lerpNumber(0.05, 0.1, dayAlpha)
    bloom.Size = lerpNumber(18, 24, dayAlpha)
    bloom.Threshold = lerpNumber(1.34, 1.26, dayAlpha)

    colorCorrection.Brightness = lerpNumber(-0.08, -0.06, dayAlpha)
    colorCorrection.Contrast = lerpNumber(0.18, 0.15, dayAlpha)
    colorCorrection.Saturation = lerpNumber(-0.08, -0.05, dayAlpha)
    colorCorrection.TintColor = lerpColor(Color3.fromRGB(181, 194, 226), Color3.fromRGB(229, 215, 194), dayAlpha)

    sunRays.Intensity = lerpNumber(0.003, 0.048, dayAlpha)
    sunRays.Spread = lerpNumber(0.28, 0.72, dayAlpha)

    depthOfField.FarIntensity = lerpNumber(0.2, 0.12, dayAlpha)
    depthOfField.FocusDistance = lerpNumber(90, 120, dayAlpha)
    depthOfField.InFocusRadius = lerpNumber(65, 86, dayAlpha)
    depthOfField.NearIntensity = lerpNumber(0.03, 0.02, dayAlpha)

    -- Keep stars and moon much clearer at night.
    sky.StarCount = math.floor(lerpNumber(2900, 260, dayAlpha))
    sky.SunAngularSize = lerpNumber(12, 20, dayAlpha)
    pcall(function()
        sky.MoonAngularSize = lerpNumber(20, 14, dayAlpha)
    end)

    pcall(function()
        Lighting.GlobalShadows = true
        Lighting.FogEnd = lerpNumber(8000, 120000, dayAlpha)
        Lighting.FogStart = 0
        Lighting.FogColor = lerpColor(Color3.fromRGB(54, 66, 99), Color3.fromRGB(178, 167, 149), dayAlpha)
    end)

    -- Tiny nudge to moon visibility on darker moments.
    if nightAlpha > 0.7 then
        sky.CelestialBodiesShown = true
    end

    -- Terrain clouds help break up the flat Roblox sky look.
    clouds.Cover = lerpNumber(0.48, 0.32, dayAlpha)
    clouds.Density = lerpNumber(0.92, 0.68, dayAlpha)
    clouds.Color = lerpColor(Color3.fromRGB(168, 179, 208), Color3.fromRGB(246, 241, 231), dayAlpha)
    clouds.Enabled = true
end

local cycleStart = os.clock()

applyCycleLighting(START_CLOCK_TIME)

task.spawn(function()
    while true do
        local elapsed = os.clock() - cycleStart
        local clockTime = (START_CLOCK_TIME + (elapsed / FULL_CYCLE_SECONDS) * 24) % 24
        applyCycleLighting(clockTime)
        task.wait(0.2)
    end
end)
