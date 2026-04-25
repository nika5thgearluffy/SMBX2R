local npcManager = require("npcManager")

local friendlies = {}

friendlies.ids = {}

function friendlies.register(id)
    friendlies.ids[id] = true
end

return friendlies