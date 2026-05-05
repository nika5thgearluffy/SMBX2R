--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local fishy = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fishySettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 46,
	height = 28,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 2,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	radius = 64,
}

--Applies NPC settings
npcManager.setNpcSettings(fishySettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=321,
		[HARM_TYPE_PROJECTILE_USED]=321,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=321,
		[HARM_TYPE_TAIL]=321,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_SWIM = 0
local STATE_MOVE = 1

--Register events
function fishy.onInitAPI()
	npcManager.registerEvent(npcID, fishy, "onTickEndNPC")
end

function fishy.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.attackTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.attackTimer = data.attackTimer or 0
		npcutils.faceNearestPlayer(v)
		data.radius = fishySettings.radius or 64
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if data.state == STATE_SWIM then
		v.speedX = 4.5 * v.direction
		v.speedY = 0
		if math.abs(plr.x-v.x + 250)<=data.radius and v.direction == DIR_RIGHT or math.abs(plr.x-v.x - 250)<=data.radius and v.direction == DIR_LEFT then
			if v.ai1 == 0 then
				if plr.y >= v.y then
					data.up = true
				else
					data.up = false
				end
				data.attackTimer = 16
				v.direction = -v.direction
				v.ai1 = 1
				data.state = STATE_MOVE
			end
		end
	else
		if data.attackTimer > 0 then
			v.speedX = 0
			data.attackTimer = data.attackTimer - 1
			if data.up then
				v.speedY = 4.5
			else
				v.speedY = -4.5
			end
		else
			data.state = STATE_SWIM
		end
	end
end

--Gotta return the library table!
return fishy