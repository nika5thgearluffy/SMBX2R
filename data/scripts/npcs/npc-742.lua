local npcManager = require("npcManager")
local rebounder = require("npcs/ai/rebounder");

local diagonals = {}
local npcID = NPC_ID

npcManager.setNpcSettings({id = npcID,
				  gfxheight = 40, 
				  gfxwidth = 40, 
				  width = 40, 
				  height = 40,
				  frames = 4,
				  framestyle = 0,
				  framespeed = 6,
				  nogravity=1,
				  spinjumpsafe=false,
				  jumphurt = 1,
				  nofireball=1,
				  noiceball=1,
				  grabside=0,
				  grabtop=0,
				  noyoshi=1,
				  playerblock=0})

rebounder.register(npcID)
return diagonals