--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local fireNipper = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fireNipperSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 4,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,
	grabside=false,
	grabtop=false,

	--NPC-specific properties
	projectileID = 526,
	playerProjectileID = 13,

	fireSound = 18,

	spitFrames = 2,
	spitFrameSpeed = 6,
}

local deathEffectID = 302

--Applies NPC settings
npcManager.setNpcSettings(fireNipperSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_IDLE = 0
local STATE_SHOOTING = 1

--Register events
function fireNipper.onInitAPI()
	npcManager.registerEvent(npcID, fireNipper, "onTickNPC")
	npcManager.registerEvent(npcID, fireNipper, "onDrawNPC")
end

function fireNipper.onDrawNPC(v)
	if Defines.levelFreeze then return end
	
	--if despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end

	local config = NPC.config[v.id]
	local data = v.data
	
	local idleFrames = (config.frames - config.spitFrames)
	local frame
	if data.state == STATE_IDLE then
		frame = math.floor((data.animationTimer or 0)/config.framespeed) % idleFrames
	elseif data.state == STATE_SHOOTING then
		frame = (math.floor((data.animationTimer or 0)/config.spitFrameSpeed) % config.spitFrames) + idleFrames
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = frame})
end

function fireNipper.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		
		local cfg = NPC.config[v.id]
		
		data.projectileID = cfg.projectileID
		data.playerProjectileID = cfg.playerProjectileID
		
		data.cooldowntime = data._settings.cooldowntime or 240
		
		data.fireBallCount = data._settings.fireballcount or 4
		data.projectileDelay = data._settings.projectiledelay or 6

		data.fireSound = cfg.fireSound or 0
		
		data.state = STATE_IDLE
		
		data.timer = 6
		
		data.animationTimer = 0
		
		data.initialized = true
	end
	
	
	if v.isProjectile then
		v.speedX = v.speedX*0.95
		return
	elseif v.forcedState > 0 then
		return
	end

	
	if v.heldIndex == 0 then
		npcutils.faceNearestPlayer(v)
	end

	
	if data.state == STATE_IDLE then
		data.timer = data.timer-1
		
		if data.timer <= 0 then
			data.state = STATE_SHOOTING
			data.timer = data.fireBallCount*data.projectileDelay
		end
	
	elseif data.state == STATE_SHOOTING then
	
		data.timer = data.timer-1
		
		if data.timer%data.projectileDelay==0 then
			if data.fireSound ~= 0 then
				SFX.play(data.fireSound)
			end

			local id = data.projectileID

			if v.heldIndex > 0 then
				id = data.playerProjectileID
			end

			local w = NPC.spawn(id, v.x+0.5*v.width, v.y+0.5*v.height, v.section, false, true)

			w.speedX = 3*v.direction
			w.speedY = -8
			w.layerName = "Spawned NPCs"
			w.friendly = v.friendly
			w:mem(0x132,FIELD_WORD,v.heldIndex)
		end
		
		if data.timer <= 0 then
			data.state = STATE_IDLE
			data.timer = data.cooldowntime
		end
	
	end
	
	data.animationTimer = data.animationTimer + 1
end

--Gotta return the library table!
return fireNipper