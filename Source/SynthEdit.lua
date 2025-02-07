local gfx <const> = playdate.graphics

SynthEdit = {}


SynthEdit.VFader = {}
SynthEdit.VFader.__index = SynthEdit.VFader



local valueChanged



local shouldAnimateOsc = false
local shouldAnimateLfo = false
local shouldAnimateFilter = false

SynthEdit.targetNum = 1

SynthEdit.VFader = {}
SynthEdit.VFader.__index = SynthEdit.VFader
function SynthEdit.VFader.new(x, y, label, value, minValue, maxValue, steps, targetPath, type, knob)
    local self = setmetatable({}, SynthEdit.VFader)
    self.x, self.y = x, y
    self.label = label
    self.value = type == "float" and (tonumber(value) or minValue) or (math.floor(tonumber(value) or minValue))
    self.minValue, self.maxValue = minValue, maxValue
    self.steps = steps
    self.width = 20
    self.height = 45
    self.cursorWidth, self.cursorHeight = 25, 70
    self.targetPath = targetPath
    self.type = type
    self.knob = knob
    self.handlePosition = self:valueToPosition(self.value)
    return self
end

function SynthEdit.VFader:valueToPosition(value)
    local normalizedValue = (value - self.minValue) / (self.maxValue - self.minValue)
    return self.y + self.height - normalizedValue * self.height
end

function SynthEdit.VFader:positionToValue(position)
    local normalizedPosition = (self.y + self.height - position) / self.height
    if self.type == "float" then
        return self.minValue + (self.maxValue - self.minValue) * normalizedPosition
    else
        local stepSize = (self.maxValue - self.minValue) / (self.steps - 1)
        return math.floor(normalizedPosition * (self.steps - 1) + 0.5) * stepSize + self.minValue
    end
end

function SynthEdit.VFader:draw()
    assets.vknob:drawImage(self.knob, self.x + 2, self.handlePosition - 2)
end

SynthEdit.HFader = {}
SynthEdit.HFader.__index = SynthEdit.HFader

function SynthEdit.HFader.new(x, y, label, value, minValue, maxValue, steps, targetPath, type)
    local self = setmetatable({}, SynthEdit.HFader)
    self.x, self.y = x, y
    self.label = label
    self.value = value
    self.type = type
    self.minValue, self.maxValue = minValue, maxValue
    self.steps = steps
    self.width, self.height = 35, 20
    self.cursorWidth, self.cursorHeight = 45, 25
    self.targetPath = targetPath
    self.handlePosition = self:valueToPosition(value)
    return self
end

function SynthEdit.HFader:valueToPosition(value)
    return self.x + (value - self.minValue) / (self.maxValue - self.minValue) * self.width
end

function SynthEdit.HFader:positionToValue(position)
    local normalizedPosition = (position - self.x) / self.width
    if self.type == "float" then
        return self.minValue + (self.maxValue - self.minValue) * normalizedPosition
    else
        local stepSize = (self.maxValue - self.minValue) / (self.steps - 1)
        return math.floor(normalizedPosition * (self.steps - 1) + 0.5) * stepSize + self.minValue
    end
end

function SynthEdit.HFader:draw()
    gfx.fillRoundRect(self.handlePosition - 2, self.y + 2, 8, self.height - 4, 2)
end

SynthEdit.CheckBox = {}
SynthEdit.CheckBox.__index = SynthEdit.CheckBox

function SynthEdit.CheckBox.new(x, y, label, target)
    local self = setmetatable({}, SynthEdit.CheckBox)
    self.x, self.y = x, y
    self.label = label
    self.targetPath = target
    self.checked = false
    self.width, self.height = 10, 10
    self.cursorWidth, self.cursorHeight = 40, 20
    self.faderType = "checkbox"
    return self
end

function SynthEdit.CheckBox:draw()
    if self.checked then
        gfx.fillRect(self.x + 2, self.y + 2, 6, 6)
    end
end

function SynthEdit.CheckBox:toggle()
    self.checked = not self.checked
    return true
end

SynthEdit.RadioSet = {}
SynthEdit.RadioSet.__index = SynthEdit.RadioSet

function SynthEdit.RadioSet.new(x, y, label, target1, target2)
    local self = setmetatable({}, SynthEdit.RadioSet)
    self.x, self.y = x, y
    self.label = label
    self.target1 = target1
    self.target2 = target2
    self.checked1 = false
    self.checked2 = false
    self.width, self.height = 50, 20
    self.cursorWidth, self.cursorHeight = 50, 20
    self.faderType = "radioset"
    return self
end

function SynthEdit.RadioSet:draw()
    if self.checked1 == true then
        gfx.fillRect(self.x + 2, self.y + 2, 6, 6)
    end




    if self.checked2 == true then
        gfx.fillRect(self.x + 17, self.y + 2, 6, 6)
    end
end

function SynthEdit.RadioSet:toggle(index)
    if index == 1 then
        self.checked1 = true
        self.checked2 = false
    elseif index == 2 then
        self.checked1 = false
        self.checked2 = true
    end
end

function SynthEdit.RadioSet:allOff()
    self.checked1 = false
    self.checked2 = false
end

SynthEdit.parameters = {
    -- OSCILLATOR
    { x = 15 + 22, y = 95, label = "Form", type = "int", knob = 2, min = 0, max = 7, steps = 8, target = "synth[now].oscillator.form", faderType = "horizontal" },
    { x = 66 + 22, y = 65, label = "①", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].oscillator.param1", faderType = "vertical" },
    { x = 88 + 22, y = 65, label = "②", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].oscillator.param2", faderType = "vertical" },
    -- FILTER
    { x = 118 + 22, y = 95, label = "Type", type = "int", knob = 2, min = 0, max = 6, steps = 7, target = "synth[now].filter.type", faderType = "horizontal" },
    { x = 162 + 22, y = 65, label = "Cut.", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].filter.cutoff", faderType = "vertical" },
    { x = 184 + 22, y = 65, label = "Res.", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].filter.resonance", faderType = "vertical" },




    -- AMP
    { x = 230, y = 65, label = "_A_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].amp.attack", faderType = "vertical" },
    { x = 252, y = 65, label = "_D_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].amp.decay", faderType = "vertical" },
    { x = 274, y = 65, label = "_S_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].amp.sustain", faderType = "vertical" },
    { x = 296, y = 65, label = "_R_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].amp.release", faderType = "vertical" },

    { x = 318, y = 65, label = "Vol", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].amp.volume", faderType = "vertical" },
    -- LFO
    { x = 17 + 2, y = 190, label = "Form", type = "int", knob = 2, min = 0, max = 5, steps = 6, target = "synth[now].lfo.form", faderType = "horizontal" },
    { x = 65, y = 160, label = "Frq.", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].lfo.frequency", faderType = "vertical" },
    { x = 87, y = 160, label = "Hold", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].lfo.hold", faderType = "vertical" },
    { x = 109, y = 160, label = "Dly.", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].lfo.delay", faderType = "vertical" },
    { x = 131, y = 160, label = "Dep.", type = "float", knob = 1, min = 0, max = 1, steps = 11, target = "synth[now].lfo.depth", faderType = "vertical" },
    -- ENV
    { x = 162 - 2, y = 160, label = "_A_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].env.attack", faderType = "vertical" },
    { x = 184 - 2, y = 160, label = "_D_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].env.decay", faderType = "vertical" },
    { x = 206 - 2, y = 160, label = "_S_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].env.sustain", faderType = "vertical" },
    { x = 228 - 2, y = 160, label = "_R_", type = "float", knob = 2, min = 0, max = 1, steps = 11, target = "synth[now].env.release", faderType = "vertical" },
    { x = 250 - 2, y = 160, label = "Dep.", type = "float", knob = 1, min = 0, max = 1, steps = 11, target = "synth[now].env.depth", faderType = "vertical" },
    -- MOD
    { x = 276 + 8 - 2, y = 160 + 4, label = "Pitch", type = "radioset", target1 = "synth[now].lfo.pitch", target2 = "synth[now].env.pitch", faderType = "radioset" },
    { x = 276 + 8 - 2, y = 175 + 4, label = "Cut.", type = "radioset", target1 = "synth[now].lfo.filter", target2 = "synth[now].env.filter", faderType = "radioset" },
    { x = 276 + 8 - 2, y = 190 + 4, label = "①", type = "radioset", target1 = "synth[now].lfo.param1", target2 = "synth[now].env.param1", faderType = "radioset" },
    { x = 276 + 8 - 2, y = 205 + 4, label = "②", type = "radioset", target1 = "synth[now].lfo.param2", target2 = "synth[now].env.param2", faderType = "radioset" },


}





SynthEdit.uiComponents = {}
SynthEdit.cursorMap = {}
SynthEdit.cursor = { x = 0, y = 0, w = 0, h = 0 }
SynthEdit.currentCursorIndex = 1



local noiseTable = {}
local sampleAndHoldTable = {}


local function initializeTables()
    for i = 1, 100 do
        noiseTable[i] = math.random()
    end

    --
    for i = 1, 8 do
        sampleAndHoldTable[i] = math.random()
    end
end


local function drawOscWaveform()
    local synthIndex = SynthEdit.targetNum

    local x, y, w, h = 18 + 22, 67, 37, 16
    local currentForm = sail["synth" .. synthIndex].oscillator.form
    local time = shouldAnimateOsc and (playdate.getCurrentTimeMilliseconds() / 1000) or 0

    gfx.pushContext()
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)

    -- PO波形の場合はテキスト表示
    if currentForm >= playdate.sound.kWavePOPhase then
        local poWaveforms = { "POPhase", "PODigital", "POVosim" }
        local text = poWaveforms[currentForm - playdate.sound.kWavePOPhase + 1] or "Unknown"
        gfx.drawTextAligned(text, x + w / 2, y + h / 2 - 4, kTextAlignment.center)
    else
        local drawWave = function(t)
            -- [kWaveSquare] = 0,
            -- [kWaveTriangle] = 1,
            -- [kWaveSine] = 2,
            -- [kWaveNoise] = 3,
            -- [kWaveSawtooth] = 4,
            -- [kWavePOPhase] = 5,
            -- [kWavePODigital] = 6,
            -- [kWavePOVosim] = 7,
            ------ ??????????

            for i = 0, w - 1 do
                local x1, y1 = x + i, y + h / 2
                local x2, y2 = x + i + 1, y + h / 2
                if currentForm == 0 then
                    y1 = y + h / 2 + math.sin((i / w + t) * math.pi * 2) * h / 2
                    y2 = y + h / 2 + math.sin(((i + 1) / w + t) * math.pi * 2) * h / 2
                elseif currentForm == 1 then
                    y1 = y + h / 2 -
                        (((i / w + t) % 1 < sail["synth" .. SynthEdit.targetNum].oscillator.param1) and h / 2 or -h / 2)
                    y2 = y + h / 2 -
                        ((((i + 1) / w + t) % 1 < sail["synth" .. SynthEdit.targetNum].oscillator.param1) and h / 2 or -h / 2)
                elseif currentForm == 2 then
                    y1 = y + h - ((i / w + t) % 1) * h
                    y2 = y + h - (((i + 1) / w + t) % 1) * h
                elseif currentForm == 3 then
                    local tri = function(x) return math.abs(((x % 1) * 4 + 1) % 4 - 2) - 1 end
                    y1 = y + h / 2 + tri((i / w + t) * 2) * h / 2
                    y2 = y + h / 2 + tri(((i + 1) / w + t) * 2) * h / 2
                elseif currentForm == 4 then
                    y1 = y + noiseTable[i + 1] * h

                    y2 = y + noiseTable[i + 2] * h
                else
                    y1, y2 = y + h / 2, y + h / 2
                end
                gfx.drawLine(x1, y1, x2, y2)
            end
        end

        drawWave(time % 1)
    end

    gfx.popContext()
end


local function drawLfoWaveform()
    local synthIndex = SynthEdit.targetNum
    local x, y, w, h = 18, 162, 37, 16
    local currentForm = sail["synth" .. synthIndex].lfo.form

    local time = shouldAnimateLfo and (playdate.getCurrentTimeMilliseconds() / 1000) or 0

    gfx.pushContext()
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)


    -- 波形の描画
    local drawWave = function(t)
        local stepSize = w / 8 -- S&Hのステップサイズ

        for i = 0, w - 1 do
            local x1, y1 = x + i, y + h / 2
            local x2, y2 = x + i + 1, y + h / 2

            if currentForm == 5 then
                local step = math.floor(i / stepSize) + 1
                y1 = y + sampleAndHoldTable[step] * h
                y2 = y1
            elseif currentForm == 0 then
                y1 = y + h / 2 + math.sin((i / w + t) * math.pi * 2) * h / 2
                y2 = y + h / 2 + math.sin(((i + 1) / w + t) * math.pi * 2) * h / 2
            elseif currentForm == 1 then
                y1 = y + h / 2 - (((i / w + t) % 1 < 0.5) and h / 2 or -h / 2)
                y2 = y + h / 2 - ((((i + 1) / w + t) % 1 < 0.5) and h / 2 or -h / 2)
            elseif currentForm == 2 then
                y1 = y + h - ((i / w + t) % 1) * h
                y2 = y + h - (((i + 1) / w + t) % 1) * h
            elseif currentForm == 3 then
                y1 = y + ((i / w + t) % 1) * h
                y2 = y + (((i + 1) / w + t) % 1) * h
            elseif currentForm == 4 then
                local tri = function(x) return math.abs(((x % 1) * 4 + 1) % 4 - 2) - 1 end
                y1 = y + h / 2 + tri((i / w + t) * 2) * h / 2
                y2 = y + h / 2 + tri(((i + 1) / w + t) * 2) * h / 2
            end

            gfx.drawLine(x1, y1, x2, y2)
        end
    end

    drawWave(time % 1)

    gfx.popContext()
end



local function drawFilterType()
    local synthIndex = SynthEdit.targetNum
    local x, y, w, h = 118 + 22, 67, 41, 16
    local currentType = sail["synth" .. synthIndex].filter.type

    gfx.pushContext()
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)

    assets.filterTypes:drawImage(currentType + 1, x + 8, y - 4)


    gfx.popContext()
end

function SynthEdit.drawWaveformPreviews()
    drawOscWaveform()
    drawLfoWaveform()
    drawFilterType()
end

function SynthEdit.toggleOscAnimation()
    shouldAnimateOsc = not shouldAnimateOsc
end

function SynthEdit.toggleLfoAnimation()
    shouldAnimateLfo = not shouldAnimateLfo
end

function SynthEdit.toggleFilterAnimation()
    shouldAnimateFilter = not shouldAnimateFilter
end

function SynthEdit.init()
    console.log("SynthEditの初期化を始めます")
    initializeTables()
    for i, param in ipairs(SynthEdit.parameters) do
        local component
        if param.faderType == "radioset" then
            component = SynthEdit.RadioSet.new(param.x, param.y, param.label, param.target1, param.target2)


            if SynthEdit.getInitialValue(param.target1) == 1 then
                component.checked1 = true
            else
                component.checked1 = false
            end
            if SynthEdit.getInitialValue(param.target2) == 1 then
                component.checked2 = true
            else
                component.checked2 = false
            end
        elseif param.faderType == "horizontal" then
            local initialValue = SynthEdit.getInitialValue(param.target)
            component = SynthEdit.HFader.new(param.x, param.y, param.label, initialValue, param.min, param.max,
                param.steps, param.target, param.type)
            component.handlePosition = component:valueToPosition(initialValue)
        elseif param.faderType == "checkbox" then
            local initialValue = SynthEdit.getInitialValue(param.target)
            component = SynthEdit.CheckBox.new(param.x, param.y, param.label, param.target)
            component.checked = initialValue
        elseif param.faderType == "vertical" then
            local initialValue = SynthEdit.getInitialValue(param.target)
            component = SynthEdit.VFader.new(param.x, param.y, param.label, initialValue, param.min, param.max,
                param.steps, param.target, param.type, param.knob)
            component.handlePosition = component:valueToPosition(initialValue)
        end
        table.insert(SynthEdit.uiComponents, component)
        table.insert(SynthEdit.cursorMap,
            { x = param.x - 2, y = param.y - 5, w = component.cursorWidth, h = component.cursorHeight })
    end

    if #SynthEdit.cursorMap > 0 then
        SynthEdit.cursor = {
            x = SynthEdit.cursorMap[1].x,
            y = SynthEdit.cursorMap[1].y,
            w = SynthEdit.cursorMap[1].w,
            h = SynthEdit.cursorMap[1].h
        }
    end
    console.log("SynthEditの初期化が完了しました")
end

function SynthEdit.getInitialValue(target)
    if not target then
        console.log("Warning: No target provided to getInitialValue")
        return 0
    end


    target = target:gsub("synth%[now%]", "synth" .. SynthEdit.targetNum)

    local parts = {}
    for part in target:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local category = parts[2]
    local parameter = parts[3]

    if sail["synth" .. SynthEdit.targetNum] and
        sail["synth" .. SynthEdit.targetNum][category] and
        sail["synth" .. SynthEdit.targetNum][category][parameter] ~= nil then
        local value = sail["synth" .. SynthEdit.targetNum][category][parameter]
        return type(value) == "boolean" and (value and 1 or 0) or value
    else
        console.log("初期値が見つかりません: " .. target)
        return 0
    end
end

function SynthEdit.draw()
    for _, component in ipairs(SynthEdit.uiComponents) do
        component:draw()
    end

    gfx.drawText("_w_", 302, 55)
    SynthEdit.drawWaveformPreviews()
    assets.synSelect:drawImage(SynthEdit.targetNum, 362, 38)
end

function SynthEdit.switchSynth(dir)
    if dir == 1 then
        SynthEdit.targetNum = math.min(3, SynthEdit.targetNum + 1)
    elseif dir == 0 then
        SynthEdit.targetNum = math.max(1, SynthEdit.targetNum - 1)
    end
end

function SynthEdit.updateSail(target, value)
    local parts = {}
    for part in target:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    local synthIndex = parts[1]:match("synth(%d+)") or SynthEdit.targetNum
    local category = parts[2]
    local parameter = parts[3]

    if not sail["synth" .. synthIndex] then
        sail["synth" .. synthIndex] = {}
    end
    if not sail["synth" .. synthIndex][category] then
        sail["synth" .. synthIndex][category] = {}
    end

    sail["synth" .. synthIndex][category][parameter] = value


    if category == "lfo" or category == "env" then
        local otherCategory = (category == "lfo") and "env" or "lfo"
        sail["synth" .. synthIndex][otherCategory][parameter] = false
    end

    console.log("更新: " .. category .. "." .. parameter .. " for synth" .. synthIndex .. " to " .. tostring(value))


    Sounds.updateSynthParameters(synthIndex, sail["synth" .. synthIndex])
end

function SynthEdit.load()
    SynthEdit.targetNum = 1
    SynthEdit.currentCursorIndex = 1


    SynthEdit.uiComponents = {}
    SynthEdit.cursorMap = {}


    for i, param in ipairs(SynthEdit.parameters) do
        local component
        if param.faderType == "radioset" then
            component = SynthEdit.RadioSet.new(param.x, param.y, param.label, param.target1, param.target2)

            if param.target1 then
                component.checked1 = SynthEdit.getInitialValue(param.target1) == 1
            end
            if param.target2 then
                component.checked2 = SynthEdit.getInitialValue(param.target2) == 1
            end
        elseif param.faderType == "horizontal" then
            local initialValue = SynthEdit.getInitialValue(param.target)
            component = SynthEdit.HFader.new(param.x, param.y, param.label, initialValue,
                param.min, param.max, param.steps, param.target, param.type)
        elseif param.faderType == "checkbox" then
            local initialValue = SynthEdit.getInitialValue(param.target)
            component = SynthEdit.CheckBox.new(param.x, param.y, param.label, param.target)
            component.checked = initialValue == 1
        elseif param.faderType == "vertical" then
            local initialValue = SynthEdit.getInitialValue(param.target)
            component = SynthEdit.VFader.new(param.x, param.y, param.label, initialValue,
                param.min, param.max, param.steps, param.target, param.type, param.knob)
        end

        if component then
            table.insert(SynthEdit.uiComponents, component)
            table.insert(SynthEdit.cursorMap, {
                x = param.x - 2,
                y = param.y - 5,
                w = component.cursorWidth,
                h = component.cursorHeight
            })
        end
    end


    if #SynthEdit.cursorMap > 0 then
        SynthEdit.cursor = {
            x = SynthEdit.cursorMap[1].x,
            y = SynthEdit.cursorMap[1].y,
            w = SynthEdit.cursorMap[1].w,
            h = SynthEdit.cursorMap[1].h
        }
    end


    for i = 1, 3 do
        Sounds.updateSynthParameters(i, sail["synth" .. i])
    end
end

local function getIncrement(baseIncrement, componentType)
    if componentType == "int" then
        return baseIncrement >= 0 and math.max(1, math.floor(baseIncrement)) or math.min(-1, math.ceil(baseIncrement))
    else -- float
        return baseIncrement
    end
end

function SynthEdit.handleInput()
    local oldIndex = SynthEdit.currentCursorIndex
    local rowCount = 12


    if KeyManager.justReleased(KeyManager.keys.left) then
        SynthEdit.currentCursorIndex = math.max(1, SynthEdit.currentCursorIndex - 1)
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        SynthEdit.currentCursorIndex = math.min(#SynthEdit.cursorMap, SynthEdit.currentCursorIndex + 1)
    elseif KeyManager.justReleased(KeyManager.keys.up) then
        if SynthEdit.currentCursorIndex > rowCount then
            SynthEdit.currentCursorIndex = SynthEdit.currentCursorIndex - rowCount
        elseif SynthEdit.currentCursorIndex > 1 then
            SynthEdit.currentCursorIndex = SynthEdit.currentCursorIndex - 1
        end
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        if SynthEdit.currentCursorIndex <= rowCount then
            SynthEdit.currentCursorIndex = math.min(#SynthEdit.cursorMap, SynthEdit.currentCursorIndex + rowCount)
        elseif SynthEdit.currentCursorIndex < #SynthEdit.cursorMap then
            SynthEdit.currentCursorIndex = SynthEdit.currentCursorIndex + 1
        end
    end


    if oldIndex ~= SynthEdit.currentCursorIndex then
        SynthEdit.cursor.x = SynthEdit.cursorMap[SynthEdit.currentCursorIndex].x
        SynthEdit.cursor.y = SynthEdit.cursorMap[SynthEdit.currentCursorIndex].y
        SynthEdit.cursor.w = SynthEdit.cursorMap[SynthEdit.currentCursorIndex].w
        SynthEdit.cursor.h = SynthEdit.cursorMap[SynthEdit.currentCursorIndex].h
    end


    local component = SynthEdit.uiComponents[SynthEdit.currentCursorIndex]
    if not component then return end

    local isHorizontal = component.width and component.width > component.height
    local isCheckbox = component.faderType == "checkbox"
    local function updateValue(increment)
        if component.faderType == "radioset" then
            if KeyManager.justComboReleased("leftA") then
                component:toggle(1)
                SynthEdit.updateSail(component.target1, true)
                SynthEdit.updateSail(component.target2, false)
            elseif KeyManager.justComboReleased("rightA") then
                component:toggle(2)
                SynthEdit.updateSail(component.target1, false)
                SynthEdit.updateSail(component.target2, true)
            end
        elseif isCheckbox then
            return component:toggle()
        elseif component.type == "int" then
            local newValue = math.floor(component.value + increment + 0.5)
            component.value = math.max(component.minValue, math.min(component.maxValue, newValue))
        else -- float
            component.value = math.max(component.minValue, math.min(component.maxValue, component.value + increment))
        end
        if component.valueToPosition then
            component.handlePosition = component:valueToPosition(component.value)
        end
        return true
    end
    if component.faderType == "radioset" then
        if KeyManager.justReleased(KeyManager.keys.a) then
            component:allOff()
            SynthEdit.updateSail(component.target1, false)
            SynthEdit.updateSail(component.target2, false)
        end
    end

    local valueChanged = false

    if isCheckbox then
        if KeyManager.justReleased(KeyManager.keys.a) then
            component.checked = not component.checked
            valueChanged = true

            SynthEdit.updateSail(component.targetPath, component.checked)
            return -- 更新後は即座に関数を抜ける
        end
    elseif isHorizontal then
        local increment = getIncrement(0.01, component.type)
        local largeIncrement = getIncrement(0.1, component.type)

        if KeyManager.justComboReleased("rightA") then
            valueChanged = updateValue(largeIncrement)
        elseif KeyManager.justComboReleased("leftA") then
            valueChanged = updateValue(-largeIncrement)
        end
    else
        local increment = getIncrement(0.01, component.type)
        local largeIncrement = getIncrement(0.1, component.type)

        if KeyManager.justComboReleased("upA") then
            valueChanged = updateValue(largeIncrement)
        elseif KeyManager.justComboReleased("downA") then
            valueChanged = updateValue(-largeIncrement)
        end
    end

    if CrankManager.forwardTick then
        valueChanged = updateValue(getIncrement(0.01, component.type))
    elseif CrankManager.backwardTick then
        valueChanged = updateValue(-getIncrement(0.01, component.type))
    end

    if valueChanged then
        if component and component.targetPath then
            SynthEdit.updateSail(component.targetPath, component.value)


            local parts = {}
            for part in component.targetPath:gmatch("[^.]+") do
                table.insert(parts, part)
            end
            local category = parts[2]
            local parameter = parts[3]
            console.log("値が変わったで！ " .. category .. "." .. parameter .. ": " ..
                tostring(sail["synth" .. SynthEdit.targetNum][category][parameter]))


            if isHorizontal then
                console.log("HFaderの値: " .. tostring(component.value))
                console.log("HFaderの位置: " .. tostring(component.handlePosition))
            end
        else
            if component.faderType == "radioset" then
                local targetPath1 = component.target1:gsub("synth%[now%].", "")
                local targetPath2 = component.target2:gsub("synth%[now%].", "")
                local targetPath1Category = targetPath1:match("([^%.]*)%.")
                local targetPath2Category = targetPath2:match("([^%.]*)%.")
                local targetPath1Parameter = targetPath1:match("%.(.*)")
                local targetPath2Parameter = targetPath2:match("%.(.*)")


                if component.checked1 then
                    sail["synth" .. SynthEdit.targetNum][targetPath1Category][targetPath1Parameter] = true
                    sail["synth" .. SynthEdit.targetNum][targetPath2Category][targetPath2Parameter] = false
                elseif component.checked2 then
                    sail["synth" .. SynthEdit.targetNum][targetPath1Category][targetPath1Parameter] = false
                    sail["synth" .. SynthEdit.targetNum][targetPath2Category][targetPath2Parameter] = true
                else
                    sail["synth" .. SynthEdit.targetNum][targetPath1Category][targetPath1Parameter] = false
                    sail["synth" .. SynthEdit.targetNum][targetPath2Category][targetPath2Parameter] = false
                end
            else
                console.log("コンポーネントかターゲットパスがおかしいで")
            end
        end

        valueChanged = false
    end
end

return SynthEdit
