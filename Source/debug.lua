console = {}


local isDebug = false

function console.active()
    isDebug = true
end

function console.deactive()
    isDebug = false
end

function console.isDebug()
    return isDebug
end

function console.log(...)
    if isDebug then
        local args = { ... }
        local debugString = ""
        for i, v in ipairs(args) do
            debugString = debugString .. tostring(v) .. "\t"
        end
        print(debugString)
    end
end
