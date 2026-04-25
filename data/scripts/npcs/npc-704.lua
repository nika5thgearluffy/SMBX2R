--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local fireChomp = require("npcs/ai/fireChomp")

--Create the library table
local flameChomp = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local flameChompSettings = {
	id = npcID,
    explodetime = 80,
    shootframes = 2,
    idleframes = 1,
    explodeframes = 2,

    tailid = 705,
	nogliding=true,
    projectileid = 706,
    closeness = 8,
    acceleration = 0.0648,
    maxspeed = 2,
    tailoffsetx = 0,
    tailoffsety = 0,
    taileffectid = 300
}

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=299,
		[HARM_TYPE_NPC]=299,
		[HARM_TYPE_PROJECTILE_USED]=299,
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=299,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

fireChomp.register(npcID, flameChompSettings)

--Gotta return the library table!
return flameChomp