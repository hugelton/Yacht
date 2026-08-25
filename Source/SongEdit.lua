local gfx <const> = playdate.graphics

SongEdit = {}

SongEdit.cursor = { x = 1, y = 1, w = 1, h = 1 }
SongEdit.scrollOffset = 0
SongEdit.maxRegions = 64
SongEdit.songLength = 64
SongEdit.tracksCount = 5 -- length, synth1, synth2, synth3, drums
SongEdit.selectedUI = "grid"

-- グリッドの設定
local startX, startY = 72, 88
local cellWidth, cellHeight = 32, 16
local trackHeight = 28
local trackOffset = 0

local cursorX, cursorY = 1, 1
SongEdit.cursors = {}

SongEdit.endType = "none" -- "none", "coda", "d.c."のいずれか




for y = 1, SongEdit.tracksCount do
    SongEdit.cursors[y] = {}
    for x = 1, 10 do
        local yPos
        if y == 1 then
            yPos = startY
        else
            yPos = startY + cellHeight + (y - 2) * trackHeight - trackOffset
        end
        local height = (y == 1) and cellHeight or trackHeight
        SongEdit.cursors[y][x] = {
            x = startX + ((x - 1) * cellWidth),
            y = yPos,
            w = cellWidth - 1,
            h = height - 1
        }
    end
end



function SongEdit.load()
    cursorX = 1
    cursorY = 1
    SongEdit.scrollOffset = 0
    SongEdit.endType = keel.loop and "d.c." or "coda"
    Music.setSongLoop(keel.loop == true)
end

function SongEdit.init()
    console.log("Initializing SongEdit")
    cursorX, cursorY = 1, 1
    SongEdit.scrollOffset = 0
    Music.maxRegion = Music.maxRegion or 64

    SongEdit.endType = keel.loop and "d.c." or "coda"
    Music.setSongLoop(keel.loop == true)

    console.log("SongEdit initialization complete")
end

local function moveCursorRight()
    if cursorX < 10 then
        cursorX = cursorX + 1
    elseif SongEdit.scrollOffset < SongEdit.songLength - 10 then
        SongEdit.scrollOffset = SongEdit.scrollOffset + 1
    end
end

local function moveCursorLeft()
    if cursorX > 1 then
        cursorX = cursorX - 1
    elseif SongEdit.scrollOffset > 0 then
        SongEdit.scrollOffset = SongEdit.scrollOffset - 1
    end
end

function SongEdit.handleInput()
    if KeyManager.justReleased(KeyManager.keys.left) then
        moveCursorLeft()
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        moveCursorRight()
    elseif KeyManager.justReleased(KeyManager.keys.up) then
        cursorY = math.max(1, cursorY - 1)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        cursorY = math.min(SongEdit.tracksCount, cursorY + 1)
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        if cursorY == 1 then
            SongEdit.toggleLength()
        else
            SongEdit.toggleRegion()
        end
    elseif KeyManager.justComboReleased("upA") then
        SongEdit.incrementRegion()
    elseif KeyManager.justComboReleased("downA") then
        SongEdit.decrementRegion()
    elseif KeyManager.justComboReleased("leftA") then
        if SongEdit.copyRegionLeft() then moveCursorLeft() end
    elseif KeyManager.justComboReleased("rightA") then
        if SongEdit.copyRegionRight() then moveCursorRight() end
    end

    if CrankManager.forwardTick then
        moveCursorRight()
    elseif CrankManager.backwardTick then
        moveCursorLeft()
    end



    SongEdit.cursor.x = SongEdit.cursors[cursorY][cursorX].x
    SongEdit.cursor.y = SongEdit.cursors[cursorY][cursorX].y
    SongEdit.cursor.w = SongEdit.cursors[cursorY][cursorX].w
    SongEdit.cursor.h = SongEdit.cursors[cursorY][cursorX].h
end

function SongEdit.toggleLength()
    local position = SongEdit.scrollOffset + cursorX
    if position == keel.songEnd then
        if SongEdit.endType == "none" then
            SongEdit.endType = "coda"
            keel.loop = false
            Music.setSongLoop(false)
        elseif SongEdit.endType == "coda" then
            SongEdit.endType = "d.c."
            keel.loop = true
            Music.setSongLoop(true)
        else -- "d.c."の場合
            -- codaとD.C.を解除し、songEndを短くする
            SongEdit.endType = "none"
            keel.songEnd = math.max(1, keel.songEnd - 1)
            keel.loop = false
            Music.setSongLoop(false)
        end
    else
        -- 新しい位置にsongEndを設定し、codaを設定
        keel.songEnd = position
        SongEdit.endType = "coda"
        keel.loop = false
        Music.setSongLoop(false)
    end
end

-- The arrangement lives in keel; the length row (cursorY == 1) has no region
-- value of its own, so every helper below is a no-op there.
local function selectedTrack()
    if cursorY <= 1 then return nil end
    return SongEdit.getTrackName(cursorY), SongEdit.scrollOffset + cursorX
end

function SongEdit.toggleRegion()
    local trackName, position = selectedTrack()
    if not trackName then return false end
    keel[trackName][position] = (keel[trackName][position] or 0) == 0 and 1 or 0
    return true
end

function SongEdit.incrementRegion()
    local trackName, position = selectedTrack()
    if not trackName then return false end
    keel[trackName][position] = math.min(SongEdit.maxRegions, (keel[trackName][position] or 0) + 1)
    return true
end

function SongEdit.decrementRegion()
    local trackName, position = selectedTrack()
    if not trackName then return false end
    keel[trackName][position] = math.max(0, (keel[trackName][position] or 0) - 1)
    return true
end

function SongEdit.copyRegionLeft()
    local trackName, position = selectedTrack()
    if not trackName or position <= 1 then return false end
    keel[trackName][position - 1] = keel[trackName][position] or 0
    return true
end

function SongEdit.copyRegionRight()
    local trackName, position = selectedTrack()
    if not trackName or position >= SongEdit.songLength then return false end
    keel[trackName][position + 1] = keel[trackName][position] or 0
    return true
end

function SongEdit.draw()
    -- グリッドの描画
    for y = 1, SongEdit.tracksCount do
        local trackName = SongEdit.getTrackName(y)
        for x = 1, 10 do
            local gridPosition = SongEdit.scrollOffset + x
            if gridPosition <= SongEdit.maxRegions then
                if y == 1 then -- lengthトラック
                    local textWidth, textHeight = gfx.getTextSize(gridPosition)
                    local textX = SongEdit.cursors[y][x].x + (SongEdit.cursors[y][x].w - textWidth) / 2
                    local textY = SongEdit.cursors[y][x].y + (SongEdit.cursors[y][x].h - textHeight) / 2 - 16
                    gfx.drawText(gridPosition, textX, textY)
                else -- その他のトラック
                    local region = keel[trackName][gridPosition] or 0
                    if region > 0 then
                        gfx.drawRoundRect(
                            SongEdit.cursors[y][x].x + 1,
                            SongEdit.cursors[y][x].y + 1,
                            SongEdit.cursors[y][x].w - 2,
                            SongEdit.cursors[y][x].h - 2,
                            2
                        )
                        local regionText = tostring(region)
                        local textWidth, textHeight = gfx.getTextSize("*" .. regionText .. "*")
                        local textX = SongEdit.cursors[y][x].x + (SongEdit.cursors[y][x].w - textWidth) / 2
                        local textY = SongEdit.cursors[y][x].y + (SongEdit.cursors[y][x].h - textHeight) / 2

                        assets.drawSegments(regionText, textX - 5, textY - 2)
                    end
                end
            end
        end
    end




    local scrollBarXpos = 26 + (328 * (SongEdit.scrollOffset / 54))
    gfx.fillRoundRect(scrollBarXpos, 217, 20, 13, 2)

    local endPos = 26 + (328 * (keel.songEnd / 54))






    if SongEdit.endType == "coda" then
        assets.songLoopModes:drawImage(1, endPos, 216)
        assets.fonts.cavs:drawTextAligned("Coda", 40, 90, kTextAlignment.center)
    elseif SongEdit.endType == "d.c." then
        assets.songLoopModes:drawImage(2, endPos, 216)
        assets.fonts.cavs:drawTextAligned("D.C.", 40, 90, kTextAlignment.center)
    else
        assets.fonts.cavs:drawTextAligned("End", 40, 90, kTextAlignment.center)
    end

    gfx.drawText(Music.currentPosition .. "  /  " .. keel.songEnd, 300, 50)



    local locationBarX = Music.currentPosition - SongEdit.scrollOffset
    if locationBarX > 0 and locationBarX <= 10 then
        gfx.setLineWidth(2)
        gfx.drawRect(
            SongEdit.cursors[1][locationBarX].x + 1,
            SongEdit.cursors[1][1].y + 1,
            29,
            SongEdit.cursors[SongEdit.tracksCount][1].y + SongEdit.cursors[SongEdit.tracksCount][1].h -
            SongEdit.cursors[1][1].y - 2
        )
        gfx.setLineWidth(1)
    end

    if SongEdit.scrollOffset + 10 >= keel.songEnd then
        local endIndex = math.min(10, keel.songEnd - SongEdit.scrollOffset)
        if endIndex > 0 then
            local endX = SongEdit.cursors[1][endIndex].x
            local endY = SongEdit.cursors[1][endIndex].y
            local endWidth = SongEdit.cursors[1][1].w
            local endHeight = SongEdit.cursors[1][1].h



            if SongEdit.endType ~= "none" then
                local x = endX + (endWidth - 32) / 2
                local y = endY + (endHeight - 16) / 2








                if SongEdit.endType == "coda" then
                    assets.songLoopModes:drawImage(1, x, y)
                else
                    assets.songLoopModes:drawImage(2, x, y)
                end
            end
        end
    end
end

function SongEdit.getTrackName(index)
    local trackNames = { "length", "synth1", "synth2", "synth3", "drums" }
    return trackNames[index]
end

return SongEdit
