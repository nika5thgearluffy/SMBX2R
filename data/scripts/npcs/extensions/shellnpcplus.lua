local waterplus = {}
local npcManager = require("npcManager")
local aiextensions = require("npcs/extensions/aiextensions")

aiextensions.bind("isshell", waterplus, "onTickEndNPC")

function waterplus.onTickEndNPC(v)
    if Defines.levelFreeze then return end
    if v.despawnTimer > 0 and v:mem(0x138, FIELD_WORD) == 0 then
        if not v.data._basegame._shellInitialized then
            v.data._basegame._shellInitialized = true
            if v.data._settings.shellStartsSpinning then
                v.speedX = v.direction * Defines.projectilespeedx
                v:mem(0x136, FIELD_BOOL, true)
                SFX.play(9)
            end
        end
    else
        v.data._basegame._shellInitialized = false
    end
end

return waterplus