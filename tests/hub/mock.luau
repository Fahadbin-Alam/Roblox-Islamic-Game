-- A small stand-in for the Roblox engine, enough to run the hub world builders outside Studio.
-- It models Vector3/CFrame math exactly (so part placement can be checked) and a plain
-- instance tree with Name/Parent/attributes. Rendering, physics and lighting are not modelled.

mock = { oversized = {} }

local function fmt(n)
    return string.format("%.3f", n)
end

---------------------------------------------------------------- Vector3
local Vector3Meta = {}
Vector3Meta.__index = Vector3Meta

local function v3(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __type = "Vector3" }, Vector3Meta)
end

local function isV3(value)
    return type(value) == "table" and value.__type == "Vector3"
end

Vector3Meta.__add = function(a, b)
    return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
Vector3Meta.__sub = function(a, b)
    return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
Vector3Meta.__mul = function(a, b)
    if type(a) == "number" then
        return v3(b.X * a, b.Y * a, b.Z * a)
    elseif type(b) == "number" then
        return v3(a.X * b, a.Y * b, a.Z * b)
    end
    return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3Meta.__div = function(a, b)
    if type(b) == "number" then
        return v3(a.X / b, a.Y / b, a.Z / b)
    end
    return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
Vector3Meta.__unm = function(a)
    return v3(-a.X, -a.Y, -a.Z)
end
Vector3Meta.__eq = function(a, b)
    return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
Vector3Meta.__tostring = function(a)
    return fmt(a.X) .. ", " .. fmt(a.Y) .. ", " .. fmt(a.Z)
end
Vector3Meta.__index = function(self, key)
    if key == "Magnitude" then
        return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
    elseif key == "Unit" then
        local m = math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
        if m == 0 then
            return v3(0, 0, 0)
        end
        return v3(self.X / m, self.Y / m, self.Z / m)
    end
    return rawget(Vector3Meta, key)
end
function Vector3Meta.Dot(a, b)
    return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
function Vector3Meta.Cross(a, b)
    return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function Vector3Meta.Lerp(a, b, t)
    return a + (b - a) * t
end
function Vector3Meta.Abs(a)
    return v3(math.abs(a.X), math.abs(a.Y), math.abs(a.Z))
end

Vector3 = {
    new = v3,
    zero = v3(0, 0, 0),
    one = v3(1, 1, 1),
    xAxis = v3(1, 0, 0),
    yAxis = v3(0, 1, 0),
    zAxis = v3(0, 0, 1),
}

Vector2 = {
    new = function(x, y)
        return { X = x or 0, Y = y or 0, __type = "Vector2" }
    end,
}

---------------------------------------------------------------- CFrame
-- Stored as position + 3x3 rotation matrix rows (r00..r22), column vectors are the axes.
local CFrameMeta = {}

local function cf(px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    return setmetatable({
        __type = "CFrame",
        px = px, py = py, pz = pz,
        r00 = r00, r01 = r01, r02 = r02,
        r10 = r10, r11 = r11, r12 = r12,
        r20 = r20, r21 = r21, r22 = r22,
    }, CFrameMeta)
end

local function identityAt(x, y, z)
    return cf(x, y, z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
end

local function rotX(a)
    local c, s = math.cos(a), math.sin(a)
    return cf(0, 0, 0, 1, 0, 0, 0, c, -s, 0, s, c)
end
local function rotY(a)
    local c, s = math.cos(a), math.sin(a)
    return cf(0, 0, 0, c, 0, s, 0, 1, 0, -s, 0, c)
end
local function rotZ(a)
    local c, s = math.cos(a), math.sin(a)
    return cf(0, 0, 0, c, -s, 0, s, c, 0, 0, 0, 1)
end

local function mulCF(a, b)
    return cf(
        a.r00 * b.px + a.r01 * b.py + a.r02 * b.pz + a.px,
        a.r10 * b.px + a.r11 * b.py + a.r12 * b.pz + a.py,
        a.r20 * b.px + a.r21 * b.py + a.r22 * b.pz + a.pz,
        a.r00 * b.r00 + a.r01 * b.r10 + a.r02 * b.r20,
        a.r00 * b.r01 + a.r01 * b.r11 + a.r02 * b.r21,
        a.r00 * b.r02 + a.r01 * b.r12 + a.r02 * b.r22,
        a.r10 * b.r00 + a.r11 * b.r10 + a.r12 * b.r20,
        a.r10 * b.r01 + a.r11 * b.r11 + a.r12 * b.r21,
        a.r10 * b.r02 + a.r11 * b.r12 + a.r12 * b.r22,
        a.r20 * b.r00 + a.r21 * b.r10 + a.r22 * b.r20,
        a.r20 * b.r01 + a.r21 * b.r11 + a.r22 * b.r21,
        a.r20 * b.r02 + a.r21 * b.r12 + a.r22 * b.r22
    )
end

local function pointToWorld(a, v)
    return v3(
        a.r00 * v.X + a.r01 * v.Y + a.r02 * v.Z + a.px,
        a.r10 * v.X + a.r11 * v.Y + a.r12 * v.Z + a.py,
        a.r20 * v.X + a.r21 * v.Y + a.r22 * v.Z + a.pz
    )
end

local function inverse(a)
    -- Rotation is orthonormal, so the inverse is the transpose.
    local r = cf(0, 0, 0, a.r00, a.r10, a.r20, a.r01, a.r11, a.r21, a.r02, a.r12, a.r22)
    local p = pointToWorld(r, v3(-a.px, -a.py, -a.pz))
    r.px, r.py, r.pz = p.X, p.Y, p.Z
    return r
end

CFrameMeta.__mul = function(a, b)
    if isV3(b) then
        return pointToWorld(a, b)
    end
    return mulCF(a, b)
end
CFrameMeta.__add = function(a, b)
    return cf(a.px + b.X, a.py + b.Y, a.pz + b.Z, a.r00, a.r01, a.r02, a.r10, a.r11, a.r12, a.r20, a.r21, a.r22)
end
CFrameMeta.__sub = function(a, b)
    return cf(a.px - b.X, a.py - b.Y, a.pz - b.Z, a.r00, a.r01, a.r02, a.r10, a.r11, a.r12, a.r20, a.r21, a.r22)
end
CFrameMeta.__index = function(self, key)
    if key == "Position" or key == "p" then
        return v3(self.px, self.py, self.pz)
    elseif key == "X" then
        return self.px
    elseif key == "Y" then
        return self.py
    elseif key == "Z" then
        return self.pz
    elseif key == "LookVector" then
        return v3(-self.r02, -self.r12, -self.r22)
    elseif key == "RightVector" then
        return v3(self.r00, self.r10, self.r20)
    elseif key == "UpVector" then
        return v3(self.r01, self.r11, self.r21)
    elseif key == "Rotation" then
        return cf(0, 0, 0, self.r00, self.r01, self.r02, self.r10, self.r11, self.r12, self.r20, self.r21, self.r22)
    elseif key == "Inverse" then
        return inverse
    elseif key == "PointToWorldSpace" then
        return pointToWorld
    elseif key == "PointToObjectSpace" then
        return function(a, v)
            return pointToWorld(inverse(a), v)
        end
    elseif key == "ToWorldSpace" then
        return mulCF
    elseif key == "ToObjectSpace" then
        return function(a, b)
            return mulCF(inverse(a), b)
        end
    elseif key == "Lerp" then
        return function(a, b, t)
            -- Position-only lerp is enough for builder scripts.
            local p = v3(a.px, a.py, a.pz):Lerp(v3(b.px, b.py, b.pz), t)
            return cf(p.X, p.Y, p.Z, a.r00, a.r01, a.r02, a.r10, a.r11, a.r12, a.r20, a.r21, a.r22)
        end
    end
    return nil
end

local function lookAt(at, target, up)
    up = up or v3(0, 1, 0)
    local look = (target - at).Unit
    local right = look:Cross(up).Unit
    if right.Magnitude < 0.5 then
        right = v3(1, 0, 0)
    end
    local realUp = right:Cross(look)
    -- Columns: right, up, back (-look)
    return cf(at.X, at.Y, at.Z, right.X, realUp.X, -look.X, right.Y, realUp.Y, -look.Y, right.Z, realUp.Z, -look.Z)
end

CFrame = {
    new = function(a, b, c, ...)
        if a == nil then
            return identityAt(0, 0, 0)
        elseif isV3(a) and isV3(b) then
            return lookAt(a, b)
        elseif isV3(a) then
            return identityAt(a.X, a.Y, a.Z)
        elseif select("#", ...) >= 9 then
            local r = { ... }
            return cf(a, b, c, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
        end
        return identityAt(a, b, c)
    end,
    Angles = function(x, y, z)
        return mulCF(mulCF(rotX(x), rotY(y)), rotZ(z))
    end,
    fromEulerAnglesXYZ = function(x, y, z)
        return mulCF(mulCF(rotX(x), rotY(y)), rotZ(z))
    end,
    fromEulerAnglesYXZ = function(x, y, z)
        return mulCF(mulCF(rotY(y), rotX(x)), rotZ(z))
    end,
    fromOrientation = function(x, y, z)
        return mulCF(mulCF(rotY(y), rotX(x)), rotZ(z))
    end,
    fromAxisAngle = function(axis, angle)
        local u = axis.Unit
        local c, s, t = math.cos(angle), math.sin(angle), 1 - math.cos(angle)
        return cf(0, 0, 0,
            t * u.X * u.X + c, t * u.X * u.Y - s * u.Z, t * u.X * u.Z + s * u.Y,
            t * u.X * u.Y + s * u.Z, t * u.Y * u.Y + c, t * u.Y * u.Z - s * u.X,
            t * u.X * u.Z - s * u.Y, t * u.Y * u.Z + s * u.X, t * u.Z * u.Z + c)
    end,
    lookAt = lookAt,
    fromMatrix = function(pos, vX, vY, vZ)
        vZ = vZ or vX:Cross(vY)
        return cf(pos.X, pos.Y, pos.Z, vX.X, vY.X, vZ.X, vX.Y, vY.Y, vZ.Y, vX.Z, vY.Z, vZ.Z)
    end,
    identity = identityAt(0, 0, 0),
}

---------------------------------------------------------------- Small datatypes
local Color3Meta = {}
Color3Meta.__index = Color3Meta
local function color(r, g, b)
    return setmetatable({ R = r, G = g, B = b, __type = "Color3" }, Color3Meta)
end
function Color3Meta.Lerp(a, b, t)
    return color(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
Color3 = {
    new = function(r, g, b)
        return color(r or 0, g or 0, b or 0)
    end,
    fromRGB = function(r, g, b)
        return color((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
    end,
    fromHSV = function()
        return color(1, 1, 1)
    end,
}

UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = {
    new = function(xs, xo, ys, yo) return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) } end,
    fromScale = function(x, y) return { X = UDim.new(x, 0), Y = UDim.new(y, 0) } end,
    fromOffset = function(x, y) return { X = UDim.new(0, x), Y = UDim.new(0, y) } end,
}
NumberRange = { new = function(a, b) return { Min = a, Max = b or a } end }
NumberSequence = { new = function(...) return { ... } end }
NumberSequenceKeypoint = { new = function(...) return { ... } end }
ColorSequence = { new = function(...) return { ... } end }
ColorSequenceKeypoint = { new = function(...) return { ... } end }
TweenInfo = { new = function(...) return { ... } end }
PhysicalProperties = { new = function(...) return { ... } end }
Rect = { new = function(...) return { ... } end }
Font = { new = function(...) return { ... } end, fromEnum = function(e) return e end }

Enum = setmetatable({}, {
    __index = function(_, enumName)
        return setmetatable({}, {
            __index = function(_, item)
                return { Name = item, EnumType = enumName, __enum = enumName .. "." .. item }
            end,
        })
    end,
})

---------------------------------------------------------------- Signals
local function signal()
    return {
        Connect = function()
            return { Disconnect = function() end }
        end,
        Once = function()
            return { Disconnect = function() end }
        end,
        Wait = function() end,
    }
end

---------------------------------------------------------------- Instances
local partClasses = {
    Part = true, WedgePart = true, CornerWedgePart = true, TrussPart = true,
    SpawnLocation = true, Seat = true, VehicleSeat = true, MeshPart = true, UnionOperation = true,
}

local isAMap = {
    BasePart = partClasses,
    PVInstance = partClasses,
    Light = { PointLight = true, SpotLight = true, SurfaceLight = true },
    GuiObject = { Frame = true, TextLabel = true, ImageLabel = true, TextButton = true },
    LayerCollector = { SurfaceGui = true, BillboardGui = true, ScreenGui = true },
}

local Instance_ = {}
local allInstances = {}

local function newInstance(className)
    local props = {
        ClassName = className,
        Name = className,
        Children = {},
        Attributes = {},
        Tags = {},
        Destroyed = false,
    }

    if partClasses[className] then
        props.Size = v3(4, 1, 2)
        props.CFrame = identityAt(0, 0, 0)
        props.Color = Color3.fromRGB(163, 162, 165)
        props.Transparency = 0
        props.Anchored = false
        props.CanCollide = true
        props.CanTouch = true
        props.CanQuery = true
        props.CastShadow = true
        props.Shape = Enum.PartType.Block
        props.Material = Enum.Material.Plastic
    end

    local object = {}
    local signals = {}

    setmetatable(object, {
        __index = function(_, key)
            local value = props[key]
            if value ~= nil then
                return value
            end
            if key == "Position" and props.CFrame then
                return props.CFrame.Position
            elseif key == "Orientation" then
                return v3(0, 0, 0)
            elseif key == "Parent" then
                return nil
            end
            local method = Instance_[key]
            if method then
                return method
            end
            if key:match("^[A-Z]") and (key:match("Changed$") or key:match("Added$") or key:match("Removed$") or key:match("Removing$") or key == "Destroying" or key == "Touched" or key == "TouchEnded" or key == "Triggered" or key == "Event" or key == "OnServerEvent" or key == "OnClientEvent" or key == "Heartbeat" or key == "Stepped" or key == "RenderStepped" or key == "PromptTriggered") then
                signals[key] = signals[key] or signal()
                return signals[key]
            end
            -- Child lookup like `folder.Child`.
            for _, child in ipairs(props.Children) do
                if child.Name == key then
                    return child
                end
            end
            return nil
        end,
        __newindex = function(self, key, value)
            if key == "Parent" then
                local old = props.Parent
                if old then
                    local siblings = old.Children
                    for i, child in ipairs(siblings) do
                        if child == self then
                            table.remove(siblings, i)
                            break
                        end
                    end
                end
                props.Parent = value
                if value then
                    table.insert(value.Children, self)
                end
                return
            elseif key == "Position" then
                local c = props.CFrame or identityAt(0, 0, 0)
                props.CFrame = cf(value.X, value.Y, value.Z, c.r00, c.r01, c.r02, c.r10, c.r11, c.r12, c.r20, c.r21, c.r22)
                return
            elseif key == "Size" and partClasses[className] then
                assert(isV3(value), "Size must be a Vector3")
                for _, axis in ipairs({ "X", "Y", "Z" }) do
                    local n = value[axis]
                    assert(n == n, "NaN size on " .. tostring(props.Name))
                    if n > 2048 then
                        -- Roblox silently clamps this, so record it for checks.luau to report.
                        table.insert(mock.oversized, string.format("%s is %s studs on %s", tostring(props.Name), fmt(n), axis))
                    end
                end
            elseif key == "CFrame" then
                assert(type(value) == "table" and value.__type == "CFrame", "CFrame must be a CFrame on " .. tostring(props.Name))
                assert(value.px == value.px and value.py == value.py and value.pz == value.pz, "NaN CFrame on " .. tostring(props.Name))
            end
            props[key] = value
        end,
        __tostring = function()
            return props.Name
        end,
    })

    table.insert(allInstances, object)
    return object
end

local function className(object)
    return object.ClassName
end

function Instance_.IsA(self, name)
    local cls = className(self)
    if cls == name or name == "Instance" then
        return true
    end
    local group = isAMap[name]
    return group ~= nil and group[cls] == true
end
function Instance_.GetChildren(self)
    return table.clone(self.Children)
end
function Instance_.GetDescendants(self)
    local result = {}
    local function walk(node)
        for _, child in ipairs(node.Children) do
            table.insert(result, child)
            walk(child)
        end
    end
    walk(self)
    return result
end
function Instance_.FindFirstChild(self, name, recursive)
    for _, child in ipairs(self.Children) do
        if child.Name == name then
            return child
        end
    end
    if recursive then
        for _, child in ipairs(self.Children) do
            local found = child:FindFirstChild(name, true)
            if found then
                return found
            end
        end
    end
    return nil
end
function Instance_.FindFirstChildOfClass(self, cls)
    for _, child in ipairs(self.Children) do
        if child.ClassName == cls then
            return child
        end
    end
    return nil
end
function Instance_.FindFirstChildWhichIsA(self, cls)
    for _, child in ipairs(self.Children) do
        if child:IsA(cls) then
            return child
        end
    end
    return nil
end
function Instance_.WaitForChild(self, name)
    local child = self:FindFirstChild(name)
    assert(child, "WaitForChild would hang: " .. tostring(self.Name) .. "." .. name)
    return child
end
function Instance_.SetAttribute(self, key, value)
    self.Attributes[key] = value
end
function Instance_.GetAttribute(self, key)
    return self.Attributes[key]
end
function Instance_.GetAttributes(self)
    return self.Attributes
end
function Instance_.Destroy(self)
    self.Parent = nil
    rawset(self, "__destroyed", true)
end
function Instance_.ClearAllChildren(self)
    for _, child in ipairs(self:GetChildren()) do
        child:Destroy()
    end
end
function Instance_.GetFullName(self)
    local names = {}
    local node = self
    while node do
        table.insert(names, 1, node.Name)
        node = node.Parent
    end
    return table.concat(names, ".")
end
function Instance_.PivotTo(self, target)
    if self.CFrame then
        self.CFrame = target
    end
end
function Instance_.GetPivot(self)
    return self.CFrame or identityAt(0, 0, 0)
end
function Instance_.Clone(self)
    local copy = newInstance(self.ClassName)
    for _, key in ipairs({ "Name", "Size", "CFrame", "Color", "Material", "Transparency", "Anchored", "CanCollide", "Shape" }) do
        if self[key] ~= nil then
            copy[key] = self[key]
        end
    end
    return copy
end
-- Terrain-only calls are accepted and ignored.
for _, name in ipairs({ "FillBall", "FillBlock", "FillCylinder", "FillWedge", "Clear", "SetMaterialColor", "ScaleTo", "Play", "Stop", "Fire", "FireAllClients", "FireClient", "BreakJoints", "SetPrimaryPartCFrame" }) do
    Instance_[name] = function() end
end

Instance = {
    new = function(cls, parent)
        local object = newInstance(cls)
        if parent then
            object.Parent = parent
        end
        return object
    end,
}

---------------------------------------------------------------- Services
local services = {}
local game_ = newInstance("DataModel")
game_.Name = "game"

local function service(name)
    if not services[name] then
        local s = newInstance(name)
        s.Name = name
        s.Parent = game_
        services[name] = s
    end
    return services[name]
end

local tags = {}
rawset(Instance_, "GetService", function(_, name)
    return service(name)
end)

local CollectionService = service("CollectionService")
rawset(Instance_, "AddTag", function(self, objectOrTag, maybeTag)
    local object, tag = self, objectOrTag
    if self == CollectionService then
        object, tag = objectOrTag, maybeTag
    end
    tags[tag] = tags[tag] or {}
    table.insert(tags[tag], object)
    object.Tags[tag] = true
end)
rawset(Instance_, "HasTag", function(self, tag)
    return self.Tags[tag] == true
end)
rawset(Instance_, "GetTagged", function(_, tag)
    local result = {}
    for _, object in ipairs(tags[tag] or {}) do
        if not rawget(object, "__destroyed") then
            table.insert(result, object)
        end
    end
    return result
end)
rawset(Instance_, "GetInstanceAddedSignal", function()
    return signal()
end)
rawset(Instance_, "GetInstanceRemovedSignal", function()
    return signal()
end)

local Workspace = service("Workspace")
local terrain = newInstance("Terrain")
terrain.Name = "Terrain"
terrain.Parent = Workspace
rawset(Instance_, "Raycast", function()
    return nil
end)
rawset(Instance_, "IsServer", function()
    return true
end)
rawset(Instance_, "IsClient", function()
    return false
end)
rawset(Instance_, "IsStudio", function()
    return false
end)
rawset(Instance_, "GetPlayers", function()
    return {}
end)

game = game_
workspace = Workspace

-- Spawned loops run until their first wait, then stay parked: enough to check one pass.
local function runUntilWait(fn, ...)
    local co = coroutine.create(fn)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        error(err, 0)
    end
end

task = {
    spawn = runUntilWait,
    defer = function() end,
    delay = function() end,
    wait = function()
        if coroutine.isyieldable() then
            coroutine.yield()
        end
        return 0
    end,
}

typeof = function(value)
    if type(value) == "table" and value.__type then
        return value.__type
    end
    return type(value)
end
wait = task.wait
tick = os.clock
warn = function(...)
    print("warn:", ...)
end

---------------------------------------------------------------- Module loading
-- `loaders[path]` holds module bodies keyed like "ReplicatedStorage/Shared/Data/TravelRoute".
loaders = {}
local moduleCache = {}

-- Module scripts are mocked as instances so `script.Parent.Modules.X` and
-- `Shared.Data.X` style lookups resolve to the right loader.
local function ensurePath(path)
    local node = game_
    for segment in string.gmatch(path, "[^/]+") do
        local child = node:FindFirstChild(segment)
        if not child then
            if node == game_ then
                child = service(segment)
            else
                child = newInstance("Folder")
                child.Name = segment
                child.Parent = node
            end
        end
        node = child
    end
    return node
end

function registerModule(path, body)
    local node = ensurePath(path)
    rawset(node, "__modulePath", path)
    loaders[path] = body
end

function require(descriptor)
    local path = rawget(descriptor, "__modulePath")
    assert(path, "No module registered for " .. tostring(descriptor.Name))
    if moduleCache[path] == nil then
        moduleCache[path] = loaders[path](descriptor)
    end
    return moduleCache[path]
end

function scriptAt(path)
    local node = ensurePath(path)
    return node
end

mock.allInstances = allInstances
mock.isV3 = isV3
mock.pointToWorld = pointToWorld
mock.service = service
mock.tags = tags
