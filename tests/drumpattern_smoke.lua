playdate = { graphics = {} }
console = { log = function() end }
Music = { tick = 1 }

local input = { pressed = {}, released = {}, combos = {} }
KeyManager = {
    keys = { up = "up", down = "down", left = "left", right = "right", a = "a", b = "b" }
}
function KeyManager.isPressed(key) return input.pressed[key] == true end

function KeyManager.justReleased(key) return input.released[key] == true end

function KeyManager.justComboPressed(name) return input.combos[name] == true end

local function press(spec)
    input.pressed, input.released, input.combos = {}, {}, {}
    for key, value in pairs(spec) do input[key] = value end
end

local function newRegion(withLanes)
    local region = { patterns = {}, velos = {}, chance = {} }
    for drumIndex = 1, 6 do
        region.patterns[drumIndex] = {}
        for step = 1, 16 do region.patterns[drumIndex][step] = 0 end
    end
    for step = 1, 16 do
        region.velos[step] = 0.5
        region.chance[step] = 0.5
    end
    if withLanes then
        region.accent, region.active = {}, {}
        for step = 1, 16 do
            region.accent[step] = 0
            region.active[step] = 1
        end
    end
    return region
end

boat = { drums = { newRegion(false) } }

dofile("Source/drumPattern.lua")

local region = boat.drums[1]

-- Projects saved before the accent/active lanes existed must be backfilled.
DrumPattern.load()
assert(type(region.accent) == "table" and type(region.active) == "table",
    "missing lanes must be backfilled on load")
for step = 1, 16 do
    assert(region.accent[step] == 0, "accent must default to off")
    assert(region.active[step] == 1, "active must default to on")
end

-- A on the velocity row toggles accent, A on the chance row toggles active.
DrumPattern.cursor.x, DrumPattern.cursor.y = 3, 7
press({ released = { a = true } })
DrumPattern.handleInput()
assert(region.accent[3] == 1, "A on the velocity row must toggle accent")

DrumPattern.cursor.y = 8
press({ released = { a = true } })
DrumPattern.handleInput()
assert(region.active[3] == 0, "A on the chance row must toggle active")

press({ released = { a = true } })
DrumPattern.handleInput()
assert(region.active[3] == 1, "toggling active twice must restore it")

-- The value rows adjust their own value and must not walk the cursor away
-- before the adjustment lands.
DrumPattern.cursor.y = 7
press({ pressed = { a = true }, combos = { upA = true } })
DrumPattern.handleInput()
assert(math.abs(region.velos[3] - 0.6) < 0.0001, "A + up must raise velocity")
assert(DrumPattern.cursor.y == 7, "the velocity row must keep the cursor put")

DrumPattern.cursor.y = 8
press({ pressed = { a = true }, combos = { downA = true } })
DrumPattern.handleInput()
assert(math.abs(region.chance[3] - 0.4) < 0.0001, "A + down must lower chance")
assert(DrumPattern.cursor.y == 8, "the chance row must keep the cursor put")

-- The six drum rows keep the paint-and-walk behaviour.
DrumPattern.cursor.y = 3
press({ pressed = { a = true }, combos = { upA = true } })
DrumPattern.handleInput()
assert(region.patterns[3][3] == 1, "A + up must paint the drum cell")
assert(DrumPattern.cursor.y == 2, "A + up must walk up the drum rows")

-- Holding A must not also run the plain d-pad moves.
DrumPattern.cursor.x, DrumPattern.cursor.y = 5, 2
press({ pressed = { a = true }, released = { right = true }, combos = { rightA = true } })
DrumPattern.handleInput()
assert(DrumPattern.cursor.x == 6, "A + right must advance exactly one step")

-- New regions and region switches always carry both lanes.
DrumPattern.switchRegion(1)
local created = boat.drums[DrumPattern.currentRegion]
assert(created ~= region, "switching past the last region must create one")
assert(created.accent[1] == 0 and created.active[1] == 1, "new regions must have both lanes")

print("drum pattern smoke tests passed")
