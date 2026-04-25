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
	
	effectID = 296,
	iscold = true,
	slippery = true,
	durability = -1,
}

iciclelib.register(npcID, icicleSettings, 0)

--Gotta return the library table!
return icicle