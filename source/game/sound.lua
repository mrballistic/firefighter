import "CoreLibs/timer"

-- Sound effects. Synthesized by default (no audio files needed); any of
-- source/sounds/{bounce,rescue,express,splat,gameover}.wav that exists is used
-- instead. Playdate wants 16-bit PCM or IMA-ADPCM .wav (see docs/art-brief.md).

local snd <const> = playdate.sound

Sound = {}

local bounceSynth, chimeSynth, missSynth
local samples = {}

function Sound.init()
    for _, name in ipairs({ "bounce", "rescue", "express", "splat", "gameover" }) do
        samples[name] = snd.sampleplayer.new("sounds/" .. name) -- nil if absent
    end

    bounceSynth = snd.synth.new(snd.kWaveTriangle)
    bounceSynth:setADSR(0, 0.06, 0, 0.04)

    chimeSynth = snd.synth.new(snd.kWaveSquare)
    chimeSynth:setADSR(0, 0.06, 0.3, 0.08)
    chimeSynth:setVolume(0.25)

    missSynth = snd.synth.new(snd.kWaveSawtooth)
    missSynth:setADSR(0, 0.1, 0.4, 0.15)
    missSynth:setVolume(0.3)
end

-- Play notes {hz, ...} one after another on a synth.
local function sequence(synth, notes, noteLength, gapMs)
    for i, hz in ipairs(notes) do
        playdate.timer.performAfterDelay((i - 1) * gapMs, function()
            synth:playNote(hz, 1, noteLength)
        end)
    end
end

-- Pitch follows hit position (an octave from left edge to right edge),
-- so you can hear where you caught them.
function Sound.bounce(h)
    if samples.bounce then
        -- Same idea for a sample: half an octave either side of normal pitch.
        samples.bounce:play(1, 2 ^ (h / 2))
    else
        bounceSynth:playNote(330 * 2 ^ ((h + 1) / 2), 0.7, 0.08)
    end
end

function Sound.rescue(express)
    if express and samples.express then
        samples.express:play()
    elseif samples.rescue then
        samples.rescue:play()
    elseif express then
        sequence(chimeSynth, { 523, 659, 784, 1047 }, 0.06, 60)
    else
        sequence(chimeSynth, { 523, 784 }, 0.07, 80)
    end
end

-- A victim hit the ground.
function Sound.splat()
    if samples.splat then return samples.splat:play() end
    sequence(missSynth, { 220, 147 }, 0.15, 130)
end

-- Plays after a short delay so it follows the final splat instead of covering it.
local GAME_OVER_DELAY_MS <const> = 500

function Sound.gameOver()
    playdate.timer.performAfterDelay(GAME_OVER_DELAY_MS, function()
        if samples.gameover then return samples.gameover:play() end
        sequence(missSynth, { 330, 262, 196, 131 }, 0.2, 220)
    end)
end
