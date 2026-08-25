import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"
import "CoreLibs/keyboard"
import "CoreLibs/qrcode"
import "CoreLibs/nineslice"

local gfx <const> = playdate.graphics



import "debug"
import "Music"
import "data"
import "keyManager"
import "globalBar"
import "Toolbox"
import "pageSwitcher"
import "pianoRoll"
import "drumPattern"
import "cursor"
import "assets"
import "crankManager"
import "SynthEdit"
import "Mixer"
import "SongEdit"
import "Sounds"
import "MIDI"
import "FileDialog"
import "Recorder"
import "SampleSelector"
import "DrumEdit"
import "Preferences"
import "Visualizer"





yachtMeta = {
    version = "1.1.0",
    name = "Yacht",
    author = "hugelton",
}

PROJECT_FORMAT_VERSION = 1


currentFocus = "main" -- "main", "globalBar", "Toolbox", "pageSwitcher"




currentPage = "PianoRoll"
pageNames = {
    "PianoRoll",
    "DrumPattern",
    "SynthEdit",
    "DrumEdit",
    "Mixer",
    "SongEdit",
    "Visualizer",
    "Preferences",

}
pages = {
    PianoRoll = PianoRoll,
    DrumPattern = DrumPattern,
    SynthEdit = SynthEdit,
    DrumEdit = DrumEdit,
    Mixer = Mixer,
    SongEdit = SongEdit,
    Visualizer = Visualizer,
    Preferences = Preferences

}


assets.init()
local menu = playdate.getSystemMenu()

local function safeDeepCopy(src, seen)
    if type(src) ~= "table" then return src end
    seen = seen or {}
    if seen[src] then return seen[src] end

    local result = {}
    seen[src] = result
    for k, v in pairs(src) do
        result[safeDeepCopy(k, seen)] = safeDeepCopy(v, seen)
    end
    return result
end

local function projectFilename(name)
    local filename = tostring(name or "Untitled")
    filename = filename:gsub("[/\\:*?\"<>|]", "_")
    filename = filename:gsub("^%s+", ""):gsub("%s+$", "")
    return filename ~= "" and filename or "Untitled"
end

local function migrateProjectData(data)
    if type(data) ~= "table" then return nil, "Invalid project data" end

    local version = data.formatVersion
    if version == nil then version = 1 end
    if type(version) ~= "number" or version % 1 ~= 0 or version < 1 then
        return nil, "Invalid project format version"
    end
    if version > PROJECT_FORMAT_VERSION then
        return nil, "Project requires a newer Yacht version"
    end

    local migrated = safeDeepCopy(data)
    while version < PROJECT_FORMAT_VERSION do
        -- Future migrations are applied one version at a time here.
        version = version + 1
        migrated.formatVersion = version
    end
    migrated.formatVersion = PROJECT_FORMAT_VERSION
    return migrated
end

local function validateSettingsData(value)
    if type(value) ~= "table" or type(value.midiEnabled) ~= "boolean" or
        (value.midiClockSource ~= "Internal" and value.midiClockSource ~= "External") or
        type(value.midiChannels) ~= "table" or type(value.drumMidiNotes) ~= "table" then
        return false
    end
    for _, key in ipairs({ "syn1", "syn2", "syn3", "drums" }) do
        local channel = value.midiChannels[key]
        if type(channel) ~= "number" or channel < 1 or channel > 16 then return false end
    end
    for _, key in ipairs({
        "kick", "snare", "closedHiHat", "openHiHat", "percussion1", "percussion2"
    }) do
        local note = value.drumMidiNotes[key]
        if type(note) ~= "number" or note < 0 or note > 127 then return false end
    end
    return true
end

local function isSafeJSONFile(path)
    local file = playdate.file.open(path, playdate.file.kFileRead)
    if not file then return false end

    local maxBytes = 1024 * 1024
    local text, bytesRead = file:read(maxBytes + 1)
    file:close()
    if not text or not bytesRead or bytesRead == 0 or bytesRead > maxBytes then
        return false
    end

    local index, length = 1, #text
    local function skipWhitespace()
        while index <= length and text:sub(index, index):match("%s") do
            index = index + 1
        end
    end

    local parseValue

    local function parseString()
        if text:sub(index, index) ~= '"' then return false end
        index = index + 1
        while index <= length do
            local char = text:sub(index, index)
            local byte = string.byte(char)
            if char == '"' then
                index = index + 1
                return true
            elseif char == "\\" then
                index = index + 1
                local escaped = text:sub(index, index)
                if escaped == "u" then
                    local hex = text:sub(index + 1, index + 4)
                    if #hex ~= 4 or not hex:match("^%x%x%x%x$") then return false end
                    index = index + 5
                elseif escaped:match('^["\\/bfnrt]$') then
                    index = index + 1
                else
                    return false
                end
            elseif byte and byte < 32 then
                return false
            else
                index = index + 1
            end
        end
        return false
    end

    local function parseNumber()
        local start = index
        if text:sub(index, index) == "-" then index = index + 1 end

        local first = text:sub(index, index)
        if first == "0" then
            index = index + 1
        elseif first:match("[1-9]") then
            repeat
                index = index + 1
            until not text:sub(index, index):match("%d")
        else
            return false
        end

        if text:sub(index, index) == "." then
            index = index + 1
            if not text:sub(index, index):match("%d") then return false end
            repeat
                index = index + 1
            until not text:sub(index, index):match("%d")
        end

        local exponent = text:sub(index, index)
        if exponent == "e" or exponent == "E" then
            index = index + 1
            local sign = text:sub(index, index)
            if sign == "+" or sign == "-" then index = index + 1 end
            if not text:sub(index, index):match("%d") then return false end
            repeat
                index = index + 1
            until not text:sub(index, index):match("%d")
        end

        return tonumber(text:sub(start, index - 1)) ~= nil
    end

    function parseValue(depth)
        if depth > 64 then return false end
        skipWhitespace()
        local char = text:sub(index, index)

        if char == '"' then return parseString() end
        if char == "-" or char:match("%d") then return parseNumber() end
        for _, literal in ipairs({ "true", "false", "null" }) do
            if text:sub(index, index + #literal - 1) == literal then
                index = index + #literal
                return true
            end
        end

        if char == "[" then
            index = index + 1
            skipWhitespace()
            if text:sub(index, index) == "]" then
                index = index + 1
                return true
            end
            while true do
                if not parseValue(depth + 1) then return false end
                skipWhitespace()
                local separator = text:sub(index, index)
                if separator == "]" then
                    index = index + 1
                    return true
                elseif separator ~= "," then
                    return false
                end
                index = index + 1
            end
        elseif char == "{" then
            index = index + 1
            skipWhitespace()
            if text:sub(index, index) == "}" then
                index = index + 1
                return true
            end
            while true do
                skipWhitespace()
                if not parseString() then return false end
                skipWhitespace()
                if text:sub(index, index) ~= ":" then return false end
                index = index + 1
                if not parseValue(depth + 1) then return false end
                skipWhitespace()
                local separator = text:sub(index, index)
                if separator == "}" then
                    index = index + 1
                    return true
                elseif separator ~= "," then
                    return false
                end
                index = index + 1
            end
        end
        return false
    end

    local valid = parseValue(0)
    skipWhitespace()
    return valid and index > length
end

local menuItem, error = menu:addMenuItem("Load", function()
    FileDialog.open("/", "json", function(selectedPath)
        if selectedPath then
            local datastorePath = selectedPath:gsub("^/+", ""):gsub("%.json$", "")
            if datastorePath ~= "" then
                if not isSafeJSONFile(selectedPath) then
                    Balloon.open("Invalid or damaged project file")
                    return
                end
                local data = playdate.datastore.read(datastorePath)
                if data then
                    if loadProject(data) then
                        Balloon.open("Project loaded: " .. datastorePath)
                    end
                else
                    Balloon.open("Failed to load project: " .. datastorePath)
                end
            end
        else
            Balloon.open("Load cancelled")
        end
    end)
end)



local menuItem, error = menu:addMenuItem("Save", function()
    saveProject()
end)

local function onPageChange(newPage)
    currentPage = newPage
    Toolbox.onPageChange(newPage)
end


function makeMenuImage()
    menuImage = playdate.graphics.image.new(400, 240)
    playdate.graphics.pushContext(menuImage)
    playdate.graphics.setColor(playdate.graphics.kColorWhite)
    playdate.graphics.fillRect(0, 0, 200, 240)


    local line_height = 12
    local base_y = 5
    local current_y = base_y

    -- タイトル
    gfx.drawText("*" .. playdate.metadata.name .. " " .. playdate.metadata.version .. " beta *", 5, current_y)
    current_y = current_y + line_height
    gfx.drawText("*made by Leo Kuroshita*", 5, current_y)
    current_y = current_y + line_height
    gfx.drawText("*for Hugelton inst. kobe,japan.*", 5, current_y)
    assets.playdates:drawImage(1, 10, 100)
    playdate.graphics.popContext()
    playdate.setMenuImage(menuImage, 0)
end

function playdate.init()
    console.log("Initializing...")

    playdate.setCrankSoundsDisabled(true)

    Toolbox.init()

    GlobalBar.init()

    for _, page in pairs(pages) do
        if page.init then
            page.init()
        end
    end
    Sounds.init()
    MIDI.init()

    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            if currentPage == "PianoRoll" then
                if PianoRoll.currentView == "notes" then
                    assets.backgroundImages.seq:draw(0, 0)
                elseif PianoRoll.currentView == "automation" then
                    assets.backgroundImages.seq2:draw(0, 0)
                end
            elseif currentPage == "DrumPattern" then
                assets.backgroundImages.patterns:draw(0, 0)
            elseif currentPage == "SynthEdit" then
                assets.backgroundImages.syn:draw(0, 0)
            elseif currentPage == "DrumEdit" then
                assets.backgroundImages.drums:draw(0, 0)
            elseif currentPage == "Mixer" then
                assets.backgroundImages.mixer:draw(0, 0)
            elseif currentPage == "SongEdit" then
                assets.backgroundImages.song:draw(0, 0)
            elseif currentPage == "Preferences" then
                assets.backgroundImages.pref:draw(0, 0)
            elseif currentPage == "Visualizer" then
                assets.backgroundImages.visual:draw(0, 0)
            end
        end
    )


    makeMenuImage()

    console.log("Initialization complete")
end

playdate.init()


local function handleInput()
    if KeyManager.justReleased(KeyManager.keys.b) then
        if currentFocus == "globalBar" or currentFocus == "Toolbox" then
            currentFocus = "main"
        elseif currentFocus == "pageSwitcher" then
            currentFocus = "globalBar"
            PageSwitcher.close()
        elseif currentFocus == "main" then
            currentFocus = "globalBar"
        elseif currentFocus == "dialog" then
            SampleSelector.close()
        end
    end




    if currentFocus == "main" then
        if pages[currentPage] and pages[currentPage].handleInput then
            pages[currentPage].handleInput()
        end
    elseif currentFocus == "globalBar" then
        GlobalBar.handleInput()
    elseif currentFocus == "Toolbox" then
        Toolbox.handleInput()
    elseif currentFocus == "pageSwitcher" then
        local newPage = PageSwitcher.handleInput()
        if newPage then
            onPageChange(newPage)
            currentFocus = "main"
            PageSwitcher.close()
        end
    elseif currentFocus == "dialog" then
        SampleSelector.handleInput()
    end


    if KeyManager.justComboPressed("ab") then
        Music.flipState()
    end
end



Balloon = {}

Balloon.isOpen = false
Balloon.message = ""
Balloon.padding = 20
Balloon.minWidth = 100
Balloon.maxWidth = 380
Balloon.cornerOffset = 10
Balloon.timer = nil
Balloon.displayDuration = 2000

function Balloon.open(text)
    Balloon.message = text
    Balloon.isOpen = true


    if Balloon.timer then
        Balloon.timer:remove()
    end


    Balloon.timer = playdate.timer.new(Balloon.displayDuration, function()
        Balloon.close()
    end)


    local textWidth = assets.fonts.cavs:getTextWidth(text)
    local textHeight = assets.fonts.cavs:getHeight()

    Balloon.size = {
        w = math.min(math.max(textWidth + Balloon.padding * 2, Balloon.minWidth), Balloon.maxWidth),
        h = textHeight + Balloon.padding
    }

    Balloon.size.x = 400 - Balloon.size.w - Balloon.cornerOffset
    Balloon.size.y = 240 - Balloon.size.h - Balloon.cornerOffset
end

function Balloon.close()
    Balloon.isOpen = false
    if Balloon.timer then
        Balloon.timer:remove()
        Balloon.timer = nil
    end
end

function Balloon.draw()
    if not Balloon.isOpen then return end


    playdate.graphics.setColor(playdate.graphics.kColorWhite)
    playdate.graphics.fillRoundRect(
        Balloon.size.x,
        Balloon.size.y,
        Balloon.size.w,
        Balloon.size.h,
        4
    )


    playdate.graphics.setColor(playdate.graphics.kColorBlack)
    playdate.graphics.drawRoundRect(
        Balloon.size.x,
        Balloon.size.y,
        Balloon.size.w,
        Balloon.size.h,
        4
    )


    assets.fonts.cavs:drawTextAligned(
        Balloon.message,
        Balloon.size.x + (Balloon.size.w / 2),
        Balloon.size.y + (Balloon.size.h - assets.fonts.cavs:getHeight()) / 2,
        kTextAlignment.center
    )
end

function playdate.update()
    Music.Refresh()

    gfx.sprite.update()
    KeyManager.update()
    CrankManager.update()
    Recorder.update()



    if currentFocus == "FileDialog" then
        FileDialog.handleInput()
    else
        handleInput()
    end


    playdate.graphics.setColor(gfx.kColorBlack)

    if pages[currentPage] and pages[currentPage].draw then
        pages[currentPage].draw()
    end



    PageSwitcher.mask.draw()

    if PageSwitcher.isOpen() then
        PageSwitcher.draw()
    end



    Toolbox.update()

    if Toolbox.dialog.isOpen then
        Toolbox.drawDialog()
    end



    GlobalBar.draw()
    FileDialog.draw()

    -- Drawn last so the picker works from any page that opens it.
    SampleSelector.draw()

    cursor.update()
    if Balloon.isOpen then
        Balloon.draw()
    end
end

console.log("Main script loaded")

print(yachtMeta.name .. " " .. yachtMeta.version .. " beta")


local posDetect = {}
posDetect.show = false
posDetect.size = false
posDetect.delta = 1
posDetect.x = 100
posDetect.y = 100
posDetect.w = 2
posDetect.h = 2




function playdate.keyPressed(key)
    if key == "1" then
        currentPage = "PianoRoll"



        PianoRoll.switchMode("notes")
    elseif key == "2" then
        currentPage = "PianoRoll"
        PianoRoll.switchMode("automation")
    elseif key == "3" then
        currentPage = "DrumPattern"
    elseif key == "4" then
        currentPage = "SynthEdit"
    elseif key == "5" then
        currentPage = "DrumEdit"
    elseif key == "6" then
        currentPage = "Mixer"
    elseif key == "7" then
        currentPage = "SongEdit"
    elseif key == "8" then
        currentPage = "Visualizer"
    elseif key == "9" then
        currentPage = "Preferences"
    elseif key == "e" then
        Music.flipState()
    elseif key == "r" then
        Music.flipMode()
    elseif key == "q" then
        if PageSwitcher.isOpen() then
            PageSwitcher.close()
            currentFocus = "main"
        else
            PageSwitcher.open()
            currentFocus = "pageSwitcher"
        end
    elseif key == "z" then
        posDetect.show = not posDetect.show
    elseif key == "x" then
        posDetect.size = not posDetect.size
    elseif key == "c" then
        posDetect.delta = 1
    elseif key == "v" then
        posDetect.delta = 10
    elseif key == "b" then
        posDetect.delta = 100
    end


    if posDetect.size then
        if key == "j" then
            posDetect.w = posDetect.w - posDetect.delta
        elseif key == "k" then
            posDetect.h = posDetect.h + posDetect.delta
        elseif key == "i" then
            posDetect.h = posDetect.h - posDetect.delta
        elseif key == "l" then
            posDetect.w = posDetect.w + posDetect.delta
        end
    else
        if key == "j" then
            posDetect.x = posDetect.x - posDetect.delta
        elseif key == "k" then
            posDetect.y = posDetect.y + posDetect.delta
        elseif key == "i" then
            posDetect.y = posDetect.y - posDetect.delta
        elseif key == "l" then
            posDetect.x = posDetect.x + posDetect.delta
        end
    end
end

function playdate.debugDraw()
    if posDetect.show then
        playdate.setDebugDrawColor(1, 0, 0, 1)
        gfx.setColor(1)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)


        gfx.setLineWidth(2)



        gfx.drawRect(
            posDetect.x,
            posDetect.y,
            posDetect.w,
            posDetect.h
        )


        gfx.drawText("pos: " .. posDetect.x .. ", " .. posDetect.y, 100, 110)
        gfx.drawText("size: " .. posDetect.w .. ", " .. posDetect.h, 100, 120)


        gfx.setLineWidth(1)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

function loadProject(data)
    if not data then
        Balloon.open("Invalid project data")
        return false
    end


    local migratedData, migrationError = migrateProjectData(data)
    if not migratedData then
        Balloon.open(migrationError)
        return false
    end

    if not migratedData.sail or not migratedData.mast or
        not migratedData.keel or not migratedData.boat then
        Balloon.open("Missing required project components")
        return false
    end


    local newSail = safeDeepCopy(migratedData.sail)
    local newMast = safeDeepCopy(migratedData.mast)
    local newKeel = safeDeepCopy(migratedData.keel)
    local newBoat = safeDeepCopy(migratedData.boat)
    local newSettings = migratedData.settings and safeDeepCopy(migratedData.settings) or settings
    if not validateSettingsData(newSettings) then
        Balloon.open("Invalid project settings")
        return false
    end


    if not validateProjectStructure(newSail, newMast, newKeel, newBoat) then
        Balloon.open("Invalid project structure")
        return false
    end


    Music.tick = 1
    Music.currentPosition = 1
    Music.state = false
    Music.hasStartedCurrentStep = false


    sail = newSail
    mast = newMast
    keel = newKeel
    boat = newBoat
    settings = newSettings
    mast.isPlaying = false


    PianoRoll.load()
    DrumPattern.load()
    SynthEdit.load()
    Mixer.load()
    SongEdit.load()
    Preferences.load()
    Sounds.load()
    MIDI.init()


    playdate.graphics.sprite.redrawBackground()

    return true
end

function validateProjectStructure(sail, mast, keel, boat)
    local function numberIn(value, minimum, maximum)
        return type(value) == "number" and value == value and
            value >= minimum and value <= maximum
    end

    local function hasNumericSteps(values, minimum, maximum)
        if type(values) ~= "table" then return false end
        for step = 1, 16 do
            if not numberIn(values[step], minimum, maximum) then return false end
        end
        return true
    end

    if type(sail) ~= "table" or type(mast) ~= "table" or
        type(keel) ~= "table" or type(boat) ~= "table" then
        return false
    end

    if not (sail.synth1 and sail.synth2 and sail.synth3 and
            sail.drum1 and sail.drum2 and sail.drum3 and
            sail.drum4 and sail.drum5 and sail.drum6 and
            sail.mixer) then
        return false
    end

    for i = 1, 3 do
        local synth = sail["synth" .. i]
        if type(synth) ~= "table" or type(synth.oscillator) ~= "table" or
            type(synth.filter) ~= "table" or type(synth.amp) ~= "table" or
            type(synth.lfo) ~= "table" or type(synth.env) ~= "table" then
            return false
        end
        -- mode/loadSample arrived with the sampler; older projects omit both
        -- and fall back to the oscillator.
        if synth.mode ~= nil and synth.mode ~= "osc" and
            synth.mode ~= "wavetable" and synth.mode ~= "sample" then
            return false
        end
        if synth.loadSample ~= nil and type(synth.loadSample) ~= "string" then
            return false
        end
        if synth.sampler ~= nil then
            if type(synth.sampler) ~= "table" or
                not numberIn(synth.sampler.tune, 0, 1) or
                not numberIn(synth.sampler.length, 0, 1) then
                return false
            end
        end
        if not numberIn(synth.oscillator.form, 0, 7) or
            not numberIn(synth.oscillator.param1, 0, 1) or
            not numberIn(synth.oscillator.param2, 0, 1) or
            not numberIn(synth.filter.type, 0, 6) or
            not numberIn(synth.filter.cutoff, 0, 1) or
            not numberIn(synth.filter.resonance, 0, 1) then
            return false
        end
        for _, field in ipairs({ "volume", "attack", "decay", "sustain", "release" }) do
            if not numberIn(synth.amp[field], 0, 1) then return false end
        end
        if not numberIn(synth.lfo.form, 0, 5) or
            not numberIn(synth.lfo.frequency, 0, 1) or
            not numberIn(synth.lfo.depth, 0, 1) or
            not numberIn(synth.lfo.hold, 0, 1) or
            not numberIn(synth.lfo.delay, 0, 1) or
            not numberIn(synth.env.attack, 0, 1) or
            not numberIn(synth.env.decay, 0, 1) or
            not numberIn(synth.env.sustain, 0, 1) or
            not numberIn(synth.env.release, 0, 1) or
            not numberIn(synth.env.depth, 0, 1) then
            return false
        end
        for _, source in ipairs({ synth.lfo, synth.env }) do
            for _, field in ipairs({ "pitch", "filter", "param1", "param2" }) do
                if type(source[field]) ~= "boolean" then return false end
            end
        end
    end

    for _, field in ipairs({ "pitch", "slope", "decay", "curve", "gain", "limit", "mix" }) do
        if not numberIn(sail.drum1[field], 0, 1) then return false end
    end
    for _, field in ipairs({ "snappy", "pitch", "slope", "decay", "tone" }) do
        if not numberIn(sail.drum2[field], 0, 1) then return false end
    end
    for drumIndex = 3, 6 do
        local drum = sail["drum" .. drumIndex]
        if not numberIn(drum.pitch, 0, 1) or not numberIn(drum.length, 0, 1) or
            (drum.loadSample ~= nil and type(drum.loadSample) ~= "string") then
            return false
        end
    end

    local mixerNames = { "synth1", "synth2", "synth3", "drum1", "drum2",
        "drum3", "drum4", "drum5", "drum6" }
    for i = 1, #mixerNames do
        local channel = sail.mixer[mixerNames[i]]
        if type(channel) ~= "table" or not numberIn(channel.volume, 0, 1) or
            type(channel.mute) ~= "boolean" or not numberIn(channel.pan, -1, 1) then
            return false
        end
    end


    if type(mast.name) ~= "string" or mast.name == "" or
        type(mast.bpm) ~= "number" or mast.bpm < 20 or mast.bpm > 300 or
        type(mast.swing) ~= "number" or mast.swing < 0 or mast.swing > 50 or
        type(mast.steps) ~= "number" or type(mast.measure) ~= "number" then
        return false
    end


    if not (numberIn(keel.songEnd, 1, 64) and type(keel.synth1) == 'table' and
            type(keel.synth2) == 'table' and type(keel.synth3) == 'table' and
            type(keel.drums) == 'table' and type(keel.loop) == "boolean") then
        return false
    end
    for _, trackName in ipairs({ "synth1", "synth2", "synth3", "drums" }) do
        for position = 1, 64 do
            local regionNumber = keel[trackName][position]
            if regionNumber ~= nil and not numberIn(regionNumber, 0, 64) then
                return false
            end
        end
    end


    if not (type(boat.synths) == 'table' and type(boat.drums) == 'table') then
        return false
    end

    for _, region in ipairs(boat.synths) do
        if type(region) ~= "table" then return false end
        for synthIndex = 1, 3 do
            local pattern = region[synthIndex]
            if type(pattern) ~= "table" or type(pattern.notes) ~= "table" or
                type(pattern.length) ~= "table" or type(pattern.pan) ~= "table" or
                type(pattern.velos) ~= "table" then
                return false
            end
            if not hasNumericSteps(pattern.notes, 0, 127) or
                not hasNumericSteps(pattern.length, 0, 16) or
                not hasNumericSteps(pattern.pan, -1, 1) or
                not hasNumericSteps(pattern.velos, 0, 1) then
                return false
            end
        end
    end

    for _, region in ipairs(boat.drums) do
        if type(region) ~= "table" or type(region.patterns) ~= "table" or
            type(region.velos) ~= "table" or type(region.chance) ~= "table" then
            return false
        end
        for drumIndex = 1, 6 do
            if not hasNumericSteps(region.patterns[drumIndex], 0, 1) then return false end
        end
        if not hasNumericSteps(region.velos, 0, 1) or
            not hasNumericSteps(region.chance, 0, 1) then return false end
        -- accent/active arrived after the first release, so older projects omit
        -- them; DrumPattern.load backfills whatever is missing.
        for _, lane in ipairs({ "accent", "active" }) do
            if region[lane] ~= nil and not hasNumericSteps(region[lane], 0, 1) then
                return false
            end
        end
    end


    return true
end

function saveProject()
    local saveData = {
        formatVersion = PROJECT_FORMAT_VERSION,
        appVersion = yachtMeta.version,
        sail = safeDeepCopy(sail),
        mast = safeDeepCopy(mast),
        keel = safeDeepCopy(keel),
        boat = safeDeepCopy(boat),
        settings = safeDeepCopy(settings)
    }
    saveData.mast.isPlaying = false


    if not validateProjectStructure(saveData.sail, saveData.mast, saveData.keel, saveData.boat) then
        Balloon.open("Failed to create valid save data")
        return false
    end

    local writeOK, result = pcall(
        playdate.datastore.write,
        saveData,
        projectFilename(saveData.mast.name),
        true
    )
    local success = writeOK and result
    if success then
        Balloon.open("Project saved successfully")
        return true
    else
        Balloon.open("Failed to save project")
        return false
    end
end
