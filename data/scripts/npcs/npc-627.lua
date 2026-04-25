-- Code based on the engine block cannons and their AI file (npc-535.lua, npc-536.lua, cannons.lua)

-- Vertical Egg-Plant
local eggplant = {}

local npcManager = require("npcManager")
local npcParse = require("npcParse")
local yoshieggplants = require("npcs/ai/yoshieggplant")

local npcID = NPC_ID

--*************************************************************************
--*
--*								Settings
--*
--*************************************************************************

npcManager.setNpcSettings(table.join(
	{
		id = npcID,
		gfxwidth=40,
		gfxheight=64,
		gfxoffsetx=0,
		gfxoffsety=16,
	},
	yoshieggplants.eggplantSharedSettings
))

--*************************************************************************
--*
--*								Event Handlers
--*
--*************************************************************************

npcManager.registerEvent(npcID, yoshieggplants, "onStartNPC", "onStartPlant")
npcManager.registerEvent(npcID, eggplant, "onTickNPC", "onTickPlant")
npcManager.registerEvent(npcID, eggplant, "onTickEndNPC", "onTickEndPlant")
npcManager.registerEvent(npcID, yoshieggplants, "onDrawNPC", "onDrawPlant")

function eggplant.onInitAPI()
	yoshieggplants.register(npcID, false, false, 305);
end

function eggplant:onTickPlant()
	yoshieggplants.onTickPlant(self)
end
function eggplant:onTickEndPlant()
	yoshieggplants.onTickEndPlant(self)
end


return eggplant