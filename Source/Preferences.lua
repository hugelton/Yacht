local gfx <const> = playdate.graphics

Preferences = {}

-- Vertical Fader
Preferences.VFader = {}
Preferences.VFader.__index = Preferences.VFader

function Preferences.VFader.new(x, y, label, value, minValue, maxValue, steps, target)
    local self = setmetatable({}, Preferences.VFader)
    self.x, self.y = x, y
    self.label = label
    self.value = value
    self.minValue, self.maxValue = minValue, maxValue
    self.steps = steps
    self.target = target
    self.width, self.height = 20, 100
    return self
end

function Preferences.VFader:draw()
    gfx.drawRect(self.x, self.y, self.width, self.height)
    local valueY = self.y + self.height - (self.value - self.minValue) / (self.maxValue - self.minValue) * self.height
    gfx.fillRect(self.x, valueY, self.width, self.height - (valueY - self.y))
    gfx.drawText(self.label, self.x, self.y + self.height + 5)
end

function Preferences.VFader:handleInput()
    if KeyManager.justReleased(KeyManager.keys.up) then
        self.value = math.min(self.maxValue, self.value + (self.maxValue - self.minValue) / self.steps)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        self.value = math.max(self.minValue, self.value - (self.maxValue - self.minValue) / self.steps)
    end
    Preferences.updateSettings(self.target, self.value)
end

Preferences.HFader = {}
Preferences.HFader.__index = Preferences.HFader

function Preferences.HFader.new(x, y, label, value, minValue, maxValue, steps, target, type)
    local self = setmetatable({}, Preferences.HFader)
    self.x, self.y = x, y
    self.label = label
    self.value = value
    self.type = type
    self.minValue, self.maxValue = minValue, maxValue
    self.steps = steps
    self.width, self.height = 100, 20
    self.cursorWidth, self.cursorHeight = 110, 25
    self.target = target
    self.handlePosition = self:valueToPosition(value)
    return self
end

function Preferences.HFader:valueToPosition(value)
    return self.x + (value - self.minValue) / (self.maxValue - self.minValue) * self.width
end

function Preferences.HFader:positionToValue(position)
    local normalizedPosition = (position - self.x) / self.width
    if self.type == "float" then
        return self.minValue + (self.maxValue - self.minValue) * normalizedPosition
    else
        local stepSize = (self.maxValue - self.minValue) / (self.steps - 1)
        return math.floor(normalizedPosition * (self.steps - 1) + 0.5) * stepSize + self.minValue
    end
end

function Preferences.HFader:draw()
    gfx.drawRect(self.x, self.y + (self.height / 2) - 2, self.width, 4)

    for i = 0, self.steps - 1 do
        local x = self.x + i * (self.width / (self.steps - 1))
        gfx.drawLine(x, self.y + self.height - 4, x, self.y + self.height - 2)
    end

    gfx.fillRect(self.handlePosition - 4, self.y, 8, self.height)
    gfx.drawTextAligned(self.label, self.x + self.width / 2, self.y + self.height + 5, kTextAlignment.center)
end

function Preferences.HFader:handleInput()
    local increment = (self.maxValue - self.minValue) / self.steps
    if KeyManager.justReleased(KeyManager.keys.right) then
        self.value = math.min(self.maxValue, self.value + increment)
    elseif KeyManager.justReleased(KeyManager.keys.left) then
        self.value = math.max(self.minValue, self.value - increment)
    end
    self.handlePosition = self:valueToPosition(self.value)
    Preferences.updateSettings(self.target, self.value)
end

-- Checkbox
Preferences.CheckBox = {}
Preferences.CheckBox.__index = Preferences.CheckBox

function Preferences.CheckBox.new(x, y, label, target)
    local self = setmetatable({}, Preferences.CheckBox)
    self.x, self.y = x, y
    self.label = label
    self.checked = false
    self.target = target
    self.width, self.height = 20, 20
    return self
end

function Preferences.CheckBox:draw()
    gfx.drawRect(self.x, self.y, self.width, self.height)
    if self.checked then
        gfx.fillRect(self.x + 4, self.y + 4, self.width - 8, self.height - 8)
    end
    gfx.drawText(self.label, self.x + self.width + 5, self.y + 5)
end

function Preferences.CheckBox:handleInput()
    if KeyManager.justReleased(KeyManager.keys.a) then
        self.checked = not self.checked
        Preferences.updateSettings(self.target, self.checked)
    end
end

-- Dropdown
Preferences.Dropdown = {}
Preferences.Dropdown.__index = Preferences.Dropdown

function Preferences.Dropdown.new(x, y, label, options, value, target)
    local self = setmetatable({}, Preferences.Dropdown)
    self.x, self.y = x, y
    self.label = label
    self.options = options
    self.value = value
    self.target = target
    self.width, self.height = 100, 20
    self.currentIndex = 1
    for i, option in ipairs(options) do
        if option == value then
            self.currentIndex = i
            break
        end
    end
    return self
end

function Preferences.Dropdown:draw()
    gfx.drawRect(self.x, self.y, self.width, self.height)
    gfx.drawText(self.label .. ": " .. self.options[self.currentIndex], self.x + 5, self.y + 5)
end

function Preferences.Dropdown:handleInput()
    if KeyManager.justReleased(KeyManager.keys.right) then
        self.currentIndex = (self.currentIndex % #self.options) + 1
    elseif KeyManager.justReleased(KeyManager.keys.left) then
        self.currentIndex = ((self.currentIndex - 2) % #self.options) + 1
    end
    self.value = self.options[self.currentIndex]
    Preferences.updateSettings(self.target, self.value)
end

-- Number Input
Preferences.NumberInput = {}
Preferences.NumberInput.__index = Preferences.NumberInput

function Preferences.NumberInput.new(x, y, label, value, minValue, maxValue, target, options)
    local self = setmetatable({}, Preferences.NumberInput)
    options = options or {}
    self.x, self.y = x, y
    self.label = label
    self.value = value
    self.minValue, self.maxValue = minValue, maxValue
    self.target = target

    self.width = options.width or 20
    self.height = 20
    self.labelWidth = options.labelWidth or 80
    -- Coarse step for A + left/right; MIDI notes jump by an octave.
    self.coarseStep = options.coarseStep or 1

    return self
end

function Preferences.NumberInput:draw()
    gfx.drawTextAligned(self.label, self.x, self.y + 2, kTextAlignment.left)
    local startX = self.x + self.labelWidth
    gfx.drawRect(startX, self.y, self.width, self.height)
    gfx.drawTextAligned(tostring(self.value), startX + self.width / 2, self.y + 2, kTextAlignment.center)
end

function Preferences.NumberInput:nudge(delta)
    self.value = math.max(self.minValue, math.min(self.maxValue, self.value + delta))
end

function Preferences.NumberInput:handleInput()
    if not self.target then
        console.log("Error: target is nil for NumberInput")
        return
    end

    if KeyManager.justComboPressed("leftA") then
        self:nudge(-self.coarseStep)
    elseif KeyManager.justComboPressed("rightA") then
        self:nudge(self.coarseStep)
    elseif KeyManager.justReleased(KeyManager.keys.left) or CrankManager.backwardTick then
        self:nudge(-1)
    elseif KeyManager.justReleased(KeyManager.keys.right) or CrankManager.forwardTick then
        self:nudge(1)
    end

    Preferences.updateSettings(self.target, self.value)
end

Preferences.uiComponents = {}
Preferences.cursorMap = {}
Preferences.cursor = { x = 0, y = 0, w = 0, h = 0 }
Preferences.currentCursorIndex = 1


-- Note inputs share a narrower label column so three fit across the panel.
local noteInput = { labelWidth = 55, width = 30, coarseStep = 12 }

Preferences.parameters = {
    { x = 20,  y = 42,  label = "USB MIDI", type = "checkbox", target = "midiEnabled", faderType = "checkbox" },
    { x = 170, y = 42,  label = "Clock", type = "dropdown", options = { "Internal", "External" }, target = "midiClockSource", faderType = "dropdown" },

    { x = 20,  y = 70,  label = "Syn A Ch", type = "number", min = 1, max = 16, target = "midiChannels.syn1", faderType = "number", labelWidth = 70, width = 26 },
    { x = 145, y = 70,  label = "Syn B Ch", type = "number", min = 1, max = 16, target = "midiChannels.syn2", faderType = "number", labelWidth = 70, width = 26 },
    { x = 270, y = 70,  label = "Syn C Ch", type = "number", min = 1, max = 16, target = "midiChannels.syn3", faderType = "number", labelWidth = 70, width = 26 },
    { x = 20,  y = 98,  label = "Drums Ch", type = "number", min = 1, max = 16, target = "midiChannels.drums", faderType = "number", labelWidth = 70, width = 26 },

    { x = 20,  y = 146, label = "Kick", type = "number", min = 0, max = 127, target = "drumMidiNotes.kick", faderType = "number", labelWidth = noteInput.labelWidth, width = noteInput.width, coarseStep = noteInput.coarseStep },
    { x = 145, y = 146, label = "Snare", type = "number", min = 0, max = 127, target = "drumMidiNotes.snare", faderType = "number", labelWidth = noteInput.labelWidth, width = noteInput.width, coarseStep = noteInput.coarseStep },
    { x = 270, y = 146, label = "Close", type = "number", min = 0, max = 127, target = "drumMidiNotes.closedHiHat", faderType = "number", labelWidth = noteInput.labelWidth, width = noteInput.width, coarseStep = noteInput.coarseStep },
    { x = 20,  y = 172, label = "Open", type = "number", min = 0, max = 127, target = "drumMidiNotes.openHiHat", faderType = "number", labelWidth = noteInput.labelWidth, width = noteInput.width, coarseStep = noteInput.coarseStep },
    { x = 145, y = 172, label = "Perc1", type = "number", min = 0, max = 127, target = "drumMidiNotes.percussion1", faderType = "number", labelWidth = noteInput.labelWidth, width = noteInput.width, coarseStep = noteInput.coarseStep },
    { x = 270, y = 172, label = "Perc2", type = "number", min = 0, max = 127, target = "drumMidiNotes.percussion2", faderType = "number", labelWidth = noteInput.labelWidth, width = noteInput.width, coarseStep = noteInput.coarseStep },
}
function Preferences.init()
    console.log("Initializing Preferences")
    Preferences.uiComponents = {}
    Preferences.cursorMap = {}
    Preferences.currentCursorIndex = 1
    for i, param in ipairs(Preferences.parameters) do
        local component
        local initialValue = Preferences.getInitialValue(param.target)
        if param.faderType == "horizontal" then
            component = Preferences.HFader.new(param.x, param.y, param.label, initialValue, param.min, param.max,
                param.steps, param.target, param.type)
        elseif param.faderType == "checkbox" then
            component = Preferences.CheckBox.new(param.x, param.y, param.label, param.target)
            component.checked = initialValue
        elseif param.faderType == "number" then
            component = Preferences.NumberInput.new(param.x, param.y, param.label, initialValue, param.min, param.max,
                param.target, param)
        elseif param.faderType == "dropdown" then
            component = Preferences.Dropdown.new(param.x, param.y, param.label, param.options, initialValue, param
                .target)
        end
        table.insert(Preferences.uiComponents, component)
        local cursorWidth = component.width + 4
        if param.faderType == "number" then
            cursorWidth = component.labelWidth + component.width + 4
        end
        table.insert(Preferences.cursorMap,
            { x = param.x - 2, y = param.y - 5, w = cursorWidth, h = component.height + 10 })
    end

    if #Preferences.cursorMap > 0 then
        Preferences.cursor = {
            x = Preferences.cursorMap[1].x,
            y = Preferences.cursorMap[1].y,
            w = Preferences.cursorMap[1].w,
            h = Preferences.cursorMap[1].h
        }
    end
    console.log("Preferences initialization complete")
end

function Preferences.load()
    Preferences.init()
end

function Preferences.getInitialValue(target)
    local parts = {}
    for part in target:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local value = settings
    for _, part in ipairs(parts) do
        value = value[part]
        if value == nil then
            console.log("Initial value not found for: " .. target)
            return 0
        end
    end
    return value
end

function Preferences.draw()
    assets.fonts.cavs:drawText("Drum note map", 20, 124)
    assets.fonts.nada:drawTextAligned("A + left/right: octave", 380, 127, kTextAlignment.right)

    for _, component in ipairs(Preferences.uiComponents) do
        component:draw()
    end

    assets.fonts.nada:drawText("note CH NOTE VELO [LEN] | drum NOTE VELO | start stop clock", 20, 196)
    assets.fonts.nada:drawText(MIDI.getStatus(), 20, 211)
end

function Preferences.handleInput()
    if #Preferences.uiComponents == 0 then return end
    local oldIndex = Preferences.currentCursorIndex

    if KeyManager.justReleased(KeyManager.keys.up) then
        Preferences.currentCursorIndex = math.max(1, Preferences.currentCursorIndex - 1)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        Preferences.currentCursorIndex = math.min(#Preferences.cursorMap, Preferences.currentCursorIndex + 1)
    end

    if oldIndex ~= Preferences.currentCursorIndex then
        Preferences.cursor.x = Preferences.cursorMap[Preferences.currentCursorIndex].x
        Preferences.cursor.y = Preferences.cursorMap[Preferences.currentCursorIndex].y
        Preferences.cursor.w = Preferences.cursorMap[Preferences.currentCursorIndex].w
        Preferences.cursor.h = Preferences.cursorMap[Preferences.currentCursorIndex].h
    end

    local component = Preferences.uiComponents[Preferences.currentCursorIndex]
    component:handleInput()
end

function Preferences.updateSettings(target, value)
    local parts = {}
    for part in target:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local current = settings
    for i = 1, #parts - 1 do
        if current[parts[i]] == nil then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end

    -- The focused component writes its value back every frame, so bail out
    -- unless something actually moved: the clock side effect below starts
    -- playback and must not fire just because the cursor is parked here.
    local key = parts[#parts]
    if current[key] == value then return end

    current[key] = value
    console.log("Updated setting: " .. target .. " to " .. tostring(value))

    if target == "midiEnabled" and not value and settings.midiClockSource == "External" then
        Music.syncClock()
    elseif target == "midiClockSource" then
        MIDI.clockPulses = 0
        Music.syncClock()
    end
end

return Preferences
