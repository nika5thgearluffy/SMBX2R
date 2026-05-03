local configFileReader = require("configFileReader")
local npcManager = require("npcManager")
local waterleaper = require("npcs/ai/yurarinBoo")

local yurarinBoo = {}

local npcID = NPC_ID;

function yurarinBoo.onInitAPI()
	waterleaper.register(npcID)
end

local yurarinBooData = {}

yurarinBooData.config = npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 48, 
	gfxheight = 48, 
	width = 40, 
	height = 24, 
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	jumphurt = 0, 
	noblockcollision = 1,
	nofireball = 1,
	noiceball = 0,
	noyoshi = 0,
	nowaterphysics=true,
	speed=0,
	--lua only
	--death stuff
	resttime=30,
	type=waterleaper.TYPE.SECTION,
	friendlyrest = true,
	projectile = 726,
	projectilespeed = 4,
	score = 4,
})

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

return yurarinBoo;