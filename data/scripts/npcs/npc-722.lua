--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local thwomps = require("npcs/ai/thwomps")
local icicle = require("npcs/ai/icicle")

local function npcHitPOW(v, other)
	v:kill(3)
	other:kill(3)
end
thwomps.registerNPCInteraction(npcID, npcHitPOW)
icicle.registerNPCInteraction(npcID, npcHitPOW)

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 32,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = false, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	isstationary = true,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = true,
	npcblocktop = false,
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	nopowblock = false,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 1, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=true,
	grabtop=true,
	weight = 1,
	powradius = 160,
	powtype = "SMW"

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
	
	-- Various interactions
	-- ishot = true,
	-- iscold = true,
	-- durability = -1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	-- weight = 2,
	-- isstationary = true, -- gradually slows down the NPC
	-- nogliding = true, -- The NPC ignores gliding blocks (1f0)

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]={id = 312, xoffsetBack = 0, yoffsetBack = 0},
		[HARM_TYPE_NPC]={id = 312, xoffsetBack = 0, yoffsetBack = 0},
		[HARM_TYPE_PROJECTILE_USED]={id = 312, xoffsetBack = 0, yoffsetBack = 0},
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 0},
		--[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]={id = 312, xoffsetBack = 0, yoffsetBack = 0},
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]={id = 312, xoffsetBack = 0, yoffsetBack = 0},
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onPostNPCKill")
	registerEvent(sampleNPC, "onNPCPOWHit")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onNPCHarm(e, v, r, c)
	if v.id == npcID and type(c)== "NPC" then
		if not NPC.SHELL_MAP[c.id] then
			e.cancelled = true
		else
			c:kill(3)
		end
	end
end

function sampleNPC.onNPCPOWHit(eo, npc, type)
	if npc.id == npcID and type ~= Misc.powType[NPC.config[npc.id].powtype] then
		eo.cancelled = true
	end
end

function sampleNPC.onPostNPCKill(v, r)
	if v.id ~= npcID then return end
	if r == 6 or r == 9 then return end

	Misc.doPOW(NPC.config[v.id].powtype, v.x + 0.5 * v.width, v.y + 0.5 * v.height, NPC.config[v.id].powradius)
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze or v.despawnTimer <= 0 or v:mem(0x138, FIELD_WORD) ~= 0 then return end 

	if NPC.config[v.id].playerblock then
		for k,p in ipairs(Player.get()) do
			if p.speedY < 0 and p.y > v.y + v.height and Colliders.speedCollide(p, v) then
				v:kill(3)
				p:mem(0x11C, FIELD_WORD, 0)
				p.speedY = 0
			end
		end
		local padding = 12
		for k,n in NPC.iterateIntersecting(v.x - padding + v.speedX, v.y - padding + v.speedY, v.x + v.width + padding + v.speedX, v.y + v.height + padding + v.speedY) do
			if n ~= v and NPC.config[n.id].isshell and n.despawnTimer > 0 and n.isProjectile and Colliders.speedCollide(n, v) then
				v:kill(3)
			end
		end
	end

	if not v:mem(0x136, FIELD_BOOL) then return end

	if not v.data._basegame.thrown then
		v.data._basegame.thrown = true
		return
	end

	--Execute main AI. This template just jumps when it touches the ground.
	if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockUp or v:mem(0x12, FIELD_WORD) ~= 0 then
		v:kill(3)
	end
end

--Gotta return the library table!
return sampleNPC