--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local flameChomp = {}
--Defines NPC config for our NPC. You can remove superfluous definitions.
local sharedSettings = {
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 5,
	framestyle = 1,
	framespeed = 8,
	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = true,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	nowalldeath = true,

	grabside=false,
	grabtop=false,

    idletime = 150,
    explodetime = 80,
    shoottime = 32,
    shootdelay = 16,
    shootframes = 2,
    idleframes = 1,
    explodeframes = 2,
    taildeathdelay = 1,

    tailid = 705,
    projectileid = 706,
    closeness = 8,
    acceleration = 0.0648,
    maxspeed = 2,
    tailoffsetx = 0,
    tailoffsety = 0,
    taileffectid = 300,
	shootsound = 16
}

local chompIDs = {}

function flameChomp.register(id, settings)
    chompIDs[id] = true
    npcManager.registerEvent(id, flameChomp, "onTickEndNPC")
	npcManager.registerEvent(id, flameChomp, "onDrawNPC")
    npcManager.setNpcSettings(table.join(settings, sharedSettings))
end

--Custom local definitions below
local STATE_CHASE = 0
local STATE_SPLIT = 1
local STATE_EXPLODE = 2

--Register events
function flameChomp.onInitAPI()
	registerEvent(flameChomp, "onPostNPCKill")
end

function flameChomp.onDrawNPC(v)
    if v.despawnTimer <= 0 then return end

	local data = v.data._basegame
	if not data.initialized then return end
    local cfg = NPC.config[v.id]
	
	local f = math.floor(data.timer / cfg.framespeed)
	
	if data.state == STATE_CHASE then
		f = f % cfg.idleframes
	elseif data.state == STATE_SPLIT then
        f = math.min(f, cfg.shootframes - 1) + cfg.idleframes
	elseif data.state == STATE_EXPLODE then
        f = (f % cfg.explodeframes) + cfg.idleframes + cfg.shootframes
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame=f})
	v.animationTimer = 100
end

function flameChomp.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		
		if data.tailObject then
			for i=#data.tailObject,1,-1 do
				if data.tailObject[i].isValid then
					data.tailObject[i]:kill(HARM_TYPE_OFFSCREEN)
					data.tailObject[i] = nil
				end
			end
		end
		
		data.initialized = false
		return
	end
		
    local cfg = NPC.config[v.id]

	--Initialize
	if not data.initialized then
		--Initialize necessary data.

		data.tailWidth = NPC.config[cfg.tailID].width*0.5
		data.tailHeight = NPC.config[cfg.tailID].height*0.5
		
		data.state = STATE_CHASE
		
		data.follower = v.data._settings.length or 4
		data.tailObject = {}
		
		data.maxHistoryCount = math.max(data.follower*cfg.closeness,1)
		
		data.tailHistory = {}
		
		for i=1,data.follower do
			local s = NPC.spawn(cfg.tailID, v.x, v.y, v.section, false, true)
            s.data._basegame.parent = v
			s.friendly = v.friendly
			s.layerName = v.layerName
			s.noMoreObjInLayer = v.noMoreObjInLayer
			data.tailObject[i] = s
		end
		
        local startPos = vector(
            v.x + 0.5 * v.width + cfg.tailoffsetx,
            v.y + 0.5 * v.height + cfg.tailoffsety)
		for i=1,data.maxHistoryCount do
			data.tailHistory[i] = vector(startPos.x, startPos.y)
		end
		
		data.homingDist = 1
		
		data.timer = 0
		
		data.initialized = true
	end

	local held = false

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) ~= 0    --Grabbed
	or v:mem(0x132, FIELD_WORD) > 0    --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		held = true
	end

	if not held then
		data.timer = data.timer+1
		
		--Execute main AI. This template just jumps when it touches the ground.
		if data.state == STATE_CHASE then
			
			if (cfg.idletime > 0 or data.follower == 0) and data.timer >= cfg.idletime then
				data.state = STATE_SPLIT
				data.timer = 0
				
				if data.follower>0 then
				
					v.speedX = 0
					v.speedY = 0
					if data.tailObject[data.follower].isValid then
						data.tailObject[data.follower]:kill(HARM_TYPE_OFFSCREEN)
						data.tailObject[data.follower] = nil
					end
					data.follower = data.follower-1
				else
					data.state = STATE_EXPLODE
					data.timer = 0
				end

			end
		elseif data.state == STATE_SPLIT then
			local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
			if data.timer==cfg.shootdelay then
				if cfg.shootsound ~= 0 then
					SFX.play(cfg.shootsound)
				end
			
				local w = NPC.spawn(cfg.projectileID, v.x+0.5*v.width, v.y+0.5*v.height, v.section, false, true)
				local aimang = math.atan2(p.y-v.y,p.x-v.x)
				w.speedX = 2.5*math.cos(aimang)
				w.speedY = 2.5*math.sin(aimang)
				w.layerName = "Spawned NPCs"
				w.friendly = v.friendly
			end
			
			if data.timer >= cfg.shoottime then
				data.state = STATE_CHASE
				data.timer = 0
			end
		
		elseif data.state == STATE_EXPLODE then
			
			if data.timer >= cfg.explodetime then
				if v.friendly then
					Explosion.spawn(v.x+0.5*v.width, v.y+0.5*v.height, 0)
				else
					Explosion.spawn(v.x+0.5*v.width, v.y+0.5*v.height, 3)
				end
				v:kill(HARM_TYPE_OFFSCREEN)
			end
		end
		
		if data.state == STATE_CHASE or data.state == STATE_EXPLODE then
		
			if not data.holding then
		
				--Homing X position
				local p = npcutils.getNearestPlayer(v)
			
				local distX = (p.x + 0.5 * p.width) - (v.x + 0.5 * v.width)
				
				if math.abs(distX)>data.homingDist then
					v.speedX = math.clamp(v.speedX + cfg.acceleration*math.sign(distX),-cfg.maxspeed,cfg.maxspeed)
				end
				
				--Homing Y position
			
				local distY = (p.y + 0.5 * p.height) - (v.y + 0.5 * v.height)
				
				if math.abs(distY)>data.homingDist then
					v.speedY = math.clamp(v.speedY + cfg.acceleration*math.sign(distY),-cfg.maxspeed,cfg.maxspeed)
				end
			else
			
				--Slow down the speed from throwing
				v.speedX = v.speedX*0.99
				
				if math.abs(v.speedX)<0.1 then
					v.speedX = 0
				end
				
				v.speedY = v.speedY*0.99
				
				if math.abs(v.speedY)<0.1 then
					v.speedY = 0
					data.holding = false
				end
				
			end
		end

		v.despawnTimer = 180
	end
	
	if data.maxHistoryCount<=1 then return end
	
	if data.state ~= STATE_CHASE then return end

	data.tailHistory[1].x = v.x + 0.5 * v.width + cfg.tailoffsetx
	data.tailHistory[1].y = v.y + 0.5 * v.height + cfg.tailoffsety
	
	--Update Position History
	for i=data.maxHistoryCount-1,1,-1 do
		data.tailHistory[i+1].x = data.tailHistory[i].x
		data.tailHistory[i+1].y = data.tailHistory[i].y
	end
	
	
	local t = v.despawnTimer
	--Update Tail Position
	for i=#data.tailObject,1,-1 do
		if data.tailObject[i].isValid then
			data.tailObject[i].friendly = v.friendly or held
			data.tailObject[i].x = data.tailHistory[i*cfg.closeness].x - 0.5 * data.tailObject[i].width
			data.tailObject[i].y = data.tailHistory[i*cfg.closeness].y - 0.5 * data.tailObject[i].height

			data.tailObject[i].despawnTimer = t
		end
	end
	
end

local function killRoutine(tailObject, cfg)
    if cfg.taildeathdelay == 0 then
		for i=1,#tailObject do
			if tailObject[i].isValid then
				Effect.spawn(cfg.taileffectid,tailObject[i].x,tailObject[i].y)
				tailObject[i]:kill(HARM_TYPE_OFFSCREEN)
			end
		end
    else
		for i=1,#tailObject do
			if tailObject[i].isValid then
                Routine.waitFrames(cfg.taildeathdelay)
				if tailObject[i].isValid then
					Effect.spawn(cfg.taileffectid,tailObject[i].x,tailObject[i].y)
					tailObject[i]:kill(HARM_TYPE_OFFSCREEN)
				end
			end
		end
    end
end

local transitiveProperties = {
	"noMoreObjInLayer",
	"activateEventName",
	"deathEventName",
	"layerName",
	"friendly",
	"dontMove",
	"talkEventName",
	"msg",
	"attachedLayerName",
	"isHidden"
}

local function respawn(id, x, y, settings, section, props)
	Routine.wait(settings.respawndelay)
	local p = Player.getNearest(x, y)
	if p.section == section then
		local newX = p.x - 420
		if p.x > x then
			newX = p.x + 420
		end
		local n = NPC.spawn(id, newX, p.y + 0.5 * p.height + RNG.random(-200, 200), section, true, true)
		if n.x > p.x then
			n.x = n.x + 0.5 * n.width
		else
			n.x = n.x - 0.5 * n.width
		end
		
		n.data._settings = settings
		for k,p in ipairs(transitiveProperties) do
			n[p] = props[p]
		end
	end
end

function flameChomp.onPostNPCKill(v, killReason)
	if not chompIDs[v.id] then return end
	
	local data = v.data._basegame
	
	if killReason == HARM_TYPE_OFFSCREEN or killReason == HARM_TYPE_SPINJUMP or killReason == HARM_TYPE_HELD then
		for i=#data.tailObject,1,-1 do
			if data.tailObject[i].isValid then
				Effect.spawn(10,data.tailObject[i].x,data.tailObject[i].y)
				data.tailObject[i]:kill(HARM_TYPE_OFFSCREEN)
			end
		end
	else
        Routine.run(killRoutine, data.tailObject, NPC.config[v.id])
    end

    if v.data._settings.respawns then
		local props = {}
		for k,p in ipairs(transitiveProperties) do
			props[p] = v[p]
		end
		Routine.run(respawn, v.id, v.x + 0.5 * v.width, v.y + 0.5 * v.height, v.data._settings, v.section, props)
    end
end

--Gotta return the library table!
return flameChomp