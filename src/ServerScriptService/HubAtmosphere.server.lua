--!strict

local Lighting = game:GetService("Lighting")

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

Lighting.Brightness = 2.8
Lighting.ClockTime = 8.8
Lighting.EnvironmentDiffuseScale = 0.48
Lighting.EnvironmentSpecularScale = 0.38
Lighting.OutdoorAmbient = Color3.fromRGB(205, 196, 182)
Lighting.Ambient = Color3.fromRGB(156, 149, 138)
Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 229)
Lighting.ColorShift_Bottom = Color3.fromRGB(227, 214, 192)

local atmosphere = ensureAtmosphere()
atmosphere.Color = Color3.fromRGB(233, 223, 205)
atmosphere.Decay = Color3.fromRGB(223, 205, 179)
atmosphere.Density = 0.2
atmosphere.Glare = 0.18
atmosphere.Haze = 0.72
atmosphere.Offset = 0.04

local bloom = ensureBloom()
bloom.Intensity = 0.2
bloom.Size = 28
bloom.Threshold = 1.2

local colorCorrection = ensureColorCorrection()
colorCorrection.Brightness = 0.03
colorCorrection.Contrast = 0.09
colorCorrection.Saturation = -0.01
colorCorrection.TintColor = Color3.fromRGB(255, 245, 233)

local sunRays = ensureSunRays()
sunRays.Intensity = 0.06
sunRays.Spread = 0.84
