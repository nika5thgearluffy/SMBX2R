--[[

	From MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local lineguide = require("lineguide")

local numberPlatform = {}
local npcID = NPC_ID


local disappearEffect = 294

local DISAPPEAR_TYPE = {
	DESPAWN = 0,
	DIE = 1,
	RESPAWN = 2,
}


local numberPlatformSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 64,
	height = 56,
	
	frames = 2,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = true,
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

	ignorethrownnpcs = true,
	notcointransformable = true,
	luahandlesspeed = true,



	numberFrames = 10,
	numberWidth = 32,
	numberGap = 20,

	numberColors = {
		Color.fromHexRGB(0xBD2900),
		Color.fromHexRGB(0xFF5A00),
		Color.fromHexRGB(0xA57384),
		Color.fromHexRGB(0x7B5A63),
	},

	containedNPCSpeedX = 0,
	containedNPCSpeedY = -6,

	triggerWeight = 1,
	ignorePlayers = false,
	ignoreNPCs = false,

	disappearEffect = disappearEffect,

	pressedSound = Misc.resolveSoundFile("number-platform-pressed"),
	disappearSound = Misc.resolveSoundFile("number-platform-disappear"),
	countdownSound = Misc.resolveSoundFile("number-platform-countdown"),
	respawnSound = Misc.resolveSoundFile("number-platform-disappear"),

	disappearType = DISAPPEAR_TYPE.DESPAWN,
	spawnedDisappearType = DISAPPEAR_TYPE.DIE,
	respawnDuration = 160,
}

npcManager.setNpcSettings(numberPlatformSettings)
npcManager.registerHarmTypes(npcID,{},nil)


lineguide.registerNpcs(npcID)


function numberPlatform.onInitAPI()
	npcManager.registerEvent(npcID, numberPlatform, "onTickEndNPC")
	npcManager.registerEvent(npcID, numberPlatform, "onDrawNPC")
end


local function initialise(v,data,config,settings)
	data.initialized = true

	data.counter = settings.counter or 1

	data.pressed = false

	data.animationTimer = 0
end

local function handleAnimation(v,data,config)
	if data.pressed then
		data.animationTimer = math.min((config.frames - 2)*config.framespeed + 1,data.animationTimer + 1)
	else
		data.animationTimer = math.max(0,data.animationTimer - 1)
	end

	local frame = math.min(config.frames,math.ceil(data.animationTimer/config.framespeed))

	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
end


local function isOnPlatform(v,o)
	return (o.x+o.width > v.x and o.x < v.x+v.width and o.y+o.height >= v.y-0.01 and o.y+o.height <= v.y+0.1)
end

local function npcCanWeigh(npc)
    if npc.despawnTimer <= 0 or npc.isGenerator or not npc.collidesBlockBottom or npc:mem(0x12C,FIELD_WORD) > 0 or npc:mem(0x138,FIELD_WORD) > 0 then
        return false
    end

    if not npc:mem(0x136,FIELD_BOOL) then
        if npc.noblockcollision then
            return false
        end

        local config = NPC.config[npc.id]
        if config.noblockcollision then
            return false
        end
    end

    return true
end


local function findIsPressed(v,data,config,settings)
	if v.friendly then
		return false
	end

	local weight = 0

	if not config.ignorePlayers then
		for _,p in ipairs(Player.get()) do
			if p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) then
				if p.standingNPC == v or (p:isOnGround() and isOnPlatform(v,p)) then
					weight = weight + p:getWeight()

					if weight >= config.triggerWeight then
						return true
					end
				end
			end
		end
	end

	if not config.ignoreNPCs then
		for _,n in NPC.iterateIntersecting(v.x,v.y - 4,v.x + v.width,v.y + 4) do
			if n ~= v and isOnPlatform(v,n) and npcCanWeigh(n) then
				weight = weight + n:getWeight()

				if weight >= config.triggerWeight then
					return true
				end
			end
		end
	end

	return false
end


function numberPlatform.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
		if data.respawnTimer ~= nil and data.respawnTimer > 0 then
			if v:mem(0x126,FIELD_BOOL) and v:mem(0x128,FIELD_BOOL) then
				data.respawnTimer = nil
			else
				data.respawnTimer = data.respawnTimer - 1

				if data.respawnTimer <= 0 then
					local config = NPC.config[v.id]

					v:mem(0x124,FIELD_BOOL,true)
					v.despawnTimer = 180

					Effect.spawn(config.disappearEffect,v.x + v.width*0.5,v.y + v.height*0.5)
					SFX.play(config.respawnSound)

					data.respawnTimer = nil
				end
			end
		end

		data.initialized = false
		return
	end

	local settings = v.data._settings
	local config = NPC.config[v.id]

	if not data.initialized then
		initialise(v,data,config,settings)
	end


	local isPressed = false

	if v:mem(0x12C,FIELD_WORD) == 0 and not v:mem(0x136,FIELD_BOOL) and v:mem(0x138,FIELD_WORD) == 0 then
		isPressed = findIsPressed(v,data,config,settings)

		local lineguideData = v.data._basegame.lineguide

		if lineguideData == nil or lineguideData.state == lineguide.states.NORMAL then
			v.speedX,v.speedY = npcutils.getLayerSpeed(v)
		end
	end

	if isPressed and not data.pressed then
		-- Just got onto platform
		SFX.play(config.pressedSound)
	elseif not isPressed and data.pressed then
		-- Just got off of platform
		data.counter = data.counter - 1

		if data.counter > 0 then
			SFX.play(config.countdownSound)
		else
			-- Diseappear
			if v.ai1 > 0 then
				local npc = NPC.spawn(v.ai1,v.x + v.width*0.5,v.y + v.height*0.5,v.section,false,true)

				npc.direction = v.direction
				npc.speedX = config.containedNPCSpeedX*npc.direction
				npc.speedY = config.containedNPCSpeedY

				npc.layerName = "Spawned NPCs"
				--npc.friendly = v.friendly

				npc:mem(0x136,FIELD_BOOL,true)
			end
			
			Effect.spawn(config.disappearEffect,v.x + v.width*0.5,v.y + v.height*0.5)
			SFX.play(config.disappearSound)

			local disappearType = config.disappearType
			if v.spawnId == 0 then
				disappearType = config.spawnedDisappearType
			end

			if disappearType == DISAPPEAR_TYPE.DIE then
				v:kill(HARM_TYPE_VANISH)
			else
				if disappearType == DISAPPEAR_TYPE.RESPAWN and v.spawnId > 0 then
					data.respawnTimer = config.respawnDuration
				end

				v:mem(0x124,FIELD_BOOL,false)
				v.despawnTimer = 0
			end
		end
	end

	data.pressed = isPressed

	handleAnimation(v,data,config)
end


local lowPriorityStates = table.map{1,3,4}

local function drawNPC(v,config,offsetX,offsetY,frame,color)
	local texture = Graphics.sprites.npc[v.id].img
	if texture == nil then
		return
	end

	local priority = -56
	if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
		priority = -75
	elseif v:mem(0x12C,FIELD_WORD) > 0 then
		priority = -30
	elseif config.foreground then
		priority = -15
	end

	local width = config.gfxwidth
	local height = config.gfxheight
	local x = v.x + v.width*0.5 - width*0.5 + config.gfxoffsetx + offsetX
	local y = v.y + config.height - height + config.gfxoffsety + offsetY

	Graphics.drawBox{
		texture = texture,priority = priority,color = color,sceneCoords = true,
		x = x,y = y,width = width,height = height,
		sourceX = 0,sourceY = frame*height,
		sourceWidth = width,sourceHeight = height,
	}
end

function numberPlatform.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local config = NPC.config[v.id]
	local data = v.data._basegame

	local settings = v.data._settings

	if not data.initialized then
		initialise(v,data,config,settings)
	end


	drawNPC(v,config,0,0,v.animationFrame,Color.white)

	-- Draw number
	local text = tostring(math.max(1,data.counter))
	local textWidth = (#text - 1)*config.numberGap + config.numberWidth
	local textColor = config.numberColors[math.clamp(data.counter,1,#config.numberColors)]

	local frameOffset = npcutils.getTotalFramesByFramestyle(v)

	for i = 1,#text do
		local frame = string.byte(text[i]) - 48 + frameOffset
		local x = (i-1)*config.numberGap - textWidth*0.5 + config.numberWidth*0.5

		drawNPC(v,config,x,0,frame,textColor)
	end

	npcutils.hideNPC(v)
end


return numberPlatform