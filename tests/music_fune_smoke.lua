package.path = "Source/?.lua;./?.lua;" .. package.path

local clock = 20
local selected_callback
local menu = {}

function menu:addOptionsMenuItem(title, options, initial, callback)
    assert(title == "Fune")
    assert(options[1] == "Off" and options[2] == "Shadow" and options[3] == "Active")
    assert(initial == "Off")
    selected_callback = callback
    return { setValue = function() end }
end

playdate = {
    sound = {
        getCurrentTime = function() return clock end,
    },
    getSystemMenu = function() return menu end,
}

console = { log = function() end }
mast = { name = "Smoke", bpm = 120, swing = 0, steps = 16, measure = 4, isPlaying = false }
keel = {
    songEnd = 2,
    loop = true,
    synth1 = { 1, 2 },
    synth2 = { 0, 0 },
    synth3 = { 0, 0 },
    drums = { 0, 0 },
}
boat = { synths = {}, drums = {} }
settings = {}
Sounds = {
    instruments = {},
    playMidiSynth = function() end,
    playDrum = function() end,
}

local created = {}
local function fake_runtime(args)
    local runtime = {
        args = args,
        project = { ppqn = 96 },
        playing = false,
        current_tick = 0,
        mode = args.mode or "region",
        position = args.position or 1,
        tempo_bpm = mast.bpm,
        swing_percent = mast.swing,
    }

    function runtime:play() self.playing = true end
    function runtime:start() self.playing = true; self.current_tick = 0 end
    function runtime:pause() self.playing = false end
    function runtime:stop() self.playing = false; self.current_tick = 0 end
    function runtime:is_playing() return self.playing end
    function runtime:update(dt)
        if self.playing then self.current_tick = self.current_tick + dt * 192 end
        return { { kind = "marker", dt = dt } }, { audio = 0, midi = 0 }
    end
    function runtime:receive_midi() return {}, {}, { audio = 0, midi = 0 } end
    function runtime:queue_scene() return 384 end
    function runtime:queue_next_scene() return 384 end
    function runtime:scene_id() return "yacht_scene_01" end
    function runtime:tick() return self.current_tick end
    function runtime:mode_name() return self.mode end
    function runtime:position_value() return self.position end
    function runtime:set_mode(mode, position)
        self.mode = mode
        self.position = position or self.position
        return self.current_tick
    end
    function runtime:set_position(position)
        self.position = position
        return self.current_tick
    end
    function runtime:set_tempo(bpm, swing_percent)
        self.tempo_bpm = bpm
        self.swing_percent = swing_percent
    end

    created[#created + 1] = runtime
    return runtime
end

function import(name)
    if name == "FuneCore" then
        FunePlaydate = { yacht_runtime = { new = fake_runtime } }
    elseif name == "FuneBridge" then
        dofile("Source/FuneBridge.lua")
    else
        error("unexpected import in Music smoke test: " .. tostring(name))
    end
end

local music = dofile("Source/Music.lua")
assert(music == Music)
assert(type(Music._legacyFlipState) == "function", "Music must retain the legacy playback toggle")
assert(type(Music._legacyRefresh) == "function", "Music must retain the legacy refresh path")

-- First refresh installs the system menu while legacy playback remains stopped.
Music.Refresh()
assert(selected_callback, "Music.Refresh must lazily install the Fune system menu")
assert(not FuneBridge:isEnabled())

-- Shadow keeps legacy playback authoritative while advancing a silent Fune runtime.
selected_callback("Shadow")
assert(FuneBridge.mode == "shadow")
Music.flipState()
assert(Music.state == true and mast.isPlaying == true, "Shadow must preserve legacy play state")
assert(created[#created].playing == true, "Shadow runtime must follow legacy play state")
clock = clock + 0.25
Music.Refresh()
assert(FuneBridge:tick() > 0, "Shadow runtime must advance behind legacy playback")

-- Active takeover disables the legacy transport, then the same Music.flipState
-- call controls Fune instead of creating a second playback path.
selected_callback("Active")
assert(FuneBridge:isActive())
assert(Music.state == false, "Active takeover must stop legacy Music")
Music.flipState()
assert(mast.isPlaying == true and FuneBridge.runtime:is_playing(),
    "Music.flipState must control Fune while Active")

clock = clock + 0.25
Music.Refresh()
assert(Music.tick == 3, "96 PPQN Fune tick 48 must map to Yacht step 3")
assert(Music.currentPosition == 1 and Music.mode == "region",
    "Active runtime navigation must mirror into Yacht UI state")

-- BPM and swing are live parameters and should not require a project rebuild.
local runtime_before_tempo = FuneBridge.runtime
mast.bpm = 90
mast.swing = 25
clock = clock + 0.01
Music.Refresh()
assert(FuneBridge.runtime == runtime_before_tempo, "BPM/swing edits must not rebuild the project snapshot")
assert(FuneBridge.runtime.tempo_bpm == 90 and FuneBridge.runtime.swing_percent == 25,
    "Active runtime must receive Yacht BPM and swing changes")

-- Existing Yacht navigation remains authoritative: bridge sees it next refresh.
Music.mode = "song"
Music.currentPosition = 2
clock = clock + 0.01
Music.Refresh()
assert(FuneBridge.runtime:mode_name() == "song")
assert(FuneBridge.runtime:position_value() == 2)

Music.flipState()
assert(not FuneBridge.runtime:is_playing() and mast.isPlaying == false,
    "second Music.flipState must pause Fune")

-- In-place editing does not change table identities. The bridge fingerprints the
-- playback data while stopped and rebuilds immediately before the next Play.
local runtime_before_edit = FuneBridge.runtime
local created_before_edit = #created
keel.synth1[1] = 2
Music.flipState()
assert(#created == created_before_edit + 1,
    "an in-place Yacht arrangement edit must rebuild Fune before the next Play")
assert(FuneBridge.runtime ~= runtime_before_edit and FuneBridge.runtime:is_playing(),
    "rebuilt Active runtime must start through the normal Music.flipState entry point")
assert(FuneBridge.runtime.args.keel.synth1[1] == 2,
    "rebuilt runtime must receive the edited Yacht arrangement")
Music.flipState()
assert(not FuneBridge.runtime:is_playing())

-- A project Load replaces mast/keel/boat/settings tables. That must invalidate the
-- Fune snapshot even if the loaded values happen to be similar to the old project.
local runtime_before_load = FuneBridge.runtime
mast = { name = "Loaded", bpm = 100, swing = 10, steps = 16, measure = 4, isPlaying = false }
keel = {
    songEnd = 1,
    loop = false,
    synth1 = { 1 }, synth2 = { 0 }, synth3 = { 0 }, drums = { 0 },
}
boat = { synths = {}, drums = {} }
settings = {}
clock = clock + 0.01
Music.Refresh()
assert(FuneBridge.runtime ~= runtime_before_load,
    "replacing Yacht project tables must rebuild Fune automatically")
assert(FuneBridge.runtime.args.mast.name == "Loaded")
assert(FuneBridge.runtime.tempo_bpm == 100 and FuneBridge.runtime.swing_percent == 10,
    "loaded Yacht transport settings must reach the rebuilt runtime")

selected_callback("Off")
assert(not FuneBridge:isEnabled())
assert(Music.state == false and mast.isPlaying == false)

print("music_fune_smoke.lua: ok")
