console = { log = function() end }

local RATE, FRAMES = 22050, 12127
local played, ranges, volumes, rates = {}, {}, {}, {}

local function stub(names, extra)
    local object = extra or {}
    for _, name in ipairs(names) do object[name] = function() end end
    return object
end

local function newSamplePlayer(sample)
    local player = { sample = sample }
    -- Mirrors the SDK contract: repeatCount must have an integer value.
    function player:play(repeatCount, rate)
        if repeatCount ~= nil and math.type(repeatCount) ~= "integer" and
            select(2, math.modf(repeatCount)) ~= 0.0 then
            error("bad argument #1 to 'play' (number has no integer representation)")
        end
        played[#played + 1] = repeatCount
        return true
    end

    -- start/end are frame offsets, so both must be whole numbers.
    function player:setPlayRange(first, last)
        for _, value in ipairs({ first, last }) do
            if select(2, math.modf(value)) ~= 0.0 then
                error("bad argument to 'setPlayRange' (number has no integer representation)")
            end
        end
        ranges[#ranges + 1] = { first = first, last = last }
    end

    function player:setVolume(v) volumes[#volumes + 1] = v end

    function player:setRate(r) rates[#rates + 1] = r end

    function player:getLength() return self.sample.frames / RATE end

    player.setSample = function(self, s) self.sample = s end
    return player
end

playdate = {
    file = { exists = function() return true end },
    sound = {
        kWaveSine = "sine", kWaveNoise = "noise",
        kFilterLowPass = "lp",
        sample = {
            new = function()
                return {
                    frames = FRAMES,
                    getLength = function() return FRAMES / RATE end,
                    getSampleRate = function() return RATE end
                }
            end
        },
        sampleplayer = { new = function(sample) return newSamplePlayer(sample) end },
        synth = { new = function() return stub({ "setWaveform", "playNote", "setVolume", "setDecay" }) end },
        overdrive = { new = function() return stub({ "setMix", "setLimit", "setGain" }) end },
        envelope = { new = function() return stub({ "setScale", "setOffset", "setCurvature", "setDecay" }) end },
        twopolefilter = { new = function() return stub({ "setFrequency" }) end },
        channel = { new = function() return stub({ "addSource", "addEffect" }) end }
    }
}

dofile("Source/data.lua")
dofile("Source/Sounds.lua")

-- Set up just the sample-backed drum slots (3-6).
Sounds.drums = { lengths = {} }
Sounds.channels = {}
Sounds.missingSamples = {}
for i = 3, 6 do
    Sounds.channels["drum" .. i] = playdate.sound.channel.new()
    assert(Sounds.loadDrumSample(i, sail["drum" .. i].loadSample), "bundled drum samples must load")
end

assert(Sounds.drums.lengths[3] == FRAMES,
    "sample lengths must be stored in frames, not seconds")

-- setPlayRange must receive whole frame offsets.
sail.drum3.length = 0.37
Sounds.updateDrumParameters(3, sail.drum3)
local range = ranges[#ranges]
assert(range.first == 0 and range.last == math.floor(FRAMES * 0.37),
    "the play range must span the requested fraction of the sample")

sail.drum3.length = 0
Sounds.updateDrumParameters(3, sail.drum3)
assert(ranges[#ranges].last >= 1, "a zero length must still leave a playable frame")

-- A pitch of zero would stall the player.
sail.drum3.pitch = 0
Sounds.updateDrumParameters(3, sail.drum3)
assert(rates[#rates] > 0, "the playback rate must stay above zero")

-- The regression: fractional velocities used to be passed as the repeat count.
for _, velocity in ipairs({ 1, 0.8, 0.75, 0.1, 0 }) do
    local before = #played
    Sounds.playDrum(3, velocity)
    assert(#played == before + 1, "a fractional velocity must not crash playback")
    assert(played[#played] == 1, "sample drums play exactly once per trigger")
    assert(math.abs(volumes[#volumes] - velocity) < 0.0001,
        "velocity must drive the player volume")
end

Sounds.playDrum(3, 1.4)
assert(volumes[#volumes] == 1, "velocity must clamp to the 0-1 range")

print("drum sample smoke tests passed")
