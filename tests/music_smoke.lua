local fakeTime = 0
playdate = {
    sound = {
        getCurrentTime = function() return fakeTime end
    }
}
console = { log = function() end }

local synthCalls = {}
local drumCalls = {}
Sounds = {
    playMidiSynth = function(index, note, velocity, length)
        table.insert(synthCalls, {
            index = index,
            note = note,
            velocity = velocity,
            length = length
        })
    end,
    playDrum = function(index, velocity)
        table.insert(drumCalls, { index = index, velocity = velocity })
    end
}

local function steps(value)
    local result = {}
    for i = 1, 16 do result[i] = value end
    return result
end

local function synthPattern(note)
    return {
        notes = steps(note),
        velos = steps(1),
        length = steps(1),
        pan = steps(0)
    }
end

local function synthRegion(note1, note2, note3)
    return {
        synthPattern(note1),
        synthPattern(note2),
        synthPattern(note3)
    }
end

local function drumRegion(activeDrum)
    local patterns = {}
    for drum = 1, 6 do
        patterns[drum] = steps(drum == activeDrum and 1 or 0)
    end
    return {
        patterns = patterns,
        velos = steps(1),
        chance = steps(1),
        accent = steps(0),
        active = steps(1)
    }
end

mast = {
    bpm = 120,
    swing = 0,
    isPlaying = false
}
keel = {
    songEnd = 2,
    loop = false,
    synth1 = { 2, 1 },
    synth2 = { 0, 0 },
    synth3 = { 0, 0 },
    drums = { 2, 1 }
}
boat = {
    synths = {
        synthRegion(48, 0, 0),
        synthRegion(72, 0, 0)
    },
    drums = {
        drumRegion(1),
        drumRegion(2)
    }
}

local function clearCalls()
    synthCalls = {}
    drumCalls = {}
end

local function resetTrackPositions()
    for track in pairs(Music.trackRegions) do
        Music.trackRegions[track] = 1
    end
end

dofile("Source/Music.lua")

-- Region mode must play the selected region directly, independent of keel.
Music.state = true
Music.mode = "region"
Music.currentPosition = 2
Music.tick = 1
Music.next()
assert(#synthCalls == 1, "region mode should play one populated synth track")
assert(synthCalls[1].note == 72, "region mode must read synth data from the selected region")
assert(#drumCalls == 1 and drumCalls[1].index == 2,
    "region mode must read drum data from the selected region")
assert(Music.getCurrentBlock("synth1") == 2,
    "current block should report the selected region in region mode")

-- Song mode must resolve each track's region number through keel.
clearCalls()
Music.state = true
Music.mode = "song"
Music.currentPosition = 1
Music.tick = 1
resetTrackPositions()
Music.next()
assert(#synthCalls == 1 and synthCalls[1].note == 72,
    "song mode must play the synth region assigned in keel")
assert(#drumCalls == 1 and drumCalls[1].index == 2,
    "song mode must play the drum region assigned in keel")
assert(Music.getCurrentBlock("synth1") == 2,
    "current block should report the arranged region in song mode")

-- Straight timing at 120 BPM is one 16th note = 0.125 seconds.
dofile("Source/Music.lua")
fakeTime = 0
mast.swing = 0
Music.flipState()
fakeTime = 0.124
Music.Refresh()
assert(Music.tick == 1, "straight timing must not advance early")
fakeTime = 0.125
Music.Refresh()
assert(Music.tick == 2, "straight timing must advance after one 16th note")

-- 50% swing delays the even 16th to 0.1875 seconds while preserving the pair.
dofile("Source/Music.lua")
fakeTime = 0
mast.swing = 50
Music.flipState()
fakeTime = 0.125
Music.Refresh()
assert(Music.tick == 1, "positive swing must delay the offbeat")
fakeTime = 0.1875
Music.Refresh()
assert(Music.tick == 2, "50% swing must advance at the delayed offbeat")
fakeTime = 0.25
Music.Refresh()
assert(Music.tick == 3, "the swung pair must still total two straight 16ths")

print("music smoke tests passed")
