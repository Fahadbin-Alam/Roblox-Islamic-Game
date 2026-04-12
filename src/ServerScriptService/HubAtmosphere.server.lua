--!strict

local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local Workspace = game:GetService("Workspace")

local START_CLOCK_TIME = 9.15
local FULL_CYCLE_SECONDS = 780
local MIN_NIGHT_BRIGHTNESS = 1.45
local MAX_DAY_BRIGHTNESS = 2.35

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
    Workspace.Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(198, 174, 126))
    Workspace.Terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(171, 139, 96))
    Workspace.Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(116, 104, 91))
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
    Lighting.EnvironmentDiffuseScale = lerpNumber(0.42, 0.56, dayAlpha)
    Lighting.EnvironmentSpecularScale = lerpNumber(0.22, 0.42, dayAlpha)
    Lighting.OutdoorAmbient = lerpColor(Color3.fromRGB(66, 72, 92), Color3.fromRGB(174, 164, 148), dayAlpha)
    Lighting.Ambient = lerpColor(Color3.fromRGB(49, 54, 73), Color3.fromRGB(130, 121, 108), dayAlpha)
    Lighting.ColorShift_Top = lerpColor(Color3.fromRGB(111, 126, 170), Color3.fromRGB(236, 222, 199), dayAlpha)
    Lighting.ColorShift_Bottom = lerpColor(Color3.fromRGB(74, 87, 126), Color3.fromRGB(195, 179, 152), dayAlpha)
    Lighting.ShadowSoftness = lerpNumber(0.68, 0.48, dayAlpha)

    pcall(function()
        Lighting.ExposureCompensation = lerpNumber(-0.02, -0.08, dayAlpha)
    end)

    atmosphere.Color = lerpColor(Color3.fromRGB(95, 117, 168), Color3.fromRGB(220, 207, 184), dayAlpha)
    atmosphere.Decay = lerpColor(Color3.fromRGB(71, 92, 137), Color3.fromRGB(190, 167, 136), dayAlpha)
    atmosphere.Density = lerpNumber(0.32, 0.22, dayAlpha)
    atmosphere.Glare = lerpNumber(0.03, 0.11, dayAlpha)
    atmosphere.Haze = lerpNumber(1.18, 0.88, dayAlpha)
    atmosphere.Offset = lerpNumber(0.11, 0.04, dayAlpha)

    bloom.Intensity = lerpNumber(0.08, 0.16, dayAlpha)
    bloom.Size = lerpNumber(24, 30, dayAlpha)
    bloom.Threshold = lerpNumber(1.28, 1.18, dayAlpha)

    colorCorrection.Brightness = lerpNumber(-0.05, -0.04, dayAlpha)
    colorCorrection.Contrast = lerpNumber(0.16, 0.12, dayAlpha)
    colorCorrection.Saturation = lerpNumber(-0.04, -0.02, dayAlpha)
    colorCorrection.TintColor = lerpColor(Color3.fromRGB(186, 199, 232), Color3.fromRGB(238, 224, 202), dayAlpha)

    sunRays.Intensity = lerpNumber(0.005, 0.075, dayAlpha)
    sunRays.Spread = lerpNumber(0.3, 0.84, dayAlpha)

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
        Lighting.FogEnd = lerpNumber(9000, 180000, dayAlpha)
        Lighting.FogStart = 0
        Lighting.FogColor = lerpColor(Color3.fromRGB(54, 67, 102), Color3.fromRGB(188, 177, 157), dayAlpha)
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
