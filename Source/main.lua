import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"
import "CoreLibs/keyboard"
import "CoreLibs/qrcode"
import "CoreLibs/keyboard"
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
import "FileDialog"
import "DrumEdit"
import "Toolbox"
import "Preferences"
import "Visualizer"





yachtMeta = {
    version = "1.0.2",
    name = "Yacht",
    author = "hugelton",
}



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
    "Preferences ",

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
local menuItem, error = menu:addMenuItem("Load", function()
    FileDialog.open("/", "json", function(selectedPath)
        if selectedPath then
            local filename = selectedPath:match("([^/]+)%.json$")
            if filename then
                local data = playdate.datastore.read(filename)
                if data then
                    if loadProject(data) then
                        Balloon.open("Project loaded successfully from: " .. filename)
                    end
                else
                    Balloon.open("Failed to load project: " .. filename)
                end
            end
        else
            Balloon.open("Load cancelled")
        end
    end)
end)



local menuItem, error = menu:addMenuItem("Save", function()
    local data = {
        sail = sail,
        mast = mast,
        keel = keel,
        boat = boat
    }

    local success = playdate.datastore.write(data, data.mast.name, true)
    if success then
        Balloon.open("Project saved successfully")
    else
        Balloon.open("Failed to save project")
    end
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

    playdate.setCrankSoundsDisabled(disable)

    Toolbox.init()

    GlobalBar.init()

    for _, page in pairs(pages) do
        if page.init then
            page.init()
        end
    end
    Sounds.init()

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
            if currentPage == "DrumEdit" then DrumEdit.closeSampleSelector() end
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
        DrumEdit.handleSampleSelector()
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


    if not data.sail or not data.mast or not data.keel or not data.boat then
        Balloon.open("Missing required project components")
        return false
    end


    local function safeDeepCopy(src)
        if type(src) ~= 'table' then return src end
        local result = {}
        for k, v in pairs(src) do
            if type(v) == 'table' then
                result[k] = safeDeepCopy(v)
            else
                result[k] = v
            end
        end
        return result
    end


    local newSail = safeDeepCopy(data.sail)
    local newMast = safeDeepCopy(data.mast)
    local newKeel = safeDeepCopy(data.keel)
    local newBoat = safeDeepCopy(data.boat)


    if not validateProjectStructure(newSail, newMast, newKeel, newBoat) then
        Balloon.open("Invalid project structure")
        return false
    end


    Music.tick = 1
    Music.currentPosition = 1
    Music.state = false
    mast.isPlaying = false


    sail = newSail
    mast = newMast
    keel = newKeel
    boat = newBoat


    PianoRoll.load()
    DrumPattern.load()
    SynthEdit.load()
    Mixer.load()
    SongEdit.load()
    Sounds.init()


    playdate.graphics.sprite.redrawBackground()

    return true
end

function validateProjectStructure(sail, mast, keel, boat)
    if not (sail.synth1 and sail.synth2 and sail.synth3 and
            sail.drum1 and sail.drum2 and sail.drum3 and
            sail.drum4 and sail.drum5 and sail.drum6 and
            sail.mixer) then
        return false
    end


    if not (mast.name and mast.bpm and mast.swing and
            mast.steps and mast.measure) then
        return false
    end


    if not (keel.songEnd and type(keel.synth1) == 'table' and
            type(keel.synth2) == 'table' and type(keel.synth3) == 'table' and
            type(keel.drums) == 'table') then
        return false
    end


    if not (type(boat.synths) == 'table' and type(boat.drums) == 'table') then
        return false
    end


    return true
end

function saveProject(data)
    if Music.state then
        Music.flipState()
    end


    local saveData = {
        sail = safeDeepCopy(sail),
        mast = safeDeepCopy(mast),
        keel = safeDeepCopy(keel),
        boat = safeDeepCopy(boat)
    }


    if not validateProjectStructure(saveData.sail, saveData.mast, saveData.keel, saveData.boat) then
        Balloon.open("Failed to create valid save data")
        return false
    end

    local success = playdate.datastore.write(saveData, saveData.mast.name, true)
    if success then
        Balloon.open("Project saved successfully")
        return true
    else
        Balloon.open("Failed to save project")
        return false
    end
end
