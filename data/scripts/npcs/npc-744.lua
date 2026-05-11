--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sml = require("npcs/ai/SMLDeath")

--Create the library table
local hopper = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local hopperSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 64,
	frames = 3,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	muted = false,
	score = 5,
	jumpheight = 7.5,
	health = 3,
	weight = 2,
}

--Applies NPC settings
npcManager.setNpcSettings(hopperSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=325,
		[HARM_TYPE_FROMBELOW]=325,
		[HARM_TYPE_NPC]=325,
		[HARM_TYPE_PROJECTILE_USED]=325,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=325,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=324,
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function hopper.onInitAPI()
	npcManager.registerEvent(npcID, hopper, "onTickEndNPC")
	registerEvent(hopper, "onNPCHarm")
end

function getAnimationFrame(v)
	local data = v.data
	local frame = 0
    if not data.death then
		frame = math.floor(lunatime.tick() / 8) % 2
    else
		frame = 2
	end
	v.animationFrame = frame
end

function hopper.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if not data.health then
		data.health = hopperSettings.health
	end
	
	if reason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		Misc.givePoints(5, v, true)
		SFX.play(2)
		data.death = true
	end
	
	if reason == HARM_TYPE_NPC then
	
		if culprit then
			if culprit.__type == "NPC" and (culprit.id == 13 or culprit.id == 108 or culprit.id == 17 or NPC.config[culprit.id].SMLDamageSystem) then
				data.health = data.health - 1
				culprit:kill()
			else
				data.health = 0
			end
		else
			for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if NPC.config[n.id].SMLDamageSystem then
					data.health = data.health - 1
					SFX.play(9)
					Animation.spawn(75, n.x, n.y)
					if data.health > 0 then
						eventObj.cancelled = true
					end
				end
			end
		end
		
		if data.health > 0 then
			SFX.play(9)
			if reason ~= HARM_TYPE_SWORD and culprit then
				Animation.spawn(75, culprit.x, culprit.y)
			end
			eventObj.cancelled = true
			return
		end
		
	end
	
end

function hopper.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.death = false
		data.deathTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.deathTimer = data.deathTimer or 0
	end
	
	getAnimationFrame(v)
	
	if not data.death then
		if v.collidesBlockBottom then
			npcutils.faceNearestPlayer(v)
			v.speedX = 1.5 * v.direction
			v.speedY = -NPC.config[v.id].jumpheight
		end
	else
		v.speedX = 0
		v.speedY = 3.5
		v.friendly = true
		if v.collidesBlockBottom then
			data.deathTimer = data.deathTimer + 1
			if data.deathTimer >= 48 then
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

--Gotta return the library table!
return hopper