local npcManager = require("npcManager")
local burner = require("npcs/ai/burner")

local burnerTop = {}
local npcID = NPC_ID

local burnerTopSettings = {
	id = npcID,

	flames = 4
}

burner.registerBurner(npcID, burnerTopSettings)

--Gotta return the library table!
return burnerTop