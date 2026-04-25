--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local lakitushop = require("lakitushop")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxwidth = 56,
	gfxheight = 72,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 56,
	height = 72,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4, -- idleframes
    throwframes = 4,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

    staticdirection = true,
    luahandlesspeed = true,
	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onDrawNPC(v)
	local data = v.data._basegame
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) ~= 0   --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end

    if not data.initialized then
        data.initialized = true
        data.state = data.state or 1
        data.timer = data.timer or 0
        v.direction = -1
        if data.post and data.post.isValid then
            if data.post.x + 0.5 * data.post.width > v.x + 0.5 * v.width then
                v.direction = 1
            end
			data.target = vector(data.post.x + 0.5 * data.post.width + (0.5 * v.width + 32) * -v.direction, data.post.y - 96)
			v.speedY = 8
			v.speedX = 1 * v.direction
        else
			-- spawned without a post, just hang out.
			data.state = 5
			data.target = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
		end

    end

	if data.state == 5 then
		-- state for 'hanging out'
		v.speedX = v.speedX * 0.95
		v.speedY = v.speedY * 0.95 + math.sin(data.timer * 0.1) * 0.1
		data.timer = data.timer + 1
    elseif data.state < 3 and data.post and data.post.isValid then
        if v.x + 0.5 * v.width < data.post.x + 0.5 * data.post.width then
            v.direction = 1
        else
            v.direction = -1
        end
		v.speedX = math.clamp((data.target.x - (v.x + 0.5 * v.width)) * 0.1, -4, 4)
		v.speedY = math.clamp((data.target.y - (v.y + 0.5 * v.height)) * 0.2, -8, 8)
        if data.state == 2	then

            data.timer = data.timer + 1
            if data.timer > 32 then
                data.state = 1
            end
        else
            data.timer = 0
        end
    else
        v.speedX = math.clamp(v.speedX + v.direction * 0.1, -4, 4)
        v.speedY = math.max(v.speedY - 0.3, -8)
        if v.despawnTimer < 175 then
            v:kill(9)
        end
    end
	
    if data.state == 2 and data.timer > 0 then
        local cfg = NPC.config[v.id]
        local framesToSkip = cfg.frames
        if cfg.framestyle == 1 then
            framesToSkip = cfg.frames * 2
            if v.direction == 1 then
                framesToSkip = cfg.frames * 2 + cfg.throwframes
            end
        end

        v.animationFrame = framesToSkip + (math.floor(data.timer/cfg.framespeed) % cfg.throwframes)
        v.animationTimer = 6
    end

    if Misc.isPausedByLua() then
        v.x = v.x + v.speedX
        v.y = v.y + v.speedY
    end

	if lakitushop.dropItem(v, not Misc.isPaused())
		and vector(data.target.x - (v.x + 0.5 * v.width), data.target.y - (v.y + 0.5 * v.height)).length < 16  then
		data.state = 2
	end
end

--Gotta return the library table!
return sampleNPC