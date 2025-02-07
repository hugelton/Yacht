import "CoreLibs/crank"

CrankManager = {}

CrankManager.ticksPerRevolution = 24 -- tick per revolution
CrankManager.tickInterval = 50       -- 　ms


local isDocked = playdate.isCrankDocked()
local lastTickTime = playdate.getCurrentTimeMilliseconds()

CrankManager.forwardTick = false
CrankManager.backwardTick = false

local forwardCallbacks = {}
local backwardCallbacks = {}

function CrankManager.update()
    local currentTime = playdate.getCurrentTimeMilliseconds()
    local crankTicks = playdate.getCrankTicks(CrankManager.ticksPerRevolution)

    if crankTicks ~= 0 then
        if currentTime - lastTickTime >= CrankManager.tickInterval then
            CrankManager.forwardTick = (crankTicks > 0)
            CrankManager.backwardTick = (crankTicks < 0)
            lastTickTime = currentTime

            if CrankManager.forwardTick then
                for _, callback in ipairs(forwardCallbacks) do
                    callback()
                end
            elseif CrankManager.backwardTick then
                for _, callback in ipairs(backwardCallbacks) do
                    callback()
                end
            end
        end
    else
        CrankManager.forwardTick = false
        CrankManager.backwardTick = false
    end




    local currentDocked = playdate.isCrankDocked()
    if currentDocked ~= isDocked then
        isDocked = currentDocked
        if isDocked then
            CrankManager.onCrankDocked()
        else
            CrankManager.onCrankUndocked()
        end
    end

    playdate.timer.updateTimers()
end

function CrankManager.addForwardCallback(callback)
    table.insert(forwardCallbacks, callback)
end

function CrankManager.addBackwardCallback(callback)
    table.insert(backwardCallbacks, callback)
end

function CrankManager.getPosition()
    return playdate.getCrankPosition()
end

function CrankManager.getChange()
    return playdate.getCrankChange()
end

function CrankManager.isDocked()
    return isDocked
end

function CrankManager.onCrankDocked()
    console.log("Crank docked")
end

function CrankManager.onCrankUndocked()
    console.log("Crank undocked")
end

return CrankManager
