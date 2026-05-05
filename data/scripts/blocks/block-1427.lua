--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID

--Defines Block config for our Block. You can remove superfluous definitions.
local sampleBlockSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change
	passthrough = true,
	popIDs = {736, 738}
}

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onIntersectBlock")
end

function sampleBlock.onIntersectBlock(v,n)
    if type(n) == "Player" then
		for _,npc in ipairs(NPC.get(Block.config[v.id].popIDs)) do
			NPC.config[npc.id].exitable = true
			npc.ai5 = 1
			npc.friendly = true
		end
	end
end

--Gotta return the library table!
return sampleBlock