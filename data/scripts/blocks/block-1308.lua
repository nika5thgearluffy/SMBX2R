local blockmanager = require("blockmanager")
local sync = require("blocks/ai/synced")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	floorslope = -1,
})

sync.registerSwitchableBlock(blockID, 1)

return block