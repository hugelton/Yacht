local gfx <const> = playdate.graphics

-- Modal sample picker shared by DrumEdit (drum slots 3-6) and SynthEdit
-- (wavetable / sample voices). The caller supplies an onSelect callback and
-- decides what to do with the chosen name.
SampleSelector = {}

SampleSelector.list = {
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

SampleSelector.state = {
    isOpen = false,
    selectedIndex = 1,
    scrollOffset = 0,
    maxVisibleItems = 7,
    itemHeight = 20,
    width = 360,
    height = 180,
    x = (400 - 360) / 2,
    y = (240 - 180) / 2,
    title = "Select Sample",
    onSelect = nil
}

function SampleSelector.isOpen()
    return SampleSelector.state.isOpen
end

-- Mic recordings are appended so freshly captured takes show up in the picker.
function SampleSelector.entries()
    local entries = {}
    for _, name in ipairs(SampleSelector.list) do entries[#entries + 1] = name end
    for _, name in ipairs(Recorder.list()) do entries[#entries + 1] = name end
    return entries
end

local function scrollToSelection()
    local state = SampleSelector.state
    if state.selectedIndex <= state.scrollOffset then
        state.scrollOffset = state.selectedIndex - 1
    elseif state.selectedIndex > state.scrollOffset + state.maxVisibleItems then
        state.scrollOffset = state.selectedIndex - state.maxVisibleItems
    end
    state.scrollOffset = math.max(0, math.min(state.scrollOffset,
        math.max(0, #SampleSelector.list - state.maxVisibleItems)))
end

-- onSelect(name) returns true when the sample was accepted; returning false
-- keeps the dialog open so the user can pick something else.
function SampleSelector.open(title, currentSample, onSelect)
    local state = SampleSelector.state
    state.isOpen = true
    state.title = title or "Select Sample"
    state.onSelect = onSelect
    state.selectedIndex = 1
    state.scrollOffset = 0

    for index, name in ipairs(SampleSelector.list) do
        if name == currentSample then
            state.selectedIndex = index
            break
        end
    end
    scrollToSelection()

    cursor.hide()
    currentFocus = "dialog"
end

function SampleSelector.close()
    local state = SampleSelector.state
    if not state.isOpen then return end
    state.isOpen = false
    state.onSelect = nil
    cursor.show()
    currentFocus = "main"
end

function SampleSelector.handleInput()
    local state = SampleSelector.state
    if not state.isOpen then return end

    if KeyManager.justReleased(KeyManager.keys.up) or CrankManager.backwardTick then
        state.selectedIndex = math.max(1, state.selectedIndex - 1)
        scrollToSelection()
    elseif KeyManager.justReleased(KeyManager.keys.down) or CrankManager.forwardTick then
        state.selectedIndex = math.min(#SampleSelector.list, state.selectedIndex + 1)
        scrollToSelection()
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        local selected = SampleSelector.list[state.selectedIndex]
        local accepted = selected and state.onSelect and state.onSelect(selected)
        if accepted then
            SampleSelector.close()
        else
            Balloon.open("Sample is not installed")
        end
    end
end

function SampleSelector.draw()
    local state = SampleSelector.state
    if not state.isOpen then return end

    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.5)
    gfx.fillRect(0, 0, 400, 240)

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(state.x, state.y, state.width, state.height, 0)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(state.x, state.y, state.width, state.height, 0)

    gfx.drawTextAligned("*" .. state.title .. "*", state.x + state.width / 2,
        state.y + 10, kTextAlignment.center)

    gfx.drawRect(state.x + 10, state.y + 28, state.width - 30,
        state.itemHeight * state.maxVisibleItems + 1)
    gfx.drawRect(state.x + state.width - 21, state.y + 28, 17,
        state.itemHeight * state.maxVisibleItems + 1)

    for i = 1, math.min(state.maxVisibleItems, #SampleSelector.list - state.scrollOffset) do
        local index = i + state.scrollOffset
        local y = state.y + 28 + (i - 1) * state.itemHeight

        gfx.setDitherPattern(0.5)
        gfx.drawRect(state.x + 10, y, state.width - 30, state.itemHeight + 1)
        gfx.setDitherPattern(0)

        if index == state.selectedIndex then
            gfx.fillRect(state.x + 10, y, state.width - 30, state.itemHeight)
            gfx.setImageDrawMode(gfx.kDrawModeInverted)
        end

        gfx.drawText("💽", state.x + 15, y + 6)
        assets.fonts.nada:drawText(SampleSelector.list[index], state.x + 35, y + 6)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    if #SampleSelector.list > state.maxVisibleItems then
        local scrollBarHeight = (state.maxVisibleItems / #SampleSelector.list) * (state.height - 80)
        local scrollBarY = state.y + 28 +
            (state.scrollOffset / (#SampleSelector.list - state.maxVisibleItems)) *
            (state.height - 40 - scrollBarHeight)
        gfx.fillRoundRect(state.x + state.width - 19, scrollBarY, 13, scrollBarHeight, 2)
    end

    gfx.setColor(gfx.kColorBlack)
end

console.log("SampleSelector loaded")

return SampleSelector
