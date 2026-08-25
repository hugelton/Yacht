# Fune Core integration experiment

This branch keeps the legacy `Music.lua` playback path intact while testing Fune Core beside it.

## Goal

Move Yacht's sequencing / transport behavior toward the shared Fune Core without rewriting Playdate-specific UI, crank input, datastore, or synthesis code.

```text
Yacht UI / data
 mast / keel / boat
        |
    FuneBridge
        |
 FunePlaydate runtime
        |
 ScenePlayer / ClockDriver
        |
 Yacht Sounds
```

## Install FuneCore.lua

With the Fune and Yacht repositories checked out locally:

```bash
cd Fune
python3 tools/install_yacht_bundle.py ../Yacht
```

This builds Fune's single-file Playdate bundle and copies it to:

```text
Yacht/Source/FuneCore.lua
```

The generated file exposes the global `FunePlaydate` table. It contains its own module loader and does not require Fune's source tree at Playdate runtime.

## Minimal Yacht hook

After `FuneCore.lua` exists, the experimental Yacht startup hook only needs to import the bundle and bridge after the normal Yacht modules are loaded:

```lua
import "FuneCore"
import "FuneBridge"
```

After `Sounds.init()` the bridge can add one Playdate system-menu option:

```lua
FuneBridge:installMenu(playdate.getSystemMenu())
```

Playdate supports up to three custom System Menu items; Yacht currently uses Load and Save, so this experiment deliberately consumes only the third slot.

The runtime update hook is:

```lua
if FuneBridge:isEnabled() then
    FuneBridge:update()
end
```

Do not replace `Music.Refresh()` yet while testing Shadow mode.

## Rollout modes

### Off

Legacy Yacht only. Fune runtime is not instantiated.

### Shadow

Fune imports the current `mast / keel / boat / settings` and advances its own transport, but uses a null sound output. Legacy `Music.lua` remains the audible playback engine.

Use this first to inspect:

- transport tick progression
- imported Scene position
- quantized Scene transitions
- loop boundaries
- external MIDI Clock behavior

without double-triggering audio.

### Active

Fune rebuilds the same imported project with the real Yacht `Sounds` adapter and sets legacy `Music.state = false` before takeover.

Track mapping:

```text
Fune track 1 -> Yacht Synth 1
Fune track 2 -> Yacht Synth 2
Fune track 3 -> Yacht Synth 3
Fune track 4 -> Yacht Drums
```

The importer preserves Yacht's original `0.25 / 0.5 / 0.75 / 1.0 / 1.5` second note lengths as event metadata, so the Playdate sound behavior can remain compatible even though Fune internally uses tick-based note lifecycle data.

## Bridge API

```lua
FuneBridge:enableShadow()
FuneBridge:enableActive()
FuneBridge:disable()

FuneBridge:play()
FuneBridge:start()
FuneBridge:pause()
FuneBridge:stop()
FuneBridge:update()

FuneBridge:queueScene(2)
FuneBridge:queueNextScene()
FuneBridge:sceneId()
FuneBridge:tick()

FuneBridge:receiveMidi(rawBytes)
```

`receiveMidi()` accepts raw realtime MIDI bytes and shares the Fune MIDI Start / Stop / Continue / Clock implementation used by Linux and macOS.

## What is intentionally not changed yet

- `Music.lua`
- Play/Pause input routing
- Project save format
- PianoRoll / DrumPattern editing
- `Sounds.lua`
- main branch

The first milestone is to prove the imported Fune runtime can run in Shadow and Active modes on the Playdate simulator without changing the editor or synthesis implementation.
