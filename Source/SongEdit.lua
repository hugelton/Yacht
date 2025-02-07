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
    SongEdit.endType = "none"


    if not keel.songEnd then

    end


    Music.setSongLoop(SongEdit.endType == "d.c.")
end

function SongEdit.init()
    console.log("Initializing SongEdit")
    cursorX, cursorY = 1, 1
    SongEdit.scrollOffset = 0
    Music.maxRegion = Music.maxRegion or 64


    if not mast.song then
        mast.song = {
            length = {},
            synth1 = {},
            synth2 = {},
            synth3 = {},
            drums = {}
        }
        for i = 1, Music.maxRegion do
            mast.song.length[i] = (i <= Music.maxRegion and 1 or 0)
            mast.song.synth1[i] = 0
            mast.song.synth2[i] = 0
            mast.song.synth3[i] = 0
            mast.song.drums[i] = 0
        end
    end

    console.log("SongEdit initialization complete")
end

function SongEdit.handleInput()
    if KeyManager.justReleased(KeyManager.keys.left) then
        cursorX = math.max(1, cursorX - 1)
        if cursorX == 1 and SongEdit.scrollOffset > 0 then
            SongEdit.scrollOffset = SongEdit.scrollOffset - 1
        end
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        if cursorX < 10 or (cursorX == 10 and SongEdit.scrollOffset < SongEdit.songLength - 10) then
            cursorX = math.min(10, cursorX + 1)
            if cursorX == 10 and SongEdit.scrollOffset < SongEdit.songLength - 10 then
                SongEdit.scrollOffset = SongEdit.scrollOffset + 1
            end
        end
    elseif KeyManager.justReleased(KeyManager.keys.up) then
        cursorY = math.max(1, cursorY - 1)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        cursorY = math.min(SongEdit.tracksCount, cursorY + 1)
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        local position = SongEdit.scrollOffset + cursorX
        if cursorY == 1 then
            SongEdit.toggleLength()
        else
            local trackName = SongEdit.getTrackName(cursorY)
            if keel[trackName][position] == 0 then
                keel[trackName][position] = 1
            else
                keel[trackName][position] = 0
            end
        end
    elseif KeyManager.justComboReleased("upA") then
        if cursorY > 1 then
            local trackName = SongEdit.getTrackName(cursorY)
            local position = SongEdit.scrollOffset + cursorX
            keel[trackName][position] = math.min(SongEdit.maxRegions, (keel[trackName][position] or 0) + 1)
        end
    elseif KeyManager.justComboReleased("downA") then
        if cursorY > 1 then
            local trackName = SongEdit.getTrackName(cursorY)
            local position = SongEdit.scrollOffset + cursorX
            keel[trackName][position] = math.max(0, (keel[trackName][position] or 0) - 1)
        end
    end

    if CrankManager.forwardTick then
        if cursorX < 10 or (cursorX == 10 and SongEdit.scrollOffset < SongEdit.songLength - 10) then
            cursorX = math.min(10, cursorX + 1)
            if cursorX == 10 and SongEdit.scrollOffset < SongEdit.songLength - 10 then
                SongEdit.scrollOffset = SongEdit.scrollOffset + 1
            end
        end
    elseif CrankManager.backwardTick then
        cursorX = math.max(1, cursorX - 1)
        if cursorX == 1 and SongEdit.scrollOffset > 0 then
            SongEdit.scrollOffset = SongEdit.scrollOffset - 1
        end
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
            Music.setSongLoop(false)
        elseif SongEdit.endType == "coda" then
            SongEdit.endType = "d.c."
            Music.setSongLoop(true)
        else -- "d.c."の場合
            -- codaとD.C.を解除し、songEndを短くする
            SongEdit.endType = "none"
            keel.songEnd = math.max(1, keel.songEnd - 1)
            Music.setSongLoop(false)
        end
    else
        -- 新しい位置にsongEndを設定し、codaを設定
        keel.songEnd = position
        SongEdit.endType = "coda"
        Music.setSongLoop(false)
    end
end

function SongEdit.toggleRegion()
    local trackName = SongEdit.getTrackName(cursorY)
    local position = SongEdit.scrollOffset + cursorX
    if mast.song[trackName][position] == 0 then
        mast.song[trackName][position] = 1
    else
        mast.song[trackName][position] = 0
    end
end

function SongEdit.incrementRegion()
    local trackName = SongEdit.getTrackName(cursorY)
    local position = SongEdit.scrollOffset + cursorX
    mast.song[trackName][position] = math.min(SongEdit.maxRegions, mast.song[trackName][position] + 1)
end

function SongEdit.decrementRegion()
    local trackName = SongEdit.getTrackName(cursorY)
    local position = SongEdit.scrollOffset + cursorX
    mast.song[trackName][position] = math.max(0, mast.song[trackName][position] - 1)
end

function SongEdit.copyRegionLeft()
    local trackName = SongEdit.getTrackName(cursorY)
    local position = SongEdit.scrollOffset + cursorX
    if position > 1 then
        mast.song[trackName][position - 1] = mast.song[trackName][position]
    end
end

function SongEdit.copyRegionRight()
    local trackName = SongEdit.getTrackName(cursorY)
    local position = SongEdit.scrollOffset + cursorX
    if position < SongEdit.songLength then
        mast.song[trackName][position + 1] = mast.song[trackName][position]
    end
end

function SongEdit.draw()
    -- グリッドの描画
    for y = 1, SongEdit.tracksCount do
        local trackName = SongEdit.getTrackName(y)
        for x = 1, 10 do
            local gridPosition = SongEdit.scrollOffset + x
            if gridPosition <= SongEdit.maxRegions then
                if y == 1 then -- lengthトラック
                    local regionText = tostring(region)
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
    else
        assets.songLoopModes:drawImage(2, endPos, 216)
        assets.fonts.cavs:drawTextAligned("D.C.", 40, 90, kTextAlignment.center)
    end

    gfx.drawText(Music.currentPosition .. "  /  " .. SongEdit.scrollOffset, 300, 50)



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
