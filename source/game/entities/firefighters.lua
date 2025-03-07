import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Firefighters').extends(gfx.sprite)

-- Constants for movement
local SCREEN_WIDTH <const> = 400
local MIN_X <const> = 50  -- Left boundary (near building)
local MAX_X <const> = 350 -- Right boundary (near ambulance)
local Y_POSITION <const> = 200 -- Vertical position of firefighters

function Firefighters:init()
    -- Create a temporary placeholder image for the firefighters
    local firefighterWidth = 40
    local firefighterHeight = 20
    local image = gfx.image.new(firefighterWidth, firefighterHeight)
    
    -- Draw the placeholder sprite
    gfx.pushContext(image)
        gfx.fillRect(0, 0, firefighterWidth, firefighterHeight)
    gfx.popContext()
    
    -- Initialize the sprite with the image
    self:setImage(image)
    
    -- Set initial position
    self:moveTo(SCREEN_WIDTH/2, Y_POSITION)
    
    -- Add to display list
    self:add()
end

function Firefighters:update()
    -- Get crank change for movement
    local change = playdate.getCrankChange()
    
    -- Update position based on crank movement
    if change ~= 0 then
        local newX = self.x + (change * 2) -- Adjust multiplier for desired sensitivity
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
    return math.abs(x - self.x) < width/2 and math.abs(y - self.y) < 10
end
