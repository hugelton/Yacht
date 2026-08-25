FuneBridge = {
    runtime = nil,
    mode = "disabled", -- disabled | shadow | active
    lastTime = nil,
    lastEvents = {},
    lastActions = {},
    error = nil,
    menuItem = nil,
}

local function now()
    if playdate and playdate.sound and playdate.sound.getCurrentTime then
        return playdate.sound.getCurrentTime()
    end
    return 0
end

local function notify(message)
    if Balloon and Balloon.open then
        Balloon.open(message)
    elseif console and console.log then
        console.log(message)
    elseif print then
        print(message)
    end
end

local NullSounds = {
    instruments = {
        { allNotesOff = function() end },
        { allNotesOff = function() end },
        { allNotesOff = function() end },
    },
    playMidiSynth = function() end,
    playDrum = function() end,
}

local function runtimeSounds(mode)
    if mode == "active" then return Sounds end
    return NullSounds
end

function FuneBridge.available()
    return type(FunePlaydate) == "table"
        and type(FunePlaydate.yacht_runtime) == "table"
        and type(FunePlaydate.yacht_runtime.new) == "function"
end

function FuneBridge.isEnabled()
    return FuneBridge.mode ~= "disabled" and FuneBridge.runtime ~= nil
end

function FuneBridge.isActive()
    return FuneBridge.mode == "active" and FuneBridge.runtime ~= nil
end

function FuneBridge.rebuild(mode)
    mode = mode or FuneBridge.mode
    if mode ~= "shadow" and mode ~= "active" then
        FuneBridge.runtime = nil
        FuneBridge.mode = "disabled"
        FuneBridge.lastTime = nil
        return false, "FuneBridge is disabled"
    end

    if not FuneBridge.available() then
        FuneBridge.runtime = nil
        FuneBridge.mode = "disabled"
        FuneBridge.error = "FuneCore is not loaded"
        return false, FuneBridge.error
    end

    local ok, result = pcall(function()
        return FunePlaydate.yacht_runtime.new({
            mast = mast,
            keel = keel,
            boat = boat,
            settings = settings,
            sounds = runtimeSounds(mode),
        })
    end)

    if not ok then
        FuneBridge.runtime = nil
        FuneBridge.mode = "disabled"
        FuneBridge.error = tostring(result)
        return false, FuneBridge.error
    end

    FuneBridge.runtime = result
    FuneBridge.mode = mode
    FuneBridge.lastTime = now()
    FuneBridge.lastEvents = {}
    FuneBridge.lastActions = {}
    FuneBridge.error = nil
    return true
end

function FuneBridge.enableShadow()
    return FuneBridge.rebuild("shadow")
end

function FuneBridge.enableActive()
    local ok, message = FuneBridge.rebuild("active")
    if not ok then return false, message end

    -- Avoid double-triggering notes when Fune takes over audio playback.
    if Music then Music.state = false end
    if mast then mast.isPlaying = false end
    return true
end

function FuneBridge.disable()
    if FuneBridge.runtime and FuneBridge.runtime.stop then
        FuneBridge.runtime:stop()
    end
    FuneBridge.runtime = nil
    FuneBridge.mode = "disabled"
    FuneBridge.lastTime = nil
    FuneBridge.lastEvents = {}
    FuneBridge.lastActions = {}
end

function FuneBridge.setMode(mode)
    local normalized = string.lower(tostring(mode or "off"))
    if normalized == "off" or normalized == "disabled" then
        FuneBridge.disable()
        notify("Fune Core: off")
        return true
    elseif normalized == "shadow" then
        local ok, message = FuneBridge.enableShadow()
        notify(ok and "Fune Core: shadow" or ("Fune Core: " .. tostring(message)))
        return ok, message
    elseif normalized == "active" then
        local ok, message = FuneBridge.enableActive()
        notify(ok and "Fune Core: active" or ("Fune Core: " .. tostring(message)))
        return ok, message
    end
    return false, "Unknown Fune mode: " .. tostring(mode)
end

function FuneBridge.installMenu(menu)
    if not FuneBridge.available() then return nil, "FuneCore is not loaded" end
    if FuneBridge.menuItem then return FuneBridge.menuItem end
    if not menu and playdate and playdate.getSystemMenu then
        menu = playdate.getSystemMenu()
    end
    if not menu or not menu.addOptionsMenuItem then
        return nil, "Playdate system menu is unavailable"
    end

    local item, errorMessage = menu:addOptionsMenuItem(
        "Fune",
        { "Off", "Shadow", "Active" },
        "Off",
        function(value)
            local ok = FuneBridge.setMode(value)
            if not ok and FuneBridge.menuItem and FuneBridge.menuItem.setValue then
                FuneBridge.menuItem:setValue("Off")
            end
        end
    )
    if not item then return nil, errorMessage end
    FuneBridge.menuItem = item
    return item
end

function FuneBridge.play()
    if not FuneBridge.runtime then return false end
    FuneBridge.lastTime = now()
    FuneBridge.runtime:play()
    if FuneBridge.isActive() and mast then mast.isPlaying = true end
    return true
end

function FuneBridge.start()
    if not FuneBridge.runtime then return false end
    FuneBridge.lastTime = now()
    FuneBridge.runtime:start()
    if FuneBridge.isActive() and mast then mast.isPlaying = true end
    return true
end

function FuneBridge.pause()
    if not FuneBridge.runtime then return false end
    FuneBridge.runtime:pause()
    FuneBridge.lastTime = now()
    if FuneBridge.isActive() and mast then mast.isPlaying = false end
    return true
end

function FuneBridge.stop()
    if not FuneBridge.runtime then return false end
    FuneBridge.runtime:stop()
    FuneBridge.lastTime = now()
    if FuneBridge.isActive() and mast then mast.isPlaying = false end
    return true
end

function FuneBridge.update(dt)
    if not FuneBridge.runtime then return {} end

    if dt == nil then
        local current = now()
        local previous = FuneBridge.lastTime or current
        dt = math.max(0, current - previous)
        FuneBridge.lastTime = current
    end

    local events = FuneBridge.runtime:update(dt)
    FuneBridge.lastEvents = events or {}
    return FuneBridge.lastEvents
end

function FuneBridge.receiveMidi(data)
    if not FuneBridge.runtime then return {}, {} end
    local events, actions = FuneBridge.runtime:receive_midi(data)
    FuneBridge.lastEvents = events or {}
    FuneBridge.lastActions = actions or {}
    if FuneBridge.isActive() and mast then
        mast.isPlaying = FuneBridge.runtime:is_playing()
    end
    return FuneBridge.lastEvents, FuneBridge.lastActions
end

function FuneBridge.queueScene(scene, quantize)
    if not FuneBridge.runtime then return nil end
    return FuneBridge.runtime:queue_scene(scene, quantize)
end

function FuneBridge.queueNextScene()
    if not FuneBridge.runtime then return nil end
    return FuneBridge.runtime:queue_next_scene()
end

function FuneBridge.sceneId()
    if not FuneBridge.runtime then return nil end
    return FuneBridge.runtime:scene_id()
end

function FuneBridge.tick()
    if not FuneBridge.runtime then return 0 end
    return FuneBridge.runtime:tick()
end

return FuneBridge
