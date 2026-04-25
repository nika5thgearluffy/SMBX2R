local waterplus = {}
local npcManager = require("npcManager")
local aiextensions = require("npcs/extensions/aiextensions")
local npcutils = require("npcs/npcutils")

aiextensions.bind("isstationary", waterplus, "onTickEndNPC", "onItemPhysicsNPC")
aiextensions.bind("nowalldeath", waterplus, "onTickEndNPC", "onWallThrownNPC")
aiextensions.bind("slippery", waterplus, "onTickNPC", "onSlipperyNPC")

function waterplus.onItemPhysicsNPC(v)
    if Defines.levelFreeze then return end
    npcutils.applyStationary(v)
end

function waterplus.onWallThrownNPC(v)
    if Defines.levelFreeze or v.despawnTimer <= 0 then return end
    npcutils.preventWallDeath(v)
end

function waterplus.onSlipperyNPC(v)
    if v.despawnTimer <= 0 then return end
    for k,p in ipairs(Player.get()) do
        if p.standingNPC == v and v.speedX == 0 then -- slippery if the npc is moving sideways is HYPER BROKEN!!
            p:mem(0x0A, FIELD_BOOL, true)
        end
    end
end


return waterplus