--[[

	Credit to Saturnyoshi for making "newplants" and creating most of the graphics used

	From MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local piranhaPlant = {}

piranhaPlant.idMap  = {}
piranhaPlant.idList = {}


local STATE_HIDE  = 0
local STATE_RISE  = 1
local STATE_REST  = 2
local STATE_LOWER = 3

local DIR_UP_LEFT    = DIR_LEFT
local DIR_DOWN_RIGHT = DIR_RIGHT


local function getInfo(v)
	local config = NPC.config[v.id]
	local data = v.data._basegame

	local settings = v.data._settings

	return config,data,settings
end
local function getDirectionInfo(v)
	if NPC.config[v.id].isHorizontal then
		return "x","spawnX","width" ,"speedX",  "gfxwidth" ,"sourceX","xOffset"
	else
		return "y","spawnY","height","speedY",  "gfxheight","sourceY","yOffset"
	end
end


local function canComeOut(v,direction,isHorizontal)
	local width,height
	if not isHorizontal then
		width,height = 32,300
	else
		width,height = 300,32
	end

	for _,playerObj in ipairs(Player.get()) do
		if  playerObj.deathTimer == 0 and not playerObj:mem(0x13C,FIELD_BOOL) -- If alive
		and (v.x) <= (playerObj.x+playerObj.width +width ) and (v.x+v.width ) >= (playerObj.x-width )
		and (v.y) <= (playerObj.y+playerObj.height+height) and (v.y+v.height) >= (playerObj.y-height)
		then
			return false
		end
	end

	return true
end


local function move(v,distance)
	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)


	local tip = (v[position] + v[size]*0.5) + (v[size]*0.5*data.direction)

	tip = tip + distance*data.direction

	-- Make sure to keep the position in a valid range
	local upPosition = (data.home+(config[size]*data.direction))
	local downPosition = data.home

	if math.sign(downPosition-tip) == data.direction then
		tip = downPosition
	elseif math.sign(upPosition-tip) == -data.direction and not config.isJumping then
		tip = upPosition
	end


	-- Reapply the position
	if config.changeSize then
		v[size] = math.min(math.abs(data.home-tip),config[size])
	end

	v[position] = tip-((v[size]/2)*data.direction)-(v[size]/2)
end

local function initialise(v)
	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	if v.spawnId > 0 then
		data.direction = v.spawnDirection
		data.home = v[spawnPosition] + v[size]*0.5 - v[size]*0.5*data.direction
	else
		if v.direction ~= 0 then
			data.direction = v.direction
		elseif v:mem(0x138,FIELD_WORD) == 3 then -- Coming out of the bottom of a block
			data.direction = DIR_DOWN_RIGHT
		else
			data.direction = DIR_UP_LEFT
		end

		data.home = v[position] + v[size]*0.5 - v[size]*0.5*data.direction
	end

	if data.originallyFriendly == nil then
		data.originallyFriendly = v.friendly
	else
		v.friendly = data.originallyFriendly
	end

	if not data.originallyFriendly and not v.dontMove and v:mem(0x138,FIELD_WORD) == 0 then
		move(v,-v[size])

		if canComeOut(v,data.direction,config.isHorizontal) then
			data.state = STATE_RISE
		else
			data.state = STATE_HIDE
			v.friendly = v.friendly or config.becomeFriendly
		end
	else
		data.state = STATE_REST
	end

	data.timer = 0
	data.animationTimer = 0

	data.jumpSpeed = nil -- Used by jumping piranha plants
end


local function handleAnimation(v)
	local config,data,settings = getInfo(v)

	data.animationTimer = data.animationTimer + 1


	local frame = math.floor(data.animationTimer/config.framespeed)

	if config.isVenusFireTrap then
		frame = frame % (config.frames*0.25)

		-- Face any nearby players
		local playerObj = npcutils.getNearestPlayer(v)

		if playerObj ~= nil then
			local distance = vector(
				(playerObj.x+(playerObj.width /2))-(v.x+(v.width /2)),
				(playerObj.y+(playerObj.height/2))-(v.y+(v.height/2))
			)

			if distance.x > 0 then
				frame = frame+(config.frames/2)
			end
			if distance.y < 0 then
				frame = frame+(config.frames/4)
			end
		end
	elseif config.fireSpitFrames ~= nil then
		local spitAnimationDuration = config.fireSpitFrames*config.fireSpitFrameSpeed
		local totalSpitTime = settings.fireSpurtDelay*settings.fireSpurts-- + spitAnimationDuration

		local spitTimer = data.timer - config.restTime*0.5
		local spitFrameTimer = spitTimer % settings.fireSpurtDelay

		if data.state == STATE_REST and spitTimer >= 0 and spitTimer < totalSpitTime and spitFrameTimer < spitAnimationDuration then
			frame = math.min(config.fireSpitFrames - 1,math.floor(spitFrameTimer/config.fireSpitFrameSpeed))
			data.animationTimer = 0
		else
			local neutralFrames = config.frames - config.fireSpitFrames

			frame = (frame % neutralFrames) + config.fireSpitFrames
		end
	else
		frame = frame % config.frames
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame,direction = data.direction})
end
local function doFireSpurt(v,spurtNumber)
	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)


	local fireID = settings.fireID
	if fireID == 0 then
		fireID = config.defaultFireID
	end

	if fireID == 0 then
		return
	end


	for i = 1,settings.firePerSpurt do
		local spawnPosition = vector(v.x + v.width*0.5,v.y + v.height*0.5)
		spawnPosition[position] = spawnPosition[position] + v[size]*0.25*data.direction


		--local totalIndex = (spurtNumber - 1)*math.ceil(settings.firePerSpurt*0.5) + math.abs(index)
		--local angle = (settings.fireAngle*totalIndex)*math.sign(index)

		local angle
		if settings.firePerSpurt > 1 then
			local align = (i - 1) - (settings.firePerSpurt - 1)*0.5

			angle = settings.fireAngle*(align + (spurtNumber - 1)*math.sign(align))
		else
			local n = Player.getNearest(spawnPosition.x,spawnPosition.y)

			if (n.x + n.width*0.5) < spawnPosition.x then
				angle = -settings.fireAngle
			else
				angle = settings.fireAngle
			end
		end

		local speed = vector(0,0)
		speed[position] = (settings.fireSpeed*data.direction)
		speed = speed:rotate(angle)


		local fire = NPC.spawn(fireID,spawnPosition.x,spawnPosition.y,v.section,false,true)

		if speed.x ~= 0 then
			fire.direction = math.sign(speed.x)
		else
			npcutils.faceNearestPlayer(fire)
		end

		fire.speedX = speed.x
		fire.speedY = speed.y

		fire.layerName = "Spawned NPCs"
		fire.friendly = data.originallyFriendly
	end

	if config.fireSound ~= nil and config.fireSound ~= 0 then
		SFX.play(config.fireSound)
	end
end


function piranhaPlant.registerPlant(id)
	npcManager.registerEvent(id,piranhaPlant,"onTickEndNPC")
	npcManager.registerEvent(id,piranhaPlant,"onDrawNPC")

    piranhaPlant.idMap[id] = true
    table.insert(piranhaPlant.idList,id)
end


function piranhaPlant.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	
	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	if not data.state then
		initialise(v)
	end

	--Text.print(v.height,v.x-camera.x,v.y-camera.y)
	--Colliders.Box(v.x,v.y,v.width,v.height):Draw(Color.red.. 0.25)
	--Colliders.Box(v.x,data.home,v.width,16):Draw(Color.purple.. 0.5)

	if v:mem(0x136,FIELD_BOOL) then -- If in a projectile state, PANIC!
		v:kill(HARM_TYPE_NPC)
		return
	elseif v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then -- Held or in a forced state
		data.home = v[position] + v[size]*0.5 - v[size]*0.5*data.direction

		if v:mem(0x138,FIELD_WORD) ~= 1 then -- from a block
			v[size] = config[size]
		end

		handleAnimation(v)
		return
	end


	local layerObj = v.layerObj
	
	if layerObj ~= nil and not layerObj:isPaused() then
		local xMultiplier = 1
		local yMultiplier = 1
		if config.isJumping then
			if config.isHorizontal then
				xMultiplier = 0
			else
				yMultiplier = 0
			end
		end
		v.x = v.x + layerObj.speedX * xMultiplier
		v.y = v.y + layerObj.speedY * yMultiplier
		data.home = data.home + layerObj[speed]
	end

	if data.state == STATE_HIDE then
		data.timer = data.timer + 1

		if data.timer > config.hideTime and (canComeOut(v,data.direction,config.isHorizontal) or config.ignorePlayers) then
			data.state = STATE_RISE
			data.timer = 0

			v[position] = data.home - v[size] * 0.5 - (v[size]*0.5*data.direction)
			v.friendly = data.originallyFriendly
		end
	elseif data.state == STATE_RISE then
		local tip = (v[position] + v[size]*0.5) + (v[size]*0.5*data.direction)
		local topPosition = data.home+(config[size]*data.direction)

		if tip == topPosition or (data.jumpSpeed and data.jumpSpeed > 0) then
			data.state = STATE_REST
			data.timer = 0

			data.jumpSpeed = nil
		elseif config.isJumping then
			data.jumpSpeed = (data.jumpSpeed or config.jumpStartSpeed) + config.jumpRisingGravity
			move(v,-data.jumpSpeed)
		else
			move(v,config.movementSpeed)
		end
	elseif data.state == STATE_REST then
		if not data.originallyFriendly and not v.dontMove then
			data.timer = data.timer + 1

			local restTime = config.restTime

			if config.defaultFireID ~= nil and (config.defaultFireID ~= 0 or settings.fireID ~= 0) then
				local currentSpurt = math.floor(data.timer - restTime*0.5 + 0.5)/math.max(1,settings.fireSpurtDelay) + 1

				if currentSpurt == math.floor(currentSpurt) and currentSpurt >= 1 and currentSpurt <= settings.fireSpurts then
					doFireSpurt(v,currentSpurt)
				end

				restTime = restTime + settings.fireSpurts*settings.fireSpurtDelay
				--restTime = restTime + (settings.fireSpurts - 1)*settings.fireSpurtDelay
			end

			if data.timer > restTime then
				data.state = STATE_LOWER
				data.timer = 0
			end
		end
	elseif data.state == STATE_LOWER then
		local tip = (v[position] + v[size]*0.5) + (v[size]*0.5*data.direction)

		if (v.direction == 1 and tip <= data.home) or (v.direction == -1 and tip >= data.home) then
			data.state = STATE_HIDE
			data.timer = 0

			data.jumpSpeed = nil

			v.friendly = data.originallyFriendly or config.becomeFriendly
		elseif config.isJumping then
			data.jumpSpeed = math.min(config.jumpMaxSpeed,(data.jumpSpeed or 0) + config.jumpFallingGravity)
			move(v,-data.jumpSpeed)
		else
			move(v,-config.movementSpeed)
		end
	end

	handleAnimation(v)
end

function piranhaPlant.onDrawNPC(v)
	if v.despawnTimer <= 0 then
		npcutils.hideNPC(v)
		return
	end

	if v:mem(0x12C,FIELD_WORD) ~= 0 or v:mem(0x138,FIELD_WORD) > 0 then
		return
	end

	local config,data,settings = getInfo(v)
	local position,spawnPosition,size,speed, gfxSize,sourcePosition,positionOffset = getDirectionInfo(v)

	if not data.state then
		initialise(v)
	end
	

	-- Determine priority
	local priority = -75
	if config.foreground then
		priority = -15
	end

	-- Determine how much of the image to show
	local graphicsSize,offset,source = config[gfxSize],0,0
	if config.changeSize then
		local difference = (config[size] - v[size])

		if difference > 0 then
			graphicsSize = graphicsSize - difference

			if config.isHorizontal then
				offset = offset + difference*0.5
			else
				offset = offset + difference
			end

			if data.direction == DIR_DOWN_RIGHT then
				source = source + difference
			end
		end
	end
	
	if graphicsSize > 0 then
		npcutils.drawNPC(v,{[positionOffset] = offset,[size] = math.floor(graphicsSize),[sourcePosition] = source,priority = priority})
	end

	npcutils.hideNPC(v)
end


function piranhaPlant.onNPCHarm(eventObj,v,reason,culprit)
	if not piranhaPlant.idMap[v.id] then
		return
	end

	if v.width == 0 or v.height == 0 then
		eventObj.cancelled = true
		return
	end

	if reason == HARM_TYPE_SPINJUMP and type(culprit) == "Player" then
		-- Piranha plants can be killed by boot stomps/statue stomps, but not by spin jumps/yoshi stomps
		if culprit:mem(0x50,FIELD_BOOL) or culprit.mount == MOUNT_YOSHI then
			eventObj.cancelled = true
			return
		end
	end
end

function piranhaPlant.onInitAPI()
	registerEvent(piranhaPlant,"onNPCHarm")
end


return piranhaPlant