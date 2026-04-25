local npcManager = require("npcManager")
local springLib = require("npcs/ai/springs")

local springs = {}

local npcID = NPC_ID

local sideSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 16,
	height = 30,
	frames = 1,
	framestyle = 1,
	nohurt=-1,
	playerblock=false,
	jumphurt = true,
	nogravity = true,
	nofireball= true,
	npcblock = false,
	playerblocktop = false,
	noblockcollision = true,
	ignorethrownnpcs = true,
	npcblocktop = false,
	grabside = false,
	grabtop = false,
	noiceball= true,
	noyoshi= true,
	harmlessgrab = true,
	harmlessthrown=true,
	force = 4,
	weakforce = -0.77,
	npcforce = -0.77,
	usedirectiontobounce = true
}

npcManager.setNpcSettings(sideSettings)
springLib.register(npcID, springLib.TYPE.SIDE)

return springs