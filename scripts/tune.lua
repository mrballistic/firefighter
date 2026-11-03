-- Bounce tuning sweep. Run from the repo root:  lua scripts/tune.lua
-- Simulates a perfect player aiming at fixed hit positions from every window
-- and prints bounces-to-rescue for a grid of BOUNCE_SPEED / spread values.
-- Goal: each step of aim should buy noticeably fewer bounces.

dofile("source/game/config.lua")
dofile("source/game/physics.lua")

local AIMS = { 0, 0.25, 0.5, 0.75, 1 }

local function simulate(p, vx, aim)
    local b = { x = p.x, y = p.y, vx = vx, vy = Config.JUMP_VY }
    local n = 0
    for _ = 1, 30 * 60 do
        local py = b.y
        Physics.step(b, 1 / 30)
        Physics.collideWalls(b)
        local nx = math.max(Config.NET_MIN_X, math.min(Config.NET_MAX_X, b.x - aim * Config.NET_HALF_WIDTH))
        if Physics.isCatch(py, b, nx) then Physics.bounce(b, nx); n = n + 1 end
        if Physics.isRescued(b) then return n end
        if Physics.isLost(b) then return nil end
    end
    return nil
end

local function row()
    local cells = {}
    for _, aim in ipairs(AIMS) do
        local sum, count, fail = 0, 0, false
        for _, p in ipairs(Config.spawnPoints()) do
            for _, vx in ipairs({ Config.JUMP_VX_MIN, Config.JUMP_VX_MAX }) do
                local n = simulate(p, vx, aim)
                if not n then fail = true else sum = sum + n; count = count + 1 end
            end
        end
        cells[#cells + 1] = fail and "  FAIL" or string.format("%6.1f", sum / count)
    end
    return table.concat(cells)
end

-- Optional grids from the command line, e.g.
--   lua scripts/tune.lua "260,280,300" "12,16,20" "4,6"
local function list(arg, default)
    if not arg then return default end
    local out = {}
    for n in arg:gmatch("[^,]+") do out[#out + 1] = tonumber(n) end
    return out
end
local speeds = list(arg[1], { 200, 220, 240, 260, 280 })
local spreads = list(arg[2], { 30, 35, 40, 45 })
local biases = list(arg[3], { 4, 8 })

print("mean bounces to rescue, by aim:      0  0.25   0.5  0.75     1   apex(px) airtime(s)")
for _, bias in ipairs(biases) do
    for _, speed in ipairs(speeds) do
        for _, spread in ipairs(spreads) do
            Config.BOUNCE_SPEED, Config.BOUNCE_SPREAD_DEG, Config.BOUNCE_BIAS_DEG = speed, spread, bias
            local apex = speed * speed / (2 * Config.GRAVITY)
            local air = 2 * speed / Config.GRAVITY
            print(string.format("speed %3d spread %2d bias %d  %s   %5.0f    %4.2f",
                speed, spread, bias, row(), apex, air))
        end
    end
end
