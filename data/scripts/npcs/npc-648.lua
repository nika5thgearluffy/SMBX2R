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
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 2,
	
	width = 32,
	height = 32,
	
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

	chasehitblocks = 0,
	knockbackhitblocks = 1
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
		[HARM_TYPE_JUMP]            = 281,
		[HARM_TYPE_FROMBELOW]       = 281,
		[HARM_TYPE_NPC]             = 281,
		[HARM_TYPE_PROJECTILE_USED] = 281,
		[HARM_TYPE_HELD]            = 281,
		[HARM_TYPE_TAIL]            = 281,
	}
)

return bully