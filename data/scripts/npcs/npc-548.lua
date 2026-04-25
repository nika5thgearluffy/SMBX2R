local npcManager = require("npcManager")
local burner = require("npcs/ai/burner")

local burnerTop = {}
local npcID = NPC_ID

local burnerTopSettings = {
	id = npcID,

	-- cooldown = 256,
	-- globalCooldown = 256,
    startwaittime = 32,
	triggerweight = 2,
	ignoreplayers = false,
	ignorenpcs = false,
	flames = 1,
	spawndelay = 32,
	stepactivated = true
}

burner.registerBurner(npcID, burnerTopSettings)

--Gotta return the library table!
return burnerTop