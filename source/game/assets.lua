-- Art loading with placeholder fallback, plus a tiny animation helper.
--
-- If source/images/<name>.png (or an animated <name>-table-W-H.png) exists,
-- it's used; otherwise the entity draws its own placeholder. Art can be
-- dropped in one file at a time without code changes. A replacement must
-- match the existing file's name and pixel size (collision depends on it).

local gfx <const> = playdate.graphics

Assets = {}

local imageCache, tableCache = {}, {}

function Assets.image(name, fallback)
    if imageCache[name] == nil then
        imageCache[name] = gfx.image.new("images/" .. name) or false
    end
    if imageCache[name] then return imageCache[name] end
    if fallback then return fallback() end
    return nil
end

-- source/images/<name>-table-<w>-<h>.png. Returns nil if absent.
function Assets.imagetable(name)
    if tableCache[name] == nil then
        tableCache[name] = gfx.imagetable.new("images/" .. name) or false
    end
    return tableCache[name] or nil
end

-- Animation: a looping imagetable driven by an explicit clock, so it freezes
-- when the game pauses (CoreLibs' gfx.animation.loop runs on wall time and
-- wouldn't). Falls back to a still image: <name>.png, then the placeholder.
--
-- `step` is how much clock advances one frame. Usually seconds, but anything
-- works: the firefighters advance by pixels walked.
local Anim = {}
Anim.__index = Anim

function Assets.anim(name, step, fallback)
    local self = setmetatable({ clock = 0, step = step }, Anim)
    self.frames = Assets.imagetable(name)
    if not self.frames then
        self.still = Assets.image(name, fallback)
    end
    return self
end

function Anim:isAnimated() return self.frames ~= nil end

function Anim:advance(amount) self.clock = self.clock + amount end

function Anim:reset() self.clock = 0 end

-- Start at a random point so many copies don't animate in lockstep.
function Anim:randomizePhase()
    if self.frames then
        self.clock = math.random() * self.step * self.frames:getLength()
    end
end

function Anim:frameIndex()
    if not self.frames then return 1 end
    return math.floor(self.clock / self.step) % self.frames:getLength() + 1
end

function Anim:image()
    if not self.frames then return self.still end
    return self.frames:getImage(self:frameIndex())
end

-- Push the current frame to a sprite, only when it changed.
function Anim:apply(sprite)
    local img = self:image()
    if img and sprite:getImage() ~= img then sprite:setImage(img) end
end
