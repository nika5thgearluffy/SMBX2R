--[[

	From MrDoubleA's NPC Pack
	Credit to Novarender for vastly improving the font used for character names

]]

local npcManager = require("npcManager")
local ai = require("npcs/ai/goaltape")


local goalTape = {}
local npcID = NPC_ID



local goalTapeSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 16,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 48,
	height = 16,
	
	frames = 1,
	framestyle = 1,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	nowalldeath = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
    harmlessthrown = true,

	ignorethrownnpcs = true,
    
    notcointransformable = true,

    
    movementSpeed = 2, -- How fast the goal tape moves up and down.
    requiredCollisionType = ai.COLLISION_TYPE_TOUCH_ABOVE, -- Where the player must touch the goal tape to activate it. It can be 0 to act like SMM, it can be 1 to act like SMM2, or it can be 2 to act like SMW.

    doDarken = true,    -- Whether or not everything is darkened during the exit animation.
    doIrisOut = true,   -- Whether or not there's an iris out effect to exit the level.
	pausesGame = false, -- Where or not the entire game is paused during the exit.
	isOrb = false,      -- Whether or not the NPC is a ? Orb.

	poseTime = 464,      -- The frame on which the pose is done.
	startExitTime = 560, -- The frame on which the iris out starts.

	useVictoryPoses = true, -- If true, the player will use a victory pose if applicable.

    mainSFX = SFX.open(Misc.resolveSoundFile("goalTape_main.ogg")),       -- The sound played when hitting the goal tape. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.
    irisOutSFX = SFX.open(Misc.resolveSoundFile("goalTape_irisOut.ogg")), -- The sound used for the iris out. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.

    heldNPCsTransform = true, -- Whether or not an NPC being held will transform when hitting the goal.
    
    -- Results
    displayCharacterName = true, -- Whether or not the character's name is displayed with the results.
    displayCourseClear = true,   -- Whether or not the "course clear" text is displayed with the results.
    doTimerCountdown = true,     -- Whether or not to do the countdown of the timer, if the timer is enabled.

	winType = LEVEL_WIN_TYPE_TAPE,
    timerScoreMultiplier = 50, -- How many points each timer second is worth.
    timerCountdownSpeed = 128, -- How many frames it takes to count down the timer.

    -- The sound effects using for the timer countdown. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.
    countdownStartSFX = SFX.open(Misc.resolveSoundFile("goalTape_countdown_start.wav")),
    countdownLoopSFX  = SFX.open(Misc.resolveSoundFile("goalTape_countdown_loop.wav")),
    countdownEndSFX   = SFX.open(Misc.resolveSoundFile("goalTape_countdown_end.wav")),
}

npcManager.setNpcSettings(goalTapeSettings)
npcManager.registerDefines(npcID,{NPC.UNHITTABLE})
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})


ai.register(npcID)


return goalTape