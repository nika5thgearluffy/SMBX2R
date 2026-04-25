local npcManager = require("npcManager")
local babyYoshis = require("npcs/ai/babyyoshis")

local purpleBabyYoshi = {}
local npcID = NPC_ID;

--baby yoshi adaptations, please define your npc config here
local settings = {
	id = npcID,
	slamdelay = 20,
	powtype = "SMW",
	powradius = 150
}

-- Settings for npc
npcManager.setNpcSettings(table.join(settings, babyYoshis.babyYoshiSettings));

-- Final setup
local function swallowFunction (v)
	Misc.doPOW(NPC.config[v.id].powtype, v.x + 0.5 * v.width, v.y + 0.5 * v.height, NPC.config[v.id].powradius)
end

function purpleBabyYoshi.onInitAPI()
	babyYoshis.register(npcID, babyYoshis.colors.PURPLE, swallowFunction);
end

return purpleBabyYoshi;