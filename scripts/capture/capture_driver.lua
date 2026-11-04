-- Capture driver. NOT part of the game: scripts/capture/build_capture.sh
-- copies the game source to build/, appends `import "capture_driver"` to
-- main.lua there, and the copy runs in the Playdate Simulator.
--
-- It plays the game itself (fake buttons and crank, fixed random seed,
-- silent) in one of two modes, set by CAPTURE_MODE:
--   "shots" (scripts/screenshots.sh): 8x speed; writes a PNG when each
--           shot's moment arrives, then quits.
--   "video" (scripts/video.sh): writes every frame to CAPTURE_OUT/frames/
--           (menu attract mode, then a real game), logs highlight moments
--           (Express, net narrowing, misses) for picking stills, then quits.
--
-- CAPTURE_OUT and CAPTURE_MODE come from capture_config.lua, which the build
-- script generates.

import "capture_config"

local gfx <const> = playdate.graphics

local VIDEO <const> = CAPTURE_MODE == "video"
local SPEED <const> = VIDEO and 4 or 8      -- game frames per simulator frame
local VIDEO_MENU_FRAMES <const> = 30 * 5    -- attract mode before pressing Start
local VIDEO_FRAMES <const> = 30 * 48        -- total length of the recording
local DT <const> = 1 / 30
local NET_SPEED <const> = 450    -- px/s the scripted player cranks at (a brisk turn is ~720)
local AIM <const> = 0.6          -- right of center: steady progress, few misses
local GIVE_UP_FRAMES <const> = 30 * 60 * 15

-- Determinism, silence, no shake, crank undocked ------------------------------
math.randomseed(20261103)
playdate.getElapsedTime = function() return DT end
playdate.resetElapsedTime = function() end
playdate.isCrankDocked = function() return false end
for _, name in ipairs({ "bounce", "rescue", "splat", "gameOver", "extraLife" }) do
    Sound[name] = function() end
end
Effects.shake = function() end

-- Fake input ---------------------------------------------------------------------
local input = { a = false, crank = 0 }
playdate.buttonJustPressed = function(button)
    return button == playdate.kButtonA and input.a
end
playdate.buttonIsPressed = function() return false end
playdate.getCrankChange = function()
    local c = input.crank
    input.crank = 0
    return c, c
end

-- Observe what the game draws and pops up --------------------------------------------
local texts = {}
local realDrawText = gfx.drawText
gfx.drawText = function(text, ...)
    texts[#texts + 1] = text
    return realDrawText(text, ...)
end

local frame = 0
local lastPopup = nil

-- Progress log, readable on the host at
-- <SDK>/Disk/Data/com.mrballistic.crankandcatch.capture/capturelog.json
local log = { games = 1, maxScore = 0, captured = {}, events = {} }
local function writeLog(status)
    log.status, log.frame = status, frame
    playdate.datastore.write(log, "capturelog")
end
local realPopup = Effects.popup
Effects.popup = function(text, x, y)
    lastPopup = { text = text, frame = frame }
    if VIDEO then log.events[#log.events + 1] = { frame = frame, text = text } end
    return realPopup(text, x, y)
end

local function onScreen(pattern)
    for _, t in ipairs(texts) do
        local m = t:match(pattern)
        if m then return m end
    end
end

local function victims()
    local out = {}
    for _, s in ipairs(gfx.sprite.getAllSprites()) do
        if s.body then out[#out + 1] = s end
    end
    return out
end

local function net()
    for _, s in ipairs(gfx.sprite.getAllSprites()) do
        if s:isa(Firefighters) then return s end
    end
end

local function airborne(minClearance)
    local line = Physics.catchLine() - minClearance
    local list = {}
    for _, v in ipairs(victims()) do
        if v.body.y < line then list[#list + 1] = v end
    end
    return list
end

local function spreadOut(list, minGap)
    for i = 1, #list do
        for j = i + 1, #list do
            if math.abs(list[i].body.x - list[j].body.x) < minGap then return false end
        end
    end
    return true
end

-- Scripted player: crank toward the next landing point at a human-ish speed.
local function steer()
    local n = net()
    if not n then return end
    local target, soonest
    for _, v in ipairs(victims()) do
        local t = Physics.timeToLand(v.body)
        if t and (not soonest or t < soonest) then target, soonest = v, t end
    end
    if not target then return end
    -- In video mode each jumper gets its own aim, so the footage shows a mix
    -- of short and long throws (and the odd Express).
    if VIDEO and not target.captureAim then target.captureAim = 0.45 + math.random() * 0.45 end
    local want = Physics.landingX(target.body) - (target.captureAim or AIM) * n.half
    local step = NET_SPEED * DT
    local dx = math.max(-step, math.min(step, want - n.x))
    input.crank = dx / Config.CRANK_SENSITIVITY
end

-- The shots ------------------------------------------------------------------------------
local shots = {
    {
        name = "01-menu",
        ready = function()
            if frame < 90 or not onScreen("^Press") then return false end
            for _, v in ipairs(victims()) do
                local b = v.body
                if b.y < 150 and b.x > 150 and b.x < 280 and math.abs(b.vy) < 60 then return true end
            end
            return false
        end,
    },
    {
        -- "2 up": two jumpers in the air at once, well apart and clearly airborne.
        name = "02-two-up",
        ready = function()
            local score = tonumber(onScreen("^Score: (%d+)") or "0")
            if score < 500 then return false end
            local all = victims()
            if #all ~= 2 then return false end
            local up = airborne(40)
            return #up == 2 and spreadOut(up, 90)
        end,
    },
}
local done = {}       -- name -> true once captured
local remaining = #shots

local function capture(name)
    local path = CAPTURE_OUT .. "/" .. name .. ".png"
    playdate.simulator.writeToFile(gfx.getWorkingImage(), path)
    log.captured[#log.captured + 1] = name
    writeLog("captured " .. name)
end

-- Main loop ----------------------------------------------------------------------------------
local realUpdate = playdate.update
local pressQueue = 0  -- pending A presses (one per game frame)

function playdate.update()
    for _ = 1, SPEED do
        frame = frame + 1
        texts = {}

        input.a = false
        if pressQueue > 0 then
            input.a = true
            pressQueue = pressQueue - 1
        end
        steer()
        realUpdate()
        log.maxScore = math.max(log.maxScore, tonumber(onScreen("^Score: (%d+)") or "0"))

        if VIDEO then
            playdate.simulator.writeToFile(gfx.getWorkingImage(),
                string.format("%s/frames/f%05d.png", CAPTURE_OUT, frame))
            if frame == VIDEO_MENU_FRAMES then pressQueue = 1 end
            if frame >= VIDEO_FRAMES then
                writeLog("video done")
                playdate.simulator.exit()
                return
            end
            goto continue
        end

        -- The menu shot comes first; the gameplay shots in whatever order
        -- their moments arrive.
        for i, shot in ipairs(shots) do
            if not done[shot.name] and (i == 1 or done[shots[1].name]) and shot.ready() then
                capture(shot.name)
                done[shot.name] = true
                remaining = remaining - 1
                if i == 1 then pressQueue = 1 end -- leave the menu, start playing
                break
            end
        end

        if remaining == 0 or frame > GIVE_UP_FRAMES then
            local missing = {}
            for _, shot in ipairs(shots) do
                if not done[shot.name] then missing[#missing + 1] = shot.name end
            end
            writeLog(#missing > 0 and ("gave up waiting for " .. table.concat(missing, ", ")) or "done")
            playdate.simulator.exit()
            return
        end

        -- Ran out of lives before the next shot: back to the menu and go again.
        if onScreen("^GAME OVER") and pressQueue == 0 then
            pressQueue = 2
            log.games = log.games + 1
            writeLog("restarting")
        end
        ::continue::
    end
end
