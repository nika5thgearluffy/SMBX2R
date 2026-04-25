--[[

	From MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")

local ai = require("npcs/ai/swingingPlatform")
local syncedNPC = require("npcs/ai/syncedNPC")


local swingingPlatform = {}
local npcID = NPC_ID


local swingingPlatformSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,

	gfxoffsetx = 0,
	gfxoffsety = 10,
	
	width = 44,
	height = 44,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = true,
	harmlessthrown = true,

	notcointransformable = true,
	ignorethrownnpcs = true,
	staticdirection = true,
	luahandlesspeed = true,
	--nogliding = true,
}

npcManager.setNpcSettings(swingingPlatformSettings)
npcManager.registerHarmTypes(npcID,{},nil)


syncedNPC.register(npcID,true)

ai.registerBall(npcID)


return swingingPlatform