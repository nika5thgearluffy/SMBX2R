--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local pop = require("npcs/ai/SMLPop")

--Create the library table
local marinePop = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local marinePopSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 86,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 52,
	height = 30,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	ignorethrownnpcs = true,
	notcointransformable = true,
	
	--[[***********
	CUSTOM SETTINGS
	**************]]
	
	--Change this to have the NPC be able to change direction while controlling it
	staticdirection = true,
	--Change this to change the speed of the vehicle
	movementSpeed = 4.5,
	--If false, the player can't exit the vehicle **WARNING** may lead to soft lock if the player needs to exit to progress.
	exitable = true,
	--Change this to change the projectile it shoots
	projectile = npcID - 1,
	--Change this to alter the delay between projectile shots
	shootDelay = 20,
	--This is the sound effect that plays when the vehicle shoots a projectile. If you want a default sound just replace it with a number
	shotSound = "sound/extended/sml1-shoot.ogg",
	--An offset for where the projectile should be spawned. Please change anything you would like for the Y offset here, and the X offset below
	spawnOffsetX = {},
	spawnOffsetY = 6,
	--An offset to position the player, more intended for large characters and costumes
	popOffsetX = 0,
	popOffsetY = 0,
}

marinePopSettings.spawnOffsetX[-1] = (0)
marinePopSettings.spawnOffsetX[1] = (marinePopSettings.width - 26)

local config = npcManager.setNpcSettings(marinePopSettings)

pop.register(npcID)

--Gotta return the library table!
return marinePop