local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local torches = {}

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

function torches.register(id)
    npcManager.registerEvent(id, torches, "onTickEndNPC")
end

--*********************************************
--                                            *
--                     AI                     *
--                                            *
--*********************************************

-- DINO TORCH FLAMES
function torches.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138,FIELD_WORD) > 0 then
		data.exists = false
		data.timer = 0
		return
	end
	
	-- Initialization
	if not data.exists then
		
		data.timer = data.timer or 0
		data.frame = 0
		data.exists = true;
		data.frameset = 1
		
		if data.friendly == nil then
			data.friendly = v.friendly
		end
		
		if data.parent and data.parent.isValid then
			data.xOffset = v.x - data.parent.x
			data.yOffset = v.y - data.parent.y
			data.parentId = data.parent.id
		end
	end
	
	-- Snap to parent of the torch
	if data.parent then
		if (not data.parent.isValid) or data.parent.id ~= data.parentId or data.parent:mem(0x12C, FIELD_WORD) > 0 or data.parent:mem(0x138, FIELD_WORD) > 0 then
			v:kill(9)
			return
		else
			v.x = data.parent.x + data.xOffset
			v.y = data.parent.y + data.yOffset
		end
	else
		v.speedX,v.speedY = npcutils.getLayerSpeed(v)
	end

	local cfg = NPC.config[v.id]
	local framesets = cfg.framesets or 4
	local duration = cfg.duration or 162
	local frames = cfg.frames or 2
	
	-- hardcoded animation time baybee
	-- i want to clean this up but at the same time i have no idea how i'd do it lol
	data.timer = data.timer + 1;

	data.frame = math.floor(data.timer / cfg.framespeed) % cfg.frames

	local frame = data.frame
	local t = data.timer
	local modifier = 1
	local extendTime = math.min(cfg.framespeed * frames * 2, duration * 0.5 / ((framesets) * 2))

	if data.timer >= duration - extendTime * (framesets - 1) then
		modifier = -1
		t = duration - data.timer
	end
		
	if t % extendTime == 0 then
		data.frameset = math.clamp(data.frameset + modifier, 1, framesets)
	end

    if v.lightSource then
		if data.brightness == nil then
			data.brightness = v.lightSource.brightness
		end
		local growthRatio
		if t < duration * 0.5 then
			growthRatio = math.clamp(t/(extendTime * (framesets - 1)), 0, 1)
		else
			growthRatio = math.clamp((duration-t)/(extendTime * (framesets - 1)), 0, 1)
		end
		v.lightSource.brightness = growthRatio * data.brightness
        v.lightSource.type = Darkness.lighttype.LINE
		local ratio = v.width/v.height
		if ratio > 1 then
			v.lightSource.parentoffset = vector(cfg.lightoffsetx - (v.width - v.height) * 0.5, cfg.lightoffsety)
			v.lightSource.radius = v.height
			v.lightSource.dir = vector(v.direction * growthRatio * (v.width - v.height), 0)
		else
			v.lightSource.parentoffset = vector(cfg.lightoffsetx, cfg.lightoffsety +(v.height - v.width) * 0.5)
			v.lightSource.dir = vector(0, -(v.height - v.width) * growthRatio)
			v.lightSource.radius = v.width
		end
    end

	if data.timer >= duration then
		v:kill(9)
	end
	
	-- flame shouldn't hit you until it's fully out
	if data.frameset == framesets then
		v.friendly = data.friendly;
	else
		v.friendly = true;
	end
	
	-- update animations
	v.animationTimer = 500
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = frame + (data.frameset - 1) * frames,
		frames = NPC.config[v.id].frames * framesets,
	});
end

return torches;