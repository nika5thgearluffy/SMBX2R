local dirCannon = {}

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
--NPCutils for rendering --
local npcutils = require("npcs/npcutils")

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sharedSettings = {
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = true,
	npcblocktop = false,
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Define custom properties below
	shotcount = 1, -- used by single, dual and quad cannons
	shotspeed = 2,
	pulsex = true, -- controls the scaling of the sprite when firing
	pulsey = true,
	shotsound = 22,
	shotid = 695,
	effectid = 131,
	effectoffsetx = -16,
	effectoffsety = -16
}

--Register events
function dirCannon.register(id, config)
	npcManager.registerEvent(id, dirCannon, "onTickNPC")
    npcManager.registerEvent(id, dirCannon, "onDrawNPC")

	npcManager.setNpcSettings(table.join(config, sharedSettings))
end


local function init(v)
	local data = v.data._basegame
	local cfg = v.data._settings

	local npcConfig = NPC.config[v.id]
	data.initialized = true
	data.frameTimer = npcConfig.framespeed
	data.shootTimer = lunatime.toTicks(cfg.aOptions.roundDelay)
	data.shotsFired = 0

	if data.friendly == nil and cfg.bOptions.hidden then
		data.friendly = v.friendly
		v.friendly = true
	end

	if data.friendly == nil and v:mem(0x12C, FIELD_WORD) == 0 then
		data.friendly = v.friendly
	end

	data.sprSizex = 1
	data.sprSizey = 1
	data.rotation = cfg.aOptions.constantRotation / lunatime.toTicks(1)

	local frames = npcConfig.frames
	if npcConfig.framestyle == 1 then
		frames = frames * 2
	elseif npcConfig.framestyle == 2 then
		frames = frames * 4
	end

	data.angle = cfg.bOptions.shootAngle
	
	data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = frames, texture = Graphics.sprites.npc[v.id].img}
end

function dirCannon.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		init(v)
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) ~= 0   --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end

	-- Custom settings --
	local cfg = v.data._settings
	local npcConfig = NPC.config[v.id]

	if data.angle > 360 then
		data.angle = data.angle - 360
	end

	data.sprSizex = math.max(data.sprSizex - 0.05, 1)
	data.sprSizey = math.max(data.sprSizey - 0.05, 1)

	-- The 360 Cannon --
	local ballsPShot = cfg.bOptions.shootAmount or npcConfig.shotcount

	-- Calculating angles in vectors and center of NPC --
	local vectorAngle = vector(0, -1):rotate(data.angle)
	local center = vector(v.x + v.width/2, v.y + v.height/2)

	-- Handling shooting --
	if v.ai1 <= 0 then v.ai1 = npcConfig.shotid end
	data.shootTimer = data.shootTimer - 1
	if not data.friendly and data.shootTimer <= 0 then
		for i = 1, ballsPShot do
			-- Spawning the NPC --
			local otherAng = vectorAngle:rotate(i*360/ballsPShot)

			v1 = NPC.spawn(v.ai1, center.x + (otherAng.x * v.width/3), center.y + (otherAng.y * v.height/3), v.section, false, true)

			v1.direction = math.sign(otherAng.x * npcConfig.shotspeed)
			if cfg.bOptions.noblockcollision then
				v1.noblockcollision = true
			end

			v1.speedX, v1.speedY = otherAng.x * npcConfig.shotspeed * cfg.aOptions.multiplier, otherAng.y * npcConfig.shotspeed * cfg.aOptions.multiplier
			v1.layerName = "Spawned NPCs"
			v1.friendly = data.friendly
			v1.data._basegame.speedX = v1.speedX
			v1.data._basegame.speedY = v1.speedY

			v1:mem(0x136, FIELD_BOOL, cfg.aOptions.projectile)

			-- Spawning smoke --
			a1 = Animation.spawn(npcConfig.effectid, v1.x + 0.5 * v1.width + npcConfig.effectoffsetx, v1.y + 0.5 * v1.height + npcConfig.effectoffsety)
			a1.speedX, a1.speedY = v1.speedX, v1.speedY
		end

		if data.shotsFired >= cfg.aOptions.shotsPerRound - 1 then
			data.shootTimer = lunatime.toTicks(cfg.aOptions.roundDelay)
			data.shotsFired = 0
		else
			data.shootTimer = lunatime.toTicks(cfg.aOptions.shootDelay)
			data.shotsFired = data.shotsFired + 1
		end

		SFX.play(npcConfig.shotsound)

		if npcConfig.pulsex then
			data.sprSizex = 1.5
		end

		if npcConfig.pulsey then
			data.sprSizey = 1.5
		end
	end

	-- Aiming and Constant Rotation --
	if cfg.aOptions.pAim then
		local cPlayer = Player.getNearest(center.x, center.y)
		data.chVector = vector((cPlayer.x+cPlayer.width/2) - (center.x), (cPlayer.y+cPlayer.height/2) - (center.y)) -- Thanks 8luestorm for this chunk lol
		data.angle = math.deg(math.atan2(data.chVector.y, data.chVector.x)) + 90
	else
		data.angle = data.angle + data.rotation
	end

	-- Layer Movement --
	npcutils.applyLayerMovement(v)
end

function dirCannon.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	local data = v.data._basegame

	if not data.initialized then
		init(v)
	end

	-- Accessing custom settings --
	local cfg = v.data._settings

	if cfg.bOptions.hidden then
		npcutils.hideNPC(v)
		return
	end

	if v.isHidden then return end

	local npcConfig = NPC.config[v.id]

	-- Setting some properties --
	data.img.x, data.img.y = v.x + 0.5 * v.width + npcConfig.gfxoffsetx, v.y + 0.5 * v.height + npcConfig.gfxoffsety
	data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
	data.img.rotation = data.angle

	local p = -45
	if npcConfig.foreground then
		p = -15
	end

	-- Drawing --
	data.img:draw{frame = v.animationFrame, sceneCoords = true, priority = p}

	npcutils.hideNPC(v)
end

return dirCannon