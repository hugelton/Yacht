-- mast : song data
mast = {
    name = "Untitled",
    bpm = 120.0,
    swing = 0.0,
    steps = 16,
    measure = 4,
    isPlaying = false,
    isSolo = false,

}

-- keel : song construction data
keel = {
    songEnd = 4,
    loop = false,
    synth1 = { 1, 1, 1, 1 },
    synth2 = { 1, 1, 1, 1 },
    synth3 = { 1, 1, 1, 1 },
    drums = { 1, 1, 1, 1 },
}
-- boat : region data
boat = {

    -- synth : region -> patterns
    synths = {
        {     -- region
            { -- synth1
                notes = { 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, },
                length = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, },
                pan = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                velos = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, },

            },
            { -- synth2
                notes = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                length = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                pan = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                velos = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, },

            },
            { --symth3
                notes = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                length = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                pan = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                velos = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, },
            }

        },

    },

    -- boat -> drums : region -> patterns
    drums = {
        { -- region
            patterns = {

                { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, },
                { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, },
                { 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, },
                { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, },
                { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
                { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },

            },
            accent = { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 },
            velos = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            active = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
            chance = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
        },
    }
}

-- sail : synth data
sail = {
    synth1 = {
        oscillator = { form = 2, param1 = 0, param2 = 0 },
        filter = { type = 0, cutoff = 0.3, resonance = 0.1 },
        amp = { volume = 1, attack = 0, decay = 0.3, sustain = 0, release = 0 },
        lfo = {
            form = 0,
            frequency = 0,
            depth = 0,
            pitch = false,
            param1 = false,
            param2 = false,
            filter = false,
            hold = 0.0,
            delay = 0
        },
        env = { attack = 0, decay = 0.4, sustain = 0, release = 0, pitch = false, filter = true, param1 = false, param2 = false, depth = 1.0 }
    },
    synth2 = {
        oscillator = { form = 2, param1 = 0, param2 = 0 },
        filter = { type = 0, cutoff = 1, resonance = 0 },
        amp = { volume = 1, attack = 0, decay = 0, sustain = 1, release = 0 },
        lfo = {
            form = 0,
            frequency = 0,
            depth = 0,
            pitch = false,
            param1 = false,
            param2 = false,
            filter = true,
            hold = 0.0,
            delay = 0
        },
        env = { attack = 0, decay = 0.0, sustain = 1, release = 0, pitch = false, filter = false, param1 = false, param2 = false, depth = 1.0 }

    },
    synth3 = {
        oscillator = { form = 2, param1 = 0, param2 = 0 },
        filter = { type = 0, cutoff = 1, resonance = 0 },
        amp = { volume = 1, attack = 0, decay = 0, sustain = 1, release = 0 },
        lfo = {
            form = 0,
            frequency = 0,
            depth = 0,
            pitch = false,
            param1 = false,
            param2 = false,
            filter = true,
            hold = 0.0,
            delay = 0
        },
        env = { attack = 0, decay = 0.0, sustain = 1, release = 0, pitch = false, filter = false, param1 = false, param2 = false, depth = 1.0 }
    },
    drum1 = {
        waveform = 0,
        pitch = 0.5,
        slope = 0.5,
        decay = 0.3,
        curve = 1.0,
        gain = 1.0,
        limit = 0.5,
        mix = 1.0

    },
    drum2 = {
        snappy = 0.5,
        pitch = 0.5,
        slope = 0.5,
        decay = 0.5,
        tone = 1.0
    },
    drum3 = { loadSample = "09_CH", pitch = 0.5, length = 1.0 },
    drum4 = { loadSample = "09_OH", pitch = 0.5, length = 1.0 },
    drum5 = { loadSample = "77_LT", pitch = 0.5, length = 1.0 },
    drum6 = { loadSample = "08_CP", pitch = 0.5, length = 1.0 },

    mixer = {
        synth1 = { volume = 0.8, mute = true, pan = 0.0 },
        synth2 = { volume = 0.8, mute = true, pan = 0.0 },
        synth3 = { volume = 0.8, mute = true, pan = 0.0 },
        drum1 = { volume = 0.8, mute = true, pan = 0.0 },
        drum2 = { volume = 0.8, mute = true, pan = 0.0 },
        drum3 = { volume = 0.8, mute = false, pan = 0.0 },
        drum4 = { volume = 0.8, mute = true, pan = 0.0 },
        drum5 = { volume = 0.8, mute = true, pan = 0.0 },
        drum6 = { volume = 0.8, mute = true, pan = 0.0 },
        volume = 1.0
    }
}



settings = {
    -- カーソル設定
    cursorBlinkSpeed = 0.5, -- 秒単位、小さいほど速く点滅

    -- MIDI設定
    midiEnabled = true, -- MIDIのon/off

    -- シンセサイザーとドラムのMIDIチャンネル設定（MIDI出力用）
    midiChannels = {
        syn1 = 1,
        syn2 = 2,
        syn3 = 3,
        drums = 10, -- 一般的にドラムはチャンネル10を使用
    },

    -- ドラムのインストゥルメントごとのMIDI note number（MIDI出力用）
    drumMidiNotes = {
        kick = 36,        -- C1
        snare = 38,       -- D1
        closedHiHat = 42, -- F#1
        openHiHat = 46,   -- A#1
        percussion1 = 47, -- B1
        percussion2 = 48, -- C2
    },

    -- MIDIクロック設定
    midiClockSource = "Internal", -- "Internal" または "External"
    midiClockOutput = true,       -- MIDI clockの出力をするかしないか

    -- その他の設定（必要に応じて）
    tempo = 120, -- BPM
    swing = 0,   -- スイング量（0-1の範囲）
}
