import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Victim').extends(gfx.sprite)

-- Constants for victim
local VICTIM_SIZE <const> = 15
local BOUNCE_DAMPING <const> = 0.8  -- Increased to preserve more momentum
local HORIZONTAL_DAMPING <const> = 0.95  -- Slightly increased air resistance

function Victim:init(x, y, velocityX, velocityY, notifyObserversFn)
    Victim.super.init(self)
    
    -- Create victim image
    local image = gfx.image.new(VICTIM_SIZE, VICTIM_SIZE)
    
    -- Draw the victim (simple placeholder graphics)
    gfx.pushContext(image)
        -- Set color to white for the victim
        gfx.setColor(gfx.kColorWhite)
        -- Circle shape for victim
        gfx.fillCircleAtPoint(VICTIM_SIZE/2, VICTIM_SIZE/2, VICTIM_SIZE/2 - 1)
    gfx.popContext()
    
    -- Initialize sprite with the image
    self:setImage(image)
    
    -- Set initial position and velocity
    self:moveTo(x, y)
    self.velocity = {
        x = velocityX or 0,
        y = velocityY or 0
    }
    
    -- State tracking
    self.active = true
    self.rescued = false
    self.lost = false
    
    -- Add to display list
    self:add()
    
    -- Store the notifyObservers function
    self.notifyObservers = notifyObserversFn
end

function Victim:update()
    -- Call parent update first
    Victim.super.update(self)
    
    if not self.active then
        return
    end
    
    -- Get delta time from playdate
    local dt = 1/playdate.display.getRefreshRate()
    
    -- Update position based on velocity
    local newX = self.x + (self.velocity.x * dt)
    local newY = self.y + (self.velocity.y * dt)
    
    -- Apply horizontal damping
    self.velocity.x = self.velocity.x * HORIZONTAL_DAMPING
    
    -- Check boundaries
    if newY > 240 then  -- Bottom boundary
        -- Victim has fallen off screen
        self:onLost()
        return
    elseif newY < 0 then  -- Top boundary
        -- Clamp to top and reverse velocity
        newY = 0
        self.velocity.y = math.abs(self.velocity.y) * 0.5  -- Bounce down with reduced velocity
    end
    
    -- Update position
    self:moveTo(newX, newY)
end

function Victim:bounce()
    -- Apply bounce damping to both velocities
    self.velocity.x = self.velocity.x * BOUNCE_DAMPING
    self.velocity.y = self.velocity.y * BOUNCE_DAMPING
    
    -- Strong right bias and minimum speed
    local MIN_HORIZONTAL_SPEED <const> = 50
    local RIGHT_BIAS <const> = 30
    
    -- Add right bias and ensure minimum speed
    self.velocity.x = math.max(self.velocity.x + RIGHT_BIAS, MIN_HORIZONTAL_SPEED)
end

function Victim:rescue()
    if not self.rescued and self.active then
        self.rescued = true
        self.active = false
        self.notifyObservers("victimRescued")
        self:remove()  -- Remove from display list
    end
end

function Victim:onLost()
    if not self.lost and self.active then
        self.lost = true
        self.active = false
        self.notifyObservers("victimLost")
        self:remove()  -- Remove from display list
    end
end

function Victim:getPosition()
    return self.x, self.y
end

function Victim:getVelocity()
    return self.velocity.x, self.velocity.y
end

function Victim:setVelocity(x, y)
    self.velocity.x = x
    self.velocity.y = y
end

function Victim:isActive()
    return self.active
end

function Victim:getBounds()
    return {
        left = self.x - VICTIM_SIZE/2,
        right = self.x + VICTIM_SIZE/2,
        top = self.y - VICTIM_SIZE/2,
        bottom = self.y + VICTIM_SIZE/2,
        width = VICTIM_SIZE,
        height = VICTIM_SIZE
    }
end
