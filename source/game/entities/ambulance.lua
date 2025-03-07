import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Ambulance').extends(gfx.sprite)

-- Constants for ambulance dimensions
local AMBULANCE_WIDTH <const> = 40
local AMBULANCE_HEIGHT <const> = 30
local AMBULANCE_X <const> = 370  -- Position from left edge
local AMBULANCE_Y <const> = 210  -- Position from top

function Ambulance:init()
    -- Create ambulance image
    local image = gfx.image.new(AMBULANCE_WIDTH, AMBULANCE_HEIGHT)
    
    -- Draw the ambulance (simple placeholder graphics)
    gfx.pushContext(image)
        -- Main body
        gfx.fillRect(0, 10, AMBULANCE_WIDTH, AMBULANCE_HEIGHT - 10)
        -- Cab
        gfx.fillRect(5, 0, 20, 15)
        -- Cross symbol
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(25, 15, 10, 10)
        gfx.setColor(gfx.kColorBlack)
    gfx.popContext()
    
    -- Initialize sprite with the image
    self:setImage(image)
    
    -- Position the ambulance
    self:moveTo(AMBULANCE_X, AMBULANCE_Y)
    
    -- Add to display list
    self:add()
end

-- Check if a point is within the ambulance's catch zone
function Ambulance:isInSafeZone(x, y)
    local bounds = self:getBounds()
    return x >= bounds.left and x <= bounds.right and
           y >= bounds.top and y <= bounds.bottom
end

-- Get ambulance position
function Ambulance:getPosition()
    return self.x, self.y
end

-- Get ambulance boundaries
function Ambulance:getBounds()
    return {
        left = self.x - AMBULANCE_WIDTH/2,
        right = self.x + AMBULANCE_WIDTH/2,
        top = self.y - AMBULANCE_HEIGHT/2,
        bottom = self.y + AMBULANCE_HEIGHT/2
    }
end
