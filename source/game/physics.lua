-- Victim physics. Pure Lua (depends only on Config), testable without the SDK.
--
-- A body is a plain table { x, y, vx, vy } in screen pixels / pixels-per-second.
-- The core mechanic: a bounce's direction depends ONLY on where the victim
-- lands on the net. Speed is constant, so the player aims by positioning.

Physics = {}

function Physics.clampDt(dt)
    if dt > Config.MAX_DT then return Config.MAX_DT end
    if dt < 0 then return 0 end
    return dt
end

-- Semi-implicit Euler: update velocity, then position.
function Physics.step(b, dt)
    b.vy = b.vy + Config.GRAVITY * dt
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt
end

-- Left: bounce off the building face.
-- Right: the screen edge is the ambulance's back door. An overshoot stops
-- dead and drops straight in, rather than ricocheting back into the field
-- (which punished the strongest throws with an endless loop).
function Physics.collideWalls(b)
    local r = Config.VICTIM_RADIUS
    if b.vx < 0 and b.x - r < Config.BUILDING_RIGHT then
        b.x = Config.BUILDING_RIGHT + r
        b.vx = -b.vx
    elseif b.vx > 0 and b.x + r > Config.SCREEN_WIDTH then
        b.x = Config.SCREEN_WIDTH - r
        b.vx = 0
    end
end

-- The height the victim's center is at when its feet touch the net.
function Physics.catchLine()
    return Config.NET_Y - Config.VICTIM_RADIUS
end

-- -1 = left edge of the net, 0 = center, +1 = right edge.
function Physics.hitPosition(x, netX)
    local h = (x - netX) / Config.NET_HALF_WIDTH
    if h > 1 then return 1 end
    if h < -1 then return -1 end
    return h
end

-- Launch velocity for a given hit position. Angle is measured from vertical;
-- positive leans toward the ambulance.
function Physics.bounceAngle(h)
    return Config.BOUNCE_BIAS_DEG + h * Config.BOUNCE_SPREAD_DEG
end

function Physics.bounceVelocity(h)
    local a = math.rad(Physics.bounceAngle(h))
    return Config.BOUNCE_SPEED * math.sin(a), -Config.BOUNCE_SPEED * math.cos(a)
end

-- True if the body crossed the net surface this step while falling and is
-- over the net. Testing the crossing (not "inside a box") means a catch fires
-- exactly once and can't be skipped by a large step.
function Physics.isCatch(prevY, b, netX)
    local line = Physics.catchLine()
    return b.vy > 0
        and prevY <= line and b.y >= line
        and math.abs(b.x - netX) <= Config.NET_HALF_WIDTH
end

-- Apply a catch: snap to the net and launch. Returns the hit position.
function Physics.bounce(b, netX)
    local h = Physics.hitPosition(b.x, netX)
    b.y = Physics.catchLine()
    b.vx, b.vy = Physics.bounceVelocity(h)
    b.bounces = (b.bounces or 0) + 1
    return h
end

-- Seconds until a body next crosses the catch line on the way down, ignoring
-- walls, or nil if it never will. Used by the menu's demo player to get under
-- jumpers early, the way a person would.
function Physics.timeToLand(b)
    local dy = Physics.catchLine() - b.y
    local disc = b.vy * b.vy + 2 * Config.GRAVITY * dy
    if disc < 0 then return nil end
    local t = (-b.vy + math.sqrt(disc)) / Config.GRAVITY
    if t < 0 then return nil end
    return t
end

-- Where that crossing happens (x), or nil.
function Physics.landingX(b)
    local t = Physics.timeToLand(b)
    return t and (b.x + b.vx * t)
end

-- Dropping into the ambulance (or touching it on the way past).
function Physics.isRescued(b)
    return b.x >= Config.AMBULANCE_LEFT
        and b.y + Config.VICTIM_RADIUS >= Config.AMBULANCE_TOP
end

function Physics.isLost(b)
    return b.y - Config.VICTIM_RADIUS > Config.SCREEN_HEIGHT
end
