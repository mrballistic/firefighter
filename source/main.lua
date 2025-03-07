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
    VICTIM_SPAWN_INTERVAL = 3,
    SCORE_PER_RESCUE = 100,  -- Score per successful rescue
    VICTIMS_INCREASE_THRESHOLD = 500,  -- Score needed to allow 2 victims
    INITIAL_HORIZONTAL_VELOCITY = 100  -- Initial push from building
}

-- Get maximum allowed victims based on score
local function getMaxVictims(score)
    if score < Config.VICTIMS_INCREASE_THRESHOLD then
        return 1  -- Start with one victim
    else
        return 2  -- Allow two victims after threshold
    end
end

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
            local catchInfo = gameState.entities.firefighters:canCatch(victimX, victimY)
            if catchInfo then
                -- Get current velocities
                local vx, vy = victim:getVelocity()
                
                -- Calculate bounce velocities based on hit position
                local MIN_BOUNCE_VELOCITY <const> = 200  -- Minimum velocity to reach ambulance
                local HORIZONTAL_BOOST <const> = 30      -- Base horizontal boost
                local EDGE_BOOST <const> = 40           -- Additional boost when hitting edges
                
                -- Calculate hit position relative to center (-1 to 1, where 0 is center)
                local hitPosition = catchInfo.hitPosition
                
                -- More horizontal velocity when hitting edges
                local edgeBoost = math.abs(hitPosition) * EDGE_BOOST
                local newVx = math.max(vx * 0.5, 0) + HORIZONTAL_BOOST + edgeBoost
                
                -- Ensure minimum upward velocity while preserving some momentum
                local newVy = -math.max(math.abs(vy), MIN_BOUNCE_VELOCITY)
                
                -- Apply new velocities
                victim:setVelocity(newVx, newVy)
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
    -- Clear all sprites
    gfx.sprite.removeAll()
    
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
        gameState.score = gameState.score + Config.SCORE_PER_RESCUE
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
        -- Force immediate spawn of new victim after death
        gameState.timeSinceLastSpawn = Config.VICTIM_SPAWN_INTERVAL * 2
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
            -- Clear all sprites when returning to menu
            gfx.sprite.removeAll()
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
        local maxVictims = getMaxVictims(gameState.score)
        
        -- Only spawn if we're below max victims and enough time has passed
        if gameState.timeSinceLastSpawn >= Config.VICTIM_SPAWN_INTERVAL and
           #gameState.activeVictims < maxVictims and
           gameState.lives > 0 then  -- Only spawn if we have lives left
            
            -- Spawn new victim when none are active (after rescue or death)
            if #gameState.activeVictims == 0 then
                -- Reset spawn timer and create new victim
                gameState.timeSinceLastSpawn = 0
                local spawnX, spawnY = gameState.entities.building:getRandomSpawnPoint()
                local newVictim = Victim(spawnX, spawnY, Config.INITIAL_HORIZONTAL_VELOCITY, 0, notifyObservers)
                table.insert(gameState.activeVictims, newVictim)
            -- For second victim (if allowed by score)
            elseif maxVictims > 1 and #gameState.activeVictims == 1 then
                -- Spawn additional victim
                local spawnX, spawnY = gameState.entities.building:getRandomSpawnPoint()
                local newVictim = Victim(spawnX, spawnY, Config.INITIAL_HORIZONTAL_VELOCITY, 0, notifyObservers)
                table.insert(gameState.activeVictims, newVictim)
                gameState.timeSinceLastSpawn = 0
            end
        end
    end
    
    -- Update sprites (this draws all game entities)
    gfx.sprite.update()
    
    -- Update timers
    playdate.timer.updateTimers()
    
    -- Draw UI overlay
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)  -- Ensure text is white
    
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
    
    gfx.setImageDrawMode(gfx.kDrawModeCopy)  -- Reset draw mode
end

-- Set up menu state when the game first loads
gameState.currentState = GameState.MENU
