-- Headless smoke test: runs the real main.lua against a stubbed Playdate API
-- and plays several full games with a scripted player. From the repo root:
--   lua tests/smoke.lua               # no art on disk: placeholder fallbacks
--   SMOKE_ART=1 lua tests/smoke.lua   # every image present, sheets 4 frames
--
-- What it catches: runtime errors in OUR code (nil fields, bad state
-- transitions, scoring/lives logic) across menu → play → pause → game over →
-- menu → play. What it can't catch: a wrong Playdate API name or signature;
-- the stubs accept any call. That still needs the simulator.

-- Permissive stub: any field is a callable stub; calling returns a stub.
local Stub = {}
local function stub() return setmetatable({}, Stub) end
Stub.__index = function() return stub() end
Stub.__call = function() return stub() end

local WITH_ART = os.getenv("SMOKE_ART") == "1"

-- Recorded output ------------------------------------------------------------
local texts = {}        -- text drawn this frame
local saved = nil       -- last datastore.write
local soundsPlayed = {}

-- Input state the test controls
local input = { justA = false, justB = false, left = false, right = false, crank = 0 }

-- CoreLibs object model -------------------------------------------------------
function class(name)
    local c = {}
    c.__index = c
    return {
        extends = function(parent)
            -- gfx.sprite is both the module (static update/removeAll) and the
            -- base class; subclasses get the instance methods.
            parent = rawget(parent, "__instance") or parent
            c.super = parent
            -- Like the SDK, sprites own width/height (their image's size);
            -- game code storing its own values there would silently fail on
            -- a real Playdate, so fail loudly here.
            c.__newindex = function(t, k, v)
                if (k == "width" or k == "height") and rawget(c, "__isSprite") then
                    error("sprite." .. k .. " is read-only on Playdate (use another field name)", 2)
                end
                rawset(t, k, v)
            end
            if rawget(parent, "__isSprite") then c.__isSprite = true end
            setmetatable(c, {
                __index = parent,
                __call = function(cls, ...)
                    local o = setmetatable({}, cls)
                    o:init(...)
                    return o
                end,
            })
            _G[name] = c
        end,
    }
end

-- Sprites ---------------------------------------------------------------------
local live = {}
local Sprite = {}
Sprite.__index = Sprite
Sprite.__isSprite = true -- subclasses inherit the marker (see class())
function Sprite:init() self.x, self.y = 0, 0 end
function Sprite:moveTo(x, y)
    assert(type(x) == "number" and type(y) == "number", "moveTo needs numbers")
    assert(x == x and y == y, "moveTo got NaN")
    self.x, self.y = x, y
end
function Sprite:setImage(img) assert(img, "setImage(nil)"); self.image = img end
function Sprite:getImage() return self.image end
function Sprite:setZIndex(z) self.z = z end
function Sprite:getSize() return self.image:getSize() end
function Sprite:add() live[self] = true end
function Sprite:remove() live[self] = nil end
Sprite.update = function() end

local function image(w, h)
    local img = stub()
    rawset(img, "invertedImage", function() return image(w, h) end)
    rawset(img, "getSize", function() return w or 16, h or 16 end)
    return img
end

-- A fake 4-frame imagetable; each frame is a distinct image object.
local function imagetable(name)
    local w, h = name:match("smoke") and 64 or 16, name:match("smoke") and 24 or 16
    local frames = { image(w, h), image(w, h), image(w, h), image(w, h) }
    return {
        getLength = function() return #frames end,
        getImage = function(_, i)
            assert(i >= 1 and i <= #frames, "frame index out of range: " .. tostring(i))
            return frames[i]
        end,
        frames = frames,
    }
end

-- playdate API ------------------------------------------------------------------
kTextAlignment = { left = 0, right = 1, center = 2 }

local gfx = setmetatable({
    kColorWhite = 1, kColorBlack = 0,
    kDrawModeFillWhite = 1, kDrawModeCopy = 0,
    image = {
        new = function(a, b)
            if type(a) == "string" then
                return WITH_ART and image() or nil
            end
            return image(a, b)
        end,
    },
    imagetable = { new = function(path) return WITH_ART and imagetable(path) or nil end },
    sprite = setmetatable({
        -- Like the SDK: the callback is drawn by a sprite, which removeAll() deletes.
        setBackgroundDrawingCallback = function(fn)
            local bg = setmetatable({ isBackground = true, draw = fn }, Sprite)
            live[bg] = true
        end,
        update = function()
            for s in pairs(live) do s:update() end
        end,
        removeAll = function() live = {} end,
        __instance = Sprite,
    }, { __index = function(_, k) return Sprite[k] or stub() end }),
    drawText = function(t) table.insert(texts, t) end,
    getTextSize = function(t) return #t * 8, 18 end,
    drawTextAligned = function(t) table.insert(texts, t) end,
}, Stub)

local timers = {}
playdate = setmetatable({
    graphics = gfx,
    kButtonA = "a", kButtonB = "b", kButtonLeft = "left", kButtonRight = "right",
    buttonJustPressed = function(b)
        if b == "a" then return input.justA end
        if b == "b" then return input.justB end
        return false
    end,
    buttonIsPressed = function(b) return input[b] == true end,
    getCrankChange = function() local c = input.crank; input.crank = 0; return c end,
    isCrankDocked = function() return false end,
    getElapsedTime = function() return 1 / 30 end,
    resetElapsedTime = function() end,
    getSecondsSinceEpoch = function() return 12345 end,
    datastore = {
        read = function() return saved end,
        write = function(t) saved = { highScore = t.highScore } end,
    },
    timer = {
        performAfterDelay = function(ms, fn) table.insert(timers, fn) end,
        updateTimers = function()
            local due = timers; timers = {}
            for _, fn in ipairs(due) do fn() end
        end,
    },
    sound = setmetatable({
        sampleplayer = { new = function() return nil end },
        synth = {
            new = function()
                local s = stub()
                rawset(s, "playNote", function(_, hz)
                    assert(type(hz) == "number" and hz > 0, "bad pitch")
                    table.insert(soundsPlayed, hz)
                end)
                return s
            end,
        },
    }, Stub),
    ui = { crankIndicator = stub() },
}, Stub)

-- import -> dofile from source/, CoreLibs ignored, each file once
local imported = {}
function import(path)
    if path:match("^CoreLibs/") or imported[path] then return end
    imported[path] = true
    dofile("source/" .. path .. ".lua")
end

-- Harness -----------------------------------------------------------------------
local function frame()
    texts = {}
    playdate.update()
    input.justA, input.justB = false, false
end

local function press(button) input["just" .. button] = true; frame() end

local function screenHas(pattern)
    for _, t in ipairs(texts) do if t:find(pattern) then return t end end
    return nil
end

local function shown(prefix)
    local t = screenHas("^" .. prefix)
    return t and tonumber(t:match("(%d+)$"))
end

local function findNet()
    for s in pairs(live) do if getmetatable(s) == Firefighters then return s end end
end

-- Scripted player: steer the net under whichever victim lands next, landing
-- it right of center (aim 0.6). Uses the crank, like a real player.
local function play()
    local net = findNet()
    local target, soonest
    for s in pairs(live) do
        local t = s.body and Physics.timeToLand(s.body)
        if t and (not soonest or t < soonest) then target, soonest = s, t end
    end
    if net and target then
        local want = Physics.landingX(target.body) - 0.6 * net.half
        input.crank = (want - net.x) / Config.CRANK_SENSITIVITY
    end
    frame()
end

local passed, failed = 0, 0
local function check(cond, msg)
    if cond then passed = passed + 1 else failed = failed + 1; print("  FAIL " .. msg) end
end

local function findSprite(cls)
    for s in pairs(live) do if getmetatable(s) == cls then return s end end
end

local function hasBackground()
    for s in pairs(live) do if s.isBackground then return true end end
    return false
end

-- The run ---------------------------------------------------------------------------
import("main")
print(WITH_ART and "smoke (with art: 4-frame sheets)" or "smoke (no art: placeholders)")

frame()
if WITH_ART then
    check(hasBackground(), "background art on the menu at launch")
    check(not screenHas(Config.TITLE), "title art replaces the title text")
else
    check(screenHas(Config.TITLE), "menu shows title text without title art")
end
check(shown("High Score: ") == nil, "no high score line until there is one")

-- Attract mode: the demo plays itself for 60 s without scoring or sound.
-- Each jumper is classified by where it was when it disappeared.
local soundsBefore = #soundsPlayed
local demoVictims, demoRescues, demoLost, netMoved = 0, 0, 0, false
local tracked = {}
local net0 = findSprite(Firefighters).x
for _ = 1, 30 * 60 do
    frame()
    for s in pairs(live) do
        if s.body and not tracked[s] then tracked[s] = true; demoVictims = demoVictims + 1 end
    end
    for s in pairs(tracked) do
        if not live[s] then
            tracked[s] = nil
            if s.body.x >= Config.AMBULANCE_LEFT then demoRescues = demoRescues + 1 else demoLost = demoLost + 1 end
        end
    end
    netMoved = netMoved or findSprite(Firefighters).x ~= net0
end
print(string.format("  attract mode: %d jumpers, %d rescued, %d dropped in 60 s", demoVictims, demoRescues, demoLost))
check(demoVictims >= 5, "demo keeps sending jumpers")
check(demoRescues >= 4 * demoLost, "demo player rescues at least 80% (" .. demoRescues .. " vs " .. demoLost .. " dropped)")
check(netMoved, "demo net moves")
check(#soundsPlayed == soundsBefore, "demo is silent")
check(not screenHas("^Score: "), "no score HUD on the menu")

press("A")
check(shown("Score: ") == 0 and shown("Lives: ") == Config.START_LIVES, "game starts at 0 / full lives")
check(findSprite(Firefighters).netWidth == Config.NET_WIDTH_START, "net starts at its widest")

if WITH_ART then
    check(hasBackground(), "background art survives starting a game")
    local building, net, smoke = findSprite(Building), findSprite(Firefighters), findSprite(Smoke)
    check(smoke ~= nil, "smoke sprite created when its art exists")
    check(smoke and smoke.y + 12 == Config.BUILDING_TOP, "smoke sits on the roof")
    check(smoke and smoke.z < Config.Z_VICTIM and building.z < smoke.z, "draw order: building < smoke < victims")

    local seen = {}
    for _ = 1, 30 do frame(); seen[building:getImage()] = true end
    local n = 0; for _ in pairs(seen) do n = n + 1 end
    check(n == 4, "building flames cycle through all 4 frames (saw " .. n .. ")")

    local standing = net:getImage()
    for _ = 1, 15 do frame() end
    check(net:getImage() == standing, "firefighters stand still when the net isn't moving")
    local stepped = false
    for _ = 1, 10 do input.left = true; frame(); stepped = stepped or net:getImage() ~= standing end
    input.left = false
    check(stepped, "firefighters step while the net moves")
    frame()
    check(net:getImage() == standing, "firefighters return to standing when stopped")

    press("B")
    local frozen = building:getImage()
    for _ = 1, 30 do frame() end
    check(building:getImage() == frozen, "animation freezes while paused")
    press("B")
else
    check(findSprite(Smoke) == nil, "no smoke sprite without smoke art")
end

-- Play well for 2 minutes of game time.
for _ = 1, 30 * 120 do play() end
local scoreAfterPlay = shown("Score: ")
local netNow = findSprite(Firefighters)
check(netNow.netWidth == Rules.netWidth(scoreAfterPlay) or netNow.netWidth > Rules.netWidth(scoreAfterPlay),
    "net width follows the score")
check(netNow.netWidth < Config.NET_WIDTH_START, "net has narrowed by " .. tostring(scoreAfterPlay) .. " points")
check(netNow.half == netNow.netWidth / 2, "catch area matches the drawn net")
print(string.format("  scripted player: score %s, lives %s after 2 min",
    tostring(scoreAfterPlay), tostring(shown("Lives: "))))
check(scoreAfterPlay and scoreAfterPlay >= 1000, "a good player scores (got " .. tostring(scoreAfterPlay) .. ")")
check(#soundsPlayed > 0, "sounds played")

-- Pause freezes everything.
press("B")
check(screenHas("^PAUSED"), "B pauses")
local pausedScore = shown("Score: ")
for _ = 1, 90 do frame() end
check(shown("Score: ") == pausedScore, "nothing happens while paused")
press("B")
check(not screenHas("^PAUSED"), "B resumes")

-- System menu auto-pauses.
playdate.gameWillPause()
frame()
check(screenHas("^PAUSED"), "system menu pauses")
press("A")

-- Stop playing: victims fall, game ends.
local frames = 0
while not screenHas("^GAME OVER") and frames < 30 * 120 do frame(); frames = frames + 1 end
check(screenHas("^GAME OVER"), "game over when lives run out")
local final = shown("Final Score: ")
check(final and final >= scoreAfterPlay, "final score shown")
check(screenHas("^NEW HIGH SCORE"), "new high score announced")
check(saved and saved.highScore == final, "high score saved to datastore")

-- Effects/timers keep running on the game over screen without error.
for _ = 1, 60 do frame() end

press("A")
-- The high score rotates with the hints on one line; wait for its turn.
local function waitForHighScore()
    for _ = 1, 30 * Config.HINT_DURATION * 5 do
        if screenHas("^High Score: ") then return shown("High Score: ") end
        frame()
    end
end
check(waitForHighScore() == final, "back on the menu, which shows the high score")

-- Second game: fresh state, no carry-over (old bug: duplicated observers).
press("A")
check(shown("Score: ") == 0 and shown("Lives: ") == Config.START_LIVES, "second game resets")
for _ = 1, 30 * 60 do play() end
local s2 = shown("Score: ")
check(s2 and s2 % 50 == 0, "second game scores in normal increments (" .. tostring(s2) .. ")")

-- Reload with a saved high score (simulates relaunching the game).
imported = {}
live = {}
import("main")
frame()
check(waitForHighScore() == final, "high score survives relaunch")

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
