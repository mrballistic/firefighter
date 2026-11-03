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

function Effects.popup(text, x, y)
    table.insert(popups, { text = text, x = x, y = y, t = 0 })
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
            local y = p.y - progress * Config.POPUP_RISE
            -- Keep the whole text on screen (popups near the ambulance would
            -- otherwise run off the right edge).
            local w = gfx.getTextSize(p.text)
            local half = w / 2 + 4
            local x = math.max(half, math.min(Config.SCREEN_WIDTH - half, p.x))
            gfx.drawTextAligned(p.text, x, y, kTextAlignment.center)
        end
    end
end
