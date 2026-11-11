-- Engine calls the client scripts (and some server scripts) need beyond tests/sim/engine.luau.
local Instance_ = mock.Instance_

function Instance_.Fire(bindable, ...)
    bindable.Event._fire(...)
end

-- Attribute and property change signals, fired when values change.
local attributeSignals = setmetatable({}, { __mode = "k" })
function Instance_.GetAttributeChangedSignal(self, name)
    attributeSignals[self] = attributeSignals[self] or {}
    attributeSignals[self][name] = attributeSignals[self][name] or mock.signal()
    return attributeSignals[self][name]
end
local baseSetAttribute = Instance_.SetAttribute
function Instance_.SetAttribute(self, key, value)
    local old = self.Attributes[key]
    baseSetAttribute(self, key, value)
    if old ~= value then
        local signals = attributeSignals[self]
        if signals and signals[key] then
            signals[key]._fire()
        end
        if rawget(self, "__attrChanged") then
            rawget(self, "__attrChanged")._fire(key)
        end
    end
end
function Instance_.GetPropertyChangedSignal()
    return mock.signal()
end

-- Platform calls the HUDs make.
function Instance_.SetCore() end
function Instance_.SetCoreGuiEnabled() end
function Instance_.PromptGameInvite() end
function Instance_.CanSendGameInviteAsync()
    return true
end
function Instance_.AdjustSpeed() end
function Instance_.BulkMoveTo() end
function Instance_.LoadAnimation()
    local track = mock.newInstance("AnimationTrack")
    rawset(track, "Play", function() end)
    rawset(track, "Stop", function() end)
    rawset(track, "AdjustSpeed", function() end)
    return track
end
function Instance_.GetMouseLocation()
    return Vector2.new(640, 360)
end
function Instance_.IsKeyDown()
    return false
end

-- Read-only layout and physics values the engine computes.
Instance_.AbsoluteSize = Vector2.new(1280, 720)
Instance_.AbsolutePosition = Vector2.new(0, 0)
Instance_.AbsoluteContentSize = Vector2.new(0, 240)
Instance_.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
Instance_.TextBounds = Vector2.new(120, 20)
for _, name in ipairs({ "PromptGamePassPurchaseFinished", "PromptProductPurchaseFinished", "PromptPurchaseFinished", "PromptBundlePurchaseFinished" }) do
    mock.extraSignals[name] = true
end
game:GetService("Lighting").ClockTime = 14
Instance_.AnchorPoint = Vector2.new(0, 0)
Instance_.CameraOffset = Vector3.new(0, 0, 0)
Vector3.zero = Vector3.zero or Vector3.new(0, 0, 0)
Vector3.one = Vector3.one or Vector3.new(1, 1, 1)
