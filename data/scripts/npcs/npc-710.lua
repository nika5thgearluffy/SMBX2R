--[[

	From MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local klonoa = require("characters/klonoa")


local hidingLakitu = {}
local npcID = NPC_ID

local deathEffectID = 304

local hidingLakituSettings = {
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
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	idleTime = 48,  -- How long the lakitu stays hiding before it starts rising.
	watchTime = 64, -- How long the lakitu looks left and right before it starts rising again.
	readyTime = 24, -- How long the lakitu waits before throwing an NPC.
	throwTime = 32, -- How long the lakitu is throwing an NPC.

	watchHeight = 20, -- How far out of the pike the lakitu is when watching.

	raiseSpeed = 1,   -- How fast the lakitu raises upwards.
	lowerSpeed = 1.5, -- How fast the lakitu returns to its spawn point.

	throwXSpeed = 1.5, -- How fast the thrown NPC moves horizontally.
	throwYSpeed = -5,  -- How fast the thrown NPC moves vertically.

	changeSize = true, -- Whether or not the NPC's hitbox and graphical size changes when moving.
	becomeFriendly = true, -- Whether or not the NPC should become friendly when fully retracted.

	throwSFX = 25, -- The sound played when the lakitu throws an NPC. Can be nil for none, a number for a vanilla sound, or a sound effect object/string for a custom sound.

	minPlayerDistance = 48, -- The minimum distance from the player to be able to start rising.

	defaultThrowID = 286,

	throwFrames = 1,
	throwFrameSpeed = 8,
}

npcManager.setNpcSettings(hidingLakituSettings)
npcManager.registerDefines(npcID,{NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

klonoa.UngrabableNPCs[npcID] = true

-- Define constants
local DIR_UP   = DIR_LEFT
local DIR_DOWN = DIR_RIGHT

local STATE_IDLE       = 0
local STATE_START_RISE = 1
local STATE_WATCH      = 2
local STATE_FINAL_RISE = 3
local STATE_READY      = 4
local STATE_THROW      = 5
local STATE_LOWER      = 6

local facePlayerStateMap = table.map{STATE_IDLE,STATE_START_RISE,STATE_FINAL_RISE,STATE_READY} -- A map of states the lakitu is able to face the player in

local throwSpecialCases = {
	[12] = function(v,w) v.ai2 = 2 end, -- Podoboo
	[45] = function(v,w) v.ai1 = 1 end, -- Throw block
	[615] = function(v,w) v.data._basegame.ownerBro = w end, -- Boomerang
}

function hidingLakitu.onInitAPI()
	npcManager.registerEvent(npcID,hidingLakitu,"onTickEndNPC")
	npcManager.registerEvent(npcID,hidingLakitu,"onDrawNPC")

	registerEvent(hidingLakitu,"onNPCHarm")
end


local function moveNPC(v,data,config,distance,limit)
	local distanceFromHome = ((v.y + v.height*0.5 + v.height*0.5*data.verticalDirection) - data.home)*data.verticalDirection
	local clampedDistance = math.clamp(distance,-distanceFromHome,limit - distanceFromHome)

	if config.changeSize then
		if data.verticalDirection == DIR_UP then
			v.y = v.y + clampedDistance*data.verticalDirection
		end

		v.height = v.height + clampedDistance
	else
		v.y = v.y + clampedDistance*data.verticalDirection
	end

	return (clampedDistance ~= distance)
end

local function handleAnimation(v,data,config)
	local idleFrames = (config.frames*0.5 - config.throwFrames)
	local frame

	if data.state == STATE_THROW then
		frame = math.min(config.throwFrames - 1,math.floor(data.timer/config.throwFrameSpeed)) + idleFrames
		data.animationTimer = 0
	else
		frame = math.floor(data.animationTimer/config.framespeed) % idleFrames
		data.animationTimer = data.animationTimer + 1
	end

	if data.horizontalDirection == DIR_RIGHT then
		frame = frame + config.frames*0.5
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame,direction = data.verticalDirection})
end

local function initialise(v,data,config,settings)
	if data.originallyFriendly == nil then
		data.originallyFriendly = v.friendly
	else
		v.friendly = data.originallyFriendly
	end

	if settings.horizontalDirection == 2 then
		data.horizontalDirection = DIR_RIGHT
	else
		data.horizontalDirection = DIR_LEFT
	end

	if v.spawnId > 0 then
		data.verticalDirection = v.spawnDirection
		data.home = v.spawnY + v.spawnHeight*0.5 - v.spawnHeight*0.5*data.verticalDirection
	else
		if v.direction ~= 0 then
			data.verticalDirection = v.direction
		elseif v:mem(0x138,FIELD_WORD) == 3 then -- Coming out of the bottom of a block
			data.verticalDirection = DIR_DOWN
		else
			data.verticalDirection = DIR_UP
		end

		data.home = v.y + v.height*0.5 - v.height*0.5*data.verticalDirection
	end

	if not v.friendly and not v.dontMove and v:mem(0x138,FIELD_WORD) == 0 then
		moveNPC(v,data,config,-v.height,config.height)
		data.state = STATE_IDLE
		v.friendly = data.originallyFriendly or config.becomeFriendly
	else
		data.state = STATE_READY
	end
	
	data.timer = 0

	data.animationTimer = 0
end


function hidingLakitu.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	local settings = v.data._settings
	local config = NPC.config[v.id]

	if not data.state then
		initialise(v,data,config,settings)
	end

	
	if v:mem(0x136,FIELD_BOOL) then -- Projectile
		v:harm(HARM_TYPE_NPC)
		return
	elseif v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then -- Held or in a forced state
		data.home = v.y + v.height*0.5 - v.height*0.5*data.verticalDirection

		if v:mem(0x138,FIELD_WORD) ~= 1 then -- from a block
			v.height = config.height
		end

		handleAnimation(v,data,config)
		return
	end


	local layerObj = v.layerObj
	if layerObj ~= nil and not layerObj:isPaused() then
		v.x = v.x + layerObj.speedX
		v.y = v.y + layerObj.speedY
		data.home = data.home + layerObj.speedY
	end


	local n = npcutils.getNearestPlayer(v)
	local playerDistanceX = (n.x + n.width*0.5) - (v.x + v.width*0.5)

	if settings.horizontalDirection == 0 and facePlayerStateMap[data.state] and math.abs(playerDistanceX) > 8 then
		data.horizontalDirection = math.sign(playerDistanceX)
	end
	
	
	data.timer = data.timer + 1

	if data.state == STATE_IDLE then
		if data.timer >= config.idleTime then
			if math.abs(playerDistanceX) > config.minPlayerDistance then
				data.state = STATE_START_RISE
				data.timer = 0

				v.friendly = data.originallyFriendly
			else
				data.timer = 0
			end
		end
	elseif data.state == STATE_START_RISE then
		local atLimit = moveNPC(v,data,config,config.raiseSpeed,config.watchHeight)

		if atLimit then
			data.state = STATE_WATCH
			data.timer = 0
		end
	elseif data.state == STATE_WATCH then
		if data.timer >= config.watchTime then
			data.state = STATE_FINAL_RISE
			data.timer = 0
		elseif data.timer%math.ceil(config.watchTime/3) == 0 then
			data.horizontalDirection = -data.horizontalDirection
		end
	elseif data.state == STATE_FINAL_RISE then
		local atLimit = moveNPC(v,data,config,config.raiseSpeed,config.height)

		if atLimit then
			data.state = STATE_READY
			data.timer = 0
		end
	elseif data.state == STATE_READY then
		if data.timer >= config.readyTime then
			data.state = STATE_THROW
			data.timer = 0
		end
	elseif data.state == STATE_THROW then
		if data.timer == 1 then
			local spawnId = v.ai1
			if spawnId == 0 then
				spawnId = config.defaultThrowID
			end

			local throwConfig = NPC.config[spawnId]

			local spawnY
			if data.verticalDirection == DIR_UP then
				spawnY = v.y + v.height - throwConfig.height*0.5
			else
				spawnY = v.y + throwConfig.height*0.5
			end

			local w = NPC.spawn(spawnId,v.x + v.width*0.5,spawnY,v.section,false,true)

			w.layerName = "Spawned NPCs"
			w.friendly = data.originallyFriendly

			w.direction = data.horizontalDirection
			w.speedX = config.throwXSpeed*data.horizontalDirection

			if not throwConfig.nogravity then
				w.speedY = -config.throwYSpeed*data.verticalDirection
			end
			if throwConfig.harmlessthrown then
				w:mem(0x136,FIELD_BOOL,true)
			end
			if throwConfig.iscoin then
				w.ai1 = 1
			end

			if throwSpecialCases[w.id] then
				throwSpecialCases[w.id](w,v)
			end

			if config.throwSFX then
				SFX.play(config.throwSFX)
			end
		elseif data.timer >= config.throwTime then
			if v.dontMove then
				data.state = STATE_READY
			else
				data.state = STATE_LOWER
			end

			data.timer = 0
		end
	elseif data.state == STATE_LOWER then
		local atLimit = moveNPC(v,data,config,-config.lowerSpeed,config.height)

		if atLimit then
			data.state = STATE_IDLE
			data.timer = 0

			v.friendly = data.originallyFriendly or config.becomeFriendly
		end
	end

	v.speedX = 0
	v.speedY = 0

	handleAnimation(v,data,config)
end

function hidingLakitu.onDrawNPC(v)
	if v.despawnTimer <= 0 then
		npcutils.hideNPC(v)
		return
	end

	if v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL) or v:mem(0x138,FIELD_WORD) > 0 then
		return
	end

	local settings = v.data._settings
	local config = NPC.config[v.id]
	local data = v.data._basegame

	if not data.state then
		initialise(v,data,config,settings)
	end

	local priority = -75
	if config.foreground then
		priority = -15
	end

	local gfxheight = config.gfxheight
	local yOffset = 0
	local sourceY = 0

	if config.changeSize then
		local difference = (config.height - v.height)

		if difference > 0 then
			gfxheight = gfxheight - difference
			yOffset = yOffset + difference

			if data.verticalDirection == DIR_DOWN then
				sourceY = sourceY + difference
			end
		end
	end


	if gfxheight > 0 then
		npcutils.drawNPC(v,{yOffset = yOffset,height = gfxheight,sourceY = sourceY,priority = priority})
	end

	--Text.print(v.friendly,v.x - camera.x,v.y - camera.y)

	npcutils.hideNPC(v)
end


function hidingLakitu.onNPCHarm(eventObj,v,reason)
	if v.id == npcID then
		if v.width == 0 or v.height == 0 then
			eventObj.cancelled = true
			return
		end
	end
end


return hidingLakitu