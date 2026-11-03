-- Scoring and difficulty. Pure Lua (depends only on Config), testable without the SDK.

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
