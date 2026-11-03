-- Scoring, difficulty and fair spawning. Pure Lua (depends on Config and
-- Physics), testable without the SDK.

Rules = {}

local function step(score)
    return math.floor(score / Config.SPEEDUP_EVERY)
end

-- How many victims may be in the air at once.
function Rules.maxVictims(score)
    local n = 1
    for _, threshold in ipairs(Config.EXTRA_VICTIM_SCORES) do
        if score >= threshold then n = n + 1 end
    end
    return n
end

-- Seconds before an additional victim jumps while others are in the air.
function Rules.spawnInterval(score)
    return math.max(Config.SPAWN_INTERVAL_MIN,
        Config.SPAWN_INTERVAL - step(score) * Config.SPAWN_INTERVAL_STEP)
end

-- Multiplier on simulation time. Scaling time (not gravity or speed) keeps
-- every trajectory's shape identical, so the reachability guarantees in the
-- physics tests still hold at any difficulty: the game just plays faster.
function Rules.timeScale(score)
    return math.min(Config.TIME_SCALE_MAX, 1 + step(score) * Config.TIME_SCALE_STEP)
end

-- Points for a rescue that took `bounces` catches. Returns points, isExpress.
function Rules.rescueScore(bounces)
    if bounces <= Config.EXPRESS_MAX_BOUNCES then
        return Config.SCORE_PER_RESCUE + Config.EXPRESS_BONUS, true
    end
    return Config.SCORE_PER_RESCUE, false
end

-- Fair spawning ---------------------------------------------------------------

-- Could a player reach both landings? a and b are {t = seconds, x = px}.
-- Landings close together on the ground are fine at any timing (one net
-- position catches both). Otherwise the time gap must cover the crank travel
-- plus reaction time. timeScale converts game seconds to real seconds: at
-- 1.4x the player has less real time for the same game-time gap.
function Rules.landingsCompatible(a, b, timeScale)
    local dx = math.abs(a.x - b.x) - Config.NET_HALF_WIDTH
    if dx <= 0 then return true end
    local realGap = math.abs(a.t - b.t) / (timeScale or 1)
    return realGap >= dx / Config.FAIR_NET_SPEED + Config.FAIR_REACTION
end

local function nextLanding(body)
    local t = Physics.timeToLand(body)
    if not t then return nil end
    return { t = t, x = body.x + body.vx * t }
end

-- Is launching `candidate` (a body) fair given the bodies already in the air?
-- Only each jumper's NEXT landing is checked: later bounces go where the
-- player aims them, so clashes after that are the player's to manage.
function Rules.fairToLaunch(candidate, others, timeScale)
    local mine = nextLanding(candidate)
    if not mine then return false end
    for _, o in ipairs(others) do
        local theirs = nextLanding(o)
        if theirs and not Rules.landingsCompatible(mine, theirs, timeScale) then
            return false
        end
    end
    return true
end

-- Pick a fair jump: a body {x, y, vx, vy} from a random window and speed, or
-- nil if none of FAIR_LAUNCH_TRIES candidates is fair right now (try again
-- next frame). `random` defaults to math.random (injectable for tests).
function Rules.chooseLaunch(spawnPoints, others, timeScale, random)
    random = random or math.random
    for _ = 1, Config.FAIR_LAUNCH_TRIES do
        local p = spawnPoints[random(1, #spawnPoints)]
        local body = {
            x = p.x, y = p.y,
            vx = random(Config.JUMP_VX_MIN, Config.JUMP_VX_MAX),
            vy = Config.JUMP_VY,
        }
        if Rules.fairToLaunch(body, others, timeScale) then return body end
    end
    return nil
end
