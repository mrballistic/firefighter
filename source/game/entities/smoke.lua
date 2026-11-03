import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

-- Smoke drifting off the building's roof. Art-only: there's no placeholder,
-- so without images/smoke-table-*.png there's simply no smoke.
-- It runs on its own clock (SMOKE_FRAME_DURATION), independent of the flames.

class('Smoke').extends(gfx.sprite)

-- Returns nil when there's no smoke art.
function Smoke.create()
    if not Assets.imagetable("smoke") then return nil end
    return Smoke()
end

function Smoke:init()
    Smoke.super.init(self)
    self.anim = Assets.anim("smoke", Config.SMOKE_FRAME_DURATION)
    self.anim:apply(self)
    self:setZIndex(Config.Z_SMOKE)
    -- Bottom-left corner sits on the roof's left edge; the puffs drift up and
    -- to the right from there.
    local w, h = self:getImage():getSize()
    self:moveTo(Config.BUILDING_LEFT + w / 2, Config.BUILDING_TOP - h / 2)
    self:add()
end

function Smoke:tick(dt)
    self.anim:advance(dt)
    self.anim:apply(self)
end
