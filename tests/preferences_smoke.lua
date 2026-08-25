playdate = { graphics = {} }
console = { log = function() end }

local syncCount = 0
Music = { syncClock = function() syncCount = syncCount + 1 end }
MIDI = { clockPulses = 0, getStatus = function() return "" end }
CrankManager = { forwardTick = false, backwardTick = false }

local input = { released = {}, combos = {} }
KeyManager = {
    keys = { up = "up", down = "down", left = "left", right = "right", a = "a", b = "b" }
}
function KeyManager.justReleased(key) return input.released[key] == true end

function KeyManager.justComboPressed(name) return input.combos[name] == true end

local function tap(spec)
    input.released, input.combos = {}, {}
    for key, value in pairs(spec) do input[key] = value end
    Preferences.handleInput()
end

settings = {
    midiEnabled = true,
    midiClockSource = "Internal",
    midiChannels = { syn1 = 1, syn2 = 2, syn3 = 3, drums = 10 },
    drumMidiNotes = {
        kick = 36,
        snare = 38,
        closedHiHat = 42,
        openHiHat = 46,
        percussion1 = 47,
        percussion2 = 48
    }
}

dofile("Source/Preferences.lua")

Preferences.init()
assert(#Preferences.uiComponents == 12, "every MIDI setting needs a control")
assert(#Preferences.cursorMap == #Preferences.uiComponents, "each control needs a cursor box")

-- Parking on a control must not keep re-applying it: Music.syncClock starts
-- playback, so firing it every frame would run the transport by itself.
for _ = 1, 5 do tap({}) end
tap({ released = { down = true } }) -- onto the clock dropdown
for _ = 1, 5 do tap({}) end
assert(syncCount == 0, "an unchanged setting must not trigger side effects")

tap({ released = { right = true } })
assert(settings.midiClockSource == "External", "right must switch the clock source")
assert(syncCount == 1, "changing the clock source must resync exactly once")
for _ = 1, 5 do tap({}) end
assert(syncCount == 1, "holding still must not resync again")

-- Walk down to the drum note map: checkbox, clock, 3 synth channels, drum
-- channel, then kick.
for _ = 1, 5 do tap({ released = { down = true } }) end
local kick = Preferences.uiComponents[Preferences.currentCursorIndex]
assert(kick.label == "Kick", "reading order must reach the kick note next")

tap({ released = { right = true } })
assert(settings.drumMidiNotes.kick == 37, "right must nudge the note by one")
tap({ released = { left = true } })
assert(settings.drumMidiNotes.kick == 36, "left must nudge the note back")

tap({ combos = { rightA = true } })
assert(settings.drumMidiNotes.kick == 48, "A + right must jump an octave")
tap({ combos = { leftA = true } })
assert(settings.drumMidiNotes.kick == 36, "A + left must jump back an octave")

for _ = 1, 12 do tap({ combos = { rightA = true } }) end
assert(settings.drumMidiNotes.kick == 127, "notes must clamp to the MIDI range")
for _ = 1, 12 do tap({ combos = { leftA = true } }) end
assert(settings.drumMidiNotes.kick == 0, "notes must clamp at zero")

-- Every drum slot MIDI.drumForNote looks up must be reachable.
local labels = {}
for _, component in ipairs(Preferences.uiComponents) do
    if component.target then labels[component.target] = true end
end
for _, target in ipairs({
    "drumMidiNotes.kick", "drumMidiNotes.snare", "drumMidiNotes.closedHiHat",
    "drumMidiNotes.openHiHat", "drumMidiNotes.percussion1", "drumMidiNotes.percussion2"
}) do
    assert(labels[target], target .. " has no editor")
end

print("preferences smoke tests passed")
