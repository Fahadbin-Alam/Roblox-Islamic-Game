--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CAMEL_TAG = "RideableCamel"

type CamelState = {
    Seat: VehicleSeat?,
    PromptConnections: { RBXScriptConnection },
    CurrentThrottle: number,
    CurrentSteer: number,
}

local camelStates: { [Model]: CamelState } = {}
local promptConnections: { [ProximityPrompt]: RBXScriptConnection } = {}

local function getCamelFromInstance(instance: Instance): Model?
    local current: Instance? = instance

    while current do
        if current:IsA("Model") and CollectionService:HasTag(current, CAMEL_TAG) then
            return current
        end

        current = current.Parent
    end

    return nil
end

local function getSeat(camel: Model): VehicleSeat?
    local existing = camel:FindFirstChild("CamelSeat", true)

    if existing and existing:IsA("VehicleSeat") then
        return existing
    end

    return nil
end

local function getRoot(camel: Model): BasePart?
    if camel.PrimaryPart then
        return camel.PrimaryPart
    end

    local root = camel:FindFirstChild("CamelRoot", true)

    if root and root:IsA("BasePart") then
        camel.PrimaryPart = root
        return root
    end

    return nil
end

local function setCamelPromptEnabled(camel: Model, enabled: boolean)
    for _, descendant in ipairs(camel:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant:GetAttribute("PromptAction") == "RideCamel" then
            descendant.Enabled = enabled
        end
    end
end

local function seatPlayerOnCamel(player: Player, camel: Model)
    local seat = getSeat(camel)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not seat or not humanoid or humanoid.Health <= 0 then
        return
    end

    if seat.Occupant and seat.Occupant ~= humanoid then
        return
    end

    seat:Sit(humanoid)
    setCamelPromptEnabled(camel, false)
end

local function connectPrompt(prompt: ProximityPrompt)
    if promptConnections[prompt] then
        return
    end

    if prompt:GetAttribute("PromptAction") ~= "RideCamel" then
        return
    end

    promptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
        local camel = getCamelFromInstance(prompt)

        if camel then
            seatPlayerOnCamel(player, camel)
        end
    end)
end

local function setupCamel(camel: Model)
    if camelStates[camel] then
        return
    end

    local seat = getSeat(camel)

    if not seat then
        return
    end

    local promptState = {
        Seat = seat,
        PromptConnections = {},
        CurrentThrottle = 0,
        CurrentSteer = 0,
    }
    camelStates[camel] = promptState

    for _, descendant in ipairs(camel:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            connectPrompt(descendant)
        end
    end

    table.insert(promptState.PromptConnections, camel.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            connectPrompt(descendant)
        end
    end))

    table.insert(promptState.PromptConnections, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        setCamelPromptEnabled(camel, seat.Occupant == nil)
    end))
end

local function cleanupCamel(camel: Model)
    local state = camelStates[camel]

    if not state then
        return
    end

    for _, connection in ipairs(state.PromptConnections) do
        connection:Disconnect()
    end

    camelStates[camel] = nil
end

local function getCamelControls(seat: VehicleSeat): (number?, number?)
    local occupant = seat.Occupant

    if not occupant or occupant.Health <= 0 then
        return nil, nil
    end

    local player = Players:GetPlayerFromCharacter(occupant.Parent)

    if not player or player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true then
        occupant.Sit = false
        return nil, nil
    end

    local throttle = seat.ThrottleFloat
    local steer = seat.SteerFloat

    return throttle, steer
end

RunService.Heartbeat:Connect(function(deltaTime)
    for camel, state in pairs(camelStates) do
        local seat = state.Seat
        local root = getRoot(camel)

        if not camel.Parent or not seat or not root then
            cleanupCamel(camel)
            continue
        end

        local throttle, steer = getCamelControls(seat)
        local inputAlpha = math.min(1, deltaTime * 4.8)
        state.CurrentThrottle += ((throttle or 0) - state.CurrentThrottle) * inputAlpha
        state.CurrentSteer += ((steer or 0) - state.CurrentSteer) * inputAlpha

        if math.abs(state.CurrentThrottle) > 0.015 or math.abs(state.CurrentSteer) > 0.015 then
            local speed = camel:GetAttribute("CamelSpeed")

            if type(speed) ~= "number" then
                speed = 46
            end

            local currentCFrame = camel:GetPivot()
            local turnRate = camel:GetAttribute("CamelTurnRate")

            if type(turnRate) ~= "number" then
                turnRate = 2.2
            end

            local steeredCFrame = currentCFrame * CFrame.Angles(0, -state.CurrentSteer * turnRate * deltaTime, 0)
            local forward = -steeredCFrame.RightVector
            local flatForward = Vector3.new(forward.X, 0, forward.Z)

            if flatForward.Magnitude > 0.01 then
                local nextPosition = steeredCFrame.Position + flatForward.Unit * state.CurrentThrottle * speed * deltaTime
                camel:PivotTo(CFrame.new(nextPosition) * (steeredCFrame - steeredCFrame.Position))
            else
                camel:PivotTo(steeredCFrame)
            end
        end
    end
end)

for _, camel in ipairs(CollectionService:GetTagged(CAMEL_TAG)) do
    if camel:IsA("Model") then
        setupCamel(camel)
    end
end

CollectionService:GetInstanceAddedSignal(CAMEL_TAG):Connect(function(instance)
    if instance:IsA("Model") then
        setupCamel(instance)
    end
end)

CollectionService:GetInstanceRemovedSignal(CAMEL_TAG):Connect(function(instance)
    if instance:IsA("Model") then
        cleanupCamel(instance)
    end
end)
