import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Firefighters').extends(gfx.sprite)

-- Constants for movement
local SCREEN_WIDTH <const> = 400
local MIN_X <const> = 50  -- Left boundary (near building)
local MAX_X <const> = 350 -- Right boundary (near ambulance)
local Y_POSITION <const> = 220 -- Vertical position of firefighters (near bottom of building)

function Firefighters:init(notifyObserversFn)
    -- Store the notifyObservers function
    self.notifyObservers = notifyObserversFn
    -- Create a temporary placeholder image for the firefighters
    local firefighterWidth = 40
    local firefighterHeight = 20
    local image = gfx.image.new(firefighterWidth, firefighterHeight)
    
    -- Draw the placeholder sprite
    gfx.pushContext(image)
        -- Set color to white for all elements
        gfx.setColor(gfx.kColorWhite)
        
        -- Draw the net (trampoline)
        gfx.fillRect(0, firefighterHeight/2, firefighterWidth, firefighterHeight/2)
        -- Draw the firefighters (two figures)
        gfx.fillRect(5, 0, 10, firefighterHeight/2)  -- Left firefighter
        gfx.fillRect(firefighterWidth-15, 0, 10, firefighterHeight/2)  -- Right firefighter
    gfx.popContext()
    
    -- Initialize the sprite with the image
    self:setImage(image)
    
    -- Set initial position
    self:moveTo(SCREEN_WIDTH/2, Y_POSITION)
    
    -- Add to display list
    self:add()
end

-- Movement configuration
local CRANK_SENSITIVITY <const> = 2.0
local MOVEMENT_SPEED <const> = 200 -- pixels per second

function Firefighters:update(dt)
    -- Base update for sprite
    Firefighters.super.update(self)
end

-- Handle crank-based position updates
function Firefighters:updatePosition()
    -- Get crank change for movement
    local change = playdate.getCrankChange()
    
    -- Update position based on crank movement
    if change ~= 0 then
        local newX = self.x + (change * CRANK_SENSITIVITY)
        -- Clamp position within boundaries
        newX = math.max(MIN_X, math.min(MAX_X, newX))
        self:moveTo(newX, self.y)
    end
end

-- Get the current position of the firefighters
function Firefighters:getPosition()
    return self.x, self.y
end

-- Check if a point is within the catching range
function Firefighters:canCatch(x, y)
    -- Simple rectangle collision check
    local width = self:getSize()
    local catchWidth = width * 0.8 -- Slightly smaller than visual width for better gameplay
    local catchHeight = 20 -- Vertical catching range
    
    -- Check if point is within catch area
    local inRange = math.abs(x - self.x) < catchWidth/2 and 
                   math.abs(y - self.y) < catchHeight/2
    
    -- If in range, notify observers of potential catch
    if inRange then
        -- The actual catch handling will be managed by the physics system
        -- This just indicates the firefighters are in position to catch
        -- Using our observer pattern instead of eventEmitter
        self.notifyObservers("catchAttempt", {
            x = self.x,
            y = self.y,
            width = catchWidth,
            height = catchHeight
        })
    end
    
    return inRange
end

-- Handle successful catch
function Firefighters:onCatch()
    -- Could add animation or visual feedback here
    self.notifyObservers("victimCaught")
end
