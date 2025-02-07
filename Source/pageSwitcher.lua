local gfx <const> = playdate.graphics

PageSwitcher = {}

local pages = { "PianoRoll", "DrumPattern", "SynthEdit", "DrumEdit", "Mixer", "SongEdit", "Visualizer", "Preferences" }
local selectedPage = 1
local isOpen = false

PageSwitcher.cursor = {}


PageSwitcher.cursor.x = 1
PageSwitcher.cursor.y = 100
PageSwitcher.cursor.w = 32
PageSwitcher.cursor.h = 32



local iconPos = {
    28,
    72,
    116,
    160,
    204,
    248,
    292,
    336

}



function PageSwitcher.open()
    isOpen = true
end

function PageSwitcher.close()
    isOpen = false
end

function PageSwitcher.handleInput()
    if not isOpen then return nil end

    if KeyManager.justReleased(KeyManager.keys.left) then
        selectedPage = ((selectedPage - 2) % #pages) + 1
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        selectedPage = (selectedPage % #pages) + 1
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        local newPage = pages[selectedPage]
        PageSwitcher.close()


        return newPage
    elseif KeyManager.justReleased(KeyManager.keys.b) then
        PageSwitcher.close()
    end
    return nil
end

function PageSwitcher.draw()
    if not isOpen then return end



    --
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(20, 90, 360, 70, 2)


    gfx.setColor(gfx.kColorBlack)



    for i, page in ipairs(pages) do
        assets.icons:drawImage(i, iconPos[i], 100)
    end
    gfx.drawTextInRect("*" .. pages[selectedPage] .. "*", iconPos[1], 140, 128, 32)

    gfx.drawRoundRect(20, 90, 360, 70, 2)




    PageSwitcher.cursor.x = iconPos[selectedPage]
end

function PageSwitcher.isOpen()
    return isOpen
end

PageSwitcher.mask = {}

PageSwitcher.mask.target = 1
PageSwitcher.mask.current = 0
PageSwitcher.mask.alpha = 0.7

function PageSwitcher.mask.draw()
    PageSwitcher.mask.current = PageSwitcher.mask.current +
        PageSwitcher.mask.alpha * (PageSwitcher.mask.target - PageSwitcher.mask.current)

    if isOpen then
        PageSwitcher.mask.target = 0.5
    else
        PageSwitcher.mask.target = 1
    end

    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(PageSwitcher.mask.current)
    gfx.fillRect(0, 0, 400, 240)
end

console.log("PageSwitcher loaded")
