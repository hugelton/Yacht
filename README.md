# Yacht - The Handheld Music Studio

![card](https://github.com/user-attachments/assets/c2ccc0da-5949-4fd8-b213-61de6916fb7b)

Yacht is a music creation tool designed for the Playdate handheld gaming system. It features a piano roll sequencer, drum pattern editor, synthesizer controls, and song arrangement capabilities.

https://kurogedelic.itch.io/yacht

## Features

- Wrote by Playdate LUA
- Piano roll with note editing and automation
- Drum pattern editor with velocity, accent, chance and per-step mute
- 3 synthesizer channels with comprehensive sound design controls
- Three voice modes per synth: oscillator, wavetable and sampler
- Sample-based drum machine with 6 drum slots
- Mixer with volume and pan controls
- Pattern-based song arrangement system
- Realtime visualization of playing notes

## Synth voice modes

The Mode column on the left of the SynthEdit page picks what each of the three
synths plays. A + up/down cycles the mode.

| Mode | Voice | Notes |
| --- | --- | --- |
| Osc | Built-in waveform | Form picks one of 8 waveforms; ① / ② are the synth parameters |
| Wave | The sample sliced into 256-frame wavetable cells | Scan moves across the table and can be driven from the MOD matrix |
| Smpl | The sample played back pitched | MIDI note 60 (C4) plays at normal speed |

Selecting Wave or Smpl swaps the oscillator panel for the sampler panel, which
replaces the scope and the Form slider with these controls:

| Control | What it does |
| --- | --- |
| Sample slot | Shows the loaded sample; A opens the picker |
| REC | A records from the microphone, A again stops early |
| Scan / Len | Wavetable position, or playback length for a plain sample |
| Tune | Transposes the voice by up to +/- 2 octaves |

Filter, amplifier, LFO and envelope apply in every mode. If a sample cannot be
loaded the voice falls back to the oscillator and the slot label shows a `!`.

Recordings are captured as up to 4 seconds of 16-bit mono, stored in the app's
Data folder as `recordings/RECn.pda` across 8 slots, and appear in the sample
picker alongside the bundled drum samples. They are saved in Playdate's own
`.pda` format because the SDK cannot read back the WAV files it writes.

## Drum pattern lanes

Below the six drum rows the editor has two value lanes. On either lane, A alone
toggles a flag and A + up/down changes the value:

| Lane | A | A + up/down |
| --- | --- | --- |
| Velocity | accent on/off (boosts the step by 25%) | step velocity |
| Chance | step on/off (a muted step plays nothing) | probability the step fires |

## Behavior

Save and load project data on JSON file.

## Development

Build the Playdate bundle:

```sh
pdc Source Output.pdx
```

Run the smoke tests:

```sh
for t in tests/*.lua; do lua "$t" || break; done
```

The bundled drum sounds in `Source/Samples` are original procedural samples
made without third-party recordings.

Project JSON files contain a `formatVersion` field. Files created before this
field was introduced are treated as format version 1.

The optional USB serial MIDI bridge accepts text commands through the Playdate
serial message interface. Incoming `drum` notes are matched against the drum
note map on the Preferences page:

```text
note CHANNEL NOTE VELOCITY [LENGTH]
drum NOTE VELOCITY
start
continue
stop
clock
```

## License

### Source Code

The source code is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

### UI Graphics and Assets

All UI graphics and visual assets are licensed under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0). This means you are free to:

- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material

Under the following terms:

- Attribution — You must give appropriate credit
- NonCommercial — You may not use the material for commercial purposes
- ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license

### Fonts

- Cavs
- Nada
- Groria

The custom fonts used in this project were created by Leo Kuroshita and are licensed under the SIL Open Font License 1.1 (OFL-1.1). This means you are free to:

- Use the fonts in your own works
- Share and distribute the fonts
- Modify the fonts to create derivative works

Under the following terms:

- Attribution is required
- Modified fonts must be released under the same license
- The fonts cannot be sold by themselves, but may be bundled with software

## Acknowledgments

Made by Leo Kuroshita from Hügelton Instrument. kobe, japan.

## Disclaimer

This is a hobby project. While I've made it open source because I believe it might be valuable to others, the code may not be extensively documented. Feel free to explore and learn from it, but please understand its experimental nature.

---

Note: This is a creative endeavor and the code structure reflects its organic development. While functional, it may not follow all best practices and could benefit from community improvements.
