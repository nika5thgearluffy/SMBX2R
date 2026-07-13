local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local flipperGate = {}

flipperGate.sharedSettings = {
    	frames = 1,
    	framestyle = 1,

    	noiceball = true,
    	noyoshi = true,
	luahandlesspeed = true,
	nohurt = true,
	jumphurt = true,
	notcointransformable = true,
	ignorethrownnpcs = true,
	noblockcollision = true,
    	nowaterphysics = true,
	isstationary = true,
    	nogravity = true,
	staticdirection = true,

	-- Custom:

	isVertical = false,

	solidBlockID = 1006,
	widthBuffer = 1.5,
	heightBuffer = 1,

	openSpeed = 10,
	openRotation = 85,
	stuckRotation = -15,
	pivotDist = 0.25,

	closeSound = 37,
	stuckSound = 3,

	debugMode = false,
}

function flipperGate.register(id)
    	npcManager.registerEvent(id, flipperGate, "onTickEndNPC")
    	npcManager.registerEvent(id, flipperGate, "onDrawNPC")
end

local IDLE = 0
local FLIP = 1
local STUCK = 2

-- takes start and makes it get closer to goal, at speed change
-- borrowed from SMATRS
local function approach(start, goal, change)
    	if start > goal then
        	return math.max(goal, start - change)
    	elseif start < goal then
        	return math.min(goal, start + change)
    	else
        	return goal
    	end
end

local function flipCheck(p, v, config)
	if config.isVertical then
		if (p.y < (v.y + v.height) and v.direction == -1) or ((p.y + p.height) > v.y and v.direction == 1) then
			return true
		end
	else
		if (p.x < (v.x + v.width) and v.direction == -1) or ((p.x + p.width) > v.x and v.direction == 1) then
			return true
		end
	end

	return false
end

local function byeByeBlock(data)
	if data.block and data.block.isValid then 
		data.block:delete() 
		data.block = nil
	end
end

function flipperGate.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
        local config = NPC.config[v.id]

	if v.despawnTimer <= 0 or not v.isValid then
		data.initialized = false
		byeByeBlock(data)

		return
	end

	if not data.initialized then
		data.initialized = true

		local whichWayWidth = ((config.isVertical and config.heightBuffer) or config.widthBuffer)
		local whichWayHeight = ((config.isVertical and config.widthBuffer) or config.heightBuffer)

		data.hitbox = Colliders.Box(v.x, v.y, v.width * whichWayWidth, v.height * whichWayHeight)
		data.rotation = 0
		data.state = IDLE
	end

	data.hitbox.x = v.x + (v.width * 0.5) - (data.hitbox.width * 0.5)
	data.hitbox.y = v.y + (v.height * 0.5) - (data.hitbox.height * 0.5)

	if config.debugMode then
		Colliders.getHitbox(v):Draw(Color.fromHexRGBA(0xFFFF0099))
		data.hitbox:Debug(true)
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then return end
        npcutils.applyLayerMovement(v)

	for _,p in ipairs(Player.get()) do
		if p.forcedState == 0 and p.deathTimer == 0 and Colliders.collide(data.hitbox, p) then
			if flipCheck(p, v, config) then
				if data.state ~= FLIP then
					data.state = FLIP
					SFX.play("sound/extended/flipper-open.ogg")
				end
			else
				if data.state ~= STUCK then
					if data.state == FLIP then
						if config.closeSound then
							SFX.play(config.closeSound)
						end
					elseif data.state == IDLE then
						if config.stuckSound then
							SFX.play(config.stuckSound)
						end
					end

					data.state = STUCK
				end
			end
		else
			if data.state ~= IDLE then
				if config.closeSound and data.state ~= STUCK then
					SFX.play(config.closeSound)
				end

				data.state = IDLE
			end
		end
	end

	if data.state == FLIP then
		byeByeBlock(data)
	else
		if not data.block then
			data.block = Block.spawn(config.solidBlockID, v.x, v.y)
			data.block.width = v.width
			data.block.height = v.height
		end
	end

	if data.block and data.block.isValid then
		local newBlockX = v.x + v.width * 0.5 - data.block.width * 0.5
		local newBlockY = v.y + v.height * 0.5 - data.block.height * 0.5

		data.block.extraSpeedX = (newBlockX - data.block.x)
		data.block.extraSpeedY = (newBlockY - data.block.y)
		data.block:translate(data.block.extraSpeedX, data.block.extraSpeedY)
	end

	if data.state == IDLE then
		data.rotation = approach(data.rotation, 0, config.openSpeed)
	elseif data.state == FLIP then
		data.rotation = approach(data.rotation, (config.openRotation * -v.direction), config.openSpeed)
	elseif data.state == STUCK then
		data.rotation = approach(data.rotation, (config.stuckRotation * -v.direction), config.openSpeed)
	end
end

function flipperGate.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
        local config = NPC.config[v.id]
	local img = Graphics.sprites.npc[v.id].img

	if not data.rotation then return end

	local lowPriorityStates = table.map{1, 3, 4}
	local priority = (lowPriorityStates[v:mem(0x138, FIELD_WORD)] and -75) or (v:mem(0x12C, FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	local pivots = (config.isVertical and {vector(config.pivotDist, 0.5), vector((1 - config.pivotDist), 0.5)}) or {vector(0.5, config.pivotDist), vector(0.5, (1 - config.pivotDist))}
	local dir = {-1, 1}

	local xOryOffsets = {(config.pivotDist / 2), (1 - (config.pivotDist / 2))}
	local xOffsetsTex = {-(config.gfxwidth * (config.pivotDist / 2)), -(config.gfxwidth - (config.gfxwidth * (config.pivotDist / 2)))}
	local yOffsetsTex = {-(config.gfxheight * (config.pivotDist / 2)), -(config.gfxheight - (config.gfxheight * (config.pivotDist / 2)))}

	for j = 1,2 do
		data.sprite = {}

    		if data.sprite[j] == nil then
        		data.sprite[j] = Sprite{texture = img, frames = npcutils.getTotalFramesByFramestyle(v), pivot = pivots[j]}
    		end

		if config.isVertical then
    			data.sprite[j].x = (v.x + (v.width * xOryOffsets[j])) + config.gfxoffsetx
    			data.sprite[j].y = v.y + (v.height / 2) + config.gfxoffsety
    			data.sprite[j].width = (config.gfxwidth / 2)
			data.sprite[j].texscale.x = config.gfxwidth
			data.sprite[j].texposition.x = xOffsetsTex[j]
			data.sprite[j].rotation = (-data.rotation * dir[j])
		else
    			data.sprite[j].x = v.x + (v.width / 2) + config.gfxoffsetx 
    			data.sprite[j].y = (v.y + (v.height * xOryOffsets[j])) + config.gfxoffsety
    			data.sprite[j].height = (config.gfxheight / 2)
			data.sprite[j].texscale.y = config.gfxheight
			data.sprite[j].texposition.y = yOffsetsTex[j]
			data.sprite[j].rotation = (data.rotation * dir[j])
		end

    		data.sprite[j]:draw{frame = (v.animationFrame + 1), priority = priority, sceneCoords = true}
	end

	npcutils.hideNPC(v)
end

return flipperGate