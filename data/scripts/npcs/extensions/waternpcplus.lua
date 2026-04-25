local waterplus = {}
local npcManager = require("npcManager")
local aiextensions = require("npcs/extensions/aiextensions")

aiextensions.bind("iswaternpc", waterplus, "onTickEndNPC")

local function horiz(v)
    if v.underwater then
        if v.ai5 == 0 then
            v.ai5 = v.y
        end
        --Misc.dialog(v.ai1, v.ai2, v.ai3, v.ai4, v.ai5)
        if v.collidesBlockLeft or v.collidesBlockRight then
            v.direction = -v.direction
        end
        v.speedX = v.direction
        v.speedY = v.ai5 - v.y
    else
        v.ai5 = 0
    end
end

local function vert(v)
    if v.underwater then
        if v.ai5 == 0 then 
            v.ai5 = v.x
        end

        if v.collidesBlockUp then
            v:mem(0xD8, FIELD_FLOAT, 1)
        end
        if v.collidesBlockBottom then
            v:mem(0xD8, FIELD_FLOAT, -1)
        end
        v.x = v.ai5
        v.speedY = NPC.config[v.id].speed * v:mem(0xD8, FIELD_FLOAT)
    else
        v.ai5 = 0
    end
end

local function bounce(v)
    if v.underwater then
        v.speedY = -4
        v.ai5 = 1
    elseif v.ai5 > 0 then
        v.ai5 = v.ai5 - 1
        v.speedY = -4
        if v.ai5 == 0 then
            v.ai4 = v.ai4 + 1
            if v.ai4 == 5 then
                v.ai4 = 0
                v.speedY = -8
            end
        end
    end
end

local exfuncs = {
    [5] = horiz,
    [6] = vert,
    [7] = bounce
}

function waterplus.onTickEndNPC(v)
    if Defines.levelFreeze then return end
    if v.despawnTimer > 0 and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x136, FIELD_BOOL) == false and exfuncs[v.ai1] ~= nil then
        exfuncs[v.ai1](v)
    end
end

return waterplus