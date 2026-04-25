--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local cannonBall = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local cannonBallSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 24,
	gfxwidth = 24,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 24,
	height = 24	,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 16, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
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

	waittimer = 10,
	explosiontype = 3
}

--Applies NPC settings
npcManager.setNpcSettings(cannonBallSettings)

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
		--HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=291,
		--[HARM_TYPE_FROMBELOW]=751,
		[HARM_TYPE_NPC]=291,
		[HARM_TYPE_PROJECTILE_USED]=291,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=291,
		[HARM_TYPE_TAIL]=291,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


local function overlappingsolid(v)
	-- if there are no blocks overlapping
	local blocks = Colliders.getColliding{a = v,b = Block.SOLID .. Block.PLAYER,btype = Colliders.BLOCK,collisionGroup = v.collisionGroup}
	if #blocks == 0 then
		-- check for npcs overlapping
		for _, hit in ipairs(Colliders.getColliding{a = v, b = NPC.ALL, btype = Colliders.NPC,collisionGroup = v.collisionGroup}) do
			-- only care about npcs flagged as npcblock
			if NPC.config[hit.id].npcblock then
				-- overlapping an npc
				return true
			end
		end
	else
		-- overlapping a block
		return true
	end
	-- overlapping nothing
	return false
end

--Register events
function cannonBall.onInitAPI()
	npcManager.registerEvent(npcID, cannonBall, "onTickEndNPC")
	--npcManager.registerEvent(npcID, cannonBall, "onDrawNPC")
	--registerEvent(cannonBall, "onNPCKill")
end

function cannonBall.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	if v.despawnTimer > 0 and v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 then
		if v.speedX == 0 and v.speedY == 0 then
			v.speedX = NPC.config[v.id].speed * v.direction
		end

		
		local data = v.data._basegame
		
		--If despawned
		if v.despawnTimer <= 0 then
			data.waitTimer = NPC.config[v.id].waittimer
			v.noblockcollision = true
			return
		end

		--Depending on the NPC, these checks must be handled differently
		if v:mem(0x12C, FIELD_WORD) ~= 0   --Grabbed
		or v:mem(0x136, FIELD_BOOL)        --Thrown
		or v:mem(0x138, FIELD_WORD) > 0    --Contained within
		then
			return
		end

		if data.waitTimer == nil then
			data.waitTimer = NPC.config[v.id].waittimer
		end

		data.waitTimer = data.waitTimer - 1
		if data.waitTimer <= 0 then
			if v.noblockcollision then
				-- disable noblockcollision when we stop colliding with stuff
				if not overlappingsolid(v) then
					-- nothing was overlapping, enable collision
					v.noblockcollision = false
				else
					-- check again in a few frames
					data.waitTimer = 5
				end
			end
		else
			v.noblockcollision = true
		end

		if data.waitTimer <= 0 then
			if v.collidesBlockBottom or v.collidesBlockRight or v.collidesBlockUp or v.collidesBlockBottom or v:mem(0x120, FIELD_BOOL) then
				v:kill(HARM_TYPE_OFFSCREEN)
				Explosion.spawn(v.x+v.width/2, v.y+v.height/2, NPC.config[v.id].explosiontype)
			end
			
			-- if v.friendly then
			-- 	if #Colliders.getColliding{a = Colliders.getSpeedHitbox(v), b = NPC.HITTABLE, btype = Colliders.NPC, filter = Colliders.FILTER_COL_NPC_DEF} > 0 then
			-- 		Explosion.spawn(v.x+v.width/2, v.y+v.height/2, 3)
			-- 		v:kill(HARM_TYPE_NPC)
			-- 	end
			-- end
		end
	end
end

--Gotta return the library table!
return cannonBall