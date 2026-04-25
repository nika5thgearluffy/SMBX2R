local blockmanager = require("blockmanager")
local glidingAI = require("blocks/ai/glidingblock")

local table_insert = table.insert

local blockID = BLOCK_ID

local onef0 = {}

--disable vanilla collision
blockmanager.setBlockSettings({
    id = blockID,
    passthrough = true,
	ediblebyvine = true, -- edible by mutant vine
})

glidingAI.register(blockID)

return onef0