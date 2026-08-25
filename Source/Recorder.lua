local gfx <const> = playdate.graphics

-- Microphone capture for the synth sampler. Recordings are written to the
-- app's Data folder in Playdate's own .pda format; .wav is deliberately not
-- used because the SDK cannot read back the WAV files it writes.
Recorder = {}

Recorder.directory = "recordings"
Recorder.extension = ".pda"
Recorder.maxSeconds = 4
Recorder.slotCount = 8

Recorder.isRecording = false
Recorder.buffer = nil
Recorder.startedAt = 0
Recorder.onComplete = nil
Recorder.level = 0

function Recorder.path(name)
    return Recorder.directory .. "/" .. name .. Recorder.extension
end

function Recorder.isRecordingName(name)
    return type(name) == "string" and name:match("^REC%d+$") ~= nil
end

function Recorder.exists(name)
    return Recorder.isRecordingName(name) and playdate.file.exists(Recorder.path(name))
end

-- Names of the slots that currently hold audio, in slot order.
function Recorder.list()
    local names = {}
    for slot = 1, Recorder.slotCount do
        local name = "REC" .. slot
        if playdate.file.exists(Recorder.path(name)) then
            names[#names + 1] = name
        end
    end
    return names
end

-- Reuses the lowest free slot, then wraps around to REC1 once all are taken.
function Recorder.nextSlotName()
    for slot = 1, Recorder.slotCount do
        local name = "REC" .. slot
        if not playdate.file.exists(Recorder.path(name)) then return name end
    end
    return "REC1"
end

function Recorder.elapsed()
    if not Recorder.isRecording then return 0 end
    return math.min(Recorder.maxSeconds,
        (playdate.getCurrentTimeMilliseconds() - Recorder.startedAt) / 1000)
end

local function finish(name, sample)
    Recorder.isRecording = false
    Recorder.buffer = nil
    playdate.sound.micinput.stopListening()

    local callback = Recorder.onComplete
    Recorder.onComplete = nil
    if not sample then
        if callback then callback(nil) end
        return
    end

    playdate.file.mkdir(Recorder.directory)
    local saved = pcall(function() sample:save(Recorder.path(name)) end)
    if saved and playdate.file.exists(Recorder.path(name)) then
        if callback then callback(name) end
    else
        console.log("Recorder: failed to save " .. name)
        if callback then callback(nil) end
    end
end

-- onComplete(name) receives the slot name, or nil when the take was lost.
function Recorder.start(onComplete)
    if Recorder.isRecording then return false end

    local buffer = playdate.sound.sample.new(Recorder.maxSeconds,
        playdate.sound.kFormat16bitMono)
    if not buffer then return false end

    local name = Recorder.nextSlotName()
    Recorder.buffer = buffer
    Recorder.onComplete = onComplete
    Recorder.isRecording = true
    Recorder.startedAt = playdate.getCurrentTimeMilliseconds()
    Recorder.level = 0

    playdate.sound.micinput.startListening()
    local started = playdate.sound.micinput.recordToSample(buffer, function(sample)
        finish(name, sample or buffer)
    end, "Record a sample for your instrument")

    if not started then
        Recorder.isRecording = false
        Recorder.buffer = nil
        Recorder.onComplete = nil
        playdate.sound.micinput.stopListening()
        return false
    end
    return true
end

function Recorder.stop()
    if not Recorder.isRecording then return end
    -- The completion callback fires synchronously from here.
    playdate.sound.micinput.stopRecording()
end

function Recorder.update()
    if not Recorder.isRecording then return end
    Recorder.level = playdate.sound.micinput.getLevel() or 0
end

-- Compact meter drawn inside the oscillator panel while capturing.
function Recorder.drawMeter(x, y, width, height)
    local remaining = Recorder.maxSeconds - Recorder.elapsed()

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(x, y, width, height)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(x, y, width, height)

    local meterWidth = math.floor((width - 4) * math.max(0, math.min(1, Recorder.level)))
    gfx.fillRect(x + 2, y + 2, meterWidth, height - 4)

    assets.fonts.nada:drawTextAligned(string.format("%.1fs", remaining),
        x + width / 2, y + height + 2, kTextAlignment.center)
end

console.log("Recorder loaded")

return Recorder
