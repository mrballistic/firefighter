import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Firefighters').extends(gfx.sprite)

-- Image is 20px tall; the net's top surface is at local y = 10, which is the
-- sprite's centre, so moveTo(x, NET_Y) puts the net surface exactly on NET_Y.
local IMAGE_HEIGHT <const> = 20

local function makePlaceholder()
    local w = Config.NET_WIDTH
    local image = gfx.image.new(w, IMAGE_HEIGHT)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        -- Two firefighters holding the net at each end
        gfx.fillRect(0, 2, 5, 16)
        gfx.fillRect(w - 5, 2, 5, 16)
        -- Net
        gfx.fillRect(0, 10, w, 4)
        -- Aim marks: centre notch and quarter ticks, so hit position is readable
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(w / 2 - 1, 10, 2, 4)
        gfx.fillRect(w / 4, 12, 1, 2)
        gfx.fillRect(3 * w / 4, 12, 1, 2)
    gfx.popContext()
    return image
end

function Firefighters:init()
    Firefighters.super.init(self)
    -- Walk cycle: frames advance per pixel moved (not per second), so their
    -- steps match the crank. Frame 1 is the standing pose.
    self.anim = Assets.anim("firefighters", Config.FIREFIGHTER_STRIDE, makePlaceholder)
    self.anim:apply(self)
    self.moved = false
    self.dipTime = 0
    self:setZIndex(Config.Z_NET)
    self:moveTo((Config.NET_MIN_X + Config.NET_MAX_X) / 2, Config.NET_Y)
    self:add()
end

-- Crank is the primary control; the D-pad is a fallback (handy in the simulator).
function Firefighters:updatePosition(dt)
    local dx = playdate.getCrankChange() * Config.CRANK_SENSITIVITY
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = dx - Config.DPAD_SPEED * dt
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = dx + Config.DPAD_SPEED * dt
    end
    self:moveBy(dx)
end

-- Menu demo: walk toward targetX at a human-ish speed.
function Firefighters:steer(targetX, dt)
    local maxStep = Config.DEMO_NET_SPEED * dt
    self:moveBy(math.max(-maxStep, math.min(maxStep, targetX - self.x)))
end

function Firefighters:moveBy(dx)
    self.moved = false
    if dx ~= 0 then
        local x = math.max(Config.NET_MIN_X, math.min(Config.NET_MAX_X, self.x + dx))
        if x ~= self.x then
            self.anim:advance(math.abs(x - self.x))
            self.moved = true
        end
        self:moveTo(x, self.y)
    end
end

-- Visual only: the net sags briefly on a catch. Physics always uses NET_Y.
function Firefighters:dip()
    self.dipTime = Config.NET_DIP_DURATION
    self:moveTo(self.x, Config.NET_Y + Config.NET_DIP)
end

function Firefighters:tick(dt)
    if not self.moved then self.anim:reset() end -- stand still when not moving
    self.anim:apply(self)
    if self.dipTime > 0 then
        self.dipTime = self.dipTime - dt
        if self.dipTime <= 0 then self:moveTo(self.x, Config.NET_Y) end
    end
end
