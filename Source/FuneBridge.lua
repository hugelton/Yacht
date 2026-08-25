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

function FuneBridge:available()
    return type(FunePlaydate) == "table"
        and type(FunePlaydate.yacht_runtime) == "table"
        and type(FunePlaydate.yacht_runtime.new) == "function"
end

function FuneBridge:isEnabled()
    return self.mode ~= "disabled" and self.runtime ~= nil
end

function FuneBridge:isActive()
    return self.mode == "active" and self.runtime ~= nil
end

function FuneBridge:rebuild(mode)
    mode = mode or self.mode
    if mode ~= "shadow" and mode ~= "active" then
        self.runtime = nil
        self.mode = "disabled"
        self.lastTime = nil
        return false, "FuneBridge is disabled"
    end

    if not self:available() then
        self.runtime = nil
        self.mode = "disabled"
        self.error = "FuneCore is not loaded"
        return false, self.error
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
        self.runtime = nil
        self.mode = "disabled"
        self.error = tostring(result)
        return false, self.error
    end

    self.runtime = result
    self.mode = mode
    self.lastTime = now()
    self.lastEvents = {}
    self.lastActions = {}
    self.error = nil
    return true
end

function FuneBridge:enableShadow()
    local ok, message = self:rebuild("shadow")
    if ok then self:syncLegacyPlayback() end
    return ok, message
end

function FuneBridge:enableActive()
    local ok, message = self:rebuild("active")
    if not ok then return false, message end

    -- Avoid double-triggering notes when Fune takes over audio playback.
    if Music then Music.state = false end
    if mast then mast.isPlaying = false end
    return true
end

function FuneBridge:disable()
    if self.runtime and self.runtime.stop then
        self.runtime:stop()
    end
    self.runtime = nil
    self.mode = "disabled"
    self.lastTime = nil
    self.lastEvents = {}
    self.lastActions = {}
end

function FuneBridge:setMode(mode)
    local normalized = string.lower(tostring(mode or "off"))
    if normalized == "off" or normalized == "disabled" then
        self:disable()
        notify("Fune Core: off")
        return true
    elseif normalized == "shadow" then
        local ok, message = self:enableShadow()
        notify(ok and "Fune Core: shadow" or ("Fune Core: " .. tostring(message)))
        return ok, message
    elseif normalized == "active" then
        local ok, message = self:enableActive()
        notify(ok and "Fune Core: active" or ("Fune Core: " .. tostring(message)))
        return ok, message
    end
    return false, "Unknown Fune mode: " .. tostring(mode)
end

function FuneBridge:installMenu(menu)
    if not self:available() then return nil, "FuneCore is not loaded" end
    if self.menuItem then return self.menuItem end
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
            local ok = self:setMode(value)
            if not ok and self.menuItem and self.menuItem.setValue then
                self.menuItem:setValue("Off")
            end
        end
    )
    if not item then return nil, errorMessage end
    self.menuItem = item
    return item
end

function FuneBridge:play()
    if not self.runtime then return false end
    self.lastTime = now()
    self.runtime:play()
    if self:isActive() and mast then mast.isPlaying = true end
    return true
end

function FuneBridge:start()
    if not self.runtime then return false end
    self.lastTime = now()
    self.runtime:start()
    if self:isActive() and mast then mast.isPlaying = true end
    return true
end

function FuneBridge:pause()
    if not self.runtime then return false end
    self.runtime:pause()
    self.lastTime = now()
    if self:isActive() and mast then mast.isPlaying = false end
    return true
end

function FuneBridge:stop()
    if not self.runtime then return false end
    self.runtime:stop()
    self.lastTime = now()
    if self:isActive() and mast then mast.isPlaying = false end
    return true
end

function FuneBridge:syncLegacyPlayback()
    if self.mode ~= "shadow" or not self.runtime or not Music then return end
    local legacyPlaying = Music.state == true
    local funePlaying = self.runtime:is_playing()
    if legacyPlaying and not funePlaying then
        self:play()
    elseif not legacyPlaying and funePlaying then
        self:pause()
    end
end

function FuneBridge:togglePlayback()
    if self:isActive() then
        if self.runtime:is_playing() then
            return self:pause()
        end
        return self:play()
    end

    if Music and Music.flipState then
        Music.flipState()
        self:syncLegacyPlayback()
        return true
    end
    return false
end

function FuneBridge:update(dt)
    if not self.runtime then return {} end
    self:syncLegacyPlayback()

    if dt == nil then
        local current = now()
        local previous = self.lastTime or current
        dt = math.max(0, current - previous)
        self.lastTime = current
    end

    local events = self.runtime:update(dt)
    self.lastEvents = events or {}
    return self.lastEvents
end

function FuneBridge:receiveMidi(data)
    if not self.runtime then return {}, {} end
    local events, actions = self.runtime:receive_midi(data)
    self.lastEvents = events or {}
    self.lastActions = actions or {}
    if self:isActive() and mast then
        mast.isPlaying = self.runtime:is_playing()
    end
    return self.lastEvents, self.lastActions
end

function FuneBridge:queueScene(scene, quantize)
    if not self.runtime then return nil end
    return self.runtime:queue_scene(scene, quantize)
end

function FuneBridge:queueNextScene()
    if not self.runtime then return nil end
    return self.runtime:queue_next_scene()
end

function FuneBridge:sceneId()
    if not self.runtime then return nil end
    return self.runtime:scene_id()
end

function FuneBridge:tick()
    if not self.runtime then return 0 end
    return self.runtime:tick()
end

return FuneBridge
