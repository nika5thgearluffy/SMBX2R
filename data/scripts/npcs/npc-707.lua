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
	frames = 3,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	jumphurt = true,
	spinjumpsafe = true,
	nogliding = true,
    idletime = -1,
    explodetime = 80,
    shootframes = 0,
    idleframes = 1,
    explodeframes = 2,

    tailid = 705,
    projectileid = 706,
    closeness = 8,
    acceleration = 0.0448,
    maxspeed = 2,
    tailoffsetx = 0,
    tailoffsety = 0,
    taileffectid = 300
}

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD
	}, 
	{
		[HARM_TYPE_PROJECTILE_USED]=303,
		[HARM_TYPE_HELD]=10
	}
);

fireChomp.register(npcID, flameChompSettings)

--Gotta return the library table!
return flameChomp