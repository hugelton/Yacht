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

local function legacyMode()
    if Music and (Music.mode == "region" or Music.mode == "song") then return Music.mode end
    return "song"
end

local function legacyPosition()
    if Music and tonumber(Music.currentPosition) then return tonumber(Music.currentPosition) end
    return 1
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
        self:disable()
        return false, "FuneBridge is disabled"
    end

    if not self:available() then
        self:disable()
        self.error = "FuneCore is not loaded"
        return false, self.error
    end

    -- Tear down the previous runtime before changing routing modes. This is
    -- especially important for Active -> Shadow/Active transitions because
    -- Yacht instruments may still have notes sounding.
    if self.runtime and self.runtime.stop then
        self.runtime:stop()
    end

    local ok, result = pcall(function()
        return FunePlaydate.yacht_runtime.new({
            mast = mast,
            keel = keel,
            boat = boat,
            settings = settings,
            sounds = runtimeSounds(mode),
            mode = legacyMode(),
            position = legacyPosition(),
        })
    end)

    if not ok then
        self.runtime = nil
        self.mode = "disabled"
        self.lastTime = nil
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
    if ok then self:syncLegacyState() end
    return ok, message
end

function FuneBridge:enableActive()
    local ok, message = self:rebuild("active")
    if not ok then return false, message end

    -- Avoid double-triggering notes when Fune takes over audio playback.
    if Music then Music.state = false end
    if mast then mast.isPlaying = false end
    self:syncLegacyIndicators()
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
    if Music then Music.state = false end
    if mast then mast.isPlaying = false end
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

function FuneBridge:syncLegacyNavigation()
    if not self.runtime or not Music then return end
    if not self.runtime.mode_name or not self.runtime.position_value then return end

    local targetMode = legacyMode()
    local targetPosition = legacyPosition()
    if self.runtime:mode_name() ~= targetMode then
        self.runtime:set_mode(targetMode, targetPosition, "none")
    elseif self.runtime:position_value() ~= targetPosition then
        self.runtime:set_position(targetPosition, "none")
    end
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

function FuneBridge:syncLegacyIndicators()
    if not self:isActive() or not self.runtime or not Music then return end

    if self.runtime.mode_name then Music.mode = self.runtime:mode_name() end
    if self.runtime.position_value then Music.currentPosition = self.runtime:position_value() end
    if mast then mast.isPlaying = self.runtime:is_playing() end

    -- Fune uses 96 PPQN internally while Yacht's GlobalBar shows a 1..16
    -- step cursor. Convert the absolute Fune transport tick back to Yacht's
    -- current step without changing the Fune transport itself.
    local ppqn = tonumber(self.runtime.project and self.runtime.project.ppqn) or 96
    local beats = math.max(1, tonumber(mast and mast.measure) or 4)
    local steps = math.max(1, tonumber(mast and mast.steps) or 16)
    local barTicks = ppqn * beats
    local stepTicks = barTicks / steps
    local tick = tonumber(self.runtime:tick()) or 0
    Music.tick = (math.floor((tick % barTicks) / stepTicks) % steps) + 1

    if Music.updateCurrentBlocks then Music.updateCurrentBlocks() end
end

function FuneBridge:syncLegacyState()
    self:syncLegacyNavigation()
    self:syncLegacyPlayback()
    self:syncLegacyIndicators()
end

function FuneBridge:togglePlayback()
    if self:isActive() then
        if self.runtime:is_playing() then
            return self:pause()
        end
        return self:play()
    end

    if Music then
        local legacyFlip = Music._legacyFlipState or Music.flipState
        if legacyFlip then
            legacyFlip()
            self:syncLegacyPlayback()
            return true
        end
    end
    return false
end

function FuneBridge:update(dt)
    if not self.runtime then return {} end
    self:syncLegacyNavigation()
    self:syncLegacyPlayback()

    if dt == nil then
        local current = now()
        local previous = self.lastTime or current
        dt = math.max(0, current - previous)
        self.lastTime = current
    end

    local events = self.runtime:update(dt)
    self.lastEvents = events or {}
    self:syncLegacyIndicators()
    return self.lastEvents
end

function FuneBridge:receiveMidi(data)
    if not self.runtime then return {}, {} end
    local events, actions = self.runtime:receive_midi(data)
    self.lastEvents = events or {}
    self.lastActions = actions or {}
    self:syncLegacyIndicators()
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
