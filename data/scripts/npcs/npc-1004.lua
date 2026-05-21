--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

--Create the library table
local rocky = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local rockySettings = {
	id = npcID,
	--Sprite size
	gfxheight = 96,
	gfxwidth = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 52,
	height = 80,
	frames = 6,
	framestyle = 1,
	framespeed = 8, 
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	muted = false,
	score = 8,
	AcurrateTurn = 40,
	health = 10,
	weight = 5
}

--Applies NPC settings
npcManager.setNpcSettings(rockySettings)

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
		--[HARM_TYPE_NPC]=10,
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
function rocky.onInitAPI()
	npcManager.registerEvent(npcID, rocky, "onTickEndNPC")
	registerEvent(rocky, "onNPCHarm")
	registerEvent(rocky, "onNPCKill")
end

function rocky.onNPCKill(obj, v, harm)
	if v.id == npcID then
		local data = v.data
		if harm == HARM_TYPE_NPC or harm == HARM_TYPE_LAVA or harm == HARM_TYPE_SWORD then
			Animation.spawn(330, v.x - 22, v.y - 16, v.animationFrame + 1)
		end
	end
end

function rocky.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	local settings = v.data._settings
	if v.id ~= npcID then return end
	if not data.health then
		data.health = rockySettings.health
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
	if data.health <= 5 and settings.phase2 then
		settings.walk = true
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

function effectconfig.onTick.TICK_BOSSDEATH2(v)
	if v.timer <= 64 and lunatime.tick() % 4 < 2 then
		v.animationFrame = -15
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

local function getAnimationFrame(v)
    local data = v.data
	local settings = v.data._settings
    local frame = 0

	if settings.walk then
		if data.timer <= 63 then
			frame = math.floor(lunatime.tick() / 8) % 3
		end
	end
    if data.timer >= 64 and data.timer <= 111 then
		frame = 3
	elseif data.timer >= 112 and data.timer <= 117 then
		frame = 4
	elseif data.timer >= 118 then
		frame = 5
	end

    v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = frame})
end

function rocky.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 115
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 115
	end

	if data.Chase == nil then
		data.Chase = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
	end
	
	if v:mem(0x136, FIELD_BOOL)    --Thrown 
	then
		if v.collidesBlockBottom then 
			v.speedX = 0 
		end
	end
	
	getAnimationFrame(v)
	
	if settings.walk then 
		if data.timer <= 63 then
			data.Chase = data.Chase + 1
			v.speedX = 2.4 * v.direction
		else
			v.speedX = 0
		end
		if data.Chase >= NPC.config[v.id].AcurrateTurn then
			if v.x > Player.getNearest(v.x, v.y).x then
				v.direction = -1
			else
				v.direction = 1
			end
			data.Chase = 0
		end
	end
	
	data.timer = data.timer + 1
	
	if data.timer == 120 then
		if v.direction == DIR_LEFT then
			local n = NPC.spawn(748, v.x - 0.4 * v.width, v.y - 0.4 * v.height + 8, player.section, false, true)
			n.direction = DIR_LEFT
		else
			local n = NPC.spawn(748, v.x + 0.9 * v.width + 29, v.y - 0.4 * v.height + 8, player.section, false, true)
			n.direction = DIR_RIGHT
		end
	end
	if data.timer >= 128 then data.timer = 0 end
	
	
	if v.ai2 > 0 then
		v.ai2 = v.ai2 - 1
		v.invincibleToSword = true
	else
		v.invincibleToSword = false
	end	
end

--Gotta return the library table!
return rocky