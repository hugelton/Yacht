-- Sounds.lua

local snd = playdate.sound
local sail = sail -- data.luaからsailを参照

Sounds = {}
Sounds.soloState = {
    synth1 = false,
    synth2 = false,
    synth3 = false,
    drums = false
}
Sounds.currentSoloTrack = nil


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

    for i = 1, 3 do
        local synthData = sail["synth" .. i]
        local synth = snd.synth.new(snd.kWaveSine)
        Sounds.synths[i] = synth
        Sounds.instruments[i] = snd.instrument.new()
        Sounds.instruments[i]:addVoice(synth)
        Sounds.channels["synth" .. i] = snd.channel.new()
        Sounds.channels["synth" .. i]:addSource(Sounds.instruments[i])
        local filterData = sail["synth" .. i].filter
        local filter = snd.twopolefilter.new(snd.kFilterLowPass)
        Sounds.filters[i] = filter
        Sounds.channels["synth" .. i]:addEffect(filter)

        Sounds.lfos[i] = snd.lfo.new()
        Sounds.envs["synth" .. i] = playdate.sound.envelope.new(
            sail["synth" .. i].env.attack,
            sail["synth" .. i].env.decay,
            sail["synth" .. i].env.sustain,
            sail["synth" .. i].env.release
        )


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

                    Sounds.drums.lengths[i] = Sounds.drums[i]:getLength()




                    Sounds.channels["drum" .. i]:addSource(Sounds.drums[i])
                    Sounds.updateDrumParameters(i, sail["drum" .. i])
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

function Sounds.updateSynthParameters(synthIndex, params)
    local synth = Sounds.synths[synthIndex]
    local lfo = Sounds.lfos[synthIndex]
    local filter = Sounds.filters[synthIndex]
    local env = Sounds.envs["synth" .. synthIndex]

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
    synth:setWaveform(waveforms[params.oscillator.form] or snd.kWaveSine)
    synth:setParameter(1, params.oscillator.param1)
    synth:setParameter(2, params.oscillator.param2)

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
    if params.lfo.param1 then
        synth:setParameterMod(1, lfo)
    elseif params.env.param1 then
        synth:setParameterMod(1, env)
    else
        synth:setParameterMod(1, nil)
    end

    -- パラメーター2モジュレーション
    if params.lfo.param2 then
        synth:setParameterMod(2, lfo)
    elseif params.env.param2 then
        synth:setParameterMod(2, env)
    else
        synth:setParameterMod(2, nil)
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
            drum:setRate(params.pitch)



            drum:setPlayRange(1, Sounds.drums.lengths[drumIndex] * params.length)
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
            -- Sample-based drums (3-6)
            if Sounds.drums[drumIndex].play then -- sampleplayerならplayメソッドを使用
                Sounds.drums[drumIndex]:play(velocity)
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

            -- sailの更新時はショートネームを保存
            local drumData = sail["drum" .. drumNumber]
            if drumData then
                drumData.loadSample = sampleName -- フルパスではなくショートネームを保存
                Sounds.updateDrumParameters(drumNumber, drumData)
            end
            console.log("Loaded sample for drum " .. drumNumber .. ": " .. sampleName)
        else
            console.log("Failed to load sample: " .. samplePath)
        end
    end
end

function Sounds.playMidiSynth(synthIndex, note, velocity, length)
    -- print(synthIndex, note, velocity, length)
    Sounds.instruments[synthIndex]:playMIDINote(note, velocity, length)
end

function Sounds.setChannel(channelName, parameter, value)
    local channel = Sounds.channels[channelName]
    if channel then
        if parameter == "volume" then
            if not sail.mixer[channelName].mute then
                channel:setVolume(value)
            else
                channel:setVolume(0)
            end
        elseif parameter == "pan" then
            channel:setPan(value)
        elseif parameter == "mute" then
            if value then
                channel:setVolume(0)
            else
                channel:setVolume(sail.mixer[channelName].volume)
            end
        end
    end
end

function Sounds.updateEchoParameters()
    Sounds.echo:setFeedback(sail.effects.echo.feedback)

    for channelName, channelData in pairs(sail.mixer) do
        if type(channelData) == "table" and channelData.echo ~= nil then
            local echo = Sounds.echoes[channelName]
            if echo then
                echo.tap:setDelay(sail.effects.echo.delay)
                echo.tap:setVolume(channelData.echo)
                print("Updated echo for " ..
                    channelName ..
                    ": volume=" ..
                    channelData.echo ..
                    ", feedback=" .. sail.effects.echo.feedback .. ", delay=" .. sail.effects.echo.delay)
            else
                print("Warning: No echo effect for " .. channelName)
            end
        end
    end
end

function Sounds.setPan(sourceType, index, pan)
    local channelKey = sourceType == "synth" and index or "drum" .. index
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

function Sounds.muteOtherTracks(soloTrack)
    for track, _ in pairs(Sounds.soloState) do
        if track ~= soloTrack then
            Sounds.muteTrack(track, true)
        else
            Sounds.muteTrack(track, false)
        end
    end
end

function Sounds.unmuteAllTracks()
    for track, _ in pairs(Sounds.soloState) do
        Sounds.muteTrack(track, false)
    end
end

function Sounds.muteTrack(track, shouldMute)
    print((shouldMute and "Muted" or "Unmuted") .. " track: " .. track)
end

function Sounds.hasSolo()
    return Sounds.currentSoloTrack ~= nil
end

function Sounds.getSolo()
    return Sounds.currentSoloTrack and { Sounds.currentSoloTrack } or {}
end

return Sounds
