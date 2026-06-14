-- NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local sml = require("npcs/ai/SMLDeath")

-- Create the library table
local snake = {}
-- NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
-- Defines NPC config for our NPC. You can remove superfluous definitions.
local snakeSettings = {
    id = npcID,
    gfxheight = 64,
    gfxwidth = 48,
    width = 48,
    height = 50,
    frames = 4,
    framestyle = 1,
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
	cliffturn = true,
	score = 5,

    -- Define custom properties below
    projectilespeed = 4,
	muted = false,
}

-- Applies NPC settings
npcManager.setNpcSettings(snakeSettings)

-- Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID, {
    HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC,
    HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA, HARM_TYPE_HELD, HARM_TYPE_TAIL,
    HARM_TYPE_SPINJUMP,  HARM_TYPE_OFFSCREEN,
    HARM_TYPE_SWORD
}, {
    [HARM_TYPE_JUMP] = 332,
    [HARM_TYPE_FROMBELOW] = 332,
    [HARM_TYPE_NPC] = 332,
    [HARM_TYPE_PROJECTILE_USED] = 332,
    [HARM_TYPE_LAVA] = {
        id = 13,
        xoffset = 0.5,
        xoffsetBack = 0,
        yoffset = 1,
        yoffsetBack = 1.5
    },
    [HARM_TYPE_HELD] = 332,
    [HARM_TYPE_TAIL] = 332,
    [HARM_TYPE_SPINJUMP] = 10,
     [HARM_TYPE_OFFSCREEN]= 332,
    [HARM_TYPE_SWORD] = 10
});

-- Custom local definitions below

-- Register events
function snake.onInitAPI()
    npcManager.registerEvent(npcID, snake, "onTickEndNPC")
	registerEvent(snake, "onNPCHarm")
end

function snake.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		Misc.givePoints(5, v, true)
		SFX.play(2)
		data.death = true
	end
end

function snake.onTickNPC(v)
    local targetedplayer = Player.getNearest(v.x + v.width / 2,
                                             v.y + v.height / 2)
    if math.abs(v.x - targetedplayer.x) < 512 and
        math.abs(v.y - targetedplayer.y) < 256 then
        if v.x < targetedplayer.x then
            v.direction = 1
        else
            v.direction = -1
        end
    end
end

local function getAnimationFrame(v)
    local data = v.data
    local settings = v.data._settings
    local frame = 0

    if data.spawnTimer == settings.delay or data.spawnTimer <= 30 then
        frame = 2
    else
		if settings.walk then
			if v.direction == DIR_LEFT then
				frame = math.floor(lunatime.tick() / 8) % 2
			else
				frame = math.floor(lunatime.tick() / 8) % 2 + 4
			end
		else
			frame = 0
		end
    end

	if data.death then
		frame = 3
	end

    v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = frame})
end

function snake.onTickEndNPC(v)
    -- Don't act during time freeze
    if Defines.levelFreeze then return end

    local data = v.data
    local settings = v.data._settings
    if settings.delay == nil then settings.delay = 180 end
    data.spawnTimer = data.spawnTimer or settings.delay - 10

    getAnimationFrame(v)

    -- If despawned
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        -- Reset our properties, if necessary
        data.initialized = false
        data.spawnTimer = settings.delay - 10
		data.death = false
		data.deathTimer = 0
        return
    end

    -- Initialize
    if not data.initialized then
        -- Initialize necessary data.
        data.initialized = true
		data.deathTimer = data.deathTimer or 0
    end

    -- Depending on the NPC, these checks must be handled differently
    if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
    or v:mem(0x136, FIELD_BOOL) -- Thrown
    or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
    then
        -- Handling
    end
	
	if settings.walk then
		if data.spawnTimer == settings.delay or data.spawnTimer <= 30 then
			v.speedX = 0
		else
			v.speedX = 1.25 * v.direction
		end
	end
	
	if data.death == nil then data.death = false end

	if not data.death then
		if data.spawnTimer == nil then data.spawnTimer = settings.delay - 10 end

		if data.spawnTimer <= settings.delay then
			data.spawnTimer = data.spawnTimer + 1
		end

		local targetedplayer = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)

		if data.spawnTimer == settings.delay then
			local originX = v.x + 0.5 * v.width - 4
			local originY = v.y + 0.5 * v.height
			local projectile = NPC.spawn(726, originX, originY,
										 targetedplayer.section, false, true)
			SFX.play(42)
			if v.direction == DIR_LEFT then
				projectile.direction = DIR_LEFT
			else
				projectile.direction = DIR_RIGHT
			end

			projectile.speedX = snakeSettings.projectilespeed * v.direction
			local traveltime = math.max((targetedplayer.x - originX) / projectile.speedX, 1)
			projectile.speedY = (targetedplayer.y - originY) / traveltime
			projectile.speedY = math.min(math.max(projectile.speedY, -2), 2)
			data.spawnTimer = 0
		end
			if data.spawnTimer == settings.delay - 1 then
				if v.x < targetedplayer.x then
					v.direction = 1
				else
					v.direction = -1
				end
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
return snake
