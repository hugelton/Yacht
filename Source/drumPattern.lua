local gfx <const> = playdate.graphics

DrumPattern = {}

DrumPattern.cursor = { x = 1, y = 1 }
DrumPattern.currentRegion = 1

DrumPattern.grids = {
    maxH = 16,
    maxV = 8 -- 6 (patterns) + 1 (velocity) + 1 (chance)
}

DrumPattern.cursors = {}

local startX, startY = 55, 38
local cellWidth, cellHeight = 18, 18
local valueHeight = 32
local gapHeight = 6
local valueGap = 14
local valueMargin = 1


for y = 1, DrumPattern.grids.maxV do
    DrumPattern.cursors[y] = {}
    for x = 1, DrumPattern.grids.maxH do
        local yPos = startY + ((y - 1) * cellHeight)
        local height = cellHeight
        if y > 6 then
            yPos = yPos + gapHeight * (y - 6) + (y - 7) * valueGap -- 6行目以降にギャップを追加
            height = valueHeight
        end
        DrumPattern.cursors[y][x] = {
            x = startX + ((x - 1) * cellWidth),
            y = yPos,
            w = cellWidth - 1,
            h = height - 1
        }
    end
end


function DrumPattern.init()
    console.log("Initializing DrumPattern")
    DrumPattern.cursor.x, DrumPattern.cursor.y = 1, 1
    DrumPattern.currentRegion = 1
    console.log("DrumPattern initialization complete")
end

function DrumPattern.handleInput()
    local currentPattern = boat.drums[DrumPattern.currentRegion]

    if KeyManager.justComboPressed("upB") then
        DrumPattern.switchRegion(1)
    elseif KeyManager.justComboPressed("downB") then
        if DrumPattern.currentRegion == 1 then
            return
        end
        DrumPattern.switchRegion(-1)
    elseif KeyManager.justComboPressed("upA") then
        DrumPattern.toggleValue(currentPattern)
        DrumPattern.cursor.y = math.max(1, DrumPattern.cursor.y - 1)
    elseif KeyManager.justComboPressed("downA") then
        DrumPattern.toggleValue(currentPattern)
        DrumPattern.cursor.y = math.min(DrumPattern.grids.maxV, DrumPattern.cursor.y + 1)
    end

    if KeyManager.justReleased(KeyManager.keys.left) then
        DrumPattern.cursor.x = math.max(1, DrumPattern.cursor.x - 1)
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        DrumPattern.cursor.x = math.min(DrumPattern.grids.maxH, DrumPattern.cursor.x + 1)
    elseif KeyManager.justReleased(KeyManager.keys.up) then
        DrumPattern.cursor.y = math.max(1, DrumPattern.cursor.y - 1)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        DrumPattern.cursor.y = math.min(DrumPattern.grids.maxV, DrumPattern.cursor.y + 1)
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        DrumPattern.toggleValue(currentPattern)
    elseif KeyManager.isPressed(KeyManager.keys.a) then
        DrumPattern.handleCombos(currentPattern)
    end
end

function DrumPattern.toggleValue(currentPattern)
    if DrumPattern.cursor.y <= 6 then
        currentPattern.patterns[DrumPattern.cursor.y][DrumPattern.cursor.x] =
            1 - currentPattern.patterns[DrumPattern.cursor.y][DrumPattern.cursor.x]
    end
end

function DrumPattern.handleCombos(currentPattern)
    if KeyManager.justComboPressed("leftA") then
        DrumPattern.toggleValue(currentPattern)
        DrumPattern.cursor.x = math.max(1, DrumPattern.cursor.x - 1)
    elseif KeyManager.justComboPressed("rightA") then
        DrumPattern.toggleValue(currentPattern)
        DrumPattern.cursor.x = math.min(DrumPattern.grids.maxH, DrumPattern.cursor.x + 1)
    elseif KeyManager.justComboPressed("upA") then
        if DrumPattern.cursor.y == 7 then
            currentPattern.velos[DrumPattern.cursor.x] = math.min(1, currentPattern.velos[DrumPattern.cursor.x] + 0.1)
        elseif DrumPattern.cursor.y == 8 then
            currentPattern.chance[DrumPattern.cursor.x] = math.min(1, currentPattern.chance[DrumPattern.cursor.x] + 0.1)
        end
    elseif KeyManager.justComboPressed("downA") then
        if DrumPattern.cursor.y == 7 then
            currentPattern.velos[DrumPattern.cursor.x] = math.max(0, currentPattern.velos[DrumPattern.cursor.x] - 0.1)
        elseif DrumPattern.cursor.y == 8 then
            currentPattern.chance[DrumPattern.cursor.x] = math.max(0, currentPattern.chance[DrumPattern.cursor.x] - 0.1)
        end
    end
end

function DrumPattern.switchRegion(direction)
    local newRegion = DrumPattern.currentRegion + direction
    if newRegion < 1 or newRegion > #boat.drums then
        DrumPattern.createNewRegion()
    else
        DrumPattern.currentRegion = newRegion
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

function DrumPattern.createNewRegion()
    local newRegion = {
        patterns = {},
        velos = {},
        chance = {}
    }


    for y = 1, 6 do
        newRegion.patterns[y] = {}
        for x = 1, 16 do
            newRegion.patterns[y][x] = 0
        end
    end


    for x = 1, 16 do
        newRegion.velos[x] = 1
        newRegion.chance[x] = 1
    end

    table.insert(boat.drums, newRegion)
    DrumPattern.currentRegion = #boat.drums
end

function DrumPattern.draw()
    local currentPattern = boat.drums[DrumPattern.currentRegion]

    DrumPattern.drawPatterns(currentPattern)
    DrumPattern.drawVelocity(currentPattern)
    DrumPattern.drawChance(currentPattern)


    gfx.setColor(0)
    gfx.setDitherPattern(0.75)

    -- global.tick

    gfx.fillRect(
        DrumPattern.cursors[1][Music.tick].x,
        DrumPattern.cursors[1][1].y,
        DrumPattern.cursors[1][1].w,
        200)


    gfx.setColor(0)

    assets.drawSegments(DrumPattern.currentRegion, 365, 42)
end

function DrumPattern.load()
    DrumPattern.cursor.x = 1
    DrumPattern.cursor.y = 1
    DrumPattern.currentRegion = 1
end

function DrumPattern.drawPatterns(currentPattern)
    for y = 1, 6 do
        for x = 1, DrumPattern.grids.maxH do
            if currentPattern.patterns[y][x] == 1 then
                gfx.fillRoundRect(
                    DrumPattern.cursors[y][x].x + 1,
                    DrumPattern.cursors[y][x].y + 1,
                    DrumPattern.cursors[y][x].w - 2,
                    DrumPattern.cursors[y][x].h - 2,
                    2
                )
            end
        end
    end
end

function DrumPattern.drawVelocity(currentPattern)
    for x = 1, DrumPattern.grids.maxH do
        local fullHeight = DrumPattern.cursors[7][x].h - 2 * valueMargin
        local veloHeight = math.floor(currentPattern.velos[x] * fullHeight)
        local y = DrumPattern.cursors[7][x].y + DrumPattern.cursors[7][x].h - veloHeight - valueMargin

        gfx.fillRect(
            DrumPattern.cursors[7][x].x + 1,
            math.floor(y),
            DrumPattern.cursors[7][x].w - 2,
            veloHeight
        )
    end
end

function DrumPattern.drawChance(currentPattern)
    for x = 1, DrumPattern.grids.maxH do
        local fullHeight = DrumPattern.cursors[8][x].h - 2 * valueMargin
        local chanceHeight = math.floor(currentPattern.chance[x] * fullHeight)
        local y = DrumPattern.cursors[8][x].y + DrumPattern.cursors[8][x].h - chanceHeight - valueMargin

        gfx.fillRect(
            DrumPattern.cursors[8][x].x + 1,
            math.floor(y),
            DrumPattern.cursors[8][x].w - 2,
            chanceHeight
        )
    end
end

function DrumPattern.clearPattern()
    console.log("clear")
end

function DrumPattern.randomizePattern()
    console.log("randomizePattern")
end

function DrumPattern.copyPattern(sourceRegion, targetRegion)
    console.log("copy")
end

console.log("DrumPattern module loaded")

return DrumPattern
