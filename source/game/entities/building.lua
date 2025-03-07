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
        -- Main building structure
        gfx.fillRect(0, 0, BUILDING_WIDTH, BUILDING_HEIGHT)
        
        -- Windows (spawn points)
        for i = 1, WINDOW_COUNT do
            local windowY = (i * (BUILDING_HEIGHT/(WINDOW_COUNT + 1))) - (WINDOW_SIZE/2)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(5, windowY, WINDOW_SIZE, WINDOW_SIZE)
            gfx.setColor(gfx.kColorBlack)
        end
    gfx.popContext()
    
    -- Initialize sprite with the image
    self:setImage(image)
    
    -- Position the building
    self:moveTo(BUILDING_X, BUILDING_HEIGHT/2)
    
    -- Store window positions for spawning
    self.windowPositions = {}
    for i = 1, WINDOW_COUNT do
        local windowY = (i * (BUILDING_HEIGHT/(WINDOW_COUNT + 1)))
        table.insert(self.windowPositions, {
            x = BUILDING_X + WINDOW_SIZE/2,
            y = windowY
        })
    end
    
    -- Add to display list
    self:add()
end

-- Get a random window position for spawning victims
function Building:getRandomSpawnPoint()
    local windowIndex = math.random(1, #self.windowPositions)
    return self.windowPositions[windowIndex].x, self.windowPositions[windowIndex].y
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
