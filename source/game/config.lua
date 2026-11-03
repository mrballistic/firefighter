-- Shared layout and tuning constants.
--
-- Pure Lua: no playdate.* APIs here, so tests/physics_test.lua can load this
-- file with stock Lua (no SDK needed). Keep it that way.

Config = {
    TITLE = "CRANK & CATCH",

    SCREEN_WIDTH = 400,
    SCREEN_HEIGHT = 240,

    -- Building (left side). Its bottom sits on the bottom of the screen.
    BUILDING_X = 30,          -- centre x
    BUILDING_WIDTH = 40,
    BUILDING_HEIGHT = 200,
    WINDOW_COUNT = 5,
    WINDOW_SIZE = 20,
    WINDOW_TOP_OFFSET = 15,   -- first window centre, below the roof
    WINDOW_SPACING = 30,

    -- Net (firefighters). NET_Y is the top surface of the net.
    NET_Y = 220,
    NET_WIDTH = 48,
    CRANK_SENSITIVITY = 2.0,  -- pixels per degree of crank
    DPAD_SPEED = 220,         -- pixels per second (fallback control)

    -- Ambulance (right side)
    AMBULANCE_X = 370,        -- centre x
    AMBULANCE_Y = 220,        -- centre y
    AMBULANCE_WIDTH = 40,
    AMBULANCE_HEIGHT = 30,
    FLASH_DURATION = 0.2,

    -- Victims
    VICTIM_SIZE = 15,
    JUMP_VX_MIN = 50,         -- horizontal speed leaving the window
    JUMP_VX_MAX = 80,
    JUMP_VY = -80,            -- small upward hop leaving the window

    -- Physics
    GRAVITY = 400,            -- px/s^2
    BOUNCE_SPEED = 280,       -- every bounce leaves the net at this speed
    BOUNCE_BIAS_DEG = 5,      -- centre hit: nearly vertical, slight forward lean
    BOUNCE_SPREAD_DEG = 15,   -- edge hit adds/removes this much angle
    MAX_DT = 1 / 15,          -- clamp frame time so a hitch can't teleport bodies

    -- Rules
    START_LIVES = 3,
    SCORE_PER_RESCUE = 100,
    EXPRESS_MAX_BOUNCES = 2,  -- rescue in this many bounces or fewer...
    EXPRESS_BONUS = 50,       -- ...earns this on top
    RESPAWN_DELAY = 0.75,     -- seconds after the screen empties

    -- Difficulty ramp (see rules.lua)
    EXTRA_VICTIM_SCORES = { 500, 2000 }, -- each threshold allows one more victim at once
    SPEEDUP_EVERY = 500,      -- score per difficulty step
    SPAWN_INTERVAL = 3,       -- seconds before an additional victim jumps...
    SPAWN_INTERVAL_STEP = 0.25, -- ...minus this per step...
    SPAWN_INTERVAL_MIN = 1.5, -- ...down to this
    TIME_SCALE_STEP = 0.05,   -- game speed +5% per step...
    TIME_SCALE_MAX = 1.4,     -- ...capped here

    -- Effects
    POPUP_DURATION = 0.8,
    POPUP_RISE = 20,
    SHAKE_DURATION = 0.25,
    SHAKE_AMOUNT = 3,
    NET_DIP = 3,              -- pixels the net sags on a catch
    NET_DIP_DURATION = 0.1,

    -- Animation timing (only used when the art has *-table-W-H.png sheets).
    -- Each loops on its own clock; all freeze while paused.
    VICTIM_FRAME_DURATION = 0.12,   -- seconds per flail frame
    BUILDING_FRAME_DURATION = 0.18, -- seconds per flame flicker frame
    SMOKE_FRAME_DURATION = 0.3,     -- seconds per smoke frame (slow drift)
    FIREFIGHTER_STRIDE = 8,         -- pixels walked per step frame

    -- Menu attract mode: the scene plays itself behind the title.
    DEMO_NET_SPEED = 200,     -- px/s, about what a player manages on the crank
    DEMO_NET_HOME = 110,      -- where the demo net waits: under the first landings
    DEMO_AIM_MIN = 0.2,       -- each demo jumper gets a random aim in this range,
    DEMO_AIM_MAX = 0.9,       -- so the demo shows short and long throws
    DEMO_RESPAWN_DELAY = 1.0,
    DEMO_FIRST_WINDOW = 4,    -- demo jumpers use the lower windows, clear of the title text
    HINT_DURATION = 3,        -- seconds each menu hint shows before the next
    BLINK_PERIOD = 1.0,       -- "Press A" blink cycle, seconds

    -- Draw order (higher draws on top). Background art is drawn underneath all.
    Z_BUILDING = 10,
    Z_SMOKE = 20,
    Z_AMBULANCE = 30,
    Z_NET = 40,
    Z_VICTIM = 50,
}

-- Derived values
Config.VICTIM_RADIUS = Config.VICTIM_SIZE / 2
Config.NET_HALF_WIDTH = Config.NET_WIDTH / 2
Config.BUILDING_Y = Config.SCREEN_HEIGHT - Config.BUILDING_HEIGHT / 2
Config.BUILDING_TOP = Config.SCREEN_HEIGHT - Config.BUILDING_HEIGHT
Config.BUILDING_LEFT = Config.BUILDING_X - Config.BUILDING_WIDTH / 2
Config.BUILDING_RIGHT = Config.BUILDING_X + Config.BUILDING_WIDTH / 2
Config.AMBULANCE_LEFT = Config.AMBULANCE_X - Config.AMBULANCE_WIDTH / 2
Config.AMBULANCE_TOP = Config.AMBULANCE_Y - Config.AMBULANCE_HEIGHT / 2
Config.NET_MIN_X = Config.BUILDING_RIGHT + Config.NET_HALF_WIDTH
Config.NET_MAX_X = Config.AMBULANCE_LEFT - Config.NET_HALF_WIDTH

-- Where victims appear: just outside each window, on the building's face.
function Config.spawnPoints()
    local points = {}
    for i = 1, Config.WINDOW_COUNT do
        points[i] = {
            x = Config.BUILDING_RIGHT + Config.VICTIM_RADIUS,
            y = Config.BUILDING_TOP + Config.WINDOW_TOP_OFFSET + (i - 1) * Config.WINDOW_SPACING,
        }
    end
    return points
end
