local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("npcs/ai/chainChomp")


local chompPost = {}
local npcID = NPC_ID

local CHAIN_EFFECT_ID = 283

local chompPostSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = true,
	npcblocktop = false,
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = false,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	grabside = true,
	grabtop = true,

	notcointransformable = true,
	ignorethrownnpcs = true,
	isstationary = true,
	nowalldeath = true,

	weight = 2,


	chainEffectID = CHAIN_EFFECT_ID,

	chainSnapThreshold = 64,

	disableSpinJumpWhenHeld = true,
	setGroupWhenHeld = true,
}

npcManager.setNpcSettings(chompPostSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)


ai.registerPost(npcID)


return chompPost