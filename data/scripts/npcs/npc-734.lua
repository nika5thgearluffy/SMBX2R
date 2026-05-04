--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sml = require("npcs/ai/SMLDeath")


--********************************************************
--Parenting code used from basegame dinotorch and bros.lua
--********************************************************


--Create the library table
local mekabon = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local mekabonSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 50,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	cliffturn = true,
	attackDelay=224,
	muted=false,
}

--Applies NPC settings
npcManager.setNpcSettings(mekabonSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=320,
		[HARM_TYPE_NPC]=320,
		[HARM_TYPE_PROJECTILE_USED]=320,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=320,
		[HARM_TYPE_TAIL]=320,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=320,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_STROLL = 0
local STATE_ATTACK = 1
local STATE_HURT = 2

--Register events
function mekabon.onInitAPI()
	npcManager.registerEvent(npcID, mekabon, "onTickEndNPC")
	registerEvent(mekabon, "onNPCKill")
	registerEvent(mekabon, "onNPCHarm")
end

function mekabon.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_STROLL
		data.timer = 0
		data.deathTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_STROLL
		data.timer = data.timer or 0
		data.deathTimer = data.deathTimer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
	end
	
	if data.state == STATE_ATTACK and data.timer == 0 then
		data.head = NPC.spawn(npcID - 1, v.x + 0.5 * v.width, v.y - 0.5 * v.height, v:mem(0x146, FIELD_WORD), false, true)
		data.head.direction = v.direction
		data.head.layerName = "Spawned NPCs"
		data.head.data.parent = v
		data.head.data.owner = v
	end
	
	if data.head and data.head.isValid and data.offsetFunction then
		data.offsetFunction(v, data.head)
		data.head.direction = v.direction
	end
	
	data.timer = data.timer + 1
	
	if data.state == STATE_STROLL then
		v.speedX = 0.8 * v.direction
		v.animationFrame = math.floor(lunatime.tick() / 16) % 2
		if data.timer >= mekabonSettings.attackDelay then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_ATTACK
			data.timer = 0
		end
	elseif data.state == STATE_ATTACK then
		v.speedX = 0
		v.animationFrame = 2
		if data.timer >= 167 then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_STROLL
			data.timer = 0
		end
	else
		v.animationFrame = 3
		v.speedX = 0
		v.friendly = true
		if v.collidesBlockBottom then
			data.deathTimer = data.deathTimer + 1
			if data.deathTimer >= 96 then
				v:kill(HARM_TYPE_OFFSCREEN)
				if not NPC.config[v.id].muted then
					SFX.play("sound/extended/sml1-death.ogg")
				else
					SFX.play(4)
				end
			end
		end
	end
end

function mekabon.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if reason == HARM_TYPE_JUMP then
		if data.state == STATE_STROLL then
			eventObj.cancelled = true
			Misc.givePoints(4, v, true)
			SFX.play(2)
			data.state = STATE_HURT
		end
	end
end

function mekabon.onNPCKill(eventObj, v, killReason)
	if v.id ~= npcID then return end;
	-- Took this part from the dino torch lua file
	local data = v.data
	
	if (data.head == nil) then
		return;
	end
	
	if data.head.isValid == true then
		data.head:kill(9)
	end
end

--Gotta return the library table!
return mekabon