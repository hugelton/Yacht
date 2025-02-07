import "CoreLibs/graphics"
import "CoreLibs/object"
local gfx <const> = playdate.graphics

assets = {}




assets.backgroundImages = {}

assets.fonts = {}


assets.filterTypes = {}
assets.filterTypes = playdate.graphics.imagetable.new("Images/synth_filter")


assets.mode          = {}
assets.mode          = playdate.graphics.imagetable.new("Images/mode")

assets.vknob         = {}
assets.vknob         = playdate.graphics.imagetable.new("Images/vknob")

assets.segments      = {}
assets.segments      = playdate.graphics.imagetable.new("Images/segments")

assets.segmentsSmall = {}
assets.segmentsSmall = playdate.graphics.imagetable.new("Images/segmentsSmall")

assets.loop          = {}
assets.loop          = playdate.graphics.imagetable.new("Images/loop")

assets.synSelect     = {}
assets.synSelect     = playdate.graphics.imagetable.new("Images/synSelect")

assets.icons         = {}

assets.icons         = playdate.graphics.imagetable.new("Images/icons")

assets.solos         = {}
assets.solos         = playdate.graphics.imagetable.new("Images/solos")
assets.plays         = {}
assets.plays         = playdate.graphics.imagetable.new("Images/plays")

assets.songLoopModes = {}
assets.songLoopModes = playdate.graphics.imagetable.new("Images/songLoopModes")



assets.playdates = {}
assets.playdates = playdate.graphics.imagetable.new("Images/playdates")

assets.balloonDiv = playdate.graphics.nineSlice.new("Images/balloon_9slice", 4, 4, 56, 56)

assets.mute = {}
assets.mute = playdate.graphics.imagetable.new("Images/mute")

function assets.init()
    assets.fonts.nada = gfx.font.new("fonts/nada")
    gfx.setFont(assets.fonts.nada, playdate.graphics.font.kVariantNormal)

    assets.fonts.cavs = gfx.font.new("fonts/cavs")
    gfx.setFont(assets.fonts.cavs, playdate.graphics.font.kVariantBold)


    assets.fonts.groria = gfx.font.new("fonts/groria")
    gfx.setFont(assets.fonts.groria, playdate.graphics.font.kVariantItalic)



    playdate.setCrankSoundsDisabled(0)
    --

    assets.backgroundImages.syn = playdate.graphics.image.new("Images/syn")
    assets.backgroundImages.seq = playdate.graphics.image.new("Images/seq")
    assets.backgroundImages.seq2 = playdate.graphics.image.new("Images/seq2")
    assets.backgroundImages.patterns = playdate.graphics.image.new("Images/patterns")
    assets.backgroundImages.drums = playdate.graphics.image.new("Images/drums")
    assets.backgroundImages.mixer = playdate.graphics.image.new("Images/mixer")
    assets.backgroundImages.song = playdate.graphics.image.new("Images/song")
    assets.backgroundImages.visual = playdate.graphics.image.new("Images/Visualizer")
    assets.backgroundImages.pref = playdate.graphics.image.new("Images/pref")




    console.log("Loaded assets")
end

function assets.drawSegments(val, x, y)
    local tens = math.floor(val / 10)
    local ones = val % 10

    if tens > 0 then
        assets.segmentsSmall:drawImage(tens, x + 3, y)
        assets.segmentsSmall:drawImage(ones == 0 and 10 or ones, x + 13, y)
    else
        assets.segmentsSmall:drawImage(ones, x + 5, y)
    end
end
