package.path = "Source/?.lua;./?.lua;" .. package.path

local clock = 10
playdate = {
    sound = {
        getCurrentTime = function() return clock end,
    },
}

mast = { bpm = 120, isPlaying = false }
keel = { songEnd = 1, loop = true, synth1 = { 1 }, synth2 = { 0 }, synth3 = { 0 }, drums = { 0 } }
boat = { synths = {}, drums = {} }
settings = {}
Music = { state = true }
Sounds = {
    instruments = {},
    playMidiSynth = function() end,
    playDrum = function() end,
}

local created = {}
local function fake_runtime(args)
    local runtime = {
        args = args,
        playing = false,
        current_tick = 0,
        scene = "yacht_scene_01",
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
    function runtime:receive_midi(data)
        if data == string.char(0xFA) then self.playing = true end
        return {}, { "start" }, { audio = 0, midi = 0 }
    end
    function runtime:queue_scene(scene) self.scene = "yacht_scene_0" .. tostring(scene); return 384 end
    function runtime:queue_next_scene() return 384 end
    function runtime:scene_id() return self.scene end
    function runtime:tick() return self.current_tick end

    created[#created + 1] = runtime
    return runtime
end

FunePlaydate = {
    yacht_runtime = {
        new = fake_runtime,
    },
}

local bridge = dofile("Source/FuneBridge.lua")
assert(bridge.available(), "FuneBridge must detect loaded FuneCore")
assert(not bridge.isEnabled(), "bridge must begin disabled")

local ok = bridge.enableShadow()
assert(ok and bridge.mode == "shadow", "shadow mode must initialize")
assert(created[#created].args.sounds ~= Sounds, "shadow mode must not route into Yacht Sounds")
bridge:play()
clock = 10.25
local events = bridge:update()
assert(#events == 1, "shadow update must run the Fune runtime")
assert(math.abs(bridge.tick() - 48) < 1e-9, "wall clock delta must reach Fune runtime")

ok = bridge.enableActive()
assert(ok and bridge.isActive(), "active mode must initialize")
assert(created[#created].args.sounds == Sounds, "active mode must route into Yacht Sounds")
assert(Music.state == false, "active takeover must disable legacy Music playback")
bridge:play()
assert(mast.isPlaying == true, "active play must mirror mast playback state")
bridge:pause()
assert(mast.isPlaying == false, "active pause must mirror mast playback state")

assert(bridge.queueScene(2) == 384, "bridge must expose quantized scene queueing")
assert(bridge.sceneId() == "yacht_scene_02", "bridge must expose current Fune scene")

local selected_callback
local menu = {}
function menu:addOptionsMenuItem(title, options, initial, callback)
    assert(title == "Fune", "bridge menu title must be short")
    assert(#options == 3 and options[1] == "Off" and options[2] == "Shadow" and options[3] == "Active",
        "bridge menu must expose three rollout modes")
    assert(initial == "Off", "bridge menu must default to Off")
    selected_callback = callback
    return { setValue = function() end }
end

bridge:disable()
local item = bridge.installMenu(menu)
assert(item and selected_callback, "bridge must install an options menu item")
selected_callback("Shadow")
assert(bridge.mode == "shadow", "system menu Shadow option must enable shadow runtime")
selected_callback("Active")
assert(bridge.mode == "active", "system menu Active option must enable audio takeover")
selected_callback("Off")
assert(bridge.mode == "disabled", "system menu Off option must disable Fune runtime")

bridge:disable()
assert(not bridge.isEnabled() and bridge.mode == "disabled", "disable must tear down runtime")

print("funebridge_smoke.lua: ok")
