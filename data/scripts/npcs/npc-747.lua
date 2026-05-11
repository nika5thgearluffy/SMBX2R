--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sml = require("npcs/ai/SMLDeath")

--Create the library table
local Rock = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local RockSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 46,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 46,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 3,
	framestyle = 1,
	framespeed = 16, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	score = 4,
	noyoshi= true,
	nowaterphysics = true,
	muted = false,
}

--Applies NPC settings
npcManager.setNpcSettings(RockSettings)

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
		[HARM_TYPE_JUMP]=327,
		[HARM_TYPE_FROMBELOW]=327,
		[HARM_TYPE_NPC]=327,
		[HARM_TYPE_PROJECTILE_USED]=327,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=327,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN] = {id=327, speedY=-2.5},
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function Rock.onInitAPI()
	npcManager.registerEvent(npcID, Rock, "onTickEndNPC")
	registerEvent(Rock, "onNPCHarm")
end

function Rock.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		Misc.givePoints(4, v, true)
		SFX.play(2)
		data.death = true
	end
end

local function getAnimationFrame(v)
    local data = v.data
    local frame = 0

    if not data.death then
		if v.collidesBlockBottom then
			frame = math.floor(lunatime.tick() / 5) % 2
		else
			if v.speedX == 0 then
				frame = frame
			end
		end
    else
		frame = 2
	end

    v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = frame})
end

function Rock.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.death = false
		data.deathTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		data.initialized = true
		data.deathTimer = data.deathTimer or 0
	end
	
	getAnimationFrame(v)
	
	if not data.death then

		if not v.collidesBlockBottom then
			v.speedX = 0
			v.speedY = 3
		else
			v.speedX = 5.5 * v.direction
		end
	else
		v.speedX = 0
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
return Rock