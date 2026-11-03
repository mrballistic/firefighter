import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "game/config"
import "game/physics"
import "game/rules"
import "game/assets"
import "game/sound"
import "game/effects"
import "game/entities/building"
import "game/entities/smoke"
import "game/entities/firefighters"
import "game/entities/ambulance"
import "game/entities/victim"

local gfx <const> = playdate.graphics

local State <const> = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "gameOver",
}

local game = {
    state = State.MENU,
    score = 0,
    lives = Config.START_LIVES,
    highScore = 0,
    newHighScore = false,
    demo = true,       -- menu attract mode: the scene plays itself, nothing scores
    menuTime = 0,      -- drives the menu's blink and hint rotation
    spawnTimer = 0,
    victims = {},
    building = nil,
    smoke = nil,  -- nil when there's no smoke art
    net = nil,
    ambulance = nil,
}

-- High score persistence ----------------------------------------------------

local function loadHighScore()
    local data = playdate.datastore.read()
    game.highScore = (data and data.highScore) or 0
end

local function saveHighScore()
    playdate.datastore.write({ highScore = game.highScore })
end

-- Game flow -----------------------------------------------------------------

-- Background art is drawn by a sprite the SDK creates for the callback, and
-- gfx.sprite.removeAll() deletes it, so it's re-registered on every scene build.
local backgroundImage = nil

local function setupBackground()
    if backgroundImage then
        gfx.sprite.setBackgroundDrawingCallback(function()
            backgroundImage:draw(0, 0)
        end)
    end
end

-- The same scene serves the menu (as an attract-mode demo) and the game.
local function buildScene()
    gfx.sprite.removeAll()
    setupBackground()
    Effects.reset()
    game.spawnTimer = 0
    game.victims = {}
    game.building = Building()
    game.smoke = Smoke.create()
    game.net = Firefighters()
    game.ambulance = Ambulance()
end

local function enterMenu()
    buildScene()
    game.state = State.MENU
    game.demo = true
    game.menuTime = 0
end

local function startGame()
    buildScene()
    game.state = State.PLAYING
    game.demo = false
    game.score = 0
    game.lives = Config.START_LIVES
    game.newHighScore = false
    playdate.getCrankChange() -- discard crank movement made on the menu
end

local function endGame()
    game.state = State.GAME_OVER
    Sound.gameOver()
    if game.newHighScore then saveHighScore() end
end

-- Returns false (and spawns nothing) when no fair jump exists right now;
-- the caller just tries again next frame.
local function spawnVictim()
    local points = game.building:getSpawnPoints(game.demo and Config.DEMO_FIRST_WINDOW or 1)
    local others = {}
    for i, v in ipairs(game.victims) do others[i] = v.body end
    local scale = game.demo and 1 or Rules.timeScale(game.score)
    local launch = Rules.chooseLaunch(points, others, scale)
    if not launch then return false end
    local v = Victim(launch.x, launch.y, launch.vx, launch.vy)
    if game.demo then
        v.demoAim = Config.DEMO_AIM_MIN + math.random() * (Config.DEMO_AIM_MAX - Config.DEMO_AIM_MIN)
    end
    table.insert(game.victims, v)
    game.spawnTimer = 0
    return true
end

local function onRescued(victim)
    if game.demo then
        victim:remove()
        game.ambulance:flash()
        game.spawnTimer = 0 -- give the demo net time to walk back
        return
    end
    local points, express = Rules.rescueScore(victim.body.bounces)
    victim:remove()
    game.ambulance:flash()
    Sound.rescue(express)
    Effects.popup((express and "EXPRESS +" or "+") .. points, Config.AMBULANCE_X - 10, Config.AMBULANCE_TOP - 20)
    game.score = game.score + points
    if game.score > game.highScore then
        game.highScore = game.score
        game.newHighScore = true
    end
    game.spawnTimer = 0
end

local function onLost(victim)
    if game.demo then
        victim:remove()
        game.spawnTimer = 0
        return
    end
    local x = victim.body.x
    victim:remove()
    game.lives = game.lives - 1
    game.spawnTimer = 0
    Effects.shake()
    Effects.popup("MISS", x, Config.SCREEN_HEIGHT - 30)
    Sound.splat()
    if game.lives <= 0 then
        endGame()
    end
end

local function updateVictims(dt)
    local netX = game.net.x
    -- Iterate backwards so removing index i doesn't skip anyone.
    for i = #game.victims, 1, -1 do
        local v = game.victims[i]
        local b = v.body
        local prevY = b.y

        Physics.step(b, dt)
        Physics.collideWalls(b)
        if Physics.isCatch(prevY, b, netX) then
            local h = Physics.bounce(b, netX)
            if not game.demo then Sound.bounce(h) end
            game.net:dip()
        end

        if Physics.isRescued(b) then
            onRescued(v)
            table.remove(game.victims, i)
        elseif Physics.isLost(b) then
            onLost(v)
            table.remove(game.victims, i)
        else
            v:tick(dt)
            v:sync()
        end
    end
end

-- Menu demo player: head for wherever the next jumper will come down (rising
-- or falling), offset so they land at that jumper's aim. Between jumpers,
-- wait near the building where they first land.
local function updateDemoNet(dt)
    local target, soonest
    for _, v in ipairs(game.victims) do
        local t = Physics.timeToLand(v.body)
        if t and (not soonest or t < soonest) then target, soonest = v, t end
    end
    if target then
        local landX = Physics.landingX(target.body)
        game.net:steer(landX - target.demoAim * Config.NET_HALF_WIDTH, dt)
    else
        game.net:steer(Config.DEMO_NET_HOME, dt)
    end
end

local function updateSpawning(dt)
    if game.demo then
        game.spawnTimer = game.spawnTimer + dt
        if #game.victims == 0 and game.spawnTimer >= Config.DEMO_RESPAWN_DELAY then
            spawnVictim()
        end
        return
    end
    if game.state ~= State.PLAYING then return end
    game.spawnTimer = game.spawnTimer + dt
    local n = #game.victims
    if n < Rules.maxVictims(game.score) then
        local wait = (n == 0) and Config.RESPAWN_DELAY or Rules.spawnInterval(game.score)
        if game.spawnTimer >= wait then
            spawnVictim()
        end
    end
end

-- Input ---------------------------------------------------------------------

local function handleInput(dt)
    local a = playdate.buttonJustPressed(playdate.kButtonA)
    local b = playdate.buttonJustPressed(playdate.kButtonB)

    if game.state == State.MENU then
        if a then startGame() end
    elseif game.state == State.PLAYING then
        if b then
            game.state = State.PAUSED
        else
            game.net:updatePosition(dt)
        end
    elseif game.state == State.PAUSED then
        if a or b then game.state = State.PLAYING end
        playdate.getCrankChange() -- discard crank movement made while paused
    elseif game.state == State.GAME_OVER then
        if a then enterMenu() end
    end
end

-- Drawing -------------------------------------------------------------------

local titleImage = nil -- loaded at setup; nil falls back to text

-- Text on a black backing box, so it stays readable over the skyline, smoke
-- and moving sprites. align: "center" (x is the center), "left" or "right".
local function label(text, x, y, align)
    local w, h = gfx.getTextSize(text)
    if align == "center" then
        x = x - w / 2
    elseif align == "right" then
        x = x - w
    end
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(x - 4, y - 2, w + 8, h + 4, 3)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(text, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function centered(text, y)
    label(text, Config.SCREEN_WIDTH / 2, y, "center")
end

local MENU_HINTS <const> = {
    "Crank or ✛ moves the net",
    "Catch right of center to throw farther",
    "Two bounces or fewer: Express bonus",
}

-- Two lines under the title, kept above the top of the demo's bounce arcs:
-- a blinking prompt, then one line rotating through the high score (once
-- there is one) and the hints.
local function drawMenu()
    if titleImage then
        local w = titleImage:getSize()
        titleImage:draw((Config.SCREEN_WIDTH - w) / 2, 6)
    else
        centered(Config.TITLE, 24)
    end

    if (game.menuTime % Config.BLINK_PERIOD) < Config.BLINK_PERIOD * 0.7 then
        centered("Press Ⓐ to Start", 66)
    end

    local lines = {}
    if game.highScore > 0 then lines[1] = "High Score: " .. game.highScore end
    for _, hint in ipairs(MENU_HINTS) do lines[#lines + 1] = hint end
    local i = math.floor(game.menuTime / Config.HINT_DURATION) % #lines + 1
    centered(lines[i], 86)

    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:draw()
    end
end

local function drawUI()
    if game.state == State.MENU then
        drawMenu()
        return
    end

    -- Score sits top center, clear of the smoke drifting off the roof (top left).
    label("Score: " .. game.score, Config.SCREEN_WIDTH / 2, 5, "center")
    label("Lives: " .. game.lives, Config.SCREEN_WIDTH - 5, 5, "right")
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    Effects.draw()
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    if game.state == State.PAUSED then
        centered("PAUSED", 90)
        centered("Press Ⓑ to Resume", 115)
    elseif game.state == State.GAME_OVER then
        centered("GAME OVER", 70)
        centered("Final Score: " .. game.score, 95)
        if game.newHighScore then centered("NEW HIGH SCORE!", 120) end
        centered("Press Ⓐ for Menu", 145)
    end
end

-- Main loop -----------------------------------------------------------------

function playdate.update()
    local dt = Physics.clampDt(playdate.getElapsedTime())
    playdate.resetElapsedTime()

    handleInput(dt)

    if game.state == State.PLAYING then
        -- Difficulty speeds up the simulation, not the player's controls.
        local simDt = dt * Rules.timeScale(game.score)
        updateVictims(simDt)
        updateSpawning(simDt)
    elseif game.state == State.MENU then
        game.menuTime = game.menuTime + dt
        updateDemoNet(dt)
        updateVictims(dt)
        updateSpawning(dt)
    end
    if game.state == State.PLAYING or game.state == State.MENU then
        game.net:tick(dt)
        game.ambulance:tick(dt)
    end
    if game.state ~= State.PAUSED then
        Effects.update(dt)
        -- Ambient animation keeps going on the menu and game over screens too.
        game.building:tick(dt)
        if game.smoke then game.smoke:tick(dt) end
    end

    -- Always-redraw: the sprite system clears (to the background color or
    -- background art) and redraws the whole frame, so immediate-mode UI text
    -- never leaves stale pixels.
    gfx.sprite.update()
    drawUI()
    playdate.timer.updateTimers()
end

-- System events: pause when the Playdate menu opens; save before sleep/quit.
function playdate.gameWillPause()
    if game.state == State.PLAYING then game.state = State.PAUSED end
end

function playdate.gameWillTerminate()
    saveHighScore()
end

function playdate.deviceWillSleep()
    saveHighScore()
end

-- One-time setup ------------------------------------------------------------

playdate.display.setRefreshRate(30)
gfx.setBackgroundColor(gfx.kColorBlack)
gfx.sprite.setAlwaysRedraw(true)

backgroundImage = Assets.image("background")

titleImage = Assets.image("title")

math.randomseed(playdate.getSecondsSinceEpoch())
loadHighScore()
Sound.init()
enterMenu()
playdate.resetElapsedTime()
