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
