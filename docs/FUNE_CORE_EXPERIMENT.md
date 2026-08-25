# Fune Core experiment

This branch lets Yacht compare its legacy playback engine with the shared Fune Core without committing the private Fune source into this public repository.

## Layout

```text
Fune/                     private repository
  tools/install_yacht_bundle.py
  ...

Yacht/                    public repository
  Source/FuneBridge.lua   tracked
  Source/Music.lua        tracked integration wrapper
  Source/FuneCore.lua     generated locally, gitignored
```

`Source/FuneCore.lua` is a generated bundle. Do not commit it to Yacht.

## Prepare a local build

Check out the experiment branch in Yacht:

```bash
cd Yacht
git switch experiment/fune-core
```

With the Fune and Yacht repositories next to each other, run from Fune:

```bash
cd ../Fune
python3 tools/install_yacht_bundle.py ../Yacht
```

This builds the current Playdate bundle and installs it as:

```text
Yacht/Source/FuneCore.lua
```

If the Playdate SDK `pdc` command is already on `PATH`, installation and compilation can be done in one command:

```bash
python3 tools/install_yacht_bundle.py ../Yacht --build
```

Equivalent manual build from Yacht:

```bash
pdc Source Output.pdx
```

Open `Output.pdx` in the Playdate Simulator as usual.

## Runtime modes

The Playdate system menu gains a `Fune` option after Yacht starts:

- `Off` — legacy Yacht Music playback only.
- `Shadow` — legacy Yacht playback remains audible while Fune runs silently from the same project data. Use this for transport/position comparison.
- `Active` — Fune owns playback and routes its events into the existing Yacht `Sounds` implementation.

The normal Yacht controls are unchanged. GlobalBar Play, A+B, and the Simulator playback shortcut still call `Music.flipState()`; the wrapper chooses the active engine.

## Compatibility behavior

Fune currently mirrors Yacht's two playback modes:

- Region mode: `currentPosition` directly selects Region N on all four tracks.
- Song mode: `currentPosition` is the arrangement position and each track resolves its Region through `keel`.

Song mode advances at bar boundaries, follows Yacht loop state, and a non-looping song stops after its final bar and returns to position 1.

Yacht BPM changes are sent to the Fune transport immediately. Yacht Swing 0–50% maps to Fune swing 0–1, where 50% produces a 75/25 sixteenth-note pair while preserving the total pair duration.

The Fune transport runs at 96 PPQN. Active mode maps that position back to Yacht's 1–16 `Music.tick` display so existing UI code does not need a second playhead implementation.

## Editing and project load

Project Load replaces `mast`, `keel`, `boat`, and `settings`; FuneBridge detects this and rebuilds its playback snapshot automatically.

For edits made in-place to notes, drum patterns, velocities, note lengths, pan, chance/active/accent, arrangement slots, and MIDI mappings, FuneBridge keeps a lightweight playback-data fingerprint. Edits made while stopped are incorporated before the next Play. Edits made while playing are deferred until playback is paused, avoiding a transport jump in the middle of a bar.

BPM and Swing are live parameters and do not rebuild the snapshot.

## Tests

The experiment branch runs SDK-independent smoke tests in GitHub Actions:

```bash
lua5.4 tests/funebridge_smoke.lua
lua5.4 tests/music_fune_smoke.lua
```

These cover mode switching, Shadow/Active routing, Yacht UI state synchronization, BPM/Swing synchronization, project replacement, and in-place edit refresh.

Actual `pdc` compilation is intentionally left to a local Playdate SDK installation. Panic's SDK download requires acceptance of the Playdate SDK license, so the public CI does not automatically download or redistribute the SDK.
