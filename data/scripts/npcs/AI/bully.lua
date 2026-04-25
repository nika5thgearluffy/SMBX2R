--[[

	From MrDoubleA's NPC Pack

	Graphics by MatiasNTRM

]]

local npcManager = require("npcManager")

local bully = {}

local bullyMap = {}
local npcID = NPC_ID

local bumper = require("npcs/ai/bumper")
local springs = require("npcs/ai/springs")

local defaultSettings = {
    wanderframes = 2,      -- Number of wander frames. Remainder is number of knockback frames

	wanderspeed    = 1,  -- The speed that the NPC wanders around its spawn position at.
	wanderdistance = 96, -- The maximum distance that the NPC can normally wander from its spawn position.

	startchasedistance = 160, -- The distance a player needs to be in for the NPC to start chasing them.
	stopchasedistance  = 224, -- The distance a player needs to be in for the NPC to continue chasing them.
	stopchasecooldown = 60, -- frames for player to be out of sotpchasedistance for the chase to really stop

	chasespeed        = 3.5,  -- The maximum speed the NPC will chase a player at.
	chaseacceleration = 0.08, -- How fast the NPC accelerates while chasing a player.

    knockbackspeed    = 5, -- The speed at which the NPC gets knocked back when bumped
    knockbackfalloff  = 0.085, -- By how much the knockback is decreased each frame
    otherknockbackspeed = 6.5, -- The speed at which the colliding object gets knocked back

    noticebounce = 4, -- The bounce speed when noticing a player

    chasehitblocks = 0, -- Whether and how to hit blocks when knocked back.
    knockbackhitblocks = 0, -- Whether and how to hit blocks when knocked back.
    -- 0 is no effect
    -- 1 hits any block
    -- 2 breaks certain blocks and hits others
}

local STATE_WANDER = 0
local STATE_CHASE  = 1
local STATE_HIT    = 2
local STATE_SINK   = 3

local function bumpBumper(v, w)
	local data = v.data._basegame
	local direction = data.direction or v.direction

	if w then
		direction = (math.sign((w.x+(w.width/2))-(v.x+(v.width/2))))
	end

	data.state = STATE_HIT

	v.speedX = -NPC.config[v.id].knockbackspeed*direction

	data.direction = direction

	return true
end

function bully.register(id, settings)
    bullyMap[id] = true
	bumper.registerDirectionFlip(id, bumpBumper)
	springs.registerHorizontalBounceResponse(id, bumpBumper)
    npcManager.setNpcSettings(table.join(settings,defaultSettings))
	npcManager.registerEvent(id,bully,"onTickNPC")
	npcManager.registerEvent(id,bully,"onDrawNPC")
end

local colBox = Colliders.Box(0,0,0,0)
local colPoint = Colliders.Point(0,0)

local function updateHomePosition(v)
	local data = v.data._basegame

	data.home = vector(v.x+(v.width/2),v.y+(v.height/2))
	data.homeDirection = v.direction
end

function bully.onInitAPI()
	registerEvent(bully,"onNPCHarm")
end

local function init(v, data)
	data.state = STATE_WANDER
	data.timer = 0

	if v.spawnId > 0 then
		data.home = vector(v.spawnX+(v.spawnWidth/2),v.spawnY+(v.spawnHeight/2))
		data.homeDirection = v.spawnDirection
	else
		updateHomePosition(v)
	end

	data.direction = v.direction

	data.animationTimer = 0
end

function bully.onNPCHarm(eventObj,v,reason,w)
	if (not bullyMap[v.id]) or (reason == HARM_TYPE_OFFSCREEN or reason == HARM_TYPE_HELD or reason == HARM_TYPE_PROJECTILE_USED) or (reason == HARM_TYPE_NPC and v:mem(0x134, FIELD_WORD) == 0) then return end

	local data = v.data._basegame

	if not data.state then
		init(v, data)
	end

	if reason == HARM_TYPE_LAVA then
		if data.state ~= STATE_SINK then
			data.state = STATE_SINK
			data.timer = 0

			v.noblockcollision = true
			v.spawnId = 0
		end
	elseif data.state ~= STATE_SINK then
		local direction = data.direction or v.direction

		if w then
			direction = (math.sign((w.x+(w.width/2))-(v.x+(v.width/2))))
            if (type(w) == "NPC") then
                w.direction = direction
                w.speedX = NPC.config[v.id].otherknockbackspeed*direction
            end
		end

		data.state = STATE_HIT

		v.speedX = -NPC.config[v.id].knockbackspeed*direction
		if reason == HARM_TYPE_FROMBELOW then
			v.speedY = -5
			v.speedX = 0
		end
		data.direction = direction

		SFX.play(3)
	end

	eventObj.cancelled = true
end

function bully.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.data._basegame.animationTimer == nil then
		return
	end

    local data = v.data._basegame
	local config = NPC.config[v.id]
	
	if data.state == STATE_HIT or v.isProjectile then
		v.animationFrame = config.wanderframes+(math.floor(data.animationTimer/config.framespeed)%(config.frames-config.wanderframes))
	else
		local framespeed = config.framespeed

		if data.state == STATE_CHASE or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
			framespeed = framespeed/2
		end

		v.animationFrame = math.floor(data.animationTimer/framespeed)%config.wanderframes
	end

	if config.framestyle >= 1 and (data.direction == DIR_RIGHT) then
		v.animationFrame = v.animationFrame+(config.frames)
	end
	if config.framestyle >= 2 and (v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)) then
		v.animationFrame = v.animationFrame+(config.frames*2)
	end
end

local function hitBlocks(v, hitNum)
    if hitNum == 0 then return end
    local data = v.data._basegame
    for k,b in Block.iterateIntersecting(
            v.x + v.speedX,
            v.y + v.speedY + 2,
            v.x + v.width + v.speedX,
            v.y + v.height + v.speedY - 2) do
        if (not b.isHidden) and b.y <= v.y + v.height and Block.SOLID_MAP[b.id] and (not b:mem(0x5A, FIELD_BOOL)) then
            if hitNum > 1 and (Block.MEGA_SMASH_MAP[b.id] or Block.MEGA_HIT_MAP[b.id]) then
                b:remove(true)
                v.speedX = v.speedX * 0.9
            else
                b:hit()
            end
        end
    end
end

function bully.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
		data.state = nil
		data.timer = nil

		data.home = nil
		data.homeDirection = nil

		data.direction = nil

		data.animationTimer = nil
		return
	end

	if not data.state then
		init(v, data)
	end

	data.animationTimer = data.animationTimer + 1

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_WANDER
		data.timer = 0

		data.direction = v.direction

		updateHomePosition(v)

		return
	end

	local distanceFromHomeX = (data.home.x-(v.x+(v.width/2)))

	-- Player collision
    if not v.friendly then
        for _,w in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
            if w.forcedState == 0 and w.deathTimer == 0 and not w:mem(0x13C,FIELD_BOOL) and v:mem(0x130,FIELD_WORD) ~= w.idx then
                local direction = (math.sign((w.x+(w.width/2))-(v.x+(v.width/2))))

                w:mem(0x138,FIELD_FLOAT,NPC.config[v.id].otherknockbackspeed*direction)

                data.state = STATE_HIT

                v.speedX = -config.knockbackspeed*direction
                data.direction = direction

                SFX.play(3)
            end
        end
    end


	if v.isProjectile then
		data.state = STATE_WANDER
		data.timer = 0

		data.direction = v.direction

		updateHomePosition(v)

		return
	end


	if data.state == STATE_WANDER then
		v.speedX = config.wanderSpeed*data.direction

		if v:mem(0x120,FIELD_BOOL) and (v.collidesBlockLeft or v.collidesBlockRight) then
			updateHomePosition(v)
		elseif math.abs(distanceFromHomeX) > config.wanderDistance then
			data.direction = math.sign(distanceFromHomeX)
		end

		local n = Player.getNearest(v.x+(v.width/2),v.y+(v.height/2))

		if n then
			local distanceX = (n.x+(n.width /2))-(v.x+(v.width /2))
			local distanceY = (n.y+(n.height/2))-(v.y+(v.height/2))

			local distance = math.abs(distanceX)+math.abs(distanceY)

			if distance < config.startChaseDistance then
				if v.collidesBlockBottom then
					v.speedY = -config.noticebounce
					data.hasLanded = false
				end

				v.speedX = 0

				data.chasingPlayer = n

				data.state = STATE_CHASE
				data.timer = 0

				data.direction = math.sign(distanceX)
			end
		end
	elseif data.state == STATE_CHASE then
		local exit = (not data.chasingPlayer or not data.chasingPlayer.isValid or data.chasingPlayer.forcedState > 0 or data.chasingPlayer.deathTimer > 0 or data.chasingPlayer:mem(0x13C,FIELD_BOOL))
	
		local distanceX = (data.chasingPlayer.x+(data.chasingPlayer.width /2))-(v.x+(v.width /2))
		local distanceY = (data.chasingPlayer.y+(data.chasingPlayer.height/2))-(v.y+(v.height/2))

		local distance = math.abs(distanceX)+math.abs(distanceY)

		exit = (distance > config.stopChaseDistance)

		if not v.collidesBlockBottom and not data.hasLanded then
			v.speedX = 0
			return
		end
		data.hasLanded = true
		v.speedX = math.clamp((v.speedX+(math.sign(distanceX)*config.chaseAcceleration)),-config.chaseSpeed,config.chaseSpeed)
		data.direction = math.sign(distanceX)

		colPoint.x = (v.x+(v.width/2))+(4 *math.sign(v.speedX))
		colPoint.y = (v.y+v.height - 2)

		local turn = true

		hitBlocks(v, config.chasehitblocks)

		local blockList = {}
		for k,b in Block.iterateIntersecting(colPoint.x, colPoint.y, colPoint.x + 1, colPoint.y + v.height + 16) do
			if not b.isHidden and not b:mem(0x5A, FIELD_BOOL) then
				local fs = Block.config[b.id].floorslope
				if (fs == -1 and b.y >= v.y + v.height - b.height)
				or (fs >= 0 and b.y >= v.y - b.height) then
					table.insert(blockList, b)
				end
			end
		end
		if #blockList > 0 then
			local c, p, _, b = Colliders.raycast(colPoint, vector.down2 * (v.height + 16), blockList)
			if not c then
				c, p, _, b = Colliders.raycast(vector(colPoint.x + 1, colPoint.y), vector.down2 * (v.height + 16), blockList)
			end
			if c then
				local compareY = b.y
				local fs = Block.config[b.id].floorslope
				local tolerance = 4
				local steepness = 1
				local x = v.x
				if fs ~= 0 then
					steepness = (b.height/b.width)
					local travelDistance = math.abs(v.speedX)
					tolerance = tolerance + (travelDistance + 0.5 * v.height) * steepness
					if fs < 0 then
						compareY = compareY + b.height - steepness * ((v.x + v.width)-b.x)
						x = v.x + v.width
					else
						compareY = compareY + steepness * (v.x - b.x)
					end
					compareY = math.max(compareY, v.y + v.height)
				else
					if v:mem(0x22, FIELD_WORD) > 0 then
						tolerance = b.y - (v.y + v.height)
					end
					compareY = v.y + v.height
				end
				if math.abs(p.y - compareY)/(v.width/32) < tolerance then
					turn = false
				end
			end
		end

		if turn then
			v.speedX = 0
		end

		if exit then
			data.timer = data.timer + 1
			if data.timer >= config.stopchasecooldown then
				data.state = STATE_WANDER
				data.timer = 0

				data.chasingPlayer = nil
			end
		else
			data.timer = 0
		end
	elseif data.state == STATE_HIT then
		v.speedX = v.speedX - (math.sign(v.speedX)*config.knockbackfalloff)

		local e = Effect.spawn(74,0,0)

		e.x = v.x+(v.width/2)+(e.width/2)-v.speedX+RNG.random(-v.width/10,v.width/10)
		e.y = v.y+v.height-e.height * 0.5

        hitBlocks(v, config.knockbackhitblocks)

		if math.abs(v.speedX) <= 0.5 then
			data.state = STATE_WANDER
			data.timer = 0
			
			v.speedX = 0
		end

		SFX.play(10)
	elseif data.state == STATE_SINK then
		data.timer = data.timer + 1

		if data.timer%16 == 0 then
			SFX.play(16)
		end

		v.speedX,v.speedY = 0,0.45

		if not config.nogravity and v.underwater and not config.nowaterphysics then
			v.speedY = v.speedY - (Defines.npc_grav/5)
		elseif not config.nogravity then
			v.speedY = v.speedY - (Defines.npc_grav)
		end

		colBox.x,colBox.y = v.x,v.y-1
		colBox.width,colBox.height = v.width,1

		if #Colliders.getColliding{a = colBox,b = Block.LAVA,btype = Colliders.BLOCK,collisionGroup = v.collisionGroup} > 0
		or #Colliders.getColliding{a = v     ,b = Block.LAVA,btype = Colliders.BLOCK,collisionGroup = v.collisionGroup} == 0 and data.timer > 1
		then
			v:kill(HARM_TYPE_LAVA)
		end
	end
end

return bully