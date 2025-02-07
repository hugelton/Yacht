local gfx <const> = playdate.graphics

Visualizer = {}


local KEYBOARD_WIDTH = 382
local KEY_WIDTH = KEYBOARD_WIDTH / 128
local KEYBOARD_HEIGHT = 30
local START_X = 8
local START_Y = 60
local KEYBOARD_SPACING = 50
local DRUM_SPACING = 30
local DRUM_SIZE = 20
local DRUMS_START_Y = 205
local DOT_SIZE = 4


function Visualizer.init()
    console.log("Initializing Visualizer")
end

function Visualizer.drawKeyboard(y)
    gfx.drawRect(START_X, y, KEYBOARD_WIDTH, KEYBOARD_HEIGHT)


    for i = 0, 127 do
        local x          = START_X + (i * KEY_WIDTH)
        -- 黒鍵のパターンを判定（C# D# F# G# A#）
        local isBlackKey = ({ 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 })[i % 12 + 1] == 1

        if isBlackKey then
            gfx.fillRect(x, y, KEY_WIDTH, KEYBOARD_HEIGHT * 0.6)
        end
    end
end

function Visualizer.showNote(synthIndex, note)
    if note and note > 0 then
        local y = START_Y + (synthIndex - 1) * KEYBOARD_SPACING

        local adjustedNote = note - 1
        local x = START_X + (adjustedNote * KEY_WIDTH) - (DOT_SIZE / 2)


        local isBlackKey = ({ 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 })[adjustedNote % 12 + 1] == 1


        if isBlackKey then
            gfx.setColor(gfx.kColorWhite)
            gfx.setDitherPattern(0.5)
            gfx.fillRect(x + 2, y, KEY_WIDTH, KEYBOARD_HEIGHT * 0.6)
            gfx.setColor(gfx.kColorBlack)
        else
            gfx.setDitherPattern(0.5)
            gfx.fillRect(x + 2, y, KEY_WIDTH, KEYBOARD_HEIGHT)
        end
    end
end

function Visualizer.showDrumHit(drumIndex)
    if drumIndex > 0 and drumIndex <= 6 then
        local x = START_X + (drumIndex - 1) * DRUM_SPACING

        gfx.fillRoundRect(x + 3, DRUMS_START_Y + 2, DRUM_SIZE - 6, DRUM_SIZE - 6, 6)
    end
end

function Visualizer.draw()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    -- Visualizer.drawKeyboard(START_Y)
    -- assets.fonts.cavs:drawText("Synthesizer A", START_X, START_Y - 12)
    -- Visualizer.drawKeyboard(START_Y + KEYBOARD_SPACING)
    -- assets.fonts.cavs:drawText("Synthesizer B", START_X, START_Y + KEYBOARD_SPACING - 12)
    -- Visualizer.drawKeyboard(START_Y + KEYBOARD_SPACING * 2)
    -- assets.fonts.cavs:drawText("Synthesizer C", START_X, START_Y + KEYBOARD_SPACING * 2 - 12)
    -- assets.fonts.cavs:drawText("Drums", START_X, DRUMS_START_Y - 12)
    -- assets.fonts.nada:drawText("Kick Snare Close Open Perc1 Perc2", START_X, DRUMS_START_Y + 24)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    local rhythm = (Music.tick % 2) + 1
    assets.playdates:drawImage(rhythm, 200, 200)
    assets.playdates:drawImage(rhythm, 250, 200)
    assets.playdates:drawImage(rhythm, 300, 200)
    assets.playdates:drawImage(rhythm, 350, 200)




    for synthIndex = 1, 3 do
        if boat.synths[Music.currentPosition] and
            boat.synths[Music.currentPosition][synthIndex] and
            boat.synths[Music.currentPosition][synthIndex].notes then
            local currentNotes = boat.synths[Music.currentPosition][synthIndex].notes
            local note = currentNotes[Music.tick]
            if note then
                Visualizer.showNote(synthIndex, note)
            end
        end
    end


    local currentDrumPattern = boat.drums[Music.currentPosition]

    if currentDrumPattern and currentDrumPattern.patterns then
        for drumIndex = 1, 6 do
            if currentDrumPattern.patterns[drumIndex] and
                currentDrumPattern.patterns[drumIndex][Music.tick] == 1 then
                Visualizer.showDrumHit(drumIndex)
            end
        end
    end
end

return Visualizer
