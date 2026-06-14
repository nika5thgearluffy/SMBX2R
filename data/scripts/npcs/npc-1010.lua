-- NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sml = require("npcs/ai/SMLDeath")

-- Create the library table
local pompon = {}
-- NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
-- Defines NPC config for our NPC. You can remove superfluous definitions.
local pomponSettings = {
    id = npcID,
    gfxheight = 48,
    gfxwidth = 48,
    width = 48,
    height = 48,
    frames = 3,
    framestyle = 0,
    framespeed = 8,
    speed = 1,

    npcblock = false,
    npcblocktop = false,
    playerblock = false,
    playerblocktop = false,

    nohurt = false,
    nogravity = false,
    noblockcollision = false,
    nofireball = false,
    noiceball = false,
    noyoshi = false,
    nowaterphysics = false,

    jumphurt = false,
    spinjumpsafe = false,
    harmlessgrab = false,
    harmlessthrown = false,

    grabside = false,
    grabtop = false,
	score = 5,
	cliffturn = true,

    -- Define custom properties below
    projectileHeight = 9,
	walkTime = 96,
	projectile = 726,
	muted = false,
	health = 2
}

-- Applies NPC settings
npcManager.setNpcSettings(pomponSettings)

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
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=333,
		[HARM_TYPE_FROMBELOW]=333,
		[HARM_TYPE_NPC]=333,
		[HARM_TYPE_PROJECTILE_USED]=333,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=333,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN] = {id=333, speedY=-2.5},
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_WALK = 0
local STATE_SHOOT = 1
local STATE_DEATH = 2

-- Register events
function pompon.onInitAPI()
    npcManager.registerEvent(npcID, pompon, "onTickEndNPC")
	registerEvent(pompon, "onNPCHarm")
end

function pompon.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if not data.health then
		data.health = pomponSettings.health
	end
	
	if reason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		Misc.givePoints(5, v, true)
		SFX.play(2)
		data.state = STATE_DEATH
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
	
	if culprit then
		if data.health > 0 then
			SFX.play(9)
			if reason ~= HARM_TYPE_SWORD then
				Animation.spawn(75, culprit.x, culprit.y)
			end
			eventObj.cancelled = true
			return
		end
	end
		
	end
end

local function getAnimationFrame(v)
    local data = v.data
    local frame = 0

    if data.state == STATE_WALK then
		frame = math.floor(lunatime.tick() / 8) % 2
	elseif data.state == STATE_SHOOT then
		if data.timer <= 32 then
			frame = 0
		else
			frame = 1
		end
	else
		frame = 2
	end
    v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = frame})
end

function pompon.onTickEndNPC(v)
    -- Don't act during time freeze
    if Defines.levelFreeze then return end

    local data = v.data

    getAnimationFrame(v)

    -- If despawned
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        -- Reset our properties, if necessary
        data.initialized = false
		data.deathTimer = 0
		data.timer = 0
        return
    end

    -- Initialize
    if not data.initialized then
        -- Initialize necessary data.
        data.initialized = true
		data.deathTimer = data.deathTimer or 0
		data.timer = data.timer or 0
    end

    -- Depending on the NPC, these checks must be handled differently
    if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
    or v:mem(0x136, FIELD_BOOL) -- Thrown
    or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
    then
        data.timer = 0
    end
	
	if data.state == nil then data.state = STATE_WALK end
	
	data.timer = data.timer + 1
	
	if data.state == STATE_WALK then
		v.speedX = 1.3 * v.direction
		if data.timer >= pomponSettings.walkTime then
			data.timer = 0
			data.state = STATE_SHOOT
		end
	elseif data.state == STATE_SHOOT then
		v.speedX = 0
		if data.timer == 31 then
			SFX.play(42)
			local n = NPC.spawn(pomponSettings.projectile, v.x + pomponSettings.width / 5, v.y - pomponSettings.height / 2)
			n.speedY = -pomponSettings.projectileHeight
			n.speedX = 0
		elseif data.timer >= 64 then
			data.state = STATE_WALK
			data.timer = 0
		end
	else
		v.friendly = true
		v.speedX = 0
		if v.collidesBlockBottom then
			data.deathTimer = data.deathTimer + 1
			if data.deathTimer >= 64 then
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

-- Gotta return the library table!
return pompon
