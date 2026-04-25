--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local solidBall = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local solidBallSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 24,
	gfxwidth = 24,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 20,
	height = 20	,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = true,
	npcblocktop = true,
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,
}

npcManager.registerHarmTypes(npcID,
	{
		-- HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		-- [HARM_TYPE_JUMP]=292,
		--[HARM_TYPE_FROMBELOW]=751,
		[HARM_TYPE_NPC]=292,
		[HARM_TYPE_PROJECTILE_USED]=292,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=292,
		[HARM_TYPE_TAIL]=292,
		-- [HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Applies NPC settings
npcManager.setNpcSettings(solidBallSettings)

--Custom local definitions below

function solidBall.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	if v.despawnTimer > 0 and v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 then
		if v.speedX == 0 and v.speedY == 0 then
			v.speedX = NPC.config[v.id].speed * v.direction
		end
	end
end

npcManager.registerEvent(npcID, solidBall, "onTickEndNPC")

--Gotta return the library table!
return solidBall