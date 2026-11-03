import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

class('Firefighters').extends(gfx.sprite)

-- Image is 20px tall; the net's top surface is at local y = 10, which is the
-- sprite's center, so moveTo(x, NET_Y) puts the net surface exactly on NET_Y.
local IMAGE_HEIGHT <const> = 20
-- Each firefighter (with their end of the net) is this many columns at either
-- edge of the art; everything between is net, redrawn at the current width.
local END_WIDTH <const> = 5

local function makePlaceholder()
    local w = Config.NET_WIDTH
    local image = gfx.image.new(w, IMAGE_HEIGHT)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        -- Two firefighters holding the net at each end
        gfx.fillRect(0, 2, END_WIDTH, 16)
        gfx.fillRect(w - END_WIDTH, 2, END_WIDTH, 16)
        gfx.fillRect(0, 10, w, 4)
    gfx.popContext()
    return image
end

-- The net between the firefighters at width w: top rope (row 10), a
-- checkered mesh (rows 11-12), bottom rope (row 13), and aim marks under it
-- (a 3-row center notch, single-row quarter ticks) at the same proportional
-- spots as the art. Then the firefighters, copied from the source frame.
local function composeNet(source, w)
    local srcW = source:getSize()
    local img = gfx.image.new(w, IMAGE_HEIGHT)
    gfx.pushContext(img)
        gfx.setColor(gfx.kColorWhite)
        local left, right = END_WIDTH, w - END_WIDTH
        gfx.fillRect(left, 10, right - left, 1)
        for x = left, right - 1 do
            if x % 2 == 1 then gfx.fillRect(x, 11, 1, 1) else gfx.fillRect(x, 12, 1, 1) end
        end
        gfx.fillRect(left, 13, right - left, 1)
        gfx.fillRect(w / 2 - 2, 14, 2, 3)
        gfx.fillRect(w / 4 - 1, 14, 1, 1)
        gfx.fillRect(3 * w / 4 - 1, 14, 1, 1)
        source:draw(0, 0, gfx.kImageUnflipped, geo.rect.new(0, 0, END_WIDTH, IMAGE_HEIGHT))
        source:draw(w - END_WIDTH, 0, gfx.kImageUnflipped,
            geo.rect.new(srcW - END_WIDTH, 0, END_WIDTH, IMAGE_HEIGHT))
    gfx.popContext()
    return img
end

function Firefighters:init(width)
    Firefighters.super.init(self)
    -- Walk cycle: frames advance per pixel moved (not per second), so their
    -- steps match the crank. Frame 1 is the standing pose.
    self.anim = Assets.anim("firefighters", Config.FIREFIGHTER_STRIDE, makePlaceholder)
    self.images = {}  -- [width][frame] -> composed image, built on first use
    -- Not `self.width`: Playdate sprites already have a read-only width
    -- (their image's), and writes to it are silently ignored.
    self.netWidth = width or Config.NET_WIDTH
    self.targetWidth = self.netWidth
    self.half = self.netWidth / 2
    self.moved = false
    self.dipTime = 0
    self:setZIndex(Config.Z_NET)
    local minX, maxX = Physics.netRange(self.half)
    self:moveTo((minX + maxX) / 2, Config.NET_Y)
    self:refreshImage()
    self:add()
end

function Firefighters:refreshImage()
    local frame = self.anim:frameIndex()
    local byWidth = self.images[self.netWidth]
    if not byWidth then
        byWidth = {}
        self.images[self.netWidth] = byWidth
    end
    local img = byWidth[frame]
    if not img then
        local source = self.anim:isAnimated() and self.anim.frames:getImage(frame) or self.anim.still
        img = composeNet(source, self.netWidth)
        byWidth[frame] = img
    end
    if self:getImage() ~= img then self:setImage(img) end
end

-- The net narrows toward this width over the next few frames (see tick).
function Firefighters:setTargetWidth(w)
    self.targetWidth = w
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
        local minX, maxX = Physics.netRange(self.half)
        local x = math.max(minX, math.min(maxX, self.x + dx))
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

    -- Narrow (or widen) 2 px at a time toward the target, keeping the width
    -- even so the net stays symmetric. Physics reads self.half every frame,
    -- so the catch area always matches what's drawn.
    if self.netWidth ~= self.targetWidth then
        self.resizeClock = (self.resizeClock or 0) + dt * Config.NET_RESIZE_SPEED
        while self.resizeClock >= 2 and self.netWidth ~= self.targetWidth do
            self.resizeClock = self.resizeClock - 2
            self.netWidth = self.netWidth + ((self.targetWidth > self.netWidth) and 2 or -2)
        end
        self.half = self.netWidth / 2
        local minX, maxX = Physics.netRange(self.half)
        self:moveTo(math.max(minX, math.min(maxX, self.x)), self.y)
    else
        self.resizeClock = 0
    end

    self:refreshImage()
    if self.dipTime > 0 then
        self.dipTime = self.dipTime - dt
        if self.dipTime <= 0 then self:moveTo(self.x, Config.NET_Y) end
    end
end
