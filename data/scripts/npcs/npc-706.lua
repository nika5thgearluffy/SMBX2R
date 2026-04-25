--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local flameChompFire = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local flameChompFireSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 16,
	width = 16,
	height = 16,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nogliding=true,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,
	
	ignorethrownnpcs = true,
	linkshieldable = true,
	lightradius=32,
	lightbrightness=1,
	lightcolor=Color.orange,

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	ishot=true,
	durability=3,
}

--Applies NPC settings
npcManager.setNpcSettings(flameChompFireSettings)

--Gotta return the library table!
return flameChompFire