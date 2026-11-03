-- Physics tests. Loaded by tests/run.lua (run that, not this file).

local test, check = T.test, T.check

local DT = 1 / 30
local HALF = Config.NET_HALF_WIDTH

local function clampNet(x)
    return math.max(Config.NET_MIN_X, math.min(Config.NET_MAX_X, x))
end

-- Simulate one victim from a spawn point with a perfect player who always
-- puts the net so the victim lands at hit position `aim`.
-- Returns outcome ("rescued" | "lost" | "timeout"), bounce count, trace.
local function simulate(spawn, jumpVx, aim)
    local b = { x = spawn.x, y = spawn.y, vx = jumpVx, vy = Config.JUMP_VY }
    local bounces = 0
    for _ = 1, 30 * 60 do
        local prevY = b.y
        Physics.step(b, DT)
        Physics.collideWalls(b)
        -- Perfect tracking: net chases the victim's x, offset by the aim.
        local netX = clampNet(b.x - aim * HALF)
        if Physics.isCatch(prevY, b, netX) then
            Physics.bounce(b, netX)
            bounces = bounces + 1
        end
        if Physics.isRescued(b) then return "rescued", bounces end
        if Physics.isLost(b) then return "lost", bounces end
    end
    return "timeout", bounces
end

local function eachSpawn(fn)
    for i, p in ipairs(Config.spawnPoints()) do
        for _, vx in ipairs({ Config.JUMP_VX_MIN, Config.JUMP_VX_MAX }) do
            fn(p, vx, string.format("window %d, vx %d", i, vx))
        end
    end
end

print("physics")

test("hitPosition is -1 at left edge, 0 centre, +1 right edge, clamped", function()
    check(Physics.hitPosition(100 - HALF, 100) == -1, "left")
    check(Physics.hitPosition(100, 100) == 0, "centre")
    check(Physics.hitPosition(100 + HALF, 100) == 1, "right")
    check(Physics.hitPosition(100 + 3 * HALF, 100) == 1, "clamp high")
    check(Physics.hitPosition(100 - 3 * HALF, 100) == -1, "clamp low")
end)

test("every bounce leaves the net at the same speed", function()
    for _, h in ipairs({ -1, -0.5, 0, 0.5, 1 }) do
        local vx, vy = Physics.bounceVelocity(h)
        local speed = math.sqrt(vx * vx + vy * vy)
        check(math.abs(speed - Config.BOUNCE_SPEED) < 1e-6, "speed at h=" .. h)
        check(vy < 0, "goes up at h=" .. h)
    end
end)

test("centre hit leans slightly forward; right edge far forward; left edge backward", function()
    local cvx = Physics.bounceVelocity(0)
    local rvx = Physics.bounceVelocity(1)
    local lvx = Physics.bounceVelocity(-1)
    check(cvx > 0, "centre goes forward")
    check(rvx > 3 * cvx, "right edge much further forward")
    check(lvx < 0, "left edge goes back toward the building")
end)

test("hitting further right always sends the victim further right", function()
    local prev = -math.huge
    for k = -10, 10 do
        local vx = Physics.bounceVelocity(k / 10)
        check(vx > prev, "monotonic at h=" .. k / 10)
        prev = vx
    end
end)

test("highest possible bounce stays on screen, below the score line", function()
    local maxRise = Config.BOUNCE_SPEED ^ 2 / (2 * Config.GRAVITY)
    local apexTop = Physics.catchLine() - maxRise - Config.VICTIM_RADIUS
    check(apexTop > 20, "apex top at y=" .. apexTop)
end)

test("catch fires only while falling, only over the net", function()
    local line = Physics.catchLine()
    check(Physics.isCatch(line - 2, { x = 100, y = line + 2, vy = 50 }, 100), "falling, centred")
    check(not Physics.isCatch(line + 2, { x = 100, y = line - 2, vy = -50 }, 100), "rising")
    check(not Physics.isCatch(line - 2, { x = 100 + HALF + 1, y = line + 2, vy = 50 }, 100), "off the edge")
    check(not Physics.isCatch(line + 1, { x = 100, y = line + 5, vy = 50 }, 100), "already below")
end)

test("a large step can't tunnel through the net", function()
    local line = Physics.catchLine()
    check(Physics.isCatch(line - 60, { x = 100, y = line + 60, vy = 900 }, 100), "big step")
end)

test("after a bounce the victim is not re-caught on the next frames", function()
    local b = { x = 150, y = Physics.catchLine(), vx = 0, vy = 0 }
    Physics.bounce(b, 150)
    for _ = 1, 5 do
        local prevY = b.y
        Physics.step(b, DT)
        check(not Physics.isCatch(prevY, b, 150), "re-caught")
    end
end)

test("building face reflects; right edge stops the victim over the ambulance", function()
    local b = { x = Config.BUILDING_RIGHT, y = 150, vx = -100, vy = 0 }
    Physics.collideWalls(b)
    check(b.vx == 100, "building face")
    b = { x = Config.SCREEN_WIDTH, y = 150, vx = 100, vy = 0 }
    Physics.collideWalls(b)
    check(b.vx == 0, "right edge stops")
    check(b.x >= Config.AMBULANCE_LEFT, "and is over the ambulance")
end)

test("an overshoot from the far end of the net still ends in the ambulance", function()
    local b = { x = Config.NET_MAX_X, y = Physics.catchLine(), vx = 0, vy = 0 }
    b.vx, b.vy = Physics.bounceVelocity(1)
    for _ = 1, 30 * 5 do
        Physics.step(b, DT)
        Physics.collideWalls(b)
        if Physics.isRescued(b) then return end
        check(not Physics.isLost(b), "lost")
    end
    error("never rescued")
end)

test("every window's first fall lands within reach of the net", function()
    eachSpawn(function(p, vx, label)
        local b = { x = p.x, y = p.y, vx = vx, vy = Config.JUMP_VY }
        local line = Physics.catchLine()
        check(p.y < line - 20, label .. ": window too low to catch (y=" .. p.y .. ")")
        while b.y < line do Physics.step(b, DT) end
        check(b.x >= Config.NET_MIN_X - HALF and b.x <= Config.NET_MAX_X + HALF,
            label .. ": lands at x=" .. b.x)
    end)
end)

test("aiming for the right edge rescues in at most 3 bounces", function()
    eachSpawn(function(p, vx, label)
        local outcome, n = simulate(p, vx, 0.9)
        check(outcome == "rescued", label .. ": " .. outcome)
        check(n <= 3, label .. ": took " .. n .. " bounces")
    end)
end)

test("centre catches are safe and still get there, just slowly", function()
    eachSpawn(function(p, vx, label)
        local outcome, n = simulate(p, vx, 0)
        check(outcome == "rescued", label .. ": " .. outcome)
        check(n >= 4, label .. ": too fast for a safe play (" .. n .. ")")
    end)
end)

test("aiming further right never takes more bounces", function()
    eachSpawn(function(p, vx, label)
        local prev = math.huge
        for _, aim in ipairs({ 0, 0.25, 0.5, 0.75, 1 }) do
            local outcome, n = simulate(p, vx, aim)
            check(outcome == "rescued", label .. " aim " .. aim .. ": " .. outcome)
            check(n <= prev, label .. " aim " .. aim .. ": " .. n .. " > " .. prev)
            prev = n
        end
    end)
end)


test("an express rescue is achievable by aiming at the edge", function()
    local best = math.huge
    eachSpawn(function(p, vx)
        local outcome, n = simulate(p, vx, 1)
        if outcome == "rescued" then best = math.min(best, n) end
    end)
    check(best <= Config.EXPRESS_MAX_BOUNCES, "best was " .. best .. " bounces")
end)

test("centre catches can never earn the express bonus", function()
    eachSpawn(function(p, vx, label)
        local _, n = simulate(p, vx, 0)
        check(n > Config.EXPRESS_MAX_BOUNCES, label .. ": " .. n)
    end)
end)

test("landingX predicts where a jumper crosses the catch line", function()
    for _, p in ipairs(Config.spawnPoints()) do
        local b = { x = p.x, y = p.y, vx = 65, vy = Config.JUMP_VY }
        local predicted = Physics.landingX(b)
        local line = Physics.catchLine()
        while b.y < line do Physics.step(b, 1 / 240) end
        check(math.abs(predicted - b.x) < 1.5, string.format("predicted %.1f, actual %.1f", predicted, b.x))
    end
end)
