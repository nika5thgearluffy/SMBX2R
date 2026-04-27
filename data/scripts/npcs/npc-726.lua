--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxheight = 28,
	gfxwidth = 28,
	width = 28,
	height = 28,
	frames = 2,
	framestyle = 0,
	framespeed = 8, 
	speed = 1,
	score = 0,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,
	ignorethrownnpcs = true,

	grabside=false,
	grabtop=false,
	
--Emits light if the Darkness feature is active:
	lightradius = 30,
	lightbrightness = 2,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	lightcolor = Color.yellow,
	ishot=true,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Gotta return the library table!
return sampleNPC