--------------------------------------------------------------------
--          Icicle from Super Mario Maker 2 by Nintendo           --
--                    Recreated by IAmPlayer                      --
--------------------------------------------------------------------

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local iciclelib = require("npcs/ai/icicle")

local icicle = {}
local npcID = NPC_ID

local icicleSettings = {
	id = npcID,
	
	dripeffectID = 0,
	effectID = 298,
	iscold = false,
	durability = -1,
	breaksound = 4
}

iciclelib.register(npcID, icicleSettings, 1)

--Gotta return the library table!
return icicle