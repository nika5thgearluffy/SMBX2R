local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local shy = {}

local ids = {}
local idMap = {}

function shy.register(id, bonkFunc)
	table.insert(ids, id)
	idMap[id] = bonkFunc
	npcManager.registerEvent(id, shy, "onTickEndNPC")
	npcManager.registerEvent(id, shy, "onDrawNPC")
end

function shy.onInitAPI()
	registerEvent(shy, "onNPCHarm", "onNPCHarm", false)
end

local STATE_WALK = 1
local STATE_BOPPED = 2
local STATE_WAKING = 3

local function initialise(v)
	local data = v.data._basegame
	data.state = STATE_WALK
    data.frame = 0
	data.timer = 65
	data.playerEvent = 0
	data.bonkAnimationTimer = 0
end

function shy.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 then
		data.state = nil;
		return
	end
	
	if v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x136, FIELD_BOOL) then
		data.state = STATE_WALK;
		data.timer = 0;
		data.frame = 0
		data.playerEvent = 0
		v.animationTimer = 99
		data.bonkAnimationTimer = 0
	else
		if data.state == STATE_WALK then
			v.speedX = v.direction * 1.25 * NPC.config[v.id].speed
		else
			v.speedX = 0
		end
	end

	if data.state == nil then
		initialise(v)
	end

	if v:mem(0x138, FIELD_WORD) > 0 then return end

	if data.playerEvent > 0 then
		idMap[v.id](Player(data.playerEvent), v)
		data.playerEvent = 0
	end
	
	local cfg = NPC.config[v.id]
	data.timer = data.timer + 1
	if data.state == STATE_BOPPED then
		if data.timer >= cfg.bonktime then
			data.state = STATE_WAKING
			data.timer = 0
		end
	elseif data.state == STATE_WAKING then
		if data.timer >= cfg.waketime then
			data.state = STATE_WALK
			data.timer = 0
			v.speedY = -2.4
		end
	end

	if data.bonkAnimationTimer > 0 then
		data.bonkAnimationTimer = data.bonkAnimationTimer - 0.5
	end
end

function shy.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end

	local data = v.data._basegame
	if data.timer == nil then return end

	local cfg = NPC.config[v.id]
	local walkFrames = cfg.frames - cfg.bonkedframes
	local frameset = 0
	if data.state == STATE_WALK then
		v.animationFrame = math.floor(data.timer / cfg.framespeed) % walkFrames
	elseif data.state == STATE_BOPPED then
		frameset = 1
		local add = math.ceil(data.bonkAnimationTimer* 0.125)
		
		v.animationFrame = 0 + add
	elseif data.state == STATE_WAKING then
		frameset = 1
		v.animationFrame = 0
		
		--butt shake
		if data.timer < cfg.framespeed * 10 then
			if data.timer%4 > 0 and data.timer%4 < 3 then
				v.x = v.x + 2
			else
				v.x = v.x - 2
			end
		end
	end
	
	if frameset == 0 then
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frames = walkFrames,
			gap = cfg.bonkedframes,
			offset = 0
		})
	elseif frameset == 1 then
		v.animationFrame = utils.getFrameByFramestyle(v, {
			frames = cfg.bonkedframes,
			gap = 0,
			offset = walkFrames
		})
	end
end

function shy.onNPCHarm(eventObj, v, killReason, culprit)
	if not idMap[v.id] then return end
	if killReason ~= HARM_TYPE_JUMP and killReason ~= HARM_TYPE_SPINJUMP and killReason ~= HARM_TYPE_TAIL then return end
	eventObj.cancelled = true
	local data = v.data._basegame
	
	if killReason ~= HARM_TYPE_TAIL then
		if data.state ~= STATE_WALK then
			if culprit then
				data.playerEvent = culprit.idx
			end
		else
			Effect.spawn(10, v.x, v.y)
			v.speedY = -2
		end
	else
		Effect.spawn(10, v.x, v.y)
		v.speedY = -4

	end
		
	data.state = STATE_BOPPED
	data.timer = 0
	SFX.play(2)
end

return shy;