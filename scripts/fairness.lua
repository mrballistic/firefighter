-- Fairness probe for the multi-jumper stages. Run from the repo root:
--   lua scripts/fairness.lua [netSpeed] [score]       # defaults: 300 px/s, scores 1000 and 2500
--   lua scripts/fairness.lua 450 2500
--
-- Simulates the game's real spawn rules (Rules.chooseLaunch, maxVictims,
-- spawnInterval, timeScale) with a player who knows every landing point but
-- moves the net at a capped speed (px per REAL second). For every miss it asks
-- whether any player at that speed could have made it: a miss is "unavoidable"
-- when another jumper landed far away, too close in time for the net to cross.
-- Also reports jumpers per minute, so fairness doesn't quietly starve the
-- busy stages.

dofile("source/game/config.lua")
dofile("source/game/physics.lua")
dofile("source/game/rules.lua")

-- Overrides for tuning sweeps:
--   FAIR_SPEED=260 FAIR_REACTION=0.3 lua scripts/fairness.lua
Config.FAIR_NET_SPEED = tonumber(os.getenv("FAIR_SPEED") or "") or Config.FAIR_NET_SPEED
Config.FAIR_REACTION = tonumber(os.getenv("FAIR_REACTION") or "") or Config.FAIR_REACTION

-- FAIR_OFF=1 lua scripts/fairness.lua  -> baseline with fair spawning disabled
if os.getenv("FAIR_OFF") == "1" then
    Rules.fairToLaunch = function() return true end
    print("(fair spawning disabled)")
end

local DT = 1 / 30
local AIM = 0.6
local MINUTES = 200

local function run(speed, score)
    math.randomseed(42)
    local scale = Rules.timeScale(score)
    local half = Rules.netWidth(score) / 2
    local netMin, netMax = Physics.netRange(half)
    local simDt = DT * scale
    local caught, lost, unavoidable, spawned = 0, 0, 0, 0
    local victims, net, timer = {}, 200, 0
    local landings = {} -- recent {t = frame, x} catch-line crossings

    for f = 1, 30 * 60 * MINUTES do
        timer = timer + simDt
        local n = #victims
        if n < Rules.maxVictims(score) then
            local wait = (n == 0) and Config.RESPAWN_DELAY or Rules.spawnInterval(score)
            if timer >= wait then
                local b = Rules.chooseLaunch(Config.spawnPoints(), victims, scale, nil, half)
                if b then victims[#victims + 1] = b; timer = 0; spawned = spawned + 1 end
            end
        end

        -- Player: chase the soonest landing at a capped real-time speed.
        local target, soonest
        for _, b in ipairs(victims) do
            local t = Physics.timeToLand(b)
            if t and (not soonest or t < soonest) then target, soonest = b, t end
        end
        if target then
            local want = Physics.landingX(target) - AIM * half
            local step = speed * DT
            net = math.max(netMin, math.min(netMax,
                net + math.max(-step, math.min(step, want - net))))
        end

        for i = #victims, 1, -1 do
            local b = victims[i]
            local py = b.y
            Physics.step(b, simDt)
            Physics.collideWalls(b)
            local line = Physics.catchLine()
            if py <= line and b.y >= line and b.vy > 0 then
                landings[#landings + 1] = { f = f, x = b.x, body = b }
            end
            if Physics.isCatch(py, b, net, half) then Physics.bounce(b, net, half); caught = caught + 1 end
            if Physics.isRescued(b) then
                table.remove(victims, i); timer = 0
            elseif Physics.isLost(b) then
                lost = lost + 1
                -- Find this jumper's crossing, then any other crossing that
                -- needed the net elsewhere too soon before or after it.
                local mine
                for k = #landings, 1, -1 do if landings[k].body == b then mine = landings[k]; break end end
                if mine then
                    for _, o in ipairs(landings) do
                        if o.body ~= b and math.abs(o.f - mine.f) <= 60 then
                            local dx = math.abs(o.x - mine.x) - half
                            local realGap = math.abs(o.f - mine.f) * DT
                            if dx > 0 and realGap < dx / speed then unavoidable = unavoidable + 1; break end
                        end
                    end
                end
                table.remove(victims, i); timer = 0
            end
        end
        -- keep only the last ~3 s of crossings
        while #landings > 0 and landings[1].f < f - 90 do table.remove(landings, 1) end
    end

    print(string.format("score %4d (%d jumpers, %.2fx, net %2d px) crank %3d px/s: %5.1f jumpers/min, %5.1f misses/min, unavoidable %4.1f%% of misses",
        score, Rules.maxVictims(score), scale, half * 2, speed,
        spawned / MINUTES, lost / MINUTES, lost > 0 and 100 * unavoidable / lost or 0))
end

local speeds = arg[1] and { tonumber(arg[1]) } or { 300, 450 }
local scores = arg[2] and { tonumber(arg[2]) } or { 1000, 2500 }
for _, score in ipairs(scores) do
    for _, speed in ipairs(speeds) do run(speed, score) end
end
