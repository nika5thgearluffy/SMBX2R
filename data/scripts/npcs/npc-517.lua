--[[

	Credit to Saturnyoshi for making "newplants" and creating most of the graphics used

	From MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local ai = require("npcs/ai/piranhaPlant")

local piranhaPlant = {}
local npcID = NPC_ID

local defaultFireID = 511

local piranhaPlantSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 64,
	height = 32,
	
	frames = 4,
	framestyle = 1,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,


	movementSpeed = 1.5,   -- How fast the NPC moves when coming out or retracting back.
	hideTime      = 50,    -- How long the NPC rests before coming out.
	restTime      = 100,   -- How long the NPC rests before retracting back.
	ignorePlayers = false, -- Whether or not the NPC can come out, even if there's a player in the way.

	isHorizontal   = true, -- Whether or not the NPC is horizontal.
	changeSize     = true, -- Whether or not the NPC's hitbox and graphical size changes when moving.
	becomeFriendly = true, -- Whether or not the NPC should become friendly when fully retracted.
	isVenusFireTrap = true, -- Whether or not this NPC will attempt to look at a nearby player.

	defaultFireID = defaultFireID,  -- The NPC ID of the fire shot by the NPC. If nil or 0, no fire will be shot.
	fireSound     = 18,             -- The sound effect to play when shooting fire. If nil or 0, no sound will play.
}

npcManager.setNpcSettings(piranhaPlantSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]            = 10,
		[HARM_TYPE_FROMBELOW]       = 10,
		[HARM_TYPE_NPC]             = 10,
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_HELD]            = 10,
		[HARM_TYPE_TAIL]            = 10,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

ai.registerPlant(npcID)

return piranhaPlant