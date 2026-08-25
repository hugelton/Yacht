# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

Yacht is a music creation tool (DAW) for the Playdate handheld gaming system, written in Lua. It features a piano roll sequencer, drum pattern editor, synthesizer controls, and song arrangement capabilities.

**Metadata:** Version 1.0.8, Author: hügelton instrument (Leo Kuroshita), Kobe, Japan

**License:** Source code is GPL-3.0; UI graphics/assets are CC BY-NC-SA 4.0; Fonts are OFL-1.1

## Build and Run

**Build:**
```bash
pdc Source Output.pdx
```

**Run on simulator:**
The Output.pdx bundle can be run directly in the Playdate Simulator.

**Clean build:**
```bash
rm -rf Output.pdx
pdc Source Output.pdx
```

## Architecture

### Core Data Structure (The Boat Metaphor)

The project uses a nautical metaphor for its data structure:

- **mast**: Song metadata (name, BPM, swing, steps per measure, isPlaying, isSolo)
- **sail**: Synthesizer and drum sound parameters (oscillator, filter, amp, LFO, envelope settings)
- **keel**: Song construction data (which patterns to play in each measure, song end position, loop setting)
- **boat**: Region data containing actual note data for synths and drum patterns

This structure is validated and serialized/deserialized as JSON for save/load.

### Page System

The app is organized into pages, each with its own UI and logic:

- **PianoRoll**: Note editing and automation (two modes: notes/automation)
- **DrumPattern**: Drum pattern editor with velocity, accent, chance and per-step mute (the `accent`/`active` lanes on a drum region)
- **SynthEdit**: 3-voice synthesizer editor (oscillator, filter, amp, LFO, envelope). The Mode column selects the voice source per synth: `osc` (built-in waveform), `wavetable` (a sample sliced into 256-frame cells, scanned by ①) or `sample` (pitched playback). Stored as `sail.synthN.mode` / `sail.synthN.loadSample`; both are optional so older projects load as `osc`.
- **DrumEdit**: Drum sample editor with 6 drum slots (kick, snare, closed hi-hat, open hi-hat, percussion 1-2)
- **Mixer**: Volume and pan controls for all channels
- **SongEdit**: Pattern-based song arrangement
- **Visualizer**: Real-time visualization of playing notes
- **Preferences**: System settings including MIDI configuration

Each page is a module with `init()`, `handleInput()`, and `draw()` functions.

### Focus System

Input routing is managed through `currentFocus`:
- `"main"`: Active page receives input
- `"globalBar"`: Global navigation bar
- `"Toolbox"`: Quick action toolbox
- `"pageSwitcher"`: Page selection overlay
- `"dialog"`: Modal dialogs (e.g., sample selector)
- `"FileDialog"`: File load/save dialog

The B button cycles focus: main ↔ globalBar ↔ pageSwitcher (closes on exit)

### Input Handling

- **KeyManager**: Custom wrapper for Playdate input
- **CrankManager**: Handles crank input for parameter adjustments
- **Keyboard shortcuts**: Number keys 1-9 for quick page switching, E for play/pause, R for mode toggle, Q for page switcher

### Audio System

- **Music.lua**: Handles playback state, timing, tick updates
- **Sounds.lua**: Manages synth and drum sound engines
- **MIDI.lua**: MIDI input/output support (configurable in Preferences)

All audio synthesis uses Playdate's built-in sound engine.

### Save/Load System

Projects are saved/loaded as JSON using `playdate.datastore`:
- Menu items: "Load" (file browser) and "Save" (uses project name from mast.name)
- Data validation ensures structure integrity before loading
- All four components (sail, mast, keel, boat) must be present and valid

### Assets

- Custom fonts in `Source/fonts/`: Cavs, Nada, Gloria (OFL-1.1 licensed)
- UI images in `Source/images/`
- Drum samples in `Source/Samples/`
- System assets (launch image, card image) in `Source/SystemAssets/`

Managed through `assets.lua` module.

## Development Notes

- The codebase uses a module pattern with explicit imports
- Each page module should follow the init/handleInput/draw pattern
- Background images change based on current page (set in sprite background callback)
- The `Balloon` system provides temporary toast notifications
- Cursor management includes a custom cursor sprite with blink speed configuration
- Debug drawing is available through `playdate.debugDraw()` (toggle with posDetect)
