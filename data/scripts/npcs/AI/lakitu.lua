local lakitu = {}

-- Unlike other AI files, this AI file presently does not contain much logic for the NPC's movement.
-- Instead, it provides a callback for NPCs looking to do something after being spawned by a Lakitu specifically.
-- The callback handler first returns the spawned NPC, then the lakitu.

local callbackHandlers = {}

function lakitu.registerOnPostSpawnCallback(id, func)
    callbackHandlers[id] = func
end

function lakitu.spawnNPC(lakituNPC, spawnID, x, y, speedX, speedY)
    local egg = NPC.spawn(spawnID, x, y, lakituNPC:mem(0x146, FIELD_WORD), false, true)
    egg.direction = math.abs(egg.speedX)
    egg.speedY = speedY or 0
    egg.speedX = speedX or 0
    if NPC.config[lakituNPC.id].inheritfriendly then
        egg.friendly = lakituNPC.friendly
    end
    egg:mem(0x3C, FIELD_STRING, "Spawned NPCs")
    if callbackHandlers[spawnID] then
        callbackHandlers[spawnID](egg, lakituNPC)
    end

    return egg
end

return lakitu