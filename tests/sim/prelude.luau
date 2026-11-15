-- Test helpers for the simulation specs.
local passed, failed = 0, 0
currentSpec = ""

function test(name, fn)
    local ok, err = xpcall(fn, debug.traceback)
    if ok then
        passed += 1
        print("ok   " .. currentSpec .. " > " .. name)
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

function expectTrue(value, message)
    if not value then
        error(message or "expected true", 2)
    end
end

function finish()
    print(string.format("%d passed, %d failed", passed, failed))
    if failed > 0 then
        error("simulation tests failed")
    end
end
