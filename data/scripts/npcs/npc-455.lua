local npcManager = require("npcManager")
local springLib = require("npcs/ai/springs")

local springs = {}

local npcID = NPC_ID

local regularSettings = {
	id = npcID,
	gfxoffsety=0,
	gfxheight = 32,
	gfxwidth = 32,
	width = 30,
	height = 16,
	frames = 1,
	framestyle = 1,
	nohurt=true,
	playerblock=false,
	jumphurt = true,
	nogravity = true,
	nofireball= true,
	npcblock = false,
	playerblocktop = false,
	ignorethrownnpcs = true,
	npcblocktop = false,
	grabside = false,
	noblockcollision=true,
	grabtop = false,
	noiceball= true,
	noyoshi= false,
	harmlessgrab = true,
	harmlessthrown=true,
	force = 15,
	weakforce = -0.77,
	npcforce = -0.77,
	springdropcooldown = 15
}

npcManager.setNpcSettings(regularSettings)
springLib.register(npcID, springLib.TYPE.VERTICAL)

return springs