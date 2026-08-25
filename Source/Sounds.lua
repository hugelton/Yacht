-- Sounds.lua

local snd = playdate.sound

Sounds = {}
Sounds.soloState = {
    synth1 = false,
    synth2 = false,
    synth3 = false,
    drums = false
}
Sounds.currentSoloTrack = nil

-- Frames per wavetable cell. Must be a power of two; every bundled sample is
-- long enough to yield at least ten cells at this size.
Sounds.WAVETABLE_CELL = 256

-- Which voice source each synth is currently running, and what it was asked
-- for. They differ when a sample is missing and we fall back to oscillator.
Sounds.synthModes = {}

local function loadSynthSample(name)
    if type(name) ~= "string" or name == "" then return nil end
    local path = Sounds.getSamplePath(name)
    if not path or not playdate.file.exists(path) then return nil end
    return playdate.sound.sample.new(path)
end

-- sample:getLength() is in seconds; frame offsets are what setPlayRange and
-- the wavetable slicer actually need.
function Sounds.sampleFrameCount(sample)
    if not sample then return 0 end
    local seconds = sample:getLength() or 0
    local rate = sample:getSampleRate() or 44100
    return math.floor(seconds * rate)
end

local function wavetableCells(sample)
    return math.max(1, math.floor(Sounds.sampleFrameCount(sample) / Sounds.WAVETABLE_CELL))
end

-- 0-1 fraction of the sample that a "sample" voice plays back.
function Sounds.samplerLength(params)
    local sampler = params and params.sampler
    local value = sampler and tonumber(sampler.length) or 1
    return math.max(0.01, math.min(1, value))
end

-- Semitone offset applied to sample and wavetable voices (+/- 24).
function Sounds.synthTranspose(synthIndex)
    local params = sail["synth" .. synthIndex]
    if not params or not params.sampler then return 0 end
    if Sounds.getSynthMode(synthIndex) == "osc" then return 0 end
    local tune = tonumber(params.sampler.tune) or 0.5
    return math.floor((tune - 0.5) * 48 + 0.5)
end

-- Returns the new voice plus the mode it actually ended up in.
function Sounds.buildSynthVoice(synthIndex, params)
    local mode = params.mode or "osc"

    if mode == "sample" or mode == "wavetable" then
        local sample = loadSynthSample(params.loadSample)
        if sample then
            if mode == "sample" then
                -- Length trims the take; the wavetable slicer wants it whole.
                local length = Sounds.samplerLength(params)
                local frames = Sounds.sampleFrameCount(sample)
                if length < 1 and frames > 1 then
                    local trimmed = sample:getSubsample(0, math.max(1, math.floor(frames * length)))
                    if trimmed then sample = trimmed end
                end
                local ok, synth = pcall(snd.synth.new, sample)
                if ok and synth then return synth, "sample" end
            else
                local synth = snd.synth.new()
                local ok = pcall(function()
                    synth:setWavetable(sample, Sounds.WAVETABLE_CELL, wavetableCells(sample))
                end)
                if ok then return synth, "wavetable" end
            end
        end
        console.log("Synth " .. tostring(synthIndex) .. ": " .. mode ..
            " unavailable, falling back to oscillator")
    end

    return snd.synth.new(snd.kWaveSine), "osc"
end

-- There is no synth:setSample in the Lua API, so switching voice source means
-- building a fresh synth and swapping the instrument on the channel.
function Sounds.rebuildSynthVoice(synthIndex, params)
    local channelName = "synth" .. synthIndex
    local channel = Sounds.channels[channelName]
    local previous = Sounds.instruments[synthIndex]

    if previous then
        previous:allNotesOff()
        if channel then channel:removeSource(previous) end
    end

    local synth, activeMode = Sounds.buildSynthVoice(synthIndex, params)
    local instrument = snd.instrument.new()
    instrument:addVoice(synth)

    Sounds.synths[synthIndex] = synth
    Sounds.instruments[synthIndex] = instrument
    Sounds.synthModes[synthIndex] = {
        mode = activeMode,
        requested = params.mode or "osc",
        sample = params.loadSample,
        -- Only a sample voice bakes the length into its buffer.
        length = (params.mode == "sample") and Sounds.samplerLength(params) or nil
    }

    if channel then channel:addSource(instrument) end
    return activeMode
end

function Sounds.getSynthMode(synthIndex)
    local state = Sounds.synthModes[synthIndex]
    return state and state.mode or "osc"
end

-- Returns false when the requested mode could not be honoured (missing or
-- unusable sample), in which case the voice stays on the oscillator.
function Sounds.setSynthMode(synthIndex, mode)
    local params = sail["synth" .. synthIndex]
    if not params then return false end
    params.mode = mode
    Sounds.updateSynthParameters(synthIndex, params)
    return Sounds.getSynthMode(synthIndex) == mode
end

function Sounds.setSynthSample(synthIndex, sampleName)
    local params = sail["synth" .. synthIndex]
    if not params then return false end

    local path = Sounds.getSamplePath(sampleName)
    if not path or not playdate.file.exists(path) then return false end

    params.loadSample = sampleName
    Sounds.updateSynthParameters(synthIndex, params)
    return true
end


function Sounds.init()
    console.log("Starting Sounds.init()...")
    Sounds.synths = {}
    Sounds.instruments = {}
    Sounds.channels = {}
    Sounds.drums = {}
    Sounds.drums.lengths = {}
    Sounds.filters = {}
    Sounds.lfos = {}
    Sounds.envs = {}
    Sounds.missingSamples = {}
    Sounds.synthModes = {}
    Sounds.automationPans = { 0, 0, 0 }
    Sounds.currentSoloTrack = nil
    Sounds.soloState = {
        synth1 = false,
        synth2 = false,
        synth3 = false,
        drums = false
    }

    for i = 1, 3 do
        local synthData = sail["synth" .. i]
        Sounds.channels["synth" .. i] = snd.channel.new()

        local filter = snd.twopolefilter.new(snd.kFilterLowPass)
        Sounds.filters[i] = filter
        Sounds.channels["synth" .. i]:addEffect(filter)

        Sounds.lfos[i] = snd.lfo.new()
        Sounds.envs["synth" .. i] = playdate.sound.envelope.new(
            synthData.env.attack,
            synthData.env.decay,
            synthData.env.sustain,
            synthData.env.release
        )

        -- The voice itself depends on the mode (oscillator / wavetable /
        -- sample), so it is built separately and can be swapped later.
        Sounds.rebuildSynthVoice(i, synthData)
        Sounds.updateSynthParameters(i, synthData)
    end



    for i = 1, 6 do
        Sounds.channels["drum" .. i] = snd.channel.new()

        if i == 1 then -- Kick
            Sounds.drums[i] = snd.synth.new(snd.kWaveSine)
            Sounds.drums[i]:setDecay(0.1)
            Sounds.drums[i]:setSustain(1)
            Sounds.drums[i]:setRelease(1)


            Sounds.drums.kickEnv = playdate.sound.envelope.new(0, 0, 0, 0.5)
            Sounds.drums[i]:setFrequencyMod(Sounds.drums.kickEnv)


            Sounds.drums.drive = playdate.sound.overdrive.new()

            Sounds.channels["drum" .. i]:addSource(Sounds.drums[i])
            Sounds.channels["drum" .. i]:addEffect(Sounds.drums.drive)

            Sounds.updateDrumParameters(i, sail["drum" .. i])
        elseif i == 2 then -- Snare
            Sounds.drums[i] = snd.synth.new(snd.kWaveSine)

            Sounds.drums.snappy = snd.synth.new(snd.kWaveNoise)

            Sounds.drums.filter = playdate.sound.twopolefilter.new(snd.kFilterLowPass)

            Sounds.drums.snareEnv = playdate.sound.envelope.new(0, 0.5, 0, 0.05)
            Sounds.drums[i]:setFrequencyMod(Sounds.drums.snareEnv)
            Sounds.drums.totalPitch = 1



            Sounds.drums.snappy:setADSR(0, 0.5, 0, 0.05)

            Sounds.channels["drum" .. i]:addSource(Sounds.drums[i])
            Sounds.channels["drum" .. i]:addSource(Sounds.drums.snappy)
            Sounds.channels["drum" .. i]:addEffect(Sounds.drums.filter)

            Sounds.updateDrumParameters(i, sail["drum" .. i])
        elseif i <= 6 then
            if sail["drum" .. i].loadSample then
                local samplePath = Sounds.getSamplePath(sail["drum" .. i].loadSample)
                local sample = playdate.sound.sample.new(samplePath)
                if sample then
                    Sounds.drums[i] = playdate.sound.sampleplayer.new(sample)

                    Sounds.drums.lengths[i] = Sounds.sampleFrameCount(sample)




                    Sounds.channels["drum" .. i]:addSource(Sounds.drums[i])
                    Sounds.updateDrumParameters(i, sail["drum" .. i])
                else
                    Sounds.missingSamples[i] = samplePath
                    console.log("Missing sample for drum " .. i .. ": " .. samplePath)
                end
            end
        end
    end





    for channelName, channelData in pairs(sail.mixer) do
        if type(channelData) == "table" then
            Sounds.setChannel(channelName, "volume", channelData.volume)
            Sounds.setChannel(channelName, "mute", channelData.mute)
            Sounds.setChannel(channelName, "pan", channelData.pan)
        end
    end






    console.log("Finishing Sounds.init(). Instruments:", Sounds.instruments)
end

function Sounds.load()
    Sounds.currentSoloTrack = nil
    for track in pairs(Sounds.soloState) do Sounds.soloState[track] = false end

    for synthIndex = 1, 3 do
        Sounds.updateSynthParameters(synthIndex, sail["synth" .. synthIndex])
    end
    Sounds.updateDrumParameters(1, sail.drum1)
    Sounds.updateDrumParameters(2, sail.drum2)

    for drumIndex = 3, 6 do
        local drumData = sail["drum" .. drumIndex]
        if drumData.loadSample then
            Sounds.loadDrumSample(drumIndex, drumData.loadSample)
        elseif Sounds.drums[drumIndex] then
            Sounds.channels["drum" .. drumIndex]:removeSource(Sounds.drums[drumIndex])
            Sounds.drums[drumIndex] = nil
            Sounds.drums.lengths[drumIndex] = nil
        end
    end

    for channelName, channelData in pairs(sail.mixer) do
        if type(channelData) == "table" then
            Sounds.setChannel(channelName, "volume", channelData.volume)
            Sounds.setChannel(channelName, "mute", channelData.mute)
            Sounds.setChannel(channelName, "pan", channelData.pan)
        end
    end
end

function Sounds.updateSynthParameters(synthIndex, params)
    synthIndex = tonumber(synthIndex) or synthIndex

    -- Swap the voice first if the mode or the chosen sample changed.
    local state = Sounds.synthModes[synthIndex]
    local wantLength = (params.mode == "sample") and Sounds.samplerLength(params) or nil
    if not state or state.requested ~= (params.mode or "osc") or
        state.sample ~= params.loadSample or state.length ~= wantLength then
        Sounds.rebuildSynthVoice(synthIndex, params)
    end

    local synth = Sounds.synths[synthIndex]
    local lfo = Sounds.lfos[synthIndex]
    local filter = Sounds.filters[synthIndex]
    local env = Sounds.envs["synth" .. synthIndex]
    if not synth then return end

    local activeMode = Sounds.getSynthMode(synthIndex)
    -- Which SDK synth parameter each MOD row drives. Oscillators expose two
    -- parameters; a wavetable exposes its 0-1 scan position on parameter 2;
    -- a plain sample voice has none.
    local modTarget1, modTarget2
    if activeMode == "osc" then
        modTarget1, modTarget2 = 1, 2
    elseif activeMode == "wavetable" then
        modTarget1 = 2
    end

    -- オシレーター
    local waveforms = {
        [0] = snd.kWaveSine,
        [1] = snd.kWaveSquare,
        [2] = snd.kWaveSawtooth,
        [3] = snd.kWaveTriangle,
        [4] = snd.kWaveNoise,
        [5] = snd.kWavePOPhase,
        [6] = snd.kWavePODigital,
        [7] = snd.kWavePOVosim
    }

    -- LFO
    local lfoWaveforms = {
        [0] = snd.kLFOSine,
        [1] = snd.kLFOSquare,
        [2] = snd.kLFOSawtoothUp,
        [3] = snd.kLFOSawtoothDown,
        [4] = snd.kLFOTriangle,
        [5] = snd.kLFOSampleAndHold
    }

    -- オシレーター設定
    if activeMode == "osc" then
        synth:setWaveform(waveforms[params.oscillator.form] or snd.kWaveSine)
        synth:setParameter(1, params.oscillator.param1)
        synth:setParameter(2, params.oscillator.param2)
    elseif activeMode == "wavetable" then
        -- ① scans across the table; the Form knob has no meaning here.
        synth:setParameter(2, params.oscillator.param1)
    end

    -- フィルター設定
    Sounds.updateFilterParameters(synthIndex, params.filter)

    -- アンプ設定
    synth:setVolume(params.amp.volume)
    synth:setAttack(params.amp.attack)
    synth:setDecay(params.amp.decay)
    synth:setSustain(params.amp.sustain)
    synth:setRelease(params.amp.release)

    -- LFO設定
    if lfo then
        lfo:setType(lfoWaveforms[params.lfo.form] or snd.kLFOSine)
        lfo:setRate(params.lfo.frequency * 20)
        -- depth を数値として扱う
        local lfoDepth = tonumber(params.lfo.depth) or 0
        lfo:setDepth(lfoDepth)
        lfo:setDelay(params.lfo.hold, params.lfo.delay)
    end

    -- エンベロープ設定
    if env then
        env:setAttack(params.env.attack or 0)
        env:setDecay(params.env.decay or 0)
        env:setSustain(params.env.sustain or 0)
        env:setRelease(params.env.release or 0)
        -- depth を数値として扱う
        local envDepth = tonumber(params.env.depth) or 0
        env:setScale(envDepth * 10)
    end

    -- モジュレーション設定
    -- フリケンシーモジュレーション
    if params.lfo.pitch then
        synth:setFrequencyMod(lfo)
    elseif params.env.pitch then
        synth:setFrequencyMod(env)
    else
        synth:setFrequencyMod(nil)
    end

    -- フィルターモジュレーション
    if params.lfo.filter then
        filter:setFrequencyMod(lfo)
    elseif params.env.filter then
        filter:setFrequencyMod(env)
    else
        filter:setFrequencyMod(nil)
    end

    -- パラメーター1モジュレーション
    if modTarget1 then
        if params.lfo.param1 then
            synth:setParameterMod(modTarget1, lfo)
        elseif params.env.param1 then
            synth:setParameterMod(modTarget1, env)
        else
            synth:setParameterMod(modTarget1, nil)
        end
    end

    -- パラメーター2モジュレーション
    if modTarget2 then
        if params.lfo.param2 then
            synth:setParameterMod(modTarget2, lfo)
        elseif params.env.param2 then
            synth:setParameterMod(modTarget2, env)
        else
            synth:setParameterMod(modTarget2, nil)
        end
    end
end

function Sounds.updateFilterParameters(synthIndex, params)
    local filter = Sounds.filters[synthIndex]

    -- フィルタータイプの設定
    local filterTypes = {
        [0] = snd.kFilterLowPass,
        [1] = snd.kFilterHighPass,
        [2] = snd.kFilterBandPass,
        [3] = snd.kFilterNotch,
        [4] = snd.kFilterPEQ,
        [5] = snd.kFilterLowShelf,
        [6] = snd.kFilterHighShelf
    }
    filter:setType(filterTypes[params.type] or snd.kFilterLowPass)

    -- フィルター周波数の設定（0-1の範囲を20-20000 Hzに変換）
    local frequency = 20 * math.exp(math.log(1000) * params.cutoff)
    filter:setFrequency(frequency)

    -- レゾナンスの設定
    filter:setResonance(params.resonance)

    -- ミックスレベルの設定（デフォルトは1 = 100%ウェット）
    filter:setMix(1)

    -- ゲインの設定（PEQとシェルフタイプのフィルターでのみ使用）
    if params.type == 4 or params.type >= 5 then -- PEQ or Shelf types
        filter:setGain(params.gain or 0)         -- gainパラメータが存在しない場合は0をデフォルト値として使用
    end
end

function Sounds.updateDrumParameters(drumIndex, params)
    local drum = Sounds.drums[drumIndex]

    if drumIndex == 1 then -- Kick
        -- ピッチエンベロープの設定

        Sounds.drums.kickEnv:setScale(params.slope * 10)
        Sounds.drums.kickEnv:setOffset(params.pitch - 2)
        Sounds.drums.kickEnv:setCurvature(params.curve)
        Sounds.drums.kickEnv:setDecay(params.decay)
        drum:setRelease(params.decay)
        -- drum:setFrequencyMod(env)

        -- オーバードライブのパラメータ更新
        Sounds.drums.drive:setMix(params.mix)
        Sounds.drums.drive:setLimit(params.limit)
        Sounds.drums.drive:setGain(params.gain * 2)
    elseif drumIndex == 2 then -- Snare
        -- フィルターのパラメータ更新
        Sounds.drums.totalPitch = params.pitch * 200
        -- print(Sounds.drums.totalPitch)
        Sounds.drums.filter:setFrequency(params.tone * 10000)
        Sounds.drums.snareEnv:setDecay(params.decay)
        Sounds.drums.snareEnv:setScale(params.slope)
        Sounds.drums.snappy:setVolume(params.snappy)
        Sounds.drums.snappy:setDecay(params.decay)
        drum:setDecay(params.decay)
    else -- Sample-based drums
        if drum then
            -- A rate of exactly 0 stalls the player.
            drum:setRate(math.max(0.01, params.pitch))

            -- setPlayRange takes integer frame offsets, not seconds.
            local frames = Sounds.drums.lengths[drumIndex]
            if frames and frames > 0 then
                local last = math.max(1, math.floor(frames * math.max(0, math.min(1, params.length))))
                drum:setPlayRange(0, last)
            end
        end
    end

    -- 共通パラメータ設定（シンセドラムの場合）
    if drumIndex <= 2 then
        drum:setAttack(0)
        drum:setDecay(params.decay)
        drum:setSustain(0)
        drum:setRelease(0.05)
    end
end

function Sounds.playDrum(drumIndex, velocity)
    if Sounds.drums[drumIndex] then
        if drumIndex == 1 then
            -- Synthesized drums (Kick and
            Sounds.drums[drumIndex]:playNote(60, velocity, 0.5)
        elseif drumIndex == 2 then
            -- Snare)



            Sounds.drums.snappy:playNote(500, velocity, 1)
            Sounds.drums[drumIndex]:playNote(Sounds.drums.totalPitch, velocity, 1)
        else
            -- Sample-based drums (3-6). play()'s first argument is the repeat
            -- count and must be an integer, so velocity goes to the volume.
            local player = Sounds.drums[drumIndex]
            if player.play then
                player:setVolume(math.max(0, math.min(1, velocity or 1)))
                player:play(1)
            end
        end
    end
end

-- サンプル名からフルパスを生成するヘルパー関数
function Sounds.getSamplePath(sampleName)
    if not sampleName then return nil end

    -- 既にフルパスの場合はそのまま返す
    if sampleName:match("^Samples/.*%.wav$") then
        return sampleName
    end

    -- Mic recordings live in the writable Data folder, not the bundle.
    if Recorder.isRecordingName(sampleName) then
        return Recorder.path(sampleName)
    end

    -- ショートネームをフルパスに変換
    return "Samples/" .. sampleName .. ".wav"
end

-- loadDrumSample関数を修正
function Sounds.loadDrumSample(drumNumber, sampleName)
    if drumNumber > 2 and drumNumber <= 6 then
        local samplePath = Sounds.getSamplePath(sampleName)
        local sample = playdate.sound.sample.new(samplePath)

        if sample then
            if Sounds.drums[drumNumber] then
                Sounds.drums[drumNumber]:setSample(sample)
            else
                Sounds.drums[drumNumber] = playdate.sound.sampleplayer.new(sample)
                Sounds.channels["drum" .. drumNumber]:addSource(Sounds.drums[drumNumber])
            end
            Sounds.drums.lengths[drumNumber] = Sounds.sampleFrameCount(sample)

            -- sailの更新時はショートネームを保存
            local drumData = sail["drum" .. drumNumber]
            if drumData then
                drumData.loadSample = sampleName -- フルパスではなくショートネームを保存
                Sounds.updateDrumParameters(drumNumber, drumData)
            end
            console.log("Loaded sample for drum " .. drumNumber .. ": " .. sampleName)
            Sounds.missingSamples[drumNumber] = nil
            return true
        else
            console.log("Failed to load sample: " .. samplePath)
            Sounds.missingSamples[drumNumber] = samplePath
        end
    end
    return false
end

function Sounds.playMidiSynth(synthIndex, note, velocity, length, automationPan)
    local instrument = Sounds.instruments[synthIndex]
    if not instrument then return end

    local channelName = "synth" .. synthIndex
    Sounds.automationPans[synthIndex] = automationPan or 0
    Sounds.setChannel(channelName, "pan", sail.mixer[channelName].pan)

    local tuned = math.max(0, math.min(127, note + Sounds.synthTranspose(synthIndex)))
    instrument:playMIDINote(tuned, velocity, length)
end

local function channelGroup(channelName)
    if channelName:sub(1, 5) == "synth" then return channelName end
    if channelName:sub(1, 4) == "drum" then return "drums" end
    return channelName
end

function Sounds.applyChannelVolume(channelName)
    local channel = Sounds.channels[channelName]
    local mixerData = sail.mixer[channelName]
    if not channel or not mixerData then return end

    local isAudible
    if Sounds.currentSoloTrack then
        isAudible = channelGroup(channelName) == Sounds.currentSoloTrack
    else
        isAudible = not mixerData.mute
    end
    channel:setVolume(isAudible and mixerData.volume or 0)
end

function Sounds.refreshChannelVolumes()
    for channelName in pairs(Sounds.channels) do
        Sounds.applyChannelVolume(channelName)
    end
end

function Sounds.setChannel(channelName, parameter, value)
    local channel = Sounds.channels[channelName]
    if channel then
        if parameter == "volume" then
            Sounds.applyChannelVolume(channelName)
        elseif parameter == "pan" then
            local synthIndex = tonumber(channelName:match("^synth(%d+)$"))
            local automationPan = synthIndex and Sounds.automationPans[synthIndex] or 0
            channel:setPan(math.max(-1, math.min(1, value + automationPan)))
        elseif parameter == "mute" then
            Sounds.applyChannelVolume(channelName)
        end
    end
end

function Sounds.setPan(sourceType, index, pan)
    local channelKey = sourceType == "synth" and "synth" .. index or "drum" .. index
    local channel = Sounds.channels[channelKey]
    if channel then
        channel:setPan(pan)
    end
end

function Sounds.solo(track)
    if track ~= "synth1" and track ~= "synth2" and track ~= "synth3" and track ~= "drums" then
        print("Invalid track: " .. track)
        return
    end

    if Sounds.currentSoloTrack == nil then
        Sounds.soloState[track] = true
        Sounds.currentSoloTrack = track
        Sounds.muteOtherTracks(track)
        print("Soloed track: " .. track)
    elseif Sounds.currentSoloTrack == track then
        Sounds.soloState[track] = false
        Sounds.currentSoloTrack = nil
        Sounds.unmuteAllTracks()
        print("Unsoloed track: " .. track)
    else
        Sounds.soloState[Sounds.currentSoloTrack] = false
        Sounds.soloState[track] = true
        Sounds.currentSoloTrack = track
        Sounds.muteOtherTracks(track)
        print("Switched solo to track: " .. track)
    end
end

function Sounds.muteOtherTracks()
    Sounds.refreshChannelVolumes()
end

function Sounds.unmuteAllTracks()
    Sounds.refreshChannelVolumes()
end

function Sounds.muteTrack(track)
    if track == "drums" then
        for i = 1, 6 do
            Sounds.applyChannelVolume("drum" .. i)
        end
    else
        Sounds.applyChannelVolume(track)
    end
end

function Sounds.hasSolo()
    return Sounds.currentSoloTrack ~= nil
end

function Sounds.getSolo()
    return Sounds.currentSoloTrack and { Sounds.currentSoloTrack } or {}
end

return Sounds
