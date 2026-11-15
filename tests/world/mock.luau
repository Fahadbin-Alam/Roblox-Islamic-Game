-- A small stand-in for the parts of the Roblox engine the world builders use, so the
-- battle arenas can be generated outside Studio and checked for walkable ground.
-- Only geometry is modelled faithfully (Vector3, CFrame, part size/shape/collision and
-- terrain fills). Everything else accepts any property and ignores it.

local mathSqrt = math.sqrt

-- Vector3 ----------------------------------------------------------------------------
local Vector3Meta = {}
Vector3Meta.__index = function(self, key)
    if key == "Magnitude" then
        return mathSqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
    elseif key == "Unit" then
        local m = mathSqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
        if m == 0 then
            return Vector3.new(0, 0, 0)
        end
        return Vector3.new(self.X / m, self.Y / m, self.Z / m)
    end
    return Vector3Meta[key]
end

local function v3(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __kind = "Vector3" }, Vector3Meta)
end

Vector3Meta.__add = function(a, b)
    return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
Vector3Meta.__sub = function(a, b)
    return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
Vector3Meta.__unm = function(a)
    return v3(-a.X, -a.Y, -a.Z)
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
Vector3Meta.__eq = function(a, b)
    return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
Vector3Meta.__tostring = function(a)
    return string.format("(%.2f, %.2f, %.2f)", a.X, a.Y, a.Z)
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

Vector3 = {
    new = v3,
    zero = v3(0, 0, 0),
    one = v3(1, 1, 1),
    xAxis = v3(1, 0, 0),
    yAxis = v3(0, 1, 0),
    zAxis = v3(0, 0, 1),
}

-- CFrame: position p and rotation columns r (right), u (up), b (back = -look) ----------
local CFrameMeta = {}

local function cf(p, r, u, b)
    return setmetatable({ p = p, r = r, u = u, b = b, __kind = "CFrame" }, CFrameMeta)
end

CFrameMeta.__index = function(self, key)
    if key == "Position" or key == "p" then
        return rawget(self, "p")
    elseif key == "LookVector" then
        return -self.b
    elseif key == "RightVector" then
        return self.r
    elseif key == "UpVector" then
        return self.u
    elseif key == "X" then
        return self.p.X
    elseif key == "Y" then
        return self.p.Y
    elseif key == "Z" then
        return self.p.Z
    elseif key == "Rotation" then
        return cf(Vector3.zero, self.r, self.u, self.b)
    end
    return CFrameMeta[key]
end

local function rotate(c, v)
    return c.r * v.X + c.u * v.Y + c.b * v.Z
end

CFrameMeta.__mul = function(a, b)
    if b.__kind == "Vector3" then
        return a.p + rotate(a, b)
    end
    return cf(a.p + rotate(a, b.p), rotate(a, b.r), rotate(a, b.u), rotate(a, b.b))
end
CFrameMeta.__add = function(a, v)
    return cf(a.p + v, a.r, a.u, a.b)
end
CFrameMeta.__sub = function(a, v)
    return cf(a.p - v, a.r, a.u, a.b)
end

function CFrameMeta.Inverse(c)
    -- Rotation is orthonormal, so its inverse is its transpose.
    local r = v3(c.r.X, c.u.X, c.b.X)
    local u = v3(c.r.Y, c.u.Y, c.b.Y)
    local b = v3(c.r.Z, c.u.Z, c.b.Z)
    local inv = cf(Vector3.zero, r, u, b)
    return cf(-(rotate(inv, c.p)), r, u, b)
end
function CFrameMeta.PointToObjectSpace(c, v)
    return c:Inverse() * v
end
function CFrameMeta.PointToWorldSpace(c, v)
    return c * v
end
function CFrameMeta.VectorToObjectSpace(c, v)
    return rotate(c:Inverse(), v)
end
function CFrameMeta.VectorToWorldSpace(c, v)
    return rotate(c, v)
end
function CFrameMeta.ToWorldSpace(a, b)
    return a * b
end
function CFrameMeta.ToObjectSpace(a, b)
    return a:Inverse() * b
end
function CFrameMeta.Lerp(a, b, t)
    -- Good enough for geometry checks: lerp position, keep the nearer rotation.
    local base = t < 0.5 and a or b
    return cf(a.p:Lerp(b.p, t), base.r, base.u, base.b)
end
function CFrameMeta.GetComponents(c)
    return c.p.X, c.p.Y, c.p.Z, c.r.X, c.u.X, c.b.X, c.r.Y, c.u.Y, c.b.Y, c.r.Z, c.u.Z, c.b.Z
end

local IDENTITY = cf(Vector3.zero, v3(1, 0, 0), v3(0, 1, 0), v3(0, 0, 1))

local function lookAt(at, target)
    local look = (target - at)
    if look.Magnitude < 1e-6 then
        return cf(at, IDENTITY.r, IDENTITY.u, IDENTITY.b)
    end
    look = look.Unit
    local worldUp = v3(0, 1, 0)
    if math.abs(look:Dot(worldUp)) > 0.9999 then
        worldUp = v3(0, 0, 1)
    end
    local right = look:Cross(worldUp).Unit
    local up = right:Cross(look).Unit
    return cf(at, right, up, -look)
end

local function rotX(a)
    local c, s = math.cos(a), math.sin(a)
    return cf(Vector3.zero, v3(1, 0, 0), v3(0, c, s), v3(0, -s, c))
end
local function rotY(a)
    local c, s = math.cos(a), math.sin(a)
    return cf(Vector3.zero, v3(c, 0, -s), v3(0, 1, 0), v3(s, 0, c))
end
local function rotZ(a)
    local c, s = math.cos(a), math.sin(a)
    return cf(Vector3.zero, v3(c, s, 0), v3(-s, c, 0), v3(0, 0, 1))
end

CFrame = {
    identity = IDENTITY,
    new = function(a, b, c, ...)
        if a == nil then
            return IDENTITY
        end
        if type(a) == "number" then
            if select("#", ...) >= 9 then
                local r00, r01, r02, r10, r11, r12, r20, r21, r22 = ...
                return cf(v3(a, b, c), v3(r00, r10, r20), v3(r01, r11, r21), v3(r02, r12, r22))
            end
            return cf(v3(a, b, c), IDENTITY.r, IDENTITY.u, IDENTITY.b)
        end
        if b ~= nil then
            return lookAt(a, b)
        end
        return cf(a, IDENTITY.r, IDENTITY.u, IDENTITY.b)
    end,
    lookAt = function(at, target)
        return lookAt(at, target)
    end,
    Angles = function(x, y, z)
        return rotX(x or 0) * rotY(y or 0) * rotZ(z or 0)
    end,
    fromEulerAnglesXYZ = function(x, y, z)
        return rotX(x or 0) * rotY(y or 0) * rotZ(z or 0)
    end,
    fromEulerAnglesYXZ = function(x, y, z)
        return rotY(y or 0) * rotX(x or 0) * rotZ(z or 0)
    end,
    fromOrientation = function(x, y, z)
        return rotY(y or 0) * rotX(x or 0) * rotZ(z or 0)
    end,
}

-- Plain value types ------------------------------------------------------------------
local function valueType(fields)
    return function(...)
        local args = { ... }
        local t = {}
        for i, name in ipairs(fields) do
            t[name] = args[i]
        end
        return t
    end
end

Color3 = {
    fromRGB = function(r, g, b)
        return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }
    end,
    new = function(r, g, b)
        return { R = r or 0, G = g or 0, B = b or 0 }
    end,
    fromHSV = function(h, s, v)
        return { R = v, G = v, B = v }
    end,
}
Vector2 = { new = valueType({ "X", "Y" }), zero = { X = 0, Y = 0 } }
UDim = { new = valueType({ "Scale", "Offset" }) }
UDim2 = {
    new = valueType({ "XS", "XO", "YS", "YO" }),
    fromOffset = valueType({ "XO", "YO" }),
    fromScale = valueType({ "XS", "YS" }),
}
NumberRange = { new = valueType({ "Min", "Max" }) }
NumberSequence = { new = valueType({ "Value" }) }
NumberSequenceKeypoint = { new = valueType({ "Time", "Value" }) }
ColorSequence = { new = valueType({ "Value" }) }
ColorSequenceKeypoint = { new = valueType({ "Time", "Value" }) }
TweenInfo = { new = valueType({ "Time" }) }
PhysicalProperties = { new = valueType({ "Density" }) }
BrickColor = { new = valueType({ "Name" }) }

Enum = setmetatable({}, {
    __index = function(_, enumName)
        return setmetatable({}, {
            __index = function(_, item)
                return { EnumType = enumName, Name = item }
            end,
        })
    end,
})

-- Instances ----------------------------------------------------------------------------
local PART_CLASSES = { Part = true, WedgePart = true, CornerWedgePart = true, TrussPart = true, SpawnLocation = true, MeshPart = true, Seat = true }
local CLASS_PARENTS = {
    Part = "BasePart",
    WedgePart = "BasePart",
    CornerWedgePart = "BasePart",
    TrussPart = "BasePart",
    SpawnLocation = "BasePart",
    MeshPart = "BasePart",
    Seat = "BasePart",
    Folder = "Instance",
    Model = "PVInstance",
    Terrain = "BasePart",
}

local InstanceMeta = {}
local methods = {}

local allParts = {}
terrainSolids = {}

local function newInstance(className)
    local self = setmetatable({
        __props = { Name = className, ClassName = className, Parent = nil },
        __children = {},
        __attributes = {},
    }, InstanceMeta)

    if PART_CLASSES[className] then
        local props = self.__props
        props.Size = v3(4, 1, 2)
        props.CFrame = IDENTITY
        props.CanCollide = true
        props.Transparency = 0
        props.Anchored = false
        props.Shape = Enum.PartType.Block
        table.insert(allParts, self)
    end

    return self
end

InstanceMeta.__index = function(self, key)
    local props = rawget(self, "__props")
    local value = props[key]

    if value ~= nil then
        return value
    end

    if key == "Position" and props.CFrame then
        return props.CFrame.Position
    end

    if methods[key] then
        return methods[key]
    end

    for _, child in ipairs(rawget(self, "__children")) do
        if child.__props.Name == key then
            return child
        end
    end

    return nil
end

InstanceMeta.__newindex = function(self, key, value)
    local props = rawget(self, "__props")

    if key == "Parent" then
        local old = props.Parent
        if old then
            local siblings = old.__children
            for i = #siblings, 1, -1 do
                if siblings[i] == self then
                    table.remove(siblings, i)
                end
            end
        end
        props.Parent = value
        if value then
            table.insert(value.__children, self)
        end
        return
    end

    if key == "Position" and props.CFrame then
        local c = props.CFrame
        props.CFrame = cf(value, c.r, c.u, c.b)
        return
    end

    if key == "Orientation" and props.CFrame then
        local p = props.CFrame.Position
        props.CFrame = CFrame.new(p) * CFrame.fromOrientation(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
        return
    end

    props[key] = value
end

function methods:IsA(className)
    local current = self.__props.ClassName
    while current do
        if current == className or className == "Instance" then
            return true
        end
        current = CLASS_PARENTS[current]
    end
    return false
end
function methods:FindFirstChild(name)
    for _, child in ipairs(self.__children) do
        if child.__props.Name == name then
            return child
        end
    end
    return nil
end
function methods:WaitForChild(name)
    local child = self:FindFirstChild(name)
    assert(child, "WaitForChild would hang: " .. tostring(name))
    return child
end
function methods:FindFirstChildOfClass(className)
    for _, child in ipairs(self.__children) do
        if child.__props.ClassName == className then
            return child
        end
    end
    return nil
end
function methods:FindFirstChildWhichIsA(className)
    for _, child in ipairs(self.__children) do
        if child:IsA(className) then
            return child
        end
    end
    return nil
end
function methods:GetChildren()
    return table.clone(self.__children)
end
function methods:GetDescendants()
    local out = {}
    local function walk(node)
        for _, child in ipairs(node.__children) do
            table.insert(out, child)
            walk(child)
        end
    end
    walk(self)
    return out
end
function methods:SetAttribute(name, value)
    self.__attributes[name] = value
end
function methods:GetAttribute(name)
    return self.__attributes[name]
end
function methods:Destroy()
    self.Parent = nil
    self.__props.Destroyed = true
end
function methods:ClearAllChildren()
    for _, child in ipairs(self:GetChildren()) do
        child:Destroy()
    end
end
function methods:GetFullName()
    local names = {}
    local node = self
    while node do
        table.insert(names, 1, node.__props.Name)
        node = node.__props.Parent
    end
    return table.concat(names, ".")
end
function methods:PivotTo(c)
    self.__props.CFrame = c
end
function methods:GetPivot()
    return self.__props.CFrame or IDENTITY
end
function methods:FillBlock(c, size)
    table.insert(terrainSolids, { Kind = "Block", CFrame = c, Size = size })
end
function methods:FillBall(position, radius)
    table.insert(terrainSolids, { Kind = "Ball", CFrame = CFrame.new(position), Size = v3(radius * 2, radius * 2, radius * 2) })
end
function methods:FillCylinder(c, height, radius)
    table.insert(terrainSolids, { Kind = "Block", CFrame = c, Size = v3(radius * 2, height, radius * 2) })
end
function methods:FillWedge(c, size)
    table.insert(terrainSolids, { Kind = "Wedge", CFrame = c, Size = size })
end
function methods:Clear() end
function methods:GetAttributeChangedSignal()
    return { Connect = function() return { Disconnect = function() end } end }
end

local signal = { Connect = function() return { Disconnect = function() end } end, Wait = function() end }
methods.ChildAdded = signal
methods.DescendantAdded = signal
methods.Triggered = signal
methods.Touched = signal

Instance = { new = function(className, parent)
    local inst = newInstance(className)
    if parent then
        inst.Parent = parent
    end
    return inst
end }

-- Services ---------------------------------------------------------------------------
game = newInstance("DataModel")
local services = {}
local function service(name, className)
    local s = newInstance(className or name)
    s.Name = name
    s.Parent = game
    services[name] = s
    return s
end
local workspaceService = service("Workspace")
local terrain = newInstance("Terrain")
terrain.Name = "Terrain"
terrain.Parent = workspaceService
table.remove(allParts) -- terrain is tracked through terrainSolids, not as a part
workspace = workspaceService
service("ReplicatedStorage")
service("ServerScriptService")
service("Lighting")
service("Players")
service("RunService")
service("CollectionService")
service("Debris")
service("TweenService")

function methods:GetService(name)
    return services[name] or service(name)
end

-- Module loading: ModuleScript stand-ins carry a loader function -----------------------
function makeModule(parent, name, loader)
    local module = newInstance("ModuleScript")
    module.Name = name
    module.Parent = parent
    rawset(module, "__loader", loader)
    return module
end

local moduleCache = {}
function require(module)
    if moduleCache[module] == nil then
        local loader = rawget(module, "__loader")
        assert(loader, "No loader for module " .. tostring(module and module.Name))
        moduleCache[module] = loader({ Parent = module.Parent, Name = module.Name })
    end
    return moduleCache[module]
end

task = {
    spawn = function(fn, ...)
        if type(fn) == "function" then
            fn(...)
        end
    end,
    delay = function() end,
    defer = function() end,
    wait = function()
        return 0
    end,
}
typeof = function(value)
    if type(value) == "table" then
        if value.__kind then
            return value.__kind
        end
        if rawget(value, "__props") then
            return "Instance"
        end
    end
    return type(value)
end

function getAllParts()
    local live = {}
    for _, part in ipairs(allParts) do
        if not part.__props.Destroyed then
            table.insert(live, part)
        end
    end
    return live
end
