import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "game/entities/firefighters"
import "game/entities/building"
import "game/entities/ambulance"
import "game/entities/victim"

-- Shortcuts for common functions
local gfx <const> = playdate.graphics
local display <const> = playdate.display

-- Game states enum
local GameState = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "gameOver"
}

-- Game configuration
local Config = {
    FPS = 30,
    PHYSICS_STEP = 1/30,
    MAX_VICTIMS = 5,
    VICTIM_SPAWN_INTERVAL = 3
}

-- Game state
local gameState = {
    currentState = GameState.MENU,
    score = 0,
    lives = 3,
    highScore = 0,
    timeSinceLastSpawn = 0,
    activeVictims = {},
    entities = {
        firefighters = nil,
        building = nil,
        ambulance = nil
    },
    observers = {}
}

-- Observer pattern implementation
local function addObserver(event, callback)
    if not gameState.observers[event] then
        gameState.observers[event] = {}
    end
    table.insert(gameState.observers[event], callback)
end

local function notifyObservers(event, data)
    if gameState.observers[event] then
        for _, callback in ipairs(gameState.observers[event]) do
            callback(data)
        end
    end
end

-- Physics system
local physics = {
    gravity = 200,  -- pixels per second squared
    lastUpdate = playdate.getCurrentTimeMilliseconds()
}

local function updatePhysics(dt)
    -- Update physics for active victims
    for i = #gameState.activeVictims, 1, -1 do
        local victim = gameState.activeVictims[i]
        
        if victim:isActive() then
            -- Apply gravity
            local vx, vy = victim:getVelocity()
            victim:setVelocity(vx, vy + physics.gravity * dt)
            
            -- Update victim's internal position
            if victim.update then
                victim:update()
            end
            
            -- Get updated position
            local victimX, victimY = victim:getPosition()
            local victimBounds = victim:getBounds()
            
            -- Check for collision with firefighters
            if gameState.entities.firefighters:canCatch(victimX, victimY) then
                -- Bounce the victim
                local _, vy = victim:getVelocity()
                victim:setVelocity(50, -math.abs(vy))  -- Bounce towards ambulance
                victim:bounce()
            end
            
            -- Check for rescue by ambulance
            if gameState.entities.ambulance:isInRescueZone(victimX, victimY) then
                victim:rescue()
                gameState.entities.ambulance:onRescue()
                table.remove(gameState.activeVictims, i)
            end
            
            -- Remove inactive victims from the array
            if not victim:isActive() then
                table.remove(gameState.activeVictims, i)
            end
        end
    end
end

-- Initialize game
local function initGame()
    -- Clear the display
    gfx.clear()
    
    -- Reset game state
    gameState.currentState = GameState.PLAYING
    gameState.score = 0
    gameState.lives = 3
    gameState.timeSinceLastSpawn = 0
    gameState.activeVictims = {}
    
    -- Set background color
    gfx.setBackgroundColor(gfx.kColorBlack)
    
    -- Create game entities
    gameState.entities.building = Building()
    gameState.entities.firefighters = Firefighters(notifyObservers)
    gameState.entities.ambulance = Ambulance(notifyObservers)
    
    -- Set up observers
    addObserver("victimRescued", function(data)
        gameState.score = gameState.score + 100
        if gameState.score > gameState.highScore then
            gameState.highScore = gameState.score
            notifyObservers("newHighScore", gameState.highScore)
        end
    end)
    
    addObserver("victimLost", function()
        gameState.lives = gameState.lives - 1
        if gameState.lives <= 0 then
            gameState.currentState = GameState.GAME_OVER
            notifyObservers("gameOver", gameState.score)
        end
    end)
end

-- Input handling
local function handleInput()
    -- Handle menu navigation
    if gameState.currentState == GameState.MENU then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            initGame()
        end
    end
    
    -- Handle pause toggle
    if playdate.buttonJustPressed(playdate.kButtonB) then
        if gameState.currentState == GameState.PLAYING then
            gameState.currentState = GameState.PAUSED
        elseif gameState.currentState == GameState.PAUSED then
            gameState.currentState = GameState.PLAYING
        end
    end
    
    -- Handle game over state
    if gameState.currentState == GameState.GAME_OVER then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState.currentState = GameState.MENU
        end
    end
    
    -- Handle in-game input
    if gameState.currentState == GameState.PLAYING then
        -- Crank input is handled by Firefighters entity
        gameState.entities.firefighters:updatePosition()
    end
end

-- Main update function
function playdate.update()
    -- Clear the screen and set to black background
    gfx.clear()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite) -- Set to white for sprites and text
    
    -- Calculate delta time
    local currentTime = playdate.getCurrentTimeMilliseconds()
    local dt = (currentTime - physics.lastUpdate) / 1000.0
    physics.lastUpdate = currentTime
    
    -- Handle input
    handleInput()
    
    -- Update game logic based on state
    if gameState.currentState == GameState.PLAYING then
        -- Update physics
        updatePhysics(dt)
        
        -- Update game entities
        for _, entity in pairs(gameState.entities) do
            if entity.update then
                entity:update(dt)
            end
        end
        
        -- Update victim spawning
        gameState.timeSinceLastSpawn = gameState.timeSinceLastSpawn + dt
        if gameState.timeSinceLastSpawn >= Config.VICTIM_SPAWN_INTERVAL and
           #gameState.activeVictims < Config.MAX_VICTIMS then
            -- Spawn new victim
            local spawnX, spawnY = gameState.entities.building:getRandomSpawnPoint()
            -- Create new victim with reference to notifyObservers
            local newVictim = Victim(spawnX, spawnY, 50, 0, notifyObservers)  -- Initial velocity towards right
            table.insert(gameState.activeVictims, newVictim)
            gameState.timeSinceLastSpawn = 0
        end
    end
    
    -- Update sprites (this draws all game entities)
    gfx.sprite.update()
    
    -- Update timers
    playdate.timer.updateTimers()
    
    -- Draw UI overlay
    if gameState.currentState == GameState.MENU then
        gfx.drawText("FIRE", 180, 100)
        gfx.drawText("Press Ⓐ to Start", 150, 120)
        gfx.drawText("High Score: " .. gameState.highScore, 150, 140)
    elseif gameState.currentState == GameState.PLAYING then
        gfx.drawText("Score: " .. gameState.score, 5, 5)
        gfx.drawText("Lives: " .. gameState.lives, 300, 5)
    elseif gameState.currentState == GameState.PAUSED then
        gfx.drawText("PAUSED", 170, 110)
        gfx.drawText("Press Ⓑ to Resume", 140, 130)
    elseif gameState.currentState == GameState.GAME_OVER then
        gfx.drawText("GAME OVER", 160, 100)
        gfx.drawText("Final Score: " .. gameState.score, 150, 120)
        gfx.drawText("Press Ⓐ for Menu", 145, 140)
    end
end

-- Set up menu state when the game first loads
gameState.currentState = GameState.MENU
