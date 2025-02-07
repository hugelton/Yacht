local gfx <const> = playdate.graphics

Toolbox = {}

Toolbox.cursor = {
    x = 0,
    y = 0,
    w = 0,
    h = 0
}

Toolbox.buttons = {
    PianoRoll = {
        { name = "prev-synthnum",  x = 350, y = 38,  w = 12, h = 24, isTop = true },
        { name = "next-synthnum",  x = 380, y = 38,  w = 12, h = 24 },
        { name = "next-region",    x = 382, y = 70,  w = 8,  h = 8 },
        { name = "prev-region",    x = 382, y = 81,  w = 8,  h = 8 },

        { name = "notes",          x = 350, y = 100, w = 12, h = 24 },
        { name = "automation",     x = 380, y = 100, w = 12, h = 24 },


        { name = "clear-pattern",  x = 350, y = 134, w = 42, h = 21 },
        { name = "random-pattern", x = 350, y = 157, w = 42, h = 21 },

    },
    DrumPattern = {
        { name = "next-region", x = 382, y = 39, w = 8, h = 8, isTop = true },
        { name = "prev-region", x = 382, y = 50, w = 8, h = 8 },
    },
    SynthEdit = {
        { name = "prev-synthnum", x = 350, y = 38, w = 12, h = 24, isTop = true },
        { name = "next-synthnum", x = 380, y = 38, w = 12, h = 24 },
    },
}

Toolbox.selectedButton = 1
Toolbox.justEntered = false



Toolbox.explosion = {
    isActive = false,
    circles = {},
    maxRadius = 300,
    currentCircle = 1
}



function Toolbox.init()
    console.log("Loaded Toolbox")
end

function Toolbox.update()
    Toolbox.updateCursor()
    Toolbox.drawExplosion()
end

function Toolbox.handleInput()
    if Toolbox.dialog.isOpen then
        Toolbox.handleDialogInput()
    else
        local buttons = Toolbox.buttons[currentPage]
        if not buttons then return end

        if currentFocus == "Toolbox" then
            if Toolbox.justEntered then
                Toolbox.justEntered = false
                Toolbox.selectedButton = 1
            else
                if KeyManager.justReleased(KeyManager.keys.up) or KeyManager.justReleased(KeyManager.keys.left) then
                    if buttons[Toolbox.selectedButton].isTop then
                        currentFocus = "globalBar"
                        return
                    else
                        Toolbox.selectedButton = math.max(1, Toolbox.selectedButton - 1)
                    end
                elseif KeyManager.justReleased(KeyManager.keys.down) or KeyManager.justReleased(KeyManager.keys.right) then
                    Toolbox.selectedButton = math.min(#buttons, Toolbox.selectedButton + 1)
                elseif KeyManager.justReleased(KeyManager.keys.a) then
                    Toolbox.executeButtonAction(buttons[Toolbox.selectedButton].name)
                end
            end
        end
    end
end

function Toolbox.updateCursor()
    local buttons = Toolbox.buttons[currentPage]
    if not buttons or #buttons == 0 then
        Toolbox.cursor.x = 0
        Toolbox.cursor.y = 0
        Toolbox.cursor.w = 0
        Toolbox.cursor.h = 0
        return
    end

    if Toolbox.dialog.isOpen then
        local screenWidth, screenHeight = playdate.display.getSize()
        local dialogHeight = 120
        local optionWidth = 60
        local optionHeight = 20
        local y = (screenHeight - dialogHeight) / 2
        local optionY = y + dialogHeight - optionHeight - 10
        local centerX = screenWidth / 2

        local selectedX = centerX + (Toolbox.dialog.selection == 1 and -optionWidth - 10 or optionWidth + 10)

        Toolbox.cursor.x = selectedX - optionWidth / 2
        Toolbox.cursor.y = optionY
        Toolbox.cursor.w = optionWidth
        Toolbox.cursor.h = optionHeight
    else
        Toolbox.selectedButton = math.min(Toolbox.selectedButton, #buttons)
        local selectedButton = buttons[Toolbox.selectedButton]
        Toolbox.cursor.x = selectedButton.x
        Toolbox.cursor.y = selectedButton.y
        Toolbox.cursor.w = selectedButton.w
        Toolbox.cursor.h = selectedButton.h
    end
end

function Toolbox.executeButtonAction(buttonName)
    if currentPage == "PianoRoll" then
        if buttonName == "prev-synthnum" then
            PianoRoll.switchSynth(0)
        elseif buttonName == "next-synthnum" then
            PianoRoll.switchSynth(1)
        elseif buttonName == "prev-region" then
            if PianoRoll.currentRegion >= 1 then
                PianoRoll.switchRegion(0)
            end
        elseif buttonName == "next-region" then
            if PianoRoll.currentRegion <= 32 then
                PianoRoll.switchRegion(1)
            end
        elseif buttonName == "notes" then
            PianoRoll.switchMode("notes")
        elseif buttonName == "automation" then
            PianoRoll.switchMode("automation")
        elseif buttonName == "clear-pattern" then
            Toolbox.showDialog("Clear pattern?", function(result)
                if result == "Yes" then
                    Toolbox.startExplosionEffect()
                    PianoRoll.clearPattern()
                end
            end)
        elseif buttonName == "random-pattern" then
            Toolbox.showDialog("Generate random pattern?", function(result)
                if result == "Yes" then
                    PianoRoll.randomizePattern()
                end
            end)
        elseif buttonName == "copy-pattern" then
            PianoRoll.copyPattern()
        end
    elseif currentPage == "DrumPattern" then
        if buttonName == "prev-region" then
            if DrumPattern.currentRegion >= 1 then
                DrumPattern.switchRegion(-1)
            end
        elseif buttonName == "next-region" then
            if DrumPattern.currentRegion <= 32 then
                DrumPattern.switchRegion(1)
            end
        elseif buttonName == "clear-pattern" then

        end
    elseif currentPage == "SynthEdit" then
        if buttonName == "prev-synthnum" then
            SynthEdit.switchSynth(0)
        elseif buttonName == "next-synthnum" then
            SynthEdit.switchSynth(1)
        end
    end
end

function Toolbox.setCurrentPage(page)
    Toolbox.currentPage = page
    Toolbox.selectedButton = 1
    Toolbox.justEntered = true
    Toolbox.updateCursor()
end

function Toolbox.onPageChange(newPage)
    Toolbox.setCurrentPage(newPage)
    Toolbox.dialog.isOpen = false
end

function Toolbox.enterToolbox()
    Toolbox.justEntered = true
    Toolbox.selectedButton = 1
end

Toolbox.dialog = {
    isOpen = false,
    message = "",
    callback = nil,
    selection = 2,
}

function Toolbox.showDialog(message, callback)
    Toolbox.dialog.isOpen = true
    Toolbox.dialog.message = message
    Toolbox.dialog.callback = callback
    Toolbox.dialog.selection = 1
end

function Toolbox.handleDialogInput()
    if KeyManager.justReleased(KeyManager.keys.left) or KeyManager.justReleased(KeyManager.keys.right) then
        Toolbox.dialog.selection = 3 - Toolbox.dialog.selection
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        local result = Toolbox.dialog.selection == 1 and "Yes" or "No"
        Toolbox.dialog.isOpen = false
        if Toolbox.dialog.callback then
            Toolbox.dialog.callback(result)
        end
    elseif KeyManager.justReleased(KeyManager.keys.b) then
        Toolbox.dialog.isOpen = false
        if Toolbox.dialog.callback then
            Toolbox.dialog.callback("Cancel")
        end
    end
end

function Toolbox.drawDialog()
    local screenWidth, screenHeight = playdate.display.getSize()
    local dialogWidth, dialogHeight = 300, 120
    local x = (screenWidth - dialogWidth) / 2
    local y = (screenHeight - dialogHeight) / 2


    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, dialogWidth, dialogHeight, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, dialogWidth, dialogHeight, 10)


    gfx.drawTextAligned(Toolbox.dialog.message, screenWidth / 2, y + 20, kTextAlignment.center)


    local optionWidth = 60
    local optionHeight = 20
    local optionY = y + dialogHeight - optionHeight - 10
    local centerX = screenWidth / 2

    gfx.drawTextAligned("Yes", centerX - optionWidth - 10, optionY + 5, kTextAlignment.center)
    gfx.drawRoundRect(centerX - optionWidth * 1.5 - 10, optionY, optionWidth, optionHeight, 3)

    gfx.drawTextAligned("No", centerX + optionWidth + 10, optionY + 5, kTextAlignment.center)
    gfx.drawRoundRect(centerX + optionWidth * 0.5 + 10, optionY, optionWidth, optionHeight, 3)


    local selectedX = centerX + (Toolbox.dialog.selection == 1 and -optionWidth - 10 or optionWidth + 10)
    gfx.drawRoundRect(selectedX - optionWidth / 2, optionY, optionWidth, optionHeight, 3)
end

function Toolbox.drawExplosion()
    if not Toolbox.explosion.isActive then return end


    local centerX, centerY = 200, 120



    for i, circle in ipairs(Toolbox.explosion.circles) do
        circle.radius = circle.radius + (Toolbox.explosion.maxRadius / 30)


        if circle.isWhite then
            gfx.setColor(gfx.kColorWhite)
        else
            gfx.setColor(gfx.kColorBlack)
        end


        gfx.fillCircleAtPoint(centerX, centerY, circle.radius)
    end


    gfx.setColor(gfx.kColorBlack)
end

function Toolbox.startExplosionEffect()
    Toolbox.explosion.isActive = true
    Toolbox.explosion.circles = {}
    Toolbox.explosion.currentCircle = 1


    local function createNextCircle()
        if Toolbox.explosion.currentCircle <= 8 then
            table.insert(Toolbox.explosion.circles, {
                radius = 0,
                isWhite = (Toolbox.explosion.currentCircle % 2 == 0)
            })
            Toolbox.explosion.currentCircle = Toolbox.explosion.currentCircle + 1


            if Toolbox.explosion.currentCircle <= 16 then
                playdate.timer.new(62.5, createNextCircle)
            end
        end
    end


    createNextCircle()


    playdate.timer.new(1000, function()
        Toolbox.explosion.isActive = false
        Toolbox.explosion.circles = {}
    end)
end

return Toolbox
