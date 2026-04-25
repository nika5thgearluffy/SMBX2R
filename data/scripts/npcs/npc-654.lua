local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("npcs/ai/chainChomp")


local chomp = {}
local npcID = NPC_ID

local CHAIN_EFFECT_ID = 283
local DEATH_EFFECT_ID = 284

local chompSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	staticdirection = true,


	looseJumpSpeedX = 2,
	looseJumpSpeedY = -5.5,

	chainedJumpSpeedX = 1.5,
	chainedJumpSpeedY = -3,
	
	escapedSpeedX = 7,
	escapedSpeedY = -6.5,

	underwaterSpeedX = 1.2,
	underwaterFloatSpeed = 1,
	underwaterFloatTime = 16,

	deceleration = 0.05,

	patrolTime = 128,
	prepareTime = 32,
	lungeTime = 64,

	lungeMinRandomAngle = -35,
	lungeMaxRandomAngle = -10,
	lungeTargetExtraRadius = 32,
	lungeSpeed = 12,

	returnGravityMultiplier = 1,
	returnSpeedPerBlock = 0.8,

	targetPlayersNormally = true,
	targetEnemiesNormally = false,
	destroyBlocksNormally = true,
	eatEnemiesNormally = false,

	targetPlayersFriendly = false,
	targetEnemiesFriendly = true,
	destroyBlocksFriendly = true,
	eatEnemiesFriendly = true,


	chainEffectID = CHAIN_EFFECT_ID,
	chainCount = 4,
	chainTimeDifference = 8,
}

npcManager.setNpcSettings(chompSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = DEATH_EFFECT_ID,
		[HARM_TYPE_FROMBELOW]       = DEATH_EFFECT_ID,
		[HARM_TYPE_NPC]             = DEATH_EFFECT_ID,
		[HARM_TYPE_PROJECTILE_USED] = DEATH_EFFECT_ID,
		[HARM_TYPE_HELD]            = DEATH_EFFECT_ID,
		[HARM_TYPE_TAIL]            = DEATH_EFFECT_ID,
		[HARM_TYPE_SPINJUMP]        = DEATH_EFFECT_ID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)


ai.registerChomp(npcID)


return chomp