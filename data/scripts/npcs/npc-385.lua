local npcManager = require("npcManager")
local torches = require("npcs/ai/torches")

local torchVert = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local torchVertSettings = {
	id = npcID, 
	gfxwidth = 32, 
	gfxheight = 88, 
	width = 28, 
	height = 80, 
	frames = 2,
	framespeed = 2, 
	framestyle = 1,
	score = 0,
	nogravity = 1,
	ignorethrownnpcs = true,
	staticdirection = true,
	noblockcollision = 1,
	gfxoffsety = 8,
	noyoshi = 1,
	jumphurt = 1,
	-- Light library stuff
	lightradius = 64,
	lightbrightness = 2,
	lightcolor = Color.orange,
	ishot = true,
	durability = -1,
	duration = 162,
	framesets = 4
}

npcManager.setNpcSettings(torchVertSettings);

function torchVert.onInitAPI()
    torches.register(npcID)
end

return torchVert;