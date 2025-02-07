local gfx <const> = playdate.graphics

local sail = sail

Mixer = {}


Mixer.VFader = {}
Mixer.VFader.__index = Mixer.VFader
Mixer.cursor = {}
Mixer.cursor.x = 1
Mixer.cursor.y = 1
Mixer.cursor.w = 1
Mixer.cursor.h = 1

function Mixer.VFader.new(x, y, value, minValue, maxValue, steps)
    local self = setmetatable({}, Mixer.VFader)
    self.x, self.y = x, y
    self.value = value or 0.7
    self.minValue, self.maxValue = minValue or 0, maxValue or 1
    self.steps = steps or 11
    self.width, self.height = 20, 90
    self.handlePosition = self:valueToPosition(self.value)
    return self
end

function Mixer.VFader:valueToPosition(value)
    return self.y + self.height - (value - self.minValue) / (self.maxValue - self.minValue) * self.height
end

function Mixer.VFader:positionToValue(position)
    local normalizedPosition = (self.y + self.height - position) / self.height
    local stepSize = (self.maxValue - self.minValue) / (self.steps - 1)
    return math.floor(normalizedPosition * (self.steps - 1) + 0.5) * stepSize + self.minValue
end

function Mixer.VFader:draw(isSelected)
    gfx.fillRoundRect(self.x + 2, self.handlePosition - 2, self.width - 4, 8, 2)

    if isSelected then
        Mixer.cursor.x = self.x - 2
        Mixer.cursor.y = self.y - 2
        Mixer.cursor.w = self.width + 4
        Mixer.cursor.h = self.height + 10
    end
end

Mixer.Knob = {}
Mixer.Knob.__index = Mixer.Knob

function Mixer.Knob.new(x, y, value, ...)
    local self = setmetatable({}, Mixer.Knob)
    self.x, self.y = x, y
    self.value = value or 0
    self.radius = 8
    self.isEcho = ...
    return self
end

function Mixer.Knob:draw(isSelected)
    local angle = math.pi * (1.5 + self.value / 1.551724138)

    if self.isEcho then
        angle = math.pi * (.9 + (self.value * 2) / 1.551724138)
    end
    local endX = self.x + math.cos(angle) * self.radius
    local endY = self.y + math.sin(angle) * self.radius
    gfx.drawLine(self.x, self.y, endX, endY)
    if isSelected then
        Mixer.cursor.x = self.x - self.radius - 2
        Mixer.cursor.y = self.y - self.radius - 2
        Mixer.cursor.w = (self.radius + 2) * 2
        Mixer.cursor.h = (self.radius + 2) * 2
    end
end

Mixer.MuteButton = {}
Mixer.MuteButton.__index = Mixer.MuteButton

function Mixer.MuteButton.new(x, y)
    local self = setmetatable({}, Mixer.MuteButton)
    self.x, self.y = x, y
    self.width, self.height = 16, 16
    self.isActive = false
    return self
end

function Mixer.MuteButton:draw(isSelected)
    if self.isActive then
        assets.mute:drawImage(2, self.x, self.y)
    else
        assets.mute:drawImage(1, self.x, self.y)
    end


    if isSelected then
        Mixer.cursor.x = self.x - 2
        Mixer.cursor.y = self.y - 2
        Mixer.cursor.w = self.width + 4
        Mixer.cursor.h = self.height + 4
    end
end

Mixer.tracks = {}
Mixer.cursorX = 1
Mixer.cursorY = 1

function Mixer.load()
    Mixer.cursorX = 1
    Mixer.cursorY = 1


    Mixer.tracks = {}
    local trackCount = 9
    local startX = 8
    local spacing = 38

    local trackNames = { "synth1", "synth2", "synth3", "drum1", "drum2", "drum3", "drum4", "drum5", "drum6" }
    local displayNames = { "*Syn1*", "*Syn2*", "*Syn3*", "*Kick*", "*Snare*", "*Close*", "*Open*", "*Prc1*", "*Prc2*" }

    for i = 1, trackCount do
        local x = startX + (i - 1) * spacing
        local trackName = trackNames[i]
        local displayName = displayNames[i]

        if sail.mixer[trackName] then
            local track = {
                name = trackName,
                label = displayName,
                fader = Mixer.VFader.new(x + 10, 70, sail.mixer[trackName].volume, 0, 1, 11),
                pan = Mixer.Knob.new(x + 20, 185, sail.mixer[trackName].pan, false),
                mute = Mixer.MuteButton.new(x + 12, 210)
            }
            track.mute.isActive = sail.mixer[trackName].mute
            table.insert(Mixer.tracks, track)
        end
    end


    for channelName, channelData in pairs(sail.mixer) do
        if type(channelData) == "table" then
            Sounds.setChannel(channelName, "volume", channelData.volume)
            Sounds.setChannel(channelName, "mute", channelData.mute)
            Sounds.setChannel(channelName, "pan", channelData.pan)
        end
    end
end

function Mixer.init()
    local trackCount = 9
    local startX = 8
    local spacing = 38

    local trackNames = { "synth1", "synth2", "synth3", "drum1", "drum2", "drum3", "drum4", "drum5", "drum6" }
    local displayNames = { "*Syn1*", "*Syn2*", "*Syn3*", "*Kick*", "*Snare*", "*Close*", "*Open*", "*Prc1*", "*Prc2*" }

    for i = 1, trackCount do
        local x = startX + (i - 1) * spacing
        local trackName = trackNames[i]
        local displayName = displayNames[i]

        if sail.mixer[trackName] then
            local track = {
                name = trackName,
                label = displayName,
                fader = Mixer.VFader.new(x + 10, 70, sail.mixer[trackName].volume, 0, 1, 11),
                pan = Mixer.Knob.new(x + 20, 185, sail.mixer[trackName].pan, false),
                mute = Mixer.MuteButton.new(x + 12, 210)
            }
            track.mute.isActive = sail.mixer[trackName].mute
            table.insert(Mixer.tracks, track)
        else
            console.log("Warning: No mixer data for track " .. trackName)
        end
    end
end

function Mixer.updateSounds()
    local trackNames = { "synth1", "synth2", "synth3", "drum1", "drum2", "drum3", "drum4", "drum5", "drum6" }
    for i, track in ipairs(Mixer.tracks) do
        local trackName = trackNames[i]
        Sounds.setChannel(trackName, "volume", sail.mixer[trackName].volume)
        Sounds.setChannel(trackName, "pan", sail.mixer[trackName].pan)
        Sounds.setChannel(trackName, "mute", sail.mixer[trackName].mute)
    end
end

function Mixer.draw()
    for i, track in ipairs(Mixer.tracks) do
        track.fader:draw(Mixer.cursorX == i and Mixer.cursorY == 1)
        track.pan:draw(Mixer.cursorX == i and Mixer.cursorY == 2)
        track.mute:draw(Mixer.cursorX == i and Mixer.cursorY == 3)
        gfx.drawTextAligned(track.label, track.fader.x + 15, 45, kTextAlignment.center)
    end

    Mixer.updateSounds()
end

function Mixer.handleInput()
    if KeyManager.justReleased(KeyManager.keys.left) then
        Mixer.cursorX = math.max(1, Mixer.cursorX - 1)
    elseif KeyManager.justReleased(KeyManager.keys.right) then
        Mixer.cursorX = math.min(#Mixer.tracks, Mixer.cursorX + 1)
    end

    if KeyManager.justReleased(KeyManager.keys.up) then
        Mixer.cursorY = math.max(1, Mixer.cursorY - 1)
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        Mixer.cursorY = math.min(4, Mixer.cursorY + 1)
    end

    local currentTrack = Mixer.tracks[Mixer.cursorX]
    local trackName = currentTrack.name



    if Mixer.cursorY == 1 then -- Fader
        if KeyManager.justComboReleased("upA") or KeyManager.justComboReleased("downA") or CrankManager.forwardTick or CrankManager.backwardTick then
            sail.mixer[trackName].volume = currentTrack.fader.value
        end
    elseif Mixer.cursorY == 2 then -- Pan
        if KeyManager.justComboReleased("leftA") or KeyManager.justComboReleased("rightA") or CrankManager.forwardTick or CrankManager.backwardTick then
            sail.mixer[trackName].pan = currentTrack.pan.value
        end
    elseif Mixer.cursorY == 3 then -- Mute
        if KeyManager.justReleased(KeyManager.keys.a) then
            currentTrack.mute.isActive = not currentTrack.mute.isActive
            sail.mixer[trackName].mute = currentTrack.mute.isActive
        end
    end

    if KeyManager.justComboReleased("upA") then
        if Mixer.cursorY == 1 then
            currentTrack.fader.value = math.min(1, currentTrack.fader.value + 0.05)
            currentTrack.fader.handlePosition = currentTrack.fader:valueToPosition(currentTrack.fader.value)
        elseif Mixer.cursorY == 2 then
            currentTrack.pan.value = math.min(1, currentTrack.pan.value + 0.1)
        end
    elseif KeyManager.justComboReleased("downA") then
        if Mixer.cursorY == 1 then
            currentTrack.fader.value = math.max(0, currentTrack.fader.value - 0.05)
            currentTrack.fader.handlePosition = currentTrack.fader:valueToPosition(currentTrack.fader.value)
        elseif Mixer.cursorY == 2 then
            currentTrack.pan.value = math.max(-1, currentTrack.pan.value - 0.1)
        end
    end



    if CrankManager.forwardTick then
        if Mixer.cursorY == 1 then
            currentTrack.fader.value = math.min(1, currentTrack.fader.value + 0.05)
            currentTrack.fader.handlePosition = currentTrack.fader:valueToPosition(currentTrack.fader.value)
        elseif Mixer.cursorY == 2 then
            currentTrack.pan.value = math.min(1, currentTrack.pan.value + 0.1)
        end
    elseif CrankManager.backwardTick then
        if Mixer.cursorY == 1 then
            currentTrack.fader.value = math.max(0, currentTrack.fader.value - 0.05)
            currentTrack.fader.handlePosition = currentTrack.fader:valueToPosition(currentTrack.fader.value)
        elseif Mixer.cursorY == 2 then
            currentTrack.pan.value = math.max(-1, currentTrack.pan.value - 0.1)
        end
    end
end

return Mixer
