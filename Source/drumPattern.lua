local gfx <const> = playdate.graphics

DrumPattern = {}

DrumPattern.cursor = { x = 1, y = 1 }
DrumPattern.currentRegion = 1
DrumPattern.clipboard = nil

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
    DrumPattern.ensureLanes(boat.drums[DrumPattern.currentRegion])
    console.log("DrumPattern initialization complete")
end

-- Projects saved before the accent/active lanes existed have no such tables.
-- Music.next() tolerates them being missing, but the editor needs real values.
function DrumPattern.ensureLanes(pattern)
    if type(pattern) ~= "table" then return nil end
    pattern.accent = pattern.accent or {}
    pattern.active = pattern.active or {}
    for step = 1, DrumPattern.grids.maxH do
        if pattern.accent[step] ~= 1 then pattern.accent[step] = 0 end
        if pattern.active[step] ~= 0 then pattern.active[step] = 1 end
    end
    return pattern
end

function DrumPattern.handleInput()
    local currentPattern = DrumPattern.ensureLanes(boat.drums[DrumPattern.currentRegion])
    if not currentPattern then return end

    if KeyManager.justComboPressed("upB") then
        DrumPattern.switchRegion(1)
        return
    elseif KeyManager.justComboPressed("downB") then
        if DrumPattern.currentRegion == 1 then
            return
        end
        DrumPattern.switchRegion(-1)
        return
    end

    -- A acts as a modifier while held, so the plain d-pad moves must not also run.
    if KeyManager.isPressed(KeyManager.keys.a) then
        DrumPattern.handleCombos(currentPattern)
        return
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
    end
end

function DrumPattern.toggleValue(currentPattern)
    local x, y = DrumPattern.cursor.x, DrumPattern.cursor.y
    if y <= 6 then
        currentPattern.patterns[y][x] = 1 - currentPattern.patterns[y][x]
    elseif y == 7 then
        currentPattern.accent[x] = 1 - currentPattern.accent[x]
    elseif y == 8 then
        currentPattern.active[x] = 1 - currentPattern.active[x]
    end
end

function DrumPattern.handleCombos(currentPattern)
    local x, y = DrumPattern.cursor.x, DrumPattern.cursor.y

    if KeyManager.justComboPressed("leftA") then
        DrumPattern.toggleValue(currentPattern)
        DrumPattern.cursor.x = math.max(1, x - 1)
    elseif KeyManager.justComboPressed("rightA") then
        DrumPattern.toggleValue(currentPattern)
        DrumPattern.cursor.x = math.min(DrumPattern.grids.maxH, x + 1)
    elseif KeyManager.justComboPressed("upA") then
        if y == 7 then
            currentPattern.velos[x] = math.min(1, currentPattern.velos[x] + 0.1)
        elseif y == 8 then
            currentPattern.chance[x] = math.min(1, currentPattern.chance[x] + 0.1)
        else
            DrumPattern.toggleValue(currentPattern)
            DrumPattern.cursor.y = math.max(1, y - 1)
        end
    elseif KeyManager.justComboPressed("downA") then
        if y == 7 then
            currentPattern.velos[x] = math.max(0, currentPattern.velos[x] - 0.1)
        elseif y == 8 then
            currentPattern.chance[x] = math.max(0, currentPattern.chance[x] - 0.1)
        else
            DrumPattern.toggleValue(currentPattern)
            DrumPattern.cursor.y = math.min(DrumPattern.grids.maxV, y + 1)
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
    DrumPattern.ensureLanes(boat.drums[DrumPattern.currentRegion])
end

function DrumPattern.createNewRegion()
    local newRegion = {
        patterns = {},
        velos = {},
        chance = {},
        accent = {},
        active = {}
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
        newRegion.accent[x] = 0
        newRegion.active[x] = 1
    end

    table.insert(boat.drums, newRegion)
    DrumPattern.currentRegion = #boat.drums
end

function DrumPattern.draw()
    local currentPattern = DrumPattern.ensureLanes(boat.drums[DrumPattern.currentRegion])
    if not currentPattern then return end

    DrumPattern.drawPatterns(currentPattern)
    DrumPattern.drawVelocity(currentPattern)
    DrumPattern.drawChance(currentPattern)
    DrumPattern.drawSkippedSteps(currentPattern)


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
    DrumPattern.clipboard = nil
    for _, pattern in ipairs(boat.drums) do
        DrumPattern.ensureLanes(pattern)
    end
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
        local cell = DrumPattern.cursors[7][x]
        local fullHeight = cell.h - 2 * valueMargin
        local veloHeight = math.floor(currentPattern.velos[x] * fullHeight)
        local y = cell.y + cell.h - veloHeight - valueMargin

        gfx.fillRect(cell.x + 1, math.floor(y), cell.w - 2, veloHeight)

        -- Accent reads as a cap floating above the velocity bar, so it stays
        -- legible even when the bar itself is at full height.
        if currentPattern.accent[x] == 1 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(cell.x + 1, cell.y + valueMargin + 4, cell.w - 2, 2)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(cell.x + 1, cell.y + valueMargin, cell.w - 2, 4)
        end
    end
end

-- Steps switched off in the "active" lane are washed out across every row.
function DrumPattern.drawSkippedSteps(currentPattern)
    local top = DrumPattern.cursors[1][1].y
    local bottom = DrumPattern.cursors[8][1]
    local height = bottom.y + bottom.h - top

    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
    for x = 1, DrumPattern.grids.maxH do
        if currentPattern.active[x] == 0 then
            local cell = DrumPattern.cursors[1][x]
            gfx.fillRect(cell.x, top, cell.w, height)
        end
    end
    gfx.setColor(gfx.kColorBlack)
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
    local pattern = boat.drums[DrumPattern.currentRegion]
    if not pattern then return end
    for drumIndex = 1, 6 do
        for step = 1, 16 do
            pattern.patterns[drumIndex][step] = 0
        end
    end
    for step = 1, 16 do
        pattern.velos[step] = 1
        pattern.chance[step] = 1
        if pattern.accent then pattern.accent[step] = 0 end
        if pattern.active then pattern.active[step] = 1 end
    end
end

function DrumPattern.randomizePattern()
    local pattern = boat.drums[DrumPattern.currentRegion]
    if not pattern then return end
    local probabilities = { 0.35, 0.2, 0.55, 0.12, 0.1, 0.08 }
    for drumIndex = 1, 6 do
        for step = 1, 16 do
            pattern.patterns[drumIndex][step] =
                math.random() < probabilities[drumIndex] and 1 or 0
        end
    end
    for step = 1, 16 do
        pattern.velos[step] = math.random(70, 100) / 100
        pattern.chance[step] = 1
        if pattern.accent then pattern.accent[step] = step % 4 == 1 and 1 or 0 end
        if pattern.active then pattern.active[step] = 1 end
    end
end

function DrumPattern.copyPattern()
    local current = boat.drums[DrumPattern.currentRegion]
    if not current then return false end

    if not DrumPattern.clipboard then
        DrumPattern.clipboard = {
            patterns = { {}, {}, {}, {}, {}, {} },
            velos = {},
            chance = {},
            accent = {},
            active = {}
        }
        for drumIndex = 1, 6 do
            for step = 1, 16 do
                DrumPattern.clipboard.patterns[drumIndex][step] = current.patterns[drumIndex][step]
            end
        end
        for step = 1, 16 do
            DrumPattern.clipboard.velos[step] = current.velos[step]
            DrumPattern.clipboard.chance[step] = current.chance[step]
            DrumPattern.clipboard.accent[step] = current.accent and current.accent[step] or 0
            DrumPattern.clipboard.active[step] = current.active and current.active[step] or 1
        end
        Balloon.open("Pattern copied; choose destination")
    else
        for drumIndex = 1, 6 do
            for step = 1, 16 do
                current.patterns[drumIndex][step] = DrumPattern.clipboard.patterns[drumIndex][step]
            end
        end
        current.accent = current.accent or {}
        current.active = current.active or {}
        for step = 1, 16 do
            current.velos[step] = DrumPattern.clipboard.velos[step]
            current.chance[step] = DrumPattern.clipboard.chance[step]
            current.accent[step] = DrumPattern.clipboard.accent[step]
            current.active[step] = DrumPattern.clipboard.active[step]
        end
        DrumPattern.clipboard = nil
        Balloon.open("Pattern pasted")
    end
    return true
end

console.log("DrumPattern module loaded")

return DrumPattern
