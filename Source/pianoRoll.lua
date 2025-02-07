local gfx <const> = playdate.graphics


---
--- Demon PianoRoll System.
--- for Yacht
--- v0.1
--- 2024 Leo Kuroshita
---


PianoRoll = {}

PianoRoll.cursor = { x = 1, y = 1 }
PianoRoll.grids = {
    notes = { maxH = 16, maxV = 12 },
    automation = { maxH = 16, maxV = 9 }
}
PianoRoll.scrollOffset = 1
PianoRoll.noteHeight = 16

PianoRoll.currentTrack = 1
PianoRoll.currentRegion = 1

PianoRoll.currentView = "notes"
PianoRoll.kLegato = 1.5

PianoRoll.cursors = {
    notes = {},
    automation = {}
}
local elapseBomb = 0


local notesStartX, notesStartY = 55, 38
local notesCellWidth, notesCellHeight = 16, 16

local autoStartX, autoStartY = 55, 38
local autoCellWidth, autoCellHeight = 18, 18

local cursorHold = {
    notes = { x = 1, y = 1 },
    automation = { x = 1, y = 1 }
}


PianoRoll.keysLabels = {
    { 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 },
    { 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0 },
    { 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1 },
    { 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0 },
    { 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1 },
    { 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
    { 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0 },
    { 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1 },
    { 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0 },
    { 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1 },
    { 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0 },
    { 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1 }
}
PianoRoll.keysLabelOptimized = {}
for _, row in ipairs(PianoRoll.keysLabels) do
    table.insert(PianoRoll.keysLabelOptimized, table.concat(row))
end


PianoRoll.keysName = { "C.", "C#", "D.", "D#", "E.", "F.", "F#", "G.", "G#", "A.", "A#", "B." }

function PianoRoll.keyName(noteNumber)
    local octave = math.floor((noteNumber) / 12)
    local noteIndex = (noteNumber + -2) % 12 + 1
    return PianoRoll.keysName[noteIndex] .. octave
end

for y = 1, PianoRoll.grids.notes.maxV do
    PianoRoll.cursors.notes[y] = {}
    for x = 1, PianoRoll.grids.notes.maxH do
        PianoRoll.cursors.notes[y][x] = {
            x = notesStartX + ((x - 1) * notesCellWidth),
            y = notesStartY + ((y - 1) * notesCellHeight),
            w = notesCellWidth - 1,
            h = notesCellHeight - 1
        }
    end
end


local lengthRows = 5
local panRows = 3
local veloRows = 2
local gapHeight = 6

for y = 1, PianoRoll.grids.automation.maxV do
    PianoRoll.cursors.automation[y] = {}
    for x = 1, PianoRoll.grids.automation.maxH do
        local yPos = autoStartY + ((y - 1) * autoCellHeight)
        local height = autoCellHeight

        if y > lengthRows then
            yPos = yPos + gapHeight
        end

        if y > lengthRows + panRows then
            height = autoCellHeight + 16

            yPos = yPos + gapHeight + 1
        end

        PianoRoll.cursors.automation[y][x] = {
            x = autoStartX + ((x - 1) * autoCellWidth),
            y = yPos,
            w = autoCellWidth - 1,
            h = height - 1
        }
    end
end
function PianoRoll.init()
    console.log("Initializing PianoRoll")
    PianoRoll.cursor.x, PianoRoll.cursor.y = 1, 1
    PianoRoll.scrollOffset = 63
    PianoRoll.currentView = "notes"
    console.log("PianoRoll initialization complete")
end

function PianoRoll.handleInput()
    local currentPattern = boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack]
    if KeyManager.justComboPressed("rightB") then
        PianoRoll.switchMode("automation")
    elseif KeyManager.justComboPressed("leftB") then
        PianoRoll.switchMode("notes")
    end
    if KeyManager.justComboPressed("upB") then
        if PianoRoll.currentRegion <= 32 then
            PianoRoll.switchRegion(1)
        end
    elseif KeyManager.justComboPressed("downB") then
        if PianoRoll.currentRegion >= 1 then
            PianoRoll.switchRegion(0)
        end
    end




    if PianoRoll.currentView == "notes" then
        PianoRoll.handleNotesInput(currentPattern)
    elseif PianoRoll.currentView == "automation" then
        PianoRoll.handleAutomationInput(currentPattern)
    end
end

function PianoRoll.handleNotesInput(currentPattern)
    if CrankManager.forwardTick then
        PianoRoll.moveCursorUp()
    elseif CrankManager.backwardTick then
        PianoRoll.moveCursorDown()
    end

    if KeyManager.justReleased(KeyManager.keys.left) then
        PianoRoll.cursor.x = math.max(1, PianoRoll.cursor.x - 1)
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        PianoRoll.cursor.x = math.min(PianoRoll.grids.notes.maxH, PianoRoll.cursor.x + 1)
    elseif KeyManager.justReleased(KeyManager.keys.up) then
        PianoRoll.moveCursorUp()
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        PianoRoll.moveCursorDown()
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        PianoRoll.toggleNote(currentPattern)
    elseif KeyManager.isPressed(KeyManager.keys.a) then
        PianoRoll.handleNotesCombos(currentPattern)
    end
end

function PianoRoll.handleAutomationInput(currentPattern)
    if KeyManager.justReleased(KeyManager.keys.left) then
        PianoRoll.cursor.x = math.max(1, PianoRoll.cursor.x - 1)
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        PianoRoll.cursor.x = math.min(PianoRoll.grids.automation.maxH, PianoRoll.cursor.x + 1)
    elseif KeyManager.justReleased(KeyManager.keys.up) then
        PianoRoll.cursor.y = math.max(1, PianoRoll.cursor.y - 1)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        PianoRoll.cursor.y = math.min(PianoRoll.grids.automation.maxV, PianoRoll.cursor.y + 1)
    elseif KeyManager.justReleased(KeyManager.keys.a) or
        KeyManager.justComboPressed("leftA") or
        KeyManager.justComboPressed("rightA") or
        KeyManager.justComboPressed("upA") or
        KeyManager.justComboPressed("downA") then
        PianoRoll.updateAutomation(currentPattern)
    end

    if KeyManager.justComboPressed("leftA") then
        PianoRoll.cursor.x = math.max(1, PianoRoll.cursor.x - 1)
    elseif KeyManager.justComboPressed("rightA") then
        PianoRoll.cursor.x = math.min(PianoRoll.grids.automation.maxH, PianoRoll.cursor.x + 1)
    elseif KeyManager.justComboPressed("upA") then
        PianoRoll.cursor.y = math.max(1, PianoRoll.cursor.y - 1)
    elseif KeyManager.justComboPressed("downA") then
        PianoRoll.cursor.y = math.min(PianoRoll.grids.automation.maxV, PianoRoll.cursor.y + 1)
    end
end

function PianoRoll.moveCursorUp()
    if PianoRoll.cursor.y > 1 then
        PianoRoll.cursor.y = PianoRoll.cursor.y - 1
    elseif PianoRoll.cursor.y == 1 and PianoRoll.scrollOffset < 116 then
        PianoRoll.scrollOffset = PianoRoll.scrollOffset + 1
    end
end

function PianoRoll.moveCursorDown()
    if PianoRoll.cursor.y < PianoRoll.grids.notes.maxV then
        PianoRoll.cursor.y = PianoRoll.cursor.y + 1
    elseif PianoRoll.cursor.y == PianoRoll.grids.notes.maxV and PianoRoll.scrollOffset > 1 then
        PianoRoll.scrollOffset = PianoRoll.scrollOffset - 1
    end
end

function PianoRoll.toggleNote(currentPattern)
    local note = PianoRoll.scrollOffset + PianoRoll.grids.notes.maxV - PianoRoll.cursor.y
    if currentPattern.notes[PianoRoll.cursor.x] == note then
        currentPattern.notes[PianoRoll.cursor.x] = 0
    else
        currentPattern.notes[PianoRoll.cursor.x] = note
    end
end

function PianoRoll.handleNotesCombos(currentPattern)
    local note = PianoRoll.scrollOffset + PianoRoll.grids.notes.maxV - PianoRoll.cursor.y



    if KeyManager.justComboPressed("leftA") then
        currentPattern.notes[PianoRoll.cursor.x] = note
        PianoRoll.cursor.x = math.max(1, PianoRoll.cursor.x - 1)
    elseif KeyManager.justComboPressed("rightA") then
        currentPattern.notes[PianoRoll.cursor.x] = note

        PianoRoll.cursor.x = math.min(PianoRoll.grids.notes.maxH, PianoRoll.cursor.x + 1)
    elseif KeyManager.justComboPressed("upA") then
        note = PianoRoll.scrollOffset + PianoRoll.grids.notes.maxV - PianoRoll.cursor.y + 1
        currentPattern.notes[PianoRoll.cursor.x] = note
        PianoRoll.moveCursorUp()
    elseif KeyManager.justComboPressed("downA") then
        note = PianoRoll.scrollOffset + PianoRoll.grids.notes.maxV - PianoRoll.cursor.y - 1
        currentPattern.notes[PianoRoll.cursor.x] = note
        PianoRoll.moveCursorDown()
    end
end

function PianoRoll.updateAutomation(currentPattern)
    if PianoRoll.cursor.y <= 5 then
        local lengths = { 0.25, 0.5, 0.75, 1.0, PianoRoll.kLegato }
        currentPattern.length[PianoRoll.cursor.x] = lengths[PianoRoll.cursor.y]
    elseif PianoRoll.cursor.y <= 8 then
        local pans = { -1, 0, 1 }
        currentPattern.pan[PianoRoll.cursor.x] = pans[PianoRoll.cursor.y - 5]
    else
        local step = 0.1
        if KeyManager.justComboPressed("upA") then
            currentPattern.velos[PianoRoll.cursor.x] = math.min(1, currentPattern.velos[PianoRoll.cursor.x] + step)
        elseif KeyManager.justComboPressed("downA") then
            currentPattern.velos[PianoRoll.cursor.x] = math.max(0, currentPattern.velos[PianoRoll.cursor.x] - step)
        end
    end
end

function PianoRoll.drawNotes(pattern)
    if not pattern then return end

    for step, note in ipairs(pattern.notes) do
        if note ~= 0 then
            local y = PianoRoll.grids.notes.maxV - (note - PianoRoll.scrollOffset)
            if y >= 1 and y <= PianoRoll.grids.notes.maxV then
                gfx.fillRoundRect(
                    PianoRoll.cursors.notes[y][step].x + 1,
                    PianoRoll.cursors.notes[y][step].y + 1,
                    PianoRoll.cursors.notes[y][step].w - 2,
                    PianoRoll.cursors.notes[y][step].h - 2,
                    2
                )
            end
        end
    end
end

function PianoRoll.drawAutomation(pattern)
    for step, length in ipairs(pattern.length) do
        local y
        if length == PianoRoll.kLegato then
            y = 5
        elseif length == 1.0 then
            y = 4
        elseif length == 0.75 then
            y = 3
        elseif length == 0.5 then
            y = 2
        else
            y = 1
        end

        gfx.fillRoundRect(
            PianoRoll.cursors.automation[y][step].x + 1,
            PianoRoll.cursors.automation[y][step].y + 1,
            PianoRoll.cursors.automation[y][step].w - 2,
            PianoRoll.cursors.automation[y][step].h - 2,
            2
        )
    end


    for step, pan in ipairs(pattern.pan) do
        local y
        if pan == -1 then
            y = 6 -- L
        elseif pan == 0 then
            y = 7 -- C
        else
            y = 8
        end

        gfx.fillRoundRect(
            PianoRoll.cursors.automation[y][step].x + 1,
            PianoRoll.cursors.automation[y][step].y + 1,
            PianoRoll.cursors.automation[y][step].w - 2,
            PianoRoll.cursors.automation[y][step].h - 2,
            2
        )
    end


    for step, velo in ipairs(pattern.velos) do
        local cursor = PianoRoll.cursors.automation[lengthRows + panRows + 1][step]
        local fullHeight = cursor.h
        local veloHeight = math.floor(velo * fullHeight)

        gfx.fillRect(
            cursor.x + 1,
            cursor.y + fullHeight - veloHeight,
            cursor.w - 2,
            veloHeight
        )
    end
end

function PianoRoll.load()
    PianoRoll.currentTrack = 1
    PianoRoll.currentRegion = 1
    PianoRoll.scrollOffset = 63
    PianoRoll.currentView = "notes"
end

function PianoRoll.drawKeys()
    local baseNote = PianoRoll.scrollOffset - 1

    gfx.setColor(playdate.graphics.kColorBlack)

    local currentNoteIndex = (baseNote - 1) % 12 + 1
    local currentNotePattern = PianoRoll.keysLabelOptimized[currentNoteIndex]

    for i = 1, 12 do
        if currentNotePattern:sub(i, i) == '1' then
            gfx.fillRect(8, (12 - i) * 16 + 38, 47, 16)
        end
    end

    local isBlackKey = currentNotePattern:sub(12 - PianoRoll.cursor.y + 1, 12 - PianoRoll.cursor.y + 1) == '1'

    if isBlackKey then
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
    end
    local currentNoteName = PianoRoll.keyName(baseNote + PianoRoll.cursor.y - 1)
    gfx.drawText(currentNoteName, 14, PianoRoll.cursor.y * 16 - 16 + 38 + 4)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function PianoRoll.drawScrollBar()
    local currentPattern = boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack]
    for i = 1, 16 do
        local tinyX = i * 2 + 309
        local tinyY = (((127 - currentPattern.notes[i]) / 127) * 156) + 55

        if not (currentPattern.notes[i] == 0) then
            gfx.fillRect(tinyX, tinyY, 2, 2)
        end
    end

    local scrollBarY = 160 - ((PianoRoll.scrollOffset / 127) * 160)

    gfx.setColor(playdate.graphics.kColorBlack)
    gfx.setDitherPattern(0.75)
    gfx.fillRect(310, 53, 33, scrollBarY - 14)

    gfx.fillRect(310, scrollBarY + 54, 33, 240 - scrollBarY - 80)

    gfx.setColor(playdate.graphics.kColorBlack)
    gfx.drawRect(310, 39 + scrollBarY, 33, 16)
end

PianoRoll.sidebar = {}
PianoRoll.sidebar.region = {}


function PianoRoll.sidebar.draw()
end

function PianoRoll.sidebar.region.draw()
end

function PianoRoll.draw()
    -- gfx.clear()


    gfx.setColor(0)

    if PianoRoll.currentView == "notes" then
        if boat and boat.synths and boat.synths[PianoRoll.currentRegion] and boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack] then
            PianoRoll.drawNotes(boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack])
        end
        PianoRoll.drawKeys()
        PianoRoll.drawScrollBar()
    elseif PianoRoll.currentView == "automation" then
        if boat and boat.synths and boat.synths[PianoRoll.currentRegion] and boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack] then
            PianoRoll.drawAutomation(boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack])
        end
    end
    PianoRoll.sidebar.draw()
    gfx.setColor(0)
    gfx.setDitherPattern(0.75)


    if PianoRoll.currentView == "notes" then
        gfx.fillRect(
            PianoRoll.cursors.notes[1][Music.tick].x,
            PianoRoll.cursors.notes[1][1].y,
            PianoRoll.cursors.notes[1][1].w,
            200)
    elseif PianoRoll.currentView == "automation" then
        gfx.fillRect(
            PianoRoll.cursors.automation[1][Music.tick].x,
            PianoRoll.cursors.automation[1][1].y,
            PianoRoll.cursors.automation[1][1].w,
            200)
    end

    assets.drawSegments(PianoRoll.currentRegion, 365, 72)
    assets.synSelect:drawImage(PianoRoll.currentTrack, 362, 38)
end

function addNewRegionToAllSynths()
    if not boat.synths then
        boat.synths = {}
    end


    local newRegionIndex = #boat.synths + 1


    boat.synths[newRegionIndex] = {}


    for synthIndex = 1, 3 do
        local newRegion = {
            notes = {},
            length = {},
            pan = {},
            velos = {}
        }


        for i = 1, 16 do
            newRegion.notes[i] = 0
            newRegion.length[i] = 1.0
            newRegion.pan[i] = 0
            newRegion.velos[i] = 1
        end


        boat.synths[newRegionIndex][synthIndex] = newRegion
    end


    return newRegionIndex
end

function PianoRoll.switchSynth(dir)
    if dir == 1 then
        PianoRoll.currentTrack = math.min(3, PianoRoll.currentTrack + 1)
    elseif dir == 0 then
        PianoRoll.currentTrack = math.max(1, PianoRoll.currentTrack - 1)
    end
end

function PianoRoll.switchMode(mode)
    if mode == "notes" then
        cursorHold.automation, PianoRoll.currentView, PianoRoll.cursor = PianoRoll.cursor, "notes", cursorHold.notes
    elseif mode == "automation" then
        cursorHold.notes, PianoRoll.currentView, PianoRoll.cursor = PianoRoll.cursor, "automation", cursorHold
            .automation
    end
end

function PianoRoll.switchRegion(dir)
    if dir == 1 then
        if #boat.synths <= PianoRoll.currentRegion then
            addNewRegionToAllSynths()
        end
        PianoRoll.currentRegion = PianoRoll.currentRegion + 1
    elseif dir == 0 then
        PianoRoll.currentRegion = math.max(1, PianoRoll.currentRegion - 1)
    end
end

function PianoRoll.clearPattern()
    console.log("clearPattern")
    local currentPattern = boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack]
    for i = 1, 16 do
        currentPattern.notes[i] = 0
        currentPattern.length[i] = 1.0
        currentPattern.pan[i] = 0
        currentPattern.velos[i] = 1
    end
end

function PianoRoll.randomizePattern()
    console.log("randomizePattern")
    local currentPattern = boat.synths[PianoRoll.currentRegion][PianoRoll.currentTrack]


    local scale = { 60, 62, 64, 65, 67, 69, 71, 72, 74, 76 } -- C4からC5までのCメジャースケール

    -- パターン生成のパラメータ
    local noteChance = 0.7   -- 新しいノートが存在する確率
    local holdChance = 0.4   -- 直前のノートを継続する確率
    local legatoChance = 0.3 -- レガートになる確率
    local lastNote = nil     -- 直前のノート
    local isHolding = false  -- ノートを継続中かどうか


    for i = 1, 16 do
        currentPattern.notes[i] = 0
        currentPattern.length[i] = 1.0
        currentPattern.pan[i] = 0
        currentPattern.velos[i] = 1.0
    end

    -- パターンを生成
    for i = 1, 16 do
        if isHolding and lastNote then
            -- 継続中のノートを維持
            currentPattern.notes[i] = lastNote
            currentPattern.length[i - 1] = PianoRoll.kLegato
            currentPattern.velos[i] = currentPattern.velos[i - 1]
            currentPattern.pan[i] = currentPattern.pan[i - 1]


            -- ノートの継続を終了するかどうか判定
            if math.random() > holdChance then
                isHolding = false
            end
        elseif math.random() < noteChance then
            -- 新しいノートを生成
            local noteIndex = math.random(1, #scale)
            local note = scale[noteIndex]

            -- 直前のノートに近い音を選ぶ（継続中でない場合）
            if lastNote and not isHolding then
                -- 前の音から最大3度程度の移動に制限
                local currentIndex = 1
                for j, n in ipairs(scale) do
                    if n == lastNote then
                        currentIndex = j
                        break
                    end
                end
                local maxStep = 3
                local startIdx = math.max(1, currentIndex - maxStep)
                local endIdx = math.min(#scale, currentIndex + maxStep)
                noteIndex = math.random(startIdx, endIdx)
                note = scale[noteIndex]
            end

            currentPattern.notes[i] = note
            currentPattern.velos[i] = math.random(70, 100) / 100
            currentPattern.pan[i] = (math.random() - 0.5) * 0.4

            -- このノートを継続するかどうか判定
            if math.random() < holdChance then
                isHolding = true
            else
                isHolding = false
            end

            -- レガート処理（継続しない場合）
            if not isHolding and lastNote and math.random() < legatoChance then
                currentPattern.length[i - 1] = PianoRoll.kLegato
            else
                currentPattern.length[i] = math.random(2, 4) / 4
            end

            lastNote = note
        else
            -- 空白を入れる
            currentPattern.notes[i] = 0
            currentPattern.length[i] = 1.0
            lastNote = nil
            isHolding = false
        end
    end

    -- 最後のノートのレガートを解除
    currentPattern.length[16] = 1.0
end

function PianoRoll.copyPattern(sourceRegion, targetRegion)
    -- パターンをコピーする処理
    local fileList = { "File1.txt", "File2.txt", "File3.txt", "File4.txt", "File5.txt", "File6.txt", "File7.txt" }
    FileDialog.open(fileList, function(selectedFile)
        if selectedFile then
            print("Selected file: " .. selectedFile)
        else
            print("File selection cancelled")
        end
    end)
end

console.log("max" .. #boat.synths)

return PianoRoll
