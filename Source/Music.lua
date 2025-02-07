Music = {}

Music.tick = 1
Music.mode = "region"
Music.state = false
Music.maxTick = 16
Music.songLoop = true
Music.currentPosition = 1

Music.trackRegions = {
    synth1 = 1,
    synth2 = 1,
    synth3 = 1,
    drums = 1
}

Music.currentBlocks = {
    synth1 = 0,
    synth2 = 0,
    synth3 = 0,
    drums = 0
}

local lastTickTime = 0
local accumulatedTime = 0



local function safeGet(t, ...)
    for _, k in ipairs({ ... }) do
        if type(t) ~= "table" then return nil end
        t = t[k]
    end
    return t
end

function Music.flipMode()
    Music.mode = Music.mode == "region" and "song" or "region"
    if Music.mode == "song" then
        for track in pairs(Music.trackRegions) do
            Music.trackRegions[track] = 1
        end
        Music.currentPosition = 1
    end
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
    local elapsedTime = currentTime - lastTickTime
    accumulatedTime = accumulatedTime + elapsedTime

    local bpm = mast.bpm or 120
    local swing = mast.swing or 0
    local beatTime = 60.0 / bpm
    local tickTime = beatTime / 4


    local evenTickTime = tickTime * (2 - swing)
    local oddTickTime = tickTime * (2 + swing)
    local currentTickTime = (Music.tick % 2 == 1) and evenTickTime or oddTickTime

    while accumulatedTime >= currentTickTime do
        accumulatedTime = accumulatedTime - currentTickTime

        Music.tick = (Music.tick % Music.maxTick) + 1

        if Music.tick == 1 then
            if Music.mode == "song" then
                Music.currentPosition = (Music.currentPosition % (keel.songEnd or 64)) + 1
                for track in pairs(Music.trackRegions) do
                    Music.trackRegions[track] = Music.currentPosition
                end
            end

            if Music.currentPosition == 1 and not Music.songLoop and Music.mode == "song" then
                Music.state = false
                mast.isPlaying = false
                console.log("Song finished playing.")
                return
            end
        end

        Music.updateCurrentBlocks()
        Music.next()

        currentTickTime = (Music.tick % 2 == 1) and evenTickTime or oddTickTime
    end

    lastTickTime = currentTime
end

function Music.next()
    if not Music.state then return end

    for track, position in pairs(Music.trackRegions) do
        local regionNumber = safeGet(keel, track, position) or 0
        Music.currentBlocks[track] = regionNumber

        if regionNumber > 0 then
            local currentRegion
            if track:sub(1, 5) == "synth" then
                local synthIndex = tonumber(track:sub(6))
                currentRegion = safeGet(boat.synths, 1, synthIndex)
            elseif track == "drums" then
                currentRegion = safeGet(boat.drums, regionNumber)
            end

            if currentRegion then
                if track:sub(1, 5) == "synth" then
                    local synthIndex = tonumber(track:sub(6))
                    local note = safeGet(currentRegion.notes, Music.tick)
                    local velocity = safeGet(currentRegion.velos, Music.tick) or 1
                    local length = safeGet(currentRegion.length, Music.tick) or 1
                    if note and note > 0 then
                        Sounds.playMidiSynth(synthIndex, note, velocity, length)
                    end
                elseif track == "drums" then
                    if currentRegion.patterns then
                        for i = 1, 6 do
                            if safeGet(currentRegion.patterns, i, Music.tick) == 1 then
                                local velocity = safeGet(currentRegion.velos, Music.tick) or 1
                                Sounds.playDrum(i, velocity)
                            end
                        end
                    end
                end
            end
        end
    end
end

function Music.setSongLoop(loop)
    Music.songLoop = loop
end

function Music.setMaxRegion(max)
    keel.songEnd = max
end

function Music.updateCurrentBlocks()
    for track, position in pairs(Music.trackRegions) do
        Music.currentBlocks[track] = safeGet(keel, track, position) or 0
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
