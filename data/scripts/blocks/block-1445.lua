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
}

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onCollideBlock")
end

function sampleBlock.onCollideBlock(v,n)
    if type(n) == "Player" and v:collidesWith(n) == 3 then
		n:harm()
	end
end

--Gotta return the library table!
return sampleBlock