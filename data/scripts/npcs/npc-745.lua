--[[

	Written by MrDoubleA
	Please give credit!

	Credit to Saturnyoshi for starting to make "newplants" and creating most of the graphics used

	Edited by MegaDood

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local piranhaPlant = {}
local npcID = NPC_ID

local piranhaPlantSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 56,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 56,
	
	frames = 1,
	framestyle = 1,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	movementSpeed = 1.5,   -- How fast the NPC moves when coming out or retracting back.
	hideTime      = 64,    -- How long the NPC rests before coming out.
	restTime      = 128,    -- How long the NPC rests before retracting back.
	ignorePlayers = true, -- Whether or not the NPC can come out, even if there's a player in the way.
	
	isHorizontal = false, -- Whether or not the NPC is horizontal.
}

npcManager.setNpcSettings(piranhaPlantSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local STATE_HIDE  = 0
local STATE_RISE  = 1
local STATE_REST  = 2
local STATE_LOWER = 3

local DIR_UP_LEFT    = DIR_LEFT
local DIR_DOWN_RIGHT = DIR_RIGHT


local function getInfo(v)
	local config = NPC.config[v.id]
	local data = v.data

	local settings = v.data._settings

	local configSettings = settings.config
	if not configSettings.override then
		configSettings = config
	end
	
	return config,data,settings,configSettings
end

local function getDirectionInfo(v)
	return "y","spawnY","height","speedY",  "gfxheight","sourceY","yOffset"
end

local function spawnUp(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	SFX.play(22)
	local spawnID = v.ai1
	if spawnID == 0 then
		spawnID = 746
	end
	if v.x >= plr.x then
		local n = NPC.spawn(spawnID, v.x - v.width * 0.5 - 15 * (1 + v.direction), v.y + 11, player.section, false, true)
		Animation.spawn(10,n.x + 10,n.y - 5) 
		n.direction = DIR_LEFT
		n.speedX = 4 * n.direction
	elseif v.x < plr.x then
		local n = NPC.spawn(spawnID, v.x - v.width * -0.5 + 16 * (1 - v.direction), v.y + 11, player.section, false, true)
		Animation.spawn(10,n.x - 10,n.y - 5) 
		n.direction = DIR_RIGHT
		n.speedX = 4 * n.direction
	end
end

local function spawnDown(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	SFX.play(22)
	local spawnID = v.ai1
	if spawnID == 0 then
		spawnID = 746
	end
	if v.x >= plr.x then
		local n = NPC.spawn(spawnID, v.x - v.width * -0.5 - 16 * (1 + v.direction), v.y + 44, player.section, false, true)
		n.direction = DIR_LEFT
		Animation.spawn(10,n.x + 10,n.y - 5)
		n.speedX = 4 * n.direction
	elseif v.x < plr.x then
		local n = NPC.spawn(spawnID, v.x - v.width * -1.5 + 15 * (1 - v.direction), v.y + 44, player.section, false, true)
		n.direction = DIR_RIGHT
		Animation.spawn(10,n.x - 10,n.y - 5)
		n.speedX = 4 * n.direction
	end
end


local function move(v,distance)
	local config,data,settings,configSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)


	local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)

	tip = tip + (distance*data.direction)

	-- Make sure to keep the position in a valid range
	local upPosition = (data.home+(config[size]*data.direction))
	local downPosition = data.home

	if math.sign(downPosition-tip) == data.direction then
		tip = downPosition
	elseif math.sign(upPosition-tip) == -data.direction and not config.isJumping then
		tip = upPosition
	end


	-- Reapply the position
	if settings.changeSize then
		v[size] = math.min(math.abs(data.home-tip),config[size])
	end

	v[position] = tip-((v[size]/2)*data.direction)-(v[size]/2)
end

local function initialise(v)
	local config,data,settings,configSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	if v.spawnId > 0 then
		data.direction = v.spawnDirection
		data.home = (v[spawnPosition]+(v[size]/2))-((v[size]/2)*data.direction)
	else
		data.direction = v.direction
		data.home = v[position]-(v[size]*data.direction)
	end

	if not v.friendly then
		data.state = STATE_RISE
		move(v,-v[size])
	else
		data.state = STATE_REST
	end

	data.timer = 0
	data.animationTimer = 0
end


local function canComeOut(v,direction)

	local width,height = 32,300
		
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


function piranhaPlant.onInitAPI()
	npcManager.registerEvent(npcID, piranhaPlant, "onTickNPC")
	npcManager.registerEvent(npcID, piranhaPlant, "onTickEndNPC")
	npcManager.registerEvent(npcID, piranhaPlant, "onDrawNPC")
end


function piranhaPlant.onTickNPC(v)
	if Defines.levelFreeze then return end

	local config,data,settings,configSettings,fireSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	if data.state == STATE_REST then
		if v.direction == -1 then
			if configSettings.restTime > 32 then
				if data.timer == configSettings.restTime - 32 then
					spawnUp(v)
				end
			else
				if data.timer == 1 then
					spawnUp(v)
				end
			end
		else
			if configSettings.restTime > 32 then
				if data.timer == configSettings.restTime - 32 then
					spawnDown(v)
				end
			else
				if data.timer == 1 then
					spawnDown(v)
				end
			end
		end
	end
end


function piranhaPlant.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local config,data,settings,configSettings,fireSettings = getInfo(v)
	local position,spawnPosition,size,speed = getDirectionInfo(v)

	
	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	if not data.state then
		initialise(v)
	end

	if v:mem(0x136,FIELD_BOOL) or v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then -- If in a projectile state, PANIC!
		v:kill(HARM_TYPE_NPC)
		return
	end

	
	if v.layerObj ~= nil and not Layer.isPaused() then
		v.x = v.x + v.layerObj.speedX
		v.y = v.y + v.layerObj.speedY
		data.home = data.home + v.layerObj[speed]
	end

	if data.state == STATE_HIDE then
		data.timer = data.timer + 1

		if data.timer > configSettings.hideTime and (canComeOut(v,data.direction) or configSettings.ignorePlayers) then
			data.state = STATE_RISE
			data.timer = 0
		end
	elseif data.state == STATE_RISE then
		local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)
		local topPosition = data.home+(config[size]*data.direction)

		if tip == topPosition then
			data.state = STATE_REST
			data.timer = 0
		else
			move(v,data.jumpSpeed or configSettings.movementSpeed)
		end
	elseif data.state == STATE_REST then
		if not v.friendly then
			data.timer = data.timer + 1
			if data.timer > configSettings.restTime and not v.friendly then
				data.state = STATE_LOWER
				data.timer = 0
			end
		end
	elseif data.state == STATE_LOWER then
		local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)

		if tip == data.home then
			data.state = STATE_HIDE
			data.timer = 0
		else
			move(v,data.jumpSpeed or -configSettings.movementSpeed)
		end
	end

	--npcutils.faceNearestPlayer(v)

	--Colliders.Box(v.x,v.y,v.width,v.height):Draw(Color.red.. 0.25)
	--Colliders.Box(v.x,data.home,v.width,16):Draw(Color.purple.. 0.5)
end

function piranhaPlant.onDrawNPC(v)
	if v.despawnTimer <= 0 or v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then return end

	local config,data,settings,configSettings = getInfo(v)
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
	if settings.changeSize then
		local round = math.ceil
		if data.direction == DIR_DOWN_RIGHT then
			round = math.floor
		end

		local tip = (v[position]+(v[size]/2))+((v[size]/2)*data.direction)

		graphicsSize = math.min(math.abs(data.home-tip),graphicsSize)
		offset = round(-graphicsSize+config[size])

		source = offset*((data.direction+1)*0.5)
	end
	

	npcutils.drawNPC(v,{[positionOffset] = offset,[size] = graphicsSize,[sourcePosition] = source,priority = priority})
	npcutils.hideNPC(v)
end


return piranhaPlant