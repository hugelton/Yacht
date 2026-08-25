Music = {}

local SYNTH_TRACK_PREFIX <const> = "synth"
local DRUM_TRACK <const> = "drums"
local DEFAULT_BPM <const> = 120
local DEFAULT_SONG_END <const> = 64
local TICKS_PER_BEAT <const> = 4
local MAX_SWING_PERCENT <const> = 50

local TRACK_NAMES <const> = {
    "synth1",
    "synth2",
    "synth3",
    DRUM_TRACK
}

Music.tick = 1
Music.mode = "region"
Music.state = false
Music.maxTick = 16
Music.songLoop = true
Music.currentPosition = 1

Music.trackRegions = {}
Music.currentBlocks = {}
for _, track in ipairs(TRACK_NAMES) do
    Music.trackRegions[track] = 1
    Music.currentBlocks[track] = 0
end

local lastTickTime = 0
local accumulatedTime = 0

local function safeGet(value, ...)
    for _, key in ipairs({ ... }) do
        if type(value) ~= "table" then return nil end
        value = value[key]
    end
    return value
end

local function isSynthTrack(track)
    return track:sub(1, #SYNTH_TRACK_PREFIX) == SYNTH_TRACK_PREFIX
end

local function synthIndexForTrack(track)
    if not isSynthTrack(track) then return nil end
    return tonumber(track:sub(#SYNTH_TRACK_PREFIX + 1))
end

local function resetSongPosition()
    Music.currentPosition = 1
    for track in pairs(Music.trackRegions) do
        Music.trackRegions[track] = 1
    end
end

local function tickDuration(tick, bpm, swingPercent)
    local beatTime = 60.0 / bpm
    local baseTickTime = beatTime / TICKS_PER_BEAT
    local clampedSwing = math.max(0, math.min(MAX_SWING_PERCENT, swingPercent or 0))
    local swingAmount = clampedSwing / 100

    -- Swing delays the even 16th while preserving the duration of each pair.
    -- At 0% both ticks are straight; at 50% the pair is split 75/25.
    if tick % 2 == 1 then
        return baseTickTime * (1 + swingAmount)
    end
    return baseTickTime * (1 - swingAmount)
end

local function regionNumberForTrack(track, arrangementPosition)
    if Music.mode == "region" then
        return Music.currentPosition
    end
    return safeGet(keel, track, arrangementPosition) or 0
end

local function currentRegionForTrack(track, regionNumber)
    local synthIndex = synthIndexForTrack(track)
    if synthIndex then
        return safeGet(boat, "synths", regionNumber, synthIndex), synthIndex
    end

    if track == DRUM_TRACK then
        return safeGet(boat, "drums", regionNumber), nil
    end

    return nil, nil
end

local function playSynthStep(region, synthIndex)
    local note = safeGet(region, "notes", Music.tick)
    if not note or note <= 0 then return end

    local velocity = safeGet(region, "velos", Music.tick) or 1
    local length = safeGet(region, "length", Music.tick) or 1
    Sounds.playMidiSynth(synthIndex, note, velocity, length)
end

local function playDrumStep(region)
    if type(region.patterns) ~= "table" then return end

    local velocity = safeGet(region, "velos", Music.tick) or 1
    for drumIndex = 1, 6 do
        if safeGet(region, "patterns", drumIndex, Music.tick) == 1 then
            Sounds.playDrum(drumIndex, velocity)
        end
    end
end

function Music.flipMode()
    Music.mode = Music.mode == "region" and "song" or "region"
    resetSongPosition()
    Music.updateCurrentBlocks()
    console.log("Switching to " .. Music.mode .. " mode")
end

function Music.flipState()
    Music.state = not Music.state
    mast.isPlaying = Music.state
    if Music.state then
        lastTickTime = playdate.sound.getCurrentTime()
    end
end

function Music.Refresh()
    if not Music.state then return end

    local currentTime = playdate.sound.getCurrentTime()
    accumulatedTime = accumulatedTime + (currentTime - lastTickTime)

    local bpm = mast.bpm or DEFAULT_BPM
    local swing = mast.swing or 0
    local currentTickTime = tickDuration(Music.tick, bpm, swing)

    while accumulatedTime >= currentTickTime do
        accumulatedTime = accumulatedTime - currentTickTime
        Music.tick = (Music.tick % Music.maxTick) + 1

        if Music.tick == 1 and Music.mode == "song" then
            Music.currentPosition = (Music.currentPosition % (keel.songEnd or DEFAULT_SONG_END)) + 1
            for track in pairs(Music.trackRegions) do
                Music.trackRegions[track] = Music.currentPosition
            end

            if Music.currentPosition == 1 and not Music.songLoop then
                Music.state = false
                mast.isPlaying = false
                console.log("Song finished playing.")
                return
            end
        end

        Music.updateCurrentBlocks()
        Music.next()
        currentTickTime = tickDuration(Music.tick, bpm, swing)
    end

    lastTickTime = currentTime
end

function Music.next()
    if not Music.state then return end

    for track, arrangementPosition in pairs(Music.trackRegions) do
        local regionNumber = regionNumberForTrack(track, arrangementPosition)
        Music.currentBlocks[track] = regionNumber

        if regionNumber > 0 then
            local region, synthIndex = currentRegionForTrack(track, regionNumber)
            if region then
                if synthIndex then
                    playSynthStep(region, synthIndex)
                elseif track == DRUM_TRACK then
                    playDrumStep(region)
                end
            end
        end
    end
end

function Music.setSongLoop(loop)
    Music.songLoop = loop == true
end

function Music.setMaxRegion(max)
    keel.songEnd = max
end

function Music.updateCurrentBlocks()
    for track, arrangementPosition in pairs(Music.trackRegions) do
        Music.currentBlocks[track] = regionNumberForTrack(track, arrangementPosition)
    end
end

function Music.getCurrentPosition()
    return Music.currentPosition
end

function Music.getCurrentBlock(track)
    return Music.currentBlocks[track]
end

function Music.getAllCurrentBlocks()
    return Music.currentBlocks
end

return Music
