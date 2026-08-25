playdate = { graphics = {} }
console = { log = function() end }

local songLoop = nil
Music = {
    currentPosition = 1,
    setSongLoop = function(value) songLoop = value end
}
CrankManager = { forwardTick = false, backwardTick = false }

local input = { released = {}, combos = {} }
KeyManager = {
    keys = { up = "up", down = "down", left = "left", right = "right", a = "a", b = "b" }
}
function KeyManager.justReleased(key) return input.released[key] == true end

function KeyManager.justComboReleased(name) return input.combos[name] == true end

local function press(spec)
    input.released, input.combos = {}, {}
    for key, value in pairs(spec) do input[key] = value end
end

local function tap(spec)
    press(spec)
    SongEdit.handleInput()
end

mast = { name = "Test" }
keel = {
    songEnd = 4,
    loop = false,
    synth1 = { 2, 0, 0, 0 },
    synth2 = { 0, 0, 0, 0 },
    synth3 = { 0, 0, 0, 0 },
    drums = { 1, 1, 1, 1 }
}

dofile("Source/SongEdit.lua")

SongEdit.init()
assert(SongEdit.endType == "coda", "a non-looping song must start on coda")
assert(songLoop == false, "init must push keel.loop into Music")
assert(mast.song == nil, "the vestigial mast.song table must be gone")

-- Row 1 is the length lane and owns no region value.
assert(SongEdit.incrementRegion() == false, "the length row has no region to bump")
assert(SongEdit.copyRegionRight() == false, "the length row has nothing to copy")

tap({ released = { down = true } }) -- move onto the synth1 track

-- A + right copies the region to the right and follows it.
tap({ combos = { rightA = true } })
assert(keel.synth1[2] == 2, "A + right must copy the region rightwards")
assert(SongEdit.cursor.x == SongEdit.cursors[2][2].x, "the cursor must follow the copy")

-- A + up / A + down retarget keel, not the old phantom table.
tap({ combos = { upA = true } })
assert(keel.synth1[2] == 3, "A + up must increment the region number")
tap({ combos = { downA = true } })
assert(keel.synth1[2] == 2, "A + down must decrement the region number")

-- A + left copies back and follows.
tap({ combos = { leftA = true } })
assert(keel.synth1[1] == 2, "A + left must copy the region leftwards")
assert(SongEdit.cursor.x == SongEdit.cursors[2][1].x, "the cursor must follow the copy")
assert(SongEdit.copyRegionLeft() == false, "position 1 has no left neighbour")

-- Plain A toggles the cell on and off.
tap({ released = { a = true } })
assert(keel.synth1[1] == 0, "A must clear a set region")
tap({ released = { a = true } })
assert(keel.synth1[1] == 1, "A must set a cleared region")

-- The end marker cycles coda -> D.C. -> none, keeping keel.loop in step.
tap({ released = { up = true } }) -- back to the length row
for _ = 1, 3 do tap({ released = { right = true } }) end
assert(SongEdit.scrollOffset == 0, "four columns fit without scrolling")

tap({ released = { a = true } })
assert(SongEdit.endType == "d.c." and keel.loop == true and songLoop == true,
    "coda must advance to D.C. and enable looping")

tap({ released = { a = true } })
assert(SongEdit.endType == "none" and keel.loop == false and songLoop == false,
    "D.C. must advance to none and disable looping")
assert(keel.songEnd == 3, "clearing the marker must pull the song end back")

tap({ released = { a = true } })
assert(SongEdit.endType == "coda" and keel.songEnd == 4,
    "marking a fresh position must set the song end and a coda")

print("song edit smoke tests passed")
