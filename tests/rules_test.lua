-- Rules tests. Loaded by tests/run.lua (run that, not this file).

local test, check = T.test, T.check

print("\nrules")

test("victims allowed at once: 1, then 2 at 500, then 3 at 2000", function()
    check(Rules.maxVictims(0) == 1, "start")
    check(Rules.maxVictims(499) == 1, "499")
    check(Rules.maxVictims(500) == 2, "500")
    check(Rules.maxVictims(1999) == 2, "1999")
    check(Rules.maxVictims(2000) == 3, "2000")
    check(Rules.maxVictims(1e6) == 3, "never more than 3")
end)

test("spawn interval shrinks with score but never below the minimum", function()
    check(Rules.spawnInterval(0) == Config.SPAWN_INTERVAL, "start")
    check(Rules.spawnInterval(1000) < Rules.spawnInterval(0), "shrinks")
    check(Rules.spawnInterval(1e6) == Config.SPAWN_INTERVAL_MIN, "floor")
end)

test("game speed ramps up and is capped", function()
    check(Rules.timeScale(0) == 1, "start at normal speed")
    check(Rules.timeScale(499) == 1, "no change before the first step")
    check(Rules.timeScale(500) > 1, "speeds up")
    check(Rules.timeScale(1e6) == Config.TIME_SCALE_MAX, "cap")
end)

test("express bonus for rescues in 2 bounces or fewer", function()
    local normal, e1 = Rules.rescueScore(3)
    local express, e2 = Rules.rescueScore(2)
    check(normal == Config.SCORE_PER_RESCUE and not e1, "3 bounces is normal")
    check(express == Config.SCORE_PER_RESCUE + Config.EXPRESS_BONUS and e2, "2 bounces is express")
end)

test("landings on the same spot are always compatible", function()
    check(Rules.landingsCompatible({ t = 1, x = 150 }, { t = 1, x = 160 }), "10 px apart, same instant")
end)

test("far-apart landings need enough time to crank across", function()
    local a = { t = 1.0, x = 100 }
    local farSoon = { t = 1.2, x = 300 }  -- 176 px of travel in 0.2 s: no
    local farLater = { t = 2.0, x = 300 } -- same distance in 1 s: yes
    check(not Rules.landingsCompatible(a, farSoon), "too soon")
    check(Rules.landingsCompatible(a, farLater), "enough time")
end)

test("faster game speed leaves less real time, so a borderline gap becomes unfair", function()
    local a, b = { t = 1.0, x = 100 }, { t = 1.0 + (176 / Config.FAIR_NET_SPEED + Config.FAIR_REACTION) * 1.05, x = 300 }
    check(Rules.landingsCompatible(a, b, 1.0), "fair at normal speed")
    check(not Rules.landingsCompatible(a, b, 1.4), "unfair at 1.4x")
end)

test("a launch clashing with a jumper already in the air is refused", function()
    local p = Config.spawnPoints()[3]
    local candidate = { x = p.x, y = p.y, vx = 65, vy = Config.JUMP_VY }
    local t = Physics.timeToLand(candidate)
    -- another jumper landing at the far end of the net at the same moment
    local other = { x = Config.NET_MAX_X, y = Physics.catchLine() - 0.5 * Config.GRAVITY * t * t, vx = 0, vy = 0 }
    check(not Rules.fairToLaunch(candidate, { other }), "should refuse")
    check(Rules.fairToLaunch(candidate, {}), "fine when alone")
end)

test("chooseLaunch returns nil rather than an unfair jump, and a fair one when it can", function()
    local saved = Rules.fairToLaunch
    Rules.fairToLaunch = function() return false end
    check(Rules.chooseLaunch(Config.spawnPoints(), {}, 1) == nil, "nothing fair: wait")
    Rules.fairToLaunch = saved
    local b = Rules.chooseLaunch(Config.spawnPoints(), {}, 1)
    check(b and b.vx >= Config.JUMP_VX_MIN and b.vx <= Config.JUMP_VX_MAX and b.vy == Config.JUMP_VY, "valid body")
end)


test("net starts wide, narrows each step, never below the minimum, always even", function()
    check(Rules.netWidth(0) == Config.NET_WIDTH_START, "start")
    check(Rules.netWidth(499) == Config.NET_WIDTH_START, "no change before the first step")
    check(Rules.netWidth(500) == Config.NET_WIDTH_START - Config.NET_WIDTH_STEP, "first step")
    check(Rules.netWidth(1e6) == Config.NET_WIDTH_MIN, "floor")
    for s = 0, 6000, 250 do check(Rules.netWidth(s) % 2 == 0, "even at " .. s) end
end)

test("a wider net makes more landings catchable together", function()
    local a, b = { t = 1, x = 100 }, { t = 1, x = 130 }
    check(Rules.landingsCompatible(a, b, 1, Config.NET_WIDTH_START / 2), "30 px apart: one wide net covers both")
    check(not Rules.landingsCompatible(a, b, 1, Config.NET_WIDTH_MIN / 2), "but not the narrowest")
end)


test("an extra life at every EXTRA_LIFE_EVERY points", function()
    local e = Config.EXTRA_LIFE_EVERY
    check(Rules.extraLivesEarned(e - 100, e - 50) == 0, "below the line")
    check(Rules.extraLivesEarned(e - 50, e + 50) == 1, "crossing the first threshold")
    check(Rules.extraLivesEarned(e + 50, e + 150) == 0, "already past it")
    check(Rules.extraLivesEarned(2 * e - 50, 2 * e + 100) == 1, "crossing the second")
    check(Rules.extraLivesEarned(0, 100) == 0, "not at the start")
end)

test("extra lives come every 5,000 points", function()
    check(Config.EXTRA_LIFE_EVERY == 5000, "tuned value")
end)


test("rescues are worth 10 more per speed-up, 100 up to 160 at full speed", function()
    check(Rules.rescueScore(3, 0) == 100, "start")
    check(Rules.rescueScore(3, 499) == 100, "before the first speed-up")
    check(Rules.rescueScore(3, 500) == 110, "first speed-up")
    check(Rules.rescueScore(3, 3000) == 160, "full speed")
    check(Rules.rescueScore(3, 50000) == 160, "stops rising with the speed")
    check(Rules.rescueScore(2, 3000) == 210, "Express adds a flat 50 on top")
end)

test("rescue value tracks the speed-up exactly", function()
    for s = 0, 6000, 250 do
        local expected = Config.SCORE_PER_RESCUE
            + math.floor((Rules.timeScale(s) - 1) / Config.TIME_SCALE_STEP + 0.5) * Config.SCORE_PER_SPEEDUP
        check(Rules.rescueScore(3, s) == expected, "at " .. s)
    end
end)
