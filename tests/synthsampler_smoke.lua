console = { log = function() end }

-- Frame counts of the real bundled samples (16-bit mono, 22050 Hz).
local sampleFrames = { ["09_BD"] = 12127, ["08_CH"] = 2646, ["08_OH"] = 15876 }
local RATE = 22050

local calls = { setWavetable = {}, setWaveform = {}, parameter = {}, parameterMod = {} }
local built = 0

local function newSynth(tag)
    local synth = { tag = tag, wavetable = nil }
    function synth:setWaveform(w)
        calls.setWaveform[#calls.setWaveform + 1] = w
        self.waveform = w
    end

    function synth:setWavetable(sample, size, xsize)
        if sample.format ~= "16bitMono" then error("wavetable needs 16-bit mono") end
        if size % 2 ~= 0 then error("cell size must be a power of two") end
        calls.setWavetable[#calls.setWavetable + 1] = { size = size, xsize = xsize }
        self.wavetable = { size = size, xsize = xsize }
    end

    function synth:setParameter(index, value)
        calls.parameter[#calls.parameter + 1] = { index = index, value = value }
    end

    function synth:setParameterMod(index, signal)
        calls.parameterMod[#calls.parameterMod + 1] = { index = index, signal = signal }
    end

    for _, name in ipairs({ "setVolume", "setAttack", "setDecay", "setSustain",
        "setRelease", "setFrequencyMod" }) do
        synth[name] = function() end
    end
    return synth
end

local function stub(names, extra)
    local object = extra or {}
    for _, name in ipairs(names) do object[name] = function() end end
    return object
end

playdate = {
    file = {
        exists = function(path)
            local name = path:match("^Samples/(.+)%.wav$")
            return name ~= nil and sampleFrames[name] ~= nil
        end
    },
    sound = {
        kWaveSine = "sine", kWaveSquare = "square", kWaveSawtooth = "saw",
        kWaveTriangle = "triangle", kWaveNoise = "noise",
        kWavePOPhase = "pophase", kWavePODigital = "podigital", kWavePOVosim = "povosim",
        kLFOSine = "lfosine", kLFOSquare = "lfosquare", kLFOSawtoothUp = "lfosawup",
        kLFOSawtoothDown = "lfosawdown", kLFOTriangle = "lfotri", kLFOSampleAndHold = "lfosh",
        kFilterLowPass = "lp", kFilterHighPass = "hp", kFilterBandPass = "bp",
        kFilterNotch = "notch", kFilterPEQ = "peq",
        kFilterLowShelf = "ls", kFilterHighShelf = "hs",
        synth = {
            new = function(arg)
                built = built + 1
                local synth = newSynth(built)
                if type(arg) == "table" and arg.frames then synth.sample = arg end
                return synth
            end
        },
        instrument = {
            new = function()
                return stub({ "allNotesOff", "playMIDINote", "setVolume" },
                    { addVoice = function(self, voice) self.voice = voice end })
            end
        },
        channel = {
            new = function()
                local channel = { sources = {} }
                function channel:addSource(s) self.sources[s] = true end

                function channel:removeSource(s) self.sources[s] = nil end

                channel.addEffect = function() end
                channel.setVolume = function() end
                channel.setPan = function() end
                return channel
            end
        },
        sample = {
            new = function(path)
                local name = path:match("^Samples/(.+)%.wav$")
                local frames = name and sampleFrames[name]
                if not frames then return nil end
                return {
                    frames = frames,
                    format = "16bitMono",
                    getLength = function() return frames / RATE end,
                    getSampleRate = function() return RATE end
                }
            end
        },
        lfo = { new = function() return stub({ "setType", "setRate", "setDepth", "setDelay" }) end },
        envelope = {
            new = function()
                return stub({ "setAttack", "setDecay", "setSustain", "setRelease", "setScale" })
            end
        },
        twopolefilter = {
            new = function()
                return stub({ "setType", "setFrequency", "setResonance", "setMix",
                    "setGain", "setFrequencyMod" })
            end
        }
    }
}

dofile("Source/data.lua")
dofile("Source/Sounds.lua")

-- Mirror the synth half of Sounds.init() without stubbing the drum engine.
Sounds.synths, Sounds.instruments, Sounds.channels = {}, {}, {}
Sounds.filters, Sounds.lfos, Sounds.envs = {}, {}, {}
Sounds.synthModes, Sounds.automationPans = {}, { 0, 0, 0 }
for i = 1, 3 do
    Sounds.channels["synth" .. i] = playdate.sound.channel.new()
    Sounds.filters[i] = playdate.sound.twopolefilter.new()
    Sounds.lfos[i] = playdate.sound.lfo.new()
    Sounds.envs["synth" .. i] = playdate.sound.envelope.new()
    Sounds.rebuildSynthVoice(i, sail["synth" .. i])
    Sounds.updateSynthParameters(i, sail["synth" .. i])
end

-- Default projects stay on the oscillator.
for i = 1, 3 do
    assert(Sounds.getSynthMode(i) == "osc", "synths must default to oscillator mode")
end

local function reset()
    calls = { setWavetable = {}, setWaveform = {}, parameter = {}, parameterMod = {} }
end

-- Sample mode swaps the voice and drops the oscillator-only calls.
reset()
sail.synth1.loadSample = "09_BD"
assert(Sounds.setSynthMode(1, "sample"), "a bundled sample must load")
assert(Sounds.getSynthMode(1) == "sample")
assert(Sounds.synths[1].sample ~= nil, "the voice must be built from the sample")
assert(#calls.setWaveform == 0, "a sample voice has no waveform")
assert(#calls.parameter == 0, "a sample voice has no parameters")
assert(Sounds.channels.synth1.sources[Sounds.instruments[1]], "the new voice must be on the channel")

-- Wavetable mode slices the sample into power-of-two cells and scans with ①.
reset()
sail.synth1.oscillator.param1 = 0.25
assert(Sounds.setSynthMode(1, "wavetable"), "wavetable mode must build")
assert(Sounds.getSynthMode(1) == "wavetable")
local table1 = calls.setWavetable[1]
assert(table1 and table1.size == 256, "cells must be 256 frames")
assert(table1.xsize == math.floor(sampleFrames["09_BD"] / 256), "cell count must span the sample")
assert(#calls.setWaveform == 0, "a wavetable voice has no waveform")
assert(#calls.parameter == 1 and calls.parameter[1].index == 2,
    "the scan position is SDK parameter 2")
assert(math.abs(calls.parameter[1].value - 0.25) < 0.0001, "① drives the scan position")

-- The shortest sample still yields a usable table.
reset()
assert(Sounds.setSynthSample(1, "08_CH"), "switching samples must reload the voice")
assert(calls.setWavetable[1].xsize == math.floor(sampleFrames["08_CH"] / 256))
assert(calls.setWavetable[1].xsize >= 1, "every sample must yield at least one cell")

-- The ① MOD row retargets onto the wavetable scan parameter.
reset()
sail.synth1.lfo.param1 = true
sail.synth1.env.param1 = false
Sounds.updateSynthParameters(1, sail.synth1)
local routed = false
for _, call in ipairs(calls.parameterMod) do
    if call.index == 2 and call.signal == Sounds.lfos[1] then routed = true end
end
assert(routed, "the ① MOD row must drive the wavetable scan in wavetable mode")
for _, call in ipairs(calls.parameterMod) do
    assert(call.index ~= 1, "a wavetable voice has no SDK parameter 1 to modulate")
end

-- A missing sample falls back to the oscillator instead of going silent.
reset()
sail.synth2.loadSample = "does_not_exist"
assert(Sounds.setSynthMode(2, "sample") == false, "a missing sample must report failure")
assert(Sounds.getSynthMode(2) == "osc", "the voice must fall back to the oscillator")
assert(#calls.setWaveform > 0, "the fallback voice is a real oscillator")
assert(Sounds.setSynthSample(2, "nope") == false, "unknown sample names must be rejected")

-- Re-applying identical parameters must not churn the voice.
reset()
local before = Sounds.synths[3]
Sounds.updateSynthParameters(3, sail.synth3)
Sounds.updateSynthParameters(3, sail.synth3)
assert(Sounds.synths[3] == before, "an unchanged mode must not rebuild the voice")

-- Going back to oscillator restores waveform handling.
reset()
assert(Sounds.setSynthMode(1, "osc"), "returning to oscillator mode must work")
assert(#calls.setWaveform > 0, "oscillator mode sets a waveform again")
assert(#calls.parameter == 2, "oscillator mode drives both synth parameters")

print("synth sampler smoke tests passed")
