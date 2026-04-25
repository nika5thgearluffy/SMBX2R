--[[

	Credit to Saturnyoshi for making "newplants" and creating most of the graphics used

	From MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local ai = require("npcs/ai/piranhaPlant")

local piranhaPlant = {}
local npcID = NPC_ID

local defaultFireID = 527

local piranhaPlantSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 48,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 48,
	
	frames = 4,
	framestyle = 1,
	framespeed = 4,
	
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


	jumpStartSpeed     = -6,      -- How fast the NPC moves when first jumping out of the pipe.
	jumpRisingGravity  = 0.1,     -- The gravity of the NPC while rising.
	jumpFallingGravity = 0.01,    -- The gravity of the NPC while falling.
	jumpMaxSpeed       = 1,       -- The terminal velocity of the NPC while falling.
	hideTime           = 50,      -- How long the NPC rests before coming out.
	restTime           = 3,       -- How long the NPC rests before retracting back.
	ignorePlayers      = false,   -- Whether or not the NPC can come out, even if there's a player in the way.
	
	isHorizontal   = false, -- Whether or not the NPC is horizontal.
	changeSize     = true,  -- Whether or not the NPC's hitbox and graphical size changes when moving
	becomeFriendly = true, -- Whether or not the NPC should become friendly when fully retracted.
	isJumping      = true,  -- Whether or not the NPC acts like a jumping piranha plant.


	defaultFireID = defaultFireID,  -- The NPC ID of the fire shot by the NPC. If nil or 0, no fire will be shot.
	fireSound     = 18,             -- The sound effect to play when shooting fire. If nil or 0, no sound will play.

	fireSpitFrames     = 2, -- The number of frames used while spitting a fireball.
	fireSpitFrameSpeed = 4, -- How long a single fire spitting frame lasts.
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