--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local redirector = require("redirector")
local effectconfig = require("game/effectconfig")

--******************************
--Death effect code by MrDoubleA
--******************************

--Create the library table
local dragonmazu = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local dragonmazuSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 88,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 88,
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

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
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
	shootDelay=48,
	health=20,
}

--Applies NPC settings
npcManager.setNpcSettings(dragonmazuSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
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
function dragonmazu.onInitAPI()
	npcManager.registerEvent(npcID, dragonmazu, "onTickEndNPC")
	registerEvent(dragonmazu, "onNPCHarm")
	registerEvent(dragonmazu, "onNPCKill")
end

function dragonmazu.onNPCKill(obj, v, harm)
	if v.id == npcID then
		local data = v.data
		if harm == HARM_TYPE_NPC or harm == HARM_TYPE_SWORD then
			Animation.spawn(323, v.x, v.y - 8, v.animationFrame + 1)
		end
	end
end

function dragonmazu.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if not data.health then
		data.health = dragonmazuSettings.health
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

function effectconfig.onTick.TICK_BOSSDEATH4(v)
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

function dragonmazu.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	npcutils.applyLayerMovement(v)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.keepSpeedX = 0
		data.keepSpeedY = 0
		return
	end
	
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.keepSpeedX = data.keepSpeedX or 0
		data.keepSpeedY = data.keepSpeedY or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		v.animationFrame = 0
	end

	data.timer = data.timer + 1
	
	if data.timer == dragonmazuSettings.shootDelay then
		SFX.play(42)
		local n
		if v.direction == DIR_LEFT then
			n = NPC.spawn(87,v.x - 24,v.y + 32)
		else
			n = NPC.spawn(87,v.x + 40,v.y + 32)
		end
		n.speedX = 4 * v.direction
	elseif data.timer >= dragonmazuSettings.shootDelay then
		v.animationFrame = 1
		v.speedX = 0
		v.speedY = 0
	else
		v.speedX = data.keepSpeedX
		v.speedY = data.keepSpeedY
		v.animationFrame = 0
	end
	
	if data.timer >= dragonmazuSettings.shootDelay + 16 then
		data.timer = 0
	end
	
	for _,bgo in ipairs(BGO.getIntersecting(v.x+(v.width/2)-0.5,v.y+(v.height/2),v.x+(v.width/2)+0.5,v.y+(v.height/2)+0.5)) do
		if redirector.VECTORS[bgo.id] then -- If this is a redirector and has a speed associated with it
			local redirectorSpeed = redirector.VECTORS[bgo.id] * 2 -- Get the redirector's speed and make it match the speed in the NPC's settings		
			-- Now, just put that speed from earlier onto the NPC
			data.keepSpeedX = redirectorSpeed.x
			data.keepSpeedY = redirectorSpeed.y
		elseif bgo.id == redirector.TERMINUS then -- If this BGO is one of the crosses
			-- Simply make the NPC stop moving
			data.keepSpeedX = 0
			data.keepSpeedY = 0
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = dragonmazuSettings.frames
	});
	
end

--Gotta return the library table!
return dragonmazu