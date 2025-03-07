import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Ambulance').extends(gfx.sprite)

-- Constants for ambulance dimensions
local AMBULANCE_WIDTH <const> = 40
local AMBULANCE_HEIGHT <const> = 30
local AMBULANCE_X <const> = 370  -- Position from left edge
local AMBULANCE_Y <const> = 220  -- Position from top (aligned with firefighters)

-- Animation configuration
local FLASH_DURATION <const> = 0.2
local RESCUE_ZONE_HEIGHT <const> = 40  -- Extends above the ambulance

function Ambulance:init(notifyObserversFn)
    -- Store the notifyObservers function
    self.notifyObservers = notifyObserversFn
    Ambulance.super.init(self)
    
    -- Create ambulance image
    local image = gfx.image.new(AMBULANCE_WIDTH, AMBULANCE_HEIGHT)
    
    -- Draw the ambulance (simple placeholder graphics)
    gfx.pushContext(image)
        -- Set color to white for the ambulance
        gfx.setColor(gfx.kColorWhite)
        
        -- Main body
        gfx.fillRect(0, 10, AMBULANCE_WIDTH, AMBULANCE_HEIGHT - 10)
        -- Cab
        gfx.fillRect(5, 0, 20, 15)
        -- Cross symbol (black on white)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(25, 15, 10, 10)
    gfx.popContext()
    
    -- Initialize sprite with the image
    self:setImage(image)
    
    -- Position the ambulance
    self:moveTo(AMBULANCE_X, AMBULANCE_Y)
    
    -- Add to display list
    self:add()
    
    -- Initialize flash state
    self.isFlashing = false
    self.flashTimer = 0
end

function Ambulance:update(dt)
    -- Base update for sprite
    Ambulance.super.update(self)
    
    -- Update flash effect
    if self.isFlashing then
        self.flashTimer = self.flashTimer - dt
        if self.flashTimer <= 0 then
            self.isFlashing = false
            self:setImage(self.originalImage)
        end
    end
end

-- Check if a point is within the ambulance's rescue zone
function Ambulance:isInRescueZone(x, y)
    local bounds = self:getBounds()
    return x >= bounds.left and x <= bounds.right and
           y >= bounds.top - RESCUE_ZONE_HEIGHT and y <= bounds.bottom
end

-- Handle successful rescue
function Ambulance:onRescue()
    -- Store original image if not already stored
    if not self.originalImage then
        self.originalImage = self:getImage()
    end
    
    -- Create flash effect
    local flashImage = gfx.image.new(AMBULANCE_WIDTH, AMBULANCE_HEIGHT)
    gfx.pushContext(flashImage)
        gfx.fillRect(0, 0, AMBULANCE_WIDTH, AMBULANCE_HEIGHT)
    gfx.popContext()
    
    -- Apply flash effect
    self:setImage(flashImage)
    self.isFlashing = true
    self.flashTimer = FLASH_DURATION
    
    -- Notify observers
    self.notifyObservers("victimRescued")
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

-- Get rescue zone boundaries (for debugging or UI purposes)
function Ambulance:getRescueZoneBounds()
    local bounds = self:getBounds()
    bounds.top = bounds.top - RESCUE_ZONE_HEIGHT
    return bounds
end
