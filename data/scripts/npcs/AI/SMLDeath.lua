local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")

local npc = {}

function effectconfig.onTick.TICK_SML(v)
	v.speedX = 2 * -v.direction
end

return npc