local gfx <const> = playdate.graphics

cursor = {}

cursor.target = { x = 0, y = 0, w = 0, h = 0 }
cursor.current = { x = 0, y = 0, w = 0, h = 0 }
cursor.alpha = 0.7
cursor.isVisible = true


cursor.blinker = gfx.animation.blinker.new(60, 60, true)
cursor.blinker:startLoop()




function cursor.hide()
    cursor.isVisible = false
end

function cursor.show()
    cursor.isVisible = true
end

function cursor.move(x, y, w, h)
    cursor.target.x = x
    cursor.target.y = y
    cursor.target.w = w
    cursor.target.h = h
end

function cursor.update()
    if not cursor.isVisible then
        return
    end
    cursor.blinker:update()
    if (not playdate.getReduceFlashing()) then
        if cursor.blinker.on then
            playdate.graphics.setColor(gfx.kColorWhite)
        else
            playdate.graphics.setColor(gfx.kColorBlack)
        end
    end


    cursor.current.x = cursor.current.x + cursor.alpha * (cursor.target.x - cursor.current.x)
    cursor.current.y = cursor.current.y + cursor.alpha * (cursor.target.y - cursor.current.y)
    cursor.current.w = cursor.current.w + cursor.alpha * (cursor.target.w - cursor.current.w)
    cursor.current.h = cursor.current.h + cursor.alpha * (cursor.target.h - cursor.current.h)

    local armLength = math.max(2, math.min(cursor.current.w, cursor.current.h) * 0.3)

    gfx.setLineWidth(2)
    playdate.graphics.setLineCapStyle(playdate.graphics.kLineCapStyleRound)


    --- aim left top corner
    gfx.drawLine(
        cursor.current.x,
        cursor.current.y,
        cursor.current.x,
        cursor.current.y + armLength)
    gfx.drawLine(
        cursor.current.x,
        cursor.current.y,
        cursor.current.x + armLength,
        cursor.current.y)

    --- aim right top corner
    gfx.drawLine(
        cursor.current.x + cursor.current.w,
        cursor.current.y,
        cursor.current.x + cursor.current.w,
        cursor.current.y + armLength)
    gfx.drawLine(
        cursor.current.x + cursor.current.w,
        cursor.current.y,
        cursor.current.x + cursor.current.w - armLength,
        cursor.current.y)



    --- aim right bottom corner
    gfx.drawLine(
        cursor.current.x + cursor.current.w,
        cursor.current.y + cursor.current.h,
        cursor.current.x + cursor.current.w - armLength,
        cursor.current.y + cursor.current.h)
    gfx.drawLine(
        cursor.current.x + cursor.current.w,
        cursor.current.y + cursor.current.h,
        cursor.current.x + cursor.current.w,
        cursor.current.y + cursor.current.h - armLength)

    --- aim left bottom corner
    gfx.drawLine(
        cursor.current.x,
        cursor.current.y + cursor.current.h,
        cursor.current.x,
        cursor.current.y + cursor.current.h - armLength)
    gfx.drawLine(
        cursor.current.x,
        cursor.current.y + cursor.current.h,
        cursor.current.x + armLength,
        cursor.current.y + cursor.current.h)




    gfx.setLineWidth(1)

    if currentFocus == "globalBar" then
        if GlobalBar.cursor.x then
            cursor.move(
                GlobalBar.cursors[GlobalBar.cursor.x].x,
                GlobalBar.cursors[GlobalBar.cursor.x].y,
                GlobalBar.cursors[GlobalBar.cursor.x].w,
                GlobalBar.cursors[GlobalBar.cursor.x].h)
        end
    elseif currentFocus == "sideBar" then
        cursor.move(10, 10, 30, 30)
    elseif currentFocus == "pageSwitcher" then
        cursor.move(
            PageSwitcher.cursor.x, PageSwitcher.cursor.y, PageSwitcher.cursor.w, PageSwitcher.cursor.h)
    elseif currentFocus == "main" then
        if currentPage == "PianoRoll" then
            if PianoRoll.currentView == "notes" then
                if PianoRoll.cursor.x then
                    cursor.move(
                        PianoRoll.cursors.notes[PianoRoll.cursor.y][PianoRoll.cursor.x].x,
                        PianoRoll.cursors.notes[PianoRoll.cursor.y][PianoRoll.cursor.x].y,
                        PianoRoll.cursors.notes[PianoRoll.cursor.y][PianoRoll.cursor.x].w,
                        PianoRoll.cursors.notes[PianoRoll.cursor.y][PianoRoll.cursor.x].h)
                end
            elseif PianoRoll.currentView == "automation" then
                if PianoRoll.cursor.x then
                    cursor.move(
                        PianoRoll.cursors.automation[PianoRoll.cursor.y][PianoRoll.cursor.x].x,
                        PianoRoll.cursors.automation[PianoRoll.cursor.y][PianoRoll.cursor.x].y,
                        PianoRoll.cursors.automation[PianoRoll.cursor.y][PianoRoll.cursor.x].w,
                        PianoRoll.cursors.automation[PianoRoll.cursor.y][PianoRoll.cursor.x].h)
                end
            end
        elseif currentPage == "DrumPattern" then
            if DrumPattern.cursor.x then
                cursor.move(
                    DrumPattern.cursors[DrumPattern.cursor.y][DrumPattern.cursor.x].x,
                    DrumPattern.cursors[DrumPattern.cursor.y][DrumPattern.cursor.x].y,
                    DrumPattern.cursors[DrumPattern.cursor.y][DrumPattern.cursor.x].w,
                    DrumPattern.cursors[DrumPattern.cursor.y][DrumPattern.cursor.x].h)
            end
        elseif currentPage == "SynthEdit" then
            cursor.move(
                SynthEdit.cursor.x, SynthEdit.cursor.y, SynthEdit.cursor.w, SynthEdit.cursor.h)
        elseif currentPage == "DrumEdit" then
            cursor.move(
                DrumEdit.cursor.x, DrumEdit.cursor.y, DrumEdit.cursor.w, DrumEdit.cursor.h)
        elseif currentPage == "Mixer" then
            cursor.move(
                Mixer.cursor.x, Mixer.cursor.y, Mixer.cursor.w, Mixer.cursor.h)
        elseif currentPage == "SongEdit" then
            cursor.move(
                SongEdit.cursor.x, SongEdit.cursor.y, SongEdit.cursor.w, SongEdit.cursor.h)
        elseif currentPage == "Preferences" then
            cursor.move(
                Preferences.cursor.x, Preferences.cursor.y, Preferences.cursor.w, Preferences.cursor.h
            )
        elseif currentPage == "Visualizer" then
            cursor.move(
                -1, -1, 402, 242
            )
        end
    elseif currentFocus == "Toolbox" then
        cursor.move(
            Toolbox.cursor.x, Toolbox.cursor.y, Toolbox.cursor.w, Toolbox.cursor.h)
    end
    if currentFocus == "globalBar" or
        currentFocus == "pageSwitcher" or
        currentFocus == "Toolbox" or

        currentFocus == "main" and currentPage == "Preferences"
    then
        if KeyManager.isPressed(KeyManager.keys.a) then
            gfx.setColor(gfx.kColorXOR)

            gfx.fillRect(cursor.current.x,
                cursor.current.y,
                cursor.current.w,
                cursor.current.h)


            gfx.setColor(gfx.kColorBlack)
        end
    end
end
