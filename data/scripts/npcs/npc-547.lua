local npcManager = require("npcManager")
local burnerFire = require("npcs/ai/burner")

local fire = {}
local npcID = NPC_ID

local fireSettings = {
	id = npcID,
	gfxheight = 94,
	gfxwidth = 28,
	width = 24,
	height = 88,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 2,
	framestyle = 0,
	framespeed = 2,
	speed = 1,

	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	
    ishot = true,
    durability = -1,
	
	lightradius = 64,
	lightbrightness = 1,
	lightcolor = Color.orange,
	framesets = 4
}

local configFile = npcManager.setNpcSettings(fireSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

burnerFire.registerFire(npcID)

--Gotta return the library table!
return fire