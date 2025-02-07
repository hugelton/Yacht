KeyManager = {}

LONG_PRESS_DURATION = 500

KeyManager.keys = {
    up = playdate.kButtonUp,
    down = playdate.kButtonDown,
    left = playdate.kButtonLeft,
    right = playdate.kButtonRight,
    a = playdate.kButtonA,
    b = playdate.kButtonB
}

KeyManager.combos = {
    upA = { KeyManager.keys.up, KeyManager.keys.a },
    upB = { KeyManager.keys.up, KeyManager.keys.b },
    downA = { KeyManager.keys.down, KeyManager.keys.a },
    downB = { KeyManager.keys.down, KeyManager.keys.b },
    leftA = { KeyManager.keys.left, KeyManager.keys.a },
    leftB = { KeyManager.keys.left, KeyManager.keys.b },
    rightA = { KeyManager.keys.right, KeyManager.keys.a },
    rightB = { KeyManager.keys.right, KeyManager.keys.b },
    ab = { KeyManager.keys.a, KeyManager.keys.b },
    upDown = { KeyManager.keys.up, KeyManager.keys.down },
    leftRight = { KeyManager.keys.left, KeyManager.keys.right }
}

local keyStates = {}
local comboStates = {}
local activeCombo = nil
local comboKeys = {}
local lastUpdateTime = playdate.getCurrentTimeMilliseconds()


for name, key in pairs(KeyManager.keys) do
    keyStates[key] = {
        isPressed = false,
        justPressed = false,
        justReleased = false,
        pressTime = 0,
        isLongPress = false,
        wasPartOfCombo = false
    }
end

for name, combo in pairs(KeyManager.combos) do
    comboStates[name] = {
        isPressed = false,
        justPressed = false,
        justReleased = false
    }
end

local function updateKeyState(key)
    local state = keyStates[key]
    local isPressed = playdate.buttonIsPressed(key)

    state.justPressed = isPressed and not state.isPressed and not state.wasPartOfCombo
    state.justReleased = not isPressed and state.isPressed and not state.wasPartOfCombo
    state.isPressed = isPressed

    if not isPressed then
        state.wasPartOfCombo = false
    end

    return state
end

local function updateComboState(comboName, combo)
    local state = comboStates[comboName]
    local key1, key2 = combo[1], combo[2]
    local isPressed = keyStates[key1].isPressed and keyStates[key2].isPressed

    state.justPressed = isPressed and not state.isPressed
    state.justReleased = not isPressed and state.isPressed
    state.isPressed = isPressed

    if state.justPressed then
        activeCombo = comboName
        comboKeys = { [key1] = true, [key2] = true }
        keyStates[key1].wasPartOfCombo = true
        keyStates[key2].wasPartOfCombo = true
    elseif state.justReleased then
        activeCombo = nil
        comboKeys = {}
    end

    return state
end

function KeyManager.update()
    local currentTime = playdate.getCurrentTimeMilliseconds()
    local deltaTime = currentTime - lastUpdateTime
    lastUpdateTime = currentTime


    for comboName, combo in pairs(KeyManager.combos) do
        updateComboState(comboName, combo)
    end


    for key, state in pairs(keyStates) do
        local updatedState = updateKeyState(key)
        if updatedState.justPressed then
            state.pressTime = 0
            state.isLongPress = false
        elseif updatedState.isPressed then
            state.pressTime = state.pressTime + deltaTime
            if state.pressTime >= LONG_PRESS_DURATION and not state.isLongPress then
                state.isLongPress = true
            end
        end
    end
end

function KeyManager.isPressed(key)
    return keyStates[key].isPressed
end

function KeyManager.justPressed(key)
    return keyStates[key].justPressed
end

function KeyManager.justReleased(key)
    return keyStates[key].justReleased
end

function KeyManager.isLongPress(key)
    return keyStates[key].isLongPress
end

function KeyManager.isComboPressed(comboName)
    return comboStates[comboName].isPressed
end

function KeyManager.justComboPressed(comboName)
    return comboStates[comboName].justPressed
end

function KeyManager.justComboReleased(comboName)
    return comboStates[comboName].justReleased
end

function KeyManager.printKeyStatus()
    local keys = { "up", "down", "left", "right", "a", "b" }
    local combos = { "upA", "upB", "downA", "downB", "leftA", "leftB", "rightA", "rightB", "ab" }

    for _, key in ipairs(keys) do
        if KeyManager.justPressed(KeyManager.keys[key]) then
            console.log(key .. " button just pressed")
        end
        if KeyManager.justReleased(KeyManager.keys[key]) then
            console.log(key .. " button just released")
        end
    end

    for _, combo in ipairs(combos) do
        if KeyManager.justComboPressed(combo) then
            console.log(combo .. " combo just pressed")
        end
        if KeyManager.justComboReleased(combo) then
            console.log(combo .. " combo just released")
        end
    end
end

return KeyManager
