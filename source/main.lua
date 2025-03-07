import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "game/entities/firefighters"
import "game/entities/building"
import "game/entities/ambulance"

-- Shortcuts for common functions
local gfx <const> = playdate.graphics
local display <const> = playdate.display

-- Game state
local gameState = {
    score = 0,
    lives = 3,
    isPlaying = false,
    firefighters = nil,
    building = nil,
    ambulance = nil
}

-- Initialize game
function initGame()
    -- Clear the display
    gfx.clear()
    
    -- Set up initial game state
    gameState.score = 0
    gameState.lives = 3
    gameState.isPlaying = true
    
    -- Set background color
    gfx.setBackgroundColor(gfx.kColorBlack)
    
    -- Create game entities
    gameState.building = Building()
    gameState.firefighters = Firefighters()
    gameState.ambulance = Ambulance()
end

-- Update game state
function playdate.update()
    -- Firefighters will handle their own crank input and updates
    
    -- Update sprites
    gfx.sprite.update()
    
    -- Update timers
    playdate.timer.updateTimers()
    
    -- Draw score
    gfx.drawText("Score: " .. gameState.score, 5, 5)
    gfx.drawText("Lives: " .. gameState.lives, 300, 5)
end

-- Initialize the game when the file loads
initGame()
