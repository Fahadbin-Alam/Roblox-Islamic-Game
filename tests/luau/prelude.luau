-- Minimal stand-ins for the Roblox globals used by the shared data modules.
Color3 = { fromRGB = function(r, g, b) return { R = r, G = g, B = b } end }
Vector3 = { new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0 } end }
Enum = setmetatable({}, { __index = function(_, enumName)
    return setmetatable({}, { __index = function(_, item) return enumName .. "." .. item end })
end })

loaders = {}
local cache = {}
local root = {}

local function folder(name)
    return setmetatable({ Name = name, Parent = root }, {
        __index = function(self, child)
            return { Path = name .. "/" .. child, Parent = self }
        end,
    })
end

for _, name in ipairs({ "Config", "Data", "Modules" }) do
    root[name] = folder(name)
end

function require(descriptor)
    local path = descriptor.Path

    if cache[path] == nil then
        local loader = loaders[path]
        assert(loader, "No module at " .. tostring(path))
        cache[path] = loader({ Parent = descriptor.Parent })
    end

    return cache[path]
end

function load(path)
    local name = path:match("^[^/]+")
    local child = path:match("/(.+)$")
    return require(root[name][child])
end

local passed, failed = 0, 0
currentSpec = ""

function test(name, fn)
    local ok, err = pcall(fn)

    if ok then
        passed += 1
    else
        failed += 1
        print(string.format("FAIL %s > %s\n    %s", currentSpec, name, tostring(err)))
    end
end

function expectEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message or "values differ", tostring(expected), tostring(actual)), 2)
    end
end

function finish()
    print(string.format("%d passed, %d failed", passed, failed))

    if failed > 0 then
        error("tests failed")
    end
end
