local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}


blockmanager.setBlockSettings({
	id = blockID,
	customhurt = true,
})

function block.onCollideBlock(v,n)
	if(n.__type == "Player") then
		if n.forcedState == FORCEDSTATE_NONE and n.invincibilityTimer == 0 and not n:isDead() and not Defines.cheat_donthurtme then
			n:kill()
		end
	end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

return block