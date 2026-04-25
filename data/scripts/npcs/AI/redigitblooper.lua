local redigitblooper = {}

local npcManager = require("npcManager")

function redigitblooper.registerBlooper(id)
    npcManager.registerEvent(id, redigitblooper, "onTickNPC")
end

function redigitblooper.onTickNPC(v)
    if Defines.levelFreeze then return end

    local data = v.data._basegame

    local settings = v.data._settings

    if v.despawnTimer <= 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) ~= 0 then
        data.initialized = false
    end
    if not data.initialized then
        data.timer = 0
        data.initialized = true
        data.referenceY = v.y
    end

    if v.underwater then
        if data.timer == 0 then
            if not settings.chase then
                v.ai2 = -60
                if v.ai4 == 1 or (v.y > data.referenceY - settings.heightGain) then
                    data.timer = data.timer + 1
                    v.speedX = v.direction * NPC.config[v.id].speed * 4
                    v.ai2 = 999
                    data.referenceY = v.y
                end
            else
                if v.ai2 == 59 then
                    data.timer = data.timer + 1
                end
            end
        else
            data.timer = data.timer + 1
            v.ai2 = 999
            if data.timer >= settings.riseDuration - 1 then
                data.timer = 0
                v.ai2 = 1
            end
        end
    else
        data.timer = 0
    end
end

return redigitblooper