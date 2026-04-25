--[[

	From MrDoubleA's NPC Pack

	Graphics by MatiasNTRM

]]

local npcManager = require("npcManager")
local bullyAI = require("npcs/ai/bully")

local bully = {}
local npcID = NPC_ID

local bullySettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,

	gfxoffsetx = 0,
	gfxoffsety = 2,
	
	width = 60,
	height = 54,
	
	frames = 3,
	framestyle = 1,
	framespeed = 8,
	
	speed = 1,
	score = 0,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	weight = 2,

	noticebounce = 2,
	knockbackspeed = 3.5,
	otherknockbackspeed = 8,
	knockbackfalloff = 0.1,
	chasespeed = 4,
	chaseacceleration = 0.1,
	startchasedistance = 200,
	stopchasedistance = 300,
	wanderdistance = 128,
	wanderspeed = 1.25,
	chasehitblocks = 2,
	knockbackhitblocks = 2
}

bullyAI.register(npcID, bullySettings)

npcManager.registerDefines(npcID,{NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = 282,
		[HARM_TYPE_FROMBELOW]       = 282,
		[HARM_TYPE_NPC]             = 282,
		[HARM_TYPE_PROJECTILE_USED] = 282,
		[HARM_TYPE_HELD]            = 282,
		[HARM_TYPE_TAIL]            = 282,
	}
)

return bully