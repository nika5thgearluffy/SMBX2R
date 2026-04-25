--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local flameChompTail = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local flameChompTailSettings = {
	id = npcID,
	gfxheight = 16,
	gfxwidth = 16,
	width = 16,
	height = 16,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 4,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,
	
	nogliding=true,
	ignorethrownnpcs = true,
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	grabside=false,
	grabtop=false,
	ishot=true,
	durability=-1
}

--Applies NPC settings
npcManager.setNpcSettings(flameChompTailSettings)

--Register events
function flameChompTail.onInitAPI()
	npcManager.registerEvent(npcID, flameChompTail, "onDrawNPC")
end

function flameChompTail.onDrawNPC(v)
	--If despawned
	if v.despawnTimer <= 0 then return end

	if v.data._basegame.parent == nil or not v.data._basegame.parent.isValid then
		v.friendly = true
	end

	local p = -45.1
	if NPC.config[v.id].foreground then
		p = -15.1
	end
	
	npcutils.drawNPC(v,{priority = p})
	npcutils.hideNPC(v)
end

--Gotta return the library table!
return flameChompTail