-- Score popups and screen shake.

local gfx <const> = playdate.graphics

Effects = {}

local popups = {}
local shakeTime = 0

function Effects.reset()
    popups = {}
    shakeTime = 0
    playdate.display.setOffset(0, 0)
end

local POPUP_LINE <const> = 18 -- vertical spacing between stacked popups

-- Where a popup is drawn now: it rises over its lifetime.
local function currentY(p)
    return p.y - (p.t / Config.POPUP_DURATION) * Config.POPUP_RISE
end

-- Center x that keeps the whole text on screen.
local function onScreenX(x, w)
    local half = w / 2 + 4
    return math.max(half, math.min(Config.SCREEN_WIDTH - half, x))
end

-- Popups that would overlap one still showing are stacked above it (a rescue
-- that crosses a threshold also narrows the net, so both pop at once). They
-- all rise at the same rate, so stacked popups keep their spacing.
function Effects.popup(text, x, y)
    local w = gfx.getTextSize(text)
    x = onScreenX(x, w)
    local moved = true
    while moved do
        moved = false
        for _, p in ipairs(popups) do
            local py = currentY(p)
            if math.abs(py - y) < POPUP_LINE and math.abs(p.x - x) < (w + p.w) / 2 then
                y = py - POPUP_LINE
                moved = true
            end
        end
    end
    table.insert(popups, { text = text, x = x, y = y, t = 0, w = w })
end

function Effects.shake()
    shakeTime = Config.SHAKE_DURATION
end

function Effects.update(dt)
    for i = #popups, 1, -1 do
        local p = popups[i]
        p.t = p.t + dt
        if p.t >= Config.POPUP_DURATION then table.remove(popups, i) end
    end

    if shakeTime > 0 then
        shakeTime = shakeTime - dt
        if shakeTime > 0 then
            local a = Config.SHAKE_AMOUNT
            playdate.display.setOffset(math.random(-a, a), math.random(-a, a))
        else
            playdate.display.setOffset(0, 0)
        end
    end
end

-- Call with the white-text draw mode already set.
function Effects.draw()
    for _, p in ipairs(popups) do
        local progress = p.t / Config.POPUP_DURATION
        -- Blink out over the last quarter of its life.
        if progress < 0.75 or math.floor(p.t * 20) % 2 == 0 then
            -- x was clamped on screen when the popup was created.
            gfx.drawTextAligned(p.text, p.x, currentY(p), kTextAlignment.center)
        end
    end
end
