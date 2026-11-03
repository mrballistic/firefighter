import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

class('Building').extends(gfx.sprite)

local function makePlaceholder(spawnPoints)
    local w, h = Config.BUILDING_WIDTH, Config.BUILDING_HEIGHT
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, w, h)
        gfx.setColor(gfx.kColorBlack)
        local ws = Config.WINDOW_SIZE
        for _, p in ipairs(spawnPoints) do
            local localY = p.y - Config.BUILDING_TOP
            gfx.fillRect(w - ws - 4, localY - ws / 2, ws, ws)
        end
    gfx.popContext()
    return image
end

function Building:init()
    Building.super.init(self)
    self.spawnPoints = Config.spawnPoints()
    self.anim = Assets.anim("building", Config.BUILDING_FRAME_DURATION, function()
        return makePlaceholder(self.spawnPoints)
    end)
    self.anim:apply(self)
    self:setZIndex(Config.Z_BUILDING)
    self:moveTo(Config.BUILDING_X, Config.BUILDING_Y)
    self:add()
end

function Building:tick(dt)
    self.anim:advance(dt)
    self.anim:apply(self)
end

-- Spawn points from window `minWindow` down (1 = top window, the default).
function Building:getSpawnPoints(minWindow)
    if not minWindow or minWindow <= 1 then return self.spawnPoints end
    local out = {}
    for i = minWindow, #self.spawnPoints do out[#out + 1] = self.spawnPoints[i] end
    return out
end
