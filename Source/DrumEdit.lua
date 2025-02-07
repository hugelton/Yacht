local gfx <const> = playdate.graphics

DrumEdit = {}



DrumEdit.sampleList = {
    "08_CH",
    "08_CP",
    "08_OH",
    "09_BD",
    "09_CH",
    "09_LM",
    "09_OH",
    "09_SN",
    "09_TM",
    "77_BD",
    "77_CH",
    "77_CL",
    "77_HT",
    "77_LT",
    "77_OH",
    "77_SN",
    "78_CB",
    "78_CH",
    "78_CL",
    "78_MR",
    "78_OH",
    "78_TB"
}





DrumEdit.sampleSelector = {
    isOpen = false,
    selectedIndex = 1,
    scrollOffset = 0,
    maxVisibleItems = 7,
    itemHeight = 20,
    width = 360,
    height = 180,
    x = (400 - 360) / 2,
    y = (240 - 180) / 2,
    targetDrum = nil
}



local sail = sail

-- UI components
DrumEdit.VFader = {}
DrumEdit.VFader.__index = DrumEdit.VFader

DrumEdit.HFader = {}
DrumEdit.HFader.__index = DrumEdit.HFader

DrumEdit.Button = {}
DrumEdit.Button.__index = DrumEdit.Button

-- Cursor
DrumEdit.cursor = { x = 0, y = 0, w = 0, h = 0 }
DrumEdit.currentCursorIndex = 1


DrumEdit.drums = sail


DrumEdit.uiComponents = {}
DrumEdit.cursorMap = {}

DrumEdit.parameters = {
    -- Kick (drum1)
    -- { x = 20,  y = 85,  label = "Wave",        type = "int",    min = 0,                     max = 4,             steps = 5,  target = "drum1.waveform", faderType = "horizontal" },
    { x = 20,  y = 55 + 5 + 2, label = "Pitch",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.pitch",  faderType = "vertical" },
    { x = 50,  y = 55 + 5 + 2, label = "Slope",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.slope",  faderType = "vertical" },
    { x = 80,  y = 55 + 5 + 2, label = "Decay",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.decay",  faderType = "vertical" },
    { x = 110, y = 55 + 5 + 2, label = "Crv.",        type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.curve",  faderType = "vertical" },
    { x = 140, y = 55 + 5 + 2, label = "Gain",        type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.gain",   faderType = "vertical" },
    { x = 170, y = 55 + 5 + 2, label = "Limit",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.limit",  faderType = "vertical" },
    { x = 200, y = 55 + 5 + 2, label = "Mix",         type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum1.mix",    faderType = "vertical" },


    -- Snare (drum2)
    { x = 235, y = 55 + 5 + 2, label = "Snpy.",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum2.snappy", faderType = "vertical" },
    { x = 265, y = 55 + 5 + 2, label = "Pitch",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum2.pitch",  faderType = "vertical" },
    { x = 295, y = 55 + 5 + 2, label = "Slope",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum2.slope",  faderType = "vertical" },
    { x = 325, y = 55 + 5 + 2, label = "Decay",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum2.decay",  faderType = "vertical" },
    { x = 355, y = 55 + 5 + 2, label = "Tone",        type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum2.tone",   faderType = "vertical" },

    -- Sample-based drums (drum3 to drum6)
    { x = 20,  y = 140 + 10,   label = "Pitch",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum3.pitch",  faderType = "horizontal" },
    { x = 115, y = 140 + 10,   label = "Pitch",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum4.pitch",  faderType = "horizontal" },
    { x = 210, y = 140 + 10,   label = "Pitch",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum5.pitch",  faderType = "horizontal" },
    { x = 305, y = 140 + 10,   label = "Pitch",       type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum6.pitch",  faderType = "horizontal" },

    { x = 20,  y = 175,        label = "Length",      type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum3.length", faderType = "horizontal" },
    { x = 115, y = 175,        label = "Length",      type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum4.length", faderType = "horizontal" },
    { x = 210, y = 175,        label = "Length",      type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum5.length", faderType = "horizontal" },
    { x = 305, y = 175,        label = "Length",      type = "float",  min = 0,                     max = 1,             steps = 11, target = "drum6.length", faderType = "horizontal" },

    -- Load Sample buttons
    { x = 15,  y = 205,        label = "Load Sample", type = "button", target = "drum3.loadSample", faderType = "button" },
    { x = 110, y = 205,        label = "Load Sample", type = "button", target = "drum4.loadSample", faderType = "button" },
    { x = 205, y = 205,        label = "Load Sample", type = "button", target = "drum5.loadSample", faderType = "button" },
    { x = 300, y = 205,        label = "Load Sample", type = "button", target = "drum6.loadSample", faderType = "button" },
}

-- VFader methods
function DrumEdit.VFader.new(x, y, label, value, minValue, maxValue, steps, targetPath, type)
    local self = setmetatable({}, DrumEdit.VFader)
    self.x, self.y = x, y
    self.label = label
    self.value = value
    self.minValue, self.maxValue = minValue, maxValue
    self.steps = steps
    self.targetPath = targetPath
    self.type = type
    self.width, self.height = 15, 50
    self.cursorWidth, self.cursorHeight = 20, 55
    self.handlePosition = self:valueToPosition(value)
    return self
end

function DrumEdit.VFader:valueToPosition(value)
    return self.y + self.height - (value - self.minValue) / (self.maxValue - self.minValue) * self.height
end

function DrumEdit.VFader:positionToValue(position)
    local normalizedPosition = (self.y + self.height - position) / self.height
    if self.type == "float" then
        return self.minValue + (self.maxValue - self.minValue) * normalizedPosition
    else
        local stepSize = (self.maxValue - self.minValue) / (self.steps - 1)
        return math.floor(normalizedPosition * (self.steps - 1) + 0.5) * stepSize + self.minValue
    end
end

function DrumEdit.VFader:draw()
    gfx.fillRoundRect(self.x + 2, self.handlePosition - 4, self.width - 4, 8, 2)
end

-- HFader methods
function DrumEdit.HFader.new(x, y, label, value, minValue, maxValue, steps, targetPath, type)
    local self = setmetatable({}, DrumEdit.HFader)
    self.x, self.y = x, y
    self.label = label
    self.value = value
    self.minValue, self.maxValue = minValue, maxValue
    self.steps = steps
    self.targetPath = targetPath
    self.type = type
    self.width, self.height = 70, 15
    self.cursorWidth, self.cursorHeight = 75, 20
    self.handlePosition = self:valueToPosition(value)
    return self
end

function DrumEdit.HFader:valueToPosition(value)
    return self.x + (value - self.minValue) / (self.maxValue - self.minValue) * self.width
end

function DrumEdit.HFader:positionToValue(position)
    local normalizedPosition = (position - self.x) / self.width
    if self.type == "float" then
        return self.minValue + (self.maxValue - self.minValue) * normalizedPosition
    else
        local stepSize = (self.maxValue - self.minValue) / (self.steps - 1)
        return math.floor(normalizedPosition * (self.steps - 1) + 0.5) * stepSize + self.minValue
    end
end

function DrumEdit.HFader:draw()
    gfx.fillRoundRect(self.handlePosition - 4, self.y + 2, 8, self.height - 4, 2)
end

-- Button methods
function DrumEdit.Button.new(x, y, label, callback, targetPath)
    local self = setmetatable({}, DrumEdit.Button)
    self.x, self.y = x, y
    self.label = label
    self.callback = callback
    self.targetPath = targetPath
    self.width, self.height = 80, 20
    self.cursorWidth, self.cursorHeight = 85, 25
    return self
end

function DrumEdit.Button:draw()
    if self.targetPath then
        local drumNumber = self.targetPath:match("drum(%d+)")
        if drumNumber then
            local drumData = sail["drum" .. drumNumber]
            local displayName = "Error"

            if drumData and drumData.loadSample then
                displayName = drumData.loadSample

                if #displayName > 16 then
                    displayName = displayName:sub(1, 13) .. "..."
                end
            end



            assets.fonts.nada:drawTextAligned("💽 " .. displayName, self.x + self.width / 2, self.y + 5,
                kTextAlignment.center)
        end
    end
end

function DrumEdit.showSampleSelector(drumNumber)
    local selector = DrumEdit.sampleSelector
    selector.isOpen = true
    selector.targetDrum = drumNumber
    selector.selectedIndex = 1
    selector.scrollOffset = 0
    cursor.hide()
    currentFocus = "dialog"
end

function DrumEdit.handleSampleSelector()
    local selector = DrumEdit.sampleSelector

    if KeyManager.justReleased(KeyManager.keys.up) or CrankManager.forwardTick then
        selector.selectedIndex = math.max(1, selector.selectedIndex - 1)
        if selector.selectedIndex <= selector.scrollOffset then
            selector.scrollOffset = selector.selectedIndex - 1
        end
    elseif KeyManager.justReleased(KeyManager.keys.down) or CrankManager.backwardTick then
        selector.selectedIndex = math.min(#DrumEdit.sampleList, selector.selectedIndex + 1)
        if selector.selectedIndex > selector.scrollOffset + selector.maxVisibleItems then
            selector.scrollOffset = selector.selectedIndex - selector.maxVisibleItems
        end
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        local selectedSample = DrumEdit.sampleList[selector.selectedIndex]

        sail["drum" .. selector.targetDrum].loadSample = selectedSample

        Sounds.loadDrumSample(selector.targetDrum, selectedSample)


        DrumEdit.closeSampleSelector()
    end
end

function DrumEdit.closeSampleSelector()
    local selector = DrumEdit.sampleSelector
    selector.isOpen = false
    cursor.show()
    currentFocus = "main"
end

function DrumEdit.drawSampleSelector()
    if not DrumEdit.sampleSelector.isOpen then return end
    local selector = DrumEdit.sampleSelector


    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, 400, 240)


    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(selector.x, selector.y, selector.width, selector.height, 0)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(selector.x, selector.y, selector.width, selector.height, 0)

    gfx.drawTextAligned("*Select Sample*", selector.x + selector.width / 2,
        selector.y + 10, kTextAlignment.center)

    gfx.drawRect(selector.x + 10, selector.y + 28, selector.width - 30,
        selector.itemHeight * selector.maxVisibleItems + 1)
    gfx.drawRect(selector.x + selector.width - 21, selector.y + 28, 17,
        selector.itemHeight * selector.maxVisibleItems + 1)


    for i = 1, math.min(selector.maxVisibleItems, #DrumEdit.sampleList - selector.scrollOffset) do
        local index = i + selector.scrollOffset
        local y = selector.y + 28 + (i - 1) * selector.itemHeight

        gfx.setDitherPattern(0.5)
        gfx.drawRect(selector.x + 10, y, selector.width - 30, selector.itemHeight + 1)
        gfx.setDitherPattern(0)

        if index == selector.selectedIndex then
            gfx.fillRect(selector.x + 10, y, selector.width - 30, selector.itemHeight)
            gfx.setImageDrawMode(gfx.kDrawModeInverted)
        end

        gfx.drawText("💽", selector.x + 15, y + 6)
        assets.fonts.nada:drawText(DrumEdit.sampleList[index], selector.x + 35, y + 6)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end


    if #DrumEdit.sampleList > selector.maxVisibleItems then
        local scrollBarHeight = (selector.maxVisibleItems / #DrumEdit.sampleList) * (selector.height - 80)
        local scrollBarY = selector.y + 28 +
            (selector.scrollOffset / (#DrumEdit.sampleList - selector.maxVisibleItems)) *
            (selector.height - 40 - scrollBarHeight)
        gfx.fillRoundRect(selector.x + selector.width - 19, scrollBarY, 13, scrollBarHeight, 2)
    end
end

function DrumEdit.load()
    DrumEdit.currentCursorIndex = 1


    DrumEdit.uiComponents = {}
    DrumEdit.cursorMap = {}


    for i = 3, 6 do
        local drumData = sail["drum" .. i]
        if drumData and drumData.loadSample then
            local samplePath = drumData.loadSample
            if playdate.file.exists(samplePath) then
                sail["drum" .. i].sample = samplePath
                Sounds.loadDrumSample(i, samplePath)
            else
                console.log("Sample not found: " .. samplePath)
                sail["drum" .. i].sample = nil
            end
        end
    end


    for i, param in ipairs(DrumEdit.parameters) do
        local component
        local initialValue = DrumEdit.getInitialValue(param.target)

        if param.faderType == "horizontal" then
            component = DrumEdit.HFader.new(param.x, param.y, param.label, initialValue,
                param.min, param.max, param.steps, param.target, param.type)
        elseif param.faderType == "vertical" then
            component = DrumEdit.VFader.new(param.x, param.y, param.label, initialValue,
                param.min, param.max, param.steps, param.target, param.type)
        elseif param.faderType == "button" then
            component = DrumEdit.Button.new(param.x, param.y, param.label,
                function() DrumEdit.loadSample(param.target) end, param.target)
        end

        table.insert(DrumEdit.uiComponents, component)
        table.insert(DrumEdit.cursorMap,
            { x = param.x - 2, y = param.y - 3, w = component.cursorWidth, h = component.cursorHeight })
    end


    for i = 1, 6 do
        if sail["drum" .. i] then
            Sounds.updateDrumParameters(i, sail["drum" .. i])
        end
    end
end

function DrumEdit.init()
    for i = 3, 6 do
        local drumData = sail["drum" .. i]
        if drumData and drumData.loadSample then
            local samplePath = drumData.loadSample
            if playdate.file.exists(samplePath) then
                sail["drum" .. i].sample = samplePath

                Sounds.loadDrumSample(i, samplePath)
            else
                console.log("Sample not found: " .. samplePath)
                sail["drum" .. i].sample = nil
            end
        end
    end


    for i, param in ipairs(DrumEdit.parameters) do
        local component
        local initialValue = DrumEdit.getInitialValue(param.target)
        if param.faderType == "horizontal" then
            component = DrumEdit.HFader.new(param.x, param.y, param.label, initialValue, param.min, param.max,
                param.steps, param.target, param.type)
        elseif param.faderType == "vertical" then
            component = DrumEdit.VFader.new(param.x, param.y, param.label, initialValue, param.min, param.max,
                param.steps, param.target, param.type)
        elseif param.faderType == "button" then
            component = DrumEdit.Button.new(
                param.x,
                param.y,
                param.label,
                function() DrumEdit.loadSample(param.target) end,
                param.target
            )
        end
        table.insert(DrumEdit.uiComponents, component)
        table.insert(DrumEdit.cursorMap,
            { x = param.x - 2, y = param.y - 3, w = component.cursorWidth, h = component.cursorHeight })
    end

    DrumEdit.updateCursor()
end

DrumEdit.dialog = {
    isOpen = false,
    message = "",
    callback = nil,
    selection = 1, -- 1 for Yes, 2 for No
}

function DrumEdit.showDialog(message, callback)
    DrumEdit.dialog.isOpen = true
    DrumEdit.dialog.message = message
    DrumEdit.dialog.callback = callback
    DrumEdit.dialog.selection = 1
end

function DrumEdit.drawDialog()
    local screenWidth, screenHeight = playdate.display.getSize()
    local dialogWidth, dialogHeight = 300, 120
    local x = (screenWidth - dialogWidth) / 2
    local y = (screenHeight - dialogHeight) / 2

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, dialogWidth, dialogHeight, 10)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, dialogWidth, dialogHeight, 10)

    gfx.drawTextAligned(DrumEdit.dialog.message, screenWidth / 2, y + 20, kTextAlignment.center)

    local optionWidth = 60
    local optionHeight = 20
    local optionY = y + dialogHeight - optionHeight - 10
    local centerX = screenWidth / 2

    gfx.drawTextAligned("Yes", centerX - optionWidth - 10, optionY + 5, kTextAlignment.center)
    gfx.drawRoundRect(centerX - optionWidth * 1.5 - 10, optionY, optionWidth, optionHeight, 3)

    gfx.drawTextAligned("No", centerX + optionWidth + 10, optionY + 5, kTextAlignment.center)
    gfx.drawRoundRect(centerX + optionWidth * 0.5 + 10, optionY, optionWidth, optionHeight, 3)

    local selectedX = centerX + (DrumEdit.dialog.selection == 1 and -optionWidth - 10 or optionWidth + 10)
    gfx.drawRoundRect(selectedX - optionWidth / 2, optionY, optionWidth, optionHeight, 3)
end

function DrumEdit.handleInput()
    if DrumEdit.sampleSelector.isOpen then
        DrumEdit.handleSampleSelector()
        return
    end

    if KeyManager.justReleased(KeyManager.keys.left) then
        DrumEdit.currentCursorIndex = math.max(1, DrumEdit.currentCursorIndex - 1)
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        DrumEdit.currentCursorIndex = math.min(#DrumEdit.cursorMap, DrumEdit.currentCursorIndex + 1)
    end



    if DrumEdit.currentCursorIndex <= 3 then
        if KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 13
        end
    elseif DrumEdit.currentCursorIndex <= 6 then
        if KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 14
        end
    elseif DrumEdit.currentCursorIndex <= 9 then
        if KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 15
        end
    elseif DrumEdit.currentCursorIndex <= 12 then
        if KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 16
        end
    elseif DrumEdit.currentCursorIndex <= 13 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 2
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 17
        end
    elseif DrumEdit.currentCursorIndex <= 14 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 5
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 18
        end
    elseif DrumEdit.currentCursorIndex <= 15 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 8
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 19
        end
    elseif DrumEdit.currentCursorIndex <= 16 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 10
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 20
        end
    elseif DrumEdit.currentCursorIndex <= 17 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 13
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 21
        end
    elseif DrumEdit.currentCursorIndex <= 18 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 14
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 22
        end
    elseif DrumEdit.currentCursorIndex <= 19 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 15
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 23
        end
    elseif DrumEdit.currentCursorIndex <= 20 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 16
        elseif KeyManager.justReleased(KeyManager.keys.down) then
            DrumEdit.currentCursorIndex = 24
        end
    elseif DrumEdit.currentCursorIndex <= 21 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 17
        end
    elseif DrumEdit.currentCursorIndex <= 22 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 18
        end
    elseif DrumEdit.currentCursorIndex <= 23 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 19
        end
    elseif DrumEdit.currentCursorIndex <= 24 then
        if KeyManager.justReleased(KeyManager.keys.up) then
            DrumEdit.currentCursorIndex = 20
        end
    end








    DrumEdit.updateCursor()

    local component = DrumEdit.uiComponents[DrumEdit.currentCursorIndex]
    if component then
        if component.callback then -- Button
            if KeyManager.justReleased(KeyManager.keys.a) then
                component.callback()
            end
        else -- Fader
            local increment
            if component.type == "int" then
                increment = 1
            else
                increment = 0.1
            end

            if KeyManager.justComboReleased("upA") or KeyManager.justComboReleased("rightA") or CrankManager.forwardTick then
                local newValue = component.value + increment
                if newValue <= component.maxValue then
                    component.value = newValue
                    component.handlePosition = component:valueToPosition(component.value)
                    DrumEdit.updateParameter(component.targetPath, component.value)
                end
            elseif KeyManager.justComboReleased("downA") or KeyManager.justComboReleased("leftA") or CrankManager.backwardTick then
                local newValue = component.value - increment
                if newValue >= component.minValue then
                    component.value = newValue
                    component.handlePosition = component:valueToPosition(component.value)
                    DrumEdit.updateParameter(component.targetPath, component.value)
                end
            end
        end
    end
end

function DrumEdit.updateCursor()
    if DrumEdit.currentCursorIndex >= 1 and DrumEdit.currentCursorIndex <= #DrumEdit.cursorMap then
        DrumEdit.cursor.x = DrumEdit.cursorMap[DrumEdit.currentCursorIndex].x
        DrumEdit.cursor.y = DrumEdit.cursorMap[DrumEdit.currentCursorIndex].y
        DrumEdit.cursor.w = DrumEdit.cursorMap[DrumEdit.currentCursorIndex].w
        DrumEdit.cursor.h = DrumEdit.cursorMap[DrumEdit.currentCursorIndex].h
    end
end

function DrumEdit.getInitialValue(target)
    local parts = {}
    for part in target:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local current = sail
    for i = 1, #parts do
        if current[parts[i]] == nil then
            console.log("Warning: Could not find initial value for " .. target)
            return 0
        end
        current = current[parts[i]]
    end

    return current
end

function DrumEdit.updateParameter(targetPath, value)
    local parts = {}
    for part in targetPath:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local current = sail
    for i = 1, #parts - 1 do
        if current[parts[i]] == nil then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end
    current[parts[#parts]] = value


    local drumNumber = parts[1]:match("drum(%d+)")
    if drumNumber then
        drumNumber = tonumber(drumNumber)

        Sounds.updateDrumParameters(drumNumber, sail["drum" .. drumNumber])
    end


    console.log("Updated " .. targetPath .. " to " .. tostring(value))
end

function DrumEdit.loadSample(targetPath)
    local drumNumber = targetPath:match("drum(%d+)")
    if drumNumber then
        DrumEdit.showSampleSelector(tonumber(drumNumber))
    end
end

function DrumEdit.draw()
    for _, component in ipairs(DrumEdit.uiComponents) do
        component:draw()
    end

    if DrumEdit.sampleSelector.isOpen then
        DrumEdit.drawSampleSelector()
    end
    if DrumEdit.dialog.isOpen then
        DrumEdit.drawDialog()
    end
end

return DrumEdit
