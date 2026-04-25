--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local dirCannon = require("npcs/AI/directionalCannon")

--Create the library table
local singleCannon = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local settings = {
	id = npcID,
	width=64,
	height=64,
	gfxwidth=64,
	gfxheight=64,
	shotcount = 1,
	shotid = 696
}

--Custom local definitions below

dirCannon.register(npcID, settings)

--Gotta return the library table!
return singleCannon