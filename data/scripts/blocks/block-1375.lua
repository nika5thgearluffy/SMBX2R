local blockManager = require("blockManager")

local ai = require("blocks/ai/bombableblock")

local sampleBlock = {}
local blockID = BLOCK_ID


local bombableBlock = {
	id = blockID,
	
	frames = 1,
	framespeed = 8,

	smashable = 0,
}

blockManager.setBlockSettings(bombableBlock)

ai.register(blockID)

return sampleBlock