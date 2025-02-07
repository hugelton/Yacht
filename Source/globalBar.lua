-- Grobalbar.lua
local gfx <const> = playdate.graphics

GlobalBar = {}

GlobalBar.backgroundImage = playdate.graphics.image.new("Images/ribbon")

local offsetY = 7
local buttonHeight = 23
GlobalBar.buttons = {
    { label = "Name",  w = 92, x = 8,   getValue = function() return mast.name end },
    { label = "BPM",   w = 55, x = 102, getValue = function() return string.format("%.1f", mast.bpm) end },
    { label = "Swing", w = 42, x = 158, getValue = function() return string.format("%d%%", mast.swing) end },
    { label = "Tick",  w = 32, x = 200, getValue = function() return tostring(Music.tick) end },
    { label = "Play",  w = 25, x = 231, getValue = function() return mast.isPlaying and true or false end },
    { label = "Mode",  w = 24, x = 259, getValue = function() return Music.mode end },
    {
        label = "modeNum",
        w = 32,
        x = 283,
        getValue = function()
            if Music.mode == "region" then
                return Music.currentPositionP
            else
                return Music.currentPosition
            end
        end
    },
    {
        label = "solo",
        w = 24,
        x = 318
        ,
        getValue = function()

        end
    },
    { label = "Switcher", w = 40, x = 350, getValue = function() return "Switcher" end },
}
GlobalBar.cursor = { x = 9, y = 1 }
GlobalBar.cursors = {}

local function updateCursors()
    GlobalBar.cursors = {}
    for i, button in ipairs(GlobalBar.buttons) do
        table.insert(GlobalBar.cursors, {
            x = button.x,
            y = offsetY,
            w = button.w,
            h = buttonHeight
        })
    end
end

updateCursors()

local isKeyboardOpen = false

function GlobalBar.init()
    updateCursors()
end

function GlobalBar.handleInput()
    if isKeyboardOpen then
        return
    end
    local selectedButton = GlobalBar.buttons[GlobalBar.cursor.x]
    if KeyManager.justPressed(KeyManager.keys.left) then
        GlobalBar.cursor.x = math.max(1, GlobalBar.cursor.x - 1)
    elseif KeyManager.justPressed(KeyManager.keys.right) then
        GlobalBar.cursor.x = math.min(#GlobalBar.cursors, GlobalBar.cursor.x + 1)
    end


    if KeyManager.justReleased(KeyManager.keys.a) then
        if selectedButton.label == "Name" then
            isKeyboardOpen = true
            playdate.keyboard.show(mast.name)
            currentFocus = "keyboard"
        elseif selectedButton.label == "Play" then
            Music.flipState()
        elseif selectedButton.label == "Mode" then
            Music.flipMode()
        elseif selectedButton.label == "Loop" then
            Music.songLoop = not Music.songLoop
        elseif selectedButton.label == "Switcher" then
            console.log("Switch.")
            PageSwitcher.open()
            currentFocus = "pageSwitcher"
        elseif selectedButton.label == "solo" then
            local soloTrack
            if currentPage == "PianoRoll" or currentPage == "SynthEdit" then
                local trackIndex = currentPage == "PianoRoll" and PianoRoll.currentTrack or SynthEdit.targetNum
                soloTrack = "synth" .. trackIndex
            elseif currentPage == "DrumPattern" or currentPage == "DrumEdit" then
                soloTrack = "drums"
            end
            if soloTrack then
                Sounds.solo(soloTrack)
            end
        end
    end


    if KeyManager.justReleased(KeyManager.keys.down) then
        if selectedButton.label == "Switcher" then
            if currentPage == "PianoRoll" or currentPage == "DrumPattern" or currentPage == "SynthEdit" then
                console.log("GlobalBar: Moving to Toolbox")
                currentFocus = "Toolbox"
                Toolbox.enterToolbox()
            end
        else
            currentFocus = "main"
        end
    end


    if selectedButton.label == "Switcher" then
        -- currentPage = "PianoRoll"
        if CrankManager.forwardTick then
            -- mast.bpm = math.max(20, mast.bpm - 0.1)



            if currentPage == "PianoRoll" then

            elseif currentPage == "DrumPattern" then
                currentPage = "PianoRoll"
            elseif currentPage == "SynthEdit" then
                currentPage = "DrumPattern"
            elseif currentPage == "DrumEdit" then
                currentPage = "SynthEdit"
            elseif currentPage == "Mixer" then
                currentPage = "DrumEdit"
            elseif currentPage == "SongEdit" then
                currentPage = "Mixer"
            elseif currentPage == "Visualizer" then
                currentPage = "SongEdit"
            elseif currentPage == "Preferences" then
                currentPage = "Visualizer"
            end
        elseif CrankManager.backwardTick then
            -- mast.bpm = math.min(300, mast.bpm + 0.1)
            if currentPage == "PianoRoll" then
                currentPage = "DrumPattern"
            elseif currentPage == "DrumPattern" then
                currentPage = "SynthEdit"
            elseif currentPage == "SynthEdit" then
                currentPage = "DrumEdit"
            elseif currentPage == "DrumEdit" then
                currentPage = "Mixer"
            elseif currentPage == "Mixer" then
                currentPage = "SongEdit"
            elseif currentPage == "SongEdit" then
                currentPage = "Visualizer"
            elseif currentPage == "Visualizer" then
                currentPage = "Preferences"
            elseif currentPage == "Preferences" then

            end
        end
    end

    -- テンポとスイングの調整

    if selectedButton.label == "BPM" then
        if KeyManager.justComboPressed("upA") then
            mast.bpm = math.min(300, mast.bpm + 1)
        elseif KeyManager.justComboPressed("downA") then
            mast.bpm = math.max(20, mast.bpm - 1)
        elseif CrankManager.forwardTick then
            mast.bpm = math.min(300, mast.bpm + 0.1)
        elseif CrankManager.backwardTick then
            mast.bpm = math.max(20, mast.bpm - 0.1)
        end
    elseif selectedButton.label == "Swing" then
        if KeyManager.justComboPressed("upA") or CrankManager.forwardTick then
            mast.swing = math.min(50, mast.swing + 1)
        elseif KeyManager.justComboPressed("downA") or CrankManager.backwardTick then
            mast.swing = math.max(0, mast.swing - 1)
        end
    elseif selectedButton.label == "modeNum" then
        if Music.mode == "region" then
            -- リージョンモードの時は存在するリージョンの範囲内でのみ移動
            if KeyManager.justComboPressed("upA") or CrankManager.forwardTick then
                -- 存在するリージョンの最大数を取得 (#boat.synths または #boat.drums の大きい方)
                local maxRegion = math.max(#boat.synths, #boat.drums)
                Music.currentPosition = math.min(maxRegion, Music.currentPosition + 1)
            elseif KeyManager.justComboPressed("downA") or CrankManager.backwardTick then
                Music.currentPosition = math.max(1, Music.currentPosition - 1)
            end
        else
            -- ソングモードの時は songEnd までの範囲で移動可能
            if KeyManager.justComboPressed("upA") or CrankManager.forwardTick then
                Music.currentPosition = math.min(keel.songEnd, Music.currentPosition + 1)
            elseif KeyManager.justComboPressed("downA") or CrankManager.backwardTick then
                Music.currentPosition = math.max(1, Music.currentPosition - 1)
            end
        end
    end
end

function GlobalBar.draw()
    GlobalBar.backgroundImage:draw(0, 0)

    for i, button in ipairs(GlobalBar.buttons) do
        local value = button.getValue()

        if button.label == "BPM" then
            gfx.drawTextAligned("*" .. value .. "*", button.x + button.w + 2, 14, kTextAlignment.right)
        elseif button.label == "Swing" then
            gfx.drawTextAligned("*" .. value .. "*", button.x + button.w + 4, 14, kTextAlignment.right)
        elseif button.label == "Tick" then
            gfx.drawTextAligned("*" .. value .. "*", button.x + button.w + 4, 14, kTextAlignment.right)
        elseif button.label == "Name" then
            gfx.drawTextAligned("*" .. value .. "*", button.x + 4, 14, kTextAlignment.left)
        elseif button.label == "Play" then
            -- gfx.drawTextAligned("*" .. value .. "*", button.x + button.w / 2, 14, kTextAlignment.center)



            if value then
                assets.plays:drawImage(1, button.x + 1, 7 - 1)
            else
                assets.plays:drawImage(2, button.x + 1, 7 - 1)
            end
        elseif button.label == "Mode" then
            if Music.mode == "region" then
                assets.mode:drawImage(1, button.x, 7)
            elseif Music.mode == "song" then
                assets.mode:drawImage(2, button.x, 7)
            end
        elseif button.label == "modeNum" then
            if Music.mode == "region" then
                assets.drawSegments(Music.currentPosition, button.x + 8, 11)
            else
                gfx.drawTextAligned("*" .. Music.currentPosition .. "*", button.x + 22, 14, kTextAlignment.center)
            end
        elseif button.label == "solo" then
            --
            if Sounds.hasSolo() then
                -- Sounds.soloState
                assets.solos:drawImage(2, button.x + 1, 7 - 1)
                -- gfx.drawTextAligned("*S*", button.x + button.w / 2, 14, kTextAlignment.center)
            else
                assets.solos:drawImage(1, button.x + 1, 7 - 1)
                -- gfx.drawTextAligned("*x*", button.x + button.w / 2, 14, kTextAlignment.center)
            end
        end
    end
end

local maxLength = 13
local previousText = ""

function playdate.keyboard.textChangedCallback()
    local newText = playdate.keyboard.text
    local newLength = utf8.len(newText)

    if newLength > maxLength and utf8.len(previousText) <= maxLength then
        -- 新しいテキストが制限を超えていて、前のテキストが制限内だった場合
        playdate.keyboard.text = previousText
    elseif newLength > maxLength then
        -- 新しいテキストが制限を超えている場合、14文字に切り詰める
        playdate.keyboard.text = utf8.sub(newText, 1, maxLength)
    end

    -- mast.name を更新
    mast.name = playdate.keyboard.text

    -- 現在のテキストを保存
    previousText = playdate.keyboard.text
end

function playdate.keyboard.keyboardDidHideCallback()
    isKeyboardOpen = false
    currentFocus = "globalBar"
end

console.log("GlobalBar loaded")
