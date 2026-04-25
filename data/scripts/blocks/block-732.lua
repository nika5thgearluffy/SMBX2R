local brittle = require("blocks/ai/brittle")

local blockID = BLOCK_ID

local block = {}

brittle.register(blockID, "leaf", {
	id = blockID
})

return block