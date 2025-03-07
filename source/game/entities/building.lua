import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Building').extends(gfx.sprite)

-- Constants for building dimensions
local BUILDING_WIDTH <const> = 40
local BUILDING_HEIGHT <const> = 180
local WINDOW_SIZE <const> = 20
local WINDOW_COUNT <const> = 6
local BUILDING_X <const> = 30  -- Position from left edge

function Building:init()
    -- Create building image
    local image = gfx.image.new(BUILDING_WIDTH, BUILDING_HEIGHT)
    
    -- Draw the building
    gfx.pushContext(image)
        -- Set color to white for the building
        gfx.setColor(gfx.kColorWhite)
        
        -- Main building structure
        gfx.fillRect(0, 0, BUILDING_WIDTH, BUILDING_HEIGHT)
        
        -- Windows (spawn points)
        for i = 1, WINDOW_COUNT do
            local windowY = (i * (BUILDING_HEIGHT/(WINDOW_COUNT + 1))) - (WINDOW_SIZE/2)
            gfx.setColor(gfx.kColorBlack)  -- Windows are black
            gfx.fillRect(5, windowY, WINDOW_SIZE, WINDOW_SIZE)
            gfx.setColor(gfx.kColorWhite)  -- Back to white for next building part
        end
    gfx.popContext()
    
    -- Initialize sprite with the image
    self:setImage(image)
    
    -- Position the building (offset from top to show full height)
    self:moveTo(BUILDING_X, 160)  -- Position lower on screen to leave room for score
    
    -- Store window positions for spawning
    self.windowPositions = {}
    for i = 1, WINDOW_COUNT do
        -- Adjust window positions relative to building position
        local windowY = (i * (BUILDING_HEIGHT/(WINDOW_COUNT + 1)))
        table.insert(self.windowPositions, {
            x = BUILDING_X + WINDOW_SIZE/2,
            y = self.y - BUILDING_HEIGHT/2 + windowY  -- Relative to building's center
        })
    end
    
    -- Add to display list
    self:add()
end

-- Victim spawning configuration
local SPAWN_VELOCITY_X <const> = 50  -- Initial horizontal velocity
local SPAWN_VELOCITY_Y <const> = 0   -- Initial vertical velocity
local MIN_SPAWN_INTERVAL <const> = 2  -- Minimum time between spawns
local MAX_SPAWN_INTERVAL <const> = 5  -- Maximum time between spawns

function Building:update(dt)
    -- Base update for sprite
    Building.super.update(self)
end

-- Get a random window position for spawning victims
function Building:getRandomSpawnPoint()
    local windowIndex = math.random(1, #self.windowPositions)
    return self.windowPositions[windowIndex].x, self.windowPositions[windowIndex].y
end

-- Spawn a new victim
function Building:spawnVictim()
    local spawnX, spawnY = self:getRandomSpawnPoint()
    
    -- Create victim data
    local victim = {
        active = true,
        position = { x = spawnX, y = spawnY },
        velocity = { 
            x = SPAWN_VELOCITY_X,
            y = SPAWN_VELOCITY_Y
        },
        size = { width = 15, height = 15 }  -- Adjust size as needed
    }
    
    -- Notify observers of new victim
    playdate.eventEmitter:emit("victimSpawned", victim)
    
    return victim
end

-- Get building boundaries
function Building:getBoundaries()
    return {
        left = self.x - BUILDING_WIDTH/2,
        right = self.x + BUILDING_WIDTH/2,
        top = self.y - BUILDING_HEIGHT/2,
        bottom = self.y + BUILDING_HEIGHT/2
    }
end

-- Get window positions (for debugging or UI purposes)
function Building:getWindowPositions()
    return self.windowPositions
end
