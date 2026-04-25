local blockmanager = require("blockmanager")

local block = {}

local blockID = BLOCK_ID

--disable vanilla collision
blockmanager.setBlockSettings({
    id = blockID,
	ceilingslope=1
})


return block