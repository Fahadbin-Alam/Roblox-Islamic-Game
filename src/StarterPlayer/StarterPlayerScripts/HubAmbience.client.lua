--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local trailPulses: { Instance } = {}
local rideableCamels: { Instance } = {}
local camelRootPoseCache: { [Model]: CFrame } = {}

local function getNumberAttribute(instance: Instance, name: string, fallback: number): number
    local value = instance:GetAttribute(name)

    if type(value) == "number" then
        return value
    end

    return fallback
end

local function getBasePart(parent: Instance, name: string): BasePart?
    local child = parent:FindFirstChild(name)

    if child and child:IsA("BasePart") then
        return child
    end

    return nil
end

local function addTrackedInstance(list: { Instance }, instance: Instance)
    if table.find(list, instance) then
        return
    end

    table.insert(list, instance)
end

local function removeTrackedInstance(list: { Instance }, instance: Instance)
    local index = table.find(list, instance)

    if index then
        table.remove(list, index)
    end
end

local function dampAlpha(deltaTime: number, responsiveness: number): number
    return math.clamp(deltaTime * responsiveness, 0, 1)
end

local function animateTrailPulse(part: BasePart, now: number)
    local phase = getNumberAttribute(part, "PulsePhase", 0)
    local pulse = (math.sin(now * 2.8 + phase) + 1) * 0.5

    part.Transparency = 0.18 + pulse * 0.36
end

local function setCamelPart(model: Model, name: string, cframe: CFrame)
    local part = getBasePart(model, name)

    if part then
        part.CFrame = cframe
    end
end

local function animateCamelLeg(model: Model, pivot: CFrame, index: number, localOffset: Vector3, stride: number, lift: number)
    local leg = getBasePart(model, string.format("Leg_%d", index))
    local hoof = getBasePart(model, string.format("Hoof_%d", index))
    local swingOffset = Vector3.new(stride * 0.42, lift * 0.16, 0)

    if leg then
        leg.CFrame = pivot * CFrame.new(localOffset + swingOffset) * CFrame.Angles(0, 0, stride * 0.12)
    end

    if hoof then
        hoof.CFrame = pivot * CFrame.new(localOffset + Vector3.new(stride * 0.62, -4.9 + lift, 0)) * CFrame.Angles(0, 0, stride * 0.1)
    end
end

local function animateRideableCamel(model: Model, now: number, deltaTime: number)
    local root = model.PrimaryPart or getBasePart(model, "CamelRoot")

    if not root then
        return
    end

    model.PrimaryPart = root

    local seat = model:FindFirstChild("CamelSeat", true)
    local throttle = 0
    local steer = 0

    if seat and seat:IsA("VehicleSeat") and seat.Occupant then
        throttle = seat.ThrottleFloat
        steer = seat.SteerFloat
    end

    local moving = math.abs(throttle) > 0.04 or math.abs(steer) > 0.04
    local phase = getNumberAttribute(model, "StridePhase", 0)
    local pace = moving and 7.4 or 1.4
    local strideScale = moving and 1 or 0.14
    local wave = now * pace + phase
    local strideA = math.sin(wave) * strideScale
    local strideB = math.sin(wave + math.pi) * strideScale
    local liftA = math.max(0, math.sin(wave)) * (moving and 0.65 or 0.08)
    local liftB = math.max(0, math.sin(wave + math.pi)) * (moving and 0.65 or 0.08)
    local bob = (moving and math.abs(math.sin(wave)) * 0.28 or math.sin(now * 1.1 + phase) * 0.08)
    local neckNod = math.sin(wave + 0.6) * (moving and 0.08 or 0.025)
    local tailSway = math.sin(wave + 1.1) * (moving and 0.18 or 0.06)
    local smoothedRoot = camelRootPoseCache[model] and camelRootPoseCache[model]:Lerp(root.CFrame, dampAlpha(deltaTime, 9.2)) or root.CFrame
    camelRootPoseCache[model] = smoothedRoot
    local pivot = smoothedRoot * CFrame.new(0, bob, 0)

    setCamelPart(model, "Body", pivot * CFrame.new(0, 1.2, 0))
    setCamelPart(model, "Hump", pivot * CFrame.new(-1.6, 5.2, 0) * CFrame.Angles(0, math.rad(180), 0))
    setCamelPart(model, "Chest", pivot * CFrame.new(-7.2, 1.4, 0))
    setCamelPart(model, "Neck", pivot * CFrame.new(-10, 6.6, 0) * CFrame.Angles(0, 0, math.rad(-18) + neckNod))
    setCamelPart(model, "Head", pivot * CFrame.new(-11.9, 10.8, 0) * CFrame.Angles(0, 0, neckNod * 0.45))
    setCamelPart(model, "Muzzle", pivot * CFrame.new(-15.4, 10.3, 0) * CFrame.Angles(0, 0, neckNod * 0.45))
    setCamelPart(model, "LeftEar", pivot * CFrame.new(-11.7, 13.1, -1.15) * CFrame.Angles(math.rad(12), 0, math.rad(-10) + neckNod))
    setCamelPart(model, "RightEar", pivot * CFrame.new(-11.7, 13.1, 1.15) * CFrame.Angles(math.rad(-12), 0, math.rad(-10) + neckNod))
    setCamelPart(model, "Tail", pivot * CFrame.new(8.8, 2.7, 0) * CFrame.Angles(0, 0, math.rad(34) + tailSway))
    setCamelPart(model, "SaddleBlanket", pivot * CFrame.new(1.2, 5, 0))
    setCamelPart(model, "SaddleBack", pivot * CFrame.new(4.2, 6.1, 0))
    setCamelPart(model, "SaddleFront", pivot * CFrame.new(-2.4, 5.95, 0))

    animateCamelLeg(model, pivot, 1, Vector3.new(-5.2, -3.2, -2.1), strideA, liftA)
    animateCamelLeg(model, pivot, 2, Vector3.new(-5.2, -3.2, 2.1), strideB, liftB)
    animateCamelLeg(model, pivot, 3, Vector3.new(5.2, -3.2, -2.1), strideB, liftB)
    animateCamelLeg(model, pivot, 4, Vector3.new(5.2, -3.2, 2.1), strideA, liftA)
end

local function applyCameraPolish(now: number)
    local camera = Workspace.CurrentCamera

    if not camera or camera.CameraType == Enum.CameraType.Scriptable then
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return
    end

    local seatPart = humanoid.SeatPart

    if seatPart and seatPart:IsA("VehicleSeat") and seatPart:GetAttribute("PromptAction") == "RideCamel" then
        local rideInput = math.clamp(math.abs(seatPart.ThrottleFloat) + math.abs(seatPart.SteerFloat) * 0.45, 0, 1)
        local rideBob = math.sin(now * 7.4) * 0.07 * rideInput
        local rideSide = math.cos(now * 3.7) * 0.04 * rideInput

        humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.new(rideSide, rideBob, 0), 0.16)
        camera.FieldOfView = camera.FieldOfView + ((73 + rideInput * 4.5) - camera.FieldOfView) * 0.08
        return
    end

    local speed = root.AssemblyLinearVelocity.Magnitude

    if speed < 1 then
        humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.zero, 0.14)
        camera.FieldOfView = camera.FieldOfView + ((player:GetAttribute("InBattle") == true and 76 or 72) - camera.FieldOfView) * 0.08
        return
    end

    local battleScale = player:GetAttribute("InBattle") == true and 0.1 or 0.06
    local bob = math.sin(now * 9.2) * battleScale
    local side = math.cos(now * 4.6) * battleScale * 0.55
    local baseFov = player:GetAttribute("InBattle") == true and 76 or 72
    local targetFov = baseFov + math.clamp(speed / 24, 0, 1) * 3.5

    humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.new(side, bob, 0), 0.18)
    camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * 0.08
end

for _, instance in ipairs(CollectionService:GetTagged("TrailPulse")) do
    addTrackedInstance(trailPulses, instance)
end

for _, instance in ipairs(CollectionService:GetTagged("RideableCamel")) do
    addTrackedInstance(rideableCamels, instance)
end

CollectionService:GetInstanceAddedSignal("TrailPulse"):Connect(function(instance: Instance)
    addTrackedInstance(trailPulses, instance)
end)

CollectionService:GetInstanceRemovedSignal("TrailPulse"):Connect(function(instance: Instance)
    removeTrackedInstance(trailPulses, instance)
end)

CollectionService:GetInstanceAddedSignal("RideableCamel"):Connect(function(instance: Instance)
    addTrackedInstance(rideableCamels, instance)
end)

CollectionService:GetInstanceRemovedSignal("RideableCamel"):Connect(function(instance: Instance)
    removeTrackedInstance(rideableCamels, instance)
end)

RunService.RenderStepped:Connect(function(deltaTime)
    local now = os.clock()

    for index = #trailPulses, 1, -1 do
        local instance = trailPulses[index]

        if not instance.Parent then
            table.remove(trailPulses, index)
            continue
        end

        if instance:IsA("BasePart") then
            animateTrailPulse(instance, now)
        end
    end

    for index = #rideableCamels, 1, -1 do
        local instance = rideableCamels[index]

        if not instance.Parent then
            if instance:IsA("Model") then
                camelRootPoseCache[instance] = nil
            end
            table.remove(rideableCamels, index)
            continue
        end

        if instance:IsA("Model") then
            animateRideableCamel(instance, now, deltaTime)
        end
    end

    applyCameraPolish(now)
end)
