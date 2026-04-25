local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local fireNipper = {}
local npcID = NPC_ID

local deathEffectID = 301

local fireNipperSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 4,
	framestyle = 1,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	luahandlesspeed = true,


	triggerWidth = 30,
	triggerHeight = 256,

	patrolDistance = 128,
	turnAroundWait = 60,

	jumpSpeed = -7,

	speed = 1.4,
	hopSpeed = -1.5,

	jumpFrames = 2,
	jumpFrameSpeed = 8,

	fireID = 526,
	fireSpeedX = 0,
	fireSpeedY = -6,
	fireSound = 18,
}

npcManager.setNpcSettings(fireNipperSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

function fireNipper.onInitAPI()
	npcManager.registerEvent(npcID, fireNipper, "onTickEndNPC")
end


local STATE_HOP  = 0
local STATE_JUMP = 1
local STATE_FALL = 2

local function shouldJump(v,config)
	local col = Colliders.Box(0,0,0,0)

	col.width = config.triggerWidth
	col.height = config.triggerHeight
	col.x = v.x + (v.width - col.width)*0.5
	col.y = v.y - col.height

	--col:draw()

	for _,p in ipairs(Player.get()) do
		if p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) and p.section == v.section and col:collide(p) then
			return true
		end
	end

	return false
end

local function spitFire(v,config)
	if config.fireID <= 0 then
		return
	end

	local n = NPC.spawn(config.fireID,v.x + v.width*0.5,v.y + v.height*0.5,v.section,false,true)

	n.direction = v.direction
	n.speedX = config.fireSpeedX*n.direction
	n.speedY = config.fireSpeedY

	n.layerName = "Spawned NPCs"
	n.friendly = v.friendly

	if config.fireSound ~= 0 then
		SFX.play(config.fireSound)
	end
end


function fireNipper.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	local config = NPC.config[v.id]

	if not data.initialized then
		data.initialized = true

		data.state = STATE_HOP
		data.turnAroundTimer = 0

		data.animationTimer = 0
	end
	
	if v:mem(0x12C,FIELD_WORD) == 0 and not v:mem(0x136,FIELD_BOOL) and v:mem(0x138,FIELD_WORD) == 0 then
		-- Basic jumping behaviour
		if data.state == STATE_HOP then
			if shouldJump(v,config) then
				data.state = STATE_JUMP
				v.speedX = 0
				v.speedY = config.jumpSpeed
			end
		else
			if v.collidesBlockBottom then
				data.state = STATE_HOP
			elseif data.state == STATE_JUMP and v.speedY > 0 then
				spitFire(v,config)
				data.state = STATE_FALL
			end
		end

		-- Patrolling
		if not v.dontMove and data.state == STATE_HOP then
			local distance = (v.spawnX + v.spawnWidth*0.5) - (v.x + v.width*0.5)

			if data.turnAroundTimer <= 0 then
				-- Hopping
				if v.spawnId > 0 and (math.abs(distance) > config.patrolDistance and math.sign(distance) == -v.direction) then
					data.turnAroundTimer = config.turnAroundWait
				end

				v.speedX = config.speed*v.direction
				
				if v.collidesBlockBottom then
					v.speedY = config.hopSpeed
				end
			else
				-- Waiting to turn around
				data.turnAroundTimer = data.turnAroundTimer - 1

				if v.collidesBlockBottom then
					v.speedX = 0
				end

				if data.turnAroundTimer <= 0 and distance ~= 0 then
					v.direction = math.sign(distance)
				end
			end
		end
	end

	-- Animation
	local hopFrames = (config.frames - config.jumpFrames)
	local frame
	if data.state ~= STATE_JUMP then
		frame = math.floor(data.animationTimer/config.framespeed) % hopFrames
	else
		frame = (math.floor(data.animationTimer/config.jumpFrameSpeed) % config.jumpFrames) + hopFrames
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	data.animationTimer = data.animationTimer + 1
end

return fireNipper