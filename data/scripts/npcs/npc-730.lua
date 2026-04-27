--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

--******************************
--Death effect code by MrDoubleA
--******************************

--Create the library table
local bowser = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local bowserSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 128,
	gfxwidth = 160,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 100,
	height = 84,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
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
	muted=false,
	score=9,
	health=5,
}

--Applies NPC settings
npcManager.setNpcSettings(bowserSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);


--Register events
function bowser.onInitAPI()
	npcManager.registerEvent(npcID, bowser, "onTickEndNPC")
	registerEvent(bowser, "onNPCHarm")
	registerEvent(bowser, "onNPCKill")
end

function bowser.onNPCKill(obj, v, harm)
	if v.id == npcID then
		local data = v.data
		if harm == HARM_TYPE_NPC or harm == HARM_TYPE_LAVA or harm == HARM_TYPE_SWORD then
			Animation.spawn(319, v.x - 30, v.y - 44, v.animationFrame + 1)
		end
	end
end

function bowser.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if not data.health then
		data.health = bowserSettings.health
	end
	if culprit then
		if culprit.__type == "NPC" and (culprit.id == 13 or culprit.id == 108 or culprit.id == 17 or NPC.config[culprit.id].SMLDamageSystem) then
			if v:mem(0x156, FIELD_WORD) <= 0 then
				data.health = data.health - 1
				v:mem(0x156, FIELD_WORD,20)
				culprit:kill()
			end
		elseif reason ~= HARM_TYPE_LAVA then
			if v:mem(0x156, FIELD_WORD) <= 0 then
				data.health = data.health - 5
				v:mem(0x156, FIELD_WORD,20)
				if culprit.isHittable then
					culprit:kill()
				end
			end
		else
			data.health = 0
		end
	elseif reason ~= HARM_TYPE_SWORD then
		for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if NPC.config[n.id].SMLDamageSystem then
				if v:mem(0x156, FIELD_WORD) <= 0 then
					data.health = data.health - 1
					v:mem(0x156, FIELD_WORD,20)
					SFX.play(9)
					Animation.spawn(75, n.x, n.y)
				end
				if data.health > 0 then
					eventObj.cancelled = true
				end
			end
		end
	end
	if reason == HARM_TYPE_SWORD then
		if v:mem(0x156, FIELD_WORD) <= 0 then
			data.health = data.health - 1
			v:mem(0x156, FIELD_WORD,20)
			v.ai2 = 16
		end
		if Colliders.downSlash(player,v) then
			player.speedY = -6
		end
	end
	if data.health > 0 then
		if v:mem(0x156, FIELD_WORD) == 20 then
			if NPC.config[v.id].muted then
				SFX.play(66)
			else
				SFX.play("sound/extended/sml1-boss-hurt.ogg")
			end
			if reason ~= HARM_TYPE_SWORD and culprit then
				Animation.spawn(75, culprit.x, culprit.y)
			end
		end
		eventObj.cancelled = true
		return
	end
end

function effectconfig.onTick.TICK_BOSSDEATH3(v)
	if v.timer <= 64 and lunatime.tick() % 4 < 2 then
		v.animationFrame = -50
	else
		v.animationFrame = 0
	end

	if v.timer > 64 and v.timer % 18 == 0 then
		local e = Effect.spawn(69,0,0)

		e.timer = math.floor(e.timer/2)

		e.x = (v.x+(v.width /2)-(e.width /2)+RNG.random(-e.width /2,e.width /2))
		e.y = (v.y+(v.height/2)-(e.height/2)+RNG.random(-e.height/2,e.height/2))
		SFX.play(22)
	end
end

local function getFrame(v)
	local data = v.data
	if v.collidesBlockBottom then
		if data.timer <= 48 or data.timer >= 72 and data.timer <= 87 then
			v.animationFrame = 0
		elseif data.timer >= 49 and data.timer <= 71 then
			v.animationFrame = 1
		end
	else
		if v.speedY <= 0 then
			v.animationFrame = 2
		else
			v.animationFrame = 3
		end
	end
	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
end

function bowser.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.airTimer = data.airTimer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		v.animationFrame = 0
	end
	
	getFrame(v)
	
	if v.collidesBlockBottom then
		npcutils.faceNearestPlayer(v)
		data.timer = data.timer + 1
		if data.timer == 49 then
			SFX.play(42)
			local n
			if v.direction == DIR_LEFT then
				n = NPC.spawn(87,v.x,v.y + 32)
			else
				n = NPC.spawn(87,v.x + 48,v.y + 32)
			end
			n.speedX = 4 * v.direction
		end
		data.airTimer = 0
	else
		data.airTimer = data.airTimer + 1
		if data.airTimer == 32 and v.speedY <= 0 then
			SFX.play(42)
			local n
			if v.direction == DIR_LEFT then
				n = NPC.spawn(87,v.x,v.y + 32)
			else
				n = NPC.spawn(87,v.x + 48,v.y + 32)
			end
			n.speedX = 4 * v.direction
		end
		data.timer = 0
	end
	
	if data.timer >= 88 then
		v.speedY = -8.5
	end
	
	if v.ai2 > 0 then
		v.ai2 = v.ai2 - 1
		v.invincibleToSword = true
	else
		v.invincibleToSword = false
	end	
	
end

--Gotta return the library table!
return bowser