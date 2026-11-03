import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Ambulance').extends(gfx.sprite)

local function makePlaceholder()
    local w, h = Config.AMBULANCE_WIDTH, Config.AMBULANCE_HEIGHT
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 10, w, h - 10)  -- body
        gfx.fillRect(w - 15, 2, 15, 10) -- cab (facing away from the building)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(12, 14, 10, 4)     -- cross
        gfx.fillRect(15, 11, 4, 10)
    gfx.popContext()
    return image
end

function Ambulance:init()
    Ambulance.super.init(self)

    self.normalImage = Assets.image("ambulance", makePlaceholder)
    self.flashImage = Assets.image("ambulance-flash", function()
        return self.normalImage:invertedImage()
    end)

    self.flashTimer = 0
    self:setZIndex(Config.Z_AMBULANCE)
    self:setImage(self.normalImage)
    self:moveTo(Config.AMBULANCE_X, Config.AMBULANCE_Y)
    self:add()
end

function Ambulance:flash()
    self.flashTimer = Config.FLASH_DURATION
    self:setImage(self.flashImage)
end

-- Called by main.lua with dt. (Not named update(): gfx.sprite.update() calls
-- update() with no arguments.)
function Ambulance:tick(dt)
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
        if self.flashTimer <= 0 then
            self:setImage(self.normalImage)
        end
    end
end
