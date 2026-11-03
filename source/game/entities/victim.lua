import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Victim').extends(gfx.sprite)

local function makePlaceholder()
    local s = Config.VICTIM_SIZE
    local image = gfx.image.new(s, s)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(7, 3, 3)      -- head
        gfx.fillRect(6, 6, 3, 5)            -- body
        gfx.drawLine(2, 5, 12, 5)           -- arms (flailing)
        gfx.drawLine(6, 11, 3, 14)          -- legs
        gfx.drawLine(8, 11, 11, 14)
    gfx.popContext()
    return image
end

-- Victims don't move themselves: main.lua steps `body` with Physics and then
-- calls sync(). (Sprites' own update() is also called by gfx.sprite.update(),
-- so putting movement there would double-step it.)
function Victim:init(x, y, vx, vy)
    Victim.super.init(self)
    self.anim = Assets.anim("victim", Config.VICTIM_FRAME_DURATION, makePlaceholder)
    self.anim:randomizePhase()
    self.anim:apply(self)
    self:setZIndex(Config.Z_VICTIM)
    self.body = { x = x, y = y, vx = vx, vy = vy, bounces = 0 }
    self:sync()
    self:add()
end

function Victim:tick(dt)
    self.anim:advance(dt)
    self.anim:apply(self)
end

function Victim:sync()
    self:moveTo(self.body.x, self.body.y)
end
