# Optional Fune Core integration

Yacht can use the shared Fune Core as an optional playback kernel while keeping the normal public Yacht checkout fully buildable without Fune.

## Default Yacht build

Yacht ships `Source/FuneBridge.lua` and a small compatibility wrapper around the existing `Music.flipState()` / `Music.Refresh()` entry points.

It does **not** ship the private/generated `FuneCore.lua` bundle.

Without FuneCore:

- `FuneBridge:available()` is false.
- no Fune system-menu item is installed.
- Region/Song playback stays on the legacy Yacht Music path.
- the project remains buildable as an ordinary public Yacht checkout.

## Enable Fune Core locally

Keep Fune and Yacht checked out next to each other, then run from the Fune repository:

```bash
python3 tools/install_yacht_bundle.py ../Yacht
```

The installer:

1. builds Fune's single-file Playdate bundle;
2. writes it to `Yacht/Source/FuneCore.lua`;
3. inserts `import "FuneCore"` immediately before Yacht's committed `import "FuneBridge"` line.

`Source/FuneCore.lua` is gitignored by Yacht and is never committed to this public repository.

If Playdate SDK `pdc` is available:

```bash
python3 tools/install_yacht_bundle.py ../Yacht --build
```

This also runs:

```bash
pdc Source Output.pdx
```

To return the checkout to the public build-safe state:

```bash
python3 tools/install_yacht_bundle.py ../Yacht --uninstall
```

That removes the generated bundle and the local `import "FuneCore"` line.

## Runtime boundary

```text
Yacht UI / project data
 mast / keel / boat / settings
          |
      FuneBridge
          |
     FunePlaydate
          |
 Transport / ScenePlayer
          |
     OutputRouter
          |
      Yacht Sounds
```

Yacht UI, crank/input handling, datastore and synthesis stay Playdate-specific. Fune owns portable Region/Scene/transport/playback behavior when Active.

## Rollout modes

The Playdate system menu gains a `Fune` item only when the generated core is loaded.

### Off

Legacy Yacht playback only.

### Shadow

Legacy Yacht remains audible. Fune imports the same project and advances silently for comparison.

### Active

Fune owns transport/playback and routes its events back into Yacht's existing `Sounds` implementation.

Track mapping:

```text
Fune track 1 -> Yacht Synth 1
Fune track 2 -> Yacht Synth 2
Fune track 3 -> Yacht Synth 3
Fune track 4 -> Yacht Drums
```

## Compatibility

Fune's Yacht adapter supports both meanings of `Music.currentPosition`:

- Region mode: direct Region number.
- Song mode: arrangement position resolved through `keel`.

It also supports:

- 96 PPQN internal transport;
- Yacht 16-step UI position mapping;
- Yacht BPM and 0-50% Swing live updates;
- looping/non-looping songs;
- Yacht note length metadata;
- project Load detection;
- stopped-state note/drum/arrangement edit refresh;
- MIDI Start / Stop / Continue / Clock in the shared runtime.

## Tests

The public Yacht CI verifies both paths:

```bash
lua5.4 tests/music_smoke.lua          # no FuneCore, legacy path
lua5.4 tests/funebridge_smoke.lua     # bridge API
lua5.4 tests/music_fune_smoke.lua     # injected core takeover path
```

Fune's own CI separately verifies bundle generation, installer install/uninstall behavior, Yacht import/runtime behavior, Linux ALSA and macOS CoreMIDI adapters.
