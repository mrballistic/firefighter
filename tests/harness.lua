-- Minimal test harness shared by the *_test.lua files. Pure Lua.
T = { passed = 0, failed = 0 }

function T.test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        T.passed = T.passed + 1
        print("  ok   " .. name)
    else
        T.failed = T.failed + 1
        print("  FAIL " .. name .. "\n       " .. tostring(err))
    end
end

function T.check(cond, msg) if not cond then error(msg, 2) end end

function T.finish()
    print(string.format("\n%d passed, %d failed", T.passed, T.failed))
    os.exit(T.failed == 0 and 0 or 1)
end
